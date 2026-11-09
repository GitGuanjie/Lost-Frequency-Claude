extends RefCounted
## Level 20 "the Electric" (SOURCE: black concrete halls, black tiled ceiling,
## grey carpet, neon lighting; the halls are ramps that go down so gently the
## change is unnoticeable; doors lead to games). Built as three sloped runs and
## a dark bend: E1 north (0 -> -1.5 m), E2 east (-1.5 -> -2.9 m), E3 south
## (-2.9 -> -4.4 m), slope 2.6-4.4 % (about 1.5-2.5 degrees). Game rooms are flat
## at the height of their door. Every piece is built in a frame tilted along the
## slope, so the walls stay square to the floor.

const W := 4.0
const HH := 3.2
const T := 0.3
const E1A := Vector3(10, 0, -48.15)
const E1B := Vector3(10, -1.5, -96)
const E2A := Vector3(12, -1.5, -98)
const E2B := Vector3(48, -2.9, -98)
const E3A := Vector3(50, -2.9, -96)
const E3B := Vector3(50, -4.4, -66)
const STUB_Y := -4.4

var L: LevelBase
var props: Node3D
var k: GeoKit
var neon_spots: Array = []       # [{pos, col}]
var rooms: Dictionary = {}       # name -> {floor_y, rect:[x0,z0,x1,z1], door:Vector3, door_yaw}
var doors: Dictionary = {}       # name -> {pivot, body, open, pos}
var _seg_i := 0


func _init(level: LevelBase, props_root: Node3D) -> void:
	L = level
	props = props_root


static func materials() -> void:
	MatLib.define("l20_bconcrete", {"albedo_a": Color(0.055, 0.055, 0.06), "albedo_b": Color(0.035, 0.035, 0.04), "noise_scale": 1.5,
		"stain_amount": 0.2, "stain_color": Color(0.02, 0.02, 0.02), "roughness_a": 0.55, "roughness_b": 0.8, "bump_strength": 0.7}, "concrete")
	MatLib.define("l20_bceiling", {"albedo_a": Color(0.03, 0.03, 0.035), "albedo_b": Color(0.025, 0.025, 0.03), "pattern": 7,
		"pattern_scale": Vector2(0.61, 0.61), "grout_width": 0.012, "grout_color": Color(0.09, 0.09, 0.1), "roughness_a": 0.6,
		"roughness_b": 0.8, "noise_scale": 0.7})
	MatLib.define("l20_gcarpet", {"albedo_a": Color(0.22, 0.22, 0.23), "albedo_b": Color(0.17, 0.17, 0.18), "pattern": 6,
		"pattern_scale": Vector2(0.45, 0.45), "pattern_color": Color(0.28, 0.28, 0.3), "pattern_strength": 0.25, "noise_scale": 0.8,
		"stain_amount": 0.2, "stain_color": Color(0.12, 0.12, 0.12), "roughness_a": 1.0, "roughness_b": 1.0, "bump_strength": 0.6})
	MatLib.define("l20_frost", {"albedo_a": Color(0.62, 0.68, 0.74), "albedo_b": Color(0.48, 0.54, 0.6), "noise_scale": 4.0,
		"roughness_a": 0.3, "roughness_b": 0.6, "bump_strength": 1.2})
	MatLib.define("l20_gamedoor", {"albedo_a": Color(0.08, 0.08, 0.1), "albedo_b": Color(0.06, 0.06, 0.08), "metallic_value": 0.6,
		"roughness_a": 0.3, "roughness_b": 0.45})
	MatLib.define("l20_padwall", {"albedo_a": Color(0.16, 0.17, 0.22), "albedo_b": Color(0.13, 0.14, 0.19), "pattern": 1,
		"pattern_scale": Vector2(1.0, 1.0), "grout_width": 0.02, "grout_color": Color(0.02, 0.02, 0.03), "roughness_a": 0.9,
		"roughness_b": 1.0, "bump_strength": 0.8})
	MatLib.define("l20_foam", {"albedo_a": Color(0.85, 0.25, 0.6), "albedo_b": Color(0.75, 0.2, 0.55), "roughness_a": 0.9, "roughness_b": 1.0})
	for c in [["cyan", Color(0.15, 0.9, 1.0)], ["magenta", Color(1.0, 0.15, 0.75)], ["violet", Color(0.55, 0.25, 1.0)],
			["blue", Color(0.2, 0.35, 1.0)], ["green", Color(0.2, 1.0, 0.35)], ["red", Color(1.0, 0.08, 0.06)],
			["amber", Color(1.0, 0.55, 0.1)], ["dim", Color(0.12, 0.14, 0.2)]]:
		MatLib.register("l20_neon_" + c[0], MatLib.panel(c[1], 3.0 if c[0] != "dim" else 0.4))
	for c in [["off", Color(0.10, 0.12, 0.16), 0.35], ["green", Color(0.15, 1.0, 0.3), 1.5], ["red", Color(1.0, 0.1, 0.06), 1.6],
			["amber", Color(1.0, 0.55, 0.08), 1.6]]:
		MatLib.register("l20_game_" + c[0], MatLib.panel(c[1], c[2]))
	MatLib.register("l20_neon_dead", MatLib.panel(Color(0.2, 0.2, 0.22), 0.05))
	MatLib.register("l20_porthole", MatLib.panel(Color(0.45, 0.2, 0.8), 0.9))


func build() -> void:
	k = L.kit("Electric")
	# entrance threshold: white concrete gives way to black just past the door
	seg(E1A, E1B, [{"s": 10.85, "side": 1, "room": "viridis"}, {"s": 31.85, "side": -1, "room": "lasers"}], ["cyan", "magenta"], 1.0)
	corner(Vector3(10, -1.5, -98), ["magenta"])
	seg(E2A, E2B, [{"s": 12.0, "side": 1, "room": "climb"}, {"s": 26.0, "side": -1, "room": "asteroids"}], ["violet", "cyan"], 0.8)
	corner(Vector3(50, -2.9, -98), ["blue"])
	seg(E3A, E3B, [], ["blue", "dim"], 0.45)
	_bend()
	_cap_walls()
	_rooms()
	k.commit()


## Build one sloped hall run from floor point a to floor point b.
func seg(a: Vector3, b: Vector3, door_list: Array, neon: Array, light_fade: float) -> void:
	var z := (b - a).normalized()
	var x := Vector3.UP.cross(z).normalized()
	var y := z.cross(x).normalized()
	var B := Basis(x, y, z)
	var len := (b - a).length()
	var f := func(u: float, v: float, s: float) -> Transform3D: return Transform3D(B, a + B * Vector3(u, v, s))
	k.box_xf(f.call(0.0, -0.15, len * 0.5), Vector3(W + 0.6, 0.3, len), "l20_gcarpet")
	k.box_xf(f.call(0.0, HH + 0.15, len * 0.5), Vector3(W + 0.6, 0.3, len), "l20_bceiling", GeoKit.NY, true)
	for side in [1, -1]:
		var u: float = side * (W * 0.5 + T * 0.5)
		var ops: Array = []
		for d in door_list:
			if int(d["side"]) == side:
				ops.append(d)
		ops.sort_custom(func(p, q): return float(p["s"]) < float(q["s"]))
		var cur := 0.0
		for d in ops:
			var s0: float = float(d["s"]) - 0.65
			var s1: float = float(d["s"]) + 0.65
			k.box_xf(f.call(u, HH * 0.5, (cur + s0) * 0.5), Vector3(T, HH + 0.6, s0 - cur), "l20_bconcrete")
			k.box_xf(f.call(u, 2.4 + (HH + 0.3 - 2.4) * 0.5, float(d["s"])), Vector3(T, HH + 0.3 - 2.4, 1.3), "l20_bconcrete")
			_door(f.call(u, 0.0, float(d["s"])), side, str(d["room"]), a + B * Vector3(u, 0.0, float(d["s"])))
			cur = s1
		k.box_xf(f.call(u, HH * 0.5, (cur + len) * 0.5), Vector3(T, HH + 0.6, len - cur), "l20_bconcrete")
		# neon: a strip under the ceiling and a low one at the skirting, broken at doors
		var col: String = neon[0] if side == 1 else neon[neon.size() - 1]
		var cur2 := 0.4
		var stops: Array = []
		for d in ops:
			stops.append([float(d["s"]) - 1.0, float(d["s"]) + 1.0])
		stops.append([len - 0.4, len])
		for st in stops:
			if st[0] > cur2 + 0.2:
				var mid: float = (cur2 + st[0]) * 0.5
				var inner: float = side * (W * 0.5 - 0.03)
				k.box_xf(f.call(inner, HH - 0.12, mid), Vector3(0.05, 0.05, st[0] - cur2), "l20_neon_" + col, GeoKit.ALL, false)
				k.box_xf(f.call(inner, 0.12, mid), Vector3(0.04, 0.03, st[0] - cur2), "l20_neon_" + col, GeoKit.ALL, false)
			cur2 = st[1]
	# light anchors along the run (fewer and dimmer as the hall goes down)
	var n := int(len / 7.0)
	for i in n:
		var s := (i + 0.5) * len / n
		var side2 := 1 if i % 2 == 0 else -1
		var c: String = neon[i % neon.size()]
		neon_spots.append({"pos": a + B * Vector3(side2 * 1.2, HH - 0.5, s), "col": c, "e": light_fade})
	# a ceiling seam strip down the centre every other run
	_seg_i += 1
	if _seg_i % 2 == 1:
		k.box_xf(f.call(0.0, HH - 0.01, len * 0.5), Vector3(0.12, 0.02, len - 2.0), "l20_neon_dim", GeoKit.NY, false)


func corner(c: Vector3, neon: Array) -> void:
	k.box_mm(Vector3(c.x - 2.3, c.y - 0.3, c.z - 2.3), Vector3(c.x + 2.3, c.y, c.z + 2.3), "l20_gcarpet")
	k.box_mm(Vector3(c.x - 2.3, c.y + HH, c.z - 2.3), Vector3(c.x + 2.3, c.y + HH + 0.3, c.z + 2.3), "l20_bceiling", GeoKit.NY, true)
	neon_spots.append({"pos": c + Vector3(0, HH - 0.5, 0), "col": neon[0], "e": 0.8})


func _cap_walls() -> void:
	# outer walls of the corners (the runs are open-ended)
	var c1 := Vector3(10, -1.5, -98)
	k.box_mm(Vector3(c1.x - 2.3, c1.y - 0.3, c1.z - 2.3), Vector3(c1.x + 2.3, c1.y + HH + 0.3, c1.z - 2.0), "l20_bconcrete")
	k.box_mm(Vector3(c1.x - 2.3, c1.y - 0.3, c1.z - 2.3), Vector3(c1.x - 2.0, c1.y + HH + 0.3, c1.z + 2.3), "l20_bconcrete")
	k.box_mm(Vector3(c1.x + 2.0, c1.y - 0.3, c1.z + 2.0), Vector3(c1.x + 2.3, c1.y + HH + 0.3, c1.z + 2.3), "l20_bconcrete")
	var c2 := Vector3(50, -2.9, -98)
	k.box_mm(Vector3(c2.x - 2.3, c2.y - 0.3, c2.z - 2.3), Vector3(c2.x + 2.3, c2.y + HH + 0.3, c2.z - 2.0), "l20_bconcrete")
	k.box_mm(Vector3(c2.x + 2.0, c2.y - 0.3, c2.z - 2.3), Vector3(c2.x + 2.3, c2.y + HH + 0.3, c2.z + 2.3), "l20_bconcrete")
	k.box_mm(Vector3(c2.x - 2.3, c2.y - 0.3, c2.z + 2.0), Vector3(c2.x - 2.0, c2.y + HH + 0.3, c2.z + 2.3), "l20_bconcrete")
	# the threshold from the white Waiting halls into the black (a frame of both)
	k.box_mm(Vector3(8.0, 0.0, -48.6), Vector3(12.0, 0.01, -48.15), "l20_carpet", GeoKit.PY, false)


## The far end: E3 bends west into darkness and a frost-locked double door.
func _bend() -> void:
	var y := STUB_Y
	k.box_mm(Vector3(38.0, y - 0.3, -66.3), Vector3(52.3, y, -61.7), "l20_gcarpet")
	k.box_mm(Vector3(38.0, y + HH, -66.3), Vector3(52.3, y + HH + 0.3, -61.7), "l20_bceiling", GeoKit.NY, true)
	k.box_mm(Vector3(38.0, y - 0.3, -62.0), Vector3(52.3, y + HH + 0.3, -61.7), "l20_bconcrete")
	k.box_mm(Vector3(52.0, y - 0.3, -66.3), Vector3(52.3, y + HH + 0.3, -61.7), "l20_bconcrete")
	k.box_mm(Vector3(38.0, y - 0.3, -66.3), Vector3(48.0, y + HH + 0.3, -66.0), "l20_bconcrete")
	k.box_mm(Vector3(37.7, y - 0.3, -66.3), Vector3(38.0, y + HH + 0.3, -61.7), "l20_bconcrete")
	# double door, rimed over
	for zz in [-64.55, -63.45]:
		k.box(Vector3(38.06, y + 1.12, zz), Vector3(0.08, 2.24, 1.08), "l20_gamedoor", GeoKit.ALL, false)
		k.box(Vector3(38.12, y + 0.4, zz), Vector3(0.04, 0.8, 1.08), "l20_frost", GeoKit.ALL, false)
	k.box(Vector3(38.1, y + 2.3, -64.0), Vector3(0.1, 0.14, 2.3), "l20_frost", GeoKit.ALL, false)
	for i in 7:
		k.box(Vector3(38.6 + i * 0.9, y + 0.02, -64.0 + sin(i * 1.7) * 0.9), Vector3(0.8 - i * 0.08, 0.04, 0.6), "l20_frost", GeoKit.PY, false)
	# the last neon on the run is dead; a faint strip remains at the bend
	k.box(Vector3(49.0, y + HH - 0.12, -62.07), Vector3(5.0, 0.05, 0.05), "l20_neon_dead", GeoKit.ALL, false)
	neon_spots.append({"pos": Vector3(44.0, y + 2.6, -64.0), "col": "dim", "e": 0.35})


func _door(xf: Transform3D, side: int, room: String, world_pos: Vector3) -> void:
	# hinged door in the opening; the leaf swings into the room
	var pivot := Node3D.new()
	var hinge := xf * Transform3D(Basis(), Vector3(0, 0, -0.6))
	pivot.transform = Transform3D(Basis(Vector3.UP, hinge.basis.get_euler().y), hinge.origin)
	props.add_child(pivot)
	var leaf := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.06, 2.3, 1.2)
	leaf.mesh = bm
	leaf.position = Vector3(0, 1.15, 0.6)
	leaf.material_override = MatLib.get_mat("l20_gamedoor")
	pivot.add_child(leaf)
	var port := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.07, 0.36, 0.36)
	port.mesh = pm
	port.position = Vector3(0, 1.55, 0.6)
	port.material_override = MatLib.get_mat("l20_porthole")
	pivot.add_child(port)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.08, 2.3, 1.2)
	cs.shape = sh
	cs.position = Vector3(0, 1.15, 0.6)
	body.add_child(cs)
	pivot.add_child(body)
	doors[room] = {"pivot": pivot, "body": body, "open": false, "pos": world_pos, "side": side,
		"base_yaw": pivot.rotation.y, "hall_normal": (xf.basis.x * -side).normalized()}


func _rooms() -> void:
	# floors/ceilings/walls for the four game rooms; the hall wall closes the fourth
	# side (each rect ends at the hall wall's outer face).
	_room("viridis", -4.0, -65.0, 7.7, -53.0, float(doors["viridis"]["pos"].y), 3.6, "x+")
	_room("lasers", 12.3, -87.0, 26.0, -73.0, float(doors["lasers"]["pos"].y), 3.6, "x-")
	_room("climb", 17.0, -116.0, 31.0, -100.3, float(doors["climb"]["pos"].y), 10.0, "z+")
	_room("asteroids", 31.0, -95.7, 45.0, -82.0, float(doors["asteroids"]["pos"].y), 4.2, "z-")


func _room(name: String, x0: float, z0: float, x1: float, z1: float, y: float, h: float, hall_side: String) -> void:
	var mn := Vector3(x0, y, z0)
	var mx := Vector3(x1, y + h, z1)
	var e := {"x-": 0.3, "x+": 0.3, "z-": 0.3, "z+": 0.3}
	e[hall_side] = 0.0
	var a := Vector3(mn.x - e["x-"], 0, mn.z - e["z-"])
	var b := Vector3(mx.x + e["x+"], 0, mx.z + e["z+"])
	var wall_mat := "l20_padwall" if name == "climb" else "l20_bconcrete"
	k.box_mm(Vector3(a.x, y - 0.3, a.z), Vector3(b.x, y, b.z), "l20_padwall" if name == "climb" else "l20_gcarpet")
	k.box_mm(Vector3(a.x, y + h, a.z), Vector3(b.x, y + h + 0.3, b.z), "l20_bceiling", GeoKit.NY, true)
	var walls := {"x-": [Vector3(a.x, y - 0.3, a.z), Vector3(mn.x, y + h, b.z)],
		"x+": [Vector3(mx.x, y - 0.3, a.z), Vector3(b.x, y + h, b.z)],
		"z-": [Vector3(a.x, y - 0.3, a.z), Vector3(b.x, y + h, mn.z)],
		"z+": [Vector3(a.x, y - 0.3, mx.z), Vector3(b.x, y + h, b.z)]}
	for key in walls.keys():
		if key == hall_side:
			continue
		var w2: Array = walls[key]
		k.box_mm(w2[0], w2[1], wall_mat)
	# soffit above the hall wall, inside the room, so no gap shows over the sloped wall
	var lo := y + HH - 0.3
	match hall_side:
		"x+": k.box_mm(Vector3(mx.x - 0.3, lo, a.z), Vector3(mx.x, y + h, b.z), wall_mat)
		"x-": k.box_mm(Vector3(mn.x, lo, a.z), Vector3(mn.x + 0.3, y + h, b.z), wall_mat)
		"z+": k.box_mm(Vector3(a.x, lo, mx.z - 0.3), Vector3(b.x, y + h, mx.z), wall_mat)
		"z-": k.box_mm(Vector3(a.x, lo, mn.z), Vector3(b.x, y + h, mn.z + 0.3), wall_mat)
	rooms[name] = {"floor_y": y, "min": mn, "max": mx, "door": doors[name]["pos"]}
