SHELL=/bin/sh
GLCC=glcc
LIBCON_H=../libcon_h/libcon_h.a

TARGET=mandelbrot.gt1
OBJS=mandelbrot.o
ASMS=fixed8.s

all: ${TARGET}

${TARGET}: ${OBJS} ${ASMS} ${LIBCON_H} Makefile
	${GLCC} -map=32k,./mandelbrot.ovl -rom=v5a ${OBJS} ${ASMS} ${LIBCON_H} -o $@

%.o: %.c
	${GLCC} -c -rom=v5a $< -o $@

broom: FORCE

clean: FORCE
	-rm 2>/dev/null ${OBJS} ${TARGET}

.PHONY: FORCE
