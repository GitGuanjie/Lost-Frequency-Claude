extends RefCounted
## Level 0.3 dressing: the abandoned camp of Task Force 104-CX (assignment:
## defrost and remodel; equipment: two blowtorches) and the traces the crew and
## their reinforcements left through the rooms. Nobody is here (page: Major Took
## arrives on 01-01-2020 and finds no one). Poly Haven CC0 models via Props.place.

const G := preload("res://levels/L000_3/L000_3_geo.gd")

var lvl
var props := 0
var torches: Array = []      # interact points of the two blowtorches
var desk := Vector3.ZERO
var gen_pos := Vector3.ZERO
var doors: Array = []        # doorway centres of the chunk being dressed


func ok(pos: Vector3, clear: float = 1.0) -> bool:
	for d in doors:
		if Vector2(pos.x - d.x, pos.z - d.z).length() < clear:
			return false
	return true


func _init(level) -> void:
	lvl = level


func p(parent: Node3D, id: String, pos: Vector3, yaw: float = 0.0, h: float = 0.0, collide: bool = false) -> Node3D:
	if not ok(pos):
		return null
	var n: Node3D = Props.place(lvl, parent, id, pos, yaw, h, collide)
	if n:
		props += 1
	return n


## A roll lying on its side (carpet, wallpaper) as a rotated cylinder.
static func roll(parent: Node3D, pos: Vector3, yaw: float, r: float, length: float, mat: String, core: String) -> void:
	var pv := Node3D.new()
	pv.position = pos + Vector3(0, r, 0)
	pv.rotation = Vector3(0, deg_to_rad(yaw), PI * 0.5)
	parent.add_child(pv)
	var g := GeoKit.new(pv, "Roll")
	g.cylinder(Vector3.ZERO, r, length, mat, 14, false)
	g.cylinder(Vector3.ZERO, r * 0.3, length + 0.02, core, 8, false)
	g.commit()


static func bucket(k: GeoKit, pos: Vector3) -> void:
	k.cylinder(pos + Vector3(0, 0.18, 0), 0.15, 0.36, "l03_bucket", 12, false)
	k.cylinder(pos + Vector3(0, 0.355, 0), 0.13, 0.012, "l03_paste", 12, false, true)


static func blowtorch(k: GeoKit, pos: Vector3, yaw: float) -> void:
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	k.cylinder(pos + Vector3(0, 0.15, 0), 0.055, 0.3, "l03_torch", 12, false)
	k.box_xf(Transform3D(b, pos + Vector3(0, 0.33, 0)), Vector3(0.05, 0.06, 0.05), "l03_brass", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, pos + Vector3(0, 0.35, 0) + b * Vector3(0, 0, -0.12)), Vector3(0.025, 0.025, 0.22), "l03_brass", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, pos + Vector3(0, 0.36, 0) + b * Vector3(0, 0, -0.25)), Vector3(0.04, 0.04, 0.06), "l03_rust_dark", GeoKit.ALL, false)


## Tripod work light: the crew "improved the lightings" with these.
func work_light(k: GeoKit, parent: Node3D, pos: Vector3, grp: String) -> void:
	k.box(pos + Vector3(0, 1.0, 0), Vector3(0.035, 2.0, 0.035), "l03_metal", GeoKit.ALL, false)
	for a in 3:
		var ang := TAU * a / 3.0
		var d := Vector3(cos(ang), 0, sin(ang))
		k.box_xf(Transform3D(Basis(d.cross(Vector3.UP).normalized(), 0.45), pos + d * 0.22 + Vector3(0, 0.3, 0)), Vector3(0.025, 0.7, 0.025), "l03_metal", GeoKit.ALL, false)
	p(parent, "ph/caged_hanging_light", pos + Vector3(0, 1.72, 0), 0.0, 0.42)
	lvl.lights.add_anchor(pos + Vector3(0, 1.85, 0), Color(1.0, 0.83, 0.62), 1.5, 8.5, 0.0, grp)


## Floor cable from a to b (a flat run of black boxes).
static func cable(k: GeoKit, a: Vector3, b: Vector3) -> void:
	var d := b - a
	d.y = 0
	var L := d.length()
	var bas := Basis(Vector3.UP, atan2(d.x, d.z))
	k.box_xf(Transform3D(bas, (a + b) * 0.5 + Vector3(0, 0.012, 0)), Vector3(0.025, 0.024, L), "l03_cable", GeoKit.ALL, false)


## The camp room of chunk (0,0): x 6..18, z 6..18.
func camp(node: Node3D, grp: String) -> void:
	var k := GeoKit.new(node, "Camp")
	var c := Vector3(12, 0, 12)
	desk = c + Vector3(0, 0, -1.2)
	p(node, "ph/metal_office_desk", desk, 0.0, 0.0, true)
	p(node, "ph/classic_laptop", desk + Vector3(-0.45, 0.79, 0.05), 200.0, 0.3)
	p(node, "ph/vintage_radio_transceiver", desk + Vector3(0.62, 0.79, -0.18), -20.0)
	p(node, "ph/clipboard", desk + Vector3(0.05, 0.79, 0.15), 12.0)
	p(node, "ph/binder_notebook", desk + Vector3(-0.85, 0.79, -0.2), 70.0)
	p(node, "ph/plastic_bottle_gallon", desk + Vector3(0.88, 0.79, 0.25), 0.0)
	p(node, "ph/stationery_supplies", desk + Vector3(0.35, 0.79, -0.28), 0.0)
	p(node, "ph/vintage_flashlight", desk + Vector3(-0.1, 0.79, -0.3), 75.0)
	p(node, "ph/office_notepads", desk + Vector3(-0.3, 0.79, -0.25), 5.0)
	p(node, "ph/plastic_monobloc_chair_01", desk + Vector3(-0.5, 0, 0.85), 175.0)
	p(node, "ph/plastic_monobloc_chair_01", desk + Vector3(0.6, 0, 0.95), 150.0)
	p(node, "ph/plastic_monobloc_chair_01", desk + Vector3(1.5, 0, -0.2), -100.0)
	p(node, "ph/plastic_monobloc_chair_01", c + Vector3(-3.4, 0, 3.6), 60.0)
	# generator, cables and two tripod work lights
	gen_pos = Vector3(16.6, 0, 7.3)
	p(node, "ph/portable_generator", gen_pos, 200.0, 0.0, true)
	p(node, "ph/propane_tank", gen_pos + Vector3(-0.8, 0, -0.1), 0.0)
	p(node, "ph/plastic_bottle_gallon", gen_pos + Vector3(0.45, 0, 0.6), 30.0)
	work_light(k, node, Vector3(8.2, 0, 8.0), grp)
	work_light(k, node, Vector3(15.9, 0, 15.6), grp)
	cable(k, gen_pos, Vector3(8.2, 0, 8.0))
	cable(k, gen_pos + Vector3(0, 0, 0.3), Vector3(16.6, 0, 15.6))
	cable(k, Vector3(16.6, 0, 15.6), Vector3(15.9, 0, 15.6))
	# shelving along the north wall with boxed fittings
	for sx in [8.4, 9.2]:
		p(node, "ph/steel_frame_shelves_02", Vector3(sx, 0, 6.38), 0.0, 2.1, true)
	p(node, "ph/cardboard_box_01", Vector3(8.4, 0.02, 6.4), 10.0)
	p(node, "ph/cardboard_box_01", Vector3(9.2, 0.74, 6.38), -5.0)
	p(node, "ph/plastic_crate_01", Vector3(8.4, 1.44, 6.38), 90.0)
	p(node, "ph/plastic_crate_01", Vector3(9.2, 0.02, 6.38), 90.0)
	p(node, "ph/propane_tank", Vector3(8.35, 0.74, 6.4), 0.0)
	p(node, "ph/medical_box", Vector3(9.2, 1.44, 6.4), 0.0)
	# remodelling stock: carpet and wallpaper rolls, paste buckets
	for i in 3:
		roll(node, Vector3(6.75 + i * 0.0, 0.0, 9.3 + i * 0.62), 0.0, 0.29, 3.6, "l03_roll_wool", "l03_cardboard")
	roll(node, Vector3(7.0, 0.58, 9.6), 0.0, 0.26, 3.6, "l03_roll_wool", "l03_cardboard")
	k.box_mm(Vector3(6.5, 0.0, 14.0), Vector3(7.4, 0.5, 14.7), "l03_cardboard", GeoKit.ALL, true)
	for i in 6:
		k.cylinder(Vector3(6.65 + (i % 3) * 0.28, 0.55, 14.2 + (i / 3) * 0.3), 0.06, 0.55, "l03_roll_paper", 10, false)
	for bp in [Vector3(7.8, 0, 14.9), Vector3(8.15, 0, 15.15), Vector3(7.7, 0, 15.4), Vector3(13.4, 0, 16.9)]:
		bucket(k, bp)
	# a half-laid strip of the new wool carpet, curling at the edge
	k.box_mm(Vector3(9.6, 0.0, 13.8), Vector3(12.8, 0.02, 17.4), "l03_carpet_wool_new", GeoKit.ALL, false)
	roll(node, Vector3(9.6, 0.0, 15.6), 90.0, 0.2, 3.6, "l03_roll_wool", "l03_cardboard")
	# the crate the blowtorches were issued in
	var crate := Vector3(16.4, 0, 11.2)
	p(node, "ph/old_military_crate", crate, 90.0, 0.0, true)
	blowtorch(k, crate + Vector3(-0.08, 0.3, -0.35), 30.0)
	blowtorch(k, crate + Vector3(0.1, 0.3, 0.3), -60.0)
	torches = [crate + Vector3(0, 0.6, 0)]
	p(node, "ph/metal_tool_chest", Vector3(17.3, 0, 13.0), -90.0, 0.0, true)
	p(node, "ph/wooden_ladder", Vector3(17.45, 0, 9.0), -90.0, 2.4, false)
	p(node, "ph/hand_truck", Vector3(14.2, 0, 6.6), 160.0)
	p(node, "ph/trashbag", Vector3(6.6, 0, 17.4), 0.0)
	p(node, "ph/trashbag", Vector3(7.2, 0, 17.5), 40.0)
	p(node, "ph/cardboard_box_01", Vector3(10.8, 0, 6.5), 4.0, 0.0, true)
	p(node, "ph/cardboard_box_01", Vector3(10.85, 0.34, 6.5), -8.0)
	p(node, "ph/wooden_crate_01", Vector3(13.2, 0, 6.5), 0.0, 0.0, true)
	p(node, "ph/plastic_crate_01", Vector3(14.9, 0, 17.2), 20.0)
	p(node, "ph/korean_fire_extinguisher_01", Vector3(17.6, 0, 16.9), -90.0)
	# the wallpaper pasting table: a sheet half pasted, frozen stiff to the board
	var pt := Vector3(9.4, 0, 12.4)
	k.box(pt + Vector3(0, 0.77, 0), Vector3(0.62, 0.03, 2.5), "l03_board", GeoKit.ALL, true)
	for lx in [-0.26, 0.26]:
		for lz in [-1.1, 1.1]:
			k.box(pt + Vector3(lx, 0.38, lz), Vector3(0.03, 0.76, 0.03), "l03_metal", GeoKit.ALL, false)
	k.box(pt + Vector3(0, 0.79, -0.15), Vector3(0.53, 0.004, 2.0), "l03_roll_paper", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.RIGHT, -1.2), pt + Vector3(0, 0.55, 1.35)), Vector3(0.53, 0.004, 0.55), "l03_roll_paper", GeoKit.ALL, false)
	k.box(pt + Vector3(0.12, 0.81, 0.6), Vector3(0.12, 0.04, 0.2), "l03_board", GeoKit.ALL, false)
	bucket(k, pt + Vector3(0.6, 0, -0.9))
	roll(node, pt + Vector3(-0.15, 0.79, -1.0), 90.0, 0.06, 0.53, "l03_roll_paper", "l03_cardboard")
	# second rack on the east wall and a stack of boxed fittings
	for sz in [8.3, 9.1]:
		p(node, "ph/steel_frame_shelves_02", Vector3(17.62, 0, sz), -90.0, 2.1, true)
	p(node, "ph/cardboard_box_01", Vector3(17.6, 0.74, 8.3), 80.0)
	p(node, "ph/plastic_crate_01", Vector3(17.6, 1.44, 9.1), 0.0)
	p(node, "ph/propane_tank", Vector3(17.6, 0.02, 9.1), 0.0)
	for i in 4:
		if ok(Vector3(6.6, 0, 7.0), 1.1):
			k.box_xf(Transform3D(Basis(Vector3.UP, 0.08 * i), Vector3(6.75, 0.2 + i * 0.4, 6.95)), Vector3(0.6, 0.4, 0.5), "l03_cardboard", GeoKit.ALL, i == 0)
	# drop cloth with a frost crust where the mist reached it
	k.box_xf(Transform3D(Basis(Vector3.UP, 0.12), Vector3(13.7, 0.01, 14.4)), Vector3(2.4, 0.012, 1.8), "l03_dropcloth", GeoKit.ALL, false)
	k.commit()


## Traces of the crew and reinforcement task forces in an ordinary chunk.
func traces(node: Node3D, rooms: Array, r: RandomNumberGenerator, grp: String) -> void:
	var plain: Array = []
	for rm in rooms:
		if rm["kind"] in ["plain", "duct"]:
			plain.append(rm["rect"])
	if plain.is_empty() or r.randf() > 0.6:
		return
	var k := GeoKit.new(node, "Traces")
	var wr: Rect2 = plain[r.randi() % plain.size()]
	var c := wr.get_center()
	var base := Vector3(c.x + r.randf_range(-0.3, 0.3) * wr.size.x * 0.5, 0, c.y + r.randf_range(-0.3, 0.3) * wr.size.y * 0.5)
	match r.randi() % 5:
		0:
			p(node, "ph/propane_tank", base, r.randf() * 360.0)
			p(node, "ph/metal_tool_chest", base + Vector3(0.7, 0, 0.2), r.randf() * 360.0, 0.0, true)
		1:
			roll(node, base, r.randf() * 180.0, 0.28, 3.4, "l03_roll_wool", "l03_cardboard")
			bucket(k, base + Vector3(0.9, 0, 0.9))
		2:
			p(node, "ph/cardboard_box_01", base, r.randf() * 360.0, 0.0, true)
			p(node, "ph/plastic_crate_01", base + Vector3(0.6, 0, -0.3), r.randf() * 360.0)
			p(node, "ph/vintage_flashlight", base + Vector3(-0.7, 0, 0.4), r.randf() * 360.0)
		3:
			work_light(k, node, base, grp)
			p(node, "ph/trashbag", base + Vector3(0.8, 0, 0.5), r.randf() * 360.0)
		_:
			p(node, "ph/hand_truck", base, r.randf() * 360.0)
			p(node, "ph/cardboard_box_01", base + Vector3(0.0, 0.1, 0.0), r.randf() * 360.0)
			bucket(k, base + Vector3(-0.6, 0, 0.5))
	k.commit()


## Hall dressing: the crew's last working spot on the gallery.
func hall(node: Node3D, ox: float, oz: float, grp: String) -> void:
	var k := GeoKit.new(node, "HallKit")
	var g := Vector3(ox + 14.0, G.UP, oz + 2.4)
	p(node, "ph/wooden_ladder", g + Vector3(1.2, 0, 0.6), 15.0, 2.6, false)
	p(node, "ph/metal_tool_chest", g + Vector3(-1.5, 0, -1.0), 10.0, 0.0, true)
	p(node, "ph/propane_tank", g + Vector3(-2.2, 0, -1.2), 0.0)
	work_light(k, node, g + Vector3(-0.5, 0, 0.8), grp)
	roll(node, g + Vector3(-5.5, 0, -1.4), 90.0, 0.28, 3.4, "l03_roll_wool", "l03_cardboard")
	bucket(k, g + Vector3(2.6, 0, -1.3))
	p(node, "ph/trashbag", Vector3(ox + 2.0, G.UP, oz + 12.0), 0.0)
	p(node, "ph/cardboard_box_01", Vector3(ox + 1.6, G.UP, oz + 15.0), 30.0, 0.0, true)
	p(node, "ph/plastic_crate_01", Vector3(ox + 22.0, 0, oz + 3.0), 0.0)
	p(node, "ph/hand_truck", Vector3(ox + 3.0, 0, oz + 20.0), 120.0)
	p(node, "ph/korean_fire_extinguisher_01", Vector3(ox + 0.3, 0, oz + 9.0), 90.0)
	k.commit()
