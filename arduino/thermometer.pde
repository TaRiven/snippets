#include <Servo.h>

#define DECAY_FACTOR 5
#define MIN_POT_DISTANCE 90
#define DEBUG 0

#define SERVO_ID 3
#define POT_ID 0
#define THERMISTOR_ID 1
#define THE_LIGHT 13
#define VAR_LIGHT 11

int decayAvg = -1;
int prevRange = 0;
unsigned long lightUntil = 0;

#if DEBUG
int prevValue = -1;
#endif /* DEBUG */

Servo s;

void setup() {
#if DEBUG
    Serial.begin(9600);
#endif /* DEBUG */
    s.attach(SERVO_ID);
}

int computeSmoothedReading(int newReading) {

    if(decayAvg == -1) {
        decayAvg = newReading;
    } else {
        decayAvg = ((decayAvg * DECAY_FACTOR) + newReading) / (DECAY_FACTOR + 1);
    }

    return (int)decayAvg;
}

int angle() {
    // The reading is scaled beyond the range of the servo so it's
    // more sensitive.
    int reading = map(analogRead(THERMISTOR_ID), 0, 1023, 720, 0);

    // The potentiometer is used for calibrating the reading
    int range = map(analogRead(POT_ID), 0, 1023, -720, 720);
    if (abs(range - prevRange) > MIN_POT_DISTANCE) {
        prevRange = range;
        lightUntil = millis() + 5000;
    }

    // Combining the reading and the range, we get the current position
    int rv = computeSmoothedReading(constrain(reading + range, 0, 180));

#if DEBUG
    if (rv != prevValue) {
        Serial.print(reading, DEC);
        Serial.print("/");
        Serial.print(range, DEC);
        Serial.print(" -> ");
        Serial.print(rv, DEC);
        Serial.println("");
        prevValue = rv;
    }
#endif /* DEBUG */

    // We use the light to indicate whether we're within a reasonable
    // calibrated range for the analog display.  You could also just like,
    // Aim for 90°, but that'd be too easy.
    if (rv > 45 && rv < 135) {
        digitalWrite(THE_LIGHT, LOW);
    }
    else {
        digitalWrite(THE_LIGHT, HIGH);
    }

    return rv;
}

void setVarLight(int a) {
    if (millis() < lightUntil) {
        int rel = constrain(abs(90 - a), 0, 20);
        int lightVal = map(rel, 0, 20, 128, 0);
        analogWrite(VAR_LIGHT, lightVal);
    } else {
        analogWrite(VAR_LIGHT, 0);
    }
}

void loop() {
    int a = angle();
    // Move the servo to the computed angle.
    s.write(a);
    // Adjust the other light to the distance from 90
    setVarLight(a);
}
