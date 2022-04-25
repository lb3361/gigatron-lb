# Custom ROM 

This version of the v5a development ROM contains a modified version of
the main loop that takes advantage of the new expansion board to
implement audio and video.

The patches in file `Core/dev.asm.py` are selected when the
Python variable `WITH_512K_BOARD` is set to `True`.
Additional changes to the reset program `../progs/reset512/Reset.gcl`
detect the presence of the expansion board.


# 1. Compiling

The compilation depends on the applications located in the main rom directory.
You need to compile with the following incantation:
```
$ make APPS=/path/to/gigatron-rom/Apps
```

# 2. Video

The patched Gigatron loop only executes an `ora([Y,X++],OUT)` instruction
to send the first pixel of each scanline and execute vCPU instruction
during the remaining cycles of the scanline. This single instruction
triggers the video snooping logic which sends the successive pixels
until the Gigatron executes the `ld(syncBits,OUT)` instruction that
marks the end of the scanline.

The updated loop always shows pixels for the A and C scanlines.
Whether pixels are shown for the B and D scanlines is determined by
the variables `videoModeB` (0x0a) and `videoModeD` (0x0c). It does not
support the Gigatron video mode 3 which displays only the A scanlines.
Video mode 2 is shown instead. Changing the video mode no longer
changes the execution speed of vCPU programs.

The variable `videoModeC` (0x0b) is now used to contain flags. Only
one such flag is defined at the moment. Setting bit 0 of `videoModeC`
enables double vertical resolution. When this bit is set, instead of
obtaining pixels from the same page for all four scanlines A, B, C,
and D, the Gigatron automatically increments the page number before
processing scanlines C and D.


# 3. Audio

When audio is active, the patched Gigatron loop also forwards 
the 6 bits audio sample to the pulse modulation logic
using instruction `ctrl(Y,0xD0)`. This happens shortly
after starting the C scanlines, in addition to the normal
code that combines the upper 4 bits of the audio sample
and the blinkenlights into the extended output register.


# 4. Detecting the ROM

The presence of the patched ROM is easy to detect because the values
stored in variable `videoModeB` (0xa) and `videoModeD` (0xc) are now
always greater than 0xfc.  The following test can therefore be used:
```
      if ( (0xfc & *(char*)0xa) == 0xfc)
         { /* we have a patched rom */ }
```
