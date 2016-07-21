%%{
    machine html;

    include '_navigation.rl';
    include '_helpers.rl';

    include 'data.rl';

    include 'starttag.rl';
    include 'endtag.rl';

    include 'comment.rl';
    include 'doctype.rl';
    include 'cdata.rl';

    include 'scriptdata.rl';
    include 'rcdata.rl';
    include 'rawtext.rl';
    include 'plaintext.rl';
}%%
