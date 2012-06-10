/*----------------------------------------------------------------------*
 * Christmas Candle Timer
 * Jack Christensen
 * v1.1 09Oct2011
 * v1.2 04Dec2011 Added sunrise and sunset calculation, and ability
 *      for a schedule to turn the lamps on or off at sunrise or
 *      sunset, plus or minus an offset.
 * v1.3 09Jun2012 Use Timezone library, remove schedules from EEPROM.
 *
 * The calculated sunrise and sunset do not currently take DST into
 * account, standard time is always assumed. This is OK because the
 * candles will only be used during the holidays, i.e. standard time,
 * but for other uses this should be added.
 *
 * 
 *
 * This work is licensed under the Creative Commons Attribution-        *
 * ShareAlike 3.0 Unported License. To view a copy of this license,     *
 * visit http://creativecommons.org/licenses/by-sa/3.0/ or send a       *
 * letter to Creative Commons, 171 Second Street, Suite 300,            *
 * San Francisco, California, 94105, USA.                               *
 *----------------------------------------------------------------------*/

/*----------------------------------------------------------------------* 
 * Each schedule entry consists of four int8_t values. The first entry  *
 * is not an actual schedule, but gives the number of schedule entries  *
 * that follow.                                                         *
 *                                                                      *
 * The first four bytes are as follows:                                 *
 * 00: # of schedules                                                   *
 * 01: 0 (reserved for future use)                                      *
 * 02: 0 (RFU)                                                          *
 * 03: 0 (RFU)                                                          *
 *                                                                      *
 * Beginning at offset 04, each schedule is as follows:                 *
 * 04: Hour                                                             *
 * 05: Minute                                                           *
 * 06: Action, 1=turn lamps on, 0=turn lamps off                        *
 * 07: 0 (RFU)                                                          *
 *                                                                      *
 * Sunrise is denoted by Hour = -1, and then Minute is the number       *
 * of minutes offset from Sunrise (-128 to 127)                         *
 *                                                                      *
 * Sunset is denoted by Hour = -2, and then Minute is the number        *
 * of minutes offset from Sunrise (-128 to 127)                         *
 *----------------------------------------------------------------------*/

