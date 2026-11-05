extends RefCounted
## Level 9 helper for levels/L009/L009.gd: houses, interiors, yards, dead trees,
## street furniture and the airport / outskirts set pieces. Geometry goes into a
## GeoKit through a local frame: x along the frontage, z from the front wall (0)
## to the back (+d), y up from the lot surface. The front faces -z (the street).

const T := 0.16
const SH := 2.75
const PX := 1
const NX := 2
const PY := 4
const NY := 8
const PZ := 16
const NZ := 32
const ALL := 63

var k: GeoKit
var xf: Transform3D
var r: RandomNumberGenerator
var hw := 10.0
var hd := 9.0


func _init(kit: GeoKit, frame: Transform3D, rng: RandomNumberGenerator) -> void:
	k = kit
	xf = frame
	r = rng


# ------------------------------------------------------------ primitives

func bx(a: Vector3, b: Vector3, mat: String, faces: int = ALL, col: bool = false, surf: String = "") -> void:
	var mn := Vector3(minf(a.x, b.x), minf(a.y, b.y), minf(a.z, b.z))
	var mx := Vector3(maxf(a.x, b.x), maxf(a.y, b.y), maxf(a.z, b.z))
	k.box_xf(Transform3D(xf.basis, xf * ((mn + mx) * 0.5)), mx - mn, mat, faces, col, surf)


## Box in a yawed sub-frame (furniture, door leaves). c = local floor centre.
func ybx(c: Vector3, yaw: float, a: Vector3, b: Vector3, mat: String, col: bool = false) -> void:
	var bas := Basis(Vector3.UP, yaw)
	k.box_xf(Transform3D(xf.basis * bas, xf * (c + bas * ((a + b) * 0.5))), (b - a).abs(), mat, ALL, col)


## Square-section beam between two local points (branches, posts, wires).
func stick(a: Vector3, b: Vector3, th: float, mat: String, col: bool = false) -> void:
	var d := b - a
	var y := d.normalized()
	var ref := Vector3.UP if absf(y.y) < 0.95 else Vector3.RIGHT
	var x := ref.cross(y).normalized()
	k.box_xf(Transform3D(xf.basis * Basis(x, y, x.cross(y)), xf * ((a + b) * 0.5)), Vector3(th, d.length(), th), mat, ALL, col)


## Convex polygon (local points), oriented so its normal follows `hint`.
func poly(pts: Array, mat: String, hint: Vector3, back_mat: String = "") -> void:
	var w: Array = []
	for q in pts:
		w.append(xf * (q as Vector3))
	var n: Vector3 = ((w[1] as Vector3) - w[0]).cross((w[2] as Vector3) - w[0]).normalized()
	if n.dot(xf.basis * hint) < 0.0:
		w.reverse()
		n = -n
	_fan(w, n, mat)
	if back_mat != "":
		var b := w.duplicate()
		b.reverse()
		_fan(b, -n, back_mat)


func _fan(w: Array, n: Vector3, mat: String) -> void:
	var s: Dictionary = k._s(mat)
	var base: int = s["v"].size()
	var tu := Vector3(-n.z, 0.0, n.x).normalized() if absf(n.y) < 0.92 else Vector3.RIGHT
	var tv := n.cross(tu).normalized()
	for q in w:
		var p: Vector3 = q
		s["v"].append(p)
		s["n"].append(n)
		if absf(n.y) > 0.92:
			s["uv"].append(Vector2(p.x, p.z))
		elif absf(n.y) < 0.08:
			s["uv"].append(Vector2(p.dot(tu), -p.y))
		else:
			s["uv"].append(Vector2(p.dot(tu), p.dot(tv)))
		s["uv2"].append(Vector2.ZERO)
	for i in range(1, w.size() - 1):
		s["i"].append_array([base, base + i + 1, base + i])
	k.stats["tris"] += w.size() - 2


## Local point on house wall `side` (0 front, 1 right, 2 back, 3 left):
## s = distance along the wall, n = outward offset from the wall's centre line.
func sp(side: int, s: float, y: float, n: float) -> Vector3:
	match side:
		0:
			return Vector3(s, y, -n)
		1:
			return Vector3(hw + n, y, s)
		2:
			return Vector3(hw - s, y, hd + n)
	return Vector3(-n, y, hd - s)


func _pieces(s0: float, s1: float, y0: float, y1: float, ops: Array) -> Array:
	var out: Array = []
	var o := ops.duplicate()
	o.sort_custom(func(p, q): return float(p["at"]) < float(q["at"]))
	var cur := s0
	for op in o:
		var w: float = op.get("w", 1.0)
		var a := clampf(float(op["at"]) - w * 0.5, s0, s1)
		var b := clampf(float(op["at"]) + w * 0.5, s0, s1)
		var top := y0 + float(op.get("h", 2.15))
		if a > cur + 0.01:
			out.append(Rect2(cur, y0, a - cur, y1 - y0))
		if top < y1 - 0.01:
			out.append(Rect2(a, top, b - a, y1 - top))
		cur = maxf(cur, b)
	if cur < s1 - 0.01:
		out.append(Rect2(cur, y0, s1 - cur, y1 - y0))
	return out


## Exterior wall: outer material + collision, optional interior lining.
func side_wall(side: int, y0: float, y1: float, mo: String, mi: String, ops: Array = []) -> void:
	var even := side % 2 == 0
	var ln := hw if even else hd
	var e0 := -T * 0.5 if even else T * 0.5
	var e1 := ln + T * 0.5 if even else ln - T * 0.5
	var fo: int = [NZ, PX, PZ, NX][side]
	var fi: int = [PZ, NX, NZ, PX][side]
	var fe := (PX | NX) if even else (PZ | NZ)
	for p in _pieces(e0, e1, y0, y1, ops):
		var pr: Rect2 = p
		var a := sp(side, pr.position.x, pr.position.y, -T * 0.5)
		var b := sp(side, pr.end.x, pr.end.y, T * 0.5)
		bx(a, b, mo, fo | fe | PY | NY, true)
		if mi != "":
			bx(a, b, mi, fi)


func window(side: int, s: float, y0: float, w: float, h: float, inner: bool, shutter: String) -> void:
	var o := T * 0.5
	bx(sp(side, s - w * 0.5 - 0.09, y0 - 0.09, o), sp(side, s + w * 0.5 + 0.09, y0 + h + 0.09, o + 0.03), "l9_trim")
	bx(sp(side, s - w * 0.5, y0, o), sp(side, s + w * 0.5, y0 + h, o + 0.045), "l9_glass")
	bx(sp(side, s - 0.022, y0, o), sp(side, s + 0.022, y0 + h, o + 0.065), "l9_trim")
	bx(sp(side, s - w * 0.5, y0 + h * 0.56 - 0.022, o), sp(side, s + w * 0.5, y0 + h * 0.56 + 0.022, o + 0.065), "l9_trim")
	bx(sp(side, s - w * 0.5 - 0.15, y0 - 0.15, o), sp(side, s + w * 0.5 + 0.15, y0 - 0.08, o + 0.09), "l9_trim")
	if shutter != "":
		bx(sp(side, s - w * 0.5 - 0.5, y0, o), sp(side, s - w * 0.5 - 0.12, y0 + h, o + 0.04), shutter)
		bx(sp(side, s + w * 0.5 + 0.12, y0, o), sp(side, s + w * 0.5 + 0.5, y0 + h, o + 0.04), shutter)
	if inner:
		bx(sp(side, s - w * 0.5, y0, -o), sp(side, s + w * 0.5, y0 + h, -o - 0.02), "l9_glass")
		bx(sp(side, s - w * 0.5 - 0.08, y0 - 0.07, -o), sp(side, s + w * 0.5 + 0.08, y0, -o - 0.13), "l9_trim")


## Roof over the local rectangle [x0,x1] x [z0,z1] from wall top `top`.
func roof(kind: String, x0: float, x1: float, z0: float, z1: float, top: float, sl: float, mat: String, wallm: String) -> float:
	var ov := 0.45
	var e := top - ov * sl
	var w := x1 - x0
	var d := z1 - z0
	var cz := (z0 + z1) * 0.5
	var cx := (x0 + x1) * 0.5
	if kind == "flat":
		bx(Vector3(x0 - 0.2, top, z0 - 0.2), Vector3(x1 + 0.2, top + 0.35, z1 + 0.2), "l9_trim_dark")
		return top + 0.35
	if kind == "gable_front" or (kind == "hip" and w < d):
		var yr := top + w * 0.5 * sl
		for sgn in [-1.0, 1.0]:
			var xe := x0 - ov if sgn < 0.0 else x1 + ov
			poly([Vector3(xe, e, z0 - ov), Vector3(xe, e, z1 + ov), Vector3(cx, yr, z1 + ov - (w * 0.5 + ov if kind == "hip" else 0.0)),
				Vector3(cx, yr, z0 - ov + (w * 0.5 + ov if kind == "hip" else 0.0))], mat, Vector3(sgn, 1, 0), "l9_soffit")
		if kind == "hip":
			for sgn in [-1.0, 1.0]:
				var ze := z0 - ov if sgn < 0.0 else z1 + ov
				poly([Vector3(x0 - ov, e, ze), Vector3(x1 + ov, e, ze), Vector3(cx, yr, ze - sgn * (w * 0.5 + ov))], mat, Vector3(0, 1, sgn), "l9_soffit")
		else:
			poly([Vector3(x0, top, z0 - T * 0.5), Vector3(x1, top, z0 - T * 0.5), Vector3(cx, yr, z0 - T * 0.5)], wallm, Vector3(0, 0, -1))
			poly([Vector3(x0, top, z1 + T * 0.5), Vector3(x1, top, z1 + T * 0.5), Vector3(cx, yr, z1 + T * 0.5)], wallm, Vector3(0, 0, 1))
		return yr
	var yr2 := top + d * 0.5 * sl
	var hx := (d * 0.5 + ov) if kind == "hip" else 0.0
	for sgn in [-1.0, 1.0]:
		var ze := z0 - ov if sgn < 0.0 else z1 + ov
		poly([Vector3(x0 - ov, e, ze), Vector3(x1 + ov, e, ze), Vector3(x1 + ov - hx, yr2, cz), Vector3(x0 - ov + hx, yr2, cz)], mat, Vector3(0, 1, sgn), "l9_soffit")
	if kind == "hip":
		for sgn in [-1.0, 1.0]:
			var xe := x0 - ov if sgn < 0.0 else x1 + ov
			poly([Vector3(xe, e, z0 - ov), Vector3(xe, e, z1 + ov), Vector3(xe - sgn * hx, yr2, cz)], mat, Vector3(sgn, 1, 0), "l9_soffit")
	else:
		poly([Vector3(x0 - T * 0.5, top, z0), Vector3(x0 - T * 0.5, top, z1), Vector3(x0 - T * 0.5, yr2, cz)], wallm, Vector3(-1, 0, 0))
		poly([Vector3(x1 + T * 0.5, top, z0), Vector3(x1 + T * 0.5, top, z1), Vector3(x1 + T * 0.5, yr2, cz)], wallm, Vector3(1, 0, 0))
	return yr2


# ------------------------------------------------------------- houses

## Seeded description of one house (every house differs; twins share a seed).
static func make_spec(seed_v: int, lot_w: float) -> Dictionary:
	var q := RandomNumberGenerator.new()
	q.seed = seed_v
	var style := q.randi() % 5           # 0 ranch, 1 colonial, 2 bungalow, 3 split, 4 modern box
	var st := 2 if style in [1, 3, 4] and q.randf() < 0.85 else 1
	var garage := 0
	if style in [0, 3] or q.randf() < 0.25:
		garage = 1 if q.randf() < 0.5 else 3
	var maxw := lot_w - 3.6 - (6.2 if garage != 0 else 0.0)
	if maxw < 8.0:
		garage = 0
		maxw = lot_w - 3.6
	var w := minf(q.randf_range(8.4, 13.6), maxw)
	var d := q.randf_range(8.4, 11.0)
	var sids := ["l9_sid_0", "l9_sid_1", "l9_sid_2", "l9_sid_3", "l9_sid_4", "l9_sid_5", "l9_sid_6", "l9_brick_0", "l9_brick_1", "l9_brick_2", "l9_stucco_0", "l9_stucco_1"]
	var sid: String = sids[q.randi() % sids.size()]
	if style == 4:
		sid = "l9_stucco_%d" % (q.randi() % 2)
	var roofs := ["hip", "gable", "gable_front", "gable", "flat"]
	var rf: String = roofs[style]
	if style != 4 and q.randf() < 0.3:
		rf = roofs[q.randi() % 4]
	var ds := snappedf(w * q.randf_range(0.3, 0.7), 0.05)
	var xs := snappedf(w * q.randf_range(0.48, 0.6), 0.05)
	if absf(xs - ds) < 1.2:
		xs = clampf(ds + (1.3 if ds < w * 0.5 else -1.3), 2.4, w - 2.4)
	var zs := snappedf(d * q.randf_range(0.46, 0.56), 0.05)
	var kleft := q.randf() < 0.5
	var xb := snappedf(w * q.randf_range(0.42, 0.58), 0.05)
	return {"seed": seed_v, "style": style, "w": w, "d": d, "fh": 0.45, "st": st, "roof": rf,
		"sl": q.randf_range(0.42, 0.72), "sid": sid, "roofm": "l9_roof_%d" % (q.randi() % 4),
		"door": "l9_door_%d" % (1 + q.randi() % 4), "ds": ds, "porch": style in [1, 2] or q.randf() < 0.35,
		"proof": style == 2 or q.randf() < 0.4, "garage": garage, "chim": style != 4 and q.randf() < 0.5,
		"shut": "l9_door_%d" % (1 + q.randi() % 4) if q.randf() < 0.4 else "", "paint": q.randi() % 6,
		"zs": zs, "xs": xs, "xb": xb, "kleft": kleft,
		"bdoor": clampf((xb * 0.5) if kleft else (xb + (w - xb) * 0.5), 1.0, w - 1.0),
		"empty": q.randf() < 0.14, "fab": q.randi() % 6, "floor": q.randi() % 3, "yard": q.randf() < 0.55,
		"enter": true}


## Local x-extent of the footprint incl. garage: [min, max].
static func extent(s: Dictionary) -> Vector2:
	var g: int = s["garage"]
	return Vector2(-6.2 if g == 3 else 0.0, float(s["w"]) + (6.2 if g == 1 else 0.0))


func house(s: Dictionary) -> void:
	hw = s["w"]
	hd = s["d"]
	var fh: float = s["fh"]
	var st: int = s["st"]
	var top := fh + SH * st
	var sid: String = s["sid"]
	var enter: bool = s["enter"]
	var mi := ("l9_paint_%d" % int(s["paint"])) if enter else ""
	var ds: float = s["ds"]
	var zs: float = s["zs"]
	var g: int = s["garage"]
	bx(Vector3(-T * 0.5, 0, -T * 0.5), Vector3(hw + T * 0.5, fh, hd + T * 0.5), "l9_foundation", ALL & ~NY, true, "wood")
	side_wall(0, fh, top, sid, mi, [{"at": ds, "w": 1.0, "h": 2.15}] if enter else [])
	side_wall(1, fh, top, sid, mi)
	side_wall(2, fh, top, sid, mi, [{"at": hw - float(s["bdoor"]), "w": 0.95, "h": 2.1}] if enter else [])
	side_wall(3, fh, top, sid, mi)
	if enter:
		bx(Vector3(0, fh + 2.6, 0), Vector3(hw, fh + 2.7, hd), "l9_ceiling", NY)
	if st == 2:
		bx(sp(0, -T, fh + SH - 0.1, T * 0.5), sp(0, hw + T, fh + SH + 0.05, T * 0.5 + 0.05), "l9_trim")
	# windows: avoid door, partitions and the garage side
	var shut: String = s["shut"]
	for fl in st:
		var y0 := fh + 0.95 + fl * SH
		var n := maxi(1, int((hw - 1.0) / 2.7))
		for i in n:
			var sx := (i + 0.5) * hw / n
			if fl == 0 and absf(sx - ds) < 1.5:
				continue
			if fl == 0 and absf(sx - float(s["xs"])) < 0.8:
				continue
			window(0, sx, y0, 1.1, 1.35, enter and fl == 0, shut)
		for side in [1, 3]:
			if fl == 0 and side == g:
				continue
			for zc in [zs * 0.5, (zs + hd) * 0.5]:
				window(side, zc if side == 1 else hd - zc, y0, 1.0, 1.3, enter and fl == 0, "")
		for i in 2:
			var bxp := hw * (0.25 + 0.5 * i)
			if fl == 0 and (absf(bxp - float(s["bdoor"])) < 1.4 or absf(bxp - float(s["xb"])) < 0.8):
				continue
			window(2, hw - bxp, y0, 1.0, 1.25, enter and fl == 0, "")
	# front door: trim, leaf (ajar inward when the house can be entered)
	var dm: String = s["door"]
	bx(sp(0, ds - 0.62, fh, T * 0.5), sp(0, ds - 0.5, fh + 2.27, T * 0.5 + 0.05), "l9_trim")
	bx(sp(0, ds + 0.5, fh, T * 0.5), sp(0, ds + 0.62, fh + 2.27, T * 0.5 + 0.05), "l9_trim")
	bx(sp(0, ds - 0.62, fh + 2.15, T * 0.5), sp(0, ds + 0.62, fh + 2.3, T * 0.5 + 0.05), "l9_trim")
	if enter:
		var ang := deg_to_rad(r.randf_range(55.0, 85.0))
		ybx(Vector3(ds - 0.5, fh, T * 0.5) + Vector3(cos(ang), 0, sin(ang)) * 0.47, -ang, Vector3(-0.47, 0.01, -0.025), Vector3(0.47, 2.12, 0.025), dm)
		var bd: float = s["bdoor"]
		ybx(Vector3(bd + 0.5, fh, hd - T * 0.5 - 0.48), PI * 0.5, Vector3(-0.46, 0.01, -0.02), Vector3(0.46, 2.08, 0.02), dm)
	else:
		bx(sp(0, ds - 0.5, fh, T * 0.5), sp(0, ds + 0.5, fh + 2.15, T * 0.5 + 0.03), dm)
	# porch or stoop + steps
	var pd := 1.8 if s["porch"] else 1.0
	var pw := 3.4 if s["porch"] else 1.6
	bx(Vector3(ds - pw * 0.5, 0, -pd), Vector3(ds + pw * 0.5, fh, -T * 0.5), "l9_porch_wood", ALL & ~NY, true)
	k.stairs(xf * Vector3(ds, 0, -pd - 0.9), xf.basis * Vector3(0, 0, 1), 1.4, fh, 3, "l9_porch_wood", 0.3, true)
	if s["porch"] and s["proof"]:
		for sx in [ds - pw * 0.5 + 0.15, ds + pw * 0.5 - 0.15]:
			bx(Vector3(sx - 0.08, fh, -pd + 0.07), Vector3(sx + 0.08, fh + 2.5, -pd + 0.23), "l9_trim", ALL, true)
		bx(Vector3(ds - pw * 0.5 - 0.2, fh + 2.5, -pd - 0.2), Vector3(ds + pw * 0.5 + 0.2, fh + 2.62, -T * 0.5), "l9_trim_dark")
	# garage
	if g != 0:
		var gx0 := hw if g == 1 else -6.2
		var gt := fh + 2.55
		bx(Vector3(gx0, 0, 0.6), Vector3(gx0 + 6.2, gt, 0.6 + 7.0), sid, ALL & ~NY, true)
		bx(Vector3(gx0 + 0.6, 0, 0.56), Vector3(gx0 + 5.6, 2.25, 0.6), "l9_garage")
		roof("hip" if s["roof"] != "flat" else "flat", gx0, gx0 + 6.2, 0.6, 7.6, gt, 0.35, s["roofm"], sid)
	var ridge := roof(s["roof"], 0, hw, 0, hd, top, s["sl"], s["roofm"], sid)
	if s["chim"]:
		var cxp := -0.75 if g != 3 else hw + 0.08
		bx(Vector3(cxp, 0, hd * 0.55 - 0.55), Vector3(cxp + 0.67, ridge + 0.7, hd * 0.55 + 0.55), "l9_brick_0", ALL, true)


## Yard dressing for one lot. Lot local extents: x [lx0,lx1], z [zf (sidewalk), zb].
func yard(s: Dictionary, lx0: float, lx1: float, zf: float, zb: float) -> void:
	var ds: float = s["ds"]
	var pd := 1.8 if s["porch"] else 1.0
	bx(Vector3(ds - 0.6, 0, zf), Vector3(ds + 0.6, 0.03, -pd - 0.9), "l9_paver", PY)
	var g: int = s["garage"]
	if g != 0:
		var gx0 := hw if g == 1 else -6.2
		bx(Vector3(gx0 + 0.5, 0, zf), Vector3(gx0 + 5.7, 0.025, 0.56), "l9_driveway", PY)
	# mailbox and dead shrubs along the front wall
	var mx := ds + 1.3
	bx(Vector3(mx - 0.05, 0, zf + 0.5), Vector3(mx + 0.05, 1.05, zf + 0.6), "l9_fence_wood")
	bx(Vector3(mx - 0.13, 1.05, zf + 0.33), Vector3(mx + 0.13, 1.3, zf + 0.8), "l9_metal_dark")
	for i in 3:
		var sx := r.randf_range(0.6, hw - 0.6)
		if absf(sx - ds) > 2.0:
			bx(Vector3(sx - 0.5, 0, -0.95), Vector3(sx + 0.5, r.randf_range(0.5, 0.9), -0.2), "l9_hedge")
	if r.randf() < 0.6:
		tree(Vector3(lx0 + 2.4 if r.randf() < 0.5 else lx1 - 2.4, 0, zf * r.randf_range(0.35, 0.6)), 1.0)
	if r.randf() < 0.5:
		tree(Vector3(r.randf_range(lx0 + 2.0, lx1 - 2.0), 0, minf(zb - 2.0, hd + 4.5)), 0.9)
	if not s["yard"] or zb - hd < 5.0:
		return
	# fully furnished back yard (patio, table, grill, swings or shed)
	var z0 := hd + 0.4
	var bd: float = s["bdoor"]
	bx(Vector3(bd - 2.0, 0, z0), Vector3(bd + 2.0, 0.08, z0 + 3.2), "l9_driveway", ALL & ~NY, true)
	var tc := Vector3(bd, 0.08, z0 + 1.8)
	bx(tc + Vector3(-0.55, 0.7, -0.55), tc + Vector3(0.55, 0.75, 0.55), "l9_metal_dark", ALL, true)
	bx(tc + Vector3(-0.04, 0, -0.04), tc + Vector3(0.04, 0.7, 0.04), "l9_metal_dark")
	stick(tc + Vector3(0, 0.75, 0), tc + Vector3(0, 2.3, 0), 0.04, "l9_metal_dark")
	poly([tc + Vector3(-1.2, 2.0, -1.2), tc + Vector3(1.2, 2.0, -1.2), tc + Vector3(1.2, 2.0, 1.2), tc + Vector3(-1.2, 2.0, 1.2)], "l9_fab_%d" % int(s["fab"]), Vector3.UP, "l9_fab_%d" % int(s["fab"]))
	for a in 4:
		var v := Vector3(cos(a * PI * 0.5), 0, sin(a * PI * 0.5)) * 0.95
		ybx(tc + v, -a * PI * 0.5, Vector3(-0.22, 0, -0.22), Vector3(0.22, 0.45, 0.22), "l9_metal_dark")
	bx(Vector3(bd + 2.6, 0, z0 + 0.4), Vector3(bd + 3.3, 0.95, z0 + 1.0), "l9_metal_dark", ALL, true)
	var mid := (lx0 + lx1) * 0.5
	if r.randf() < 0.5 and zb - hd > 8.0:
		var sw := Vector3(clampf(mid + r.randf_range(-3.0, 3.0), lx0 + 2.5, lx1 - 2.5), 0, zb - 2.6)
		for sgn in [-1.0, 1.0]:
			stick(sw + Vector3(sgn * 1.6, 0, -0.8), sw + Vector3(sgn * 1.6, 2.2, 0), 0.07, "l9_metal_dark", true)
			stick(sw + Vector3(sgn * 1.6, 0, 0.8), sw + Vector3(sgn * 1.6, 2.2, 0), 0.07, "l9_metal_dark")
		stick(sw + Vector3(-1.7, 2.2, 0), sw + Vector3(1.7, 2.2, 0), 0.08, "l9_metal_dark")
		for sx in [-0.7, 0.7]:
			stick(sw + Vector3(sx, 2.2, 0), sw + Vector3(sx + 0.1, 0.5, 0.15), 0.02, "l9_metal_dark")
			bx(sw + Vector3(sx - 0.2, 0.45, 0.05), sw + Vector3(sx + 0.35, 0.5, 0.3), "l9_plastic_0")
	elif zb - hd > 7.0:
		var shx := lx1 - 3.2 if r.randf() < 0.5 else lx0 + 0.6
		bx(Vector3(shx, 0, zb - 3.0), Vector3(shx + 2.6, 2.1, zb - 0.6), "l9_fence_wood", ALL, true)
		poly([Vector3(shx - 0.15, 2.1, zb - 3.15), Vector3(shx + 2.75, 2.1, zb - 3.15), Vector3(shx + 2.75, 2.45, zb - 1.8), Vector3(shx - 0.15, 2.45, zb - 1.8)], s["roofm"], Vector3(0, 1, -1), "l9_soffit")
		poly([Vector3(shx - 0.15, 2.1, zb - 0.45), Vector3(shx + 2.75, 2.1, zb - 0.45), Vector3(shx + 2.75, 2.45, zb - 1.8), Vector3(shx - 0.15, 2.45, zb - 1.8)], s["roofm"], Vector3(0, 1, 1), "l9_soffit")


## A dead tree: trunk (collides) and bare branches.
func tree(p: Vector3, sc: float) -> void:
	var h := r.randf_range(3.4, 5.8) * sc
	var rad := r.randf_range(0.14, 0.24) * sc
	k.cylinder(xf * (p + Vector3(0, h * 0.5, 0)), rad, h, "l9_bark", 7, true, false)
	for i in 4 + r.randi() % 4:
		var a := r.randf() * TAU
		var dir := Vector3(cos(a), r.randf_range(0.45, 1.25), sin(a)).normalized()
		var b0 := p + Vector3(0, h * r.randf_range(0.45, 0.92), 0)
		var ln := r.randf_range(1.2, 2.7) * sc
		var b1 := b0 + dir * ln
		stick(b0, b1, rad * 0.5, "l9_bark")
		for j in 2:
			var a2 := a + r.randf_range(-1.1, 1.1)
			var m := b0 + dir * ln * r.randf_range(0.5, 0.8)
			stick(m, m + Vector3(cos(a2), r.randf_range(0.3, 1.4), sin(a2)).normalized() * ln * 0.55, rad * 0.22, "l9_bark")
	stick(p + Vector3(0, h - 0.1, 0), p + Vector3(r.randf_range(-0.7, 0.7), h + 1.3 * sc, r.randf_range(-0.7, 0.7)), rad * 0.5, "l9_bark")


# ---------------------------------------------------------- interiors

## Furnished (or empty) ground floor. Returns {"drawer": local pos} for pickups.
func interior(s: Dictionary) -> Dictionary:
	hw = s["w"]
	hd = s["d"]
	var fh: float = s["fh"]
	var x0 := T * 0.5
	var x1 := hw - T * 0.5
	var z0 := T * 0.5
	var z1 := hd - T * 0.5
	var zs: float = s["zs"]
	var xs: float = s["xs"]
	var xb: float = s["xb"]
	var ds: float = s["ds"]
	var bd: float = s["bdoor"]
	var kl: bool = s["kleft"]
	var paint := "l9_paint_%d" % int(s["paint"])
	var floors := ["l9_wood", "l9_carpet_0", "l9_carpet_1"]
	var fl: String = floors[int(s["floor"])]
	# partitions: front split (wide archway), mid wall (two doors), back split
	var da := clampf((x0 + xb) * 0.5, x0 + 0.8, xb - 0.8)
	var db := clampf((xb + x1) * 0.5, xb + 0.8, x1 - 0.8)
	if absf(da - xs) < 0.9:
		da = clampf(xs - 1.0, x0 + 0.8, xb - 0.8)
	if absf(db - xs) < 0.9:
		db = clampf(xs + 1.0, xb + 0.8, x1 - 0.8)
	_part_x(xs, z0, zs, fh, paint, [{"at": (z0 + zs) * 0.5, "w": 1.7, "h": 2.25}])
	_part_z(zs, x0, x1, fh, paint, [{"at": da, "w": 0.95, "h": 2.1}, {"at": db, "w": 0.95, "h": 2.1}])
	_part_x(xb, zs, z1, fh, paint, [])
	var liv_left := ds < xs
	var rooms := [
		{"t": "living", "a": Vector2(x0 if liv_left else xs, z0), "b": Vector2(xs if liv_left else x1, zs)},
		{"t": "dining", "a": Vector2(xs if liv_left else x0, z0), "b": Vector2(x1 if liv_left else xs, zs)},
		{"t": "kitchen", "a": Vector2(x0 if kl else xb, zs), "b": Vector2(xb if kl else x1, z1)},
		{"t": "bedroom", "a": Vector2(xb if kl else x0, zs), "b": Vector2(x1 if kl else xb, z1)}]
	var block: Array = [Rect2(ds - 0.8, z0, 1.6, 1.5), Rect2(xs - 0.9, (z0 + zs) * 0.5 - 1.1, 1.8, 2.2),
		Rect2(da - 0.8, zs - 0.9, 1.6, 1.8), Rect2(db - 0.8, zs - 0.9, 1.6, 1.8), Rect2(bd - 0.8, z1 - 1.5, 1.6, 1.5)]
	var out := {}
	if s.get("arcade", false):
		block.append(Rect2(ds + 0.9, z0, 1.2, 1.4))
		_item("arcade", Vector3(ds + 1.5, fh, z0 + 0.42), 0.0, "", "")
	for rm in rooms:
		var a: Vector2 = rm["a"]
		var b: Vector2 = rm["b"]
		var fm := fl
		if rm["t"] == "kitchen":
			fm = "l9_tile_floor"
		elif rm["t"] == "dining":
			fm = "l9_wood"
		bx(Vector3(a.x, fh, a.y), Vector3(b.x, fh + 0.012, b.y), fm, PY)
		if not s["empty"]:
			var res := _furnish(rm["t"], a, b, fh, block, s)
			if res.has("drawer"):
				out["drawer"] = res["drawer"]
	return out


func _part_x(x: float, za: float, zb: float, fh: float, m: String, ops: Array) -> void:
	for p in _pieces(za, zb, fh, fh + 2.6, ops):
		var pr: Rect2 = p
		bx(Vector3(x - 0.05, pr.position.y, pr.position.x), Vector3(x + 0.05, pr.end.y, pr.end.x), m, ALL, true)


func _part_z(z: float, xa: float, xb_: float, fh: float, m: String, ops: Array) -> void:
	for p in _pieces(xa, xb_, fh, fh + 2.6, ops):
		var pr: Rect2 = p
		bx(Vector3(pr.position.x, pr.position.y, z - 0.05), Vector3(pr.end.x, pr.end.y, z + 0.05), m, ALL, true)


## Try to put an item (width w along the wall, depth dp) against one of the
## room's walls (prefs: 0 front z, 1 right x, 2 back z, 3 left x), avoiding
## door clearances and other items. Returns [centre, yaw] or [].
func _slot(a: Vector2, b: Vector2, w: float, dp: float, prefs: Array, block: Array) -> Array:
	for side in prefs:
		var ln := (b.x - a.x) if side % 2 == 0 else (b.y - a.y)
		if ln < w + 0.3:
			continue
		for t in [0.5, 0.25, 0.75, 0.12, 0.88]:
			var s := clampf(t * ln, w * 0.5 + 0.15, ln - w * 0.5 - 0.15)
			var c: Vector2
			var rr: Rect2
			match side:
				0:
					c = Vector2(a.x + s, a.y + dp * 0.5 + 0.03)
					rr = Rect2(c.x - w * 0.5, c.y - dp * 0.5, w, dp)
				2:
					c = Vector2(a.x + s, b.y - dp * 0.5 - 0.03)
					rr = Rect2(c.x - w * 0.5, c.y - dp * 0.5, w, dp)
				1:
					c = Vector2(b.x - dp * 0.5 - 0.03, a.y + s)
					rr = Rect2(c.x - dp * 0.5, c.y - w * 0.5, dp, w)
				_:
					c = Vector2(a.x + dp * 0.5 + 0.03, a.y + s)
					rr = Rect2(c.x - dp * 0.5, c.y - w * 0.5, dp, w)
			var ok := true
			for q in block:
				if (q as Rect2).intersects(rr):
					ok = false
					break
			if ok:
				block.append(rr.grow(0.25))
				return [c, [0.0, -PI * 0.5, PI, PI * 0.5][side], side]
	return []


func _furnish(t: String, a: Vector2, b: Vector2, fh: float, block: Array, s: Dictionary) -> Dictionary:
	var fab := "l9_fab_%d" % int(s["fab"])
	var out := {}
	var wood := "l9_wood_dark" if r.randf() < 0.5 else "l9_wood"
	match t:
		"living":
			var so := _slot(a, b, 2.1, 0.9, [2, 3, 1, 0], block)
			if so.size() > 0:
				var c3 := Vector3(so[0].x, fh, so[0].y)
				_item("sofa", c3, so[1], fab, wood)
				var fwd := Basis(Vector3.UP, so[1]) * Vector3(0, 0, 1.45)
				bx(c3 + fwd + Vector3(-1.3, 0.012, -1.0).rotated(Vector3.UP, so[1]), c3 + fwd + Vector3(1.3, 0.022, 1.0).rotated(Vector3.UP, so[1]), "l9_rug", PY)
				ybx(c3 + fwd, so[1], Vector3(-0.55, 0, -0.3), Vector3(0.55, 0.42, 0.3), wood, true)
				var tv := _slot(a, b, 1.5, 0.45, [(int(so[2]) + 2) % 4, 1, 3, 0], block)
				if tv.size() > 0:
					_item("tv", Vector3(tv[0].x, fh, tv[0].y), tv[1], fab, wood)
			for it in ["armchair", "shelf", "lamp"]:
				var w: float = {"armchair": 0.95, "shelf": 0.9, "lamp": 0.45}[it]
				var sl := _slot(a, b, w, 0.85 if it == "armchair" else 0.35, [1, 3, 0, 2], block)
				if sl.size() > 0:
					_item(it, Vector3(sl[0].x, fh, sl[0].y), sl[1], fab, wood)
		"dining":
			var c := (a + b) * 0.5
			if b.x - a.x > 3.2 and b.y - a.y > 3.0:
				var c3 := Vector3(c.x, fh, c.y)
				bx(c3 + Vector3(-0.85, 0.72, -0.5), c3 + Vector3(0.85, 0.77, 0.5), wood, ALL, true)
				for lx in [-0.75, 0.75]:
					for lz in [-0.42, 0.42]:
						bx(c3 + Vector3(lx - 0.04, 0, lz - 0.04), c3 + Vector3(lx + 0.04, 0.72, lz + 0.04), wood)
				for i in 4:
					var off := Vector3([-0.45, 0.45, -0.45, 0.45][i], 0, [-0.8, -0.8, 0.8, 0.8][i])
					_item("chair", c3 + off, 0.0 if off.z < 0.0 else PI, fab, wood)
				block.append(Rect2(c.x - 1.4, c.y - 1.4, 2.8, 2.8))
			for it in ["sideboard", "shelf"]:
				var sl := _slot(a, b, 1.6 if it == "sideboard" else 0.9, 0.45, [0, 1, 3, 2], block)
				if sl.size() > 0:
					_item(it, Vector3(sl[0].x, fh, sl[0].y), sl[1], fab, wood)
		"kitchen":
			var outer := 3 if s["kleft"] else 1
			var ln := b.y - a.y - 0.4
			var sl := _slot(a, b, ln, 0.62, [outer], block)
			if sl.size() > 0:
				var c3 := Vector3(sl[0].x, fh, sl[0].y)
				_item("counter", c3, sl[1], fab, wood, ln)
				out["drawer"] = c3 + Vector3(0, 0.95, 0)
			for it in ["fridge", "stove"]:
				var s2 := _slot(a, b, 0.8, 0.72, [0, 2, 1, 3], block)
				if s2.size() > 0:
					_item(it, Vector3(s2[0].x, fh, s2[0].y), s2[1], fab, wood)
		"bedroom":
			var bdl := _slot(a, b, 1.7, 2.15, [2, 1, 3], block)
			if bdl.size() > 0:
				var c3 := Vector3(bdl[0].x, fh, bdl[0].y)
				_item("bed", c3, bdl[1], fab, wood)
				for sx in [-1.15, 1.15]:
					var ns: Vector3 = c3 + (Vector3(sx, 0, -0.85)).rotated(Vector3.UP, bdl[1])
					ybx(ns, bdl[1], Vector3(-0.24, 0, -0.2), Vector3(0.24, 0.55, 0.2), wood)
					ybx(ns, bdl[1], Vector3(-0.12, 0.55, -0.12), Vector3(0.12, 0.85, 0.12), "l9_shade")
			for it in ["dresser", "wardrobe"]:
				var s3 := _slot(a, b, 1.2, 0.55, [1, 3, 0], block)
				if s3.size() > 0:
					_item(it, Vector3(s3[0].x, fh, s3[0].y), s3[1], fab, wood)
	return out


## Furniture in its own frame: x along the wall, +z faces into the room.
func _item(t: String, c: Vector3, yaw: float, fab: String, wood: String, ln: float = 1.0) -> void:
	match t:
		"sofa", "armchair":
			var h := 1.05 if t == "sofa" else 0.47
			ybx(c, yaw, Vector3(-h, 0, -0.42), Vector3(h, 0.42, 0.42), fab, true)
			ybx(c, yaw, Vector3(-h, 0.42, -0.42), Vector3(h, 0.9, -0.2), fab, true)
			ybx(c, yaw, Vector3(-h, 0.42, -0.2), Vector3(-h + 0.2, 0.62, 0.42), fab)
			ybx(c, yaw, Vector3(h - 0.2, 0.42, -0.2), Vector3(h, 0.62, 0.42), fab)
		"tv":
			ybx(c, yaw, Vector3(-0.75, 0, -0.22), Vector3(0.75, 0.5, 0.22), wood, true)
			ybx(c, yaw, Vector3(-0.6, 0.56, -0.08), Vector3(0.6, 1.24, -0.02), "l9_screen")
			ybx(c, yaw, Vector3(-0.12, 0.5, -0.1), Vector3(0.12, 0.56, 0.0), "l9_screen")
		"shelf":
			ybx(c, yaw, Vector3(-0.45, 0, -0.16), Vector3(0.45, 1.9, 0.16), wood, true)
			for y in [0.25, 0.75, 1.25]:
				ybx(c, yaw, Vector3(-0.4, y, -0.1), Vector3(0.4, y + 0.27, 0.17), "l9_books")
		"lamp":
			ybx(c, yaw, Vector3(-0.15, 0, -0.15), Vector3(0.15, 0.04, 0.15), "l9_metal_dark")
			ybx(c, yaw, Vector3(-0.02, 0, -0.02), Vector3(0.02, 1.45, 0.02), "l9_metal_dark")
			ybx(c, yaw, Vector3(-0.2, 1.4, -0.2), Vector3(0.2, 1.7, 0.2), "l9_shade")
		"chair":
			ybx(c, yaw, Vector3(-0.21, 0.43, -0.21), Vector3(0.21, 0.47, 0.21), wood)
			ybx(c, yaw, Vector3(-0.21, 0.47, -0.21), Vector3(0.21, 0.95, -0.17), wood)
			ybx(c, yaw, Vector3(-0.19, 0, -0.19), Vector3(0.19, 0.43, 0.19), wood)
		"sideboard", "dresser":
			var w := 0.8 if t == "sideboard" else 0.6
			ybx(c, yaw, Vector3(-w, 0, -0.22), Vector3(w, 0.88, 0.22), wood, true)
			ybx(c, yaw, Vector3(-0.35, 1.3, -0.24), Vector3(0.35, 1.85, -0.21), "l9_art")
		"wardrobe":
			ybx(c, yaw, Vector3(-0.6, 0, -0.27), Vector3(0.6, 2.0, 0.27), wood, true)
		"arcade":
			ybx(c, yaw, Vector3(-0.36, 0, -0.34), Vector3(0.36, 1.78, 0.3), "l9_arcade", true)
			ybx(c, yaw, Vector3(-0.36, 0.92, 0.3), Vector3(0.36, 1.0, 0.56), "l9_arcade")
			ybx(c, yaw, Vector3(-0.27, 1.08, 0.28), Vector3(0.27, 1.46, 0.33), "l9_screen")
			ybx(c, yaw, Vector3(-0.34, 1.56, 0.27), Vector3(0.34, 1.74, 0.33), "l9_screen")
			ybx(c, yaw, Vector3(-0.2, 1.0, 0.45), Vector3(-0.16, 1.1, 0.49), "l9_sign_black")
		"counter":
			var h := ln * 0.5
			ybx(c, yaw, Vector3(-h, 0, -0.31), Vector3(h, 0.88, 0.29), "l9_cabinet", true)
			ybx(c, yaw, Vector3(-h, 0.88, -0.31), Vector3(h, 0.93, 0.33), "l9_counter")
			ybx(c, yaw, Vector3(-0.35, 0.89, -0.22), Vector3(0.35, 0.935, 0.2), "l9_steel")
			ybx(c, yaw, Vector3(-h, 1.45, -0.31), Vector3(h, 2.15, 0.02), "l9_cabinet")
		"fridge":
			ybx(c, yaw, Vector3(-0.4, 0, -0.36), Vector3(0.4, 1.8, 0.36), "l9_appliance", true)
			ybx(c, yaw, Vector3(0.3, 0.9, 0.36), Vector3(0.34, 1.5, 0.39), "l9_steel")
		"stove":
			ybx(c, yaw, Vector3(-0.38, 0, -0.33), Vector3(0.38, 0.9, 0.33), "l9_appliance", true)
			ybx(c, yaw, Vector3(-0.38, 0.9, -0.33), Vector3(0.38, 0.93, 0.33), "l9_screen")
		"bed":
			ybx(c, yaw, Vector3(-0.85, 0, -1.07), Vector3(0.85, 0.32, 1.07), wood, true)
			ybx(c, yaw, Vector3(-0.8, 0.32, -1.0), Vector3(0.8, 0.54, 1.03), "l9_sheet")
			ybx(c, yaw, Vector3(-0.82, 0.5, -0.3), Vector3(0.82, 0.6, 1.06), fab)
			ybx(c, yaw, Vector3(-0.72, 0.54, -0.98), Vector3(-0.06, 0.68, -0.62), "l9_sheet")
			ybx(c, yaw, Vector3(0.06, 0.54, -0.98), Vector3(0.72, 0.68, -0.62), "l9_sheet")
			ybx(c, yaw, Vector3(-0.85, 0, -1.07), Vector3(0.85, 1.1, -0.99), wood)


# --------------------------------------------------------- street props

## Lamp post: pole on the verge, arm over the street. state 0 dead, 1 flicker, 2 on.
func lamp(p: Vector3, out: Vector3, state: int, seed_v: float) -> Vector3:
	bx(p + Vector3(-0.09, 0, -0.09), p + Vector3(0.09, 5.5, 0.09), "l9_metal_dark", ALL, true)
	var tip := p + out * 1.6 + Vector3(0, 5.35, 0)
	stick(p + Vector3(0, 5.3, 0), tip, 0.08, "l9_metal_dark")
	bx(tip + Vector3(-0.3, -0.14, -0.3), tip + Vector3(0.3, 0.02, 0.3), "l9_metal_dark")
	k.panel(xf * (tip + Vector3(0, -0.145, 0)), 0.46, 0.46, "l9_lamp", seed_v + (100.0 if state == 0 else 0.0), 0.9 if state == 1 else 0.0)
	return tip + Vector3(0, -0.4, 0)


## Square arrow sign facing `face`; turn 0 straight, 1 left, 2 right.
func arrow_sign(c: Vector3, face: Vector3, turn: int) -> void:
	var rt := Vector3(face.z, 0, -face.x)
	var bas := Basis(rt, Vector3.UP, face)
	k.box_xf(Transform3D(xf.basis * bas, xf * c), Vector3(0.86, 0.86, 0.03), "l9_sign_black")
	k.box_xf(Transform3D(xf.basis * bas, xf * (c + face * 0.012)), Vector3(0.78, 0.78, 0.03), "l9_sign_white")
	var f := face * 0.04
	var pts: Array = []
	match turn:
		0:
			pts = [[Vector2(-0.07, -0.29), Vector2(0.07, -0.29), Vector2(0.07, 0.06), Vector2(-0.07, 0.06)], [Vector2(-0.22, 0.04), Vector2(0.22, 0.04), Vector2(0, 0.3)]]
		1:
			pts = [[Vector2(-0.06, -0.07), Vector2(0.29, -0.07), Vector2(0.29, 0.07), Vector2(-0.06, 0.07)], [Vector2(-0.04, -0.22), Vector2(-0.04, 0.22), Vector2(-0.3, 0)]]
		_:
			pts = [[Vector2(-0.29, -0.07), Vector2(0.06, -0.07), Vector2(0.06, 0.07), Vector2(-0.29, 0.07)], [Vector2(0.04, -0.22), Vector2(0.04, 0.22), Vector2(0.3, 0)]]
	for shape in pts:
		var q: Array = []
		for v in shape:
			q.append(c + f + rt * (v as Vector2).x + Vector3.UP * (v as Vector2).y)
		poly(q, "l9_sign_black", face)


## Wooden utility pole with a crossarm; returns the three wire anchor points.
func pole(p: Vector3, along: Vector3) -> Array:
	k.cylinder(xf * (p + Vector3(0, 4.6, 0)), 0.14, 9.2, "l9_pole_wood", 6, true, false)
	var cr := along.cross(Vector3.UP).normalized()
	stick(p + Vector3(0, 8.4, 0) - cr * 1.1, p + Vector3(0, 8.4, 0) + cr * 1.1, 0.1, "l9_pole_wood")
	bx(p + Vector3(-0.25, 7.0, -0.25), p + Vector3(0.25, 7.8, 0.25), "l9_metal_dark")
	return [p + Vector3(0, 8.5, 0) - cr, p + Vector3(0, 8.5, 0), p + Vector3(0, 8.5, 0) + cr]


func wire(a: Vector3, b: Vector3) -> void:
	var m := (a + b) * 0.5 + Vector3(0, -0.9, 0)
	stick(a, m, 0.025, "l9_wire")
	stick(m, b, 0.025, "l9_wire")


func bench(c: Vector3, yaw: float) -> void:
	ybx(c, yaw, Vector3(-0.9, 0.42, -0.22), Vector3(0.9, 0.47, 0.22), "l9_fence_wood", true)
	ybx(c, yaw, Vector3(-0.9, 0.55, -0.24), Vector3(0.9, 0.9, -0.2), "l9_fence_wood")
	for sx in [-0.75, 0.75]:
		ybx(c, yaw, Vector3(sx - 0.04, 0, -0.2), Vector3(sx + 0.04, 0.42, 0.2), "l9_metal_dark")


## Horizontal crawl tube (axis along local x) with glowing white windows.
func tube(c: Vector3, ln: float, rad: float) -> void:
	var n := 14
	for i in n:
		var a := TAU * (i + 0.5) / n
		var nrm := Vector3(0, sin(a), cos(a))
		var bas := Basis(Vector3.RIGHT, nrm.cross(Vector3.RIGHT), nrm)
		var lit := i in [2, 5, 9, 12]
		k.box_xf(Transform3D(xf.basis * bas, xf * (c + nrm * rad)), Vector3(ln, TAU * rad / n + 0.03, 0.06), "l9_plastic_2", ALL, false)
		if lit:
			for wx in [-ln * 0.3, 0.0, ln * 0.3]:
				for sgn in [1.0, -1.0]:
					k.box_xf(Transform3D(xf.basis * bas, xf * (c + nrm * (rad + sgn * 0.035) + Vector3(wx, 0, 0))), Vector3(0.5, 0.28, 0.01), "l9_tube_window")
	k.add_box_shape(Transform3D(xf.basis, xf * c), Vector3(ln, rad * 2.0, rad * 2.0), "plastic")


# ------------------------------------------------------ set pieces

## Small airport on the sign route: terminal (glass front facing -z), canopy,
## control tower and a line of faint blue taxiway lights. Returns door centre.
func airport(w: float, dpt: float) -> Vector3:
	var tw := minf(w - 16.0, 70.0)
	var x0 := (w - tw) * 0.5
	var z0 := 14.0
	var hh := 9.0
	bx(Vector3(x0, 0, z0), Vector3(x0 + tw, 0.15, z0 + 22.0), "l9_driveway", ALL, true)
	for p in [[Vector3(x0, 0.15, z0 + 22.0), Vector3(x0 + tw, hh, z0 + 22.3)], [Vector3(x0, 0.15, z0), Vector3(x0 + 0.3, hh, z0 + 22.0)],
			[Vector3(x0 + tw - 0.3, 0.15, z0), Vector3(x0 + tw, hh, z0 + 22.0)]]:
		bx(p[0], p[1], "l9_terminal", ALL, true)
	bx(Vector3(x0 - 0.5, hh, z0 - 0.5), Vector3(x0 + tw + 0.5, hh + 1.4, z0 + 22.8), "l9_terminal", ALL, true)
	var dc := x0 + tw * 0.5
	for i in int(tw / 3.0):
		var sx := x0 + 1.5 + i * 3.0
		if absf(sx - dc) < 2.6:
			continue
		bx(Vector3(sx - 1.45, 0.15, z0 - 0.06), Vector3(sx + 1.45, hh, z0 + 0.06), "l9_glass", ALL, true)
		bx(Vector3(sx + 1.45, 0.15, z0 - 0.12), Vector3(sx + 1.55, hh, z0 + 0.12), "l9_metal_dark", ALL, true)
	bx(Vector3(dc - 2.5, 3.0, z0 - 0.08), Vector3(dc + 2.5, hh, z0 + 0.08), "l9_glass", ALL, true)
	bx(Vector3(dc - 4.0, 4.0, z0 - 8.0), Vector3(dc + 4.0, 4.3, z0), "l9_terminal")
	for sx in [dc - 3.8, dc + 3.8]:
		bx(Vector3(sx - 0.12, 0, z0 - 7.8), Vector3(sx + 0.12, 4.0, z0 - 7.56), "l9_metal_dark", ALL, true)
	bx(Vector3(x0 + tw * 0.2, 0.15, z0 + 6.0), Vector3(x0 + tw * 0.8, 0.16, z0 + 21.0), "l9_tile_floor", PY)
	# control tower behind the terminal
	var tc := Vector3(x0 + tw * 0.78, 0, z0 + 30.0)
	k.cylinder(xf * (tc + Vector3(0, 12.0, 0)), 1.6, 24.0, "l9_terminal", 10, true, true)
	k.cylinder(xf * (tc + Vector3(0, 25.6, 0)), 3.4, 3.2, "l9_glass", 10, false, true)
	k.cylinder(xf * (tc + Vector3(0, 27.5, 0)), 3.8, 0.6, "l9_terminal", 10, false, true)
	# apron + taxiway edge lights
	bx(Vector3(4.0, 0, z0 + 24.0), Vector3(w - 4.0, 0.06, dpt - 4.0), "l9_asphalt", ALL & ~NY, true)
	for i in int((w - 10.0) / 6.0):
		for zz in [z0 + 44.0, z0 + 62.0]:
			if zz < dpt - 6.0:
				bx(Vector3(5.0 + i * 6.0, 0.06, zz), Vector3(5.25 + i * 6.0, 0.3, zz + 0.25), "l9_taxi" if (i + int(zz)) % 5 != 0 else "l9_metal_dark")
	return Vector3(dc, 0.15, z0)


## Night skyline cluster (no collision): dark towers with scattered lit windows.
func skyline(c: Vector3, along: Vector3, n: int) -> void:
	var side := along.cross(Vector3.UP).normalized()
	for i in n:
		var p := c + along * r.randf_range(0.0, 260.0) + side * r.randf_range(-170.0, 170.0)
		var w := r.randf_range(18.0, 34.0)
		var h := r.randf_range(40.0, 150.0)
		bx(p + Vector3(-w * 0.5, 0, -w * 0.5), p + Vector3(w * 0.5, h, w * 0.5), "l9_tower")
		for j in 26:
			var fy := r.randf_range(4.0, h - 3.0)
			var s := r.randf_range(-w * 0.45, w * 0.45)
			var o := p - along * (w * 0.5 + 0.05) + side * s + Vector3(0, fy, 0)
			bx(o - side * 0.7 - Vector3(0, 0.5, 0), o + side * 0.7 + Vector3(0, 0.5, 0) - along * 0.02, "l9_win_lit" if r.randf() < 0.7 else "l9_win_cold")
