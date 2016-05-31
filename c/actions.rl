%%{
    machine html;

    action SaveQuote {
        state->quote = fc;
    }

    action IsMatchingQuote { fc == state->quote }

    action StartData {
        token_init_character(state, token_character_data);
    }

    action StartRCData {
        token_init_character(state, token_character_rcdata);
    }

    action StartCData {
        token_init_character(state, token_character_cdata);
    }

    action StartSafe {
        token_init_character(state, token_character_safe);
    }

    action StartAppropriateEndTag {
        state->appropriate_end_tag_offset = state->last_start_tag_name.data;
    }

    action IsAppropriateEndTagFed { state->appropriate_end_tag_offset == state->last_start_tag_name.data + state->last_start_tag_name.length }

    action FeedAppropriateEndTag() { !($IsAppropriateEndTagFed) && *(state->appropriate_end_tag_offset++) == (fc | 0x20) }

    action SetAppropriateEndTagName {
        get_token(state, end_tag)->name = state->last_start_tag_name;
    }

    action StartSlice {
        state->start_slice = p;
    }

    action MarkPosition {
        state->mark = p;
    }

    action UnmarkPosition {
        state->mark = 0;
    }

    action AdvanceMarkedPosition {
        state->mark++;
    }

    action EmitToken {
        Token* token = &state->token;
        bool isnt_eof = p != eof;
        token->raw.length = p - token->raw.data + isnt_eof;
        state->emit_token(token);
        token->type = token_none;
        token->raw.data = p + isnt_eof;
        token->raw.length = 0;
    }

    action EndText {
        set_string(&get_token(state, character)->value, state->start_slice, state->mark != 0 ? state->mark : p);
    }

    action AsRawSlice {
        token_init_character(state, token_character_raw);
    }

    action EmitSlice() {
        $EndText
        p--;
        $EmitToken
        p++;
    }

    action CreateStartTagToken {
        TokenStartTag *start_tag = create_token(state, start_tag);
        reset_string(&start_tag->name);
        start_tag->self_closing = false;
        start_tag->attributes.count = 0;
    }

    action SetStartTagName {
        set_string(&get_token(state, start_tag)->name, state->start_slice, p);
    }

    action SetEndTagName {
        set_string(&get_token(state, end_tag)->name, state->start_slice, p);
    }

    action SetLastStartTagName {
        state->last_start_tag_name = get_token(state, start_tag)->name;
    }

    action SetSelfClosingFlag {
        get_token(state, start_tag)->self_closing = true;
    }

    action EmitComment() {
        set_string(&create_token(state, comment)->value, state->start_slice, state->mark);
        $EmitToken
        $UnmarkPosition
    }

    action CreateEndTagToken {
        reset_string(&create_token(state, end_tag)->name);
    }

    action CreateAttribute {
        TokenAttributes *attributes = &get_token(state, start_tag)->attributes;
        assert(attributes->count < sizeof(attributes->items) / sizeof(attributes->items[0]));
        Attribute *attr = state->attribute = &attributes->items[attributes->count];
        reset_string(&attr->name);
        reset_string(&attr->value);
    }

    action SetAttributeValue {
        assert(state->token.type == token_start_tag);
        set_string(&state->attribute->value, state->start_slice, p);
    }

    action AppendAttribute {
        TokenAttributes *attributes = &get_token(state, start_tag)->attributes;
        Attribute *attr = state->attribute;
        assert(&attributes->items[attributes->count] == attr);
        set_string(&attr->name, state->start_slice, p);
        attributes->count++;
    }

    action IsCDataAllowed { state->allow_cdata }

    action CreateDocType {
        TokenDocType *doc_type = create_token(state, doc_type);
        reset_opt_string(&doc_type->name);
        reset_opt_string(&doc_type->public_id);
        reset_opt_string(&doc_type->system_id);
        doc_type->force_quirks = false;
    }

    action SetDocTypeName {
        set_opt_string(&get_token(state, doc_type)->name, state->start_slice, p);
    }

    action SetForceQuirksFlag {
        get_token(state, doc_type)->force_quirks = true;
    }

    action SetDocTypePublicIdentifier {
        set_opt_string(&get_token(state, doc_type)->public_id, state->start_slice, p);
    }

    action SetDocTypeSystemIdentifier {
        set_opt_string(&get_token(state, doc_type)->system_id, state->start_slice, p);
    }
}%%
