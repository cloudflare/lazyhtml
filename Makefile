RAGEL = ragel
RAGELFLAGS += -d
CFLAGS += -g $(shell pkg-config --cflags json-c)
LDFLAGS += $(shell pkg-config --libs json-c)

%.dot: js-tokenizer.rl syntax.rl
	$(RAGEL) $(RAGELFLAGS) -PVp -M $(notdir $(basename $@)) $< > $@ || rm $@

%.png: %.dot
	dot -Tpng $< -o $@

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
