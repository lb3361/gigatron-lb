SHELL=/bin/sh
TARGETS=all broom clean
GIGAROM=${abspath ../../../gigatron-rom}
GLCC=glcc

SUBDIRS=memtest pwmtest zpbanktest mscp mandelbrot reset512
# SUBDIRS += music64k (realpath --relative-to does not work on macos)

${TARGETS}:
	for n in ${SUBDIRS}; do \
	  make -C $$n GIGAROM=${GIGAROM} GLCC=${GLCC} $@ || exit 1; done

.PHONY: all broom clean
