# codemark-grammars

Curated **language profiles** for [codemark](https://github.com/DanielCardonaRojas/codemark).

```bash
codemark languages registry list
codemark languages install ruby      # downloads, verifies, installs
```

## Available

| Language | Extensions | Grammar | Revision |
|---|---|---|---|
| bash | `sh`, `bash` | [tree-sitter-bash](https://github.com/tree-sitter/tree-sitter-bash) | `v0.25.1` |
| c_sharp ⚠️ | `cs`, `csx` | [tree-sitter-c-sharp](https://github.com/tree-sitter/tree-sitter-c-sharp) | `v0.23.1` |
| go ⚠️ | `go` | [tree-sitter-go](https://github.com/tree-sitter/tree-sitter-go) | `v0.25.0` |
| lua | `lua` | [tree-sitter-lua](https://github.com/tree-sitter-grammars/tree-sitter-lua) | `v0.4.0` |
| php | `php`, `phtml` | [tree-sitter-php](https://github.com/tree-sitter/tree-sitter-php) | `v0.25.1` |
| python ⚠️ | `py`, `pyi`, `pyw` | [tree-sitter-python](https://github.com/tree-sitter/tree-sitter-python) | `v0.25.0` |
| ruby | `rb`, `rake`, `gemspec` | [tree-sitter-ruby](https://github.com/tree-sitter/tree-sitter-ruby) | `v0.23.1` |
| scala | `scala`, `sc` | [tree-sitter-scala](https://github.com/tree-sitter/tree-sitter-scala) | `v0.26.3` |
| swift ⚠️ | `swift` | [tree-sitter-swift](https://github.com/alex-pinkus/tree-sitter-swift) | `0.7.3` |
| typescript ⚠️ | `ts` | [tree-sitter-typescript](https://github.com/tree-sitter/tree-sitter-typescript) | `v0.23.2` |
| zig | `zig`, `zon` | [tree-sitter-zig](https://github.com/tree-sitter-grammars/tree-sitter-zig) | `v1.1.2` |

⚠️ **replaces a codemark built-in.** `languages install` handles it; a manual
`add` needs `--override-builtin`. Codemark prefers a dynamic grammar over the
built-in it shadows, which is what lets a bundled language be served from here —
C#, Swift and TypeScript are together 11.7 MB of codemark's 24.2 MB binary.
Python and Go join them for the same reason.

Some languages were evaluated and set aside — see
[NOT-YET-SUPPORTED.md](NOT-YET-SUPPORTED.md) for which, and why.

### Where each `.wasm` came from

Every profile here was verified against a specific `.wasm`. These are the exact
release assets, so you can reproduce the verification rather than hoping your
build matches:

| Language | Download | SHA-256 | Size |
|---|---|---|---|
| bash | [`tree-sitter-bash.wasm` @ v0.25.1](https://github.com/tree-sitter/tree-sitter-bash/releases/download/v0.25.1/tree-sitter-bash.wasm) | `8292919c88a0f7d3…` | 1.30 MB |
| c_sharp | [`tree-sitter-c_sharp.wasm` @ v0.23.1](https://github.com/tree-sitter/tree-sitter-c-sharp/releases/download/v0.23.1/tree-sitter-c_sharp.wasm) | `d7fe0bf8e8b8d26b…` | 5.65 MB |
| go | [`tree-sitter-go.wasm` @ v0.25.0](https://github.com/tree-sitter/tree-sitter-go/releases/download/v0.25.0/tree-sitter-go.wasm) | `9504573f352b20be…` | 212 KB |
| lua | [`tree-sitter-lua.wasm` @ v0.4.0](https://github.com/tree-sitter-grammars/tree-sitter-lua/releases/download/v0.4.0/tree-sitter-lua.wasm) | `46aa46cf86966ba3…` | 48 KB |
| php | [`tree-sitter-php.wasm` @ v0.25.1](https://github.com/tree-sitter/tree-sitter-php/releases/download/v0.25.1/tree-sitter-php.wasm) | `bd5e2bf8d42306b7…` | 1.03 MB |
| python | [`tree-sitter-python.wasm` @ v0.25.0](https://github.com/tree-sitter/tree-sitter-python/releases/download/v0.25.0/tree-sitter-python.wasm) | `16108b50df4ee9a3…` | 447 KB |
| ruby | [`tree-sitter-ruby.wasm` @ v0.23.1](https://github.com/tree-sitter/tree-sitter-ruby/releases/download/v0.23.1/tree-sitter-ruby.wasm) | `09a96427d7c72f06…` | 2.01 MB |
| scala | [`tree-sitter-scala.wasm` @ v0.26.3](https://github.com/tree-sitter/tree-sitter-scala/releases/download/v0.26.3/tree-sitter-scala.wasm) | `3809e090e63fa5a9…` | 3.84 MB |
| swift | [`tree-sitter-swift.wasm` @ 0.7.3](https://github.com/alex-pinkus/tree-sitter-swift/releases/download/0.7.3/tree-sitter-swift.wasm) | `0258a7ef17303a80…` | 3.65 MB |
| typescript | [`tree-sitter-tsx.wasm` @ v0.23.2](https://github.com/tree-sitter/tree-sitter-typescript/releases/download/v0.23.2/tree-sitter-tsx.wasm) | `79e5da75ea62855a…` | 1.38 MB |
| zig | [`tree-sitter-zig.wasm` @ v1.1.2](https://github.com/tree-sitter-grammars/tree-sitter-zig/releases/download/v1.1.2/tree-sitter-zig.wasm) | `54b3b83dd9c62da5…` | 675 KB |

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

This registry **hosts** `manifest.json` files only. It does not serve `.wasm`
grammars — but each entry *points at* the prebuilt one published by the
grammar's own project, pinned by SHA-256, which is what makes
`codemark languages install <lang>` a single step. Codemark downloads from
upstream, verifies the digest against this repo's index, and refuses to install
anything else.

An entry without a `wasm_url` still works; you just supply the `.wasm`:

```bash
codemark languages add ./ruby.wasm --from-registry ruby
```

Codemark accepts **ABI 13–15** (roughly CLI 0.21–0.25) and rejects an
incompatible module up front, so it's safe to try whatever you have. To build it
yourself (needs Docker or emscripten):

```bash
npm install -g tree-sitter-cli@0.25
git clone --depth 1 --branch <rev> https://github.com/tree-sitter/tree-sitter-ruby
cd tree-sitter-ruby && tree-sitter build --wasm
```

Shipping profiles rather than binaries is deliberate: hosting `.wasm` files
would mean a build pipeline per grammar, a license review per grammar, and
megabytes per language — none of which is the actual problem. The problem is the
profile.

**Finding a grammar:** tree-sitter has no search command.
[nvim-treesitter's `parsers.lua`](https://github.com/nvim-treesitter/nvim-treesitter/blob/main/lua/nvim-treesitter/parsers.lua)
is the best source — ~570 parsers, machine-readable, each with a repo URL and a
pinned revision (which is what `grammar_rev` wants). The
[tree-sitter wiki list](https://github.com/tree-sitter/tree-sitter/wiki/List-of-parsers)
is the canonical catalogue but carries no revisions.

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
[CONTRIBUTING.md](CONTRIBUTING.md) to add one, and [MANIFEST.md](MANIFEST.md)
for a field-by-field breakdown of what a profile contains and how each part
fails.

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
scripts/asset-table.sh             regenerates the provenance table
MANIFEST.md                        what every manifest field means
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
