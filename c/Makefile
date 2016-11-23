RAGEL = ragel
RAGELFLAGS = -G2
CFLAGS = -g -O3
override CFLAGS += -std=c99 -Wall -Wextra -Wcast-qual -Wwrite-strings -Wshadow -Winline -Wdisabled-optimization -Wuninitialized -Wcast-align -Wmissing-field-initializers -Werror -Wno-error=missing-field-initializers
TESTS := $(wildcard ../tests*.dat)
OUT = out
TARGET := $(shell $(CC) -dumpmachine)
OUT_TARGET := $(OUT)/$(TARGET)
RAGEL_SOURCES := tokenizer.rl $(wildcard ../syntax/*.rl)
SOURCES := $(wildcard *.c)

## Phony tasks

.PHONY: all
all: lib quick-test

.PHONY: lib
lib: $(OUT_TARGET)/liblhtml.a

# doesn't print test names, error details etc., but useful for quick checks
.PHONY: quick-test
quick-test: $(OUT_TARGET)/test-runner $(TESTS)
	prove --exec $+

.PHONY: test
test: $(OUT_TARGET)/test-runner $(TESTS)
	($(patsubst %, $(OUT_TARGET)/test-runner %;, $(TESTS))) | tap-summary

.PHONY: bamboo-test
$(OUT_TARGET)/%.xml: ../%.dat $(OUT_TARGET)/test-runner
	$(OUT_TARGET)/test-runner $< | tail -n +2 | tap-xunit > $@

bamboo-test: $(patsubst ../%.dat, $(OUT_TARGET)/%.xml, $(TESTS))

.PHONY: clean-obj
clean-obj:
	rm -rf $(OUT_TARGET)

.PHONY: clean
clean:
	rm -rf $(OUT)

.PHONY: bench
bench: $(OUT_TARGET)/bench
	@for f in ../bench-fixtures/*.html; do echo $$f; $< $$f /dev/null; done

## Intermediate dependencies

$(OUT) $(OUT_TARGET):
	mkdir -p $@

$(OUT)/tokenizer.c: $(RAGEL_SOURCES) | $(OUT)
	$(RAGEL) $(RAGELFLAGS) -s $< -o /dev/stdout | sed -E 's/^static const int ([^ ]+) = ([0-9]+);/#define \1 \2/g' > $@

tests.pb-c.c: tests.proto
	protoc-c --c_out=$(@D) --proto_path=$(<D) $<

tests.pb-c.h: | tests.pb-c.c

$(OUT)/%.d: %.c | $(OUT)
	$(CC) $(CFLAGS) -DPROTOBUF_C_tests_2eproto__INCLUDED -MM $< -MT "\$$(OUT)/$(@F)" -MT "\$$(OUT_TARGET)/$(@F:.d=.o)" -MP -MF $@

$(OUT)/tokenizer.d: tokenizer.rl | $(OUT)
	$(CC) $(CFLAGS) -xc -iquote. -MM $< -MT "\$$(OUT)/$(@F)" -MT "\$$(OUT_TARGET)/$(@F:.d=.o)" -MP -MF $@

ifneq (, $(filter all lib %test bench $(OUT)/%.d $(OUT_TARGET)/%, $(MAKECMDGOALS)))
-include $(patsubst %.c, $(OUT)/%.d, $(SOURCES))
-include $(OUT)/tokenizer.d
endif

## Object files

$(OUT_TARGET)/%.o: | $(OUT_TARGET)
	$(CC) $(CFLAGS) -c $< -o $@

$(OUT_TARGET)/tokenizer.o: $(OUT)/tokenizer.c | $(OUT_TARGET)
	$(CC) $(CFLAGS) -iquote. -c $< -o $@

$(OUT_TARGET)/test.o: | $(OUT_TARGET)
	$(CC) $(CFLAGS) -Wno-cast-qual -Wno-cast-align -c $< -o $@

## Final library and binaries

$(OUT_TARGET)/liblhtml.a: $(OUT_TARGET)/tokenizer.o $(OUT_TARGET)/parser-feedback.o $(OUT_TARGET)/serializer.o
	ar rcs $@ $?

$(OUT_TARGET)/trace: $(OUT_TARGET)/trace.o $(OUT_TARGET)/tokenizer.o $(OUT_TARGET)/parser-feedback.o
$(OUT_TARGET)/bench: $(OUT_TARGET)/bench.o $(OUT_TARGET)/liblhtml.a

$(OUT_TARGET)/test-runner: $(OUT_TARGET)/test.o $(OUT_TARGET)/tests.pb-c.o $(OUT_TARGET)/tokenizer.o $(OUT_TARGET)/parser-feedback.o $(OUT_TARGET)/concat-char-tokens.o $(OUT_TARGET)/decoder.o
	$(CC) $(CFLAGS) $(shell pkg-config --cflags 'libprotobuf-c >= 1.0.0') $(shell pkg-config --libs 'libprotobuf-c >= 1.0.0') $+ -o $@
