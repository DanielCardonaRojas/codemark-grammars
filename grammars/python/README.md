# Python

| | |
|---|---|
| Grammar | https://github.com/tree-sitter/tree-sitter-python |
| Revision | `v0.25.0` |
| Built with | tree-sitter CLI 0.25 (prebuilt release asset) |
| Profile version | 2.1.0 |

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

## Built into codemark before 0.8.0

Codemark compiled a Python grammar in until 0.8.0, which moved it to this
registry (codemark#278); since then Dart is the only built-in grammar.
On codemark 0.8.0 and later this is an ordinary registry entry. On an older
codemark it **replaces** the built-in instead, which needs
`--override-builtin` on a manual `add`; the index marks it with
`"overrides_builtin": true` so `languages install` and the verification
harness pass the flag.

Both `python` and its alias `py` were a reserved name on codemark before 0.8.0, which is why
[CONTRIBUTING.md](../../CONTRIBUTING.md) lists Python among the names a *new*
grammar may not take. This entry is the exception, the same path
`c_sharp`, `swift` and `typescript` take.

## Notes

**There is no `method` node kind.** A Python method is a `function_definition`
nested inside a `class_definition` — the grammar draws no distinction. So this
profile labels `function_definition` as `function` and has no `method` label at
all, unlike C# (`method_declaration`) or Ruby (`method`). One container entry,
`function`, covers plain functions, methods and nested closures.

**`decorated_definition` is a landmark, but not a container.** A decorated
function parses as `decorated_definition` → `decorator` + `function_definition`.
It is kept as a landmark, as in the built-in profile codemark shipped before
0.8.0, so a `@decorator`-ed function or class has an anchor. It carries no
label, so it is never a container and doesn't double a breadcrumb — the trail
shows the wrapped `def`.

Lines inside decorated definitions can't currently be bookmarked, and that is
true with or without this landmark (and with the old built-in profile). A body
statement yields a query matching every decorated definition in the file, and a
decorator line yields an impossible `(decorator) @target` pattern. That's a
codemark query-generator limitation, recorded in `samples/invoice.py.lines`.

**`block` is the body wrapper.** Python's indented suite is a `block` node,
playing the role C#'s `declaration_list` does. It is dropped for the same
reason: it is a level that names nothing.

`lambda` is labelled `function` and kept as a landmark, but it has no `name`
field — like a Zig `struct_declaration`, it can anchor a query and stick while
scrolling, and the breadcrumb renderer skips it.

Extensions are `py`, `pyi` (stub files) and `pyw`. Stubs are worth including:
they are real Python the grammar parses, and a bookmark into a large `.pyi`
benefits from the same structure.
