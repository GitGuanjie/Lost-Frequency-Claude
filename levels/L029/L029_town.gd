extends RefCounted
## Level 29 inner circle: Hyperia and the farms.
## SOURCE: Hyperia is a modest-sized settlement in the middle of the island,
## surrounded by forest and tall mountains; the hub through which all trading
## passes ("a gigantic industrial complex"), with office-like buildings that
## act as diplomatic stations for many societies, "a gathering station, and not
## a capital". Between the mountains: small wooden towns, large farms, huts.
## ADAPTATION: a timber town around a market plaza, a three-storey diplomatic
## hall with a public gallery reached by a grand stair, a covered trade hall
## stacked with goods and ore from the caves, a timber yard, a bridge over the
## Almond Water river, farm fields with huts and fences.

var lvl
var ter
var bk
var k: GeoKit
var props: Node3D
var hall_gallery := Vector3.ZERO
var hall_front_z := 0.0
var footprints: Array = []        # [Vector2 centre, radius] kept clear of trees
var stall_spots: Array = []

const HALL := Vector3(0.0, 0.0, -252.0)
const HALL_W := 30.0
const HALL_D := 14.0


func _init(level, terrain, build_kit, kit: GeoKit, prop_parent: Node3D) -> void:
	lvl = level
	ter = terrain
	bk = build_kit
	k = kit
	props = prop_parent


func build() -> void:
	_hall()
	_houses()
	_trade_hall(Vector3(40.0, 0, -207.0))
	_stalls()
	_timber_yard(Vector3(-52.0, 0, -160.0))
	_bridge(-312.0)
	_farms()
	_plaza_dressing()


func _foot(p: Vector3, r: float) -> void:
	footprints.append([Vector2(p.x, p.z), r])


# ------------------------------------------------------------ the hall

func _hall() -> void:
	var o := HALL
	bk.solid(o, 0.0, HALL_W, HALL_D, 3, {"door_x": 0.0, "pitch": 3.2, "chimney": false, "wall": "l29_plank"})
	_foot(o, 19.0)
	var b := Basis()
	var gs: Vector2 = bk.ground_span(o, b, HALL_W, HALL_D)
	var fy := gs.y + 0.25
	var gal_y := fy + 3.0
	hall_front_z = o.z + HALL_D * 0.5
	var z0 := hall_front_z
	var z1 := z0 + 3.2
	# public gallery along the front at the second floor
	k.slab(-HALL_W * 0.5, z0, HALL_W * 0.5, z1, gal_y, 0.24, "l29_deck_wood")
	for i in 7:
		var x := -HALL_W * 0.5 + 0.3 + i * (HALL_W - 0.6) / 6.0
		var gy: float = ter.h(x, z1 - 0.2)
		k.box(Vector3(x, (gy - 0.3 + gal_y + 2.9) * 0.5, z1 - 0.2), Vector3(0.36, gal_y + 2.9 - gy + 0.3, 0.36), "l29_timber")
	k.box(Vector3(0, gal_y + 2.95, z1 - 0.2), Vector3(HALL_W + 0.4, 0.3, 0.4), "l29_timber", GeoKit.ALL, false)
	bk.rail(Vector3(-HALL_W * 0.5, gal_y, z1), Vector3(-1.2, gal_y, z1))
	bk.rail(Vector3(1.2, gal_y, z1), Vector3(HALL_W * 0.5, gal_y, z1))
	bk.rail(Vector3(-HALL_W * 0.5, gal_y, z0), Vector3(-HALL_W * 0.5, gal_y, z1))
	bk.rail(Vector3(HALL_W * 0.5, gal_y, z0), Vector3(HALL_W * 0.5, gal_y, z1))
	bk.stair_to(Vector3(0, gal_y, z1), Vector3(0, 0, -1), 2.2, "l29_deck_wood")
	hall_gallery = Vector3(0, gal_y, (z0 + z1) * 0.5)
	# gallery-level doors and benches
	for x in [-9.0, 0.0, 9.0]:
		k.box(Vector3(x, gal_y + 1.05, z0 + 0.05), Vector3(1.1, 2.1, 0.1), "l29_timber", GeoKit.ALL, false)
		k.box(Vector3(x, gal_y + 1.12, z0 + 0.02), Vector3(1.4, 2.3, 0.06), "l29_deck_wood", GeoKit.ALL, false)
	for x in [-5.0, 5.0, -12.5, 12.5]:
		bk.prop(props, "kenney/graveyard-kit/bench-damaged", Vector3(x, gal_y, z0 + 0.6), 0.0, 0.9)
	# the banners of the societies that keep offices here (no names: most
	# nations have no formal name, per the page)
	var cloths := ["l29_cloth_a", "l29_cloth_b", "l29_cloth_c", "l29_cloth_d", "l29_cloth_a", "l29_cloth_c"]
	for i in 6:
		var x := -12.5 + i * 5.0
		k.box(Vector3(x, gal_y - 1.2, z1 + 0.02), Vector3(1.3, 2.3, 0.04), cloths[i], GeoKit.ALL, false)
		k.box(Vector3(x, gal_y - 0.04, z1 + 0.02), Vector3(1.5, 0.08, 0.08), "l29_timber", GeoKit.ALL, false)
	# sign board over the main door
	k.box(Vector3(0, fy + 2.55, z0 + 0.12), Vector3(4.2, 0.6, 0.1), "l29_whitewash", GeoKit.ALL, false)
	var lab := Label3D.new()
	lab.text = "HYPERIA  —  GATHERING STATION"
	lab.font_size = 64
	lab.pixel_size = 0.004
	lab.modulate = Color(0.16, 0.06, 0.05)
	lab.outline_size = 0
	lab.shaded = true
	lab.position = Vector3(0, fy + 2.55, z0 + 0.18)
	lvl.add_child(lab)


# ------------------------------------------------------------ houses

func _houses() -> void:
	# [x, z, yaw, w, d, storeys]
	var list := [
		[-13.0, -150.0, 90.0, 7.0, 6.0, 2], [13.5, -152.0, -90.0, 8.0, 6.0, 2], [-13.5, -166.0, 90.0, 6.5, 5.5, 1],
		[14.0, -168.0, -90.0, 7.0, 6.5, 2], [-30.0, -180.0, 120.0, 8.0, 6.0, 2], [-38.0, -200.0, 90.0, 7.5, 6.0, 2],
		[-39.0, -219.0, 80.0, 7.0, 6.5, 1], [-33.0, -238.0, 50.0, 8.5, 6.0, 2], [31.0, -236.0, -50.0, 8.0, 6.0, 2],
		[30.0, -181.0, -120.0, 7.0, 6.0, 1], [-56.0, -186.0, 95.0, 7.0, 5.5, 1], [-58.0, -222.0, 75.0, 8.0, 6.0, 2],
		[58.0, -240.0, -70.0, 7.0, 6.0, 1], [-26.0, -276.0, 10.0, 7.5, 6.0, 2], [27.0, -278.0, -15.0, 7.0, 6.0, 1],
		[-46.0, -258.0, 40.0, 6.5, 5.5, 1], [47.0, -170.0, -100.0, 6.5, 5.5, 1], [-16.0, -134.0, 80.0, 6.0, 5.0, 1],
	]
	for h in list:
		var o := Vector3(h[0], 0, h[1])
		bk.solid(o, h[2], h[3], h[4], h[5], {"door_x": 0.0})
		_foot(o, maxf(h[3], h[4]) * 0.75)
		# washing lines, barrels, a bench by some doors
		var b := Basis(Vector3.UP, deg_to_rad(h[2]))
		var front: Vector3 = o + b * Vector3(h[3] * 0.5 - 0.7, 0, h[4] * 0.5 + 0.9)
		front.y = ter.h(front.x, front.z)
		bk.prop(props, "ph/Barrel_01" if int(h[0]) % 2 == 0 else "ph/wooden_crate_01", front, lvl.rng.randf_range(0, 360), 0.0, true)
		if int(h[1]) % 3 == 0:
			var bp: Vector3 = o + b * Vector3(-h[3] * 0.5 + 1.2, 0, h[4] * 0.5 + 0.8)
			bk.prop(props, "kenney/graveyard-kit/bench-damaged", Vector3(bp.x, ter.h(bp.x, bp.z), bp.z), h[2], 0.9)


# ------------------------------------------------------------ trade

func _trade_hall(o: Vector3) -> void:
	# a long roof on red-wood posts, open on three sides, with a closed back
	var w := 26.0
	var d := 12.0
	var b := Basis(Vector3.UP, deg_to_rad(-90.0))
	var gs: Vector2 = bk.ground_span(o, b, w, d)
	var fy := gs.y + 0.15
	k.box_xf(Transform3D(b, Vector3(o.x, (fy + gs.x - 0.6) * 0.5, o.z)), Vector3(w + 0.4, fy - gs.x + 0.6, d + 0.4), "l29_stone")
	_foot(o, 15.0)
	for i in 6:
		for s in [-1.0, 1.0]:
			var lp := Vector3(-w * 0.5 + 0.3 + i * (w - 0.6) / 5.0, 0, s * (d * 0.5 - 0.3))
			var p: Vector3 = o + b * lp
			k.box(Vector3(p.x, fy + 2.4, p.z), Vector3(0.36, 4.8, 0.36), "l29_timber")
	k.box_xf(Transform3D(b, o + b * Vector3(0, fy + 2.4, -d * 0.5 + 0.1)), Vector3(w, 4.8, 0.2), "l29_plank")
	bk.roof(Vector3(o.x, 0, o.z), b, w, d, fy + 4.8, 2.6, "l29_plank")
	# goods: crates, barrels, sacks, ore from the cave veins (iron and copper)
	var ids := ["ph/wooden_crate_01", "ph/Barrel_01", "ph/barrel_03", "ph/old_military_crate", "ph/cardboard_box_01", "kenney/food-kit/bag"]
	for row in 3:
		for i in 9:
			var lp := Vector3(-w * 0.5 + 1.8 + i * 2.8 + lvl.rng.randf_range(-0.4, 0.4), 0, -d * 0.5 + 1.6 + row * 3.2 + lvl.rng.randf_range(-0.3, 0.3))
			if row == 1 and i % 3 == 1:
				continue
			var p: Vector3 = o + b * lp
			p.y = fy
			var id: String = ids[(i + row * 2) % ids.size()]
			bk.prop(props, id, p, lvl.rng.randf_range(0, 360), 0.55 if id.ends_with("bag") else 0.0, row != 1)
			if id == "ph/wooden_crate_01":
				bk.prop(props, id, p + Vector3(0, 0.6, 0), lvl.rng.randf_range(0, 360))
				bk.prop(props, id, p + Vector3(0, 1.2, 0), lvl.rng.randf_range(0, 360))
	for j in 4:
		var lp := Vector3(-8.0 + j * 5.0, 0, d * 0.5 - 1.6)
		var p: Vector3 = o + b * lp
		var mat := "l29_iron" if j % 2 == 0 else "l29_copper"
		for q in 7:
			var off := Vector3(lvl.rng.randf_range(-0.7, 0.7), 0, lvl.rng.randf_range(-0.5, 0.5))
			var s: float = lvl.rng.randf_range(0.25, 0.5)
			k.box_xf(Transform3D(Basis.from_euler(Vector3(lvl.rng.randf(), lvl.rng.randf() * 3.0, lvl.rng.randf())), p + off + Vector3(0, fy + 0.65 + s * 0.3, 0)), Vector3(s, s * 0.7, s * 0.9), mat, GeoKit.ALL, false)
		k.box(p + Vector3(0, fy + 0.3, 0), Vector3(1.9, 0.6, 1.2), "l29_deck_wood")
	bk.prop(props, "ph/hand_truck", o + b * Vector3(6.0, 0, 0) + Vector3(0, fy, 0), 40.0)
	bk.prop(props, "ph/CashRegister_01", o + b * Vector3(-11.0, 0, 2.0) + Vector3(0, fy + 0.88, 0), -90.0)
	bk.prop(props, "ph/dining_table", o + b * Vector3(-11.0, 0, 2.0) + Vector3(0, fy, 0), 0.0, 0.0, true)
	for i in 3:
		bk.prop(props, "ph/hanging_industrial_lamp", o + b * Vector3(-8.0 + i * 8.0, 0, 0) + Vector3(0, fy + 3.4, 0), 0.0)


func _stalls() -> void:
	var cl := ["l29_cloth_a", "l29_cloth_b", "l29_cloth_c", "l29_cloth_d"]
	var n := 9
	for i in n:
		var a := -PI * 0.5 + (float(i) + 0.5) / n * TAU
		if absf(wrapf(a - PI * 0.5, -PI, PI)) < 0.45 or absf(wrapf(a + PI * 0.5, -PI, PI)) < 0.35:
			continue
		var c: Vector3 = ter.TOWN + Vector3(cos(a), 0, sin(a)) * 13.5
		c.y = 0.0
		var yaw := rad_to_deg(atan2(ter.TOWN.x - c.x, ter.TOWN.z - c.z))
		_stall(c, yaw, cl[i % cl.size()], i)


func _lane_stalls() -> void:
	# a market lane from the plaza up to the hall stair
	var cl := ["l29_cloth_b", "l29_cloth_c", "l29_cloth_a", "l29_cloth_d"]
	var i := 0
	for z in [-221.0, -228.5]:
		for sx in [-1.0, 1.0]:
			var c := Vector3(sx * 6.2, 0, z)
			var yaw: float = -90.0 * sx
			_stall(c, yaw, cl[i % 4], i)
			i += 1


func _stall(c: Vector3, yaw: float, cloth: String, i: int) -> void:
	var goods := ["kenney/food-kit/barrel", "kenney/food-kit/bag", "kenney/food-kit/bowl", "kenney/food-kit/pot-stew", "kenney/food-kit/carton", "ph/plastic_crate_01"]
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	var y: float = ter.h(c.x, c.z)
	for sx in [-1.3, 1.3]:
		for sz in [-0.9, 0.9]:
			var p: Vector3 = c + b * Vector3(sx, 0, sz)
			k.box(Vector3(p.x, y + 1.25 + (0.2 if sz < 0 else 0.0), p.z), Vector3(0.12, 2.5 + (0.4 if sz < 0 else 0.0), 0.12), "l29_timber", GeoKit.ALL, false)
	k.box_xf(Transform3D(b * Basis(Vector3.RIGHT, -0.22), c + Vector3(0, y + 2.6, 0)), Vector3(3.0, 0.05, 2.2), cloth, GeoKit.ALL, false)
	k.box_xf(Transform3D(b, c + b * Vector3(0, 0, 0.75) + Vector3(0, y + 0.45, 0)), Vector3(2.6, 0.9, 0.6), "l29_deck_wood")
	stall_spots.append(c)
	for g in 3:
		var gp: Vector3 = c + b * Vector3(-0.8 + g * 0.8, 0, 0.75)
		var id: String = goods[(i + g) % goods.size()]
		bk.prop(props, id, Vector3(gp.x, y + 0.9, gp.z), lvl.rng.randf_range(0, 360), 0.32 if id.begins_with("kenney") else 0.0)
	bk.prop(props, "ph/barrel_03", c + b * Vector3(1.6, 0, -0.6) + Vector3(0, y, 0), 0.0, 0.0, true)
	bk.prop(props, "ph/wooden_crate_01", c + b * Vector3(-1.7, 0, -0.4) + Vector3(0, y, 0), 30.0, 0.0, true)


func _plaza_dressing() -> void:
	_lane_stalls()
	var c: Vector3 = ter.TOWN
	# the trade board: a timber pillar hung with notices, at the plaza centre
	k.box(c + Vector3(0, 1.6, 0), Vector3(0.9, 3.2, 0.9), "l29_timber")
	k.box(c + Vector3(0, 3.35, 0), Vector3(1.5, 0.3, 1.5), "l29_roof", GeoKit.ALL, false)
	for s in 4:
		var d := Vector3(cos(s * PI * 0.5), 0, sin(s * PI * 0.5))
		for j in 3:
			var p := c + d * 0.47 + Vector3(0, 1.3 + j * 0.42, 0) + Vector3(-d.z, 0, d.x) * (j - 1) * 0.2
			k.box(p, Vector3(0.3 if absf(d.z) > 0.5 else 0.01, 0.34, 0.01 if absf(d.z) > 0.5 else 0.3), "paper", GeoKit.ALL, false)
	for a in [0.3, 1.9, 3.4, 4.9]:
		var p := c + Vector3(cos(a), 0, sin(a)) * 24.0
		k.box(p + Vector3(0, 1.7, 0), Vector3(0.18, 3.4, 0.18), "l29_timber")
		k.box(p + Vector3(0, 3.25, 0), Vector3(0.9, 0.1, 0.1), "l29_timber", GeoKit.ALL, false)
		bk.prop(props, "ph/lantern_chandelier_01", p + Vector3(0.4, 2.4, 0), 0.0, 0.8)
	for i in 6:
		var p := c + Vector3(lvl.rng.randf_range(-9.0, 9.0), 0, lvl.rng.randf_range(-9.0, 9.0))
		if p.distance_to(c) < 2.5:
			continue
		bk.prop(props, ["ph/wooden_crate_01", "ph/Barrel_01", "ph/barrel_03"][i % 3], p, lvl.rng.randf_range(0, 360), 0.0, true)
	for cp in [[Vector3(-19.0, 0, 6.0), 70.0], [Vector3(16.0, 0, -11.0), -30.0], [Vector3(4.0, 0, 21.0), 10.0], [Vector3(-10.0, 0, -19.0), 120.0]]:
		_cart(c + (cp[0] as Vector3), cp[1])
	# a well with a timber headframe
	var wp := c + Vector3(-6.0, 0, -6.5)
	k.cylinder(wp + Vector3(0, 0.45, 0), 1.0, 0.9, "l29_stone", 14, true, true)
	k.cylinder(wp + Vector3(0, 0.91, 0), 0.82, 0.03, "unlit_black", 14, false, true)
	for sx in [-0.95, 0.95]:
		k.box(wp + Vector3(sx, 1.3, 0), Vector3(0.14, 2.6, 0.14), "l29_timber", GeoKit.ALL, false)
	k.box(wp + Vector3(0, 2.4, 0), Vector3(2.1, 0.14, 0.14), "l29_timber", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.RIGHT, 0.5), wp + Vector3(0, 2.75, 0.45)), Vector3(2.4, 0.08, 1.2), "l29_roof", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.RIGHT, -0.5), wp + Vector3(0, 2.75, -0.45)), Vector3(2.4, 0.08, 1.2), "l29_roof", GeoKit.ALL, false)
	bk.prop(props, "ph/barrel_03", wp + Vector3(1.4, 0, 0.6), 0.0, 0.6)
	bk.prop(props, "ph/wooden_picnic_table", c + Vector3(-8.0, 0, 9.0), 30.0, 0.0, true)
	bk.prop(props, "ph/wooden_picnic_table", c + Vector3(7.5, 0, 10.0), -20.0, 0.0, true)


func _cart(p: Vector3, yaw: float) -> void:
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	p.y = ter.h(p.x, p.z)
	k.box_xf(Transform3D(b, p + Vector3(0, 0.75, 0)), Vector3(1.4, 0.08, 2.4), "l29_deck_wood", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, p + Vector3(0, 0.7, 0)), Vector3(1.3, 0.9, 2.2), "l29_deck_wood", 0, true)
	for sx in [-0.7, 0.7]:
		k.box_xf(Transform3D(b, p + b * Vector3(sx, 0.98, 0)), Vector3(0.06, 0.4, 2.4), "l29_plank", GeoKit.ALL, false)
		var wh := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.48
		cm.bottom_radius = 0.48
		cm.height = 0.1
		cm.radial_segments = 14
		wh.mesh = cm
		wh.material_override = MatLib.get_mat("l29_timber")
		wh.transform = Transform3D(b * Basis(Vector3.FORWARD, PI * 0.5), p + b * Vector3(sx * 1.12, 0.48, 0.2))
		lvl.add_child(wh)
	for sx in [-0.35, 0.35]:
		k.box_xf(Transform3D(b * Basis(Vector3.RIGHT, -0.25), p + b * Vector3(sx, 0.55, 1.9)), Vector3(0.07, 0.07, 1.8), "l29_timber", GeoKit.ALL, false)
	for i in 3:
		var id: String = ["ph/wooden_crate_01", "kenney/food-kit/bag", "ph/barrel_03"][(i + int(yaw)) % 3]
		bk.prop(props, id, p + b * Vector3(0, 0.79, -0.6 + i * 0.6), yaw + 10.0 * i, 0.5 if id.begins_with("kenney") else 0.0)


func _timber_yard(o: Vector3) -> void:
	# red logs of the native tree and sawn beams (SOURCE: easily cut with an axe;
	# a chemical process makes the wood one of the strongest materials)
	o.y = ter.h(o.x, o.z)
	_foot(o, 10.0)
	for row in 3:
		for i in 5 - row:
			var lg := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.38
			cm.bottom_radius = 0.42
			cm.height = 7.0
			cm.radial_segments = 10
			lg.mesh = cm
			lg.material_override = MatLib.get_mat("l29_bark")
			lg.rotation = Vector3(0, 0, PI * 0.5)
			lg.position = o + Vector3(0, 0.42 + row * 0.72, -1.6 + i * 0.82 + row * 0.41)
			lvl.add_child(lg)
	k.box(o + Vector3(0, 1.2, 0.0), Vector3(7.0, 2.4, 4.4), "l29_bark", 0, true)
	for i in 4:
		k.box(o + Vector3(6.5, 0.2 + i * 0.32, -1.0), Vector3(4.0, 0.3, 2.2 - i * 0.3), "l29_plank")
	bk.prop(props, "ph/wooden_ladder", o + Vector3(4.0, 0, 2.0), 0.0, 2.2)
	bk.prop(props, "ph/metal_tool_chest", o + Vector3(8.5, 0, 1.2), 40.0)
	# a saw bench under a lean-to roof
	k.box(o + Vector3(6.0, 0.5, 4.0), Vector3(3.2, 1.0, 1.0), "l29_deck_wood")
	for sx in [-2.0, 2.0]:
		k.box(o + Vector3(6.0 + sx, 1.6, 5.4), Vector3(0.2, 3.2, 0.2), "l29_timber", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.RIGHT, 0.25), o + Vector3(6.0, 3.1, 4.4)), Vector3(4.6, 0.12, 3.0), "l29_roof", GeoKit.ALL, false)


func _bridge(z: float) -> void:
	var x0: float = ter.RIVER_X - 13.0
	var x1: float = ter.RIVER_X + 15.0
	var y: float = ter.WATER_Y + 1.6
	var ga: float = ter.h(x0, z)
	var gb: float = ter.h(x1, z)
	k.ramp(Vector3(x0 - 4.0, ga, z), Vector3(x0, y, z), 3.0, 0.3, "l29_deck_wood")
	k.ramp(Vector3(x1, y, z), Vector3(x1 + 4.0, gb, z), 3.0, 0.3, "l29_deck_wood")
	k.slab(x0, z - 1.5, x1, z + 1.5, y, 0.25, "l29_deck_wood")
	for s in [-1.0, 1.0]:
		bk.rail(Vector3(x0, y, z + s * 1.5), Vector3(x1, y, z + s * 1.5))
	for x in range(int(x0) + 2, int(x1), 4):
		var g: float = ter.h(float(x), z)
		for s in [-1.0, 1.0]:
			k.cylinder(Vector3(x, (y + g - 1.0) * 0.5, z + s * 1.4), 0.18, y - g + 1.0, "l29_timber", 7, false, true)


# ------------------------------------------------------------ farms

func _farms() -> void:
	for i in ter.FIELDS.size():
		var f: Array = ter.FIELDS[i]
		var c := Vector3(f[0], 0, f[1])
		# a hut at one corner and a fence along one long side
		var hx: float = f[0] + (f[2] + 4.5) * (1.0 if i % 2 == 0 else -1.0)
		var hz: float = f[1] - f[3] + 3.0
		bk.solid(Vector3(hx, 0, hz), 90.0 if i % 2 == 1 else -90.0, 4.6, 3.8, 1, {"door_x": 0.0, "chimney": i % 3 == 0})
		_foot(Vector3(hx, 0, hz), 4.0)
		var fz: float = f[1] + f[3] + 1.2
		var x := float(f[0]) - float(f[2])
		while x < float(f[0]) + float(f[2]):
			var nx := minf(x + 2.4, float(f[0]) + float(f[2]))
			var ya: float = ter.h(x, fz)
			var yb: float = ter.h(nx, fz)
			k.box(Vector3(x, ya + 0.55, fz), Vector3(0.12, 1.1, 0.12), "l29_timber", GeoKit.ALL, false)
			for ry in [0.45, 0.9]:
				var a := Vector3(x, ya + ry, fz)
				var bb := Vector3(nx, yb + ry, fz)
				k.box_xf(Transform3D(Basis.looking_at((bb - a).normalized(), Vector3.UP), (a + bb) * 0.5), Vector3(0.05, 0.1, a.distance_to(bb)), "l29_timber", GeoKit.ALL, false)
			x = nx
		bk.prop(props, "ph/wooden_crate_01", Vector3(hx + 1.5, ter.h(hx + 1.5, hz + 3.0), hz + 3.0), 30.0)
		if i % 2 == 0:
			bk.prop(props, "ph/Barrel_01", Vector3(hx - 1.4, ter.h(hx - 1.4, hz + 2.8), hz + 2.8), 0.0, 0.0, true)
