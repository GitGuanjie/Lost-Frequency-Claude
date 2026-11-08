**v1.5.0-dev28 (2026-11-08):** Repaired two-level routes on ship/arcade/submarine, added sixteen inspectable clinic clocks, 27 themed E-interactions and 81 existing GLB placements across nine levels. 243/243 offline tests pass; **native Godot and 100-entry acceptance remain unverified**. See `DEV28_README_FIRST_CN.md`.

**v1.5.0-dev27 (2026-11-08):** 8 source-aware environments now have physically modeled themed field sectors, 18 exploration spurs, 16 ascents, 8 optional collidable crossings, 228 uses of existing GLBs, and 48 E interactions with actual light/bridge changes. Static 237/237 and 100-entry prerequisites PASS; Godot native NOT RUN (engine absent). Existing 100 levels/235 exits unchanged; 27 PLAYABLE/73 IN_DEVELOPMENT. See `DEV27_README_FIRST_CN.md`.

**v1.5.0-dev26 (2026-11-08):** Thirteen previously thin levels get 43 source-aware environmental interactions, 86 non-colliding existing GLB placements, 43 height-gated proximity cues and true light-state feedback; Level 197 adds four physically modeled mineral galleries with eight independent up/down ramps. Static 231/231 and 100-level entry preflight PASS; Godot native NOT RUN (engine missing), original canonical exits and level statuses preserved. See `DEV26_README_FIRST_CN.md`.

**v1.5.0-dev25 (2026-11-08):** Distinct Wiki-aware optional network annexes at L041/L048/L140/L201; natural island forks at L149; restrained gravestone journal in L100; no invented L069 service station. 225/225 offline tests pass, native Godot verification blocked (engine unavailable). See `DEV25_README_FIRST_CN.md`.

**v1.5.0-dev24 (2026-11-08):** Ten different expedition macro-morphologies (100 generated deck nodes, 107 links, 300 additional placements using 85 existing GLBs); two altitude bands, safe physical optional bridges with retractable railings, lighting controls and area-specific ambience. Static 219/219 PASS; native Godot QA FAIL at missing engine. See `DEV24_README_FIRST_CN.md`.

**v1.5.0-dev23 (2026-11-08):** Ten genuinely connected landmark spurs beyond the DEV22 terraces: 20 upper galleries, 6 optional lower courts, 26 physical stair runs, 10 survey-activated collidable bridges, 30 interactive beacons, 30 ambient clues, and 160 additional placements from 61 existing GLB assets. Original entrance guardrails now have verified source-level openings, and lower-branch rail gaps are explicit. Static 213/213 and world audit PASS; native Godot import FAIL (engine missing). DO NOT claim actual playable release. See `DEV23_README_FIRST_CN.md`.

**v1.5.0-dev22:** 10 new themed vertically connected districts (42 elevations / 626 design floor units / 64 real stair flights / 272 existing GLB placements), interactive light and route-gate state, and global zero-argument interaction callback compatibility. 207 offline tests pass; Godot engine QA pending. See `DEV22_README_FIRST_CN.md`.

**v1.5.0-dev21 (2026-11-07):** 10 wiki-themed scenography packs integrated into real dev20 spatial blueprints: 330 existing GLB prop instances across 68 model types, 20 physically supported overlook terraces, 30 interactive light markers, 30 inspectable props, 20 positional ambience cues; repaired dev20 callback player-argument bug. 189/189 offline tests pass; native Godot unavailable and not certified. See `DEV21_README_FIRST_CN.md`.

**v1.5.0-dev20 (2026-11-07):** 10 site-specific seeded architectural annexes (560 walkable cells, 740 horizontal links, 40 stairs, 60 E interactions), separate indoor/open-air construction, 178/178 offline tests. Native Godot unverified due missing engine; **not** certified playable. See `DEV20_README_FIRST_CN.md`.

**v1.5.0-dev17 (2026-11-07):** Level 8 SDF 6 braided cave bypasses + 2 interlinks, Level 37 two fixed multi-tier Poolrooms annexes (3/4 decks), 143/143 static tests, 100 levels/235 declared exits unchanged. Godot native QA attempted but unavailable; no EXE certified. See `DEV17_README_FIRST_CN.md` and `docs/production/V150_DEV17_SPATIAL_LABYRINTH_CN.md`.

**v1.5.0-dev15 (2026-11-07):** 9 处空间结构续改，新增七座连续分层双梯建筑、Level 22 的 4 层修复、Level 30 的可连通悬浮岛高桥。125 项静态 QA 通过，Godot/Windows 未实测。详见 `DEV15_README_FIRST_CN.md`、`docs/production/V150_DEV15_VERTICAL_NETWORKS_CN.md`。

**v1.5.0-dev14 (2026-11-07):** L000/L001/L009/L011 竖向多层空间升级；新增 4/5 层中庭、3 层仓库检修环、4 层停车屋顶、4 层城市空桥。118 项离线静态测试通过，Godot/Windows 引擎尚未验证，不能称正式可玩。参见 `docs/production/V150_DEV14_VERTICAL_REWORK_CN.md`。

## DEV7 milestone (2026-11-07) — SOURCE COVERAGE, NOT RELEASE ACCEPTANCE

100/100 canon roster entries now have scene-source candidates; 16 new in dev7, all `IN_DEVELOPMENT`. This is **not** a 100-level playable release. Headless Godot and Windows tests were not executable in this environment. Static contracts: 48/48 passed. Exit declarations: 235; 43 levels reachable by the configuration graph, not physically certified. See `docs/production/V150_DEV7_REPORT_CN.md` and `NEXT_SESSION_V150_DEV7_CN.md`. `RUN_DEV7_QA_WINDOWS.ps1` verifies engine QA; `tools/production_gate_dev7.py --release` blocks false stable release.

## DEV6 experimental expansion (2026-11-07)

84 scene-source candidates, including 16 new IN_DEVELOPMENT scenes. 100 roster slots are **not** 100 finished levels. F6 offers an oriented directed path preview; developer paths reflect manifest declarations, not verified player traversal. For Windows, run `RUN_DEV6_QA_WINDOWS.ps1` with Godot 4.5.1; no new content may be promoted without engine + manual evidence.

> **v1.5.0-dev5（2026-11-07）**：68 个场景源码，新增 12 个来源对应且具有不同地形/交互的开发中关卡；192 条出口清单、可到达 36 关（仅配置图），28 项静态测试通过。`ExitTrigger` 增加物理占用和条件防绕过校验。Godot 尚未运行，Windows 包为离线实验构建，不保证可启动。详情见 `docs/production/V150_DEV5_REPORT_CN.md`。

> **开发版更新 v1.5.0-dev4（2026-11-07）：** 56 个场景源码，新增 9 个来源约束场景、40 个明确标注的临时入口别名和新一轮世界审计。新场景仍为 `IN_DEVELOPMENT`；22 项离线完整性测试通过，但 Godot/Windows 实测尚未执行。详见 `docs/production/V150_DEV4_REPORT_CN.md`。

# LOST FREQUENCY — a source-locked Backrooms adaptation (Godot 4.5)

An unofficial, non-commercial game adaptation of the **Backrooms Wiki, English Wikidot
continuity** (https://backrooms-wiki.wikidot.com/). The target roster is a curated
**100-level list** (`docs/canon/LEVEL_100_MATRIX.csv`). Every level counts only after it
passes engine-executed gates. Unbuilt entries appear as **LOCKED / IN DEVELOPMENT**.

> Status is reported honestly in `reports/QUALITY_SCOREBOARD.md` and in-game (F3).
> This is a rebuild of V62; see `docs/production/V62_INTAKE_AUDIT.md` for why.

> **v1.5.0-dev3 development source snapshot (2026-11-07):** 47 built scene files, of which 8 new
> source-bound environments (L031, L048, L000_3, L006_1, L021, L808, L922 and L149) are
> **IN DEVELOPMENT / NOT ENGINE VERIFIED**. The previous dev1 and dev2 candidate levels
> remain pending native Godot testing. Dev3 adds a two-floor enterable hotel, a traversable
> four-flight repeating stairwell, a low-gravity archipelago, an arcade green-card interaction,
> several source-accurate destination paths and more. See `docs/production/V150_DEV3_REPORT_CN.md`.
> The experimental Windows bundle uses an offline PCK repack and has not passed native launch QA.

## Run it
Requirements: **Godot 4.5.x** (tested with 4.5.1-stable). Forward+ renderer.

```bash
godot --path .
```

Controls: WASD / mouse, Shift sprint, Ctrl/C crouch (swim down), Space jump (swim up),
E interact, F flashlight (when you have one), J journal, **Esc pause menu** (mouse
interactive). Gamepad is supported. Keys can be rebound in Settings.

Developer channel (never writes your story save):
- **F6**: directional world connection map (observed story routes or developer declared routes).
- **F3**: 100-level browser with search and filters, source readout, and spawning of built levels.
- **F4 / Shift+F4**: next/previous built catalog item (developer mode only, never a story exit).
- **F7**: flycam inspection; exiting it returns to the player's safe position.

Photographic CC0 textures (Poly Haven) are fetched, not committed:
```bash
python3 -I tools/fetch_assets.py   # pinned in assets/external/lock.json; procedural fallback if absent
```

## Fast offline preflight + targeted Godot QA for dev3
```bash
python tools/preflight_dev.py
python -m unittest discover -s tests/static -v
python tools/world_audit.py
python tools/run_dev3_qa.py --plan-only
# On a machine with Godot 4.5.1:
python tools/run_dev3_qa.py --godot godot --story
```
On Windows: `RUN_DEV3_QA_WINDOWS.ps1 -GodotExe "<path to Godot 4.5.1 console EXE>" -Story`.
For a native Windows build (requires installed Godot 4.5.1 export templates):
`EXPORT_DEV3_WINDOWS.ps1 -GodotExe "<path to Godot 4.5.1 console EXE>"`.
A development-only export with engine QA skipped is possible via `-SkipQa`, but it must not be called verified.
No static result substitutes for engine import, level QA, screenshot review, or human playtest.

## Test it (real engine)
```bash
godot --headless --path . --import
godot --headless --path . --fixed-fps 60 res://tests/QARunner.tscn -- --qa
```
Suites: `registry` (100 entries, sources), `lint` (every story exit cites a documented
edge or is labelled ADAPTATION), `save` (atomic writes, developer isolation, corruption
fallback, V62 migration), `ui` (Esc/F3/F4/F7/journal), and `levels`. For each built level,
`levels` checks load, spawn clearance, collision, exits, navmesh reachability, a **walker bot
that physically walks to an exit and triggers it**, and determinism over three seeds.
Output: `reports/qa/latest_results.json`.

Rendered evidence (GPU, or software Vulkan via Xvfb + Mesa lavapipe):
```bash
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver vulkan res://tests/CaptureRunner.tscn -- --qa --levels=L000
```
Shell wrappers are in `scripts/qa/`.

## Layout
```
autoload/   Settings, LevelRegistry, SessionState, SaveService, TransitionService, AudioSynth, MatLib, Telemetry
core/       player, interaction, world (GeoKit, ChunkWorld, LevelBase, LightPool, WaterVolume), routing, graphics/shaders, audio
ui/         Overlay (HUD, pause, F3 browser, settings, journal, credits), MainMenu
levels/<SID>/  scene + level script + level.json manifest (status, exits with source quotes)
data/canon/    levels.json (100 sourced entries), transitions.json (393 documented edges)
docs/canon/    CANON_POLICY, LEVEL_100_MATRIX.csv, levels/<SID>.md dossiers, conflicts, licences
docs/production/ intake audit, world graph, popularity/selection, milestones, handoff
tests/      QA harness + capture runner     tools/  canon data builder
```

## Licence and attribution
Level texts adapted from the Backrooms Wiki are © their authors, **CC BY-SA 3.0** (per-page
citations in Credits and in `docs/canon/ATTRIBUTION_AND_LICENSES.md`). As the wiki's
Licensing Guide requires for Backrooms games, this whole folder (code included) is released
under **CC BY-SA 3.0**; see `LICENSE.md` for the release statement. All textures and sounds
are generated procedurally in-project. No third-party images, models or audio are shipped.


## v1.5.0-dev8 vertical rework and physical route regression

This development update adds an elevated maintenance gallery in Level 1, a multi-storey parking garage in Level 9, and interactive acoustic cues in Level 7. Smiler collision checks and the L009→L011 QA waypoint runner are strengthened. See `docs/production/V150_DEV8_REPORT_CN.md`.

Windows: run `RUN_DEV8_QA_WINDOWS.ps1 -GodotExe <Godot 4.5.1 console executable> -Story` before any release. This source revision has **not** passed engine or native Windows runtime tests in the authoring environment.

### DEV18 (2026-11-07): physical environmental interactions and discoverable ambience

New Level 0 wall markings, Level 1 industrial pressure valves, Level 8 road/sign and branch-formation surveys, Level 37 sensory Poolrooms interactions; 17 low-frequency atmosphere events across L000, L001, L008, L037, and L009; an optional persistent field journal; chunk-owned interaction bodies; native Godot dev18 QA suite. See `DEV18_README_FIRST_CN.md` and `docs/production/DEV18_沉浸式交互开发报告.md`. Static checks are not a substitute for engine QA (not performed on this build machine).
