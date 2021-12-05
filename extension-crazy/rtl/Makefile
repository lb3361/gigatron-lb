
TARGETS=all broom clean
SUBDIRS=basic

${TARGETS}:
	for n in ${SUBDIRS}; do make -C $$n $@ ; done

.PHONY: all broom clean
