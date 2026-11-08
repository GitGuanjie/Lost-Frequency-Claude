# Lost Frequency — world integrity audit

> Manifest and existing QA evidence only. No Godot runtime was executed by this script.

Roster **100**, built **100**, declared exits **235**.
Built-to-built routes: **135** declared / **47** observed in QA snapshots.
From L000: **43** built levels manifest-reachable / **24** QA-snapshot-reachable.
Unreachable built levels: `L000_1, L000_2, L000_3, L001_1, L001_2, L001_3, L003_5, L005_1, L005_3, L007_7, L007_8, L009_3, L010_1, L011_2, L011_3, L013, L015, L016, L017, L018, L026, L027, L028, L030, L032, L037_1, L048, L052, L055, L058, L060, L073, L075, L077, L079, L085, L094, L096, L100, L140, L149, L160, L197, L200, L256, L263, L320, L404, L601, L737, L899, L906, L922, L965, L974, L994, L999`.

## Integrity issues
No structural manifest issues detected by this audit.

## Evidence interpretation
A QA-observed trigger is **not** evidence of a successful physical traversal. Missing QA observations are **not** proof of a broken route: triggers may stream in or require conditions.
Never mark a level PLAYABLE automatically based on this report.
