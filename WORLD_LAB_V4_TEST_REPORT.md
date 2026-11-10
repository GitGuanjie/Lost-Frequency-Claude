# ContinuityLab v4 — QA record (2026-11-09)

## Actual tests executed in authoring environment

```
python -m unittest discover -s tests -p 'test_worldlab*static.py' -v
```

**29 / 29 passed**: 9 inherited v2, 7 inherited v3, 13 new v4
contract/invariant checks. These cover synthetic portal ownership over a
35×35 sampling grid, negative coordinates, 8×8 trunk connectivity across
multiple superdistricts, four-piece hub opening alignment, bridge support
and separation from stair voids, expected source hooks, autosave and source
isolation. The Python spatial oracle is not a Godot physics simulator.

Full diff was compared against the supplied v3 full-source ZIP by SHA256:
- 3714 baseline files, 3711 byte-for-byte identical.
- Exactly 3 existing experimental files changed:
  `core/world/ChunkWorld3D.gd`, `core/world/ContinuityTopology.gd`,
  `labs/Level0ContinuityLab.gd`.
- 7 new source/QA/readme files (this report included, now 7).
- Canonical `levels/` contents, `data/canon/`, `project.godot`, and
  `autoload/TransitionService.gd` remain unmodified.

## NOT executed; mandatory before calling this playable

Godot 4.5.1 native import, CompileAll, v2/v3/v4 headless topology scripts,
physical bridge and stair walking, in-game lighting interactions and
session save, real Windows GPU FPS/latency/memory benchmarks, and Windows EXE
export. **No Godot binary is installed in this authoring environment.**

`RUN_WORLD_LAB_V4_QA_WINDOWS.bat` and
`tests/ContinuitySuperDistrictTest.gd` are delivered but not executed.

Known architectural boundary: the `L001_PROXY` lab region is not a proper
canonical scene transition and must not be reported as one.
