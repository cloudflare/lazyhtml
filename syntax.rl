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
    action To_ScriptDataDoubleEscapeStart { fgoto ScriptDataDoubleEscapeStart; }
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

    _PlainText = (
        UnsafeNULL |
        ^0 @EmitCharacterToken
    )*;

    _Quote = ('"' | "'");

    _StartQuote = _Quote @SaveQuote;

    _EndQuote = _Quote when IsMatchingQuote;

    Data := (
        # '&' @To_CharacterReferenceInData |
        any @EmitCharacterToken
    )* :> '<' @To_TagOpen;

    RCData := (
        # '&' @To_CharacterReferenceInRCData |
        _PlainText
    ) :> '<' @To_RCDataLessThanSign;

    RawText := (
        _PlainText
    ) :> '<' @To_RawTextLessThanSign;

    ScriptData := (
        _PlainText
    ) :> '<' @To_ScriptDataLessThanSign;

    PlainText := _PlainText;

    TagOpen := (
        '!' @To_MarkupDeclarationOpen |
        '/' @To_EndTagOpen |
        alpha @CreateStartTagToken @Reconsume @To_TagName |
        '?' @Reconsume @To_BogusComment
    ) @lerr(EmitLessThanSignCharacterToken) @lerr(Reconsume) @lerr(To_Data);

    EndTagOpen := (
        (
            alpha @CreateEndTagToken @Reconsume @To_TagName |
            '>' @To_Data
        ) >1 |
        any >0 @Reconsume @To_BogusComment
    ) @eof(EmitLessThanSignCharacterToken) @eof(EmitSolidusCharacterToken) @eof(Reconsume) @eof(To_Data);

    TagName := (
        (
            upper @AppendUpperCaseToTagName |
            0 @AppendReplacementCharacterToTagName
        ) >1 |
        any >0 @AppendToTagName
    )* :> (
        TagNameSpace @To_BeforeAttributeName |
        '/' @To_SelfClosingStartTag |
        '>' @EmitTagToken @To_Data
    ) @eof(Reconsume) @eof(To_Data);

    RCDataLessThanSign := (
        '/' @CreateTemporaryBuffer @To_RCDataEndTagOpen
    ) @lerr(EmitLessThanSignCharacterToken) @lerr(Reconsume) @lerr(To_RCData);

    RCDataEndTagOpen := alpha @CreateEndTagToken @Reconsume @To_RCDataEndTagName @lerr(EmitLessThanSignCharacterToken) @lerr(EmitSolidusCharacterToken) @lerr(Reconsume) @lerr(To_RCData);

    RCDataEndTagName := (
        upper @AppendUpperCaseToTagName |
        lower @AppendToTagName
    )* @AppendToTemporaryBuffer :> (
        TagNameSpace when IsAppropriateEndTagToken @To_BeforeAttributeName |
        '/' when IsAppropriateEndTagToken @To_SelfClosingStartTag |
        '>' when IsAppropriateEndTagToken @EmitTagToken @To_Data
    ) @lerr(EmitLessThanSignCharacterToken) @lerr(EmitSolidusCharacterToken) @lerr(EmitTemporaryBufferCharacterToken) @lerr(Reconsume) @lerr(To_RCData);

    RawTextLessThanSign := (
        '/' @CreateTemporaryBuffer @To_RawTextEndTagOpen
    ) @lerr(EmitLessThanSignCharacterToken) @lerr(Reconsume) @lerr(To_RawText);

    RawTextEndTagOpen := alpha @CreateEndTagToken @Reconsume @To_RawTextEndTagName @lerr(EmitLessThanSignCharacterToken) @lerr(EmitSolidusCharacterToken) @lerr(Reconsume) @lerr(To_RawText);

    RawTextEndTagName := (
        upper @AppendUpperCaseToTagName |
        lower @AppendToTagName
    )* @AppendToTemporaryBuffer :> (
        TagNameSpace when IsAppropriateEndTagToken @To_BeforeAttributeName |
        '/' when IsAppropriateEndTagToken @To_SelfClosingStartTag |
        '>' when IsAppropriateEndTagToken @EmitTagToken @To_Data
    ) @lerr(EmitLessThanSignCharacterToken) @lerr(EmitSolidusCharacterToken) @lerr(EmitTemporaryBufferCharacterToken) @lerr(Reconsume) @lerr(To_RawText);

    ScriptDataLessThanSign := (
        '/' @CreateTemporaryBuffer @To_ScriptDataEndTagOpen |
        '!' @EmitLessThanSignCharacterToken @EmitExclamationMarkCharacterToken @To_ScriptDataEscapeStart
    ) @lerr(EmitLessThanSignCharacterToken) @lerr(Reconsume) @lerr(To_ScriptData);

    ScriptDataEndTagOpen := alpha @CreateEndTagToken @Reconsume @To_ScriptDataEndTagName @lerr(EmitLessThanSignCharacterToken) @lerr(EmitSolidusCharacterToken) @lerr(Reconsume) @lerr(To_ScriptData);

    ScriptDataEndTagName := (
        upper @AppendUpperCaseToTagName @AppendToTemporaryBuffer @To_ScriptDataEndTagName |
        lower @AppendToTagName @AppendToTemporaryBuffer @To_ScriptDataEndTagName
    )* :> (
        TagNameSpace when IsAppropriateEndTagToken @To_BeforeAttributeName |
        '/' when IsAppropriateEndTagToken @To_SelfClosingStartTag |
        '>' when IsAppropriateEndTagToken @EmitTagToken @To_Data
    ) @lerr(EmitLessThanSignCharacterToken) @lerr(EmitSolidusCharacterToken) @lerr(EmitTemporaryBufferCharacterToken) @lerr(Reconsume) @lerr(To_ScriptData);

    ScriptDataEscapeStart := (
        '-' @EmitHyphenMinusCharacterToken @To_ScriptDataEscapeStartDash
    ) @lerr(Reconsume) @lerr(To_ScriptData);

    ScriptDataEscapeStartDash := (
        '-' @EmitHyphenMinusCharacterToken @To_ScriptDataEscapedDashDash
    ) @lerr(Reconsume) @lerr(To_ScriptData);

    ScriptDataEscaped := (
        any @EmitCharacterToken
    )* :> (
        '-' @EmitHyphenMinusCharacterToken @To_ScriptDataEscapedDash |
        '<' @To_ScriptDataEscapedLessThanSign
    ) @eof(Reconsume) @eof(To_Data);

    ScriptDataEscapedDash := (
        (
            '-' @EmitHyphenMinusCharacterToken @To_ScriptDataEscapedDashDash |
            '<' @To_ScriptDataEscapedLessThanSign |
            UnsafeNULL @To_ScriptDataEscaped
        ) >1 |
        any >0 @EmitCharacterToken @To_ScriptDataEscaped
    ) @eof(Reconsume) @eof(To_Data);

    ScriptDataEscapedDashDash := (
        (
            '-' @EmitHyphenMinusCharacterToken @To_ScriptDataEscapedDashDash |
            '<' @To_ScriptDataEscapedLessThanSign |
            '>' @EmitGreaterThanCharacterToken @To_ScriptData |
            UnsafeNULL @To_ScriptDataEscaped
        ) >1 |
        any >0 @EmitCharacterToken @To_ScriptDataEscaped
    ) @eof(Reconsume) @eof(To_Data);

    ScriptDataEscapedLessThanSign := (
        (
            '/' @To_ScriptDataEscapedEndTagOpen |
            alpha @EmitLessThanSignCharacterToken @Reconsume @To_ScriptDataDoubleEscapeStart
        ) >CreateTemporaryBuffer |
        ^('/' | alpha) @EmitLessThanSignCharacterToken @Reconsume @To_ScriptDataEscaped
    );

    ScriptDataEscapedEndTagOpen := alpha @CreateEndTagToken @Reconsume @To_ScriptDataEscapedEndTagName @lerr(EmitLessThanSignCharacterToken) @lerr(EmitSolidusCharacterToken) @lerr(Reconsume) @lerr(To_ScriptDataEscaped);

    ScriptDataEscapedEndTagName := (
        upper @AppendUpperCaseToTagName |
        lower @AppendToTagName
    )* @AppendToTemporaryBuffer :> (
        TagNameSpace when IsAppropriateEndTagToken @To_BeforeAttributeName |
        '/' when IsAppropriateEndTagToken @To_SelfClosingStartTag |
        '>' when IsAppropriateEndTagToken @EmitTagToken @To_Data
    ) @lerr(EmitLessThanSignCharacterToken) @lerr(EmitSolidusCharacterToken) @lerr(EmitTemporaryBufferCharacterToken) @lerr(Reconsume) @lerr(To_ScriptDataEscaped);

    ScriptDataDoubleEscapeStart := (
        upper @AppendUpperCaseToTemporaryBuffer |
        lower @AppendToTemporaryBuffer
    )* @EmitCharacterToken :> (
        TagNameEnd >1 when IsTemporaryBufferScript @To_ScriptDataDoubleEscaped |
        TagNameEnd >0 @To_ScriptDataEscaped
    ) >EmitCharacterToken
    @lerr(Reconsume) @lerr(To_ScriptDataEscaped);

    ScriptDataDoubleEscaped := (
        (
            '-' @EmitHyphenMinusCharacterToken @To_ScriptDataDoubleEscapedDash |
            '<' @EmitLessThanSignCharacterToken @To_ScriptDataDoubleEscapedLessThanSign |
            UnsafeNULL
        ) >1 |
        any >0 @EmitCharacterToken
    ) @eof(Reconsume) @eof(To_Data);

    ScriptDataDoubleEscapedDash := (
        (
            '-' @EmitHyphenMinusCharacterToken @To_ScriptDataDoubleEscapedDashDash |
            '<' @EmitLessThanSignCharacterToken @To_ScriptDataDoubleEscapedLessThanSign |
            UnsafeNULL @To_ScriptDataDoubleEscaped
        ) >1 |
        any >0 @EmitCharacterToken @To_ScriptDataDoubleEscaped
    ) @eof(Reconsume) @eof(To_Data);

    ScriptDataDoubleEscapedDashDash := (
        '-' @EmitHyphenMinusCharacterToken
    )* :> (
        '<' @EmitLessThanSignCharacterToken @To_ScriptDataDoubleEscapedLessThanSign |
        '>' @EmitGreaterThanCharacterToken @To_ScriptData |
        UnsafeNULL @To_ScriptDataDoubleEscaped
    ) @eof(Reconsume) @eof(To_Data);

    ScriptDataDoubleEscapedLessThanSign := (
        '/' @CreateTemporaryBuffer @EmitSolidusCharacterToken @To_ScriptDataDoubleEscapeEnd
    ) @lerr(Reconsume) @lerr(To_ScriptDataDoubleEscaped);

    ScriptDataDoubleEscapeEnd := (
        upper @AppendUpperCaseToTemporaryBuffer |
        lower @AppendToTemporaryBuffer
    )* @EmitCharacterToken :> (
        TagNameEnd >1 when IsTemporaryBufferScript @To_ScriptDataEscaped |
        TagNameEnd >0 @To_ScriptDataDoubleEscaped
    ) >EmitCharacterToken
    @lerr(Reconsume) @lerr(To_ScriptDataDoubleEscaped);

    BeforeAttributeName := (
        TagNameSpace >2
    )* :> (
        ('/' | '>') >1 @Reconsume @To_AfterAttributeName |
        (
            '=' >1 @AppendToAttributeName |
            any >0 @Reconsume
        ) >CreateAttribute @To_AttributeName
    ) @eof(Reconsume) @eof(To_Data);

    AttributeName := (
        (
            upper @AppendUpperCaseToAttributeName |
            0 @AppendReplacementCharacterToAttributeName
        ) >1 |
        any >0 @AppendToAttributeName
    )* %AppendAttribute :> (
        TagNameEnd @Reconsume @To_AfterAttributeName |
        '=' @To_BeforeAttributeValue
    ) @eof(Reconsume) @eof(To_Data);

    AfterAttributeName := (
        TagNameSpace >2
    )* :> (
        (
            '/' @To_SelfClosingStartTag |
            '=' @To_BeforeAttributeValue |
            '>' @EmitTagToken @To_Data
        ) >1 |
        any >0 @CreateAttribute @Reconsume @To_AttributeName
    ) @eof(Reconsume) @eof(To_Data);

    BeforeAttributeValue := (
        TagNameSpace >2
    )* :> (
        (
            _StartQuote @To_AttributeValueQuoted |
            '&' @Reconsume @To_AttributeValueUnquoted |
            0 @AppendReplacementCharacterToAttributeValue @To_AttributeValueUnquoted |
            '>' @EmitTagToken @To_Data
        ) >1 |
        any >0 @AppendToAttributeValue @To_AttributeValueUnquoted
    ) @eof(Reconsume) @eof(To_Data);

    AttributeValueQuoted := (
        0 >1 @AppendReplacementCharacterToAttributeValue |
        any >0 @AppendToAttributeValue
    )* :> (
        _EndQuote @To_AfterAttributeValueQuoted
        # '&' @To_CharacterReferenceInAttributeValue
    ) @eof(Reconsume) @eof(To_Data);

    AttributeValueUnquoted := (
        0 >1 @AppendReplacementCharacterToAttributeValue |
        any >0 @AppendToAttributeValue
    )* :> (
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

    _BogusComment = (
        0 >1 @AppendReplacementCharacter |
        any >0 @AppendCharacter
    )* >StartString >eof(StartString) :> '>' @EmitComment @To_Data @eof(EmitComment) @eof(Reconsume) @eof(To_Data);

    BogusComment := _BogusComment;

    MarkupDeclarationOpen := (
        (
            '--' @StartString @To_CommentStart |
            /DOCTYPE/i @To_DocType
            '[' when IsCDataAllowed 'CDATA[' @To_CDataSection
        ) @1 |
        _BogusComment $0
    );

    CommentStart := (
        (
            '-' @To_CommentStartDash |
            '>' @EmitComment @To_Data
        ) >1 |
        (
            0 >1 @AppendReplacementCharacter |
            any >0 @AppendCharacter
        ) @To_Comment
    ) @eof(EmitComment) @eof(Reconsume) @eof(To_Data);

    CommentStartDash := (
        (
            '-' @To_CommentEnd |
            '>' @EmitComment @To_Data
        ) >1 |
        (
            0 >1 @AppendReplacementCharacter |
            any >0 @AppendCharacter
        ) >AppendHyphenMinusCharacter @To_Comment
    ) @eof(EmitComment) @eof(Reconsume) @eof(To_Data);

    Comment := (
        0 >1 @AppendReplacementCharacter |
        any >0 @AppendCharacter
    )* :> (
        '-' @To_CommentEndDash
    ) @eof(EmitComment) @eof(Reconsume) @eof(To_Data);

    CommentEndDash := (
        '-' >1 @To_CommentEnd |
        (
            0 >1 @AppendReplacementCharacter |
            any >0 @AppendCharacter
        ) >AppendHyphenMinusCharacter @To_Comment
    ) @eof(EmitComment) @eof(Reconsume) @eof(To_Data);

    CommentEnd := (
        '-' >2 @AppendHyphenMinusCharacter
    )* :> (
        (
            '>' @EmitComment @To_Data |
            '!' @To_CommentEndBang
        ) >1 |
        (
            0 >1 @AppendReplacementCharacter |
            any >0 @AppendCharacter
        ) >AppendHyphenMinusCharacter >AppendHyphenMinusCharacter @To_Comment
    ) @eof(EmitComment) @eof(Reconsume) @eof(To_Data);

    CommentEndBang := (
        (
            '>' @EmitComment @To_Data
        ) >1 |
        (
            '-' >1 @To_CommentEndDash |
            (
                0 >1 @AppendReplacementCharacter |
                any >0 @AppendCharacter
            ) @To_Comment
        ) >AppendHyphenMinusCharacter >AppendHyphenMinusCharacter >AppendExclamationMarkCharacter
    ) @eof(EmitComment) @eof(Reconsume) @eof(To_Data);

    DocType := (
        TagNameSpace >1
    )* :> (
        '>' >1 @SetForceQuirksFlag @EmitDocType @To_Data |
        any >0 @CreateDocTypeName @Reconsume @To_DocTypeName
    ) >CreateDocType >eof(CreateDocType) @eof(SetForceQuirksFlag) @eof(EmitDocType) @eof(Reconsume) @eof(To_Data);

    DocTypeName := (
        (
            0 @AppendReplacementCharacterToDocTypeName |
            upper @AppendUpperCaseToDocTypeName
        ) >1 |
        any >0 @AppendToDocTypeName
    )* :> (
        TagNameSpace |
        '>'
    ) @Reconsume @To_AfterDocTypeName @eof(Reconsume) @eof(To_AfterDocTypeName);

    AfterDocTypeName := (
        TagNameSpace >2
    )* :> (
        '>' @EmitDocType @To_Data |
        /PUBLIC/i @To_BeforeDocTypePublicIdentifier |
        /SYSTEM/i @To_BeforeDocTypeSystemIdentifier
    ) $lerr(Reconsume) $lerr(SetForceQuirksFlag) $lerr(To_BogusDocType);

    BeforeDocTypePublicIdentifier := (
        TagNameSpace >2
    )* :> (
        _StartQuote @CreatePublicIdentifier @To_DocTypePublicIdentifierQuoted
    ) @lerr(SetForceQuirksFlag) @lerr(Reconsume) @lerr(To_BogusDocType);

    DocTypePublicIdentifierQuoted := (
        0 >1 @AppendReplacementCharacterToDocTypePublicIdentifier |
        any >0 @AppendToDocTypePublicIdentifier
    )* :> (
        _EndQuote @To_BetweenDocTypePublicAndSystemIdentifiers |
        '>' @SetForceQuirksFlag @EmitDocType @To_Data
    ) @eof(SetForceQuirksFlag) @eof(EmitDocType) @eof(Reconsume) @eof(To_Data);

    BetweenDocTypePublicAndSystemIdentifiers := (
        TagNameSpace >2
    )* :> (
        _StartQuote @CreateSystemIdentifier @To_DocTypeSystemIdentifierQuoted |
        '>' @EmitDocType @To_Data
    ) @lerr(SetForceQuirksFlag) @lerr(Reconsume) @lerr(To_BogusDocType);

    BeforeDocTypeSystemIdentifier := (
        TagNameSpace >2
    )* :> (
        _StartQuote @CreateSystemIdentifier @To_DocTypeSystemIdentifierQuoted
    ) @lerr(SetForceQuirksFlag) @lerr(Reconsume) @lerr(To_BogusDocType);

    DocTypeSystemIdentifierQuoted := (
        0 >1 @AppendReplacementCharacterToDocTypeSystemIdentifier |
        any >0 @AppendToDocTypeSystemIdentifier
    )* :> (
        _EndQuote @To_AfterDocTypeSystemIdentifier |
        '>' @SetForceQuirksFlag @EmitDocType @To_Data
    ) @eof(SetForceQuirksFlag) @eof(EmitDocType) @eof(Reconsume) @eof(To_Data);

    AfterDocTypeSystemIdentifier := (
        TagNameSpace >2
    )* :> (
        '>' >1 @EmitDocType @To_Data |
        any >0 @To_BogusDocType
    ) @eof(SetForceQuirksFlag) @eof(EmitDocType) @eof(Reconsume) @eof(To_Data);

    BogusDocType := any* :> '>' @EmitDocType @To_Data @eof(EmitDocType) @eof(Reconsume) @eof(To_Data);

    CDataSection := (
        any* :>> ']]>'
    ) >StartSlice >eof(StartSlice) @EmitCompleteCData @To_Data @eof(EmitIncompleteCData) @eof(Reconsume) @eof(To_Data);
}%%