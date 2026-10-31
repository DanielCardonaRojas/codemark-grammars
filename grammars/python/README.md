# Python

| | |
|---|---|
| Grammar | https://github.com/tree-sitter/tree-sitter-python |
| Revision | `v0.25.0` |
| Built with | tree-sitter CLI 0.25 (prebuilt release asset) |
| Profile version | 2.0.0 |

## Verified against

```bash
curl -fsSL -o python.wasm \
  https://github.com/tree-sitter/tree-sitter-python/releases/download/v0.25.0/tree-sitter-python.wasm
codemark languages install python
```

SHA-256 `16108b50df4ee9a30168794252ab55e7c93bfc5765d7fa0aa3e335752c515f47`
(457,883 bytes).

A `.wasm` you build yourself will differ byte-for-byte (emscripten output isn't
reproducible) but should verify identically — node kinds come from the grammar
revision, not the build.

## This entry overrides a built-in

Codemark bundles a Python grammar, so this entry **replaces** it. That needs
`--override-builtin` on a manual `add`; the index marks it with
`"overrides_builtin": true` so the verification harness passes the flag.

Both `python` and its alias `py` are reserved names, which is why
[CONTRIBUTING.md](../../CONTRIBUTING.md) lists Python among the names a *new*
grammar may not take. An override entry is the exception, and it is the same
path `c_sharp`, `swift` and `typescript` already take.

## Notes

**There is no `method` node kind.** A Python method is a `function_definition`
nested inside a `class_definition` — the grammar draws no distinction. So this
profile labels `function_definition` as `function` and has no `method` label at
all, unlike C# (`method_declaration`) or Ruby (`method`). One container entry,
`function`, covers plain functions, methods and nested closures.

**`decorated_definition` is a wrapper, not a landmark.** A decorated function
parses as `decorated_definition` → `decorator` + `function_definition`. It
carries a `definition` field, so it looks like a named body to the generator,
but promoting it doubles every decorated method in a breadcrumb trail. Dropped
in `curation`; the wrapped `function_definition` is the real anchor.

**`block` is the body wrapper.** Python's indented suite is a `block` node,
playing the role C#'s `declaration_list` does. It is dropped for the same
reason: it is a level that names nothing.

`lambda` is labelled `function` and kept as a landmark, but it has no `name`
field — like a Zig `struct_declaration`, it can anchor a query and stick while
scrolling, and the breadcrumb renderer skips it.

Extensions are `py`, `pyi` (stub files) and `pyw`. Stubs are worth including:
they are real Python the grammar parses, and a bookmark into a large `.pyi`
benefits from the same structure.
