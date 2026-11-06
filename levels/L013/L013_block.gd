extends RefCounted
## Level 13 streamed apartment grammar (ADAPTATION: the page gives no map).
## Each 24 m chunk owns two halls (local north z 0..2 and west x 0..2) and a
## 22 x 22 block: column A (flats facing the west hall or the spine), a spine
## hall, column B (flats facing the spine) and column C (flats facing the next
## chunk's west hall), plus an optional cross hall from the west hall to the
## spine. Chunks are randomly transposed (floor-independent), so door-lined
## strands run both ways and the plan never settles into a grid. Two storeys
## (y 0 and y 3) are walkable. About half the chunks hold a stair core
## (switchback stair with an open well + lift lobby) at a floor-independent
## position, so climbing past the storeys re-floors everything around it.

const P := preload("res://levels/L013/L013_parts.gd")
const CS := 24.0
const CW := 2.0
const FH := P.FH
const CH := P.CH
const T := P.T
const BLAND := ["L013>L000#1", "L013>L114#2", "L013>L327#3", "L013>L395#4", "L013>L410#5"]

var lvl: Node3D
var parts: RefCounted
var _tr := false       # current chunk transposed (local x <-> z)
var _o := Vector3.ZERO


func _init(level: Node3D, p: RefCounted) -> void:
	lvl = level
	parts = p


func h01(a: int, b: int, salt: Variant) -> float:
	return float(absi(hash([lvl.level_seed, a, b, salt])) % 100003) / 100003.0


# ------------------------------------------------------------ mapping

func transposed(cx: int, cz: int) -> bool:
	if absi(cx) <= 2 and (cz == 0 or cz == -1):
		return true       # authored: the long hall the player starts in runs along world x
	return h01(cx, cz, "tr") < 0.5


## Chunk-local (x, y, z) to world.
func w(x: float, y: float, z: float) -> Vector3:
	return _o + (Vector3(z, y, x) if _tr else Vector3(x, y, z))


func wd(d: Vector2) -> Vector3:
	return Vector3(d.y, 0, d.x) if _tr else Vector3(d.x, 0, d.y)


func wr(r: Rect2) -> Rect2:
	if _tr:
		return Rect2(_o.x + r.position.y, _o.z + r.position.x, r.size.y, r.size.x)
	return Rect2(_o.x + r.position.x, _o.z + r.position.y, r.size.x, r.size.y)


func bmm(k: GeoKit, a: Vector3, b: Vector3, mat: String, faces := GeoKit.ALL, collide := true) -> void:
	var p := w(a.x, a.y, a.z)
	var q := w(b.x, b.y, b.z)
	k.box_mm(Vector3(minf(p.x, q.x), minf(p.y, q.y), minf(p.z, q.z)), Vector3(maxf(p.x, q.x), maxf(p.y, q.y), maxf(p.z, q.z)), mat, faces, collide)


## World position of a chunk-local point (for the level script and QA).
func local_to_world(key: Vector2i, x: float, y: float, z: float) -> Vector3:
	var o := Vector3(key.x * CS, 0, key.y * CS)
	return o + (Vector3(z, y, x) if transposed(key.x, key.y) else Vector3(x, y, z))


# ------------------------------------------------------------ plans

## Floor-independent: does the chunk hold a stair core, and where.
func core_plan(cx: int, cz: int) -> Dictionary:
	if cx == 0 and cz == 0:
		return {"core": true, "zc": 11.0, "endless": false, "down": "L013>L070#6"}
	var core := h01(cx, cz, "core") < 0.55
	var zc: float = [6.2, 11.0, 14.6][int(h01(cx, cz, "zc") * 3.0) % 3]
	var endless: bool = core and not lvl.qa_fixture and h01(cx, cz, "endless") < 0.09
	return {"core": core, "zc": zc, "endless": endless, "down": "L013>L070#6" if h01(cx, cz, "down") < 0.5 else "L013>L208#7"}


## Per-storey layout plan.
func plan(cx: int, cz: int, s: int) -> Dictionary:
	var cp := core_plan(cx, cz)
	var r := RandomNumberGenerator.new()
	r.seed = hash([lvl.level_seed, "plan", cx, cz, lvl.floor_base, s])
	var anchor: bool = cx == 0 and cz == 0 and lvl.floor_base == lvl.start_base
	var da: float = [6.2, 6.6, 7.0][r.randi() % 3]
	var db: float = [6.2, 6.6, 7.0][r.randi() % 3]
	var zx := -1.0
	if r.randf() < 0.4:
		zx = [8.0, 12.0, 16.0][r.randi() % 3]
		if cp["core"] and zx + CW > cp["zc"] - 4.2 and zx < cp["zc"] + 5.2:
			zx = -1.0
	var wall: String = "l13_wall_beige" if h01(cx, cz + s * 7, "paint" + str(lvl.floor_base)) < 0.55 else "l13_wall_white"
	var corr: String = "l13_lino" if h01(cx, cz + s * 7, "floor" + str(lvl.floor_base)) < 0.5 else "l13_lam"
	if anchor:
		da = 6.6
		db = 6.6
		zx = -1.0
		wall = "l13_wall_beige"
		corr = "l13_lam"
	var sx := CW + da
	return {"core": cp, "sx": sx, "xc": sx + CW + db, "zx": zx, "wall": wall, "corr": corr, "anchor": anchor, "r": r}


# ------------------------------------------------------------------ chunk

func build_chunk(cx: int, cz: int, node: Node3D) -> Dictionary:
	var group := "%d,%d" % [cx, cz]
	node.set_meta("group", group)
	_o = Vector3(cx * CS, 0, cz * CS)
	_tr = transposed(cx, cz)
	var meta := {"apts": [], "duds": [], "exits": [], "tvdoors": [], "knocks": [], "core": core_plan(cx, cz), "lifts": []}
	var k := GeoKit.new(node, "K")
	for s in 2:
		_storey(k, node, cx, cz, s, meta, group)
	var cp: Dictionary = meta["core"]
	if cp["core"]:
		_core(k, node, cx, cz, cp, meta, group, plan(cx, cz, 0)["wall"])
	k.commit()
	return meta


func _line(a: Vector2, b: Vector2, n: Vector2) -> Dictionary:
	return {"a": a, "b": b, "n": n, "ops": [], "doors": []}


func _storey(k: GeoKit, node: Node3D, cx: int, cz: int, s: int, meta: Dictionary, group: String) -> void:
	var pl := plan(cx, cz, s)
	var r: RandomNumberGenerator = pl["r"]
	var y := s * FH
	var sx: float = pl["sx"]
	var zx: float = pl["zx"]
	var cp: Dictionary = pl["core"]
	var zc: float = cp["zc"]
	var wmat: String = pl["wall"]
	var corr: String = pl["corr"]
	# ---- floors and ceiling (the corridor/block rects are symmetric under transposition)
	var holes := [wr(Rect2(4.0, zc, 3.0, 5.2))] if cp["core"] else []
	var corrs := [Rect2(_o.x, _o.z, CS, CW), Rect2(_o.x, _o.z + CW, CW, CS - CW)]
	var block := [Rect2(_o.x + CW, _o.z + CW, CS - CW, CS - CW)]
	for rr in corrs:
		k.box_mm(Vector3(rr.position.x, y - 0.3, rr.position.y), Vector3(rr.end.x, y, rr.end.y), corr, GeoKit.PY)
	for rrv in _cut(block, holes):
		var rr: Rect2 = rrv
		k.box_mm(Vector3(rr.position.x, y - 0.3, rr.position.y), Vector3(rr.end.x, y, rr.end.y), "l13_lam", GeoKit.PY)
	for rrv in _cut(corrs + block, holes):
		var rr: Rect2 = rrv
		k.box_mm(Vector3(rr.position.x, y + CH, rr.position.y), Vector3(rr.end.x, y + CH + 0.05, rr.end.y), "l13_ceiling", GeoKit.NY, false)
	bmm(k, Vector3(sx, y + 0.002, CW), Vector3(sx + CW, y + 0.012, CS), corr, GeoKit.PY, false)
	if zx > 0.0:
		bmm(k, Vector3(CW, y + 0.002, zx), Vector3(sx, y + 0.012, zx + CW), corr, GeoKit.PY, false)
	# ---- wall lines (chunk-local 2D); n = corridor-side normal
	var L := {}
	L["N"] = _line(Vector2(CW, CW), Vector2(CS, CW), Vector2(0, -1))
	L["W"] = _line(Vector2(CW, CW), Vector2(CW, CS), Vector2(-1, 0))
	L["E"] = _line(Vector2(CS, CW), Vector2(CS, CS), Vector2(1, 0))
	L["S"] = _line(Vector2(CW, CS), Vector2(CS, CS), Vector2(0, 1))
	L["SW"] = _line(Vector2(sx, CW), Vector2(sx, CS), Vector2(1, 0))
	L["SE"] = _line(Vector2(sx + CW, CW), Vector2(sx + CW, CS), Vector2(-1, 0))
	var sp_op := {"at": sx - CW + CW * 0.5, "w": CW - T, "h": CH, "sill": 0.0}
	L["N"]["ops"].append(sp_op)
	L["S"]["ops"].append(sp_op.duplicate())
	if zx > 0.0:
		L["XN"] = _line(Vector2(CW, zx), Vector2(sx, zx), Vector2(0, 1))
		L["XS"] = _line(Vector2(CW, zx + CW), Vector2(sx, zx + CW), Vector2(0, -1))
		L["W"]["ops"].append({"at": zx + 1.0 - CW, "w": CW - T, "h": CH, "sill": 0.0})
		L["SW"]["ops"].append({"at": zx + 1.0 - CW, "w": CW - T, "h": CH, "sill": 0.0})
	if cp["core"]:
		L["W"]["ops"].append({"at": zc - 1.0 - CW, "w": 2.0 - T, "h": CH, "sill": 0.0})
	if pl["anchor"] and s == 0:
		# authored, along the start hall: a deeper-yellow wall (Level 289) and a plain
		# door out (Level 0) where the stair core leaves dead space behind the plaster;
		# a dud yellow wall round the corner (repeated failure = wrong wall)
		L["W"]["ops"].append({"at": zc + 2.6 - CW, "w": 0.86, "h": 2.04, "sill": 0.0})
		L["W"]["doors"].append({"at": zc + 2.6 - CW, "kind": "bland", "num": "", "edge": "L013>L000#1"})
		L["W"]["doors"].append({"at": zc - 3.1 - CW, "kind": "yellow", "real": true})
		L["N"]["doors"].append({"at": 12.0, "kind": "yellow", "real": false})
	# ---- lots
	var lots := _lots(pl, r)
	var sp := _specials(cx, cz, s, pl)
	for i in lots.size():
		var lot: Dictionary = lots[i]
		lot["num"] = "%d%02d" % [lvl.floor_base + s, i + 1]
		_place_lot(k, node, y, lot, L, r, sp, meta, cx, cz, s, i, group, pl)
	# ---- party walls (column cuts) and the column B | C back-to-back wall
	for pw in _party(pl, lots):
		P.wall(k, w(pw[0].x, y, pw[0].y), w(pw[1].x, y, pw[1].y), CH, T, wmat, [])
	# ---- build lines
	for key in L:
		var ln: Dictionary = L[key]
		var a := w(ln["a"].x, y, ln["a"].y)
		var b := w(ln["b"].x, y, ln["b"].y)
		P.wall(k, a, b, CH, T, wmat, ln["ops"])
		var n3 := wd(ln["n"])
		P.baseboard(k, a, b, n3, ln["ops"])
		for d in ln["doors"]:
			_door_detail(k, node, a, b, n3, d, meta, group)
	# ---- hall lights
	_lights(k, Vector2(1.2, 1.0), Vector2(1, 0), 24.0, y, r, group)
	_lights(k, Vector2(1.0, 4.6), Vector2(0, 1), 19.0, y, r, group)
	_lights(k, Vector2(sx + 1.0, 3.4), Vector2(0, 1), 20.0, y, r, group)
	if zx > 0.0:
		_lights(k, Vector2(CW + 2.0, zx + 1.0), Vector2(1, 0), sx - CW - 2.5, y, r, group)


static func _cut(rects: Array, holes: Array) -> Array:
	var out := rects
	for h in holes:
		var hh: Rect2 = h
		var nxt: Array = []
		for rrv in out:
			var rr: Rect2 = rrv
			if not rr.intersects(hh):
				nxt.append(rr)
				continue
			var i := rr.intersection(hh)
			if i.position.x > rr.position.x + 0.001:
				nxt.append(Rect2(rr.position.x, rr.position.y, i.position.x - rr.position.x, rr.size.y))
			if i.end.x < rr.end.x - 0.001:
				nxt.append(Rect2(i.end.x, rr.position.y, rr.end.x - i.end.x, rr.size.y))
			if i.position.y > rr.position.y + 0.001:
				nxt.append(Rect2(i.position.x, rr.position.y, i.size.x, i.position.y - rr.position.y))
			if i.end.y < rr.end.y - 0.001:
				nxt.append(Rect2(i.position.x, i.end.y, i.size.x, rr.end.y - i.end.y))
		out = nxt
	return out


func _lights(k: GeoKit, start: Vector2, dir: Vector2, len: float, y: float, r: RandomNumberGenerator, group: String) -> void:
	var n := int(len / 3.6) + 1
	var d3 := wd(dir)
	for i in n:
		var q := start + dir * (i * 3.6)
		var p := w(q.x, y + CH, q.y)
		var dead := r.randf() < 0.17
		k.cylinder(p + Vector3.DOWN * 0.05, 0.17, 0.09, "l13_dome_dead" if dead else "l13_dome", 8, false, true)
		if not dead and i % 2 == 0:
			lvl.lamp(p + Vector3.DOWN * 0.35, Color(1.0, 0.84, 0.62), 1.0, 4.8, 0.08 if r.randf() < 0.15 else 0.0, group, int(round(y / FH)))
		if i % 3 == 1:
			k.box(p + d3 * 1.8 + Vector3.DOWN * 0.02, Vector3(0.11, 0.035, 0.11), "l13_trim", GeoKit.ALL & ~GeoKit.PY, false)   # smoke detector


# ------------------------------------------------------------------- lots

## Lots per column: {rect (local), fronts: [[line key, weight]], col}.
func _lots(pl: Dictionary, r: RandomNumberGenerator) -> Array:
	var sx: float = pl["sx"]
	var xc: float = pl["xc"]
	var zx: float = pl["zx"]
	var cp: Dictionary = pl["core"]
	var out: Array = []
	var cols := [[CW, sx], [sx + CW, xc], [xc, CS]]
	for col in 3:
		var x0: float = cols[col][0]
		var x1: float = cols[col][1]
		var spans: Array = [[CW, CS]]
		if col == 0 and cp["core"]:
			spans = [[CW, cp["zc"] - 4.2], [cp["zc"] + 5.2, CS]]
		elif col == 0 and zx > 0.0:
			spans = [[CW, zx], [zx + CW, CS]]
		for sp in spans:
			var z0: float = sp[0]
			var z1: float = sp[1]
			if z1 - z0 < 3.0:
				continue
			var n := maxi(1, int(round((z1 - z0) / 5.3)))
			var zs: Array = [z0]
			for j in range(1, n):
				zs.append(snappedf(z0 + (z1 - z0) * j / n + r.randf_range(-0.5, 0.5), 0.1))
			zs.append(z1)
			for j in n:
				var rect := Rect2(x0, zs[j], x1 - x0, zs[j + 1] - zs[j])
				var fr: Array = []
				match col:
					0:
						fr = [["W", 3.0], ["SW", 2.0]]
						if zx > 0.0 and absf(rect.end.y - zx) < 0.01:
							fr.append(["XN", 3.0])
						if zx > 0.0 and absf(rect.position.y - zx - CW) < 0.01:
							fr.append(["XS", 3.0])
					1:
						fr = [["SE", 4.0]]
					2:
						fr = [["E", 4.0]]
				if absf(rect.position.y - CW) < 0.01:
					fr.append(["N", 1.0])
				if absf(rect.end.y - CS) < 0.01:
					fr.append(["S", 1.0])
				out.append({"rect": rect, "fronts": fr, "col": col, "first": j == 0, "z0": z0})
	return out


## Party walls: every lot boundary inside a column, the B|C back wall, the core.
func _party(pl: Dictionary, lots: Array) -> Array:
	var out: Array = []
	var seen := {}
	var zx: float = pl["zx"]
	if zx > 0.0:
		seen["0:%.2f" % zx] = true
		seen["0:%.2f" % (zx + CW)] = true
	for lot in lots:
		var rc: Rect2 = lot["rect"]
		for z in [rc.position.y, rc.end.y]:
			var key := "%d:%.2f" % [lot["col"], z]
			if z > CW + 0.01 and z < CS - 0.01 and not seen.has(key):
				seen[key] = true
				out.append([Vector2(rc.position.x, z), Vector2(rc.end.x, z)])
	out.append([Vector2(pl["xc"], CW), Vector2(pl["xc"], CS)])
	var cp: Dictionary = pl["core"]
	if cp["core"]:
		out.append([Vector2(7.0, cp["zc"] - 4.2), Vector2(7.0, cp["zc"] + 5.2)])
		for z in [cp["zc"] - 4.2, cp["zc"] + 5.2]:
			if not seen.has("0:%.2f" % z):
				out.append([Vector2(CW, z), Vector2(pl["sx"], z)])
	return out


## Rare sourced features for this chunk storey (streamed exits are off in QA).
func _specials(cx: int, cz: int, s: int, pl: Dictionary) -> Dictionary:
	var sp := {}
	if pl["anchor"] or lvl.qa_fixture:
		return sp
	var h := func(salt: String) -> float: return h01(cx * 977 + lvl.floor_base, cz * 131 + s, salt)
	if h.call("bland") < 0.16:
		sp["bland"] = BLAND[int(h.call("bdest") * 5.0) % 5]
	if h.call("red") < 0.045:
		sp["red"] = true
	if h.call("235") < 0.02:
		sp["d235"] = true
	if h.call("yellow") < 0.11:
		sp["yellow"] = h.call("yreal") < 0.45
	if h.call("chess") < 0.06:
		sp["chess"] = true
	return sp


func _pick(fr: Array, r: RandomNumberGenerator) -> String:
	var tot := 0.0
	for f in fr:
		tot += float(f[1])
	var x := r.randf() * tot
	for f in fr:
		x -= float(f[1])
		if x <= 0.0:
			return f[0]
	return fr[0][0]


func _place_lot(k: GeoKit, node: Node3D, y: float, lot: Dictionary, L: Dictionary, r: RandomNumberGenerator, sp: Dictionary, meta: Dictionary, cx: int, cz: int, s: int, idx: int, group: String, pl: Dictionary) -> void:
	var rect: Rect2 = lot["rect"]
	var fk := _pick(lot["fronts"], r)
	var anchor_open := false
	if pl["anchor"] and lot["col"] == 0:
		fk = "W"
		anchor_open = s == 0 and lot["first"] and lot["z0"] > 12.0
	var ln: Dictionary = L[fk]
	var la: Vector2 = ln["a"]
	var lb: Vector2 = ln["b"]
	var dirl := (lb - la).normalized()
	var s0 := (rect.position - la).dot(dirl)
	var s1 := (rect.end - la).dot(dirl)
	var lo := minf(s0, s1)
	var hi := maxf(s0, s1)
	var W := hi - lo
	var D := rect.size.x if absf(dirl.y) > 0.5 else rect.size.y
	var right := r.randf() < 0.5
	if anchor_open:
		right = false
	var at := (hi - 0.8) if right else (lo + 0.8)
	var deep := D >= 6.2 and W >= 4.4
	var wide := not deep and W >= 7.6 and D >= 4.6
	var inhabited := r.randf() < 0.42 or not (deep or wide)
	if pl["anchor"] and s == 0 and lot["col"] == 0:
		inhabited = not anchor_open
	var kind := "closed" if inhabited else "open"
	var number: String = lot["num"]
	if inhabited and sp.has("red") and not sp.has("red_done"):
		kind = "red"
		number = ""
		sp["red_done"] = true
	elif inhabited and sp.has("d235") and not sp.has("d235_done"):
		number = "235"
		sp["d235_done"] = true
	ln["ops"].append({"at": at, "w": P.DW, "h": P.DH, "sill": 0.0})
	ln["doors"].append({"at": at, "kind": kind, "num": number, "inhab": inhabited, "tv": inhabited and r.randf() < 0.3})
	# a second feature along an inhabited front: an exit door or a deeper-yellow wall
	var free_at := (lo + 1.6) if right else (hi - 1.6)
	if inhabited and W >= 4.2:
		if sp.has("bland") and not sp.has("bland_done"):
			sp["bland_done"] = true
			ln["ops"].append({"at": free_at, "w": 0.86, "h": 2.04, "sill": 0.0})
			ln["doors"].append({"at": free_at, "kind": "bland", "num": "", "edge": sp["bland"]})
		elif sp.has("yellow") and not sp.has("yellow_done"):
			sp["yellow_done"] = true
			ln["doors"].append({"at": free_at, "kind": "yellow", "real": sp["yellow"]})
	if inhabited:
		return
	# ---- an empty flat: furnished interior in a canonical frame (door near its origin)
	var n2: Vector2 = ln["n"]
	var inward := wd(-n2)
	var u3 := wd(dirl)
	var origin := w(la.x, y, la.y) + u3 * (lo + T * 0.5) + inward * (T * 0.5)
	var f := P.fr(origin, u3, inward)
	var Din := D - T
	W -= T
	var apt_id := "%d:%d,%d:%d:%d" % [lvl.floor_base, cx, cz, s, idx]
	var chess: bool = sp.has("chess") and not sp.has("chess_done") and Din >= 6.0
	if chess:
		sp["chess_done"] = true
	var g: Dictionary
	var gw: float
	var gd: float
	if deep:
		g = P.fr(P.fp(f, W, 0, 0), -u3, inward) if right else f
		gw = W
		gd = Din
	else:
		g = P.fr(P.fp(f, W, 0, 0), inward, -u3) if right else P.fr(origin, inward, u3)
		gw = Din
		gd = W
	var info: Dictionary = lvl.interior.build(k, node, g, gw, gd, r, apt_id, group, chess, anchor_open)
	info["rect"] = wr(rect)
	info["y"] = y
	info["id"] = apt_id
	meta["apts"].append(info)


func _door_detail(k: GeoKit, node: Node3D, a: Vector3, b: Vector3, n: Vector3, d: Dictionary, meta: Dictionary, group: String) -> void:
	var dir := (b - a).normalized()
	var at: float = d["at"]
	var c := a + dir * at
	var kind: String = d["kind"]
	if kind == "yellow":
		var bas := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
		k.box_xf(Transform3D(bas, c + Vector3.UP * (CH * 0.5) + n * (T * 0.5 + 0.006)), Vector3(2.2, CH - 0.02, 0.01), "l13_yellow", GeoKit.ALL, false)
		if d["real"]:
			var t: ExitTrigger = lvl.make_exit("L013>L289#11", "noclip", c + Vector3.UP * 1.0, Vector3(2.0, 2.0, 0.9) if absf(dir.x) > 0.5 else Vector3(0.9, 2.0, 2.0), "Push through the deeper-yellow wall", node)
			if t:
				t.hold_seconds = 2.6
				meta["exits"].append({"id": "L013>L289#11", "pos": c + n * 0.5})
		else:
			meta["duds"].append({"pos": c + Vector3.UP * 1.0, "n": n, "fails": 0, "hold": 0.0})
		return
	P.door(k, node, a, b, at, n, kind, d.get("num", ""), 0.86 if kind == "bland" else P.DW)
	var front := c + n * (T * 0.5 + 0.55)
	var edge := ""
	var prompt := ""
	match kind:
		"bland":
			edge = d["edge"]
			prompt = "Open the plain door"
		"red":
			edge = "L013>L275#10"
			prompt = "Open the red door"
		_:
			if d.get("num", "") == "235":
				edge = "L013>L235#9"
				prompt = "Try the door marked 235"
	if edge != "":
		var t2: ExitTrigger = lvl.make_exit(edge, "interact", front + Vector3.UP * 1.0, Vector3(1.2, 2.0, 1.2), prompt, node)
		if t2:
			meta["exits"].append({"id": edge, "pos": front})
	elif d.get("inhab", false):
		var bas2 := Basis(dir, Vector3.UP, dir.cross(Vector3.UP).normalized())
		k.box_xf(Transform3D(bas2, c + n * (T * 0.5 + 0.35) + Vector3.UP * 0.006), Vector3(0.8, 0.012, 0.5), "l13_mat", GeoKit.ALL, false)
		k.box_xf(Transform3D(bas2, c + n * (T * 0.5 + 0.03) + Vector3.UP * 0.008), Vector3(0.8, 0.012, 0.03), "l13_glow", GeoKit.ALL, false)
		lvl.add_knock(node, c + n * 0.3 + Vector3.UP * 1.2, d.get("tv", false), meta)
		if d.get("tv", false):
			meta["tvdoors"].append(c)


# ------------------------------------------------------------- stair core

func _core(k: GeoKit, node: Node3D, cx: int, cz: int, cp: Dictionary, meta: Dictionary, group: String, wmat: String) -> void:
	var zc: float = cp["zc"]
	var base: int = lvl.floor_base
	var endless: bool = cp["endless"]
	var s_lo := maxi(-2, -base)
	var s_hi := 3 if endless else mini(3, 290 - base)
	var stop_hi := not endless and s_hi == 290 - base
	var labels := {}
	for s in range(s_lo, s_hi + 2):
		labels[s] = "" if base + s <= 0 else str(base + s)
	var f := P.fr(w(4.0, 0, zc), wd(Vector2(1, 0)), wd(Vector2(0, 1)))
	parts.shaft(k, node, f, s_lo, s_hi, stop_hi, wmat, labels, group)
	meta["shaft"] = wr(Rect2(4.0, zc, 3.0, 5.2))
	meta["endless"] = endless
	var lz := zc - 2.0 + T * 0.5
	var into := wd(Vector2(0, 1))
	for s in range(s_lo, s_hi + 1):
		var y := s * FH
		var real := s == 0 or s == 1
		var ground := base + s <= 0
		var lm := "void_black" if ground else wmat
		if not real:
			# virtual storeys: a closed lobby seen only through the stair door
			bmm(k, Vector3(CW, y - 0.3, zc - 2.0), Vector3(7.0, y, zc), "void_black" if ground else "l13_lino_tile", GeoKit.PY)
			bmm(k, Vector3(CW, y + CH, zc - 2.0), Vector3(7.0, y + CH + 0.05, zc), "l13_ceiling", GeoKit.NY, false)
			P.wall(k, w(CW, y, zc - 2.0), w(CW, y, zc), CH, T, lm)
			P.wall(k, w(7.0, y, zc - 2.0), w(7.0, y, zc), CH, T, lm)
		else:
			bmm(k, Vector3(CW, y + 0.002, zc - 2.0), Vector3(7.0, y + 0.012, zc), "l13_lino_tile", GeoKit.PY, false)
		P.wall(k, w(CW, y, zc), w(4.0, y, zc), CH, T, lm)
		if ground:
			P.wall(k, w(CW, y, zc - 2.0), w(7.0, y, zc - 2.0), CH, T, "void_black")
			if base == 1 and s == -1:
				var t: ExitTrigger = lvl.make_exit(cp["down"], "walk_in", w(5.5, y + 1.0, zc - 1.0), Vector3(1.6, 2.0, 1.6), "", node)
				if t:
					meta["exits"].append({"id": cp["down"], "pos": w(5.5, y, zc - 0.9)})
			continue
		# lift doors in the lobby's far wall, call button, floor indicator
		P.wall(k, w(CW, y, zc - 2.0), w(7.0, y, zc - 2.0), CH, T, wmat, [{"at": 3.5, "w": 1.1, "h": P.DH, "sill": 0.0}])
		for sd in [-1.0, 1.0]:
			bmm(k, Vector3(5.5 + sd * 0.55 - 0.06, y, lz - 0.02), Vector3(5.5 + sd * 0.55 + 0.06, y + P.DH + 0.1, lz + 0.03), "l13_steel")
		bmm(k, Vector3(4.89, y + P.DH, lz - 0.02), Vector3(6.11, y + P.DH + 0.1, lz + 0.03), "l13_steel", GeoKit.ALL, false)
		bmm(k, Vector3(4.96, y, lz - T * 0.5 - 0.02), Vector3(5.49, y + P.DH, lz - 0.02), "l13_steel")
		bmm(k, Vector3(5.51, y, lz - T * 0.5 - 0.02), Vector3(6.04, y + P.DH, lz - 0.02), "l13_steel")
		bmm(k, Vector3(6.3, y + 1.0, lz), Vector3(6.42, y + 1.28, lz + 0.015), "l13_steel", GeoKit.ALL, false)
		bmm(k, Vector3(6.34, y + 1.1, lz + 0.015), Vector3(6.38, y + 1.14, lz + 0.022), "l13_led" if (cx + cz + s) % 3 != 0 else "l13_dark", GeoKit.ALL, false)
		bmm(k, Vector3(5.2, y + 2.28, lz), Vector3(5.8, y + 2.42, lz + 0.02), "l13_dark", GeoKit.ALL, false)
		P.label(node, str(base + s), w(5.5, y + 2.35, lz + 0.022), into, 0.0016, Color(1.0, 0.45, 0.2), 9.0)
		var lc := w(4.5, y + CH, zc - 1.0)
		k.cylinder(lc + Vector3.DOWN * 0.05, 0.17, 0.09, "l13_dome", 8, false)
		if s >= -1 and s <= 2:
			lvl.lamp(lc + Vector3.DOWN * 0.4, Color(1.0, 0.85, 0.65), 0.6, 3.4, 0.0, group, s)
		if real:
			var it: Interactable = lvl.add_lift(node, w(6.36, y + 1.14, lz + 0.1), Vector2i(cx, cz), s)
			meta["lifts"].append({"s": s, "pos": w(5.5, y, zc - 1.0), "it": it})
			if cx == 0 and cz == 0 and s == 0 and base == lvl.start_base:
				bmm(k, Vector3(CW + 0.6, y + 1.0, lz), Vector3(CW + 1.8, y + 1.8, lz + 0.03), "l13_cork", GeoKit.ALL, false)
				lvl.lobby_note(node, w(CW + 1.2, y + 1.4, lz + 0.05), into)
