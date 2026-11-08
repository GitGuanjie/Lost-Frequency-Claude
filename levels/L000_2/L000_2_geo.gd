extends RefCounted
## Level 0.2 "Remodeled Mess": floor plan and architecture (design notes in L000_2.gd).
## One storey of a remodelled office suite on a 3 m grid. Every surface is a thin
## finished skin over an unfinished house: wall sheets over bare studs, a drop
## ceiling under open floor joists, a carpeted deck over a concrete crawlspace.
## The skin pieces that can fail are built as separate pivots so the collapse can
## animate them; all wall collision is a static core that never moves.

const C := 3.0          # grid cell (m)
const X0 := -13.5       # west edge of the grid
const NI := 9           # cells west-east
const NJ := 12          # cells south-north (z runs negative)
const H := 2.7          # finished ceiling height
const T := 0.14         # wall thickness (two sheets on 90 mm studs)
const SLAB_Y := -0.75   # crawlspace slab under the deck
const PIT_Y := -0.54    # sunken lounge floor (three 0.18 m risers)
const JOIST_Y := 3.42   # unfinished floor joists above the drop ceiling
const DOOR_W := 0.95
const DOOR_H := 2.1

## id: [i0, j0, i1, j1, kind]
const ROOMS := {
	"V": [3, 0, 5, 1, "reception"], "C": [4, 2, 4, 9, "corridor"], "N": [2, 10, 6, 11, "lobby"],
	"W1": [0, 2, 3, 5, "office"], "W2": [2, 6, 3, 7, "bathroom"], "W3": [0, 6, 1, 7, "storage"],
	"W4": [0, 8, 3, 9, "conference"], "W5": [0, 10, 1, 11, "files"],
	"E1": [5, 2, 8, 4, "break"], "E2": [5, 5, 8, 7, "lounge"], "E3": [5, 8, 6, 9, "foreman"],
	"E4": [7, 8, 8, 9, "office_small"], "E5": [7, 10, 8, 11, "utility"],
}
const HUBS := ["C", "N", "V"]
## Edges left fully open (no wall at all): reception -> corridor -> lobby.
const OPEN := ["h4_2", "h4_10"]
## The pit of the sunken lounge (inside room E2).
const PIT := Rect2(3.3, -22.2, 8.4, 5.4)
## The door back to Level 0, centre of the lobby's north wall.
const EXIT_DOOR := Vector3(0.0, 0.0, -36.0)
const ENTRY_DOOR := Vector3(0.0, 0.0, 0.0)

var lvl
var rng: RandomNumberGenerator
var grid: Dictionary = {}        # Vector2i -> room id
var doors: Dictionary = {}       # edge key -> {"at", "swing"}
var room_doors: Dictionary = {}  # room id -> [world points]
var cells: Dictionary = {}       # Vector2i -> cell record (collapse state)
var vis: GeoKit
var col: GeoKit
var stat: GeoKit
var dip_cells: Array = []


func _init(level) -> void:
	lvl = level
	rng = level.rng


# ------------------------------------------------------------------ helpers

static func cell_rect(i: int, j: int) -> Rect2:
	return Rect2(X0 + i * C, -(j + 1) * C, C, C)


static func cell_center(i: int, j: int) -> Vector3:
	return Vector3(X0 + (i + 0.5) * C, 0.0, -(j + 0.5) * C)


func room_rect(id: String) -> Rect2:
	var r: Array = ROOMS[id]
	return Rect2(X0 + r[0] * C, -(r[3] + 1) * C, (r[2] - r[0] + 1) * C, (r[3] - r[1] + 1) * C)


func room_at(i: int, j: int) -> String:
	return grid.get(Vector2i(i, j), "")


func in_pit(p: Vector3, pad: float = 0.0) -> bool:
	return PIT.grow(pad).has_point(Vector2(p.x, p.z))


## True when p is at least `clear` metres from every doorway of the room.
func clear_of_doors(id: String, p: Vector3, clear: float = 1.25) -> bool:
	for d in room_doors.get(id, []):
		if Vector2(p.x - d.x, p.z - d.z).length() < clear:
			return false
	return true


func floor_y_at(p: Vector3) -> float:
	return PIT_Y if in_pit(p) else 0.0


# ------------------------------------------------------------------ plan

func plan() -> void:
	for id in ROOMS.keys():
		var r: Array = ROOMS[id]
		for i in range(r[0], r[2] + 1):
			for j in range(r[1], r[3] + 1):
				grid[Vector2i(i, j)] = id
	# shared edges per room pair
	var pairs: Dictionary = {}
	for e in _edges():
		if e["a"] == "" or e["b"] == "" or e["a"] == e["b"] or e["key"] in OPEN:
			continue
		var pk: String = "|".join([e["a"], e["b"]] if e["a"] < e["b"] else [e["b"], e["a"]])
		if not pairs.has(pk):
			pairs[pk] = []
		pairs[pk].append(e)
	var want: Dictionary = {}
	# every room gets one door to a hub when it touches one (seeded edge choice)
	for id in ROOMS.keys():
		if id in HUBS:
			continue
		var opts: Array = []
		for pk in pairs.keys():
			var pr: PackedStringArray = (pk as String).split("|")
			if id in pr and (pr[0] in HUBS or pr[1] in HUBS):
				opts.append(pk)
		if opts.is_empty():
			for pk in pairs.keys():
				if id in (pk as String).split("|"):
					opts.append(pk)
		opts.sort()
		want[opts[rng.randi() % opts.size()]] = true
	# extra connecting doors between neighbours
	var keys: Array = pairs.keys()
	keys.sort()
	for pk in keys:
		if not want.has(pk) and not ("V" in (pk as String).split("|")) and rng.randf() < 0.45:
			want[pk] = true
	for pk in want.keys():
		var es: Array = pairs[pk]
		var e: Dictionary = es[rng.randi() % es.size()]
		var at := C * 0.5 + rng.randf_range(-0.55, 0.55)
		doors[e["key"]] = {"at": at, "swing": 1 if rng.randf() < 0.5 else -1}
		var p: Vector3 = e["p0"] + (e["p1"] - e["p0"]).normalized() * at
		for id in [e["a"], e["b"]]:
			if not room_doors.has(id):
				room_doors[id] = []
			room_doors[id].append(p)
	# the open hub edges count as doorways for dressing clearance
	for k in OPEN:
		for e in _edges():
			if e["key"] == k:
				var mid: Vector3 = (e["p0"] + e["p1"]) * 0.5
				for id in [e["a"], e["b"]]:
					if not room_doors.has(id):
						room_doors[id] = []
					room_doors[id].append(mid)
	# the entry door (shut behind you) and the old door back to Level 0
	doors["h4_0"] = {"at": C * 0.5, "swing": 0, "closed": true}
	doors["h4_12"] = {"at": C * 0.5, "swing": 0, "closed": true}
	room_doors["V"].append(ENTRY_DOOR)
	room_doors["N"].append(EXIT_DOOR)
	# floor cells that will sag when the collapse reaches them
	var cand: Array = []
	for k in grid.keys():
		var id: String = grid[k]
		if id in ["V", "E2"] or (id == "N" and k.y == 11 and absi(k.x - 4) <= 1):
			continue
		cand.append(k)
	cand.sort()
	for n in 9:
		var k: Vector2i = cand[rng.randi() % cand.size()]
		if not k in dip_cells:
			dip_cells.append(k)


## All grid edges: {key, a, b, p0, p1, n_b} (n_b: normal pointing into room b).
func _edges() -> Array:
	var out: Array = []
	for i in range(0, NI + 1):
		for j in NJ:
			var x := X0 + i * C
			out.append({"key": "v%d_%d" % [i, j], "a": room_at(i - 1, j), "b": room_at(i, j),
				"p0": Vector3(x, 0, -j * C), "p1": Vector3(x, 0, -(j + 1) * C), "n_b": Vector3(1, 0, 0),
				"ca": Vector2i(i - 1, j), "cb": Vector2i(i, j)})
	for j in range(0, NJ + 1):
		for i in NI:
			var z := -j * C
			out.append({"key": "h%d_%d" % [i, j], "a": room_at(i, j - 1), "b": room_at(i, j),
				"p0": Vector3(X0 + i * C, 0, z), "p1": Vector3(X0 + (i + 1) * C, 0, z), "n_b": Vector3(0, 0, -1),
				"ca": Vector2i(i, j - 1), "cb": Vector2i(i, j)})
	return out


# ------------------------------------------------------------------ build

func build() -> void:
	stat = lvl.kit("L02_Static")
	vis = lvl.kit("L02_Skin")
	col = lvl.kit("L02_WallCores")
	for k in grid.keys():
		cells[k] = {"key": k, "room": grid[k], "c": cell_center(k.x, k.y), "walls": [], "deck": [],
			"ceil": null, "trof": null, "lit": false, "work": false, "state": 0, "dust": 0.0, "t": 0.0}
	_floors()
	_walls()
	_ceilings()
	_house()
	stat.commit()
	vis.commit()
	_strip(vis)
	# col is never committed: its body holds the static wall collision only


static func _strip(k: GeoKit) -> void:
	for c in k.body.get_children():
		c.free()


func _floors() -> void:
	var r := room_rect("V")
	# crawlspace slab under the whole house
	stat.box_mm(Vector3(X0 - 0.2, SLAB_Y - 0.3, -NJ * C - 0.2), Vector3(X0 + NI * C + 0.2, SLAB_Y, 0.2), "l02_slab")
	for j in NJ:
		var run0 := -1
		for i in range(0, NI + 1):
			var k := Vector2i(i, j)
			var plain: bool = i < NI and grid.has(k) and grid[k] != "E2" and not k in dip_cells
			if plain and run0 < 0:
				run0 = i
			elif not plain and run0 >= 0:
				_deck(X0 + run0 * C, X0 + i * C, -(j + 1) * C, -j * C, j)
				run0 = -1
	for k in dip_cells:
		_dip(k)
	# sunken lounge: carpeted ring at 0, pit at PIT_Y, stairs on the west and north sides
	var e2 := room_rect("E2")
	var ring := [Rect2(e2.position.x, e2.position.y, PIT.position.x - e2.position.x, e2.size.y),
		Rect2(PIT.end.x, e2.position.y, e2.end.x - PIT.end.x, e2.size.y),
		Rect2(PIT.position.x, e2.position.y, PIT.size.x, PIT.position.y - e2.position.y),
		Rect2(PIT.position.x, PIT.end.y, PIT.size.x, e2.end.y - PIT.end.y)]
	for rr in ring:
		stat.box_mm(Vector3(rr.position.x, SLAB_Y, rr.position.y), Vector3(rr.end.x, 0.0, rr.end.y), "l02_carpet")
	stat.box_mm(Vector3(PIT.position.x, SLAB_Y, PIT.position.y), Vector3(PIT.end.x, PIT_Y, PIT.end.y), "l02_carpet_pit")
	stat.stairs(Vector3(PIT.position.x + 0.9, PIT_Y, PIT.get_center().y), Vector3(-1, 0, 0), 2.4, -PIT_Y, 3, "l02_carpet", 0.3)
	stat.stairs(Vector3(PIT.get_center().x + 1.5, PIT_Y, PIT.position.y + 0.9), Vector3(0, 0, -1), 2.0, -PIT_Y, 3, "l02_carpet", 0.3)
	# brass nosing strips along the pit edge
	vis.box_mm(Vector3(PIT.position.x - 0.03, -0.02, PIT.position.y - 0.03), Vector3(PIT.end.x + 0.03, 0.006, PIT.position.y + 0.02), "l02_brass", GeoKit.ALL, false)
	vis.box_mm(Vector3(PIT.position.x - 0.03, -0.02, PIT.end.y - 0.02), Vector3(PIT.end.x + 0.03, 0.006, PIT.end.y + 0.03), "l02_brass", GeoKit.ALL, false)
	vis.box_mm(Vector3(PIT.end.x - 0.02, -0.02, PIT.position.y), Vector3(PIT.end.x + 0.03, 0.006, PIT.end.y), "l02_brass", GeoKit.ALL, false)
	vis.box_mm(Vector3(PIT.position.x - 0.03, -0.02, PIT.position.y), Vector3(PIT.position.x + 0.02, 0.006, PIT.end.y), "l02_brass", GeoKit.ALL, false)
	# entrance threshold mat area in reception
	vis.box_mm(Vector3(r.get_center().x - 1.0, 0.0, -1.6), Vector3(r.get_center().x + 1.0, 0.012, -0.3), "l02_mat", GeoKit.ALL, false)


func _deck(x0: float, x1: float, z0: float, z1: float, j: int) -> void:
	var m := "l02_carpet"
	# split bathroom tile runs from carpet runs
	var i0 := int(round((x0 - X0) / C))
	var i1 := int(round((x1 - X0) / C))
	var seg0 := i0
	for i in range(i0, i1 + 1):
		var is_bath: bool = i < i1 and grid.get(Vector2i(i, j), "") == "W2"
		var prev_bath: bool = i > seg0 and grid.get(Vector2i(i - 1, j), "") == "W2"
		if i == i1 or (i > seg0 and is_bath != prev_bath):
			m = "l02_btile_floor" if prev_bath else "l02_carpet"
			stat.box_mm(Vector3(X0 + seg0 * C, -0.1, z0), Vector3(X0 + i * C, 0.0, z1), m, GeoKit.PY)
			vis.box_mm(Vector3(X0 + seg0 * C, -0.22, z0), Vector3(X0 + i * C, -0.1, z1), "l02_joist_rim", GeoKit.SIDES, false)
			seg0 = i


## A deck cell that will sag into the crawlspace: two half-panels hinged at the
## cell edges, both tilting down to a valley so the sag stays walkable (21 deg).
func _dip(k: Vector2i) -> void:
	var rc := cell_rect(k.x, k.y)
	var along_z: bool = grid.get(k, "") == "C" or rng.randf() < 0.5
	var halves: Array = []
	for s in [0, 1]:
		var pv := Node3D.new()
		pv.name = "Dip_%d_%d_%d" % [k.x, k.y, s]
		lvl.add_child(pv)
		var g: GeoKit
		var axis: Vector3
		var sign := 1.0
		if along_z:
			pv.position = Vector3(rc.position.x, 0.0, rc.end.y if s == 0 else rc.position.y)
			g = GeoKit.new(pv, "Deck")
			var dz := -C * 0.5 if s == 0 else C * 0.5
			g.box_mm(Vector3(0.0, -0.1, minf(0.0, dz)), Vector3(C, 0.0, maxf(0.0, dz)), "l02_carpet", GeoKit.PY)
			g.box_mm(Vector3(0.0, -0.13, minf(0.0, dz)), Vector3(C, -0.1, maxf(0.0, dz)), "l02_ply", GeoKit.ALL, false)
			axis = Vector3(1, 0, 0)
			sign = -1.0 if s == 0 else 1.0
		else:
			pv.position = Vector3(rc.position.x if s == 0 else rc.end.x, 0.0, rc.end.y)
			g = GeoKit.new(pv, "Deck")
			var dx := C * 0.5 if s == 0 else -C * 0.5
			g.box_mm(Vector3(minf(0.0, dx), -0.1, -C), Vector3(maxf(0.0, dx), 0.0, 0.0), "l02_carpet", GeoKit.PY)
			g.box_mm(Vector3(minf(0.0, dx), -0.13, -C), Vector3(maxf(0.0, dx), -0.1, 0.0), "l02_ply", GeoKit.ALL, false)
			axis = Vector3(0, 0, 1)
			sign = -1.0 if s == 0 else 1.0
		g.commit()
		halves.append({"pivot": pv, "axis": axis, "sign": sign})
	cells[k]["deck"] = halves
	# what the sag reveals: broken joists and rubble on the crawlspace slab
	for n in 4:
		var p := Vector3(rc.position.x + rng.randf_range(0.4, C - 0.4), SLAB_Y, rc.position.y + rng.randf_range(0.4, C - 0.4))
		vis.box_xf(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).rotated(Vector3.RIGHT, rng.randf_range(-0.3, 0.3)), p + Vector3(0, 0.08, 0)),
			Vector3(rng.randf_range(0.6, 1.6), 0.18, 0.05), "l02_stud", GeoKit.ALL, false)
	vis.box_mm(Vector3(rc.position.x, SLAB_Y, rc.position.y), Vector3(rc.end.x, SLAB_Y + 0.02, rc.end.y), "l02_dirt", GeoKit.PY, false)


func _walls() -> void:
	for e in _edges():
		var a: String = e["a"]
		var b: String = e["b"]
		if a == b or (a == "" and b == "") or e["key"] in OPEN:
			continue
		var ops: Array = []
		if doors.has(e["key"]):
			ops = [{"at": doors[e["key"]]["at"], "w": DOOR_W, "h": DOOR_H}]
		var p0: Vector3 = e["p0"]
		var p1: Vector3 = e["p1"]
		var nb: Vector3 = e["n_b"]
		col.wall(p0, p1, H + 0.6, T, "l02_wall", ops)
		var sides := []
		if b != "":
			sides.append([nb, b, e["cb"]])
		if a != "":
			sides.append([-nb, a, e["ca"]])
		var any_fall := false
		var falls := {}
		for s in sides:
			var f: bool = rng.randf() < 0.42
			falls[s[1]] = f
			any_fall = any_fall or f
		if any_fall or a == "" or b == "":
			_studs(p0, p1, ops, a == "" or b == "", -nb if a == "" else nb)
		for s in sides:
			var n: Vector3 = s[0]
			var id: String = s[1]
			var m := "l02_btile_wall" if id == "W2" else "l02_wall"
			if falls[id]:
				_falling_sheet(p0, p1, n, ops, m, s[2])
			else:
				var o := n * (T * 0.5 - 0.01)
				vis.wall(p0 + o, p1 + o, H, 0.02, m, ops)
				vis.wall(p0 + o + n * 0.012, p1 + o + n * 0.012, 0.1, 0.012, "l02_trim", ops)
		if ops.size() > 0 and not doors[e["key"]].get("closed", false):
			_door_frame(e, ops[0]["at"], doors[e["key"]]["swing"])


## Bare framing visible once a sheet falls: studs at 0.4 m centres, plates and a
## header over a doorway. Exterior walls get pink batts and OSB sheathing.
func _studs(p0: Vector3, p1: Vector3, ops: Array, exterior: bool, out_n: Vector3) -> void:
	var d := (p1 - p0).normalized()
	var hh := JOIST_Y + 0.12 if exterior else H
	var L := (p1 - p0).length()
	var gaps: Array = []
	for op in ops:
		gaps.append([float(op["at"]) - DOOR_W * 0.5 - 0.04, float(op["at"]) + DOOR_W * 0.5 + 0.04])
	var bas := Basis(d, Vector3.UP, d.cross(Vector3.UP))
	var s := 0.02
	while s < L:
		var skip := false
		for g in gaps:
			if s > g[0] and s < g[1]:
				skip = true
		if not skip:
			vis.box_xf(Transform3D(bas, p0 + d * s + Vector3.UP * (hh * 0.5)), Vector3(0.04, hh, 0.09), "l02_stud", GeoKit.ALL, false)
			if exterior and s + 0.4 < L:
				var gap_ok := true
				for g in gaps:
					if s + 0.2 > g[0] - 0.2 and s + 0.2 < g[1] + 0.2:
						gap_ok = false
				if gap_ok:
					vis.box_xf(Transform3D(bas, p0 + d * (s + 0.2) + Vector3.UP * (hh * 0.5) + out_n * 0.01), Vector3(0.36, hh - 0.1, 0.06), "l02_insul", GeoKit.ALL, false)
		s += 0.4
	vis.box_xf(Transform3D(bas, p0 + d * (L * 0.5) + Vector3.UP * 0.02), Vector3(L, 0.04, 0.09), "l02_stud", GeoKit.ALL, false)
	vis.box_xf(Transform3D(bas, p0 + d * (L * 0.5) + Vector3.UP * (hh - 0.02)), Vector3(L, 0.04, 0.09), "l02_stud", GeoKit.ALL, false)
	for op in ops:
		vis.box_xf(Transform3D(bas, p0 + d * float(op["at"]) + Vector3.UP * (DOOR_H + 0.1)), Vector3(DOOR_W + 0.1, 0.2, 0.09), "l02_stud", GeoKit.ALL, false)
	if exterior:
		var o := out_n * (T * 0.5 - 0.01)
		vis.wall(p0 + o, p1 + o, hh, 0.02, "l02_osb", ops)


## A wall sheet that topples into the room on side n when the collapse arrives.
func _falling_sheet(p0: Vector3, p1: Vector3, n: Vector3, ops: Array, mat: String, cell: Vector2i) -> void:
	var pv := Node3D.new()
	pv.name = "Sheet_%d_%d" % [cell.x, cell.y]
	var o := n * (T * 0.5 - 0.01)
	pv.position = p0 + o
	lvl.add_child(pv)
	var g := GeoKit.new(pv, "Sheet")
	g.wall(Vector3.ZERO, p1 - p0, H, 0.02, mat, ops)
	g.wall(n * 0.012, p1 - p0 + n * 0.012, 0.1, 0.012, "l02_trim", ops)
	g.commit()
	_strip(g)
	var d := (p1 - p0).normalized()
	var sgn := 1.0 if d.cross(Vector3.UP).dot(n) < 0.0 else -1.0
	if cells.has(cell):
		cells[cell]["walls"].append({"pivot": pv, "axis": d, "sign": sgn})


func _door_frame(e: Dictionary, at: float, swing: int) -> void:
	var p0: Vector3 = e["p0"]
	var p1: Vector3 = e["p1"]
	var d := (p1 - p0).normalized()
	var nb: Vector3 = e["n_b"]
	var bas := Basis(d, Vector3.UP, d.cross(Vector3.UP))
	var c := p0 + d * at
	for sd in [-1.0, 1.0]:
		vis.box_xf(Transform3D(bas, c + d * (sd * (DOOR_W * 0.5 + 0.035)) + Vector3.UP * (DOOR_H * 0.5)), Vector3(0.07, DOOR_H, T + 0.04), "l02_trim", GeoKit.ALL, false)
	vis.box_xf(Transform3D(bas, c + Vector3.UP * (DOOR_H + 0.035)), Vector3(DOOR_W + 0.14, 0.07, T + 0.04), "l02_trim", GeoKit.ALL, false)
	# the leaf stands open about 80 degrees against the wall of one room
	var side: Vector3 = nb * float(swing)
	if (swing > 0 and e["b"] == "") or (swing < 0 and e["a"] == ""):
		side = -side
	var hinge := c - d * (DOOR_W * 0.5) + side * (T * 0.5)
	var ang := deg_to_rad(80.0)
	var leaf_dir := (d * cos(ang) + side * sin(ang)).normalized()
	var lb := Basis(leaf_dir, Vector3.UP, leaf_dir.cross(Vector3.UP))
	vis.box_xf(Transform3D(lb, hinge + leaf_dir * (DOOR_W * 0.47) + Vector3.UP * (DOOR_H * 0.5 - 0.01)), Vector3(DOOR_W - 0.04, DOOR_H - 0.03, 0.04), "l02_door", GeoKit.ALL, false)
	vis.box_xf(Transform3D(lb, hinge + leaf_dir * (DOOR_W * 0.84) + Vector3.UP * 1.0 + leaf_dir.cross(Vector3.UP) * 0.04), Vector3(0.12, 0.025, 0.03), "l02_brass", GeoKit.ALL, false)


## Drop ceiling: one pivot per cell (3x3 m of 0.6 m tiles), a troffer in most.
func _ceilings() -> void:
	var ks: Array = cells.keys()
	ks.sort()
	for k in ks:
		var rc := cell_rect(k.x, k.y)
		var rec: Dictionary = cells[k]
		# hinge along a walled side when there is one, else the panel drops flat
		var hinge := "drop"
		if room_at(k.x - 1, k.y) != rec["room"]:
			hinge = "west"
		elif room_at(k.x + 1, k.y) != rec["room"]:
			hinge = "east"
		elif room_at(k.x, k.y + 1) != rec["room"]:
			hinge = "north"
		if rng.randf() < 0.3:
			hinge = "drop"
		var lit: bool = rec["room"] != "W5" or k.y % 2 == 0
		var cc := Vector3(rc.get_center().x, H - 0.004, rc.get_center().y)
		var subs: Array = []
		if hinge == "drop":
			# four 1.5 m sections that come down separately and land askew
			for a in 2:
				for b in 2:
					var sp := Node3D.new()
					sp.name = "Ceil_%d_%d_%d" % [k.x, k.y, a * 2 + b]
					sp.position = Vector3(rc.position.x + 0.75 + 1.5 * a, H, rc.position.y + 0.75 + 1.5 * b)
					lvl.add_child(sp)
					subs.append(sp)
		else:
			var hp := Node3D.new()
			hp.name = "Ceil_%d_%d" % [k.x, k.y]
			match hinge:
				"east": hp.position = Vector3(rc.end.x, H, rc.end.y)
				"north": hp.position = Vector3(rc.position.x, H, rc.position.y)
				_: hp.position = Vector3(rc.position.x, H, rc.end.y)
			lvl.add_child(hp)
			subs.append(hp)
		for si in subs.size():
			var pv: Node3D = subs[si]
			var g := GeoKit.new(pv, "Tiles")
			if hinge == "drop":
				g.box_mm(Vector3(-0.75, 0, -0.75), Vector3(0.75, 0.025, 0.75), "l02_ceiling", GeoKit.NY, false)
				g.box_mm(Vector3(-0.75, 0, -0.75), Vector3(0.75, 0.025, 0.75), "l02_tileback", GeoKit.PY | GeoKit.SIDES, false)
			else:
				var lo := Vector3(rc.position.x, H, rc.position.y) - pv.position
				g.box_mm(lo, lo + Vector3(C, 0.025, C), "l02_ceiling", GeoKit.NY, false)
				g.box_mm(lo, lo + Vector3(C, 0.025, C), "l02_tileback", GeoKit.PY | GeoKit.SIDES, false)
			if si == 0:
				var lc := cc - pv.position
				if lit:
					var along_x: bool = k.x % 2 == 0
					var sx := 1.2 if along_x else 0.6
					var sz := 0.6 if along_x else 1.2
					g.box(lc + Vector3(0, -0.006, 0), Vector3(sx + 0.06, 0.02, sz + 0.06), "l02_frame", GeoKit.ALL, false)
					g.panel(lc + Vector3(0, -0.017, 0), sx, sz, "l02_trof", rng.randf() * 10.0)
				elif rng.randf() < 0.6:
					g.box(lc + Vector3(0, -0.006, 0), Vector3(0.6, 0.02, 0.6), "l02_grille", GeoKit.ALL, false)
			g.commit()
		rec["ceil"] = subs[0]
		rec["subs"] = subs
		rec["hinge"] = hinge
		rec["trof"] = subs[0].get_node_or_null("Tiles/Mesh_l02_trof")
		rec["lit"] = lit and (k.x + k.y) % 2 == 0 or (lit and rec["room"] in ["C", "V", "N"])
		rec["work"] = rng.randf() < 0.18


## The unfinished house the remodel was built inside: floor joists and subfloor
## above the drop ceiling, a duct and loose cable in the plenum.
func _house() -> void:
	var x0 := X0 - 0.2
	var x1 := X0 + NI * C + 0.2
	var z := -0.15
	while z > -NJ * C:
		vis.box(Vector3((x0 + x1) * 0.5, JOIST_Y, z), Vector3(x1 - x0, 0.24, 0.045), "l02_stud", GeoKit.ALL, false)
		z -= 0.6
	vis.box_mm(Vector3(x0, JOIST_Y + 0.12, -NJ * C - 0.2), Vector3(x1, JOIST_Y + 0.14, 0.2), "l02_osb", GeoKit.ALL, false)
	vis.box(Vector3(X0 + 4.5 * C, 3.05, -NJ * C * 0.5), Vector3(0.5, 0.32, NJ * C - 2.0), "l02_duct", GeoKit.ALL, false)
	vis.box(Vector3(X0 + 2.0 * C, 3.12, -4.5 * C), Vector3(4 * C, 0.3, 0.45), "l02_duct", GeoKit.ALL, false)
	vis.box(Vector3(X0 + 6.5 * C, 3.12, -6.0 * C), Vector3(4 * C, 0.3, 0.45), "l02_duct", GeoKit.ALL, false)
	for n in 22:
		var p := Vector3(rng.randf_range(X0 + 1, X0 + NI * C - 1), 3.25, rng.randf_range(-NJ * C + 1, -1))
		vis.box_xf(Transform3D(Basis(Vector3.UP, rng.randf() * PI).rotated(Vector3.RIGHT, 0.15), p), Vector3(rng.randf_range(2.0, 5.0), 0.02, 0.02), "l02_cable", GeoKit.ALL, false)
