%%{
    machine html;

    action SaveQuote {
        this.quote = fc;
    }

    action IsMatchingQuote { fc === this.quote }

    action StartString {
        this.string = '';
    }

    action AppendCharacter {
        this.string += data[p];
    }

    action AppendLowerCasedCharacter {
        this.string += String.fromCharCode(fc + 0x20);
    }

    action AppendReplacementCharacter {
        this.string += '\uFFFD';
    }

    action AppendHyphenMinusCharacter {
        this.string += '-';
    }

    action AppendDoubleHyphenMinusCharacter {
        this.string += '--';
    }

    action AppendExclamationMarkCharacter {
        this.string += '!';
    }

    action AppendRightBracketCharacter {
        this.string += ']';
    }

    action AppendDoubleRightBracketCharacter {
        this.string += ']]';
    }

    action StartSlice {
        this.startSlice = p;
    }

    action AppendSlice {
        this.string += data.slice(this.startSlice, p);
    }

    action EmitString {
        this.emitToken({
            type: 'Character',
            value: this.string
        });
    }

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

    action CreateStartTagToken {
        this.tagToken = { type: 'StartTag', name: '', selfClosing: false, attributes: [] };
    }

    action SetTagName {
        this.tagToken.name = this.string;
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

    action IsAppropriateEndTagToken { this.string === this.lastStartTagName }

    action EmitTemporaryBufferCharacterToken {
        this.emitToken({
            type: 'Character',
            value: this.tempBuf
        });
    }

    action IsTemporaryBufferScript { this.tempBuf === 'script' }

    action SetSelfClosingFlag {
        if (this.tagToken.type === 'StartTag') {
            this.tagToken.selfClosing = true;
        }
    }

    action EmitComment {
        this.emitToken({
            type: 'Comment',
            value: this.string
        });
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

    action AppendUpperCaseToTemporaryBuffer {
        this.tempBuf += data[p].toLowerCase();
    }

    action CreateAttribute {
        this.attribute = {
            name: '',
            value: ''
        };
    }

    action SetAttributeValue {
        this.attribute.value = this.string;
    }

    action AppendAttribute {
        AppendAttribute: if (this.tagToken.type === 'StartTag') {
            for (var i = 0; i < this.tagToken.attributes.length; i++) {
                if (this.tagToken.attributes[i].name === this.string) {
                    break AppendAttribute;
                }
            }
            this.attribute.name = this.string;
            this.tagToken.attributes.push(this.attribute);
        }
    }

    action IsCDataAllowed { this.allowCData }

    action CreateDocType {
        this.docTypeToken = { type: 'DocType', name: null, forceQuirks: false, publicId: null, systemId: null };
    }

    action SetDocTypeName {
        this.docTypeToken.name = this.string;
    }

    action SetForceQuirksFlag {
        this.docTypeToken.forceQuirks = true;
    }

    action SetDocTypePublicIdentifier {
        this.docTypeToken.publicId = this.string;
    }

    action SetDocTypeSystemIdentifier {
        this.docTypeToken.systemId = this.string;
    }
}%%
