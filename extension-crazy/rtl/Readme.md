Work in progress.


* ise-mini/mini.jed -- Simple logic that leaves nAE cleared. 
  This is not reliable because the fast SRAM timings are more sensitive to the Gigatron CLK2/CLK1 hack.
  
* ise-full/full.jed -- Toggles nAE for half of the cycle and latch the fast SRAM outputs.
  This is far more reliable and a good stepping stone for full video snoop.
