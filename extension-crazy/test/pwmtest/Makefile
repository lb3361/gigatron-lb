SHELL=/bin/sh
GLCC=glcc

all: pwmtest.gt1

pwmtest.gt1: pwmtest.c
	${GLCC} -map=32k -rom=v5a pwmtest.c -o pwmtest.gt1

broom: FORCE

clean: FORCE
	-rm 2>/dev/null pwmtest.gt1

.PHONY: FORCE
