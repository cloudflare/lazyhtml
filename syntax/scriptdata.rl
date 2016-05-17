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
    ) @err(MarkPosition) @err(EmitSlice) @err(Reconsume) @err(To_ScriptData);

    ScriptDataEscaped := _SafeText :> ((
        '-' @To_ScriptDataEscapedDash |
        '<' @To_ScriptDataEscapedLessThanSign
    ) >StartSlice)?;

    ScriptDataEscapedDash := (
        (
            '-' @To_ScriptDataEscapedDashDash |
            '<' @MarkPosition @EmitSlice @StartSlice @To_ScriptDataEscapedLessThanSign
        ) >1 |
        any >0 @MarkPosition @EmitSlice @Reconsume @To_ScriptDataEscaped
    ) @eof(MarkPosition) @eof(EmitSlice);

    ScriptDataEscapedDashDash := '-'* <: (
        (
            '<' @To_ScriptDataEscapedLessThanSign |
            '>' @MarkPosition @EmitSlice @Reconsume @To_ScriptData
        ) >1 |
        any >0 @MarkPosition @EmitSlice @Reconsume @To_ScriptDataEscaped
    ) @eof(MarkPosition) @eof(EmitSlice);

    ScriptDataEscapedLessThanSign := (
        _SpecialEndTag |
        (/script/i TagNameEnd) @MarkPosition @EmitSlice @Reconsume @To_ScriptDataDoubleEscaped
    ) @err(MarkPosition) @err(EmitSlice) @err(Reconsume) @err(To_ScriptDataEscaped);

    ScriptDataDoubleEscaped := _SafeText :> ((
        '-' @To_ScriptDataDoubleEscapedDash |
        '<' @To_ScriptDataDoubleEscapedLessThanSign
    ) >StartSlice)?;

    ScriptDataDoubleEscapedDash := (
        (
            '-' @To_ScriptDataDoubleEscapedDashDash |
            '<' @To_ScriptDataDoubleEscapedLessThanSign
        ) >1 |
        any >0 @MarkPosition @EmitSlice @Reconsume @To_ScriptDataDoubleEscaped
    ) @eof(MarkPosition) @eof(EmitSlice);

    ScriptDataDoubleEscapedDashDash := '-'* <: (
        (
            '<' @To_ScriptDataDoubleEscapedLessThanSign |
            '>' @MarkPosition @EmitSlice @Reconsume @To_ScriptData
        ) >1 |
        any >0 @MarkPosition @EmitSlice @Reconsume @To_ScriptDataDoubleEscaped
    ) @eof(MarkPosition) @eof(EmitSlice);

    ScriptDataDoubleEscapedLessThanSign := (
        '/' /script/i TagNameEnd @MarkPosition @EmitSlice @Reconsume @To_ScriptDataEscaped
    ) @err(MarkPosition) @err(EmitSlice) @err(Reconsume) @err(To_ScriptDataDoubleEscaped);
}%%
