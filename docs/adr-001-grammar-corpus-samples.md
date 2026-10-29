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

Use **three** sample sources per language, committed side by side in
`grammars/<lang>/samples/`:

| File | Source | Supplies |
|---|---|---|
| `corpus.<ext>` | extracted from the grammar's `test/corpus/` | syntactic breadth — every construct the grammar handles |
| `idiomatic.<ext>` | written for this repo | realistic nesting, ordinary constructs in context |
| `<Name>.<ext>` | written for this repo, small | the `.lines` breadcrumb targets |

`verify.sh` already passes every non-`.lines` file in `samples/` to the
generator, so this needs no harness change beyond the extractor.

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

## The corpus is not idiomatic, and that matters

A corpus block is a *parser test*, not code anyone would write:

```csharp
public class F {}
public class F : object, IAlpha, IOmega { }
internal class F<in T1, out T2> {}
```

Measured across the 154 C# blocks:

| Property | Value |
|---|---|
| Blocks using single-letter type names (`F`, `A`, `T1`) | 30 |
| Blocks showing a method body inside a class | **24 / 154** |
| Blocks at brace depth ≤ 1 (flat declarations) | **98 / 154** |
| Blocks at brace depth ≥ 3 | 16 |

The corpus is **breadth-first and structurally flat by construction** — it
proves each construct *parses*, deliberately in isolation. But `containers` is
derived only from observing one declaration nested inside another, so flatness
is exactly the wrong shape for the field that fails hardest.

### Idiomatic code finds different things

Running the generator over a hand-written, idiomatic 65-line C# service
(async, LINQ, records, events, a nested private class) against the 1387-line
corpus:

| Source | Landmarks | Containers |
|---|---|---|
| Corpus alone | 32 | 13 |
| Idiomatic alone | 17 | 8 |
| **Combined** | **32** | **14** |

The sets are not nested. Each finds containers the other misses:

- **Only idiomatic finds:** `constructor_declaration`
- **Only corpus finds:** `event_declaration`, `indexer_declaration`,
  `struct_declaration`, `local_function_statement`, `variable_declaration`,
  `function_pointer_parameter`

The corpus wins on *rare* constructs; idiomatic code wins on the *ordinary*
ones that a parser test has no reason to nest. A constructor containing
statements is unremarkable in real code and absent from a test suite that only
needs to prove constructors parse.

> **Three sources, not one.** Corpus for syntactic breadth, idiomatic sample
> for realistic nesting, small hand-written sample for the `.lines` breadcrumb
> targets. Measured, each contributes containers the others miss.

## What makes a good idiomatic sample

The corpus covers *what parses*. The idiomatic sample must cover *what nests*,
since that is the only way `containers` is discovered. Concretely:

- **Every container kind must actually contain something.** A constructor with
  a body, a method with a loop, a nested type with a method. An empty
  declaration teaches the generator nothing about containment.
- **Three levels deep at least** — `namespace > class > method > statement` —
  because that is what a real breadcrumb trail looks like.
- **The language's ordinary idioms**, not its exotica: async/await, LINQ or
  comprehensions, pattern matching, properties, generics with real
  constraints, error handling. These are what users bookmark.
- **No two sibling statements with the same shape.** Identical siblings make
  the generated structural query ambiguous and codemark refuses the bookmark —
  this has already bitten Scala, C# and Zig samples.
- **Realistic names.** `InvoiceService`, not `F`. Costs nothing, and makes a
  failing snapshot readable.

Sample code must be original to this repo or permissively licensed, as
CONTRIBUTING already requires.

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

**Published style guides** ([google/styleguide](https://github.com/google/styleguide)).
Code samples there are Apache-2.0 — a usable licence, unlike
learnxinyminutes. But they are *snippets illustrating a rule*, often
deliberately showing the wrong way too, and several guides (Java) carry almost
no inline code at all. They would need as much curation as writing the sample
directly, with worse structural coverage. Rejected; revisit per-language if an
idiomatic sample proves hard to write.

**[Rosetta Code](https://rosettacode.org/wiki/Rosetta_Code).** Appealing shape:
the same task implemented across many languages, which would make samples
comparable and give broad coverage cheaply. Rejected on two grounds.

*Licence, decisively.* Content is **GFDL 1.2** — copyleft with share-alike, and
notably harder to work with than learnxinyminutes' CC BY-SA: using the material
under any GFDL-incompatible licence requires permission from *every individual
contributor* who edited it. For a wiki with years of history that is not
practical.

*Structure, independently.* The examples are task fragments, not nested
programs — the C# `Classes` entry is ~25 lines with a class and a `Main`, the
Swift one ~15 lines with no namespace layer at all. That is the same flatness
problem the grammar corpus has, without the corpus's compensating breadth. It
would add a third source that overlaps what the idiomatic sample already
covers, while contributing no rare constructs.

**learnxinyminutes.** ~800–900 lines per language, genuinely good coverage of
syntax variations. Rejected on licence: CC BY-SA 3.0 share-alike would
propagate to this repo, which currently declares no licence at all and whose
CONTRIBUTING states "sample code must be yours or permissively licensed".
Worth revisiting for a grammar with no corpus, after settling this repo's own
licence.

**Hand-writing samples *instead of* the corpus.** Rejected — it reproduces the
guessing the generator exists to remove, and measurably misses rare constructs
(`event_declaration`, `indexer_declaration`, `struct_declaration`). But
hand-writing *alongside* the corpus is now part of the decision, because the
corpus is flat and misses ordinary nesting like a constructor with a body.

**Enumerating node types from the grammar.** Rejected previously and still
rejected: no usage signal, and it cannot produce `containers` at all. It is
also how the original broken Lua fixture happened — `call_expression` and
`local_function_declaration` looked plausible and did not exist.

## Open questions

- Should the extractor cap total size per language?
- Should corpus-derived and hand-written samples be distinguishable in the
  snapshot, so a reviewer can tell which source contributed a breadcrumb?
- Zig has no corpus. Leave it hand-written, or look for a secondary source?
