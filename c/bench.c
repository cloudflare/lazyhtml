#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "tokenizer.h"
#include <mach/mach_time.h>
#include <stdbool.h>
#include "parser-feedback.h"
#include "serializer.h"

static FILE *out;

static void writehbstr(lhtml_string_t str, __attribute__((unused)) lhtml_serializer_state_t *serializer) {
    fwrite(str.data, str.length, 1, out);
}

typedef struct {
    lhtml_token_handler_t handler;
    lhtml_feedback_state_t *feedback;
} bench_state_t;

static void modtoken(lhtml_token_t *token, bench_state_t *bench_state) {
    if (token->type == LHTML_TOKEN_START_TAG) {
        lhtml_token_starttag_t *tag = &token->start_tag;
        if (tag->type == LHTML_TAG_A) {
            lhtml_attribute_t *href = LHTML_FIND_ATTR(&tag->attributes, "href");
            if (href != NULL) {
                token->raw.has_value = href->raw.has_value = false;
                href->value = LHTML_STRING("[REPLACED]");
            }
        }
    }
    lhtml_emit(token, bench_state);
}

static const int CHUNK_SIZE = 1024;
#define BUFFER_SIZE (100 << 10)
#define MAX_ATTR_COUNT 256
#define MAX_NS_DEPTH 64

int main(int argc, char **argv) {
    assert(argc >= 3);

    FILE *in = fopen(argv[1], "rb");
    fseek(in, 0, SEEK_END);
    size_t total_length = (size_t) ftell(in);
    rewind(in);

    char *html = malloc(total_length);
    fread(html, total_length, 1, in);

    fclose(in);

    char buffer[BUFFER_SIZE];
    lhtml_attribute_t attr_buffer[MAX_ATTR_COUNT];
    lhtml_ns_t ns_buffer[MAX_NS_DEPTH];

    out = fopen(argv[2], "wb");

    uint64_t start = mach_absolute_time();

    for (int i = 0; i < 100; i++) {
        rewind(out);

        lhtml_state_t state = {
            .buffer = {
                .data = buffer,
                .capacity = BUFFER_SIZE
            },
            .attr_buffer = {
                .data = attr_buffer,
                .capacity = MAX_ATTR_COUNT
            }
        };

        lhtml_init(&state);

        lhtml_feedback_state_t pf_state = {
            .ns_stack = {
                .data = ns_buffer,
                .capacity = MAX_NS_DEPTH
            }
        };
        lhtml_feedback_inject(&state, &pf_state);

        bench_state_t bench_state = {
            .feedback = &pf_state
        };
        LHTML_ADD_HANDLER(&state, &bench_state, modtoken);

        lhtml_serializer_state_t serializer_state = {
            .writer = writehbstr
        };
        lhtml_serializer_inject(&state, &serializer_state);

        lhtml_string_t chunk = {
            .data = html,
            .length = CHUNK_SIZE
        };

        const char *lastChunk = html + (total_length - (total_length % CHUNK_SIZE));

        for (; chunk.data < lastChunk; chunk.data += CHUNK_SIZE) {
            assert(lhtml_feed(&state, &chunk));
        }

        chunk.length = total_length % CHUNK_SIZE;

        assert(lhtml_feed(&state, &chunk));

        assert(lhtml_feed(&state, NULL));
    }

    fprintf(stderr, "Total time: %lluµs\n", (mach_absolute_time() - start) / 1000 / 100);

    free(html);

    fclose(out);

	return 0;
}
