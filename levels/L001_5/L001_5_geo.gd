extends RefCounted
## Level 1.5 "Inverted": layout and dressing (design notes in L001_5.gd).
## Blank white rooms and halls on two heights: an arrival room, the long hall of
## Figure 1, a west wing (an office, an upside-down room, a room whose window
## shows a mirror of itself) and a double-height hall with a gallery at +3 m
## ("somewhere between floors") whose landing window looks outside.

const H := 2.8
const HG := 6.0
const GAL_Y := 3.0
const T := 0.2

var lvl
var rng: RandomNumberGenerator
var k: GeoKit
var root: Node3D
var fixtures: Array = []      # [pos, range, energy, facing_up]
var windows: Array = []       # {pos, normal, kind}
var fracture_spots: Array = []  # candidate noclip walls {center, normal}
var props := 0


func _init(level) -> void:
	lvl = level
	rng = level.rng


func p(id: String, pos: Vector3, yaw: float = 0.0, h: float = 0.0, collide: bool = false) -> Node3D:
	var n: Node3D = Props.place(lvl, root, id, pos, yaw, h, collide)
	if n:
		props += 1
	return n


## A model hung upside down from the ceiling at height y.
func flipped(id: String, x: float, z: float, y: float, yaw: float, h: float = 0.0) -> void:
	var n := p(id, Vector3(x, y, z), yaw, h)
	if n:
		n.rotation = Vector3(PI, deg_to_rad(yaw), 0)


func build() -> void:
	root = Node3D.new()
	root.name = "Dressing"
	lvl.add_child(root)
	k = lvl.kit("L15_Shell")
	_shell()
	_fixtures()
	_dress()
	k.commit()


func _shell() -> void:
	# floors and ceilings
	k.box_mm(Vector3(-19.0, -0.3, -36.3), Vector3(14.3, 0.0, 0.3), "l15_floor")
	k.box_mm(Vector3(-4.2, H, -8.0), Vector3(4.2, H + 0.3, 0.2), "l15_ceiling")
	k.box_mm(Vector3(-18.8, H, -36.2), Vector3(1.5, H + 0.3, -8.0), "l15_ceiling")
	k.box_mm(Vector3(1.5, HG, -30.2), Vector3(14.2, HG + 0.3, -9.8), "l15_ceiling")
	var W := func(a: Vector2, b: Vector2, h: float, ops: Array = []) -> void:
		k.wall(Vector3(a.x, 0, a.y), Vector3(b.x, 0, b.y), h, T, "l15_wall", ops)
	# arrival room A
	W.call(Vector2(-4, 0), Vector2(4, 0), H)
	W.call(Vector2(-4, 0), Vector2(-4, -8), H)
	W.call(Vector2(4, 0), Vector2(4, -8), H)
	W.call(Vector2(-10, -8), Vector2(4, -8), H, [{"at": 10.0, "w": 3.0, "h": H}])
	# west wing outer wall, with R3's mirror window
	W.call(Vector2(-10, -8), Vector2(-10, -36), H, [{"at": 24.5, "w": 2.4, "h": 1.7, "sill": 0.55}])
	# the long hall H1: doors west to R1/R2/R3, east into the high hall G
	W.call(Vector2(-1.5, -8), Vector2(-1.5, -36), H, [{"at": 5.0, "w": 1.0, "h": 2.1}, {"at": 15.0, "w": 1.0, "h": 2.1}, {"at": 24.0, "w": 1.0, "h": 2.1}])
	W.call(Vector2(1.5, -8), Vector2(1.5, -36), HG, [{"at": 6.0, "w": 1.2, "h": 2.2}, {"at": 18.0, "w": 1.2, "h": 2.2}])
	W.call(Vector2(-10, -18), Vector2(-1.5, -18), H)
	W.call(Vector2(-10, -28), Vector2(-1.5, -28), H)
	W.call(Vector2(-18.8, -36), Vector2(1.5, -36), H)
	# high hall G
	W.call(Vector2(1.5, -10), Vector2(14, -10), HG)
	W.call(Vector2(1.5, -30), Vector2(14, -30), HG, [{"at": 10.75, "w": 1.6, "h": 1.3, "sill": GAL_Y + 0.9}])
	W.call(Vector2(14, -10), Vector2(14, -30), HG)
	# the mirrored copy of R3 seen through its window
	W.call(Vector2(-18.8, -28), Vector2(-18.8, -36), H)
	W.call(Vector2(-18.8, -28), Vector2(-10, -28), H)
	# gallery at +3 m, landing and stair along the south wall, railing
	k.box_mm(Vector3(10.5, GAL_Y - 0.3, -29.9), Vector3(13.9, GAL_Y, -10.1), "l15_floor")
	k.box_mm(Vector3(7.3, GAL_Y - 0.3, -12.3), Vector3(10.5, GAL_Y, -10.1), "l15_floor")
	k.stairs(Vector3(2.5, 0.0, -11.2), Vector3(1, 0, 0), 2.0, GAL_Y, 17, "l15_stair", 0.28)
	k.box_mm(Vector3(2.5, 0.0, -12.3), Vector3(7.3, GAL_Y - 0.3, -12.2), "l15_wall", GeoKit.ALL, false)
	for z in range(-12, -30, -2):
		k.box(Vector3(10.55, GAL_Y + 0.5, float(z) - 0.5), Vector3(0.05, 1.0, 0.05), "l15_rail", GeoKit.ALL, false)
	k.box(Vector3(10.55, GAL_Y + 1.02, -21.0), Vector3(0.07, 0.05, 17.9), "l15_rail")
	k.add_box_shape(Transform3D(Basis(), Vector3(10.55, GAL_Y + 0.55, -21.0)), Vector3(0.06, 1.1, 17.9), "metal")
	k.box(Vector3(8.9, GAL_Y + 1.02, -12.25), Vector3(3.2, 0.05, 0.07), "l15_rail")
	k.add_box_shape(Transform3D(Basis(), Vector3(8.9, GAL_Y + 0.55, -12.25)), Vector3(3.2, 1.1, 0.06), "metal")
	# windows: glass that stops you, frames, and what each one shows
	_window(Vector3(-10.0, 0.55, -32.5), Vector3(1, 0, 0), "mirror", 2.4, 1.7)
	_window(Vector3(12.25, GAL_Y + 0.9, -30.0), Vector3(0, 0, 1), "outside", 1.6, 1.3)
	# skirting along the main runs
	for run in [[Vector3(-1.4, 0, -8.2), Vector3(-1.4, 0, -35.8)], [Vector3(1.4, 0, -8.2), Vector3(1.4, 0, -35.8)]]:
		k.box_mm((run[0] as Vector3).min(run[1]) - Vector3(0.02, 0, 0), (run[0] as Vector3).max(run[1]) + Vector3(0.02, 0.09, 0), "l15_skirt", GeoKit.ALL, false)
	# candidate shattered walls for the noclip exit
	fracture_spots = [
		{"c": Vector3(-1.5, 1.2, -10.4), "n": Vector3(1, 0, 0)},
		{"c": Vector3(14.0, 1.2, -20.0), "n": Vector3(-1, 0, 0)},
		{"c": Vector3(-6.0, 1.2, -8.0), "n": Vector3(0, 0, -1)},
		{"c": Vector3(-10.0, 1.2, -22.0), "n": Vector3(1, 0, 0)},
	]


func _window(base: Vector3, n: Vector3, kind: String, w: float, h: float) -> void:
	var along := Vector3(-n.z, 0, n.x)
	var bas := Basis(along, Vector3.UP, n)
	var c := base + Vector3(0, h * 0.5, 0)
	k.box_xf(Transform3D(bas, c + n * 0.12 + Vector3(0, -h * 0.5 - 0.03, 0)), Vector3(w + 0.2, 0.05, 0.14), "l15_frame", GeoKit.ALL, false)
	for sd in [-1.0, 1.0]:
		k.box_xf(Transform3D(bas, c + along * (sd * (w * 0.5 + 0.025))), Vector3(0.05, h + 0.1, T + 0.06), "l15_frame", GeoKit.ALL, false)
	k.box_xf(Transform3D(bas, c + Vector3(0, h * 0.5 + 0.025, 0)), Vector3(w + 0.1, 0.05, T + 0.06), "l15_frame", GeoKit.ALL, false)
	k.box_xf(Transform3D(bas, c), Vector3(0.035, h, 0.035), "l15_frame", GeoKit.ALL, false)
	k.box_xf(Transform3D(bas, c), Vector3(w, 0.035, 0.035), "l15_frame", GeoKit.ALL, false)
	k.box_xf(Transform3D(bas, c - n * 0.02), Vector3(w, h, 0.01), "glass", GeoKit.ALL, false)
	k.add_box_shape(Transform3D(bas, c), Vector3(w, h, 0.1), "tile")
	if kind == "outside":
		# daylight beyond: pale sky over a grey horizon, set back so it has depth
		k.box_xf(Transform3D(bas, c - n * 3.0 + Vector3(0, 0.35, 0)), Vector3(6.0, 2.2, 0.05), "l15_sky", GeoKit.ALL, false)
		k.box_xf(Transform3D(bas, c - n * 2.95 + Vector3(0, -0.8, 0)), Vector3(6.0, 0.9, 0.05), "l15_ground", GeoKit.ALL, false)
		for sd in [-1.0, 1.0]:
			k.box_xf(Transform3D(bas, c - n * 1.5 + along * (sd * 1.4)), Vector3(0.05, 3.0, 3.0), "l15_wall", GeoKit.ALL, false)
	windows.append({"pos": c, "normal": n, "kind": kind})


func _fixtures() -> void:
	var F := func(pos: Vector3, rng_m: float, e: float, up: bool = false) -> void:
		var s := 1.0 if not up else -1.0
		k.box(pos + Vector3(0, -0.02 * s, 0), Vector3(0.66, 0.05, 1.26), "l15_fixture", GeoKit.ALL, false)
		k.box(pos + Vector3(0, -0.05 * s, 0), Vector3(0.58, 0.012, 1.18), "l15_dark", GeoKit.ALL, false)
		fixtures.append([pos + Vector3(0, -0.75 * s, 0), rng_m, e, up])
	F.call(Vector3(0, H, -2.5), 4.5, 1.5)
	F.call(Vector3(0, H, -5.8), 4.5, 1.5)
	var z := -10.0
	while z > -35.0:
		F.call(Vector3(0, H, z), 4.2, 1.5)
		z -= 4.0
	for c in [Vector3(-5.8, H, -11.0), Vector3(-5.8, H, -15.0), Vector3(-5.8, H, -32.0), Vector3(-14.2, H, -32.0)]:
		F.call(c, 4.5, 1.5)
	for gx in [4.5, 8.0]:
		for gz in [-13.0, -18.0, -23.0, -28.0]:
			F.call(Vector3(gx, HG, gz), 7.0, 2.0)
	for gz in [-15.0, -25.0]:
		F.call(Vector3(12.2, HG, gz), 5.5, 1.6)
	# the upside-down room: its fixture lies on the floor and pours darkness upward
	F.call(Vector3(-5.8, 0.0, -23.0), 4.0, 1.6, true)


func _dress() -> void:
	# R1: a vacated office
	p("ph/metal_office_desk", Vector3(-6.5, 0, -12.0), 0.0, 0.0, true)
	p("ph/SchoolChair_01", Vector3(-6.2, 0, -11.1), 200.0)
	p("kenney/furniture-kit/coatrackstanding", Vector3(-9.4, 0, -9.0), 0.0, 1.75)
	p("ph/drawer_cabinet", Vector3(-9.6, 0, -15.5), 90.0, 1.3, true)
	p("ph/cardboard_box_01", Vector3(-3.0, 0, -17.2), 20.0)
	p("ph/wall_clock", Vector3(-5.5, 2.1, -17.88), 0.0)
	# R2: upside down - desk, chair, cabinet and clock hang from the ceiling
	flipped("ph/metal_office_desk", -6.0, -21.5, H, 0.0)
	flipped("ph/SchoolChair_01", -6.3, -20.6, H, 180.0)
	flipped("ph/drawer_cabinet", -9.6, -25.0, H, 90.0, 1.3)
	flipped("ph/Shelf_01", -2.1, -26.0, H, -90.0)
	flipped("ph/wooden_crate_01", -4.0, -27.0, H, 10.0)
	var wc := p("ph/wall_clock", Vector3(-5.5, 0.6, -18.12), 180.0)
	if wc:
		wc.rotation = Vector3(0, PI, PI)
	# R3 and its mirror image beyond the window (x' = -20 - x)
	for side in [1.0, -1.0]:
		var X := func(x: float) -> float: return x if side > 0 else -20.0 - x
		var yaw_f := 1.0 if side > 0 else -1.0
		p("ph/ArmChair_01", Vector3(X.call(-7.6), 0, -30.0), yaw_f * 150.0)
		p("ph/ArmChair_01", Vector3(X.call(-8.4), 0, -33.4), yaw_f * 70.0)
		p("kenney/furniture-kit/pottedplant", Vector3(X.call(-9.4), 0, -31.0), 0.0, 1.3)
		p("ph/wall_clock", Vector3(X.call(-5.0), 2.1, -35.88), 0.0)
		p("ph/coffee_table_round_01", Vector3(X.call(-6.0), 0, -31.4), 0.0, 0.42, side > 0)
		p("kenney/furniture-kit/cabinettelevision", Vector3(X.call(-4.0), 0, -35.5), 0.0, 0.55)
		p("ph/Television_01", Vector3(X.call(-4.0), 0.55, -35.5), 0.0)
		p("kenney/furniture-kit/pottedplant", Vector3(X.call(-2.2), 0, -28.6), 0.0, 1.2)
	# the high hall: a few chairs facing the wall, a ladder left behind
	for i in 5:
		p("ph/plastic_monobloc_chair_01", Vector3(13.0 - (i % 2) * 0.2, 0, -14.0 - i * 1.4), -90.0 + rng.randf_range(-8, 8))
	p("ph/wooden_ladder", Vector3(5.0, 0, -28.6), 180.0, 0.0, true)
	p("ph/plastic_monobloc_chair_01", Vector3(12.2, GAL_Y, -28.8), 180.0)
	# hall clutter: a chair on its side, a box, a lost flashlight
	var ch := p("ph/SchoolChair_01", Vector3(0.6, 0.25, -19.0), 70.0)
	if ch:
		ch.rotation = Vector3(0, deg_to_rad(70.0), PI * 0.5)
	p("ph/vintage_flashlight", Vector3(-0.7, 0, -27.4), 130.0)
	p("ph/cardboard_box_01", Vector3(-3.2, 0, -1.0), rng.randf() * 360.0)
	# mosaic of shattered reality: wall fragments hanging in the air of the hall
	for i in 14:
		var fz := rng.randf_range(-12.0, -34.0)
		var fx := rng.randf_range(-1.2, 1.2)
		var fy := rng.randf_range(0.5, 2.5)
		var b := Basis.from_euler(Vector3(rng.randf_range(-0.5, 0.5), rng.randf() * TAU, rng.randf_range(-0.5, 0.5)))
		k.box_xf(Transform3D(b, Vector3(fx, fy, fz)), Vector3(rng.randf_range(0.15, 0.5), rng.randf_range(0.15, 0.5), 0.02), "l15_wall" if i % 3 else "l15_floor", GeoKit.ALL, false)
	# seeded displaced wall tiles
	for i in 6:
		var z := rng.randf_range(-12.0, -34.0)
		var sd := -1.0 if rng.randf() < 0.5 else 1.0
		k.box(Vector3(sd * 1.38, rng.randf_range(0.4, 2.4), z), Vector3(0.04, 0.6, 0.6), "l15_wall")
