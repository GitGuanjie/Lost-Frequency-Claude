# LOST FREQUENCY — ContinuityLab v4 (experimental source)

**This is an unverified Godot 4.5.1 source experiment, not a Windows game build.**
All 100 canon levels and the story/exits are retained from the v2.0.0 source.
The experimental world is entered through the main menu option
`Experimental · Seamless 3D World Lab`.

## What v4 adds

- Deterministic **8 × 8 chunk superdistricts** (192 × 192 metres), over five
  levels from `y = -2` to `y = +2` (vertical span 22.5 metres).
- Two orthogonal two-chunk-wide street/hall networks per superdistrict;
  broad shared-face doorways across district boundaries. Traversal remains
  in one scene and physics world, not separate canonical Level scenes.
- Four aligned superhub chunks form an 8 × 8 metre vertical opening; all
  four levels above the solid bottom have real collision-floor bridge strips.
- Existing 4 × 4 macro-region atria remain supported and share the same
  floor carving and railing functions.
- Architecture variants: threshold nexus, vertical foundry, abandoned transit,
  hanging city, archive, service cathedral and silent cistern. These are
  geometry/lighting vocabularies, not photorealistic asset imports.
- A persistent survey console at each superdistrict's centre (floor 0).
  It switches the loaded spine lighting and survives restarting that seed.
- `F2` searches nearby unvisited hubs; explored map identifies hubs (`H`),
  spines (`=`), normal atria (`A`), clues (`*`) and user markers (`M`).
- Changes to the **experimental** 3D streamer: dirty-state autosave every
  12 seconds during play, immediate flush on the world swap/menu/close/focus
  loss, and immediate deactivation of evicted chunk collision objects.

## Controls

- WASD + mouse, Ctrl/C crouch, Shift run, Space jump, E interact, F light.
- F2: locate nearest unvisited 8x8 superdistrict hub (no teleport).
- F4: change local decorative fitout. Border routing, voids and bridges
  remain determined only by seed and world coordinates.
- F5/F6: cycle saved world seeds / create new seeded world.
- F8: map; F9: persistent marker in current chunk; F10: save + menu.
- Try walking east/north to the 8x8 central nexus, at chunk coordinates
  `(3..4, y, 3..4)`. The district boundary at x=4 leads into a deliberately
  non-canon Level 1 warehouse **proxy**, not the real canonical Level 1.

## QA

On Windows, with Godot 4.5.1 and Python 3 installed:

`RUN_WORLD_LAB_V4_QA_WINDOWS.bat "C:\path\to\Godot_v4.5.1-stable_win64_console.exe"`

The batch imports assets, runs CompileAll and v2/v3/v4 headless topology
checks, runs 29 offline Python regression tests, then launches the lab.
Use `--qa-only` as second argument for headless-only tests.

Manual acceptance: start lab, step around the x=3/4 and z=3/4 shared
borders, climb all five storeys, traverse the two east-west suspended
bridges, toggle a hub terminal and watch lighting update, move far enough
for chunks to unload/reload, restart and verify discoveries and markers.
Also test negative coordinates and F5/F6 seed isolation. Record GPU fps,
peak memory, build stalls and QA logs.

## Boundaries and honest limitations

This is **not** a full, canonical, non-Euclidean Level 0 to Level 1 transition;
that still requires portal/transfer architecture and an explicit canon route.
The v4 world is not yet a complete Minecraft-equivalent world simulation:
no persistent entity AI, terrain deformation, global pathfinder or large-scale
sector transport. The rendering vocabulary is intentionally lightweight,
not finished 4K megastructure art. Geometry is still authored with GeoKit.

The v4 Godot/Windows native QA scripts are supplied, but **not executed here**.
Python invariants are not proof of walkable physical collisions or correct
compiled GDScript. Do not treat the package as certified playable until the
Windows/Godot checklist passes.

See `docs/production/WORLD_CONTINUITY_LAB_V4.md` for structure and further work.
