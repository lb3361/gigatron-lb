# GLCC linker map for 512k board

This directory contains three versions of the console library
targeting normal resolution (160x120), narrow resolution (320x120) and
high resolution (320x240) and a linker map for glcc.  To use the
linker map use a glcc version greater than `GLCC_RELEASE_1.4-15` with
the command
```
$ glcc --mapdir=/path/to/thisdir  -map=512k{,overlays} ...
```
The following help is printed with
```
$ glcc --mapdir=/path/to/thisdir  -map=512k --info
```

> Memory map '512k' targets Gigatrons equipped with the 512k board.
>
> Thanks to the video snooping capabilities of the 512k board, the video buffer is displaced into banks 12 to 15 depending on the chosen video mode. Code and data can then use the entire 64k addressable by the Gigatron CPU.
>
> Overlay 'lo' limits code and data to memory below 0x8000 allowing the code to remap the range 0x8000-0xffff without risk.  Overlays 'hr' and 'nr' respectively link the high-resolution (320x240) or narrow resolution (320x120) console library. Otherwise one gets a standard resolution console in page 14.  Overlay 'noromcheck' prevents the startup code from checking the presence of a 512k patched ROM which is nevertheless necessary for several programs.
