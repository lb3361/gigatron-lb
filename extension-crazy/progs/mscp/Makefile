ROM=dev7
GLCC=glcc
PYTHON=python3
OBJS=mscp.o core.o
ASMS=onload.s

PGMS=mscp.gt1 mscp_b.gt1 mscp_n.gt1 mscp_h.gt1

all: ${PGMS}

mscp.gt1: ${OBJS} ${ASMS} mscp.ovl
	${GLCC} -rom=${ROM} -map=128k,./mscp.ovl ${OBJS} ${ASMS} -o $@
	${PYTHON} addbook.py $@ book.bin

mscp_b.gt1: ${OBJS} ${ASMS} mscp.ovl
	${GLCC} -rom=${ROM} -map=512k,./mscp.ovl ${OBJS} ${ASMS} -o $@
	${PYTHON} addbook.py $@ book.bin

mscp_n.gt1: ${OBJS} ${ASMS} mscp.ovl
	${GLCC} -rom=${ROM} -map=512k,nr,./mscp.ovl ${OBJS} ${ASMS} -o $@
	${PYTHON} addbook.py $@ book.bin

mscp_h.gt1: ${OBJS} ${ASMS} mscp.ovl
	${GLCC} -rom=${ROM} -map=512k,hr,./mscp.ovl ${OBJS} ${ASMS} -o $@
	${PYTHON} addbook.py $@ book.bin

mscp.o: mscp.c core.h
	${GLCC} -rom=${ROM} -c $<

core.o: core.c core.h
	${GLCC} -rom=${ROM} -c $<

dumpbook: mscp.c
	${CC} -DSAVE_BOOK_BIN=1 -DSUBTRACTIVE_RND=1 mscp.c -o dumpbook

book.bin: dumpbook book.txt mscp.c Makefile
	./dumpbook

clean:
	-rm ${OBJS} *.gt1 *.prf *.frg prof.txt dumpbook mscp


# Profiling support

GTSIM=gtsim -rom ../../../gigatron-rom/dev128k7.rom -vmode 1975
GTPROF=gtprof
CFILES=${OBJS:.o=.c}

prof.txt: mscp-sim.prf
	${GTPROF} mscp-sim.prf mscp-sim.frg | sort -nr > $@

mscp-sim.gt1: ${CFILES} ${ASMS} mscp.ovl
	${GLCC} -rom=${ROM} -map=sim,allout,./mscp.ovl \
	    -DREPEATABLE_RND=1 ${CFILES} ${ASMS} -o $@ --frags > mscp-sim.frg
	${PYTHON} addbook.py $@ book.bin

mscp-sim.prf: mscp-sim.gt1 prof.in
	${GTSIM} -prof $@ mscp-sim.gt1 < prof.in


