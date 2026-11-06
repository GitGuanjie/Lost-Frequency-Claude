extends RefCounted
## Level 12 props (static builders). Everything is boxes in a local frame `xf`
## so a piece can be yawed, tilted and sunk "halfway through the floor" (the
## floor slab hides whatever is below y = 0).
##   SOURCE: "Lamps, chairs, tables, drawers, the works." / "Some are halfway
##   through the floor." / main-room table and chair / the main door and its
##   copycats out in the white.

const DOOR_W := 0.9
const DOOR_H := 2.05


## Level 12 looks: white paint, a plain wooden table, old beaten furniture.
static func materials() -> void:
	MatLib.define("l12_wall", {"albedo_a": Color(0.93, 0.93, 0.92), "albedo_b": Color(0.9, 0.9, 0.89), "noise_scale": 0.6,
		"roughness_a": 0.85, "roughness_b": 0.95, "bump_strength": 0.12, "grime_height": 0.09, "grime_color": Color(0.8, 0.8, 0.79)}, "plaster")
	MatLib.define("l12_ceiling", {"albedo_a": Color(0.95, 0.95, 0.94), "albedo_b": Color(0.93, 0.93, 0.92), "bump_strength": 0.05}, "plaster")
	MatLib.define("l12_room_floor", {"albedo_a": Color(0.86, 0.86, 0.85), "albedo_b": Color(0.82, 0.82, 0.81), "roughness_a": 0.5,
		"roughness_b": 0.65, "noise_scale": 0.4, "stain_amount": 0.12, "stain_color": Color(0.74, 0.74, 0.72), "bump_strength": 0.05}, "plaster")
	MatLib.define("l12_floor", {"albedo_a": Color(0.94, 0.94, 0.94), "albedo_b": Color(0.92, 0.92, 0.92), "noise_scale": 0.15,
		"roughness_a": 0.95, "roughness_b": 1.0, "bump_strength": 0.03}, "plaster")
	MatLib.define("l12_floor_worn", {"albedo_a": Color(0.92, 0.92, 0.91), "albedo_b": Color(0.88, 0.88, 0.87), "stain_amount": 0.3,
		"stain_color": Color(0.76, 0.76, 0.75), "stain_scale": 0.2, "bump_strength": 0.08}, "plaster")
	MatLib.define("l12_floor_broken", {"albedo_a": Color(0.9, 0.9, 0.89), "albedo_b": Color(0.85, 0.85, 0.84), "pattern": 1,
		"pattern_scale": Vector2(2.0, 2.0), "grout_width": 0.012, "grout_color": Color(0.62, 0.62, 0.61), "tile_variation": 0.04,
		"stain_amount": 0.45, "stain_color": Color(0.7, 0.7, 0.69), "bump_strength": 0.15}, "plaster")
	MatLib.define("l12_table", {"albedo_a": Color(0.5, 0.36, 0.22), "albedo_b": Color(0.44, 0.31, 0.19), "pattern_scale": Vector2(1.4, 0.2)}, "wood_floor")
	MatLib.define("l12_wood_old", {"albedo_a": Color(0.34, 0.24, 0.15), "albedo_b": Color(0.27, 0.18, 0.11), "stain_amount": 0.55,
		"stain_color": Color(0.18, 0.13, 0.08), "roughness_a": 0.75, "roughness_b": 0.95, "bump_strength": 0.7}, "wood_floor")
	MatLib.define("l12_wood_pale", {"albedo_a": Color(0.55, 0.47, 0.36), "albedo_b": Color(0.47, 0.39, 0.29), "stain_amount": 0.45,
		"stain_color": Color(0.36, 0.3, 0.22), "roughness_a": 0.85, "roughness_b": 1.0}, "wood_floor")
	MatLib.define("l12_paint_old", {"albedo_a": Color(0.74, 0.7, 0.58), "albedo_b": Color(0.66, 0.62, 0.5), "stain_amount": 0.5,
		"stain_color": Color(0.5, 0.44, 0.32), "peel_amount": 0.35, "peel_color": Color(0.36, 0.26, 0.16)}, "plaster")
	MatLib.define("l12_seat_old", {"albedo_a": Color(0.4, 0.42, 0.34), "albedo_b": Color(0.33, 0.35, 0.28), "roughness_a": 1.0,
		"stain_amount": 0.5, "stain_color": Color(0.26, 0.25, 0.2), "noise_scale": 3.0}, "plaster")
	MatLib.define("l12_metal_old", {"albedo_a": Color(0.36, 0.35, 0.33), "albedo_b": Color(0.28, 0.27, 0.25), "stain_amount": 0.5,
		"stain_color": Color(0.36, 0.22, 0.12)}, "metal")
	MatLib.define("l12_shade", {"albedo_a": Color(0.8, 0.72, 0.52), "albedo_b": Color(0.72, 0.63, 0.43), "stain_amount": 0.45,
		"stain_color": Color(0.58, 0.48, 0.3), "roughness_a": 1.0, "noise_scale": 2.5}, "plaster")
	MatLib.define("l12_door", {"albedo_a": Color(0.85, 0.84, 0.8), "albedo_b": Color(0.82, 0.81, 0.77), "roughness_a": 0.45,
		"roughness_b": 0.55, "grime_height": 0.3, "grime_color": Color(0.7, 0.69, 0.65), "bump_strength": 0.05}, "plaster")
	MatLib.define("l12_door_panel", {"albedo_a": Color(0.8, 0.79, 0.75), "albedo_b": Color(0.78, 0.77, 0.73), "roughness_a": 0.45}, "plaster")
	MatLib.define("l12_trim", {"albedo_a": Color(0.8, 0.79, 0.76), "albedo_b": Color(0.78, 0.77, 0.74)}, "trim_white")
	MatLib.define("l12_knob", {"albedo_a": Color(0.55, 0.47, 0.3), "albedo_b": Color(0.45, 0.38, 0.24), "metallic_value": 0.8}, "metal")
	MatLib.register("l12_panel", MatLib.panel(Color(1.0, 1.0, 0.98), 2.4))


static func _b(k: GeoKit, xf: Transform3D, c: Vector3, s: Vector3, mat: String) -> void:
	k.box_xf(xf * Transform3D(Basis(), c), s, mat, GeoKit.ALL, false)


static func _col(k: GeoKit, xf: Transform3D, c: Vector3, s: Vector3, surface: String) -> void:
	k.add_box_shape(xf * Transform3D(Basis(), c), s, surface)
	k.signature = hash([k.signature, (xf * c).snapped(Vector3.ONE * 0.01), s])


## Plain four-legged table. `broken` legs are left out (abyss breakdown).
static func table(k: GeoKit, xf: Transform3D, top: String, leg: String, w := 1.1, d := 0.7, h := 0.74, broken := 0, collide := true) -> void:
	_b(k, xf, Vector3(0, h - 0.022, 0), Vector3(w, 0.044, d), top)
	_b(k, xf, Vector3(0, h - 0.09, d * 0.5 - 0.07), Vector3(w - 0.16, 0.09, 0.022), leg)
	_b(k, xf, Vector3(0, h - 0.09, -d * 0.5 + 0.07), Vector3(w - 0.16, 0.09, 0.022), leg)
	_b(k, xf, Vector3(w * 0.5 - 0.07, h - 0.09, 0), Vector3(0.022, 0.09, d - 0.16), leg)
	_b(k, xf, Vector3(-w * 0.5 + 0.07, h - 0.09, 0), Vector3(0.022, 0.09, d - 0.16), leg)
	var i := 0
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			i += 1
			if i <= broken:
				continue
			_b(k, xf, Vector3(sx * (w * 0.5 - 0.07), (h - 0.044) * 0.5, sz * (d * 0.5 - 0.07)), Vector3(0.05, h - 0.044, 0.05), leg)
	if collide:
		_col(k, xf, Vector3(0, h * 0.5, 0), Vector3(w, h, d), "wood")


## Kitchen chair facing local +Z (back on -Z).
static func chair(k: GeoKit, xf: Transform3D, wood: String, seat: String, collide := true, back := true) -> void:
	var sh := 0.46
	_b(k, xf, Vector3(0, sh - 0.025, 0.01), Vector3(0.44, 0.05, 0.42), seat)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_b(k, xf, Vector3(sx * 0.19, (sh - 0.05) * 0.5, sz * 0.18), Vector3(0.035, sh - 0.05, 0.035), wood)
	_b(k, xf, Vector3(0, 0.16, 0.18), Vector3(0.36, 0.025, 0.02), wood)
	_b(k, xf, Vector3(0, 0.16, -0.18), Vector3(0.36, 0.025, 0.02), wood)
	if back:
		for sx in [-1.0, 1.0]:
			_b(k, xf, Vector3(sx * 0.19, sh + 0.25, -0.19), Vector3(0.035, 0.5, 0.035), wood)
		_b(k, xf, Vector3(0, sh + 0.44, -0.19), Vector3(0.42, 0.1, 0.025), wood)
		_b(k, xf, Vector3(0, sh + 0.22, -0.19), Vector3(0.38, 0.04, 0.02), wood)
	if collide:
		_col(k, xf, Vector3(0, sh * 0.5, 0), Vector3(0.44, sh, 0.42), "wood")


## Floor lamp with a yellowed shade (two stacked boxes read as a taper).
static func lamp(k: GeoKit, xf: Transform3D, metal: String, shade: String, collide := true) -> void:
	_b(k, xf, Vector3(0, 0.02, 0), Vector3(0.3, 0.04, 0.3), metal)
	_b(k, xf, Vector3(0, 0.75, 0), Vector3(0.028, 1.42, 0.028), metal)
	_b(k, xf, Vector3(0, 1.42, 0), Vector3(0.40, 0.16, 0.40), shade)
	_b(k, xf, Vector3(0, 1.57, 0), Vector3(0.30, 0.14, 0.30), shade)
	if collide:
		_col(k, xf, Vector3(0, 0.8, 0), Vector3(0.3, 1.6, 0.3), "metal")


## Chest of drawers, fronts on local +Z.
static func drawers(k: GeoKit, xf: Transform3D, body: String, front: String, knob: String, w := 0.8, h := 0.9, rows := 3, collide := true) -> void:
	_b(k, xf, Vector3(0, h * 0.5 + 0.03, 0), Vector3(w, h - 0.06, 0.44), body)
	_b(k, xf, Vector3(0, 0.03, 0.01), Vector3(w - 0.06, 0.06, 0.4), knob)
	var rh := (h - 0.14) / rows
	for i in rows:
		var y := 0.1 + rh * (i + 0.5)
		_b(k, xf, Vector3(0, y, 0.228), Vector3(w - 0.08, rh - 0.035, 0.02), front)
		for sx in [-1.0, 1.0]:
			_b(k, xf, Vector3(sx * w * 0.22, y, 0.25), Vector3(0.05, 0.03, 0.03), knob)
	if collide:
		_col(k, xf, Vector3(0, h * 0.5, 0), Vector3(w, h, 0.46), "wood")


## A door leaf in pivot-local space: hinge at the origin, leaf along local -X
## (right-hand hinge), faces on +-Z. Opening rotates the pivot about Y.
static func leaf(k: GeoKit, paint: String, panel: String, knob: String) -> void:
	var w := DOOR_W - 0.04
	var h := DOOR_H - 0.02
	k.box(Vector3(-w * 0.5, h * 0.5 + 0.01, 0), Vector3(w, h, 0.045), paint)
	for sz in [-1.0, 1.0]:
		for row in [[0.52, 0.62], [1.42, 0.86]]:
			for col in [-0.23, 0.23]:
				k.box(Vector3(-w * 0.5 + col * w, row[0], sz * 0.025), Vector3(w * 0.34, row[1], 0.008), panel, GeoKit.ALL, false)
		k.box(Vector3(-w + 0.075, 1.0, sz * 0.045), Vector3(0.05, 0.05, 0.05), knob, GeoKit.ALL, false)
		k.box(Vector3(-w + 0.075, 1.0, sz * 0.027), Vector3(0.06, 0.14, 0.01), knob, GeoKit.ALL, false)


## Door frame (casing) around an opening centred at the wall plane of `xf`
## (local X along the wall, Z through it), wall thickness `t`.
static func frame(k: GeoKit, xf: Transform3D, t: float, trim: String) -> void:
	var hw := DOOR_W * 0.5
	for side in [-1.0, 1.0]:
		_b(k, xf, Vector3(side * (hw + 0.035), DOOR_H * 0.5, 0), Vector3(0.07, DOOR_H, t + 0.04), trim)
	_b(k, xf, Vector3(0, DOOR_H + 0.04, 0), Vector3(DOOR_W + 0.14, 0.08, t + 0.04), trim)
