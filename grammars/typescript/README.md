# TypeScript

| | |
|---|---|
| Grammar | https://github.com/tree-sitter/tree-sitter-typescript |
| Revision | `v0.23.2` |
| Built with | tree-sitter CLI 0.23 (prebuilt release asset) |
| Profile version | 1.0.0 |

## Verified against

```bash
codemark languages install typescript
```

## This entry overrides a built-in

Codemark bundles a TypeScript grammar, so this entry **replaces** it — 2.75 MB
of a 24.2 MB binary. The index marks it `"overrides_builtin": true`.

## Notes

**That release ships two wasm assets**, and the first one alphabetically is
`tree-sitter-tsx.wasm`, which exports `tree_sitter_tsx` — a different grammar.
The entry pins `tree-sitter-typescript.wasm` explicitly. Same trap as
`tree-sitter-php_only.wasm`.

This entry claims only `.ts`. The built-in also claims `.tsx`, which this
grammar cannot parse — see codemark#244 for the resulting name/extension
resolution gap.

**Namespaces are not exercised.** A bookmark inside a `namespace` makes the
query generator emit a pattern matching 0 nodes, so it can't be created at all
(codemark#246). `internal_module` stays in `containers` because it is the right
kind once that is fixed; the sample simply can't cover it today.

`class_body`, `property_signature` and `public_field_definition` were dropped
from the generated landmarks; `method_definition` and `function_declaration`
were added to `containers`.
