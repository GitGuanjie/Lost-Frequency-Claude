#!/usr/bin/env python3
"""Compare the published GitHub branch tree with the local commit tree.

This is the definitive check that the branch on GitHub carries exactly the
files of the local commit: same paths, same blobs.
"""
import json
import subprocess
import sys

REPO = r"E:\cherry mimo ccnot\backrooms\_dl\lf_v5"
OWNER = "GitGuanjie"
REPO_NAME = "Lost-Frequency-Claude"
BRANCH = "feature/infinite-backrooms-v5"
ARGS = r"E:\cherry mimo ccnot\backrooms\_dl\_ghargs\tree_branch.json"
MCODE = r"E:\cherry mimo ccnot\.minimax\bin\mcode-tools.cmd"


def git(*args):
    return subprocess.run(
        ["git", "-C", REPO, "-c", "core.quotepath=false"] + list(args),
        capture_output=True, check=True,
    ).stdout.decode("utf-8")


def remote_tree():
    out = subprocess.run(
        [MCODE, "connector", "call",
         "connector__github__get_repository_tree", "--args-file", ARGS],
        capture_output=True,
    ).stdout.decode("utf-8", "replace")
    # The connector prints [{"type":"text","text":"<json string>"}]
    payload = json.loads(out)
    text = payload[0]["text"]
    return json.loads(text)["tree"]


def main():
    head = sys.argv[1] if len(sys.argv) > 1 else "HEAD"
    local = {}
    for line in git("ls-tree", "-r", head).splitlines():
        meta, path = line.split("\t", 1)
        local[path] = meta.split()[2]

    remote = {}
    for node in remote_tree():
        if node.get("type") == "blob":
            remote[node["path"]] = node["sha"]

    only_local = sorted(set(local) - set(remote))
    only_remote = sorted(set(remote) - set(local))
    both = sorted(set(local) & set(remote))
    differ = [p for p in both if local[p] != remote[p]]

    print("local blobs : %d" % len(local))
    print("remote blobs: %d" % len(remote))
    print("only local  : %d %s" % (len(only_local), only_local[:10]))
    print("only remote : %d %s" % (len(only_remote), only_remote[:10]))
    print("different sha: %d %s" % (len(differ), differ[:10]))
    print("IDENTICAL" if not (only_local or only_remote or differ) else "DIFFERENCES FOUND")


if __name__ == "__main__":
    main()
