# Level rebuild brief (v2.0 rebuild programme, 2026-11-08)

The dev28 import contained 73 `IN_DEVELOPMENT` levels. A native audit (`tests/LevelEntryProbe.tscn`,
reports in `reports/qa/entry_audit/levels/`) showed many of them are placeholders: one sand slab with
twelve boxes, a red plane, a single bed in a void. Your job is to replace each assigned level with a real,
canon-faithful, film-grade space that a player wants to explore.

Read first, in this order:
1. `docs/canon/levels/<SID>.md` (the dossier) and `sources/wiki_text/<SID>.md` (the captured page text).
   The dossier is the canon contract. Every space, phenomenon, item, sound and exit must come from it.
2. `docs/production/LEVEL_AUTHORING_GUIDE.md`. Sections 0–10 apply in full; section 9 (film-grade rules)
   is mandatory.
3. The current stub in `levels/<SID>/` and its `level.json`. Keep `stable_id`, the edge ids and the
   arrival tags. Set `"legacy_overlays": false` in `level.json` (see guide section 11). You may rewrite every `.gd` file in that folder from scratch, and you should.
4. One finished reference level close to your theme. Office/backrooms: `levels/L001`, `levels/L002`.
   Water: `levels/L037`, `levels/L007`. Outdoor: `levels/L011`, `levels/L009`. Domestic: `levels/L974`.
   Hotel: `levels/L005`. Large vertical: `levels/L004`, `levels/L601`.

## What "done" means
- **Canon.** Nothing invented. Exits come only from `data/canon/transitions.json` edge ids already in
  `level.json` (or labelled ADAPTATION in the dossier). Entities appear only if the dossier lists them as
  CONFIRMED/REPORTED, and then as scripted presences, never combat. If the page says the level is empty,
  express that emptiness with architecture, light and sound, not with an empty plane.
- **Space.** At least two walkable heights where the page allows it (stairs/ramps with real collision),
  a readable route structure (loops, branches, landmarks, sightlines), and no visible world edge
  (ChunkWorld streaming, enclosure, fog/darkness or long sightlines that end in geometry).
- **Dressing.** Use the prop library generously and plausibly, as the page supports:
  - `Props.place(self, parent, "ph/<id>", pos, yaw_deg, height=0, collide=false)` places a Poly Haven
    CC0 model, real-world scale, from `assets/external/models/`. The list is in
    `assets/external/models/INDEX.md`.
  - `Props.place(self, parent, "kenney/<pack>/<name>", pos, yaw_deg, height, collide)` places a Kenney
    CC0 GLB (`assets/packs/catalog.json`).
  - Only give collision to props that sit off the walking route or are meant to block (one box each).
    Keep instance counts sane: a few hundred per level at most. Use `ChunkWorld` chunk callbacks for
    streamed levels.
- **Light and sound.** Motivated light pools with dark gaps (LightPool anchors), per-level fog and
  environment, and a soundscape that matches the page.
- **Interaction.** Notes and interactables whose text paraphrases the dossier (short quotes ≤25 words,
  attributed). One stateful signature mechanic from the dossier's "Signature mechanic" section.
- **Arrivals.** Every `from_<SID>` arrival that exists for this level faces into the space and reads as
  the continuation of the exit action.
- **QA.** The `levels` suite passes with 0 failures for seeds 1001, 2002 and 3003, walker bot included.
  `CompileAll` reports 0 failing scripts.
- **Stills.** Capture at least 4 curated `add_shot` views. Look at every JPEG yourself with the Read tool,
  fix what looks empty, broken, black, blown out or obviously fake, and capture again.

## Hard limits
- Change only files under `levels/<SID>/` for your SIDs, plus the `## Test evidence` section of
  `docs/canon/levels/<SID>.md`. If you think a core change is needed, describe it in your final report
  instead of making it.
- Set no level to `PLAYABLE`: the integrator promotes after review. Leave `status` as `IN_DEVELOPMENT`
  and fill `qa_summary` in your report.
- Run one Godot process at a time. Memory is shared with three other builders.
- Commit on your branch with clear messages. Do not push, merge or touch other worktrees.

## Commands (run from your worktree root)
```bash
godot --headless --path . --import > /dev/null 2>&1   # once after creating the worktree, ~3 min
godot --headless --path . res://tests/CompileAll.tscn 2>&1 | grep -E "COMPILE_|Parse Error|Compile Error" -A1
godot --headless --path . --fixed-fps 60 res://tests/QARunner.tscn -- --qa --suite=levels --levels=SID --seed=1001 --out=res://.work/qa_SID.json
godot --headless --path . res://tests/LevelEntryProbe.tscn -- --qa --level=SID   # prints content metrics into reports/qa/entry_audit/levels/SID.json
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver vulkan res://tests/CaptureRunner.tscn -- --qa --levels=SID --w=640 --frames=16 --out=res://.work/cap_SID.json
```
Stills land in `reports/screenshots/SID_<shot>.jpg`. Software rendering takes about 130 ms per frame;
that is not a GPU performance figure.

## Final report (your last message)
For each SID: what the space is now (3–5 lines), which dossier facts drive it, the metrics line from the
entry probe (meshes / triangles / props / lights / interactables / footprint), the QA result for the three
seeds, the still filenames, and any open issue. Include the branch name and commit hash.
