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
    action To_RCDataEndTagOpen { fgoto RCDataEndTagOpen; }
    action To_RCDataEndTagName { fgoto RCDataEndTagName; }
    action To_RawTextEndTagOpen { fgoto RawTextEndTagOpen; }
    action To_RawTextEndTagName { fgoto RawTextEndTagName; }
    action To_ScriptDataEndTagOpen { fgoto ScriptDataEndTagOpen; }
    action To_ScriptDataEscapeStart { fgoto ScriptDataEscapeStart; }
    action To_ScriptDataEndTagName { fgoto ScriptDataEndTagName; }
    action To_ScriptDataEscapeStartDash { fgoto ScriptDataEscapeStartDash; }
    action To_ScriptDataEscapedDashDash { fgoto ScriptDataEscapedDashDash; }
    action To_ScriptDataEscapedDash { fgoto ScriptDataEscapedDash; }
    action To_ScriptDataEscapedLessThanSign { fgoto ScriptDataEscapedLessThanSign; }
    action To_ScriptDataEscaped { fgoto ScriptDataEscaped; }
    action To_ScriptDataEscapedEndTagOpen { fgoto ScriptDataEscapedEndTagOpen; }
    action To_ScriptDataEscapedEndTagName { fgoto ScriptDataEscapedEndTagName; }
    action To_ScriptDataDoubleEscaped { fgoto ScriptDataDoubleEscaped; }
    action To_ScriptDataDoubleEscapedDash { fgoto ScriptDataDoubleEscapedDash; }
    action To_ScriptDataDoubleEscapedLessThanSign { fgoto ScriptDataDoubleEscapedLessThanSign; }
    action To_ScriptDataDoubleEscapedDashDash { fgoto ScriptDataDoubleEscapedDashDash; }
    action To_ScriptDataDoubleEscapeEnd { fgoto ScriptDataDoubleEscapeEnd; }
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

    UnsafeNULL = 0 @EmitReplacementCharacterToken;

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

    Data := ((
        # '&' @To_CharacterReferenceInData |
        _Slice $1 %0
    )+ %2 >StartString %EmitString %eof(EmitString))? :> '<' @To_TagOpen;

    RCData := ((
        # '&' @To_CharacterReferenceInRCData |
        _SafeStringChunk
    )+ >StartString %EmitString %eof(EmitString))? :> '<' @To_RCDataLessThanSign;

    RawText := (
        _SafeText
    ) :> '<' @To_RawTextLessThanSign;

    ScriptData := (
        _SafeText
    ) :> '<' @To_ScriptDataLessThanSign;

    PlainText := _SafeText;

    TagOpen := (
        '!' @To_MarkupDeclarationOpen |
        '/' @To_EndTagOpen |
        alpha @CreateStartTagToken @StartString @Reconsume @To_TagName |
        '?' @Reconsume @To_BogusComment
    ) @lerr(EmitLessThanSignCharacterToken) @lerr(Reconsume) @lerr(To_Data);

    EndTagOpen := (
        (
            alpha @CreateEndTagToken @StartString @Reconsume @To_TagName |
            '>' @To_Data
        ) >1 |
        any >0 @Reconsume @To_BogusComment
    ) @eof(EmitLessThanSignCharacterToken) @eof(EmitSolidusCharacterToken) @eof(Reconsume) @eof(To_Data);

    TagName := (
        upper @AppendLowerCasedCharacter |
        0 @AppendReplacementCharacter |
        (_Slice -- (upper | 0)) $1 %0
    )* %2 %SetTagName :> (
        TagNameSpace @To_BeforeAttributeName |
        '/' @To_SelfClosingStartTag |
        '>' @EmitTagToken @To_Data
    ) @eof(Reconsume) @eof(To_Data);

    RCDataLessThanSign := (
        '/' @CreateTemporaryBuffer @To_RCDataEndTagOpen
    ) @lerr(EmitLessThanSignCharacterToken) @lerr(Reconsume) @lerr(To_RCData);

    RCDataEndTagOpen := alpha @CreateEndTagToken @StartString @Reconsume @To_RCDataEndTagName @lerr(EmitLessThanSignCharacterToken) @lerr(EmitSolidusCharacterToken) @lerr(Reconsume) @lerr(To_RCData);

    RCDataEndTagName := (
        upper @AppendLowerCasedCharacter |
        lower @AppendCharacter
    )* @AppendToTemporaryBuffer %SetTagName (
        TagNameSpace when IsAppropriateEndTagToken @To_BeforeAttributeName |
        '/' when IsAppropriateEndTagToken @To_SelfClosingStartTag |
        '>' when IsAppropriateEndTagToken @EmitTagToken @To_Data
    ) @lerr(EmitLessThanSignCharacterToken) @lerr(EmitSolidusCharacterToken) @lerr(EmitTemporaryBufferCharacterToken) @lerr(Reconsume) @lerr(To_RCData);

    RawTextLessThanSign := (
        '/' @CreateTemporaryBuffer @To_RawTextEndTagOpen
    ) @lerr(EmitLessThanSignCharacterToken) @lerr(Reconsume) @lerr(To_RawText);

    RawTextEndTagOpen := alpha @CreateEndTagToken @StartString @Reconsume @To_RawTextEndTagName @lerr(EmitLessThanSignCharacterToken) @lerr(EmitSolidusCharacterToken) @lerr(Reconsume) @lerr(To_RawText);

    RawTextEndTagName := (
        upper @AppendLowerCasedCharacter |
        lower @AppendCharacter
    )* @AppendToTemporaryBuffer %SetTagName (
        TagNameSpace when IsAppropriateEndTagToken @To_BeforeAttributeName |
        '/' when IsAppropriateEndTagToken @To_SelfClosingStartTag |
        '>' when IsAppropriateEndTagToken @EmitTagToken @To_Data
    ) @lerr(EmitLessThanSignCharacterToken) @lerr(EmitSolidusCharacterToken) @lerr(EmitTemporaryBufferCharacterToken) @lerr(Reconsume) @lerr(To_RawText);

    ScriptDataLessThanSign := (
        '/' @CreateTemporaryBuffer @To_ScriptDataEndTagOpen |
        '!' @EmitLessThanSignCharacterToken @EmitCharacterToken @To_ScriptDataEscapeStart
    ) @lerr(EmitLessThanSignCharacterToken) @lerr(Reconsume) @lerr(To_ScriptData);

    ScriptDataEndTagOpen := alpha @CreateEndTagToken @StartString @Reconsume @To_ScriptDataEndTagName @lerr(EmitLessThanSignCharacterToken) @lerr(EmitSolidusCharacterToken) @lerr(Reconsume) @lerr(To_ScriptData);

    ScriptDataEndTagName := (
        upper @AppendLowerCasedCharacter @AppendToTemporaryBuffer @To_ScriptDataEndTagName |
        lower @AppendCharacter @AppendToTemporaryBuffer @To_ScriptDataEndTagName
    )* %SetTagName (
        TagNameSpace when IsAppropriateEndTagToken @To_BeforeAttributeName |
        '/' when IsAppropriateEndTagToken @To_SelfClosingStartTag |
        '>' when IsAppropriateEndTagToken @EmitTagToken @To_Data
    ) @lerr(EmitLessThanSignCharacterToken) @lerr(EmitSolidusCharacterToken) @lerr(EmitTemporaryBufferCharacterToken) @lerr(Reconsume) @lerr(To_ScriptData);

    ScriptDataEscapeStart := (
        '-' @EmitCharacterToken @To_ScriptDataEscapeStartDash
    ) @lerr(Reconsume) @lerr(To_ScriptData);

    ScriptDataEscapeStartDash := (
        '-' @EmitCharacterToken @To_ScriptDataEscapedDashDash
    ) @lerr(Reconsume) @lerr(To_ScriptData);

    ScriptDataEscaped := _SafeText :> (
        '-' @EmitCharacterToken @To_ScriptDataEscapedDash |
        '<' @To_ScriptDataEscapedLessThanSign
    ) @eof(Reconsume) @eof(To_Data);

    ScriptDataEscapedDash := (
        (
            '-' @EmitCharacterToken @To_ScriptDataEscapedDashDash |
            '<' @To_ScriptDataEscapedLessThanSign
        ) >1 |
        any >0 @Reconsume @To_ScriptDataEscaped
    ) @eof(Reconsume) @eof(To_Data);

    ScriptDataEscapedDashDash := (
        (
            '-' @EmitCharacterToken @To_ScriptDataEscapedDashDash |
            '<' @To_ScriptDataEscapedLessThanSign |
            '>' @EmitCharacterToken @To_ScriptData
        ) >1 |
        any >0 @Reconsume @To_ScriptDataEscaped
    ) @eof(Reconsume) @eof(To_Data);

    ScriptDataEscapedLessThanSign := (
        (
            '/' @CreateTemporaryBuffer @To_ScriptDataEscapedEndTagOpen |
            (/script/i TagNameEnd) >EmitLessThanSignCharacterToken $EmitCharacterToken @To_ScriptDataDoubleEscaped $lerr(Reconsume) $lerr(To_ScriptDataEscaped)
        ) >1 |
        any >0 @EmitLessThanSignCharacterToken @Reconsume @To_ScriptDataEscaped
    );

    ScriptDataEscapedEndTagOpen := alpha @CreateEndTagToken @StartString @Reconsume @To_ScriptDataEscapedEndTagName @lerr(EmitLessThanSignCharacterToken) @lerr(EmitSolidusCharacterToken) @lerr(Reconsume) @lerr(To_ScriptDataEscaped);

    ScriptDataEscapedEndTagName := (
        upper @AppendLowerCasedCharacter |
        lower @AppendCharacter
    )* @AppendToTemporaryBuffer %SetTagName (
        TagNameSpace when IsAppropriateEndTagToken @To_BeforeAttributeName |
        '/' when IsAppropriateEndTagToken @To_SelfClosingStartTag |
        '>' when IsAppropriateEndTagToken @EmitTagToken @To_Data
    ) @lerr(EmitLessThanSignCharacterToken) @lerr(EmitSolidusCharacterToken) @lerr(EmitTemporaryBufferCharacterToken) @lerr(Reconsume) @lerr(To_ScriptDataEscaped);

    ScriptDataDoubleEscaped := _SafeText :> (
        '-' @EmitCharacterToken @To_ScriptDataDoubleEscapedDash |
        '<' @EmitCharacterToken @To_ScriptDataDoubleEscapedLessThanSign
    ) @eof(Reconsume) @eof(To_Data);

    ScriptDataDoubleEscapedDash := (
        (
            '-' @EmitCharacterToken @To_ScriptDataDoubleEscapedDashDash |
            '<' @EmitCharacterToken @To_ScriptDataDoubleEscapedLessThanSign |
            UnsafeNULL @To_ScriptDataDoubleEscaped
        ) >1 |
        any >0 @EmitCharacterToken @To_ScriptDataDoubleEscaped
    ) @eof(Reconsume) @eof(To_Data);

    ScriptDataDoubleEscapedDashDash := ('-'+ >StartString >StartSlice %AppendSlice %EmitString %eof(AppendSlice) %eof(EmitString))? <: (
        (
            '<' @EmitCharacterToken @To_ScriptDataDoubleEscapedLessThanSign |
            '>' @EmitCharacterToken @To_ScriptData
        ) >1 |
        any >0 @Reconsume @To_ScriptDataDoubleEscaped
    ) @eof(Reconsume) @eof(To_Data);

    ScriptDataDoubleEscapedLessThanSign := (
        '/' @CreateTemporaryBuffer @EmitSolidusCharacterToken @To_ScriptDataDoubleEscapeEnd
    ) @lerr(Reconsume) @lerr(To_ScriptDataDoubleEscaped);

    ScriptDataDoubleEscapeEnd := (
        upper @AppendUpperCaseToTemporaryBuffer |
        lower @AppendToTemporaryBuffer
    )* @EmitCharacterToken (
        TagNameEnd >1 when IsTemporaryBufferScript @To_ScriptDataEscaped |
        TagNameEnd >0 @To_ScriptDataDoubleEscaped
    ) >EmitCharacterToken
    @lerr(Reconsume) @lerr(To_ScriptDataDoubleEscaped);

    BeforeAttributeName := TagNameSpace* <: (
        ('/' | '>') >1 @Reconsume @To_AfterAttributeName |
        (
            '=' >1 @AppendCharacter |
            any >0 @Reconsume
        ) >CreateAttribute >StartString @To_AttributeName
    ) @eof(Reconsume) @eof(To_Data);

    AttributeName := (
        (
            upper @AppendLowerCasedCharacter |
            0 @AppendReplacementCharacter
        ) >1 |
        (_Slice -- (upper | 0)) $1 %0
    )* %2 %AppendAttribute :> (
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
            '-' @To_CommentStartDash |
            '>' @EmitComment @To_Data
        ) >1 |
        any >0 @Reconsume @To_Comment
    ) @eof(EmitComment) @eof(Reconsume) @eof(To_Data);

    CommentStartDash := (
        (
            '-' @To_CommentEnd |
            '>' @EmitComment @To_Data
        ) >1 |
        any >0 @AppendHyphenMinusCharacter @Reconsume @To_Comment
    ) @eof(EmitComment) @eof(Reconsume) @eof(To_Data);

    Comment := _SafeStringChunk? :> (
        '-' @To_CommentEndDash
    ) @eof(EmitComment) @eof(Reconsume) @eof(To_Data);

    CommentEndDash := (
        '-' >1 @To_CommentEnd |
        any >0 @AppendHyphenMinusCharacter @Reconsume @To_Comment
    ) @eof(EmitComment) @eof(Reconsume) @eof(To_Data);

    CommentEnd := ('-'+ >StartSlice %AppendSlice %eof(AppendSlice))? <: (
        (
            '>' @EmitComment @To_Data |
            '!' @To_CommentEndBang
        ) >1 |
        any >0 @AppendDoubleHyphenMinusCharacter @Reconsume @To_Comment
    ) @eof(EmitComment) @eof(Reconsume) @eof(To_Data);

    CommentEndBang := (
        '>' >1 @EmitComment @To_Data |
        any >0 @AppendDoubleHyphenMinusCharacter @AppendExclamationMarkCharacter @Reconsume @To_Comment
    ) @eof(EmitComment) @eof(Reconsume) @eof(To_Data);

    DocType := TagNameSpace* <: (
        '>' >1 @SetForceQuirksFlag @EmitDocType @To_Data |
        any >0 @Reconsume @To_DocTypeName
    ) >CreateDocType >eof(CreateDocType) @eof(SetForceQuirksFlag) @eof(EmitDocType) @eof(Reconsume) @eof(To_Data);

    DocTypeName := (
        (
            0 @AppendReplacementCharacter |
            upper @AppendLowerCasedCharacter
        ) >1 |
        any >0 @AppendCharacter
    )* >StartString %SetDocTypeName %eof(SetDocTypeName) :> (
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

    CDataSection := (
        ']' @To_CDataSectionEnd |
        (_Slice -- ']') $1 %0
    )* $eof(EmitString) @eof(Reconsume) @eof(To_Data);

    CDataSectionEnd := (
        ']' >1 @To_CDataSectionEndRightBracket |
        any >0 @AppendRightBracketCharacter @Reconsume @To_CDataSection
    ) @eof(AppendRightBracketCharacter) @eof(EmitString) @eof(Reconsume) @eof(To_Data);

    CDataSectionEndRightBracket := (']' @AppendCharacter)* <: (
        '>' >1 @EmitString @To_Data |
        any >0 @AppendDoubleRightBracketCharacter @Reconsume @To_CDataSection
    ) @eof(AppendDoubleRightBracketCharacter) @eof(EmitString) @eof(Reconsume) @eof(To_Data);
}%%