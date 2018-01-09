%%{
    machine html;

    action Err_AbruptClosingOfEmptyComment { parse_error(state, LHTML_ERR_ABRUPT_CLOSING_OF_EMPTY_COMMENT); }
    action Err_AbruptDoctypePublicIdentifier { parse_error(state, LHTML_ERR_ABRUPT_DOCTYPE_PUBLIC_IDENTIFIER); }
    action Err_AbruptDoctypeSystemIdentifier { parse_error(state, LHTML_ERR_ABRUPT_DOCTYPE_SYSTEM_IDENTIFIER); }
    action Err_CDataInHtmlContent { parse_error(state, LHTML_ERR_CDATA_IN_HTML_CONTENT); }
    action Err_EndTagWithAttributes { parse_error(state, LHTML_ERR_END_TAG_WITH_ATTRIBUTES); }
    action Err_EndTagWithTrailingSolidus { parse_error(state, LHTML_ERR_END_TAG_WITH_TRAILING_SOLIDUS); }
    action Err_EofBeforeTagName { parse_error(state, LHTML_ERR_EOF_BEFORE_TAG_NAME); }
    action Err_EofInCData { parse_error(state, LHTML_ERR_EOF_IN_CDATA); }
    action Err_EofInComment { parse_error(state, LHTML_ERR_EOF_IN_COMMENT); }
    action Err_EofInDoctype { parse_error(state, LHTML_ERR_EOF_IN_DOCTYPE); }
    action Err_EofInScriptHtmlCommentLikeText { parse_error(state, LHTML_ERR_EOF_IN_SCRIPT_HTML_COMMENT_LIKE_TEXT); }
    action Err_EofInTag { parse_error(state, LHTML_ERR_EOF_IN_TAG); }
    action Err_IncorrectlyClosedComment { parse_error(state, LHTML_ERR_INCORRECTLY_CLOSED_COMMENT); }
    action Err_IncorrectlyOpenedComment { parse_error(state, LHTML_ERR_INCORRECTLY_OPENED_COMMENT); }
    action Err_InvalidCharacterSequenceAfterDoctypeName { parse_error(state, LHTML_ERR_INVALID_CHARACTER_SEQUENCE_AFTER_DOCTYPE_NAME); }
    action Err_InvalidFirstCharacterOfTagName { parse_error(state, LHTML_ERR_INVALID_FIRST_CHARACTER_OF_TAG_NAME); }
    action Err_MissingAttributeValue { parse_error(state, LHTML_ERR_MISSING_ATTRIBUTE_VALUE); }
    action Err_MissingDoctypeName { parse_error(state, LHTML_ERR_MISSING_DOCTYPE_NAME); }
    action Err_MissingDoctypePublicIdentifier { parse_error(state, LHTML_ERR_MISSING_DOCTYPE_PUBLIC_IDENTIFIER); }
    action Err_MissingDoctypeSystemIdentifier { parse_error(state, LHTML_ERR_MISSING_DOCTYPE_SYSTEM_IDENTIFIER); }
    action Err_MissingEndTagName { parse_error(state, LHTML_ERR_MISSING_END_TAG_NAME); }
    action Err_MissingQuoteBeforeDoctypePublicIdentifier { parse_error(state, LHTML_ERR_MISSING_QUOTE_BEFORE_DOCTYPE_PUBLIC_IDENTIFIER); }
    action Err_MissingQuoteBeforeDoctypeSystemIdentifier { parse_error(state, LHTML_ERR_MISSING_QUOTE_BEFORE_DOCTYPE_SYSTEM_IDENTIFIER); }
    action Err_MissingSpaceAfterDoctypePublicKeyword { parse_error(state, LHTML_ERR_MISSING_SPACE_AFTER_DOCTYPE_PUBLIC_KEYWORD); }
    action Err_MissingSpaceAfterDoctypeSystemKeyword { parse_error(state, LHTML_ERR_MISSING_SPACE_AFTER_DOCTYPE_SYSTEM_KEYWORD); }
    action Err_MissingWhitespaceBeforeDoctypeName { parse_error (state, LHTML_ERR_MISSING_WHITESPACE_BEFORE_DOCTYPE_NAME); }
    action Err_MissingWhitespaceBetweenAttributes { parse_error(state, LHTML_ERR_MISSING_WHITESPACE_BETWEEN_ATTRIBUTES); }
    action Err_MissingWhitespaceBetweenDoctypePublicAndSystemIdentifiers { parse_error(state, LHTML_ERR_MISSING_WHITESPACE_BETWEEN_DOCTYPE_PUBLIC_AND_SYSTEM_IDENTIFIERS); }
    action Err_NestedComment { parse_error(state, LHTML_ERR_NESTED_COMMENT); }
    action Err_UnexpectedCharacterAfterDoctypeSystemIdentifier { parse_error(state, LHTML_ERR_UNEXPECTED_CHARACTER_AFTER_DOCTYPE_SYSTEM_IDENTIFIER); }
    action Err_UnexpectedCharacterInAttributeName { parse_error(state, LHTML_ERR_UNEXPECTED_CHARACTER_IN_ATTRIBUTE_NAME); }
    action Err_UnexpectedCharacterInUnquotedAttributeValue { parse_error(state, LHTML_ERR_UNEXPECTED_CHARACTER_IN_UNQUOTED_ATTRIBUTE_VALUE); }
    action Err_UnexpectedEqualsSignBeforeAttributeName { parse_error(state, LHTML_ERR_UNEXPECTED_EQUALS_SIGN_BEFORE_ATTRIBUTE_NAME); }
    action Err_UnexpectedQuestionMarkInsteadOfTagName { parse_error(state, LHTML_ERR_UNEXPECTED_QUESTION_MARK_INSTEAD_OF_TAG_NAME); }
    action Err_UnexpectedSolidusInTag { parse_error(state, LHTML_ERR_UNEXPECTED_SOLIDUS_IN_TAG); }
}%%