%%{
    machine html;

    access this.;

    include 'js-actions.rl';
    include 'syntax/index.rl';

    write data nofinal noprefix;
}%%

var fs = require('fs');

function convertBuffer(nodeBuffer) {
    return nodeBuffer.buffer.slice(nodeBuffer.byteOffset, nodeBuffer.byteOffset + nodeBuffer.byteLength);
}

var namedEntityValues = JSON.parse('[' + fs.readFileSync(__dirname + '/entities/values.txt', 'utf-8') + ']');
var namedEntityHandlers = new Uint16Array(convertBuffer(fs.readFileSync(__dirname + '/entities/handlers.dat')));
var numericEntities = new Uint16Array(convertBuffer(fs.readFileSync(__dirname + '/entities/numeric.dat')));

function getNumericEntity(code) {
    if (code < 256) {
        code = numericEntities[code];
    } else if (code >= 0xD800 && code <= 0xDFFF || code > 0x10FFFF) {
        code = 0xFFFD;
    }
    return String.fromCodePoint(code);
}

var states = exports.states = {
    error,
    Data: en_Data,
    RCData: en_RCData,
    RawText: en_RawText,
    ScriptData: en_ScriptData,
    PlainText: en_PlainText,
    TagOpen: en_TagOpen,
    EndTagOpen: en_EndTagOpen,
    StartTagName: en_StartTagName,
    RCDataLessThanSign: en_RCDataLessThanSign,
    RawTextLessThanSign: en_RawTextLessThanSign,
    ScriptDataLessThanSign: en_ScriptDataLessThanSign,
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
    SelfClosingTag: en_SelfClosingTag,
    BogusComment: en_BogusComment,
    MarkupDeclarationOpen: en_MarkupDeclarationOpen,
    Comment: en_Comment,
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
    CDataSection: en_CDataSection
};

exports.HtmlTokenizer = class HtmlTokenizer {
    constructor(options) {
        %%write init nocs;
        Object.defineProperties(this, {
            allowCData: {
                enumerable: true,
                value: !!options.allowCData
            },
            emitToken: {
                enumerable: true,
                value: options.onToken
            },
            lastStartTagName: {
                writable: true,
                value: options.lastStartTagName
            },
            onTrace: {
                enumerable: true,
                value: options.onTrace
            },
            quote: {
                writable: true,
                value: 0
            },
            docTypeToken: {
                writable: true,
                value: null
            },
            startTagToken: {
                writable: true,
                value: null
            },
            endTagToken: {
                writable: true,
                value: null
            },
            attribute: {
                writable: true,
                value: null
            },
            string: {
                writable: true,
                value: ''
            },
            startSlice: {
                writable: true,
                value: -1
            },
            mark: {
                writable: true,
                value: 0
            },
            numericEntity: {
                writable: true,
                value: 0
            },
            namedEntityOffset: {
                writable: true,
                value: 0
            },
            namedEntityMatch: {
                writable: true,
                value: 0
            },
            namedEntityPos: {
                writable: true,
                value: 0
            },
            appropriateEndTagOffset: {
                writable: true,
                value: 0
            },
            buffer: {
                writable: true,
                value: ''
            }
        });
        var startState = options.initialState || en_Data;
        if (this.onTrace) {
            Object.defineProperties(this, {
                _cs: {
                    writable: true,
                    value: startState
                },
                cs: {
                    configurable: true,
                    get() {
                        return this._cs;
                    },
                    set(value) {
                        throw new Error('Changing state before the feed.');
                    }
                }
            });
        } else {
            Object.defineProperty(this, 'cs', {
                writable: true,
                value: startState
            });
        }
        Object.preventExtensions(this);
    }

    feed(data, isEnd) {
        var p = this.buffer.length;
        data = this.buffer + data;
        this.buffer = '';
        var pe = data.length;
        var eof = isEnd ? pe : -1;
        if (this.onTrace) {
            Object.defineProperty(this, 'cs', {
                set(value) {
                    if (value === this._cs) return;
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
        var bufferStart = this.startSlice;
        if (bufferStart >= 0) {
            this.buffer = data.slice(bufferStart);
            this.mark -= bufferStart;
            this.namedEntityPos -= bufferStart;
            this.startSlice = 0;
        }
    }
};

Object.freeze(exports.HtmlTokenizer.prototype);
