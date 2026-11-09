extends RefCounted
## Level 49 trench grammar. Each 32 m chunk is a 16 x 16 grid of 2 m cells.
## Trenches (one cell = 2 m wide, floor at FLOOR) are carved from a node near
## the chunk centre out to the crossing cell of every open edge, with random
## lateral jogs (the traverses that make WWI trenches zig-zag). Everything not
## carved is earth up to ground level (y = 0), where no man's land begins.
## Features: emplacement (3 x 3, covered, with a high fire-step), artillery
## station (3 x 4 pit with mortars), dugout bunker (stair down to a timbered
## room at UFLOOR), collapsed bunker. The Gutter Bunkers live in chunk (0,0).

const CHUNK := 32.0
const CELL := 2.0
const NC := 16
const FLOOR := -2.4
const EARTH_BOTTOM := -2.6
const UFLOOR := -5.2
const UCEIL := -2.95
const STAIR_ROOF := -0.35
const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var seed_value := 0


func _init(s: int) -> void:
	seed_value = s


func h(parts: Array) -> int:
	return absi(hash(parts + [seed_value]))


# ---------------------------------------------------------------- edges

## Is the edge between (cx, cz) and its east neighbour open? Row cz = 0 is a
## continuous fire trench; otherwise about three edges in five are open.
func open_e(cx: int, cz: int) -> bool:
	return cz == 0 or h([cx, cz, "e"]) % 100 < 58


## Edge between (cx, cz) and its south neighbour: every third column is a
## communication trench running the whole way.
func open_s(cx: int, cz: int) -> bool:
	return posmod(cx, 3) == 0 or h([cx, cz, "s"]) % 100 < 52


func cross_e(cx: int, cz: int) -> int:
	return 8 if cz == 0 else 4 + h([cx, cz, "ex"]) % 8


func cross_s(cx: int, cz: int) -> int:
	return 4 + h([cx, cz, "sx"]) % 8


## Open sides of a chunk: {dir index: crossing cell}
func doors(cx: int, cz: int) -> Dictionary:
	var d := {}
	if open_e(cx, cz):
		d[0] = Vector2i(NC - 1, cross_e(cx, cz))
	if open_e(cx - 1, cz):
		d[1] = Vector2i(0, cross_e(cx - 1, cz))
	if open_s(cx, cz):
		d[2] = Vector2i(cross_s(cx, cz), NC - 1)
	if open_s(cx, cz - 1):
		d[3] = Vector2i(cross_s(cx, cz - 1), 0)
	return d


# ---------------------------------------------------------------- carving

## Returns the layout: {cells: {Vector2i: type}, doors, node, feature, ...}
## types: t trench, w wide, s stair, r room, u tunnel, c culvert, x collapsed
func layout(cx: int, cz: int) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = h([cx, cz, "lay"])
	var dr := doors(cx, cz)
	var cells := {}
	var out := {"cells": cells, "doors": dr, "bunkers": [], "feature": "none", "stairs": []}
	if dr.is_empty():
		return out
	var gutter := cx == 0 and cz == 0
	var node := Vector2i(6 + r.randi() % 4, 6 + r.randi() % 4)
	if gutter:
		node = Vector2i(7, 8)
		for i in range(1, NC - 1):
			cells[Vector2i(i, 8)] = "t"
	out["node"] = node
	cells[node] = "t"
	if gutter:
		_gutter(out)
		# north and south paths leave along columns kept clear of the dugouts
		for j in range(1, 8):
			cells[Vector2i(NC - 2, j)] = "t"
		for j in range(9, NC - 1):
			cells[Vector2i(1, j)] = "t"
		var starts := {0: Vector2i(NC - 2, 8), 1: Vector2i(1, 8), 2: Vector2i(1, NC - 2), 3: Vector2i(NC - 2, 1)}
		for k in dr:
			_walk(cells, starts[k], dr[k], r)
		return out
	for k in dr:
		_walk(cells, node, dr[k], r)
	var roll := r.randi() % 100
	if roll < 22:
		out["feature"] = "emplacement"
		_wide(cells, node, Vector2i(3, 3))
	elif roll < 40:
		out["feature"] = "artillery"
		_wide(cells, node, Vector2i(3, 4))
	elif roll < 52:
		out["feature"] = "collapsed"
	if roll >= 40 or r.randf() < 0.35:
		var b := _bunker(cells, r)
		if not b.is_empty():
			if out["feature"] == "collapsed":
				b["collapsed"] = true
			out["bunkers"].append(b)
			if out["feature"] == "none":
				out["feature"] = "bunker"
	return out


func _walk(cells: Dictionary, from: Vector2i, to: Vector2i, r: RandomNumberGenerator) -> void:
	var p := from
	var guard := 0
	while p != to and guard < 200:
		guard += 1
		var dx := to.x - p.x
		var dz := to.y - p.y
		var primary_x := absi(dx) >= absi(dz)
		var prim := absi(dx) if primary_x else absi(dz)
		var lat := absi(dz) if primary_x else absi(dx)
		var step := Vector2i.ZERO
		if prim > lat + 2 and r.randf() < 0.28:
			# a traverse jog sideways, staying inside the chunk
			var s := 1 if r.randf() < 0.5 else -1
			step = Vector2i(0, s) if primary_x else Vector2i(s, 0)
			var q := p + step
			if q.x < 1 or q.x > NC - 2 or q.y < 1 or q.y > NC - 2:
				step = Vector2i.ZERO
		if step == Vector2i.ZERO:
			if prim > 0 and (prim > lat or lat == 0):
				step = Vector2i(signi(dx), 0) if primary_x else Vector2i(0, signi(dz))
			else:
				step = Vector2i(0, signi(dz)) if primary_x else Vector2i(signi(dx), 0)
		p += step
		if not cells.has(p):
			cells[p] = "t"


func _wide(cells: Dictionary, c: Vector2i, size: Vector2i) -> void:
	for i in size.x:
		for j in size.y:
			var p := c + Vector2i(i - size.x / 2, j - size.y / 2)
			if p.x >= 1 and p.x <= NC - 2 and p.y >= 1 and p.y <= NC - 2:
				cells[p] = "w"


func _free(cells: Dictionary, p: Vector2i) -> bool:
	if p.x < 1 or p.x > NC - 2 or p.y < 1 or p.y > NC - 2:
		return false
	return not cells.has(p)


## Find a trench cell and a direction with room for a stair and a 3 x 2 room.
func _bunker(cells: Dictionary, r: RandomNumberGenerator) -> Dictionary:
	var keys := cells.keys()
	keys.sort()
	for tries in 40:
		var t: Vector2i = keys[r.randi() % keys.size()]
		if cells[t] != "t":
			continue
		var d: Vector2i = DIRS[r.randi() % 4]
		var lat := Vector2i(d.y, d.x)
		var need := [t + d, t + d * 2]
		for k: int in [3, 4]:
			for l: int in [-1, 0, 1]:
				need.append(t + d * k + lat * l)
		var ok := true
		for p in need:
			if not _free(cells, p):
				ok = false
				break
		# keep a ring of earth round the room
		if ok:
			for l: int in [-2, 2]:
				for k: int in [3, 4]:
					if cells.has(t + d * k + lat * l):
						ok = false
			for l: int in [-1, 0, 1]:
				if cells.has(t + d * 5 + lat * l):
					ok = false
		if not ok:
			continue
		cells[t + d] = "s"
		cells[t + d * 2] = "s"
		var room: Array = []
		for k: int in [3, 4]:
			for l: int in [-1, 0, 1]:
				cells[t + d * k + lat * l] = "r"
				room.append(t + d * k + lat * l)
		return {"t": t, "d": d, "room": room}
	return {}


## Chunk (0,0): the M.E.G. "Gutter Bunkers", three dugouts off the fire trench
## joined underground, and a drainage culvert that floods.
func _gutter(out: Dictionary) -> void:
	var cells: Dictionary = out["cells"]
	out["feature"] = "gutter"
	var d := Vector2i(0, -1)
	for bx: int in [3, 7, 11]:
		var t := Vector2i(bx, 8)
		cells[t + d] = "s"
		cells[t + d * 2] = "s"
		var room: Array = []
		for k: int in [3, 4]:
			for l: int in [-1, 0, 1]:
				cells[t + d * k + Vector2i(l, 0)] = "r"
				room.append(t + d * k + Vector2i(l, 0))
		out["bunkers"].append({"t": t, "d": d, "room": room, "gutter": true})
	# the tunnel joining the three rooms (row 4, between them)
	for x: int in [5, 9]:
		cells[Vector2i(x, 4)] = "u"
	# a low drainage culvert under the south wall near the east end
	cells[Vector2i(13, 9)] = "c"
	cells[Vector2i(13, 10)] = "c"
	out["culvert"] = [Vector2i(13, 8), Vector2i(13, 9), Vector2i(13, 10)]


static func cpos(c: Vector2i, y: float = 0.0) -> Vector3:
	return Vector3(c.x * CELL + CELL * 0.5, y, c.y * CELL + CELL * 0.5)


static func is_open(t: String) -> bool:
	return t == "t" or t == "w"


# ---------------------------------------------------------------- geometry

func build(k: GeoKit, lay: Dictionary, r: RandomNumberGenerator) -> Dictionary:
	var cells: Dictionary = lay["cells"]
	var dr: Dictionary = lay["doors"]
	var info := {"walls": [], "floor_cells": []}
	_earth(k, cells)
	var entrances := {}
	for b in lay["bunkers"]:
		entrances[[b["t"], b["d"]]] = true
	var keys := cells.keys()
	keys.sort()
	for c: Vector2i in keys:
		var t: String = cells[c]
		if not is_open(t):
			continue
		var p := cpos(c)
		info["floor_cells"].append(c)
		# mud floor, duckboards on most cells
		k.box_mm(Vector3(p.x - 1.0, EARTH_BOTTOM, p.z - 1.0), Vector3(p.x + 1.0, FLOOR, p.z + 1.0), "l49_mud_floor")
		var along_x := cells.has(c + Vector2i(1, 0)) or cells.has(c + Vector2i(-1, 0))
		if r.randf() < 0.72:
			_duckboard(k, p, along_x, r)
		for di in 4:
			var dv: Vector2i = DIRS[di]
			var n := c + dv
			var nt: String = cells.get(n, "")
			if is_open(nt):
				continue
			if n.x < 0 or n.x >= NC or n.y < 0 or n.y >= NC:
				if dr.has(di) and dr[di] == c:
					continue
			if entrances.has([c, dv]):
				continue
			if nt == "c":
				continue
			_revetment(k, p, dv, r, t == "w")
			info["walls"].append([c, di])
	return info


## Earth between the trenches, merged into row runs; stair cells only carry
## a thin roof; culvert cells leave a low passage under them.
func _earth(k: GeoKit, cells: Dictionary) -> void:
	for j in NC:
		var i := 0
		while i < NC:
			var t: String = cells.get(Vector2i(i, j), "")
			if is_open(t):
				i += 1
				continue
			var bottom := _bottom(t)
			var i1 := i
			while i1 + 1 < NC:
				var t2: String = cells.get(Vector2i(i1 + 1, j), "")
				if is_open(t2) or _bottom(t2) != bottom:
					break
				i1 += 1
			var mn := Vector3(i * CELL, bottom, j * CELL)
			var mx := Vector3((i1 + 1) * CELL, 0.0, (j + 1) * CELL)
			k.box_mm(mn, mx, "l49_mud_wall", GeoKit.SIDES | GeoKit.NY, true)
			k.box_mm(Vector3(mn.x, -0.01, mn.z), mx, "l49_ground", GeoKit.PY, false)
			i = i1 + 1


func _bottom(t: String) -> float:
	if t == "s":
		return STAIR_ROOF
	if t == "c":
		return FLOOR + 1.25
	return EARTH_BOTTOM


func _duckboard(k: GeoKit, p: Vector3, along_x: bool, r: RandomNumberGenerator) -> void:
	var y := FLOOR + 0.06
	var yaw := 0.0 if along_x else PI * 0.5
	var b := Basis(Vector3.UP, yaw + r.randf_range(-0.05, 0.05))
	for s: float in [-0.42, 0.42]:
		k.box_xf(Transform3D(b, p + Vector3(0, y - 0.03, 0) + b.z * s), Vector3(2.0, 0.06, 0.08), "l49_board_dark", GeoKit.ALL, false)
	var n := 9
	for i in n:
		var x := -0.9 + i * 1.8 / (n - 1)
		if r.randf() < 0.08:
			continue
		k.box_xf(Transform3D(b * Basis(Vector3.UP, r.randf_range(-0.06, 0.06)), p + Vector3(0, y + 0.02, 0) + b.x * x), Vector3(0.12, 0.03, 1.05), "l49_board", GeoKit.ALL, false)
	k.add_box_shape(Transform3D(b, p + Vector3(0, y - 0.02, 0)), Vector3(2.0, 0.08, 1.05), "wood")


## One 2 m wall face on side `dv` of a trench cell: planks, corrugated iron or
## sandbags, with the parapet sandbags and sometimes wire on top.
func _revetment(k: GeoKit, p: Vector3, dv: Vector2i, r: RandomNumberGenerator, wide: bool) -> void:
	var n := Vector3(dv.x, 0, dv.y)
	var t := Vector3(-dv.y, 0, dv.x)
	var face := p + n * 0.94
	var b := Basis(t, Vector3.UP, -n)
	var hh := -FLOOR
	var style := r.randi() % 3
	if r.randf() < 0.18:
		# a bare stretch: the revetment has rotted away, only a post or two left
		k.box(face + t * r.randf_range(-0.8, 0.8) + Vector3(0, FLOOR + 0.9, 0) - n * 0.05, Vector3(0.12, 1.8, 0.12), "l49_post", GeoKit.ALL, false)
		style = -1
	match style:
		-1:
			pass
		0:  # planks between posts
			var y := FLOOR + 0.12
			while y < -0.05:
				var ph := r.randf_range(0.2, 0.28)
				k.box_xf(Transform3D(b * Basis(Vector3.BACK, r.randf_range(-0.03, 0.03)), face + Vector3(0, y + ph * 0.5, 0) + t * r.randf_range(-0.05, 0.05)), Vector3(2.0, ph - 0.02, 0.05), "l49_plank", GeoKit.ALL, false)
				y += ph
		1:  # corrugated iron sheets, one bent
			for s: float in [-0.5, 0.5]:
				var lean := r.randf_range(-0.05, 0.08)
				k.box_xf(Transform3D(b * Basis(Vector3.RIGHT, lean), face + t * s + Vector3(0, FLOOR + hh * 0.5, 0) - n * 0.02), Vector3(1.0, hh - 0.1, 0.03), "l49_iron", GeoKit.ALL, false)
		_:  # sandbag wall
			var y := FLOOR
			var row := 0
			while y < -0.1:
				var off := 0.25 if row % 2 == 1 else 0.0
				var x := -1.0 + off
				while x < 1.0:
					var w := minf(0.5, 1.0 - x)
					if w > 0.12:
						var bc := face + t * (x + w * 0.5) + Vector3(0, y + 0.1, 0) - n * r.randf_range(0.0, 0.05)
						k.box_xf(Transform3D(b, bc), Vector3(w - 0.03, 0.15, 0.3), "l49_bag", GeoKit.ALL, false)
						k.box_xf(Transform3D(b, bc + Vector3(0, 0.08, 0)), Vector3(w - 0.1, 0.05, 0.22), "l49_bag", GeoKit.ALL, false)
					x += 0.5
				y += 0.21
				row += 1
	# posts
	if style == 0 or style == 1:
		for s: float in [-0.95, 0.95]:
			k.box(face + t * s + Vector3(0, FLOOR + hh * 0.5 + 0.1, 0) - n * 0.08, Vector3(0.12, hh + 0.3, 0.12), "l49_post", GeoKit.ALL, false)
	# parapet: two rows of sandbags along the lip, on the earth
	for row in 2:
		var x := -1.0 + (0.25 if row == 1 else 0.0)
		while x < 1.0:
			var w := minf(0.5, 1.0 - x)
			if w > 0.12:
				var pb := b * Basis(Vector3.UP, r.randf_range(-0.08, 0.08))
				var pc := p + n * (1.2 + row * 0.05) + t * (x + w * 0.5) + Vector3(0, 0.08 + row * 0.19, 0)
				k.box_xf(Transform3D(pb, pc), Vector3(w - 0.03, 0.15, 0.34), "l49_bag", GeoKit.ALL, false)
				k.box_xf(Transform3D(pb, pc + Vector3(0, 0.085, 0)), Vector3(w - 0.1, 0.05, 0.26), "l49_bag", GeoKit.ALL, false)
			x += 0.5
	# rusted, tangled wire on pickets behind some stretches
	if r.randf() < 0.42:
		var back := p + n * 2.6
		for s: float in [-1.0, 0.0, 1.0]:
			k.box(back + t * s + Vector3(0, 0.55, 0), Vector3(0.05, 1.1, 0.05), "l49_rust", GeoKit.ALL, false)
		for i in 7:
			var y := 0.15 + i * 0.14
			var a := back + t * -1.0 + Vector3(0, y, 0) + n * r.randf_range(-0.2, 0.2)
			var e := back + t * 1.0 + Vector3(0, y + r.randf_range(-0.12, 0.12), 0) + n * r.randf_range(-0.2, 0.2)
			var dirv := (e - a)
			k.box_xf(Transform3D(Basis.looking_at(dirv.normalized(), Vector3.UP), (a + e) * 0.5), Vector3(0.012, 0.012, dirv.length()), "l49_rust", GeoKit.ALL, false)
