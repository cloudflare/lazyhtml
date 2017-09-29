RAGEL = ragel
RAGELFLAGS =

RL_FILES := $(wildcard syntax/*.rl)

.PHONY: c-tokenizer
c-tokenizer:
	make -C c

%.dot: c/tokenizer.rl $(RL_FILES)
	$(RAGEL) $(RAGELFLAGS) -Vp -M $(notdir $(basename $@)) $< > $@
	node simplify-graph.js $@

%.png: %.dot
	dot -Tpng $< -o $@
	open $@

.PHONY: clean
clean:
	rm -rf *.dot *.png
	make -C c clean
	cd rust; cargo clean
