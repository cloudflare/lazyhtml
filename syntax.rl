%%{
    machine html;

    action Reconsume { fhold; }
    action To_CharacterReferenceInData { fgoto CharacterReferenceInData; }
    action To_TagOpen { fgoto TagOpen; }
    action To_Data { fgoto Data; }
    action To_CharacterReferenceInRCData { fgoto CharacterReferenceInRCData; }
    action To_RCDataLessThanSign { fgoto RCDataLessThanSign; }
    action To_RCData { fgoto RCData; }
    action To_RawTextLessThanSign { fgoto RawTextLessThanSign; }
    action To_RawText { fgoto RawText; }
    action To_ScriptDataLessThanSign { fgoto ScriptDataLessThanSign; }
    action To_ScriptData { fgoto ScriptData; }
    action To_MarkupDeclarationOpen { fgoto MarkupDeclarationOpen; }
    action To_EndTagOpen { fgoto EndTagOpen; }
    action To_StartTagName { fgoto StartTagName; }
    action To_EndTagName { fgoto EndTagName; }
    action To_EndTagNameContents { fgoto EndTagNameContents; }
    action To_BogusComment { fgoto BogusComment; }
    action To_BeforeAttributeName { fgoto BeforeAttributeName; }
    action To_SelfClosingTag { fgoto SelfClosingTag; }
    action To_ScriptDataEscapedDashDash { fgoto ScriptDataEscapedDashDash; }
    action To_ScriptDataEscapedDash { fgoto ScriptDataEscapedDash; }
    action To_ScriptDataEscapedLessThanSign { fgoto ScriptDataEscapedLessThanSign; }
    action To_ScriptDataEscaped { fgoto ScriptDataEscaped; }
    action To_ScriptDataDoubleEscaped { fgoto ScriptDataDoubleEscaped; }
    action To_ScriptDataDoubleEscapedDash { fgoto ScriptDataDoubleEscapedDash; }
    action To_ScriptDataDoubleEscapedLessThanSign { fgoto ScriptDataDoubleEscapedLessThanSign; }
    action To_ScriptDataDoubleEscapedDashDash { fgoto ScriptDataDoubleEscapedDashDash; }
    action To_AttributeName { fgoto AttributeName; }
    action To_AfterAttributeName { fgoto AfterAttributeName; }
    action To_BeforeAttributeValue { fgoto BeforeAttributeValue; }
    action To_AttributeValueQuoted { fgoto AttributeValueQuoted; }
    action To_AttributeValueUnquoted { fgoto AttributeValueUnquoted; }
    action To_AfterAttributeValueQuoted { fgoto AfterAttributeValueQuoted; }
    action To_CharacterReferenceInAttributeValue { fgoto CharacterReferenceInAttributeValue; }
    action To_CommentStart { fgoto CommentStart; }
    action To_DocType { fgoto DocType; }
    action To_CDataSection { fgoto CDataSection; }
    action To_CDataSectionEnd { fgoto CDataSectionEnd; }
    action To_CDataSectionEndRightBracket { fgoto CDataSectionEndRightBracket; }
    action To_Comment { fgoto Comment; }
    action To_BeforeDocTypeName { fgoto BeforeDocTypeName; }
    action To_DocTypeName { fgoto DocTypeName; }
    action To_AfterDocTypeName { fgoto AfterDocTypeName; }
    action To_BeforeDocTypePublicIdentifier { fgoto BeforeDocTypePublicIdentifier; }
    action To_DocTypePublicIdentifierQuoted { fgoto DocTypePublicIdentifierQuoted; }
    action To_BogusDocType { fgoto BogusDocType; }
    action To_BetweenDocTypePublicAndSystemIdentifiers { fgoto BetweenDocTypePublicAndSystemIdentifiers; }
    action To_DocTypeSystemIdentifierQuoted { fgoto DocTypeSystemIdentifierQuoted; }
    action To_BeforeDocTypeSystemIdentifier { fgoto BeforeDocTypeSystemIdentifier; }
    action To_AfterDocTypeSystemIdentifier { fgoto AfterDocTypeSystemIdentifier; }

    action FeedAppropriateEndTagWithLowerCased() { !($IsAppropriateEndTagFed) && ($GetNextAppropriateEndTagChar) === fc + 0x20 }
    action FeedAppropriateEndTag() { !($IsAppropriateEndTagFed) && ($GetNextAppropriateEndTagChar) === fc }

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

    _SafeStringChunk = (
        0 @AppendReplacementCharacter |
        _CRLF $2 |
        ^(0 | CR)+ $1 %0 >StartSlice %AppendSlice %eof(AppendSlice)
    )+ %2;

    _SafeText = (_SafeStringChunk >StartString %EmitString %eof(EmitString))? $1 %2;

    _SafeString = _SafeStringChunk? >StartString >eof(StartString);

    _Name = (
        upper @AppendLowerCasedCharacter |
        0 @AppendReplacementCharacter |
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

    _AttrNamedEntity = alnum+ >StartNamedEntity $UnmatchNamedEntity $FeedNamedEntity <: (
        ';' >1 @FeedNamedEntity @AppendNamedEntity |
        '=' >1 |
        any >0 @AppendNamedEntity @Reconsume
    );

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

    _AttrEntity = '&' @MarkPosition (
        (
            _AttrNamedEntity |
            _NumericEntity
        ) >1 |
        any >0 @Reconsume
    ) >eof(AppendSlice);

    _StartTagEnd = (
        TagNameSpace @To_BeforeAttributeName |
        '/' @To_SelfClosingTag |
        '>' @EmitStartTagToken @To_Data
    );

    _EndTagEnd = (
        TagNameSpace |
        '/' |
        '>'
    ) @Reconsume @To_EndTagNameContents;

    EndTagName := _Name :> _EndTagEnd >SetEndTagName;

    EndTagNameContents := (
        start: (TagNameSpace | '/')* <: (
            '>' @EmitEndTagToken @To_Data |
            any+ >0 :> (
                '/' -> start |
                '>' @EmitEndTagToken @To_Data |
                '=' TagNameSpace* <: (
                    _StartQuote >1 any* :> _EndQuote -> start |
                    '>' >1 @EmitEndTagToken @To_Data |
                    any+ >0 :> (
                        TagNameSpace -> start |
                        '>' @EmitEndTagToken @To_Data
                    )
                )
            )
        )
    );

    _SpecialEndTag = (
        '/' >StartAppropriateEndTag
        (
            upper when FeedAppropriateEndTagWithLowerCased |
            lower when FeedAppropriateEndTag
        )*
        _EndTagEnd when IsAppropriateEndTagFed >CreateEndTagToken >SetAppropriateEndTagName
    ) @err(AppendSlice) @err(EmitString) @err(Reconsume);

    Data := ((
        _CRLF $2 |
        (
            _Entity |
            ^('&' | CR)
        )+ $1 %0 >StartSlice %AppendSlice %eof(AppendSlice)
    )+ %2 >StartString %EmitString <eof(EmitString))? :> '<' @StartString @StartSlice @To_TagOpen;

    TagOpen := (
        (
            '!' @To_MarkupDeclarationOpen |
            '/' @To_EndTagOpen |
            alpha @CreateStartTagToken @Reconsume @To_StartTagName |
            '?' @Reconsume @To_BogusComment
        ) >1 |
        any >0 @AppendSlice @EmitString @Reconsume @To_Data
    ) @eof(AppendSlice) @eof(EmitString);

    EndTagOpen := (
        (
            alpha @CreateEndTagToken @Reconsume @To_EndTagName |
            '>' @To_Data
        ) >1 |
        any >0 @Reconsume @To_BogusComment
    ) @eof(AppendSlice) @eof(EmitString);

    StartTagName := _Name %SetStartTagName :> _StartTagEnd;

    RCData := ((
        0 @AppendReplacementCharacter |
        _CRLF $2 |
        (
            _Entity |
            ^(0 | CR | '&')
        )+ $1 %0 >StartSlice %AppendSlice %eof(AppendSlice)
    )+ %2 >StartString %EmitString <eof(EmitString))? :> '<' @StartString @StartSlice @To_RCDataLessThanSign;

    RCDataLessThanSign := _SpecialEndTag @err(To_RCData);

    RawText := (
        _SafeText
    ) :> '<' @StartString @StartSlice @To_RawTextLessThanSign;

    RawTextLessThanSign := _SpecialEndTag @err(To_RawText);

    ScriptData := (
        _SafeText
    ) :> '<' @StartString @StartSlice @To_ScriptDataLessThanSign;

    ScriptDataLessThanSign := (
        _SpecialEndTag |
        '!--' @To_ScriptDataEscapedDashDash
    ) @err(AppendSlice) @err(EmitString) @err(Reconsume) @err(To_ScriptData);

    ScriptDataEscaped := _SafeText :> (
        '-' @To_ScriptDataEscapedDash |
        '<' @To_ScriptDataEscapedLessThanSign
    ) >StartString >StartSlice;

    ScriptDataEscapedDash := (
        (
            '-' @To_ScriptDataEscapedDashDash |
            '<' @AppendSlice @EmitString @StartString @StartSlice @To_ScriptDataEscapedLessThanSign
        ) >1 |
        any >0 @AppendSlice @EmitString @Reconsume @To_ScriptDataEscaped
    ) @eof(AppendSlice) @eof(EmitString);

    ScriptDataEscapedDashDash := '-'* <: (
        (
            '<' @To_ScriptDataEscapedLessThanSign |
            '>' @AppendSlice @EmitString @Reconsume @To_ScriptData
        ) >1 |
        any >0 @AppendSlice @EmitString @Reconsume @To_ScriptDataEscaped
    ) @eof(AppendSlice) @eof(EmitString);

    ScriptDataEscapedLessThanSign := (
        _SpecialEndTag |
        (/script/i TagNameEnd) @AppendSlice @EmitString @Reconsume @To_ScriptDataDoubleEscaped
    ) @err(AppendSlice) @err(EmitString) @err(Reconsume) @err(To_ScriptDataEscaped);

    ScriptDataDoubleEscaped := _SafeText :> (
        '-' @To_ScriptDataDoubleEscapedDash |
        '<' @To_ScriptDataDoubleEscapedLessThanSign
    ) >StartString >StartSlice;

    ScriptDataDoubleEscapedDash := (
        (
            '-' @To_ScriptDataDoubleEscapedDashDash |
            '<' @To_ScriptDataDoubleEscapedLessThanSign
        ) >1 |
        any >0 @AppendSlice @EmitString @Reconsume @To_ScriptDataDoubleEscaped
    ) @eof(AppendSlice) @eof(EmitString);

    ScriptDataDoubleEscapedDashDash := '-'* <: (
        (
            '<' @To_ScriptDataDoubleEscapedLessThanSign |
            '>' @AppendSlice @EmitString @Reconsume @To_ScriptData
        ) >1 |
        any >0 @AppendSlice @EmitString @Reconsume @To_ScriptDataDoubleEscaped
    ) @eof(AppendSlice) @eof(EmitString);

    ScriptDataDoubleEscapedLessThanSign := (
        '/' /script/i TagNameEnd @AppendSlice @EmitString @Reconsume @To_ScriptDataEscaped
    ) @err(AppendSlice) @err(EmitString) @err(Reconsume) @err(To_ScriptDataDoubleEscaped);

    PlainText := _SafeText;

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
        0 @AppendReplacementCharacter |
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

    _BogusComment = _SafeString :> '>' @EmitComment @To_Data @eof(EmitComment);

    BogusComment := _BogusComment;

    MarkupDeclarationOpen := (
        (
            '--' @To_Comment |
            /DOCTYPE/i @To_DocType |
            '[' when IsCDataAllowed 'CDATA[' @To_CDataSection
        ) @1 |
        _BogusComment $0
    );

    Comment := (
        start: (
            (
                '-' @StartSlice @MarkPosition -> comment_start_dash |
                '>' -> final |
                0 @AppendReplacementCharacter -> text |
                CR -> crlf
            ) >1 |
            any >0 @StartSlice -> text_slice
        ),

        crlf: CR* $AppendLFCharacter <: (
            LF >1 @StartSlice -> text_slice |
            0 >1 @AppendLFCharacter @AppendReplacementCharacter -> text |
            '-' >1 @AppendLFCharacter @StartSlice @MarkPosition -> comment_end_dash |
            any >0 @AppendLFCharacter @StartSlice -> text_slice
        ),

        comment_start_dash: (
            (
                '-' -> comment_end |
                '>' -> final |
                0 @AppendSlice @AppendReplacementCharacter -> text |
                CR @AppendSlice -> crlf
            ) >1 |
            any >0 -> text_slice
        ),

        text: 0* $AppendReplacementCharacter <: (
            '-' >1 @StartSlice @MarkPosition -> comment_end_dash |
            CR >1 -> crlf |
            any >0 @StartSlice -> text_slice
        ),

        text_slice: any* :> (
            0 @AppendSlice @AppendReplacementCharacter -> text |
            '-' @MarkPosition -> comment_end_dash |
            CR @AppendSlice -> crlf
        ) @eof(AppendSlice),

        comment_end_dash: (
            (
                '-' -> comment_end |
                0 @AppendSlice @AppendReplacementCharacter -> text |
                CR >1 @AppendSlice -> crlf
            ) >1 |
            any >0 -> text_slice
        ) @eof(AppendSliceBeforeTheMark),

        comment_end: '-'* $AdvanceMarkedPosition <: (
            (
                '>' @AppendSliceBeforeTheMark -> final |
                '!' -> comment_end_bang |
                0 @AppendSlice @AppendReplacementCharacter -> text |
                CR @AppendSlice -> crlf
            ) >1 |
            any >0 -> text_slice
        ) @eof(AppendSliceBeforeTheMark),

        comment_end_bang: (
            '-' >1 @MarkPosition -> comment_end_dash |
            '>' >1 @AppendSliceBeforeTheMark -> final |
            0 >1 @AppendSlice @AppendReplacementCharacter -> text |
            CR >1 @AppendSlice -> crlf |
            any >0 -> text_slice
        ) @eof(AppendSliceBeforeTheMark)
    ) @EmitComment @To_Data @eof(EmitComment);

    DocType := TagNameSpace* <: (
        '>' >1 @SetForceQuirksFlag @EmitDocType @To_Data |
        any >0 @Reconsume @To_DocTypeName
    ) >CreateDocType >eof(CreateDocType) @eof(SetForceQuirksFlag) @eof(EmitDocType);

    DocTypeName := _Name %SetDocTypeName %eof(SetDocTypeName) :> (
        TagNameSpace |
        '>'
    ) @Reconsume @To_AfterDocTypeName @eof(SetForceQuirksFlag) @eof(EmitDocType);

    AfterDocTypeName := TagNameSpace* (
        '>' @EmitDocType @To_Data |
        /PUBLIC/i @To_BeforeDocTypePublicIdentifier |
        /SYSTEM/i @To_BeforeDocTypeSystemIdentifier
    ) @err(SetForceQuirksFlag) @err(Reconsume) @err(To_BogusDocType);

    BeforeDocTypePublicIdentifier := TagNameSpace* <: (
        _StartQuote >1 @To_DocTypePublicIdentifierQuoted |
        any >0 @SetForceQuirksFlag @Reconsume @To_BogusDocType
    ) @eof(SetForceQuirksFlag) @eof(EmitDocType);

    DocTypePublicIdentifierQuoted := _SafeString %SetDocTypePublicIdentifier %eof(SetDocTypePublicIdentifier) :> (
        _EndQuote @To_BetweenDocTypePublicAndSystemIdentifiers |
        '>' @SetForceQuirksFlag @EmitDocType @To_Data
    ) @eof(SetForceQuirksFlag) @eof(EmitDocType);

    BetweenDocTypePublicAndSystemIdentifiers := TagNameSpace* <: (
        (
            _StartQuote @To_DocTypeSystemIdentifierQuoted |
            '>' @EmitDocType @To_Data
        ) >1 |
        any >0 @SetForceQuirksFlag @Reconsume @To_BogusDocType
    ) @eof(SetForceQuirksFlag) @eof(EmitDocType);

    BeforeDocTypeSystemIdentifier := TagNameSpace* <: (
        _StartQuote >1 @To_DocTypeSystemIdentifierQuoted |
        any >0 @SetForceQuirksFlag @Reconsume @To_BogusDocType
    ) @eof(SetForceQuirksFlag) @eof(EmitDocType);

    DocTypeSystemIdentifierQuoted := _SafeString %SetDocTypeSystemIdentifier %eof(SetDocTypeSystemIdentifier) :> (
        _EndQuote @To_AfterDocTypeSystemIdentifier |
        '>' @SetForceQuirksFlag @EmitDocType @To_Data
    ) @eof(SetForceQuirksFlag) @eof(EmitDocType);

    AfterDocTypeSystemIdentifier := TagNameSpace* <: (
        any @Reconsume @To_BogusDocType
    ) @eof(SetForceQuirksFlag) @eof(EmitDocType);

    BogusDocType := any* :> '>' @EmitDocType @To_Data @eof(EmitDocType);

    CDataSection := (
        start: (
            ']' >1 @StartSlice @MarkPosition -> cdata_end |
            CR >1 -> crlf |
            any >0 @StartSlice -> text_slice
        ),

        text_slice: any* :> (
            CR >1 @AppendSlice -> crlf |
            ']' >1 @MarkPosition -> cdata_end
        ) @eof(AppendSlice) @eof(EmitString),

        crlf: CR* $AppendLFCharacter <: (
            LF >1 |
            any >0 @AppendLFCharacter
        ) @StartSlice @eof(AppendLFCharacter) @eof(EmitString) -> text_slice,

        cdata_end: (
            ']' >1 -> cdata_end_right_bracket |
            CR >1 @AppendSlice -> crlf |
            any >0 -> text_slice
        ) @eof(AppendSlice) @eof(EmitString),

        cdata_end_right_bracket: ']'* $AdvanceMarkedPosition <: (
            '>' >1 @AppendSliceBeforeTheMark -> final |
            CR >1 @AppendSlice -> crlf |
            any >0 -> text_slice
        ) @eof(AppendSlice) @eof(EmitString)
    ) @EmitString @To_Data;
}%%