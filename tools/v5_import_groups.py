#!/usr/bin/env python3
"""List differing files, grouped by top-level directory, with optional prefix filter."""
import json
import sys
from collections import defaultdict

path = sys.argv[1]
prefixes = sys.argv[2:] if len(sys.argv) > 2 else None

with open(path, encoding="utf-8") as fh:
    m = json.load(fh)

groups = defaultdict(list)
for item in m["different"]:
    top = item["path"].split("/", 1)[0]
    groups[top].append(item["path"])
for item in m["new"]:
    top = item["path"].split("/", 1)[0]
    groups[top].append("[NEW] " + item["path"])

for top in sorted(groups):
    if prefixes and top not in prefixes:
        continue
    print("=== %s (%d) ===" % (top, len(groups[top])))
    for p in sorted(groups[top]):
        print("  " + p)
    print()
