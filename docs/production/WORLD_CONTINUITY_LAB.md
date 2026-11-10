# Lost Frequency — World Continuity Prototype (2026-11-09)

Base: user-supplied `LostFrequency-v2.0.0-source(1).zip`, Godot 4.5.1.
This is a prototype patch, **not a certified Windows release**. The game roster,
canonical exits, original L001 scene, and existing 93 playable levels are not
replaced. Source-locked lore remains authoritative.

## Play the experiment

Open in the Godot 4.5.1 editor and import the project (`project.godot`), or run
`RUN_WORLD_LAB_WINDOWS.bat` with Godot 4.5.1 installed. On the
main menu choose **Experimental · Seamless 3D World Lab**.

- WASD, Shift, Ctrl, Space: move, sprint, crouch, jump.
- F9: mark current 3-D chunk with a small metal marker and persist the change.
- F10: return to main menu. Leaving and reentering retains chunk markers.
- Walk east past x=96 metres (chunk x=4) to enter **L001_PROXY** without
  destroying the current scene. This is a **non-canonical proxy/architecture
  demonstration**, *not* the real Level 1 content.
- Climb the alternating physical stairs. Five storeys are available, floors
  -2 through +2, at 4.5 metre intervals. The horizontal world is unbounded.
- Each chunk has stable, 24 m x 24 m floor coordinates. Only the vicinity of
  the player is loaded; other chunks are regenerated deterministically.

## Architecture and implementation

1. `core/world/ContinuityTopology.gd`: pure deterministic coordinate,
   topology, shared-face door, and stairwell rules. Shared face openings do
   not depend on generation order or chunk version.
2. `core/world/ChunkWorld3D.gd`: independent x/y/z streaming, nearest-first
   builds and distant unloading. Optional per-chunk serialized `versions` and
   `changes`, stored separately from the official story save.
3. `labs/Level0ContinuityLab.*`: functional scene containing physically
   continuous horizontal rooms and stairs, procedural light/props, and a
   visible same-scene district change from the Level 0-style zone into a
   Level 1-inspired **proxy**. It is not registered as a canon level or exit.
4. `ui/MainMenu.gd`: explicit opt-in experimental entry point.
5. `core/world/ChunkWorld.gd` and `levels/L000/L000.gd`: the regular Level 0
   retains its existing 2-D generator and strict lore. The chunk shift-version
   map and tactile wall marks are now scoped into the existing `SaveService`
   dictionary, so they persist when the story file is saved. Default use by
   other levels remains unchanged.

## State / compatibility

- The lab uses developer mode (never writes the story checkpoint). Its own
  `user://continuity_lab/world.json` save is read at launch, and F9 writes an
  atomic replacement with `.bak` fallback. The default seed is 1337.
- Official Level 0 chunk versions are saved as optional `chunk_worlds.L000`
  data in the ordinary story save; no schema version bump is required.
- Existing saves without the new optional fields work as before.
- Lab geometry uses existing generated MatLib shaders, not external images.
- The original `TransitionService` still swaps scenes for actual canon exits.
  That behavior is intentionally **not misrepresented as solved**. Cross-level
  world streaming is demonstrated by a proxy district in one active scene.

## Tests and limitations

Run the new engine test:

```sh
godot --headless --path . --import
godot --headless --path . --script res://tests/ContinuityTopologyTest.gd
godot --headless --path . res://tests/CompileAll.tscn
```

Then do real interactive tests: walk across 10+ horizontal chunk boundaries,
climb all five floors, mark an upper floor with F9, walk away enough to unload,
return, restart the app and confirm the marker remains. Check Story Mode L000
and its `qa_self_test` still work. QA existing 100 levels before releasing.

Current limitations:
- This environment did not have a Godot engine executable, so live engine QA,
  player collision/path traversal and Windows export are **not certified**.
- The five-floor limit is deliberate in this demonstration. Extending vertical
  streaming bounds is straightforward but needs new escape/fall safeguards.
- The L001_PROXY zone is intentionally small and simple; it is not the full
  original L001 geometry or canon noclip transition.
- There is no world-scale region manager, origin rebasing, asynchronous mesh
  building, runtime navmesh stitching, deep state migration, or network sync.
- The stair structures are physical ramps; precise last-tread clearances need
  validation in the actual engine. 3-D floor openings are also unguarded in
  this prototype, so this isn't release-ready level design.
- Procedural layouts are deterministic per chunk but do not yet implement
  macro-scale halls, cities, structured routes or generation constraints for
  all 100 different Backrooms levels.

## Recommended follow-up

Pass real QA, refine stair landings and collisions, benchmark frame timings,
then extract a `WorldRegionDirector` that composes truly compatible adjacent
regions from their authored grammars and preserves canonical non-Euclidean
transitions separately (portals / streaming handoff). Move one real Level 0
connected architectural district first, not all 100 levels at once.
