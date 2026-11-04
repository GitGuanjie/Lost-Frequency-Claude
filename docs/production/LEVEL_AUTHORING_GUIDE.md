# Level authoring guide (contract for every level)

Read this before building a level. The reference implementation is `levels/L000/`.

## 0. Canon first
- The **only** source is the level's dated snapshot (`docs/canon/levels/<SID>.md`
  dossier; raw text at `/tmp/claude-0/-home-user-claude-EO/b1bbc6d3-61e8-5445-bc39-785c3bc288f0/scratchpad/wiki_text/<SID>.md`).
  This is the English Backrooms Wikidot page captured 2026-11-04. No Fandom, Kane Pixels or memory.
- Every mechanic, material choice, sound, hazard, entity and exit must map to a dossier
  **SOURCE FACT** row, or be explicitly labelled **ADAPTATION** with a one-line reason in
  `level.json` `notes` (e.g. "cave layout grammar is ours; page gives no map").
- Entity policy: spawn nothing the page doesn't support. If the page says devoid of
  entities, the level is empty, and that emptiness is intentional, high-quality design.
- Compact canon spaces stay compact. Don't add towers, combat, collectibles or quests the
  page doesn't support. Verticality only where the page supports it.

## 1. Files you create (and nothing outside them, except your dossier's Test evidence)
```
levels/<SID>/<SID>.gd      extends LevelBase; build() + optional level_process()
levels/<SID>/<SID>.tscn    root Node3D with the script; export var stable_id = "<SID>"
levels/<SID>/level.json    manifest (schema below)
reports/screenshots/<SID>_<shot>.jpg   max 2 committed stills, 640x360, quality 0.70 (≤ ~30 KB each)
reports/qa/levels/<SID>.json, reports/qa/levels/<SID>_capture.json   QA outputs
docs/canon/levels/<SID>.md  only replace the "## Test evidence" section
```
Do **not** edit `core/`, `autoload/`, `ui/`, `tests/`, `data/`, or other levels. Level-specific
helpers go in your level script (or `levels/<SID>/*.gd`). If you need a framework change,
work around it locally and describe the need in your final report.
Size budget: level script ≤ 30 KB. No binary assets: materials come from shaders (MatLib)
and sound from AudioSynth.

`.tscn` template:
```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://levels/<SID>/<SID>.gd" id="1_s"]

[node name="<SID>" type="Node3D"]
script = ExtResource("1_s")
stable_id = "<SID>"
```

## 2. Manifest `level.json`
```json
{
  "stable_id": "L005", "scene": "res://levels/L005/L005.tscn",
  "status": "IN_DEVELOPMENT",            // the integrator sets PLAYABLE after QA review
  "qa_status": "NOT_TESTED",
  "procedural": true,                    // true only if the seed changes the layout
  "arrivals": ["start", "from_L019"],
  "signature": "one sentence: what makes this place itself",
  "mechanics": ["short_ids"],
  "exits": [
    {"id": "L005>L006#3", "to": "L006", "trigger": "walk_in", "label": "Followed the heat down to ...",
     "confidence": "CONFIRMED+DANGEROUS", "basis": "SOURCE", "source_section": "Entrances and Exits",
     "source_quote": "verbatim ≤25 words from the page", "hint": "non-spoiler clue",
     "arrival": "from_L005"}
  ],
  "fail_states": [], "entity_policy": "...", "notes": "ADAPTATION notes, known gaps"
}
```
- Exit **ids must be the ids in `data/canon/transitions.json`** (`<SID>>LXXX#n`). The lint
  fails a SOURCE exit whose id isn't there. Destinations outside the built set are fine: the
  game shows "documented route, not built in this release" and offers an honest release-
  boundary return. Don't invent edges. `"to": "@origin"` means "back where you came from"
  and only applies where the page says so (e.g. Level 188's entry window).
- Arrival tags are `from_<SID of origin>`. Provide one for every built-slice edge that
  enters your level (listed in your task), plus `start`.

## 3. LevelBase API (core/world/LevelBase.gd)
- Override `build()`. Use `rng` (seeded from `level_seed`; deterministic). Override
  `level_process(delta)` for mechanics, `on_player_ready()` for first-frame logic.
- `rules` dict before the player spawns: `gravity, flashlight ("allowed"|"weak"|"fails"|"none"),
  walk_speed, sprint_speed, jump_velocity, oxygen_seconds, view_distance, reverb_room, reverb_wet`.
- Environment: `indoor_env(ambient, energy, fog_color, fog_density)` or
  `outdoor_env(sky_top, sky_horizon, ground, Vector2(sun_pitch, sun_yaw), sun_color, sun_energy, fog_color, fog_density)`.
  Then tweak `environment` directly (exposure, glow, adjustment_*, volumetric fog only if needed).
- `kit("Name") -> GeoKit`, then call `.commit()` at the end. `lights.setup(pool_size, shadows)`
  then `lights.add_anchor(pos, color, energy, range, flicker, group)` (nearest-N real lights).
  `sound.bed(recipe, params, db)`, `sound.emitter(recipe, pos, params, db, max_dist)`,
  `sound.oneshot(recipe, params, min_s, max_s, radius, "[caption]", db)`.
- `add_arrival(tag, pos, yaw_deg)`; `add_exit(edge_id, kind, center, size, prompt) -> ExitTrigger`
  (kinds: walk_in, interact, noclip, fall, dwell, condition; set `.hold_seconds`, `.fall_y`,
  `.condition = Callable`). `make_exit(..., parent)` for exits inside streamed chunks.
- `add_note(id, title, text, center)` for in-world documents. **Paraphrase** in your own
  words, with no long page quotes; a note may cite "per M.E.G. survey" style framing only if the
  page has that voice. `add_interactable(center, size, prompt, callable)`.
- `checkpoint(tag)` at safe, sourced rest points. `add_shot(name, pos, target, extra)`;
  override `qa_capture_plan()` when stills need preparation (see L000).
- QA hooks: in QA mode (`SessionState.is_qa()`), make one sourced exit deterministically
  reachable from `start` (as L000 does with its flickering wall in chunk (1,0)). The walker
  bot must be able to walk there on the navmesh and fire it through the normal trigger logic.
  Never place a fixture outside QA mode.

## 4. GeoKit (core/world/GeoKit.gd)
`box(center,size,mat,faces,collide,surface)`, `box_mm(min,max,...)`, `slab(x0,z0,x1,z1,y_top,thick,mat,faces)`,
`wall(a,b,height,thick,mat,openings=[{at,w,h,sill}],faces)`, `arch_wall(...)`, `ramp(a,b,width,thick,mat)`,
`stairs(start,dir,width,rise,steps,mat,run,solid)` (visual steps + smooth collision),
`cylinder(center,r,h,mat,sides)`, `panel(center,sx,sz,mat,seed,flicker)` (emissive ceiling panel),
`quad(...)`. Faces flags `PX NX PY NY PZ NZ ALL SIDES`. One mesh per material per kit.
Footstep surfaces derive from material names (carpet/tile/wood/metal/grass/dirt/sand/snow/water/plush),
or pass `surface`. Walls are cheap; aim for < ~6000 collision shapes in a loaded area.
Big or "infinite" levels use `ChunkWorld` (core/world/ChunkWorld.gd; see L000), and the docs must
say the playable world is a finite streaming window.

## 5. Materials, light, sound
- `MatLib` presets (autoload/MatLib.gd): l0_*, concrete, concrete_dark, pool_tile, plaster, metal,
  rust, wood_floor, brick, asphalt, grass, dirt, sand, rock, trim_white, void_black, glass,
  unlit_black, panel, water_pool. Make level looks with
  `MatLib.define("l5_carpet", {params}, "base_preset")` (surface.gdshader uniforms: albedo_a/b,
  noise_scale, pattern 0-15 (1 tiles, 2 stripes, 3 planks, 4 bricks, 5 dots, 6 carpet(+motif),
  7 ceiling tiles, 8 chevron, 9 checker, 10 damask, 11 rock strata, 12 grass, 13 sand ripples,
  14 offset tiles, 15 terrazzo), pattern_scale/color/strength, grout_*, roughness_a/b,
  metallic_value, bump_strength, stain_*, grime_*, wetness, emission_color/energy/flicker,
  caustics + water_y, peel_*). Use level-prefixed names, e.g. `l37_tile`.
- Water: `MatLib.register("l7_sea", MatLib.water({shallow_color, deep_color, absorption, clarity,
  wave_height, wave_scale, foam_amount, dark_surface}))`, plus `WaterVolume.setup(min,max,mat)`.
  The player swims with buoyancy, oxygen and an underwater tint automatically.
- Emissive panels: `MatLib.register("l5_sconce", MatLib.panel(color, energy))`.
- `LadderVolume.setup(min,max)` (add as a child) makes climbable shafts/ladders.
- Audio recipes (AudioSynth): fluorescent_hum, room_tone{cutoff,rumble}, water_bed{bright},
  drip{freq}, footstep, wind, crickets, transformer{base}, crackle, pipe_clank{f}, rain, thunder,
  distant_boom, pad{root,chord,bright}, chiptune{bpm,scale,root}, static, creak{freq}, splash,
  knock{hits}, music_box{notes,root}, heartbeat, whisper, scratch, ui. Combine for identity.
  Every recurring sound gets a `[caption]` subtitle.
- Light: a few strong, motivated sources beat uniform brightness. Use LightPool for many
  fixtures, a DirectionalLight (via outdoor_env) for sky levels, emissive panels for distance.

## 6. Quality bar (the integrator reviews screenshots)
- A player who knows the page must recognise the place from one still.
- One or more **authored signature anchors** (hand-placed coordinates) plus procedural fill
  where the page implies scale. No uniform box grids, no palette swaps of L000.
- The defining mechanic is a stateful system (darkness rules, water and oxygen, heat, peripheral
  shift, door rules, sleep exits...), not a sign.
- Exits are physically discoverable through non-spoiler affordances (sound, light, architecture)
  that match the page's wording. No glowing portals, no floating text in the world.
- Spawn on solid floor with clearance. No floating stairs, invisible walls at doors, or
  unreachable modelled areas unless they are intentionally inaccessible and explained.

## 7. Commands (from the project root of your worktree)
```bash
godot --headless --path . --import          # after adding files (registers .uid files)
godot --headless --path . --fixed-fps 60 res://tests/QARunner.tscn -- --qa --suite=all --levels=<SID> --out=res://reports/qa/levels/<SID>.json
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver vulkan res://tests/CaptureRunner.tscn -- --qa --levels=<SID> --w=640 --frames=24 --out=res://reports/qa/levels/<SID>_capture.json
```
QA must report 0 failures for your level (and must not break registry/lint/save/ui). Look at
your stills (Read the .jpg files) and iterate until the place reads correctly. Rendering is
software (lavapipe): roughly 130 ms per frame, and that number is not a GPU result.

## 8. Finish
- `level.json` status stays `IN_DEVELOPMENT`. The integrator promotes after review.
- Replace your dossier's "## Test evidence" with: QA command + date, checks passed, bot route
  (edge, simulated seconds, distance), determinism, stills paths, known gaps.
- Commit in your worktree branch with a clear message. Report: files, QA summary, what is
  SOURCE vs ADAPTATION, known gaps, and any framework needs.
