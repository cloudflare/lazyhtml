#ifndef LHTML_TOKENIZER_H
#define LHTML_TOKENIZER_H

#include <stddef.h>
#include <stdbool.h>
#include <inttypes.h>
#include "tag-types.h"

extern const int LHTML_STATE_ERROR;
extern const int LHTML_STATE_DATA;
extern const int LHTML_STATE_RCDATA;
extern const int LHTML_STATE_RAWTEXT;
extern const int LHTML_STATE_PLAINTEXT;
extern const int LHTML_STATE_SCRIPTDATA;

// gcc :(
#ifdef __clang__
#define LHTML_IMMUTABLE const
#else
#define LHTML_IMMUTABLE
#endif

#define LHTML_BUFFER_T(ITEM_T) struct {\
    ITEM_T *LHTML_IMMUTABLE data;\
    LHTML_IMMUTABLE size_t capacity;\
}

#define LHTML_LIST_T(BUFFER_T) struct {\
    union {\
        BUFFER_T buffer;\
        const LHTML_BUFFER_T(__typeof__(((BUFFER_T *)0)->data[0]));\
    };\
    size_t length;\
}

typedef struct {
    const char *data;
    size_t length;
} lhtml_string_t;

typedef LHTML_BUFFER_T(char) lhtml_buffer_t;

typedef struct {
    bool has_value;
    lhtml_string_t value;
} lhtml_opt_string_t;

typedef enum {
    LHTML_TOKEN_UNKNOWN,
    LHTML_TOKEN_CHARACTER,
    LHTML_TOKEN_COMMENT,
    LHTML_TOKEN_START_TAG,
    LHTML_TOKEN_END_TAG,
    LHTML_TOKEN_DOCTYPE,
    LHTML_TOKEN_EOF,
    LHTML_TOKEN_ERROR
} lhtml_token_type_t;

typedef enum {
    LHTML_TOKEN_CHARACTER_RAW,
    LHTML_TOKEN_CHARACTER_DATA,
    LHTML_TOKEN_CHARACTER_RCDATA,
    LHTML_TOKEN_CHARACTER_CDATA,
    LHTML_TOKEN_CHARACTER_SAFE
} lhtml_token_character_kind_t;

typedef struct {
    lhtml_token_character_kind_t kind;
    lhtml_string_t value;
} lhtml_token_character_t;

typedef struct {
    lhtml_string_t value;
} lhtml_token_comment_t;

typedef struct {
    lhtml_string_t name;
    lhtml_string_t value;

    lhtml_opt_string_t raw;
} lhtml_attribute_t;

typedef LHTML_BUFFER_T(lhtml_attribute_t) lhtml_attr_buffer_t;
typedef LHTML_LIST_T(lhtml_attr_buffer_t) lhtml_attributes_t;

typedef struct {
    lhtml_string_t name;
    lhtml_tag_type_t type;
    lhtml_attributes_t attributes;
    bool self_closing;
} lhtml_token_starttag_t;

typedef struct {
    lhtml_string_t name;
    lhtml_tag_type_t type;
} lhtml_token_endtag_t;

typedef struct {
    lhtml_opt_string_t name;
    lhtml_opt_string_t public_id;
    lhtml_opt_string_t system_id;
    bool force_quirks;
} lhtml_token_doctype_t;

typedef struct {
    lhtml_token_type_t type;
    union {
        lhtml_token_character_t character;
        lhtml_token_comment_t comment;
        lhtml_token_starttag_t start_tag;
        lhtml_token_endtag_t end_tag;
        lhtml_token_doctype_t doctype;
    };
    lhtml_opt_string_t raw;
} lhtml_token_t;

#define LHTML_TOKEN_CALLBACK_T(NAME, T) void (*NAME)(lhtml_token_t *token, T *extra)

typedef __attribute__((nonnull(1))) LHTML_TOKEN_CALLBACK_T(lhtml_token_callback_t, void);

typedef struct lhtml_token_handler_s lhtml_token_handler_t;

struct lhtml_token_handler_s {
    lhtml_token_callback_t callback;
    lhtml_token_handler_t *next;
};

typedef struct {
    lhtml_token_handler_t base_handler; // needs to be the first one

    bool allow_cdata;
    char quote;
    int cs;
    lhtml_tag_type_t last_start_tag_type;
    lhtml_buffer_t buffer;
    lhtml_attr_buffer_t attr_buffer;

    uint64_t special_end_tag_type;
    lhtml_token_handler_t *last_handler;
    lhtml_token_t token;
    lhtml_attribute_t *attribute;
    const char *start_slice;
    const char *mark;
    char *buffer_pos;
} lhtml_state_t;

__attribute__((nonnull))
void lhtml_init(lhtml_state_t *state);

__attribute__((nonnull))
void lhtml_add_handler(lhtml_state_t *state, lhtml_token_handler_t *handler, lhtml_token_callback_t callback);

__attribute__((nonnull))
void lhtml_emit(lhtml_token_t *token, void *extra);

__attribute__((warn_unused_result, nonnull(1)))
bool lhtml_feed(lhtml_state_t *state, const lhtml_string_t *chunk);

__attribute__((pure, warn_unused_result))
bool lhtml_name_equals(const lhtml_string_t actual, const lhtml_string_t expected);

__attribute__((pure, warn_unused_result))
lhtml_tag_type_t lhtml_get_tag_type(const lhtml_string_t name);

__attribute__((nonnull, pure, warn_unused_result))
lhtml_attribute_t *lhtml_find_attr(lhtml_attributes_t *attrs, const lhtml_string_t name);

__attribute__((nonnull, warn_unused_result))
lhtml_attribute_t *lhtml_create_attr(lhtml_attributes_t *attrs);

#define LHTML_STRING(str) ((lhtml_string_t) { .data = str, .length = sizeof(str) - 1 })

#define LHTML_NAME_EQUALS(actual, expected) lhtml_name_equals(actual, LHTML_STRING(expected))

#define LHTML_FIND_ATTR(attrs, name) lhtml_find_attr(attrs, LHTML_STRING(name))

#define LHTML_ADD_HANDLER(tokenizer, state, callback) {\
    _Static_assert(offsetof(__typeof__(*(state)), handler) == 0, ".handler is the first item in the state");\
    LHTML_TOKEN_CALLBACK_T(cb, __typeof__(*(state))) = callback;\
    lhtml_add_handler(tokenizer, &(state)->handler, (lhtml_token_callback_t) cb);\
}

#endif
