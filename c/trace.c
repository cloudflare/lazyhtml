#include <assert.h>
#include <stdio.h>
#include <strings.h>
#include "tokenizer.h"
#include "parser-feedback.h"

const char *TOKEN_TYPE_NAMES[] = {
    "None",
    "Character",
    "Comment",
    "StartTag",
    "EndTag",
    "DocType",
    "EOF"
};

const char *TOKEN_CHARACTER_KIND_NAMES[] = {
    "Raw",
    "Data",
    "RCData",
    "CData",
    "Safe"
};

static void print_string(const lhtml_string_t *str) {
    printf("'");
    fwrite(str->data, sizeof(char), str->length, stdout);
    printf("'");
}

static void print_opt_string(const lhtml_opt_string_t *str) {
    if (str->has_value) {
        print_string(&str->value);
    } else {
        printf("(none)");
    }
}

static void on_token(lhtml_token_t *token, __attribute__((unused)) void *extra) {
    printf("%s { ", TOKEN_TYPE_NAMES[token->type]);
    switch (token->type) {
        case LHTML_TOKEN_CHARACTER:
            printf(".kind = %s, .value = ", TOKEN_CHARACTER_KIND_NAMES[token->character.kind]);
            print_string(&token->character.value);
            printf(", ");
            break;

        case LHTML_TOKEN_COMMENT:
            printf(".value = ");
            print_string(&token->comment.value);
            printf(", ");
            break;

        case LHTML_TOKEN_START_TAG:
            printf(".name = ");
            print_string(&token->start_tag.name);
            printf(", .self_closing = %s, .attributes = { ", token->start_tag.self_closing ? "true" : "false");
            const lhtml_attributes_t *attributes = &token->start_tag.attributes;
            const size_t count = attributes->count;
            const lhtml_attribute_t *items = attributes->items;
            for (size_t i = 0; i < count; i++) {
                if (i > 0) {
                    printf(", ");
                }
                const lhtml_attribute_t *attr = &items[i];
                print_string(&attr->name);
                printf(" = ");
                print_string(&attr->value);
            }
            printf(" } , ");
            break;

        case LHTML_TOKEN_END_TAG:
            printf(".name = ");
            print_string(&token->end_tag.name);
            printf(", ");
            break;

        case LHTML_TOKEN_DOCTYPE:
            printf(".name = ");
            print_opt_string(&token->doctype.name);
            printf(", .public_id = ");
            print_opt_string(&token->doctype.public_id);
            printf(", .system_id = ");
            print_opt_string(&token->doctype.system_id);
            printf(", .force_quirks = %s, ", token->doctype.force_quirks ? "true" : "false");
            break;

        default:
            break;
    }
    printf(".raw = ");
    print_string(&token->raw);
    printf(" }\n");
}

static size_t min(size_t a, size_t b) {
    return a < b ? a : b;
}

int main(const int argc, const char *const argv[]) {
    assert(argc >= 2);
    lhtml_state_t state;
    const char *data = NULL;
    size_t chunk_size = 1024;
    size_t buffer_size = 1024;
    int initial_state = LHTML_STATE_DATA;
    bool with_feedback = false;
    for (int i = 1; i < argc; i++) {
        const char *arg = argv[i];
        if (strncmp(arg, "--", sizeof("--") - 1) == 0) {
            arg += sizeof("--") - 1;
            if (sscanf(arg, "chunk=%zd", &chunk_size) > 0) {
                continue;
            }
            if (sscanf(arg, "buffer=%zd", &buffer_size) > 0) {
                continue;
            }
            if (strncmp(arg, "feedback", sizeof("feedback")) == 0) {
                with_feedback = true;
                continue;
            }
            if (strncmp(arg, "state=", sizeof("state=") - 1) == 0) {
                arg += sizeof("state=") - 1;
                if (strcasecmp(arg, "Data") == 0) {
                    initial_state = LHTML_STATE_DATA;
                    continue;
                }
                if (strcasecmp(arg, "PlainText") == 0) {
                    initial_state = LHTML_STATE_PLAINTEXT;
                    continue;
                }
                if (strcasecmp(arg, "RCData") == 0) {
                    initial_state = LHTML_STATE_RCDATA;
                    continue;
                }
                if (strcasecmp(arg, "RawText") == 0) {
                    initial_state = LHTML_STATE_RAWTEXT;
                    continue;
                }
                if (strcasecmp(arg, "ScriptData") == 0) {
                    initial_state = LHTML_STATE_SCRIPTDATA;
                    continue;
                }
            }
        }
        data = arg;
    }
    assert(data != NULL);
    assert(chunk_size <= 1024);
    assert(buffer_size <= 1024);
    char buffer[buffer_size];
    const lhtml_options_t options = {
        .allow_cdata = false,
        .on_token = on_token,
        .last_start_tag_name = { .length = 0 },
        .initial_state = initial_state,
        .buffer = buffer,
        .buffer_size = buffer_size
    };
    lhtml_init(&state, &options);
    lhtml_feedback_state_t pf_state;
    if (with_feedback) {
        lhtml_feedback_inject(&state, &pf_state);
    }
    const size_t total_len = strlen(data);
    for (size_t i = 0; i < total_len; i += chunk_size) {
        const lhtml_string_t str = {
            .data = data + i,
            .length = min(chunk_size, total_len - i)
        };
        printf("// Feeding chunk '%.*s'\n", (int) str.length, str.data);
        lhtml_feed(&state, &str);
        assert(state.cs != LHTML_STATE_ERROR);
        printf("// Buffer contents: '%.*s'\n", (int) (state.buffer_pos - state.token.raw.data), state.token.raw.data);
    }
    lhtml_feed(&state, NULL);
    assert(state.cs != LHTML_STATE_ERROR);
    return 0;
}
