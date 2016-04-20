const fs = require('fs');
const xml2js = require('xml2js');
const _ = require('lodash');
const assert = require('assert');

function assertProp(tagName, propName, $, value, valueMsg) {
    assert.equal($[propName], value, `<${tagName} ${propName} /> is supposed to be equal to ${valueMsg || value}.`);
}

function assertId(tagName, $, i) {
    assertProp(tagName, 'id', $, i, 'its position');
}

xml2js.parseString(fs.readFileSync('machine.xml', 'utf-8'), (err, {
    ragel: {
        ragel_def: [{
            machine: [{
                action_list: [{ action }],
                action_table_list: [{ action_table }],
                start_state: [start_state],
                error_state: [error_state],
                entry_points: [{ entry }],
                state_list: [{ state }]
            }]
        }]
    }
}) => {
    assert.strictEqual(entry.length, 1, 'Expected only one entry point.');
    assert.strictEqual(entry[0]._, start_state, 'Expected start_state to be the only entry point.');
    assert.equal(error_state, 0, 'Expected error state to be at position 0.');
    assert.equal(start_state, 1, 'Expected start state to be at position 1.');
    action = _.map(action, ({ $, text }, i) => {
        assertId('action', $, i);
        return { text, referenced: false };
    });
    action_table = _.map(action_table, ({ $, _ }, i) => {
        assertId('action_table', $, i);
        assertProp('action_table', 'length', $, 1);
        const act = action[_];
        assert(!act.referenced, `<action id="${_}" /> was referenced twice in the action_table.`);
        act.referenced = true;
        return JSON.parse(act.text);
    });
    var referencedBy = {};
    state = _.map(state, ({ $, trans_list: [{ t }] }, i) => {
        assertId('state', $, i);
        return (
            _(t)
            .map(t => t.split(' '))
            .map(([ start, end, toState, action ]) => {
                assert.strictEqual(start, end, 'Character ranges are currently unsupported.');
                referencedBy[action] = (referencedBy[action] | 0) + 1;
                return {
                    match: +start,
                    action: action !== 'x' ? +action : -1,
                    toState: +toState
                };
            })
            .value()
        );
    });
    fs.writeFileSync('machine.json', JSON.stringify({
        action_table,
        state
    }, null, 4));
});
