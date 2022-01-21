SHELL=/bin/sh
COMPILE_GCL=python3 ../../rom/Core/compilegcl.py -s ../../rom/interface.json
export PYTHONDONTWRITEBYTECODE:=please

all: Reset.gt1

Reset.gt1: Reset.gcl
	${COMPILE_GCL} Reset.gcl

broom: FORCE

clean: FORCE
	-rm 2>/dev/null Reset.gt1

.PHONY: FORCE


