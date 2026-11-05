extends RefCounted
## Level 4 streamed office grammar (ADAPTATION: the page gives no map).
## Every 24 m chunk is one office block plus the two corridors on its west and
## north sides, built on two walkable storeys (y = 0 and y = 3.6). The block's
## vertical feature is shared by both storeys:
##   plain  - nothing vertical
##   core   - switchback fire stair between the storeys + lift shaft
##   atrium - double-height void with a glass-railed gallery above and
##            (sometimes) a sunken floor below
##   well   - light well: glazed walls looking across a shaft at more office
##            floors stacked above and below, out of sight (no visible edge)
##   exit   - (story mode, rare) an office stairway leading down out of the level
## Each storey is either "ring" (perimeter offices around an open floor),
## "open" (empty open-plan with columns) or "conf" (ring + a conference room).
## The page says the building is almost completely devoid of furniture, so
## floors are empty: only ghost marks where desks stood, a few partitions.

const P := preload("res://levels/L004/L004_parts.gd")
const CS := 24.0
const CW := 2.4
const FY := [0.0, 3.6]
const T := P.T
const CH := P.CH

var lvl: Node3D
var parts: RefCounted


func _init(level: Node3D, p: RefCounted) -> void:
	lvl = level
	parts = p


func h01(a: int, b: int, salt: int) -> float:
	return float(absi(hash([lvl.level_seed, a, b, salt])) % 100003) / 100003.0


func plan(cx: int, cz: int) -> Dictionary:
	var pl := {"v": "plain", "R": Rect2(), "dim": false, "lift": -1, "dest": ""}
	if cx == 0 and cz == 0:
		pl["v"] = "anchor"
		return pl
	var r := RandomNumberGenerator.new()
	r.seed = hash([lvl.level_seed, "plan", cx, cz])
	var h := h01(cx, cz, 3)
	var d := maxi(absi(cx), absi(cz))
	var v := "plain"
	if cx == 1 and cz == 1:
		v = "well"      # authored: a light well always sits diagonally off the anchor
	elif d >= 2 and h < 0.07 and not lvl.qa_fixture:
		v = "exit"
	elif h < 0.33:
		v = "core"
	elif h < 0.47:
		v = "atrium"
	elif h < 0.63:
		v = "well"
	pl["v"] = v
	match v:
		"core", "exit":
			pl["R"] = Rect2([9.6, 12.0, 14.4][r.randi() % 3], [10.8, 12.0, 13.2][r.randi() % 3], 7.2 if v == "core" else 4.8, 6.6)
		"atrium":
			var w: float = [8.4, 9.6][r.randi() % 2]
			var dd: float = [8.4, 9.6][r.randi() % 2]
			pl["R"] = Rect2(snappedf(9.6 + r.randf() * (22.8 - 9.6 - w), 1.2), snappedf(9.6 + r.randf() * (22.8 - 9.6 - dd), 1.2), w, dd)
			pl["sunken"] = r.randf() < 0.6
		"well":
			pl["R"] = Rect2([10.8, 12.0, 13.2, 14.4][r.randi() % 4], [10.8, 12.0, 13.2, 14.4][r.randi() % 4], 7.2, 7.2)
	var types: Array = []
	for f in 2:
		var t := r.randf()
		types.append("open" if t < 0.36 else ("conf" if (t > 0.8 and v == "plain") else "ring"))
	pl["types"] = types
	pl["dim"] = r.randf() < 0.18
	if v == "core" and r.randf() < 0.16:
		pl["lift"] = r.randi() % 2
	if v == "exit":
		var e := r.randf()
		pl["dest"] = "L004>L005#1" if e < 0.55 else ("L004>L006#2" if e < 0.9 else "L004>L071#4")
	return pl


# ------------------------------------------------------------- chunk

func build_chunk(cx: int, cz: int, node: Node3D) -> Dictionary:
	var pl := plan(cx, cz)
	var group := "%d,%d" % [cx, cz]
	node.set_meta("group", group)
	var o := Vector3(cx * CS, 0, cz * CS)
	var meta := {"v": pl["v"], "exits": [], "windows": [], "dispensers": []}
	var k := GeoKit.new(node, "K")
	var r := RandomNumberGenerator.new()
	r.seed = hash([lvl.level_seed, "chunk", cx, cz])
	if pl["v"] == "anchor":
		lvl.anchor.build(k, node, o, meta)
		k.commit()
		return meta
	var R: Rect2 = pl["R"]
	var Rw := Rect2(R.position + Vector2(o.x, o.z), R.size)
	var v: String = pl["v"]
	# ---- floors and ceilings
	var corr := [Rect2(o.x, o.z, CS, CW), Rect2(o.x, o.z + CW, CW, CS - CW)]
	var block := [Rect2(o.x + CW, o.z + CW, CS - CW, CS - CW)]
	var f0_holes: Array = []
	var c0_holes: Array = []
	var f1_holes: Array = []
	var c1_holes: Array = []
	match v:
		"core":
			c0_holes = [Rw]; f1_holes = [Rw]; c1_holes = [Rw]
		"exit":
			f0_holes = [Rw]; c0_holes = [Rw]
		"atrium":
			if pl.get("sunken", false):
				f0_holes = [Rw.grow(-1.2)]
			c0_holes = [Rw]; f1_holes = [Rw]
		"well":
			f0_holes = [Rw]; c0_holes = [Rw]; f1_holes = [Rw]; c1_holes = [Rw]
	P.floor_rects(k, corr, 0.0, 0.3, "l4_carpet_corr")
	P.floor_rects(k, P.cut(block, f0_holes), 0.0, 0.3, "l4_carpet")
	P.ceil_rects(k, P.cut(corr + block, c0_holes), CH, "l4_ceiling")
	P.floor_rects(k, corr, FY[1], 0.8, "l4_carpet_corr")
	P.floor_rects(k, P.cut(block, f1_holes), FY[1], 0.8, "l4_carpet")
	P.ceil_rects(k, P.cut(corr + block, c1_holes), FY[1] + CH, "l4_ceiling")
	# ---- storeys
	for f in 2:
		_corridor_lights(k, o, FY[f], group, r)
		var t: String = pl["types"][f]
		if t == "open":
			_open(k, node, o, FY[f], R, r, meta, group, pl["dim"])
		else:
			_ring(k, node, o, FY[f], R, r, meta, group, pl["dim"], t == "conf")
	# ---- vertical feature
	match v:
		"core":
			var sf := P.fr(o + Vector3(R.position.x, 0, R.position.y), Vector3.RIGHT, Vector3.BACK)
			var sw: Dictionary = parts.stairwell(k, node, sf, 0.0, true, "core", [])
			for dd in sw["doors"]:
				P.door_trim(k, dd["a"] + Vector3.UP * dd["y"], dd["b"] + Vector3.UP * dd["y"], dd["at"], P.DOOR_W, P.DOOR_H, "l4_frame", "l4_firedoor", 1.0)
				P.exit_sign(k, node, dd["a"] + Vector3.UP * dd["y"], dd["b"] + Vector3.UP * dd["y"], dd["at"], 2.38, -1.0)
			var lf := P.fr(o + Vector3(R.position.x + 4.8, 0, R.position.y), Vector3.RIGHT, Vector3.BACK)
			var car: Variant = parts.lift(k, node, lf, pl["lift"])
			var x1 := o.x + R.end.x
			k.wall(Vector3(x1, -0.3, o.z + R.position.y + 2.4), Vector3(x1, -0.3, o.z + R.end.y), 7.5, T, "l4_wall", [], GeoKit.ALL)
			k.wall(Vector3(o.x + R.position.x + 4.8, -0.3, o.z + R.end.y), Vector3(x1 + T * 0.5, -0.3, o.z + R.end.y), 7.5, T, "l4_wall", [], GeoKit.ALL)
			if car != null and not lvl.qa_fixture:
				var tr: ExitTrigger = lvl.make_exit("L004>L003#3", "interact", car, Vector3(2.0, 2.0, 2.0), "Ride the lift: the panel only shows a down arrow", node)
				if tr:
					meta["exits"].append({"trig": tr, "id": "L004>L003#3", "pos": car + Vector3(0, 0.3, -1.4), "zone": Rect2(Rw.position.x + 4.8, Rw.position.y - 0.3, 2.4, 2.7),
						"seal": {"a": lf["o"], "b": lf["o"] + Vector3.RIGHT * 2.4, "at": 1.2, "w": 1.1, "y": FY[pl["lift"]]}, "door": null})
		"exit":
			_exit_stair(k, node, o, R, pl["dest"], meta)
		"atrium":
			_atrium(k, node, o, R, pl.get("sunken", false), group)
		"well":
			_well(k, node, o, R, r, meta, cx == 1 and cz == 1)
	k.commit()
	meta["boxes"] = k.stats["boxes"]
	return meta


func _corridor_lights(k: GeoKit, o: Vector3, y: float, group: String, r: RandomNumberGenerator) -> void:
	for i in 10:
		var dead := r.randf() < 0.16
		var cxp := o + Vector3(1.2 + i * 2.4, y + CH - 0.004, 1.2)
		k.panel(cxp, 1.2, 0.6, "l4_panel", 100.0 + i if dead else float(i * 7 + 3), 0.0)
		if i % 2 == 0 and not dead:
			lvl.lights.add_anchor(cxp + Vector3.DOWN * 0.75, Color(0.92, 0.96, 1.0), 1.1, 5.5, 0.0, group)
		if i > 0:
			var czp := o + Vector3(1.2, y + CH - 0.004, 1.2 + i * 2.4)
			var dead2 := r.randf() < 0.12
			k.panel(czp, 0.6, 1.2, "l4_panel", 100.0 + i if dead2 else float(i * 5 + 1), 0.0)
			if i % 2 == 0 and not dead2:
				lvl.lights.add_anchor(czp + Vector3.DOWN * 0.75, Color(0.92, 0.96, 1.0), 1.1, 5.5, 0.0, group)


# ------------------------------------------------------------- storeys

## Wall along +x or +z in chunk-local coords with openings and painted-over
## windows. side: which face(s) get the window decals (1, -1 or 0 = both).
func _wall(k: GeoKit, o: Vector3, y: float, a: Vector2, b: Vector2, ops: Array, wins: Array, side: float, doors: Array = []) -> void:
	var A := o + Vector3(a.x, y, a.y)
	var B := o + Vector3(b.x, y, b.y)
	k.wall(A, B, CH, T, "l4_wall", ops, GeoKit.ALL)
	for w in wins:
		if side >= 0.0:
			P.black_window(k, A, B, w, minf(1.6, 2.0), 0.9, 1.4, 1.0, int(w * 10.0) % 3 == 0)
		if side <= 0.0:
			P.black_window(k, A, B, w, minf(1.6, 2.0), 0.9, 1.4, -1.0, int(w * 7.0) % 4 == 0)
	for d in doors:
		P.door_trim(k, A, B, d[0], P.DOOR_W, P.DOOR_H, "l4_frame", "l4_door" if d[1] != 0.0 else "", d[1])


func _ring(k: GeoKit, node: Node3D, o: Vector3, y: float, R: Rect2, r: RandomNumberGenerator, meta: Dictionary, group: String, dim: bool, conf: bool) -> void:
	var xs: Array = [2.4, 7.2]
	for x in [10.8, 14.4, 19.2]:
		if r.randf() > 0.22:
			xs.append(x)
	xs.append(24.0)
	var zs: Array = [9.6]
	for z in [13.2, 16.8, 20.4]:
		if r.randf() > 0.22:
			zs.append(z)
	zs.append(24.0)
	var pn := 1 + r.randi() % (xs.size() - 2)
	var pw := r.randi() % (zs.size() - 1)
	# --- north row
	var ops_out: Array = []
	var wins_out: Array = []
	var ops_in: Array = []
	var doors_in: Array = []
	for i in xs.size() - 1:
		var x0: float = xs[i]
		var x1: float = xs[i + 1]
		var mid := (x0 + x1) * 0.5 - 2.4
		if i == pn:
			ops_out.append({"at": mid, "w": x1 - x0 - 1.4, "h": 2.3})
			ops_in.append({"at": mid, "w": x1 - x0 - 1.4, "h": 2.3})
		else:
			wins_out.append(mid)
			var at := mid + r.randf_range(-0.4, 0.4) * (x1 - x0 - 2.0) * 0.5
			ops_in.append({"at": at, "w": P.DOOR_W, "h": P.DOOR_H})
			doors_in.append([at, -1.0 if r.randf() < 0.7 else 0.0])
			_room_light(k, o + Vector3((x0 + x1) * 0.5, y, 4.8), group, r, dim)
		if i > 0:
			k.wall(o + Vector3(x0, y, 2.4), o + Vector3(x0, y, 7.2), CH, T, "l4_wall", [], GeoKit.ALL)
	_wall(k, o, y, Vector2(2.4, 2.4 - T * 0.5), Vector2(24.0 + T * 0.5, 2.4 - T * 0.5), ops_out, wins_out, 0.0)
	_wall(k, o, y, Vector2(2.4 - T * 0.5, 7.2), Vector2(24.0 + T * 0.5, 7.2), ops_in, [], 0.0, doors_in)
	# --- west row (below a small lobby that links the west corridor to the floor)
	ops_out = [{"at": 6.0, "w": 1.8, "h": 2.3}]
	wins_out = []
	ops_in = [{"at": 1.2, "w": 1.8, "h": 2.3}]
	doors_in = []
	for j in zs.size() - 1:
		var z0: float = zs[j]
		var z1: float = zs[j + 1]
		var mid := (z0 + z1) * 0.5 - 2.4
		var midi := (z0 + z1) * 0.5 - 7.2
		if j == pw:
			ops_out.append({"at": mid, "w": z1 - z0 - 1.4, "h": 2.3})
			ops_in.append({"at": midi, "w": z1 - z0 - 1.4, "h": 2.3})
		else:
			wins_out.append(mid)
			var at := midi + r.randf_range(-0.3, 0.3)
			ops_in.append({"at": at, "w": P.DOOR_W, "h": P.DOOR_H})
			doors_in.append([at, 1.0 if r.randf() < 0.7 else 0.0])
			_room_light(k, o + Vector3(4.8, y, (z0 + z1) * 0.5), group, r, dim)
		k.wall(o + Vector3(2.4, y, z0), o + Vector3(7.2, y, z0), CH, T, "l4_wall", [], GeoKit.ALL)
	_wall(k, o, y, Vector2(2.4 - T * 0.5, 2.4), Vector2(2.4 - T * 0.5, 24.0 + T * 0.5), ops_out, wins_out, 0.0)
	_wall(k, o, y, Vector2(7.2, 7.2), Vector2(7.2, 24.0 + T * 0.5), ops_in, [], 0.0, doors_in)
	_room_light(k, o + Vector3(4.8, y, 8.4), group, r, dim)
	# --- east and south walls of the block face the neighbours' corridors
	_edge_wall(k, o, y, true, r, 7.2)
	_edge_wall(k, o, y, false, r, 7.2)
	# --- interior: open floor, maybe a conference room
	var interior := Rect2(7.2, 7.2, 16.8, 16.8)
	if conf:
		_conference(k, node, o, y, r, group)
	else:
		_columns(k, o, y, R, [Vector2(12.0, 12.0), Vector2(12.0, 19.2), Vector2(19.2, 12.0), Vector2(19.2, 19.2)])
		_ghosts(k, o, y, R, r, interior, 2 + r.randi() % 2)
	_grid_lights(k, o, y, R, r, interior, group, dim, conf)
	# --- almond water against the north row's inner wall
	var spots: Array = []
	for i in range(1, xs.size() - 1):
		if i != pn:
			spots.append(xs[i])
	if pn != xs.size() - 2:
		spots.append(22.9)
	_dispensers(k, node, o, y, r, meta, spots, 7.2 + T * 0.5, Vector3.BACK)
	_clutter(k, o, y, R, r, interior)


func _edge_wall(k: GeoKit, o: Vector3, y: float, east: bool, r: RandomNumberGenerator, solid_until: float) -> void:
	var ops: Array = []
	var cands := [9.6, 13.2, 16.8, 20.4]
	var n := 1 + r.randi() % 2
	var used := []
	while used.size() < n:
		var c: float = cands[r.randi() % cands.size()]
		if not used.has(c):
			used.append(c)
	for c in used:
		ops.append({"at": c - 2.4, "w": [1.8, 2.4, 3.6][r.randi() % 3], "h": 2.3})
	var wins := _wins_between(21.6, ops, 2.4, 1.0)
	if east:
		_wall(k, o, y, Vector2(24.0, 2.4), Vector2(24.0, 24.0 + T * 0.5), ops, wins, -1.0)
	else:
		_wall(k, o, y, Vector2(2.4, 24.0), Vector2(24.0 + T * 0.5, 24.0), ops, wins, 1.0)


## Window positions along a wall of length len that keep clear of openings.
func _wins_between(len: float, ops: Array, start: float, tail: float, step := 3.6) -> Array:
	var out: Array = []
	var at := start
	while at < len - tail:
		var ok := true
		for op in ops:
			if absf(at - float(op["at"])) < float(op["w"]) * 0.5 + 1.1:
				ok = false
		if ok:
			out.append(at)
		at += step
	return out


func _open(k: GeoKit, node: Node3D, o: Vector3, y: float, R: Rect2, r: RandomNumberGenerator, meta: Dictionary, group: String, dim: bool) -> void:
	var cands := [4.8, 8.4, 12.0, 15.6, 19.2]
	for side in 4:
		var a := r.randi() % 2
		var b := 3 + r.randi() % 2
		var ops: Array = [{"at": cands[a] - 2.4 + 1.2, "w": 3.6, "h": 2.4}, {"at": cands[b] - 2.4 + 1.2, "w": 3.6, "h": 2.4}]
		var wins := _wins_between(21.6, ops, 3.6, 2.6)
		match side:
			0: _wall(k, o, y, Vector2(2.4, 2.4 - T * 0.5), Vector2(24.0 + T * 0.5, 2.4 - T * 0.5), ops, wins, 0.0)
			1: _wall(k, o, y, Vector2(2.4 - T * 0.5, 2.4), Vector2(2.4 - T * 0.5, 24.0 + T * 0.5), ops, wins, 0.0)
			2: _wall(k, o, y, Vector2(24.0, 2.4), Vector2(24.0, 24.0 + T * 0.5), ops, wins, 0.0)
			3: _wall(k, o, y, Vector2(2.4, 24.0), Vector2(24.0 + T * 0.5, 24.0), ops, wins, 0.0)
	var interior := Rect2(2.4, 2.4, 21.6, 21.6)
	_columns(k, o, y, R, [Vector2(9.6, 9.6), Vector2(9.6, 16.8), Vector2(16.8, 9.6), Vector2(16.8, 16.8)])
	_ghosts(k, o, y, R, r, interior, 4 + r.randi() % 3)
	# a few cubicle partitions that were never taken away
	for n in r.randi() % 3:
		var px := r.randf_range(4.0, 20.0)
		var pz := r.randf_range(4.0, 20.0)
		var len := r.randf_range(2.4, 4.8)
		var along_x := r.randf() < 0.5
		var rect := Rect2(px - 0.2, pz - 0.2, (len if along_x else 0.0) + 0.4, (0.0 if along_x else len) + 0.4)
		if rect.intersects(R.grow(0.8)) or rect.end.x > 23.4 or rect.end.y > 23.4:
			continue
		var a3 := o + Vector3(px, y, pz)
		var b3 := a3 + (Vector3(len, 0, 0) if along_x else Vector3(0, 0, len))
		k.wall(a3, b3, 1.35, 0.06, "l4_partition", [], GeoKit.ALL)
		k.box((a3 + b3) * 0.5 + Vector3.UP * 1.365, Vector3(len if along_x else 0.07, 0.03, 0.07 if along_x else len), "l4_alu", GeoKit.ALL, false)
	_grid_lights(k, o, y, R, r, interior, group, dim, false)
	_dispensers(k, node, o, y, r, meta, [2.6, 22.4], 2.4, Vector3.BACK)
	_clutter(k, o, y, R, r, interior)


func _columns(k: GeoKit, o: Vector3, y: float, R: Rect2, pts: Array) -> void:
	for p in pts:
		var pp: Vector2 = p
		if R.grow(0.8).has_point(pp):
			continue
		k.box(o + Vector3(pp.x, y + CH * 0.5, pp.y), Vector3(0.5, CH, 0.5), "l4_wall", GeoKit.SIDES)


## Darker, unfaded carpet where desks stood before the floor was emptied.
func _ghosts(k: GeoKit, o: Vector3, y: float, R: Rect2, r: RandomNumberGenerator, area: Rect2, n: int) -> void:
	for i in n:
		var w := 3.4
		var d := 1.8
		var p := Vector2(r.randf_range(area.position.x + 0.8, area.end.x - w - 0.8), r.randf_range(area.position.y + 0.8, area.end.y - d - 0.8))
		var rc := Rect2(p, Vector2(w, d))
		if rc.intersects(R.grow(0.6)):
			continue
		for q in 4:
			var qx := p.x + (q % 2) * 1.75
			var qz := p.y + (q / 2) * 0.95
			k.box_mm(o + Vector3(qx, y, qz), o + Vector3(qx + 1.6, y + 0.004, qz + 0.8), "l4_carpet_ghost", GeoKit.PY, false)


func _room_light(k: GeoKit, c: Vector3, group: String, r: RandomNumberGenerator, dim: bool) -> void:
	var dead := r.randf() < (0.55 if dim else 0.12)
	k.panel(c + Vector3.UP * (CH - 0.004), 0.6, 1.2, "l4_panel", 100.0 if dead else r.randf() * 50.0, 0.0)
	if not dead:
		lvl.lights.add_anchor(c + Vector3.UP * (CH - 0.75), Color(0.92, 0.96, 1.0), 0.9, 4.6, 0.0, group)


func _grid_lights(k: GeoKit, o: Vector3, y: float, R: Rect2, r: RandomNumberGenerator, area: Rect2, group: String, dim: bool, conf: bool) -> void:
	var nx := int(area.size.x / 2.4)
	var nz := int(area.size.y / 2.4)
	for j in nz:
		for i in nx:
			var p := Vector2(area.position.x + 1.2 + i * 2.4, area.position.y + 1.2 + j * 2.4)
			if R.grow(0.4).has_point(p):
				continue
			if conf and Rect2(10.8, 10.8, 10.8, 8.4).has_point(p):
				continue
			var c := o + Vector3(p.x, y + CH - 0.004, p.y)
			if (i + j) % 2 == 1:
				if r.randf() < 0.25:
					k.box_mm(c + Vector3(-0.3, 0, -0.3), c + Vector3(0.3, 0.003, 0.3), "l4_grille", GeoKit.NY, false)
				continue
			var dead := r.randf() < (0.7 if dim else 0.16)
			var flick := 0.8 if r.randf() < 0.04 else 0.0
			k.panel(c, 0.6, 1.2, "l4_panel", 100.0 + i if dead else float(i * 11 + j * 3), flick)
			if not dead and (i % 2 == 0) and (j % 2 == 0):
				lvl.lights.add_anchor(c + Vector3.DOWN * 0.75, Color(0.92, 0.96, 1.0), 0.95, 5.8, flick, group)


func _conference(k: GeoKit, node: Node3D, o: Vector3, y: float, r: RandomNumberGenerator, group: String) -> void:
	var x0 := 10.8
	var z0 := 10.8
	var x1 := 21.6
	var z1 := 19.2
	_wall(k, o, y, Vector2(x0, z0), Vector2(x1, z0), [], [], 0.0)
	_wall(k, o, y, Vector2(x0, z1), Vector2(x1, z1), [{"at": 2.0, "w": P.DOOR_W, "h": P.DOOR_H}], [], 0.0, [[2.0, -1.0]])
	_wall(k, o, y, Vector2(x0, z0 - T * 0.5), Vector2(x0, z1 + T * 0.5), [{"at": 4.2, "w": 1.8, "h": P.DOOR_H}], [], 0.0, [[4.2, 0.0]])
	_wall(k, o, y, Vector2(x1, z0 - T * 0.5), Vector2(x1, z1 + T * 0.5), [], [], 0.0)
	# the one piece of furniture nobody took: the conference table
	var c := o + Vector3((x0 + x1) * 0.5, y, (z0 + z1) * 0.5)
	k.box(c + Vector3(0, 0.74, 0), Vector3(5.2, 0.05, 1.3), "l4_table")
	for s in [-1.0, 1.0]:
		k.box(c + Vector3(s * 2.0, 0.36, 0), Vector3(0.12, 0.72, 0.9), "l4_rail", GeoKit.ALL, false)
	k.box(o + Vector3(x1 - T * 0.5 - 0.02, y + 1.45, (z0 + z1) * 0.5), Vector3(0.03, 1.1, 2.4), "l4_white", GeoKit.ALL, false)
	k.box(o + Vector3(x1 - T * 0.5 - 0.04, y + 0.88, (z0 + z1) * 0.5), Vector3(0.06, 0.04, 2.4), "l4_alu", GeoKit.ALL, false)
	k.box(o + Vector3(x0 + 0.3, y + 2.66, (z0 + z1) * 0.5), Vector3(0.12, 0.12, 2.6), "l4_beige", GeoKit.ALL, false)
	for q in 4:
		var p := o + Vector3(x0 + 2.7 + (q % 2) * 5.4, y + CH - 0.004, z0 + 2.1 + (q / 2) * 4.2)
		var dead := r.randf() < 0.2
		k.panel(p, 0.6, 1.2, "l4_panel", 100.0 if dead else float(q * 9), 0.0)
		if not dead and q % 3 == 0:
			lvl.lights.add_anchor(p + Vector3.DOWN * 0.75, Color(0.92, 0.96, 1.0), 1.0, 5.5, 0.0, group)


func _dispensers(k: GeoKit, node: Node3D, o: Vector3, y: float, r: RandomNumberGenerator, meta: Dictionary, xs: Array, z: float, n: Vector3) -> void:
	if xs.is_empty():
		return
	var count := 1 if r.randf() < 0.55 else 2
	var used := []
	for i in count:
		var x: float = xs[r.randi() % xs.size()]
		if used.has(x):
			continue
		used.append(x)
		var t := r.randf()
		var kind := "cooler" if t < 0.5 else ("vending" if t < 0.8 else "fountain")
		var c: Vector3 = parts.dispenser(k, kind, o + Vector3(x + (0.55 if kind == "vending" else 0.25), y, z), n)
		meta["dispensers"].append({"kind": kind, "pos": c})
		lvl.register_dispenser(node, kind, c, "%d:%d:%d:%d" % [int(o.x), int(o.z), int(y), i])


func _clutter(k: GeoKit, o: Vector3, y: float, R: Rect2, r: RandomNumberGenerator, area: Rect2) -> void:
	for i in r.randi() % 3:
		var p := Vector2(r.randf_range(area.position.x + 1.0, area.end.x - 1.0), r.randf_range(area.position.y + 1.0, area.end.y - 1.0))
		if R.grow(0.8).has_point(p):
			continue
		var c := o + Vector3(p.x, y, p.y)
		match r.randi() % 3:
			0:
				k.box(c + Vector3(0, 0.18, 0), Vector3(0.52, 0.36, 0.4), "l4_cardboard")
			1:
				# a ceiling tile pushed out of its grid; cable hangs from the void
				k.box_mm(c + Vector3(-0.3, CH - 0.002, -0.3), c + Vector3(0.3, CH, 0.3), "l4_dark", GeoKit.NY, false)
				k.box(c + Vector3(0.1, CH - 0.45, 0.05), Vector3(0.02, 0.9, 0.02), "l4_dark", GeoKit.ALL, false)
				k.box(c + Vector3(0.4, 0.01, -0.2), Vector3(0.6, 0.015, 0.6), "l4_ceiling", GeoKit.ALL, false)
			_:
				k.box(c + Vector3(0, 0.003, 0), Vector3(0.14, 0.006, 0.14), "l4_alu", GeoKit.ALL, false)


# ------------------------------------------------------ vertical kinds

func _exit_stair(k: GeoKit, node: Node3D, o: Vector3, R: Rect2, dest: String, meta: Dictionary) -> void:
	var style := "old" if dest == "L004>L005#1" else ("dark" if dest == "L004>L006#2" else "basement")
	var sf := P.fr(o + Vector3(R.position.x, 0, R.position.y), Vector3.RIGHT, Vector3.BACK)
	var dk := GeoKit.new(node, "ExitDoor")
	var sw: Dictionary = parts.stairwell(k, node, sf, 0.0, false, style, [])
	var d: Dictionary = sw["doors"][0]
	P.door_trim(dk, d["a"], d["b"], d["at"], P.DOOR_W, P.DOOR_H, "l4_oldwood" if style == "old" else "l4_frame", "l4_oldwood" if style == "old" else "l4_firedoor", 1.0)
	if style == "basement":
		P.label(dk.root, "BASEMENT", d["a"] + Vector3(d["at"], 2.32, -T * 0.5 - 0.01), Vector3.FORWARD, 0.0024, Color(0.12, 0.12, 0.12))
	else:
		P.exit_sign(dk, dk.root, d["a"], d["b"], d["at"], 2.38, -1.0)
	dk.commit()
	var bottom: Vector3 = sw["bottom"]
	var tr: ExitTrigger = lvl.make_exit(dest, "walk_in", bottom + Vector3(0, 1.0, 0), Vector3(2.0, 2.0, 1.3), "", node)
	if style == "old":
		var ol := OmniLight3D.new()
		ol.light_color = Color(1.0, 0.66, 0.36)
		ol.light_energy = 0.9
		ol.omni_range = 4.0
		node.add_child(ol)
		ol.global_position = bottom + Vector3(0, 0.6, -1.0)
	if tr:
		meta["exits"].append({"trig": tr, "id": dest, "pos": d["a"] + Vector3(d["at"], 1.3, -0.25), "zone": Rect2(o.x + R.position.x, o.z + R.position.y, 4.8, 6.6),
			"seal": {"a": d["a"], "b": d["b"], "at": d["at"], "w": P.DOOR_W, "y": 0.0}, "door": dk.root})


func _atrium(k: GeoKit, node: Node3D, o: Vector3, R: Rect2, sunken: bool, group: String) -> void:
	var x0 := o.x + R.position.x
	var z0 := o.z + R.position.y
	var x1 := o.x + R.end.x
	var z1 := o.z + R.end.y
	var y: float = FY[1]
	# slab edge fascia and the glass balustrade around the gallery
	for e in [[Vector3(x0, 0, z0), Vector3(x1, 0, z0)], [Vector3(x1, 0, z0), Vector3(x1, 0, z1)], [Vector3(x1, 0, z1), Vector3(x0, 0, z1)], [Vector3(x0, 0, z1), Vector3(x0, 0, z0)]]:
		var a: Vector3 = e[0]
		var b: Vector3 = e[1]
		var mn := Vector3(minf(a.x, b.x) - 0.03, CH, minf(a.z, b.z) - 0.03)
		var mx := Vector3(maxf(a.x, b.x) + 0.03, y, maxf(a.z, b.z) + 0.03)
		k.box_mm(mn, mx, "l4_wall", GeoKit.ALL, false)
		k.box_mm(Vector3(mn.x, y, mn.z), Vector3(mx.x, y + 1.0, mx.z), "l4_glass", GeoKit.ALL, true)
		k.box_mm(Vector3(mn.x - 0.02, y + 1.0, mn.z - 0.02), Vector3(mx.x + 0.02, y + 1.06, mx.z + 0.02), "l4_rail", GeoKit.ALL, false)
	# high ceiling lights over the void
	for j in int(R.size.y / 2.4):
		for i in int(R.size.x / 2.4):
			var c := Vector3(x0 + 1.2 + i * 2.4, y + CH - 0.004, z0 + 1.2 + j * 2.4)
			k.panel(c, 0.6, 1.2, "l4_panel", float(i + j * 5), 0.0)
			if (i + j) % 2 == 0:
				lvl.lights.add_anchor(c + Vector3.DOWN * 1.1, Color(0.92, 0.96, 1.0), 1.5, 9.0, 0.0, group)
	if sunken:
		var pit := Rect2(x0 + 1.2, z0 + 1.2, R.size.x - 2.4, R.size.y - 2.4)
		var dep := 0.72
		k.box_mm(Vector3(pit.position.x, -dep - 0.3, pit.position.y), Vector3(pit.end.x, -dep, pit.end.y), "l4_carpet_corr", GeoKit.PY)
		var sx := pit.position.x + pit.size.x * 0.5
		k.box_mm(Vector3(pit.position.x, -dep, pit.position.y - 0.1), Vector3(sx - 1.2, 0.0, pit.position.y), "l4_wall", GeoKit.PZ)
		k.box_mm(Vector3(sx + 1.2, -dep, pit.position.y - 0.1), Vector3(pit.end.x, 0.0, pit.position.y), "l4_wall", GeoKit.PZ)
		k.box_mm(Vector3(pit.position.x, -dep, pit.end.y), Vector3(pit.end.x, 0.0, pit.end.y + 0.1), "l4_wall", GeoKit.NZ)
		k.box_mm(Vector3(pit.position.x - 0.1, -dep, pit.position.y), Vector3(pit.position.x, 0.0, pit.end.y), "l4_wall", GeoKit.PX)
		k.box_mm(Vector3(pit.end.x, -dep, pit.position.y), Vector3(pit.end.x + 0.1, 0.0, pit.end.y), "l4_wall", GeoKit.NX)
		k.stairs(Vector3(sx, -dep, pit.position.y + 4 * 0.3), Vector3.FORWARD, 2.4, dep, 4, "l4_carpet_corr", 0.3, true)
		# a drinking fountain on the sunken floor's far wall
		var c: Vector3 = parts.dispenser(k, "fountain", Vector3(sx + 1.8, -dep, pit.end.y), Vector3.FORWARD)
		lvl.register_dispenser(node, "fountain", c, "atr:%d:%d" % [int(o.x), int(o.z)])


func _well(k: GeoKit, node: Node3D, o: Vector3, R: Rect2, r: RandomNumberGenerator, meta: Dictionary, forced: bool) -> void:
	var x0 := o.x + R.position.x
	var z0 := o.z + R.position.y
	var x1 := o.x + R.end.x
	var z1 := o.z + R.end.y
	var ctr := Vector3((x0 + x1) * 0.5, 0, (z0 + z1) * 0.5)
	var sides := [[Vector3(x0 - T * 0.5, 0, z0), Vector3(x1 + T * 0.5, 0, z0)], [Vector3(x1, 0, z0), Vector3(x1, 0, z1)],
		[Vector3(x0 - T * 0.5, 0, z1), Vector3(x1 + T * 0.5, 0, z1)], [Vector3(x0, 0, z0), Vector3(x0, 0, z1)]]
	var ats := [1.3, 3.65, 6.0]
	for si in 4:
		var a: Vector3 = sides[si][0]
		var b: Vector3 = sides[si][1]
		var dir := (b - a).normalized()
		var inn := (ctr - (a + b) * 0.5)
		inn.y = 0.0
		inn = inn.normalized()
		var bas := Basis(dir, Vector3.UP, dir.cross(Vector3.UP))
		for f in 2:
			var base: float = FY[f] - (0.3 if f == 0 else 0.0)
			var sill: float = 0.9 + (0.3 if f == 0 else 0.0)
			var ops: Array = []
			for at in ats:
				ops.append({"at": at, "w": 1.9, "h": 1.5, "sill": sill})
			k.wall(a + Vector3.UP * base, b + Vector3.UP * base, P.FH + (0.3 if f == 0 else 0.0), 0.2, "l4_facade", ops, GeoKit.ALL)
			for wi in ats.size():
				var at: float = ats[wi]
				var pc: Vector3 = a + dir * at + Vector3.UP * (FY[f] + 0.9 + 0.75)
				var clear := r.randf() < 0.2 or (forced and f == 1 and si == 0 and wi == 1)
				k.box_xf(Transform3D(bas, pc), Vector3(1.9, 1.5, 0.03), "l4_glass" if clear else "l4_blackglass", GeoKit.ALL, true)
				for s in [-1.0, 1.0]:
					k.box_xf(Transform3D(bas, pc + dir * (s * 0.97)), Vector3(0.06, 1.56, 0.24), "l4_alu", GeoKit.ALL, false)
				k.box_xf(Transform3D(bas, pc + Vector3.DOWN * 0.78 - inn * 0.12), Vector3(1.98, 0.04, 0.2), "l4_alu", GeoKit.ALL, false)
				if clear:
					meta["windows"].append({"pos": pc, "n": -inn})
		# the shaft keeps going: more storeys above and below, out of reach
		var mid := (a + b) * 0.5 + inn * 0.101
		var half := (b - a).length() * 0.5
		k.quad(mid + Vector3.UP * 22.0, inn, dir * half, Vector3.UP * 14.8, "l4_facade")
		k.quad(mid + Vector3.UP * -15.3, inn, dir * half, Vector3.UP * 15.0, "l4_facade")
		for lv in range(-8, 10):
			if lv == 0 or lv == 1:
				continue
			for at in ats:
				var lit := h01(int(a.x * 10.0 + at), lv, si + 17) < 0.11
				k.quad(a + dir * at + Vector3.UP * (lv * P.FH + 1.65) + inn * 0.105, inn, dir * 0.95, Vector3.UP * 0.75, "l4_litwin" if lit else "l4_blackglass")
	k.box_mm(Vector3(x0, -31.0, z0), Vector3(x1, -30.0, z1), "void_black", GeoKit.PY, false)
