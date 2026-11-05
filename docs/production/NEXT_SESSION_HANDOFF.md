# Next-session handoff

Repository `GitGuanjie/claude-EO`, branch `claude/affectionate-wright-axgljs`, folder `lost_frequency/`.
Engine: Godot **4.5.1** (Forward+). Tested on Linux with headless runs and software Vulkan (Mesa
lavapipe under Xvfb). No real GPU was available.

## State at handoff (2026-11-05, v1.1.0-m2)
- **Playable (engine QA 0 failures, stills reviewed by the AI integrator): 15.** These are L000, L001, L002, L004, L005,
  L006, L007, L008, L009, L011, L019, L025, L037, L188 and L974. 13 are story-reachable; L974 is developer-only per canon.
- **User feedback on v1.0 (applied):** the levels felt too few and too boundaried, and the user wanted "Backrooms
  film" 3D space with continuous switching. Response:
  - Seamless switching: the destination prefetches near an exit and swaps under a no-clip glitch, with
    momentum, view pitch and flashlight carried over. There is no loading screen.
  - A found-footage camcorder filter with a REC timestamp and handheld sway (Settings toggle).
  - Level 0 two-storey atrium zones.
  - Guide section 9, "Film-grade spatial rules": multi-height spaces and no visible boundaries are now mandatory.
  - L002, L004 and L008 were built under these rules (two-deck tunnels and catwalks, two-floor office blocks with
    light wells, and caves from -8 m to +5 m).
- **Fixes this round:**
  - Arrivals now update the story checkpoint, so Continue resumes in the level you reached.
  - MSAA made the water depth read 0 (opaque water); the project now uses FXAA.
  - QA reports are compacted.
- **Repository budget:** 4.85 MB of the research repository's 5 MiB cap. **Move the game to its own repository
  before adding more levels**: `git subtree split --prefix=lost_frequency -b lost-frequency`, then push that
  branch to a new repository.

## Exact commands
(Story suite: add `--story_hops=N` to limit the chain; `--seed=N` sets the level-suite seed.)
```bash
cd lost_frequency
godot --headless --path . --import
godot --headless --path . --fixed-fps 60 res://tests/QARunner.tscn -- --qa                    # all suites
godot --headless --path . --fixed-fps 60 res://tests/QARunner.tscn -- --qa --suite=levels --levels=L008
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver vulkan res://tests/CaptureRunner.tscn -- --qa --levels=L008 --w=640 --frames=24
python3 -I tools/build_reports.py      # scoreboard, acceptance CSV, world_graph.dot
godot --headless --path . --export-release "Windows Desktop" ../export/windows/LostFrequency.exe
```

## Open issues found at handoff
- **Root cause of the earlier "story stall" (fixed):** in story-only runs, `TransitionService.load_level` freed
  the current scene, which was the QA runner itself. The Jolt "max jobs" warning was a side effect, not
  the cause. The story suite (`--suite=story --story_hops=5`) now runs: 28 passed, 1 failed.
  0 → 1 → 19 → 5 → 9 passes with seamless switching, sourced arrivals, carried state and the on-disk save advancing.
- **Remaining failure:** the walker bot does not complete Level 9's sourced arrow-sign route
  (`L009>L011#1` needs the signs passed in order) when starting from the `from_L005` house arrival. It works from
  `start`. Check the waypoint walks (printed as `STORY waypoint ...`). The house arrival is upstairs, and the first
  sign may be unreachable within the streaming radius.
- QA runs that execute in parallel share `user://qa_saves`. Run story suites one at a time.

## Highest-value next steps
1. Move the game to its own repository (see above), then raise the storage budget.
2. Remaining **Group A**: L003, L010, L012, L013, L014; add `from_L002` to L001 and `from_L004` to L006.
3. Retrofit section 9 (multi-height and no-boundary) onto the first-wave levels: L001, L005, L006, L009, L011,
   L019, L025, L037, L188.
3. Top-rated flagships: L404, L200, L289, L906, L601, L256, L999, L000_1, L005_1.
4. A human playtest of the chain on a real GPU. Record frame-time numbers, then promote to ACCEPTED.
5. Move the game into its own repository (`git subtree split --prefix=lost_frequency`). The research
   repository caps total tracked size at 5 MiB, which limits stills and evidence.

Build rule for every level: follow `docs/production/LEVEL_AUTHORING_GUIDE.md`, then pass QA with 0
failures and the walker bot. Integrator review of stills comes before `status: PLAYABLE`. Use at most
4–6 parallel builders: this session hit the account usage limit twice with 6 opus builders plus
sonnet researchers.
