'use strict';

const test = require('tape-catch');
const testsDir = `${__dirname}/../html5lib-tests/tokenizer`;
const fs = require('fs');
const { HtmlTokenizer, states } = require('./tokenizer');
const decodeToken = require('./decode-token');

function unescape(str) {
    return str.replace(/\\u([0-9a-f]{4})/i, (_, code) => String.fromCharCode(parseInt(code, 16)));
}

function stringify(str) {
    return JSON.stringify(str).replace(/[\u007F-\uFFFF]/g, c => `\\u${('000' + c.charCodeAt(0).toString(16)).slice(-4)}`);
}

function deepUnescape(obj) {
    if (typeof obj === 'string') {
        return unescape(obj);
    }
    for (let key in obj) {
        obj[key] = deepUnescape(obj[key]);
    }
    return obj;
}

function codeFrame(str, pos) {
    const toPos = stringify(str.slice(0, pos)).slice(0, -1);
    const afterPos = stringify(str.slice(pos)).slice(1);
    const length = stringify(str.slice(pos, pos + 1)).length - 2;
    pos = toPos.length;
    str = toPos + afterPos;
    return str + '\n' + '-'.repeat(pos) + '^'.repeat(length) + '-'.repeat(str.length - pos - length);
}

function squashCharTokens(tokens) {
    const newTokens = [];
    let lastToken;
    for (let token of tokens) {
        if (token[0] === 'Character' && lastToken !== undefined && lastToken[0] === 'Character') {
            lastToken[1] += token[1];
        } else {
            newTokens.push(lastToken = token);
        }
    }
    return newTokens;
}

const stateMappings = {
    'data state': states.Data,
    'PLAINTEXT state': states.PlainText,
    'RCDATA state': states.RCData,
    'RAWTEXT state': states.RawText,
    'script data state': states.ScriptData
};

function tokenize(input, { lastStartTag, initialState }) {
    if (initialState !== undefined && !(initialState in stateMappings)) {
        throw new Error(`Requested unexpected state ${initialState}`);
    }
    const tokens = [];
    let raw = '';
    const tokenizer = new HtmlTokenizer({
        lastStartTagName: lastStartTag,
        initialState: initialState && stateMappings[initialState],
        onToken(token, rawSlice) {
            raw += rawSlice;
            decodeToken(token);
            switch (token.type) {
                case 'Character': {
                    tokens.push(['Character', token.value]);
                    break;
                }

                case 'StartTag': {
                    tokens.push([
                        'StartTag',
                        token.name,
                        token.attributes.reduce((attrs, { name, value }) => {
                            if (!(name in attrs)) {
                                attrs[name] = value;
                            }
                            return attrs;
                        }, Object.create(null))
                    ].concat(token.selfClosing ? [true] : []));
                    break;
                }

                case 'EndTag': {
                    tokens.push(['EndTag', token.name]);
                    break;
                }

                case 'Comment': {
                    tokens.push(['Comment', token.value]);
                    break;
                }

                case 'DocType': {
                    tokens.push([
                        'DOCTYPE',
                        token.name,
                        token.publicId,
                        token.systemId,
                        !token.forceQuirks
                    ]);
                    break;
                }
            }
        }
    });
    for (const char of input) {
        tokenizer.feed(char, false);
    }
    tokenizer.feed('', true);
    raw += tokenizer.buffer;
    return { tokens, raw };
}

function testFile(path) {
    const { tests } = JSON.parse(fs.readFileSync(path, 'utf-8'));
    if (tests) {
        tests.forEach(({
            description,
            input,
            output,
            initialStates = ['data state'],
            doubleEscaped = false,
            lastStartTag
        }) => {
            test(description, t => {
                output = output.filter(item => item !== 'ParseError');
                if (doubleEscaped) {
                    input = unescape(input);
                    output = deepUnescape(output);
                }
                output = squashCharTokens(output);
                initialStates.forEach(initialState => {
                    const actual = tokenize(input, { lastStartTag, initialState });
                    t.deepEqual(
                        squashCharTokens(actual.tokens),
                        output,
                        `${initialState} tokens`
                    );
                    t.equal(actual.raw, input, `${initialState} raw`)
                });
                t.end();
            });
        });
    }
}

fs.readdirSync(testsDir).forEach(name => {
    if (/\.test$/.test(name) && !/entities/i.test(name)) {
        testFile(`${testsDir}/${name}`);
    }
});

testFile(`${__dirname}/../script-data.test`);
