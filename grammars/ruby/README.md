# Ruby

| | |
|---|---|
| Grammar | https://github.com/tree-sitter/tree-sitter-ruby |
| Revision | `v0.23.1` |
| Built with | tree-sitter CLI 0.23 (prebuilt release asset) |
| Profile version | 1.0.0 |

Obtained from the repo's release assets rather than built from source — codemark
accepts ABI 13–15, so a 0.23-era `.wasm` loads fine.

## Verified against

```bash
curl -fsSL -o ruby.wasm \
  https://github.com/tree-sitter/tree-sitter-ruby/releases/download/v0.23.1/tree-sitter-ruby.wasm
codemark languages add ./ruby.wasm --from-registry ruby
```

SHA-256 `09a96427d7c72f0613ed470cd9812223fc4a91d6a9c025c0235cc6bd59ff96f4`.

A `.wasm` you build yourself will differ byte-for-byte (emscripten output
isn't reproducible) but should verify identically — node kinds come from the
grammar revision, not the build.

## Notes

Ruby names its declarations with bare words (`class`, `module`, `method`,
`singleton_method`) rather than the `*_declaration` / `*_item` conventions most
grammars use. Anything derived from kind names alone will miss them.

`method` and `singleton_method` were added to `containers` by hand. The
generator only proposes a container for a kind it *observes* wrapping another
declaration, and in this sample the methods contain only control flow — correct
by its own rule, but methods are exactly what you want named in a breadcrumb.
