# Swift

| | |
|---|---|
| Grammar | https://github.com/alex-pinkus/tree-sitter-swift |
| Revision | `0.7.3` |
| Built with | tree-sitter CLI 0.25 (prebuilt release asset) |
| Profile version | 1.0.0 |

## Verified against

```bash
codemark languages install swift
```

## This entry overrides a built-in

Codemark bundles a Swift grammar, so this entry **replaces** it — 3.24 MB of a
24.2 MB binary, the second largest of the eight. The index marks it
`"overrides_builtin": true`.

## Notes

`class_body` and `enum_class_body` were dropped from the generated landmarks:
both are `{ }` wrappers, not declarations.

`function_declaration` and `init_declaration` were added to `containers` by
hand — the generator only proposes a container for a kind it *observes* wrapping
another declaration, and in this sample those hold only statements.

The sample covers an `extension`, which is a container Swift uses heavily and
which sits outside the class body: a bookmark there resolves to
`extension Invoice: Payable > func pay(...)`.
