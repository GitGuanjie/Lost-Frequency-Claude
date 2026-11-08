extends RefCounted
## Level 0.3 "The Icy Rooms": streamed room grammar (design notes in L000_3.gd).
## Each 24 m chunk is a Level 0 floor plan on a 3 m grid: a seeded partition into
## rectangular rooms and hallways, every pair of neighbouring rooms joined by a
## doorway, the chunk's west and north borders owned by the chunk itself.
## Room kinds: plain, ice (a giant cube that barely fits), pit (sunken room with an
## ice-sheet floor), duct (ceiling tiles stripped to the rusty ducts). Chunk (0,0)
## holds the abandoned task-force camp, chunk (-1,0) the two-storey duct hall.

const CS := 24.0
const CELL := 3.0
const N := 8
const H := 2.75           # Level 0 ceiling height
const HW := 3.75          # walls run up past the drop ceiling into the plenum
const T := 0.16
const PIT_Y := -0.54      # three 0.18 m risers
const UP := 3.24          # duct hall gallery (18 risers)
const TOP := 6.4          # duct hall roof
const DOOR_H := 2.15
const CAMP := Rect2i(2, 2, 4, 4)
const HALL := Vector2i(-1, 0)

var lvl
var seed_v := 0
var _doors: Array = []


func _init(level) -> void:
	lvl = level
	seed_v = level.level_seed


func h01(a: int, b: int, salt: int) -> float:
	return float(absi(hash([seed_v, a, b, salt])) % 100003) / 100003.0


## Remodel progress: the crew worked outward from their camp, so rooms near it
## carry the new wool carpet and wallpaper (both failing again); the rest is the
## original frozen state.
func remodelled(cx: int, cz: int) -> bool:
	if cx == 0 and cz == 0:
		return true
	if Vector2i(cx, cz) == HALL:
		return false
	return maxi(absi(cx), absi(cz)) <= 1 and h01(cx, cz, 31) < 0.6


func is_hall(cx: int, cz: int) -> bool:
	if Vector2i(cx, cz) == HALL:
		return true
	return maxi(absi(cx), absi(cz)) >= 3 and h01(cx, cz, 41) < 0.07


# ------------------------------------------------------------------ partition

func _split(rect: Rect2i, r: RandomNumberGenerator, out: Array) -> void:
	var w := rect.size.x
	var d := rect.size.y
	if (w <= 2 and d <= 2) or (w <= 3 and d <= 3 and r.randf() < 0.55) or (w * d <= 6 and r.randf() < 0.4):
		out.append(rect)
		return
	var along_x := w > d or (w == d and r.randf() < 0.5)
	var n := w if along_x else d
	if n < 2:
		along_x = not along_x
		n = w if along_x else d
	var cut := 1
	if n >= 4:
		cut = r.randi_range(2, n - 2)
		if r.randf() < 0.22:
			cut = 1 if r.randf() < 0.5 else n - 1   # a 3 m hallway
	elif n == 3:
		cut = 1 if r.randf() < 0.5 else 2
	if along_x:
		_split(Rect2i(rect.position.x, rect.position.y, cut, d), r, out)
		_split(Rect2i(rect.position.x + cut, rect.position.y, w - cut, d), r, out)
	else:
		_split(Rect2i(rect.position.x, rect.position.y, w, cut), r, out)
		_split(Rect2i(rect.position.x, rect.position.y + cut, w, d - cut), r, out)


## Room rects (cell units) and the id grid for one chunk.
func partition(cx: int, cz: int, r: RandomNumberGenerator) -> Dictionary:
	var rooms: Array = []
	if cx == 0 and cz == 0:
		rooms.append(CAMP)
		for rr in [Rect2i(0, 0, 8, 2), Rect2i(0, 6, 8, 2), Rect2i(0, 2, 2, 4), Rect2i(6, 2, 2, 4)]:
			_split(rr, r, rooms)
	else:
		_split(Rect2i(0, 0, N, N), r, rooms)
	var ids: Array = []
	ids.resize(N * N)
	for i in rooms.size():
		var rc: Rect2i = rooms[i]
		for x in range(rc.position.x, rc.end.x):
			for z in range(rc.position.y, rc.end.y):
				ids[z * N + x] = i
	return {"rooms": rooms, "ids": ids}


# ------------------------------------------------------------------ chunk

## Builds one chunk into `node`. Returns meta: vents, ducts, scraps, ice, pit,
## gallery and the world rect of every room (for dressing and QA).
func build_chunk(cx: int, cz: int, node: Node3D) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = hash([seed_v, cx, cz, "l03"])
	var ox := cx * CS
	var oz := cz * CS
	var rem := remodelled(cx, cz)
	var wall := "l03_wall_new" if rem else "l03_wall_frozen"
	var carpet := "l03_carpet_wool" if rem else "l03_carpet_frost"
	var grp := "%d,%d" % [cx, cz]
	_doors = []
	var meta := {"doors": _doors, "vents": [], "ducts": [], "scraps": [], "ice": [], "pits": [], "rooms": [], "lit": 0,
		"remodel": rem, "hall": false, "gallery": Vector3.ZERO, "items": []}
	var k := GeoKit.new(node, "K")
	var ice := GeoKit.new(node, "Ice")
	ice.shadows = false
	if is_hall(cx, cz):
		meta["hall"] = true
		_hall(k, ice, node, ox, oz, r, grp, meta)
		_border(k, cx, cz, "x", "l03_wall_frozen", TOP)
		_border(k, cx, cz, "z", "l03_wall_frozen", TOP)
		k.commit()
		ice.commit()
		return meta
	var part := partition(cx, cz, r)
	var rooms: Array = part["rooms"]
	var ids: Array = part["ids"]
	# room kinds
	var kinds: Array = []
	var has_pit := false
	var has_duct := false
	for i in rooms.size():
		var rc: Rect2i = rooms[i]
		var kind := "plain"
		var camp := cx == 0 and cz == 0 and i == 0
		if camp:
			kind = "camp"
		elif not rem and rc.size.x >= 2 and rc.size.y >= 2 and rc.size.x * rc.size.y <= 6 and r.randf() < 0.5:
			kind = "ice"
		elif not has_pit and rc.size.x >= 3 and rc.size.y >= 3 and r.randf() < 0.45:
			kind = "pit"
			has_pit = true
		elif not has_duct and maxi(rc.size.x, rc.size.y) >= 3 and r.randf() < 0.5:
			kind = "duct"
			has_duct = true
		kinds.append(kind)
		var wr := Rect2(ox + rc.position.x * CELL, oz + rc.position.y * CELL, rc.size.x * CELL, rc.size.y * CELL)
		meta["rooms"].append({"rect": wr, "kind": kind})
	# floors
	for i in rooms.size():
		var wr: Rect2 = meta["rooms"][i]["rect"]
		if kinds[i] == "pit":
			_pit(k, ice, wr, r, carpet, meta)
		else:
			k.box_mm(Vector3(wr.position.x, -0.3, wr.position.y), Vector3(wr.end.x, 0.0, wr.end.y), carpet, GeoKit.PY)
	# interior walls with a doorway for every neighbouring pair
	_inner_walls(k, ox, oz, ids, r, wall)
	_border(k, cx, cz, "x", wall, HW)
	_border(k, cx, cz, "z", wall, HW)
	# one vent per chunk (most chunks) pumps mist; other rooms get dead grilles
	var vent_room := -1
	if r.randf() < 0.8:
		var cand: Array = []
		for i in rooms.size():
			if kinds[i] in ["plain", "duct", "pit"]:
				cand.append(i)
		if not cand.is_empty():
			vent_room = cand[r.randi() % cand.size()]
	# ceilings, fixtures, ice, ducts
	for i in rooms.size():
		var wr: Rect2 = meta["rooms"][i]["rect"]
		var kind: String = kinds[i]
		if kind == "duct":
			_duct_room(k, node, wr, r, grp, meta)
		else:
			k.box_mm(Vector3(wr.position.x, H, wr.position.y), Vector3(wr.end.x, H + 0.12, wr.end.y), "l03_ceiling", GeoKit.NY, false)
			_fixtures(k, wr, r, grp, rem, kind, meta)
		if kind == "ice":
			_ice_cube(k, ice, wr, r, meta)
		elif kind == "plain" and rem and r.randf() < 0.35:
			_ice_remains(k, ice, wr, r)
		if i == vent_room or r.randf() < 0.5:
			_vent_grille(k, wr, r, meta, i == vent_room)
		if not rem:
			_scraps(k, node, wr, r, meta)
	k.commit()
	ice.commit()
	return meta


## Interior walls: merged runs along each grid line, one doorway per room pair.
func _inner_walls(k: GeoKit, ox: float, oz: float, ids: Array, r: RandomNumberGenerator, wall: String) -> void:
	for axis in ["x", "z"]:
		for line in range(1, N):
			var run0 := -1
			var ops: Array = []
			var seen: Dictionary = {}
			for t in range(0, N + 1):
				var differ := false
				var pair := ""
				if t < N:
					var a: int = ids[t * N + line - 1] if axis == "x" else ids[(line - 1) * N + t]
					var b: int = ids[t * N + line] if axis == "x" else ids[line * N + t]
					differ = a != b
					pair = "%d_%d" % [mini(a, b), maxi(a, b)]
				if differ and run0 < 0:
					run0 = t
					ops = []
				if differ:
					if not seen.has(pair):
						seen[pair] = [t]
					else:
						seen[pair].append(t)
				if (not differ or t == N) and run0 >= 0:
					for pk in seen.keys():
						var cells: Array = seen[pk]
						var pick: int = cells[r.randi() % cells.size()]
						ops.append(_door(pick - run0, r))
						if cells.size() >= 3 and r.randf() < 0.4:
							var pick2: int = cells[(cells.find(pick) + cells.size() / 2) % cells.size()]
							if absi(pick2 - pick) >= 2:
								ops.append(_door(pick2 - run0, r))
					var a3: Vector3
					var b3: Vector3
					if axis == "x":
						a3 = Vector3(ox + line * CELL, 0, oz + run0 * CELL)
						b3 = Vector3(ox + line * CELL, 0, oz + t * CELL)
					else:
						a3 = Vector3(ox + run0 * CELL, 0, oz + line * CELL)
						b3 = Vector3(ox + t * CELL, 0, oz + line * CELL)
					k.wall(a3, b3, HW, T, wall, ops)
					_skirting(k, a3, b3, ops)
					_note_doors(a3, b3, ops)
					run0 = -1
					seen = {}


func _door(cell: int, r: RandomNumberGenerator) -> Dictionary:
	if r.randf() < 0.18:
		return {"at": (cell + 0.5) * CELL, "w": 2.4, "h": H - 0.02}
	return {"at": (cell + 0.5) * CELL + r.randf_range(-0.4, 0.4), "w": 1.1, "h": DOOR_H}


## Border wall along the chunk's west (x) or north (z) edge. Openings are hashed
## from the border's own key, so the chunk on the other side never disagrees.
func _border(k: GeoKit, cx: int, cz: int, axis: String, wall: String, height: float) -> void:
	var ops: Array = []
	for i in N:
		var hv := h01(cx * 3 + (0 if axis == "x" else 1), cz * 7 + i, 77)
		if hv < 0.32 or (i == 3 and hv < 0.8) or (i == 5 and hv < 0.5):
			if hv < 0.06:
				ops.append({"at": (i + 0.5) * CELL, "w": 2.6, "h": H - 0.02})
			else:
				ops.append({"at": (i + 0.5) * CELL, "w": 1.15, "h": DOOR_H})
	var ox := cx * CS
	var oz := cz * CS
	var a := Vector3(ox, 0, oz)
	var b := Vector3(ox, 0, oz + CS) if axis == "x" else Vector3(ox + CS, 0, oz)
	k.wall(a, b, height, T, wall, ops)
	_skirting(k, a, b, ops)
	_note_doors(a, b, ops)


func _note_doors(a: Vector3, b: Vector3, ops: Array) -> void:
	var d := (b - a).normalized()
	for op in ops:
		_doors.append(a + d * float(op["at"]))


## Frost heaped along the foot of a wall (both faces), broken at doorways.
func _skirting(k: GeoKit, a: Vector3, b: Vector3, ops: Array) -> void:
	var d := (b - a)
	var L := d.length()
	var dn := d / L
	var nrm := Vector3(-dn.z, 0, dn.x)
	var cuts: Array = [[0.0, 0.0]]
	for op in ops:
		cuts.append([float(op["at"]) - float(op["w"]) * 0.5, float(op["at"]) + float(op["w"]) * 0.5])
	cuts.append([L, L])
	cuts.sort_custom(func(p, q): return p[0] < q[0])
	var bas := Basis(dn, Vector3.UP, dn.cross(Vector3.UP))
	for i in cuts.size() - 1:
		var s0: float = cuts[i][1]
		var s1: float = cuts[i + 1][0]
		if s1 - s0 < 0.2:
			continue
		for sd in [-1.0, 1.0]:
			var c: Vector3 = a + dn * ((s0 + s1) * 0.5) + nrm * sd * (T * 0.5 + 0.03) + Vector3.UP * 0.025
			k.box_xf(Transform3D(bas, c), Vector3(s1 - s0, 0.05, 0.07), "l03_snow", GeoKit.ALL, false)


func _fixtures(k: GeoKit, wr: Rect2, r: RandomNumberGenerator, grp: String, rem: bool, kind: String, meta: Dictionary) -> void:
	var nx := int(round(wr.size.x / CELL))
	var nz := int(round(wr.size.y / CELL))
	for i in nx:
		for j in nz:
			var c := Vector3(wr.position.x + (i + 0.5) * CELL, H - 0.004, wr.position.y + (j + 0.5) * CELL)
			var dead := r.randf() < (0.06 if rem else 0.22)
			var dim := not dead and not rem and r.randf() < 0.35
			var rot := (i + j) % 2 == 0
			var mat := "l03_panel_dead" if dead else ("l03_panel_dim" if dim else "l03_panel")
			k.box(c + Vector3(0, 0.005, 0), Vector3(1.26 if rot else 0.66, 0.02, 0.66 if rot else 1.26), "l03_frame", GeoKit.ALL, false)
			k.panel(c, 1.2 if rot else 0.6, 0.6 if rot else 1.2, mat, r.randf() * 10.0, 0.7 if (not dead and r.randf() < 0.06) else 0.0)
			if dead or kind == "camp":
				continue
			if (i + j) % 2 == 0 or nx * nz <= 2:
				var e := 0.75 if dim else 1.05
				lvl.lights.add_anchor(c + Vector3.DOWN * 0.3, Color(0.86, 0.93, 1.0), e, 6.0, 0.0, grp)
				meta["lit"] += 1


## "Gigantic cubes of ice ... within rooms so small in comparison that only barely
## contains them": a cube with 0.75 m margins, cracks and bubbles frozen inside.
func _ice_cube(k: GeoKit, ice: GeoKit, wr: Rect2, r: RandomNumberGenerator, meta: Dictionary) -> void:
	var m := 0.75
	var hh := r.randf_range(2.2, 2.5)
	var mn := Vector3(wr.position.x + m, 0.0, wr.position.y + m)
	var mx := Vector3(wr.end.x - m, hh, wr.end.y - m)
	ice.box_mm(mn, mx, "l03_ice")
	var c := (mn + mx) * 0.5
	var sz := mx - mn
	for n in r.randi_range(4, 7):
		var p := c + Vector3(r.randf_range(-0.4, 0.4) * sz.x, r.randf_range(-0.35, 0.35) * sz.y, r.randf_range(-0.4, 0.4) * sz.z)
		var b := Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3.RIGHT, r.randf_range(-1.2, 1.2))
		ice.box_xf(Transform3D(b, p), Vector3(r.randf_range(0.4, 1.1), r.randf_range(0.25, 0.7), 0.004), "l03_ice_crack", GeoKit.ALL, false)
	for n in r.randi_range(10, 18):
		var p2 := c + Vector3(r.randf_range(-0.45, 0.45) * sz.x, r.randf_range(-0.45, 0.4) * sz.y, r.randf_range(-0.45, 0.45) * sz.z)
		ice.box(p2, Vector3.ONE * r.randf_range(0.02, 0.06), "l03_ice_crack", GeoKit.ALL, false)
	# frost skirt around the base and a crust on top
	k.box_mm(mn - Vector3(0.12, 0, 0.12), Vector3(mx.x + 0.12, 0.05, mx.z + 0.12), "l03_snow", GeoKit.ALL, false)
	k.box_mm(Vector3(mn.x + 0.1, hh, mn.z + 0.1), Vector3(mx.x - 0.1, hh + 0.03, mx.z - 0.1), "l03_snow", GeoKit.ALL, false)
	meta["ice"].append(c)


## Blowtorched remains near the camp: cut slabs and a refrozen meltwater sheet.
func _ice_remains(k: GeoKit, ice: GeoKit, wr: Rect2, r: RandomNumberGenerator) -> void:
	var c := wr.get_center()
	var sheet := Vector2(minf(wr.size.x - 1.6, 3.6), minf(wr.size.y - 1.6, 3.0))
	if sheet.x < 1.0 or sheet.y < 1.0:
		return
	k.box_mm(Vector3(c.x - sheet.x * 0.5, 0.0, c.y - sheet.y * 0.5), Vector3(c.x + sheet.x * 0.5, 0.012, c.y + sheet.y * 0.5), "l03_icesheet", GeoKit.ALL, false)
	for n in r.randi_range(2, 4):
		var p := Vector3(c.x + r.randf_range(-sheet.x, sheet.x) * 0.4, 0.0, c.y + r.randf_range(-sheet.y, sheet.y) * 0.4)
		var s := Vector3(r.randf_range(0.4, 1.0), r.randf_range(0.25, 0.7), r.randf_range(0.4, 0.9))
		ice.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3.RIGHT, r.randf_range(-0.2, 0.2)), p + Vector3(0, s.y * 0.45, 0)), s, "l03_ice", GeoKit.ALL, false)


## A sunken room (Level 0's "rooms, hallways, and stairs"): a 1.2 m rim of carpet
## around a pit three risers down whose floor is a sheet of ice.
func _pit(k: GeoKit, ice: GeoKit, wr: Rect2, r: RandomNumberGenerator, carpet: String, meta: Dictionary) -> void:
	var pr := wr.grow(-1.2)
	for rr in [Rect2(wr.position.x, wr.position.y, wr.size.x, pr.position.y - wr.position.y),
			Rect2(wr.position.x, pr.end.y, wr.size.x, wr.end.y - pr.end.y),
			Rect2(wr.position.x, pr.position.y, pr.position.x - wr.position.x, pr.size.y),
			Rect2(pr.end.x, pr.position.y, wr.end.x - pr.end.x, pr.size.y)]:
		k.box_mm(Vector3(rr.position.x, -0.6, rr.position.y), Vector3(rr.end.x, 0.0, rr.end.y), carpet)
	k.box_mm(Vector3(pr.position.x, -0.9, pr.position.y), Vector3(pr.end.x, PIT_Y, pr.end.y), "l03_carpet_frost", GeoKit.PY)
	ice.box_mm(Vector3(pr.position.x + 0.3, PIT_Y, pr.position.y + 0.3), Vector3(pr.end.x - 0.3, PIT_Y + 0.025, pr.end.y - 0.3), "l03_icesheet", GeoKit.PY, false)
	# frosted nosing on the pit edge
	for e in [[Vector3(pr.position.x, -0.03, pr.position.y - 0.03), Vector3(pr.end.x, 0.01, pr.position.y + 0.02)],
			[Vector3(pr.position.x, -0.03, pr.end.y - 0.02), Vector3(pr.end.x, 0.01, pr.end.y + 0.03)],
			[Vector3(pr.position.x - 0.03, -0.03, pr.position.y), Vector3(pr.position.x + 0.02, 0.01, pr.end.y)],
			[Vector3(pr.end.x - 0.02, -0.03, pr.position.y), Vector3(pr.end.x + 0.03, 0.01, pr.end.y)]]:
		k.box_mm(e[0], e[1], "l03_snow", GeoKit.ALL, false)
	# stairs down from the north and south rims
	var c := pr.get_center()
	k.stairs(Vector3(c.x, PIT_Y, pr.position.y + 0.9), Vector3(0, 0, -1), 1.8, -PIT_Y, 3, "l03_carpet_frost", 0.3)
	k.stairs(Vector3(c.x + r.randf_range(-1.0, 1.0), PIT_Y, pr.end.y - 0.9), Vector3(0, 0, 1), 1.8, -PIT_Y, 3, "l03_carpet_frost", 0.3)
	meta["pits"].append(Vector3(c.x, PIT_Y, c.y))


## Ceiling tiles stripped to reach the vents: open T-bar grid, a dark plenum and a
## rusty, frosted duct run that the level script can make "clip around".
func _duct_room(k: GeoKit, node: Node3D, wr: Rect2, r: RandomNumberGenerator, grp: String, meta: Dictionary) -> void:
	k.box_mm(Vector3(wr.position.x, HW - 0.05, wr.position.y), Vector3(wr.end.x, HW + 0.1, wr.end.y), "l03_plenum", GeoKit.NY, false)
	var x := wr.position.x + 0.6
	while x < wr.end.x - 0.01:
		k.box(Vector3(x, H + 0.01, wr.get_center().y), Vector3(0.025, 0.03, wr.size.y), "l03_frame", GeoKit.ALL, false)
		x += 0.6
	var z := wr.position.y + 0.6
	while z < wr.end.y - 0.01:
		k.box(Vector3(wr.get_center().x, H + 0.01, z), Vector3(wr.size.x, 0.03, 0.025), "l03_frame", GeoKit.ALL, false)
		z += 0.6
	# a few tiles left in place, some hanging by one corner
	for n in r.randi_range(3, 6):
		var tp := Vector3(wr.position.x + 0.3 + 0.6 * r.randi_range(0, int(wr.size.x / 0.6) - 1), H + 0.012, wr.position.y + 0.3 + 0.6 * r.randi_range(0, int(wr.size.y / 0.6) - 1))
		if r.randf() < 0.4:
			k.box_xf(Transform3D(Basis(Vector3.RIGHT, r.randf_range(0.5, 1.0)), tp + Vector3(0, -0.22, 0)), Vector3(0.58, 0.015, 0.58), "l03_ceiling", GeoKit.ALL, false)
		else:
			k.box(tp, Vector3(0.58, 0.015, 0.58), "l03_ceiling", GeoKit.ALL, false)
	var along_x := wr.size.x >= wr.size.y
	var y := H + 0.42
	var off := r.randf_range(-0.6, 0.6)
	var segs := 3
	var L := (wr.size.x if along_x else wr.size.y) / segs
	for s in segs:
		var pv := Node3D.new()
		pv.name = "Duct_%d" % s
		if along_x:
			pv.position = Vector3(wr.position.x + L * (s + 0.5), y, wr.get_center().y + off)
		else:
			pv.position = Vector3(wr.get_center().x + off, y, wr.position.y + L * (s + 0.5))
		node.add_child(pv)
		var g := GeoKit.new(pv, "Seg")
		duct_segment(g, L - 0.04, along_x, r)
		g.commit()
		meta["ducts"].append(pv)
	# the crew's work light hangs where the tiles came down
	var lc := Vector3(wr.get_center().x - off * 0.8, 0, wr.get_center().y + off * 0.5)
	Props.place(lvl, node, "ph/caged_hanging_light", lc + Vector3(0, H - 0.2, 0), r.randf() * 180.0, 0.45)
	lvl.lights.add_anchor(lc + Vector3(0, H - 0.4, 0), Color(1.0, 0.82, 0.62), 1.15, 6.5, 0.0, grp)
	meta["lit"] += 1
	if r.randf() < 0.7:
		Props.place(lvl, node, "ph/wooden_ladder", Vector3(lc.x + 0.6, 0, lc.z - 0.4), r.randf_range(-30, 30), 1.9, false)


## One rusty duct section centred on its pivot: body, flanges, hangers, frost.
static func duct_segment(g: GeoKit, L: float, along_x: bool, r: RandomNumberGenerator) -> void:
	var size := Vector3(L, 0.5, 0.75) if along_x else Vector3(0.75, 0.5, L)
	g.box(Vector3.ZERO, size, "l03_rust", GeoKit.ALL, false)
	g.box(Vector3(0, 0.255, 0), Vector3(size.x - 0.04, 0.02, size.z - 0.04), "l03_snow", GeoKit.ALL, false)
	var n := maxi(1, int(L / 1.5))
	for i in n + 1:
		var t := -L * 0.5 + L * float(i) / float(n)
		var p := Vector3(t, 0, 0) if along_x else Vector3(0, 0, t)
		g.box(p, Vector3(0.05, 0.56, 0.81) if along_x else Vector3(0.81, 0.56, 0.05), "l03_rust_dark", GeoKit.ALL, false)
		if i % 2 == 1:
			g.box(p + Vector3(0, 0.6, 0), Vector3(0.02, 0.7, 0.02), "l03_rust_dark", GeoKit.ALL, false)
	for i in r.randi_range(2, 5):
		var t2 := r.randf_range(-L * 0.45, L * 0.45)
		var p2 := (Vector3(t2, -0.25, r.randf_range(-0.3, 0.3)) if along_x else Vector3(r.randf_range(-0.3, 0.3), -0.25, t2))
		var hl := r.randf_range(0.1, 0.32)
		g.box(p2 + Vector3(0, -hl * 0.5, 0), Vector3(0.035, hl, 0.035), "l03_ice", GeoKit.ALL, false)


## A wall grille near the ceiling in a room corner. Active ones pump mist (the
## level script adds the particles, sound and the "block it" interaction).
func _vent_grille(k: GeoKit, wr: Rect2, r: RandomNumberGenerator, meta: Dictionary, active: bool) -> void:
	var side := r.randi() % 4
	var p: Vector3
	var n: Vector3
	var y := 2.42
	match side:
		0:
			p = Vector3(wr.position.x + 0.65, y, wr.position.y + T * 0.5 + 0.01)
			n = Vector3(0, 0, 1)
		1:
			p = Vector3(wr.end.x - 0.65, y, wr.end.y - T * 0.5 - 0.01)
			n = Vector3(0, 0, -1)
		2:
			p = Vector3(wr.position.x + T * 0.5 + 0.01, y, wr.end.y - 0.65)
			n = Vector3(1, 0, 0)
		_:
			p = Vector3(wr.end.x - T * 0.5 - 0.01, y, wr.position.y + 0.65)
			n = Vector3(-1, 0, 0)
	var sz := Vector3(0.6, 0.3, 0.03) if absf(n.z) > 0.5 else Vector3(0.03, 0.3, 0.6)
	k.box(p, sz, "l03_grille", GeoKit.ALL, false)
	k.box(p - n * 0.005, sz + Vector3(0.06, 0.06, 0.0) if absf(n.z) > 0.5 else sz + Vector3(0.0, 0.06, 0.06), "l03_rust_dark", GeoKit.ALL, false)
	# icicles under the grille and frost below it
	for i in r.randi_range(3, 6):
		var t := r.randf_range(-0.26, 0.26)
		var hl := r.randf_range(0.08, 0.3 if active else 0.16)
		var q := p + (Vector3(t, 0, 0) if absf(n.z) > 0.5 else Vector3(0, 0, t)) + n * 0.03 + Vector3(0, -0.15 - hl * 0.5, 0)
		k.box(q, Vector3(0.03, hl, 0.03), "l03_ice", GeoKit.ALL, false)
	if active:
		var fp := Vector3(p.x, 0.0, p.z) + n * 0.6
		k.box(fp + Vector3(0, 0.01, 0), Vector3(1.4, 0.02, 1.4) if absf(n.z) > 0.5 else Vector3(1.4, 0.02, 1.4), "l03_snow", GeoKit.ALL, false)
		meta["vents"].append({"pos": p, "n": n, "rect": wr})


## Scraps of frozen wallpaper still clinging to bare walls (some will let go).
func _scraps(k: GeoKit, node: Node3D, wr: Rect2, r: RandomNumberGenerator, meta: Dictionary) -> void:
	for i in r.randi_range(1, 3):
		var side := r.randi() % 4
		var p: Vector3
		var n: Vector3
		var t := r.randf_range(0.25, 0.75)
		match side:
			0:
				p = Vector3(wr.position.x + wr.size.x * t, 0, wr.position.y + T * 0.5 + 0.012)
				n = Vector3(0, 0, 1)
			1:
				p = Vector3(wr.position.x + wr.size.x * t, 0, wr.end.y - T * 0.5 - 0.012)
				n = Vector3(0, 0, -1)
			2:
				p = Vector3(wr.position.x + T * 0.5 + 0.012, 0, wr.position.y + wr.size.y * t)
				n = Vector3(1, 0, 0)
			_:
				p = Vector3(wr.end.x - T * 0.5 - 0.012, 0, wr.position.y + wr.size.y * t)
				n = Vector3(-1, 0, 0)
		p.y = r.randf_range(1.1, 2.3)
		var mi := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(r.randf_range(0.3, 0.7), r.randf_range(0.4, 0.9))
		mi.mesh = qm
		mi.material_override = MatLib.get_mat("l03_scrap")
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		node.add_child(mi)
		mi.transform = Transform3D(Basis.looking_at(-n, Vector3.UP) * Basis(Vector3.BACK, r.randf_range(-0.3, 0.3)), p)
		meta["scraps"].append(mi)
	# fallen scraps on the carpet
	for i in r.randi_range(0, 2):
		var fp := Vector3(r.randf_range(wr.position.x + 0.5, wr.end.x - 0.5), 0.012, r.randf_range(wr.position.y + 0.5, wr.end.y - 0.5))
		k.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3.RIGHT, r.randf_range(-0.1, 0.1)), fp), Vector3(r.randf_range(0.25, 0.5), 0.006, r.randf_range(0.3, 0.6)), "l03_scrap", GeoKit.ALL, false)


# ------------------------------------------------------------------ duct hall

## The duct hall: a two-storey Level 0 hall (the parent level's own atriums), a
## gallery ringing a 12 m void, the oldest ducts crossing it overhead.
func _hall(k: GeoKit, ice: GeoKit, node: Node3D, ox: float, oz: float, r: RandomNumberGenerator, grp: String, meta: Dictionary) -> void:
	var v0 := Vector2(ox + 6.0, oz + 6.0)
	var v1 := Vector2(ox + 18.0, oz + 18.0)
	k.box_mm(Vector3(ox, -0.6, oz), Vector3(ox + CS, 0.0, oz + CS), "l03_carpet_frost", GeoKit.PY)
	ice.box_mm(Vector3(v0.x + 2.0, 0.0, v0.y + 2.5), Vector3(v1.x - 1.5, 0.02, v1.y - 2.0), "l03_icesheet", GeoKit.PY, false)
	# gallery floor around the void, ceiling tile underneath
	for rc in [[ox, oz, ox + CS, v0.y], [ox, v1.y, ox + CS, oz + CS], [ox, v0.y, v0.x, v1.y], [v1.x, v0.y, ox + CS, v1.y]]:
		k.box_mm(Vector3(rc[0], UP - 0.25, rc[1]), Vector3(rc[2], UP, rc[3]), "l03_carpet_frost", GeoKit.PY | GeoKit.SIDES)
		k.box_mm(Vector3(rc[0], UP - 0.27, rc[1]), Vector3(rc[2], UP - 0.25, rc[3]), "l03_ceiling", GeoKit.NY, false)
	k.box_mm(Vector3(ox, TOP, oz), Vector3(ox + CS, TOP + 0.2, oz + CS), "l03_ceiling", GeoKit.NY, false)
	# upper shell above the neighbours' border walls
	for e in [[Vector3(ox, HW, oz + CS - 0.08), Vector3(ox + CS, TOP, oz + CS + 0.08)], [Vector3(ox + CS - 0.08, HW, oz), Vector3(ox + CS + 0.08, TOP, oz + CS)]]:
		k.box_mm(e[0], e[1], "l03_wall_frozen")
	# parapets (gap at the stair head, north-west)
	var rh := 1.0
	k.box_mm(Vector3(v0.x + 1.7, UP, v0.y - 0.14), Vector3(v1.x, UP + rh, v0.y), "l03_wall_frozen")
	k.box_mm(Vector3(v0.x, UP, v1.y), Vector3(v1.x, UP + rh, v1.y + 0.14), "l03_wall_frozen")
	k.box_mm(Vector3(v1.x, UP, v0.y), Vector3(v1.x + 0.14, UP + rh, v1.y), "l03_wall_frozen")
	k.box_mm(Vector3(v0.x - 0.14, UP, v0.y), Vector3(v0.x, UP + rh, v1.y), "l03_wall_frozen")
	for e in [[Vector3(v0.x + 1.7, UP + rh, v0.y - 0.16), Vector3(v1.x + 0.16, UP + rh + 0.05, v0.y + 0.02)],
			[Vector3(v0.x - 0.16, UP + rh, v1.y - 0.02), Vector3(v1.x + 0.16, UP + rh + 0.05, v1.y + 0.16)]]:
		k.box_mm(e[0], e[1], "l03_snow", GeoKit.ALL, false)
	# the stair rises north along the void's west edge onto the north gallery
	var steps := 18
	var run := 0.3
	k.stairs(Vector3(v0.x + 0.85, 0.0, v0.y + steps * run), Vector3(0, 0, -1), 1.5, UP, steps, "l03_carpet_frost", run, false)
	# a sloped balustrade follows the flight (solid parapet, 1 m above the nosings)
	var s0 := Vector3(v0.x + 1.66, 0.0, v0.y + steps * run)
	var s1 := Vector3(v0.x + 1.66, UP, v0.y)
	var sl := s1 - s0
	var bz := sl.normalized()
	var bx := Vector3.UP.cross(bz).normalized()
	var by := bz.cross(bx).normalized()
	k.box_xf(Transform3D(Basis(bx, by, bz), (s0 + s1) * 0.5 + by * 0.35), Vector3(0.12, 1.3, sl.length()), "l03_wall_frozen")
	k.box_xf(Transform3D(Basis(bx, by, bz), (s0 + s1) * 0.5 + by * 1.02), Vector3(0.16, 0.05, sl.length()), "l03_snow", GeoKit.ALL, false)
	# columns under the gallery edge
	for p in [Vector2(v1.x, v0.y), Vector2(v0.x, v1.y), v1, Vector2((v0.x + v1.x) * 0.5, v0.y), Vector2((v0.x + v1.x) * 0.5, v1.y), Vector2(v1.x, (v0.y + v1.y) * 0.5)]:
		k.box(Vector3(p.x, (UP - 0.25) * 0.5, p.y), Vector3(0.5, UP - 0.25, 0.5), "l03_wall_frozen")
	# lights: panels under the gallery, tall panels over the void
	for j in N:
		for i in N:
			var c := Vector2(ox + (i + 0.5) * CELL, oz + (j + 0.5) * CELL)
			var in_void := c.x > v0.x and c.x < v1.x and c.y > v0.y and c.y < v1.y
			var dead := r.randf() < 0.3
			var mat := "l03_panel_dead" if dead else ("l03_panel_dim" if r.randf() < 0.4 else "l03_panel")
			var y := TOP - 0.004 if in_void else UP - 0.274
			k.panel(Vector3(c.x, y, c.y), 1.2, 0.6, mat, r.randf() * 10.0)
			if not in_void:
				k.panel(Vector3(c.x, TOP - 0.004, c.y), 1.2, 0.6, "l03_panel_dead" if r.randf() < 0.4 else "l03_panel_dim", r.randf() * 10.0)
			if not dead and (i + j) % 2 == 0:
				lvl.lights.add_anchor(Vector3(c.x, y - 0.35, c.y), Color(0.84, 0.92, 1.0), 1.5 if in_void else 0.9, 9.5 if in_void else 5.5, 0.0, grp)
				meta["lit"] += 1
			if not in_void and (i + j) % 2 == 1 and r.randf() < 0.6:
				lvl.lights.add_anchor(Vector3(c.x, TOP - 0.4, c.y), Color(0.84, 0.92, 1.0), 0.8, 5.0, 0.0, grp)
	# two old duct runs cross the void just under the roof, in clipping sections
	for zz in [v0.y + 3.0, v1.y - 3.5]:
		for s in 3:
			var pv := Node3D.new()
			pv.name = "HallDuct"
			pv.position = Vector3(ox + 4.0 + 8.0 * s, TOP - 0.9, zz)
			node.add_child(pv)
			var g := GeoKit.new(pv, "Seg")
			duct_segment(g, 7.96, true, r)
			g.commit()
			meta["ducts"].append(pv)
	# a downward vent on each run pumps mist into the void
	meta["vents"].append({"pos": Vector3(ox + 12.0, TOP - 1.17, v0.y + 3.0), "n": Vector3.DOWN})
	meta["vents"].append({"pos": Vector3(ox + 9.0, TOP - 1.17, v1.y - 3.5), "n": Vector3.DOWN})
	for vp in [Vector3(ox + 12.0, TOP - 1.16, v0.y + 3.0), Vector3(ox + 9.0, TOP - 1.16, v1.y - 3.5)]:
		k.box(vp, Vector3(0.5, 0.03, 0.5), "l03_grille", GeoKit.ALL, false)
	# blowtorched cube remains on the hall floor
	for n in 5:
		var p := Vector3(r.randf_range(v0.x + 2.5, v1.x - 2.0), 0.0, r.randf_range(v0.y + 3.0, v1.y - 2.5))
		var s := Vector3(r.randf_range(0.5, 1.4), r.randf_range(0.3, 1.0), r.randf_range(0.5, 1.2))
		ice.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * TAU), p + Vector3(0, s.y * 0.48, 0)), s, "l03_ice", GeoKit.ALL, n < 2)
	meta["gallery"] = Vector3(ox + 16.5, UP, oz + 3.0)
	meta["ice"].append(Vector3(ox + 12.0, 0.5, oz + 12.0))
	# one ice cube still crammed into the small room at the gallery's east end
	var cube := Rect2(ox + 18.0, oz + 18.0, 6.0, 6.0)
	k.box_mm(Vector3(cube.position.x, UP, cube.position.y), Vector3(cube.end.x - 0.01, TOP, cube.position.y + 0.14), "l03_wall_frozen", GeoKit.ALL)
	k.box_mm(Vector3(cube.position.x, UP, cube.position.y), Vector3(cube.position.x + 0.14, TOP, cube.position.y + 2.0), "l03_wall_frozen", GeoKit.ALL)
	k.box_mm(Vector3(cube.position.x, UP, cube.position.y + 3.2), Vector3(cube.position.x + 0.14, TOP, cube.end.y), "l03_wall_frozen", GeoKit.ALL)
	ice.box_mm(Vector3(cube.position.x + 0.85, UP, cube.position.y + 0.85), Vector3(cube.end.x - 0.7, UP + 2.45, cube.end.y - 0.7), "l03_ice")
	meta["ice"].append(Vector3(cube.get_center().x, UP + 1.2, cube.get_center().y))
	meta["rooms"].append({"rect": Rect2(ox, oz, CS, CS), "kind": "hall"})
