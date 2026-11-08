extends RefCounted
## Level 36, Terminal C: the gate hall with gate C31 (where our flight boards),
## the Gate 32 Support Group's camp around C32, a luxury lounge on a mezzanine,
## restrooms and a fountain, clocks that show random times or have no hands.

const Z0 := -112.0
const Z1 := -152.0
const HX := 24.0
const H := 8.0
const LOUNGE_Y := 4.2
const GATE_DOOR := Vector3(0.0, 0.0, -152.0)
const C32_CAMP := Vector3(-15.0, 0.0, -134.0)

var lvl
var core
var k: GeoKit
var d: GeoKit
var door_body: StaticBody3D
var leaves: Array = []          # [Node3D] sliding glass leaves
var gate_label: Label3D
var board: Label3D
var clocks: Array = []


func _init(level, c) -> void:
	lvl = level
	core = c
	k = c.k
	d = c.d


func build(node: Node3D, r: RandomNumberGenerator) -> void:
	k.slab(-HX, Z0, HX, Z1, 0.0, 0.5, "l36_carpet")
	k.slab(-3.0, Z0, 3.0, Z1, 0.004, 0.01, "l36_floor_hall")
	k.slab(-HX, Z0, HX, Z1, H + 0.4, 0.4, "l36_ceiling")
	k.wall(Vector3(-HX, 0, Z0), Vector3(HX, 0, Z0), H, 0.3, "l36_wall", [{"at": HX, "w": 12.0, "h": 5.5}])
	k.wall(Vector3(-HX, 0, Z0), Vector3(-HX, 0, Z1), H, 0.3, "l36_wall", [{"at": 22.0, "w": 2.4, "h": 2.6}, {"at": 7.0, "w": 1.4, "h": 2.3}, {"at": 10.0, "w": 1.4, "h": 2.3}])
	k.wall(Vector3(HX, 0, Z0), Vector3(HX, 0, Z1), H, 0.3, "l36_wall", [{"at": 32.0, "w": 2.4, "h": 2.6}])
	k.wall(Vector3(-HX, 0, Z1), Vector3(HX, 0, Z1), H, 0.3, "l36_wall", [{"at": HX, "w": 3.0, "h": 2.6}])
	_gate(node)
	_closed_gate(node, Vector3(-HX + 0.2, 0, -134.0), PI * 0.5, "C32")
	_closed_gate(node, Vector3(HX - 0.2, 0, -144.0), -PI * 0.5, "C30")
	_camp(node, r)
	_lounge(node, r)
	# seating blocks (centre walkway left clear)
	for row in 4:
		var z := -117.0 - float(row) * 3.2
		core.seats(Transform3D(Basis(), Vector3(4.5, 0, z)), 8)
		if row < 2:
			core.seats(Transform3D(Basis(Vector3.UP, PI), Vector3(-4.5, 0, z - 0.6)), 8)
	for row in 2:
		var z2 := -138.0 - float(row) * 3.2
		core.seats(Transform3D(Basis(), Vector3(3.5, 0, z2)), 6)
		core.seats(Transform3D(Basis(Vector3.UP, PI), Vector3(-3.5, 0, z2 - 0.6)), 6)
	# frosted, evenly glowing glass along the gate wall: the same light at every hour
	for sx in [-1.0, 1.0]:
		var xa: float = sx * 3.4
		var xb: float = sx * 22.6
		var cxw: float = (xa + xb) * 0.5
		d.box(Vector3(cxw, 3.8, Z1 + 0.17), Vector3(absf(xb - xa), 5.6, 0.02), "l36_frosted", GeoKit.ALL, false)
		var xm: float = xa
		while absf(xm) <= absf(xb) + 0.01:
			d.box(Vector3(xm, 3.8, Z1 + 0.22), Vector3(0.14, 5.8, 0.1), "l36_steel", GeoKit.ALL, false)
			xm += sx * 2.4
		for yy in [1.0, 6.6]:
			d.box(Vector3(cxw, yy, Z1 + 0.22), Vector3(absf(xb - xa), 0.14, 0.1), "l36_steel", GeoKit.ALL, false)
		lvl.lights.add_anchor(Vector3(sx * 13.0, 3.5, Z1 + 2.5), Color(0.86, 0.9, 0.96), 1.1, 14.0)
	# more seating facing the glass, and charging columns
	for row in 2:
		for sx in [-1.0, 1.0]:
			var x0: float = 8.6 if sx > 0 else -14.6
			core.seats(Transform3D(Basis(Vector3.UP, PI), Vector3(x0 + 6.0 * 0.62, 0, -143.0 - float(row) * 3.0)), 6)
	for p in [Vector3(-10.0, 0, -122.0), Vector3(10.0, 0, -132.0), Vector3(-6.0, 0, -144.0), Vector3(16.0, 0, -146.0)]:
		k.box(p + Vector3(0, 0.6, 0), Vector3(0.35, 1.2, 0.35), "l36_counter_front")
		d.box(p + Vector3(0, 1.0, 0.18), Vector3(0.25, 0.3, 0.01), "l36_screen", GeoKit.ALL, false)
	# restrooms and a water fountain on the west wall
	for i in 2:
		var zz := Z0 - 7.0 - float(i) * 3.0
		d.box(Vector3(-HX + 0.2, 1.15, zz), Vector3(0.1, 2.3, 1.4), "l36_dark", GeoKit.ALL, false)
		core.label(node, Vector3(-HX + 0.27, 2.75, zz), PI * 0.5, ["WOMEN", "MEN"][i], 36, Color(1, 1, 1))
	k.box(Vector3(-HX + 0.45, 0.45, Z0 - 12.6), Vector3(0.5, 0.9, 0.7), "l36_steel")
	d.box(Vector3(-HX + 0.5, 0.92, Z0 - 12.6), Vector3(0.45, 0.06, 0.55), "l36_counter", GeoKit.ALL, false)
	# lights: long panels, a dim area near the closed gates
	for z in [-118.0, -128.0, -138.0, -148.0]:
		for x in [-14.0, 0.0, 14.0]:
			d.panel(Vector3(x, H - 0.01, z), 6.0, 1.0, "l36_panel" if not (x < 0.0 and z == -138.0) else "l36_panel_flick", x + z, 0.8 if x < 0.0 and z == -138.0 else 0.0)
			lvl.lights.add_anchor(Vector3(x, H - 1.0, z), Color(0.96, 0.96, 1.0), 1.5, 14.0, 0.6 if x < 0.0 and z == -138.0 else 0.0)
	# clocks: random times, one with no hands
	for i in 4:
		var cp := Vector3([-20.0, 9.0, 15.0, 21.0][i], 5.6, Z0 - 0.19)
		for layer in [[0.46, 0.04, "l36_dark", 0.0], [0.42, 0.05, "l36_counter", -0.012]]:
			var fm := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = layer[0]
			cm.bottom_radius = layer[0]
			cm.height = layer[1]
			cm.radial_segments = 24
			fm.mesh = cm
			fm.material_override = MatLib.get_mat(layer[2])
			fm.rotation.x = PI * 0.5
			fm.position = cp + Vector3(0, 0, layer[3])
			node.add_child(fm)
		if i == 2:
			continue
		var hands := Node3D.new()
		hands.position = cp + Vector3(0, 0, -0.05)
		node.add_child(hands)
		for hh in [[0.28, 0.035, r.randf() * TAU], [0.2, 0.05, r.randf() * TAU]]:
			var mi := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(hh[1], hh[0], 0.01)
			mi.mesh = bm
			mi.material_override = MatLib.get_mat("l36_dark")
			var piv := Node3D.new()
			piv.rotation.z = hh[2]
			mi.position.y = hh[0] * 0.5
			piv.add_child(mi)
			hands.add_child(piv)
		clocks.append(hands)
	core.board_sign(node, Vector3(0, 6.4, Z0 - 0.4), 0.0, "TERMINAL C   GATES C30 - C32")
	core.board_sign(node, Vector3(0, 4.6, -125.0), 0.0, "EXIT  <")


## Gate C31: podium, sliding glass doors, the jet bridge rising to a dark aircraft door.
func _gate(node: Node3D) -> void:
	var g := GATE_DOOR
	# jet bridge
	k.slab(-1.6, g.z, 1.6, g.z - 2.0, 0.0, 0.5, "l36_carpet")
	k.ramp(Vector3(0, 0, g.z - 2.0), Vector3(0, 0.9, g.z - 14.0), 3.2, 0.3, "l36_carpet")
	k.slab(-1.6, g.z - 14.0, 1.6, g.z - 18.0, 0.9, 0.5, "l36_carpet")
	for sx in [-1.75, 1.75]:
		k.box(Vector3(sx, 1.8, g.z - 9.0), Vector3(0.3, 3.6, 18.0), "l36_wall_bag")
	k.box(Vector3(0, 3.7, g.z - 9.0), Vector3(3.8, 0.3, 18.0), "l36_wall_bag")
	k.box(Vector3(0, 2.0, g.z - 18.2), Vector3(3.2, 4.0, 0.3), "l36_wall_bag")
	d.box(Vector3(0, 1.95, g.z - 18.0), Vector3(1.0, 1.9, 0.04), "l36_void", GeoKit.ALL, false)
	d.box(Vector3(0, 1.95, g.z - 18.01), Vector3(1.2, 2.06, 0.02), "l36_steel", GeoKit.ALL, false)
	for z in [-4.0, -9.0, -14.0]:
		d.panel(Vector3(0, 3.54, g.z + z), 0.4, 1.4, "l36_panel", z, 0.0)
		lvl.lights.add_anchor(Vector3(0, 3.0, g.z + z), Color(0.95, 0.95, 0.9), 0.7, 5.0)
	# sliding glass leaves and the collider that holds the gate shut
	for sx in [-1.0, 1.0]:
		var leaf := Node3D.new()
		leaf.position = Vector3(sx * 0.75, 1.3, g.z)
		node.add_child(leaf)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.5, 2.6, 0.06)
		mi.mesh = bm
		mi.material_override = MatLib.get_mat("l36_glass")
		leaf.add_child(mi)
		var fr := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3(1.5, 0.08, 0.08)
		fr.mesh = fm
		fr.material_override = MatLib.get_mat("l36_steel")
		fr.position.y = -1.26
		leaf.add_child(fr)
		leaves.append(leaf)
	door_body = StaticBody3D.new()
	door_body.name = "GateDoor"
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(3.0, 2.6, 0.2)
	cs.shape = sh
	cs.position = Vector3(0, 1.3, g.z)
	door_body.add_child(cs)
	node.add_child(door_body)
	# podium and the gate board
	k.box_mm(Vector3(-5.4, 0, g.z + 4.0), Vector3(-2.4, 1.1, g.z + 4.8), "l36_counter_front")
	d.box_mm(Vector3(-5.5, 1.1, g.z + 3.95), Vector3(-2.3, 1.15, g.z + 4.85), "l36_counter")
	d.box(Vector3(0, 4.0, g.z + 0.2), Vector3(4.4, 1.6, 0.1), "l36_dark", GeoKit.ALL, false)
	d.box(Vector3(0, 4.0, g.z + 0.26), Vector3(4.2, 1.4, 0.01), "l36_screen", GeoKit.ALL, false)
	gate_label = core.label(node, Vector3(0, 4.0, g.z + 0.28), 0.0, "C31", 44, Color(1.0, 0.86, 0.3))
	core.label(node, Vector3(0, 5.3, g.z + 0.2), 0.0, "GATE C31", 72, Color(1, 1, 1))
	d.box(Vector3(-3.9, 1.7, g.z + 4.4), Vector3(1.8, 0.9, 0.08), "l36_dark", GeoKit.ALL, false)
	# the hub's main departures board
	d.box(Vector3(-12.0, 5.0, Z0 - 0.25), Vector3(7.0, 3.2, 0.2), "l36_dark", GeoKit.ALL, false)
	d.box(Vector3(-12.0, 5.0, Z0 - 0.36), Vector3(6.8, 3.0, 0.01), "l36_screen", GeoKit.ALL, false)
	board = core.label(node, Vector3(-15.2, 5.0, Z0 - 0.38), PI, "", 30, Color(1.0, 0.86, 0.3))
	board.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	board.position = Vector3(-8.8, 5.0, Z0 - 0.38)


func _closed_gate(node: Node3D, pos: Vector3, yaw: float, name: String) -> void:
	var b := Basis(Vector3.UP, yaw)
	d.box_xf(Transform3D(b, pos + Vector3(0, 1.3, 0)), Vector3(2.4, 2.6, 0.08), "l36_glass", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, pos + Vector3(0, 1.3, 0)), Vector3(2.4, 2.6, 0.2), "l36_glass", 0, true)
	d.box_xf(Transform3D(b, pos + Vector3(0, 1.3, -0.15)), Vector3(2.4, 2.6, 0.05), "l36_void", GeoKit.ALL, false)
	core.label(node, pos + b * Vector3(0, 3.2, 0.12), yaw, "GATE " + name, 64, Color(1, 1, 1))


## The Gate 32 Support Group's camp: blankets, bags as pillows, a schedule board.
## They are out on one of their group outings; their chatter carries.
func _camp(node: Node3D, r: RandomNumberGenerator) -> void:
	var c := C32_CAMP
	var cols := ["l36_bag_b", "l36_bag_c", "l36_bag_d", "l36_bag_e", "l36_fabric"]
	for i in 44:
		var p := c + Vector3(r.randf_range(-7.0, 6.0), 0, r.randf_range(-8.0, 8.0))
		if absf(p.x) < 3.4:
			continue
		var bl := Transform3D(Basis(Vector3.UP, r.randf() * TAU), p + Vector3(0, 0.012, 0))
		d.box_xf(bl, Vector3(r.randf_range(1.4, 2.0), 0.03, r.randf_range(1.0, 1.5)), cols[r.randi() % cols.size()], GeoKit.ALL, false)
		if r.randf() < 0.35:
			d.box_xf(bl * Transform3D(Basis(Vector3(0, 0, 1), 0.2), Vector3(0.3, 0.1, 0.1)), Vector3(0.9, 0.12, 1.0), cols[r.randi() % cols.size()], GeoKit.ALL, false)
		if r.randf() < 0.7:
			core.suitcase(p + Vector3(r.randf_range(-0.6, 0.6), 0.02, r.randf_range(-0.5, 0.5)), r.randf() * TAU, r, r.randf() < 0.3)
		if r.randf() < 0.4:
			Props.place(lvl, node, "kenney/furniture-kit/pillowlong", p + Vector3(0.3, 0.03, 0.0), r.randf() * 360.0, 0.25)
	for j in 2:
		core.seats(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-HX + 1.0, 0, -127.0 - float(j) * 9.0)), 6)
	# the group's own day/night schedule, hand-lettered on an easel
	var e := c + Vector3(3.6, 0, 5.5)
	for sx in [-0.5, 0.5]:
		d.box_xf(Transform3D(Basis(Vector3(1, 0, 0), -0.15), e + Vector3(sx, 0.85, 0)), Vector3(0.05, 1.7, 0.05), "l36_fabric", GeoKit.ALL, false)
	d.box_xf(Transform3D(Basis(Vector3(1, 0, 0), -0.15), e + Vector3(0, 1.25, 0.08)), Vector3(1.1, 0.8, 0.03), "paper", GeoKit.ALL, false)
	core.label(node, e + Vector3(0, 1.32, 0.13), 0.0, "GATE 32 SUPPORT GROUP\nlights out  /  breakfast\noutings: lounges, shops,\nthe Meeting Place", 18, Color(0.15, 0.15, 0.2)).rotation.x = -0.15
	Props.place(lvl, node, "kenney/food-kit/pot-stew", c + Vector3(-4.0, 0.0, 3.0), 0.0, 0.3)
	Props.place(lvl, node, "kenney/food-kit/bag", c + Vector3(-3.4, 0.0, 3.4), 30.0, 0.35)
	Props.place(lvl, node, "ph/vintage_suitcase", c + Vector3(-5.5, 0.0, -4.0), 60.0)
	Props.place(lvl, node, "kenney/furniture-kit/radio", c + Vector3(-2.0, 0.02, -1.5), 20.0, 0.35)


## A luxury lounge on a mezzanine (+4.2 m): sofas, books, a buffet, a fridge.
func _lounge(node: Node3D, r: RandomNumberGenerator) -> void:
	var y := LOUNGE_Y
	k.slab(12.0, Z0 - 0.15, HX - 0.15, -128.0, y, 0.3, "l36_carpet")
	k.stairs(Vector3(22.6, 0, -134.44), Vector3(0, 0, 1), 2.0, y, 23, "l36_floor_hall", 0.28)
	k.box(Vector3(12.0, y + 0.55, -120.0), Vector3(0.1, 1.1, 15.7), "l36_glass")
	k.box(Vector3(16.8, y + 0.55, -128.0), Vector3(9.6, 1.1, 0.1), "l36_glass")
	d.box(Vector3(12.0, y + 1.12, -120.0), Vector3(0.1, 0.06, 15.7), "l36_steel", GeoKit.ALL, false)
	d.box(Vector3(16.8, y + 1.12, -128.0), Vector3(9.6, 0.06, 0.1), "l36_steel", GeoKit.ALL, false)
	for zc in [-115.0, -127.0]:
		k.cylinder(Vector3(12.4, y * 0.5, zc), 0.25, y, "l36_column", 12)
	core.board_sign(node, Vector3(17.0, y + 2.8, -127.9), 0.0, "LOUNGE")
	for i in 3:
		var p := Vector3(16.0 + float(i % 2) * 4.0, y, -116.0 - float(i) * 3.5)
		Props.place(lvl, node, "kenney/furniture-kit/loungesofa", p, 0.0, 0.85)
		Props.place(lvl, node, "ph/coffee_table_round_01", p + Vector3(0, 0, 1.3), 0.0)
		Props.place(lvl, node, "ph/ArmChair_01", p + Vector3(1.6, 0, 1.4), -100.0)
	Props.place(lvl, node, "kenney/furniture-kit/bookcaseopen", Vector3(23.6, y, -114.0), -90.0, 2.0)
	Props.place(lvl, node, "kenney/furniture-kit/kitchenfridgelarge", Vector3(23.5, y, -118.0), -90.0, 1.95)
	Props.place(lvl, node, "ph/Television_01", Vector3(23.4, y + 1.0, -121.0), -90.0)
	k.box(Vector3(23.2, y + 0.45, -124.5), Vector3(1.0, 0.9, 4.0), "l36_counter_front")
	d.box(Vector3(23.2, y + 0.92, -124.5), Vector3(1.1, 0.05, 4.1), "l36_counter", GeoKit.ALL, false)
	for i in 6:
		Props.place(lvl, node, "kenney/food-kit/" + ["plate-dinner", "bowl", "cup-coffee", "plate", "glass", "soda-can"][i], Vector3(23.1, y + 0.95, -126.2 + float(i) * 0.6), 0.0, 0.12)
	d.panel(Vector3(18.0, H - 0.01, -120.0), 1.4, 1.4, "l36_panel", 1.0, 0.0)
	lvl.lights.add_anchor(Vector3(18.0, y + 3.0, -120.0), Color(1.0, 0.9, 0.75), 1.1, 9.0)
