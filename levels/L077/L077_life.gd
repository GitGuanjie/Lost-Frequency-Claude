extends RefCounted
## Level 77 living things and forest matter, all procedural meshes:
## - deciduous forest trees (tall boles, broad crowns); their shader is darkened
##   from the hills so the forest reads as nightbound (page: "the surrounding
##   forest appears nightbound");
## - Shenandoah Sheep (head-up and grazing variants) for the flocks;
## - Nguithr'xurh sub-clusters: silk sheets slung between trunks, a dense funnel
##   and egg sacs (page caption: "A small sub-cluster, possibly a hatchery");
## - detritus heaps (litter mound + fallen boles) for the 6 km no-clip.

var tree_mat: ShaderMaterial
var crown_mat: ShaderMaterial
var wool_mat: StandardMaterial3D
var silk_mat: ShaderMaterial
var sac_mat: StandardMaterial3D
var mound_mat: StandardMaterial3D
var glint_mat: StandardMaterial3D
var trees: Array = []          # [trunk, crown] pairs
var sheep_up: ArrayMesh
var sheep_down: ArrayMesh
var silk_mesh: ArrayMesh
var mound_mesh: SphereMesh
var sac_mesh: SphereMesh
var glint_mesh: SphereMesh
var tuft: ArrayMesh
var tuft_mat: StandardMaterial3D

const TREE_SH := """
shader_type spatial;
render_mode diffuse_burley, cull_disabled;
uniform float dark_k = 0.25;
uniform bool crown = false;
varying vec3 wp;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec3 c;
	if (crown) {
		float l = vn(wp.xz * 1.7 + wp.y * 0.9) * 0.6 + vn(wp.xy * 4.0) * 0.4;
		c = COLOR.rgb * (0.65 + 0.7 * l);
	} else {
		float g = vn(vec2(UV.x * 9.0, UV.y * 0.7)) * 0.6 + vn(vec2(UV.x * 30.0, UV.y * 3.0)) * 0.4;
		c = mix(vec3(0.07, 0.06, 0.05), vec3(0.15, 0.13, 0.1), g);
		c = mix(c, vec3(0.06, 0.09, 0.03), smoothstep(0.55, 0.85, vn(UV * 2.0)) * smoothstep(3.0, 0.0, UV.y) * 0.7);
	}
	ALBEDO = c * dark_k;
	ROUGHNESS = 0.95;
}
"""

const SILK_SH := """
shader_type spatial;
render_mode cull_disabled, depth_draw_never, diffuse_lambert, specular_disabled;
uniform float dark_k = 0.25;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
void fragment() {
	float strands = smoothstep(0.55, 0.95, vn(UV * vec2(40.0, 6.0))) + smoothstep(0.6, 0.97, vn(UV * vec2(7.0, 38.0) + 3.0));
	float body = vn(UV * 5.0);
	float edge = smoothstep(0.0, 0.12, UV.x) * smoothstep(1.0, 0.88, UV.x) * smoothstep(0.0, 0.1, UV.y) * smoothstep(1.0, 0.85, UV.y);
	ALBEDO = vec3(0.62, 0.62, 0.58) * mix(0.6, 1.0, dark_k);
	ALPHA = clamp((0.22 + 0.35 * body + 0.5 * strands) * edge * COLOR.a, 0.0, 0.85);
	ROUGHNESS = 0.6;
}
"""


func _init() -> void:
	var sh := Shader.new()
	sh.code = TREE_SH
	tree_mat = ShaderMaterial.new()
	tree_mat.shader = sh
	crown_mat = ShaderMaterial.new()
	crown_mat.shader = sh
	crown_mat.set_shader_parameter("crown", true)
	var ss := Shader.new()
	ss.code = SILK_SH
	silk_mat = ShaderMaterial.new()
	silk_mat.shader = ss
	wool_mat = StandardMaterial3D.new()
	wool_mat.vertex_color_use_as_albedo = true
	wool_mat.roughness = 1.0
	sac_mat = StandardMaterial3D.new()
	sac_mat.albedo_color = Color(0.5, 0.48, 0.4)
	sac_mat.roughness = 0.7
	sac_mat.subsurf_scatter_enabled = false
	mound_mat = StandardMaterial3D.new()
	mound_mat.albedo_color = Color(0.11, 0.07, 0.035)
	mound_mat.roughness = 1.0
	glint_mat = StandardMaterial3D.new()
	glint_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glint_mat.albedo_color = Color(0.9, 0.85, 0.6)
	var r := RandomNumberGenerator.new()
	r.seed = 77020
	for i in 5:
		trees.append(_tree(r, 15.0 + i * 2.6, 0.32 + i * 0.05))
	tuft = _tuft(r)
	tuft_mat = StandardMaterial3D.new()
	tuft_mat.vertex_color_use_as_albedo = true
	tuft_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	tuft_mat.roughness = 0.9
	sheep_up = _sheep(r, false)
	sheep_down = _sheep(r, true)
	silk_mesh = _sheet()
	mound_mesh = SphereMesh.new()
	mound_mesh.radius = 1.0
	mound_mesh.height = 2.0
	mound_mesh.radial_segments = 14
	mound_mesh.rings = 7
	sac_mesh = SphereMesh.new()
	sac_mesh.radius = 0.16
	sac_mesh.height = 0.36
	sac_mesh.radial_segments = 8
	sac_mesh.rings = 5
	glint_mesh = SphereMesh.new()
	glint_mesh.radius = 0.018
	glint_mesh.height = 0.036
	glint_mesh.radial_segments = 4
	glint_mesh.rings = 2


func set_dark(k: float) -> void:
	tree_mat.set_shader_parameter("dark_k", k)
	crown_mat.set_shader_parameter("dark_k", k)
	silk_mat.set_shader_parameter("dark_k", k)


# ---------------------------------------------------------------- mesh pieces

func _tube(st: SurfaceTool, pts: Array, radii: Array, sides: int) -> void:
	var rings: Array = []
	var vlen := 0.0
	for i in pts.size():
		var p: Vector3 = pts[i]
		if i > 0:
			vlen += p.distance_to(pts[i - 1])
		var t: Vector3 = ((pts[mini(i + 1, pts.size() - 1)] as Vector3) - (pts[maxi(i - 1, 0)] as Vector3)).normalized()
		var x := t.cross(Vector3.FORWARD if absf(t.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
		var z := t.cross(x).normalized()
		var ring: Array = []
		for k in sides + 1:
			var a := TAU * k / sides
			var n := x * cos(a) + z * sin(a)
			ring.append([p + n * float(radii[i]), n, Vector2(float(k) / sides, vlen)])
		rings.append(ring)
	for i in range(1, rings.size()):
		for k in sides:
			var q := [rings[i - 1][k], rings[i - 1][k + 1], rings[i][k + 1], rings[i][k]]
			for idx in [0, 2, 1, 0, 3, 2]:
				var v: Array = q[idx]
				st.set_normal(v[1])
				st.set_uv(v[2])
				st.add_vertex(v[0])


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
		pts.append(c + (v as Vector3) * s * r.randf_range(0.8, 1.15))
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
			var up := clampf((vv.y - c.y) / maxf(s.y, 0.01) * 0.5 + 0.5, 0.0, 1.0)
			st.set_color(col * (0.7 + 0.45 * up))
			st.set_normal((n + (vv - c).normalized()).normalized())
			st.add_vertex(vv)


## A tall deciduous forest tree: straight bole, a few rising limbs, a broad crown.
func _tree(r: RandomNumberGenerator, h: float, r0: float) -> Array:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array = []
	var rad: Array = []
	var off := Vector3.ZERO
	var lean := Vector3(r.randf_range(-1, 1), 0, r.randf_range(-1, 1)).normalized() * r.randf_range(0.0, 0.35)
	for i in 7:
		var t := float(i) / 6.0
		if i > 0:
			off += Vector3(r.randf_range(-0.3, 0.3), 0, r.randf_range(-0.3, 0.3)) + lean
		pts.append(Vector3(off.x, t * h * 0.62 - 0.4, off.z))
		rad.append(r0 * (1.0 - t * 0.55) * (1.6 if i == 0 else 1.0))
	_tube(st, pts, rad, 7)
	var top: Vector3 = pts[6]
	var tips: Array = [top + Vector3(0, h * 0.16, 0)]
	_tube(st, [top, top + Vector3(0, h * 0.16, 0)], [r0 * 0.45, r0 * 0.12], 5)
	var limbs := r.randi_range(4, 6)
	for k in limbs:
		var a := TAU * k / limbs + r.randf_range(-0.5, 0.5)
		var u := r.randf_range(0.45, 0.95)
		var base: Vector3 = (pts[3] as Vector3).lerp(top, (u - 0.45) / 0.5)
		var d := Vector3(cos(a), r.randf_range(0.35, 0.9), sin(a)).normalized()
		var ln := h * r.randf_range(0.2, 0.32)
		var mid := base + d * ln * 0.5 + Vector3(0, ln * 0.12, 0)
		var tip := base + d * ln + Vector3(0, ln * 0.2, 0)
		_tube(st, [base, mid, tip], [r0 * 0.3, r0 * 0.18, r0 * 0.07], 5)
		tips.append(tip)
		# a forked twig pair at the limb end
		for s in [-1.0, 1.0]:
			var tw := tip + Vector3(-d.z * s, 0.6, d.x * s) * ln * 0.25
			_tube(st, [mid, tw], [r0 * 0.1, r0 * 0.04], 3)
	var trunk := st.commit()
	var sc := SurfaceTool.new()
	sc.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tp in tips:
		var s := h * r.randf_range(0.11, 0.15)
		var col := Color(0.05, 0.1, 0.03).lerp(Color(0.075, 0.12, 0.035), r.randf())
		_blob(sc, (tp as Vector3) + Vector3(r.randf_range(-0.5, 0.5) * s, r.randf_range(-0.2, 0.4) * s, r.randf_range(-0.5, 0.5) * s),
			Vector3(s * 1.5, s * 0.85, s * 1.4), r, col)
	return [trunk, sc.commit()]


## A Shenandoah Sheep, ~1.3 m long, local +Z forward. Fleece is a lumpy off-white
## mass; face and legs are dark.
func _sheep(r: RandomNumberGenerator, grazing: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wool := Color(0.46, 0.44, 0.38)
	_blob(st, Vector3(0, 0.78, 0), Vector3(0.42, 0.36, 0.66), r, wool)
	_blob(st, Vector3(0, 0.9, -0.2), Vector3(0.36, 0.26, 0.4), r, wool * 1.05)
	_blob(st, Vector3(0, 0.88, 0.32), Vector3(0.32, 0.26, 0.32), r, wool * 0.95)
	var face := Color(0.035, 0.03, 0.028)
	var hp := Vector3(0, 0.36, 0.86) if grazing else Vector3(0, 0.98, 0.78)
	_blob(st, hp, Vector3(0.12, 0.13, 0.22), r, face)
	_blob(st, hp + Vector3(0, 0.1, -0.12), Vector3(0.16, 0.12, 0.13), r, wool * 0.9)
	for s in [-1.0, 1.0]:
		_blob(st, hp + Vector3(s * 0.15, 0.08, -0.06), Vector3(0.09, 0.03, 0.05), r, face)
	for lx in [-0.2, 0.2]:
		for lz in [-0.42, 0.4]:
			_blob(st, Vector3(lx, 0.24, lz), Vector3(0.05, 0.27, 0.05), r, face)
	if grazing:
		_blob(st, Vector3(0, 0.62, 0.62), Vector3(0.14, 0.2, 0.18), r, face)
	return st.commit()


## A tuft of zoysia/bluegrass blades (~0.3 m), for the near ground.
func _tuft(r: RandomNumberGenerator) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 24:
		var b := Vector3(r.randf_range(-0.45, 0.45), 0, r.randf_range(-0.45, 0.45))
		var a := r.randf() * TAU
		var side := Vector3(cos(a), 0, sin(a)) * 0.014
		var tip := b + Vector3(r.randf_range(-0.06, 0.06), r.randf_range(0.1, 0.2), r.randf_range(-0.06, 0.06))
		var col := Color(0.075, 0.14, 0.04).lerp(Color(0.1, 0.17, 0.05), r.randf())
		for v in [b - side, tip, b + side]:
			st.set_color(col * (0.8 if v != tip else 1.1))
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	return st.commit()


## One silk sheet: a sagging, slightly twisted quad strip (UV 0..1 both ways).
func _sheet() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nu := 8
	var nv := 5
	var grid: Array = []
	for j in nv + 1:
		var row: Array = []
		for i in nu + 1:
			var u := float(i) / nu
			var v := float(j) / nv
			var sag := sin(u * PI) * 0.35 * (1.0 - v * 0.5)
			row.append(Vector3(u - 0.5, v - 0.5 - sag, 0.08 * sin(u * 5.0 + v * 3.0)))
		grid.append(row)
	for j in nv:
		for i in nu:
			var q := [[grid[j][i], Vector2(float(i) / nu, float(j) / nv)], [grid[j][i + 1], Vector2(float(i + 1) / nu, float(j) / nv)],
				[grid[j + 1][i + 1], Vector2(float(i + 1) / nu, float(j + 1) / nv)], [grid[j + 1][i], Vector2(float(i) / nu, float(j + 1) / nv)]]
			for idx in [0, 1, 2, 0, 2, 3]:
				st.set_normal(Vector3(0, 0, 1))
				st.set_uv(q[idx][1])
				st.set_color(Color(1, 1, 1, 1))
				st.add_vertex(q[idx][0])
	return st.commit()


# ---------------------------------------------------------------- placement

## Instances of one tree variant set into MultiMeshes under `parent`.
func commit_trees(parent: Node3D, by_kind: Dictionary, reach: float, origin: Vector3) -> void:
	for kind in by_kind.keys():
		var xfs: Array = by_kind[kind]
		if xfs.is_empty():
			continue
		var pair: Array = trees[kind]
		for part in 2:
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = pair[part]
			mm.instance_count = xfs.size()
			for i in xfs.size():
				var xf: Transform3D = xfs[i]
				mm.set_instance_transform(i, Transform3D(xf.basis, xf.origin - origin))
			var mi := MultiMeshInstance3D.new()
			mi.position = origin
			mi.name = "Tree%d_%s" % [kind, "bole" if part == 0 else "crown"]
			mi.multimesh = mm
			mi.material_override = tree_mat if part == 0 else crown_mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.visibility_range_end = reach
			mi.visibility_range_end_margin = 8.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			parent.add_child(mi)


## A Nguithr'xurh sub-cluster around a centre: silk slung between the given
## trunk points, a dense funnel low down, a clutch of egg sacs and a few
## pairs of eye-glints. Returns the glint nodes (the level blinks them).
func cluster(parent: Node3D, c: Vector3, trunks: Array, r: RandomNumberGenerator, dense: bool) -> Array:
	var root := Node3D.new()
	root.name = "SubCluster"
	root.position = c
	parent.add_child(root)
	var sheets := 0
	for i in trunks.size():
		for j in range(i + 1, trunks.size()):
			var a: Vector3 = trunks[i] - c
			var b: Vector3 = trunks[j] - c
			var span := Vector2(b.x - a.x, b.z - a.z).length()
			if span < 2.0 or span > 9.0 or sheets >= (7 if dense else 4):
				continue
			sheets += 1
			for layer in 2:
				var y0 := r.randf_range(0.6, 2.2) + layer * r.randf_range(1.6, 3.2)
				var hgt := r.randf_range(1.8, 3.6)
				var mi := MeshInstance3D.new()
				mi.mesh = silk_mesh
				mi.material_override = silk_mat
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				var mid := (a + b) * 0.5
				mi.position = Vector3(mid.x, y0 + hgt * 0.5, mid.z)
				mi.rotation.y = atan2(-(b.z - a.z), b.x - a.x)
				mi.rotation.x = r.randf_range(-0.3, 0.3)
				mi.scale = Vector3(span, hgt, 1.0)
				mi.visibility_range_end = 70.0
				root.add_child(mi)
	# the funnel: overlapping sheets wound round a low knot of silk
	var knot := Vector3(r.randf_range(-1, 1), 0.0, r.randf_range(-1, 1))
	for k in (6 if dense else 3):
		var mi := MeshInstance3D.new()
		mi.mesh = silk_mesh
		mi.material_override = silk_mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = knot + Vector3(0, 0.9 + k * 0.15, 0)
		mi.rotation = Vector3(r.randf_range(-0.5, 0.5), TAU * k / 6.0, r.randf_range(-0.4, 0.4))
		mi.scale = Vector3(r.randf_range(1.6, 2.6), r.randf_range(1.4, 2.2), 1.0)
		mi.visibility_range_end = 70.0
		root.add_child(mi)
	if dense:
		for k in r.randi_range(7, 14):
			var s := MeshInstance3D.new()
			s.mesh = sac_mesh
			s.material_override = sac_mat
			s.position = knot + Vector3(r.randf_range(-0.7, 0.7), r.randf_range(0.5, 1.6), r.randf_range(-0.7, 0.7))
			s.scale = Vector3.ONE * r.randf_range(0.7, 1.3)
			s.visibility_range_end = 50.0
			root.add_child(s)
	var glints: Array = []
	for k in (4 if dense else 2):
		var g := Node3D.new()
		var a := r.randf() * TAU
		g.position = knot + Vector3(cos(a) * r.randf_range(1.5, 3.5), r.randf_range(0.4, 3.5), sin(a) * r.randf_range(1.5, 3.5))
		g.rotation.y = a
		for s in [-1.0, 1.0]:
			var e := MeshInstance3D.new()
			e.mesh = glint_mesh
			e.material_override = glint_mat
			e.position = Vector3(s * 0.05, 0, 0)
			g.add_child(e)
		root.add_child(g)
		glints.append(g)
	return glints


## A heap of leaf litter and fallen boles; returns the collider-size used.
func detritus(level: Node3D, parent: Node3D, p: Vector3, r: RandomNumberGenerator) -> Vector3:
	var mi := MeshInstance3D.new()
	mi.mesh = mound_mesh
	mi.material_override = mound_mat
	mi.position = p + Vector3(0, -0.15, 0)
	mi.scale = Vector3(2.0, 0.75, 1.7)
	mi.rotation.y = r.randf() * TAU
	parent.add_child(mi)
	for k in 3:
		Props.place(level, parent, "ph/dead_tree_trunk", p + Vector3(r.randf_range(-0.8, 0.8), 0.15 + k * 0.28, r.randf_range(-0.8, 0.8)),
			r.randf_range(0, 360), r.randf_range(0.42, 0.6))
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(2.6, 1.2, 2.6)
	cs.shape = bs
	cs.position = p + Vector3(0, 0.4, 0)
	cs.set_meta("surface", "dirt")
	body.add_child(cs)
	parent.add_child(body)
	return bs.size
