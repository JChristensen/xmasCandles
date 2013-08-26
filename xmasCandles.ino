#include <Button.h>              //http://github.com/JChristensen/Button
//#include <DS1307RTC.h>           //http://www.arduino.cc/playground/Code/Time
#include <DS3232RTC.h>           //http://github.com/JChristensen/DS3232RTC
//#include <MCP79412RTC.h>         //http://github.com/JChristensen/MCP79412RTC
#include <Streaming.h>           //http://arduiniana.org/libraries/streaming/
#include <Time.h>                //http://www.arduino.cc/playground/Code/Time
#include <Timezone.h>            //http://github.com/JChristensen/Timezone
#include <Wire.h>                //http://arduino.cc/en/Reference/Libraries

/*----------------------------------------------------------------------*
 * Christmas Candle Timer                                               *
 * Jack Christensen                                                     *
 * v1.1 09Oct2011                                                       *
 * v1.2 04Dec2011 Added sunrise and sunset calculation, and ability     *
 *      for a schedule to turn the lamps on or off at sunrise or        *
 *      sunset, plus or minus an offset.                                *
 * v1.3 09Jun2012 Use Timezone library, remove schedules from EEPROM.   *
 * v1.4 11May2013 Bugfix: Make last schedule active when local time is  *
 *      earlier than the first schedule. Thanks to Andy Olson for       *
 *      finding this bug.                                               *
 *                                                                      *
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

//FUSE SETTINGS (L/H/E)
//0xE2/0xD6/0x05    Internal RC osc @ 8MHz, preserve EEPROM
//0xFF/0xDE/0x05    Uno
//0x62/0xD9/0xFF    Factory
//0xFF/0xD6/0x05    "Uno" @ 8MHz, ICSP

char* PROGMEM SKETCH_NAME = __FILE__;
char* PROGMEM SKETCH_VER = "v1.4";
char* PROGMEM COMPILE_DATE = __DATE__;
char* PROGMEM COMPILE_TIME = __TIME__;
