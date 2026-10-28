# Languages evaluated but not added

Grammars that were tried and set aside, with the reason. Recorded so the next
person doesn't repeat the work — and so these can be revisited if the grammar
or codemark changes.

## Kotlin — the grammar declares no field names

[`fwcd/tree-sitter-kotlin`](https://github.com/fwcd/tree-sitter-kotlin) @ `0.3.8`
loads and parses fine, but exposes **zero** named fields:

```
class_declaration []
  type_identifier []
  class_body []
    function_declaration []
```

`containers` is a `(node_kind, name_field)` pair, so with no fields there is no
valid entry to write — `codemark languages validate` correctly rejects
`["class_declaration", "name"]` because `name` isn't a field anywhere in the
grammar. Landmarks alone would still give structural anchoring, but no
breadcrumbs.

**Revisit if:** the grammar adds field names, another Kotlin grammar does, or
breadcrumbs learn to fall back to positional child lookup.

## Elixir — declarations are macros, not node kinds

[`elixir-lang/tree-sitter-elixir`](https://github.com/elixir-lang/tree-sitter-elixir) @ `v0.3.5`
parses correctly, but `defmodule`, `def` and `defp` are ordinary macro
invocations rather than distinct node kinds. The AST is almost entirely `call`
and `do_block`:

```
call [target=identifier]        # this is `defmodule`
  arguments []
  do_block []
    call [target=identifier]    # this is `def`
```

Every declaration is the same kind, so `landmark_kinds` can't distinguish a
module from a function from a `Enum.reduce` call. A useful Elixir profile would
need matching on the *call target's text*, which the `Profile` schema doesn't
express.

**Revisit if:** `Profile` grows a predicate for call-target names, or a
different Elixir grammar models declarations structurally.
