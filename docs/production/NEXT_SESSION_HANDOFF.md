# Next-session handoff

Repository `GitGuanjie/Lost-Frequency-Claude`, branch `main`. The game is at the repository root.
Its history was imported from `GitGuanjie/claude-EO` (`lost_frequency/`, branch `claude/affectionate-wright-axgljs`)
on 2026-11-06. Engine: Godot **4.5.1** (Forward+).

## State (2026-11-06)
- **Built: 23 (see the scoreboard for the current list; this line was written at 19).** L000, L001, L002, L003, L004,
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
Group A is complete, and L404, L200 and L289 are built. Next are the flagships L906, L601, L256, L999, L000_1, L005_1, L006_1 and L808; then Group C/D.
Each needs: QA with 0 failures plus the walker bot, two reviewed stills, and `status: PLAYABLE` only after review.
Use at most 4 parallel builders: six opus builders hit the account usage limit twice.
