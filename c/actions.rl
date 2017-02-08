%%{
    machine html;

    action SaveQuote {
        state->quote = fc;
    }

    action IsMatchingQuote { fc == state->quote }

    action StartData {
        token_init_character(token, LHTML_TOKEN_CHARACTER_DATA);
    }

    action StartRCData {
        token_init_character(token, LHTML_TOKEN_CHARACTER_RCDATA);
    }

    action StartCData {
        token_init_character(token, LHTML_TOKEN_CHARACTER_CDATA);
    }

    action StartSafe {
        token_init_character(token, LHTML_TOKEN_CHARACTER_SAFE);
    }

    action StartAppropriateEndTag {
        state->special_end_tag_type = 0;
    }

    action FeedAppropriateEndTag { tag_type_append_char(&state->special_end_tag_type, fc) }

    action IsAppropriateEndTagFed { state->special_end_tag_type == state->last_start_tag_type }

    action SetAppropriateEndTagName {
        lhtml_token_endtag_t *end_tag = GET_TOKEN(END_TAG);
        set_string(&GET_TOKEN(END_TAG)->name, state->start_slice + 2, p);
        end_tag->type = state->special_end_tag_type;
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
        emit_token(state, p + (p != eof));
    }

    action EndText {
        end_text(state, p);
    }

    action AsRawSlice {
        token_init_character(token, LHTML_TOKEN_CHARACTER_RAW);
    }

    action EmitSlice {
        end_text(state, p);
        emit_token(state, p);
    }

    action CreateStartTagToken {
        lhtml_token_starttag_t *start_tag = CREATE_TOKEN(START_TAG);
        reset_string(&start_tag->name);
        start_tag->self_closing = false;
        start_tag->attributes.buffer = state->attr_buffer;
        start_tag->attributes.length = 0;
    }

    action SetStartTagName {
        lhtml_token_starttag_t *start_tag = GET_TOKEN(START_TAG);
        set_string(&start_tag->name, state->start_slice, p);
        start_tag->type = lhtml_get_tag_type(start_tag->name);
    }

    action SetEndTagName {
        lhtml_token_endtag_t *end_tag = GET_TOKEN(END_TAG);
        set_string(&end_tag->name, state->start_slice, p);
        end_tag->type = lhtml_get_tag_type(end_tag->name);
    }

    action SetLastStartTagName {
        state->last_start_tag_type = GET_TOKEN(START_TAG)->type;
    }

    action SetSelfClosingFlag {
        GET_TOKEN(START_TAG)->self_closing = true;
    }

    action EndComment {
        set_string(&CREATE_TOKEN(COMMENT)->value, state->start_slice, state->mark);
    }

    action CreateEndTagToken {
        reset_string(&CREATE_TOKEN(END_TAG)->name);
    }

    action CanCreateAttribute { can_create_attr(&GET_TOKEN(START_TAG)->attributes) }

    action CreateAttribute {
        lhtml_attributes_t *attributes = &GET_TOKEN(START_TAG)->attributes;
        lhtml_attribute_t *attr = state->attribute = &attributes->data[attributes->length];
        reset_string(&attr->name);
        reset_string(&attr->value);
    }

    action SetAttributeValue {
        lhtml_attribute_t *attr = state->attribute;
        set_string(&attr->value, state->start_slice, p);
        attr->raw.value.length = (size_t) (p + (*p == '"' || *p == '\'') - attr->name.data);
    }

    action AppendAttribute {
        lhtml_attributes_t *attributes = &GET_TOKEN(START_TAG)->attributes;
        lhtml_attribute_t *attr = state->attribute;
        assert(&attributes->data[attributes->length] == attr);
        set_string(&attr->name, state->start_slice, p);
        attr->raw.has_value = true;
        attr->raw.value = attr->name;
        attributes->length++;
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
