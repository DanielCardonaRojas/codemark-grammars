# Anatomy of a profile manifest

Every `grammars/<lang>/manifest.json` in this repo — and every manifest codemark
installs into its grammar cache — uses this format. This page explains each
field, **which code actually reads it**, and **how each one fails**, which is
rarely an error message.

If you're contributing a profile, read this alongside
[CONTRIBUTING.md](CONTRIBUTING.md). The short version: don't hand-write a
manifest. Fetch one with `--from-registry`, or generate one with
`languages profile init`, and hand-edit only to curate the result.

---

## Shape

```json
{
  "name": "lua",
  "version": "0.3.0",
  "extensions": ["lua"],
  "profile": {
    "landmark_kinds": [
      "function_declaration",
      "function_definition",
      "variable_declaration"
    ],
    "node_labels": {
      "function_declaration": "function",
      "function_definition": "function",
      "if_statement": "if statement",
      "function_call": "call"
    },
    "containers": ["function"]
  }
}
```

The single `"function"` container covers both `function_declaration` and
`function_definition`, since both carry that label.

Codemark reads exactly three top-level fields:

```rust
struct Manifest {
    name: String,
    extensions: Vec<String>,
    profile: Option<Profile>,
}
```

`version` is written by `codemark languages add` (always `"0.1.0"`) and **never
read back**. In this repo the meaningful one is `profile_version` in
`index.json` — that's what `languages registry list` displays, and what you bump
when you change a profile.

---

## Top-level fields

### `name`

Carries three separate responsibilities:

1. **Bookmark identity.** Codemark stores this string on every bookmark and
   looks the language up by it when resolving later. Renaming a grammar after
   bookmarks exist orphans them.
2. **Collision domain.** It must not be — or alias — a codemark built-in.
   `rust`, `rs`, `ts`, `py`, `cs` and friends are rejected before any file is
   written, because such a grammar could never win lookup.
3. **WASM symbol binding.** A Tree-sitter module exports `tree_sitter_<name>`,
   so this must match the grammar's own name. Installing
   `tree-sitter-lua.wasm` under the name `mylua` fails with *"module did not
   contain language function: tree_sitter_mylua"*.

Registration keys off this field, **not the directory name**. Keep them equal by
convention, but nothing enforces it. Matching is case-insensitive.

### `extensions`

Dotless and lowercase: `["rb", "rake", "gemspec"]`.

`codemark languages add` normalizes what you pass on the command line — trims,
strips a leading `.`, lowercases, drops empties. **A hand-edited manifest gets
none of that.** A stored `".lua"` registers verbatim and matches no file;
`languages list` will show `[".lua"]` while nothing resolves.

Extensions owned by a built-in are dropped at discovery with a warning. The
grammar's other extensions still register — it isn't all-or-nothing.

### `curation` (registry-only)

Not read by codemark — it exists so the committed profile is **reproducible**:

```
generated(samples) + curation == committed profile
```

The generator proposes a profile from the samples; a human then removes noise
and adds containers the samples don't happen to nest. Recording those edits
makes the difference auditable, and `scripts/verify.sh` asserts the equation,
so a sample change that alters the proposal fails loudly instead of leaving the
manifest quietly stale.

```json
"curation": {
  "drop_landmarks": ["declaration_list", "foreach_statement"],
  "add_containers": ["constructor"],
  "why": "declaration_list is the { } body wrapper; a constructor nests statements in real code even though this sample's doesn't."
}
```

| Key | Effect |
|---|---|
| `drop_landmarks` | remove the **kind** from landmarks and labels |
| `drop_labels` | remove just the label for that kind |
| `drop_containers` | remove one **label** from `containers` |
| `add_landmarks` / `add_labels` | the inverse, keyed by node kind |
| `add_containers` | add one **label** to `containers` |
| `why` | **required** — a reviewer must be able to tell curation from a mistake |

Note the asymmetry: landmarks and labels are keyed by **node kind**, containers
by **label**. Dropping a landmark therefore does *not* implicitly drop a
container — several kinds can share a label, so removing `foreach_statement`
must not take `class` with it. A label is dropped only when no remaining kind
carries it.

Drops apply before additions, so the result doesn't depend on key order.

### `profile`

Optional. Omitting it (or `{}`) is valid: parsing and structural resolution work
without one. What you lose is breadcrumbs and good query summaries — which is
the entire reason this registry exists.

Unknown keys inside `profile` are **ignored, not rejected**. That's deliberate,
so a manifest from a newer codemark still loads on an older binary. The cost is
that a typo'd key silently does nothing. `codemark languages validate` reports
them as warnings.

---

## The three profile fields

Each has exactly one consumer, and — the key fact — **they don't fail the same
way**:

| Field | Consumer | If wrong |
|---|---|---|
| `landmark_kinds` | `generator::is_landmark_kind` | Degrades quietly — falls back to a built-in union of 40 kinds |
| `node_labels` | `classifier::classify_node_type` | Degrades quietly — falls back to a global table |
| `containers` | `breadcrumbs::extract_breadcrumbs` | **Breadcrumbs vanish — no fallback at all** |

Two have a safety net. One doesn't. That asymmetry is why this repo verifies
profiles against committed snapshots instead of trusting review — see
[CONTRIBUTING.md](CONTRIBUTING.md#what-verification-actually-checks).

### `landmark_kinds`

Node kinds that anchor a structural query. When codemark walks from a bookmarked
node up to the file root, landmark ancestors become part of the stored query —
that's what lets a bookmark survive edits elsewhere in the file.

Typically declarations: functions, methods, classes, structs, enums, modules,
type aliases, constants.

**It is additive, not authoritative:**

```rust
fn is_landmark_kind(node_kind: &str, profile: &Profile) -> bool {
    profile.landmark_kinds.iter().any(|k| k == node_kind)
        || DECLARATION_TYPES.contains(&node_kind)
}
```

`DECLARATION_TYPES` is a 40-kind union drawn from codemark's eight built-in
languages. So `class_declaration` is a landmark for *your* grammar whether you
list it or not — which is exactly why a wrong `landmark_kinds` often looks like
it works. You can add kinds; you can't remove them.

### `node_labels`

**This is a translation layer into one cross-language vocabulary.** Each grammar
spells its constructs differently; `node_labels` maps those spellings onto a
shared set of concepts, so query summaries and TUI icons can talk about "a
function" without knowing the language.

The same concept across the profiles in this repo:

| Language | Node kind | Label |
|---|---|---|
| Ruby | `method` | `method` |
| Bash | `function_definition` | `function` |
| Lua | `function_declaration` | `function` |
| PHP | `method_declaration` | `method` |
| Scala | `function_definition` | `function` |
| Zig | `function_declaration` | `function` |

Six grammars, five spellings, one concept. That normalization is the whole
point — a profile that gets the left column right but invents labels on the
right has made its language *less* usable, not more.

It isn't limited to landmarks: control flow and expressions get labels too
(`if statement`, `for loop`, `call`), which is what makes a query summary
readable.

Also additive: a missing entry falls through to a global table, then to the raw
node kind.

**So the value side is not free-form.** Icon lookup keys off the label string,
so an invented one parses fine and silently loses its icon — and splits a
concept that should be unified across languages:

`function` · `method` · `class` · `interface` · `enum` · `impl` · `module` ·
`namespace` · `type` · `variable` · `macro` · `constructor` · `init` ·
`deinit` · `subscript` · `if statement` · `for loop` · `while loop` · `match` ·
`return` · `assignment` · `call` · `expression`

`languages validate` warns about anything outside this set.

> **`node_labels` does not create `@sticky` captures.** The `@sticky.function`
> annotations you see in generated queries come from a hardcoded table in
> codemark's generator that takes no profile. Adding a label here won't produce
> one.

### `containers`

**Labels** from [`node_labels`](#node_labels), naming the landmarks the UI treats
specially:

```json
"node_labels": {
  "class_declaration": "class",
  "struct_declaration": "class",
  "method_declaration": "method"
},
"containers": ["class", "method"]
```

A bookmark nested inside a kind carrying one of those labels gets a trail:

```
Context: 2:module Billing › 3:  class Invoice › 11:    def compute
```

One entry covers **every** kind with that label, which is the point of keying on
the classified vocabulary: a grammar's several spellings of the same idea are
named once. Above, `class` picks up both `class_declaration` and
`struct_declaration`.

Three counterintuitive properties:

**1. No fallback.** The walker builds its whitelist purely from this list. Name a
label no kind in the profile carries — or leave it empty — and breadcrumbs are
blank. Unlike the other two fields, nothing covers for you. `validate` reports an
unmatched label as an **error** for exactly this reason.

**2. A container does not have to be named.** This is the part that trips people
authoring a profile for a language like Zig.

`containers` drives two presentations of one idea:

| Presentation | What it needs | Nameless container |
|---|---|---|
| **Sticky header** | the *line*, pinned at the top of the viewer while you scroll | works fine |
| **Breadcrumb trail** | the *name*, for a one-line path to the target | skipped by the renderer |

So a kind with no name field is still a legitimate container. A Zig struct is an
anonymous value bound by its enclosing `variable_declaration`:

```zig
pub const Invoice = struct {
    pub fn compute(self: *Self) f64 { ... }
};
```

`struct_declaration` has no name of its own, but you certainly want it pinned
while scrolling through its methods. Listing its label is correct; the breadcrumb
renderer is what decides to skip it.

**3. A container is a landmark with a body.** That is the rule the generator
applies, and having a body is what makes a kind worth pinning — it is something
you can scroll inside. A one-liner (a C# `field_declaration`, a TypeScript
`method_signature`) has nothing to scroll past and only adds noise.

This cuts both ways, and the cut is visible in this repo. C#'s
`property_declaration` is labelled `variable`, the same as `field_declaration`,
so it cannot be a container without dragging those one-liners in too — recorded
in that manifest's `curation.why` rather than worked around.

#### The legacy pair form

Manifests written before this schema used `[node_kind, name_field]` pairs:

```json
"containers": [["class_declaration", "name"], ["impl_item", "type"]]
```

Codemark still reads them, so an old manifest keeps working — `Profile` is
`#[serde(default)]` with no `deny_unknown_fields` precisely so that holds. The
name field is dropped on the way in: nothing ever read it (the walker extracts
the whole source line), and the label form has no per-kind slot for it.
`validate` reports the pair form as a warning pointing at the new shape.

Every profile in this repo is on the label form as of `profile_version` 2.0.0.

---

## Why a wrong manifest is hard to notice

Three compounding reasons:

1. **Node kinds are grammar-specific.** Ruby says `method`, Rust
   `function_item`, Lua `function_declaration`. Lua has `function_call`, *not*
   `call_expression`. Copying kinds between languages produces a manifest that
   loads cleanly and does nothing.
2. **Unknown profile keys are ignored**, by design.
3. **Two of three fields degrade rather than fail**, so partial correctness
   looks like success.

### Always validate

```bash
codemark languages validate
```

```
Found issues with installed grammars:
  - .../lua: error: profile.landmark_kinds[1]: node kind 'function_item' is not
    defined by this grammar, so it can never match

Warnings (these grammars still work):
  - .../lua: warning: profile.containers: no containers, so this language
    produces no breadcrumbs
```

**Errors** mean that entry can never match; they also block an install, so a bad
profile can't replace a working grammar. **Warnings** are advisory. Close misses
get a suggestion (`'local_function_declaration' … did you mean
'function_declaration'?`).

**What `validate` can't check:** Tree-sitter exposes field names globally rather
than per node kind, so `["mod_item", "value"]` — a real field, but not one
`mod_item` has — passes. Harmless today given the field is unread, but a clean
`validate` isn't proof the pair is right.

### And confirm breadcrumbs separately

Because `containers` fails silently, validation alone isn't enough. That's what
`scripts/verify.sh` is for: it bookmarks nested lines and diffs the resulting
breadcrumbs against a committed snapshot. Deleting a `containers` entry passes
the lint, installs, validates, and produces a *byte-identical query* — only the
snapshot catches it.

---

## Language-specific gotchas seen so far

Real cases from profiles in this repo, worth reading before authoring a new one:

| Language | Gotcha |
|---|---|
| **Lua** | `function_call`, not `call_expression`; no `local_function_declaration` at all. An early hand-written profile used both and silently produced no breadcrumbs. |
| **Ruby** | Declarations are bare words (`class`, `module`, `method`) with no `_declaration` suffix. Anything deriving kinds from naming conventions misses them. |
| **PHP** | `namespace X;` (semicolon form) doesn't enclose anything in the AST, so it can never appear in a breadcrumb. The braced form does. The repo also publishes two grammars from subdirectories, so its index entry needs `grammar_dir` and names one of two wasm assets. |
| **Zig** | A struct is an anonymous value bound by the enclosing `variable_declaration`, so `struct_declaration` has no name field. It is still a valid container — it sticks while you scroll, and the breadcrumb renderer skips it. |
| **Scala** | Identical sibling statements make the generated query ambiguous and codemark refuses the bookmark — a sample-authoring constraint, not a profile defect. |
| **Kotlin** | The grammar declares *no field names at all*, so no `containers` entry is possible. See [NOT-YET-SUPPORTED.md](NOT-YET-SUPPORTED.md). |
| **Elixir** | `defmodule`/`def` are macro calls, so every declaration is the same node kind. Not expressible in this schema. See [NOT-YET-SUPPORTED.md](NOT-YET-SUPPORTED.md). |

---

## Related

- [CONTRIBUTING.md](CONTRIBUTING.md) — how to add a profile
- [NOT-YET-SUPPORTED.md](NOT-YET-SUPPORTED.md) — grammars evaluated and set aside
- [`grammars/lua/manifest.json`](grammars/lua/manifest.json) — a verified reference manifest
- The codemark repo's `dev-docs/guides/manifest-anatomy.md` — the same material
  with implementation detail, for codemark contributors
