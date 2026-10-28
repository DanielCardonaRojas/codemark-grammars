# Lua

| | |
|---|---|
| Grammar | https://github.com/tree-sitter-grammars/tree-sitter-lua |
| Revision | `v0.4.0` |
| Built with | tree-sitter CLI 0.25 (prebuilt release asset) |
| Profile version | 1.0.0 |

## Verified against

```bash
curl -fsSL -o lua.wasm \
  https://github.com/tree-sitter-grammars/tree-sitter-lua/releases/download/v0.4.0/tree-sitter-lua.wasm
codemark languages add ./lua.wasm --from-registry lua
```

SHA-256 `46aa46cf86966ba30af11a2674372ec0e51dd355464cad1aa1dca3a981a84a2b`.

A `.wasm` you build yourself will differ byte-for-byte (emscripten output
isn't reproducible) but should verify identically — node kinds come from the
grammar revision, not the build.

## Notes on this grammar

Lua's node kinds differ from the names most other grammars use, which makes it a
good reference case — several plausible-looking kinds simply don't exist:

| Plausible guess | Actual Lua kind |
|---|---|
| `call_expression` | `function_call` |
| `local_function_declaration` | *(none)* — locals are `variable_declaration` |
| `function_definition_statement` | *(none)* |

An earlier hand-written version of this profile used the left column. It loaded
without complaint and produced no breadcrumbs at all, because the single
`containers` entry pointed at a kind that doesn't exist. That is the failure this
registry's verification exists to prevent.

### Three landmark shapes

Lua exercises all three ways a declaration can appear, which is why it's useful
as the reference entry:

- `function_declaration` — a name field *and* a body. The clean case, and the
  only one that can be a container.
- `function_definition` — an anonymous function expression: a body, but no name
  of its own (the name lives on the enclosing assignment). A landmark, never a
  container, so a bookmark inside one correctly has **no** breadcrumb.
- `variable_declaration` — no fields at all; the name is nested under
  `assignment_statement > variable_list`. A landmark via that nested name.

## Known limitation

`samples/sample.lua.lines` has line 21 commented out. Bookmarking a line two
levels deep (inside a `for` loop inside a function) currently fails in
codemark's query generator with "Impossible pattern" — it constrains a `name:`
field on an ancestor kind that has none. This is a generator bug, not a profile
one: it reproduces with an empty profile. Re-enable that line once it's fixed.
