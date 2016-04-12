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
    action To_CommentStartDash { fgoto CommentStartDash; }
    action To_Comment { fgoto Comment; }
    action To_CommentEnd { fgoto CommentEnd; }
    action To_CommentEndDash { fgoto CommentEndDash; }
    action To_CommentEndBang { fgoto CommentEndBang; }
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

    _Slice = (any $1 %0)+ >StartSlice %AppendSlice %eof(AppendSlice);

    _SafeStringChunk = (
        0 @AppendReplacementCharacter |
        (_Slice -- 0) $1 %0
    )+ %2;

    _SafeText = (_SafeStringChunk >StartString %EmitString %eof(EmitString))? $1 %2;

    _SafeString = _SafeStringChunk? >StartString >eof(StartString);

    _Name = (
        upper @AppendLowerCasedCharacter |
        0 @AppendReplacementCharacter |
        (_Slice -- (upper | 0)) $1 %0
    )* %2;

    Data := ((
        # '&' @To_CharacterReferenceInData |
        _Slice $1 %0
    )+ %2 >StartString %EmitString %eof(EmitString))? :> '<' @StartString @StartSlice @To_TagOpen;

    RCData := ((
        # '&' @To_CharacterReferenceInRCData |
        _SafeStringChunk
    ) >StartString %EmitString %eof(EmitString))? :> '<' @StartString @StartSlice2 @To_RCDataLessThanSign;

    RawText := (
        _SafeText
    ) :> '<' @StartString @StartSlice2 @To_RawTextLessThanSign;

    ScriptData := (
        _SafeText
    ) :> '<' @StartString @StartSlice2 @To_ScriptDataLessThanSign;

    PlainText := _SafeText;

    TagOpen := (
        '!' @To_MarkupDeclarationOpen |
        '/' @To_EndTagOpen |
        alpha @CreateStartTagToken @StartString @Reconsume @To_TagName |
        '?' @Reconsume @To_BogusComment
    ) @lerr(AppendSlice) @lerr(EmitString) @lerr(Reconsume) @lerr(To_Data);

    EndTagOpen := (
        (
            alpha @CreateEndTagToken @StartString @Reconsume @To_TagName |
            '>' @To_Data
        ) >1 |
        any >0 @Reconsume @To_BogusComment
    ) @eof(AppendSlice) @lerr(EmitString) @eof(Reconsume) @eof(To_Data);

    TagName := _Name %SetTagName :> (
        TagNameSpace @To_BeforeAttributeName |
        '/' @To_SelfClosingStartTag |
        '>' @EmitTagToken @To_Data
    ) @eof(Reconsume) @eof(To_Data);

    RCDataLessThanSign := (
        '/' @CreateEndTagToken
        (
            upper @AppendLowerCasedCharacter |
            lower @AppendCharacter
        )* %SetTagName (
            TagNameSpace when IsAppropriateEndTagToken @To_BeforeAttributeName |
            '/' when IsAppropriateEndTagToken @To_SelfClosingStartTag |
            '>' when IsAppropriateEndTagToken @EmitTagToken @To_Data
        ) @lerr(StartString)
    ) @lerr(AppendSlice2) @lerr(EmitString) @lerr(Reconsume) @lerr(To_RCData);

    RawTextLessThanSign := (
        '/' @CreateEndTagToken
        (
            upper @AppendLowerCasedCharacter |
            lower @AppendCharacter
        )* %SetTagName (
            TagNameSpace when IsAppropriateEndTagToken @To_BeforeAttributeName |
            '/' when IsAppropriateEndTagToken @To_SelfClosingStartTag |
            '>' when IsAppropriateEndTagToken @EmitTagToken @To_Data
        ) @lerr(StartString)
    ) @lerr(AppendSlice2) @lerr(EmitString) @lerr(Reconsume) @lerr(To_RawText);

    ScriptDataLessThanSign := (
        (
            '/' @CreateEndTagToken
            (
                upper @AppendLowerCasedCharacter |
                lower @AppendCharacter
            )* %SetTagName (
                TagNameSpace when IsAppropriateEndTagToken @To_BeforeAttributeName |
                '/' when IsAppropriateEndTagToken @To_SelfClosingStartTag |
                '>' when IsAppropriateEndTagToken @EmitTagToken @To_Data
            ) @lerr(StartString)
        ) |
        '!--' @To_ScriptDataEscapedDashDash
    ) @lerr(AppendSlice2) @lerr(EmitString) @lerr(Reconsume) @lerr(To_ScriptData);

    ScriptDataEscaped := _SafeText :> (
        '-' @To_ScriptDataEscapedDash |
        '<' @To_ScriptDataEscapedLessThanSign
    ) >StartString >StartSlice2 @eof(Reconsume) @eof(To_Data);

    ScriptDataEscapedDash := (
        (
            '-' @To_ScriptDataEscapedDashDash |
            '<' @AppendSlice2 @EmitString @StartString @StartSlice2 @To_ScriptDataEscapedLessThanSign
        ) >1 |
        any >0 @AppendSlice2 @EmitString @Reconsume @To_ScriptDataEscaped
    ) @eof(AppendSlice2) @eof(EmitString) @eof(Reconsume) @eof(To_Data);

    ScriptDataEscapedDashDash := '-'* <: (
        (
            '<' @To_ScriptDataEscapedLessThanSign |
            '>' @AppendSlice2 @AppendCharacter @EmitString @To_ScriptData
        ) >1 |
        any >0 @AppendSlice2 @EmitString @Reconsume @To_ScriptDataEscaped
    ) @eof(AppendSlice2) @eof(EmitString) @eof(Reconsume) @eof(To_Data);

    ScriptDataEscapedLessThanSign := (
        (
            '/' @CreateEndTagToken
            (
                upper @AppendLowerCasedCharacter |
                lower @AppendCharacter
            )* %SetTagName (
                TagNameSpace when IsAppropriateEndTagToken @To_BeforeAttributeName |
                '/' when IsAppropriateEndTagToken @To_SelfClosingStartTag |
                '>' when IsAppropriateEndTagToken @EmitTagToken @To_Data
            ) @lerr(StartString)
        ) |
        (/script/i TagNameEnd) @AppendSlice2 @AppendCharacter @EmitString @To_ScriptDataDoubleEscaped
    ) @lerr(AppendSlice2) @lerr(EmitString) @lerr(Reconsume) @lerr(To_ScriptDataEscaped);

    ScriptDataDoubleEscaped := _SafeText :> (
        '-' @To_ScriptDataDoubleEscapedDash |
        '<' @To_ScriptDataDoubleEscapedLessThanSign
    ) >StartString >StartSlice2 @eof(Reconsume) @eof(To_Data);

    ScriptDataDoubleEscapedDash := (
        (
            '-' @To_ScriptDataDoubleEscapedDashDash |
            '<' @To_ScriptDataDoubleEscapedLessThanSign
        ) >1 |
        any >0 @AppendSlice2 @EmitString @Reconsume @To_ScriptDataDoubleEscaped
    ) @eof(AppendSlice2) @eof(EmitString) @eof(Reconsume) @eof(To_Data);

    ScriptDataDoubleEscapedDashDash := '-'* <: (
        (
            '<' @To_ScriptDataDoubleEscapedLessThanSign |
            '>' @AppendSlice2 @AppendCharacter @EmitString @To_ScriptData
        ) >1 |
        any >0 @AppendSlice2 @EmitString @Reconsume @To_ScriptDataDoubleEscaped
    ) @eof(AppendSlice2) @eof(EmitString) @eof(Reconsume) @eof(To_Data);

    ScriptDataDoubleEscapedLessThanSign := (
        '/' /script/i TagNameEnd @AppendSlice2 @AppendCharacter @EmitString @To_ScriptDataEscaped
    ) @lerr(AppendSlice2) @lerr(EmitString) @lerr(Reconsume) @lerr(To_ScriptDataDoubleEscaped);

    BeforeAttributeName := TagNameSpace* <: (
        ('/' | '>') >1 @Reconsume @To_AfterAttributeName |
        (
            '=' >1 @AppendCharacter |
            any >0 @Reconsume
        ) >CreateAttribute >StartString @To_AttributeName
    ) @eof(Reconsume) @eof(To_Data);

    AttributeName := _Name %AppendAttribute :> (
        TagNameEnd @Reconsume @To_AfterAttributeName |
        '=' @To_BeforeAttributeValue
    ) @eof(Reconsume) @eof(To_Data);

    AfterAttributeName := TagNameSpace* <: (
        (
            '/' @To_SelfClosingStartTag |
            '=' @To_BeforeAttributeValue |
            '>' @EmitTagToken @To_Data
        ) >1 |
        any >0 @CreateAttribute @StartString @Reconsume @To_AttributeName
    ) @eof(Reconsume) @eof(To_Data);

    BeforeAttributeValue := TagNameSpace* <: (
        _StartQuote >1 @To_AttributeValueQuoted |
        any >0 @Reconsume @To_AttributeValueUnquoted
    ) @eof(Reconsume) @eof(To_Data);

    AttributeValueQuoted := _SafeString %SetAttributeValue :> (
        _EndQuote @To_AfterAttributeValueQuoted
        # '&' @To_CharacterReferenceInAttributeValue
    ) @eof(Reconsume) @eof(To_Data);

    AttributeValueUnquoted := _SafeString %SetAttributeValue :> (
        TagNameSpace @To_BeforeAttributeName |
        '>' @EmitTagToken @To_Data
        # '&' @To_CharacterReferenceInAttributeValue
    ) @eof(Reconsume) @eof(To_Data);

    AfterAttributeValueQuoted := (
        (
            TagNameSpace @To_BeforeAttributeName |
            '/' @To_SelfClosingStartTag |
            '>' @EmitTagToken @To_Data
        ) >1 |
        any >0 @Reconsume @To_BeforeAttributeName
    ) @eof(Reconsume) @eof(To_Data);

    SelfClosingStartTag := (
        '>' >1 @SetSelfClosingFlag @EmitTagToken @To_Data |
        any >0 @Reconsume @To_BeforeAttributeName
    ) @eof(Reconsume) @eof(To_Data);

    _BogusComment = _SafeString :> '>' @EmitComment @To_Data @eof(EmitComment) @eof(Reconsume) @eof(To_Data);

    BogusComment := _BogusComment;

    MarkupDeclarationOpen := (
        (
            '--' @StartString @To_CommentStart |
            /DOCTYPE/i @To_DocType |
            '[' when IsCDataAllowed 'CDATA[' @StartString @To_CDataSection
        ) @1 |
        _BogusComment $0
    );

    CommentStart := (
        (
            '-' @StartSlice @To_CommentStartDash |
            '>' @EmitComment @To_Data
        ) >1 |
        any >0 @Reconsume @To_Comment
    ) @eof(EmitComment) @eof(Reconsume) @eof(To_Data);

    CommentStartDash := (
        (
            '-' @To_CommentEnd |
            '>' @EmitComment @To_Data
        ) >1 |
        any >0 @AppendSlice @Reconsume @To_Comment
    ) @eof(EmitComment) @eof(Reconsume) @eof(To_Data);

    Comment := _SafeStringChunk? :> (
        '-' @StartSlice @To_CommentEndDash
    ) @eof(EmitComment) @eof(Reconsume) @eof(To_Data);

    CommentEndDash := (
        '-' >1 @To_CommentEnd |
        any >0 @AppendSlice @Reconsume @To_Comment
    ) @eof(EmitComment) @eof(Reconsume) @eof(To_Data);

    CommentEnd := '-'* >StartSlice2 <eof(AppendSlice2) <: (
        (
            '>' @AppendSlice2 @EmitComment @To_Data |
            '!' @To_CommentEndBang
        ) >1 |
        any >0 @AppendSlice @Reconsume @To_Comment
    ) @eof(EmitComment) @eof(Reconsume) @eof(To_Data);

    CommentEndBang := (
        '>' >1 @EmitComment @To_Data |
        any >0 @AppendSlice @Reconsume @To_Comment
    ) @eof(EmitComment) @eof(Reconsume) @eof(To_Data);

    DocType := TagNameSpace* <: (
        '>' >1 @SetForceQuirksFlag @EmitDocType @To_Data |
        any >0 @Reconsume @To_DocTypeName
    ) >CreateDocType >eof(CreateDocType) @eof(SetForceQuirksFlag) @eof(EmitDocType) @eof(Reconsume) @eof(To_Data);

    DocTypeName := _Name >StartString %SetDocTypeName %eof(SetDocTypeName) :> (
        TagNameSpace |
        '>'
    ) @Reconsume @To_AfterDocTypeName @eof(Reconsume) @eof(To_AfterDocTypeName);

    AfterDocTypeName := TagNameSpace* (
        '>' @EmitDocType @To_Data |
        /PUBLIC/i @To_BeforeDocTypePublicIdentifier |
        /SYSTEM/i @To_BeforeDocTypeSystemIdentifier
    ) $lerr(Reconsume) $lerr(SetForceQuirksFlag) $lerr(To_BogusDocType);

    BeforeDocTypePublicIdentifier := TagNameSpace* (
        _StartQuote @To_DocTypePublicIdentifierQuoted
    ) @lerr(SetForceQuirksFlag) @lerr(Reconsume) @lerr(To_BogusDocType);

    DocTypePublicIdentifierQuoted := _SafeString %SetDocTypePublicIdentifier %eof(SetDocTypePublicIdentifier) :> (
        _EndQuote @To_BetweenDocTypePublicAndSystemIdentifiers |
        '>' @SetForceQuirksFlag @EmitDocType @To_Data
    ) @eof(SetForceQuirksFlag) @eof(EmitDocType) @eof(Reconsume) @eof(To_Data);

    BetweenDocTypePublicAndSystemIdentifiers := TagNameSpace* (
        _StartQuote @To_DocTypeSystemIdentifierQuoted |
        '>' @EmitDocType @To_Data
    ) @lerr(SetForceQuirksFlag) @lerr(Reconsume) @lerr(To_BogusDocType);

    BeforeDocTypeSystemIdentifier := TagNameSpace* (
        _StartQuote @To_DocTypeSystemIdentifierQuoted
    ) @lerr(SetForceQuirksFlag) @lerr(Reconsume) @lerr(To_BogusDocType);

    DocTypeSystemIdentifierQuoted := _SafeString %SetDocTypeSystemIdentifier %eof(SetDocTypeSystemIdentifier) :> (
        _EndQuote @To_AfterDocTypeSystemIdentifier |
        '>' @SetForceQuirksFlag @EmitDocType @To_Data
    ) @eof(SetForceQuirksFlag) @eof(EmitDocType) @eof(Reconsume) @eof(To_Data);

    AfterDocTypeSystemIdentifier := TagNameSpace* <: (
        '>' >1 @EmitDocType @To_Data |
        any >0 @To_BogusDocType
    ) @eof(SetForceQuirksFlag) @eof(EmitDocType) @eof(Reconsume) @eof(To_Data);

    BogusDocType := any* :> '>' @EmitDocType @To_Data @eof(EmitDocType) @eof(Reconsume) @eof(To_Data);

    CDataSection := _Slice? :> (
        ']' @StartSlice @To_CDataSectionEnd
    ) @eof(EmitString) @eof(Reconsume) @eof(To_Data);

    CDataSectionEnd := (
        ']' >1 @To_CDataSectionEndRightBracket |
        any >0 @AppendSlice @Reconsume @To_CDataSection
    ) @eof(AppendSlice) @eof(EmitString) @eof(Reconsume) @eof(To_Data);

    CDataSectionEndRightBracket := ']'* >StartSlice2 <: (
        '>' >1 @AppendSlice2 @EmitString @To_Data |
        any >0 @AppendSlice @Reconsume @To_CDataSection
    ) @eof(AppendSlice) @eof(EmitString) @eof(Reconsume) @eof(To_Data);
}%%