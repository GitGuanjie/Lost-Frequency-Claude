extends RefCounted
## DEV16 / SpatialBranchworks
## Physically instantiated tiered exploration circuit: two opposed stairs per gap,
## FOUR ground-connected branching paths per tier, traversable north/south pocket
## loops, central return deck and two landing galleries.
## Top and bottom are *only* connected by real stairs; no teleports or new exits.
## Unlike VerticalArchitecture, stair runs are OUTSIDE every full central slab,
## so decks do not have to be cut around risers.
## This is not player traversal certification: run DEV16 Godot QA.

const RISE_MIN := 3.2
const RISE_MAX := 4.0
const STAIR_RUN := 16.0
const STAIR_STEPS := 32

static func _floor_y(origin: Vector3, tier: int, rise: float, descend: bool) -> float:
    return origin.y + float(tier) * rise * (-1.0 if descend else 1.0)

static func install(owner: LevelBase, tag: String, origin: Vector3,
        tiers: int, rise: float, mat: String, accent: String,
        descend: bool = false, open_side: int = 0, annex_east_tier2: bool = false) -> Dictionary:
    assert(tiers >= 3 and tiers <= 7)
    assert(rise >= RISE_MIN and rise <= RISE_MAX)
    var kit: GeoKit = owner.kit("DEV16_" + tag)
    var y_low: float = origin.y - float(tiers - 1) * rise if descend else origin.y
    var y_high: float = origin.y if descend else origin.y + float(tiers - 1) * rise
    for f in range(tiers):
        var y: float = _floor_y(origin, f, rise, descend)
        # The central 18x18 m walk is always a real collidable surface.
        kit.slab(origin.x - 9.0, origin.z - 9.0,
            origin.x + 9.0, origin.z + 9.0, y, 0.3, mat)
        # Two *independent* pair-bridges attach north/south pocket courts to
        # the central floor, forming two cycles PER floor.
        for zs in [-1.0, 1.0]:
            var za: float = origin.z + zs * 9.0
            var zb: float = origin.z + zs * 15.0
            for xb in [-5.2, 5.2]:
                kit.slab(origin.x + xb - 1.25, minf(za, zb),
                    origin.x + xb + 1.25, maxf(za, zb), y, 0.3, mat)
            var zmin: float = origin.z + (-23.0 if zs < 0.0 else 15.0)
            var zmax: float = origin.z + (-15.0 if zs < 0.0 else 23.0)
            kit.slab(origin.x - 10.0, zmin,
                origin.x + 10.0, zmax, y, 0.3, mat)
            # Textured rim; visually signals height without blocking the path.
            kit.box(Vector3(origin.x, y + 0.6, origin.z + zs * 23.08),
                Vector3(20.0, 1.2, 0.16), accent)
            for sx in [-1.0, 1.0]:
                # Paired sites need an unobstructed opening for the two linked
                # bridge tiers. Rail ends protect the remaining pocket rim.
                if (f == 1 or f == tiers - 1) and int(sx) == open_side:
                    for zstub in [-1.0, 1.0]:
                        kit.box(Vector3(origin.x + sx * 10.1, y + 0.5,
                            origin.z + zs * 19.0 + zstub * 3.1),
                            Vector3(0.16, 1.0, 1.8), accent)
                else:
                    kit.box(Vector3(origin.x + sx * 10.1, y + 0.5,
                        origin.z + zs * 19.0), Vector3(0.16, 1.0, 8.0), accent)
        # Stair endpoint gangways are short overhanging slabs, not a floor
        # above the slope. Each stair end joins the core via x=+/-9.
        for side in [-1.0, 1.0]:
            for zside in [-1.0, 1.0]:
                var cx: float = origin.x + side * 11.8
                var cz: float = origin.z + zside * 8.0
                kit.slab(minf(cx, origin.x + side * 8.8), cz - 1.15,
                    maxf(cx, origin.x + side * 8.8), cz + 1.15,
                    y, 0.25, mat)
            # Short protective railing around centre, leaving stair openings.
            if annex_east_tier2 and f == 2 and side > 0.0:
                # DEV20: actually open the core-to-balcony doorway. Removing
                # only the far-end guard was not enough: the inner rail blocked it.
                for offset_z in [-3.65, 3.65]:
                    kit.box(Vector3(origin.x + side * 9.06, y + 0.6,
                        origin.z + offset_z), Vector3(0.15, 1.2, 2.7), accent)
            else:
                kit.box(Vector3(origin.x + side * 9.06, y + 0.6, origin.z),
                    Vector3(0.15, 1.2, 10.0), accent)
        if f > 0:
            # Additional transverse balcony on upper tiers: the walkway is
            # attached to its central deck rather than suspended in empty air.
            var offset: float = 1.0 if f % 2 == 0 else -1.0
            kit.slab(origin.x + offset * 9.0, origin.z - 2.0,
                origin.x + offset * 19.0, origin.z + 2.0, y, 0.26, mat)
            if not (annex_east_tier2 and f == 2):
                kit.box(Vector3(origin.x + offset * 19.05, y + 0.62, origin.z),
                    Vector3(0.16, 1.24, 4.0), accent)
        # Non-blocking vertical supports outside the walking envelope.
        for side in [-1.0, 1.0]:
            for zn in [-22.8, 22.8]:
                kit.box(Vector3(origin.x + side * 9.7,
                    (y_low + y) * 0.5 - 0.3, origin.z + zn),
                    Vector3(0.38, y - y_low + 0.6, 0.38), accent)
    # Between consecutive decks: two stairs at opposite flanks. Both ascend
    # from whichever tier is geometrically LOWER, including descending worlds.
    for f in range(tiers - 1):
        var ya: float = _floor_y(origin, f, rise, descend)
        var yb: float = _floor_y(origin, f + 1, rise, descend)
        var lower: float = minf(ya, yb)
        kit.stairs(Vector3(origin.x + 11.8, lower + 0.02, origin.z - 8.0),
            Vector3(0, 0, 1), 2.3, rise, STAIR_STEPS, mat,
            STAIR_RUN / float(STAIR_STEPS), false)
        kit.stairs(Vector3(origin.x - 11.8, lower + 0.02, origin.z + 8.0),
            Vector3(0, 0, -1), 2.3, rise, STAIR_STEPS, mat,
            STAIR_RUN / float(STAIR_STEPS), false)
    kit.commit()
    return {"tag": tag, "tiers": tiers, "rise": rise, "descend": descend,
        "top": y_high, "bottom": y_low,
        "stairs": 2 * (tiers - 1), "pocket_loops": 2 * tiers,
        "per_tier_branch_corridors": 4 * tiers}


## Connect two separately constructed sites at the SAME rise and at the same
## local Z coordinate. The bridge endpoints touch the *outside* pocket floors
## at z=+/-19, not the intermediate-height stair shafts at z=+/-8.
## Two different levels are tied together, so the 2-tower network forms
## additional long-distance cycles rather than a single dead-end bridge.
static func link_sites(owner: LevelBase, tag: String,
        a: Vector3, b: Vector3, tiers: int, rise: float,
        mat: String, accent: String) -> Dictionary:
    assert(a.x + 32.0 < b.x and absf(a.z - b.z) < 0.01)
    assert(tiers >= 3)
    var kit: GeoKit = owner.kit("DEV16_CrossSite_" + tag)
    var links := [1, tiers - 1]
    var length: float = b.x - a.x - 20.0
    for f in links:
        var y: float = a.y + float(f) * rise
        var z: float = a.z + (19.0 if f % 2 == 0 else -19.0)
        kit.slab(a.x + 10.0, z - 1.65,
            b.x - 10.0, z + 1.65, y, 0.3, mat)
        for side in [-1.0, 1.0]:
            kit.box(Vector3((a.x + b.x) * 0.5, y + 0.62, z + side * 1.68),
                Vector3(length, 1.24, 0.12), accent)
        # Slim supports every ~12 m; no floating collision-only skybox bridges.
        for i in range(1, int(length / 12.0) + 1):
            var x: float = a.x + 10.0 + float(i) * length / float(int(length / 12.0) + 1)
            kit.box(Vector3(x, (a.y + y) * 0.5 - 0.4, z),
                Vector3(0.5, y - a.y + 0.8, 0.5), accent)
    kit.commit()
    return {"links": links.size(), "length_each": length}
