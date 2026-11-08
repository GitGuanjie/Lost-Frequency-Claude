extends RefCounted
## Level 52 set dressing: reddish-brown pictographs drawn into images at runtime
## (projected onto the rock with Decal nodes), the three remains at the entrance,
## the extinguished campfire and the crude tools. No binary assets.

const OCHRE := Color(0.6, 0.2, 0.08)
const SCRATCH := Color(0.78, 0.72, 0.62)

static var _tex: Dictionary = {}


## kinds: campfire, animals, animals_bad, enclosed, hands, claws, eyes
static func texture(kind: String, variant: int = 0) -> ImageTexture:
	var key := "%s_%d" % [kind, variant]
	if _tex.has(key):
		return _tex[key]
	var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var r := RandomNumberGenerator.new()
	r.seed = hash(key)
	var col := SCRATCH if kind == "claws" else OCHRE
	match kind:
		"campfire":
			_fire(img, Vector2(128, 200), col, r)
			var figs := [Vector2(62, 150), Vector2(128, 96), Vector2(194, 150)]
			var crossed := [0, 2] if variant % 2 == 0 else [1, 2]
			for i in 3:
				_stick(img, figs[i], 0.9, col, r)
				if i in crossed:
					_line(img, figs[i] + Vector2(-26, -40), figs[i] + Vector2(26, 44), 5.0, col, r)
					_line(img, figs[i] + Vector2(26, -40), figs[i] + Vector2(-26, 44), 5.0, col, r)
		"animals", "animals_bad":
			var bad := 0.0 if kind == "animals" else 1.0 + variant * 0.6
			_beast(img, Vector2(84, 110), 1.0, variant % 2 == 0, bad, col, r)
			_beast(img, Vector2(178, 178), 0.75, variant % 2 == 1, bad * 1.4, col, r)
		"enclosed":
			_stick(img, Vector2(128, 128), 0.85, col, r)
			for i in 14:
				var a := TAU * i / 14.0 + r.randf_range(-0.12, 0.12)
				var c := Vector2(128, 132) + Vector2(cos(a) * 92, sin(a) * 100)
				var s := r.randf_range(7, 13)
				if i % 3 == 0:
					_ring(img, c, s, 3.5, col, r)
				else:
					var pts := []
					for k in 4:
						pts.append(c + Vector2(cos(k * 1.57 + r.randf()), sin(k * 1.57 + r.randf())) * s)
					for k in 4:
						_line(img, pts[k], pts[(k + 1) % 4], 3.5, col, r)
		"hands":
			for i in 3 + variant % 3:
				_hand(img, Vector2(r.randf_range(50, 206), r.randf_range(60, 200)), r.randf_range(0.8, 1.1), r.randf_range(-0.5, 0.5), col, r)
		"claws":
			var a0 := Vector2(r.randf_range(60, 100), 30)
			for k in 4 + variant % 2:
				var off := Vector2(k * 26, r.randf_range(-8, 8))
				_line(img, a0 + off, a0 + off + Vector2(r.randf_range(20, 70), r.randf_range(170, 210)), r.randf_range(3.0, 5.5), col, r)
		"eyes":
			for side in [-1.0, 1.0]:
				var c := Vector2(128 + side * 58, 128 + r.randf_range(-6, 6))
				for k in 24:
					var t0 := TAU * k / 24.0
					var t1 := TAU * (k + 1) / 24.0
					_line(img, c + Vector2(cos(t0) * 46, sin(t0) * 22), c + Vector2(cos(t1) * 46, sin(t1) * 22), 4.5, col, r)
				_disc(img, c + Vector2(r.randf_range(-6, 6), 0), 13.0, col, 1.0)
	_grain(img, r)
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_tex[key] = t
	return t


static func _disc(img: Image, c: Vector2, rad: float, col: Color, a: float) -> void:
	var x0 := maxi(0, int(c.x - rad))
	var x1 := mini(255, int(c.x + rad))
	var y0 := maxi(0, int(c.y - rad))
	var y1 := mini(255, int(c.y + rad))
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var d := Vector2(x, y).distance_to(c)
			if d <= rad:
				var al := a * clampf((rad - d) * 1.5, 0.0, 1.0)
				var old := img.get_pixel(x, y)
				if al > old.a:
					img.set_pixel(x, y, Color(col.r, col.g, col.b, al))


static func _line(img: Image, a: Vector2, b: Vector2, w: float, col: Color, r: RandomNumberGenerator) -> void:
	var n := maxi(2, int(a.distance_to(b) / 2.0))
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		_disc(img, p + Vector2(r.randf_range(-1.0, 1.0), r.randf_range(-1.0, 1.0)), w * 0.85 * r.randf_range(0.85, 1.1), col, r.randf_range(0.85, 1.0))


static func _ring(img: Image, c: Vector2, rad: float, w: float, col: Color, r: RandomNumberGenerator) -> void:
	for k in 16:
		_line(img, c + Vector2(cos(TAU * k / 16.0), sin(TAU * k / 16.0)) * rad, c + Vector2(cos(TAU * (k + 1) / 16.0), sin(TAU * (k + 1) / 16.0)) * rad, w, col, r)


static func _stick(img: Image, c: Vector2, s: float, col: Color, r: RandomNumberGenerator) -> void:
	_ring(img, c + Vector2(0, -38) * s, 10.0 * s, 4.0, col, r)
	_line(img, c + Vector2(0, -27) * s, c + Vector2(0, 12) * s, 5.0, col, r)
	_line(img, c + Vector2(0, -15) * s, c + Vector2(-20, 2) * s, 4.5, col, r)
	_line(img, c + Vector2(0, -15) * s, c + Vector2(20, -2) * s, 4.5, col, r)
	_line(img, c + Vector2(0, 12) * s, c + Vector2(-14, 42) * s, 4.5, col, r)
	_line(img, c + Vector2(0, 12) * s, c + Vector2(14, 42) * s, 4.5, col, r)


static func _fire(img: Image, c: Vector2, col: Color, r: RandomNumberGenerator) -> void:
	for k in 5:
		var x := -30.0 + k * 15.0
		_line(img, c + Vector2(x, 18), c + Vector2(x * 0.4 + r.randf_range(-6, 6), -40 - r.randf_range(0, 18)), 4.5, col, r)
	_line(img, c + Vector2(-40, 22), c + Vector2(40, 18), 6.0, col, r)


static func _beast(img: Image, c: Vector2, s: float, tusked: bool, bad: float, col: Color, r: RandomNumberGenerator) -> void:
	var j := func(p: Vector2) -> Vector2: return c + p * s + Vector2(r.randf_range(-1, 1), r.randf_range(-1, 1)) * bad * 9.0
	var body: Array = []
	for k in 14:
		var t := TAU * k / 14.0
		body.append(j.call(Vector2(cos(t) * 52, sin(t) * 28 - (6.0 if sin(t) < 0.0 else 0.0))))
	for k in 14:
		_line(img, body[k], body[(k + 1) % 14], 4.5, col, r)
	for lx in [-34.0, -18.0, 20.0, 36.0]:
		_line(img, j.call(Vector2(lx, 20)), j.call(Vector2(lx + r.randf_range(-4, 4), 58)), 4.5, col, r)
	var hd: Vector2 = j.call(Vector2(-66, -12))
	_ring(img, hd, 13.0 * s, 4.0, col, r)
	if tusked:
		_line(img, hd + Vector2(-6, 8), j.call(Vector2(-88, 22)), 4.0, col, r)
		_line(img, j.call(Vector2(-88, 22)), j.call(Vector2(-80, 4)), 4.0, col, r)
		_line(img, hd + Vector2(-10, 6), j.call(Vector2(-74, 42)), 4.5, col, r)
	else:
		_line(img, hd + Vector2(0, -10), j.call(Vector2(-58, -48)), 3.5, col, r)
		_line(img, j.call(Vector2(-58, -48)), j.call(Vector2(-46, -58)), 3.5, col, r)
		_line(img, hd + Vector2(-8, -10), j.call(Vector2(-80, -46)), 3.5, col, r)
	_line(img, j.call(Vector2(50, -6)), j.call(Vector2(66, 14)), 3.5, col, r)


static func _hand(img: Image, c: Vector2, s: float, rot: float, col: Color, r: RandomNumberGenerator) -> void:
	var rotv := func(p: Vector2) -> Vector2: return c + p.rotated(rot) * s
	_disc(img, rotv.call(Vector2(0, 8)), 17.0 * s, col, 0.95)
	_disc(img, rotv.call(Vector2(0, 20)), 14.0 * s, col, 0.95)
	var fingers := [[Vector2(-14, -8), Vector2(-19, -36)], [Vector2(-5, -10), Vector2(-6, -44)], [Vector2(5, -10), Vector2(6, -46)], [Vector2(14, -8), Vector2(18, -38)], [Vector2(-16, 14), Vector2(-36, -2)]]
	for f in fingers:
		_line(img, rotv.call(f[0]), rotv.call(f[1]), 9.0 * s, col, r)


static func _grain(img: Image, r: RandomNumberGenerator) -> void:
	var nz := FastNoiseLite.new()
	nz.seed = r.randi()
	nz.frequency = 0.09
	for y in 256:
		for x in 256:
			var c := img.get_pixel(x, y)
			if c.a <= 0.0:
				continue
			var g := 0.8 + 0.3 * nz.get_noise_2d(x, y) + r.randf_range(-0.15, 0.05)
			img.set_pixel(x, y, Color(c.r * (0.85 + 0.2 * g), c.g, c.b, clampf(c.a * g, 0.0, 0.95)))


## A projected painting on rock: n is the wall normal (pointing into the air).
static func decal(parent: Node3D, at: Vector3, n: Vector3, w: float, h: float, tex: Texture2D, alpha: float = 0.9) -> Decal:
	var x := Vector3.UP.cross(n)
	if x.length() < 0.2:
		x = Vector3.RIGHT
	x = x.normalized()
	var z := x.cross(n).normalized()
	var d := Decal.new()
	d.transform = Transform3D(Basis(x, n, z), at)
	d.size = Vector3(w, 1.6, h)
	d.texture_albedo = tex
	d.modulate = Color(1, 1, 1, alpha)
	d.albedo_mix = 1.0
	d.upper_fade = 0.35
	d.lower_fade = 0.35
	d.distance_fade_enabled = true
	d.distance_fade_begin = 26.0
	d.distance_fade_length = 6.0
	parent.add_child(d)
	return d


static func _mesh(parent: Node3D, m: Mesh, mat: Material, xf: Transform3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	mi.transform = xf
	parent.add_child(mi)
	return mi


static func _cap(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = maxf(h, r * 2.0)
	c.radial_segments = 12
	c.rings = 4
	return c


static func _sph(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 12
	s.rings = 6
	return s


## The three remains found three metres from the entrance: bloated, in active decay,
## skeletonised; all incomplete. Rendered as dark, dressed shapes (no gore close-ups).
static func remains(parent: Node3D, base: Vector3, yaw: float) -> void:
	var root := Node3D.new()
	root.name = "Remains"
	root.position = base
	root.rotation.y = yaw
	parent.add_child(root)
	var cloth_a := MatLib.standard(Color(0.07, 0.075, 0.065), 0.95)
	var cloth_b := MatLib.standard(Color(0.09, 0.07, 0.05), 0.95)
	var skin := MatLib.standard(Color(0.2, 0.19, 0.14), 0.6)
	var dark := MatLib.standard(Color(0.12, 0.09, 0.07), 0.6)
	var bone := MatLib.standard(Color(0.62, 0.56, 0.42), 0.8)
	var stain := MatLib.standard(Color(0.05, 0.035, 0.025), 0.35)
	var flat := Basis(Vector3(0, 0, 1), PI * 0.5)
	# 1: bloated (swollen torso, one leg missing)
	var b1 := Vector3(-1.1, 0, -0.7)
	_mesh(root, _cap(0.3, 1.05), cloth_a, Transform3D(flat.rotated(Vector3.UP, 0.4), b1 + Vector3(0, 0.22, 0)).scaled_local(Vector3(1.0, 0.85, 1.0)))
	_mesh(root, CylinderMesh.new(), MatLib.standard(Color(0.05, 0.035, 0.025), 0.35), Transform3D(Basis().scaled(Vector3(1.9, 0.01, 1.2)), b1 + Vector3(0, 0.006, 0)))
	_mesh(root, _sph(0.15), skin, Transform3D(Basis(), b1 + Vector3(-0.55, 0.22, 0.24)).scaled_local(Vector3(1.1, 1.0, 1.15)))
	_mesh(root, _cap(0.11, 0.8), cloth_a, Transform3D(flat.rotated(Vector3.UP, 0.15), b1 + Vector3(0.75, 0.12, -0.18)))
	_mesh(root, _cap(0.09, 0.55), skin, Transform3D(flat.rotated(Vector3.UP, 1.4), b1 + Vector3(-0.2, 0.1, 0.5)))
	# 2: active decay (collapsed, darker, an arm gone)
	var b2 := Vector3(0.4, 0, 0.5)
	_mesh(root, _cap(0.22, 0.95), cloth_b, Transform3D(flat.rotated(Vector3.UP, -0.9), b2 + Vector3(0, 0.18, 0)).scaled_local(Vector3(1, 0.7, 1)))
	_mesh(root, _sph(0.13), dark, Transform3D(Basis(), b2 + Vector3(-0.32, 0.12, -0.42)))
	_mesh(root, _cap(0.08, 0.7), dark, Transform3D(flat.rotated(Vector3.UP, -0.5), b2 + Vector3(0.5, 0.08, 0.42)))
	_mesh(root, CylinderMesh.new(), stain, Transform3D(Basis().scaled(Vector3(1.6, 0.01, 1.1)), b2 + Vector3(0, 0.006, 0)))
	# 3: skeleton (bones not fully bleached), legs missing below the pelvis
	var b3 := Vector3(1.0, 0, -1.2)
	var sk := Basis(Vector3.UP, 0.7)
	_mesh(root, _sph(0.1), bone, Transform3D(sk, b3 + sk * Vector3(-0.62, 0.09, 0)).scaled_local(Vector3(1.0, 0.9, 1.15)))
	for i in 8:
		_mesh(root, _cap(0.018, 0.4 - absf(i - 3.5) * 0.03), bone, Transform3D(sk * Basis(Vector3(1, 0, 0), PI * 0.5), b3 + sk * Vector3(-0.35 + i * 0.05, 0.07, 0)))
	_mesh(root, _cap(0.025, 0.75), bone, Transform3D(sk * flat, b3 + sk * Vector3(-0.1, 0.04, 0)))
	_mesh(root, _sph(0.12), bone, Transform3D(sk, b3 + sk * Vector3(0.3, 0.05, 0)).scaled_local(Vector3(0.6, 0.45, 1.3)))
	_mesh(root, _cap(0.022, 0.32), bone, Transform3D(sk * flat * Basis(Vector3.RIGHT, 0.4), b3 + sk * Vector3(-0.3, 0.03, 0.24)))
	# the torn rucksack beside the skeleton
	var rk := b3 + sk * Vector3(0.2, 0, 0.75)
	var pack := MatLib.standard(Color(0.22, 0.24, 0.17), 0.95)
	_mesh(root, BoxMesh.new(), pack, Transform3D(Basis(Vector3.UP, 0.3).scaled(Vector3(0.42, 0.26, 0.3)), rk + Vector3(0, 0.13, 0)))
	_mesh(root, BoxMesh.new(), pack, Transform3D(Basis(Vector3(1, 0, 0), 1.2).rotated(Vector3.UP, 0.3).scaled(Vector3(0.38, 0.02, 0.28)), rk + Vector3(0.05, 0.02, 0.32)))


## A single extinguished campfire: ring of stones, charred sticks, ash.
static func campfire(level: Node3D, parent: Node3D, c: Vector3, r: RandomNumberGenerator) -> void:
	var char_m := MatLib.standard(Color(0.04, 0.035, 0.03), 0.9)
	var ash := MatLib.standard(Color(0.32, 0.31, 0.29), 1.0)
	var disc := CylinderMesh.new()
	disc.top_radius = 0.42
	disc.bottom_radius = 0.48
	disc.height = 0.05
	_mesh(parent, disc, ash, Transform3D(Basis(), c + Vector3(0, 0.025, 0)))
	for i in 9:
		var a := TAU * i / 9.0 + r.randf_range(-0.1, 0.1)
		Props.place(level, parent, "ph/rock_07", c + Vector3(cos(a), 0, sin(a)) * 0.58, r.randf_range(0, 360), r.randf_range(0.13, 0.2))
	for i in 6:
		var stick := CylinderMesh.new()
		stick.top_radius = 0.025
		stick.bottom_radius = 0.035
		stick.height = r.randf_range(0.4, 0.7)
		stick.radial_segments = 6
		var bs := Basis(Vector3(0, 0, 1), r.randf_range(1.2, 1.45)).rotated(Vector3.UP, TAU * i / 6.0 + r.randf())
		_mesh(parent, stick, char_m, Transform3D(bs, c + Vector3(r.randf_range(-0.12, 0.12), 0.08, r.randf_range(-0.12, 0.12))))


## Crude prehistoric tools: knapped stones, a bone and a sharpened stick.
static func tools(level: Node3D, parent: Node3D, c: Vector3, r: RandomNumberGenerator) -> void:
	for i in 3:
		Props.place(level, parent, "ph/rock_07", c + Vector3(r.randf_range(-0.4, 0.4), 0, r.randf_range(-0.3, 0.3)), r.randf_range(0, 360), 0.06)
	var bone := MatLib.standard(Color(0.6, 0.55, 0.43), 0.8)
	_mesh(parent, _cap(0.025, 0.36), bone, Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5).rotated(Vector3.UP, r.randf() * TAU), c + Vector3(0.35, 0.03, 0.3)))
	var wood := MatLib.standard(Color(0.22, 0.16, 0.1), 0.9)
	var stick := CylinderMesh.new()
	stick.top_radius = 0.004
	stick.bottom_radius = 0.025
	stick.height = 1.1
	stick.radial_segments = 6
	_mesh(parent, stick, wood, Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5).rotated(Vector3.UP, r.randf() * TAU), c + Vector3(-0.3, 0.03, 0.45)))
