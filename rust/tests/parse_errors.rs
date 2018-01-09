use token::TokenRange;
use std::collections::HashSet;

pub const ERROR_CODES: &'static [&'static str] = &[
    "abrupt-closing-of-empty-comment",
    "abrupt-doctype-public-identifier",
    "abrupt-doctype-system-identifier",
    // "absence-of-digits-in-numeric-character-reference" (character references are not supported)
    "cdata-in-html-content",
    // "character-reference-outside-unicode-range" (character references are not supported)
    // "control-character-in-input-stream" (has significant performance impact)
    // "control-character-reference" (character references are not supported)
    "end-tag-with-attributes",
    "duplicate-attribute",
    "end-tag-with-trailing-solidus",
    "eof-before-tag-name",
    "eof-in-cdata",
    "eof-in-comment",
    "eof-in-doctype",
    "eof-in-script-html-comment-like-text",
    "eof-in-tag",
    "incorrectly-closed-comment",
    "incorrectly-opened-comment",
    "invalid-character-sequence-after-doctype-name",
    "invalid-first-character-of-tag-name",
    "missing-attribute-value",
    "missing-doctype-name",
    "missing-doctype-public-identifier",
    "missing-doctype-system-identifier",
    "missing-end-tag-name",
    "missing-quote-before-doctype-public-identifier",
    "missing-quote-before-doctype-system-identifier",
    "missing-whitespace-after-doctype-public-keyword",
    "missing-whitespace-after-doctype-system-keyword",
    "missing-whitespace-before-doctype-name",
    "missing-whitespace-between-attributes",
    "missing-whitespace-between-doctype-public-and-system-identifiers",
    "nested-comment",
    // "noncharacter-character-reference" (character references are not supported)
    // "noncharacter-in-input-stream" (requires UTF decoding, has significant performance impact)
    "non-void-html-element-start-tag-with-trailing-solidus",
    // "null-character-reference" (character references are not supported)
    // "surrogate-character-reference" (character references are not supported)
    // "surrogate-in-input-stream" (requires UTF decoding, has significant performance impact)
    "unexpected-character-after-doctype-system-identifier",
    "unexpected-character-in-attribute-name",
    "unexpected-character-in-unquoted-attribute-value",
    "unexpected-equals-sign-before-attribute-name",
    // "unexpected-null-character" (has significant performance impact)
    "unexpected-question-mark-instead-of-tag-name",
    "unexpected-solidus-in-tag",
    // "unknown-named-character-reference" (character references are not supported)
];

pub type ParseErrors = HashSet<(TokenRange, &'static str)>;
