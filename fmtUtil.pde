void sPrintI00(int val)
{
    //Print an integer in "00" format (with leading zero).
    //Input value assumed to be between 0 and 99.
    if (val < 10) Serial << '0';
    Serial << _DEC(val);
    return;
}

void sPrintDigits(int digits)
{
    // utility function for digital clock display: prints preceding colon and leading 0
    Serial << ":";
    if(digits < 10) Serial << '0';
    Serial << _DEC(digits);
}

void printTime(time_t t) {		//print time to serial monitor
    sPrintI00(hour(t));
    sPrintDigits(minute(t));
    sPrintDigits(second(t));
    Serial << ' ' << dayShortStr(weekday(t)) << ' ';
    sPrintI00(day(t));
    Serial << ' ' << monthShortStr(month(t)) << ' ' << _DEC(year(t)) << endl;
}

void copyToBuffer(byte *dest, unsigned long source) {

    /* Copies 4 bytes to the designated offset in the buffer */

    dest[0] = source >> 24;
    dest[1] = (source >> 16) & 0xFF;
    dest[2] = (source >> 8) & 0xFF;
    dest[3] = source & 0xFF;
}

unsigned long getFromBuffer(byte *source) {

    /* Gets 4 bytes from the buffer starting at the designated offset */

    unsigned long retValue;

    retValue = 0;
    retValue = source[0];
    retValue = source[1] + (retValue << 8);
    retValue = source[2] + (retValue << 8);
    retValue = source[3] + (retValue << 8);
    return retValue;
}

void printVersionInfo() {
    Serial << __FILE__ << endl << __DATE__ << ' ' << __TIME__ << endl;
}

void printSunRiseSet(void)
{
    Serial << "Ordinal Date: " << _DEC(ord) << endl;

    Serial << "Sunrise: ";
    if (sunriseH < 10) Serial << '0';
    Serial << _DEC(sunriseH) << ":";
    if (sunriseM < 10)
        Serial << '0';
    else
        Serial << _DEC(sunriseM / 10);
    Serial << _DEC(sunriseM % 10) << endl;

    Serial << "Sunset: ";
    if (sunsetH < 10) Serial << '0';
    Serial << _DEC(sunsetH) << ":";
    if (sunsetM < 10)
        Serial << '0';
    else
        Serial << _DEC(sunsetM / 10);
    Serial << _DEC(sunsetM % 10) << endl;
}
