#include <stdio.h>
#include <assert.h>
#include <strings.h>
#define ufc (*p + 0x20)

%%{
    machine html;

    access state->;

    include 'c-actions.rl';
    include 'syntax.rl';

    write data;
}%%

typedef struct TokenizerState {
    int cs;
} TokenizerState;

void html_tokenizer_init(TokenizerState *const state) {
    %%write init;
    state->cs = html_en_RCData;
}

int html_tokenizer_feed(TokenizerState *const state, const char *const chunk, const unsigned long length) {
    const char *p = chunk;
    const char *pe = chunk + length;
    const char *eof = length > 0 ? 0 : pe;
    %%write exec;
    if (state->cs == html_error) {
        fprintf(stderr, "Tokenization error at '%c'\n", *p);
    }
    return state->cs;
}

int html_tokenizer_end(TokenizerState *const state) {
    html_tokenizer_feed(state, "", 0);
    if (state->cs == html_error) {
        fprintf(stderr, "Tokenization error in finalizer");
    }
    return state->cs;
}

const char NULL_CHAR = '\0';

int main(const int argc, const char *const argv[]) {
    assert(argc >= 2);
    TokenizerState state;
    html_tokenizer_init(&state);
    for (const char *input = argv[1]; *input; input++) {
        assert(html_tokenizer_feed(&state, *input == '`' ? &NULL_CHAR : input, 1) != html_error);
    }
    assert(html_tokenizer_end(&state) != html_error);
    return state.cs;
}
