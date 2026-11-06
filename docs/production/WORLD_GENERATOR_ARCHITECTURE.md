# World generator architecture

## Layers
- **Autoload services**: `Settings` (input map, buses, accessibility), `LevelRegistry` (100-entry roster +
  per-level manifests; never invents status), `SessionState` (STORY / DEVELOPER / QA scopes, seeds),
  `SaveService` (versioned atomic saves, backup and corruption quarantine, V62 migration),
  `TransitionService` (rule-checked exits, async loading, `@origin`, release boundary),
  `AudioSynth` (runtime synthesis), `MatLib` (procedural materials), `Telemetry` (frame sampling),
  `Overlay` (all UI).
- **LevelBase** (`core/world/LevelBase.gd`): the contract. It handles deterministic `rng`, the
  environment, the light pool, the soundscape, safe spawning (floor raycast and capsule clearance,
  with a spiral search if blocked), manifest-validated exits, checkpoints and QA descriptors.
- **GeoKit**: batched geometry with one mesh per material and box/cylinder collision tagged by
  footstep surface. UVs are world-projected metres, so patterns continue across pieces. It provides
  primitives for walls with openings, arcades, stairs with smooth collision, ramps, slabs and
  emissive panels.
- **ChunkWorld**: deterministic streamed chunks keyed by `(cx, cz, version)`. Border openings
  depend only on border identity and on the (stable) kinds of both sides, so rebuilt chunks always
  reconnect. Optional *peripheral shift* rebuilds chunks that are out of frustum and don't contain
  the player.
- **LightPool**: many authored fixtures, few real lights (nearest-N assignment with fade-in, flicker,
  group removal on chunk unload).
- **WaterVolume / LadderVolume**: swim (buoyancy, oxygen, underwater tint and low-pass) and climbing.
- **ExitTrigger** kinds: walk_in, interact, noclip (sustained push into a volume), fall, dwell,
  condition.

## Level grammars, not one generator
Each level owns its grammar in its script. Level 0 uses a cell maze (randomised Kruskal plus loops
plus carved rooms, doorway or full openings), with zone kinds chosen by smooth regional noise
(pillars), hash singletons (arches, holes, blackout, red) and distance gating (anomalies grow
farther out), plus sunken stair rooms. Other levels define their own grammars (see their scripts and
dossiers). The duplication detector in QA compares material and geometry histograms across levels
to catch palette swaps.

## Determinism and evidence
Seeds are derived per level from the story save seed (story) or the session or QA override. QA
checks same-seed reproduction and three-seed divergence for procedural levels. Navigation for QA is
baked at runtime from static colliders. The walker bot drives the real `CharacterBody3D` along
the navmesh path and must fire the exit through its normal trigger logic.

## Infinity
"Infinite" levels are finite streaming windows (radius 2 chunks loaded, unload beyond 3) over a
32-bit coordinate space with stable world coordinates. They do not simulate infinity.
