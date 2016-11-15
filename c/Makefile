RAGEL = ragel
RAGELFLAGS = -G2
CFLAGS = $(EXTRA_CFLAGS) -g -O3 -std=c99 -Wall -Wextra -Wcast-qual -Wwrite-strings -Wshadow -Winline -Wdisabled-optimization -Wuninitialized -Wcast-align -Werror -Wmissing-field-initializers
LDFLAGS =

.PHONY: print-builddeps
print-builddeps:
	@echo pkg-config nodejs libprotobuf-c-dev ragel

tokenizer.c: tokenizer.rl actions.rl $(wildcard syntax/*.rl)
	$(RAGEL) $(RAGELFLAGS) -s $<
	sed -i.bak -E 's/^static const int ([^ ]+) = ([0-9]+);/#define \1 \2/g' $@
	rm $@.bak

tokenizer.o: tokenizer.c tokenizer.h
	$(CC) $(CFLAGS) -Wno-unused -c $< -o $@

tests.pb-c.c: tests.proto
	protoc-c --c_out=$(@D) --proto_path=$(<D) $<

tests.pb-c.h: tests.pb-c.c

parser-feedback.o: parser-feedback.c parser-feedback.h
serializer.o: serializer.c serializer.h
concat-char-tokens.o: concat-char-tokens.c concat-char-tokens.h
decoder.o: decoder.c decoder.h
tests.pb-c.o: tests.pb-c.c tests.pb-c.h
trace.o: trace.c
bench.o: bench.c

parser-feedback.o serializer.o concat-char-tokens.o decoder.o tests.pb-c.o trace.o bench.o:
	$(CC) $(CFLAGS) -c $< -o $@

transformer.a: tokenizer.o parser-feedback.o serializer.o
	ar rcs $@ $+

trace: trace.o tokenizer.o parser-feedback.o
bench: bench.o transformer.a
	$(CC) $(CFLAGS) $(LDFLAGS) $+ -o $@

test.o: test.c tests.pb-c.h
	$(CC) $(CFLAGS) -Wno-cast-qual -Wno-cast-align -c $< -o $@

test-runner: test.o tests.pb-c.o tokenizer.o parser-feedback.o concat-char-tokens.o decoder.o
	$(CC) $(CFLAGS) $(shell pkg-config --cflags 'libprotobuf-c >= 1.0.0') $(LDFLAGS) $(shell pkg-config --libs 'libprotobuf-c >= 1.0.0') $+ -o $@

.PHONY: test
test: test-runner
ifndef CI
	./$< | ../js/node_modules/.bin/tap-summary
else
	echo "{}" > package.json
	npm i tap-xunit
	./$< | tail -n +2 | ./node_modules/tap-xunit/bin/tap-xunit > results.xml
endif

.PHONY: clean
clean:
	rm -rf *.dot *.png *.o tokenizer{.c,.a,} test
