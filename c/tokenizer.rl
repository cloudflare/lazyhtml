#include <stdio.h>
#include <assert.h>
#include <strings.h>
#include <stdbool.h>

%%{
    machine html;

    access state->;

    include 'c/actions.rl';
    include 'syntax/index.rl';

    write data nofinal noprefix;
}%%

typedef struct {
    const char *data;
    size_t length;
} TokenizerString;

typedef struct {
    bool has_value;
    TokenizerString value;
} TokenizerOptionalString;

typedef enum {
    token_none,
    token_character,
    token_comment,
    token_start_tag,
    token_end_tag,
    token_doc_type
} TokenType;

typedef enum {
    token_character_raw,
    token_character_data,
    token_character_rcdata,
    token_character_cdata,
    token_character_safe
} TokenCharacterKind;

typedef struct {
    TokenCharacterKind kind;
    TokenizerString value;
} TokenCharacter;

typedef struct {
    TokenizerString value;
} TokenComment;

typedef struct {
    TokenizerString name;
    TokenizerString value;
} Attribute;

const unsigned int MAX_ATTR_COUNT = 256;

typedef struct {
    unsigned int count;
    Attribute items[MAX_ATTR_COUNT];
} TokenAttributes;

typedef struct {
    TokenizerString name;
    bool self_closing;
    TokenAttributes attributes;
} TokenStartTag;

typedef struct {
    TokenizerString name;
} TokenEndTag;

typedef struct {
    TokenizerOptionalString name;
    TokenizerOptionalString public_id;
    TokenizerOptionalString system_id;
    bool force_quirks;
} TokenDocType;

typedef struct {
    TokenType type;
    union {
        TokenCharacter character;
        TokenComment comment;
        TokenStartTag start_tag;
        TokenEndTag end_tag;
        TokenDocType doc_type;
    };
    TokenizerString raw;
} Token;

#define get_token(state, wanted_type) (assert(state->token.type == token_##wanted_type), &state->token.wanted_type)

#define create_token(state, wanted_type) (state->token.type = token_##wanted_type, &state->token.wanted_type)

typedef void (*TokenHandler)(const Token *token);

typedef struct TokenizerState {
    bool allow_cdata;
    TokenHandler emit_token;
    TokenizerString last_start_tag_name;
    char quote;
    Token token;
    Attribute *attribute;
    const char *start_slice;
    const char *mark;
    const char *appropriate_end_tag_offset;
    TokenizerString buffer;
    int cs;
} TokenizerState;

typedef struct TokenizerOpts {
    bool allow_cdata;
    TokenHandler on_token;
    TokenizerString last_start_tag_name;
    int initial_state;
    TokenizerString buffer;
} TokenizerOpts;

static void set_string(TokenizerString *dest, const char *start, const char *end) {
    assert(end >= start);
    dest->length = end - start;
    dest->data = start;
}

static void reset_string(TokenizerString *dest) {
    dest->length = 0;
}

static void set_opt_string(TokenizerOptionalString *dest, const char *start, const char *end) {
    dest->has_value = true;
    set_string(&dest->value, start, end);
}

static void reset_opt_string(TokenizerOptionalString *dest) {
    dest->has_value = false;
}

static void token_init_character(TokenizerState *state, TokenCharacterKind kind) {
    TokenCharacter *character = create_token(state, character);
    character->kind = kind;
    reset_string(&character->value);
}

void html_tokenizer_init(TokenizerState *state, const TokenizerOpts *options) {
    %%write init nocs;
    state->allow_cdata = options->allow_cdata;
    state->emit_token = options->on_token;
    state->last_start_tag_name = options->last_start_tag_name;
    state->token.type = token_none;
    reset_string(&state->token.raw);
    state->quote = 0;
    state->attribute = NULL;
    state->start_slice = NULL;
    state->mark = NULL;
    state->appropriate_end_tag_offset = NULL;
    state->buffer = options->buffer;
    state->cs = options->initial_state;
}

int html_tokenizer_feed(TokenizerState *state, const TokenizerString *chunk) {
    const char *const start = chunk != NULL ? chunk->data : NULL;
    const char *p = start;
    const char *const pe = chunk != NULL ? start + chunk->length : NULL;
    const char *const eof = NULL;

    %%write exec;

    return state->cs;
}

const char NULL_CHAR = '\0';

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
        .initial_state = en_Data,
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
    assert(html_tokenizer_feed(&state, &str) != error);
    assert(html_tokenizer_feed(&state, NULL) != error);
    return 0;
}
