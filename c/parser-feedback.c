#include <stdbool.h>
#include <assert.h>
#include "parser-feedback.h"

lhtml_ns_t lhtml_get_current_ns(lhtml_feedback_state_t *state) {
    return state->ns_stack[state->ns_depth - 1];
}

static bool is_foreign_ns(lhtml_ns_t ns) {
    return ns != LHTML_NS_HTML;
}

static bool is_in_foreign_content(lhtml_feedback_state_t *state) {
    return is_foreign_ns(lhtml_get_current_ns(state));
}

static void enter_ns(lhtml_feedback_state_t *state, lhtml_ns_t ns) {
    if (state->ns_depth < LHTML_MAX_NS_DEPTH) {
        state->ns_stack[state->ns_depth++] = ns;
    } else {
        state->tokenizer->cs = 0;
    }
    state->tokenizer->allow_cdata = is_foreign_ns(ns);
}

static void leave_ns(lhtml_feedback_state_t *state) {
    if (state->ns_depth > 1) {
        state->ns_depth--;
    } else {
        state->tokenizer->cs = 0;
    }
    state->tokenizer->allow_cdata = is_in_foreign_content(state);
}

static void ensure_tokenizer_mode(lhtml_state_t *tokenizer, lhtml_tag_type_t tag_type) {
    int new_state;

    switch (tag_type) {
        case LHTML_TAG_TEXTAREA:
        case LHTML_TAG_TITLE:
            new_state = LHTML_STATE_RCDATA;
            break;

        case LHTML_TAG_PLAINTEXT:
            new_state = LHTML_STATE_PLAINTEXT;
            break;

        case LHTML_TAG_SCRIPT:
            new_state = LHTML_STATE_SCRIPTDATA;
            break;

        case LHTML_TAG_STYLE:
        case LHTML_TAG_IFRAME:
        case LHTML_TAG_XMP:
        case LHTML_TAG_NOEMBED:
        case LHTML_TAG_NOFRAMES:
        case LHTML_TAG_NOSCRIPT:
            new_state = LHTML_STATE_RAWTEXT;
            break;

        default:
            return;
    }

    tokenizer->cs = new_state;
}

static bool foreign_causes_exit(const lhtml_token_starttag_t *start_tag) {
    switch (start_tag->type) {
        case LHTML_TAG_B:
        case LHTML_TAG_BIG:
        case LHTML_TAG_BLOCKQUOTE:
        case LHTML_TAG_BODY:
        case LHTML_TAG_BR:
        case LHTML_TAG_CENTER:
        case LHTML_TAG_CODE:
        case LHTML_TAG_DD:
        case LHTML_TAG_DIV:
        case LHTML_TAG_DL:
        case LHTML_TAG_DT:
        case LHTML_TAG_EM:
        case LHTML_TAG_EMBED:
        /*case LHTML_TAG_H1:
        case LHTML_TAG_H2:
        case LHTML_TAG_H3:
        case LHTML_TAG_H4:
        case LHTML_TAG_H5:
        case LHTML_TAG_H6:*/
        case LHTML_TAG_HEAD:
        case LHTML_TAG_HR:
        case LHTML_TAG_I:
        case LHTML_TAG_IMG:
        case LHTML_TAG_LI:
        case LHTML_TAG_LISTING:
        case LHTML_TAG_MENU:
        case LHTML_TAG_META:
        case LHTML_TAG_NOBR:
        case LHTML_TAG_OL:
        case LHTML_TAG_P:
        case LHTML_TAG_PRE:
        case LHTML_TAG_RUBY:
        case LHTML_TAG_S:
        case LHTML_TAG_SMALL:
        case LHTML_TAG_SPAN:
        case LHTML_TAG_STRONG:
        case LHTML_TAG_STRIKE:
        case LHTML_TAG_SUB:
        case LHTML_TAG_SUP:
        case LHTML_TAG_TABLE:
        case LHTML_TAG_TT:
        case LHTML_TAG_U:
        case LHTML_TAG_UL:
        case LHTML_TAG_VAR:
            return true;
        case LHTML_TAG_FONT: {
            const lhtml_attributes_t *attrs = &start_tag->attributes;
            for (size_t i = 0; i < attrs->count; i++) {
                const lhtml_string_t name = attrs->items[i].name;
                if (LHTML_NAME_EQUALS(name, "color") || LHTML_NAME_EQUALS(name, "size") || LHTML_NAME_EQUALS(name, "face")) {
                    return true;
                }
            }
            return false;
        }
        default: {
            const lhtml_string_t name = start_tag->name;
            return name.length == 2 && ((name.data[0] | 0x20) == 'h') && (name.data[1] >= '1' && name.data[1] <= '6');
        }
    }
}

static bool foreign_is_integration_point(lhtml_ns_t ns, lhtml_tag_type_t type, const lhtml_string_t name, const lhtml_attributes_t *attrs) {
    switch (ns) {
        case LHTML_NS_MATHML:
            switch (type) {
                case LHTML_TAG_MI:
                case LHTML_TAG_MO:
                case LHTML_TAG_MN:
                case LHTML_TAG_MS:
                case LHTML_TAG_MTEXT:
                    return true;

                default: {
                    if (attrs && LHTML_NAME_EQUALS(name, "annotation-xml")) {
                        for (size_t i = 0; i < attrs->count; i++) {
                            const lhtml_attribute_t *attr = &attrs->items[i];
                            if (LHTML_NAME_EQUALS(attr->name, "encoding") && (LHTML_NAME_EQUALS(attr->value, "text/html") || LHTML_NAME_EQUALS(attr->value, "application/xhtml+xml"))) {
                                return true;
                            }
                        }
                    }
                    return false;
                }
            }

        case LHTML_NS_SVG:
            return type == LHTML_TAG_DESC || type == LHTML_TAG_TITLE || type == LHTML_TAG_FOREIGNOBJECT;

        case LHTML_NS_HTML:
            return false;

        default:
            assert(false);
    }
}

static bool handle_start_tag_token(lhtml_feedback_state_t *state, lhtml_token_starttag_t *tag) {
    lhtml_tag_type_t type = tag->type;

    if (type == LHTML_TAG_SVG || type == LHTML_TAG_MATH) {
        enter_ns(state, (lhtml_ns_t) type);
        return false;
    }

    lhtml_ns_t ns = lhtml_get_current_ns(state);

    if (is_foreign_ns(ns)) {
        if (foreign_causes_exit(tag)) {
            leave_ns(state);
            return false;
        }

        return !tag->self_closing && foreign_is_integration_point(ns, type, tag->name, &tag->attributes);
    } else {
        switch (type) {
            case LHTML_TAG_PRE:
            case LHTML_TAG_TEXTAREA:
            case LHTML_TAG_LISTING:
                state->skip_next_newline = true;
                break;

            case LHTML_TAG_IMAGE:
                tag->type = LHTML_TAG_IMG;
                tag->name = LHTML_STRING("img");
                break;

            default:
                break;
        }

        ensure_tokenizer_mode(state->tokenizer, type);

        return false;
    }
}

static void handle_end_tag_token(lhtml_feedback_state_t *state, const lhtml_token_endtag_t *tag) {
    lhtml_tag_type_t type = tag->type;

    if (is_in_foreign_content(state)) {
        lhtml_ns_t ns = lhtml_get_current_ns(state);

        if (type == (lhtml_tag_type_t) ns) {
            leave_ns(state);
        }
    } else if (state->ns_depth >= 2) {
        lhtml_ns_t prev_ns = state->ns_stack[state->ns_depth - 2];

        if (foreign_is_integration_point(prev_ns, type, tag->name, NULL)) {
            leave_ns(state);
        }
    }
}

static void handle_token(lhtml_token_t *token, void *extra) {
    lhtml_feedback_state_t *state = extra;

    if (state->skip_next_newline) {
        state->skip_next_newline = false;

        if (token->type == LHTML_TOKEN_CHARACTER) {
            lhtml_string_t *value = &token->character.value;

            if (value->length >= 1) {
                size_t skip = 0;

                if (value->data[0] == '\n') {
                    skip = 1;
                } else if (value->data[0] == '\r') {
                    skip = value->length >= 2 && value->data[1] == '\n' ? 2 : 1;
                }

                if (value->length == skip) {
                    return;
                }

                value->data += skip;
                value->length -= skip;
            }
        }
    }

    if (token->type == LHTML_TOKEN_START_TAG) {
        bool enter_html = handle_start_tag_token(state, &token->start_tag);
        lhtml_emit(token, extra);
        if (enter_html) {
            enter_ns(state, LHTML_NS_HTML);
        }
    } else {
        lhtml_emit(token, extra);
        if (token->type == LHTML_TOKEN_END_TAG) {
            handle_end_tag_token(state, &token->end_tag);
        }
    }
}

void lhtml_feedback_inject(lhtml_state_t *tokenizer, lhtml_feedback_state_t *state) {
    state->tokenizer = tokenizer;
    state->ns_depth = 0;
    state->skip_next_newline = false;
    enter_ns(state, LHTML_NS_HTML);
    lhtml_add_handler(tokenizer, &state->handler, handle_token);
}