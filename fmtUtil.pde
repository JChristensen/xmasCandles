void sPrintI00(int val)
{
    //Print an integer in "00" format (with leading zero).
    //Input value assumed to be between 0 and 99.
    if (val < 10) Serial.print('0');
    Serial.print(val);
    return;
}

void sPrintDigits(int digits)
{
    // utility function for digital clock display: prints preceding colon and leading 0
    Serial.print(":");
    if(digits < 10) Serial.print('0');
    Serial.print(digits);
}

void printTime(time_t t) {		//print time to serial monitor
    sPrintI00(hour(t));
    sPrintDigits(minute(t));
    sPrintDigits(second(t));
    Serial.print(' ');
    Serial.print(dayShortStr(weekday(t)));
    Serial.print(' ');
    sPrintI00(day(t));
    Serial.print(' ');
    Serial.print(monthShortStr(month(t)));
    Serial.print(' ');
    Serial.print(year(t));
    Serial.println();
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
    Serial.println(__FILE__);
    Serial.print(__DATE__);
    Serial.print(' ');
    Serial.println(__TIME__);
}

void printSunRiseSet(void)
{
    Serial.print("Ordinal Date: ");
    Serial.println(ord, DEC);

    Serial.print("Sunrise: ");
    if (sunriseH < 10) Serial.print('0');
    Serial.print (sunriseH, DEC);
    Serial.print (":");
    if (sunriseM < 10)
        Serial.print('0');
    else
        Serial.print(sunriseM / 10, DEC);
    Serial.print (sunriseM % 10, DEC);
    Serial.println();

    Serial.print("Sunset: ");
    if (sunsetH < 10) Serial.print('0');
    Serial.print (sunsetH, DEC);
    Serial.print (":");
    if (sunsetM < 10)
        Serial.print('0');
    else
        Serial.print(sunsetM / 10, DEC);
    Serial.print (sunsetM % 10, DEC);
    Serial.println();
}
