
all: GAL1_v7.jed GAL2_v7.jed broom

GAL1_v7.jed: GAL1_v7.pld

GAL2_v7.jed: GAL2_v7.pld

%.jed: %.pld
	@echo "WinCUPL is not scriptable."
	@echo "You must start WinCUPL to load $< and press F9 to produce $@."


broom:
	find . -type f | git check-ignore --stdin | xargs -t -r rm

clean: broom
	-rm *.jed *.doc


.PHONY: all broom clean
