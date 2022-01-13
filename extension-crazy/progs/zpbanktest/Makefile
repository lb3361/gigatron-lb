SHELL=/bin/sh
GLCC=glcc

all: zpbanktest.gt1

zpbanktest.gt1: zpbanktest.c
	${GLCC} -map=32k -rom=v5a zpbanktest.c bankasm.s -o $@

broom: FORCE

clean: FORCE
	-rm 2>/dev/null memtest.gt1

.PHONY: FORCE
