# Lost Frequency — Continuity Lab v2: procedural architecture + exploration

**Branchless source patch to the user-supplied v2 World Continuity Lab**, dated
2026-11-09. Non-canonical, developer-mode experiment; no modification to the
100 source-locked level manifests, transition registry, original Level 1, or
current story save. Godot 4.5.1 source only; **Windows and physics QA pending**.

## Implemented in code

- All **four** chunk wall faces are authored. East/west neighbours derive an
  identical seeded portal from the same owner coordinate; north/south do the
  same. This addresses the earlier two-wall-only layout. Faces may overlap
  as intended when both chunks are loaded to make partially streamed edges
  safer; player traversal/physics still requires native Godot QA.
- A **4×4 chunk macro theme** persists across a neighbourhood. Lab themes:
  yellow maze, vaulted offices, service annex, abandoned archive, structural
  gallery, silent quarters; the east proxy has industrial alternatives.
- Eight **local room motifs** (crossroads, archive, machinery, column gallery,
  shrine, storage, reading room, observation), and a stable entry hall in the
  initial 0:0:0 chunk. Interiors contain shelves, machinery, ribs, beams,
  overhead panels and, on selected motifs, four side galleries with >4 m
  central doorways. Props were kept clear of the central cross and stairs.
- The five-floor stair topology from v1 remains. Added **side / bottom rails**
  around floor openings, leaving the upper landing open for the incoming ramp.
  Stair collision, reachable paths and guardrail clearance are *not* engine
  certified.
- Rare deterministic **discoveries** (`Interactable`) with a label and note.
  Once collected, their state persists per chunk after unload and restart.
- **Exploration map** with visited chunks, landmarks and manually marked
  positions on the current floor; explored count in the HUD.
- **Reconfigurable rooms**: F4 increments that chunk's variation version, but
  fixed four-way doors, macro theme and stair topology never change. F9 is a
  pure marker toggle and redraws the chunk **without** changing its variation.
- **Multiple worlds**: F6 selects a fresh seed, each saved in a distinct
  `user://continuity_lab/world_<seed>.json` file. F5 cycles an index of
  previously created seeds, including the original 1337 world (which retains
  the previous `world.json` path). Never deletes earlier worlds.
- **Staggered initial chunk loading**: the 3×3 floor is ready before spawn,
  then neighbouring floors stream in over frames instead of making an
  immediate 27-chunk build during startup.

## Controls

| Key | Action |
| --- | --- |
| WASD / mouse / Shift / Ctrl / Space / E | movement / look / sprint / crouch / jump / interact |
| F4 | Reshape the current room, preserving portals and stairs |
| F5 | Cycle through previously generated and saved worlds |
| F6 | Generate a new random world seed (old worlds retained) |
| F8 | Toggle 9×9 explored-area map for the current floor |
| F9 | Toggle persistent chunk marker |
| F10 | Exit the lab and save to the main menu |

Original Level 0 and the `L001_PROXY` are physically adjacent *only in this
laboratory*. The real canonical Level 0 → Level 1 non-Euclidean transition is
**not** changed; it still uses the base project's scene transition system.

## Test commands

Offline static source contract (performed by this delivery):

```bash
python3 -m unittest discover -s tests -p 'test_worldlab_v2_static.py' -v
```

Godot native checks (**not available in the author's container**):

```bash
godot --headless --path . --import
godot --headless --path . res://tests/CompileAll.tscn
godot --headless --path . --script res://tests/ContinuityTopologyTest.gd
godot --path . res://labs/Level0ContinuityLab.tscn
```

On Windows, use `RUN_WORLD_LAB_V2_QA_WINDOWS.bat` with the Godot console
executable on PATH or pass its path as first argument. Then manually test:

1. Visit all four adjacent chunks from the origin; check there are **no
   invisible walls or falls** at the borders (door locations vary by seed).
2. Climb every floor, and descend each stair; inspect railings, ceiling
   clearance and ramp transition around y=4.5 m boundaries.
3. Cross east to x>=96 m, walk back west, verify the same player and scene
   remain alive and that the warehouse proxy appearance changes continuously.
4. F9 marker, F4 room reshuffle, exit and restart. Both should survive.
5. Collect a discovery with E. Leave until its chunk unloads, revisit and
   restart: discovery must stay absent and the map progress must persist.
6. F6 twice, F5 through all saved seeds, verify each seed's state remains
   isolated and the old 1337 world is still accessible.
7. Long walk (>=30 chunk transitions) with frame telemetry, and test negative
   X/Z keys and high/low floors for collision and streaming stalls.
8. Run original story Level 0, L009→L011, and full 100-level regression after
   any actual engine errors are fixed. Do not claim release acceptance until
   these and native Windows smoke tests pass.

## Caveats

- No engine executable or outgoing download route existed in this authoring
  environment. **The code is not compiled or runtime certified here.**
- The level's 3D world remains capped at floors -2..+2 and radius 1 chunk
  horizontally / vertically for live loading. Horizontal space has no fixed
  map boundary but is not a physically infinite memory resident world.
- These motifs are test geometry, not polished final assets or a sophisticated
  graph-grammar procedural generator; a macro path planner and real 100-level
  world composition remain future work.
- Interactive discoveries are deliberately lab-only and not canonical lore.
  Source-locked exits and entities are not altered.
- The screenshot/film-quality target, genuine 4K skyboxes, AI entities,
  navigation baking, player collisions across all seams, and real GPU
  performance were not verified or newly implemented in this patch.
