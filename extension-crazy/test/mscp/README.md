# MSCP

Marcel's Simple Chess Program is a simple but surprisingly capable
chess program written in C by Marcel van Kervinck. The compiled
version of MSCP requires about 56KB to run. This is problematic
because the video buffer takes nearly 20KB of the 64KB Gigatron
address space.

Using memory banking from C is difficult. However, thanks to the crazy
expansion board, we can displace the video buffer into a different
memory bank, freeing the full address space.  This is easily achieved
with the [libconb](../../glcc/libconb) library which overrides the
low-level primitives of the GLCC console library to precisely displace
the console memory into bank 14...

For the first time, MSCP runs on a real Gigatron. It does not play
very fast and it does not use the opening book because, absent a
Gigatron OS, there is no way to load the file "book.txt" from the SD
card. But it plays...

This also works with the normal v5a ROM but wastes time because
we could run the vCPU instead of sending pixels to the screen.
Note that the program spends a substantial time initializing
tables at the beginning. Be patient.
