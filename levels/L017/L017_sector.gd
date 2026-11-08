extends RefCounted
## Level 17 sector shell: one athwartship slice of the ship, 12 m long and 22 m
## across, on two decks. Sector n (1..217) runs from z0 = -(n-1)*L (its aft
## bulkhead, nearer the entrance closet) forward to z0 - L. Local "u" runs
## forward from the aft bulkhead (world z = z0 - u).
##
## Upper deck (floor y = 0, deckhead 2.7): port and starboard side passages along
## the hull, joined by the athwartship passage (u 5..7). Four compartments open
## off it, plus two ladder trunks (centre aft, centre fore) whose inclined ladders
## drop to the lower deck (floor y = -3.2): an engineering flat that is a loop
## between the two ladders. Every sector builds its own aft bulkhead with two
## watertight doors (one per side passage); sector 1's aft bulkhead holds the
## entrance closet instead, and sector 217 also closes its fore end.

const Rooms := preload("res://levels/L017/L017_rooms.gd")
const Anchors := preload("res://levels/L017/L017_anchors.gd")
const Eng := preload("res://levels/L017/L017_engine.gd")
const L := 12.0
const N := 217
const LOW := -3.2
const HEAD := 2.7
const HULL := 11.0
const SIDE := 9.2
const PA := 5.0            # athwartship passage aft wall (u)
const PF := 7.0            # athwartship passage fore wall (u)
const DOOR_X := 10.1       # bulkhead door centre |x|
const ROOMS := {"AP": [-SIDE, -3.0, 0.2, PA], "AS": [3.0, SIDE, 0.2, PA], "FP": [-SIDE, -3.0, PF, 11.8], "FS": [3.0, SIDE, PF, 11.8]}

var lv                      # the level (LevelBase)
var n := 1
var z0 := 0.0
var rng := RandomNumberGenerator.new()
var node: Node3D
var k: GeoKit
var machine := false
var wear := 0               # 0 clean, 1 worn, 2 filthy (sanitation / upkeep)
var plan := {}              # room id -> type
var holes_up: Array = []    # extra upper-deck floor holes [x0, x1, u0, u1]
var meta := {"lights_up": [], "lights_low": [], "clocks": [], "doors": [], "figures": [], "fx": []}


static func z_of(sector: int) -> float:
	return -float(sector - 1) * L


static func sector_at(z: float) -> int:
	return clampi(int(floor(-z / L)) + 1, 1, N)


func _init(level, sector: int, level_seed: int) -> void:
	lv = level
	n = sector
	z0 = z_of(n)
	rng.seed = hash([level_seed, 17, n])
	wear = [0, 1, 1, 2][rng.randi() % 4]
	var types := ["barracks", "galley", "comms", "storage"]
	for id in ["AP", "AS", "FP", "FS"]:
		plan[id] = types[rng.randi() % types.size()]
	if not plan.values().has("comms") and rng.randf() < 0.5:
		plan["FS"] = "comms"


func P(x: float, y: float, u: float) -> Vector3:
	return Vector3(x, y, z0 - u)


func bmm(x0: float, y0: float, u0: float, x1: float, y1: float, u1: float, mat: String, faces := GeoKit.ALL, collide := true) -> void:
	k.box_mm(Vector3(minf(x0, x1), minf(y0, y1), z0 - maxf(u0, u1)), Vector3(maxf(x0, x1), maxf(y0, y1), z0 - minf(u0, u1)), mat, faces, collide)


func box(c: Vector3, s: Vector3, mat: String, collide := false) -> void:
	k.box(P(c.x, c.y, c.z), s, mat, GeoKit.ALL, collide)


func paint() -> String:
	return "l17_paint%d" % wear


func deck() -> String:
	return "l17_deck%d" % wear


# ------------------------------------------------------------------ build

func build(parent: Node3D) -> Dictionary:
	node = Node3D.new()
	node.name = "Sector_%03d" % n
	parent.add_child(node)
	k = GeoKit.new(node, "Hull")
	Anchors.plan(self)
	machine = plan["FP"] == "machine"
	_floors()
	_hull()
	_bulkhead()
	if n == N:
		_end_bulkhead()
	_joiners()
	_trunks()
	_overhead()
	_stencils()
	Rooms.dress_sector(self)
	Eng.engineering(self)
	Eng.passages(self)
	Anchors.dress(self)
	k.commit()
	return meta


func _floors() -> void:
	var holes: Array = [[-2.05, 1.0, 0.95, 2.05]]
	if not machine:
		holes.append([-1.0, 2.05, 9.95, 11.05])
	holes.append_array(holes_up)
	floor_with_holes(-HULL, HULL, -0.2, L - 0.2, 0.0, 0.3, deck(), "l17_overhead", holes)
	# lower deck: steel checker plate, dark
	bmm(-HULL, LOW - 0.4, -0.2, HULL, LOW, L - 0.2, "l17_plate", GeoKit.PY | GeoKit.SIDES)
	# deckhead over the upper deck (painted steel overhead)
	bmm(-HULL, HEAD, -0.2, HULL, HEAD + 0.3, L - 0.2, "l17_overhead", GeoKit.NY)


## Slab split around rectangular holes [x0, x1, u0, u1]; top and underside
## carry different materials (deck covering above, painted steel below).
func floor_with_holes(x0: float, x1: float, u0: float, u1: float, ytop: float, thick: float, top: String, under: String, holes: Array) -> void:
	var xs: Array = [x0, x1]
	for h in holes:
		for xv in [h[0], h[1]]:
			if xv > x0 and xv < x1 and not xs.has(xv):
				xs.append(xv)
	xs.sort()
	for i in xs.size() - 1:
		var xa: float = xs[i]
		var xb: float = xs[i + 1]
		var xm := (xa + xb) * 0.5
		var cuts: Array = []
		for h in holes:
			if xm > h[0] and xm < h[1]:
				cuts.append([float(h[2]), float(h[3])])
		cuts.sort_custom(func(a, b): return a[0] < b[0])
		var cur := u0
		for c in cuts:
			if c[0] > cur + 0.01:
				bmm(xa, ytop - thick, cur, xb, ytop, c[0], top, GeoKit.PY)
				bmm(xa, ytop - thick, cur, xb, ytop, c[0], under, GeoKit.NY | GeoKit.SIDES, false)
			cur = maxf(cur, c[1])
		if cur < u1 - 0.01:
			bmm(xa, ytop - thick, cur, xb, ytop, u1, top, GeoKit.PY)
			bmm(xa, ytop - thick, cur, xb, ytop, u1, under, GeoKit.NY | GeoKit.SIDES, false)


func _hull() -> void:
	for s in [-1.0, 1.0]:
		var x: float = s * (HULL + 0.15)
		bmm(x - 0.15, LOW - 0.4, -0.2, x + 0.15, HEAD + 0.3, L - 0.2, "l17_hullside")
		# hull frames (ribs) and a closed deadlight (porthole) per frame bay
		var fx: float = s * (HULL - 0.06)
		var f := 0.4
		while f < L - 0.3:
			bmm(fx - 0.06, 0.0, f - 0.05, fx + 0.06, HEAD, f + 0.05, paint(), GeoKit.ALL, false)
			bmm(fx - 0.06, LOW, f - 0.05, fx + 0.06, -0.3, f + 0.05, "l17_steel", GeoKit.ALL, false)
			f += 1.2
		for u in [2.6, 8.6]:
			var ph := Node3D.new()
			node.add_child(ph)
			ph.position = P(s * (HULL - 0.02), 1.55, u)
			ph.rotation.y = -s * PI * 0.5
			Rooms.disc(ph, 0.24, 0.05, "l17_brass")
			var cover := Rooms.disc(ph, 0.19, 0.06, "l17_door")
			cover.position.z = 0.02


## The aft bulkhead of this sector with a watertight door in each side passage.
func _bulkhead() -> void:
	var a := P(-HULL, 0.0, 0.0)
	var b := P(HULL, 0.0, 0.0)
	var ops: Array = []
	if n > 1:
		ops = [{"at": HULL - DOOR_X, "w": 0.86, "h": 1.92}, {"at": HULL + DOOR_X, "w": 0.86, "h": 1.92}]
	else:
		ops = [{"at": HULL - DOOR_X, "w": 0.72, "h": 1.9}]
	k.wall(a, b, HEAD + 0.3, 0.4, paint(), ops)
	k.wall(P(-HULL, LOW, 0.0), P(HULL, LOW, 0.0), -LOW, 0.4, "l17_steel")
	# vertical stiffeners on both faces
	var x := -HULL + 0.9
	while x < HULL - 0.6:
		if absf(absf(x) - DOOR_X) > 0.8:
			for su in [-0.25, 0.25]:
				bmm(x - 0.05, 0.0, su - 0.05, x + 0.05, HEAD, su + 0.05, paint(), GeoKit.ALL, false)
				bmm(x - 0.05, LOW, su - 0.05, x + 0.05, -0.3, su + 0.05, "l17_steel", GeoKit.ALL, false)
		x += 1.5
	if n > 1:
		for s in [-1.0, 1.0]:
			var dx: float = s * DOOR_X
			# raised coaming frame round the opening (visual; the sill is flush)
			for su in [-0.24, 0.24]:
				bmm(dx - 0.55, 1.92, su - 0.04, dx + 0.55, 2.08, su + 0.04, "l17_door", GeoKit.ALL, false)
				bmm(dx - 0.55, 0.0, su - 0.04, dx - 0.43, 2.0, su + 0.04, "l17_door", GeoKit.ALL, false)
				bmm(dx + 0.43, 0.0, su - 0.04, dx + 0.55, 2.0, su + 0.04, "l17_door", GeoKit.ALL, false)
			bmm(dx - 0.43, 0.0, -0.22, dx + 0.43, 0.05, 0.22, "l17_door", GeoKit.PY, false)
			meta["doors"].append({"key": "%d_%d" % [n, int(s)], "hinge": P(dx - s * 0.43, 0.0, -0.21), "side": s, "sector": n})


func _end_bulkhead() -> void:
	k.wall(P(-HULL, LOW, L - 0.2), P(HULL, LOW, L - 0.2), HEAD + 0.3 - LOW, 0.4, paint())


func _joiners() -> void:
	var t := 0.1
	for s in [-1.0, 1.0]:
		k.wall(P(s * SIDE, 0, 0.2), P(s * SIDE, 0, L - 0.2), HEAD, t, paint(), [{"at": (PA + PF) * 0.5 - 0.2, "w": 2.0, "h": 2.25}])
		k.wall(P(s * 3.0, 0, 0.2), P(s * 3.0, 0, PA), HEAD, t, paint())
		if not machine:
			k.wall(P(s * 3.0, 0, PF), P(s * 3.0, 0, L - 0.2), HEAD, t, paint())
	for u in [PA, PF]:
		var ops: Array = [{"at": SIDE - 6.1, "w": 0.82, "h": 1.95}, {"at": SIDE, "w": 2.4, "h": 2.25}, {"at": SIDE + 6.1, "w": 0.82, "h": 1.95}]
		if machine and u == PF:
			ops = [{"at": SIDE, "w": 5.0, "h": 2.3}]
		k.wall(P(-SIDE, 0, u), P(SIDE, 0, u), HEAD, t, paint(), ops)
	# door frames round the four compartment doors
	for u in ([PA] if machine else [PA, PF]):
		for x in [-6.1, 6.1]:
			for sx in [-0.46, 0.46]:
				bmm(x + sx - 0.05, 0.0, u - 0.08, x + sx + 0.05, 2.0, u + 0.08, "l17_door", GeoKit.ALL, false)
			bmm(x - 0.51, 1.95, u - 0.08, x + 0.51, 2.05, u + 0.08, "l17_door", GeoKit.ALL, false)


func _trunks() -> void:
	# aft ladder: rises westward from the lower deck to the upper deck at x = -2.0
	k.stairs(P(2.16, LOW, 1.5), Vector3(-1, 0, 0), 1.0, -LOW, 16, "l17_tread", 0.26)
	# fore ladder: rises eastward to x = 2.0
	if not machine:
		k.stairs(P(-2.16, LOW, 10.5), Vector3(1, 0, 0), 1.0, -LOW, 16, "l17_tread", 0.26)
	var specs: Array = [[-2.05, 1.0, 0.95, 2.05, 1.0]]
	if not machine:
		specs.append([-1.0, 2.05, 9.95, 11.05, -1.0])
	for spec in specs:
		var x0: float = spec[0]
		var x1: float = spec[1]
		var u0: float = spec[2]
		var u1: float = spec[3]
		var s: float = spec[4]
		# guard rails round the opening, open at the ladder head
		for u in [u0, u1]:
			rail(Vector3(x0, 0, u), Vector3(x1, 0, u))
		var xe: float = x1 if s > 0 else x0
		rail(Vector3(xe, 0, u0), Vector3(xe, 0, u1))
		# hand rails along the ladder
		var xl: float = 2.16 if s > 0 else -2.16
		var xt: float = -2.0 if s > 0 else 2.0
		for u in [u0 + 0.06, u1 - 0.06]:
			var a := P(xl, LOW + 0.95, u)
			var b := P(xt, 0.95, u)
			var c := (a + b) * 0.5
			var d := b - a
			var ax := d.normalized()
			var az := Vector3(0, 0, 1)
			var bas := Basis(ax, az.cross(ax).normalized(), az)
			k.box_xf(Transform3D(bas.orthonormalized(), c), Vector3(d.length(), 0.05, 0.05), "l17_rail", GeoKit.ALL, false)
			k.box(P(xl, LOW + 0.47, u), Vector3(0.05, 0.95, 0.05), "l17_rail", GeoKit.ALL, false)


## Pipe guard rail between two upper-deck points (local x, y, u), with stanchions.
func rail(a: Vector3, b: Vector3, y0 := 0.0) -> void:
	var pa := P(a.x, y0, a.z)
	var pb := P(b.x, y0, b.z)
	var len := pa.distance_to(pb)
	var mid := (pa + pb) * 0.5
	var along_x := absf(pb.x - pa.x) > absf(pb.z - pa.z)
	var sz := Vector3(len, 0.05, 0.05) if along_x else Vector3(0.05, 0.05, len)
	k.box(mid + Vector3(0, 1.0, 0), sz, "l17_rail", GeoKit.ALL, false)
	k.box(mid + Vector3(0, 0.55, 0), sz, "l17_rail", GeoKit.ALL, false)
	# one collision slab so the rail really stops you
	var cs := Vector3(len, 1.05, 0.08) if along_x else Vector3(0.08, 1.05, len)
	k.box(mid + Vector3(0, 0.52, 0), cs, "l17_rail", 0, true)
	var steps := maxi(1, int(len / 1.1))
	for i in steps + 1:
		var p := pa.lerp(pb, float(i) / steps)
		k.box(p + Vector3(0, 0.5, 0), Vector3(0.05, 1.0, 0.05), "l17_rail", GeoKit.ALL, false)


## Pipes, cable runs and beams under the deckhead; light fixtures and anchors.
func _overhead() -> void:
	# athwartship passage: three pipe runs and a cable tray
	for spec in [[2.48, 0.09, "l17_lagging", 5.35], [2.5, 0.06, "l17_pipe_red", 5.65], [2.42, 0.05, "l17_steel", 6.65]]:
		Rooms.pipe_x(self, -HULL, HULL, float(spec[0]), float(spec[3]), float(spec[1]), str(spec[2]))
	bmm(-SIDE, 2.55, 6.05, SIDE, 2.58, 6.5, "l17_steel", GeoKit.ALL, false)
	# side passages: fore-and-aft pipe runs along the hull and deck beams
	for s in [-1.0, 1.0]:
		Rooms.pipe_u(self, s * 10.75, 2.45, -0.2, L - 0.2, 0.08, "l17_lagging")
		Rooms.pipe_u(self, s * 10.55, 2.55, -0.2, L - 0.2, 0.05, "l17_pipe_red" if s > 0 else "l17_steel")
		Rooms.pipe_u(self, s * 9.45, 2.5, -0.2, L - 0.2, 0.04, "l17_steel")
		var u := 0.6
		while u < L - 0.3:
			bmm(s * SIDE, HEAD - 0.16, u - 0.05, s * HULL, HEAD, u + 0.05, "l17_overhead", GeoKit.ALL, false)
			u += 1.2
	# lower deck: big pipe runs
	for spec in [[-6.0, -0.6, 0.16, "l17_lagging"], [6.5, -0.65, 0.12, "l17_steel"], [-9.8, -0.7, 0.1, "l17_pipe_red"], [9.6, -0.55, 0.14, "l17_lagging"]]:
		Rooms.pipe_u(self, float(spec[0]), float(spec[1]), -0.2, L - 0.2, float(spec[2]), str(spec[3]))
	# light fixtures: caged bulbs. Upkeep decides which ones are dead.
	var up: Array = [[-6.0, 6.0], [0.0, 6.0], [6.0, 6.0], [-10.1, 2.6], [-10.1, 9.2], [10.1, 2.6], [10.1, 9.2]]
	for i in up.size():
		var lx: float = up[i][0]
		var lu: float = up[i][1]
		var dead: bool = wear == 2 and rng.randf() < 0.35
		Rooms.bulb(self, P(lx, HEAD, lu), dead)
		if not dead:
			var warm := Color(1.0, 0.78, 0.5) if rng.randf() < 0.8 else Color(0.9, 0.85, 0.75)
			meta["lights_up"].append([P(lx, HEAD - 0.35, lu), warm, 0.9 if absf(lx) < 9 else 0.75, 6.5, 0.08 if wear > 0 and rng.randf() < 0.3 else 0.0])
	for lu in [3.6, 8.4]:
		for lx in [-6.5, 6.5]:
			Rooms.bulb(self, P(lx, -0.3, lu), false)
			meta["lights_low"].append([P(lx, -0.75, lu), Color(1.0, 0.72, 0.45), 1.4, 8.0, 0.0])
	meta["lights_low"].append([P(0.0, -0.7, 6.0), Color(1.0, 0.72, 0.45), 0.8, 6.0, 0.0])


func _stencils() -> void:
	var col := Color(0.12, 0.12, 0.11)
	for s in [-1.0, 1.0]:
		var x: float = s * (DOOR_X - 0.95)
		Rooms.label(self, "%d" % n, P(x, 2.25, 0.21), Vector3(0, 0, -1), 0.012, col, 64)
		Rooms.label(self, "SECTOR %d" % n, P(x, 1.75, 0.21), Vector3(0, 0, -1), 0.005, col, 48)
		if n > 1:
			Rooms.label(self, "%d" % (n - 1), P(x, 2.25, -0.21), Vector3(0, 0, 1), 0.012, col, 64)
			Rooms.label(self, "SECTOR %d" % (n - 1), P(x, 1.75, -0.21), Vector3(0, 0, 1), 0.005, col, 48)
		Rooms.label(self, "WATERTIGHT DOOR - KEEP CLOSED", P(s * DOOR_X, 2.35, 0.21), Vector3(0, 0, -1), 0.0028, Color(0.45, 0.06, 0.04), 48)
	Rooms.label(self, "SECTOR %d   FR %d-%d" % [n, n * 10, n * 10 + 9], P(0.0, 2.2, PA + 0.06), Vector3(0, 0, 1), 0.004, col, 48)
