extends RefCounted
## Level 37 chunk painters (static). Each painter receives a fresh cell grid
## (L037_cells.gd) whose border passages and landings are already carved and
## locked, a seeded RNG and the border openings. Painters decide floors, depths,
## ceilings, stairs, pillars and light features; L037.gd emits them.
## Hub painters are the hand-authored signature rooms (fixed coordinates).
## SOURCE mapping: uniform pools/hallways + abnormal open areas (fact 2), pillars
## protruding from water (6), open water without ledges (6), irregular light and
## completely dark areas (7), staircases into deep pits of water (8).

const Cells := preload("res://levels/L037/L037_cells.gd")
const N := 16
const C := 2.0
const WALK := -0.18
const SHALLOW := -0.05
const DRY := 0.35
const LEDGE := 0.05      # dry rim around pits: the flights start above the water


## An open light well: the ceiling over these cells is removed up to the bright
## void, so slanted light falls through at an irregular angle (plus fill light).
static func well(g, i0: int, j0: int, i1: int, j1: int, ceil: float, _extra: float, e: float) -> void:
	g.ceil_rect(i0, j0, i1, j1, Cells.TOP + 1.0)
	g.lights.append({"t": "sky", "x0": i0 * C, "z0": j0 * C, "x1": i1 * C, "z1": j1 * C, "y": Cells.TOP, "low": ceil, "e": e})


static func pillar(g, i: int, j: int, s: float, round := false) -> void:
	if not g.is_res(i, j) and not g.solid(i, j):
		g.pillars.append({"x": (i + 0.5) * C, "z": (j + 0.5) * C, "s": s, "round": round})


## Landing edge of an opening and the inward direction (local metres).
static func landing_edge(o: Dictionary) -> Array:
	var t0: int = o["t0"]
	var w: int = o["w"]
	var mid := (t0 + w * 0.5) * C
	match str(o["side"]):
		"w":
			return [Vector3(2 * C, WALK, mid), Vector3(1, 0, 0)]
		"e":
			return [Vector3((N - 2) * C, WALK, mid), Vector3(-1, 0, 0)]
		"n":
			return [Vector3(mid, WALK, 2 * C), Vector3(0, 0, 1)]
	return [Vector3(mid, WALK, (N - 2) * C), Vector3(0, 0, -1)]


## Reserve the cells a flight occupies (from a local top edge, down dir d).
static func reserve_flight(g, top: Vector3, d: Vector3, w: float, length: float) -> void:
	var a := top - Vector3(d.z, 0, d.x).abs() * (w * 0.5) - d * 0.5
	var b := top + Vector3(d.z, 0, d.x).abs() * (w * 0.5) + d * (length + 0.5)
	g.reserve(floori(minf(a.x, b.x) / C), floori(minf(a.z, b.z) / C), ceili(maxf(a.x, b.x) / C), ceili(maxf(a.z, b.z) / C))


## True when the perimeter wall on `side` (0 w, 1 e, 2 n, 3 s) is masonry from
## t0..t1 (local metres along it) at least up to height y (no passage there).
static func wall_ok(g, side: int, t0: float, t1: float, y: float) -> bool:
	for t in range(floori(t0 / C), ceili(t1 / C)):
		var c := Vector2i([0, N - 1, t, t][side], [t, t, 0, N - 1][side])
		if not g.inside(c.x, c.y):
			return false
		if not g.solid(c.x, c.y) and g.cy[c.y * N + c.x] > y:
			return false
	return true


static func carve(g, a: Vector2i, b: Vector2i, y: float, ceil: float, x_first: bool) -> void:
	var p := a
	var path: Array = [p]
	for pass_i in 2:
		var do_x := x_first if pass_i == 0 else not x_first
		if do_x:
			while p.x != b.x:
				p.x += signi(b.x - p.x)
				path.append(p)
		else:
			while p.y != b.y:
				p.y += signi(b.y - p.y)
				path.append(p)
	for c in path:
		if g.solid(c.x, c.y):
			g.setc(c.x, c.y, y, ceil)


# =============================================================== hub rooms

## Grand Pool Hall (chunk 0,0): spawn alcove, pillar lattice in a two-depth
## pool, light wells and a high slit, a lightless west corner with an enclosed
## tunnel (the Level 43 candidate), underwater lamps along the pool walls.
static func hub_hall(g, meta: Dictionary) -> void:
	g.rect(1, 1, N - 1, N - 1, WALK, 8.0)
	g.rect(1, 1, 3, N - 1, Cells.SOLID)
	g.rect(1, 2, 2, 12, SHALLOW, 2.3)          # enclosed dark tunnel x 2..4, z 4..24
	g.setc(2, 11, SHALLOW, 2.3)                # its mouth, low in the west wall
	g.reserve(1, 1, 4, 15)
	g.rect(3, 12, 6, 15, DRY, 4.5)             # dry spawn platform under a low soffit
	g.reserve(3, 11, 7, 15)
	g.stair(Vector3(9.0, DRY, 24.0), Vector3(0, 0, -1), 5.6, WALK)
	g.stair(Vector3(12.0, DRY, 27.0), Vector3(1, 0, 0), 5.6, WALK)
	g.rect(6, 2, 14, 11, -1.6)                 # pool...
	g.rect(8, 4, 12, 9, -3.2)                  # ...with a deeper heart
	g.stair(Vector3(20.0, WALK, 22.0), Vector3(0, 0, -1), 3.8, -1.6)
	g.reserve(9, 10, 11, 12)
	g.stair(Vector3(12.0, WALK, 14.0), Vector3(1, 0, 0), 3.8, -1.6)
	g.reserve(5, 6, 7, 8)
	for j in [3, 5, 7, 9]:
		for i in [5, 7, 9, 11, 13]:
			pillar(g, i, j, 1.0)
	pillar(g, 8, 13, 1.0)
	pillar(g, 12, 13, 1.0)
	well(g, 7, 3, 13, 4, 8.0, 3.5, 4.2)
	well(g, 10, 7, 12, 9, 8.0, 4.0, 4.6)
	well(g, 12, 12, 14, 13, 8.0, 2.5, 2.6)
	g.lights.append({"t": "slit", "p": Vector3(29.98, 5.6, 14.0), "n": Vector3(-1, 0, 0), "len": 10.0, "h": 0.8, "e": 2.6})
	for p in [Vector3(15.0, -1.0, 21.99), Vector3(25.0, -1.0, 21.99)]:
		g.lights.append({"t": "uw", "p": p, "n": Vector3(0, 0, -1), "e": 1.5})
	for p in [Vector3(27.99, -1.0, 8.0), Vector3(27.99, -1.0, 17.0)]:
		g.lights.append({"t": "uw", "p": p, "n": Vector3(-1, 0, 0), "e": 1.5})
	meta["tunnel_end"] = Vector3(3.0, SHALLOW, 5.0)


## The Stair Pit (chunk 1,0): a grand staircase descends straight from the
## passage into a 7 m pit of water; sheer walls, no ledges; a colonnade around
## the rim and pillars rising from the pit floor; one light well, a faint glow
## far below, everything else dim.
static func hub_pit(g, meta: Dictionary) -> void:
	g.rect(1, 1, N - 1, N - 1, LEDGE, 9.5)
	g.rect(5, 4, 12, 12, -7.5)
	g.stair(Vector3(10.0, LEDGE, 15.0), Vector3(1, 0, 0), 5.8, -7.5)
	g.reserve(1, 6, 10, 9)
	g.stair(Vector3(22.0, LEDGE, 8.0), Vector3(0, 0, 1), 3.8, -7.5)
	g.reserve(10, 3, 12, 9)
	for c in [[4, 3], [12, 3], [4, 12], [12, 12], [6, 3], [8, 3], [6, 12], [8, 12], [10, 12], [12, 5], [12, 7], [12, 9]]:
		pillar(g, c[0], c[1], 1.1)
	for c in [[6, 4], [8, 10], [11, 10]]:
		pillar(g, c[0], c[1], 1.2)
	well(g, 8, 9, 11, 12, 9.5, 3.5, 5.0)
	for x in [14.0, 20.0]:
		g.lights.append({"t": "uw", "p": Vector3(x, -6.2, 23.99), "n": Vector3(0, 0, -1), "e": 2.2})
	g.lights.append({"t": "slit", "p": Vector3(27.0, 6.6, 2.02), "n": Vector3(0, 0, 1), "len": 5.0, "h": 0.6, "e": 1.8})
	meta["pit"] = true


## DEV17: Two deterministic Poolrooms annexes attached to the original
## stair-pit hub, with an intact low doorway on their west and east interfaces.
## The water remains below y=0, no entities or extra lore-breaking exits.
static func hub_annex(g, meta: Dictionary, second: bool = false) -> void:
	g.rect(1, 1, Cells.N - 1, Cells.N - 1, WALK, 10.5)
	# Deep open basin, but keep the entire perimeter dry/wadeable for the
	# ground-level access circuit. Both sets of physical stairs lie outside it.
	g.rect(5, 5, 13, 12, -7.75 if second else -6.50, 10.5)
	g.reserve(2, 2, 15, 14)
	# Contrasting submerged side chambers, still no underwater labyrinth exits.
	g.rect(7, 8, 11, 11, -8.25 if second else -7.25, 10.5)
	# Open floor and catwalks deliberately remain unobstructed; a tiled
	# deep basin supplies the primary spatial contrast instead of pillars.
	g.lights.append({"t": "slit", "p": Vector3(16.0, 8.7, 2.02), "n": Vector3(0, 0, 1), "len": 12.0, "h": 0.6, "e": 1.6})
	for pos in [Vector3(16, -4, 21.99), Vector3(22, -5, 15.99)]:
		g.lights.append({"t": "uw", "p": pos, "n": Vector3(0, 0, -1), "e": 1.8})
	meta["dev17_annex"] = "four-tier south loop" if second else "three-tier upper-lower loops"


# ========================================================= procedural kinds

static func _pool_stair(g, r: RandomNumberGenerator, side: String, i0: int, j0: int, pw: int, ph: int, py: float) -> void:
	var w := 2 * C - 0.2
	var length: float = Cells.run_for(WALK - py)
	var top: Vector3
	var d: Vector3
	match side:
		"n":
			var t := i0 + r.randi() % maxi(1, pw - 1)
			top = Vector3((t + 1) * C, WALK, j0 * C)
			d = Vector3(0, 0, 1)
		"s":
			var t := i0 + r.randi() % maxi(1, pw - 1)
			top = Vector3((t + 1) * C, WALK, (j0 + ph) * C)
			d = Vector3(0, 0, -1)
		"w":
			var t := j0 + r.randi() % maxi(1, ph - 1)
			top = Vector3(i0 * C, WALK, (t + 1) * C)
			d = Vector3(1, 0, 0)
		_:
			var t := j0 + r.randi() % maxi(1, ph - 1)
			top = Vector3((i0 + pw) * C, WALK, (t + 1) * C)
			d = Vector3(-1, 0, 0)
	g.stair(top, d, w, py)
	reserve_flight(g, top - d * C, d, w, length + C)


## Uniform pool hall: walkway band, one rectangular pool (sometimes a deeper
## heart), stairs into it, a lattice of far too many pillars, light wells.
static func hall(g, r: RandomNumberGenerator, meta: Dictionary) -> void:
	var ceil := 6.0 + 0.5 * (r.randi() % 6)
	g.rect(1, 1, N - 1, N - 1, WALK, ceil)
	var pw := 5 + r.randi() % 6
	var ph := 5 + r.randi() % 6
	var i0 := 3 + r.randi() % (11 - pw)
	var j0 := 3 + r.randi() % (11 - ph)
	var py := -1.4 - 0.1 * (r.randi() % 10)
	g.rect(i0, j0, i0 + pw, j0 + ph, py)
	if pw >= 7 and ph >= 7 and r.randf() < 0.75:
		g.rect(i0 + 2, j0 + 2, i0 + pw - 2, j0 + ph - 2, py - 0.8 - 0.2 * (r.randi() % 5))
	var sides := ["n", "s", "w", "e"]
	for n in 1 + (1 if r.randf() < 0.6 else 0):
		_pool_stair(g, r, sides.pop_at(r.randi() % sides.size()), i0, j0, pw, ph, py)
	var off := r.randi() % 2
	var round := r.randf() < 0.35
	var s := 0.8 + 0.1 * (r.randi() % 4)
	for j in range(2 + off, N - 2, 2):
		for i in range(2 + off, N - 2, 2):
			pillar(g, i, j, s, round)
	for n in 2 + r.randi() % 2:
		var ww := 1 + r.randi() % 3
		var wh := 1 + r.randi() % 2
		var wi := 2 + r.randi() % (12 - ww)
		var wj := 2 + r.randi() % (12 - wh)
		well(g, wi, wj, wi + ww, wj + wh, ceil, 2.5 + r.randf() * 1.5, 3.2 + r.randf() * 1.6)
	if r.randf() < 0.7:
		var x := (i0 + 1 + r.randi() % maxi(1, pw - 2)) * C
		g.lights.append({"t": "uw", "p": Vector3(x, (WALK + py) * 0.5, j0 * C + 0.01), "n": Vector3(0, 0, 1), "e": 1.4})
	meta["pool"] = Rect2i(i0, j0, pw, ph)


## Staircases descending directly into a deep pit of water.
static func pit(g, r: RandomNumberGenerator, meta: Dictionary) -> void:
	var ceil := 7.5 + 0.5 * (r.randi() % 5)
	g.rect(1, 1, N - 1, N - 1, LEDGE, ceil)
	var depth := -6.0 - 0.5 * (r.randi() % 4)
	var length: float = Cells.run_for(LEDGE - depth)
	var need := ceili(length / C) + 1
	var long_x := r.randf() < 0.5
	var pw := mini(9, need + r.randi() % 2) if long_x else 4 + r.randi() % 3
	var ph := 4 + r.randi() % 3 if long_x else mini(9, need + r.randi() % 2)
	var i0 := 3 + r.randi() % maxi(1, 11 - pw)
	var j0 := 3 + r.randi() % maxi(1, 11 - ph)
	g.rect(i0, j0, i0 + pw, j0 + ph, depth)
	var top: Vector3
	var d: Vector3
	if long_x:
		var t := j0 + r.randi() % maxi(1, ph - 1)
		var west := r.randf() < 0.5
		top = Vector3((i0 if west else i0 + pw) * C, LEDGE, (t + 1) * C)
		d = Vector3(1, 0, 0) if west else Vector3(-1, 0, 0)
	else:
		var t := i0 + r.randi() % maxi(1, pw - 1)
		var north := r.randf() < 0.5
		top = Vector3((t + 1) * C, LEDGE, (j0 if north else j0 + ph) * C)
		d = Vector3(0, 0, 1) if north else Vector3(0, 0, -1)
	g.stair(top, d, 2 * C - 0.2, depth)
	reserve_flight(g, top - d * C, d, 2 * C - 0.2, length + C)
	for i in range(i0 - 1, i0 + pw + 1, 2):
		pillar(g, i, j0 - 1, 1.0)
		pillar(g, i, j0 + ph, 1.0)
	for n in 2:
		pillar(g, i0 + r.randi() % pw, j0 + r.randi() % ph, 1.1)
	var wi := i0 + r.randi() % maxi(1, pw - 2)
	var wj := j0 + r.randi() % maxi(1, ph - 2)
	well(g, wi, wj, wi + 2, wj + 2, ceil, 3.0, 4.6)
	g.lights.append({"t": "uw", "p": Vector3((i0 + pw * 0.5) * C, depth + 1.2, j0 * C + 0.01), "n": Vector3(0, 0, 1), "e": 2.0})
	meta["pit"] = true


## Flooded pillar forest: open water wall to wall with no ledge to climb onto;
## each passage ends in a landing whose stairs descend into the water.
static func pillars(g, r: RandomNumberGenerator, ops: Array, meta: Dictionary) -> void:
	var ceil := 5.0 + 0.5 * (r.randi() % 4)
	var depth := -1.8 - 0.2 * (r.randi() % 4)
	g.rect(1, 1, N - 1, N - 1, depth, ceil)
	for o in ops:
		var le := landing_edge(o)
		var w := float(o["w"]) * C - 0.3
		g.stair(le[0], le[1], w, depth)
		reserve_flight(g, le[0], le[1], w, Cells.run_for(WALK - depth) + C)
	var sp := 3.2
	var row := 0
	var z := 3.0
	while z < 29.5:
		var x := 3.0 + (sp * 0.5 if row % 2 == 1 else 0.0)
		while x < 29.5:
			var ci := int(x / C)
			var cj := int(z / C)
			if not g.is_res(ci, cj) and not g.solid(ci, cj):
				g.pillars.append({"x": x, "z": z, "s": 0.75})
			x += sp
		z += sp * 0.87
		row += 1
	var side := r.randi() % 4
	for n in 3:
		var t := 3.0 + n * 9.0 + r.randf() * 3.0
		var p: Vector3
		var nn: Vector3
		match side:
			0:
				p = Vector3(C + 0.02, ceil - 1.4, t)
				nn = Vector3(1, 0, 0)
			1:
				p = Vector3((N - 1) * C - 0.02, ceil - 1.4, t)
				nn = Vector3(-1, 0, 0)
			2:
				p = Vector3(t, ceil - 1.4, C + 0.02)
				nn = Vector3(0, 0, 1)
			_:
				p = Vector3(t, ceil - 1.4, (N - 1) * C - 0.02)
				nn = Vector3(0, 0, -1)
		var ln := 2.5 + r.randf() * 2.0
		if wall_ok(g, side, t - ln * 0.5, t + ln * 0.5, p.y - 0.5):
			g.lights.append({"t": "slit", "p": p, "n": nn, "len": ln, "h": 0.7, "e": 2.4})
	meta["flooded"] = true


## Uniform hallway crossing the chunk; side passages join it. Some hallways are
## swim lanes with no ledge. Lights along it are irregular, some missing.
## branch: a rare dead-end corridor that runs on (Level 233 candidate).
static func corridor(g, r: RandomNumberGenerator, ops: Array, axis: String, meta: Dictionary, branch: bool) -> void:
	var ceil := 3.4 + 0.2 * (r.randi() % 5)
	var swim := r.randf() < 0.3
	var lane_y := -1.8 if swim else WALK
	if axis == "x":
		g.rect(1, 7, N - 1, 9, lane_y, ceil)
	else:
		g.rect(7, 1, 9, N - 1, lane_y, ceil)
	for o in ops:
		var le := landing_edge(o)
		var side := str(o["side"])
		var on_axis := (axis == "x" and side in ["w", "e"]) or (axis == "z" and side in ["n", "s"])
		var t0: int = o["t0"]
		var cell: Vector2i
		match side:
			"w":
				cell = Vector2i(1, t0)
			"e":
				cell = Vector2i(N - 2, t0)
			"n":
				cell = Vector2i(t0, 1)
			_:
				cell = Vector2i(t0, N - 2)
		if on_axis and t0 <= 8 and t0 + int(o["w"]) >= 8:
			if swim:
				g.stair(le[0], le[1], float(o["w"]) * C - 0.3, lane_y)
			continue
		var target := Vector2i(cell.x, clampi(cell.y, 6, 9)) if axis == "x" else Vector2i(clampi(cell.x, 6, 9), cell.y)
		carve(g, cell, target, WALK, minf(ceil, float(o["ceil"])), axis == "z")
		if swim:
			var tgt := Vector3((target.x + 0.5) * C, WALK, (target.y + 0.5) * C)
			var dd := Vector3(0, 0, signf(8.0 - target.y)) if axis == "x" else Vector3(signf(8.0 - target.x), 0, 0)
			g.stair(tgt + dd * (C * 0.5), dd, C - 0.2, lane_y)
	var gap := 0
	for t in range(1, N - 1, 2):
		var x := (t + 0.5) * C if axis == "x" else 8.0 * C
		var z := 8.0 * C if axis == "x" else (t + 0.5) * C
		var dead := r.randf() < 0.35 or gap > 0
		gap = maxi(0, gap - 1)
		if r.randf() < 0.12:
			gap = 2
		g.lights.append({"t": "panel", "x": x, "z": z, "y": ceil, "e": 0.0 if dead else 1.8, "dead": dead})
	if branch and not swim:
		var bi := 3 + r.randi() % 9
		var up := r.randf() < 0.5
		var a := Vector2i(bi, 6 if up else 9) if axis == "x" else Vector2i(6 if up else 9, bi)
		var b := Vector2i(bi, 2 if up else 13) if axis == "x" else Vector2i(2 if up else 13, bi)
		carve(g, a, b, WALK, ceil, axis == "z")
		g.lights.append({"t": "panel", "x": (a.x + 0.5) * C, "z": (a.y + 0.5) * C, "y": ceil, "e": 0.9, "dead": false})
		meta["branch_end"] = Vector3((b.x + 0.5) * C, WALK, (b.y + 0.5) * C)
	meta["swim"] = swim


## Lightless low rooms joined by enclosed tunnels; some tunnels dead-end deep in
## the dark (each a Level 43 candidate, rolled by L037.gd).
static func dark(g, r: RandomNumberGenerator, ops: Array, meta: Dictionary) -> void:
	var ceil := 2.6 + 0.2 * (r.randi() % 3)
	var rw := 4 + r.randi() % 3
	var rh := 4 + r.randi() % 3
	var i0 := 4 + r.randi() % (9 - rw)
	var j0 := 4 + r.randi() % (9 - rh)
	g.rect(i0, j0, i0 + rw, j0 + rh, WALK, ceil)
	var mid := Vector2i(i0 + (rw >> 1), j0 + (rh >> 1))
	for o in ops:
		var t0: int = o["t0"]
		var cell: Vector2i
		match str(o["side"]):
			"w":
				cell = Vector2i(1, t0)
			"e":
				cell = Vector2i(N - 2, t0)
			"n":
				cell = Vector2i(t0, 1)
			_:
				cell = Vector2i(t0, N - 2)
		carve(g, cell, mid, WALK, 2.4, str(o["side"]) in ["w", "e"])
	var ends: Array = []
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for n in 2:
		var dvec: Vector2i = dirs.pop_at(r.randi() % dirs.size())
		var start := mid
		while not g.solid(start.x + dvec.x, start.y + dvec.y) and g.inside(start.x + dvec.x, start.y + dvec.y):
			start += dvec
		var p := start
		var ln := 0
		while ln < 7:
			var q := p + dvec
			if q.x < 2 or q.y < 2 or q.x > N - 3 or q.y > N - 3 or not g.solid(q.x, q.y):
				break
			if not (g.solid(q.x + dvec.y, q.y + dvec.x) and g.solid(q.x - dvec.y, q.y - dvec.x)):
				break
			g.setc(q.x, q.y, SHALLOW, 2.2)
			p = q
			ln += 1
		if ln >= 3:
			ends.append(Vector3((p.x + 0.5) * C, SHALLOW, (p.y + 0.5) * C))
	meta["tunnel_ends"] = ends
	meta["dark"] = true


## Abnormally shaped open area: relief ceilings, round basins whose floors fall
## in terraces (true variable depth), angled free-standing walls, scattered
## round pillars, one large tilted light plane.
static func open(g, r: RandomNumberGenerator, ops: Array, meta: Dictionary) -> void:
	var ceil := 5.5 + 0.5 * (r.randi() % 4)
	g.rect(1, 1, N - 1, N - 1, WALK, ceil)
	var dome := Rect2i()
	for n in 2:
		var a := 2 + r.randi() % 8
		var b := 2 + r.randi() % 8
		var rr := Rect2i(a, b, 2 + r.randi() % 4, 2 + r.randi() % 4)
		g.ceil_rect(rr.position.x, rr.position.y, rr.end.x, rr.end.y, ceil - 2.0 if n == 0 else ceil + 2.5)
		if n == 1:
			dome = rr
	for n in 2 + r.randi() % 2:
		var bx := 4.0 + r.randf() * 8.0
		var bz := 4.0 + r.randf() * 8.0
		var rad := 2.0 + r.randf() * 2.6
		var d0 := -0.9 - 0.3 * (r.randi() % 3)
		for j in range(2, N - 2):
			for i in range(2, N - 2):
				var dist := Vector2(i + 0.5 - bx, j + 0.5 - bz).length()
				if dist < rad and not g.solid(i, j):
					g.setc(i, j, minf(g.f(i, j), d0 - 0.7 * floorf((rad - dist) / 1.3)))
		var si := clampi(int(bx), 2, N - 3)
		var sj := clampi(int(bz), 2, N - 3)
		var ei := si
		while ei < N - 2 and g.f(ei + 1, sj) < WALK - 0.01:
			ei += 1
		if ei < N - 2 and not g.solid(ei + 1, sj) and g.f(ei + 1, sj) >= WALK - 0.01 and g.f(ei, sj) < WALK - 0.3:
			var top := Vector3((ei + 1) * C, WALK, (sj + 0.5) * C)
			g.stair(top, Vector3(-1, 0, 0), C - 0.2, g.f(ei, sj))
			g.reserve(ei, sj, ei + 2, sj + 1)
	for n in 2 + r.randi() % 2:
		var wx := 9.0 + r.randf() * 14.0
		var wz := 9.0 + r.randf() * 14.0
		if g.is_res(int(wx / C), int(wz / C)):
			continue
		g.walls.append({"x": wx, "z": wz, "len": 4.0 + r.randf() * 3.0,
			"rot": r.randf_range(0.35, 1.2) * (1.0 if r.randf() < 0.5 else -1.0), "h": ceil - 1.2})
	for n in 4 + r.randi() % 4:
		var i := 2 + r.randi() % 12
		var j := 2 + r.randi() % 12
		if not g.is_res(i, j):
			g.pillars.append({"x": (i + r.randf()) * C, "z": (j + r.randf()) * C, "s": 0.7 + r.randf() * 0.8, "round": true})
	var lx := (dome.position.x + dome.size.x * 0.5) * C
	var lz := (dome.position.y + dome.size.y * 0.5) * C
	var n := Vector3(r.randf_range(-0.7, 0.7), -1.0, r.randf_range(-0.7, 0.7)).normalized()
	var hu := n.cross(Vector3(0, 0, 1)).normalized() * (2.0 + r.randf() * 1.5)
	var hv := n.cross(hu).normalized() * (1.0 + r.randf())
	g.lights.append({"t": "tilt", "p": Vector3(lx, ceil + 1.6, lz), "n": n, "hu": hu, "hv": hv, "e": 4.0, "low": ceil})
	meta["open"] = true
