extends RefCounted
## Level 29 plants, all procedural meshes drawn through MultiMeshes per cell:
## - the native tree (SOURCE): thick, tall, red trunk and white leaves;
## - crops in the farm fields of the inner circle (three row crops);
## - "unique flowers" that paint the hills in many colours (SOURCE).

const CELL := 64.0

var bark_mat: Material
var leaf_mat: StandardMaterial3D
var crop_mat: StandardMaterial3D
var meshes: Dictionary = {}       # kind -> [mesh, material, cast_shadow, range]
var cells: Dictionary = {}        # Vector2i -> {kind: [xf...]}
var count := 0


func _init() -> void:
	MatLib.define("l29_bark", {"albedo_a": Color(0.42, 0.075, 0.05), "albedo_b": Color(0.30, 0.05, 0.035), "pattern": 2,
		"pattern_scale": Vector2(0.09, 1.0), "pattern_color": Color(0.17, 0.03, 0.02), "pattern_strength": 0.65,
		"noise_scale": 1.6, "bump_strength": 1.6, "roughness_a": 0.85, "roughness_b": 1.0}, "concrete")
	bark_mat = MatLib.get_mat("l29_bark")
	leaf_mat = StandardMaterial3D.new()
	leaf_mat.vertex_color_use_as_albedo = true
	leaf_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaf_mat.roughness = 0.9
	leaf_mat.backlight_enabled = true
	leaf_mat.backlight = Color(0.35, 0.3, 0.3)
	leaf_mat.emission_enabled = true
	leaf_mat.emission = Color(0.2, 0.19, 0.19)
	crop_mat = StandardMaterial3D.new()
	crop_mat.vertex_color_use_as_albedo = true
	crop_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	crop_mat.roughness = 0.95
	var r := RandomNumberGenerator.new()
	r.seed = 29020
	for i in 4:
		var pair := _tree(r, 13.0 + i * 3.5, 0.5 + i * 0.09)
		meshes["trunk%d" % i] = [pair[0], bark_mat, true, 420.0]
		meshes["crown%d" % i] = [pair[1], leaf_mat, true, 420.0]
	meshes["crop0"] = [_crop(r, 1.05, Color(0.22, 0.2, 0.08), Color(0.62, 0.52, 0.22), 7), crop_mat, false, 170.0]   # grain
	meshes["crop1"] = [_crop(r, 0.55, Color(0.05, 0.12, 0.03), Color(0.18, 0.36, 0.1), 5), crop_mat, false, 150.0]   # leafy rows
	meshes["crop2"] = [_crop(r, 1.7, Color(0.07, 0.15, 0.04), Color(0.36, 0.42, 0.14), 6), crop_mat, false, 170.0]    # tall maize-like
	var cols := [Color(0.85, 0.16, 0.22), Color(0.95, 0.75, 0.15), Color(0.55, 0.25, 0.85), Color(0.95, 0.95, 0.92), Color(0.25, 0.45, 0.95), Color(0.98, 0.45, 0.15)]
	for i in cols.size():
		meshes["flower%d" % i] = [_flowers(r, cols[i]), crop_mat, false, 110.0]


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


## Irregular foliage mass: a displaced, once-subdivided octahedron, vertex-lit.
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
			var k := (0.62 + 0.38 * up) * r.randf_range(0.9, 1.05)
			st.set_color(Color(base.r * k, base.g * k, base.b * k))
			st.set_normal((n + (vv - c).normalized()).normalized())
			st.add_vertex(vv)


## Thick, tall red trunk; white crown of heavy masses.
func _tree(r: RandomNumberGenerator, h: float, r0: float) -> Array:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array = []
	var rad: Array = []
	var off := Vector3.ZERO
	var nseg := 6
	for i in nseg + 1:
		var t := float(i) / nseg
		if i > 0:
			off += Vector3(r.randf_range(-0.22, 0.22), 0, r.randf_range(-0.22, 0.22))
		pts.append(Vector3(off.x, t * h * 0.72 - 0.4, off.z))
		rad.append(r0 * (1.0 - t * 0.55) * (1.4 if i == 0 else 1.0))
	_tube(st, pts, rad, 8)
	var top_p: Vector3 = pts[pts.size() - 1]
	var tips: Array = [top_p + Vector3(0, h * 0.14, 0)]
	var limbs := r.randi_range(4, 5)
	for k in limbs:
		var a := TAU * k / limbs + r.randf_range(-0.4, 0.4)
		var base: Vector3 = (pts[nseg - 2] as Vector3).lerp(top_p, r.randf_range(0.2, 1.0))
		var d := Vector3(cos(a), r.randf_range(0.5, 1.0), sin(a)).normalized()
		var ln := h * r.randf_range(0.2, 0.3)
		var tip := base + d * ln
		_tube(st, [base, base + d * ln * 0.5 + Vector3(0, ln * 0.08, 0), tip], [r0 * 0.34, r0 * 0.22, r0 * 0.1], 5)
		tips.append(tip)
	var trunk := st.commit()
	var sc := SurfaceTool.new()
	sc.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tp in tips:
		for j in 2:
			var s := h * r.randf_range(0.09, 0.14)
			var white := Color(0.86, 0.85, 0.82) if j == 0 else Color(0.78, 0.79, 0.76)
			_blob(sc, (tp as Vector3) + Vector3(r.randf_range(-1, 1) * s, r.randf_range(-0.3, 0.6) * s, r.randf_range(-1, 1) * s),
				Vector3(s * 1.35, s * 0.8, s * 1.25), r, white)
	return [trunk, sc.commit()]


## A short stretch of crop row: crossed cards with ragged, spiky tops, dark
## at the foot and lighter at the tips, 2.4 m of row per instance.
func _crop(r: RandomNumberGenerator, h: float, c0: Color, c1: Color, _blades: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in 6:
		var base := Vector3(-1.1 + p * 0.44 + r.randf_range(-0.1, 0.1), 0, r.randf_range(-0.1, 0.1))
		var hh := h * r.randf_range(0.65, 1.1)
		for q in 2:
			var a := r.randf() * PI + q * PI * 0.5
			var d := Vector3(cos(a), 0, sin(a)) * 0.28
			var k := r.randf_range(0.8, 1.1)
			var top := Color(c1.r * k, c1.g * k, c1.b * k)
			var mid := c0.lerp(top, 0.55)
			var v0 := hh * 0.5
			var pts := [base - d, base + d, base + d * 0.9 + Vector3(0, v0, 0), base - d * 0.9 + Vector3(0, v0, 0)]
			for idx in [0, 1, 2, 0, 2, 3]:
				st.set_color(c0 if idx < 2 else mid)
				st.set_normal(Vector3.UP)
				st.add_vertex(pts[idx])
			for sp in 3:
				var u0 := -0.9 + sp * 0.6
				var a0: Vector3 = base + d * u0 + Vector3(0, v0, 0)
				var a1: Vector3 = base + d * (u0 + 0.6) + Vector3(0, v0, 0)
				var tip: Vector3 = base + d * (u0 + 0.3 + r.randf_range(-0.2, 0.2)) + Vector3(r.randf_range(-0.06, 0.06), hh * r.randf_range(0.8, 1.0), r.randf_range(-0.06, 0.06))
				for v in [[a0, mid], [a1, mid], [tip, top]]:
					st.set_color(v[1])
					st.set_normal(Vector3.UP)
					st.add_vertex(v[0])
	return st.commit()


## A patch of small flower heads on short stems (one colour per mesh).
func _flowers(r: RandomNumberGenerator, col: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stem := Color(0.16, 0.32, 0.1)
	for i in 14:
		var p := Vector3(r.randf_range(-1.2, 1.2), 0, r.randf_range(-1.2, 1.2))
		var hh := r.randf_range(0.18, 0.45)
		var top := p + Vector3(0, hh, 0)
		for v in [[p + Vector3(-0.015, 0, 0), stem], [p + Vector3(0.015, 0, 0), stem], [top, stem]]:
			st.set_color(v[1])
			st.set_normal(Vector3.UP)
			st.add_vertex(v[0])
		var s := r.randf_range(0.11, 0.18)
		var k := r.randf_range(0.85, 1.1)
		var cc := Color(col.r * k, col.g * k, col.b * k)
		for q in [[Vector3(-s, 0, 0), Vector3(0, 0, s), Vector3(s, 0, 0)], [Vector3(-s, 0, 0), Vector3(s, 0, 0), Vector3(0, 0, -s)]]:
			for v in q:
				st.set_color(cc)
				st.set_normal(Vector3.UP)
				st.add_vertex(top + (v as Vector3) + Vector3(0, 0.01, 0))
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


func add_tree(i: int, xf: Transform3D) -> void:
	add("trunk%d" % i, xf)
	add("crown%d" % i, xf)


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
			# the node sits at the cell centre so its visibility range is measured
			# from the plants, not from the world origin
			var centre := Vector3((k.x + 0.5) * CELL, 0.0, (k.y + 0.5) * CELL)
			centre.y = (xfs[0] as Transform3D).origin.y
			for i in xfs.size():
				var xf: Transform3D = xfs[i]
				xf.origin -= centre
				mm.set_instance_transform(i, xf)
			var mi := MultiMeshInstance3D.new()
			mi.position = centre
			mi.name = "%s_%d_%d" % [kind, k.x, k.y]
			mi.multimesh = mm
			mi.material_override = spec[1]
			if not spec[2]:
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.visibility_range_end = spec[3]
			mi.visibility_range_end_margin = 20.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			parent.add_child(mi)
