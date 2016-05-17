%%{
    machine html;

    Data := (any+ >StartData >StartSlice %MarkPosition %EmitSlice)? :> (
        '<' @StartString @StartSlice @To_TagOpen
    )?;

    TagOpen := (
        (
            '!' @To_MarkupDeclarationOpen |
            '/' @To_EndTagOpen |
            alpha @CreateStartTagToken @Reconsume @To_StartTagName |
            '?' @Reconsume @To_BogusComment
        ) >1 |
        any >0 @MarkPosition @EmitSlice @Reconsume @To_Data
    ) @eof(MarkPosition) @eof(EmitSlice);

    _BogusComment = _String :> '>' @EmitComment @To_Data @eof(EmitComment);

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
