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

    _DecNumericEntity = digit @AppendSliceBeforeTheMark @StartNumericEntity @Reconsume digit* $AppendDecDigitToNumericEntity %AppendNumericEntity %eof(AppendNumericEntity) <: (
        ';' >1 any |
        any >0
    ) @StartSlice @Reconsume;

    _HexNumericEntity = xdigit @AppendSliceBeforeTheMark @StartNumericEntity @Reconsume (
        digit @AppendHexDigit09ToNumericEntity |
        /[a-f]/i @AppendHexDigitAFToNumericEntity
    )* %AppendNumericEntity %eof(AppendNumericEntity) <: (
        ';' >1 any |
        any >0
    ) @StartSlice @Reconsume;

    _NamedEntity = alnum+ >StartNamedEntity >UnmatchNamedEntity $FeedNamedEntity <: (
        ';' >1 @FeedNamedEntity @AppendNamedEntity |
        any >0 @AppendNamedEntity @Reconsume
    ) @eof(AppendNamedEntity) @eof(AppendSlice);

    _NumericEntity = '#' (
        (
            /x/i (
                _HexNumericEntity >1 |
                any >0 @Reconsume
            ) >eof(AppendSlice) |
            _DecNumericEntity
        ) >1 |
        any >0 @Reconsume
    ) >eof(AppendSlice);

    # This is meant to be used as part of a slice-chained string.
    # It will try hard not to break the current slice by using MarkPosition
    # and will break it when only absolutely necessary (real entity detected,
    # so old slice needs to be appended, then character reference added and
    # new slice started after the match; this way, slice change is transparent for
    # the parent state machine and it can continue parsing its own text)
    _Entity = '&' @MarkPosition (
        (
            _NamedEntity |
            _NumericEntity
        ) >1 |
        any >0 @Reconsume
    ) >eof(AppendSlice);

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
