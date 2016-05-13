RAGEL = ragel
RAGELFLAGS += --reduce-frontend -G2
CFLAGS += -g $(shell pkg-config --cflags json-c)
LDFLAGS += $(shell pkg-config --libs json-c)

tokenizer.c: tokenizer.rl actions.rl $(wildcard syntax/*.rl)
	cd .. && $(RAGEL) $(RAGELFLAGS) -s c/$< | grep -v "^compiling"

tokenizer: tokenizer.c
	$(CC) $(CFLAGS) $(LDFLAGS) $< -o $@

.PHONY: clean
clean:
	rm -rf *.dot *.png tokenizer.c tokenizer
