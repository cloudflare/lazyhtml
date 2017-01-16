%%{
    machine html;

    _StartTagEnd = (
        TagNameSpace @To_BeforeAttributeName |
        '/' @To_SelfClosingTag |
        '>' @SetLastStartTagName @Next_Data @EmitToken
    );

    StartTagName := any* %SetStartTagName :> _StartTagEnd;

    BeforeAttributeName := TagNameSpace* <: (
        ('/' | '>') >1 @Reconsume @To_AfterAttributeName |
        any >0 when CanCreateAttribute @CreateAttribute @StartSlice @To_AttributeName
    );

    AttributeName := any* %AppendAttribute :> (
        TagNameEnd @Reconsume @To_AfterAttributeName |
        '=' @To_BeforeAttributeValue
    );

    AfterAttributeName := TagNameSpace* <: (
        (
            _StartTagEnd |
            '=' @To_BeforeAttributeValue
        ) >1 |
        any >0 when CanCreateAttribute @CreateAttribute @StartSlice @To_AttributeName
    );

    BeforeAttributeValue := TagNameSpace* <: (
        _StartQuote >1 @To_AttributeValueQuoted |
        any >0 @Reconsume @To_AttributeValueUnquoted
    );

    _AttrValue = (any* >StartSlice %SetAttributeValue)?;

    AttributeValueQuoted := _AttrValue :> _EndQuote @To_BeforeAttributeName;

    AttributeValueUnquoted := _AttrValue :> ((TagNameSpace | '>') & _StartTagEnd);

    SelfClosingTag := (
        '>' >1 @SetSelfClosingFlag @SetLastStartTagName @Next_Data @EmitToken |
        any >0 @Reconsume @To_BeforeAttributeName
    );
}%%
