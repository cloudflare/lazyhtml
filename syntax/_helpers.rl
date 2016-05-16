%%{
    machine html;

    TAB = '\t';
    CR = '\r';
    LF = '\n';
    FF = '\f';

    TagNameSpace = TAB | CR | LF | FF | ' ';

    TagNameEnd = TagNameSpace | '/' | '>';

    _Quote = ('"' | "'");

    _StartQuote = _Quote @SaveQuote;

    _EndQuote = _Quote when IsMatchingQuote;

    _CRLF = CR @AppendLFCharacter LF?;

    _NUL = 0 @AppendReplacementCharacter;

    _SafeStringChunk = (
        _NUL |
        _CRLF $2 |
        ^(0 | CR)+ $1 %0 >StartSlice %AppendSlice %eof(AppendSlice)
    )+ %2;

    _SafeText = (_SafeStringChunk >StartString %EmitString %eof(EmitString))? $1 %2;

    _SafeString = _SafeStringChunk? >StartString >eof(StartString);

    _Name = (
        upper @AppendLowerCasedCharacter |
        _NUL |
        ^(upper | 0)+ $1 %0 >StartSlice %AppendSlice %eof(AppendSlice)
    )* %2;

    _EndTagEnd = (
        TagNameSpace |
        '/' |
        '>'
    ) @Reconsume @To_EndTagNameContents;

    action FeedAppropriateEndTagWithLowerCased() { !($IsAppropriateEndTagFed) && ($GetNextAppropriateEndTagChar) === fc + 0x20 }
    action FeedAppropriateEndTag() { !($IsAppropriateEndTagFed) && ($GetNextAppropriateEndTagChar) === fc }

    _SpecialEndTag = (
        '/' >StartAppropriateEndTag
        (
            upper when FeedAppropriateEndTagWithLowerCased |
            lower when FeedAppropriateEndTag
        )*
        _EndTagEnd when IsAppropriateEndTagFed >CreateEndTagToken >SetAppropriateEndTagName
    ) @err(AppendSlice) @err(EmitString) @err(Reconsume);
}%%
