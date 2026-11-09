# Prompt for the next Claude Code session (paste as-is)

Continue LOST FREQUENCY, a Godot 4.5.1 Backrooms game canon-locked to the English Backrooms Wikidot
(snapshot 2026-11-04), in repository `GitGuanjie/Lost-Frequency-Claude`, branch `main`.
The whole project is CC BY-SA 3.0. Third-party assets must be CC0 or CC BY / CC BY-SA compatible and recorded.

Read first, in order:
1. `CLAUDE.md`
2. `docs/production/REMAINING_PLAN.md` (current state, the 7 levels left, ranked follow-ups)
3. `docs/production/LEVEL_REBUILD_BRIEF.md` (the builder brief; it produced 66 accepted rebuilds)
4. `docs/production/LEVEL_AUTHORING_GUIDE.md` (sections 9–11 are mandatory)
5. `docs/canon/CANON_POLICY.md` and `reports/QUALITY_SCOREBOARD.md`

Setup if missing: Godot 4.5.1 on PATH as `godot`, export templates in
`~/.local/share/godot/export_templates/4.5.1.stable/`, `apt-get install -y mesa-vulkan-drivers`. Then
`godot --headless --path . --import`.

Goals, in order:
1. Rebuild the last 7 IN_DEVELOPMENT levels: L050, L073, L085, L320, L032, L028, L808. Use at most 4 builder
   agents in parallel, each in its own git worktree with 3 levels, given the brief plus the QA tips listed in
   REMAINING_PLAN.md. As integrator: review every still yourself, merge with --no-ff, rerun the `levels` suite on
   the merged code (seed 1001, 0 failures), then set `status: PLAYABLE` and run `tools/build_reports.py`.
2. Performance pass on the heaviest levels (L994, L003_5, L108, L049): decimate or swap props, keep the look.
3. Add the most-requested core APIs (carried player status; runtime exit destinations; capture-mode flag),
   then simplify the per-level workarounds.
4. Re-run the full strict QA sweep (one Godot process per level), the 100-level entry probe and CompileAll.
5. Export Windows and Linux builds, zip them with README, LICENSE and the scoreboard, and send them to me.
   Commit and push after every merged batch; back builder branches up to origin if a usage limit interrupts.

Report honest counters: requested / source-audited / built scenes / playable-in-engine / lore-validated /
fully accepted / story-reachable. Do not claim "100 complete" until 100 levels actually pass.
