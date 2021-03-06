//GLOBAL CONSTANTS
#define TACT_DEBOUNCE 25
#define SUNRISE -1                //hour value in schedule that denotes sunrise rather than a fixed time
#define SUNSET -2                 //hour value in schedule that denotes sunset rather than a fixed time

//CONSTANTS FOR SUNRISE AND SUNSET CALCULATIONS
#define OFFICIAL_ZENITH 90.83333
#define LAT 42.9275      //latitude
#define LONG -83.6301    //longitude

//MCU PIN ASSIGNMENTS
#define TOGGLE_BTN 2     //manual on/off button
#define LED1 3
#define LED2 4
#define LED3 5

//GLOBAL VARIABLES
int8_t sched[] = { 4,0,0,0,  0,0,0,0,  5,0,1,0,  -1,30,0,0,  -2,-30,1,0 };
boolean ledState;
Button btnToggle = Button(TOGGLE_BTN, true, true, TACT_DEBOUNCE);
time_t utcNow, locNow, utcLast, utcStart;                   //RTC is set to UTC
int8_t utcH, utcM, utcS, locH, locM, locS;                  //utc and local time parts
uint8_t sunriseH, sunriseM, sunsetH, sunsetM;               //hour and minute for sunrise and sunset 
int ord;                                                    //ordinal date (day of year)
uint8_t currentSched;                                       //the current schedule in effect
uint8_t overrideSched;                                      //the schedule in effect when the manual off/on button was last pressed

//Timezone objects for US Eastern Time
TimeChangeRule EDT = {"EDT", Second, Sun, Mar, 2, -240};    //Daylight time = UTC - 4 hours
TimeChangeRule EST = {"EST", First, Sun, Nov, 2, -300};     //Standard time = UTC - 5 hours
Timezone ET(EDT, EST);
TimeChangeRule *tcr;
int utcOffset;

void setup(void)
{
    Serial.begin(9600);
    printVersionInfo();
    pinMode(LED1, OUTPUT);             //pin configuration
    pinMode(LED2, OUTPUT);
    pinMode(LED3, OUTPUT);

    setSyncProvider(RTC.get);          //function to get the time from the RTC
    if(timeStatus() != timeSet) {
        Serial << F("FAIL: RTC sync") << endl;
        delay(10000);
    }
    else {
        Serial << F("RTC sync") << endl;
        utcNow = now();
        utcLast = utcNow;
        utcStart = utcNow;
        updateTime();
        ord = ordinalDate(locNow);
        calcSunset (ord, LAT, LONG, false, utcOffset, OFFICIAL_ZENITH, sunriseH, sunriseM);
        calcSunset (ord, LAT, LONG, true, utcOffset, OFFICIAL_ZENITH, sunsetH, sunsetM);
        Serial << F("UTC: ");
        printTime(utcNow);        
        Serial << F("Local time: ");
        printTime(locNow);
        printSunRiseSet();
    }
    setLEDs(true, true);        //lamp test
    setLEDs(false, true);
    delay(500);
    currentSched = processSchedules();
}

void loop(void)
{
    btnToggle.read();
    if (btnToggle.wasReleased()) {    //manual override -- only lasts until next schedule time
        overrideSched = currentSched;
        Serial << F("Manual ") << (ledState ? "OFF" : "ON") << endl;
        setLEDs(ledState = !ledState, true);
    }
    utcNow = now();
    if (utcNow != utcLast) {
        updateTime();
        if (utcS < second(utcLast)) {
            if (utcH != hour(utcLast)) {    //recalculate DST change times, sunrise, sunset for the day
                ord = ordinalDate(locNow);
                calcSunset (ord, LAT, LONG, false, utcOffset, OFFICIAL_ZENITH, sunriseH, sunriseM);
                calcSunset (ord, LAT, LONG, true, utcOffset, OFFICIAL_ZENITH, sunsetH, sunsetM);
            }
            currentSched = processSchedules();
        }
        utcLast = utcNow;
    }
}

void updateTime(void)              //update various time variables
{
    utcH = hour(utcNow);
    utcM = minute(utcNow);
    utcS = second(utcNow);
    locNow = ET.toLocal(utcNow, &tcr);   //TZ adjustment
    utcOffset = tcr -> offset / 60;
    locH = hour(locNow);
    locM = minute(locNow);
    locS = second(locNow);
}

uint8_t processSchedules(void)
{
    int8_t nSched, schedHour, schedMin;
    boolean schedState, setState;
    int schedTime, localTime;
    uint8_t i, schedNbr;

    nSched = sched[0];
    schedNbr = 0;
    localTime = 100 * hour(locNow) + minute(locNow);    //local time as a single integer for comparison
    Serial << endl << F("Local time: ") << _DEC(localTime) << ' ';
    printTime(locNow); 
    printSunRiseSet();

    for (i=1; i<=nSched; i++) {
        schedHour = sched[i * 4];
        schedMin = sched[i * 4 + 1];
        schedState = sched[i * 4 + 2];
        Serial << F("Schedule ") << _DEC(i) << F(": ") << _DEC(schedHour) << ' ' << _DEC(schedMin) << ' '  << _DEC(schedState);

        if (schedHour == SUNRISE)         //for sunrise schedules, calculate the actual hour and minute
            calcSunOffset(sunriseH, sunriseM, schedHour, schedMin);
        else if (schedHour == SUNSET)     //for sunset schedules, calculate the actual hour and minute 
            calcSunOffset(sunsetH, sunsetM, schedHour, schedMin);
        Serial << endl;

        schedTime = 100 * schedHour + schedMin;         //schedule time as a single integer for comparison
        if (localTime >= schedTime) {
            schedNbr = i;
            setState = schedState;
        }
    }
    //if local time < first schedule time, then the last schedule is in effect
    if (schedNbr == 0) {
        schedNbr = nSched;
        setState = schedState;
    }
    
    Serial << F("Active=") << _DEC(schedNbr);
    if (ledState != setState && overrideSched != schedNbr) {    //don't set LEDs if override in effect
        overrideSched = 0;                                      //cancel any manual override in effect
        Serial << F(", set LEDs");
        setLEDs(ledState = setState, true);
    }
    Serial << endl;
    return schedNbr;    //return the active schedule number
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
    Serial << F(" = ") << _DEC(schedHour) << ' ' << _DEC(schedMin);
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

