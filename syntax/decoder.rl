%%{
    machine html_decoder;

    CR = '\r';
    LF = '\n';

    _CRLF = CR @AppendLFCharacter LF?;

    _NUL = 0 @AppendReplacementCharacter;

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

    _AttrNamedEntity = alnum+ >StartNamedEntity $UnmatchNamedEntity $FeedNamedEntity <: (
        ';' @FeedNamedEntity @AppendNamedEntity |
        '=' |
        any >0 @AppendNamedEntity @Reconsume
    ) @eof(AppendNamedEntity) @eof(AppendSlice);

    _AttrEntity = '&' @MarkPosition (
        (
            _AttrNamedEntity |
            _NumericEntity
        ) >1 |
        any >0 @Reconsume
    ) >eof(AppendSlice);

    AttrValue := (
        _NUL |
        _CRLF $2 |
        (
            _AttrEntity |
            ^(0 | CR | '&')
        )+ $1 %0 >StartSlice %AppendSlice %eof(AppendSlice)
    )+;

    Data := (
        _CRLF $2 |
        (
            _Entity |
            ^('&' | CR)
        )+ $1 %0 >StartSlice %AppendSlice %eof(AppendSlice)
    )+;

    RCData := (
        _CRLF $2 |
        _NUL |
        (
            _Entity |
            ^('&' | 0 | CR)
        )+ $1 %0 >StartSlice %AppendSlice %eof(AppendSlice)
    )+;

    CData := (
        _CRLF $2 |
        ^CR+ $1 %0 >StartSlice %AppendSlice %eof(AppendSlice)
    )+;

    Comment := (
        _CRLF $2 |
        _NUL |
        ^(0 | CR)+ $1 %0 >StartSlice %AppendSlice %eof(AppendSlice)
    )+;
}%%
