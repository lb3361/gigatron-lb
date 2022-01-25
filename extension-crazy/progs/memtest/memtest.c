#include <stdlib.h>
#include <string.h>
#include <gigatron/console.h>
#include <gigatron/sys.h>


#define bankInfo_DEVROM (*(char*)0xb)

void old_set_bank(int bank)
{
  char bits = ctrlBits_v5;
  SYS_ExpanderControl(bits ^ ((bits ^ (bank << 6)) & 0xc0));
}

void new_set_bank(int nbank, int flags)
{
  int code = ((nbank & 0xf) << 12) | ((flags & 0xf) << 8) | 0x0F0;
  SYS_ExpanderControl(code);
#if DEBUG_BANKINFO
  cprintf(" sys(%04x): %02x %02x\n", code, ctrlBits_v5, bankInfo_DEVROM);
#endif
}

int main()
{
  int b;
  char *addr = (char*)0x8100;

  cprintf("\fInitial bits\n--------------------\n");
  cprintf(" ctrlBits=%02x\n", ctrlBits_v5);
  cprintf(" bankInfo=%02x\n", bankInfo_DEVROM);
  
  cprintf("\n\nTest banks 1-3 old style\n--------------------\n");
  cprintf("Writing patterns, old way\n");
  for (b=1; b != 4; b++) {
    old_set_bank(b);
    for (addr = (char*)0x8000; addr; addr += 0x1000) {
      char v = b ^ ((size_t)addr >> 8);
      memset(addr, v, 0x1000);
      if (*addr != v)
        cprintf(" Read/write discrepancy in %04x\n");
    }
  }
  for (b=1; b != 4; b++) {
    cprintf("Testing bank %d (old way)\n", b);
    old_set_bank(b);
    for (addr = (char*)0x8000; addr; addr += 0x1000) {
      char *p = addr;
      char *e = addr + 0x1000;
      char v = b ^ ((size_t)p >> 8);
      while (p != e) {
        if (*p != v) {
          cprintf("[%04x]=%02x (expect %02x)\n", p, *p, v);
          break;
        }
        p++;
      }
      if (p != e)
        break;
    }
  }
  old_set_bank(0);
  for (b=1; b != 4; b++) {
    cprintf("Testing bank %d (new,b0)\n", b);
    new_set_bank(b, 0);
    for (addr = (char*)0x8000; addr; addr += 0x1000) {
      char *p = addr;
      char *e = addr + 0x1000;
      char v = b ^ ((size_t)p >> 8);
      while (p != e) {
        if (*p != v) {
          cprintf("[%04x]=%02x (expect %02x)\n", p, *p, v);
          break;
        }
        p++;
      }
      if (p != e)
        break;
    }
  }
  new_set_bank(0,0);
  old_set_bank(1);
  
  cprintf("\n\nTest banks 1-15 new style\n--------------------\n");
  cprintf("Writing patterns (new, p)\n");
  for (b=1; b != 16; b++) {
    new_set_bank(b,8);
    for (addr = (char*)0x8000; addr; addr += 0x1000) {
      char v = b ^ ((size_t)addr >> 8);
      memset(addr, v, 0x1000);
    }
  }
  new_set_bank(0,0);
  for (b=1; b != 4; b++) {
    cprintf("Testing bank %d (old way)\n", b);
    old_set_bank(b);
    for (addr = (char*)0x8000; addr; addr += 0x1000) {
      char *p = addr;
      char *e = addr + 0x1000;
      char v = b ^ ((size_t)p >> 8);
      while (p != e) {
        if (*p != v) {
          cprintf("[%04x]=%02x (expect %02x)\n", p, *p, v);
          break;
        }
        p++;
      }
      if (p != e)
        break;
    }
  }
  for (b=1; b != 16; b++) {
    cprintf("Testing bank %d (new, p)\n", b);
    new_set_bank(b,8);
    old_set_bank(b); // mess with ctrlBits - shouldn't change
    for (addr = (char*)0x8000; addr; addr += 0x1000) {
      char *p = addr;
      char *e = addr + 0x1000;
      char v = b ^ ((size_t)p >> 8);
      while (p != e) {
        if (*p != v) {
          cprintf("[%04x]=%02x (expect %02x)\n", p, *p, v);
          break;
        }
        p++;
      }
      if (p != e)
        break;
    }
  }
  new_set_bank(0,0);
  old_set_bank(1);
  return 0;
}


