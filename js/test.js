'use strict';

const test = require('tape-catch');
const { readFileSync } = require('fs');
const { Suite } = require('protocol-buffers')(readFileSync(`${__dirname}/../tokenizer-tests.proto`));
const { HtmlTokenizer, states } = require('./tokenizer');
const decodeToken = require('./decode-token');

const stateMappings = {
    [Suite.Test.State.Data]: states.Data,
    [Suite.Test.State.PlainText]: states.PlainText,
    [Suite.Test.State.RCData]: states.RCData,
    [Suite.Test.State.RawText]: states.RawText,
    [Suite.Test.State.ScriptData]: states.ScriptData
};

function pairsToMap(pairs) {
    return pairs.reduce((map, attr) => {
        if (!(attr.name in map)) {
            map[attr.name] = attr.value;
        }
        return map;
    }, Object.create(null));
}

function fromOpt(maybe) {
    return maybe.has_value ? maybe.value : null;
}

function fromTestToken(token) {
    const type = Object.keys(token)[0];
    token = token[type];
    switch (type) {
        case 'start_tag': return {
            type: 'StartTag',
            name: token.name,
            attributes: pairsToMap(token.attributes),
            selfClosing: token.self_closing
        };

        case 'end_tag': return {
            type: 'EndTag',
            name: token.name
        };

        case 'comment': return {
            type: 'Comment',
            value: token.data
        };

        case 'character': return {
            type: 'Character',
            value: token.data
        };

        case 'doc_type': return {
            type: 'DocType',
            name: fromOpt(token.name),
            publicId: fromOpt(token.public_id),
            systemId: fromOpt(token.system_id),
            forceQuirks: token.force_quirks
        };

        default: throw new TypeError(`Unknown token type: ${type}`);
    }
}

function tokenize(input, { lastStartTag, initialState }) {
    const tokens = [];
    let raw = '';
    let charToken = null, lastToken = null;
    function onToken(token, rawSlice) {
        raw += rawSlice;

        if (charToken && token.type === 'Character' && token.kind === charToken.kind) {
            charToken.value += token.value;
            return;
        }

        if (charToken) {
            decodeToken(charToken);
            if (lastToken && lastToken.type === 'Character') {
                lastToken.value += charToken.value;
            } else {
                tokens.push(lastToken = {
                    type: 'Character',
                    value: charToken.value
                });
            }
            charToken = null;
        }

        if (token.type === 'EOF') {
            return;
        }

        if (token.type === 'Character') {
            charToken = token;
            return;
        }

        decodeToken(token);

        if (token.type === 'StartTag') {
            token.attributes = pairsToMap(token.attributes);
        }

        tokens.push(lastToken = token);
    }
    const tokenizer = new HtmlTokenizer({
        lastStartTagName: lastStartTag,
        initialState: stateMappings[initialState],
        onToken
    });
    for (const char of input) {
        tokenizer.feed(char, false);
    }
    tokenizer.feed('', true);
    onToken({ type: 'EOF' }, tokenizer.buffer);
    return { tokens, raw };
}

const { tests } = Suite.decode(readFileSync(`${__dirname}/../tests.dat`));

tests.forEach(({
    description,
    input,
    output,
    initial_states: initialStates,
    last_start_tag: lastStartTag
}) => {
    if (description.includes('entity')) return;
    test(description, t => {
        output = output.map(fromTestToken);
        initialStates.forEach(initialState => {
            const actual = tokenize(input, { lastStartTag, initialState });
            t.deepEqual(
                actual.tokens,
                output,
                `${initialState} tokens`
            );
            t.equal(actual.raw, input, `${initialState} raw`)
        });
        t.end();
    });
});
