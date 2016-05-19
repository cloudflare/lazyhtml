%%{
    machine html;

    Comment := (
        start: (
            (
                '-' -> comment_start_dash |
                '>' -> final
            ) >1 >MarkPosition |
            any >0 -> text_slice
        ),

        comment_start_dash: (
            (
                '-' -> comment_end |
                '>' -> final
            ) >1 |
            any >0 -> text_slice
        ),

        text_slice: any* :> (
            '-' @MarkPosition -> comment_end_dash
        ) @eof(MarkPosition),

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
                '>' -> final
            ) >1 |
            any >0 -> text_slice
        )
    ) >StartSlice >eof(StartSlice) >eof(MarkPosition) @EmitComment @To_Data @eof(EmitComment);
}%%
