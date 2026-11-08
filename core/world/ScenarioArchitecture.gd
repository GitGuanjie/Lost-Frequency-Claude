extends RefCounted
## DEV21 bespoke architectural signatures for the two REAL, guarded overlook
## terraces built by AtriumWeave. These details are on the edge/overhead,
## leaving the 3.6m observation walk unobstructed.

static func dress_terrace(k: GeoKit, sid: String, xc: float, zfront: float,
        y: float, tier: int, mat: String, accent: String) -> int:
    var n := 0
    # Small supports and identity-specific framework. Every design uses the
    # existing level's defined procedural materials, not unrelated textures.
    var side := 1.0 if tier == 0 else -1.0
    for sign in [-1.0, 1.0]:
        var x := xc + sign * 1.61
        match sid:
            "L028": # Stormstone Keep masonry watchpoint
                k.cylinder(Vector3(x, y + 1.12, zfront + 1.10), 0.23, 2.24, mat, 8)
                k.box(Vector3(x, y + 2.2, zfront + 1.10), Vector3(0.65, 0.32, 0.68), accent)
                n += 2
            "L032": # Night forest; crooked bone-like armatures
                k.cylinder(Vector3(x, y + 1.42, zfront + 1.35), 0.11, 2.84, mat, 6)
                k.box(Vector3(x - sign * 0.38, y + 2.51, zfront + 1.40),
                    Vector3(0.78, 0.13, 0.15), accent, GeoKit.ALL, false)
                n += 2
            "L050": # Roadside mast and broken marker
                k.box(Vector3(x, y + 1.20, zfront + 1.15), Vector3(0.19, 2.4, 0.18), accent)
                k.box(Vector3(x - sign * 0.28, y + 2.2, zfront + 1.15),
                    Vector3(0.65, 0.45, 0.10), mat, GeoKit.ALL, false)
                n += 2
            "L073": # Redlands defensive parapet
                k.box(Vector3(x, y + 0.75, zfront + 0.85), Vector3(0.55, 1.5, 0.55), mat)
                k.box(Vector3(x, y + 1.60, zfront + 0.85), Vector3(0.72, 0.20, 0.72), accent)
                n += 2
            "L077": # Mist trail return indicator
                k.box(Vector3(x, y + 1.25, zfront + 1.12), Vector3(0.17, 2.5, 0.17), mat)
                k.box(Vector3(x - sign * 0.28, y + 1.96, zfront + 1.12),
                    Vector3(0.65, 0.13, 0.22), accent, GeoKit.ALL, false)
                n += 2
            "L085": # Sealed industrial-luxury veranda
                k.box(Vector3(x, y + 1.35, zfront + 1.55), Vector3(0.15, 2.7, 0.15), accent)
                k.box(Vector3(x, y + 2.65, zfront + 1.55),
                    Vector3(0.48, 0.12, 0.68), mat, GeoKit.ALL, false)
                n += 2
            "L094": # Toy-scale false perspective
                k.box_xf(Transform3D(Basis(Vector3.UP, sign * 0.19),
                    Vector3(x, y + 1.48, zfront + 1.10)),
                    Vector3(0.17, 2.96, 0.17), accent, GeoKit.ALL, false)
                k.box(Vector3(x - sign * 0.34, y + 2.54, zfront + 1.10),
                    Vector3(0.75, 0.13, 0.13), mat, GeoKit.ALL, false)
                n += 2
            "L108": # Craterwood support roots
                k.cylinder(Vector3(x, y + 1.45, zfront + 1.10), 0.21, 2.90, mat, 7)
                k.box(Vector3(x - sign * 0.34, y + 2.37, zfront + 1.10),
                    Vector3(0.68, 0.24, 0.16), accent, GeoKit.ALL, false)
                n += 2
            "L320": # Silent amusement-park pavilion frame
                k.box(Vector3(x, y + 1.45, zfront + 1.6), Vector3(0.14, 2.9, 0.14), accent)
                k.box(Vector3(x, y + 2.80, zfront + 1.6),
                    Vector3(0.52, 0.16, 0.52), mat, GeoKit.ALL, false)
                n += 2
            "L808": # Neon city light-gate frame
                k.box(Vector3(x, y + 1.45, zfront + 1.1), Vector3(0.15, 2.9, 0.15), accent)
                k.box(Vector3(x - sign * 0.26, y + 2.56, zfront + 1.1),
                    Vector3(0.56, 0.16, 0.16), mat, GeoKit.ALL, false)
                n += 2
    # Overhead line is noncolliding, clear even for tall players, and gives the
    # eye a stable high landmark visible from the interior maze.
    if sid in ["L085", "L320", "L808", "L028"]:
        k.box(Vector3(xc, y + 2.88, zfront + 1.55),
            Vector3(3.35, 0.16, 0.14), accent, GeoKit.ALL, false)
        n += 1
    if sid in ["L032", "L077", "L108"]:
        k.box(Vector3(xc + side * 0.20, y + 2.38, zfront + 1.2),
            Vector3(2.55, 0.12, 0.14), accent, GeoKit.ALL, false)
        n += 1
    return n
