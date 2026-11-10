# World Lab v3 static verification — 2026-11-09

- Input: `LostFrequency-v2.0.0-ContinuityLab-v2-FULL-SOURCE.zip`.
- Scope: `ContinuityTopology.gd`, `Level0ContinuityLab.gd`, one backward
  compatibility static test, new Python/Godot tests and documentation.
- Test command: `python3 -m unittest discover -s tests -p 'test_worldlab*static.py' -v`
- Result: **16/16 tests passing** (9 previous contracts, 7 new macro tests).
- Structural checks: 4 core quadrants align at one void, bridge strips cross
  each x seam, no stair/void overlap, baseline 4-way portals stay passable,
  save seed and relay state isolated, original canon files present.
- Additional native test: `tests/ContinuityMacroStructureTest.gd` (supplied
  but **NOT EXECUTED**).
- Native Godot, collision, FPS, Windows game EXE: **NOT TESTED** — no Godot
  binary in authoring environment. Source files are not yet runtime-certified.
- No new third-party images, models, or restrictive assets introduced.
