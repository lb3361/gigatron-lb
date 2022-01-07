SHELL=/bin/sh
TARGETS=all broom clean
GIGAROM=../gigatron-rom
GLCC=glcc

SUBDIRS=memtest pwmtest reset512

${TARGETS}:
	for n in ${SUBDIRS}; do make -C $$n GIGAROM=${GIGAROM} GLCC=${GLCC} $@ ; done

.PHONY: all broom clean
