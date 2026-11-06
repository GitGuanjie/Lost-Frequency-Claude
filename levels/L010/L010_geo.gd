extends RefCounted
## Level 10 meshing. Near chunks (64 m): 2 m terrain mesh with matching 1 m
## HeightMapShape3D collision, crop canopy sheets with skirts, dirt-track
## ribbons, lumpy constant-height hedges, tree lines (MultiMesh crowns) and
## farm structures. Far chunks (same grid, out to ~350 m): 8 m terrain with the
## canopy baked into vertex colour, box hedges, low-detail crowns, structure
## silhouettes. Crop tiles (16 m): thousands of stalk clumps per tile as one
## MultiMesh per crop, streamed around the camera with a visibility range.

const B := preload("res://levels/L010/L010_barn.gd")
const W := preload("res://levels/L010/L010_world.gd")
const P := preload("res://levels/L010/L010_proto.gd")
const CS := 64.0
const G := 35
const TILE := 16.0
const STEP := 0.45

var w
var clump: Array = []
var crown_hi: Array = []
var crown_lo: Array = []
var trunk: ArrayMesh
var worm: ArrayMesh
var _hb: Array = []


func _init(world) -> void:
	w = world
	clump = [null, P.clump(1), P.clump(2), P.clump(3), P.clump(4)]
	for i in 3:
		crown_hi.append(P.blob(1, 11 + i))
		crown_lo.append(P.blob(0, 21 + i))
	trunk = P.trunk()
	worm = P.worm()


static func H(hs: PackedFloat32Array, gx: int, gz: int) -> float:
	return hs[(gz + 1) * G + gx + 1]


## Height of the rendered terrain at (x, z) (same triangle split as the mesh).
func hm(meta: Dictionary, x: float, z: float) -> float:
	var hs: PackedFloat32Array = meta["hs"]
	var fx := clampf((x - float(meta["ox"])) * 0.5, -1.0, 32.999)
	var fz := clampf((z - float(meta["oz"])) * 0.5, -1.0, 32.999)
	var gx := floori(fx)
	var gz := floori(fz)
	var u := fx - gx
	var t := fz - gz
	var a := H(hs, gx, gz)
	var c := H(hs, gx + 1, gz + 1)
	if u >= t:
		var b := H(hs, gx + 1, gz)
		return a + (b - a) * u + (c - b) * t
	var d := H(hs, gx, gz + 1)
	return a + (c - d) * u + (d - a) * t


static func code(t: int) -> float:
	return [0.0, 0.0, 0.5, 1.0][t]


# ---------------------------------------------------------------- near

func near(cx: int, cz: int, node: Node3D) -> Dictionary:
	var ox := cx * CS
	var oz := cz * CS
	var hs := PackedFloat32Array()
	hs.resize(G * G)
	for gz in G:
		for gx in G:
			hs[gz * G + gx] = w.h_at(ox + (gx - 1) * 2.0, oz + (gz - 1) * 2.0)
	var cr := PackedByteArray()
	cr.resize(34 * 34)
	for l in 34:
		for k in 34:
			var hc := (hs[l * G + k] + hs[l * G + k + 1] + hs[(l + 1) * G + k] + hs[(l + 1) * G + k + 1]) * 0.25
			cr[l * 34 + k] = w.crop_at(ox + (k - 0.5) * 2.0, oz + (l - 0.5) * 2.0, hc)
	var meta := {"ox": ox, "oz": oz, "hs": hs, "cr": cr, "structs": [], "canola": [], "tiles": {}}
	_terrain(meta, node)
	_canopy(meta, node)
	_tracks(meta, node)
	var body := StaticBody3D.new()
	body.name = "Bounds"
	node.add_child(body)
	var fol := P.MB.new()
	var trees: Array = []
	_hb = [[], [], []]
	_bounds(meta, fol, body, trees, true)
	fol.inst(node, "l10_hedge")
	for v in 3:
		_mm(node, crown_lo[v], "l10_hedge", _hb[v], true)
	_trees(meta, trees, node, body, true)
	_structs(meta, node, true)
	return meta


func _terrain(meta: Dictionary, node: Node3D) -> void:
	var hs: PackedFloat32Array = meta["hs"]
	var cr: PackedByteArray = meta["cr"]
	var ox: float = meta["ox"]
	var oz: float = meta["oz"]
	var mb := P.MB.new()
	for gz in 33:
		for gx in 33:
			var x := ox + gx * 2.0
			var z := oz + gz * 2.0
			var nrm := Vector3(H(hs, gx - 1, gz) - H(hs, gx + 1, gz), 4.0, H(hs, gx, gz - 1) - H(hs, gx, gz + 1)).normalized()
			var soil := 0.0
			var kind := 0
			for q in [Vector2i(gx, gz), Vector2i(gx + 1, gz), Vector2i(gx, gz + 1), Vector2i(gx + 1, gz + 1)]:
				var t: int = cr[q.y * 34 + q.x]
				if t > 0:
					soil += 0.25
					kind = maxi(kind, t)
			if soil == 0.0:
				var y: Rect2 = w.plot_at(x, z)["yard"]
				if y.size.x > 0.0 and y.grow(-1.0).has_point(Vector2(x, z)):
					soil = 0.45 * (0.5 + 0.5 * sin(x * 0.7) * sin(z * 0.53))
			mb.vert(Vector3(x, H(hs, gx, gz), z), nrm, Color(soil, 0.0, code(kind)), Vector2(x, z))
	var bx := roundi(ox / 2.0)
	var bz := roundi(oz / 2.0)
	for r in 32:
		for c in 32:
			if w.is_hole(bx + c, bz + r):
				continue
			var a := r * 33 + c
			mb.i.append_array([a, a + 1, a + 34, a, a + 34, a + 33])
	var mi := mb.inst(node, "l10_terrain")
	mi.name = "Terrain"
	var md := PackedFloat32Array()
	md.resize(65 * 65)
	for sz in 65:
		for sx in 65:
			var gx := sx >> 1
			var gz := sz >> 1
			var a := H(hs, gx, gz)
			if sx & 1 == 0 and sz & 1 == 0:
				md[sz * 65 + sx] = a
			elif sz & 1 == 0:
				md[sz * 65 + sx] = (a + H(hs, gx + 1, gz)) * 0.5
			elif sx & 1 == 0:
				md[sz * 65 + sx] = (a + H(hs, gx, gz + 1)) * 0.5
			else:
				md[sz * 65 + sx] = (a + H(hs, gx + 1, gz + 1)) * 0.5
	var sh := HeightMapShape3D.new()
	sh.map_width = 65
	sh.map_depth = 65
	sh.map_data = md
	var body := StaticBody3D.new()
	body.name = "Ground"
	var cs := CollisionShape3D.new()
	cs.shape = sh
	cs.position = Vector3(ox + 32.0, 0.0, oz + 32.0)
	cs.set_meta("surface", "grass")
	body.add_child(cs)
	node.add_child(body)


func _canopy(meta: Dictionary, node: Node3D) -> void:
	var hs: PackedFloat32Array = meta["hs"]
	var cr: PackedByteArray = meta["cr"]
	var ox: float = meta["ox"]
	var oz: float = meta["oz"]
	var mb := P.MB.new()
	var rows_of := {}
	for r in 32:
		for c in 32:
			var t: int = cr[(r + 1) * 34 + c + 1]
			if t == 0:
				continue
			var ch: float = W.CANOPY[t]
			var x0 := ox + c * 2.0
			var z0 := oz + r * 2.0
			var p: Dictionary = w.plot_at(x0 + 1.0, z0 + 1.0)
			var col := Color(1.0 if p["rows"] else 0.0, 0.0, code(t))
			var g := [H(hs, c, r), H(hs, c + 1, r), H(hs, c + 1, r + 1), H(hs, c, r + 1)]
			var pts := [Vector3(x0, g[0] + ch, z0), Vector3(x0 + 2.0, g[1] + ch, z0), Vector3(x0 + 2.0, g[2] + ch, z0 + 2.0), Vector3(x0, g[3] + ch, z0 + 2.0)]
			# the sheet stops behind the first two rows of edge stalks
			var il := 0.4 if cr[(r + 1) * 34 + c] != t else 0.0
			var ir := 0.4 if cr[(r + 1) * 34 + c + 2] != t else 0.0
			var iff := 0.4 if cr[r * 34 + c + 1] != t else 0.0
			var ib := 0.4 if cr[(r + 2) * 34 + c + 1] != t else 0.0
			var tp := [pts[0] + Vector3(il, 0, iff), pts[1] + Vector3(-ir, 0, iff), pts[2] + Vector3(-ir, 0, -ib), pts[3] + Vector3(il, 0, -ib)]
			var nrm: Vector3 = (pts[2] - pts[0]).cross(pts[1] - pts[3]).normalized()
			if nrm.y < 0.0:
				nrm = -nrm
			var a := mb.vert(tp[0], nrm, col)
			mb.vert(tp[1], nrm, col)
			mb.vert(tp[2], nrm, col)
			mb.vert(tp[3], nrm, col)
			mb.quad(a, a + 1, a + 2, a + 3, Vector3.UP)
			# skirts where the crop (or its height) changes
			var sides := [[Vector2i(-1, 0), 0, 3, Vector3.LEFT], [Vector2i(1, 0), 1, 2, Vector3.RIGHT], [Vector2i(0, -1), 0, 1, Vector3.FORWARD], [Vector2i(0, 1), 3, 2, Vector3.BACK]]
			for s in sides:
				var o: Vector2i = s[0]
				if cr[(r + 1 + o.y) * 34 + c + 1 + o.x] == t:
					continue
				var nn: Vector3 = s[3]
				for lay in 3:
					var ins: Vector3 = nn * -[0.02, 0.3, 0.62][lay]
					var p0: Vector3 = pts[s[1]] + ins
					var p1: Vector3 = pts[s[2]] + ins
					var lc := Color(col.r, lay * 0.5, col.b)
					var b := mb.vert(p0 - Vector3(0, ch + 0.06, 0), nn, lc, Vector2(ch, -0.06))
					mb.vert(p1 - Vector3(0, ch + 0.06, 0), nn, lc, Vector2(ch, -0.06))
					mb.vert(p1 + Vector3(0, 0.3, 0), nn, lc, Vector2(ch, ch + 0.3))
					mb.vert(p0 + Vector3(0, 0.3, 0), nn, lc, Vector2(ch, ch + 0.3))
					mb.quad(b, b + 1, b + 2, b + 3, nn)
	mb.inst(node, "l10_canopy")


func _tracks(meta: Dictionary, node: Node3D) -> void:
	var ox: float = meta["ox"]
	var oz: float = meta["oz"]
	var mb := P.MB.new()
	for i in range(w.xi(ox - 8.0), w.xi(ox + CS + 8.0) + 1):
		var tx: float = w.xline(i) + W.TOFF
		if w.xtrack(i) and tx >= ox and tx < ox + CS:
			_ribbon(mb, meta, true, tx, oz, oz + CS)
	for j in range(w.zi(oz - 8.0), w.zi(oz + CS + 8.0) + 1):
		var tz: float = w.zline(j) + W.TOFF
		if w.ztrack(j) and tz >= oz and tz < oz + CS:
			_ribbon(mb, meta, false, tz, ox, ox + CS)
	mb.inst(node, "l10_track", false)


func _ribbon(mb: P.MB, meta: Dictionary, along_z: bool, c: float, a: float, b: float) -> void:
	var across := [-W.THW, -1.05, 0.0, 1.05, W.THW]
	var steps := int((b - a) / 2.0)
	var lift := 0.0 if along_z else 0.012
	var base := mb.v.size()
	for s in steps + 1:
		var t := a + s * 2.0
		for o in across:
			var x: float = c + o if along_z else t
			var z: float = t if along_z else c + o
			mb.vert(Vector3(x, hm(meta, x, z) + lift, z), Vector3.UP, Color.WHITE, Vector2(o, t))
	for s in steps:
		for q in 4:
			var i0 := base + s * 5 + q
			mb.quad(i0, i0 + 1, i0 + 6, i0 + 5, Vector3.UP)


## Pieces [from, to, taper_from, taper_to] of a boundary segment clipped to [a, b].
static func _cut(s0: float, s1: float, a: float, b: float, gp: Array) -> Array:
	var out: Array = []
	var cur := a
	var tcur := is_equal_approx(a, s0)
	var sorted := gp.duplicate()
	sorted.sort_custom(func(p, q): return p.x < q.x)
	for g in sorted:
		if g.y <= cur or g.x >= b:
			continue
		if g.x > cur + 0.3:
			out.append([cur, g.x, tcur, true])
		cur = g.y
		tcur = true
	if b > cur + 0.3:
		out.append([cur, b, tcur, is_equal_approx(b, s1)])
	return out


## Hedges (mesh + collision) and the tree positions of every boundary in the chunk.
func _bounds(meta: Dictionary, mb, body: StaticBody3D, trees: Array, hi: bool) -> void:
	var ox: float = meta["ox"]
	var oz: float = meta["oz"]
	for vert in [true, false]:
		var o0 := ox if vert else oz
		var a0 := oz if vert else ox
		var l0: int = w.xi(o0) if vert else w.zi(o0)
		var l1: int = w.xi(o0 + CS - 0.01) if vert else w.zi(o0 + CS - 0.01)
		for li in range(l0, l1 + 1):
			var lp: float = w.xline(li) if vert else w.zline(li)
			if lp < o0 or lp >= o0 + CS:
				continue
			var m0: int = w.zi(a0) if vert else w.xi(a0)
			var m1: int = w.zi(a0 + CS - 0.01) if vert else w.xi(a0 + CS - 0.01)
			for m in range(m0, m1 + 1):
				var kind: int = w.xseg(li, m) if vert else w.zseg(m, li)
				var s0: float = w.zline(m) if vert else w.xline(m)
				var s1: float = w.zline(m + 1) if vert else w.xline(m + 1)
				var a := maxf(s0, a0)
				var b := minf(s1, a0 + CS)
				var gp: Array = w.gaps(true, li, m) if vert else w.gaps(false, m, li)
				if kind == 1 or kind == 2:
					for pc in _cut(s0, s1, a, b, gp + _wet(vert, lp, a, b)):
						if hi:
							_hedge(mb, body, meta, vert, lp, pc)
						else:
							_hedge_far(mb, vert, lp, pc)
				if kind >= 2:
					var r := RandomNumberGenerator.new()
					r.seed = hash([w.sd, li, m, vert, 77])
					var t := s0 + r.randf_range(3.0, 9.0)
					while t < s1 - 3.0:
						var ok: bool = t >= a and t < b and (w.h_at(lp, t) if vert else w.h_at(t, lp)) > W.WATER_Y + 0.4
						for g in gp:
							if t > g.x - 2.5 and t < g.y + 2.5:
								ok = false
						var off := r.randf_range(-0.5, 0.5)
						var sc := r.randf_range(0.8, 1.3)
						if ok:
							trees.append([Vector3(lp + off, 0, t) if vert else Vector3(t, 0, lp + off), sc, r.randi()])
						t += r.randf_range(8.0, 17.0) if kind == 2 else r.randf_range(6.5, 11.0)
	# a few field trees in grass plots
	for i in range(w.xi(ox), w.xi(ox + CS - 0.01) + 1):
		for j in range(w.zi(oz), w.zi(oz + CS - 0.01) + 1):
			var p: Dictionary = w.plot(i, j)
			if p["crop"] != 0 or p["home"]:
				continue
			var r := RandomNumberGenerator.new()
			r.seed = hash([w.sd, i, j, 78])
			var rc: Rect2 = p["rect"]
			for n in 2 + r.randi() % 4:
				var q := Vector3(r.randf_range(rc.position.x, rc.end.x), 0, r.randf_range(rc.position.y, rc.end.y))
				var sc := r.randf_range(0.9, 1.4)
				var sd := r.randi()
				if q.x >= ox and q.x < ox + CS and q.z >= oz and q.z < oz + CS and w.h_at(q.x, q.z) > W.WATER_Y + 0.4:
					trees.append([q, sc, sd])


## Stretches of a boundary line whose ground lies under (or at) the water level.
func _wet(vert: bool, lp: float, a: float, b: float) -> Array:
	var out: Array = []
	var t := a
	var st := -1.0
	while t <= b + 0.01:
		var g: float = w.h_at(lp, t) if vert else w.h_at(t, lp)
		if g < W.WATER_Y + 1.2 and st < 0.0:
			st = t - 1.0
		elif g >= W.WATER_Y + 1.2 and st >= 0.0:
			out.append(Vector2(st, t + 1.0))
			st = -1.0
		t += 2.0
	if st >= 0.0:
		out.append(Vector2(st, b + 2.0))
	return out


const PROF := [Vector2(-0.8, -0.3), Vector2(-0.95, 0.45), Vector2(-0.8, 1.12), Vector2(-0.42, 1.55), Vector2(0.42, 1.55), Vector2(0.8, 1.12), Vector2(0.95, 0.45), Vector2(0.8, -0.3)]
const PNRM := [Vector2(-1, -0.3), Vector2(-1, 0.05), Vector2(-0.8, 0.6), Vector2(-0.25, 1), Vector2(0.25, 1), Vector2(0.8, 0.6), Vector2(1, 0.05), Vector2(1, -0.3)]


func _hedge(mb: P.MB, body: StaticBody3D, meta: Dictionary, vert: bool, lp: float, pc: Array) -> void:
	var a: float = pc[0]
	var b: float = pc[1]
	var n := maxi(1, int(ceil((b - a) / 0.6)))
	var base := mb.v.size()
	for s in n + 1:
		var t := a + (b - a) * s / n
		var f := 1.0
		if pc[2]:
			f = minf(f, clampf((t - a) / 0.8, 0.2, 1.0))
		if pc[3]:
			f = minf(f, clampf((b - t) / 0.8, 0.2, 1.0))
		var g := hm(meta, lp, t) if vert else hm(meta, t, lp)
		for q in 8:
			var pr: Vector2 = PROF[q]
			var nz := sin(t * 2.9 + lp * 0.37 + q * 1.3) * 0.45 + sin(t * 1.13 + q * 2.3 + lp) * 0.35 + sin(t * 5.7 + q * 4.1) * 0.2
			var sx := pr.x * f * (1.0 + (0.3 if q in [1, 2, 5, 6] else 0.1) * nz)
			var y := g + (pr.y * (0.6 + 0.4 * f) if pr.y > 0.0 else pr.y)
			var pn: Vector2 = PNRM[q]
			var p := Vector3(lp + sx, y, t) if vert else Vector3(t, y, lp + sx)
			var nn := (Vector3(pn.x, pn.y, 0) if vert else Vector3(0, pn.y, pn.x)).normalized()
			mb.vert(p, nn, Color.WHITE, Vector2(t, y))
	# leafy clumps on both faces break up the silhouette (tops stay at one height)
	var t2 := a + 0.35
	while t2 < b - 0.3:
		var g2 := hm(meta, lp, t2) if vert else hm(meta, t2, lp)
		var k := int(t2 * 7.3 + lp * 3.1)
		for side in [-1.0, 1.0]:
			var y2: float = g2 + [0.45, 0.95, 1.2][absi(k) % 3]
			var r2: float = 0.38 + 0.12 * absf(sin(t2 * 5.1 + side))
			var off: float = side * (0.62 if y2 - g2 < 1.0 else 0.42)
			var c2 := Vector3(lp + off, y2, t2) if vert else Vector3(t2, y2, lp + off)
			_hb[absi(k + int(side)) % 3].append(Transform3D(Basis(Vector3.UP, t2 * 2.3).scaled(Vector3(r2, minf(r2, W.HEDGE_H - (y2 - g2) + 0.05), r2)), c2))
		t2 += 0.55
	for s in n:
		for q in 7:
			var i0 := base + s * 8 + q
			var face: Vector3 = mb.n[i0] + mb.n[i0 + 1]
			mb.quad(i0, i0 + 8, i0 + 9, i0 + 1, face)
	for e in [0, n]:
		if pc[2 if e == 0 else 3]:
			var c0: int = base + e * 8
			var face := Vector3(0, 0, -1 if e == 0 else 1) if vert else Vector3(-1 if e == 0 else 1, 0, 0)
			for q in range(1, 7):
				mb.tri(c0, c0 + q, c0 + q + 1, face)
	# collision in <= 8 m boxes
	var m := maxi(1, int(ceil((b - a) / 8.0)))
	for s in m:
		var t0 := a + (b - a) * s / m
		var t1 := a + (b - a) * (s + 1) / m
		var lo := 1.0e9
		var hi := -1.0e9
		for t in [t0, (t0 + t1) * 0.5, t1]:
			var g := hm(meta, lp, t) if vert else hm(meta, t, lp)
			lo = minf(lo, g)
			hi = maxf(hi, g)
		var top := hi + W.HEDGE_H
		var c := Vector3(lp, (lo - 0.3 + top) * 0.5, (t0 + t1) * 0.5) if vert else Vector3((t0 + t1) * 0.5, (lo - 0.3 + top) * 0.5, lp)
		var sz := Vector3(1.5, top - lo + 0.3, t1 - t0) if vert else Vector3(t1 - t0, top - lo + 0.3, 1.5)
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = sz
		cs.shape = bs
		cs.position = c
		cs.set_meta("surface", "grass")
		body.add_child(cs)


func _hedge_far(k: GeoKit, vert: bool, lp: float, pc: Array) -> void:
	var a: float = pc[0]
	var b: float = pc[1]
	var m := maxi(1, int(ceil((b - a) / 16.0)))
	for s in m:
		var t0 := a + (b - a) * s / m
		var t1 := a + (b - a) * (s + 1) / m
		var tm := (t0 + t1) * 0.5
		var g: float = w.h_at(lp, tm) if vert else w.h_at(tm, lp)
		var c := Vector3(lp, g + 0.6, tm) if vert else Vector3(tm, g + 0.6, lp)
		k.box(c, Vector3(1.7, W.HEDGE_H + 0.5, t1 - t0) if vert else Vector3(t1 - t0, W.HEDGE_H + 0.5, 1.7), "l10_hedge", GeoKit.ALL, false)


func _trees(meta: Dictionary, trees: Array, node: Node3D, body: StaticBody3D, hi: bool) -> void:
	if trees.is_empty():
		return
	var crowns: Array = [[], [], []]
	var trunks: Array = []
	for t in trees:
		var p: Vector3 = t[0]
		var sc: float = t[1]
		var r := RandomNumberGenerator.new()
		r.seed = t[2]
		p.y = hm(meta, p.x, p.z) if hi else w.h_at(p.x, p.z)
		var th := r.randf_range(2.8, 4.2) * sc
		var yaw := r.randf() * TAU
		trunks.append(Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(0.24 * sc, th + 0.6, 0.24 * sc)), p - Vector3(0, 0.3, 0)))
		var nb := 7 if hi else 3
		for bi in nb:
			var ang := yaw + bi * 2.4
			var off := Vector3.ZERO if bi == 0 else Vector3(cos(ang), 0, sin(ang)) * r.randf_range(1.8, 3.2) * sc
			var cy := th + (2.6 if bi == 0 else r.randf_range(0.4, 3.4)) * sc
			var cs := (3.0 if bi == 0 else r.randf_range(1.8, 2.6)) * sc
			crowns[r.randi() % 3].append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(cs, cs * 0.78, cs)), p + off + Vector3(0, cy, 0)))
		if hi and body:
			var cs3 := CollisionShape3D.new()
			var cy3 := CylinderShape3D.new()
			cy3.radius = 0.3 * sc
			cy3.height = th + 0.6
			cs3.shape = cy3
			cs3.position = p + Vector3(0, th * 0.5, 0)
			cs3.set_meta("surface", "wood")
			body.add_child(cs3)
	for v in 3:
		_mm(node, (crown_hi if hi else crown_lo)[v], "l10_crown", crowns[v], hi)
	if hi:
		_mm(node, trunk, "l10_bark", trunks, true)


func _mm(node: Node3D, mesh: Mesh, mat: String, xfs: Array, shadow: bool) -> void:
	if xfs.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = MatLib.get_mat(mat)
	if not shadow:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(mi)


func _structs(meta: Dictionary, node: Node3D, hi: bool) -> void:
	var ox: float = meta["ox"]
	var oz: float = meta["oz"]
	for i in range(w.xi(ox) - 1, w.xi(ox + CS) + 1):
		for j in range(w.zi(oz) - 1, w.zi(oz + CS) + 1):
			var p: Dictionary = w.plot(i, j)
			if hi:
				var cn: Rect2 = p["canola"]
				if cn.size.x > 0.0 and cn.get_center().x >= ox and cn.get_center().x < ox + CS and cn.get_center().y >= oz and cn.get_center().y < oz + CS:
					meta["canola"].append(cn)
			if p["kind"] == "":
				continue
			var yc: Vector2 = (p["yard"] as Rect2).get_center()
			if yc.x < ox or yc.x >= ox + CS or yc.y < oz or yc.y >= oz + CS:
				continue
			var kit := GeoKit.new(node, "Farm")
			kit.shadows = hi
			var r := RandomNumberGenerator.new()
			r.seed = hash([w.sd, i, j, 79])
			var red: bool = p["home"] or w.h01(i, j, 19) < 0.4
			var b := B.new(kit, p["frame"], r)
			if hi:
				var info: Dictionary = b.build(p["kind"], red)
				info["kind"] = p["kind"]
				info["home"] = p["home"]
				info["frame"] = p["frame"]
				meta["structs"].append(info)
			else:
				b.far(p["kind"], red)
			kit.commit()


# ----------------------------------------------------------------- far

func far(cx: int, cz: int, node: Node3D) -> Dictionary:
	var ox := cx * CS
	var oz := cz * CS
	var mb := P.MB.new()
	for gz in 9:
		for gx in 9:
			var x := ox + gx * 8.0
			var z := oz + gz * 8.0
			var h: float = w.h_at(x, z)
			var t: int = w.crop_at(x, z, h)
			var nrm: Vector3 = Vector3(w.h_at(x - 4.0, z) - w.h_at(x + 4.0, z), 8.0, w.h_at(x, z - 4.0) - w.h_at(x, z + 4.0)).normalized()
			mb.vert(Vector3(x, h + (W.CANOPY[t] - 0.04 if t > 0 else -0.05), z), nrm, Color(0.0, 1.0 if t > 0 else 0.0, code(t)))
	for r in 8:
		for c in 8:
			var a := r * 9 + c
			mb.i.append_array([a, a + 1, a + 10, a, a + 10, a + 9])
	# skirts hide hairline cracks where this 8 m ring meets the 2 m near terrain
	for e in 4:
		for q in 8:
			var ia: int = [q, 72 + q, q * 9, q * 9 + 8][e]
			var ib: int = [q + 1, 73 + q, (q + 1) * 9, (q + 1) * 9 + 8][e]
			var i0 := mb.vert(mb.v[ia], mb.n[ia], mb.c[ia])
			mb.vert(mb.v[ib], mb.n[ib], mb.c[ib])
			mb.vert(mb.v[ib] - Vector3(0, 3, 0), mb.n[ib], mb.c[ib])
			mb.vert(mb.v[ia] - Vector3(0, 3, 0), mb.n[ia], mb.c[ia])
			mb.i.append_array([i0, i0 + 1, i0 + 2, i0, i0 + 2, i0 + 3, i0, i0 + 2, i0 + 1, i0, i0 + 3, i0 + 2])
	mb.inst(node, "l10_terrain", false)
	var meta := {"ox": ox, "oz": oz}
	var k := GeoKit.new(node, "FarHedge")
	k.shadows = false
	var trees: Array = []
	_bounds(meta, k, null, trees, false)
	k.commit()
	_trees(meta, trees, node, null, false)
	_structs(meta, node, false)
	return meta


# --------------------------------------------------------------- tiles

## Stalk clumps for one 16 m tile of a near chunk (one MultiMesh per crop).
func tile(meta: Dictionary, tx: int, tz: int, parent: Node3D) -> Node3D:
	var ox: float = meta["ox"]
	var oz: float = meta["oz"]
	var cr: PackedByteArray = meta["cr"]
	var r := RandomNumberGenerator.new()
	r.seed = hash([w.sd, int(ox), int(oz), tx, tz])
	var b1 := PackedFloat32Array()
	var b2 := PackedFloat32Array()
	var b3 := PackedFloat32Array()
	var b4 := PackedFloat32Array()
	var n := int(TILE / STEP)
	var x0 := ox + tx * TILE
	var z0 := oz + tz * TILE
	var pts: Array = []
	for bb in n:
		for aa in n:
			pts.append(Vector2(x0 + (aa + r.randf()) * STEP, z0 + (bb + r.randf()) * STEP))
	# a denser fringe of stalks along every crop edge in the tile hides the canopy skirt
	var c0 := int((x0 - ox) * 0.5)
	var r0 := int((z0 - oz) * 0.5)
	for lz in 8:
		for lx in 8:
			var k := c0 + lx + 1
			var l := r0 + lz + 1
			var t: int = cr[l * 34 + k]
			if t == 0:
				continue
			var ex := ox + (k - 1) * 2.0
			var ez := oz + (l - 1) * 2.0
			for o in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				if cr[(l + o.y) * 34 + k + o.x] == t:
					continue
				for q in 6:
					var u := (q + r.randf()) / 6.0 * 2.0
					var d := r.randf_range(0.12, 0.4)
					var px := ex + (d if o.x < 0 else (2.0 - d if o.x > 0 else u))
					var pz := ez + (d if o.y < 0 else (2.0 - d if o.y > 0 else u))
					pts.append(Vector2(px, pz))
	for v: Vector2 in pts:
		var yaw := r.randf() * TAU
		var s := r.randf_range(0.85, 1.15)
		var t: int = cr[(int((v.y - oz) * 0.5) + 1) * 34 + int((v.x - ox) * 0.5) + 1]
		if t == 0:
			continue
		var c := cos(yaw) * s
		var sn := sin(yaw) * s
		var row := [c, 0.0, sn, v.x, 0.0, s, 0.0, hm(meta, v.x, v.y) - 0.03, -sn, 0.0, c, v.y]
		if t == 1:
			b1.append_array(row)
		elif t == 2:
			b2.append_array(row)
		else:
			b3.append_array(row)
	# grass tufts on verges, headlands, lake edges and the tracks' centre strip
	var cell_ok := {}
	for bb in 40:
		for aa in 40:
			var x := x0 + (aa + r.randf()) * 0.4
			var z := z0 + (bb + r.randf()) * 0.4
			var ck := Vector2i(int((x - ox) * 0.5), int((z - oz) * 0.5))
			if cr[(ck.y + 1) * 34 + ck.x + 1] != 0:
				continue
			if not cell_ok.has(ck):
				var cx := ox + ck.x * 2.0 + 1.0
				var cz := oz + ck.y * 2.0 + 1.0
				var yd: Rect2 = w.plot_at(cx, cz)["yard"]
				cell_ok[ck] = 0 if (yd.size.x > 0.0 and yd.grow(1.5).has_point(Vector2(cx, cz))) else (2 if float(w.track_near(cx, cz)[0]) < 3.6 else 1)
			if cell_ok[ck] == 0:
				continue
			if cell_ok[ck] == 2:
				var td: float = w.track_near(x, z)[0]
				if td > 0.25 and td < 1.95:
					continue
			var y := hm(meta, x, z)
			if y < W.WATER_Y + 0.05 or w.n2.get_noise_2d(x * 9.0, z * 9.0) < -0.25 + (y - W.WATER_Y) * 0.0:
				continue
			var s := r.randf_range(0.55, 1.25)
			var yaw := r.randf() * TAU
			b4.append_array([cos(yaw) * s, 0.0, sin(yaw) * s, x, 0.0, s, 0.0, y - 0.02, -sin(yaw) * s, 0.0, cos(yaw) * s, z])
	var nd := Node3D.new()
	nd.name = "Tile_%d_%d" % [tx, tz]
	parent.add_child(nd)
	var bufs := [b1, b2, b3, b4]
	for i in 4:
		var buf: PackedFloat32Array = bufs[i]
		if buf.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = clump[i + 1]
		mm.instance_count = buf.size() / 12
		mm.buffer = buf
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = MatLib.get_mat("l10_stalk")
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = 34.0 if i < 3 else 24.0
		mi.visibility_range_end_margin = 6.0
		nd.add_child(mi)
	return nd
