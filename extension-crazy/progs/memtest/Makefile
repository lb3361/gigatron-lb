SHELL=/bin/sh
GLCC=glcc

all: memtest.gt1

memtest.gt1: memtest.c
	${GLCC} -map=32k -rom=v5a memtest.c -o memtest.gt1

broom: FORCE

clean: FORCE
	-rm 2>/dev/null memtest.gt1

.PHONY: FORCE
