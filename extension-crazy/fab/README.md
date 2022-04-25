
# Fabrication

# Fabrication


# Building the boards

Assembling surface mount component is challenging for a hobbyist like
me. The most practical and economical approach at this point is to 
contact Hans61 on the forum because he now has mastered his reflow oven.
I only have good things to say about HansPCB ;-)

The early versions of the board were build by relying on JLCPCB SMT
assembly service as much as possible. Alas, in these times of chip
shortage, JLCPCB does not always have the necessary chips in
stock or sells them for unreasonable prices. Therefore I often had
finish the board with hand soldering.  Hand-soldering the 8 pins PLL
chip is quite easy with the "lots of flux" method. Hand-soldering the
44 pins SRAM is difficult but possible. Hand-soldering the CPLD is well
beyond my skills, which is annoying because its availability on JLCPCB
is spotty and they tend to offer it with a significant price markup.

Some boards have a solder jumper to determine whether to power the PLL
chip with +5v or +3.3v. For reasons still unknown, it seems that +5v
works more reliably.

The manufacturing files found in this directory are upside down. What
they claim is the top-side is in fact the bottom side of the board
which contains the SMT parts. I This tends to work better with the
JLCPCB process because asking them to assemble the top side eliminates
the need to mirror the coordinates of the pick-and-place file (do we
do it? do they do it?, etc).  When the half-assembled boards arrive,
one has to hand-solder the missing parts, the 74HCT377 dip chip, the
connectors, and the leds.

# Programming the CPLD

Before programming the CPLD, it is wise to test that the board does
not have shorts. This is best achieved by measuring the resistance
between the ground GND and both the VCC (+5v) and V33 (+3.3v) signals
that are available in several parts of the board. It is also wise to
check that there are no shorts between the legs of the hand-soldered
chips. 
The most reliable the
[xc3sprog](https://github.com/matrix-io/xc3sprog) program with a
[Diligent HS2 cable](https://digilent.com/shop/jtag-hs2-programming-cable/). 

This works well because `xcs3prog` works around JTAG pecularities of 
the XC9500XL chip. As long as one uses this particular program,
I believe that one could replace the Diligent cable
by any cheap [FTDI232H adapter](https://ftdichip.com/products/um232h-b)
supported by xc3sprog. The cautious way to program the CPLD is to
provide +5v power to any VCC pin, check that the V33 pins show a
stable 3.3v, connect the cable, and type

```
xc3sprog -c jtaghs2 -v rtl/ise-main/main.jed
```
A less cautious but far simpler way is to simply program the board installed on the
Gigatron: power up the Gigatron, issue the programming command which
crashes the Gigatron but programs the chip, and power-cycle to reset
the Gigatron. I have done that dozens of times without damage.

# Programming the patched ROM

The patched dev rom is available in the 
[rom directory of this repository](https://github.com/lb3361/gigatron-lb/tree/main/extension-crazy/rom).
The easiest way is to use a [TL866ii plus](https://www.amazon.com/s?k=tl866ii+plus+programmer) programmer,
either with its proprietary software or with the open source 
[minipro](https://gitlab.com/DavidGriffith/minipro) software. 
For instance, to program a a Microchip AT27C1024 one-time-programmable rom, type:
```
	minipro -p 'AT27C1024@DIP40' -w dev.rom -y -s
```
Other parts are the AMD 27C1024 and the ST Microelectronics M27C1024 EPROMs than 
can be found on ebay or amazon. You might need an UV EPROM eraser as second hand
chips rarely come clean. I do not have direct experience, but anything
faster then 120ns should work.
