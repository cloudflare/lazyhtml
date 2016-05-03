%%{
    machine html;

    action SaveQuote {
        this.quote = fc;
    }

    action IsMatchingQuote { fc === this.quote }

    action StartString {
        this.string = '';
    }

    action AppendEqualsCharacter {
        this.string += '=';
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

    action MarkPosition {
        this.mark = p;
    }

    action AdvanceMarkedPosition {
        this.mark++;
    }

    action AppendSliceBeforeTheMark {
        this.string += data.slice(this.startSlice, this.mark);
    }

    action AppendSliceAfterTheMark {
        this.string += data.slice(this.mark, p);
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

    action StartNumericEntity {
        this.numericEntity = 0;
    }

    action AppendHexDigit09ToNumericEntity {
        this.numericEntity = this.numericEntity * 16 + (fc & 0xF);
    }

    action AppendHexDigitAFToNumericEntity {
        this.numericEntity = this.numericEntity * 16 + ((fc + 9) & 0xF);
    }

    action AppendDecDigitToNumericEntity {
        this.numericEntity = this.numericEntity * 10 + (fc & 0xF);
    }

    action AppendNumericEntity {
        this.string += getNumericEntity(this.numericEntity);
    }

    action StartNamedEntity {
        this.namedEntityOffset = 1;
    }

    action UnmatchNamedEntity {
        this.namedEntityMatch = 0;
    }

    action FeedNamedEntity {
        var min = 0;
        var max = namedEntityHandlers[this.namedEntityOffset++] - 1;
        var ch = fc;

        while (min <= max) {
            var i = (min + max) >> 1;
            var curPos = this.namedEntityOffset + i * 3;
            var curCh = namedEntityHandlers[curPos];

            if (curCh < ch) {
                min = i + 1;
            } else if (curCh > ch) {
                max = i - 1;
            } else {
                var action = namedEntityHandlers[++curPos];
                if (action > 0) {
                    this.namedEntityMatch = action;
                    this.namedEntityPos = p;
                }
                this.namedEntityOffset = namedEntityHandlers[++curPos];
                break;
            }
        }

        if (min > max || namedEntityHandlers[this.namedEntityOffset] === 0) {
            this.namedEntityOffset = 0;
        }
    }

    action AppendNamedEntity() {
        if (this.namedEntityMatch > 0) {
            $AppendSliceBeforeTheMark
            this.string += namedEntityValues[this.namedEntityMatch];
            this.startSlice = this.namedEntityPos + 1;
        }
    }
}%%
