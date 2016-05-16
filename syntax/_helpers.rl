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

    _NUL = 0 @AppendReplacementCharacter;

    _SafeText = (any+ >StartSafe >StartSlice %EmitSlice %eof(EmitSlice))?;

    _String = (any+ >StartSlice %AppendSlice %eof(AppendSlice))? >StartString >eof(StartString);

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

    _SpecialEndTag = (
        '/' >StartAppropriateEndTag
        (alpha when FeedAppropriateEndTag)*
        _EndTagEnd when IsAppropriateEndTagFed >CreateEndTagToken >SetAppropriateEndTagName
    ) @err(AppendSlice) @err(EmitString) @err(Reconsume);
}%%
