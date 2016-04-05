var Benchmark = require('benchmark');
var MyTokenizer = require('../js-tokenizer').HtmlTokenizer;
var Parse5Tokenizer = require('parse5/lib/tokenizer');
var text = require('fs').readFileSync(`${__dirname}/huge-page.html`, 'utf-8');

new Benchmark.Suite()
    .add('my', function() {
        var tokenizer = new MyTokenizer({
            onToken() {}
        });
        tokenizer.feed(text, true);
    })
    .add('parse5', function() {
        var tokenizer = new Parse5Tokenizer();
        tokenizer.write(text, true);
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
    .on('complete', function() {
        console.log('Fastest is ' + this.filter('fastest').map('name'));
    })
    .run();
