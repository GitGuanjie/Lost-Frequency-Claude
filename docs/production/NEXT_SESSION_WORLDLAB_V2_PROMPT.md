# Claude Code handoff — Continuous World v2 (Godot-first)

Repository: user's local Lost Frequency v2.0.0 source plus WorldLab v1 & v2.
Non-canon experiment at `labs/Level0ContinuityLab.gd`. Do NOT overwrite the
production Level 0 or any canonical route as part of this task.

1. Install/run Godot 4.5.1 stable console; inspect the source first, particularly
   `core/world/{ContinuityTopology,ChunkWorld3D}.gd`, `labs/Level0ContinuityLab.gd`,
   `tests/ContinuityTopologyTest.gd` and docs `WORLD_CONTINUITY_LAB_V2.md`.
2. Run resource import, CompileAll and the full topology test. Fix any errors
   by submitting minimal code patches, then record exact return codes and logs.
3. Open the lab in native Forward+ and walk 30 chunk boundaries, including
   negative coordinates and the x>=96 industrial region. Test four-way
   portals, all five storeys, rails, transitions and frame budget. Repair
   stair collision if needed; don't claim a pass based on a static script.
4. Restart the engine after F4/F9/collect and F5/F6; verify deterministic
   room types, discoveries, markers and multi-seed save isolation. Test return
   from lab to main menu and official story after a lab session.
5. Run the entire source-locked 100-level QA suite, original Story route
   chain and a Windows executable smoke test. Preserve original 93 PLAYABLE.
6. Once certified, incrementally replace fixed 24m room templates with a
   *constraint-solved architectural grammar*: 4/8/16-chunk landmarks,
   multistorey galleries/bridges, branch rooms, underpasses and maintenance
   loops. Enforce boundary-port compatibility, traversal connectivity and
   safe spawn via physical graph/path testing across multiple seeds.
7. Implement a persistent world-region streaming director only after all
   current lab tests pass. True canonical L000->L001 noclip transitions remain
   separate and will require scoped design, not proxy-region trickery.

Make the game richer but NEVER certify a feature without real-engine evidence.
Track: levels preserved, seeds tested, crossings visited, nav failures,
collisions, p95 and p99 frame times, draw calls, triangles, memory and
Windows smoke outcome. Document reproducer coordinates for any failure.
