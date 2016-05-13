'use strict';

var Benchmark = require('benchmark');
var MyTokenizer = require('./tokenizer').HtmlTokenizer;
var Parse5Tokenizer = require('parse5/lib/tokenizer');
var fs = require('fs');
var text;

var suite =
    new Benchmark.Suite()
    .add('my', () => {
        new MyTokenizer({
            onToken() {}
        }).feed(text, true);
    })
    .add('parse5', () => {
        var tokenizer = new Parse5Tokenizer();
        tokenizer.write(text, true);
        do {
            var token = tokenizer.getNextToken();
        } while (token.type !== 'EOF_TOKEN');
    })
    .on('error', event => {
        throw event.target.error;
    })
    .on('cycle', event => console.log(String(event.target)));

function logAndUnderline(text, char) {
    console.log(text);
    console.log(char.repeat(text.length));
}

var fixturesPath = `${__dirname}/../bench-fixtures`;

fs.readdirSync(fixturesPath).forEach(src => {
    var fill = '='.repeat(src.length);
    console.log(fill);
    console.log(src);
    console.log(fill);
    text = fs.readFileSync(`${fixturesPath}/${src}`, 'utf-8');
    suite.run();
});
