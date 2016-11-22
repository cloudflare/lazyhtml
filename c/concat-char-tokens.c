#include <assert.h>
#include <string.h>
#include "concat-char-tokens.h"

static void on_token(lhtml_token_t *token, lhtml_concat_state_t *state) {
    if (token->type == LHTML_TOKEN_CHARACTER) {
        if (!state->char_token_buf_pos) {
            state->char_token_buf_pos = state->char_token_buf;
        }
        const lhtml_string_t *value = &token->character.value;
        assert(state->char_token_buf_pos + token->character.value.length < state->char_token_buf_end);
        memcpy(state->char_token_buf_pos, value->data, token->character.value.length);
        state->char_token_buf_pos += token->character.value.length;
        return;
    }
    if (state->char_token_buf_pos) {
        size_t length = (size_t) (state->char_token_buf_pos - state->char_token_buf);
        lhtml_token_t char_token = {
            .type = LHTML_TOKEN_CHARACTER,
            .character = {
                .value = {
                    .data = state->char_token_buf,
                    .length = length
                }
            },
            .raw = {
                .has_value = true,
                .value = {
                    .data = state->char_token_buf,
                    .length = length
                }
            }
        };
        state->char_token_buf_pos = NULL;
        lhtml_emit(&char_token, state);
    }
    lhtml_emit(token, state);
}

void lhtml_concat_inject(lhtml_state_t *tokenizer, lhtml_concat_state_t *state, lhtml_buffer_t buffer) {
    state->char_token_buf = buffer.data;
    state->char_token_buf_end = buffer.data + buffer.length;
    state->char_token_buf_pos = NULL;
    LHTML_ADD_HANDLER(tokenizer, state, on_token);
}
