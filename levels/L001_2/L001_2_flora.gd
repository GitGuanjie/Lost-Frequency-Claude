extends RefCounted
## Level 1.2 vegetation: procedural vertex-coloured meshes (grass tufts, flowers,
## sunflowers, bluebonnet spikes, ferns, cacti, rose bushes, vine leaves) and
## MultiMesh scattering per 8 m bay so distant bays are culled by visibility range.
## No textures; colour comes from vertex and instance colours.

var mat_v: StandardMaterial3D        # vertex colour only
var mat_vi: StandardMaterial3D       # vertex x instance colour
var meshes: Dictionary = {}
var instances := 0
var tris := 0


func _init() -> void:
	mat_v = StandardMaterial3D.new()
	mat_v.vertex_color_use_as_albedo = true
	mat_v.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat_v.roughness = 0.85
	mat_v.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat_vi = mat_v.duplicate()
	var r := RandomNumberGenerator.new()
	r.seed = 12012
	meshes["tuft"] = _tuft(r, 9, 0.5)
	meshes["tall"] = _tuft(r, 12, 1.0)
	meshes["flower"] = _flower()
	meshes["sunflower"] = _sunflower()
	meshes["bluebonnet"] = _bluebonnet()
	meshes["fern"] = _fern(r)
	meshes["cactus"] = _cactus()
	meshes["leaf"] = _leaf()
	meshes["rose"] = _rose(r)


# ------------------------------------------------------------------ meshes

func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color, n := Vector3.UP) -> void:
	for pair in [[a, ca], [b, cb], [c, cc]]:
		st.set_color(pair[1])
		st.set_normal(n)
		st.add_vertex(pair[0])


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, c0: Color, c1: Color, n := Vector3.UP) -> void:
	_tri(st, a, b, c, c0, c0, c1, n)
	_tri(st, a, c, d, c0, c1, c1, n)


## Grass tuft: tapered, bent blades, dark at the root, lighter at the tip.
func _tuft(r: RandomNumberGenerator, blades: int, h: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var root := Color(0.04, 0.09, 0.025)
	for i in blades:
		var a := r.randf() * TAU
		var d := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-d.z, 0, d.x)
		var base := d * r.randf_range(0.0, 0.12)
		var hh := h * r.randf_range(0.55, 1.0)
		var w := r.randf_range(0.018, 0.03)
		var bend := d * hh * r.randf_range(0.15, 0.4)
		var mid := base + Vector3(0, hh * 0.55, 0) + bend * 0.35
		var tip := base + Vector3(0, hh, 0) + bend
		var tipc := Color(0.2, 0.36, 0.09).lerp(Color(0.42, 0.48, 0.2), r.randf() * 0.5)
		var midc := root.lerp(tipc, 0.55)
		_quad(st, base - side * w, base + side * w, mid + side * w * 0.7, mid - side * w * 0.7, root, midc)
		_tri(st, mid - side * w * 0.7, mid + side * w * 0.7, tip, midc, midc, tipc)
	return st.commit()


## A generic flower: a thin stem, five petals (white, tinted per instance), a centre.
func _flower() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stem := Color(0.18, 0.3, 0.12)
	var h := 0.5
	_quad(st, Vector3(-0.006, 0, 0), Vector3(0.006, 0, 0), Vector3(0.006, h, 0), Vector3(-0.006, h, 0), stem, stem)
	_quad(st, Vector3(0, 0, -0.006), Vector3(0, 0, 0.006), Vector3(0, h, 0.006), Vector3(0, h, -0.006), stem, stem)
	var c := Vector3(0, h, 0)
	var white := Color(1, 1, 1)
	for i in 5:
		var a0 := TAU * float(i) / 5.0
		var p1 := c + Vector3(cos(a0 - 0.45) * 0.07, 0.012, sin(a0 - 0.45) * 0.07)
		var p2 := c + Vector3(cos(a0) * 0.1, 0.035, sin(a0) * 0.1)
		var p3 := c + Vector3(cos(a0 + 0.45) * 0.07, 0.012, sin(a0 + 0.45) * 0.07)
		_tri(st, c + Vector3(0, 0.01, 0), p1, p2, white, white, white)
		_tri(st, c + Vector3(0, 0.01, 0), p2, p3, white, white, white)
	var core := Color(0.95, 0.85, 0.3)
	for i in 5:
		var a := TAU * float(i) / 5.0
		var b := TAU * float(i + 1) / 5.0
		_tri(st, c + Vector3(0, 0.03, 0), c + Vector3(cos(a), 1.0, sin(a)) * 0.02 + Vector3(0, 0.0, 0), c + Vector3(cos(b), 1.0, sin(b)) * 0.02, core, core, core)
	return st.commit()


## A sunflower: tall stem, two leaves, a big tilted head.
func _sunflower() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stem := Color(0.16, 0.3, 0.08)
	var h := 1.75
	_quad(st, Vector3(-0.02, 0, 0), Vector3(0.02, 0, 0), Vector3(0.015, h, 0), Vector3(-0.015, h, 0), stem, stem)
	_quad(st, Vector3(0, 0, -0.02), Vector3(0, 0, 0.02), Vector3(0, h, 0.015), Vector3(0, h, -0.015), stem, stem)
	var leaf := Color(0.12, 0.28, 0.07)
	for s in [-1.0, 1.0]:
		var b := Vector3(0, 0.7 + 0.25 * s, 0)
		_quad(st, b, b + Vector3(s * 0.18, 0.1, 0.08), b + Vector3(s * 0.38, 0.0, 0.0), b + Vector3(s * 0.18, 0.05, -0.08), leaf, leaf.lightened(0.15))
	var c := Vector3(0, h, 0.04)
	var face := Basis(Vector3(1, 0, 0), deg_to_rad(-12.0))
	var petal := Color(0.98, 0.78, 0.08)
	var seed_c := Color(0.22, 0.12, 0.04)
	for i in 18:
		var a := TAU * float(i) / 18.0
		var p1 := c + face * Vector3(cos(a - 0.12), sin(a - 0.12), 0) * 0.13
		var p2 := c + face * Vector3(cos(a), sin(a), 0.02) * 0.27
		var p3 := c + face * Vector3(cos(a + 0.12), sin(a + 0.12), 0) * 0.13
		_tri(st, p1, p2, p3, petal, petal.lightened(0.1), petal, (face * Vector3(0, 0, 1) + Vector3.UP * 1.5).normalized())
	for i in 12:
		var a := TAU * float(i) / 12.0
		var b := TAU * float(i + 1) / 12.0
		_tri(st, c + face * Vector3(0, 0, 0.03), c + face * Vector3(cos(a), sin(a), 0.01) * 0.14, c + face * Vector3(cos(b), sin(b), 0.01) * 0.14, seed_c, seed_c, seed_c, (face * Vector3(0, 0, 1) + Vector3.UP * 1.5).normalized())
	return st.commit()


## Bluebonnet: a short stem with a spike of blue-violet florets and a white tip.
func _bluebonnet() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var stem := Color(0.16, 0.28, 0.12)
	_quad(st, Vector3(-0.008, 0, 0), Vector3(0.008, 0, 0), Vector3(0.006, 0.42, 0), Vector3(-0.006, 0.42, 0), stem, stem)
	var blue := Color(0.16, 0.22, 0.75)
	for j in 7:
		var y := 0.2 + float(j) * 0.035
		var rr := 0.045 * (1.0 - float(j) / 9.0)
		var col := Color(0.95, 0.95, 0.98) if j == 6 else blue.lerp(Color(0.38, 0.3, 0.8), float(j % 2) * 0.5)
		for i in 4:
			var a := TAU * float(i) / 4.0 + float(j) * 0.7
			var p := Vector3(cos(a), 0, sin(a)) * rr + Vector3(0, y, 0)
			_tri(st, Vector3(0, y - 0.01, 0), p + Vector3(0, 0.02, 0), p + Vector3(-sin(a), 0, cos(a)) * 0.02, col, col, col)
	return st.commit()


func _fern(r: RandomNumberGenerator) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c0 := Color(0.05, 0.16, 0.05)
	var c1 := Color(0.18, 0.4, 0.12)
	for i in 9:
		var a := TAU * float(i) / 9.0 + r.randf() * 0.3
		var d := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-d.z, 0, d.x)
		var ln := r.randf_range(0.7, 1.1)
		var mid := d * ln * 0.5 + Vector3(0, 0.55, 0)
		var tip := d * ln + Vector3(0, 0.25, 0)
		_quad(st, Vector3.ZERO, side * 0.02, mid + side * 0.12, mid - side * 0.12, c0, c1)
		_tri(st, mid - side * 0.12, mid + side * 0.12, tip, c1, c1, c1.lightened(0.15))
	return st.commit()


## A ribbed columnar cactus with two arms (a desert plant beside the ferns).
func _cactus() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var g0 := Color(0.12, 0.3, 0.14)
	var g1 := Color(0.2, 0.42, 0.2)
	var parts := [[Vector3.ZERO, 0.16, 1.6], [Vector3(0.28, 0.6, 0), 0.09, 0.6], [Vector3(-0.26, 0.85, 0), 0.08, 0.45]]
	for pt in parts:
		var o: Vector3 = pt[0]
		var rad: float = pt[1]
		var h: float = pt[2]
		for i in 8:
			var a := TAU * float(i) / 8.0
			var b := TAU * float(i + 1) / 8.0
			var pa := Vector3(cos(a), 0, sin(a)) * rad
			var pb := Vector3(cos(b), 0, sin(b)) * rad * 0.82
			var n := Vector3(cos((a + b) * 0.5), 0, sin((a + b) * 0.5))
			_quad(st, o + pa, o + pb, o + pb + Vector3(0, h, 0), o + pa + Vector3(0, h, 0), g0 if i % 2 == 0 else g1, g1, n)
			_tri(st, o + Vector3(0, h + rad * 0.6, 0), o + pa + Vector3(0, h, 0), o + pb + Vector3(0, h, 0), g1, g1, g1)
	# arm elbows
	_quad(st, Vector3(0.1, 0.55, -0.06), Vector3(0.1, 0.55, 0.06), Vector3(0.3, 0.62, 0.06), Vector3(0.3, 0.62, -0.06), g0, g0)
	_quad(st, Vector3(-0.1, 0.8, -0.05), Vector3(-0.1, 0.8, 0.05), Vector3(-0.27, 0.86, 0.05), Vector3(-0.27, 0.86, -0.05), g0, g0)
	return st.commit()


func _leaf() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c0 := Color(0.08, 0.22, 0.06)
	var c1 := Color(0.22, 0.42, 0.13)
	_quad(st, Vector3(0, 0, 0), Vector3(0.05, 0.0, 0.05), Vector3(0, 0, 0.16), Vector3(-0.05, 0.0, 0.05), c0, c1, Vector3.UP)
	return st.commit()


## A rose bush: a mound of leaves with a few red heads.
func _rose(r: RandomNumberGenerator) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lc := Color(0.07, 0.2, 0.06)
	for i in 34:
		var a := r.randf() * TAU
		var y := r.randf_range(0.15, 0.8)
		var rad := (0.5 - absf(y - 0.45) * 0.6) * r.randf_range(0.6, 1.0)
		var p := Vector3(cos(a) * rad, y, sin(a) * rad)
		var d := Vector3(cos(a), r.randf_range(-0.3, 0.5), sin(a)).normalized()
		var side := d.cross(Vector3.UP).normalized() * 0.06
		_quad(st, p, p + side, p + d * 0.16, p - side, lc, lc.lightened(0.2), (d + Vector3.UP).normalized())
	var red := Color(0.62, 0.03, 0.06)
	for i in 7:
		var a := r.randf() * TAU
		var p := Vector3(cos(a) * 0.38, r.randf_range(0.5, 0.85), sin(a) * 0.38)
		for j in 6:
			var b := TAU * float(j) / 6.0
			var e := TAU * float(j + 1) / 6.0
			_tri(st, p + Vector3(0, 0.07, 0), p + Vector3(cos(b), 0, sin(b)) * 0.06, p + Vector3(cos(e), 0, sin(e)) * 0.06, red.lightened(0.15), red, red)
	return st.commit()


# ------------------------------------------------------------------ scatter

## One MultiMeshInstance3D for a list of transforms (and optional colours).
func scatter(parent: Node3D, kind: String, xfs: Array, colors: Array = [], vis_end := 48.0) -> MultiMeshInstance3D:
	if xfs.is_empty():
		return null
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = not colors.is_empty()
	mm.mesh = meshes[kind]
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
		if mm.use_colors:
			mm.set_instance_color(i, colors[i])
	var mi := MultiMeshInstance3D.new()
	mi.name = "Flora_" + kind
	mi.multimesh = mm
	mi.material_override = mat_vi if mm.use_colors else mat_v
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = vis_end
	mi.visibility_range_end_margin = 6.0
	mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	parent.add_child(mi)
	instances += xfs.size()
	tris += xfs.size() * (meshes[kind] as ArrayMesh).surface_get_array_index_len(0) / 3 if (meshes[kind] as ArrayMesh).surface_get_array_index_len(0) > 0 else xfs.size() * (meshes[kind] as ArrayMesh).surface_get_array_len(0) / 3
	return mi


static func xf(p: Vector3, yaw: float, s: float, tilt := 0.0) -> Transform3D:
	var b := Basis(Vector3.UP, yaw).scaled(Vector3(s, s, s))
	if tilt != 0.0:
		b = Basis(Vector3(1, 0, 0), tilt) * b
	return Transform3D(b, p)
