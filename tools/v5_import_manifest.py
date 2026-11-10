#!/usr/bin/env python3
"""Import manifest: compare an extracted source archive against a git checkout.

Emits a JSON manifest with, for every archive file:
  - SAME      : byte-identical to the checkout
  - DIFFERENT : present in both, contents differ
  - NEW       : present in the archive, absent from the checkout
and, for every checkout file absent from the archive:
  - MISSING   : would be deleted by a naive copy (informational only)

The manifest is the input to a whitelist import: only NEW/DIFFERENT files are
copied, so canon content (levels/**, data/canon/**) is never silently replaced.

Usage:
  python tools/v5_import_manifest.py --archive <dir> --repo <dir> --out <json>
"""

import argparse
import hashlib
import json
import os
import sys

SKIP_TOP = {".git", ".godot", "__pycache__"}
SKIP_EXT = {".pyc", ".zip", ".exe", ".dll", ".pck"}


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def walk(root):
    out = {}
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_TOP]
        for name in filenames:
            if os.path.splitext(name)[1].lower() in SKIP_EXT:
                continue
            full = os.path.join(dirpath, name)
            rel = os.path.relpath(full, root).replace("\\", "/")
            out[rel] = full
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--archive", required=True)
    ap.add_argument("--repo", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--prefix", default="",
                    help="sub-path inside the archive to treat as project root")
    args = ap.parse_args()

    arc_root = os.path.join(args.archive, args.prefix) if args.prefix else args.archive
    if not os.path.isdir(arc_root):
        sys.exit("archive root not found: %s" % arc_root)

    arc = walk(arc_root)
    repo = walk(args.repo)

    same, different, new = [], [], []
    for rel, path in sorted(arc.items()):
        if rel in repo:
            a = sha256(path)
            b = sha256(repo[rel])
            (same if a == b else different).append(
                {"path": rel, "sha256": a, "repo_sha256": b})
        else:
            new.append({"path": rel, "sha256": sha256(path)})

    missing = []
    for rel in sorted(repo):
        if rel not in arc:
            missing.append(rel)

    manifest = {
        "archive_root": arc_root,
        "repo_root": os.path.abspath(args.repo),
        "counts": {
            "archive_files": len(arc),
            "repo_files": len(repo),
            "same": len(same),
            "different": len(different),
            "new": len(new),
            "missing_from_archive": len(missing),
        },
        "new": new,
        "different": different,
        "missing_from_archive": missing,
    }
    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(manifest, fh, indent=2, ensure_ascii=False)

    c = manifest["counts"]
    print("archive=%d repo=%d same=%d different=%d new=%d missing=%d"
          % (c["archive_files"], c["repo_files"], c["same"],
             c["different"], c["new"], c["missing_from_archive"]))
    print("manifest -> %s" % args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
