extends RefCounted
## Level 0.2 furnishing: what a remodelling crew would have fitted to a "fixed"
## Level 0 (page: dry red carpet, repainted white walls, working Wi-Fi and
## outlets, the occasional bathroom) plus their own job-site leftovers.
## Poly Haven CC0 and Kenney CC0 models via Props.place; built-ins via GeoKit.

const G := preload("res://levels/L000_2/L000_2_geo.gd")

var lvl
var geo
var rng: RandomNumberGenerator
var k: GeoKit
var root: Node3D
var props := 0
var routers: Array = []      # LED positions (blinking handled by the level)


func _init(level, g) -> void:
	lvl = level
	geo = g
	rng = level.rng


func p(id: String, pos: Vector3, yaw: float = 0.0, h: float = 0.0, collide: bool = false) -> Node3D:
	var n: Node3D = Props.place(lvl, root, id, pos, yaw, h, collide)
	if n:
		props += 1
	return n


## Point d metres in from wall `side` of rect r at fraction t along it, plus the
## yaw that faces a +Z-forward model into the room.
static func wallpos(r: Rect2, side: String, t: float, d: float) -> Array:
	match side:
		"n": return [Vector3(r.position.x + r.size.x * t, 0, r.position.y + d), 0.0]
		"s": return [Vector3(r.position.x + r.size.x * t, 0, r.end.y - d), 180.0]
		"w": return [Vector3(r.position.x + d, 0, r.position.y + r.size.y * t), 90.0]
	return [Vector3(r.end.x - d, 0, r.position.y + r.size.y * t), -90.0]


func ok(id: String, pos: Vector3, clear: float = 1.3) -> bool:
	return geo.clear_of_doors(id, pos, clear) and not geo.in_pit(pos, 0.5)


func dress() -> void:
	root = Node3D.new()
	root.name = "Furnishing"
	lvl.add_child(root)
	k = lvl.kit("L02_Built")
	for id in G.ROOMS.keys():
		var kind: String = G.ROOMS[id][4]
		var r: Rect2 = geo.room_rect(id)
		call("_" + kind, id, r)
		_outlets(id, r)
		if not kind in ["bathroom", "storage", "utility", "files"]:
			for side in ["n", "s", "e", "w"]:
				if rng.randf() < (0.8 if kind == "corridor" else 0.5):
					for t in ([0.2, 0.45, 0.7, 0.92] if kind == "corridor" else [rng.randf_range(0.25, 0.75)]):
						_art(id, r, side, t)
	k.commit()


# ------------------------------------------------------------------ rooms

func _reception(id: String, r: Rect2) -> void:
	# reception counter on the west side, waiting chairs on the east
	var cx := r.position.x + 1.9
	k.box_mm(Vector3(cx - 1.2, 0, -3.6), Vector3(cx + 1.2, 1.05, -3.0), "l02_laminate")
	k.box_mm(Vector3(cx - 1.3, 1.05, -3.7), Vector3(cx + 1.3, 1.09, -2.9), "l02_counter_top", GeoKit.ALL, false)
	k.box_mm(Vector3(cx - 1.2, 0, -4.5), Vector3(cx - 0.6, 0.75, -3.6), "l02_laminate")
	p("ph/classic_laptop", Vector3(cx + 0.3, 1.09, -3.35), 180.0, 0.3)
	p("ph/office_notepads", Vector3(cx - 0.6, 1.09, -3.3), 10.0)
	p("ph/stationery_supplies", Vector3(cx + 0.9, 1.09, -3.4), 0.0)
	p("kenney/furniture-kit/chairdesk", Vector3(cx + 0.2, 0, -4.2), 0.0, 1.0)
	p("ph/wall_clock", Vector3(cx, 2.0, r.end.y - 0.04), 180.0)
	var ex := r.end.x - 1.0
	for n in 3:
		p("ph/ArmChair_01", Vector3(ex, 0, -1.6 - n * 1.05), -90.0, 0.0, true)
	p("ph/coffee_table_round_01", Vector3(ex - 1.3, 0, -2.6), 0.0, 0.42, true)
	p("ph/office_notepads", Vector3(ex - 1.3, 0.42, -2.6), 30.0)
	p("kenney/furniture-kit/pottedplant", Vector3(r.end.x - 0.45, 0, r.position.y + 0.45), 0.0, 1.35)
	p("kenney/furniture-kit/pottedplant", Vector3(r.position.x + 0.45, 0, r.end.y - 0.45), 40.0, 1.35)
	p("ph/fire_alarm", Vector3(r.position.x + 0.03, 1.3, -1.2), 90.0)
	_router(Vector3(cx - 1.0, 1.09, -3.55))


func _corridor(id: String, r: Rect2) -> void:
	var z := r.end.y - 2.5
	var n := 0
	while z > r.position.y + 1.5:
		var side := "w" if n % 2 == 0 else "e"
		var wp := wallpos(r, side, (z - r.position.y) / r.size.y, 0.18)
		if ok(id, wp[0], 1.0):
			match n % 4:
				0: p("ph/korean_fire_extinguisher_01", wp[0] + Vector3(0, 0.0, 0), wp[1])
				1: p("kenney/furniture-kit/pottedplant", wp[0] + (Vector3(-0.15, 0, 0) if side == "e" else Vector3(0.15, 0, 0)), 0.0, 1.3)
				2: p("ph/fire_alarm", wp[0] + Vector3(0, 1.3, 0) + (Vector3(0.14, 0, 0) if side == "e" else Vector3(-0.14, 0, 0)), wp[1])
				3: p("kenney/furniture-kit/trashcan", wp[0], wp[1], 0.6)
		z -= 3.4 + rng.randf() * 1.6
		n += 1
	p("ph/wall_clock", Vector3(r.position.x + 0.04, 2.0, r.get_center().y), 90.0)


func _lobby(id: String, r: Rect2) -> void:
	# the door back to Level 0 is a different, older door: yellowed, scuffed,
	# with Level 0's light leaking under it (built by the level script)
	for sx in [-4.0, 4.0]:
		p("ph/Sofa_01", Vector3(sx, 0, r.position.y + 0.45), 0.0, 0.0, true)
		p("kenney/furniture-kit/pottedplant", Vector3(sx + (1.4 if sx > 0 else -1.4), 0, r.position.y + 0.4), 0.0, 1.4)
		p("ph/coffee_table_round_01", Vector3(sx, 0, r.position.y + 1.7), 0.0, 0.4, true)
	k.box_mm(Vector3(-5.5, 0, r.position.y + 0.1), Vector3(-2.5, 0.012, r.position.y + 2.6), "l02_rug", GeoKit.ALL, false)
	k.box_mm(Vector3(2.5, 0, r.position.y + 0.1), Vector3(5.5, 0.012, r.position.y + 2.6), "l02_rug", GeoKit.ALL, false)
	p("ph/korean_fire_extinguisher_01", Vector3(r.end.x - 0.2, 0, r.get_center().y), -90.0)
	p("ph/WetFloorSign_01", Vector3(-2.2, 0, r.end.y - 2.2), 25.0)
	p("ph/wall_clock", Vector3(r.end.x - 0.04, 2.0, r.get_center().y + 0.5), -90.0)
	_router(Vector3(r.position.x + 0.16, 2.2, r.get_center().y))


func _office(id: String, r: Rect2) -> void:
	# open-plan bays: desk pairs divided by fabric partitions
	var cols := 2 if r.size.x > 7.0 else 1
	var rows := int(r.size.y / 3.2)
	for ci in cols:
		for ri in rows:
			var c := Vector3(r.position.x + r.size.x * (ci + 0.5) / cols, 0, r.position.y + 1.8 + ri * 3.1)
			if not ok(id, c, 1.6):
				continue
			var yaw := 0.0 if ri % 2 == 0 else 180.0
			p("ph/metal_office_desk", c, yaw, 0.0, true)
			p("kenney/furniture-kit/chairdesk", c + Vector3(rng.randf_range(-0.4, 0.4), 0, 0.85 if yaw == 0.0 else -0.85), yaw + 180.0 + rng.randf_range(-35, 35), 1.0)
			p("kenney/furniture-kit/computerscreen", c + Vector3(-0.3, 0.79, -0.15 if yaw == 0.0 else 0.15), yaw, 0.42)
			p("kenney/furniture-kit/computerkeyboard", c + Vector3(-0.3, 0.79, 0.15 if yaw == 0.0 else -0.15), yaw, 0.03)
			if rng.randf() < 0.6:
				p("ph/binder_notebook", c + Vector3(0.6, 0.79, 0), rng.randf() * 360.0)
			if rng.randf() < 0.5:
				p("ph/stationery_supplies", c + Vector3(0.35, 0.79, 0.1), rng.randf() * 360.0)
			var pz := c.z + (-0.65 if yaw == 0.0 else 0.65)
			k.box(Vector3(c.x, 0.7, pz), Vector3(2.3, 1.4, 0.06), "l02_fabric")
			k.box(Vector3(c.x, 1.41, pz), Vector3(2.32, 0.03, 0.08), "l02_metal", GeoKit.ALL, false)
	for t in [0.2, 0.45, 0.8]:
		var wp := wallpos(r, "w", t, 0.3)
		if ok(id, wp[0]):
			p("ph/drawer_cabinet", wp[0], wp[1], 1.3, true)
	var sp := wallpos(r, "n", 0.85, 0.2)
	if ok(id, sp[0]):
		p("ph/Shelf_01", sp[0], sp[1], 0.0, true)
	p("kenney/furniture-kit/pottedplant", Vector3(r.end.x - 0.5, 0, r.end.y - 0.5), 0.0, 1.3)
	p("ph/wall_clock", wallpos(r, "s", 0.5, 0.04)[0] + Vector3(0, 2.0, 0), 180.0)
	_router(wallpos(r, "n", 0.15, 0.16)[0] + Vector3(0, 2.1, 0))


func _office_small(id: String, r: Rect2) -> void:
	var c := r.get_center()
	p("ph/metal_office_desk", Vector3(c.x, 0, c.y - 0.6), 0.0, 0.0, true)
	p("kenney/furniture-kit/chairdesk", Vector3(c.x + 0.2, 0, c.y + 0.3), 160.0, 1.0)
	p("kenney/furniture-kit/computerscreen", Vector3(c.x - 0.2, 0.79, c.y - 0.75), 0.0, 0.42)
	p("ph/office_notepads", Vector3(c.x + 0.5, 0.79, c.y - 0.6), 0.0)
	var wp := wallpos(r, "e", 0.3, 0.2)
	if ok(id, wp[0]):
		p("ph/Shelf_01", wp[0], wp[1], 0.0, true)
	p("kenney/furniture-kit/pottedplant", Vector3(r.position.x + 0.45, 0, r.position.y + 0.45), 0.0, 1.2)
	p("kenney/furniture-kit/trashcan", Vector3(c.x + 1.3, 0, c.y - 1.0), 0.0, 0.55)


func _bathroom(id: String, r: Rect2) -> void:
	# three stalls on the west side, sinks and mirrors on the east
	for s in 3:
		var z0 := r.position.y + 0.2 + s * 1.2
		var x0 := r.position.x
		k.box(Vector3(x0 + 0.85, 1.0, z0), Vector3(1.6, 1.75, 0.03), "l02_stall")
		k.box(Vector3(x0 + 1.62, 1.0, z0 + 0.6), Vector3(0.03, 1.75, 0.55 if s != 1 else 0.2), "l02_stall")
		p("kenney/furniture-kit/toilet", Vector3(x0 + 0.38, 0, z0 + 0.6), 90.0, 0.8)
	k.box(Vector3(r.position.x + 0.85, 1.0, r.position.y + 3.8), Vector3(1.6, 1.75, 0.03), "l02_stall")
	for s in 3:
		var z := r.position.y + 0.9 + s * 1.4
		if not ok(id, Vector3(r.end.x - 0.3, 0, z), 0.9):
			continue
		p("kenney/furniture-kit/bathroomsink", Vector3(r.end.x - 0.3, 0, z), -90.0, 0.9)
		p("kenney/furniture-kit/bathroommirror", Vector3(r.end.x - 0.08, 1.25, z), -90.0, 0.75)
	k.box(Vector3(r.end.x - 0.1, 1.4, r.end.y - 0.6), Vector3(0.12, 0.3, 0.26), "l02_metal", GeoKit.ALL, false)
	p("ph/WetFloorSign_01", Vector3(r.get_center().x + 0.3, 0, r.end.y - 1.2), rng.randf() * 360.0)
	p("kenney/furniture-kit/trashcan", Vector3(r.end.x - 0.3, 0, r.end.y - 0.35), 0.0, 0.6)


func _storage(id: String, r: Rect2) -> void:
	# the crew's staging room: shelving, boxed fittings, tools, paint
	for t in [0.18, 0.5, 0.82]:
		var wp := wallpos(r, "w", t, 0.3)
		if ok(id, wp[0], 1.0):
			p("ph/steel_frame_shelves_02", wp[0], wp[1], 2.1, true)
			for lv in [0.0, 0.72, 1.42]:
				if rng.randf() < 0.75:
					_cbox(wp[0] + Vector3(0.0, lv + 0.04, rng.randf_range(-0.12, 0.12)), Vector3(0.42, 0.3, 0.36), false)
	var c := r.get_center()
	for n in 7:
		var bp := Vector3(c.x + rng.randf_range(-0.6, 1.8), 0, c.y + rng.randf_range(-2.2, 2.2))
		if ok(id, bp, 1.1):
			if n < 2:
				p("ph/cardboard_box_01", bp, rng.randf() * 360.0, 0.0, true)
			else:
				_cbox(bp, Vector3(0.5, 0.38, 0.4), true)
				if rng.randf() < 0.5:
					_cbox(bp + Vector3(0.02, 0.38, 0.0), Vector3(0.44, 0.3, 0.36), false)
	p("ph/wooden_ladder", Vector3(r.end.x - 0.6, 0, r.position.y + 0.6), 30.0, 0.0, true)
	p("ph/hand_truck", Vector3(r.end.x - 0.5, 0, r.end.y - 0.7), 200.0)
	p("ph/metal_tool_chest", Vector3(c.x + 0.6, 0, r.position.y + 0.4), 0.0, 0.0, true)
	p("ph/portable_generator", Vector3(c.x - 0.4, 0, r.end.y - 0.5), 170.0, 0.0, true)
	p("ph/power_box_01", Vector3(c.x + 1.2, 0, r.end.y - 0.4), 180.0)
	for n in 4:
		var bp := Vector3(c.x + rng.randf_range(-0.8, 1.2), 0, c.y + rng.randf_range(-1.6, 1.6))
		if ok(id, bp, 1.0):
			k.cylinder(bp + Vector3(0, 0.2, 0), 0.15, 0.4, "l02_paint_can", 12, false)
	# drop cloth spread across the floor
	k.box_xf(Transform3D(Basis(Vector3.UP, rng.randf() * 0.4), Vector3(c.x + 0.3, 0.01, c.y + 0.4)), Vector3(2.6, 0.012, 2.0), "l02_dropcloth", GeoKit.ALL, false)
	p("ph/trashbag", Vector3(r.position.x + 1.6, 0, r.end.y - 0.4), 0.0)


func _conference(id: String, r: Rect2) -> void:
	var c := r.get_center()
	for dx in [-1.15, 1.15]:
		p("ph/dining_table", Vector3(c.x + dx, 0, c.y), 0.0, 0.0, true)
	for n in 4:
		var x := c.x - 1.5 + n * 1.0
		p("ph/dining_chair_02", Vector3(x, 0, c.y - 1.05), 0.0 + rng.randf_range(-12, 12))
		p("ph/dining_chair_02", Vector3(x, 0, c.y + 1.05), 180.0 + rng.randf_range(-12, 12))
	p("ph/office_notepads", Vector3(c.x - 0.6, 0.88, c.y), 0.0)
	p("ph/binder_notebook", Vector3(c.x + 0.8, 0.88, c.y + 0.2), 30.0)
	var wp := wallpos(r, "w", 0.5, 0.25)
	if ok(id, wp[0], 1.0):
		p("kenney/furniture-kit/cabinettelevision", wp[0], wp[1], 0.6, true)
		p("ph/Television_01", wp[0] + Vector3(0.05, 0.6, 0), wp[1])
	var bp := wallpos(r, "e", 0.5, 0.03)
	k.box(bp[0] + Vector3(-0.01, 1.45, 0), Vector3(0.02, 1.1, 2.2), "l02_board", GeoKit.ALL, false)
	k.box(bp[0] + Vector3(-0.025, 0.88, 0), Vector3(0.05, 0.03, 2.2), "l02_metal", GeoKit.ALL, false)
	p("kenney/furniture-kit/pottedplant", Vector3(r.end.x - 0.5, 0, r.position.y + 0.5), 0.0, 1.3)
	p("ph/wall_clock", wallpos(r, "n", 0.5, 0.04)[0] + Vector3(0, 2.05, 0), 0.0)
	_router(wallpos(r, "s", 0.85, 0.16)[0] + Vector3(0, 2.1, 0))


func _files(id: String, r: Rect2) -> void:
	for row in 2:
		for n in 4:
			var pos := Vector3(r.position.x + 0.9 + n * 1.2, 0, r.position.y + 1.4 + row * 2.4)
			if ok(id, pos, 1.0):
				p("ph/drawer_cabinet", pos, 0.0 if row == 0 else 180.0, 1.35, true)
	for n in 5:
		var bp := Vector3(r.position.x + rng.randf_range(0.6, 5.4), 0, r.position.y + rng.randf_range(2.4, 3.0))
		if ok(id, bp, 1.0):
			_cbox(bp, Vector3(0.45, 0.32, 0.36), false)


func _break(id: String, r: Rect2) -> void:
	# kitchenette along the north wall
	var z := r.position.y
	var x0 := r.position.x + 0.8
	var x1 := x0 + 4.2
	if ok(id, Vector3((x0 + x1) * 0.5, 0, z + 0.3), 2.2):
		k.box_mm(Vector3(x0, 0, z + 0.07), Vector3(x1, 0.88, z + 0.67), "l02_cabinet")
		k.box_mm(Vector3(x0 - 0.02, 0.88, z + 0.05), Vector3(x1 + 0.02, 0.92, z + 0.7), "l02_counter_top", GeoKit.ALL, false)
		k.box_mm(Vector3(x0, 1.45, z + 0.07), Vector3(x1, 2.15, z + 0.42), "l02_cabinet", GeoKit.ALL, false)
		p("kenney/furniture-kit/kitchenfridgelarge", Vector3(x1 + 0.55, 0, z + 0.45), 0.0, 1.85, true)
		p("kenney/furniture-kit/kitchenmicrowave", Vector3(x0 + 0.5, 0.92, z + 0.35), 0.0, 0.32)
		p("kenney/furniture-kit/kitchencoffeemachine", Vector3(x0 + 1.4, 0.92, z + 0.3), 0.0, 0.36)
		k.box_mm(Vector3(x0 + 2.4, 0.86, z + 0.2), Vector3(x0 + 3.0, 0.93, z + 0.6), "l02_metal", GeoKit.ALL, false)
	var c := r.get_center()
	p("ph/dining_table", Vector3(c.x - 2.6, 0, c.y + 0.4), 90.0, 0.0, true)
	for n in 4:
		var side := -1.0 if n < 2 else 1.0
		p("ph/plastic_monobloc_chair_01", Vector3(c.x - 2.6 + side * 0.95, 0, c.y + 0.4 + (n % 2 - 0.5) * 1.1), -90.0 * side + rng.randf_range(-15, 15))
	# lounge corner by the east wall
	var sx := r.end.x - 1.1
	p("ph/Sofa_01", Vector3(sx, 0, c.y + 1.2), -90.0, 0.0, true)
	p("ph/ArmChair_01", Vector3(sx - 1.3, 0, r.end.y - 0.7), 160.0, 0.0, true)
	p("ph/coffee_table_round_01", Vector3(sx - 1.4, 0, c.y + 1.2), 0.0, 0.4, true)
	p("kenney/furniture-kit/cabinettelevision", Vector3(sx - 3.2, 0, c.y + 1.2), 90.0, 0.55, true)
	p("ph/Television_01", Vector3(sx - 3.2, 0.55, c.y + 1.2), 90.0)
	p("kenney/furniture-kit/trashcan", Vector3(x0 - 0.4, 0, z + 0.35), 0.0, 0.6)
	_router(Vector3(x1 - 0.3, 2.15, z + 0.25))


func _lounge(id: String, r: Rect2) -> void:
	var pc: Vector2 = G.PIT.get_center()
	var y := G.PIT_Y
	p("ph/Sofa_01", Vector3(pc.x + 0.6, y, G.PIT.end.y - 0.55), 180.0, 0.0, true)
	p("ph/Sofa_01", Vector3(G.PIT.end.x - 0.55, y, pc.y + 0.2), -90.0, 0.0, true)
	p("ph/ArmChair_01", Vector3(pc.x - 1.8, y, pc.y + 1.3), 135.0, 0.0, true)
	p("ph/ArmChair_01", Vector3(pc.x + 2.4, y, G.PIT.position.y + 0.6), -20.0, 0.0, true)
	p("ph/coffee_table_round_01", Vector3(pc.x + 0.8, y, pc.y + 0.3), 0.0, 0.4, true)
	p("ph/office_notepads", Vector3(pc.x + 0.8, y + 0.4, pc.y + 0.3), 15.0)
	k.box_mm(Vector3(pc.x - 1.4, y, pc.y - 1.3), Vector3(pc.x + 3.0, y + 0.012, pc.y + 1.6), "l02_rug", GeoKit.ALL, false)
	for t in [0.25, 0.7]:
		var wp := wallpos(r, "e", t, 0.2)
		if ok(id, wp[0], 1.0):
			p("ph/Shelf_01", wp[0], wp[1], 0.0, true)
	p("kenney/furniture-kit/pottedplant", Vector3(r.position.x + 0.5, 0, r.end.y - 0.5), 0.0, 1.4)
	p("kenney/furniture-kit/pottedplant", Vector3(r.end.x - 0.5, 0, r.end.y - 0.5), 70.0, 1.4)
	p("kenney/furniture-kit/lamproundfloor", Vector3(G.PIT.end.x - 0.4, y, G.PIT.end.y - 0.4), 0.0, 1.55)
	lvl.lights.add_anchor(Vector3(G.PIT.end.x - 0.4, y + 1.5, G.PIT.end.y - 0.4), Color(1.0, 0.82, 0.6), 0.7, 4.0, 0.0, "lamp")
	_router(wallpos(r, "e", 0.25, 0.16)[0] + Vector3(0, 1.62, 0))


func _foreman(id: String, r: Rect2) -> void:
	# the crew's site office: the clipboard and documents are staged by the level
	var c := r.get_center()
	p("ph/metal_office_desk", Vector3(c.x, 0, c.y - 0.5), 0.0, 0.0, true)
	p("ph/GreenChair_01", Vector3(c.x + 0.3, 0, c.y + 0.4), 170.0)
	p("ph/vintage_radio_transceiver", Vector3(c.x + 0.6, 0.79, c.y - 0.75), -15.0)
	p("ph/binder_notebook", Vector3(c.x - 0.75, 0.79, c.y - 0.6), 20.0)
	p("ph/clipboard", Vector3(c.x - 0.15, 0.79, c.y - 0.35), 8.0)
	var wp := wallpos(r, "w", 0.3, 0.3)
	if ok(id, wp[0], 1.0):
		p("ph/drawer_cabinet", wp[0], wp[1], 1.3, true)
	p("ph/wooden_crate_01", Vector3(r.end.x - 0.6, 0, r.end.y - 0.4), 180.0)
	p("ph/hand_truck", Vector3(r.end.x - 0.45, 0, r.position.y + 0.6), -60.0)
	p("ph/plastic_bottle_gallon", Vector3(r.end.x - 0.9, 0, r.position.y + 0.4), 0.0)
	# cork board with pinned job sheets and a blue floor plan
	var bp := wallpos(r, "n", 0.5, 0.03)
	k.box(bp[0] + Vector3(0, 1.55, 0.01), Vector3(1.6, 0.9, 0.02), "l02_cork", GeoKit.ALL, false)
	k.box(bp[0] + Vector3(-0.35, 1.6, 0.025), Vector3(0.6, 0.45, 0.005), "l02_blueprint", GeoKit.ALL, false)
	for n in 3:
		k.box(bp[0] + Vector3(0.25 + n * 0.2, 1.5 + (n % 2) * 0.15, 0.025), Vector3(0.18, 0.25, 0.004), "paper", GeoKit.ALL, false)
	p("ph/wall_clock", wallpos(r, "e", 0.5, 0.04)[0] + Vector3(0, 2.0, 0), -90.0)


func _utility(id: String, r: Rect2) -> void:
	var c := r.get_center()
	k.cylinder(Vector3(r.end.x - 0.5, 0.78, r.position.y + 0.55), 0.3, 1.55, "l02_heater", 16)
	k.box_mm(Vector3(r.position.x + 0.1, 0, r.position.y + 0.07), Vector3(r.position.x + 0.9, 0.55, r.position.y + 0.7), "l02_mopsink")
	p("ph/utility_box_01", Vector3(c.x, 0, r.position.y + 0.3), 0.0, 1.0, true)
	p("ph/power_box_01", Vector3(c.x + 0.9, 1.3, r.position.y + 0.25), 0.0)
	var wp := wallpos(r, "e", 0.65, 0.3)
	if ok(id, wp[0], 1.0):
		p("ph/steel_frame_shelves_02", wp[0], wp[1], 2.1, true)
		p("ph/plastic_bottle_gallon", wp[0] + Vector3(0, 0.75, 0.1), 0.0)
		p("ph/plastic_crate_01", wp[0] + Vector3(0, 1.45, 0), 90.0)
	p("ph/WetFloorSign_01", Vector3(c.x - 0.5, 0, c.y + 0.8), 30.0)
	p("ph/trashbag", Vector3(r.position.x + 0.5, 0, r.end.y - 0.5), 0.0)
	k.box(Vector3(r.position.x + 0.7, 1.4, r.position.y + 0.08), Vector3(0.35, 0.5, 0.06), "l02_metal", GeoKit.ALL, false)


# ------------------------------------------------------------------ details

## Wall outlets around the room (page: consistently working outlets).
func _outlets(id: String, r: Rect2) -> void:
	if id in ["C", "N"]:
		return
	for side in ["n", "s", "e", "w"]:
		var t := 0.2 + rng.randf() * 0.6
		var wp := wallpos(r, side, t, 0.075)
		if not ok(id, wp[0], 1.0):
			continue
		var pos: Vector3 = wp[0] + Vector3(0, 0.32, 0)
		var sz := Vector3(0.075, 0.12, 0.012) if side in ["n", "s"] else Vector3(0.012, 0.12, 0.075)
		k.box(pos, sz, "l02_trim", GeoKit.ALL, false)


## A small Wi-Fi router with status LEDs (page: consistently working Wi-Fi).
func _router(pos: Vector3) -> void:
	if pos.y > 1.2:
		k.box(pos + Vector3(0, -0.01, 0), Vector3(0.34, 0.02, 0.2), "l02_trim", GeoKit.ALL, false)
	k.box(pos + Vector3(0, 0.03, 0), Vector3(0.26, 0.05, 0.17), "l02_router", GeoKit.ALL, false)
	for n in 2:
		k.box(pos + Vector3(-0.09 + n * 0.18, 0.13, 0.06), Vector3(0.012, 0.16, 0.012), "l02_router", GeoKit.ALL, false)
	k.box(pos + Vector3(0, 0.045, 0.087), Vector3(0.12, 0.012, 0.004), "l02_led", GeoKit.ALL, false)
	routers.append(pos)


## Framed prints: the kind of art a refit office is hung with.
func _art(id: String, r: Rect2, side: String, t: float) -> void:
	var wp := wallpos(r, side, t, 0.1)
	if not ok(id, wp[0], 1.1):
		return
	var along := Vector3(1, 0, 0) if side in ["n", "s"] else Vector3(0, 0, 1)
	var nrm := Vector3(0, 0, 1) if side == "n" else (Vector3(0, 0, -1) if side == "s" else (Vector3(1, 0, 0) if side == "w" else Vector3(-1, 0, 0)))
	var w := rng.randf_range(0.6, 1.1)
	var h := w * rng.randf_range(0.6, 0.85)
	var c: Vector3 = wp[0] + Vector3(0, 1.55, 0)
	var bas := Basis(along, Vector3.UP, along.cross(Vector3.UP))
	k.box_xf(Transform3D(bas, c), Vector3(w, h, 0.03), "l02_art_frame", GeoKit.ALL, false)
	k.box_xf(Transform3D(bas, c + nrm * 0.016), Vector3(w - 0.08, h - 0.08, 0.004), "l02_art_a" if rng.randf() < 0.5 else "l02_art_b", GeoKit.ALL, false)


## Cheap cardboard carton (the Poly Haven box is used only where it is seen up close).
func _cbox(pos: Vector3, size: Vector3, collide: bool) -> void:
	var b := Basis(Vector3.UP, rng.randf_range(-0.3, 0.3))
	k.box_xf(Transform3D(b, pos + Vector3(0, size.y * 0.5, 0)), size, "l02_cardboard", GeoKit.ALL, collide)
	k.box_xf(Transform3D(b, pos + Vector3(0, size.y + 0.001, 0)), Vector3(size.x * 0.98, 0.002, 0.05), "l02_tape", GeoKit.ALL, false)
