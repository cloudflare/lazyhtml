%%{
    machine html;

    CDataSection := (
        start: any* :> (
            ']' @MarkPosition -> cdata_end
        ) @eof(EmitSlice),

        cdata_end: (
            ']' >1 -> cdata_end_right_bracket |
            any >0 -> start
        ) @eof(EmitSlice),

        cdata_end_right_bracket: ']'* $AdvanceMarkedPosition <: (
            '>' >1 @EmitSliceBeforeTheMark -> final |
            any >0 -> start
        ) @eof(EmitSlice)
    ) >StartCData >StartSlice @EmitString @To_Data;
}%%
