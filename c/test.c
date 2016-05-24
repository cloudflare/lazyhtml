#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include "tests.pb-c.h"
#include "tokenizer.h"

TokenizerString to_tok_string(const ProtobufCBinaryData *data) {
    TokenizerString str = {
        .length = data->len,
        .data = (char *) data->data
    };
    return str;
}

int to_tok_state(const Suite__Test__State state) {
    #define state_case(NAME) \
        case SUITE__TEST__STATE__##NAME:\
            return html_state_##NAME;

    switch (state) {
        state_case(Data)
        state_case(PlainText)
        state_case(RCData)
        state_case(RawText)
        state_case(ScriptData)

        default: assert(false);
    }
}

typedef struct {
    unsigned int count;
    Token items[100];
} CollectedTokens;

void on_token(const Token *token) {
    CollectedTokens *tokens = (CollectedTokens *) token->extra;
}

void run_test(const Suite__Test *test) {
    CollectedTokens tokens;
    TokenizerOpts options = {
        .on_token = on_token,
        .last_start_tag_name = to_tok_string(&test->last_start_tag),
        .extra = &tokens
    };
    TokenizerState state;
    TokenizerString input = to_tok_string(&test->input);
    for (int i = 0; i < test->n_initial_states; i++) {
        tokens.count = 0;
        options.initial_state = to_tok_state(test->initial_states[i]);
        html_tokenizer_init(&state, &options);
        html_tokenizer_feed(&state, &input);
        // html_tokenizer_feed(&state, NULL);
        if (state.cs == html_state_error) {
            printf(
                "not ok - %.*s\n"
                "  ---\n"
                "  message: 'Failed in state %u'\n"
                "  severity: fail\n"
                "  ...\n",
                (int ) test->description.len,
                (char *) test->description.data,
                i
            );
        }
    }
    printf(
        "ok - %.*s\n",
        (int ) test->description.len,
        (char *) test->description.data
    );
}

void run_suite(const Suite *suite) {
    const int n = suite->n_tests;
    printf(
        "TAP version 13\n"
        "1..%u\n",
        n
    );
    for (int i = 0; i < n; i++) {
        run_test(suite->tests[i]);
    }
}

int main() {
    FILE *infile = fopen("../tests.dat", "rb");

    assert(infile);

    fseek(infile, 0L, SEEK_END);
    unsigned int numbytes = ftell(infile);

    uint8_t *buffer = malloc(numbytes);

    assert(buffer);

    fseek(infile, 0L, SEEK_SET);

    assert(fread(buffer, sizeof(char), numbytes, infile) == numbytes);
    fclose(infile);

    Suite *suite = suite__unpack(NULL, numbytes, buffer);

    assert(suite);

    run_suite(suite);

    suite__free_unpacked(suite, NULL);

    free(buffer);
    return 0;
}