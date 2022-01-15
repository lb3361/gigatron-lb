SHELL=/bin/sh
GLCC=glcc


LIBNAME=libcon_h.a
SFILES=cons_asm.s
CFILES=cons_setup.c cons_output.c cons_geom.c cons_extra.c
O5FILES=${patsubst %.c,%_5.o,${CFILES}}
O6FILES=${patsubst %.c,%_6.o,${CFILES}}
OFILES=${O5FILES} ${O6FILES}

all: ${LIBNAME} test.gt1

${LIBNAME}: ${SFILES} ${O4FILES} ${O5FILES} ${O6FILES}
	cat $+ > $@

%_5.o: %.c
	${GLCC} -c -cpu=5 -o $@ $<

%_6.o: %.c
	${GLCC} -c -cpu=6 -o $@ $<


test.gt1: test.c ${LIBNAME}
	${GLCC} -rom=v5a -o $@ test.c ${LIBNAME}

broom: FORCE

clean: FORCE
	-rm 2>/dev/null ${LIBNAME} ${OFILES} test.gt1

.PHONY: FORCE
