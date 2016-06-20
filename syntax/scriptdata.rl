%%{
    machine html;

    ScriptData := (
        _SafeText
    ) :> (
        '<' @StartSlice @To_ScriptDataLessThanSign
    )?;

    ScriptDataLessThanSign := (
        _SpecialEndTag |
        '!--' >StartSafe @To_ScriptDataEscapedDashDash
    ) @err(EmitSlice) @err(Reconsume) @err(To_ScriptData);

    ScriptDataEscaped := _SafeText :> (
        '-' @StartSafe @StartSlice @To_ScriptDataEscapedDash |
        '<' @StartSlice @To_ScriptDataEscapedLessThanSign
    );

    ScriptDataEscapedDash := (
        (
            '-' @To_ScriptDataEscapedDashDash |
            '<' @EmitSlice @StartSlice @To_ScriptDataEscapedLessThanSign
        ) >1 |
        any >0 @EmitSlice @Reconsume @To_ScriptDataEscaped
    ) @eof(EmitSlice);

    ScriptDataEscapedDashDash := '-'* <: (
        (
            '<' @EmitSlice @StartSlice @To_ScriptDataEscapedLessThanSign |
            '>' @EmitSlice @Reconsume @To_ScriptData
        ) >1 |
        any >0 @EmitSlice @Reconsume @To_ScriptDataEscaped
    ) @eof(EmitSlice);

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
    ) @err(Reconsume) @err(To_ScriptDataDoubleEscaped);
}%%
