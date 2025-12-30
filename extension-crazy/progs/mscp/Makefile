ROM=dev7
GLCC=glcc
PYTHON=python3
PGMS=mscp.gt1 mscp_b.gt1 mscp_n.gt1 mscp_h.gt1
OBJS=mscp.o core.o

all: ${PGMS}

mscp.gt1: ${OBJS} book.bin
	${GLCC} -rom=${ROM} -map=128k ${OBJS} -o $@
	booklen=`ls -ln book.bin | awk '{ print($$5); }'` ;\
	${PYTHON} gt1merge.py $@ --raw=book.bin@0x4000 --doke=$$booklen@0x42 -o $@

mscp_b.gt1: ${OBJS} book.bin
	${GLCC} -rom=${ROM} -map=512k ${OBJS} -o $@
	booklen=`ls -ln book.bin | awk '{ print($$5); }'` ;\
	${PYTHON} gt1merge.py $@ --raw=book.bin@0x4000 --doke=$$booklen@0x42 -o $@

mscp_n.gt1: ${OBJS} book.bin
	${GLCC} -rom=${ROM} -map=512k,nr ${OBJS} -o $@
	booklen=`ls -ln book.bin | awk '{ print($$5); }'` ;\
	${PYTHON} gt1merge.py $@ --raw=book.bin@0x4000 --doke=$$booklen@0x42 -o $@

mscp_h.gt1: ${OBJS} book.bin
	${GLCC} -rom=${ROM} -map=512k,hr ${OBJS} -o $@
	booklen=`ls -ln book.bin | awk '{ print($$5); }'` ;\
	${PYTHON} gt1merge.py $@ --raw=book.bin@0x4000 --doke=$$booklen@0x42 -o $@

mscp.o: mscp.c core.h
	${GLCC} -rom=${ROM} -c $<

core.o: core.c core.h
	${GLCC} -rom=${ROM} -c $<

book.bin: book.txt mscp.c Makefile
	${CC} -DSAVE_BOOK_BIN=1 -DSUBTRACTIVE_RND=1 mscp.c -o dumpbook
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


# Old version

mscp0.gt1: mscp0.c
	${GLCC} -rom=${ROM} -map=sim,allout -DAVOID_SCANF $< -o $@


