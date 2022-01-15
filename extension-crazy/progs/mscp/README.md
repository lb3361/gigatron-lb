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
  
* The third version `mscp_h.gt1` uses library [libcon_h](../libcon_h)
  which doubles both the horizontal and vertical video resolution,
  yielding 320x240 pixels able to display 30 lines of 52 characters.

Both `mscp.gt1` and `mscp_n.gt1` can work with the normal ROM v5a.
This wastes time because we could run the vCPU instead of sending
pixels to the screen. However `mscp_h.gt1` only runs with 
the patched ROM.


I was happy to get Marcel's chess program running on a real Gigatron.
However, to play against the Gigatron, one has to be willing to wait 
a couple minutes between each ply...



