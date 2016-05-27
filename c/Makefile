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

tests.pb-c.c: tests.proto
	protoc-c --c_out=$(@D) --proto_path=$(<D) $<

tests.pb-c.h: tests.pb-c.c

.PHONY: test
test: test.c tests.pb-c.c tokenizer.o
	$(CC) $(CFLAGS) $(shell pkg-config --cflags 'libprotobuf-c >= 1.0.0') $(LDFLAGS) $(shell pkg-config --libs 'libprotobuf-c >= 1.0.0') $+ -o $@
	./$@ | ../js/node_modules/.bin/tap-summary

.PHONY: clean
clean:
	rm -rf *.dot *.png tokenizer.c tokenizer
