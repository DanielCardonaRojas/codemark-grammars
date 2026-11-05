# Java

| | |
|---|---|
| Grammar | https://github.com/tree-sitter/tree-sitter-java |
| Revision | `v0.23.5` |
| Built with | tree-sitter CLI 0.25 (prebuilt release asset) |
| Profile version | 2.0.0 |

## Verified against

```bash
curl -fsSL -o java.wasm \
  https://github.com/tree-sitter/tree-sitter-java/releases/download/v0.23.5/tree-sitter-java.wasm
codemark languages install java
```

SHA-256 `4fdeac4ca6ca089f06c6f7e562abcac1733cd465728cc7031ebb73c2019122c4`
(414,641 bytes).

A `.wasm` you build yourself will differ byte-for-byte (emscripten output isn't
reproducible) but should verify identically — node kinds come from the grammar
revision, not the build.

## What this adds over the built-in

The landmark set is a strict superset of the built-in Java profile's. The
additions that matter:

- **`record_declaration`** — a Java 16+ record is a declaration the built-in
  doesn't know about at all, so it could never be anchored. Labelled `class`.
- **`constructor` as a container** — the built-in labels
  `constructor_declaration` but doesn't list `constructor` among its
  containers, so a bookmark inside a constructor showed the class and skipped
  the constructor. The snapshot for line 157 pins the fix.
- **`enum_constant`** — a Java enum constant can carry a class body with
  overridden methods, so it genuinely contains declarations.
- **`lambda_expression`** and **`annotation_type_declaration`**.

## Notes

**Annotated methods render their annotation, not their signature.** This is
the one rough edge. `modifiers` is a *child* of `method_declaration`, so an
`@Override` method's node starts on the annotation line — and because
`extract_breadcrumbs` renders a node's first source line, the breadcrumb reads
`@Override` rather than `public double total() {`. Python avoided this by
dropping `decorated_definition`, which is a separate wrapper node; here the
annotation is *inside* the declaration, so no profile change can express it.
The chosen sample lines sit in un-annotated methods so the committed trails
stay informative, but a real bookmark inside an annotated method will show the
annotation. Fixing it properly means teaching the breadcrumb renderer to skip
leading `modifiers`, which is a codemark change, not a profile one.

**There is no `switch_statement` node kind.** tree-sitter-java parses a
`switch` in statement position as a `switch_expression`. Writing
`"switch_statement": "match"` — the name that reads naturally — is a hard lint
error (`node kind 'switch_statement' is not defined by this grammar, so it can
never match`), which is how this was caught. The profile labels `switch_block`
and `switch_expression` instead.

**`method_invocation` was the significant false positive.** At 8 occurrences it
was promoted as a landmark *and* labelled `method` — which is a container — so
every `foo.bar()` call site would have entered a breadcrumb trail as though it
were a method declaration. Relabelled `call`, which is what the built-in does.
`object_creation_expression` (`new Invoice(...)`) is labelled `call` for the
same reason.

**`field_declaration` and `local_variable_declaration` matched on a
`declarator` field**, not a name: the identifier lives one level down in a
`variable_declarator`, so what the generator found was the whole declarator.
Dropped as landmarks, kept as `variable` labels.

**`enum_body_declarations` is the body wrapper** holding an enum's members
after its constants — the role C#'s `declaration_list` and Python's `block`
play. Dropped; the `enum_declaration` that owns it is the real landmark.

**Ambiguous anchors are common in Java.** `this.x = y;` and
`return "literal";` are such frequent shapes that several otherwise-obvious
sample lines generate a query matching three nodes and are refused outright.
The `.lines` file records which ones and why.

The only extension is `java`.
