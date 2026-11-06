# Quality scoreboard

Generated 2026-11-06 07:11 UTC by `tools/build_reports.py` from engine artefacts.

**100 requested / 100 source-audited / 23 built scenes / 21 playable-in-engine / 23 lore-validated (AI review) / 0 fully accepted / 18 story-reachable**

Definitions: *playable-in-engine* means the scene loads in Godot, spawns safely, and a walker bot physically triggered a sourced exit. *Lore-validated* means the integrator reviewed the stills and manifest against the dossier (Claude, not a human). *Fully accepted* needs human sign-off and real-GPU performance evidence, so it is 0 by design until those exist. *Story-reachable* means reachable from Level 0 through implemented story exits between playable levels.

## Global suites (latest run)

| Suite | Passed | Failed | Run | File |
|---|---:|---:|---|---|
| duplication | 55 | 0 | 2026-11-05T05:38:54 | `reports/qa/latest_results.json` |
| lint | 371 | 0 | 2026-11-05T05:38:54 | `reports/qa/latest_results.json` |
| registry | 426 | 0 | 2026-11-05T05:38:54 | `reports/qa/latest_results.json` |
| save | 14 | 0 | 2026-11-05T05:38:54 | `reports/qa/latest_results.json` |
| story | 21 | 4 | 2026-11-05T05:38:54 | `reports/qa/latest_results.json` |
| ui | 25 | 0 | 2026-11-05T05:38:54 | `reports/qa/latest_results.json` |

## Built levels

| Level | Status | QA | Checks | Bot exit (sim s) | Nav | Save | Stills | Story-reachable |
|---|---|---|---:|---|---|---|---:|---|
| L000 | PLAYABLE | ENGINE_SMOKE_PASS | 21/21 | L000>L001#1 (11.7) | ok | ok | 5 | yes |
| L001 | PLAYABLE | ENGINE_SMOKE_PASS | 19/19 | L001>L019#10 (11.7) | ok | ok | 2 | yes |
| L002 | PLAYABLE | ENGINE_SMOKE_PASS | 27/27 | L002>L998#13 (40.8) | ok | ok | 2 | yes |
| L003 | PLAYABLE | ENGINE_SMOKE_PASS | 33/33 | L003>L069#4 (3.8) | ok | ok | 2 | yes |
| L004 | PLAYABLE | ENGINE_SMOKE_PASS | 25/25 | L004>L005#1 (9.4) | ok | ok | 2 | yes |
| L005 | PLAYABLE | ENGINE_SMOKE_PASS | 23/23 | L005>L006#3 (48.5) | ok | ok | 2 | yes |
| L006 | PLAYABLE | ENGINE_SMOKE_PASS | 19/19 | L006>L007#1 (44.1) | ok | ok | 2 | yes |
| L007 | PLAYABLE | ENGINE_SMOKE_PASS | 17/17 | L007>L009#3 (1.2) | ok | ok | 2 | yes |
| L008 | PLAYABLE | ENGINE_SMOKE_PASS | 14/14 | L008>L009#1 (8.9) | ok | — | 2 | yes |
| L009 | PLAYABLE | ENGINE_SMOKE_PASS | 25/25 | L009>L011#1 (11.0) | ok | ok | 2 | yes |
| L010 | PLAYABLE | ENGINE_SMOKE_PASS | 23/23 | L010>L184#2 (5.8) | ok | ok | 2 | yes |
| L011 | PLAYABLE | ENGINE_SMOKE_PASS | 23/23 | L011>L025#39 (23.5) | ok | ok | 8 | yes |
| L012 | PLAYABLE | ENGINE_SMOKE_PASS | 43/43 | L012>L001#1 (1.6) | ok | ok | 2 | yes |
| L013 | PLAYABLE | ENGINE_SMOKE_PASS | 29/29 | L013>L000#1 (3.6) | ok | ok | 2 | no |
| L014 | PLAYABLE | ENGINE_SMOKE_PASS | 22/22 | L014>EXT#1 (18.9) | ok | ok | 2 | no |
| L019 | PLAYABLE | ENGINE_SMOKE_PASS | 47/47 | L019>L005#6 (8.1) | ok | ok | 2 | yes |
| L037 | PLAYABLE | ENGINE_SMOKE_PASS | 19/19 | L037>L043#2 (7.7) | ok | ok | 2 | yes |
| L188 | PLAYABLE | ENGINE_SMOKE_PASS | 19/19 | L188>EXT#1 (0.2) | ok | ok | 2 | yes |
| L025 | PLAYABLE | ENGINE_SMOKE_PASS | 29/29 | L025>L000#1 (6.6) | ok | ok | 2 | yes |
| L200 | PLAYABLE | ENGINE_SMOKE_PASS | 22/22 | — | ok | ok | 2 | no |
| L289 | PLAYABLE | ENGINE_SMOKE_PASS | 25/25 | L289>EXT#1 (15.3) | ok | ok | 2 | yes |
| L404 | PLAYABLE | ENGINE_SMOKE_PASS | 23/23 | — | ok | ok | 2 | no |
| L974 | PLAYABLE | ENGINE_SMOKE_PASS | 22/22 | L974>EXT#2 (31.0) | ok | ok | 2 | no |

## Roster progress by group

| Group | Entries | Built |
|---|---:|---:|
| A_LOCKED_EXISTING | 18 | 18 |
| B_FLAGSHIP | 32 | 5 |
| C_HIGH_INTEREST | 25 | 0 |
| D_BREADTH | 25 | 0 |

## Honest limits

- Rendering evidence comes from Mesa lavapipe (software Vulkan, Forward+). Frame times are **not** GPU numbers, and the 60 FPS / RTX 3060 target is **UNVERIFIED** until measured on real hardware.
- No human playtest or human lore review has happened yet. `ACCEPTED` stays at 0 until one does.
- Levels without a scene are shown in-game as LOCKED / IN DEVELOPMENT, with their source readout.
- The full per-level matrix is in `reports/LEVEL_ACCEPTANCE.csv` and `docs/canon/LEVEL_100_MATRIX.csv`.
