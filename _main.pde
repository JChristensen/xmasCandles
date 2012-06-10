//FUSE SETTINGS (L/H/E)
//0xE2/0xD6/0x05    Internal RC osc @ 8MHz, preserve EEPROM
//0xFF/0xDE/0x05    Uno
//0x62/0xD9/0xFF    Factory
//0xFF/0xD6/0x05    "Uno" @ 8MHz, ICSP

//LIBRARIES
#include <Time.h>                //http://www.arduino.cc/playground/Code/Time
#include <Wire.h>                //http://arduino.cc/en/Reference/Libraries
#include "DS1307RTC.h"           //http://www.arduino.cc/playground/Code/Time (declares the RTC variable)
#include <EEPROM.h>              //http://arduino.cc/en/Reference/Libraries
#include <button.h>              //homegrown ;-)
#include "tz.h"                  //part of this project

//GLOBAL CONSTANTS
#define TACT_DEBOUNCE 25
//#define AUTO_TOGGLE 300000      //toggle the LED every 5 minutes
#define SUNRISE -1                //hour value in schedule that denotes sunrise rather than a fixed time
#define SUNSET -2                 //hour value in schedule that denotes sunset rather than a fixed time

//CONSTANTS FOR SUNRISE AND SUNSET CALCULATIONS
#define OFFICIAL_ZENITH 90.83333
#define LAT 42.93        //latitude
#define LONG -83.62      //longitude
#define UTC_OFFSET -5    //US Eastern time

//MCU PIN ASSIGNMENTS
#define TOGGLE_BTN 2
#define LED1 3
#define LED2 4
#define LED3 5

//FUNCTION PROTOTYPES
//void setLEDs(boolean state, boolean slow=true);

//GLOBAL VARIABLES
boolean ledState;
button btnToggle = button(TOGGLE_BTN, true, true, TACT_DEBOUNCE);
time_t utcNow, locNow, utcLast, ntpNextSync, utcStart, uptime;    //RTC is set to UTC
int8_t utcH, utcM, utcS, locH, locM, locS;                        //utc and local time parts
uint8_t sunriseH, sunriseM, sunsetH, sunsetM;                     //hour and minute for sunrise and sunset 
int ord;                                                          //ordinal date (day of year)

void setup(void)
{
    pinMode(A2, OUTPUT);        //power for the RTC
    digitalWrite(A2, LOW);
    pinMode(A3, OUTPUT);
    digitalWrite(A3, HIGH);
    
    Serial.begin(9600);
    printVersionInfo();
    pinMode(LED1, OUTPUT);        //pin configuration
    pinMode(LED2, OUTPUT);
    pinMode(LED3, OUTPUT);
    
    setSyncProvider(RTC.get);          //function to get the time from the RTC
    if(timeStatus()!= timeSet) {
        Serial.println("FAIL: RTC sync");
        delay(10000);
    }
    else {
        Serial.println("RTC sync");
        utcNow = now();
        utcLast = utcNow;
        utcStart = utcNow;
        calcDstChanges();
        locNow = utcToLocal(utcNow);          //TZ adjustment
        ord = ordinalDate(locNow);
        calcSunset (ord, LAT, LONG, false, UTC_OFFSET, OFFICIAL_ZENITH, sunriseH, sunriseM);
        calcSunset (ord, LAT, LONG, true, UTC_OFFSET, OFFICIAL_ZENITH, sunsetH, sunsetM);
        Serial.print("UTC: ");
        printTime(utcNow);        
        Serial.print("Local time: ");
        printTime(locNow);
        printSunRiseSet();
    }
    setLEDs(true, true);        //lamp test
    setLEDs(false, true);
    setLEDs(true, false);
    delay(500);
    setLEDs(false, false);
}

void loop(void)
{
    btnToggle.read();
    if (btnToggle.wasReleased()) {
        Serial.print("Manual ");
        Serial.println(!ledState ? "ON" : "OFF");
        setLEDs(ledState = !ledState, true);
    }
    utcNow = now();
    if (utcNow != utcLast) {
        updateTime();
        if (utcS < second(utcLast)) {
            if (utcH == 0 && utcM == 0) {    //recalculate DST change times, sunrise, sunset for the day
                calcDstChanges();
                ord = ordinalDate(locNow);
                calcSunset (ord, LAT, LONG, false, UTC_OFFSET, OFFICIAL_ZENITH, sunriseH, sunriseM);
                calcSunset (ord, LAT, LONG, true, UTC_OFFSET, OFFICIAL_ZENITH, sunsetH, sunsetM);
            }
            processSchedules();
        }
        utcLast = utcNow;
    }
}

void updateTime(void)              //update various time variables
{
    utcH = hour(utcNow);
    utcM = minute(utcNow);
    utcS = second(utcNow);
    locNow = utcToLocal(utcNow);   //TZ adjustment
    locH = hour(locNow);
    locM = minute(locNow);
    locS = second(locNow);
}

void processSchedules(void)
{
    int8_t nSched, schedHour, schedMin;
    boolean schedState;
    uint16_t addr;
    
    nSched = EEPROM.read(0x100);
    Serial.println();
    Serial.print("Local time: ");
    printTime(locNow); 
    printSunRiseSet();
    for (uint8_t i=0; i<nSched; i++) {
        addr = 0x104 + i * 4;
        schedHour = EEPROM.read(addr);
        schedMin = EEPROM.read(addr + 1);
        schedState = EEPROM.read(addr + 2);
        Serial.print("Schedule ");
        Serial.print(i, DEC);
        Serial.print(": ");
        Serial.print(schedHour, DEC);
        Serial.print(' ');
        Serial.print(schedMin, DEC);
        Serial.print(' ');
        Serial.print(schedState, DEC);
        
        if (schedHour == SUNRISE)    //for sunrise schedules, calculate the actual hour and minute
            calcSunOffset(sunriseH, sunriseM, schedHour, schedMin);
        
        if (schedHour == SUNSET)     //for sunset schedules, calculate the actual hour and minute 
            calcSunOffset(sunsetH, sunsetM, schedHour, schedMin);
        
        if (schedHour == locH && schedMin == locM) {
            Serial.print(" -- SETTING...");
            setLEDs(ledState = schedState, true);
        }
        Serial.println();
    }
}

void calcSunOffset(uint8_t sunH, uint8_t sunM, int8_t &schedHour, int8_t &schedMin)
{
    //for schedule entries that are based on sunrise or sunset, this
    //calculates the actual hour and minute.
    tmElements_t tm;
    time_t sunTime;
    
    breakTime(locNow, tm);        //get the parts of the current time
    tm.Hour = sunH;               //substitute in the sunrise or sunset time
    tm.Minute = sunM;
    tm.Second = 0;
    sunTime = makeTime(tm);       //make the sunrise or sunset time into a time_t
    sunTime += schedMin * 60;     //add the offset minutes
    schedHour = hour(sunTime);
    schedMin = minute(sunTime);
    Serial.print(" = ");
    Serial.print(schedHour, DEC);
    Serial.print(' ');
    Serial.print(schedMin, DEC);
}

void setLEDs(boolean state, boolean slow)
{
    int pause = slow ? 500 : 0;
    
    if (state) {
        digitalWrite(LED1, HIGH);
        delay(pause);
        digitalWrite(LED2, HIGH);
        delay(pause);
        digitalWrite(LED3, HIGH);
        delay(pause);
    }
    else {
        digitalWrite(LED1, LOW);
        delay(pause);
        digitalWrite(LED2, LOW);
        delay(pause);
        digitalWrite(LED3, LOW);
        delay(pause);
    }
}
