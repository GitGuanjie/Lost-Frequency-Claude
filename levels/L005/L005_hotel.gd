extends RefCounted
## Level 5 "The Main Hall" grammar: a hotel floor plan, not a maze. Seeded 32 m
## chunks of 3.2 m cells. Corridors are carved from each border entry to a hub
## with L/Z elbows; guest rooms (1x1 / 1x2 cells, numbered doors) line every
## corridor; galleries open into lounges; lift chunks carry a fixed elevator
## bank so the "floors 1-12" relocation lands in an identical car elsewhere.
## Each chunk draws only its own half-thickness wall faces (streaming-safe).

const G := 3.2
const N := 10
const CS := 32.0
const H := 3.4
const T := 0.1
const MASS := 0
const COR := 1
const CAR := 2
const BALL := 3
const SERV := 4
const DIRS := [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const FLOORS := {"hall": "l5_carpet", "dark": "l5_carpet", "walnut": "l5_walnut", "gallery": "l5_marble",
	"elevator": "l5_marble", "lobby": "l5_marble", "ballroom": "l5_carpet"}
const LIFT_ROWS := [2, 3, 6, 7]

var L: Node3D
var P: RefCounted       # L005_props
var seed_v := 0
var lift_keys: Array = []   # index f-1 -> chunk key for elevator floor f (1..12)
var _cur_kind := ""
var _cur_key := Vector2i.ZERO


func _init(level: Node3D, props: RefCounted) -> void:
	L = level
	P = props
	seed_v = level.level_seed
	lift_keys = [Vector2i(-1, 0)]
	var r := RandomNumberGenerator.new()
	r.seed = hash([seed_v, "lifts"])
	var guard := 0
	while lift_keys.size() < 12 and guard < 2000:
		guard += 1
		var k := Vector2i(r.randi_range(-7, 7), r.randi_range(-7, 7))
		if maxi(absi(k.x), absi(k.y)) < 3:
			continue
		var ok := true
		for o in lift_keys:
			if maxi(absi(o.x - k.x), absi(o.y - k.y)) < 2:
				ok = false
		if ok:
			lift_keys.append(k)


func h01(a: int, b: int, salt: int) -> float:
	return float(absi(hash([seed_v, a, b, salt])) % 100003) / 100003.0


func kind_of(cx: int, cz: int) -> String:
	if cx == 0 and cz == 0:
		return "ballroom"
	if cx == -1 and cz == 0:
		return "lobby"
	if lift_keys.has(Vector2i(cx, cz)):
		return "elevator"
	var h := h01(cx, cz, 3)
	if maxi(absi(cx), absi(cz)) >= 2 and h < 0.07:
		return "dark"
	if h < 0.2:
		return "gallery"
	if h < 0.48:
		return "walnut"
	return "hall"


## Corridor crossings on the border between (ax,az) and its +x / +z neighbour.
func entries(ax: int, az: int, axis: String) -> Array:
	var bx := ax + (1 if axis == "x" else 0)
	var bz := az + (1 if axis == "z" else 0)
	var ka := kind_of(ax, az)
	var kb := kind_of(bx, bz)
	if axis == "x" and ka == "lobby" and kb == "ballroom":
		return [2, 3, 4, 5, 6, 7]
	if ka == "ballroom" or kb == "ballroom":
		return [2, 7]
	var la := ka in ["elevator", "lobby"]
	var lb := kb in ["elevator", "lobby"]
	if axis == "z" and (la or lb):
		return [8]
	var r := RandomNumberGenerator.new()
	r.seed = hash([seed_v, "b", axis, ax, az])
	if axis == "x" and lb:
		return [4] if kb == "lobby" else [[0, 1, 4, 5, 8, 9][r.randi() % 6]]
	if r.randf() < 0.1 and not la:
		return []
	var out := [2 + r.randi() % 6]
	if r.randf() < 0.3:
		var e2 := 1 + r.randi() % 8
		if absi(e2 - int(out[0])) >= 3:
			out.append(e2)
	return out


func _in(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < N and c.y < N


func _line(cells: PackedInt32Array, a: Vector2i, b: Vector2i) -> void:
	var c := a
	var step := Vector2i(signi(b.x - a.x), signi(b.y - a.y))
	while true:
		if cells[c.y * N + c.x] != CAR:
			cells[c.y * N + c.x] = COR
		if c == b:
			break
		c += step


func layout(cx: int, cz: int) -> Dictionary:
	var kind := kind_of(cx, cz)
	var r := RandomNumberGenerator.new()
	r.seed = hash([seed_v, "lay", cx, cz])
	var cells := PackedInt32Array()
	cells.resize(N * N)
	var E := {0: entries(cx, cz - 1, "z"), 1: entries(cx, cz, "x"), 2: entries(cx, cz, "z"), 3: entries(cx - 1, cz, "x")}
	var lay := {"kind": kind, "cells": cells, "E": E, "rooms": [], "doors": {}, "key": Vector2i(cx, cz)}
	if kind == "ballroom":
		for j in N:
			for i in N:
				var ring := i == 0 or j == 0 or i == N - 1 or j == N - 1
				cells[j * N + i] = COR if ring else (BALL if j <= 6 else SERV)
		L.core.ballroom_doors(lay, r)
		return lay
	var hub := Vector2i(2 + r.randi() % 6, 2 + r.randi() % 6)
	var lift := kind in ["elevator", "lobby"]
	if lift:
		hub = Vector2i(8, 5)
		for j in N:
			cells[j * N + 8] = COR
			cells[j * N + 9] = COR
		for j in LIFT_ROWS:
			cells[j * N + 7] = CAR
	for d in 4:
		for e in E[d]:
			var s := [Vector2i(e, 0), Vector2i(N - 1, e), Vector2i(e, N - 1), Vector2i(0, e)][d] as Vector2i
			var pts := [s]
			if d == 1 or d == 3:
				var xm := hub.x if lift else r.randi_range(mini(s.x, hub.x), maxi(s.x, hub.x))
				pts.append_array([Vector2i(xm, s.y), Vector2i(xm, hub.y), hub])
			else:
				var zm := r.randi_range(mini(s.y, hub.y), maxi(s.y, hub.y))
				pts.append_array([Vector2i(s.x, zm), Vector2i(hub.x, zm), hub])
			for q in pts.size() - 1:
				_line(cells, pts[q], pts[q + 1])
	if kind == "gallery":
		for j in range(hub.y - 1, hub.y + 2):
			for i in range(hub.x - 1, hub.x + 2):
				if _in(Vector2i(i, j)):
					cells[j * N + i] = COR
	var reserved := {}
	if kind == "lobby":
		_room(lay, [Vector2i(7, 1), Vector2i(6, 1)], Vector2i(8, 1), 3, r, "damaged")
		_room(lay, [Vector2i(7, 8), Vector2i(6, 8)], Vector2i(8, 8), 3, r, "dark")
		reserved[Vector2i(7, 5)] = true
		reserved[Vector2i(7, 4)] = true
	var order := []
	for j in N:
		for i in N:
			if cells[j * N + i] == COR:
				order.append(Vector2i(i, j))
	for c in order:
		var ds := [0, 1, 2, 3]
		for q in range(3, 0, -1):
			var w := r.randi() % (q + 1)
			var tmp = ds[q]
			ds[q] = ds[w]
			ds[w] = tmp
		for d in ds:
			var c1: Vector2i = c + DIRS[d]
			if not _in(c1) or cells[c1.y * N + c1.x] != MASS or reserved.has(c1) or r.randf() > 0.82:
				continue
			var cl := [c1]
			var c2: Vector2i = c1 + DIRS[d]
			if _in(c2) and cells[c2.y * N + c2.x] == MASS and not reserved.has(c2) and r.randf() < 0.75:
				cl.append(c2)
			_room(lay, cl, c, d, r, "")
	return lay


func _room(lay: Dictionary, cl: Array, door_cell: Vector2i, d: int, r: RandomNumberGenerator, special: String) -> void:
	var cells: PackedInt32Array = lay["cells"]
	var id := 100 + (lay["rooms"] as Array).size()
	for c in cl:
		cells[c.y * N + c.x] = id
	var kind: String = lay["kind"]
	var st := "locked"
	var x := r.randf()
	if x < 0.16:
		st = "unlocks"
	elif x < 0.36:
		st = "unlocked"
	elif x < 0.44:
		st = "random"
	var num := str(r.randi_range(1, 999))
	if r.randf() < 0.18:
		num = str(r.randi_range(1000, 9999))
	elif r.randf() < 0.06:
		num += ["A", "B", "C", "D"][r.randi() % 4]
	var room := {"id": id, "cells": cl, "door": door_cell, "dir": d, "special": special, "state": st,
		"number": num, "furnished": cl.size() == 2 and r.randf() < 0.42, "chatter": st == "locked" and r.randf() < 0.12,
		"dark": kind == "dark" and r.randf() < 0.45, "floor": "l5_walnut" if r.randf() < 0.4 else "l5_room_carpet",
		"paper": "l5_room_paper" if r.randf() < 0.6 else "l5_room_paper_b"}
	if room["dark"]:
		room["furnished"] = false
	(lay["rooms"] as Array).append(room)
	var c1: Vector2i = door_cell + DIRS[d]
	lay["doors"]["%d,%d,%d" % [door_cell.x, door_cell.y, d]] = room
	lay["doors"]["%d,%d,%d" % [c1.x, c1.y, (d + 2) % 4]] = room


func edge(lay: Dictionary, i: int, j: int, d: int) -> String:
	var cells: PackedInt32Array = lay["cells"]
	var c := cells[j * N + i]
	var nb: Vector2i = Vector2i(i, j) + DIRS[d]
	if not _in(nb):
		if c == COR and (i if d in [0, 2] else j) in lay["E"][d]:
			return "open"
		return "wall"
	var c2 := cells[nb.y * N + nb.x]
	if c2 == c and c != CAR:
		return "open"
	if lay["doors"].has("%d,%d,%d" % [i, j, d]):
		return "door"
	if (c == CAR and d == 1) or (c == COR and c2 == CAR and d == 3):
		return "car"
	return "wall"


## Half-wall segment geometry: [a, b, interior normal] (a->b keeps +z inside).
func edge_geo(o: Vector3, i: int, j: int, d: int) -> Array:
	var x0 := o.x + i * G
	var z0 := o.z + j * G
	match d:
		0:
			return [Vector3(x0, 0, z0 + T * 0.5), Vector3(x0 + G, 0, z0 + T * 0.5), Vector3(0, 0, 1)]
		1:
			return [Vector3(x0 + G - T * 0.5, 0, z0), Vector3(x0 + G - T * 0.5, 0, z0 + G), Vector3(-1, 0, 0)]
		2:
			return [Vector3(x0 + G, 0, z0 + G - T * 0.5), Vector3(x0, 0, z0 + G - T * 0.5), Vector3(0, 0, -1)]
	return [Vector3(x0 + T * 0.5, 0, z0 + G), Vector3(x0 + T * 0.5, 0, z0), Vector3(1, 0, 0)]


## Wall band from y0 to y1 with rectangular openings [{at, w, h}].
func wall(k: GeoKit, a: Vector3, b: Vector3, y0: float, y1: float, thick: float, mat: String, ops: Array, faces: int, collide: bool) -> void:
	var dv := Vector3(b.x - a.x, 0, b.z - a.z)
	var length := dv.length()
	if length < 0.01 or y1 - y0 < 0.004:
		return
	var dir := dv / length
	var bas := Basis(dir, Vector3.UP, dir.cross(Vector3.UP))
	var cur := 0.0
	for op in ops:
		var s0 := clampf(float(op["at"]) - float(op["w"]) * 0.5, 0.0, length)
		var s1 := clampf(float(op["at"]) + float(op["w"]) * 0.5, 0.0, length)
		var top := float(op["h"])
		_piece(k, a, bas, cur, s0, y0, y1, thick, mat, faces, collide)
		_piece(k, a, bas, s0, s1, maxf(y0, top), y1, thick, mat, faces, collide)
		cur = maxf(cur, s1)
	_piece(k, a, bas, cur, length, y0, y1, thick, mat, faces, collide)


func _piece(k: GeoKit, a: Vector3, bas: Basis, s0: float, s1: float, y0: float, y1: float, thick: float, mat: String, faces: int, collide: bool) -> void:
	if y1 - y0 < 0.004 or s1 - s0 < 0.004:
		return
	var c := Vector3(a.x, 0, a.z) + bas.x * ((s0 + s1) * 0.5) + Vector3.UP * ((y0 + y1) * 0.5)
	k.box_xf(Transform3D(bas, c), Vector3(s1 - s0, y1 - y0, thick), mat, faces, collide)


## Corridor dressing: walnut wainscot, gilt chair rail, damask, cream crown.
func cor_wall(k: GeoKit, a: Vector3, b: Vector3, n: Vector3, ops: Array, collide: bool) -> void:
	var f := GeoKit.PZ | GeoKit.PX | GeoKit.NX
	if collide:
		wall(k, a - n * T * 0.5, b - n * T * 0.5, 0.0, H, T * 2.0, "l5_wallpaper", ops, 0, true)
	wall(k, a, b, 0.0, 0.95, T, "l5_wainscot", ops, f, false)
	wall(k, a + n * 0.02, b + n * 0.02, 0.93, 0.99, T, "l5_trim_gold", ops, f | GeoKit.PY | GeoKit.NY, false)
	wall(k, a, b, 0.95, 3.14, T, "l5_wallpaper", ops, f, false)
	wall(k, a + n * 0.04, b + n * 0.04, 3.14, H, T, "l5_crown", ops, f | GeoKit.NY, false)


func room_wall(k: GeoKit, a: Vector3, b: Vector3, n: Vector3, ops: Array, paper: String, collide: bool) -> void:
	var f := GeoKit.PZ | GeoKit.PX | GeoKit.NX
	if collide:
		wall(k, a - n * T * 0.5, b - n * T * 0.5, 0.0, H, T * 2.0, paper, ops, 0, true)
	wall(k, a, b, 0.0, 3.2, T, paper, ops, f, false)
	wall(k, a + n * 0.01, b + n * 0.01, 0.0, 0.14, T, "l5_wood", ops, f | GeoKit.PY, false)
	wall(k, a + n * 0.03, b + n * 0.03, 3.2, H, T, "l5_crown", ops, f | GeoKit.NY, false)


# ------------------------------------------------------------------ builder

func build_chunk(cx: int, cz: int, node: Node3D) -> Dictionary:
	var lay := layout(cx, cz)
	var kind: String = lay["kind"]
	_cur_kind = kind
	_cur_key = Vector2i(cx, cz)
	var cells: PackedInt32Array = lay["cells"]
	var r := RandomNumberGenerator.new()
	r.seed = hash([seed_v, "dec", cx, cz])
	var k := GeoKit.new(node, "K")
	var o := Vector3(cx * CS, 0, cz * CS)
	var group := "%d,%d" % [cx, cz]
	var meta := {"kind": kind, "blank": [], "speakers": [], "buzz": [], "chatter": [], "dark_rooms": [], "cars": [],
		"key": Vector2i(cx, cz), "group": group}
	var cor_floor: String = FLOORS.get(kind, "l5_carpet")
	var rooms_by_id := {}
	for rm in lay["rooms"]:
		rooms_by_id[rm["id"]] = rm
	# floors (merged runs per material, collision) and ceilings (visual only)
	for j in N:
		var run := ""
		var run_c := ""
		var i0 := 0
		for i in N + 1:
			var m := ""
			var cm := ""
			if i < N:
				var c := cells[j * N + i]
				if c == COR:
					m = cor_floor
					cm = "l5_ceiling"
				elif c == CAR:
					m = "l5_lift_floor"
				elif c >= 100:
					m = rooms_by_id[c]["floor"]
					cm = "l5_ceiling"
			if m != run or cm != run_c:
				if run != "":
					k.box_mm(o + Vector3(i0 * G, -0.3, j * G), o + Vector3(i * G, 0.0, (j + 1) * G), run, GeoKit.PY)
				if run_c != "":
					k.box_mm(o + Vector3(i0 * G, H, j * G), o + Vector3(i * G, H + 0.2, (j + 1) * G), run_c, GeoKit.NY, false)
				run = m
				run_c = cm
				i0 = i
	# walls + dressing
	var sconce_n := 0
	for j in N:
		for i in N:
			var c := cells[j * N + i]
			if c == MASS or (kind == "ballroom" and c != COR):
				continue
			for d in 4:
				var e := edge(lay, i, j, d)
				if e == "open":
					continue
				var g := edge_geo(o, i, j, d)
				var a: Vector3 = g[0]
				var b: Vector3 = g[1]
				var n: Vector3 = g[2]
				var t := (b - a).normalized()
				var ops := []
				var room: Dictionary = lay["doors"].get("%d,%d,%d" % [i, j, d], {})
				if e == "door":
					ops = [{"at": G * 0.5, "w": 1.1, "h": 2.32}]
				elif e == "car":
					ops = [{"at": G * 0.5, "w": 1.6, "h": 2.36}]
				var face := a + n * T * 0.5
				var nb: Vector2i = Vector2i(i, j) + DIRS[d]
				var nc := cells[nb.y * N + nb.x] if _in(nb) else -1
				var emit := c == COR or nc == MASS or nc == -1 or (nc != COR and (nc > c or (nc == c and d < 2)))
				if c == COR:
					cor_wall(k, a, b, n, ops, true)
					if e == "door":
						_door_dressing(k, node, meta, room, face, t, n, i, j, d, o, r)
					elif e == "car":
						_car_facade(k, face, t, n, j)
					var lit := (i + j + d) % 2 == 0 and e != "car"
					if lit:
						var dead := kind == "dark" and r.randf() < 0.7
						var s := G * 0.5 if e == "wall" else G * 0.5 - 1.06
						var lp: Vector3 = P.sconce(k, face + t * s, n, dead)
						if not dead:
							L.lights.add_anchor(lp, Color(1.0, 0.74, 0.48), 1.0, 5.8, 0.0, group)
							sconce_n += 1
							if sconce_n % 7 == 3:
								meta["buzz"].append(lp)
					if e == "wall":
						_dress_blank(k, meta, face, t, n, kind, lit, r)
				elif c == CAR:
					_car_wall(k, a, b, n, ops, j, emit)
				else:
					var rm: Dictionary = rooms_by_id[c]
					room_wall(k, a, b, n, ops, rm["paper"], emit)
					if e == "door":
						_casing(k, face, t, n, "l5_wood", 0.0)
	for rm in lay["rooms"]:
		_room_inside(k, node, meta, rm, o, r, group)
	for j in LIFT_ROWS:
		if cells[j * N + 7] == CAR:
			_car(k, node, meta, o, j, kind)
	if kind == "ballroom":
		L.core.ballroom(k, node, meta, lay, o)
	if kind == "lobby":
		L.core.lobby(k, node, meta, lay, o)
	k.commit()
	meta["boxes"] = k.stats["boxes"]
	meta["shapes"] = k.stats["shapes"]
	return meta


func _casing(k: GeoKit, face: Vector3, t: Vector3, n: Vector3, mat: String, ext: float) -> void:
	var c := face + t * G * 0.5
	var b := Basis(t, Vector3.UP, n)
	for sx in [-1.0, 1.0]:
		k.box_xf(Transform3D(b, c + t * sx * (0.6 + ext) + Vector3.UP * 1.19 + n * 0.015), Vector3(0.1, 2.38, 0.03), mat, GeoKit.ALL, false)
	k.box_xf(Transform3D(b, c + Vector3.UP * (2.43 + ext * 0.5) + n * 0.02), Vector3(1.34 + ext * 2.0, 0.14 + ext, 0.04), mat, GeoKit.ALL, false)


func _door_dressing(k: GeoKit, node: Node3D, meta: Dictionary, room: Dictionary, face: Vector3, t: Vector3, n: Vector3, i: int, j: int, d: int, o: Vector3, r: RandomNumberGenerator) -> void:
	var c := face + t * G * 0.5
	var beverly: bool = room.get("special", "") == "beverly"
	_casing(k, face, t, n, "l5_trim_gold" if beverly else "l5_wood", 0.0)
	if beverly:
		k.box_xf(Transform3D(Basis(t, Vector3.UP, n), c + Vector3.UP * 2.66 + n * 0.012), Vector3(0.62, 0.11, 0.012), "l5_silver", GeoKit.ALL, false)
		P.label(node, "The Beverly Room", c + Vector3.UP * 2.66 + n * 0.02, n, 0.0011, Color(0.1, 0.1, 0.11), 14.0)
	else:
		var pp := c + t * 0.8 + Vector3.UP * 1.56
		k.box_xf(Transform3D(Basis(t, Vector3.UP, n), pp + n * 0.006), Vector3(0.15, 0.1, 0.012), "l5_trim_gold", GeoKit.ALL, false)
		P.label(node, str(room.get("number", "")), pp + n * 0.014, n, 0.0009, Color(0.12, 0.07, 0.02))
	var sp: String = room.get("special", "")
	if room.get("dark", false):
		meta["dark_rooms"].append({"pos": c + Vector3.UP * 1.2 - n * 1.2, "n": n})
		return
	var hinge := c - n * T * 0.5 - t * 0.5
	if sp == "dark" or sp == "damaged":
		L.core.special_door(k, node, meta, sp, hinge, t, -n)
		return
	var style := "white" if beverly else "std"
	var dr: StaticBody3D = P.make_door(node, hinge, t, -n, style)
	dr.number = str(room.get("number", ""))
	dr.state = room.get("state", "locked")
	dr.beverly = beverly
	if dr.state == "unlocks":
		dr.unlock_at = r.randf_range(60.0, 900.0)
	dr.next_event = r.randf_range(15.0, 80.0)
	if room.get("open", false):
		dr.swing_to(1.0, true)
	L.register_door(dr)
	if room.get("chatter", false):
		meta["chatter"].append(c - n * 2.0 + Vector3.UP * 1.4)


func _dress_blank(k: GeoKit, meta: Dictionary, face: Vector3, t: Vector3, n: Vector3, kind: String, lit: bool, r: RandomNumberGenerator) -> void:
	var c := face + t * G * 0.5
	if kind == "lobby":
		return
	var x := r.randf()
	if x < 0.13:
		P.sofa(k, c, n)
		if not lit:
			P.painting(k, c, n, 1.3, 0.8, 1.75)
	elif x < 0.22:
		P.bookshelf(k, c, n, r)
	elif x < 0.32:
		var gram := r.randf() < 0.45 or kind == "gallery"
		P.cabinet(k, c, n, gram)
		if gram:
			meta["speakers"].append(c + n * 0.3 + Vector3.UP * 1.3)
		if not lit:
			P.painting(k, c, n, 0.7, 0.9, 1.75)
	elif x < 0.5:
		if not lit:
			var sz := [[0.9, 0.7], [0.62, 0.84], [1.3, 0.85]][r.randi() % 3] as Array
			P.painting(k, c, n, sz[0], sz[1], 1.62)
		meta["blank"].append({"p": c, "t": t, "n": n})
	elif x < 0.56:
		P.console(k, c, n)
		if not lit:
			P.painting(k, c, n, 0.8, 0.6, 1.6)
	else:
		if x > 0.93:
			meta["speakers"].append(P.speaker(k, c, n))
		meta["blank"].append({"p": c, "t": t, "n": n})


func _room_inside(k: GeoKit, node: Node3D, meta: Dictionary, rm: Dictionary, o: Vector3, r: RandomNumberGenerator, group: String) -> void:
	var dc: Vector2i = rm["door"]
	var d: int = rm["dir"]
	var fwd := Vector3(DIRS[d].x, 0, DIRS[d].y)
	var depth := G * (rm["cells"] as Array).size()
	var door_pt := o + Vector3((dc.x + 0.5) * G, 0, (dc.y + 0.5) * G) + fwd * G * 0.5
	var far := door_pt + fwd * (depth - T)
	if rm["furnished"]:
		var b := Basis(Vector3.UP.cross(-fwd), Vector3.UP, -fwd)
		var lamp: Vector3 = P.room_set(k, b, far, depth - T)
		L.lights.add_anchor(lamp + Vector3.UP * 0.25, Color(1.0, 0.66, 0.36), 0.75, 4.6, 0.0, group)
		var bed := far - fwd * 1.05 + b.x * -0.2 + Vector3.UP * 0.55
		var it := Interactable.new()
		node.add_child(it)
		it.setup(bed, Vector3(1.4, 0.3, 1.9), "Rest in the furnished room", Callable(L, "rest_in_room"))
		P.painting(k, far, -fwd, 0.9, 0.6, 1.75)
	elif rm.get("special", "") == "" and not rm["dark"] and r.randf() < 0.3:
		k.box_xf(Transform3D(Basis(), door_pt + fwd * (depth * 0.5) + Vector3.UP * 0.006), Vector3(1.6, 0.012, 1.6), "l5_rug", GeoKit.ALL, false)


# --------------------------------------------------------------- elevators

func _style(j: int) -> String:
	if _cur_kind == "lobby":
		return "modern" if j < 5 else "antique"
	return "antique" if h01(_cur_key.x, _cur_key.y, 17) < 0.55 else "modern"


func _car_wall(k: GeoKit, a: Vector3, b: Vector3, n: Vector3, ops: Array, j: int, collide: bool) -> void:
	var f := GeoKit.PZ | GeoKit.PX | GeoKit.NX
	if collide:
		wall(k, a - n * T * 0.5, b - n * T * 0.5, 0.0, H, T * 2.0, "l5_steel", ops, 0, true)
	if _style(j) == "antique":
		wall(k, a, b, 0.0, 0.95, T, "l5_lift_wood", ops, f, false)
		wall(k, a, b, 0.95, 2.62, T, "l5_lattice", ops, f, false)
		wall(k, a, b, 2.62, H, T, "void_black", ops, f, false)
	else:
		wall(k, a, b, 0.0, 2.55, T, "l5_steel", ops, f, false)
		wall(k, a + n * 0.03, b + n * 0.03, 0.92, 0.98, T, "l5_steel_dark", ops, f | GeoKit.PY | GeoKit.NY, false)
		wall(k, a, b, 2.55, H, T, "void_black", ops, f, false)


func _car_facade(k: GeoKit, face: Vector3, t: Vector3, n: Vector3, j: int) -> void:
	var c := face + t * G * 0.5
	var b := Basis(t, Vector3.UP, n)
	var antique := _style(j) == "antique"
	var mat := "l5_copper" if antique else "l5_steel"
	for sx in [-1.0, 1.0]:
		k.box_xf(Transform3D(b, c + t * sx * 0.88 + Vector3.UP * 1.2 + n * 0.03), Vector3(0.16, 2.4, 0.06), mat, GeoKit.ALL, false)
	k.box_xf(Transform3D(b, c + Vector3.UP * 2.48 + n * 0.035), Vector3(1.92, 0.2, 0.07), mat, GeoKit.ALL, false)
	if antique:
		k.box_xf(Transform3D(b, c + Vector3.UP * 2.84 + n * 0.012), Vector3(0.62, 0.3, 0.024), "l5_trim_gold", GeoKit.ALL, false)
	else:
		k.box_xf(Transform3D(b, c + Vector3.UP * 2.82 + n * 0.012), Vector3(0.5, 0.2, 0.024), "l5_steel_dark", GeoKit.ALL, false)


## One car: lowered ceiling, lamp, 382-button panel, gate/doors, blocker.
func _car(k: GeoKit, node: Node3D, meta: Dictionary, o: Vector3, j: int, kind: String) -> void:
	var x0 := o.x + 7 * G
	var z0 := o.z + j * G
	var org := Vector3(x0 + G * 0.5, 0, z0 + G * 0.5)
	var style := _style(j)
	var antique := style == "antique"
	k.box_mm(Vector3(x0, 2.6, z0), Vector3(x0 + G, 2.7, z0 + G), "l5_lift_wood" if antique else "l5_steel", GeoKit.NY, false)
	k.panel(Vector3(org.x, 2.595, org.z), 0.9, 0.5, "l5_lift_lamp")
	var lamp: int = L.lights.add_anchor(Vector3(org.x, 2.3, org.z), Color(1.0, 0.8, 0.55), 0.8, 4.2, 0.0, meta["group"])
	# panel on the car's north wall, by the door
	var pc := Vector3(x0 + G - 0.72, 1.35, z0 + T + 0.012)
	k.box_xf(Transform3D(Basis(), pc + Vector3(0, 0, -0.012)), Vector3(0.52, 0.96, 0.012), "l5_trim_gold", GeoKit.ALL, false)
	k.quad(pc, Vector3(0, 0, 1), Vector3(0.21, 0, 0), Vector3(0, 0.42, 0), "l5_lift_buttons", Vector2.ZERO, true)
	k.box_xf(Transform3D(Basis(), Vector3(pc.x + 0.06, pc.y + 0.405, pc.z + 0.004)), Vector3(0.3, 0.032, 0.006), "l5_trim_gold", GeoKit.ALL, false)
	var it := Interactable.new()
	node.add_child(it)
	it.setup(pc + Vector3(0, 0, 0.025), Vector3(0.44, 0.86, 0.05), "Press a floor button")
	var rd: Label3D = P.label(node, "", pc + Vector3(0, 0.56, 0), Vector3(0, 0, 1), 0.0016, Color(0.95, 0.75, 0.4), 6.0)
	rd.shaded = false
	# gallery-side indicator
	var ind: Label3D = P.label(node, "1", Vector3(x0 + G + T + 0.07, 2.84 if antique else 2.82, org.z), Vector3(1, 0, 0), 0.0018, Color(0.12, 0.08, 0.03) if antique else Color(1.0, 0.55, 0.25), 18.0)
	# gate / doors and the blocker used while riding
	var dn := Node3D.new()
	dn.position = Vector3(x0 + G, 0, org.z - 0.8)
	node.add_child(dn)
	var leaves: Array = []
	if antique:
		var mi := MeshInstance3D.new()
		mi.mesh = P.gate_mesh()
		mi.basis = Basis(Vector3.UP, -PI * 0.5)
		mi.scale = Vector3(0.12, 1, 1)
		dn.add_child(mi)
		leaves.append(mi)
	else:
		for s in 2:
			var lf := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.05, 2.34, 0.8)
			lf.mesh = bm
			lf.material_override = MatLib.get_mat("l5_steel")
			lf.position = Vector3(0, 1.17, -0.42 if s == 0 else 2.02)
			dn.add_child(lf)
			leaves.append(lf)
	var blk := StaticBody3D.new()
	blk.collision_layer = 0
	blk.collision_mask = 0
	var bcs := CollisionShape3D.new()
	var bsh := BoxShape3D.new()
	bsh.size = Vector3(0.12, 2.4, 1.7)
	bcs.shape = bsh
	bcs.position = Vector3(0, 1.2, 0.8)
	blk.add_child(bcs)
	dn.add_child(blk)
	var car := {"idx": LIFT_ROWS.find(j), "origin": org, "style": style, "door": dn, "leaves": leaves, "blocker": blk,
		"panel": it, "readout": rd, "indicator": ind, "lamp": lamp, "key": meta["key"], "open": true}
	it.action = Callable(L, "panel_press").bind(car)
	meta["cars"].append(car)
