%%{
    machine html;

    _StartTagEnd = (
        TagNameSpace @To_BeforeAttributeName |
        '/' @To_SelfClosingTag |
        '>' @EmitStartTagToken @To_Data
    );

    _AttrNamedEntity = alnum+ >StartNamedEntity $UnmatchNamedEntity $FeedNamedEntity <: (
        ';' @FeedNamedEntity @AppendNamedEntity |
        '=' |
        any >0 @AppendNamedEntity @Reconsume
    );

    _AttrEntity = '&' @MarkPosition (
        (
            _AttrNamedEntity |
            _NumericEntity
        ) >1 |
        any >0 @Reconsume
    ) >eof(AppendSlice);

    StartTagName := _Name %SetStartTagName :> _StartTagEnd;

    BeforeAttributeName := TagNameSpace* <: (
        ('/' | '>') >1 @Reconsume @To_AfterAttributeName |
        (
            '=' >1 @AppendEqualsCharacter |
            any >0 @Reconsume
        ) >CreateAttribute >StartString @To_AttributeName
    );

    AttributeName := _Name %AppendAttribute :> (
        TagNameEnd @Reconsume @To_AfterAttributeName |
        '=' @To_BeforeAttributeValue
    );

    AfterAttributeName := TagNameSpace* <: (
        (
            _StartTagEnd |
            '=' @To_BeforeAttributeValue
        ) >1 |
        any >0 @CreateAttribute @StartString @Reconsume @To_AttributeName
    );

    BeforeAttributeValue := TagNameSpace* <: (
        _StartQuote >1 @To_AttributeValueQuoted |
        any >0 @Reconsume @To_AttributeValueUnquoted
    );

    _AttrValue = ((
        _NUL |
        _CRLF $2 |
        (
            _AttrEntity |
            ^(0 | CR | '&')
        )+ $1 %0 >StartSlice %AppendSlice
    )+ %2 >StartString %SetAttributeValue)?;

    AttributeValueQuoted := _AttrValue :> _EndQuote @To_AfterAttributeValueQuoted;

    AttributeValueUnquoted := _AttrValue :> ((TagNameSpace | '>') & _StartTagEnd);

    AfterAttributeValueQuoted := (
        _StartTagEnd >1 |
        any >0 @Reconsume @To_BeforeAttributeName
    );

    SelfClosingTag := (
        '>' >1 @SetSelfClosingFlag @EmitStartTagToken @To_Data |
        any >0 @Reconsume @To_BeforeAttributeName
    );
}%%
