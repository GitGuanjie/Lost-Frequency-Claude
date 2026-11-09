extends RefCounted
## Level 140 camp: the lobby cottage (honey bottles, the strainer, the queen's
## jar, a closet with a jacket, a sleeping loft), the porch, the backyard
## garden with "the little one", and the beehive by the first sunflower field.
## SOURCE (testimony): "the multiple bottles we have sitting around in the
## lobby", flowers in the backyard, the little one "a bit sad and tired", a
## beehive "not too far from the first sunflower field", a jacket "from the
## closet". ADAPTATION: the cottage layout, loft and furniture are ours.

var lvl
var ter
var k: GeoKit
var props: Node3D
var fy := 0.0
var loft_y := 0.0
var jar_spots: Array = []         # free shelf spots for new jars
var little_one: Node3D
var light_ids: Array = []
var door := Vector3.ZERO
var porch := Vector3.ZERO
var hive_spots: Array = []

const X0 := -12.0
const X1 := -4.0
const Z0 := -5.5
const Z1 := 5.5
const WALL_H := 3.0


func _init(level, terrain, kit: GeoKit, prop_parent: Node3D) -> void:
	lvl = level
	ter = terrain
	k = kit
	props = prop_parent


static func materials() -> void:
	_tex("l140_boards", "old_wood_floor", Color(1.0, 0.86, 0.68), 2.0)
	_tex("l140_floor_wood", "old_wood_floor", Color(0.85, 0.66, 0.48), 1.8)
	MatLib.define("l140_wall_paint", {"albedo_a": Color(0.82, 0.76, 0.62), "albedo_b": Color(0.76, 0.7, 0.56), "pattern": 2,
		"pattern_scale": Vector2(0.18, 1.0), "pattern_color": Color(0.68, 0.62, 0.5), "pattern_strength": 0.35, "noise_scale": 1.0}, "plaster")
	MatLib.define("l140_roof", {"albedo_a": Color(0.42, 0.2, 0.14), "albedo_b": Color(0.34, 0.16, 0.11), "pattern": 14,
		"pattern_scale": Vector2(0.38, 0.2), "grout_width": 0.03, "grout_color": Color(0.16, 0.08, 0.05), "tile_variation": 0.15}, "rock")
	MatLib.define("l140_stone", {"albedo_a": Color(0.5, 0.47, 0.42), "albedo_b": Color(0.4, 0.37, 0.33), "pattern": 4,
		"pattern_scale": Vector2(0.5, 0.25), "grout_width": 0.03, "grout_color": Color(0.3, 0.28, 0.25)}, "rock")
	MatLib.define("l140_trim", {"albedo_a": Color(0.3, 0.42, 0.32), "albedo_b": Color(0.26, 0.38, 0.28), "noise_scale": 2.0}, "wood_floor")
	MatLib.define("l140_hive_a", {"albedo_a": Color(0.92, 0.88, 0.78), "albedo_b": Color(0.86, 0.82, 0.72), "noise_scale": 2.0, "stain_amount": 0.2}, "plaster")
	MatLib.define("l140_hive_b", {"albedo_a": Color(0.92, 0.75, 0.3), "albedo_b": Color(0.86, 0.7, 0.26), "noise_scale": 2.0, "stain_amount": 0.2}, "plaster")
	MatLib.define("l140_hive_c", {"albedo_a": Color(0.45, 0.62, 0.72), "albedo_b": Color(0.4, 0.56, 0.66), "noise_scale": 2.0, "stain_amount": 0.2}, "plaster")
	var pane := StandardMaterial3D.new()
	pane.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pane.albedo_color = Color(0.7, 0.8, 0.85, 0.15)
	pane.roughness = 0.05
	MatLib.register("l140_glass", pane)
	var honey := StandardMaterial3D.new()
	honey.albedo_color = Color(0.85, 0.5, 0.08)
	honey.roughness = 0.15
	honey.emission_enabled = true
	honey.emission = Color(0.35, 0.16, 0.02)
	honey.rim_enabled = true
	honey.rim = 0.4
	MatLib.register("l140_honey", honey)
	MatLib.register("l140_window_lit", MatLib.panel(Color(1.0, 0.75, 0.42), 1.2))
	MatLib.register("l140_comb", MatLib.standard(Color(0.9, 0.62, 0.15), 0.3, 0.0, Color(0.3, 0.15, 0.0), 0.3))


static func _tex(name: String, asset: String, tint: Color, rep: float) -> void:
	var base := "res://assets/external/%s/%s_%%s_1k.jpg" % [asset, asset]
	if not ResourceLoader.exists(base % "diff"):
		MatLib.define(name, {"albedo_a": tint * 0.5, "albedo_b": tint * 0.4}, "wood_floor")
		return
	var m := StandardMaterial3D.new()
	m.albedo_texture = load(base % "diff")
	m.albedo_color = tint
	if ResourceLoader.exists(base % "nor_gl"):
		m.normal_enabled = true
		m.normal_texture = load(base % "nor_gl")
	m.roughness = 0.8
	m.uv1_scale = Vector3(1.0 / rep, 1.0 / rep, 1.0)
	MatLib.register(name, m)


func build() -> void:
	_cottage()
	_interior()
	_porch()
	_backyard()
	_hives()


func _cottage() -> void:
	var pad: float = ter.h_pad()
	fy = pad + 0.45
	loft_y = fy + 2.75
	k.box_mm(Vector3(X0 - 0.2, pad - 0.8, Z0 - 0.2), Vector3(X1 + 0.2, fy, Z1 + 0.2), "l140_stone")
	k.box_mm(Vector3(X0 + 0.1, fy - 0.05, Z0 + 0.1), Vector3(X1 - 0.1, fy + 0.02, Z1 - 0.1), "l140_floor_wood")
	var win := {"w": 1.0, "h": 1.2, "sill": 0.9}
	door = Vector3(X1, fy, 1.6)
	k.wall(Vector3(X1, fy, Z0), Vector3(X1, fy, Z1), WALL_H, 0.2, "l140_boards", [{"at": 1.6 - Z0, "w": 1.1, "h": 2.15, "sill": 0.0}, win.merged({"at": 3.6})])
	k.wall(Vector3(X0, fy, Z0), Vector3(X0, fy, Z1), WALL_H, 0.2, "l140_boards", [{"at": 9.8, "w": 0.95, "h": 2.05, "sill": 0.0}])
	k.wall(Vector3(X0, fy, Z1), Vector3(X1, fy, Z1), WALL_H, 0.2, "l140_boards", [win.merged({"at": 2.6}), win.merged({"at": 5.6})])
	k.wall(Vector3(X0, fy, Z0), Vector3(X1, fy, Z0), WALL_H, 0.2, "l140_boards", [win.merged({"at": 5.6})])
	# panes and frames in the window openings
	for p in [[Vector3(X1, fy + 1.5, Z0 + 3.6), Vector3(0.04, 1.2, 1.0)], 			[Vector3(X0 + 2.6, fy + 1.5, Z1), Vector3(1.0, 1.2, 0.04)], [Vector3(X0 + 5.6, fy + 1.5, Z1), Vector3(1.0, 1.2, 0.04)],
			[Vector3(X0 + 5.6, fy + 1.5, Z0), Vector3(1.0, 1.2, 0.04)]]:
		k.box(p[0], p[1], "l140_glass", GeoKit.ALL, false)
		var fr: Vector3 = p[1]
		k.box(p[0] - Vector3(0, 0.62, 0), Vector3(maxf(fr.x, 0.3) + 0.2, 0.06, maxf(fr.z, 0.3) + 0.2), "l140_trim", GeoKit.ALL, false)
	for c in [Vector3(X0, 0, Z0), Vector3(X1, 0, Z0), Vector3(X0, 0, Z1), Vector3(X1, 0, Z1)]:
		k.box(Vector3(c.x, fy + WALL_H * 0.5, c.z), Vector3(0.24, WALL_H, 0.24), "l140_trim", GeoKit.ALL, false)
	# gable roof, ridge along z
	var pitch := 3.2
	var half := (X1 - X0) * 0.5 + 0.5
	var ang := atan2(pitch, (X1 - X0) * 0.5)
	var cx := (X0 + X1) * 0.5
	for s in [-1.0, 1.0]:
		var c := Vector3(cx + s * half * 0.5, fy + WALL_H + pitch * 0.5 - 0.5 * tan(ang) * 0.5 + 0.08, 0.0)
		k.box_xf(Transform3D(Basis(Vector3.BACK, -s * ang), c), Vector3(half / cos(ang), 0.14, Z1 - Z0 + 1.2), "l140_roof", GeoKit.ALL & ~GeoKit.NY, false)
		k.box_xf(Transform3D(Basis(Vector3.BACK, -s * ang), c - Vector3(0, 0.1, 0)), Vector3(half / cos(ang) - 0.3, 0.04, Z1 - Z0 + 0.2), "l140_boards", GeoKit.ALL, false)
	for sz in [Z0, Z1]:
		k._tri_fan(Vector3(cx, fy + WALL_H + pitch, sz), Vector3(X0, fy + WALL_H, sz), Vector3(X1, fy + WALL_H, sz), Vector3(0, 0, signf(sz)), "l140_boards")
		k._tri_fan(Vector3(cx, fy + WALL_H + pitch, sz - signf(sz) * 0.1), Vector3(X0, fy + WALL_H, sz - signf(sz) * 0.1), Vector3(X1, fy + WALL_H, sz - signf(sz) * 0.1), Vector3(0, 0, -signf(sz)), "l140_boards")
	k.box(Vector3(X0 + 1.4, fy + WALL_H + pitch * 0.7, -2.5), Vector3(0.6, pitch * 1.4, 0.6), "l140_stone", GeoKit.ALL, false)
	# loft over the west half, stair along the north wall
	k.slab(X0 + 0.1, Z0 + 0.1, cx, Z1 - 0.1, loft_y, 0.18, "l140_floor_wood")
	var steps := 16
	var run := 0.23
	k.stairs(Vector3(cx + steps * run, fy, Z0 + 0.75), Vector3(-1, 0, 0), 1.0, loft_y - fy, steps, "l140_floor_wood", run)
	for i in 4:
		var z := Z0 + 1.35 + i * (Z1 - Z0 - 1.5) / 3.0
		k.box(Vector3(cx + 0.05, loft_y + 0.5, z), Vector3(0.07, 1.0, 0.07), "l140_trim", GeoKit.ALL, false)
	var ra := Vector3(cx + 0.05, loft_y, Z0 + 1.35)
	var rb := Vector3(cx + 0.05, loft_y, Z1 - 0.15)
	k.box(Vector3(ra.x, loft_y + 1.0, (ra.z + rb.z) * 0.5), Vector3(0.08, 0.08, rb.z - ra.z), "l140_trim", GeoKit.ALL, false)
	k.box(Vector3(ra.x, loft_y + 0.55, (ra.z + rb.z) * 0.5), Vector3(0.12, 1.1, rb.z - ra.z), "l140_trim", 0, true)
	# lit window panels for the evening
	for p in [[Vector3(X1 - 0.3, fy + 1.5, Z0 + 3.6), Vector3(0.04, 1.0, 0.8)], [Vector3(X0 + 2.6, fy + 1.5, Z1 - 0.3), Vector3(0.8, 1.0, 0.04)]]:
		k.box(p[0], p[1], "l140_window_lit", GeoKit.ALL, false)
	light_ids.append(lvl.lights.add_anchor(Vector3(cx + 1.5, fy + 2.4, 0.5), Color(1.0, 0.72, 0.42), 1.1, 8.0, 0.0, "cottage"))
	light_ids.append(lvl.lights.add_anchor(Vector3(X0 + 1.8, loft_y + 1.6, 0.0), Color(1.0, 0.7, 0.4), 0.8, 5.0, 0.0, "loft"))


func _jar(p: Vector3, big: bool = false) -> void:
	var r := 0.07 if not big else 0.1
	var hgt := 0.17 if not big else 0.24
	k.cylinder(p + Vector3(0, hgt * 0.5, 0), r, hgt, "l140_honey", 10, false, true)
	k.cylinder(p + Vector3(0, hgt + 0.02, 0), r * 0.85, 0.04, "l140_trim", 10, false, true)


func _interior() -> void:
	# honey shelves along the west wall under the loft
	for sx in [0]:
		var x: float = X0 + 0.35 + sx
		for zi in 2:
			var zc := -2.2 + zi * 3.6
			for hy in [0.45, 0.95, 1.45, 1.95]:
				k.box(Vector3(x, fy + hy, zc), Vector3(0.4, 0.04, 2.4), "l140_boards", GeoKit.ALL, false)
				for j in 9:
					var z := zc - 1.05 + j * 0.26
					if lvl.rng.randf() < 0.82:
						_jar(Vector3(x + lvl.rng.randf_range(-0.05, 0.05), fy + hy + 0.02, z), lvl.rng.randf() < 0.25)
					elif hy < 1.5:
						jar_spots.append(Vector3(x, fy + hy + 0.02, z))
			for sz in [-1.2, 1.2]:
				k.box(Vector3(x, fy + 1.1, zc + sz), Vector3(0.42, 2.2, 0.05), "l140_boards", GeoKit.ALL, false)
	# the table where the wax is strained into bottles
	var t := Vector3(-8.5, fy, 0.8)
	Props.place(lvl, props, "ph/dining_table", t, 90.0, 0.0, true)
	Props.place(lvl, props, "ph/dining_chair_02", t + Vector3(-1.0, 0, 0.6), 90.0)
	Props.place(lvl, props, "ph/dining_chair_02", t + Vector3(1.0, 0, -0.5), -90.0)
	Props.place(lvl, props, "kenney/food-kit/pot", t + Vector3(0, 0.88, -0.3), 0.0, 0.3)
	for i in 3:
		k.box_xf(Transform3D(Basis(Vector3.UP, 0.3 * i), t + Vector3(-0.2 + i * 0.25, 0.9, 0.4)), Vector3(0.42, 0.03, 0.22), "l140_comb", GeoKit.ALL, false)
	for i in 5:
		_jar(t + Vector3(0.25 + i * 0.14, 0.88, -0.25 + (i % 2) * 0.15))
	_jar(t + Vector3(-0.5, 0.88, 0.0), true)
	k.cylinder(t + Vector3(-0.5, 0.88 + 0.3, 0.0), 0.105, 0.03, "l140_window_lit", 10, false, true)
	# kitchen corner (south wall) and the closet (north-east)
	for i in 3:
		Props.place(lvl, props, "kenney/furniture-kit/kitchencabinet", Vector3(-7.4 + i * 0.95, fy, Z1 - 0.55), 180.0, 0.9)
	Props.place(lvl, props, "kenney/furniture-kit/kitchensink", Vector3(-4.55, fy, Z1 - 0.55), 180.0, 0.9)
	Props.place(lvl, props, "kenney/furniture-kit/kitchenstove", Vector3(-8.35, fy, Z1 - 0.55), 180.0, 0.9)
	Props.place(lvl, props, "ph/drawer_cabinet", Vector3(-4.6, fy, -1.6), -90.0, 1.9, true)
	Props.place(lvl, props, "ph/ArmChair_01", Vector3(-5.2, fy, 3.0), -120.0)
	Props.place(lvl, props, "kenney/furniture-kit/rugrounded", Vector3(-7.0, fy + 0.02, 1.0), 0.0, 0.02)
	Props.place(lvl, props, "ph/vintage_radio_transceiver", Vector3(-4.5, fy + 1.9, -1.6), -90.0)
	Props.place(lvl, props, "ph/wall_clock", Vector3(-8.0, fy + 2.2, Z0 + 0.12), 0.0)
	Props.place(lvl, props, "ph/lantern_chandelier_01", Vector3(-6.4, fy + 2.0, 0.5), 0.0, 0.7)
	# loft: two beds, a nightstand
	Props.place(lvl, props, "kenney/furniture-kit/bedsingle", Vector3(X0 + 1.4, loft_y, -2.4), 90.0, 0.55)
	Props.place(lvl, props, "kenney/furniture-kit/bedsingle", Vector3(X0 + 1.4, loft_y, 1.2), 90.0, 0.55)
	Props.place(lvl, props, "ph/ClassicNightstand_01", Vector3(X0 + 0.5, loft_y, -0.6), 90.0)
	Props.place(lvl, props, "ph/vintage_flashlight", Vector3(X0 + 0.5, loft_y + 0.7, -0.6), 30.0)


func _porch() -> void:
	var x0 := X1
	var x1 := X1 + 2.6
	k.slab(x0, Z0 + 0.5, x1, Z1 - 0.5, fy, 0.2, "l140_floor_wood")
	for z in [Z0 + 0.6, 0.0, Z1 - 0.6]:
		k.box(Vector3(x1 - 0.15, fy + 1.3, z), Vector3(0.15, 2.6, 0.15), "l140_trim")
	k.box_xf(Transform3D(Basis(Vector3.BACK, -0.25), Vector3(X1 + 1.3, fy + 2.8, 0.0)), Vector3(3.0, 0.08, Z1 - Z0), "l140_roof", GeoKit.ALL, false)
	var g: float = ter.h(x1 + 1.0, 1.6)
	var n := maxi(1, int(ceil((fy - g) / 0.17)))
	k.stairs(Vector3(x1 + n * 0.3, g, 1.6), Vector3(-1, 0, 0), 1.6, fy - g, n, "l140_floor_wood", 0.3)
	porch = Vector3(X1 + 1.3, fy, 1.6)
	Props.place(lvl, props, "kenney/furniture-kit/chairrounded", Vector3(X1 + 1.2, fy, -3.0), -90.0, 0.95)
	Props.place(lvl, props, "kenney/furniture-kit/chairrounded", Vector3(X1 + 1.2, fy, -1.6), -90.0, 0.95)
	Props.place(lvl, props, "kenney/furniture-kit/sidetable", Vector3(X1 + 1.3, fy, -2.3), 0.0, 0.55)
	_jar(Vector3(X1 + 1.3, fy + 0.56, -2.3))
	Props.place(lvl, props, "ph/lantern_chandelier_01", Vector3(X1 + 1.6, fy + 1.75, 3.4), 0.0, 0.7)
	light_ids.append(lvl.lights.add_anchor(Vector3(X1 + 1.6, fy + 2.0, 3.4), Color(1.0, 0.7, 0.4), 0.9, 7.0, 0.04, "porch"))


func _backyard() -> void:
	var x0 := -30.0
	var x1 := X0 - 0.6
	var z0 := -7.0
	var z1 := 7.0
	# a low picket fence with a gate gap behind the back door
	for e in [[Vector2(x0, z0), Vector2(x1, z0)], [Vector2(x0, z1), Vector2(x1, z1)], [Vector2(x0, z0), Vector2(x0, z1)]]:
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		var n := int(a.distance_to(b) / 0.4)
		for i in n + 1:
			var p := a.lerp(b, float(i) / n)
			var y: float = ter.h(p.x, p.y)
			k.box(Vector3(p.x, y + 0.45, p.y), Vector3(0.07, 0.9, 0.05), "l140_hive_a", GeoKit.ALL, false)
		var ya: float = ter.h(a.x, a.y)
		var yb: float = ter.h(b.x, b.y)
		for ry in [0.3, 0.7]:
			var pa := Vector3(a.x, ya + ry, a.y)
			var pb := Vector3(b.x, yb + ry, b.y)
			k.box_xf(Transform3D(Basis.looking_at((pb - pa).normalized(), Vector3.UP), (pa + pb) * 0.5), Vector3(0.03, 0.07, pa.distance_to(pb)), "l140_hive_a", GeoKit.ALL, false)
		k.box_xf(Transform3D(Basis.looking_at((Vector3(b.x, yb, b.y) - Vector3(a.x, ya, a.y)).normalized(), Vector3.UP), Vector3((a.x + b.x) * 0.5, (ya + yb) * 0.5 + 0.45, (a.y + b.y) * 0.5)), Vector3(0.1, 0.9, a.distance_to(b)), "l140_hive_a", 0, true)
	# raised beds
	for i in 3:
		var c := Vector3(x0 + 3.5 + i * 5.0, 0, -2.5)
		c.y = ter.h(c.x, c.z)
		k.box(c + Vector3(0, 0.15, 0), Vector3(3.6, 0.3, 1.4), "l140_boards")
		var c2 := Vector3(c.x, 0, 3.5)
		c2.y = ter.h(c2.x, c2.z)
		k.box(c2 + Vector3(0, 0.15, 0), Vector3(3.6, 0.3, 1.4), "l140_boards")
	Props.place(lvl, props, "kenney/furniture-kit/bench", Vector3(-25.0, ter.h(-25.0, 6.0), 6.0), 180.0, 1.0)
	# the watering can
	var wc := Vector3(-13.6, ter.h(-13.6, 2.6), 2.6)
	k.cylinder(wc + Vector3(0, 0.15, 0), 0.13, 0.3, "l140_trim", 10, false, true)
	k.box_xf(Transform3D(Basis(Vector3.BACK, 0.8), wc + Vector3(0.22, 0.24, 0)), Vector3(0.3, 0.03, 0.03), "l140_trim", GeoKit.ALL, false)
	# the little one: a small potted flower, tired, by the back door
	var lp := Vector3(-13.0, 0, 5.6)
	lp.y = ter.h(lp.x, lp.z)
	k.cylinder(lp + Vector3(0, 0.12, 0), 0.14, 0.24, "l140_roof", 10, true, true)
	little_one = Node3D.new()
	little_one.name = "LittleOne"
	little_one.position = lp + Vector3(0, 0.24, 0)
	lvl.add_child(little_one)
	var stem := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.008
	cm.bottom_radius = 0.012
	cm.height = 0.32
	stem.mesh = cm
	stem.material_override = MatLib.standard(Color(0.18, 0.36, 0.1), 0.8)
	stem.position = Vector3(0, 0.16, 0)
	little_one.add_child(stem)
	var head := MeshInstance3D.new()
	head.name = "Head"
	head.mesh = load("res://levels/L140/L140_flora.gd").hydrangea(Color(0.95, 0.55, 0.65), 0.05, 14, 77)
	head.material_override = MatLib.standard(Color(1, 1, 1), 0.8)
	(head.material_override as StandardMaterial3D).vertex_color_use_as_albedo = true
	head.position = Vector3(0.1, 0.26, 0)
	head.rotation = Vector3(0, 0, -1.1)
	little_one.add_child(head)


func _hives() -> void:
	var c: Vector3 = ter.HIVES
	c.y = ter.h(c.x, c.z)
	k.box(c + Vector3(0, 0.25, 0), Vector3(6.0, 0.12, 0.8), "l140_boards")
	for sx in [-2.8, 2.8]:
		for sz in [-0.3, 0.3]:
			k.box(c + Vector3(sx, 0.12, sz), Vector3(0.1, 0.25, 0.1), "l140_boards", GeoKit.ALL, false)
	k.box(c + Vector3(0, 0.6, 0), Vector3(6.0, 1.2, 0.8), "l140_boards", 0, true)
	var mats := ["l140_hive_a", "l140_hive_b", "l140_hive_c", "l140_hive_a"]
	for i in 4:
		var p := c + Vector3(-2.2 + i * 1.45, 0.31, 0)
		var n := 2 + (i % 2)
		for b in n:
			k.box(p + Vector3(0, 0.15 + b * 0.3, 0), Vector3(0.52, 0.28, 0.44), mats[(i + b) % 4], GeoKit.ALL, false)
		k.box(p + Vector3(0, 0.05 + n * 0.3, 0), Vector3(0.6, 0.07, 0.52), "l140_roof", GeoKit.ALL, false)
		k.box(p + Vector3(0, 0.05, 0.23), Vector3(0.3, 0.025, 0.01), "unlit_black", GeoKit.ALL, false)
		hive_spots.append(p + Vector3(0, 0.1, 0.3))
