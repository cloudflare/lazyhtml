const fs = require('fs');
const _ = require('lodash');
const { action_table, state } = require('./machine.json');

const stateOffsets = _.transform(state, (result, t) => {
    result.list.push(result.next);
    result.next += 1 + t.length * 3;
}, { next: 0, list: [] }).list;

fs.writeFile('values.txt', JSON.stringify([''].concat(action_table)).slice(1, -1));

fs.writeFile('handlers.dat', new Buffer(new Uint16Array(_(state).map((t, i) => [
    t.length,
    _.map(t, t => [t.match, t.action + 1, stateOffsets[t.toState]])
]).flattenDeep().value()).buffer));
