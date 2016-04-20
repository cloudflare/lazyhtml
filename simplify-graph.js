'use strict';

var fs = require('fs');
var graphlib = require('graphlib-dot');

var g = graphlib.read(fs.readFileSync(process.argv[2], 'utf-8'));

g.nodes().forEach(v => {
    var out = g.outEdges(v);
    var outW = new Set(out.map(edge => edge.w));
    outW.forEach(w => {
        var labels = out.reduce((map, edge) => {
            if (edge.w === w) {
                var match = g.edge(v, w, edge.name).label.match(/^(.*?)( \/ \w+(?:, \w+)*)?$/);
                var strings = map.get(match[2] || '');
                if (!strings) {
                    map.set(match[2] || '', strings = []);
                }
                strings.push(match[1]);
                g.removeEdge(v, w, edge.name);
            }
            return map;
        }, new Map());
        var label = Array.from(labels, ([ action, strings ]) => strings.join(' | ') + action).join('\n');
        g.setEdge(v, w, { label });
    });
});

fs.writeFileSync(process.argv[2], graphlib.write(g));
