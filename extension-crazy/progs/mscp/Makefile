SHELL=/bin/sh
CC=glcc
CFLAGS=-rom=v5a -DAVOID_SCANF
LDFLAGS=

all: mscp.gt1 mscp_n.gt1 mscp_h.gt1 

mscp.gt1: mscp.o
	${CC} ${LDFLAGS} ${CFLAGS} -map=512k mscp.o -o $@

mscp_n.gt1: mscp.o
	${CC} ${LDFLAGS} ${CFLAGS} -map=512k,nr mscp.o -o $@

mscp_h.gt1: mscp.o
	${CC} ${LDFLAGS} ${CFLAGS} -map=512k,hr mscp.o -o $@

%.o: %.c
	${CC} ${CFLAGS} ${DEFS} -c $<

broom: FORCE

clean: FORCE
	-rm *.o *.gt1

FORCE:

.PHONY: FORCE
