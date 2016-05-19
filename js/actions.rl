%%{
    machine html;

    action SaveQuote {
        this.quote = fc;
    }

    action IsMatchingQuote { fc === this.quote }

    action StartData {
        this.token = {
            type: 'Character',
            kind: 'Data',
            value: ''
        };
    }

    action StartRCData {
        this.token = {
            type: 'Character',
            kind: 'RCData',
            value: ''
        };
    }

    action StartCData {
        this.token = {
            type: 'Character',
            kind: 'CData',
            value: ''
        };
    }

    action StartSafe {
        this.token = {
            type: 'Character',
            kind: 'Safe',
            value: ''
        };
    }

    action StartAppropriateEndTag {
        this.appropriateEndTagOffset = 0;
    }

    action IsAppropriateEndTagFed { this.appropriateEndTagOffset === this.lastStartTagName.length }

    action FeedAppropriateEndTag() { !($IsAppropriateEndTagFed) && this.lastStartTagName.charCodeAt(this.appropriateEndTagOffset++) === (fc | 0x20) }

    action SetAppropriateEndTagName {
        this.token.name = this.lastStartTagName;
    }

    action StartSlice {
        this.startSlice = p;
    }

    action MarkPosition {
        this.mark = p;
    }

    action UnmarkPosition {
        this.mark = -1;
    }

    action AdvanceMarkedPosition {
        this.mark++;
    }

    action EmitToken {
        this.emitToken(this.token, data.slice(this.tokenStart, this.tokenStart = p + 1));
        this.token = null;
    }

    action EndText {
        this.token.value = data.slice(this.startSlice, this.mark >= 0 ? this.mark : p);
    }

    action AsRawSlice {
        this.token = {
            type: 'Character',
            kind: '',
            value: ''
        };
    }

    action EmitSlice() {
        $EndText
        p--;
        $EmitToken
        p++;
    }

    action CreateStartTagToken {
        this.token = { type: 'StartTag', name: '', selfClosing: false, attributes: [] };
    }

    action SetStartTagName {
        this.token.name = data.slice(this.startSlice, p);
    }

    action SetEndTagName {
        this.token.name = data.slice(this.startSlice, p);
    }

    action SetLastStartTagName {
        this.lastStartTagName = this.token.name;
    }

    action SetSelfClosingFlag {
        this.token.selfClosing = true;
    }

    action EmitComment() {
        this.token = {
            type: 'Comment',
            value: data.slice(this.startSlice, this.mark)
        };
        $EmitToken
        $UnmarkPosition
    }

    action CreateEndTagToken {
        this.token = { type: 'EndTag', name: '' };
    }

    action CreateAttribute {
        this.attribute = {
            name: '',
            value: ''
        };
    }

    action SetAttributeValue {
        this.attribute.value = data.slice(this.startSlice, p);
    }

    action AppendAttribute {
        this.attribute.name = data.slice(this.startSlice, p);
        this.token.attributes.push(this.attribute);
    }

    action IsCDataAllowed { this.allowCData }

    action CreateDocType {
        this.token = { type: 'DocType', name: null, forceQuirks: false, publicId: null, systemId: null };
    }

    action SetDocTypeName {
        this.token.name = data.slice(this.startSlice, p);
    }

    action SetForceQuirksFlag {
        this.token.forceQuirks = true;
    }

    action SetDocTypePublicIdentifier {
        this.token.publicId = data.slice(this.startSlice, p);
    }

    action SetDocTypeSystemIdentifier {
        this.token.systemId = data.slice(this.startSlice, p);
    }
}%%
