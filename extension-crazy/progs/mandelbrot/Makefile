SHELL=/bin/sh
CC=glcc
CFLAGS=-rom=v5a
LDFLAGS=--mapdir=../glcc -map=512k,lo,hr
TARGET=mandelbrot.gt1
OBJS=mandelbrot.o
ASMS=fixed8.s

all: ${TARGET}

${TARGET}: ${OBJS} ${ASMS} ../glcc/map512k/libcon_h.a Makefile
	${CC} ${LDFLAGS} ${CFLAGS} ${OBJS} ${ASMS} ${LIBCON_H} -o $@

%.o: %.c
	${CC} -c ${CFLAGS} -rom=v5a $< -o $@

broom: FORCE

clean: FORCE
	-rm 2>/dev/null ${OBJS} ${TARGET}

.PHONY: FORCE
