SHELL=/bin/sh
GLCC=glcc


LIBNAME=libconb
SFILES=cons_asm.s
CFILES=cons_setup.c
O5FILES=${patsubst %.c,%_5.o,${CFILES}}
O6FILES=${patsubst %.c,%_6.o,${CFILES}}
OFILES=${O5FILES} ${O6FILES}

all: ${LIBNAME}.a test.gt1

${LIBNAME}.a: ${SFILES} ${O4FILES} ${O5FILES} ${O6FILES}
	cat $+ > $@

%_5.o: %.c
	${GLCC} -c -cpu=5 -o $@ $<

%_6.o: %.c
	${GLCC} -c -cpu=6 -o $@ $<


test.gt1: test.c ${LIBNAME}.a
	${GLCC} -rom=v5a -o $@ test.c -L. -lconb

broom: FORCE

clean: FORCE
	-rm 2>/dev/null ${LIBNAME}.a ${OFILES} test.gt1

.PHONY: FORCE
