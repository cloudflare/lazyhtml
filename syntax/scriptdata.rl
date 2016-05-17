%%{
    machine html;

    ScriptData := (
        _SafeText
    ) :> (
        '<' @StartString @StartSlice @To_ScriptDataLessThanSign
    )?;

    ScriptDataLessThanSign := (
        _SpecialEndTag |
        '!--' @To_ScriptDataEscapedDashDash
    ) @err(AppendSlice) @err(EmitString) @err(Reconsume) @err(To_ScriptData);

    ScriptDataEscaped := _SafeText :> ((
        '-' @To_ScriptDataEscapedDash |
        '<' @To_ScriptDataEscapedLessThanSign
    ) >StartString >StartSlice)?;

    ScriptDataEscapedDash := (
        (
            '-' @To_ScriptDataEscapedDashDash |
            '<' @AppendSlice @EmitString @StartString @StartSlice @To_ScriptDataEscapedLessThanSign
        ) >1 |
        any >0 @AppendSlice @EmitString @Reconsume @To_ScriptDataEscaped
    ) @eof(AppendSlice) @eof(EmitString);

    ScriptDataEscapedDashDash := '-'* <: (
        (
            '<' @To_ScriptDataEscapedLessThanSign |
            '>' @AppendSlice @EmitString @Reconsume @To_ScriptData
        ) >1 |
        any >0 @AppendSlice @EmitString @Reconsume @To_ScriptDataEscaped
    ) @eof(AppendSlice) @eof(EmitString);

    ScriptDataEscapedLessThanSign := (
        _SpecialEndTag |
        (/script/i TagNameEnd) @AppendSlice @EmitString @Reconsume @To_ScriptDataDoubleEscaped
    ) @err(AppendSlice) @err(EmitString) @err(Reconsume) @err(To_ScriptDataEscaped);

    ScriptDataDoubleEscaped := _SafeText :> ((
        '-' @To_ScriptDataDoubleEscapedDash |
        '<' @To_ScriptDataDoubleEscapedLessThanSign
    ) >StartString >StartSlice)?;

    ScriptDataDoubleEscapedDash := (
        (
            '-' @To_ScriptDataDoubleEscapedDashDash |
            '<' @To_ScriptDataDoubleEscapedLessThanSign
        ) >1 |
        any >0 @AppendSlice @EmitString @Reconsume @To_ScriptDataDoubleEscaped
    ) @eof(AppendSlice) @eof(EmitString);

    ScriptDataDoubleEscapedDashDash := '-'* <: (
        (
            '<' @To_ScriptDataDoubleEscapedLessThanSign |
            '>' @AppendSlice @EmitString @Reconsume @To_ScriptData
        ) >1 |
        any >0 @AppendSlice @EmitString @Reconsume @To_ScriptDataDoubleEscaped
    ) @eof(AppendSlice) @eof(EmitString);

    ScriptDataDoubleEscapedLessThanSign := (
        '/' /script/i TagNameEnd @AppendSlice @EmitString @Reconsume @To_ScriptDataEscaped
    ) @err(AppendSlice) @err(EmitString) @err(Reconsume) @err(To_ScriptDataDoubleEscaped);
}%%
