# LazyHTML (lhtml)

LazyHTML is an HTML5-compliant parser and serializer than enables building transformation pipeline in a pluggable manner.

## Testing

```
make test
```

## Benchmark

```
make bench
```

## How do we use it?

First of all, you need to create a buffer of a desired size:

```c
char buffer[1048576];
```

Then, you want to create a parsing state and initialize it with desired options:

```c
lhtml_options_t options = {
  .initial_state = LHTML_STATE_DATA,
  .allow_cdata = false,
  .last_start_tag_name = { .length = 0 },
  .buffer = buffer,
  .buffer_size = sizeof(buffer)
};

lhtml_state_t state;

lhtml_init(state, options);
```

At this point, you can inject own handler(s) for transformation:

```
lhtml_token_handler_t handler;
lhtml_add_handler(&state, &handler, handle_token);
```

Finally, feed it chunk by chunk:

```c
lhtml_string_t chunk = { .data = "...", .length = 3 };
lhtml_feed(&state, &chunk);
```

And finalize by sending NULL chunk (noting that no further data will be available):

```c
lhtml_feed(&state, NULL);
```

## Nice, but what do we put into the custom handlers / plugins?

Each plugin can have own state. To simplify the API, we take advantage of the fact that in C, structure always points to its first element, so if your transformation needs its own state, the convention is to put lhtml_token_handler_t handler; as the first item of your structure, and dereference the extra pointer in a callback to your state. If transformation doesn't need its own state, lhtml_token_handler_t can be used directly as shown below. This item is needed so that lhtml could chain various handlers into a single pipeline (if you're familiar with Nginx module system, this should look familiar to you, although with some modifications).

So, for example, function that only transforms href propertly on links, can look like following:

```c
// define static string to be used for replacements
static const lhtml_string_t REPLACEMENT = {
  .data = "[REPLACED]",
  .length = sizeof("[REPLACED]") - 1
};

static void token_handler(lhtml_token_t *token, void *extra /* this can be your state */) {
  if (token->type == LHTML_TOKEN_START_TAG) { // we're interested only in start tags
    const lhtml_token_starttag_t *tag = &token->start_tag;
    if (tag->type == LHTML_TAG_A) { // check whether tag is of type <a>
      const size_t n_attrs = tag->attributes.count;
      const lhtml_attribute_t *attrs = tag->attributes.items;
      for (size_t i = 0; i < n_attrs; i++) { // iterate over attributes
        const lhtml_attribute_t *attr = &attrs[i];
        if (lhtml_name_equals(attr->name, "href")) { // match the attribute name
          attr->value = REPLACEMENT; // set the attribute value
        }
      }
    }
  }
  lhtml_emit(token, extra); // pass transformed token(s) to next handler(s)
}
```

In your main code, use this handler:

```c
lhtml_token_handler_t handler;
lhtml_add_handler(&state, &handler, token_handler);
```

That's it!

## What does it do?

lhtml is a lexer which is also written in Ragel, but in a more modular fashion and with support for HTML5.

* Various parts of the HTML syntax spec live in separate Ragel files (syntax/comment.rl, syntax.starttag.rl, ...) and are connected in syntax/index.rl

![files](https://github.com/cloudflare/lazyhtml/blob/60b7026da4c0df92284e03212988beac7c973b6e/images/syntax-files.png)

* Syntax descriptions are separated from actions.

![descriptions](https://github.com/cloudflare/lazyhtml/blob/60b7026da4c0df92284e03212988beac7c973b6e/images/syntax-description.png)

One benefit that this brings is enforced named actions in such codestyle. This makes it easy to visualize, debug and fix specific machines using built-in Ragel's visualization.
Sample output from make AttributeName.png below:

![visualization](https://github.com/cloudflare/lazyhtml/blob/60b7026da4c0df92284e03212988beac7c973b6e/images/ragel-visualization.png)

This was proved/used during development, as the parser was prototyped in JavaScript for the sake of simplicity and then ported to C with only API / string handling changes within couple of days.

* lhtml operates on a byte level. HTML spec defines precise set of encodings that are allowed, and one interesting bit from the spec is:

> Since support for encodings that are not defined in the WHATWG Encoding standard is prohibited, [UTF-16 encodings](https://html.spec.whatwg.org/multipage/infrastructure.html#utf-16-encoding) are the only encodings that this specification needs to treat as not being [ASCII-compatible encodings](https://html.spec.whatwg.org/multipage/infrastructure.html#ascii-compatible-encoding).

That means that as long as we care only about ASCII-compatible subset (and we do for all the known tags and attributes potentially used in transformations) and the content is not in UTF-16, we can lex HTML on a byte level without expensive streaming decoding in front of it and encoding back after transformation. This is pretty much what we did in the previous parsers, so we can't transform UTF-16 at the moment, but should we decide that we want it in the future, it can be implemented as a special-cased transform in the front of the lexer (it's pretty rare on the Web though, so it's unlikely we will want it as potential issues overweight benefits).

* lhtml operates in a streaming fashion. When it gets a new chunk, it combines it with a previous leftover in the preallocated buffer and parses the newly formed string. The leftover is formed from the part of the previous token that was not finished.

* Character tokens (pure text) is not saved between buffers as they are the most popular content, and usually we don't care about them for transformation. That means only short tokens such as start tags, end tags, comments and doctype will be buffered.

* This leftover + chunk concatenation is the only place where copy occurs. This significantly simplifies handling of the strings across the code (as otherwise we would end up with a rope instead of flat in-memory chunk), and has low overhead (uses only one memmove on small leftover and one memcpy on the new chunk). Parsing itself is zero-copy, and returns tokens with {data, length} string structures which point to this buffer, making them lightweight on memory and easy to work with (and they're compatible with ngx_str_t out of the box).

* All the memory is statically allocated for entire context (document). On one hand, this means that if transformation wants to preserve some tokens, it needs to copy their data manually into own state, but on another hand brings significant performance wins as we don't need to allocate/free memory over and over for various buffers and tokens, and instead reuse same one. Also, this allows to avoid any restrictions on how that memory is allocated (whether it's malloc/free, Nginx pool or even a stack - anything works as long as it's live during the parsing).

* Tag names are hashed by transforming each letter to range of 1..26 with shifting step of 5 bits. This wouldn't cover custom tags, but gives a fast inlinable linear function that covers all the standard tags we care about, and for the other rare cases we can use lhtml_name_equals which compares the actual names in a case-insensitive manner.

* Each token & attribute, in addition to lexed strings, provides a string for the entire token / attribute which can be used if no modifications happened. This both allows to preserve formatting and bring even better performance by avoiding custom per-token serialization in favor of passing this raw strings as-is to the output on any tokens that we don't care about (don't modify).


## So is it correct and fast?

It's HTML5 compliant, was tested against the official test suites, and several contributions were sent to the specification itself for clarification / simplification of the spec language.

Unlike existing parsers, it didn't bail out on any of the 2,382,625 documents from HTTP Archive, although 0.2% of documents exceeded expected bufferization limits as they were in fact JavaScript or RSS or other types of content incorrectly served with Content-Type: text/html, and since anything is valid HTML5, parser tried to parse e.g. a<b; x=3; y=4 as incomplete tag with attributes. This is very rare (and goes to even lower amount of 0.03% when two error-prone advertisement networks are excluded from those results), but still needs to be accounted for and is a valid case for bailing out.

As for the benchmarks, I used an example which transforms HTML spec itself (7.9 MB HTML file) by replacing every `<a href>` (only that property only in those tags) to a static value. It was compared against few existing and popular HTML parser (only tokenization mode was used for the fair comparison, so that they don't need to build AST and so on), and timings in milliseconds for 100 iterations are the following (lazy mode means that we're using raw strings whenever possible, the other one serializes each token just for the comparison):

Parser | Example #1: 3.6 MB	| Example #2: 7.9 MB | Speed #1 (MB/s) | Speed #2 (MB/s)
--- | --- | --- | --- | ---
Gumbo (Google) |	265.05 |	542.93 |	13.62 |	14.62
html5ever (Mozilla) |	289.75 |	444.32 |	12.46 |	17.87
libhubbbub (Netsurf) | 113.57 |	232.33 |	31.80	| 34.17
lhtml (CloudFlare) |45.32 |	71.55 |	79.69 |	110.97
lhtml (lazy mode) (CloudFlare) |	26.40 |	49.57 |	136.78 |	160.18

![comparison](https://github.com/cloudflare/lazyhtml/blob/60b7026da4c0df92284e03212988beac7c973b6e/images/perf-comparison.png)

## Are there any quirks?

these parts were carefully extracted from the spec in the way that doesn't break compatibility, but instead allows to move out unnecessary yet expensive operations into a separate optional module in the pipeline.

More specifically, as per specification, you have various text transformations in different contexts, such as:

* normalizing CR / CRLF to LF
* named / numeric XML-like entities
* replacing U+0000 (NUL) character with U+FFFD (replacement character) in certain contexts where it's considered unsafe
* normalizing uppercase tag names and attributes to lowercase in non-XML contexts

Those are important for correct display in browsers, but as we don't render content, perform very limited text processing, and care only about standard (ASCII-subset) tag names and attributes, we can get away with ignoring those and implementing in a separate plugin if needed. This doesn't change correctness as long as you do e.g. case-insensitive comparisons (which we already do in a very cheap way - case-insensitive hashing).

Otherwise, we would need to apply charset detection and text decoding (as entity matches or U+FFFD have different representations in various encodings) in front of the parser which would make it significantly slower for little to no benefits.

## License

BSD licensed. See the [LICENSE](LICENSE) file for details.