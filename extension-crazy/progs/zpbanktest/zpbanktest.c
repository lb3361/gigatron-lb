#include <stdlib.h>
#include <math.h>
#include <gigatron/console.h>
#include <gigatron/sys.h>


/* From bankasm.h */
extern int _banktest(char *addr, char bitmask);
extern int _change_zbank(void);

int has_zbank(void)
{
  static int v = -1;
  if (v < 0)
    v = _banktest((char*)0xffu, 0x20);
  return v;
}

int set_zbank(int ok)
{
  if (! has_zbank())
    return -1;
  if (!(ctrlBits_v5 & 0x20) != !!ok)
    _change_zbank();
  return !(ctrlBits_v5 & 0x20);
}



int main()
{
  int v;
  const char *s = "pi";
  double x = 3.141592653589793;
  double y;

  cprintf("\fZero page banking\n--------------------\n\n");
  
  cprintf("Testing /ZPBANK\n");
  v = has_zbank();
  cprintf("- %s\n", (v) ? "yes" : "no");
  if (v == 0) {
    cprintf("No /ZPBANK support\n");
    return 10;
  }

  cprintf("Setting /ZPBANK:\n");
  set_zbank(1);

  for (;;)
    {
      cprintf("- ctrlBits=0x%02x\n\n", ctrlBits_v5);
      if (ctrlBits_v5 & 0x20)
        {
          cprintf("/ZPBANK not set!\n");
          return 10;
        }
      cprintf("Doing stuff\n");
      cprintf("- %s=%.8g\n", s, x);
      y = sqrt(x);
      cprintf("- y=sqrt(%s)=%.8g\n", s, y);
      cprintf("- y*y=%.8g\n", y*y);
      cprintf("- log(%s)=%.8g\n", s, log(x));
      cprintf("- log(y)=%.8g\n", log(y));
      s = "x";
      x += 1.0;
      cprintf("Press any key\n");
      if (console_waitkey() == 'Q')
        break;
      cprintf("\fZero page banking\n--------------------\n\n");
    }
  return 0;
}


