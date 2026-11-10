# Continuity lab patch — test evidence, 2026-11-09

Base artifact: `LostFrequency-v2.0.0-source(1).zip`.
Modified project version: `2.0.0-worldlab-prototype`.

## Completed verification in this environment

- Added `tests/static/test_continuity_patch.py`: **6 tests passed, 0 failed**.
  Checks source references, negative coordinates, shared border identity,
  alternating stair shafts, bounding geometry and main-menu integration.
- Ran **all existing static tests** on **unmodified source ZIP**:
  `243 tests; 180 failures; 2 errors`.
- Ran all static tests after changes (6 additional tests):
  `249 tests; 180 failures; 2 errors`.
- The 180 failures / 2 errors were already present in the user's source, mainly
  because legacy dev-stage tests assert older scene statuses and snapshots.
  This comparison is not proof of Godot engine compatibility; it merely shows
  the existing static failure count did not increase.
- Verified all original `levels/*` manifests and canon source files are
  unmodified by this patch. Only Level 0's existing script was updated with
  optional persistence support.

## Not performed

- Native Godot compilation / scene instantiation (no Godot engine executable
  or working network route to download it in this environment).
- Real physics walk from all five storeys, rollback/persistence through an
  actual engine session, 100-Level QA regression, GPU performance measurement,
  Windows EXE export, Windows QA.

**Result: prototype source available for engine validation; NOT a certified
playable release.**

## Quick launch

Godot 4.5.1 installed:

```bash
godot --path . res://labs/Level0ContinuityLab.tscn
```

Windows: open `RUN_WORLD_LAB_WINDOWS.bat` if Godot is on PATH; otherwise drag
`Godot_v4.5.1-stable_win64_console.exe` onto it. The main menu also includes
**Experimental · Seamless 3D World Lab**.

Run native tests as in `docs/production/WORLD_CONTINUITY_LAB.md`, and address
any GDScript parse/physics defects before shipping a Windows build.
