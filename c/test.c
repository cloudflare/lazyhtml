#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "tests.pb-c.h"
#include "tokenizer.h"

static TokenizerString to_tok_string(const ProtobufCBinaryData *data) {
    TokenizerString str = {
        .length = data->len,
        .data = (char *) data->data
    };
    return str;
}

static int to_tok_state(const Suite__Test__State state) {
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
    const char *error;
    const char *raw_pos;
    unsigned int expected_pos;
    const unsigned int expected_length;
    Suite__Test__Token **const expected;
} State;

static bool bool_equals(bool actual, protobuf_c_boolean expected) {
    return !actual == !expected;
}

static bool string_equals(const TokenizerString *actual, const ProtobufCBinaryData *expected) {
    return actual->length == expected->len && memcmp(actual->data, expected->data, actual->length) == 0;
}

static bool opt_string_equals(const TokenizerOptionalString *actual, const Suite__Test__OptionalString *expected) {
    if (!bool_equals(actual->has_value, expected->has_value)) {
        return false;
    }
    if (actual->has_value) {
        return string_equals(&actual->value, &expected->value);
    } else {
        return true;
    }
}

static bool attribute_equals(const Attribute *actual, const Suite__Test__Attribute *expected) {
    return string_equals(&actual->name, &expected->name) && string_equals(&actual->value, &expected->value);
}

static bool token_equals(const Token *token, const Suite__Test__Token *test) {
    const Suite__Test__Token__TokenCase test_type = test->token_case;
    switch (token->type) {
        case token_doc_type: {
            if (test_type != SUITE__TEST__TOKEN__TOKEN_DOC_TYPE) {
                return false;
            }
            const TokenDocType *actual = &token->doc_type;
            const Suite__Test__DOCTYPE *expected = test->doc_type;
            return (
                opt_string_equals(&actual->name, expected->name) &&
                opt_string_equals(&actual->public_id, expected->public_id) &&
                opt_string_equals(&actual->system_id, expected->system_id) &&
                bool_equals(actual->force_quirks, expected->force_quirks)
            );
            break;
        }
        case token_start_tag: {
            if (test_type != SUITE__TEST__TOKEN__TOKEN_START_TAG) {
                return false;
            }
            const TokenStartTag *actual = &token->start_tag;
            const Suite__Test__StartTag *expected = test->start_tag;
            if (!(
                string_equals(&actual->name, &expected->name) &&
                actual->attributes.count == expected->n_attributes &&
                bool_equals(actual->self_closing, expected->self_closing)
            )) {
                return false;
            }
            const unsigned int n = actual->attributes.count;
            for (int i = 0; i < n; i++) {
                if (!attribute_equals(&actual->attributes.items[i], expected->attributes[i])) {
                    return false;
                }
            }
            break;
        }
        case token_end_tag: {
            if (test_type != SUITE__TEST__TOKEN__TOKEN_END_TAG) {
                return false;
            }
            const TokenEndTag *actual = &token->end_tag;
            const Suite__Test__EndTag *expected = test->end_tag;
            return (
                string_equals(&actual->name, &expected->name)
            );
            break;
        }
        case token_comment: {
            if (test_type != SUITE__TEST__TOKEN__TOKEN_COMMENT) {
                return false;
            }
            const TokenComment *actual = &token->comment;
            const Suite__Test__Comment *expected = test->comment;
            return (
                string_equals(&actual->value, &expected->value)
            );
            break;
        }
        case token_character: {
            if (test_type != SUITE__TEST__TOKEN__TOKEN_CHARACTER) {
                return false;
            }
            const TokenCharacter *actual = &token->character;
            const Suite__Test__Character *expected = test->character;
            return (
                string_equals(&actual->value, &expected->value)
            );
            break;
        }
        default: {
            assert(false);
        }
    }
    return true;
}

static void on_token(const Token *token) {
    State *state = (State *) token->extra;
    if (state->error) {
        return;
    }
    if (token->raw.data != state->raw_pos) {
        state->error = "Raw position mismatch";
        return;
    }
    state->raw_pos = token->raw.data + token->raw.length;
    if (state->expected_pos >= state->expected_length) {
        state->error = "Extraneous tokens";
        return;
    }
    Suite__Test__Token *expected = state->expected[state->expected_pos++];
    if (!token_equals(token, expected)) {
        state->error = "Token mismatch";
        return;
    }
}

static void run_test(const Suite__Test *test) {
    State custom_state = {
        .expected_length = test->n_output,
        .expected = test->output
    };
    TokenizerOpts options = {
        .on_token = on_token,
        .last_start_tag_name = to_tok_string(&test->last_start_tag),
        .extra = &custom_state
    };
    TokenizerState state;
    TokenizerString input = to_tok_string(&test->input);
    for (int i = 0; i < test->n_initial_states; i++) {
        options.initial_state = to_tok_state(test->initial_states[i]);
        html_tokenizer_init(&state, &options);
        custom_state.error = 0;
        custom_state.raw_pos = input.data;
        custom_state.expected_pos = 0;
        html_tokenizer_feed(&state, &input);
        // html_tokenizer_feed(&state, NULL);
        if (!custom_state.error && state.cs == html_state_error) {
            custom_state.error = "Tokenization error";
        }
        if (!custom_state.error && custom_state.expected_pos < custom_state.expected_length) {
            custom_state.error = "Not enough tokens";
        }
        if (custom_state.error) {
            printf(
                "not ok - %.*s\n"
                "  ---\n"
                "  message: '%s'\n"
                "  severity: fail\n"
                "  "
                "  ...\n",
                (int ) test->description.len,
                (char *) test->description.data,
                custom_state.error
            );
        }
    }
    printf(
        "ok - %.*s\n",
        (int ) test->description.len,
        (char *) test->description.data
    );
}

static void run_suite(const Suite *suite) {
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