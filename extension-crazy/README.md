# Crazy expansion board for the Gigatron

The goal of this expansion board is to provide an easy way to
experiment with all kind of hardware hacks for the Gigatron.
Hans61's help was invaluable to get this idea off the ground.
Yet this is still very experimental. Work in progress.

## 1. Idea

The core of the board is a XC95144XL CPLD with a 100 pins package
mediating access to a 512KB static RAM that is fast enough to perform
multiple reads or writes during a single Gigatron cycle. For instance,
in a single cycle, one could serve the Gigatron memory requests and
fetch pixels from the memory to drive the VGA output. Of course, and
this is the point of this board, we can easily change what the board
does by reprogramming the CPLD.

This CPLD is not very powerful by today's standards. The datasheet
describes it as roughly comparable to eight 54v18 GALs. Its main
advantage are its 5v-tolerant I/O pins and the free availability of
its software development suite. Another possible choice was the
ATF1508 which is a true 5v part and is slighlty cheaper. Alas there
are less free tools available to fully exploit the ATF1508...

![Board diagram](images/diag.png)

The board also contains a CY2302 zero delay PLL that takes the 6.25MHz
Gigatron clock and generates two additional clocks at 2x and 4x the
frequency with aligned phases. These fast clocks can be used to drive
the SRAM at a faster rate than the Gigatron CPU.

The last chip is a 74LVC244 buffer that sits between the 8 low bits
`A0..7` of the Gigatron address bus and the `RA0..7` wires that
connect the CPLD to the 8 low bits of the SRAM address bus. When the
74LVC244 outputs are active, the Gigatron `A0..7` go into both the
SRAM address bus and the CPLD ports `RA0..7`. When the 74LVC244
outputs are tri-stated, the CPLD has exclusive control of the SRAM
address bus. Of course one has to be careful to prevent bus contention
on these address lines.  This was useful to save CPLD I/O pins and
turned out to be trickier than I expected.

![Schematics](Schematics.pdf)

## 2. Layout

The board layout places all the SMT components out-of-sight on the
back side of the board. The visible side contains two connectors for
SPI devices using the SD Card breakout pinout, a JTAG connector to
program the CPLD, an expansion connector, and a good old 74HCT377 near
the OUT register because the VGA resistors are matched to that specific chip.

The v8d version of this board no longer relies on a SD card breakout but 
features a SD card socket. Since the CPLD already works in 3.3v, there
is no need for level translators. This changes gives more than enough 
space on the board to implement the analog part of the 8 bit audio output
and provide a new audio connector.

![Layout](images/layout.png)

![Front view](images/front.jpg)

![Back view](images/back.jpg)

Building such boards is discussed in directory [fab](./fab).


## 3. Usage

This describes the current CPLD programming.

This board is backward compatible with the latest version "dual drive"
of the [GAL based extension board](../extension-retro).
The following text only describes the features that are specific to
this board.  Many of these features can be used with the regular
Gigatron ROM.  However things get better when one uses the patched ROM
found in the [rom](./rom) directory.


## 3.1. Extended banking

We want to use all 512K of memory while remaining maximally compatible
with existing software and allowing fast bank switches. The [normal
ctrl codes](https://forum.gigatron.io/viewtopic.php?f=4&t=331) that
`SYS_ExpanderControl` saves in the `ctrlBits_v5` memory location
(0x1f8) only support four banks. Yet, banking-aware software expects
to save and restore a banking configuration by copying and
manipulating `ctrlBits_v5`.

The current CPLD program defines a new four bit banking register NBANK
and a flag NBANKP. They can be set using an [extended
ctrl code](https://forum.gigatron.io/viewtopic.php?f=4&t=331) with
device address 0xF. Register NBANK is read from the top four bits of
the code, flags NBANKP from the following bit:
```
  SYS_ExpanderControl( ((NBANK&7)<<12) | ((NBANKP&1)<<11) | 0xF0 );
```
The flags define two modes of operation:

* When flag NBANKP is not set, everything works as usual except that
  selecting bank 0 with the normal banking bits actually maps bank
  NBANK in the address range [0x8000-0xffff].

  This mode is convenient to access a high bank in a manner that
  will not confuse code that is unaware of the existence of the 512k board.
  Such code can still temporarily map a different bank and then 
  restore the high bank masquerading as bank 0 using only 
  the normal control codes. Zero page banking also works as usual, 
  essentially swapping address ranges [0x80-0xff] and [0x8080-0x80ff].

* When flag NBANKP is set, bank NBANK is mapped in [0x8000-0xffff]
  regardless of the normal control bits. Meanwhile the low
  addresses [0x0000-0x7fff] shows bank 0 as usual. If zero page
  banking is enabled, showing the bank specified by
  the normal banking bits in [0x80-0xff]. This mode provides a quick 
  way to temporarily map any bank, do something, and almost immediately 
  restore the previous state by resetting the extended 
  banking bits to their previous value.

The function `SYS_ExpanderControl` implemented by the patched ROM
recognizes these extended banking codes and saves them into the six
high bits of memory location 0xb (ex `videoModeC`).

Both modes are exercised by the [memory test program](progs/memtest).

*Warning: I am thinking of simplifying this (2025)*


## 3.2. Video snooping

During each Gigatron cycle, the board has time to perform a read or write cycle
to serve the Gigatron and two additional read cycles. These extra read cycles
are used to feed pixels to the video output in a manner that is compatible
with the Gigatron operation.

* Native instructions that target the output register `OUT` only change
  bits 6 and 7 of the output register, which respectively represent the
  horizontal and vertical sync signals. The other bits are discarded.

* When a native instruction targeting the output register reads its
  input from a non-page-zero location in memory, the memory
  address is recorded and video snooping starts. During each Gigatron cycle,
  including the current one, pixel data read at the recorded address is
  fed into bits 0..6 of the output register, and the address is incremented.
  Any other output instruction stops this process.

This process is compatible with the existing ROM. Each of the
successive `or([Y,Xpp],OUT)` instruction that used to send
pixels to the output register now restarts the snooping process
at address `[Y,X]`. The final instruction of a scanline, `ld($c0,OUT)`
then stops the snooping process.

This scheme becomes a lot more interesting with the patched ROM
because it issues a single `or([Y,Xpp],OUT)` instruction at the
beginning of the scanline and a single `ld($c0,OUT)` instruction at
the end of the scanline. In the meantime, it executes vCPU
instructions while the video snooping logic feeds the successive
pixels into the VGA port.


## 3.3. Video banking and double resolution

Unlike the normal Gigatron, the video snooping logic does not only
read pixels from bank 0 or from the bank currently accessed by the CPU.
Pixels are read from a bank that depends on the contents of a four-bits
video banking register and also on the high bit of the scanline page number
in the Gigatron video Table located at address 0x100.

Assume the banking register contains bits `XXYZ` and assume the high
bit of the page number in the video table is `H`.  The video snooping logic
in fact reads two pixels during each Gigatron cycle, one from page `XXYH`
and another from page `XXZH` and feed them to the output register
at twice the Gigatron clock frequency.

* When bits `Y` and `Z` of the video banking register are identical,
  the two identical pixels combine into pixels with the usual horizontal
  Gigatron resolution of 160 pixels.

* When bits `Y` and `Z` are different, we obtain double resolutio
  scanlines with 320 pixels. Even and odd pixels are read from
  the same address in different banks `XXYH` and `XXZH`.

In addition to this double horizontal resolution, the patched ROM
provides means to double the vertical resolution. Each of the 120
ordinary lines of the Gigatron display is in fact scanned four times
using the same page number obtained from the video table. The
patched ROM optionally increments the page number
betweeen the second and third line. This means that each
entry of the video table at location 0x100 now describes
two lines located in successive pages in memory.

The video bank register can be written with an extended ctrl code
```
  SYS_ExpanderControl(  (XXYZ << 8) | 0xE0 );
```
The patched ROM feature that increments the page number is
enabled when bit 0 of location 0x0b is set (ex videoModeC location).


## 3.4. Extended audio

The center pin of the PWM header (or the XIN3 pin of the extension
header on earlier versions boards) outputs an average voltage in range
0.0 to 3.3V that depends linearly on the upper byte of the last
extended control code for device 13.  In other words,
```
  SYS_ExpanderControl( (x<<8) | 0XD0 );
```
sets an average voltage of x * 3.3 / 255 volts. This is achieved with
``bit-reversed`` pulse modulation scheme whose noise goes into
frequencies above 50kHZ.

When the Gigatron sound output is active, the patched ROM forwards
all 8 bits of the sound sample to this pulse modulation output.
The v8d board then applies a high pass filter to remove the DC component
and an active low pass filters that cuts frequencies above about 4KHz,
which is needed because the Gigatron only updates the samples at about 8kHz.


## 3.5. New native opcodes

This is still a very experimental development. 
See https://forum.gigatron.io/viewtopic.php?p=2874#p2874.
