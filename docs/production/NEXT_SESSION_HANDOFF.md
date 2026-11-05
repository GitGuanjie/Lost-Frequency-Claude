# Next-session handoff

Repository `GitGuanjie/claude-EO`, branch `claude/affectionate-wright-axgljs`, folder `lost_frequency/`.
Engine: Godot **4.5.1** (Forward+). Tested on Linux with headless runs and software Vulkan (Mesa
lavapipe under Xvfb). No real GPU was available.

## State at handoff (2026-11-05)
- **Sources:** 100/100 live Wikidot pages captured (2026-11-04), with 100 dossiers, 406 documented
  edges and full attribution. Levels 320 and 289 needed their offset-paginated sections captured.
- **Framework:** done and engine-tested (UI 25/25, save 14/14, registry, lint, duplication detector,
  per-level gates, story-mode playthrough suite, walker bot, rendered capture runner, Windows/Linux
  export presets).
- **Playable levels (engine QA 0 failures, stills reviewed by the AI integrator):** L000, L001, L019,
  L005, L006, L007, L009, L011, L025, L037, L188 (11). The story chain is verified in real story mode:
  0 → 1 → 19 → 5 → 9 (arrivals, safe spawn and journal checked on every hop). See
  `reports/QUALITY_SCOREBOARD.md` for the hops that currently pass.
- **Partially built, not integrated:** L008 "Cave Systems" (scripts written, no scene/manifest yet)
  and L974 "Kitty's House" (art + Kitty AI scripts, no scene/manifest yet). The work-in-progress files
  are in the worktree branches `worktree-agent-a5935631a21ca30f2` (L007/L008) and
  `worktree-agent-a33de440778939e7b` (L037/L974) under `.claude/worktrees/`. These are local only and
  lost when the container is reclaimed, so copy them first if you need them.
- **Not started:** the other 87 roster levels. They show as LOCKED / IN DEVELOPMENT in the F3
  browser with their source readout.
- **Fully accepted: 0.** This needs a human playtest, a human lore review and real-GPU performance
  numbers.

## Exact commands
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
- **Story chain past Level 9 is not verified.** In a long story-suite run (with route waypoints added for
  Level 9's arrow signs), Godot printed `Jolt Physics job system exceeded the maximum number of jobs` and
  stalled. Likely cause: a heavy streamed level (L009/L011) combined with the chained loads. Reproduce with
  `--suite=story`, check that each previous level is fully freed before the next physics step, and consider
  smaller per-chunk collision counts. Hops 0 → 1 → 19 → 5 → 9 passed in the full-suite run of 2026-11-05.
- The story-suite assertion that checks the on-disk save after each hop was rewritten to read the file
  directly. Earlier it failed on some hops; confirm it on the next run.

## Highest-value next steps
1. Finish **L008** (completes 7 → 8 → 9 in the story) and **L974**.
2. Remaining **Group A**: L002, L003, L004, L010, L012, L013, L014 (all but 13 are story-reachable).
3. Top-rated flagships: L404, L200, L289, L906, L601, L256, L999, L000_1, L005_1.
4. A human playtest of the chain on a real GPU. Record frame-time numbers, then promote to ACCEPTED.
5. Move the game into its own repository (`git subtree split --prefix=lost_frequency`). The research
   repository caps total tracked size at 5 MiB, which limits stills and evidence.

Build rule for every level: follow `docs/production/LEVEL_AUTHORING_GUIDE.md`, then pass QA with 0
failures and the walker bot. Integrator review of stills comes before `status: PLAYABLE`. Use at most
4–6 parallel builders: this session hit the account usage limit twice with 6 opus builders plus
sonnet researchers.
