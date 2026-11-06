extends RefCounted
## Level 906 crossing: the authored heart of the library where the four halls
## meet (page: Blanche's office is "a small area in the center of the level",
## the Tea Room "a small kitchen area in the middle of the library").
## Plan (ADAPTATION): a 38 m square crossing with a 4.5 m gallery ring carried
## over the mouths of the four halls, chamfered corner blocks (the tea room in the
## south-east one, the door Blanche opens for departing guests in the north-west
## one), guest rooms in the four corners of the gallery level, a marble stair
## (after the staircase sketch credited on the page) climbing to the north
## gallery, and the office pavilion in the middle under the great candelabra.

const K := preload("res://levels/L906/L906_kit.gd")
const R := 19.0          # crossing half-size (arms start here)
const MOUTH := 11.2      # half-width of a hall (outer walls)
const ROOM := 13.8       # guest rooms occupy |x|,|z| in [ROOM, R] on the gallery
const CH := 2.4          # chamfer leg on the corner blocks
const LIGHT := Color(1.0, 0.71, 0.4)

var L: Node3D
var door_pivot: Node3D
var door_glow: StandardMaterial3D
var door_node: Node3D
var spots: Array = []


func _init(level: Node3D) -> void:
	L = level


func build() -> void:
	var k: GeoKit = L.kit("Crossing")
	k.slab(-R - 0.3, -R - 0.3, R + 0.3, R + 0.3, 0.0, 0.3, "wood_floor", GeoKit.PY)
	_runners(k)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_corner(k, sx, sz)
	_band(k)
	_stair(k)
	# great candelabra over the crossing and four over the gallery bridges
	var lp := K.candelabra(k, Vector3(0, 13.2, 1.5), 2.3, 20, 3)
	L.lights.add_anchor(lp, LIGHT, 5.5, 28.0)
	for d: Vector3 in [Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0)]:
		var p := K.candelabra(k, d * 15.1 + Vector3.UP * 9.6, 1.0, 10, 2)
		L.lights.add_anchor(p, LIGHT, 2.6, 17.0)
	# paintings on the NE and SW chamfers (page: "painted landscapes" on the ceiling;
	# framed landscapes below are ADAPTATION)
	for c in [[1.0, -1.0, "l906_painting"], [-1.0, 1.0, "l906_painting2"]]:
		var sx: float = c[0]
		var sz: float = c[1]
		var n := Vector3(-sx, 0, -sz).normalized()
		K.painting(k, Vector3(sx, 0, sz) * (MOUTH + CH * 0.5) + Vector3.UP * 2.3 + n * 0.16, n, 2.0, 1.4, c[2])
		K.candlestick(k, Vector3(sx, 0, sz) * (MOUTH + CH * 0.5) + n * 0.6, 3, 1.2)
	k.commit()
	_guide_door()


func _runners(k: GeoKit) -> void:
	for seg in [[Vector3(-2.2, 0, -R), Vector3(2.2, 0.012, -2.6)], [Vector3(-2.2, 0, 10.2), Vector3(2.2, 0.012, R)],
			[Vector3(-R, 0, -2.2), Vector3(-2.2, 0.012, 2.2)], [Vector3(2.2, 0, -2.2), Vector3(R, 0.012, 2.2)],
			[Vector3(-2.2, 0, -2.6), Vector3(2.2, 0.012, 2.2)]]:
		var a: Vector3 = seg[0]
		var b: Vector3 = seg[1]
		k.box_mm(a, b, "l906_carpet", GeoKit.PY, false)
		var along_z := (b.z - a.z) > (b.x - a.x)
		if along_z:
			k.box_mm(Vector3(a.x - 0.12, 0, a.z), Vector3(a.x, 0.014, b.z), "l906_carpet_edge", GeoKit.PY, false)
			k.box_mm(Vector3(b.x, 0, a.z), Vector3(b.x + 0.12, 0.014, b.z), "l906_carpet_edge", GeoKit.PY, false)
		else:
			k.box_mm(Vector3(a.x, 0, a.z - 0.12), Vector3(b.x, 0.014, a.z), "l906_carpet_edge", GeoKit.PY, false)
			k.box_mm(Vector3(a.x, 0, b.z), Vector3(b.x, 0.014, b.z + 0.12), "l906_carpet_edge", GeoKit.PY, false)


## Corner block: bookcases on the faces towards the hall mouths, a chamfer facing
## the centre, the corner tower rising into the dark above the guest room.
func _corner(k: GeoKit, sx: float, sz: float) -> void:
	var t := 0.3
	var h := K.GAL - 0.3
	# walls on the faces (thick panel; bookcases in front of them)
	k.box_mm(Vector3(minf(sx * MOUTH, sx * (MOUTH + t)), 0, minf(sz * (MOUTH + CH), sz * R)), Vector3(maxf(sx * MOUTH, sx * (MOUTH + t)), h, maxf(sz * (MOUTH + CH), sz * R)), "l906_panel")
	k.box_mm(Vector3(minf(sx * (MOUTH + CH), sx * R), 0, minf(sz * MOUTH, sz * (MOUTH + t))), Vector3(maxf(sx * (MOUTH + CH), sx * R), h, maxf(sz * MOUTH, sz * (MOUTH + t))), "l906_panel")
	if true:
		K.shelves(k, Vector3(sx * (MOUTH - 0.23), 0, sz * (MOUTH + CH + 0.1)), Vector3(sx * (MOUTH - 0.23), 0, sz * (R - 0.1)), 0.45, 11, Vector3(-sx, 0, 0))
		K.shelves(k, Vector3(sx * (MOUTH + CH + 0.1), 0, sz * (MOUTH - 0.23)), Vector3(sx * (R - 0.1), 0, sz * (MOUTH - 0.23)), 0.45, 11, Vector3(0, 0, -sz))
	# chamfer (tea room and guide door get their own openings)
	var a := Vector3(sx * MOUTH, 0, sz * (MOUTH + CH))
	var b := Vector3(sx * (MOUTH + CH), 0, sz * MOUTH)
	if sx > 0 and sz > 0:
		k.wall(a, b, h, t, "l906_panel", [{"at": a.distance_to(b) * 0.5, "w": 1.3, "h": 2.5}])
	elif not (sx < 0 and sz < 0):
		k.wall(a, b, h, t, "l906_panel")
	# guest room on the gallery level, tower above
	var g := K.GAL
	var ry := 8.4
	k.slab(sx * MOUTH, sz * MOUTH, sx * (R + 0.3), sz * (R + 0.3), ry + 0.3, 0.3, "l906_panel")
	k.box_mm(Vector3(minf(sx * MOUTH, sx * (R + 0.3)), ry + 0.3, minf(sz * MOUTH, sz * (R + 0.3))), Vector3(maxf(sx * MOUTH, sx * (R + 0.3)), K.CHAIN_TOP, maxf(sz * MOUTH, sz * (R + 0.3))), "l906_panel", GeoKit.ALL ^ GeoKit.PY ^ GeoKit.NY)
	k.box(Vector3(sx * (MOUTH + 0.02), ry + 0.42, sz * (MOUTH + 3.9)), Vector3(0.06, 0.06, 7.8), "l906_gilt", GeoKit.ALL, false)
	k.box(Vector3(sx * (MOUTH + 3.9), ry + 0.42, sz * (MOUTH + 0.02)), Vector3(7.8, 0.06, 0.06), "l906_gilt", GeoKit.ALL, false)
	var dz := sz * ROOM
	var door_at := absf(R - ROOM) * 0.5
	# the face along x (z = sz*ROOM) holds the door; the face along z is a bookcase wall
	k.wall(Vector3(sx * ROOM, g, dz), Vector3(sx * R, g, dz), ry - g, 0.2, "l906_panel", [{"at": door_at, "w": 1.05, "h": 2.2}])
	k.wall(Vector3(sx * ROOM, g, dz), Vector3(sx * ROOM, g, sz * R), ry - g, 0.2, "l906_panel")
	k.wall(Vector3(sx * R, g, sz * ROOM), Vector3(sx * R, g, sz * R), ry - g, 0.2, "l906_panel")
	k.wall(Vector3(sx * ROOM, g, sz * R), Vector3(sx * R, g, sz * R), ry - g, 0.2, "l906_panel")
	K.shelves(k, Vector3(sx * (ROOM - 0.33), g, sz * (ROOM + 0.2)), Vector3(sx * (ROOM - 0.33), g, sz * (R - 0.2)), 0.45, 10, Vector3(-sx, 0, 0))
	var dc := Vector3(sx * (ROOM + door_at), g, dz)
	k.box(dc + Vector3(0, 2.32, -sz * 0.12), Vector3(1.4, 0.16, 0.06), "l906_gilt", GeoKit.ALL, false)
	if not (sx > 0 and sz > 0):
		# closed door leaf: Tom's room (SW) or an empty guest room
		k.box(dc + Vector3(0, 1.1, 0), Vector3(1.04, 2.2, 0.06), "l906_wood")
		k.box(dc + Vector3(sx * -0.38, 1.05, -sz * 0.05), Vector3(0.06, 0.06, 0.06), "l906_brass", GeoKit.ALL, false)
		var tom := sx < 0 and sz > 0
		if tom:
			k.box(dc + Vector3(0, 0.012, -sz * 0.06), Vector3(0.9, 0.016, 0.03), "l906_flame", GeoKit.ALL, false)
		L.add_interactable(dc + Vector3(0, 1.1, -sz * 0.15), Vector3(1.0, 2.0, 0.3), "Knock" if tom else "Try the door",
			func(_p): L.hosts.door_knock(tom))
	# the gallery walkway carpet
	spots.append(Vector3(sx * 12.4, g + 0.01, sz * 12.4))


func _band(k: GeoKit) -> void:
	var g := K.GAL
	var bands := [[-R, -R, R, -MOUTH], [-R, MOUTH, R, R], [MOUTH, -MOUTH, R, MOUTH], [-R, -MOUTH, -MOUTH, MOUTH]]
	for b in bands:
		k.slab(b[0], b[1], b[2], b[3], g, 0.3, "l906_wood")
		k.box_mm(Vector3(b[0], g, b[1]), Vector3(b[2], g + 0.004, b[3]), "wood_floor", GeoKit.PY, false)
	# walkway runners (inner ring)
	for s: float in [-1.0, 1.0]:
		k.box_mm(Vector3(-ROOM + 0.4, g, minf(s * 11.6, s * 13.0)), Vector3(ROOM - 0.4, g + 0.012, maxf(s * 11.6, s * 13.0)), "l906_carpet", GeoKit.PY, false)
		k.box_mm(Vector3(minf(s * 11.6, s * 13.0), g, -ROOM + 0.4), Vector3(maxf(s * 11.6, s * 13.0), g + 0.012, ROOM - 0.4), "l906_carpet", GeoKit.PY, false)
		# inner rail (stair gap on the north side) and the fascia
		if s < 0:
			K.rail(k, Vector3(-MOUTH, g, -MOUTH - 0.05), Vector3(-1.9, g, -MOUTH - 0.05))
			K.rail(k, Vector3(1.9, g, -MOUTH - 0.05), Vector3(MOUTH, g, -MOUTH - 0.05))
		else:
			K.rail(k, Vector3(-MOUTH, g, MOUTH + 0.05), Vector3(MOUTH, g, MOUTH + 0.05))
		K.rail(k, Vector3(s * (MOUTH + 0.05), g, -MOUTH), Vector3(s * (MOUTH + 0.05), g, MOUTH))
		# outer rails where the gallery looks down a hall's nave
		K.rail(k, Vector3(-7.05, g, s * (R - 0.05)), Vector3(7.05, g, s * (R - 0.05)))
		K.rail(k, Vector3(s * (R - 0.05), g, -7.05), Vector3(s * (R - 0.05), g, 7.05))
		k.box(Vector3(0, g - 0.22, s * (MOUTH - 0.01)), Vector3(2 * MOUTH, 0.08, 0.03), "l906_gilt", GeoKit.ALL, false)
		k.box(Vector3(s * (MOUTH - 0.01), g - 0.22, 0), Vector3(0.03, 0.08, 2 * MOUTH), "l906_gilt", GeoKit.ALL, false)
		# columns under the bridges
		for x: float in [-8.6, -4.6, 4.6, 8.6]:
			K.column(k, Vector3(x, 0, s * (MOUTH + 0.25)), g - 0.3, 0.22)
			K.column(k, Vector3(s * (MOUTH + 0.25), 0, x), g - 0.3, 0.22)
		for x: float in [-7.25, 7.25]:
			K.column(k, Vector3(x, 0, s * (R - 0.3)), g - 0.3, 0.19)
			K.column(k, Vector3(s * (R - 0.3), 0, x), g - 0.3, 0.19)
	# a guest's writing table on the west bridge (the rumour note sits here)
	K.table(k, Vector3(-16.6, g, 5.2), 1.2, 0.7)
	K.chair(k, Vector3(-16.6, g, 4.45), Vector3(0, 0, 1))
	K.candlestick(k, Vector3(-16.2, g + 0.76, 5.35), 1, 0.18)
	L.add_note("l906_rumour", "A guest's note", "On the library's own notepaper, in a hurried hand: \"They say if you stay here too long you start Witnessing the Beyond: memory goes, then your name, then the rest. I have asked everyone. Nobody has met anyone it happened to. Nobody has a report. Somebody at the U.E.C. probably made it up, and they never stop repeating it.\" Underneath, in a neater hand: \"More tea?\"", Vector3(-16.75, g + 0.8, 5.25))
	spots.append_array([Vector3(-16.9, g + 0.77, 5.2), Vector3(12.4, g + 0.01, 3.0), Vector3(-3.0, g + 0.01, -12.4)])


## Marble stair from the crossing floor to the north gallery (two flights).
func _stair(k: GeoKit) -> void:
	var w := 3.6
	k.stairs(Vector3(0, 0, -2.6), Vector3(0, 0, -1), w, 2.25, 12, "l906_marble", 0.3)
	k.box_mm(Vector3(-w * 0.5, 0, -7.4), Vector3(w * 0.5, 2.25, -6.2), "l906_marble")
	k.box_mm(Vector3(-w * 0.5, 0, -MOUTH), Vector3(w * 0.5, 2.24, -7.4), "l906_marble")
	k.stairs(Vector3(0, 2.25, -7.4), Vector3(0, 0, -1), w, 2.25, 13, "l906_marble", 0.293)
	k.box_mm(Vector3(-1.4, 0.0, -7.4), Vector3(1.4, 2.262, -6.2), "l906_carpet", GeoKit.PY, false)
	# balustrades: sloped marble rails on both sides, newel posts with candles
	for s: float in [-1.0, 1.0]:
		for f in [[Vector3(s * 1.9, 0.95, -2.6), Vector3(s * 1.9, 3.2, -6.2)], [Vector3(s * 1.9, 3.2, -7.4), Vector3(s * 1.9, K.GAL + 0.95, -MOUTH)]]:
			var a: Vector3 = f[0]
			var b: Vector3 = f[1]
			var z := (b - a).normalized()
			k.box_xf(Transform3D(Basis(Vector3.RIGHT, z.cross(Vector3.RIGHT), z), (a + b) * 0.5), Vector3(0.22, 0.14, a.distance_to(b) + 0.2), "l906_marble", GeoKit.ALL, false)
			var base := a - Vector3(0, 0.95, 0)
			var top := b - Vector3(0, 0.95, 0)
			k.box_xf(Transform3D(Basis(Vector3.RIGHT, z.cross(Vector3.RIGHT), z), (base + top) * 0.5 + Vector3.UP * 0.12), Vector3(0.3, 0.26, a.distance_to(b)), "l906_marble", GeoKit.ALL, false)
			for t in 11:
				var p := a.lerp(b, (t + 0.5) / 11.0)
				k.cylinder(Vector3(p.x, p.y - 0.45, p.z), 0.06, 0.78, "l906_marble", 8, false)
			k.add_box_shape(Transform3D(Basis(Vector3.RIGHT, z.cross(Vector3.RIGHT), z), (a + b) * 0.5 + Vector3.DOWN * 0.4), Vector3(0.22, 1.2, a.distance_to(b)), "tile")
		k.box(Vector3(s * 1.9, 3.2 - 0.4, -6.8), Vector3(0.24, 1.3, 1.4), "l906_marble")
		k.box(Vector3(s * 1.9, 0.62, -2.45), Vector3(0.5, 1.24, 0.5), "l906_marble")
		k.box(Vector3(s * 1.9, 1.29, -2.45), Vector3(0.6, 0.1, 0.6), "l906_gilt", GeoKit.ALL, false)
		K.candlestick(k, Vector3(s * 1.9, 1.34, -2.45), 5, 0.55)
		L.lights.add_anchor(Vector3(s * 1.9, 2.1, -2.45), LIGHT, 0.9, 6.0)
	spots.append(Vector3(0.9, 2.26, -6.8))


## The door Blanche opens for a departing guest (NW chamfer). Closed until she
## guides you to it; beyond it a short passage ends in the light of the level you
## asked for.
func _guide_door() -> void:
	var c := Vector3(-1, 0, -1) * (MOUTH + CH * 0.5)
	door_node = Node3D.new()
	door_node.name = "GuideDoor"
	L.add_child(door_node)
	var n := Vector3(1, 0, 1).normalized()
	door_node.transform = Transform3D(Basis(n.cross(Vector3.UP) * -1.0, Vector3.UP, n), c)
	var k := GeoKit.new(door_node, "Door")
	var half := CH * 0.5 * sqrt(2.0) + 0.1
	k.wall(Vector3(-half, 0, 0), Vector3(half, 0, 0), K.GAL - 0.3, 0.3, "l906_panel", [{"at": half, "w": 1.3, "h": 2.6}])
	k.box(Vector3(0, 2.75, 0.17), Vector3(1.7, 0.16, 0.05), "l906_gilt", GeoKit.ALL, false)
	for s: float in [-1.0, 1.0]:
		k.box(Vector3(s * 0.75, 1.3, 0.17), Vector3(0.12, 2.6, 0.06), "l906_gilt", GeoKit.ALL, false)
		k.box_mm(Vector3(s * 0.86 - 0.06, 0, -3.4), Vector3(s * 0.86 + 0.06, 2.6, -0.15), "l906_panel")
	k.box_mm(Vector3(-0.92, 2.6, -3.4), Vector3(0.92, 2.7, -0.15), "l906_panel")
	k.box_mm(Vector3(-0.6, 0, -3.4), Vector3(0.6, 0.012, -0.15), "l906_carpet", GeoKit.PY, false)
	k.commit()
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(1.7, 2.6)
	q.mesh = qm
	q.position = Vector3(0, 1.3, -3.3)
	door_glow = StandardMaterial3D.new()
	door_glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	door_glow.albedo_color = Color(0.02, 0.02, 0.02)
	q.material_override = door_glow
	door_node.add_child(q)
	door_pivot = Node3D.new()
	door_pivot.position = Vector3(-0.64, 0, -0.05)
	door_node.add_child(door_pivot)
	var dk := GeoKit.new(door_pivot, "Leaf")
	dk.box(Vector3(0.64, 1.3, 0), Vector3(1.26, 2.58, 0.07), "l906_wood")
	dk.box(Vector3(0.64, 1.95, 0.04), Vector3(0.9, 0.9, 0.01), "l906_panel", GeoKit.PZ, false)
	dk.box(Vector3(0.64, 0.75, 0.04), Vector3(0.9, 0.9, 0.01), "l906_panel", GeoKit.PZ, false)
	dk.commit()
	L.add_interactable(c + n * 0.25 + Vector3.UP * 1.3, Vector3(1.2, 2.4, 0.3), "Examine the tall door", func(_p): L.hosts.door_examined())


## Open or close the guide door; colour is the light of the destination.
func set_door(open: bool, glow := Color(0, 0, 0)) -> void:
	door_pivot.rotation.y = deg_to_rad(95.0) if open else 0.0
	door_glow.albedo_color = glow if open else Color(0.02, 0.02, 0.02)
