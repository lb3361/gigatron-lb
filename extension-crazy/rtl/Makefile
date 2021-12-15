
TARGETS=all broom clean
SUBDIRS=ise-base ise-snoop

${TARGETS}:
	for n in ${SUBDIRS}; do make -C $$n $@ ; done

.PHONY: all broom clean
