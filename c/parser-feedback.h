#ifndef LHTML_FEEDBACK_H
#define LHTML_FEEDBACK_H

#include "tokenizer.h"

typedef enum {
    LHTML_NS_HTML = LHTML_TAG_HTML,
    LHTML_NS_MATHML = LHTML_TAG_MATH,
    LHTML_NS_SVG = LHTML_TAG_SVG
} lhtml_ns_t;

typedef LHTML_BUFFER_T(lhtml_ns_t) lhtml_ns_buffer_t;
typedef LHTML_LIST_T(lhtml_ns_buffer_t) lhtml_ns_stack_t;

typedef struct {
    lhtml_token_handler_t handler; // needs to be the first one

    lhtml_state_t *tokenizer;
    lhtml_ns_stack_t ns_stack;
    bool skip_next_newline;
} lhtml_feedback_state_t;

__attribute__((nonnull))
void lhtml_feedback_inject(lhtml_state_t *tokenizer, lhtml_feedback_state_t *state, lhtml_ns_buffer_t ns_buffer);

__attribute__((nonnull, pure, warn_unused_result))
lhtml_ns_t lhtml_get_current_ns(const lhtml_feedback_state_t *state);

#endif
