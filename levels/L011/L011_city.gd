extends RefCounted
## Level 11 geometry helper for levels/L011/L011.gd: buildings (lit, dark or
## black-mirror facades; enterable ground-floor public rooms), streets with
## working signals, the canal with bridges, parks and street props. All world
## coordinates; one GeoKit per chunk.

const LY := 0.15
const ALL := 63
const SIDES := 51
const PY := 4

var k: GeoKit
var r: RandomNumberGenerator


func _init(kit: GeoKit, rng: RandomNumberGenerator) -> void:
	k = kit
	r = rng


func bmm(a: Vector3, b: Vector3, mat: String, faces: int = ALL, col: bool = true) -> void:
	k.box_mm(a.min(b), a.max(b), mat, faces, col)


func stick(a: Vector3, b: Vector3, th: float, mat: String, col: bool = false) -> void:
	var d := b - a
	var y := d.normalized()
	var x := (Vector3.UP if absf(y.y) < 0.95 else Vector3.RIGHT).cross(y).normalized()
	k.box_xf(Transform3D(Basis(x, y, x.cross(y)), (a + b) * 0.5), Vector3(th, d.length(), th), mat, ALL, col)


func tri(a: Vector3, b: Vector3, c: Vector3, mat: String, hint: Vector3) -> void:
	var n := (b - a).cross(c - a).normalized()
	if n.dot(hint) < 0.0:
		var t := b
		b = c
		c = t
		n = -n
	var s: Dictionary = k._s(mat)
	var base: int = s["v"].size()
	for p in [a, b, c]:
		s["v"].append(p)
		s["n"].append(n)
		s["uv"].append(Vector2(p.x + p.y, p.z + p.y))
		s["uv2"].append(Vector2.ZERO)
	s["i"].append_array([base, base + 2, base + 1])


## Face frame of a building rect for front side f (0 -z, 1 +x, 2 +z, 3 -x):
## returns [origin corner on the facade line, along unit, outward unit, length].
static func face(rc: Rect2, f: int) -> Array:
	match f:
		0:
			return [Vector3(rc.position.x, 0, rc.position.y), Vector3(1, 0, 0), Vector3(0, 0, -1), rc.size.x]
		1:
			return [Vector3(rc.end.x, 0, rc.position.y), Vector3(0, 0, 1), Vector3(1, 0, 0), rc.size.y]
		2:
			return [Vector3(rc.end.x, 0, rc.end.y), Vector3(-1, 0, 0), Vector3(0, 0, 1), rc.size.x]
	return [Vector3(rc.position.x, 0, rc.end.y), Vector3(0, 0, -1), Vector3(-1, 0, 0), rc.size.y]


# ------------------------------------------------------------- buildings

## Build one planned building. Returns light anchor positions for open rooms.
func building(b: Dictionary) -> Array:
	var rc: Rect2 = b["r"]
	var h: float = b["h"]
	var fac: String = b["fac"]
	var lights: Array = []
	var shop: String = b["shop"]
	var y0 := LY
	if b["kind"] == "tower":
		var pod: float = b["pod"]
		var ins: float = b["ins"]
		_block(rc, y0, pod, fac, shop, b["front"], lights)
		var sh := rc.grow(-ins)
		k.box_mm(Vector3(sh.position.x, pod, sh.position.y), Vector3(sh.end.x, h, sh.end.y), fac, SIDES | PY, true)
		var cr := sh.grow(-3.5)
		k.box_mm(Vector3(cr.position.x, h, cr.position.y), Vector3(cr.end.x, h + 5.0, cr.end.y), "l11_roofdeck", SIDES | PY, false)
		if b["spire"]:
			var c := Vector3(cr.get_center().x, h + 5.0, cr.get_center().y)
			stick(c, c + Vector3(0, 14.0, 0), 0.5, "l11_rail_metal")
			k.box(c + Vector3(0, 14.3, 0), Vector3(0.6, 0.6, 0.6), "l11_blink", ALL, false)
	elif b["kind"] == "house":
		_house(b)
	else:
		_block(rc, y0, h, fac, shop, b["front"], lights)
		if h > 9.0 and r.randf() < 0.5:
			var c := rc.get_center()
			k.cylinder(Vector3(c.x + r.randf_range(-3, 3), h + 1.6, c.y + r.randf_range(-3, 3)), 1.3, 3.2, "l11_wood", 10, false, true)
		if h > 6.0:
			bmm(Vector3(rc.position.x, h, rc.position.y), Vector3(rc.end.x, h + 0.9, rc.position.y + 0.3), fac, SIDES | PY, false)
	return lights


## Ground floor (open public room behind glass, or sealed) + the mass above.
func _block(rc: Rect2, y0: float, top: float, fac: String, shop: String, f: int, lights: Array) -> void:
	if shop == "" or top < 4.0:
		k.box_mm(Vector3(rc.position.x, y0, rc.position.y), Vector3(rc.end.x, top, rc.end.y), fac, SIDES | PY, true)
		if shop == "" and fac == "l11_fac_mirror":
			var fr := face(rc, f)
			var o: Vector3 = fr[0] + fr[1] * (float(fr[3]) * 0.5) + Vector3(0, y0, 0)
			bmm(o - fr[1] * 0.9 + fr[2] * 0.01, o + fr[1] * 0.9 + fr[2] * 0.08 + Vector3(0, 2.3, 0), "l11_dark", ALL, false)
		return
	var fr2 := face(rc, f)
	var org: Vector3 = fr2[0] + Vector3(0, y0, 0)
	var al: Vector3 = fr2[1]
	var out: Vector3 = fr2[2]
	var ln: float = fr2[3]
	var dp := minf(9.0, (rc.size.y if f % 2 == 0 else rc.size.x) - 2.0)
	var gh := 4.3
	# mass above the room, and the solid rest of the ground floor behind it
	k.box_mm(Vector3(rc.position.x, y0 + gh, rc.position.y), Vector3(rc.end.x, top, rc.end.y), fac, SIDES | PY, true)
	var back := org - out * dp
	var far := org + al * ln - out * ((rc.size.y if f % 2 == 0 else rc.size.x))
	bmm(back + Vector3(0, 0, 0), far + Vector3(0, gh, 0), fac, SIDES, true)
	# room shell
	bmm(org - out * dp + al * 0.0, org + al * 0.25 + Vector3(0, gh, 0), "l11_shop_wall", ALL, true)
	bmm(org + al * (ln - 0.25) - out * dp, org + al * ln + Vector3(0, gh, 0), "l11_shop_wall", ALL, true)
	bmm(back + al * 0.25 + out * 0.0, back + al * (ln - 0.25) + out * 0.05 + Vector3(0, gh - 0.4, 0), "l11_shop_wall", ALL, false)
	bmm(org - out * dp, org + al * ln + Vector3(0, 0.02, 0), "l11_terrazzo" if shop == "lobby" else "l11_tile", PY, false)
	bmm(org - out * dp + Vector3(0, gh - 0.45, 0), org + al * ln + Vector3(0, gh, 0), "l11_shop_ceiling", ALL, false)
	for i in maxi(1, int(ln / 4.0)):
		var pc: Vector3 = org + al * ((i + 0.5) * ln / maxi(1, int(ln / 4.0))) - out * dp * 0.5 + Vector3(0, gh - 0.47, 0)
		k.panel(pc, 1.2 if f % 2 == 0 else 0.4, 0.4 if f % 2 == 0 else 1.2, "l11_panel", float(i))
	lights.append(org + al * (ln * 0.5) - out * (dp * 0.5) + Vector3(0, gh - 1.0, 0))
	# glass front with a doorway, sign band above
	var dc := ln * (0.5 if shop != "arcade" else 0.3)
	var gw := "glass"
	for seg in [[0.25, dc - 0.95], [dc + 0.95, ln - 0.25]]:
		if seg[1] - seg[0] > 0.1:
			bmm(org + al * float(seg[0]) - out * 0.05, org + al * float(seg[1]) + Vector3(0, 3.3, 0), gw, ALL, true)
			for m in range(int(seg[0]), int(seg[1]), 3):
				bmm(org + al * (m + 0.0) - out * 0.06, org + al * (m + 0.08) + out * 0.04 + Vector3(0, 3.3, 0), "l11_rail_metal", ALL, false)
	bmm(org - out * 0.1 + Vector3(0, 3.3, 0), org + al * ln + out * 0.12 + Vector3(0, gh, 0), "l11_dark", ALL, true)
	_furnish(shop, org, al, out, ln, dp)


func _furnish(shop: String, org: Vector3, al: Vector3, out: Vector3, ln: float, dp: float) -> void:
	var P := func(s: float, d: float, y: float) -> Vector3: return org + al * s - out * d + Vector3(0, y, 0)
	match shop:
		"store":
			for i in maxi(1, int((ln - 4.0) / 3.2)):
				var s := 2.2 + i * 3.2
				bmm(P.call(s, 2.6, 0), P.call(s + 0.9, dp - 1.2, 1.7), "l11_shelf", ALL, true)
				for y in [0.4, 0.95, 1.5]:
					bmm(P.call(s - 0.05, 2.7, y), P.call(s + 0.95, dp - 1.3, y + 0.3), "l11_goods", ALL, false)
			bmm(P.call(ln - 2.6, 0.9, 0), P.call(ln - 0.6, 1.6, 1.0), "l11_wood", ALL, true)
		"laundromat":
			for i in int((ln - 1.0) / 0.8):
				var s := 0.6 + i * 0.8
				bmm(P.call(s, dp - 0.8, 0), P.call(s + 0.72, dp - 0.1, 0.95), "l11_paper", ALL, true)
				bmm(P.call(s + 0.16, dp - 0.83, 0.3), P.call(s + 0.56, dp - 0.8, 0.7), "l11_dark", ALL, false)
			bmm(P.call(ln * 0.3, dp * 0.45, 0.42), P.call(ln * 0.7, dp * 0.45 + 0.5, 0.48), "l11_wood", ALL, true)
		"office":
			for i in maxi(1, int((ln - 2.0) / 3.0)):
				var s := 1.4 + i * 3.0
				bmm(P.call(s, dp * 0.5, 0.72), P.call(s + 1.5, dp * 0.5 + 0.75, 0.76), "l11_wood", ALL, true)
				bmm(P.call(s + 0.5, dp * 0.5 + 0.9, 0), P.call(s + 1.0, dp * 0.5 + 1.4, 0.95), "l11_fabric", ALL, false)
				bmm(P.call(s, dp * 0.5 - 0.1, 0.0), P.call(s + 1.6, dp * 0.5 - 0.05, 1.3), "l11_fabric", ALL, false)
		"lobby":
			bmm(P.call(ln * 0.5 - 1.6, dp - 2.2, 0), P.call(ln * 0.5 + 1.6, dp - 1.4, 1.1), "l11_wood", ALL, true)
			for s in [1.5, ln - 2.5]:
				bmm(P.call(s, 1.6, 0), P.call(s + 1.0, 2.4, 0.45), "l11_fabric", ALL, true)
				k.cylinder(P.call(s + 0.5, 3.6, 0.35), 0.35, 0.7, "l11_dark", 8, true, true)
				k.cylinder(P.call(s + 0.5, 3.6, 1.1), 0.55, 0.9, "l11_leaves", 8, false, true)
		"arcade":
			for i in int((ln - 2.0) / 1.2):
				var s := 1.2 + i * 1.2
				for row in [dp - 0.6, dp * 0.45]:
					cabinet(P.call(s, row, 0.0), atan2(out.x, out.z) + (PI if row < dp * 0.5 else 0.0), "l11_cabinet_red" if (i + int(row)) % 2 == 0 else "l11_cabinet_blue")


## Arcade cabinet; front (screen side) faces +z of its yaw frame.
func cabinet(c: Vector3, yaw: float, body: String) -> void:
	var bas := Basis(Vector3.UP, yaw)
	var B := func(a: Vector3, b: Vector3, m: String, col: bool) -> void: k.box_xf(Transform3D(bas, c + bas * ((a + b) * 0.5)), (b - a).abs(), m, ALL, col)
	B.call(Vector3(-0.36, 0, -0.35), Vector3(0.36, 1.8, 0.3), body, true)
	B.call(Vector3(-0.36, 0.92, 0.3), Vector3(0.36, 1.0, 0.56), body, false)
	B.call(Vector3(-0.28, 1.08, 0.29), Vector3(0.28, 1.5, 0.33), "l11_screen_game", false)
	B.call(Vector3(-0.34, 1.58, 0.28), Vector3(0.34, 1.76, 0.33), "l11_neon_cyan", false)
	B.call(Vector3(-0.2, 1.0, 0.44), Vector3(-0.15, 1.08, 0.49), "l11_dark", false)


func _house(b: Dictionary) -> void:
	var rc: Rect2 = b["r"]
	var h: float = b["h"]
	k.box_mm(Vector3(rc.position.x, LY, rc.position.y), Vector3(rc.end.x, h, rc.end.y), b["fac"], SIDES, true)
	var e := 0.4
	var y1 := h + 2.2
	var x0 := rc.position.x - e
	var x1 := rc.end.x + e
	var z0 := rc.position.y - e
	var z1 := rc.end.y + e
	var cz := rc.get_center().y
	for q in [[Vector3(x0, h, z0), Vector3(x1, h, z0), Vector3(x1, y1, cz), Vector3(x0, y1, cz), -1.0], [Vector3(x0, h, z1), Vector3(x1, h, z1), Vector3(x1, y1, cz), Vector3(x0, y1, cz), 1.0]]:
		tri(q[0], q[1], q[2], "l11_roofdeck", Vector3(0, 1, q[4]))
		tri(q[0], q[2], q[3], "l11_roofdeck", Vector3(0, 1, q[4]))
	for sx in [rc.position.x, rc.end.x]:
		tri(Vector3(sx, h, rc.position.y), Vector3(sx, h, rc.end.y), Vector3(sx, y1 - 0.3, cz), "l11_fac_house", Vector3(sign(sx - rc.get_center().x), 0, 0))
	var fr := face(rc, b["front"])
	var o: Vector3 = fr[0] + fr[1] * (float(fr[3]) * 0.4) + Vector3(0, LY, 0)
	bmm(o - fr[1] * 0.5 + fr[2] * 0.01, o + fr[1] * 0.5 + fr[2] * 0.07 + Vector3(0, 2.15, 0), "l11_wood", ALL, false)


# --------------------------------------------------------------- streets

## Cobra-head street light; returns the light anchor point.
func street_light(p: Vector3, out: Vector3, led: bool) -> Vector3:
	bmm(p + Vector3(-0.1, 0, -0.1), p + Vector3(0.1, 8.0, 0.1), "l11_rail_metal", ALL, true)
	var tip := p + out * 2.6 + Vector3(0, 7.9, 0)
	stick(p + Vector3(0, 7.8, 0), tip, 0.12, "l11_rail_metal")
	k.box(tip, Vector3(0.9, 0.18, 0.45) if absf(out.x) > 0.5 else Vector3(0.45, 0.18, 0.9), "l11_rail_metal", ALL, false)
	k.panel(tip + Vector3(0, -0.1, 0), 0.7 if absf(out.x) > 0.5 else 0.32, 0.32 if absf(out.x) > 0.5 else 0.7, "l11_lamp_led" if led else "l11_lamp", 1.0)
	return tip + Vector3(0, -0.5, 0)


## Signal mast on a corner; heads for both axes (ns faces +-z, ew faces +-x).
func signal_mast(p: Vector3) -> void:
	bmm(p + Vector3(-0.1, 0, -0.1), p + Vector3(0.1, 5.2, 0.1), "l11_rail_metal", ALL, true)
	for ax in ["ns", "ew"]:
		var o := Vector3(0, 0, 0.32) if ax == "ns" else Vector3(0.32, 0, 0)
		for sg in [1.0, -1.0]:
			var hc: Vector3 = p + o * sg + Vector3(0, 4.2, 0)
			k.box(hc, Vector3(0.35, 1.05, 0.35), "l11_dark", ALL, false)
			var f: Vector3 = o.normalized() * sg * 0.18
			for i in 3:
				var cc: Vector3 = hc + f + Vector3(0, 0.32 - i * 0.32, 0)
				k.box(cc, Vector3(0.22, 0.22, 0.03) if ax == "ns" else Vector3(0.03, 0.22, 0.22), "l11_sig_%s_%s" % [ax, ["r", "a", "g"][i]], ALL, false)


func tree(p: Vector3, sc: float) -> void:
	var h := r.randf_range(3.2, 4.6) * sc
	k.cylinder(p + Vector3(0, h * 0.5, 0), 0.16 * sc, h, "l11_bark", 7, true, false)
	for i in 3:
		var c := p + Vector3(r.randf_range(-0.8, 0.8), h + r.randf_range(-0.3, 1.0), r.randf_range(-0.8, 0.8)) * sc
		k.cylinder(c, r.randf_range(1.1, 1.7) * sc, r.randf_range(1.4, 2.2) * sc, "l11_leaves", 9, false, true)


func bench(c: Vector3, yaw: float) -> void:
	var bas := Basis(Vector3.UP, yaw)
	k.box_xf(Transform3D(bas, c + bas * Vector3(0, 0.45, 0)), Vector3(1.8, 0.08, 0.45), "l11_wood", ALL, true)
	k.box_xf(Transform3D(bas, c + bas * Vector3(0, 0.75, -0.2)), Vector3(1.8, 0.4, 0.06), "l11_wood", ALL, false)
	k.box_xf(Transform3D(bas, c + bas * Vector3(0, 0.22, 0)), Vector3(1.5, 0.44, 0.3), "l11_rail_metal", ALL, false)


## Canal segment along x in corridor [oz, oz+20] for chunk x range [x0, x1];
## the bridge square [x0, x0+20] carries the z-street over the water.
func canal(x0: float, x1: float, oz: float, lights: Array) -> void:
	var c0 := oz + 3.5
	var c1 := oz + 16.5
	k.slab(x0 + 20.0, oz, x1, c0, LY, 0.45, "l11_sidewalk", PY | SIDES)
	k.slab(x0 + 20.0, c1, x1, oz + 20.0, LY, 0.45, "l11_sidewalk", PY | SIDES)
	k.slab(x0, c0, x1, c1, -4.5, 0.4, "l11_canal_wall", PY)
	bmm(Vector3(x0, -4.5, c0 - 0.4), Vector3(x1, LY - 0.3, c0), "l11_canal_wall", ALL, true)
	bmm(Vector3(x0, -4.5, c1), Vector3(x1, LY - 0.3, c1 + 0.4), "l11_canal_wall", ALL, true)
	# bridge deck + parapets (z-street continues over the canal)
	k.slab(x0 + 4.0, c0, x0 + 16.0, c1, 0.0, 0.9, "l11_asphalt", ALL)
	k.slab(x0, c0, x0 + 4.0, c1, LY, 1.05, "l11_sidewalk", ALL)
	k.slab(x0 + 16.0, c0, x0 + 20.0, c1, LY, 1.05, "l11_sidewalk", ALL)
	for xx in [x0 + 0.15, x0 + 19.85]:
		bmm(Vector3(xx - 0.15, LY, c0), Vector3(xx + 0.15, LY + 1.05, c1), "l11_canal_wall", ALL, true)
	# quay railings with ladder gaps; quay lamps
	for side in [[c0 - 0.1, 1.0], [c1 + 0.1, -1.0]]:
		var z: float = side[0]
		var gap := x0 + (40.0 if side[1] > 0.0 else 60.0)
		for seg in [[x0 + 20.0, gap - 0.6], [gap + 0.6, x1]]:
			bmm(Vector3(seg[0], LY + 1.0, z - 0.05), Vector3(seg[1], LY + 1.08, z + 0.05), "l11_rail_metal", ALL, true)
			bmm(Vector3(seg[0], LY, z - 0.03), Vector3(seg[1], LY + 1.0, z + 0.03), "l11_rail_metal", ALL, false)
		var lad := LadderVolume.new()
		k.root.add_child(lad)
		var zl := z + float(side[1]) * 0.25
		lad.setup(Vector3(gap - 0.5, -3.2, minf(zl, z) - 0.15), Vector3(gap + 0.5, LY + 1.3, maxf(zl, z) + 0.15))
		for y in range(-3, 1):
			stick(Vector3(gap - 0.4, y + 0.2, z + float(side[1]) * 0.12), Vector3(gap + 0.4, y + 0.2, z + float(side[1]) * 0.12), 0.05, "l11_rail_metal")
		for lx in [x0 + 30.0, x0 + 70.0]:
			var lp := Vector3(lx, LY, z - float(side[1]) * 0.6)
			bmm(lp + Vector3(-0.08, 0, -0.08), lp + Vector3(0.08, 4.2, 0.08), "l11_rail_metal", ALL, true)
			k.box(lp + Vector3(0, 4.35, 0), Vector3(0.4, 0.4, 0.4), "l11_lamp", ALL, false)
			lights.append(lp + Vector3(0, 4.0, 0))
	var wv := WaterVolume.new()
	k.root.add_child(wv)
	wv.setup(Vector3(x0, -4.1, c0), Vector3(x1, -1.7, c1), "l11_water", true)
	wv.fog_color = Color(0.02, 0.04, 0.05)
	wv.tint = Color(0.06, 0.12, 0.13)


# ------------------------------------------------------------ set pieces

## Barricade of cars and furniture across a z-street at z, gap on the west sidewalk.
func barricade(x0: float, z: float) -> void:
	for p in [[Vector3(x0 + 4.4, LY - 0.15, z - 1.0), Vector3(x0 + 8.8, 1.45, z + 0.9), "l11_cabinet_blue"],
			[Vector3(x0 + 11.0, LY - 0.15, z - 0.6), Vector3(x0 + 15.4, 1.45, z + 1.3), "l11_paper"],
			[Vector3(x0 + 8.8, 0.0, z - 0.4), Vector3(x0 + 11.0, 0.95, z + 0.6), "l11_fabric"],
			[Vector3(x0 + 15.5, LY, z - 0.4), Vector3(x0 + 17.0, 2.1, z + 0.3), "l11_wood"],
			[Vector3(x0 + 17.0, LY, z - 0.6), Vector3(x0 + 20.0, 1.2, z + 0.6), "l11_crate"],
			[Vector3(x0 + 1.95, LY, z - 0.5), Vector3(x0 + 4.4, 1.3, z + 0.5), "l11_crate"]]:
		bmm(p[0], p[1], p[2], ALL, true)
	for c in [Vector3(x0 + 6.6, 1.45, z), Vector3(x0 + 13.2, 1.45, z + 0.35)]:
		k.box(c + Vector3(0, 0.27, 0), Vector3(2.0, 0.55, 1.5), "l11_dark", ALL, false)
	stick(Vector3(x0 + 9.0, 0.95, z), Vector3(x0 + 10.6, 2.4, z + 0.2), 0.25, "l11_paper")
	bmm(Vector3(x0 + 3.0, 1.3, z - 0.3), Vector3(x0 + 4.0, 2.2, z + 0.3), "l11_crate", ALL, false)


func memorial(c: Vector3) -> void:
	for i in 9:
		var p := c + Vector3(r.randf_range(-1.6, 1.6), 0, r.randf_range(-0.3, 0.3))
		k.box(p + Vector3(0, 0.08, 0), Vector3(0.07, 0.16, 0.07), "l11_candle", ALL, false)
	for i in 6:
		var p := c + Vector3(r.randf_range(-1.8, 1.8), 0, r.randf_range(-0.4, 0.1))
		stick(p, p + Vector3(r.randf_range(-0.2, 0.2), 0.45, -0.1), 0.02, "l11_leaves")
		k.box(p + Vector3(0, 0.48, -0.1), Vector3(0.14, 0.12, 0.14), "l11_flower", ALL, false)
	for i in 3:
		var p := c + Vector3(-1.2 + i * 1.1, 0.0, -0.35)
		k.box_xf(Transform3D(Basis(Vector3.RIGHT, -0.25), p + Vector3(0, 0.25, 0)), Vector3(0.3, 0.4, 0.03), "l11_wood", ALL, false)
		k.box_xf(Transform3D(Basis(Vector3.RIGHT, -0.25), p + Vector3(0, 0.25, 0.02)), Vector3(0.24, 0.32, 0.01), "l11_paper", ALL, false)


## Out-of-place elevator in a wall facing `out` (along = wall direction).
func elevator(c: Vector3, along: Vector3, out: Vector3) -> Vector3:
	bmm(c - along * 1.25 + out * 0.0, c + along * 1.25 + out * 0.12 + Vector3(0, 2.7, 0), "l11_steel", ALL, false)
	bmm(c - along * 1.0 + out * 0.12, c - along * 0.02 + out * 0.15 + Vector3(0, 2.3, 0), "l11_steel", ALL, false)
	bmm(c + along * 0.02 + out * 0.12, c + along * 1.0 + out * 0.15 + Vector3(0, 2.3, 0), "l11_steel", ALL, false)
	bmm(c - along * 1.02 + out * 0.12 + Vector3(0, 2.3, 0), c + along * 1.02 + out * 0.16 + Vector3(0, 2.36, 0), "l11_dark", ALL, false)
	var bp := c + along * 1.6 + Vector3(0, 1.15, 0)
	bmm(bp - along * 0.12 + out * 0.0, bp + along * 0.12 + out * 0.06 + Vector3(0, 0.3, 0), "l11_steel", ALL, false)
	k.box(bp + out * 0.07 + Vector3(0, 0.15, 0), Vector3(0.07, 0.07, 0.07), "l11_button", ALL, false)
	return bp


## Car-shaped static prop (barricades); length along `along`.
func dead_car(c: Vector3, yaw: float, mat: String) -> void:
	var bas := Basis(Vector3.UP, yaw)
	k.box_xf(Transform3D(bas, c + Vector3(0, 0.66, 0)), Vector3(4.4, 0.68, 1.8), mat, ALL, true)
	k.box_xf(Transform3D(bas, c + bas * Vector3(-0.05, 1.27, 0)), Vector3(2.1, 0.55, 1.62), "l11_dark", ALL, false)
