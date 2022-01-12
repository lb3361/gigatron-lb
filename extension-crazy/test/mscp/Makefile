
CC=glcc
DEFS=-DAVOID_SCANF
CFLAGS=-rom=v5a
LDFLAGS=-map=64k,./mscp.ovl
LIBCONB=../../glcc/libconb/libconb.a

mscp.gt1: mscp.o ${LIBCONB}
	${CC} ${CFLAGS} ${LDFLAGS} mscp.o ${LIBCONB} -o $@

%.o: %.c
	${CC} ${CFLAGS} ${DEFS} -c $<

broom: FORCE

clean: FORCE
	-rm mscp.o mscp.gt1

FORCE:

.PHONY: FORCE
