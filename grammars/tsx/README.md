# TSX

| | |
|---|---|
| Grammar | https://github.com/tree-sitter/tree-sitter-typescript (`tsx/`) |
| Revision | `v0.23.2` |
| Built with | tree-sitter CLI 0.23 (prebuilt release asset) |
| Profile version | 1.0.0 |

## Verified against

```bash
codemark languages install tsx
```

Download: https://github.com/tree-sitter/tree-sitter-typescript/releases/download/v0.23.2/tree-sitter-tsx.wasm
SHA-256: `79e5da75ea62855a0cd67177685f0164eac87d5f630b3cbe1e0a099751ad30f8`

## Why a separate entry

tree-sitter-typescript publishes two grammars from one repository: `typescript/`
and `tsx/`. They are different parsers — the TypeScript grammar reads `<T>x`
as a type assertion and cannot parse JSX at all — so `.tsx` cannot share the
`typescript` entry. Before codemark 0.8.0 the built-in TypeScript grammar had a
TSX variant and claimed both extensions; once it was unbundled, `.tsx` needed an
entry of its own. `grammar_dir` is `tsx` so CI builds the right one.

## Built into codemark before 0.8.0

On codemark versions that still compile TypeScript in, `tsx` is an alias of
the built-in, so installing this entry needs `--override-builtin` and the index
marks it `"overrides_builtin": true` — the same as the other unbundled languages.
From 0.8.0 on it is an ordinary registry entry.

## Notes

The profile is the TypeScript profile plus JSX labels: `jsx_element` and
`jsx_self_closing_element` → `call`, `jsx_expression` → `expression`. JSX kinds
are deliberately not landmarks or containers — see `curation.why` in the
manifest. The sample mirrors grammars/typescript's constructs so the two
profiles can be compared, and `scripts/apply-curation.py` regenerates the same
TypeScript decisions from it.

**Namespaces are not exercised**, for the same reason as TypeScript
(codemark#246).
