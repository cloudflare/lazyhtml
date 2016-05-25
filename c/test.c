#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "tests.pb-c.h"
#include "tokenizer.h"

static TokenizerString to_tok_string(const ProtobufCBinaryData data) {
    TokenizerString str = {
        .length = data.len,
        .data = (char *) data.data
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

static ProtobufCBinaryData to_test_string(const TokenizerString src) {
    ProtobufCBinaryData dest;
    dest.data = (unsigned char *) src.data;
    dest.len = src.length;
    return dest;
}

static Suite__Test__OptionalString to_opt_test_string(const TokenizerOptionalString src) {
    Suite__Test__OptionalString dest = SUITE__TEST__OPTIONAL_STRING__INIT;
    if ((dest.has_value = src.has_value)) {
        dest.value = to_test_string(src.value);
    }
    return dest;
}

static void fprint_msg(FILE *file, const ProtobufCMessage *msg) {
    const ProtobufCMessageDescriptor *desc = msg->descriptor;
    fprintf(file, "%s { ", desc->short_name);
    const unsigned int n_fields = desc->n_fields;
    const ProtobufCFieldDescriptor* fields = desc->fields;
    const char *mem = (const char *) msg;
    for (int i = 0; i < n_fields; i++) {
        if (i > 0) {
            fprintf(file, ", ");
        }
        const ProtobufCFieldDescriptor* field = &fields[i];
        if (field->flags & PROTOBUF_C_FIELD_FLAG_ONEOF) {
            unsigned int quantifier = *((unsigned int *) (mem + field->quantifier_offset));
            i += quantifier - 1;
            assert(i >= 0 && i < n_fields);
            field = &fields[i];
            for (; i < n_fields && fields[i].quantifier_offset == field->quantifier_offset; i++);
            i--;
        }
        if (n_fields > 1) {
            fprintf(file, "%s = ", field->name);
        }
        if (field->label == PROTOBUF_C_LABEL_OPTIONAL && !*((bool *) (mem + field->quantifier_offset))) {
            fprintf(file, "(none)");
            continue;
        }
        const void *value = mem + field->offset;
        unsigned int n_values = 1;
        if (field->label == PROTOBUF_C_LABEL_REPEATED) {
            n_values = *((unsigned int *) (mem + field->quantifier_offset));
            value = *((void **) value);
            fprintf(file, "[ ");
        }
        for (int j = 0; j < n_values; j++) {
            if (j > 0) {
                fprintf(file, ", ");
            }
            switch (field->type) {
                case PROTOBUF_C_TYPE_BOOL: {
                    const bool *rec = value;
                    fprintf(file, "%s", *rec ? "true" : "false");
                    value = rec + 1;
                    break;
                }

                case PROTOBUF_C_TYPE_BYTES: {
                    const ProtobufCBinaryData *rec = value;
                    fprintf(file, "'");
                    const size_t len = rec->len;
                    const char *data = (const char *) rec->data;
                    for (int i = 0; i < len; i++) {
                        const char c = data[i];
                        if (iscntrl(c)) {
                            fprintf(file, "\\x%02X", c);
                        } else if (c == '\'') {
                            fprintf(file, "\\\'");
                        } else {
                            fprintf(file, "%c", c);
                        }
                    }
                    fprintf(file, "'");
                    value = rec + 1;
                    break;
                }

                case PROTOBUF_C_TYPE_ENUM: {
                    const unsigned int *rec = value;
                    const ProtobufCEnumDescriptor *desc = field->descriptor;
                    fprintf(file, "%s", protobuf_c_enum_descriptor_get_value(desc, *rec)->name);
                    value = rec + 1;
                    break;
                }

                case PROTOBUF_C_TYPE_MESSAGE: {
                    ProtobufCMessage *const *rec = value;
                    fprint_msg(file, *rec);
                    value = rec + 1;
                    break;
                }

                default:
                    assert(false);
            }
        }
        if (field->label == PROTOBUF_C_LABEL_REPEATED) {
            fprintf(file, " ]");
        }
    }
    fprintf(file, " }");
}

static bool tokens_match(const Token *src, const Suite__Test__Token *expected) {
    Suite__Test__Token actual = SUITE__TEST__TOKEN__INIT;

    #define case_token(TYPE, NAME, CAP_TYPE) case token_##NAME:;\
        Suite__Test__##TYPE NAME = SUITE__TEST__##CAP_TYPE##__INIT;\
        actual.token_case = SUITE__TEST__TOKEN__TOKEN_##CAP_TYPE;\
        actual.NAME = &NAME;

    Suite__Test__OptionalString name, public_id, system_id;

    const unsigned int n_attributes = src->type == token_start_tag ? src->start_tag.attributes.count : 0;
    Suite__Test__Attribute attributes[n_attributes];
    Suite__Test__Attribute *attribute_pointers[n_attributes];

    switch (src->type) {
        default:
            assert(false);

        case_token(Character, character, CHARACTER)
            character.value = to_test_string(src->character.value);
            break;

        case_token(DocType, doc_type, DOC_TYPE)
            name = to_opt_test_string(src->doc_type.name);
            public_id = to_opt_test_string(src->doc_type.public_id);
            system_id = to_opt_test_string(src->doc_type.system_id);
            doc_type.name = &name;
            doc_type.public_id = &public_id;
            doc_type.system_id = &system_id;
            doc_type.force_quirks = src->doc_type.force_quirks;
            break;

        case_token(Comment, comment, COMMENT)
            comment.value = to_test_string(src->comment.value);
            break;

        case_token(EndTag, end_tag, END_TAG)
            end_tag.name = to_test_string(src->end_tag.name);
            break;

        case_token(StartTag, start_tag, START_TAG)
            start_tag.name = to_test_string(src->start_tag.name);
            start_tag.n_attributes = n_attributes;
            for (int i = 0; i < n_attributes; i++) {
                Suite__Test__Attribute *attr = attribute_pointers[i] = &attributes[i];
                suite__test__attribute__init(attr);
                const Attribute *src_attr = &src->start_tag.attributes.items[i];
                attr->name = to_test_string(src_attr->name);
                attr->value = to_test_string(src_attr->value);
            }
            start_tag.attributes = &attribute_pointers[0];
            start_tag.self_closing = src->start_tag.self_closing;
            break;
    }

    size_t actual_len = protobuf_c_message_get_packed_size(&actual.base);
    size_t expected_len = protobuf_c_message_get_packed_size(&expected->base);

    bool same = actual_len == expected_len;

    if (same) {
        uint8_t actual_buf[actual_len];
        uint8_t expected_buf[expected_len];

        protobuf_c_message_pack(&actual.base, actual_buf);
        protobuf_c_message_pack(&expected->base, expected_buf);

        same = memcmp(actual_buf, expected_buf, actual_len) == 0;
    }

    if (!same) {
        fprintf(stderr, "Actual: ");
        fprint_msg(stderr, &actual.base);
        fprintf(stderr, "\nExpected: ");
        fprint_msg(stderr, &expected->base);
        fprintf(stderr, "\n");
    }

    return same;
}

typedef struct {
    const char *error;
    const char *raw_pos;
    unsigned int expected_pos;
    const unsigned int expected_length;
    Suite__Test__Token **const expected;
} State;

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
    if (!tokens_match(token, expected)) {
        state->error = "Token mismatch";
        return;
    }
}

static void run_test(const Suite__Test *test) {
    if (strnstr((char *) test->description.data, "entity", test->description.len) != NULL || strnstr((char *) test->description.data, "NUL", test->description.len) != NULL) {
        // TODO: add decoding support
        return;
    }

    State custom_state = {
        .expected_length = test->n_output,
        .expected = test->output
    };
    TokenizerOpts options = {
        .on_token = on_token,
        .last_start_tag_name = to_tok_string(test->last_start_tag),
        .extra = &custom_state
    };
    TokenizerState state;
    TokenizerString input = to_tok_string(test->input);
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