RAGEL = ragel
RAGELFLAGS = --reduce-frontend --colm-backend -G2 -L
CFLAGS = -g -O3 -Wall -Wextra -Werror
LDFLAGS =

tokenizer.c: tokenizer.rl actions.rl $(wildcard syntax/*.rl)
	cd .. && $(RAGEL) $(RAGELFLAGS) -s c/$< | grep -v "^compiling"

tokenizer.o: tokenizer.c tokenizer.h
	$(CC) $(CFLAGS) -c -Wno-parentheses-equality -Wno-unused-const-variable $< -o $@

parser-feedback.o: parser-feedback.c parser-feedback.h
tests.pb-c.o: tests.pb-c.c tests.pb-c.h
test.o: test.c
trace.o: trace.c

parser-feedback.o tests.pb-c.o test.o trace.o:
	$(CC) $(CFLAGS) -c $< -o $@

trace: trace.o tokenizer.o parser-feedback.o
	$(CC) $(CFLAGS) $(LDFLAGS) $+ -o $@

tests.pb-c.c: tests.proto
	protoc-c --c_out=$(@D) --proto_path=$(<D) $<

tests.pb-c.h: tests.pb-c.c

.PHONY: test
test: test.o tests.pb-c.o tokenizer.o
	$(CC) $(CFLAGS) $(shell pkg-config --cflags 'libprotobuf-c >= 1.0.0') $(LDFLAGS) $(shell pkg-config --libs 'libprotobuf-c >= 1.0.0') $+ -o $@
	./$@ | ../js/node_modules/.bin/tap-summary

.PHONY: clean
clean:
	rm -rf *.dot *.png *.o tokenizer.c tokenizer test
