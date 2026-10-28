# Scala

| | |
|---|---|
| Grammar | https://github.com/tree-sitter/tree-sitter-scala |
| Revision | `v0.26.3` |
| Built with | tree-sitter CLI 0.26 (prebuilt release asset) |
| Profile version | 1.0.0 |

## Verified against

```bash
curl -fsSL -o scala.wasm \
  https://github.com/tree-sitter/tree-sitter-scala/releases/download/v0.26.3/tree-sitter-scala.wasm
codemark languages add ./scala.wasm --from-registry scala
```

Built with a CLI *newer* than codemark's 0.25 runtime, and it loads — the ABI it
emits is still ≤ 15. Tree-sitter is backwards-compatible, so this is fine until
a grammar emits ABI 16.

## Notes

`class_parameter`, `class_parameters` and `var_definition` were dropped from the
generated landmarks: the first two are constructor-parameter wrappers, and
`var_definition`'s only name-ish field is `type`.

The sample deliberately gives the two `if` branches **different shapes**
(`total = applyTax(...)` vs `total += ...`). Identical sibling statements make
the generated structural query match both, and codemark refuses an ambiguous
bookmark. That's a sample-authoring constraint, not a profile defect.
