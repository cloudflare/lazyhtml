%%{
    machine html;

    access this.;

    include 'js-actions.rl';
    include 'syntax.rl';

    write data nofinal noprefix;
}%%

var states = exports.states = {
    error,
    Data: en_Data,
    RCData: en_RCData,
    RawText: en_RawText,
    ScriptData: en_ScriptData,
    PlainText: en_PlainText,
    TagOpen: en_TagOpen,
    EndTagOpen: en_EndTagOpen,
    TagName: en_TagName,
    RCDataLessThanSign: en_RCDataLessThanSign,
    RawTextLessThanSign: en_RawTextLessThanSign,
    ScriptDataLessThanSign: en_ScriptDataLessThanSign,
    ScriptDataEscapeStart: en_ScriptDataEscapeStart,
    ScriptDataEscapeStartDash: en_ScriptDataEscapeStartDash,
    ScriptDataEscaped: en_ScriptDataEscaped,
    ScriptDataEscapedDash: en_ScriptDataEscapedDash,
    ScriptDataEscapedDashDash: en_ScriptDataEscapedDashDash,
    ScriptDataEscapedLessThanSign: en_ScriptDataEscapedLessThanSign,
    ScriptDataDoubleEscaped: en_ScriptDataDoubleEscaped,
    ScriptDataDoubleEscapedDash: en_ScriptDataDoubleEscapedDash,
    ScriptDataDoubleEscapedDashDash: en_ScriptDataDoubleEscapedDashDash,
    ScriptDataDoubleEscapedLessThanSign: en_ScriptDataDoubleEscapedLessThanSign,
    BeforeAttributeName: en_BeforeAttributeName,
    AttributeName: en_AttributeName,
    AfterAttributeName: en_AfterAttributeName,
    BeforeAttributeValue: en_BeforeAttributeValue,
    AttributeValueQuoted: en_AttributeValueQuoted,
    AttributeValueUnquoted: en_AttributeValueUnquoted,
    AfterAttributeValueQuoted: en_AfterAttributeValueQuoted,
    SelfClosingStartTag: en_SelfClosingStartTag,
    BogusComment: en_BogusComment,
    MarkupDeclarationOpen: en_MarkupDeclarationOpen,
    CommentStart: en_CommentStart,
    CommentStartDash: en_CommentStartDash,
    Comment: en_Comment,
    CommentEndDash: en_CommentEndDash,
    CommentEnd: en_CommentEnd,
    CommentEndBang: en_CommentEndBang,
    DocType: en_DocType,
    DocTypeName: en_DocTypeName,
    AfterDocTypeName: en_AfterDocTypeName,
    BeforeDocTypePublicIdentifier: en_BeforeDocTypePublicIdentifier,
    DocTypePublicIdentifierQuoted: en_DocTypePublicIdentifierQuoted,
    BetweenDocTypePublicAndSystemIdentifiers: en_BetweenDocTypePublicAndSystemIdentifiers,
    BeforeDocTypeSystemIdentifier: en_BeforeDocTypeSystemIdentifier,
    DocTypeSystemIdentifierQuoted: en_DocTypeSystemIdentifierQuoted,
    AfterDocTypeSystemIdentifier: en_AfterDocTypeSystemIdentifier,
    BogusDocType: en_BogusDocType,
    CDataSection: en_CDataSection,
    CDataSectionEnd: en_CDataSectionEnd,
    CDataSectionEndRightBracket: en_CDataSectionEndRightBracket
};

for (var key in states) {
    states[states[key]] = key;
}

var CR = new RegExp('\r\n?', 'g');

exports.HtmlTokenizer = class HtmlTokenizer {
    constructor(options) {
        %%write init nocs;
        this.cs = options.initialState || en_Data;
        this.allowCData = !!options.allowCData;
        this.emitToken = options.onToken;
        this.lastStartTagName = options.lastStartTagName;
        this.onTrace = options.onTrace;
        this.quote = 0;
        this.docTypeToken = null;
        this.tagToken = null;
        this.attribute = null;
        this.string = '';
        this.startSlice = this.startSlice2 = 0;
        if (this.onTrace) {
            this._cs = this.cs;
            Object.defineProperty(this, 'cs', {
                get() {
                    return this._cs;
                },
                set(value) {
                    throw new Error('Changing state before the feed.');
                }
            });
        }
    }

    feed(data, isEnd) {
        // Preprocess
        {
            data = data.replace(CR, '\n');
        }
        var p = 0;
        var pe = data.length;
        var eof = isEnd ? pe : -1;
        if (this.onTrace) {
            Object.defineProperty(this, 'cs', {
                set(value) {
                    this.onTrace({
                        from: this._cs,
                        to: value,
                        at: p,
                        in: data
                    });
                    this._cs = value;
                }
            });
        }
        %%write exec;
        if (this.cs === error) {
            throw new Error('Tokenization error at ' + p);
        }
    }
};
