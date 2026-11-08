extends RefCounted
## Level 1.2 dressing: grass carpet and multicoloured flowers per 8 m bay, vines
## up every pillar and wall (some across the ceiling, hanging in curtains), the
## sunflower batch, three bluebonnet patches, roses, ferns beside cacti (plants of
## contradicting climates), the settlers' leftovers and the threshold's crates.

const G := preload("res://levels/L001_2/L001_2_geo.gd")
const PALETTE := [Color(0.85, 0.08, 0.1), Color(0.97, 0.8, 0.12), Color(0.96, 0.95, 0.9), Color(0.62, 0.42, 0.88),
	Color(0.96, 0.5, 0.72), Color(0.97, 0.45, 0.08), Color(0.3, 0.42, 0.95)]
const SUNFLOWERS := Vector3(-20.0, 0.0, -24.0)
const PATCHES := [Vector3(-28.4, 0.0, -43.6), Vector3(12.0, 0.0, -84.0), Vector3(-24.0, 0.0, -84.0)]

var lvl
var geo
var flora
var k: GeoKit
var props := 0
var leaves: Dictionary = {}     # band index -> Array[Transform3D]
var flowers_n := 0
var tufts_n := 0


func _init(level, g, f, dress: GeoKit) -> void:
	lvl = level
	geo = g
	flora = f
	k = dress


func p(parent: Node3D, id: String, pos: Vector3, yaw := 0.0, h := 0.0, collide := false) -> Node3D:
	var n: Node3D = Props.place(lvl, parent, id, pos, yaw, h, collide)
	if n:
		props += 1
	return n


static func noise(x: float, z: float, s: float) -> float:
	return 0.5 + 0.25 * sin(x * 0.31 + s) * cos(z * 0.27 - s * 0.7) + 0.25 * sin((x + z) * 0.13 + s * 1.9)


## Ground height for planting, or NAN where nothing grows.
func ground(x: float, z: float) -> float:
	var v := Vector2(x, z)
	for b in geo.blocked:
		if (b as Rect2).has_point(v):
			return NAN
	if x < G.X0 + 0.25 or x > G.X1 - 0.25 or z < G.Z1 + 0.25:
		return NAN
	if z > G.ZG and absf(x) > 11.7:
		return NAN
	if G.TERRACE.has_point(v):
		return G.TERRACE_Y
	if G.PIT.has_point(v):
		return G.PIT_Y
	return 0.0


# ------------------------------------------------------------------ carpet

func carpet(parent: Node3D, r: RandomNumberGenerator) -> void:
	var z0 := 4.0
	while z0 > G.Z1:
		var x0 := G.X0
		while x0 < G.X1:
			if z0 <= G.ZG or absf(x0 + 4.0) < 12.0:
				_bay(parent, x0, z0, r)
			x0 += G.BAY
		z0 -= G.BAY


func _bay(parent: Node3D, x0: float, z0: float, r: RandomNumberGenerator) -> void:
	var c := Vector3(x0 + 4.0, 0, z0 - 4.0)
	var hall := z0 > G.ZG
	var d := 1.0
	if hall:
		d = 0.35 if z0 <= -4.0 else 0.12
	var node := Node3D.new()
	node.name = "Bay_%d_%d" % [int(x0), int(z0)]
	node.position = c
	parent.add_child(node)
	var tf: Array = []
	var tl: Array = []
	var fl: Array = []
	var fc: Array = []
	var n := int(64.0 * 2.8 * d)
	for i in n:
		var x := c.x + r.randf_range(-4.0, 4.0)
		var z := c.z + r.randf_range(-4.0, 4.0)
		var nz := noise(x, z, 1.3)
		if hall and nz < 0.62 - (z0 + 12.0) * 0.01:
			continue
		var y := ground(x, z)
		if is_nan(y):
			continue
		var tall := nz > 0.66 and not hall
		var xf: Transform3D = flora.xf(Vector3(x - c.x, y, z - c.z), r.randf() * TAU, r.randf_range(0.8, 1.3) * (1.0 if not tall else 1.15))
		(tl if tall else tf).append(xf)
	var nf := int(64.0 * 1.5 * d)
	for i in nf:
		var x := c.x + r.randf_range(-4.0, 4.0)
		var z := c.z + r.randf_range(-4.0, 4.0)
		var y := ground(x, z)
		if is_nan(y) or (hall and noise(x, z, 1.3) < 0.6):
			continue
		var ci := int(noise(x * 0.5, z * 0.5, 4.2) * 11.0 + c.x * 0.37 + c.z * 0.21) % PALETTE.size()
		if r.randf() < 0.35:
			ci = r.randi() % PALETTE.size()
		var col: Color = PALETTE[ci]
		col = col.lerp(Color(1, 1, 1), r.randf() * 0.15)
		fl.append(flora.xf(Vector3(x - c.x, y, z - c.z), r.randf() * TAU, r.randf_range(0.8, 1.7)))
		fc.append(col)
	flora.scatter(node, "tuft", tf, [], 52.0)
	flora.scatter(node, "tall", tl, [], 52.0)
	flora.scatter(node, "flower", fl, fc, 44.0)
	tufts_n += tf.size() + tl.size()
	flowers_n += fl.size()


## The batch of sunflowers, the bluebonnet patches, roses, ferns and cacti.
func specials(parent: Node3D, r: RandomNumberGenerator) -> void:
	var sf: Array = []
	for i in 44:
		var a := r.randf() * TAU
		var rad := sqrt(r.randf()) * 3.0
		var pos := SUNFLOWERS + Vector3(cos(a) * rad, 0, sin(a) * rad)
		if is_nan(ground(pos.x, pos.z)):
			continue
		sf.append(flora.xf(pos, r.randf_range(-0.5, 0.5), r.randf_range(0.85, 1.2)))
	flora.scatter(parent, "sunflower", sf, [], 0.0)
	for pc in PATCHES:
		var bb: Array = []
		for i in 320:
			var a := r.randf() * TAU
			var rad := sqrt(r.randf()) * 2.8
			var pos: Vector3 = pc + Vector3(cos(a) * rad, 0, sin(a) * rad)
			var y := ground(pos.x, pos.z)
			if is_nan(y):
				continue
			bb.append(flora.xf(Vector3(pos.x, y, pos.z), r.randf() * TAU, r.randf_range(0.8, 1.3)))
		flora.scatter(parent, "bluebonnet", bb, [], 60.0)
	var roses: Array = []
	var ferns: Array = []
	var cacti: Array = []
	for i in 160:
		var pos := Vector3(r.randf_range(G.X0 + 1, G.X1 - 1), 0, r.randf_range(-62.0, G.Z1 + 1.0))
		var y := ground(pos.x, pos.z)
		if is_nan(y):
			continue
		pos.y = y
		var deep := pos.z < -74.0 or G.PIT.has_point(Vector2(pos.x, pos.z))
		var roll := r.randf()
		if roll < 0.35 and deep:
			roses.append(flora.xf(pos, r.randf() * TAU, r.randf_range(0.8, 1.4)))
		elif roll < 0.75:
			ferns.append(flora.xf(pos, r.randf() * TAU, r.randf_range(0.8, 1.5)))
		elif roll < 0.86 and deep:
			cacti.append(flora.xf(pos, r.randf() * TAU, r.randf_range(0.8, 1.3)))
	flora.scatter(parent, "rose", roses, [], 0.0)
	flora.scatter(parent, "fern", ferns, [], 0.0)
	flora.scatter(parent, "cactus", cacti, [], 0.0)


# ------------------------------------------------------------------ vines

func _leaf_at(pos: Vector3, n: Vector3, r: RandomNumberGenerator, s := 1.0) -> void:
	var up := n.normalized()
	var ref := Vector3.RIGHT if absf(up.x) < 0.9 else Vector3.FORWARD
	var xa := up.cross(ref).normalized()
	var za := xa.cross(up).normalized()
	var b := Basis(xa, up, za).rotated(up, r.randf() * TAU)
	b = b.rotated(xa, r.randf_range(-0.6, 0.6))
	var band := int(floor(-pos.z / 16.0))
	if not leaves.has(band):
		leaves[band] = []
	leaves[band].append(Transform3D(b.scaled(Vector3.ONE * s * r.randf_range(0.8, 1.6)), pos + up * 0.025))


## A strand from a to b with jitter, leaves along it. n = facing for the leaves.
func strand(a: Vector3, b: Vector3, n: Vector3, r: RandomNumberGenerator, jitter := 0.25, leafy := 1.0) -> void:
	var segs := maxi(2, int(a.distance_to(b) / 0.7))
	var prev := a
	var side := (b - a).cross(n).normalized()
	for i in segs:
		var t := float(i + 1) / segs
		var nxt := a.lerp(b, t) + side * (r.randf_range(-jitter, jitter) if i < segs - 1 else 0.0)
		var d := nxt - prev
		if d.length() > 0.01:
			k.box_xf(Transform3D(Basis.looking_at(d, n if absf(d.normalized().dot(n)) < 0.95 else Vector3.RIGHT), (prev + nxt) * 0.5), Vector3(0.035, 0.035, d.length()), "l12_vine", GeoKit.ALL, false)
			var m := int(d.length() / 0.12 * leafy)
			for j in m:
				_leaf_at(prev.lerp(nxt, r.randf()) + side * r.randf_range(-0.06, 0.06), n + side * r.randf_range(-0.6, 0.6), r)
		prev = nxt


func vines(r: RandomNumberGenerator) -> void:
	var faces := [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]
	for pl in geo.pillars:
		var base: Vector3 = pl
		var hall := base.z > G.ZG
		if hall and base.z > -6.0:
			continue
		for f in faces:
			var fv: Vector3 = f
			var count := 1 if hall else r.randi_range(1, 3)
			for s in count:
				var side := fv.cross(Vector3.UP)
				var off := side * r.randf_range(-0.5, 0.5)
				var a := base + fv * 0.72 + off
				var top := G.HH - 0.05
				var b := Vector3(a.x, top if not hall else r.randf_range(1.0, 2.6), a.z) + side * r.randf_range(-0.3, 0.3)
				strand(a, b, fv, r, 0.18)
				if not hall and r.randf() < 0.45:
					# across the ceiling, with hanging drapes
					var dir := fv
					var ln := r.randf_range(2.5, 7.0)
					var c0 := Vector3(b.x, top, b.z)
					var c1 := c0 + dir * ln + side * r.randf_range(-1.0, 1.0)
					strand(c0, c1, Vector3.DOWN, r, 0.3, 0.8)
					var dd := 0.0
					while dd < ln:
						var hp := c0.lerp(c1, dd / ln)
						strand(hp, hp + Vector3(r.randf_range(-0.1, 0.1), -r.randf_range(0.4, 1.9), r.randf_range(-0.1, 0.1)), side, r, 0.06, 0.9)
						dd += r.randf_range(0.6, 1.4)
	# walls
	for w in geo.walls:
		var a: Vector3 = w["a"]
		var b: Vector3 = w["b"]
		var ln := a.distance_to(b)
		var dir := (b - a) / ln
		var nrm := Vector3(-dir.z, 0, dir.x)
		var t := r.randf_range(0.3, 1.2)
		while t < ln - 0.3:
			var open := false
			for op in w["ops"]:
				if absf(t - float(op["at"])) < float(op["w"]) * 0.5 + 0.2:
					open = true
			var p0 := a + dir * t
			if not open and p0.z < -4.0:
				for sgn in [-1.0, 1.0]:
					var fp: Vector3 = p0 + nrm * sgn * 0.17
					if absf(fp.x) > G.X1 or fp.z < G.Z1 or (fp.z > G.ZG and absf(fp.x) > 12.0):
						continue
					var h := r.randf_range(1.2, G.HH - 0.05) if p0.z < G.ZG else r.randf_range(0.6, 2.0)
					strand(fp, fp + Vector3(0, h, 0) + dir * r.randf_range(-0.8, 0.8), nrm * sgn, r, 0.3)
					if r.randf() < 0.5:
						k.box(fp + Vector3(0, 0.25, 0) + nrm * sgn * 0.01, Vector3(absf(dir.x) * 1.4 + 0.03, 0.5, absf(dir.z) * 1.4 + 0.03), "l12_moss", GeoKit.ALL, false)
			t += r.randf_range(1.0, 2.2)
	# curtains of hanging vines in the deep garden
	for i in 26:
		var c := Vector3(r.randf_range(G.X0 + 2, G.X1 - 2), G.HH - 0.05, r.randf_range(-74.0, G.Z1 + 2.0))
		var ln := r.randf_range(2.0, 5.0)
		var dir := Vector3(r.randf_range(-1, 1), 0, r.randf_range(-1, 1)).normalized()
		strand(c, c + dir * ln, Vector3.DOWN, r, 0.3, 0.7)
		var dd := 0.0
		while dd < ln:
			var hp := c + dir * dd
			strand(hp, hp + Vector3(0, -r.randf_range(1.2, 3.4), 0), dir.cross(Vector3.UP), r, 0.08, 1.0)
			dd += r.randf_range(0.35, 0.8)


func commit_leaves(parent: Node3D) -> void:
	for band in leaves.keys():
		flora.scatter(parent, "leaf", leaves[band], [], 0.0)


# ------------------------------------------------------------------ props

func objects(parent: Node3D, r: RandomNumberGenerator) -> void:
	# threshold hall: Level 1 crates and a leak under the pipe
	for c in [Vector3(-8.5, 0, 6.0), Vector3(8.0, 0, 16.0), Vector3(-9.0, 0, 20.0)]:
		for j in 3:
			var s := r.randf_range(0.8, 1.1)
			k.box_xf(Transform3D(Basis(Vector3.UP, r.randf_range(-0.2, 0.2)), c + Vector3(r.randf_range(-0.4, 0.4), s * 0.5 + float(j / 2) * 0.95, float(j % 2) * 1.1)), Vector3(s, s * 0.95, s), "l12_wood", GeoKit.ALL, j < 2)
	p(parent, "ph/wooden_crate_01", Vector3(9.0, 0, 4.0), 30.0)
	p(parent, "ph/Barrel_01", Vector3(-10.5, 0, 12.0), 0.0)
	for i in 3:
		k.box(Vector3(2.3 + r.randf_range(-0.6, 0.6), 0.004, 8.0 + r.randf_range(-1.0, 1.0)), Vector3(r.randf_range(0.6, 1.4), 0.004, r.randf_range(0.6, 1.2)), "l12_moss" if i == 0 else "l12_ceiling", GeoKit.ALL, false)
	# the settlers' leftovers, overgrown
	var camp := Vector3(17.0, 0, -55.0)
	p(parent, "ph/wooden_picnic_table", camp, 80.0)
	p(parent, "ph/plastic_monobloc_chair_01", camp + Vector3(1.6, 0, 1.2), 140.0)
	var ch := p(parent, "ph/plastic_monobloc_chair_01", camp + Vector3(-1.9, 0.3, -0.8), 40.0)
	if ch:
		ch.rotation.z = PI * 0.5
	p(parent, "kenney/food-kit/pot-stew", camp + Vector3(0.2, 0.75, 0.3), 0.0, 0.25)
	p(parent, "kenney/graveyard-kit/lantern-glass", camp + Vector3(-0.4, 0.75, -0.5), 0.0, 0.35)
	p(parent, "ph/vintage_suitcase", Vector3(27.0, 0, -58.0), 70.0)
	p(parent, "ph/propane_tank", Vector3(29.5, 0, -45.0), 0.0)
	p(parent, "ph/Barrel_01", Vector3(14.0, 0, -45.0), 0.0)
	p(parent, "ph/wooden_crate_01", Vector3(26.0, 0, -62.0), 15.0)
	p(parent, "ph/trashbag", Vector3(15.0, 0, -63.0), 50.0)
	for b in [Vector3(20.5, 0.06, -58.5), Vector3(27.5, 0.06, -55.0)]:
		k.box_xf(Transform3D(Basis(Vector3.UP, r.randf()), b), Vector3(0.75, 0.12, 1.9), "l12_cloth", GeoKit.ALL, false)
	# the botanist's dropped kit by the sunflowers
	p(parent, "ph/binder_notebook", SUNFLOWERS + Vector3(3.6, 0.0, 2.8), 30.0)
	p(parent, "ph/vintage_flashlight", SUNFLOWERS + Vector3(4.0, 0.0, 3.3), 110.0)
	for i in 5:
		p(parent, "ph/rock_07", Vector3(r.randf_range(-29, -15), G.TERRACE_Y, r.randf_range(-52, -68)), r.randf() * 360.0, 0.0)


## Drifting motes (pollen) that follow the camera.
static func motes(lvl) -> CPUParticles3D:
	var pt := CPUParticles3D.new()
	pt.name = "Pollen"
	pt.amount = 140
	pt.lifetime = 9.0
	pt.preprocess = 9.0
	pt.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	pt.emission_box_extents = Vector3(9, 2.2, 9)
	pt.direction = Vector3(0.3, 0.2, 0.1)
	pt.spread = 180.0
	pt.gravity = Vector3(0, -0.01, 0)
	pt.initial_velocity_min = 0.02
	pt.initial_velocity_max = 0.12
	pt.local_coords = false
	var q := QuadMesh.new()
	q.size = Vector2(0.018, 0.018)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_color = Color(1.0, 0.95, 0.7, 0.7)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material = m
	pt.mesh = q
	lvl.add_child(pt)
	return pt


## A puff of pollen at a patch.
static func puff(lvl, at: Vector3) -> void:
	var pt := CPUParticles3D.new()
	pt.one_shot = true
	pt.amount = 90
	pt.lifetime = 3.5
	pt.explosiveness = 0.9
	pt.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	pt.emission_sphere_radius = 0.6
	pt.direction = Vector3.UP
	pt.spread = 70.0
	pt.gravity = Vector3(0, -0.05, 0)
	pt.initial_velocity_min = 0.2
	pt.initial_velocity_max = 0.7
	var q := QuadMesh.new()
	q.size = Vector2(0.03, 0.03)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.albedo_color = Color(0.75, 0.78, 1.0, 0.8)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	q.material = m
	pt.mesh = q
	pt.position = at + Vector3(0, 0.4, 0)
	lvl.add_child(pt)
	pt.emitting = true
	lvl.get_tree().create_timer(5.0).timeout.connect(pt.queue_free)
