%%{
    machine html;

    RCData := ((
        _NUL |
        _CRLF $2 |
        (
            _Entity |
            ^(0 | CR | '&')
        )+ $1 %0 >StartSlice %AppendSlice %eof(AppendSlice)
    )+ %2 >StartString %EmitString <eof(EmitString))? :> '<' @StartString @StartSlice @To_RCDataLessThanSign;

    RCDataLessThanSign := _SpecialEndTag @err(To_RCData);
}%%
