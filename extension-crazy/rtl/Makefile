SHELL=/bin/sh

QUARTUSDIR=/home/quartus/intelFPGA_lite/13.0sp1
QUARTUS_SH=${QUARTUSDIR}/quartus/bin/quartus_sh --64bit
POF2JED=wine c:/pof2jed/bin/pof2jed.exe

SUBDIRS=basic-pqfp100

all: FORCE
	for dir in ${SUBDIRS}; do make -C $$dir  \
	   "QUARTUSDIR=${QUARTUSDIR}"\
	   "QUARTUS_SH=${QUARTUS_SH}"\
	   "POF2JED=${POF2JED}" \
	   all ; done

clean: FORCE
	for dir in ${SUBDIRS}; do make -C $$dir  \
	   "QUARTUSDIR=${QUARTUSDIR}"\
	   "QUARTUS_SH=${QUARTUS_SH}"\
	   "POF2JED=${POF2JED}" \
	   clean ; done




FORCE:

.PHONY: FORCE
