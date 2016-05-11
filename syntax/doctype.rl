%%{
    machine html;

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
}%%
