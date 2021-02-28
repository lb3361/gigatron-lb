
all: GAL1.jed GAL2.jed

GAL1.jed: GAL1.pld

GAL2.jed: GAL2.pld

%.jed: %.pld
	@echo "WinCUPL is not scriptable."
	@echo "You must start WinCUPL to load $< and press F9 to produce $@."


broom:
	find . -type f | git check-ignore --stdin | xargs -t -r rm

clean: broom
	-rm *.jed *.doc


.PHONY: all broom clean
