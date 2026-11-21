# JSON

| | |
|---|---|
| Grammar | https://github.com/tree-sitter/tree-sitter-json |
| Revision | `v0.24.8` |
| Built with | tree-sitter CLI 0.24 (prebuilt release asset) |
| Profile version | 1.0.0 |

## Verified against

```bash
curl -fsSL -o json.wasm \
  https://github.com/tree-sitter/tree-sitter-json/releases/download/v0.24.8/tree-sitter-json.wasm
codemark languages add ./json.wasm --from-registry json
```

SHA-256 `d2119fb98d5912719b13f9458574f8608d2d29dfbe45f6be1f860ea1fe2a2405`.

Needs a codemark that names a `pair` by its `key` (see below). An older one
installs and validates this profile cleanly, then refuses almost every nested
line as an ambiguous query.

## Notes on this grammar

JSON has no declarations, so `languages profile init` proposes an **empty**
profile: it only promotes kinds it sees wrapping a declaration. The whole
profile is therefore curation, recorded in the manifest.

The structure a reader navigates by is the key path, and `pair` is the only
kind with a name — in its `key` field, not `name`. So `pair` is the one
landmark, labelled `variable` (the closest shared concept for a named value),
and that label is the one container. A bookmark on `customer.address.city`
gets the trail `"customer": {` › `"address": {`.

`object` and `array` are left out on purpose: both are anonymous values, so
they add no name to a breadcrumb and would only add anchors between the keys.

### What codemark had to learn

Two generator changes were needed before this profile did anything useful:

- **Name a `pair` by its key.** The generator read names from a `name` field
  only, so every pair was nameless and every query purely structural —
  `customer.address.city` and `totals.tax.rate` produced patterns of the same
  shape, and nearly every nested line was refused as ambiguous. A string key
  is matched on its content (`city`, not `"city"`).
- **Don't let a trailing comma widen the target.** A pair stops before its
  separator comma, so a whole-line selection of `"city": "Springfield",` used
  to resolve to the enclosing object. The comma is now trimmed when that lands
  on a node with a name.

## Known limitation

Objects inside an array are anonymous, so a key that every element shares
(`lines[0].sku` vs `lines[1].sku`) has no path that tells them apart, and
codemark refuses the bookmark. This is the same identical-siblings limitation
recorded for Scala. A key unique to one element (`lines[1].discount`) works.
`samples/invoice.json.lines` records two refused lines rather than omitting
them.

`.jsonc` and other JSON-with-comments extensions aren't registered, though
the grammar parses `//` and `/* */` comments.
