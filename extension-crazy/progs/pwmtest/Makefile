SHELL=/bin/sh
CC=glcc
CFLAGS=-rom=v5a
LDFLAGS=-map=512k,noromcheck

all: pwmtest.gt1

pwmtest.gt1: pwmtest.c
	${CC} ${LDFLAGS} ${CFLAGS} pwmtest.c -o pwmtest.gt1

broom: FORCE

clean: FORCE
	-rm 2>/dev/null pwmtest.gt1

.PHONY: FORCE
