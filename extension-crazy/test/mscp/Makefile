
CC=glcc
DEFS=-DAVOID_SCANF
CFLAGS=-rom=v5a
LDFLAGS=-map=64k,./mscp.ovl
LIBS=-L../../glcc/libconb -lconb

mscp.gt1: mscp.o
	${CC} ${CFLAGS} ${LDFLAGS} mscp.o ${LIBS} -o $@

%.o: %.c
	${CC} ${CFLAGS} ${DEFS} -c $<

broom: FORCE

clean: FORCE
	-rm mscp.o mscp.gt1

FORCE:

.PHONY: FORCE
