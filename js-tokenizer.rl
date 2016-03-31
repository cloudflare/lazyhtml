%%{
    machine html;

    access this.;

    include 'js-actions.rl';
    include 'syntax.rl';

    write data;
}%%

class HtmlTokenizer {
    constructor() {
        %%write init;
    }

    feed(data, isEnd) {
        let p = 0;
        const pe = data.length;
        const eof = isEnd ? pe : -1;
        %%write exec;
        if (this.cs === html_error) {
            throw new Error('Tokenization error at ' + p);
        }
    }

    end() {
        this.feed('', true);
    }
}

const tokenizer = new HtmlTokenizer();
tokenizer.feed("<![CDATA[x");
tokenizer.end();
