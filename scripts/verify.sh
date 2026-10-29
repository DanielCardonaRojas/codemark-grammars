#!/usr/bin/env bash
#
# Verify one grammar's curated profile against the grammar it targets.
#
# A profile is a set of tree-sitter node kinds and field names. Nothing about a
# JSON file says whether those kinds exist, and a wrong one fails *silently* —
# `landmark_kinds` falls back to a built-in union, and `containers` just produces
# no breadcrumb. So reviewing a profile by eye proves very little. This script is
# what makes a profile verified rather than merely reviewed:
#
#   1. build the grammar's .wasm at the pinned revision (ABI 0.25)
#   2. install it with this repo's profile
#   3. `codemark languages validate` — must be lint-clean
#   3b. regenerate the profile from the samples, apply the manifest's recorded
#      curation, and confirm it reproduces the committed profile
#   4. bookmark each sample's marked lines and compare against committed
#      snapshots of the query, resolution method and breadcrumbs
#
# Step 4 is the part that catches a profile that loads but does nothing.
#
# Usage:
#   scripts/verify.sh <language> [--update]
#
#   --update  rewrite the committed snapshots instead of comparing (use when a
#             profile change is intentional; review the diff before committing)

set -euo pipefail

LANG_NAME="${1:-}"
UPDATE="${2:-}"

if [[ -z "$LANG_NAME" ]]; then
  echo "usage: scripts/verify.sh <language> [--update]" >&2
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LANG_DIR="$REPO_ROOT/grammars/$LANG_NAME"
CODEMARK="${CODEMARK:-codemark}"

[[ -d "$LANG_DIR" ]] || { echo "no such grammar: $LANG_NAME" >&2; exit 2; }

# --- read the pinned grammar revision from the index -------------------------

read_index_field() {
  python3 - "$REPO_ROOT/index.json" "$LANG_NAME" "$1" <<'PY'
import json, sys
index, name, field = sys.argv[1], sys.argv[2], sys.argv[3]
for e in json.load(open(index))["grammars"]:
    if e["name"] == name:
        print(e.get(field) or "")
        break
else:
    sys.exit(f"{name} is not in index.json")
PY
}

GRAMMAR_REPO="$(read_index_field grammar_repo)"
GRAMMAR_REV="$(read_index_field grammar_rev)"
# Subdirectory holding `grammar.js`, for repos that publish several grammars.
# tree-sitter-php keeps them in `php/` and `php_only/` and has nothing at the
# root, so building from the clone root fails with "Failed to load grammar.js".
GRAMMAR_DIR="$(read_index_field grammar_dir)"

[[ -n "$GRAMMAR_REPO" ]] || { echo "index.json: $LANG_NAME has no grammar_repo" >&2; exit 2; }
[[ -n "$GRAMMAR_REV" ]]  || { echo "index.json: $LANG_NAME has no grammar_rev" >&2; exit 2; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# --- 1. build the .wasm at the pinned revision -------------------------------
#
# Pinned because a profile is only valid against the grammar revision it was
# authored against: node kinds change between grammar versions, and a renamed
# kind turns a working profile into a silent no-op.

WASM="${WASM_OVERRIDE:-}"
if [[ -z "$WASM" ]]; then
  echo "==> building $LANG_NAME grammar at $GRAMMAR_REV"
  git clone --quiet --depth 1 --branch "$GRAMMAR_REV" "$GRAMMAR_REPO" "$WORK/grammar"
  BUILD_DIR="$WORK/grammar${GRAMMAR_DIR:+/$GRAMMAR_DIR}"
  [[ -f "$BUILD_DIR/grammar.js" ]] || {
    echo "no grammar.js in ${GRAMMAR_DIR:-the repository root} — set \`grammar_dir\` in index.json" >&2
    echo "candidates:" >&2
    find "$WORK/grammar" -name grammar.js -not -path '*/node_modules/*' -maxdepth 3 >&2
    exit 1
  }
  # Most grammars commit the generated `src/parser.c`, but not all:
  # tree-sitter-swift ships only `grammar.js` and `src/scanner.c` and expects
  # the parser to be generated. `tree-sitter build --wasm` assumes parser.c is
  # already present and fails with a bare "parser.c: No such file or directory".
  #
  # Generating only when it is missing keeps the committed-parser case building
  # from exactly the bytes the grammar authors published.
  if [[ ! -f "$BUILD_DIR/src/parser.c" ]]; then
    echo "==> no src/parser.c committed, running tree-sitter generate"
    ( cd "$BUILD_DIR" && tree-sitter generate )
  fi

  ( cd "$BUILD_DIR" && tree-sitter build --wasm )
  WASM="$(find "$BUILD_DIR" -maxdepth 1 -name '*.wasm' | head -1)"
  [[ -n "$WASM" ]] || { echo "tree-sitter build --wasm produced no .wasm" >&2; exit 1; }
fi

# --- 2. install using this repo as the registry ------------------------------
#
# Installing through `--from-registry` against this checkout means CI exercises
# the same path a user takes, including the index wiring, rather than just
# copying a manifest into place.

export CODEMARK_GRAMMARS_DIR="$WORK/grammars"
export CODEMARK_GRAMMAR_REGISTRY="$REPO_ROOT"
mkdir -p "$CODEMARK_GRAMMARS_DIR"

# A codemark without `--from-registry` can't verify anything here, and clap's
# "unexpected argument" is a confusing way to learn that.
if ! "$CODEMARK" languages add --help 2>&1 | grep -q -- '--from-registry'; then
  cat >&2 <<MSG
This codemark has no \`languages add --from-registry\`, which this harness needs.

  codemark: $CODEMARK

Build one from a revision that includes the grammar registry, or set CODEMARK
to point at it.
MSG
  exit 2
fi

# An entry that replaces a codemark built-in needs `--override-builtin`;
# without it the install is refused. Passing it unconditionally would hide a
# genuine collision for a language that *isn't* meant to override one, so only
# add it when the index says this entry is deliberately an override.
OVERRIDE_FLAG=()
if [[ "$(read_index_field overrides_builtin)" == "True" ]]; then
  OVERRIDE_FLAG=(--override-builtin)
fi

echo "==> installing $LANG_NAME with this repo's profile"
"$CODEMARK" languages add "$WASM" --from-registry "$LANG_NAME" "${OVERRIDE_FLAG[@]}" >/dev/null

# --- 3. the profile must be lint-clean ---------------------------------------
#
# `validate` checks every node kind and container field against the loaded
# grammar. An error means that part of the profile can never match.

echo "==> validating"
"$CODEMARK" languages validate > "$WORK/validate.json"
python3 - "$WORK/validate.json" <<'PY'
import json, sys
v = json.load(open(sys.argv[1]))["data"]
for w in v.get("warnings", []):
    print("  warning:", w)
if not v["valid"]:
    for i in v["issues"]:
        print("  ERROR:", i)
    sys.exit("profile is not valid for this grammar")
print("  profile is valid")
PY

# --- 3b. the profile must be reproducible from the samples -------------------
#
# The committed profile is generated output plus human curation. Without this
# check the two are connected only by memory: a sample change that alters the
# proposal leaves the manifest quietly stale, and nothing distinguishes
# deliberate curation from drift.
#
# Needs a codemark built with --features profile-authoring. Skipping is allowed
# for a local run against a stock binary, but in CI it is a failure: the check
# skipped itself silently on every run for its first day of life, which defeats
# the point of having it. Set REQUIRE_REPRODUCIBLE=0 to downgrade to a warning.

REQUIRE_REPRODUCIBLE="${REQUIRE_REPRODUCIBLE:-${CI:-0}}"

if "$CODEMARK" languages profile --help >/dev/null 2>&1; then
  echo "==> checking the profile is reproducible from samples + curation"
  GEN_ARGS=()
  for sample in "$LANG_DIR"/samples/*; do
    [[ "$sample" == *.lines ]] && continue
    GEN_ARGS+=(--sample "$sample")
  done
  "$CODEMARK" languages profile init "$WASM" "${GEN_ARGS[@]}" \
    --name "$LANG_NAME" > "$WORK/generated.json"
  python3 "$REPO_ROOT/scripts/apply-curation.py" \
    "$WORK/generated.json" "$LANG_DIR/manifest.json" --check
elif [[ "$REQUIRE_REPRODUCIBLE" != "0" && "$REQUIRE_REPRODUCIBLE" != "false" ]]; then
  cat >&2 <<MSG
This codemark has no \`languages profile init\`, so the profile cannot be
checked for reproducibility — and this run requires it.

  codemark: $CODEMARK

Build it with \`--features profile-authoring\`, or set REQUIRE_REPRODUCIBLE=0
to downgrade this to a warning.
MSG
  exit 2
else
  echo "==> skipping reproducibility check (no profile-authoring build)"
fi

# --- 4. compare against the committed snapshots ------------------------------
#
# Each sample has a `.lines` file listing the 1-based lines to bookmark. A line
# is chosen to sit *inside* a construct the profile claims to understand, so a
# broken `containers` shows up as a missing breadcrumb rather than passing
# unnoticed.

REPO="$WORK/repo"
mkdir -p "$REPO"
cp "$LANG_DIR"/samples/* "$REPO/"
( cd "$REPO" && git init -q . && git add -A \
    && git -c user.email=ci@example.com -c user.name=ci commit -qm fixture )

( cd "$REPO" && "$CODEMARK" init >/dev/null 2>&1 )

ACTUAL="$WORK/actual.json"
echo "[]" > "$ACTUAL"

for sample in "$LANG_DIR"/samples/*; do
  base="$(basename "$sample")"
  [[ "$base" == *.lines ]] && continue
  lines_file="$sample.lines"
  [[ -f "$lines_file" ]] || { echo "missing $lines_file (one 1-based line per entry)" >&2; exit 2; }

  while read -r line; do
    [[ -z "$line" || "$line" == \#* ]] && continue
    ( cd "$REPO" && "$CODEMARK" add --file "$base" --range "$line" ) > "$WORK/add.json"
    id="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["data"]["id"])' "$WORK/add.json")"
    ( cd "$REPO" && "$CODEMARK" show "$id" ) > "$WORK/show.json"

    # Keep only what the profile determines. Ids, hashes and timestamps vary per
    # run and would make every snapshot a false failure. Read the CLI output
    # from a file rather than interpolating it into the script: a query contains
    # newlines and quotes that would not survive inlining.
    python3 - "$ACTUAL" "$base" "$line" "$WORK/show.json" <<'PY'
import json, sys
path, sample, line, shown = sys.argv[1:5]
data = json.load(open(shown))["data"]
bm = data["bookmark"]
res = (data.get("resolutions") or [{}])[0]
crumbs = res.get("breadcrumbs")
entries = json.load(open(path))
entries.append({
    "sample": sample,
    "line": int(line),
    "query": bm["query"],
    "resolution_method": bm.get("resolution_method"),
    # Empty breadcrumbs are a legitimate expected value (a landmark with no
    # name field can't be a container), so they are pinned rather than skipped.
    "breadcrumbs": json.loads(crumbs) if crumbs else [],
})
json.dump(entries, open(path, "w"), indent=2, sort_keys=True)
PY
  done < "$lines_file"
done

SNAPSHOT="$LANG_DIR/expected/bookmarks.json"

if [[ "$UPDATE" == "--update" ]]; then
  cp "$ACTUAL" "$SNAPSHOT"
  echo "==> updated $SNAPSHOT"
  exit 0
fi

[[ -f "$SNAPSHOT" ]] || { echo "no snapshot at $SNAPSHOT — run with --update" >&2; exit 2; }

echo "==> comparing against $SNAPSHOT"
if diff -u "$SNAPSHOT" "$ACTUAL"; then
  echo "==> $LANG_NAME OK"
else
  cat >&2 <<'MSG'

The profile no longer produces the committed results.

An empty "breadcrumbs" usually means `containers` names a node kind or a
name-field this grammar does not have — it fails silently at runtime, which is
exactly what this snapshot exists to catch.

If the change is intentional, re-run with --update and review the diff.
MSG
  exit 1
fi
