# codemark-grammars

Curated **language profiles** for [codemark](https://github.com/DanielCardonaRojas/codemark).

```bash
codemark languages registry list
codemark languages add ./tree-sitter-ruby.wasm --from-registry ruby
```

## Available

| Language | Extensions | Grammar | Revision |
|---|---|---|---|
| bash | `sh`, `bash` | [tree-sitter-bash](https://github.com/tree-sitter/tree-sitter-bash) | `v0.25.1` |
| lua | `lua` | [tree-sitter-lua](https://github.com/tree-sitter-grammars/tree-sitter-lua) | `v0.4.0` |
| ruby | `rb`, `rake`, `gemspec` | [tree-sitter-ruby](https://github.com/tree-sitter/tree-sitter-ruby) | `v0.23.1` |

### Where each `.wasm` came from

Every profile here was verified against a specific `.wasm`. These are the exact
release assets, so you can reproduce the verification rather than hoping your
build matches:

| Language | Download | SHA-256 | Size |
|---|---|---|---|
| bash | [`tree-sitter-bash.wasm` @ v0.25.1](https://github.com/tree-sitter/tree-sitter-bash/releases/download/v0.25.1/tree-sitter-bash.wasm) | `8292919c88a0f7d3…` | 1.30 MB |
| lua | [`tree-sitter-lua.wasm` @ v0.4.0](https://github.com/tree-sitter-grammars/tree-sitter-lua/releases/download/v0.4.0/tree-sitter-lua.wasm) | `46aa46cf86966ba3…` | 48 KB |
| ruby | [`tree-sitter-ruby.wasm` @ v0.23.1](https://github.com/tree-sitter/tree-sitter-ruby/releases/download/v0.23.1/tree-sitter-ruby.wasm) | `09a96427d7c72f06…` | 2.01 MB |

Regenerate this table with `scripts/asset-table.sh` after adding a language or
re-pinning a revision, so it can't drift from `index.json`.

A checksum mismatch isn't necessarily a problem — a `.wasm` you build yourself
from the same revision will differ byte-for-byte from the released one (emscripten
output isn't reproducible across toolchains). The Lua profile was authored against
a locally built 53 KB `.wasm` and verifies *identically* against the 48 KB release
asset: node kinds come from the grammar revision, not the build.

The checksums are here so you can tell *which* artifact a result came from, not
as a security control — verify the download against GitHub's release page if
that matters to you.

## Profiles, not binaries

This registry ships `manifest.json` files. It does **not** host `.wasm`
grammars — you supply those.

Many grammars publish a prebuilt `.wasm` in their GitHub releases, which is the
quickest route. Codemark accepts **ABI 13–15** (roughly CLI 0.21–0.25) and
rejects an incompatible module up front, so it's safe to just try one:

```bash
curl -fsSL -o ruby.wasm \
  https://github.com/tree-sitter/tree-sitter-ruby/releases/download/v0.23.1/tree-sitter-ruby.wasm
codemark languages add ./ruby.wasm --from-registry ruby
```

Otherwise build it (needs Docker or emscripten):

```bash
npm install -g tree-sitter-cli@0.25
git clone --depth 1 --branch <rev> https://github.com/tree-sitter/tree-sitter-ruby
cd tree-sitter-ruby && tree-sitter build --wasm
```

**Finding a grammar:** tree-sitter has no search command.
[nvim-treesitter's `parsers.lua`](https://github.com/nvim-treesitter/nvim-treesitter/blob/main/lua/nvim-treesitter/parsers.lua)
is the best source — ~570 parsers, machine-readable, each with a repo URL and a
pinned revision (which is what `grammar_rev` wants). The
[tree-sitter wiki list](https://github.com/tree-sitter/tree-sitter/wiki/List-of-parsers)
is the canonical catalogue but carries no revisions.

That split is deliberate. Hosting binaries would mean running a build pipeline
for every grammar at ABI 0.25, reviewing each grammar's license for
redistribution, and serving megabytes per language — none of which is the actual
problem. The problem is the profile.

## What a profile is, and why it needs curating

Codemark can parse any language with a Tree-sitter grammar. The *profile* is what
makes it useful: which node kinds are structural landmarks, what to call them,
and which ones nest others (for breadcrumbs).

The node kinds are grammar-specific and non-obvious. Ruby says `method`, Rust
says `function_item`, Lua says `function_declaration` — and Lua has
`function_call`, not `call_expression`. Guess wrong and **nothing visibly
breaks**: `landmark_kinds` quietly falls back to a built-in set, and `containers`
just stops producing breadcrumbs. A profile can be wrong for a long time without
anyone noticing.

So every profile here is machine-verified, not merely reviewed. See
[CONTRIBUTING.md](CONTRIBUTING.md).

## Layout

```
index.json                         what's available; one entry per language
grammars/<lang>/
  manifest.json                    the curated profile
  samples/<file>                   real source the profile is verified against
  samples/<file>.lines             which lines to bookmark
  expected/bookmarks.json          committed snapshot of the results
  README.md                        grammar repo, revision, notes
scripts/verify.sh                  the verification harness
```

### One entry per language, not per version

Most grammars absorb new syntax by *adding* node kinds, so a single profile
covers Swift 4/5/6. Genuinely separate grammars (Python 2 vs 3) get separate
entries with distinct names — not a version field — because codemark's grammar
cache is one directory per name and stored bookmarks reference a language by
name alone.

`grammar_rev` pins the revision a profile was authored and verified against,
since a renamed node kind silently invalidates a profile.

## Using a different registry

```toml
# ~/.config/codemark/config.toml
[grammars]
registry_url = "file:///srv/codemark-grammars"   # fork, mirror, or air-gapped
```

`CODEMARK_GRAMMAR_REGISTRY` overrides it for one run. The index is cached
locally, so installs keep working offline.
