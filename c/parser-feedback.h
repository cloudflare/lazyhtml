#ifndef PARSER_FEEDBACK_H
#define PARSER_FEEDBACK_H

#include <assert.h>
#include "tokenizer.h"

typedef enum {
    NS_HTML = HTML_TAG_HTML,
    NS_MATHML = HTML_TAG_MATH,
    NS_SVG = HTML_TAG_SVG
} Namespace;

#define MAX_NS_DEPTH 20

typedef struct {
    TokenizerState *tokenizer;
    void *wrapped_extra;
    TokenHandler wrapped_handler;
    size_t ns_depth;
    Namespace ns_stack[MAX_NS_DEPTH];
    bool skip_next_newline;
} ParserFeedbackState;

void parser_feedback_inject(ParserFeedbackState *state, TokenizerState *tokenizer);

#endif
