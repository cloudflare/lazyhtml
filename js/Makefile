RAGEL = ragel
RAGELFLAGS += --reduce-frontend -F1 -P
CFLAGS += -g $(shell pkg-config --cflags json-c)
LDFLAGS += $(shell pkg-config --libs json-c)

tokenizer.js: tokenizer.rl actions.rl $(wildcard ../syntax/*.rl)
decoder.js: decoder.rl actions.rl ../syntax/decoder.rl

tokenizer.js decoder.js:
	cd .. && $(RAGEL) $(RAGELFLAGS) -s js/$< | grep -v "^compiling"

.PHONY: test
test: test.js tokenizer.js decoder.js ../tests.dat
	npm test

.PHONY: bench
bench: bench.js tokenizer.js decoder.js
	npm run bench

.PHONY: clean
clean:
	rm -rf tokenizer.js decoder.js
