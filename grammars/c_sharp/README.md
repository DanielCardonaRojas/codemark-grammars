# C#

| | |
|---|---|
| Grammar | https://github.com/tree-sitter/tree-sitter-c-sharp |
| Revision | `v0.23.1` |
| Built with | tree-sitter CLI 0.23 (prebuilt release asset) |
| Profile version | 1.0.0 |

## Verified against

```bash
curl -fsSL -o c_sharp.wasm \
  https://github.com/tree-sitter/tree-sitter-c-sharp/releases/download/v0.23.1/tree-sitter-c_sharp.wasm
codemark languages install c_sharp
```

## This entry overrides a built-in

Codemark bundles a C# grammar, so this entry **replaces** it. That needs
`--override-builtin` on a manual `add`; the index marks it with
`"overrides_builtin": true` so the verification harness passes the flag.

C# is the largest bundled grammar — 5.67 MB of a 24.2 MB binary, 38% of all
grammar weight — which is why it is the first built-in moved to the registry.

## Notes

The registry name is **`c_sharp`**, not `csharp`. A Tree-sitter module exports
`tree_sitter_<name>` and this one exports `tree_sitter_c_sharp`, so the install
name has to match the export exactly or loading fails.

Dropped from the generated landmarks: `declaration_list` (the `{ }` body
wrapper), `foreach_statement` (control flow that matched on a `type` field), and
`variable_declaration` (same — `type` is not a name).

`constructor_declaration` was added to `containers` by hand. The generator only
proposes a container for a kind it *observes* wrapping another declaration, and
in this sample the constructor holds only an assignment.

The sample avoids a symmetric `if`/`else`: two structurally identical sibling
branches make the generated query match both, and codemark refuses an ambiguous
bookmark. That is a sample-authoring constraint, not a profile defect.
