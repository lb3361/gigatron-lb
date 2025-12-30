SHELL=/bin/sh

RTL=..
XTCLSH=${RTL}/scripts/xtclsh
IMPACT=${RTL}/scripts/impact
XC3SPROG=${RTL}/scripts/xc3sprog

PROJECT=main

all: ${PROJECT}.jed

svf: ${PROJECT}.svf ${PROJECT}.xsvf

${PROJECT}.jed: ../top.v ../top.ucf  ${PROJECT}.tcl
	@echo
	@echo "========== generating " $@
	@echo
	-rm 2>/dev/null top.jed
	${XTCLSH} ${PROJECT}.tcl rebuild_project
	mv top.jed ${PROJECT}.jed
	mv top.rpt ${PROJECT}.rpt

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

prog: ${PROJECT}.jed
	${XC3SPROG} -c jtaghs2 -v ${PROJECT}.jed
