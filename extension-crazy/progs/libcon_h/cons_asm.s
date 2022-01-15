

def scope():
    ctrlBits_v5 = 0x1f8

    def code_bank():
        # Clobbers R21, R22
        nohop()
        ## save current bank (to be completed)
        label('_cons_save_current_bank')
        RET()
        ## restore_saved_bank
        label('_cons_restore_saved_bank')
        LDWI('SYS_ExpanderControl_v4_40');STW('sysFn');
        LDWI(0x00F0);SYS(40);
        RET();
        ## set extended banking code for address in vAC
        label('_cons_set_bank_even')
        BGE('.wbb1')
        LDWI(0xF0F0);BRA('.wbb3')
        label('.wbb1')
        LDWI(0xE0F0);BRA('.wbb3')
        label('_cons_set_bank_odd')
        BGE('.wbb2')
        LDWI(0xD0F0);BRA('.wbb3')
        label('.wbb2')
        LDWI(0xC0F0);BRA('.wbb3')
        label('.wbb3')
        STW(R22)
        LDW('sysFn');STW(R21)
        LDWI('SYS_ExpanderControl_v4_40');STW('sysFn')
        LDW(R22);SYS(40)
        LDW(R21);STW('sysFn')
        RET()
        
    module(name='cons_bank.s',
           code=[ ('EXPORT', '_cons_save_current_bank'),
                  ('EXPORT', '_cons_restore_saved_bank'),
                  ('EXPORT', '_cons_set_bank_even'),
                  ('EXPORT', '_cons_set_bank_odd'),
                  ('CODE', '_cons_set_bank', code_bank) ] )

    
    # -- int _console_printchars(int fgbg, char *addr, const char *s, int len)
    #
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
        CALLI('_cons_save_current_bank')
        LDW(R8);STW('sysArgs0')                  # move fgbg, freeing R8
        LDI(0);STW(R12)                          # R12: character counter
        label('.loop')
        LDW(R10);PEEK();STW(R8)                  # R8: character code
        LDI(1);ADDW(R10);STW(R10)                # next char
        LDWI(0x8000);ORW(R9);STW('sysArgs4')     # destination address
        LDW(R9);ADDI(3);STW(R9);                 # next address
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
        tryhop(4);LDW(R12);POP();RET()

    def code_printonechar():
        nohop()
        label('_printonechar')
        PUSH()
        _LDI('SYS_VDrawBits_134');STW('sysFn')
        LDW(R9);CALLI('_cons_set_bank_even')
        LDW(R8);LSLW();LSLW();ADDW(R8);ADDW(R13)
        STW(R13);LUP(0);ST('sysArgs2');SYS(134);INC('sysArgs4')
        LDI(2);ADDW(R13);LUP(0);ST('sysArgs2');SYS(134);INC('sysArgs4')
        LDI(4);ADDW(R13);LUP(0);ST('sysArgs2');SYS(134)
        LDW('sysArgs4');SUBI(2);STW('sysArgs4')
        LDW(R9);CALLI('_cons_set_bank_odd');
        LDI(1);ADDW(R13);LUP(0);ST('sysArgs2');SYS(134);INC('sysArgs4')
        LDI(3);ADDW(R13);LUP(0);ST('sysArgs2');SYS(134);INC('sysArgs4')
        LDI(0);ST('sysArgs2');SYS(134)
        tryhop(2);POP();RET()

    module(name='cons_printchar.s',
           code=[ ('EXPORT', '_console_printchars'),
                  ('IMPORT', '_cons_save_current_bank'),
                  ('IMPORT', '_cons_set_bank_even'),
                  ('IMPORT', '_cons_set_bank_odd'),
                  ('IMPORT', '_cons_restore_saved_bank'),
                  ('CODE', '_console_printchars', code_printchars),
                  ('CODE', '_printonechar', code_printonechar) ] )
    
    # -- void _console_clear(char *addr, char clr, int nl)
    #
    # Clears from addr to the end of line with color clr.
    # Repeats for nl successive lines.

    def code_clear():
        label('_console_clear')
        PUSH()
        CALLI('_cons_save_current_bank')
        LDI(160);SUBW(R8);ST(R11)
        LD(R9);ANDI(0x3f);ST('sysArgs1')
        LDWI('SYS_SetMemory_v2_54');STW('sysFn')
        label('.loop')
        # even pixels
        LDW(R8);CALLI('_cons_set_bank_even')
        LD(R11);ST('sysArgs0')
        LDWI(0x8000);ORW(R8);STW('sysArgs2')
        SYS(54)
        # odd pixels
        LDW(R8);CALLI('_cons_set_bank_odd')
        LD(R11);ST('sysArgs0')
        LDWI(0x8000);ORW(R8);STW('sysArgs2')
        SYS(54)
        # loop
        INC(R8+1)
        LDW(R10);SUBI(1);STW(R10);
        _BNE('.loop')
        CALLI('_cons_restore_saved_bank')
        tryhop(2);POP();RET()

    module(name='cons_clear.s',
           code=[ ('EXPORT', '_console_clear'),
                  ('IMPORT', '_cons_save_current_bank'),
                  ('IMPORT', '_cons_set_bank_even'),
                  ('IMPORT', '_cons_set_bank_odd'),
                  ('IMPORT', '_cons_restore_saved_bank'),
                  ('CODE', '_console_clear', code_clear) ] )
    
scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
