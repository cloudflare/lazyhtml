RAGEL = ragel
RAGELFLAGS += --reduce-frontend -F1
CFLAGS += -g $(shell pkg-config --cflags json-c)
LDFLAGS += $(shell pkg-config --libs json-c)

RL_FILES := $(wildcard syntax/*.rl)

%.dot: js-tokenizer.rl $(RL_FILES)
	$(RAGEL) $(RAGELFLAGS) -PVp -M $(notdir $(basename $@)) $< > $@
	node simplify-graph.js $@

%.png: %.dot
	dot -Tpng $< -o $@
	open $@

c-tokenizer.c: c-tokenizer.rl c-actions.rl $(RL_FILES)
	$(RAGEL) $(RAGELFLAGS) $<

js-tokenizer.js: js-tokenizer.rl js-actions.rl $(RL_FILES)
	$(RAGEL) $(RAGELFLAGS) -Ps $< | grep -v "^compiling"

.PHONY: js-tokenizer
js-tokenizer: js-tokenizer.js

c-tokenizer: c-tokenizer.c
	$(CC) $(CFLAGS) $(LDFLAGS) $< -o $@

.PHONY: test
test: test.js js-tokenizer.js
	npm test

.PHONY: bench
bench: bench/index.js js-tokenizer.js
	npm run bench

.PHONY: clean
clean:
	rm -rf *.dot *.png c-tokenizer.c c-tokenizer js-tokenizer.js
