# Verilog code for the CPLD

File `ise-main/main.jed` contains the programming information for the CPLD.
A good way to do this is to use program `xc3sprog` with a FTDI232 cable.

To regenerate this file from the source `top.v`, `top.ucf`, and from the settings
found in `ise-main/main.tcl`, you must make sure that the shell scripts found
in directory `script` invoke the Xilinx ISE Webpack `xtclsh` program. The default
script searches a Wine install of the Win7 version or a Linux install which can
be capricious because it relies on lots of obselete libraries.
