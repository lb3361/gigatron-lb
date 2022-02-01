# Mandelbrot

This is a rewritten version of the Mandelbrot program in 320x240
resolution. I had to change the fixed point format to have 8 bits of
fractional part because one cannot otherwise separate the pixels for
the zoomed displays. Although it has been rewritten in vCPU + C, it
remains quite close to the original. I also use qwertyface's
multiplication trick to great effect because we now have plenty of
memory to store a table of squares.

Speedwise, we have to compute four times more pixels per screen, but
the Gigatron 512k is about four times faster than a standard Gigatron
in default mode 1. The big speedup remains qwertyface's multiplication
trick which goes about five times faster than the old code in this
application (big table, no overflow checks, no fallback to normal
multiplication.)
