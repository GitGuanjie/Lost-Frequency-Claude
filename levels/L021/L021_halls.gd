extends RefCounted
## Level 21 geometry: the central square with the front desk, the four hallway
## mouths, streamed hallway segments with doors on both sides, and the dark,
## non-shifting Exit halls one storey down behind the neon "Exit" door.
## Hallway coordinates: u runs along the hallway, v across it (EW: v = z - 12).

const CS := 24.0
const C := Vector3(12.0, 0.0, 12.0)
const SQ := 5.6            # half-size of the central square
const HW := 2.6            # hallway width
const HH := 2.65           # hallway height
const T := 0.15
const SPACING := 3.0
const EXIT_X := 60.0       # neon Exit door, north wall of the east hallway
const DY := -4.5           # floor of the dark Exit halls
const JX0 := 57.0
const JX1 := 63.0
const JZ0 := -9.0
const JZ1 := 2.3
const DARK_Z := -6.0

var L: Node3D


func _init(level: Node3D) -> void:
	L = level


static func materials() -> void:
	MatLib.define("l21_carpet", {"albedo_a": Color(0.30, 0.20, 0.17), "albedo_b": Color(0.25, 0.16, 0.14), "pattern": 6,
		"pattern_scale": Vector2(0.45, 0.45), "pattern_color": Color(0.52, 0.42, 0.28), "pattern_strength": 0.4,
		"stain_amount": 0.3, "stain_color": Color(0.18, 0.13, 0.1), "stain_scale": 0.4, "bump_strength": 0.4}, "l0_carpet")
	MatLib.define("l21_wall", {"albedo_a": Color(0.74, 0.69, 0.58), "albedo_b": Color(0.70, 0.64, 0.53), "pattern": 2,
		"pattern_scale": Vector2(0.12, 1.0), "pattern_color": Color(0.66, 0.60, 0.48), "pattern_strength": 0.25,
		"stain_amount": 0.2, "stain_color": Color(0.5, 0.45, 0.36), "grime_height": 0.25, "grime_color": Color(0.45, 0.40, 0.32)}, "plaster")
	MatLib.define("l21_wainscot", {"albedo_a": Color(0.42, 0.30, 0.22), "albedo_b": Color(0.36, 0.26, 0.19), "pattern": 3,
		"pattern_scale": Vector2(0.25, 3.0)}, "wood_floor")
	MatLib.define("l21_ceiling", {"albedo_a": Color(0.82, 0.80, 0.74), "albedo_b": Color(0.76, 0.74, 0.68), "pattern": 7,
		"pattern_scale": Vector2(0.6, 0.6), "pattern_strength": 0.15}, "plaster")
	MatLib.define("l21_trim", {"albedo_a": Color(0.86, 0.83, 0.76), "albedo_b": Color(0.80, 0.77, 0.70)}, "trim_white")
	MatLib.define("l21_door", {"albedo_a": Color(0.36, 0.22, 0.14), "albedo_b": Color(0.30, 0.18, 0.11), "pattern": 3,
		"pattern_scale": Vector2(0.18, 2.5), "roughness_a": 0.6}, "wood_floor")
	MatLib.define("l21_door_pale", {"albedo_a": Color(0.62, 0.58, 0.50), "albedo_b": Color(0.56, 0.52, 0.45)}, "trim_white")
	MatLib.define("l21_sandstone", {"albedo_a": Color(0.80, 0.66, 0.44), "albedo_b": Color(0.72, 0.58, 0.38), "pattern": 11,
		"pattern_scale": Vector2(0.3, 0.3), "pattern_strength": 0.4, "bump_strength": 0.8}, "sand")
	MatLib.define("l21_brick", {}, "brick")
	MatLib.define("l21_marble", {"albedo_a": Color(0.86, 0.85, 0.82), "albedo_b": Color(0.78, 0.77, 0.74), "pattern": 15,
		"pattern_scale": Vector2(0.4, 0.4), "roughness_a": 0.3, "roughness_b": 0.4}, "pool_tile")
	MatLib.define("l21_floor_sq", {"albedo_a": Color(0.58, 0.54, 0.46), "albedo_b": Color(0.50, 0.46, 0.39), "pattern": 9,
		"pattern_scale": Vector2(0.6, 0.6), "pattern_color": Color(0.32, 0.26, 0.20), "pattern_strength": 0.6, "roughness_a": 0.4}, "pool_tile")
	MatLib.define("l21_dark", {"albedo_a": Color(0.16, 0.15, 0.14), "albedo_b": Color(0.12, 0.11, 0.10), "stain_amount": 0.4,
		"stain_color": Color(0.07, 0.06, 0.05), "grime_height": 0.6, "grime_color": Color(0.06, 0.05, 0.04)}, "concrete_dark")
	MatLib.define("l21_dark_floor", {"albedo_a": Color(0.14, 0.12, 0.11), "albedo_b": Color(0.10, 0.09, 0.08), "pattern": 6}, "l0_carpet")
	MatLib.define("l21_dark_door", {"albedo_a": Color(0.22, 0.20, 0.18), "albedo_b": Color(0.18, 0.16, 0.15)}, "wood_floor")
	MatLib.register("l21_light_panel", MatLib.panel(Color(1.0, 0.9, 0.74), 2.0))
	MatLib.register("l21_neon", MatLib.panel(Color(1.0, 0.08, 0.05), 4.0, 0.04))
	MatLib.register("l21_brass", MatLib.standard(Color(0.72, 0.56, 0.28), 0.35, 0.8))


## Map hallway-local (u along, y, v across) to world for an axis ("x": east-west, "z": north-south).
static func W(axis: String, u: float, y: float, v: float, line: float) -> Vector3:
	return Vector3(u, y, line + v) if axis == "x" else Vector3(line + v, y, u)


static func S(axis: String, lu: float, h: float, lv: float) -> Vector3:
	return Vector3(lu, h, lv) if axis == "x" else Vector3(lv, h, lu)


## A hallway segment from u0 to u1. doors: [{u, side, label, mat}], returns door fronts.
func segment(k: GeoKit, axis: String, line: float, u0: float, u1: float, y0: float, dark: bool, blocked_at: float = INF, holes: Array = []) -> void:
	var len := u1 - u0
	var um := (u0 + u1) * 0.5
	var wall := "l21_dark" if dark else "l21_wall"
	k.box(W(axis, um, y0 - 0.15, 0, line), S(axis, len, 0.3, HW + T * 2), "l21_dark_floor" if dark else "l21_carpet")
	k.box(W(axis, um, y0 + HH + 0.06, 0, line), S(axis, len, 0.12, HW + T * 2), "l21_dark" if dark else "l21_ceiling")
	for side: float in [-1.0, 1.0]:
		var v := side * (HW * 0.5 + T * 0.5)
		var cuts := [u0]
		for h in holes:
			if float(h[1]) == side:
				cuts.append(float(h[0]) - 0.5)
				cuts.append(float(h[0]) + 0.5)
		cuts.append(u1)
		for i in range(0, cuts.size(), 2):
			var a: float = cuts[i]
			var b: float = cuts[i + 1]
			if b - a > 0.01:
				k.box(W(axis, (a + b) * 0.5, y0 + HH * 0.5, v, line), S(axis, b - a, HH, T), wall)
			if i + 2 < cuts.size():
				var c0: float = cuts[i + 1]
				var c1: float = cuts[i + 2]
				k.box(W(axis, (c0 + c1) * 0.5, y0 + (2.12 + HH) * 0.5, v, line), S(axis, c1 - c0, HH - 2.12, T), wall)
		if not dark:
			k.box(W(axis, um, y0 + 0.5, side * (HW * 0.5 - 0.012), line), S(axis, len, 1.0, 0.024), "l21_wainscot", GeoKit.ALL, false)
			k.box(W(axis, um, y0 + 1.02, side * (HW * 0.5 - 0.02), line), S(axis, len, 0.05, 0.04), "l21_trim", GeoKit.ALL, false)
	if blocked_at < INF:
		# the hallway has shifted: it simply ends in a wall here
		k.box(W(axis, blocked_at, y0 + HH * 0.5, 0, line), S(axis, 0.3, HH, HW), wall)


## One door, flush in the wall, with casing, knob and (optionally) a number plaque.
func door(k: GeoKit, parent: Node3D, axis: String, line: float, u: float, side: float, y0: float, mat: String, label: String, dark: bool) -> Dictionary:
	var face := side * (HW * 0.5)
	k.box(W(axis, u, y0 + 1.03, face - side * 0.02, line), S(axis, 0.92, 2.06, 0.04), mat, GeoKit.ALL, false)
	k.box(W(axis, u, y0 + 2.12, face - side * 0.03, line), S(axis, 1.14, 0.1, 0.05), "l21_dark" if dark else "l21_trim", GeoKit.ALL, false)
	for e in [-0.52, 0.52]:
		k.box(W(axis, u + e, y0 + 1.06, face - side * 0.03, line), S(axis, 0.09, 2.12, 0.05), "l21_dark" if dark else "l21_trim", GeoKit.ALL, false)
	k.cylinder(W(axis, u + 0.34, y0 + 1.0, face - side * 0.07, line), 0.028, 0.06, "l21_brass", 8, false)
	if label != "":
		var lb := Label3D.new()
		lb.text = label
		lb.font_size = 54
		lb.pixel_size = 0.0028
		lb.outline_size = 0
		lb.modulate = Color(0.85, 0.7, 0.4) if not dark else Color(0.5, 0.48, 0.44)
		lb.shaded = true
		lb.position = W(axis, u, y0 + 1.68, face - side * 0.045, line)
		var n := W(axis, 0, 0, -side, 0) - W(axis, 0, 0, 0, 0)
		lb.rotation.y = atan2(n.x, n.z)
		parent.add_child(lb)
		k.box(W(axis, u, y0 + 1.68, face - side * 0.025, line), S(axis, 0.3, 0.16, 0.012), "l21_brass", GeoKit.ALL, false)
	var front := W(axis, u, y0 + 1.1, face - side * 0.55, line)
	return {"front": front, "normal": (W(axis, 0, 0, -side, 0) - W(axis, 0, 0, 0, 0)).normalized()}


## The central square: four hallway mouths, the front desk, chairs. Entities never come here.
func square(k: GeoKit) -> void:
	var y := 3.4
	k.box(Vector3(C.x, -0.15, C.z), Vector3(SQ * 2 + 0.4, 0.3, SQ * 2 + 0.4), "l21_floor_sq")
	k.box(Vector3(C.x, y + 0.06, C.z), Vector3(SQ * 2 + 0.4, 0.12, SQ * 2 + 0.4), "l21_ceiling")
	for side: float in [-1.0, 1.0]:
		var d := side * (SQ + T * 0.5)
		for axis in ["x", "z"]:
			# walls of the square with the hallway mouth in the middle
			for seg in [[-SQ - T, -HW * 0.5 - T], [HW * 0.5 + T, SQ + T]]:
				var a: float = seg[0]
				var b: float = seg[1]
				var c := Vector3(C.x + (a + b) * 0.5, y * 0.5, C.z + d) if axis == "x" else Vector3(C.x + d, y * 0.5, C.z + (a + b) * 0.5)
				var s := Vector3(b - a, y, T) if axis == "x" else Vector3(T, y, b - a)
				k.box(c, s, "l21_wall")
				var wc := c + (Vector3(0, 0.5 - y * 0.5, -side * 0.09) if axis == "x" else Vector3(-side * 0.09, 0.5 - y * 0.5, 0))
				k.box(wc, Vector3(s.x if axis == "x" else 0.02, 1.0, s.z if axis == "z" else 0.02), "l21_wainscot", GeoKit.ALL, false)
			# lintel above the mouth
			var lc := Vector3(C.x, (HH + y) * 0.5, C.z + d) if axis == "x" else Vector3(C.x + d, (HH + y) * 0.5, C.z)
			k.box(lc, Vector3(HW + T * 2, y - HH, T) if axis == "x" else Vector3(T, y - HH, HW + T * 2), "l21_wall")
	# the front desk: a wooden counter with a marble top, facing south (the visitor side)
	var dz := C.z - 0.6
	k.box(Vector3(C.x, 0.55, dz), Vector3(2.8, 1.1, 0.12), "l21_wainscot")
	for sx in [-1.4, 1.4]:
		k.box(Vector3(C.x + sx, 0.55, dz - 0.4), Vector3(0.12, 1.1, 0.9), "l21_wainscot")
	k.box(Vector3(C.x, 1.13, dz - 0.05), Vector3(3.0, 0.06, 0.45), "l21_marble")
	k.box(Vector3(C.x, 0.76, dz - 0.5), Vector3(2.7, 0.05, 0.6), "l21_wainscot", GeoKit.ALL, false)
	k.add_box_shape(Transform3D(Basis(), Vector3(C.x, 0.55, dz - 0.4)), Vector3(2.9, 1.1, 0.95), "wood")
	# ceiling fittings
	for p in [Vector3(C.x - 2.6, y - 0.01, C.z - 2.6), Vector3(C.x + 2.6, y - 0.01, C.z - 2.6), Vector3(C.x - 2.6, y - 0.01, C.z + 2.6), Vector3(C.x + 2.6, y - 0.01, C.z + 2.6)]:
		k.panel(p, 0.6, 0.6, "l21_light_panel")
	# mouths: the first 6.4 m of each hallway belong to the square's chunk
	segment(k, "x", C.z, C.x + SQ, CS, 0.0, false)
	segment(k, "x", C.z, 0.0, C.x - SQ, 0.0, false)
	segment(k, "z", C.x, C.z + SQ, CS, 0.0, false)
	segment(k, "z", C.x, 0.0, C.z - SQ, 0.0, false)


## The neon Exit door's stairwell and the dark junction one storey down.
func exit_well(k: GeoKit) -> void:
	var x0 := EXIT_X - 0.9
	var x1 := EXIT_X + 0.9
	var zt := C.z - HW * 0.5 - T
	# landing, stair (25 risers, 4.5 m), side walls, ceiling
	k.box(Vector3(EXIT_X, -0.15, zt - 0.6), Vector3(1.8, 0.3, 1.2), "l21_dark_floor")
	k.stairs(Vector3(EXIT_X, DY, JZ1), Vector3(0, 0, 1), 1.6, -DY, 25, "l21_dark_floor", 0.28)
	for sx in [x0 - T * 0.5, x1 + T * 0.5]:
		k.box(Vector3(sx, (DY + HH) * 0.5, (JZ1 + zt) * 0.5), Vector3(T, HH - DY, zt - JZ1), "l21_dark")
	k.box(Vector3(EXIT_X, HH + 0.06, (JZ1 + zt) * 0.5), Vector3(1.8 + T * 2, 0.12, zt - JZ1), "l21_dark")
	# junction room with three dark hallway mouths (north, east, west)
	k.box(Vector3((JX0 + JX1) * 0.5, DY - 0.15, (JZ0 + JZ1) * 0.5), Vector3(JX1 - JX0, 0.3, JZ1 - JZ0), "l21_dark_floor")
	k.box(Vector3((JX0 + JX1) * 0.5, DY + HH + 0.06, (JZ0 + JZ1) * 0.5), Vector3(JX1 - JX0 + 0.3, 0.12, JZ1 - JZ0 + 0.3), "l21_dark")
	for side: float in [-1.0, 1.0]:
		var xs := JX0 - T * 0.5 if side < 0.0 else JX1 + T * 0.5
		for seg in [[JZ0, DARK_Z - HW * 0.5], [DARK_Z + HW * 0.5, JZ1]]:
			k.box(Vector3(xs, DY + HH * 0.5, (seg[0] + seg[1]) * 0.5), Vector3(T, HH, seg[1] - seg[0]), "l21_dark")
	for seg in [[JX0, EXIT_X - HW * 0.5], [EXIT_X + HW * 0.5, JX1]]:
		k.box(Vector3((seg[0] + seg[1]) * 0.5, DY + HH * 0.5, JZ0 - T * 0.5), Vector3(seg[1] - seg[0], HH, T), "l21_dark")
	for seg in [[JX0, x0], [x1, JX1]]:
		k.box(Vector3((seg[0] + seg[1]) * 0.5, DY + HH * 0.5, JZ1 + T * 0.5), Vector3(seg[1] - seg[0], HH, T), "l21_dark")
