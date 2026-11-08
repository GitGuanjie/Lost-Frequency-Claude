extends RefCounted
## Level 1.1 "Corrupted Corridor": the streamed corridor (design notes in L001_1.gd).
## The corridor runs along -Z from the Level 1 entrance at z = 0. It is cut into
## 6 m segments (four per 24 m chunk); a precomputed profile gives every segment its
## floor heights, width and ceiling height, so slopes, jogs and repeats stay
## continuous across chunk borders and identical for a seed.

const S := 24.0
const SEG := 6.0
const SPC := 4
const N_CH := 30          # chunks 1..29 hold corridor; 30+ is void
const WALL_T := 0.25

var lvl
var Y: Array = []         # floor height at segment boundary g (0..)
var W: Array = []         # width of segment g
var HC: Array = []        # ceiling height of segment g
var HUE: Array = []       # hue variant per chunk (Sector 2)
var DSEED: Array = []     # decoration seed per chunk (repeats share one)
var REPEAT: Dictionary = {}
var min_y := 0.0


func _init(level) -> void:
	lvl = level


static func sector(n: int) -> int:
	if n <= 8:
		return 1
	if n <= 18:
		return 2
	if n <= 25:
		return 3
	if n <= 29:
		return 4
	return 5


static func depth_sector(d: float) -> int:
	return sector(int(ceil(maxf(d, 0.01) / S)))


func profile(rng: RandomNumberGenerator) -> void:
	REPEAT = {10: 9, 11: 9, 15: 14, 16: 14}
	Y = [0.0]
	DSEED = [0]
	HUE = [0]
	for n in range(1, N_CH + 1):
		var sec := sector(n)
		DSEED.append(DSEED[REPEAT[n]] if REPEAT.has(n) else n)
		HUE.append(HUE[REPEAT[n]] if REPEAT.has(n) else (1 + rng.randi() % 4 if sec == 2 and rng.randf() < 0.75 else 0))
		for kl in SPC:
			var g := (n - 1) * SPC + kl
			if REPEAT.has(n):
				var src: int = (REPEAT[n] - 1) * SPC + kl
				W.append(W[src])
				HC.append(HC[src])
				Y.append(Y[g] + (Y[src + 1] - Y[src]))
				continue
			match sec:
				1:
					W.append(7.2 if n == 8 else 3.66)
					HC.append(3.0 if n == 8 else (snappedf(rng.randf_range(2.15, 3.6), 0.05) if n > 1 or kl > 0 else 2.75))
					Y.append(Y[g])
				2:
					W.append(3.66)
					HC.append(snappedf(rng.randf_range(2.6, 3.2), 0.05))
					var amp := clampf(float(n - 8) / 8.0, 0.25, 1.0)
					var dy := 0.0
					if (kl != 0 or n == 9) and not n in [13, 17]:
						dy = rng.randf_range(-2.6, 2.6) * amp
						if absf(dy) < 0.4:
							dy = 0.0
					Y.append(Y[g] + dy)
				3:
					W.append(snappedf(rng.randf_range(1.85, 6.1), 0.05))
					HC.append(6.1)
					Y.append(Y[g])
				_:
					W.append(3.66)
					HC.append(4.6)
					Y.append(Y[g])
	for y in Y:
		min_y = minf(min_y, y)


func seg_z0(g: int) -> float:
	return -g * SEG


## Floor height at depth d (linear inside a segment).
func floor_at(d: float) -> float:
	var g := clampi(int(floor(d / SEG)), 0, W.size() - 1)
	var f := clampf((d - g * SEG) / SEG, 0.0, 1.0)
	return lerpf(Y[g], Y[g + 1], f)


func width_at(d: float) -> float:
	return W[clampi(int(floor(d / SEG)), 0, W.size() - 1)]


## Core corridor shell for chunk n (floor, walls, ceiling, jogs, fixtures).
## Materials come from mats {wall, floor, ceil}. Returns the light fixture points.
func shell(k: GeoKit, n: int, mats: Dictionary, r: RandomNumberGenerator, skip_wall: Dictionary) -> Array:
	var fixtures: Array = []
	var sec := sector(n)
	for kl in SPC:
		var g := (n - 1) * SPC + kl
		var z0 := seg_z0(g)
		var z1 := z0 - SEG
		var y0: float = Y[g]
		var y1: float = Y[g + 1]
		var w: float = W[g]
		var hc: float = HC[g]
		var hw := w * 0.5
		# floor
		if absf(y1 - y0) < 0.01:
			if not mats.get("nofloor", false):
				k.box_mm(Vector3(-hw, y0 - 0.3, z1), Vector3(hw, y0, z0), mats["floor"])
			k.box_mm(Vector3(-hw, y0 + hc, z1), Vector3(hw, y0 + hc + 0.3, z0), mats["ceil"])
		else:
			k.ramp(Vector3(0, y0, z0), Vector3(0, y1, z1), w, 0.3, mats["floor"])
			var c0 := Vector3(0, y0 + hc + 0.3, z0)
			var c1 := Vector3(0, y1 + hc + 0.3, z1)
			k.ramp(c0, c1, w, 0.3, mats["ceil"])
		var lo := minf(y0, y1) - 0.4
		var hi := maxf(y0, y1) + hc + 0.35
		for side in [-1.0, 1.0]:
			var key := "%d_%d" % [kl, int(side)]
			if skip_wall.has(key):
				var ops: Array = skip_wall[key]
				var a := Vector3(side * (hw + WALL_T * 0.5), lo, z0)
				var b := Vector3(side * (hw + WALL_T * 0.5), lo, z1)
				# openings are given relative to the floor; shift by the wall base
				var sh: Array = []
				for op in ops:
					var o: Dictionary = (op as Dictionary).duplicate()
					o["sill"] = float(o.get("sill", 0.0)) + (y0 - lo)
					sh.append(o)
				k.wall(a, b, hi - lo, WALL_T, mats["wall"], sh)
			else:
				k.box_mm(Vector3(side * hw - (WALL_T if side < 0 else 0.0), lo, z1), Vector3(side * hw + (WALL_T if side > 0 else 0.0), hi, z0), mats["wall"])
		# jog / bulkhead where the next segment differs
		if g + 1 < W.size():
			var w2: float = W[g + 1]
			var hc2: float = HC[g + 1]
			if absf(w2 - w) > 0.01:
				var a0 := minf(w, w2) * 0.5
				var a1 := maxf(w, w2) * 0.5 + WALL_T
				var top := y1 + maxf(hc, hc2) + 0.3
				for side in [-1.0, 1.0]:
					k.box_mm(Vector3(minf(side * a0, side * a1), y1 - 0.4, z1 - 0.12), Vector3(maxf(side * a0, side * a1), top, z1 + 0.12), mats["wall"])
				if w2 > w:
					k.box_mm(Vector3(-w2 * 0.5, y1 + hc, z1 - 0.12), Vector3(w2 * 0.5, y1 + maxf(hc, hc2) + 0.3, z1 + 0.12), mats["ceil"], GeoKit.ALL, false)
			if absf(hc2 - hc) > 0.01:
				var wm := maxf(w, w2) * 0.5
				k.box_mm(Vector3(-wm, y1 + minf(hc, hc2), z1 - 0.15), Vector3(wm, y1 + maxf(hc, hc2) + 0.3, z1 + 0.15), mats["ceil"], GeoKit.ALL, false)
		# a fluorescent fixture per segment (sector rules decide if it is lit)
		var fz := z0 - SEG * 0.5
		var fy := lerpf(y0, y1, 0.5) + hc
		fixtures.append(Vector3(0, fy, fz))
	return fixtures


## Surface-mounted twin-tube fixture: housing + emissive diffuser.
static func fixture(k: GeoKit, p: Vector3, tube: String, seed_v: float) -> void:
	k.box(p + Vector3(0, -0.04, 0), Vector3(0.28, 0.08, 1.26), "l11_metal", GeoKit.ALL, false)
	k.panel(p + Vector3(0, -0.085, 0), 0.22, 1.2, tube, seed_v)


## A crack in the block wall showing pipes behind it (page: exposed piping and
## ducts appear through cracks and holes). Returns the opening for the wall.
static func crack(k: GeoKit, side: float, hw: float, z: float, y: float, r: RandomNumberGenerator) -> Dictionary:
	var w := r.randf_range(0.9, 1.8)
	var h := r.randf_range(0.7, 1.4)
	var sill := r.randf_range(0.5, 1.2)
	var xin := side * (hw + WALL_T)
	var xout := side * (hw + WALL_T + 0.55)
	var x_lo := minf(xin, xout)
	var x_hi := maxf(xin, xout)
	var zl := z - w * 0.5 - 0.1
	var zh := z + w * 0.5 + 0.1
	var yb := y + sill
	var yt := y + sill + h
	k.box_mm(Vector3(minf(xout, xout - side * 0.06), yb - 0.1, zl), Vector3(maxf(xout, xout - side * 0.06), yt + 0.1, zh), "l11_cavity", GeoKit.ALL, false)
	k.box_mm(Vector3(x_lo, yb - 0.1, zl), Vector3(x_hi, yb, zh), "l11_cavity", GeoKit.ALL, false)
	k.box_mm(Vector3(x_lo, yt, zl), Vector3(x_hi, yt + 0.1, zh), "l11_cavity", GeoKit.ALL, false)
	k.box_mm(Vector3(x_lo, yb, zl - 0.06), Vector3(x_hi, yt, zl), "l11_cavity", GeoKit.ALL, false)
	k.box_mm(Vector3(x_lo, yb, zh), Vector3(x_hi, yt, zh + 0.06), "l11_cavity", GeoKit.ALL, false)
	for i in r.randi_range(2, 3):
		var py := y + sill + 0.15 + i * (h - 0.3) / 2.0
		var px := side * (hw + WALL_T + 0.2 + 0.1 * (i % 2))
		var m := "l11_rust" if r.randf() < 0.5 else "l11_pipe"
		k.box(Vector3(px, py, z), Vector3(0.11, 0.11, w + 0.3), m, GeoKit.ALL, false)
	# broken block pieces under the hole
	for i in r.randi_range(2, 4):
		var bp := Vector3(side * (hw - r.randf_range(0.1, 0.5)), y + 0.08, z + r.randf_range(-w * 0.5, w * 0.5))
		k.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * PI).rotated(Vector3.RIGHT, r.randf_range(-0.4, 0.4)), bp), Vector3(0.3, 0.15, 0.18), "l11_block", GeoKit.ALL, false)
	return {"at": 0.0, "w": w, "h": h, "sill": sill, "z": z}
