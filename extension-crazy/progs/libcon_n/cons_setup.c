#include <stdlib.h>
#include <string.h>
#include <gigatron/console.h>
#include <gigatron/libc.h>
#include <gigatron/sys.h>

static void console_exitm_msgfunc(int retcode, const char *s)
{
  if (s) {
    static struct console_state_s rst = {3, 0, 0, 1, 1};
    console_state = rst;
    console_state.cy = console_info.nlines;
    console_print(s, console_info.ncolumns);
  }

  {
    /* Halting code (flash pixel using the proper screen) */
    char c = 0;
    char *row = (char*)(((*(char*)0x100)|0x80) << 8);
    SYS_ExpanderControl(0xe1f0u);
    SYS_ExpanderControl(ctrlBits_v5 & 0x3f);
    while (1)
      row[(char)retcode] = ++c;
  }
}

void _console_setup(void)
{
  /* TODO: Test availability of the 512KB extension */

  // Display even pixels from page 14/15
  // and odd pixels from page 12/13
  SYS_ExpanderControl(0x0ee0u);
  _exitm_msgfunc = console_exitm_msgfunc;
  console_clear_screen();
}
