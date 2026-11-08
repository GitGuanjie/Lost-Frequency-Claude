extends RefCounted
## Level 1.1 set pieces: the Level 1 entrance, Outposts 1-4, Jakob's Hut and the
## M.E.G. cordon at the end of Sector 3. Everything here is from the page's
## Bases/Outposts and Entrances sections; layouts are ours (ADAPTATION).

const G := preload("res://levels/L001_1/L001_1_geo.gd")

var lvl
var geo: G


func _init(level, g) -> void:
	lvl = level
	geo = g


static func label(parent: Node3D, text: String, pos: Vector3, yaw: float, size: int = 48, col := Color(0.1, 0.1, 0.1)) -> Label3D:
	var lb := Label3D.new()
	lb.text = text
	lb.font_size = size
	lb.pixel_size = 0.004
	lb.modulate = col
	lb.outline_size = 0
	lb.position = pos
	lb.rotation.y = deg_to_rad(yaw)
	lb.double_sided = false
	parent.add_child(lb)
	return lb


## Chunk 0: the doorway back to Level 1 with a stretch of grey Level 1 hall
## behind it (the walk_in exit fills the doorway).
func entrance(k: GeoKit, node: Node3D) -> void:
	var hw := 3.66 * 0.5
	k.wall(Vector3(-hw - 0.3, 0, 0.12), Vector3(hw + 0.3, 0, 0.12), 3.2, 0.25, "l11_block", [{"at": hw + 0.3, "w": 2.2, "h": 2.4}])
	# Level 1 side: concrete, a pillar, darkness
	k.box_mm(Vector3(-5, -0.3, 0.25), Vector3(5, 0, 9), "l11_l1_floor")
	k.box_mm(Vector3(-5, 3.4, 0.25), Vector3(5, 3.7, 9), "l11_l1_wall")
	k.box_mm(Vector3(-5.3, -0.3, 0.25), Vector3(-5, 3.7, 9), "l11_l1_wall")
	k.box_mm(Vector3(5, -0.3, 0.25), Vector3(5.3, 3.7, 9), "l11_l1_wall")
	k.box_mm(Vector3(-5.3, -0.3, 9), Vector3(5.3, 3.7, 9.3), "l11_l1_wall")
	k.box(Vector3(2.6, 1.7, 5.5), Vector3(0.9, 3.4, 0.9), "l11_l1_wall")
	k.box(Vector3(-2.2, 3.2, 4.0), Vector3(0.18, 0.18, 9.0), "l11_rust", GeoKit.ALL, false)
	k.box(Vector3(1.0, 3.25, 4.0), Vector3(0.12, 0.12, 9.0), "l11_pipe", GeoKit.ALL, false)
	geo.fixture(k, Vector3(-1.2, 3.4, 5.0), "l11_tube_l1", 3.0)
	lvl.lights.add_anchor(Vector3(-1.2, 3.0, 5.0), Color(0.85, 0.9, 0.95), 0.6, 6.0, 0.25, "k0")
	# the sign posted outside the entrance (faces Level 1)
	k.box(Vector3(1.9, 2.0, 0.33), Vector3(1.1, 0.5, 0.03), "l11_sign_white", GeoKit.ALL, false)
	label(node, "LEVEL 1.1\nENTRANCE", Vector3(1.9, 2.0, 0.355), 0.0, 40)
	# inside: M.E.G. notice beside the doorway, facing the corridor
	k.box(Vector3(-1.45, 1.6, -0.03), Vector3(0.5, 0.65, 0.02), "l11_sign_white", GeoKit.ALL, false)
	label(node, "M.E.G.\nLEVEL 1.1\nSECTOR 1", Vector3(-1.45, 1.62, -0.045), 180.0, 22)


## Outpost 1 (Sector 1): a room off the corridor like an unfinished basement:
## unpainted block, wooden boards over dirt, bunks four sets three high,
## coolers, a supply store, piping and ducts, fluorescent light.
func outpost1(k: GeoKit, node: Node3D, z0: float, r: RandomNumberGenerator) -> Dictionary:
	var hw := 3.66 * 0.5
	var xd := -hw - G.WALL_T          # inner face of the corridor wall (room side)
	var zc := z0 - 3.0
	var x0 := xd - 8.0
	var fy := -0.54
	var z_a := zc + 4.5
	var z_b := zc - 4.5
	k.box_mm(Vector3(x0, fy - 0.3, z_b), Vector3(xd - 0.9, fy, z_a), "l11_plank")
	k.box_mm(Vector3(xd - 0.9, fy - 0.3, z_b), Vector3(xd, fy, zc - 1.1), "l11_plank")
	k.box_mm(Vector3(xd - 0.9, fy - 0.3, zc + 1.1), Vector3(xd, fy, z_a), "l11_plank")
	k.stairs(Vector3(xd - 0.9, fy, zc), Vector3(1, 0, 0), 2.2, -fy, 3, "l11_plank", 0.3)
	k.box_mm(Vector3(xd, fy - 0.3, z_b), Vector3(xd + 0.3, 0.0, z_a), "l11_block_raw")
	k.box_mm(Vector3(x0, 2.4, z_b), Vector3(xd, 2.7, z_a), "l11_block_raw", GeoKit.ALL, false)
	k.box_mm(Vector3(x0 - 0.25, fy - 0.3, z_b), Vector3(x0, 2.7, z_a), "l11_block_raw")
	k.box_mm(Vector3(x0 - 0.25, fy - 0.3, z_a), Vector3(xd, 2.7, z_a + 0.25), "l11_block_raw")
	k.box_mm(Vector3(x0 - 0.25, fy - 0.3, z_b - 0.25), Vector3(xd, 2.7, z_b), "l11_block_raw")
	# ducts and pipes on the ceiling
	k.box(Vector3(x0 + 4.0, 2.2, zc), Vector3(0.6, 0.35, 8.8), "l11_duct", GeoKit.ALL, false)
	k.box(Vector3(x0 + 1.0, 2.3, zc), Vector3(0.12, 0.12, 8.8), "l11_rust", GeoKit.ALL, false)
	k.box(Vector3(x0 + 6.6, 2.32, zc), Vector3(0.09, 0.09, 8.8), "l11_pipe", GeoKit.ALL, false)
	for fz in [zc + 2.2, zc - 2.2]:
		geo.fixture(k, Vector3(x0 + 5.5, 2.4, fz), "l11_tube", r.randf() * 9.0)
		lvl.lights.add_anchor(Vector3(x0 + 5.5, 2.0, fz), Color(0.92, 0.95, 1.0), 1.0, 6.5, 0.0, "k2")
	# four bunk sets, three high, along the far wall
	for b in 4:
		var bz := z_a - 1.2 - b * 2.1
		_bunk(k, Vector3(x0 + 1.05, fy, bz), 3)
	# coolers and the supply store along the south wall
	for c in 3:
		var p := Vector3(x0 + 3.2 + c * 0.85, fy, z_b + 0.45)
		k.box(p + Vector3(0, 0.25, 0), Vector3(0.7, 0.5, 0.45), "l11_cooler")
		k.box(p + Vector3(0, 0.52, 0), Vector3(0.72, 0.05, 0.47), "l11_cooler_lid", GeoKit.ALL, false)
	for s in 2:
		var sp := Vector3(x0 + 6.0 + s * 0.8, fy, z_b + 0.35)
		Props.place(lvl, node, "ph/steel_frame_shelves_02", sp, 0.0, 2.0, true)
		for lv in [0.05, 0.75, 1.45]:
			k.box(sp + Vector3(0, lv + 0.14, 0), Vector3(0.45, 0.28, 0.35), "l11_cardboard", GeoKit.ALL, false)
	# table with the survey note
	k.box_mm(Vector3(x0 + 3.0, fy, zc - 0.5), Vector3(x0 + 4.6, fy + 0.74, zc + 0.5), "l11_wood")
	Props.place(lvl, node, "ph/vintage_radio_transceiver", Vector3(x0 + 4.1, fy + 0.74, zc + 0.15), 200.0)
	Props.place(lvl, node, "ph/plastic_crate_01", Vector3(x0 + 2.4, fy, zc + 1.6), 15.0)
	Props.place(lvl, node, "ph/plastic_monobloc_chair_01", Vector3(x0 + 3.8, fy, zc + 1.0), 160.0)
	k.box(Vector3(xd - 0.02, 2.0, zc + 1.6), Vector3(0.03, 0.4, 0.9), "l11_sign_white", GeoKit.ALL, false)
	label(node, "OUTPOST 1\nM.E.G.", Vector3(xd - 0.04, 2.0, zc + 1.6), -90.0, 26)
	return {"note_at": Vector3(x0 + 3.5, fy + 0.78, zc - 0.1), "rest": Vector3(x0 + 4.0, fy, zc + 2.5),
		"open": {"at": 3.0, "w": 2.2, "h": 2.3}}


func _bunk(k: GeoKit, base: Vector3, levels: int) -> void:
	for corner in [Vector2(-0.45, -0.95), Vector2(0.45, -0.95), Vector2(-0.45, 0.95), Vector2(0.45, 0.95)]:
		k.box(base + Vector3(corner.x, 1.2, corner.y), Vector3(0.05, 2.4, 0.05), "l11_metal")
	for i in levels:
		var y := 0.32 + i * 0.75
		k.box(base + Vector3(0, y, 0), Vector3(0.95, 0.05, 1.95), "l11_metal", GeoKit.ALL, false)
		k.box(base + Vector3(0, y + 0.09, 0), Vector3(0.88, 0.13, 1.88), "l11_mattress", GeoKit.ALL, false)
		var bl: String = ["l11_cloth_r", "l11_cloth_g", "l11_cloth_b", "l11_cloth_y"][int(absf(base.z * 7.0 + i * 3.0)) % 4]
		k.box(base + Vector3(0.02, y + 0.17, 0.25), Vector3(0.9, 0.05, 1.25), bl, GeoKit.ALL, false)
		k.box(base + Vector3(0, y + 0.2, -0.72), Vector3(0.55, 0.1, 0.32), "l11_sign_white", GeoKit.ALL, false)


## Outpost 2: the trading hall (the widened chunk) with a doorway on either side
## into a small network of rooms: dormitory (16 bunks) + storage to the west,
## kitchen/dining + common area to the east. White tile throughout.
func outpost2(k: GeoKit, node: Node3D, zc: float, r: RandomNumberGenerator) -> Dictionary:
	var hw := 7.2 * 0.5
	var xd := hw + G.WALL_T
	var tubes: Array = []
	for side in [-1.0, 1.0]:
		var xa: float = side * xd
		var xb: float = side * (xd + 10.0)
		var x_lo := minf(xa, xb)
		var x_hi := maxf(xa, xb)
		var z_a := zc + 6.0
		var z_m := zc - 4.0
		var z_b := zc - 10.0
		k.box_mm(Vector3(x_lo, -0.3, z_b), Vector3(x_hi, 0.0, z_a), "l11_wtile_floor")
		k.box_mm(Vector3(x_lo, 3.0, z_b), Vector3(x_hi, 3.3, z_a), "l11_wtile", GeoKit.ALL, false)
		k.box_mm(Vector3(minf(xb, xb + side * 0.25), -0.3, z_b - 0.25), Vector3(maxf(xb, xb + side * 0.25), 3.3, z_a + 0.25), "l11_wtile")
		k.box_mm(Vector3(x_lo, -0.3, z_a), Vector3(x_hi, 3.3, z_a + 0.25), "l11_wtile")
		k.box_mm(Vector3(x_lo, -0.3, z_b - 0.25), Vector3(x_hi, 3.3, z_b), "l11_wtile")
		# partition between the two rooms of this side, with a doorway
		k.wall(Vector3(x_lo, 0, z_m), Vector3(x_hi, 0, z_m), 3.0, 0.15, "l11_wtile", [{"at": 2.0 if side > 0 else 8.0, "w": 1.0, "h": 2.1}])
		for fz in [zc + 3.0, zc - 1.5, zc - 7.0]:
			var fp := Vector3(side * (xd + 5.0), 3.0, fz)
			geo.fixture(k, fp, "l11_tube_o2", r.randf() * 9.0)
			tubes.append(fp)
		if side < 0:
			# dormitory: eight double bunks = 16 bunks
			for b in 8:
				var bx := x_lo + 1.0 + (b % 4) * 2.3
				var bz := z_a - 1.3 if b < 4 else z_m + 1.3
				_bunk(k, Vector3(bx, 0, bz), 2)
			# storage room: shelving and crates
			for s in 4:
				Props.place(lvl, node, "ph/steel_frame_shelves_02", Vector3(x_lo + 1.0 + s * 1.6, 0, z_b + 0.4), 0.0, 2.1, true)
				for lv in [0.05, 0.75, 1.45]:
					k.box(Vector3(x_lo + 1.0 + s * 1.6, lv + 0.15, z_b + 0.4), Vector3(0.48, 0.3, 0.38), "l11_cardboard", GeoKit.ALL, false)
			for c in 5:
				_crate(k, Vector3(x_lo + 1.5 + r.randf() * 7.0, 0, z_m - 2.5 - r.randf() * 2.0), r)
		else:
			# kitchen + dining
			k.box_mm(Vector3(x_hi - 0.7, 0, z_a - 8.0), Vector3(x_hi - 0.05, 0.9, z_a - 0.3), "l11_counter")
			Props.place(lvl, node, "kenney/furniture-kit/kitchenstove", Vector3(x_hi - 0.45, 0, z_a - 2.0), -90.0, 0.9, true)
			Props.place(lvl, node, "kenney/furniture-kit/kitchenfridgelarge", Vector3(x_hi - 0.45, 0, z_a - 0.6), -90.0, 1.85, true)
			Props.place(lvl, node, "kenney/furniture-kit/kitchenmicrowave", Vector3(x_hi - 0.4, 0.9, z_a - 4.5), -90.0, 0.32)
			for t in 2:
				var tp := Vector3(x_lo + 3.0 + t * 3.0, 0, zc + 1.5)
				Props.place(lvl, node, "ph/wooden_picnic_table", tp, 0.0, 0.0, true)
			# common area: sofa, armchairs, TV
			Props.place(lvl, node, "ph/Sofa_01", Vector3(x_lo + 4.0, 0, z_b + 0.6), 0.0, 0.0, true)
			Props.place(lvl, node, "ph/ArmChair_01", Vector3(x_lo + 2.0, 0, z_b + 2.2), 60.0, 0.0, true)
			Props.place(lvl, node, "ph/coffee_table_round_01", Vector3(x_lo + 4.0, 0, z_b + 2.2), 0.0, 0.42, true)
			Props.place(lvl, node, "kenney/furniture-kit/cabinettelevision", Vector3(x_lo + 4.0, 0, z_m - 0.4), 180.0, 0.6, true)
			Props.place(lvl, node, "ph/Television_01", Vector3(x_lo + 4.0, 0.6, z_m - 0.4), 180.0)
			Props.place(lvl, node, "ph/vintage_radio_transceiver", Vector3(x_hi - 0.4, 0.9, z_a - 6.0), -90.0)
	# trading hall: folding tables of goods along both walls
	for side in [-1.0, 1.0]:
		for t in 3:
			var tz := zc + 8.0 - t * 5.5
			if absf(tz - (zc + 3.0)) < 1.8:
				continue
			var tx: float = side * (hw - 0.55)
			k.box_mm(Vector3(tx - 0.4, 0.7, tz - 0.9), Vector3(tx + 0.4, 0.74, tz + 0.9), "l11_counter", GeoKit.ALL, false)
			for leg in [Vector2(-0.35, -0.85), Vector2(0.35, -0.85), Vector2(-0.35, 0.85), Vector2(0.35, 0.85)]:
				k.box(Vector3(tx + leg.x, 0.35, tz + leg.y), Vector3(0.03, 0.7, 0.03), "l11_metal", GeoKit.ALL, false)
			for g in 5:
				var gp := Vector3(tx + r.randf_range(-0.25, 0.25), 0.74, tz + r.randf_range(-0.7, 0.7))
				var sz := Vector3(r.randf_range(0.12, 0.3), r.randf_range(0.1, 0.3), r.randf_range(0.12, 0.3))
				k.box(gp + Vector3(0, sz.y * 0.5, 0), sz, ["l11_cardboard", "l11_bottle", "l11_cloth_r", "l11_cloth_g", "l11_can"][r.randi() % 5], GeoKit.ALL, false)
			k.add_box_shape(Transform3D(Basis(), Vector3(tx, 0.37, tz)), Vector3(0.8, 0.74, 1.8), "wood")
	k.box(Vector3(0, 2.62, zc + 11.9), Vector3(3.0, 0.36, 0.04), "l11_sign_white", GeoKit.ALL, false)
	for cxs in [-1.3, 1.3]:
		k.box(Vector3(cxs, 2.9, zc + 11.9), Vector3(0.02, 0.2, 0.02), "l11_metal", GeoKit.ALL, false)
	label(node, "OUTPOST 2  —  TRADING HALL", Vector3(0, 2.62, zc + 11.925), 0.0, 30)
	var timer_at := Vector3(-hw + 0.06, 1.5, zc + 9.0)
	k.box(timer_at, Vector3(0.1, 0.35, 0.25), "l11_metal", GeoKit.ALL, false)
	return {"tubes": tubes, "timer_at": timer_at, "west": {"at": 6.0, "w": 1.6, "h": 2.2}, "east": {"at": 6.0, "w": 1.6, "h": 2.2}}


## Outpost 3: a supply shelf on the wall with a cot underneath. Its items are
## separate nodes so the level can make them vanish (page: supplies have been
## known to inexplicably disappear from the shelf).
func outpost3(k: GeoKit, node: Node3D, z: float, y: float, r: RandomNumberGenerator) -> Array:
	var hw := 3.66 * 0.5
	var x := hw - 0.25
	k.box(Vector3(x, y + 1.1, z), Vector3(0.45, 0.04, 2.0), "l11_metal", GeoKit.ALL, false)
	k.box(Vector3(x, y + 1.6, z), Vector3(0.45, 0.04, 2.0), "l11_metal", GeoKit.ALL, false)
	for dz in [-0.98, 0.98]:
		k.box(Vector3(x + 0.2, y + 0.9, z + dz), Vector3(0.04, 1.8, 0.04), "l11_metal", GeoKit.ALL, false)
	k.box(Vector3(x - 0.1, y + 0.3, z), Vector3(0.7, 0.08, 1.85), "l11_canvas")
	k.box(Vector3(x - 0.1, y + 0.36, z + 0.7), Vector3(0.5, 0.06, 0.35), "l11_mattress", GeoKit.ALL, false)
	k.box(Vector3(x - 0.24, y + 2.0, z), Vector3(0.02, 0.3, 0.9), "l11_sign_white", GeoKit.ALL, false)
	label(node, "OUTPOST 3", Vector3(x - 0.26, y + 2.0, z), -90.0, 26)
	var items: Array = []
	for i in 7:
		var mi := MeshInstance3D.new()
		var shelf_y := y + (1.12 if i < 4 else 1.62)
		var iz := z - 0.8 + (i % 4) * 0.5
		if i % 2 == 0:
			var cm := CylinderMesh.new()
			cm.top_radius = 0.06
			cm.bottom_radius = 0.06
			cm.height = 0.24
			mi.mesh = cm
			mi.material_override = MatLib.get_mat("l11_bottle")
			mi.position = Vector3(x, shelf_y + 0.12, iz)
		else:
			var bm := BoxMesh.new()
			bm.size = Vector3(0.3, 0.2, 0.25)
			mi.mesh = bm
			mi.material_override = MatLib.get_mat("l11_cardboard" if i % 3 else "l11_can")
			mi.position = Vector3(x, shelf_y + 0.1, iz)
		node.add_child(mi)
		items.append(mi)
	return items


## Jakob's Hut: clothes and bedding speared on sticks in a large recess.
func hut(k: GeoKit, node: Node3D, z: float, y: float, r: RandomNumberGenerator) -> Dictionary:
	var hw := 3.66 * 0.5
	var x0 := hw + G.WALL_T
	var depth := 6.0
	var zl := z + 3.5
	var zr := z - 3.5
	k.box_mm(Vector3(x0 - 0.05, y - 0.3, zr), Vector3(x0 + depth, y, zl), "l11_floor")
	k.box_mm(Vector3(x0, y + 3.0, zr), Vector3(x0 + depth, y + 3.3, zl), "l11_ceil", GeoKit.ALL, false)
	k.box_mm(Vector3(x0 + depth, y - 0.3, zr - 0.25), Vector3(x0 + depth + 0.25, y + 3.3, zl + 0.25), "l11_block")
	k.box_mm(Vector3(x0, y - 0.3, zl), Vector3(x0 + depth, y + 3.3, zl + 0.25), "l11_block")
	k.box_mm(Vector3(x0, y - 0.3, zr - 0.25), Vector3(x0 + depth, y + 3.3, zr), "l11_block")
	var c := Vector3(x0 + 3.2, y, z)
	var apex := c + Vector3(0, 2.4, 0)
	var cloths := ["l11_cloth_r", "l11_cloth_g", "l11_cloth_b", "l11_cloth_y", "l11_canvas", "l11_mattress"]
	for i in 9:
		var a := TAU * i / 9.0 + 0.2
		var foot := c + Vector3(cos(a) * 1.9, 0, sin(a) * 1.9)
		var dir := (apex - foot)
		var mid := (apex + foot) * 0.5
		var up := dir.normalized()
		var side := up.cross(Vector3(cos(a + PI * 0.5), 0, sin(a + PI * 0.5))).normalized()
		k.box_xf(Transform3D(Basis(side, up, side.cross(up)), mid + up * 0.15), Vector3(0.04, dir.length() + 0.3, 0.04), "l11_stick", GeoKit.ALL, false)
		if i != 6:
			var b := Vector3(cos(a + 0.35), 0, sin(a + 0.35))
			var drape := (apex * 0.45 + (c + b * 1.75) * 0.55)
			var n_out := (drape - (c + Vector3(0, drape.y - c.y, 0))).normalized()
			var t := n_out.cross(Vector3.UP).normalized()
			var u := t.cross(n_out).normalized()
			k.box_xf(Transform3D(Basis(t, u, n_out), drape + Vector3(0, -0.25, 0)), Vector3(1.35, 1.7, 0.03), cloths[i % cloths.size()], GeoKit.ALL, false)
	k.add_box_shape(Transform3D(Basis(), c + Vector3(0, 1.2, 0)), Vector3(3.8, 2.4, 3.8), "wood")
	for s in 3:
		var sp := Vector3(x0 + 0.9, y, z + 2.6 - s * 0.9)
		k.box(sp + Vector3(0, 0.08, 0), Vector3(0.8, 0.16, 0.75), cloths[(s + 2) % cloths.size()], GeoKit.ALL, false)
	_crate(k, Vector3(x0 + 5.3, y, z + 2.6), r)
	_crate(k, Vector3(x0 + 5.3, y, z + 1.6), r)
	Props.place(lvl, node, "ph/vintage_flashlight", Vector3(x0 + 1.6, y, z - 2.6), 40.0)
	Props.place(lvl, node, "ph/plastic_bottle_gallon", Vector3(x0 + 5.4, y, z - 2.8), 0.0)
	Props.place(lvl, node, "ph/vintage_suitcase", Vector3(x0 + 4.8, y, z - 1.4), 100.0)
	return {"lantern": Vector3(x0 + 1.4, y + 0.5, z - 1.4), "note_at": Vector3(x0 + 1.4, y + 0.05, z - 1.9)}


## Outpost 4: a wooden storage crate about four feet on all axes in the middle
## of the dark hall.
func outpost4(k: GeoKit, node: Node3D, z: float, y: float) -> Vector3:
	var c := Vector3(0, y + 0.61, z)
	k.box(c, Vector3(1.22, 1.22, 1.22), "l11_crate")
	for e in [-0.56, 0.56]:
		k.box(c + Vector3(0, e, 0), Vector3(1.26, 0.1, 1.26), "l11_crate_dark", GeoKit.ALL, false)
	label(node, "OUTPOST 4", c + Vector3(0, 0.15, 0.625), 0.0, 30, Color(0.85, 0.85, 0.8))
	return c


## The M.E.G. cordon at the end of Sector 3: sign and tape (explorers still pass).
func cordon(k: GeoKit, node: Node3D, z: float, y: float, w: float) -> void:
	var hw := w * 0.5
	for x in [-hw + 0.2, hw - 0.2]:
		k.box(Vector3(x, y + 0.55, z), Vector3(0.06, 1.1, 0.06), "l11_metal", GeoKit.ALL, false)
	for h in [0.6, 1.0]:
		k.box(Vector3(0, y + h, z), Vector3(w - 0.3, 0.06, 0.006), "l11_tape", GeoKit.ALL, false)
	var sp := Vector3(-hw * 0.4, y, z + 0.6)
	k.box(sp + Vector3(-0.5, 0.75, 0), Vector3(0.05, 1.5, 0.05), "l11_metal", GeoKit.ALL, false)
	k.box(sp + Vector3(0.5, 0.75, 0), Vector3(0.05, 1.5, 0.05), "l11_metal", GeoKit.ALL, false)
	k.box(sp + Vector3(0, 1.45, 0), Vector3(1.3, 0.8, 0.04), "l11_sign_yellow")
	label(node, "WARNING!\nDo not pass this point.\nDeath is imminent to all\nwho enter Sector 4.\n— M.E.G.", sp + Vector3(0, 1.45, 0.025), 0.0, 22)


func _crate(k: GeoKit, p: Vector3, r: RandomNumberGenerator) -> void:
	var sz := Vector3(r.randf_range(0.6, 1.0), r.randf_range(0.45, 0.8), r.randf_range(0.5, 0.8))
	k.box_xf(Transform3D(Basis(Vector3.UP, r.randf_range(-0.2, 0.2)), p + Vector3(0, sz.y * 0.5, 0)), sz, "l11_crate")
