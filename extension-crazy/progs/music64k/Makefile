SHELL=/bin/sh
NAME=Music64k_ROMv5a
GIGAROM=${abspath ../../../../gigatron-rom}
GIGAROMR=${shell realpath --relative-to=. "${GIGAROM}"}
GTBASIC=${GIGAROM}/Contrib/at67/tools/gtbasic/gtbasic

all: ${NAME}.gt1

${NAME}.gbas: ${NAME}.gbas.in Makefile
	echo ${GIGAROMR}
	sed -e 's@@GIGAROM@@${GIGAROMR}g' < $< > $@

${NAME}.gt1: ${NAME}.gbas
	${GTBASIC} ${NAME}.gbas 2>${NAME}.log || (tail ${NAME}.log && exit 1)

broom: FORCE
	-rm 2>/dev/null ${NAME}.gbas ${NAME}.gasm ${NAME}.log

clean: broom
	-rm 2>/dev/null ${NAME}.gt1

.PHONY: FORCE


