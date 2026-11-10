# Claude Code / Codex handoff — Lost Frequency ContinuityLab v3

Repository baseline: user's `LostFrequency-v2.0.0-ContinuityLab-v2` complete
Godot 4.5.1 project, patched only in the experimental world laboratory. Read:

1. `docs/production/WORLD_CONTINUITY_LAB_V3.md`
2. `core/world/ContinuityTopology.gd`
3. `labs/Level0ContinuityLab.gd`
4. `core/world/ChunkWorld3D.gd`
5. `tests/ContinuityMacroStructureTest.gd` and `tests/test_worldlab_v3_static.py`
6. `docs/canon/CANON_POLICY.md` and `reports/QUALITY_SCOREBOARD.md`

Priority 1 is NATIVE CERTIFICATION, not more generic room dressing:

- Get Godot 4.5.1, run the source import, CompileAll, both native topology
  suites and then `res://labs/Level0ContinuityLab.tscn` in an actual renderer.
- Explore all four atrium quadrants `(1,0,1)` `(2,0,1)` `(1,0,2)` `(2,0,2)`
  and floor levels -2..+2. Use physics ray probes and a walker bot, not static
  assertions alone, to certify portals, stair landings, well bridges, railings,
  floor slab gaps, safe falls and the persistent relay interaction.
- Check 3 random seeds, negative X/Z, 50 streamed chunk crossings, unload /
  re-enter, saved relay state, F4 fixed geometry, F5/F6 world separation.
- Measure CPU build spikes, triangle/collider counts, GPU FPS on the heaviest
  views and collision broadphase cost. Reduce number of overlapping physical
  wall colliders and slabs if necessary; never delete portal safety.
- If native parsing fails, repair the lab in a separate branch, and rerun every
  test; do not claim finished until manual Windows runtime smoke passes.

Priority 2, only after this is green:

- Upgrade from the 2x2 core to planner-authored 4x4 / 8x8 structures with
  nested routing, multi-level platform networks, richer art and light design.
- Incorporate real source-derived geometry from canonical L000 and L001 into
  an explicit seamless world manager. Preserve non-Euclidean portals where
  the original wiki says level adjacency is not spatial. Do not overwrite
  source-locked exits or invent canon entities.
- Add world snapshots/deltas, LOD, multimesh batching, streaming worker
  budget, and seed regression visualization.
- Run the legacy 100-level QA and story suites, including Windows standalone
  export on a real machine, before release claims.

Do not treat a compilation pass or a still image as physical traversal
certification. Keep the experimental mode and story-mode saves isolated.
