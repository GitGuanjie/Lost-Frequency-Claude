extends RefCounted
## Level 37 "Sublimity" — cell grammar for one 32 m chunk (16 x 16 cells, 2 m).
## A cell is either SOLID tiled masonry (BASE..TOP) or open, with a floor top and
## a ceiling height. The water surface is y = 0 everywhere, so every floor below
## zero is submerged and the depth varies with the floor, never with the water.
## Floors are emitted as merged tiled columns from BASE up to the floor top, so
## pool walls, pit walls and ledgeless drops are the exposed sides of columns.
## Positions recorded here (stairs, pillars, lights) are LOCAL metres; L037.gd
## adds the chunk origin when it emits them.

const N := 16
const C := 2.0
const SOLID := 1000.0
const BASE := -9.0
const TOP := 11.0           # above this is the bright void seen through open wells

var fy := PackedFloat32Array()      # floor top per cell (SOLID = masonry)
var cy := PackedFloat32Array()      # ceiling height per cell
var lock := PackedByteArray()       # 1 = passage / landing floor painters keep
var res := PackedByteArray()        # 1 = reserved (stairs, approaches): no pillar
var stairs: Array = []              # {top: Vector3 local top-edge centre, d: Vector3 down dir, w, bot}
var pillars: Array = []             # {x, z, s, round, rot}
var walls: Array = []               # free-standing angled partitions {x, z, len, rot, h}
var lights: Array = []              # light features, consumed by L037.gd


func _init() -> void:
	fy.resize(N * N)
	cy.resize(N * N)
	lock.resize(N * N)
	res.resize(N * N)
	fy.fill(SOLID)
	cy.fill(4.0)


func inside(i: int, j: int) -> bool:
	return i >= 0 and j >= 0 and i < N and j < N


func f(i: int, j: int) -> float:
	return fy[j * N + i] if inside(i, j) else SOLID


func solid(i: int, j: int) -> bool:
	return f(i, j) >= SOLID


func is_res(i: int, j: int) -> bool:
	return (not inside(i, j)) or res[j * N + i] == 1


## Floor (unless the cell is locked) and optionally ceiling.
func setc(i: int, j: int, y: float, ceil: float = -1.0, force: bool = false) -> void:
	if not inside(i, j):
		return
	var k := j * N + i
	if force or lock[k] == 0:
		fy[k] = y
	if ceil > 0.0:
		cy[k] = ceil


func rect(i0: int, j0: int, i1: int, j1: int, y: float, ceil: float = -1.0) -> void:
	for j in range(maxi(j0, 0), mini(j1, N)):
		for i in range(maxi(i0, 0), mini(i1, N)):
			setc(i, j, y, ceil)


func ceil_rect(i0: int, j0: int, i1: int, j1: int, c: float) -> void:
	for j in range(maxi(j0, 0), mini(j1, N)):
		for i in range(maxi(i0, 0), mini(i1, N)):
			cy[j * N + i] = c


func reserve(i0: int, j0: int, i1: int, j1: int) -> void:
	for j in range(maxi(j0, 0), mini(j1, N)):
		for i in range(maxi(i0, 0), mini(i1, N)):
			res[j * N + i] = 1


func lock_cell(i: int, j: int) -> void:
	if inside(i, j):
		lock[j * N + i] = 1
		res[j * N + i] = 1


func min_floor() -> float:
	var m := SOLID
	for v in fy:
		m = minf(m, v)
	return m


## Record a staircase. top = local top-edge centre at the upper floor height,
## d = horizontal unit vector pointing DOWN the flight, w = width, bot = lower floor.
func stair(top: Vector3, d: Vector3, w: float, bot: float) -> void:
	stairs.append({"top": top, "d": d, "w": w, "bot": bot})


## Horizontal length a flight needs for a given rise (matches emit_stairs).
static func run_for(rise: float) -> float:
	return 0.3 * maxi(2, ceili(rise / 0.25))


# --------------------------------------------------------------- emission

## Greedy rectangles of equal value; skip(k) excludes cells.
func _merge(vals: PackedFloat32Array, skip: Callable) -> Array:
	var out: Array = []
	var seen := PackedByteArray()
	seen.resize(N * N)
	for j in N:
		for i in N:
			var k := j * N + i
			if seen[k] == 1 or skip.call(k):
				continue
			var v := vals[k]
			var i1 := i + 1
			while i1 < N and seen[j * N + i1] == 0 and not skip.call(j * N + i1) and vals[j * N + i1] == v:
				i1 += 1
			var j1 := j + 1
			var grow := true
			while j1 < N and grow:
				for ii in range(i, i1):
					var kk := j1 * N + ii
					if seen[kk] == 1 or skip.call(kk) or vals[kk] != v:
						grow = false
						break
				if grow:
					j1 += 1
			for jj in range(j, j1):
				for ii in range(i, i1):
					seen[jj * N + ii] = 1
			out.append([i, j, i1, j1, v])
	return out


## Floors, masonry and ceilings as merged tiled boxes. Cells whose ceiling is
## at or above TOP are open wells (no ceiling box).
func emit(k: GeoKit, ox: float, oz: float, mat: String, ceil_mat: String) -> void:
	for r in _merge(fy, func(_kk: int) -> bool: return false):
		var y: float = r[4]
		var mn := Vector3(ox + r[0] * C, BASE, oz + r[1] * C)
		if y >= SOLID:
			k.box_mm(mn, Vector3(ox + r[2] * C, TOP, oz + r[3] * C), mat, GeoKit.SIDES)
		else:
			k.box_mm(mn, Vector3(ox + r[2] * C, y, oz + r[3] * C), mat, GeoKit.PY | GeoKit.SIDES)
	for r in _merge(cy, func(kk: int) -> bool: return fy[kk] >= SOLID or cy[kk] >= TOP):
		k.box_mm(Vector3(ox + r[0] * C, r[4], oz + r[1] * C), Vector3(ox + r[2] * C, TOP, oz + r[3] * C), ceil_mat, GeoKit.NY | GeoKit.SIDES)


## Visual steps + smooth ramp collision (GeoKit.stairs); deep flights also get
## stepped collision mass beneath the ramp so swimmers cannot pass under them.
func emit_stairs(k: GeoKit, ox: float, oz: float, mat: String) -> void:
	for s in stairs:
		var top: Vector3 = s["top"] + Vector3(ox, 0, oz)
		var d: Vector3 = s["d"]
		var w: float = s["w"]
		var bot: float = s["bot"]
		var rise := top.y - bot
		if rise < 0.05:
			continue
		var steps := maxi(2, ceili(rise / 0.25))
		var run := 0.3
		var start := top + d * (run * steps)
		start.y = bot
		k.stairs(start, -d, w, rise, steps, mat, run, true)
		if rise > 1.0:
			var h := rise / steps
			var a := 1
			while a < steps:
				var b := mini(steps, a + 3)
				var c := start - d * (run * (a + b) * 0.5)
				c.y = bot + h * a * 0.5
				var along := run * (b - a)
				var size := Vector3(absf(d.x) * along + absf(d.z) * w, h * a, absf(d.z) * along + absf(d.x) * w)
				k.box(c, size, mat, 0, true)
				a = b


func emit_pillars(k: GeoKit, ox: float, oz: float, mat: String) -> void:
	for p in pillars:
		var ci := floori(float(p["x"]) / C)
		var cj := floori(float(p["z"]) / C)
		if inside(ci, cj) and cy[cj * N + ci] >= TOP:
			continue   # never under an open well
		var c := Vector3(ox + float(p["x"]), (BASE + TOP) * 0.5, oz + float(p["z"]))
		var s: float = p["s"]
		if p.get("round", false):
			k.cylinder(c, s * 0.5, TOP - BASE, mat, 20, true, false)
		elif absf(float(p.get("rot", 0.0))) > 0.001:
			k.box_xf(Transform3D(Basis(Vector3.UP, float(p["rot"])), c), Vector3(s, TOP - BASE, s), mat, GeoKit.SIDES)
		else:
			k.box(c, Vector3(s, TOP - BASE, s), mat, GeoKit.SIDES)
	for wdef in walls:
		var h: float = wdef["h"]
		var c := Vector3(ox + float(wdef["x"]), (BASE + h) * 0.5, oz + float(wdef["z"]))
		k.box_xf(Transform3D(Basis(Vector3.UP, float(wdef["rot"])), c), Vector3(float(wdef["len"]), h - BASE, 0.5), mat, GeoKit.ALL)
