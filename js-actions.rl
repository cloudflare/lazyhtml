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

    action StartSlice {
        this.startSlice = p;
    }

    action StartSlice2 {
        this.startSlice2 = p;
    }

    action AppendSlice {
        this.string += data.slice(this.startSlice, p);
    }

    action AppendSlice2 {
        this.string += data.slice(this.startSlice2, p);
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

    action CreateStartTagToken {
        this.tagToken = { type: 'StartTag', name: '', selfClosing: false, attributes: [] };
    }

    action SetTagName {
        this.tagToken.name = this.string;
    }

    action EmitTagToken {
        if (this.tagToken.type === 'StartTag') {
            this.lastStartTagName = this.tagToken.name;
        }
        this.emitToken(this.tagToken);
    }

    action IsAppropriateEndTagToken { this.string === this.lastStartTagName }

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
