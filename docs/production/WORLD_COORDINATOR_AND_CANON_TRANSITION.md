# WORLD COORDINATOR AND THE CANONICAL LEVEL 0 → LEVEL 1 FOLD

**Branch:** `feature/infinite-backrooms-v5`
**Base:** `ebbf6f7cb6aa58a92f4a090ddc465611bd84c1ad` (`main`)
**Engine:** Godot 4.5.1 stable (`f62fdbde1`)
**Scope of this document:** the persistent coordinator, the canonical transition
it drives, the two geometry defects that were closed with it, and the three
instrument defects that were found while measuring it.

---

## 1. What the laboratory did not have

The v5 laboratory shipped a complete procedural world: multiscale planning,
deterministic streaming, persistent chunk state and a physics walker that
crosses seams, climbs staircases and crosses the atrium bridge. It had exactly
one way to move between places, and it was not enough.

* **No persistent player.** The laboratory spawned its own `Player`. The story
  system's `TransitionService` created a *different* `Player` in the
  destination and carried a handful of numbers across
  (`TransitionService.carry`: pitch, local velocity, flashlight, crouch). The
  inventory, the body state, the light and the node identity were lost.
* **No non-Euclidean transfer.** The v5 handoff says it plainly: *"No noclip
  and no canon transitions in the lab. The three connection kinds are specified
  in the coordinate document, but only PHYSICAL is implemented."*
* **No canonical route.** The laboratory could not reach any canonical level.
  The `L001_PROXY` zone was, correctly, never presented as Level 1.

---

## 2. The coordinator

`core/world/WorldCoordinator.gd`

The coordinator lives under the scene-tree **root**, not inside a level, so it
survives a scene change. It owns the wanderer.

### 2.1 Three connection kinds, never conflated

| Kind | Meaning | What the coordinator does |
|---|---|---|
| `PHYSICAL` | the two places are adjacent in space | nothing — the player walks across |
| `NOCLIP` | a non-Euclidean fold to a place that is not adjacent | moves the player, keeps the session |
| `CANON_STORY` | a documented story route | moves the player, keeps the session, and the edge must come from a canon manifest |

`WorldCoordinator.validate_kind()` refuses a mismatch:

* a `NOCLIP` transfer of an edge whose trigger is not `noclip` is rejected;
* a `CANON_STORY` transfer of a laboratory adaptation edge is rejected — an
  adaptation can never be passed off as a canon route;
* a `PHYSICAL` transfer is rejected outright — a physical connection needs no
  transfer, and pretending otherwise is how a walkable corridor turns into a
  teleport.

### 2.2 The transfer

```
transfer(edge_id, kind)
  -> resolve_edge()          story manifest first, then the laboratory table
  -> validate_kind()
  -> capture_session()       light, crouch, pitch, local velocity
  -> freeze the player
  -> identify the PLACE that is being left          (see 2.3)
  -> detach the player to the tree root
  -> release that place and wait for the physics world to drop its bodies
  -> load the destination scene
  -> wait until the destination reports `built`
  -> take the destination's VALIDATED arrival transform
  -> reparent the player into the destination
  -> apply the destination's rules, then restore the carried state
  -> re-point the destination's streamed world at the persistent player
```

Three details matter:

* **The arrival is validated by the destination, not by the coordinator.** The
  destination spawns its own player at the declared arrival, runs its own
  `_validate_spawn()` (a capsule sweep for clear ground), and the coordinator
  then adopts that validated transform. The coordinator never guesses a place.
* **The player is moved, not rebuilt.** `Node.reparent()` moves the same node.
  The instance id before the fold is the instance id after it. The destination
  level's own player is discarded. There is exactly one player afterwards, and
  the test asserts both facts.
* **The place is released before the destination is created**, and the
  coordinator waits until the physics world has really dropped that place's
  collision bodies. Two streamed worlds alive at the same time share one
  physics space, and the Jolt job system then runs out of slots.

### 2.3 Which place is being left

This is the one decision in the coordinator that is easy to get wrong, and
getting it wrong is not a cosmetic bug.

`get_tree().current_scene` is the obvious answer, and in the game it is the
right one: the level scene *is* the current scene, and the player is its direct
child. But a place can be a child of the tree root that is **not** the current
scene — the laboratory under test is exactly that, and so is any streamed
overlay in the game.

Releasing the wrong node has three consequences, and all three were observed:

1. **The old world stays alive** beside the new one. Two streamed worlds then
   share one physics space, the Jolt job system runs out of slots, it reports
   *"Jolt Physics job system exceeded the maximum number of jobs … Waiting for
   jobs to become available"*, and **the physics frame never fires again**. The
   fold hangs and the process never terminates.
2. **The test harness is destroyed.** In the first version of the native test
   the laboratory was a sibling of the test scene, so releasing
   `current_scene` freed the *test*. The test's watchdog and its report writer
   went with it, so the run hung with no output at all — a failure that looks
   exactly like a hang and is not one.
3. **Nothing in the code says so.** The release is a `queue_free()` on a
   plausible-looking variable.

The rule the coordinator uses is **ownership**, not identity:

```gdscript
func _source_place() -> Node:
    var root := get_tree().root
    var current := get_tree().current_scene
    if player != null and is_instance_valid(player):
        # Preferred: the current scene, when it really is the place the
        # wanderer stands in. This keeps the coordinator consistent with
        # TransitionService.load_level in the game.
        if current != null and is_instance_valid(current) and _is_ancestor_of(current, player):
            return current
        # Otherwise: the top-level ancestor of the wanderer. That node owns
        # the geometry, the collision bodies and the streaming of the place.
        var n: Node = player.get_parent()
        while n != null and n != root:
            var parent := n.get_parent()
            if parent == null or parent == root:
                return n
            n = parent
    return current
```

The coordinator then refuses to run at all if the place it resolved is itself
or the tree root, and the native test asserts that the laboratory place was
really released — by **instance id**, because a released node reference reads
as `null` in GDScript (see §6.3).

### 2.4 Autoloads are resolved at runtime

`LevelRegistry` and `TransitionService` are looked up through
`Engine.get_main_loop()` at call time, never as compile-time identifiers. A
headless `--script` run has no autoloads, and a hard reference made the world
classes unloadable there — that was one of the five defects the v5 session
already fixed in `ChunkWorld3D`, and the same discipline is kept here.

---

## 3. The canonical route

### 3.1 What the source says

`data/canon/transitions.json` and `levels/L000/level.json` both declare:

| Field | Value |
|---|---|
| edge id | `L000>L001#1` |
| trigger | `noclip` |
| label | "Threw yourself through a flickering wall" |
| basis | `SOURCE` |
| source quote | "find a flickering wall to throw yourself through" |
| hint | "Some wall sections flicker and crackle. Arch rooms seem to hold them more often. Sprint into one and keep pushing." |
| arrival | `from_L000` |

Level 1 declares `from_L000` among its arrivals, and its scene is
`res://levels/L001/L001.tscn`.

### 3.2 The laboratory edge

The laboratory is an **adaptation** of Level 0, not the canonical Level 0
scene. It therefore does not get to invent a route. It declares an
*adaptation edge* that names the canon edge it realises:

`data/lab/transitions.json`

```json
{
  "id": "LAB>L000>L001#1",
  "from": "LAB",
  "to": "L001",
  "trigger": "noclip",
  "basis": "ADAPTATION",
  "canon_edge": "L000>L001#1",
  "arrival": "from_L000"
}
```

`WorldCoordinator.resolve_edge()` then **requires** the canon edge to exist. If
`L000>L001#1` were ever removed from the canonical manifests, the laboratory
edge would stop resolving and the fold would stop working — the adaptation
cannot outlive the source it points at.

The destination is the **real Level 1 scene**, loaded through the level
registry. There is no proxy, no stand-in and no `L001_PROXY`.

### 3.3 The flickering wall

`labs/Level0ContinuityLab.gd::_add_canon_portal()` builds it in the spawn
chunk, on the north boundary:

* the **same material** the canonical Level 0 uses (`l0_wall_flicker`, defined
  with the same emission and flicker parameters), so the wall reads exactly
  like the one the source page describes;
* a buzzing light in front of it and a crackle;
* a `LabPortal` with the `noclip` trigger, which requires the player to **push
  into** the volume for 1.2 s, exactly like the canonical Level 0 exit.

The placement is deterministic and independent of the seed. It is clear of
every declared portal, every stair slot, the atrium well and the structural
pilasters of the megastructure.

`LabPortal` differs from `ExitTrigger` in one way: it hands the edge to the
coordinator instead of calling `TransitionService.request_exit()`.

### 3.4 The portal does not await the fold it starts

The portal **latches** until the fold has actually completed: the destination
takes seconds to load, and a trigger that re-fired in the meantime would start
a second, competing transfer. The latch is released by the coordinator's
`transfer_completed` / `transfer_failed` signals, not by a loop inside the
portal.

That matters because **the fold releases the place the portal lives in**. A
portal that awaited the transfer from inside itself would be resuming a
destroyed instance. The upstream story exits already rely on exactly this
pattern: `TransitionService.request_exit()` calls the coroutine `load_level()`
without awaiting it, and the engine keeps such a coroutine alive until it
finishes. (An earlier version of `LabPortal` did await it, with a comment
claiming that an un-awaited call "would leave it suspended forever" — that
claim was wrong, and the upstream code was the counter-example.)

### 3.5 The destination is loaded ahead of the fold

The destination scene is loaded **while the player is still walking towards
the portal**, so the fold itself is a cache hit. The one-off cost belongs in
the approach, not in the transition.

---

## 4. Two geometry defects that were closed with it

The v5 handoff listed six known issues. Two of them were geometry defects in
the laboratory, and both were closed in this session.

### 4.1 The open stairwell (v5 known issue 2)

The floor opening of a staircase was **4.2 m** wide, but the ramp that fills
it was **2.4 m** wide and did not start where the opening did. The difference
was an unguarded strip of open floor beside the ramp, and a 1.4 m gap in front
of it — a 4.5 m drop to the storey below, reachable by walking.

**The fix.** The hole and the ramp are now **one rectangle**, by construction:

```gdscript
# core/world/ContinuityTopology.gd
static func stair_slot(shaft: int) -> Rect2:
    return Rect2(shaft_x(shaft) + 0.3, STAIR_Z0, STAIR_WIDTH, STAIR_RUN * STAIR_STEPS)
```

The floor builder and the ramp builder both read that one rectangle. A hole
can no longer be wider or longer than its ramp, because they are the same
value. The floor opening went from 4.2 m × 13.2 m to **2.4 m × 12.0 m**, which
is exactly the ramp's footprint.

### 4.2 A door that opened onto the stairwell (v5 known issue 3)

The lateral position of a face door was drawn from `{8, 12, 16}`. The stairs
occupy z ∈ [6.8, 18.8] and two narrow x bands, so a door could open straight
onto the stairwell.

**The fix.** The door position is now derived from the stair geometry, and the
door is 4 m **wide**, so the whole opening has to be clear, not only its
centre:

| Face | Lateral axis | Positions | Why |
|---|---|---|---|
| east / west | z | 3.0, 4.5, 21.0 | clear of the stair run; on the shared circulation lanes |
| north / south | x | 11.0, 12.0, 13.0 | clear of both shaft bands; in line with the door of the room partitions |

The old check in the topology test — *"the door is between 8 m and 16 m"* — was
a proxy for safety, and the defect it missed is exactly what it let through.
It is replaced by the invariant that actually matters:

```gdscript
_check("door clear of every stair slot",
    not ContinuityTopology.opening_hits_stair(off, 4.0, axis), ...)
```

`ContinuityTopology.opening_hits_stair()` is the shared definition of "this
opening touches a stair", used by the test and available to any future
generator.

---

## 5. What is proven, and how

`tests/ContinuityCanonTransitionTest.gd` (a **scene** run, so the autoloads
exist).

The test does not read a table and declare victory. It drives a real
`CharacterBody3D` into the flickering wall with the physics engine and then
inspects the world. **37 checks, 0 failures.**

| Group | Check | What it proves |
|---|---|---|
| edge | the laboratory edge resolves | the adaptation is declared |
| edge | it names the canon edge `L000>L001#1` | the adaptation points at a canon edge |
| edge | it is labelled `ADAPTATION` | it is not passed off as canon |
| edge | it points at the real Level 1 | no proxy destination |
| edge | the canon edge resolves from the canonical manifest | the source route exists |
| edge | the canon trigger is `noclip`, basis `SOURCE` | it is the documented route |
| edge | the canon edge carries a source quote | it is traceable to the page |
| edge | the arrival is `from_L000` | the arrival is one the destination has |
| dest | the destination is `res://levels/L001/L001.tscn` | the real Level 1 |
| dest | the Level 1 scene exists on disk | it is really there |
| dest | Level 1 declares `from_L000` | the arrival is real |
| dest | no proxy level is used | `L001_PROXY` is never substituted |
| portal | the laboratory built the portal | the exit is real geometry |
| portal | it fires the laboratory edge, kind `noclip` | it is wired to the right edge |
| walk | the runner stands on solid ground in front of the wall | the wall is approachable |
| walk | the runner reaches the trigger volume | the trigger is where it is drawn |
| walk | the player survived the approach | nothing died on the way |
| fold | the fold completes **exactly once** | one transfer, not two |
| dest | the session is in Level 1 | the destination took effect |
| dest | the current scene is Level 1 | the scene was replaced |
| dest | it runs `res://levels/L001/L001.gd` | the canonical script, not a stand-in |
| player | **exactly one player node** exists afterwards | no duplicated or leaked player |
| player | the player's instance id is unchanged | the node was **moved**, not rebuilt |
| player | the player belongs to the Level 1 scene | the handover is real |
| player | Level 1 drives the persistent player | the level's own reference was updated |
| player | the player stands on solid ground in Level 1 | the arrival is valid |
| player | the carried light state survived | the session was carried, not reset |
| release | the laboratory's streamed world was released | no leaked world |
| release | the laboratory **place** was released | the right node was released, not merely its chunks |

Report: `reports/qa/continuity_canon_transition.json`.

Run it with:

```
godot --headless --path . --fixed-fps 60 res://tests/ContinuityCanonTransitionTest.tscn
```

---

## 6. Three instrument defects that were found while measuring it

These are recorded because each of them produced a **clean, plausible, wrong
number**, and each of them is a trap that the next session will meet again.

### 6.1 A counter that was declared but never incremented

`ChunkWorld3D.stream_stats` declares `{"built": 0, "unloaded": 0, …}`. The
`unloaded` counter was incremented in `_unload()`. The **`built` counter was
never incremented anywhere** — `_build()` did not touch it.

So every measurement that read it reported **zero chunks built**, while the
streamer was in fact building chunks. The number was not wrong by a little: it
was wrong by the whole quantity being measured, and it looked exactly like a
correct answer.

*Fixed:* `_build()` now advances the counter where the chunk is registered.

### 6.2 The engine's frame-time monitors do not measure the frame cost

`Performance.TIME_PROCESS` and `Performance.TIME_PHYSICS_PROCESS` report a
near-constant value under `--fixed-fps`: in the recorded gate run, the *cold
start* median and the *cold start* maximum were **both exactly 16.074 ms**,
and the *steady state* median was the same number. A statistic whose median,
p95, p99 and maximum are identical has **zero resolution**: it cannot tell a
cheap frame from an expensive one.

The cross-check is arithmetic and does not depend on the engine:

| Quantity | Value |
|---|---|
| iterations measured | 954 |
| engine monitor median | 16.074 ms |
| implied total | 15.3 s |
| **measured wall clock of the measured section** | **1.486 s** |

The engine monitor over-reports by about **10×**. The wall clock does not:
954 iterations at a 0.842 ms median is 0.80 s, which fits inside the 1.486 s
the section actually took.

*The number that is believed is therefore the wall clock.* The probe measures
it independently of the engine, and it validates itself two ways:

* the per-sample wall times must **add up** to the elapsed time of the measured
  section (within 25 %);
* the wall clock must have a **wider relative spread** than the engine
  monitor — otherwise the instrument that is believed has no more resolution
  than the one that is distrusted.

Both checks are part of the probe, and both pass.

### 6.3 A released node reference reads as `null`

`is_instance_valid(world)` on a reference to a node that has been freed is
**false** — and so is `world != null`. A check written as

```gdscript
_check(world != null and not is_instance_valid(world), "the laboratory was released")
```

therefore **fails on a correctly released world**, because the guard
`world != null` is false for a freed node. The first version of the test
reported this failure while the laboratory had in fact been released perfectly.

*Fixed:* the test keeps the **instance id** of the node and asks
`is_instance_id_valid(id)` after the fold. An id that no longer resolves is a
node that is really gone, and the check can no longer be satisfied by a
reference that was never valid.

---

## 7. Measured performance

`tests/ContinuityPerformanceProbe.gd` walks the player along the **same route
the physical walk test proves is walkable** — out through the declared east
portal, back along the lane, out through the declared west portal into
negative coordinates, and home again — so that the streamer really has to
build and unload chunks while the measurement runs.

The probe **checks** that it measured something: that every leg was walked,
that the player travelled, that chunks were built and unloaded during the
measurement, and that the streamed world has real geometry and real collision.
(An earlier version of the probe reported a clean 19.7 ms median while the
player had never left the spawn chunk and not one chunk had been built.)

**Headless CPU numbers, Godot 4.5.1, RTX-less dummy renderer** (the run whose
log is committed in `reports/infinite_world/gate10_performance.log`):

| Statistic | Per frame |
|---|---|
| median | **0.822 ms** |
| p95 | 1.837 ms |
| p99 | 17.107 ms |
| max | 35.536 ms |

These are wall-clock samples, so they move a little from run to run: an earlier
run of the same probe measured median 0.84 ms, p95 2.14 ms, p99 15.37 ms,
max 29.14 ms. The **median** is stable to about ±0.03 ms; the **tail** is not,
because the tail is the chunk-build burst and the burst lands on a different
frame each time. Any single number from the tail should be read as "one burst",
not as a bound.

The 60 fps budget is 16.667 ms. The median is comfortably inside it; the tail
is not, and the tail is the chunk-build burst (`builds_per_frame = 2`, so up to
two whole chunks are generated in one frame).

**Streaming during the measured section:**

| Quantity | Value |
|---|---|
| chunks built | 18 |
| chunks unloaded | 9 |
| peak resident chunks | 36 |
| peak triangles | 34 012 |
| peak colliders | 1 147 |
| distance walked | 68.9 m |

The walk really crossed chunk seams: the probe's four legs ended in chunks
`(1,0,0)`, `(0,0,0)`, `(-1,0,0)` and `(0,0,0)`, and the probe fails the run if
a leg is not reached or if no chunk is built or unloaded while the player is
moving.

**What is NOT claimed:** GPU frame time. The run is headless, there is no
renderer, and the cost of drawing 34 012 triangles on a real GPU is
`UNVERIFIED`. So is playability with a human at the keyboard.

---

## 8. What is NOT claimed

* The fold is verified in **headless Godot 4.5.1 with the physics engine**. It
  has **not** been verified on a Windows GPU build with a human at the
  keyboard. That is listed as `UNVERIFIED` in the QA matrix.
* Only the `L000 → L001` route is implemented. The other three kinds of edge
  in the canon graph are not yet reachable from the laboratory.
* The laboratory edge is an `ADAPTATION`. It is not presented as canon, and it
  cannot be, because the laboratory is not the canonical Level 0 scene.
* The transition does not write the story save. The laboratory runs in
  developer mode, and the coordinator deliberately leaves the canonical
  checkpoint and journal untouched.
* The performance numbers are **CPU numbers from a headless run**. They are
  not a frame-time budget for the shipping game.

---

## 9. The shipped build printed an engine error on every boot

This section is about the **exported Windows executable**, and about the check
that was supposed to cover it and did not.

### 9.1 The symptom

Every boot of the exported build printed:

```
ERROR: Parent node is busy adding/removing children, `remove_child()` can't be called at this time. Consider using `remove_child.call_deferred(child)` instead.
   at: remove_child (scene/main/node.cpp:1718)
```

`MainMenu._ready()` is where the `--lab` command line entry point lives, and it
called the scene change straight from `_ready()`:

```gdscript
func _open_world_lab() -> void:
	SessionState.set_mode(SessionState.Mode.DEVELOPER)
	get_tree().change_scene_to_file("res://labs/Level0ContinuityLab.tscn")
```

The engine, replacing the outgoing scene, calls `root->remove_child(old_scene)`.
That call happens **inside** `root->add_child(main_scene)`, so root is still
committing the main-scene insertion and refuses the removal.

### 9.2 How bad it actually is — measured, not inferred

The first reading of this defect was "the laboratory never opens in the shipped
build". An A/B on the same tree, with one file swapped and nothing else
changed, says otherwise:

| Variant | `Parent node is busy` errors | laboratory started |
|---|---|---|
| pre-fix (synchronous `change_scene_to_file`) | **1** | **yes** |
| post-fix (deferred) | **0** | **yes** |

The outgoing scene is still disposed — by the deferred `queue_free()` one frame
later — so nothing leaks. **The honest severity is: a spurious engine error on
every boot of the shipped build, and a removal the engine explicitly refused.**
That is exactly the hazard the engine's own message warns about, and it is not
a cosmetic matter: an error on every boot is the first thing a reviewer sees,
and it is the kind of error that hides the *next* error.

The evidence is in `reports/infinite_world/mainmenu_ab.log`.

### 9.3 The check that said "clean" and was measuring the wrong process

The first version of this session ran the same command against the **editor
binary**:

```
Godot_v4.5.1-stable_win64_console.exe --headless --path <project> -- --lab
```

and reported **zero errors**. That was a false negative, and the reason is
mundane: `godot --path <project>` with **no scene argument opens the editor**.
The measured process was a headless editor sitting idle. It never executed
`MainMenu._ready()`, so it could not produce the error.

* **A run that does not reach the code cannot report a defect in it — and it
  cannot certify the absence of one either.** The instrument has to be shown to
  have reached the thing it is measuring, and the only way to show that is a
  positive signal from inside the code under test.

That is why the laboratory now prints one line the moment its scene is live:

```
[ContinuityLab] ready seed=1337 world_id=L000_CONTINUITY_PROTOTYPE
```

A silent process proves nothing; this line does.

### 9.4 The fix

The engine's message says what to do: defer the removal. The scene change is
now deferred by one frame, so it runs when the tree is idle:

```gdscript
func _open_world_lab() -> void:
	SessionState.set_mode(SessionState.Mode.DEVELOPER)
	get_tree().call_deferred("change_scene_to_file", "res://labs/Level0ContinuityLab.tscn")
```

The laboratory already used `call_deferred` for the same reason when it
re-enters itself for a new seed (`_switch_seed`). The menu was the one path
that did not.

### 9.5 A QA entry point that hung instead of failing

`--shot` waited on `await RenderingServer.frame_post_draw`, which **never
fires** under the dummy renderer that `--headless` uses. The run therefore
hung for ever and looked like a slow success — the same failure shape as §9.3,
one level down. The shot path now refuses to pretend:

```
SHOT failed: the headless display server cannot render a frame
```

and exits with status 2. A headless capture is not possible; a windowed one is.

### 9.6 Evidence from the exported executable

| Run | Command | Engine errors | Laboratory |
|---|---|---|---|
| headless | `LostFrequency-InfiniteBackrooms-v5.exe --headless --fixed-fps 60 -- --lab` | **0** | starts |
| windowed | `LostFrequency-InfiniteBackrooms-v5.exe --fixed-fps 60 -- --lab --shot=<png>` | **0** | starts, renders |

The windowed run is a real Vulkan frame from the shipped build
(`Vulkan 1.4.351 - Forward+ - Using Device #0: NVIDIA - NVIDIA GeForce RTX 3060 Laptop GPU`),
1600×900, kept as `reports/infinite_world/continuity_lab_release_build.jpg`.
The raw logs are `reports/infinite_world/release_boot_headless.log` and
`reports/infinite_world/release_boot_windowed.log`.

**Still not claimed:** a human at the keyboard on the shipped build. The frame
proves the renderer draws the laboratory; it does not prove the game is
*playable*. See §8.

---

## 10. The six instruments the brief asked for, and the three defects they found in each other

The brief's seventh requirement is the one a static check cannot satisfy:
*"physically walk between chunks and floors, verify transitions, stress-test
long-distance exploration, test saving and reloading. Static-code checks alone
do not demonstrate playability."* Requirement 3 asks for loops and hidden
regions, requirement 4 for guaranteed connectivity, requirement 6 for LOD and
occlusion. This section is about the native Godot tests that answer those, and
— more usefully — about the three defects the instruments found **in the
instruments**, each of which had produced a green result.

### 10.1 The six tests

| # | Test | Requirement | What it actually proves | Result |
|---|---|---|---|---|
| 11 | `ContinuityConnectivityTest` | 1, 4 | Every chunk of a 7×7 area is connected to the spawn through real doorways: a seam graph BFS, then a per-chunk flood fill with the player's own capsule, then a walkable-area count per chunk. Any disconnected component must be a **declared** hidden region. | 152 checks, 0 failures |
| 12 | `ContinuityLoopWalkTest` | 3 | The megastructure publishes one closed circuit ring; the ring is present in the **built mesh** (vertices in the 2–20 mm band the floor slab never reaches); and a real body walks the four-chunk ring and comes home. | 17 checks, 0 failures |
| 13 | `ContinuityHiddenRegionTest` | 3 | A dead-end vault with **exactly one** opening, proved by a physics sweep rather than by sampling: a 1.4 m mouth is thinner than a uniform grid can cross, so any grid flood fill would silently fail to prove it. | 16 checks, 0 failures |
| 14 | `ContinuityStressTest` | 7 | A body walks 134.8 m through six chunk seams on a route planned on the player's own walkable grid; then a 40-chunk sweep proves chunks stream in and out, that the resident count stays bounded, and that a change made before the sweep is still there after it. | 12 checks, 0 failures |
| 15/16 | `ContinuityPersistenceTest` | 7 | The save → restart → reload round trip, split across **two processes** because a single process cannot tell "the disk works" from "the in-memory scope was never cleared". | 22 checks, 0 failures |
| — | `ContinuityGpuProbe` | 6 | LOD, the visibility range and occlusion culling measured on a **real GPU in a window**: draw calls, objects, primitives and frame time for four configurations, three interleaved rounds each; plus the lifecycle of a chunk's detail in both directions. | 9 checks, 0 failures |

The GPU probe is deliberately **not** in the headless gate. The headless display
server has no renderer, so a headless run of that file would report zero draw
calls and a perfect frame time — the exact kind of green that means nothing.
Run windowed, it refuses to start:

```
GPU PROBE: the headless display server has no renderer.
```

### 10.2 The first instrument defect: "stuck" was measured as net displacement

The long walk failed on its first run. The body stopped at world position
`(119.31, 0.02, 14.76)` with 18 of 26 waypoints reached, and the walker had
been asked to recover **2 817 times**.

The walker was not stuck. The trace showed it walking towards its waypoint at
about three metres per second, being dragged back to the corner, walking
forward again, and being dragged back. The reason it was dragged back was the
**stuck detector itself**:

```gdscript
if player.global_position.distance_to(_last_progress) > 1.6:   # OLD
    _last_progress = player.global_position
    _stuck = 0
else:
    _stuck += 1
```

Progress was measured as *net displacement from an arbitrary earlier
position*. A body that walks a metre towards its target, turns a corner and
walks a metre back has covered two metres and arrived where it started, and
that instrument calls it stuck. The fix is to measure the thing that actually
means progress:

```gdscript
if distance < _best - 0.02:      # NEW
    _best = distance
    _stuck = 0
else:
    _stuck += 1
```

**A "stuck" detector must watch the distance to the target, not the distance
from an anchor.** The anchor version cannot distinguish "the body is wedged"
from "the body is on a detour", so it fires on every corner.

### 10.3 The second instrument defect: "reached" was looser than the corner

With the detector fixed, the walker still stopped — 0.9 m short of a waypoint
that sat in a doorway, facing a wall. The cause was the second radius:

```gdscript
const REACH := 1.0     # OLD: a waypoint counts as reached from a metre away
```

The route turned a corner at a point that was **0.88 m away**. A radius of
1.0 m therefore let the body "reach" the corner while it was still on the wrong
side of it, turn towards the next waypoint, and walk into the partition wall
that the corner exists to go around. The radius is now **0.4 m**, smaller than
the planner's 0.75 m grid step, so the body has to arrive at a corner before it
is allowed to leave it.

**A waypoint that marks a corner has to be reached, not approached.** A
reach radius that is large compared with the geometry turns every corner into
a wall.

### 10.4 The third instrument defect: the two halves of the round trip wrote one report

`ContinuityPersistenceTest` runs its write half and its read half in two
separate processes — that is the whole point of the test — but both halves
wrote their findings to `continuity_persistence.json`. The read half ran last
and **overwrote the write half's evidence**, so the report showed 9 checks
where the run had made 22.

**An instrument that overwrites its own evidence is an instrument that can
only ever show the last thing that happened.** The two phases now write to
`continuity_persistence_write.json` and `continuity_persistence_read.json`.

### 10.5 The two pieces of shared test infrastructure, and why they are shared

Two files carry the walking:

* `tests/ContinuityPathFinder.gd` — lays a grid of points the player's capsule
  fits in, searches it, and removes the corners of the result with a physics
  sweep, so the body is only ever asked to walk along a line it can walk.
* `tests/ContinuityWalker.gd` — drives the body. It probes the directions
  around the desired one with the player's **own** collision shape and picks
  the first one that is actually free; it never walks backwards into a side
  room (a free heading that turns *away* from the target is rejected); and it
  backtracks along the route it has already walked when it does stall.

They are shared on purpose. The first version of the walker lived in two files
at once, and a bug in it — a detour offset that was never cleared, so a body
that had detoured once walked 100° off its route for the rest of the walk —
had to be fixed in two places. **One walker, one planner.** The stress test and
the loop test now use the same body behaviour, so a bug in the body cannot
show up in one test and hide in the other.

The planner's clearance is 2 cm, not 0, and that is not tidiness. Godot's
physics server keeps transforms in **float32**, so a capsule placed flush with
the floor lands 2.4 × 10⁻⁷ m inside it in half of the chunks and reads as a
collision. With a zero clearance, three chunks of a nine-chunk area were
reported as "not standable" — **the defect was in the instrument, not in the
world**, and the way to tell the two apart was to look at the magnitude of the
penetration.

### 10.6 LOD, the visibility range and occlusion culling, measured

Measured on an **NVIDIA GeForce RTX 3060 Laptop GPU**, Vulkan 1.4.351, three
interleaved rounds of 60 frames each, median of the rounds. The four
configurations are interleaved rather than measured one after the other,
because a laptop GPU that is shared with the desktop drifts, and a number
measured now and a number measured two minutes later are not the same
measurement.

| Configuration | Draw calls | Objects | Primitives | Frame time | Chunks by detail |
|---|---|---|---|---|---|
| baseline | 189 | 189 | 35 608 | 2.61 ms | 75 × detail 0 |
| geometric LOD only | 181 | 181 | 35 194 | 2.39 ms | 27 × detail 0, 48 × detail 2 |
| + visibility range 40 m | **76** | 76 | **15 394** | 2.42 ms | 27 × detail 0, 48 × detail 2 |
| + occlusion culling | **71** | 71 | **15 310** | 2.42 ms | 27 × detail 0, 48 × detail 2 |

Reading the four rows separately, because the mechanisms are not additive:

* The **visibility range** is where the money is: it takes **59.8 % of the
  draw calls** and **56.8 % of the primitives** away, and it costs nothing
  but a range on a mesh, because the geometry beyond it is never drawn and is
  never rebuilt.
* The **geometric level of detail** alone takes **1.2 % of the primitives**
  and 4.2 % of the draw calls. That is small on purpose: the walkable world —
  the floor, the walls, the stairs, the partitions, the columns — is built at
  **every** level of detail, so a far chunk is a cheaper chunk and not a
  *different* chunk. A level of detail that dropped the walls would make the
  topology of the world depend on the distance of the camera, and the player
  would walk through a wall that was there a moment ago. (The offline Python
  contract `test_routing_does_not_depend_on_mutable_room_versions` caught
  exactly that mistake when it was introduced.)
* The level of detail works in **both** directions. A chunk that the wanderer
  has left behind gives its detail back while it is still resident — the
  probe walks the camera three chunks away and watches the chunk it left go
  from detail 0 to detail 2. A level of detail that only ever *added* detail
  would save nothing in a world that is explored, because the chunks the
  wanderer has visited are exactly the ones that are kept. The two
  directions have different thresholds, so a wanderer walking back and forth
  over the edge of a band does not rebuild the same chunk every few seconds.
* **Occlusion culling** takes another 5 draw calls (6.6 %) and 84 primitives
  on top of that. The occlusion instances are real: **75 `OccluderInstance3D`
  nodes**, one set of wall spans per chunk, with the door gaps left open so
  that what is visible through a doorway is never culled. With the level of
  detail inert — the first configuration measured, where `lod_far_chunks`
  equalled the streaming radius and no chunk ever left the decorative tail —
  occlusion culling on its own took the draw calls from 189 to **133
  (−29.6 %)**. The two mechanisms overlap: the more the level of detail
  removes, the less is left for occlusion to hide.

Two more things are worth stating plainly:

* **The frame time barely moves** (2.61 ms → 2.42 ms). At this scale the
  scene is far below the capacity of the GPU, so the win is in *what the
  renderer draws*, not in milliseconds. On a scene that actually reaches the
  frame budget the same ratio is worth far more than 0.2 ms.
* The project setting `rendering/occlusion_culling/use_occlusion_culling` is
  now **on**, and the probe asserts it, because with it off the fourth
  configuration is byte for byte the third one and the comparison would be a
  comparison of a world with itself.

### 10.7 What is still NOT claimed

* **A human at the keyboard.** Every number in §10.6 comes from a robot
  walking a route a planner computed for it. The GPU probe proves the renderer
  draws the world cheaply; it does not prove the game is playable.
* **The occlusion and LOD numbers are for one camera position** in one seed.
  They are a measurement, not a budget.
* **The GPU probe is not in the headless gate.** It is a separate windowed
  command, and it says so loudly when it is run headless.


