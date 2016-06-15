#ifndef DECODER_H
#define DECODER_H

#include <assert.h>
#include "tokenizer.h"

typedef struct {
    TokenHandler handler;
} DecoderState;

void decoder_inject(TokenizerState *tokenizer, DecoderState *state);

#endif
