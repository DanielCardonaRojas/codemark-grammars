# PHP

| | |
|---|---|
| Grammar | https://github.com/tree-sitter/tree-sitter-php |
| Revision | `v0.25.1` |
| Built with | tree-sitter CLI 0.25 (prebuilt release asset) |
| Profile version | 1.0.0 |

## Verified against

```bash
curl -fsSL -o php.wasm \
  https://github.com/tree-sitter/tree-sitter-php/releases/download/v0.25.1/tree-sitter-php.wasm
codemark languages add ./php.wasm --from-registry php
```

## Notes

`namespace App\Billing;` — the semicolon form — does **not** enclose the rest of
the file in the AST, so it never appears in a breadcrumb. The braced form
(`namespace X { ... }`) does. `namespace_definition` is kept as a container for
that reason, even though this sample can't exercise it.

`declaration_list` (the `{ }` body of a class) was dropped from the generated
landmarks: it's a structural wrapper, not a declaration.

`method_declaration`, `function_definition` and `namespace_definition` were
added to `containers` by hand — the generator only proposes a container for a
kind it *observes* wrapping another declaration, and in this sample the methods
hold only control flow.
