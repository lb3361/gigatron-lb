#include <stdlib.h>
#include <math.h>
#include <gigatron/console.h>
#include <gigatron/sys.h>

#if _GLCC_VER < 104010
# error This program requires a more recent version of GLCC.
#endif

/* From bankasm.h */
extern int _banktest(char *addr, char bitmask);
extern void _change_zpbank(void);

int has_zbank(void)
{
  static int v = -1;
  if (v < 0)
    v = _banktest((char*)0xffu, 0x20);
  return v;
}

void do_something()
{
  const char *s = "pi";
  double x = 3.141592653589793;
  double y;

  for (;;)
    {
      cprintf("- ctrlBits=0x%02x\n\n", ctrlBits_v5);
      if (ctrlBits_v5 & 0x20)
        {
          cprintf("/ZPBANK not set!\n");
          exit(10);
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
}

int main()
{
  int v;

  cprintf("\fZero page banking\n--------------------\n\n");
  
  cprintf("Testing /ZPBANK\n");
  v = has_zbank();
  cprintf("- %s\n", (v) ? "yes" : "no");
  if (v == 0) {
    cprintf("No /ZPBANK support\n");
    return 10;
  }
  cprintf("Changing /ZPBANK:\n");
  _change_zpbank();
  do_something();
  _change_zpbank();
  return 0;
}


