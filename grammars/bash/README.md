# Bash

| | |
|---|---|
| Grammar | https://github.com/tree-sitter/tree-sitter-bash |
| Revision | `v0.25.1` |
| Built with | tree-sitter CLI 0.25 (prebuilt release asset) |
| Profile version | 1.0.0 |

## Notes

Bash has one container kind: `function_definition`. There is no class or module
layer, so breadcrumbs are a single level — that is correct, not a gap.

`declaration_command` (`local`, `declare`, `export`) is a landmark so those
bindings can be bookmarked, but it is not a container: it holds no nested
declarations.
