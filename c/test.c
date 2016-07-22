#include <assert.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include "tests.pb-c.h"
#include "tokenizer.h"
#include "field-names.h"
#include "parser-feedback.h"
#include "concat-char-tokens.h"
#include "decoder.h"

static lhtml_string_t to_tok_string(const ProtobufCBinaryData data) {
    lhtml_string_t str = {
        .length = data.len,
        .data = (char *) data.data
    };
    return str;
}

static int to_tok_state(const Suite__Test__State state) {
    #define state_case(NAME) \
        case SUITE__TEST__STATE__##NAME:\
            return LHTML_STATE_##NAME;

    switch (state) {
        state_case(DATA)
        state_case(PLAINTEXT)
        state_case(RCDATA)
        state_case(RAWTEXT)
        state_case(SCRIPTDATA)

        default:
            assert(false);
            return LHTML_STATE_ERROR;
    }
}

static ProtobufCBinaryData to_test_string(const lhtml_string_t src) {
    ProtobufCBinaryData dest;
    dest.data = (unsigned char *) src.data;
    dest.len = src.length;
    return dest;
}

static void to_opt_test_string(const lhtml_opt_string_t src, volatile protobuf_c_boolean *has_value, volatile ProtobufCBinaryData *value) {
    if ((*has_value = src.has_value)) {
        *value = to_test_string(src.value);
    }
}

static void fprint_escaped_str(FILE *file, const ProtobufCBinaryData str) {
    fprintf(file, "'");
    for (size_t i = 0; i < str.len; i++) {
        const unsigned char c = str.data[i];
        if (iscntrl(c)) {
            fprintf(file, "\\x%02X", c);
        } else if (c == '\'') {
            fprintf(file, "\\\'");
        } else {
            fprintf(file, "%c", c);
        }
    }
    fprintf(file, "'");
}

static void fprint_msg(FILE *file, const volatile ProtobufCMessage *msg) {
    const ProtobufCMessageDescriptor *desc = msg->descriptor;
    fprintf(file, "%s { ", desc->short_name);
    const unsigned int n_fields = desc->n_fields;
    const unsigned int n_distinct_fields = desc->n_field_ranges;
    const ProtobufCFieldDescriptor* fields = desc->fields;
    const char *mem = (const char *) msg;
    for (unsigned int i = 0; i < n_fields; i++) {
        if (i > 0) {
            fprintf(file, ", ");
        }
        const ProtobufCFieldDescriptor* field = &fields[i];
        bool is_oneof = field->flags & PROTOBUF_C_FIELD_FLAG_ONEOF;
        if (is_oneof) {
            unsigned int quantifier = *((unsigned int *) (mem + field->quantifier_offset));
            i += quantifier - 1;
            assert(i >= 0 && i < n_fields);
            field = &fields[i];
            for (; i < n_fields && fields[i].quantifier_offset == field->quantifier_offset; i++);
            i--;
        }
        if (n_distinct_fields > 1) {
            fprintf(file, "%s = ", field->name);
        }
        if (!is_oneof && field->label == PROTOBUF_C_LABEL_OPTIONAL && !*((bool *) (mem + field->quantifier_offset))) {
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
        for (unsigned int j = 0; j < n_values; j++) {
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
                    fprint_escaped_str(file, *rec);
                    value = rec + 1;
                    break;
                }

                case PROTOBUF_C_TYPE_ENUM: {
                    const int *rec = value;
                    const ProtobufCEnumDescriptor *enum_desc = field->descriptor;
                    fprintf(file, "%s", protobuf_c_enum_descriptor_get_value(enum_desc, *rec)->name);
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

typedef struct {
    lhtml_token_handler_t handler;

    lhtml_state_t tokenizer;
    lhtml_feedback_state_t feedback;
    lhtml_concat_state_t concat;
    lhtml_decoder_state_t decoder;

    Suite__Test__State initial_state;
    bool error;
    const char *raw_pos;
    size_t expected_pos;
    const size_t expected_length;
    const Suite__Test *test;
} test_state_t;

static void fprint_fail(FILE *file, test_state_t *state, const char *msg) {
    state->error = true;
    fprintf(
        file,
        "not ok - %s\n"
        "  ---\n"
        "    input: ",
        msg
    );
    fprint_escaped_str(file, state->test->input);
    fprintf(
        file,
        "\n"
        "    state: %s\n"
        ,
        protobuf_c_enum_descriptor_get_value(&suite__test__state__descriptor, state->initial_state)->name
    );
}

static void fprint_fail_end(FILE *file) {
    fprintf(file, "  ...\n");
}

static void tokens_match(test_state_t *state, const lhtml_token_t *src) {
    if (state->expected_pos >= state->expected_length) {
        fprint_fail(stdout, state, "Extraneous tokens");
        fprintf(stdout, "  actual:   %zu\n", state->expected_pos);
        fprintf(stdout, "  expected: %zu\n", state->expected_length - 1);
        fprint_fail_end(stdout);
        return;
    }

    const ProtobufCMessage *expected = &state->test->output[state->expected_pos]->base;

    volatile Suite__Test__Token actual = SUITE__TEST__TOKEN__INIT;

    #define case_token(TYPE, CAP_TYPE) case LHTML_TOKEN_##CAP_TYPE:;\
        volatile Suite__Test__##TYPE LHTML_FIELD_NAME_##CAP_TYPE = SUITE__TEST__##CAP_TYPE##__INIT;\
        actual.token_case = SUITE__TEST__TOKEN__TOKEN_##CAP_TYPE;\
        actual.LHTML_FIELD_NAME_##CAP_TYPE = (Suite__Test__##TYPE *) &LHTML_FIELD_NAME_##CAP_TYPE;

    const size_t n_attributes = src->type == LHTML_TOKEN_START_TAG ? src->start_tag.attributes.count : 0;
    Suite__Test__Attribute attributes[n_attributes];
    Suite__Test__Attribute *attribute_pointers[n_attributes];

    switch (src->type) {
        default:
            assert(false);

        case_token(Character, CHARACTER)
            character.value = to_test_string(src->character.value);
            break;

        case_token(Doctype, DOCTYPE)
            to_opt_test_string(src->doctype.name, &doctype.has_name, &doctype.name);
            to_opt_test_string(src->doctype.public_id, &doctype.has_public_id, &doctype.public_id);
            to_opt_test_string(src->doctype.system_id, &doctype.has_system_id, &doctype.system_id);
            doctype.force_quirks = src->doctype.force_quirks;
            break;

        case_token(Comment, COMMENT)
            comment.value = to_test_string(src->comment.value);
            break;

        case_token(EndTag, END_TAG)
            end_tag.name = to_test_string(src->end_tag.name);
            break;

        case_token(StartTag, START_TAG)
            start_tag.name = to_test_string(src->start_tag.name);
            start_tag.n_attributes = 0;
            for (size_t i = 0; i < n_attributes; i++) {
                Suite__Test__Attribute *attr = attribute_pointers[start_tag.n_attributes] = &attributes[start_tag.n_attributes];
                suite__test__attribute__init(attr);
                const lhtml_attribute_t *src_attr = &src->start_tag.attributes.items[i];
                const ProtobufCBinaryData name = attr->name = to_test_string(src_attr->name);
                attr->value = to_test_string(src_attr->value);
                bool duplicate_name = false;
                long insert_before = -1;
                for (size_t j = 0; j < start_tag.n_attributes; j++) {
                    ProtobufCBinaryData other_name = attributes[j].name;
                    int cmp_result = memcmp(name.data, other_name.data, name.len < other_name.len ? name.len : other_name.len);
                    if (name.len == other_name.len && cmp_result == 0) {
                        duplicate_name = true;
                        break;
                    }
                    if (cmp_result < 0 && insert_before < 0) {
                        insert_before = (long) j;
                    }
                }
                if (!duplicate_name) {
                    start_tag.n_attributes++;
                    if (insert_before >= 0) {
                        const Suite__Test__Attribute new_attr = attributes[start_tag.n_attributes - 1];
                        for (long j = (long) start_tag.n_attributes - 2; j >= insert_before; j--) {
                            attributes[j + 1] = attributes[j];
                        }
                        attributes[insert_before] = new_attr;
                    }
                }
            }
            start_tag.attributes = attribute_pointers;
            start_tag.self_closing = src->start_tag.self_closing;
            break;
    }

    size_t actual_len = protobuf_c_message_get_packed_size((ProtobufCMessage *) &actual);
    size_t expected_len = protobuf_c_message_get_packed_size((ProtobufCMessage *) expected);

    bool same = actual_len == expected_len;

    if (same) {
        uint8_t actual_buf[actual_len];
        uint8_t expected_buf[expected_len];

        protobuf_c_message_pack((ProtobufCMessage *) &actual, actual_buf);
        protobuf_c_message_pack(expected, expected_buf);

        same = memcmp(actual_buf, expected_buf, actual_len) == 0;
    }

    if (!same) {
        fprint_fail(stdout, state, "token mismatch");

        fprintf(stdout, "    actual:   ");
        fprint_msg(stdout, (ProtobufCMessage *) &actual);
        fprintf(stdout, "\n");

        fprintf(stdout, "    expected: ");
        fprint_msg(stdout, expected);
        fprintf(stdout, "\n");

        fprint_fail_end(stdout);
    }

    return;
}

static void on_token(lhtml_token_t *token, void *extra) {
    test_state_t *state = extra;
    if (state->error || token->type == LHTML_TOKEN_EOF) {
        return;
    }
    if (token->type == LHTML_TOKEN_ERROR) {
        fprint_fail(stdout, state, "tokenization error");
        fprintf(stdout, "    leftover: \"%.*s\"\n", (int) token->raw.length, token->raw.data);
        fprint_fail_end(stdout);
        return;
    }
    tokens_match(state, token);
    if (!state->error) {
        state->expected_pos++;
    }
}

static void run_test(const Suite__Test *test, bool with_feedback) {
    printf(
        "# %.*s%s\n",
        (int) test->description.len,
        (char *) test->description.data,
        with_feedback ? " (with feedback)" : ""
    );
    for (size_t i = 0; i < test->input.len; i++) {
        char c = (char) test->input.data[i];
        if (c == '&' || c == '\0' || c == '\r') {
            printf("ok # skip Decoding is unsupported yet\n");
            return;
        }
    }
    test_state_t state = {
        .expected_length = test->n_output,
        .test = test
    };
    char buffer[2048];
    lhtml_options_t options = {
        .last_start_tag_name = to_tok_string(test->last_start_tag),
        .buffer = buffer,
        .buffer_size = sizeof(buffer)
    };
    lhtml_string_t input = to_tok_string(test->input);
    for (size_t i = 0; i < test->n_initial_states; i++) {
        state.initial_state = test->initial_states[i];
        state.error = false;
        state.raw_pos = input.data;
        state.expected_pos = 0;
        options.initial_state = to_tok_state(state.initial_state);
        lhtml_init(&state.tokenizer, &options);
        if (with_feedback) {
            lhtml_feedback_inject(&state.tokenizer, &state.feedback);
        }
        lhtml_concat_inject(&state.tokenizer, &state.concat);
        lhtml_decoder_inject(&state.tokenizer, &state.decoder);
        lhtml_add_handler(&state.tokenizer, &state.handler, on_token);
        for (size_t j = 0; j < input.length; j++) {
            char c = input.data[j]; // to ensure that pointers are not saved to the original data
            const lhtml_string_t ch = {
                .length = 1,
                .data = &c
            };
            if (!lhtml_feed(&state.tokenizer, &ch) || state.error) {
                return;
            }
        }
        if (!lhtml_feed(&state.tokenizer, NULL) || state.error) {
            return;
        }

        if (state.expected_pos < state.expected_length) {
            fprint_fail(stdout, &state, "Not enough tokens");
            fprintf(stdout, "    actual:   %zu\n", state.expected_pos);
            fprintf(stdout, "    expected: %zu\n", state.expected_length);
            fprint_fail_end(stdout);
            return;
        }
    }
    printf("ok\n");
}

static void run_suite(const char *path, bool with_feedback) {
    FILE *infile = fopen(path, "rb");

    assert(infile);

    fseek(infile, 0, SEEK_END);
    size_t numbytes = (size_t) ftell(infile);

    uint8_t *buffer = malloc(numbytes);

    assert(buffer);

    rewind(infile);

    size_t readbytes = fread(buffer, sizeof(char), numbytes, infile);
    assert(readbytes == numbytes);
    fclose(infile);

    Suite *suite = suite__unpack(NULL, numbytes, buffer);

    free(buffer);

    assert(suite);

    const size_t n = suite->n_tests;

    printf(
        "TAP version 13\n"
        "1..%zu\n",
        n
    );

    for (size_t i = 0; i < n; i++) {
        run_test(suite->tests[i], with_feedback);
    }

    suite__free_unpacked(suite, NULL);
}

int main() {
    run_suite("../tests.dat", false);
    run_suite("../tests-with-feedback.dat", true);

    return 0;
}
