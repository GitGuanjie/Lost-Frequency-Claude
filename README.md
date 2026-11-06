# LOST FREQUENCY — a source-locked Backrooms adaptation (Godot 4.5)

An unofficial, non-commercial game adaptation of the **Backrooms Wiki, English Wikidot
continuity** (https://backrooms-wiki.wikidot.com/). The target roster is a curated
**100-level list** (`docs/canon/LEVEL_100_MATRIX.csv`). Every level counts only after it
passes engine-executed gates. Unbuilt entries appear as **LOCKED / IN DEVELOPMENT**.

> Status is reported honestly in `reports/QUALITY_SCOREBOARD.md` and in-game (F3).
> This is a rebuild of V62; see `docs/production/V62_INTAKE_AUDIT.md` for why.

## Run it
Requirements: **Godot 4.5.x** (tested with 4.5.1-stable). Forward+ renderer.

```bash
godot --path lost_frequency
```

Controls: WASD / mouse, Shift sprint, Ctrl/C crouch (swim down), Space jump (swim up),
E interact, F flashlight (when you have one), J journal, **Esc pause menu** (mouse
interactive). Gamepad is supported. Keys can be rebound in Settings.

Developer channel (never writes your story save):
- **F3**: 100-level browser with search and filters, source readout, and spawning of built levels.
- **F4 / Shift+F4**: next/previous built catalog item (developer mode only, never a story exit).
- **F7**: flycam inspection; exiting it returns to the player's safe position.

Photographic CC0 textures (Poly Haven) are fetched, not committed:
```bash
python3 -I tools/fetch_assets.py   # pinned in assets/external/lock.json; procedural fallback if absent
```

## Test it (real engine)
```bash
cd lost_frequency
godot --headless --path . --import
godot --headless --path . --fixed-fps 60 res://tests/QARunner.tscn -- --qa
```
Suites: `registry` (100 entries, sources), `lint` (every story exit cites a documented
edge or is labelled ADAPTATION), `save` (atomic writes, developer isolation, corruption
fallback, V62 migration), `ui` (Esc/F3/F4/F7/journal), and `levels`. For each built level,
`levels` checks load, spawn clearance, collision, exits, navmesh reachability, a **walker bot
that physically walks to an exit and triggers it**, and determinism over three seeds.
Output: `reports/qa/latest_results.json`.

Rendered evidence (GPU, or software Vulkan via Xvfb + Mesa lavapipe):
```bash
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver vulkan res://tests/CaptureRunner.tscn -- --qa --levels=L000
```
Shell wrappers are in `scripts/qa/`.

## Layout
```
autoload/   Settings, LevelRegistry, SessionState, SaveService, TransitionService, AudioSynth, MatLib, Telemetry
core/       player, interaction, world (GeoKit, ChunkWorld, LevelBase, LightPool, WaterVolume), routing, graphics/shaders, audio
ui/         Overlay (HUD, pause, F3 browser, settings, journal, credits), MainMenu
levels/<SID>/  scene + level script + level.json manifest (status, exits with source quotes)
data/canon/    levels.json (100 sourced entries), transitions.json (393 documented edges)
docs/canon/    CANON_POLICY, LEVEL_100_MATRIX.csv, levels/<SID>.md dossiers, conflicts, licences
docs/production/ intake audit, world graph, popularity/selection, milestones, handoff
tests/      QA harness + capture runner     tools/  canon data builder
```

## Licence and attribution
Level texts adapted from the Backrooms Wiki are © their authors, **CC BY-SA 3.0** (per-page
citations in Credits and in `docs/canon/ATTRIBUTION_AND_LICENSES.md`). As the wiki's
Licensing Guide requires for Backrooms games, this whole folder (code included) is released
under **CC BY-SA 3.0**; see `LICENSE.md` for the release statement. All textures and sounds
are generated procedurally in-project. No third-party images, models or audio are shipped.
