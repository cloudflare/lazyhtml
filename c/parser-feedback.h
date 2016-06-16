#ifndef LHTML_FEEDBACK_H
#define LHTML_FEEDBACK_H

#include "tokenizer.h"

typedef enum {
    LHTML_NS_HTML = LHTML_TAG_HTML,
    LHTML_NS_MATHML = LHTML_TAG_MATH,
    LHTML_NS_SVG = LHTML_TAG_SVG
} lhtml_ns_t;

#define MAX_NS_DEPTH 20

typedef struct {
    lhtml_token_handler_t handler; // needs to be the first one

    lhtml_state_t *tokenizer;
    size_t ns_depth;
    lhtml_ns_t ns_stack[MAX_NS_DEPTH];
    bool skip_next_newline;
} lhtml_feedback_state_t;

void lhtml_feedback_inject(lhtml_state_t *tokenizer, lhtml_feedback_state_t *state);

#endif
