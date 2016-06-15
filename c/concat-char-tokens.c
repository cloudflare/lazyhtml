#include <assert.h>
#include <string.h>
#include "concat-char-tokens.h"

static void on_token(Token *token, void *extra) {
    ConcatCharTokensState *state = extra;
    if (token->type == token_character) {
        if (!state->char_token_buf_pos) {
            state->char_token_buf_pos = state->char_token_buf;
        }
        const TokenizerString *value = &token->character.value;
        assert((size_t) (state->char_token_buf_pos - state->char_token_buf) + token->character.value.length < sizeof(state->char_token_buf));
        memcpy(state->char_token_buf_pos, value->data, token->character.value.length);
        state->char_token_buf_pos += token->character.value.length;
        return;
    }
    if (state->char_token_buf_pos) {
        size_t length = (size_t) (state->char_token_buf_pos - state->char_token_buf);
        Token char_token = {
            .type = token_character,
            .character = {
                .value = {
                    .data = state->char_token_buf,
                    .length = length
                }
            },
            .raw = {
                .data = state->char_token_buf,
                .length = length
            }
        };
        state->char_token_buf_pos = NULL;
        html_tokenizer_emit(extra, &char_token);
    }
    html_tokenizer_emit(extra, token);
}

void concat_char_tokens_inject(TokenizerState *tokenizer, ConcatCharTokensState *state) {
    state->char_token_buf_pos = NULL;
    html_tokenizer_add_handler(tokenizer, &state->handler, on_token);
}
