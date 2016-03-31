%%{
    machine html;

    action EmitReplacementCharacterToken {
        console.log("CharacterToken(NULL)");
    }

    action EmitCharacterToken {
        console.log("CharacterToken('%s')", data[p]);
    }

    action AppendToComment {
        console.log("Comment.value += '%s'", data[p]);
    }

    action CreateStartTagToken {
        console.log("TagToken = { kind: 'start' }");
    }

    action AppendUpperCaseToTagName {
        console.log("TagToken.name += '%s'", data[p].toLowerCase());
    }

    action AppendToTagName {
        console.log("TagToken.name += '%s'", data[p]);
    }

    action EmitLessThanSignCharacterToken {
        console.log("CharacterToken('<')");
    }

    action EmitTagToken {
        console.log("TagToken.emit()");
    }

    action CreateTemporaryBuffer {
        console.log("TempBuf = ''");
    }

    action ApppendToTemporaryBuffer {
        console.log("TempBuf += '%s'", data[p]);
    }

    action IsAppropriateEndTagToken { console.log("IsAppropriateEndTagToken?"), 1 }

    action EmitTemporaryBufferCharacterToken {
        console.log("CharacterToken(TempBuf)");
    }

    action IsTemporaryBufferScript { console.log("IsTemporaryBufferScript?"), 1 }

    action SetSelfClosingFlag {
        console.log("TagToken.selfClosing = true");
    }

    action AppendReplacementCharacterToComment {
        console.log("Comment += NULL");
    }

    action CreateComment {
        console.log("Comment = { value: '' }");
    }

    action EmitComment {
        console.log("Comment.emit()");
    }

    action EmitDocType {
        console.log("DocType.emit()");
    }

    action CreateEndTagToken {
        console.log("TagToken = { kind: 'end' }");
    }

    action EmitSolidusCharacterToken {
        console.log("CharacterToken('/')");
    }

    action EmitExclamationMarkCharacterToken {
        console.log("CharacterToken('!')");
    }

    action EmitHyphenMinusCharacterToken {
        console.log("CharacterToken('-')");
    }

    action EmitGreaterThanCharacterToken {
        console.log("CharacterToken('>')");
    }

    action AppendUpperCaseToTemporaryBuffer {
        console.log("TempBuf += '%s'", data[p].toLowerCase());
    }

    action CreateAttribute {
        console.log("Attribute = { name: '', value: '' }");
    }

    action AppendUpperCaseToAttributeName {
        console.log("Attribute.name += '%s'", data[p].toLowerCase());
    }

    action AppendReplacementCharacterToAttributeName {
        console.log("Attribute.name += NULL");
    }

    action AppendToAttributeName {
        console.log("Attribute.name += '%s'", data[p]);
    }

    action AppendReplacementCharacterToAttributeValue {
        console.log("Attribute.value += NULL");
    }

    action AppendToAttributeValue {
        console.log("Attribute.value += '%s'", data[p]);
    }

    action IsCDataAllowed { console.log("IsCDataAllowed?"), 1 }

    action AppendHyphenMinusToComment {
        console.log("Comment.value += '-'");
    }

    action AppendExclamationMarkToComment {
        console.log("Comment.value += '!'");
    }

    action CreateDocType {
        console.log("DocType = {}");
    }

    action SetForceQuirksFlag {
        console.log("DocType.forceQuirks = true");
    }

    action AppendUpperCaseToDocTypeName {
        console.log("DocType.name += '%s'", data[p].toLowerCase());
    }

    action AppendReplacementCharacterToDocTypeName {
        console.log("DocType.name += NULL");
    }

    action AppendToDocTypeName {
        console.log("DocType.name += '%s'", data[p]);
    }

    action CreatePublicIdentifier {
        console.log("DocType.publicId = ''");
    }

    action AppendReplacementCharacterToDocTypePublicIdentifier {
        console.log("DocType.publicId += NULL");
    }

    action AppendToDocTypePublicIdentifier {
        console.log("DocType.publicId += '%s'", data[p]);
    }

    action CreateSystemIdentifier {
        console.log("DocType.systemId = ''");
    }

    action AppendReplacementCharacterToDocTypeSystemIdentifier {
        console.log("DocType.systemId += NULL");
    }

    action AppendToDocTypeSystemIdentifier {
        console.log("DocType.systemId += '%s'", data[p]);
    }

    action StartCData {
        console.log("StartCData");
    }

    action EmitIncompleteCData {
        console.log("EmitIncompleteCData");
    }

    action EmitCompleteCData {
        console.log("EmitCompleteCData");
    }
}%%
