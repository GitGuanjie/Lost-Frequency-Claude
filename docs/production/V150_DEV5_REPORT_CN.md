# Lost Frequency v1.5.0-dev5 — Source and validation report

**State:** development source snapshot and offline experimental Windows repack. This is **not** a Godot engine-certified or Windows-verified release.

## Completed changes

- Preserved all 56 prior built scenes and their media, added **12 independent source-grounded scene implementations**, bringing the roster to **68/100 scenes**:
  - L001_2 Concrete Garden: overgrown concrete, abandoned ruins, memory-flower interactables.
  - L016 Altered Topography: rainforest, separate glacial traverse, low gravity and climate event clock.
  - L024 The Moon: lead-painted plastic landscape, PlasticWorks facility gate and siren clock.
  - L026 SS Fun =): multi-deck passenger liner, branching cabin corridor, stairwell, source poster and overboard danger.
  - L028 Final Virtue: six distinct runestones, two-level keep, periodic lightning and source exits.
  - L029 Hyperian: island harbor, wooden trading plaza, white-leaf trees and unsafe vessels.
  - L041 The Black Lake: supported boardwalk over hot tar and unstable islands.
  - L050 The moribund Highway: stationary traffic and investigable vehicles; no invented exits.
  - L071 Void Basement: dim repeating basement and diegetic file corruption; no invented escape.
  - L094 Motion: 1930s-style town, almond-water fountain, traversable hill and stop-motion-inspired night changes.
  - L100 Brief Peace: sandbar, memorial markers and swim-triggered source departure.
  - L114 Sweet Dreams: one small childhood bedroom, bed-triggered transition, fall-through void.
- New `.gd`, `.tscn`, `level.json` for each; all exits are exact IDs in `data/canon/transitions.json`, with original source URLs/short quotations preserved in their manifests.
- Fixed `ExitTrigger.gd` so interaction requires player occupancy, and source-defined conditions cannot be circumvented by calling `fire()` directly. Condition-gated walk-in exits can activate after the condition becomes true while the player is inside.
- Registered **9 additional transparent provisional arrival aliases** for newly connected existing scenes. They are safe spawn fallbacks, not bespoke arrival architecture. Existing 40 aliases remain; 49 provisional labels in total.
- Added a dev5 fail-closed Godot QA runner and a PowerShell entrypoint, alongside a separate **native** Godot 4.5.1 Windows export script that requires proper engine import, tests, and export templates.

## Honest quality status

| Verification | Result |
|---|---|
| `python -m unittest discover -s tests/static` | **28 / 28 passed** (includes 6 new dev5 source tests) |
| `python tools/world_audit.py --fail-on-issues` | **PASS; 0 structural integrity issues** |
| Canonical roster | 100 target levels |
| Built scene files | **68** (including 12 dev5 unverified candidates) |
| Declared exits | **192** |
| Declared built-to-built routes | **107** |
| From L000, manifest reachable | **36** |
| From L000, old QA-observed trigger connectivity | **21** (NOT dev5 verification) |
| Provisional arrival aliases | **49** (follow-up visual level design needed) |
| Native Godot source import, 3D physics, pathfinding | **NOT RUN: Godot executable unavailable in this environment** |
| L009 → L011 historical story failure | **NOT RETESTED** |
| GPU images, FPS benchmarking, Windows actual launch | **NOT RUN** |
| Experimental embedded PCK archive validation | Assesses only file hashes and index integrity; does not establish program correctness |

**Important:** No new scenes were promoted to `PLAYABLE`, and previous QA reports were not relabeled as current results. Story mode may show release boundaries for `IN_DEVELOPMENT` destinations, which can be entered through the F3 developer browser for debugging. Source restrictions also mean certain newly built levels have no known safe return route.

## Remaining high-priority defects

1. Install Godot 4.5.1 and matching Windows export templates. Run `RUN_DEV5_QA_WINDOWS.ps1` on a Windows system. Do not overwrite older QA reports with fabricated results.
2. Fix any parse/build/spawn/collision faults revealed in engine logs. Inspect the new ship upper bridge, castle stairs, beach/ocean intersection, volcanic tar boardwalk and exit hitboxes specifically.
3. Repair and re-test L009 → L011 end-to-end with real physics and physically satisfied route progression.
4. Replace provisional arrival aliases with purpose-made entrances, beginning with connections on the primary Level 0 path.
5. Increase meaningful interactive content (not just geometry) and optimize collision meshes; benchmark 1% low FPS and load times on real Windows GPU hardware.
6. Continue designing remaining 32 roster levels under the saved English-Wikidot source policy. Add no arbitrary links to increase graph reachability.

## Reproduction

```powershell
python -m unittest discover -s tests/static -v
python tools/world_audit.py --fail-on-issues
.\RUN_DEV5_QA_WINDOWS.ps1 -GodotExe 'C:\Godot\Godot_v4.5.1-stable_win64_console.exe' -Story
.\EXPORT_DEV5_WINDOWS.ps1 -GodotExe 'C:\Godot\Godot_v4.5.1-stable_win64_console.exe'
```

The separate experimental Windows package is built by a repeatable offline embedded-resource repacker using the earlier Windows executable. It is **not** a substitute for the normal export procedure.
