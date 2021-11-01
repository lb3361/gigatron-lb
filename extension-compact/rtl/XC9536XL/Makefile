

all: gigaexp.jed gigaexp.svf gigaexp.xsvf broom

gigaexp.jed: ../gigaexp.v ../gigaexp.ucf gigaexp.tcl
	@echo
	@echo "========== generating " $@
	@echo
	wine 'C:\Xilinx\14.7\ISE_DS\ISE\bin\nt64\xtclsh.exe' gigaexp.tcl rebuild_project

gigaexp.svf: gigaexp.jed
	@echo
	@echo "========== generating " $@
	@echo
	( echo setMode -bscan ; \
	  echo setCable -port svf -file gigaexp ; \
	  echo addDevice -p 1 -file gigaexp.jed ; \
	  echo program -e -v -p 1 ; \
	  echo quit ) | \
	wine 'C:\Xilinx\14.7\ISE_DS\ISE\bin\nt64\impact.exe' -batch

gigaexp.xsvf: gigaexp.jed
	@echo
	@echo "========== generating " $@
	@echo
	( echo setMode -bscan ; \
	  echo setCable -port xsvf -file gigaexp ; \
	  echo addDevice -p 1 -file gigaexp.jed ; \
	  echo program -e -v -p 1 ; \
	  echo quit ) | \
	wine 'C:\Xilinx\14.7\ISE_DS\ISE\bin\nt64\impact.exe' -batch


.PHONY: all broom clean 

broom:
	-find . -type f | git check-ignore --stdin | xargs -t -r rm
	-find . -type d | git check-ignore --stdin | tac | xargs -t -r rmdir 

clean: broom
	-rm gigaexp.jed gigaexp.svf gigaexp.xsvf

