#include "decoder.h"

static char *to_ascii_lower(TokenizerString *str, char *data) {
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

static void handle_token(Token *token, void *extra) {
    if (token->type == token_start_tag) {
        TokenStartTag *start_tag = &token->start_tag;
        TokenAttributes *attrs = &start_tag->attributes;
        size_t buf_size = start_tag->name.length;
        for (size_t i = 0; i < attrs->count; i++) {
            buf_size += attrs->items[i].name.length;
        }
        char buffer[buf_size];
        char *buf_pos = buffer;
        buf_pos = to_ascii_lower(&start_tag->name, buf_pos);
        for (size_t i = 0; i < attrs->count; i++) {
            Attribute *attr = &attrs->items[i];
            buf_pos = to_ascii_lower(&attr->name, buf_pos);
        }
        html_tokenizer_emit(extra, token);
    } else if (token->type == token_end_tag) {
        TokenizerString *end_tag_name = &token->end_tag.name;
        char buffer[end_tag_name->length];
        to_ascii_lower(end_tag_name, buffer);
        html_tokenizer_emit(extra, token);
    } else if (token->type == token_doc_type && token->doc_type.name.has_value) {
        TokenizerString *doc_type_name = &token->doc_type.name.value;
        char buffer[doc_type_name->length];
        to_ascii_lower(doc_type_name, buffer);
        html_tokenizer_emit(extra, token);
    } else {
        html_tokenizer_emit(extra, token);
    }
}

void decoder_inject(TokenizerState *tokenizer, DecoderState *state) {
    html_tokenizer_add_handler(tokenizer, &state->handler, handle_token);
}