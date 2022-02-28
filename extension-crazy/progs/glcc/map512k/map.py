
def map_describe():
    print('''  Memory map '512k' targets Gigatrons equipped with the 512k board.

  Thanks to the video snooping capabilities of the 512k board, the
  video buffer is displaced into banks 12 to 15 depending on the
  chosen video mode. Code and data can then use the entire 64k
  addressable by the Gigatron CPU.

  Overlay 'lo' limits code and data to memory below 0x8000 allowing
  the code to remap the range 0x8000-0xffff without risk.  Overlays
  'hr' and 'nr' respectively link the high-resolution (320x240) or
  narrow resolution (320x120) console library. Otherwise one gets a
  standard resolution console in page 14.  Overlay 'noromcheck'
  prevents the startup code from checking the presence of a 512k
  patched ROM which is nevertheless necessary for several programs.
''')

# Note: this map compiles a small stub in 0x200 that checks that the
# memory is sufficient. It avoids loading anything in 0x8200-0x8240 to
# avoid overwriting the stub on a 32KB machine.

# ------------size----addr----step----end---- flags (1=nocode, 2=nodata, 4=noheap)
segments = [ (0x00fa, 0x0200, 0x0100, 0x0500, 0),
             (0x0200, 0x0500, None,   None,   0),
             (0x7800, 0x0800, None,   None,   0),
             (0x0200, 0x8000, None,   None,   0),
             (0x7AC0, 0x8240, None,   None,   0) ]

initsp = 0xfffc
libcon = "con_b"
check512krom = True

def map_segments():
    '''
    Enumerate all segments as tuples (saddr, eaddr, dataonly)
    '''
    global segments
    for tp in segments:
        estep = tp[2] or 1
        eaddr = tp[3] or (tp[1] + estep)
        for addr in range(tp[1], eaddr, estep):
            yield (addr, addr+tp[0], tp[4])

def map_libraries(romtype):
    '''
    Returns a list of extra libraries to scan before the standard ones
    '''
    return [ libcon ]

def map_modules(romtype):
    '''
    Generate an extra modules for this map. At the minimum this should
    define a function '_gt1exec' that sets the stack pointer,
    checks the rom and ram size, then calls v(args.e). This is often
    pinned at address 0x200.
    '''
    def code0():
        org(0x200)
        label(args.gt1exec)
        # Set stack
        LDWI(initsp);STW(SP);
        if check512krom:
            # Check presence of patched rom
            LD(0xa);ANDI(0xfc);XORI(0xfc);BNE('.err')
        else:
            # Check ram>64k and expansion present
            LD('memSize');BNE('.err')
            LDWI(0x1f8);PEEK();BEQ('.err')
        # Check romtype
        if romtype and romtype >= 0x80:
            LD('romType');ANDI(0xfc);XORI(romtype);BNE('.err')
        elif romtype:
            LD('romType');ANDI(0xfc);SUBI(romtype);BLT('.err')
        # Call _start
        LDWI(v(args.e));CALL(vAC)
        # Run Marcel's smallest program when machine check fails
        label('.err')
        LDW('frameCount');DOKE(vPC+1);BRA('.err')

    module(name='_gt1exec.s',
           code=[ ('EXPORT', '_gt1exec'),
                  ('CODE', '_gt1exec', code0) ] )

    debug(f"synthetizing module '_gt1exec.s' at address 0x200")


# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
