#ifndef LHTML_CONCAT_STRINGS_H
#define LHTML_CONCAT_STRINGS_H

#include "tokenizer.h"

typedef struct {
    lhtml_token_handler_t handler; // needs to be the first one
    lhtml_buffer_t buffer;
    char *buffer_pos;
} lhtml_concat_state_t;

__attribute__((nonnull))
void lhtml_concat_inject(lhtml_state_t *tokenizer, lhtml_concat_state_t *state);

#endif
