# Infinite Backrooms v5 — World Coordinates and Connectivity Specification

Status: implemented and natively verified on Godot 4.7.2 (Windows).
All values below are the literal constants in
`core/world/ContinuityTopology.gd` and `core/world/RegionalPlan.gd`.

---

## 1. Coordinate system

Right-handed, Y up, metres.

| Quantity | Value | Source |
|---|---|---|
| Chunk footprint | 24 m × 24 m | `ContinuityTopology.WIDTH` |
| Storey height | 4.5 m | `ContinuityTopology.FLOOR_HEIGHT` |
| Lowest storey | −2 (y = −9.0 m) | `ContinuityTopology.MIN_FLOOR` |
| Highest storey | +2 (y = +9.0 m) | `ContinuityTopology.MAX_FLOOR` |
| Ceiling height | 4.25 m | `labs/Level0ContinuityLab.gd` `H` |

```
chunk_key(world_position)  =  ( floor(x / 24), floor(y / 4.5), floor(z / 24) )
chunk_origin(key)          =  ( key.x * 24, key.y * 4.5, key.z * 24 )
```

Negative coordinates use `floor`, not truncation, so chunk (−1, y, −1) spans
x ∈ [−24, 0) and z ∈ [−24, 0). The origin of chunk (0, 0, 0) is world
(0, 0, 0).

A full address is
`WorldAddress(world_id, zone_id, chunk_x, chunk_y, chunk_z, local_position)`.

---

## 2. Zone map

A zone is one 8 × 8-chunk superdistrict (192 m square).

```
super_key(k)  =  ( floor(k.x / 8), 0, floor(k.z / 8) )
district_key  =  ( floor(k.x / 16), 0, floor(k.z / 16) )
macro_key(k)  =  ( floor(k.x / 4),  0, floor(k.z / 4)  )
```

| Zone id | Meaning |
|---|---|
| `Z_L000_YELLOW` | the spawn superdistrict — canonical Level 0 look-alike |
| `Z_PROXY_WAREHOUSE` | one whole superdistrict of bare concrete (non-canon) |
| `Z_<sx>_<sz>` | every other superdistrict |

The warehouse superdistrict is `proxy_super_key(seed)`:
`x = 1 + roll(0..3)`, `z = roll(0..2)`. It is never `(0, 0)`, so the spawn
superdistrict — and with it the central hub at chunks x = 3..4, z = 3..4 —
always belongs to exactly one zone.

**Invariant (natively asserted):** for every seed, the four hub chunks
`(3, y, 3)`, `(4, y, 3)`, `(3, y, 4)`, `(4, y, 4)` are in the same zone as
the spawn chunk.

---

## 3. Shared-face ownership

Every physical border between two chunks is owned by exactly one canonical
shared-face key. Both sides of the seam read the same owner, so the opening
is identical no matter which chunk is generated first.

```
face_owner(k, "east")  = k
face_owner(k, "west")  = k + (-1, 0, 0)
face_owner(k, "north") = k
face_owner(k, "south") = k + (0, 0, -1)

face_axis("east"/"west") = "x"      face_axis("north"/"south") = "z"

border_slot(seed, owner, axis) = 1 + roll(0..2)
border_offset(seed, owner, axis) = 4 + 4 * border_slot   →  8, 12 or 16
face_offset(seed, k, face) = border_offset(seed, face_owner(k, face), face_axis(face))
```

`face_offset` is the **distance along the wall** of the opening's centre
measured from the wall's start corner:

* east / west faces: measured along **z** from the chunk's south corner,
* north / south faces: measured along **x** from the chunk's west corner.

The opening is 4 m wide, so it spans 6–10, 10–14 or 14–18.

**Invariant (natively asserted, 100 997 assertions):** for every seed and
every coordinate, `face_openings(seed, k, face)` equals
`face_openings(seed, neighbour(k, face), opposite(face))`.

---

## 4. Opening catalogue

| Seam type | Condition | Openings (local, along the wall) |
|---|---|---|
| macro core | `is_core_edge(k, face)` | 11 m at 12 m; plus a 5 m opening at 21.5 or 2.5 when the chunk has an atrium |
| superdistrict hub | `is_superhub_edge(k, face)` | 12 m at 12 m; plus a 4 m opening at 22 or 2 m over the hub bridge |
| superdistrict spine | `is_super_spine_edge(k, face)` | 16 m at 12 m |
| default | everything else | 4 m at `face_offset` |

Widths are measured so that the four hub chunks form one 2×2 hall with a
10 m central well and continuous bridges, and the two-chunk-wide spines form
uninterrupted boulevards.

---

## 5. Vertical connectivity

Two alternating stair shafts per superdistrict column:

```
outgoing_shaft(storey) = storey mod 2            0 or 1
incoming_shaft(storey) = outgoing_shaft(storey - 1)
shaft_x(0) = 6.0 m      shaft_x(1) = 15.0 m
```

* The **outgoing** ramp of a storey is built at
  `(chunk.x*24 + shaft_x(outgoing) + 1.5, chunk.y*4.5, chunk.z*24 + 6.8)`,
  2.4 m wide, 20 steps, 0.6 m run, rising 4.5 m towards +z.
* The **incoming** hole in the floor of the next storey is cut at the same
  shaft, so the ramp always lands in the slot it came from.
* Because the shafts alternate, the up-ramp and the down-well of a storey are
  always in different x bands: on storey 0 the ramp is at x ∈ [5.4, 9.6] and
  the well at x ∈ [14.4, 18.6], and vice versa on storey 1.

Each storey therefore offers two vertical routes in and two out.

**Floor contract.** The floor of a storey is solid everywhere except the
incoming slot and, in the macro core, the atrium well. The slot is
x ∈ [shaft_x(incoming) − 0.6, +3.6], z ∈ [5.4, 18.6]; the atrium well is a
5 m × 5 m quadrant in the inner corner of each of the four core chunks;
the bridge restores a 5 m × 3 m strip across that well.

**Invariant (natively asserted):** the well and the bridge are either both
present or both absent, the bridge is inside the well, and the well never
intersects the stair slot.

---

## 6. The three connection kinds

| Kind | Meaning | In the lab |
|---|---|---|
| **PHYSICAL** | an ordinary passage between contiguous parts of the same space | every shared face, every stair, every bridge |
| **NOCLIP** | a non-Euclidean transfer through a portal | **not implemented** in this build |
| **CANON_STORY** | a source-documented transition with conditions and destination rules | **not implemented** in this build |

The lab is a non-canon exploration mode. It has no noclip portal and no
canon exit, and it must not grow one: inventing a canon exit is explicitly
out of scope. The canonical 100-level story keeps its own transition graph in
`data/canon/transitions.json`, driven by `autoload/TransitionService.gd`.

---

## 7. Streaming and persistence contract

| Property | Rule |
|---|---|
| Seed | one integer per world; the seed plus the coordinates fully determine the layout |
| Generator version | `RegionalPlan.GENERATOR_VERSION` and `ChunkWorld3D.GENERATOR_VERSION` = 5 |
| Loaded set | bounded by `radius_xz` / `radius_y` around the player; chunks beyond `unload_xz` / `unload_y` are released |
| Build order | nearest first, biased 6× towards the player's heading |
| Build budget | `builds_per_frame` chunks **and** `build_budget_ms` milliseconds per frame, whichever comes first |
| Cancellation | the wanted set is recomputed every frame, so a chunk the player walked away from is never built |
| Save | one file per world (`user://continuity_lab/world_<seed>.json`), atomic write with a `.bak` rotation |
| Save contents | only the per-chunk **versions** and **changes** that differ from the default; never the geometry |
| Seed isolation | a save stores its `world_id` and its `seed`; a mismatch is rejected, and worlds never share a file |
| Migration | a save written by another generator version keeps the seed and drops the layout versions, which only mean something inside the generator that wrote them |

---

## 8. Known geometry properties (not defects)

* **The stairwell of the incoming shaft is open.** The floor slot is 4.2 m
  wide and the ramp that fills it is 2.4 m wide, so a 1.8 m strip beside the
  ramp is an unguarded well down to the next storey. This is the v4 design
  and it is preserved; the physical walker uses it as a legitimate route.
* **A face opening can land on the stair slot.** The portal offsets (8, 12,
  16) and the slot band (14.4 … 18.6) overlap, so a portal at 16 may open
  partly over the well. The native physical test routes around the two
  lanes (z = 2.2 m and z = 21.5 m) that are solid across a whole chunk.
* **A room partition may sit between two lanes.** The partitions of the
  `archive`, `reading_room`, `shrine`, `observation`, `storage` and
  `machinery` motifs leave a 4.4 m doorway in the middle of each wall. The
  walker finds it by sliding along the wall.
