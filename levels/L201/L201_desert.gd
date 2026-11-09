extends RefCounted
## Level 201: the Cool Desert and the sea's edge. A half-buried purple-marble temple with
## statues, busts and murals, floating neon rings around its columns and dial-up terminals
## sitting on the courtyard floor; potted plants; floating geometric shapes; the oasis below
## sea level ringed by palms; abandoned M.E.G. Research Base Zeta beside the temple; the palm
## line of the Sunset Coast; and under the Web Sea, the Digital Trench of floating windows.

const Land := preload("res://levels/L201/L201_land.gd")
const FX := preload("res://levels/L201/L201_fx.gd")
const SAFE := ["L001", "L003", "L004", "L005", "L007", "L025", "L031", "L087"]
const BROKEN := ["L000", "L002", "L006", "L008", "L017", "L058"]
const SAFE_EDGE := {"L001": "L201>L001#3", "L003": "L201>L003#4", "L004": "L201>L004#5", "L005": "L201>L005#6",
	"L007": "L201>L007#7", "L025": "L201>L025#8", "L031": "L201>L031#9", "L087": "L201>L087#10"}

var L: LevelBase
var land
var k: GeoKit
var d: GeoKit
var root: Node3D
var rng: RandomNumberGenerator
var rings: Array = []          # [node, base_y, phase]
var shapes: Array = []         # [node, axis, speed, base_y]
var windows: Array = []        # {node, sid, safe, pos, edge}
var ghosts: Array = []
var schools: Array = []        # [MultiMeshInstance3D centre]
var terminal_pos := Vector3.ZERO
var clock_pos := Vector3.ZERO
var clock_node: Node3D
var notes: Array = []
var lamp_pts: Array = []       # [pos, color, energy, range]


func _init(level: LevelBase, land_ref, r: RandomNumberGenerator) -> void:
	L = level
	land = land_ref
	rng = r
	k = GeoKit.new(level, "Desert")
	d = GeoKit.new(level, "DesertDress")
	root = Node3D.new()
	root.name = "DesertProps"
	level.add_child(root)


func gy(x: float, z: float) -> float:
	return land.h(x, z)


func build() -> void:
	_temple()
	_base_zeta()
	_oasis()
	_coast()
	_shapes()
	_trench()
	k.commit()
	d.commit()


# ------------------------------------------------------------------ the temple

func _temple() -> void:
	var c: Vector3 = Land.TEMPLE
	var top := c.y + 0.6
	var hw := 9.0
	var hl := 12.0
	# stylobate and steps up from the north (sea side)
	k.box(Vector3(c.x, (c.y - 1.5 + top) * 0.5, c.z), Vector3(hw * 2.0, top - c.y + 1.5, hl * 2.0), "l201_marble")
	for i in 3:
		k.box(Vector3(c.x, c.y + 0.1 + i * 0.2, c.z - hl - 1.05 + i * 0.35), Vector3(8.0, 0.2 + i * 0.4, 0.7), "l201_marble")
	# peristyle: some columns stand to the roofline, many are broken, a few have fallen
	var col_pts: Array = []
	var z := -hl + 0.8
	while z <= hl - 0.7:
		col_pts.append(Vector2(-hw + 0.8, z))
		col_pts.append(Vector2(hw - 0.8, z))
		z += 3.1
	for x: float in [-4.4, -1.5, 1.5, 4.4]:
		col_pts.append(Vector2(x, -hl + 0.8))
		col_pts.append(Vector2(x, hl - 0.8))
	var ring_count := 0
	for i in col_pts.size():
		var p: Vector2 = col_pts[i]
		var b := Vector3(c.x + p.x, top, c.z + p.y)
		var roll := rng.randf()
		var hgt := 6.5 if roll < 0.55 else rng.randf_range(1.2, 4.2)
		if roll > 0.9:
			# fallen drum lying on the platform
			k.box_xf(Transform3D(Basis(Vector3.UP, rng.randf() * TAU), b + Vector3(1.2, 0.45, 0.4)), Vector3(0.9, 0.9, 3.2), "l201_marble")
			hgt = 0.6
		k.cylinder(b + Vector3(0, hgt * 0.5, 0), 0.45, hgt, "l201_marble", 14)
		d.box(b + Vector3(0, 0.12, 0), Vector3(1.15, 0.24, 1.15), "l201_marble", GeoKit.ALL, false)
		if hgt > 6.0:
			d.box(b + Vector3(0, hgt + 0.15, 0), Vector3(1.2, 0.3, 1.2), "l201_marble", GeoKit.ALL, false)
		if hgt > 3.0 and ring_count < 9 and rng.randf() < 0.6:
			var rn := FX.neon_ring(root, b + Vector3(0, rng.randf_range(2.0, minf(hgt, 5.0)), 0), 0.9, "l201_pink" if ring_count % 2 == 0 else "l201_cyan")
			rings.append([rn, rn.position.y, rng.randf() * TAU])
			ring_count += 1
			if ring_count % 3 == 1:
				lamp_pts.append([rn.position, Color(1.0, 0.35, 0.7) if ring_count % 2 == 1 else Color(0.3, 0.9, 1.0), 1.0, 7.0])
	# entablature over the intact south-west run
	k.box(Vector3(c.x - hw + 0.8, top + 6.95, c.z + 4.0), Vector3(1.3, 0.6, 13.0), "l201_marble", GeoKit.ALL, false)
	k.box(Vector3(c.x, top + 6.95, c.z + hl - 0.8), Vector3(hw * 2.0 - 0.4, 0.6, 1.3), "l201_marble", GeoKit.ALL, false)
	# cella: inner room, partly collapsed, door to the north courtyard
	var cz0 := c.z - 1.0
	var cz1 := c.z + 9.0
	k.wall(Vector3(c.x - 4.0, top, cz0), Vector3(c.x + 4.0, top, cz0), 4.8, 0.5, "l201_marble", [{"at": 4.0, "w": 2.2, "h": 3.2}])
	k.wall(Vector3(c.x - 4.0, top, cz0), Vector3(c.x - 4.0, top, cz1), 4.8, 0.5, "l201_marble")
	k.wall(Vector3(c.x + 4.0, top, cz0), Vector3(c.x + 4.0, top, cz0 + 5.0), 3.2, 0.5, "l201_marble")
	k.wall(Vector3(c.x + 4.0, top, cz0 + 7.5), Vector3(c.x + 4.0, top, cz1), 1.4, 0.5, "l201_marble")
	k.wall(Vector3(c.x - 4.0, top, cz1), Vector3(c.x + 4.0, top, cz1), 4.8, 0.5, "l201_marble")
	for q in 5:
		k.box_xf(Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(c.x + 5.4 + rng.randf_range(-0.6, 1.2), top + 0.25, cz0 + 5.0 + q * 0.6)), Vector3(rng.randf_range(0.4, 1.0), 0.5, 0.6), "l201_marble")
	# murals: sunset panels on the cella's inner walls
	var mural := FX.mat(FX.SHAPE)
	mural.set_shader_parameter("a", Vector3(1.0, 0.45, 0.3))
	mural.set_shader_parameter("b", Vector3(0.5, 0.2, 0.9))
	for side: float in [-1.0, 1.0]:
		if side > 0.0:
			continue
		var mi := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(6.0, 2.4)
		mi.mesh = qm
		mi.material_override = mural
		mi.position = Vector3(c.x + side * 3.74, top + 2.6, (cz0 + cz1) * 0.5)
		mi.rotation.y = PI * 0.5
		root.add_child(mi)
	# statue of a figure and three busts on plinths
	_statue(Vector3(c.x, top, cz1 - 1.6))
	for bp in [Vector3(c.x - 6.5, top, c.z - 7.0), Vector3(c.x + 6.6, top, c.z - 3.0), Vector3(c.x - 6.4, top, c.z + 6.0)]:
		_bust(bp)
	# courtyard terminals: old desktops sitting on the floor, some without keyboards
	var tp: Array = [Vector3(c.x - 2.2, top, c.z - 6.0), Vector3(c.x + 0.4, top, c.z - 7.2), Vector3(c.x + 3.0, top, c.z - 5.6)]
	for i in tp.size():
		var p: Vector3 = tp[i]
		_terminal(p, i != 1)
	terminal_pos = tp[1] + Vector3(0, 0.35, 0)
	# potted plants (none native to a desert)
	for pp in [Vector3(c.x - 3.0, top, cz0 - 0.6), Vector3(c.x + 3.0, top, cz0 - 0.6), Vector3(c.x - 7.5, top, c.z - 10.5), Vector3(c.x + 7.5, top, c.z - 10.5), Vector3(c.x + 7.4, top, c.z + 9.0)]:
		Props.place(L, root, "kenney/furniture-kit/pottedplant", pp, rng.randf() * 360.0, rng.randf_range(1.0, 1.5))
	# half buried: sand drifts heaped against the east side
	var sand_mat: Material = (L.get("land_mat") as Material)
	for q in 4:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 1.0
		sm.height = 2.0
		sm.radial_segments = 16
		sm.rings = 8
		mi.mesh = sm
		mi.scale = Vector3(rng.randf_range(4.0, 6.0), rng.randf_range(1.6, 2.6), rng.randf_range(5.0, 8.0))
		mi.position = Vector3(c.x + hw + rng.randf_range(-1.5, 0.5), c.y - 0.2, c.z - 9.0 + q * 6.0)
		mi.material_override = sand_mat
		root.add_child(mi)
	notes.append(["l201_temple", "Plaque on the temple steps", "Smooth purple marble, half-buried: columns, walls, statues, busts and murals in an old Greco-Roman style. Neon rings float around the columns. In the courtyard, old desktop computers sit on the floor; most still work.", Vector3(c.x + 2.0, c.y + 0.6, c.z - hl - 1.2)])


func _statue(p: Vector3) -> void:
	k.box(p + Vector3(0, 0.6, 0), Vector3(1.4, 1.2, 1.4), "l201_marble")
	var parts := [[Vector3(0, 2.2, 0), Vector3(0.75, 1.9, 0.45)], [Vector3(0, 3.45, 0), Vector3(0.42, 0.5, 0.45)], [Vector3(-0.55, 2.35, 0), Vector3(0.2, 1.3, 0.22)],
		[Vector3(0.55, 2.7, 0.1), Vector3(0.2, 1.3, 0.22)]]
	for q in parts:
		d.box(p + (q[0] as Vector3), q[1], "l201_marble", GeoKit.ALL, false)


func _bust(p: Vector3) -> void:
	k.box(p + Vector3(0, 0.55, 0), Vector3(0.6, 1.1, 0.6), "l201_marble")
	d.box(p + Vector3(0, 1.3, 0), Vector3(0.7, 0.4, 0.4), "l201_marble", GeoKit.ALL, false)
	d.cylinder(p + Vector3(0, 1.62, 0), 0.12, 0.25, "l201_marble", 8, false)
	d.box(p + Vector3(0, 1.92, 0), Vector3(0.34, 0.42, 0.38), "l201_marble", GeoKit.ALL, false)


func _terminal(p: Vector3, keyboard: bool) -> void:
	k.box(p + Vector3(0, 0.17, 0), Vector3(0.6, 0.34, 0.5), "l201_canvas")
	d.box(p + Vector3(0, 0.6, -0.05), Vector3(0.52, 0.46, 0.5), "l201_canvas", GeoKit.ALL, false)
	d.quad(p + Vector3(0, 0.62, -0.305), Vector3(0, 0, -1), Vector3(0.19, 0, 0), Vector3(0, 0.15, 0), "l201_crt", Vector2.ZERO, true)
	if keyboard:
		d.box(p + Vector3(0, 0.02, -0.55), Vector3(0.5, 0.04, 0.18), "l201_canvas", GeoKit.ALL, false)
	lamp_pts.append([p + Vector3(0, 0.6, -0.6), Color(0.3, 1.0, 0.6), 0.35, 3.0])


# ------------------------------------------------------------------ Base Zeta

func _base_zeta() -> void:
	var c := Vector3(Land.TEMPLE.x + 26.0, 0.0, Land.TEMPLE.z + 14.0)
	c.y = gy(c.x, c.z)
	for t in 2:
		var tc := c + Vector3(-3.5 + t * 7.0, 0, -4.0)
		tc.y = gy(tc.x, tc.z)
		for s: float in [-1.0, 1.0]:
			k.box_xf(Transform3D(Basis(Vector3(0, 0, 1), s * 0.75), tc + Vector3(s * 0.95, 1.05, 0)), Vector3(0.08, 2.8, 4.2), "l201_canvas")
		d.box(tc + Vector3(0, 2.05, 0), Vector3(0.12, 0.12, 4.4), "l201_metal", GeoKit.ALL, false)
	var tbl := c + Vector3(0, gy(c.x, c.z + 2.0) - c.y, 2.0)
	Props.place(L, root, "ph/metal_office_desk", tbl, 0.0, 0.0, true)
	Props.place(L, root, "ph/vintage_radio_transceiver", tbl + Vector3(-0.5, 0.79, 0), 180.0)
	Props.place(L, root, "ph/clipboard", tbl + Vector3(0.4, 0.79, 0.1), 20.0)
	clock_node = Props.place(L, root, "ph/wall_clock", tbl + Vector3(0.75, 0.79, -0.2), 160.0)
	clock_pos = tbl + Vector3(0.75, 0.95, -0.2)
	Props.place(L, root, "ph/portable_generator", c + Vector3(3.6, gy(c.x + 3.6, c.z + 3.2) - c.y, 3.2), 30.0, 0.0, true)
	Props.place(L, root, "ph/plastic_monobloc_chair_01", tbl + Vector3(0.2, 0, 0.9), 190.0)
	for i in 6:
		var cp := c + Vector3(rng.randf_range(-6.0, 6.0), 0, rng.randf_range(3.5, 7.0))
		cp.y = gy(cp.x, cp.z)
		Props.place(L, root, ["ph/old_military_crate", "ph/wooden_crate_01", "ph/cardboard_box_01"][i % 3], cp, rng.randf() * 360.0, 0.0, i % 3 == 0)
	for i in 5:
		Props.place(L, root, "ph/plastic_bottle_gallon", tbl + Vector3(-0.8 + i * 0.12, 0.79, 0.3), rng.randf() * 360.0)
	FX.neon_text(root, "M.E.G. BASE ZETA", c + Vector3(0, 3.2, -6.4), Vector3(0, 0, 1), 0.5, Color(0.9, 0.9, 0.7))
	d.box(c + Vector3(0, 2.6, -6.5), Vector3(4.4, 0.8, 0.1), "l201_metal", GeoKit.ALL, true)
	for sx: float in [-2.0, 2.0]:
		d.box(c + Vector3(sx, 1.1, -6.5), Vector3(0.1, 2.2, 0.1), "l201_metal", GeoKit.ALL, true)
	notes.append(["l201_zeta", "M.E.G. Research Team Base Zeta - final log", "Team of at least 25. All names for this level's places and entities are ours. Losses: 6 through links to the Null, 2 to Binary Fish schools, 3 to the Tune-Out. Supplies left for anyone in need: Almond Water, Firesalt, some Level Keys. Keep moving. Keep noise near you.", tbl + Vector3(0.4, 0.9, 0.1)])
	notes.append(["l201_links", "Typed list taped to the radio", "TRENCH HYPERLINKS (confirmed). SAFE: Levels 1, 3, 4, 5, 7, 25, 31, 87. BROKEN - lead to the Null (white void, whispers of 'four zero four'): Levels 0, 2, 6, 8, 17, 58. Do not use unconfirmed links.", tbl + Vector3(-0.5, 0.95, 0)])
	lamp_pts.append([c + Vector3(0, 2.4, 2.0), Color(1.0, 0.85, 0.6), 0.6, 6.0])


# ------------------------------------------------------------------ oasis, coast, shapes

func _oasis() -> void:
	var o: Vector3 = Land.OASIS
	for i in 11:
		var a := TAU * i / 11.0 + rng.randf_range(-0.2, 0.2)
		var r := rng.randf_range(11.0, 14.0)
		var b := Vector3(o.x + cos(a) * r, 0, o.z + sin(a) * r)
		b.y = gy(b.x, b.z) - 0.1
		FX.palm(d, b, rng.randf_range(6.5, 10.0), Vector3(-cos(a), 0, -sin(a)))


func _coast() -> void:
	var x := -66.0
	while x < 66.0:
		var b := Vector3(x + rng.randf_range(-2.0, 2.0), 0, -74.0 + rng.randf_range(-4.0, 3.0))
		b.y = gy(b.x, b.z) - 0.1
		FX.palm(d, b, rng.randf_range(7.0, 11.0), Vector3(rng.randf_range(-0.4, 0.4), 0, -1.0))
		x += rng.randf_range(7.0, 11.0)
	# Static Ghosts on the coast: most stare at the sun, some lie on the sand
	for i in 6:
		var gp := Vector3(rng.randf_range(-40.0, 40.0), 0, rng.randf_range(-84.0, -78.0))
		gp.y = gy(gp.x, gp.z)
		var lie := i >= 4
		ghosts.append(FX.ghost(root, gp, PI + rng.randf_range(-0.3, 0.3) if not lie else rng.randf() * TAU, "lie" if lie else "stand", float(i) * 3.1))
	for i in 2:
		var gp := Vector3(rng.randf_range(-30.0, 50.0), 0, rng.randf_range(-20.0, 60.0))
		gp.y = gy(gp.x, gp.z)
		ghosts.append(FX.ghost(root, gp, rng.randf() * TAU, "stand", 40.0 + i))


func _shapes() -> void:
	var kinds := ["box", "sphere", "torus", "prism", "hex", "box", "torus", "sphere"]
	for i in 16:
		var p := Vector3(rng.randf_range(-60.0, 60.0), rng.randf_range(9.0, 30.0), rng.randf_range(-55.0, 85.0))
		var s := rng.randf_range(2.0, 6.5)
		var mesh: Mesh
		match kinds[i % kinds.size()]:
			"box":
				var bm := BoxMesh.new()
				bm.size = Vector3.ONE * s
				mesh = bm
			"sphere":
				var sm := SphereMesh.new()
				sm.radius = s * 0.5
				sm.height = s
				sm.radial_segments = 10
				sm.rings = 6
				mesh = sm
			"torus":
				var tm := TorusMesh.new()
				tm.inner_radius = s * 0.3
				tm.outer_radius = s * 0.5
				tm.rings = 18
				tm.ring_segments = 8
				mesh = tm
			"prism":
				var pm := PrismMesh.new()
				pm.size = Vector3(s, s, s)
				mesh = pm
			_:
				var cm := CylinderMesh.new()
				cm.top_radius = s * 0.45
				cm.bottom_radius = s * 0.45
				cm.height = s * 0.6
				cm.radial_segments = 6
				mesh = cm
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		var m := FX.mat(FX.SHAPE)
		var pal: Array = [[Vector3(1.0, 0.4, 0.75), Vector3(0.2, 0.9, 1.0)], [Vector3(1.0, 0.8, 0.3), Vector3(1.0, 0.3, 0.6)], [Vector3(0.6, 0.4, 1.0), Vector3(0.3, 1.0, 0.8)]][i % 3]
		m.set_shader_parameter("a", pal[0])
		m.set_shader_parameter("b", pal[1])
		mi.material_override = m
		mi.position = p
		mi.rotation = Vector3(rng.randf() * TAU, rng.randf() * TAU, 0)
		root.add_child(mi)
		shapes.append([mi, Vector3(rng.randf_range(-1, 1), 1, rng.randf_range(-1, 1)).normalized(), rng.randf_range(0.05, 0.25), p.y])


# ------------------------------------------------------------------ the Digital Trench

func _trench() -> void:
	var tr: Rect2 = Land.TRENCH
	var ids: Array = SAFE.duplicate()
	ids.append_array(BROKEN)
	# deterministic shuffle of placement, safe and broken mixed along the trench
	var spots: Array = []
	for i in ids.size():
		var row := i % 2
		var col := i / 2
		spots.append(Vector3(tr.position.x + 9.0 + col * 7.3 + (3.0 if row == 1 else 0.0), 0, tr.position.y + 12.0 + row * 16.0 + rng.randf_range(-2.0, 2.0)))
	for i in ids.size():
		var sid: String = ids[i]
		var p: Vector3 = spots[(i * 5) % ids.size()]
		p.y = gy(p.x, p.z)
		var safe := SAFE.has(sid)
		var node := _window(p + Vector3(0, 1.7, 0), sid, safe, rng.randf_range(-0.5, 0.5))
		windows.append({"node": node, "sid": sid, "safe": safe, "pos": p, "edge": SAFE_EDGE.get(sid, "L201>EXT#12"), "base_y": node.position.y})
	for i in 5:
		var sc := Vector3(rng.randf_range(tr.position.x + 6.0, tr.end.x - 6.0), Land.TRENCH_FLOOR + rng.randf_range(2.5, 6.0), rng.randf_range(tr.position.y + 4.0, tr.end.y - 4.0))
		schools.append([FX.fish_school(root, sc, 26, rng), sc])
	for i in 4:
		var sc := Vector3(rng.randf_range(-50.0, 50.0), rng.randf_range(-2.4, -1.4), rng.randf_range(-112.0, -96.0))
		schools.append([FX.fish_school(root, sc, 18, rng), sc])


## An early-Internet window: grey body, blue title bar, a few lines and an underlined link.
func _window(c: Vector3, sid: String, safe: bool, yaw: float) -> Node3D:
	var n := Node3D.new()
	n.name = "TrenchWindow_" + sid
	root.add_child(n)
	n.position = c
	n.rotation.y = yaw
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.6, 1.8, 0.04)
	body.mesh = bm
	body.material_override = MatLib.standard(Color(0.72, 0.72, 0.74), 0.6, 0.0, Color(0.72, 0.72, 0.76), 0.55)
	n.add_child(body)
	var bar := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(2.6, 0.24, 0.05)
	bar.mesh = tm
	bar.position = Vector3(0, 0.78, 0)
	bar.material_override = MatLib.standard(Color(0.05, 0.1, 0.5), 0.5, 0.0, Color(0.1, 0.2, 0.9), 1.2)
	n.add_child(bar)
	var dname: String = LevelRegistry.display_name(sid)
	var lvl_no := str(int(sid.substr(1)))
	_text(n, ("Level %s" % lvl_no) if (dname == "" or dname == sid) else dname, Vector3(-1.2, 0.78, 0.04), 0.0032, Color(1, 1, 1), HORIZONTAL_ALIGNMENT_LEFT)
	if safe:
		_text(n, "An old page about this level, from the\nearly days. Parts of it may be out of date\nor simply wrong. Read with care.", Vector3(-1.2, 0.3, 0.04), 0.0028, Color(0.08, 0.08, 0.08), HORIZONTAL_ALIGNMENT_LEFT)
		_text(n, "> Go to Level %s" % lvl_no, Vector3(-1.2, -0.45, 0.04), 0.0042, Color(0.05, 0.1, 0.85), HORIZONTAL_ALIGNMENT_LEFT, true)
	else:
		_text(n, "Error 404\nThe page could not be found.", Vector3(-1.2, 0.25, 0.04), 0.0034, Color(0.4, 0.05, 0.05), HORIZONTAL_ALIGNMENT_LEFT)
		_text(n, "> Level %s" % lvl_no, Vector3(-1.2, -0.45, 0.04), 0.0042, Color(0.35, 0.1, 0.6), HORIZONTAL_ALIGNMENT_LEFT, true)
	return n


func _text(n: Node3D, t: String, p: Vector3, px: float, col: Color, al: int, underline := false) -> void:
	var l := Label3D.new()
	l.text = t
	l.font_size = 48
	l.pixel_size = px
	l.modulate = col
	l.outline_size = 0
	l.horizontal_alignment = al
	l.position = p + Vector3(0, 0, 0.0)
	l.offset = Vector2(0, 0)
	l.shaded = false
	if underline:
		l.text = t
		var u := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(1.3, 0.025, 0.01)
		u.mesh = bm
		u.material_override = MatLib.standard(col, 0.5, 0.0, col, 1.0)
		u.position = p + Vector3(0.65, -0.22, 0.0)
		n.add_child(u)
	n.add_child(l)
