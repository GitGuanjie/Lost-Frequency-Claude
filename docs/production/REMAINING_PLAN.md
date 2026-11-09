# Remaining plan (written 2026-11-09, end of the v2 rebuild session)

## Where things stand
- 100 of 100 roster levels load and spawn safely through the real F3 transition
  (`tests/LevelEntryProbe.tscn`, one process per level). `tests/CompileAll.tscn`: 0 failing scripts.
- **93 PLAYABLE**: QA `levels` suite 0 failures (walker bot included; self-tests must raise no GDScript
  errors) and stills reviewed by the integrator. 81 of them have a walker-bot-fired exit; 12 are levels whose
  page documents no exit (`no_exit_reason`).
- **7 IN_DEVELOPMENT** (they load and spawn, but still use the external dev28 agent's generic scaffold):

| SID | Page title | Exits currently in level.json | Notes |
|---|---|---|---|
| L050 | Level 50 "The moribund Highway" | none | Check dossier for documented edges before adding any. Reference: L069 (highway + car). |
| L073 | Level 73 "The Redlands" | none | Reference: L737 (desert), L016 (terrain states). |
| L085 | Level 85 "Brilliant Evermore" | L085>L064#1, L085>L601#2, L085>EXT#3 | Reference: L005_3 (endless interior), L601. |
| L320 | Level 320 | L320>L001#1, L320>L009#2, L320>L011#3, L320>L048#5 | dev28 built a "five-storey" district here; replace with the page's real space. Full offset capture in `sources/wiki_text/L320_full.md`. |
| L032 | Level 32 | L032>EXT#1 | Reference: L017 (streamed sectors). |
| L028 | Level 28 | L028>L004#2, L028>L073#3, L028>L009_3#5 | Abyss Pools feed L010_1 (edge L028>L010_1#1 is documented). Reference: L027 (stormstone plain is its border). |
| L808 | Level 808 | L808>L185#1 | Reference: L201 (stylised neon world). |

Each one: read `docs/canon/levels/<SID>.md` and `sources/wiki_text/<SID>.md`, then follow
`docs/production/LEVEL_REBUILD_BRIEF.md` exactly (the same brief produced the 66 rebuilt levels).

## Known follow-ups (not blocking, ranked)
1. **Performance on prop-dense levels.** Software-rendered stills only; no GPU numbers yet. Heaviest spawn
   counts: L994 ~2.3M triangles (Poly Haven boulders/pebbles), L003_5 ~1.5M, L108 ~0.99M, L049 ~0.91M.
   Fix: decimate the heaviest Poly Haven models further (gltfpack `-si`), add LODs, or swap scatter rocks for
   Kenney nature rocks. Measure on a real GPU (F3 browser + `Telemetry`).
2. **Core APIs requested by builders** (each level currently has a local workaround):
   - carried player status across levels (L010_1 radiation, L999 bleaching, L998 waterlogged gear);
   - runtime-chosen exit destinations (`to: null` edges; L906, L021, L018, L023, L006_1, L737 set the cached edge);
   - forced crouch, vehicle/seat mode (L027, L069), camera shake (L024), per-zone environment override (L053),
     LightPool anchor energy setter (L140), level-owned audio bus effects (L003_5), ladder top-exit (L114, L027);
   - a capture-mode flag so CaptureRunner shots do not trip level kill rules (L049, L011_3).
3. **QA harness**: the nav-bake window is sized by straight-line distance to the farthest exit (distant or
   lazily created exits are not bot-tested); the "distinct layouts" signature only fingerprints box colliders;
   LevelEntryProbe counts sky/backdrop meshes in the footprint and omits MultiMesh triangles.
4. **Visual polish noted in review**: L197 Crimson Fortress still reads flat; L011_3 alley is near-monochrome;
   L030 island top sparse; L071 deliberately dark; primitive human figures in L017, L899, L024, L031.
5. **dev26 vignette data** (`data/dev26_curated_vignettes.json`) still targets old stub coordinates for L101,
   L114 and L160; those levels relocate the cues at runtime. Retire those entries when convenient.
6. **Human acceptance**: "fully accepted" stays 0 until a human playtests and real-GPU performance evidence exists.

## Commands
```bash
godot --headless --path . --import
godot --headless --path . res://tests/CompileAll.tscn
godot --headless --path . res://tests/LevelEntryProbe.tscn -- --qa --level=L050
godot --headless --path . --fixed-fps 60 res://tests/QARunner.tscn -- --qa --suite=levels --levels=L050 --seed=1001 --out=res://.work/qa_L050.json
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver vulkan res://tests/CaptureRunner.tscn -- --qa --levels=L050 --w=640 --frames=16 --out=res://.work/cap_L050.json
python3 -I tools/build_reports.py
godot --headless --path . --export-release "Windows Desktop" build/win/LostFrequency.exe
```
