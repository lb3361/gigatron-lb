SHELL=/bin/sh
GLCC=glcc


LIBNAME=libconb
SFILES=$(wildcard *.s)
CFILES=$(wildcard *.c)
O4FILES=${patsubst %.c,%_4.o,${CFILES}}
O5FILES=${patsubst %.c,%_5.o,${CFILES}}
O6FILES=${patsubst %.c,%_6.o,${CFILES}}
OFILES=${O4FILES} ${O5FILES} ${O6FILES}

all: ${LIBNAME}.a test.gt1

${LIBNAME}.a: ${SFILES} ${O4FILES} ${O5FILES} ${O6FILES}
	cat $+ > $@

%_4.o: %.c
	${GLCC} -c -cpu=4 -o $@ $<

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
