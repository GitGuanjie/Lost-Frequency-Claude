extends RefCounted
## Level 8 layout: the authored 9th Road (stable spine, "islands of stability")
## and the procedural, shifting caves around it. Geometry via CaveGeo.gd.
## Road floor heights are absolute; every road tube has a flat floor.

const Cave := preload("res://levels/L008/CaveGeo.gd")
const CS := 30.0
const N := 24                     # lattice cells per chunk side (CS / H)

## Road nodes: floor point, tube radius, vertical squash. Segment i joins
## node i to node i+1 with node i's radius/squash.
const ROAD := [
	[Vector3(13, 0, 2), 3.0, 0.72], [Vector3(36, -0.6, 5), 3.0, 0.72], [Vector3(60, -2.0, 9), 2.3, 1.6],
	[Vector3(82, -4.0, 2), 2.3, 1.6], [Vector3(104, -6.0, -6), 2.7, 1.0], [Vector3(128, -8.0, -10), 2.7, 1.0],
	[Vector3(150, -8.0, -12), 2.6, 0.9], [Vector3(169, -8.0, -14), 0.0, 0.0], [Vector3(169, 4.0, -14), 2.8, 0.75],
	[Vector3(190, 4.5, -8), 2.8, 0.75], [Vector3(212, 5.0, 4), 2.6, 0.9], [Vector3(230, 2.0, 14), 2.6, 0.9],
	[Vector3(242, -2.0, 20), 2.6, 0.9], [Vector3(256, 1.0, 27), 2.8, 0.8], [Vector3(282, 1.0, 35), 2.8, 0.8],
	[Vector3(312, 0.5, 42), 3.2, 0.8], [Vector3(336, 0.0, 46), 3.2, 0.8], [Vector3(352, 0.0, 47), 3.2, 0.8],
]
const LAKE := Vector3(-7.0, 0.0, 0.0)
const BREAK := Vector3(128.0, -8.0, -10.0)
const SHAFT := Vector3(169.0, -8.0, -14.0)
const TAR := Vector3(205.0, 5.0, -17.0)
const PIT := Vector3(126.0, -8.0, 13.0)
const DIP := Vector3(242.0, -2.0, 20.0)
const CAVER := Vector3(191.0, 4.5, -2.0)
const EXIT := Vector3(350.0, 0.0, 47.0)


## Global, version-independent features: the road and its set pieces.
static func road_features() -> Array:
	var fs: Array = []
	fs.append({"t": "room", "c": Vector3(0, 3, 0), "r": Vector3(19, 9, 15), "f": 0.0, "amp": 1.6})
	fs.append({"t": "bowl", "c": LAKE, "r": Vector2(12, 10), "depth": 5.0, "amp": 0.3})
	fs.append({"t": "tube", "a": Vector3(-2, 1.3, -10), "b": Vector3(-4, 1.3, -21), "ra": 2.4, "rb": 2.2, "sq": 0.9, "fa": 0.0, "fb": 0.0, "amp": 0.9})
	fs.append({"t": "tube", "a": Vector3(2, 1.3, 11), "b": Vector3(4, 1.3, 21), "ra": 2.4, "rb": 2.2, "sq": 0.9, "fa": 0.0, "fb": 0.0, "amp": 0.9})
	for i in ROAD.size() - 1:
		var p0: Vector3 = ROAD[i][0]
		var p1: Vector3 = ROAD[i + 1][0]
		var r: float = ROAD[i][1]
		if r <= 0.0:
			# the shaft: vertical, no floor; the upper tunnel's floor opens over it
			fs.append({"t": "tube", "a": p0 + Vector3(0, 2.4, 0), "b": p1 + Vector3(0, 1.6, 0), "ra": 2.4, "rb": 2.4, "sq": 1.0, "amp": 0.6, "shaft": true})
			continue
		var sq: float = ROAD[i][2]
		var h := 1.3 if sq < 1.0 else 2.0
		fs.append({"t": "tube", "a": p0 + Vector3(0, h, 0), "b": p1 + Vector3(0, h, 0), "ra": r, "rb": r, "sq": sq, "fa": p0.y, "fb": p1.y, "amp": 0.9, "road": i})
	fs.append({"t": "room", "c": BREAK + Vector3(0, 5, 0), "r": Vector3(22, 13, 17), "f": BREAK.y, "amp": 1.8})
	fs.append({"t": "tube", "a": PIT + Vector3(0, 1.4, -11), "b": PIT + Vector3(0, 1.4, -4), "ra": 2.2, "rb": 2.2, "sq": 0.9, "fa": PIT.y, "fb": PIT.y, "amp": 0.8})
	fs.append({"t": "room", "c": PIT + Vector3(0, 2.5, 0), "r": Vector3(7, 4.5, 6), "f": PIT.y, "amp": 1.0})
	fs.append({"t": "tube", "a": PIT + Vector3(0, -1.2, 0), "b": PIT + Vector3(0, -14, 0), "ra": 1.5, "rb": 1.5, "sq": 1.0, "amp": 0.4})
	fs.append({"t": "tube", "a": TAR + Vector3(5, 1.3, 19), "b": TAR + Vector3(1, 1.3, 6), "ra": 2.1, "rb": 2.1, "sq": 0.9, "fa": TAR.y, "fb": TAR.y, "amp": 0.8})
	fs.append({"t": "room", "c": TAR + Vector3(0, 2.4, 0), "r": Vector3(7, 4.0, 6), "f": TAR.y, "amp": 1.0})
	fs.append({"t": "tube", "a": CAVER + Vector3(-1, 1.2, -5), "b": CAVER + Vector3(0, 1.2, 1), "ra": 2.0, "rb": 1.8, "sq": 0.9, "fa": CAVER.y, "fb": CAVER.y, "amp": 0.6})
	# gallery: a ramp climbing from the canyon to a ledge 9 m above the
	# breakdown chamber floor, so you can look down into it
	fs.append({"t": "tube", "a": Vector3(100, -4.7, -8), "b": Vector3(117, 2.3, -23), "ra": 2.0, "rb": 2.0, "sq": 0.9, "fa": -6.0, "fb": 1.0, "amp": 0.7})
	fs.append({"t": "tube", "a": Vector3(117, 2.3, -23), "b": Vector3(127, 2.3, -24), "ra": 2.2, "rb": 2.4, "sq": 0.9, "fa": 1.0, "fb": 1.0, "amp": 0.7})
	# the drowned way in from Level 7: a flooded tunnel under the pool's west bank
	fs.append({"t": "tube", "a": LAKE + Vector3(-7, -3.6, 1), "b": LAKE + Vector3(-19, -4.2, 2), "ra": 2.1, "rb": 1.6, "sq": 1.0, "amp": 0.5})
	# high, narrow bypass over the flood-prone dip (the safe, slower way)
	var by := [Vector3(225, 2.2, 9), Vector3(243, 3.6, 12), Vector3(261, 2.0, 30)]
	for i in 2:
		fs.append({"t": "tube", "a": by[i] + Vector3(0, 1.1, 0), "b": by[i + 1] + Vector3(0, 1.1, 0), "ra": 1.45, "rb": 1.45, "sq": 0.95, "fa": by[i].y, "fb": by[i + 1].y, "amp": 0.5})
	for f in fs:
		f["bb"] = Cave.aabb_of(f)
	return fs


## Closest point on the road centre line (floor level) to p.
static func road_closest(p: Vector3) -> Vector3:
	var best := Vector3.ZERO
	var bd := 1e9
	for i in ROAD.size() - 1:
		var a: Vector3 = ROAD[i][0]
		var b: Vector3 = ROAD[i + 1][0]
		var ab := b - a
		var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
		var q := a + ab * t
		if q.distance_to(p) < bd:
			bd = q.distance_to(p)
			best = q
	return best


## Marker positions every ~50 m of road (arc length), with the tangent.
static func marker_points() -> Array:
	var out: Array = []
	var acc := 12.0
	var next := 12.0
	for i in ROAD.size() - 1:
		var a: Vector3 = ROAD[i][0]
		var b: Vector3 = ROAD[i + 1][0]
		var l := a.distance_to(b)
		while next <= acc + l:
			var t := (next - acc) / l
			if ROAD[i][1] > 0.0:
				out.append([a.lerp(b, t), (b - a).normalized()])
			next += 50.0
		acc += l
	return out


static func h01(sd: int, a: int, b: int, salt: int) -> float:
	return float(absi(hash([sd, a, b, salt])) % 100003) / 100003.0


## Border passage between chunk (ax,az) and its +X ("x") or +Z ("z")
## neighbour. Depends only on the border, never on chunk versions.
static func portal(sd: int, ax: int, az: int, axis: String) -> Dictionary:
	if h01(sd, ax * 3 + (0 if axis == "x" else 1), az, 41) > 0.62:
		return {}
	var r := RandomNumberGenerator.new()
	r.seed = hash([sd, "portal", axis, ax, az])
	var along := r.randf_range(8.0, 22.0)
	var fy: float = [-3.0, 0.0, 3.0][r.randi() % 3]
	var c: Vector3
	var n: Vector3
	if axis == "x":
		c = Vector3((ax + 1) * CS, fy, az * CS + along)
		n = Vector3.RIGHT
	else:
		c = Vector3(ax * CS + along, fy, (az + 1) * CS)
		n = Vector3.BACK
	# near the road a passage meets it at road level (no pits in the road)
	var rc := road_closest(c)
	if Vector2(rc.x - c.x, rc.z - c.z).length() < 11.0:
		c.y = rc.y
	return {"floor": c, "n": n, "r": 2.1}


static func portals_of(sd: int, cx: int, cz: int) -> Array:
	var out: Array = []
	for b in [[cx, cz, "x", -1.0], [cx - 1, cz, "x", 1.0], [cx, cz, "z", -1.0], [cx, cz - 1, "z", 1.0]]:
		var pt := portal(sd, b[0], b[1], b[2])
		if not pt.is_empty():
			pt["inner"] = (pt["floor"] as Vector3) + (pt["n"] as Vector3) * 6.0 * float(b[3])
			out.append(pt)
	return out


static func stub(pt: Dictionary) -> Dictionary:
	var c: Vector3 = pt["floor"]
	var n: Vector3 = pt["n"]
	return {"t": "tube", "a": c - n * 6.3 + Vector3(0, 1.2, 0), "b": c + n * 6.3 + Vector3(0, 1.2, 0), "ra": pt["r"], "rb": pt["r"],
		"sq": 0.9, "fa": c.y, "fb": c.y, "amp": 0.7}


## Off-road chamber for a chunk version: what is here changes when nobody looks.
static func offroad(sd: int, cx: int, cz: int, version: int, pts: Array) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = hash([sd, "cave", cx, cz, version])
	var kinds := ["plain", "plain", "spikes", "spikes", "breakdown", "lowg", "flood"]
	var kind: String = kinds[r.randi() % kinds.size()]
	var fy := 0.0
	for pt in pts:
		fy += (pt["floor"] as Vector3).y
	fy = fy / maxf(1.0, pts.size()) + r.randf_range(-1.0, 1.0)
	var rad := Vector3(r.randf_range(5.5, 8.0), r.randf_range(3.2, 5.0), r.randf_range(5.5, 8.0))
	if kind in ["lowg", "breakdown"]:
		rad = Vector3(minf(rad.x * 1.1, 8.6), rad.y * 1.5, minf(rad.z * 1.1, 8.6))
	var c := Vector3(cx * CS + r.randf_range(13.5, 16.5), fy, cz * CS + r.randf_range(13.5, 16.5))
	return {"kind": kind, "floor": c, "rad": rad, "rng": r}


static func materials(GLOW: Color) -> void:
	MatLib.define("l8_rock", {"albedo_a": Color(0.36, 0.33, 0.29), "albedo_b": Color(0.22, 0.2, 0.18), "pattern": 11, "pattern_color": Color(0.5, 0.46, 0.4),
		"pattern_strength": 0.55, "noise_scale": 0.55, "bump_strength": 2.4, "wetness": 0.55, "stain_amount": 0.45, "stain_color": Color(0.16, 0.15, 0.13),
		"roughness_a": 0.75, "roughness_b": 0.95}, "rock")
	MatLib.define("l8_floor", {"albedo_a": Color(0.27, 0.24, 0.2), "albedo_b": Color(0.17, 0.15, 0.12), "pattern": 11, "pattern_strength": 0.25,
		"noise_scale": 0.9, "bump_strength": 1.6, "wetness": 0.85, "stain_amount": 0.5, "stain_color": Color(0.12, 0.11, 0.09)}, "rock")
	MatLib.define("l8_flowstone", {"albedo_a": Color(0.62, 0.57, 0.48), "albedo_b": Color(0.46, 0.42, 0.35), "pattern_color": Color(0.7, 0.66, 0.57),
		"noise_scale": 1.4, "wetness": 0.7, "bump_strength": 1.6}, "rock")
	MatLib.define("l8_cracked", {"albedo_a": Color(0.4, 0.37, 0.33), "albedo_b": Color(0.28, 0.26, 0.23), "pattern": 14, "pattern_scale": Vector2(0.45, 0.32),
		"grout_width": 0.035, "grout_color": Color(0.03, 0.03, 0.03), "tile_variation": 0.12, "bump_strength": 1.5}, "concrete")
	MatLib.define("l8_metal", {"albedo_a": Color(0.42, 0.42, 0.4), "albedo_b": Color(0.3, 0.29, 0.27), "stain_amount": 0.5, "stain_color": Color(0.3, 0.17, 0.09)}, "metal")
	MatLib.define("l8_board", {"albedo_a": Color(0.25, 0.2, 0.15), "albedo_b": Color(0.19, 0.15, 0.11), "pattern_scale": Vector2(1.4, 0.2)}, "wood_floor")
	MatLib.define("l8_tar", {"albedo_a": Color(0.05, 0.035, 0.02), "albedo_b": Color(0.02, 0.015, 0.01), "roughness_a": 0.05, "roughness_b": 0.18,
		"bump_strength": 0.6, "noise_scale": 0.5}, "concrete")
	MatLib.define("l8_suit", {"albedo_a": Color(0.85, 0.36, 0.08), "albedo_b": Color(0.7, 0.28, 0.06), "stain_amount": 0.5, "stain_color": Color(0.3, 0.2, 0.12), "noise_scale": 3.0}, "plaster")
	MatLib.define("l8_skin", {"albedo_a": Color(0.55, 0.5, 0.46), "albedo_b": Color(0.48, 0.43, 0.4)}, "plaster")
	MatLib.define("l8_pack", {"albedo_a": Color(0.16, 0.2, 0.15), "albedo_b": Color(0.12, 0.15, 0.11), "noise_scale": 3.0}, "plaster")
	MatLib.define("l8_sand", {"wetness": 0.3}, "sand")
	MatLib.define("l8_gravel", {"albedo_a": Color(0.42, 0.4, 0.37), "albedo_b": Color(0.3, 0.29, 0.27), "pattern": 15, "pattern_color": Color(0.55, 0.53, 0.5),
		"pattern_strength": 0.8, "bump_strength": 2.0, "wetness": 0.3}, "concrete")
	MatLib.define("l8_asphalt", {"wetness": 0.45}, "asphalt")
	MatLib.register("l8_lake", MatLib.water({"shallow_color": Color(0.32, 0.36, 0.32), "deep_color": Color(0.02, 0.035, 0.035), "absorption": 0.9,
		"clarity": 0.7, "wave_height": 0.01, "wave_scale": 0.8, "foam_amount": 0.0, "roughness_value": 0.03}))
	MatLib.register("l8_paint", MatLib.panel(GLOW, 1.6))
	MatLib.register("l8_heat", MatLib.panel(Color(1.0, 0.45, 0.15), 2.2))
