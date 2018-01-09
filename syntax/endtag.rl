%%{
    machine html;

    EndTagName := (any* :> _EndTagEnd >SetEndTagName) @eof(Err_EofInTag);

    EndTagNameContents := (
        start: (TagNameSpace)* <: (
            '/' >1 -> solidus |
            '>' >1 @EmitToken @To_Data |
            any+ >0 @Err_EndTagWithAttributes :> (
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
        ),
        solidus: (
            '>' @Err_EndTagWithTrailingSolidus @EmitToken @To_Data |
            any >0 @Reconsume -> start
        )
    ) @eof(Err_EofInTag);

    EndTagOpen := (
        (
            alpha @CreateEndTagToken @StartSlice @To_EndTagName |
            '>' @Err_MissingEndTagName @CreateUnparsed @EmitToken @To_Data
        ) >1 |
        any >0 @Err_InvalidFirstCharacterOfTagName @StartSlice @Reconsume @To_BogusComment
    ) @eof(Err_EofBeforeTagName) @eof(CreateCharacter) @eof(EmitSlice);
}%%
