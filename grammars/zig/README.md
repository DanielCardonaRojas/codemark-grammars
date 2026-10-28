# Zig

| | |
|---|---|
| Grammar | https://github.com/tree-sitter-grammars/tree-sitter-zig |
| Revision | `v1.1.2` |
| Built with | tree-sitter CLI 0.25 (prebuilt release asset) |
| Profile version | 1.0.0 |

## Verified against

```bash
curl -fsSL -o zig.wasm \
  https://github.com/tree-sitter-grammars/tree-sitter-zig/releases/download/v1.1.2/tree-sitter-zig.wasm
codemark languages add ./zig.wasm --from-registry zig
```

## Notes

Zig has no class or module construct, so breadcrumbs are a single function
level. That's the language, not a gap.

`struct_declaration` is a landmark but **not** a container: in Zig a struct is
an anonymous value bound by the enclosing `variable_declaration`, so it carries
no name field of its own. The generator proposed
`["variable_declaration", "type"]` — a real field, but the *type*, not a name —
and it was removed rather than shipped, since a breadcrumb reading `f64` helps
nobody.
