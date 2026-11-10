# Infinite Backrooms v5 — Handoff

**Branch:** `feature/infinite-backrooms-v5`
**Commit:** `2d20da72d4db63316bc9ebeda00034851d3c6696`
**Base:** the contents of `LostFrequency-v2.0.0-ContinuityLab-v4-FULL-SOURCE.zip`
(the upstream repository `GitGuanjie/Lost-Frequency-Claude` was not reachable
from this session, so the branch is local; see *Git* below.)
**Engine:** Godot 4.7.2.stable.official (`ed1daf0bf`)
**Tested on:** Windows, NVIDIA GeForce RTX 3060 Laptop GPU, Vulkan 1.4.351 Forward+

---

## 1. What this session actually did

The brief asked for a working, tested, exportable "infinite backrooms"
world. The honest summary is:

**Fixed first, built second.** The v4 package had never been run through a
native engine. Running it first found five defects that made the shipped QA
entry point unusable and the world class unloadable in a headless test run.
All of them are fixed and covered by a test.

**Then the structural work.** A chunk no longer chooses its own
architecture. A 16×16-chunk district, an 8×8-chunk superdistrict and the
megastructure inside it decide together, and the chunk follows. The
megastructure repeats one world-aligned bay grid, so a colonnade, a floor
inlay and a wall rhythm cross a chunk seam as one building rather than as
two rooms that happen to meet.

**Then the identity fix.** The hard-coded `k.x >= 4` split is gone. It used
to cut the central superdistrict hub into two different architectural
identities and to present a bare-concrete warehouse as the canonical Level 1.
Zones are now whole superdistricts with explicit ids, and the canonical
Level 0 identity is preserved inside the yellow zone whatever megastructure
the region rolled.

**Then the proof.** A new native test drives a real `CharacterBody3D`
through the generated world: it crosses a chunk seam through the *declared*
portal, comes back, walks into negative coordinates and back, climbs a
staircase to the next storey, and crosses the atrium bridge of the shared
macro hall without falling into the void.

---

## 2. Files changed

### New

| File | Purpose |
|---|---|
| `core/world/WorldAddress.gd` | explicit `world_id / zone_id / chunk / local_position` addressing |
| `core/world/RegionalPlan.gd` | the multiscale plan: district → superdistrict → megastructure → macro → chunk |
| `tests/ContinuityRegionalPlanTest.gd` | 6 505 native assertions on the plan |
| `tests/ContinuityPhysicalWalkTest.gd` | 14 physical checks: a body walks the world |
| `tests/ContinuityPhysicalWalkTest.tscn` | the scene for the above |
| `tests/test_worldlab_v5_static.py` | 16 offline contracts for the new layers |
| `RUN_V5_QA_WINDOWS.bat` | the reproducible native verification suite (8 gates) |
| `docs/production/INFINITE_BACKROOMS_V5_ARCHITECTURE.md` | the generation architecture |
| `docs/production/INFINITE_BACKROOMS_V5_COORDINATES.md` | coordinates and connectivity specification |
| `docs/production/INFINITE_BACKROOMS_V5_SAVE_SCHEMA.md` | the versioned save schema |
| `reports/qa/INFINITE_BACKROOMS_V5_QA_REPORT.md` | the measured QA results |

### Modified

| File | Change |
|---|---|
| `core/world/ChunkWorld3D.gd` | tab indentation fixed; the `SaveService` autoload resolved at runtime; a plan cache; heading-biased, time-budgeted streaming; a safe chunk detach; generator-versioned saves with a migration rule; stream statistics |
| `core/world/ContinuityTopology.gd` | zone identity (`zone_id`, `proxy_super_key`, `zone_id_for_super`, `is_proxy_zone`); `macro_theme` and `macro_structure` follow the zone; the `k.x >= 4` rule deleted |
| `labs/Level0ContinuityLab.gd` | the chunk builder consults the regional plan; `_add_megastructure` and `_add_structure_beacon`; the zone-aware palette; the address in the HUD; `--lab` and `--shot` command-line entry points; a QA seed override |
| `ui/MainMenu.gd` | the lab button is renamed and starts the lab through the command-line path as well |
| `ui/Overlay.gd` | the toast trim no longer removes a child while the toast box is adding one |
| `tests/ContinuityTopologyTest.gd` | the zone invariants replace the deleted district assertion |
| `tests/test_worldlab_v2/v3/v4_static.py` | explicit UTF-8 reads; the v4 chunk-detach contract updated |
| `project.godot` | version `2.1.0-infinite-backrooms-v5` |
| `RUN_WORLD_LAB_WINDOWS.bat`, `RUN_WORLD_LAB_V2/V3/V4_QA_WINDOWS.bat` | the trailing-backslash bug that broke every `--path` argument |

### Untouched on purpose

`levels/`, `data/canon/`, `autoload/TransitionService.gd`,
`autoload/SaveService.gd`, `core/routing/`, `core/player/`, `core/graphics/`
— the canonical 100-level story system.

---

## 3. How to reproduce

### Verify the source

```
git clone <this repo>
cd LostFrequency-ContinuityLab-v4
RUN_V5_QA_WINDOWS.bat "C:\path\to\Godot_v4.7.2-stable_win64_console.exe"
```

Exit code 0 means: the project imports, all 425 scripts compile, 198 103
native assertions pass, a real body walks the generated world, and the 45
offline contracts hold.

> The Windows export templates for 4.7.2 must be installed
> (`%APPDATA%\Godot\export_templates\4.7.2.stable`). They were downloaded
> for this session from the official object-storage mirror because the
> GitHub release CDN is unreachable from this network.

### Export for Windows

```
godot --headless --path . --export-release "Windows Desktop" "..\export\windows\LostFrequency.exe"
```

Produces a single 238.8 MB executable with the PCK embedded.

### Run it

```
LostFrequency.exe                       # the main menu
LostFrequency.exe -- --lab              # straight into the procedural world
LostFrequency.exe -- --lab --shot "C:\shot.png"   # capture the world and quit
```

In the lab: **F8** map, **F9** persistent marker, **F4** reshape the room
motif (never the structure), **F5/F6** switch or create a world seed,
**F10** back to the menu.

---

## 4. Git

The upstream repository was not reachable from this session, so the branch
exists locally:

```
git log --oneline -n 3
git rev-parse HEAD        # 2d20da72d4db63316bc9ebeda00034851d3c6696
git branch --show-current # feature/infinite-backrooms-v5
```

To publish it:

```
git remote add upstream https://github.com/GitGuanjie/Lost-Frequency-Claude.git
git push upstream feature/infinite-backrooms-v5
```

The commit has no parent, because the v4 package arrived as a zip without its
history. If the upstream history is available, rebase onto the verified
baseline `ebbf6f7cb6aa58a92f4a090ddc465611bd84c1ad` before pushing:

```
git remote add upstream https://github.com/GitGuanjie/Lost-Frequency-Claude.git
git fetch upstream
git rebase --onto upstream/ebbf6f7cb6aa58a92f4a090ddc465611bd84c1ad --root feature/infinite-backrooms-v5
```

---

## 5. Known issues

1. **Godot 4.7.2 prints *Parent node is busy adding/removing children* on
   every scene change.** Reproduced with a two-scene probe containing no
   project code, so it is engine behaviour. Harmless, but noisy in a QA log.
2. **The lab's stairwells are open.** The floor slot is 4.2 m wide, the ramp
   that fills it is 2.4 m wide; the 1.8 m strip beside the ramp is an
   unguarded drop to the storey below. v4 behaviour, preserved on purpose.
3. **A face opening can land on a stair slot.** The portal offsets (8, 12,
   16) and the slot band (14.4 … 18.6) overlap. Worth fixing: either move
   the slot or derive the portal offsets from the slot.
4. **Sixteen pre-existing 100-level failures** (L026, L028, L032, L050,
   L073, L085, L320, L808 and one story check). Unchanged by this work and
   still open.
5. **No performance numbers.** See the QA report, section 6: a frame-time
   capture was not made, so none are claimed.
6. **No noclip and no canon transitions in the lab.** The three connection
   kinds are specified in the coordinate document, but only PHYSICAL is
   implemented. Adding a NOCLIP or CANON_STORY transition needs a design
   decision that has not been made yet.

---

## 6. Next session — in priority order

1. **Fix the 16 pre-existing 100-level failures.** They are the only red
   marks left in the canonical system, and they are content defects in
   L026, L028, L032, L050, L073, L085, L320, L808 and one story check.
2. **Measure performance honestly.** A frame-time capture while walking the
   lab — median, p95, p99, streaming stalls, RAM, VRAM, triangle and
   collider counts — written into the QA report. The HUD already exposes the
   loaded triangle and collider totals and the streamer already reports
   built/unloaded/peak counts.
3. **Derive the portal offsets from the stair slot** so an opening can never
   land on a well.
4. **Close the open stairwell** by making the floor slot the same width as
   the ramp that fills it.
5. **Noclip and canon transitions.** Design first: the lab has no canon
   exits today, and inventing one is exactly what the brief forbids. The
   coordinate document already separates the three connection kinds.
6. **More megastructure kinds.** Four kinds and five partitions are in
   place; a 16×16 district layer exists but currently only carries a style
   name — give it real content (a district-wide silhouette, a district
   landmark, a district-wide event).
7. **A route planner for the physical test.** The walker currently follows
   hand-written waypoints. A planner over the declared portal graph would
   let it prove that *any* two chunks are connected, not only the routes
   that were written down by hand.

---

## 7. Evidence index

| Claim | Where |
|---|---|
| the native suite passes | `RUN_V5_QA_WINDOWS.bat`, exit 0, output quoted in the QA report §2 |
| the world is physically walkable | `tests/ContinuityPhysicalWalkTest.gd`, `reports/qa/continuity_physical_walk.json` |
| the plan is deterministic | `tests/ContinuityRegionalPlanTest.gd`, 6 505 assertions |
| the canonical levels did not regress | the before/after suite diff in the QA report §4 |
| the Windows build runs | the export and runtime table in the QA report §5 |
| the architecture | `docs/production/INFINITE_BACKROOMS_V5_ARCHITECTURE.md` |
| the coordinates and connectivity | `docs/production/INFINITE_BACKROOMS_V5_COORDINATES.md` |
| the save format | `docs/production/INFINITE_BACKROOMS_V5_SAVE_SCHEMA.md` |
