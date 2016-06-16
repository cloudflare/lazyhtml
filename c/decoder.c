#include "decoder.h"

static char *to_ascii_lower(lhtml_string_t *str, char *data) {
    for (size_t i = 0; i < str->length; i++) {
        char c = str->data[i];
        if (c >= 'A' && c <= 'Z') {
            c |= 0x20;
        }
        data[i] = c;
    }
    str->data = data;
    return data + str->length;
}

static void handle_token(lhtml_token_t *token, void *extra) {
    if (token->type == LHTML_TOKEN_START_TAG) {
        lhtml_token_starttag_t *start_tag = &token->start_tag;
        lhtml_attributes_t *attrs = &start_tag->attributes;
        size_t buf_size = start_tag->name.length;
        for (size_t i = 0; i < attrs->count; i++) {
            buf_size += attrs->items[i].name.length;
        }
        char buffer[buf_size];
        char *buf_pos = buffer;
        buf_pos = to_ascii_lower(&start_tag->name, buf_pos);
        for (size_t i = 0; i < attrs->count; i++) {
            lhtml_attribute_t *attr = &attrs->items[i];
            buf_pos = to_ascii_lower(&attr->name, buf_pos);
        }
        lhtml_emit(token, extra);
    } else if (token->type == LHTML_TOKEN_END_TAG) {
        lhtml_string_t *end_tag_name = &token->end_tag.name;
        char buffer[end_tag_name->length];
        to_ascii_lower(end_tag_name, buffer);
        lhtml_emit(token, extra);
    } else if (token->type == LHTML_TOKEN_DOCTYPE && token->doctype.name.has_value) {
        lhtml_string_t *doc_type_name = &token->doctype.name.value;
        char buffer[doc_type_name->length];
        to_ascii_lower(doc_type_name, buffer);
        lhtml_emit(token, extra);
    } else {
        lhtml_emit(token, extra);
    }
}

void lhtml_decoder_inject(lhtml_state_t *tokenizer, lhtml_decoder_state_t *state) {
    lhtml_add_handler(tokenizer, &state->handler, handle_token);
}