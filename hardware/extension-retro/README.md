
![PCB image](images/Render.jpg)

# Gigatron RAM and IO expansion (v6)


This is a 128KB RAM and IO extension that is compatible enough with [Marcel's latest design](https://forum.gigatron.io/viewtopic.php?f=4&t=64&start=50#p804) to boot simple programs from a SD card connect to the SPI0 bus. Compared to Marcel's design, this version has support for the [various SPI modes](https://en.wikipedia.org/wiki/Serial_Peripheral_Interface#Clock_polarity_and_phase) (CPOL, CPHA) and has support for banking the upper half of the zero page for [reasons discussed here](https://forum.gigatron.io/viewtopic.php?p=2014#p2014).

Like my [earlier design](https://forum.gigatron.io/viewtopic.php?p=2011), this extension board has a convenient header to plug one [a cheap SD breakout board](https://www.amazon.com/gp/product/B07MTTLF75). However, its implementation is substantially different. Instead of relying on TSSOP 74x00 chips surface mounted on the reverse side of the card, this functionally richer version relies on two ATF22V10C GALS just like in the eighties and a single 74HCT244 to gate the data bus. Since I wanted to use DIP sockets to easily reprogram the GALs, it would have been silly to hide a single 74HCT244 on the bottom side of the board. This makes the board a bit bigger (80x50mm instead of 50x55mm). I am still thinking of a compact CPLD based version (see the `extension-compact` directory) but there is value in the retro look.

## Building and installing the expansion board.

### PCB

You can easily order PCBs by giving `Gerber_PCB-v6.zip` to your preferred provider. 
I got mine from JLCPCB (five boards for $3.10 plus shipping).
If you want to change things, investigate the `easyeda` subdirectory.

### Components

The list of components can be found in file `BOM.csv`.
The trickiest part is to select the pin headers that are located on the reverse side of the board and should plug into the RAM socket on the gigatron motherboard. Most pin headers are too thick. The best soluton I found were relatively expensive Preci-Dip headers with a thin side and a thick side. If you have a Digi-Key account, you can use [this link](https://www.digikey.com/BOM/Create/CreateSharedBom?bomId=8557252) to see exactly what I ordered from them.

### Programming the GALs

The ATF22V10C GALs are supported by the same cheap XGecu TL866IIplus I use to program the Gigatron ROM. The files `cupl/GAL1.pld` and `cupl/GAL2.pld` describe the logic equations. You do not need to compile them with Atmel's finicky [WinCUPL](https://www.microchip.com/en-us/products/fpgas-and-plds/spld-cplds/pld-design-resources) program because the repository contains the two output files `cupl/GAL1.jed` and `cups/GAL2.jed` that must be programmed into the GALs. This can be done using XGecu's Windows software or using [minipro](https://gitlab.com/DavidGriffith/minipro) on Linux:
```
    $ minipro -p atf22v10c -w GAL1.jed  ### for the first GAL (the south one)
    $ minipro -p atf22v10c -w GAL2.jed  ### for the second GAL (the north one)
```
Mark the GALs because you do not want to swap them.


### Soldering the components

This is not going to be too hard for those who have already built their Gigatron. It is wise to use sockets for the two GALs (in case you want to reprogram them) and the SRAM. Start with the capacitors. Then plug the bottom headers on a spare IC socket to make sure they have the right position and solder them on the back side of the board. Then solder the SRAM socket, the GAL sockets, the top side headers, the diodes, the resistors, and the 74HCT244.

### Installing the board

Do not forget to wire the A15 point on the Gigatron board to the A15 header on the board. I am using little horizontal 1x1 pin headers on both the Gigatron board and the expansion board, connected by a short breadboard wire.


## What works

The 128K RAM extension should be detected by the Gigatron ROMv4, ROMV5a, and DevRom. Many programs such as TinyBasic or MSBasic can use 64K of them.

Booting from the SD requires the DevRom because of a one byte error in ROMv5a. Note that this is a very experimental code. It only works with a FAT32 formatted SDCard and only boots the program named `SYSTEM.GT1` found in the first partition. I was able to boot short program such as Blinky or Hello World by renaming them `SYSTEM.GT1`. Something seems broken for longer programs.

## Programming with the expansion board

Following Marcel's design, this board adds a new native instruction `ctrl` to the Gigatron that smartly repurposes a nonsensical opcode that tries to simultaneously read and write the RAM. This instruction is supported by the assembler and can be found in a couple places in the ROM. Its arguments are similar to the arguments of a store instruction, but without the brackets as the address bus will be used to carry information. 

Here how the ROM initializes the extension board:
```
# Setup I/O and RAM expander
ctrl(0b01111100)                # Disable SPI slaves, enable RAM, bank 1
#      ^^^^^^^^
#      |||||||`-- SCLK
#      ||||||`--- Not connected
#      |||||`---- /SS0
#      ||||`----- /SS1
#      |||`------ /SS2
#      ||`------- /SS3
#      |`-------- B0
#      `--------- B1
# bit15 --------- MOSI = 0
```

TO BE CONTINUED
