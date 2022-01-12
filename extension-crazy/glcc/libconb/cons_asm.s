

def scope():

    def code_bank():
        # This assumes that the main program only uses normal banking
        # Clobbers R22. Use R21
        
        ctrlBits_v5 = 0x1f8
        nohop()
        
        ## save current bank
        label('_cons_save_current_bank')
        LDWI(v('_cons_restore_saved_bank')+12);STW(R22)
        LDWI(ctrlBits_v5);PEEK();ANDI(0xC0);POKE(R22);RET();

        ## restore_saved_bank
        label('_cons_restore_saved_bank')
        LDWI('SYS_ExpanderControl_v4_40');STW('sysFn');
        LDWI(ctrlBits_v5);PEEK();ANDI(0x3C);ORI(0);SYS(40);
        LDWI(0x00F0);SYS(40);
        RET();
    
        ## set extended banking code for address in vAC
        label('_cons_update_extbank')
        BGE('.wbb1')
        LDWI(0xF1F0);BRA('.wbb2')
        label('.wbb1')
        LDWI(0xE1F0);
        label('.wbb2')
        XORW(R21);BEQ('.wbb3')
        XORW(R21);STW(R21);SYS(40);
        label('.wbb3')
        RET()

        ## write to video bank for address in vAC
        label('_cons_write_to_video_bank')
        PUSH()
        ORI(0xff);STW(R21)
        LDWI('SYS_ExpanderControl_v4_40');STW('sysFn')
        LDW(R21);CALLI('_cons_update_extbank')
        CALLI('_cons_save_current_bank')
        LDWI(ctrlBits_v5);PEEK();ANDI(0x3f);SYS(40);
        POP();RET();
        
    module(name='conb_bank.s',
           code=[ ('EXPORT', '_cons_save_current_bank'),
                  ('EXPORT', '_cons_restore_saved_bank'),
                  ('EXPORT', '_cons_update_extbank'),
                  ('EXPORT', '_cons_write_to_video_bank'),
                  ('CODE', '_write_to_video_bank', code_bank) ] )

    
    # -- int _console_printchars(int fgbg, char *addr, const char *s, int len)
    
    # Draws up to `len` characters from string `s` at the screen
    # position given by address `addr`.  This assumes that the
    # horizontal offsets in the string table are all zero. All
    # characters are printed on a single line (no newline).  The
    # function returns when any of the following conditions is met:
    # (1) `len` characters have been printed, (2) the next character
    # would not fit horizontally on the screen, or (3), an unprintable
    # character, i.e. not in [0x20-0x83], has been met.

    def code_printchars():
        label('_console_printchars')
        PUSH()
        LDW(R9);CALLI('_cons_write_to_video_bank')
        _LDI('SYS_VDrawBits_134');STW('sysFn')   # prep sysFn
        LDW(R8);STW('sysArgs0')                  # move fgbg, freeing R8
        LDI(0);STW(R12)                          # R12: character counter
        label('.loop')
        LDW(R10);PEEK();STW(R8)                  # R8: character code
        LDI(1);ADDW(R10);STW(R10)                # next char
        LDW(R9);STW('sysArgs4')                  # destination address
        ADDI(6);STW(R9);                         # next address
        LD(vACL);SUBI(0xA0);_BGT('.ret')         # beyond screen?
        _LDI('font32up');STW(R13)                # R13: font address
        LDW(R8);SUBI(32);_BLT('.ret'  )          # c<32
        STW(R8);SUBI(50);_BLT('.draw')           # 32 <= c < 82
        STW(R8);SUBI(50);_BGE('.ret')            # >= 132
        _LDI('font82up');STW(R13)
        label('.draw')
        CALLI('_printonechar')
        LDI(1);ADDW(R12);STW(R12);               # increment counter
        XORW(R11);_BNE('.loop')                  # loop
        label('.ret')
        CALLI('_cons_restore_saved_bank')
        tryhop(5);LDW(R12);POP();RET()

    def code_printonechar():
        nohop()
        label('_printonechar')
        LDWI(0x8000);ORW('sysArgs4');STW('sysArgs4')
        LDW(R8);LSLW();LSLW();ADDW(R8);ADDW(R13)
        STW(R13);LUP(0);ST('sysArgs2');SYS(134);INC(R13);INC('sysArgs4')
        LDW(R13);LUP(0);ST('sysArgs2');SYS(134);INC(R13);INC('sysArgs4')
        LDW(R13);LUP(0);ST('sysArgs2');SYS(134);INC(R13);INC('sysArgs4')
        LDW(R13);LUP(0);ST('sysArgs2');SYS(134);INC(R13);INC('sysArgs4')
        LDW(R13);LUP(0);ST('sysArgs2');SYS(134);INC('sysArgs4')
        LDI(0);ST('sysArgs2');SYS(134)
        RET()

    module(name='cons_printchar.s',
           code=[ ('EXPORT', '_console_printchars'),
                  ('IMPORT', '_cons_write_to_video_bank'),
                  ('IMPORT', '_cons_restore_saved_bank'),
                  ('CODE', '_console_printchars', code_printchars),
                  ('CODE', '_printonechar', code_printonechar) ] )
    
    # -- void _console_clear(char *addr, char clr, int nl)
    # Clears from addr to the end of line with color clr.
    # Repeats for nl successive lines.

    def code_clear():
        label('_console_clear')
        PUSH()
        LDW(R8);CALLI('_cons_write_to_video_bank')
        LDI(160);SUBW(R8);ST(R11)
        LD(R9);ANDI(0x3f);ST('sysArgs1')
        label('.loop')
        LDW(R8);CALLI('_cons_update_extbank')
        LDWI('SYS_SetMemory_v2_54');STW('sysFn')
        LD(R11);ST('sysArgs0')
        LDWI(0x8000);ORW(R8);STW('sysArgs2')
        SYS(54)
        INC(R8+1)
        LDW(R10)
        SUBI(1);
        STW(R10);
        _BNE('.loop')
        CALLI('_cons_restore_saved_bank')
        tryhop(2);POP();RET()

    module(name='cons_clear.s',
           code=[ ('EXPORT', '_console_clear'),
                  ('IMPORT', '_cons_write_to_video_bank'),
                  ('IMPORT', '_cons_update_extbank'),
                  ('IMPORT', '_cons_restore_saved_bank'),
                  ('CODE', '_console_clear', code_clear) ] )
    
scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
