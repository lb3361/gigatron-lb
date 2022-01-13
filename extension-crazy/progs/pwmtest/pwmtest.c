#include <stdlib.h>
#include <string.h>
#include <gigatron/console.h>
#include <gigatron/sys.h>


void set_pwm(int v)
{
  SYS_ExpanderControl( (v << 10) | 0xD0 );
}

int main()
{
  int v = 32;

  cprintf("\f\n\n"
          "-Voltage 0 to 3.3v shows\n"
          " on pin XIN3 or on center\n"
          " pin of PWM header.\n"
          "-Change v with up/down.\n");
  
  for(;;)
    {
      set_pwm(v);
      console_state.cy = 0;
      cprintf("PWM v=%2d\n", v);
      console_waitkey();
      if (buttonState == (0xFF ^ buttonDown))
        v = (v > 0) ? v - 1 : 0;
      if (buttonState == (0xFF ^ buttonUp))
        v = (v < 63) ? v + 1 : 63;
    }
}

