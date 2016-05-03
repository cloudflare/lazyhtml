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
    action To_TagName { fgoto TagName; }
    action To_BogusComment { fgoto BogusComment; }
    action To_BeforeAttributeName { fgoto BeforeAttributeName; }
    action To_SelfClosingStartTag { fgoto SelfClosingStartTag; }
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

    TAB = '\t';
    LF = '\n';
    FF = '\f';

    TagNameSpace = TAB | LF | FF | ' ';

    TagNameEnd = TagNameSpace | '/' | '>';

    _Quote = ('"' | "'");

    _StartQuote = _Quote @SaveQuote;

    _EndQuote = _Quote when IsMatchingQuote;

    _SafeStringChunk = (
        0 @AppendReplacementCharacter |
        ^0+ $1 %0 >StartSlice %AppendSlice %eof(AppendSlice)
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

    _UnsafeNUL = 0+ $1 %0 >AppendSlice $AppendReplacementCharacter %StartSlice %eof(StartSlice);

    Data := (
        (
            _Entity >1 |
            any >0
        )+ >StartString >StartSlice %AppendSlice %eof(AppendSlice) %EmitString <eof(EmitString)
    )? :> '<' @StartString @StartSlice @To_TagOpen;

    RCData := (
        (
            (
                _Entity |
                _UnsafeNUL
            ) >1 |
            any >0
        )+ >StartString >StartSlice %AppendSlice %eof(AppendSlice) %EmitString <eof(EmitString)
    )? :> '<' @StartString @StartSlice @To_RCDataLessThanSign;

    RawText := (
        _SafeText
    ) :> '<' @StartString @StartSlice @To_RawTextLessThanSign;

    ScriptData := (
        _SafeText
    ) :> '<' @StartString @StartSlice @To_ScriptDataLessThanSign;

    PlainText := _SafeText;

    TagOpen := (
        (
            '!' @To_MarkupDeclarationOpen |
            '/' @To_EndTagOpen |
            alpha @CreateStartTagToken @StartString @Reconsume @To_TagName |
            '?' @Reconsume @To_BogusComment
        ) >1 |
        any >0 @AppendSlice @EmitString @Reconsume @To_Data
    ) @eof(AppendSlice) @eof(EmitString);

    EndTagOpen := (
        (
            alpha @CreateEndTagToken @StartString @Reconsume @To_TagName |
            '>' @To_Data
        ) >1 |
        any >0 @Reconsume @To_BogusComment
    ) @eof(AppendSlice) @eof(EmitString);

    _TagEnd = (
        TagNameSpace @To_BeforeAttributeName |
        '/' @To_SelfClosingStartTag |
        '>' @EmitTagToken @To_Data
    );

    TagName := _Name %SetTagName :> _TagEnd;

    _SpecialEndTag = (
        '/'
        (
            (
                upper @AppendLowerCasedCharacter |
                lower+ $1 %0 >MarkPosition %AppendSliceAfterTheMark
            )* %CreateEndTagToken %SetTagName <: any @Reconsume _TagEnd when IsAppropriateEndTagToken
        ) <>lerr(StartString)
    );

    RCDataLessThanSign := _SpecialEndTag @lerr(AppendSlice) @lerr(EmitString) @lerr(Reconsume) @lerr(To_RCData);

    RawTextLessThanSign := _SpecialEndTag @lerr(AppendSlice) @lerr(EmitString) @lerr(Reconsume) @lerr(To_RawText);

    ScriptDataLessThanSign := (
        _SpecialEndTag $0 |
        '!--' @To_ScriptDataEscapedDashDash $1
    ) @lerr(AppendSlice) @lerr(EmitString) @lerr(Reconsume) @lerr(To_ScriptData);

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
    ) @lerr(AppendSlice) @lerr(EmitString) @lerr(Reconsume) @lerr(To_ScriptDataEscaped);

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
    ) @lerr(AppendSlice) @lerr(EmitString) @lerr(Reconsume) @lerr(To_ScriptDataDoubleEscaped);

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
            _TagEnd |
            '=' @To_BeforeAttributeValue
        ) >1 |
        any >0 @CreateAttribute @StartString @Reconsume @To_AttributeName
    );

    BeforeAttributeValue := TagNameSpace* <: (
        _StartQuote >1 @To_AttributeValueQuoted |
        any >0 @Reconsume @To_AttributeValueUnquoted
    );

    AttributeValueQuoted := (
        (
            (
                _AttrEntity |
                _UnsafeNUL
            ) >1 |
            any >0
        )+ >StartString >StartSlice %AppendSlice %SetAttributeValue
    )? :> _EndQuote @To_AfterAttributeValueQuoted;

    AttributeValueUnquoted := (
        (
            (
                _AttrEntity |
                _UnsafeNUL
            ) >1 |
            any >0
        )+ >StartString >StartSlice %AppendSlice %SetAttributeValue
    )? :> ((TagNameSpace | '>') & _TagEnd);

    AfterAttributeValueQuoted := (
        _TagEnd >1 |
        any >0 @Reconsume @To_BeforeAttributeName
    );

    SelfClosingStartTag := (
        '>' >1 @SetSelfClosingFlag @EmitTagToken @To_Data |
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
                0 @AppendReplacementCharacter -> text
            ) >1 |
            any >0 @StartSlice -> text_slice
        ),

        comment_start_dash: (
            (
                '-' -> comment_end |
                '>' -> final |
                0 @AppendSlice @AppendReplacementCharacter -> text
            ) >1 |
            any >0 -> text_slice
        ),

        text: (
            0 >1 @AppendReplacementCharacter -> text |
            '-' >1 @StartSlice @MarkPosition -> comment_end_dash |
            any >0 @StartSlice -> text_slice
        ),

        text_slice: (
            0 >1 @AppendSlice @AppendReplacementCharacter -> text |
            '-' >1 @MarkPosition -> comment_end_dash |
            any >0 -> text_slice
        ) @eof(AppendSlice),

        comment_end_dash: (
            (
                '-' -> comment_end |
                0 @AppendSlice @AppendReplacementCharacter -> text
            ) >1 |
            any >0 -> text_slice
        ) @eof(AppendSliceBeforeTheMark),

        comment_end: (
            (
                '-' @AdvanceMarkedPosition -> comment_end |
                '>' @AppendSliceBeforeTheMark -> final |
                '!' -> comment_end_bang |
                0 @AppendSlice @AppendReplacementCharacter -> text
            ) >1 |
            any >0 -> text_slice
        ) @eof(AppendSliceBeforeTheMark),

        comment_end_bang: (
            '-' >1 @MarkPosition -> comment_end_dash |
            '>' >1 @AppendSliceBeforeTheMark -> final |
            0 >1 @AppendSlice @AppendReplacementCharacter -> text |
            any >0 -> text_slice
        ) @eof(AppendSliceBeforeTheMark)
    ) >StartString @EmitComment @To_Data @eof(EmitComment);

    DocType := TagNameSpace* <: (
        '>' >1 @SetForceQuirksFlag @EmitDocType @To_Data |
        any >0 @Reconsume @To_DocTypeName
    ) >CreateDocType >eof(CreateDocType) @eof(SetForceQuirksFlag) @eof(EmitDocType);

    DocTypeName := _Name >StartString %SetDocTypeName %eof(SetDocTypeName) :> (
        TagNameSpace |
        '>'
    ) @Reconsume @To_AfterDocTypeName @eof(SetForceQuirksFlag) @eof(EmitDocType);

    AfterDocTypeName := TagNameSpace* (
        '>' @EmitDocType @To_Data |
        /PUBLIC/i @To_BeforeDocTypePublicIdentifier |
        /SYSTEM/i @To_BeforeDocTypeSystemIdentifier
    ) @lerr(SetForceQuirksFlag) @lerr(Reconsume) @lerr(To_BogusDocType);

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
            ']' @MarkPosition >1 -> cdata_end |
            any >0 -> start
        ),

        cdata_end: (
            ']' >1 -> cdata_end_right_bracket |
            any >0 -> start
        ),

        cdata_end_right_bracket: (
            ']' >1 @AdvanceMarkedPosition -> cdata_end_right_bracket |
            '>' >1 @AppendSliceBeforeTheMark -> final |
            any >0 -> start
        )
    ) >StartString >StartSlice <>eof(AppendSlice) <>eof(EmitString) @EmitString @To_Data;
}%%