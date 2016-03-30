%%{
    machine html;

    action Reconsume { fhold; }

    include "actions.rl";

    TAB = '\t';
    LF = '\n';
    FF = '\f';

    TagNameSpace = TAB | LF | FF | ' ';

    TagNameEnd = TagNameSpace | '/' | '>';

    UnsafeNULL = 0 @EmitReplacementCharacterToken;

    PlainText = (
        UnsafeNULL |
        ^('<' | 0) @EmitCharacterToken
    );

    _BogusComment = (
        ^0 @AppendToComment |
        0 @AppendReplacementCharacterToComment
    )* >CreateComment %EmitComment $eof(EmitComment) :> '>';

    _BogusDocType = any* %EmitDocType $eof(EmitDocType) :> '>';

    main :=
    start: any @Reconsume -> Data,
    Data: (
        # '&' -> CharacterReferenceInData |
        '<' -> TagOpen |
        ^'<' @EmitCharacterToken
    ),
    RCData: (
        # '&' -> CharacterReferenceInRCData |
        '<' -> RCDataLessThanSign |
        PlainText
    ),
    RawText: (
        '<' -> RawTextLessThanSign |
        PlainText
    ),
    ScriptData: (
        '<' -> ScriptDataLessThanSign |
        PlainText
    ),
    PlainText: PlainText,
    TagOpen: (
        '!' -> MarkupDeclarationOpen |
        '/' -> EndTagOpen |
        upper @CreateStartTagToken @AppendUpperCaseToTagName -> TagName |
        lower @CreateStartTagToken @AppendToTagName -> TagName |
        '?' -> BogusComment |
        ^('!' | '/' | alpha | '?') @EmitLessThanSignCharacterToken @Reconsume -> Data
    ),
    EndTagOpen: (
        upper @CreateEndTagToken @AppendUpperCaseToTagName -> TagName |
        lower @CreateEndTagToken @AppendToTagName -> TagName |
        '>' -> Data |
        ^(alpha | '>') -> BogusComment
    ) $eof(EmitLessThanSignCharacterToken) $eof(EmitSolidusCharacterToken),
    TagName: (
        TagNameSpace -> BeforeAttributeName |
        '/' -> SelfClosingStartTag |
        '>' @EmitTagToken -> Data |
        upper @AppendUpperCaseToTagName |
        UnsafeNULL |
        ^(TagNameEnd | upper | 0) @AppendToTagName
    ),
    RCDataLessThanSign: (
        '/' @CreateTemporaryBuffer -> RCDataEndTagOpen |
        ^'/' @EmitLessThanSignCharacterToken @Reconsume -> RCData
    ),
    RCDataEndTagOpen: (
        upper @CreateEndTagToken @AppendUpperCaseToTagName @ApppendToTemporaryBuffer -> RCDataEndTagName |
        lower @CreateEndTagToken @AppendToTagName @ApppendToTemporaryBuffer -> RCDataEndTagName |
        ^alpha @EmitLessThanSignCharacterToken @EmitSolidusCharacterToken @Reconsume -> RCData
    ),
    RCDataEndTagName: (
        TagNameSpace when IsAppropriateEndTagToken -> BeforeAttributeName |
        '/' when IsAppropriateEndTagToken -> SelfClosingStartTag |
        '>' when IsAppropriateEndTagToken @EmitTagToken -> Data |
        upper @AppendUpperCaseToTagName @ApppendToTemporaryBuffer |
        lower @AppendToTagName @ApppendToTemporaryBuffer |
        ^(
            TagNameEnd when IsAppropriateEndTagToken |
            alpha
        ) @EmitLessThanSignCharacterToken @EmitSolidusCharacterToken @EmitTemporaryBufferCharacterToken @Reconsume -> RCData
    ),
    RawTextLessThanSign: (
        '/' @CreateTemporaryBuffer -> RawTextEndTagOpen |
        ^'/' @EmitLessThanSignCharacterToken @Reconsume -> RawText
    ),
    RawTextEndTagOpen: (
        upper @CreateEndTagToken @AppendUpperCaseToTagName @ApppendToTemporaryBuffer -> RawTextEndTagName |
        lower @CreateEndTagToken @AppendToTagName @ApppendToTemporaryBuffer -> RawTextEndTagName |
        ^alpha @EmitLessThanSignCharacterToken @EmitSolidusCharacterToken @Reconsume -> RawText
    ),
    RawTextEndTagName: (
        TagNameSpace when IsAppropriateEndTagToken -> BeforeAttributeName |
        '/' when IsAppropriateEndTagToken -> SelfClosingStartTag |
        '>' when IsAppropriateEndTagToken @EmitTagToken -> Data |
        upper @AppendUpperCaseToTagName @ApppendToTemporaryBuffer |
        lower @AppendToTagName @ApppendToTemporaryBuffer |
        ^(
            TagNameEnd when IsAppropriateEndTagToken |
            alpha
        ) @EmitLessThanSignCharacterToken @EmitTemporaryBufferCharacterToken @Reconsume -> RawText
    ),
    ScriptDataLessThanSign: (
        '/' @CreateTemporaryBuffer -> ScriptDataEndTagOpen |
        '!' @EmitLessThanSignExclamationMarkCharacterToken -> ScriptDataEscapeStart |
        ^('/' | '!') @EmitLessThanSignCharacterToken @Reconsume -> ScriptData
    ),
    ScriptDataEndTagOpen: (
        upper @CreateEndTagToken @AppendUpperCaseToTagName @ApppendToTemporaryBuffer -> ScriptDataEndTagName |
        lower @CreateEndTagToken @AppendToTagName @ApppendToTemporaryBuffer -> ScriptDataEndTagName |
        ^alpha @EmitLessThanSignCharacterToken @EmitSolidusCharacterToken @Reconsume -> ScriptData
    ),
    ScriptDataEndTagName: (
        TagNameSpace when IsAppropriateEndTagToken -> BeforeAttributeName |
        '/' when IsAppropriateEndTagToken -> SelfClosingStartTag |
        '>' when IsAppropriateEndTagToken @EmitTagToken -> Data |
        upper @AppendUpperCaseToTagName @ApppendToTemporaryBuffer |
        lower @AppendToTagName @ApppendToTemporaryBuffer |
        ^(
            TagNameEnd when IsAppropriateEndTagToken |
            alpha
        ) @EmitLessThanSignCharacterToken @EmitSolidusCharacterToken @Reconsume -> ScriptData
    ),
    ScriptDataEscapeStart: (
        '-' @EmitHyphenMinusCharacterToken -> ScriptDataEscapeStartDash |
        ^'-' @Reconsume -> ScriptData
    ),
    ScriptDataEscapeStartDash: (
        '-' @EmitHyphenMinusCharacterToken -> ScriptDataEscapedDashDash |
        ^'-' @Reconsume -> ScriptData
    ),
    ScriptDataEscaped: (
        '-' @EmitHyphenMinusCharacterToken -> ScriptDataEscapedDash |
        '<' -> ScriptDataEscapedLessThanSign |
        UnsafeNULL |
        ^('-' | '<' | 0) @EmitCharacterToken
    ),
    ScriptDataEscapedDash: (
        '-' @EmitHyphenMinusCharacterToken -> ScriptDataEscapedDashDash |
        '<' -> ScriptDataEscapedLessThanSign |
        UnsafeNULL -> ScriptDataEscaped |
        ^('-' | '<' | 0) @EmitCharacterToken
    ),
    ScriptDataEscapedDashDash: (
        '-' @EmitHyphenMinusCharacterToken |
        '<' -> ScriptDataEscapedLessThanSign |
        '>' @EmitGreaterThanCharacterToken -> ScriptData |
        UnsafeNULL -> ScriptDataEscaped |
        ^('-' | '<' | '>' | 0) @EmitCharacterToken -> ScriptDataEscaped
    ),
    ScriptDataEscapedLessThanSign: (
        '/' @CreateTemporaryBuffer -> ScriptDataEscapedEndTagOpen |
        upper @CreateTemporaryBuffer @AppendUpperCaseToTagName @ApppendToTemporaryBuffer @EmitLessThanSignCharacterToken @EmitCharacterToken -> ScriptDataDoubleEscapeStart |
        lower @CreateTemporaryBuffer @AppendToTagName @ApppendToTemporaryBuffer @EmitLessThanSignCharacterToken @EmitCharacterToken -> ScriptDataDoubleEscapeStart |
        ^('/' | alpha) @EmitLessThanSignCharacterToken @Reconsume -> ScriptDataEscaped
    ),
    ScriptDataEscapedEndTagOpen: (
        upper @CreateEndTagToken @AppendUpperCaseToTagName @ApppendToTemporaryBuffer -> ScriptDataEscapedEndTagName |
        lower @CreateEndTagToken @AppendToTagName @ApppendToTemporaryBuffer -> ScriptDataEscapedEndTagName |
        ^alpha @EmitLessThanSignCharacterToken @EmitSolidusCharacterToken @Reconsume -> ScriptDataEscaped
    ),
    ScriptDataEscapedEndTagName: (
        TagNameSpace when IsAppropriateEndTagToken -> BeforeAttributeName |
        '/' when IsAppropriateEndTagToken -> SelfClosingStartTag |
        '>' when IsAppropriateEndTagToken @EmitTagToken -> Data |
        upper @AppendUpperCaseToTagName @ApppendToTemporaryBuffer |
        lower @AppendToTagName @ApppendToTemporaryBuffer |
        ^(
            TagNameEnd when IsAppropriateEndTagToken |
            alpha
        ) @EmitLessThanSignCharacterToken @EmitSolidusCharacterToken @EmitTemporaryBufferCharacterToken @Reconsume -> ScriptDataEscaped
    ),
    ScriptDataDoubleEscapeStart: (
        TagNameEnd when IsTemporaryBufferScript @EmitCharacterToken -> ScriptDataDoubleEscaped |
        (TagNameEnd - (TagNameEnd when IsTemporaryBufferScript)) @EmitCharacterToken -> ScriptDataEscaped |
        upper @AppendUpperCaseToTemporaryBuffer @EmitCharacterToken |
        lower @ApppendToTemporaryBuffer @EmitCharacterToken |
        ^(TagNameEnd | alpha) @Reconsume -> ScriptDataEscaped
    ),
    ScriptDataDoubleEscaped: (
        '-' @EmitHyphenMinusCharacterToken -> ScriptDataDoubleEscapedDash |
        '<' @EmitLessThanSignCharacterToken -> ScriptDataDoubleEscapedLessThanSign |
        UnsafeNULL |
        ^('-' | '<' | 0) @EmitCharacterToken
    ),
    ScriptDataDoubleEscapedDash: (
        '-' @EmitHyphenMinusCharacterToken -> ScriptDataDoubleEscapedDashDash |
        '<' @EmitLessThanSignCharacterToken -> ScriptDataDoubleEscapedLessThanSign |
        UnsafeNULL -> ScriptDataDoubleEscaped |
        ^('-' | '<' | 0) @EmitCharacterToken -> ScriptDataDoubleEscaped
    ),
    ScriptDataDoubleEscapedDashDash: (
        '-' @EmitHyphenMinusCharacterToken |
        '<' @EmitLessThanSignCharacterToken -> ScriptDataDoubleEscapedLessThanSign |
        '>' @EmitGreaterThanCharacterToken -> ScriptData |
        UnsafeNULL -> ScriptDataDoubleEscaped |
        ^('-' | '<' | '>' | 0) @EmitCharacterToken -> ScriptDataDoubleEscaped
    ),
    ScriptDataDoubleEscapedLessThanSign: (
        '/' @CreateTemporaryBuffer @EmitSolidusCharacterToken -> ScriptDataDoubleEscapeEnd |
        ^'/' @Reconsume -> ScriptDataDoubleEscaped
    ),
    ScriptDataDoubleEscapeEnd: (
        TagNameEnd when IsTemporaryBufferScript @EmitCharacterToken -> ScriptDataEscaped |
        (TagNameEnd - (TagNameEnd when IsTemporaryBufferScript)) @EmitCharacterToken -> ScriptDataDoubleEscaped |
        upper @AppendUpperCaseToTemporaryBuffer @EmitCharacterToken |
        lower @ApppendToTemporaryBuffer @EmitCharacterToken |
        ^(TagNameEnd | alpha) @Reconsume -> ScriptDataDoubleEscaped
    ),
    BeforeAttributeName: (
        TagNameSpace |
        '/' -> SelfClosingStartTag |
        '>' @EmitTagToken -> Data |
        upper @CreateAttribute @AppendUpperCaseToAttributeName -> AttributeName |
        0 @CreateAttribute @AppendReplacementCharacterToAttributeName -> AttributeName |
        ^(TagNameSpace | '/' | '>' | upper | 0) @CreateAttribute @AppendToAttributeName -> AttributeName
    ),
    AttributeName: (
        TagNameSpace -> AfterAttributeName |
        '/' -> SelfClosingStartTag |
        '=' -> BeforeAttributeValue |
        '>' @EmitTagToken -> Data |
        upper @AppendUpperCaseToAttributeName |
        0 @AppendReplacementCharacterToAttributeName |
        ^(TagNameSpace | '/' | '=' | '>' | upper | 0) @AppendToAttributeName
    ),
    AfterAttributeName: (
        TagNameSpace |
        '/' -> SelfClosingStartTag |
        '=' -> BeforeAttributeValue |
        '>' @EmitTagToken -> Data |
        upper @CreateAttribute @AppendUpperCaseToAttributeName -> AttributeName |
        0 @CreateAttribute @AppendReplacementCharacterToAttributeName -> AttributeName |
        ^(TagNameSpace | '/' | '=' | '>' | upper | 0) @CreateAttribute @AppendToAttributeName -> AttributeName
    ),
    BeforeAttributeValue: (
        TagNameSpace |
        '"' -> AttributeValueDoubleQuoted |
        '&' @Reconsume -> AttributeValueUnquoted |
        "'" -> AttributeValueSingleQuoted |
        0 @AppendReplacementCharacterToAttributeValue -> AttributeValueUnquoted |
        '>' @EmitTagToken -> Data |
        ^(TagNameSpace | '"' | '&' | "'" | 0 | '>') @AppendToAttributeValue -> AttributeValueUnquoted
    ),
    AttributeValueDoubleQuoted: (
        '"' -> AfterAttributeValueQuoted |
        # '&' -> CharacterReferenceInAttributeValue |
        0 @AppendReplacementCharacterToAttributeValue |
        ^('"' | 0) @AppendToAttributeValue
    ),
    AttributeValueSingleQuoted: (
        "'" -> AfterAttributeValueQuoted |
        # '&' -> CharacterReferenceInAttributeValue |
        0 @AppendReplacementCharacterToAttributeValue |
        ^("'" | 0) @AppendToAttributeValue
    ),
    AttributeValueUnquoted: (
        TagNameSpace -> BeforeAttributeName |
        # '&' -> CharacterReferenceInAttributeValue |
        '>' @EmitTagToken -> Data |
        0 @AppendReplacementCharacterToAttributeValue |
        ^(TagNameSpace | '>' | 0) @AppendToAttributeValue
    ),
    AfterAttributeValueQuoted: (
        TagNameSpace -> BeforeAttributeName |
        '/' -> SelfClosingStartTag |
        '>' @EmitTagToken -> Data |
        ^(TagNameSpace | '/' | '>') @Reconsume -> BeforeAttributeName
    ),
    SelfClosingStartTag: (
        '>' @SetSelfClosingFlag @EmitTagToken -> Data |
        ^'>' @Reconsume -> BeforeAttributeName
    ),
    BogusComment: _BogusComment -> Data,
    MarkupDeclarationOpen: (
        '--' @CreateComment -> CommentStart |
        /doctype/i -> DocType |
        '[CDATA[' when AllowCData -> CDataSection |
        (_BogusComment - ((
            '--' |
            /doctype/i |
            '[CDATA[' when AllowCData
        ) any*)) -> Data
    ),
    CommentStart: (
        '-' -> CommentStartDash |
        0 @AppendReplacementCharacterToComment -> Comment |
        '>' @EmitComment -> Data |
        ^('-' | 0 | '>') @AppendToComment -> Comment
    ) $eof(EmitComment),
    CommentStartDash: (
        '-' -> CommentEnd |
        0 @AppendHyphenMinusToComment @AppendReplacementCharacterToComment -> Comment |
        '>' @EmitComment -> Data |
        ^('-' | 0 | '>') @AppendHyphenMinusToComment @AppendToComment -> Comment
    ) $eof(EmitComment),
    Comment: (
        '-' -> CommentEndDash |
        0 @AppendReplacementCharacterToComment |
        ^('-' | 0) @AppendToComment
    ) $eof(EmitComment),
    CommentEndDash: (
        '-' -> CommentEnd |
        0 @AppendHyphenMinusToComment @AppendReplacementCharacterToComment -> Comment |
        ^('-' | 0) @AppendHyphenMinusToComment @AppendToComment -> Comment
    ) $eof(EmitComment),
    CommentEnd: (
        '>' @EmitComment -> Data |
        0 @AppendHyphenMinusToComment @AppendReplacementCharacterToComment -> Comment |
        '!' -> CommentEndBang |
        '-' @AppendHyphenMinusToComment |
        ^('>' | 0 | '!' | '-') @AppendHyphenMinusToComment @AppendHyphenMinusToComment @AppendToComment -> Comment
    ) $eof(EmitComment),
    CommentEndBang: (
        '-' @AppendHyphenMinusToComment @AppendHyphenMinusToComment @AppendExclamationMarkToComment -> CommentEndDash |
        '>' @EmitComment -> Data |
        0 @AppendHyphenMinusToComment @AppendHyphenMinusToComment @AppendExclamationMarkToComment @AppendToComment -> Comment
    ) $eof(EmitComment),
    DocType: (
        TagNameSpace -> BeforeDocTypeName |
        ^TagNameSpace @Reconsume -> BeforeDocTypeName
    ) $eof(CreateDocType) $eof(SetForceQuirksFlag) $eof(EmitDocType),
    BeforeDocTypeName: (
        TagNameSpace |
        upper @CreateDocType @AppendUpperCaseToDocTypeName -> DocTypeName |
        0 @CreateDocType @AppendReplacementCharacterToDocTypeName -> DocTypeName |
        '>' @CreateDocType @SetForceQuirksFlag @EmitDocType -> Data |
        ^(TagNameSpace | upper | 0 | '>') @CreateDocType @AppendToDocTypeName -> DocTypeName
    ) $eof(CreateDocType) $eof(SetForceQuirksFlag) $eof(EmitDocType),
    DocTypeName: (
        TagNameSpace -> AfterDocTypeName |
        '>' @EmitDocType -> Data |
        upper @AppendUpperCaseToDocTypeName |
        0 @AppendReplacementCharacterToDocTypeName |
        ^(TagNameSpace | '>' | upper | 0) @AppendToDocTypeName
    ) $eof(SetForceQuirksFlag) $eof(EmitDocType),
    AfterDocTypeName: (
        TagNameSpace |
        '>' @EmitDocType -> Data |
        'PUBLIC' -> AfterDocTypePublicKeyword |
        'SYSTEM' -> AfterDocTypeSystemKeyword |
        (_BogusDocType - ((
            TagNameSpace |
            '>' |
            'PUBLIC' |
            'SYSTEM'
        ) any*)) -> Data
    ) $eof(SetForceQuirksFlag) $eof(EmitDocType),
    AfterDocTypePublicKeyword: (
        TagNameSpace -> BeforeDocTypePublicIdentifier |
        '"' @CreatePublicIdentifier -> DocTypePublicIdentifierDoubleQuoted |
        "'" @CreatePublicIdentifier -> DocTypePublicIdentifierSingleQuoted |
        '>' @SetForceQuirksFlag @EmitDocType -> Data |
        ^(TagNameSpace | '"' | "'" | '>') @SetForceQuirksFlag -> BogusDocType
    ) $eof(SetForceQuirksFlag) $eof(EmitDocType),
    BeforeDocTypePublicIdentifier: (
        TagNameSpace |
        '"' @CreatePublicIdentifier -> DocTypePublicIdentifierDoubleQuoted |
        "'" @CreatePublicIdentifier -> DocTypePublicIdentifierSingleQuoted |
        '>' @SetForceQuirksFlag @EmitDocType -> Data |
        ^(TagNameSpace | '"' | "'" | '>') @SetForceQuirksFlag -> BogusDocType
    ) $eof(SetForceQuirksFlag) $eof(EmitDocType),
    DocTypePublicIdentifierDoubleQuoted: (
        '"' -> AfterDocTypePublicIdentifier |
        0 @AppendReplacementCharacterToDocTypePublicIdentifier |
        '>' @SetForceQuirksFlag @EmitDocType -> Data |
        ^('"' | 0 | '>') @AppendToDocTypePublicIdentifier
    ) $eof(SetForceQuirksFlag) $eof(EmitDocType),
    DocTypePublicIdentifierSingleQuoted: (
        "'" -> AfterDocTypePublicIdentifier |
        0 @AppendReplacementCharacterToDocTypePublicIdentifier |
        '>' @SetForceQuirksFlag @EmitDocType -> Data |
        ^("'" | 0 | '>') @AppendToDocTypePublicIdentifier
    ) $eof(SetForceQuirksFlag) $eof(EmitDocType),
    AfterDocTypePublicIdentifier: (
        TagNameSpace -> BetweenDocTypePublicAndSystemIdentifiers |
        '>' @EmitDocType -> Data |
        '"' @CreateSystemIdentifier -> DocTypeSystemIdentifierDoubleQuoted |
        "'" @CreateSystemIdentifier -> DocTypeSystemIdentifierSingleQuoted |
        ^(TagNameSpace | '>' | '"' | "'") @SetForceQuirksFlag -> BogusDocType
    ) $eof(SetForceQuirksFlag) $eof(EmitDocType),
    BetweenDocTypePublicAndSystemIdentifiers: (
        TagNameSpace |
        '>' @EmitDocType -> Data |
        '"' @CreateSystemIdentifier -> DocTypeSystemIdentifierDoubleQuoted |
        "'" @CreateSystemIdentifier -> DocTypeSystemIdentifierSingleQuoted |
        ^(TagNameSpace | '>' | '"' | "'") @SetForceQuirksFlag -> BogusDocType
    ) $eof(SetForceQuirksFlag) $eof(EmitDocType),
    AfterDocTypeSystemKeyword: (
        TagNameSpace -> BeforeDocTypeSystemIdentifier |
        '"' @CreateSystemIdentifier -> DocTypeSystemIdentifierDoubleQuoted |
        "'" @CreateSystemIdentifier -> DocTypeSystemIdentifierSingleQuoted |
        '>' @SetForceQuirksFlag @EmitDocType -> Data |
        ^(TagNameSpace | '"' | "'" | '>') @SetForceQuirksFlag -> BogusDocType
    ) $eof(SetForceQuirksFlag) $eof(EmitDocType),
    BeforeDocTypeSystemIdentifier: (
        TagNameSpace |
        '"' @CreateSystemIdentifier -> DocTypeSystemIdentifierDoubleQuoted |
        "'" @CreateSystemIdentifier -> DocTypeSystemIdentifierSingleQuoted |
        '>' @SetForceQuirksFlag @EmitDocType -> Data |
        ^(TagNameSpace | '"' | "'" | '>') @SetForceQuirksFlag -> BogusDocType
    ) $eof(SetForceQuirksFlag) $eof(EmitDocType),
    DocTypeSystemIdentifierDoubleQuoted: (
        '"' -> AfterDocTypeSystemIdentifier |
        0 @AppendReplacementCharacterToDocTypeSystemIdentifier |
        '>' @SetForceQuirksFlag @EmitDocType -> Data |
        ^('"' | 0 | '>') @AppendToDocTypeSystemIdentifier
    ) $eof(SetForceQuirksFlag) $eof(EmitDocType),
    DocTypeSystemIdentifierSingleQuoted: (
        "'" -> AfterDocTypeSystemIdentifier |
        0 @AppendReplacementCharacterToDocTypeSystemIdentifier |
        '>' @SetForceQuirksFlag @EmitDocType -> Data |
        ^("'" | 0 | '>') @AppendToDocTypeSystemIdentifier
    ) $eof(SetForceQuirksFlag) $eof(EmitDocType),
    AfterDocTypeSystemIdentifier: (
        TagNameSpace |
        '>' @EmitDocType -> Data |
        ^(TagNameSpace | '>') -> BogusDocType
    ) $eof(SetForceQuirksFlag) $eof(EmitDocType),
    BogusDocType: _BogusDocType -> Data,
    CDataSection: (
        any* >StartCData $eof(EmitIncompleteCData) :>> ']]>' @EmitCompleteCData
    ) -> Data
    ;
}%%