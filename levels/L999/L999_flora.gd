extends RefCounted
## Level 999 trees: procedural meshes, no textures, no sway shader (the page:
## despite the constant wind, the trees "do not move or sway").
## - old forest trees: tall straight trunks with buttress fins at the base,
##   bare for most of their height, a few limbs and a high, heavy crown that
##   towers toward the stars (only the oldest trees survive the soil);
## - grey palm trees on the beach: curved ringed trunk, drooping fronds.
## Trunks use a MatLib bark preset (metre UVs, vertical grooves); crowns and
## fronds are vertex-coloured. Instances go into MultiMeshes per 48 m cell.

const CELL := 48.0

var bark_mat: Material
var leaf_mat: StandardMaterial3D
var meshes: Dictionary = {}       # name -> [trunk ArrayMesh, crown ArrayMesh]
var cells: Dictionary = {}        # Vector2i -> {kind: [xf...]}
var count := 0


func _init() -> void:
	MatLib.define("l999_bark", {"albedo_a": Color(0.1, 0.1, 0.1), "albedo_b": Color(0.06, 0.06, 0.06), "pattern": 2,
		"pattern_scale": Vector2(0.11, 1.0), "pattern_color": Color(0.03, 0.03, 0.03), "pattern_strength": 0.6,
		"noise_scale": 1.4, "bump_strength": 1.4, "roughness_a": 0.95, "roughness_b": 1.0}, "concrete")
	MatLib.define("l999_palm", {"albedo_a": Color(0.24, 0.24, 0.24), "albedo_b": Color(0.17, 0.17, 0.17), "pattern": 2,
		"pattern_scale": Vector2(0.18, 1.0), "uv_rotate": 1.5708, "pattern_color": Color(0.1, 0.1, 0.1), "pattern_strength": 0.55,
		"noise_scale": 2.0, "bump_strength": 1.0}, "concrete")
	bark_mat = MatLib.get_mat("l999_bark")
	leaf_mat = StandardMaterial3D.new()
	leaf_mat.vertex_color_use_as_albedo = true
	leaf_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaf_mat.roughness = 0.95
	leaf_mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	var r := RandomNumberGenerator.new()
	r.seed = 99920
	for i in 4:
		meshes["old%d" % i] = _old_tree(r, 19.0 + i * 3.0, 0.42 + i * 0.07)
	for i in 3:
		meshes["palm%d" % i] = _palm(r, 7.5 + i * 2.0)


# ---------------------------------------------------------------- pieces

## Tapered tube along a polyline with radii; u = arc length around, v = height.
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
			ring.append([p + n * float(radii[i]), n, Vector2(a * float(radii[i]) * 1.0, p.y)])
		rings.append(ring)
	for i in range(1, rings.size()):
		for k in sides:
			var q := [rings[i - 1][k], rings[i - 1][k + 1], rings[i][k + 1], rings[i][k]]
			for idx in [0, 2, 1, 0, 3, 2]:
				var v: Array = q[idx]
				st.set_normal(v[1])
				st.set_uv(v[2])
				st.add_vertex(v[0])


## A triangle whose front face (clockwise in Godot) looks along n.
func _ftri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3) -> void:
	if (b - a).cross(c - a).dot(n) > 0.0:
		var t := b
		b = c
		c = t
	for v in [a, b, c]:
		st.set_normal(n)
		st.set_uv(Vector2(v.x + v.z, v.y))
		st.add_vertex(v)


## An irregular foliage mass (displaced octahedron, subdivided once).
func _blob(st: SurfaceTool, c: Vector3, s: Vector3, r: RandomNumberGenerator, shade: float) -> void:
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
		pts.append(c + (v as Vector3) * s * r.randf_range(0.72, 1.18))
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
			var g := (0.05 + 0.07 * up) * shade * r.randf_range(0.85, 1.1)
			st.set_color(Color(g, g, g))
			st.set_normal((n + (vv - c).normalized()).normalized())
			st.add_vertex(vv)


func _old_tree(r: RandomNumberGenerator, h: float, r0: float) -> Array:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# main trunk: slight wander, strong taper
	var pts: Array = []
	var rad: Array = []
	var off := Vector3.ZERO
	var nseg := 7
	for i in nseg + 1:
		var t := float(i) / nseg
		if i > 0:
			off += Vector3(r.randf_range(-0.25, 0.25), 0, r.randf_range(-0.25, 0.25))
		pts.append(Vector3(off.x, t * h * 0.82 - 0.3, off.z))
		rad.append(r0 * (1.0 - t * 0.62) * (1.35 if i == 0 else 1.0))
	_tube(st, pts, rad, 9)
	# buttress fins at the base
	var fins := r.randi_range(4, 6)
	for k in fins:
		var a := TAU * k / fins + r.randf_range(-0.3, 0.3)
		var d := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-d.z, 0, d.x) * 0.07
		var out := r0 * r.randf_range(1.7, 2.5)
		var top := r0 * r.randf_range(1.8, 3.2)
		var p0 := d * r0 * 0.6 + Vector3(0, top, 0)
		var p1 := d * out + Vector3(0, -0.15, 0)
		var p2 := d * r0 * 0.6 + Vector3(0, -0.15, 0)
		for s in [-1.0, 1.0]:
			var n: Vector3 = Vector3(-d.z, 0, d.x) * s
			_ftri(st, p0 + side * s, p1 + side * s, p2 + side * s, n)
		var tn := (d + Vector3.UP).normalized()
		_ftri(st, p0 - side, p1 - side, p1 + side, tn)
		_ftri(st, p0 - side, p1 + side, p0 + side, tn)
	# limbs from the upper trunk
	var top_p: Vector3 = pts[pts.size() - 1]
	var tips: Array = [top_p + Vector3(0, h * 0.12, 0)]
	var limbs := r.randi_range(3, 5)
	for k in limbs:
		var a := TAU * k / limbs + r.randf_range(-0.4, 0.4)
		var base: Vector3 = (pts[nseg - 1] as Vector3).lerp(top_p, r.randf_range(0.0, 0.9))
		var d := Vector3(cos(a), r.randf_range(0.7, 1.3), sin(a)).normalized()
		var ln := h * r.randf_range(0.16, 0.26)
		var mid := base + d * ln * 0.5 + Vector3(0, ln * 0.1, 0)
		var tip := base + d * ln
		_tube(st, [base, mid, tip], [r0 * 0.3, r0 * 0.2, r0 * 0.1], 5)
		tips.append(tip)
	var trunk := st.commit()
	# crown: heavy, flat-bottomed masses around the limb tips
	var sc := SurfaceTool.new()
	sc.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tp in tips:
		var c: Vector3 = tp
		for j in 4:
			var s := h * r.randf_range(0.06, 0.11)
			_blob(sc, c + Vector3(r.randf_range(-1, 1) * s * 1.2, r.randf_range(-0.4, 0.8) * s, r.randf_range(-1, 1) * s * 1.2),
				Vector3(s * 1.3, s * 0.7, s * 1.2), r, 1.0 if j < 2 else 0.75)
	return [trunk, sc.commit()]


func _palm(r: RandomNumberGenerator, h: float) -> Array:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array = []
	var rad: Array = []
	var lean := r.randf_range(1.2, 2.6)
	for i in 9:
		var t := float(i) / 8.0
		pts.append(Vector3(lean * t * t, t * h - 0.2, 0))
		rad.append(lerpf(0.24, 0.15, t))
	_tube(st, pts, rad, 7)
	var trunk := st.commit()
	var sc := SurfaceTool.new()
	sc.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top: Vector3 = pts[8]
	var fronds := r.randi_range(9, 12)
	for k in fronds:
		var a := TAU * k / fronds + r.randf_range(-0.2, 0.2)
		var d := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-d.z, 0, d.x)
		var ln := r.randf_range(2.8, 3.8)
		var lift := r.randf_range(0.4, 1.2)
		var prev := top
		var n := 7
		for j in range(1, n + 1):
			var t := float(j) / n
			var p := top + d * ln * t + Vector3(0, lift * sin(t * PI * 0.7) - t * t * ln * 0.75, 0)
			var w := 0.55 * sin(t * PI) + 0.05
			var g0 := 0.06 + 0.03 * t
			var col := Color(g0, g0, g0)
			# leaflets: two drooping halves forming a shallow V
			for s in [-1.0, 1.0]:
				var o: Vector3 = side * w * s + Vector3(0, -w * 0.35, 0)
				for v in [prev, p, p + o, prev, p + o, prev + o * 0.8]:
					sc.set_color(col)
					sc.set_normal(Vector3.UP)
					sc.add_vertex(v)
			prev = p
	# a dark knot of old frond bases at the crown
	_blob(sc, top + Vector3(0, -0.2, 0), Vector3(0.45, 0.4, 0.45), r, 0.6)
	return [trunk, sc.commit()]


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


func commit(parent: Node3D) -> void:
	for k in cells.keys():
		var c: Dictionary = cells[k]
		for kind in c.keys():
			var xfs: Array = c[kind]
			var pair: Array = meshes[kind]
			var is_palm := (kind as String).begins_with("palm")
			for part in 2:
				var mm := MultiMesh.new()
				mm.transform_format = MultiMesh.TRANSFORM_3D
				mm.mesh = pair[part]
				mm.instance_count = xfs.size()
				for i in xfs.size():
					mm.set_instance_transform(i, xfs[i])
				var mi := MultiMeshInstance3D.new()
				mi.name = "%s_%s_%d_%d" % [kind, "trunk" if part == 0 else "crown", k.x, k.y]
				mi.multimesh = mm
				mi.material_override = (MatLib.get_mat("l999_palm") if is_palm else bark_mat) if part == 0 else leaf_mat
				# canopy never darkens the level (constant aura): no tree shadows
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				mi.visibility_range_end = 320.0
				parent.add_child(mi)
