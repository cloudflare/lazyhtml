%%{
    machine html;

    RawText := (
        _SafeText
    ) :> '<' @StartString @StartSlice @To_RawTextLessThanSign;

    RawTextLessThanSign := _SpecialEndTag @err(To_RawText);
}%%
