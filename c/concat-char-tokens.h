#ifndef LHTML_CONCAT_STRINGS_H
#define LHTML_CONCAT_STRINGS_H

#include "tokenizer.h"

typedef struct {
    lhtml_token_handler_t handler; // needs to be the first one

    char char_token_buf[1024];
    char *char_token_buf_pos;
} lhtml_concat_state_t;

void lhtml_concat_inject(lhtml_state_t *tokenizer, lhtml_concat_state_t *state);

#endif
