#include <assert.h>
#include <string.h>
#include "tokenizer.h"
#include "field-names.h"

%%{
    machine html;

    include 'actions.rl';
    include '../syntax/index.rl';

    access state->;
}%%

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wunused-variable"
%%write data nofinal noprefix;
#pragma GCC diagnostic pop

#define GET_TOKEN(TYPE) (assert(token->type == LHTML_TOKEN_##TYPE), &token->LHTML_FIELD_NAME_##TYPE)

#define CREATE_TOKEN(TYPE, VALUE) {\
    token->type = LHTML_TOKEN_##TYPE;\
    token->LHTML_FIELD_NAME_##TYPE = (__typeof__(token->LHTML_FIELD_NAME_##TYPE)) VALUE;\
}

#define HELPER(...) __attribute__((always_inline, __VA_ARGS__)) inline static

HELPER(nonnull)
lhtml_string_t range_string(const char *begin, const char *end) {
    assert(end >= begin);
    return (lhtml_string_t) {
        .data = begin,
        .length = (size_t) (end - begin)
    };
}

HELPER(nonnull)
lhtml_opt_string_t opt_range_string(const char *begin, const char *end) {
    return (lhtml_opt_string_t) {
        .has_value = true,
        .value = range_string(begin, end)
    };
}

HELPER(const, warn_unused_result)
uint64_t tag_type_append_char(uint64_t *code, char c) {
    // protect against overflow
    if (*code >> (64 - 5)) {
        return *code = 0;
    }

    if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')) {
        return *code = (*code << 5) | (c & 31);
    } else {
        return *code = 0;
    }
}

__attribute__((always_inline))
inline lhtml_tag_type_t lhtml_get_tag_type(const lhtml_string_t name) {
    uint64_t code = 0;

    for (size_t i = 0; i < name.length; i++) {
        if (!tag_type_append_char(&code, name.data[i])) {
            break;
        }
    }

    return code;
}

HELPER(nonnull)
void emit_token(lhtml_state_t *state, const char *end) {
    lhtml_token_t *token = &state->token;
    token->raw.value.length = (size_t) (end - token->raw.value.data);
    if (token->raw.value.length) {
        token->raw.has_value = true;
        lhtml_emit(token, &state->base_handler);
    }
    token->type = LHTML_TOKEN_ERROR;
    token->raw.value.data = end;
    token->raw.value.length = 0;
}

HELPER(nonnull)
bool already_errored(lhtml_state_t *state, lhtml_string_t unprocessed) {
    if (unprocessed.length > 0) {
        lhtml_token_t *token = &state->token;
        token->type = LHTML_TOKEN_ERROR;
        token->raw.value = unprocessed;
        token->raw.has_value = true;
        lhtml_emit(token, &state->base_handler);
    }
    return false;
}

HELPER(nonnull)
bool emit_error(lhtml_state_t *state, lhtml_string_t unprocessed) {
    state->token.type = LHTML_TOKEN_ERROR;
    emit_token(state, state->buffer_pos);
    return already_errored(state, unprocessed);
}

HELPER(nonnull)
void emit_slice(lhtml_state_t *state, const char *p) {
    lhtml_token_t *token = &state->token;
    const char *slice_end = state->mark != NULL ? state->mark : p;
    GET_TOKEN(CHARACTER)->value = range_string(state->slice_start, slice_end);
    emit_token(state, slice_end);
}

HELPER(nonnull)
void emit_eof(lhtml_state_t *state) {
    lhtml_token_t *token = &state->token;
    token->type = LHTML_TOKEN_EOF;
    token->raw.has_value = true;
    lhtml_emit(token, &state->base_handler);
}

void lhtml_emit(lhtml_token_t *token, void *extra) {
    lhtml_token_handler_t *handler = ((lhtml_token_handler_t *) extra)->next;
    if (handler != NULL) {
        handler->callback(token, handler);
    }
}

inline bool lhtml_str_nocase_equals(const lhtml_string_t actual, const lhtml_string_t expected) {
    size_t length = expected.length;

    if (actual.length != length) {
        return false;
    }

    for (size_t i = 0; i < length; i++) {
        char c = actual.data[i];
        c |= ((unsigned char) (c - 'A') < 26) << 5; // tolower that vectorizes
        char e = expected.data[i];

        if (c != e) {
            return false;
        }
    }

    return true;
}

inline lhtml_attribute_t *lhtml_find_attr(lhtml_attributes_t *attrs, const lhtml_string_t name) {
    size_t count = attrs->length;
    lhtml_attribute_t *items = attrs->data;
    for (size_t i = 0; i < count; i++) {
        lhtml_attribute_t *attr = &items[i];
        if (lhtml_str_nocase_equals(attr->name, name)) {
            return attr;
        }
    }
    return NULL;
}

HELPER(nonnull)
bool can_create_attr(lhtml_attributes_t *attrs) {
    return attrs->length < attrs->capacity;
}

inline lhtml_attribute_t *lhtml_create_attr(lhtml_attributes_t *attrs) {
    return can_create_attr(attrs) ? &attrs->data[attrs->length++] : NULL;
}

void lhtml_init(lhtml_state_t *state) {
    %%write init nocs;

    if (state->cs == 0) {
        state->cs = en_Data;
    }

    state->buffer_pos = state->buffer.data;
}

void lhtml_append_handlers(lhtml_token_handler_t *dest, lhtml_token_handler_t *src) {
    while (dest->next != NULL) {
        dest = dest->next;
    }
    dest->next = src;
}

bool lhtml_feed(lhtml_state_t *state, const lhtml_string_t *chunk) {
    lhtml_token_t *const token = &state->token;

    if (token->type == LHTML_TOKEN_EOF) {
        // if already saw an EOF, ignore any further input
        return false;
    }

    if (state->cs == error) {
        if (chunk != NULL) {
            return already_errored(state, *chunk);
        } else {
            token->raw.value.length = 0;
            emit_eof(state);
            return false;
        }
    }

    lhtml_string_t unprocessed = chunk != NULL ? *chunk : LHTML_STRING("");

    do {
        token->raw.value.data = state->buffer.data;

        size_t available_space = (size_t) (state->buffer.data + state->buffer.capacity - state->buffer_pos);

        if (unprocessed.length <= available_space) {
            available_space = unprocessed.length;
        } else if (available_space == 0) {
            state->cs = error;
            return emit_error(state, unprocessed);
        }

        const char *p = state->buffer_pos;

        if (available_space > 0) {
            memcpy(state->buffer_pos, unprocessed.data, available_space);
            state->buffer_pos += available_space;
            unprocessed.data += available_space;
            unprocessed.length -= available_space;
        }

        const char *const pe = state->buffer_pos;
        const char *const eof = chunk == NULL ? pe : NULL;

        %%write exec;

        if (state->cs == error) {
            return emit_error(state, unprocessed);
        }

        if (chunk == NULL) {
            token->raw.value.length = (size_t) (pe - token->raw.value.data);
            emit_eof(state);
            return true;
        }

        if (token->type == LHTML_TOKEN_CHARACTER) {
            emit_slice(state, pe);
            CREATE_TOKEN(CHARACTER, {});
            state->slice_start = token->raw.value.data;
        }

        size_t shift = (size_t) (token->raw.value.data - state->buffer.data);

        if (shift != 0) {
            switch (token->type) {
                case LHTML_TOKEN_COMMENT: {
                    token->comment.value.data -= shift;
                    break;
                }

                case LHTML_TOKEN_DOCTYPE: {
                    token->doctype.name.value.data -= shift;
                    token->doctype.public_id.value.data -= shift;
                    token->doctype.system_id.value.data -= shift;
                    break;
                }

                case LHTML_TOKEN_END_TAG: {
                    token->end_tag.name.data -= shift;
                    break;
                }

                case LHTML_TOKEN_START_TAG: {
                    token->start_tag.name.data -= shift;
                    lhtml_attributes_t *attrs = &token->start_tag.attributes;
                    for (size_t i = 0; i < attrs->length; i++) {
                        lhtml_attribute_t *attr = &attrs->data[i];
                        attr->name.data -= shift;
                        attr->value.data -= shift;
                        attr->raw.value.data -= shift;
                    }
                    break;
                }

                default: {
                    break;
                }
            }

            memmove(state->buffer.data, token->raw.value.data, (size_t) (state->buffer_pos - token->raw.value.data));
            state->buffer_pos -= shift;
            state->slice_start -= shift;

            if (state->mark != NULL) {
                state->mark -= shift;
            }
        }
    } while (unprocessed.length > 0);

    return true;
}
