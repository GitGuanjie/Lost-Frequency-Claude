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

**Headless CPU numbers, Godot 4.5.1, RTX-less dummy renderer:**

| Statistic | Per frame |
|---|---|
| median | **0.84 ms** |
| p95 | 2.14 ms |
| p99 | 15.37 ms |
| max | 29.14 ms |

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
