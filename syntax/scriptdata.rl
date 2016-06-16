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
    ) @err(AsRawSlice) @err(EmitSlice) @err(Reconsume) @err(To_ScriptData);

    ScriptDataEscaped := _SafeText :> ((
        '-' @To_ScriptDataEscapedDash |
        '<' @To_ScriptDataEscapedLessThanSign
    ) >StartSlice)?;

    ScriptDataEscapedDash := (
        (
            '-' @To_ScriptDataEscapedDashDash |
            '<' @AsRawSlice @EmitSlice @StartSlice @To_ScriptDataEscapedLessThanSign
        ) >1 |
        any >0 @AsRawSlice @EmitSlice @Reconsume @To_ScriptDataEscaped
    ) @eof(AsRawSlice) @eof(EmitSlice);

    ScriptDataEscapedDashDash := '-'* <: (
        (
            '<' @AsRawSlice @EmitSlice @StartSlice @To_ScriptDataEscapedLessThanSign |
            '>' @AsRawSlice @EmitSlice @Reconsume @To_ScriptData
        ) >1 |
        any >0 @AsRawSlice @EmitSlice @Reconsume @To_ScriptDataEscaped
    ) @eof(AsRawSlice) @eof(EmitSlice);

    ScriptDataEscapedLessThanSign := (
        _SpecialEndTag |
        (/script/i TagNameEnd) @StartSafe @To_ScriptDataDoubleEscaped
    ) @err(AsRawSlice) @err(EmitSlice) @err(Reconsume) @err(To_ScriptDataEscaped);

    ScriptDataDoubleEscaped := any* :> (
        '-' @To_ScriptDataDoubleEscapedDash |
        '<' @To_ScriptDataDoubleEscapedLessThanSign
    ) @eof(EmitSlice);

    ScriptDataDoubleEscapedDash := (
        (
            '-' @To_ScriptDataDoubleEscapedDashDash |
            '<' @To_ScriptDataDoubleEscapedLessThanSign
        ) >1 |
        any >0 @To_ScriptDataDoubleEscaped
    ) @eof(EmitSlice);

    ScriptDataDoubleEscapedDashDash := '-'* <: (
        (
            '<' @To_ScriptDataDoubleEscapedLessThanSign |
            '>' @EmitSlice @Reconsume @To_ScriptData
        ) >1 |
        any >0 @To_ScriptDataDoubleEscaped
    ) @eof(EmitSlice);

    ScriptDataDoubleEscapedLessThanSign := (
        '/' /script/i TagNameEnd @EmitSlice @Reconsume @To_ScriptDataEscaped
    ) @err(To_ScriptDataDoubleEscaped);
}%%
