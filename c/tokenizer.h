#ifndef LHTML_TOKENIZER_H
#define LHTML_TOKENIZER_H

#include <stddef.h>
#include <stdbool.h>

extern const int LHTML_STATE_ERROR;
extern const int LHTML_STATE_DATA;
extern const int LHTML_STATE_RCDATA;
extern const int LHTML_STATE_RAWTEXT;
extern const int LHTML_STATE_PLAINTEXT;
extern const int LHTML_STATE_SCRIPTDATA;

typedef struct {
    size_t length;
    const char *data;
} lhtml_string_t;

typedef struct {
    bool has_value;
    lhtml_string_t value;
} lhtml_opt_string_t;

typedef enum {
    LHTML_TOKEN_UNKNOWN,
    LHTML_TOKEN_CHARACTER,
    LHTML_TOKEN_COMMENT,
    LHTML_TOKEN_START_TAG,
    LHTML_TOKEN_END_TAG,
    LHTML_TOKEN_DOCTYPE,
    LHTML_TOKEN_EOF
} lhtml_token_type_t;

typedef enum {
    LHTML_TOKEN_CHARACTER_RAW,
    LHTML_TOKEN_CHARACTER_DATA,
    LHTML_TOKEN_CHARACTER_RCDATA,
    LHTML_TOKEN_CHARACTER_CDATA,
    LHTML_TOKEN_CHARACTER_SAFE
} lhtml_token_character_kind_t;

typedef struct {
    lhtml_token_character_kind_t kind;
    lhtml_string_t value;
} lhtml_token_character_t;

typedef struct {
    lhtml_string_t value;
} lhtml_token_comment_t;

typedef struct {
    lhtml_string_t name;
    lhtml_string_t value;
} lhtml_attribute_t;

#define MAX_ATTR_COUNT 256

typedef struct {
    size_t count;
    lhtml_attribute_t items[MAX_ATTR_COUNT];
} lhtml_attributes_t;

typedef enum {
    // Regular elements
    LHTML_TAG_A = 1,
    LHTML_TAG_ABBR = 34898,
    LHTML_TAG_ADDRESS = 1212749427,
    LHTML_TAG_AREA = 51361,
    LHTML_TAG_ARTICLE = 1698991493,
    LHTML_TAG_ASIDE = 1680517,
    LHTML_TAG_AUDIO = 1741103,
    LHTML_TAG_B = 2,
    LHTML_TAG_BASE = 67173,
    LHTML_TAG_BDI = 2185,
    LHTML_TAG_BDO = 2191,
    LHTML_TAG_BLOCKQUOTE = 84081888640645,
    LHTML_TAG_BODY = 81049,
    LHTML_TAG_BR = 82,
    LHTML_TAG_BUTTON = 89805294,
    LHTML_TAG_CANVAS = 102193203,
    LHTML_TAG_CAPTION = 3272222190,
    LHTML_TAG_CITE = 108165,
    LHTML_TAG_CODE = 113797,
    LHTML_TAG_COL = 3564,
    LHTML_TAG_COLGROUP = 119595941552,
    LHTML_TAG_DATA = 132737,
    LHTML_TAG_DATALIST = 139185235572,
    LHTML_TAG_DD = 132,
    LHTML_TAG_DEL = 4268,
    LHTML_TAG_DETAILS = 4483753363,
    LHTML_TAG_DFN = 4302,
    LHTML_TAG_DIALOG = 143700455,
    LHTML_TAG_DIV = 4406,
    LHTML_TAG_DL = 140,
    LHTML_TAG_DT = 148,
    LHTML_TAG_EM = 173,
    LHTML_TAG_EMBED = 5671076,
    LHTML_TAG_FIELDSET = 216002612404,
    LHTML_TAG_FIGCAPTION = 221245627573742,
    LHTML_TAG_FIGURE = 211015237,
    LHTML_TAG_FOOTER = 217567410,
    LHTML_TAG_FORM = 212557,
    LHTML_TAG_HEAD = 267300,
    LHTML_TAG_HEADER = 273715378,
    LHTML_TAG_HGROUP = 276381360,
    LHTML_TAG_HR = 274,
    LHTML_TAG_HTML = 283052,
    LHTML_TAG_I = 9,
    LHTML_TAG_IFRAME = 308872613,
    LHTML_TAG_IMG = 9639,
    LHTML_TAG_INPUT = 9913012,
    LHTML_TAG_INS = 9683,
    LHTML_TAG_KBD = 11332,
    LHTML_TAG_KEYGEN = 375168174,
    LHTML_TAG_LABEL = 12617900,
    LHTML_TAG_LEGEND = 408131012,
    LHTML_TAG_LI = 393,
    LHTML_TAG_LINK = 402891,
    LHTML_TAG_MAIN = 427310,
    LHTML_TAG_MAP = 13360,
    LHTML_TAG_MARK = 427595,
    LHTML_TAG_MATH = 427656,
    LHTML_TAG_MENU = 431573,
    LHTML_TAG_MENUITEM = 452537405613,
    LHTML_TAG_META = 431745,
    LHTML_TAG_METER = 13815986,
    LHTML_TAG_NAV = 14390,
    LHTML_TAG_NOSCRIPT = 497783744020,
    LHTML_TAG_OBJECT = 505746548,
    LHTML_TAG_OL = 492,
    LHTML_TAG_OPTGROUP = 533254979248,
    LHTML_TAG_OPTION = 520758766,
    LHTML_TAG_OUTPUT = 526009012,
    LHTML_TAG_P = 16,
    LHTML_TAG_PARAM = 16828461,
    LHTML_TAG_PICTURE = 17485682245,
    LHTML_TAG_PRE = 16965,
    LHTML_TAG_PROGRESS = 569594418803,
    LHTML_TAG_Q = 17,
    LHTML_TAG_RP = 592,
    LHTML_TAG_RT = 596,
    LHTML_TAG_RUBY = 611417,
    LHTML_TAG_S = 19,
    LHTML_TAG_SAMP = 624048,
    LHTML_TAG_SCRIPT = 641279508,
    LHTML_TAG_SECTION = 20572677614,
    LHTML_TAG_SELECT = 643175540,
    LHTML_TAG_SLOT = 635380,
    LHTML_TAG_SMALL = 20350348,
    LHTML_TAG_SOURCE = 653969509,
    LHTML_TAG_SPAN = 639022,
    LHTML_TAG_STRONG = 659111367,
    LHTML_TAG_STYLE = 20604293,
    LHTML_TAG_SUB = 20130,
    LHTML_TAG_SUMMARY = 21119796825,
    LHTML_TAG_SUP = 20144,
    LHTML_TAG_SVG = 20167,
    LHTML_TAG_TABLE = 21006725,
    LHTML_TAG_TBODY = 21052569,
    LHTML_TAG_TD = 644,
    LHTML_TAG_TEMPLATE = 693016856197,
    LHTML_TAG_TEXTAREA = 693389805729,
    LHTML_TAG_TFOOT = 21183988,
    LHTML_TAG_TH = 648,
    LHTML_TAG_THEAD = 21238820,
    LHTML_TAG_TIME = 664997,
    LHTML_TAG_TITLE = 21287301,
    LHTML_TAG_TR = 658,
    LHTML_TAG_TRACK = 21562475,
    LHTML_TAG_U = 21,
    LHTML_TAG_UL = 684,
    LHTML_TAG_VAR = 22578,
    LHTML_TAG_VIDEO = 23367855,
    LHTML_TAG_WBR = 23634,

    // Obsolete elements
    LHTML_TAG_APPLET = 50868404,
    LHTML_TAG_ACRONYM = 1193786157,
    LHTML_TAG_BGSOUND = 2402801092,
    LHTML_TAG_DIR = 4402,
    LHTML_TAG_FRAME = 6882725,
    LHTML_TAG_FRAMESET = 225533152436,
    LHTML_TAG_NOFRAMES = 497362711731,
    LHTML_TAG_ISINDEX = 10311110840,
    LHTML_TAG_LISTING = 13207479751,
    LHTML_TAG_NEXTID = 475812132,
    LHTML_TAG_NOEMBED = 15541373092,
    LHTML_TAG_PLAINTEXT = 18005893977876,
    LHTML_TAG_RB = 578,
    LHTML_TAG_RTC = 19075,
    LHTML_TAG_STRIKE = 659105125,
    LHTML_TAG_XMP = 25008,
    LHTML_TAG_BASEFONT = 70436208084,
    LHTML_TAG_BIG = 2343,
    LHTML_TAG_BLINK = 2500043,
    LHTML_TAG_CENTER = 106385586,
    LHTML_TAG_FONT = 212436,
    LHTML_TAG_MARQUEE = 14011651237,
    LHTML_TAG_MULTICOL = 469649100268,
    LHTML_TAG_NOBR = 474194,
    LHTML_TAG_SPACER = 654347442,
    LHTML_TAG_TT = 660,
    LHTML_TAG_IMAGE = 9864421,

    // MathML text integration points
    LHTML_TAG_MI = 425,
    LHTML_TAG_MO = 431,
    LHTML_TAG_MN = 430,
    LHTML_TAG_MS = 435,
    LHTML_TAG_MTEXT = 14292756,

    // SVG HTML integration points
    LHTML_TAG_DESC = 136803,
    // LHTML_TAG_TITLE // already exists,
    // LHTML_TAG_FOREIGNOBJECT // too long,
} lhtml_tag_type_t;

typedef struct {
    lhtml_string_t name;
    lhtml_tag_type_t type;
    lhtml_attributes_t attributes;
    bool self_closing;
} lhtml_token_starttag_t;

typedef struct {
    lhtml_string_t name;
    lhtml_tag_type_t type;
} lhtml_token_endtag_t;

typedef struct {
    lhtml_opt_string_t name;
    lhtml_opt_string_t public_id;
    lhtml_opt_string_t system_id;
    bool force_quirks;
} lhtml_token_doctype_t;

typedef struct {
    lhtml_token_type_t type;
    union {
        lhtml_token_character_t character;
        lhtml_token_comment_t comment;
        lhtml_token_starttag_t start_tag;
        lhtml_token_endtag_t end_tag;
        lhtml_token_doctype_t doctype;
    };
    lhtml_string_t raw;
} lhtml_token_t;

typedef struct lhtml_token_handler lhtml_token_handler_t;

typedef __attribute__((nonnull(1))) void (*lhtml_token_callback_t)(lhtml_token_t *token, void *extra);

struct lhtml_token_handler {
    lhtml_token_callback_t callback;
    lhtml_token_handler_t *next;
};

typedef struct {
    lhtml_token_handler_t base_handler; // needs to be the first one

    int cs;
    lhtml_token_handler_t *handler;
    char quote;
    bool allow_cdata;
    char last_start_tag_name_buf[20]; // all the tags that might need this, fit
    const char *last_start_tag_name_end;
    lhtml_token_t token;
    lhtml_attribute_t *attribute;
    const char *start_slice;
    const char *mark;
    const char *appropriate_end_tag_offset;
    char *buffer;
    char *buffer_pos;
    const char *buffer_end;
} lhtml_state_t;

typedef struct {
    int initial_state;
    bool allow_cdata;
    lhtml_string_t last_start_tag_name;
    char *buffer;
    size_t buffer_size;
    lhtml_token_callback_t on_token;
} lhtml_options_t;

__attribute__((nonnull))
void lhtml_init(lhtml_state_t *state, const lhtml_options_t *options);

__attribute__((nonnull))
void lhtml_add_handler(lhtml_state_t *state, lhtml_token_handler_t *handler, lhtml_token_callback_t callback);

__attribute__((nonnull, always_inline))
void lhtml_emit(lhtml_token_t *token, void *extra);

__attribute__((nonnull(1)))
int lhtml_feed(lhtml_state_t *state, const lhtml_string_t *chunk);

__attribute__((const, nonnull, warn_unused_result))
bool lhtml_name_equals(const lhtml_string_t actual, const char *expected);

#endif
