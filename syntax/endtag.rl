%%{
    machine html;

    EndTagName := any* :> _EndTagEnd >SetEndTagName;

    EndTagNameContents := (
        start: (TagNameSpace | '/')* <: (
            '>' @EmitToken @To_Data |
            any+ >0 :> (
                '/' -> start |
                '>' @EmitToken @To_Data |
                '=' TagNameSpace* <: (
                    _StartQuote >1 any* :> _EndQuote -> start |
                    '>' >1 @EmitToken @To_Data |
                    any+ >0 :> (
                        TagNameSpace -> start |
                        '>' @EmitToken @To_Data
                    )
                )
            )
        )
    );

    EndTagOpen := (
        (
            alpha @CreateEndTagToken @StartSlice @To_EndTagName |
            '>' @CreateUnparsed @EmitToken @To_Data
        ) >1 |
        any >0 @Reconsume @To_BogusComment
    ) @eof(CreateCharacter) @eof(EmitSlice);
}%%
