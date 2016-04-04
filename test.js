'use strict';

const test = require('tape-catch');
const testsDir = 'html5lib-tests/tokenizer';
const fs = require('fs');
const { HtmlTokenizer, states } = require('./js-tokenizer');
const decodeHtmlEntitites = require('he').decode;

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
    'RAWTEXT state': states.RawText
};

function tokenize(input, { lastStartTag, initialState }) {
    let tokens = [];
    if (initialState !== undefined && !(initialState in stateMappings)) {
        throw new Error(`Requested unexpected state ${initialState}`);
    }
    let lastTrace;
    new HtmlTokenizer({
        lastStartTagName: lastStartTag,
        initialState: initialState && stateMappings[initialState],
        onToken(token) {
            // console.log(token);
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
                            attrs[name] = value;
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

                default: {
                    throw new Error(`Unexpected token type ${token.type}`);
                }
            }
        },
        // onTrace(trace) {
        //     if (!(trace.from in states)) {
        //         if (trace.from !== lastTrace.to) {
        //             throw new Error(`Unexpected transition ${lastTrace.from} -> ${lastTrace.to} -> ... -> ${trace.from} -> ${trace.to}`);
        //         }
        //         trace.from = lastTrace.from;
        //     }
        //     if (trace.from === trace.to) return;
        //     if (trace.to in states) {
        //         console.info('%s -> %s:\n%s', states[trace.from], states[trace.to], codeFrame(trace.in, trace.at));
        //     }
        //     lastTrace = trace;
        // }
    }).feed(input, true);
    if (lastTrace && !(lastTrace.to in states)) {
        console.info('%s -> %s:\n%s', states[lastTrace.from], 'EOF', codeFrame(lastTrace.in, lastTrace.at));
    }
    return tokens;
}

fs.readdirSync(testsDir).forEach(name => {
    if (/entities/i.test(name)) return;
    const match = name.match(/(.*)\.test$/);
    if (!match) return;
    const { tests } = JSON.parse(fs.readFileSync(`${testsDir}/${name}`, 'utf-8'));
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
                    t.deepEqual(
                        squashCharTokens(tokenize(input, { lastStartTag, initialState })).map(token => {
                            switch (token[0]) {
                                case 'Character':
                                    token[1] = decodeHtmlEntitites(token[1]);
                                    break;

                                case 'StartTag':
                                    for (let name in token[2]) {
                                        token[2][name] = decodeHtmlEntitites(token[2][name], {
                                            isAttributeValue: true
                                        });
                                    }
                                    break;
                            }
                            return token;
                        }),
                        output,
                        initialState
                    );
                });
                t.end();
            });
        });
    }
});
