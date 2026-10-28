# Bash

| | |
|---|---|
| Grammar | https://github.com/tree-sitter/tree-sitter-bash |
| Revision | `v0.25.1` |
| Built with | tree-sitter CLI 0.25 (prebuilt release asset) |
| Profile version | 1.0.0 |

## Verified against

```bash
curl -fsSL -o bash.wasm \
  https://github.com/tree-sitter/tree-sitter-bash/releases/download/v0.25.1/tree-sitter-bash.wasm
codemark languages add ./bash.wasm --from-registry bash
```

SHA-256 `8292919c88a0f7d3fb31d0cd0253ca5a9531bc1ede82b0537f2c63dd8abe6a7a`.

A `.wasm` you build yourself will differ byte-for-byte (emscripten output
isn't reproducible) but should verify identically — node kinds come from the
grammar revision, not the build.

## Notes

Bash has one container kind: `function_definition`. There is no class or module
layer, so breadcrumbs are a single level — that is correct, not a gap.

`declaration_command` (`local`, `declare`, `export`) is a landmark so those
bindings can be bookmarked, but it is not a container: it holds no nested
declarations.
