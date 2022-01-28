

def scope():

    def code_slowmul():
        # Fixed point 4+8 multiply
        nohop()
        label('slowmul')
        LDWI('SYS_LSRW1_48');STW('sysFn')
        # vars: A:R8, B:R9, C:R10, bits:R11
        LDW(R9);LSLW();LSLW();LSLW();LSLW();STW(R9)
        LDI(0);STW(R10)
        LDI(1);STW(R11)
        label('.slowmul1')
        LDW(R11);ANDW(R8);BEQ('.slowmul2')
        LDW(R9)
        label('.slowmul2')
        ADDW(R10);SYS(48);STW(R10)
        LDW(R11);LSLW();STW(R11)
        LD(vACH);XORI(0x10);BNE('.slowmul1')
        LDW(R8+1);ANDI(0xf0);BEQ('.slowmul3');LDW(R9)
        label('.slowmul3')
        ADDW(R10)
        RET()

    module(name='slowmul.s',
           code=[('EXPORT', 'slowmul'),
                 ('CODE',  'slowmul', code_slowmul) ] )


    def code_mul2():
        nohop()
        # Fixed point 3+8 square
        label('sqr')  # A:R8
        LDWI('squares');STW(R12)
        LDW(R8);BGE('.s1')
        LDI(0);SUBW(R8)
        label('.s1')
        LSLW();ADDW(R12);DEEK()
        RET()

        # Fixed point 3+8 multiply
        label('mul2') # A:R8 B:R9 C:R10 sign:R11 squares R12
        LDWI('squares');STW(R12)
        LDI(0);ST(R11)
        SUBW(R8);BLT('.m1')
        STW(R8);INC(R11)
        label('.m1')
        LDI(0);SUBW(R9);BLT('.m2')
        STW(R9);INC(R11)
        label('.m2')
        LDW(R8);LSLW();ADDW(R12);DEEK();STW(R10) # C contains A^2
        LDW(R8);SUBW(R9);BGE('.m3')
        LDW(R9);SUBW(R8)
        label('.m3')
        LSLW();ADDW(R12);DEEK();STW(R8)          # A contains (A-B)^2
        LDW(R9);LSLW();ADDW(R12);DEEK()
        ADDW(R10);SUBW(R8);STW(R10)              # C contains A^2+B^2-(A-B)^2 = 2AB
        LDW(R11);ANDI(1);BNE('.m4')
        LDW(R10);RET()
        label('.m4')
        LDI(0);SUBW(R10);RET()

    module(name='mul2.s',
           code=[('EXPORT', 'sqr'),
                 ('EXPORT', 'mul2'),
                 ('IMPORT', 'squares'),
                 ('CODE',  'mul2', code_mul2) ] )


    
    x0 = 0x48 # from mandelbrot.c
    y0 = 0x4a # from mandelbrot.c
    lastPix = 0x50
    i = 0x51
    x = 0x52
    y = 0x54
    xx = 0x56
    yy = 0x58
    
    def code_calcpixel():
        nohop();
        label('calc_pixel')
        PUSH();
        LDI(0);STW(x);STW(y);STW(xx);STW(yy);ST(i)
        label('.cp1')
        INC(i);LD(i);XORI(64);BEQ('.cp2');
        LDW(x);STW(R8);LDW(y);STW(R9);CALLI('mul2');ADDW(y0);STW(y)
        LDW(xx);SUBW(yy);ADDW(x0);STW(x)
        STW(R8);CALLI('sqr');STW(xx)
        LDW(y);STW(R8);CALLI('sqr');STW(yy)
        LDWI(0xfbff);ADDW(xx);ADDW(yy);BLE('.cp1')
        LD(i)
        label('.cp2')
        POP();RET()
        
    module(name='calcpixel.s',
           code=[('EXPORT', 'calc_pixel'),
                 ('IMPORT', 'sqr'),
                 ('IMPORT', 'mul2'),
                 ('CODE', 'calc_pixel', code_calcpixel) ] )

    def code_checkcalc():
        nohop()
        label('check_calc')
        PUSH()
        LD(lastPix);BNE('.calc')
        # bail if (x+1)^2 + y^2 < 1/16
        LDW(y0);STW(R8);CALLI('sqr');STW(yy)
        LDW(x0);INC(vACH);STW(R8);CALLI('sqr');ADDW(yy);SUBI(16);BLE('.no')
        # q = (x - 1/4)^2 + y^2
        # bail if q * (q + x - 1/4) < 1/4*y^2 
        LDW(x0);SUBI(64);STW(R8);CALLI('sqr');ADDW(yy) # q
        STW(R8);ADDW(x0);SUBI(64);STW(R9);CALLI('mul2');LSLW() # *4
        SUBW(yy);BLE('.no')
        label('.calc')
        CALLI('calc_pixel')
        ST(lastPix)
        POP();RET()
        label('.no')
        LDI(0);
        POP();RET()
        
    module(name='checkcalc.s',
           code=[('EXPORT', 'check_calc'),
                 ('IMPORT', 'sqr'),
                 ('IMPORT', 'mul2'),
                 ('IMPORT', 'calc_pixel'),
                 ('CODE', 'check_calc', code_checkcalc) ] )
        
scope()

# Local Variables:
# mode: python
# indent-tabs-mode: ()
# End:
