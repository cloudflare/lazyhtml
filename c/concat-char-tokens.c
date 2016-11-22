#include <assert.h>
#include <string.h>
#include "concat-char-tokens.h"

static void on_token(lhtml_token_t *token, lhtml_concat_state_t *state) {
    if (token->type == LHTML_TOKEN_CHARACTER) {
        const lhtml_string_t *value = &token->character.value;
        assert(state->buffer_pos + value->length < state->buffer.data + state->buffer.capacity);
        memcpy(state->buffer_pos, value->data, value->length);
        state->buffer_pos += value->length;
        return;
    }
    size_t length = (size_t) (state->buffer_pos - state->buffer.data);
    if (length > 0) {
        lhtml_string_t value = {
            .data = state->buffer.data,
            .length = length
        };
        lhtml_token_t char_token = {
            .type = LHTML_TOKEN_CHARACTER,
            .character = {
                .value = value
            },
            .raw = {
                .has_value = true,
                .value = value
            }
        };
        state->buffer_pos = state->buffer.data;
        lhtml_emit(&char_token, state);
    }
    lhtml_emit(token, state);
}

void lhtml_concat_inject(lhtml_state_t *tokenizer, lhtml_concat_state_t *state) {
    state->buffer_pos = state->buffer.data;
    LHTML_ADD_HANDLER(tokenizer, state, on_token);
}
