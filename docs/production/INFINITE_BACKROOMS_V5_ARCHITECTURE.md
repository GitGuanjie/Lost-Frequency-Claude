# Infinite Backrooms v5 — Procedural Generation Architecture

Status: implemented and natively verified on Godot 4.7.2 (Windows).
Scope: the non-canon continuity lab (`labs/Level0ContinuityLab.gd`).
The canonical 100-level story system (`levels/`, `data/canon/`) is untouched.

---

## 1. The problem v4 left behind

v4 generated every 24 m chunk on its own. A chunk rolled its own room motif,
its own theme, its own superstructure and its own partition walls. Two
chunks that touched could look like two buildings that had never heard of
each other, and the only structure that crossed a chunk seam was the pair of
shared wall openings plus the 4×4 macro hall.

v4 also carried a hard-coded district rule:

```gdscript
static func district(k: Vector3i) -> String:
    return "L001_PROXY" if k.x >= 4 else "L000"
```

That rule was wrong twice. It cut the central superdistrict hub (chunks
x = 3..4, z = 3..4) into two different architectural identities, and it
presented a bare-concrete warehouse as if it were the canonical Level 1.

---

## 2. The layer stack

Every layer owns one geometric constraint, and every value in every layer is a
**pure function of (world seed, coordinates)**. Load order, player movement
and the mutable per-room version counter are never consulted.

```
World            identified by world_id (seed + generator version)
 └ District      16 × 16 chunks  (384 m square)  — owns the zone identity
    └ Superdistrict 8 × 8 chunks (192 m square) — owns the megastructure
       └ Megastructure  a rectangle of chunks inside one superdistrict
          └ Macro cell    4 × 4 chunks (96 m square) — owns the hall type
             └ Chunk        24 m square — owns the room motif
```

| Layer | Code | Scale |
|---|---|---|
| District | `RegionalPlan.district_plan` | 16 × 16 chunks |
| Superdistrict | `RegionalPlan.super_plan` | 8 × 8 chunks |
| Megastructure | `RegionalPlan.structure_of` | 4×4 … 8×8 chunks |
| Macro cell | `ContinuityTopology.macro_structure` | 4 × 4 chunks |
| Chunk | `ContinuityTopology.room_type` | 24 m |

`ContinuityTopology` (coordinate-only rules) and `RegionalPlan` (the
multiscale plan) are both `RefCounted` with static functions, so they can be
used from a `--script` headless run that has no autoloads and no scene tree.

---

## 3. World identity and zone addressing

A **zone** is one whole superdistrict (8 × 8 chunks = 192 m square). Because
zone borders follow the superdistrict skeleton, a zone can never cut a
transit hub, a spine or a megastructure in half.

```gdscript
const ZONE_YELLOW := "Z_L000_YELLOW"       # canonical Level 0 look-alike
const ZONE_PROXY  := "Z_PROXY_WAREHOUSE"    # non-canon concrete warehouse
```

* `ContinuityTopology.zone_id(seed, chunk)` — the zone of a chunk.
* `ContinuityTopology.proxy_super_key(seed)` — the one superdistrict that
  holds the warehouse. It is never the spawn superdistrict.
* `ContinuityTopology.zone_id_for_super(s)` — the seed-independent zone of a
  superdistrict.

The warehouse is explicitly **not** canonical Level 1. It is an architectural
adaptation with its own zone id, so a player (or a QA script) can never
confuse "a concrete room that happens to be far east" with "Level 1".

### Explicit addressing

`core/world/WorldAddress.gd` addresses a physical place:

```
world_id | zone_id | chunk_x:chunk_y:chunk_z | local_x,local_y,local_z
```

Canonical Backrooms identity (L000, L001, …) is deliberately **not** part of
the address. A canonical level is a story destination with its own rules and
visual language; a physical coordinate is a place in a generated space.
Keeping the two apart is what allows the yellow zone to keep the Level 0 look
while every other zone is free to have its own identity.

The lab HUD prints the live address, so the player can always tell which
zone and which chunk they are in.

---

## 4. Megastructures

Each superdistrict declares at least one megastructure. The footprint is a
rectangle of chunks inside the superdistrict, taken from a fixed partition so
that two structures in the same superdistrict can never overlap:

| Roll | Footprint (chunks) | Size |
|---|---|---|
| 0 | (0,0)–(8,4) | 192 m × 96 m |
| 1 | (0,4)–(8,8) | 192 m × 96 m |
| 2 | (0,0)–(4,8) | 96 m × 192 m |
| 3 | (4,0)–(8,8) | 96 m × 192 m |
| 4 | (4,4)–(8,8) | 96 m × 96 m |
| 5 | (4,4)–(8,8) **and** (0,0)–(8,4) | corner block + north band |

Four structural kinds give the four silhouettes:

| Kind | Read |
|---|---|
| `arcade` | a continuous colonnade with cornices |
| `machine_hall` | silos, gantries, a wide clear floor |
| `shaft_stack` | slender stacks, ducts, catwalks |
| `archive_block` | shelving rows and aisles |

### Why the bay grid lines up

Every chunk of a megastructure repeats the **same chunk-local bay grid**:
columns at (4.0, 3.7), (20.0, 3.7), (4.0, 20.3), (20.0, 20.3), wall
pilasters at the same four positions, overhead beams on the structure's long
axis, and two continuous floor inlays at z = 2.0 m and z = 22.0 m.

Because the chunk size (24 m) divides the bay spacing evenly, a column at
local x = 4 in chunk *n* and a column at local x = 4 in chunk *n+1* are
exactly 24 m apart in world space. The colonnade therefore reads as **one
building** crossing the seam, not as a row of rooms that happen to line up.

All four bay positions are clear of:

* the stair slot (x ∈ [5.4, 9.6] ∪ [14.4, 18.6], z ∈ [5.4, 18.6]),
* the atrium well and the superdistrict hub well,
* the four seeded edge portals (their spans are z ∈ [6, 10], [10, 14] or
  [14, 18], and the bays sit at z = 3.7 and z = 20.3).

The floor inlays are 12 mm proud of the floor and carry no collision, so
they mark the structure without changing the walkable surface.

### One landmark per structure

The chunk at the structure's anchor carries a fluted pylon with an emissive
cap and a real `OmniLight3D` instead of the plain column. The anchor is in
world chunk coordinates, so it is stable for a given seed and never moves
when chunks are streamed in or out.

---

## 5. Material identity is not architecture identity

A megastructure changes the **geometry** of a region; it never changes the
identity of the level the region belongs to.

| Zone family | Floor | Wall | Ceiling |
|---|---|---|---|
| `level0` (the yellow zone) | `l0_carpet` | `l0_wallpaper` | `l0_ceiling` |
| `warehouse` (the proxy zone) | `concrete_dark` | `concrete` | `metal` |
| `civic` (every other zone) | `concrete` | `l0_wallpaper_pale` | `l0_ceiling` |

The canonical Level 0 look — mono yellow wallpaper, damp carpet, buzzing
ceiling — is preserved inside the yellow zone whatever megastructure kind
the region rolled. The accent material (columns, beams, inlays) is chosen
per structure kind on top of that family.

---

## 6. Roles

`RegionalPlan.chunk_plan(seed, chunk)["role"]` decides which architecture
builds a chunk:

| Role | Condition | Architecture |
|---|---|---|
| `core` | 4×4 macro core | shared 2×2 atrium hall |
| `hub` | 8×8 superdistrict hub | the transit hub with its light well |
| `spine` | on a superdistrict spine | the boulevard with pilasters and beams |
| `structure` | inside a megastructure | the structure's own bay grid |
| `field` | everything else | the room motif and its partitions |

The roles are mutually exclusive and are checked in this order, so the
megastructure layer never shadows the shared halls.

---

## 7. Determinism guarantees

* `RegionalPlan.chunk_plan(seed, k) == RegionalPlan.chunk_plan(seed, k)` for
  every coordinate, including negative ones — asserted by
  `tests/ContinuityRegionalPlanTest.gd`.
* The plan never reads the mutable room version — asserted by the same test
  and by `tests/test_worldlab_v5_static.py`.
* A megastructure owns exactly one id and one kind across all of its chunks
  — asserted by the native test.
* Two structures in one superdistrict never overlap — asserted by the native
  test.
* A rebuilt chunk has the same structure as the chunk it replaced — asserted
  **physically** by `tests/ContinuityPhysicalWalkTest.gd`.

---

## 8. What is deliberately NOT done

* **No canonical level was rewritten.** `levels/`, `data/canon/levels.json`
  and `data/canon/transitions.json` are byte-identical to the v4 package.
* **No monsters, no weapons, no PvE extraction.** Canon-safe levels stay
  canon-safe. The lab remains a non-canon exploration mode.
* **No invented canon exits.** The lab has no transitions to canonical
  levels.
* **No unlimited memory growth.** The world is streamed with a bounded
  loaded-chunk set and a per-world save that stores only what changed.
