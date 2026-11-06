extends RefCounted
## Level 2 props (GeoKit only): pipes, machinery, fixtures, clutter and doors.
## Source: "Level 2 - Abandoned Utility Halls" (Backrooms Wiki rev 93, CC BY-SA
## 3.0), dossier docs/canon/levels/L002.md. Shapes follow the page's wording:
## floor-to-ceiling machinery and thick pipes that do not work together, flatbed
## trolleys, oil drums, boxes, toolboxes, stepladders, extension cords, shattered
## bulbs, paper, and doors "in various colors, materials, sizes, and types".


## Frame for a horizontal direction d: x = side, y = up, z = d.
static func frame(d: Vector3) -> Basis:
	var f := Vector3(d.x, 0.0, d.z).normalized()
	return Basis(Vector3.UP.cross(f).normalized(), Vector3.UP, f)


## Round pipe from a to b (n-gon prism, visual only).
static func pipe(k: GeoKit, a: Vector3, b: Vector3, r: float, mat: String, sides: int = 8) -> void:
	var ax := b - a
	var ln := ax.length()
	if ln < 0.01:
		return
	var d := ax / ln
	var ref := Vector3.UP if absf(d.y) < 0.9 else Vector3.RIGHT
	var u := d.cross(ref).normalized()
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


## Flat disc facing n (gauge faces, drum lids).
static func disk(k: GeoKit, c: Vector3, n: Vector3, r: float, mat: String, sides: int = 12) -> void:
	var ref := Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT
	var u := n.cross(ref).normalized()
	var v := n.cross(u).normalized()
	for i in sides:
		var a0 := TAU * i / sides
		var a1 := TAU * (i + 1) / sides
		k._tri_fan(c, c + (u * cos(a0) + v * sin(a0)) * r, c + (u * cos(a1) + v * sin(a1)) * r, n, mat)


## Oriented box: centre c, local size s, horizontal facing d, optional collision.
static func obox(k: GeoKit, c: Vector3, d: Vector3, s: Vector3, mat: String, collide: bool = false) -> void:
	k.box_xf(Transform3D(frame(d), c), s, mat, GeoKit.ALL, collide)


## A bundle of wall pipes along a straight run p0->p1 (floor points on the wall
## line), offset `out` into the corridor. Heights/radii come from the slot rng so
## both halves of a corridor agree. Brackets every 2.5 m. Joints and flanges.
static func pipe_run(k: GeoKit, p0: Vector3, p1: Vector3, out: Vector3, spec: Array) -> void:
	var d := (p1 - p0)
	var ln := d.length()
	if ln < 0.3:
		return
	d /= ln
	for s in spec:
		var y: float = s[0]
		var r: float = s[1]
		var mat: String = s[2]
		var off: Vector3 = out * (r + 0.05)
		pipe(k, p0 + off + Vector3.UP * y, p1 + off + Vector3.UP * y, r, mat, 10 if r > 0.1 else 7)
		var t := 1.25
		while t < ln - 0.4:
			var c := p0 + d * t + Vector3.UP * y
			pipe(k, c + off - d * 0.04, c + off + d * 0.04, r * 1.18, "l2_steel", 10 if r > 0.1 else 7)
			t += 2.5
	# brackets: vertical steel channel holding the bundle
	var tb := 0.6
	while tb < ln - 0.2:
		var c2 := p0 + d * tb
		var top := 0.0
		for s in spec:
			top = maxf(top, float(s[0]) + float(s[1]))
		if top > 0.0:
			obox(k, c2 + out * 0.03 + Vector3.UP * (top * 0.5 + 0.1), d, Vector3(0.05, top + 0.1, 0.06), "l2_steel")
		tb += 2.5


## Fluorescent batten fixture: steel housing, emissive tube quad (in `kmat` kit).
static func batten(k: GeoKit, kl: GeoKit, c: Vector3, d: Vector3, mat: String, seed_v: float, flick: float, hang: float = 0.0) -> void:
	var side := Vector3.UP.cross(d).normalized()
	obox(k, c + Vector3.UP * 0.05, d, Vector3(0.18, 0.08, 1.3), "l2_fixture")
	if hang > 0.05:
		for s: float in [-0.5, 0.5]:
			pipe(k, c + d * s + Vector3.UP * 0.08, c + d * s + Vector3.UP * (0.08 + hang), 0.008, "l2_cord", 4)
	kl.quad(c + Vector3.DOWN * 0.002, Vector3.DOWN, d * 0.6, side * 0.045, mat, Vector2(seed_v, flick), true)


## Exposed series wiring along a ceiling run (cable tray plus sagging cable).
static func wiring(k: GeoKit, a: Vector3, b: Vector3) -> void:
	var d := (b - a).normalized()
	obox(k, (a + b) * 0.5, d, Vector3(0.32, 0.04, (b - a).length()), "l2_steel")
	var n := 6
	for i in n:
		var t0 := float(i) / n
		var t1 := float(i + 1) / n
		var s0 := sin(t0 * PI * 3.0) * 0.06
		var s1 := sin(t1 * PI * 3.0) * 0.06
		pipe(k, a.lerp(b, t0) + Vector3(0, -0.05 - absf(s0), 0), a.lerp(b, t1) + Vector3(0, -0.05 - absf(s1), 0), 0.014, "l2_cord", 4)


## Floor-to-ceiling machine against a wall. foot = wall-line floor point, out =
## unit vector into the corridor, along = corridor direction. kind 0..4.
static func machine(k: GeoKit, foot: Vector3, out: Vector3, along: Vector3, depth: float, h: float, kind: int, r: RandomNumberGenerator) -> void:
	var len := r.randf_range(0.9, 2.2)
	var c := foot + out * (depth * 0.5)
	match kind:
		0:   # electrical cabinet bank with louvres and gauges
			obox(k, c + Vector3.UP * (h * 0.5), along, Vector3(depth, h, len), "l2_cabinet", true)
			for i in int(len / 0.6):
				var z := -len * 0.5 + 0.3 + i * 0.6
				obox(k, c + out * (depth * 0.5 + 0.005) + along * z + Vector3.UP * 1.55, along, Vector3(0.012, 0.5, 0.42), "l2_louvre")
			dial(k, c + out * (depth * 0.5) + Vector3.UP * 1.25, out, 0.09)
		1:   # pump/motor skid with a drive housing and vertical risers
			obox(k, c + Vector3.UP * 0.35, along, Vector3(depth, 0.7, len), "l2_machine", true)
			k.cylinder(c + Vector3.UP * 0.95, minf(depth * 0.42, 0.3), 0.5, "l2_machine_dark", 10, false)
			for s: float in [-0.3, 0.3]:
				pipe(k, foot + out * 0.12 + along * (len * s) + Vector3.UP * 0.7, foot + out * 0.12 + along * (len * s) + Vector3.UP * h, 0.07, "l2_pipe_green", 8)
		2:   # tall insulated tank
			k.cylinder(c + Vector3.UP * (h * 0.45), depth * 0.5, h * 0.9, "l2_insul", 12, true)
			pipe(k, c + Vector3.UP * (h * 0.9), c + Vector3.UP * h, 0.08, "l2_steel", 8)
		3:   # transformer/compressor box with fins
			obox(k, c + Vector3.UP * (h * 0.32), along, Vector3(depth, h * 0.64, len), "l2_machine_dark", true)
			for i in int(len / 0.12):
				obox(k, c + out * (depth * 0.5 + 0.02) + along * (-len * 0.5 + 0.06 + i * 0.12) + Vector3.UP * (h * 0.32), along, Vector3(0.04, h * 0.5, 0.012), "l2_steel")
		_:   # control panel with valve wheel
			obox(k, c + Vector3.UP * 1.0, along, Vector3(depth, 2.0, len), "l2_machine", true)
			valve(k, c + out * (depth * 0.5) + Vector3.UP * 1.1, out)
			dial(k, c + out * (depth * 0.5) + along * (len * 0.3) + Vector3.UP * 1.6, out, 0.1)


## Wall-mounted pressure dial.
static func dial(k: GeoKit, c: Vector3, out: Vector3, r: float = 0.11) -> void:
	pipe(k, c - out * 0.01, c + out * 0.06, r, "l2_steel", 10)
	disk(k, c + out * 0.061, out, r * 0.85, "l2_dialface", 12)
	var side := Vector3.UP.cross(out).normalized()
	k.box_xf(Transform3D(Basis(side, Vector3.UP, out).rotated(out, 0.9), c + out * 0.066), Vector3(0.01, r * 1.3, 0.005), "l2_red", GeoKit.ALL, false)


## Hand-wheel valve on a stub pipe.
static func valve(k: GeoKit, c: Vector3, out: Vector3) -> void:
	pipe(k, c - out * 0.15, c + out * 0.08, 0.035, "l2_steel", 8)
	var side := Vector3.UP.cross(out).normalized()
	for i in 8:
		var a0 := TAU * i / 8.0
		var a1 := TAU * (i + 1) / 8.0
		pipe(k, c + out * 0.08 + (side * cos(a0) + Vector3.UP * sin(a0)) * 0.14, c + out * 0.08 + (side * cos(a1) + Vector3.UP * sin(a1)) * 0.14, 0.016, "l2_red", 5)


# ------------------------------------------------------------------ clutter

## Flatbed trolley, optionally loaded with a drum or boxes.
static func trolley(k: GeoKit, c: Vector3, d: Vector3, r: RandomNumberGenerator) -> void:
	obox(k, c + Vector3.UP * 0.22, d, Vector3(0.62, 0.05, 1.1), "l2_steel", true)
	for sx: float in [-0.25, 0.25]:
		for sz: float in [-0.45, 0.45]:
			var side := Vector3.UP.cross(d).normalized()
			k.cylinder(c + side * sx + d * sz + Vector3.UP * 0.08, 0.07, 0.05, "l2_rubber", 8, false)
	var hb := c + d * 0.55
	obox(k, hb + Vector3.UP * 0.55, d, Vector3(0.6, 0.03, 0.03), "l2_steel")
	for sx: float in [-0.28, 0.28]:
		obox(k, hb + Vector3.UP.cross(d).normalized() * sx + Vector3.UP * 0.38, d, Vector3(0.03, 0.34, 0.03), "l2_steel")
	if r.randf() < 0.5:
		drum(k, c + Vector3.UP * 0.25 + d * -0.15, r)
	else:
		for i in 1 + r.randi() % 3:
			obox(k, c + Vector3.UP * (0.4 + i * 0.3) + d * r.randf_range(-0.25, 0.25), d.rotated(Vector3.UP, r.randf_range(-0.3, 0.3)), Vector3(0.45, 0.3, 0.4), "l2_cardboard" if r.randf() < 0.6 else "l2_woodbox")


static func drum(k: GeoKit, base: Vector3, r: RandomNumberGenerator, collide: bool = false) -> void:
	var mats := ["l2_drum_blue", "l2_drum_red", "l2_drum_rust"]
	var m: String = mats[r.randi() % mats.size()]
	k.cylinder(base + Vector3.UP * 0.44, 0.29, 0.88, m, 12, collide)
	for y: float in [0.28, 0.6]:
		k.cylinder(base + Vector3.UP * y, 0.3, 0.035, "l2_steel", 12, false, false)


## Toolbox, stepladder, extension-cord coil, shattered bulbs, paper scraps.
static func small_clutter(k: GeoKit, c: Vector3, d: Vector3, r: RandomNumberGenerator) -> void:
	var side := Vector3.UP.cross(d).normalized()
	match r.randi() % 6:
		0:
			obox(k, c + Vector3.UP * 0.11, d.rotated(Vector3.UP, r.randf_range(-0.6, 0.6)), Vector3(0.22, 0.2, 0.5), "l2_red")
			obox(k, c + Vector3.UP * 0.24, d, Vector3(0.05, 0.05, 0.3), "l2_steel")
		1:   # stepladder leaning against the wall
			var lb := Basis(side, Vector3.UP, d).rotated(side, 0.22)
			for s: float in [-0.22, 0.22]:
				k.box_xf(Transform3D(lb, c + d * s + Vector3.UP * 0.8), Vector3(0.04, 1.6, 0.07), "l2_alu", GeoKit.ALL, false)
			for i in 4:
				k.box_xf(Transform3D(lb, c + Vector3.UP * (0.3 + i * 0.36) + side * (-0.02 * i)), Vector3(0.06, 0.03, 0.44), "l2_alu", GeoKit.ALL, false)
		2:   # extension cord coil
			for i in 10:
				var a0 := TAU * i / 10.0
				var a1 := TAU * (i + 1) / 10.0
				for rr: float in [0.16, 0.2]:
					pipe(k, c + Vector3(cos(a0) * rr, 0.02, sin(a0) * rr), c + Vector3(cos(a1) * rr, 0.02, sin(a1) * rr), 0.012, "l2_cord_orange", 4)
		3:   # shattered bulb glass
			for i in 7:
				obox(k, c + Vector3(r.randf_range(-0.4, 0.4), 0.004, r.randf_range(-0.4, 0.4)), Vector3(r.randf_range(-1, 1), 0, r.randf_range(-1, 1)), Vector3(0.05, 0.004, 0.07), "l2_glass_bits")
			pipe(k, c + Vector3(0.1, 0.01, 0.0), c + Vector3(0.4, 0.01, 0.1), 0.012, "l2_glass_bits", 5)
		4:   # scraps of paper
			for i in 3:
				obox(k, c + Vector3(r.randf_range(-0.5, 0.5), 0.003, r.randf_range(-0.5, 0.5)), Vector3(r.randf_range(-1, 1), 0, r.randf_range(-1, 1)), Vector3(0.21, 0.003, 0.29), "paper")
		_:   # boxes of supplies
			for i in 1 + r.randi() % 2:
				obox(k, c + Vector3.UP * (0.18 + i * 0.36), d.rotated(Vector3.UP, r.randf_range(-0.4, 0.4)), Vector3(0.5, 0.36, 0.45), "l2_cardboard" if i == 0 else "l2_woodbox")


# -------------------------------------------------------------------- doors

## Door specs: leaf material, width, frame material, extra decoration.
const DOOR_MATS := {
	"steel_white": "l2_door_white", "steel_grey": "l2_door_grey", "steel_cream": "l2_door_cream",
	"void_window": "l2_door_grey", "void_open": "l2_door_cream", "sign": "l2_door_grey",
	"plywood": "l2_plywood", "aged_wood": "l2_wood_aged", "tall70": "l2_door_dark",
	"rainbow": "l2_door_white", "piano": "l2_door_cream", "metal": "l2_metal_bare",
	"blue": "l2_door_blue", "pink": "l2_door_pink", "blade": "l2_metal_bare",
	"broken_knob": "l2_wood_aged", "elevator": "l2_elevator", "l101": "l2_door_white", "room": "l2_door_cream",
}


## Builds a door leaf (closed) in a wall opening. hinge-free facade: c = centre of
## the opening on the corridor-side wall face, out = unit normal into the
## corridor, w/h = opening size. Returns the leaf centre (for interactables).
static func door(k: GeoKit, lvl, c: Vector3, out: Vector3, w: float, h: float, kind: String, r: RandomNumberGenerator) -> Vector3:
	var along := Vector3.UP.cross(out).normalized()
	var mat: String = DOOR_MATS.get(kind, "l2_door_grey")
	var leaf_c := c - out * 0.09 + Vector3.UP * (h * 0.5)
	# frame / casing
	for s: float in [-1.0, 1.0]:
		obox(k, c + along * (s * (w * 0.5 + 0.04)) + Vector3.UP * (h * 0.5) + out * 0.01, out, Vector3(0.08, h + 0.04, 0.06), "l2_frame")
	obox(k, c + Vector3.UP * (h + 0.04) + out * 0.01, out, Vector3(w + 0.16, 0.08, 0.06), "l2_frame")
	if kind == "elevator":
		for s: float in [-1.0, 1.0]:
			obox(k, leaf_c + along * (s * w * 0.25), out, Vector3(w * 0.5 - 0.01, h, 0.05), "l2_elevator", true)
		obox(k, c + along * (w * 0.5 + 0.3) + Vector3.UP * 1.2 + out * 0.02, out, Vector3(0.14, 0.32, 0.03), "l2_steel")
		obox(k, c + along * (w * 0.5 + 0.3) + Vector3.UP * 1.25 + out * 0.04, out, Vector3(0.05, 0.05, 0.02), "l2_amber")
		obox(k, c + Vector3.UP * (h + 0.25) + out * 0.02, out, Vector3(0.5, 0.14, 0.03), "l2_machine_dark")
		return leaf_c
	if kind == "rainbow":
		var cols := ["l2_rb_r", "l2_rb_o", "l2_rb_y", "l2_rb_g", "l2_rb_b", "l2_rb_v"]
		for i in 6:
			obox(k, leaf_c + Vector3.UP * (-h * 0.5 + h * (i + 0.5) / 6.0), out, Vector3(w, h / 6.0, 0.05), cols[i], true)
		return leaf_c
	obox(k, leaf_c, out, Vector3(w, h, 0.05), mat, true)
	# hardware
	var knob := c + along * (w * 0.5 - 0.12) + Vector3.UP * 1.0 + out * -0.06
	if kind == "broken_knob":
		obox(k, knob + Vector3.DOWN * 0.07 + out * 0.03, out.rotated(along, 0.5), Vector3(0.03, 0.03, 0.07), "l2_brass")
	elif kind in ["metal", "blade", "tall70"]:
		obox(k, knob + out * 0.03, out, Vector3(0.03, 0.22, 0.04), "l2_steel")
	else:
		pipe(k, knob, knob + out * 0.07, 0.03, "l2_brass", 8)
	match kind:
		"steel_white", "steel_grey", "steel_cream", "l101", "piano", "sign", "room":
			# embossed squares, a lock box, kick plate
			for yy: float in [0.55, 1.45]:
				for xx: float in [-0.2, 0.2]:
					obox(k, leaf_c + along * xx + Vector3.UP * (yy - h * 0.5) + out * 0.03, out, Vector3(0.3, 0.6, 0.012), mat)
			obox(k, leaf_c + Vector3.UP * (0.15 - h * 0.5) + out * 0.03, out, Vector3(w - 0.08, 0.22, 0.008), "l2_steel")
		"void_window":
			obox(k, leaf_c + Vector3.UP * 0.45 + out * 0.028, out, Vector3(0.36, 0.5, 0.01), "l2_frame")
			obox(k, leaf_c + Vector3.UP * 0.45 + out * 0.034, out, Vector3(0.3, 0.44, 0.004), "void_black")
		"metal", "blade":
			for yy: float in [0.1, h * 0.5, h - 0.1]:
				for xx in [-w * 0.42, 0.0, w * 0.42]:
					pipe(k, leaf_c + along * xx + Vector3.UP * (yy - h * 0.5) + out * 0.025, leaf_c + along * xx + Vector3.UP * (yy - h * 0.5) + out * 0.04, 0.015, "l2_steel", 5)
			obox(k, leaf_c + Vector3.UP * (h * 0.5 - 0.35) + out * 0.03, out, Vector3(w - 0.1, 0.05, 0.01), "l2_steel")
		"plywood":
			obox(k, leaf_c + out * 0.028, out, Vector3(w * 0.9, 0.06, 0.01), "l2_steel")
		"aged_wood", "broken_knob":
			for i in 4:
				obox(k, leaf_c + along * (-w * 0.375 + i * w * 0.25) + out * 0.028, out, Vector3(0.012, h - 0.1, 0.006), "l2_frame")
	if kind == "blade":
		# a Macchina blade driven diagonally into the door
		var bb := Basis(along, Vector3.UP, out).rotated(out, 0.8)
		k.box_xf(Transform3D(bb, leaf_c + out * 0.12 + Vector3.UP * 0.1), Vector3(0.09, 0.9, 0.012), "l2_blade", GeoKit.ALL, false)
		k.box_xf(Transform3D(bb, leaf_c + out * 0.12 + Vector3.UP * 0.1 + bb.y * -0.55), Vector3(0.05, 0.3, 0.05), "l2_machine_dark", GeoKit.ALL, false)
	if kind == "tall70":
		var lb := Label3D.new()
		lb.text = "70"
		lb.font_size = 160
		lb.pixel_size = 0.004
		lb.modulate = Color(0.22, 0.21, 0.2)
		lb.outline_size = 0
		lb.position = leaf_c + out * 0.03 + Vector3.UP * (h * 0.15)
		lb.rotation.y = atan2(out.x, out.z)
		k.root.add_child(lb)
	if kind == "sign":
		chalk_sign(k, c + out * 0.02 + Vector3.UP * (h + 0.32) + along * 0.0, out, "LEVEL 1  ->  THIS DOOR")
	return leaf_c


## Chalk/marker writing on concrete ("wanderers ... leave signs or engravings").
static func chalk_sign(k: GeoKit, p: Vector3, out: Vector3, text: String, col: Color = Color(0.92, 0.9, 0.84)) -> void:
	var lb := Label3D.new()
	lb.text = text
	lb.font_size = 44
	lb.pixel_size = 0.0035
	lb.modulate = col
	lb.outline_size = 0
	lb.position = p + out * 0.01
	lb.rotation.y = atan2(out.x, out.z)
	lb.rotation.z = 0.03
	k.root.add_child(lb)


## Railing with posts along a->b (top rail at 1.05 m); collision as a thin wall.
static func railing(k: GeoKit, a: Vector3, b: Vector3, collide: bool = true) -> void:
	var d := b - a
	var ln := Vector3(d.x, 0, d.z).length()
	if ln < 0.1:
		return
	var f := Vector3(d.x, 0, d.z) / ln
	pipe(k, a + Vector3.UP * 1.05, b + Vector3.UP * 1.05, 0.025, "l2_rail_yellow", 6)
	pipe(k, a + Vector3.UP * 0.55, b + Vector3.UP * 0.55, 0.018, "l2_rail_yellow", 6)
	var n := int(ln / 1.2) + 1
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		pipe(k, p, p + Vector3.UP * 1.05, 0.022, "l2_rail_yellow", 6)
	if absf(a.y - b.y) < 0.01:
		obox(k, (a + b) * 0.5 + Vector3.UP * 0.12, f, Vector3(0.012, 0.1, ln), "l2_rail_yellow")
	if collide:
		k.add_box_shape(Transform3D(frame(f), (a + b) * 0.5 + Vector3.UP * 0.6), Vector3(0.06, 1.2, ln), "metal")
