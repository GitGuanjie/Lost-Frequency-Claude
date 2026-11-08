extends RefCounted
## Level 114 geometry: the childhood bedroom shell, the fused second room, the
## bed, the closet and the window. Everything that faces the void is matte
## black and unlit, so from the void only the lit doorway reads.

const T := 0.12          # wall thickness
const SKIN := "unlit_black"

var L: Node3D
var k: GeoKit
var W := 4.0
var D := 4.6
var H := 2.5
var hx := 2.0
var door_x := 1.0
var has_window := true
var frag := false
var frag_y := 0.36
var frag_z0 := 0.0
var frag_z1 := 0.0
var frag_w := 2.9
var closet_x0 := -0.2


func _init(level: Node3D, kit: GeoKit) -> void:
	L = level
	k = kit


static func materials(seed_v: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = hash([seed_v, "mats"])
	var beige := Color(0.70, 0.66, 0.58).lerp(Color(0.66, 0.66, 0.62), r.randf())
	MatLib.define("l114_wall", {"albedo_a": beige, "albedo_b": beige.darkened(0.06), "noise_scale": 3.0,
		"stain_amount": 0.32, "stain_color": Color(0.46, 0.43, 0.36), "stain_scale": 1.4,
		"grime_height": 0.25, "grime_color": Color(0.40, 0.37, 0.31), "bump_strength": 0.15,
		"roughness_a": 0.9, "roughness_b": 0.97}, "plaster")
	MatLib.define("l114_ceiling", {"albedo_a": Color(0.74, 0.73, 0.69), "albedo_b": Color(0.69, 0.68, 0.64),
		"stain_amount": 0.4, "stain_color": Color(0.50, 0.46, 0.36), "stain_scale": 0.9, "bump_strength": 0.3}, "plaster")
	MatLib.define("l114_carpet", {"albedo_a": Color(0.33, 0.33, 0.34), "albedo_b": Color(0.27, 0.27, 0.28),
		"pattern": 6, "pattern_scale": Vector2(0.12, 0.12), "pattern_strength": 0.12, "noise_scale": 9.0,
		"stain_amount": 0.25, "stain_color": Color(0.24, 0.22, 0.19), "stain_scale": 1.2, "bump_strength": 0.5,
		"roughness_a": 1.0, "roughness_b": 1.0})
	MatLib.define("l114_rug", {"albedo_a": Color(0.36, 0.30, 0.42), "albedo_b": Color(0.30, 0.25, 0.36),
		"pattern": 6, "pattern_scale": Vector2(0.3, 0.3), "pattern_color": Color(0.55, 0.48, 0.38),
		"pattern_strength": 0.35, "bump_strength": 0.4})
	MatLib.define("l114_trim", {"albedo_a": Color(0.80, 0.78, 0.72), "albedo_b": Color(0.74, 0.72, 0.66),
		"stain_amount": 0.2, "stain_color": Color(0.55, 0.5, 0.4)}, "trim_white")
	MatLib.define("l114_wood", {"albedo_a": Color(0.40, 0.27, 0.17), "albedo_b": Color(0.33, 0.22, 0.14),
		"pattern": 3, "pattern_scale": Vector2(0.12, 1.2)}, "wood_floor")
	# The bed: always the same single bed with a dark blue floral bedsheet.
	MatLib.define("l114_sheet", {"albedo_a": Color(0.07, 0.10, 0.24), "albedo_b": Color(0.09, 0.12, 0.28),
		"pattern": 10, "pattern_scale": Vector2(0.18, 0.18), "pattern_color": Color(0.30, 0.38, 0.62),
		"pattern_strength": 0.6, "noise_scale": 4.0, "bump_strength": 0.25, "roughness_a": 0.95, "roughness_b": 1.0,
		"stain_amount": 0.25, "stain_color": Color(0.12, 0.12, 0.14), "stain_scale": 2.0})
	MatLib.define("l114_mattress", {"albedo_a": Color(0.66, 0.63, 0.56), "albedo_b": Color(0.58, 0.55, 0.47),
		"pattern": 9, "pattern_scale": Vector2(0.15, 0.15), "pattern_strength": 0.06,
		"stain_amount": 0.45, "stain_color": Color(0.48, 0.40, 0.26), "stain_scale": 2.5})
	MatLib.define("l114_frag_wall", {"albedo_a": Color(0.62, 0.66, 0.55), "albedo_b": Color(0.56, 0.60, 0.50),
		"pattern": 2, "pattern_scale": Vector2(0.09, 1.0), "pattern_color": Color(0.70, 0.66, 0.50),
		"pattern_strength": 0.35, "stain_amount": 0.35, "stain_color": Color(0.42, 0.40, 0.30),
		"grime_height": 0.3, "grime_color": Color(0.36, 0.34, 0.27)}, "plaster")
	MatLib.define("l114_frag_floor", {"albedo_a": Color(0.42, 0.31, 0.21), "albedo_b": Color(0.36, 0.26, 0.17),
		"stain_amount": 0.2}, "wood_floor")
	MatLib.define("l114_metal", {"albedo_a": Color(0.6, 0.6, 0.6), "albedo_b": Color(0.5, 0.5, 0.5),
		"metallic_value": 0.7, "roughness_a": 0.4, "roughness_b": 0.55}, "metal")
	MatLib.register("l114_lamp_panel", MatLib.panel(Color(0.86, 0.93, 1.0), 1.7))
	MatLib.register("l114_glass", MatLib.standard(Color(0.05, 0.06, 0.08), 0.08, 0.3, Color(0.03, 0.04, 0.06), 0.4))
	MatLib.register("l114_rope", MatLib.standard(Color(0.55, 0.46, 0.30), 0.95))
	MatLib.register("l114_cloth_a", MatLib.standard(Color(0.35, 0.18, 0.22), 1.0))
	MatLib.register("l114_cloth_b", MatLib.standard(Color(0.22, 0.30, 0.40), 1.0))
	MatLib.register("l114_cloth_c", MatLib.standard(Color(0.62, 0.58, 0.48), 1.0))
	MatLib.register("l114_plastic", MatLib.standard(Color(0.86, 0.84, 0.78), 0.5))
	MatLib.register("l114_poster", MatLib.standard(Color(0.55, 0.52, 0.46), 0.9))


## A wall slab whose room-facing faces use `mat` and whose void-facing face is black.
func solid(c: Vector3, s: Vector3, mat: String, outer: int) -> void:
	k.box(c, s, mat, GeoKit.ALL & ~outer, true)
	k.box(c, s, SKIN, outer, false)


## Axis wall with rectangular holes. axis "x": runs along x at depth z0..z1.
## holes: [[s0, s1, y0, y1]] in the wall's running coordinate.
func wall(axis: String, a0: float, a1: float, d0: float, d1: float, y0: float, y1: float, holes: Array, mat: String, outer: int) -> void:
	var cursor := a0
	var sorted := holes.duplicate()
	sorted.sort_custom(func(p, q): return p[0] < q[0])
	for h in sorted:
		if h[0] > cursor + 0.001:
			_piece(axis, cursor, h[0], d0, d1, y0, y1, mat, outer)
		if h[2] > y0 + 0.001:
			_piece(axis, h[0], h[1], d0, d1, y0, h[2], mat, outer)
		if h[3] < y1 - 0.001:
			_piece(axis, h[0], h[1], d0, d1, h[3], y1, mat, outer)
		cursor = h[1]
	if cursor < a1 - 0.001:
		_piece(axis, cursor, a1, d0, d1, y0, y1, mat, outer)


func _piece(axis: String, s0: float, s1: float, d0: float, d1: float, y0: float, y1: float, mat: String, outer: int) -> void:
	if axis == "x":
		solid(Vector3((s0 + s1) * 0.5, (y0 + y1) * 0.5, (d0 + d1) * 0.5), Vector3(s1 - s0, y1 - y0, d1 - d0), mat, outer)
	else:
		solid(Vector3((d0 + d1) * 0.5, (y0 + y1) * 0.5, (s0 + s1) * 0.5), Vector3(d1 - d0, y1 - y0, s1 - s0), mat, outer)


func plan(r: RandomNumberGenerator) -> void:
	W = snappedf(r.randf_range(3.7, 4.4), 0.05)
	D = snappedf(r.randf_range(4.4, 5.1), 0.05)
	H = snappedf(r.randf_range(2.42, 2.56), 0.02)
	hx = W * 0.5
	door_x = hx - 1.0
	has_window = r.randf() < 0.6
	frag = r.randf() < 0.7
	frag_y = [0.36, 0.54, -0.36][r.randi() % 3]
	frag_z0 = -D + 1.75
	frag_z1 = frag_z0 + 1.5
	frag_w = snappedf(r.randf_range(2.7, 3.3), 0.05)
	closet_x0 = snappedf(r.randf_range(-0.45, -0.1), 0.05)


func shell() -> void:
	# floor (carpet) and its black underside
	k.box(Vector3(0, -0.1, -D * 0.5 + T * 0.5), Vector3(W + T * 2, 0.2, D + T), "l114_carpet", GeoKit.PY, true)
	k.box(Vector3(0, -0.1, -D * 0.5 + T * 0.5), Vector3(W + T * 2, 0.2, D + T), SKIN, GeoKit.ALL & ~GeoKit.PY, false)
	# ceiling
	k.box(Vector3(0, H + 0.06, -D * 0.5), Vector3(W + T * 2, 0.12, D + T * 2), "l114_ceiling", GeoKit.NY, false)
	k.box(Vector3(0, H + 0.06, -D * 0.5), Vector3(W + T * 2, 0.12, D + T * 2), SKIN, GeoKit.ALL & ~GeoKit.NY, false)
	# south wall with the doorway onto the void
	wall("x", -hx - T, hx + T, 0.0, T, 0.0, H, [[door_x - 0.45, door_x + 0.45, 0.0, 2.05]], "l114_wall", GeoKit.PZ)
	# north wall with the closet opening
	wall("x", -hx - T, hx + T, -D - T, -D, 0.0, H, [[closet_x0, closet_x0 + 1.6, 0.0, 2.1]], "l114_wall", GeoKit.NZ)
	# west wall with the optional window above the bed
	var wz := -D + 1.15
	wall("z", -D, 0.0, -hx - T, -hx, 0.0, H, [[wz - 0.5, wz + 0.5, 1.05, 2.05]] if has_window else [], "l114_wall", GeoKit.NX)
	# east wall with the optional opening into a fused second room
	wall("z", -D, 0.0, hx, hx + T, 0.0, H, [[frag_z0, frag_z1, 0.0, minf(2.15 + maxf(frag_y, 0.0), frag_y + 2.36)]] if frag else [], "l114_wall", GeoKit.PX)
	# skirting, door casing, light-switch plate, outlets
	for seg in [[Vector3(0, 0.05, -D + 0.01), Vector3(W, 0.1, 0.02)], [Vector3(-hx + 0.01, 0.05, -D * 0.5), Vector3(0.02, 0.1, D)]]:
		k.box(seg[0], seg[1], "l114_trim", GeoKit.ALL, false)
	for x0x1 in [[-hx, door_x - 0.5], [door_x + 0.5, hx]]:
		k.box(Vector3((x0x1[0] + x0x1[1]) * 0.5, 0.05, -0.01), Vector3(x0x1[1] - x0x1[0], 0.1, 0.02), "l114_trim", GeoKit.ALL, false)
	for sx in [-1.0, 1.0]:
		k.box(Vector3(door_x + sx * 0.49, 1.05, -0.015), Vector3(0.07, 2.1, 0.03), "l114_trim", GeoKit.ALL, false)
	k.box(Vector3(door_x, 2.09, -0.015), Vector3(1.05, 0.08, 0.03), "l114_trim", GeoKit.ALL, false)
	k.box(Vector3(door_x - 0.75, 1.2, -0.008), Vector3(0.08, 0.12, 0.016), "l114_plastic", GeoKit.ALL, false)
	for p in [Vector3(-hx + 0.006, 0.3, -D + 2.6), Vector3(hx - 0.006, 0.3, -D + 0.3), Vector3(0.6, 0.3, -0.006)]:
		var sz := Vector3(0.012, 0.11, 0.07) if absf(p.x) > hx - 0.1 else Vector3(0.07, 0.11, 0.012)
		k.box(p, sz, "l114_plastic", GeoKit.ALL, false)
	# ceiling fixture: a flat sterile dome
	k.cylinder(Vector3(0, H - 0.03, -D * 0.5), 0.2, 0.05, "l114_plastic", 18, false)
	k.cylinder(Vector3(0, H - 0.07, -D * 0.5), 0.16, 0.04, "l114_lamp_panel", 18, false)
	if has_window:
		_window(wz)


func _window(wz: float) -> void:
	var x := -hx
	k.box(Vector3(x + 0.07, 1.04, wz), Vector3(0.16, 0.05, 1.1), "l114_trim", GeoKit.ALL, false)
	for dz in [-0.52, 0.52]:
		k.box(Vector3(x + 0.03, 1.55, wz + dz), Vector3(0.06, 1.04, 0.05), "l114_trim", GeoKit.ALL, false)
	k.box(Vector3(x + 0.03, 2.07, wz), Vector3(0.06, 0.05, 1.1), "l114_trim", GeoKit.ALL, false)
	k.box(Vector3(x - 0.04, 1.55, wz), Vector3(0.03, 0.06, 1.0), "l114_trim", GeoKit.ALL, false)
	k.box(Vector3(x - 0.04, 1.55, wz), Vector3(0.03, 1.0, 0.04), "l114_trim", GeoKit.ALL, false)
	# curtain rod and two limp curtains
	k.box(Vector3(x + 0.12, 2.18, wz), Vector3(0.02, 0.02, 1.5), "l114_metal", GeoKit.ALL, false)


## The fused second room: same dim light, other wallpaper and floor, another height.
func fragment() -> void:
	if not frag:
		return
	var y := frag_y
	var x0 := hx + T
	var x1 := x0 + frag_w
	var z0 := frag_z0 - 1.1
	var z1 := frag_z1 + 0.7
	var top := y + 2.38
	k.box(Vector3((x0 + x1) * 0.5, y - 0.1, (z0 + z1) * 0.5), Vector3(x1 - x0, 0.2, z1 - z0), "l114_frag_floor", GeoKit.PY | GeoKit.NX, true)
	k.box(Vector3((x0 + x1) * 0.5, y - 0.1, (z0 + z1) * 0.5), Vector3(x1 - x0, 0.2, z1 - z0), SKIN, GeoKit.ALL & ~(GeoKit.PY | GeoKit.NX), false)
	k.box(Vector3((x0 + x1) * 0.5, top + 0.06, (z0 + z1) * 0.5), Vector3(x1 - x0 + T * 2, 0.12, z1 - z0 + T * 2), "l114_ceiling", GeoKit.ALL & ~GeoKit.PY, false)
	k.box(Vector3((x0 + x1) * 0.5, top + 0.06, (z0 + z1) * 0.5), Vector3(x1 - x0 + T * 2, 0.12, z1 - z0 + T * 2), SKIN, GeoKit.PY, false)
	# the back of the old room's wall, seen from inside the fused room, wears this room's paper
	var oy1 := minf(2.15 + maxf(y, 0.0), top)
	var fx := x0 + 0.003
	for pc in [[z0, frag_z0, y, top], [frag_z1, z1, y, top], [frag_z0, frag_z1, oy1, top], [frag_z0, frag_z1, y, 0.0]]:
		if pc[1] - pc[0] > 0.01 and pc[3] - pc[2] > 0.01:
			k.box(Vector3(fx, (pc[2] + pc[3]) * 0.5, (pc[0] + pc[1]) * 0.5), Vector3(0.004, pc[3] - pc[2], pc[1] - pc[0]), "l114_frag_wall", GeoKit.PX, false)
	var lo := minf(y, 0.0) - 0.2
	wall("x", x0, x1 + T, z0 - T, z0, lo, top, [], "l114_frag_wall", GeoKit.NZ)
	wall("x", x0, x1 + T, z1, z1 + T, lo, top, [], "l114_frag_wall", GeoKit.PZ)
	wall("z", z0 - T, z1 + T, x1, x1 + T, lo, top, [], "l114_frag_wall", GeoKit.PX)
	# Where the two rooms overlap, the old room's wall face shows through the new one.
	k.box(Vector3(x0 - 0.002 - T * 0.5, (y + top) * 0.5, z0 - 0.5), Vector3(T, top - y, 1.0), "l114_frag_wall", GeoKit.ALL, false)
	if y < 0.0:
		# sunken: the gap under the main room's wall reads as a ragged lip
		k.box(Vector3(hx + T * 0.5, y * 0.5, (frag_z0 + frag_z1) * 0.5), Vector3(T, -y, frag_z1 - frag_z0), "l114_frag_wall", GeoKit.ALL, true)
	# steps through the opening
	var zm := (frag_z0 + frag_z1) * 0.5
	if y > 0.0:
		var n := int(round(y / 0.18))
		k.stairs(Vector3(hx - 0.28 * n + 0.05, 0.0, zm), Vector3(1, 0, 0), frag_z1 - frag_z0 - 0.06, 0.18, n, "l114_frag_floor")
	else:
		k.stairs(Vector3(x0 + 0.28 * 2 + 0.02, y, zm), Vector3(-1, 0, 0), frag_z1 - frag_z0 - 0.06, 0.18, 2, "l114_frag_floor")
	# a protruding stub of the other room's wall, cutting into this one at an odd angle
	var stub := Transform3D(Basis(Vector3.UP, deg_to_rad(9.0)), Vector3(hx - 0.32, H * 0.5, frag_z0 - 0.08))
	k.box_xf(stub, Vector3(0.62, H, T), "l114_frag_wall")
	k.box(Vector3((x0 + x1) * 0.5, top - 0.03, (z0 + z1) * 0.5), Vector3(0.3, 0.05, 0.3), "l114_plastic", GeoKit.ALL, false)
	k.cylinder(Vector3((x0 + x1) * 0.5, top - 0.07, (z0 + z1) * 0.5), 0.14, 0.04, "l114_lamp_panel", 18, false)


## The single bed: a mattress fitted snugly to a wooden frame, blue floral sheet.
func bed() -> Array:
	var x0 := -hx
	var x1 := -hx + 1.0
	var z0 := -D + 0.03
	var z1 := z0 + 2.02
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	# collision as one block (frame + mattress), visuals in parts; the dark gap stays open
	k.add_box_shape(Transform3D(Basis(), Vector3(cx, 0.29, cz)), Vector3(1.0, 0.58, 2.02), "plush")
	for lx in [x0 + 0.04, x1 - 0.04]:
		for lz in [z0 + 0.04, z1 - 0.04]:
			k.box(Vector3(lx, 0.14, lz), Vector3(0.06, 0.28, 0.06), "l114_wood", GeoKit.ALL, false)
	for sz in [z0 + 0.02, z1 - 0.02]:
		k.box(Vector3(cx, 0.3, sz), Vector3(1.0, 0.12, 0.04), "l114_wood", GeoKit.ALL, false)
	for sx in [x0 + 0.02, x1 - 0.02]:
		k.box(Vector3(sx, 0.3, cz), Vector3(0.04, 0.12, 2.02), "l114_wood", GeoKit.ALL, false)
	k.box(Vector3(cx, 0.62, z0 + 0.02), Vector3(1.0, 0.5, 0.05), "l114_wood", GeoKit.ALL, false)
	k.box(Vector3(cx, 0.32, cz), Vector3(0.94, 0.04, 1.96), "l114_wood", GeoKit.ALL, false)
	k.box(Vector3(cx, 0.43, cz), Vector3(0.92, 0.18, 1.94), "l114_mattress", GeoKit.ALL, false)
	# the sheet hangs over the mattress edge on the room side
	k.box(Vector3(cx + 0.01, 0.53, cz + 0.12), Vector3(0.98, 0.035, 1.66), "l114_sheet", GeoKit.ALL, false)
	k.box(Vector3(x1 + 0.005, 0.42, cz + 0.12), Vector3(0.012, 0.24, 1.66), "l114_sheet", GeoKit.ALL, false)
	k.box(Vector3(cx + 0.01, 0.43, z1 + 0.005), Vector3(0.98, 0.22, 0.012), "l114_sheet", GeoKit.ALL, false)
	# fold-back and pillow
	k.box(Vector3(cx + 0.01, 0.565, z0 + 0.62), Vector3(0.98, 0.04, 0.22), "l114_sheet", GeoKit.ALL, false)
	k.box(Vector3(cx, 0.6, z0 + 0.3), Vector3(0.62, 0.12, 0.36), "l114_mattress", GeoKit.ALL, false)
	return [Vector3(cx, 0.0, cz), x1, z0, z1]


## Closet behind the north wall: white sliding doors, one pushed aside to a dark gap.
func closet(r: RandomNumberGenerator) -> Vector3:
	var x0 := closet_x0
	var x1 := x0 + 1.6
	var zb := -D - T - 0.62
	k.box(Vector3((x0 + x1) * 0.5, -0.05, (zb - D - T) * 0.5), Vector3(1.6, 0.1, -D - T - zb), "l114_carpet", GeoKit.PY, true)
	solid(Vector3((x0 + x1) * 0.5, 1.2, zb - 0.06), Vector3(1.8, 2.4, 0.12), "l114_wall", GeoKit.NZ)
	for sx in [x0 - 0.06, x1 + 0.06]:
		solid(Vector3(sx, 1.2, (zb - D - T) * 0.5), Vector3(0.12, 2.4, -D - T - zb), "l114_wall", GeoKit.PX if sx > x0 else GeoKit.NX)
	solid(Vector3((x0 + x1) * 0.5, 2.15, (zb - D - T) * 0.5), Vector3(1.8, 0.1, -D - T - zb), "l114_wall", GeoKit.PY)
	k.box(Vector3((x0 + x1) * 0.5, 2.06, -D - 0.04), Vector3(1.6, 0.08, 0.08), "l114_trim", GeoKit.ALL, false)
	# rod with hanging clothes, boxes on the floor
	k.box(Vector3((x0 + x1) * 0.5, 1.75, zb + 0.3), Vector3(1.5, 0.02, 0.02), "l114_metal", GeoKit.ALL, false)
	var mats := ["l114_cloth_a", "l114_cloth_b", "l114_cloth_c"]
	var x := x0 + 0.12
	while x < x1 - 0.12:
		var len := r.randf_range(0.55, 0.95)
		k.box(Vector3(x, 1.72 - len * 0.5, zb + 0.3), Vector3(0.05, len, 0.42), mats[r.randi() % 3], GeoKit.ALL, false)
		x += r.randf_range(0.07, 0.13)
	# sliding doors: A fully left, B overlapping, leaving a dark gap at the right end
	k.box(Vector3(x0 + 0.42, 1.03, -D - 0.05), Vector3(0.82, 2.04, 0.035), "l114_trim")
	k.box(Vector3(x0 + 0.86, 1.03, -D - 0.1), Vector3(0.82, 2.04, 0.035), "l114_trim")
	k.box(Vector3(x0 + 0.28, 1.0, -D - 0.028), Vector3(0.12, 0.02, 0.01), "l114_metal", GeoKit.ALL, false)
	return Vector3(x1 - 0.18, 1.05, -D - 0.4)


## The door leaf in the hinge's local frame (pivot at the hinge, closed along -x).
## Returns the outer knob in local coordinates; the rope is tied there.
static func door_leaf(dk: GeoKit) -> Vector3:
	dk.box(Vector3(-0.42, 1.02, 0.02), Vector3(0.84, 2.02, 0.04), "l114_trim", GeoKit.ALL, false)
	for pz in [0.045, -0.005]:
		dk.box(Vector3(-0.42, 0.55, pz), Vector3(0.6, 0.6, 0.012), "l114_trim", GeoKit.ALL, false)
		dk.box(Vector3(-0.42, 1.45, pz), Vector3(0.6, 0.7, 0.012), "l114_trim", GeoKit.ALL, false)
	var knob_out := Vector3(-0.76, 0.95, 0.08)
	dk.cylinder(knob_out, 0.03, 0.05, "l114_metal", 10, false)
	dk.cylinder(Vector3(-0.76, 0.95, -0.04), 0.03, 0.05, "l114_metal", 10, false)
	dk.box(knob_out + Vector3(0, -0.02, 0.02), Vector3(0.07, 0.05, 0.07), "l114_rope", GeoKit.ALL, false)
	dk.cylinder(Vector3(knob_out.x, (knob_out.y - 137.0) * 0.5, knob_out.z + 0.03), 0.018, knob_out.y + 137.0, "l114_rope", 6, false)
	return knob_out
