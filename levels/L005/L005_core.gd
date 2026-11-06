extends RefCounted
## Level 5 authored anchors. Chunk (0,0) holds The Beverly Room ("The Eternal
## Ballroom": spacious, doors on all sides, one small table with drinks and an
## unfinished Mahjong game under a large chandelier) inside a Main Hall ring, and
## a service stair down to The Boiler Room, which runs south under the hotel and
## grows hotter until the way down to Level 6. Chunk (-1,0) is the lift lobby.

const G := 3.2
const T := 0.1
const HB := 8.0          # ballroom height
const BY := -5.0         # boiler room floor (first hall)

var L: Node3D
var P: RefCounted
var W: RefCounted        # hotel grammar (wall helpers)
var boiler_fixed: Array = []     # [{pos, recipe, params, min, max, caption, vol, dist, t}]
var furnaces: Array = []


func _init(level: Node3D, props: RefCounted, hotel: RefCounted) -> void:
	L = level
	P = props
	W = hotel


# ----------------------------------------------------------- Beverly Room

func ballroom_doors(lay: Dictionary, r: RandomNumberGenerator) -> void:
	var slots := []
	for j in range(1, 7):
		slots.append([Vector2i(0, j), 1])
		slots.append([Vector2i(9, j), 3])
	for i in range(1, 9):
		slots.append([Vector2i(i, 0), 2])
	var ball := []
	for s in slots:
		var c: Vector2i = s[0]
		var d: int = s[1]
		var route := c == Vector2i(0, 3)
		if not route and r.randf() > 0.68:
			continue
		var x := r.randf()
		var st := "unlocked" if (route or x < 0.45) else ("locked" if x < 0.85 else "random")
		var room := {"special": "beverly", "state": st, "open": route, "number": "", "dark": false, "chatter": false}
		lay["doors"]["%d,%d,%d" % [c.x, c.y, d]] = room
		ball.append({"cell": c, "d": d})
	lay["ball_doors"] = ball


func _bwall(k: GeoKit, a: Vector3, b: Vector3, ops: Array) -> void:
	var f := GeoKit.PZ | GeoKit.PX | GeoKit.NX
	var n := (b - a).normalized().cross(Vector3.UP)
	W.wall(k, a, b, 0.0, HB, T, "l5_ball_wall", ops, 0, true)
	W.wall(k, a, b, 0.0, 1.1, T, "l5_ball_dado", ops, f, false)
	W.wall(k, a + n * 0.02, b + n * 0.02, 1.08, 1.15, T, "l5_trim_gold", ops, f | GeoKit.PY | GeoKit.NY, false)
	W.wall(k, a, b, 1.1, 6.9, T, "l5_ball_wall", ops, f, false)
	W.wall(k, a + n * 0.05, b + n * 0.05, 6.9, HB, T, "l5_ball_frieze", ops, f | GeoKit.NY, false)


func ballroom(k: GeoKit, node: Node3D, meta: Dictionary, lay: Dictionary, o: Vector3) -> void:
	var x0 := 3.2
	var x1 := 28.8
	var z0 := 3.2
	var z1 := 22.4
	var west := []
	var north := []
	var east := []
	for bd in lay["ball_doors"]:
		var c: Vector2i = bd["cell"]
		match int(bd["d"]):
			1: west.append({"at": z1 - (c.y * G + G * 0.5), "w": 1.1, "h": 2.32})
			3: east.append({"at": (c.y * G + G * 0.5) - z0, "w": 1.1, "h": 2.32})
			2: north.append({"at": (c.x * G + G * 0.5) - x0, "w": 1.1, "h": 2.32})
	for arr in [west, north, east]:
		arr.sort_custom(func(p, q): return p["at"] < q["at"])
	k.box_mm(Vector3(x0, -0.3, z0), Vector3(x1, 0.0, z1), "l5_parquet_wood", GeoKit.PY)
	k.box_mm(Vector3(x0, HB, z0), Vector3(x1, HB + 0.2, z1), "l5_ball_ceiling", GeoKit.NY, false)
	_bwall(k, Vector3(x0 + T * 0.5, 0, z1), Vector3(x0 + T * 0.5, 0, z0), west)
	_bwall(k, Vector3(x0, 0, z0 + T * 0.5), Vector3(x1, 0, z0 + T * 0.5), north)
	_bwall(k, Vector3(x1 - T * 0.5, 0, z0), Vector3(x1 - T * 0.5, 0, z1), east)
	_bwall(k, Vector3(x1, 0, z1 - T * 0.5), Vector3(x0, 0, z1 - T * 0.5), [{"at": x1 - 24.0, "w": 1.1, "h": 2.32}])
	# door heads on the ballroom side
	for bd in lay["ball_doors"]:
		var c: Vector2i = bd["cell"]
		var d: int = bd["d"]
		var g: Array = W.edge_geo(o, c.x, c.y, d)
		var t: Vector3 = (g[1] - g[0]).normalized()
		var n: Vector3 = -g[2]
		var mid: Vector3 = (g[0] + g[1]) * 0.5 - g[2] * T * 1.5
		_door_head(k, mid, t, n)
	_door_head(k, Vector3(24.0, 0, z1 - T), Vector3(1, 0, 0), Vector3(0, 0, -1))
	# gilded panel mouldings in every bay (raised above the door heads)
	var dbays := {"w": [], "n": [], "e": [], "s": [7]}
	for bd in lay["ball_doors"]:
		var c: Vector2i = bd["cell"]
		match int(bd["d"]):
			1: dbays["w"].append(c.y)
			2: dbays["n"].append(c.x)
			3: dbays["e"].append(c.y)
	for b in range(1, 7):
		_bay(k, Vector3(x0 + T + 0.01, 0, b * G + G * 0.5), Vector3(1, 0, 0), b in dbays["w"])
		_bay(k, Vector3(x1 - T - 0.01, 0, b * G + G * 0.5), Vector3(-1, 0, 0), b in dbays["e"])
	for b in range(1, 9):
		_bay(k, Vector3(b * G + G * 0.5, 0, z0 + T + 0.01), Vector3(0, 0, 1), b in dbays["n"])
		_bay(k, Vector3(b * G + G * 0.5, 0, z1 - T - 0.01), Vector3(0, 0, -1), b in dbays["s"])
	# pilasters with crystal sconces
	for zz in [6.4, 9.6, 12.8, 16.0, 19.2]:
		_pilaster(k, Vector3(x0 + T, 0, zz), Vector3(1, 0, 0), meta)
		_pilaster(k, Vector3(x1 - T, 0, zz), Vector3(-1, 0, 0), meta)
	for xx in [6.4, 9.6, 12.8, 16.0, 19.2, 22.4, 25.6]:
		_pilaster(k, Vector3(xx, 0, z0 + T), Vector3(0, 0, 1), meta)
		_pilaster(k, Vector3(xx, 0, z1 - T), Vector3(0, 0, -1), meta)
	# coffered ceiling
	for xx in [6.4, 9.6, 12.8, 16.0, 19.2, 22.4, 25.6]:
		k.box_mm(Vector3(xx - 0.14, HB - 0.32, z0), Vector3(xx + 0.14, HB, z1), "l5_ball_beam", GeoKit.ALL, false)
	for zz in [6.4, 9.6, 12.8, 16.0, 19.2]:
		k.box_mm(Vector3(x0, HB - 0.3, zz - 0.14), Vector3(x1, HB - 0.02, zz + 0.14), "l5_ball_beam", GeoKit.ALL, false)
	_chandelier(k, node, Vector3(16.0, 0, 12.8))
	_table(k, node, Vector3(16.0, 0, 12.8))
	_odd_doors(k, Vector3(16.0, 0, 12.8))
	_service(k, node, meta)


func _bay(k: GeoKit, c: Vector3, n: Vector3, door: bool) -> void:
	var b := Basis(Vector3.UP.cross(n), Vector3.UP, n)
	var w := 2.2
	var y0 := 3.35 if door else 1.55
	var y1 := 6.45
	for e in [[0.0, y0, w, 0.05], [0.0, y1, w, 0.05], [-w * 0.5, (y0 + y1) * 0.5, 0.05, y1 - y0], [w * 0.5, (y0 + y1) * 0.5, 0.05, y1 - y0]]:
		k.box_xf(Transform3D(b, c + b.x * e[0] + Vector3.UP * e[1] + n * 0.012), Vector3(e[2], e[3], 0.024), "l5_trim_gold", GeoKit.ALL, false)
	if not door:
		for e in [[0.0, 0.25, 2.0, 0.04], [0.0, 0.85, 2.0, 0.04], [-1.0, 0.55, 0.04, 0.64], [1.0, 0.55, 0.04, 0.64]]:
			k.box_xf(Transform3D(b, c + b.x * e[0] + Vector3.UP * e[1] + n * 0.012), Vector3(e[2], e[3], 0.02), "l5_trim_gold", GeoKit.ALL, false)


func _door_head(k: GeoKit, mid: Vector3, t: Vector3, n: Vector3) -> void:
	var b := Basis(t, Vector3.UP, n)
	for sx in [-1.0, 1.0]:
		k.box_xf(Transform3D(b, mid + t * sx * 0.62 + Vector3.UP * 1.2 + n * 0.02), Vector3(0.12, 2.4, 0.04), "l5_trim_gold", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, mid + Vector3.UP * 2.5 + n * 0.04), Vector3(1.5, 0.2, 0.08), "l5_trim_gold", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, mid + Vector3.UP * 2.78 + n * 0.06), Vector3(1.0, 0.36, 0.06), "l5_ball_frieze", GeoKit.ALL, false)


func _pilaster(k: GeoKit, p: Vector3, n: Vector3, meta: Dictionary) -> void:
	var b := Basis(Vector3.UP.cross(n), Vector3.UP, n)
	k.box_xf(Transform3D(b, p + Vector3.UP * 3.5 + n * 0.07), Vector3(0.46, 6.8, 0.14), "l5_ball_pilaster", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, p + Vector3.UP * 0.18 + n * 0.09), Vector3(0.56, 0.36, 0.18), "l5_trim_gold", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, p + Vector3.UP * 6.85 + n * 0.1), Vector3(0.6, 0.3, 0.2), "l5_trim_gold", GeoKit.ALL, false)
	var s := p + Vector3.UP * 3.3 + n * 0.2
	k.box_xf(Transform3D(b, s), Vector3(0.08, 0.3, 0.2), "l5_trim_gold", GeoKit.ALL, false)
	for q in 5:
		var off := Vector3.UP.cross(n) * (q - 2) * 0.06
		k.box_xf(Transform3D(b, s + off + n * 0.1 + Vector3.UP * (0.12 - absf(q - 2) * 0.05)), Vector3(0.025, 0.16, 0.025), "l5_crystal", GeoKit.ALL, false)
	L.lights.add_anchor(s + n * 0.35 + Vector3.UP * 0.2, Color(1.0, 0.8, 0.55), 1.1, 7.0, 0.0, meta["group"])


func _chandelier(k: GeoKit, node: Node3D, c: Vector3) -> void:
	k.cylinder(c + Vector3.UP * 7.35, 0.04, 1.3, "l5_trim_gold", 6, false)
	k.cylinder(c + Vector3.UP * 7.96, 0.9, 0.06, "l5_ball_beam", 16, false)
	k.cylinder(c + Vector3.UP * 6.3, 0.34, 0.9, "l5_trim_gold", 12, false)
	var tiers := [[5.65, 1.75, 26], [6.05, 1.25, 20], [6.42, 0.75, 14]]
	for tr in tiers:
		var y: float = tr[0]
		var rad: float = tr[1]
		var cnt: int = tr[2]
		k.cylinder(c + Vector3.UP * y, rad, 0.05, "l5_trim_gold", 24, false, false)
		for q in cnt:
			var a := TAU * q / cnt
			var p := c + Vector3(cos(a) * rad, y, sin(a) * rad)
			k.box(p + Vector3.DOWN * 0.13, Vector3(0.05, 0.2, 0.05), "l5_crystal", GeoKit.ALL, false)
			if q % 2 == 0:
				k.box(p + Vector3.UP * 0.1, Vector3(0.035, 0.12, 0.035), "l5_candle", GeoKit.ALL, false)
				k.box(p + Vector3.UP * 0.19, Vector3(0.04, 0.06, 0.04), "l5_flame", GeoKit.ALL, false)
		for q in 8:
			var a := TAU * q / 8.0
			P.tube(k, c + Vector3.UP * 6.3, c + Vector3(cos(a) * rad, y, sin(a) * rad), 0.018, "l5_trim_gold", 5)
	for q in 18:
		var a := TAU * q / 18.0 + 0.1
		k.box(c + Vector3(cos(a) * 0.5, 5.55 - (q % 3) * 0.12, sin(a) * 0.5), Vector3(0.05, 0.32, 0.05), "l5_crystal", GeoKit.ALL, false)
	var lt := OmniLight3D.new()
	lt.name = "Chandelier"
	lt.position = c + Vector3.UP * 5.6
	lt.light_color = Color(1.0, 0.8, 0.56)
	lt.light_energy = 3.0
	lt.omni_range = 21.0
	lt.omni_attenuation = 1.2
	lt.shadow_enabled = true
	lt.omni_shadow_mode = OmniLight3D.SHADOW_DUAL_PARABOLOID
	lt.light_specular = 0.4
	node.add_child(lt)
	L.chandelier = lt
	var fill := OmniLight3D.new()
	fill.position = c + Vector3.UP * 3.2
	fill.light_color = Color(1.0, 0.72, 0.45)
	fill.light_energy = 0.8
	fill.omni_range = 10.0
	node.add_child(fill)
	L.chandelier_fill = fill


func _table(k: GeoKit, node: Node3D, c: Vector3) -> void:
	k.cylinder(c + Vector3.UP * 0.025, 0.32, 0.05, "l5_trim_gold", 14, false)
	k.cylinder(c + Vector3.UP * 0.38, 0.06, 0.66, "l5_trim_gold", 8, false)
	k.cylinder(c + Vector3.UP * 0.73, 0.62, 0.04, "l5_wood", 24, true)
	k.cylinder(c + Vector3.UP * 0.756, 0.64, 0.012, "l5_cloth", 24, false)
	k.cylinder(c + Vector3.UP * 0.63, 0.645, 0.25, "l5_cloth", 24, false, false)
	var top := 0.762
	var r := RandomNumberGenerator.new()
	r.seed = 777
	# the unfinished game: four short walls, four hands, scattered discards
	for side in 4:
		var rot := Basis(Vector3.UP, side * PI * 0.5)
		for q in 9:
			if side == 1 and q > 5:
				continue
			for tier in 2:
				if side == 3 and q < 3 and tier == 1:
					continue
				var p: Vector3 = c + rot * Vector3(-0.17 + q * 0.03, top + 0.009 + tier * 0.019, -0.2)
				_tile(k, Transform3D(rot, p), false)
		for q in 13:
			var p: Vector3 = c + rot * Vector3(-0.2 + q * 0.031, top + 0.02, -0.44)
			_tile(k, Transform3D(rot * Basis(Vector3.RIGHT, -PI * 0.5 + 0.18), p), side != 0)
	for q in 22:
		var a := r.randf() * TAU
		var d := r.randf_range(0.02, 0.13)
		var p := c + Vector3(cos(a) * d, top + 0.009, sin(a) * d)
		_tile(k, Transform3D(Basis(Vector3.UP, r.randf() * TAU), p), true)
	for q in 7:
		var a := TAU * (q + 0.5) / 7.0
		var p := c + Vector3(cos(a) * 0.52, top, sin(a) * 0.52)
		k.cylinder(p + Vector3.UP * 0.055, 0.034, 0.11, "glass", 8, false)
		k.cylinder(p + Vector3.UP * 0.035, 0.029, 0.06, "l5_liquor" if q % 3 else "l5_wine", 8, false)
	for q in 2:
		var p := c + Vector3(-0.28 + q * 0.6, top, 0.3 - q * 0.62)
		k.cylinder(p + Vector3.UP * 0.12, 0.042, 0.24, "l5_bottle", 10, false)
		k.cylinder(p + Vector3.UP * 0.29, 0.015, 0.1, "l5_bottle", 8, false)
	var it := Interactable.new()
	node.add_child(it)
	it.setup(c + Vector3.UP * 0.8, Vector3(0.9, 0.18, 0.9), "Finish the game of Mahjong", Callable(L, "mahjong_attempt"))


func _tile(k: GeoKit, xf: Transform3D, face_up: bool) -> void:
	k.box_xf(xf, Vector3(0.026, 0.017, 0.036), "l5_tile_ivory", GeoKit.ALL, false)
	var back := xf.basis.y * (-0.006 if face_up else 0.006)
	k.box_xf(Transform3D(xf.basis, xf.origin + back), Vector3(0.0265, 0.006, 0.0365), "l5_tile_green", GeoKit.ALL, false)
	if face_up:
		k.box_xf(Transform3D(xf.basis, xf.origin + xf.basis.y * 0.0087), Vector3(0.012, 0.0005, 0.02), "l5_tile_mark", GeoKit.ALL, false)


## Doors on the ceiling (and one let into the floor) — reported, uncanny.
func _odd_doors(k: GeoKit, c: Vector3) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = hash([L.level_seed, "ceil"])
	var spots := []
	for xi in 8:
		for zi in 6:
			var p := Vector3(4.8 + xi * G, HB - 0.03, 4.8 + zi * G)
			if Vector2(p.x - c.x, p.z - c.z).length() > 3.6:
				spots.append(p)
	for q in range(spots.size() - 1, 0, -1):
		var w := r.randi() % (q + 1)
		var tmp = spots[q]
		spots[q] = spots[w]
		spots[w] = tmp
	for q in 12:
		var p: Vector3 = spots[q]
		var bas := Basis(Vector3.UP, (r.randi() % 2) * PI * 0.5) * Basis(Vector3.RIGHT, PI * 0.5)
		k.box_xf(Transform3D(bas, p + Vector3.UP * 0.012), Vector3(1.24, 2.42, 0.02), "l5_trim_gold", GeoKit.ALL, false)
		k.box_xf(Transform3D(bas, p - Vector3.UP * 0.02), Vector3(1.0, 2.25, 0.05), "l5_door_white" if r.randf() < 0.6 else "l5_door", GeoKit.ALL, false)
		k.box_xf(Transform3D(bas, p + bas * Vector3(0.38, 0.0, 0.07)), Vector3(0.05, 0.05, 0.06), "l5_trim_gold", GeoKit.ALL, false)
	var fb := Basis(Vector3.UP, 0.4) * Basis(Vector3.RIGHT, -PI * 0.5)
	var fp := Vector3(8.6, 0.004, 18.4)
	k.box_xf(Transform3D(fb, fp), Vector3(1.24, 2.42, 0.006), "l5_trim_gold", GeoKit.ALL, false)
	k.box_xf(Transform3D(fb, fp + Vector3.UP * 0.002), Vector3(1.0, 2.25, 0.006), "l5_door", GeoKit.ALL, false)


# ------------------------------------------------------- service stairwell

func _service(k: GeoKit, node: Node3D, meta: Dictionary) -> void:
	var x0 := 3.2
	var x1 := 28.8
	var z0 := 22.4
	var z1 := 28.8
	var f := GeoKit.PZ | GeoKit.PX | GeoKit.NX
	k.box_mm(Vector3(19.2, -0.3, z0), Vector3(x1, 0.0, z1), "l5_concrete", GeoKit.PY | GeoKit.NX)
	k.box_mm(Vector3(x0, BY - 0.3, z0), Vector3(19.2, BY, z1), "l5_boiler_floor", GeoKit.PY)
	k.box_mm(Vector3(x0, 3.4, z0), Vector3(x1, 3.6, z1), "l5_concrete", GeoKit.NY, false)
	# shaft walls (north has the ballroom door above and the boiler opening below)
	W.wall(k, Vector3(x0, 0, z0 + T * 0.5), Vector3(19.2, 0, z0 + T * 0.5), BY, 0.0, T, "l5_concrete", [{"at": 2.5, "w": 3.0, "h": -2.6}], f | GeoKit.NZ, true)
	W.wall(k, Vector3(x0, 0, z0 + T * 0.5), Vector3(x1, 0, z0 + T * 0.5), 0.0, 3.4, T, "l5_concrete", [{"at": 20.8, "w": 1.1, "h": 2.32}], f, true)
	W.wall(k, Vector3(x1, 0, z1 - T * 0.5), Vector3(x0, 0, z1 - T * 0.5), 0.0, 3.4, T, "l5_concrete", [], f, true)
	W.wall(k, Vector3(19.2, 0, z1 - T * 0.5), Vector3(x0, 0, z1 - T * 0.5), BY, 0.0, T, "l5_concrete", [], f, true)
	W.wall(k, Vector3(x0 + T * 0.5, 0, z1), Vector3(x0 + T * 0.5, 0, z0), BY, 3.4, T, "l5_concrete", [], f, true)
	W.wall(k, Vector3(x1 - T * 0.5, 0, z0), Vector3(x1 - T * 0.5, 0, z1), 0.0, 3.4, T, "l5_concrete", [], f, true)
	k.box_mm(Vector3(19.2, BY, z0), Vector3(19.4, -0.3, z1), "l5_concrete", GeoKit.NX)
	k.stairs(Vector3(10.8, BY, 23.75), Vector3(1, 0, 0), 2.3, 5.0, 28, "l5_concrete", 0.3, true)
	# handrails (sloped along the open side of the flight, then along the landing edge)
	var a := Vector3(10.8, BY + 0.95, 24.95)
	var b := Vector3(19.2, 0.95, 24.95)
	P.tube(k, a, b, 0.03, "l5_rail", 6)
	var sd := (b - a).normalized()
	var up := Vector3(0, 0, 1).cross(sd).normalized()
	k.box_xf(Transform3D(Basis(sd, up, Vector3(0, 0, 1)), (a + b) * 0.5 - up * 0.48), Vector3((b - a).length(), 1.0, 0.06), "l5_rail", 0, true)
	for q in 15:
		var x := 11.0 + q * 0.58
		var y := BY + (x - 10.8) / 8.4 * 5.0
		k.box(Vector3(x, y + 0.47, 24.95), Vector3(0.03, 0.94, 0.03), "l5_rail", GeoKit.ALL, false)
	P.tube(k, Vector3(19.3, 0.95, 24.95), Vector3(19.3, 0.95, z1), 0.03, "l5_rail", 6)
	k.box_mm(Vector3(19.25, 0.0, 24.95), Vector3(19.35, 1.0, z1), "l5_rail", 0, true)
	for q in 6:
		k.box(Vector3(19.3, 0.47, 25.4 + q * 0.6), Vector3(0.03, 0.94, 0.03), "l5_rail", GeoKit.ALL, false)
	# conduit, signage, bare bulbs
	for zz in [27.6, 28.1]:
		P.tube(k, Vector3(x0 + 0.3, BY, zz), Vector3(x0 + 0.3, 3.4, zz), 0.07, "l5_pipe_green", 8)
	P.tube(k, Vector3(x0 + 0.3, 2.9, 27.85), Vector3(x1 - 0.3, 2.9, 27.85), 0.06, "l5_pipe_rust", 8)
	P.label(node, "BOILER ROOM", Vector3(22.0, 2.0, z1 - T), Vector3(0, 0, -1), 0.004, Color(0.85, 0.82, 0.74), 16.0)
	k.box_xf(Transform3D(Basis(), Vector3(24.0, 2.66, z0 + T + 0.01)), Vector3(0.62, 0.11, 0.012), "l5_silver", GeoKit.ALL, false)
	P.label(node, "The Beverly Room", Vector3(24.0, 2.66, z0 + T + 0.02), Vector3(0, 0, 1), 0.0011, Color(0.1, 0.1, 0.11), 14.0)
	for p in [Vector3(24.0, 3.25, 26.0), Vector3(12.0, 0.25, 26.6)]:
		k.cylinder(p, 0.06, 0.12, "l5_bulb", 8, false)
		var lt := SpotLight3D.new()
		lt.position = p + Vector3.DOWN * 0.12
		lt.rotation_degrees = Vector3(-90, 0, 0)
		lt.light_color = Color(1.0, 0.75, 0.48)
		lt.light_energy = 1.6
		lt.spot_range = 9.0
		lt.spot_angle = 68.0
		node.add_child(lt)
	var dr: StaticBody3D = P.make_door(node, Vector3(23.5, 0, z0), Vector3(1, 0, 0), Vector3(0, 0, 1), "white")
	dr.beverly = true
	dr.state = "unlocked"
	dr.swing_to(1.0, true)
	L.register_door(dr)


# ------------------------------------------------------------------ lobby

func lobby(k: GeoKit, node: Node3D, meta: Dictionary, lay: Dictionary, o: Vector3) -> void:
	var n := Vector3(1, 0, 0)
	var wx := o.x + 8 * G + T
	var pz := 5 * G + 0.75
	k.box_xf(Transform3D(Basis(Vector3(0, 0, -1), Vector3.UP, n), Vector3(wx + 0.02, 1.6, pz)), Vector3(0.9, 1.1, 0.04), "l5_wood", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3(0, 0, -1), Vector3.UP, n), Vector3(wx + 0.045, 1.6, pz)), Vector3(0.78, 0.98, 0.01), "l5_notice", GeoKit.ALL, false)
	P.label(node, "HOUSEKEEPING", Vector3(wx + 0.05, 2.0, pz), n, 0.0016, Color(0.15, 0.1, 0.06))
	var it := Interactable.new()
	node.add_child(it)
	it.setup(Vector3(wx + 0.1, 1.6, pz), Vector3(0.2, 1.0, 0.8), "Read")
	it.as_note("l5_lift_notice", "Housekeeping notice (M.E.G. outpost)",
		"Lift advisory for wanderers.\n\nThe cars list floors 1 to 382. Buttons 1 through 12 never take you up or down: the car stays on this floor and opens somewhere else in the hotel.\n\nThirteen and above: some were found dead, the rest were never seen again. Nobody knows what is above twelve. Do not test it.\n\nFor the Boiler Room, take the service door at the back of The Beverly Room. Ask us for the way through.")
	var e := Vector3(-1, 0, 0)
	var ex := o.x + CS_X - T
	P.sofa(k, Vector3(ex, 0, o.z + 1.6), e)
	P.bookshelf(k, Vector3(ex, 0, o.z + 4.8), e, RandomNumberGenerator.new())
	P.cabinet(k, Vector3(ex, 0, o.z + 30.4), e, true)
	meta["speakers"].append(Vector3(ex - 0.3, 1.3, o.z + 30.4))
	for zz in [9.6, 22.4]:
		_pendant(k, Vector3(o.x + 8 * G + G, 3.4, zz), meta)


const CS_X := 32.0


func _pendant(k: GeoKit, p: Vector3, meta: Dictionary) -> void:
	k.cylinder(p + Vector3.DOWN * 0.3, 0.02, 0.6, "l5_trim_gold", 6, false)
	k.cylinder(p + Vector3.DOWN * 0.66, 0.42, 0.12, "l5_trim_gold", 14, false)
	for q in 8:
		var a := TAU * q / 8.0
		var c := p + Vector3(cos(a) * 0.4, -0.55, sin(a) * 0.4)
		k.box(c, Vector3(0.03, 0.1, 0.03), "l5_candle", GeoKit.ALL, false)
		k.box(c + Vector3.UP * 0.08, Vector3(0.035, 0.05, 0.035), "l5_flame", GeoKit.ALL, false)
	L.lights.add_anchor(p + Vector3.DOWN * 0.9, Color(1.0, 0.74, 0.46), 1.3, 7.5, 0.0, meta["group"])


## Door leaves that never open like the others: the dark wooden door (Level 9)
## and the damaged door wanderers from Level 19 stumble through.
func special_door(k: GeoKit, node: Node3D, meta: Dictionary, sp: String, hinge: Vector3, t: Vector3, room_dir: Vector3) -> void:
	var z := t.cross(Vector3.UP)
	var bas := Basis(t, Vector3.UP, z)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var mi := MeshInstance3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(1.0, 2.25, 0.05)
	cs.shape = sh
	cs.position = Vector3(0.5, 1.125, 0)
	body.add_child(cs)
	body.add_child(mi)
	var front := -room_dir
	if sp == "dark":
		mi.mesh = P.door_mesh("dark")
		body.transform = Transform3D(bas, hinge)
		var sz := Vector3(1.2, 2.2, 1.5) if absf(t.x) > 0.5 else Vector3(1.5, 2.2, 1.2)
		L.make_exit("L005>L009#4", "interact", hinge + t * 0.5 + front * 0.75 + Vector3.UP * 1.1, sz, "Open the dark wooden door", node)
		meta["dark_door"] = hinge + t * 0.5
	else:
		mi.mesh = P.door_mesh("std")
		var sw := 1.0 if room_dir.dot(z) < 0.0 else -1.0
		body.transform = Transform3D(bas * Basis(Vector3.UP, sw * 0.5) * Basis(Vector3.BACK, 0.05), hinge + Vector3.UP * 0.03)
		for q in 5:
			var p := hinge + t * (0.25 + q * 0.17) + front * (0.2 + 0.1 * (q % 2)) + Vector3.UP * 0.01
			k.box_xf(Transform3D(Basis(Vector3.UP, q * 0.9), p), Vector3(0.22 - q * 0.02, 0.02, 0.03), "l5_door", GeoKit.ALL, false)
		k.box_xf(Transform3D(bas, hinge + t * 0.5 + Vector3.UP * 1.2 + room_dir * 1.1), Vector3(1.3, 2.4, 0.02), "void_black", GeoKit.ALL, false)
	node.add_child(body)
