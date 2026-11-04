# Quality scoreboard

Generated 2026-11-04 18:34 UTC by `tools/build_reports.py` from engine artefacts.

**100 requested / 100 source-audited / 1 built scenes / 1 playable-in-engine / 1 lore-validated (AI review) / 0 fully accepted / 1 story-reachable**

Definitions: *playable-in-engine* means the scene loads in Godot, spawns safely, and a walker bot physically triggered a sourced exit. *Lore-validated* means the integrator reviewed the stills and manifest against the dossier (Claude, not a human). *Fully accepted* needs human sign-off and real-GPU performance evidence, so it is 0 by design until those exist. *Story-reachable* means reachable from Level 0 through implemented story exits between playable levels.

## Global suites (latest run)

| Suite | Passed | Failed | Run | File |
|---|---:|---:|---|---|
| duplication | 1 | 0 | 2026-11-04T18:30:19 | `reports/qa/latest_results.json` |
| lint | 7 | 0 | 2026-11-04T18:30:19 | `reports/qa/latest_results.json` |
| registry | 406 | 0 | 2026-11-04T18:30:19 | `reports/qa/latest_results.json` |
| save | 14 | 0 | 2026-11-04T18:30:19 | `reports/qa/latest_results.json` |
| ui | 25 | 0 | 2026-11-04T18:30:19 | `reports/qa/latest_results.json` |

## Built levels

| Level | Status | QA | Checks | Bot exit (sim s) | Nav | Save | Stills | Story-reachable |
|---|---|---|---:|---|---|---|---:|---|
| L000 | PLAYABLE | ENGINE_SMOKE_PASS | 16/16 | L000>L001#1 (11.7) | ok | ok | 6 | yes |

## Roster progress by group

| Group | Entries | Built |
|---|---:|---:|
| A_LOCKED_EXISTING | 18 | 1 |
| B_FLAGSHIP | 32 | 0 |
| C_HIGH_INTEREST | 25 | 0 |
| D_BREADTH | 25 | 0 |

## Honest limits

- Rendering evidence comes from Mesa lavapipe (software Vulkan, Forward+). Frame times are **not** GPU numbers, and the 60 FPS / RTX 3060 target is **UNVERIFIED** until measured on real hardware.
- No human playtest or human lore review has happened yet. `ACCEPTED` stays at 0 until one does.
- Levels without a scene are shown in-game as LOCKED / IN DEVELOPMENT, with their source readout.
- The full per-level matrix is in `reports/LEVEL_ACCEPTANCE.csv` and `docs/canon/LEVEL_100_MATRIX.csv`.
