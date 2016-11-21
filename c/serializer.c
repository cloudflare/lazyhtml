#include <stdbool.h>
#include <assert.h>
#include "serializer.h"

static void serialize(lhtml_token_t *token, lhtml_serializer_state_t *extra) {
    lhtml_serializer_options_t *options = &extra->options;

    lhtml_string_callback_t write = options->writer;

    if (token->raw.has_value) {
        if (options->compact && token->type == LHTML_TOKEN_COMMENT) {
            return;
        }

        write(token->raw.value, extra);
        return;
    }

    switch (token->type) {
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
                    if (token->doctype.system_id.has_value) {
                        // with public and system ids: `<!DOCTYPE PUBLIC "public-id" "system-id">`
                        write(LHTML_STRING("\" \""), extra);
                        write(token->doctype.system_id.value, extra); // shouldn't contain `"` or `>`
                    }
                    write(LHTML_STRING("\">"), extra);
                } else if (token->doctype.system_id.has_value) {
                    // with system id only: `<!DOCTYPE SYSTEM "system-id">`
                    write(LHTML_STRING("SYSTEM \""), extra);
                    write(token->doctype.system_id.value, extra); // shouldn't contain `"` or `>`
                    write(LHTML_STRING("\">"), extra);
                }
            } else {
                write(LHTML_STRING(">"), extra);
            }
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
            for (size_t i = 0; i < attrs->count; i++) {
                lhtml_attribute_t *attr = &attrs->items[i];
                write(LHTML_STRING(" "), extra);
                if (attr->raw.has_value) {
                    write(attr->raw.value, extra);
                } else {
                    write(attr->name, extra);
                    write(LHTML_STRING("=\""), extra);
                    write(attr->value, extra); // shouldn't contain '"'
                    write(LHTML_STRING("\""), extra);
                }
            }
            if (token->start_tag.self_closing) {
                write(LHTML_STRING("/"), extra);
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

        case LHTML_TOKEN_ERROR:
        case LHTML_TOKEN_EOF: {
            break;
        }

        case LHTML_TOKEN_UNKNOWN: {
            assert(false);
            break;
        }
    }
}

void lhtml_serializer_inject(lhtml_state_t *tokenizer, lhtml_serializer_state_t *state, const lhtml_serializer_options_t *options) {
    state->options = *options;
    LHTML_ADD_HANDLER(tokenizer, state, serialize);
}
