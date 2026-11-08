#!/usr/bin/env python3
"""Static world/canon/QA evidence audit for Lost Frequency.

Does not imply runtime pass. Does not edit manifests or mark anything PLAYABLE.
Runs offline from the Godot repository root; Python standard library only.
"""
from __future__ import annotations

import argparse
import csv
import json
from collections import defaultdict, deque
from html import escape
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "reports" / "world_audit"


def jread(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (ValueError, OSError):
        return None


def reach(nodes: set[str], edges: list[dict[str, Any]], start="L000") -> set[str]:
    adj: dict[str, list[str]] = defaultdict(list)
    for e in edges:
        if e["from"] in nodes and e["to"] in nodes:
            adj[e["from"]].append(e["to"])
    seen: set[str] = set()
    q = deque([start])
    while q:
        s = q.popleft()
        if s not in nodes or s in seen:
            continue
        seen.add(s)
        q.extend(adj[s])
    return seen


def read_data(root=ROOT):
    roster = jread(root / "data/canon/levels.json")
    if not isinstance(roster, dict):
        raise ValueError("Invalid canonical roster")
    entries = {e["stable_id"]: e for e in roster["levels"]}
    built = {}
    edges = []
    issues = []
    for sid, entry in entries.items():
        mp = root / "levels" / sid / "level.json"
        if not mp.exists():
            continue
        manifest = jread(mp)
        if not isinstance(manifest, dict):
            issues.append({"type": "bad_manifest", "sid": sid, "message": str(mp)})
            continue
        scene = manifest.get("scene", "")
        if not scene or not (root / scene.removeprefix("res://")).is_file():
            issues.append({"type": "missing_scene", "sid": sid, "message": scene})
            continue
        built[sid] = manifest
        arrivals = set(manifest.get("arrivals", []))
        seen_ids = set()
        for e in manifest.get("exits", []):
            edge = dict(e)
            edge["from"] = sid
            edge["to"] = str(e.get("to", ""))
            edge["id"] = str(e.get("id", ""))
            edge["basis"] = str(e.get("basis", ""))
            edges.append(edge)
            if not edge["id"].startswith(sid + ">"):
                issues.append({"type": "bad_edge_id", "sid": sid, "message": edge["id"]})
            if edge["id"] in seen_ids:
                issues.append({"type": "duplicate_edge_id", "sid": sid, "message": edge["id"]})
            seen_ids.add(edge["id"])
            if edge["to"] in built:
                pass  # checked in second pass
        if "start" not in arrivals:
            issues.append({"type": "missing_start_arrival", "sid": sid, "message": str(sorted(arrivals))})
    for e in edges:
        target = e["to"]
        if target not in built:
            continue
        arrival = str(e.get("arrival", "from_" + e["from"]))
        arrivals = set(built[target].get("arrivals", []))
        if arrival not in arrivals:
            issues.append({"type": "missing_arrival", "sid": target, "message": f"{e['id']}: requires {arrival}"})
    return entries, built, edges, issues


def evidence(root, built: dict, edges: list[dict]) -> tuple[dict, dict]:
    level_qa = {}
    for sid in built:
        candidates = [root / "reports/qa/levels" / (sid + ".json")]
        for p in candidates:
            d = jread(p)
            if isinstance(d, dict):
                for rec in d.get("levels", []):
                    if rec.get("stable_id") == sid:
                        level_qa[sid] = rec
                        break
    # Older consolidated QA may supply evidence for levels without single-level JSON.
    aggregate = jread(root / "reports/qa/latest_results.json") or {}
    for rec in aggregate.get("levels", []):
        if rec.get("stable_id") in built and rec["stable_id"] not in level_qa:
            level_qa[rec["stable_id"]] = rec
    flags = {}
    for sid, rec in level_qa.items():
        nav = rec.get("nav", {})
        flags[sid] = {
            "status": rec.get("qa_status", "NOT_REPORTED"),
            "observed": {x.get("edge") for x in nav.get("exits", []) if x.get("edge")},
            "nav_reachable": {x.get("edge") for x in nav.get("exits", []) if x.get("reachable")},
            "bot_fired": bool(rec.get("bot", {}).get("fired", False)),
            "build_ms": rec.get("build_ms"),
            "collision_shapes": rec.get("collision_shapes"),
        }
    return level_qa, flags


def svg_via_dot(built: dict, edges: list[dict], reachable: set[str], observed: dict, outpath: Path):
    import subprocess
    lines = ['digraph World {', 'graph [bgcolor="#101820", ranksep=1.05, nodesep=.47, pad=.4];',
             'node [shape=box, style="rounded,filled", fontname="DejaVu Sans", fontsize=12, color="#42555b", fontcolor="#e9f0eb", fillcolor="#243840"];',
             'edge [arrowsize=.6, color="#48969d", penwidth=1.5];']
    for sid in sorted(built):
        color = '#327278' if sid in reachable else '#383e49'
        lines.append(f'"{sid}" [label="{sid.replace("_", ".")}", fillcolor="{color}"];')
    grouped = defaultdict(list)
    for edge in edges:
        if edge["from"] in built and edge["to"] in built and edge["to"] != edge["from"]:
            grouped[(edge["from"], edge["to"])].append(edge)
    for (source, target), items in sorted(grouped.items()):
        o = observed.get(source, {}).get('observed', set())
        hit = any(item['id'] in o for item in items)
        adapter = any(item['basis'] == 'ADAPTATION' for item in items)
        style = 'solid' if hit else 'dashed'
        color = '#dea25b' if adapter else ('#56b1b4' if hit else '#667d80')
        lines.append(f'"{source}" -> "{target}" [style="{style}", color="{color}"];')
    lines.append('}')
    dot = '\n'.join(lines)
    (outpath.with_suffix('.dot')).write_text(dot, encoding='utf-8')
    try:
        subprocess.run(['dot', '-Tsvg', str(outpath.with_suffix('.dot')), '-o', str(outpath)], check=True, timeout=30)
        return True
    except (OSError, subprocess.SubprocessError):
        return False


def audit(root=ROOT, output=OUT, render=True):
    entries, built, edges, issues = read_data(root)
    qas, observed = evidence(root, built, edges)
    declared_built = [e for e in edges if e['from'] in built and e['to'] in built]
    seen_built = [e for e in declared_built if e['id'] in observed.get(e['from'], {}).get('observed', set())]
    reachable = reach(set(built), declared_built)
    observed_reachable = reach(set(built), seen_built)
    src_count = len(edges)
    csv_rows = []
    for e in edges:
        to = e['to']
        o = observed.get(e['from'], {})
        status = ('OBSERVED_QA' if e['id'] in o.get('observed', set()) else 'NOT_OBSERVED_IN_QA') if e['from'] in observed else 'NO_LEVEL_QA'
        csv_rows.append({
            'from': e['from'], 'edge': e['id'], 'to': to,
            'target_built': to in built, 'source_basis': e['basis'],
            'qa_evidence': status, 'qa_nav_reachable': e['id'] in o.get('nav_reachable', set()),
            'arrival': e.get('arrival', 'from_' + e['from']),
        })
    output.mkdir(parents=True, exist_ok=True)
    with (output / 'exit_evidence.csv').open('w', encoding='utf-8-sig', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=csv_rows[0].keys())
        writer.writeheader(); writer.writerows(csv_rows)
    report = {
        'source': 'manifest + existing QA reports (not a fresh runtime test)',
        'roster_count': len(entries), 'built_count': len(built), 'declared_exit_count': src_count,
        'built_to_built_exit_count': len(declared_built), 'observed_built_to_built_exit_count': len(seen_built),
        'reachable_by_manifest': sorted(reachable), 'reachable_by_qa_snapshot': sorted(observed_reachable),
        'built_not_reachable': sorted(set(built)-reachable), 'issues': issues,
        'qa_levels_with_reports': len(qas),
        'evidence_gap': sorted(e['id'] for e in edges if e['id'] not in observed.get(e['from'],{}).get('observed',set())),
        'high_collision_levels': sorted([{'id': sid, 'collision_shapes': rec['collision_shapes']} for sid, rec in observed.items() if isinstance(rec['collision_shapes'], int)], key=lambda x:-x['collision_shapes'])[:12],
        'provisional_start_arrivals': sorted([{'level':sid,'arrival':tag} for sid,m in built.items() for tag in m.get('arrival_aliases',[])] ,key=lambda x:(x['level'],x['arrival'])),
    }
    (output / 'world_report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    if render:
        svg_via_dot(built, edges, reachable, observed, output/'world_graph.svg')
    lines = [
        '# Lost Frequency — world integrity audit',
        '',
        '> Manifest and existing QA evidence only. No Godot runtime was executed by this script.',
        '',
        f'Roster **{len(entries)}**, built **{len(built)}**, declared exits **{src_count}**.',
        f'Built-to-built routes: **{len(declared_built)}** declared / **{len(seen_built)}** observed in QA snapshots.',
        f'From L000: **{len(reachable)}** built levels manifest-reachable / **{len(observed_reachable)}** QA-snapshot-reachable.',
        f'Unreachable built levels: `{", ".join(sorted(set(built)-reachable))}`.',
        '', '## Integrity issues',
    ]
    if not issues: lines.append('No structural manifest issues detected by this audit.')
    else:
        lines.extend([f'- `{i["type"]}` in `{i["sid"]}`: {i["message"]}' for i in issues])
    lines.extend(['', '## Evidence interpretation',
                  'A QA-observed trigger is **not** evidence of a successful physical traversal. '
                  'Missing QA observations are **not** proof of a broken route: triggers may stream in or require conditions.',
                  'Never mark a level PLAYABLE automatically based on this report.', ''])
    (output/'WORLD_AUDIT.md').write_text('\n'.join(lines), encoding='utf-8')
    return report


def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--root', type=Path, default=ROOT)
    ap.add_argument('--out', type=Path, default=None)
    ap.add_argument('--no-render', action='store_true')
    ap.add_argument('--fail-on-issues', action='store_true')
    args=ap.parse_args()
    root=args.root.resolve()
    report=audit(root, args.out or (root / 'reports/world_audit'), not args.no_render)
    print(f"built={report['built_count']} exits={report['declared_exit_count']} manifest_reachable={len(report['reachable_by_manifest'])} qa_observed_reachable={len(report['reachable_by_qa_snapshot'])} issues={len(report['issues'])}")
    if args.fail_on_issues and report['issues']:
        raise SystemExit(2)


if __name__ == '__main__': main()
