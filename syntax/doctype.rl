%%{
    machine html;

    DocType := (
        TagNameSpace >1 @To_BeforeDocTypeName |
        '>' >1 @Err_MissingDoctypeName @SetForceQuirksFlag @EmitToken @To_Data |
        any >0 @Err_MissingWhitespaceBeforeDoctypeName @StartSlice @To_DocTypeName
    ) >CreateDocType >eof(CreateDocType) @eof(Err_EofInDoctype) @eof(SetForceQuirksFlag) @eof(EmitToken);

    BeforeDocTypeName := TagNameSpace* <: (
        '>' >1 @Err_MissingDoctypeName @SetForceQuirksFlag @EmitToken @To_Data |
        any >0 @StartSlice @To_DocTypeName
    ) >eof(CreateDocType) @eof(Err_EofInDoctype) @eof(SetForceQuirksFlag) @eof(EmitToken);

    DocTypeName := any* %SetDocTypeName %eof(SetDocTypeName) :> (
        TagNameSpace |
        '>'
    ) @Reconsume @To_AfterDocTypeName @eof(Err_EofInDoctype) @eof(SetForceQuirksFlag) @eof(EmitToken);

    AfterDocTypeName := TagNameSpace* $eof(Err_EofInDoctype) $eof(SetForceQuirksFlag) $eof(Reconsume) $eof(To_BogusDocType) (
        (
            '>' @EmitToken @To_Data |
            /PUBLIC/i @To_AfterDocTypePublicKeyword |
            /SYSTEM/i @To_AfterDocTypeSystemKeyword
        ) @err(Err_InvalidCharacterSequenceAfterDoctypeName)
    )? $err(SetForceQuirksFlag) $err(Reconsume) $err(To_BogusDocType);

     AfterDocTypePublicKeyword := (
         TagNameSpace >1 @To_BeforeDocTypePublicIdentifier |
        _StartQuote >1 @Err_MissingSpaceAfterDoctypePublicKeyword @To_DocTypePublicIdentifierQuoted |
        any >0 @Reconsume @To_BeforeDocTypePublicIdentifier
    ) @eof(Err_EofInDoctype) @eof(SetForceQuirksFlag) @eof(EmitToken);

    BeforeDocTypePublicIdentifier := TagNameSpace* <: (
        _StartQuote >1 @To_DocTypePublicIdentifierQuoted |
        '>' >1 @Err_MissingDoctypePublicIdentifier @SetForceQuirksFlag @EmitToken @To_Data |
        any >0 @Err_MissingQuoteBeforeDoctypePublicIdentifier @SetForceQuirksFlag @Reconsume @To_BogusDocType
    ) @eof(Err_EofInDoctype) @eof(SetForceQuirksFlag) @eof(EmitToken);

    DocTypePublicIdentifierQuoted := any* >StartSlice >eof(StartSlice) %SetDocTypePublicIdentifier %eof(SetDocTypePublicIdentifier) :> (
        _EndQuote @To_AfterDocTypePublicIdentifier |
        '>' @Err_AbruptDoctypePublicIdentifier @SetForceQuirksFlag @EmitToken @To_Data
    ) @eof(Err_EofInDoctype) @eof(SetForceQuirksFlag) @eof(EmitToken);

    AfterDocTypePublicIdentifier := (
        (
            TagNameSpace @To_BetweenDocTypePublicAndSystemIdentifiers |
            _StartQuote @Err_MissingWhitespaceBetweenDoctypePublicAndSystemIdentifiers @To_DocTypeSystemIdentifierQuoted |
            '>' @EmitToken @To_Data
        ) >1 |
        any >0 @Err_MissingQuoteBeforeDoctypeSystemIdentifier @SetForceQuirksFlag @Reconsume @To_BogusDocType
    ) @eof(Err_EofInDoctype) @eof(SetForceQuirksFlag) @eof(EmitToken);

    BetweenDocTypePublicAndSystemIdentifiers := TagNameSpace* <: (
        (
            _StartQuote @To_DocTypeSystemIdentifierQuoted |
            '>' @EmitToken @To_Data
        ) >1 |
        any >0 @Err_MissingQuoteBeforeDoctypeSystemIdentifier @SetForceQuirksFlag @Reconsume @To_BogusDocType
    ) @eof(Err_EofInDoctype) @eof(SetForceQuirksFlag) @eof(EmitToken);

    AfterDocTypeSystemKeyword := (
        TagNameSpace >1 @To_BeforeDocTypeSystemIdentifier |
        _StartQuote >1 @Err_MissingSpaceAfterDoctypeSystemKeyword @To_DocTypeSystemIdentifierQuoted |
        any >0 @Reconsume @To_BeforeDocTypeSystemIdentifier
    ) @eof(Err_EofInDoctype) @eof(SetForceQuirksFlag) @eof(EmitToken);

    BeforeDocTypeSystemIdentifier := TagNameSpace* <: (
        _StartQuote >1 @To_DocTypeSystemIdentifierQuoted |
        '>' >1 @Err_MissingDoctypeSystemIdentifier @SetForceQuirksFlag @EmitToken @To_Data |
        any >0 @Err_MissingQuoteBeforeDoctypeSystemIdentifier @SetForceQuirksFlag @Reconsume @To_BogusDocType
    ) @eof(Err_EofInDoctype) @eof(SetForceQuirksFlag) @eof(EmitToken);

    DocTypeSystemIdentifierQuoted := any* >StartSlice >eof(StartSlice) %SetDocTypeSystemIdentifier %eof(SetDocTypeSystemIdentifier) :> (
        _EndQuote @To_AfterDocTypeSystemIdentifier |
        '>' @Err_AbruptDoctypeSystemIdentifier @SetForceQuirksFlag @EmitToken @To_Data
    ) @eof(Err_EofInDoctype) @eof(SetForceQuirksFlag) @eof(EmitToken);

    AfterDocTypeSystemIdentifier := TagNameSpace* <: (
        '>' >1 @EmitToken @To_Data |
        any >0 @Err_UnexpectedCharacterAfterDoctypeSystemIdentifier @Reconsume @To_BogusDocType
    ) @eof(Err_EofInDoctype) @eof(SetForceQuirksFlag) @eof(EmitToken);

    BogusDocType := any* :> '>' @EmitToken @To_Data @eof(EmitToken);
}%%
