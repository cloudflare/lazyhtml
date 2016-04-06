'use strict';

var Benchmark = require('benchmark');
var MyTokenizer = require('../js-tokenizer').HtmlTokenizer;
var Parse5Tokenizer = require('parse5/lib/tokenizer');
var text = require('fs').readFileSync(`${__dirname}/huge-page.html`, 'utf-8');
var text2 = require('fs').readFileSync(`${__dirname}/huge-page-2.html`, 'utf-8');

new Benchmark.Suite()
    .add('my #1', function() {
        new MyTokenizer({
            onToken() {}
        }).feed(text, true);
    })
    .add('parse5 #1', function() {
        var tokenizer = new Parse5Tokenizer();
        tokenizer.write(text, true);
        do {
            var token = tokenizer.getNextToken();
        } while (token.type !== 'EOF_TOKEN');
    })
    .add('my #2', function() {
        new MyTokenizer({
            onToken() {}
        }).feed(text2, true);
    })
    .add('parse5 #2', function() {
        var tokenizer = new Parse5Tokenizer();
        tokenizer.write(text2, true);
        do {
            var token = tokenizer.getNextToken();
        } while (token.type !== 'EOF_TOKEN');
    })
    .on('error', function(event) {
        throw event.target.error;
    })
    .on('cycle', function(event) {
        console.log(String(event.target));
    })
    .run();
