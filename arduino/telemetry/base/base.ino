#include <JeeLib.h>
#include <avr/sleep.h>

const int THIS_ID(1);
const int LED_PORT(9);
const int MIN_REPORT_FREQ(60000);
const int LIGHT_BLINK_FREQ_ON(250);
const int LIGHT_BLINK_FREQ_OFF(750);

/*
 Output:

 - Normal readings:

     < PORT READING LOW HIGH SEQ

 - Info messages

     # text

 - Exceptional messages

     * MS_SINCE_LAST_HEARD

 */

// The JeeLink LED is backwards.  I don't know why.
#define JEE_LED_ON 0
#define JEE_LED_OFF 1

typedef struct {
    int reading;
    int high;
    int low;
    byte port;
    byte seq;
} data_t;

static bool shouldSend(false);
static unsigned long lastHeard(0);
static unsigned long offAfter(0);

static MilliTimer lastHeardTimer;
static MilliTimer lightBlinkTimer;

ISR(WDT_vect) { Sleepy::watchdogEvent(); }

void setup () {
    pinMode(LED_PORT, OUTPUT);
    digitalWrite(LED_PORT, JEE_LED_OFF);

    Serial.begin(57600);
    rf12_initialize(THIS_ID, RF12_433MHZ, 4);
    Serial.print("# Initialized ");
    Serial.println(THIS_ID);

    lastHeardTimer.set(MIN_REPORT_FREQ);
}

void loop () {
    data_t data;

    if (rf12_recvDone() && rf12_crc == 0 && rf12_len == sizeof(data)) {

        data = *((data_t*)rf12_data);

        digitalWrite(LED_PORT, JEE_LED_ON);
        delay(250);
        digitalWrite(LED_PORT, JEE_LED_OFF);

        Serial.print("< ");
        Serial.print(data.port);
        Serial.print(" ");
        Serial.flush();
        Serial.print(data.reading);
        Serial.print(" ");
        Serial.flush();
        Serial.print(data.low);
        Serial.print("-");
        Serial.flush();
        Serial.print(data.high);
        Serial.print(" ");
        Serial.flush();
        Serial.println(data.seq);
        Serial.flush();

        lastHeardTimer.set(MIN_REPORT_FREQ);
        lastHeard = millis();

        if (RF12_WANTS_ACK) {
            rf12_sendStart(RF12_ACK_REPLY, &data.seq, sizeof(data.seq));
            rf12_sendWait(1); // don't power down too soon
        }

        // power down for 2 seconds (multiple of 16 ms)
        rf12_sleep(RF12_SLEEP);
        Sleepy::loseSomeTime(2000);
        rf12_sleep(RF12_WAKEUP);
    } else {
        // switch into idle mode until the next interrupt
        set_sleep_mode(SLEEP_MODE_IDLE);
        sleep_mode();
    }

    if (lastHeardTimer.poll()) {
        lastHeardTimer.set(MIN_REPORT_FREQ);
        Serial.print("* ");
        Serial.flush();
        Serial.println(millis() - lastHeard);
    }
}
