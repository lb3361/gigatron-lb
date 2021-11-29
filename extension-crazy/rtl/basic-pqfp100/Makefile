SHELL=/bin/sh

PROJECTNAME=basic

QUARTUSDIR=/home/quartus/intelFPGA_lite/13.0sp1
QUARTUS_SH=${QUARTUSDIR}/quartus/bin/quartus_sh --64bit
POF2JED=wine c:/pof2jed/bin/pof2jed.exe



all: ${PROJECTNAME}.jed

${PROJECTNAME}.jed: output_files/${PROJECTNAME}.pof
	${POF2JED} -i output_files/${PROJECTNAME}.pof -o ${PROJECTNAME}.jed \
		-device 1508as -pin_keep # -tdi_pullup -tms_pullup -jtag on

output_files/${PROJECTNAME}.pof: ../main-basic.v ../top-pqfp100.tcl ../top.v
	${QUARTUS_SH} -t setup.tcl
	${QUARTUS_SH} --flow compile ${PROJECTNAME}


clean: FORCE
	-rm 2>/dev/null *.qpf *.qsf *.qws *.jed *.txt
	-rm 2>/dev/null -rf output_files db incremental_db








FORCE:

.PHONY: FORCE
