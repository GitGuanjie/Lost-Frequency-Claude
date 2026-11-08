# dev5 continuation / reproducibility

Baseline: `LostFrequency_v1.5.0-dev5_source.zip` (68 built scenes, 12 new development candidates).

1. Do not throw away current work or re-extract older archives. Verify project `config/version` first.
2. Install official Godot 4.5.1 (plus Windows export templates) and import the project on Windows.
3. Run `python -m unittest discover -s tests/static -v` and `python tools/world_audit.py --fail-on-issues`.
4. Run `.\RUN_DEV5_QA_WINDOWS.ps1 -GodotExe '<path_to_godot_console.exe>' -Story`. Test each dev5 level in its own fresh `reports/qa/v150_dev5/<sid>.json` plus logs. Do not mark level playable until physical exits, collision, player spawn, QA screenshots, and human play are checked.
5. Fix actual errors, particularly script parsing, stairs and correct exit occupancy/condition handling; verify L009→L011.
6. Native Windows build: `.\EXPORT_DEV5_WINDOWS.ps1 -GodotExe '<path_to_godot_console.exe>'` after QA passes. Test GPU FPS and screenshot visually before distributing as stable.
7. Keep the canon source policy: no convenient invented level transitions, no invented hostile entities. Continue developing remaining 32 slots with genuinely different spaces.
8. Keep commit history, a concise `STATUS.md`, and new verified evidence; avoid storing huge raw QA pass arrays.

Known result: 28 static tests pass, world manifest audit passes, **Godot is unavailable in this environment**; no new scene has been engine-certified.
