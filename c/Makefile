RAGEL = ragel
RAGELFLAGS = -G2
CFLAGS = -g -O3
override CFLAGS += -std=c99 -Wall -Wextra -Wcast-qual -Wwrite-strings -Wshadow -Winline -Wdisabled-optimization -Wuninitialized -Wcast-align -Wno-missing-field-initializers -Werror
OUT = out
TARGET := $(shell $(CC) -dumpmachine)
OUT_TARGET := $(OUT)/$(TARGET)
RAGEL_SOURCES := actions.rl $(wildcard ../syntax/*.rl)
SOURCES := $(wildcard *.c)

## Phony tasks

.PHONY: all
all: lib

.PHONY: lib
lib: $(OUT_TARGET)/liblhtml.a

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

$(OUT)/tokenizer.c: tokenizer.rl $(RAGEL_SOURCES) | $(OUT)
	$(RAGEL) $(RAGELFLAGS) $< -o $@

$(OUT)/tokenizer-states.h: tokenizer-states.rl $(RAGEL_SOURCES) | $(OUT)
	$(RAGEL) $(RAGELFLAGS) $< -o $@

$(OUT)/%.d: %.c | $(OUT)
	$(CC) $(CFLAGS) -MM $< -MT "\$$(OUT)/$(@F)" -MT "\$$(OUT_TARGET)/$(@F:.d=.o)" -MP -MF $@

$(OUT)/tokenizer.d: $(OUT)/tokenizer.c
	$(CC) $(CFLAGS) -xc -iquote. -MM $< -MT "\$$(OUT)/$(@F)" -MT "\$$(OUT_TARGET)/$(@F:.d=.o)" -MP -MF $@

ifneq (, $(filter all lib bench $(OUT)/%.d $(OUT_TARGET)/%, $(MAKECMDGOALS)))
-include $(patsubst %.c, $(OUT)/%.d, $(SOURCES))
-include $(OUT)/tokenizer.d
endif

## Object files

$(OUT_TARGET)/%.o: | $(OUT_TARGET)
	$(CC) $(CFLAGS) -c $< -o $@

$(OUT_TARGET)/tokenizer.o: $(OUT)/tokenizer-states.h
$(OUT_TARGET)/tokenizer.o:
	$(CC) $(CFLAGS) -c $< -include $(OUT)/tokenizer-states.h -iquote. -Wno-parentheses-equality -o $@

$(OUT_TARGET)/parser-feedback.o: $(OUT)/tokenizer-states.h
$(OUT_TARGET)/parser-feedback.o:
	$(CC) $(CFLAGS) -c $< -include $(OUT)/tokenizer-states.h -o $@

## Final library and binaries

$(OUT_TARGET)/liblhtml.a: $(OUT_TARGET)/tokenizer.o $(OUT_TARGET)/parser-feedback.o $(OUT_TARGET)/serializer.o
	ar rcs $@ $?

$(OUT_TARGET)/trace: $(OUT_TARGET)/trace.o $(OUT_TARGET)/tokenizer.o $(OUT_TARGET)/parser-feedback.o
$(OUT_TARGET)/bench: $(OUT_TARGET)/bench.o $(OUT_TARGET)/liblhtml.a
