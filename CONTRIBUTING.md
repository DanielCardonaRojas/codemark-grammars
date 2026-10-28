# Contributing a profile

Adding a language is five files and one script. The script is the point: it
proves your profile works instead of asking a reviewer to take it on faith.

## 1. Build the grammar

```bash
npm install -g tree-sitter-cli@0.25          # must be 0.25 — that's the ABI codemark loads
git clone --depth 1 --branch v1.2.3 https://github.com/tree-sitter/tree-sitter-ruby
cd tree-sitter-ruby && tree-sitter build --wasm
```

Note the exact tag you cloned — it becomes `grammar_rev`.

## 2. Generate the profile — don't hand-write it

```bash
# needs a codemark built with --features profile-authoring
codemark languages profile init ./tree-sitter-ruby.wasm \
  --sample sample.rb --name ruby --extensions rb,rake \
  --out grammars/ruby/manifest.json
```

This parses your samples and derives the profile from what the trees actually
contain. It prints an **evidence table** — every node kind it saw, how often,
whether it became a landmark, which field held its name, and why — so you can
audit each decision rather than trusting the output.

Hand-writing is the fallback, not the default. The kinds are grammar-specific
and a wrong one fails silently.

## 3. Add samples and pick lines

```
grammars/ruby/samples/sample.rb         real source, covering the constructs you care about
grammars/ruby/samples/sample.rb.lines   1-based lines to bookmark, one per line
```

**Choose lines that sit *inside* constructs your profile claims to understand** —
a statement nested in a method nested in a class. A line at top level exercises
nothing. If `containers` is wrong, a nested line loses its breadcrumb; a
top-level line looks fine either way.

Sample code must be yours or permissively licensed.

## 4. Add the index entry

```json
{
  "name": "ruby",
  "extensions": ["rb", "rake"],
  "profile_version": "1.0.0",
  "profile_url": "grammars/ruby/manifest.json",
  "ts_abi": "0.25",
  "grammar_repo": "https://github.com/tree-sitter/tree-sitter-ruby",
  "grammar_rev": "v1.2.3",
  "description": "Ruby"
}
```

`name` must not collide with a codemark built-in (rust, swift, typescript,
python, go, java, c#, dart) or their aliases — such an entry could never
resolve, and codemark rejects it on install.

## 5. Verify

```bash
./scripts/verify.sh ruby --update     # generate the snapshot
./scripts/verify.sh ruby              # confirm it passes
```

Commit the generated `expected/bookmarks.json`. CI runs the same script.

### What verification actually checks

1. The grammar builds at the pinned revision.
2. The profile installs — which **lints every node kind and container field
   against the grammar**. A kind the grammar doesn't define is an error: it can
   never match.
3. `codemark languages validate` is clean.
4. Bookmarking each chosen line reproduces the committed query, resolution
   method and breadcrumbs.

Step 4 is what the other steps can't do. Deleting a `containers` entry passes
the lint (it's only a warning), installs fine, validates fine, and produces a
*byte-identical query* — breadcrumbs just quietly stop. Only the snapshot
catches it.

## Updating an existing profile

Re-run with `--update`, then **read the diff**. Breadcrumbs that disappeared
mean a `containers` entry stopped matching. Bump `profile_version` in
`index.json`; bump `grammar_rev` too if you re-pinned the grammar.

## Review checklist

- [ ] `grammar_rev` is an exact tag or commit, not a branch
- [ ] Samples cover nesting, not just top-level declarations
- [ ] At least one chosen line is 2+ levels deep
- [ ] `expected/bookmarks.json` is committed and CI is green
- [ ] Non-empty breadcrumbs wherever a line sits inside a named construct
- [ ] `grammars/<lang>/README.md` records the grammar repo, revision, and
      anything surprising about the language
