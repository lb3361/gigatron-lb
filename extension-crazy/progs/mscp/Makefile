
CC=glcc
DEFS=-DAVOID_SCANF
CFLAGS=-rom=v5a
LDFLAGS=-map=64k,./mscp.ovl
LIBCON_B=../libcon_b/libcon_b.a
LIBCON_N=../libcon_n/libcon_n.a
LIBCON_H=../libcon_h/libcon_h.a

all: mscp.gt1 mscp_n.gt1 mscp_h.gt1

mscp.gt1: mscp.o ${LIBCON_B}
	${CC} ${CFLAGS} ${LDFLAGS} mscp.o ${LIBCON_B} -o $@

mscp_n.gt1: mscp.o ${LIBCON_N}
	${CC} ${CFLAGS} ${LDFLAGS} mscp.o ${LIBCON_N} -o $@

mscp_h.gt1: mscp.o ${LIBCON_H}
	${CC} ${CFLAGS} ${LDFLAGS} mscp.o ${LIBCON_H} -o $@

%.o: %.c
	${CC} ${CFLAGS} ${DEFS} -c $<

broom: FORCE

clean: FORCE
	-rm mscp.o mscp.gt1

FORCE:

.PHONY: FORCE
