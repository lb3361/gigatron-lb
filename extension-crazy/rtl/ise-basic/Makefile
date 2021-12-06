SHELL=/bin/sh

RTL=..
XTCLSH=${RTL}/scripts/xtclsh
IMPACT=${RTL}/scripts/impact

PROJECT=basic

all: ${PROJECT}.jed ${PROJECT}.svf ${PROJECT}.xsvf

${PROJECT}.jed: ../top.v ../top.ucf ../main-${PROJECT}.v ${PROJECT}.tcl
	@echo
	@echo "========== generating " $@
	@echo
	${XTCLSH} ${PROJECT}.tcl rebuild_project
	cp top.jed ${PROJECT}.jed

${PROJECT}.svf: ${PROJECT}.jed
	@echo
	@echo "========== generating " $@
	@echo
	( echo setMode -bscan ; \
	  echo setCable -port svf -file ${PROJECT} ; \
	  echo addDevice -p 1 -file ${PROJECT}.jed ; \
	  echo program -e -v -p 1 ; \
	  echo quit ) | \
	${IMPACT} -batch

${PROJECT}.xsvf: ${PROJECT}.jed
	@echo
	@echo "========== generating " $@
	@echo
	( echo setMode -bscan ; \
	  echo setCable -port xsvf -file ${PROJECT} ; \
	  echo addDevice -p 1 -file ${PROJECT}.jed ; \
	  echo program -e -v -p 1 ; \
	  echo quit ) | \
	${IMPACT} -batch


.PHONY: all broom clean 

broom:
	-find . -type f | git check-ignore --stdin | xargs -t -r rm
	-find . -type d | git check-ignore --stdin | tac | xargs -t -r rmdir 

clean: broom
	-rm ${PROJECT}.jed ${PROJECT}.svf ${PROJECT}.xsvf

