#include <stdio.h>
#include <assert.h>
#define ufc (*p + 0x20)

%%{
    machine html;

    access state->;

    include 'syntax.rl';
}%%

typedef struct TokenizerState {
    int cs;
} TokenizerState;

void html_tokenizer_init(TokenizerState *const state) {
    %%write init;
}

int html_tokenizer_feed(TokenizerState *const state, const char *const chunk, const unsigned long length) {
    const char *p = chunk;
    const char *pe = chunk + length;
    const char *eof = length > 0 ? 0 : pe;
    %%write exec;
    if (state->cs == html_error) {
        fprintf(stderr, "Tokenization error at %ld\n", (p - chunk));
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

static const char input[] = "<divine>Hello, world!</div>";

int main() {
    TokenizerState state;
    html_tokenizer_init(&state);
    assert(html_tokenizer_feed(&state, input, sizeof(input) - 1) != html_error);
    assert(html_tokenizer_end(&state) != html_error);
    return state.cs;
}
