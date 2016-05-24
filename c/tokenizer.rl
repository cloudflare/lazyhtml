#include <assert.h>
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
    state->token.type = token_none;
    reset_string(&state->token.raw);
    state->token.extra = options->extra;
    state->quote = 0;
    state->attribute = 0;
    state->start_slice = 0;
    state->mark = 0;
    state->appropriate_end_tag_offset = 0;
    state->buffer = options->buffer;
    state->cs = options->initial_state;
}

int html_tokenizer_feed(TokenizerState *state, const TokenizerString *chunk) {
    const char *const start = chunk != 0 ? chunk->data : 0;
    const char *p = start;
    const char *const pe = chunk != 0 ? start + chunk->length : 0;
    const char *const eof = 0;

    %%write exec;

    return state->cs;
}
