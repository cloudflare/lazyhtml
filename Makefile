RAGEL = ragel
RAGELFLAGS += --reduce-frontend -F1
CFLAGS += -g $(shell pkg-config --cflags json-c)
LDFLAGS += $(shell pkg-config --libs json-c)

RL_FILES := $(wildcard syntax/*.rl)

%.dot: js/tokenizer.rl $(RL_FILES)
	$(RAGEL) $(RAGELFLAGS) -PVp -M $(notdir $(basename $@)) $< > $@
	node simplify-graph.js $@

%.png: %.dot
	dot -Tpng $< -o $@
	open $@

tests.dat: convert-tests.js js/tests.proto .git/modules/html5lib-tests/HEAD
	node $< html5lib-tests/tokenizer $@

tests-with-feedback.dat: convert-tests.js js/tests.proto
	node $< parser-feedback-tests $@

.PHONY: clean
clean:
	rm -rf *.dot *.png

.PHONY: js-tokenizer
js-tokenizer:
	make -C js tokenizer.js

.PHONY: c-tokenizer
c-tokenizer:
	make -C c tokenizer
