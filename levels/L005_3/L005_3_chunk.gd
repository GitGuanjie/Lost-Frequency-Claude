extends RefCounted
## Level 5.3 chunk builder: all seven floors of one 24 m chunk. Returns meta:
## {kind, floors: {f: {anchors: [...], props: [...]}}, doors: [...]}.

const S := preload("res://levels/L005_3/L005_3_stacks.gd")
const CS := 24.0
const COR := 4.0

var lvl
var forced_dead := Vector2i(1, 0)


func _init(level) -> void:
	lvl = level


func build(cx: int, cz: int, node: Node3D) -> Dictionary:
	var sd: int = lvl.level_seed
	var o := Vector3(cx * CS, 0, cz * CS)
	var kind := S.kind_of(cx, cz, sd)
	var meta := {"kind": kind, "floors": {}, "doors": [], "origin": o}
	var k := GeoKit.new(node, "Stacks")
	for f in range(1, S.NF + 1):
		var y0 := S.floor_y(f)
		var fm := {"anchors": [], "props": []}
		meta["floors"][f] = fm
		_slabs(k, o, y0, kind, f == S.NF)
		_pillars(k, o, y0)
		_chandelier(k, o + Vector3(2.0, y0, 2.0), fm, true)
		_chandelier(k, o + Vector3(2.0, y0, 14.0), fm, false)
		_chandelier(k, o + Vector3(14.0, y0, 2.0), fm, false)
		if kind == "void":
			_void_edges(k, o, y0, f)
			_void_lamp(k, o, y0, fm)
			if f < S.NF:
				_void_stairs(k, o, y0)
		else:
			_stacks(k, node, o, y0, cx, cz, f, sd, fm, meta)
	k.commit()
	return meta


# ------------------------------------------------------------ slabs

func _slab(k: GeoKit, mn: Vector3, mx: Vector3, top_mat: String, ceiling: bool) -> void:
	var c := (mn + mx) * 0.5
	var sz := mx - mn
	k.box(c, sz, top_mat, GeoKit.PY, true)
	if ceiling:
		k.box(c, sz, "l53_ceiling", GeoKit.NY, false)


func _slabs(k: GeoKit, o: Vector3, y0: float, kind: String, top: bool) -> void:
	var lo := y0 - S.SLAB
	_slab(k, o + Vector3(0, lo, 0), o + Vector3(COR, y0, CS), "l53_marble", true)
	_slab(k, o + Vector3(COR, lo, 0), o + Vector3(CS, y0, COR), "l53_marble", true)
	# red-and-gold runners down both corridors
	k.box(o + Vector3(2.0, y0 + 0.006, 12.0), Vector3(1.7, 0.01, CS), "l53_carpet", GeoKit.PY, false)
	k.box(o + Vector3(14.0, y0 + 0.006, 2.0), Vector3(CS - COR, 0.01, 1.7), "l53_carpet", GeoKit.PY, false)
	if kind != "void":
		_slab(k, o + Vector3(COR, lo, COR), o + Vector3(CS, y0, CS), "l53_parquet", true)
	# coffer beams under the floor above
	var cy := y0 + S.CEIL - 0.14
	for x in [0.2, 3.8]:
		k.box(o + Vector3(x, cy, 12.0), Vector3(0.3, 0.28, CS), "l53_walnut", GeoKit.ALL & ~GeoKit.PY, false)
	for z in [0.2, 3.8]:
		k.box(o + Vector3(14.0, cy, z), Vector3(CS - COR, 0.28, 0.3), "l53_walnut", GeoKit.ALL & ~GeoKit.PY, false)
	for i in 6:
		k.box(o + Vector3(2.0, cy, 2.0 + i * 4.0), Vector3(COR, 0.2, 0.18), "l53_gold", GeoKit.NY | GeoKit.PZ | GeoKit.NZ, false)
		k.box(o + Vector3(6.0 + i * 4.0 - 2.0, cy, 2.0), Vector3(0.18, 0.2, COR), "l53_gold", GeoKit.NY | GeoKit.PX | GeoKit.NX, false)
	if top:
		var ty := y0 + S.FH
		k.box(o + Vector3(CS * 0.5, ty - S.SLAB * 0.5, CS * 0.5), Vector3(CS, S.SLAB, CS), "l53_ceiling", GeoKit.NY, false)


func _pillars(k: GeoKit, o: Vector3, y0: float) -> void:
	for p in [Vector3(COR, 0, COR), Vector3(CS, 0, COR), Vector3(COR, 0, CS), Vector3(CS, 0, CS)]:
		var c: Vector3 = o + p
		k.box(c + Vector3(0, y0 + S.CEIL * 0.5, 0), Vector3(1.0, S.CEIL, 1.0), "l53_tuff", GeoKit.SIDES, true, "stone")
		k.box(c + Vector3(0, y0 + 0.25, 0), Vector3(1.2, 0.5, 1.2), "l53_granite", GeoKit.SIDES | GeoKit.PY, false)
		k.box(c + Vector3(0, y0 + S.CEIL - 0.3, 0), Vector3(1.2, 0.22, 1.2), "l53_gold", GeoKit.SIDES | GeoKit.NY, false)


## A gilt ring of candles on a chain, under the ceiling.
func _chandelier(k: GeoKit, base: Vector3, fm: Dictionary, big: bool) -> void:
	var y := base.y + S.CEIL - (1.5 if big else 1.2)
	var r := 0.75 if big else 0.5
	var c := Vector3(base.x, y, base.z)
	k.box(c + Vector3(0, (base.y + S.CEIL - y) * 0.5, 0), Vector3(0.04, base.y + S.CEIL - y, 0.04), "l53_gold", GeoKit.SIDES, false)
	var n := 8 if big else 6
	for i in n:
		var a := TAU * i / n
		var p := c + Vector3(cos(a) * r, 0, sin(a) * r)
		k.box_xf(Transform3D(Basis(Vector3.UP, -a), (c + p) * 0.5), Vector3(r, 0.035, 0.035), "l53_gold", GeoKit.ALL, false)
		k.box(p + Vector3(0, 0.1, 0), Vector3(0.05, 0.2, 0.05), "l53_candle", GeoKit.SIDES, false)
		k.box(p + Vector3(0, 0.24, 0), Vector3(0.03, 0.07, 0.03), "l53_flame", GeoKit.ALL, false)
	fm["anchors"].append({"pos": c + Vector3(0, 0.2, 0), "color": Color(1.0, 0.72, 0.42), "energy": 2.4 if big else 1.6, "range": 9.0 if big else 7.0})
	if big:
		fm["props"].append({"id": "ph/Chandelier_01", "pos": c + Vector3(0, -0.35, 0), "yaw": 0.0, "h": 1.1, "collide": false})


# ------------------------------------------------------------ the void

func _void_edges(k: GeoKit, o: Vector3, y0: float, f: int) -> void:
	# iron bars along every edge, open where the stairs meet the corridor
	var edges := [[Vector3(COR, 0, COR), Vector3(CS, 0, COR)], [Vector3(COR, 0, CS), Vector3(CS, 0, CS)],
		[Vector3(COR, 0, COR), Vector3(COR, 0, CS)], [Vector3(CS, 0, COR), Vector3(CS, 0, CS)]]
	for ei in 4:
		var a: Vector3 = edges[ei][0]
		var b: Vector3 = edges[ei][1]
		var gaps: Array = []
		if ei == 0 and f < S.NF:
			gaps.append([12.0, 13.6])          # down to the first flight
		if ei == 2 and f > 1:
			gaps.append([10.1, 11.5])          # up from the second flight
		_bars(k, o, y0, a, b, gaps)
		# granite fascia on the slab edge seen from the void
		var mid := (a + b) * 0.5
		var along := (b - a)
		var inward := Vector3(along.z, 0, -along.x).normalized() * (1.0 if ei % 2 == 0 else -1.0)
		var sz := Vector3(absf(along.x) + 0.02, 0.6, absf(along.z) + 0.02)
		if sz.x < 0.1:
			sz.x = 0.06
		if sz.z < 0.1:
			sz.z = 0.06
		k.box(o + mid + Vector3(0, y0 - 0.3, 0) - inward * 0.0, sz, "l53_granite", GeoKit.ALL, false)


## A tiered candle chandelier on the one chain that runs down the void.
func _void_lamp(k: GeoKit, o: Vector3, y0: float, fm: Dictionary) -> void:
	var c := o + Vector3(14.0, y0 + 2.4, 14.0)
	_beam(k, c + Vector3.UP * 0.4, c + Vector3.UP * (S.FH - 0.4), 0.05, 0.05, "l53_iron")
	k.cylinder(c + Vector3.UP * 0.25, 0.12, 0.6, "l53_gold", 8, false)
	for tier in 2:
		var r := 1.1 - tier * 0.45
		var cy := c + Vector3.UP * (tier * 0.55)
		var n := 12 - tier * 4
		for i in n:
			var a := TAU * i / n
			var p := cy + Vector3(cos(a) * r, 0, sin(a) * r)
			k.box_xf(Transform3D(Basis(Vector3.UP, -a), (cy + p) * 0.5), Vector3(r, 0.04, 0.04), "l53_gold", GeoKit.ALL, false)
			k.box(p + Vector3(0, 0.1, 0), Vector3(0.05, 0.2, 0.05), "l53_candle", GeoKit.SIDES, false)
			k.box(p + Vector3(0, 0.25, 0), Vector3(0.035, 0.08, 0.035), "l53_flame", GeoKit.ALL, false)
	fm["anchors"].append({"pos": c + Vector3(0, 0.3, 0), "color": Color(1.0, 0.7, 0.4), "energy": 3.2, "range": 14.0, "void": true})


func _bars(k: GeoKit, o: Vector3, y0: float, a: Vector3, b: Vector3, gaps: Array) -> void:
	var horiz := absf(b.x - a.x) > 0.1
	var s0 := (a.x if horiz else a.z) + 0.5
	var s1 := (b.x if horiz else b.z) - 0.5
	var cuts := [s0]
	for g in gaps:
		cuts.append(g[0])
		cuts.append(g[1])
	cuts.append(s1)
	for i in range(0, cuts.size(), 2):
		var u0: float = cuts[i]
		var u1: float = cuts[i + 1]
		if u1 - u0 < 0.2:
			continue
		var c: Vector3 = (Vector3((u0 + u1) * 0.5, 0, a.z) if horiz else Vector3(a.x, 0, (u0 + u1) * 0.5)) + o
		var sz := Vector3(u1 - u0, 1.1, 0.04) if horiz else Vector3(0.04, 1.1, u1 - u0)
		var faces := (GeoKit.PZ | GeoKit.NZ) if horiz else (GeoKit.PX | GeoKit.NX)
		k.box(c + Vector3(0, y0 + 0.55, 0), sz, "l53_bars", faces, true, "metal")
		k.box(c + Vector3(0, y0 + 1.12, 0), Vector3(sz.x + 0.04, 0.06, sz.z + 0.04), "l53_iron", GeoKit.ALL, false)
		k.box(c + Vector3(0, y0 + 0.04, 0), Vector3(sz.x + 0.04, 0.08, sz.z + 0.04), "l53_iron", GeoKit.ALL, false)


## Wooden stairs hung in the void: floor f up to floor f+1 by two flights.
func _void_stairs(k: GeoKit, o: Vector3, y0: float) -> void:
	k.box(o + Vector3(12.8, y0 - 0.15, 4.8), Vector3(1.6, 0.3, 1.6), "l53_parquet", GeoKit.ALL, true, "wood")
	k.stairs(o + Vector3(12.0, y0, 4.8), Vector3(-1, 0, 0), 1.4, 2.5, 14, "l53_walnut", 0.28, false)
	k.box(o + Vector3(6.1, y0 + 2.35, 5.15), Vector3(4.0, 0.3, 2.1), "l53_parquet", GeoKit.ALL, true, "wood")
	k.stairs(o + Vector3(5.0, y0 + 2.5, 6.2), Vector3(0, 0, 1), 1.4, 2.5, 14, "l53_walnut", 0.28, false)
	k.box(o + Vector3(4.85, y0 + 4.85, 10.8), Vector3(1.7, 0.3, 1.4), "l53_parquet", GeoKit.ALL, true, "wood")
	# stringers
	for z in [4.08, 5.52]:
		_beam(k, o + Vector3(12.0, y0 - 0.2, z), o + Vector3(8.08, y0 + 2.3, z), 0.08, 0.28, "l53_walnut")
	for x in [4.28, 5.72]:
		_beam(k, o + Vector3(x, y0 + 2.3, 6.2), o + Vector3(x, y0 + 4.8, 10.12), 0.08, 0.28, "l53_walnut")
	# iron bars on the open sides (sloped along the flights)
	_rail(k, o + Vector3(12.0, y0, 5.55), o + Vector3(8.08, y0 + 2.5, 5.55))
	_rail(k, o + Vector3(5.75, y0 + 2.5, 6.2), o + Vector3(5.75, y0 + 5.0, 10.12))
	_rail(k, o + Vector3(8.1, y0 + 2.5, 6.2), o + Vector3(5.75, y0 + 2.5, 6.2))
	_rail(k, o + Vector3(8.1, y0 + 2.5, 5.55), o + Vector3(8.1, y0 + 2.5, 6.2))
	_rail(k, o + Vector3(5.7, y0 + 5.0, 11.5), o + Vector3(5.7, y0 + 5.0, 10.12))
	# hangers to the slab above
	for p in [Vector3(8.0, 0, 4.2), Vector3(8.0, 0, 6.1), Vector3(5.7, 0, 6.1)]:
		_beam(k, o + p + Vector3(0, y0 + 2.5, 0), o + p + Vector3(0, y0 + S.CEIL, 0), 0.05, 0.05, "l53_iron")


func _rail(k: GeoKit, a: Vector3, b: Vector3) -> void:
	var d := b - a
	var hd := Vector3(d.x, 0, d.z)
	var ln := hd.length()
	if ln < 0.05:
		return
	var z := hd.normalized()
	var x := Vector3.UP.cross(z).normalized()
	var slope := Basis(x, Vector3.UP, z).rotated(x, -atan2(d.y, ln))
	k.box_xf(Transform3D(slope, (a + b) * 0.5 + Vector3.UP * 0.55), Vector3(0.04, 1.1, sqrt(ln * ln + d.y * d.y)), "l53_bars", GeoKit.PX | GeoKit.NX, true, "metal")
	_beam(k, a + Vector3.UP * 1.12, b + Vector3.UP * 1.12, 0.06, 0.06, "l53_iron")


func _beam(k: GeoKit, a: Vector3, b: Vector3, w: float, h: float, mat: String) -> void:
	var d := b - a
	if d.length() < 0.02:
		return
	var z := d.normalized()
	var up := Vector3.UP if absf(z.y) < 0.95 else Vector3.RIGHT
	var x := up.cross(z).normalized()
	var y := z.cross(x).normalized()
	k.box_xf(Transform3D(Basis(x, y, z), (a + b) * 0.5), Vector3(w, h, d.length()), mat, GeoKit.ALL, false)


# ------------------------------------------------------------ the stacks

## A wall of shelves from a to b (horizontal), books on both faces, a marble
## band above with paintings or the inscription on the corridor side.
## out: unit vector towards the corridor.
func _shelf_wall(k: GeoKit, node: Node3D, a: Vector3, b: Vector3, out: Vector3, y0: float, openings: Array, band: bool, cx: int, cz: int, f: int, ei: int, fm: Dictionary) -> void:
	var horiz := absf(b.x - a.x) > 0.1
	var u0 := a.x if horiz else a.z
	var u1 := b.x if horiz else b.z
	var cuts := [u0]
	var off := (a.x if horiz else a.z) - (COR + 0.5)
	openings = openings.duplicate()
	openings.sort_custom(func(x, y): return x[0] < y[0])
	for g in openings:
		cuts.append(off + float(g[0]))
		cuts.append(off + float(g[1]))
	cuts.append(u1)
	var depth := 0.62
	var line := a + out * -0.31    # wall centre line (inside the block)
	for i in range(0, cuts.size(), 2):
		var s0: float = cuts[i]
		var s1: float = cuts[i + 1]
		if s1 - s0 < 0.3:
			continue
		var c := Vector3((s0 + s1) * 0.5, 0, line.z) if horiz else Vector3(line.x, 0, (s0 + s1) * 0.5)
		var sz := Vector3(s1 - s0, S.SHELF_H, depth) if horiz else Vector3(depth, S.SHELF_H, s1 - s0)
		var bf := (GeoKit.PZ | GeoKit.NZ) if horiz else (GeoKit.PX | GeoKit.NX)
		var ends := (GeoKit.PX | GeoKit.NX) if horiz else (GeoKit.PZ | GeoKit.NZ)
		k.box(c + Vector3(0, y0 + S.SHELF_H * 0.5, 0), sz, "l53_books", bf, true, "wood")
		k.box(c + Vector3(0, y0 + S.SHELF_H * 0.5, 0), sz + Vector3(0.04, 0.0, 0.04) * (Vector3(1, 0, 0) if horiz else Vector3(0, 0, 1)), "l53_walnut_end", ends, false)
		k.box(c + Vector3(0, y0 + S.SHELF_H + 0.06, 0), sz * Vector3(1, 0, 1) + Vector3(0.12, 0.12, 0.12), "l53_walnut", GeoKit.ALL, false)
		k.box(c + out * (depth * 0.5 + 0.03) + Vector3(0, y0 + 0.07, 0), (Vector3(s1 - s0, 0.14, 0.06) if horiz else Vector3(0.06, 0.14, s1 - s0)), "l53_granite", GeoKit.ALL, false)
		# a rolling library ladder on some long runs
		if s1 - s0 > 5.0 and S.rnd(cx, cz, f, lvl.level_seed, ei * 7 + i) < 0.35:
			var lp := (Vector3(s0 + 1.6, 0, line.z) if horiz else Vector3(line.x, 0, s0 + 1.6)) + out * (depth * 0.5 + 0.55)
			var top := lp - out * 0.5 + Vector3(0, y0 + S.SHELF_H, 0)
			var side := (Vector3(1, 0, 0) if horiz else Vector3(0, 0, 1)) * 0.22
			for s in [-1.0, 1.0]:
				_beam(k, lp + side * s + Vector3(0, y0, 0), top + side * s, 0.05, 0.06, "l53_walnut")
			for j in range(1, 11):
				var p := (lp + Vector3(0, y0, 0)).lerp(top, j / 11.0)
				_beam(k, p - side, p + side, 0.035, 0.035, "l53_walnut")
	if not band:
		return
	# marble band above the shelves, gilt mouldings, paintings / inscription
	var bc := (a + b) * 0.5 + out * -0.2
	var bsz := Vector3(u1 - u0, S.CEIL - S.SHELF_H, 0.4) if horiz else Vector3(0.4, S.CEIL - S.SHELF_H, u1 - u0)
	k.box(bc + Vector3(0, y0 + S.SHELF_H + bsz.y * 0.5, 0), bsz, "l53_marble_wall", GeoKit.ALL & ~GeoKit.PY, false)
	k.box(bc + out * 0.21 + Vector3(0, y0 + S.SHELF_H + 0.16, 0), (Vector3(u1 - u0, 0.08, 0.05) if horiz else Vector3(0.05, 0.08, u1 - u0)), "l53_gold", GeoKit.ALL, false)
	var face := bc + out * 0.205
	var inscription := S.rnd(cx, cz, f, lvl.level_seed, ei + 31) < 0.22 or (cx == 0 and cz == 0 and f == S.ENTRY_F and ei == 0)
	if inscription:
		var lb := Label3D.new()
		lb.text = "PROMETHEI   BIBLIOTHECA"
		lb.font_size = 96
		lb.pixel_size = 0.0042
		lb.modulate = Color(0.62, 0.44, 0.16)
		lb.outline_size = 0
		lb.shaded = false
		lb.double_sided = false
		lb.position = face + out * 0.01 + Vector3(0, y0 + S.CEIL - 0.45, 0)
		lb.basis = Basis.looking_at(-out, Vector3.UP)
		node.add_child(lb)
		return
	var n := int((u1 - u0) / 6.5)
	for j in n:
		var t := (j + 0.5) / n
		var pc := (a + (b - a) * t) + out * 0.005 + Vector3(0, y0 + 4.0, 0)
		var hu := (Vector3(0.65, 0, 0) if horiz else Vector3(0, 0, 0.65))
		var hv := Vector3(0, 0.4, 0)
		k.quad(pc, out, hu * (1.0 if out.z > 0.0 or out.x < 0.0 else -1.0), hv, "l53_painting", Vector2(S.rnd(cx, cz, f, lvl.level_seed, ei * 13 + j), 0.0), true)
		for e in [[-hu - hv, hu - hv], [-hu + hv, hu + hv], [-hu - hv, -hu + hv], [hu - hv, hu + hv]]:
			_beam(k, pc + e[0] * 1.06 + out * 0.03, pc + e[1] * 1.06 + out * 0.03, 0.07, 0.07, "l53_gold")
		fm["anchors"].append({"pos": pc + out * 0.9 + Vector3(0, 0.6, 0), "color": Color(1.0, 0.78, 0.5), "energy": 0.5, "range": 3.0})


## Double-sided range of shelves standing in the block.
func _range(k: GeoKit, c: Vector3, along_z: bool, ln: float, y0: float) -> void:
	var sz := Vector3(0.7, S.SHELF_H, ln) if along_z else Vector3(ln, S.SHELF_H, 0.7)
	var bf := (GeoKit.PX | GeoKit.NX) if along_z else (GeoKit.PZ | GeoKit.NZ)
	var ends := (GeoKit.PZ | GeoKit.NZ) if along_z else (GeoKit.PX | GeoKit.NX)
	k.box(c + Vector3(0, y0 + S.SHELF_H * 0.5, 0), sz, "l53_books", bf, true, "wood")
	k.box(c + Vector3(0, y0 + S.SHELF_H * 0.5, 0), sz + (Vector3(0, 0, 0.04) if along_z else Vector3(0.04, 0, 0)), "l53_walnut_end", ends, false)
	k.box(c + Vector3(0, y0 + S.SHELF_H + 0.05, 0), sz * Vector3(1, 0, 1) + Vector3(0.1, 0.1, 0.1), "l53_walnut", GeoKit.ALL, false)


func _stacks(k: GeoKit, node: Node3D, o: Vector3, y0: float, cx: int, cz: int, f: int, sd: int, fm: Dictionary, meta: Dictionary) -> void:
	var entry := cx == 0 and cz == 0 and f == S.ENTRY_F
	var dead := S.dead_end(cx, cz, f, sd, forced_dead)
	var ori := 0 if (dead or entry or S.rnd(cx, cz, f, sd, 1) < 0.5) else 1
	var bay := not dead and not entry and S.rnd(cx, cz, f, sd, 2) < 0.45
	var xs := [6.4, 9.0, 11.6, 14.2, 16.8, 19.4, 22.0]
	var aisles := [7.7, 10.3, 12.9, 15.5, 18.1, 20.7]
	var ai := [1, 4] if S.rnd(cx, cz, f, sd, 3) < 0.5 else [0, 3]
	var open_ns: Array = []
	for i in ai:
		open_ns.append([aisles[i] - 0.8, aisles[i] + 0.8])
	if dead:
		open_ns = [[11.8, 14.4]]
	if entry:
		open_ns = [[13.0, 15.0], [aisles[0] - 0.8, aisles[0] + 0.8]]
	var open_w := [[4.8, 6.2]]
	var open_e := [[21.8, 23.2]]
	# perimeter: S, N, W, E (ori 1 swaps which edges get the aisle openings)
	var ew_open := open_ns if ori == 1 else []
	_shelf_wall(k, node, o + Vector3(COR + 0.5, 0, COR), o + Vector3(CS - 0.5, 0, COR), Vector3(0, 0, -1), y0, open_ns if ori == 0 else open_w, true, cx, cz, f, 0, fm)
	_shelf_wall(k, node, o + Vector3(COR + 0.5, 0, CS), o + Vector3(CS - 0.5, 0, CS), Vector3(0, 0, 1), y0, (open_ns if not dead and not entry else []) if ori == 0 else open_e, true, cx, cz, f, 1, fm)
	_shelf_wall(k, node, o + Vector3(COR, 0, COR + 0.5), o + Vector3(COR, 0, CS - 0.5), Vector3(-1, 0, 0), y0, open_w if ori == 0 else ew_open, true, cx, cz, f, 2, fm)
	_shelf_wall(k, node, o + Vector3(CS, 0, COR + 0.5), o + Vector3(CS, 0, CS - 0.5), Vector3(1, 0, 0), y0, open_e if ori == 0 else ew_open, true, cx, cz, f, 3, fm)
	for i in xs.size():
		var p: float = xs[i]
		if bay and i == 5:
			continue
		if dead and (i == 2 or i == 3):
			continue
		if entry and i == 3:
			continue
		var c := o + (Vector3(p, 0, 14.0) if ori == 0 else Vector3(14.0, 0, p))
		_range(k, c, ori == 0, 15.2, y0)
	if dead:
		_dead_end(k, node, o, y0, meta, fm)
	if entry:
		_alcove(k, o, y0)
	if bay:
		var tc := o + (Vector3(19.4, y0, 13.0) if ori == 0 else Vector3(13.0, y0, 19.4))
		var yaw := 90.0 if ori == 0 else 0.0
		fm["props"].append({"id": "ph/dining_table", "pos": tc, "yaw": yaw, "h": 0.0, "collide": true})
		for s in [-1.0, 1.0]:
			var off := (Vector3(s * 0.85, 0, 0.5) if ori == 0 else Vector3(0.5, 0, s * 0.85))
			fm["props"].append({"id": "ph/dining_chair_02", "pos": tc + off, "yaw": yaw + (90.0 if s > 0 else -90.0), "h": 0.0, "collide": false})
		fm["props"].append({"id": "ph/binder_notebook", "pos": tc + Vector3(0.2, 0.88, -0.3), "yaw": 25.0, "h": 0.0, "collide": false})
		# a green-shaded reading lamp, lit
		var lp := tc + Vector3(0, 0.88, 0)
		k.box(lp + Vector3(0, 0.02, 0), Vector3(0.2, 0.04, 0.2), "l53_gold", GeoKit.ALL, false)
		k.box(lp + Vector3(0, 0.2, 0), Vector3(0.03, 0.36, 0.03), "l53_gold", GeoKit.ALL, false)
		k.box(lp + Vector3(0, 0.4, 0), Vector3(0.36, 0.1, 0.16), "l53_shade", GeoKit.ALL, false)
		fm["anchors"].append({"pos": lp + Vector3(0, 0.3, 0), "color": Color(1.0, 0.82, 0.55), "energy": 1.2, "range": 4.5})
	elif S.rnd(cx, cz, f, sd, 5) < 0.35:
		fm["props"].append({"id": "ph/ArmChair_01", "pos": o + Vector3(1.0, y0, 9.0), "yaw": 90.0, "h": 0.0, "collide": true})


## The page's dead end: a short corridor between shelves ending in a marble
## wall with a small wooden door (it leads back to the library's entrance).
func _dead_end(k: GeoKit, node: Node3D, o: Vector3, y0: float, meta: Dictionary, fm: Dictionary) -> void:
	for x in [11.5, 14.7]:
		_range(k, o + Vector3(x, 0, 10.8), true, 12.4, y0)
	var wc := o + Vector3(13.1, y0, 17.2)
	k.box(wc + Vector3(-1.35, S.CEIL * 0.5, 0), Vector3(1.0, S.CEIL, 0.4), "l53_marble_wall", GeoKit.ALL, true, "stone")
	k.box(wc + Vector3(1.35, S.CEIL * 0.5, 0), Vector3(1.0, S.CEIL, 0.4), "l53_marble_wall", GeoKit.ALL, true, "stone")
	k.box(wc + Vector3(0, (1.8 + S.CEIL) * 0.5, 0), Vector3(1.7, S.CEIL - 1.8, 0.4), "l53_marble_wall", GeoKit.ALL, true, "stone")
	k.box(wc + Vector3(0, 0.9, 0.04), Vector3(1.7, 1.8, 0.3), "l53_door_old", GeoKit.NZ, true, "wood")
	k.box(wc + Vector3(0, 0.9, -0.12), Vector3(0.9, 1.75, 0.05), "l53_door_old", GeoKit.ALL, false)
	k.box(wc + Vector3(0.3, 0.9, -0.16), Vector3(0.05, 0.05, 0.05), "l53_gold", GeoKit.ALL, false)
	k.box(wc + Vector3(0, 0.12, -0.25), Vector3(1.7, 0.24, 0.12), "l53_granite", GeoKit.ALL, false)
	meta["doors"].append({"pos": wc + Vector3(0, 0.95, -0.55), "face": Vector3(0, 0, -1)})
	fm["anchors"].append({"pos": wc + Vector3(0, 2.6, -1.2), "color": Color(1.0, 0.7, 0.4), "energy": 0.9, "range": 5.0})
	k.box(wc + Vector3(-0.75, 2.2, -0.24), Vector3(0.06, 0.2, 0.06), "l53_candle", GeoKit.ALL, false)
	k.box(wc + Vector3(-0.75, 2.34, -0.24), Vector3(0.03, 0.07, 0.03), "l53_flame", GeoKit.ALL, false)


## The arrival alcove: the old wooden door from the hotel, in a marble niche
## lined with the hotel's own peeled wallpaper.
func _alcove(k: GeoKit, o: Vector3, y0: float) -> void:
	for x in [12.85, 15.15]:
		k.box(o + Vector3(x, y0 + S.SHELF_H * 0.5, 5.2), Vector3(0.3, S.SHELF_H, 2.4), "l53_marble_wall", GeoKit.ALL, true, "stone")
		k.box(o + Vector3(x + (0.16 if x < 14.0 else -0.16), y0 + 1.6, 5.4), Vector3(0.02, 3.0, 1.6), "l53_wallpaper_old", GeoKit.PX if x < 14.0 else GeoKit.NX, false)
	k.box(o + Vector3(14.0, y0 + S.SHELF_H * 0.5, 6.35), Vector3(2.6, S.SHELF_H, 0.3), "l53_marble_wall", GeoKit.ALL, true, "stone")
	k.box(o + Vector3(14.0, y0 + 1.05, 6.18), Vector3(1.05, 2.1, 0.06), "l53_door_old", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		k.box(o + Vector3(14.0 + s * 0.6, y0 + 1.1, 6.16), Vector3(0.12, 2.2, 0.1), "l53_walnut", GeoKit.ALL, false)
	k.box(o + Vector3(14.0, y0 + 2.25, 6.16), Vector3(1.32, 0.12, 0.1), "l53_walnut", GeoKit.ALL, false)
	k.box(o + Vector3(14.38, y0 + 1.0, 6.12), Vector3(0.06, 0.06, 0.06), "l53_gold", GeoKit.ALL, false)
	k.box(o + Vector3(14.0, y0 + S.SHELF_H - 0.2, 5.2), Vector3(2.6, 0.4, 2.4), "l53_marble_wall", GeoKit.NY, false)
