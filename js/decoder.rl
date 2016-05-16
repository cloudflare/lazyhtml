%%{
    machine html_decoder;

    action Reconsume { fhold; }

    action AppendLFCharacter {
        string += '\n';
    }

    action AppendReplacementCharacter {
        string += '\uFFFD';
    }

    action StartSlice {
        startSlice = p;
    }

    action AppendSlice {
        string += data.slice(startSlice, p);
    }

    action MarkPosition {
        mark = p;
    }

    action AppendSliceBeforeTheMark {
        string += data.slice(startSlice, mark);
    }

    action StartNumericEntity {
        numericEntity = 0;
    }

    action AppendHexDigit09ToNumericEntity {
        numericEntity = numericEntity * 16 + (fc & 0xF);
    }

    action AppendHexDigitAFToNumericEntity {
        numericEntity = numericEntity * 16 + ((fc + 9) & 0xF);
    }

    action AppendDecDigitToNumericEntity {
        numericEntity = numericEntity * 10 + (fc & 0xF);
    }

    action AppendNumericEntity {
        string += getNumericEntity(numericEntity);
    }

    action StartNamedEntity {
        namedEntityOffset = 1;
    }

    action UnmatchNamedEntity {
        namedEntityMatch = 0;
    }

    action FeedNamedEntity {
        var min = 0;
        var max = namedEntityHandlers[namedEntityOffset++] - 1;
        var ch = fc;

        while (min <= max) {
            var i = (min + max) >> 1;
            var curPos = namedEntityOffset + i * 3;
            var curCh = namedEntityHandlers[curPos];

            if (curCh < ch) {
                min = i + 1;
            } else if (curCh > ch) {
                max = i - 1;
            } else {
                var action = namedEntityHandlers[++curPos];
                if (action > 0) {
                    namedEntityMatch = action;
                    namedEntityPos = p;
                }
                namedEntityOffset = namedEntityHandlers[++curPos];
                break;
            }
        }

        if (min > max || namedEntityHandlers[namedEntityOffset] === 0) {
            namedEntityOffset = 0;
        }
    }

    action AppendNamedEntity() {
        if (namedEntityMatch > 0) {
            $AppendSliceBeforeTheMark
            string += namedEntityValues[namedEntityMatch];
            startSlice = namedEntityPos + 1;
        }
    }

    include 'syntax/decoder.rl';

    write data nofinal noprefix;
}%%

var fs = require('fs');

function convertBuffer(nodeBuffer) {
    return nodeBuffer.buffer.slice(nodeBuffer.byteOffset, nodeBuffer.byteOffset + nodeBuffer.byteLength);
}

var entitiesDir = __dirname + '/../entities';

var namedEntityValues = JSON.parse('[' + fs.readFileSync(entitiesDir + '/values.txt', 'utf-8') + ']');
var namedEntityHandlers = new Uint16Array(convertBuffer(fs.readFileSync(entitiesDir + '/handlers.dat')));
var numericEntities = new Uint16Array(convertBuffer(fs.readFileSync(entitiesDir + '/numeric.dat')));

function getNumericEntity(code) {
    if (code < 256) {
        code = numericEntities[code];
    } else if (code >= 0xD800 && code <= 0xDFFF || code > 0x10FFFF) {
        code = 0xFFFD;
    }
    return String.fromCodePoint(code);
}

var states = exports.states = {
    Data: en_Data,
    RCData: en_RCData,
    CData: en_CData,
    Comment: en_Comment,
    AttrValue: en_AttrValue
};

exports.decode = function (cs, data) {
    var string = '';
    var p = 0, pe = data.length, eof = pe;
    var startSlice, mark;
    var numericEntity;
    var namedEntityMatch, namedEntityOffset, namedEntityPos;
    %%write init nocs;
    %%write exec;
    if (cs === error) {
        throw new Error('Decoding error at ' + p);
    }
    return string;
};