%%{
    machine html;

    DocType := TagNameSpace* <: (
        '>' >1 @SetForceQuirksFlag @EmitToken @To_Data |
        any >0 @Reconsume @To_DocTypeName
    ) >CreateDocType >eof(CreateDocType) @eof(SetForceQuirksFlag) @eof(EmitToken);

    DocTypeName := any* >StartSlice %SetDocTypeName %eof(SetDocTypeName) :> (
        TagNameSpace |
        '>'
    ) @Reconsume @To_AfterDocTypeName @eof(SetForceQuirksFlag) @eof(EmitToken);

    AfterDocTypeName := TagNameSpace* (
        '>' @EmitToken @To_Data |
        /PUBLIC/i @To_BeforeDocTypePublicIdentifier |
        /SYSTEM/i @To_BeforeDocTypeSystemIdentifier
    ) @err(SetForceQuirksFlag) @err(Reconsume) @err(To_BogusDocType);

    BeforeDocTypePublicIdentifier := TagNameSpace* <: (
        _StartQuote >1 @To_DocTypePublicIdentifierQuoted |
        any >0 @SetForceQuirksFlag @Reconsume @To_BogusDocType
    ) @eof(SetForceQuirksFlag) @eof(EmitToken);

    DocTypePublicIdentifierQuoted := any* >StartSlice %SetDocTypePublicIdentifier %eof(SetDocTypePublicIdentifier) :> (
        _EndQuote @To_BetweenDocTypePublicAndSystemIdentifiers |
        '>' @SetForceQuirksFlag @EmitToken @To_Data
    ) @eof(SetForceQuirksFlag) @eof(EmitToken);

    BetweenDocTypePublicAndSystemIdentifiers := TagNameSpace* <: (
        (
            _StartQuote @To_DocTypeSystemIdentifierQuoted |
            '>' @EmitToken @To_Data
        ) >1 |
        any >0 @SetForceQuirksFlag @Reconsume @To_BogusDocType
    ) @eof(SetForceQuirksFlag) @eof(EmitToken);

    BeforeDocTypeSystemIdentifier := TagNameSpace* <: (
        _StartQuote >1 @To_DocTypeSystemIdentifierQuoted |
        any >0 @SetForceQuirksFlag @Reconsume @To_BogusDocType
    ) @eof(SetForceQuirksFlag) @eof(EmitToken);

    DocTypeSystemIdentifierQuoted := any* >StartSlice %SetDocTypeSystemIdentifier %eof(SetDocTypeSystemIdentifier) :> (
        _EndQuote @To_AfterDocTypeSystemIdentifier |
        '>' @SetForceQuirksFlag @EmitToken @To_Data
    ) @eof(SetForceQuirksFlag) @eof(EmitToken);

    AfterDocTypeSystemIdentifier := TagNameSpace* <: (
        any @Reconsume @To_BogusDocType
    ) @eof(SetForceQuirksFlag) @eof(EmitToken);

    BogusDocType := any* :> '>' @EmitToken @To_Data @eof(EmitToken);
}%%
