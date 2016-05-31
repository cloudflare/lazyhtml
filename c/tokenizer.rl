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

static void set_string(TokenizerString *dest, const char *start, const char *end) {
    assert(end >= start);
    dest->length = end - start;
    dest->data = start;
}

static void reset_string(TokenizerString *dest) {
    dest->length = 0;
}

static void set_opt_string(TokenizerOptionalString *dest, const char *start, const char *end) {
    dest->has_value = true;
    set_string(&dest->value, start, end);
}

static void reset_opt_string(TokenizerOptionalString *dest) {
    dest->has_value = false;
}

static void token_init_character(TokenizerState *state, TokenCharacterKind kind) {
    TokenCharacter *character = create_token(state, character);
    character->kind = kind;
    reset_string(&character->value);
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
    state->token.extra = options->extra;
    state->token.raw.data = state->buffer;
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

    const int shift = state->token.raw.data - state->buffer;

    if (shift != 0) {
        memmove(state->buffer, state->token.raw.data, pe - state->token.raw.data);
        state->token.raw.data = state->buffer;
        state->buffer_pos -= shift;
        state->start_slice -= shift;

        if (state->mark != NULL) {
            state->mark -= shift;
        }

        switch (state->token.type) {
            case token_character: {
                state->token.character.value.data -= shift;
                break;
            }

            case token_comment: {
                state->token.comment.value.data -= shift;
                break;
            }

            case token_doc_type: {
                state->token.doc_type.name.value.data -= shift;
                state->token.doc_type.public_id.value.data -= shift;
                state->token.doc_type.system_id.value.data -= shift;
                break;
            }

            case token_end_tag: {
                state->token.end_tag.name.data -= shift;
                break;
            }

            case token_start_tag: {
                state->token.start_tag.name.data -= shift;
                TokenAttributes *attrs = &state->token.start_tag.attributes;
                for (int i = 0; i < attrs->count; i++) {
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
    }

    return state->cs;
}
