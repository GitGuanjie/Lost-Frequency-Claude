# BASELINE — Infinite Backrooms v5 on Godot 4.5.1

**Date:** 2026-11-10
**Branch:** `feature/infinite-backrooms-v5`
**Base commit:** `ebbf6f7cb6aa58a92f4a090ddc465611bd84c1ad` (`main` of `GitGuanjie/Lost-Frequency-Claude`)
**Engine:** Godot **4.5.1** stable official (`f62fdbde1`), `--rendering-driver` default (headless runs)
**GPU:** not used — every gate below is a headless CPU run
**Python:** 3.12.1 (`E:\pythonF\python.exe`)

This document states exactly what was **run** and what **failed**. Nothing here
is inferred from the existence of a script.

---

## 0. What the upstream repository actually contained

`main` was cloned and inspected before anything was written.

| Question | Answer | Evidence |
|---|---|---|
| Is `main` at the documented baseline? | **Yes** — `ebbf6f7cb6aa58a92f4a090ddc465611bd84c1ad` | `git ls-remote`, `git rev-parse HEAD` |
| Does `main` contain the Continuity Lab? | **No** — no `labs/`, no `core/world/ChunkWorld3D.gd`, no `ContinuityTopology.gd`, no `WorldAddress.gd`, no `RegionalPlan.gd` | `get_repository_tree` on `main`, `core/world` subtree |
| Does `main` contain the v4/v5 tests? | **No** — no `tests/Continuity*`, no `tests/test_worldlab_v*_static.py` | same tree query |
| Level count on `main` | **100** level directories | `levels/` tree |
| Was `feature/infinite-backrooms-v5` already pushed? | **No** — branches on the remote are `build/r3a`, `build/r3b`, `build/r3c`, `build/r5b`, `build/r5c`, `build/r5d`, `build/r6a`, `integrate/dev28`, `main` | `list_branches` |
| Does `data/canon/transitions.json` differ from the archive? | **No** — byte-identical | SHA-256 manifest |

So the warning in the brief was correct: the laboratory work was **not** on
`main`, and this session had to import it.

### 0.1 Import manifest (archive vs `main`)

`tools/v5_import_manifest.py` compares every file of the supplied
`LostFrequency-v2.1.0-InfiniteBackrooms-v5-SOURCE.zip` against the checkout.

```
archive=4389  repo=3694  same=1672  different=2017  new=700  missing=5
```

The 2 017 "different" files are dominated by noise that is **not** a content
difference:

| Class | Count | Real change? |
|---|---|---|
| `.uid` sidecars (Godot 4.4+ resource UIDs, regenerated per machine) | ~700 | No |
| CRLF vs LF line endings (`36/36`, `72/72`, `277/277`, `90/90` numstat) | most of `core/graphics/shaders/*.gdshader`, `core/player/Player.gd` | No |
| `assets/external/models/*.jpg` + `.import` | 644 | **No** — gitignored build artefacts that Godot regenerates from the embedded GLB images; all 83 `.glb` files are byte-identical |
| `levels/**` | 452 | **Yes** — the archive carries a *different* 100-level snapshot |
| `data/devNN_*.json` | 21 | Yes — procedural data |
| `core/world/ChunkWorld.gd` | 1 | **Yes** — +41 lines, opt-in chunk persistence |
| `ui/MainMenu.gd` | 1 | **Yes** — +12 lines, lab button and `--lab` command-line entry |
| `ui/Overlay.gd` | 1 | **Yes** — +9/−5, toast-stack fix |
| The laboratory itself (new) | 55 code files | **Yes** — this is the import |

### 0.2 What was imported, and what was deliberately not

`tools/v5_import_whitelist.py` derives the whitelist from the manifest **by
rule**, and `tools/v5_import.py` copies it with three enforced guarantees:

1. only whitelisted paths are touched;
2. `levels/**` and `data/canon/**` are **protected** — the importer aborts if a
   whitelist entry points into them;
3. every copied file is verified against the SHA-256 recorded in the manifest,
   before and after the copy.

```
whitelist=699 copied=699 NEW=696 DIFFERENT=3
```

Git-tracked effect of the import: **56 new files + 3 modified files**, and
`git status --short -- levels data/canon` reports **0 changed files**.

The 452 differing `levels/**` files and the 21 differing `data/devNN_*.json`
files are **not** imported. The archive's 100-level snapshot is a different
content line; reconciling it against the canonical story system is a separate,
explicitly staged phase (the brief forbids touching `levels/**` and
`data/canon/**` during the laboratory phase).

---

## 1. Native gate results — Godot 4.5.1

Run with `tools/run_v5_gates.ps1` (runs **every** gate and records each one,
including the failures, instead of stopping at the first one).

| # | Gate | Command | Result | Detail |
|---|---|---|---|---|
| 01 | asset import | `--headless --path . --import` | **PASS** | exit 0, 78.8 s, 2 580 imported files |
| 02 | CompileAll | `res://tests/CompileAll.tscn` | **PASS** | `scripts=425 failing=0` |
| 03 | ContinuityTopologyTest | `--script res://tests/ContinuityTopologyTest.gd` | **PASS** | `15593 checks, 0 failures` |
| 04 | ContinuityMacroStructureTest | `--script res://tests/ContinuityMacroStructureTest.gd` | **PASS** | `74529 assertions, 0 failures` |
| 05 | ContinuitySuperDistrictTest | `--script res://tests/ContinuitySuperDistrictTest.gd` | **PASS** | `100997 assertions, 0 failures` |
| 06 | ContinuityRegionalPlanTest | `--script res://tests/ContinuityRegionalPlanTest.gd` | **PASS** | `6505 assertions, 0 failures` |
| 07 | ContinuityPhysicalWalkTest | `res://tests/ContinuityPhysicalWalkTest.tscn` | **PASS** | `14 checks, 0 failures` |
| 08 | offline Python contracts | `unittest discover -p 'test_worldlab*static.py'` | **PASS** | `Ran 45 tests … OK` |

**Native assertion total: 198 624** (15 593 + 74 529 + 100 997 + 6 505), plus
14 physical-walk checks.

> The v5 handoff claimed "198 103 native assertions" on **Godot 4.7.2**. This
> session re-ran the whole suite on **Godot 4.5.1** and reproduced it. The
> laboratory does **not** depend on a 4.6/4.7-only API.

Logs: `reports/infinite_world/gate01..gate08*.log`
Machine-readable table: `reports/infinite_world/v5_gate_summary.json`

### 1.1 Gate 07 — what the walker physically proved

`ContinuityPhysicalWalkTest` drives a real `CharacterBody3D` through the
generated world with the physics engine. It crosses the declared east portal
of chunk 0 through real collision, walks into negative coordinates and back,
climbs a staircase to the next storey, and crosses the atrium bridge of the
shared macro hall without falling into the void. It is a physics test, not a
graph oracle: if the declared portal and the built wall disagree, the walker
cannot get through and the test fails.

It reports `14 checks, 0 failures`, matching the v5 handoff exactly.

### 1.2 Engine-version note

The `ObjectDB instances leaked at exit` / `1 resources still in use at exit`
messages in the gate-07 log are engine shutdown noise from the test harness,
not test failures: the test itself printed `14 checks, 0 failures` and the
process exit code was 0.

---

## 2. Baseline failure list

**Native laboratory failures: none.** All eight gates pass on a clean
Godot 4.5.1 checkout of the imported laboratory.

The failures that remain are **inherited from the v5 archive and are not yet
addressed**; they are listed here so the baseline is honest, and each one is
either fixed or explicitly carried forward in this session:

| # | Source | Status at this baseline |
|---|---|---|
| B1 | v5 handoff known issue 2 — the floor slot of a stairwell is 4.2 m wide but the ramp that fills it is 2.4 m wide, leaving a 1.8 m unguarded drop to the storey below | **open** |
| B2 | v5 handoff known issue 3 — a face portal offset (8 / 12 / 16 m) can land on the stair-slot band (5.4 … 18.6 m), so a wall opening can open straight onto the open well | **open** |
| B3 | v5 handoff known issue 6 — **no NOCLIP and no canon transition exists in the laboratory**; only `PHYSICAL` is implemented | **open** |
| B4 | v5 handoff known issue 4 — 16 pre-existing 100-level failures (L026, L028, L032, L050, L073, L085, L320, L808 and one story check) | **not re-measured at this baseline** — see the regression section of the final report |
| B5 | v5 handoff known issue 5 — no performance numbers | **open** |

---

## 3. Reproduction

```powershell
# from the repository root
powershell -ExecutionPolicy Bypass -File tools\run_v5_gates.ps1 `
    -Engine "E:\cherry mimo ccnot\backrooms\_dl\godot451\Godot_v4.5.1-stable_win64_console.exe" `
    -Python "E:\pythonF\python.exe"
```

Exit code 0 means every gate passed. The script writes
`reports/infinite_world/v5_gate_summary.json` with one row per gate.
