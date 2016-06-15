#ifndef PARSER_FEEDBACK_H
#define PARSER_FEEDBACK_H

#include "tokenizer.h"

typedef enum {
    NS_HTML = HTML_TAG_HTML,
    NS_MATHML = HTML_TAG_MATH,
    NS_SVG = HTML_TAG_SVG
} Namespace;

#define MAX_NS_DEPTH 20

typedef struct {
    TokenHandler handler; // needs to be the first one

    TokenizerState *tokenizer;
    size_t ns_depth;
    Namespace ns_stack[MAX_NS_DEPTH];
    bool skip_next_newline;
} ParserFeedbackState;

void parser_feedback_inject(TokenizerState *tokenizer, ParserFeedbackState *state);

#endif
