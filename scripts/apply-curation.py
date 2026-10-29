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


def apply(generated: dict, curation: dict) -> dict:
    """Return `generated` with `curation` applied. Order is fixed so the result
    is deterministic regardless of how the curation block is written."""
    profile = {
        "landmark_kinds": list(generated.get("landmark_kinds", [])),
        "node_labels": dict(generated.get("node_labels", {})),
        "containers": [list(c) for c in generated.get("containers", [])],
    }

    # Drops first: a kind removed from landmarks should also lose its label and
    # any container entry, so a curation block doesn't have to repeat itself.
    drop = set(curation.get("drop_landmarks", []))
    if drop:
        profile["landmark_kinds"] = [k for k in profile["landmark_kinds"] if k not in drop]
        profile["node_labels"] = {k: v for k, v in profile["node_labels"].items() if k not in drop}
        profile["containers"] = [c for c in profile["containers"] if c[0] not in drop]

    for kind in curation.get("drop_labels", []):
        profile["node_labels"].pop(kind, None)

    for pair in curation.get("drop_containers", []):
        profile["containers"] = [c for c in profile["containers"] if c != list(pair)]

    # Then additions.
    for kind in curation.get("add_landmarks", []):
        if kind not in profile["landmark_kinds"]:
            profile["landmark_kinds"].append(kind)

    for kind, label in curation.get("add_labels", {}).items():
        profile["node_labels"][kind] = label

    for pair in curation.get("add_containers", []):
        if list(pair) not in profile["containers"]:
            profile["containers"].append(list(pair))

    profile["landmark_kinds"].sort()
    profile["containers"].sort()
    return profile


def normalized(profile: dict) -> dict:
    """Compare on content, not on ordering or absent-vs-empty."""
    return {
        "landmark_kinds": sorted(profile.get("landmark_kinds", [])),
        "node_labels": dict(sorted(profile.get("node_labels", {}).items())),
        "containers": sorted([list(c) for c in profile.get("containers", [])]),
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
