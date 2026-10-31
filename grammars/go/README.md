# Go

| | |
|---|---|
| Grammar | https://github.com/tree-sitter/tree-sitter-go |
| Revision | `v0.25.0` |
| Built with | tree-sitter CLI 0.25 (prebuilt release asset) |
| Profile version | 2.0.0 |

## Verified against

```bash
curl -fsSL -o go.wasm \
  https://github.com/tree-sitter/tree-sitter-go/releases/download/v0.25.0/tree-sitter-go.wasm
codemark languages install go
```

SHA-256 `9504573f352b20be7f2f1911754d710622aedc15afff16d5ed8fb5645681aee7`
(217,182 bytes).

A `.wasm` you build yourself will differ byte-for-byte (emscripten output isn't
reproducible) but should verify identically — node kinds come from the grammar
revision, not the build.

## This entry overrides a built-in

Codemark bundles a Go grammar, so this entry **replaces** it. That needs
`--override-builtin` on a manual `add`; the index marks it with
`"overrides_builtin": true` so the verification harness passes the flag.

`go` is a reserved name, which is why
[CONTRIBUTING.md](../../CONTRIBUTING.md) lists Go among the names a *new*
grammar may not take. An override entry is the exception, and it is the same
path `c_sharp`, `python`, `swift` and `typescript` already take.

## Notes

**`type_declaration` wraps `type_spec`, and both are landmarks.** `type S
struct {` parses as a `type_declaration` containing a `type_spec`, and both
carry the `type` label. They start on the *same line*, so a naive breadcrumb
walk emits the header twice and spends two slots on one level of nesting;
codemark collapses the duplicate, and the committed snapshot for line 47 pins
that behaviour — it is a single `type LineItem struct {` entry. Both kinds are
kept because `type_declaration` alone cannot anchor an individual spec inside a
grouped `type ( A int; B int )` block.

**`type_spec` and `func_literal` can never be proposed.** The generator
promotes a kind only when it observes a body or a name the kind owns.
`type_spec`'s name lives in a child, and a Go closure never wraps a
declaration, so no sample can make the generator suggest either one — they are
declared in `curation.add_landmarks`. `func_literal` is worth anchoring: a
closure passed to `errgroup.Go` or a deferred cleanup is exactly the code you
want to return to. Like Python's `lambda` it has no `name` field, so it sticks
while scrolling and the breadcrumb renderer skips it; it is deliberately not a
container.

**The struct body is three layers of wrapper.** A field is reached through
`struct_type` → `field_declaration_list` → `field_declaration`. All three were
proposed as landmarks and all three are dropped: they play the role C#'s
`declaration_list` and Python's `block` do, and `struct_type` is additionally
mislabelled `class`, which Go has no concept of. Fields are anchored through
the type that declares them.

**`parameter_declaration` was the biggest false positive.** It matched 16 times
on a `type` field rather than a name — the generator accepts `type` as
name-bearing, so every parameter looked like a named declaration. Left in, an
argument would be the nearest anchor for half the file. `composite_literal`
matched the same way on `LineItem{...}`.

**`method_elem` is an interface method spec**, not a definition with a body. It
carries a name field so it was promoted, but it can never contain anything.

`go_statement` and `defer_statement` are labelled `call` rather than `go` and
`defer`: both wrap a call expression, and `codemark languages validate` warns
that a label outside the built-in set renders without an icon.

The only extension is `go`. Go has no stub or secondary file type the way
Python has `.pyi`, and `go.mod` is a different grammar entirely.
