#include <assert.h>
#include <string.h>
#include "tokenizer.h"
#include "field-names.h"

%%{
    machine html;

    include 'actions.rl';
    include '../syntax/index.rl';

    access state->;

    write data nofinal noprefix;
}%%

const int LHTML_STATE_ERROR = error;
const int LHTML_STATE_DATA = en_Data;
const int LHTML_STATE_RCDATA = en_RCData;
const int LHTML_STATE_RAWTEXT = en_RawText;
const int LHTML_STATE_PLAINTEXT = en_PlainText;
const int LHTML_STATE_SCRIPTDATA = en_ScriptData;

#define GET_TOKEN(TYPE) (assert(token->type == LHTML_TOKEN_##TYPE), &token->LHTML_FIELD_NAME_##TYPE)

#define CREATE_TOKEN(TYPE) (token->type = LHTML_TOKEN_##TYPE, &token->LHTML_FIELD_NAME_##TYPE)

#define HELPER(...) __attribute__((always_inline, __VA_ARGS__)) inline static

HELPER(nonnull)
void set_string(lhtml_string_t *dest, const char *begin, const char *end) {
    assert(end >= begin);
    dest->length = (size_t) (end - begin);
    dest->data = begin;
}

HELPER(nonnull)
void reset_string(lhtml_string_t *dest) {
    dest->length = 0;
}

HELPER(nonnull)
void set_opt_string(lhtml_opt_string_t *dest, const char *begin, const char *end) {
    dest->has_value = true;
    set_string(&dest->value, begin, end);
}

HELPER(nonnull)
void reset_opt_string(lhtml_opt_string_t *dest) {
    dest->has_value = false;
}

HELPER(nonnull)
void token_init_character(lhtml_token_t *token, lhtml_token_character_kind_t kind) {
    lhtml_token_character_t *character = CREATE_TOKEN(CHARACTER);
    character->kind = kind;
    reset_string(&character->value);
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
    token->type = LHTML_TOKEN_UNKNOWN;
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
    lhtml_token_t *token = &state->token;
    token->raw.value.length = (size_t) (state->buffer_pos - token->raw.value.data);
    if (token->raw.value.length > 0) {
        token->type = LHTML_TOKEN_ERROR;
        token->raw.has_value = true;
        lhtml_emit(token, &state->base_handler);
        token->raw.value.data = state->buffer_pos = state->buffer.data;
    }
    return already_errored(state, unprocessed);
}

HELPER(nonnull)
void end_text(lhtml_state_t *state, const char *p) {
    lhtml_token_t *token = &state->token;
    set_string(&GET_TOKEN(CHARACTER)->value, state->start_slice, state->mark != NULL ? state->mark : p);
}

void lhtml_emit(lhtml_token_t *token, void *extra) {
    lhtml_token_handler_t *handler = ((lhtml_token_handler_t *) extra)->next;
    if (handler != NULL) {
        handler->callback(token, handler);
    }
}

inline bool lhtml_name_equals(const lhtml_string_t actual, const lhtml_string_t expected) {
    size_t length = expected.length;

    if (actual.length != length) {
        return false;
    }

    for (size_t i = 0; i < length; i++) {
        char c = actual.data[i];
        c |= (char) (((unsigned char) c - 'A' < 26) << 5);
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
        if (lhtml_name_equals(attr->name, name)) {
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
        state->cs = LHTML_STATE_DATA;
    }

    state->last_handler = &state->base_handler;
    state->buffer_pos = state->buffer.data;
}

void lhtml_add_handler(lhtml_state_t *state, lhtml_token_handler_t *handler, lhtml_token_callback_t callback) {
    handler->callback = callback;
    handler->next = NULL;
    state->last_handler = state->last_handler->next = handler;
}

bool lhtml_feed(lhtml_state_t *state, const lhtml_string_t *chunk) {
    lhtml_token_t *const token = &state->token;

    if (state->cs == 0) {
        if (chunk != NULL) {
            return already_errored(state, *chunk);
        } else {
            token->type = LHTML_TOKEN_EOF;
            token->raw.value.length = 0;
            token->raw.has_value = true;
            lhtml_emit(token, &state->base_handler);
            return false;
        }
    }

    lhtml_string_t unprocessed;

    if (chunk != NULL) {
        unprocessed = *chunk;
    } else {
        unprocessed.data = NULL;
        unprocessed.length = 0;
    }

    do {
        token->raw.value.data = state->buffer.data;

        size_t available_space = (size_t) (state->buffer.data + state->buffer.capacity - state->buffer_pos);

        if (unprocessed.length <= available_space) {
            available_space = unprocessed.length;
        } else if (available_space == 0) {
            state->cs = 0;
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

        if (state->cs == 0) {
            return emit_error(state, unprocessed);
        }

        if (chunk == NULL) {
            token->type = LHTML_TOKEN_EOF;
            token->raw.value.length = (size_t) (pe - token->raw.value.data);
            token->raw.has_value = true;
            lhtml_emit(token, &state->base_handler);
            state->cs = 0; // treat any further input as error
            return true;
        }

        if (token->type == LHTML_TOKEN_CHARACTER) {
            const char *middle = state->mark != NULL ? state->mark : pe;
            set_string(&token->character.value, state->start_slice, middle);
            token->raw.value.length = (size_t) (middle - token->raw.value.data);
            if (token->raw.value.length) {
                lhtml_token_character_kind_t kind = token->character.kind;
                token->raw.has_value = true;
                lhtml_emit(token, &state->base_handler);
                token->type = LHTML_TOKEN_CHARACTER; // restore just in case
                token->character.kind = kind;
            }
            token->raw.value.data = state->start_slice = middle;
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
            state->start_slice -= shift;

            if (state->mark != NULL) {
                state->mark -= shift;
            }
        }
    } while (unprocessed.length > 0);

    return true;
}
