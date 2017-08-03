%%{
    machine html;

    RCData := (any+ >CreateCharacter >UnsafeNull >AllowEntities >StartSlice %EmitSlice)? :> (
        '<' @StartSlice @To_RCDataLessThanSign
    )?;

    RCDataLessThanSign := _SpecialEndTag @err(To_RCData);
}%%
