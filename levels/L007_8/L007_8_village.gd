extends RefCounted
## Level 7.8 stilt architecture: weatherboard houses on wood, metal or concrete stilts
## that run down to the seabed 20 m below, plank decks with rails, one- and two-storey
## houses (outside stair to an upper balcony), rope-and-plank bridges, ladders from the sea.

const SEABED := -20.5


static func poly(k: GeoKit, mat: String, pts: Array, n: Vector3) -> void:
	var s: Dictionary = k._s(mat)
	var base: int = s["v"].size()
	var tu: Vector3 = (pts[1] - pts[0]).normalized()
	var tv: Vector3 = n.cross(tu).normalized()
	for q in pts:
		s["v"].append(q)
		s["n"].append(n)
		s["uv"].append(k._uv_for(q, n, tu, tv))
		s["uv2"].append(Vector2.ZERO)
	var flip: bool = (pts[1] - pts[0]).cross(pts[2] - pts[0]).dot(n) > 0.0
	for i in range(1, pts.size() - 1):
		if flip:
			s["i"].append_array([base, base + i + 1, base + i])
		else:
			s["i"].append_array([base, base + i, base + i + 1])
	k.stats["tris"] += pts.size() - 2


static func quad(k: GeoKit, mat: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3, toward: Vector3) -> void:
	var n := (b - a).cross(d - a).normalized()
	if n.dot(toward) < 0.0:
		n = -n
	poly(k, mat, [a, b, c, d], n)


static func beam(k: GeoKit, a: Vector3, b: Vector3, w: float, h: float, mat: String, collide: bool = false) -> void:
	var z := (b - a).normalized()
	var x := Vector3.UP.cross(z)
	if x.length() < 0.01:
		x = Vector3.RIGHT
	x = x.normalized()
	k.box_xf(Transform3D(Basis(x, z.cross(x).normalized(), z), (a + b) * 0.5), Vector3(w, h, (b - a).length()), mat, GeoKit.ALL, collide)


## Deck rectangle of a house record (x0, z0, x1, z1).
static func deck_rect(h: Dictionary) -> Rect2:
	var c: Vector3 = h["c"]
	var hw: float = float(h["w"]) * 0.5 + float(h["porch"])
	var hd: float = float(h["d"]) * 0.5 + float(h["porch"])
	return Rect2(c.x - hw, c.z - hd, hw * 2.0, hd * 2.0)


## Point on the deck edge of h facing toward p (at deck height).
static func edge_toward(h: Dictionary, p: Vector3) -> Vector3:
	var c: Vector3 = h["c"]
	var r := deck_rect(h)
	var d := Vector2(p.x - c.x, p.z - c.z).normalized()
	var t := minf(r.size.x * 0.5 / maxf(absf(d.x), 0.001), r.size.y * 0.5 / maxf(absf(d.y), 0.001))
	return Vector3(c.x + d.x * (t - 0.05), c.y, c.z + d.y * (t - 0.05))


static func stilts(k: GeoKit, h: Dictionary) -> void:
	var r := deck_rect(h)
	var top: float = float((h["c"] as Vector3).y) - 0.3
	var kind: String = h["stilt"]
	var nx := maxi(2, int(ceil(r.size.x / 3.2)) + 1)
	var nz := maxi(2, int(ceil(r.size.y / 3.2)) + 1)
	var pts: Array = []
	for i in nx:
		for j in nz:
			if i == 0 or j == 0 or i == nx - 1 or j == nz - 1 or (i + j) % 2 == 0:
				pts.append(Vector2(r.position.x + 0.3 + (r.size.x - 0.6) * float(i) / (nx - 1), r.position.y + 0.3 + (r.size.y - 0.6) * float(j) / (nz - 1)))
	for p in pts:
		var c := Vector3(p.x, (top + SEABED) * 0.5, p.y)
		match kind:
			"concrete":
				k.box(c, Vector3(0.5, top - SEABED, 0.5), "concrete")
			"metal":
				k.cylinder(c, 0.14, top - SEABED, "rust", 8)
			_:
				k.cylinder(c, 0.17, top - SEABED, "l78_wood_stilt", 7)
	if kind == "wood":
		# cross bracing between the outer stilts, from the waterline up to the deck
		var corners := [Vector2(r.position.x + 0.3, r.position.y + 0.3), Vector2(r.end.x - 0.3, r.position.y + 0.3),
			Vector2(r.end.x - 0.3, r.end.y - 0.3), Vector2(r.position.x + 0.3, r.end.y - 0.3)]
		for i in 4:
			var a: Vector2 = corners[i]
			var b: Vector2 = corners[(i + 1) % 4]
			beam(k, Vector3(a.x, -0.8, a.y), Vector3(b.x, top - 0.2, b.y), 0.08, 0.14, "l78_wood_stilt")
			beam(k, Vector3(a.x, top - 0.25, a.y), Vector3(b.x, top - 0.25, b.y), 0.12, 0.22, "l78_wood_stilt")
	elif kind == "concrete":
		beam(k, Vector3(r.position.x + 0.3, top - 0.25, r.get_center().y), Vector3(r.end.x - 0.3, top - 0.25, r.get_center().y), 0.4, 0.4, "concrete")


## Rails round a deck, with gaps at the given world points (bridges, stairs).
static func rails(k: GeoKit, rect: Rect2, y: float, gaps: Array) -> void:
	var cs := [Vector2(rect.position.x, rect.position.y), Vector2(rect.end.x, rect.position.y), Vector2(rect.end.x, rect.end.y), Vector2(rect.position.x, rect.end.y)]
	for i in 4:
		var a: Vector2 = cs[i]
		var b: Vector2 = cs[(i + 1) % 4]
		var n := int(ceil(a.distance_to(b) / 0.5))
		var run_start := -1
		for s in n + 1:
			var p := a.lerp(b, float(s) / n)
			var blocked := false
			for g in gaps:
				if p.distance_to(Vector2((g as Vector3).x, (g as Vector3).z)) < 1.0:
					blocked = true
			if not blocked and run_start < 0:
				run_start = s
			if (blocked or s == n) and run_start >= 0:
				var e := s - 1 if blocked else s
				if e > run_start:
					var pa := a.lerp(b, float(run_start) / n)
					var pb := a.lerp(b, float(e) / n)
					beam(k, Vector3(pa.x, y + 1.0, pa.y), Vector3(pb.x, y + 1.0, pb.y), 0.08, 0.08, "l78_wood_rail")
					beam(k, Vector3(pa.x, y + 0.5, pa.y), Vector3(pb.x, y + 0.5, pb.y), 0.05, 0.08, "l78_wood_rail")
					k.add_box_shape(Transform3D(Basis(), Vector3((pa.x + pb.x) * 0.5, y + 0.55, (pa.y + pb.y) * 0.5)),
						Vector3(maxf(absf(pb.x - pa.x), 0.08), 1.1, maxf(absf(pb.y - pa.y), 0.08)), "wood")
					var m := int(ceil(pa.distance_to(pb) / 1.4))
					for q in m + 1:
						var pp := pa.lerp(pb, float(q) / m)
						k.box(Vector3(pp.x, y + 0.52, pp.y), Vector3(0.09, 1.04, 0.09), "l78_wood_rail", GeoKit.ALL, false)
				run_start = -1


## One storey of walls, x0..x1 / z0..z1 at floor y, with a door on `door` side.
static func storey(k: GeoKit, x0: float, z0: float, x1: float, z1: float, y: float, hgt: float, paint: String, door: String, win_rng: RandomNumberGenerator) -> void:
	var sides := {"s": [Vector3(x0, y, z1), Vector3(x1, y, z1)], "n": [Vector3(x1, y, z0), Vector3(x0, y, z0)],
		"e": [Vector3(x1, y, z1), Vector3(x1, y, z0)], "w": [Vector3(x0, y, z0), Vector3(x0, y, z1)]}
	for key in sides.keys():
		var a: Vector3 = sides[key][0]
		var b: Vector3 = sides[key][1]
		var length := a.distance_to(b)
		var ops: Array = []
		if key == door:
			ops.append({"at": length * 0.5, "w": 0.95, "h": 2.05, "sill": 0.0})
			if length > 4.5:
				ops.append({"at": length * 0.2, "w": 0.9, "h": 0.9, "sill": 1.0})
		else:
			var nwin := 2 if length > 5.0 else 1
			for i in nwin:
				if win_rng.randf() < 0.85:
					ops.append({"at": length * (float(i) + 0.5) / nwin, "w": 0.9, "h": 1.0, "sill": 0.95})
		k.wall(a, b, hgt, 0.14, paint, ops)
		# white trim round each window and the door
		var dir := (b - a).normalized()
		var out := dir.cross(Vector3.UP).normalized()
		for op in ops:
			var c := a + dir * float(op["at"]) + out * 0.075
			var w: float = op["w"]
			var oh: float = op["h"]
			var sill: float = op["sill"]
			for side in [-1.0, 1.0]:
				k.box_xf(Transform3D(Basis(dir, Vector3.UP, out), c + dir * side * (w * 0.5 + 0.04) + Vector3.UP * (sill + oh * 0.5)), Vector3(0.08, oh + 0.16, 0.04), "l78_trim", GeoKit.ALL, false)
			k.box_xf(Transform3D(Basis(dir, Vector3.UP, out), c + Vector3.UP * (sill + oh + 0.04)), Vector3(w + 0.16, 0.08, 0.05), "l78_trim", GeoKit.ALL, false)
			if sill > 0.0:
				k.box_xf(Transform3D(Basis(dir, Vector3.UP, out), c + Vector3.UP * (sill - 0.03) + out * 0.04), Vector3(w + 0.2, 0.06, 0.12), "l78_trim", GeoKit.ALL, false)


## Gable roof over x0..x1 / z0..z1 from wall top y, ridge along the longer side.
static func roof(k: GeoKit, x0: float, z0: float, x1: float, z1: float, y: float, rise: float, mat: String, gable_mat: String, snow: bool) -> void:
	var o := 0.45
	var along_x := (x1 - x0) >= (z1 - z0)
	var mats := [mat, "l78_snow"] if snow else [mat]
	for li in mats.size():
		var lm: String = mats[li]
		var up := 0.06 + 0.16 * li
		if along_x:
			var zm := (z0 + z1) * 0.5
			var r0 := Vector3(x0 - o, y + rise + up, zm)
			var r1 := Vector3(x1 + o, y + rise + up, zm)
			quad(k, lm, r0, r1, Vector3(x1 + o, y - 0.25 + up, z1 + o), Vector3(x0 - o, y - 0.25 + up, z1 + o), Vector3(0, 1, 1))
			quad(k, lm, r0, r1, Vector3(x1 + o, y - 0.25 + up, z0 - o), Vector3(x0 - o, y - 0.25 + up, z0 - o), Vector3(0, 1, -1))
			if li == 0:
				quad(k, lm, r0 - Vector3(0, 0.12, 0), r1 - Vector3(0, 0.12, 0), Vector3(x1 + o, y - 0.37, z1 + o), Vector3(x0 - o, y - 0.37, z1 + o), Vector3(0, -1, 0))
				quad(k, lm, r0 - Vector3(0, 0.12, 0), r1 - Vector3(0, 0.12, 0), Vector3(x1 + o, y - 0.37, z0 - o), Vector3(x0 - o, y - 0.37, z0 - o), Vector3(0, -1, 0))
				for xx in [x0, x1]:
					poly(k, gable_mat, [Vector3(xx, y, z0), Vector3(xx, y, z1), Vector3(xx, y + rise, zm)], Vector3(signf(xx - (x0 + x1) * 0.5), 0, 0))
		else:
			var xm := (x0 + x1) * 0.5
			var r0 := Vector3(xm, y + rise + up, z0 - o)
			var r1 := Vector3(xm, y + rise + up, z1 + o)
			quad(k, lm, r0, r1, Vector3(x1 + o, y - 0.25 + up, z1 + o), Vector3(x1 + o, y - 0.25 + up, z0 - o), Vector3(1, 1, 0))
			quad(k, lm, r0, r1, Vector3(x0 - o, y - 0.25 + up, z1 + o), Vector3(x0 - o, y - 0.25 + up, z0 - o), Vector3(-1, 1, 0))
			if li == 0:
				quad(k, lm, r0 - Vector3(0, 0.12, 0), r1 - Vector3(0, 0.12, 0), Vector3(x1 + o, y - 0.37, z1 + o), Vector3(x1 + o, y - 0.37, z0 - o), Vector3(0, -1, 0))
				quad(k, lm, r0 - Vector3(0, 0.12, 0), r1 - Vector3(0, 0.12, 0), Vector3(x0 - o, y - 0.37, z1 + o), Vector3(x0 - o, y - 0.37, z0 - o), Vector3(0, -1, 0))
				for zz in [z0, z1]:
					poly(k, gable_mat, [Vector3(x0, y, zz), Vector3(x1, y, zz), Vector3(xm, y + rise, zz)], Vector3(0, 0, signf(zz - (z0 + z1) * 0.5)))


## A whole stilt house. Returns {door_pos: Vector3 (outside, on the porch), inside: Vector3, rect}.
static func house(k: GeoKit, h: Dictionary, rng: RandomNumberGenerator, gaps: Array) -> Dictionary:
	var c: Vector3 = h["c"]
	var w: float = h["w"]
	var d: float = h["d"]
	var x0 := c.x - w * 0.5
	var x1 := c.x + w * 0.5
	var z0 := c.z - d * 0.5
	var z1 := c.z + d * 0.5
	var rect := deck_rect(h)
	k.slab(rect.position.x, rect.position.y, rect.end.x, rect.end.y, c.y, 0.3, "wood_floor")
	stilts(k, h)
	var paint: String = h["paint"]
	var door: String = h["door"]
	var floors: int = h.get("floors", 1)
	var hgt := 2.65
	storey(k, x0, z0, x1, z1, c.y, hgt, paint, door, rng)
	var top := c.y + hgt
	var dn: Vector3 = {"s": Vector3(0, 0, 1), "n": Vector3(0, 0, -1), "e": Vector3(1, 0, 0), "w": Vector3(-1, 0, 0)}[door]
	var half := (d if door in ["s", "n"] else w) * 0.5
	var door_out: Vector3 = Vector3(c.x, c.y, c.z) + dn * (half + 0.9)
	var inside: Vector3 = Vector3(c.x, c.y, c.z) + dn * (half - 1.1)
	var stair_gap := Vector3.INF
	if floors > 1:
		k.slab(x0, z0, x1, z1, top + 0.15, 0.15, "wood_floor")
		# local frame: v toward the door, u to the right of it
		var sd: Vector3 = dn.cross(Vector3.UP).normalized()
		var bw := (w if door in ["s", "n"] else d) * 0.5
		var C := Vector3(c.x, 0.0, c.z)
		var up_y := top + 0.15
		var run := 0.27
		var steps := 16
		var v0 := -half + 0.3
		var top_v := v0 + run * steps
		var st_start: Vector3 = C + sd * (bw + 0.6) + dn * v0 + Vector3(0, c.y, 0)
		k.stairs(st_start, dn, 1.0, up_y - c.y, steps, "wood_floor", run, false)
		_slab_uv(k, C, sd, dn, -bw, half, bw + 1.15, half + 1.3, up_y)
		_slab_uv(k, C, sd, dn, bw + 0.05, top_v - 0.2, bw + 1.15, half, up_y)
		var b0: Vector3 = C + sd * (-bw) + dn * half
		var b1: Vector3 = C + sd * (bw + 1.15) + dn * (half + 1.3)
		var brect := Rect2(Vector2(minf(b0.x, b1.x), minf(b0.z, b1.z)), Vector2(absf(b1.x - b0.x), absf(b1.z - b0.z)))
		rails(k, brect, up_y, [C + dn * half, C + sd * (bw + 0.6) + dn * half])
		stair_gap = st_start
		var store_rng := RandomNumberGenerator.new()
		store_rng.seed = rng.randi()
		storey(k, x0, z0, x1, z1, up_y, 2.5, paint, door, store_rng)
		top = up_y + 2.5
		h["balcony"] = C + dn * (half + 0.65) + Vector3(0, up_y, 0)
	# ceiling of the top room and the roof
	k.slab(x0, z0, x1, z1, top + 0.08, 0.08, "l78_ceiling", GeoKit.NY | GeoKit.PY)
	roof(k, x0, z0, x1, z1, top + 0.08, minf(w, d) * 0.32, h["roof"], paint, bool(h.get("snow", false)))
	if bool(h.get("snow", false)):
		# a thick, unmelting cap: drifts along the eaves and the ridge, a crust on the sills
		var rise := minf(w, d) * 0.32
		var ax := w >= d
		for e in [-1.0, 1.0]:
			if ax:
				k.box(Vector3(c.x, top - 0.12, c.z + e * (d * 0.5 + 0.38)), Vector3(w + 0.95, 0.22, 0.32), "l78_snow", GeoKit.ALL, false)
			else:
				k.box(Vector3(c.x + e * (w * 0.5 + 0.38), top - 0.12, c.z), Vector3(0.32, 0.22, d + 0.95), "l78_snow", GeoKit.ALL, false)
		k.box(Vector3(c.x, top + 0.08 + rise + 0.2, c.z), Vector3(w + 0.95, 0.2, 0.35) if ax else Vector3(0.35, 0.2, d + 0.95), "l78_snow", GeoKit.ALL, false)
		for e in [-1.0, 1.0]:
			k.box(Vector3(c.x + e * 1.4, c.y + 0.12, c.z + d * 0.5 + 0.55), Vector3(0.9, 0.18, 0.6), "l78_snow", GeoKit.ALL, false)
	rails(k, rect, c.y, gaps)
	return {"door_pos": door_out, "inside": inside, "rect": rect, "dn": dn}


## Horizontal slab given in a house's local (u, v) frame.
static func _slab_uv(k: GeoKit, C: Vector3, sd: Vector3, dn: Vector3, u0: float, v0: float, u1: float, v1: float, y: float) -> void:
	var p0: Vector3 = C + sd * u0 + dn * v0
	var p1: Vector3 = C + sd * u1 + dn * v1
	k.slab(p0.x, p0.z, p1.x, p1.z, y, 0.18, "wood_floor")


## Rope-and-plank bridge between two deck points. Returns nothing; collision is one
## ramp plus rope rails. weak = thinner planks with gaps (the one that gives way).
static func bridge(k: GeoKit, a: Vector3, b: Vector3, rng: RandomNumberGenerator, weak: bool = false) -> void:
	var f := b - a
	var flat := Vector3(f.x, 0, f.z)
	var len := flat.length()
	var dir := flat.normalized()
	var side := dir.cross(Vector3.UP).normalized()
	k.ramp(a + Vector3(0, -0.02, 0), b + Vector3(0, -0.02, 0), 1.3, 0.12, "l78_wood_stilt", "wood")
	var n := int(len / 0.3)
	for i in n:
		var t := (float(i) + 0.5) / n
		if weak and rng.randf() < 0.18:
			continue
		var p := a.lerp(b, t) + Vector3(0, 0.035 - 0.12 * sin(PI * t) * 0.0, 0)
		var yaw := rng.randf_range(-0.05, 0.05)
		var pd := dir.rotated(Vector3.UP, yaw)
		k.box_xf(Transform3D(Basis(pd, Vector3.UP, pd.cross(Vector3.UP)), p), Vector3(0.22, 0.05, 1.45), "wood_floor", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		var ra: Vector3 = a + side * s * 0.72 + Vector3.UP * 1.0
		var rb: Vector3 = b + side * s * 0.72 + Vector3.UP * 1.0
		var m := 6
		for i in m:
			var t0 := float(i) / m
			var t1 := float(i + 1) / m
			beam(k, ra.lerp(rb, t0) + Vector3.UP * (-0.18 * sin(PI * t0)), ra.lerp(rb, t1) + Vector3.UP * (-0.18 * sin(PI * t1)), 0.035, 0.035, "l78_rope")
		for t in [0.0, 1.0]:
			var pp: Vector3 = a.lerp(b, t) + side * s * 0.72
			k.box(pp + Vector3(0, 0.55, 0), Vector3(0.1, 1.1, 0.1), "l78_wood_stilt", GeoKit.ALL, false)
		var mid: Vector3 = (a + b) * 0.5 + side * s * 0.72 + Vector3.UP * 0.6
		k.add_box_shape(Transform3D(Basis(dir, Vector3.UP, dir.cross(Vector3.UP)), mid), Vector3(len, 1.2, 0.06), "wood")


## A small deserted rowing boat (hull of planks), floating at y.
static func boat(k: GeoKit, c: Vector3, yaw: float, mat: String) -> void:
	var bas := Basis(Vector3.UP, yaw)
	var L := 4.2
	var W := 1.4
	var pts_top := [Vector3(0, 0.45, L * 0.5), Vector3(W * 0.5, 0.4, L * 0.25), Vector3(W * 0.5, 0.38, -L * 0.42), Vector3(0, 0.42, -L * 0.5),
		Vector3(-W * 0.5, 0.38, -L * 0.42), Vector3(-W * 0.5, 0.4, L * 0.25)]
	var pts_bot := [Vector3(0, -0.2, L * 0.42), Vector3(W * 0.3, -0.3, L * 0.2), Vector3(W * 0.3, -0.3, -L * 0.35), Vector3(0, -0.25, -L * 0.42),
		Vector3(-W * 0.3, -0.3, -L * 0.35), Vector3(-W * 0.3, -0.3, L * 0.2)]
	for i in 6:
		var a: Vector3 = c + bas * (pts_top[i] as Vector3)
		var b: Vector3 = c + bas * (pts_top[(i + 1) % 6] as Vector3)
		var cc: Vector3 = c + bas * (pts_bot[(i + 1) % 6] as Vector3)
		var d: Vector3 = c + bas * (pts_bot[i] as Vector3)
		var mid: Vector3 = (a + b + cc + d) * 0.25
		quad(k, mat, a, b, cc, d, mid - c)
		quad(k, mat, a, b, cc, d, c - mid)
	var floor_pts: Array = []
	for p in pts_bot:
		floor_pts.append(c + bas * ((p as Vector3) + Vector3(0, 0.12, 0)))
	poly(k, mat, floor_pts, Vector3.UP)
	for z in [-0.6, 0.5]:
		k.box_xf(Transform3D(bas, c + bas * Vector3(0, 0.15, z)), Vector3(W * 0.8, 0.05, 0.28), mat, GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		k.box_xf(Transform3D(bas * Basis(Vector3.UP, s * 0.25), c + bas * Vector3(s * 0.55, 0.35, -0.2)), Vector3(0.05, 0.05, 2.6), "l78_wood_stilt", GeoKit.ALL, false)
