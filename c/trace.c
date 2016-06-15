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

static void print_string(const TokenizerString *str) {
    printf("'");
    fwrite(str->data, sizeof(char), str->length, stdout);
    printf("'");
}

static void print_opt_string(const TokenizerOptionalString *str) {
    if (str->has_value) {
        print_string(&str->value);
    } else {
        printf("(none)");
    }
}

static void on_token(Token *token, __attribute__((unused)) void *extra) {
    printf("%s { ", TOKEN_TYPE_NAMES[token->type]);
    switch (token->type) {
        case token_character:
            printf(".kind = %s, .value = ", TOKEN_CHARACTER_KIND_NAMES[token->character.kind]);
            print_string(&token->character.value);
            printf(", ");
            break;

        case token_comment:
            printf(".value = ");
            print_string(&token->comment.value);
            printf(", ");
            break;

        case token_start_tag:
            printf(".name = ");
            print_string(&token->start_tag.name);
            printf(", .self_closing = %s, .attributes = { ", token->start_tag.self_closing ? "true" : "false");
            const TokenAttributes *attributes = &token->start_tag.attributes;
            const size_t count = attributes->count;
            const Attribute *items = attributes->items;
            for (size_t i = 0; i < count; i++) {
                if (i > 0) {
                    printf(", ");
                }
                const Attribute *attr = &items[i];
                print_string(&attr->name);
                printf(" = ");
                print_string(&attr->value);
            }
            printf(" } , ");
            break;

        case token_end_tag:
            printf(".name = ");
            print_string(&token->end_tag.name);
            printf(", ");
            break;

        case token_doc_type:
            printf(".name = ");
            print_opt_string(&token->doc_type.name);
            printf(", .public_id = ");
            print_opt_string(&token->doc_type.public_id);
            printf(", .system_id = ");
            print_opt_string(&token->doc_type.system_id);
            printf(", .force_quirks = %s, ", token->doc_type.force_quirks ? "true" : "false");
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
    TokenizerState state;
    const char *data = NULL;
    size_t chunk_size = 1024;
    size_t buffer_size = 1024;
    int initial_state = html_state_Data;
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
                    initial_state = html_state_Data;
                    continue;
                }
                if (strcasecmp(arg, "PlainText") == 0) {
                    initial_state = html_state_PlainText;
                    continue;
                }
                if (strcasecmp(arg, "RCData") == 0) {
                    initial_state = html_state_RCData;
                    continue;
                }
                if (strcasecmp(arg, "RawText") == 0) {
                    initial_state = html_state_RawText;
                    continue;
                }
                if (strcasecmp(arg, "ScriptData") == 0) {
                    initial_state = html_state_ScriptData;
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
    const TokenizerOpts options = {
        .allow_cdata = false,
        .on_token = on_token,
        .last_start_tag_name = { .length = 0 },
        .initial_state = initial_state,
        .buffer = buffer,
        .buffer_size = buffer_size
    };
    html_tokenizer_init(&state, &options);
    ParserFeedbackState pf_state;
    if (with_feedback) {
        parser_feedback_inject(&state, &pf_state);
    }
    const size_t total_len = strlen(data);
    for (size_t i = 0; i < total_len; i += chunk_size) {
        const TokenizerString str = {
            .data = data + i,
            .length = min(chunk_size, total_len - i)
        };
        printf("// Feeding chunk '%.*s'\n", (int) str.length, str.data);
        html_tokenizer_feed(&state, &str);
        assert(state.cs != html_state_error);
        printf("// Buffer contents: '%.*s'\n", (int) (state.buffer_pos - state.token.raw.data), state.token.raw.data);
    }
    html_tokenizer_feed(&state, NULL);
    assert(state.cs != html_state_error);
    return 0;
}
