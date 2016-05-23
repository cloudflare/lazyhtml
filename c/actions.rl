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
        assert(state->token.type == token_end_tag);
        state->token.end_tag.name = state->last_start_tag_name;
    }

    action StartSlice {
        state->start_slice = p;
    }

    action MarkPosition {
        state->mark = p;
    }

    action UnmarkPosition {
        state->mark = NULL;
    }

    action AdvanceMarkedPosition {
        state->mark++;
    }

    action EmitToken {
        Token* token = &state->token;
        token->raw.length = p - token->raw.data + 1;
        state->emit_token(token);
        token->type = token_none;
        token->raw.data = p + 1;
        token->raw.length = 0;
    }

    action EndText {
        assert(state->token.type == token_character);
        set_string(&state->token.character.value, state->start_slice, state->mark != NULL ? state->mark : p);
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
        state->token.type = token_start_tag;
        reset_string(&state->token.start_tag.name);
        state->token.start_tag.self_closing = false;
        state->token.start_tag.attributes.count = 0;
    }

    action SetStartTagName {
        assert(state->token.type == token_start_tag);
        set_string(&state->token.start_tag.name, state->start_slice, p);
    }

    action SetEndTagName {
        assert(state->token.type == token_end_tag);
        set_string(&state->token.end_tag.name, state->start_slice, p);
    }

    action SetLastStartTagName {
        assert(state->token.type == token_start_tag);
        state->last_start_tag_name = state->token.start_tag.name;
    }

    action SetSelfClosingFlag {
        assert(state->token.type == token_start_tag);
        state->token.start_tag.self_closing = true;
    }

    action EmitComment() {
        state->token.type = token_comment;
        set_string(&state->token.comment.value, state->start_slice, state->mark);
        $EmitToken
        $UnmarkPosition
    }

    action CreateEndTagToken {
        state->token.type = token_end_tag;
        reset_string(&state->token.end_tag.name);
    }

    action CreateAttribute {
        assert(state->token.type == token_start_tag);
        assert(state->token.start_tag.attributes.count < MAX_ATTR_COUNT);
        state->attribute = &state->token.start_tag.attributes.items[state->token.start_tag.attributes.count];
        reset_string(&state->attribute->name);
        reset_string(&state->attribute->value);
    }

    action SetAttributeValue {
        assert(state->token.type == token_start_tag);
        set_string(&state->attribute->value, state->start_slice, p);
    }

    action AppendAttribute {
        assert(state->token.type == token_start_tag);
        assert(&state->token.start_tag.attributes.items[state->token.start_tag.attributes.count] == state->attribute);
        set_string(&state->attribute->name, state->start_slice, p);
        state->token.start_tag.attributes.count++;
    }

    action IsCDataAllowed { state->allow_cdata }

    action CreateDocType {
        state->token.type = token_doc_type;
        state->token.doc_type.name.has_value = false;
        state->token.doc_type.public_id.has_value = false;
        state->token.doc_type.system_id.has_value = false;
        state->token.doc_type.force_quirks = false;
    }

    action SetDocTypeName {
        assert(state->token.type == token_doc_type);
        state->token.doc_type.name.has_value = true;
        set_string(&state->token.doc_type.name.value, state->start_slice, p);
    }

    action SetForceQuirksFlag {
        state->token.doc_type.force_quirks = true;
    }

    action SetDocTypePublicIdentifier {
        assert(state->token.type == token_doc_type);
        state->token.doc_type.public_id.has_value = true;
        set_string(&state->token.doc_type.public_id.value, state->start_slice, p);
    }

    action SetDocTypeSystemIdentifier {
        assert(state->token.type == token_doc_type);
        state->token.doc_type.system_id.has_value = true;
        set_string(&state->token.doc_type.system_id.value, state->start_slice, p);
    }
}%%
