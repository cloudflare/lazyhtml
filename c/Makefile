CC = clang # gcc doesn't support some of the features we use
RAGEL = ragel
RAGELFLAGS = -G2
CFLAGS = -g -O3 -Wall -Wextra -Wcast-qual -Wwrite-strings -Wshadow -Winline -Wdisabled-optimization -Wconversion -Wnull-dereference -Wuninitialized -Wcast-align -Werror -Wmissing-field-initializers
LDFLAGS =

.PHONY: print-builddeps
print-builddeps:
	@echo clang protobuf-c-compiler libprotobuf-c-dev

tokenizer.c: tokenizer.rl actions.rl $(wildcard syntax/*.rl)
	$(RAGEL) $(RAGELFLAGS) -s $<

tokenizer.o: tokenizer.c tokenizer.h
	$(CC) $(CFLAGS) -c -Wno-parentheses-equality -Wno-unused-const-variable $< -o $@

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

.PHONY: test
test: test.o tests.pb-c.o tokenizer.o parser-feedback.o concat-char-tokens.o decoder.o
	$(CC) $(CFLAGS) $(shell pkg-config --cflags 'libprotobuf-c >= 1.0.0') $(LDFLAGS) $(shell pkg-config --libs 'libprotobuf-c >= 1.0.0') $+ -o $@
	./$@ | ../js/node_modules/.bin/tap-summary

.PHONY: clean
clean:
	rm -rf *.dot *.png *.o tokenizer.c tokenizer test
