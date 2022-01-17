# A whole Gigatron in a 100 pins XC95144XL

Bmwtcu mentionned in a [comment](https://forum.gigatron.io/viewtopic.php?p=2826#p2826) 
that a whole Gigatron barely fits in a XC95144XL, which is a nice way to understand
the size of this part.

This directory contains my attempt to replicate bmwtcu's comment.  I
was able to fit the Gigatron in the same part as the one used in the
expansion board and using an external ROM, an external RAM, and also
an external 74HCT595 to implement the serial input register.  I was
not able to make it fit inside the CPLD. Another chip is probably
needed to adjust the voltage levels of the output register for the VGA
monitor.

The Xilinx tool tend to use a lot of resources to implement the ALU's
adder. One has to control the space/speed trade-off with precise
incantations in the TCL file `ise-gigatron/gigatron.tcl` that
generates the Xilinx ISE. 
```
   project set "Implementation Template" "Optimize Density" -process "Fit"
   project set "Collapsing Input Limit (2-54)" "12" -process "Fit"
   project set "Collapsing Pterm Limit (1-90)" "30" -process "Fit"
```

This is provided without warranty...

