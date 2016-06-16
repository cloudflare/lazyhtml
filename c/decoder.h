#ifndef LHTML_DECODER_H
#define LHTML_DECODER_H

#include <assert.h>
#include "tokenizer.h"

typedef struct {
    lhtml_token_handler_t handler;
} lhtml_decoder_state_t;

void lhtml_decoder_inject(lhtml_state_t *tokenizer, lhtml_decoder_state_t *state);

#endif
