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

    action FeedAppropriateEndTag() { !($IsAppropriateEndTagFed) && this.lastStartTagName.charCodeAt(this.appropriateEndTagOffset++) === (fc | 0x20) }

    action SetAppropriateEndTagName {
        this.endTagToken.name = this.lastStartTagName;
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

    action EmitSlice() {
        this.emitToken({
            type: 'Character',
            kind: this.charTokenKind,
            value: data.slice(this.startSlice, this.mark)
        });
        $DiscardSlice
        this.charTokenKind = '';
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

    action SetAttributeValue() {
        this.attribute.value = data.slice(this.startSlice, p);
        $DiscardSlice
    }

    action AppendAttribute() {
        this.attribute.name = data.slice(this.startSlice, p);
        $DiscardSlice
        this.startTagToken.attributes.push(this.attribute);
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
