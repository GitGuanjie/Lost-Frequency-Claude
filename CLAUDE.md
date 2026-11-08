# LOST FREQUENCY — instructions for Claude Code sessions

A Godot 4.5.1 game adapting the English Backrooms Wikidot (canon snapshot dated 2026-11-04 in `sources/`).
Target: 100 roster levels (`docs/canon/LEVEL_100_MATRIX.csv`). Honest status: `reports/QUALITY_SCOREBOARD.md`.

Start each session by reading `docs/production/NEXT_SESSION_HANDOFF.md`, `docs/production/LEVEL_AUTHORING_GUIDE.md`
(section 9, film-grade spatial rules, is mandatory), `docs/production/LEVEL_REBUILD_BRIEF.md` (the current level
rebuild programme) and `docs/canon/CANON_POLICY.md`. The `*_CN.md` notes are historical dev-build logs from an
external agent (dev1–dev28); they are kept for provenance, not as instructions.

Rules:
- Canon comes only from the dossier and the `sources/wiki_text/` snapshot. Exits use documented edge ids from
  `data/canon/transitions.json`, or are labelled ADAPTATION. Never invent entities or exits.
- A level is PLAYABLE only after QA passes with 0 failures (walker bot included) and its stills have been reviewed.
  Never report "100 complete" until it is true.
- `godot --headless --path . res://tests/CompileAll.tscn` must report 0 failing scripts before any commit;
  one parse error in a core script disables every autoload and no level can open.
- Third-party assets: CC0 or CC BY / CC BY-SA compatible only. Record each one in
  `assets/external/lock.json` / `assets/ASSET_PROVENANCE.csv` and in the credits.
- The whole project is CC BY-SA 3.0 (see LICENSE.md).
- Write documentation in English. Commit tested work with clear messages and push.
