extends RefCounted
## Level 90 house: a freshly renovated two-storey family house with a big
## attic. Footprint x -7..7, z 0..11 (front faces -Z). Ground floor (F0): hall
## with the stair (and the painted-shut door under it), living room (west
## front), open kitchen and dining (west back), laundry and bathroom 1 (east
## front), a den still mid-paint (east back). First floor (F1): bedroom 1 and
## bathroom 2 (west), bedroom 2 and a bonus room with the attic stair (east),
## a landing round the stair void. Attic (A): under a 40 degree gable roof,
## the broken air conditioner, ducts, insulation and old rat traps.

const X0 := -7.0
const X1 := 7.0
const Z0 := 0.0
const Z1 := 11.0
const F0 := 0.45
const F1 := 3.45
const C1 := 6.15
const A := 6.27
const HX0 := -1.0           # hall west wall
const HX1 := 1.6            # hall east wall
const SX0 := 0.5            # main stair x range
const SX1 := 1.5
const SZ0 := 1.6            # main stair foot (rises toward +Z)
const S_STEPS := 16
const S_RUN := 0.28
const AX0 := 2.4            # attic stair foot (rises toward +X)
const AZ0 := 5.68           # attic stair z range
const AZ1 := 6.48
const A_STEPS := 14
const A_RUN := 0.24
const PITCH := 40.0
const RIDGE_Z := 5.5
const KS := 2.05            # Kenney furniture-kit scale to real size

var lvl
var anchors := {}
var lights: Array = []      # [pos, color, energy, range, storey]
var lamp_nodes: Array = []


func _init(level) -> void:
	lvl = level


static func stair_top_z() -> float:
	return SZ0 + S_STEPS * S_RUN


static func attic_top_x() -> float:
	return AX0 + A_STEPS * A_RUN


## Height of the underside of the roof above a point (attic headroom).
static func roof_y(z: float) -> float:
	return A + (RIDGE_Z - absf(z - RIDGE_Z)) * tan(deg_to_rad(PITCH))


func build(node: Node3D) -> void:
	var k := GeoKit.new(node, "House")
	var g := GeoKit.new(node, "HouseGlass")
	_floors(k)
	_exterior(k, g)
	_interior(k)
	_stairs(k)
	_porch_and_deck(k)
	_roof(k, node)
	_attic(k)
	k.commit()
	g.commit()
	for c in g.root.get_children():
		if c is MeshInstance3D:
			(c as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_furnish(node)


# ---------------------------------------------------------------- shell

func _floors(k: GeoKit) -> void:
	k.box_mm(Vector3(X0 - 0.12, 0.0, Z0 - 0.12), Vector3(X1 + 0.12, F0 - 0.03, Z1 + 0.12), "l90_brick")
	k.slab(X0, Z0, X1, Z1, F0, 0.03, "l90_wood")
	# tiled wet rooms and kitchen on the ground floor
	k.slab(X0 + 0.06, 5.66, HX0 - 0.06, Z1 - 0.06, F0 + 0.004, 0.01, "l90_tile_floor", GeoKit.PY)
	k.slab(HX1 + 0.06, Z0 + 0.06, X1 - 0.06, 3.74, F0 + 0.004, 0.01, "l90_tile_floor", GeoKit.PY)
	# first-floor slab with the stair void (ceiling below, boards above)
	var tz := stair_top_z()
	for r in [[X0, Z0, SX0, Z1], [SX0, Z0, X1, SZ0], [SX0, tz, X1, Z1], [SX1, SZ0, X1, tz]]:
		_slab2(k, r, F1 - 0.2, F1, "l90_wood", "l90_ceiling")
	k.slab(X0 + 0.06, 7.66, HX0 - 0.06, Z1 - 0.06, F1 + 0.004, 0.01, "l90_tile_floor", GeoKit.PY)
	# attic floor (= first-floor ceiling) with the attic-stair void
	var ax := attic_top_x()
	for r in [[X0, Z0, X1, AZ0], [X0, AZ1, X1, Z1], [X0, AZ0, AX0, AZ1], [ax, AZ0, X1, AZ1]]:
		_slab2(k, r, C1, A, "l90_attic_floor", "l90_ceiling")


## A floor slab piece: boards on top and sides, painted ceiling underneath.
func _slab2(k: GeoKit, r: Array, y0: float, y1: float, top: String, under: String) -> void:
	var mn := Vector3(r[0], y0, r[1])
	var mx := Vector3(r[2], y1, r[3])
	k.box_mm(mn, mx, top, GeoKit.PY | GeoKit.SIDES, true)
	k.box_mm(mn, Vector3(mx.x, y0 + 0.001, mx.z), under, GeoKit.NY, false)


func _ext_wall(k: GeoKit, a: Vector3, b: Vector3, hh: float, ops: Array, inward: Vector3, inner: String = "l90_paint") -> void:
	k.wall(a - inward * 0.06, b - inward * 0.06, hh, 0.12, "l90_stucco", ops)
	k.wall(a + inward * 0.05, b + inward * 0.05, hh, 0.1, inner, ops)


func _exterior(k: GeoKit, g: GeoKit) -> void:
	var h0 := F1 - F0
	var h1 := C1 - F1
	var W := 1.2
	# front (z = 0), positions measured from x = X0
	_ext_wall(k, Vector3(X0, F0, Z0), Vector3(X1, F0, Z0), h0, [
		{"at": 1.8, "w": W, "h": 1.5, "sill": 0.8}, {"at": 4.4, "w": W, "h": 1.5, "sill": 0.8},
		{"at": 6.78, "w": 1.0, "h": 2.2, "sill": 0.0}, {"at": 9.75, "w": 0.8, "h": 0.9, "sill": 1.35},
		{"at": 12.45, "w": 0.8, "h": 0.9, "sill": 1.35}], Vector3(0, 0, 1))
	_ext_wall(k, Vector3(X0, F1, Z0), Vector3(X1, F1, Z0), h1, [
		{"at": 1.8, "w": W, "h": 1.4, "sill": 0.85}, {"at": 4.4, "w": W, "h": 1.4, "sill": 0.85},
		{"at": 6.78, "w": 0.9, "h": 1.3, "sill": 0.9}, {"at": 10.0, "w": W, "h": 1.4, "sill": 0.85},
		{"at": 12.6, "w": W, "h": 1.4, "sill": 0.85}], Vector3(0, 0, 1))
	# back (z = 11)
	_ext_wall(k, Vector3(X0, F0, Z1), Vector3(X1, F0, Z1), h0, [
		{"at": 1.6, "w": 1.4, "h": 1.1, "sill": 1.1}, {"at": 4.4, "w": 1.8, "h": 2.25, "sill": 0.0},
		{"at": 7.3, "w": 0.8, "h": 1.3, "sill": 0.9}, {"at": 10.5, "w": W, "h": 1.5, "sill": 0.8},
		{"at": 12.8, "w": W, "h": 1.5, "sill": 0.8}], Vector3(0, 0, -1))
	_ext_wall(k, Vector3(X0, F1, Z1), Vector3(X1, F1, Z1), h1, [
		{"at": 3.0, "w": 0.9, "h": 1.0, "sill": 1.3}, {"at": 7.3, "w": 0.8, "h": 1.3, "sill": 0.9},
		{"at": 12.2, "w": W, "h": 1.4, "sill": 0.85}], Vector3(0, 0, -1))
	# west (x = -7)
	_ext_wall(k, Vector3(X0, F0, Z0), Vector3(X0, F0, Z1), h0, [
		{"at": 2.8, "w": W, "h": 1.5, "sill": 0.8}, {"at": 8.3, "w": W, "h": 1.2, "sill": 1.0}], Vector3(1, 0, 0))
	_ext_wall(k, Vector3(X0, F1, Z0), Vector3(X0, F1, Z1), h1, [
		{"at": 3.6, "w": W, "h": 1.4, "sill": 0.85}, {"at": 9.3, "w": 0.7, "h": 0.9, "sill": 1.4}], Vector3(1, 0, 0))
	# east (x = 7)
	_ext_wall(k, Vector3(X1, F0, Z0), Vector3(X1, F0, Z1), h0, [
		{"at": 1.9, "w": 0.7, "h": 0.9, "sill": 1.4}, {"at": 7.4, "w": W, "h": 1.5, "sill": 0.8}], Vector3(-1, 0, 0))
	_ext_wall(k, Vector3(X1, F1, Z0), Vector3(X1, F1, Z1), h1, [
		{"at": 2.8, "w": W, "h": 1.4, "sill": 0.85}, {"at": 8.3, "w": W, "h": 1.4, "sill": 0.85}], Vector3(-1, 0, 0))
	# band course between the storeys and a brick plinth
	for s in [[Vector3(0, F1 - 0.1, Z0 - 0.14), Vector3(14.3, 0.18, 0.06)], [Vector3(0, F1 - 0.1, Z1 + 0.14), Vector3(14.3, 0.18, 0.06)],
			[Vector3(X0 - 0.14, F1 - 0.1, 5.5), Vector3(0.06, 0.18, 11.3)], [Vector3(X1 + 0.14, F1 - 0.1, 5.5), Vector3(0.06, 0.18, 11.3)]]:
		k.box(s[0], s[1], "l90_trim", GeoKit.ALL, false)
	# windows: [x or z, storey floor y, width, height, sill]
	for w in [[-5.2, F0, W, 1.5, 0.8], [-2.6, F0, W, 1.5, 0.8], [2.75, F0, 0.8, 0.9, 1.35], [5.45, F0, 0.8, 0.9, 1.35],
			[-5.2, F1, W, 1.4, 0.85], [-2.6, F1, W, 1.4, 0.85], [-0.22, F1, 0.9, 1.3, 0.9], [3.0, F1, W, 1.4, 0.85], [5.6, F1, W, 1.4, 0.85]]:
		_window(k, g, Vector3(w[0], w[1] + w[4] + w[3] * 0.5, Z0), w[2], w[3], true, -1.0)
	for w in [[-5.4, F0, 1.4, 1.1, 1.1], [0.3, F0, 0.8, 1.3, 0.9], [3.5, F0, W, 1.5, 0.8], [5.8, F0, W, 1.5, 0.8],
			[-4.0, F1, 0.9, 1.0, 1.3], [0.3, F1, 0.8, 1.3, 0.9], [5.2, F1, W, 1.4, 0.85]]:
		_window(k, g, Vector3(w[0], w[1] + w[4] + w[3] * 0.5, Z1), w[2], w[3], true, 1.0)
	for w in [[X0, F0, 2.8, W, 1.5, 0.8], [X0, F0, 8.3, W, 1.2, 1.0], [X0, F1, 3.6, W, 1.4, 0.85], [X0, F1, 9.3, 0.7, 0.9, 1.4],
			[X1, F0, 1.9, 0.7, 0.9, 1.4], [X1, F0, 7.4, W, 1.5, 0.8], [X1, F1, 2.8, W, 1.4, 0.85], [X1, F1, 8.3, W, 1.4, 0.85]]:
		_window(k, g, Vector3(w[0], w[1] + w[5] + w[4] * 0.5, w[2]), w[3], w[4], false, -1.0 if w[0] < 0.0 else 1.0)
	# the patio slider: one fixed pane, the other slid open
	g.box(Vector3(-3.05, F0 + 1.12, Z1 + 0.02), Vector3(0.88, 2.2, 0.02), "l90_glass")
	k.box(Vector3(-3.05, F0 + 1.12, Z1 + 0.02), Vector3(0.05, 2.2, 0.08), "l90_frame", GeoKit.ALL, false)
	_door_frame(k, Vector3(-2.6, F0, Z1), 1.8, 2.25, true)
	# front door, standing open into the hall
	_door_frame(k, Vector3(-0.22, F0, Z0), 1.0, 2.2, true)
	k.box(Vector3(-0.68, F0 + 1.1, 0.55), Vector3(0.05, 2.18, 0.92), "l90_door_front", GeoKit.ALL, false)


func _window(k: GeoKit, g: GeoKit, c: Vector3, w: float, hh: float, along_x: bool, out_sign: float) -> void:
	if along_x:
		g.box(c, Vector3(w, hh, 0.02), "l90_glass")
		k.box(c, Vector3(0.04, hh, 0.07), "l90_frame", GeoKit.ALL, false)
		k.box(c, Vector3(w, 0.04, 0.07), "l90_frame", GeoKit.ALL, false)
		for s in [-1.0, 1.0]:
			k.box(c + Vector3(s * (w * 0.5 + 0.04), 0, 0), Vector3(0.09, hh + 0.16, 0.3), "l90_trim", GeoKit.ALL, false)
		k.box(c + Vector3(0, hh * 0.5 + 0.06, 0), Vector3(w + 0.26, 0.12, 0.3), "l90_trim", GeoKit.ALL, false)
		k.box(c + Vector3(0, -hh * 0.5 - 0.04, out_sign * 0.08), Vector3(w + 0.3, 0.06, 0.36), "l90_trim", GeoKit.ALL, false)
		# shutters outside, for the curb appeal
		for s in [-1.0, 1.0]:
			k.box(c + Vector3(s * (w * 0.5 + 0.38), 0, out_sign * 0.2), Vector3(0.5, hh + 0.1, 0.04), "l90_shutter", GeoKit.ALL, false)
	else:
		g.box(c, Vector3(0.02, hh, w), "l90_glass")
		k.box(c, Vector3(0.07, hh, 0.04), "l90_frame", GeoKit.ALL, false)
		k.box(c, Vector3(0.07, 0.04, w), "l90_frame", GeoKit.ALL, false)
		for s in [-1.0, 1.0]:
			k.box(c + Vector3(0, 0, s * (w * 0.5 + 0.04)), Vector3(0.3, hh + 0.16, 0.09), "l90_trim", GeoKit.ALL, false)
		k.box(c + Vector3(0, hh * 0.5 + 0.06, 0), Vector3(0.3, 0.12, w + 0.26), "l90_trim", GeoKit.ALL, false)
		k.box(c + Vector3(out_sign * 0.08, -hh * 0.5 - 0.04, 0), Vector3(0.36, 0.06, w + 0.3), "l90_trim", GeoKit.ALL, false)


func _door_frame(k: GeoKit, base: Vector3, w: float, hh: float, along_x: bool) -> void:
	var d := 0.3
	if along_x:
		for s in [-1.0, 1.0]:
			k.box(base + Vector3(s * (w * 0.5 + 0.04), hh * 0.5, 0), Vector3(0.08, hh, d), "l90_trim", GeoKit.ALL, false)
		k.box(base + Vector3(0, hh + 0.05, 0), Vector3(w + 0.16, 0.1, d), "l90_trim", GeoKit.ALL, false)
	else:
		for s in [-1.0, 1.0]:
			k.box(base + Vector3(0, hh * 0.5, s * (w * 0.5 + 0.04)), Vector3(d, hh, 0.08), "l90_trim", GeoKit.ALL, false)
		k.box(base + Vector3(0, hh + 0.05, 0), Vector3(d, 0.1, w + 0.16), "l90_trim", GeoKit.ALL, false)


## An interior door leaf swung back against the wall beside its opening.
func _leaf(k: GeoKit, hinge: Vector3, along_z: bool, w: float, sgn: float = 1.0) -> void:
	var sz := Vector3(0.04, 2.06, w * 0.95) if along_z else Vector3(w * 0.95, 2.06, 0.04)
	var off := Vector3(0, 0, w * 0.48 * sgn) if along_z else Vector3(w * 0.48 * sgn, 0, 0)
	k.box(hinge + off + Vector3(0, 1.03, 0), sz, "l90_door", GeoKit.ALL, false)


# ---------------------------------------------------------------- interior

func _interior(k: GeoKit) -> void:
	var h0 := F1 - F0 - 0.2
	var h1 := C1 - F1
	# ground floor -----------------------------------------------------
	k.wall(Vector3(HX0, F0, Z0 + 0.12), Vector3(HX0, F0, Z1 - 0.12), h0, 0.12, "l90_paint", [
		{"at": 2.5, "w": 1.6, "h": 2.2}, {"at": 8.3, "w": 2.0, "h": 2.2}])
	k.wall(Vector3(HX1, F0, Z0 + 0.12), Vector3(HX1, F0, Z1 - 0.12), h0, 0.12, "l90_paint", [
		{"at": 0.85, "w": 0.9, "h": 2.1}, {"at": 8.1, "w": 1.8, "h": 2.2}])
	k.wall(Vector3(X0 + 0.11, F0, 5.6), Vector3(HX0 - 0.06, F0, 5.6), h0, 0.12, "l90_paint", [{"at": 2.9, "w": 2.6, "h": 2.3}])
	k.wall(Vector3(HX1 + 0.06, F0, 3.8), Vector3(X1 - 0.11, F0, 3.8), h0, 0.12, "l90_paint", [{"at": 3.8, "w": 0.85, "h": 2.1}])
	k.wall(Vector3(3.9, F0, Z0 + 0.12), Vector3(3.9, F0, 3.74), h0, 0.12, "l90_tile_wall")
	# bathroom 1 tiles to 1.4 m on its inner faces
	k.box_mm(Vector3(3.97, F0, 0.12), Vector3(3.99, F0 + 1.4, 3.73), "l90_tile_wall", GeoKit.PX, false)
	k.box_mm(Vector3(3.96, F0, 3.73), Vector3(6.88, F0 + 1.4, 3.74), "l90_tile_wall", GeoKit.NZ, false)
	_leaf(k, Vector3(HX1 + 0.08, F0, 1.3), true, 0.9, -1.0)
	_leaf(k, Vector3(5.83, F0, 3.86), false, 0.85, -1.0)
	_door_frame(k, Vector3(HX1, F0, 0.97), 0.9, 2.1, false)
	_door_frame(k, Vector3(5.4, F0, 3.8), 0.85, 2.1, true)
	# the den is mid-paint: an unfinished accent wall with tape and a roller line
	k.box_mm(Vector3(X1 - 0.13, F0 + 0.1, 4.0), Vector3(X1 - 0.12, F0 + 2.75, 6.4), "l90_accent", GeoKit.NX, false)
	k.box_mm(Vector3(X1 - 0.13, F0 + 0.1, 6.4), Vector3(X1 - 0.12, F0 + 1.6, 6.9), "l90_accent", GeoKit.NX, false)
	k.box_mm(Vector3(X1 - 0.14, F0 + 2.75, 4.0), Vector3(X1 - 0.12, F0 + 2.8, 10.8), "l90_tape", GeoKit.NX, false)
	# first floor ------------------------------------------------------
	k.wall(Vector3(HX0, F1, Z0 + 0.12), Vector3(HX0, F1, Z1 - 0.12), h1, 0.12, "l90_paint", [
		{"at": 1.2, "w": 0.9, "h": 2.1}, {"at": 9.2, "w": 0.85, "h": 2.1}])
	k.wall(Vector3(HX1, F1, Z0 + 0.12), Vector3(HX1, F1, Z1 - 0.12), h1, 0.12, "l90_paint", [
		{"at": 0.75, "w": 0.85, "h": 2.1}, {"at": 8.4, "w": 0.9, "h": 2.1}])
	k.wall(Vector3(X0 + 0.11, F1, 7.6), Vector3(HX0 - 0.06, F1, 7.6), h1, 0.12, "l90_tile_wall")
	k.wall(Vector3(HX1 + 0.06, F1, 5.6), Vector3(X1 - 0.11, F1, 5.6), h1, 0.12, "l90_paint2")
	k.box_mm(Vector3(X0 + 0.11, F1, 7.67), Vector3(HX0 - 0.07, F1 + 1.5, 7.68), "l90_tile_wall", GeoKit.PZ, false)
	_leaf(k, Vector3(HX0 - 0.08, F1, 1.65), true, 0.9)
	_leaf(k, Vector3(HX0 - 0.08, F1, 9.62), true, 0.85)
	_leaf(k, Vector3(HX1 + 0.08, F1, 0.33), true, 0.85)
	_leaf(k, Vector3(HX1 + 0.08, F1, 8.85), true, 0.9)
	for d in [[HX0, F0, 2.5, 1.6, 2.2], [HX0, F1, 1.2, 0.9, 2.1], [HX0, F1, 9.2, 0.85, 2.1], [HX1, F1, 0.75, 0.85, 2.1], [HX1, F1, 8.4, 0.9, 2.1]]:
		_door_frame(k, Vector3(d[0], d[1], d[2]), d[3], d[4], false)
	# skirting boards along the hall on both storeys
	for y in [F0, F1]:
		for x in [HX0 + 0.07, HX1 - 0.07]:
			k.box(Vector3(x, y + 0.06, 5.5), Vector3(0.02, 0.12, 10.7), "l90_trim", GeoKit.ALL, false)


func _stairs(k: GeoKit) -> void:
	k.stairs(Vector3((SX0 + SX1) * 0.5, F0, SZ0), Vector3(0, 0, 1), SX1 - SX0, F1 - F0, S_STEPS, "l90_stair", S_RUN, true)
	# a white stringer and a newel post with a handrail on the open side
	var tz := stair_top_z()
	var a := Vector3(SX0 - 0.03, F0 + 0.92, SZ0 + 0.1)
	var b := Vector3(SX0 - 0.03, F1 + 0.92, tz)
	var dir := (b - a).normalized()
	k.box_xf(Transform3D(Basis.looking_at(dir, Vector3.UP), (a + b) * 0.5), Vector3(0.07, 0.07, (b - a).length()), "l90_stair", GeoKit.ALL, false)
	for i in 12:
		var p := a.lerp(b, (i + 0.5) / 12.0)
		k.box(Vector3(p.x, p.y - 0.46, p.z), Vector3(0.04, 0.92, 0.04), "l90_trim", GeoKit.ALL, false)
	k.box(Vector3(SX0 - 0.03, F0 + 0.6, SZ0 + 0.05), Vector3(0.12, 1.2, 0.12), "l90_stair", GeoKit.ALL, false)
	k.box_mm(Vector3(SX0 - 0.02, F0, SZ0 + 0.1), Vector3(SX0 - 0.01, F0 + 0.18, tz), "l90_trim", GeoKit.NX, false)
	# the painted-shut door under the stair (west face of the stair block)
	k.box(Vector3(SX0 - 0.015, F0 + 0.92, 5.05), Vector3(0.03, 1.84, 0.78), "l90_door", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		k.box(Vector3(SX0 - 0.03, F0 + 0.94, 5.05 + s * 0.43), Vector3(0.05, 1.88, 0.07), "l90_trim", GeoKit.ALL, false)
	k.box(Vector3(SX0 - 0.03, F0 + 1.91, 5.05), Vector3(0.05, 0.07, 0.94), "l90_trim", GeoKit.ALL, false)
	k.box(Vector3(SX0 - 0.05, F0 + 0.95, 4.74), Vector3(0.04, 0.06, 0.06), "l90_brass", GeoKit.ALL, false)
	anchors["cupboard"] = Vector3(SX0 - 0.3, F0 + 1.0, 5.05)
	# landing guard rails round the void
	_rail(k, Vector3(SX0 - 0.03, F1, SZ0), Vector3(SX0 - 0.03, F1, tz - 1.0))
	_rail(k, Vector3(SX0 - 0.03, F1, SZ0), Vector3(SX1, F1, SZ0))
	# attic stair: steep and narrow, along the bonus room's front wall
	var ax := attic_top_x()
	k.stairs(Vector3(AX0, F1, (AZ0 + AZ1) * 0.5), Vector3(1, 0, 0), AZ1 - AZ0, A - F1, A_STEPS, "l90_attic_floor", A_RUN, true)
	k.box_mm(Vector3(AX0, F1, AZ1), Vector3(ax, F1 + 0.04, AZ1 + 0.03), "l90_trim", GeoKit.ALL, false)
	_rail(k, Vector3(AX0, A, AZ1 + 0.04), Vector3(ax - 0.9, A, AZ1 + 0.04))
	_rail(k, Vector3(AX0, A, AZ0 - 0.04), Vector3(ax - 0.9, A, AZ0 - 0.04))
	_rail(k, Vector3(AX0 - 0.04, A, AZ0), Vector3(AX0 - 0.04, A, AZ1))


func _rail(k: GeoKit, a: Vector3, b: Vector3) -> void:
	var c := (a + b) * 0.5
	var l := a.distance_to(b)
	var along_z := absf(b.z - a.z) > absf(b.x - a.x)
	var sz := Vector3(0.07, 0.06, l) if along_z else Vector3(l, 0.06, 0.07)
	k.box(c + Vector3(0, 0.95, 0), sz, "l90_stair", GeoKit.ALL, false)
	var n := maxi(int(l / 0.13), 1)
	for i in n:
		var p := a.lerp(b, (i + 0.5) / n)
		k.box(p + Vector3(0, 0.47, 0), Vector3(0.03, 0.94, 0.03), "l90_trim", GeoKit.ALL, false)
	var col := Vector3(0.1, 1.0, l) if along_z else Vector3(l, 1.0, 0.1)
	k.add_box_shape(Transform3D(Basis(), c + Vector3(0, 0.5, 0)), col, "wood")


func _porch_and_deck(k: GeoKit) -> void:
	# front portico: a slab, two columns, a pediment roof, three steps
	k.box_mm(Vector3(-2.3, 0.0, -2.4), Vector3(1.9, F0, 0.0), "l90_paver")
	k.stairs(Vector3(-0.22, 0.0, -3.3), Vector3(0, 0, 1), 2.0, F0, 3, "l90_paver", 0.3, true)
	for x in [-2.0, 1.6]:
		k.cylinder(Vector3(x, F0 + 1.45, -2.1), 0.17, 2.9, "l90_trim", 12, true)
		k.box(Vector3(x, F0 + 0.06, -2.1), Vector3(0.46, 0.12, 0.46), "l90_trim", GeoKit.ALL, false)
		k.box(Vector3(x, F0 + 2.86, -2.1), Vector3(0.44, 0.1, 0.44), "l90_trim", GeoKit.ALL, false)
	k.box(Vector3(-0.2, F0 + 3.0, -1.15), Vector3(4.6, 0.22, 2.6), "l90_trim", GeoKit.ALL, false)
	var st := Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-24.0)), Vector3(-0.2, F0 + 3.45, -1.25))
	k.box_xf(st, Vector3(4.8, 0.1, 2.9), "l90_roof", GeoKit.ALL, false)
	# back deck with rails and steps to the lawn
	k.box_mm(Vector3(-6.4, 0.0, Z1), Vector3(1.2, F0 - 0.02, Z1 + 3.4), "l90_deck_frame", GeoKit.SIDES, true)
	for i in 30:
		var x0 := -6.4 + i * 0.253
		k.box_mm(Vector3(x0 + 0.006, F0 - 0.05, Z1 + 0.02), Vector3(x0 + 0.247, F0, Z1 + 3.4), "l90_deck", GeoKit.PY | GeoKit.SIDES, false)
	k.add_box_shape(Transform3D(Basis(), Vector3(-2.6, F0 - 0.025, Z1 + 1.7)), Vector3(7.6, 0.05, 3.4), "wood")
	k.stairs(Vector3(-0.8, 0.0, Z1 + 4.3), Vector3(0, 0, -1), 1.6, F0, 3, "l90_deck", 0.3, true)
	_rail(k, Vector3(-6.35, F0, Z1 + 0.1), Vector3(-6.35, F0, Z1 + 3.35))
	_rail(k, Vector3(-6.35, F0, Z1 + 3.35), Vector3(-1.65, F0, Z1 + 3.35))
	_rail(k, Vector3(1.15, F0, Z1 + 0.1), Vector3(1.15, F0, Z1 + 3.35))
	for x in [-6.3, -3.9, -1.6, 1.1]:
		k.box(Vector3(x, F0 * 0.5, Z1 + 3.3), Vector3(0.14, F0, 0.14), "l90_deck_frame", GeoKit.ALL, false)


## Gable roof along X, shingles outside, plywood underside seen from the attic.
func _roof(k: GeoKit, node: Node3D) -> void:
	var pitch := deg_to_rad(PITCH)
	var half := (Z1 - Z0) * 0.5
	var over := 0.55
	var rise := half * tan(pitch)
	for s: float in [-1.0, 1.0]:
		var b := Basis(Vector3.RIGHT, s * pitch)
		var run := half + over
		var sl := run / cos(pitch)
		var zc := RIDGE_Z + s * (half + over) * 0.5
		var yc := A + rise - (half + over) * 0.5 * tan(pitch) * 1.0
		var n := b.y
		var c := Vector3(0, yc, zc) + n * 0.12
		k.box_xf(Transform3D(b, c), Vector3(X1 - X0 + 0.9, 0.12, sl), "l90_roof", GeoKit.PY | GeoKit.SIDES, true)
		k.box_xf(Transform3D(b, c - n * 0.07), Vector3(X1 - X0 + 0.9, 0.02, sl), "l90_plywood", GeoKit.NY, false)
		# exposed rafters in the attic
		var zi := RIDGE_Z + s * half * 0.5
		var yi := A + rise - half * 0.5 * tan(pitch)
		var x := X0 + 0.3
		while x < X1:
			k.box_xf(Transform3D(b, Vector3(x, yi, zi) - n * 0.03), Vector3(0.05, 0.16, half / cos(pitch)), "l90_attic_wood", GeoKit.ALL, false)
			x += 0.6
		# fascia and gutter along the eave
		var ez := RIDGE_Z + s * (half + over)
		k.box(Vector3(0, A - over * tan(pitch) + 0.02, ez), Vector3(X1 - X0 + 0.9, 0.22, 0.05), "l90_trim", GeoKit.ALL, false)
		k.box(Vector3(0, A - over * tan(pitch) - 0.05, ez + s * 0.07), Vector3(X1 - X0 + 0.9, 0.1, 0.12), "l90_gutter", GeoKit.ALL, false)
	k.box(Vector3(0, A + rise + 0.2, RIDGE_Z), Vector3(X1 - X0 + 0.9, 0.12, 0.3), "l90_roof", GeoKit.ALL, false)
	k.box(Vector3(0, A + rise - 0.05, RIDGE_Z), Vector3(X1 - X0, 0.2, 0.08), "l90_attic_wood", GeoKit.ALL, false)
	# chimney stack on the west gable
	var ch := A + rise + 1.0
	k.box(Vector3(X0 - 0.55, ch * 0.5, 6.0), Vector3(0.9, ch, 1.1), "l90_brick")
	# gable triangles: stucco outside, plywood inside, collision boxes for the attic
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sti := SurfaceTool.new()
	sti.begin(Mesh.PRIMITIVE_TRIANGLES)
	for sx in [-1.0, 1.0]:
		var xo: float = (X0 - 0.06) if sx < 0.0 else (X1 + 0.06)
		var xi: float = (X0 + 0.06) if sx < 0.0 else (X1 - 0.06)
		var tri_o := [Vector3(xo, A - 0.12, Z0), Vector3(xo, A + rise + 0.1, RIDGE_Z), Vector3(xo, A - 0.12, Z1)]
		var tri_i := [Vector3(xi, A, Z0), Vector3(xi, A + rise, RIDGE_Z), Vector3(xi, A, Z1)]
		var ord_o := [0, 1, 2, 0, 2, 1]
		var ord_i := [0, 2, 1, 0, 1, 2]
		for i in ord_o:
			st.set_normal(Vector3(sx, 0, 0))
			st.set_uv(Vector2(tri_o[i].z, -tri_o[i].y))
			st.add_vertex(tri_o[i])
		for i in ord_i:
			sti.set_normal(Vector3(-sx, 0, 0))
			sti.set_uv(Vector2(tri_i[i].z, -tri_i[i].y))
			sti.add_vertex(tri_i[i])
		for j in 4:
			var y0 := A + j * rise / 4.0
			var hz := half * (1.0 - (j + 0.5) / 4.0)
			k.add_box_shape(Transform3D(Basis(), Vector3((X0 if sx < 0.0 else X1), y0 + rise / 8.0, RIDGE_Z)), Vector3(0.2, rise / 4.0, hz * 2.0 + 0.4), "wood")
	for pair in [[st, "l90_stucco"], [sti, "l90_plywood"]]:
		var mi := MeshInstance3D.new()
		mi.mesh = (pair[0] as SurfaceTool).commit()
		mi.material_override = MatLib.get_mat(pair[1])
		node.add_child(mi)


## Attic: joists with insulation between them, plywood walkway boards, a gable
## vent window at each end (the only daylight up here).
func _attic(k: GeoKit) -> void:
	var x := X0 + 0.4
	while x < X1 - 0.2:
		k.box(Vector3(x, A + 0.04, 5.5), Vector3(0.05, 0.1, 10.6), "l90_attic_wood", GeoKit.ALL, false)
		x += 0.6
	k.box_mm(Vector3(X0 + 0.15, A + 0.002, 0.7), Vector3(X1 - 0.15, A + 0.07, 1.9), "l90_insul", GeoKit.PY, false)
	k.box_mm(Vector3(X0 + 0.15, A + 0.002, 9.1), Vector3(X1 - 0.15, A + 0.07, 10.3), "l90_insul", GeoKit.PY, false)
	# plywood walkway down the middle
	k.box_mm(Vector3(X0 + 0.3, A + 0.09, 3.9), Vector3(X1 - 0.3, A + 0.11, 5.6), "l90_plywood", GeoKit.PY | GeoKit.SIDES, false)
	k.add_box_shape(Transform3D(Basis(), Vector3(0, A + 0.055, 4.75)), Vector3(X1 - X0 - 0.6, 0.11, 1.7), "wood")
	# gable vent windows
	for sx in [-1.0, 1.0]:
		var gx: float = X0 if sx < 0.0 else X1
		var c := Vector3(gx, A + 2.1, RIDGE_Z)
		k.box(c + Vector3(0, 0.42, 0), Vector3(0.3, 0.08, 0.92), "l90_trim", GeoKit.ALL, false)
		k.box(c - Vector3(0, 0.42, 0), Vector3(0.3, 0.08, 0.92), "l90_trim", GeoKit.ALL, false)
		for s in [-1.0, 1.0]:
			k.box(c + Vector3(0, 0, s * 0.42), Vector3(0.3, 0.92, 0.08), "l90_trim", GeoKit.ALL, false)
		for j in 5:
			k.box(c + Vector3(sx * 0.02, -0.3 + j * 0.15, 0), Vector3(0.04, 0.03, 0.78), "l90_trim", GeoKit.ALL, false)
	anchors["attic_vent_w"] = Vector3(X0 + 0.3, A + 2.1, RIDGE_Z)


# ---------------------------------------------------------------- furniture

func _ph(node: Node3D, id: String, p: Vector3, yaw: float, collide: bool = false, h: float = 0.0) -> Node3D:
	return Props.place(lvl, node, "ph/" + id, p, yaw, h, collide)


func _kn(node: Node3D, name: String, p: Vector3, yaw: float, collide: bool = false, mult: float = 1.0) -> Node3D:
	var id := "kenney/furniture-kit/" + name
	var hh := Props.bounds(id).size.y * KS * mult
	return Props.place(lvl, node, id, p, yaw, maxf(hh, 0.01), collide)


func _food(node: Node3D, name: String, p: Vector3, yaw: float, h: float) -> Node3D:
	return Props.place(lvl, node, "kenney/food-kit/" + name, p, yaw, h, false)


func _furnish(n: Node3D) -> void:
	_hall(n)
	_living(n)
	_kitchen(n)
	_east_ground(n)
	_upstairs(n)
	_attic_props(n)
	_ceiling_lamps(n)


func _hall(n: Node3D) -> void:
	_kn(n, "rugdoormat", Vector3(-0.22, F0 + 0.005, 0.5), 0.0)
	_kn(n, "rugrectangle", Vector3(-0.22, F0 + 0.004, 3.6), 90.0, false, 0.9)
	_ph(n, "ClassicNightstand_01", Vector3(-0.72, F0, 6.6), 90.0, true)
	anchors["flyer"] = Vector3(-0.68, F0 + 0.72, 6.6)
	_kn(n, "plantsmall2", Vector3(-0.72, F0 + 0.7, 6.95), 0.0, false, 0.8)
	_ph(n, "ornate_mirror_01", Vector3(-0.92, F0 + 1.55, 6.6), 90.0)
	_ph(n, "wall_clock", Vector3(HX1 - 0.08, F0 + 2.05, 7.0), -90.0)
	_kn(n, "coatrackstanding", Vector3(-0.7, F0, 1.2), 0.0, false, 1.1)
	# thermostat on the hall wall, opposite the stair foot
	anchors["thermostat"] = Vector3(HX0 + 0.08, F0 + 1.45, 4.3)


func _living(n: Node3D) -> void:
	_kn(n, "rugrectangle", Vector3(-4.0, F0 + 0.004, 2.7), 0.0, false, 1.0)
	_ph(n, "Sofa_01", Vector3(-4.0, F0, 4.85), 180.0, true)
	_ph(n, "ArmChair_01", Vector3(-6.2, F0, 2.4), 100.0, true)
	_ph(n, "ArmChair_01", Vector3(-1.9, F0, 2.6), -100.0, true)
	_ph(n, "coffee_table_round_01", Vector3(-4.0, F0, 2.9), 0.0, true)
	_kn(n, "cabinettelevision", Vector3(-4.0, F0, 0.33), 0.0, true)
	_ph(n, "Television_01", Vector3(-4.0, F0 + 0.62, 0.33), 0.0)
	_kn(n, "lamproundfloor", Vector3(-6.45, F0, 4.9), 0.0)
	_kn(n, "pottedplant", Vector3(-1.5, F0, 0.5), 0.0)
	_ph(n, "wooden_bookshelf_worn", Vector3(-6.55, F0, 0.9), 90.0, true)
	_food(n, "cup-saucer", Vector3(-3.8, F0 + 0.49, 2.8), 30.0, 0.08)
	_kn(n, "books", Vector3(-4.3, F0 + 0.49, 3.1), 20.0, false, 0.4)


func _kitchen(n: Node3D) -> void:
	var cz := Z1 - 0.1 - 0.46
	var xs := [-6.5, -5.62, -4.74, -3.86]
	var parts := ["kitchencabinetdrawer", "kitchensink", "kitchenstove", "kitchencabinet"]
	for i in 4:
		_kn(n, parts[i], Vector3(xs[i] + 0.22, F0, cz), 180.0, true)
	for i in [0, 2, 3]:
		_kn(n, "kitchencabinetupper", Vector3(xs[i] + 0.22, F0 + 1.45, Z1 - 0.1 - 0.23), 180.0)
	_kn(n, "kitchenfridgelarge", Vector3(-6.5, F0, 6.4), 90.0, true)
	_kn(n, "kitchencoffeemachine", Vector3(-3.6, F0 + 0.92, cz), 180.0)
	_kn(n, "toaster", Vector3(-6.2, F0 + 0.92, cz), 180.0)
	anchors["brochure"] = Vector3(-4.3, F0 + 0.93, cz - 0.1)
	_ph(n, "dining_table", Vector3(-3.9, F0, 7.6), 90.0, true)
	for c in [[-4.4, 6.65, 0.0], [-3.4, 6.65, 0.0], [-4.4, 8.6, 180.0], [-3.4, 8.6, 180.0], [-5.35, 7.6, 90.0]]:
		_ph(n, "dining_chair_02", Vector3(c[0], F0, c[1]), c[2], true)
	_food(n, "bowl", Vector3(-3.9, F0 + 0.88, 7.6), 0.0, 0.12)
	_food(n, "glass", Vector3(-3.5, F0 + 0.88, 7.3), 0.0, 0.14)
	_ph(n, "Chandelier_01", Vector3(-3.9, F1 - 1.05, 7.6), 0.0)


func _east_ground(n: Node3D) -> void:
	# laundry: washer, dryer, shelves, the breaker panel, exterminator's paperwork
	_kn(n, "washer", Vector3(2.15, F0, 0.48), 0.0, true)
	_kn(n, "dryer", Vector3(2.95, F0, 0.48), 0.0, true)
	_ph(n, "steel_frame_shelves_02", Vector3(3.55, F0, 2.6), -90.0, true)
	_ph(n, "power_box_01", Vector3(HX1 + 0.3, F0 + 1.2, 3.55), 180.0)
	anchors["breaker"] = Vector3(HX1 + 0.3, F0 + 1.45, 3.4)
	_ph(n, "plastic_crate_01", Vector3(3.55, F0 + 0.02, 2.6), 0.0)
	_ph(n, "trashbag", Vector3(2.0, F0, 3.2), 40.0)
	_ph(n, "WetFloorSign_01", Vector3(3.3, F0, 1.6), 20.0)
	anchors["invoice"] = Vector3(2.55, F0 + 0.95, 0.5)
	# bathroom 1
	_kn(n, "toilet", Vector3(6.55, F0, 2.6), -90.0, true)
	_kn(n, "bathroomsink", Vector3(4.6, F0, 0.4), 0.0, true)
	_kn(n, "bathroommirror", Vector3(4.6, F0 + 1.4, 0.16), 0.0)
	_kn(n, "showerround", Vector3(6.35, F0, 0.65), 0.0, true, 0.95)
	# den: furnished at one end, decorators' leftovers at the other
	_kn(n, "loungesofa", Vector3(3.6, F0, 10.35), 180.0, true)
	_kn(n, "tablecoffee", Vector3(3.6, F0, 9.1), 0.0, true)
	_kn(n, "cabinettelevision", Vector3(3.6, F0, 6.2), 0.0, true, 0.95)
	_kn(n, "televisionmodern", Vector3(3.6, F0 + 0.6, 6.2), 0.0)
	_kn(n, "bookcaseopen", Vector3(2.0, F0, 4.6), 90.0, true)
	_ph(n, "wooden_ladder", Vector3(6.3, F0, 5.2), 90.0, false, 1.9)
	_ph(n, "metal_tool_chest", Vector3(6.4, F0, 8.7), -90.0, true)
	_ph(n, "cardboard_box_01", Vector3(5.6, F0, 9.9), 15.0, true)
	_ph(n, "cardboard_box_01", Vector3(5.6, F0 + 0.34, 9.9), 40.0)
	anchors["paint"] = Vector3(6.2, F0, 6.6)


func _upstairs(n: Node3D) -> void:
	# bedroom 1 (west front)
	_kn(n, "beddouble", Vector3(-4.6, F1, 2.0), 0.0, true)
	_ph(n, "ClassicNightstand_01", Vector3(-6.0, F1, 0.4), 0.0, true)
	_ph(n, "ClassicNightstand_01", Vector3(-3.2, F1, 0.4), 0.0, true)
	_kn(n, "lamproundfloor", Vector3(-6.0, F1 + 0.7, 0.4), 0.0, false, 0.35)
	_kn(n, "lamproundfloor", Vector3(-3.2, F1 + 0.7, 0.4), 0.0, false, 0.35)
	_ph(n, "drawer_cabinet", Vector3(-6.6, F1, 5.4), 90.0, true)
	_kn(n, "ruground", Vector3(-4.0, F1 + 0.004, 5.0), 0.0)
	_ph(n, "GreenChair_01", Vector3(-2.0, F1, 6.6), -135.0, true)
	anchors["bed"] = Vector3(-4.6, F1, 2.0)
	# bathroom 2 (west back)
	_kn(n, "bathtub", Vector3(-5.6, F1, 10.3), 0.0, true, 0.85)
	_kn(n, "toilet", Vector3(-6.55, F1, 8.3), 90.0, true)
	_kn(n, "bathroomsink", Vector3(-3.0, F1, 7.95), 180.0, true)
	_kn(n, "bathroommirror", Vector3(-3.0, F1 + 1.4, 7.72), 180.0)
	_kn(n, "bathroomcabinet", Vector3(-1.5, F1, 10.6), 180.0, true)
	_ph(n, "rubber_duck_toy", Vector3(-5.3, F1 + 0.55, 10.35), 120.0, false, 0.09)
	# bedroom 2 (east front)
	_kn(n, "bedsingle", Vector3(6.0, F1, 2.6), -90.0, true)
	_kn(n, "desk", Vector3(2.4, F1, 4.95), 180.0, true)
	_kn(n, "chairdesk", Vector3(2.4, F1, 4.3), 0.0, true)
	_kn(n, "bookcaseclosed", Vector3(4.0, F1, 5.2), 180.0, true)
	_kn(n, "ruground", Vector3(4.4, F1 + 0.004, 2.4), 0.0)
	_kn(n, "pottedplant", Vector3(6.6, F1, 5.1), 0.0)
	# bonus room with the attic stair (east back)
	_ph(n, "ArmChair_01", Vector3(5.6, F1, 9.3), 200.0, true)
	_kn(n, "sidetable", Vector3(6.5, F1, 8.4), 0.0, true)
	_ph(n, "vintage_suitcase", Vector3(5.0, F1, 10.6), 0.0, true)
	_ph(n, "cardboard_box_01", Vector3(4.0, F1, 10.5), 0.0, true)
	_ph(n, "cardboard_box_01", Vector3(4.05, F1 + 0.34, 10.5), 25.0)


func _attic_props(n: Node3D) -> void:
	# the air handler "in shambles": a cabinet with its panel off, ducts hanging loose
	var ac := Vector3(-2.6, A + 0.11, 5.6)
	anchors["ac"] = ac
	var k := GeoKit.new(n, "AirHandler")
	k.box(ac + Vector3(0, 0.75, 0), Vector3(1.6, 1.5, 0.9), "l90_ac_metal", GeoKit.ALL, true)
	k.box(ac + Vector3(0.0, 0.75, 0.46), Vector3(1.3, 1.2, 0.02), "l90_ac_dark", GeoKit.ALL, false)
	k.box(ac + Vector3(0.4, 0.75, 0.47), Vector3(0.36, 0.36, 0.02), "l90_ac_fan", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-78.0)), ac + Vector3(0.2, 0.06, 1.2)), Vector3(1.3, 1.2, 0.03), "l90_ac_metal", GeoKit.ALL, false)
	k.box(ac + Vector3(-0.4, 1.55, 0), Vector3(0.5, 0.12, 0.5), "l90_ac_metal", GeoKit.ALL, false)
	k.box(ac + Vector3(-1.1, 0.6, 0.0), Vector3(0.5, 0.2, 0.1), "l90_ac_dark", GeoKit.ALL, false)
	for i in 6:
		k.box(ac + Vector3(0.7 + i * 0.03, 0.2 + i * 0.12, 0.47), Vector3(0.012, 0.012, 0.5), "l90_wire%d" % (i % 3), GeoKit.ALL, false)
	k.commit()
	_ph(n, "modular_airduct_rectangular_01", ac + Vector3(0.0, 0.25, -3.0), 90.0, false, 0.62)
	_ph(n, "modular_electric_cables", ac + Vector3(-0.5, 0.0, -0.9), 0.0)
	_ph(n, "metal_tool_chest", ac + Vector3(1.4, 0.0, -1.0), 30.0)
	_ph(n, "vintage_flashlight", ac + Vector3(1.0, 0.0, 1.0), 70.0)
	_ph(n, "caged_hanging_light", Vector3(0.0, A + 3.4, 5.5), 0.0, false, 0.6)
	# what the renovators left: boxes, a suitcase, a crate of lamps
	for b in [[-5.6, 4.6, 10.0], [-5.1, 6.4, 40.0], [-5.9, 5.8, 75.0], [4.8, 4.6, 5.0], [6.3, 7.4, 60.0], [5.9, 5.0, 20.0]]:
		_ph(n, "cardboard_box_01", Vector3(b[0], A + 0.11, b[1]), b[2], true)
	_ph(n, "cardboard_box_01", Vector3(-5.6, A + 0.45, 4.6), 30.0)
	_ph(n, "vintage_suitcase", Vector3(3.6, A + 0.11, 7.7), -20.0)
	_ph(n, "old_bed_frame", Vector3(5.6, A + 0.11, 3.0), 90.0, false, 1.0)
	# the exterminator's work: snap traps and bait stations along the eaves
	var tk := GeoKit.new(n, "Traps")
	var r := RandomNumberGenerator.new()
	r.seed = 9090
	for i in 22:
		var side := 1.0 if i % 2 == 0 else -1.0
		var z := RIDGE_Z + side * r.randf_range(2.8, 3.6)
		var x := r.randf_range(X0 + 0.5, X1 - 0.5)
		var p := Vector3(x, A + 0.11, z)
		if i % 3 == 0:
			tk.box(p + Vector3(0, 0.05, 0), Vector3(0.24, 0.1, 0.16), "l90_bait", GeoKit.ALL, false)
		else:
			tk.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * TAU), p + Vector3(0, 0.01, 0)), Vector3(0.1, 0.012, 0.18), "l90_trap_wood", GeoKit.ALL, false)
			tk.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * TAU), p + Vector3(0, 0.025, 0)), Vector3(0.08, 0.004, 0.08), "l90_trap_metal", GeoKit.ALL, false)
	tk.commit()


func _ceiling_lamps(n: Node3D) -> void:
	var warm := Color(1.0, 0.86, 0.68)
	for l in [[Vector3(-0.2, F1 - 0.22, 3.0), 0.8, 0], [Vector3(-0.2, F1 - 0.22, 8.8), 0.7, 0], [Vector3(-4.0, F1 - 0.22, 2.8), 0.9, 0],
			[Vector3(-4.6, F1 - 0.22, 9.4), 0.9, 0], [Vector3(2.7, F1 - 0.22, 1.9), 0.6, 0], [Vector3(5.4, F1 - 0.22, 1.9), 0.6, 0],
			[Vector3(4.3, F1 - 0.22, 7.6), 0.8, 0], [Vector3(-4.0, C1 - 0.22, 3.0), 0.8, 1], [Vector3(-4.0, C1 - 0.22, 9.3), 0.7, 1],
			[Vector3(4.3, C1 - 0.22, 2.8), 0.7, 1], [Vector3(4.6, C1 - 0.22, 8.4), 0.7, 1], [Vector3(-0.2, C1 - 0.22, 8.0), 0.6, 1]]:
		var p: Vector3 = l[0]
		lamp_nodes.append(_kn(n, "lampsquareceiling", p + Vector3(0, -0.18, 0), 0.0))
		lights.append([p + Vector3(0, -0.35, 0), warm, float(l[1]) * 1.7, 5.2, l[2]])
	# the attic's bare bulbs
	lights.append([Vector3(0.0, A + 2.7, 5.5), Color(1.0, 0.8, 0.55), 1.6, 7.5, 2])
	lights.append([Vector3(-3.6, A + 2.4, 4.6), Color(1.0, 0.8, 0.55), 1.1, 6.0, 2])
