%%{
    machine html;

    access this.;

    include 'js-actions.rl';
    include 'syntax.rl';

    write data nofinal noprefix;
}%%

var numericEntities = new Uint16Array(256);

for (var i = 0; i < numericEntities.length; i++) {
    numericEntities[i] = i;
}

numericEntities[0x00] = 0xFFFD;
numericEntities[0x80] = 0x20AC;
numericEntities[0x82] = 0x201A;
numericEntities[0x83] = 0x0192;
numericEntities[0x84] = 0x201E;
numericEntities[0x85] = 0x2026;
numericEntities[0x86] = 0x2020;
numericEntities[0x87] = 0x2021;
numericEntities[0x88] = 0x02C6;
numericEntities[0x89] = 0x2030;
numericEntities[0x8A] = 0x0160;
numericEntities[0x8B] = 0x2039;
numericEntities[0x8C] = 0x0152;
numericEntities[0x8E] = 0x017D;
numericEntities[0x91] = 0x2018;
numericEntities[0x92] = 0x2019;
numericEntities[0x93] = 0x201C;
numericEntities[0x94] = 0x201D;
numericEntities[0x95] = 0x2022;
numericEntities[0x96] = 0x2013;
numericEntities[0x97] = 0x2014;
numericEntities[0x98] = 0x02DC;
numericEntities[0x99] = 0x2122;
numericEntities[0x9A] = 0x0161;
numericEntities[0x9B] = 0x203A;
numericEntities[0x9C] = 0x0153;
numericEntities[0x9E] = 0x017E;
numericEntities[0x9F] = 0x0178;

function getNumericEntity(code) {
    if (code < 256) {
        code = numericEntities[code];
    } else if (code >= 0xD800 && code <= 0xDFFF || code > 0x10FFFF) {
        code = 0xFFFD;
    }
    return String.fromCodePoint(code);
}

var fs = require('fs');

var namedEntityValues = JSON.parse('[' + fs.readFileSync(__dirname + '/entities/values.txt', 'utf-8') + ']');

var namedEntityHandlers = new Uint16Array(fs.readFileSync(__dirname + '/entities/handlers.dat').buffer);

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
    CDataSection: en_CDataSection
};

for (var key in states) {
    states[states[key]] = key;
}

var CR = new RegExp('\r\n?', 'g');

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
            tagToken: {
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
                value: 0
            },
            startSlice2: {
                writable: true,
                value: 0
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

Object.freeze(exports.HtmlTokenizer.prototype);
