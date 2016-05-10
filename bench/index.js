'use strict';

var Benchmark = require('benchmark');
var MyTokenizer = require('../js-tokenizer').HtmlTokenizer;
var Parse5Tokenizer = require('parse5/lib/tokenizer');
var read = require('fs').readFileSync;
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

['huge-page.html', 'huge-page-2.html'].forEach(src => {
    var fill = '='.repeat(src.length);
    console.log(fill);
    console.log(src);
    console.log(fill);
    text = read(`${__dirname}/${src}`, 'utf-8');
    suite.run();
});
