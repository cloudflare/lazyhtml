%%{
    machine html;

    access this.;
    alphtype u8;

    include 'js-actions.rl';
    include 'syntax.rl';

    write data;
}%%

const states = exports.states = {
    start: html_start,
    first_final: html_first_final,
    error: html_error,
    PlainText: html_en_PlainText,
    Data: html_en_Data,
    RCData: html_en_RCData,
    RawText: html_en_RawText,
    ScriptData: html_en_ScriptData,
    TagOpen: html_en_TagOpen,
    EndTagOpen: html_en_EndTagOpen,
    TagName: html_en_TagName,
    RCDataLessThanSign: html_en_RCDataLessThanSign,
    RCDataEndTagOpen: html_en_RCDataEndTagOpen,
    RCDataEndTagName: html_en_RCDataEndTagName,
    RawTextLessThanSign: html_en_RawTextLessThanSign,
    RawTextEndTagOpen: html_en_RawTextEndTagOpen,
    RawTextEndTagName: html_en_RawTextEndTagName,
    ScriptDataLessThanSign: html_en_ScriptDataLessThanSign,
    ScriptDataEndTagOpen: html_en_ScriptDataEndTagOpen,
    ScriptDataEndTagName: html_en_ScriptDataEndTagName,
    ScriptDataEscapeStart: html_en_ScriptDataEscapeStart,
    ScriptDataEscapeStartDash: html_en_ScriptDataEscapeStartDash,
    ScriptDataEscaped: html_en_ScriptDataEscaped,
    ScriptDataEscapedDash: html_en_ScriptDataEscapedDash,
    ScriptDataEscapedDashDash: html_en_ScriptDataEscapedDashDash,
    ScriptDataEscapedLessThanSign: html_en_ScriptDataEscapedLessThanSign,
    ScriptDataEscapedEndTagOpen: html_en_ScriptDataEscapedEndTagOpen,
    ScriptDataEscapedEndTagName: html_en_ScriptDataEscapedEndTagName,
    ScriptDataDoubleEscapeStart: html_en_ScriptDataDoubleEscapeStart,
    ScriptDataDoubleEscaped: html_en_ScriptDataDoubleEscaped,
    ScriptDataDoubleEscapedDash: html_en_ScriptDataDoubleEscapedDash,
    ScriptDataDoubleEscapedDashDash: html_en_ScriptDataDoubleEscapedDashDash,
    ScriptDataDoubleEscapedLessThanSign: html_en_ScriptDataDoubleEscapedLessThanSign,
    ScriptDataDoubleEscapeEnd: html_en_ScriptDataDoubleEscapeEnd,
    BeforeAttributeName: html_en_BeforeAttributeName,
    AttributeName: html_en_AttributeName,
    AfterAttributeName: html_en_AfterAttributeName,
    BeforeAttributeValue: html_en_BeforeAttributeValue,
    AttributeValueDoubleQuoted: html_en_AttributeValueDoubleQuoted,
    AttributeValueSingleQuoted: html_en_AttributeValueSingleQuoted,
    AttributeValueUnquoted: html_en_AttributeValueUnquoted,
    AfterAttributeValueQuoted: html_en_AfterAttributeValueQuoted,
    SelfClosingStartTag: html_en_SelfClosingStartTag,
    BogusComment: html_en_BogusComment,
    MarkupDeclarationOpen: html_en_MarkupDeclarationOpen,
    CommentStart: html_en_CommentStart,
    CommentStartDash: html_en_CommentStartDash,
    Comment: html_en_Comment,
    CommentEndDash: html_en_CommentEndDash,
    CommentEnd: html_en_CommentEnd,
    CommentEndBang: html_en_CommentEndBang,
    DocType: html_en_DocType,
    BeforeDocTypeName: html_en_BeforeDocTypeName,
    DocTypeName: html_en_DocTypeName,
    AfterDocTypeName: html_en_AfterDocTypeName,
    AfterDocTypePublicKeyword: html_en_AfterDocTypePublicKeyword,
    BeforeDocTypePublicIdentifier: html_en_BeforeDocTypePublicIdentifier,
    DocTypePublicIdentifierDoubleQuoted: html_en_DocTypePublicIdentifierDoubleQuoted,
    DocTypePublicIdentifierSingleQuoted: html_en_DocTypePublicIdentifierSingleQuoted,
    AfterDocTypePublicIdentifier: html_en_AfterDocTypePublicIdentifier,
    BetweenDocTypePublicAndSystemIdentifiers: html_en_BetweenDocTypePublicAndSystemIdentifiers,
    AfterDocTypeSystemKeyword: html_en_AfterDocTypeSystemKeyword,
    BeforeDocTypeSystemIdentifier: html_en_BeforeDocTypeSystemIdentifier,
    DocTypeSystemIdentifierDoubleQuoted: html_en_DocTypeSystemIdentifierDoubleQuoted,
    DocTypeSystemIdentifierSingleQuoted: html_en_DocTypeSystemIdentifierSingleQuoted,
    AfterDocTypeSystemIdentifier: html_en_AfterDocTypeSystemIdentifier,
    BogusDocType: html_en_BogusDocType,
    CDataSection: html_en_CDataSection
};

for (let key in states) {
    states[states[key]] = key;
}

const CR = new RegExp('\r\n?', 'g');

exports.HtmlTokenizer = class HtmlTokenizer {
    constructor(options) {
        %%write init;
        this.cs = options.initialState || states.Data;
        this.allowCData = true;
        this.emitToken = options.onToken;
        this.lastStartTagName = options.lastStartTagName;
        this.onTrace = options.onTrace;
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
        let p = 0;
        const pe = data.length;
        const eof = isEnd ? pe : -1;
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
        if (this.cs === html_error) {
            throw new Error('Tokenization error at ' + p);
        }
    }
};
