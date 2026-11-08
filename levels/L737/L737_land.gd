extends RefCounted
## Level 737 surface: the end of "the endless passage" (start), the ruins of New
## Ephyra (Site 737-1, compressed to the foot of the pyramid), ruined blocks of
## stone/marble/pyrite/gold that do not take the heat (stepping points), the
## dissolved Provisional Database 737-λ, a Fireteam "Midas" post, and the
## Frontrooms landmarks scattered in the haze (SOURCE table: Eiffel Tower,
## Statue of Liberty, Elizabeth Tower at 07:37, Great Sphinx, Pyramids of Giza,
## Golden Gate Bridge over nothingness, Versailles fragments, Burj Khalifa tip).

const T := preload("res://levels/L737/L737_terrain.gd")
const START := Vector3(0, 0, 28)
const MIDAS := Vector3(-24, 0, 12)
const PDB := Vector3(24, 0, 10)

var L: LevelBase
var props: Node3D
var ter
var k: GeoKit
var stones: Array = []        # stepping-stone tops (Vector3)
var lamps: Array = []
var phone := Vector3.ZERO
var suit_crate := Vector3.ZERO
var midas_top := Vector3.ZERO
var bigben := Vector3.ZERO
var mats := ["l737_stone", "l737_marble", "l737_stone", "l737_pyrite", "l737_marble", "l737_gold"]


func _init(level: LevelBase, props_root: Node3D, terrain) -> void:
	L = level
	props = props_root
	ter = terrain


func gy(x: float, z: float) -> float:
	return ter.h(x, z)


func build() -> void:
	k = L.kit("Surface")
	_passage()
	_avenue()
	_ruins()
	_stepping_stones()
	_midas()
	_pdb()
	_versailles()
	_landmarks()
	k.commit()


## SOURCE: "escort them to Level 50 and proceed through the endless passage" -
## the passage arrives here: a long stone corridor in an outcrop that never ends
## in sight (it bends away into the dark).
func _passage() -> void:
	var z0 := 32.0
	k.box_mm(Vector3(-9, -3, z0), Vector3(-1.6, 9, 80), "l737_stone")
	k.box_mm(Vector3(1.6, -3, z0), Vector3(9, 9, 72), "l737_stone")
	k.box_mm(Vector3(-1.6, 4.2, z0), Vector3(1.6, 9, 80), "l737_stone")
	k.box_mm(Vector3(-1.6, -0.6, z0 - 0.5), Vector3(1.6, 0.0, 80), "l737_dark")
	k.box_mm(Vector3(-9, -3, 76.5), Vector3(9, 9, 80), "l737_stone")
	k.box_mm(Vector3(1.6, -3, 72), Vector3(14, 9, 76.5), "l737_dark")
	for z in range(36, 72, 6):
		k.box(Vector3(-1.55, 2.1, z), Vector3(0.1, 4.2, 0.4), "l737_relief", GeoKit.ALL, false)
		k.box(Vector3(1.55, 2.1, z), Vector3(0.1, 4.2, 0.4), "l737_relief", GeoKit.ALL, false)
	# the doorway is framed like a gate, worn to a slant by the wind
	k.box(Vector3(0, 4.6, z0 - 0.4), Vector3(4.6, 0.8, 1.0), "l737_marble", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		k.box(Vector3(s * 2.0, 2.1, z0 - 0.4), Vector3(0.8, 4.2, 1.0), "l737_marble", GeoKit.ALL, true)
	# heat-resistant cloth left by those who were driven through
	k.box_xf(Transform3D(Basis(Vector3.UP, 0.5), Vector3(0.6, 0.05, 30.6)), Vector3(1.4, 0.05, 0.9), "l737_flower", GeoKit.ALL, false)
	k.box_mm(Vector3(-2.6, -0.4, 24.0), Vector3(2.6, 0.12, 32.0), "l737_stone")


func _column(c: Vector3, h: float, r := 0.8, mat := "l737_marble") -> void:
	k.cylinder(c + Vector3(0, h * 0.5, 0), r, h, mat, 12, true)
	k.box(c + Vector3(0, 0.2, 0), Vector3(r * 2.6, 0.4, r * 2.6), mat, GeoKit.ALL, false)
	if h > 5.0:
		k.box(c + Vector3(0, h + 0.25, 0), Vector3(r * 2.6, 0.5, r * 2.6), mat, GeoKit.ALL, false)


func _avenue() -> void:
	# a processional way from the passage to the portico: paved, colonnaded, ruined
	k.box_mm(Vector3(-6, -0.4, -36), Vector3(6, 0.08, 24), "l737_stone")
	var z := 20.0
	var i := 0
	while z > -32.0:
		for s in [-1.0, 1.0]:
			var hh: float = [7.5, 2.2, 5.0, 1.0, 7.5, 3.4][(i + int(s + 1.0)) % 6]
			_column(Vector3(s * 8.0, 0, z), hh)
		z -= 6.5
		i += 1
	for f in [[Vector3(-11.5, 0.8, -2.0), 0.3], [Vector3(10.6, 0.8, -15.0), -0.5], [Vector3(-12.2, 0.8, 12.0), 1.1]]:
		k.box_xf(Transform3D(Basis(Vector3.UP, f[1]) * Basis(Vector3.BACK, PI * 0.5), f[0]), Vector3(1.6, 6.5, 1.6), "l737_marble", GeoKit.ALL, true)
	# the plaza before the pyramid
	k.box_mm(Vector3(-70, -0.5, -170), Vector3(70, 0.0, -36), "l737_stone", GeoKit.PY | GeoKit.SIDES)


func _ruins() -> void:
	var rooms := [[Vector3(-26, 0, -6), 9.0, 7.0], [Vector3(26, 0, -10), 10.0, 8.0], [Vector3(-42, 0, 8), 8.0, 9.0],
		[Vector3(42, 0, 2), 9.0, 7.0], [Vector3(-36, 0, -24), 12.0, 7.0], [Vector3(34, 0, -27), 8.0, 6.0], [Vector3(-18, 0, 22), 7.0, 6.0]]
	for r in rooms:
		var c: Vector3 = r[0]
		var w: float = r[1]
		var d: float = r[2]
		c.y = gy(c.x, c.z) - 0.6
		var seg := 0
		for side in [[Vector3(-w, 0, -d), Vector3(w, 0, -d)], [Vector3(w, 0, -d), Vector3(w, 0, d)], [Vector3(w, 0, d), Vector3(-w, 0, d)], [Vector3(-w, 0, d), Vector3(-w, 0, -d)]]:
			var a: Vector3 = c + side[0] * 0.5
			var b: Vector3 = c + side[1] * 0.5
			var n := int((b - a).length() / 1.5)
			for j in n:
				seg += 1
				if (seg * 7 + int(c.x)) % 5 == 0:
					continue
				var p := a.lerp(b, (j + 0.5) / n)
				var hgt := 0.8 + absf(sin(seg * 1.7 + c.x)) * 4.2
				var dir := (b - a).normalized()
				k.box_xf(Transform3D(Basis(Vector3.UP, atan2(dir.x, dir.z)), p + Vector3(0, hgt * 0.5, 0)), Vector3(0.8, hgt, 1.55), mats[seg % 3], GeoKit.ALL, true)
		# remnants of furnishings: a stone bench, a table slab, a broken urn
		k.box(c + Vector3(-1.0, 0.95, 0.5), Vector3(2.4, 0.3, 0.8), "l737_stone", GeoKit.ALL, true)
		k.box(c + Vector3(1.2, 0.85, -0.8), Vector3(1.4, 0.5, 1.0), "l737_marble", GeoKit.ALL, true)
		Props.place(L, props, "kenney/mini-dungeon/pot", c + Vector3(2.4, 0.6, 1.4), L.rng.randf_range(0, 360), 0.7)
		Props.place(L, props, "kenney/mini-dungeon/rocks", c + Vector3(-2.2, 0.6, -1.6), L.rng.randf_range(0, 360), 0.6)
	# statues on plinths, one toppled, one headless and vast
	for st in [[Vector3(-14, 0, 6), 0.0, false], [Vector3(14, 0, -8), 180.0, false], [Vector3(-16, 0, -22), 40.0, true], [Vector3(18, 0, 16), -30.0, false]]:
		_statue(st[0], st[1], st[2])
	# a colossal seated figure's legs and lap at the east edge of the city
	k.box(Vector3(52, 3.0, -14), Vector3(6, 6, 5), "l737_stone", GeoKit.ALL, true)
	k.box(Vector3(52, 7.5, -16.5), Vector3(6, 9, 2.5), "l737_stone", GeoKit.ALL, true)
	for s in [-1.0, 1.0]:
		k.box(Vector3(52 + s * 1.6, 1.6, -10.5), Vector3(1.8, 3.2, 2.2), "l737_stone", GeoKit.ALL, true)


func _statue(c: Vector3, yaw: float, fallen: bool) -> void:
	k.box(c + Vector3(0, 0.7, 0), Vector3(2.2, 1.4, 2.2), "l737_marble", GeoKit.ALL, true)
	var root := Node3D.new()
	root.position = c + Vector3(0, 1.4, 0)
	root.rotation = Vector3(PI * 0.5 if fallen else 0.0, deg_to_rad(yaw), 0.0)
	if fallen:
		root.position = c + Vector3(0, 0.5, 2.6)
	props.add_child(root)
	var m := MatLib.standard(Color(0.82, 0.78, 0.7), 0.55)
	var parts := [[Vector3(0, 1.6, 0), Vector3(0.9, 1.6, 0.55)], [Vector3(-0.25, 0.5, 0), Vector3(0.35, 1.3, 0.35)], [Vector3(0.25, 0.5, 0), Vector3(0.35, 1.3, 0.35)],
		[Vector3(0, 2.7, 0), Vector3(0.42, 0.5, 0.45)], [Vector3(-0.6, 2.0, 0.2), Vector3(0.24, 1.2, 0.24)]]
	for p in parts:
		var mi := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = (p[1] as Vector3).x * 0.5
		cm.height = maxf((p[1] as Vector3).y, cm.radius * 2.0)
		mi.mesh = cm
		mi.material_override = m
		mi.position = p[0]
		root.add_child(mi)


func _stepping_stones() -> void:
	# SOURCE: navigate by the blocks; they do not take the heat. Denser near routes.
	var rng := L.rng
	var anchors := [START, MIDAS, PDB, Vector3(-30, 0, -20), Vector3(40, 0, -20), Vector3(-60, 0, 30), Vector3(60, 0, 30), Vector3(-80, 0, -40), Vector3(80, 0, -50)]
	for i in 70:
		var a: Vector3 = anchors[i % anchors.size()]
		var b: Vector3 = anchors[(i * 3 + 1) % anchors.size()]
		var p := a.lerp(b, rng.randf()) + Vector3(rng.randf_range(-7, 7), 0, rng.randf_range(-7, 7))
		if absf(p.x) < 7.0 and p.z < 24.0 and p.z > -36.0:
			continue
		if Vector2(p.x, p.z - 50.0).length() < 12.0:
			continue
		var sx := rng.randf_range(1.4, 3.4)
		var sz := rng.randf_range(1.4, 3.4)
		var hh := rng.randf_range(0.5, 1.6)
		var y := gy(p.x, p.z)
		var m: String = mats[rng.randi() % mats.size()]
		k.box_xf(Transform3D(Basis(Vector3.UP, rng.randf_range(0, PI)) * Basis(Vector3.RIGHT, rng.randf_range(-0.08, 0.08)), Vector3(p.x, y + hh * 0.5 - 0.5, p.z)), Vector3(sx, hh, sz), m, GeoKit.ALL, true)
		stones.append(Vector3(p.x, y + hh - 0.5, p.z))


## Sentinels of Navy Fireteam "Midas": they locate and apprehend intruders and
## extract them to Level 169 (memory erasure there).
func _midas() -> void:
	var c := MIDAS
	c.y = gy(c.x, c.z)
	k.box_mm(Vector3(c.x - 3.5, c.y - 1.0, c.z - 3.5), Vector3(c.x + 3.5, c.y + 0.8, c.z + 3.5), "l737_stone")
	k.stairs(Vector3(c.x + 3.5 + 3 * 0.32, c.y, c.z), Vector3(-1, 0, 0), 2.4, 0.8, 3, "l737_stone", 0.32)
	midas_top = c + Vector3(0, 0.8, 0)
	var navy := MatLib.standard(Color(0.06, 0.1, 0.22), 0.45, 0.4)
	var gold := MatLib.standard(Color(0.9, 0.7, 0.28), 0.3, 0.9)
	var visor := MatLib.standard(Color(0.95, 0.75, 0.3), 0.1, 0.9, Color(1.0, 0.7, 0.3), 0.6)
	for g in [[Vector3(-1.2, 0, -0.6), 60.0], [Vector3(1.0, 0, 0.4), 100.0], [Vector3(-0.4, 0, 1.4), 120.0]]:
		var root := Node3D.new()
		root.position = midas_top + g[0]
		root.rotation.y = deg_to_rad(g[1])
		props.add_child(root)
		for p in [["c", Vector3(-0.12, 0.47, 0), Vector3(0.17, 0.94, 0), navy], ["c", Vector3(0.12, 0.47, 0), Vector3(0.17, 0.94, 0), navy],
				["c", Vector3(0, 1.25, 0), Vector3(0.5, 0.8, 0), navy], ["s", Vector3(0, 1.78, 0), Vector3(0.3, 0.32, 0.3), navy],
				["s", Vector3(0, 1.79, 0.1), Vector3(0.22, 0.1, 0.12), visor], ["b", Vector3(0, 1.32, 0), Vector3(0.52, 0.06, 0.34), gold],
				["c", Vector3(-0.3, 1.15, 0.1), Vector3(0.12, 0.7, 0), navy], ["c", Vector3(0.3, 1.15, 0.1), Vector3(0.12, 0.7, 0), navy],
				["b", Vector3(0.06, 1.1, 0.35), Vector3(0.07, 0.1, 0.75), MatLib.standard(Color(0.08, 0.08, 0.09), 0.4, 0.7)]]:
			var mi := MeshInstance3D.new()
			if p[0] == "c":
				var cm := CapsuleMesh.new()
				cm.radius = (p[2] as Vector3).x * 0.5
				cm.height = (p[2] as Vector3).y
				mi.mesh = cm
			elif p[0] == "s":
				var sm := SphereMesh.new()
				sm.radius = 0.5
				sm.height = 1.0
				mi.mesh = sm
				mi.scale = p[2]
			else:
				var bm := BoxMesh.new()
				bm.size = p[2]
				mi.mesh = bm
			mi.material_override = p[3]
			mi.position = p[1]
			root.add_child(mi)
	Props.place(L, props, "ph/vintage_radio_transceiver", midas_top + Vector3(2.2, 0, -2.2), 30.0)
	Props.place(L, props, "ph/old_military_crate", midas_top + Vector3(-2.4, 0, 2.0), 80.0, 0.0, true)


## The dissolved Provisional Database 737-λ: a collapsed prefab, crates, a field
## desk with a Midas-linked emergency phone, and a spare UltraSuit.
func _pdb() -> void:
	var c := PDB
	c.y = gy(c.x, c.z)
	k.box_mm(Vector3(c.x - 6, c.y - 0.6, c.z - 4), Vector3(c.x + 6, c.y + 0.25, c.z + 4), "l737_concrete")
	var top := c.y + 0.25
	k.box(Vector3(c.x - 5.8, top + 1.3, c.z), Vector3(0.12, 2.6, 7.6), "l737_steel", GeoKit.ALL, true)
	k.box(Vector3(c.x, top + 1.3, c.z - 3.8), Vector3(11.6, 2.6, 0.12), "l737_steel", GeoKit.ALL, true)
	k.box_xf(Transform3D(Basis(Vector3.BACK, 0.35), Vector3(c.x - 1.0, top + 1.6, c.z - 1.0)), Vector3(9.0, 0.08, 6.0), "l737_steel", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.RIGHT, -1.2), Vector3(c.x + 5.6, top + 0.5, c.z + 1.5)), Vector3(0.12, 2.6, 3.6), "l737_steel", GeoKit.ALL, false)
	Props.place(L, props, "ph/metal_office_desk", Vector3(c.x - 3.0, top, c.z - 2.4), 0.0, 0.0, true)
	Props.place(L, props, "ph/vintage_radio_transceiver", Vector3(c.x - 3.6, top + 0.79, c.z - 2.5), 10.0)
	Props.place(L, props, "ph/clipboard", Vector3(c.x - 2.4, top + 0.79, c.z - 2.3), 40.0)
	phone = Vector3(c.x - 2.8, top + 0.85, c.z - 2.2)
	k.box(phone + Vector3(0, -0.02, 0), Vector3(0.22, 0.1, 0.3), "l737_steel", GeoKit.ALL, false)
	k.box(phone + Vector3(0, 0.05, -0.05), Vector3(0.06, 0.04, 0.24), "l737_dark", GeoKit.ALL, false)
	k.box(phone + Vector3(0.07, 0.05, 0.06), Vector3(0.05, 0.02, 0.05), "l737_warn", GeoKit.ALL, false)
	for cr in [[Vector3(2.2, 0, -2.6), 10.0], [Vector3(3.6, 0, -2.0), 70.0], [Vector3(1.0, 0, 2.4), 25.0]]:
		Props.place(L, props, "ph/old_military_crate", Vector3(c.x, top, c.z) + cr[0], cr[1], 0.0, true)
	suit_crate = Vector3(c.x + 3.0, top + 0.7, c.z + 2.4)
	k.box(suit_crate + Vector3(0, -0.35, 0), Vector3(1.0, 0.7, 0.7), "l737_steel", GeoKit.ALL, true)
	k.box(suit_crate + Vector3(0, 0.01, 0), Vector3(1.02, 0.05, 0.72), "l737_warn", GeoKit.ALL, false)
	Props.place(L, props, "ph/portable_generator", Vector3(c.x - 4.6, top, c.z + 2.6), 90.0)
	Props.place(L, props, "ph/security_light", Vector3(c.x - 5.6, top + 2.6, c.z - 3.6), 45.0)
	var lb := Label3D.new()
	lb.text = "PROVISIONAL DATABASE 737-λ\nDISSOLVED · OPERATIONS MOVED TO SCARF-λ"
	lb.font_size = 40
	lb.pixel_size = 0.004
	lb.modulate = Color(0.95, 0.8, 0.4)
	lb.position = Vector3(c.x, top + 2.0, c.z - 3.72)
	props.add_child(lb)


func _versailles() -> void:
	# SOURCE: "Remnants of its architecture with gold accents ... fragmented walls"
	var c := Vector3(78, 0, -6)
	c.y = gy(c.x, c.z) - 0.5
	k.arch_wall(c, c + Vector3(0, 0, 22), 9.0, 0.9, "l737_marble", [{"at": 4.0, "w": 2.6, "spring": 4.5}, {"at": 11.0, "w": 2.6, "spring": 4.5}, {"at": 18.0, "w": 2.6, "spring": 4.5}])
	for z in [1.0, 7.5, 14.5, 21.0]:
		k.box(c + Vector3(-0.5, 4.5, z), Vector3(0.2, 9.0, 0.5), "l737_gold", GeoKit.ALL, false)
	k.box(c + Vector3(-0.55, 8.6, 11.0), Vector3(0.12, 0.4, 22.0), "l737_gold", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.BACK, 0.25), c + Vector3(4, 2.0, 28)), Vector3(0.9, 6.0, 8.0), "l737_marble", GeoKit.ALL, true)


func _landmarks() -> void:
	_big_ben(Vector3(-92, 0, 40))
	_liberty(Vector3(88, 0, 36))
	_burj(Vector3(46, 0, 150))
	_sphinx(Vector3(-118, 0, -64))
	_eiffel(Vector3(170, 0, -200))
	for p in [Vector3(420, 0, -300), Vector3(500, 0, -200), Vector3(380, 0, -420)]:
		var s := 140.0 if p.x > 450.0 else 110.0
		_giza(Vector3(p.x, gy(p.x, p.z) - 10.0, p.z), s)
	_golden_gate()


func _big_ben(c: Vector3) -> void:
	c.y = gy(c.x, c.z) - 6.0
	bigben = c
	k.box(c + Vector3(0, 30, 0), Vector3(11, 60, 11), "l737_relief", GeoKit.ALL, true)
	for y in [20.0, 40.0]:
		k.box(c + Vector3(0, y, 0), Vector3(11.6, 1.0, 11.6), "l737_gold", GeoKit.ALL, false)
	k.box(c + Vector3(0, 66, 0), Vector3(12.4, 12, 12.4), "l737_stone", GeoKit.ALL, false)
	for j in 6:
		var w := 11.0 - j * 1.9
		k.box(c + Vector3(0, 73 + j * 3.0, 0), Vector3(w, 3.0, w), "l737_gold", GeoKit.ALL, false)
	k.cylinder(c + Vector3(0, 93, 0), 0.4, 6.0, "l737_gold", 6, false)
	# clock faces frozen at 07:37 (hour hand 228.5 deg, minute hand 222 deg)
	for f in 4:
		var yaw := PI * 0.5 * f
		var bas := Basis(Vector3.UP, yaw)
		var n := bas * Vector3(0, 0, 1)
		var fc := c + Vector3(0, 66, 0) + n * 6.25
		k.box_xf(Transform3D(bas, fc), Vector3(8.0, 8.0, 0.1), "l737_marble", GeoKit.ALL, false)
		k.box_xf(Transform3D(bas, fc + n * 0.04), Vector3(7.0, 7.0, 0.05), "l737_lamp", GeoKit.ALL, false)
		for hand in [[228.5, 2.0, 0.3], [222.0, 3.0, 0.18]]:
			var a := deg_to_rad(hand[0])
			var dir := bas * Vector3(sin(a), cos(a), 0)
			k.box_xf(Transform3D(bas * Basis(Vector3.BACK, -a), fc + n * 0.12 + dir * hand[1] * 0.5), Vector3(hand[2], hand[1], 0.06), "l737_dark", GeoKit.ALL, false)


func _liberty(c: Vector3) -> void:
	# tarnished and partially buried: head, crown and the raised arm with the torch
	c.y = gy(c.x, c.z) - 1.0
	var verd := "l737_verdigris"
	k.box(c + Vector3(0, 2.6, 0), Vector3(4.2, 5.2, 4.6), verd, GeoKit.ALL, true)
	k.box(c + Vector3(0, 1.2, 2.2), Vector3(2.6, 2.2, 0.9), verd, GeoKit.ALL, false)
	for j in 7:
		var a := deg_to_rad(-60.0 + j * 20.0)
		k.box_xf(Transform3D(Basis(Vector3.BACK, a), c + Vector3(sin(a) * 2.8, 5.8 + cos(a) * 1.2, 0.4)), Vector3(0.45, 2.6, 0.3), verd, GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.BACK, -0.15), c + Vector3(5.5, 6.0, -1.0)), Vector3(2.2, 14.0, 2.2), verd, GeoKit.ALL, true)
	k.cylinder(c + Vector3(6.6, 13.6, -1.0), 1.4, 1.6, verd, 12, false)
	k.cylinder(c + Vector3(6.6, 15.0, -1.0), 0.9, 1.4, "l737_gold", 10, false)


func _burj(c: Vector3) -> void:
	c.y = gy(c.x, c.z) - 4.0
	for j in 5:
		var w := 9.0 - j * 1.7
		k.box(c + Vector3(0, j * 9.0 + 4.5, 0), Vector3(w, 9.0, w * 0.8), "l737_glass", GeoKit.ALL, j == 0)
	k.cylinder(c + Vector3(0, 58.0, 0), 0.7, 28.0, "l737_steel", 8, false)


func _sphinx(c: Vector3) -> void:
	c.y = gy(c.x, c.z) - 1.0
	var m := "l737_dust_solid"
	k.box(c + Vector3(0, 4.0, 4.0), Vector3(9.0, 8.0, 22.0), m, GeoKit.ALL, true)
	for s in [-1.0, 1.0]:
		k.box(c + Vector3(s * 2.6, 1.3, -11.0), Vector3(2.8, 2.6, 10.0), m, GeoKit.ALL, true)
	k.box(c + Vector3(0, 10.5, -6.0), Vector3(6.0, 7.0, 6.0), m, GeoKit.ALL, true)
	k.box(c + Vector3(0, 9.0, -6.0), Vector3(8.6, 6.0, 3.0), m, GeoKit.ALL, false)
	k.box(c + Vector3(0, 9.6, -9.2), Vector3(3.2, 3.0, 0.8), "l737_stone", GeoKit.ALL, false)


func _eiffel(c: Vector3) -> void:
	c.y = gy(c.x, c.z)
	var hgt := 150.0
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var base := c + Vector3(sx * 30, 0, sz * 30)
			var top := c + Vector3(sx * 3.5, hgt * 0.6, sz * 3.5)
			var mid := (base + top) * 0.5
			var dir := (top - base).normalized()
			var x := Vector3.UP.cross(dir).normalized()
			if x.length() < 0.1:
				x = Vector3.RIGHT
			k.box_xf(Transform3D(Basis(x, dir, x.cross(dir)), mid), Vector3(4.0, (top - base).length(), 4.0), "l737_gold", GeoKit.ALL, false)
	for pl in [[0.15, 44.0], [0.38, 26.0], [0.6, 12.0]]:
		k.box(c + Vector3(0, hgt * pl[0], 0), Vector3(pl[1], 3.0, pl[1]), "l737_gold", GeoKit.ALL, false)
	k.box(c + Vector3(0, hgt * 0.8, 0), Vector3(5.0, hgt * 0.4, 5.0), "l737_gold", GeoKit.ALL, false)
	k.cylinder(c + Vector3(0, hgt + 6.0, 0), 0.8, 12.0, "l737_gold", 6, false)


func _giza(c: Vector3, s: float) -> void:
	for j in 10:
		var w := s * 2.0 * (1.0 - j / 10.0)
		k.box(c + Vector3(0, j * s * 0.1 + s * 0.05, 0), Vector3(w, s * 0.1, w), "l737_stone", GeoKit.ALL, false)


func _golden_gate() -> void:
	var z := -80.0
	var y := 70.0
	k.box_mm(Vector3(-560, y - 3, z - 7), Vector3(-340, y, z + 7), "l737_bridge", GeoKit.ALL, false)
	for x in [-500.0, -400.0]:
		for s in [-1.0, 1.0]:
			k.box(Vector3(x, y + 40, z + s * 6), Vector3(4, 150, 4), "l737_bridge", GeoKit.ALL, false)
		k.box(Vector3(x, y + 100, z), Vector3(4, 4, 14), "l737_bridge", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		for j in 20:
			var t0 := j / 20.0
			var t1 := (j + 1) / 20.0
			var p0 := Vector3(lerpf(-500, -400, t0), y + 112 - 100 * 4.0 * t0 * (1.0 - t0), z + s * 6)
			var p1 := Vector3(lerpf(-500, -400, t1), y + 112 - 100 * 4.0 * t1 * (1.0 - t1), z + s * 6)
			var d := p1 - p0
			k.box_xf(Transform3D(Basis(Vector3.BACK, atan2(d.y, d.x) - PI * 0.5), (p0 + p1) * 0.5), Vector3(0.8, d.length(), 0.8), "l737_bridge", GeoKit.ALL, false)
