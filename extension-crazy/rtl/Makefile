
TARGETS=all broom clean
SUBDIRS=ise-main

${TARGETS}:
	for n in ${SUBDIRS}; do make -C $$n $@ ; done

.PHONY: all broom clean
