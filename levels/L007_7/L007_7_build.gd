extends RefCounted
## Level 7.7 geometry (static). Coordinates: sea surface y = 0, rock summit
## y = S (47 m, SOURCE fact 5). The lighthouse is a square concrete tower
## (half-size HT) on the summit; door on its +z face.
##   shell    - the tower's ground-floor walls as seen from OUTSIDE.
##   stub     - what the doorway shows from outside: the start of the corridor.
##   interior - the ground floor as it is INSIDE: a complex of rooms wider and
##              deeper than the tower (fact 8, "bigger on the inside").
##   always   - floors/ceilings in the footprint, upper floor, stairs, roof.
## L007_7.gd toggles shell+stub vs interior at the door threshold.

const S := 47.0
const UF := 50.2          # upper floor level (ground floor 3.2 m)
const ROOF := 53.5        # the "Ceiling" (upper floor 3.3 m)
const HT := 4.5           # tower half-size
const WT := 0.35          # wall thickness
const IX := 9.5           # interior half-width (inside only)
const IZ0 := -8.0         # interior back wall z (inside only)
const DOOR_W := 1.1
const LAMP := Vector3(-1.6, ROOF, -0.4)


static func materials() -> void:
	MatLib.define("l77_rock", {"albedo_a": Color(0.27, 0.25, 0.22), "albedo_b": Color(0.17, 0.16, 0.14),
		"pattern": 11, "pattern_color": Color(0.34, 0.31, 0.27), "pattern_strength": 0.5, "noise_scale": 0.55,
		"roughness_a": 0.75, "roughness_b": 0.95, "bump_strength": 2.4, "wetness": 0.18}, "rock")
	MatLib.define("l77_rock_top", {"albedo_a": Color(0.22, 0.21, 0.19), "albedo_b": Color(0.11, 0.105, 0.10),
		"pattern": 15, "pattern_color": Color(0.30, 0.28, 0.25), "pattern_strength": 0.35, "noise_scale": 1.3,
		"roughness_a": 0.6, "roughness_b": 0.95, "bump_strength": 2.6, "wetness": 0.35, "stain_amount": 0.5,
		"stain_color": Color(0.08, 0.09, 0.08)}, "rock")
	MatLib.define("l77_concrete", {"albedo_a": Color(0.50, 0.49, 0.46), "albedo_b": Color(0.38, 0.37, 0.34),
		"noise_scale": 1.4, "stain_amount": 0.75, "stain_color": Color(0.36, 0.33, 0.28), "grime_height": 0.6,
		"grime_color": Color(0.30, 0.28, 0.24), "roughness_a": 0.88, "roughness_b": 0.98, "bump_strength": 1.0}, "concrete")
	MatLib.define("l77_concrete_in", {"albedo_a": Color(0.40, 0.38, 0.34), "albedo_b": Color(0.31, 0.30, 0.26),
		"noise_scale": 1.2, "stain_amount": 0.8, "stain_color": Color(0.30, 0.30, 0.22), "grime_height": 0.5,
		"grime_color": Color(0.20, 0.22, 0.16), "roughness_a": 0.9, "roughness_b": 1.0, "bump_strength": 0.8}, "concrete")
	MatLib.define("l77_floor", {"albedo_a": Color(0.40, 0.38, 0.35), "albedo_b": Color(0.32, 0.30, 0.27),
		"noise_scale": 1.6, "stain_amount": 0.6, "stain_color": Color(0.22, 0.22, 0.18), "wetness": 0.25,
		"roughness_a": 0.8, "roughness_b": 0.95}, "concrete")
	MatLib.define("l77_wood", {"albedo_a": Color(0.34, 0.25, 0.17), "albedo_b": Color(0.26, 0.19, 0.13),
		"stain_amount": 0.5, "stain_color": Color(0.16, 0.14, 0.10)}, "wood_floor")
	MatLib.define("l77_rust", {"albedo_a": Color(0.42, 0.22, 0.11), "albedo_b": Color(0.28, 0.15, 0.09),
		"noise_scale": 2.6, "bump_strength": 1.4, "stain_amount": 0.4, "stain_color": Color(0.18, 0.12, 0.08)}, "rust")
	MatLib.define("l77_white_decay", {"albedo_a": Color(0.82, 0.81, 0.77), "albedo_b": Color(0.62, 0.60, 0.55),
		"noise_scale": 1.8, "stain_amount": 0.7, "stain_color": Color(0.45, 0.42, 0.36), "roughness_a": 0.8,
		"roughness_b": 0.95, "bump_strength": 0.9, "wetness": 0.3}, "concrete")
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.75, 0.80, 0.80, 0.16)
	glass.roughness = 0.08
	glass.metallic_specular = 0.9
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	MatLib.register("l77_glass", glass)
	MatLib.register("l77_glass_dirty", glass.duplicate())
	(MatLib.get_mat("l77_glass_dirty") as StandardMaterial3D).albedo_color = Color(0.55, 0.58, 0.5, 0.35)
	MatLib.register("l77_bulb", MatLib.standard(Color(0.85, 0.86, 0.82), 0.05, 0.1, Color(1.0, 0.95, 0.8), 0.0))
	MatLib.register("l77_dark", MatLib.standard(Color(0.06, 0.06, 0.06), 0.7, 0.3))
	MatLib.register("l77_panelface", MatLib.standard(Color(0.22, 0.24, 0.22), 0.6, 0.5))
	MatLib.register("l77_canvas", MatLib.standard(Color(0.18, 0.16, 0.12), 0.95))
	MatLib.register("l77_mould", MatLib.standard(Color(0.12, 0.16, 0.08), 1.0))
	MatLib.register("l77_deadplant", MatLib.standard(Color(0.24, 0.18, 0.11), 1.0))
	MatLib.register("l77_pot", MatLib.standard(Color(0.45, 0.24, 0.16), 0.9))


## The Geolith: a column from the sea floor to the summit, irregular, wider
## below, with a narrow walkable top. Collision only where you can touch it.
static func rock(k: GeoKit, r: RandomNumberGenerator) -> void:
	var y := -60.0
	while y < S - 6.0:
		var t := clampf((y + 60.0) / (S + 54.0), 0.0, 1.0)
		var w := lerpf(46.0, 21.0, t)
		var d := lerpf(42.0, 24.0, t)
		var hgt := minf(9.0, S - 0.5 - y)
		for n in 3:
			var off := Vector3(r.randf_range(-3.0, 3.0), 0, r.randf_range(-3.0, 3.0)) * (1.0 - t * 0.5)
			var yaw := r.randf_range(-0.5, 0.5) + n * 0.7
			var sz := Vector3(w * r.randf_range(0.65, 0.95), hgt, d * r.randf_range(0.65, 0.95))
			# keep the east face clear of the spur's fall line (x <= 11.5)
			var hx := 0.5 * (absf(cos(yaw)) * sz.x + absf(sin(yaw)) * sz.z)
			var cx := minf(off.x - 2.0, 11.5 - hx)
			# below the summit cliffs the visible mass is the boulder pile (dress);
			# these boxes are its collision only
			k.box_xf(Transform3D(Basis(Vector3.UP, yaw), Vector3(cx, y + hgt * 0.5, off.z + 1.5)), sz, "l77_rock", GeoKit.ALL if y >= 26.0 else 0)
		y += 7.0
	# the summit: a narrow, uneven plateau around the tower
	k.box_mm(Vector3(-8.6, S - 8.0, -6.8), Vector3(8.6, S, 12.2), "l77_rock_top")
	k.box_xf(Transform3D(Basis(Vector3.UP, 0.35), Vector3(-7.0, S - 4.1, 7.0)), Vector3(6.0, 8.2, 7.0), "l77_rock_top")
	k.box_xf(Transform3D(Basis(Vector3.UP, -0.25), Vector3(6.8, S - 4.0, -4.5)), Vector3(6.4, 8.0, 7.5), "l77_rock_top")
	k.box_xf(Transform3D(Basis(Vector3.UP, 0.6), Vector3(-4.0, S - 4.05, -7.6)), Vector3(7.0, 8.1, 4.0), "l77_rock_top")
	# the east spur: a narrow tongue of rock out over open water (the jump)
	k.box_mm(Vector3(8.0, S - 3.5, 5.2), Vector3(13.2, S, 8.6), "l77_rock_top")
	k.box_xf(Transform3D(Basis(Vector3.UP, 0.18), Vector3(14.4, S - 1.6, 6.8)), Vector3(3.2, 3.2, 2.6), "l77_rock_top")
	# a few raised lips of rock on the uneven rim (never on the east ledge)
	for p in [[Vector3(-8.4, S + 0.25, 3.0), 0.4, Vector3(2.2, 0.5, 4.0)], [Vector3(-6.0, S + 0.2, 11.4), -0.3, Vector3(3.5, 0.4, 1.8)],
			[Vector3(2.0, S + 0.22, -8.4), 0.2, Vector3(5.0, 0.44, 2.0)], [Vector3(-8.8, S + 0.3, -5.0), 0.7, Vector3(2.4, 0.6, 3.0)]]:
		k.box_xf(Transform3D(Basis(Vector3.UP, p[1]), p[0]), p[2], "l77_rock_top")


static func _square_walls(k: GeoKit, y: float, h: float, mat: String, door: bool, windows: bool) -> void:
	var a := HT
	var front_ops: Array = [{"at": a, "w": DOOR_W, "h": 2.1}] if door else []
	var win := func(n: int) -> Array:
		var out: Array = []
		if windows:
			for i in n:
				out.append({"at": (2.0 * a) * (i + 1) / (n + 1), "w": 0.9, "h": 1.15, "sill": 1.0})
		return out
	k.wall(Vector3(-a, y, a), Vector3(a, y, a), h, WT, mat, front_ops if door else win.call(2))
	k.wall(Vector3(a, y, -a), Vector3(-a, y, -a), h, WT, mat, win.call(2))
	k.wall(Vector3(-a, y, -a), Vector3(-a, y, a), h, WT, mat, win.call(2))
	k.wall(Vector3(a, y, a), Vector3(a, y, -a), h, WT, mat, win.call(2))


static func shell(k: GeoKit) -> void:
	_square_walls(k, S, UF - S, "l77_concrete", true, false)


## Corridor stub visible through the door from outside (inside the footprint).
static func stub(k: GeoKit) -> void:
	k.wall(Vector3(-1.2, S, HT - WT * 0.5), Vector3(-1.2, S, -HT + WT * 0.5), UF - S, 0.14, "l77_concrete_in", [{"at": 2.3, "w": 0.9, "h": 2.05}])
	k.wall(Vector3(1.2, S, HT - WT * 0.5), Vector3(1.2, S, -HT + WT * 0.5), UF - S, 0.14, "l77_concrete_in", [{"at": 3.5, "w": 0.9, "h": 2.05}])


## The ground floor as it is inside: a corridor from the door to the back with
## two rooms either side, all wider and deeper than the tower.
static func interior(k: GeoKit) -> void:
	var h := UF - S
	var m := "l77_concrete_in"
	k.slab(-IX, IZ0, -HT, HT, S + 0.03, 0.2, "l77_floor")
	k.slab(HT, IZ0, IX, HT, S + 0.03, 0.2, "l77_floor")
	k.slab(-HT, IZ0, HT, -HT, S + 0.03, 0.2, "l77_floor")
	# ceilings outside the tower footprint (the footprint uses the upper-floor slab)
	k.box_mm(Vector3(-IX, UF - 0.25, IZ0), Vector3(-HT, UF, HT), m, GeoKit.NY)
	k.box_mm(Vector3(HT, UF - 0.25, IZ0), Vector3(IX, UF, HT), m, GeoKit.NY)
	k.box_mm(Vector3(-HT, UF - 0.25, IZ0), Vector3(HT, UF, -HT), m, GeoKit.NY)
	# outer walls
	k.wall(Vector3(-IX, S, HT), Vector3(IX, S, HT), h, WT, m, [{"at": IX, "w": DOOR_W, "h": 2.1}])
	k.wall(Vector3(IX, S, IZ0), Vector3(-IX, S, IZ0), h, WT, m)
	k.wall(Vector3(-IX, S, IZ0), Vector3(-IX, S, HT), h, WT, m)
	k.wall(Vector3(IX, S, HT), Vector3(IX, S, IZ0), h, WT, m)
	# corridor walls with doorways (west: parlour, back room; east: dining, bedroom)
	k.wall(Vector3(-1.2, S, HT), Vector3(-1.2, S, IZ0), h, 0.14, m, [{"at": 2.3, "w": 0.9, "h": 2.05}, {"at": 8.6, "w": 0.9, "h": 2.05}])
	k.wall(Vector3(1.2, S, HT), Vector3(1.2, S, IZ0), h, 0.14, m, [{"at": 3.5, "w": 0.9, "h": 2.05}, {"at": 10.0, "w": 0.9, "h": 2.05}])
	# room splits
	k.wall(Vector3(-IX, S, 0.0), Vector3(-1.2, S, 0.0), h, 0.14, m, [{"at": 2.0, "w": 0.85, "h": 2.0}])
	k.wall(Vector3(1.2, S, -2.5), Vector3(IX, S, -2.5), h, 0.14, m)
	# skirting of damp along the corridor
	for s in [-1.0, 1.0]:
		k.box_mm(Vector3(1.13 * s - 0.04, S, IZ0), Vector3(1.13 * s + 0.04, S + 0.12, HT), "l77_wood", GeoKit.ALL, false)


## Floors, ceilings and everything above the ground floor (always present).
static func tower(k: GeoKit) -> void:
	var a := HT
	# ground floor inside the footprint
	k.slab(-a, -a, a, a, S + 0.03, 0.2, "l77_floor")
	# upper-floor slab with the opening over stair A (x -0.65..0.65, z -3.3..1.9)
	k.box_mm(Vector3(-a, UF - 0.25, -a), Vector3(-0.65, UF, a), "l77_floor")
	k.box_mm(Vector3(0.65, UF - 0.25, -a), Vector3(a, UF, a), "l77_floor")
	k.box_mm(Vector3(-0.65, UF - 0.25, -a), Vector3(0.65, UF, -3.4), "l77_floor")
	k.box_mm(Vector3(-0.65, UF - 0.25, 1.9), Vector3(0.65, UF, a), "l77_floor")
	# stair A: ground floor -> upper floor, rising away from the door (toward -z)
	k.stairs(Vector3(0, S + 0.03, 1.6), Vector3(0, 0, -1), 1.1, UF - S - 0.03, 18, "l77_wood", 0.27, false)
	for sx in [-0.58, 0.58]:
		k.ramp(Vector3(sx, S + 0.25, 1.75), Vector3(sx, UF - 0.05, -3.3), 0.06, 0.32, "l77_wood")
	# upper floor walls with windows (inner face rusted metal lining below)
	_square_walls(k, UF, ROOF - UF, "l77_concrete", false, true)
	for s in [-1.0, 1.0]:
		k.box_mm(Vector3(-a + WT * 0.5, UF, (a - WT * 0.5) * s - 0.03 * s), Vector3(a - WT * 0.5, UF + 0.95, (a - WT * 0.5) * s + 0.0), "l77_rust", GeoKit.ALL, false)
		k.box_mm(Vector3((a - WT * 0.5) * s - 0.03 * s, UF, -a + WT * 0.5), Vector3((a - WT * 0.5) * s, UF + 0.95, a - WT * 0.5), "l77_rust", GeoKit.ALL, false)
	# window glass (upper floor only)
	for z in [-a, a]:
		for i in 2:
			var x := -a + 2.0 * a * (i + 1) / 3.0
			k.box(Vector3(x, UF + 1.575, z), Vector3(0.9, 1.15, 0.03), "l77_glass_dirty", GeoKit.ALL, true)
	for x in [-a, a]:
		for i in 2:
			var z := -a + 2.0 * a * (i + 1) / 3.0
			k.box(Vector3(x, UF + 1.575, z), Vector3(0.03, 1.15, 0.9), "l77_glass_dirty", GeoKit.ALL, true)
	# stair B: upper floor -> roof, rising toward -z along the east half
	k.stairs(Vector3(2.75, UF, 1.4), Vector3(0, 0, -1), 1.1, ROOF - UF, 18, "l77_rust", 0.27, false)
	k.box_mm(Vector3(2.15, UF, -3.7), Vector3(3.35, UF + 0.04, -3.45), "l77_rust", GeoKit.ALL, false)
	# roof slab ("the Ceiling") with the hatch over stair B (x 2.15..3.35, z -3.7..1.6)
	var m := "l77_white_decay"
	k.box_mm(Vector3(-a - 0.25, ROOF - 0.3, -a - 0.25), Vector3(2.15, ROOF, a + 0.25), m)
	k.box_mm(Vector3(3.35, ROOF - 0.3, -a - 0.25), Vector3(a + 0.25, ROOF, a + 0.25), m)
	k.box_mm(Vector3(2.15, ROOF - 0.3, -a - 0.25), Vector3(3.35, ROOF, -3.7), m)
	k.box_mm(Vector3(2.15, ROOF - 0.3, 1.6), Vector3(3.35, ROOF, a + 0.25), m)
	# parapet + rail around the roof
	for s in [-1.0, 1.0]:
		k.box_mm(Vector3(-a - 0.25, ROOF, (a + 0.1) * s - 0.15), Vector3(a + 0.25, ROOF + 0.55, (a + 0.1) * s + 0.15), "l77_concrete")
		k.box_mm(Vector3((a + 0.1) * s - 0.15, ROOF, -a - 0.25), Vector3((a + 0.1) * s + 0.15, ROOF + 0.55, a + 0.25), "l77_concrete")
		k.box_mm(Vector3(-a - 0.2, ROOF + 1.05, (a + 0.1) * s - 0.03), Vector3(a + 0.2, ROOF + 1.11, (a + 0.1) * s + 0.03), "l77_rust", GeoKit.ALL, false)
		k.box_mm(Vector3((a + 0.1) * s - 0.03, ROOF + 1.05, -a - 0.2), Vector3((a + 0.1) * s + 0.03, ROOF + 1.11, a + 0.2), "l77_rust", GeoKit.ALL, false)
	for i in 9:
		var t := -a + i * (2.0 * a / 8.0)
		for s in [-1.0, 1.0]:
			k.box(Vector3(t, ROOF + 0.82, (a + 0.1) * s), Vector3(0.05, 0.5, 0.05), "l77_rust", GeoKit.ALL, false)
			k.box(Vector3((a + 0.1) * s, ROOF + 0.82, t), Vector3(0.05, 0.5, 0.05), "l77_rust", GeoKit.ALL, false)
	# hatch coaming
	k.box_mm(Vector3(2.05, ROOF, -3.8), Vector3(3.45, ROOF + 0.25, -3.7), "l77_rust", GeoKit.ALL, false)
	k.box_mm(Vector3(3.35, ROOF, -3.8), Vector3(3.45, ROOF + 0.25, 1.6), "l77_rust", GeoKit.ALL, false)
	k.box_mm(Vector3(2.05, ROOF, -3.8), Vector3(2.15, ROOF + 0.25, 1.6), "l77_rust", GeoKit.ALL, false)
	# lamp-room base and frame; glass panes are mostly intact, a few are gone
	k.cylinder(LAMP + Vector3(0, 0.15, 0), 2.1, 0.3, "l77_concrete", 12)
	var panes := 12
	for i in panes:
		var a0 := TAU * i / panes
		var p := LAMP + Vector3(cos(a0) * 2.0, 0.3, sin(a0) * 2.0)
		k.box_xf(Transform3D(Basis(Vector3.UP, -a0), p + Vector3(0, 1.45, 0)), Vector3(0.06, 2.9, 0.06), "l77_rust", GeoKit.ALL, false)
		if i != 3 and i != 8:
			var c := LAMP + Vector3(cos(a0 + PI / panes) * 1.93, 1.75, sin(a0 + PI / panes) * 1.93)
			k.box_xf(Transform3D(Basis(Vector3.UP, -(a0 + PI / panes) + PI * 0.5), c), Vector3(1.0, 2.8, 0.02), "l77_glass", GeoKit.ALL, i % 4 != 1)
	k.cylinder(LAMP + Vector3(0, 3.3, 0), 2.2, 0.2, "l77_rust", 12, false)
	k.cylinder(LAMP + Vector3(0, 3.7, 0), 1.2, 0.6, "l77_rust", 12, false)
	k.cylinder(LAMP + Vector3(0, 0.9, 0), 0.35, 1.2, "l77_rust", 10)
