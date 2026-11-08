extends RefCounted
## The page's four room types plus the occasional car room. ADAPTATION: one
## authored instance each, with real second levels (catwalks, mezzanine, walkway).

const U := Vector3(0, 1, 0)
const K := preload("res://levels/L003/L003_kit.gd")


static func _box_room(k: GeoKit, x0: float, z0: float, x1: float, z1: float, y: float, h: float, wall: String, floor_mat: String, ops: Dictionary) -> void:
	k.slab(x0 - 0.3, z0 - 0.3, x1 + 0.3, z1 + 0.3, y, 0.3, floor_mat)
	k.slab(x0 - 0.3, z0 - 0.3, x1 + 0.3, z1 + 0.3, y + h + 0.3, 0.3, "l3_ceiling")
	k.wall(Vector3(x0 - 0.15, y, z0 - 0.3), Vector3(x0 - 0.15, y, z1 + 0.3), h, 0.3, wall, ops.get("w", []))
	k.wall(Vector3(x1 + 0.15, y, z0 - 0.3), Vector3(x1 + 0.15, y, z1 + 0.3), h, 0.3, wall, ops.get("e", []))
	k.wall(Vector3(x0 - 0.3, y, z0 - 0.15), Vector3(x1 + 0.3, y, z0 - 0.15), h, 0.3, wall, ops.get("n", []))
	if ops.has("arch"):
		k.arch_wall(Vector3(x0 - 0.3, y, z1 + 0.15), Vector3(x1 + 0.3, y, z1 + 0.15), h, 0.3, wall, ops["arch"])
	else:
		k.wall(Vector3(x0 - 0.3, y, z1 + 0.15), Vector3(x1 + 0.3, y, z1 + 0.15), h, 0.3, wall, ops.get("s", []))


# ------------------------------------------------------------- car room

## "Occasionally, a room with a car inside may appear." Room behind the arrival
## hall's north wall; the plug that hides it is managed by L003_sys.gd.
static func car_room(lvl, k: GeoKit) -> void:
	k.slab(3.85, -10.15, 12.15, -1.55, 0.0, 0.3, "l3_floor")
	k.slab(3.85, -10.15, 12.15, -1.4, 3.7, 0.3, "l3_ceiling")
	k.wall(Vector3(4.0, 0, -10.3), Vector3(4.0, 0, -1.4), 3.4, 0.3, "l3_brick_dark")
	k.wall(Vector3(12.0, 0, -10.3), Vector3(12.0, 0, -1.4), 3.4, 0.3, "l3_brick_dark")
	k.wall(Vector3(3.85, 0, -10.15), Vector3(12.15, 0, -10.15), 3.4, 0.3, "l3_brick_dark")
	k.box_mm(Vector3(4.15, 3.2, -1.7), Vector3(11.85, 3.4, -1.4), "l3_brick_dark")
	K.car(k, Vector3(8.0, 0, -6.3), Vector3(0, 0, 1))
	for i in 3:
		k.cylinder(Vector3(9.2 + i * 0.4, 0.006, -3.6 - i * 1.6), 0.25 + i * 0.08, 0.01, "l3_oil", 12, false)
	K.drum(k, Vector3(11.2, 0, -9.3), "l3_drum_blue")
	k.box_mm(Vector3(4.15, 0, -9.85), Vector3(4.6, 1.8, -7.0), "l3_steel")
	for y: float in [0.6, 1.2, 1.75]:
		k.box_mm(Vector3(4.15, y, -9.85), Vector3(4.65, y + 0.04, -7.0), "l3_steel", GeoKit.ALL, false)
	K.pipe(lvl.tubes, Vector3(8.0, 3.4, -6.0), Vector3(8.0, 2.75, -6.0), 0.006, "l3_cable", 4)
	k.cylinder(Vector3(8.0, 2.7, -6.0), 0.06, 0.1, "l3_fixture", 8, false)
	lvl.tubes.cylinder(Vector3(8.0, 2.62, -6.0), 0.045, 0.08, "l3_tube_warm", 8, false)
	lvl.lights.add_anchor(Vector3(8.0, 2.45, -6.0), Color("ffc780"), 1.1, 7.0, 0.0)
	K.wall_dress(k, lvl.rng, Vector3(4.15, 0, -1.7), Vector3(4.15, 0, -6.6), Vector3(1, 0, 0), 3.4, true, 0.5)
	var ex: ExitTrigger = lvl.add_exit("L003>L069#4", "interact", Vector3(6.4, 1.0, -6.4), Vector3(1.0, 2.0, 2.6), "Get into the car")
	lvl.sys.car_exit = ex
	k.commit()


# -------------------------------------------------------- generator room

static func generator_room(lvl, k: GeoKit, r: RandomNumberGenerator) -> void:
	var W := "l3_brick_red" if r.randf() < 0.5 else "l3_brick_buff"
	_box_room(k, 30.3, -12.0, 56.0, 12.0, 0.0, 11.0, W, "l3_floor", {
		"w": [{"at": 12.3, "w": 4.4, "h": 4.0}],
		"e": [{"at": 8.3, "w": 2.4, "h": 2.8}, {"at": 18.3, "w": 2.2, "h": 2.4, "sill": 5.0}],
		"s": [{"at": 18.0, "w": 2.6, "h": 3.0}]})
	# catwalks at +5 m: north, east, south, plus a bridge between the generators
	K.deck(k, 30.3, -12.0, 56.0, -10.6, 5.0)
	K.deck(k, 54.6, -10.6, 56.0, 10.6, 5.0)
	K.deck(k, 40.5, 10.6, 56.0, 12.0, 5.0)
	K.deck(k, 43.3, -10.6, 44.7, 10.6, 5.0)
	for seg in [[Vector3(30.3, 5, -10.6), Vector3(43.3, 5, -10.6)], [Vector3(44.7, 5, -10.6), Vector3(54.6, 5, -10.6)],
			[Vector3(40.5, 5, 10.6), Vector3(43.3, 5, 10.6)], [Vector3(44.7, 5, 10.6), Vector3(54.6, 5, 10.6)],
			[Vector3(54.6, 5, -10.6), Vector3(54.6, 5, 10.6)],
			[Vector3(43.3, 5, -10.6), Vector3(43.3, 5, 10.6)], [Vector3(44.7, 5, -10.6), Vector3(44.7, 5, 10.6)]]:
		K.railing(k, seg[0], seg[1])
	k.stairs(Vector3(33.0, 0, 11.3), Vector3(1, 0, 0), 1.2, 5.0, 28, "l3_grate", 0.27, false)
	K.pipe(k, Vector3(33.0, 1.0, 10.68), Vector3(40.6, 6.0, 10.68), 0.024, "l3_rail", 6)
	K.pipe(k, Vector3(33.0, 0.5, 10.68), Vector3(40.6, 5.5, 10.68), 0.02, "l3_rail", 6)
	for z: float in [-3.2, 3.2]:
		k.box(Vector3(44.0, 2.47, z), Vector3(0.22, 4.94, 0.22), "l3_steel")
	for x: float in [33.0, 39.0, 46.0, 52.0]:
		K.pipe(k, Vector3(x, 4.9, -10.62), Vector3(x, 3.6, -12.0), 0.04, "l3_steel", 6)
	# the generator sets (one of them is unstable: see L003_sys.gd)
	for c: Vector3 in [Vector3(38.5, 0, -6), Vector3(38.5, 0, 6), Vector3(50, 0, -6), Vector3(50, 0, 6)]:
		K.generator(k, c, Vector3(1, 0, 0), 11.0)
		var em: AudioStreamPlayer3D = lvl.sound.emitter("transformer", c + U * 2.0, {"base": 50.0 + c.x * 0.1}, -10.0, 22.0)
		if c.x == 50.0 and c.z == 6.0:
			lvl.sys.gen_emit = em
	lvl.sys.unstable_gen = Vector3(50, 0, 6)
	# switchgear walls under the north catwalk and along the west wall
	var x := 31.0
	while x < 53.0:
		K.obox(k, Vector3(x + 0.55, 1.1, -11.7), Vector3(0, 0, 1), Vector3(1.0, 2.2, 0.6), "l3_cabinet", true)
		K.obox(k, Vector3(x + 0.55, 1.6, -11.39), Vector3(0, 0, 1), Vector3(0.6, 0.5, 0.02), "l3_louvre")
		K.obox(k, Vector3(x + 0.35, 1.0, -11.39), Vector3(0, 0, 1), Vector3(0.14, 0.14, 0.03), "l3_dial")
		x += 1.15 if r.randf() < 0.8 else 2.0
	for z: float in [-9.0, -7.8, -6.6, 4.0, 5.2, 6.4, 7.6]:
		K.obox(k, Vector3(30.65, 1.2, z), Vector3(1, 0, 0), Vector3(1.0, 2.4, 0.7), "l3_ebox_grey", true)
		K.obox(k, Vector3(31.01, 1.9, z), Vector3(1, 0, 0), Vector3(0.5, 0.3, 0.02), "l3_dial")
	for i in 7:
		var y := 6.0 + i * 0.25
		K.pipe(k, Vector3(30.35, y, -12.0), Vector3(30.35, y, 12.0), 0.03 + 0.02 * (i % 3), ["l3_cable", "l3_conduit", "l3_pipe_black"][i % 3], 6)
		K.pipe(k, Vector3(55.95, y + 1.5, -12.0), Vector3(55.95, y + 1.5, 4.0), 0.03 + 0.02 * (i % 3), ["l3_conduit_grey", "l3_cable", "l3_pipe_black"][i % 3], 6)
	K.wall_dress(k, r, Vector3(30.5, 0, 12.0), Vector3(46.4, 0, 12.0), Vector3(0, 0, -1), 4.6, true, 0.6)
	K.wall_dress(k, r, Vector3(56.0, 0, 8.0), Vector3(56.0, 0, -2.6), Vector3(-1, 0, 0), 4.6, true, 0.3)
	# Almond Water and Firesalt crates (page: "appear in here abundantly")
	for i in 5:
		K.crate(k, Vector3(32.2 + (i % 2) * 0.9, (i / 2) * 0.62, 6.5 + (i % 3) * 0.7), Vector3(0.8, 0.6, 0.6), r.randf_range(-0.2, 0.2), "l3_crate" if i % 2 == 0 else "l3_cardboard")
	for lx: float in [36.0, 44.0, 52.0]:
		for lz: float in [-6.0, 0.0, 6.0]:
			lvl.lamp(k, Vector3(lx, 11.0, lz), Vector3(1, 0, 0), 2.4, "dead" if r.randf() < 0.25 else "on", 14.0, 2.2)
	for lx: float in [35.0, 49.0]:
		lvl.lamp(k, Vector3(lx, 4.9, -11.3), Vector3(1, 0, 0), 0.0, "on", 6.0)
	lvl.sys.live_wire(k, Vector3(41.5, 4.94, -10.75), Vector3(41.0, 0.02, -10.0))
	lvl.sys.outlet(k, Vector3(53.2, 0.45, -11.38), Vector3(0, 0, 1))
	lvl.zones.append({"name": "generator", "box": AABB(Vector3(30.3, -1, -12), Vector3(25.7, 13, 24))})
	# upper passage (catwalk level) and lower ramp passage toward Base Gamma
	K.hall(k, Vector3(56.3, 5.0, 6.0), Vector3(74.0, 5.0, 6.0), 2.2, 2.6, W)
	K.wall_dress(k, r, Vector3(56.5, 5.0, 4.9), Vector3(73.8, 5.0, 4.9), Vector3(0, 0, 1), 2.6, true, 0.8)
	K.wall_dress(k, r, Vector3(56.5, 5.0, 7.1), Vector3(73.8, 5.0, 7.1), Vector3(0, 0, -1), 2.6, true, 0.8)
	lvl.lamp(k, Vector3(61.0, 7.6, 6.0), Vector3(1, 0, 0))
	lvl.lamp(k, Vector3(68.5, 7.6, 6.0), Vector3(1, 0, 0), 0.0, "flicker")
	K.sign(k, "BASE GAMMA  →\nviewing gantry", Vector3(57.5, 6.8, 4.92), Vector3(0, 0, 1), 0.7, 0.3)
	k.slab(56.0, -5.5, 60.0, -2.5, 0.0, 0.3, "l3_floor")
	k.ramp(Vector3(60.0, 0.0, -4.0), Vector3(72.0, -5.0, -4.0), 3.0, 0.3, "l3_floor")
	k.slab(72.0, -5.5, 74.3, -2.5, -5.0, 0.3, "l3_floor")
	for z: float in [-5.35, -2.65]:
		k.wall(Vector3(56.3, -5.0, z), Vector3(74.0, -5.0, z), 8.3, 0.3, W)
	k.slab(56.0, -5.5, 60.0, -2.5, 3.1, 0.3, "l3_ceiling")
	k.ramp(Vector3(60.0, 3.1, -4.0), Vector3(72.0, -1.9, -4.0), 3.0, 0.3, "l3_ceiling")
	k.slab(72.0, -5.5, 74.3, -2.5, -1.9, 0.3, "l3_ceiling")
	K.pipe(k, Vector3(56.3, 0.95, -5.12), Vector3(60.0, 0.95, -5.12), 0.025, "l3_rail", 6)
	K.pipe(k, Vector3(60.0, 0.95, -5.12), Vector3(72.0, -4.05, -5.12), 0.025, "l3_rail", 6)
	for i in 4:
		K.pipe(k, Vector3(56.3, 2.5 - i * 0.12, -2.85), Vector3(60.0, 2.5 - i * 0.12, -2.85), 0.03, ["l3_cable", "l3_pipe_black"][i % 2], 6)
		K.pipe(k, Vector3(60.0, 2.5 - i * 0.12, -2.85), Vector3(72.0, -2.5 - i * 0.12, -2.85), 0.03, ["l3_cable", "l3_pipe_black"][i % 2], 6)
	lvl.sys.purpified(k, Vector3(66.0, -2.5, -5.2), Vector3(0, 0, 1))
	lvl.lamp(k, Vector3(63.5, 1.35, -4.0), Vector3(1, 0, 0))
	lvl.lamp(k, Vector3(70.0, -1.2, -4.0), Vector3(1, 0, 0), 0.0, "warm")
	K.sign(k, "BASE GAMMA  →\nsecurity check ahead", Vector3(58.6, 1.7, -2.82), Vector3(0, 0, -1), 0.72, 0.32)


# ---------------------------------------------------------- assembly line

static func assembly(lvl, k: GeoKit, r: RandomNumberGenerator) -> void:
	var W := "l3_brick_buff"
	K.hall(k, Vector3(48, 0, 12.3), Vector3(48, 0, 16.0), 2.6, 3.0, W)
	_box_room(k, 34.15, 16.15, 69.85, 43.85, 0.0, 9.0, W, "l3_floor", {"n": [{"at": 14.15, "w": 2.6, "h": 3.0}]})
	for z: float in [24.0, 30.0, 36.0]:
		K.conveyor(k, Vector3(39.0, 0, z), Vector3(64.0, 0, z), 0.9)
		k.box(Vector3(37.4, 1.2, z), Vector3(2.2, 2.4, 1.8), "l3_gen_body")
		k.box(Vector3(37.4, 2.75, z), Vector3(1.4, 0.7, 1.2), "l3_steel", GeoKit.ALL, false)
		K.pipe(k, Vector3(37.4, 3.1, z), Vector3(37.4, 9.0, z), 0.16, "l3_conduit", 8)
		k.box(Vector3(38.55, 0.95, z), Vector3(0.1, 0.5, 0.95), "l3_rubber", GeoKit.ALL, false)
		k.box(Vector3(65.6, 0.45, z), Vector3(1.4, 0.9, 1.6), "l3_steel")
		lvl.sys.add_belt(Vector3(38.6, 0.92, z), Vector3(64.6, 0.92, z), "bottle" if z == 30.0 else "box")
		lvl.sound.emitter("transformer", Vector3(37.4, 1.5, z), {"base": 33.0}, -16.0, 18.0)
		for i in 6:
			K.crate(k, Vector3(64.95 + (i % 2) * 0.5, 0.9, z - 0.5 + (i / 2) * 0.45), Vector3(0.4, 0.3, 0.35), r.randf() * 0.4, "l3_cardboard")
	# yellow aisle lines
	for z: float in [21.0, 27.0, 33.0, 39.0]:
		k.box(Vector3(52.0, 0.005, z), Vector3(30.0, 0.01, 0.08), "l3_rail", GeoKit.ALL, false)
	# control mezzanine with booth
	k.slab(44.0, 39.2, 69.85, 43.85, 3.6, 0.25, "l3_grate")
	# Leave an actual 4.4 m-wide access opening for the new upper stair.
	K.railing(k, Vector3(44.0, 3.6, 39.2), Vector3(45.8, 3.6, 39.2))
	K.railing(k, Vector3(50.2, 3.6, 39.2), Vector3(69.85, 3.6, 39.2))
	_assembly_upper_walk(lvl, k)
	k.stairs(Vector3(38.4, 0, 41.3), Vector3(1, 0, 0), 1.4, 3.6, 20, "l3_grate", 0.40, false)
	K.pipe(k, Vector3(38.4, 0.95, 40.6), Vector3(46.4, 4.55, 40.6), 0.024, "l3_rail", 6)
	for x: float in [46.0, 52.0, 58.0, 64.0]:
		k.box(Vector3(x, 1.68, 39.4), Vector3(0.2, 3.36, 0.2), "l3_steel")
	k.wall(Vector3(52.0, 3.6, 40.6), Vector3(60.0, 3.6, 40.6), 2.6, 0.12, "l3_cabinet", [{"at": 1.4, "w": 0.9, "h": 2.1}, {"at": 5.0, "w": 5.0, "h": 1.0, "sill": 1.0}])
	k.box(Vector3(57.0, 5.1, 40.6), Vector3(5.0, 1.0, 0.02), "l3_glass_dark", GeoKit.ALL, false)
	for x: float in [52.0, 60.0]:
		k.wall(Vector3(x, 3.6, 40.6), Vector3(x, 3.6, 43.85), 2.6, 0.12, "l3_cabinet")
	k.slab(52.0, 40.6, 60.0, 43.85, 6.3, 0.1, "l3_steel")
	k.box(Vector3(56.0, 4.1, 43.4), Vector3(3.5, 1.0, 0.6), "l3_ebox_grey")
	lvl.tubes.quad(Vector3(56.0, 4.85, 43.08), Vector3(0, 0, -1), Vector3(0.6, 0, 0), Vector3(0, 0.25, 0), "l3_screen")
	lvl.lights.add_anchor(Vector3(56.0, 5.3, 42.0), Color("99ccff"), 0.6, 5.0)
	# Almond Water by the pallet (page: collections unheard of on other levels)
	for i in 6:
		var p := Vector3(35.6 + (i % 3) * 1.3, 0, 17.2 + (i / 3) * 1.3)
		k.box(p + Vector3(0.0, 0.07, 0.0), Vector3(1.2, 0.14, 1.2), "l3_crate")
		k.box(p + Vector3(0.0, 0.14 + 0.55, 0.0), Vector3(1.1, 1.1 - (i % 2) * 0.3, 1.1), "l3_bottle")
	for i in 26:
		var bp := Vector3(36.0 + r.randf() * 5.0, 0.13, 20.4 + r.randf() * 2.4)
		k.cylinder(bp, 0.04, 0.26, "l3_bottle", 6, false)
	lvl.add_interactable(Vector3(38.2, 0.6, 20.8), Vector3(3.6, 1.2, 1.4), "Take a bottle of Almond Water", lvl.sys.take_water)
	for lx: float in [42.0, 52.0, 62.0]:
		for lz: float in [21.0, 30.0, 39.0]:
			lvl.lamp(k, Vector3(lx, 9.0, lz), Vector3(1, 0, 0), 2.2, "dead" if r.randf() < 0.2 else "on", 14.0, 2.4)
	K.wall_dress(k, r, Vector3(34.3, 0, 23.0), Vector3(34.3, 0, 43.6), Vector3(1, 0, 0), 4.5, true, 0.4)
	K.wall_dress(k, r, Vector3(69.7, 0, 16.4), Vector3(69.7, 0, 38.6), Vector3(-1, 0, 0), 4.5, true, 0.4)
	lvl.zones.append({"name": "assembly", "box": AABB(Vector3(34, -1, 16), Vector3(36, 11, 28))})


## DEV12: vertical rework of the assembly hall, extending the old mezzanine to
## a THIRD navigable height. The room roof at y=9 has 2.7 m clearance above
## the new upper walkway. Source remains an electrical station, not a new exit.
static func _assembly_upper_walk(lvl, k: GeoKit) -> void:
	var y := 6.2
	# Existing lower mezzanine top is 3.6m; stairs use 18 treads @ 0.38m.
	k.stairs(Vector3(48.0, 3.6, 40.4), Vector3.FORWARD, 1.8, 2.6, 18, "l3_grate", 0.38, false)
	# Two connecting cross-bridges and a return view over the live conveyor lines.
	for rc in [
		Rect2(Vector2(43.0, 31.9), Vector2(25.0, 2.6)),
		Rect2(Vector2(53.0, 20.0), Vector2(2.8, 13.0)),
		Rect2(Vector2(53.0, 19.8), Vector2(13.5, 2.7)),
		Rect2(Vector2(63.9, 19.8), Vector2(2.6, 8.0))
	]:
		k.slab(rc.position.x, rc.position.y, rc.end.x, rc.end.y, y, 0.22, "l3_grate")
	# Collision guardrail on exposed edges, with the stair landing open.
	for ab in [
		[Vector3(43.0, y, 31.65), Vector3(52.8, y, 31.65)],
		[Vector3(56.0, y, 31.65), Vector3(68.0, y, 31.65)],
		[Vector3(43.0, y, 34.6), Vector3(46.7, y, 34.6)],
		[Vector3(49.3, y, 34.6), Vector3(68.0, y, 34.6)],
		[Vector3(52.9, y, 20.0), Vector3(52.9, y, 31.9)],
		[Vector3(56.0, y, 22.7), Vector3(56.0, y, 31.8)],
		[Vector3(53.0, y, 19.65), Vector3(66.5, y, 19.65)],
		[Vector3(56.0, y, 22.7), Vector3(64.0, y, 22.7)],
		[Vector3(66.65, y, 19.8), Vector3(66.65, y, 27.8)]
	]:
		K.railing(k, ab[0], ab[1])
	for x in [44.0, 57.5, 66.0]:
		k.box(Vector3(x, 3.0, 32.9), Vector3(0.24, 6.0, 0.24), "l3_steel", GeoKit.ALL, false)
	lvl.add_note("l3_upper_maintenance", "Overhead maintenance diagram",
		"The numbering on the assembly machinery repeats vertically: station A at ground, station A at the control deck, station A above the conveyor. The upper diagram has no date.",
		Vector3(60.0, y + 0.28, 20.9), Vector3(0.55, 0.08, 0.35))
	lvl.add_landmark("Assembly hall: upper cross-bridge", Vector3(54.5, y, 32.6))
	lvl.add_shot("assembly_upper", Vector3(60.0, y + 1.58, 21.1), Vector3(45.0, 0.7, 30.0), {"flashlight": true})



# ----------------------------------------------------------- boiler room

static func boiler_room(lvl, k: GeoKit, r: RandomNumberGenerator) -> void:
	var W := "l3_brick_dark"
	_box_room(k, 2.15, 9.15, 21.85, 26.85, -3.5, 9.0, W, "l3_floor", {"n": [{"at": 13.15, "w": 1.6, "h": 2.4, "sill": 3.5}]})
	K.deck(k, 2.15, 9.15, 21.85, 10.9, 0.0)
	K.deck(k, 19.6, 10.9, 21.85, 18.1, 0.0)
	K.railing(k, Vector3(2.15, 0, 10.9), Vector3(19.6, 0, 10.9))
	K.railing(k, Vector3(19.6, 0, 10.9), Vector3(19.6, 0, 18.1))
	k.stairs(Vector3(20.7, -3.5, 23.4), Vector3(0, 0, -1), 1.4, 3.5, 19, "l3_grate", 0.28, false)
	K.pipe(k, Vector3(19.98, -2.55, 23.4), Vector3(19.98, 0.95, 18.08), 0.024, "l3_rail", 6)
	for x: float in [4.0, 8.0, 12.0, 16.0, 19.7]:
		k.box(Vector3(x, -1.78, 10.8), Vector3(0.16, 3.44, 0.16), "l3_steel")
	k.box(Vector3(19.7, -1.78, 17.9), Vector3(0.16, 3.44, 0.16), "l3_steel")
	K.boiler(k, Vector3(7.0, -3.5, 18.5), Vector3(0, 0, 1), 5.8)
	K.boiler(k, Vector3(13.5, -3.5, 18.5), Vector3(0, 0, 1), 5.8)
	for bx: float in [7.0, 13.5]:
		lvl.lights.add_anchor(Vector3(bx, -2.0, 14.3), Color("ff7326"), 1.3, 6.5, 0.25)
		lvl.sound.emitter("room_tone", Vector3(bx, -1.5, 18.5), {"cutoff": 120.0, "rumble": 1.0}, -8.0, 14.0)
	# the black liquid's source: headers, leaking flanges and pools
	for i in 4:
		var y := 4.6 - i * 0.42
		K.pipe(k, Vector3(2.3, y, 26.6 - i * 0.3), Vector3(21.7, y, 26.6 - i * 0.3), 0.14 + 0.03 * (i % 2), "l3_pipe_black", 10)
	K.pipe(k, Vector3(2.4, 4.9, 9.4), Vector3(2.4, 4.9, 26.6), 0.22, "l3_pipe_black", 12)
	for pool in [[Vector3(10.4, -3.5, 24.0), 1.3], [Vector3(17.0, -3.5, 13.0), 0.9], [Vector3(4.2, -3.5, 25.2), 0.8]]:
		var c: Vector3 = pool[0]
		var rad: float = pool[1]
		k.cylinder(c + U * 0.012, rad, 0.02, "l3_sludge", 18, false)
		k.cylinder(c + Vector3(rad * 0.6, 0.014, rad * 0.4), rad * 0.55, 0.02, "l3_sludge", 12, false)
		K.pipe(k, Vector3(c.x, 3.0, c.z), Vector3(c.x, -1.6, c.z), 0.1, "l3_pipe_black", 10)
		K.pipe(k, Vector3(c.x, -1.6, c.z), Vector3(c.x, -1.72, c.z), 0.14, "l3_flange", 10)
		lvl.sludge.append({"c": c, "r": rad})
		lvl.sys.drip(Vector3(c.x, -1.75, c.z))
	K.wall_dress(k, r, Vector3(2.3, 0.0, 9.3), Vector3(14.0, 0.0, 9.3), Vector3(0, 0, 1), 5.0, true, 0.5)
	K.wall_dress(k, r, Vector3(21.7, -3.5, 26.0), Vector3(21.7, -3.5, 19.0), Vector3(-1, 0, 0), 3.0, true, 0.6)
	lvl.lamp(k, Vector3(9.0, 5.8, 12.5), Vector3(1, 0, 0), 1.2, "warm", 11.0, 1.8)
	lvl.lamp(k, Vector3(10.0, 5.8, 23.5), Vector3(1, 0, 0), 1.6, "flicker", 11.0, 1.8)
	K.sign(k, "DANGER\nBLACK LIQUID\nscalding / toxic fumes\ndo not touch the pipes", Vector3(17.6, 1.5, 9.32), Vector3(0, 0, 1), 0.6, 0.5, "l3_sign_yellow", Color("1a0d05"), 32)
	lvl.zones.append({"name": "boiler", "box": AABB(Vector3(2, -4, 9), Vector3(20, 10, 18))})


# ---------------------------------------------------------------- sanctum

static func sanctum(lvl, k: GeoKit, r: RandomNumberGenerator) -> void:
	var W := "l3_brick_red"
	_box_room(k, 15.15, -47.85, 38.85, -21.15, 0.0, 15.0, W, "l3_stone", {"arch": [{"at": 12.35, "w": 1.1, "spring": 1.8}]})
	# altar platform and steps
	k.slab(21.0, -47.85, 33.0, -41.0, 0.9, 0.9, "l3_marble")
	k.stairs(Vector3(27.0, 0, -39.6), Vector3(0, 0, -1), 8.0, 0.9, 5, "l3_marble", 0.28)
	K.statue(k, Vector3(27.0, 0.9, -45.2), Vector3(0, 0, 1))
	for x: float in [20.5, 33.5]:
		for z: float in [-25.0, -29.5, -34.0, -38.5, -43.0]:
			K.column(k, Vector3(x, 0, z), 10.0, 0.5)
		k.box(Vector3(x, 10.4, -34.0), Vector3(1.5, 0.8, 19.6), "l3_marble")
		k.box(Vector3(x, 11.0, -34.0), Vector3(1.8, 0.4, 20.0), "l3_marble", GeoKit.ALL, false)
	k.box(Vector3(27.0, 10.4, -43.0), Vector3(12.0, 0.8, 1.5), "l3_marble", GeoKit.ALL, false)
	for x: float in [15.16, 38.84]:
		var out := Vector3(1, 0, 0) if x < 20 else Vector3(-1, 0, 0)
		for z: float in [-27.25, -36.25]:
			K.obox(k, Vector3(x + out.x * 0.04, 4.8, z), out, Vector3(3.6, 4.6, 0.05), "l3_canvas")
	# brass wall lamps; a pale light falls on the statue
	for p: Vector3 in [Vector3(15.3, 4.2, -31.8), Vector3(38.7, 4.2, -31.8), Vector3(15.3, 4.2, -40.6), Vector3(38.7, 4.2, -40.6), Vector3(15.3, 4.2, -23.5), Vector3(38.7, 4.2, -23.5)]:
		var out := Vector3(1, 0, 0) if p.x < 20 else Vector3(-1, 0, 0)
		K.obox(k, p + out * 0.08, out, Vector3(0.3, 0.4, 0.16), "l3_rail")
		lvl.tubes.quad(p + out * 0.17 + U * 0.05, out, Vector3(0, 0, 0.1), Vector3(0, 0.12, 0), "l3_tube_warm")
		lvl.lights.add_anchor(p + out * 0.5, Color("ffb86b"), 0.9, 8.0)
	var sp := SpotLight3D.new()
	sp.position = Vector3(27.0, 14.0, -36.0)
	sp.light_color = Color("dbe6ff")
	sp.light_energy = 7.0
	sp.spot_range = 22.0
	sp.spot_angle = 22.0
	sp.shadow_enabled = true
	lvl.add_child(sp)
	sp.look_at(Vector3(27.0, 3.5, -45.2))
	lvl.zones.append({"name": "sanctum", "box": AABB(Vector3(15, -1, -48), Vector3(24, 16, 27))})
	lvl.add_note("L003_glyphs", "Glyphs on the pedestal",
		"[i]A band of carved glyphs runs around the statue's pedestal. You cannot read them; nothing about them looks like any alphabet you know.[/i]\n\nScratched into the floor beside it, in English: [i]M.E.G. says the same lines are on every pedestal. Nobody can read them. Nothing will follow you in here.[/i]",
		Vector3(27.0, 1.5, -43.9), Vector3(1.8, 1.0, 0.5), false)
