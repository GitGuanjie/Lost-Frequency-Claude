extends RefCounted
## Level 23 growth: procedural meshes and MultiMesh scattering (no textures).
## Bark-grooved trunks (surface conifers, aspens and broadleaf hardwoods; the
## gnarled trunks that grow into the glow rooms; the downward trees of the
## core), leaf masses, glowing fungi, the Gardener's Sorries (bioluminescent
## specks with hanging silk threads) and a glow shader fed by instance colour.

const GLOW := """shader_type spatial;
render_mode unshaded, cull_disabled;
uniform float energy = 2.2;
void fragment() { ALBEDO = COLOR.rgb * energy * mix(0.3, 1.0, UV.y); }"""

var bark: Material
var pale: Material
var leaf: StandardMaterial3D
var glow: ShaderMaterial
var glow_soft: ShaderMaterial
var meshes: Dictionary = {}
var instances := 0


func _init() -> void:
	MatLib.define("l23_bark", {"albedo_a": Color(0.11, 0.075, 0.05), "albedo_b": Color(0.07, 0.05, 0.035), "pattern": 2,
		"pattern_scale": Vector2(0.14, 1.0), "pattern_color": Color(0.035, 0.025, 0.02), "pattern_strength": 0.7,
		"noise_scale": 1.2, "bump_strength": 1.6, "stain_amount": 0.5, "stain_color": Color(0.05, 0.09, 0.04), "stain_scale": 0.5}, "concrete")
	MatLib.define("l23_aspen", {"albedo_a": Color(0.55, 0.55, 0.5), "albedo_b": Color(0.45, 0.45, 0.4), "pattern": 5,
		"pattern_scale": Vector2(0.3, 0.6), "pattern_color": Color(0.08, 0.08, 0.07), "pattern_strength": 0.5, "noise_scale": 2.0}, "plaster")
	bark = MatLib.get_mat("l23_bark")
	pale = MatLib.get_mat("l23_aspen")
	leaf = StandardMaterial3D.new()
	leaf.vertex_color_use_as_albedo = true
	leaf.cull_mode = BaseMaterial3D.CULL_DISABLED
	leaf.roughness = 0.9
	glow = ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = GLOW
	glow.shader = sh
	glow_soft = ShaderMaterial.new()
	glow_soft.shader = sh
	glow_soft.set_shader_parameter("energy", 0.75)
	var r := RandomNumberGenerator.new()
	r.seed = 23023
	meshes["gnarl"] = _trunk(r, 1.0, 0.5, 9, 0.35)          # unit height, scaled in y
	meshes["root"] = _trunk(r, 1.0, 0.12, 6, 0.18)
	meshes["conifer"] = _trunk(r, 34.0, 0.75, 8, 0.12)
	meshes["aspen"] = _trunk(r, 22.0, 0.22, 6, 0.1)
	meshes["hardwood"] = _trunk(r, 26.0, 0.95, 9, 0.2)
	meshes["cones"] = _cones(r)
	meshes["crown"] = _crown(r, 5, Color(0.035, 0.07, 0.03))
	meshes["aspen_crown"] = _crown(r, 3, Color(0.08, 0.1, 0.035))
	meshes["bush"] = _crown(r, 4, Color(0.03, 0.08, 0.035))
	meshes["glowbush"] = _crown(r, 4, Color(0.75, 0.75, 0.75))
	meshes["mushroom"] = _mushroom()
	var sp := SphereMesh.new()
	sp.radius = 0.025
	sp.height = 0.05
	sp.radial_segments = 6
	sp.rings = 3
	meshes["speck"] = sp
	var th := BoxMesh.new()
	th.size = Vector3(0.006, 1.0, 0.006)
	meshes["thread"] = th


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
			ring.append([p + n * float(radii[i]), n, Vector2(a * 0.6, p.y)])
		rings.append(ring)
	for i in range(1, rings.size()):
		for k in sides:
			var q := [rings[i - 1][k], rings[i - 1][k + 1], rings[i][k + 1], rings[i][k]]
			for idx in [0, 2, 1, 0, 3, 2]:
				var v: Array = q[idx]
				st.set_normal(v[1])
				st.set_uv(v[2])
				st.add_vertex(v[0])


## Trunk with a flared, rooty base and a wandering axis (local base at 0).
func _trunk(r: RandomNumberGenerator, h: float, r0: float, sides: int, wander: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array = []
	var rad: Array = []
	var off := Vector3.ZERO
	var n := 9
	for i in n + 1:
		var t := float(i) / n
		if i > 0:
			off += Vector3(r.randf_range(-1, 1), 0, r.randf_range(-1, 1)) * wander * h / n
		pts.append(Vector3(off.x, t * h - 0.05 * h if i == 0 else t * h, off.z))
		rad.append(r0 * (1.0 - t * 0.55) * (1.0 + 0.8 * pow(1.0 - t, 6.0)))
	_tube(st, pts, rad, sides)
	return st.commit()


func _blob(st: SurfaceTool, c: Vector3, s: Vector3, r: RandomNumberGenerator, col: Color) -> void:
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
		for vi in f:
			var vv: Vector3 = pts[vi]
			var up := clampf((vv.y - c.y) / s.y * 0.5 + 0.5, 0.0, 1.0)
			st.set_color(col * (0.7 + 0.6 * up) * r.randf_range(0.85, 1.15))
			st.set_uv(Vector2(0, 1))
			st.set_normal((vv - c).normalized())
			st.add_vertex(vv)


func _crown(r: RandomNumberGenerator, n: int, col: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		var a := TAU * i / n
		var c := Vector3(cos(a) * 1.1, r.randf_range(-0.4, 0.6), sin(a) * 1.1) * (0.0 if i == 0 else 1.0)
		_blob(st, c, Vector3(1.6, 1.0, 1.5) * r.randf_range(0.8, 1.2), r, col)
	return st.commit()


## Conifer crown: stacked drooping tiers (Douglas fir / cedar / redwood look).
func _cones(r: RandomNumberGenerator) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tiers := 7
	for t in tiers:
		var y0 := 14.0 + t * 2.8
		var rad := 4.2 * (1.0 - float(t) / tiers) + 0.6
		var segs := 9
		var col := Color(0.02, 0.05, 0.03) * r.randf_range(0.8, 1.3)
		for k in segs:
			var a0 := TAU * k / segs
			var a1 := TAU * (k + 1) / segs
			var tip := Vector3(0, y0 + 3.2, 0)
			var p0 := Vector3(cos(a0) * rad, y0, sin(a0) * rad)
			var p1 := Vector3(cos(a1) * rad, y0, sin(a1) * rad)
			for v in [tip, p0, p1]:
				st.set_color(col * (1.3 if v == tip else 0.8))
				st.set_normal((v - Vector3(0, y0 + 1.0, 0)).normalized())
				st.add_vertex(v)
	return st.commit()


## A glowing mushroom: thin stalk and a domed cap (vertex colour: stalk dim).
func _mushroom() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 7
	for k in segs:
		var a0 := TAU * k / segs
		var a1 := TAU * (k + 1) / segs
		var s0 := Vector3(cos(a0), 0, sin(a0)) * 0.025
		var s1 := Vector3(cos(a1), 0, sin(a1)) * 0.025
		var top := Vector3(0, 0.22, 0)
		for v in [s0, s1 + top, s1, s0, s0 + top, s1 + top]:
			st.set_uv(Vector2(0, 0))
			st.add_vertex(v)
		var c0 := Vector3(cos(a0), 0, sin(a0)) * 0.12 + Vector3(0, 0.2, 0)
		var c1 := Vector3(cos(a1), 0, sin(a1)) * 0.12 + Vector3(0, 0.2, 0)
		for v in [Vector3(0, 0.3, 0), c0, c1, Vector3(0, 0.19, 0), c1, c0]:
			st.set_uv(Vector2(0, 1))
			st.add_vertex(v)
	return st.commit()


func mm(parent: Node3D, kind: String, xfs: Array, mat: Material, colors: Array = [], vis := 0.0, shadows := false) -> MultiMeshInstance3D:
	if xfs.is_empty():
		return null
	var m := MultiMesh.new()
	m.transform_format = MultiMesh.TRANSFORM_3D
	m.use_colors = not colors.is_empty()
	m.mesh = meshes[kind]
	m.instance_count = xfs.size()
	for i in xfs.size():
		m.set_instance_transform(i, xfs[i])
		if m.use_colors:
			m.set_instance_color(i, colors[i])
	var mi := MultiMeshInstance3D.new()
	mi.name = "MM_" + kind
	mi.multimesh = m
	mi.material_override = mat
	if not shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if vis > 0.0:
		mi.visibility_range_end = vis
	parent.add_child(mi)
	instances += xfs.size()
	return mi


static func xf(p: Vector3, yaw: float, s: Vector3) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, yaw).scaled(s), p)
