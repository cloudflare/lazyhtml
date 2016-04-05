%%{
    machine html;

    action SaveQuote {
        this.quote = fc;
    }

    action IsMatchingQuote { fc === this.quote }

    action EmitReplacementCharacterToken {
        this.emitToken({
            type: 'Character',
            value: '\uFFFD'
        });
    }

    action EmitCharacterToken {
        this.emitToken({
            type: 'Character',
            value: data[p]
        });
    }

    action AppendToComment {
        this.commentToken.value += data[p];
    }

    action CreateStartTagToken {
        this.tagToken = { type: 'StartTag', name: '', selfClosing: false, attributes: [] };
    }

    action AppendUpperCaseToTagName {
        this.tagToken.name += data[p].toLowerCase();
    }

    action AppendToTagName {
        this.tagToken.name += data[p];
    }

    action AppendReplacementCharacterToTagName {
        this.tagToken.name += '\uFFFD';
    }

    action EmitLessThanSignCharacterToken {
        this.emitToken({
            type: 'Character',
            value: '<'
        });
    }

    action EmitTagToken {
        if (this.tagToken.type === 'StartTag') {
            this.lastStartTagName = this.tagToken.name;
        }
        this.emitToken(this.tagToken);
    }

    action CreateTemporaryBuffer {
        this.tempBuf = '';
    }

    action AppendToTemporaryBuffer {
        this.tempBuf += data[p];
    }

    action IsAppropriateEndTagToken { this.tagToken.name === this.lastStartTagName }

    action EmitTemporaryBufferCharacterToken {
        this.emitToken({
            type: 'Character',
            value: this.tempBuf
        });
    }

    action IsTemporaryBufferScript { this.tempBuf === 'script' }

    action SetSelfClosingFlag {
        this.tagToken.selfClosing = true;
    }

    action AppendReplacementCharacterToComment {
        this.commentToken.value += '\uFFFD';
    }

    action CreateComment {
        this.commentToken = { type: 'Comment', value: '' };
    }

    action EmitComment {
        this.emitToken(this.commentToken);
    }

    action EmitDocType {
        this.emitToken(this.docTypeToken);
    }

    action CreateEndTagToken {
        this.tagToken = { type: 'EndTag', name: '' };
    }

    action EmitSolidusCharacterToken {
        this.emitToken({
            type: 'Character',
            value: '/'
        });
    }

    action EmitExclamationMarkCharacterToken {
        this.emitToken({
            type: 'Character',
            value: '!'
        });
    }

    action EmitHyphenMinusCharacterToken {
        this.emitToken({
            type: 'Character',
            value: '-'
        });
    }

    action EmitGreaterThanCharacterToken {
        this.emitToken({
            type: 'Character',
            value: '>'
        });
    }

    action AppendUpperCaseToTemporaryBuffer {
        this.tempBuf += data[p].toLowerCase();
    }

    action CreateAttribute {
        this.attribute = {
            name: '',
            value: ''
        };
    }

    action AppendUpperCaseToAttributeName {
        this.attribute.name += data[p].toLowerCase();
    }

    action AppendReplacementCharacterToAttributeName {
        this.attribute.name += '\uFFFD';
    }

    action AppendToAttributeName {
        this.attribute.name += data[p];
    }

    action AppendReplacementCharacterToAttributeValue {
        this.attribute.value += '\uFFFD';
    }

    action AppendToAttributeValue {
        this.attribute.value += data[p];
    }

    action AppendAttribute {
        if (this.tagToken.type === 'StartTag' && !this.tagToken.attributes.some(attr => attr.name === this.attribute.name)) {
            this.tagToken.attributes.push(this.attribute);
        }
    }

    action IsCDataAllowed { this.allowCData }

    action AppendHyphenMinusToComment {
        this.commentToken.value += '-';
    }

    action AppendExclamationMarkToComment {
        this.commentToken.value += '!';
    }

    action CreateDocType {
        this.docTypeToken = { type: 'DocType', name: null, forceQuirks: false, publicId: null, systemId: null };
    }

    action CreateDocTypeName {
        this.docTypeToken.name = '';
    }

    action SetForceQuirksFlag {
        this.docTypeToken.forceQuirks = true;
    }

    action AppendUpperCaseToDocTypeName {
        this.docTypeToken.name += data[p].toLowerCase();
    }

    action AppendReplacementCharacterToDocTypeName {
        this.docTypeToken.name += '\uFFFD';
    }

    action AppendToDocTypeName {
        this.docTypeToken.name += data[p];
    }

    action CreatePublicIdentifier {
        this.docTypeToken.publicId = '';
    }

    action AppendReplacementCharacterToDocTypePublicIdentifier {
        this.docTypeToken.publicId += '\uFFFD';
    }

    action AppendToDocTypePublicIdentifier {
        this.docTypeToken.publicId += data[p];
    }

    action CreateSystemIdentifier {
        this.docTypeToken.systemId = '';
    }

    action AppendReplacementCharacterToDocTypeSystemIdentifier {
        this.docTypeToken.systemId += '\uFFFD';
    }

    action AppendToDocTypeSystemIdentifier {
        this.docTypeToken.systemId += data[p];
    }

    action StartCData {
        this.startCData = p;
    }

    action EmitIncompleteCData {
        this.emitToken({
            type: 'CData',
            value: data.slice(this.startCData)
        });
    }

    action EmitCompleteCData {
        this.emitToken({
            type: 'CData',
            value: data.slice(this.startCData, p - 2)
        });
    }
}%%
