# LOST FREQUENCY — instructions for Claude Code sessions

A Godot 4.5.1 game adapting the English Backrooms Wikidot (canon snapshot dated 2026-11-04 in `sources/`).
Target: 100 roster levels (`docs/canon/LEVEL_100_MATRIX.csv`). Honest status: `reports/QUALITY_SCOREBOARD.md`.

For the latest changes read `docs/production/NEXT_SESSION_V150_DEV3_CN.md` first, then `docs/production/NEXT_SESSION_V150_DEV2_CN.md`, then `docs/production/NEXT_SESSION_V150_DEV1_CN.md`, then `docs/production/NEXT_SESSION_HANDOFF.md`, `docs/production/LEVEL_AUTHORING_GUIDE.md`
(section 9, film-grade spatial rules, is mandatory) and `docs/canon/CANON_POLICY.md`.

Rules:
- Canon comes only from the dossier and the `sources/wiki_text/` snapshot. Exits use documented edge ids from
  `data/canon/transitions.json`, or are labelled ADAPTATION. Never invent entities or exits.
- A level is PLAYABLE only after QA passes with 0 failures (walker bot included) and its stills have been reviewed.
  Never report "100 complete" until it is true.
- Third-party assets: CC0 or CC BY / CC BY-SA compatible only. Record each one in
  `assets/external/lock.json` / `assets/ASSET_PROVENANCE.csv` and in the credits.
- The whole project is CC BY-SA 3.0 (see LICENSE.md).
- Commit tested work with clear messages and push.
