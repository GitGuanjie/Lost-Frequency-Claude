# Quality scoreboard

Generated 2026-11-08 19:16 UTC by `tools/build_reports.py` from engine artefacts.

**100 requested / 100 source-audited / 100 built scenes / 43 playable-in-engine / 51 lore-validated (AI review) / 0 fully accepted / 21 story-reachable**

Definitions: *playable-in-engine* means the scene loads in Godot, spawns safely, and a walker bot physically triggered a sourced exit. *Lore-validated* means the integrator reviewed the stills and manifest against the dossier (Claude, not a human). *Fully accepted* needs human sign-off and real-GPU performance evidence, so it is 0 by design until those exist. *Story-reachable* means reachable from Level 0 through implemented story exits between playable levels.

## Global suites (latest run)

| Suite | Passed | Failed | Run | File |
|---|---:|---:|---|---|
| duplication | 55 | 0 | 2026-11-05T05:38:54 | `reports/qa/latest_results.json` |
| framework | 8 | 0 | 2026-11-08T19:14:10 | `reports/qa/levels/L994.json` |
| lint | 371 | 0 | 2026-11-05T05:38:54 | `reports/qa/latest_results.json` |
| registry | 426 | 0 | 2026-11-05T05:38:54 | `reports/qa/latest_results.json` |
| save | 14 | 0 | 2026-11-05T05:38:54 | `reports/qa/latest_results.json` |
| story | 21 | 4 | 2026-11-05T05:38:54 | `reports/qa/latest_results.json` |
| ui | 25 | 0 | 2026-11-05T05:38:54 | `reports/qa/latest_results.json` |

## Built levels

| Level | Status | QA | Checks | Bot exit (sim s) | Nav | Save | Stills | Story-reachable |
|---|---|---|---:|---|---|---|---:|---|
| L000 | PLAYABLE | ENGINE_SMOKE_PASS | 21/21 | L000>L001#1 (11.7) | ok | ok | 11 | yes |
| L001 | PLAYABLE | ENGINE_SMOKE_PASS | 19/19 | L001>L019#10 (11.7) | ok | ok | 8 | yes |
| L002 | PLAYABLE | ENGINE_SMOKE_PASS | 28/28 | L002>L998#13 (40.8) | ok | ok | 2 | yes |
| L003 | PLAYABLE | ENGINE_SMOKE_PASS | 35/35 | L003>L069#4 (3.8) | ok | ok | 4 | yes |
| L004 | PLAYABLE | ENGINE_SMOKE_PASS | 29/29 | L004>L005#1 (9.5) | ok | ok | 2 | yes |
| L005 | PLAYABLE | ENGINE_SMOKE_PASS | 27/27 | L005>L006#3 (48.5) | ok | ok | 6 | yes |
| L006 | PLAYABLE | ENGINE_SMOKE_PASS | 19/19 | L006>L007#1 (44.1) | ok | ok | 2 | yes |
| L007 | PLAYABLE | ENGINE_SMOKE_PASS | 17/17 | L007>L009#3 (1.2) | ok | ok | 12 | yes |
| L008 | PLAYABLE | ENGINE_SMOKE_PASS | 17/17 | L008>L009#1 (8.9) | ok | ok | 2 | yes |
| L009 | PLAYABLE | ENGINE_SMOKE_PASS | 27/27 | L009>L011#1 (11.0) | ok | ok | 2 | yes |
| L010 | PLAYABLE | ENGINE_SMOKE_PASS | 24/24 | L010>L184#2 (5.8) | ok | ok | 6 | yes |
| L011 | PLAYABLE | ENGINE_SMOKE_PASS | 28/28 | L011>L025#39 (23.5) | ok | ok | 14 | yes |
| L012 | PLAYABLE | ENGINE_SMOKE_PASS | 43/43 | L012>L001#1 (1.6) | ok | ok | 2 | yes |
| L013 | PLAYABLE | ENGINE_SMOKE_PASS | 29/29 | L013>L000#1 (3.6) | ok | ok | 2 | no |
| L014 | PLAYABLE | ENGINE_SMOKE_PASS | 22/22 | L014>EXT#1 (18.9) | ok | ok | 2 | no |
| L019 | PLAYABLE | ENGINE_SMOKE_PASS | 47/47 | L019>L005#6 (8.1) | ok | ok | 2 | yes |
| L037 | PLAYABLE | ENGINE_SMOKE_PASS | 23/23 | L037>L043#2 (7.7) | ok | ok | 6 | yes |
| L188 | PLAYABLE | ENGINE_SMOKE_PASS | 19/19 | L188>EXT#1 (0.2) | ok | ok | 2 | yes |
| L015 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L016 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L017 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L018 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L020 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L022 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 2 | no |
| L023 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L024 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L025 | PLAYABLE | ENGINE_SMOKE_PASS | 31/31 | L025>L000#1 (6.6) | ok | ok | 2 | yes |
| L026 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L027 | PLAYABLE | ENGINE_SMOKE_PASS | 26/26 | L027>EXT#1 (1.4) | ok | ok | 4 | no |
| L028 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 2 | no |
| L029 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L030 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L031 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L036 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 2 | no |
| L048 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L049 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 2 | no |
| L053 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L069 | PLAYABLE | ENGINE_SMOKE_PASS | 27/27 | L069>L011#1 (12.6) | ok | ok | 4 | yes |
| L071 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 2 | no |
| L073 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L075 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L079 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L094 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L200 | PLAYABLE | ENGINE_SMOKE_PASS | 22/22 | — | ok | ok | 2 | no |
| L256 | PLAYABLE | ENGINE_SMOKE_PASS | 24/24 | — | ok | ok | 2 | no |
| L289 | PLAYABLE | ENGINE_SMOKE_PASS | 25/25 | L289>EXT#1 (15.3) | ok | ok | 2 | yes |
| L404 | PLAYABLE | ENGINE_SMOKE_PASS | 23/23 | — | ok | ok | 2 | no |
| L601 | PLAYABLE | ENGINE_SMOKE_PASS | 31/31 | L601>EXT#1 (13.8) | ok | ok | 2 | no |
| L906 | PLAYABLE | ENGINE_SMOKE_PASS | 34/34 | L906>EXT#1 (8.8) | ok | ok | 2 | no |
| L974 | PLAYABLE | ENGINE_SMOKE_PASS | 22/22 | L974>EXT#2 (2.2) | ok | ok | 2 | no |
| L000_1 | PLAYABLE | ENGINE_SMOKE_PASS | 35/35 | L000_1>L000#1 (19.2) | ok | ok | 0 | no |
| L000_2 | PLAYABLE | ENGINE_SMOKE_PASS | 25/25 | L000_2>L000#1 (11.4) | ok | ok | 0 | no |
| L000_3 | PLAYABLE | ENGINE_SMOKE_PASS | 22/22 | — | ok | ok | 0 | no |
| L001_1 | PLAYABLE | ENGINE_SMOKE_PASS | 26/26 | L001_1>L001#1 (1.1) | ok | ok | 0 | no |
| L001_2 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L001_3 | PLAYABLE | ENGINE_SMOKE_PASS | 27/27 | L001_3>L001#1 (2.2) | ok | ok | 0 | no |
| L001_5 | PLAYABLE | ENGINE_SMOKE_PASS | 24/24 | L001_5>EXT#1 (4.7) | ok | ok | 0 | yes |
| L003_5 | PLAYABLE | ENGINE_SMOKE_PASS | 27/27 | L003_5>L003#1 (14.8) | ok | ok | 0 | no |
| L005_1 | PLAYABLE | ENGINE_SMOKE_PASS | 28/28 | L005_1>L005#1 (0.7) | ok | ok | 0 | no |
| L006_1 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L007_7 | PLAYABLE | ENGINE_SMOKE_PASS | 22/22 | L007_7>L007#1 (4.7) | ok | ok | 0 | no |
| L010_1 | PLAYABLE | ENGINE_SMOKE_PASS | 23/23 | L010_1>L010#2 (15.3) | ok | ok | 0 | no |
| L011_3 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L037_1 | PLAYABLE | ENGINE_SMOKE_PASS | 17/17 | — | ok | ok | 0 | no |
| L055 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L058 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L060 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L083 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L090 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L096 | PLAYABLE | ENGINE_SMOKE_PASS | 20/20 | — | ok | ok | 4 | no |
| L808 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 2 | no |
| L922 | PLAYABLE | ENGINE_SMOKE_PASS | 21/21 | — | ok | ok | 4 | no |
| L965 | PLAYABLE | ENGINE_SMOKE_PASS | 18/18 | — | ok | ok | 6 | no |
| L994 | PLAYABLE | ENGINE_SMOKE_PASS | 23/23 | L994>EXT#1 (2.2) | ok | ok | 5 | no |
| L999 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L005_3 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L007_8 | PLAYABLE | ENGINE_SMOKE_PASS | 29/29 | L007_8>L007_7#2 (17.5) | ok | ok | 0 | no |
| L009_3 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L011_2 | PLAYABLE | ENGINE_SMOKE_PASS | 40/40 | L011_2>L283#2 (25.3) | ok | ok | 0 | no |
| L021 | PLAYABLE | ENGINE_SMOKE_PASS | 66/66 | L021>L000#1 (1.1) | ok | ok | 5 | no |
| L032 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L041 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L050 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 2 | no |
| L052 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L077 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 2 | no |
| L085 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L100 | PLAYABLE | ENGINE_SMOKE_PASS | 23/23 | L100>L004#1 (6.5) | ok | ok | 4 | no |
| L101 | PLAYABLE | ENGINE_SMOKE_PASS | 28/28 | L101>L000#1 (0.3) | ok | ok | 4 | yes |
| L108 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L114 | PLAYABLE | ENGINE_SMOKE_PASS | 25/25 | L114>L009#1 (2.6) | ok | ok | 4 | no |
| L140 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L149 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L160 | PLAYABLE | ENGINE_SMOKE_PASS | 21/21 | L160>EXT#1 (21.5) | ok | ok | 6 | no |
| L197 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L201 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L263 | PLAYABLE | ENGINE_SMOKE_PASS | 21/21 | L263>EXT#1 (1.4) | ok | ok | 4 | no |
| L320 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L737 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L899 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L998 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |

## Roster progress by group

| Group | Entries | Built |
|---|---:|---:|
| A_LOCKED_EXISTING | 18 | 18 |
| B_FLAGSHIP | 32 | 32 |
| C_HIGH_INTEREST | 25 | 25 |
| D_BREADTH | 25 | 25 |

## Honest limits

- Rendering evidence comes from Mesa lavapipe (software Vulkan, Forward+). Frame times are **not** GPU numbers, and the 60 FPS / RTX 3060 target is **UNVERIFIED** until measured on real hardware.
- No human playtest or human lore review has happened yet. `ACCEPTED` stays at 0 until one does.
- Levels without a scene are shown in-game as LOCKED / IN DEVELOPMENT, with their source readout.
- The full per-level matrix is in `reports/LEVEL_ACCEPTANCE.csv` and `docs/canon/LEVEL_100_MATRIX.csv`.
