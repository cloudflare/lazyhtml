'use strict';

require('better-log').install({
    depth: 2
});

var { states, HtmlTokenizer } = require('./js-tokenizer');
var fs = require('fs');
var now = require('performance-now');

var stateNames = Object.create(null);

stateNames[-1] = '(outside)';

for (var key in states) {
    stateNames[states[key]] = key;
}

var traces = [];

var tokenizer = new HtmlTokenizer({
    onToken() {},
    onTrace(trace) {
        traces.push({
            time: now(),
            to: trace.to
        });
    }
});

var input = fs.readFileSync(process.argv[2], 'utf-8');

var durations = {};
var lastFrom = -1;
var lastStart = now();

traces.push({
    time: lastStart,
    to: states.Data
});

tokenizer.feed(input, true);

traces.push({
    time: now(),
    to: -1
});

traces.forEach(trace => {
    if (lastFrom >= 0) {
        var fromName = stateNames[lastFrom] || `s${lastFrom}`;
        var oldDuration = durations[fromName] || 0;
        durations[fromName] = oldDuration + trace.time - lastStart;
    }
    lastFrom = trace.to;
    lastStart = trace.time;
});

durations.total = traces[traces.length - 1].time - traces[0].time;

durations =
    Object.keys(durations)
    .map(key => [key, durations[key]])
    .filter(pair => pair[1] >= durations.total * 0.01)
    .sort((a, b) => b[1] - a[1])
    .reduce((obj, pair) => {
        obj[pair[0]] = pair[1];
        return obj;
    }, {});

console.log(durations);
