# MSCP

Marcel's Simple Chess Program is a simple but surprisingly capable
chess program written in C by Marcel van Kervinck. The compiled
version of MSCP requires about 56KB to run. This is problematic
because the video buffer takes nearly 20KB of the 64KB Gigatron
address space. Using memory banking from C is difficult. However,
thanks to the crazy expansion board, we can displace the video buffer
into a different memory bank, freeing the full address space.

* The first version of this program, `mscp.gt1` achieves this using the
  [libcon_b](../libcon_b) library which overrides the low-level
  primitives of the GLCC console library and displace the video buffer
  into bank 14. 

* The second version of this program `mscp_n.gt1` uses a different 
  library named [libcon_n](../libcon_n) which not only displaces the
  video buffer but enables double horizontal resolution to display
  up to 52 characters per line. 

Both `mscp.gt1` and `mscp_n.gt1` can work with the normal ROM v5a.
This wastes time because we could run the vCPU instead of sending
pixels to the screen.

For the first time, Marcel's chess program runs on a real Gigatron.
There are caveats. You have to be patient because the Gigatron is not
a fast machine.  In addition, absent a Gigaton OS, the program cannot
load its opening library. But it plays!




