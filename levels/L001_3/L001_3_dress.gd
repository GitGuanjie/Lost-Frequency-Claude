extends RefCounted
## Level 1.3 furnishing: The Ward (M.E.G. field hospital) in the Detox Zones,
## medical supplies and equipment in the other rooms, the M.E.G. checkpoint at the
## south end. In the Decay state the same rooms are abandoned: beds tipped,
## carts and stands down, curtains torn away. Built fixtures (beds, IV stands,
## curtains, carts) are GeoKit boxes; Poly Haven / Kenney CC0 models via Props.

const G := preload("res://levels/L001_3/L001_3_geo.gd")

var lvl
var props := 0
var beds := 0
var decay := false
var cracks: Array = []       # regenerating damage in the White state


func _init(level) -> void:
	lvl = level


func p(parent: Node3D, id: String, pos: Vector3, yaw: float = 0.0, h: float = 0.0, collide: bool = false) -> Node3D:
	var n: Node3D = Props.place(lvl, parent, id, pos, yaw, h, collide)
	if n:
		props += 1
	return n


## Room-local frame: u runs from the door (u = 0) to the far wall (u = 16),
## v along z from the room centre. Returns world position.
static func w(i: int, s: int, u: float, v: float, y: float = 0.0) -> Vector3:
	return Vector3(float(s) * (G.RX0 + u), y, G.pair_z(i) + v)


## Yaw (degrees) that turns a +Z-facing model to face local direction (du, dv).
static func yaw_to(s: int, du: float, dv: float) -> float:
	return rad_to_deg(atan2(float(s) * du, dv))


func _tilt(r: RandomNumberGenerator, amount: float) -> Basis:
	if not decay:
		return Basis()
	return Basis(Vector3.UP, r.randf_range(-amount, amount))


# ------------------------------------------------------------------ fixtures

## Hospital bed, head at local -Z of `b`, foot toward +Z. Tipped in Decay.
func bed(k: GeoKit, pos: Vector3, b: Basis, r: RandomNumberGenerator) -> void:
	var bb := b * _tilt(r, 0.5)
	var lift := 0.0
	if decay and r.randf() < 0.35:
		bb = bb * Basis(Vector3(0, 0, 1), PI * 0.5 * (1.0 if r.randf() < 0.5 else -1.0))
		lift = 0.0
		pos += Vector3(0, 0.48, 0)
	var at := func(o: Vector3) -> Vector3: return pos + bb * o + Vector3(0, lift, 0)
	k.box_xf(Transform3D(bb, at.call(Vector3(0, 0.42, 0))), Vector3(0.92, 0.1, 2.05), "l13_steel", GeoKit.ALL, not decay)
	k.box_xf(Transform3D(bb, at.call(Vector3(0, 0.55, 0.02))), Vector3(0.88, 0.16, 1.95), "l13_linen", GeoKit.ALL, false)
	k.box_xf(Transform3D(bb, at.call(Vector3(0, 0.66, -0.72))), Vector3(0.6, 0.1, 0.38), "l13_linen", GeoKit.ALL, false)
	if not decay or r.randf() < 0.5:
		k.box_xf(Transform3D(bb, at.call(Vector3(0, 0.645, 0.38))), Vector3(0.9, 0.04, 1.2), "l13_blanket", GeoKit.ALL, false)
	k.box_xf(Transform3D(bb, at.call(Vector3(0, 0.8, -1.02))), Vector3(0.94, 0.8, 0.05), "l13_bedframe", GeoKit.ALL, false)
	k.box_xf(Transform3D(bb, at.call(Vector3(0, 0.62, 1.02))), Vector3(0.94, 0.45, 0.04), "l13_bedframe", GeoKit.ALL, false)
	for sx: float in [-0.47, 0.47]:
		k.box_xf(Transform3D(bb, at.call(Vector3(sx, 0.78, -0.2))), Vector3(0.03, 0.2, 0.9), "l13_steel", GeoKit.ALL, false)
		for sz: float in [-0.9, 0.9]:
			k.box_xf(Transform3D(bb, at.call(Vector3(sx * 0.9, 0.2, sz))), Vector3(0.04, 0.36, 0.04), "l13_steel", GeoKit.ALL, false)
			k.box_xf(Transform3D(bb, at.call(Vector3(sx * 0.9, 0.05, sz))), Vector3(0.05, 0.1, 0.1), "l13_rubber", GeoKit.ALL, false)
	beds += 1


func iv_stand(k: GeoKit, pos: Vector3, r: RandomNumberGenerator) -> void:
	var b := Basis()
	var base := pos
	if decay and r.randf() < 0.5:
		b = Basis(Vector3.UP, r.randf() * TAU) * Basis(Vector3.RIGHT, PI * 0.47)
		base = pos + Vector3(0, 0.05, 0)
	k.box_xf(Transform3D(b, base + b * Vector3(0, 0.95, 0)), Vector3(0.025, 1.9, 0.025), "l13_steel", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, base + b * Vector3(0, 0.03, 0)), Vector3(0.5, 0.03, 0.04), "l13_steel", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, base + b * Vector3(0, 0.03, 0)), Vector3(0.04, 0.03, 0.5), "l13_steel", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, base + b * Vector3(0, 1.88, 0)), Vector3(0.3, 0.02, 0.02), "l13_steel", GeoKit.ALL, false)
	if not decay:
		k.box_xf(Transform3D(b, base + b * Vector3(0.12, 1.72, 0)), Vector3(0.1, 0.18, 0.04), "l13_ivbag", GeoKit.ALL, false)


## Cubicle curtain hung from a ceiling track: pleated fabric panels.
func curtain(k: GeoKit, a: Vector3, bpt: Vector3, ceil_y: float, r: RandomNumberGenerator) -> void:
	var d := bpt - a
	var L := d.length()
	var dn := d / L
	var bas := Basis(dn, Vector3.UP, dn.cross(Vector3.UP))
	var top := 2.4
	k.box_xf(Transform3D(bas, (a + bpt) * 0.5 + Vector3(0, top + 0.03, 0)), Vector3(L, 0.03, 0.05), "l13_steel", GeoKit.ALL, false)
	for t: float in [0.1, 0.9]:
		k.box(a + d * t + Vector3(0, (top + ceil_y) * 0.5, 0), Vector3(0.02, ceil_y - top, 0.02), "l13_steel", GeoKit.ALL, false)
	var drawn := r.randf_range(0.4, 1.0)
	if decay:
		drawn = r.randf_range(0.0, 0.4)
	var n := int(L * drawn / 0.18)
	var nrm := dn.cross(Vector3.UP)
	for i in n:
		var c := a + dn * (0.09 + i * 0.18) + nrm * (0.05 if i % 2 == 0 else -0.05) + Vector3(0, top - 1.0, 0)
		k.box_xf(Transform3D(bas * Basis(Vector3.UP, 0.5 if i % 2 == 0 else -0.5), c), Vector3(0.2, 2.0 - (r.randf_range(0.0, 0.9) if decay else 0.0), 0.012), "l13_curtain", GeoKit.ALL, false)


func cart(k: GeoKit, pos: Vector3, yaw: float, r: RandomNumberGenerator) -> void:
	var b := Basis(Vector3.UP, deg_to_rad(yaw)) * _tilt(r, 0.6)
	var c := pos
	if decay and r.randf() < 0.4:
		b = b * Basis(Vector3(1, 0, 0), PI * 0.5)
		c = pos + Vector3(0, -0.2, 0)
	k.box_xf(Transform3D(b, c + b * Vector3(0, 0.5, 0)), Vector3(0.62, 0.8, 0.46), "l13_cart", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, c + b * Vector3(0, 0.92, 0)), Vector3(0.66, 0.03, 0.5), "l13_steel", GeoKit.ALL, false)
	for i in 3:
		k.box_xf(Transform3D(b, c + b * Vector3(0, 0.28 + i * 0.24, 0.235)), Vector3(0.5, 0.012, 0.01), "l13_steel", GeoKit.ALL, false)


func monitor(k: GeoKit, pos: Vector3, yaw: float) -> void:
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	k.box(pos + Vector3(0, 0.7, 0), Vector3(0.04, 1.4, 0.04), "l13_steel", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, pos + Vector3(0, 1.5, 0)), Vector3(0.38, 0.3, 0.1), "l13_bedframe", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, pos + Vector3(0, 1.5, 0) + b * Vector3(0, 0, 0.052)), Vector3(0.32, 0.22, 0.004), "l13_screen_dead" if decay else "l13_screen", GeoKit.ALL, false)


## A built steel rack (uprights and four shelves) along local axis `along`.
func rack(k: GeoKit, node: Node3D, c: Vector3, along: Vector3, L: float, r: RandomNumberGenerator) -> void:
	var bas := Basis(along, Vector3.UP, along.cross(Vector3.UP))
	var tb := bas * _tilt(r, 0.15)
	for t: float in [-0.5, 0.5]:
		for sd: float in [-0.25, 0.25]:
			k.box_xf(Transform3D(tb, c + tb * Vector3(t * L, 1.0, sd)), Vector3(0.04, 2.0, 0.04), "l13_steel", GeoKit.ALL, false)
	for lv: float in [0.12, 0.7, 1.28, 1.86]:
		k.box_xf(Transform3D(tb, c + tb * Vector3(0, lv, 0)), Vector3(L, 0.025, 0.55), "l13_steel", GeoKit.ALL, false)
		var x := -L * 0.5 + 0.3
		while x < L * 0.5 - 0.25:
			var roll := r.randf()
			var pp := c + tb * Vector3(x, lv + 0.013, r.randf_range(-0.08, 0.08))
			if decay and r.randf() < 0.45:
				pass
			elif roll < 0.18:
				p(node, "ph/medical_box", pp, rad_to_deg(atan2(along.x, along.z)) + r.randf_range(-10, 10))
				x += 0.55
				continue
			elif roll < 0.3:
				p(node, "ph/plastic_bottle_gallon", pp, r.randf() * 360.0)
			elif roll < 0.7:
				var sz := Vector3(r.randf_range(0.25, 0.45), r.randf_range(0.18, 0.4), r.randf_range(0.25, 0.4))
				k.box_xf(Transform3D(tb * Basis(Vector3.UP, r.randf_range(-0.2, 0.2)), pp + Vector3(0, sz.y * 0.5, 0)), sz, "l13_box_white" if r.randf() < 0.6 else "l13_cardboard", GeoKit.ALL, false)
			x += r.randf_range(0.35, 0.6)
	k.box_xf(Transform3D(tb, c + tb * Vector3(0, 1.0, 0)), Vector3(L, 2.0, 0.55), "l13_box_white", 0, true)
	if decay and r.randf() < 0.6:
		for n in r.randi_range(2, 4):
			var fp := c + bas * Vector3(r.randf_range(-L * 0.5, L * 0.5), 0, r.randf_range(0.5, 1.2) * (1.0 if r.randf() < 0.5 else -1.0))
			k.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * TAU), fp + Vector3(0, 0.15, 0)), Vector3(0.4, 0.3, 0.32), "l13_box_white", GeoKit.ALL, false)


func sign_plate(node: Node3D, k: GeoKit, pos: Vector3, yaw_rad: float, text: String) -> void:
	var b := Basis(Vector3.UP, yaw_rad)
	k.box_xf(Transform3D(b, pos), Vector3(2.4, 0.42, 0.03), "l13_sign", GeoKit.ALL, false)
	var lb := Label3D.new()
	lb.text = text
	lb.font_size = 44
	lb.pixel_size = 0.0045
	lb.modulate = Color(0.92, 0.94, 0.95) if not decay else Color(0.5, 0.5, 0.5)
	lb.outline_size = 0
	lb.double_sided = false
	lb.shaded = true
	lb.transform = Transform3D(b, pos + b * Vector3(0, 0, 0.02))
	node.add_child(lb)


# ------------------------------------------------------------------ rooms

func room(node: Node3D, k: GeoKit, rec: Dictionary, r: RandomNumberGenerator) -> void:
	var i: int = rec["i"]
	var s: int = rec["s"]
	match rec["type"]:
		"detox": _detox(node, k, i, s, r)
		"supplies": _supplies(node, k, i, s, r)
		"surgery": _surgery(node, k, i, s, r)
		"admissions": _admissions(node, k, i, s, r)
		"staff": _staff(node, k, i, s, r)
		"pharmacy": _pharmacy(node, k, i, s, r)
	var label := {"detox": "THE WARD  ·  DETOX ZONE %d" % rec["zone"], "supplies": "MEDICAL SUPPLIES", "surgery": "SURGERY",
		"admissions": "M.E.G.  ·  ADMISSIONS", "staff": "STAFF ONLY", "pharmacy": "PHARMACY"}
	var zc := G.pair_z(i)
	sign_plate(node, k, Vector3(float(s) * (G.HWD - 0.02), 3.28, zc), -PI * 0.5 * float(s), label[rec["type"]])


func _detox(node: Node3D, k: GeoKit, i: int, s: int, r: RandomNumberGenerator) -> void:
	# The Ward around the zone: beds head-to-wall on both long walls and the far wall
	for vs: float in [-1.0, 1.0]:
		var u := 2.2
		while u < 15.0:
			var head := w(i, s, u, vs * (G.RD - 0.15))
			var b := Basis(Vector3.UP, PI if vs > 0 else 0.0)
			bed(k, head + Vector3(0, 0, -vs * 1.05), b, r)
			iv_stand(k, w(i, s, u + 0.62, vs * (G.RD - 0.45)), r)
			k.box(w(i, s, u, vs * (G.RD - 0.02), 1.45), Vector3(1.4, 0.32, 0.04), "l13_cart", GeoKit.ALL, false)
			for q in 3:
				k.box(w(i, s, u - 0.4 + q * 0.4, vs * (G.RD - 0.05), 1.45), Vector3(0.12, 0.12, 0.03), "l13_tape" if q == 0 else ("l13_pad" if q == 1 else "l13_steel"), GeoKit.ALL, false)
			if r.randf() < 0.5:
				monitor(k, w(i, s, u - 0.62, vs * (G.RD - 0.35)), yaw_to(s, 0, -vs))
			if u + 1.3 < 15.0:
				curtain(k, w(i, s, u + 1.3, vs * (G.RD - 0.05)), w(i, s, u + 1.3, vs * (G.RD - 2.3)), G.RH, r)
			if r.randf() < 0.35:
				cart(k, w(i, s, u + 0.9, vs * (G.RD - 2.55)), yaw_to(s, 0, -vs), r)
			u += 2.6
	for v: float in [-4.5, 0.0, 4.5]:
		var head := w(i, s, 15.85, v)
		bed(k, head + Vector3(-float(s) * 1.05, 0, 0), Basis(Vector3.UP, -PI * 0.5 * float(s)), r)
		iv_stand(k, w(i, s, 15.6, v + 0.65), r)
	# near the door: a nurses' station
	var st := w(i, s, 1.9, -5.3)
	k.box_xf(Transform3D(Basis(), st + Vector3(0, 0.5, 0)), Vector3(1.0, 1.0, 2.2), "l13_cart", GeoKit.ALL, true)
	k.box(st + Vector3(0, 1.02, 0), Vector3(1.1, 0.04, 2.3), "l13_counter", GeoKit.ALL, false)
	p(node, "ph/classic_laptop", st + Vector3(0, 1.04, -0.5), yaw_to(s, 1, 0) + 180.0, 0.3)
	p(node, "ph/clipboard", st + Vector3(0.1, 1.04, 0.4), r.randf() * 40.0)
	p(node, "ph/medical_box", st + Vector3(-0.1, 1.04, 0.85), 10.0)
	p(node, "kenney/furniture-kit/chairdesk", w(i, s, 0.75, -5.0), yaw_to(s, 1, 0) + (r.randf_range(-60, 60) if decay else 0.0), 1.0)
	p(node, "ph/wall_clock", w(i, s, 0.17, 4.0, 2.6), yaw_to(s, 1, 0))
	p(node, "kenney/furniture-kit/trashcan", w(i, s, 0.6, 6.5), 0.0, 0.6)


func _supplies(node: Node3D, k: GeoKit, i: int, s: int, r: RandomNumberGenerator) -> void:
	var ax := Vector3(float(s), 0, 0)
	for v: float in [-5.2, -1.9, 2.4, 5.6]:
		rack(k, node, w(i, s, 6.8, v), ax, 6.0, r)
	# under and on the mezzanine
	for v: float in [-6.0, -2.0, 2.0, 6.0]:
		rack(k, node, w(i, s, 15.6, v), Vector3(0, 0, 1), 3.0, r)
		rack(k, node, w(i, s, 15.6, v, G.MEZ_Y), Vector3(0, 0, 1), 3.0, r)
	p(node, "ph/hand_truck", w(i, s, 2.5, 3.5), yaw_to(s, 1, 0.4) + (70.0 if decay else 0.0))
	p(node, "ph/wooden_crate_01", w(i, s, 2.4, -7.6), 15.0, 0.0, true)
	p(node, "ph/old_military_crate", w(i, s, 4.0, 7.9), 0.0, 0.0, true)
	p(node, "ph/plastic_crate_01", w(i, s, 1.4, 7.8), r.randf() * 360.0)
	p(node, "ph/metal_office_desk", w(i, s, 13.5, 6.8, G.MEZ_Y), yaw_to(s, -1, 0), 0.0, true)
	p(node, "ph/binder_notebook", w(i, s, 13.4, 6.8, G.MEZ_Y + 0.79), r.randf() * 360.0)
	p(node, "ph/clipboard", w(i, s, 13.6, 6.3, G.MEZ_Y + 0.79), r.randf() * 360.0)


func _surgery(node: Node3D, k: GeoKit, i: int, s: int, r: RandomNumberGenerator) -> void:
	var grp := "k%d" % int(floor(G.pair_z(i) / G.S))
	for v0: float in [-3.6, 3.6]:
		var c := w(i, s, 6.2, v0)
		var tb := Basis(Vector3.UP, PI * 0.5) * _tilt(r, 0.4)
		k.box_xf(Transform3D(tb, c + Vector3(0, 0.4, 0)), Vector3(0.5, 0.8, 0.8), "l13_steel", GeoKit.ALL, true)
		k.box_xf(Transform3D(tb, c + Vector3(0, 0.86, 0)), Vector3(0.62, 0.1, 2.0), "l13_steel", GeoKit.ALL, false)
		k.box_xf(Transform3D(tb, c + Vector3(0, 0.95, 0)), Vector3(0.56, 0.08, 1.9), "l13_pad", GeoKit.ALL, false)
		if not decay:
			k.box_xf(Transform3D(tb, c + Vector3(0, 1.0, 0.25)), Vector3(0.58, 0.02, 1.0), "l13_drape", GeoKit.ALL, false)
		for du: float in [-0.6, 0.6]:
			p(node, "ph/modern_ceiling_lamp_01", c + Vector3(float(s) * du, G.RH - 1.6, 0), 0.0, 1.6)
		lvl.lights.add_anchor(c + Vector3(0, 2.6, 0), Color(1.0, 1.0, 0.97), 1.8 if not decay else 0.0, 5.0, 0.0, grp)
		monitor(k, w(i, s, 7.4, v0 - 1.4), yaw_to(s, -0.5, 1))
		cart(k, w(i, s, 5.0, v0 + 1.3), yaw_to(s, 1, 0), r)
		cart(k, w(i, s, 7.6, v0 + 1.3), yaw_to(s, -1, 0), r)
		iv_stand(k, w(i, s, 5.2, v0 - 1.2), r)
		# anaesthesia trolley: a tall cabinet with gauges and a screen
		var an := w(i, s, 4.6, v0 - 0.9)
		k.box(an + Vector3(0, 0.7, 0), Vector3(0.6, 1.4, 0.55), "l13_cart", GeoKit.ALL, true)
		k.box(an + Vector3(0, 1.45, 0), Vector3(0.55, 0.1, 0.5), "l13_steel", GeoKit.ALL, false)
		monitor(k, an + Vector3(0, 0.2, 0), yaw_to(s, 1, 0))
	for u: float in [5.0, 6.3, 7.6, 8.9, 10.2]:
		p(node, "ph/drawer_cabinet", w(i, s, u, G.RD - 0.3), 180.0, 1.6, true)
	# glass-fronted instrument cabinets on the door wall
	for v: float in [-7.4, -5.6, 5.6]:
		var gc := w(i, s, 0.35, v, 1.1)
		k.box(gc, Vector3(0.4, 2.0, 1.6), "l13_cart", GeoKit.ALL, true)
		k.box(gc + Vector3(float(s) * 0.205, 0.0, 0), Vector3(0.01, 1.8, 1.45), "l13_glass", GeoKit.ALL, false)
		for lv: float in [-0.5, 0.0, 0.5]:
			k.box(gc + Vector3(float(s) * 0.05, lv, 0), Vector3(0.3, 0.02, 1.5), "l13_steel", GeoKit.ALL, false)
			for q in 4:
				k.box(gc + Vector3(float(s) * 0.05, lv + 0.08, -0.55 + q * 0.36 + r.randf_range(-0.05, 0.05)), Vector3(0.18, 0.14, 0.16), "l13_box_white", GeoKit.ALL, false)
	for u: float in [1.5, 2.6]:
		p(node, "kenney/furniture-kit/bathroomsink", w(i, s, u, G.RD - 0.3), 180.0, 0.9)
	p(node, "ph/propane_tank", w(i, s, 9.6, 1.0), 0.0)
	p(node, "ph/propane_tank", w(i, s, 9.9, 0.6), 0.0)
	# observation deck on the mezzanine
	for v: float in [-3.0, -1.0, 1.0, 3.0]:
		p(node, "ph/plastic_monobloc_chair_01", w(i, s, 12.2, v, G.MEZ_Y), yaw_to(s, -1, 0) + (r.randf_range(-90, 90) if decay else 0.0))
	p(node, "ph/metal_office_desk", w(i, s, 14.8, 5.5, G.MEZ_Y), yaw_to(s, -1, 0), 0.0, true)
	p(node, "ph/classic_laptop", w(i, s, 14.8, 5.4, G.MEZ_Y + 0.79), yaw_to(s, -1, 0), 0.3)


func _admissions(node: Node3D, k: GeoKit, i: int, s: int, r: RandomNumberGenerator) -> void:
	# triage counter across the room; the M.E.G. decides who goes in first
	var bas := Basis(Vector3(0, 0, 1), Vector3.UP, Vector3(-float(s), 0, 0))
	for seg in [[-6.0, -1.2], [1.2, 6.0]]:
		var a: float = seg[0]
		var b: float = seg[1]
		k.box_xf(Transform3D(bas, w(i, s, 5.0, (a + b) * 0.5, 0.55)), Vector3(b - a, 1.1, 0.6), "l13_cart", GeoKit.ALL, true)
		k.box_xf(Transform3D(bas, w(i, s, 5.0, (a + b) * 0.5, 1.12)), Vector3(b - a + 0.1, 0.04, 0.7), "l13_counter", GeoKit.ALL, false)
	for v: float in [-4.0, -2.0, 2.0, 4.0]:
		p(node, "ph/classic_laptop", w(i, s, 5.05, v, 1.14), yaw_to(s, -1, 0), 0.3)
		p(node, "kenney/furniture-kit/chairdesk", w(i, s, 6.0, v), yaw_to(s, -1, 0) + (r.randf_range(-70, 70) if decay else 0.0), 1.0)
	for u: float in [9.0, 10.5, 12.0, 13.5]:
		p(node, "ph/drawer_cabinet", w(i, s, u, -G.RD + 0.3), 0.0, 1.5, true)
	for row in 3:
		for n in 6:
			var u2 := 1.5 + row * 1.2
			p(node, "ph/plastic_monobloc_chair_01", w(i, s, u2, -6.5 + n * 0.75 if n < 3 else 4.2 + (n - 3) * 0.75), yaw_to(s, 1, 0) + (r.randf_range(-120, 120) if decay else 0.0))
	p(node, "ph/metal_office_desk", w(i, s, 11.5, 3.0), yaw_to(s, -1, 0), 0.0, true)
	p(node, "ph/vintage_radio_transceiver", w(i, s, 11.4, 3.3, 0.79), yaw_to(s, -1, 0))
	p(node, "ph/clipboard", w(i, s, 11.6, 2.5, 0.79), 30.0)
	p(node, "ph/security_camera_01", w(i, s, 0.35, 8.6, 4.4), yaw_to(s, 1, -1))


func _staff(node: Node3D, k: GeoKit, i: int, s: int, r: RandomNumberGenerator) -> void:
	for vs: float in [-1.0, 1.0]:
		for u: float in [3.0, 6.0, 9.0, 12.0]:
			p(node, "kenney/furniture-kit/bedbunk", w(i, s, u, vs * (G.RD - 1.15)), (0.0 if vs < 0 else 180.0) + (r.randf_range(-25, 25) if decay else 0.0), 1.85, true)
	for v: float in [-4.5, -3.6, -2.7, -1.8, 1.8, 2.7, 3.6, 4.5]:
		k.box(w(i, s, 15.75, v, 0.95), Vector3(0.5, 1.9, 0.86), "l13_locker", GeoKit.ALL, true)
	p(node, "ph/dining_table", w(i, s, 8.0, 0.0), yaw_to(s, 1, 0), 0.0, true)
	for n in 6:
		var dv := -0.8 + (n % 3) * 0.8
		var du := -0.75 if n < 3 else 0.75
		p(node, "ph/dining_chair_02", w(i, s, 8.0 + du, dv), yaw_to(s, -du, 0) + (r.randf_range(-80, 80) if decay else 0.0))
	p(node, "kenney/furniture-kit/kitchenfridge", w(i, s, 0.6, -6.0), yaw_to(s, 1, 0), 1.8, true)
	p(node, "kenney/furniture-kit/kitchencabinet", w(i, s, 0.55, -4.9), yaw_to(s, 1, 0), 0.9, true)
	p(node, "kenney/furniture-kit/kitchencoffeemachine", w(i, s, 0.55, -4.9, 0.9), yaw_to(s, 1, 0), 0.35)
	p(node, "ph/Sofa_01", w(i, s, 4.5, 5.6), yaw_to(s, 0, -1), 0.0, true)


func _pharmacy(node: Node3D, k: GeoKit, i: int, s: int, r: RandomNumberGenerator) -> void:
	var bas := Basis(Vector3(0, 0, 1), Vector3.UP, Vector3(-float(s), 0, 0))
	k.box_xf(Transform3D(bas, w(i, s, 4.0, 0.0, 0.5)), Vector3(9.0, 1.0, 0.6), "l13_cart", GeoKit.ALL, true)
	k.box_xf(Transform3D(bas, w(i, s, 4.0, 0.0, 1.02)), Vector3(9.1, 0.04, 0.7), "l13_counter", GeoKit.ALL, false)
	for vs: float in [-1.0, 1.0]:
		for u: float in [6.5, 9.0, 11.5, 14.0]:
			rack(k, node, w(i, s, u, vs * (G.RD - 0.35)), Vector3(float(s), 0, 0), 2.2, r)
	for v: float in [-3.0, 0.0, 3.0]:
		rack(k, node, w(i, s, 15.7, v), Vector3(0, 0, 1), 2.6, r)
	p(node, "ph/CashRegister_01", w(i, s, 4.0, 2.0, 1.04), yaw_to(s, -1, 0), 0.0)
	p(node, "ph/stationery_supplies", w(i, s, 4.0, -1.5, 1.04), 0.0)
	p(node, "ph/medical_box", w(i, s, 4.05, 0.4, 1.04), 20.0)


# ------------------------------------------------------------------ hallway

func hallway(node: Node3D, k: GeoKit, i: int, r: RandomNumberGenerator) -> void:
	var zc := G.pair_z(i)
	# parked gurneys (yellow pads), benches, sanitiser stations, extinguishers
	for n in r.randi_range(1, 2):
		var sx := 1.0 if r.randf() < 0.5 else -1.0
		var z := zc + (r.randf_range(4.0, 9.5) if n == 0 and i > 0 else -r.randf_range(4.0, 9.5))
		var b := Basis(Vector3.UP, (r.randf_range(-0.6, 0.6) if decay else 0.0))
		_gurney(k, Vector3(sx * (G.HWD - 0.55), 0, z), b, r)
	var bz := zc + (6.5 if r.randf() < 0.5 and i > 0 else -6.5)
	var bs := -1.0 if r.randf() < 0.5 else 1.0
	p(node, "kenney/furniture-kit/bench", Vector3(bs * (G.HWD - 0.3), 0, bz), -90.0 * bs + (r.randf_range(-40, 40) if decay else 0.0), 0.5)
	for sx: float in [-1.0, 1.0]:
		k.box(Vector3(sx * (G.HWD - 0.05), 1.3, zc + 2.4), Vector3(0.08, 0.24, 0.13), "l13_cart", GeoKit.ALL, false)
		k.box(Vector3(sx * (G.HWD - 0.1), 1.21, zc + 2.4), Vector3(0.02, 0.04, 0.03), "l13_steel", GeoKit.ALL, false)
	p(node, "ph/korean_fire_extinguisher_01", Vector3(-(G.HWD - 0.2), 0, zc - 3.2), 90.0)
	p(node, "ph/fire_alarm", Vector3(G.HWD - 0.02, 1.4, zc - 3.0), -90.0)
	p(node, "ph/wall_clock", Vector3(-(G.HWD - 0.03), 2.6, zc + 8.0), 90.0)
	if not decay:
		_crack(node, Vector3(r.randf_range(-1.5, 1.5), 0.004, zc + r.randf_range(-8.0, 8.0)), r)


func _gurney(k: GeoKit, pos: Vector3, b: Basis, r: RandomNumberGenerator) -> void:
	k.box_xf(Transform3D(b, pos + Vector3(0, 0.7, 0)), Vector3(0.62, 0.06, 1.95), "l13_steel", GeoKit.ALL, true)
	k.box_xf(Transform3D(b, pos + Vector3(0, 0.78, 0)), Vector3(0.58, 0.1, 1.9), "l13_gurney_pad", GeoKit.ALL, false)
	if decay and r.randf() < 0.6:
		k.box_xf(Transform3D(b, pos + Vector3(0.05, 0.84, 0.3)), Vector3(0.3, 0.004, 0.7), "l13_blood", GeoKit.ALL, false)
	for sx: float in [-0.26, 0.26]:
		for sz: float in [-0.85, 0.85]:
			k.box_xf(Transform3D(b, pos + b * Vector3(sx, 0.36, sz)), Vector3(0.035, 0.68, 0.035), "l13_steel", GeoKit.ALL, false)


## Damage in the floor tile that regenerates while you watch (White state).
func _crack(node: Node3D, pos: Vector3, r: RandomNumberGenerator) -> void:
	var holder := Node3D.new()
	holder.position = pos
	node.add_child(holder)
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.25, 0.26, 0.27, 0.9)
	mat.roughness = 0.9
	var ang := r.randf() * TAU
	var c := Vector3.ZERO
	for n in 7:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var L := r.randf_range(0.15, 0.45)
		bm.size = Vector3(0.012, 0.002, L)
		mi.mesh = bm
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ang += r.randf_range(-0.9, 0.9)
		var d := Vector3(sin(ang), 0, cos(ang))
		mi.transform = Transform3D(Basis(Vector3.UP, ang), c + d * L * 0.5)
		holder.add_child(mi)
		c += d * L
		if n == 3:
			c = Vector3.ZERO
			ang += PI
	cracks.append({"node": holder, "mat": mat, "heal": 1.0})
