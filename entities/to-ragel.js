'use strict';

const fs = require('fs');
const _ = require('lodash');
const named = require('./entities.json');

const toStr = str => JSON.stringify(str);

fs.writeFile('machine.rl', `%%{
machine named_entities;

main := (${
    _(named)
    .map(({ characters }, string) => ({ string, characters }))
    .groupBy('characters')
    .map((group, characters) => `
    (
        ${
        group
        .map(({ string }) => toStr(string.slice(1)))
        .join(` |
        `)
        }
    ) @{${toStr(characters)}}`)
    .join(` |
    `)
});
}%%`);
