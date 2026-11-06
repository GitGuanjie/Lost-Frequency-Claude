# M0 — V62 intake audit (engine-executed)

Date: 2026-11-04. Auditor: Claude (automated + visual review). Input:
`LOST_FREQUENCY_V62_MINI.zip` (237 files, 8.4 MB uncompressed; Godot 4.5 project
"LOST FREQUENCY | EIGHTEEN WORLDS V62"). V62's own docs state Godot was never run
when it was built. This audit is the first real-engine execution.

## Environment
- Godot **4.5.1.stable.official.f62fdbde1** (Linux x86_64, from the official GitHub release).
- Headless runs: `--headless`. Rendered runs: Xvfb + Mesa **lavapipe** (Vulkan 1.4,
  llvmpipe, LLVM 20) with the **Forward+** renderer. Software rendering only: no GPU.

## Results
| Check | Result |
|---|---|
| `godot --headless --import` | OK, no import errors |
| V62's own `tests/godot_v62_runtime_smoke.gd` | **114 checks, 15 failed**: `ExplorerAtlas` missing on all 15 expanded worlds |
| Script errors during smoke | **12 × SCRIPT ERROR** `mission_system.gd configure(): typed array mismatch` (argument 4) |
| Exit hygiene | leaked ObjectDB instances / resources at exit |
| Rendered capture (V60 capture script, 12 worlds) | Every world renders as near-identical **dark grey-green box halls with diagonal ramps**. The palette-swap failure the mandate warns about is directly visible. |

## Canon audit of V62 world identities (against the selected Wikidot continuity)
| V62 scene | V62 identity | Live page (2026-11-04) | Verdict |
|---|---|---|---|
| World7Archives | "Drowned Archive" | Level 7 "Thalassophobia" | **wrong**: mandate-prohibited "Level 7 is not an archive" |
| World11Transit | "Midnight Transit" | Level 11 "The City That Never Sleeps" | **wrong**: city, not a metro station |
| World12Hangar | "Fractal Hangar" | Level 12 "Matrix" | **wrong**: mandate-prohibited |
| World13Glasshouse | glasshouse | Level 13 "The Boiling Frogs" | **wrong**: apartments, not a greenhouse |
| World14Vents | "Service Lung" | Level 14 "Paradise" | **wrong**: not a duct maze |
| World3Boilers / 4Offices / 6Blackout / 8Caverns / 9Suburb / 10Fields / 19Attic / 188Courtyard | generic boxes | various | identity reduced to a name label on a shared generator |

## Decision
- **Rebuild, don't patch.** The shared 48 m cell generator *is* the source of the
  repetition, and the canon identities are wrong for at least five of the 18 worlds. The new
  project (the repository root) keeps the name and the 18 level IDs (Group A). It does not
  reuse V62 world code.
- **Assets not reused.** V62's PNG materials and WAVs (~7 MB) don't fit this repository's
  storage budget, and they have no reviewed provenance record. The rebuild generates all
  materials (shaders) and audio (synthesis) in-project instead.
- **Save migration retained.** V52/V60/V62 saves (`lost_frequency_unified_v52.json`) are
  detected in sibling Godot user-data folders. Their seed and visit list are imported and
  labelled legacy; old coordinates and missions are incompatible and are discarded with an
  explanation. This is tested in `tests/qa_runner.gd` (save suite). On the audit machine the
  real V62 save created by the capture run was detected.
- **V62 regressions now under test:** dead Esc UI, mouse locked in pause, inaccessible level
  browser, F4 used as a story exit, and fake portals. See the `ui` suite.

Evidence artefacts (V62 renders, logs) are kept outside Git (size policy). This document
records the measured outcomes.
