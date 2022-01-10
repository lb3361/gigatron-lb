# RTL Projects.

This directory contains the programming information for the CPLD. 

There are two projects

* `ise-full/full.jed` only attempts to achieve parity with the v7 extension boards (the "dual drive" boards) without any enhanced video or audio. This is also a playground for setting up the memory timings. The Verilog source file is `fulltop.v`.

* `ise-main/main.jed` is the main project with support for enhanced video and pwm output. It is compiled from source file `top.v`.

