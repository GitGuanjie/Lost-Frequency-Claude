extends RefCounted
## Level 29 dockyard and outer circle. SOURCE: arrivals by sea land at
## "one of the dockyards built around the area where wanderers first arrive";
## the ocean breaks "even the strongest boats"; huts and watchtowers stand at
## elevated places like hills and cliffs of the outer circle.
## ADAPTATION: one cove dockyard (main jetty with a T-head, two finger piers,
## harbour office, warehouse, moored boats, capsized wrecks on the beach), a
## gully road up to the plateau and two cliff-top watchtowers with huts.

const DECK_Y := 1.6

var lvl
var ter
var bk
var k: GeoKit
var props: Node3D
var boats: Node3D
var office_floor := 0.0
var office_pos := Vector3.ZERO
var towers: Array = []          # [platform centre]
var exit_spots: Array = []      # [Vector3 deck point next to each sloop]


func _init(level, terrain, build_kit, kit: GeoKit, prop_parent: Node3D) -> void:
	lvl = level
	ter = terrain
	bk = build_kit
	k = kit
	props = prop_parent
	boats = Node3D.new()
	boats.name = "Boats"
	level.add_child(boats)


func build() -> void:
	_jetty()
	_moorings()
	_office()
	_warehouse()
	_beach()
	_waterfront()
	for x in [-76.0, 82.0]:
		_tower(x)


func _deck(x0: float, z0: float, x1: float, z1: float) -> void:
	k.slab(x0, z0, x1, z1, DECK_Y, 0.22, "l29_deck_wood")
	# stringers and pilings
	for x in [x0 + 0.15, x1 - 0.15]:
		k.box(Vector3(x, DECK_Y - 0.36, (z0 + z1) * 0.5), Vector3(0.18, 0.3, absf(z1 - z0)), "l29_timber", GeoKit.ALL, false)
	var nz := int(absf(z1 - z0) / 3.2)
	var nx := int(absf(x1 - x0) / 3.2)
	for i in nz + 1:
		var z := lerpf(z0 + 0.2, z1 - 0.2, float(i) / maxf(1.0, nz))
		for x in [x0 + 0.1, x1 - 0.1]:
			var g: float = ter.h(x, z)
			if g > DECK_Y - 0.4:
				continue
			k.cylinder(Vector3(x, (DECK_Y + 0.35 + g - 0.3) * 0.5, z), 0.16, DECK_Y + 0.35 - g + 0.3, "l29_timber", 7, false, true)
	if nx > 1:
		for i in nx + 1:
			var x := lerpf(x0 + 0.2, x1 - 0.2, float(i) / nx)
			for z in [z0 + 0.1, z1 - 0.1]:
				var g: float = ter.h(x, z)
				if g < DECK_Y - 0.4:
					k.cylinder(Vector3(x, (DECK_Y + 0.35 + g - 0.3) * 0.5, z), 0.16, DECK_Y + 0.35 - g + 0.3, "l29_timber", 7, false, true)


## Bull rail: a low timber curb along a pier edge (keeps walkers on the deck).
func _curb(x: float, z0: float, z1: float) -> void:
	var inward := 0.0
	k.box(Vector3(x + inward, DECK_Y + 0.2, (z0 + z1) * 0.5), Vector3(0.18, 0.4, z1 - z0), "l29_timber")


func _jetty() -> void:
	# root ramp from the beach, main jetty, T-head
	_deck(-1.7, 53.0, 1.7, 112.0)
	_deck(-13.0, 112.0, 13.0, 119.0)
	_curb(-1.7, 59.0, 112.0)
	_curb(1.7, 59.0, 112.0)
	_curb(-25.2, 59.0, 94.0)
	_curb(-22.8, 59.0, 94.0)
	_curb(20.8, 59.0, 88.0)
	_curb(23.2, 59.0, 88.0)
	# finger piers
	_deck(-25.2, 53.0, -22.8, 94.0)
	_deck(20.8, 53.0, 23.2, 88.0)
	# bollards and cleats along the T-head and the jetty
	for x in [-11.5, -7.0, -2.5, 2.5, 7.0, 11.5]:
		k.cylinder(Vector3(x, DECK_Y + 0.3, 118.5), 0.16, 0.6, "l29_iron", 8, true, true)
	for z in [66.0, 80.0, 94.0, 106.0]:
		for x in [-1.45, 1.45]:
			k.cylinder(Vector3(x, DECK_Y + 0.25, z), 0.13, 0.5, "l29_iron", 8, false, true)
	# T-head rail on the open-sea side except the two boarding gaps
	bk.rail(Vector3(-13.0, DECK_Y, 119.0), Vector3(-9.2, DECK_Y, 119.0))
	bk.rail(Vector3(-4.8, DECK_Y, 119.0), Vector3(4.8, DECK_Y, 119.0))
	bk.rail(Vector3(9.2, DECK_Y, 119.0), Vector3(13.0, DECK_Y, 119.0))
	bk.rail(Vector3(-13.0, DECK_Y, 112.0), Vector3(-13.0, DECK_Y, 119.0))
	bk.rail(Vector3(13.0, DECK_Y, 112.0), Vector3(13.0, DECK_Y, 119.0))
	# a lamp post at the T-head and warning boards
	for x in [-12.4, 12.4]:
		k.box(Vector3(x, DECK_Y + 1.6, 112.5), Vector3(0.16, 3.2, 0.16), "l29_timber", GeoKit.ALL, false)
		bk.prop(props, "ph/lantern_chandelier_01", Vector3(x, DECK_Y + 2.35, 112.5), 0.0, 0.8)
	k.box(Vector3(0, DECK_Y + 1.2, 118.7), Vector3(2.2, 1.0, 0.08), "l29_whitewash", GeoKit.ALL, false)
	k.box(Vector3(-0.9, DECK_Y + 0.4, 118.7), Vector3(0.1, 1.6, 0.1), "l29_timber", GeoKit.ALL, false)
	k.box(Vector3(0.9, DECK_Y + 0.4, 118.7), Vector3(0.1, 1.6, 0.1), "l29_timber", GeoKit.ALL, false)
	for p in [Vector3(-12.2, 0, 116.0), Vector3(12.2, 0, 114.5), Vector3(-0.9, 0, 100.0)]:
		bk.prop(props, "ph/lifebuoy", Vector3(p.x, DECK_Y + 0.05, p.z), 90.0 if absf(p.x) > 5 else 0.0, 0.8)
	exit_spots = [Vector3(-7.0, DECK_Y, 116.6), Vector3(7.0, DECK_Y, 116.6)]


func _moorings() -> void:
	# the two sloops on the open side of the T-head (the departures)
	bk.boat(boats, Vector3(-7.0, -0.05, 122.6), 90.0, 7.6, true)
	bk.boat(boats, Vector3(7.0, -0.05, 122.8), 88.0, 7.0, true)
	# rowing boats and a sloop along the piers, inside the cove
	bk.boat(boats, Vector3(-4.3, -0.05, 78.0), 3.0, 4.6, false)
	bk.boat(boats, Vector3(-4.4, -0.05, 92.0), -4.0, 5.0, false)
	bk.boat(boats, Vector3(4.4, -0.05, 86.0), 178.0, 6.6, true)
	bk.boat(boats, Vector3(-20.3, -0.05, 76.0), 2.0, 4.4, false)
	bk.boat(boats, Vector3(-27.8, -0.05, 84.0), 182.0, 6.2, true)
	bk.boat(boats, Vector3(25.8, -0.05, 74.0), -3.0, 4.8, false)
	bk.boat(boats, Vector3(18.4, -0.05, 82.0), 176.0, 4.4, false)
	# lines from boats to the bollards
	for pair in [[Vector3(-11.5, DECK_Y + 0.5, 118.5), Vector3(-10.5, 0.5, 122.6)], [Vector3(-2.5, DECK_Y + 0.5, 118.5), Vector3(-3.6, 0.5, 122.6)],
			[Vector3(2.5, DECK_Y + 0.5, 118.5), Vector3(3.8, 0.5, 122.8)], [Vector3(11.5, DECK_Y + 0.5, 118.5), Vector3(10.2, 0.5, 122.8)]]:
		var a: Vector3 = pair[0]
		var b: Vector3 = pair[1]
		var bas := Basis.looking_at((b - a).normalized(), Vector3.UP)
		k.box_xf(Transform3D(bas, (a + b) * 0.5), Vector3(0.04, 0.04, a.distance_to(b)), "l29_rope", GeoKit.ALL, false)


func _office() -> void:
	office_pos = Vector3(-30.0, 0, 46.0)
	office_floor = bk.room(office_pos, 0.0, 7.0, 5.2, 3.0)
	var f := office_floor
	var o := office_pos
	bk.prop(props, "ph/metal_office_desk", Vector3(o.x - 1.2, f, o.z - 1.6), 0.0)
	bk.prop(props, "ph/vintage_radio_transceiver", Vector3(o.x - 1.6, f + 0.79, o.z - 1.7), 10.0)
	bk.prop(props, "ph/binder_notebook", Vector3(o.x - 0.6, f + 0.79, o.z - 1.5), 20.0)
	bk.prop(props, "ph/dining_chair_02", Vector3(o.x - 1.2, f, o.z - 0.7), 180.0)
	bk.prop(props, "ph/wooden_bookshelf_worn", Vector3(o.x + 2.7, f, o.z - 2.15), 0.0)
	bk.prop(props, "ph/drawer_cabinet", Vector3(o.x + 0.9, f, o.z - 2.2), 0.0)
	bk.prop(props, "ph/wall_clock", Vector3(o.x - 0.2, f + 2.1, o.z - 2.48), 0.0)
	bk.prop(props, "ph/lantern_chandelier_01", Vector3(o.x, f + 2.05, o.z), 0.0, 0.8)
	bk.prop(props, "ph/lifebuoy", Vector3(o.x - 3.4, f + 1.4, o.z - 1.0), 90.0, 0.8)
	bk.prop(props, "ph/wooden_crate_01", Vector3(o.x + 2.4, f, o.z + 1.6), 15.0)
	bk.prop(props, "ph/vintage_suitcase", Vector3(o.x + 2.6, f + 0.35, o.z + 1.6), 25.0, 0.0)
	# notice board outside the door
	k.box(Vector3(o.x + 2.6, f + 1.5, o.z + 2.9), Vector3(1.6, 1.1, 0.08), "l29_deck_wood", GeoKit.ALL, false)
	for x in [o.x + 1.9, o.x + 3.3]:
		k.box(Vector3(x, f + 0.9, o.z + 2.95), Vector3(0.1, 1.8, 0.1), "l29_timber", GeoKit.ALL, false)
	for i in 4:
		k.box(Vector3(o.x + 2.15 + i * 0.32, f + 1.5 + (0.15 if i % 2 == 0 else -0.12), o.z + 2.95), Vector3(0.24, 0.32, 0.01), "paper", GeoKit.ALL, false)
	lvl.lights.add_anchor(Vector3(o.x, f + 2.2, o.z), Color(1.0, 0.72, 0.42), 1.4, 6.0, 0.03, "office")


func _warehouse() -> void:
	var o := Vector3(31.0, 0, 44.0)
	bk.solid(o, 0.0, 11.0, 7.5, 1, {"door_x": -2.5, "chimney": false})
	for i in 7:
		var p := Vector3(o.x - 6.0 + i * 1.9 + lvl.rng.randf_range(-0.3, 0.3), 0, o.z + 5.4 + lvl.rng.randf_range(-0.6, 0.6))
		p.y = ter.h(p.x, p.z)
		var id: String = ["ph/wooden_crate_01", "ph/Barrel_01", "ph/barrel_03", "ph/old_military_crate"][i % 4]
		bk.prop(props, id, p, lvl.rng.randf_range(0, 360), 0.0, true)
	for p in [Vector3(26.0, 0, 50.0), Vector3(35.5, 0, 50.5), Vector3(14.0, 0, 54.0), Vector3(-15.0, 0, 52.5)]:
		p.y = ter.h(p.x, p.z)
		bk.prop(props, "ph/wooden_crate_01", p, lvl.rng.randf_range(0, 360), 0.0, true)
		bk.prop(props, "ph/wooden_crate_01", p + Vector3(0, 0.6, 0), lvl.rng.randf_range(0, 360))
	bk.prop(props, "ph/hand_truck", Vector3(28.0, ter.h(28.0, 50.8), 50.8), 200.0)
	bk.prop(props, "ph/wooden_ladder", Vector3(36.6, ter.h(36.6, 48.2), 48.2), 90.0, 2.4)
	# rope coils, a net rack and a work bench on the beach front
	for p in [Vector3(-3.0, 0, 57.5), Vector3(3.2, 0, 58.0), Vector3(-21.0, 0, 57.0)]:
		k.cylinder(Vector3(p.x, DECK_Y + 0.1, p.z), 0.42, 0.18, "l29_rope", 10, false, true)
	bk.prop(props, "ph/wooden_picnic_table", Vector3(-12.0, ter.h(-12.0, 47.0), 47.0), 80.0, 0.0, true)


func _beach() -> void:
	# capsized and stove-in boats: the sea breaks even the strongest boats
	var w1: Node3D = bk.boat(boats, Vector3(-14.5, 0.55, 66.5), 24.0, 5.4, false, Vector3(PI, 0, 0.12))
	var w2: Node3D = bk.boat(boats, Vector3(15.5, 0.25, 68.0), -150.0, 6.4, false, Vector3(0.28, 0, 0.85))
	if w1 and w2:
		pass
	for i in 9:
		var p := Vector3(lvl.rng.randf_range(10.0, 22.0), 0, lvl.rng.randf_range(63.0, 72.0))
		p.y = ter.h(p.x, p.z) + 0.04
		var bas := Basis(Vector3.UP, lvl.rng.randf() * TAU) * Basis(Vector3.RIGHT, lvl.rng.randf_range(-0.15, 0.15))
		k.box_xf(Transform3D(bas, p), Vector3(0.22, 0.04, lvl.rng.randf_range(1.0, 2.6)), "l29_deck_wood", GeoKit.ALL, false)
	# rocks at the cove mouth
	for i in 8:
		var side := -1.0 if i % 2 == 0 else 1.0
		var z: float = lvl.rng.randf_range(76.0, 116.0)
		var x: float = side * (ter.cove_half(z) + lvl.rng.randf_range(-2.0, 3.0))
		var hgt: float = lvl.rng.randf_range(1.2, 3.4)
		bk.prop(props, "ph/boulder_01", Vector3(x, ter.h(x, z) - hgt * 0.3, z), lvl.rng.randf_range(0, 360), hgt, false)


## The landing front: where arrivals are met by representatives of the
## societies (SOURCE), a boat under repair, lamps and gear along the beach.
func _waterfront() -> void:
	var c := Vector3(-11.0, 0, 49.0)
	c.y = ter.h(c.x, c.z)
	for sx in [-3.6, 0.0, 3.6]:
		for sz in [-1.8, 1.8]:
			var p := c + Vector3(sx, 0, sz)
			var gy: float = ter.h(p.x, p.z)
			k.box(Vector3(p.x, (gy + c.y + 3.0) * 0.5, p.z), Vector3(0.22, c.y + 3.0 - gy, 0.22), "l29_timber")
	bk.roof(c, Basis(), 8.0, 4.4, c.y + 3.0, 1.1, "l29_plank")
	bk.prop(props, "ph/dining_table", c + Vector3(0, 0, -0.4), 0.0, 0.0, true)
	for x in [-1.6, -0.5, 0.6, 1.7]:
		bk.prop(props, "ph/dining_chair_02", c + Vector3(x * 0.6, 0, -1.3), 0.0)
	bk.prop(props, "ph/clipboard", c + Vector3(-0.4, 0.88, -0.4), 15.0)
	bk.prop(props, "ph/binder_notebook", c + Vector3(0.5, 0.88, -0.3), -10.0)
	var cloths := ["l29_cloth_a", "l29_cloth_c", "l29_cloth_b", "l29_cloth_d", "l29_cloth_a"]
	for i in 5:
		k.box(c + Vector3(-3.2 + i * 1.6, 2.35, 2.0), Vector3(1.0, 1.2, 0.03), cloths[i], GeoKit.ALL, false)
	# boat on trestles under repair
	var r := Vector3(13.0, 0, 47.0)
	r.y = ter.h(r.x, r.z)
	for dz in [-1.6, 1.6]:
		k.box(r + Vector3(0, 0.45, dz), Vector3(1.6, 0.9, 0.3), "l29_timber")
	bk.boat(lvl, r + Vector3(0, 0.75, 0), 0.0, 5.6, false, Vector3(0, 0, 0.06))
	bk.prop(props, "ph/metal_tool_chest", r + Vector3(2.0, 0, 1.0), -30.0)
	bk.prop(props, "ph/wooden_ladder", r + Vector3(-1.6, 0, 0.0), 90.0, 1.8)
	for i in 4:
		k.box(r + Vector3(2.4, 0.1 + i * 0.09, -1.5), Vector3(0.9, 0.08, 3.2 - i * 0.2), "l29_plank", GeoKit.ALL, false)
	# lamp posts along the beach front and gear by the jetty root
	for x in [-36.0, -18.0, 6.0, 30.0]:
		var p := Vector3(x, 0, 53.5)
		p.y = ter.h(p.x, p.z)
		k.box(p + Vector3(0, 1.6, 0), Vector3(0.16, 3.2, 0.16), "l29_timber")
		k.box(p + Vector3(0, 3.1, 0.35), Vector3(0.1, 0.1, 0.8), "l29_timber", GeoKit.ALL, false)
		bk.prop(props, "ph/lantern_chandelier_01", p + Vector3(0, 2.25, 0.7), 0.0, 0.8)
	for p in [Vector3(-3.4, 0, 50.0), Vector3(3.6, 0, 51.0), Vector3(-4.2, 0, 52.4), Vector3(19.0, 0, 51.5), Vector3(-27.5, 0, 52.0)]:
		p.y = ter.h(p.x, p.z)
		var id: String = ["ph/Barrel_01", "ph/wooden_crate_01", "ph/barrel_03", "ph/old_military_crate", "ph/plastic_crate_01"][int(absf(p.x)) % 5]
		bk.prop(props, id, p, lvl.rng.randf_range(0, 360), 0.0, true)


func _tower(x: float) -> void:
	var z: float = ter.coast_z(x) - 15.0
	var g: float = ter.h(x, z)
	for dx in [-2.5, 2.5]:
		for dz in [-2.5, 2.5]:
			g = maxf(g, ter.h(x + dx, z + dz))
	var top := g + 6.4
	var c := Vector3(x, top, z)
	towers.append(c)
	for dx in [-2.2, 2.2]:
		for dz in [-2.2, 2.2]:
			var gy: float = ter.h(x + dx, z + dz)
			k.box(Vector3(x + dx, (gy - 0.5 + top + 2.6) * 0.5, z + dz), Vector3(0.34, top + 2.6 - gy + 0.5, 0.34), "l29_timber")
	# cross bracing on the sides
	for side in 4:
		var a := Vector3(-2.2, 0, -2.2)
		var b := Vector3(2.2, 0, -2.2)
		match side:
			1:
				a = Vector3(2.2, 0, -2.2)
				b = Vector3(2.2, 0, 2.2)
			2:
				a = Vector3(2.2, 0, 2.2)
				b = Vector3(-2.2, 0, 2.2)
			3:
				a = Vector3(-2.2, 0, 2.2)
				b = Vector3(-2.2, 0, -2.2)
		var p0 := c + a + Vector3(0, -top + g + 0.4, 0)
		var p1 := c + b + Vector3(0, -0.3, 0)
		var bas := Basis.looking_at((p1 - p0).normalized(), Vector3.UP)
		k.box_xf(Transform3D(bas, (p0 + p1) * 0.5), Vector3(0.14, 0.14, p0.distance_to(p1)), "l29_timber", GeoKit.ALL, false)
	k.slab(x - 2.6, z - 2.6, x + 2.6, z + 2.6, top, 0.2, "l29_deck_wood")
	# railing with the stair gap on the north (land) side
	bk.rail(Vector3(x - 2.6, top, z + 2.6), Vector3(x + 2.6, top, z + 2.6))
	bk.rail(Vector3(x - 2.6, top, z - 2.6), Vector3(x - 2.6, top, z + 2.6))
	bk.rail(Vector3(x + 2.6, top, z - 2.6), Vector3(x + 2.6, top, z + 2.6))
	bk.rail(Vector3(x - 2.6, top, z - 2.6), Vector3(x - 0.8, top, z - 2.6))
	bk.rail(Vector3(x + 0.8, top, z - 2.6), Vector3(x + 2.6, top, z - 2.6))
	bk.stair_to(Vector3(x, top, z - 2.6), Vector3(0, 0, 1), 1.4, "l29_deck_wood")
	# roof on the posts
	bk.roof(Vector3(x, 0, z), Basis(), 4.6, 4.6, top + 2.6, 1.3, "l29_plank")
	# a lookout hut beside it
	bk.solid(Vector3(x + (8.0 if x < 0 else -8.0), 0, z - 9.0), 90.0 if x < 0 else -90.0, 4.4, 3.6, 1, {"door_x": 0.0})
	bk.prop(props, "ph/Barrel_01", Vector3(x + 2.0, top, z + 1.8), 0.0)
	bk.prop(props, "ph/wooden_crate_01", Vector3(x - 1.6, top, z + 1.9), 20.0)
