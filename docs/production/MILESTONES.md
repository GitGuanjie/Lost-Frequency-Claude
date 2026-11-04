# Milestones (mandate §12), with honest status

| Milestone | Mandate target | Status |
|---|---|---|
| **M0 — intake** | V62 audit in a real engine, baseline, 100-source audit | **Done.** V62 imported and run in Godot 4.5.1: its own smoke test failed 15/114 checks with 12 script errors, and its renders are a palette swap. All 100 live pages captured with title, revision, cite authors and creator; 100 dossiers; 406 documented edges. |
| **M1 — controls + base + 8-level slice** | Esc/F3/F7/F4, controller, safe spawn, loading, saves, settings, QA bot, capture; levels 0, 5, 7, 8, 11, 37, 188 + one radically different | **Framework done and engine-verified** (UI 25/25, save 14/14, registry 406, lint, story suite, walker bot). Level 0 is PLAYABLE. The slice was widened into a canon-connected story spine (0→1→19→5→6→7→8→9→11→25→{37,188}, plus 974 standalone); those levels are being built. |
| **M2 — first 20 premium** | 20 levels pass every gate | Not started. Follows slice integration. |
| **M3 — 40 accepted / 100 sourced** | 100% source identities audited | **Sourcing done early** (100/100 resolved, 0 blocked). 40 accepted: not started. |
| **M4 — 70 accepted** | all geometry families | Not started. |
| **M5 — 100 accepted** | exactly 100 canon-audited playable entries, release | Not started. |

## Quality ratchet
No milestone lowers the bar. A level counts only when engine QA passes (load, spawn, collision,
navmesh exits, a walker-bot exit, save round-trip, determinism) **and** its stills and manifest
have been reviewed against the dossier. "Fully accepted" also needs human review and real-GPU
performance evidence. Neither exists yet, so that counter is 0.

## Throughput reality
One level, built to this bar by one agent, takes roughly 1–3 hours of focused work including QA
and visual iteration. This session ran into an account usage limit once with six parallel
builders. Plan for the remaining ~87 levels in batches of 6–12, with integrator review between
batches (see NEXT_SESSION_HANDOFF.md).
