#!/usr/bin/env python3
"""Whitelist import of the Infinite Backrooms v5 laboratory into this checkout.

Rules (enforced, not merely documented):

  1. Only paths listed in the whitelist are touched.  Nothing is copied
     "because it looks related".
  2. `levels/**` and `data/canon/**` are PROTECTED.  The import aborts if a
     whitelist entry points into them.  The canonical 100-level story system
     is not modified by a laboratory import.
  3. Every copied file is verified against the SHA-256 recorded in the
     manifest.  A mismatch is a hard failure.
  4. A provenance report is written with, for each file: source path, source
     sha256, destination path, destination sha256 and the import class
     (NEW / DIFFERENT).

Usage:
  python tools/v5_import.py --archive <dir> --repo <dir> --manifest <json> \
      --whitelist <json> [--dry-run]
"""

import argparse
import hashlib
import json
import os
import shutil
import sys

PROTECTED_PREFIXES = ("levels/", "data/canon/")


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--archive", required=True)
    ap.add_argument("--repo", required=True)
    ap.add_argument("--manifest", required=True)
    ap.add_argument("--whitelist", required=True)
    ap.add_argument("--report", default=None)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    with open(args.manifest, encoding="utf-8") as fh:
        manifest = json.load(fh)
    with open(args.whitelist, encoding="utf-8") as fh:
        whitelist = json.load(fh)

    by_path = {}
    for item in manifest["new"]:
        by_path[item["path"]] = ("NEW", item["sha256"])
    for item in manifest["different"]:
        by_path[item["path"]] = ("DIFFERENT", item["sha256"])

    entries = []
    errors = []
    for rel in whitelist["files"]:
        if rel.startswith(PROTECTED_PREFIXES):
            errors.append("PROTECTED PATH IN WHITELIST: %s" % rel)
            continue
        if rel not in by_path:
            errors.append("NOT IN MANIFEST: %s" % rel)
            continue
        cls, sha = by_path[rel]
        entries.append({"path": rel, "class": cls, "sha256": sha})

    if errors:
        for e in errors:
            print("ERROR: " + e)
        return 2

    copied = 0
    for entry in entries:
        src = os.path.join(args.archive, entry["path"].replace("/", os.sep))
        dst = os.path.join(args.repo, entry["path"].replace("/", os.sep))
        if not os.path.isfile(src):
            print("ERROR: archive file missing: %s" % entry["path"])
            return 2
        got = sha256(src)
        if got != entry["sha256"]:
            print("ERROR: archive hash mismatch for %s" % entry["path"])
            return 2
        if not args.dry_run:
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copyfile(src, dst)
            after = sha256(dst)
            if after != entry["sha256"]:
                print("ERROR: destination hash mismatch for %s" % entry["path"])
                return 2
            copied += 1
        entry["dest_sha256"] = entry["sha256"]

    report = {
        "archive_root": os.path.abspath(args.archive),
        "repo_root": os.path.abspath(args.repo),
        "dry_run": args.dry_run,
        "whitelist_entries": len(entries),
        "copied": copied,
        "by_class": {
            "NEW": sum(1 for e in entries if e["class"] == "NEW"),
            "DIFFERENT": sum(1 for e in entries if e["class"] == "DIFFERENT"),
        },
        "protected_prefixes": list(PROTECTED_PREFIXES),
        "files": entries,
    }
    if args.report and not args.dry_run:
        os.makedirs(os.path.dirname(os.path.abspath(args.report)), exist_ok=True)
        with open(args.report, "w", encoding="utf-8") as fh:
            json.dump(report, fh, indent=2, ensure_ascii=False)

    print("whitelist=%d copied=%d NEW=%d DIFFERENT=%d%s"
          % (len(entries), copied, report["by_class"]["NEW"],
             report["by_class"]["DIFFERENT"], " (dry run)" if args.dry_run else ""))
    return 0


if __name__ == "__main__":
    sys.exit(main())
