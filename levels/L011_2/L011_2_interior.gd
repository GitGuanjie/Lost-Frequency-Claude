extends RefCounted
## Level 11.2 Block C interior (M.E.G. Base Omicron): ground floor and first
## floor of one identical apartment block, entered from the courtyard at
## z = -28. Plan (x: west facade 42, corridor 47.4-49.6, east facade 55):
##  G west: infirmary (-60..-46), classroom (-46..-34), lobby (-34..-22),
##          gateway doors 189 (-16) and 852 (-6)
##  G east: door 155 (-54), stairwell (-48..-36), door 283 (-33),
##          lounge (-30..-18), kitchen with the restocking fridge (-18..-6)
##  1F:     doors 36 (-54 W), 59 (-30 W), 78 (-6 W), 121 (-12 E); landing
##          (-48..-36 E); Jane's room (-30..-18 E)
## Doors carry amateur wooden signs with level numbers (SOURCE).

const X0 := 42.0
const X1 := 55.0
const CW := 47.4
const CE := 49.6
const Z0 := -60.0
const Z1 := 4.0
const F0 := 0.3
const F1 := 3.1
const CEIL0 := 2.85
const CEIL1 := 5.8
const ENTRY_Z := -28.0

var lvl
var doors: Dictionary = {}     # edge -> {pos, normal, floor}
var fridge_pos := Vector3.ZERO


func _init(level) -> void:
	lvl = level


func build(k: GeoKit, node: Node3D) -> void:
	_shell(k)
	_corridors(k)
	_rooms_ground(k, node)
	_rooms_first(k, node)
	_stair(k)
	_lights(k)


func _shell(k: GeoKit) -> void:
	# floor slabs (first floor has the stair void cut out)
	k.slab(X0, Z0, X1, Z1, F0, 0.6, "l112_lino")
	k.slab(X0, Z0, X1, -48.0, F1, 0.25, "l112_lino")
	k.slab(X0, -41.5, X1, Z1, F1, 0.25, "l112_lino")
	k.slab(X0, -48.0, 52.1, -41.5, F1, 0.25, "l112_lino")
	k.box(Vector3(54.5, F1 - 0.125, -44.75), Vector3(0.4, 0.25, 6.5), "l112_lino")
	# exterior walls, one storey at a time (guide: openings never stack)
	for y in [F0, F1]:
		var hh: float = (F1 - F0) if y == F0 else (CEIL1 - F1)
		var wops: Array = []
		var eops: Array = []
		var z := Z0 + 1.6 + 1.6
		while z < Z1 - 1.6:
			var at := z - Z0
			if y == F0 and absf(z - ENTRY_Z) < 2.4:
				pass
			elif absf(z - (-49.0)) > 2.0 and absf(z - (-7.0)) > 2.0:
				wops.append({"at": at, "w": 1.5, "h": 1.5, "sill": 0.85})
				eops.append({"at": at, "w": 1.5, "h": 1.5, "sill": 0.85})
			z += 3.2
		if y == F0:
			wops.append({"at": ENTRY_Z - Z0, "w": 2.0, "h": 2.3, "sill": 0.0})
		k.wall(Vector3(X0 + 0.15, y, Z0), Vector3(X0 + 0.15, y, Z1), hh, 0.3, "l112_white", wops)
		k.wall(Vector3(X1 - 0.15, y, Z0), Vector3(X1 - 0.15, y, Z1), hh, 0.3, "l112_white", eops)
		k.wall(Vector3(X0, y, Z0 + 0.15), Vector3(X1, y, Z0 + 0.15), hh, 0.3, "l112_white")
		k.wall(Vector3(X0, y, Z1 - 0.15), Vector3(X1, y, Z1 - 0.15), hh, 0.3, "l112_white")
		# glass in every window opening, inner sills
		for op in wops + eops:
			if op["sill"] < 0.1:
				continue
			var px: float = X0 + 0.15 if wops.has(op) else X1 - 0.15
			var pz: float = Z0 + float(op["at"])
			k.box(Vector3(px, y + 1.6, pz), Vector3(0.03, 1.5, 1.5), "l112_glass", GeoKit.ALL, false)
			k.box(Vector3(px + (0.2 if px < 48.0 else -0.2), y + 0.82, pz), Vector3(0.25, 0.05, 1.6), "l112_white_trim", GeoKit.ALL, false)
	# outside: entrance step, canopy, the orange core band above the door
	k.box(Vector3(X0 - 0.8, 0.075, ENTRY_Z), Vector3(1.6, 0.15, 3.0), "l112_concrete")
	k.box(Vector3(X0 - 1.0, 2.75, ENTRY_Z), Vector3(2.0, 0.15, 3.2), "l112_concrete")
	k.box(Vector3(X0 - 1.0, 2.84, ENTRY_Z), Vector3(1.9, 0.05, 3.1), "l112_snow", GeoKit.PY, false)
	k.box(Vector3(X0 - 0.12, 4.3, ENTRY_Z), Vector3(0.24, 3.0, 3.0), "l112_orange", GeoKit.ALL, false)
	for zc in [-49.0, -7.0]:
		k.box(Vector3(X0 - 0.12, 2.9, zc), Vector3(0.24, 5.8, 3.0), "l112_orange", GeoKit.ALL, false)
		k.box(Vector3(X1 + 0.12, 2.9, zc), Vector3(0.24, 5.8, 3.0), "l112_orange", GeoKit.ALL, false)
	k.box(Vector3(X1 + 0.12, 2.9, ENTRY_Z), Vector3(0.24, 5.8, 3.0), "l112_orange", GeoKit.ALL, false)


func _corridors(k: GeoKit) -> void:
	for y in [F0, F1]:
		var hh: float = (F1 - 0.25 - F0) if y == F0 else (CEIL1 - F1)
		var wo: Array = []
		var eo: Array = []
		if y == F0:
			wo = [_op(-52.0), _op(-40.0), {"at": ENTRY_Z - Z0, "w": 3.0, "h": 2.4, "sill": 0.0}]
			eo = [_op(-46.8), _op(-24.0), _op(-12.0)]
		else:
			eo = [_op(-38.0), _op(-24.0)]
		k.wall(Vector3(CW, y, Z0 + 0.3), Vector3(CW, y, Z1 - 0.3), hh, 0.15, "l112_wall", wo)
		k.wall(Vector3(CE, y, Z0 + 0.3), Vector3(CE, y, Z1 - 0.3), hh, 0.15, "l112_wall", eo)
		# painted dado on the corridor faces
		for side in [[CW + 0.08, 1.0], [CE - 0.08, -1.0]]:
			k.box(Vector3(side[0], y + 0.6, -28.0), Vector3(0.01, 1.2, 63.2), "l112_dado", GeoKit.ALL, false)
		# ceiling of the corridor
		k.box(Vector3((CW + CE) * 0.5, y + hh - 0.01, -28.0), Vector3(CE - CW, 0.02, 63.4), "l112_ceiling", GeoKit.NY, false)
	# room cross walls (open rooms only)
	for zw in [-46.0, -34.0, -22.0]:
		k.wall(Vector3(X0 + 0.3, F0, zw), Vector3(CW, F0, zw), F1 - 0.25 - F0, 0.15, "l112_wall")
	for zw in [-48.0, -36.0, -30.0, -18.0, -6.0]:
		k.wall(Vector3(CE, F0, zw), Vector3(X1 - 0.3, F0, zw), F1 - 0.25 - F0, 0.15, "l112_wall")
	for zw in [-48.0, -36.0, -30.0, -18.0]:
		k.wall(Vector3(CE, F1, zw), Vector3(X1 - 0.3, F1, zw), CEIL1 - F1, 0.15, "l112_wall")
	# closed first-floor west rooms: a back wall keeps the windows honest
	k.wall(Vector3(X0 + 0.9, F1, Z0 + 0.3), Vector3(X0 + 0.9, F1, Z1 - 0.3), CEIL1 - F1, 0.1, "l112_wall_dark")
	k.wall(Vector3(X1 - 0.9, F0, -60.0 + 0.3), Vector3(X1 - 0.9, F0, -48.0), F1 - 0.25 - F0, 0.1, "l112_wall_dark")
	k.wall(Vector3(X1 - 0.9, F1, -60.0 + 0.3), Vector3(X1 - 0.9, F1, -48.0), CEIL1 - F1, 0.1, "l112_wall_dark")
	k.wall(Vector3(X1 - 0.9, F1, -18.0), Vector3(X1 - 0.9, F1, Z1 - 0.3), CEIL1 - F1, 0.1, "l112_wall_dark")
	k.wall(Vector3(X1 - 0.9, F1, -36.0), Vector3(X1 - 0.9, F1, -30.0), CEIL1 - F1, 0.1, "l112_wall_dark")
	k.wall(Vector3(X0 + 0.9, F0, -22.0), Vector3(X0 + 0.9, F0, Z1 - 0.3), F1 - 0.25 - F0, 0.1, "l112_wall_dark")
	k.wall(Vector3(X1 - 0.9, F0, -36.0), Vector3(X1 - 0.9, F0, -30.0), F1 - 0.25 - F0, 0.1, "l112_wall_dark")
	k.wall(Vector3(X1 - 0.9, F0, -6.0), Vector3(X1 - 0.9, F0, Z1 - 0.3), F1 - 0.25 - F0, 0.1, "l112_wall_dark")
	# room ceilings (ground floor rooms under the first floor slab are covered by it)
	k.box(Vector3((X0 + X1) * 0.5, CEIL1 - 0.01, -28.0), Vector3(X1 - X0, 0.02, 64.0), "l112_ceiling", GeoKit.NY, false)
	k.box(Vector3((X0 + X1) * 0.5, F1 - 0.26, -28.0), Vector3(X1 - X0, 0.02, 64.0), "l112_ceiling", GeoKit.NY, false)


static func _op(z: float) -> Dictionary:
	return {"at": z - Z0 - 0.3, "w": 1.0, "h": 2.1, "sill": 0.0}


## A gateway door on a corridor wall with its wooden number sign; returns the
## interaction point in the corridor.
func gateway(k: GeoKit, edge: String, label: String, wall_x: float, z: float, y: float) -> Vector3:
	var s := 1.0 if wall_x < 48.5 else -1.0
	var face := wall_x + s * 0.075
	k.box(Vector3(face + s * 0.03, y + 1.03, z), Vector3(0.05, 2.06, 0.92), "l112_door_wood")
	k.box(Vector3(face + s * 0.02, y + 2.12, z), Vector3(0.05, 0.1, 1.12), "l112_white_trim", GeoKit.ALL, false)
	for e in [-1.0, 1.0]:
		k.box(Vector3(face + s * 0.02, y + 1.06, z + e * 0.52), Vector3(0.05, 2.12, 0.08), "l112_white_trim", GeoKit.ALL, false)
	k.box(Vector3(face + s * 0.08, y + 1.0, z - 0.35), Vector3(0.06, 0.04, 0.14), "l112_steel", GeoKit.ALL, false)
	# the sign: a scrap of board nailed crookedly beside the door
	var tilt := (hash(label) % 9 - 4) * 0.025
	var bp := Vector3(face + s * 0.03, y + 1.6, z + 0.85)
	k.box_xf(Transform3D(Basis(Vector3.RIGHT, tilt), bp), Vector3(0.03, 0.26, 0.46), "l112_board", GeoKit.ALL, false)
	for nz in [-0.18, 0.18]:
		k.box(bp + Vector3(s * 0.02, 0.0, nz), Vector3(0.02, 0.03, 0.03), "l112_steel", GeoKit.ALL, false)
	var lab := Label3D.new()
	lab.text = label
	lab.font_size = 64
	lab.pixel_size = 0.0035
	lab.modulate = Color(0.08, 0.06, 0.05)
	lab.outline_size = 0
	lab.shaded = true
	lab.position = bp + Vector3(s * 0.02, 0.0, 0.0)
	lab.rotation = Vector3(tilt, PI * 0.5 if s > 0 else -PI * 0.5, 0.0)
	lvl.add_child(lab)
	var at := Vector3(wall_x + s * 0.8, y + 1.1, z)
	doors[edge] = {"pos": at, "label": label}
	return at


func _rooms_ground(k: GeoKit, node: Node3D) -> void:
	var f := F0
	# infirmary (-60..-46 west)
	k.slab(X0 + 0.3, -59.7, CW - 0.08, -46.08, f + 0.012, 0.012, "l112_tile", GeoKit.PY)
	for i in 3:
		P(node, "ph/old_bed_frame", Vector3(43.6, f, -57.5 + i * 3.3), 90.0, true)
	P(node, "ph/medical_box", Vector3(46.6, f + 0.0, -58.9), 0.0)
	P(node, "ph/drawer_cabinet", Vector3(46.9, f, -47.0), -90.0, true)
	P(node, "ph/steel_frame_shelves_02", Vector3(46.9, f, -55.5), -90.0, true)
	P(node, "ph/plastic_crate_01", Vector3(46.8, f + 1.0, -55.5), -90.0)
	P(node, "ph/korean_fire_extinguisher_01", Vector3(47.1, f, -49.0), -90.0)
	P(node, "ph/medical_box", Vector3(46.9, f + 1.89, -47.0), 90.0)
	# classroom (-46..-34 west): desks facing north, board on the north wall
	for row in 3:
		for col in 2:
			var p := Vector3(43.6 + col * 1.9, f, -42.6 + row * 2.2)
			P(node, "ph/SchoolDesk_01", p, 180.0)
			P(node, "ph/SchoolChair_01", p + Vector3(0, 0, 0.6), 180.0)
	P(node, "ph/metal_office_desk", Vector3(44.9, f, -44.9), 0.0, true)
	k.box(Vector3(44.8, f + 1.55, -45.88), Vector3(3.0, 1.1, 0.04), "l112_chalkboard", GeoKit.ALL, false)
	k.box(Vector3(44.8, f + 0.98, -45.84), Vector3(3.0, 0.05, 0.1), "l112_door_wood", GeoKit.ALL, false)
	P(node, "ph/wall_clock", Vector3(46.4, f + 2.15, -45.86), 0.0)
	P(node, "ph/wooden_bookshelf_worn", Vector3(42.75, f, -35.2), 90.0, true)
	# lobby (-34..-22 west): the M.E.G. desk
	P(node, "ph/metal_office_desk", Vector3(44.0, f, -24.0), 90.0, true)
	P(node, "ph/vintage_radio_transceiver", Vector3(44.1, f + 0.79, -24.4), 90.0)
	P(node, "ph/clipboard", Vector3(43.9, f + 0.79, -23.5), 70.0)
	P(node, "ph/GreenChair_01", Vector3(43.0, f, -24.0), 90.0)
	P(node, "ph/old_military_crate", Vector3(45.5, f, -33.2), 0.0, true)
	P(node, "ph/old_military_crate", Vector3(45.5, f + 0.3, -33.2), 8.0)
	P(node, "ph/hand_truck", Vector3(46.8, f, -31.6), -30.0)
	P(node, "ph/fire_alarm", Vector3(47.31, f + 1.5, -26.0), -90.0)
	P(node, "ph/security_camera_01", Vector3(42.6, f + 2.4, -22.4), 140.0)
	k.box(Vector3(47.3, f + 1.5, -24.6), Vector3(0.03, 0.9, 1.4), "l112_cork", GeoKit.ALL, false)
	# lounge (-30..-18 east)
	k.slab(CE + 0.08, -29.92, X1 - 0.3, -18.08, f + 0.012, 0.012, "l112_wood", GeoKit.PY)
	P(node, "ph/Sofa_01", Vector3(54.1, f, -24.0), -90.0, true)
	P(node, "ph/ArmChair_01", Vector3(52.0, f, -27.8), 20.0)
	P(node, "ph/ArmChair_01", Vector3(52.0, f, -20.2), 160.0)
	P(node, "ph/coffee_table_round_01", Vector3(52.6, f, -24.0), 0.0)
	P(node, "ph/Television_01", Vector3(50.2, f + 0.0, -24.0), 90.0)
	P(node, "ph/wooden_bookshelf_worn", Vector3(51.5, f, -29.6), 0.0, true)
	P(node, "ph/lantern_chandelier_01", Vector3(52.4, CEIL0 - 0.9, -24.0), 0.0)
	# kitchen / apartment with the fridge (-18..-6 east)
	k.slab(CE + 0.08, -17.92, X1 - 0.3, -6.08, f + 0.012, 0.012, "l112_tile", GeoKit.PY)
	fridge_pos = Vector3(54.3, f, -16.6)
	k.box(fridge_pos + Vector3(0, 0.9, 0), Vector3(0.66, 1.8, 0.7), "l112_fridge")
	k.box(fridge_pos + Vector3(-0.34, 1.2, 0.25), Vector3(0.03, 0.5, 0.04), "l112_steel", GeoKit.ALL, false)
	for i in 3:
		k.box(Vector3(54.4, f + 0.45, -15.6 + i * 0.62), Vector3(0.6, 0.9, 0.6), "l112_counter")
		k.box(Vector3(54.4, f + 0.92, -15.6 + i * 0.62), Vector3(0.64, 0.04, 0.62), "l112_worktop", GeoKit.ALL, false)
	P(node, "ph/dining_table", Vector3(52.0, f, -10.5), 90.0, true)
	for e in [[51.4, -11.4, 90.0], [52.6, -11.4, -90.0], [51.4, -9.6, 90.0], [52.6, -9.6, -90.0]]:
		P(node, "ph/dining_chair_02", Vector3(e[0], f, e[1]), e[2])
	P(node, "ph/plastic_bottle_gallon", Vector3(54.4, f + 0.94, -14.4), 0.0)
	P(node, "ph/cardboard_box_01", Vector3(50.3, f, -7.0), 20.0)
	P(node, "ph/cardboard_box_01", Vector3(50.3, f + 0.34, -7.1), 70.0)
	P(node, "ph/wall_clock", Vector3(54.83, f + 2.0, -12.0), -90.0)


func _rooms_first(k: GeoKit, node: Node3D) -> void:
	var f := F1
	# landing (-48..-36 east) above the stair
	P(node, "ph/plastic_monobloc_chair_01", Vector3(54.0, f, -37.0), 200.0)
	P(node, "ph/propane_tank", Vector3(54.3, f, -38.3), 0.0)
	# Jane's room (-30..-18 east): the last unbarricaded room of the diary
	k.slab(CE + 0.08, -29.92, X1 - 0.3, -18.08, f + 0.012, 0.012, "l112_wood", GeoKit.PY)
	P(node, "ph/old_bed_frame", Vector3(53.6, f, -27.6), 0.0, true)
	P(node, "ph/ClassicNightstand_01", Vector3(54.4, f, -25.8), -90.0)
	P(node, "ph/GreenChair_01", Vector3(53.8, f, -20.0), -120.0)
	P(node, "ph/vintage_suitcase", Vector3(51.0, f, -29.4), 10.0)
	P(node, "ph/ornate_mirror_01", Vector3(54.83, f + 1.4, -22.8), -90.0)
	P(node, "ph/wooden_bookshelf_worn", Vector3(50.4, f, -18.6), 180.0, true)
	P(node, "ph/vintage_flashlight", Vector3(54.4, f + 0.71, -25.8), 30.0)


func _stair(k: GeoKit) -> void:
	# straight flight in the stairwell, south-going, landing on the first floor
	k.stairs(Vector3(53.2, F0, -46.0), Vector3(0, 0, 1), 2.0, F1 - F0, 16, "l112_concrete", 0.28, true)
	# rails around the void on the first floor
	k.box(Vector3(52.05, F1 + 0.5, -44.75), Vector3(0.06, 1.0, 6.5), "l112_steel", GeoKit.ALL, true)
	k.box(Vector3(53.2, F1 + 0.5, -48.0 + 0.1), Vector3(2.2, 1.0, 0.06), "l112_steel", GeoKit.ALL, true)
	k.box(Vector3(54.6, F1 * 0.5 + 0.3, -44.0), Vector3(0.05, 0.05, 4.4), "l112_steel", GeoKit.ALL, false)


func _lights(k: GeoKit) -> void:
	var warm := Color(1.0, 0.86, 0.66)
	var cool := Color(0.92, 0.95, 1.0)
	for z in [-56.0, -46.0, -36.0, -26.0, -16.0, -6.0]:
		for y in [F0, F1]:
			var ceil: float = (F1 - 0.27) if y == F0 else (CEIL1 - 0.02)
			k.panel(Vector3(48.5, ceil, z), 0.3, 1.2, "l112_tube", float(z), 0.0)
			lvl.lights.add_anchor(Vector3(48.5, ceil - 0.3, z), cool, 0.9, 5.5, 0.04 if z == -36.0 else 0.0, "interior")
	for p in [Vector3(44.8, CEIL0, -53.0), Vector3(44.8, CEIL0, -40.0), Vector3(44.8, CEIL0, -28.0), Vector3(52.3, CEIL0, -24.0), Vector3(52.3, CEIL0, -12.0), Vector3(52.3, CEIL1 - 0.3, -24.0), Vector3(53.2, CEIL1 - 0.3, -42.0)]:
		k.panel(Vector3(p.x, p.y - 0.01, p.z), 0.6, 0.6, "l112_tube", p.z, 0.0)
		lvl.lights.add_anchor(p + Vector3(0, -0.4, 0), warm, 1.1, 6.0, 0.0, "interior")


func P(node: Node3D, id: String, pos: Vector3, yaw: float, collide: bool = false) -> Node3D:
	return Props.place(lvl, node, id, pos, yaw, 0.0, collide)
