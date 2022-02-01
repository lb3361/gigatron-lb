SHELL=/bin/sh
NAME=Music64k_ROMv5a
GIGAROM=../../../../gigatron-rom
GIGAROM_R=${shell realpath --relative-to=. "${GIGAROM}"}


all: ${NAME}.gt1

${NAME}.gbas: ${NAME}.gbas.in Makefile
	sed -e 's@@GIGAROM@@${GIGAROM_R}g' < $< > $@

${NAME}.gt1: ${NAME}.gbas
	${GIGAROM}/Contrib/at67/tools/gtbasic/gtbasic ${NAME}.gbas

broom: FORCE
	-rm 2>/dev/null ${NAME}.gbas ${NAME}.gasm

clean: broom
	-rm 2>/dev/null ${NAME}.gt1

.PHONY: FORCE


