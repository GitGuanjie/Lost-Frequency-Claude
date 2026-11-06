"""Generate the machine-checkable acceptance table, the quality scoreboard and the
world-graph export from real artefacts only:

    python3 -I tools/build_reports.py

Reads data/canon/levels.json, data/canon/transitions.json, levels/<SID>/level.json,
reports/qa/latest_results.json + reports/qa/levels/*.json (engine QA) and
reports/qa/*capture*.json (rendered stills). Writes reports/LEVEL_ACCEPTANCE.csv,
reports/QUALITY_SCOREBOARD.md, docs/production/world_graph.dot and the counters
block inside docs/production/WORLD_GRAPH.md. A boolean is only true when an artefact
proves it; review-only fields stay false until a human signs off.
"""
import csv
import glob
import json
import os
from collections import defaultdict, deque
from datetime import datetime, timezone
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def load(p, default=None):
    try:
        return json.loads(Path(p).read_text(encoding="utf-8"))
    except Exception:
        return default


def main():
    roster = load(ROOT / "data/canon/levels.json")["levels"]
    edges = load(ROOT / "data/canon/transitions.json")["edges"]
    ids = [e["stable_id"] for e in roster]
    manifests = {}
    for e in roster:
        m = load(ROOT / "levels" / e["stable_id"] / "level.json")
        if m:
            manifests[e["stable_id"]] = m
    # --- engine QA: newest record per level across all result files
    qa, suites = {}, {}
    files = sorted(glob.glob(str(ROOT / "reports/qa/levels/*.json"))) + [str(ROOT / "reports/qa/latest_results.json")]
    for f in files:
        if f.endswith("_capture.json"):
            continue
        d = load(f, {})
        for r in d.get("levels", []):
            prev = qa.get(r["stable_id"])
            r["_source"] = os.path.relpath(f, ROOT)
            r["_started"] = d.get("started", "")
            if prev is None or r["_started"] >= prev.get("_started", ""):
                qa[r["stable_id"]] = r
        for k, v in d.get("suites", {}).items():
            if not k.startswith("level:"):
                suites[k] = (v["passed"], v["failed"], d.get("started", ""), os.path.relpath(f, ROOT))
        for k, v in d.get("suites", {}).items():
            if k.startswith("level:"):
                sid = k.split(":", 1)[1]
                if sid in qa and qa[sid].get("_started") == d.get("started", ""):
                    qa[sid]["_suite"] = (v["passed"], v["failed"])
    shots = defaultdict(list)
    for f in glob.glob(str(ROOT / "reports/screenshots/*.jpg")):
        shots[Path(f).name.split("_")[0]].append(os.path.relpath(f, ROOT))
    # --- story reachability over implemented, playable story exits
    playable = {s for s, m in manifests.items() if m.get("status") in ("PLAYABLE", "ACCEPTED")}
    g = defaultdict(set)
    for s, m in manifests.items():
        for x in m.get("exits", []):
            if x.get("to") and not x.get("debug_only"):
                g[s].add(x["to"])
    reach = set()
    if "L000" in playable:
        dq = deque(["L000"])
        reach.add("L000")
        while dq:
            u = dq.popleft()
            for v in g[u]:
                if v in playable and v not in reach:
                    reach.add(v)
                    dq.append(v)
    rows = []
    for e in roster:
        sid = e["stable_id"]
        m = manifests.get(sid, {})
        q = qa.get(sid, {})
        suite = q.get("_suite", (0, 0))
        engine_pass = bool(q) and suite[1] == 0 and q.get("qa_status") == "ENGINE_SMOKE_PASS"
        status = m.get("status", "NOT_STARTED")
        reviewed = status in ("PLAYABLE", "ACCEPTED")
        nav_ok = bool(q) and all(x.get("reachable") for x in q.get("nav", {}).get("exits", [])) and q.get("spawn", {}).get("spawn_ok", False)
        bot = q.get("bot", {})
        blocker = ""
        if not m:
            blocker = "not built"
        elif not engine_pass:
            blocker = "engine QA not passing" if q else "engine QA not run"
        elif not reviewed:
            blocker = "awaiting integrator review"
        rows.append({
            "level_id": e["level_id"], "stable_id": sid, "group": e["group"],
            "canonical_source_resolved": e["source_status"] in ("RESOLVED", "RESOLVED_TITLE_DIFFERS"),
            "correct_identity": reviewed,
            "unique_signature": reviewed and bool(m.get("signature")),
            "complete_scene": engine_pass,
            "real_entrance_tested": False,
            "real_exit_tested": bool(bot.get("fired")),
            "nav_and_collision_tested": nav_ok,
            "has_gameplay": reviewed and bool(m.get("mechanics")),
            "save_tested": bool(q.get("save_tested")),
            "actual_engine_tested": bool(q),
            "screenshots": len(shots.get(sid, [])),
            "fps_evidence": "UNVERIFIED (software renderer only)" if q else "",
            "lore_reviewer": "Claude (AI); human review pending" if reviewed else "",
            "qa_status": q.get("qa_status", "NOT_TESTED"),
            "implementation_status": status,
            "story_reachable": sid in reach,
            "blocker": blocker,
        })
    with open(ROOT / "reports/LEVEL_ACCEPTANCE.csv", "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)
    n = lambda pred: sum(1 for r in rows if pred(r))
    counters = {
        "requested": len(rows),
        "source_audited": n(lambda r: r["canonical_source_resolved"]),
        "built_scenes": n(lambda r: r["implementation_status"] != "NOT_STARTED"),
        "playable_in_engine": n(lambda r: r["complete_scene"] and r["real_exit_tested"]),
        "lore_validated": n(lambda r: r["correct_identity"]),
        "fully_accepted": n(lambda r: r["implementation_status"] == "ACCEPTED"),
        "story_reachable": len(reach),
    }
    # --- world graph (exactly the 100 roster nodes + one auxiliary node)
    style = {"PLAYABLE": ("#2e7d32", "white"), "ACCEPTED": ("#1b5e20", "white"),
             "IN_DEVELOPMENT": ("#f9a825", "black"), "NOT_STARTED": ("#e0e0e0", "#424242")}
    lines = ["digraph LostFrequency {", '  graph [rankdir=LR, overlap=false, splines=true, fontname="Helvetica", label="LOST FREQUENCY — 100 roster nodes; edges from the dated source pages (2026-11-04)", labelloc=t];',
             '  node [shape=box, style="rounded,filled", fontname="Helvetica", fontsize=10];', '  edge [fontsize=8];']
    for e in roster:
        st = manifests.get(e["stable_id"], {}).get("status", "NOT_STARTED")
        fill, font = style.get(st, style["NOT_STARTED"])
        label = ("L" + e["level_id"] + "\\n" + (e.get("title") or "")[:24]).replace('"', "'")
        lines.append(f'  {e["stable_id"]} [label="{label}", fillcolor="{fill}", fontcolor="{font}"];')
    lines.append('  EXT [label="outside the 100-level roster\\n(unbuilt / unnumbered)", shape=ellipse, style="dashed", fillcolor="white"];')
    impl = {(s, x["to"]) for s, m in manifests.items() for x in m.get("exits", [])}
    ext_count = defaultdict(int)
    seen = set()
    for x in edges:
        a, b = x["from"], x.get("to")
        if b not in ids:
            ext_count[a] += 1
            continue
        if (a, b) in seen:
            continue
        seen.add((a, b))
        conf = (x.get("confidence") or "").upper()
        attrs = []
        if (a, b) in impl:
            attrs.append('color="#2e7d32", penwidth=2.4')
        elif "RUMORED" in conf or "UNKNOWN" in conf:
            attrs.append('style=dotted, color="#9e9e9e"')
        elif "CONDITIONAL" in conf:
            attrs.append('style=dashed, color="#616161"')
        else:
            attrs.append('color="#424242"')
        if "DANGEROUS" in conf:
            attrs.append('fontcolor="#c62828", label="!"')
        lines.append(f'  {a} -> {b} [{", ".join(attrs)}];')
    for a, c in sorted(ext_count.items()):
        lines.append(f'  {a} -> EXT [style=dotted, color="#bdbdbd", arrowsize=0.5, label="{c}"];')
    lines.append("}")
    (ROOT / "docs/production/world_graph.dot").write_text("\n".join(lines) + "\n", encoding="utf-8")
    # --- scoreboard
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    sb = [f"# Quality scoreboard\n\nGenerated {now} by `tools/build_reports.py` from engine artefacts.\n",
          f"**{counters['requested']} requested / {counters['source_audited']} source-audited / "
          f"{counters['built_scenes']} built scenes / {counters['playable_in_engine']} playable-in-engine / "
          f"{counters['lore_validated']} lore-validated (AI review) / {counters['fully_accepted']} fully accepted / "
          f"{counters['story_reachable']} story-reachable**\n",
          "Definitions: *playable-in-engine* means the scene loads in Godot, spawns safely, and a walker bot physically "
          "triggered a sourced exit. *Lore-validated* means the integrator reviewed the stills and manifest against the "
          "dossier (Claude, not a human). *Fully accepted* needs human sign-off and real-GPU performance evidence, so it is "
          "0 by design until those exist. *Story-reachable* means reachable from Level 0 through implemented story exits "
          "between playable levels.\n",
          "## Global suites (latest run)\n", "| Suite | Passed | Failed | Run | File |", "|---|---:|---:|---|---|"]
    for k, (p_, f_, st, src) in sorted(suites.items()):
        sb.append(f"| {k} | {p_} | {f_} | {st} | `{src}` |")
    sb += ["\n## Built levels\n", "| Level | Status | QA | Checks | Bot exit (sim s) | Nav | Save | Stills | Story-reachable |",
           "|---|---|---|---:|---|---|---|---:|---|"]
    for r in rows:
        if r["implementation_status"] == "NOT_STARTED":
            continue
        q = qa.get(r["stable_id"], {})
        suite = q.get("_suite", (0, 0))
        bot = q.get("bot", {})
        bot_s = f'{bot.get("edge", "")} ({bot.get("sim_seconds", 0):.1f})' if bot.get("fired") else "—"
        sb.append(f'| {r["stable_id"]} | {r["implementation_status"]} | {r["qa_status"]} | {suite[0]}/{suite[0] + suite[1]} | {bot_s} | '
                  f'{"ok" if r["nav_and_collision_tested"] else "—"} | {"ok" if r["save_tested"] else "—"} | {r["screenshots"]} | {"yes" if r["story_reachable"] else "no"} |')
    groups = defaultdict(lambda: [0, 0])
    for r in rows:
        groups[r["group"]][0] += 1
        groups[r["group"]][1] += 1 if r["implementation_status"] != "NOT_STARTED" else 0
    sb += ["\n## Roster progress by group\n", "| Group | Entries | Built |", "|---|---:|---:|"]
    for gk in sorted(groups):
        sb.append(f"| {gk} | {groups[gk][0]} | {groups[gk][1]} |")
    sb += ["\n## Honest limits\n",
           "- Rendering evidence comes from Mesa lavapipe (software Vulkan, Forward+). Frame times are **not** GPU numbers, and "
           "the 60 FPS / RTX 3060 target is **UNVERIFIED** until measured on real hardware.",
           "- No human playtest or human lore review has happened yet. `ACCEPTED` stays at 0 until one does.",
           "- Levels without a scene are shown in-game as LOCKED / IN DEVELOPMENT, with their source readout.",
           "- The full per-level matrix is in `reports/LEVEL_ACCEPTANCE.csv` and `docs/canon/LEVEL_100_MATRIX.csv`.\n"]
    (ROOT / "reports/QUALITY_SCOREBOARD.md").write_text("\n".join(sb), encoding="utf-8")
    print(json.dumps(counters))


if __name__ == "__main__":
    main()
