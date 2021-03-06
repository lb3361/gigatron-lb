
![PCB image](images/Render.jpg)

# Gigatron RAM and IO expansion (v6)


This is a 128KB RAM and IO extension that is compatible enough with [Marcel's latest design](https://forum.gigatron.io/viewtopic.php?f=4&t=64&start=50#p804) to boot simple programs from a SD card connect to the SPI0 bus. Compared to Marcel's design, this version has support for the [various SPI modes](https://en.wikipedia.org/wiki/Serial_Peripheral_Interface#Clock_polarity_and_phase) (CPOL, CPHA) and has support for banking the upper half of the zero page for [reasons discussed here](https://forum.gigatron.io/viewtopic.php?p=2014#p2014).

Like my [earlier design](https://forum.gigatron.io/viewtopic.php?p=2011), this extension board has a convenient header to plug one [a cheap SD breakout board](https://www.amazon.com/gp/product/B07MTTLF75). However, its implementation is substantially different. Instead of relying on TSSOP 74x00 chips surface mounted on the reverse side of the card, this functionally richer version relies on two ATF22V10C GALS just like in the eighties and a single 74HCT244 to gate the data bus. Since I wanted to use DIP sockets to easily reprogram the GALs, it would have been silly to hide a single 74HCT244 on the bottom side of the board. This makes the board a bit bigger (80x50mm instead of 50x55mm). I am still thinking of a compact CPLD based version (see the `extension-compact` directory) but there is value in the retro look.

## 1 - Building and installing the expansion board.

### 1.1 - PCB

You can easily order PCBs by giving `Gerber_PCB-v6.zip` to your preferred provider. 
I got mine from JLCPCB (five boards for $3.10 plus shipping).
If you want to change things, investigate the `easyeda` subdirectory.

### 1.2 - Components

The list of components can be found in file `BOM.csv`.
The trickiest part is to select the pin headers that are located on the reverse side of the board and should plug into the RAM socket on the gigatron motherboard. Most pin headers are too thick. The best soluton I found were relatively expensive Preci-Dip headers with a thin side and a thick side. If you have a Digi-Key account, you can use [this link](https://www.digikey.com/BOM/Create/CreateSharedBom?bomId=8557252) to see exactly what I ordered from them.

### 1.3 - Programming the GALs

The ATF22V10C GALs are supported by the same cheap XGecu TL866IIplus I use to program the Gigatron ROM. The files `cupl/GAL1.pld` and `cupl/GAL2.pld` describe the logic equations. You do not need to compile them with Atmel's finicky [WinCUPL](https://www.microchip.com/en-us/products/fpgas-and-plds/spld-cplds/pld-design-resources) program because the repository contains the two output files `cupl/GAL1.jed` and `cups/GAL2.jed` that must be programmed into the GALs. This can be done using XGecu's Windows software or using [minipro](https://gitlab.com/DavidGriffith/minipro) on Linux:
```
    $ minipro -p atf22v10c -w GAL1.jed  ### for the first GAL (the south one)
    $ minipro -p atf22v10c -w GAL2.jed  ### for the second GAL (the north one)
```
Mark the GALs because you do not want to swap them.


### 1.4 - Soldering the components

This is not going to be too hard for those who have already built their Gigatron. It is wise to use sockets for the two GALs (in case you want to reprogram them) and the SRAM. Start with the capacitors. Then plug the bottom headers on a spare IC socket to make sure they have the right position and solder them on the back side of the board. Then solder the SRAM socket, the GAL sockets, the top side headers, the diodes, the resistors, and the 74HCT244.

### 1.5 - Installing the board

Do not forget to wire the A15 point on the Gigatron board to the A15 header on the board. I am using little horizontal 1x1 pin headers on both the Gigatron board and the expansion board, connected by a short breadboard wire.


## 2 - What works

The 128K RAM extension should be detected by the Gigatron ROMv4, ROMV5a, and DevRom. Many programs such as TinyBasic or MSBasic can use 64K of them.

Booting from the SD requires the DevRom because of a one byte error in ROMv5a. Note that this is a very experimental code. It only works with a FAT32 formatted SDCard and only boots the program named `SYSTEM.GT1` found in the first partition. I was able to boot short program such as Blinky or Hello World by renaming them `SYSTEM.GT1`. Something seems broken for longer programs.

## 3 - Programming with the expansion board

Following Marcel's design, this board adds a new native instruction `ctrl` to the Gigatron that smartly repurposes a nonsensical opcode that tries to simultaneously read and write the RAM. This instruction is supported by the assembler and can be found in a couple places in the ROM. Its arguments are similar to the arguments of a store instruction, but without the brackets as the address bus will be used to carry information. 

Here how the ROMv5a initializes Marcel's extension board:
```
# Setup I/O and RAM expander
ctrl(0b01111100)                # Disable SPI slaves, enable RAM, bank 1
#      ^^^^^^^^
#      |||||||`-- SCLK
#      ||||||`--- Not connected
#      |||||`---- /SS0
#      ||||`----- /SS1
#      |||`------ /SS2          # In this board, /SS2 is repurposed as /CPOL
#      ||`------- /SS3          # In this board, /SS3 is repurposed as /ZPBANK
#      |`-------- B0
#      `--------- B1
# bit15 --------- MOSI = 0
```
Note that only native code can use the `ctrl` instruction.
However VCPU programs can make use of two SYS extensions 
that can easily be found in the ROM listing.

* `SYS_ExpanderControl_v4_40` to use `ctrl` with the contents of `vAC`.
* `SYS_SpiExchangeBytes_v4_134` to send/receive bytes on a SPI channel.

### 3.1 - Memory banking

In Marcel's original design, the 128K of memory are divided in four banks of 32K. 
Bank 0 is always accessible at addresses 0x0000 to 0x7fff (low addresses)
The bits `B1` and `B0` of the `ctrl` instruction define which bank is accessible at addresses 0x8000 to 0xffff (high addresses).
For instance, selecting bank 0 (`B1=0,B0=0`) emulates a 32K Gigatron by aliasing the low and high memory addresses.
The default setup, bank 1 (`B1=0,B0=1`) emulates a 64K Gigatron by providing a fresh 32K of memory in the high addresses.
Banks 2 and 3 remain available to programs that know how to swap stuff.

One of the ideas discussed by Marcel was to hide the Gigatron OS in banked memory so that programs that did know its existence
would be able to run unfazed. However this is difficult to achieve because the VCPU code and the GCL language is very 
dependent on placing variables and subroutine addresses in page zero. The new VCPU instruction `CALLI` was specifically added
to avoid cluttering page zero with subroutine addresses. But what to do with the variables?  This board provides a solution
by using the memory banking system to swap what is visible in the upper part of page zero.

When the `/ZPBANK` bit is set to `1`, the board works exactly as Marcel's. However, when `/ZPBANK` is set to `0`, 
the address regions `[0080-00ff]` and `[8080-80ff]` are swapped. As a consequence, the memory visible at 
addresses `[0080-00ff]` comes from the bank specified by the bits `B1` and `B0` whereas the memory 
visible at addresses `[8080-80ff]` always comes from bank 0.  One has to be careful because the program stack
also lives in the upper part of the page zero. But this is going to change with at67's new ROM that can locate
the stack anywhere in the Gigatron memory.

Here are two ways to use this feature:

* The Gigatron OS could provide a VCPU entry point in 0x8080. Calling this subroutine would switch to bank 3 in both high memory and upper zero page (`B1=1`, `B0=1`, `/ZPBANK=0`), save the stack pointer, setup a new stack, and call the appropriate OS routine in the upper address area. When the routine returns, it would restore both the stack pointer and the initial bank. The OS routine is then free to use any zero page location in range 0x81-0xff with confidence that nobody is going to see them or modify them between calls. 
 
* Two programs could simultaneously be active in pages 1 and 2. Each of them could rely on a private set of zero page variables in 0x81-0xff. Each of them could have a private stack. One can switch from one program to the other by simply swapping the banks and refreshing the screen.


### 3.2 - SPI

In Marcel's design, SPI transactions are performed by first selecting a slave by setting one of the `/SS[0..3]` bits to zero using `SYS_ExpanderControl_v4_40`, then calling the `SYS_SpiExchangeBytes_v4_134` function that bangs the `SCLK` and `MOSI` bits to send bits to the slave device and reads the `MISO` lines to receive bits from the slave device. Reading the `MISO` lines is performed with a horrible trick: when the clock line `SCLK` is set to `1`, reading from the memory address does not return what is at the specified address, but returns a byte whose low nibble contains the MISO information from the four SPI channels. The code does not even try to select the MISO line corresponding to the selected channel. It instead assumes that the lines corresponding to the inactive channel are set to zero by a pull down resistor, and it reads a 1 if any of them is high.  This is problematic because, according to the specifications, using a SD card in SPI mode requires a pull up resistor on the MISO line...

This board differs from this design in three ways.

* Reading from address `0000` with `SCLK` is 1 returns the MISO information. Reading from any other address shows what is in memory regardless of `SCLK`. This is convenient because it allows us to do useful things when `SCLK` is 1.

* The board uses pull up resistors on both the `MISO0` and `MISO1` lines. Diodes make sure that two overeager devices do not cause a short by driving MISO at the same time. The GAL2 then makes sure that only the signal corresponding to the selected device makes it to the bus when the program reads address zero with `SCLK` set.

* Finally the clock signal sent to the device is not `SCLK` but `SCK` which is a XOR of `SCLK` and `CPOL`. This does not change anything when `/CPOL` has its default value 1.  Exchanging bytes with `SYS_SpiExchangeBytes_v4_134` follows [SPI mode 0 (CPHA=0,CPOL=0)](https://en.wikipedia.org/wiki/Serial_Peripheral_Interface#Mode_numbers). Setting `/CPOL` to 0 inverts the clock signal, implementing SPI mode 2 (CPHA=0,CPOL=0). Modes 1 and 3 are subtly different because asserting the clock now means that both master and slave should present a bit on respectively the MOSI and MISO lines, to be sampled when the clock is deasserted. To achieve this the bit banging routine should start each byte by inverting `/CPOL` instead of setting `SCLK` to 1. Each of the eight bits is then exchanged by writing a bit on `MOSI`, setting `SCLK`, reading a bit from `MISO`, resetting `SCLK`. For the last bit, while resetting `SCLK`, one should also invert `/CPOL` at the same time. This restore the original `/CPOL` and leaves the clock in its deasserted state.

That all for today.
