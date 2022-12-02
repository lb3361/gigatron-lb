#-----------------------------------------------------------------------
#
#	Makefile for Gigatron ROM and tooling
#
#-----------------------------------------------------------------------

# Latest development version as default target
DEV=dev.rom

# This should point into the gigatron-rom app directory
GIGAROM=../../../gigatron-rom
APPS=${GIGAROM}/Apps
RESET=../progs/reset512/Reset.gcl

all: $(DEV)

# Allow application-specific SYS extensions to live in Apps/
export PYTHONPATH:=${APPS}/Loader:${APPS}/Racer
# Prevent python from writing bytecode
export PYTHONDONTWRITEBYTECODE:=please

ifdef OS # Windows
 export PYTHONPATH:=$(subst :,;,$(PYTHONPATH))
endif

dev.rom: Core/* ${APPS}/*/* ${RESET} Makefile interface.json
	python3 Core/dev.asm.py\
		-DWITH_512K_BOARD=1\
		Snake=${APPS}/Snake/Snake_v3.gcl\
		SYS_Racer_v1.py\
		zippedRacerHorizon=${APPS}/Racer/Horizon-256x16.rgb\
		Racer=${APPS}/Racer/Racer.gcl\
		Mandelbrot=${APPS}/Mandelbrot/Mandelbrot.gcl\
		Tetronis=${APPS}/Tetronis/Tetronis_v2.gt1\
		Bricks=${APPS}/Bricks/Bricks_v2.gt1\
		TinyBASIC=${APPS}/TinyBASIC/TinyBASIC.gcl\
		TicTac=${APPS}/TicTac/LoadTicTac_v1.gcl\
		TicTacGtb=${APPS}/TicTac/TicTac_v2.gtb\
		WozMon=${APPS}/WozMon/WozMon_v2.gcl\
		Apple1=${APPS}/Apple-1/Apple-1.gt1\
		MSBASIC=${APPS}/MSBASIC/MSBASIC_v1.gt1\
		Loader=${APPS}/Loader/Loader_v4.gcl\
		Credits=${APPS}/Credits/Credits_v3.gcl\
		Egg=${APPS}/Horizon/Horizon_dev_c.gt1\
		Boot=${APPS}/CardBoot/CardBoot.gt1\
		Main=${APPS}/MainMenu/MainMenu.gcl\
		Reset=${RESET}

burn: $(DEV)
	minipro -p 'AT27C1024@DIP40' -w "$<" -y -s

broom: FORCE

clean: FORCE
	-rm -rf dev.rom dev.lst

.PHONY: FORCE


#-----------------------------------------------------------------------
#	Generic rules
#-----------------------------------------------------------------------

%.gt1: %.gcl
	Core/compilegcl.py "$<" `dirname "./$@"`

%.gt1x: %.gcl
	Core/compilegcl.py -x "$<" `dirname "./$@"`

%.gt1: %.vasm.py
	env PYTHONPATH=Core python3 "$<"
	mv out.gt1 "$@"

%.h: %.gt1
	od -t x1 -v < "$<" |\
	awk 'BEGIN {print "// Converted from $< by Makefile"}\
	     {for (i=2; i<=NF; i++) printf "0x%s,\n", $$i}' > "$@"

%.rgb: %.png
	convert "$<" "$@"

# Hex dump from object file
%.hex: %.obj
	od -An -t x1 -v < "$<" |\
	awk '{for(i=1;i<=NF;i++)print" #$$" $$i}' |\
	fmt -w 80 > "$@"

#-----------------------------------------------------------------------
#
#-----------------------------------------------------------------------
# vi: noexpandtab
