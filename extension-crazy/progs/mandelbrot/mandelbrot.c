#include <stdlib.h>
#include <gigatron/console.h>
#include <gigatron/sys.h>


# define SCREENW 320
# define SCREENH 240

typedef signed int fixed_t;
typedef void (*action_t)(void);


/* page zero global (regbase dependent) */

fixed_t      __near x0;
fixed_t      __near y0;
unsigned int __near ctrl;
char*        __near addr;
char         __near lastPix;

#define bank  (((__near char*)&ctrl)[1])
#define addrL (((__near char*)&addr)[0])
#define addrH (((__near char*)&addr)[1])


/* walking around the screen */

void move_pen(fixed_t dx, fixed_t dy)
{
  /* Note that 'bank' is the high byte of variable `ctrl`.
   * It is initialized to value 0xE8 by routine `worm()`,
   * is modified below to track in which bank the
   * current pixel lives, and is used  when `do_pixel()` 
   * or `do_grayout()` call `SYS_ExpanderControl()`.
   */
  
  if (dx > 0) {
    bank ^= 0x20;
    if (bank & 0x20)
      addrL += 1;
  } else if (dx < 0) {
    bank ^= 0x20;
    if (! (bank & 0x20))
      addrL -= 1;
  }
  if (dy > 0) {
    addrH += 1;
    if (! addrH) {
      addrH = 0x80;
      bank |= 0x10;
    }
  } else if (dy < 0) {
    addrH -= 1;
    if (addrH == 0x7f) {
      addrH = 0xFF;
      bank &= 0xEF;
    }
  }
}

void worm(register fixed_t x, register fixed_t y, fixed_t step, action_t act)
{
  int s;
  x0 = x;
  y0 = y;
  addr = (char*)0x8800;
  ctrl = 0xE8F0u;
  for (s = 0; s != SCREENH / 2; s++)
    {
      fixed_t dx = step;
      fixed_t dy = 0;
      int n = SCREENW - s - s;
      for(;;)
        {
          // execute
          (*act)();
          if (! --n) {
            // end of segment: turn right
            n = dy;
            dy = dx;
            dx = -n;
            n = ((dx) ? SCREENW : SCREENH);
            n = n - s - s - 1;
            if (dx > 0) {
              x0 += dx;
              y0 += dx;
              move_pen(dx, dx);
              break;
            }
          }
          // step
          x0 += dx;
          y0 += dy;
          move_pen(dx, dy);
        }
    }
}


/* math - half square multiplication.
   -- half square multiplication 
      https://forum.gigatron.io/viewtopic.php?p=2632#p2632
   -- fixed point implementation with 8 bit fractional part
      in fixed8.s 
*/

#define NSQUARES (1<<(3+8))

fixed_t squares[NSQUARES+NSQUARES];

extern fixed_t slowmul(register fixed_t a, register fixed_t b);
extern fixed_t sqr(register fixed_t a);
extern fixed_t mul2(register fixed_t a, register fixed_t b);
extern int calc_pixel();
extern int check_calc();

void prep_squares()
{
  int i;
  cprintf("Computing a table of %d squares\n", NSQUARES);
  for(i = 0; i != NSQUARES; i++)
    squares[i] = slowmul(i, i);
  for(i = 0; i != NSQUARES; i++)
    squares[NSQUARES+i] = 0x0800; // overflow
}


/* clock */

static int lastFrame = 0;
static char separator = 0x20;
static int clock0 = 0;
static int clockM = 0;
static int clockH = 0;

void update_clock()
{
  int elapsed = (frameCount - lastFrame) & 0xff;
  clock0 += elapsed;
  lastFrame += elapsed;
  if (clock0 - 3599 >= 0) {
    clock0 = clock0 - 3599;
    clockM += 1;
    if (clockM >= 60) {
      clockH += 1;
      clockM = 0;
      if (clockH >= 24)
        clockH = 0;
    }
  }
  separator ^= 0x1a;
  console_state.fgbg = 0x3f00;
  console_state.cy = 2;
  console_state.cx = 4;
  cprintf("%02d%c%02d", clockH, separator, clockM);
}


/* pixel callback */

void do_pixel()
{
  SYS_ExpanderControl(ctrl);
  *addr = 0x3f;
  *addr = check_calc();
  if (((frameCount - lastFrame) & 0xff) - 60 >= 0)
    update_clock();
}

/* grayout callback */

static char bayer[] = { 0, 2, 3, 1 };
static char levels[] = {0, 1, 2, 3, 1, 2, 3, 4, 2, 3, 4, 5, 3, 4, 5, 6,
                        1, 2, 3, 4, 2, 3, 4, 5, 3, 4, 5, 6, 4, 5, 6, 7,
                        2, 3, 4, 5, 3, 4, 5, 6, 4, 5, 6, 7, 5, 6, 7, 8,
                        3, 4, 5, 6, 4, 5, 6, 7, 5, 6, 7, 8, 6, 7, 8, 9};

void do_grayout()
{
  int level;
  SYS_ExpanderControl(ctrl);
  level = levels[*addr & 63];
  *addr = 0;
  if (level) {
    level = bayer[(y0 & 1) + (y0 & 1) + (x0 & 1)] + level;
    while ((level = level - 3) > 0)
      *addr += 21;
  }
  if (((frameCount - lastFrame) & 0xff) - 60 >= 0)
    update_clock();
}


/* main */

void go(int x, int y, int step)
{
  worm(x, y, step, do_pixel);
  worm(0, 0, 1, do_grayout);
}


int main()
{
  console_clear_screen();
  prep_squares();
  console_clear_screen();
  lastFrame = frameCount;
  for(;;)
    {
      go(-640, -360,  3); // global
      go(-196, -296,  1); // zoom1
      go(-512, -120,  1); // zoom2
      go(-640, -720,  9); // wide
      go(-200,    0,  3); // zoom1
      go(   0, -120,  3); // zoom2
    }  
}
