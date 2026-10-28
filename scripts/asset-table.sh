#!/usr/bin/env bash
#
# Print the "Where each .wasm came from" table for README.md.
#
# Resolves each index entry's `grammar_repo` + `grammar_rev` to the `.wasm`
# release asset, downloads it, and reports its URL, SHA-256 and size. Run this
# after adding a language (or after re-pinning a revision) and paste the output
# into README.md, so the provenance table can't drift from the index.
#
# A language whose release has no `.wasm` asset is reported as "built from
# source" rather than silently skipped — that is useful information too.
#
# Usage: scripts/asset-table.sh

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

command -v gh >/dev/null || { echo "needs the gh CLI" >&2; exit 2; }

python3 - "$REPO_ROOT/index.json" > "$WORK/entries" <<'PY'
import json, sys
for g in json.load(open(sys.argv[1]))["grammars"]:
    repo = g["grammar_repo"].removeprefix("https://github.com/")
    print(f"{g['name']}|{repo}|{g.get('grammar_rev','')}")
PY

echo "| Language | Download | SHA-256 | Size |"
echo "|---|---|---|---|"

while IFS='|' read -r name repo rev; do
  [[ -z "$rev" ]] && { echo "| $name | _no pinned revision_ | — | — |"; continue; }

  url=$(gh api "repos/$repo/releases/tags/$rev" \
        --jq '.assets[]|select(.name|endswith(".wasm")).browser_download_url' 2>/dev/null | head -1)

  if [[ -z "$url" ]]; then
    echo "| $name | _no \`.wasm\` asset at \`$rev\` — build from source_ | — | — |"
    continue
  fi

  curl -fsSL -o "$WORK/$name.wasm" "$url"
  sha=$(shasum -a 256 "$WORK/$name.wasm" | cut -d' ' -f1)
  bytes=$(wc -c < "$WORK/$name.wasm" | tr -d ' ')
  size=$(python3 -c "b=$bytes; print(f'{b/1048576:.2f} MB' if b>=1048576 else f'{b//1024} KB')")
  asset=${url##*/}

  echo "| $name | [\`$asset\` @ $rev]($url) | \`${sha:0:16}…\` | $size |"
done < "$WORK/entries"
