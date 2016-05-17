%%{
    machine html;

    RawText := _SafeText :> (
        '<' @StartSlice @To_RawTextLessThanSign
    )?;

    RawTextLessThanSign := _SpecialEndTag @err(To_RawText);
}%%
