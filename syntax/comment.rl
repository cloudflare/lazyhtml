%%{
    machine html;

    Comment := (
        start: (
            (
                '-' @StartSlice @MarkPosition -> comment_start_dash |
                '>' -> final
            ) >1 |
            any >0 @StartSlice -> text_slice
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
        ) @eof(AppendSlice),

        comment_end_dash: (
            '-' >1 -> comment_end |
            any >0 -> text_slice
        ) @eof(AppendSliceBeforeTheMark),

        comment_end: '-'* $AdvanceMarkedPosition <: (
            (
                '>' @AppendSliceBeforeTheMark -> final |
                '!' -> comment_end_bang
            ) >1 |
            any >0 -> text_slice
        ) @eof(AppendSliceBeforeTheMark),

        comment_end_bang: (
            (
                '-' @MarkPosition -> comment_end_dash |
                '>' @AppendSliceBeforeTheMark -> final
            ) >1 |
            any >0 -> text_slice
        ) @eof(AppendSliceBeforeTheMark)
    ) @EmitComment @To_Data @eof(EmitComment);
}%%
