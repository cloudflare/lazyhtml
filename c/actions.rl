%%{
    machine html;

    action SaveQuote {
        state->quote = fc;
    }

    action IsMatchingQuote { fc == state->quote }

    action StartData {
        token_init_character(state, LHTML_TOKEN_CHARACTER_DATA);
    }

    action StartRCData {
        token_init_character(state, LHTML_TOKEN_CHARACTER_RCDATA);
    }

    action StartCData {
        token_init_character(state, LHTML_TOKEN_CHARACTER_CDATA);
    }

    action StartSafe {
        token_init_character(state, LHTML_TOKEN_CHARACTER_SAFE);
    }

    action StartAppropriateEndTag {
        state->appropriate_end_tag_offset = state->last_start_tag_name_buf;
    }

    action IsAppropriateEndTagFed { state->appropriate_end_tag_offset == state->last_start_tag_name_end }

    action FeedAppropriateEndTag() { !($IsAppropriateEndTagFed) && *(state->appropriate_end_tag_offset++) == (fc | 0x20) }

    action SetAppropriateEndTagName {
        lhtml_string_t *end_tag_name = &GET_TOKEN(END_TAG)->name;
        end_tag_name->data = state->last_start_tag_name_buf;
        end_tag_name->length = (size_t) (state->last_start_tag_name_end - state->last_start_tag_name_buf);
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
        lhtml_token_t* token = &state->token;
        bool isnt_eof = p != eof;
        token->raw.length = ((size_t) (p - token->raw.data)) + isnt_eof;
        if (token->raw.length) {
            lhtml_emit(token, &state->base_handler);
        }
        token->type = LHTML_TOKEN_UNKNOWN;
        token->raw.data = p + isnt_eof;
        token->raw.length = 0;
    }

    action EndText {
        set_string(&GET_TOKEN(CHARACTER)->value, state->start_slice, state->mark != NULL ? state->mark : p);
    }

    action AsRawSlice {
        token_init_character(state, LHTML_TOKEN_CHARACTER_RAW);
    }

    action EmitSlice() {
        $EndText
        p--;
        $EmitToken
        p++;
    }

    action CreateStartTagToken {
        lhtml_token_starttag_t *start_tag = CREATE_TOKEN(START_TAG);
        reset_string(&start_tag->name);
        start_tag->self_closing = false;
        start_tag->attributes.count = 0;
    }

    action SetStartTagName {
        lhtml_token_starttag_t *start_tag = GET_TOKEN(START_TAG);
        set_string(&start_tag->name, state->start_slice, p);
        start_tag->type = get_tag_type(start_tag->name);
    }

    action SetEndTagName {
        lhtml_token_endtag_t *end_tag = GET_TOKEN(END_TAG);
        set_string(&end_tag->name, state->start_slice, p);
        end_tag->type = get_tag_type(end_tag->name);
    }

    action SetLastStartTagName {
        set_last_start_tag_name(state, GET_TOKEN(START_TAG)->name);
    }

    action SetSelfClosingFlag {
        GET_TOKEN(START_TAG)->self_closing = true;
    }

    action EmitComment() {
        set_string(&CREATE_TOKEN(COMMENT)->value, state->start_slice, state->mark);
        $EmitToken
        $UnmarkPosition
    }

    action CreateEndTagToken {
        reset_string(&CREATE_TOKEN(END_TAG)->name);
    }

    action CreateAttribute {
        lhtml_attributes_t *attributes = &GET_TOKEN(START_TAG)->attributes;
        assert(attributes->count < MAX_ATTR_COUNT);
        lhtml_attribute_t *attr = state->attribute = &attributes->items[attributes->count];
        reset_string(&attr->name);
        reset_string(&attr->value);
    }

    action SetAttributeValue {
        assert(state->token.type == LHTML_TOKEN_START_TAG);
        lhtml_attribute_t *attr = state->attribute;
        set_string(&attr->value, state->start_slice, p);
        attr->raw.length = (size_t) (p + (*p == '"' || *p == '\'') - attr->name.data);
    }

    action AppendAttribute {
        lhtml_attributes_t *attributes = &GET_TOKEN(START_TAG)->attributes;
        lhtml_attribute_t *attr = state->attribute;
        assert(&attributes->items[attributes->count] == attr);
        set_string(&attr->name, state->start_slice, p);
        attr->raw = attr->name;
        attributes->count++;
    }

    action IsCDataAllowed { state->allow_cdata }

    action CreateDocType {
        lhtml_token_doctype_t *doc_type = CREATE_TOKEN(DOCTYPE);
        reset_opt_string(&doc_type->name);
        reset_opt_string(&doc_type->public_id);
        reset_opt_string(&doc_type->system_id);
        doc_type->force_quirks = false;
    }

    action SetDocTypeName {
        set_opt_string(&GET_TOKEN(DOCTYPE)->name, state->start_slice, p);
    }

    action SetForceQuirksFlag {
        GET_TOKEN(DOCTYPE)->force_quirks = true;
    }

    action SetDocTypePublicIdentifier {
        set_opt_string(&GET_TOKEN(DOCTYPE)->public_id, state->start_slice, p);
    }

    action SetDocTypeSystemIdentifier {
        set_opt_string(&GET_TOKEN(DOCTYPE)->system_id, state->start_slice, p);
    }
}%%
