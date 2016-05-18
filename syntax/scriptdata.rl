%%{
    machine html;

    ScriptData := (
        _SafeText
    ) :> (
        '<' @StartSlice @To_ScriptDataLessThanSign
    )?;

    ScriptDataLessThanSign := (
        _SpecialEndTag |
        '!--' @To_ScriptDataEscapedDashDash
    ) @err(EmitSlice) @err(Reconsume) @err(To_ScriptData);

    ScriptDataEscaped := _SafeText :> ((
        '-' @To_ScriptDataEscapedDash |
        '<' @To_ScriptDataEscapedLessThanSign
    ) >StartSlice)?;

    ScriptDataEscapedDash := (
        (
            '-' @To_ScriptDataEscapedDashDash |
            '<' @EmitSlice @StartSlice @To_ScriptDataEscapedLessThanSign
        ) >1 |
        any >0 @EmitSlice @Reconsume @To_ScriptDataEscaped
    ) @eof(EmitSlice);

    ScriptDataEscapedDashDash := '-'* <: (
        (
            '<' @To_ScriptDataEscapedLessThanSign |
            '>' @EmitSlice @Reconsume @To_ScriptData
        ) >1 |
        any >0 @EmitSlice @Reconsume @To_ScriptDataEscaped
    ) @eof(EmitSlice);

    ScriptDataEscapedLessThanSign := (
        _SpecialEndTag |
        (/script/i TagNameEnd) @EmitSlice @Reconsume @To_ScriptDataDoubleEscaped
    ) @err(EmitSlice) @err(Reconsume) @err(To_ScriptDataEscaped);

    ScriptDataDoubleEscaped := _SafeText :> ((
        '-' @To_ScriptDataDoubleEscapedDash |
        '<' @To_ScriptDataDoubleEscapedLessThanSign
    ) >StartSlice)?;

    ScriptDataDoubleEscapedDash := (
        (
            '-' @To_ScriptDataDoubleEscapedDashDash |
            '<' @To_ScriptDataDoubleEscapedLessThanSign
        ) >1 |
        any >0 @EmitSlice @Reconsume @To_ScriptDataDoubleEscaped
    ) @eof(EmitSlice);

    ScriptDataDoubleEscapedDashDash := '-'* <: (
        (
            '<' @To_ScriptDataDoubleEscapedLessThanSign |
            '>' @EmitSlice @Reconsume @To_ScriptData
        ) >1 |
        any >0 @EmitSlice @Reconsume @To_ScriptDataDoubleEscaped
    ) @eof(EmitSlice);

    ScriptDataDoubleEscapedLessThanSign := (
        '/' /script/i TagNameEnd @EmitSlice @Reconsume @To_ScriptDataEscaped
    ) @err(EmitSlice) @err(Reconsume) @err(To_ScriptDataDoubleEscaped);
}%%
