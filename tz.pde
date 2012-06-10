#include <Time.h>                //http://www.arduino.cc/playground/Code/Time

/*----------------------------------------------------------------------*
 * Time zone and Daylight Savings info stored in EEPROM.                *
 * The following values refer to the local time of the change.          *
 *                                                                      *
 * EEPROM                                                               *
 * ADDR  DESCRIPTION                                                    *
 * ----- -------------------------------------------------------------- *
 * 00-01 DST start month (int, 1-12)                                    *
 * 02-03 DST start day of week aka DOW (int, 1-7, 1=Sun, 2=Mon, etc.)   *
 * 04-05 DST start kth day (int, 1-5, e.g. if start DOW=1 and k=2,      *
 *       then the 2nd Sunday of the month is indicated.  Does not yet   *
 *       support k<0 which would mean previous, e.g. "last Sunday       *
 *       of the month")                                                 *
 * 06-07 DST start hour (int, 0-23)                                     *
 * 08-09 DST offset, minutes (int, e.g. -240 for US Eastern time zone)  *
 * 10-13 DST abbreviation (char, e.g. "EDT\0")                          *
 *                                                                      *
 * 16-17 Std time end month (int, 1-12)                                 *
 * 18-19 Std time end DOW (int, 1-7)                                    *
 * 20-21 Std time end kth day (int, 1-5)                                *
 * 22-23 Std time end hour (int, 0-23)                                  *
 * 24-25 Std time offset, minutes (int, e.g. -300 for US Eastern)       *
 * 26-29 Std time abbreviation (char, e.g. "EST\0"                      *
 *                                                                      *
 * As of 2007, values for the US Eastern time zone would be:            *
 *   DST starts on 2nd Sun in Mar @ 0200 local time:                    *
 *     {3, 1, 2, 2, -240, "EDT"}                                        *
 *   DST ends on 1st Sun in Nov @ 0200 local time:                      *
 *     {11, 1, 1, 2, -300, "EST"}                                       *
 *----------------------------------------------------------------------*/

static dstRule dstStart, dstEnd;       //rules for daylight savings time
static time_t dstStart_t, dstEnd_t;    //dst start and end for current year, in utc

boolean isDST(time_t utc)
{
    if (utc >= dstStart_t && utc < dstEnd_t)
        return true;
    else
        return false;
}

/*----------------------------------------------------------------------*
 * Convert the given UTC time to local time, standard or                *
 * daylight time, as appropriate.                                       *
 *----------------------------------------------------------------------*/
time_t utcToLocal(time_t utc) {

    if (utc >= dstStart_t && utc < dstEnd_t) {
        return utc + dstStart.Offset * SECS_PER_MIN;
    }
    else {
        return utc + dstEnd.Offset * SECS_PER_MIN;
    }
}

/*----------------------------------------------------------------------*
 * Calculate the DST change times for the current year in UTC.          *
 * Called when a time sync packet is received/processed.                *
 *----------------------------------------------------------------------*/
void calcDstChanges() {

    boolean first = true;
    
    if (first) {                        //get the dst rules from eeprom first time only
        readEE_dst(0, dstStart);
        readEE_dst(16, dstEnd);
        first = false;
    }
    dstStart_t = dstChange_t(dstStart, year(utcNow)) - dstEnd.Offset * SECS_PER_MIN;
    dstEnd_t = dstChange_t(dstEnd, year(utcNow)) - dstStart.Offset * SECS_PER_MIN;
}

/*----------------------------------------------------------------------*
 * Use the given rule to calculate the time of a DST change (start      *
 * or end) for the given year.                                          *
 *----------------------------------------------------------------------*/
time_t dstChange_t(dstRule dst, int yr) {
    
    tmElements_t timeParts;
    time_t dstChg;
    
    timeParts.Hour = dst.Hour;
    timeParts.Minute = 0;
    timeParts.Second = 0;
    timeParts.Day = 1;
    timeParts.Month = dst.Month;
    timeParts.Year = yr - 1970;
    dstChg = makeTime(timeParts);
    if (weekday(dstChg) == dst.DOW) {
        dstChg += (7 * (dst.K - 1)) * SECS_PER_DAY;
    }
    else {
        dstChg += (7 * dst.K - abs(weekday(dstChg) - dst.DOW)) * SECS_PER_DAY;
    }
    return dstChg;
}

/*----------------------------------------------------------------------*
 * Read a dstRule struct from EEPROM at the given address.              *
 *----------------------------------------------------------------------*/
void readEE_dst(int addr, dstRule &d) {
    d.Month = readEE_int(addr);
    d.DOW = readEE_int(addr + 2);
    d.K = readEE_int(addr + 4);
    d.Hour = readEE_int(addr + 6);
    d.Offset = readEE_int(addr + 8);
    d.Abbrev[0] = EEPROM.read(addr + 10);
    d.Abbrev[1] = EEPROM.read(addr + 11);
    d.Abbrev[2] = EEPROM.read(addr + 12);
    d.Abbrev[3] = EEPROM.read(addr + 13);
}

/*----------------------------------------------------------------------*
 * Read an int (2 bytes) from EEPROM at the given address.              *
 *----------------------------------------------------------------------*/
int readEE_int(int addr) {
    return (EEPROM.read(addr) << 8) + EEPROM.read(addr+1);
}

int ordinalDate(time_t t)
{
    int m = month(t);
    int d = day(t);
    
    if (m == 1)
        return d;
    else if (m == 2)
        return d + 31;
    else {
        int n = floor(30.6 * (m + 1)) + d - 122;
        return n + (isLeap(t) ? 60 : 59);
    }
}

boolean isLeap(time_t t)
{
    //Leap years are those divisible by 4, but not those divisible by 100,
    //except that those divisble by 400 *are* leap years.
    //See Kernighan & Ritchie, 2nd edition, section 2.5.

    int y = year(t);
    return (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;
}
