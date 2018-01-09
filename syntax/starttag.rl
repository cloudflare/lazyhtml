%%{
    machine html;

    _StartTagEnd = (
        TagNameSpace @To_BeforeAttributeName |
        '/' @To_SelfClosingTag |
        '>' @SetLastStartTagName @Next_Data @EmitToken
    );

    _AttributeNameChars = (
        ('"' | "'" | '<') >1 @Err_UnexpectedCharacterInAttributeName |
        any >0
    );

    StartTagName := (any* %SetStartTagName :> _StartTagEnd) @eof(Err_EofInTag);

    BeforeAttributeName := TagNameSpace* <: (
        ('/' | '>') >1 @Reconsume @To_AfterAttributeName |
        '=' >1 @Err_UnexpectedEqualsSignBeforeAttributeName when CanCreateAttribute @StartSlice @To_AttributeName |
        _AttributeNameChars >0 when CanCreateAttribute @StartSlice @To_AttributeName
    ) @eof(Err_EofInTag);

    AttributeName := _AttributeNameChars* %AppendAttribute :> (
        TagNameEnd @Reconsume @To_AfterAttributeName |
        '=' @To_BeforeAttributeValue
    ) @eof(Err_EofInTag);

    AfterAttributeName := TagNameSpace* <: (
        (
            _StartTagEnd |
            '=' @To_BeforeAttributeValue
        ) >1 |
        _AttributeNameChars >0 when CanCreateAttribute @StartSlice @To_AttributeName
    ) @eof(Err_EofInTag);

    BeforeAttributeValue := TagNameSpace* <: (
        _StartQuote >1 @To_AttributeValueQuoted |
        '>' >1 @Err_MissingAttributeValue @Reconsume @To_AttributeValueUnquoted |
        any >0 @Reconsume @To_AttributeValueUnquoted
    ) @eof(Err_EofInTag);

    _AttrValueCharsQuoted = (any* >StartSlice %SetAttributeValue)?;

    AttributeValueQuoted := (_AttrValueCharsQuoted :> _EndQuote @To_AfterAttributeValueQuoted) @eof(Err_EofInTag);

    AfterAttributeValueQuoted := (
        _StartTagEnd >1 |
        '=' >1  @Err_MissingWhitespaceBetweenAttributes @Err_UnexpectedEqualsSignBeforeAttributeName when CanCreateAttribute @StartSlice @To_AttributeName |
        _AttributeNameChars >0 @Err_MissingWhitespaceBetweenAttributes when CanCreateAttribute @StartSlice @To_AttributeName
    ) @eof(Err_EofInTag);

    _AttrValueCharsUnquoted = ((
        ('"' | "'" | '<' | '=' | '`') >1 @Err_UnexpectedCharacterInUnquotedAttributeValue |
        any >0
    )* >StartSlice %SetAttributeValue)?;

    AttributeValueUnquoted := (_AttrValueCharsUnquoted :> ((TagNameSpace | '>') & _StartTagEnd)) @eof(Err_EofInTag);

    SelfClosingTag := (
        '>' >1 @SetSelfClosingFlag @SetLastStartTagName @Next_Data @EmitToken |
        any >0 @Err_UnexpectedSolidusInTag @Reconsume @To_BeforeAttributeName
    ) @eof(Err_EofInTag);
}%%
