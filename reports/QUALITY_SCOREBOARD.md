# Quality scoreboard

Generated 2026-11-09 01:53 UTC by `tools/build_reports.py` from engine artefacts.

**100 requested / 100 source-audited / 100 built scenes / 79 playable-in-engine / 90 lore-validated (AI review) / 0 fully accepted / 39 story-reachable**

Definitions: *playable-in-engine* means the scene loads in Godot, spawns safely, and a walker bot physically triggered a sourced exit. *Lore-validated* means the integrator reviewed the stills and manifest against the dossier (Claude, not a human). *Fully accepted* needs human sign-off and real-GPU performance evidence, so it is 0 by design until those exist. *Story-reachable* means reachable from Level 0 through implemented story exits between playable levels.

## Global suites (latest run)

| Suite | Passed | Failed | Run | File |
|---|---:|---:|---|---|
| duplication | 55 | 0 | 2026-11-05T05:38:54 | `reports/qa/latest_results.json` |
| framework | 8 | 0 | 2026-11-09T00:44:55 | `reports/qa/levels/L999.json` |
| lint | 371 | 0 | 2026-11-05T05:38:54 | `reports/qa/latest_results.json` |
| registry | 426 | 0 | 2026-11-05T05:38:54 | `reports/qa/latest_results.json` |
| save | 14 | 0 | 2026-11-05T05:38:54 | `reports/qa/latest_results.json` |
| story | 21 | 4 | 2026-11-05T05:38:54 | `reports/qa/latest_results.json` |
| ui | 25 | 0 | 2026-11-05T05:38:54 | `reports/qa/latest_results.json` |

## Built levels

| Level | Status | QA | Checks | Bot exit (sim s) | Nav | Save | Stills | Story-reachable |
|---|---|---|---:|---|---|---|---:|---|
| L000 | PLAYABLE | ENGINE_SMOKE_PASS | 22/22 | L000>L001#1 (11.7) | ok | ok | 17 | yes |
| L001 | PLAYABLE | ENGINE_SMOKE_PASS | 20/20 | L001>L019#10 (11.7) | ok | ok | 12 | yes |
| L002 | PLAYABLE | ENGINE_SMOKE_PASS | 29/29 | L002>L998#13 (40.8) | ok | ok | 2 | yes |
| L003 | PLAYABLE | ENGINE_SMOKE_PASS | 36/36 | L003>L069#4 (3.8) | ok | ok | 4 | yes |
| L004 | PLAYABLE | ENGINE_SMOKE_PASS | 30/30 | L004>L005#1 (9.5) | ok | ok | 2 | yes |
| L005 | PLAYABLE | ENGINE_SMOKE_PASS | 28/28 | L005>L006#3 (48.5) | ok | ok | 10 | yes |
| L006 | PLAYABLE | ENGINE_SMOKE_PASS | 20/20 | L006>L007#1 (44.1) | ok | ok | 6 | yes |
| L007 | PLAYABLE | ENGINE_SMOKE_PASS | 18/18 | L007>L009#3 (1.2) | ok | ok | 12 | yes |
| L008 | PLAYABLE | ENGINE_SMOKE_PASS | 18/18 | L008>L009#1 (8.9) | ok | ok | 2 | yes |
| L009 | PLAYABLE | ENGINE_SMOKE_PASS | 28/28 | L009>L011#1 (11.0) | ok | ok | 6 | yes |
| L010 | PLAYABLE | ENGINE_SMOKE_PASS | 25/25 | L010>L184#2 (5.8) | ok | ok | 6 | yes |
| L011 | PLAYABLE | ENGINE_SMOKE_PASS | 29/29 | L011>L025#39 (23.5) | ok | ok | 18 | yes |
| L012 | PLAYABLE | ENGINE_SMOKE_PASS | 44/44 | L012>L001#1 (1.6) | ok | ok | 2 | yes |
| L013 | PLAYABLE | ENGINE_SMOKE_PASS | 30/30 | L013>L000#1 (3.6) | ok | ok | 2 | no |
| L014 | PLAYABLE | ENGINE_SMOKE_PASS | 23/23 | L014>EXT#1 (18.9) | ok | ok | 2 | yes |
| L019 | PLAYABLE | ENGINE_SMOKE_PASS | 48/48 | L019>L005#6 (8.1) | ok | ok | 2 | yes |
| L037 | PLAYABLE | ENGINE_SMOKE_PASS | 24/24 | L037>L043#2 (7.7) | ok | ok | 6 | yes |
| L188 | PLAYABLE | ENGINE_SMOKE_PASS | 20/20 | L188>EXT#1 (0.2) | ok | ok | 2 | yes |
| L015 | PLAYABLE | ENGINE_SMOKE_PASS | 27/27 | L015>EXT#2 (54.3) | ok | ok | 4 | no |
| L016 | PLAYABLE | ENGINE_SMOKE_PASS | 25/25 | L016>L046#1 (15.6) | ok | ok | 4 | no |
| L017 | PLAYABLE | ENGINE_SMOKE_PASS | 26/26 | L017>EXT#1 (0.6) | ok | ok | 4 | no |
| L018 | PLAYABLE | ENGINE_SMOKE_PASS | 23/23 | L018>L019#1 (1.3) | ok | ok | 4 | no |
| L020 | PLAYABLE | ENGINE_SMOKE_PASS | 34/34 | L020>L002#1 (9.6) | ok | ok | 4 | yes |
| L022 | PLAYABLE | ENGINE_SMOKE_PASS | 26/26 | L022>L023#2 (16.2) | ok | ok | 4 | yes |
| L023 | PLAYABLE | ENGINE_SMOKE_PASS | 32/32 | L023>L135#4 (1.7) | ok | ok | 4 | yes |
| L024 | PLAYABLE | ENGINE_SMOKE_PASS | 24/24 | L024>EXT#1 (25.0) | ok | ok | 4 | yes |
| L025 | PLAYABLE | ENGINE_SMOKE_PASS | 32/32 | L025>L000#1 (6.6) | ok | ok | 2 | yes |
| L026 | PLAYABLE | ENGINE_SMOKE_PASS | 25/25 | L026>L004#1 (28.1) | ok | ok | 4 | no |
| L027 | PLAYABLE | ENGINE_SMOKE_PASS | 27/27 | L027>EXT#1 (1.4) | ok | ok | 4 | no |
| L028 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 2 | no |
| L029 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L030 | PLAYABLE | ENGINE_SMOKE_PASS | 20/20 | — | ok | ok | 4 | no |
| L031 | PLAYABLE | ENGINE_SMOKE_PASS | 29/29 | L031>L040#1 (22.6) | ok | ok | 4 | yes |
| L036 | PLAYABLE | ENGINE_SMOKE_PASS | 27/27 | L036>L036_1#1 (50.0) | ok | ok | 4 | yes |
| L048 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L049 | PLAYABLE | ENGINE_SMOKE_PASS | 29/29 | L049>L014#1 (3.9) | ok | ok | 4 | yes |
| L053 | PLAYABLE | ENGINE_SMOKE_PASS | 23/23 | L053>L009#1 (4.1) | ok | ok | 4 | yes |
| L069 | PLAYABLE | ENGINE_SMOKE_PASS | 28/28 | L069>L011#1 (12.6) | ok | ok | 4 | yes |
| L071 | PLAYABLE | ENGINE_SMOKE_PASS | 19/19 | — | ok | ok | 4 | yes |
| L073 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L075 | PLAYABLE | ENGINE_SMOKE_PASS | 26/26 | L075>EXT#1 (36.0) | ok | ok | 4 | no |
| L079 | PLAYABLE | ENGINE_SMOKE_PASS | 20/20 | L079>EXT#1 (0.8) | ok | ok | 4 | no |
| L094 | PLAYABLE | ENGINE_SMOKE_PASS | 28/28 | L094>L009#3 (5.3) | ok | ok | 4 | no |
| L200 | PLAYABLE | ENGINE_SMOKE_PASS | 23/23 | — | ok | ok | 2 | no |
| L256 | PLAYABLE | ENGINE_SMOKE_PASS | 25/25 | — | ok | ok | 2 | no |
| L289 | PLAYABLE | ENGINE_SMOKE_PASS | 26/26 | L289>EXT#1 (15.3) | ok | ok | 2 | yes |
| L404 | PLAYABLE | ENGINE_SMOKE_PASS | 24/24 | — | ok | ok | 2 | no |
| L601 | PLAYABLE | ENGINE_SMOKE_PASS | 32/32 | L601>EXT#1 (13.8) | ok | ok | 2 | no |
| L906 | PLAYABLE | ENGINE_SMOKE_PASS | 35/35 | L906>EXT#1 (8.8) | ok | ok | 2 | no |
| L974 | PLAYABLE | ENGINE_SMOKE_PASS | 23/23 | L974>EXT#2 (2.2) | ok | ok | 2 | no |
| L000_1 | PLAYABLE | ENGINE_SMOKE_PASS | 36/36 | L000_1>L000#1 (19.2) | ok | ok | 0 | no |
| L000_2 | PLAYABLE | ENGINE_SMOKE_PASS | 26/26 | L000_2>L000#1 (11.4) | ok | ok | 0 | no |
| L000_3 | PLAYABLE | ENGINE_SMOKE_PASS | 23/23 | — | ok | ok | 0 | no |
| L001_1 | PLAYABLE | ENGINE_SMOKE_PASS | 27/27 | L001_1>L001#1 (1.1) | ok | ok | 0 | no |
| L001_2 | PLAYABLE | ENGINE_SMOKE_PASS | 28/28 | L001_2>L001#1 (5.0) | ok | ok | 0 | no |
| L001_3 | PLAYABLE | ENGINE_SMOKE_PASS | 28/28 | L001_3>L001#1 (2.2) | ok | ok | 0 | no |
| L001_5 | PLAYABLE | ENGINE_SMOKE_PASS | 25/25 | L001_5>EXT#1 (4.7) | ok | ok | 0 | yes |
| L003_5 | PLAYABLE | ENGINE_SMOKE_PASS | 28/28 | L003_5>L003#1 (14.8) | ok | ok | 0 | no |
| L005_1 | PLAYABLE | ENGINE_SMOKE_PASS | 29/29 | L005_1>L005#1 (0.7) | ok | ok | 0 | no |
| L006_1 | PLAYABLE | ENGINE_SMOKE_PASS | 31/31 | L006_1>L011#2 (12.2) | ok | ok | 0 | yes |
| L007_7 | PLAYABLE | ENGINE_SMOKE_PASS | 23/23 | L007_7>L007#1 (4.7) | ok | ok | 0 | no |
| L010_1 | PLAYABLE | ENGINE_SMOKE_PASS | 24/24 | L010_1>L010#2 (15.3) | ok | ok | 0 | no |
| L011_3 | PLAYABLE | ENGINE_SMOKE_PASS | 27/27 | L011_3>L011#1 (48.2) | ok | ok | 0 | no |
| L037_1 | PLAYABLE | ENGINE_SMOKE_PASS | 18/18 | — | ok | ok | 0 | no |
| L055 | PLAYABLE | ENGINE_SMOKE_PASS | 25/25 | L055>EXT#1 (1.6) | ok | ok | 4 | no |
| L058 | PLAYABLE | ENGINE_SMOKE_PASS | 28/28 | L058>L001#2 (43.2) | ok | ok | 4 | no |
| L060 | PLAYABLE | ENGINE_SMOKE_PASS | 27/27 | L060>L007#1 (1.5) | ok | ok | 4 | no |
| L083 | PLAYABLE | ENGINE_SMOKE_PASS | 23/23 | L083>L007#1 (10.5) | ok | ok | 4 | yes |
| L090 | PLAYABLE | ENGINE_SMOKE_PASS | 23/23 | L090>EXT#1 (10.3) | ok | ok | 4 | yes |
| L096 | PLAYABLE | ENGINE_SMOKE_PASS | 21/21 | — | ok | ok | 4 | no |
| L808 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 2 | no |
| L922 | PLAYABLE | ENGINE_SMOKE_PASS | 22/22 | — | ok | ok | 4 | no |
| L965 | PLAYABLE | ENGINE_SMOKE_PASS | 19/19 | — | ok | ok | 6 | no |
| L994 | PLAYABLE | ENGINE_SMOKE_PASS | 24/24 | L994>EXT#1 (2.2) | ok | ok | 5 | no |
| L999 | PLAYABLE | ENGINE_SMOKE_PASS | 26/26 | L999>EXT#1 (34.7) | ok | ok | 4 | no |
| L005_3 | PLAYABLE | ENGINE_SMOKE_PASS | 29/29 | L005_3>L005#2 (0.6) | ok | ok | 0 | no |
| L007_8 | PLAYABLE | ENGINE_SMOKE_PASS | 30/30 | L007_8>L007_7#2 (17.5) | ok | ok | 0 | no |
| L009_3 | PLAYABLE | ENGINE_SMOKE_PASS | 23/23 | L009_3>EXT#1 (19.6) | ok | ok | 0 | no |
| L011_2 | PLAYABLE | ENGINE_SMOKE_PASS | 41/41 | L011_2>L283#2 (25.3) | ok | ok | 0 | no |
| L021 | PLAYABLE | ENGINE_SMOKE_PASS | 67/67 | L021>L000#1 (1.1) | ok | ok | 5 | yes |
| L032 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L041 | PLAYABLE | ENGINE_SMOKE_PASS | 27/27 | L041>L612#3 (9.5) | ok | ok | 4 | yes |
| L050 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 2 | no |
| L052 | PLAYABLE | ENGINE_SMOKE_PASS | 19/19 | — | ok | ok | 4 | no |
| L077 | PLAYABLE | ENGINE_SMOKE_PASS | 24/24 | L077>EXT#1 (28.4) | ok | ok | 4 | no |
| L085 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L100 | PLAYABLE | ENGINE_SMOKE_PASS | 24/24 | L100>L004#1 (6.5) | ok | ok | 4 | no |
| L101 | PLAYABLE | ENGINE_SMOKE_PASS | 29/29 | L101>L000#1 (0.3) | ok | ok | 4 | yes |
| L108 | PLAYABLE | ENGINE_SMOKE_PASS | 24/24 | L108>EXT#2 (30.9) | ok | ok | 4 | yes |
| L114 | PLAYABLE | ENGINE_SMOKE_PASS | 26/26 | L114>L009#1 (2.6) | ok | ok | 4 | no |
| L140 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L149 | PLAYABLE | ENGINE_SMOKE_PASS | 26/26 | L149>L037#1 (6.8) | ok | ok | 4 | no |
| L160 | PLAYABLE | ENGINE_SMOKE_PASS | 22/22 | L160>EXT#1 (21.5) | ok | ok | 6 | no |
| L197 | PLAYABLE | ENGINE_SMOKE_PASS | 23/23 | L197>L000#5 (59.8) | ok | ok | 4 | no |
| L201 | PLAYABLE | ENGINE_SMOKE_PASS | 50/50 | L201>L001#3 (25.6) | ok | ok | 4 | yes |
| L263 | PLAYABLE | ENGINE_SMOKE_PASS | 22/22 | L263>EXT#1 (1.4) | ok | ok | 4 | no |
| L320 | IN_DEVELOPMENT | NOT_TESTED | 0/0 | — | — | — | 0 | no |
| L737 | PLAYABLE | ENGINE_SMOKE_PASS | 29/29 | L737>L169#2 (9.4) | ok | ok | 4 | no |
| L899 | PLAYABLE | ENGINE_SMOKE_PASS | 25/25 | L899>EXT#1 (5.5) | ok | ok | 4 | no |
| L998 | PLAYABLE | ENGINE_SMOKE_PASS | 46/46 | L998>EXT#1 (46.8) | ok | ok | 4 | yes |

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
