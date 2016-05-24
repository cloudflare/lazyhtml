'use strict';

const { readdirSync, readFileSync, writeFileSync } = require('fs');
const { Suite } = require('protocol-buffers')(readFileSync(`${__dirname}/tokenizer-tests.proto`));

function unescape(str) {
    return str.replace(/\\u([0-9a-f]{4})/i, (_, code) => String.fromCharCode(parseInt(code, 16)));
}

function convertStartTag([ , name, attributes, self_closing = false ]) {
    return {
        name,
        attributes: Object.keys(attributes).map(name => ({ name, value: attributes[name] })),
        self_closing
    }
}

function convertEndTag([, name]) {
    return { name };
}

function convertComment([, data]) {
    return { data };
}

function convertCharacter([, data]) {
    return { data };
}

function convertOptString(value) {
    return value === null ? { has_value: false } : { has_value: true, value };
}

function convertDocType([, name, publicId, systemId, isCorrect]) {
    return {
        name: convertOptString(name),
        public_id: convertOptString(publicId),
        system_id: convertOptString(systemId),
        force_quirks: !isCorrect
    };
}

function convertToken(token) {
    switch (token[0]) {
        case 'StartTag': return {
            start_tag: convertStartTag(token)
        };

        case 'EndTag': return {
            end_tag: convertEndTag(token)
        };

        case 'Character': return {
            character: convertCharacter(token)
        };

        case 'Comment': return {
            comment: convertComment(token)
        };

        case 'DOCTYPE': return {
            doc_type: convertDocType(token)
        };

        default: throw new TypeError(`Unknown token type: ${token[0]}`);
    }
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
        initial_states: initialStates.map(convertState),
        last_start_tag: lastStartTag
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
