extends RefCounted
## Level 18 art: children's crayon drawings (images drawn at runtime, projected with
## Decal nodes), the Plush Dino (a soft green dinosaur toy built from primitives) and
## the resurfaced dead goldfish. No binary assets.

static var _tex: Dictionary = {}
const CRAYONS := [Color(0.9, 0.2, 0.15), Color(0.15, 0.35, 0.85), Color(0.95, 0.75, 0.1), Color(0.2, 0.65, 0.25), Color(0.85, 0.4, 0.75), Color(0.95, 0.5, 0.1)]


static func _disc(img: Image, c: Vector2, rad: float, col: Color) -> void:
	for y in range(maxi(0, int(c.y - rad)), mini(255, int(c.y + rad)) + 1):
		for x in range(maxi(0, int(c.x - rad)), mini(255, int(c.x + rad)) + 1):
			if Vector2(x, y).distance_to(c) <= rad:
				img.set_pixel(x, y, col)


static func _line(img: Image, a: Vector2, b: Vector2, w: float, col: Color, r: RandomNumberGenerator) -> void:
	var n := maxi(2, int(a.distance_to(b) / 2.0))
	for i in n + 1:
		if r.randf() < 0.88:
			_disc(img, a.lerp(b, float(i) / n) + Vector2(r.randf_range(-1, 1), r.randf_range(-1, 1)), w * 0.5, col)


static func _circle(img: Image, c: Vector2, rad: float, w: float, col: Color, r: RandomNumberGenerator) -> void:
	for k in 20:
		var a0 := TAU * k / 20.0
		var a1 := TAU * (k + 1) / 20.0
		_line(img, c + Vector2(cos(a0), sin(a0)) * rad, c + Vector2(cos(a1), sin(a1)) * rad, w, col, r)


static func _person(img: Image, c: Vector2, s: float, col: Color, r: RandomNumberGenerator) -> void:
	_circle(img, c + Vector2(0, -34) * s, 12.0 * s, 4.0, col, r)
	_line(img, c + Vector2(0, -22) * s, c + Vector2(0, 14) * s, 4.0, col, r)
	_line(img, c + Vector2(-20, -10) * s, c + Vector2(20, -10) * s, 4.0, col, r)
	_line(img, c + Vector2(0, 14) * s, c + Vector2(-12, 40) * s, 4.0, col, r)
	_line(img, c + Vector2(0, 14) * s, c + Vector2(12, 40) * s, 4.0, col, r)


## kinds: family, house, sun, rainbow, dino, flower
static func drawing(kind: String, variant: int = 0) -> ImageTexture:
	var key := "%s_%d" % [kind, variant]
	if _tex.has(key):
		return _tex[key]
	var img := Image.create(256, 256, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.97, 0.96, 0.92, 1.0))
	var r := RandomNumberGenerator.new()
	r.seed = hash(key)
	var cc := func(i: int) -> Color: return CRAYONS[(i + variant) % CRAYONS.size()]
	match kind:
		"family":
			_line(img, Vector2(10, 220), Vector2(246, 222), 6.0, cc.call(3), r)
			for i in 3 + variant % 2:
				_person(img, Vector2(50 + i * 55, 165), 1.0 - (0.35 if i == 2 else 0.0), cc.call(i), r)
			_circle(img, Vector2(215, 40), 22.0, 6.0, cc.call(2), r)
		"house":
			_line(img, Vector2(60, 120), Vector2(60, 220), 5.0, cc.call(0), r)
			_line(img, Vector2(190, 120), Vector2(190, 220), 5.0, cc.call(0), r)
			_line(img, Vector2(60, 220), Vector2(190, 220), 5.0, cc.call(0), r)
			_line(img, Vector2(45, 125), Vector2(125, 50), 6.0, cc.call(1), r)
			_line(img, Vector2(125, 50), Vector2(205, 125), 6.0, cc.call(1), r)
			_line(img, Vector2(45, 125), Vector2(205, 125), 6.0, cc.call(1), r)
			_line(img, Vector2(110, 220), Vector2(110, 170), 4.0, cc.call(4), r)
			_line(img, Vector2(140, 220), Vector2(140, 170), 4.0, cc.call(4), r)
			_line(img, Vector2(110, 170), Vector2(140, 170), 4.0, cc.call(4), r)
			_line(img, Vector2(10, 228), Vector2(246, 226), 7.0, cc.call(3), r)
		"sun":
			_circle(img, Vector2(128, 120), 40.0, 8.0, cc.call(2), r)
			for k in 12:
				var a := TAU * k / 12.0
				_line(img, Vector2(128, 120) + Vector2(cos(a), sin(a)) * 55.0, Vector2(128, 120) + Vector2(cos(a), sin(a)) * 95.0, 6.0, cc.call(5), r)
		"rainbow":
			for b in 5:
				var rad := 110.0 - b * 14.0
				for k in 16:
					var a0 := PI + PI * k / 16.0
					var a1 := PI + PI * (k + 1) / 16.0
					_line(img, Vector2(128, 200) + Vector2(cos(a0), sin(a0)) * rad, Vector2(128, 200) + Vector2(cos(a1), sin(a1)) * rad, 10.0, CRAYONS[b], r)
		"dino":
			var g := Color(0.2, 0.6, 0.25)
			_circle(img, Vector2(120, 150), 50.0, 6.0, g, r)
			_line(img, Vector2(160, 120), Vector2(200, 70), 6.0, g, r)
			_circle(img, Vector2(205, 60), 16.0, 6.0, g, r)
			_line(img, Vector2(72, 160), Vector2(20, 190), 6.0, g, r)
			for lx in [95.0, 140.0]:
				_line(img, Vector2(lx, 195), Vector2(lx, 230), 6.0, g, r)
			for k in 5:
				_line(img, Vector2(85 + k * 16, 104 - absf(k - 2) * 4), Vector2(93 + k * 16, 88 - absf(k - 2) * 4), 5.0, cc.call(5), r)
			_person(img, Vector2(40, 175), 0.7, cc.call(1), r)
		_:
			for k in 3:
				var c := Vector2(60 + k * 68, 120 + r.randf_range(-20, 20))
				_line(img, c, c + Vector2(0, 100), 5.0, CRAYONS[3], r)
				for p in 6:
					var a := TAU * p / 6.0
					_disc(img, c + Vector2(cos(a), sin(a)) * 16.0, 10.0, cc.call(k))
				_disc(img, c, 8.0, CRAYONS[2])
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_tex[key] = t
	return t


## A sheet of paper with a drawing taped to a wall (n: wall normal into the room).
static func pin(parent: Node3D, at: Vector3, n: Vector3, w: float, tex: Texture2D) -> Decal:
	var x := Vector3.UP.cross(n)
	if x.length() < 0.2:
		x = Vector3.RIGHT
	x = x.normalized()
	var z := x.cross(n).normalized()
	var d := Decal.new()
	d.transform = Transform3D(Basis(x, n, z), at)
	d.size = Vector3(w, 0.3, w * 0.78)
	d.texture_albedo = tex
	d.upper_fade = 0.1
	d.lower_fade = 0.1
	parent.add_child(d)
	return d


static func _mi(parent: Node3D, m: Mesh, mat: Material, xf: Transform3D) -> MeshInstance3D:
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
	c.radial_segments = 14
	c.rings = 6
	return c


static func _sph(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 14
	s.rings = 8
	return s


## The Plush Dino: ~0.8 m soft green toy dinosaur. Returns the root (faces -z).
static func plush_dino(parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "PlushDino"
	parent.add_child(root)
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var fur := StandardMaterial3D.new()
	fur.albedo_color = Color(0.36, 0.66, 0.3)
	fur.roughness = 1.0
	fur.rim_enabled = true
	fur.rim = 0.6
	fur.rim_tint = 0.4
	var belly := StandardMaterial3D.new()
	belly.albedo_color = Color(0.86, 0.84, 0.55)
	belly.roughness = 1.0
	var spike := StandardMaterial3D.new()
	spike.albedo_color = Color(0.95, 0.55, 0.15)
	spike.roughness = 1.0
	var eye := MatLib.standard(Color(0.02, 0.02, 0.02), 0.15)
	var flat := Basis(Vector3.RIGHT, PI * 0.5)
	_mi(body, _cap(0.17, 0.5), fur, Transform3D(flat, Vector3(0, 0.26, 0.02)))
	_mi(body, _cap(0.13, 0.36), belly, Transform3D(flat, Vector3(0, 0.22, -0.02)).scaled_local(Vector3(0.9, 1.0, 0.8)))
	_mi(body, _cap(0.075, 0.3), fur, Transform3D(Basis(Vector3.RIGHT, -0.5), Vector3(0, 0.42, -0.2)))
	_mi(body, _sph(0.11), fur, Transform3D(Basis(), Vector3(0, 0.55, -0.31)).scaled_local(Vector3(1.0, 0.9, 1.25)))
	for sx in [-0.05, 0.05]:
		_mi(body, _sph(0.022), eye, Transform3D(Basis(), Vector3(sx, 0.59, -0.42)))
	_mi(body, _cap(0.075, 0.42), fur, Transform3D(Basis(Vector3.RIGHT, PI * 0.5 + 0.35), Vector3(0, 0.2, 0.36)))
	_mi(body, _cap(0.045, 0.24), fur, Transform3D(Basis(Vector3.RIGHT, PI * 0.5 + 0.2), Vector3(0, 0.12, 0.6)))
	for lx in [-0.1, 0.1]:
		for lz in [-0.12, 0.14]:
			var leg := _mi(root, _cap(0.055, 0.2), fur, Transform3D(Basis(), Vector3(lx, 0.1, lz)))
			leg.name = "Leg"
	for k in 5:
		var sb := BoxMesh.new()
		sb.size = Vector3(0.02, 0.07, 0.07)
		_mi(body, sb, spike, Transform3D(Basis(Vector3.RIGHT, PI * 0.25), Vector3(0, 0.45 - absf(k - 2) * 0.02, -0.12 + k * 0.1)))
	return root


## A round fish bowl on a shelf; the goldfish floats belly-up at the top.
static func goldfish_bowl(parent: Node3D, at: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "GoldfishBowl"
	root.position = at
	parent.add_child(root)
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.8, 0.9, 0.95, 0.18)
	glass.roughness = 0.05
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var water := StandardMaterial3D.new()
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.albedo_color = Color(0.6, 0.75, 0.7, 0.3)
	water.roughness = 0.1
	_mi(root, _sph(0.16), glass, Transform3D(Basis(), Vector3(0, 0.15, 0)))
	var wm := CylinderMesh.new()
	wm.top_radius = 0.145
	wm.bottom_radius = 0.1
	wm.height = 0.2
	_mi(root, wm, water, Transform3D(Basis(), Vector3(0, 0.11, 0)))
	var orange := MatLib.standard(Color(0.95, 0.5, 0.12), 0.4)
	var fish := Node3D.new()
	fish.position = Vector3(0.02, 0.21, 0)
	fish.rotation = Vector3(0, 0.6, PI)
	root.add_child(fish)
	_mi(fish, _cap(0.018, 0.07), orange, Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5), Vector3.ZERO))
	var tail := BoxMesh.new()
	tail.size = Vector3(0.03, 0.03, 0.004)
	_mi(fish, tail, orange, Transform3D(Basis(Vector3(0, 0, 1), 0.8), Vector3(0.045, 0, 0)))
	return root
