# Lost Frequency — Continuity Lab v3: cross-chunk macro-architecture

Built from the user-provided `LostFrequency-v2.0.0-ContinuityLab-v2` source on
2026-11-09. **Prototype, not a certified Windows release.** Godot 4.5.1 is
required for native QA; no engine was available in the authoring environment.

## Exactly what changed

1. **4×4 chunk macro master plan:** `ContinuityTopology.macro_structure()`
   selects the same large structure for every chunk of a region. The initial
   Level 0 region always contains `grand_atrium`; other regions deterministically
   select hanging archives, riser courts, industrial concourses or solid halls.
   Changing a local room version cannot modify this macro plan.
2. **One connected 2×2 chunk, 48×48-metre hall:** adjacent core chunks share
   11 m-wide doors instead of separate 4 m openings. Additional openings at the
   inner corners connect a true 10×10-metre vertical well across all four core
   chunks. These are explicit paired-face contracts, not separate random calls.
3. **Multi-floor well:** core-floor slabs are cut around the existing stair
   shafts and a 5×5 m quadrant well. The bottom floor `-2` is solid, floors
   `-1` through `+2` expose a shared multi-storey void. A 3 m-wide **physical
   east–west bridge** in each north/south row crosses the well on every floor.
   Perimeter rails leave bridge entries open and line bridge sides. Geometry
   overlaps and real collision need Godot walkthrough verification.
4. **Shared structures:** core chunk fit-out changes by architectural family,
   including canopy ribs, suspended beams, columns and non-colliding decorative
   supports. F4 changes *overhead decorative fit-out* while preserving the
   floor, walls, well and bridge geometry.
5. **Persistent environmental interaction:** each atrium region has one relay
   at its 0th-floor anchor. Press E to toggle the relay; saved state updates
   the lighting of already-loaded core chunks. All changes remain isolated to
   the selected seed's existing JSON save file.
6. **Exploration & telemetry:** the F8 map marks visited atrium quadrants with
   `A`. The HUD names the large architecture type and shows loaded triangles
   and collider counts for profiling.

The canonical 100 levels, their game transitions, and the original `Level 0`
scene are unchanged. The `L001_PROXY` in this lab is still an architecture
proxy; this is **not** seamless entry into the original Level 1.

## Playable geometry contract

- All ordinary four-direction portals remain in safe edge corridors.
- The core interior has wide face-aligned hall apertures and separate well
  apertures. Each pair of neighbours computes matching openings from stable
  coordinates without mutable RNG state.
- The incoming staircase uses the alternating shaft at x ≈ 6/15 and
  z ≈ 5.4..18.6. Well corners occupy the inner x/z 5 m of each core chunk,
  not the stair slots.
- A core floor is split on opening boundaries and only solid cells get slabs.
  The east–west bridge strips remain solid. With no cutout, v2 floor code runs.
- No tall furniture is placed on the atrium core's main circulation paths.

## How to test

1. Extract full source and open `project.godot` in Godot 4.5.1. Or run
   `RUN_WORLD_LAB_V3_QA_WINDOWS.bat` with the path to Godot console.
2. Open **Experimental · Seamless 3D World Lab** from the main menu.
3. Go east/north from spawn into chunk `(1,0,1)`, and continue into the four
   chunks `(1,0,1)`, `(2,0,1)`, `(1,0,2)`, `(2,0,2)`.
4. Verify that all four sides have usable hall entrances, the four exposed
   quadrants form a continuous atrium, the east–west bridges can be crossed,
   and the stairways remain usable on all five floors.
5. In `(1,0,1)`, interact with the relay near the southern side of the hall;
   move away until chunks unload, then return and restart: its state and lights
   should persist. Use F4 to change the overhead fit-out without changing
   passages or bridge layout.
6. F6 to create a new seed, F5 to return to previous worlds, F9 to mark a
   chunk, F8 to inspect the visited-area map. Ensure all saves stay separate.
7. Stress test ≥50 horizontal chunk crossings, negative coordinates, repeated
   menu returns, 100 source levels and all story regressions.

Automated source tests performed:

```bash
python3 -m unittest discover -s tests -p 'test_worldlab*static.py' -v
```

Native tests supplied but **not run**:

```bash
godot --headless --path . --import
godot --headless --path . res://tests/CompileAll.tscn
godot --headless --path . --script res://tests/ContinuityTopologyTest.gd
godot --headless --path . --script res://tests/ContinuityMacroStructureTest.gd
```

## Limitations and future work

- The well is 10×10 m and spans five floor bands, not a kilometre-scale true
  megastructure; future versions can compose larger 8×8 macro blueprints.
- Stairs, rails, 11 m portals and bridge collision were mathematically checked
  but not run in Godot. Some pre-existing v2 geometry may still need fixes.
- No 4K background textures, new external art, AI enemies, network code or
  arbitrary 100-level seamless world management was added.
- The large architecture currently uses procedural GeoKit mesh materials. It
  is a geometry testbed, not final art or canon-faithful Level 0 architecture.
- Full gameplay QA, Windows executable export and GPU profiling are required
  before calling it playable or merging into a public release.
