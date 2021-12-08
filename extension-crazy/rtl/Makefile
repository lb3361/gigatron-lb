
TARGETS=all broom clean
SUBDIRS=ise-base

${TARGETS}:
	for n in ${SUBDIRS}; do make -C $$n $@ ; done

.PHONY: all broom clean
