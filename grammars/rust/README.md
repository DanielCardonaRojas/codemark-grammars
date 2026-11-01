# Rust

| | |
|---|---|
| Grammar | https://github.com/tree-sitter/tree-sitter-rust |
| Revision | `v0.24.2` |
| Built with | tree-sitter CLI 0.25 (prebuilt release asset) |
| Profile version | 2.0.0 |

## Verified against

```bash
curl -fsSL -o rust.wasm \
  https://github.com/tree-sitter/tree-sitter-rust/releases/download/v0.24.2/tree-sitter-rust.wasm
codemark languages install rust
```

SHA-256 `24c89bd9252255e4aebbcbd7d2d308bd92c86dd95a130fdc80efa49577b8d738`
(1,118,099 bytes).

A `.wasm` you build yourself will differ byte-for-byte (emscripten output isn't
reproducible) but should verify identically — node kinds come from the grammar
revision, not the build.

## This entry overrides a built-in

Codemark bundles a Rust grammar, so this entry **replaces** it. That needs
`--override-builtin` on a manual `add`; the index marks it with
`"overrides_builtin": true` so the verification harness passes the flag.

Both `rust` and its alias `rs` are reserved names, which is why
[CONTRIBUTING.md](../../CONTRIBUTING.md) lists Rust among the names a *new*
grammar may not take. An override entry is the exception, and it is the same
path `c_sharp`, `go`, `python`, `swift` and `typescript` already take.

## Notes

**This profile adds containers the built-in lacks.** The built-in Rust profile
marks only `function`, `impl`, `interface` and `module` as containers, so a
method in an inherent impl shows the impl but a **struct or enum body never
appears in a breadcrumb trail at all**. This profile adds `class` (for
`struct_item`), `enum` and `type`, which is the main practical difference
between the two. Nothing the built-in anchors on is lost — the landmark set here
is a strict superset.

**Patterns and literals are not declarations.** `struct_expression` (3
occurrences), `struct_pattern` and `tuple_struct_pattern` (3) were all proposed
as landmarks because the generator reads their `name`/`type` field as a
declaration name. But these are *use* sites: `Self { amount, .. }` and
`State::Paid(total)` in a match arm. Each was also labelled `class`, so leaving
them in would put a destructuring pattern in a trail as though it were a type
declaration. `struct_item` is the only real struct declaration.

**`declaration_list` is the body wrapper**, and at 9 occurrences it was the
most frequent kind in the evidence table. It is the `{ }` of an impl, trait or
module — the role C#'s `declaration_list` and Python's `block` play — so
anchoring on it adds a level that names nothing. The `impl_item` or `trait_item`
that owns it is the real landmark. The three struct-body wrappers
(`field_declaration`, `field_declaration_list`,
`ordered_field_declaration_list`) are dropped for the same reason.

**`function_signature_item` is a trait method signature** with no body
(`fn total(&self) -> Money;`), so it can never contain anything. The defaulted
method beside it in the sample is a real `function_item` and remains a landmark.

**`closure_expression` can never be proposed.** The generator promotes a kind
only when it observes a body or a name the kind owns, and a Rust closure never
wraps a declaration — so no sample can make it appear, and it is declared in
`curation.add_landmarks`. It is worth anchoring: a closure passed to `map` or
`and_then` is exactly the code you want to return to. Like Python's `lambda` it
has no `name` field, so it sticks while scrolling and the breadcrumb renderer
skips it; it is deliberately not a container.

**`macro_definition` is a landmark but not a container.** Codemark parses a
macro body as a `token_tree`, not as Rust, so nothing inside `macro_rules!` can
be bookmarked. You can anchor on the macro itself.

Rust spells its loops as expressions (`for_expression`, `while_expression`,
`loop_expression`), and the sample only exercises `for`, so the other two are
labelled through `curation.add_labels`.

The only extension is `rs`. Rust has no secondary source extension the way
Python has `.pyi`; `Cargo.toml` is TOML and `build.rs` is ordinary Rust.
