%%{
    machine html;

    RCData := (any+ >StartRCData >StartSlice %EmitSlice <eof(EmitSlice))? :> '<' @StartString @StartSlice @To_RCDataLessThanSign;

    RCDataLessThanSign := _SpecialEndTag @err(To_RCData);
}%%
