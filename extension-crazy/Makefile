SHELL=/bin/sh
TARGETS=all broom clean
GIGAROM=${shell realpath -s ../../gigatron-rom}
GLCC=glcc

SUBDIRS=rtl rom progs

${TARGETS}:
	for n in ${SUBDIRS}; do make -C $$n GIGAROM=${GIGAROM} GLCC=${GLCC} $@ ; done

.PHONY: all broom clean
