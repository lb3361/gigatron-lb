# LIBCONB

This library relocates the screen into page 14
and implements a basic GLCC console. This 
potentially frees all the 64KB of the normally
mapped banks 0 and 1.

The code assumes that the running program
does not manipulate the extended banking
or merely expects it to be reset to bank 0
after each console library call.
