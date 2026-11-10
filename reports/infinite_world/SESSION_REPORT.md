# SESSION REPORT — Infinite Backrooms v5, Level 0 vertical slice

**Date:** 2026-11-10
**Branch:** `feature/infinite-backrooms-v5`
**Base commit:** `ebbf6f7cb6aa58a92f4a090ddc465611bd84c1ad` (`main` of `GitGuanjie/Lost-Frequency-Claude`)
**Engine:** Godot **4.5.1** stable official (`f62fdbde1`)
**Python:** 3.12.1 (`E:\pythonF\python.exe`)
**Architecture report:** `docs/production/WORLD_COORDINATOR_AND_CANON_TRANSITION.md`
**Baseline report (the state before this session):** `reports/infinite_world/BASELINE.md`

This document states exactly what was **run** and what **failed**. Nothing here is
inferred from the existence of a script.

---

## 1. What this session delivered

| Deliverable | Where | Evidence |
|---|---|---|
| A persistent `WorldCoordinator` that owns the wanderer across a fold | `core/world/WorldCoordinator.gd` | gate 09, 37 checks |
| A laboratory portal that realises the **canon** edge `L000>L001#1` | `core/world/LabPortal.gd`, `data/lab/transitions.json` | gate 09, 37 checks |
| A flickering wall built with the canonical Level 0 material | `labs/Level0ContinuityLab.gd` | gate 09, 37 checks |
| The open stairwell closed (hole and ramp are one rectangle) | `core/world/ContinuityTopology.gd` | gate 03 + gate 07 |
| The door-onto-the-stairwell defect closed (the whole 4 m opening is clear) | `core/world/ContinuityTopology.gd` | gate 03 + gate 07 |
| Measured performance, honestly instrumented | `tests/ContinuityPerformanceProbe.gd` | gate 10 |
| A dead counter found and fixed (`stream_stats["built"]`) | `core/world/ChunkWorld3D.gd` | gate 10 |
| One reproducible command that runs every gate | `tools/run_v5_gates.ps1` | 10/10 |

**The headline:** the canonical Level 0 → Level 1 route now exists, it is
**physically walked** by a real `CharacterBody3D` into a real flickering wall,
and the player arrives in the **real** Level 1 as the **same node**, with its
light and its body state intact.

---

## 2. Gate results — Godot 4.5.1

```
powershell -ExecutionPolicy Bypass -File tools\run_v5_gates.ps1
```

| # | Gate | Result | Detail | Seconds |
|---|---|---|---|---|
| 01 | asset import | **PASS** | exit 0 | 13.6 |
| 02 | CompileAll | **PASS** | `scripts=429 failing=0` | 33.1 |
| 03 | ContinuityTopologyTest | **PASS** | `25313 checks, 0 failures` | 3.4 |
| 04 | ContinuityMacroStructureTest | **PASS** | `74529 assertions, 0 failures` | 5.5 |
| 05 | ContinuitySuperDistrictTest | **PASS** | `100997 assertions, 0 failures` | 6.2 |
| 06 | ContinuityRegionalPlanTest | **PASS** | `6505 assertions, 0 failures` | 3.5 |
| 07 | ContinuityPhysicalWalkTest | **PASS** | `14 checks, 0 failures` | 8.0 |
| 09 | ContinuityCanonTransitionTest | **PASS** | `37 checks, 0 failures` | 5.5 |
| 10 | ContinuityPerformanceProbe | **PASS** | `failures=0` | 6.1 |
| 08 | offline Python contracts | **PASS** | `Ran 45 tests … OK` | 0.6 |

**10 / 10 PASS.**

**Native assertion total: 207 344** (25 313 + 74 529 + 100 997 + 6 505), plus
14 physical-walk checks, 37 canonical-transition checks and 45 offline Python
contracts. The baseline was 198 624; the increase is the *stronger* topology
assertions added in this session (the weak "door safely within wall" proxy was
replaced by a real geometric invariant, and the stair-slot invariant was split
into two).

Logs: `reports/infinite_world/gate01..gate10*.log`
Machine-readable table: `reports/infinite_world/v5_gate_summary.json`

---

## 3. The canonical transition, and what it actually proves

`tests/ContinuityCanonTransitionTest.gd` — a **scene** run, so the autoloads
exist.

The test does not read a table and declare victory. It drives a real
`CharacterBody3D` north into the flickering wall, holds the push for the
`noclip` hold time, and then inspects the world. 37 checks, 0 failures.

The five that carry the weight:

1. **The fold completes exactly once.** `coordinator.transfer_count == 1`.
2. **The player node was MOVED, not rebuilt.** The instance id before the fold
   is the instance id after it.
3. **Exactly one player node exists afterwards.** No duplicate, no leak.
4. **The current scene runs `res://levels/L001/L001.gd`** — the canonical
   Level 1 script, not a stand-in and not `L001_PROXY`.
5. **The laboratory PLACE was released**, checked by instance id.

Full check table: `docs/production/WORLD_COORDINATOR_AND_CANON_TRANSITION.md` §5.
Report: `reports/qa/continuity_canon_transition.json`.

---

## 4. Measured performance

`tests/ContinuityPerformanceProbe.gd` walks the player along the same route the
physical walk test proves is walkable — out through the declared east portal,
back along the lane, out through the declared west portal into negative
coordinates, and home again — so the streamer really has to build and unload
chunks while the measurement runs.

**Headless CPU, Godot 4.5.1, no renderer:**

| Statistic | Per frame |
|---|---|
| median | **0.84 ms** |
| p95 | 2.14 ms |
| p99 | 15.37 ms |
| max | 29.14 ms |

The 60 fps budget is 16.667 ms. The median is comfortably inside it; the tail
is not, and the tail is the chunk-build burst (`builds_per_frame = 2`, so up to
two whole chunks are generated in one frame).

| Streaming during the measured section | Value |
|---|---|
| chunks built | 18 |
| chunks unloaded | 9 |
| peak resident chunks | 36 |
| peak triangles | 34 012 |
| peak colliders | 1 147 |
| distance walked | 68.9 m |

The walk really crossed chunk seams: the four legs ended in chunks `(1,0,0)`,
`(0,0,0)`, `(-1,0,0)` and `(0,0,0)`. The probe **fails the run** if a leg is
not reached, if no chunk is built or unloaded while the player is moving, or
if the streamed world has no real geometry or collision.

**GPU frame time is `UNVERIFIED`.** The run is headless; there is no renderer.
So is playability with a human at the keyboard.

### 4.1 The instrument had to be checked before the number was believed

`Performance.TIME_PROCESS` and `Performance.TIME_PHYSICS_PROCESS` report a
near-constant value under `--fixed-fps`: in the recorded gate run the *cold
start* median and the *cold start* maximum were **both exactly 16.074 ms**, and
the *steady state* median was the same number. A statistic whose median, p95,
p99 and maximum are identical has no resolution at all.

The cross-check is arithmetic and does not depend on the engine:

| Quantity | Value |
|---|---|
| iterations measured | 954 |
| engine monitor median | 16.074 ms |
| implied total | 15.3 s |
| **measured wall clock of the measured section** | **1.486 s** |

The engine monitor over-reports by about **10×**. The probe therefore measures
the **wall clock**, and validates itself two ways: the per-sample wall times
must add up to the elapsed time of the measured section, and the wall clock
must have a wider relative spread than the engine monitor. Both checks are part
of the probe and both pass.

---

## 5. Defects found and closed

### 5.1 Closed in this session

| ID | Defect | Fix | Proof |
|---|---|---|---|
| v5 issue 6 (B3) | **No NOCLIP and no canon transition existed in the laboratory** — only `PHYSICAL` | `WorldCoordinator` + `LabPortal` + the adaptation edge | gate 09, 37 checks |
| v5 issue 2 (B1) | the floor opening of a stairwell was 4.2 m wide while the ramp filling it was 2.4 m wide and started 1.4 m later, leaving an unguarded 4.5 m drop | hole and ramp are now **one rectangle** (`ContinuityTopology.stair_slot()`) | gate 03 + gate 07 |
| v5 issue 3 (B2) | a face door could open straight onto the stairwell | door offsets derived from the stair geometry; the **whole 4 m opening** must be clear | gate 03 + gate 07 |
| v5 issue 5 (B5) | **no performance numbers** | `ContinuityPerformanceProbe` | gate 10 |
| — | `ChunkWorld3D.stream_stats["built"]` was **declared but never incremented** — every measurement of it read zero | `_build()` advances the counter | gate 10 |
| — | the fold released `get_tree().current_scene`, which is **not** necessarily the place the player is in | ownership rule (`WorldCoordinator._source_place()`) | gate 09 |
| — | the 100-level regression script read the probe report from the wrong directory and reported **every** level as failed | path fixed | §6.1 |
| — | the 100-level regression script read an **empty** exit code from a successful import and threw on its own success | `$proc.Handle` is touched so `ExitCode` is populated | §6.4 |
| — | the entry audit's content metrics were **not reproducible**: the same level measured 675 768 / 691 180 / 698 036 triangles in three runs | the probe is now paced with `--fixed-fps 60` | §6.5 |
| — | the engine's own frame-time monitors report a **constant** under `--fixed-fps` and cannot tell a cheap frame from an expensive one | the probe measures the wall clock and cross-checks it against the elapsed time | §4.1 |
| — | a **released node reference reads as `null`** in GDScript, so a "was it released?" check written as `x != null and not is_instance_valid(x)` fails on a correctly released node | the checks use `is_instance_id_valid()` on a captured instance id | gate 09 |
| — | `Rect2`/`Vector2` store **32-bit floats** in a standard build, so `slot.size.x == 2.4` is **false** (it is 2.40000009536743) | the geometry assertions use `is_equal_approx()` | gate 03 |

### 5.2 Carried forward

| ID | Defect | Status |
|---|---|---|
| v5 issue 4 (B4) | 16 pre-existing 100-level failures (L026, L028, L032, L050, L073, L085, L320, L808 and one story check) | **re-measured on both the branch and the base commit**: 15 level-suite failures + 1 story failure = **16**, in exactly the levels the handoff named, with **zero** failures on the branch that the base does not also have (§6) |
| — | the archive's own 452 differing `levels/**` files were **deliberately not imported** | a separate phase with its own branch and its own decision about which content line wins |
| — | GPU frame time and human playability | **`UNVERIFIED`** — every run in this report is headless CPU |

---

## 6. Regression

The regression was run **twice**: once on this branch and once on a clean
worktree of the base commit `ebbf6f7`, so that "pre-existing" is a measured
result and not an assumption.

```
git worktree add --detach E:\...\lf_v5_base ebbf6f7cb6aa58a92f4a090ddc465611bd84c1ad
```

### 6.1 The 100 canonical levels — entry probe, one process per level

```
powershell -ExecutionPolicy Bypass -File RUN_100_LEVEL_ENTRY_QA_WINDOWS.ps1 -GodotExe "<godot>"
```

| | Result |
|---|---|
| Levels tested | 100 |
| Entered and spawned safely | **100** |
| Failures | **0** |

Every level loads through the real F3 developer transition and spawns the
player on solid ground. Evidence: `reports/qa/dev24_entry_100/summary.json`,
`reports/qa/dev24_entry_100/summary.csv`, and the per-level probe reports in
`reports/qa/entry_audit/levels/`.

### 6.2 The story suite

```
godot --headless --path . --fixed-fps 60 res://tests/QARunner.tscn -- --qa --suite=story
```

| Suite | Base `ebbf6f7` | This branch |
|---|---|---|
| framework | 8 passed, 0 failed | 8 passed, 0 failed |
| story | 26 passed, **1 failed** | 26 passed, **1 failed** |

The single failure is identical on both:

```
FAIL [story] bot used L020>L007#5 in story mode  { "fired": false, "ticks": 540, ... }
```

**This is a pre-existing failure on `main`, not a regression from this branch.**
It was measured on the base commit, not assumed.

### 6.3 The level suite

```
godot --headless --path . --fixed-fps 60 res://tests/QARunner.tscn -- --qa --suite=levels
```

This suite is the one that carries the v5 handoff's *"16 pre-existing 100-level
failures"*. It was run on the branch **and** on the base commit.

| | Base `ebbf6f7` | This branch |
|---|---|---|
| Total failures | 16 | **15** |
| Failures present on the branch but **not** on the base | — | **0** |
| Failures present on the base but not on the branch | 1 (`L075` checkpoint save/reload) | — |

**Zero regressions.** The 15 failures on the branch are exactly the failures
the base commit already had, in exactly these levels:

| Level | Failures |
|---|---|
| L026 | self-tests raise no script errors |
| L028 | walker bot physically triggers an exit; bot fired a declared exit; three seeds give three distinct layouts |
| L032 | at least one physical exit present near start; three seeds give three distinct layouts |
| L050 | level without exits documents why |
| L073 | level without exits documents why; three seeds give three distinct layouts |
| L085 | walker bot physically triggers an exit; bot fired a declared exit; three seeds give three distinct layouts |
| L320 | self-test: four landmark zones; three seeds give three distinct layouts |
| L808 | self-test: four different named formations |

Plus the one story failure from §6.2:

| Suite | Failures |
|---|---|
| story | bot used L020>L007#5 in story mode |

**15 + 1 = 16**, which is exactly the number the v5 handoff recorded, in
exactly the eight levels it named (L026, L028, L032, L050, L073, L085, L320,
L808) plus the one story check. The v5 handoff's list is **reproduced**, not
assumed.

The one difference — `L075 checkpoint saves and reloads with this level` — is
present on the base and absent on the branch. That check reads and writes the
**shared on-disk story save**, and both worktrees use the same `user://`
directory because they share the project name, so the two suites were
interfering with each other through that file. It is a shared-state flake, not
a code difference.

Logs: `reports/qa/levels_suite.log` (branch), `reports/qa/levels_suite_BASE.log`
(base), `reports/qa/story_suite.log`, `reports/qa/story_suite_BASE.log`.

### 6.4 Two harness bugs that had to be fixed before the regression could run

Both were in `RUN_100_LEVEL_ENTRY_QA_WINDOWS.ps1`, and both made the harness
report a failure that was not a failure of the game:

1. **The script looked for the probe's report in the wrong directory.** The
   probe writes to `reports/qa/entry_audit/levels/<SID>.json`
   (`tests/LevelEntryProbe.gd`: `REPORT_DIR`), but the script looked in its own
   `reports/qa/dev24_entry_100/levels/`. Every one of the 100 levels was
   reported as *"No probe result"* even though the probe had passed.
2. **`Start-Process -PassThru` does not populate `ExitCode`.** The script read
   the exit code of a perfectly successful asset import, got an empty value,
   and threw on its own success. The fix is to touch `$proc.Handle` right after
   starting, which caches the native handle.
3. **`@($results)` throws on a `List[object]`** in Windows PowerShell 5.1
   ("Argument types do not match"), so the summary JSON was never written.
   `$results.ToArray()` works.

All three are fixed in the same file, with the reason in a comment next to
each fix.

### 6.5 The entry audit was not reproducible, and now it is

The per-level content metrics in `reports/qa/entry_audit/levels/*.json` are a
**snapshot of a streaming world at the moment the probe measured it**, not a
property of the level. Measured evidence, the same level L026:

| Run | triangles | collision shapes | mesh instances |
|---|---|---|---|
| probe without `--fixed-fps 60` | 675 768 | 1 019 | 1 040 |
| probe without `--fixed-fps 60`, in the 100-level batch | 691 180 | 1 119 | 1 146 |
| probe with `--fixed-fps 60` (4 runs, branch and base) | 698 036 | 1 167 | 1 195 |

Without a fixed step the frame count before the measurement is not
deterministic, and a streamed level has built a different amount of geometry by
then. So a diff of those files measures **the frame rate, not the level**.

**The fix is in the script now**: the probe is launched with `--fixed-fps 60`,
like every other gate in this project. After the fix, **99 of the 100 audit
files are byte-identical to the upstream committed values except for
`build_ms`** — the upstream audit was itself produced with a fixed step, and
the numbers now reproduce. One file differs in content: L005, by 12 triangles
out of 187 122.

The PASS/FAIL verdict (load through the real F3 developer transition, safe
spawn, no fall) was never affected by this — only the content counters were.

---

## 7. Reproduction

```powershell
# every gate, one command
powershell -ExecutionPolicy Bypass -File tools\run_v5_gates.ps1 `
    -Engine "E:\cherry mimo ccnot\backrooms\_dl\godot451\Godot_v4.5.1-stable_win64_console.exe" `
    -Python "E:\pythonF\python.exe"

# the canonical transition alone
godot --headless --path . --fixed-fps 60 res://tests/ContinuityCanonTransitionTest.tscn

# the performance probe alone
godot --headless --path . --fixed-fps 60 res://tests/ContinuityPerformanceProbe.tscn

# the 100 canonical levels, one process each
powershell -ExecutionPolicy Bypass -File RUN_100_LEVEL_ENTRY_QA_WINDOWS.ps1 `
    -GodotExe "<godot 4.5.1 console exe>"
```

Exit code 0 means every gate passed. The gate runner writes
`reports/infinite_world/v5_gate_summary.json` with one row per gate.
