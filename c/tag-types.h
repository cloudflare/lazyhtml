typedef enum {
    // Custom elements
    LHTML_TAG_UNKNOWN = 0,

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
    LHTML_TAG_FOREIGNOBJECT = 7478413254770103412,
} lhtml_tag_type_t;
