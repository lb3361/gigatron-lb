SHELL=/bin/sh
TARGETS=all broom clean
GIGAROM=${abspath ../../../gigatron-rom}
GLCC=glcc

SUBDIRS=memtest pwmtest zpbanktest reset512\
        mscp mandelbrot music64k

${TARGETS}:
	for n in ${SUBDIRS}; do \
	  make -C $$n GIGAROM=${GIGAROM} GLCC=${GLCC} $@ || exit 1; done

.PHONY: all broom clean
