#include <assert.h>
#include <strings.h>
#include <stdint.h>
#include "tokenizer.h"
#include "field-names.h"

%%{
    machine html;

    include 'c/actions.rl';
    include 'syntax/index.rl';

    access state->;

    write data nofinal noprefix;
}%%

const int LHTML_STATE_ERROR = error;
const int LHTML_STATE_DATA = en_Data;
const int LHTML_STATE_RCDATA = en_RCData;
const int LHTML_STATE_RAWTEXT = en_RawText;
const int LHTML_STATE_PLAINTEXT = en_PlainText;
const int LHTML_STATE_SCRIPTDATA = en_ScriptData;

#define GET_TOKEN(TYPE) (assert(state->token.type == LHTML_TOKEN_##TYPE), &state->token.LHTML_FIELD_NAME_##TYPE)

#define CREATE_TOKEN(TYPE) (state->token.type = LHTML_TOKEN_##TYPE, &state->token.LHTML_FIELD_NAME_##TYPE)

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
void token_init_character(lhtml_state_t *state, lhtml_token_character_kind_t kind) {
    lhtml_token_character_t *character = CREATE_TOKEN(CHARACTER);
    character->kind = kind;
    reset_string(&character->value);
}

HELPER(nonnull)
void set_last_start_tag_name(lhtml_state_t *state, const lhtml_string_t name) {
    size_t len = name.length;
    if (len > sizeof(state->last_start_tag_name_buf)) {
        len = sizeof(state->last_start_tag_name_buf);
    }
    memcpy(state->last_start_tag_name_buf, name.data, len);
    state->last_start_tag_name_end = state->last_start_tag_name_buf + len;
}

HELPER(const, warn_unused_result)
lhtml_tag_type_t get_tag_type(const lhtml_string_t name) {
    uint64_t code = 0;

    const char *data = name.data;
    const char *const max = data + name.length;

    for (; data < max; data++) {
        char c = *data;

        // protect against overflow
        if (code >> (64 - 5)) {
            return 0;
        }

        if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')) {
            code = (code << 5) | (c & 31);
        } else {
            return 0;
        }
    }

    return code;
}

void lhtml_emit(lhtml_token_t *token, void *extra) {
    lhtml_token_handler_t *handler = ((lhtml_token_handler_t *) extra)->next;
    if (handler == NULL) {
        return;
    }
    handler->callback(token, handler);
}

bool lhtml_name_equals(const lhtml_string_t actual, const char *expected) {
    size_t len = actual.length;
    const char *data = actual.data;

    for (size_t i = 0; i < len; i++) {
        char c = data[i];
        c |= ((unsigned char) c - 'A' < 26U) << 5;
        char e = expected[i];

        if (e == 0 || c != e) {
            return false;
        }
    }

    return expected[len] == 0;
}

void lhtml_init(lhtml_state_t *state, const lhtml_options_t *options) {
    %%write init nocs;
    state->allow_cdata = options->allow_cdata;
    state->base_handler.next = NULL;
    state->last_handler = &state->base_handler;
    set_last_start_tag_name(state, options->last_start_tag_name);
    state->quote = 0;
    state->attribute = 0;
    state->start_slice = 0;
    state->mark = 0;
    state->appropriate_end_tag_offset = 0;
    state->buffer = state->buffer_pos = options->buffer;
    state->buffer_end = options->buffer + options->buffer_size;
    state->token.type = LHTML_TOKEN_UNKNOWN;
    state->token.raw.data = state->buffer;
    state->cs = options->initial_state;
}

void lhtml_add_handler(lhtml_state_t *state, lhtml_token_handler_t *handler, lhtml_token_callback_t callback) {
    handler->callback = callback;
    handler->next = NULL;
    state->last_handler = state->last_handler->next = handler;
}

int lhtml_feed(lhtml_state_t *state, const lhtml_string_t *chunk) {
    const char *p = state->buffer_pos;

    if (chunk != NULL) {
        char *new_buffer_pos = state->buffer_pos + chunk->length;
        assert(new_buffer_pos <= state->buffer_end);
        memcpy(state->buffer_pos, chunk->data, chunk->length);
        state->buffer_pos = new_buffer_pos;
    }

    const char *const pe = state->buffer_pos;
    const char *const eof = chunk == NULL ? pe : 0;

    %%write exec;

    if (state->cs == 0) {
        return 0;
    }

    lhtml_token_t *const token = &state->token;

    if (p == eof) {
        token->type = LHTML_TOKEN_EOF;
        token->raw.length = (size_t) (pe - token->raw.data);
        lhtml_emit(token, &state->base_handler);
        return state->cs;
    }

    if (token->type == LHTML_TOKEN_CHARACTER) {
        const char *middle = state->mark != NULL ? state->mark : pe;
        set_string(&token->character.value, state->start_slice, middle);
        token->raw.length = (size_t) (middle - token->raw.data);
        if (token->raw.length) {
            lhtml_emit(token, &state->base_handler);
            token->type = LHTML_TOKEN_CHARACTER; // restore just in case
        }
        token->raw.data = state->start_slice = middle;
    }

    size_t shift = (size_t) (token->raw.data - state->buffer);

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
            for (size_t i = 0; i < attrs->count; i++) {
                lhtml_attribute_t *attr = &attrs->items[i];
                attr->name.data -= shift;
                attr->value.data -= shift;
            }
            break;
        }

        default: {
            break;
        }
    }

    memmove(state->buffer, token->raw.data, pe - token->raw.data);
    token->raw.data = state->buffer;
    state->buffer_pos -= shift;
    state->start_slice -= shift;

    if (state->mark != NULL) {
        state->mark -= shift;
    }

    return state->cs;
}
