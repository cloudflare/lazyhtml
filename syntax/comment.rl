%%{
    machine html;

    Comment := (
        start: (
            (
                '-' @StartSlice @MarkPosition -> comment_start_dash |
                '>' -> final |
                _NUL -> text |
                CR -> crlf
            ) >1 |
            any >0 @StartSlice -> text_slice
        ),

        crlf: CR* $AppendLFCharacter <: (
            LF >1 @StartSlice -> text_slice |
            _NUL >1 >AppendLFCharacter -> text |
            '-' >1 @AppendLFCharacter @StartSlice @MarkPosition -> comment_end_dash |
            any >0 @AppendLFCharacter @StartSlice -> text_slice
        ),

        comment_start_dash: (
            (
                '-' -> comment_end |
                '>' -> final |
                _NUL >AppendSlice -> text |
                CR @AppendSlice -> crlf
            ) >1 |
            any >0 -> text_slice
        ),

        text: _NUL* <: (
            '-' >1 @StartSlice @MarkPosition -> comment_end_dash |
            CR >1 -> crlf |
            any >0 @StartSlice -> text_slice
        ),

        text_slice: any* :> (
            _NUL >AppendSlice -> text |
            '-' @MarkPosition -> comment_end_dash |
            CR @AppendSlice -> crlf
        ) @eof(AppendSlice),

        comment_end_dash: (
            (
                '-' -> comment_end |
                _NUL >AppendSlice -> text |
                CR >1 @AppendSlice -> crlf
            ) >1 |
            any >0 -> text_slice
        ) @eof(AppendSliceBeforeTheMark),

        comment_end: '-'* $AdvanceMarkedPosition <: (
            (
                '>' @AppendSliceBeforeTheMark -> final |
                '!' -> comment_end_bang |
                _NUL >AppendSlice -> text |
                CR @AppendSlice -> crlf
            ) >1 |
            any >0 -> text_slice
        ) @eof(AppendSliceBeforeTheMark),

        comment_end_bang: (
            (
                '-' @MarkPosition -> comment_end_dash |
                '>' @AppendSliceBeforeTheMark -> final |
                _NUL >AppendSlice -> text |
                CR @AppendSlice -> crlf
            ) >1 |
            any >0 -> text_slice
        ) @eof(AppendSliceBeforeTheMark)
    ) @EmitComment @To_Data @eof(EmitComment);
}%%
