%%{
    machine html;

    ScriptData := _UnsafeText :> (
        '<' @StartSlice @To_ScriptDataLessThanSign
    )?;

    ScriptDataLessThanSign := (
        _SpecialEndTag |
        '!--' >CreateCharacter >UnsafeNull @To_ScriptDataEscapedDashDash
    ) @err(EmitSlice) @err(Reconsume) @err(To_ScriptData);

    ScriptDataEscaped := _UnsafeText :> (
        '-' @CreateCharacter @UnsafeNull @StartSlice @To_ScriptDataEscapedDash |
        '<' @StartSlice @To_ScriptDataEscapedLessThanSign
    ) @eof(Err_EofInScriptHtmlCommentLikeText);

    ScriptDataEscapedDash := (
        (
            '-' @To_ScriptDataEscapedDashDash |
            '<' @EmitSlice @StartSlice @To_ScriptDataEscapedLessThanSign
        ) >1 |
        any >0 @EmitSlice @Reconsume @To_ScriptDataEscaped
    ) @eof(Err_EofInScriptHtmlCommentLikeText) @eof(EmitSlice);

    ScriptDataEscapedDashDash := '-'* <: (
        (
            '<' @EmitSlice @StartSlice @To_ScriptDataEscapedLessThanSign |
            '>' @EmitSlice @Reconsume @To_ScriptData
        ) >1 |
        any >0 @EmitSlice @Reconsume @To_ScriptDataEscaped
    ) @eof(Err_EofInScriptHtmlCommentLikeText) @eof(EmitSlice);

    ScriptDataEscapedLessThanSign := (
        _SpecialEndTag |
        (/script/i TagNameEnd) @CreateCharacter @UnsafeNull @To_ScriptDataDoubleEscaped
    ) @err(CreateCharacter) @err(EmitSlice) @err(Reconsume) @err(To_ScriptDataEscaped);

    ScriptDataDoubleEscaped := any* :> (
        '-' @To_ScriptDataDoubleEscapedDash |
        '<' @To_ScriptDataDoubleEscapedLessThanSign
    ) @eof(Err_EofInScriptHtmlCommentLikeText) @eof(EmitSlice);

    ScriptDataDoubleEscapedDash := (
        (
            '-' @To_ScriptDataDoubleEscapedDashDash |
            '<' @To_ScriptDataDoubleEscapedLessThanSign
        ) >1 |
        any >0 @To_ScriptDataDoubleEscaped
    ) @eof(Err_EofInScriptHtmlCommentLikeText) @eof(EmitSlice);

    ScriptDataDoubleEscapedDashDash := '-'* <: (
        (
            '<' @To_ScriptDataDoubleEscapedLessThanSign |
            '>' @EmitSlice @Reconsume @To_ScriptData
        ) >1 |
        any >0 @To_ScriptDataDoubleEscaped
    ) @eof(Err_EofInScriptHtmlCommentLikeText) @eof(EmitSlice);

    ScriptDataDoubleEscapedLessThanSign := (
        '/' /script/i TagNameEnd @EmitSlice @Reconsume @To_ScriptDataEscaped
    ) @err(Reconsume) @err(To_ScriptDataDoubleEscaped);
}%%
