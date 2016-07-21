#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "tokenizer.h"
#include <mach/mach_time.h>
#include <stdbool.h>
#include "parser-feedback.h"

static FILE *out;

static void writehbstr(const lhtml_string_t str) {
    fwrite(str.data, str.length, 1, out);
}

#define writestr(str) writehbstr(LHTML_STRING(str))

static void token_handler(lhtml_token_t *token, __attribute__((unused)) void *extra) {
	switch (token->type) {
        case LHTML_TOKEN_START_TAG: {
            const lhtml_token_starttag_t *tag = &token->start_tag;
#ifdef FULL_SERIALIZE
            bool is_a_tag = tag->type == LHTML_TAG_A;
#else
            if (tag->type != LHTML_TAG_A) {
                writehbstr(token->raw);
                return;
            }
            const bool is_a_tag = true;
#endif
            const size_t n_attrs = tag->attributes.count;
            const lhtml_attribute_t *attrs = tag->attributes.items;
            writestr("<");
            writehbstr(tag->name);
            for (size_t i = 0; i < n_attrs; i++) {
                const lhtml_attribute_t *attr = &attrs[i];
                const lhtml_string_t *attr_name = &attr->name;
                if (is_a_tag && LHTML_NAME_EQUALS(*attr_name, "href")) {
                    writestr(" href=\"[REPLACED]\"");
                } else {
                    writestr(" ");
                    assert(attr->raw.has_value);
                    writehbstr(attr->raw.value);
                }
            }
            if (tag->self_closing) {
                writestr("/");
            }
            writestr(">");
            break;
        }

#ifdef FULL_SERIALIZE
        case LHTML_TOKEN_DOCTYPE:
            writestr("<!DOCTYPE");
            if (token->doctype.name.has_value) {
                writestr(" ");
                writehbstr(&token->doctype.name.value);
            }
            if (token->doctype.public_id.has_value) {
                writestr(" \"");
                writehbstr(&token->doctype.public_id.value);
                writestr("\"");
            }
            if (token->doctype.system_id.has_value) {
                writestr(" \"");
                writehbstr(&token->doctype.system_id.value);
                writestr("\"");
            }
            writestr(">");
            break;

        case LHTML_TOKEN_END_TAG:
            writestr("</");
            writehbstr(&token->end_tag.name);
            writestr(">");
            break;

        case LHTML_TOKEN_COMMENT:
            writestr("<!--");
            writehbstr(&token->comment.value);
            writestr("-->");
            break;

        case LHTML_TOKEN_CHARACTER:
            writehbstr(&token->character.value);
            break;

        case LHTML_TOKEN_UNKNOWN:
        case LHTML_TOKEN_EOF:
            break;
#else
        default:
            writehbstr(token->raw);
#endif
	}
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
        lhtml_add_handler(&state, &handler, token_handler);

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
