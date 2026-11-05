# Swift

| | |
|---|---|
| Grammar | https://github.com/alex-pinkus/tree-sitter-swift |
| Revision | `0.7.3` |
| Built with | tree-sitter CLI 0.25 (prebuilt release asset) |
| Profile version | 2.1.0 |

## Verified against

```bash
codemark languages install swift
```

## Built into codemark before 0.8.0

Codemark compiled a Swift grammar in until 0.8.0, which moved it to this
registry (codemark#278); since then Dart is the only built-in grammar.
On codemark 0.8.0 and later this is an ordinary registry entry. On an older
codemark it **replaces** the built-in instead, which needs
`--override-builtin` on a manual `add`; the index marks it with
`"overrides_builtin": true` so `languages install` and the verification
harness pass the flag.

It was 3.24 MB of a 24.2 MB binary, the second largest of the eight.

## Notes

`class_body` and `enum_class_body` were dropped from the generated landmarks:
both are `{ }` wrappers, not declarations.

`function_declaration` and `init_declaration` were added to `containers` by
hand — the generator only proposes a container for a kind it *observes* wrapping
another declaration, and in this sample those hold only statements.

The sample covers an `extension`, which is a container Swift uses heavily and
which sits outside the class body: a bookmark there resolves to
`extension Invoice: Payable > func pay(...)`.

`enum_entry` is a landmark labelled `enum`, and `enum` is a container, matching
the built-in profile codemark shipped before 0.8.0. The generator can't propose
it: a `case` has no body. This grammar parses `enum` itself as a
`class_declaration`, so the `enum` container resolves only to `enum_entry` and
keeps a `case` line in the trail. `subscript_declaration` is labelled
`subscript` and `while_statement` `while loop`, also as in the built-in.
