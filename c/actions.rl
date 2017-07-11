%%{
    machine html;

    action SaveQuote {
        state->quote = fc;
    }

    action IsMatchingQuote { fc == state->quote }

    action StartData {
        CREATE_TOKEN(CHARACTER, {
            .kind = LHTML_TOKEN_CHARACTER_DATA
        });
    }

    action StartRCData {
        CREATE_TOKEN(CHARACTER, {
            .kind = LHTML_TOKEN_CHARACTER_RCDATA
        });
    }

    action StartCData {
        CREATE_TOKEN(CHARACTER, {
            .kind = LHTML_TOKEN_CHARACTER_CDATA
        });
    }

    action StartSafe {
        CREATE_TOKEN(CHARACTER, {
            .kind = LHTML_TOKEN_CHARACTER_SAFE
        });
    }

    action StartAppropriateEndTag {
        state->special_end_tag_type = 0;
    }

    action FeedAppropriateEndTag { tag_type_append_char(&state->special_end_tag_type, fc) }

    action IsAppropriateEndTagFed { state->special_end_tag_type == state->last_start_tag_type }

    action SetAppropriateEndTagName {
        lhtml_token_endtag_t *end_tag = GET_TOKEN(END_TAG);
        end_tag->name = range_string(state->start_slice + 2, p);
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
        CREATE_TOKEN(CHARACTER, {
            .kind = LHTML_TOKEN_CHARACTER_RAW
        });
    }

    action EmitSlice {
        end_text(state, p);
        emit_token(state, p);
    }

    action CreateStartTagToken {
        CREATE_TOKEN(START_TAG, {
            .attributes = (lhtml_attributes_t) {
                .buffer = state->attr_buffer
            }
        });
    }

    action SetStartTagName {
        lhtml_token_starttag_t *start_tag = GET_TOKEN(START_TAG);
        start_tag->name = range_string(state->start_slice, p);
        start_tag->type = lhtml_get_tag_type(start_tag->name);
    }

    action SetEndTagName {
        lhtml_token_endtag_t *end_tag = GET_TOKEN(END_TAG);
        end_tag->name = range_string(state->start_slice, p);
        end_tag->type = lhtml_get_tag_type(end_tag->name);
    }

    action SetLastStartTagName {
        state->last_start_tag_type = GET_TOKEN(START_TAG)->type;
    }

    action SetSelfClosingFlag {
        GET_TOKEN(START_TAG)->self_closing = true;
    }

    action EndComment {
        CREATE_TOKEN(COMMENT, {
            .value = range_string(state->start_slice, state->mark)
        });
    }

    action CreateEndTagToken {
        CREATE_TOKEN(END_TAG, {});
    }

    action CanCreateAttribute { can_create_attr(&GET_TOKEN(START_TAG)->attributes) }

    action SetAttributeValue {
        lhtml_attributes_t *attributes = &GET_TOKEN(START_TAG)->attributes;
        lhtml_attribute_t *attr = &attributes->data[attributes->length - 1];
        attr->value = range_string(state->start_slice, p);
        attr->raw.value.length = (size_t) (p + (*p == '"' || *p == '\'') - attr->name.data);
    }

    action AppendAttribute {
        lhtml_attributes_t *attributes = &GET_TOKEN(START_TAG)->attributes;
        lhtml_string_t name = range_string(state->start_slice, p);
        attributes->data[attributes->length++] = (lhtml_attribute_t) {
            .name = name,
            .raw = (lhtml_opt_string_t) {
                .has_value = true,
                .value = name
            }
        };
    }

    action IsCDataAllowed { state->allow_cdata }

    action CreateDocType {
        CREATE_TOKEN(DOCTYPE, {});
    }

    action SetDocTypeName {
        GET_TOKEN(DOCTYPE)->name = opt_range_string(state->start_slice, p);
    }

    action SetForceQuirksFlag {
        GET_TOKEN(DOCTYPE)->force_quirks = true;
    }

    action SetDocTypePublicIdentifier {
        GET_TOKEN(DOCTYPE)->public_id = opt_range_string(state->start_slice, p);
    }

    action SetDocTypeSystemIdentifier {
        GET_TOKEN(DOCTYPE)->system_id = opt_range_string(state->start_slice, p);
    }
}%%
