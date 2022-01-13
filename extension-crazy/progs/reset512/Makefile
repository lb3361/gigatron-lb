SHELL=/bin/sh
TOP=../../..
GIGAROM=../gigatron-rom
COMPILE_GCL=${TOP}/${GIGAROM}/Core/compilegcl.py -s ${TOP}/${GIGAROM}/interface.json

all: Reset.gt1

Reset.gt1: Reset.gcl
	${COMPILE_GCL} Reset.gcl

broom: FORCE

clean: FORCE
	-rm 2>/dev/null Reset.gt1

.PHONY: FORCE


