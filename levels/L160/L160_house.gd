extends RefCounted
## Level 160: her house at the end of the street ("House With Striped Awnings").
## Ground floor (y 0.3): hall with the stair, dining room with the soup laid out,
## kitchen, sitting room. Upper floor (y 3.3): her bedroom, the children's room.
## The back door opens onto "one more place you need to go through": darkness.

const X0 := 45.0
const X1 := 55.0
const Z0 := 7.0
const Z1 := 17.0
const F0 := 0.3
const F1 := 3.3
const H := 3.0
const T := 0.15
const HALL0 := 48.8
const HALL1 := 51.2

var L: Node3D
var k: GeoKit
var door_pivot: Node3D
var door_kit: GeoKit
var lamps: Array = []       # [pos, energy, range]


func _init(level: Node3D, kit: GeoKit) -> void:
	L = level
	k = kit


static func materials() -> void:
	MatLib.define("l160_house_wall", {"albedo_a": Color(0.82, 0.78, 0.68), "albedo_b": Color(0.76, 0.72, 0.62), "pattern": 2,
		"pattern_scale": Vector2(1.0, 0.18), "pattern_strength": 0.12, "stain_amount": 0.3, "stain_color": Color(0.5, 0.48, 0.42),
		"grime_height": 0.5, "grime_color": Color(0.45, 0.42, 0.36), "uv_rotate": 1.5708}, "plaster")
	MatLib.define("l160_awning", {"albedo_a": Color(0.62, 0.16, 0.14), "albedo_b": Color(0.56, 0.14, 0.12), "pattern": 2,
		"pattern_scale": Vector2(0.32, 1.0), "pattern_color": Color(0.88, 0.84, 0.74), "pattern_strength": 1.0, "roughness_a": 0.9}, "plaster")
	MatLib.define("l160_paper", {"albedo_a": Color(0.70, 0.60, 0.46), "albedo_b": Color(0.64, 0.54, 0.40), "pattern": 10,
		"pattern_scale": Vector2(0.3, 0.3), "pattern_color": Color(0.58, 0.44, 0.32), "pattern_strength": 0.4,
		"grime_height": 0.2, "grime_color": Color(0.4, 0.33, 0.24)}, "plaster")
	MatLib.define("l160_paper_kids", {"albedo_a": Color(0.62, 0.70, 0.74), "albedo_b": Color(0.58, 0.66, 0.70), "pattern": 5,
		"pattern_scale": Vector2(0.2, 0.2), "pattern_color": Color(0.85, 0.82, 0.6), "pattern_strength": 0.35}, "plaster")
	MatLib.define("l160_floorboards", {"albedo_a": Color(0.44, 0.30, 0.19), "albedo_b": Color(0.36, 0.24, 0.15)}, "wood_floor")
	MatLib.define("l160_kitchen_tile", {"albedo_a": Color(0.78, 0.76, 0.70), "albedo_b": Color(0.70, 0.68, 0.62), "pattern": 9,
		"pattern_scale": Vector2(0.3, 0.3), "pattern_color": Color(0.32, 0.36, 0.42), "pattern_strength": 0.7}, "pool_tile")
	MatLib.define("l160_ceiling", {"albedo_a": Color(0.86, 0.84, 0.78), "albedo_b": Color(0.80, 0.78, 0.72)}, "plaster")
	MatLib.define("l160_trim", {"albedo_a": Color(0.92, 0.90, 0.84), "albedo_b": Color(0.86, 0.84, 0.78)}, "trim_white")
	MatLib.register("l160_lit_window", MatLib.panel(Color(1.0, 0.72, 0.42), 0.55))
	MatLib.register("l160_ceramic", MatLib.standard(Color(0.92, 0.91, 0.88), 0.25))
	MatLib.register("l160_soup", MatLib.standard(Color(0.62, 0.30, 0.12), 0.3, 0.0, Color(0.2, 0.08, 0.02), 0.2))
	MatLib.register("l160_cloth", MatLib.standard(Color(0.86, 0.84, 0.78), 0.95))
	MatLib.register("l160_lamp_panel", MatLib.panel(Color(1.0, 0.82, 0.58), 2.2))
	MatLib.register("l160_blanket", MatLib.standard(Color(0.48, 0.36, 0.44), 1.0))


## Room-facing wall slab (all faces in mat).
func _wall(axis: String, a0: float, a1: float, d: float, y0: float, holes: Array, mat: String, outer_mat := "") -> void:
	var cursor := a0
	var hs := holes.duplicate()
	hs.sort_custom(func(p, q): return p[0] < q[0])
	for h in hs:
		if h[0] > cursor + 0.001:
			_piece(axis, cursor, h[0], d, y0, y0 + H, mat)
		if h[2] > 0.001:
			_piece(axis, h[0], h[1], d, y0, y0 + h[2], mat)
		if h[3] < H - 0.001:
			_piece(axis, h[0], h[1], d, y0 + h[3], y0 + H, mat)
		cursor = h[1]
	if cursor < a1 - 0.001:
		_piece(axis, cursor, a1, d, y0, y0 + H, mat)


func _piece(axis: String, s0: float, s1: float, d: float, y0: float, y1: float, mat: String) -> void:
	if axis == "x":
		k.box(Vector3((s0 + s1) * 0.5, (y0 + y1) * 0.5, d), Vector3(s1 - s0, y1 - y0, T), mat)
	else:
		k.box(Vector3(d, (y0 + y1) * 0.5, (s0 + s1) * 0.5), Vector3(T, y1 - y0, s1 - s0), mat)


func build() -> void:
	# porch and steps
	k.box(Vector3(50, F0 * 0.5, Z0 - 0.7), Vector3(3.4, F0, 1.4), "l160_pavement")
	k.box(Vector3(50, 0.075, Z0 - 1.55), Vector3(3.0, 0.15, 0.3), "l160_pavement", GeoKit.ALL, false)
	k.box(Vector3(50, 0.15, Z0 - 1.5), Vector3(3.0, 0.3, 0.02), "l160_pavement", GeoKit.ALL, false)
	k.ramp(Vector3(50, 0.0, Z0 - 1.95), Vector3(50, F0 + 0.01, Z0 - 1.38), 3.0, 0.2, "l160_pavement")
	for sx in [48.36, 51.64]:
		k.box(Vector3(sx, F0 + 0.45, Z0 - 0.72), Vector3(0.08, 0.9, 1.36), "l160_trim")
		k.box(Vector3(sx, F0 + 0.45, Z0 - 1.36), Vector3(0.12, 0.9, 0.12), "l160_trim")
	# floors and ceilings
	k.slab(X0, Z0, X1, Z1, F0, F0, "l160_floorboards")
	k.box(Vector3(46.9, F0 + 0.004, 15.0), Vector3(3.6, 0.008, 3.8), "l160_kitchen_tile", GeoKit.PY, false)
	# upper floor with the stair well (x 50.2..51.2, z 8.6..13.4)
	var sw0 := 50.15
	var sz0 := 8.5
	var sz1 := 13.45
	k.box_mm(Vector3(X0, F1 - 0.25, Z0), Vector3(sw0, F1, Z1), "l160_floorboards")
	k.box_mm(Vector3(sw0, F1 - 0.25, Z0), Vector3(X1, F1, sz0), "l160_floorboards")
	k.box_mm(Vector3(sw0, F1 - 0.25, sz1), Vector3(X1, F1, Z1), "l160_floorboards")
	k.box_mm(Vector3(HALL1, F1 - 0.25, sz0), Vector3(X1, F1, sz1), "l160_floorboards")
	k.box(Vector3(50, F1 - 0.26, 12), Vector3(10, 0.02, 10), "l160_ceiling", GeoKit.NY, false)
	k.box(Vector3(50, F1 + H + 0.1, 12), Vector3(10.3, 0.2, 10.3), "l160_ceiling")
	# exterior walls, ground floor: front door, back door, windows
	var win := 1.2
	_wall("x", X0, X1, Z0, F0, [[49.45, 50.55, 0.0, 2.15], [46.3, 46.3 + win, 0.9, 2.2], [52.5, 52.5 + win, 0.9, 2.2]], "l160_house_wall")
	_wall("x", X0, X1, Z1, F0, [[49.5, 50.5, 0.0, 2.1], [46.4, 47.4, 1.0, 2.1]], "l160_house_wall")
	_wall("z", Z0, Z1, X0, F0, [[9.4, 10.6, 0.9, 2.2]], "l160_house_wall")
	_wall("z", Z0, Z1, X1, F0, [[9.0, 10.2, 0.9, 2.2], [14.0, 15.2, 0.9, 2.2]], "l160_house_wall")
	# upper floor exterior
	_wall("x", X0, X1, Z0, F1, [[46.3, 46.3 + win, 0.9, 2.2], [52.5, 52.5 + win, 0.9, 2.2]], "l160_house_wall")
	_wall("x", X0, X1, Z1, F1, [[46.5, 47.7, 0.9, 2.2]], "l160_house_wall")
	_wall("z", Z0, Z1, X0, F1, [[11.4, 12.6, 0.9, 2.2]], "l160_house_wall")
	_wall("z", Z0, Z1, X1, F1, [[11.4, 12.6, 0.9, 2.2]], "l160_house_wall")
	# interior partitions, ground floor
	_wall("z", Z0, Z1, HALL0, F0, [[9.6, 11.2, 0.0, 2.2], [15.2, 16.2, 0.0, 2.1]], "l160_paper")
	_wall("z", Z0, Z1, HALL1, F0, [[7.6, 8.4, 0.0, 2.1], [15.3, 16.5, 0.0, 2.2]], "l160_paper")
	k.box(Vector3(46.9, F0 + 1.5, 13.0), Vector3(3.7, 3.0, 0.12), "l160_paper")
	# upper partitions with doors off the landing
	_wall("z", Z0, Z1, HALL0, F1, [[14.6, 15.5, 0.0, 2.1]], "l160_paper")
	_wall("z", Z0, Z1, HALL1, F1, [[14.6, 15.5, 0.0, 2.1]], "l160_paper_kids")
	k.box(Vector3(49.5, F1 + 1.5, Z0 + 0.6), Vector3(1.3, 3.0, 0.12), "l160_paper")
	# the stair (17 risers of 0.176 m) rising south along the hall's east side
	k.stairs(Vector3(50.68, F0, sz0 + 0.1), Vector3(0, 0, 1), 0.95, F1 - F0, 17, "l160_floorboards", 0.28)
	# the stair is boxed in on the hall side, with a handrail along the panel
	k.box(Vector3(50.13, (F0 + F1 - 0.25) * 0.5, (sz0 + sz1) * 0.5 + 0.05), Vector3(0.08, F1 - 0.25 - F0, sz1 - sz0 - 0.1), "l160_paper")
	var rail_a := Vector3(50.24, F0 + 0.95, sz0 + 0.1)
	var rail_b := Vector3(50.24, F1 + 0.95, sz1)
	var rd := rail_b - rail_a
	k.box_xf(Transform3D(Basis.looking_at(rd.normalized(), Vector3.UP), (rail_a + rail_b) * 0.5), Vector3(0.05, 0.05, rd.length()), "l160_door", GeoKit.ALL, false)
	# landing railing around the well
	k.box(Vector3(50.15, F1 + 0.5, (sz0 + sz1) * 0.5), Vector3(0.06, 1.0, sz1 - sz0), "l160_trim")
	# roof: gable along x
	var pitch := deg_to_rad(32.0)
	var run := 5.0 + 0.5
	var slope := run / cos(pitch)
	for s in [-1.0, 1.0]:
		var bas := Basis(Vector3(1, 0, 0), s * pitch)
		var ctr := Vector3(50, F1 + H + 0.2 + tan(pitch) * run * 0.5, 12 + s * run * 0.5)
		k.box_xf(Transform3D(bas, ctr), Vector3(10.8, 0.14, slope), "l160_roof", GeoKit.ALL, false)
	for gx in [X0 - 0.01, X1 + 0.01]:
		for i in 7:
			var hh := tan(pitch) * 5.0 / 7.0
			var ww := 10.0 * (1.0 - (float(i) + 0.5) / 7.0)
			k.box(Vector3(gx, F1 + H + 0.2 + (float(i) + 0.5) * hh, 12), Vector3(0.05, hh, ww), "l160_house_wall", GeoKit.ALL, false)
	# striped awnings over the four front windows, lit glass behind them
	for wx in [46.9, 53.1]:
		for fy in [F0, F1]:
			var bas := Basis(Vector3(1, 0, 0), deg_to_rad(-28.0))
			k.box_xf(Transform3D(bas, Vector3(wx, fy + 2.5, Z0 - 0.42)), Vector3(1.6, 0.04, 0.95), "l160_awning", GeoKit.ALL, false)
			for sx in [-0.78, 0.78]:
				k.box(Vector3(wx + sx, fy + 2.35, Z0 - 0.42), Vector3(0.03, 0.3, 0.8), "l160_awning", GeoKit.ALL, false)
			k.box(Vector3(wx, fy + 1.55, Z0 - 0.02), Vector3(win, 1.3, 0.03), "l160_lit_window", GeoKit.ALL, false)
			k.box(Vector3(wx, fy + 0.88, Z0 - 0.1), Vector3(win + 0.2, 0.06, 0.2), "l160_trim", GeoKit.ALL, false)
	for w in [[Vector3(X0 - 0.02, F0 + 1.55, 10.0), true], [Vector3(X1 + 0.02, F0 + 1.55, 9.6), true], [Vector3(X1 + 0.02, F0 + 1.55, 14.6), true],
			[Vector3(X0 - 0.02, F1 + 1.55, 12.0), true], [Vector3(X1 + 0.02, F1 + 1.55, 12.0), true]]:
		k.box(w[0], Vector3(0.03, 1.3, 1.2), "l160_lit_window", GeoKit.ALL, false)
	for w in [Vector3(46.9, F0 + 1.55, Z1 + 0.02), Vector3(47.1, F1 + 1.55, Z1 + 0.02)]:
		k.box(w, Vector3(1.1, 1.2, 0.03), "l160_lit_window", GeoKit.ALL, false)
	# door casings
	k.box(Vector3(50, F0 + 2.2, Z0 - 0.09), Vector3(1.4, 0.12, 0.06), "l160_trim", GeoKit.ALL, false)
	for sx in [-0.6, 0.6]:
		k.box(Vector3(50 + sx, F0 + 1.07, Z0 - 0.09), Vector3(0.1, 2.15, 0.06), "l160_trim", GeoKit.ALL, false)
	_vestibule()
	_tableware()
	lamps = [[Vector3(46.9, F0 + 2.3, 10.0), 1.4, 6.0], [Vector3(50.0, F0 + 2.75, 11.5), 0.8, 5.0], [Vector3(53.1, F0 + 2.6, 10.5), 0.9, 5.5],
		[Vector3(46.9, F0 + 2.6, 15.0), 0.8, 4.5], [Vector3(46.9, F1 + 2.6, 11.0), 0.7, 5.5], [Vector3(53.1, F1 + 2.6, 11.5), 0.5, 5.0],
		[Vector3(49.5, F1 + 2.6, 15.5), 0.5, 4.0]]
	for l in lamps:
		k.cylinder((l[0] as Vector3) + Vector3(0, 0.2, 0), 0.16, 0.05, "l160_lamp_panel", 14, false)


## "There's just one more place you need to go through. I will be waiting for you inside."
func _vestibule() -> void:
	var z0 := Z1 + T * 0.5
	var z1 := Z1 + 3.6
	k.box(Vector3(50, F0 * 0.5, (z0 + z1) * 0.5), Vector3(2.6, F0, z1 - z0), "unlit_black")
	k.box(Vector3(50, F0 + H * 0.5, z1), Vector3(2.6, H, 0.2), "unlit_black")
	for sx in [48.75, 51.25]:
		k.box(Vector3(sx, F0 + H * 0.5, (z0 + z1) * 0.5), Vector3(0.15, H, z1 - z0), "unlit_black")
	k.box(Vector3(50, F0 + H + 0.05, (z0 + z1) * 0.5), Vector3(2.6, 0.1, z1 - z0), "unlit_black")
	# outside face of the annex looks like the house
	k.box(Vector3(50, F0 + H * 0.5, z1 + 0.11), Vector3(2.62, H + 0.6, 0.02), "l160_house_wall", GeoKit.ALL, false)
	for sx in [48.66, 51.34]:
		k.box(Vector3(sx, F0 + H * 0.5, (z0 + z1) * 0.5), Vector3(0.02, H + 0.6, z1 - z0), "l160_house_wall", GeoKit.ALL, false)
	k.box(Vector3(50, F0 + H + 0.32, (z0 + z1) * 0.5), Vector3(2.7, 0.08, z1 - z0 + 0.2), "l160_roof", GeoKit.ALL, false)
	# the back door leaf on its own hinge (opened by the pact)
	door_pivot = Node3D.new()
	door_pivot.name = "BackDoor"
	door_pivot.position = Vector3(50.5, F0, Z1 + 0.02)
	L.add_child(door_pivot)
	door_kit = GeoKit.new(door_pivot, "BackDoorLeaf")
	door_kit.box(Vector3(-0.5, 1.05, 0), Vector3(0.98, 2.08, 0.05), "l160_door")
	door_kit.cylinder(Vector3(-0.88, 1.0, -0.05), 0.03, 0.06, "l160_chain", 10, false)
	door_kit.commit()


func _tableware() -> void:
	# a white cloth, a tureen and six bowls of her soup, steam-warm
	var c := Vector3(46.9, F0 + 0.885, 10.0)
	k.box(c + Vector3(0, 0.005, 0), Vector3(1.3, 0.01, 2.2), "l160_cloth", GeoKit.ALL, false)
	k.cylinder(c + Vector3(0, 0.1, 0), 0.16, 0.18, "l160_ceramic", 16, false)
	k.cylinder(c + Vector3(0, 0.2, 0), 0.06, 0.03, "l160_ceramic", 10, false)
	for i in 6:
		var side := -1.0 if i < 3 else 1.0
		var p := c + Vector3(side * 0.42, 0.035, -0.7 + float(i % 3) * 0.7)
		k.cylinder(p, 0.12, 0.06, "l160_ceramic", 14, false)
		k.cylinder(p + Vector3(0, 0.02, 0), 0.1, 0.03, "l160_soup", 14, false)
		k.box(p + Vector3(side * -0.18, -0.025, 0), Vector3(0.02, 0.01, 0.17), "l160_chain", GeoKit.ALL, false)
