extends RefCounted
## Level 140 plants (procedural meshes in per-cell MultiMeshes, two LODs for
## the sunflowers): sunflowers taller than you, wheat, weeds, meadow grass,
## wildflowers, garden flowers, the tiny tree and the weird hydrangea-like
## flower, the peculiar blue flower and the path of flowers it seeds.

const CELL := 24.0

var mat: StandardMaterial3D
var meshes: Dictionary = {}       # kind -> [mesh, range_begin, range_end, shadow]
var cells: Dictionary = {}
var count := 0


func _init() -> void:
	mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.9
	mat.backlight_enabled = true
	mat.backlight = Color(0.35, 0.3, 0.12)
	var r := RandomNumberGenerator.new()
	r.seed = 14020
	meshes["sun_near"] = [_sunflower(r, false), 0.0, 75.0, true]
	meshes["sun_far"] = [_sunflower(r, true), 70.0, 420.0, false]
	meshes["wheat"] = [_tufts(r, 1.05, 12, 0.1, Color(0.4, 0.32, 0.12), Color(0.95, 0.78, 0.36), true), 0.0, 150.0, false]
	meshes["weeds"] = [_tufts(r, 1.25, 6, 0.1, Color(0.06, 0.12, 0.04), Color(0.32, 0.4, 0.14), true), 0.0, 140.0, false]
	meshes["grass"] = [_tufts(r, 0.45, 9, 0.05, Color(0.1, 0.2, 0.05), Color(0.4, 0.55, 0.16), false), 0.0, 60.0, false]
	var cols := [Color(0.95, 0.85, 0.2), Color(0.95, 0.95, 0.92), Color(0.85, 0.25, 0.35), Color(0.6, 0.35, 0.9), Color(1.0, 0.55, 0.15)]
	for i in cols.size():
		meshes["wild%d" % i] = [_flowers(r, cols[i], 12, 0.12), 0.0, 70.0, false]
	meshes["path"] = [_flowers(r, Color(0.3, 0.5, 1.0), 30, 0.1), 0.0, 260.0, false]


# ---------------------------------------------------------------- meshes

func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color, n: Vector3 = Vector3.UP) -> void:
	for v in [[a, ca], [b, cb], [c, cc]]:
		st.set_color(v[1])
		st.set_normal(n)
		st.add_vertex(v[0])


func _sunflower(r: RandomNumberGenerator, low: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# a 2.4 x 1.8 m patch of 4 plants (rows run along x)
	for p in 4:
		var base := Vector3(-0.9 + (p % 2) * 1.8 + r.randf_range(-0.2, 0.2), 0, -0.45 + int(p / 2) * 0.9 + r.randf_range(-0.15, 0.15))
		var h := r.randf_range(1.75, 2.45)
		var lean := Vector3(r.randf_range(-0.12, 0.12), 0, r.randf_range(-0.08, 0.08))
		var top := base + Vector3(0, h, 0) + lean
		var stem := Color(0.16, 0.3, 0.07)
		var w := 0.035
		_tri(st, base + Vector3(-w, 0, 0), base + Vector3(w, 0, 0), top + Vector3(0, -0.1, 0), stem, stem, stem)
		_tri(st, base + Vector3(0, 0, -w), base + Vector3(0, 0, w), top + Vector3(0, -0.1, 0), stem, stem, stem)
		if not low:
			for lf in 3:
				var y := h * (0.3 + lf * 0.2)
				var a := r.randf() * TAU
				var d := Vector3(cos(a), 0, sin(a))
				var s := Vector3(-d.z, 0, d.x) * 0.16
				var c0 := base + lean * (y / h) + Vector3(0, y, 0)
				var tip := c0 + d * 0.45 + Vector3(0, -0.12, 0)
				var lc := Color(0.14, 0.3, 0.06)
				_tri(st, c0, c0 + d * 0.22 + s + Vector3(0, 0.03, 0), tip, lc, lc, lc)
				_tri(st, c0, tip, c0 + d * 0.22 - s + Vector3(0, 0.03, 0), lc, lc, lc)
		# the head faces east and a little up (toward the morning sun)
		var face := Vector3(-1.0, 0.35, r.randf_range(-0.1, 0.5)).normalized()
		var ax := face.cross(Vector3.UP).normalized()
		var ay := ax.cross(face).normalized()
		var hc := top + face * 0.05
		var disc_r := r.randf_range(0.13, 0.18)
		var n := 8 if low else 12
		var brown := Color(0.16, 0.08, 0.03)
		for i in n:
			var a0 := TAU * i / n
			var a1 := TAU * (i + 1) / n
			_tri(st, hc + face * 0.03, hc + (ax * cos(a0) + ay * sin(a0)) * disc_r, hc + (ax * cos(a1) + ay * sin(a1)) * disc_r, brown, brown * 1.3, brown * 1.3, face)
			var am := (a0 + a1) * 0.5
			var pr := disc_r + r.randf_range(0.12, 0.17)
			var yel := Color(0.98, 0.72, 0.08) * r.randf_range(0.85, 1.05)
			_tri(st, hc + (ax * cos(a0) + ay * sin(a0)) * disc_r * 0.95, hc + (ax * cos(a1) + ay * sin(a1)) * disc_r * 0.95,
				hc + (ax * cos(am) + ay * sin(am)) * pr - face * 0.03, yel, yel, yel * 1.1, face)
		# back of the head (green calyx)
		var cal := Color(0.12, 0.22, 0.05)
		for i in 6:
			var a0 := TAU * i / 6.0
			var a1 := TAU * (i + 1) / 6.0
			_tri(st, hc - face * 0.08, hc + (ax * cos(a1) + ay * sin(a1)) * disc_r * 1.1, hc + (ax * cos(a0) + ay * sin(a0)) * disc_r * 1.1, cal, cal, cal, -face)
	return st.commit()


## Ragged tufts of blades (wheat with ears, weeds, meadow grass), 1.6 m patch.
func _tufts(r: RandomNumberGenerator, h: float, blades: int, w: float, c0: Color, c1: Color, ears: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in (10 if blades >= 12 else 6):
		var base := Vector3(r.randf_range(-0.8, 0.8), 0, r.randf_range(-0.8, 0.8))
		for b in blades:
			var a := r.randf() * TAU
			var d := Vector3(cos(a), 0, sin(a))
			var s := Vector3(-d.z, 0, d.x) * w
			var hh := h * r.randf_range(0.6, 1.1)
			var tip := base + d * hh * r.randf_range(0.1, 0.3) + Vector3(0, hh, 0)
			var k := r.randf_range(0.8, 1.15)
			_tri(st, base - s, base + s, tip, c0, c0, c1 * k)
			if ears and b % 2 == 0:
				var e0 := tip + Vector3(0, -0.14, 0)
				var ec := Color(c1.r * 1.05, c1.g * 1.0, c1.b * 0.9) * k
				_tri(st, e0 - s * 1.6, e0 + s * 1.6, tip + d * 0.02 + Vector3(0, 0.05, 0), ec, ec, ec)
	return st.commit()


func _flowers(r: RandomNumberGenerator, col: Color, n: int, size: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stem := Color(0.14, 0.3, 0.08)
	for i in n:
		var p := Vector3(r.randf_range(-1.1, 1.1), 0, r.randf_range(-1.1, 1.1))
		var hh := r.randf_range(0.2, 0.5)
		var top := p + Vector3(0, hh, 0)
		_tri(st, p + Vector3(-0.012, 0, 0), p + Vector3(0.012, 0, 0), top, stem, stem, stem)
		var s := size * r.randf_range(0.7, 1.2)
		var k := r.randf_range(0.85, 1.1)
		var cc := Color(col.r * k, col.g * k, col.b * k)
		for q in 3:
			var a := q * TAU / 3.0 + r.randf()
			var d := Vector3(cos(a), 0.15, sin(a)) * s
			var e := Vector3(-d.z, 0, d.x) * 0.6
			_tri(st, top, top + d + e, top + d - e, cc * 1.1, cc, cc)
	return st.commit()


## The tiny tree (a sapling) and the weird hydrangea-like flower ball.
static func sapling() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r := RandomNumberGenerator.new()
	r.seed = 1404
	var bark := Color(0.25, 0.17, 0.1)
	for s in [Vector3(-0.03, 0, 0), Vector3(0, 0, -0.03)]:
		for v in [Vector3.ZERO - s, s, Vector3(0, 1.3, 0)]:
			st.set_color(bark)
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	for i in 40:
		var c := Vector3(r.randf_range(-0.35, 0.35), r.randf_range(0.8, 1.45), r.randf_range(-0.35, 0.35))
		var d := Vector3(r.randf_range(-1, 1), r.randf_range(-0.2, 0.4), r.randf_range(-1, 1)).normalized() * 0.11
		var e := Vector3(-d.z, 0.02, d.x) * 0.6
		var g := Color(0.18, 0.42, 0.1) * r.randf_range(0.8, 1.15)
		for v in [c, c + d + e, c + d - e]:
			st.set_color(g)
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	return st.commit()


static func hydrangea(col: Color, rad: float, florets: int, seed_value: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	for i in florets:
		var dir := Vector3(r.randf_range(-1, 1), r.randf_range(-0.4, 1), r.randf_range(-1, 1)).normalized()
		var c := dir * rad * r.randf_range(0.85, 1.0)
		var t := dir.cross(Vector3.UP if absf(dir.y) < 0.9 else Vector3.RIGHT).normalized()
		var b := dir.cross(t)
		var s := rad * 0.22
		var k := r.randf_range(0.8, 1.15)
		var cc := Color(col.r * k, col.g * k, col.b * k)
		for q in 4:
			var a := q * TAU / 4.0 + r.randf() * 0.3
			var p0 := c + (t * cos(a) + b * sin(a)) * s
			var p1 := c + (t * cos(a + 0.9) + b * sin(a + 0.9)) * s
			for v in [c + dir * 0.01, p0, p1]:
				st.set_color(cc)
				st.set_normal(dir)
				st.add_vertex(v)
	return st.commit()


# ---------------------------------------------------------------- planting

func add(kind: String, xf: Transform3D) -> void:
	var k := Vector2i(floori(xf.origin.x / CELL), floori(xf.origin.z / CELL))
	if not cells.has(k):
		cells[k] = {}
	var c: Dictionary = cells[k]
	if not c.has(kind):
		c[kind] = []
	(c[kind] as Array).append(xf)
	count += 1


func add_sunflower(xf: Transform3D) -> void:
	add("sun_near", xf)
	add("sun_far", xf)


func commit(parent: Node3D) -> void:
	for k in cells.keys():
		var c: Dictionary = cells[k]
		for kind in c.keys():
			var xfs: Array = c[kind]
			var spec: Array = meshes[kind]
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = spec[0]
			mm.instance_count = xfs.size()
			var centre := Vector3((k.x + 0.5) * CELL, (xfs[0] as Transform3D).origin.y, (k.y + 0.5) * CELL)
			for i in xfs.size():
				var xf: Transform3D = xfs[i]
				xf.origin -= centre
				mm.set_instance_transform(i, xf)
			var mi := MultiMeshInstance3D.new()
			mi.name = "%s_%d_%d" % [kind, k.x, k.y]
			mi.position = centre
			mi.multimesh = mm
			mi.material_override = mat
			if not spec[3]:
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.visibility_range_begin = spec[1]
			mi.visibility_range_end = spec[2]
			mi.visibility_range_begin_margin = 5.0 if spec[1] > 0.0 else 0.0
			mi.visibility_range_end_margin = 8.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			parent.add_child(mi)


## The blooming path: one MultiMesh revealed instance by instance.
func path_mesh(parent: Node3D, xfs: Array) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = meshes["path"][0]
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	mm.visible_instance_count = 0
	var mi := MultiMeshInstance3D.new()
	mi.name = "BlueDustPath"
	mi.multimesh = mm
	var m := mat.duplicate() as StandardMaterial3D
	m.emission_enabled = true
	m.emission = Color(0.25, 0.4, 0.7)
	m.emission_energy_multiplier = 0.6
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mm
