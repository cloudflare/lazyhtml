'use strict';

require('better-log').install({
    depth: 2
});

const { states, HtmlTokenizer } = require('./js-tokenizer');
const chalk = require('chalk');
const minimist = require('minimist');
const args = minimist(process.argv.slice(2));

if (args.help || !args._.length) {
    console.info(
    `Usage: node --harmony_destructuring ${chalk.yellow('trace [--state=Data] [--cdata] [--tag=xmp]')} ${chalk.green('"<html>"')}\n` +
    `Unicode sequences in form of "\\u12AB" are supported and converted into corresponding characters.`
    );
    process.exit(1);
}

const stateNames = Object.create(null);

for (var key in states) {
    stateNames[states[key]] = key;
}

function toStr(s) {
    return JSON.stringify(s).replace(/[\u007f-\uffff]/g, c => `\\u${('000'+c.charCodeAt(0).toString(16)).slice(-4)}`);
}

function toState(state) {
    return `-> ${chalk.italic(stateNames[state] || state)}`;
}

function codeFrame(str, pos) {
    const head = toStr(str.slice(0, pos)).slice(0, -1);
    const middle = toStr(str.charAt(pos)).slice(1, -1);
    const tail = toStr(str.slice(pos + 1)).slice(1);

    return `${chalk.yellow(`${head}${middle}${tail}`)}\n${chalk.cyan('-'.repeat(head.length))}${chalk.blue('^'.repeat(middle.length))}${chalk.cyan('-'.repeat(tail.length))}`;
}

const tokenizer = new HtmlTokenizer({
    initialState: typeof args.state === 'string' ? states[args.state] : args.state,
    allowCData: args.cdata,
    tag: args.tag,
    onToken: console.log,
    onTrace(trace) {
        if (trace.to !== trace.from && (trace.to in stateNames)) {
            console.log(codeFrame(trace.in, trace.at), toState(trace.to));
        }
    }
});

console.log(toState(tokenizer.cs));

tokenizer.feed(args._[0].replace(/\\u([0-9a-f]{4})/g, (_, code) => String.fromCharCode(parseInt(code, 16))), true);