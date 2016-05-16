'use strict';

const { states, decode } = require('./decoder');

module.exports = function decodeToken(token) {
    switch (token.type) {
        case 'StartTag':
            token.attributes.forEach(attr => {
                attr.name = decode(states.Name, attr.name);
                attr.value = decode(states.AttrValue, attr.value);
            });
            /* falls through */
        case 'EndTag':
            token.name = decode(states.Name, token.name);
            break;

        case 'Character':
            if (token.kind) {
                token.value = decode(states[token.kind], token.value);
            }
            break;

        case 'Comment':
            token.value = decode(states.Comment, token.value);
            break;

        case 'DocType':
            token.name = decode(states.Name, token.name);
            token.publicId = decode(states.Safe, token.publicId);
            token.systemId = decode(states.Safe, token.systemId);
            break;

        default:
            throw new Error(`Unexpected token type ${token.type}`);
    }
};