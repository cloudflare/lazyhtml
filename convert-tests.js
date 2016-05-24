'use strict';

const { readdirSync, readFileSync, writeFileSync } = require('fs');
const { Suite } = require('protocol-buffers')(readFileSync(`${__dirname}/js/tests.proto`));

function unescape(str) {
    return str.replace(/\\u([0-9a-f]{4})/i, (_, code) => String.fromCharCode(parseInt(code, 16)));
}

function convertOptString(value) {
    return { hasValue: value !== null, value };
}

const convert = {
    StartTag: (name, attributes, selfClosing = false) => ({
        name,
        attributes,
        selfClosing
    }),

    EndTag: (name) => ({ name }),

    Comment: (value) => ({ value }),

    Character: (value) => ({ value }),

    DocType: (name, publicId, systemId, isCorrect) => ({
        name: convertOptString(name),
        publicId: convertOptString(publicId),
        systemId: convertOptString(systemId),
        forceQuirks: !isCorrect
    })
};

function convertToken(token) {
    let [type, ...extra] = token;
    if (type === 'DOCTYPE') {
        type = 'DocType';
    }
    return {
        [type]: convert[type](...extra)
    };
}

function convertState(state) {
    switch (state) {
        case 'data state': return Suite.Test.State.Data;
        case 'PLAINTEXT state': return Suite.Test.State.PlainText;
        case 'RCDATA state': return Suite.Test.State.RCData;
        case 'RAWTEXT state': return Suite.Test.State.RawText;
        case 'script data state': return Suite.Test.State.ScriptData;
    }
}

function convertTest({
    description,
    input,
    output,
    initialStates = ['data state'],
    doubleEscaped = false,
    lastStartTag = ''
}) {
    return {
        description,
        input: doubleEscaped ? unescape(input) : input,
        output: (
            output
            .filter(token => token !== 'ParseError')
            .reduce((newTokens, token) => {
                if (doubleEscaped && (token[0] === 'Character' || token[0] === 'Comment')) {
                    token[1] = unescape(token[1]);
                }
                if (token[0] === 'Character' && newTokens.length > 0) {
                    const lastToken = newTokens[newTokens.length - 1];
                    if (lastToken[0] === 'Character') {
                        lastToken[1] += token[1];
                        return newTokens;
                    }
                }
                newTokens.push(token);
                return newTokens;
            }, [])
            .map(convertToken)
        ),
        initialStates: initialStates.map(convertState),
        lastStartTag
    };
}

const suite = {
    tests: (
        readdirSync(`${__dirname}/html5lib-tests/tokenizer`)
        .filter(name => name.endsWith('.test'))
        .map(name => `${__dirname}/html5lib-tests/tokenizer/${name}`)
        .concat(`${__dirname}/script-data.test`)
        .map(path => JSON.parse(readFileSync(path, 'utf-8')).tests)
        .filter(Boolean)
        .reduce((all, tests) => all.concat(tests), [])
        .map(convertTest)
    )
};

writeFileSync(`${__dirname}/tests.dat`, Suite.encode(suite));
