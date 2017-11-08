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

tests.dat: convert-tests.js js/tests.proto
	node $< html5lib-tests/tokenizer $@

tests-with-feedback.dat: convert-tests.js js/tests.proto
	node $< parser-feedback-tests $@ --feedback

.PHONY: clean
clean:
	rm -rf *.dot *.png
	make -C c clean
