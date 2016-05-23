RAGEL = ragel
RAGELFLAGS = --reduce-frontend -G2
CFLAGS = -g
LDFLAGS =

tokenizer.c: tokenizer.rl actions.rl $(wildcard syntax/*.rl)
	cd .. && $(RAGEL) $(RAGELFLAGS) -s c/$< | grep -v "^compiling"

tokenizer.o: tokenizer.c tokenizer.h
	$(CC) $(CFLAGS) -c -Wno-parentheses-equality $< -o $@

trace: trace.c tokenizer.o
	$(CC) $(CFLAGS) $(LDFLAGS) $+ -o $@

.PHONY: clean
clean:
	rm -rf *.dot *.png tokenizer.c tokenizer
