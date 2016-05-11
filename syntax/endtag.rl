%%{
    machine html;

    EndTagName := _Name :> _EndTagEnd >SetEndTagName;

    EndTagNameContents := (
        start: (TagNameSpace | '/')* <: (
            '>' @EmitEndTagToken @To_Data |
            any+ >0 :> (
                '/' -> start |
                '>' @EmitEndTagToken @To_Data |
                '=' TagNameSpace* <: (
                    _StartQuote >1 any* :> _EndQuote -> start |
                    '>' >1 @EmitEndTagToken @To_Data |
                    any+ >0 :> (
                        TagNameSpace -> start |
                        '>' @EmitEndTagToken @To_Data
                    )
                )
            )
        )
    );

    EndTagOpen := (
        (
            alpha @CreateEndTagToken @Reconsume @To_EndTagName |
            '>' @To_Data
        ) >1 |
        any >0 @Reconsume @To_BogusComment
    ) @eof(AppendSlice) @eof(EmitString);
}%%
