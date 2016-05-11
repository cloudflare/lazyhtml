%%{
    machine html;

    include 'syntax/_navigation.rl';
    include 'syntax/_helpers.rl';

    include 'syntax/data.rl';

    include 'syntax/starttag.rl';
    include 'syntax/endtag.rl';

    include 'syntax/comment.rl';
    include 'syntax/doctype.rl';
    include 'syntax/cdata.rl';

    include 'syntax/scriptdata.rl';
    include 'syntax/rcdata.rl';
    include 'syntax/rawtext.rl';
    include 'syntax/plaintext.rl';
}%%
