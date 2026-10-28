# codemark-grammars

Curated **language profiles** for [codemark](https://github.com/codemark-dev/codemark).

```bash
codemark languages registry list
codemark languages add ./tree-sitter-ruby.wasm --from-registry ruby
```

## Profiles, not binaries

This registry ships `manifest.json` files. It does **not** host `.wasm`
grammars — you build those yourself:

```bash
npm install -g tree-sitter-cli@0.25
git clone --depth 1 --branch <rev> https://github.com/tree-sitter/tree-sitter-ruby
cd tree-sitter-ruby && tree-sitter build --wasm
```

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
