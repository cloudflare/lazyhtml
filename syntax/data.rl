%%{
    machine html;

    Data := ((
        _CRLF $2 |
        (
            _Entity |
            ^('&' | CR)
        )+ $1 %0 >StartSlice %AppendSlice %eof(AppendSlice)
    )+ %2 >StartString %EmitString <eof(EmitString))? :> '<' @StartString @StartSlice @To_TagOpen;

    TagOpen := (
        (
            '!' @To_MarkupDeclarationOpen |
            '/' @To_EndTagOpen |
            alpha @CreateStartTagToken @Reconsume @To_StartTagName |
            '?' @Reconsume @To_BogusComment
        ) >1 |
        any >0 @AppendSlice @EmitString @Reconsume @To_Data
    ) @eof(AppendSlice) @eof(EmitString);

    _BogusComment = _SafeString :> '>' @EmitComment @To_Data @eof(EmitComment);

    BogusComment := _BogusComment;

    MarkupDeclarationOpen := (
        (
            '--' @To_Comment |
            /DOCTYPE/i @To_DocType |
            '[' when IsCDataAllowed 'CDATA[' @To_CDataSection
        ) @1 |
        _BogusComment $0
    );
}%%
