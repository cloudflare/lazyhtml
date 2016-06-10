#include <assert.h>
#include <strings.h>
#include "tokenizer.h"

%%{
    machine html;

    access state->;

    include 'c/actions.rl';
    include 'syntax/index.rl';

    write data nofinal noprefix;
}%%

const int html_state_error = error;
const int html_state_Data = en_Data;
const int html_state_RCData = en_RCData;
const int html_state_RawText = en_RawText;
const int html_state_PlainText = en_PlainText;
const int html_state_ScriptData = en_ScriptData;

#define get_token(state, wanted_type) (assert(state->token.type == token_##wanted_type), &state->token.wanted_type)

#define create_token(state, wanted_type) (state->token.type = token_##wanted_type, &state->token.wanted_type)

inline __attribute__((always_inline)) static void set_string(TokenizerString *dest, const char *begin, const char *end) {
    assert(end >= begin);
    dest->length = (size_t) (end - begin);
    dest->data = begin;
}

inline __attribute__((always_inline)) static void reset_string(TokenizerString *dest) {
    dest->length = 0;
}

inline __attribute__((always_inline)) static void set_opt_string(TokenizerOptionalString *dest, const char *begin, const char *end) {
    dest->has_value = true;
    set_string(&dest->value, begin, end);
}

inline __attribute__((always_inline)) static void reset_opt_string(TokenizerOptionalString *dest) {
    dest->has_value = false;
}

inline __attribute__((always_inline)) static void token_init_character(TokenizerState *state, TokenCharacterKind kind) {
    TokenCharacter *character = create_token(state, character);
    character->kind = kind;
    reset_string(&character->value);
}

inline __attribute__((always_inline, const, warn_unused_result)) static HtmlTagType get_tag_type(const TokenizerString name) {
  if (name.length > 12) {
      return 0;
  }

  uint64_t code = 0;

  const char *data = name.data;
  const char *const max = data + name.length;

  for (; data < max; data++) {
      char c = *data;

      if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')) {
	      code = (code << 5) | (c & 31);
      } else {
        return 0;
      }
  }

  return code;
}

bool html_name_equals(const TokenizerString actual, const char *expected) {
    size_t len = actual.length;
    const char *data = actual.data;

    for (size_t i = 0; i < len; i++) {
        char c = data[i];
        char e = expected[i];

        if (c >= 'A' && c <= 'Z') {
            c |= 0x20;
        }

        if (e == 0 || c != e) {
            return false;
        }
    }

    return expected[len] == 0;
}

void html_tokenizer_init(TokenizerState *state, const TokenizerOpts *options) {
    %%write init nocs;
    state->allow_cdata = options->allow_cdata;
    state->emit_token = options->on_token;
    state->last_start_tag_name = options->last_start_tag_name;
    state->quote = 0;
    state->attribute = 0;
    state->start_slice = 0;
    state->mark = 0;
    state->appropriate_end_tag_offset = 0;
    state->buffer = state->buffer_pos = options->buffer;
    state->buffer_end = options->buffer + options->buffer_size;
    state->token.type = token_none;
    state->token.raw.data = state->buffer;
    state->extra = options->extra;
    state->cs = options->initial_state;
}

int html_tokenizer_feed(TokenizerState *state, const TokenizerString *chunk) {
    const char *p = state->buffer_pos;

    if (chunk != NULL) {
        char *new_buffer_pos = state->buffer_pos + chunk->length;
        assert(new_buffer_pos <= state->buffer_end);
        memcpy(state->buffer_pos, chunk->data, chunk->length);
        state->buffer_pos = new_buffer_pos;
    }

    const char *const pe = state->buffer_pos;
    const char *const eof = chunk == NULL ? pe : 0;

    %%write exec;

    {
        Token *const token = &state->token;

        if (token->type == token_character) {
            const char *middle = state->mark != NULL ? state->mark : p;
            set_string(&token->character.value, state->start_slice, middle);
            token->raw.length = (size_t) (middle - token->raw.data);
            if (token->raw.length) {
                state->emit_token(token, state->extra);
                token->type = token_character; // restore just in case
            }
            token->raw.data = state->start_slice = middle;
        }

        size_t shift = (size_t) (token->raw.data - state->buffer);

        if (shift != 0) {
            switch (token->type) {
                case token_character: {
                    break;
                }

                case token_comment: {
                    token->comment.value.data -= shift;
                    break;
                }

                case token_doc_type: {
                    token->doc_type.name.value.data -= shift;
                    token->doc_type.public_id.value.data -= shift;
                    token->doc_type.system_id.value.data -= shift;
                    break;
                }

                case token_end_tag: {
                    token->end_tag.name.data -= shift;
                    break;
                }

                case token_start_tag: {
                    token->start_tag.name.data -= shift;
                    TokenAttributes *attrs = &token->start_tag.attributes;
                    for (size_t i = 0; i < attrs->count; i++) {
                        Attribute *attr = &attrs->items[i];
                        attr->name.data -= shift;
                        attr->value.data -= shift;
                    }
                    break;
                }

                case token_none: {
                    break;
                }
            }

            memmove(state->buffer, token->raw.data, pe - token->raw.data);
            token->raw.data = state->buffer;
            state->buffer_pos -= shift;
            state->start_slice -= shift;

            if (state->mark != NULL) {
                state->mark -= shift;
            }
        }
    }

    return state->cs;
}
