RAGEL = ragel
CFLAGS += $(shell pkg-config --cflags json-c)
LDFLAGS += $(shell pkg-config --libs json-c)

c-tokenizer.c: c-tokenizer.rl c-actions.rl syntax.rl
	$(RAGEL) $<

js-tokenizer.js: js-tokenizer.rl js-actions.rl syntax.rl
	$(RAGEL) -P $<

.PHONY: js-tokenizer
js-tokenizer: js-tokenizer.js

c-tokenizer: c-tokenizer.c
	$(CC) $(CFLAGS) $(LDFLAGS) $< -o $@
