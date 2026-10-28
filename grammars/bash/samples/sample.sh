#!/usr/bin/env bash
# Sample Bash exercising functions, conditionals and loops.
set -euo pipefail

TARGET="${1:-dist}"

deploy() {
  local target="$1"
  if [ -z "$target" ]; then
    echo "no target given" >&2
    return 1
  fi
  for f in "$target"/*; do
    echo "shipping $f"
  done
}

cleanup() {
  while read -r stale; do
    rm -f "$stale"
  done < /tmp/stale.txt
}

deploy "$TARGET"
