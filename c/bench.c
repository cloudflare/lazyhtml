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

static void writehbstr(lhtml_string_t str, void *extra) {
    (void) extra;
    fwrite(str.data, str.length, 1, out);
}

static void modtoken(lhtml_token_t *token, void *extra) {
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
    lhtml_emit(token, extra);
}

static const int CHUNK_SIZE = 1024;
#define BUFFER_SIZE (100 << 10)

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

    out = fopen(argv[2], "wb");

    uint64_t start = mach_absolute_time();

    for (int i = 0; i < 100; i++) {
        rewind(out);

        const lhtml_options_t options = {
            .allow_cdata = false,
            .last_start_tag_name = {
                .length = 0
            },
            .initial_state = LHTML_STATE_DATA,
            .buffer = buffer,
            .buffer_size = BUFFER_SIZE
        };

        lhtml_state_t state;
        lhtml_init(&state, &options);

        lhtml_feedback_state_t pf_state;
        lhtml_feedback_inject(&state, &pf_state);

        lhtml_token_handler_t handler;
        lhtml_add_handler(&state, &handler, modtoken);

        lhtml_serializer_state_t serializer_state;
        lhtml_serializer_inject(&state, &serializer_state, (lhtml_serializer_options_t) {
            .writer = writehbstr,
            .compact = false
        });

        lhtml_string_t chunk = {
            .data = html,
            .length = CHUNK_SIZE
        };

        const char *lastChunk = html + (total_length - (total_length % CHUNK_SIZE));

        for (; chunk.data < lastChunk; chunk.data += CHUNK_SIZE) {
            lhtml_feed(&state, &chunk);
        }

        chunk.length = total_length % CHUNK_SIZE;

        lhtml_feed(&state, &chunk);

        lhtml_feed(&state, NULL);
    }

    fprintf(stderr, "Total time: %lluµs\n", (mach_absolute_time() - start) / 1000 / 100);

    free(html);

    fclose(out);

	return 0;
}
