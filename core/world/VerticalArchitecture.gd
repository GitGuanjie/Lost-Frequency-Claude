extends RefCounted
## DEV15: Physically supported multi-storey service loops, not teleports.
## Stair runs occupy long, explicit slots in *every* raised slab. Two opposed
## flights per storey lead to opposite end galleries. A central walk and two
## outer walks allow players to change sides without retracing a stair.
## Ground floor is deliberately NOT generated: the level owns that floor.
## Canon source does not imply these routes are exits or extra locations.

const HALF_X := 8.0
const HALF_Z := 14.0
const RUN := 20.0
const STEPS := 28
const STAIR_WIDTH := 2.6

static func install(owner: LevelBase, tag: String, origin: Vector3,
        floors: int, rise: float, deck_mat: String, steel_mat: String,
        capped: bool = false) -> Dictionary:
    assert(floors >= 2 and floors <= 6)
    assert(rise >= 3.1 and rise <= 4.0)
    var k: GeoKit = owner.kit("DEV15_" + tag)
    var final_y: float = origin.y + float(floors - 1) * rise
    # End galleries are uninterrupted. Only longitudinal strips are split;
    # the continuous empty stair apertures are x[-5.5,-2.5] and [2.5,5.5].
    for f in range(1, floors):
        var y: float = origin.y + float(f) * rise
        k.slab(origin.x - 8.0, origin.z - 14.0, origin.x + 8.0,
            origin.z - 10.0, y, 0.26, deck_mat)
        k.slab(origin.x - 8.0, origin.z + 10.0, origin.x + 8.0,
            origin.z + 14.0, y, 0.26, deck_mat)
        for bounds in [[-8.0, -5.5], [-2.5, 2.5], [5.5, 8.0]]:
            k.slab(origin.x + float(bounds[0]), origin.z - 10.0,
                origin.x + float(bounds[1]), origin.z + 10.0,
                y, 0.26, deck_mat)
        # Protective barrier at outer rim and along both open stair slots.
        for side in [-1.0, 1.0]:
            k.box(Vector3(origin.x + side * 8.05, y + 0.55, origin.z),
                Vector3(0.14, 1.1, 28.0), steel_mat)
            k.box(Vector3(origin.x, y + 0.55, origin.z + side * 14.05),
                Vector3(16.0, 1.1, 0.14), steel_mat)
        for bx in [-5.5, -2.5, 2.5, 5.5]:
            k.box(Vector3(origin.x + bx, y + 0.53, origin.z),
                Vector3(0.12, 1.06, 19.3), steel_mat)
        # A thin, non-colliding ID strip on the central walk gives altitude cues.
        k.box(Vector3(origin.x, y + 0.025, origin.z + 11.7),
            Vector3(1.7, 0.05, 0.32), steel_mat, GeoKit.ALL, false)
    for f in range(floors - 1):
        var y: float = origin.y + float(f) * rise
        # 20 m horizontal travel for 3.2–3.7 m ascent => walkable slope.
        # Unlike overlapping slab stairs, both top landings are REAL surfaces.
        k.stairs(Vector3(origin.x - 4.0, y + 0.015, origin.z - 10.0),
            Vector3.FORWARD * -1.0, STAIR_WIDTH, rise, STEPS,
            deck_mat, RUN / float(STEPS), false)
        k.stairs(Vector3(origin.x + 4.0, y + 0.015, origin.z + 10.0),
            Vector3.FORWARD, STAIR_WIDTH, rise, STEPS,
            deck_mat, RUN / float(STEPS), false)
    # Columns sit OUTSIDE the tread and walkway clear width.
    for px in [-8.25, 8.25]:
        for pz in [-14.25, 14.25]:
            k.box(Vector3(origin.x + px, (origin.y + final_y + 1.7) * 0.5,
                origin.z + pz), Vector3(0.44, final_y - origin.y + 1.7, 0.44), steel_mat)
    if capped:
        k.box(Vector3(origin.x, final_y + 3.8, origin.z),
            Vector3(17.4, 0.28, 29.4), steel_mat)
    k.commit()
    return {"tag": tag, "origin": origin, "floors": floors, "rise": rise,
        "top": final_y, "stair_runs": (floors - 1) * 2,
        "floor_strips": (floors - 1) * 5}
