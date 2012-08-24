/*
INTERACTING WITH WATCH:
A button 'tap' is a quick press (a second or less).
A button 'hold' is a long press (2.5 seconds or longer).
Watch will start up in time display mode.

TIME DISPLAY MODE:
Hold left or right button to switch forward/back between clocks.
Some (but not all) clocks may use left or right button tap to switch display formats.
Hold both buttons to switch to time set mode.

TIME SET MODE:
Tap right button to increase value of current digit.
Tap left button to advance to next digit.
Hold both buttons to return to time display mode.
*/

#include <Wire.h>
#include <RTClib.h>
#include <Adafruit_GFX.h>
#include <Watch.h>

#define MODE_SET     0
#define MODE_MARQUEE 1
#define MODE_BINARY  2

void (*modeFunc[])(uint8_t) = {
  mode_set,
  mode_marquee,
  mode_binary
};
#define N_MODES (sizeof(modeFunc) / sizeof(modeFunc[0]))

Watch      watch(true); // Use double-buffered animation
RTC_DS1307 RTC;
uint8_t    mode = MODE_MARQUEE, mode_last = MODE_MARQUEE;

void setup() {
  Serial.begin(9600);
  Wire.begin();
  RTC.begin();
  watch.begin();
}

void loop() {
  uint8_t a = watch.action();
  if(a == ACTION_HOLD_BOTH) {
    if(mode == MODE_SET) {
      // Exit time setting, return to last used display mode
      set();
      mode = mode_last;
    } else {
      // Save current display mode, switch to time setting
      mode_last = mode;
      mode      = MODE_SET;
    }
  } else if(a == ACTION_HOLD_RIGHT) {
    // Switch to next display mode (w/wrap)
    if(++mode >= N_MODES) mode = 1;
  } else if(a == ACTION_HOLD_LEFT) {
    // Switch to prior display mode (w/wrap)
    if(--mode < 1) mode = N_MODES - 1;
  }

  (*modeFunc[mode])(a); // Action is passed to clock-drawing function
  watch.swapBuffers();
}

// To do: add some higher-level clipping here
void blit(uint8_t *img, int iw, int ih, int sx, int sy, int dx, int dy, int w, int h) {
  int x, y;
  for(y=0; y<h; y++) {
    for(x=0;x<w;x++) {
      watch.drawPixel(dx + x, dy + y, pgm_read_byte(&img[(sy + y) * iw + sx + x]));
    }
  }
}
