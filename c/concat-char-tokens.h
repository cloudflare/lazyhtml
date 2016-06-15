#ifndef CONCAT_CHAR_TOKENS_H
#define CONCAT_CHAR_TOKENS_H

#include "tokenizer.h"

typedef struct {
    TokenHandler handler; // needs to be the first one

    char char_token_buf[1024];
    char *char_token_buf_pos;
} ConcatCharTokensState;

void concat_char_tokens_inject(TokenizerState *tokenizer, ConcatCharTokensState *state);

#endif
