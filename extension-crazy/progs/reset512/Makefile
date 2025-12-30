SHELL=/bin/sh
GIGAROM=${abspath ../../../../gigatron-rom}
COMPILE_GCL=python3 ${GIGAROM}/Core/compilegcl.py -s ${GIGAROM}/interface.json
export PYTHONDONTWRITEBYTECODE:=please

all: Reset.gt1

Reset.gt1: Reset.gcl
	${COMPILE_GCL} Reset.gcl

broom: FORCE

clean: FORCE
	-rm 2>/dev/null Reset.gt1

.PHONY: FORCE


