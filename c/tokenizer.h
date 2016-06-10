#ifndef HTML_TOKENIZER_H
#define HTML_TOKENIZER_H

#include <stddef.h>
#include <stdbool.h>
#include <stdint.h>

extern const int html_state_error;
extern const int html_state_Data;
extern const int html_state_RCData;
extern const int html_state_RawText;
extern const int html_state_PlainText;
extern const int html_state_ScriptData;

typedef struct {
    size_t length;
    const char *data;
} TokenizerString;

typedef struct {
    bool has_value;
    TokenizerString value;
} TokenizerOptionalString;

typedef enum {
    token_none,
    token_character,
    token_comment,
    token_start_tag,
    token_end_tag,
    token_doc_type
} TokenType;

typedef enum {
    token_character_raw,
    token_character_data,
    token_character_rcdata,
    token_character_cdata,
    token_character_safe
} TokenCharacterKind;

typedef struct {
    TokenCharacterKind kind;
    TokenizerString value;
} TokenCharacter;

typedef struct {
    TokenizerString value;
} TokenComment;

typedef struct {
    TokenizerString name;
    TokenizerString value;
} Attribute;

#define MAX_ATTR_COUNT 256

typedef struct {
    size_t count;
    Attribute items[MAX_ATTR_COUNT];
} TokenAttributes;

typedef enum {
    // Regular elements
    HTML_TAG_A = 1,
    HTML_TAG_ABBR = 34898,
    HTML_TAG_ADDRESS = 1212749427,
    HTML_TAG_AREA = 51361,
    HTML_TAG_ARTICLE = 1698991493,
    HTML_TAG_ASIDE = 1680517,
    HTML_TAG_AUDIO = 1741103,
    HTML_TAG_B = 2,
    HTML_TAG_BASE = 67173,
    HTML_TAG_BDI = 2185,
    HTML_TAG_BDO = 2191,
    HTML_TAG_BLOCKQUOTE = 84081888640645,
    HTML_TAG_BODY = 81049,
    HTML_TAG_BR = 82,
    HTML_TAG_BUTTON = 89805294,
    HTML_TAG_CANVAS = 102193203,
    HTML_TAG_CAPTION = 3272222190,
    HTML_TAG_CITE = 108165,
    HTML_TAG_CODE = 113797,
    HTML_TAG_COL = 3564,
    HTML_TAG_COLGROUP = 119595941552,
    HTML_TAG_DATA = 132737,
    HTML_TAG_DATALIST = 139185235572,
    HTML_TAG_DD = 132,
    HTML_TAG_DEL = 4268,
    HTML_TAG_DETAILS = 4483753363,
    HTML_TAG_DFN = 4302,
    HTML_TAG_DIALOG = 143700455,
    HTML_TAG_DIV = 4406,
    HTML_TAG_DL = 140,
    HTML_TAG_DT = 148,
    HTML_TAG_EM = 173,
    HTML_TAG_EMBED = 5671076,
    HTML_TAG_FIELDSET = 216002612404,
    HTML_TAG_FIGCAPTION = 221245627573742,
    HTML_TAG_FIGURE = 211015237,
    HTML_TAG_FOOTER = 217567410,
    HTML_TAG_FORM = 212557,
    HTML_TAG_HEAD = 267300,
    HTML_TAG_HEADER = 273715378,
    HTML_TAG_HGROUP = 276381360,
    HTML_TAG_HR = 274,
    HTML_TAG_HTML = 283052,
    HTML_TAG_I = 9,
    HTML_TAG_IFRAME = 308872613,
    HTML_TAG_IMG = 9639,
    HTML_TAG_INPUT = 9913012,
    HTML_TAG_INS = 9683,
    HTML_TAG_KBD = 11332,
    HTML_TAG_KEYGEN = 375168174,
    HTML_TAG_LABEL = 12617900,
    HTML_TAG_LEGEND = 408131012,
    HTML_TAG_LI = 393,
    HTML_TAG_LINK = 402891,
    HTML_TAG_MAIN = 427310,
    HTML_TAG_MAP = 13360,
    HTML_TAG_MARK = 427595,
    HTML_TAG_MATH = 427656,
    HTML_TAG_MENU = 431573,
    HTML_TAG_MENUITEM = 452537405613,
    HTML_TAG_META = 431745,
    HTML_TAG_METER = 13815986,
    HTML_TAG_NAV = 14390,
    HTML_TAG_NOSCRIPT = 497783744020,
    HTML_TAG_OBJECT = 505746548,
    HTML_TAG_OL = 492,
    HTML_TAG_OPTGROUP = 533254979248,
    HTML_TAG_OPTION = 520758766,
    HTML_TAG_OUTPUT = 526009012,
    HTML_TAG_P = 16,
    HTML_TAG_PARAM = 16828461,
    HTML_TAG_PICTURE = 17485682245,
    HTML_TAG_PRE = 16965,
    HTML_TAG_PROGRESS = 569594418803,
    HTML_TAG_Q = 17,
    HTML_TAG_RP = 592,
    HTML_TAG_RT = 596,
    HTML_TAG_RUBY = 611417,
    HTML_TAG_S = 19,
    HTML_TAG_SAMP = 624048,
    HTML_TAG_SCRIPT = 641279508,
    HTML_TAG_SECTION = 20572677614,
    HTML_TAG_SELECT = 643175540,
    HTML_TAG_SLOT = 635380,
    HTML_TAG_SMALL = 20350348,
    HTML_TAG_SOURCE = 653969509,
    HTML_TAG_SPAN = 639022,
    HTML_TAG_STRONG = 659111367,
    HTML_TAG_STYLE = 20604293,
    HTML_TAG_SUB = 20130,
    HTML_TAG_SUMMARY = 21119796825,
    HTML_TAG_SUP = 20144,
    HTML_TAG_SVG = 20167,
    HTML_TAG_TABLE = 21006725,
    HTML_TAG_TBODY = 21052569,
    HTML_TAG_TD = 644,
    HTML_TAG_TEMPLATE = 693016856197,
    HTML_TAG_TEXTAREA = 693389805729,
    HTML_TAG_TFOOT = 21183988,
    HTML_TAG_TH = 648,
    HTML_TAG_THEAD = 21238820,
    HTML_TAG_TIME = 664997,
    HTML_TAG_TITLE = 21287301,
    HTML_TAG_TR = 658,
    HTML_TAG_TRACK = 21562475,
    HTML_TAG_U = 21,
    HTML_TAG_UL = 684,
    HTML_TAG_VAR = 22578,
    HTML_TAG_VIDEO = 23367855,
    HTML_TAG_WBR = 23634,

    // Obsolete elements
    HTML_TAG_APPLET = 50868404,
    HTML_TAG_ACRONYM = 1193786157,
    HTML_TAG_BGSOUND = 2402801092,
    HTML_TAG_DIR = 4402,
    HTML_TAG_FRAME = 6882725,
    HTML_TAG_FRAMESET = 225533152436,
    HTML_TAG_NOFRAMES = 497362711731,
    HTML_TAG_ISINDEX = 10311110840,
    HTML_TAG_LISTING = 13207479751,
    HTML_TAG_NEXTID = 475812132,
    HTML_TAG_NOEMBED = 15541373092,
    HTML_TAG_PLAINTEXT = 18005893977876,
    HTML_TAG_RB = 578,
    HTML_TAG_RTC = 19075,
    HTML_TAG_STRIKE = 659105125,
    HTML_TAG_XMP = 25008,
    HTML_TAG_BASEFONT = 70436208084,
    HTML_TAG_BIG = 2343,
    HTML_TAG_BLINK = 2500043,
    HTML_TAG_CENTER = 106385586,
    HTML_TAG_FONT = 212436,
    HTML_TAG_MARQUEE = 14011651237,
    HTML_TAG_MULTICOL = 469649100268,
    HTML_TAG_NOBR = 474194,
    HTML_TAG_SPACER = 654347442,
    HTML_TAG_TT = 660,
    HTML_TAG_IMAGE = 9864421,

    // MathML text integration points
    HTML_TAG_MI = 425,
    HTML_TAG_MO = 431,
    HTML_TAG_MN = 430,
    HTML_TAG_MS = 435,
    HTML_TAG_MTEXT = 14292756,

    // SVG HTML integration points
    HTML_TAG_DESC = 136803,
    // HTML_TAG_TITLE // already exists,
    // HTML_TAG_FOREIGNOBJECT // too long,
} HtmlTagType;

typedef struct {
    TokenizerString name;
    HtmlTagType type;
    TokenAttributes attributes;
    bool self_closing;
} TokenStartTag;

typedef struct {
    TokenizerString name;
    HtmlTagType type;
} TokenEndTag;

typedef struct {
    TokenizerOptionalString name;
    TokenizerOptionalString public_id;
    TokenizerOptionalString system_id;
    bool force_quirks;
} TokenDocType;

typedef struct {
    TokenType type;
    union {
        TokenCharacter character;
        TokenComment comment;
        TokenStartTag start_tag;
        TokenEndTag end_tag;
        TokenDocType doc_type;
    };
    TokenizerString raw;
} Token;

typedef __attribute__((nonnull(1))) void (*TokenHandler)(Token *token, void *extra);

typedef struct {
    int cs;
    char quote;
    bool allow_cdata;
    TokenHandler emit_token;
    TokenizerString last_start_tag_name;
    Token token;
    Attribute *attribute;
    const char *start_slice;
    const char *mark;
    const char *appropriate_end_tag_offset;
    char *buffer;
    char *buffer_pos;
    const char *buffer_end;
    void *extra;
} TokenizerState;

typedef struct {
    int initial_state;
    bool allow_cdata;
    TokenHandler on_token;
    TokenizerString last_start_tag_name;
    char *buffer;
    size_t buffer_size;
    void *extra;
} TokenizerOpts;

__attribute__((nonnull)) void html_tokenizer_init(TokenizerState *state, const TokenizerOpts *options);
__attribute__((nonnull(1))) int html_tokenizer_feed(TokenizerState *state, const TokenizerString *chunk);
__attribute__((const, nonnull, warn_unused_result)) bool html_name_equals(const TokenizerString actual, const char *expected);

#endif
