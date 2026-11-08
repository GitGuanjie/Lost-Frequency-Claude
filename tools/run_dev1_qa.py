#!/usr/bin/env python3
"""Run real Godot 4.5 QA in isolated stages with unambiguous pass/fail results.

Offline source tests are run separately; they never certify scene playability.
This script does NOT install Godot, write git commits, or export a Windows build.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LEVELS = ("L036", "L060", "L075", "L999")
QA_DIR = ROOT / "reports" / "qa" / "v150_dev1"


def stages(include_story: bool) -> list[tuple[str, list[str], int]]:
    work = [("import", ["--headless", "--path", str(ROOT), "--import"], 180)]
    for suite in ("registry", "lint", "save", "ui"):
        work.append((suite, ["--headless", "--path", str(ROOT), "--fixed-fps", "60", "res://tests/QARunner.tscn", "--", "--qa", f"--suite={suite}", f"--out=res://reports/qa/v150_dev1/{suite}.json"], 240))
    for sid in LEVELS:
        work.append((sid, ["--headless", "--path", str(ROOT), "--fixed-fps", "60", "res://tests/QARunner.tscn", "--", "--qa", "--suite=levels", f"--levels={sid}", f"--out=res://reports/qa/v150_dev1/{sid}.json"], 420))
    if include_story:
        work.append(("story", ["--headless", "--path", str(ROOT), "--fixed-fps", "60", "res://tests/QARunner.tscn", "--", "--qa", "--suite=story", "--story_hops=8", "--out=res://reports/qa/v150_dev1/story.json"], 900))
    return work


def run(godot: str, include_story: bool, plan_only: bool) -> int:
    work = stages(include_story)
    if plan_only:
        for stage, argv, timeout in work:
            print(f"{stage:12} timeout={timeout:4}s  {godot} {' '.join(argv)}")
        return 0
    QA_DIR.mkdir(parents=True, exist_ok=True)
    summary = {
        "created_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "source_status": "IN_DEVELOPMENT, never promoted by runner",
        "godot_exe": godot,
        "stages": [],
    }
    fatal = False
    for stage, argv, timeout in work:
        target = QA_DIR / f"{stage}.json" if stage != "import" else None
        log_path = QA_DIR / f"{stage}.log"
        if target is not None and target.exists():
            target.unlink()  # prevent stale report being interpreted as a new PASS
        print(f"START {stage} / timeout {timeout}s", flush=True)
        began = time.monotonic()
        try:
            with log_path.open("w", encoding="utf-8") as fh:
                process = subprocess.run([godot] + argv, cwd=ROOT, stdout=fh, stderr=subprocess.STDOUT, timeout=timeout, check=False)
            code = process.returncode
            reason = "" if code == 0 else f"Godot exit code {code}"
        except subprocess.TimeoutExpired:
            code = None
            reason = f"Godot timeout after {timeout}s"
        except (FileNotFoundError, OSError) as e:
            code = None
            reason = f"Cannot launch Godot: {e}"
        failures = []
        checks = {}
        if target is not None:
            if not target.is_file():
                reason = reason or "Missing fresh QA JSON; process exit code alone is not PASS"
            else:
                try:
                    data = json.loads(target.read_text(encoding="utf-8"))
                    failures = data.get("failures", [])
                    checks = {name: {"passed": result.get("passed", 0), "failed": result.get("failed", 0)} for name, result in data.get("suites", {}).items()}
                    expected = "levels" if stage in LEVELS else stage
                    if expected not in checks:
                        reason = reason or f"QA report missing expected suite: {expected}"
                    if failures or any(c["failed"] for c in checks.values()):
                        reason = reason or f"QA reports {len(failures)} failures"
                except (ValueError, OSError, TypeError, KeyError) as e:
                    reason = reason or f"Unreadable QA report: {e}"
        ok = code == 0 and not reason
        entry = {"stage": stage, "status": "PASS" if ok else "FAIL", "seconds": round(time.monotonic()-began, 2), "exit_code": code, "reason": reason, "checks": checks, "failures": failures, "log": str(log_path.relative_to(ROOT))}
        summary["stages"].append(entry)
        print(f"{'PASS' if ok else 'FAIL'} {stage}: {entry['seconds']}s {reason}", flush=True)
        if not ok:
            fatal = True
            break  # do not claim subsequent checks passed
    summary["status"] = "FAIL" if fatal else "PASS"
    out = QA_DIR / "batch_summary.json"
    out.write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"QA summary: {out}")
    return 1 if fatal else 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--godot", default="godot", help="Path to Godot 4.5.x executable; e.g. C:/Godot/Godot_v4.5.1-stable_win64_console.exe")
    ap.add_argument("--story", action="store_true", help="Also run the known-failing L009 story route after isolated tests")
    ap.add_argument("--plan-only", action="store_true", help="Print commands without invoking Godot or modifying reports")
    ns = ap.parse_args()
    return run(ns.godot, ns.story, ns.plan_only)


if __name__ == "__main__":
    sys.exit(main())
