## Changelog

* V6 -- Initial version for this design. The original prototype had
  address memory 0000 and 0080 readonly at all times. Bit 0 was
  permanently wired to A7. Bits 2 and 3 would present `MISO0` and
  `MISO` but only when `SCLK` was set. Therefore when `SCLK` was
  cleared, reading these addresses would respectively return 00 and 01
  as expected by the gigatron software. It turns out that this messes
  up the routine that measure the available memory immediately after
  reset, causing the gigatron to occasionnally fail to boot and loop
  indefinitely (see address 0c in the rom). This was fixed without PCB
  changes by simply reprogramming the GALs.

* V6b -- This version outputs a special clock line `SCK0` for the SD
  card that is only active when it is selected, that is, when `/SS0`
  is cleared. This is designed to prevent the a SPI1 transaction from
  being interpreted by an inserted SD card that has not yet been put
  in SPI mode. Because this card in not in SPI mode, it may answer to
  traffic on `SCK` and `MOSI` even though it is not selected. This is
  not very probable because the checksums will be wrong. Still I find
  safer to simply disable its clock line to prevent it from
  interpreting `MOSI` at all.  Version 6b needs a different program
  for GAL2.

* V7 -- This version implements the CTRL space extension and provides
  headers for further extensions. CTRL codes of the form
  `yyyyyyyypppp00xx` are interpreted as extended codes that do not
  change the traditional ctrl bits but are exposed on header H3. Such
  codes are indicated by a raising edge on `DEVCLKOUT` (DK on H3) with
  `DEVADDR0/1` (F0/1 on H3) asserted when `pppp`=0000/00001, and with
  `A8..15` containing `yyyyyyyy`. In addition, header H4 provides
  signals useful to add devices to the SPI bus. Ports SPI0, SPI1, and
  H4 have distinct MISO wires names `MISO0`, `MISO1`, and `MISOX`. The
  signal read by the Gigatron is `MISO0` when `/SS0` is asserted,
  `MISO1` when `/SS1` is asserted, and `MISOX` when none are
  asserted. These signals are left floating with values determined by
  the GAL's internal pin keeper.  Unlike version V6, all SPI ports
  receive the same clock `SCK`.

* V7b -- Change serif on header H3 to reflect the A8/A9 swap. 

