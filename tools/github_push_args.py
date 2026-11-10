#!/usr/bin/env python3
"""Build mcode-tools connector args files for connector__github__push_files.

The file contents are read from the GIT OBJECT, not from the working tree, so
the bytes pushed are exactly the bytes that were committed.

The connector rejects an oversized request, so the file list is split into
requests that stay under a size limit. Every chunk after the first continues
the branch, so the final tree is the tree of <head>.
"""
import json
import os
import subprocess
import sys

REPO = r"E:\cherry mimo ccnot\backrooms\_dl\lf_v5"
OWNER = "GitGuanjie"
REPO_NAME = "Lost-Frequency-Claude"
BRANCH = "feature/infinite-backrooms-v5"


def git(*args, binary=False):
    out = subprocess.run(
        ["git", "-C", REPO, "-c", "core.quotepath=false"] + list(args),
        capture_output=True, check=True,
    ).stdout
    return out if binary else out.decode("utf-8")


def main():
    base = sys.argv[1]
    head = sys.argv[2]
    out_dir = sys.argv[3]
    limit = int(sys.argv[4]) if len(sys.argv) > 4 else 120000
    exclude = set()
    if len(sys.argv) > 5 and sys.argv[5]:
        exclude = set(x for x in sys.argv[5].split(",") if x)

    paths = [p for p in git("diff", "--name-only", base, head).splitlines() if p]
    paths = [p for p in paths if p not in exclude]
    message = git("log", "-1", "--pretty=%B", head).strip()

    chunks = []
    current = []
    current_bytes = 0
    skipped = []
    for p in paths:
        # A path that no longer exists in the head tree was DELETED by this
        # commit. There is nothing to push for it.
        exists = subprocess.run(
            ["git", "-C", REPO, "cat-file", "-e", "%s:%s" % (head, p)],
            capture_output=True,
        ).returncode == 0
        if not exists:
            skipped.append(p)
            continue
        blob = git("show", "%s:%s" % (head, p), binary=True)
        size = len(blob)
        if current and current_bytes + size > limit:
            chunks.append(current)
            current = []
            current_bytes = 0
        current.append({"path": p, "content": blob.decode("utf-8")})
        current_bytes += size
    if current:
        chunks.append(current)

    os.makedirs(out_dir, exist_ok=True)
    for i, files in enumerate(chunks):
        args = {
            "owner": OWNER,
            "repo": REPO_NAME,
            "branch": BRANCH,
            "files": files,
            "message": message if i == 0 else (message + "\n\n(continued: part %d of %d)"
                                               % (i + 1, len(chunks))),
        }
        path = os.path.join(out_dir, "chunk_%02d.json" % i)
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            json.dump(args, f, ensure_ascii=False)
        print("chunk %02d: files=%d bytes=%d -> %s"
              % (i, len(files), sum(len(x["content"]) for x in files), path))
    print("total chunks: %d" % len(chunks))
    if skipped:
        print("skipped (deleted by this commit): %s" % ", ".join(skipped))


if __name__ == "__main__":
    main()
