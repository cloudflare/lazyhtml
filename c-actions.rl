%%{
    machine html;

    action EmitReplacementCharacterToken {
        printf("CharacterToken(NULL)\n");
    }

    action EmitCharacterToken {
        printf("CharacterToken('%c')\n", fc);
    }

    action AppendToComment {
        printf("Comment.value += '%c'\n", fc);
    }

    action CreateStartTagToken {
        printf("TagToken = { kind: 'start' }\n");
    }

    action AppendUpperCaseToTagName {
        printf("TagToken.name += '%c'\n", ufc);
    }

    action AppendToTagName {
        printf("TagToken.name += '%c'\n", fc);
    }

    action EmitLessThanSignCharacterToken {
        printf("CharacterToken('<')\n");
    }

    action EmitTagToken {
        printf("TagToken.emit()\n");
    }

    action CreateTemporaryBuffer {
        printf("TempBuf = ''\n");
    }

    action ApppendToTemporaryBuffer {
        printf("TempBuf += '%c'\n", fc);
    }

    action IsAppropriateEndTagToken { printf("IsAppropriateEndTagToken?\n"), 1 }

    action EmitTemporaryBufferCharacterToken {
        printf("CharacterToken(TempBuf)\n");
    }

    action IsTemporaryBufferScript { printf("IsTemporaryBufferScript?\n"), 1 }

    action SetSelfClosingFlag {
        printf("TagToken.selfClosing = true\n");
    }

    action AppendReplacementCharacterToComment {
        printf("Comment += NULL\n");
    }

    action CreateComment {
        printf("Comment = { value: '' }\n");
    }

    action EmitComment {
        printf("Comment.emit()\n");
    }

    action EmitDocType {
        printf("DocType.emit()\n");
    }

    action CreateEndTagToken {
        printf("TagToken = { kind: 'end' }\n");
    }

    action EmitSolidusCharacterToken {
        printf("CharacterToken('/')\n");
    }

    action EmitExclamationMarkCharacterToken {
        printf("CharacterToken('!')\n");
    }

    action EmitHyphenMinusCharacterToken {
        printf("CharacterToken('-')\n");
    }

    action EmitGreaterThanCharacterToken {
        printf("CharacterToken('>')\n");
    }

    action AppendUpperCaseToTemporaryBuffer {
        printf("TempBuf += '%c'\n", ufc);
    }

    action CreateAttribute {
        printf("Attribute = { name: '', value: '' }\n");
    }

    action AppendUpperCaseToAttributeName {
        printf("Attribute.name += '%c'\n", ufc);
    }

    action AppendReplacementCharacterToAttributeName {
        printf("Attribute.name += NULL\n");
    }

    action AppendToAttributeName {
        printf("Attribute.name += '%c'\n", fc);
    }

    action AppendReplacementCharacterToAttributeValue {
        printf("Attribute.value += NULL\n");
    }

    action AppendToAttributeValue {
        printf("Attribute.value += '%c'\n", fc);
    }

    action IsCDataAllowed { printf("IsCDataAllowed?\n"), 1 }

    action AppendHyphenMinusToComment {
        printf("Comment.value += '-'\n");
    }

    action AppendExclamationMarkToComment {
        printf("Comment.value += '!'\n");
    }

    action CreateDocType {
        printf("DocType = {}\n");
    }

    action SetForceQuirksFlag {
        printf("DocType.forceQuirks = true\n");
    }

    action AppendUpperCaseToDocTypeName {
        printf("DocType.name += '%c'\n", ufc);
    }

    action AppendReplacementCharacterToDocTypeName {
        printf("DocType.name += NULL\n");
    }

    action AppendToDocTypeName {
        printf("DocType.name += '%c'\n", fc);
    }

    action CreatePublicIdentifier {
        printf("DocType.publicId = ''\n");
    }

    action AppendReplacementCharacterToDocTypePublicIdentifier {
        printf("DocType.publicId += NULL\n");
    }

    action AppendToDocTypePublicIdentifier {
        printf("DocType.publicId += '%c'\n", fc);
    }

    action CreateSystemIdentifier {
        printf("DocType.systemId = ''\n");
    }

    action AppendReplacementCharacterToDocTypeSystemIdentifier {
        printf("DocType.systemId += NULL\n");
    }

    action AppendToDocTypeSystemIdentifier {
        printf("DocType.systemId += '%c'\n", fc);
    }

    action StartCData {
        printf("StartCData\n");
    }

    action EmitIncompleteCData {
        printf("EmitIncompleteCData\n");
    }

    action EmitCompleteCData {
        printf("EmitCompleteCData\n");
    }
}%%
