#ifndef HTML_TOKENIZER_H
#define HTML_TOKENIZER_H

#include <stddef.h>
#include <stdbool.h>

extern const int html_state_error;
extern const int html_state_Data;
extern const int html_state_RCData;
extern const int html_state_RawText;
extern const int html_state_PlainText;
extern const int html_state_ScriptData;

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

#define MAX_ATTR_COUNT 256

typedef struct {
    size_t count;
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
    void *extra;
} Token;

typedef void (*TokenHandler)(const Token *token);

typedef struct {
    bool allow_cdata;
    TokenHandler emit_token;
    TokenizerString last_start_tag_name;
    char quote;
    Token token;
    Attribute *attribute;
    const char *start_slice;
    const char *mark;
    const char *appropriate_end_tag_offset;
    char *buffer;
    char *buffer_pos;
    const char *buffer_end;
    int cs;
} TokenizerState;

typedef struct {
    bool allow_cdata;
    TokenHandler on_token;
    TokenizerString last_start_tag_name;
    int initial_state;
    char *buffer;
    size_t buffer_size;
    void *extra;
} TokenizerOpts;

void html_tokenizer_init(TokenizerState *state, const TokenizerOpts *options);
int html_tokenizer_feed(TokenizerState *state, const TokenizerString *chunk);

#endif
