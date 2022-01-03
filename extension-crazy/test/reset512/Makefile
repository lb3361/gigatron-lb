SHELL=/bin/sh
TOP=../../..
GIGAROM=${TOP}/../gigatron-rom
COMPILE_GCL=${GIGAROM}/Core/compilegcl.py -s ${GIGAROM}/interface.json

Reset.gt1: Reset.gcl
	${COMPILE_GCL} Reset.gcl

