extends RefCounted
## Level 2 structure: octagonal junctions (every turn is a multiple of 45
## degrees), corridor halves in four sections (single, upper, stacked two-storey
## with a grating mid-floor, maintenance stair), and the double-height pipe
## gallery with catwalks. A corridor between two junctions is built as two
## halves, one per chunk, so every streamed chunk owns only its own geometry.
## SOURCE: 45-degree contortions, ~5 m multiples, tight tunnels narrowed by pipes
## and machinery, chalky concrete or muddy brick walls. ADAPTATION: decks,
## stairs, catwalks and the gallery (the page gives no section or map).

const P := preload("res://levels/L002/L002_props.gd")
const T := 0.22
const DY := 4.2
const HU := 2.8
const HO := 3.0
const GH := 7.6
const TAN := 0.41421356


static func dvec(k: int) -> Vector3:
	var a := k * PI / 4.0
	return Vector3(snappedf(cos(a), 0.000001), 0.0, snappedf(sin(a), 0.000001)).normalized()


## Wall split into horizontal bands so openings can be stacked (floor door plus
## catwalk door on one face). ops: [{at, w, sill (absolute y), h}].
static func banded_wall(k: GeoKit, a: Vector3, b: Vector3, y0: float, y1: float, mat: String, ops: Array) -> void:
	var cuts: Array = [y0, y1]
	for o in ops:
		cuts.append(clampf(float(o["sill"]), y0, y1))
		cuts.append(clampf(float(o["sill"]) + float(o["h"]), y0, y1))
	cuts.sort()
	for i in cuts.size() - 1:
		var b0: float = cuts[i]
		var b1: float = cuts[i + 1]
		if b1 - b0 < 0.005:
			continue
		var bo: Array = []
		for o in ops:
			if float(o["sill"]) <= b0 + 0.001 and float(o["sill"]) + float(o["h"]) >= b1 - 0.001:
				bo.append({"at": o["at"], "w": o["w"], "h": b1 - b0 + 0.05})
		k.wall(Vector3(a.x, b0, a.z), Vector3(b.x, b0, b.z), b1 - b0, T, mat, bo, GeoKit.SIDES)


## Slab segment in a corridor frame: along [ra, rb], lateral [l0, l1].
static func seg(k: GeoKit, C: Vector3, d: Vector3, ra: float, rb: float, l0: float, l1: float, ytop: float, thick: float, mat: String, faces: int = GeoKit.ALL) -> void:
	var f := P.frame(d)
	var c := C + d * ((ra + rb) * 0.5) + f.x * ((l0 + l1) * 0.5) + Vector3.UP * (ytop - thick * 0.5)
	k.box_xf(Transform3D(f, c), Vector3(l1 - l0, thick, rb - ra), mat, faces, true)


# ----------------------------------------------------------------- junction

## Octagonal junction. faces[k] = {"ops": [{w, sill, h}], "top": y}. gallery =
## one double-height hall; otherwise a lower room plus (has_up) an upper room.
static func junction(ctx: Dictionary, C: Vector3, a: float, faces: Array, gallery: bool, has_up: bool, wall_mat: String) -> void:
	var k: GeoKit = ctx["k"]
	var L := (a + T) * TAN + 0.02
	for i in 8:
		var n := dvec(i)
		var t := Vector3(-n.z, 0, n.x)
		var F := C + n * (a + T * 0.5)
		var ops: Array = []
		for o in faces[i]["ops"]:
			var oo: Dictionary = o.duplicate()
			oo["at"] = L
			ops.append(oo)
		banded_wall(k, F - t * L, F + t * L, 0.0, float(faces[i]["top"]), wall_mat, ops)
	var e := a + T
	k.slab(C.x - e, C.z - e, C.x + e, C.z + e, 0.0, 0.3, "l2_floor", GeoKit.PY)
	if gallery:
		k.slab(C.x - e, C.z - e, C.x + e, C.z + e, GH + 0.3, 0.3, "l2_ceiling", GeoKit.NY)
		return
	k.slab(C.x - e, C.z - e, C.x + e, C.z + e, HO + 0.3, 0.3, "l2_ceiling", GeoKit.NY)
	if has_up:
		k.slab(C.x - e, C.z - e, C.x + e, C.z + e, DY, 0.3, "l2_grate", GeoKit.PY)
		k.slab(C.x - e, C.z - e, C.x + e, C.z + e, DY + HU + 0.3, 0.3, "l2_ceiling", GeoKit.NY)


# ------------------------------------------------------------------ corridor

## One corridor half from r0 (junction face) to r1 (chunk border / corner).
## hf: mode lo|up|stack|stair, w, hl, drop, tram, wall, specs. doors: [{r, s, deck, w, h}]
static func tube(lvl, ctx: Dictionary, C: Vector3, dk: int, r0: float, r1: float, hf: Dictionary, doors: Array) -> void:
	var k: GeoKit = ctx["k"]
	var r: RandomNumberGenerator = ctx["r"]
	var d := dvec(dk)
	var side := P.frame(d).x
	var w: float = hf["w"]
	var mode: String = hf["mode"]
	var hl: float = hf["hl"]
	var wm: String = hf["wall"]
	var ybot := DY - 0.3 if mode == "up" else 0.0
	var ytop := hl if mode == "lo" else DY + HU
	var half := w * 0.5
	# walls with door openings
	for s: float in [-1.0, 1.0]:
		var ops: Array = []
		for dr in doors:
			if float(dr["s"]) == s:
				ops.append({"at": float(dr["r"]) - r0, "w": dr["w"], "sill": DY if dr["deck"] == "up" else 0.0, "h": dr["h"]})
		var o: Vector3 = side * (s * (half + T * 0.5))
		banded_wall(k, C + d * r0 + o, C + d * r1 + o, ybot, ytop, wm, ops)
	# floors, mid-deck, ceiling
	if mode == "up":
		seg(k, C, d, r0, r1, -half - T, half + T, DY, 0.3, "l2_grate", GeoKit.PY)
	elif mode == "stair":
		var s0 := r0 + 0.4
		var steps := 23
		var run := 0.27
		seg(k, C, d, r0, s0 + 0.05, -half - T, half + T, 0.0, 0.3, "l2_floor", GeoKit.PY)
		k.stairs(C + d * s0, d, w, DY, steps, "l2_stair", run, true)
		seg(k, C, d, s0 + steps * run - 0.02, r1, -half - T, half + T, DY, 0.3, "l2_grate", GeoKit.PY)
		for s: float in [-1.0, 1.0]:   # handrail along both walls following the pitch
			var hb := C + d * s0 + side * (s * (half - 0.06)) + Vector3.UP * 0.95
			P.pipe(k, hb, hb + d * (steps * run) + Vector3.UP * DY, 0.025, "l2_rail_yellow", 6)
		P.chalk_sign(k, C + d * (s0 - 0.25) + side * (half - 0.01) * -1.0 + Vector3.UP * 1.7, side, "UP", Color(0.85, 0.72, 0.2))
	else:
		seg(k, C, d, r0, r1, -half - T, half + T, 0.0, 0.3, "l2_floor", GeoKit.PY)
	if mode == "stack":
		var rh := (r0 + r1) * 0.5
		if hf["drop"] and w >= 2.0 and r1 - r0 > 4.0:
			var ledge := 0.9
			seg(k, C, d, r0, rh - 0.6, -half - T, half + T, DY, 0.25, "l2_grate", GeoKit.ALL)
			seg(k, C, d, rh + 0.6, r1, -half - T, half + T, DY, 0.25, "l2_grate", GeoKit.ALL)
			seg(k, C, d, rh - 0.6, rh + 0.6, half - ledge, half + T, DY, 0.25, "l2_grate", GeoKit.ALL)
			# bent, torn grating hanging into the corridor below
			var bb := P.frame(d).rotated(d, 0.9)
			k.box_xf(Transform3D(bb, C + d * rh + side * (-half * 0.4) + Vector3.UP * (DY - 0.55)), Vector3(0.9, 0.04, 0.8), "l2_grate", GeoKit.ALL, false)
			P.railing(k, C + d * (rh - 0.75) + side * (half - ledge - 0.02) + Vector3.UP * DY, C + d * (rh + 0.75) + side * (half - ledge - 0.02) + Vector3.UP * DY, false)
			ctx["meta"]["drops"].append(C + d * rh)
		else:
			seg(k, C, d, r0, r1, -half - T, half + T, DY, 0.25, "l2_grate", GeoKit.ALL)
	seg(k, C, d, r0, r1, -half - T, half + T, ytop + 0.25, 0.25, "l2_ceiling", GeoKit.NY)
	# pipes on the walls (lower band and upper band), skipping door heights
	for s: float in [-1.0, 1.0]:
		var foot0 := C + d * r0 + side * (s * half)
		var foot1 := C + d * r1 + side * (s * half)
		var out: Vector3 = side * -s
		var has_lo_door := false
		var has_up_door := false
		for dr in doors:
			if float(dr["s"]) == s:
				if dr["deck"] == "up":
					has_up_door = true
				else:
					has_lo_door = true
		var key := "spec_r" if s > 0.0 else "spec_l"
		var spec: Array = hf[key]
		if mode == "stair":
			P.pipe_run(k, foot0 + Vector3.UP * 0.4, foot1 + Vector3.UP * (DY + 0.4), out, _fit(spec, 0.0, 2.2, false))
		elif mode != "up":
			var lim := hl if mode == "lo" else DY - 0.3
			P.pipe_run(k, foot0, foot1, out, _fit(spec, 0.0, lim - 0.2, has_lo_door))
		if mode == "up" or mode == "stack":
			P.pipe_run(k, foot0 + Vector3.UP * DY, foot1 + Vector3.UP * DY, out, _fit(hf["spec_u"], 0.0, HU - 0.2, has_up_door))
	# ceiling wiring and light fixtures
	var decks: Array = []
	if mode in ["lo", "stack"]:
		decks.append([0.0, hl if mode == "lo" else DY - 0.25, 0])
	if mode in ["up", "stack"] or mode == "stair":
		decks.append([DY, DY + HU, 1])
	for dk2 in decks:
		var cy: float = dk2[1]
		var wo := side * (half * 0.45)
		P.wiring(k, C + d * r0 + wo + Vector3.UP * (cy - 0.03), C + d * r1 + wo + Vector3.UP * (cy - 0.03))
		var rr := 5.5
		while rr < r1 - 0.3:
			if rr > r0 + 0.6:
				lvl.fixture(ctx, C + d * rr + Vector3.UP * (cy - 0.1), d, int(dk2[2]), 0.0)
			rr += 6.0
	if mode == "stair":
		lvl.fixture(ctx, C + d * (r0 + 1.0) + Vector3.UP * (HO - 0.1), d, 0, 0.0)
	# tramway rails (B.N.T.G. narrow gauge, long defunct)
	if hf["tram"] and mode in ["lo", "stack"]:
		rails(k, C + d * r0, C + d * r1)


static func _fit(spec: Array, y0: float, y1: float, door: bool) -> Array:
	var out: Array = []
	for s in spec:
		var y: float = s[0]
		var rad: float = s[1]
		if y - rad < y0 + 0.25 or y + rad > y1:
			continue
		if door and y < 2.35:
			continue
		out.append(s)
	return out


static func rails(k: GeoKit, a: Vector3, b: Vector3) -> void:
	var d := (b - a)
	var ln := d.length()
	d /= ln
	var side := P.frame(d).x
	for s: float in [-0.3, 0.3]:
		P.obox(k, (a + b) * 0.5 + side * s + Vector3.UP * 0.03, d, Vector3(0.05, 0.06, ln), "l2_railsteel")
	var t := 0.35
	while t < ln:
		P.obox(k, a + d * t + Vector3.UP * 0.005, d, Vector3(0.95, 0.03, 0.16), "l2_sleeper")
		t += 0.7


# ------------------------------------------------------------------ gallery

## Double-height pipe gallery: floor-level corridors enter below, upper-deck
## corridors arrive on catwalks over the pipes; a steel stair links the two.
static func gallery_interior(lvl, ctx: Dictionary, C: Vector3, a: float, up_dirs: Array, lo_dirs: Array) -> void:
	var k: GeoKit = ctx["k"]
	var r: RandomNumberGenerator = ctx["r"]
	# central platform and arms
	k.box_mm(C + Vector3(-1.5, DY - 0.15, -1.5), C + Vector3(1.5, DY, 1.5), "l2_grate", GeoKit.ALL)
	for dk in up_dirs:
		var d := dvec(dk)
		var start := 1.4 if dk % 2 == 0 else 1.9
		seg(k, C, d, start, a + 0.05, -0.65, 0.65, DY, 0.15, "l2_grate", GeoKit.ALL)
		var side := P.frame(d).x
		for s: float in [-1.0, 1.0]:
			var p0 := C + d * (1.5 if dk % 2 == 0 else 1.45) + side * (s * 0.63) + Vector3.UP * DY
			var p1 := C + d * (a - 0.05) + side * (s * 0.63) + Vector3.UP * DY
			if dk == 2 and s * side.x > 0.0:   # leave the stair landing open
				P.railing(k, p0, C + Vector3(0.63, DY, 1.9))
				P.railing(k, C + Vector3(0.63, DY, 3.25), p1)
			else:
				P.railing(k, p0, p1)
		for y in [DY - 0.35, DY - 0.6]:   # pipes slung under the catwalk
			P.pipe(k, C + d * start + side * 0.3 + Vector3.UP * y, C + d * a + side * 0.3 + Vector3.UP * y, 0.07, "l2_pipe_rust", 8)
	for q in 4:   # platform edges, open where an arm leaves
		var d := dvec(q * 2)
		var side := P.frame(d).x
		var c0 := C + d * 1.47 + Vector3.UP * DY
		var ep := 0.45 if up_dirs.has((q * 2 + 7) % 8) else 1.47
		var em := 0.45 if up_dirs.has((q * 2 + 1) % 8) else 1.47
		if up_dirs.has(q * 2):
			P.railing(k, c0 + side * ep, c0 + side * 0.7)
			P.railing(k, c0 - side * 0.7, c0 - side * em)
		else:
			P.railing(k, c0 + side * ep, c0 - side * em)
	# the stair: from the floor near the +x wall up to the +z catwalk
	k.stairs(C + Vector3(6.85, 0, 2.55), Vector3(-1, 0, 0), 1.1, DY, 23, "l2_stair", 0.27, true)
	k.box_mm(C + Vector3(0.6, DY - 0.15, 1.95), C + Vector3(0.7, DY, 3.15), "l2_grate", GeoKit.ALL)
	for z: float in [2.0, 3.1]:
		P.railing(k, C + Vector3(6.85, 0, z), C + Vector3(0.7, DY, z), false)
	# floor-level machinery in the quadrants, clear of the walk lanes
	for q in 4:
		var ang := (58.0 if q == 0 else 22.5 + r.randf_range(0.0, 45.0)) + q * 90.0
		var p := C + Vector3(cos(deg_to_rad(ang)), 0, sin(deg_to_rad(ang))) * 5.4
		var clear := true
		for ld in lo_dirs:
			var dd := dvec(ld)
			var rel := p - C
			var lat := (rel - dd * rel.dot(dd)).length()
			if rel.dot(dd) > 0.0 and lat < 2.2:
				clear = false
		if not clear:
			continue
		if r.randf() < 0.55:
			k.cylinder(p + Vector3.UP * 1.6, 0.85, 3.2, "l2_insul", 16, true)
			P.pipe(k, p + Vector3.UP * 3.2, p + Vector3.UP * (DY + 2.4), 0.14, "l2_pipe_green", 10)
			P.dial(k, p + (C - p).normalized() * 0.86 + Vector3.UP * 1.4, (C - p).normalized(), 0.13)
		else:
			P.obox(k, p + Vector3.UP * 1.1, (C - p).normalized(), Vector3(1.6, 2.2, 1.2), "l2_machine", true)
			P.valve(k, p + (C - p).normalized() * 0.62 + Vector3.UP * 1.2, (C - p).normalized())
	# overhead pipe racks below the catwalks (kept off the stair side) and high runs above
	for i in 4:
		var y := r.randf_range(2.75, 3.5)
		var rad := r.randf_range(0.07, 0.2)
		var m: String = ["l2_pipe_rust", "l2_pipe_green", "l2_steel", "l2_insul"][i % 4]
		P.pipe(k, C + Vector3(-a, y, -1.6 - i * 0.6), C + Vector3(a, y, -1.6 - i * 0.6), rad, m, 10)
		P.pipe(k, C + Vector3(-1.6 - i * 0.6, y + 0.3, -a), C + Vector3(-1.6 - i * 0.6, y + 0.3, a), rad * 0.85, m, 10)
		P.pipe(k, C + Vector3(-a, GH - 0.45 - i * 0.22, 2.4 + i * 0.4), C + Vector3(a, GH - 0.45 - i * 0.22, 2.4 + i * 0.4), rad, m, 10)
	# risers up the walls between the faces
	for i in 8:
		var n := dvec(i).rotated(Vector3.UP, PI / 8.0)
		var p := C + n * (a / cos(PI / 8.0) - 0.45)
		P.pipe(k, p, p + Vector3.UP * GH, 0.12 + 0.06 * (i % 2), "l2_pipe_rust" if i % 3 else "l2_pipe_green", 10)
	# hanging high-bay fixtures and wall lights at floor level
	for v in [Vector3(-3, 0, -3), Vector3(3, 0, 3), Vector3(-3, 0, 3), Vector3(3, 0, -3)]:
		lvl.fixture(ctx, C + v + Vector3.UP * (GH - 1.1), Vector3(1, 0, 0) if v.x * v.z > 0.0 else Vector3(0, 0, 1), 1, 0.9)
	lvl.fixture(ctx, C + Vector3(-4.2, HO - 0.2, 0.6), Vector3(0, 0, 1), 0, 0.0)


# ---------------------------------------------------------- rooms & features

## A room behind an unlocked door (quadrant beside a corridor). kind: bare |
## pcs | house (Level 64) | dugout (Level 902, crude tunnel at a right angle).
static func side_room(lvl, ctx: Dictionary, door_c: Vector3, out_dir: Vector3, along: Vector3, depth: float, width: float, kind: String) -> Vector3:
	var k: GeoKit = ctx["k"]
	var r: RandomNumberGenerator = ctx["r"]
	var f := Basis(along, Vector3.UP, out_dir)   # z = into the room
	var o := door_c + out_dir * T
	var h := 2.7 if kind != "dugout" else 2.0
	var wmat := "l2_wallpaper" if kind == "house" else ("l2_dirt" if kind == "dugout" else "l2_wall")
	var hw := width * 0.5
	if kind == "dugout":
		hw = 0.6
	# floor/ceiling/walls in room frame
	var fm := "l2_carpet" if kind == "house" else ("l2_dirt" if kind == "dugout" else "l2_floor")
	k.box_xf(Transform3D(f, o + out_dir * (depth * 0.5) + Vector3.DOWN * 0.15), Vector3(hw * 2 + 2 * T, 0.3, depth + 0.1), fm, GeoKit.PY, true)
	k.box_xf(Transform3D(f, o + out_dir * (depth * 0.5) + Vector3.UP * (h + 0.15)), Vector3(hw * 2 + 2 * T, 0.3, depth + 0.1), "l2_ceiling" if kind != "dugout" else "l2_dirt", GeoKit.NY, true)
	for s: float in [-1.0, 1.0]:
		k.box_xf(Transform3D(f, o + along * (s * (hw + T * 0.5)) + out_dir * (depth * 0.5) + Vector3.UP * (h * 0.5)), Vector3(T, h, depth + 0.1), wmat, GeoKit.ALL, true)
	k.box_xf(Transform3D(f, o + out_dir * (depth + T * 0.5) + Vector3.UP * (h * 0.5)), Vector3(hw * 2 + 2 * T, h, T), wmat, GeoKit.ALL, true)
	# the back face of the corridor wall beside the doorway, inside the room
	for s: float in [-1.0, 1.0]:
		var span := hw - 0.55
		if span > 0.05:
			k.box_xf(Transform3D(f, o + along * (s * (0.55 + span * 0.5)) + out_dir * -0.05 + Vector3.UP * (h * 0.5)), Vector3(span, h, 0.1), wmat, GeoKit.ALL, false)
	var mid := o + out_dir * (depth * 0.5)
	match kind:
		"bare":
			k.cylinder(mid + Vector3.UP * (h - 0.25), 0.05, 0.12, "l2_bulb", 8, false)
			P.pipe(k, mid + Vector3.UP * (h - 0.2), mid + Vector3.UP * h, 0.006, "l2_cord", 4)
			for i in 2:
				P.small_clutter(k, mid + along * r.randf_range(-hw + 0.5, hw - 0.5) + out_dir * r.randf_range(-depth * 0.3, depth * 0.3), along, r)
		"pcs":
			for i in 3:
				var dc := o + out_dir * (1.4 + i * 1.5)
				P.obox(k, dc + Vector3.UP * 0.37, along, Vector3(0.7, 0.05, hw * 2 - 0.6), "l2_woodbox", true)
				for j in int((hw * 2 - 0.8) / 0.8):
					var pc := dc + along * (-hw + 0.7 + j * 0.8) + Vector3.UP * 0.62
					P.obox(k, pc, out_dir, Vector3(0.42, 0.4, 0.4), "l2_beige")
					P.obox(k, pc + out_dir * -0.205, out_dir, Vector3(0.3, 0.24, 0.01), "l2_screen")
			k.cylinder(mid + Vector3.UP * (h - 0.25), 0.05, 0.12, "l2_bulb", 8, false)
		"house":
			P.obox(k, o + out_dir * (depth - 0.6) + Vector3.UP * 0.4, out_dir, Vector3(2.0, 0.8, 0.9), "l2_sofa", true)
			P.obox(k, mid + Vector3.UP * 0.22, out_dir, Vector3(1.2, 0.05, 0.7), "l2_woodbox")
			P.obox(k, o + out_dir * (depth - 0.02) + Vector3.UP * 1.6, out_dir, Vector3(0.8, 0.6, 0.03), "l2_frame")
			P.obox(k, o + out_dir * (depth - 0.035) + Vector3.UP * 1.6, out_dir, Vector3(0.7, 0.5, 0.01), "l2_painting")
			var lamp := o + along * (hw - 0.4) + out_dir * (depth - 0.4)
			P.pipe(k, lamp, lamp + Vector3.UP * 1.4, 0.02, "l2_brass", 6)
			k.cylinder(lamp + Vector3.UP * 1.45, 0.18, 0.25, "l2_lampshade", 10, false)
			lvl.lights.add_anchor(lamp + Vector3.UP * 1.3, Color(1.0, 0.78, 0.5), 1.4, 5.0, 0.0, ctx["g"])
		"dugout":
			for i in 5:
				P.obox(k, o + out_dir * (0.6 + i * 1.0) + along * (0.55 if i % 2 else -0.55) + Vector3.UP * r.randf_range(0.5, 1.5), out_dir, Vector3(0.12, 0.5, 0.6), "l2_dirt")
			P.obox(k, o + out_dir * (depth * 0.6) + Vector3.UP * 1.95, out_dir, Vector3(1.2, 0.1, 0.12), "l2_wood_aged")
	return o + out_dir * (depth * 0.6)


## Boiler: unreasonably hot machine room centrepiece (Level 127 noclip hotspot).
static func boiler(ctx: Dictionary, C: Vector3) -> void:
	var k: GeoKit = ctx["k"]
	k.cylinder(C + Vector3.UP * 1.3, 1.25, 2.6, "l2_boiler", 18, true)
	k.cylinder(C + Vector3.UP * 2.65, 1.0, 0.12, "l2_steel", 18, false)
	for i in 4:
		var n := dvec(i * 2 + 1)
		P.pipe(k, C + n * 0.9 + Vector3.UP * 2.6, C + n * 0.9 + Vector3.UP * HO, 0.16, "l2_pipe_rust", 10)
	P.obox(k, C + Vector3(1.24, 0.75, 0.0), Vector3(1, 0, 0), Vector3(0.7, 0.45, 0.04), "l2_fireglow")
	P.obox(k, C + Vector3(-1.24, 0.75, 0.0), Vector3(-1, 0, 0), Vector3(0.7, 0.45, 0.04), "l2_fireglow")
	P.dial(k, C + Vector3(0, 1.8, 1.26), Vector3(0, 0, 1), 0.16)


## Central machine for larger junction rooms.
static func centre_machine(ctx: Dictionary, C: Vector3) -> void:
	var k: GeoKit = ctx["k"]
	var r: RandomNumberGenerator = ctx["r"]
	if r.randf() < 0.5:
		P.obox(k, C + Vector3.UP * 0.9, Vector3(1, 0, 0), Vector3(1.6, 1.8, 1.2), "l2_machine", true)
		P.obox(k, C + Vector3.UP * 1.95, Vector3(1, 0, 0), Vector3(1.2, 0.3, 0.9), "l2_machine_dark")
		P.pipe(k, C + Vector3(0.3, 2.1, 0), C + Vector3(0.3, HO, 0), 0.12, "l2_pipe_green", 10)
	else:
		k.cylinder(C + Vector3.UP * 1.3, 0.8, 2.6, "l2_insul", 14, true)
		P.pipe(k, C + Vector3(0, 2.6, 0), C + Vector3(0, HO, 0), 0.2, "l2_steel", 10)
	P.valve(k, C + Vector3(0, 1.2, 0.62), Vector3(0, 0, 1))


## The void behind an unlocked void door: a lightless floor at y = vy with only
## the doorway standing in it. Built once; reused for every void door.
static func void_arena(parent: Node3D, at: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = "VoidRoom"
	parent.add_child(n)
	var k := GeoKit.new(n, "Void")
	k.box(at + Vector3(0, -0.15, 0), Vector3(900, 0.3, 900), "l2_voidfloor", GeoKit.PY)
	for s: float in [-1.0, 1.0]:
		k.box(at + Vector3(s * 0.62, 1.1, 0), Vector3(0.12, 2.2, 0.2), "l2_door_cream", GeoKit.ALL, false)
	k.box(at + Vector3(0, 2.26, 0), Vector3(1.36, 0.12, 0.2), "l2_door_cream", GeoKit.ALL, false)
	k.quad(at + Vector3(0, 1.1, 0), Vector3(0, 0, -1), Vector3(0.56, 0, 0), Vector3(0, 1.1, 0), "l2_doorway_glow")
	k.quad(at + Vector3(0, 1.1, 0.001), Vector3(0, 0, 1), Vector3(0.56, 0, 0), Vector3(0, 1.1, 0), "l2_doorway_glow")
	k.shadows = false
	k.commit()
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.86, 0.62)
	l.light_energy = 1.2
	l.omni_range = 9.0
	l.position = at + Vector3(0, 1.2, -0.6)
	n.add_child(l)
	n.set_meta("light", l)
	return n
