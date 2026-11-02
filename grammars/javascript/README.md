# JavaScript

| | |
|---|---|
| Grammar | https://github.com/tree-sitter/tree-sitter-javascript |
| Revision | `v0.25.0` |
| Built with | tree-sitter CLI 0.25 (prebuilt release asset) |
| Profile version | 2.0.0 |

## Verified against

```bash
curl -fsSL -o javascript.wasm \
  https://github.com/tree-sitter/tree-sitter-javascript/releases/download/v0.25.0/tree-sitter-javascript.wasm
codemark languages install javascript
```

SHA-256 `5fb488d0cabb4775a594bab85682de5ad6ce83c0d6ac997a9f82dd084d571240`
(411,770 bytes).

A `.wasm` you build yourself will differ byte-for-byte (emscripten output isn't
reproducible) but should verify identically — node kinds come from the grammar
revision, not the build.

## Not an override

Unlike `java`, `go`, `python` and `rust`, JavaScript is **not** a codemark
built-in, so this is an ordinary entry — no `--override-builtin`, no
`overrides_builtin` in the index.

The extensions don't collide either: codemark's TypeScript built-in claims only
`ts` and `tsx`, leaving `js`, `jsx`, `mjs` and `cjs` free. This profile takes
all four. JSX parses with this grammar (tree-sitter-javascript includes JSX),
which is why `jsx` is included rather than split out.

## Notes

**`lexical_declaration` was the main false positive.** At 7 occurrences it was
the most frequent proposal. It looked like a container because
`const apply = (amount) => {...}` genuinely nests an arrow function below it —
but it names nothing itself: the `variable_declarator` holds the name one level
down, and the `arrow_function` is the real body. Anchoring on it would add a
level to every trail passing through a `const` binding. Dropped as a landmark,
kept as a `variable` label.

**`arrow_function` is proposed, which is a useful contrast.** Python's `lambda`
and Rust's `closure_expression` can *never* be proposed — the generator only
promotes a kind it observes with a body or a name it owns, and those never wrap
a declaration. An arrow function **has** a body, so the generator proposes it
straight from the samples. Only `function_expression` needed declaring in
`curation.add_landmarks`, and that is because modern JavaScript prefers arrow
functions, so the sample contains no `function () {}` used as a value. Adding
one purely to satisfy the generator would be sample padding.

Both forms are labelled `function` and have no `name` field, so like a Zig
`struct_declaration` they anchor a query and stick while scrolling, and the
breadcrumb renderer skips them.

**There is no `for_of_statement` node kind.** This grammar parses
`for (const x of xs)` as a `for_in_statement`. Writing the name that reads
naturally is a hard lint error — `node kind 'for_of_statement' is not defined by
this grammar, so it can never match (did you mean 'for_in_statement'?)` — which
is how it was caught. Unlike Java, this grammar *does* have a real
`switch_statement`, so no workaround is needed there.

**`method_definition` covers more than class methods.** An object-literal
method (`const helpers = { sum(lines) {...} }`) is also a `method_definition`,
so it anchors and nests the same way. The snapshot for line 145 pins that.

`generator_function_declaration` is a distinct kind from `function_declaration`
and is labelled `function` too, so `function*` reads the same in a summary.

`field_definition` (a class field) is labelled `variable` but deliberately not
a landmark — a field is reached through the class that declares it.
