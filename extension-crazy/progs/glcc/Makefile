SHELL=/bin/sh
TARGETS=all broom clean
GLCC=glcc

SUBDIRS=libcon_b libcon_n libcon_h

all:
	for n in ${SUBDIRS}; do \
	  make -C $$n GIGAROM=${GIGAROM} GLCC=${GLCC} $@ || exit 1; done
	@cp -u libcon*/libcon*.a map512k

broom:
	for n in ${SUBDIRS}; do \
	  make -C $$n GIGAROM=${GIGAROM} GLCC=${GLCC} $@ ; done

clean:
	for n in ${SUBDIRS}; do \
	  make -C $$n GIGAROM=${GIGAROM} GLCC=${GLCC} $@ ; done
	-rm map512k/*.a


.PHONY: all broom clean
