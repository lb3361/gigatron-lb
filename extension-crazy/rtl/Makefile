
TARGETS=all broom clean
SUBDIRS=ise-mini ise-full ise-main

${TARGETS}:
	for n in ${SUBDIRS}; do make -C $$n $@ ; done

.PHONY: all broom clean
