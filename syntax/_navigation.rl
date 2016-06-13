%%{
    machine html;

    action Reconsume { fhold; }

    action Next_Data { fnext Data; }

    action To_TagOpen { fgoto TagOpen; }
    action To_Data { fgoto Data; }
    action To_RCDataLessThanSign { fgoto RCDataLessThanSign; }
    action To_RCData { fgoto RCData; }
    action To_RawTextLessThanSign { fgoto RawTextLessThanSign; }
    action To_RawText { fgoto RawText; }
    action To_ScriptDataLessThanSign { fgoto ScriptDataLessThanSign; }
    action To_ScriptData { fgoto ScriptData; }
    action To_MarkupDeclarationOpen { fgoto MarkupDeclarationOpen; }
    action To_EndTagOpen { fgoto EndTagOpen; }
    action To_StartTagName { fgoto StartTagName; }
    action To_EndTagName { fgoto EndTagName; }
    action To_EndTagNameContents { fgoto EndTagNameContents; }
    action To_BogusComment { fgoto BogusComment; }
    action To_BeforeAttributeName { fgoto BeforeAttributeName; }
    action To_SelfClosingTag { fgoto SelfClosingTag; }
    action To_ScriptDataEscapedDashDash { fgoto ScriptDataEscapedDashDash; }
    action To_ScriptDataEscapedDash { fgoto ScriptDataEscapedDash; }
    action To_ScriptDataEscapedLessThanSign { fgoto ScriptDataEscapedLessThanSign; }
    action To_ScriptDataEscaped { fgoto ScriptDataEscaped; }
    action To_ScriptDataDoubleEscaped { fgoto ScriptDataDoubleEscaped; }
    action To_ScriptDataDoubleEscapedDash { fgoto ScriptDataDoubleEscapedDash; }
    action To_ScriptDataDoubleEscapedLessThanSign { fgoto ScriptDataDoubleEscapedLessThanSign; }
    action To_ScriptDataDoubleEscapedDashDash { fgoto ScriptDataDoubleEscapedDashDash; }
    action To_AttributeName { fgoto AttributeName; }
    action To_AfterAttributeName { fgoto AfterAttributeName; }
    action To_BeforeAttributeValue { fgoto BeforeAttributeValue; }
    action To_AttributeValueQuoted { fgoto AttributeValueQuoted; }
    action To_AttributeValueUnquoted { fgoto AttributeValueUnquoted; }
    action To_DocType { fgoto DocType; }
    action To_CDataSection { fgoto CDataSection; }
    action To_Comment { fgoto Comment; }
    action To_DocTypeName { fgoto DocTypeName; }
    action To_AfterDocTypeName { fgoto AfterDocTypeName; }
    action To_BeforeDocTypePublicIdentifier { fgoto BeforeDocTypePublicIdentifier; }
    action To_DocTypePublicIdentifierQuoted { fgoto DocTypePublicIdentifierQuoted; }
    action To_BogusDocType { fgoto BogusDocType; }
    action To_BetweenDocTypePublicAndSystemIdentifiers { fgoto BetweenDocTypePublicAndSystemIdentifiers; }
    action To_DocTypeSystemIdentifierQuoted { fgoto DocTypeSystemIdentifierQuoted; }
    action To_BeforeDocTypeSystemIdentifier { fgoto BeforeDocTypeSystemIdentifier; }
    action To_AfterDocTypeSystemIdentifier { fgoto AfterDocTypeSystemIdentifier; }
}%%
