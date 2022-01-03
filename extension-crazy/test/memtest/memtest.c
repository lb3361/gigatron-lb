#include <stdlib.h>
#include <string.h>
#include <gigatron/console.h>
#include <gigatron/sys.h>


void old_set_bank(int bank)
{
  bank = bank << 6;
  SYS_ExpanderControl( ctrlBits_v5 ^ ((ctrlBits_v5 ^ bank) & 0xc0) );
}

void new_set_bank(int rbank, int wbank)
{
  char bits = ctrlBits_v5;
  SYS_ExpanderControl( ((wbank & 0xf) << 12) | ((rbank & 0xf) << 8) | 0xF0 );
  SYS_ExpanderControl( bits & 0x3f );  // set old bank 0
}

void test_rw(int bank1, int bank2)
{
  char *addr = (char*)0x9000;
  new_set_bank(bank1, bank2);
  cprintf("Reading %d, writing %d\n", bank1, bank2);
  cprintf(" rd %02x, wr %02x, rd %02x\n", *addr, (*addr = 0xaa), *addr);
  new_set_bank(bank2, bank1);
  cprintf("Reading %d, writing %d\n", bank2, bank1);
  cprintf(" rd %02x, wr %02x, rd %02x\n", *addr, (*addr = 0x55), *addr);
}




int main()
{
  int b;
  char *addr;

  cprintf("\fReset test\n--------------------\n");
  old_set_bank(0);
  if (memcmp((void*)0x100, (void*)0x8100, 0x80))
    cprintf("bank0r is not zero");
  b = *(char*)0x200 ^ 0x55;
  *(char*)0x8200 = b;
  if (*(char*)(0x200) != b)
    cprintf("bank0w is not zero");
  *(char*)0x200 = b ^ 0x55;
  cprintf("Press any key\n");
  console_waitkey();
  
  cprintf("\fRead/write test\n--------------------\n");
  test_rw(3,4);
  test_rw(3,12);
  cprintf("Press any key\n");
  console_waitkey();

  cprintf("\fTest banks 1-3 old style\n--------------------\n");
  new_set_bank(0,0);
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
  for (b=1; b != 4; b++) {
    cprintf("Testing bank %d (new way)\n", b);
    new_set_bank(b, b);
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
  
  cprintf("\fTest banks 1-15 new style\n--------------------\n");
  cprintf("Writing patterns, new way\n");
  for (b=1; b != 16; b++) {
    new_set_bank(b, b);
    for (addr = (char*)0x8000; addr; addr += 0x1000) {
      char v = b ^ ((size_t)addr >> 8);
      memset(addr, v, 0x1000);
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
  for (b=1; b != 16; b++) {
    cprintf("Testing bank %d\n", b);
    new_set_bank(b, b);
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
  
  return 0;
}


