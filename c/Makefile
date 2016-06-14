RAGEL = ragel
RAGELFLAGS = --reduce-frontend --direct-backend -G2 -L
CFLAGS = -g -O3 -Wall -Wextra -Wcast-qual -Wwrite-strings -Wshadow -Winline -Wdisabled-optimization -Wconversion -Wnull-dereference -Wuninitialized -Wcast-align -Werror -Wmissing-field-initializers
LDFLAGS =

tokenizer.c: tokenizer.rl actions.rl $(wildcard syntax/*.rl)
	cd .. && $(RAGEL) $(RAGELFLAGS) -s c/$< | grep -v "^compiling"

tokenizer.o: tokenizer.c tokenizer.h
	$(CC) $(CFLAGS) -c -Wno-parentheses-equality -Wno-unused-const-variable $< -o $@

parser-feedback.o: parser-feedback.c parser-feedback.h
tests.pb-c.o: tests.pb-c.c tests.pb-c.h
trace.o: trace.c

parser-feedback.o tests.pb-c.o trace.o:
	$(CC) $(CFLAGS) -c $< -o $@

trace: trace.o tokenizer.o parser-feedback.o
	$(CC) $(CFLAGS) $(LDFLAGS) $+ -o $@

tests.pb-c.c: tests.proto
	protoc-c --c_out=$(@D) --proto_path=$(<D) $<

tests.pb-c.h: tests.pb-c.c

test.o: test.c
	$(CC) $(CFLAGS) -Wno-cast-qual -Wno-cast-align -c $< -o $@

.PHONY: test
test: test.o tests.pb-c.o tokenizer.o parser-feedback.o
	$(CC) $(CFLAGS) $(shell pkg-config --cflags 'libprotobuf-c >= 1.0.0') $(LDFLAGS) $(shell pkg-config --libs 'libprotobuf-c >= 1.0.0') $+ -o $@
	./$@ | ../js/node_modules/.bin/tap-summary

.PHONY: clean
clean:
	rm -rf *.dot *.png *.o tokenizer.c tokenizer test
