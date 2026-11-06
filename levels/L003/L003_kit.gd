extends RefCounted
## Level 3 props (GeoKit only), shaped from the page's wording (dossier L003.md).
const U := Vector3(0, 1, 0)


static func frame(d: Vector3) -> Basis:
	var f := Vector3(d.x, 0.0, d.z).normalized()
	return Basis(U.cross(f).normalized(), U, f)


static func pipe(k: GeoKit, a: Vector3, b: Vector3, r: float, mat: String, sides: int = 8) -> void:
	var ax := b - a
	var ln := ax.length()
	if ln < 0.01:
		return
	var d := ax / ln
	var u := d.cross(U if absf(d.y) < 0.9 else Vector3.RIGHT).normalized()
	var v := d.cross(u).normalized()
	var sf: Dictionary = k._s(mat)
	for i in sides:
		var t0 := TAU * float(i) / sides
		var t1 := TAU * float(i + 1) / sides
		var n0 := u * cos(t0) + v * sin(t0)
		var n1 := u * cos(t1) + v * sin(t1)
		var vs := [a + n0 * r, a + n1 * r, b + n1 * r, b + n0 * r]
		var ns := [n0, n1, n1, n0]
		var uvs := [Vector2(t0 * r, 0.0), Vector2(t1 * r, 0.0), Vector2(t1 * r, ln), Vector2(t0 * r, ln)]
		var base: int = sf["v"].size()
		for q in 4:
			sf["v"].append(vs[q])
			sf["n"].append(ns[q])
			sf["uv"].append(uvs[q])
			sf["uv2"].append(Vector2.ZERO)
		if ((vs[1] as Vector3) - (vs[0] as Vector3)).cross((vs[2] as Vector3) - (vs[0] as Vector3)).dot(n0 + n1) > 0.0:
			sf["i"].append_array([base, base + 2, base + 1, base, base + 3, base + 2])
		else:
			sf["i"].append_array([base, base + 1, base + 2, base, base + 2, base + 3])
	k.stats["tris"] += sides * 2


static func obox(k: GeoKit, c: Vector3, d: Vector3, s: Vector3, mat: String, collide: bool = false) -> void:
	k.box_xf(Transform3D(frame(d), c), s, mat, GeoKit.ALL, collide)


static func label(parent: Node3D, text: String, pos: Vector3, out: Vector3, px: int, col: Color, pix: float = 0.004) -> Label3D:
	var lb := Label3D.new()
	lb.text = text
	lb.font_size = px
	lb.pixel_size = pix
	lb.modulate = col
	lb.outline_size = 0
	lb.position = pos + out * 0.012
	lb.rotation.y = atan2(out.x, out.z)
	parent.add_child(lb)
	return lb


## Painted M.E.G. sign plate with text (out = facing direction).
static func sign(k: GeoKit, text: String, pos: Vector3, out: Vector3, w: float, h: float, plate: String = "l3_sign_yellow", ink := Color("14120d"), px: int = 40) -> void:
	obox(k, pos, out, Vector3(w, h, 0.02), plate)
	label(k.root, text, pos + out * 0.011, out, px, ink, 0.0032)


## Corridor a->b: floor, ceiling, both walls (openings [{at,w,h,sill}] from a).
static func hall(k: GeoKit, a: Vector3, b: Vector3, w: float, h: float, wall: String, ops_l: Array = [], ops_r: Array = [], floor_mat: String = "l3_floor", ceil_mat: String = "l3_ceiling") -> void:
	var d := b - a
	d.y = 0.0
	var ln := d.length()
	var f := d / ln
	var side := U.cross(f).normalized()   # left of travel
	var bas := Basis(side, U, f)
	var mid := (a + b) * 0.5
	k.box_xf(Transform3D(bas, mid + Vector3.DOWN * 0.15), Vector3(w + 0.6, 0.3, ln), floor_mat)
	k.box_xf(Transform3D(bas, mid + U * (h + 0.15)), Vector3(w + 0.6, 0.3, ln), ceil_mat)
	var off := side * (w * 0.5 + 0.15)
	k.wall(a + off, b + off, h, 0.3, wall, ops_l)
	k.wall(a - off, b - off, h, 0.3, wall, ops_r)


## Indestructible bars a->b; rods run into the walls (page). One collider: no passing, no noclip.
static func bars(k: GeoKit, a: Vector3, b: Vector3, h: float, gate: bool = false, ext: float = 0.18) -> void:
	var d := b - a
	d.y = 0.0
	var ln := d.length()
	var f := d / ln
	var n := U.cross(f).normalized()
	var x := -ext
	while x <= ln + ext + 0.001:
		var p := a + f * x
		pipe(k, p + Vector3.DOWN * 0.05, p + U * (h + 0.05), 0.019, "l3_bars", 6)
		x += 0.125
	for y: float in [0.14, h * 0.52, h - 0.12]:
		obox(k, (a + b) * 0.5 + U * y, n, Vector3(ln + ext * 2.0, 0.06, 0.03), "l3_bars")
	if gate:
		var gc := (a + b) * 0.5
		for s: float in [-0.47, 0.47]:
			obox(k, gc + f * s + U * (h * 0.5), n, Vector3(0.06, h, 0.06), "l3_bars")
		obox(k, gc + f * 0.32 + n * 0.05 + U * 1.05, n, Vector3(0.16, 0.22, 0.09), "l3_lockbox")
	k.box_xf(Transform3D(frame(f), (a + b) * 0.5 + U * (h * 0.5)), Vector3(0.1, h + 0.1, ln + ext * 2.0), "l3_bars", 0, true, "metal")


## Fluorescent batten; tube quads go in kit lk. Returns the light anchor position.
static func batten(k: GeoKit, lk: GeoKit, pos: Vector3, along: Vector3, tube: String, seed_v: float = 0.0, flick: float = 0.0, hang: float = 0.0) -> Vector3:
	var b := frame(along)
	var c := pos + Vector3.DOWN * (hang + 0.05)
	if hang > 0.01:
		for s: float in [-0.45, 0.45]:
			pipe(k, pos + b.z * s, c + b.z * s + U * 0.05, 0.006, "l3_cable", 4)
	k.box_xf(Transform3D(b, c), Vector3(0.24, 0.07, 1.25), "l3_fixture", GeoKit.ALL, false)
	for s: float in [-0.055, 0.055]:
		lk.quad(c + b.x * s + Vector3.DOWN * 0.036, Vector3.DOWN, b.x * 0.025, b.z * 0.58, tube, Vector2(seed_v, flick), true)
	return c + Vector3.DOWN * 0.3


## Wall dressing a->b (out = into the hall): conduits, sagging cables, boxes, cabinets, motors, black pipe.
static func wall_dress(k: GeoKit, r: RandomNumberGenerator, a: Vector3, b: Vector3, out: Vector3, top: float, sludge_pipe: bool = true, density: float = 1.0) -> void:
	var d := b - a
	d.y = 0.0
	var ln := d.length()
	if ln < 0.8:
		return
	var f := d / ln
	var cy := top - r.randf_range(0.25, 0.45)
	for i in 2 + r.randi() % 2:
		var y := cy - i * 0.07
		pipe(k, a + out * (0.04 + i * 0.012) + U * y, b + out * (0.04 + i * 0.012) + U * y, 0.016 + 0.006 * (i % 2), ["l3_conduit", "l3_cable", "l3_conduit_grey"][i % 3], 5)
	for cb in 1 + r.randi() % 3:
		var sag := r.randf_range(0.08, 0.32)
		var spans := maxi(1, int(ln / r.randf_range(1.4, 2.4)))
		var n := spans * 4
		var y0 := cy - 0.15 - cb * 0.09
		var prev := a + out * (0.06 + cb * 0.025) + U * y0
		for i in range(1, n + 1):
			var t := float(i) / n
			var u := fmod(t * spans, 1.0) if i < n else 0.0
			var cur := a + f * (ln * t) + out * (0.06 + cb * 0.025) + U * (y0 - sag * 4.0 * u * (1.0 - u))
			pipe(k, prev, cur, 0.018 + 0.008 * (cb % 2), "l3_cable", 5)
			prev = cur
	if sludge_pipe:
		var py := r.randf_range(0.3, 0.55) if r.randf() < 0.55 else cy - r.randf_range(0.55, 0.8)
		var pr := r.randf_range(0.07, 0.12)
		pipe(k, a + out * (pr + 0.06) + U * py, b + out * (pr + 0.06) + U * py, pr, "l3_pipe_black", 10)
		var t := r.randf_range(0.6, 1.6)
		while t < ln - 0.3:
			var c := a + f * t + out * (pr + 0.06) + U * py
			pipe(k, c - f * 0.04, c + f * 0.04, pr + 0.025, "l3_flange", 10)
			t += r.randf_range(2.4, 3.6)
	var t2 := r.randf_range(0.4, 1.4)
	while t2 < ln - 0.5:
		var kind := r.randf()
		var p := a + f * t2
		if kind < 0.4:
			var y := r.randf_range(1.2, 1.8)
			var sz := Vector3(r.randf_range(0.25, 0.5), r.randf_range(0.3, 0.6), r.randf_range(0.12, 0.2))
			obox(k, p + out * (sz.z * 0.5) + U * y, out, sz, ["l3_ebox", "l3_ebox_grey", "l3_ebox_green"][r.randi() % 3])
			pipe(k, p + out * 0.05 + U * (y + sz.y * 0.5), p + out * 0.05 + U * cy, 0.016, "l3_conduit", 5)
			if r.randf() < 0.4:
				pipe(k, p + out * 0.05 + U * (y - sz.y * 0.5), p + out * 0.05 + U * 0.35, 0.014, "l3_conduit_grey", 5)
		elif kind < 0.52:
			var sz2 := Vector3(r.randf_range(0.6, 0.95), r.randf_range(1.2, 1.9), 0.34)
			obox(k, p + out * 0.18 + U * (sz2.y * 0.5), out, sz2, "l3_cabinet", true)
			obox(k, p + out * 0.355 + U * (sz2.y * 0.62), out, Vector3(sz2.x * 0.7, 0.3, 0.02), "l3_louvre")
			obox(k, p + out * 0.36 + U * (sz2.y * 0.32), out, Vector3(0.12, 0.12, 0.03), "l3_dial")
			pipe(k, p + out * 0.1 + U * sz2.y, p + out * 0.1 + U * cy, 0.03, "l3_conduit_grey", 6)
		elif kind < 0.66:
			# wall-mounted motor/transformer unit on a bracket
			var y2 := r.randf_range(1.6, 2.2)
			obox(k, p + out * 0.2 + U * (y2 - 0.25), out, Vector3(0.5, 0.06, 0.4), "l3_steel")
			pipe(k, p + out * 0.2 - f * 0.22 + U * (y2 - 0.05), p + out * 0.2 + f * 0.22 + U * (y2 - 0.05), 0.17, ["l3_gen_drum", "l3_ebox_grey"][r.randi() % 2], 10)
			pipe(k, p + out * 0.2 + f * 0.22 + U * (y2 - 0.05), p + out * 0.2 + f * 0.3 + U * (y2 - 0.05), 0.05, "l3_steel", 6)
		elif kind < 0.74:
			obox(k, p + out * 0.04 + U * 0.4, out, Vector3(0.09, 0.12, 0.04), "l3_outlet")
		elif kind < 0.86:
			for v in 2 + r.randi() % 3:
				var q := p + f * (v * 0.09)
				pipe(k, q + out * 0.05 + Vector3.DOWN * 0.02, q + out * 0.05 + U * cy, 0.02 + 0.012 * (v % 2), ["l3_conduit", "l3_cable", "l3_pipe_black"][v % 3], 5)
		t2 += r.randf_range(0.6, 1.6) / maxf(density, 0.3)


## Mismatched brick patches over a wall face (page: brick colour is inconsistent).
static func patches(k: GeoKit, r: RandomNumberGenerator, a: Vector3, b: Vector3, out: Vector3, h: float, mats: Array, holes: Array = []) -> void:
	var d := b - a
	d.y = 0.0
	var ln := d.length()
	var f := d / ln
	var t := r.randf_range(0.0, 2.0)
	while t < ln - 1.0:
		var w := minf(r.randf_range(1.5, 4.5), ln - t)
		var hh := h if r.randf() < 0.6 else r.randf_range(1.0, h)
		for ho in holes:
			if t < float(ho[1]) and t + w > float(ho[0]):
				w = maxf(0.0, float(ho[0]) - t)
		if w > 0.6:
			obox(k, a + f * (t + w * 0.5) + out * 0.012 + U * (hh * 0.5), out, Vector3(w, hh, 0.02), mats[r.randi() % mats.size()])
		t += w + r.randf_range(2.0, 6.0)


static func crate(k: GeoKit, c: Vector3, s: Vector3, yaw: float, mat: String) -> void:
	k.box_xf(Transform3D(Basis(U, yaw), c + U * (s.y * 0.5)), s, mat)


static func drum(k: GeoKit, c: Vector3, mat: String) -> void:
	k.cylinder(c + U * 0.45, 0.29, 0.9, mat, 12)
	for y: float in [0.3, 0.62]:
		k.cylinder(c + U * y, 0.3, 0.03, "l3_steel", 12, false, false)


## Railing with posts, rails, kick plate and a thin collider.
static func railing(k: GeoKit, a: Vector3, b: Vector3, mat: String = "l3_rail") -> void:
	var d := b - a
	var ln := Vector3(d.x, 0, d.z).length()
	if ln < 0.1:
		return
	var f := Vector3(d.x, 0, d.z) / ln
	var t := 0.0
	while t <= ln + 0.01:
		var p := a + f * t
		pipe(k, p, p + U * 1.05, 0.022, mat, 6)
		t += 1.5
	for y: float in [1.05, 0.55]:
		pipe(k, a + U * y, b + U * y, 0.024, mat, 6)
	k.box_xf(Transform3D(frame(f), (a + b) * 0.5 + U * 0.06), Vector3(0.01, 0.12, ln), mat, GeoKit.ALL, false)
	k.box_xf(Transform3D(frame(f), (a + b) * 0.5 + U * 0.55), Vector3(0.06, 1.1, ln), mat, 0, true, "metal")


## Steel grating catwalk deck (top at y) with trusses below.
static func deck(k: GeoKit, x0: float, z0: float, x1: float, z1: float, y: float) -> void:
	k.slab(x0, z0, x1, z1, y, 0.06, "l3_grate")
	var long_x := absf(x1 - x0) > absf(z1 - z0)
	for s: float in [0.0, 1.0]:
		if long_x:
			var z := lerpf(z0, z1, s)
			k.box_mm(Vector3(minf(x0, x1), y - 0.3, z - 0.04), Vector3(maxf(x0, x1), y - 0.06, z + 0.04), "l3_steel", GeoKit.ALL, false)
		else:
			var x := lerpf(x0, x1, s)
			k.box_mm(Vector3(x - 0.04, y - 0.3, minf(z0, z1)), Vector3(x + 0.04, y - 0.06, maxf(z0, z1)), "l3_steel", GeoKit.ALL, false)


## Generator set: plinth, drum, radiator, control box, exhaust to the ceiling.
static func generator(k: GeoKit, c: Vector3, along: Vector3, top: float) -> void:
	var b := frame(along)
	k.box_xf(Transform3D(b, c + U * 0.2), Vector3(3.2, 0.4, 7.0), "l3_concrete_plinth")
	k.box_xf(Transform3D(b, c + U * 1.6), Vector3(2.6, 2.4, 6.2), "l3_gen_body", GeoKit.ALL, false)
	k.add_box_shape(Transform3D(b, c + U * 1.7), Vector3(2.8, 3.0, 6.6), "metal")
	var axis_a := c + b.z * -2.6 + U * 2.2
	var axis_b := c + b.z * 2.6 + U * 2.2
	pipe(k, axis_a, axis_b, 1.15, "l3_gen_drum", 16)
	pipe(k, axis_b, axis_b + b.z * 0.5, 0.7, "l3_steel", 12)
	for s: float in [-2.0, -1.0, 0.0, 1.0, 2.0]:
		pipe(k, c + b.z * s + U * 2.2 - b.z * 0.06, c + b.z * s + U * 2.2 + b.z * 0.06, 1.2, "l3_gen_band", 16)
	k.box_xf(Transform3D(b, c - b.z * 3.4 + U * 1.5), Vector3(2.4, 2.6, 0.6), "l3_louvre")
	k.box_xf(Transform3D(b, c + b.x * 1.6 + b.z * 1.5 + U * 1.2), Vector3(0.5, 1.4, 1.0), "l3_ebox_grey")
	var ex := c + b.x * -0.6 - b.z * 1.8 + U * 3.3
	pipe(k, ex, Vector3(ex.x, top, ex.z), 0.28, "l3_pipe_rust", 10)
	pipe(k, c + b.x * 0.9 + U * 3.0, c + b.x * 0.9 + U * top, 0.12, "l3_conduit", 8)
	k.box_xf(Transform3D(b, c + b.x * 1.86 + b.z * 1.3 + U * 1.5), Vector3(0.02, 0.22, 0.22), "l3_dial", GeoKit.ALL, false)


## Fire-tube boiler on saddles with firebox glow and black outlet pipes.
static func boiler(k: GeoKit, c: Vector3, along: Vector3, top: float) -> void:
	var b := frame(along)
	for s: float in [-2.4, 2.4]:
		k.box_xf(Transform3D(b, c + b.z * s + U * 0.5), Vector3(2.6, 1.0, 0.5), "l3_concrete_plinth")
	var h := c + U * 1.9
	pipe(k, h - b.z * 3.6, h + b.z * 3.6, 1.35, "l3_boiler", 16)
	for s: float in [-3.6, 3.6]:
		pipe(k, h + b.z * s, h + b.z * (s + signf(s) * 0.12), 1.4, "l3_steel", 16)
	k.add_box_shape(Transform3D(b, h), Vector3(2.7, 2.7, 7.4), "metal")
	k.quad(h - b.z * 3.73 + Vector3.DOWN * 0.5, -b.z, b.x * 0.45, U * 0.32, "l3_fireglow")
	for s: float in [-1.5, 0.8]:
		var p := h + b.z * s + U * 1.3
		pipe(k, p, Vector3(p.x, top, p.z), 0.18, "l3_pipe_black", 10)
		pipe(k, p + U * 0.3, p + U * 0.45, 0.24, "l3_flange", 10)


## An old sedan (body, cabin, glass, wheels, lamps).
static func car(k: GeoKit, c: Vector3, d: Vector3) -> void:
	var b := frame(d)
	k.box_xf(Transform3D(b, c + U * 0.62), Vector3(1.78, 0.62, 4.7), "l3_car_paint")
	k.box_xf(Transform3D(b, c + U * 1.18 - b.z * 0.2), Vector3(1.6, 0.5, 2.4), "l3_car_glass")
	k.box_xf(Transform3D(b, c + U * 1.45 - b.z * 0.2), Vector3(1.55, 0.05, 2.1), "l3_car_paint")
	k.add_box_shape(Transform3D(b, c + U * 0.8), Vector3(1.8, 1.4, 4.7), "metal")
	for sx: float in [-0.86, 0.86]:
		for sz: float in [-1.45, 1.45]:
			pipe(k, c + b.x * (sx * 1.02) + b.z * sz + U * 0.34, c + b.x * (sx * 0.86) + b.z * sz + U * 0.34, 0.34, "l3_tyre", 12)
	for sx: float in [-0.62, 0.62]:
		k.box_xf(Transform3D(b, c + b.x * sx + b.z * 2.36 + U * 0.7), Vector3(0.3, 0.14, 0.02), "l3_headlamp", GeoKit.ALL, false)
		k.box_xf(Transform3D(b, c + b.x * sx - b.z * 2.36 + U * 0.72), Vector3(0.28, 0.1, 0.02), "l3_taillamp", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, c + b.z * 2.37 + U * 0.42), Vector3(1.8, 0.14, 0.08), "l3_chrome", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, c - b.z * 2.37 + U * 0.42), Vector3(1.8, 0.14, 0.08), "l3_chrome", GeoKit.ALL, false)


## Greco-Roman column: base, fluted shaft (16 sides), capital, abacus.
static func column(k: GeoKit, p: Vector3, h: float, r: float, mat: String = "l3_marble") -> void:
	k.box(p + U * 0.2, Vector3(r * 2.6, 0.4, r * 2.6), mat)
	k.cylinder(p + U * 0.5, r * 1.15, 0.2, mat, 16, false)
	k.cylinder(p + U * (h * 0.5), r, h - 1.0, mat, 16)
	k.cylinder(p + U * (h - 0.45), r * 1.2, 0.2, mat, 16, false)
	k.box(p + U * (h - 0.17), Vector3(r * 2.8, 0.34, r * 2.8), mat)


## The angel-deity statue on its glyph pedestal (immovable). Faces `face`.
static func statue(k: GeoKit, base: Vector3, face: Vector3) -> void:
	var b := frame(face)
	k.box_xf(Transform3D(b, base + U * 0.8), Vector3(2.2, 1.6, 2.2), "l3_marble")
	k.box_xf(Transform3D(b, base + U * 1.0 + b.z * 1.105), Vector3(1.9, 0.45, 0.02), "l3_glyphs", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, base + U * 1.66), Vector3(2.5, 0.12, 2.5), "l3_marble")
	var f := base + U * 1.72
	var rings := [[0.0, 0.62], [0.6, 0.52], [1.2, 0.42], [1.8, 0.36], [2.3, 0.34], [2.7, 0.3], [3.0, 0.2]]
	for i in rings.size() - 1:
		var y0: float = rings[i][0]
		var y1: float = rings[i + 1][0]
		k.cylinder(f + U * ((y0 + y1) * 0.5), (float(rings[i][1]) + float(rings[i + 1][1])) * 0.5, y1 - y0, "l3_marble", 14, i == 0)
	k.cylinder(f + U * 3.32, 0.17, 0.4, "l3_marble", 12, false)
	k.cylinder(f + U * 3.18, 0.09, 0.2, "l3_marble", 8, false)
	for s: float in [-1.0, 1.0]:
		pipe(k, f + U * 2.75 + b.x * (0.3 * s), f + U * 2.1 + b.x * (0.42 * s) + b.z * 0.35, 0.07, "l3_marble", 8)
		pipe(k, f + U * 2.1 + b.x * (0.42 * s) + b.z * 0.35, f + U * 2.55 + b.x * (0.12 * s) + b.z * 0.42, 0.06, "l3_marble", 8)
		var tips := [Vector2(0.75, 1.55), Vector2(1.3, 1.45), Vector2(1.7, 1.05), Vector2(1.85, 0.45), Vector2(1.75, -0.25), Vector2(1.45, -0.95), Vector2(1.05, -1.5), Vector2(0.6, -1.85)]
		var root := f + U * 2.6 - b.z * 0.3 + b.x * (0.2 * s)
		for j in tips.size():
			var tp: Vector2 = tips[j]
			var tip := root + b.x * (s * tp.x) + U * tp.y - b.z * (0.25 + 0.05 * j)
			var dirv := (tip - root).normalized()
			var bb := Basis(dirv, b.z.cross(dirv).normalized(), b.z).orthonormalized()
			k.box_xf(Transform3D(bb, (root + tip) * 0.5), Vector3((tip - root).length(), 0.5 - j * 0.03, 0.07), "l3_marble", GeoKit.ALL, false)

## Conveyor a->b, belt top at 0.9 m (goods move at runtime, L003_sys.gd).
static func conveyor(k: GeoKit, a: Vector3, b: Vector3, w: float) -> void:
	var d := b - a
	var ln := Vector3(d.x, 0, d.z).length()
	var f := Vector3(d.x, 0, d.z) / ln
	var bas := frame(f)
	var mid := (a + b) * 0.5
	k.box_xf(Transform3D(bas, mid + U * 0.86), Vector3(w, 0.08, ln), "l3_belt", GeoKit.ALL, false)
	k.add_box_shape(Transform3D(bas, mid + U * 0.5), Vector3(w + 0.2, 1.0, ln), "metal")
	for s: float in [-1.0, 1.0]:
		k.box_xf(Transform3D(bas, mid + bas.x * (s * (w * 0.5 + 0.04)) + U * 0.92), Vector3(0.05, 0.24, ln), "l3_rail", GeoKit.ALL, false)
		k.box_xf(Transform3D(bas, mid + bas.x * (s * (w * 0.5 + 0.02)) + U * 0.7), Vector3(0.06, 0.2, ln), "l3_steel", GeoKit.ALL, false)
	var t := 0.4
	while t < ln:
		var p := a + f * t
		for s: float in [-1.0, 1.0]:
			k.box_xf(Transform3D(bas, p + bas.x * (s * w * 0.42) + U * 0.36), Vector3(0.06, 0.72, 0.06), "l3_steel", GeoKit.ALL, false)
		t += 1.8
