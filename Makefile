RAGEL = ragel
RAGELFLAGS += -F1
CFLAGS += -g $(shell pkg-config --cflags json-c)
LDFLAGS += $(shell pkg-config --libs json-c)

%.dot: js-tokenizer.rl syntax.rl
	$(RAGEL) $(RAGELFLAGS) -PVp -M $(notdir $(basename $@)) $< > $@ || rm $@
	node --harmony-destructuring simplify-graph.js $@

%.png: %.dot
	dot -Tpng $< -o $@
	open $@

c-tokenizer.c: c-tokenizer.rl c-actions.rl syntax.rl
	$(RAGEL) $(RAGELFLAGS) $<

js-tokenizer.js: js-tokenizer.rl js-actions.rl syntax.rl
	$(RAGEL) $(RAGELFLAGS) -P $<

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
