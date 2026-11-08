extends RefCounted
## Four side galleries for the source-defined mineral zones of L197.
## Each gallery has TWO independent ramps, each connected to the existing
## ground floor: an honest loop, not a decorative suspended platform.
## The central 6m corridor, documented transitions, and water cove stay intact.
const GALLERIES = [
    {"zone":"turquoise", "x":-12.8, "start":-46.0, "end":-23.0, "y":4.2, "mat":"l197_turquoise"},
    {"zone":"amethyst", "x":12.8, "start":13.0, "end":36.0, "y":4.7, "mat":"l197_amethyst"},
    {"zone":"ruby", "x":-12.8, "start":62.0, "end":85.0, "y":5.1, "mat":"l197_ruby"},
    {"zone":"onyx", "x":12.8, "start":109.0, "end":132.0, "y":4.5, "mat":"l197_onyx"}
]

static func avoids_stair_or_gallery(x: float, z: float) -> bool:
    # The original seeded crystal batch is simply excluded from walkable
    # gallery footprints and the ground approach ramps. The mineral zones
    # outside these narrow lanes are unchanged.
    for record in GALLERIES:
        var cx := float(record["x"])
        var z0 := float(record["start"])
        var z1 := float(record["end"])
        if absf(x - cx) < 4.0 and z >= z0 - 10.5 and z <= z1 + 10.5:
            return true
        # Keep a transverse approach from the canonical center corridor to
        # each of the two stair bases; seeded boulders could otherwise seal it.
        if x * cx > 0.0 and absf(x) < absf(cx)+1.2:
            for base_z in [z0 - 10.0, z1 + 10.0]:
                if absf(z - base_z) < 2.6:
                    return true
    return false

static func install(level: LevelBase) -> Dictionary:
    var k := level.kit("DEV26_FourMineralGalleries")
    var count := 0
    for record in GALLERIES:
        var cx := float(record["x"])
        var z0 := float(record["start"])
        var z1 := float(record["end"])
        var top := float(record["y"])
        var zone_mat := str(record["mat"])
        # Mineral-bearing side shelf: a continuous and walkable 8m deck.
        k.slab(cx-4.0,z0,cx+4.0,z1,top,0.35,"l197_rock")
        k.stairs(Vector3(cx,0,z0-10.0),Vector3(0,0,1),2.9,top,20,"l197_rock",0.5,false)
        k.stairs(Vector3(cx,0,z1+10.0),Vector3(0,0,-1),2.9,top,20,"l197_rock",0.5,false)
        # All rails end at genuine openings; no 3m stair mouth is blocked.
        for sign in [-1.0,1.0]:
            k.box(Vector3(cx+sign*4.06,top+0.55,(z0+z1)*.5),
                Vector3(.14,1.1,z1-z0),"l197_rock")
            for zend in [z0,z1]:
                k.box(Vector3(cx+sign*2.95,top+.55,zend),
                    Vector3(2.0,1.1,.14),"l197_rock")
        # Unique source-zone silhouettes are kept at the side, not the walkway.
        for sign in [-1.0,1.0]:
            var p := Vector3(cx+sign*3.33,top+.52,(z0+z1)*.5)
            k.cylinder(p,.25,1.04,zone_mat,7,false)
        level.lights.add_anchor(Vector3(cx,top+3.0,(z0+z1)*.5),
            Color(.25,.85,.85) if str(record["zone"])=="turquoise" else (
            Color(.68,.39,.88) if str(record["zone"])=="amethyst" else (
            Color(.87,.28,.30) if str(record["zone"])=="ruby" else Color(.31,.39,.51))),
            .36,12.0,.8,"dev26_%s"%str(record["zone"]))
        level.add_landmark("%s high mineral gallery"%str(record["zone"]).capitalize(),
            Vector3(cx,top,(z0+z1)*.5))
        count += 1
    k.commit()
    return {"galleries":count,"ramps":count*2,"status":"GODOT_PHYSICS_PENDING"}
