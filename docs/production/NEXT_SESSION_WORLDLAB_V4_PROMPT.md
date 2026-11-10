# Claude Code handoff — ContinuityLab v4

Work on the supplied v4 source, Godot 4.5.1. Do not edit `levels/` or
`data/canon/` without explicit permission. This is a non-canon experiment.

1. Read `WORLD_LAB_V4_README_FIRST.md` and `docs/production/WORLD_CONTINUITY_LAB_V4.md`.
2. First run the supplied `RUN_WORLD_LAB_V4_QA_WINDOWS.bat` (or equivalent
   Linux headless scripts) and fix all compile or runtime errors before
   describing v4 as playable. The authoring environment had no Godot binary.
3. Run physical collision tests across all 2x2 hub seams, void rails, and
   4 floors of suspended bridges. Add bot navigation that records its actual
   path; static topology invariants are not enough.
4. Profile the 3x3x3 streamer under real GPU loads; optimise build spikes,
   collider count and save I/O. Measure FPS, p95/p99 frame time and VRAM.
5. After native tests pass, add higher-fidelity environment design around the
   192m superdistrict network, keeping a walkable central corridor and no
   procedural assets that violate the Backrooms canon.
6. Then prototype an opt-in seamless *canonical* Level0→Level1 transfer with
   a live world manager and preserved player state. Do not repurpose the
   `L001_PROXY` lab area as if it were the real Level1.
7. Re-run baseline 100-level entry QA and story regression, create Windows
   export, and provide exact commit and reproducible build/release archives.

Always separate tested claims from intended features. Do not invent QA numbers.
