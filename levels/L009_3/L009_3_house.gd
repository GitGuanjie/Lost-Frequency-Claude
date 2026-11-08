extends RefCounted
## A tiny, rotten, rain-drenched wooden house on a hilltop (Level 9.3). Local frame:
## x across (-3.7..3.7), z from the front (0) to the back (11), floor top at y = 0.6.
## Front room open to the roof with a plank loft (second walkable height), a hallway
## along the right wall ending in a narrow bathroom (commode under a casement onto
## colossal trees), a store room with beams and furniture, and the weak back door.

const F := 0.6
const EAVE := 3.3
const RIDGE := 5.9
const HW := 3.7
const D := 11.0

var lvl: Node3D
var root: Node3D
var k: GeoKit
var r: RandomNumberGenerator


static func materials() -> void:
	MatLib.define("l93_plank", {"albedo_a": Color(0.25, 0.21, 0.16), "albedo_b": Color(0.18, 0.15, 0.11), "pattern": 3,
		"pattern_scale": Vector2(2.4, 0.17), "grout_width": 0.006, "grout_color": Color(0.06, 0.05, 0.04),
		"stain_amount": 0.65, "stain_color": Color(0.1, 0.12, 0.07), "stain_scale": 1.3, "wetness": 0.85,
		"grime_height": 0.7, "grime_color": Color(0.1, 0.11, 0.07), "roughness_a": 0.5, "roughness_b": 0.8}, "wood_floor")
	MatLib.define("l93_floor", {"albedo_a": Color(0.22, 0.17, 0.12), "albedo_b": Color(0.16, 0.12, 0.09), "wetness": 0.95,
		"stain_amount": 0.55, "stain_color": Color(0.08, 0.07, 0.05)}, "wood_floor")
	MatLib.define("l93_roof", {"albedo_a": Color(0.16, 0.16, 0.15), "albedo_b": Color(0.12, 0.12, 0.11), "pattern": 14,
		"pattern_scale": Vector2(0.32, 0.22), "grout_width": 0.02, "grout_color": Color(0.05, 0.05, 0.05), "stain_amount": 0.7,
		"stain_color": Color(0.12, 0.17, 0.08), "wetness": 0.8}, "concrete")
	MatLib.define("l93_beam", {"albedo_a": Color(0.3, 0.23, 0.15), "albedo_b": Color(0.22, 0.17, 0.11), "pattern": 3,
		"pattern_scale": Vector2(3.0, 0.5), "wetness": 0.8, "stain_amount": 0.5, "stain_color": Color(0.1, 0.1, 0.06)}, "wood_floor")
	MatLib.register("l93_puddle", MatLib.standard(Color(0.06, 0.06, 0.055), 0.03))
	var g := StandardMaterial3D.new()
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.albedo_color = Color(0.55, 0.6, 0.6, 0.22)
	g.roughness = 0.15
	MatLib.register("l93_glass", g)


func _init(level: Node3D, parent: Node3D, xf: Transform3D, seed_v: int) -> void:
	lvl = level
	root = Node3D.new()
	root.name = "House"
	root.transform = xf
	parent.add_child(root)
	k = GeoKit.new(root, "HouseGeo")
	r = RandomNumberGenerator.new()
	r.seed = seed_v


func w(a: Vector2, b: Vector2, ops: Array = [], h: float = EAVE - F) -> void:
	k.wall(Vector3(a.x, F, a.y), Vector3(b.x, F, b.y), h, 0.14, "l93_plank", ops)


func build() -> Dictionary:
	# foundation, floor, porch and steps
	k.box_mm(Vector3(-HW - 0.05, -0.7, -0.05), Vector3(HW + 0.05, F - 0.08, D + 0.05), "l93_cobble")
	k.slab(-HW, 0.0, HW, D, F, 0.1, "l93_floor")
	k.slab(-1.9, -1.9, 1.9, 0.0, F, 0.12, "l93_floor")
	k.box_mm(Vector3(-1.9, -0.6, -1.9), Vector3(1.9, F - 0.12, -1.7), "l93_beam")
	k.stairs(Vector3(0, 0.0, -2.8), Vector3(0, 0, 1), 1.3, F, 3, "l93_beam", 0.3)
	for px in [-1.8, 1.8]:
		k.box(Vector3(px, F + 1.3, -1.8), Vector3(0.14, 2.6, 0.14), "l93_beam")
	k.box(Vector3(0, EAVE - 0.05, -1.85), Vector3(4.0, 0.12, 0.2), "l93_beam", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.RIGHT, -0.3), Vector3(0, EAVE + 0.2, -1.0)), Vector3(4.3, 0.08, 2.3), "l93_roof", GeoKit.ALL, false)
	# exterior walls
	w(Vector2(-HW, 0), Vector2(HW, 0), [{"at": HW, "w": 0.95, "h": 2.05}, {"at": 1.2, "w": 0.9, "h": 1.0, "sill": 0.95}, {"at": 6.2, "w": 0.9, "h": 1.0, "sill": 0.95}])
	w(Vector2(-HW, D), Vector2(HW, D), [{"at": 1.7, "w": 0.9, "h": 2.0}, {"at": 6.7, "w": 0.6, "h": 0.7, "sill": 1.25}])
	w(Vector2(-HW, 0), Vector2(-HW, D), [{"at": 3.2, "w": 0.9, "h": 1.0, "sill": 0.95}, {"at": 8.6, "w": 0.9, "h": 1.0, "sill": 0.95}])
	w(Vector2(HW, 0), Vector2(HW, D), [{"at": 3.0, "w": 0.9, "h": 1.0, "sill": 0.95}])
	# interior partitions: front room | hallway (right) -> bathroom; store room (left)
	w(Vector2(-HW, 6.0), Vector2(HW, 6.0), [{"at": 6.7, "w": 0.9, "h": 2.05}])
	w(Vector2(2.3, 6.0), Vector2(2.3, D), [{"at": 1.3, "w": 0.9, "h": 2.05}])
	w(Vector2(2.3, 8.6), Vector2(HW, 8.6), [{"at": 0.7, "w": 0.8, "h": 2.0}])
	# window glass (dirty) and frames
	for gl in [[Vector3(-2.5, F + 1.45, 0.0), Vector3(0.9, 1.0, 0.02)], [Vector3(2.5, F + 1.45, 0.0), Vector3(0.9, 1.0, 0.02)],
			[Vector3(-HW, F + 1.45, 3.2), Vector3(0.02, 1.0, 0.9)], [Vector3(-HW, F + 1.45, 8.6), Vector3(0.02, 1.0, 0.9)],
			[Vector3(HW, F + 1.45, 3.0), Vector3(0.02, 1.0, 0.9)]]:
		k.box(gl[0], gl[1], "l93_glass", GeoKit.ALL, false)
	# casement over the commode: two hinged leaves, one ajar
	k.box(Vector3(3.15, F + 1.6, D), Vector3(0.28, 0.66, 0.02), "l93_glass", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.UP, 0.7), Vector3(2.75, F + 1.6, D - 0.1)), Vector3(0.28, 0.66, 0.02), "l93_glass", GeoKit.ALL, false)
	k.box(Vector3(3.0, F + 1.24, D - 0.1), Vector3(0.7, 0.05, 0.2), "l93_beam", GeoKit.ALL, false)
	# ceilings over the back half; the front room is open to the rafters
	k.slab(-HW, 6.0, HW, D, EAVE, 0.1, "l93_plank", GeoKit.ALL, "wood")
	_roof()
	# the plank loft over the front of the front room, reached by a steep stair
	k.slab(-HW + 0.1, 0.1, HW - 0.1, 2.4, F + 2.4, 0.14, "l93_floor")
	k.stairs(Vector3(-0.9, F, 5.28), Vector3(0, 0, -1), 0.8, 2.4, 12, "l93_beam", 0.24)
	for rx in [-3.2, -2.0, 0.6, 1.8, 3.0]:
		k.box(Vector3(rx, F + 2.85, 2.38), Vector3(0.06, 0.9, 0.06), "l93_beam", GeoKit.ALL, false)
	k.box(Vector3(-2.4, F + 3.28, 2.38), Vector3(2.4, 0.06, 0.06), "l93_beam", GeoKit.ALL, false)
	k.box(Vector3(1.8, F + 3.28, 2.38), Vector3(3.6, 0.06, 0.06), "l93_beam", GeoKit.ALL, false)
	_dress()
	k.commit()
	return {"exit_local": Vector3(-2.0, F + 1.0, D - 0.75), "door_local": Vector3(-2.0, F + 1.0, D), "toilet": Vector3(3.0, F, D - 0.45)}


func _roof() -> void:
	var run := HW + 0.35
	var rise := RIDGE - EAVE
	var ang := atan2(rise, run)
	var ln := sqrt(run * run + rise * rise)
	for sgn in [-1.0, 1.0]:
		var c := Vector3(sgn * run * 0.5, EAVE + rise * 0.5 + 0.08, D * 0.5)
		k.box_xf(Transform3D(Basis(Vector3(0, 0, 1), -sgn * ang), c), Vector3(ln + 0.1, 0.12, D + 0.6), "l93_roof")
	# gable ends: stepped plank courses up to the ridge (no openings)
	for z in [0.0, D]:
		var steps := 8
		for i in steps:
			var y0 := EAVE + rise * float(i) / steps
			var half := run * (1.0 - float(i) / steps) - 0.25
			if half > 0.1:
				k.box(Vector3(0, y0 + rise / steps * 0.5, z), Vector3(half * 2.0, rise / steps + 0.01, 0.14), "l93_plank", GeoKit.ALL, false)
	# rafters and a ridge beam over the open front room
	k.box(Vector3(0, RIDGE - 0.15, 3.0), Vector3(0.16, 0.2, 6.2), "l93_beam", GeoKit.ALL, false)
	for z in [0.8, 2.6, 4.4]:
		for sgn in [-1.0, 1.0]:
			k.box_xf(Transform3D(Basis(Vector3(0, 0, 1), -sgn * ang), Vector3(sgn * run * 0.5, EAVE + rise * 0.5 - 0.1, z)), Vector3(ln, 0.14, 0.1), "l93_beam", GeoKit.ALL, false)
		k.box(Vector3(0, EAVE + 0.05, z), Vector3(HW * 2.0, 0.14, 0.12), "l93_beam", GeoKit.ALL, false)


func _p(id: String, pos: Vector3, yaw: float = 0.0, h: float = 0.0, col: bool = false) -> Node3D:
	return Props.place(lvl, root, id, pos, yaw, h, col)


func _puddle(c: Vector3, s: float) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = s
	cm.bottom_radius = s
	cm.height = 0.004
	cm.radial_segments = 14
	mi.mesh = cm
	mi.material_override = MatLib.get_mat("l93_puddle")
	mi.position = c + Vector3(0, 0.004, 0)
	mi.scale = Vector3(1.0, 1.0, r.randf_range(0.5, 0.9))
	mi.rotation.y = r.randf() * TAU
	root.add_child(mi)


func _dress() -> void:
	# front room: a woodworker's clutter, everything soaked
	_p("ph/dining_table", Vector3(1.3, F, 3.2), 90.0, 0.0, true)
	_p("ph/dining_chair_02", Vector3(0.45, F, 3.0), -90.0 + r.randf_range(-15, 15))
	var ch := _p("ph/dining_chair_02", Vector3(2.4, F + 0.22, 4.6), 30.0)
	if ch:
		ch.rotation = Vector3(0, deg_to_rad(30.0), deg_to_rad(80.0))
	var top := F + 0.88
	for it in [["food-kit/pot", Vector3(1.0, top, 3.6), 0.18], ["food-kit/frying-pan", Vector3(1.5, top, 2.7), 0.06],
			["food-kit/plate", Vector3(1.2, top, 3.1), 0.03], ["food-kit/mug", Vector3(1.6, top, 3.4), 0.1],
			["food-kit/cutting-board", Vector3(1.05, top, 2.6), 0.03], ["food-kit/bowl", Vector3(1.55, top, 3.9), 0.07]]:
		_p("kenney/" + str(it[0]), it[1], r.randf_range(0, 360), it[2])
	_p("ph/wooden_bookshelf_worn", Vector3(HW - 0.32, F, 4.6), -90.0, 0.0, true)
	_p("kenney/furniture-kit/kitchencabinet", Vector3(-HW + 0.32, F, 3.9), 90.0, 0.9, true)
	_p("kenney/furniture-kit/kitchenstove", Vector3(-HW + 0.32, F, 4.75), 90.0, 0.9, true)
	_p("kenney/food-kit/pan-stew", Vector3(-HW + 0.32, F + 0.9, 4.75), 0.0, 0.12)
	_p("ph/drawer_cabinet", Vector3(-HW + 0.28, F, 1.2), 90.0, 0.0, true)
	_p("ph/wooden_crate_01", Vector3(-2.4, F, 0.5), 10.0, 0.0, true)
	_p("ph/plastic_bottle_gallon", Vector3(-2.2, F + 0.35, 0.5), 40.0)
	_p("ph/vintage_grandfather_clock_01", Vector3(HW - 0.3, F, 1.6), -90.0, 0.0, true)
	# loose beams leaning on the walls ("wooden beams, drenched")
	for b in [[Vector3(-3.4, F + 1.2, 5.6), 0.35, 0.0], [Vector3(3.3, F + 1.1, 5.7), -0.3, 0.0], [Vector3(-1.6, F + 1.1, 0.25), 0.0, 0.32]]:
		k.box_xf(Transform3D(Basis.from_euler(Vector3(b[2], 0, b[1])), b[0]), Vector3(0.14, 2.4, 0.12), "l93_beam", GeoKit.ALL, false)
	_p("ph/cardboard_box_01", Vector3(-0.6, F + 2.4, 1.0), 25.0)
	_p("ph/vintage_suitcase", Vector3(1.6, F + 2.4, 0.9), 0.0)
	_p("ph/wooden_crate_01", Vector3(2.8, F + 2.4, 1.2), 70.0)
	_puddle(Vector3(0.3, F, 1.6), 0.55)
	_puddle(Vector3(2.6, F, 5.2), 0.4)
	# hallway
	_p("kenney/furniture-kit/coatrackstanding", Vector3(3.4, F, 6.5), 0.0, 1.75)
	_p("ph/wall_clock", Vector3(HW - 0.04, F + 1.9, 7.6), -90.0)
	_puddle(Vector3(3.0, F, 7.4), 0.35)
	# bathroom: a narrow box; the commode under the casement at its end
	_p("kenney/furniture-kit/toilet", Vector3(3.0, F, D - 0.42), 180.0, 0.8, true)
	_p("kenney/furniture-kit/bathroomsink", Vector3(HW - 0.25, F, 9.3), -90.0, 0.85, true)
	_p("ph/ornate_mirror_01", Vector3(HW - 0.06, F + 1.45, 9.3), -90.0)
	_puddle(Vector3(3.0, F, 9.9), 0.3)
	# store room: beams, a stripped bed, tools
	_p("ph/old_bed_frame", Vector3(-HW + 0.5, F, 7.25), 0.0, 0.0, true)
	for i in 5:
		k.box(Vector3(0.4 + i * 0.05, F + 0.07 + i * 0.13, 10.4), Vector3(3.2, 0.12, 0.16), "l93_beam", GeoKit.ALL, false)
	k.box(Vector3(0.45, F + 0.35, 10.4), Vector3(3.3, 0.7, 0.4), "l93_beam", GeoKit.ALL, true)
	_p("ph/metal_tool_chest", Vector3(1.7, F, 6.5), 180.0, 0.0, true)
	_p("ph/wooden_ladder", Vector3(-0.6, F, 6.25), 0.0, 1.9)
	_p("ph/wooden_crate_01", Vector3(-0.2, F, 8.3), 35.0, 0.0, true)
	_p("ph/cardboard_box_01", Vector3(-0.15, F + 0.35, 8.3), 10.0)
	_p("ph/barrel_03", Vector3(1.8, F, 8.8), 0.0, 0.0, true)
	_puddle(Vector3(-1.5, F, 9.4), 0.6)
