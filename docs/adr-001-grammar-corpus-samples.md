# ADR-001: Use a grammar's own test corpus as a profile sample

**Status:** Proposed
**Date:** 2026-10-28

## Context

A profile is derived entirely from parsing sample files. `propose_profile`
takes `(language, samples)` and reads nothing else — no node-type enumeration,
no grammar introspection beyond what the parse produces. That is deliberate: a
grammar's node-type list carries no usage signal (`tree-sitter-lua` defines 47
named kinds; three belong in `landmark_kinds`), and `containers` can only be
derived by *observing* which field holds a node's name.

The consequence is that coverage equals sample coverage. Today's samples are
hand-written and 24–53 lines, so they miss a lot:

| Language | Sample | Landmarks | Labels |
|---|---|---|---|
| bash | 24 lines | 2 | 5 |
| c_sharp | 45 lines | 8 | 10 |
| ruby | 32 lines | 4 | 8 |
| zig | 29 lines | 3 | 6 |

For C# that means `enum_declaration`, `record_declaration`,
`delegate_declaration`, `destructor_declaration`, `event_declaration` and
`operator_declaration` are all absent from the profile. They still *resolve*,
because `landmark_kinds` is ORed against codemark's built-in
`DECLARATION_TYPES` union — but that is luck, not design. A kind outside that
40-entry union is a silent gap.

Writing richer samples by hand doesn't scale and reproduces the original
problem: a human guessing which constructs matter.

## Decision

Use the grammar's own `test/corpus/` as an additional sample source, alongside
a small hand-written file.

Tree-sitter grammars conventionally ship a corpus of test cases in
`test/corpus/*.txt`, in this format:

```
================================================================================
Basic record declaration
================================================================================

record F {
  int Age { get; init; }
}

public record F<T> where T:struct {}

--------------------------------------------------------------------------------

(compilation_unit
  (record_declaration ...))
```

A header, the source, `---`, then the expected S-expression. We extract only
the source halves and concatenate them into one sample file.

### Why this source

- **Correctly licensed.** MIT for tree-sitter-c-sharp and most grammars, versus
  CC BY-SA 3.0 for [learnxinyminutes](https://learnxinyminutes.com/), whose
  share-alike terms would propagate to this repo.
- **Already pinned.** The corpus ships *at the `grammar_rev` the profile
  targets*, so samples and grammar cannot drift apart.
- **No new dependency.** The harness already clones that repo at that revision
  to build the `.wasm`.
- **Exhaustive by construction.** It is the grammar authors' own record of
  every syntactic form the grammar claims to handle.

### Measured effect (C#)

| | Hand-written (45 lines) | Corpus (1387 lines) |
|---|---|---|
| Landmarks | 8 | **32** |
| Labels | 10 | **30** |
| Containers | 6 | **13** |

Newly discovered: `enum_declaration`, `record_declaration`,
`delegate_declaration`, `destructor_declaration`, `event_declaration`,
`conversion_operator_declaration`, `file_scoped_namespace_declaration`, and
more.

## The corpus is not sufficient on its own

**This is the part that decides the design.** Corpus blocks are syntax
fragments — the median C# block is **5 lines**, and only 25 of 154 blocks show
a class with meaningful nesting. They demonstrate that a construct *parses*,
not that it *contains* other constructs.

`containers` depends entirely on observing one declaration nested inside
another. Measured directly:

| Input | Containers found |
|---|---|
| Corpus alone | 13 — but **no `method_declaration`** |
| Corpus + hand-written sample | 13 — **including `method_declaration`** |

A method inside a class is the single most valuable breadcrumb in almost any
language, and the corpus alone misses it. So:

> **Both sources are required.** The corpus supplies syntactic breadth; the
> hand-written sample supplies nesting depth. Neither substitutes for the other.

## Consequences

### More curation, not less

Broader coverage surfaces more noise. The C# corpus proposes 7 landmarks that
must be curated out — `declaration_list`, `enum_member_declaration_list`,
`declaration_expression`, `declaration_pattern`, `lambda_expression`,
`foreach_statement`, `function_pointer_parameter` — against 3 from the small
sample.

That is an acceptable trade: curation is reviewable and happens once, whereas a
missing kind fails silently at runtime. But it argues for two follow-ups:

- Teach the generator to recognise `_list`-suffixed wrappers directly, since
  that pattern recurs across every grammar examined.
- Have `profile init` report coverage ("the grammar defines N named kinds; your
  samples exercised M") so a gap is visible rather than assumed away.

### Not every grammar has one

| Grammar | `test/corpus/` |
|---|---|
| tree-sitter-c-sharp | 19 files, 324 KB |
| tree-sitter-php | 13 files (under `php/`) |
| tree-sitter-swift | 10 files |
| tree-sitter-ruby | 9 files |
| tree-sitter-bash | 5 files |
| **tree-sitter-zig** | **none** |

So corpus extraction must be **optional**, degrading to the hand-written sample
alone. The index already carries `grammar_dir` for repos whose grammar is in a
subdirectory (PHP); corpus lookup follows the same path.

### Repository size

The extracted C# source is ~1387 lines. Across nine languages that is a few
hundred KB of committed sample — acceptable, and it keeps `verify.sh`
hermetic (no network at verification time). If it becomes a problem, the
extractor can cap blocks per file.

### Licensing

Each grammar's licence must be checked before vendoring its corpus, and
recorded in `grammars/<lang>/README.md` next to the existing provenance. Verified: all eight
grammars currently in the registry are MIT. That must not be assumed for future
ones.

## Implementation sketch

1. `scripts/extract-corpus.sh <language>` — clone the pinned `grammar_rev`
   (already done by `verify.sh`), walk `${grammar_dir}/test/corpus/*.txt`,
   emit source halves to `grammars/<lang>/samples/corpus.<ext>`.
2. Commit the extracted file alongside the hand-written sample. `verify.sh`
   already passes every non-`.lines` file in `samples/` to the generator.
3. `.lines` entries continue to come from the **hand-written** sample only —
   corpus fragments are too short and too numerous to pick breadcrumb targets
   from, and their line numbers would churn on every grammar bump.
4. Re-run `verify.sh <lang> --update`, review the diff, bump
   `profile_version`.
5. Record the corpus's licence in the language README.

## Alternatives considered

**learnxinyminutes.** ~800–900 lines per language, genuinely good coverage of
syntax variations. Rejected on licence: CC BY-SA 3.0 share-alike would
propagate to this repo, which currently declares no licence at all and whose
CONTRIBUTING states "sample code must be yours or permissively licensed".
Worth revisiting for a grammar with no corpus, after settling this repo's own
licence.

**Hand-writing richer samples.** Does not scale, and reproduces the guessing
the generator exists to remove.

**Enumerating node types from the grammar.** Rejected previously and still
rejected: no usage signal, and it cannot produce `containers` at all. It is
also how the original broken Lua fixture happened — `call_expression` and
`local_function_declaration` looked plausible and did not exist.

## Open questions

- Should the extractor cap total size per language?
- Should corpus-derived and hand-written samples be distinguishable in the
  snapshot, so a reviewer can tell which source contributed a breadcrumb?
- Zig has no corpus. Leave it hand-written, or look for a secondary source?
