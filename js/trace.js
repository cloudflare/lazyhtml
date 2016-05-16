'use strict';

require('better-log').install({
    depth: 2
});

const { states, HtmlTokenizer } = require('./tokenizer');
const { states: decoderStates, decode } = require('./decoder');
const chalk = require('chalk');
const minimist = require('minimist');
const args = minimist(process.argv.slice(2));

if (args.help || !args._.length) {
    console.info(
    `Usage: ${chalk.yellow('node trace [--state=Data] [--cdata] [--tag=xmp] [--decode] [--chunk=1024]')} ${chalk.green('"<html>"')}\n` +
    `Unicode sequences in form of "\\u12AB" are supported and converted into corresponding characters.`
    );
    process.exit(1);
}

const stateNames = Object.create(null);

for (const key in states) {
    stateNames[states[key]] = key;
}

function toStr(s) {
    return JSON.stringify(s).replace(/[\u007f-\uffff]/g, c => `\\u${('000'+c.charCodeAt(0).toString(16)).slice(-4)}`);
}

function toState(state) {
    return `-> ${chalk.italic(stateNames[state] || state)}`;
}

function codeFrame(str, pos) {
    const head = slice.call(toStr(slice.call(str, 0, pos)), 0, -1);
    const middle = slice.call(toStr(str.charAt(pos)), 1, -1);
    const tail = slice.call(toStr(slice.call(str, pos + 1)), 1);

    return `${chalk.yellow(`${head}${chalk.bgBlue(middle)}${tail}`)}`;
}

const tokenizer = new HtmlTokenizer({
    initialState: typeof args.state === 'string' ? states[args.state] : args.state,
    allowCData: args.cdata,
    lastStartTagName: args.tag || 'xmp',
    onToken(token) {
        if (args.decode) {
            console.log('Post-processing (decoding)...');
            switch (token.type) {
                case 'Character':
                    if (token.kind) {
                        token.value = decode(decoderStates[token.kind], token.value);
                    }
                    break;

                case 'Comment':
                    token.value = decode(decoderStates.Comment, token.value);
                    break;
            }
        }
        console.log(token);
    },
    onTrace(trace) {
        if (trace.to in stateNames) {
            console.log(codeFrame(trace.in, trace.at), toState(trace.to));
        }
    }
});

console.log(toState(tokenizer.cs));

const input = args._[0].replace(/\\u([0-9a-f]{4})/g, (_, code) => String.fromCharCode(parseInt(code, 16)));

const { slice } = String.prototype;

String.prototype.slice = function (from, to) {
    const result = slice.apply(this, arguments);
    console.log(`Sliced input at ${chalk.green(from)}..${chalk.green(to)}: ${chalk.yellow(toStr(result))}`);
    return result;
};

const chunkSize = args.chunk || 1024;

for (let i = 0; i < input.length; i += chunkSize) {
    console.log('Feeding chunk #' + i);
    tokenizer.feed(slice.call(input, i, i + chunkSize), false);
}
console.log('Feeding last chunk');
tokenizer.feed('', true);
