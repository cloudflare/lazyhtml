%%{
    machine html;

    Comment := (
        start: (
            (
                '-' -> comment_start_dash |
                '<' -> comment_less_than_sign |
                '>' @Err_AbruptClosingOfEmptyComment -> final
            ) >1 >MarkPosition |
            any >0 -> text_slice
        ),

        comment_start_dash: (
            (
                '-' -> comment_end |
                '>' @Err_AbruptClosingOfEmptyComment -> final
            ) >1 |
            any >0 -> text_slice
        ),

        text_slice: any* :> (
            '<' @MarkPosition -> comment_less_than_sign |
            '-' @MarkPosition -> comment_end_dash
        ) @eof(MarkPosition),

        comment_less_than_sign: '<'* $AdvanceMarkedPosition <: (
            '!' >1 -> comment_less_than_sign_bang |
            any >0 @Reconsume -> text_slice
        ) @eof(MarkPosition),

        comment_less_than_sign_bang: (
            '-' >1 -> comment_less_than_sign_bang_dash |
            any >0 @Reconsume -> text_slice
        ),

        comment_less_than_sign_bang_dash: (
            '-' >1 ->comment_less_than_sign_bang_dash_dash |
            any >0 @Reconsume -> text_slice
        ),

        comment_less_than_sign_bang_dash_dash: (
            (
                '>' -> final |
                '!' -> comment_end_bang
            ) >1 |
            any >0 @Err_NestedComment -> text_slice
        ),

        comment_end_dash: (
            '-' >1 -> comment_end |
            any >0 -> text_slice
        ),

        comment_end: '-'* $AdvanceMarkedPosition <: (
            (
                '>' -> final |
                '!' -> comment_end_bang
            ) >1 |
            any >0 -> text_slice
        ),

        comment_end_bang: (
            (
                '-' @MarkPosition -> comment_end_dash |
                '>' @Err_IncorrectlyClosedComment -> final
            ) >1 |
            any >0 -> text_slice
        )
    ) >StartSlice >eof(StartSlice) >eof(MarkPosition) @EndComment @EmitToken @UnmarkPosition @To_Data @eof(Err_EofInComment) @eof(EndComment) @eof(EmitToken);
}%%
