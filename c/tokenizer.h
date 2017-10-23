#ifndef LHTML_TOKENIZER_H
#define LHTML_TOKENIZER_H

#include <stddef.h>
#include <stdbool.h>
#include <inttypes.h>
#include "tag-types.h"

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
        LHTML_IMMUTABLE LHTML_BUFFER_T(__typeof__(((BUFFER_T *)0)->data[0]));\
    };\
    size_t length;\
}

typedef struct {
    const char *data;
    size_t length;
} lhtml_string_t;

typedef LHTML_BUFFER_T(char) lhtml_char_buffer_t;

typedef struct {
    bool has_value;
    lhtml_string_t value;
} lhtml_opt_string_t;

typedef enum {
    LHTML_TOKEN_ERROR,
    LHTML_TOKEN_UNPARSED,
    LHTML_TOKEN_CHARACTER,
    LHTML_TOKEN_COMMENT,
    LHTML_TOKEN_START_TAG,
    LHTML_TOKEN_END_TAG,
    LHTML_TOKEN_DOCTYPE,
    LHTML_TOKEN_EOF,
    LHTML_TOKEN_CDATA_START,
    LHTML_TOKEN_CDATA_END
} lhtml_token_type_t;

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

/// <div rustbindgen nocopy></div>
typedef struct {
    lhtml_token_handler_t base_handler; // needs to be the first one

    bool allow_cdata;
    bool unsafe_null;
    bool entities;
    char quote;
    int cs;
    lhtml_tag_type_t last_start_tag_type;
    lhtml_char_buffer_t buffer;
    lhtml_attr_buffer_t attr_buffer;

    uint64_t special_end_tag_type;
    lhtml_token_t token;
    const char *slice_start;
    const char *mark;
    char *buffer_pos;
} lhtml_state_t;

__attribute__((nonnull))
void lhtml_init(lhtml_state_t *state);

__attribute__((nonnull))
void lhtml_append_handlers(lhtml_token_handler_t *dest, lhtml_token_handler_t *src);

__attribute__((nonnull))
void lhtml_emit(lhtml_token_t *token, void *extra);

__attribute__((warn_unused_result, nonnull(1)))
bool lhtml_feed(lhtml_state_t *state, const lhtml_string_t *chunk);

__attribute__((pure, warn_unused_result))
bool lhtml_str_nocase_equals(const lhtml_string_t actual, const lhtml_string_t expected);

__attribute__((pure, warn_unused_result))
lhtml_tag_type_t lhtml_get_tag_type(const lhtml_string_t name);

__attribute__((nonnull, pure, warn_unused_result))
lhtml_attribute_t *lhtml_find_attr(lhtml_attributes_t *attrs, const lhtml_string_t name);

__attribute__((nonnull, warn_unused_result))
lhtml_attribute_t *lhtml_create_attr(lhtml_attributes_t *attrs);

#define LHTML_STRING(str) ((lhtml_string_t) { .data = str, .length = sizeof(str) - 1 })

#define LHTML_STR_EQUALS(actual, expected) ({\
    lhtml_string_t _actual = (actual);\
    lhtml_string_t _expected = LHTML_STRING(expected);\
    _actual.length == _expected.length && memcmp(_actual.data, _expected.data, _expected.length) == 0;\
})

#define LHTML_STR_NOCASE_EQUALS(actual, expected) lhtml_str_nocase_equals(actual, LHTML_STRING(expected))

#define LHTML_FIND_ATTR(attrs, name) lhtml_find_attr(attrs, LHTML_STRING(name))

#define LHTML_INIT_HANDLER(state, cb) {\
    _Static_assert(offsetof(__typeof__(*(state)), handler) == 0, ".handler is the first item in the state");\
    LHTML_TOKEN_CALLBACK_T(_cb, __typeof__(*(state))) = (cb);\
    (state)->handler = (lhtml_token_handler_t) { .callback = (lhtml_token_callback_t) _cb };\
}

#define LHTML_ADD_HANDLER(tokenizer, state, cb) {\
    __typeof__((state)) _state = (state);\
    LHTML_INIT_HANDLER(_state, (cb));\
    lhtml_append_handlers(&(tokenizer)->base_handler, &_state->handler);\
}

#endif
