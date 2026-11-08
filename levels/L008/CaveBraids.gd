extends RefCounted
## DEV17 / Level 8: persistent, physically carved cave circuits; no teleports.
## Every braid attaches to the original road at both ends and crosslinks attach
## to named braid nodes. The JSON is also the single source for the offline
## topology audit, so route diagrams cannot drift away from runtime geometry.
const SOURCE := "res://data/dev17_cave_braids.json"

static func specs() -> Dictionary:
    var obj = JSON.parse_string(FileAccess.get_file_as_string(SOURCE))
    if not obj is Dictionary:
        push_error("DEV17 cave braid JSON failed to load")
        return {"braids": [], "links": []}
    return obj

static func carve_features() -> Array:
    var out: Array = []
    var spec := specs()
    for group in [spec.get("braids", []), spec.get("links", [])]:
        for route in group:
            var pts: Array = route["floor_nodes"]
            var rad: float = float(route["radius_m"])
            for idx in range(pts.size() - 1):
                var a := Vector3(float(pts[idx][0]), float(pts[idx][1]), float(pts[idx][2]))
                var b := Vector3(float(pts[idx + 1][0]), float(pts[idx + 1][1]), float(pts[idx + 1][2]))
                # Interpolated floor in the SDF makes sloped tunnels traversable;
                # each join's floor matches exactly (no floating tube ends).
                out.append({"t": "tube", "a": a + Vector3.UP * 1.65,
                    "b": b + Vector3.UP * 1.65, "ra": rad, "rb": rad,
                    "sq": 0.94, "fa": a.y, "fb": b.y, "amp": 0.35})
            # Chamber nodes intersect the passage itself, avoiding unreachable
            # 'pretty' pockets disconnected from the cave graph.
            for idx in range(1, pts.size() - 1, 2):
                var p := Vector3(float(pts[idx][0]), float(pts[idx][1]), float(pts[idx][2]))
                out.append({"t": "room", "c": p + Vector3.UP * 2.7,
                    "r": Vector3(rad * 1.9, 4.5, rad * 1.8),
                    "f": p.y, "amp": 0.55})
    return out
