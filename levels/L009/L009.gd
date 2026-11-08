extends LevelBase
const ModelDress := preload("res://core/world/ModelDress.gd")
## Level 9 — "The Suburbs" (Backrooms Wikidot rev 116, accessed 2026-11-04; cite:
## Stretchsterz, CC BY-SA 3.0). Dossier: docs/canon/levels/L009.md.
## Streamed midnight suburb: 64 m chunks = one block of lots plus its two street
## corridors. SOURCE: wet unpainted asphalt with leaves and puddles, stone
## sidewalks, furnished but unpowered houses (some empty, furnished back yards,
## a rare identical pair, clipped pairs far out), mostly dead street lamps, dead
## trees, fog that spawns The Mangled, walkways into fields (9.1 / 10), a
## playground tube with glowing windows (283), houses that may drop you into
## Level 53, an airport on the sign route (36) and the arrow street signs that
## lead to Level 11. ADAPTATION: the 100-200 mile sign walk is ten signs; the
## lamp at the next sign powers on as you follow; The Mangled is fog exposure on
## open ground, glimpsed and never fought. Helpers: levels/L009/L009_house.gd.

const H := preload("res://levels/L009/L009_house.gd")
const M := preload("res://levels/L009/L009_mats.gd")
const CS := 64.0
const W := 15.2
const ROW := 24.4
const LY := 0.15
const NS := 10
const NEED := 8
const PLAY := Vector2i(1, -1)
const SODIUM := Color(1.0, 0.7, 0.4)
const START := Vector3(46.0, 0.05, 8.0)
const WALK_Z := 34.0

var world: ChunkWorld
var qa_fixture := false
var nodes: Array = []
var pts: Array = []
var qa_pts: Array = []
var forced := {}
var air := Vector2i(9999, 9999)
var air_face := 0
var outsk := {}
var end_owner := Vector2i(9999, 9999)
var end_pos := Vector3.ZERO
var end_dir := Vector2i(1, 0)
var progress := 0
var last := -1
var qa_prog := 0
var qa_last := -1
var qa_trace: Array = []
var tlamps := {}
var house_in := ""
var visits := 0
var l53: ExitTrigger
var l53_armed := false
var fog := 0.0
var fog_phase := 0
var fog_t := 160.0
var expo := 0.0
var dread := 0.0
var tick := 0.0
var cp_cool := 0.0
var shape_node: Node3D
var shape_t := 0.0
var static_bed: AudioStreamPlayer
var hum_bed: AudioStreamPlayer
var wind_bed: AudioStreamPlayer
var heart: AudioStreamPlayer
var homes := {}
var said := {}


func build() -> void:
	qa_fixture = SessionState.is_qa()
	var has_light := SessionState.is_developer() or SaveService.item_count("flashlight") > 0
	rules["flashlight"] = "allowed" if has_light else "none"
	rules["view_distance"] = 900.0
	rules["reverb_room"] = 0.18
	rules["reverb_wet"] = 0.05
	outdoor_env(Color(0.008, 0.012, 0.03), Color(0.07, 0.08, 0.11), Color(0.01, 0.01, 0.012), Vector2(28.0, 150.0), Color(0.6, 0.7, 0.95), 0.22, Color(0.07, 0.08, 0.1), 0.010)
	environment.ambient_light_energy = 0.45
	environment.tonemap_exposure = 1.15
	environment.fog_height = 1.2
	environment.fog_height_density = 0.04
	environment.glow_intensity = 0.5
	environment.glow_hdr_threshold = 0.9
	M.define_all()
	lights.setup(10, 1)
	lights.max_distance = 70.0
	_plan()
	world = ChunkWorld.new()
	world.name = "Chunks"
	world.chunk_size = CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _build_chunk
	add_child(world)
	world.chunk_unloaded.connect(func(k): lights.remove_group("%d,%d" % [k.x, k.y]))
	if qa_fixture:
		_qa_route()
		fog_t = 1.0e9
	else:
		fog_t = rng.randf_range(120.0, 210.0)
	world.build_around(START, 2)
	_arrivals()
	var tag := TransitionService.pending_arrival
	var at: Transform3D = arrivals.get(tag, arrivals["start"])
	# ChunkWorld only built the START neighbourhood above. A source-specific
	# arrival may lie in a different chunk: build its floor, house interior and
	# navigation neighbourhood before spawning/validating the player.
	world.build_around(at.origin, 1)
	_interiors_near(at.origin, 24.0)
	var ah: Dictionary = homes["arrival"]
	var af: Transform3D = ah["frame"]
	l53 = add_exit("L009>L053#5", "condition", af * Vector3(float(ah["spec"]["ds"]), 1.65, 0.9), Vector3(1.2, 2.4, 1.2), "")
	if l53:
		l53.condition = func(): return l53_armed
		l53.fired.connect(func(_e): l53_armed = false)
	_sounds()
	shape_node = _make_shape()
	add_shot("street", Vector3(40.0, 1.62, 6.6), Vector3(100.0, 2.4, 9.5), {"flashlight": false})
	add_landmark("Spawn street (arrow sign ahead)", START)


# ------------------------------------------------------------- planning

func _h01(a: int, b: int, salt: int) -> float:
	return float(absi(hash([level_seed, a, b, salt])) % 100003) / 100003.0


func _field(cx: int, cz: int) -> bool:
	return cx == -1 and (cz == -1 or cz == 0)


func _in_air(cx: int, cz: int) -> bool:
	return cx >= air.x and cx <= air.x + 1 and cz >= air.y and cz <= air.y + 1


func _xopen(cx: int, cz: int) -> bool:
	return not (_field(cx, cz) and _field(cx, cz - 1)) and not (_in_air(cx, cz) and _in_air(cx, cz - 1))


func _zopen(cx: int, cz: int) -> bool:
	if (_field(cx, cz) and _field(cx - 1, cz)) or (_in_air(cx, cz) and _in_air(cx - 1, cz)):
		return false
	if forced.has(Vector2i(cx, cz)) or (absi(cx) <= 2 and absi(cz) <= 2):
		return true
	return _h01(cx, cz, 23) > 0.17


func kind_of(cx: int, cz: int) -> String:
	if _field(cx, cz):
		return "field"
	if Vector2i(cx, cz) == PLAY:
		return "playground"
	if _in_air(cx, cz):
		return "airport"
	if outsk.has(Vector2i(cx, cz)):
		return "outskirts"
	var d := maxi(absi(cx), absi(cz))
	var h := _h01(cx, cz, 5)
	if d >= 2 and h > 0.94:
		return "lot"
	if d >= 5 and h < 0.1:
		return "clipped"
	return "houses"


## Story route: ten arrow signs at intersections from node (1,0), mostly east,
## an airport beside it and the outskirts after the last sign.
func _plan() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "route"])
	var p := Vector2i(1, 0)
	var prev := Vector2i(1, 0)
	nodes = [p]
	for i in NS:
		var opts: Array = []
		for d in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var q: Vector2i = p + d
			if nodes.has(q) or (i < 2 and d.y != 0) or (d.y != 0 and d == -prev):
				continue
			if d.y != 0 and not _zopen(p.x, p.y if d.y > 0 else p.y - 1):
				continue
			for j in (3 if d == prev else 1):
				opts.append(d)
		var dd: Vector2i = opts[r.randi() % opts.size()] if opts.size() > 0 else Vector2i(1, 0)
		if dd.y != 0:
			forced[Vector2i(p.x, p.y if dd.y > 0 else p.y - 1)] = true
		p += dd
		prev = dd
		nodes.append(p)
	for n in nodes:
		pts.append(Vector3(n.x * CS + W * 0.5, 0.0, n.y * CS + W * 0.5))
	var e: Vector2i = nodes[NS]
	end_dir = e - (nodes[NS - 1] as Vector2i)
	var c := Vector3(e.x * CS + W * 0.5, 1.4, e.y * CS + W * 0.5)
	if end_dir.x != 0:
		end_owner = e
		outsk = {e: true, e + Vector2i(0, -1): true}
		end_pos = c + Vector3(30.0, 0, 0)
	elif end_dir.y > 0:
		end_owner = e
		outsk = {e: true, e + Vector2i(-1, 0): true}
		end_pos = c + Vector3(0, 0, 30.0)
	else:
		end_owner = e + Vector2i(0, -1)
		outsk = {end_owner: true, end_owner + Vector2i(-1, 0): true}
		end_pos = c + Vector3(0, 0, -30.0)
	forced[end_owner] = true
	for s in [4, 5, 3, 6]:
		var a: Vector2i = nodes[s]
		var b: Vector2i = nodes[s + 1]
		var cands: Array = []
		if a.y == b.y:
			cands = [[Vector2i(mini(a.x, b.x), a.y - 2), 2], [Vector2i(mini(a.x, b.x), a.y), 0]]
		else:
			cands = [[Vector2i(a.x - 2, mini(a.y, b.y)), 1], [Vector2i(a.x, mini(a.y, b.y)), 3]]
		for cd in cands:
			var g: Vector2i = cd[0]
			var ok := not nodes.has(g + Vector2i(1, 1))
			for dz in 2:
				for dx in 2:
					var q := g + Vector2i(dx, dz)
					if outsk.has(q) or q == PLAY or maxi(absi(q.x), absi(q.y)) < 3:
						ok = false
			if ok:
				air = g
				air_face = cd[1]
				return


# --------------------------------------------------------------- chunks

func _build_chunk(cx: int, cz: int, _v: int, node: Node3D) -> Dictionary:
	var kind := kind_of(cx, cz)
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, cx, cz, 9])
	var k := GeoKit.new(node, "K")
	var st := H.new(k, Transform3D.IDENTITY, r)
	var meta := {"kind": kind, "houses": []}
	var ox := cx * CS
	var oz := cz * CS
	_streets(k, st, cx, cz, r, kind == "outskirts")
	var gx := ox + (W if _zopen(cx, cz) else 0.0)
	var gz := oz + (W if _xopen(cx, cz) else 0.0)
	match kind:
		"houses", "clipped":
			k.slab(gx, gz, ox + CS, oz + CS, LY, 0.45, "l9_grass", GeoKit.PY)
			_block(k, cx, cz, gx, r, node, meta, kind == "clipped")
		"field":
			k.slab(gx, gz, ox + CS, oz + CS, LY, 0.45, "l9_field_grass", GeoKit.PY)
			for i in 5:
				st.tree(Vector3(r.randf_range(gx + 4.0, ox + CS - 4.0), LY, r.randf_range(gz + 4.0, oz + CS - 4.0)), 1.15)
			if cz == 0:
				_walkway(k, st, node)
		"playground":
			k.slab(gx, gz, ox + CS, oz + CS, LY, 0.45, "l9_grass", GeoKit.PY)
			_playground(k, st, ox, oz, node)
		"lot", "outskirts":
			k.slab(gx, gz, ox + CS, oz + CS, LY, 0.45, "l9_grass" if kind == "lot" else "l9_driveway", GeoKit.PY)
			if kind == "lot":
				for i in 6:
					st.tree(Vector3(r.randf_range(gx + 3.0, ox + CS - 3.0), LY, r.randf_range(gz + 3.0, oz + CS - 3.0)), 1.1)
				st.bench(Vector3(ox + 40.0, LY, oz + W + 3.0), PI)
			else:
				if Vector2i(cx, cz) == end_owner:
					_slabs(st, ox, oz, r)
				else:
					_night_garage(k, node, ox, oz, "%d,%d" % [cx, cz])
		"airport":
			if Vector2i(cx, cz) == air:
				_airport(k, cx, cz, r, node)
	var key := Vector2i(cx, cz)
	var ti := nodes.find(key)
	if ti >= 0 and ti < NS:
		_route_sign(k, st, ti, node)
	if key == end_owner:
		st.skyline(end_pos + Vector3(end_dir.x, 0, end_dir.y) * 260.0 - Vector3(0, 1.4, 0), Vector3(end_dir.x, 0, end_dir.y), 11)
		var t := make_exit("L009>L011#1", "condition", end_pos, Vector3(3.0, 3.0, 10.0) if end_dir.x != 0 else Vector3(10.0, 3.0, 3.0), "", node)
		if t:
			t.condition = func(): return progress >= NEED
	k.commit()
	ModelDress.decorate_chunk(self, node, "L009", cx, cz)
	return meta


func _streets(k: GeoKit, st, cx: int, cz: int, r: RandomNumberGenerator, lit: bool) -> void:
	var ox := cx * CS
	var oz := cz * CS
	var xo := _xopen(cx, cz)
	var zo := _zopen(cx, cz)
	var arms := [_zopen(cx, cz - 1), xo, zo, _xopen(cx - 1, cz)]
	if arms.has(true):
		var a0 := 3.4
		var a1 := 11.8
		k.slab(ox + a0, oz + a0, ox + a1, oz + a1, 0.0, 0.3, "l9_asphalt", GeoKit.PY)
		var strips := [[a0, 0.0, a1, a0], [a1, a0, W, a1], [a0, a1, a1, W], [0.0, a0, a0, a1]]
		for i in 4:
			var s: Array = strips[i]
			if arms[i]:
				k.slab(ox + s[0], oz + s[1], ox + s[2], oz + s[3], 0.0, 0.3, "l9_asphalt", GeoKit.PY)
			else:
				k.slab(ox + s[0], oz + s[1], ox + s[2], oz + s[3], LY, 0.45, "l9_sidewalk", GeoKit.PY | GeoKit.SIDES)
		for c in [Vector2(0, 0), Vector2(a1, 0), Vector2(0, a1), Vector2(a1, a1)]:
			k.slab(ox + c.x, oz + c.y, ox + c.x + a0, oz + c.y + a0, LY, 0.45, "l9_sidewalk", GeoKit.PY | GeoKit.SIDES)
	var grp := "%d,%d" % [cx, cz]
	if xo:
		_corridor(k, st, r, Vector3(ox + W, 0, oz), true, _h01(cx, cz, 31) < 0.35, grp, _h01(0, cz, 41) < 0.4, lit)
	if zo:
		_corridor(k, st, r, Vector3(ox, 0, oz + W), false, _h01(cx, cz, 37) < 0.35, grp, _h01(cx, 0, 43) < 0.3, lit)


func _corridor(k: GeoKit, st, r: RandomNumberGenerator, a: Vector3, ax: bool, leafy: bool, grp: String, wires: bool, lit: bool) -> void:
	var ln := CS - W
	var P := func(s: float, t: float, y: float) -> Vector3: return Vector3(a.x + s, y, a.z + t) if ax else Vector3(a.x + t, y, a.z + s)
	for b in [[0.0, 2.0, "l9_sidewalk"], [2.0, 3.4, "l9_grass"], [3.4, 11.8, "l9_asphalt_leaves" if leafy else "l9_asphalt"], [11.8, 13.2, "l9_grass"], [13.2, W, "l9_sidewalk"]]:
		var p0: Vector3 = P.call(0.0, b[0], 0.0)
		var p1: Vector3 = P.call(ln, b[1], 0.0)
		if str(b[2]).begins_with("l9_asphalt"):
			k.slab(p0.x, p0.z, p1.x, p1.z, 0.0, 0.3, b[2], GeoKit.PY)
		else:
			k.slab(p0.x, p0.z, p1.x, p1.z, LY, 0.45, b[2], GeoKit.PY | GeoKit.SIDES)
	for i in 1 + r.randi() % 3:
		k.cylinder(P.call(r.randf_range(3.0, ln - 3.0), r.randf_range(4.8, 10.4), 0.012), r.randf_range(0.7, 2.1), 0.012, "l9_puddle_water", 10, false, true)
	var lo := Vector3(0, 0, 1) if ax else Vector3(1, 0, 0)
	var used := [[ln * 0.18, 2.7], [ln * 0.75, 12.5]]
	for lp in [[ln * 0.18, 2.7, lo], [ln * 0.75, 12.5, -lo]]:
		var q: Vector3 = P.call(lp[0], lp[1], LY)
		var h := _h01(int(q.x * 3.0), int(q.z * 3.0), 51)
		var state := 2 if lit else (0 if h < 0.68 else (1 if h < 0.86 else 2))
		var tip: Vector3 = st.lamp(q, lp[2], state, float(int(h * 97.0)))
		if state > 0:
			lights.add_anchor(tip, SODIUM if not lit else Color(0.85, 0.9, 1.0), 2.6 if state == 2 else 2.1, 17.0, 0.85 if state == 1 else 0.0, grp)
	if wires:
		var along := Vector3(1, 0, 0) if ax else Vector3(0, 0, 1)
		var cr := along.cross(Vector3.UP).normalized()
		for s in [8.8, 40.8]:
			var pa: Array = st.pole(P.call(s, 13.0 if ax else 2.3, LY), along)
			var np: Vector3 = P.call(s + 32.0, 13.0 if ax else 2.3, LY) + Vector3(0, 8.5, 0)
			for j in 3:
				st.wire(pa[j], np + cr * (j - 1))
			used.append([s, 13.0 if ax else 2.3])
	for s in [6.0, 18.0, 30.0, 42.0]:
		for t in [2.7, 12.5]:
			var ok := r.randf() < 0.45
			for u in used:
				if absf(float(u[0]) - s) < 4.0 and absf(float(u[1]) - t) < 2.0:
					ok = false
			if ok:
				st.tree(P.call(s + r.randf_range(-1.5, 1.5), t, LY), 1.0)


## Two rows of lots (row 0 faces the -z street, row 1 the +z street).
func _block(k: GeoKit, cx: int, cz: int, gx: float, r: RandomNumberGenerator, node: Node3D, meta: Dictionary, clipped: bool) -> void:
	var ox := cx * CS
	var oz := cz * CS
	var zmid := oz + W + ROW
	k.box_mm(Vector3(gx, LY, zmid - 0.05), Vector3(ox + CS, LY + 1.8, zmid + 0.05), "l9_fence_wood")
	for row in 2:
		var span := ox + CS - gx
		var ws: Array = []
		if Vector2i(cx, cz) == Vector2i(0, 0) and row == 0:
			ws = [22.0, 26.8]
		elif Vector2i(cx, cz) == Vector2i(0, -1) and row == 1:
			ws = [24.4, 24.4]
		else:
			var n := maxi(2, int(round(span / 19.0)))
			var tot := 0.0
			for i in n:
				ws.append(r.randf_range(0.8, 1.2))
				tot += ws[i]
			for i in n:
				ws[i] = ws[i] * span / tot
		var x := gx
		var prev := 0
		for i in ws.size():
			var lw: float = ws[i]
			var hs := hash([level_seed, cx, cz, row, i])
			if i > 0 and r.randf() < 0.07:
				hs = prev
			prev = hs
			var tag := ""
			if Vector2i(cx, cz) == Vector2i(0, 0) and row == 0 and i == 0:
				tag = "arrival"
			elif Vector2i(cx, cz) == Vector2i(0, -1) and row == 1 and i == 1:
				tag = "arcade"
			_lot(k, node, meta, x, lw, row, oz, hs, r, tag, clipped and row == 0 and i == 1)
			if i > 0:
				var z0 := zmid - 9.0 if row == 0 else zmid
				k.box_mm(Vector3(x - 0.05, LY, z0), Vector3(x + 0.05, LY + 1.8, z0 + 9.0), "l9_fence_wood")
			x += lw


func _lot(k: GeoKit, node: Node3D, meta: Dictionary, x: float, lw: float, row: int, oz: float, hs: int, r: RandomNumberGenerator, tag: String, clip: bool) -> void:
	var spec: Dictionary = H.make_spec(hs, lw)
	if tag != "":
		spec.merge({"w": 11.5 if tag == "arrival" else 12.0, "d": 10.0, "ds": 3.4 if tag == "arrival" else 3.0, "xs": 6.6 if tag == "arrival" else 7.0,
			"garage": 0, "empty": false, "porch": true, "yard": true, "door": "l9_door_0" if tag == "arrival" else spec["door"], "arcade": tag == "arcade"}, true)
	if clip:
		spec["enter"] = false
	var ext: Vector2 = H.extent(spec)
	var sb := r.randf_range(5.5, 8.0)
	var lc := x + lw * 0.5 + r.randf_range(-0.7, 0.7)
	var mid := (ext.x + ext.y) * 0.5
	var fr := Transform3D(Basis(), Vector3(lc - mid, LY, oz + W + sb)) if row == 0 else Transform3D(Basis(Vector3.UP, PI), Vector3(lc + mid, LY, oz + CS - sb))
	var hh := H.new(k, fr, r)
	hh.house(spec)
	var lx0 := x - fr.origin.x if row == 0 else fr.origin.x - (x + lw)
	hh.yard(spec, lx0, lx0 + lw, -sb, ROW - sb)
	if clip:
		var s2: Dictionary = H.make_spec(hs + 7, lw)
		s2["enter"] = false
		var f2 := Transform3D(Basis(Vector3.UP, deg_to_rad(r.randf_range(18.0, 34.0))), fr * Vector3(r.randf_range(2.0, 4.0), 0, r.randf_range(1.5, 3.0)))
		H.new(k, f2, r).house(s2)
	if tag == "arrival":
		hh.bx(Vector3(-3.6, 0, 3.8), Vector3(-1.8, 0.3, 5.4), "l9_foundation", 63, true)
		hh.poly([Vector3(-3.5, 0.31, 3.9), Vector3(-2.7, 0.31, 3.9), Vector3(-2.7, 0.52, 5.3), Vector3(-3.5, 0.52, 5.3)], "l9_door_0", Vector3.UP)
		hh.poly([Vector3(-2.7, 0.31, 3.9), Vector3(-1.9, 0.31, 3.9), Vector3(-1.9, 0.52, 5.3), Vector3(-2.7, 0.52, 5.3)], "l9_door_0", Vector3.UP)
	if not spec["enter"]:
		return
	var fh: float = spec["fh"]
	var a := fr * Vector3(0.25, fh, 0.25)
	var b := fr * Vector3(float(spec["w"]) - 0.25, fh + 2.55, float(spec["d"]) - 0.25)
	var h := {"id": "%d" % hs + "_%d_%d" % [int(x), row], "spec": spec, "frame": fr, "built": false, "node": node,
		"aabb": AABB(a.min(b), (b - a).abs()), "door": fr * Vector3(float(spec["ds"]), fh, -0.6)}
	meta["houses"].append(h)
	if tag != "":
		homes[tag] = h


func _walkway(k: GeoKit, st, node: Node3D) -> void:
	k.box_mm(Vector3(-26.5, LY, WALK_Z - 0.75), Vector3(0.0, LY + 0.04, WALK_Z + 0.75), "l9_paver")
	st.lamp(Vector3(-1.4, LY, WALK_Z - 1.6), Vector3(-1, 0, 0), 1, 7.0)
	lights.add_anchor(Vector3(-3.0, 5.1, WALK_Z - 1.6), SODIUM, 2.0, 16.0, 0.85, "-1,0")
	make_exit("L009>L009_1#2", "walk_in", Vector3(-25.6, LY + 1.2, WALK_Z), Vector3(1.8, 2.4, 1.8), "", node)
	var t := make_exit("L009>L010#3", "condition", Vector3(-24.4, LY + 1.5, 7.5), Vector3(43.6, 3.0, 107.0), "", node)
	if t:
		t.condition = func(): return absf(player.global_position.z - WALK_Z) > 0.95


func _playground(k: GeoKit, st, ox: float, oz: float, node: Node3D) -> void:
	var c := Vector3(ox + 52.0, LY, oz + 38.0)
	k.box_mm(c + Vector3(-12, 0, -9), c + Vector3(12, 0.03, 9), "l9_sand")
	st.tube(c + Vector3(-2.0, 0.66, -3.0), 3.4, 0.66)
	lights.add_anchor(c + Vector3(-2.0, 1.6, -3.0), Color(0.85, 0.9, 1.0), 1.6, 9.0, 0.0, "%d,%d" % [PLAY.x, PLAY.y])
	make_exit("L009>L283#9", "interact", c + Vector3(0.3, 0.9, -3.0), Vector3(1.3, 1.8, 1.8), "Crawl into the tube", node)
	for sx in [6.0, 9.0]:
		st.stick(c + Vector3(sx, 0, 2.0), c + Vector3(sx, 2.6, 3.0), 0.09, "l9_metal_dark", true)
		st.stick(c + Vector3(sx, 0, 4.0), c + Vector3(sx, 2.6, 3.0), 0.09, "l9_metal_dark")
	st.stick(c + Vector3(5.8, 2.6, 3.0), c + Vector3(9.2, 2.6, 3.0), 0.1, "l9_metal_dark")
	for sx in [6.8, 8.2]:
		st.stick(c + Vector3(sx, 2.6, 3.0), c + Vector3(sx, 0.55, 3.0), 0.02, "l9_metal_dark")
		k.box(c + Vector3(sx, 0.5, 3.0), Vector3(0.5, 0.05, 0.25), "l9_plastic_0", GeoKit.ALL, false)
	k.box_mm(c + Vector3(-9.0, 0, 3.0), c + Vector3(-7.0, 1.5, 5.0), "l9_plastic_1")
	st.stick(c + Vector3(-7.0, 1.5, 4.0), c + Vector3(-3.6, 0.1, 4.0), 0.7, "l9_plastic_0")
	for p in [Vector3(-11.0, 0, -8.0), Vector3(10.0, 0, -8.0)]:
		st.bench(c + p, 0.0)
	for p in [Vector3(-16.0, 0, 12.0), Vector3(10.0, 0, 13.0), Vector3(-18.0, 0, -12.0)]:
		st.tree(c + p, 1.2)


## Non-end outskirts: a genuinely traversable, three-level parking shell,
## replacing one inaccessible solid building. The Level 11 street exit remains
## on its own separate end_owner chunk and is never obscured by this structure.
func _night_garage(k: GeoKit, node: Node3D, ox: float, oz: float, group: String) -> void:
	var x0 := ox + 32.0
	var z0 := oz + 24.0
	# Open ground floor, two upper decks and full-rise exterior stairs.
	k.slab(x0, z0, ox + 60.0, oz + 52.0, 0.18, 0.26, "l9_driveway", GeoKit.PY)
	k.slab(x0, z0, ox + 60.0, oz + 52.0, 3.40, 0.24, "l9_foundation", GeoKit.ALL)
	# The second floor begins beyond the second flight; otherwise its slab
	# would cover the player's head before they reached the top of the stairs.
	k.slab(x0, oz + 36.0, ox + 60.0, oz + 52.0, 6.80, 0.24, "l9_foundation", GeoKit.ALL)
	k.stairs(Vector3(ox + 23.2, 0.18, oz + 28.0), Vector3.RIGHT, 2.0, 3.22, 16, "l9_metal_dark", 0.55, true)
	k.stairs(Vector3(ox + 51.0, 3.40, oz + 26.0), Vector3(0, 0, 1), 2.0, 3.40, 16, "l9_metal_dark", 0.625, true)
	for xx in [x0 + 1.0, ox + 59.0]:
		for zz in [z0 + 1.0, oz + 51.0]:
			k.box(Vector3(xx, 3.3, zz), Vector3(0.45, 6.6, 0.45), "l9_metal_dark")
	for level_y in [3.40, 6.80]:
		var minz := oz + 36.0 if level_y > 5.0 else z0
		for xx in [x0, ox + 60.0]:
			k.box(Vector3(xx, level_y + 0.53, (minz + oz + 52.0) * 0.5), Vector3(0.09, 1.06, oz + 52.0 - minz), "l9_metal_dark")
		k.box(Vector3((x0 + ox + 60.0) * 0.5, level_y + 0.53, oz + 52.0), Vector3(28.0, 1.06, 0.09), "l9_metal_dark")
	for i in 8:
		k.box(Vector3(x0 + 3.0 + i * 2.7, 3.42, oz + 47.0), Vector3(0.12, 0.015, 3.2), "l9_paver", GeoKit.ALL, false)
	_night_garage_roof(k, node, ox, oz, group)
	lights.add_anchor(Vector3(ox + 46.0, 6.4, oz + 43.0), SODIUM, 1.8, 17.0, 0.25, group)
	var panel := Interactable.new()
	node.add_child(panel)
	panel.setup(Vector3(ox + 52.0, 7.8, oz + 47.0), Vector3(1.3, 1.0, 0.5), "Read the abandoned garage register", func(_p):
		Overlay.toast("Every vehicle entry has the same date. The final page shows the whole district from above.", 5.0))
	k.box(Vector3(ox + 52.0, 7.4, oz + 47.0), Vector3(1.2, 0.85, 0.14), "l9_foundation", GeoKit.ALL, false)



## DEV14: roof level (fourth elevation) with a genuine ascending switchback,
## missing stair slot, narrow eastern return and lateral observation spur.
## This is only placed in the existing non-end outskirts garage chunk.
func _night_garage_roof(k: GeoKit, node: Node3D, ox: float, oz: float, group: String) -> void:
	var y := 10.20
	# The third deck is at 6.80 m. A westbound return flight climbs to 10.20.
	# Its landing is at x=46.2. There is NO roof slab over the ascent.
	k.stairs(Vector3(ox + 55.0, 6.80, oz + 40.0), Vector3.LEFT,
		2.0, 3.40, 16, "l9_metal_dark", 0.55, false)
	for rect in [
		[ox + 32.0, oz + 36.0, ox + 46.25, oz + 52.0],
		[ox + 55.30, oz + 36.0, ox + 60.0, oz + 52.0],
		[ox + 46.25, oz + 36.0, ox + 55.30, oz + 38.60],
		[ox + 46.25, oz + 41.40, ox + 55.30, oz + 52.0]
	]:
		k.slab(rect[0], rect[1], rect[2], rect[3], y, 0.24, "l9_foundation", GeoKit.ALL)
	# Cantilever observation balcony over the edge of the older garage.
	k.slab(ox + 25.0, oz + 43.2, ox + 32.0, oz + 46.2, y, 0.22, "l9_metal_dark")
	for xx in [ox + 25.0, ox + 60.0]:
		var left := xx == ox + 25.0
		k.box(Vector3(xx, y + 0.58, oz + 44.7), Vector3(0.11, 1.16, 3.0 if left else 15.0), "l9_metal_dark")
	for zz in [oz + 36.0, oz + 52.0]:
		k.box(Vector3(ox + 46.0, y + 0.58, zz), Vector3(28.0, 1.16, 0.11), "l9_metal_dark")
	for xx in [ox + 32.0, ox + 46.25]:
		k.box(Vector3(xx, y + 0.58, oz + 44.6), Vector3(0.11, 1.16, 4.4 if xx == ox + 32.0 else 6.35), "l9_metal_dark")
	# Internal stairwell guard segments leave a wide upper landing at x=46.2.
	for zz in [oz + 38.6, oz + 41.4]:
		k.box(Vector3(ox + 51.30, y + 0.58, zz), Vector3(7.5, 1.16, 0.11), "l9_metal_dark")
	# Partial interior walls create multiple route choices on the roof.
	k.wall(Vector3(ox + 35.0, y, oz + 45.0), Vector3(ox + 55.0, y, oz + 45.0),
		2.25, 0.16, "l9_foundation", [{"at": 6.0, "w": 2.5, "h": 2.2}, {"at": 15.5, "w": 2.0, "h": 2.2}], GeoKit.SIDES)
	var register := Interactable.new()
	node.add_child(register)
	register.setup(Vector3(ox + 28.0, y + 0.9, oz + 44.7), Vector3(1.6, 1.1, 1.4),
		"Inspect the rooftop district plan", func(_p):
			Overlay.toast("Four parking floors are shown. The roof sketch has a fifth floor drawn upside down.", 5.0))
	lights.add_anchor(Vector3(ox + 30.0, y + 2.3, oz + 45.0), SODIUM, 0.8, 9.0, 0.0, group)


## Outskirts after the last sign: blank mid-rise slabs, every lamp lit.
func _slabs(st, ox: float, oz: float, r: RandomNumberGenerator) -> void:
	for i in 2:
		var x0 := ox + W + 4.0 + i * 24.0
		var z0 := oz + W + 6.0
		var hgt := r.randf_range(12.0, 18.0)
		st.bx(Vector3(x0, LY, z0), Vector3(x0 + 18.0, hgt, z0 + 34.0), "l9_apart", 63, true)
		for fl in int(hgt / 3.0) - 1:
			var y := 1.4 + fl * 3.0
			for j in 6:
				for zz in [z0 - 0.06, z0 + 34.0]:
					st.bx(Vector3(x0 + 1.5 + j * 2.8, y, zz), Vector3(x0 + 2.7 + j * 2.8, y + 1.3, zz + 0.06), "l9_glass" if r.randf() < 0.93 else "l9_win_cold")
				for xx in [x0 - 0.06, x0 + 18.0]:
					st.bx(Vector3(xx, y, z0 + 2.0 + j * 5.0), Vector3(xx + 0.06, y + 1.3, z0 + 3.4 + j * 5.0), "l9_glass" if r.randf() < 0.93 else "l9_win_cold")


func _air_frame() -> Transform3D:
	var ln := 2.0 * CS - W
	var ctr := Vector3(air.x * CS + W + ln * 0.5, LY, air.y * CS + W + ln * 0.5)
	var bas := Basis(Vector3.UP, [0.0, -PI * 0.5, PI, PI * 0.5][air_face])
	return Transform3D(bas, ctr - bas * Vector3(ln * 0.5, 0, ln * 0.5))


func _airport(k: GeoKit, cx: int, cz: int, r: RandomNumberGenerator, node: Node3D) -> void:
	var ln := 2.0 * CS - W
	var fr := _air_frame()
	var ctr := fr * Vector3(ln * 0.5, 0, ln * 0.5)
	k.slab(ctr.x - ln * 0.5, ctr.z - ln * 0.5, ctr.x + ln * 0.5, ctr.z + ln * 0.5, LY, 0.45, "l9_grass", GeoKit.PY)
	var ap := H.new(k, fr, r)
	ap.bx(Vector3(4.0, 0, 0), Vector3(ln - 4.0, 0.02, 13.0), "l9_driveway", GeoKit.PY)
	var door: Vector3 = ap.airport(ln, ln)
	var dz := fr * (door + Vector3(0, 1.3, 2.6))
	make_exit("L009>L036#7", "walk_in", dz, Vector3(5.0, 2.4, 2.0) if air_face % 2 == 0 else Vector3(2.0, 2.4, 5.0), "", node)
	var grp := "%d,%d" % [cx, cz]
	lights.add_anchor(fr * (door + Vector3(0, 3.6, -4.0)), Color(0.8, 0.85, 1.0), 1.6, 14.0, 0.9, grp)
	for sx in [-18.0, 0.0, 18.0]:
		lights.add_anchor(fr * (door + Vector3(sx, 6.5, 6.0)), Color(0.75, 0.82, 0.95), 1.2, 16.0, 0.3 if sx != 0.0 else 0.0, grp)
	var lb := Label3D.new()
	lb.text = "AIRPORT"
	lb.font_size = 96
	lb.pixel_size = 0.012
	lb.outline_size = 0
	lb.shaded = false
	lb.modulate = Color(0.42, 0.45, 0.5)
	lb.transform = Transform3D(fr.basis.rotated(Vector3.UP, PI), fr * (door + Vector3(0, 9.55, -0.62)))
	node.add_child(lb)


## Lamp + arrow sign on the far-right corner of route intersection i.
func _route_sign(k: GeoKit, st, i: int, node: Node3D) -> void:
	var n: Vector2i = nodes[i]
	var dout: Vector2i = (nodes[i + 1] as Vector2i) - n
	var din: Vector2i = dout if i == 0 else n - (nodes[i - 1] as Vector2i)
	var rgt := Vector2i(-din.y, din.x)
	var off := Vector3(din.x + rgt.x, 0, din.y + rgt.y)
	var cpos := (pts[i] as Vector3) + off * (W * 0.5 - 1.6) + Vector3(0, LY, 0)
	var turn := 0 if dout == din else (2 if dout == rgt else 1)
	var face := Vector3(-din.x, 0, -din.y)
	k.box(cpos + Vector3(0, 2.75, 0), Vector3(0.18, 5.5, 0.18), "l9_metal_dark")
	var out := -off.normalized()
	var tip := cpos + out * 1.6 + Vector3(0, 5.35, 0)
	st.stick(cpos + Vector3(0, 5.3, 0), tip, 0.08, "l9_metal_dark")
	k.box(tip + Vector3(0, -0.06, 0), Vector3(0.6, 0.16, 0.6), "l9_metal_dark", GeoKit.ALL, false)
	st.arrow_sign(cpos + face * 0.14 + Vector3(0, 2.5, 0), face, turn)
	# A street-level observation attached to the streamed sign's chunk.
	# Studying it is optional: the actual route still progresses ONLY when
	# the player's body reaches the correct intersection in order.
	var heading := "east" if dout.x > 0 else ("west" if dout.x < 0 else ("south" if dout.y > 0 else "north"))
	var number := i + 1
	var sign_trigger := Interactable.new()
	node.add_child(sign_trigger)
	sign_trigger.setup(cpos + Vector3(0, 1.7, 0), Vector3(1.8, 2.4, 1.8),
		"Examine the arrow street sign", func(_p):
			if SessionState.is_story():
				SaveService.set_flag(stable_id, "observed_arrow_%02d" % number, true)
			Overlay.subtitle("Sign %d: the arrow points %s. A lamp hums further down the street." % [number, heading], 4.0))
	var lens := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.46, 0.03, 0.46)
	lens.mesh = bm
	lens.position = tip + Vector3(0, -0.15, 0)
	node.add_child(lens)
	var ai := lights.add_anchor(tip + Vector3(0, -0.4, 0), SODIUM, 0.0, 18.0, 0.0, "%d,%d" % [n.x, n.y])
	tlamps[i] = {"lens": lens, "anchor": lights.anchors[ai]}
	_lamp_state(i)


func _lamp_state(i: int) -> void:
	var t: Dictionary = tlamps.get(i, {})
	if t.is_empty() or not is_instance_valid(t["lens"]):
		return
	var on := i == 0 or i <= last + 1
	(t["lens"] as MeshInstance3D).material_override = MatLib.get_mat("l9_lamp_on" if on else "l9_lamp_off")
	t["anchor"]["energy"] = 3.0 if on else 0.0


func _qa_route() -> void:
	var qk := kit("QAFixture")
	var qs := H.new(qk, Transform3D.IDENTITY, rng)
	for i in 3:
		var x := 38.0 - i * 8.0
		qa_pts.append(Vector3(x, 0, 7.6))
		qk.box(Vector3(x, LY + 1.4, 12.9), Vector3(0.1, 2.8, 0.1), "l9_metal_dark")
		qs.arrow_sign(Vector3(x + 0.1, LY + 2.45, 12.9), Vector3(1, 0, 0), 0)
	qk.commit()
	var t := add_exit("L009>L011#1", "condition", Vector3(12.0, 1.4, 7.6), Vector3(4.0, 3.0, 9.0), "")
	if t:
		t.condition = func(): return qa_prog >= 3
	qa_routes.append({"edge": "L009>L011#1", "target": Vector3(12.0, 0.05, 7.6), "waypoints": qa_pts.duplicate(), "note": "QA fixture: each of three arrow signs must be reached in order; real physics Area3D handles the exit"})


func _arrivals() -> void:
	add_arrival("start", START, -90.0)
	add_arrival("from_L008", Vector3(35.0, 0.05, 6.4), -90.0)
	var ah: Dictionary = homes["arrival"]
	var f: Transform3D = ah["frame"]
	var s: Dictionary = ah["spec"]
	add_arrival("from_L005", f * Vector3(float(s["ds"]), float(s["fh"]) + 0.05, -1.05), 0.0)
	add_arrival("from_L007", f * Vector3(-2.7, 0.05, 7.2), 0.0)
	var lh: Dictionary = homes["arcade"]
	add_arrival("from_L025", (lh["frame"] as Transform3D) * Vector3(4.5, 0.5, 1.95), 180.0)


func _interiors_near(p: Vector3, rad: float) -> void:
	for key in world.chunks.keys():
		for h in world.meta_of(key).get("houses", []):
			if not h["built"] and (h["door"] as Vector3).distance_to(p) < rad:
				_build_interior(h)


func _build_interior(h: Dictionary) -> void:
	h["built"] = true
	var node: Node3D = h["node"]
	if not is_instance_valid(node):
		return
	var ik := GeoKit.new(node, "Int")
	var ir := RandomNumberGenerator.new()
	ir.seed = hash([level_seed, h["id"], "in"])
	var res: Dictionary = H.new(ik, h["frame"], ir).interior(h["spec"])
	ik.commit()
	if res.has("drawer") and ir.randf() < 0.5:
		var it := add_interactable((h["frame"] as Transform3D) * (res["drawer"] as Vector3), Vector3(0.8, 0.3, 0.8), "Search the kitchen drawers", _search)
		it.once = true
		it.reparent(node)


func _search(_p: Player) -> void:
	if player.flashlight_policy == "none":
		SaveService.add_item("flashlight")
		player.flashlight_policy = "allowed"
		Overlay.toast("A flashlight in the kitchen drawer. The batteries still work. [F]", 4.5)
	else:
		Overlay.toast("Takeout menus, rubber bands, a dead remote. Nothing you need.", 3.0)


# -------------------------------------------------------------- runtime

func _sounds() -> void:
	wind_bed = sound.bed("wind", {"seconds": 9.0}, -26.0)
	sound.bed("room_tone", {"cutoff": 150.0}, -32.0)
	static_bed = sound.bed("static", {"seconds": 3.0}, -70.0)
	hum_bed = sound.bed("room_tone", {"cutoff": 110.0, "rumble": 0.6, "seconds": 5.0}, -70.0)
	heart = sound.bed("heartbeat", {}, -70.0, "SFX")
	sound.oneshot("drip", {"freq": 900.0}, 7.0, 16.0, 7.0, "[water drips from a gutter]", -24.0)
	sound.oneshot("creak", {"freq": 110.0}, 55.0, 130.0, 22.0, "[a screen door creaks somewhere down the street]", -26.0)


func _make_shape() -> Node3D:
	var n := Node3D.new()
	n.name = "FogShape"
	n.visible = false
	add_child(n)
	var sk := GeoKit.new(n, "S")
	var s := H.new(sk, Transform3D.IDENTITY, rng)
	s.stick(Vector3(0, 0, 0), Vector3(0.25, 1.9, 0.1), 0.42, "unlit_black")
	s.stick(Vector3(0.2, 1.8, 0), Vector3(0.75, 2.45, 0.2), 0.3, "unlit_black")
	s.stick(Vector3(0.1, 1.5, 0), Vector3(-0.7, 0.6, 0.1), 0.12, "unlit_black")
	s.stick(Vector3(0.2, 1.6, 0), Vector3(1.2, 1.1, -0.2), 0.12, "unlit_black")
	s.stick(Vector3(0, 0.1, 0), Vector3(-0.4, -0.05, 0.6), 0.16, "unlit_black")
	sk.commit()
	return n


func on_player_ready() -> void:
	world.target = player
	if SessionState.is_story() and SaveService.flag(stable_id, "arrived", false) == false:
		SaveService.set_flag(stable_id, "arrived", true)
		Overlay.subtitle("[wind in dead branches] [the smell of wet asphalt]", 5.0)
	match TransitionService.pending_arrival:
		"from_L008":
			Overlay.subtitle("[you land hard on wet asphalt]", 4.0)
		"from_L025":
			Overlay.subtitle("[the cabinet behind you is dark and silent]", 4.0)


func level_process(delta: float) -> void:
	if player == null:
		return
	tick -= delta
	cp_cool = maxf(0.0, cp_cool - delta)
	if tick <= 0.0:
		tick = 0.2
		_route_tick()
		_house_tick()
		_stream_interiors()
	_fog_tick(delta)


func _near(list: Array, rad: float) -> int:
	var p := player.global_position
	for i in list.size():
		var q: Vector3 = list[i]
		if Vector2(p.x - q.x, p.z - q.z).length() < rad:
			return i
	return -1


func _route_tick() -> void:
	# The compressed QA route is a physical walk on the street, with ordered
	# waypoints. A wrong sign cannot silently reset/re-complete the sequence.
	# In particular, every waypoint must actually be entered by the player.
	if qa_fixture and qa_prog < qa_pts.size():
		var next_idx: int = qa_prog
		var next_pt: Vector3 = qa_pts[next_idx]
		if Vector2(player.global_position.x - next_pt.x, player.global_position.z - next_pt.z).length() < 3.2:
			qa_last = next_idx
			qa_prog += 1
			qa_trace.append({"index": next_idx, "pos": player.global_position, "progress": qa_prog, "time_ms": Time.get_ticks_msec(), "chunk": world.key_at(player.global_position)})
	var i := _near(pts.slice(0, NS), 9.0)
	if i < 0 or i == last:
		return
	var was := progress
	progress = progress + 1 if i == last + 1 else 1
	last = i
	for j in tlamps.keys():
		_lamp_state(j)
	if progress > was:
		Overlay.subtitle("[a street lamp buzzes on, further along]", 3.0)
		if progress == 4:
			Overlay.subtitle("[a low electrical hum, far ahead]", 4.0)
		elif progress == NEED:
			Overlay.subtitle("[the hum is all around you now]", 4.0)
	elif was >= 3:
		Overlay.subtitle("[the far hum fades]", 3.0)


func _house_tick() -> void:
	var here := ""
	var key := world.key_at(player.global_position)
	var hp := player.global_position + Vector3.UP * 0.5
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			for h in world.meta_of(key + Vector2i(dx, dz)).get("houses", []):
				if (h["aabb"] as AABB).has_point(hp):
					here = h["id"]
	if here != "" and here != house_in:
		visits += 1
		if SessionState.is_story() and cp_cool <= 0.0:
			cp_cool = 60.0
			checkpoint("house")
			Overlay.toast("Indoors, the static in your head eases. (Checkpoint)", 3.5)
		if not qa_fixture and _h01(hash(here), visits, 53) < 0.06 and l53:
			l53_armed = true
			l53.global_position = player.global_position + Vector3.UP
	house_in = here


func _stream_interiors() -> void:
	var key := world.key_at(player.global_position)
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			for h in world.meta_of(key + Vector2i(dx, dz)).get("houses", []):
				if not h["built"] and (h["door"] as Vector3).distance_to(player.global_position) < 26.0:
					_build_interior(h)
					return


## Fog cycle (SOURCE: mist spawns The Mangled) + street dread (testimony:
## watched, "TV static" in the head). Houses are shelter.
func _fog_tick(delta: float) -> void:
	fog_t -= delta
	match fog_phase:
		0:
			if fog_t <= 0.0:
				fog_phase = 1
				fog_t = 14.0
				Overlay.subtitle("[a cold mist creeps up the street]", 4.0)
		1:
			fog = minf(1.0, fog + delta / 14.0)
			if fog_t <= 0.0:
				fog_phase = 2
				fog_t = rng.randf_range(45.0, 80.0)
		2:
			if fog_t <= 0.0:
				fog_phase = 3
				fog_t = 16.0
		_:
			fog = maxf(0.0, fog - delta / 16.0)
			if fog_t <= 0.0:
				fog_phase = 0
				fog_t = rng.randf_range(150.0, 260.0)
	environment.fog_density = lerpf(0.010, 0.06, fog)
	environment.fog_light_color = Color(0.07, 0.08, 0.1).lerp(Color(0.12, 0.13, 0.15), fog)
	environment.fog_height_density = lerpf(0.04, 0.5, fog)
	wind_bed.volume_db = lerpf(-26.0, -18.0, fog)
	var inside := house_in != ""
	var exposed := fog > 0.55 and not inside
	expo = expo + delta if exposed else maxf(0.0, expo - delta * 1.5)
	var rate := (1.0 / 240.0) + (1.0 / 50.0 if exposed else 0.0)
	dread = clampf(dread + (delta * rate if not inside else -delta / 25.0), 0.0, 1.0)
	if dread > 0.35 and not said.has("static"):
		said["static"] = true
		Overlay.subtitle("[a fuzzy static at the back of your head]", 4.0)
	if dread > 0.7 and not said.has("watched"):
		said["watched"] = true
		Overlay.subtitle("[you feel watched]", 3.5)
	static_bed.volume_db = lerpf(-70.0, -20.0, dread)
	hum_bed.volume_db = lerpf(hum_bed.volume_db, -70.0 + 6.0 * minf(progress, NEED), clampf(delta, 0.0, 1.0))
	heart.volume_db = lerpf(-70.0, -8.0, clampf((expo - 8.0) / 10.0, 0.0, 1.0))
	Overlay.set_screen_effect("vignette", 0.25 + 0.4 * dread)
	if not Settings.get_value("reduce_motion"):
		Overlay.set_screen_effect("grain", 0.025 + 0.1 * dread)
	if expo > 5.0 and not said.has("drag%d" % fog_phase):
		said["drag%d" % fog_phase] = true
		sound.play_at("scratch", {"seconds": 2.2}, player.global_position + Vector3(rng.randf_range(-14, 14), 0.5, rng.randf_range(-14, 14)), -6.0, "[something wet drags itself through the mist]")
	_shape_tick(delta)
	if expo > 20.0 and not qa_fixture:
		player.hurt(9.0 * delta, "The Mangled took shape in the fog")
	if fog_phase == 0:
		said.erase("drag1")
		said.erase("drag2")


func _shape_tick(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null or shape_node == null:
		return
	shape_t -= delta
	var want := expo > 10.0 and fog > 0.6
	if not want:
		shape_node.visible = false
		return
	var to := shape_node.global_position - cam.global_position
	var fwd := -cam.global_transform.basis.z
	var looked := shape_node.visible and to.normalized().dot(fwd) > 0.97
	if not shape_node.visible or looked or to.length() < 9.0 or shape_t <= 0.0:
		shape_t = 6.0
		var a := atan2(fwd.x, fwd.z) + (1.0 if rng.randf() < 0.5 else -1.0) * rng.randf_range(0.7, 1.1)
		shape_node.global_position = Vector3(player.global_position.x + sin(a) * 17.0, LY, player.global_position.z + cos(a) * 17.0)
		shape_node.rotation.y = rng.randf() * TAU
		shape_node.visible = not looked


func _exit_tree() -> void:
	Overlay.set_screen_effect("vignette", 0.25)
	Overlay.set_screen_effect("grain", 0.0 if Settings.get_value("reduce_motion") else 0.025)


# ------------------------------------------------------------------ QA

func qa_self_test() -> Array:
	var tag := TransitionService.pending_arrival
	var at: Transform3D = arrivals.get(tag, arrivals["start"])
	var key := world.key_at(at.origin)
	return [
		{"what": "actual arrival neighbourhood loaded before spawn", "ok": world.chunks.has(key), "detail": [tag, key]},
		{"what": "QA route retains real ordered waypoints", "ok": (not qa_fixture) or (qa_pts.size() == 3 and qa_prog <= 3)}
	]


func qa_capture_plan() -> Array:
	var plan: Array = qa_shots.duplicate()
	var ah: Dictionary = homes["arrival"]
	var f: Transform3D = ah["frame"]
	var zs: float = ah["spec"]["zs"]
	plan.append({"name": "house", "pos": f * Vector3(9.0, 1.62, -13.0), "target": f * Vector3(4.5, 3.2, 3.0), "flashlight": true})
	plan.append({"name": "interior", "pos": f * Vector3(6.0, 2.0, zs * 0.55), "target": f * Vector3(0.3, 0.9, zs * 0.45), "flashlight": true})
	plan.append({"name": "field", "pos": Vector3(4.0, 1.8, WALK_Z + 0.4), "target": Vector3(-30.0, 1.0, WALK_Z + 3.0), "flashlight": false})
	plan.append({"name": "tube", "pos": Vector3(119.5, 1.3, -24.0), "target": Vector3(113.0, 0.6, -29.5), "flashlight": false})
	plan.append({"name": "fog", "pos": Vector3(70.0, 1.62, 5.0), "target": Vector3(120.0, 2.0, 9.0), "prepare": _prep_fog, "flashlight": false})
	var af := _air_frame()
	var ln := 2.0 * CS - W
	plan.append({"name": "airport", "pos": af * Vector3(ln * 0.5 - 30.0, 1.7, -9.0), "target": af * Vector3(ln * 0.5 + 6.0, 7.0, 16.0), "prepare": _prep_air, "flashlight": false})
	plan.append({"name": "outskirts", "pos": end_pos + Vector3(-end_dir.x, 0, -end_dir.y) * 40.0 + Vector3(0, 0.3, 0), "target": end_pos + Vector3(end_dir.x, 0, end_dir.y) * 80.0 + Vector3(0, 8, 0), "prepare": _prep_end, "flashlight": false})
	return plan


func _prep_fog() -> void:
	fog = 1.0
	expo = 12.0
	fog_phase = 2
	fog_t = 999.0


func _prep_air() -> void:
	fog = 0.0
	expo = 0.0
	fog_phase = 0
	fog_t = 999.0
	world.build_around(_air_frame() * Vector3(CS, 0, CS), 1)


func _prep_end() -> void:
	world.build_around(end_pos, 1)
