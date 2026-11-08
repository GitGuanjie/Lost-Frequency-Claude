# Lost Frequency dev6 continuation

Do not re-extract the original m5 archive. Start from dev6 source and verify project.godot config/version.

1. Install official Godot 4.5.1 and matching export templates; run `python -m unittest discover -s tests/static -v`, `python tools/world_audit.py --fail-on-issues`, then `RUN_DEV6_QA_WINDOWS.ps1 -GodotExe <absolute console path>`.
2. DO NOT mark the 16 new scenes PLAYABLE until Godot import, script parse, collisions, actual traversal, screenshots, save/load and Windows manual play succeed. In particular, check the exterior lighthouse ramp (L007_7), casino machines (L005_1), sky-island bridges (L030), red city masking (L011_3), storm gate (L003_5).
3. L069 vehicle driving / 17-hour exit is intentionally unimplemented; the tunnel condition stays locked, not a free teleport. L017 and L965 source exits have no known destinations; do not fabricate them.
4. F6 directed route preview only covers declared links (dev) or witnessed links (story); it is not a guarantee that a physical trigger works.
5. Eliminate provisional arrivals by building sourced, physically traversable dedicated entrances. Fix L009 to L011 original story failure with Godot evidence.
6. Pursue the remaining 16 slots without reducing scene quality, update QA evidence and keep commits small. After Godot validation produce the official Windows build using EXPORT_DEV6_WINDOWS.ps1.

Inspect `V150_DEV6_REPORT_CN.md` for exact limitations and release blockers.
