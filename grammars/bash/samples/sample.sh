#!/usr/bin/env bash
#
# Idiomatic Bash exercising the constructs this profile claims to understand.
#
# Authored for this repo. Construct coverage was cross-checked against
# tree-sitter-bash's own test/corpus topics (commands, statements, literals,
# programs) — read as a checklist, not copied.
#
# Bash has no type or module layer, so a breadcrumb trail here is at most
# `function > control flow`. That is the language's ceiling, not a profile gap:
# `function_definition` is the only kind that can ever be a container. What this
# sample must therefore prove is that every control-flow kind is *labelled* and
# that none of them is wrongly promoted to a landmark.

set -euo pipefail

readonly DEFAULT_TARGET="dist"
readonly TAX_RATE=12

declare -a FAILED_UNITS=()
declare -A RETRY_BUDGET=([upload]=3 [verify]=1)

log() {
  local level="$1"
  shift
  printf '[%s] %s\n' "$level" "$*" >&2
}

# A function wrapping a conditional and a case — two distinct statement kinds
# nested one level inside a declaration.
resolve_target() {
  local requested="${1:-}"

  if [[ -z "$requested" ]]; then
    log warn "no target given, defaulting to $DEFAULT_TARGET"
    requested="$DEFAULT_TARGET"
  elif [[ ! -d "$requested" ]]; then
    log error "target $requested does not exist"
    return 1
  fi

  # Each branch is given a different shape on purpose: identical sibling
  # statements make the generated structural query ambiguous and codemark
  # refuses the bookmark. A sample-authoring constraint, not a profile defect.
  case "$requested" in
    dist | build)
      printf '%s\n' "$requested"
      ;;
    stage-*)
      local suffix="${requested#stage-}"
      printf 'staging/%s\n' "$suffix"
      ;;
    *)
      log error "unrecognised target shape: $requested"
      return 2
      ;;
  esac
}

# A function whose body holds a for loop containing a conditional — the deepest
# nesting Bash's grammar allows a breadcrumb to describe.
upload_artifacts() {
  local target="$1"
  local uploaded=0

  for artifact in "$target"/*.tar.gz; do
    if [[ ! -r "$artifact" ]]; then
      FAILED_UNITS+=("$artifact")
      continue
    fi

    log info "uploading $(basename "$artifact")"
    uploaded=$((uploaded + 1))
  done

  printf '%d\n' "$uploaded"
}

# A while loop reading from a process substitution, plus an until loop — the
# two remaining loop kinds the profile labels.
verify_checksums() {
  local manifest="$1"
  local checked=0

  while read -r expected path; do
    local actual
    actual="$(shasum -a 256 "$path" | awk '{print $1}')"

    [[ "$actual" == "$expected" ]] || {
      log error "checksum mismatch for $path"
      return 1
    }

    checked=$((checked + 1))
  done < <(grep -v '^#' "$manifest")

  local attempt=0
  until ((attempt >= RETRY_BUDGET[verify])); do
    attempt=$((attempt + 1))
  done

  printf '%d\n' "$checked"
}

# Arithmetic, parameter expansion and command substitution in one place.
apply_tax() {
  local cents="$1"
  printf '%d\n' "$((cents + (cents * TAX_RATE) / 100))"
}

main() {
  local target
  target="$(resolve_target "${1:-}")" || return $?

  local count
  count="$(upload_artifacts "$target")"
  log info "uploaded $count artifact(s)"

  if ((${#FAILED_UNITS[@]} > 0)); then
    log warn "skipped: ${FAILED_UNITS[*]}"
  fi

  log info "total with tax: $(apply_tax 1000)"
}

main "$@"
