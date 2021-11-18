# Crazy expansion board for the Gigatron

The goal of this expansion board is to provide an easy way to experiment with crazy expansion ideas for the Gigatron.
This is work in progress. And this is work that may never be finished.


The board attaches to the Gigatron like boards that combine the RAM & IO expansion with a video repeater. 
It attaches to both the SRAM socket and the OUT register socket, and also needs a wire to the A15 pin.

The core of the board is a ATF1508AS CPLD with a 100 pins package and a fast CY7C1049G 512KB stattic ram.
The CPLD essentially interposes itself between the SRAM socket and the actual memory. This SRAM is so
fast that the CPLD can perform multiple read and writes during each Gigatron cycle. One of them
can be used to serve the Gigatron memory requests, the other ones can be used for many purposes
such as generating the video signal while keeping the Gigatron CPU free for other tasks,
possibly with a higher resolution than the normal Gigatron.
Of course all depends on the CPLD program that one loads on this board. The idea is to start with
a simple program that replicates the functionality of a normal RAM & IO expansion board, then
to add the possibility to bank all 512KB of memory --Hello Gigatron 512K,--, then to recreate
the functionality of a video repeater, then to authorize higher resolutions, etc...

The ATF1508 CPLD is not very powerful by today's standards. It can be compared to having
a dozen GAL chips of the kind I use for the RAM & IO expansion board. Its main advantage
is that it works with a 5v power supply. These chips are in fact clones of the old Altera MAX 7000 
that can be programmed in Verilog using the free Intel Quartus tool (version 13). A program called 
`pof2jed` converts the Altera files into files than can be downloaded into the ATF1508 using
the moderately priced Atmel ATDH1150 USB download cable. 
See http://forum.6502.org/viewtopic.php?f=10&t=5948 for more pointers.

![Board diagram](images/diag.png)
