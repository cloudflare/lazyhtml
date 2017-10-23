#include <stdbool.h>
#include <assert.h>
#include <string.h>
#include "serializer.h"

typedef struct {
    lhtml_string_t str;
    const char separator;
    bool done;
} split_iterator_t;

static lhtml_string_t split_iterator_next(split_iterator_t *iter) {
    lhtml_string_t str = iter->str;
    const char *ptr = memchr(str.data, iter->separator, str.length);
    if (ptr == NULL) {
        iter->done = true;
        return str;
    }
    const char *next = ptr + 1;
    const char *end = str.data + str.length;
    iter->str = (lhtml_string_t) {
        .data = next,
        .length = end - next
    };
    return (lhtml_string_t) {
        .data = str.data,
        .length = ptr - str.data
    };
}

static void serialize(lhtml_token_t *token, lhtml_serializer_state_t *extra) {
    lhtml_string_callback_t write = extra->writer;

    if (token->raw.has_value) {
        write(token->raw.value, extra);
        return;
    }

    switch (token->type) {
        case LHTML_TOKEN_CDATA_START: {
            write(LHTML_STRING("<![CDATA["), extra);
            break;
        }

        case LHTML_TOKEN_CDATA_END: {
            write(LHTML_STRING("]]>"), extra);
            break;
        }

        case LHTML_TOKEN_CHARACTER: {
            write(token->character.value, extra);
            break;
        }

        case LHTML_TOKEN_DOCTYPE: {
            write(LHTML_STRING("<!DOCTYPE"), extra);
            if (token->doctype.name.has_value) {
                // with name: `<!DOCTYPE html`
                write(LHTML_STRING(" "), extra);
                write(token->doctype.name.value, extra); // non-empty; shouldn't contain spaces or `>`
                if (token->doctype.public_id.has_value) {
                    // with public id: `<!DOCTYPE PUBLIC "public-id"`
                    write(LHTML_STRING(" PUBLIC \""), extra);
                    write(token->doctype.public_id.value, extra); // shouldn't contain `"` or `>`
                    if (!(token->doctype.force_quirks && !token->doctype.system_id.has_value)) {
                        write(LHTML_STRING("\""), extra);
                    }
                } else if (token->doctype.system_id.has_value) {
                    write(LHTML_STRING(" SYSTEM"), extra);
                } else if (token->doctype.force_quirks) {
                    write(LHTML_STRING(" _"), extra);
                }
                if (token->doctype.system_id.has_value) {
                    write(LHTML_STRING(" \""), extra);
                    write(token->doctype.system_id.value, extra);
                    if (!token->doctype.force_quirks) {
                        write(LHTML_STRING("\""), extra);
                    }
                }
            }
            write(LHTML_STRING(">"), extra);
            break;
        }

        case LHTML_TOKEN_COMMENT: {
            write(LHTML_STRING("<!--"), extra);
            write(token->comment.value, extra); // shouldn't contain `-->`
            write(LHTML_STRING("-->"), extra);
            break;
        }

        case LHTML_TOKEN_START_TAG: {
            write(LHTML_STRING("<"), extra);
            write(token->start_tag.name, extra); // non-empty, starts with ASCII letter
            lhtml_attributes_t *attrs = &token->start_tag.attributes;
            for (size_t i = 0; i < attrs->length; i++) {
                lhtml_attribute_t *attr = &attrs->data[i];
                write(LHTML_STRING(" "), extra);
                if (attr->raw.has_value) {
                    write(attr->raw.value, extra);
                } else {
                    write(attr->name, extra);
                    write(LHTML_STRING("=\""), extra);
                    split_iterator_t iter = {
                        .str = attr->value,
                        .separator = '"'
                    };
                    for(;;) {
                        // escape double-quotes in attribute values by splitting
                        // the string and emitting &quot; between chunks
                        lhtml_string_t chunk = split_iterator_next(&iter);
                        write(chunk, extra);
                        if (iter.done) {
                            // last chunk, no quote afterwards
                            break;
                        }
                        write(LHTML_STRING("&quot;"), extra);
                    }
                    write(LHTML_STRING("\""), extra);
                }
            }
            if (token->start_tag.self_closing) {
                write(LHTML_STRING(" /"), extra);
            }
            write(LHTML_STRING(">"), extra);
            break;
        }

        case LHTML_TOKEN_END_TAG: {
            write(LHTML_STRING("</"), extra);
            write(token->end_tag.name, extra);
            write(LHTML_STRING(">"), extra);
            break;
        }

        case LHTML_TOKEN_UNPARSED:
        case LHTML_TOKEN_ERROR:
        case LHTML_TOKEN_EOF: {
            break;
        }
    }
}

void lhtml_serializer_inject(lhtml_state_t *tokenizer, lhtml_serializer_state_t *state) {
    LHTML_ADD_HANDLER(tokenizer, state, serialize);
}
