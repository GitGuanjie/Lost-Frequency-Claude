extends RefCounted
## Level 7.7 dressing (static). SOURCE (Ground Floor): worn-out, unhygienic
## furniture, old chairs, mouldy tables, pots of long-withered plants, painting
## frames whose contents are indiscernible, dead light switches, burned-out
## lamps barely hanging from the ceiling. (Upper Floor): the same furniture in
## a worse state, oxidized metal everywhere, enclosed rusted pipes in and out of
## the walls. (Ceiling): decaying white floor, the Lamp Zone's giant bulb behind
## ancient glass, control panels with buttons, signs, levers and an ancient radio
## transmitter, the cables behind them gone. Lifebuoy: ADAPTATION (nautical
## dressing; the page's entrance mentions sailor-styled doors).

const B := preload("res://levels/L007_7/L007_7_build.gd")
const S := B.S
const UF := B.UF
const ROOF := B.ROOF


static func _p(lvl: Node3D, parent: Node3D, id: String, pos: Vector3, yaw: float, h: float = 0.0, collide: bool = false) -> Node3D:
	return Props.place(lvl, parent, id, pos, yaw, h, collide)


static func painting(k: GeoKit, at: Vector3, normal: Vector3, w: float, h: float) -> void:
	var yaw := atan2(normal.x, normal.z)
	var b := Basis(Vector3.UP, yaw)
	k.box_xf(Transform3D(b, at), Vector3(w, h, 0.05), "l77_wood", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, at + normal * 0.028), Vector3(w - 0.12, h - 0.12, 0.004), "l77_canvas", GeoKit.ALL, false)


static func withered_plant(k: GeoKit, r: RandomNumberGenerator, at: Vector3) -> void:
	k.cylinder(at + Vector3(0, 0.16, 0), 0.17, 0.32, "l77_pot", 10, false)
	k.cylinder(at + Vector3(0, 0.31, 0), 0.15, 0.02, "l77_mould", 10, false, true)
	for n in 5:
		var d := Vector3(r.randf_range(-0.5, 0.5), 1.0, r.randf_range(-0.5, 0.5)).normalized()
		var len := r.randf_range(0.25, 0.6)
		var bb := Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3.RIGHT, r.randf_range(0.1, 0.9))
		k.box_xf(Transform3D(bb, at + Vector3(0, 0.32, 0) + bb.y * len * 0.5), Vector3(0.012, len, 0.012), "l77_deadplant", GeoKit.ALL, false)


static func switch_plate(k: GeoKit, at: Vector3, normal: Vector3) -> void:
	k.box_xf(Transform3D(Basis(Vector3.UP, atan2(normal.x, normal.z)), at), Vector3(0.08, 0.12, 0.015), "l77_panelface", GeoKit.ALL, false)


static func hanging_lamp(lvl: Node3D, parent: Node3D, at: Vector3, tilt: float) -> void:
	var h := _p(lvl, parent, "ph/modern_ceiling_lamp_01", at, 30.0)
	if h:
		h.rotation.z = tilt


## Ground floor furniture (interior only).
static func ground_floor(lvl: Node3D, parent: Node3D, k: GeoKit, r: RandomNumberGenerator) -> void:
	var f := S + 0.03
	# W1 parlour x[-9.5,-1.2] z[0,4.5]
	_p(lvl, parent, "ph/Sofa_01", Vector3(-6.0, f, 3.95), 180.0)
	_p(lvl, parent, "ph/ArmChair_01", Vector3(-8.6, f, 2.0), 105.0)
	_p(lvl, parent, "ph/ArmChair_01", Vector3(-3.4, f, 1.1), -40.0)
	_p(lvl, parent, "ph/coffee_table_round_01", Vector3(-5.7, f, 2.3), 0.0)
	_p(lvl, parent, "ph/wooden_bookshelf_worn", Vector3(-9.0, f, 0.9), 90.0)
	_p(lvl, parent, "ph/Shelf_01", Vector3(-4.6, f, 0.25), 0.0)
	painting(k, Vector3(-6.0, S + 1.85, 4.3), Vector3(0, 0, -1), 1.0, 0.75)
	painting(k, Vector3(-9.3, S + 1.7, 3.1), Vector3(1, 0, 0), 0.7, 0.9)
	withered_plant(k, r, Vector3(-8.8, f, 4.0))
	withered_plant(k, r, Vector3(-3.6, f, 4.0))
	hanging_lamp(lvl, parent, Vector3(-5.6, UF - 1.05, 2.3), 0.35)
	# W2 back room / store x[-9.5,-1.2] z[-8,0]
	_p(lvl, parent, "ph/old_military_crate", Vector3(-7.8, f, -7.2), 0.0)
	_p(lvl, parent, "ph/wooden_crate_01", Vector3(-8.9, f, -5.0), 90.0)
	_p(lvl, parent, "ph/wooden_crate_01", Vector3(-8.9, f + 0.35, -5.1), 84.0)
	_p(lvl, parent, "ph/Barrel_01", Vector3(-2.2, f, -7.3), 0.0)
	_p(lvl, parent, "ph/barrel_03", Vector3(-2.9, f, -7.4), 0.0)
	_p(lvl, parent, "ph/drawer_cabinet", Vector3(-5.0, f, -7.6), 0.0)
	_p(lvl, parent, "ph/cardboard_box_01", Vector3(-6.4, f, -1.2), 20.0)
	_p(lvl, parent, "ph/propane_tank", Vector3(-9.0, f, -2.2), 0.0)
	_p(lvl, parent, "ph/SchoolChair_01", Vector3(-4.4, f, -3.6), 140.0)
	painting(k, Vector3(-1.35, S + 1.7, -2.0), Vector3(-1, 0, 0), 0.6, 0.8)
	hanging_lamp(lvl, parent, Vector3(-5.5, UF - 1.05, -4.0), -0.4)
	# E1 dining x[1.2,9.5] z[-2.5,4.5]: mouldy tables
	_p(lvl, parent, "ph/dining_table", Vector3(5.6, f, 1.2), 0.0)
	for c in [[Vector3(4.6, f, 2.2), 180.0], [Vector3(6.6, f, 2.25), 170.0], [Vector3(5.0, f, 0.1), 10.0], [Vector3(7.2, f, -0.2), 40.0]]:
		_p(lvl, parent, "ph/dining_chair_02", c[0], c[1])
	var tipped := _p(lvl, parent, "ph/dining_chair_02", Vector3(3.2, f + 0.22, -0.9), 70.0)
	if tipped:
		tipped.rotation.x = 1.45
	for m in [Vector3(5.0, f + 0.885, 1.0), Vector3(6.3, f + 0.885, 1.5), Vector3(5.8, f + 0.885, 0.7)]:
		k.box(m, Vector3(r.randf_range(0.3, 0.6), 0.004, r.randf_range(0.2, 0.5)), "l77_mould", GeoKit.ALL, false)
	_p(lvl, parent, "ph/SchoolDesk_01", Vector3(8.8, f, 3.6), -90.0)
	_p(lvl, parent, "ph/Shelf_01", Vector3(9.25, f, -0.8), -90.0)
	_p(lvl, parent, "ph/wall_clock", Vector3(5.6, S + 2.3, 4.28), 180.0)
	painting(k, Vector3(9.3, S + 1.75, 1.6), Vector3(-1, 0, 0), 0.9, 0.7)
	withered_plant(k, r, Vector3(2.0, f, 4.0))
	withered_plant(k, r, Vector3(8.9, f, -2.0))
	hanging_lamp(lvl, parent, Vector3(5.6, UF - 1.05, 1.2), 0.25)
	# E2 bedroom x[1.2,9.5] z[-8,-2.5]
	_p(lvl, parent, "ph/old_bed_frame", Vector3(7.8, f, -6.6), 90.0)
	_p(lvl, parent, "ph/ClassicNightstand_01", Vector3(8.9, f, -4.6), -90.0)
	_p(lvl, parent, "ph/vintage_suitcase", Vector3(3.6, f, -7.6), 10.0)
	_p(lvl, parent, "ph/GreenChair_01", Vector3(2.4, f, -3.4), 150.0)
	painting(k, Vector3(5.0, S + 1.8, -7.8), Vector3(0, 0, 1), 0.8, 0.6)
	hanging_lamp(lvl, parent, Vector3(5.5, UF - 1.05, -5.2), -0.2)
	# corridor: dead switches by every doorway, a lifebuoy by the door
	for sw in [[Vector3(-1.29, S + 1.3, 2.9), Vector3(-1, 0, 0)], [Vector3(1.29, S + 1.3, 1.7), Vector3(1, 0, 0)],
			[Vector3(-1.29, S + 1.3, -3.4), Vector3(-1, 0, 0)], [Vector3(1.29, S + 1.3, -4.8), Vector3(1, 0, 0)], [Vector3(0.75, S + 1.3, 4.3), Vector3(0, 0, -1)]]:
		switch_plate(k, sw[0], sw[1])
	painting(k, Vector3(-1.13, S + 1.8, -1.0), Vector3(1, 0, 0), 0.5, 0.7)
	painting(k, Vector3(1.13, S + 1.8, -2.0), Vector3(-1, 0, 0), 0.5, 0.7)
	hanging_lamp(lvl, parent, Vector3(0.0, UF - 1.05, -6.0), 0.5)


## Upper floor: pipes everywhere, the valve hidden behind them (always present).
static func upper_floor(lvl: Node3D, parent: Node3D, k: GeoKit) -> Vector3:
	var f := UF
	_p(lvl, parent, "ph/modular_pipes", Vector3(-1.8, f, -4.05), 0.0)
	_p(lvl, parent, "ph/modular_industrial_pipes_01", Vector3(-4.0, f, 0.8), 90.0)
	_p(lvl, parent, "ph/modular_industrial_pipes_01", Vector3(4.0, f, -1.6), -90.0)
	_p(lvl, parent, "ph/metal_tool_chest", Vector3(-3.7, f, 3.6), 90.0)
	_p(lvl, parent, "ph/steel_frame_shelves_02", Vector3(-1.6, f, 3.95), 180.0)
	_p(lvl, parent, "ph/SchoolDesk_01", Vector3(1.3, f, 3.5), 200.0)
	var c := _p(lvl, parent, "ph/plastic_monobloc_chair_01", Vector3(1.6, f + 0.3, 2.3), 30.0)
	if c:
		c.rotation.z = 1.5
	_p(lvl, parent, "ph/caged_hanging_light", Vector3(-1.6, ROOF - 1.0, -1.0), 0.0)
	# horizontal runs in and out of the walls, at several heights
	for run in [[Vector3(-4.2, f + 2.55, -0.5), Vector3(0, 0, 1), 8.2, 0.11], [Vector3(-0.5, f + 2.85, -4.2), Vector3(1, 0, 0), 8.2, 0.09],
			[Vector3(4.2, f + 2.3, 0.5), Vector3(0, 0, 1), 6.0, 0.13], [Vector3(-2.0, f + 0.35, -4.15), Vector3(1, 0, 0), 4.5, 0.15],
			[Vector3(-4.15, f + 1.6, 2.2), Vector3(0, 0, 1), 3.6, 0.08]]:
		_pipe(parent, run[0], run[1], run[2], run[3])
	# the knot of vertical pipes in the north-west corner, the valve behind it
	for v in [Vector3(-3.25, 0, -3.7), Vector3(-3.0, 0, -3.15), Vector3(-3.55, 0, -2.75), Vector3(-2.7, 0, -3.85)]:
		k.cylinder(Vector3(v.x, f + (ROOF - f) * 0.5, v.z), 0.11, ROOF - f, "l77_rust", 10)
	var valve := Vector3(-4.05, f + 1.15, -3.35)
	_pipe(parent, valve + Vector3(-0.2, 0, 0), Vector3(1, 0, 0), 0.5, 0.1)
	var wheel := MeshInstance3D.new()
	wheel.name = "PressureValve"
	var tm := TorusMesh.new()
	tm.inner_radius = 0.15
	tm.outer_radius = 0.2
	wheel.mesh = tm
	wheel.material_override = MatLib.get_mat("l77_rust")
	wheel.position = valve + Vector3(0.22, 0, 0)
	wheel.rotation.z = PI * 0.5
	parent.add_child(wheel)
	return valve


static func _pipe(parent: Node3D, center: Vector3, axis: Vector3, length: float, radius: float) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = length
	cm.radial_segments = 10
	mi.mesh = cm
	mi.material_override = MatLib.get_mat("l77_rust")
	mi.position = center
	if absf(axis.x) > 0.5:
		mi.rotation.z = PI * 0.5
	elif absf(axis.z) > 0.5:
		mi.rotation.x = PI * 0.5
	parent.add_child(mi)
	for e in [-0.5, 0.5]:
		var fl := MeshInstance3D.new()
		var fm := CylinderMesh.new()
		fm.top_radius = radius * 1.45
		fm.bottom_radius = radius * 1.45
		fm.height = 0.05
		fl.mesh = fm
		fl.material_override = mi.material_override
		fl.position = center + axis * length * e * 0.92
		fl.rotation = mi.rotation
		parent.add_child(fl)


## The Lamp Zone: bulb, control consoles, radio transmitter, cut cables.
static func lamp_zone(lvl: Node3D, parent: Node3D, k: GeoKit) -> Node3D:
	var L := B.LAMP
	var bulb := MeshInstance3D.new()
	bulb.name = "GiantBulb"
	var sm := SphereMesh.new()
	sm.radius = 0.62
	sm.height = 1.5
	bulb.mesh = sm
	bulb.material_override = MatLib.get_mat("l77_bulb")
	bulb.position = L + Vector3(0, 2.15, 0)
	parent.add_child(bulb)
	k.cylinder(L + Vector3(0, 1.55, 0), 0.22, 0.2, "l77_dark", 10, false)
	# consoles along the parapet, outside the lamp room
	for i in 3:
		var at := Vector3(1.0 + i * 1.15, ROOF, -3.9)
		k.box(at + Vector3(0, 0.5, 0), Vector3(1.05, 1.0, 0.5), "l77_rust")
		k.box_xf(Transform3D(Basis(Vector3.RIGHT, -0.5), at + Vector3(0, 1.05, 0.08)), Vector3(1.0, 0.04, 0.42), "l77_panelface", GeoKit.ALL, false)
		for b in 6:
			var bx := at + Vector3(-0.35 + (b % 3) * 0.35, 1.1 - 0.08 * (b / 3), 0.05 + 0.12 * (b / 3))
			k.box(bx, Vector3(0.07, 0.04, 0.07), "l77_dark" if (b + i) % 2 == 0 else "l77_pot", GeoKit.ALL, false)
		k.box_xf(Transform3D(Basis(Vector3.RIGHT, 0.4 + 0.3 * i), at + Vector3(0.38, 1.25, 0.1)), Vector3(0.03, 0.3, 0.03), "l77_dark", GeoKit.ALL, false)
	_p(lvl, parent, "ph/metal_office_desk", Vector3(-3.0, ROOF, 3.45), 180.0, 0.0, true)
	_p(lvl, parent, "ph/vintage_radio_transceiver", Vector3(-3.3, ROOF + 0.79, 3.4), 170.0)
	_p(lvl, parent, "ph/power_box_01", Vector3(4.2, ROOF + 0.4, -1.0), -90.0)
	_p(lvl, parent, "ph/power_box_01", Vector3(4.2, ROOF + 0.4, 0.2), -90.0)
	_p(lvl, parent, "ph/modular_electric_cables", Vector3(2.2, ROOF, -4.3), 0.0)
	var sign := Label3D.new()
	sign.text = "PIPE LINK SOURCE"
	sign.font_size = 28
	sign.pixel_size = 0.0018
	sign.modulate = Color(0.75, 0.72, 0.6)
	sign.outline_size = 0
	sign.shaded = true
	sign.position = Vector3(2.15, ROOF + 1.25, -3.62)
	sign.rotation.x = -0.5
	parent.add_child(sign)
	return bulb


## Exterior: loose rock on the summit rim, a lifebuoy by the door, and huge
## rock masses on the column's flanks (never under the east spur).
static func exterior(lvl: Node3D, parent: Node3D, r: RandomNumberGenerator) -> void:
	_p(lvl, parent, "ph/lifebuoy", Vector3(1.3, S + 1.2, 4.72), 0.0)
	for p in [[Vector3(-7.8, S, 9.5), 1.2], [Vector3(-8.2, S, -3.0), 1.5], [Vector3(6.5, S, -6.2), 1.1], [Vector3(-3.0, S, -7.4), 0.9], [Vector3(7.8, S, 11.0), 0.8]]:
		_p(lvl, parent, "ph/boulder_01", p[0], r.randf() * 360.0, p[1], true)
	for n in 5:
		_p(lvl, parent, "ph/rock_07", Vector3(r.randf_range(-7.5, 7.5), S, r.randf_range(5.5, 11.5)), r.randf() * 360.0)
	# the column itself: rings of huge boulders from below the waterline up to
	# the summit cliffs; the east fall line under the spur stays clear
	var y := -6.0
	while y < S - 6.0:
		var t := clampf((y + 14.0) / (S + 8.0), 0.0, 1.0)
		var rad := lerpf(13.5, 7.0, t)
		var n := 6
		for i in n:
			var a := TAU * (i + r.randf_range(-0.3, 0.3)) / n
			var at := Vector3(cos(a) * rad - 2.0, y, sin(a) * rad + 1.5)
			if at.x > 4.0 and at.z > -3.0 and at.z < 16.0:
				continue
			var hh := minf(r.randf_range(11.0, 17.0) * (1.0 - 0.35 * t), S - 1.2 - y)
			if hh < 3.0:
				continue
			_p(lvl, parent, "ph/boulder_01", at, rad_to_deg(-a) + r.randf_range(-30.0, 30.0), hh)
		y += 7.5
	# lumps under the spur's flanks, so it reads as rock
	for b in [[Vector3(10.5, S - 4.2, 4.6), 3.6], [Vector3(12.5, S - 4.6, 9.2), 3.8], [Vector3(15.2, S - 4.4, 6.9), 3.2], [Vector3(9.0, S - 5.5, 9.6), 4.4]]:
		_p(lvl, parent, "ph/boulder_01", b[0], r.randf() * 360.0, b[1])
