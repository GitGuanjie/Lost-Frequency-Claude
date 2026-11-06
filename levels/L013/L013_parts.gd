extends RefCounted
## Level 13 building parts: materials, frame-mapped boxes, apartment doors,
## furniture sets (kitchen-living, bedroom, bathroom) and the stair core
## (switchback stair with an open well, lift lobby, landings that repeat above
## and below the two walkable storeys so the shaft reads as 290 floors).
## A frame f = {o, u, v} maps local (x along u, y up, z along v) to world.

const T := 0.14          # party / corridor wall thickness
const TI := 0.10         # partition thickness
const FH := 3.0          # floor-to-floor
const CH := 2.6          # clear ceiling height (film-real apartment block)
const DW := 0.9          # apartment door width
const DH := 2.1          # door height
const RUN := 0.28        # tread run; 9 risers of 0.167 per half-flight
const LAND := 1.3        # landing depth

var lvl: Node3D


func _init(level: Node3D) -> void:
	lvl = level


static func _photo(mat_name: String, asset: String, tint: Color, repeat_m: float, fb: Dictionary, fb_base: String) -> void:
	var base := "res://assets/external/%s/%s_%%s_1k.jpg" % [asset, asset]
	if bool(Settings.get_value("photo_materials")) and ResourceLoader.exists(base % "diff"):
		var m := ORMMaterial3D.new()
		m.albedo_texture = load(base % "diff")
		m.albedo_color = tint
		if ResourceLoader.exists(base % "nor_gl"):
			m.normal_enabled = true
			m.normal_texture = load(base % "nor_gl")
		if ResourceLoader.exists(base % "arm"):
			m.orm_texture = load(base % "arm")
		var r := 1.0 / repeat_m
		m.uv1_scale = Vector3(r, r, 1.0)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		MatLib.register(mat_name, m)
	else:
		MatLib.define(mat_name, fb, fb_base)


static func define_materials() -> void:
	if MatLib.has_mat("l13_wall_white"):
		return
	_photo("l13_wall_white", "painted_plaster_wall", Color(0.90, 0.88, 0.83), 2.5,
		{"albedo_a": Color(0.80, 0.79, 0.75), "albedo_b": Color(0.76, 0.75, 0.71), "grime_height": 0.12}, "plaster")
	_photo("l13_wall_beige", "painted_plaster_wall", Color(0.86, 0.78, 0.63), 2.5,
		{"albedo_a": Color(0.76, 0.69, 0.55), "albedo_b": Color(0.72, 0.65, 0.51), "grime_height": 0.12}, "plaster")
	_photo("l13_lam", "old_wood_floor", Color(1.0, 0.86, 0.70), 2.2,
		{"albedo_a": Color(0.56, 0.42, 0.28), "albedo_b": Color(0.50, 0.37, 0.24)}, "wood_floor")
	MatLib.define("l13_lino", {"albedo_a": Color(0.66, 0.63, 0.55), "albedo_b": Color(0.60, 0.57, 0.50), "pattern": 15,
		"pattern_color": Color(0.50, 0.47, 0.41), "pattern_strength": 0.35, "roughness_a": 0.42, "roughness_b": 0.6,
		"stain_amount": 0.3, "stain_color": Color(0.52, 0.47, 0.37), "noise_scale": 0.9, "bump_strength": 0.15}, "plaster")
	MatLib.define("l13_lino_tile", {"albedo_a": Color(0.74, 0.71, 0.63), "albedo_b": Color(0.70, 0.67, 0.59), "pattern": 9,
		"pattern_scale": Vector2(0.3, 0.3), "pattern_color": Color(0.55, 0.50, 0.42), "pattern_strength": 0.35,
		"roughness_a": 0.4, "roughness_b": 0.55, "stain_amount": 0.25, "bump_strength": 0.1}, "plaster")
	MatLib.define("l13_ceiling", {"albedo_a": Color(0.86, 0.85, 0.81), "albedo_b": Color(0.80, 0.79, 0.75), "noise_scale": 9.0,
		"bump_strength": 0.9, "stain_amount": 0.22, "stain_color": Color(0.70, 0.64, 0.50), "stain_scale": 0.25, "roughness_a": 0.95}, "plaster")
	MatLib.define("l13_base", {"albedo_a": Color(0.30, 0.22, 0.15), "albedo_b": Color(0.27, 0.20, 0.13), "roughness_a": 0.5, "pattern": 0}, "wood_floor")
	MatLib.define("l13_door", {"albedo_a": Color(0.50, 0.35, 0.22), "albedo_b": Color(0.44, 0.30, 0.18), "pattern": 3,
		"pattern_scale": Vector2(0.06, 2.2), "grout_width": 0.0, "roughness_a": 0.45, "roughness_b": 0.6}, "wood_floor")
	MatLib.define("l13_door_bland", {"albedo_a": Color(0.70, 0.67, 0.60), "albedo_b": Color(0.67, 0.64, 0.57), "roughness_a": 0.55,
		"stain_amount": 0.15, "noise_scale": 2.0, "bump_strength": 0.1}, "plaster")
	MatLib.define("l13_door_red", {"albedo_a": Color(0.50, 0.07, 0.05), "albedo_b": Color(0.45, 0.06, 0.04), "roughness_a": 0.4,
		"stain_amount": 0.1, "bump_strength": 0.1}, "plaster")
	MatLib.define("l13_trim", {"albedo_a": Color(0.84, 0.82, 0.76), "albedo_b": Color(0.80, 0.78, 0.72), "roughness_a": 0.45, "bump_strength": 0.05}, "plaster")
	MatLib.define("l13_brass", {"albedo_a": Color(0.62, 0.48, 0.24), "albedo_b": Color(0.55, 0.42, 0.20), "metallic_value": 0.8, "roughness_a": 0.32, "stain_amount": 0.1}, "metal")
	MatLib.define("l13_steel", {"albedo_a": Color(0.58, 0.58, 0.57), "albedo_b": Color(0.53, 0.53, 0.52), "pattern": 2,
		"pattern_scale": Vector2(1.0, 0.012), "pattern_color": Color(0.62, 0.62, 0.61), "pattern_strength": 0.25, "metallic_value": 0.75,
		"roughness_a": 0.32, "roughness_b": 0.45, "stain_amount": 0.08}, "metal")
	MatLib.define("l13_carpet", {"albedo_a": Color(0.36, 0.31, 0.26), "albedo_b": Color(0.31, 0.27, 0.22), "pattern": 6,
		"pattern_strength": 0.0, "wetness": 0.0, "stain_amount": 0.3, "stain_color": Color(0.26, 0.22, 0.17), "noise_scale": 0.6}, "l0_carpet")
	MatLib.define("l13_tile", {"albedo_a": Color(0.86, 0.87, 0.85), "albedo_b": Color(0.82, 0.83, 0.81), "pattern": 1,
		"pattern_scale": Vector2(0.1, 0.1), "grout_width": 0.006, "grout_color": Color(0.62, 0.62, 0.58), "stain_amount": 0.2}, "pool_tile")
	MatLib.define("l13_counter", {"albedo_a": Color(0.78, 0.74, 0.64), "albedo_b": Color(0.74, 0.70, 0.60), "pattern": 15,
		"pattern_color": Color(0.55, 0.52, 0.46), "pattern_strength": 0.3, "roughness_a": 0.35, "bump_strength": 0.05}, "plaster")
	MatLib.define("l13_cabinet", {"albedo_a": Color(0.62, 0.48, 0.32), "albedo_b": Color(0.58, 0.44, 0.29), "pattern": 3,
		"pattern_scale": Vector2(0.05, 1.8), "grout_width": 0.0, "roughness_a": 0.5}, "wood_floor")
	MatLib.define("l13_enamel", {"albedo_a": Color(0.88, 0.87, 0.82), "albedo_b": Color(0.85, 0.84, 0.79), "roughness_a": 0.25,
		"roughness_b": 0.35, "stain_amount": 0.12, "bump_strength": 0.02}, "plaster")
	MatLib.define("l13_porcelain", {"albedo_a": Color(0.93, 0.93, 0.91), "albedo_b": Color(0.91, 0.91, 0.89), "roughness_a": 0.12,
		"roughness_b": 0.18, "stain_amount": 0.08, "bump_strength": 0.0}, "plaster")
	MatLib.define("l13_fabric_a", {"albedo_a": Color(0.40, 0.34, 0.24), "albedo_b": Color(0.36, 0.30, 0.21), "noise_scale": 8.0,
		"roughness_a": 1.0, "bump_strength": 0.7, "stain_amount": 0.25}, "plaster")
	MatLib.define("l13_fabric_b", {"albedo_a": Color(0.33, 0.36, 0.30), "albedo_b": Color(0.29, 0.32, 0.27), "noise_scale": 8.0,
		"roughness_a": 1.0, "bump_strength": 0.7, "stain_amount": 0.25}, "plaster")
	MatLib.define("l13_fabric_c", {"albedo_a": Color(0.42, 0.22, 0.20), "albedo_b": Color(0.38, 0.19, 0.17), "noise_scale": 8.0,
		"roughness_a": 1.0, "bump_strength": 0.7, "stain_amount": 0.25}, "plaster")
	MatLib.define("l13_sheet", {"albedo_a": Color(0.78, 0.76, 0.70), "albedo_b": Color(0.72, 0.70, 0.64), "noise_scale": 5.0,
		"roughness_a": 1.0, "bump_strength": 0.4, "stain_amount": 0.2}, "plaster")
	MatLib.define("l13_wood", {"albedo_a": Color(0.42, 0.30, 0.19), "albedo_b": Color(0.37, 0.26, 0.16), "pattern_scale": Vector2(1.4, 0.12),
		"grout_width": 0.0, "roughness_a": 0.5}, "wood_floor")
	MatLib.define("l13_dark", {"albedo_a": Color(0.05, 0.05, 0.05), "albedo_b": Color(0.04, 0.04, 0.04), "roughness_a": 0.6, "bump_strength": 0.0}, "plaster")
	MatLib.define("l13_screen", {"albedo_a": Color(0.03, 0.035, 0.035), "albedo_b": Color(0.05, 0.055, 0.055), "roughness_a": 0.1,
		"roughness_b": 0.2, "bump_strength": 0.0}, "plaster")
	MatLib.define("l13_chess", {"albedo_a": Color(0.85, 0.80, 0.68), "albedo_b": Color(0.85, 0.80, 0.68), "pattern": 9,
		"pattern_scale": Vector2(0.05, 0.05), "pattern_color": Color(0.12, 0.08, 0.05), "pattern_strength": 1.0, "roughness_a": 0.4}, "plaster")
	MatLib.define("l13_yellow", {"albedo_a": Color(0.78, 0.62, 0.16), "albedo_b": Color(0.74, 0.58, 0.14), "noise_scale": 1.2,
		"roughness_a": 0.85, "stain_amount": 0.2, "stain_color": Color(0.62, 0.48, 0.12), "grime_height": 0.12,
		"grime_color": Color(0.5, 0.4, 0.12), "bump_strength": 0.4}, "plaster")
	MatLib.define("l13_stair", {"albedo_a": Color(0.36, 0.33, 0.29), "albedo_b": Color(0.31, 0.28, 0.25), "stain_amount": 0.35,
		"stain_color": Color(0.24, 0.21, 0.18), "noise_scale": 1.5, "bump_strength": 0.6, "roughness_a": 0.8}, "concrete")
	MatLib.define("l13_rail", {"albedo_a": Color(0.20, 0.19, 0.17), "albedo_b": Color(0.18, 0.17, 0.15), "metallic_value": 0.4, "roughness_a": 0.5, "stain_amount": 0.0}, "metal")
	MatLib.define("l13_mat", {"albedo_a": Color(0.30, 0.25, 0.18), "albedo_b": Color(0.26, 0.21, 0.15), "pattern": 2,
		"pattern_scale": Vector2(0.03, 1.0), "pattern_color": Color(0.2, 0.16, 0.1), "pattern_strength": 0.6, "roughness_a": 1.0}, "plaster")
	MatLib.define("l13_book", {"albedo_a": Color(0.42, 0.18, 0.13), "albedo_b": Color(0.18, 0.25, 0.32), "pattern": 2,
		"pattern_scale": Vector2(0.035, 1.0), "pattern_color": Color(0.66, 0.58, 0.40), "pattern_strength": 0.75, "noise_scale": 40.0, "bump_strength": 0.0}, "plaster")
	MatLib.define("l13_print_a", {"albedo_a": Color(0.46, 0.52, 0.42), "albedo_b": Color(0.62, 0.58, 0.44), "noise_scale": 3.0,
		"noise_mix": 0.9, "pattern": 11, "pattern_color": Color(0.38, 0.42, 0.48), "pattern_strength": 0.5, "roughness_a": 0.5, "bump_strength": 0.0}, "plaster")
	MatLib.define("l13_print_b", {"albedo_a": Color(0.66, 0.50, 0.36), "albedo_b": Color(0.42, 0.40, 0.46), "noise_scale": 2.5,
		"noise_mix": 0.9, "roughness_a": 0.5, "bump_strength": 0.0, "stain_amount": 0.3}, "plaster")
	MatLib.define("l13_clock", {"albedo_a": Color(0.88, 0.86, 0.80), "albedo_b": Color(0.86, 0.84, 0.78), "pattern": 5,
		"pattern_scale": Vector2(0.08, 0.08), "pattern_color": Color(0.1, 0.1, 0.1), "pattern_strength": 0.6, "roughness_a": 0.3}, "plaster")
	MatLib.define("l13_rug_a", {"albedo_a": Color(0.42, 0.16, 0.12), "albedo_b": Color(0.36, 0.13, 0.10), "pattern": 10,
		"pattern_scale": Vector2(0.4, 0.5), "pattern_color": Color(0.58, 0.42, 0.26), "pattern_strength": 0.45, "roughness_a": 1.0,
		"bump_strength": 0.6, "stain_amount": 0.25, "noise_scale": 3.0}, "plaster")
	MatLib.define("l13_rug_b", {"albedo_a": Color(0.30, 0.30, 0.22), "albedo_b": Color(0.26, 0.26, 0.19), "pattern": 10,
		"pattern_scale": Vector2(0.35, 0.45), "pattern_color": Color(0.50, 0.44, 0.30), "pattern_strength": 0.4, "roughness_a": 1.0,
		"bump_strength": 0.6, "stain_amount": 0.25, "noise_scale": 3.0}, "plaster")
	MatLib.define("l13_cork", {"albedo_a": Color(0.55, 0.40, 0.25), "albedo_b": Color(0.48, 0.34, 0.20), "noise_scale": 12.0, "bump_strength": 0.8}, "plaster")
	MatLib.register("l13_dome", MatLib.standard(Color(0.95, 0.88, 0.72), 0.4, 0.0, Color(1.0, 0.80, 0.52), 1.7))
	MatLib.register("l13_dome_dead", MatLib.standard(Color(0.62, 0.58, 0.50), 0.5))
	MatLib.register("l13_bulk", MatLib.standard(Color(0.9, 0.92, 0.9), 0.4, 0.0, Color(0.92, 0.95, 1.0), 1.6))
	MatLib.register("l13_glow", MatLib.standard(Color(0.9, 0.7, 0.4), 0.8, 0.0, Color(1.0, 0.72, 0.38), 2.2))
	MatLib.register("l13_shade", MatLib.standard(Color(0.86, 0.76, 0.58), 0.8, 0.0, Color(1.0, 0.78, 0.5), 0.9))
	MatLib.register("l13_led", MatLib.standard(Color(0.6, 0.2, 0.1), 0.4, 0.0, Color(1.0, 0.35, 0.15), 2.5))
	MatLib.register("l13_tv_on", MatLib.panel(Color(0.62, 0.70, 0.78), 1.4, 1.0, 3.0))
	var mirror := StandardMaterial3D.new()
	mirror.albedo_color = Color(0.55, 0.58, 0.6)
	mirror.metallic = 1.0
	mirror.roughness = 0.06
	MatLib.register("l13_mirror", mirror)


# ------------------------------------------------------------- frames

static func fr(o: Vector3, u: Vector3, v: Vector3) -> Dictionary:
	return {"o": o, "u": u, "v": v}


static func fp(f: Dictionary, x: float, y: float, z: float) -> Vector3:
	return f["o"] + f["u"] * x + Vector3.UP * y + f["v"] * z


## Axis-aligned box between two local corners of frame f.
static func fb(k: GeoKit, f: Dictionary, x0: float, y0: float, z0: float, x1: float, y1: float, z1: float, mat: String, collide := false, faces := GeoKit.ALL) -> void:
	var p := fp(f, x0, y0, z0)
	var q := fp(f, x1, y1, z1)
	k.box_mm(Vector3(minf(p.x, q.x), minf(p.y, q.y), minf(p.z, q.z)), Vector3(maxf(p.x, q.x), maxf(p.y, q.y), maxf(p.z, q.z)), mat, faces, collide)


static func fwall(k: GeoKit, f: Dictionary, x0: float, z0: float, x1: float, z1: float, y0: float, h: float, mat: String, ops: Array = [], th := TI) -> void:
	wall(k, fp(f, x0, y0, z0), fp(f, x1, y0, z1), h, th, mat, ops)


## GeoKit.wall with visual-only lintels (nobody can reach above a door; saves colliders).
static func wall(k: GeoKit, a: Vector3, b: Vector3, height: float, thick: float, mat: String, ops: Array = []) -> void:
	var dir := Vector3(b.x - a.x, 0.0, b.z - a.z)
	var length := dir.length()
	if length < 0.01:
		return
	dir = dir / length
	var bas := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var sorted := ops.duplicate()
	sorted.sort_custom(func(p, q): return float(p["at"]) < float(q["at"]))
	var cursor := 0.0
	for op in sorted:
		var w: float = op.get("w", 1.0)
		var top: float = float(op.get("sill", 0.0)) + float(op.get("h", 2.1))
		var s0 := clampf(float(op["at"]) - w * 0.5, 0.0, length)
		var s1 := clampf(float(op["at"]) + w * 0.5, 0.0, length)
		if s0 > cursor + 0.001:
			k.box_xf(Transform3D(bas, a + dir * ((cursor + s0) * 0.5) + Vector3.UP * (height * 0.5)), Vector3(s0 - cursor, height, thick), mat)
		if top < height - 0.001:
			k.box_xf(Transform3D(bas, a + dir * ((s0 + s1) * 0.5) + Vector3.UP * ((top + height) * 0.5)), Vector3(s1 - s0, height - top, thick), mat, GeoKit.ALL, false)
		cursor = maxf(cursor, s1)
	if cursor < length - 0.001:
		k.box_xf(Transform3D(bas, a + dir * ((cursor + length) * 0.5) + Vector3.UP * (height * 0.5)), Vector3(length - cursor, height, thick), mat)


static func label(parent: Node3D, text: String, p: Vector3, n: Vector3, px: float, col: Color, vis := 12.0) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = 64
	l.pixel_size = px
	l.modulate = col
	l.outline_size = 0
	l.double_sided = false
	var z := n.normalized()
	var x := Vector3.UP.cross(z).normalized()
	l.basis = Basis(x, Vector3.UP, z)
	l.position = p + z * 0.012
	l.visibility_range_end = vis
	parent.add_child(l)
	return l


# ------------------------------------------------------------- doors

## Door on the wall line a->b at distance `at`; n = unit normal pointing to the
## corridor side. kind: "open" (apartment, leaf swung inward), "closed"
## (inhabited), "bland" (exit: flush, no number, round knob), "red", "plain".
## Returns the corridor-side centre at floor level.
static func door(k: GeoKit, node: Node3D, a: Vector3, b: Vector3, at: float, n: Vector3, kind: String, number: String, w := DW) -> Vector3:
	var dir := (b - a)
	dir.y = 0.0
	dir = dir.normalized()
	var c := a + dir * at
	var bas := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var trim := "l13_trim" if kind != "bland" else "l13_door_bland"
	var cas := 0.07 if kind != "bland" else 0.035
	for s in [-1.0, 1.0]:
		for side in [-1.0, 1.0]:
			k.box_xf(Transform3D(bas, c + dir * (s * (w * 0.5 + cas * 0.5)) + Vector3.UP * (DH * 0.5) + n * side * (T * 0.5 + 0.012)), Vector3(cas, DH + cas, 0.024), trim, GeoKit.ALL, false)
	for side in [-1.0, 1.0]:
		k.box_xf(Transform3D(bas, c + Vector3.UP * (DH + cas * 0.5) + n * side * (T * 0.5 + 0.012)), Vector3(w + cas * 2.0, cas, 0.024), trim, GeoKit.ALL, false)
	var leaf := "l13_door"
	match kind:
		"bland": leaf = "l13_door_bland"
		"red": leaf = "l13_door_red"
	if kind == "open":
		var th := deg_to_rad(76.0)
		var ld := (dir * cos(th) - n * sin(th)).normalized()
		var hinge := c - dir * (w * 0.5 - 0.02) - n * (T * 0.5 + 0.03)
		var lb := Basis(ld, Vector3.UP, ld.cross(Vector3.UP))
		k.box_xf(Transform3D(lb, hinge + ld * ((w - 0.04) * 0.5) + Vector3.UP * (DH * 0.5 - 0.01)), Vector3(w - 0.04, DH - 0.02, 0.045), leaf, GeoKit.ALL, false)
		k.box_xf(Transform3D(lb, hinge + ld * (w - 0.13) + Vector3.UP * 1.0 + lb.z * 0.05), Vector3(0.12, 0.02, 0.03), "l13_brass", GeoKit.ALL, false)
	else:
		k.box_xf(Transform3D(bas, c + Vector3.UP * (DH * 0.5)), Vector3(w, DH, 0.05), leaf, GeoKit.ALL, true)
		var hx := c + dir * (w * 0.5 - 0.1) + Vector3.UP * 1.0 + n * 0.045
		if kind == "bland":
			k.cylinder(hx, 0.032, 0.05, "l13_steel", 8, false)
		else:
			k.box_xf(Transform3D(bas, hx + n * 0.01), Vector3(0.13, 0.022, 0.03), "l13_brass", GeoKit.ALL, false)
			k.box_xf(Transform3D(bas, hx - dir * 0.03 - Vector3.UP * 0.02), Vector3(0.05, 0.16, 0.012), "l13_brass", GeoKit.ALL, false)
	if kind != "bland" and kind != "plain":
		# number plate and peephole on the corridor face
		var pc := c + Vector3.UP * 1.62 + n * 0.035
		k.box_xf(Transform3D(bas, pc + Vector3.UP * 0.13), Vector3(0.016, 0.016, 0.03), "l13_brass", GeoKit.ALL, false)
		if number != "":
			k.box_xf(Transform3D(bas, pc + Vector3.UP * 0.32), Vector3(0.2, 0.08, 0.008), "l13_brass", GeoKit.ALL, false)
			label(node, number, pc + Vector3.UP * 0.32 + n * 0.006, n, 0.0012, Color(0.12, 0.09, 0.05), 7.0)
	return c - n * 0.0


## Baseboard on one face of the wall a->b (n = face normal), skipping openings.
static func baseboard(k: GeoKit, a: Vector3, b: Vector3, n: Vector3, ops: Array) -> void:
	var dir := b - a
	dir.y = 0.0
	var len := dir.length()
	dir = dir.normalized()
	var bas := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
	var cuts: Array = []
	for o in ops:
		cuts.append([float(o["at"]) - float(o["w"]) * 0.5 - 0.08, float(o["at"]) + float(o["w"]) * 0.5 + 0.08])
	cuts.sort_custom(func(p, q): return p[0] < q[0])
	var s := 0.0
	cuts.append([len, len])
	for c in cuts:
		var e: float = minf(float(c[0]), len)
		if e - s > 0.05:
			k.box_xf(Transform3D(bas, a + dir * ((s + e) * 0.5) + Vector3.UP * 0.05 + n * (T * 0.5 + 0.008)), Vector3(e - s, 0.1, 0.016), "l13_base", GeoKit.ALL, false)
		s = maxf(s, float(c[1]))


# ------------------------------------------------------------- furniture

## Kitchen run along the local u axis at v = 0..0.62 of frame f (back to wall).
## Returns {fridge: Vector3 (front centre), micro: Vector3}.
static func kitchen(k: GeoKit, f: Dictionary, len: float) -> Dictionary:
	var L := clampf(len, 2.4, 3.6)
	fb(k, f, 0.0, 0.0, 0.0, 0.72, 1.78, 0.68, "l13_enamel")                          # fridge
	fb(k, f, 0.06, 1.0, 0.68, 0.08, 1.5, 0.71, "l13_steel")
	k.add_box_shape(Transform3D(Basis(), (fp(f, 0.0, 0.0, 0.0) + fp(f, L, 0.9, 0.66)) * 0.5), (fp(f, L, 0.9, 0.66) - fp(f, 0.0, 0.0, 0.0)).abs(), "wood")
	fb(k, f, 0.75, 0.0, 0.0, L, 0.86, 0.6, "l13_cabinet")                            # base units
	fb(k, f, 0.74, 0.86, 0.0, L, 0.9, 0.63, "l13_counter")
	fb(k, f, 1.25, 0.895, 0.12, 1.75, 0.905, 0.5, "l13_steel")                       # sink
	fb(k, f, 1.48, 0.9, 0.04, 1.52, 1.15, 0.08, "l13_steel")
	fb(k, f, L - 0.66, 0.9, 0.06, L - 0.06, 0.92, 0.56, "l13_dark")                  # hob
	fb(k, f, 0.95, 0.9, 0.08, 1.4, 1.17, 0.42, "l13_enamel")                         # microwave
	fb(k, f, 1.0, 0.95, 0.42, 1.28, 1.13, 0.425, "l13_screen")
	fb(k, f, 0.75, 1.45, 0.0, L, 2.15, 0.34, "l13_cabinet")                          # wall units
	for i in int((L - 0.75) / 0.6):
		fb(k, f, 0.78 + i * 0.6, 0.62, 0.6, 0.8 + i * 0.6 + 0.04, 0.64, 0.62, "l13_steel")
	return {"fridge": fp(f, 0.36, 1.0, 0.95), "micro": fp(f, 1.18, 1.05, 0.7)}


## Sofa with its back to the wall (local v = 0), centred at u.
static func sofa(k: GeoKit, f: Dictionary, u: float, fab: String) -> void:
	fb(k, f, u - 0.95, 0.0, 0.0, u + 0.95, 0.42, 0.88, fab, true)
	fb(k, f, u - 0.95, 0.42, 0.0, u + 0.95, 0.85, 0.22, fab)
	fb(k, f, u - 0.95, 0.42, 0.0, u - 0.75, 0.62, 0.88, fab)
	fb(k, f, u + 0.75, 0.42, 0.0, u + 0.95, 0.62, 0.88, fab)
	fb(k, f, u - 0.72, 0.42, 0.24, u - 0.02, 0.52, 0.84, fab)
	fb(k, f, u + 0.02, 0.42, 0.24, u + 0.72, 0.52, 0.84, fab)


## Television on a low stand against the wall (local v = 0). Returns screen centre.
static func tv(k: GeoKit, f: Dictionary, u: float) -> Vector3:
	fb(k, f, u - 0.6, 0.0, 0.02, u + 0.6, 0.5, 0.45, "l13_wood", true)
	fb(k, f, u - 0.36, 0.5, 0.06, u + 0.36, 1.02, 0.5, "l13_dark")                  # CRT body
	fb(k, f, u - 0.3, 0.56, 0.5, u + 0.22, 0.96, 0.51, "l13_screen")
	fb(k, f, u + 0.25, 0.6, 0.5, u + 0.33, 0.66, 0.51, "l13_steel")
	return fp(f, u - 0.04, 0.76, 0.512)


static func table2(k: GeoKit, f: Dictionary, u: float, v: float, chess: bool) -> void:
	fb(k, f, u - 0.4, 0.72, v - 0.4, u + 0.4, 0.75, v + 0.4, "l13_wood", true)
	fb(k, f, u - 0.04, 0.0, v - 0.04, u + 0.04, 0.72, v + 0.04, "l13_rail")
	fb(k, f, u - 0.25, 0.0, v - 0.25, u + 0.25, 0.02, v + 0.25, "l13_rail")
	if chess:
		fb(k, f, u - 0.2, 0.75, v - 0.2, u + 0.2, 0.77, v + 0.2, "l13_chess")
		for i in 6:
			fb(k, f, u - 0.17 + i * 0.068, 0.77, v - 0.17, u - 0.15 + i * 0.068, 0.81, v - 0.15, "l13_porcelain")
			fb(k, f, u - 0.17 + i * 0.068, 0.77, v + 0.15, u - 0.15 + i * 0.068, 0.81, v + 0.17, "l13_dark")
	for s in [-1.0, 1.0]:
		chair(k, f, u, v + s * 0.62, s)


static func chair(k: GeoKit, f: Dictionary, u: float, v: float, facing: float) -> void:
	fb(k, f, u - 0.22, 0.44, v - 0.22, u + 0.22, 0.48, v + 0.22, "l13_wood")
	for a in [-1.0, 1.0]:
		for b in [-1.0, 1.0]:
			fb(k, f, u + a * 0.19 - 0.02, 0.0, v + b * 0.19 - 0.02, u + a * 0.19 + 0.02, 0.44, v + b * 0.19 + 0.02, "l13_wood")
	fb(k, f, u - 0.22, 0.48, v + facing * 0.2 - 0.02, u + 0.22, 0.92, v + facing * 0.2 + 0.02, "l13_wood")


## Bed with its head against local v = 0, centred on u. Returns mattress top centre.
static func bed(k: GeoKit, f: Dictionary, u: float, wide: float, sheet: String) -> Vector3:
	fb(k, f, u - wide * 0.5, 0.0, 0.0, u + wide * 0.5, 0.95, 0.06, "l13_wood")
	fb(k, f, u - wide * 0.5, 0.0, 0.06, u + wide * 0.5, 0.32, 2.0, "l13_wood", true)
	fb(k, f, u - wide * 0.5 + 0.02, 0.32, 0.08, u + wide * 0.5 - 0.02, 0.52, 1.98, "l13_sheet")
	fb(k, f, u - wide * 0.5, 0.48, 0.7, u + wide * 0.5, 0.55, 1.95, sheet)
	fb(k, f, u - wide * 0.5 + 0.1, 0.52, 0.12, u + wide * 0.5 - 0.1, 0.62, 0.48, "l13_sheet")
	return fp(f, u, 0.56, 1.0)


static func toilet(k: GeoKit, f: Dictionary, u: float) -> void:
	fb(k, f, u - 0.19, 0.0, 0.0, u + 0.19, 0.78, 0.2, "l13_porcelain")
	fb(k, f, u - 0.17, 0.0, 0.2, u + 0.17, 0.42, 0.66, "l13_porcelain")
	fb(k, f, u - 0.18, 0.42, 0.22, u + 0.18, 0.44, 0.68, "l13_porcelain")


static func basin(k: GeoKit, f: Dictionary, u: float) -> void:
	fb(k, f, u - 0.07, 0.0, 0.04, u + 0.07, 0.78, 0.18, "l13_porcelain")
	fb(k, f, u - 0.28, 0.78, 0.0, u + 0.28, 0.88, 0.46, "l13_porcelain")
	fb(k, f, u - 0.26, 1.2, 0.0, u + 0.26, 1.8, 0.02, "l13_mirror")
	fb(k, f, u - 0.02, 0.88, 0.04, u + 0.02, 1.0, 0.16, "l13_steel")


static func tub(k: GeoKit, f: Dictionary, u0: float, u1: float) -> void:
	fb(k, f, u0, 0.0, 0.0, u1, 0.55, 0.75, "l13_porcelain", true)
	fb(k, f, u0 + 0.06, 0.4, 0.06, u1 - 0.06, 0.551, 0.69, "l13_tile")
	fb(k, f, u1 - 0.3, 1.0, 0.0, u1 - 0.24, 1.9, 0.04, "l13_steel")


static func wardrobe(k: GeoKit, f: Dictionary, u: float) -> void:
	fb(k, f, u - 0.5, 0.0, 0.0, u + 0.5, 2.0, 0.58, "l13_wood", true)
	fb(k, f, u - 0.01, 0.1, 0.58, u + 0.01, 1.95, 0.59, "l13_dark")
	for s in [-1.0, 1.0]:
		fb(k, f, u + s * 0.08 - 0.01, 1.0, 0.58, u + s * 0.08 + 0.01, 1.2, 0.61, "l13_brass")


static func shelf(k: GeoKit, f: Dictionary, u: float) -> void:
	fb(k, f, u - 0.45, 0.0, 0.0, u + 0.45, 1.8, 0.02, "l13_wood")
	for sd in [-1.0, 1.0]:
		fb(k, f, u + sd * 0.44 - 0.02, 0.0, 0.0, u + sd * 0.44 + 0.02, 1.8, 0.3, "l13_wood")
	for i in 5:
		fb(k, f, u - 0.42, 0.06 + i * 0.43, 0.02, u + 0.42, 0.08 + i * 0.43, 0.3, "l13_wood")
		if i < 4:
			var fill := 0.84 - float((i * 37) % 30) / 100.0
			fb(k, f, u - 0.42, 0.08 + i * 0.43, 0.04, u - 0.42 + fill, 0.31 + i * 0.43 - float(i % 2) * 0.04, 0.27, "l13_book")


# ------------------------------------------------------------- stair core

## Switchback stair shaft with an open well. Shaft interior is local
## x 0..3, z 0..5.2 of frame f (front/door wall at z = 0, door centred at x 1.5).
## Storeys from s_lo to s_hi are built (y = s * FH); `doors` = storeys whose
## landing door is open to a lobby. `stop_lo` / `stop_hi`: the stair ends there.
func shaft(k: GeoKit, node: Node3D, f: Dictionary, s_lo: int, s_hi: int, stop_hi: bool, wall_mat: String, labels: Dictionary, group: String) -> void:
	var y_lo := s_lo * FH - 0.3
	var y_hi := s_hi * FH + CH + (0.0 if stop_hi else FH)
	var h := y_hi - y_lo
	for s in range(s_lo, s_hi + 1):
		var y := s * FH
		fwall(k, f, -T * 0.5, 0.0, 3.0 + T * 0.5, 0.0, y - 0.4 + (0.0 if s > s_lo else 0.1), FH, wall_mat, [{"at": 1.5 + T * 0.5, "w": DW, "h": DH, "sill": 0.4 - (0.0 if s > s_lo else 0.1)}], T)
	if not stop_hi:
		fwall(k, f, -T * 0.5, 0.0, 3.0 + T * 0.5, 0.0, (s_hi + 1) * FH - 0.4, CH + 0.4, wall_mat, [], T)
	fwall(k, f, -T * 0.5, 5.2, 3.0 + T * 0.5, 5.2, y_lo, h, wall_mat, [], T)
	fwall(k, f, 0.0, 0.0, 0.0, 5.2, y_lo, h, wall_mat, [], T)
	fwall(k, f, 3.0, 0.0, 3.0, 5.2, y_lo, h, wall_mat, [], T)
	fb(k, f, 0.0, y_lo - 0.1, 0.0, 3.0, y_lo, 5.2, "void_black", true)
	fb(k, f, 0.0, y_hi, 0.0, 3.0, y_hi + 0.1, 5.2, "l13_ceiling", false)
	var top_s := s_hi if stop_hi else s_hi + 1
	for s in range(s_lo, top_s + 1):
		var y := s * FH
		var far := mini(absi(s), absi(s - 1))
		var reach := s >= -1 and s <= 2
		fb(k, f, 0.0, y - 0.18, 0.0, 3.0, y, LAND, "l13_stair", reach)                         # floor landing
		label(node, str(labels.get(s, "")), fp(f, 0.55, y + 1.55, 0.0) + f["v"] * (T * 0.5), f["v"], 0.006, Color(0.16, 0.15, 0.13), 22.0)
		# landing light (fades out with distance from the walkable storeys)
		var lp := fp(f, 2.45, y + 2.2, 0.05 + T * 0.5)
		fb(k, f, 2.3, y + 2.12, T * 0.5, 2.6, y + 2.28, T * 0.5 + 0.1, "l13_bulk" if far <= 2 else "l13_dome_dead")
		if far <= 2:
			lvl.lamp(lp + f["v"] * 0.5, Color(0.92, 0.95, 1.0), [0.5, 0.5, 0.3][far], 3.3, 0.0, group, s, true)
		if s == top_s:
			if not stop_hi:
				fb(k, f, 0.0, y - 0.18, LAND, 3.0, y + CH, 5.2, "l13_stair", false)
			continue
		# flight A (x 0..1.2) up to the mid landing, flight B (x 1.8..3) up to the next floor
		# flights are walkable (and collide) only where the player can actually be
		var ra := s >= -1 and s <= 1
		flight(k, fp(f, 0.62, y, LAND), f["v"], 1.16, 9, ra)
		_soffit(k, fp(f, 0.62, y - 0.18, LAND), fp(f, 0.62, y + 1.32, LAND + 9 * RUN), 1.16)
		fb(k, f, 0.0, y + 1.32, LAND + 9 * RUN, 3.0, y + 1.5, 5.2, "l13_stair", ra)
		flight(k, fp(f, 2.38, y + 1.5, LAND + 9 * RUN), -f["v"], 1.16, 9, ra)
		_soffit(k, fp(f, 2.38, y + 1.32, LAND + 9 * RUN), fp(f, 2.38, y + 2.82, LAND), 1.16)
		# balustrades on the well (x 1.2 .. 1.8): sloped rails with real collision
		_balustrade(k, fp(f, 1.22, y, LAND), fp(f, 1.22, y + 1.5, LAND + 9 * RUN), ra)
		_balustrade(k, fp(f, 1.78, y + 1.5, LAND + 9 * RUN), fp(f, 1.78, y + 3.0, LAND), ra)
		fb(k, f, 1.2, y + 1.5, LAND + 9 * RUN - 0.03, 1.8, y + 2.45, LAND + 9 * RUN + 0.02, "l13_rail", ra)
		fb(k, f, 1.2, y + 3.0, LAND - 0.03, 1.8, y + 3.95, LAND + 0.02, "l13_rail", ra)
		lp = fp(f, 1.5, y + 1.5 + 2.2, 5.15 - T * 0.5)
		fb(k, f, 1.35, y + 1.5 + 2.12, 5.2 - T * 0.5 - 0.1, 1.65, y + 1.5 + 2.28, 5.2 - T * 0.5, "l13_bulk" if far <= 1 else "l13_dome_dead")
		if far <= 1:
			lvl.lamp(lp - f["v"] * 0.5, Color(0.92, 0.95, 1.0), 0.35, 2.8, 0.0, group, s, true)


func _soffit(k: GeoKit, a: Vector3, b: Vector3, w: float) -> void:
	var z := (b - a).normalized()
	var x := Vector3.UP.cross(z).normalized()
	var y := z.cross(x).normalized()
	k.box_xf(Transform3D(Basis(x, y, z), (a + b) * 0.5 - y * 0.06), Vector3(w, 0.12, (b - a).length()), "l13_stair", GeoKit.ALL, false)


## Half-flight of 9 risers: visual treads (sawtooth) + a smooth ramp collider.
func flight(k: GeoKit, start: Vector3, dir: Vector3, width: float, steps: int, collide: bool) -> void:
	var bas := Basis(Vector3.UP.cross(dir).normalized(), Vector3.UP, dir)
	var sh := FH * 0.5 / steps
	for i in steps:
		var top := sh * (i + 1)
		var c := start + dir * (RUN * (i + 0.5)) + Vector3.UP * (top - sh)
		k.box_xf(Transform3D(bas, c), Vector3(width, sh * 2.0, RUN), "l13_stair", GeoKit.PY | GeoKit.NZ | GeoKit.PX | GeoKit.NX, false)
	if collide:
		var a := start + Vector3.UP * 0.02
		var b := start + dir * (RUN * steps) + Vector3.UP * (FH * 0.5)
		var z := (b - a).normalized()
		var x := Vector3.UP.cross(z).normalized()
		var y := z.cross(x).normalized()
		k.add_box_shape(Transform3D(Basis(x, y, z), (a + b) * 0.5 - y * 0.05), Vector3(width, 0.1, (b - a).length()), "concrete")


func _balustrade(k: GeoKit, a: Vector3, b: Vector3, solid: bool) -> void:
	var z := (b - a).normalized()
	var x := Vector3.UP.cross(z).normalized()
	var y := z.cross(x).normalized()
	var mid := (a + b) * 0.5
	k.box_xf(Transform3D(Basis(x, y, z), mid + Vector3.UP * 0.92), Vector3(0.06, 0.05, (b - a).length()), "l13_rail", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(x, y, z), mid + Vector3.UP * 0.12), Vector3(0.03, 0.03, (b - a).length()), "l13_rail", GeoKit.ALL, false)
	if solid:
		k.add_box_shape(Transform3D(Basis(x, y, z), mid + Vector3.UP * 0.5), Vector3(0.05, 0.9, (b - a).length()), "metal")
	var n := int((b - a).length() / (0.14 if solid else 0.42))
	for i in n:
		var p := a.lerp(b, (i + 0.5) / n)
		k.box(p + Vector3.UP * 0.5, Vector3(0.018, 0.84, 0.018), "l13_rail", GeoKit.SIDES, false)
