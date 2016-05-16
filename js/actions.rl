%%{
    machine html;

    action SaveQuote {
        this.quote = fc;
    }

    action IsMatchingQuote { fc === this.quote }

    action StartData {
        this.charTokenKind = 'Data';
    }

    action StartRCData {
        this.charTokenKind = 'RCData';
    }

    action StartCData {
        this.charTokenKind = 'CData';
    }

    action StartSafe {
        this.charTokenKind = 'Safe';
    }

    action StartString {
        this.string = '';
    }

    action StartAppropriateEndTag {
        this.appropriateEndTagOffset = 0;
    }

    action IsAppropriateEndTagFed { this.appropriateEndTagOffset === this.lastStartTagName.length }

    action GetNextAppropriateEndTagChar { this.lastStartTagName.charCodeAt(this.appropriateEndTagOffset++) }

    action SetAppropriateEndTagName {
        this.endTagToken.name = this.lastStartTagName;
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

    action DiscardSlice {
        this.startSlice = -1;
    }

    action AppendSliceBeforeTheMark() {
        this.string += data.slice(this.startSlice, this.mark);
        $DiscardSlice
    }

    action AppendSlice() {
        this.string += data.slice(this.startSlice, p);
        $DiscardSlice
    }

    action EmitSliceBeforeTheMark() {
        this.emitToken({
            type: 'Character',
            kind: this.charTokenKind,
            value: data.slice(this.startSlice, this.mark)
        });
        $DiscardSlice
        this.charTokenKind = '';
    }

    action EmitSlice() {
        this.emitToken({
            type: 'Character',
            kind: this.charTokenKind,
            value: data.slice(this.startSlice, p)
        });
        $DiscardSlice
        this.charTokenKind = '';
    }

    action EmitString() {
        $DiscardSlice
        this.emitToken({
            type: 'Character',
            value: this.string
        });
    }

    action CreateStartTagToken {
        this.startTagToken = { type: 'StartTag', name: '', selfClosing: false, attributes: [] };
    }

    action SetStartTagName {
        this.startTagToken.name = this.string;
    }

    action SetEndTagName {
        this.endTagToken.name = this.string;
    }

    action EmitStartTagToken() {
        $DiscardSlice
        this.lastStartTagName = this.startTagToken.name;
        this.emitToken(this.startTagToken);
    }

    action EmitEndTagToken() {
        $DiscardSlice
        this.emitToken(this.endTagToken);
    }

    action SetSelfClosingFlag {
        this.startTagToken.selfClosing = true;
    }

    action EmitComment() {
        $DiscardSlice
        this.emitToken({
            type: 'Comment',
            value: this.string
        });
    }

    action EmitDocType() {
        $DiscardSlice
        this.emitToken(this.docTypeToken);
    }

    action CreateEndTagToken {
        this.endTagToken = { type: 'EndTag', name: '' };
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
        AppendAttribute: {
            for (var i = 0; i < this.startTagToken.attributes.length; i++) {
                if (this.startTagToken.attributes[i].name === this.string) {
                    break AppendAttribute;
                }
            }
            this.attribute.name = this.string;
            this.startTagToken.attributes.push(this.attribute);
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
