RAGEL = ragel
RAGELFLAGS += --reduce-frontend -F1 -P
CFLAGS += -g $(shell pkg-config --cflags json-c)
LDFLAGS += $(shell pkg-config --libs json-c)

tokenizer.js: tokenizer.rl actions.rl $(wildcard ../syntax/*.rl)
	cd .. && $(RAGEL) $(RAGELFLAGS) -s js/$< | grep -v "^compiling"

.PHONY: test
test: test.js tokenizer.js
	npm test

.PHONY: bench
bench: bench.js tokenizer.js
	npm run bench

.PHONY: clean
clean:
	rm -rf tokenizer.js
