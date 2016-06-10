#include <stdbool.h>
#include "parser-feedback.h"

static Namespace get_current_ns(ParserFeedbackState *state) {
    return state->ns_stack[state->ns_depth - 1];
}

static bool is_foreign_ns(Namespace ns) {
    return ns != NS_HTML;
}

static bool is_in_foreign_content(ParserFeedbackState *state) {
    return is_foreign_ns(get_current_ns(state));
}

static void enter_ns(ParserFeedbackState *state, Namespace ns) {
    assert(state->ns_depth < MAX_NS_DEPTH);
    state->ns_stack[state->ns_depth++] = ns;
    state->tokenizer->allow_cdata = is_foreign_ns(ns);
}

static void leave_ns(ParserFeedbackState *state) {
    assert(state->ns_depth > 1);
    state->ns_depth--;
    state->tokenizer->allow_cdata = is_in_foreign_content(state);
}

static void ensure_tokenizer_mode(TokenizerState *tokenizer, HtmlTagType tag_type) {
    int new_state;

    // FIXME tokenizer ignores changes until the new chunk

    switch (tag_type) {
        case HTML_TAG_TEXTAREA:
        case HTML_TAG_TITLE:
            new_state = html_state_RCData;
            break;

        case HTML_TAG_PLAINTEXT:
            new_state = html_state_PlainText;
            break;

        case HTML_TAG_SCRIPT:
            new_state = html_state_ScriptData;
            break;

        case HTML_TAG_STYLE:
        case HTML_TAG_IFRAME:
        case HTML_TAG_XMP:
        case HTML_TAG_NOEMBED:
        case HTML_TAG_NOFRAMES:
        case HTML_TAG_NOSCRIPT:
            new_state = html_state_RawText;
            break;

        default:
            return;
    }

    tokenizer->cs = new_state;
}

static bool foreign_causes_exit(const TokenStartTag *start_tag) {
    switch (start_tag->type) {
        case HTML_TAG_B: return true;
        case HTML_TAG_BIG: return true;
        case HTML_TAG_BLOCKQUOTE: return true;
        case HTML_TAG_BODY: return true;
        case HTML_TAG_BR: return true;
        case HTML_TAG_CENTER: return true;
        case HTML_TAG_CODE: return true;
        case HTML_TAG_DD: return true;
        case HTML_TAG_DIV: return true;
        case HTML_TAG_DL: return true;
        case HTML_TAG_DT: return true;
        case HTML_TAG_EM: return true;
        case HTML_TAG_EMBED: return true;
        case HTML_TAG_FONT: {
            const TokenAttributes *attrs = &start_tag->attributes;
            for (size_t i = 0; i < attrs->count; i++) {
                const TokenizerString name = attrs->items[i].name;
                if (html_name_equals(name, "color") || html_name_equals(name, "size") || html_name_equals(name, "face")) {
                    return true;
                }
            }
            return false;
        }
        /*case HTML_TAG_H1: return true;
        case HTML_TAG_H2: return true;
        case HTML_TAG_H3: return true;
        case HTML_TAG_H4: return true;
        case HTML_TAG_H5: return true;
        case HTML_TAG_H6: return true;*/
        case HTML_TAG_HEAD: return true;
        case HTML_TAG_HR: return true;
        case HTML_TAG_I: return true;
        case HTML_TAG_IMG: return true;
        case HTML_TAG_LI: return true;
        case HTML_TAG_LISTING: return true;
        case HTML_TAG_MENU: return true;
        case HTML_TAG_META: return true;
        case HTML_TAG_NOBR: return true;
        case HTML_TAG_OL: return true;
        case HTML_TAG_P: return true;
        case HTML_TAG_PRE: return true;
        case HTML_TAG_RUBY: return true;
        case HTML_TAG_S: return true;
        case HTML_TAG_SMALL: return true;
        case HTML_TAG_SPAN: return true;
        case HTML_TAG_STRONG: return true;
        case HTML_TAG_STRIKE: return true;
        case HTML_TAG_SUB: return true;
        case HTML_TAG_SUP: return true;
        case HTML_TAG_TABLE: return true;
        case HTML_TAG_TT: return true;
        case HTML_TAG_U: return true;
        case HTML_TAG_UL: return true;
        case HTML_TAG_VAR: return true;
        default: {
            const TokenizerString name = start_tag->name;
            return name.length == 2 && ((name.data[0] | 0x20) == 'h') && (name.data[1] >= '1' && name.data[1] <= '6');
        }
    }
}

static bool foreign_is_integration_point(Namespace ns, HtmlTagType type, const TokenizerString name, const TokenAttributes *attrs) {
    switch (ns) {
        case NS_MATHML:
            switch (type) {
                case HTML_TAG_MI:
                case HTML_TAG_MO:
                case HTML_TAG_MN:
                case HTML_TAG_MS:
                case HTML_TAG_MTEXT:
                    return true;

                default: {
                    if (attrs && html_name_equals(name, "annotation-xml")) {
                        for (size_t i = 0; i < attrs->count; i++) {
                            const Attribute *attr = &attrs->items[i];
                            if (html_name_equals(attr->name, "encoding") && (html_name_equals(attr->value, "text/html") || html_name_equals(attr->value, "application/xhtml+xml"))) {
                                return true;
                            }
                        }
                    }
                    return false;
                }
            }

        case NS_SVG:
            return type == HTML_TAG_DESC || type == HTML_TAG_TITLE || html_name_equals(name, "foreignobject");

        case NS_HTML:
            return false;
    }
}

static void handle_start_tag_token(ParserFeedbackState *state, TokenStartTag *tag) {
    HtmlTagType type = tag->type;

    if (type == HTML_TAG_SVG || type == HTML_TAG_MATH)
        enter_ns(state, (Namespace) type);

    Namespace ns = get_current_ns(state);

    if (is_foreign_ns(ns)) {
        if (foreign_causes_exit(tag)) {
            leave_ns(state);
            return;
        }

        if (!tag->self_closing && foreign_is_integration_point(ns, tag->type, tag->name, &tag->attributes)) {
            enter_ns(state, NS_HTML);
        }
    } else {
        switch (type) {
            case HTML_TAG_PRE:
            case HTML_TAG_TEXTAREA:
            case HTML_TAG_LISTING:
                state->skip_next_newline = true;
                break;

            case HTML_TAG_IMAGE:
                tag->type = HTML_TAG_IMG;
                break;

            default:
                break;
        }

        ensure_tokenizer_mode(state->tokenizer, type);
    }
}

static void handle_end_tag_token(ParserFeedbackState *state, const TokenEndTag *tag) {
    if (!is_in_foreign_content(state)) {
        Namespace prev_ns = state->ns_stack[state->ns_depth - 2];

        if (foreign_is_integration_point(prev_ns, tag->type, tag->name, NULL)) {
            leave_ns(state);
        }
    } else {
        Namespace ns = get_current_ns(state);
        HtmlTagType type = tag->type;

        if (type == ns) {
            leave_ns(state);
        }
    }
}

static void handle_token(Token *token, void *extra) {
    ParserFeedbackState *state = extra;
    switch (token->type) {
        case token_start_tag:
            handle_start_tag_token(state, &token->start_tag);
            break;

        case token_end_tag:
            handle_end_tag_token(state, &token->end_tag);
            break;

        default:
            break;
    }
    state->wrapped_handler(token, state->wrapped_extra);
}

void parser_feedback_inject(ParserFeedbackState *state, TokenizerState *tokenizer) {
    state->tokenizer = tokenizer;
    state->ns_depth = 0;
    state->skip_next_newline = false;
    state->wrapped_extra = tokenizer->extra;
    tokenizer->extra = state;
    state->wrapped_handler = tokenizer->emit_token;
    tokenizer->emit_token = handle_token;
    enter_ns(state, NS_HTML);
}