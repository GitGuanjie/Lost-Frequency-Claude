extends RefCounted
## Level 48 plants (procedural meshes through MultiMeshes per cell).
## SOURCE: dense tropical forest of palms, conifers, broadleaf evergreen and
## deciduous trees; lush vegetation; Gromeliads (bromeliad-like); Veroka
## Flowers (passion-flower-like, always grey) with grey egg-like fruit.

const CELL := 48.0

var bark_mat: Material
var palm_mat: Material
var leaf_mat: StandardMaterial3D
var meshes: Dictionary = {}       # kind -> [mesh, material, shadow, range]
var cells: Dictionary = {}
var count := 0


func _init() -> void:
	MatLib.define("l48_bark", {"albedo_a": Color(0.16, 0.12, 0.09), "albedo_b": Color(0.10, 0.08, 0.06), "pattern": 2,
		"pattern_scale": Vector2(0.1, 1.0), "pattern_color": Color(0.06, 0.05, 0.04), "pattern_strength": 0.6,
		"noise_scale": 1.5, "bump_strength": 1.4, "roughness_a": 0.9, "roughness_b": 1.0}, "concrete")
	MatLib.define("l48_palm", {"albedo_a": Color(0.30, 0.25, 0.19), "albedo_b": Color(0.22, 0.18, 0.13), "pattern": 2,
		"pattern_scale": Vector2(0.16, 1.0), "uv_rotate": 1.5708, "pattern_color": Color(0.14, 0.11, 0.08), "pattern_strength": 0.6,
		"noise_scale": 2.0, "bump_strength": 1.0}, "concrete")
	bark_mat = MatLib.get_mat("l48_bark")
	palm_mat = MatLib.get_mat("l48_palm")
	leaf_mat = StandardMaterial3D.new()
	leaf_mat.vertex_color_use_as_albedo = true
	leaf_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaf_mat.roughness = 0.85
	leaf_mat.backlight_enabled = true
	leaf_mat.backlight = Color(0.5, 0.35, 0.15)
	var r := RandomNumberGenerator.new()
	r.seed = 48020
	for i in 3:
		var p := _palm(r, 8.0 + i * 2.5)
		meshes["palmt%d" % i] = [p[0], palm_mat, true, 380.0]
		meshes["palmc%d" % i] = [p[1], leaf_mat, true, 380.0]
	for i in 3:
		var b := _broadleaf(r, 14.0 + i * 4.0, 0.35 + i * 0.08, Color(0.09 + i * 0.02, 0.2 + i * 0.03, 0.06))
		meshes["broadt%d" % i] = [b[0], bark_mat, true, 300.0]
		meshes["broadc%d" % i] = [b[1], leaf_mat, true, 300.0]
	for i in 2:
		var c := _conifer(r, 16.0 + i * 5.0)
		meshes["cont%d" % i] = [c[0], bark_mat, true, 300.0]
		meshes["conc%d" % i] = [c[1], leaf_mat, true, 300.0]
	meshes["bush"] = [_bushes(r), leaf_mat, false, 140.0]
	meshes["fern"] = [_ferns(r), leaf_mat, false, 90.0]
	meshes["gromeliad"] = [_rosettes(r), leaf_mat, false, 80.0]
	meshes["veroka"] = [_veroka(r), leaf_mat, false, 90.0]


# ---------------------------------------------------------------- pieces

func _tube(st: SurfaceTool, pts: Array, radii: Array, sides: int) -> void:
	var rings: Array = []
	for i in pts.size():
		var p: Vector3 = pts[i]
		var t: Vector3 = ((pts[mini(i + 1, pts.size() - 1)] as Vector3) - (pts[maxi(i - 1, 0)] as Vector3)).normalized()
		var x := t.cross(Vector3.FORWARD if absf(t.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
		var z := t.cross(x).normalized()
		var ring: Array = []
		for k in sides + 1:
			var a := TAU * k / sides
			var n := x * cos(a) + z * sin(a)
			ring.append([p + n * float(radii[i]), n, Vector2(a * float(radii[i]), p.y)])
		rings.append(ring)
	for i in range(1, rings.size()):
		for k in sides:
			var q := [rings[i - 1][k], rings[i - 1][k + 1], rings[i][k + 1], rings[i][k]]
			for idx in [0, 2, 1, 0, 3, 2]:
				var v: Array = q[idx]
				st.set_normal(v[1])
				st.set_uv(v[2])
				st.add_vertex(v[0])


func _blob(st: SurfaceTool, c: Vector3, s: Vector3, r: RandomNumberGenerator, base: Color) -> void:
	var verts := [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, -1, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]
	var faces := [[0, 2, 4], [4, 2, 1], [1, 2, 5], [5, 2, 0], [4, 3, 0], [1, 3, 4], [5, 3, 1], [0, 3, 5]]
	var nf: Array = []
	var cache := {}
	for f in faces:
		var m := []
		for e in [[f[0], f[1]], [f[1], f[2]], [f[2], f[0]]]:
			var key := "%d_%d" % [mini(e[0], e[1]), maxi(e[0], e[1])]
			if not cache.has(key):
				verts.append(((verts[e[0]] as Vector3) + (verts[e[1]] as Vector3)).normalized())
				cache[key] = verts.size() - 1
			m.append(cache[key])
		nf.append([f[0], m[0], m[2]])
		nf.append([f[1], m[1], m[0]])
		nf.append([f[2], m[2], m[1]])
		nf.append([m[0], m[1], m[2]])
	var pts: Array = []
	for v in verts:
		pts.append(c + (v as Vector3) * s * r.randf_range(0.7, 1.2))
	for f in nf:
		var a: Vector3 = pts[f[0]]
		var b: Vector3 = pts[f[1]]
		var cc: Vector3 = pts[f[2]]
		var n := (b - a).cross(cc - a).normalized()
		if n.dot((a + b + cc) / 3.0 - c) < 0.0:
			var t := b
			b = cc
			cc = t
			n = -n
		for v in [a, b, cc]:
			var vv: Vector3 = v
			var up := clampf((vv.y - c.y) / s.y * 0.5 + 0.5, 0.0, 1.0)
			var k := (0.55 + 0.6 * up) * r.randf_range(0.85, 1.1)
			st.set_color(Color(base.r * k, base.g * k, base.b * k))
			st.set_normal((n + (vv - c).normalized()).normalized())
			st.add_vertex(vv)


func _palm(r: RandomNumberGenerator, h: float) -> Array:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array = []
	var rad: Array = []
	var lean := r.randf_range(1.0, 2.8)
	for i in 8:
		var t := float(i) / 7.0
		pts.append(Vector3(lean * t * t, t * h - 0.2, 0))
		rad.append(lerpf(0.26, 0.15, t))
	_tube(st, pts, rad, 7)
	var trunk := st.commit()
	var sc := SurfaceTool.new()
	sc.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top: Vector3 = pts[7]
	var fronds := r.randi_range(9, 12)
	for k in fronds:
		var a := TAU * k / fronds + r.randf_range(-0.2, 0.2)
		var d := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-d.z, 0, d.x)
		var ln := r.randf_range(3.0, 4.2)
		var lift := r.randf_range(0.4, 1.2)
		var prev := top
		for j in range(1, 7):
			var t := float(j) / 6.0
			var p := top + d * ln * t + Vector3(0, lift * sin(t * PI * 0.7) - t * t * ln * 0.7, 0)
			var w := 0.6 * sin(t * PI) + 0.05
			var col := Color(0.10 + 0.05 * t, 0.22 + 0.06 * t, 0.06)
			for s in [-1.0, 1.0]:
				var o: Vector3 = side * w * s + Vector3(0, -w * 0.35, 0)
				for v in [prev, p, p + o, prev, p + o, prev + o * 0.8]:
					sc.set_color(col)
					sc.set_normal(Vector3.UP)
					sc.add_vertex(v)
			prev = p
	_blob(sc, top + Vector3(0, -0.25, 0), Vector3(0.45, 0.45, 0.45), r, Color(0.2, 0.15, 0.08))
	return [trunk, sc.commit()]


func _broadleaf(r: RandomNumberGenerator, h: float, r0: float, green: Color) -> Array:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array = []
	var rad: Array = []
	var off := Vector3.ZERO
	for i in 6:
		var t := float(i) / 5.0
		if i > 0:
			off += Vector3(r.randf_range(-0.3, 0.3), 0, r.randf_range(-0.3, 0.3))
		pts.append(Vector3(off.x, t * h * 0.62 - 0.3, off.z))
		rad.append(r0 * (1.0 - t * 0.55) * (1.5 if i == 0 else 1.0))
	_tube(st, pts, rad, 7)
	var top: Vector3 = pts[5]
	var tips: Array = [top + Vector3(0, h * 0.15, 0)]
	for k in 4:
		var a := TAU * k / 4.0 + r.randf_range(-0.5, 0.5)
		var base: Vector3 = (pts[3] as Vector3).lerp(top, r.randf_range(0.0, 1.0))
		var d := Vector3(cos(a), r.randf_range(0.4, 0.9), sin(a)).normalized()
		var tip := base + d * h * r.randf_range(0.22, 0.32)
		_tube(st, [base, tip], [r0 * 0.3, r0 * 0.12], 5)
		tips.append(tip)
	var trunk := st.commit()
	var sc := SurfaceTool.new()
	sc.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tp in tips:
		var s := h * r.randf_range(0.13, 0.18)
		_blob(sc, tp, Vector3(s * 1.4, s * 0.85, s * 1.3), r, green)
	return [trunk, sc.commit()]


func _conifer(r: RandomNumberGenerator, h: float) -> Array:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_tube(st, [Vector3(0, -0.3, 0), Vector3(0, h * 0.9, 0)], [0.32, 0.08], 6)
	var trunk := st.commit()
	var sc := SurfaceTool.new()
	sc.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tiers := 5
	for i in tiers:
		var t := float(i) / tiers
		var y0 := h * (0.25 + t * 0.66)
		var rr := h * 0.22 * (1.0 - t * 0.8)
		var tip := Vector3(0, y0 + h * 0.22, 0)
		var n := 9
		for k in n:
			var a0 := TAU * k / n
			var a1 := TAU * (k + 1) / n
			var p0 := Vector3(cos(a0) * rr, y0 - rr * 0.25 * r.randf(), sin(a0) * rr)
			var p1 := Vector3(cos(a1) * rr, y0 - rr * 0.25 * r.randf(), sin(a1) * rr)
			var nrm := ((p0 + p1) * 0.5 + Vector3(0, rr * 0.8, 0)).normalized()
			for v in [[p0, 0.6], [p1, 0.6], [tip, 1.0]]:
				var g: float = v[1] * r.randf_range(0.85, 1.1)
				sc.set_color(Color(0.04 * g, 0.12 * g, 0.06 * g))
				sc.set_normal(nrm)
				sc.add_vertex(v[0])
	return [trunk, sc.commit()]


func _bushes(r: RandomNumberGenerator) -> ArrayMesh:
	var sc := SurfaceTool.new()
	sc.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 3:
		var s := r.randf_range(0.5, 0.95)
		_blob(sc, Vector3(r.randf_range(-0.8, 0.8), s * 0.6, r.randf_range(-0.8, 0.8)), Vector3(s * 1.3, s * 0.9, s * 1.2), r, Color(0.08, 0.2, 0.05))
	return sc.commit()


func _card_fan(st: SurfaceTool, base: Vector3, n: int, ln: float, w: float, droop: float, c0: Color, c1: Color, r: RandomNumberGenerator) -> void:
	for k in n:
		var a := TAU * k / n + r.randf_range(-0.3, 0.3)
		var d := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-d.z, 0, d.x) * w
		var mid := base + d * ln * 0.5 + Vector3(0, ln * 0.45, 0)
		var tip := base + d * ln + Vector3(0, ln * (0.5 - droop), 0)
		for v in [[base - side * 0.3, c0], [base + side * 0.3, c0], [mid + side, c1], [base - side * 0.3, c0], [mid + side, c1], [mid - side, c1],
				[mid - side, c1], [mid + side, c1], [tip, c1]]:
			st.set_color(v[1])
			st.set_normal(Vector3.UP)
			st.add_vertex(v[0])


func _ferns(r: RandomNumberGenerator) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 3:
		_card_fan(st, Vector3(r.randf_range(-1.0, 1.0), 0, r.randf_range(-1.0, 1.0)), 7, r.randf_range(0.7, 1.2), 0.16, 0.45,
			Color(0.03, 0.08, 0.02), Color(0.12, 0.3, 0.07), r)
	return st.commit()


## Gromeliads: bromeliad rosettes of stiff leaves with a red bloom at the heart.
func _rosettes(r: RandomNumberGenerator) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 2:
		var b := Vector3(r.randf_range(-0.6, 0.6), 0, r.randf_range(-0.6, 0.6))
		_card_fan(st, b, 9, r.randf_range(0.45, 0.7), 0.07, 0.1, Color(0.05, 0.12, 0.04), Color(0.18, 0.36, 0.12), r)
		_card_fan(st, b + Vector3(0, 0.05, 0), 5, 0.22, 0.05, -0.4, Color(0.6, 0.06, 0.05), Color(0.95, 0.2, 0.12), r)
	return st.commit()


## Veroka vines on a trellis row: grey passion flowers and grey egg-like fruit.
func _veroka(r: RandomNumberGenerator) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 10:
		var p := Vector3(r.randf_range(-1.2, 1.2), r.randf_range(0.3, 1.8), r.randf_range(-0.12, 0.12))
		_blob(st, p, Vector3(0.28, 0.2, 0.18), r, Color(0.07, 0.17, 0.05))
	for i in 6:
		var p := Vector3(r.randf_range(-1.1, 1.1), r.randf_range(0.4, 1.7), r.randf_range(-0.2, 0.2) + 0.15)
		_blob(st, p, Vector3(0.05, 0.07, 0.05), r, Color(0.5, 0.5, 0.48))
	for i in 5:
		var p := Vector3(r.randf_range(-1.1, 1.1), r.randf_range(0.6, 1.8), 0.22)
		_card_fan(st, p, 8, 0.09, 0.03, 0.5, Color(0.55, 0.55, 0.55), Color(0.75, 0.75, 0.74), r)
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


func add_tree(kind: String, i: int, xf: Transform3D) -> void:
	match kind:
		"palm":
			add("palmt%d" % i, xf)
			add("palmc%d" % i, xf)
		"broad":
			add("broadt%d" % i, xf)
			add("broadc%d" % i, xf)
		_:
			add("cont%d" % i, xf)
			add("conc%d" % i, xf)


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
			mi.material_override = spec[1]
			if not spec[2]:
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.visibility_range_end = spec[3]
			mi.visibility_range_end_margin = 15.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			parent.add_child(mi)
