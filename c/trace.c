#include <assert.h>
#include <stdio.h>
#include <strings.h>
#include "tokenizer.h"

const char *TOKEN_TYPE_NAMES[] = {
    "None",
    "Character",
    "Comment",
    "StartTag",
    "EndTag",
    "DocType"
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

static void on_token(const Token *token) {
    printf("%s { ", TOKEN_TYPE_NAMES[token->type]);
    switch (token->type) {
        case token_character:
            printf(".kind = %s, .value = ", TOKEN_CHARACTER_KIND_NAMES[token->character.kind]);
            print_string(&token->character.value);
            break;

        case token_comment:
            printf(".value = ");
            print_string(&token->comment.value);
            break;

        case token_start_tag:
            printf(".name = ");
            print_string(&token->start_tag.name);
            printf(", .self_closing = %s, .attributes = { ", token->start_tag.self_closing ? "true" : "false");
            const TokenAttributes *attributes = &token->start_tag.attributes;
            const unsigned int count = attributes->count;
            const Attribute *items = attributes->items;
            for (int i = 0; i < count; i++) {
                if (i > 0) {
                    printf(", ");
                }
                const Attribute *attr = &items[i];
                print_string(&attr->name);
                printf(" = ");
                print_string(&attr->value);
            }
            printf(" } ");
            break;

        case token_end_tag:
            printf(".name = ");
            print_string(&token->end_tag.name);
            break;

        case token_doc_type:
            printf(".name = ");
            print_opt_string(&token->doc_type.name);
            printf(", .public_id = ");
            print_opt_string(&token->doc_type.public_id);
            printf(", .system_id = ");
            print_opt_string(&token->doc_type.system_id);
            printf(", .force_quirks = %s", token->doc_type.force_quirks ? "true" : "false");
            break;

        case token_none:
            break;
    }
    printf("}\n");
}

int main(const int argc, const char *const argv[]) {
    assert(argc >= 2);
    TokenizerState state;
    const TokenizerOpts options = {
        .allow_cdata = false,
        .on_token = on_token,
        .last_start_tag_name = NULL,
        .initial_state = html_state_Data,
        .buffer = {
            .length = 0,
            .data = NULL
        }
    };
    html_tokenizer_init(&state, &options);
    const TokenizerString str = {
        .length = strlen(argv[1]),
        .data = argv[1]
    };
    assert(html_tokenizer_feed(&state, &str) != html_state_error);
    // assert(html_tokenizer_feed(&state, NULL) != html_state_error);
    return 0;
}
