extends RefCounted
## Level 18 architecture and dressing: a preschool/daycare remembered from two to five
## years old, so everything is a child's size seen from a child's height (the building
## is ~1.4x: 3.9 m ceilings, 2.9 m doors, child furniture at adult height). Playroom
## with a raised book nook, a nap room, an art room, one seeded "other memory" room
## (bedroom, classroom or bathroom) and a fenced playground with a climbing tower and
## slide. ADAPTATION: the page gives no layout; this is one seeded daycare.

const H := 3.9
const T := 0.2

var lvl: Node3D
var k: GeoKit
var r: RandomNumberGenerator
var props: Node3D
var memory_kind := "bedroom"
var palette := 0


static func materials(pal: int) -> void:
	var walls := [[Color(0.93, 0.88, 0.7), Color(0.89, 0.84, 0.66)], [Color(0.82, 0.9, 0.86), Color(0.78, 0.86, 0.82)], [Color(0.92, 0.84, 0.82), Color(0.88, 0.8, 0.78)]]
	var wc: Array = walls[pal % 3]
	MatLib.define("l18_wall", {"albedo_a": wc[0], "albedo_b": wc[1], "noise_scale": 1.2, "stain_amount": 0.0, "roughness_a": 0.85}, "plaster")
	var bands := [Color(0.3, 0.55, 0.8), Color(0.85, 0.45, 0.35), Color(0.45, 0.68, 0.38)]
	MatLib.define("l18_band", {"albedo_a": bands[pal % 3], "albedo_b": bands[pal % 3] * 0.95, "noise_scale": 2.0, "roughness_a": 0.6}, "plaster")
	MatLib.define("l18_lino", {"albedo_a": Color(0.86, 0.84, 0.76), "albedo_b": Color(0.58, 0.72, 0.62), "pattern": 9,
		"pattern_scale": Vector2(0.45, 0.45), "roughness_a": 0.35, "roughness_b": 0.5, "stain_amount": 0.1}, "pool_tile")
	MatLib.define("l18_carpet", {"albedo_a": Color(0.25, 0.4, 0.7), "albedo_b": Color(0.22, 0.36, 0.64), "pattern": 6,
		"pattern_strength": 0.0, "noise_scale": 0.6, "roughness_a": 0.95, "wetness": 0.0, "stain_amount": 0.05}, "l0_carpet")
	MatLib.define("l18_rug", {"albedo_a": Color(0.92, 0.75, 0.25), "albedo_b": Color(0.85, 0.35, 0.3), "pattern": 9,
		"pattern_scale": Vector2(0.7, 0.7), "roughness_a": 0.95}, "l0_carpet")
	MatLib.define("l18_ceiling", {"stain_amount": 0.04, "albedo_a": Color(0.92, 0.9, 0.84), "albedo_b": Color(0.88, 0.86, 0.8)}, "l0_ceiling")
	MatLib.define("l18_wood", {"albedo_a": Color(0.72, 0.56, 0.36), "albedo_b": Color(0.66, 0.5, 0.31), "roughness_a": 0.55}, "wood_floor")
	MatLib.define("l18_grass", {"albedo_a": Color(0.3, 0.5, 0.18), "albedo_b": Color(0.24, 0.42, 0.14)}, "grass")
	MatLib.define("l18_sand", {"albedo_a": Color(0.88, 0.8, 0.6)}, "sand")
	MatLib.define("l18_fence", {"albedo_a": Color(0.94, 0.93, 0.88), "albedo_b": Color(0.9, 0.89, 0.84), "roughness_a": 0.6}, "trim_white")
	for c in [["l18_red", Color(0.85, 0.18, 0.15)], ["l18_yellow", Color(0.95, 0.78, 0.15)], ["l18_blue", Color(0.15, 0.4, 0.85)], ["l18_green", Color(0.2, 0.65, 0.3)]]:
		MatLib.register(c[0], MatLib.standard(c[1], 0.45))
	MatLib.register("l18_panel", MatLib.panel(Color(1.0, 0.94, 0.82), 1.6))
	MatLib.register("l18_glow", MatLib.panel(Color(1.0, 0.98, 0.93), 3.2))
	var g := StandardMaterial3D.new()
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.albedo_color = Color(0.85, 0.92, 0.95, 0.12)
	g.roughness = 0.05
	MatLib.register("l18_glass", g)


func _init(level: Node3D, rng: RandomNumberGenerator) -> void:
	lvl = level
	r = rng
	palette = r.randi() % 3
	var roll := r.randf()
	memory_kind = "bedroom" if roll < 0.45 else ("classroom" if roll < 0.8 else "washroom")
	materials(palette)
	k = GeoKit.new(level, "Daycare")
	props = Node3D.new()
	props.name = "Toys"
	level.add_child(props)


func _p(id: String, pos: Vector3, yaw: float = 0.0, h: float = 0.0, col: bool = false) -> Node3D:
	return Props.place(lvl, props, id, pos, yaw, h, col)


func wall(a: Vector2, b: Vector2, ops: Array = []) -> void:
	k.wall(Vector3(a.x, 0, a.y), Vector3(b.x, 0, b.y), H, T, "l18_wall", ops)
	# a painted band at a toddler's eye level
	var d := (b - a).normalized()
	var n := Vector2(-d.y, d.x)
	for s in [1.0, -1.0]:
		var o: Vector2 = n * (T * 0.5 + 0.006) * float(s)
		var bops: Array = []
		for op in ops:
			bops.append({"at": op["at"], "w": op["w"], "h": 9.0, "sill": 0.0})
		k.wall(Vector3(a.x + o.x, 0.9, a.y + o.y), Vector3(b.x + o.x, 0.9, b.y + o.y), 0.22, 0.012, "l18_band", bops)


func build() -> Dictionary:
	var door := {"w": 1.4, "h": 2.9}
	var win := func(at: float, wd: float = 2.0) -> Dictionary: return {"at": at, "w": wd, "h": 1.7, "sill": 1.1}
	# floors and ceiling
	k.slab(-12, -16, 12, 8, 0.0, 0.3, "l18_lino")
	k.box(Vector3(1.5, 0.006, 0.2), Vector3(13.0, 0.012, 9.0), "l18_carpet", GeoKit.ALL, false)
	k.box(Vector3(2.0, 0.015, 0.5), Vector3(5.0, 0.012, 3.6), "l18_rug", GeoKit.ALL, false)
	k.slab(-12, -16, 12, 8, H + 0.25, 0.25, "l18_ceiling")
	# outer walls
	wall(Vector2(-12, 8), Vector2(12, 8), [door.merged({"at": 12.0}), win.call(5.0), win.call(19.0)])
	wall(Vector2(12, -16), Vector2(12, 8), [door.merged({"at": 10.5}), win.call(4.0, 1.6), win.call(17.5), win.call(21.5, 1.6)])
	wall(Vector2(-12, -16), Vector2(-12, 8), [win.call(4.0, 1.6), win.call(14.0), win.call(20.5, 1.6)])
	wall(Vector2(-12, -16), Vector2(12, -16), [win.call(4.0, 1.6), win.call(12.0, 1.6), win.call(20.0, 1.6)])
	# the three back rooms
	wall(Vector2(-12, -8), Vector2(12, -8), [door.merged({"at": 4.0}), door.merged({"at": 12.0}), door.merged({"at": 20.0})])
	wall(Vector2(-4, -16), Vector2(-4, -8))
	wall(Vector2(4, -16), Vector2(4, -8))
	_glass()
	_lights()
	_outer_door()
	_nook()
	_playroom()
	_nap_room()
	_art_room()
	_memory_room()
	var yard := _playground()
	k.commit()
	return yard


func _glass() -> void:
	for gw in [[Vector3(-7, 1.95, 8), Vector3(2, 1.7, 0.03)], [Vector3(7, 1.95, 8), Vector3(2, 1.7, 0.03)],
			[Vector3(12, 1.95, -12), Vector3(0.03, 1.7, 1.6)], [Vector3(12, 1.95, 1.5), Vector3(0.03, 1.7, 2)], [Vector3(12, 1.95, 5.5), Vector3(0.03, 1.7, 1.6)],
			[Vector3(-12, 1.95, -12), Vector3(0.03, 1.7, 1.6)], [Vector3(-12, 1.95, -2), Vector3(0.03, 1.7, 2)], [Vector3(-12, 1.95, 4.5), Vector3(0.03, 1.7, 1.6)],
			[Vector3(-8, 1.95, -16), Vector3(1.6, 1.7, 0.03)], [Vector3(0, 1.95, -16), Vector3(1.6, 1.7, 0.03)], [Vector3(8, 1.95, -16), Vector3(1.6, 1.7, 0.03)]]:
		k.box(gw[0], gw[1], "l18_glass", GeoKit.ALL, false)


func _lights() -> void:
	for p in [Vector3(-6, H, -2), Vector3(0, H, 3), Vector3(6, H, -2), Vector3(6, H, 4), Vector3(-6, H, 4), Vector3(-8, H, -12), Vector3(0, H, -12), Vector3(8, H, -12)]:
		k.panel(p - Vector3(0, 0.01, 0), 1.2, 0.6, "l18_panel")
		lvl.lights.add_anchor(p - Vector3(0, 0.4, 0), Color(1.0, 0.92, 0.8), 0.9, 8.0)


## The way you came in: a doorway onto bright, featureless light. Turning round and
## walking back out is the simplest way to leave (to Level 19).
func _outer_door() -> void:
	k.slab(-1.6, 8.0, 1.6, 10.6, 0.0, 0.3, "l18_lino")
	k.box(Vector3(0, H * 0.5, 10.7), Vector3(3.4, H, 0.1), "l18_glow", GeoKit.ALL, false)
	k.wall(Vector3(-1.7, 0, 8.1), Vector3(-1.7, 0, 10.7), H, 0.15, "l18_wall")
	k.wall(Vector3(1.7, 0, 8.1), Vector3(1.7, 0, 10.7), H, 0.15, "l18_wall")
	k.slab(-1.7, 8.1, 1.7, 10.7, H, 0.1, "l18_wall")
	# cubbies and coat hooks by the door
	for i in 4:
		_p("kenney/furniture-kit/bookcaseopenlow", Vector3(-3.2 - i * 1.25, 0, 7.6), 180.0, 1.25, true)
		_p("kenney/furniture-kit/bookcaseopenlow", Vector3(3.2 + i * 1.25, 0, 7.6), 180.0, 1.25, true)
	for i in 6:
		k.box(Vector3(-5.6 + i * 0.5 + (0.0 if i < 3 else 8.2), 1.9, 7.88), Vector3(0.05, 0.05, 0.12), "l18_red" if i % 2 == 0 else "l18_yellow", GeoKit.ALL, false)
	_p("ph/vintage_suitcase", Vector3(4.6, 1.25, 7.6), 180.0, 0.35)


## A raised book nook in the playroom's west corner: a platform at 1.7 m with a stair.
func _nook() -> void:
	k.slab(-12, -2, -7, 4, 1.7, 0.2, "l18_wood")
	for x in [-7.1]:
		for z in [-1.9, 3.9]:
			k.box(Vector3(x, 0.8, z), Vector3(0.16, 1.6, 0.16), "l18_wood")
	k.stairs(Vector3(-9.5, 0, 6.52), Vector3(0, 0, -1), 1.1, 1.7, 9, "l18_wood", 0.28)
	# railings (child height, scaled)
	k.box(Vector3(-7.05, 2.35, 1.0), Vector3(0.08, 0.08, 6.0), "l18_wood", GeoKit.ALL, false)
	k.box(Vector3(-7.05, 2.0, 1.0), Vector3(0.06, 0.6, 6.0), "l18_glass", GeoKit.ALL, true)
	k.box(Vector3(-8.0, 2.35, 3.95), Vector3(1.9, 0.08, 0.08), "l18_wood", GeoKit.ALL, false)
	k.box(Vector3(-8.0, 2.0, 3.95), Vector3(1.9, 0.6, 0.06), "l18_glass", GeoKit.ALL, true)
	k.box(Vector3(-11.0, 2.35, 3.95), Vector3(1.9, 0.08, 0.08), "l18_wood", GeoKit.ALL, false)
	k.box(Vector3(-11.0, 2.0, 3.95), Vector3(1.9, 0.6, 0.06), "l18_glass", GeoKit.ALL, true)
	for i in 7:
		k.box(Vector3(-7.05, 2.0, -1.8 + i * 0.95), Vector3(0.05, 0.7, 0.05), "l18_wood", GeoKit.ALL, false)
	# up top: cushions and books; underneath: a low den
	for c in [[Vector3(-11.2, 1.8, -1.0), "l18_red"], [Vector3(-11.2, 1.8, 0.4), "l18_yellow"], [Vector3(-10.2, 1.8, -1.3), "l18_blue"]]:
		k.box(c[0] + Vector3(0, 0.12, 0), Vector3(0.9, 0.25, 0.9), c[1], GeoKit.ALL, false)
	_p("ph/Shelf_01", Vector3(-11.8, 1.7, 2.0), 90.0, 1.4, true)
	for i in 3:
		_p("kenney/furniture-kit/books", Vector3(-11.75, 1.95 + i * 0.36, 1.7 + i * 0.2), 90.0, 0.16)
	_p("kenney/furniture-kit/loungechair", Vector3(-9.0, 0, 0.0), 120.0, 0.9)
	_p("kenney/furniture-kit/pillowblue", Vector3(-10.8, 0, 2.6), 30.0, 0.25)
	_p("kenney/furniture-kit/pillow", Vector3(-11.0, 0, 1.4), 70.0, 0.25)


func _playroom() -> void:
	# low tables at adult height (a toddler's table, remembered)
	for t in [[Vector3(4.5, 0, -4.2), 0.0], [Vector3(-2.0, 0, -4.4), 90.0]]:
		t[0] += Vector3(r.randf_range(-0.7, 0.7), 0, r.randf_range(-0.4, 0.5))
		_p("kenney/furniture-kit/table", t[0], t[1], 0.8, true)
		for c in 4:
			var a := TAU * c / 4.0 + 0.4
			_p("kenney/furniture-kit/chair", t[0] + Vector3(cos(a) * 1.15, 0, sin(a) * 1.0), rad_to_deg(-a) - 90.0 + r.randf_range(-20, 20), 1.15)
	# toy shelves, blocks, a play kitchen, a rocking chair
	_p("kenney/furniture-kit/bookcaseopen", Vector3(11.6, 0, -1.0), -90.0, 2.0, true)
	_p("kenney/furniture-kit/kitchenstove", Vector3(-5.6, 0, -7.45), 0.0, 1.25, true)
	_p("kenney/furniture-kit/kitchensink", Vector3(-4.35, 0, -7.45), 0.0, 1.25, true)
	_p("kenney/furniture-kit/kitchenfridge", Vector3(-3.0, 0, -7.4), 0.0, 1.9, true)
	_p("kenney/food-kit/pot", Vector3(-5.6, 1.25, -7.45), 0.0, 0.25)
	for i in 14:
		var c: String = ["l18_red", "l18_yellow", "l18_blue", "l18_green"][i % 4]
		var bp := Vector3(1.2 + r.randf_range(-1.6, 1.6), 0.13, 0.6 + r.randf_range(-1.2, 1.2))
		if i > 9:
			bp = Vector3(1.0 + (i - 10) * 0.05, 0.39 + (i - 10) * 0.26, -0.4)
		k.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * TAU), bp), Vector3(0.26, 0.26, 0.26), c, GeoKit.ALL, false)
	_p("kenney/furniture-kit/radio", Vector3(11.5, 1.48, -1.5), -90.0, 0.3)
	_p("ph/rubber_duck_toy", Vector3(11.5, 0.88, -0.4), -100.0, 0.25)
	_p("ph/plastic_crate_01", Vector3(10.6, 0, 2.6), 15.0, 0.5, true)
	_p("ph/plastic_crate_01", Vector3(10.2, 0, 3.4), 80.0, 0.5, true)
	_p("ph/wall_clock", Vector3(0, 3.0, -7.86), 0.0, 0.45)
	_p("kenney/furniture-kit/plantsmall1", Vector3(-11.4, 1.1, -3.0), 0.0, 0.5)
	# the snack corner: water and food are always laid out
	_p("kenney/furniture-kit/sidetable", Vector3(-3.0, 0, 6.5), 0.0, 1.0, true)
	for f in [["food-kit/carton", Vector3(-3.25, 1.0, 6.4), 0.3], ["food-kit/cup", Vector3(-2.9, 1.0, 6.6), 0.16], ["food-kit/sandwich", Vector3(-2.7, 1.0, 6.3), 0.1], ["food-kit/bowl", Vector3(-3.4, 1.0, 6.7), 0.1]]:
		_p("kenney/" + str(f[0]), f[1], r.randf_range(0, 360), f[2])


func _nap_room() -> void:
	for i in 3:
		for j in 2:
			var c := Vector3(-10.4 + i * 2.6, 0, -13.8 + j * 3.4)
			k.box(c + Vector3(0, 0.25, 0), Vector3(1.0, 0.5, 2.0), "l18_blue" if (i + j) % 2 == 0 else "l18_green")
			k.box(c + Vector3(0, 0.53, 0.3), Vector3(0.96, 0.08, 1.3), "l18_yellow", GeoKit.ALL, false)
			k.box(c + Vector3(0, 0.6, -0.7), Vector3(0.7, 0.14, 0.4), "l18_fence", GeoKit.ALL, false)
	_p("ph/wooden_bookshelf_worn", Vector3(-4.4, 0, -12.0), -90.0, 1.9, true)


func _art_room() -> void:
	for t in [Vector3(-1.6, 0, -12.6), Vector3(1.8, 0, -11.6)]:
		_p("kenney/furniture-kit/table", t, 0.0, 0.8, true)
		for c in 3:
			_p("kenney/furniture-kit/chairdesk", t + Vector3(-0.8 + c * 0.8, 0, 1.1), 180.0 + r.randf_range(-15, 15), 1.15)
	for e in [Vector3(-3.0, 0, -15.2), Vector3(2.8, 0, -15.3)]:
		k.box(e + Vector3(0, 1.3, 0.1), Vector3(1.0, 1.2, 0.04), "l18_fence", GeoKit.ALL, false)
		for lx in [-0.4, 0.4]:
			k.box_xf(Transform3D(Basis(Vector3.RIGHT, 0.15), e + Vector3(lx, 1.0, 0.2)), Vector3(0.05, 2.0, 0.05), "l18_wood", GeoKit.ALL, false)
	_p("ph/stationery_supplies", Vector3(-1.6, 0.8, -12.6), 20.0, 0.25)
	_p("ph/binder_notebook", Vector3(1.6, 0.8, -11.4), 75.0)


## One more remembered room, seeded per viewer.
func _memory_room() -> void:
	match memory_kind:
		"bedroom":
			_p("kenney/furniture-kit/bedsingle", Vector3(9.8, 0, -14.4), 90.0, 0.9, true)
			_p("kenney/furniture-kit/sidetabledrawers", Vector3(11.3, 0, -9.4), -90.0, 0.8, true)
			_p("kenney/furniture-kit/lamproundfloor", Vector3(11.3, 0.8, -9.4), 0.0, 0.5)
			_p("ph/plastic_crate_01", Vector3(5.2, 0, -9.0), 30.0, 0.5, true)
			k.box(Vector3(8.0, 0.01, -12.0), Vector3(3.0, 0.012, 2.4), "l18_rug", GeoKit.ALL, false)
			_p("ph/rubber_duck_toy", Vector3(7.6, 0.02, -12.2), 40.0, 0.22)
		"classroom":
			for i in 2:
				for j in 2:
					_p("ph/SchoolDesk_01", Vector3(6.2 + i * 2.6, 0, -13.6 + j * 2.4), 0.0, 1.1, true)
					_p("ph/SchoolChair_01", Vector3(6.2 + i * 2.6, 0, -12.8 + j * 2.4), 180.0, 1.25)
			k.box(Vector3(8.0, 2.2, -15.86), Vector3(4.0, 1.5, 0.04), "l18_green", GeoKit.ALL, false)
		_:
			for i in 4:
				_p("kenney/furniture-kit/bathroomsinksquare", Vector3(5.0 + i * 1.6, 0, -15.5), 0.0, 1.15, true)
			for i in 2:
				_p("kenney/furniture-kit/toiletsquare", Vector3(11.4, 0, -14.6 + i * 2.2), -90.0, 1.0, true)
	# the resurfaced memory: a pet that died long ago
	_p("kenney/furniture-kit/sidetable", Vector3(5.0, 0, -11.0), 90.0, 1.0, true)


func _playground() -> Dictionary:
	k.slab(12.0, -16, 36, 8, -0.02, 0.3, "l18_grass")
	# picket fence round the yard (the edge of the memory)
	for side in [[Vector2(12.2, -16), Vector2(36, -16)], [Vector2(36, -16), Vector2(36, -3.0)], [Vector2(36, -1.0), Vector2(36, 8)], [Vector2(36, 8), Vector2(12.2, 8)]]:
		var a: Vector2 = side[0]
		var b: Vector2 = side[1]
		var ln := a.distance_to(b)
		var d := (b - a) / ln
		for i in int(ln / 0.32):
			var p := a + d * (i * 0.32 + 0.16)
			k.box(Vector3(p.x, 0.75, p.y), Vector3(0.09, 1.5, 0.09) if absf(d.x) < 0.5 else Vector3(0.09, 1.5, 0.09), "l18_fence", GeoKit.ALL, false)
		var mid := (a + b) * 0.5
		var sz := Vector3(absf(b.x - a.x) + 0.1, 1.4, 0.12) if absf(d.x) > 0.5 else Vector3(0.12, 1.4, absf(b.y - a.y) + 0.1)
		k.box(Vector3(mid.x, 1.1, mid.y), Vector3(sz.x, 0.08, sz.z), "l18_fence", GeoKit.ALL, false)
		k.box(Vector3(mid.x, 0.4, mid.y), Vector3(sz.x, 0.08, sz.z), "l18_fence", GeoKit.ALL, false)
		k.box(Vector3(mid.x, 0.75, mid.y), sz, "l18_fence", GeoKit.PY, true)
	# beyond the gate: the same bright nothing as the front door
	k.box(Vector3(37.6, 1.6, -2.0), Vector3(0.1, 3.2, 3.0), "l18_glow", GeoKit.ALL, false)
	k.slab(36.0, -3.4, 37.6, -0.6, -0.02, 0.3, "l18_grass")
	k.box(Vector3(36.8, 1.6, -3.45), Vector3(1.6, 3.2, 0.1), "l18_fence", GeoKit.ALL, true)
	k.box(Vector3(36.8, 1.6, -0.55), Vector3(1.6, 3.2, 0.1), "l18_fence", GeoKit.ALL, true)
	for gp in [-3.05, -0.95]:
		k.box(Vector3(36.0, 0.8, gp), Vector3(0.14, 1.6, 0.14), "l18_fence")
	# climbing tower: platform at 1.8 m, stair up the west side, slide down the east
	var tw := Vector3(24.0, 0, -6.0)
	k.slab(tw.x - 1.2, tw.z - 1.2, tw.x + 1.2, tw.z + 1.2, 1.8, 0.15, "l18_wood")
	for cx in [-1.15, 1.15]:
		for cz in [-1.15, 1.15]:
			k.box(tw + Vector3(cx, 1.6, cz), Vector3(0.14, 3.2, 0.14), "l18_red")
	k.box(tw + Vector3(0, 3.35, 0), Vector3(2.8, 0.15, 2.8), "l18_yellow", GeoKit.ALL, false)
	k.stairs(tw + Vector3(-3.7, 0, 0), Vector3(1, 0, 0), 1.0, 1.8, 9, "l18_wood", 0.28)
	k.ramp(tw + Vector3(1.2, 1.8, 0), tw + Vector3(5.2, 0.1, 0), 0.9, 0.08, "l18_yellow")
	k.box(tw + Vector3(3.2, 1.05, 0.48), Vector3(4.2, 0.3, 0.05), "l18_yellow", GeoKit.ALL, false)
	k.box(tw + Vector3(3.2, 1.05, -0.48), Vector3(4.2, 0.3, 0.05), "l18_yellow", GeoKit.ALL, false)
	for s in [Vector3(0, 2.2, 1.18), Vector3(0, 2.2, -1.18), Vector3(-1.18, 2.2, 0.75)]:
		k.box(tw + s, Vector3(2.4 if absf(s.z) > 1.0 else 0.06, 0.06, 0.06 if absf(s.z) > 1.0 else 0.9), "l18_blue", GeoKit.ALL, false)
	# swings
	var sw := Vector3(20.0, 0, 3.5)
	for sx in [-2.0, 2.0]:
		for sz in [-0.7, 0.7]:
			k.box_xf(Transform3D(Basis(Vector3.RIGHT, -sz * 0.25), sw + Vector3(sx, 1.4, sz * 0.5)), Vector3(0.1, 2.9, 0.1), "l18_blue", GeoKit.ALL, true)
	k.box(sw + Vector3(0, 2.8, 0), Vector3(4.2, 0.12, 0.12), "l18_blue", GeoKit.ALL, false)
	for s in [-0.8, 0.8]:
		k.box(sw + Vector3(s, 0.55, 0), Vector3(0.6, 0.05, 0.25), "l18_red", GeoKit.ALL, false)
		for e in [-0.27, 0.27]:
			k.box(sw + Vector3(s + e, 1.68, 0), Vector3(0.015, 2.25, 0.015), "metal", GeoKit.ALL, false)
	# sandbox
	var sb := Vector3(29.0, 0, 3.0)
	k.box(sb + Vector3(0, 0.1, 0), Vector3(3.2, 0.12, 3.2), "l18_sand", GeoKit.ALL, false)
	for e in [[Vector3(0, 0.15, 1.6), Vector3(3.3, 0.3, 0.12)], [Vector3(0, 0.15, -1.6), Vector3(3.3, 0.3, 0.12)], [Vector3(1.6, 0.15, 0), Vector3(0.12, 0.3, 3.3)], [Vector3(-1.6, 0.15, 0), Vector3(0.12, 0.3, 3.3)]]:
		k.box(sb + e[0], e[1], "l18_wood", GeoKit.ALL, false)
	_p("kenney/food-kit/bowl", sb + Vector3(0.4, 0.17, -0.3), 0.0, 0.12)
	_p("ph/wooden_picnic_table", Vector3(30.0, 0, -12.0), 90.0, 0.0, true)
	return {"tower": tw, "swings": sw, "sandbox": sb, "gate": Vector3(36.0, 0, -2.0)}
