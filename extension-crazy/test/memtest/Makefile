SHELL=/bin/sh
GLCC=glcc

memtest: memtest.c
	${GLCC} -map=32k -rom=v5a memtest.c -o memtest.gt1
