%%{
    machine html;

    CDataSection := (
        start: (
            ']' >1 @StartSlice @MarkPosition -> cdata_end |
            CR >1 -> crlf |
            any >0 @StartSlice -> text_slice
        ),

        text_slice: any* :> (
            CR @AppendSlice -> crlf |
            ']' @MarkPosition -> cdata_end
        ) @eof(AppendSlice) @eof(EmitString),

        crlf: CR* $AppendLFCharacter <: (
            LF >1 |
            any >0 @AppendLFCharacter
        ) @StartSlice @eof(AppendLFCharacter) @eof(EmitString) -> text_slice,

        cdata_end: (
            ']' >1 -> cdata_end_right_bracket |
            CR >1 @AppendSlice -> crlf |
            any >0 -> text_slice
        ) @eof(AppendSlice) @eof(EmitString),

        cdata_end_right_bracket: ']'* $AdvanceMarkedPosition <: (
            '>' >1 @AppendSliceBeforeTheMark -> final |
            CR >1 @AppendSlice -> crlf |
            any >0 -> text_slice
        ) @eof(AppendSlice) @eof(EmitString)
    ) @EmitString @To_Data;
}%%
