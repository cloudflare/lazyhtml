%%{
    machine html;

    Data := (any+ >CreateCharacter >AllowEntities >StartSlice %EmitSlice)? :> (
        '<' @StartSlice @To_TagOpen
    )?;

    TagOpen := (
        (
            '!' @To_MarkupDeclarationOpen |
            '/' @To_EndTagOpen |
            alpha @CreateStartTagToken @StartSlice @To_StartTagName |
            '?' @Err_UnexpectedQuestionMarkInsteadOfTagName @StartSlice @Reconsume @To_BogusComment
        ) >1 |
        any >0 @Err_InvalidFirstCharacterOfTagName @CreateCharacter @EmitSlice @Reconsume @To_Data
    ) @eof(Err_EofBeforeTagName) @eof(CreateCharacter) @eof(EmitSlice);

    BogusComment := any* %MarkPosition %EndComment %EmitToken %UnmarkPosition :> ('>' @To_Data)?;

    MarkupDeclarationOpen := (
        '--' @To_Comment |
        /DOCTYPE/i @To_DocType |
        ('[CDATA' (
            '[' when IsCDataAllowed @CreateCDataStart @EmitToken @To_CDataSection |
            '[' @Err_CDataInHtmlContent @To_BogusComment
        ))
    ) >StartSlice >err(StartSlice) $err(Err_IncorrectlyOpenedComment) $err(Reconsume) $err(To_BogusComment);
}%%
