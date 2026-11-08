extends RefCounted
## Level 3.5: the spired skyscraper of the M.E.G. provisional outpost "Antenna to
## Heaven" (page: repurposed natural rooms used as laboratories, utility rooms and
## living quarters for sixteen researchers, five guards and a director; all
## personnel expired; inactive). Footprint 26 x 26 m in chunk (0,0). Four
## reachable storeys (4.2 m) joined by a switchback stair in the north-west core;
## the solid tower rises to 92 m and a lattice spire to 134 m.
##   F0  lobby (arrival door from Level 3, street entrance east), guard room
##   F1  laboratories          F2  living quarters
##   F3  utility room and the director's office (sealed stair above)

const F := Rect2(11.0, 11.0, 26.0, 26.0)
const T := 0.4
const SH := 4.2
const NS := 4
const TOP := 92.0
const CORE := Rect2(11.4, 11.4, 5.6, 5.6)
const DOOR := Vector3(22.0, 0.0, 31.0)          # the door from Level 3 (partition, east face)
const ENTRY := Vector3(37.0, 0.0, 24.0)         # street entrance (east wall)

var lvl
var props := 0
var targets: Array = []
var notes_at: Dictionary = {}


func _init(level) -> void:
	lvl = level


func p(parent: Node3D, id: String, pos: Vector3, yaw: float = 0.0, h: float = 0.0, collide: bool = false) -> Node3D:
	var n: Node3D = Props.place(lvl, parent, id, pos, yaw, h, collide)
	if n:
		props += 1
	return n


func build(node: Node3D, r: RandomNumberGenerator) -> void:
	var k := GeoKit.new(node, "Tower")
	var g := GeoKit.new(node, "TowerGlass")
	g.shadows = false
	var x0 := F.position.x
	var x1 := F.end.x
	var z0 := F.position.y
	var z1 := F.end.y
	# floor slabs (the stair well is open above each flight)
	k.box_mm(Vector3(x0, -0.3, z0), Vector3(x1, 0.0, z1), "l35_floor_concrete")
	for s in range(1, NS):
		var y := s * SH
		for q in [Rect2(x0 + T, CORE.end.y, F.size.x - 2 * T, z1 - T - CORE.end.y), Rect2(CORE.end.x, z0 + T, x1 - T - CORE.end.x, CORE.end.y - z0 - T),
				Rect2(CORE.position.x, CORE.position.y, CORE.size.x, 1.2)]:
			var qr: Rect2 = q
			k.box_mm(Vector3(qr.position.x, y - 0.3, qr.position.y), Vector3(qr.end.x, y, qr.end.y), "l35_floor_concrete")
			k.box_mm(Vector3(qr.position.x, y - 0.31, qr.position.y), Vector3(qr.end.x, y - 0.3, qr.end.y), "l35_plaster", GeoKit.NY, false)
	k.box_mm(Vector3(x0, NS * SH - 0.01, z0), Vector3(x1, NS * SH + 0.3, z1), "l35_plaster", GeoKit.NY, false)
	# exterior walls per storey: window bands on F1-F3, the street entrance on F0
	for s in NS:
		var y := s * SH
		for side in 4:
			var a: Vector3
			var b: Vector3
			match side:
				0:
					a = Vector3(x0, y, z0 + T * 0.5)
					b = Vector3(x1, y, z0 + T * 0.5)
				1:
					a = Vector3(x1 - T * 0.5, y, z0)
					b = Vector3(x1 - T * 0.5, y, z1)
				2:
					a = Vector3(x1, y, z1 - T * 0.5)
					b = Vector3(x0, y, z1 - T * 0.5)
				_:
					a = Vector3(x0 + T * 0.5, y, z1)
					b = Vector3(x0 + T * 0.5, y, z0)
			var ops: Array = []
			var dn := (b - a).normalized()
			if s == 0:
				if side == 1:
					ops.append({"at": ENTRY.z - z0, "w": 4.0, "h": 3.0})
				for n in 3:
					var at := 5.0 + n * 8.0
					var wp := a + dn * at
					if side == 1 or (side == 0 and wp.x < CORE.end.x + 1.0) or (side == 3 and wp.z < CORE.end.y + 1.0):
						continue
					ops.append({"at": at, "w": 2.0, "h": 1.4, "sill": 1.4})
			else:
				for n in 7:
					var at2 := 3.0 + n * 3.35
					var wp2 := a + dn * at2
					if (side == 0 and wp2.x < CORE.end.x + 1.2) or (side == 3 and wp2.z < CORE.end.y + 1.2):
						continue
					ops.append({"at": at2, "w": 2.3, "h": 2.1, "sill": 0.95})
			k.wall(a, b, SH, T, "concrete", ops)
			var inward := Vector3(-dn.z, 0, dn.x)
			k.wall(a + inward * (T * 0.5 + 0.011), b + inward * (T * 0.5 + 0.011), SH - 0.3, 0.02, "l35_plaster", ops)
			for op in ops:
				if float(op.get("sill", 0.0)) <= 0.0:
					continue
				var c: Vector3 = a + dn * float(op["at"]) + Vector3(0, float(op["sill"]) + float(op["h"]) * 0.5, 0)
				var nrm := Vector3(-dn.z, 0, dn.x)
				g.box_xf(Transform3D(Basis(dn, Vector3.UP, dn.cross(Vector3.UP)), c), Vector3(float(op["w"]), float(op["h"]), 0.03), "l35_window_pane", GeoKit.ALL, true)
				k.box_xf(Transform3D(Basis(dn, Vector3.UP, dn.cross(Vector3.UP)), c - Vector3(0, float(op["h"]) * 0.5 + 0.03, 0) - nrm * 0.12), Vector3(float(op["w"]) + 0.1, 0.06, 0.3), "concrete_dark", GeoKit.ALL, false)
	# the solid tower above, vertical fins, a crown and the lattice spire
	k.box_mm(Vector3(x0, NS * SH, z0), Vector3(x1, TOP, z1), "concrete")
	var y := NS * SH + 1.0
	while y < TOP - 3.0:
		for side in 4:
			var pos: Vector3
			var sz: Vector3
			match side:
				0:
					pos = Vector3(F.get_center().x, y + 0.9, z0 - 0.02)
					sz = Vector3(F.size.x - 1.6, 1.6, 0.04)
				1:
					pos = Vector3(x1 + 0.02, y + 0.9, F.get_center().y)
					sz = Vector3(0.04, 1.6, F.size.y - 1.6)
				2:
					pos = Vector3(F.get_center().x, y + 0.9, z1 + 0.02)
					sz = Vector3(F.size.x - 1.6, 1.6, 0.04)
				_:
					pos = Vector3(x0 - 0.02, y + 0.9, F.get_center().y)
					sz = Vector3(0.04, 1.6, F.size.y - 1.6)
			g.box(pos, sz, "l35_glass", GeoKit.ALL, false)
		y += 3.6
	for t in range(1, 9):
		var fx := x0 + t * F.size.x / 9.0
		for zz in [z0 - 0.35, z1 + 0.35]:
			k.box(Vector3(fx, (SH + TOP) * 0.5, zz), Vector3(0.4, TOP - SH, 0.7), "concrete", GeoKit.ALL, false)
		var fz := z0 + t * F.size.y / 9.0
		for xx in [x0 - 0.35, x1 + 0.35]:
			k.box(Vector3(xx, (SH + TOP) * 0.5, fz), Vector3(0.7, TOP - SH, 0.4), "concrete", GeoKit.ALL, false)
	var cr := F.grow(1.5)
	k.box_mm(Vector3(cr.position.x, TOP - 8.0, cr.position.y), Vector3(cr.end.x, TOP, cr.end.y), "concrete_dark", GeoKit.ALL, false)
	_spire(k, Vector3(F.get_center().x, TOP, F.get_center().y))
	# entrance canopy over the street door
	k.box(Vector3(x1 + 2.0, 3.6, ENTRY.z), Vector3(4.0, 0.35, 7.0), "concrete_dark", GeoKit.ALL, false)
	_core(k)
	_frame(k)
	_storey0(k, node, r)
	_storey1(k, node, r)
	_storey2(k, node, r)
	_storey3(k, node, r)
	k.commit()
	g.commit()


func _spire(k: GeoKit, base: Vector3) -> void:
	var h := 42.0
	for dx: float in [-1.0, 1.0]:
		for dz: float in [-1.0, 1.0]:
			_strut(k, base + Vector3(dx * 4.0, 0, dz * 4.0), base + Vector3(dx * 0.4, h, dz * 0.4), 0.35)
	var y := 4.0
	while y < h - 3.0:
		var w := lerpf(4.0, 0.4, y / h)
		k.box(base + Vector3(0, y, 0), Vector3(w * 2.0, 0.25, 0.25), "l35_steel", GeoKit.ALL, false)
		k.box(base + Vector3(0, y, 0), Vector3(0.25, 0.25, w * 2.0), "l35_steel", GeoKit.ALL, false)
		y += 4.0
	k.box(base + Vector3(0, h + 4.0, 0), Vector3(0.3, 8.0, 0.3), "l35_steel", GeoKit.ALL, false)
	for ring: float in [10.0, 20.0, 30.0]:
		k.box(base + Vector3(0, ring, 0), Vector3(2.6, 0.5, 2.6), "l35_insulator", GeoKit.ALL, false)
	targets.append(base + Vector3(0, h + 8.0, 0))


static func _strut(k: GeoKit, a: Vector3, b: Vector3, th: float) -> void:
	var d := b - a
	var z := d.normalized()
	var x := Vector3.UP.cross(z)
	if x.length() < 0.1:
		x = Vector3.RIGHT
	x = x.normalized()
	var y := z.cross(x).normalized()
	k.box_xf(Transform3D(Basis(x, y, z), (a + b) * 0.5), Vector3(th, th, d.length()), "l35_steel", GeoKit.ALL, false)


## Switchback stair in the north-west core: two flights per storey around a
## solid shaft, a mid landing on the south side, a landing strip on the north.
func _core(k: GeoKit) -> void:
	for s in NS:
		var y := s * SH
		# east wall with the core door onto the landing strip, south wall solid
		k.wall(Vector3(CORE.end.x + 0.1, y, CORE.position.y), Vector3(CORE.end.x + 0.1, y, CORE.end.y + 0.2), SH, 0.2, "l35_plaster", [{"at": 0.7, "w": 1.1, "h": 2.2}])
		k.box_mm(Vector3(CORE.position.x, y, CORE.end.y), Vector3(CORE.end.x, y + SH, CORE.end.y + 0.2), "l35_plaster")
		# the solid shaft between the flights
		k.box_mm(Vector3(13.0, y, 12.6), Vector3(15.4, y + SH, 15.6), "l35_plaster")
		if s < NS - 1:
			k.stairs(Vector3(12.3, y, 12.6), Vector3(0, 0, 1), 1.4, SH * 0.5, 12, "l35_stair_concrete", 0.25)
			k.box_mm(Vector3(CORE.position.x, y + SH * 0.5 - 0.2, 15.6), Vector3(CORE.end.x, y + SH * 0.5, CORE.end.y), "l35_stair_concrete")
			k.stairs(Vector3(16.15, y + SH * 0.5, 15.6), Vector3(0, 0, -1), 1.5, SH * 0.5, 12, "l35_stair_concrete", 0.25)
			k.box(Vector3(12.3, y + 1.0 + SH * 0.25, 14.1), Vector3(0.04, 0.04, 3.2), "l35_steel", GeoKit.ALL, false)
	# the way up from F3 is sealed with concrete
	var yt := (NS - 1) * SH
	k.box_mm(Vector3(11.6, yt, 12.6), Vector3(13.0, yt + SH, 13.0), "l35_seal")
	lvl.add_interactable(Vector3(12.3, yt + 1.2, 13.2), Vector3(1.4, 2.0, 0.6), "Try the stairs up", func():
		Overlay.toast("The stairwell above is poured solid with concrete. Whoever sealed it did not want the roof.", 3.5))
	for s in NS:
		lvl.lights.add_anchor(Vector3(14.2, s * SH + 3.6, 12.0), Color(0.9, 0.93, 1.0), 0.6, 5.0, 0.3, "tower")


## Structural columns and ceiling beams on every storey (brutalist frame).
func _frame(k: GeoKit) -> void:
	for s in NS:
		var y := s * SH
		for cx: float in [17.9, 26.0, 32.0]:
			for cz: float in [17.9, 24.2, 30.5]:
				if cx < 18.0 and cz < 18.0:
					continue
				k.box(Vector3(cx, y + (SH - 0.3) * 0.5, cz), Vector3(0.7, SH - 0.3, 0.7), "concrete_dark")
		for c: float in [17.9, 24.2, 30.5]:
			k.box(Vector3(F.get_center().x + 3.0, y + SH - 0.6, c), Vector3(F.size.x - 6.8, 0.6, 0.45), "concrete_dark", GeoKit.ALL, false)
		for c2: float in [26.0, 32.0]:
			k.box(Vector3(c2, y + SH - 0.6, F.get_center().y + 3.0), Vector3(0.45, 0.6, F.size.y - 6.8), "concrete_dark", GeoKit.ALL, false)


func _ceiling_lights(k: GeoKit, y: float, pts: Array, energy: float) -> void:
	for pt in pts:
		var c: Vector3 = pt
		k.box(Vector3(c.x, y + SH - 0.33, c.z), Vector3(1.3, 0.05, 0.35), "l35_fixture", GeoKit.ALL, false)
		k.panel(Vector3(c.x, y + SH - 0.36, c.z), 1.2, 0.25, "l35_tube", float(int(c.x * 3.0) % 7))
		lvl.lights.add_anchor(Vector3(c.x, y + SH - 0.8, c.z), Color(0.92, 0.94, 1.0), energy, 8.0, 0.0, "tower")


func _storey0(k: GeoKit, node: Node3D, r: RandomNumberGenerator) -> void:
	# partition between the lobby and the guard room, door at z 20.5
	k.wall(Vector3(22.0, 0, CORE.end.y + 0.2), Vector3(22.0, 0, F.end.y - T), SH, 0.2, "l35_plaster", [{"at": 3.3, "w": 1.1, "h": 2.2}])
	# the door you came through from Level 3: a steel door that stays shut
	k.box(DOOR + Vector3(0.12, 1.05, 0), Vector3(0.05, 2.1, 1.0), "l35_door")
	k.box(DOOR + Vector3(0.12, 2.15, 0), Vector3(0.08, 0.08, 1.16), "l35_steel", GeoKit.ALL, false)
	for dz: float in [-0.54, 0.54]:
		k.box(DOOR + Vector3(0.12, 1.08, dz), Vector3(0.08, 2.16, 0.08), "l35_steel", GeoKit.ALL, false)
	k.box(DOOR + Vector3(0.17, 1.0, 0.36), Vector3(0.04, 0.04, 0.14), "l35_steel", GeoKit.ALL, false)
	# reception and security post
	k.box_mm(Vector3(27.0, 0, 15.0), Vector3(29.0, 1.05, 19.5), "l35_counter")
	k.box_mm(Vector3(26.9, 1.05, 14.9), Vector3(29.1, 1.1, 19.6), "concrete_dark", GeoKit.ALL, false)
	p(node, "ph/classic_laptop", Vector3(28.0, 1.1, 17.2), 90.0, 0.3)
	p(node, "ph/vintage_radio_transceiver", Vector3(28.1, 1.1, 18.6), 70.0)
	p(node, "ph/clipboard", Vector3(28.2, 1.1, 16.0), 100.0)
	notes_at["register"] = Vector3(28.2, 1.12, 16.0)
	p(node, "kenney/furniture-kit/chairdesk", Vector3(26.2, 0, 16.4), -90.0 + r.randf_range(-40, 40), 1.0)
	p(node, "ph/security_camera_01", Vector3(36.3, 3.6, 12.0), -135.0)
	p(node, "ph/korean_fire_extinguisher_01", Vector3(36.3, 0, 30.0), -90.0)
	p(node, "ph/old_military_crate", Vector3(33.0, 0, 34.8), 0.0, 0.0, true)
	p(node, "ph/old_military_crate", Vector3(33.1, 0.3, 34.8), 8.0)
	p(node, "ph/propane_tank", Vector3(35.5, 0, 35.5), 0.0)
	p(node, "ph/hand_truck", Vector3(30.0, 0, 35.6), 180.0)
	p(node, "ph/cardboard_box_01", Vector3(24.0, 0, 35.8), 10.0, 0.0, true)
	p(node, "ph/plastic_crate_01", Vector3(24.6, 0, 35.9), 30.0)
	# sandbagged inner line by the street door (low concrete barriers)
	p(node, "ph/concrete_road_barrier", Vector3(34.6, 0, 20.4), 90.0, 0.0, true)
	p(node, "ph/concrete_road_barrier", Vector3(34.6, 0, 27.6), 90.0, 0.0, true)
	for n in 3:
		p(node, "ph/wooden_crate_01", Vector3(31.0 + n * 0.9, 0, 12.2), 0.0, 0.0, true)
	p(node, "ph/wooden_crate_01", Vector3(31.9, 0.35, 12.2), 5.0)
	p(node, "ph/steel_frame_shelves_02", Vector3(36.3, 0, 33.0), -90.0, 2.1, true)
	p(node, "ph/plastic_crate_01", Vector3(36.3, 0.74, 33.0), 0.0)
	p(node, "ph/medical_box", Vector3(36.3, 1.44, 33.0), 90.0)
	p(node, "ph/portable_generator", Vector3(25.5, 0, 12.3), 0.0, 0.0, true)
	p(node, "ph/modular_electric_cables", Vector3(23.5, 0.0, 11.7), 0.0)
	p(node, "ph/plastic_monobloc_chair_01", Vector3(25.4, 0, 21.0), r.randf() * 360.0)
	p(node, "ph/plastic_monobloc_chair_01", Vector3(26.2, 0, 21.6), r.randf() * 360.0)
	p(node, "ph/trashbag", Vector3(22.6, 0, 36.0), 0.0)
	k.box(Vector3(22.12, 1.6, 26.0), Vector3(0.03, 1.1, 1.8), "l35_board", GeoKit.ALL, false)
	# guard room (west of the partition): lockers, cots, monitors
	for z: float in [19.0, 19.9, 20.8]:
		k.box(Vector3(11.75, 0.95, z), Vector3(0.6, 1.9, 0.86), "l35_locker", GeoKit.ALL, true)
	for n in 5:
		p(node, "ph/old_bed_frame", Vector3(13.0 + n * 1.7, 0, 34.8), 0.0, 0.0, true)
	p(node, "ph/metal_office_desk", Vector3(19.5, 0, 25.0), -90.0, 0.0, true)
	p(node, "ph/Television_01", Vector3(19.3, 0.79, 24.5), -90.0)
	p(node, "ph/Television_01", Vector3(19.3, 0.79, 25.5), -90.0)
	p(node, "ph/GreenChair_01", Vector3(18.3, 0, 25.0), 90.0)
	p(node, "ph/steel_frame_shelves_02", Vector3(11.75, 0, 27.0), 90.0, 2.1, true)
	_ceiling_lights(k, 0.0, [Vector3(29, 0, 15), Vector3(29, 0, 23), Vector3(29, 0, 31), Vector3(17, 0, 22), Vector3(17, 0, 31)], 0.9)


func _storey1(k: GeoKit, node: Node3D, r: RandomNumberGenerator) -> void:
	var y := SH
	# three rows of lab benches with instruments
	for z: float in [20.5, 26.0, 31.5]:
		k.box_mm(Vector3(20.0, y, z - 0.45), Vector3(33.0, y + 0.88, z + 0.45), "l35_counter")
		k.box_mm(Vector3(19.95, y + 0.88, z - 0.5), Vector3(33.05, y + 0.92, z + 0.5), "concrete_dark", GeoKit.ALL, false)
		for n in 5:
			var x := 21.0 + n * 2.6 + r.randf_range(-0.3, 0.3)
			match (n + int(z)) % 5:
				0: p(node, "ph/vintage_radio_transceiver", Vector3(x, y + 0.92, z), r.randf_range(-20, 20))
				1: p(node, "ph/classic_laptop", Vector3(x, y + 0.92, z), r.randf_range(-30, 30), 0.3)
				2: p(node, "ph/power_box_01", Vector3(x, y + 0.92, z), r.randf_range(-15, 15))
				3: p(node, "ph/binder_notebook", Vector3(x, y + 0.92, z), r.randf() * 360.0)
				_: p(node, "ph/medical_box", Vector3(x, y + 0.92, z), r.randf() * 360.0)
			if r.randf() < 0.6:
				p(node, "ph/bar_chair_round_01", Vector3(x + 0.4, y, z + (0.85 if n % 2 == 0 else -0.85)), r.randf() * 360.0)
	notes_at["field"] = Vector3(25.2, y + 0.94, 26.1)
	# a discharge sensor rig by the east windows: a mast with a coil
	var rig := Vector3(35.2, y, 15.0)
	k.box(rig + Vector3(0, 1.3, 0), Vector3(0.08, 2.6, 0.08), "l35_steel", GeoKit.ALL, false)
	k.cylinder(rig + Vector3(0, 1.8, 0), 0.22, 0.6, "l35_insulator", 12, false)
	k.box(rig + Vector3(0, 0.1, 0), Vector3(0.8, 0.2, 0.8), "l35_steel", GeoKit.ALL, true)
	p(node, "ph/modular_electric_cables", rig + Vector3(-1.2, 0.0, 0.0), 90.0)
	for z: float in [14.0, 15.0, 33.0, 34.0]:
		p(node, "ph/steel_frame_shelves_02", Vector3(36.3, y, z), -90.0, 2.1, true)
		p(node, "ph/plastic_crate_01", Vector3(36.3, y + 0.75, z), 0.0)
	# whiteboards on the partition-free north wall
	for x: float in [21.0, 26.0]:
		k.box(Vector3(x, y + 1.6, F.position.y + T + 0.02), Vector3(3.0, 1.2, 0.03), "l35_board", GeoKit.ALL, false)
	_ceiling_lights(k, y, [Vector3(23, 0, 21), Vector3(31, 0, 21), Vector3(23, 0, 31), Vector3(31, 0, 31), Vector3(20, 0, 14)], 1.0)


func _storey2(k: GeoKit, node: Node3D, r: RandomNumberGenerator) -> void:
	var y := SH * 2.0
	for n in 6:
		p(node, "kenney/furniture-kit/bedbunk", Vector3(20.5 + n * 2.6, y, 35.3), 180.0 + r.randf_range(-6, 6), 1.85, true)
	for n in 4:
		p(node, "kenney/furniture-kit/bedbunk", Vector3(35.3, y, 20.0 + n * 2.6), -90.0 + r.randf_range(-6, 6), 1.85, true)
	for z: float in [18.6, 19.5, 20.4, 21.3, 22.2, 23.1]:
		k.box(Vector3(17.6, y + 0.95, z), Vector3(0.6, 1.9, 0.86), "l35_locker", GeoKit.ALL, true)
	p(node, "ph/dining_table", Vector3(25.0, y, 26.0), 0.0, 0.0, true)
	for n in 6:
		var dx := -0.75 + (n % 3) * 0.75
		var dz := -0.85 if n < 3 else 0.85
		p(node, "ph/dining_chair_02", Vector3(25.0 + dx, y, 26.0 + dz), (0.0 if dz < 0 else 180.0) + r.randf_range(-40, 40))
	p(node, "kenney/furniture-kit/kitchenfridge", Vector3(20.0, y, 12.0), 0.0, 1.8, true)
	p(node, "kenney/furniture-kit/kitchencabinet", Vector3(21.0, y, 12.0), 0.0, 0.9, true)
	p(node, "kenney/furniture-kit/kitchencabinet", Vector3(22.0, y, 12.0), 0.0, 0.9, true)
	p(node, "kenney/furniture-kit/kitchencoffeemachine", Vector3(21.0, y + 0.9, 12.0), 0.0, 0.35)
	p(node, "ph/Sofa_01", Vector3(30.0, y, 14.0), 0.0, 0.0, true)
	p(node, "ph/coffee_table_round_01", Vector3(30.0, y, 15.6), 0.0, 0.4, true)
	p(node, "ph/vintage_suitcase", Vector3(27.0, y, 34.2), 20.0)
	p(node, "ph/trashbag", Vector3(18.6, y, 35.6), 0.0)
	_ceiling_lights(k, y, [Vector3(22, 0, 31), Vector3(31, 0, 31), Vector3(25, 0, 22), Vector3(31, 0, 16)], 0.8)


func _storey3(k: GeoKit, node: Node3D, r: RandomNumberGenerator) -> void:
	var y := SH * 3.0
	# utility: generators, power and switch boxes, cable runs, barrels
	for n in 3:
		p(node, "ph/portable_generator", Vector3(20.5 + n * 1.6, y, 34.8), 180.0, 0.0, true)
	for x: float in [19.0, 24.5]:
		p(node, "ph/utility_box_01", Vector3(x, y, 36.2), 180.0, 0.0, true)
	for x: float in [20.0, 22.0, 24.0]:
		p(node, "ph/power_box_01", Vector3(x, y + 1.1, 11.65), 0.0)
	p(node, "ph/modular_industrial_pipes_01", Vector3(11.9, y, 30.0), 90.0)
	p(node, "ph/modular_electric_cables", Vector3(11.8, y + 2.0, 24.0), 90.0)
	for n in 3:
		p(node, "ph/Barrel_01", Vector3(13.0 + n * 0.7, y, 36.0), r.randf() * 360.0, 0.0, true)
	p(node, "ph/metal_tool_chest", Vector3(16.0, y, 33.0), 90.0, 0.0, true)
	p(node, "ph/steel_frame_shelves_02", Vector3(11.75, y, 27.5), 90.0, 2.1, true)
	notes_at["log"] = Vector3(21.2, y + 0.6, 34.4)
	# the director's office: glass partition in the south-east corner
	k.box_mm(Vector3(28.0, y, 27.8), Vector3(36.6, y + SH, 28.0), "l35_plaster")
	k.wall(Vector3(28.0, y, 28.0), Vector3(28.0, y, 36.6), SH, 0.12, "l35_plaster", [{"at": 1.6, "w": 1.0, "h": 2.2}, {"at": 5.4, "w": 4.6, "h": 1.6, "sill": 0.9}])
	k.box(Vector3(28.0, y + 1.7, 33.4), Vector3(0.02, 1.6, 4.6), "l35_window_pane", GeoKit.ALL, true)
	p(node, "ph/metal_office_desk", Vector3(33.0, y, 32.0), -90.0, 0.0, true)
	p(node, "ph/GreenChair_01", Vector3(34.0, y, 32.0), -90.0 + r.randf_range(-30, 30))
	p(node, "ph/drawer_cabinet", Vector3(36.2, y, 29.2), -90.0, 1.5, true)
	p(node, "ph/vintage_telephone_wall_clock", Vector3(36.5, y + 2.0, 34.0), -90.0)
	p(node, "ph/wall_clock", Vector3(28.12, y + 2.6, 30.0), 90.0)
	notes_at["memo"] = Vector3(32.8, y + 0.81, 31.7)
	p(node, "ph/wooden_bookshelf_worn", Vector3(32.0, y, 36.25), 180.0, 0.0, true)
	p(node, "ph/drawer_cabinet", Vector3(36.2, y, 30.4), -90.0, 1.5, true)
	p(node, "ph/vintage_radio_transceiver", Vector3(33.3, y + 0.79, 32.6), -110.0)
	p(node, "ph/office_notepads", Vector3(32.7, y + 0.79, 31.3), 10.0)
	p(node, "ph/ArmChair_01", Vector3(29.4, y, 35.6), 140.0)
	p(node, "ph/coffee_table_round_01", Vector3(30.4, y, 34.6), 0.0, 0.45)
	p(node, "ph/vintage_suitcase", Vector3(35.6, y, 35.8), 80.0)
	k.box(Vector3(30.6, y + 1.7, 28.02), Vector3(2.6, 1.6, 0.03), "l35_board", GeoKit.ALL, false)
	_ceiling_lights(k, y, [Vector3(22, 0, 30), Vector3(22, 0, 20), Vector3(32, 0, 20), Vector3(32, 0, 32)], 0.8)
