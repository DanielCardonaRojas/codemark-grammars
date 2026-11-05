# TypeScript

| | |
|---|---|
| Grammar | https://github.com/tree-sitter/tree-sitter-typescript |
| Revision | `v0.23.2` |
| Built with | tree-sitter CLI 0.23 (prebuilt release asset) |
| Profile version | 2.1.0 |

## Verified against

```bash
codemark languages install typescript
```

## Built into codemark before 0.8.0

Codemark compiled a TypeScript grammar in until 0.8.0, which moved it to this
registry (codemark#278); since then Dart is the only built-in grammar.
On codemark 0.8.0 and later this is an ordinary registry entry. On an older
codemark it **replaces** the built-in instead, which needs
`--override-builtin` on a manual `add`; the index marks it with
`"overrides_builtin": true` so `languages install` and the verification
harness pass the flag.

It was 2.75 MB of a 24.2 MB binary.

## Notes

**That release ships two wasm assets**, and the first one alphabetically is
`tree-sitter-tsx.wasm`, which exports `tree_sitter_tsx` — a different grammar.
The entry pins `tree-sitter-typescript.wasm` explicitly. Same trap as
`tree-sitter-php_only.wasm`.

This entry claims only `.ts`; `.tsx` is the separate [`tsx`](../tsx/README.md)
entry, built from the same repository's `tsx/` grammar. The pre-0.8.0 built-in
claimed both — see codemark#244 for the name/extension resolution gap that
caused while the two were split between built-in and registry.

**Namespaces are not exercised.** A bookmark inside a `namespace` makes the
query generator emit a pattern matching 0 nodes, so it can't be created at all
(codemark#246). `internal_module` is labelled `namespace` (as in the built-in)
and `namespace` stays in `containers` because it is the right container once
that is fixed; the sample simply can't cover it today.

`class_body`, `property_signature` and `public_field_definition` were dropped
from the generated landmarks.

**Parity with the pre-0.8.0 built-in.** `export_statement` is a curated
landmark: it wraps `export const handler = () => …`, and the generator never
proposes it. With an exported arrow function in the sample, the generator itself
proposes `lexical_declaration` and `arrow_function` (labelled `function`, so the
arrow function's line shows in the trail) and labels `for_statement`,
`while_statement` and `assignment_expression`. `lexical_declaration` and
`variable_declaration` are curated to `variable`. `type` is a container, and the
sample bookmarks a line inside a multi-line `type Totals = { … }`.
