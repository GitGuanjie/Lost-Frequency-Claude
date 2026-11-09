extends RefCounted
## Level 108 growth, all procedural meshes:
## - Craterwood trees: massive mossy boles with buttress roots and heavy, high
##   crowns; instance scale grows toward the crater (page: trees grow larger
##   toward the centre, some near 200 m);
## - Hauntwood trees: grey hardwoods, dormant or decaying, bare limbs;
## - ferns for the verdant floor;
## - Anthosia: clumps of brightly coloured flowers (each clump one colour);
## - the Black Goat (a dark, long-horned goat shape; reported entity, shown
##   only at a distance).

var bark_mat: ShaderMaterial
var crown_mat: ShaderMaterial
var dead_mat: ShaderMaterial
var fern_mat: StandardMaterial3D
var flower_mat: StandardMaterial3D
var goat_mat: StandardMaterial3D
var green: Array = []      # [bole, crown]
var dead: Array = []       # bole only
var fern: ArrayMesh
var flowers: Array = []    # ArrayMesh per colour
var goat: ArrayMesh

const BARK := """
shader_type spatial;
render_mode diffuse_burley, cull_disabled;
uniform bool crown = false;
uniform bool grey = false;
varying vec3 wp;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec3 c;
	if (crown) {
		float l = vn(wp.xz * 1.3 + wp.y * 0.7) * 0.6 + vn(wp.xy * 3.0) * 0.4;
		c = COLOR.rgb * (0.6 + 0.8 * l);
	} else {
		float g = vn(vec2(UV.x * 11.0, UV.y * 0.5)) * 0.6 + vn(vec2(UV.x * 34.0, UV.y * 2.5)) * 0.4;
		c = mix(vec3(0.05, 0.045, 0.035), vec3(0.12, 0.1, 0.075), g);
		if (grey) {
			c = mix(vec3(0.08, 0.078, 0.072), vec3(0.17, 0.165, 0.155), g);
			c *= 0.75 + 0.35 * vn(vec2(UV.x * 3.0, UV.y * 0.3));
		} else {
			// thick moss up the north side and over the roots
			float mo = smoothstep(0.35, 0.7, vn(UV * vec2(4.0, 0.4)) + 0.25 * smoothstep(6.0, 0.0, UV.y));
			c = mix(c, vec3(0.04, 0.085, 0.018) * (0.7 + 0.6 * g), mo * 0.85);
		}
	}
	ALBEDO = c;
	ROUGHNESS = 0.95;
}
"""


func _init() -> void:
	var sh := Shader.new()
	sh.code = BARK
	bark_mat = ShaderMaterial.new()
	bark_mat.shader = sh
	crown_mat = ShaderMaterial.new()
	crown_mat.shader = sh
	crown_mat.set_shader_parameter("crown", true)
	dead_mat = ShaderMaterial.new()
	dead_mat.shader = sh
	dead_mat.set_shader_parameter("grey", true)
	fern_mat = StandardMaterial3D.new()
	fern_mat.vertex_color_use_as_albedo = true
	fern_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	fern_mat.roughness = 0.9
	flower_mat = StandardMaterial3D.new()
	flower_mat.vertex_color_use_as_albedo = true
	flower_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	flower_mat.roughness = 0.6
	flower_mat.emission_enabled = true
	flower_mat.emission = Color(0.06, 0.03, 0.05)
	goat_mat = StandardMaterial3D.new()
	goat_mat.albedo_color = Color(0.012, 0.011, 0.012)
	goat_mat.roughness = 0.8
	var r := RandomNumberGenerator.new()
	r.seed = 108020
	for i in 4:
		green.append(_green_tree(r, 24.0 + i * 3.0, 0.75 + i * 0.12))
	for i in 3:
		dead.append(_dead_tree(r, 15.0 + i * 3.0, 0.38 + i * 0.06))
	fern = _fern(r)
	for col in [Color(0.85, 0.1, 0.45), Color(0.95, 0.65, 0.05), Color(0.55, 0.15, 0.85), Color(0.95, 0.3, 0.1)]:
		flowers.append(_flowers(r, col))
	goat = _goat(r)


# ---------------------------------------------------------------- pieces

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
		pts.append(c + (v as Vector3) * s * r.randf_range(0.78, 1.18))
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
			st.set_color(col * (0.65 + 0.5 * up))
			st.set_uv(Vector2(0.5, vv.y))
			st.set_normal((n + (vv - c).normalized()).normalized())
			st.add_vertex(vv)


func _green_tree(r: RandomNumberGenerator, h: float, r0: float) -> Array:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array = []
	var rad: Array = []
	var off := Vector3.ZERO
	for i in 7:
		var t := float(i) / 6.0
		if i > 0:
			off += Vector3(r.randf_range(-0.3, 0.3), 0, r.randf_range(-0.3, 0.3))
		pts.append(Vector3(off.x, t * h * 0.7 - 0.6, off.z))
		rad.append(r0 * (1.0 - t * 0.6) * (1.45 if i == 0 else 1.0))
	_tube(st, pts, rad, 10)
	# buttress roots: bent tubes flaring out over the ground
	var roots := r.randi_range(5, 7)
	for k in roots:
		var a := TAU * k / roots + r.randf_range(-0.25, 0.25)
		var d := Vector3(cos(a), 0, sin(a))
		var ln := r0 * r.randf_range(2.6, 4.2)
		_tube(st, [d * r0 * 0.4 + Vector3(0, r0 * 2.2, 0), d * r0 * 1.4 + Vector3(0, r0 * 0.7, 0), d * ln + Vector3(0, -0.25, 0)],
			[r0 * 0.42, r0 * 0.3, r0 * 0.1], 6)
	var top: Vector3 = pts[6]
	var tips: Array = [top + Vector3(0, h * 0.12, 0)]
	var limbs := r.randi_range(6, 8)
	for k in limbs:
		var a := TAU * k / limbs + r.randf_range(-0.4, 0.4)
		var u := r.randf()
		var base: Vector3 = (pts[2] as Vector3).lerp(top, u)
		var d := Vector3(cos(a), r.randf_range(0.25, 0.75), sin(a)).normalized()
		var ln := h * r.randf_range(0.18, 0.3) * (1.2 - u * 0.4)
		var mid := base + d * ln * 0.5 + Vector3(0, ln * 0.1, 0)
		var tip := base + d * ln + Vector3(0, ln * 0.15, 0)
		_tube(st, [base, mid, tip], [r0 * 0.3, r0 * 0.19, r0 * 0.07], 6)
		tips.append(tip)
		tips.append(mid + Vector3(0, ln * 0.25, 0))
	var bole := st.commit()
	var sc := SurfaceTool.new()
	sc.begin(Mesh.PRIMITIVE_TRIANGLES)
	for tp in tips:
		for j in 2:
			var s := h * r.randf_range(0.065, 0.1)
			var col := Color(0.035, 0.08, 0.02).lerp(Color(0.07, 0.12, 0.03), r.randf())
			_blob(sc, (tp as Vector3) + Vector3(r.randf_range(-0.6, 0.6) * s, r.randf_range(-0.6, 0.6) * s, r.randf_range(-0.6, 0.6) * s),
				Vector3(s * 1.3, s * 1.05, s * 1.25), r, col)
	return [bole, sc.commit()]


func _dead_tree(r: RandomNumberGenerator, h: float, r0: float) -> Array:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pts: Array = []
	var rad: Array = []
	var off := Vector3.ZERO
	var lean := Vector3(r.randf_range(-1, 1), 0, r.randf_range(-1, 1)).normalized() * r.randf_range(0.05, 0.3)
	for i in 6:
		var t := float(i) / 5.0
		if i > 0:
			off += Vector3(r.randf_range(-0.3, 0.3), 0, r.randf_range(-0.3, 0.3)) + lean
		pts.append(Vector3(off.x, t * h * 0.8 - 0.4, off.z))
		rad.append(r0 * (1.0 - t * 0.7) * (1.4 if i == 0 else 1.0))
	_tube(st, pts, rad, 7)
	for k in r.randi_range(5, 8):
		var a := r.randf() * TAU
		var base: Vector3 = (pts[2] as Vector3).lerp(pts[5], r.randf())
		var d := Vector3(cos(a), r.randf_range(0.1, 0.9), sin(a)).normalized()
		var ln := h * r.randf_range(0.12, 0.3)
		var tip := base + d * ln
		_tube(st, [base, base + d * ln * 0.55 + Vector3(0, -ln * 0.05, 0), tip], [r0 * 0.22, r0 * 0.12, r0 * 0.03], 4)
		for s in [-1.0, 1.0]:
			_tube(st, [tip - d * ln * 0.3, tip + Vector3(-d.z * s, 0.7, d.x * s) * ln * 0.35], [r0 * 0.06, r0 * 0.015], 3)
	return [st.commit()]


func _fern(r: RandomNumberGenerator) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var fronds := 9
	for k in fronds:
		var a := TAU * k / fronds + r.randf_range(-0.2, 0.2)
		var d := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-d.z, 0, d.x)
		var ln := r.randf_range(0.8, 1.3)
		var prev := Vector3(0, 0.05, 0)
		for j in range(1, 7):
			var t := float(j) / 6.0
			var p := d * ln * t + Vector3(0, ln * 0.7 * sin(t * PI * 0.8), 0)
			var w := 0.22 * sin(t * PI) + 0.02
			var col := Color(0.03, 0.08, 0.02).lerp(Color(0.06, 0.12, 0.03), t)
			for s in [-1.0, 1.0]:
				var o: Vector3 = side * w * s + Vector3(0, -w * 0.3, 0)
				for v in [prev, p, p + o, prev, p + o, prev + o * 0.8]:
					st.set_color(col)
					st.set_normal(Vector3.UP)
					st.add_vertex(v)
			prev = p
	return st.commit()


## One Anthosia clump: ~16 stems, each crowned by a five-petal star.
func _flowers(r: RandomNumberGenerator, col: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 16:
		var b := Vector3(r.randf_range(-0.9, 0.9), 0, r.randf_range(-0.9, 0.9))
		var hgt := r.randf_range(0.35, 0.9)
		var top := b + Vector3(r.randf_range(-0.08, 0.08), hgt, r.randf_range(-0.08, 0.08))
		var sd := Vector3(0.012, 0, 0)
		for v in [b - sd, top, b + sd]:
			st.set_color(Color(0.04, 0.09, 0.02))
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
		var pr := r.randf_range(0.07, 0.14)
		var c2 := col * r.randf_range(0.8, 1.1)
		for p in 5:
			var a0 := TAU * p / 5.0
			var a1 := a0 + TAU / 10.0
			var a2 := a0 + TAU / 5.0
			for v in [top, top + Vector3(cos(a0), 0.3, sin(a0)) * pr, top + Vector3(cos(a1), 0.45, sin(a1)) * pr * 1.6,
					top, top + Vector3(cos(a1), 0.45, sin(a1)) * pr * 1.6, top + Vector3(cos(a2), 0.3, sin(a2)) * pr]:
				st.set_color(c2)
				st.set_normal(Vector3.UP)
				st.add_vertex(v)
	return st.commit()


func _goat(r: RandomNumberGenerator) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c := Color(1, 1, 1)
	_blob(st, Vector3(0, 0.82, 0), Vector3(0.24, 0.3, 0.62), r, c)
	_blob(st, Vector3(0, 1.05, 0.62), Vector3(0.1, 0.12, 0.14), r, c)
	_blob(st, Vector3(0, 1.18, 0.78), Vector3(0.09, 0.1, 0.18), r, c)
	_blob(st, Vector3(0, 0.98, 0.86), Vector3(0.04, 0.12, 0.04), r, c)
	for lx in [-0.12, 0.12]:
		for lz in [-0.45, 0.42]:
			_tube(st, [Vector3(lx, 0.7, lz), Vector3(lx, 0.35, lz + 0.03), Vector3(lx, 0.0, lz)], [0.05, 0.035, 0.03], 5)
	for s in [-1.0, 1.0]:
		_tube(st, [Vector3(s * 0.05, 1.28, 0.74), Vector3(s * 0.12, 1.5, 0.6), Vector3(s * 0.2, 1.6, 0.38), Vector3(s * 0.25, 1.48, 0.25)],
			[0.04, 0.033, 0.022, 0.01], 5)
	return st.commit()


# ---------------------------------------------------------------- placement

func mm(parent: Node3D, mesh: Mesh, mat: Material, xfs: Array, origin: Vector3, reach: float, shadows := false) -> void:
	if xfs.is_empty():
		return
	var m := MultiMesh.new()
	m.transform_format = MultiMesh.TRANSFORM_3D
	m.mesh = mesh
	m.instance_count = xfs.size()
	for i in xfs.size():
		var xf: Transform3D = xfs[i]
		m.set_instance_transform(i, Transform3D(xf.basis, xf.origin - origin))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = m
	mi.position = origin
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if reach > 0.0:
		mi.visibility_range_end = reach
		mi.visibility_range_end_margin = 8.0
		mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	parent.add_child(mi)
