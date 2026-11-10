#!/usr/bin/env python3
"""Summarise a v5 import manifest by top-level directory and by import class."""
import json
import sys
from collections import Counter

path = sys.argv[1]
with open(path, encoding="utf-8") as fh:
    m = json.load(fh)

for key in ("new", "different"):
    c = Counter()
    for item in m[key]:
        top = item["path"].split("/", 1)[0]
        c[top] += 1
    print("=== %s (%d) by top-level dir ===" % (key.upper(), len(m[key])))
    for top, n in c.most_common():
        print("  %-14s %5d" % (top, n))
    print()

print("=== MISSING_FROM_ARCHIVE (in repo, not in archive) ===")
for p in m["missing_from_archive"]:
    print("  " + p)

print()
print("=== NEW: non-asset entries (the candidate import whitelist) ===")
for item in m["new"]:
    if not item["path"].startswith("assets/"):
        print("  " + item["path"])
