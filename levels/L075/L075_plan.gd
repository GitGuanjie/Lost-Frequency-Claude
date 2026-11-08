extends RefCounted
## Level 75 layout: a seeded spanning-tree complex of painted rooms and corridors on a
## 6 x 5 grid of 9 m cells, with occasional loops, split floor levels (0.54 m apart,
## joined by three sand-covered steps at the doorway), windows between rooms that are not
## joined, sand-choked doorways on the outer walls, and one sand-free room.

const NX := 6
const NZ := 5
const S := 9.0
const T := 0.2
const CEIL := 4.6
const STEP := 0.54

var rng: RandomNumberGenerator
var cells: Dictionary = {}        # Vector2i -> {kind, level, paint, peel, links: {dir: true}}
var links: Dictionary = {}        # "a|b" -> {door_off, wide}
var start := Vector2i(0, 2)
var exit_cell := Vector2i(-1, -1)
var exit_side := Vector2i.ZERO
var dist: Dictionary = {}

const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


func _init(r: RandomNumberGenerator) -> void:
	rng = r


static func key(a: Vector2i, b: Vector2i) -> String:
	if a.x < b.x or (a.x == b.x and a.y < b.y):
		return "%d,%d|%d,%d" % [a.x, a.y, b.x, b.y]
	return "%d,%d|%d,%d" % [b.x, b.y, a.x, a.y]


func inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < NX and c.y < NZ


func linked(a: Vector2i, b: Vector2i) -> bool:
	return links.has(key(a, b))


func centre(c: Vector2i) -> Vector3:
	return Vector3((c.x + 0.5) * S, floor_y(c), (c.y + 0.5) * S)


func floor_y(c: Vector2i) -> float:
	return float(cells[c]["level"]) * STEP if cells.has(c) else 0.0


func cell_at(p: Vector3) -> Vector2i:
	return Vector2i(clampi(floori(p.x / S), 0, NX - 1), clampi(floori(p.z / S), 0, NZ - 1))


func plan() -> void:
	for x in NX:
		for z in NZ:
			var roll := rng.randf()
			var paint := "blue" if roll < 0.45 else ("cream" if roll < 0.88 else "red")
			cells[Vector2i(x, z)] = {"kind": "room", "level": 0, "paint": paint,
				"peel": "steel" if rng.randf() < 0.35 else "plaster", "links": {}}
	start = Vector2i(0, NZ / 2)
	# spanning tree by randomised DFS; the start is a dead-end corridor opening east
	var visited := {start: true}
	_link(start, start + Vector2i(1, 0))
	cells[start + Vector2i(1, 0)]["level"] = 0
	var stack: Array = [start + Vector2i(1, 0)]
	visited[start + Vector2i(1, 0)] = true
	while not stack.is_empty():
		var c: Vector2i = stack[stack.size() - 1]
		var opts: Array = []
		for d in DIRS:
			var n: Vector2i = c + d
			if inside(n) and not visited.has(n):
				opts.append(n)
		if opts.is_empty():
			stack.pop_back()
			continue
		var n2: Vector2i = opts[rng.randi() % opts.size()]
		visited[n2] = true
		var lv := int(cells[c]["level"]) + [-1, 0, 0, 1][rng.randi() % 4]
		cells[n2]["level"] = clampi(lv, -1, 2)
		_link(c, n2)
		stack.append(n2)
	# a few short loops, only between cells one step apart in height
	for i in 6:
		var a := Vector2i(1 + rng.randi() % (NX - 1), rng.randi() % NZ)
		var d2: Vector2i = DIRS[rng.randi() % 4]
		var b := a + d2
		if inside(b) and b != start and a != start and not linked(a, b) and absi(int(cells[a]["level"]) - int(cells[b]["level"])) <= 1:
			_link(a, b)
	# corridors: cells joined only along one axis (straight through or dead end)
	for c in cells.keys():
		var ls: Dictionary = cells[c]["links"]
		var xs := ls.has(Vector2i(1, 0)) or ls.has(Vector2i(-1, 0))
		var zs := ls.has(Vector2i(0, 1)) or ls.has(Vector2i(0, -1))
		if c == start or ((xs != zs) and rng.randf() < 0.55):
			cells[c]["kind"] = "corridor"
			cells[c]["axis"] = "x" if xs else "z"
	# breadth-first distances from the start
	dist = {start: 0}
	var q: Array = [start]
	while not q.is_empty():
		var c2: Vector2i = q.pop_front()
		for d3 in cells[c2]["links"].keys():
			var n3: Vector2i = c2 + d3
			if not dist.has(n3):
				dist[n3] = int(dist[c2]) + 1
				q.append(n3)
	# the sand-free room: the far boundary room with the longest route
	var best := -1
	for c in cells.keys():
		var on_edge: bool = c.x == NX - 1 or c.y == 0 or c.y == NZ - 1
		if not on_edge or c.x < 3:
			continue
		var dd: int = dist.get(c, 0)
		if dd > best:
			best = dd
			exit_cell = c
	cells[exit_cell]["kind"] = "room"
	cells[exit_cell]["paint"] = "cream"
	cells[exit_cell]["peel"] = "plaster"
	cells[exit_cell]["clean"] = true
	if exit_cell.x == NX - 1:
		exit_side = Vector2i(1, 0)
	elif exit_cell.y == 0:
		exit_side = Vector2i(0, -1)
	else:
		exit_side = Vector2i(0, 1)
	# door offsets along each wall; corridors take their doorways on their centre line
	for kk in links.keys():
		var parts: PackedStringArray = (kk as String).split("|")
		var pa := parts[0].split(",")
		var pb := parts[1].split(",")
		var a2 := Vector2i(int(pa[0]), int(pa[1]))
		var b2 := Vector2i(int(pb[0]), int(pb[1]))
		var corr: bool = cells[a2]["kind"] == "corridor" or cells[b2]["kind"] == "corridor"
		var both_corr: bool = cells[a2]["kind"] == "corridor" and cells[b2]["kind"] == "corridor"
		links[kk] = {"off": 0.0 if corr else rng.randf_range(-2.4, 2.4), "w": 2.6 if both_corr else (1.2 if corr or rng.randf() < 0.6 else 2.2)}


func _link(a: Vector2i, b: Vector2i) -> void:
	links[key(a, b)] = {}
	cells[a]["links"][b - a] = true
	cells[b]["links"][a - b] = true


func paint_mat(c: Vector2i) -> String:
	return "l75_%s_%s" % [cells[c]["paint"], "s" if cells[c]["peel"] == "steel" else "p"]


# ------------------------------------------------------------------ geometry

## Build the shell: floors, sand, walls (each side painted for its own room), doorways
## with steps between levels, windows, ceilings, corridor partitions, outer walls.
func build(k: GeoKit, sandk: GeoKit) -> Dictionary:
	var info := {"stairs": [], "windows": [], "choked": [], "doors": []}
	for c in cells.keys():
		_floor(k, sandk, c)
	# internal edges
	for x in NX:
		for z in NZ:
			var c := Vector2i(x, z)
			for d in [Vector2i(1, 0), Vector2i(0, 1)]:
				var n: Vector2i = c + d
				if inside(n):
					_edge(k, c, n, d, info)
	# outer walls, with sand-choked doorways
	for x in NX:
		_outer(k, Vector2i(x, 0), Vector2i(0, -1), info)
		_outer(k, Vector2i(x, NZ - 1), Vector2i(0, 1), info)
	for z in NZ:
		_outer(k, Vector2i(0, z), Vector2i(-1, 0), info)
		_outer(k, Vector2i(NX - 1, z), Vector2i(1, 0), info)
	# corridor partitions and their dropped ceilings
	for c in cells.keys():
		if cells[c]["kind"] == "corridor":
			_corridor(k, c)
	k.slab(-0.3, -0.3, NX * S + 0.3, NZ * S + 0.3, CEIL + 0.3, 0.3, "l75_ceiling")
	return info


func _floor(k: GeoKit, sandk: GeoKit, c: Vector2i) -> void:
	var y := floor_y(c)
	var x0 := c.x * S
	var z0 := c.y * S
	k.slab(x0, z0, x0 + S, z0 + S, y, 1.2 + y, "l75_floor" if not cells[c].get("clean", false) else "l75_clean", GeoKit.PY,
		"tile" if cells[c].get("clean", false) else "sand")
	if cells[c].get("clean", false):
		return
	# the sand layer: thick, nearly wall to wall, ragged at the edges
	var ins := [rng.randf_range(0.1, 0.7), rng.randf_range(0.1, 0.7), rng.randf_range(0.1, 0.7), rng.randf_range(0.1, 0.7)]
	sandk.box_mm(Vector3(x0 + ins[0], y, z0 + ins[2]), Vector3(x0 + S - ins[1], y + 0.05, z0 + S - ins[3]), "l75_sand", GeoKit.PY | GeoKit.SIDES, false)
	for i in 6:
		var px := rng.randf_range(x0 + 0.2, x0 + S - 0.2)
		var pz := rng.randf_range(z0 + 0.2, z0 + S - 0.2)
		var w := rng.randf_range(0.5, 1.6)
		sandk.box_xf(Transform3D(Basis(Vector3.UP, rng.randf() * TAU), Vector3(px, y + 0.03, pz)), Vector3(w, 0.06, w * 0.6), "l75_sand", GeoKit.PY | GeoKit.SIDES, false)


func _edge(k: GeoKit, a: Vector2i, b: Vector2i, d: Vector2i, info: Dictionary) -> void:
	var ya := floor_y(a)
	var yb := floor_y(b)
	var y0 := minf(ya, yb) - 0.6
	var top := CEIL
	var p0: Vector3
	var p1: Vector3
	var n := Vector3(d.x, 0, d.y)         # from a toward b
	if d.x == 1:
		p0 = Vector3(b.x * S, y0, a.y * S)
		p1 = Vector3(b.x * S, y0, (a.y + 1) * S)
	else:
		p0 = Vector3(a.x * S, y0, b.y * S)
		p1 = Vector3((a.x + 1) * S, y0, b.y * S)
	var ops: Array = []
	var mid := S * 0.5
	if linked(a, b):
		var l: Dictionary = links[key(a, b)]
		var hi := maxf(ya, yb)
		var at: float = mid + float(l["off"])
		ops.append({"at": at, "w": float(l["w"]), "h": 2.25, "sill": hi - y0})
		var along := (p1 - p0).normalized()
		var dp := p0 + along * at
		dp.y = hi
		info["doors"].append({"pos": dp, "n": n, "w": float(l["w"]), "a": a, "b": b})
		if absf(ya - yb) > 0.01:
			# three steps up inside the lower cell
			var low_is_a := ya < yb
			var dirn := n if low_is_a else -n
			var start_p := dp - dirn * (T * 0.5 + 0.9)
			start_p.y = minf(ya, yb)
			info["stairs"].append({"start": start_p, "dir": dirn, "w": float(l["w"]), "rise": absf(ya - yb)})
	elif cells[a]["kind"] == "room" and cells[b]["kind"] == "room" and rng.randf() < 0.32:
		var hi2 := maxf(ya, yb)
		var at2 := mid + rng.randf_range(-2.4, 2.4)
		ops.append({"at": at2, "w": rng.randf_range(1.0, 1.8), "h": 1.15, "sill": hi2 + 1.1 - y0})
		var along2 := (p1 - p0).normalized()
		info["windows"].append({"pos": p0 + along2 * at2 + Vector3(0, hi2 + 1.1 - y0, 0), "n": n})
	var ha := top - y0
	# two half-thickness skins so each room keeps its own paint
	var off := n * (T * 0.25)
	k.wall(p0 - off, p1 - off, ha, T * 0.5, paint_mat(a), ops)
	k.wall(p0 + off, p1 + off, ha, T * 0.5, paint_mat(b), ops)


func _outer(k: GeoKit, c: Vector2i, d: Vector2i, info: Dictionary) -> void:
	var y := floor_y(c)
	var y0 := y - 0.6
	var p0: Vector3
	var p1: Vector3
	if d.x != 0:
		var x := (c.x + (1 if d.x > 0 else 0)) * S
		p0 = Vector3(x, y0, c.y * S)
		p1 = Vector3(x, y0, (c.y + 1) * S)
	else:
		var z := (c.y + (1 if d.y > 0 else 0)) * S
		p0 = Vector3(c.x * S, y0, z)
		p1 = Vector3((c.x + 1) * S, y0, z)
	var ops: Array = []
	var along := (p1 - p0).normalized()
	var n := Vector3(d.x, 0, d.y)
	if c == exit_cell and d == exit_side:
		# the ordinary door out, and a window beside it
		ops.append({"at": S * 0.5 - 1.2, "w": 1.0, "h": 2.1, "sill": y - y0})
		ops.append({"at": S * 0.5 + 1.6, "w": 1.5, "h": 1.3, "sill": y - y0 + 0.95})
		info["exit_door"] = p0 + along * (S * 0.5 - 1.2) + Vector3(0, y - y0, 0)
		info["exit_window"] = p0 + along * (S * 0.5 + 1.6) + Vector3(0, y - y0 + 0.95, 0)
		info["exit_n"] = n
	elif c == start and d == Vector2i(-1, 0):
		ops.append({"at": S * 0.5, "w": 2.6, "h": 2.4, "sill": y - y0})
		info["choked"].append({"pos": p0 + along * (S * 0.5) + Vector3(0, y - y0, 0), "n": n, "w": 2.6})
	elif cells[c]["kind"] == "room" and rng.randf() < 0.3:
		var at := S * 0.5 + rng.randf_range(-2.0, 2.0)
		ops.append({"at": at, "w": 1.2, "h": 2.2, "sill": y - y0})
		info["choked"].append({"pos": p0 + along * at + Vector3(0, y - y0, 0), "n": n, "w": 1.2})
	k.wall(p0 + n * (T * 0.25), p1 + n * (T * 0.25), CEIL - y0, T * 0.5, paint_mat(c), ops)


func _corridor(k: GeoKit, c: Vector2i) -> void:
	var y := floor_y(c)
	var cc := centre(c)
	var half := 1.3
	var mat := paint_mat(c)
	var hgt := 2.95
	if cells[c]["axis"] == "x":
		for s in [-1.0, 1.0]:
			k.wall(Vector3(c.x * S + 0.1, y - 0.3, cc.z + s * (half + 0.1)), Vector3((c.x + 1) * S - 0.1, y - 0.3, cc.z + s * (half + 0.1)), CEIL - y + 0.3, T, mat)
		k.box_mm(Vector3(c.x * S + 0.1, y + hgt, cc.z - half), Vector3((c.x + 1) * S - 0.1, y + hgt + 0.12, cc.z + half), "l75_ceiling_low", GeoKit.ALL, false)
	else:
		for s in [-1.0, 1.0]:
			k.wall(Vector3(cc.x + s * (half + 0.1), y - 0.3, c.y * S + 0.1), Vector3(cc.x + s * (half + 0.1), y - 0.3, (c.y + 1) * S - 0.1), CEIL - y + 0.3, T, mat)
		k.box_mm(Vector3(cc.x - half, y + hgt, c.y * S + 0.1), Vector3(cc.x + half, y + hgt + 0.12, (c.y + 1) * S - 0.1), "l75_ceiling_low", GeoKit.ALL, false)


## Walkable bounds of a cell's floor (rooms: inside the walls; corridors: the hallway).
func walk_rect(c: Vector2i) -> Rect2:
	var cc := centre(c)
	if cells[c]["kind"] == "corridor":
		if cells[c]["axis"] == "x":
			return Rect2(c.x * S + 0.4, cc.z - 1.0, S - 0.8, 2.0)
		return Rect2(cc.x - 1.0, c.y * S + 0.4, 2.0, S - 0.8)
	return Rect2(c.x * S + 0.6, c.y * S + 0.6, S - 1.2, S - 1.2)


func ceil_y(c: Vector2i) -> float:
	return floor_y(c) + 2.95 if cells[c]["kind"] == "corridor" else CEIL
