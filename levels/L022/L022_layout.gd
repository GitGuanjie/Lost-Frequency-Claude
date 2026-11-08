extends RefCounted
## Level 22 authored layout: what lies where on decks A (y 0, census Floor 8), B (y 3,
## Floor 9, concrete miners) and C (y 6, Floor 10), the exits, arrivals and notes.

const S := preload("res://levels/L022/L022_struct.gd")

const NOCLIP_CAR := Vector3(6.0, 3.0, 4.0)
const ROPE := Vector3(22.0, 6.0, -4.0)
const L069_CAR := Vector3(-2.0, 0.0, 12.0)


static func place(L, D) -> void:
	_litter(L, D)
	_perimeter(L, D)
	_deck_a(L, D)
	_deck_b(L, D)
	_deck_c(L, D)
	_bay_lines(L, D)


## Collapse rubble chokes every edge of the slice; past it the decks carry on into the dark.
static func _perimeter(_L, D) -> void:
	for y in [0.0, 3.0, 6.0]:
		var x := -18.0
		while x <= 30.0:
			D.rubble(Vector3(x, y, -23.0), Vector3(4.4, 1.9, 2.0), true, 12)
			x += 4.0
		x = -30.0
		while x <= 30.0:
			D.rubble(Vector3(x, y, 23.0), Vector3(4.4, 1.9, 2.0), true, 12)
			x += 4.0
		var z := -14.0
		while z <= 22.0:
			D.rubble(Vector3(-31.0, y, z), Vector3(2.0, 1.9, 4.4), true, 12)
			z += 4.0
		z = -22.0
		while z <= 22.0:
			D.rubble(Vector3(31.0, y, z), Vector3(2.0, 1.9, 4.4), true, 12)
			z += 4.0
		# beyond: a few dead husks and heaps on the decks you cannot reach
		D.rubble(Vector3(-38.0, y, 6.0), Vector3(5.0, 2.3, 6.0), false, 14)
		D.rubble(Vector3(39.0, y, -10.0), Vector3(6.0, 2.4, 5.0), false, 14)
		D.rubble(Vector3(10.0, y, 31.0), Vector3(7.0, 2.6, 5.0), false, 14)


static func _hole_fringe(D, r: Rect2, y: float, skip_side: int) -> void:
	for side in 4:
		if side == skip_side:
			continue
		var n := int((r.size.x if side < 2 else r.size.y) / 0.9)
		for i in n:
			var t := (float(i) + 0.5) / n
			var p: Vector3
			var into: Vector3
			match side:
				0: p = Vector3(r.position.x + t * r.size.x, y - 0.15, r.position.y); into = Vector3(0, 0, 1)
				1: p = Vector3(r.position.x + t * r.size.x, y - 0.15, r.end.y); into = Vector3(0, 0, -1)
				2: p = Vector3(r.position.x, y - 0.15, r.position.y + t * r.size.y); into = Vector3(1, 0, 0)
				_: p = Vector3(r.end.x, y - 0.15, r.position.y + t * r.size.y); into = Vector3(-1, 0, 0)
			D.rebar(p, (into + Vector3(D.r.randf_range(-0.3, 0.3), D.r.randf_range(-0.5, 0.15), D.r.randf_range(-0.3, 0.3))).normalized(), D.r.randf_range(0.3, 1.1))
			if D.r.randf() < 0.35:
				D.v.box_xf(D._xf(p + into * 0.25 + Vector3(0, 0.05, 0), D.r.randf() * TAU, D.r.randf_range(-0.4, 0.4), 0.2), Vector3(0.6, 0.18, 0.5), "l22_rubble", GeoKit.ALL, false)


static func _deck_a(L, D) -> void:
	var y := 0.0
	var root: Node3D = L.props_root
	# the slab that fell through from deck B: rubble, a crushed car, girder poles
	L.rubble_pile(Vector3(-19.0, y, -9.5), Vector3(9.0, 2.6, 8.0), true)
	D.car(Vector3(-15.5, y, -5.2), 0.5, 2)
	D.girder(Vector3(-23.5, y + 0.1, -12.5), Vector3(-15.5, y + 2.5, -8.0))
	D.girder(Vector3(-22.0, y + 0.1, -6.0), Vector3(-17.0, y + 2.6, -11.5))
	# the deep mining shaft (approach from the south and west is clear)
	_hole_fringe(D, S.SHAFT, y, 0)
	D.rubble(Vector3(-11.5, y, 11.6), Vector3(6.0, 0.7, 1.6), false, 10)
	Props.place(L, root, "ph/wooden_ladder", Vector3(-17.4, y, 12.4), 80.0)
	Props.place(L, root, "kenney/graveyard-kit/shovel", Vector3(-16.6, y, 10.6), 30.0, 1.05)
	Props.place(L, root, "kenney/graveyard-kit/shovel", Vector3(-6.4, y, 11.4), 200.0, 1.05)
	Props.place(L, root, "ph/wooden_crate_01", Vector3(-18.2, y, 9.4), 15.0)
	Props.place(L, root, "ph/plastic_crate_01", Vector3(-17.6, y, 8.4), 40.0)
	for i in 7:
		D.v.box_xf(D._xf(Vector3(-5.5 + (i % 3) * 0.55, y + 0.15 + int(i / 3) * 0.3, 7.2), D.r.randf_range(-0.2, 0.2)), Vector3(0.5, 0.3, 0.4), "l22_minedblock", GeoKit.ALL, false)
	# people slept in the open down here
	for b in [[Vector3(2.0, y, -8.0), 0.2, "l22_bag"], [Vector3(3.2, y, -8.9), 0.1, "l22_bag2"], [Vector3(4.5, y, -7.6), 0.35, "l22_bag"],
			[Vector3(10.0, y, -10.4), 1.4, "l22_bag2"], [Vector3(-3.0, y, -16.0), 1.6, "l22_bag"]]:
		D.sleeping_bag(b[0], b[1], b[2])
	Props.place(L, root, "ph/Barrel_01", Vector3(6.2, y, -6.0), 0.0, 0.0, true)
	Props.place(L, root, "ph/trashbag", Vector3(5.6, y, -9.8), 40.0)
	Props.place(L, root, "ph/cardboard_box_01", Vector3(1.0, y, -9.6), 10.0)
	Props.place(L, root, "ph/plastic_bottle_gallon", Vector3(3.9, y, -9.7), 0.0)
	Props.place(L, root, "kenney/food-kit/can-open", Vector3(2.6, y, -7.0), 0.0, 0.12)
	for t in [[Vector3(-22.0, y, 16.0), Color(0.42, 0.42, 0.36), true, false], [Vector3(-18.5, y, 18.8), Color(0.36, 0.4, 0.3), true, true],
			[Vector3(18.0, y, -17.0), Color(0.45, 0.32, 0.22), true, false], [Vector3(22.0, y, -18.0), Color(0.3, 0.36, 0.42), false, true]]:
		_tent(L, D, t[0], 0.0, t[1], t[2], t[3])
	D.car(Vector3(22.0, y, 12.0), 0.0, 0)
	D.car(Vector3(26.0, y, -12.0), PI, 1)
	D.car(Vector3(12.0, y, -12.0), 0.05, 0)
	D.car(Vector3(-26.0, y, -3.0), PI * 0.5, 1)
	D.car(L069_CAR, 0.0, 3)
	D.trolley(Vector3(8.0, y, -2.0), 0.4, true)
	D.trolley(Vector3(9.4, y, -1.4), 1.1, false)
	D.trolley(Vector3(-6.0, y, 19.0), 2.0, true)
	D.trolley(Vector3(14.0, y, 4.0), 0.2, false)
	L.rubble_pile(Vector3(4.0, y, 4.0), Vector3(3.0, 0.9, 2.4), false)
	L.rubble_pile(Vector3(18.0, y, 4.0), Vector3(2.2, 0.6, 3.0), false)
	for f in [[4, -4, 1], [-4, 12, 2], [12, 4, 2], [-20, 4, 1], [20, -12, 0], [-4, -12, 2], [28, 4, 1], [4, 20, 0], [-12, -20, 2], [-12, 4, 0]]:
		D.fixture(Vector3(f[0], y + S.FLOOR - S.SLAB, f[1]), f[2])


static func _deck_b(L, D) -> void:
	var y := 3.0
	var root: Node3D = L.props_root
	_hole_fringe(D, S.COLLAPSE_B, y, -1)
	D.girder(Vector3(-25.0, y + 0.05, -10.5), Vector3(-13.0, y + 0.3, -8.0))
	# rails round the ramp slot (north, south, west); the east end is where the ramp lands
	var rs := S.RAMP_SLOT
	D.k.box_mm(Vector3(rs.position.x, y, rs.position.y - 0.08), Vector3(rs.end.x, y + 1.0, rs.position.y), "l22_rust", GeoKit.ALL, true)
	D.k.box_mm(Vector3(rs.position.x, y, rs.end.y), Vector3(rs.end.x, y + 1.0, rs.end.y + 0.08), "l22_rust", GeoKit.ALL, true)
	D.k.box_mm(Vector3(rs.position.x - 0.08, y, rs.position.y), Vector3(rs.position.x, y + 1.0, rs.end.y), "l22_rust", GeoKit.ALL, true)
	# shacks of wood and of mined concrete
	D.shack(Vector3(-14.0, y, -20.0), 0.0, false)
	D.shack(Vector3(-9.5, y, -20.0), 0.0, true)
	D.shack(Vector3(-5.0, y, -20.2), 0.08, false, 2.6, 2.2)
	D.shack(Vector3(-18.0, y, 19.0), PI, true)
	D.shack(Vector3(-13.5, y, 19.4), PI - 0.06, false)
	Props.place(L, root, "kenney/furniture-kit/kitchenstoveelectric", Vector3(-12.0, y, -17.9), 0.0, 0.9)
	Props.place(L, root, "kenney/food-kit/pot-stew", Vector3(-12.1, y + 0.9, -17.9), 20.0, 0.2)
	Props.place(L, root, "ph/SchoolDesk_01", Vector3(-10.4, y, -16.6), 90.0)
	Props.place(L, root, "ph/dining_chair_02", Vector3(-10.4, y, -15.8), 200.0)
	Props.place(L, root, "ph/plastic_monobloc_chair_01", Vector3(-9.3, y, -16.9), 260.0)
	Props.place(L, root, "kenney/food-kit/plate-broken", Vector3(-10.6, y + 0.88, -16.5), 0.0, 0.03)
	Props.place(L, root, "ph/wooden_crate_01", Vector3(-7.2, y, -17.4), 80.0)
	Props.place(L, root, "ph/propane_tank", Vector3(-12.9, y, -17.6), 0.0)
	Props.place(L, root, "ph/old_bed_frame", Vector3(-19.6, y, 16.0), 90.0)
	Props.place(L, root, "ph/vintage_suitcase", Vector3(-15.8, y, 16.6), 30.0)
	Props.place(L, root, "ph/Barrel_01", Vector3(-16.0, y, 21.0), 0.0, 0.0, true)
	# a washing line strung between two columns
	D.v.box_mm(Vector3(-16.0, y + 1.92, -0.01), Vector3(-8.0, y + 1.94, 0.01), "l22_dark", GeoKit.ALL, false)
	for i in 6:
		var x: float = -15.0 + i * 1.2 + D.r.randf_range(-0.2, 0.2)
		D.v.box_xf(D._xf(Vector3(x, y + 1.6, 0.0), D.r.randf_range(-0.1, 0.1)), Vector3(D.r.randf_range(0.4, 0.8), D.r.randf_range(0.5, 0.75), 0.02), "l22_cloth" if i % 2 == 0 else "l22_bag2", GeoKit.ALL, false)
	for t in [[Vector3(-6.0, y, 10.0), Color(0.22, 0.32, 0.5), false, false], [Vector3(-3.0, y, 10.6), Color(0.26, 0.4, 0.26), false, false],
			[Vector3(0.2, y, 9.6), Color(0.6, 0.36, 0.16), true, false], [Vector3(-8.6, y, 13.8), Color(0.4, 0.4, 0.28), false, true]]:
		_tent(L, D, t[0], 0.15, t[1], t[2], t[3])
	Props.place(L, root, "kenney/graveyard-kit/lantern-glass", Vector3(-4.4, y, 9.0), 0.0, 0.3)
	L.lights.add_anchor(Vector3(-4.4, y + 0.4, 9.0), Color(1.0, 0.7, 0.4), 0.6, 4.0, 0.15, "lamp")
	D.car(NOCLIP_CAR, 0.25, 0)
	D.car(Vector3(20.0, y, -12.0), 0.0, 1)
	D.car(Vector3(12.0, y, 10.5), PI * 0.5, 0)
	D.car(Vector3(-28.0, y, 4.0), 0.0, 2)
	D.trolley(Vector3(2.0, y, -2.0), 0.7, false)
	D.trolley(Vector3(14.0, y, -6.0), 2.3, true)
	# the fallen deck-C slab: rubble along its sides
	var dr := S.DEBRIS
	L.rubble_pile(Vector3(dr.position.x + 0.6, y, dr.position.y + dr.size.y * 0.55), Vector3(1.4, 1.4, dr.size.y * 0.9), false)
	L.rubble_pile(Vector3(dr.end.x - 0.6, y, dr.position.y + dr.size.y * 0.55), Vector3(1.4, 1.8, dr.size.y * 0.9), false)
	D.girder(Vector3(dr.end.x - 0.4, y + 0.1, dr.position.y + 1.0), Vector3(dr.end.x - 1.2, y + 3.0, dr.end.y - 0.5))
	for f in [[-4, -4, 2], [12, -4, 1], [-20, 12, 1], [4, 12, 2], [20, 4, 0], [-12, 4, 2], [28, -20, 0], [-4, 20, 2], [-12, -12, 1], [4, -12, 2]]:
		D.fixture(Vector3(f[0], y + S.FLOOR - S.SLAB, f[1]), f[2])


static func _deck_c(L, D) -> void:
	var y := 6.0
	var root: Node3D = L.props_root
	_hole_fringe(D, S.DEBRIS, y, 1)
	_hole_fringe(D, S.ROOF_HOLE, y + 3.0, -1)
	# chunks of the roof that came down, a car crushed beneath one
	L.rubble_pile(Vector3(-6.0, y, -4.0), Vector3(6.0, 2.2, 5.0), true)
	L.rubble_pile(Vector3(14.0, y, 14.0), Vector3(5.0, 1.8, 4.0), true)
	L.rubble_pile(Vector3(-12.0, y, -14.5), Vector3(4.0, 1.6, 3.4), true)
	D.car(Vector3(-12.0, y, -11.0), 0.2, 2)
	D.car(Vector3(20.0, y, 12.0), 0.0, 0)
	D.car(Vector3(-24.0, y, 12.0), PI, 1)
	D.car(Vector3(4.0, y, 12.0), -0.1, 0)
	D.girder(Vector3(-9.0, y + 0.1, -1.5), Vector3(-4.0, y + 2.6, -6.0))
	D.girder(Vector3(10.0, y + 0.1, 16.0), Vector3(16.0, y + 2.5, 11.0))
	D.girder(Vector3(-20.0, y + 0.05, -4.0), Vector3(-26.0, y + 0.3, 2.0), true)
	L.rough_zones.append(AABB(Vector3(-27.0, y - 0.2, -5.0), Vector3(8.0, 1.0, 8.0)))
	for t in [[Vector3(-20.0, y, 4.0), Color(0.42, 0.38, 0.3), true, false], [Vector3(-16.8, y, 6.4), Color(0.3, 0.3, 0.36), false, false]]:
		_tent(L, D, t[0], -0.2, t[1], t[2], t[3])
	Props.place(L, root, "ph/wooden_crate_01", Vector3(-14.8, y, 4.0), 60.0)
	Props.place(L, root, "kenney/graveyard-kit/debris-wood", Vector3(-15.5, y, 2.5), 10.0, 0.12)
	Props.place(L, root, "ph/metal_tool_chest", Vector3(8.0, y, -6.0), 30.0)
	Props.place(L, root, "ph/concrete_road_barrier", Vector3(0.0, y, 0.0), 90.0)
	# the hole through the roof, a rope hanging down it, grey light from above
	D.rubble(ROPE + Vector3(1.6, 0, 1.4), Vector3(1.6, 0.6, 1.4), false, 6)
	D.rubble(ROPE + Vector3(-1.8, 0, -1.2), Vector3(1.4, 0.5, 1.8), false, 6)
	for f in [[-4, 4, 2], [12, -4, 1], [-20, -12, 0], [20, 4, 1], [-12, 20, 0], [28, -12, 2], [4, -12, 2]]:
		D.fixture(Vector3(f[0], y + S.FLOOR - S.SLAB, f[1]), f[2])


static func _tent(L, D, p: Vector3, yaw: float, col: Color, occupied: bool, collapsed: bool) -> void:
	D.tent(p, yaw, col, occupied, collapsed)
	if occupied:
		L.add_interactable(p + Vector3(0, 0.6, 0), Vector3(1.8, 1.2, 2.4), "Look inside the tent", func(_p = null) -> void:
			Overlay.subtitle("[a sleeping bag, zipped to the top, and a smell long gone stale. Whoever is inside has not moved in years.]", 4.5))


## The ground is littered with broken concrete, grit and scraps on every deck.
static func _litter(L, D) -> void:
	for y in [0.0, 3.0, 6.0]:
		for i in 260:
			var p: Vector3 = Vector3(D.r.randf_range(S.X0 + 2.5, S.X1 - 2.5), y, D.r.randf_range(S.Z0 + 2.5, S.Z1 - 2.5))
			var skip := false
			for h in S.holes_for(int(y / 3.0)) + [S.CORE]:
				if (h as Rect2).grow(0.6).has_point(Vector2(p.x, p.z)):
					skip = true
			if skip:
				continue
			var big: bool = D.r.randf() < 0.18
			var sz: Vector3 = Vector3(D.r.randf_range(0.08, 0.3), D.r.randf_range(0.04, 0.12), D.r.randf_range(0.08, 0.3)) * (2.4 if big else 1.0)
			D.v.box_xf(D._xf(p + Vector3(0, sz.y * 0.3, 0), D.r.randf() * TAU, D.r.randf_range(-0.3, 0.3), D.r.randf_range(-0.3, 0.3)), sz, "l22_rubble", GeoKit.ALL, false)
			if D.r.randf() < 0.12:
				D.v.box_xf(D._xf(p + Vector3(0.4, 0.004, 0.3), D.r.randf() * TAU), Vector3(0.21, 0.004, 0.28), "paper", GeoKit.PY, false)
			if D.r.randf() < 0.06:
				D.rebar(p + Vector3(0, 0.05, 0), Vector3(D.r.randf_range(-1, 1), 0.05, D.r.randf_range(-1, 1)).normalized(), D.r.randf_range(0.6, 2.2))
		# a few more fallen ceiling pieces and girder poles across each deck
		for j in 5:
			var c: Vector3 = Vector3(D.r.randf_range(-24.0, 26.0), y, D.r.randf_range(-18.0, 18.0))
			var ok := true
			for h in S.holes_for(int(y / 3.0)) + [S.CORE, S.SHAFT]:
				if (h as Rect2).grow(3.0).has_point(Vector2(c.x, c.z)):
					ok = false
			if not ok:
				continue
			L.rubble_pile(c, Vector3(D.r.randf_range(1.6, 3.0), D.r.randf_range(0.4, 1.0), D.r.randf_range(1.4, 2.6)), false)
			if j % 2 == 0:
				var d: Vector3 = Vector3(D.r.randf_range(-1, 1), 0, D.r.randf_range(-1, 1)).normalized()
				D.girder(c - d * 2.5 + Vector3(0, 0.1, 0), c + d * 2.5 + Vector3(0, D.r.randf_range(0.1, 1.6), 0))


## Painted parking bays along the north and south rows of each deck.
static func _bay_lines(_L, D) -> void:
	for y in [0.0, 3.0, 6.0]:
		for row in [-12.0, 12.0]:
			var x := -22.5
			while x <= 30.0:
				D.v.box(Vector3(x, y + 0.004, row), Vector3(0.1, 0.008, 4.6), "l22_paint", GeoKit.PY, false)
				x += 2.5


static func exits_and_arrivals(L) -> void:
	var c := S.SHAFT.get_center()
	var shaft: ExitTrigger = L.add_exit("L022>L023#2", "fall", Vector3(c.x, -4.8, c.y), Vector3(S.SHAFT.size.x + 0.4, 10.4, S.SHAFT.size.y + 0.4), "")
	shaft.fall_y = -3.5
	var lv := LadderVolume.new()
	lv.name = "RoofRope"
	L.add_child(lv)
	lv.setup(ROPE + Vector3(-0.7, 0.0, -0.7), ROPE + Vector3(0.7, 6.5, 0.7))
	var up: ExitTrigger = L.add_exit("L022>L021#1", "walk_in", ROPE + Vector3(0, 2.5, 0), Vector3(4.6, 5.0, 4.6), "Climb the rope up through the hole")
	up.condition = func() -> bool: return L.player != null and L.player.global_position.y > ROPE.y + 2.0
	var nc: ExitTrigger = L.add_exit("L022>L817#3", "noclip", NOCLIP_CAR + Vector3(0, 0.9, 0), Vector3(2.6, 1.9, 5.8), "")
	nc.hold_seconds = 3.0
	var rope := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.025
	cm.bottom_radius = 0.025
	cm.height = 10.0
	cm.radial_segments = 6
	rope.mesh = cm
	rope.material_override = MatLib.standard(Color(0.45, 0.38, 0.26), 0.95)
	L.add_child(rope)
	rope.global_position = ROPE + Vector3(0, 5.0, 0)
	var sky := kit_box(L)
	sky.box(Vector3(ROPE.x, S.DECKS[3] + 6.9, ROPE.z), Vector3(5.0, 0.1, 5.0), "l22_daylight", GeoKit.NY, false)
	sky.commit()
	var sp := SpotLight3D.new()
	sp.light_color = Color(0.82, 0.86, 0.9)
	sp.light_energy = 3.0
	sp.spot_range = 16.0
	sp.spot_angle = 28.0
	sp.shadow_enabled = false
	L.add_child(sp)
	sp.global_transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(ROPE.x, S.DECKS[3] + 6.0, ROPE.z))
	# arrivals
	var door: Vector3 = L.glass_door_at
	L.add_arrival("start", door + Vector3(1.6, 0.02, 0.2), -70.0)
	L.add_arrival("from_L001", door + Vector3(1.6, 0.02, 0.2), -70.0)
	L.add_arrival("from_L069", L069_CAR + Vector3(2.2, 0.02, -0.6), -95.0)
	L.add_landmark("Glass doors of the stair core (deck B)", door)
	L.add_landmark("Mining shaft (to Level 23)", Vector3(c.x, 0, c.y))
	L.add_landmark("Rope up through the roof (to Level 21)", ROPE)
	L.add_landmark("Fallen deck: debris ramp B to C", Vector3(7.5, 4.5, -16.0))
	L.add_landmark("Car ramp A to B", Vector3(17.5, 1.5, 18.0))
	L.add_note("l22_meg", "M.E.G. notice taped inside the glass doors",
		"LEVEL 22 - \"RUINS LEFT BEHIND\"\nOnce an ordinary multi-storey car park full of cars and shopping trolleys. Declared the micronation of Emstable in 1987 and sealed off by 1990. It traded with the M.E.G. (2012) and the B.N.T.G. (2016) but let almost no one in.\nFamilies each worked a floor and sent a share of what they made to the floor above. The top floor lived well; below the 16th, people starved and slept in the open.\nThey mined the concrete itself. Walls, pillars and floors weakened until the place came down. No community has formed here since.\n\nWALK SLOWLY: rubble, rebar and girders everywhere. The holes are mining holes and very deep. Climbing them is heavily unadvised - deaths are on record. Tents may still hold the dead.",
		door + Vector3(-0.3, 1.3, 1.6), Vector3(0.15, 0.4, 0.4), false)
	L.add_note("l22_hilda", "Diary pages (\"Hilda\", copy - the original is with the Kalag Institute)",
		"02/08/14 - Today could be the day, Hilda. Janus, Heljan and I have been mining concrete with the new picks from the traders on the other level. Floor 20 says that if we send enough concrete for them and the floors above, my family can move up.\n\n06/08/14 - Four days of mining without a break. We trade away as little as we can, just enough for Tia to eat. Grey can't stop telling her about the new floor. People say we'll never make it. Aiden, Kellaby and Raven still try to talk me out of it.\n\n30/10/15 - Another batch of concrete to send up; Raven is carrying it for me. Grey and Tia have their fancy place up in the highs now, with Heljan. I don't know if they miss me, or if Heljan would let me visit. Probably not. But I will see you again, Tia.",
		Vector3(-3.0, 3.06, 11.9), Vector3(0.4, 0.08, 0.3))
	L.add_interactable(Vector3(c.x, 0.6, S.SHAFT.position.y - 0.6), Vector3(2.0, 1.2, 0.8), "Look down the hole", func(_p = null) -> void:
		Overlay.subtitle("[the hole drops past the slab into rough rock and dark. Pick marks on the edges. Somewhere below, a draught.]", 4.5))


static func kit_box(L) -> GeoKit:
	return L.kit("RoofLight")
