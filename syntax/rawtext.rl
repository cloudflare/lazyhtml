%%{
    machine html;

    RawText := _UnsafeText :> (
        '<' @StartSlice @To_RawTextLessThanSign
    )?;

    RawTextLessThanSign := _SpecialEndTag @err(To_RawText);
}%%
