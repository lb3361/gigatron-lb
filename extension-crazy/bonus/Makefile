
TARGETS=all broom clean
SUBDIRS=ise-gigatron

${TARGETS}:
	for n in ${SUBDIRS}; do make -C $$n $@ ; done

.PHONY: all broom clean
