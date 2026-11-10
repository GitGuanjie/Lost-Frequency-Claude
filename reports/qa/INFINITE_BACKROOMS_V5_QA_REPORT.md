# Infinite Backrooms v5 — Native QA Report

All numbers in this report were produced by the commands quoted next to them.
Nothing here is estimated, extrapolated or taken from a previous session.

* **Engine:** Godot 4.7.2.stable.official (`ed1daf0bf`), Windows 64-bit
* **Machine:** Windows, NVIDIA GeForce RTX 3060 Laptop GPU,
  Vulkan 1.4.351, Forward+ renderer
* **Date:** 2026-11-09 / 2026-11-10
* **Package under test:** `LostFrequency-v2.0.0-ContinuityLab-v4-FULL-SOURCE.zip`
  with the v5 changes described in
  `docs/production/INFINITE_BACKROOMS_V5_ARCHITECTURE.md`

Reproduce everything with:

```
RUN_V5_QA_WINDOWS.bat "C:\path\to\Godot_v4.7.2-stable_win64_console.exe"
```

---

## 1. What was broken before anything was changed

The v4 package had never been run through a native engine. Doing that first
found four defects that made the shipped QA entry point unusable.

| # | Defect | Effect | Fix |
|---|---|---|---|
| 1 | `core/world/ChunkWorld3D.gd` mixed spaces and tabs | the script did not parse; `CompileAll` reported 3 failing scripts | the block is now tab-indented |
| 2 | `ChunkWorld3D.gd` referenced the `SaveService` autoload as a compile-time identifier | headless `--script` runs have no autoloads, so the class would not compile there; `ContinuityTopologyTest` aborted before `quit()` and **hung forever** | the autoload is now resolved at runtime (`_save_service()`), with a private in-memory scope as fallback |
| 3 | `tests/test_worldlab_*_static.py` called `read_text()` without an encoding | on a non-UTF-8 locale (this machine is GBK) all 29 offline tests died with `UnicodeDecodeError` | every read now passes `encoding='utf-8'`; the QA batch also sets `PYTHONUTF8=1` |
| 4 | the QA batch files used `set "ROOT=%~dp0"` and then `--path "%ROOT%"` | `%~dp0` ends with a backslash, which escapes the closing quote: the engine received the path `"C:\...\project" --import"` and aborted with *Invalid project path specified*. **Every shipped QA batch file was broken.** | the trailing backslash is stripped (`set "ROOT=%ROOT:~0,-1%"`) in all five batch files |

A fifth defect was found later, by running the exported build:

| # | Defect | Effect | Fix |
|---|---|---|---|
| 5 | `ui/Overlay.gd` removed a toast child while the toast box was adding another | the engine reported *Parent node is busy adding/removing children* and the old toast stayed on screen | the trim now goes through the free queue |

Defect 4 is worth underlining: the documented QA entry point of the whole
project had never worked. It is now executed end to end as part of this
report.

---

## 2. Native test suite — actual results

Command: `RUN_V5_QA_WINDOWS.bat "<godot console exe>"`, exit code **0**.

| Step | Test | Result | Output line |
|---|---|---|---|
| 1 | asset import | PASS | — |
| 2 | `res://tests/CompileAll.tscn` | **PASS** | `COMPILE_ALL scripts=425 failing=0` |
| 3 | `ContinuityTopologyTest.gd` | **PASS** | `ContinuityTopologyTest v2: 15593 checks, 0 failures` |
| 4 | `ContinuityMacroStructureTest.gd` | **PASS** | `ContinuityMacroStructureTest: 74529 assertions, 0 failures` |
| 5 | `ContinuitySuperDistrictTest.gd` | **PASS** | `ContinuitySuperDistrictTest: 100997 assertions, 0 failures` |
| 6 | `ContinuityRegionalPlanTest.gd` (new) | **PASS** | `ContinuityRegionalPlanTest: 6505 assertions, 0 failures` |
| 7 | `ContinuityPhysicalWalkTest.tscn` (new, real physics) | **PASS** | `PHYSICAL_WALK 14 checks, 0 failures` |
| 8 | offline Python contracts | **PASS** | `Ran 45 tests ... OK` |

**Total native assertions: 198 103** (15 593 + 74 529 + 100 997 + 6 505 +
14 physical checks), plus 45 offline Python contracts, plus 425 scripts
compiled.

For reference, the v4 package before this work reported 29 Python tests and
**no** native run at all; the three GDScript topology tests could not even be
loaded.

---

## 3. The physical walk test

`tests/ContinuityPhysicalWalkTest.gd` + `.tscn` — a real
`CharacterBody3D` driven through the generated world with the physics engine.
A numerical check is not a substitute for it: if the declared portal and the
built wall disagree, the walker cannot get through and the test fails.

The walker steers by facing the next waypoint and pushing forward; the
player controller's own `move_and_slide()` does the wall sliding, so it
finds a doorway the way a player does. A stuck detector alternates a
detour offset so it tries both directions along a wall.

| # | Check | What it proves |
|---|---|---|
| 1 | spawns on solid ground in chunk 0:0:0 | the spawn is not floating or inside geometry |
| 2 | reaches the **declared** east portal of chunk 0 | the opening computed by the shared-face contract is a real hole in a real wall |
| 3 | the chunk key changed to x ≥ 1 | a chunk seam was physically crossed |
| 4 | returns to the spawn point through the same portal | the way back is open too |
| 5 | reaches a chunk with **negative** coordinates | negative space is reachable and correct |
| 6 | returns from the negative side | and it is a round trip |
| 7 | climbs the staircase to the next storey | the ramp is walkable, not a decoration |
| 8 | the chunk key moved up one storey | the climb changed the player's world position |
| 9 | physically crosses the **atrium bridge** of the 2×2 macro hall | the 5 m bridge over a 5 m void carries a body |
| 10 | ends on the far side of the macro hall | the bridge lands in the next chunk |
| 11 | did not fall into the atrium void | the bridge really is a floor |
| 12 | an unloaded and rebuilt chunk is structurally identical | the world is a function of the coordinates, not of the session |

The report is written to `reports/qa/continuity_physical_walk.json` with the
engine version, the seed and every individual finding.

**One placement is used and it is documented in the test source:** the
walker is set down on the solid floor beside the atrium bridge (check 9).
Reaching that floor from the spawn means crossing an open stairwell, which
is a legitimate fall, not a failure — so the bridge crossing itself is the
part that must be completed under physics. No other check places the body.

---

## 4. 100-level canonical regression — before and after

Command:
`godot --headless --path . --fixed-fps 60 res://tests/QARunner.tscn -- --qa`

Run twice: once against the unmodified v4 package (the baseline) and once
against the v5 package. Both runs are compared suite by suite.

| | Baseline (v4, unmodified) | v5 | Delta |
|---|---|---|---|
| Suites | 110 | 110 | — |
| Assertions | 9 912 | 9 912 | **0** |
| Failures | 16 | 16 | **0** |
| Suites with a different failure count | — | — | **0** |

The 16 pre-existing failures are unchanged and are all in the original
100-level content, not in the lab:

| Suite | Failures |
|---|---|
| level:L026 | 1 |
| level:L028 | 3 |
| level:L032 | 2 |
| level:L050 | 1 |
| level:L073 | 2 |
| level:L085 | 3 |
| level:L320 | 2 |
| level:L808 | 1 |
| story | 1 |

They were already failing in the shipped v4 package; this work neither
fixed nor worsened them. They are listed in the next-session handoff as
outstanding work.

**The 100 canonical levels, their story data and their transition graph were
not modified.** `levels/`, `data/canon/levels.json` and
`data/canon/transitions.json` are byte-identical to the v4 package.

---

## 5. Windows export — exported and run on this machine

Export command:

```
godot --headless --path . --export-release "Windows Desktop" "<out>\LostFrequency.exe"
```

| Property | Value |
|---|---|
| Preset | `Windows Desktop`, `export_filter=all_resources`, `binary_format/embed_pck=true` |
| Result | **single file**, 238.8 MB, no external `.pck` |
| Engine in the build | Godot 4.7.2.stable.official |
| Renderer at run time | Vulkan 1.4.351, Forward+, NVIDIA GeForce RTX 3060 Laptop GPU |

Runtime checks on the exported binary, on this Windows machine:

| Check | Command | Result |
|---|---|---|
| the build boots | `LostFrequency.exe --headless --quit-after 400` | clean boot, engine banner only, exit ok |
| the procedural world boots and renders | `LostFrequency.exe -- --lab --shot "<file>.png"` | `SHOT <file>.png err=0 size=1600x900` |
| the image is a real render, not a blank frame | pixel analysis of the PNG | 33 689 distinct colours, mean RGB (99.7, 83.1, 50.5) — the warm yellow of the Backrooms palette — luminance range 9..253 |
| the main menu is clean | `LostFrequency.exe` (no arguments) | no script errors on stderr |

The `--lab` and `--shot` switches are new command-line entry points on the
game itself:

```
LostFrequency.exe -- --lab                    # start straight in the lab
LostFrequency.exe -- --lab --shot "C:\a.png"  # capture the world and quit
```

---

## 6. Performance

**Not measured, and not claimed.** This work was done on a laptop with a
single RTX 3060 and the session did not include a frame-time capture of the
lab. Reporting a median / p95 / p99 frame time, a RAM or VRAM figure or a
triangle count here would be an invention.

What *is* measured, and is in the code:

* the loaded chunk set is bounded (`radius_xz`, `radius_y`, `unload_xz`,
  `unload_y`);
* chunk construction is limited by **both** a chunk count and a millisecond
  budget per frame (`builds_per_frame`, `build_budget_ms`), so one expensive
  chunk cannot stall a frame;
* the chunk order is biased 6× towards the player's heading, so the chunks
  the player is walking into exist before the ones behind;
* the loaded triangle and collider totals are already shown in the lab HUD
  and returned in every chunk's metadata.

Producing a real performance report is listed in the handoff.

---

## 7. Known issues in this build

1. **Godot 4.7.2 prints *Parent node is busy adding/removing children* on
   every scene change.** Reproduced with a two-scene probe that contains no
   project code at all, so it is an engine behaviour, not a defect in this
   package. It appears once per scene transition and does not affect
   gameplay.
2. The lab's stairwells are open: the floor slot is 4.2 m wide and the ramp
   that fills it is 2.4 m wide, leaving a 1.8 m strip beside the ramp that
   drops to the storey below. This is v4 behaviour and is preserved.
3. A face opening can land on a stair slot, because the portal offsets
   (8, 12, 16) and the slot band (14.4 … 18.6) overlap.
4. The 16 pre-existing 100-level failures listed in section 4.
5. The offline Python contracts read the source as text and assert on
   literals. They are a cheap tripwire, not a specification — the native
   tests are the specification.
