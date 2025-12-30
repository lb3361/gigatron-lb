SHELL=/bin/sh
CC=glcc
CFLAGS=-rom=v5a
LDFLAGS=-map=512k,lo,hr
TARGET=mandelbrot.gt1
OBJS=mandelbrot.o
ASMS=fixed8.s

all: ${TARGET}

${TARGET}: ${OBJS} ${ASMS} Makefile
	${CC} ${LDFLAGS} ${CFLAGS} ${OBJS} ${ASMS} -o $@

%.o: %.c
	${CC} -c ${CFLAGS} $< -o $@

broom: FORCE

clean: FORCE
	-rm 2>/dev/null ${OBJS} ${TARGET}

.PHONY: FORCE
