#!/usr/bin/env python3
"""Apply a manifest's recorded curation to a freshly generated profile.

The generator proposes a profile from parsed samples; a human then removes
noise (`{ }` body wrappers, control flow that matched on a `type` field) and
adds containers the samples don't happen to nest. Until now that editing was
invisible: regenerating gave a different profile than the one committed, and
nothing could tell curation from staleness.

Recording it in the manifest makes the committed profile *reproducible*:

    generated(samples) + curation == committed profile

`verify.sh` asserts exactly that, so a sample change that alters the profile
fails loudly instead of leaving the manifest quietly out of date.

Usage:
    apply-curation.py <generated.json> <manifest.json>   # prints curated profile
    apply-curation.py <generated.json> <manifest.json> --check
"""

import json
import sys


def container_entries(raw) -> list:
    """Normalize `containers` to a list of label strings.

    Accepts both shapes. The concept form is a list of labels; the legacy form
    is a list of `[kind, name_field]` pairs, which is kept as a one-element
    tuple so a part-migrated manifest round-trips rather than silently losing
    the kind.

    Written defensively because the obvious `[list(c) for c in raw]` explodes a
    label string into its characters — `"function"` becomes
    `["f", "u", "n", ...]` — which is exactly what happened on the first run of
    this migration.
    """
    out = []
    for entry in raw or []:
        if isinstance(entry, str):
            out.append(entry)
        elif isinstance(entry, (list, tuple)) and entry:
            # Legacy pair: keep only the kind, as codemark does.
            out.append([entry[0]])
    return out


def apply(generated: dict, curation: dict) -> dict:
    """Return `generated` with `curation` applied. Order is fixed so the result
    is deterministic regardless of how the curation block is written."""
    profile = {
        "landmark_kinds": list(generated.get("landmark_kinds", [])),
        "node_labels": dict(generated.get("node_labels", {})),
        "containers": container_entries(generated.get("containers")),
    }

    def label_of(kind):
        return profile["node_labels"].get(kind)

    # Drops first: a kind removed from landmarks should also lose its label, so
    # a curation block doesn't have to repeat itself.
    #
    # Dropping a landmark no longer implies dropping a container: a container is
    # a *label*, and several kinds can share one. Removing `foreach_statement`
    # must not take `class` with it just because both were proposed. A label is
    # removed only when no remaining kind carries it.
    drop = set(curation.get("drop_landmarks", []))
    if drop:
        profile["landmark_kinds"] = [k for k in profile["landmark_kinds"] if k not in drop]
        dropped_labels = {label_of(k) for k in drop if label_of(k)}
        profile["node_labels"] = {k: v for k, v in profile["node_labels"].items() if k not in drop}
        still_used = set(profile["node_labels"].values())
        orphaned = {lbl for lbl in dropped_labels if lbl not in still_used}
        profile["containers"] = [c for c in profile["containers"] if c not in orphaned]

    for kind in curation.get("drop_labels", []):
        profile["node_labels"].pop(kind, None)

    for label in curation.get("drop_containers", []):
        # Accept a bare label or a legacy pair, so an un-migrated curation block
        # keeps working while a manifest is in flight.
        target = label[0] if isinstance(label, (list, tuple)) else label
        profile["containers"] = [
            c for c in profile["containers"] if c != target and c != [target]
        ]

    # Then additions.
    for kind in curation.get("add_landmarks", []):
        if kind not in profile["landmark_kinds"]:
            profile["landmark_kinds"].append(kind)

    for kind, label in curation.get("add_labels", {}).items():
        profile["node_labels"][kind] = label

    for label in curation.get("add_containers", []):
        target = label[0] if isinstance(label, (list, tuple)) else label
        if target not in profile["containers"]:
            profile["containers"].append(target)

    profile["landmark_kinds"].sort()
    profile["containers"].sort(key=lambda c: c if isinstance(c, str) else c[0])
    return profile


def normalized(profile: dict) -> dict:
    """Compare on content, not on ordering or absent-vs-empty."""
    conts = container_entries(profile.get("containers"))
    return {
        "landmark_kinds": sorted(profile.get("landmark_kinds", [])),
        "node_labels": dict(sorted(profile.get("node_labels", {}).items())),
        "containers": sorted(conts, key=lambda c: c if isinstance(c, str) else c[0]),
    }


def main() -> int:
    if len(sys.argv) < 3:
        sys.exit(__doc__)

    gen_path, manifest_path = sys.argv[1], sys.argv[2]
    check = "--check" in sys.argv[3:]

    generated = json.load(open(gen_path))
    # `profile init --json` wraps the manifest; a bare profile is also accepted.
    if "data" in generated:
        generated = generated["data"]["manifest"]["profile"]
    elif "profile" in generated:
        generated = generated["profile"]

    manifest = json.load(open(manifest_path))
    curated = apply(generated, manifest.get("curation", {}))

    if not check:
        print(json.dumps(curated, indent=2, sort_keys=True))
        return 0

    want, got = normalized(manifest.get("profile", {})), normalized(curated)
    if want == got:
        print("  profile is reproducible from samples + curation")
        return 0

    print("The committed profile is not reproducible from the samples.\n", file=sys.stderr)
    for field in ("landmark_kinds", "containers"):
        w = [json.dumps(x) for x in want[field]]
        g = [json.dumps(x) for x in got[field]]
        for extra in sorted(set(w) - set(g)):
            print(f"  committed has {field} {extra}, regeneration does not", file=sys.stderr)
            print("    -> add it to curation.add_*, or it is stale", file=sys.stderr)
        for extra in sorted(set(g) - set(w)):
            print(f"  regeneration produces {field} {extra}, committed does not", file=sys.stderr)
            print("    -> add it to curation.drop_*, or re-run with --update", file=sys.stderr)

    wl, gl = want["node_labels"], got["node_labels"]
    for k in sorted(set(wl) | set(gl)):
        if wl.get(k) != gl.get(k):
            print(f"  node_labels[{k}]: committed={wl.get(k)!r} regenerated={gl.get(k)!r}", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
