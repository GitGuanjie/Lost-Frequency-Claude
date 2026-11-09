# Next-session handoff

Repository `GitGuanjie/Lost-Frequency-Claude`, branch `main`. The game is at the repository root.
Its history was imported from `GitGuanjie/claude-EO` (`lost_frequency/`, branch `claude/affectionate-wright-axgljs`)
on 2026-11-06. Engine: Godot **4.5.1** (Forward+).

## Latest state (2026-11-09) — read `docs/production/REMAINING_PLAN.md` first
- 100/100 levels load and spawn (native entry probe); CompileAll 0 failing scripts.
- 93 PLAYABLE (66 rebuilt in the v2 programme + 27 earlier), 7 IN_DEVELOPMENT left:
  L050, L073, L085, L320, L032, L028, L808. Paste-ready prompt: `docs/production/NEXT_SESSION_PROMPT.md`.
- Windows export: VRAM-compressed textures, non-game folders excluded (`export_presets.cfg`).

## State (2026-11-08, v2 rebuild programme)
- **Intake of the external "dev28" build.** The user supplied a dev28 build by another AI agent (100 scenes,
  27 playable + 73 IN_DEVELOPMENT). It was imported verbatim (commit 98fa23f), then:
  - **Why levels "could not open":** mixed tab/space indentation in `core/world/LevelBase.gd` broke the
    TransitionService, Overlay and MainMenu autoloads, so no level loaded. 31 further scripts failed to compile.
    All fixed; `tests/CompileAll.tscn` now guards this (0 failing scripts required).
  - **Native audit:** `tests/LevelEntryProbe.tscn` (one process per level) loads every level through the real F3
    transition and records content metrics in `reports/qa/entry_audit/levels/`. All 100 load and spawn safely.
    The metrics and stills showed most dev28 levels were placeholders (3–30 meshes) or a reused generic scaffold.
- **Rebuilt so far: 24 levels** (each QA 0 failures on seeds 1001/2002/3003 incl. walker bot; stills reviewed):
  L000_2, L001_1, L001_5, L994, L965, L011_2, L114, L160, L021, L037_1, L100, L007_7, L000_3, L001_3, L003_5,
  L010_1, L263, L101, L922, L027, L007_8, L096, L069, L005_1. Promoted to PLAYABLE.
- **In progress (round 3, branches build/r3a–d, backed up on origin):** L052, L009_3, L018; L011_3, L030, L058;
  L026, L075, L079; L031, L060, L053.
- **Still to rebuild (37):** L015, L001_2, L036, L197, L071, L022, L049, L055, L090, L020, L006_1, L737, L041,
  L005_3, L016, L017, L899, L024, L999, L023, L998, L149, L083, L201, L029, L140, L048, L094, L077, L108, L050,
  L073, L085, L320, L032, L028, L808. They load and spawn, but are thin or use the generic dev28 scaffold.
- **New assets:** 83 Poly Haven CC0 models (`assets/external/models/`, index with measured sizes in `INDEX.md`,
  provenance in `lock.json` / `ASSET_PROVENANCE.csv` / in-game credits). `Props.place()` places Poly Haven or
  Kenney models with measured scaling, optional single-box collision and a size-scaled visibility range.
- **Process:** `docs/production/LEVEL_REBUILD_BRIEF.md` is the builder brief (≤4 parallel builder agents, one
  worktree each, integrator reviews stills and merges with --no-ff). Guide section 11 has the latest notes.
- **Known follow-ups:** heavy triangle counts on prop-dense levels (L994 ~2.3M, L003_5 ~1.5M: decimate props further
  or add LODs); CaptureRunner can hang after writing stills (run under `timeout`); dev26 vignette data still
  targets old stub coordinates for L101/L114/L160 (those levels relocate the cues at runtime); no API yet for
  carried player status, forced crouch, vehicle seats or runtime-chosen destinations.

## Earlier state (2026-11-06)
- **Built: 27** (scoreboard has the list). This batch added L906, L601, L256 and L000_1. L000, L001, L002, L003, L004,
  L005, L006, L007, L008, L009, L010, L011, L012, L014, L019, L025, L037, L188 and L974. 17 are
  story-reachable from Level 0; L974 is developer-only per canon. Fully accepted: 0 (needs a human playtest and
  real-GPU numbers).
- **Film-grade features:**
  - Seamless level switching (prefetch plus a no-clip glitch, with state carried over).
  - Found-footage camcorder filter with REC timestamp.
  - Multi-storey spaces (L000 atriums, L002 decks, L004 floors, L008 shafts).
  - CC0 photographic materials (Poly Haven sets in `assets/external`; `tools/fetch_assets.py` re-fetches them, pinned by `lock.json`).
- **Sources:**
  - `sources/wiki_text/` holds the dated text snapshots of all 100 pages (2026-11-04), plus the full offset
    captures for L320 and L289 in `*_full.md`.
  - `sources/dossier_json/` holds the structured dossiers; `docs/canon/levels/` holds the markdown dossiers.
  - The mandate and roster are in `sources/`.

## Exact commands
```bash
godot --headless --path . --import
godot --headless --path . --fixed-fps 60 res://tests/QARunner.tscn -- --qa --suite=levels --levels=L003   # one level per process (memory)
godot --headless --path . --fixed-fps 60 res://tests/QARunner.tscn -- --qa --suite=story --story_hops=8   # story chain, run alone
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver vulkan res://tests/CaptureRunner.tscn -- --qa --levels=L003 --w=640 --frames=24
python3 -I tools/build_canon_data.py --snapshot <raw html dir> --roster sources/BACKROOMS_100_LEVEL_ROSTER.csv --dossiers sources/dossier_json
python3 -I tools/build_reports.py
godot --headless --path . --export-release "Windows Desktop" ../export/windows/LostFrequency.exe
```
Run one level per QA process: four heavy streamed levels in one process hit the container's memory limit.

## Open issues
- The story suite passes 0 → 1 → 19 → 5 → 9. The walker bot fails Level 9's ordered arrow-sign route
  (`L009>L011#1`) when it starts from the `from_L005` house arrival; it works from `start`.
- Add `from_L002` to L001 and `from_L004` to L006 (return trips currently land at `start`).
- First-wave levels (L001, L005, L006, L009, L011, L019, L025, L037, L188) predate guide section 9. Retrofit
  them with multi-height structure and no-boundary edges.
- QA runs executed in parallel share `user://qa_saves`.

- `GeoKit.wall()` builds a solid piece across a lower opening when two openings overlap in plan at different
  heights (window above door). Workaround: build multi-storey walls one storey at a time. Proper fix pending.
- Fixed 2026-11-06: `Overlay.toast()` looped forever on a 5th concurrent toast (QA regression test added); the
  QA runner leaked a nav map for exit-less levels.

## Next levels (priority)
Next are L999, L005_1, L006_1, L808, L994, L075, L079, L048 and L069, then the rest of Group C/D. Wire a story route into the developer-only levels only where transitions.json documents one.
Each needs: QA with 0 failures plus the walker bot, two reviewed stills, and `status: PLAYABLE` only after review.
Use at most 4 parallel builders: six opus builders hit the account usage limit twice.
