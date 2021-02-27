
TARGETS=all broom clean
SUBDIRS=XC9536XL XC9572XL

${TARGETS}:
	for n in ${SUBDIRS}; do make -C $$n $@ ; done

.PHONY: all broom clean
