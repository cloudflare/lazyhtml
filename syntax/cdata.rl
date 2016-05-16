%%{
    machine html;

    CDataSection := (
        start: any* :> (
            ']' @MarkPosition -> cdata_end
        ),

        cdata_end: (
            ']' >1 -> cdata_end_right_bracket |
            any >0 -> start
        ),

        cdata_end_right_bracket: ']'* $AdvanceMarkedPosition <: (
            '>' >1 -> final |
            any >0 -> start
        )
    ) >StartCData >StartSlice @EmitSliceBeforeTheMark @eof(EmitSlice) @To_Data;
}%%
