#ifndef LHTML_SERIALIZER_H
#define LHTML_SERIALIZER_H

#include "tokenizer.h"

typedef struct lhtml_serializer_state_s lhtml_serializer_state_t;

typedef void (*lhtml_string_callback_t)(lhtml_string_t string, lhtml_serializer_state_t *extra);

struct lhtml_serializer_state_s {
    lhtml_token_handler_t handler; // needs to be the first one
    lhtml_string_callback_t writer;
    bool compact;
};

__attribute__((nonnull))
void lhtml_serializer_inject(lhtml_state_t *tokenizer, lhtml_serializer_state_t *state);

#endif
