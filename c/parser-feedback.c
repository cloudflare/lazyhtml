#include <stdbool.h>
#include <assert.h>
#include "parser-feedback.h"
// #include "$OUT/tokenizer-states.h" - included with command option to respect env var

lhtml_ns_t lhtml_get_current_ns(const lhtml_feedback_t *state) {
    return state->ns_stack.data[state->ns_stack.length - 1];
}

static bool is_foreign_ns(lhtml_ns_t ns) {
    return ns != LHTML_NS_HTML;
}

__attribute__((warn_unused_result))
static bool enter_ns(lhtml_feedback_t *state, lhtml_ns_t ns) {
    if (state->ns_stack.length >= state->ns_stack.capacity) {
        return false;
    }
    state->ns_stack.data[state->ns_stack.length++] = ns;
    state->tokenizer->allow_cdata = is_foreign_ns(ns);
    return true;
}

static void leave_ns(lhtml_feedback_t *state) {
    assert(state->ns_stack.length > 1);
    state->ns_stack.length--;
    state->tokenizer->allow_cdata = is_foreign_ns(lhtml_get_current_ns(state));
}

static void ensure_tokenizer_mode(lhtml_tokenizer_t *tokenizer, lhtml_tag_type_t tag_type) {
    int new_state;

    switch (tag_type) {
        case LHTML_TAG_TEXTAREA:
        case LHTML_TAG_TITLE:
            new_state = html_en_RCData;
            break;

        case LHTML_TAG_PLAINTEXT:
            new_state = html_en_PlainText;
            break;

        case LHTML_TAG_SCRIPT:
            new_state = html_en_ScriptData;
            break;

        case LHTML_TAG_STYLE:
        case LHTML_TAG_IFRAME:
        case LHTML_TAG_XMP:
        case LHTML_TAG_NOEMBED:
        case LHTML_TAG_NOFRAMES:
        case LHTML_TAG_NOSCRIPT:
            new_state = html_en_RawText;
            break;

        default:
            return;
    }

    tokenizer->cs = new_state;
}

static bool can_be_self_closing(lhtml_tag_type_t tag_type) {
    switch (tag_type) {
        case LHTML_TAG_BASE:
        case LHTML_TAG_BASEFONT:
        case LHTML_TAG_BGSOUND:
        case LHTML_TAG_LINK:
        case LHTML_TAG_META:
        case LHTML_TAG_AREA:
        case LHTML_TAG_BR:
        case LHTML_TAG_EMBED:
        case LHTML_TAG_IMG:
        case LHTML_TAG_KEYGEN:
        case LHTML_TAG_WBR:
        case LHTML_TAG_INPUT:
        case LHTML_TAG_PARAM:
        case LHTML_TAG_SOURCE:
        case LHTML_TAG_TRACK:
        case LHTML_TAG_HR:
        case LHTML_TAG_MATH:
        case LHTML_TAG_SVG:
        case LHTML_TAG_COL:
        case LHTML_TAG_FRAME:
            return true;
        default:
            return false;
    }
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
            for (size_t i = 0; i < attrs->length; i++) {
                const lhtml_string_t name = attrs->data[i].name;
                if (LHTML_STR_NOCASE_EQUALS(name, "color") || LHTML_STR_NOCASE_EQUALS(name, "size") || LHTML_STR_NOCASE_EQUALS(name, "face")) {
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
                    if (attrs && LHTML_STR_NOCASE_EQUALS(name, "annotation-xml")) {
                        for (size_t i = 0; i < attrs->length; i++) {
                            const lhtml_attribute_t *attr = &attrs->data[i];
                            if (LHTML_STR_NOCASE_EQUALS(attr->name, "encoding") && (LHTML_STR_NOCASE_EQUALS(attr->value, "text/html") || LHTML_STR_NOCASE_EQUALS(attr->value, "application/xhtml+xml"))) {
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

__attribute__((warn_unused_result))
static bool handle_start_tag_token(lhtml_feedback_t *state, lhtml_token_starttag_t *tag, bool *delayed_enter_html) {
    lhtml_tag_type_t type = tag->type;

    if (type == LHTML_TAG_SVG || type == LHTML_TAG_MATH) {
        return enter_ns(state, (lhtml_ns_t) type);
    }

    lhtml_ns_t ns = lhtml_get_current_ns(state);

    if (is_foreign_ns(ns)) {
        if (foreign_causes_exit(tag)) {
            leave_ns(state);
        } else {
            *delayed_enter_html = !tag->self_closing && foreign_is_integration_point(ns, type, tag->name, &tag->attributes);
        }
    } else {
        if (type == LHTML_TAG_IMAGE) {
            tag->type = LHTML_TAG_IMG;
            tag->name = LHTML_STRING("img");
        }

        ensure_tokenizer_mode(state->tokenizer, type);
    }

    return true;
}

static void handle_end_tag_token(lhtml_feedback_t *state, const lhtml_token_endtag_t *tag) {
    lhtml_tag_type_t type = tag->type;

    lhtml_ns_t ns = lhtml_get_current_ns(state);

    if (is_foreign_ns(ns)) {
        if (type == (lhtml_tag_type_t) ns) {
            leave_ns(state);
        }
    } else if (state->ns_stack.length >= 2) {
        lhtml_ns_t prev_ns = state->ns_stack.data[state->ns_stack.length - 2];

        if (foreign_is_integration_point(prev_ns, type, tag->name, NULL)) {
            leave_ns(state);
        }
    }
}

static void handle_token(lhtml_token_t *token, lhtml_feedback_t *state) {
    if (token->type == LHTML_TOKEN_START_TAG) {
        bool delayed_enter_html = false;
        if (!handle_start_tag_token(state, &token->start_tag, &delayed_enter_html)) {
            token->type = LHTML_TOKEN_ERROR;
            state->tokenizer->cs = html_error;
        }

        lhtml_ns_t ns = lhtml_get_current_ns(state);

        if (!is_foreign_ns(ns) && !can_be_self_closing(token->start_tag.type)) {
            token->parse_errors |= 1ULL << LHTML_ERR_NON_VOID_HTML_START_TAG_WITH_TRAILING_SOLIDUS;
        }

        lhtml_emit(token, state);

        if (delayed_enter_html) {
            if (!enter_ns(state, LHTML_NS_HTML)) {
                state->tokenizer->cs = html_error;
            }
        }
    } else {
        lhtml_emit(token, state);
        if (token->type == LHTML_TOKEN_END_TAG) {
            handle_end_tag_token(state, &token->end_tag);
        }
    }
}

void lhtml_feedback_inject(lhtml_tokenizer_t *tokenizer, lhtml_feedback_t *state) {
    state->tokenizer = tokenizer;
    assert(enter_ns(state, LHTML_NS_HTML));
    LHTML_ADD_HANDLER(tokenizer, state, handle_token);
}
