extends RefCounted
## Level 16 procedural meshes and scatter: rainforest trees (emergents with
## buttress roots and lianas, canopy trees, palms), ferns and shrubs as
## alpha-scissor leaf cards; glacier spires and ice sheets for the arctic state;
## the sand-covered tree and sand-covered ice sheet (the exit); the warning
## orbs and the Light Guides.

const LEAF := """
shader_type spatial;
render_mode diffuse_burley, cull_disabled;
uniform vec3 tint_a : source_color = vec3(0.12, 0.26, 0.07);
uniform vec3 tint_b : source_color = vec3(0.2, 0.36, 0.1);
uniform float sway = 1.0;
uniform float sand = 0.0;
varying vec3 wp;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float w = COLOR.g * sway;
	VERTEX.x += sin(TIME * 1.1 + wp.x * 0.2 + wp.z * 0.13) * 0.06 * w;
	VERTEX.z += cos(TIME * 0.9 + wp.z * 0.2) * 0.05 * w;
}
void fragment() {
	if (COLOR.a > 0.5) {
		// bark (COLOR.a = 1): ridged, mossy toward the base
		float ridge = abs(fract(UV.x * 9.0) - 0.5);
		vec3 bark = mix(vec3(0.16, 0.12, 0.08), vec3(0.3, 0.26, 0.2), ridge);
		bark = mix(bark, vec3(0.12, 0.2, 0.06), (1.0 - smoothstep(0.0, 4.0, UV.y)) * 0.6);
		float grit = hsh(floor(UV * vec2(40.0, 30.0)));
		bark = mix(bark, vec3(0.6, 0.5, 0.34) * (0.8 + 0.35 * grit), sand * (0.75 + 0.25 * grit));
		ALBEDO = bark;
		ROUGHNESS = 0.95;
	} else {
		// leaf card: a few long leaves fanning from the base of the card
		vec2 uv = UV;
		float m = 0.0;
		for (int i = 0; i < 4; i++) {
			float fi = float(i);
			float ang = (fi - 1.5) * 0.35;
			vec2 p = uv - vec2(0.5, 1.0);
			vec2 q = vec2(p.x * cos(ang) - p.y * sin(ang), p.x * sin(ang) + p.y * cos(ang));
			float along = -q.y;
			float wdt = 0.13 * sin(clamp(along, 0.0, 1.0) * 3.14159) * (0.8 + 0.4 * hsh(vec2(fi, 2.0)));
			m = max(m, step(abs(q.x), wdt) * step(0.02, along) * step(along, 0.98));
		}
		if (m < 0.5) { discard; }
		float v = hsh(floor(wp.xz * 0.7));
		vec3 c = mix(tint_a, tint_b, v) * (0.75 + 0.5 * UV.y);
		ALBEDO = c;
		ROUGHNESS = 0.6;
		BACKLIGHT = c * 0.6;
	}
}
"""

const ICE := """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform float glow = 0.5;
varying vec3 wp;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float fr = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	float band = hsh(vec2(floor(wp.y * 1.3), floor(wp.x * 0.2)));
	vec3 c = mix(vec3(0.3, 0.55, 0.75), vec3(0.75, 0.88, 0.96), band * 0.6 + fr * 0.4);
	ALBEDO = c;
	ROUGHNESS = 0.05 + 0.15 * band;
	SPECULAR = 0.9;
	EMISSION = c * glow * (0.4 + 0.6 * fr);
}
"""

const GLOWDOT := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec3 col : source_color = vec3(0.7, 0.9, 1.0);
uniform float energy = 2.0;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	float d = length(UV - 0.5) * 2.0;
	float a = smoothstep(1.0, 0.0, d);
	a = a * a;
	ALBEDO = col * energy * a;
}
"""


static func shader_mat(code: String) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


static func tube(st: SurfaceTool, a: Vector3, b: Vector3, ra: float, rb: float, sides: int, col := Color(0, 0, 0, 1)) -> void:
	var ax := (b - a).normalized()
	var up := Vector3.UP if absf(ax.y) < 0.95 else Vector3.RIGHT
	var u := ax.cross(up).normalized()
	var w := ax.cross(u).normalized()
	var ln := a.distance_to(b)
	for s in sides:
		var a0 := TAU * s / sides
		var a1 := TAU * (s + 1) / sides
		var d0 := u * cos(a0) + w * sin(a0)
		var d1 := u * cos(a1) + w * sin(a1)
		var p := [a + d0 * ra, a + d1 * ra, b + d1 * rb, b + d0 * rb]
		var n := [d0, d1, d1, d0]
		var uv := [Vector2(float(s) / sides, a.y), Vector2(float(s + 1) / sides, a.y), Vector2(float(s + 1) / sides, a.y + ln), Vector2(float(s) / sides, a.y + ln)]
		for k in [0, 2, 1, 0, 3, 2]:
			st.set_color(col)
			st.set_uv(uv[k])
			st.set_normal(n[k])
			st.add_vertex(p[k])


## Two crossed leaf cards rooted at c, leaning along dir. sway in COLOR.g.
static func card(st: SurfaceTool, c: Vector3, dir: Vector3, size: float, yaw: float) -> void:
	dir = dir.normalized()
	for k in 2:
		var a := yaw + k * PI * 0.5
		var u := Vector3(cos(a), 0.0, sin(a)).normalized()
		u = (u - dir * u.dot(dir)).normalized() * size * 0.5
		var v := dir * size
		var n := u.cross(v).normalized()
		var p := [c - u, c + u, c + u + v, c - u + v]
		var uv := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		for i in [0, 1, 2, 0, 2, 3]:
			st.set_color(Color(0, 1.0 if i != 0 and i != 1 else 0.2, 0, 0))
			st.set_uv(uv[i])
			st.set_normal((n + Vector3.UP * 0.6).normalized())
			st.add_vertex(p[i])


## Rainforest emergent / canopy tree. variant 0-1 emergent, 2-3 canopy.
## sand: the trunk is crusted with sand (the exit tree).
static func tree_mesh(variant: int, sand := false) -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = 1600 + variant * 31 + (7 if sand else 0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var emergent := variant < 2
	var hgt := r.randf_range(26.0, 32.0) if emergent else r.randf_range(14.0, 19.0)
	var rad := 0.75 if emergent else 0.42
	var bark := Color(0, 0, 0, 1)
	var lean := Vector3(r.randf_range(-0.6, 0.6), 0, r.randf_range(-0.6, 0.6))
	var segs := 5
	var prev := Vector3(0, -0.5, 0)
	for i in segs:
		var t := float(i + 1) / segs
		var p := Vector3(0, hgt * 0.78 * t, 0) + lean * t * t
		tube(st, prev, p, rad * (1.0 - 0.55 * float(i) / segs), rad * (1.0 - 0.55 * t), 9, bark)
		prev = p
	# buttress roots: thin flared plates
	if emergent:
		for k in 5:
			var a := TAU * k / 5.0 + r.randf() * 0.5
			var o := Vector3(cos(a), 0, sin(a))
			for j in 3:
				var y0 := j * 0.9
				tube(st, o * rad * 0.8 + Vector3(0, y0 + 0.9, 0), o * (rad + 2.0 - j * 0.6) + Vector3(0, -0.3, 0), 0.16, 0.08, 4, bark)
	# crown: limbs out from the top with leaf clusters; lianas hang down
	var top := prev
	var limbs := 6 if emergent else 5
	for k in limbs:
		var a := TAU * k / limbs + r.randf_range(-0.3, 0.3)
		var spread := r.randf_range(3.0, 6.5) if emergent else r.randf_range(2.5, 4.5)
		var tip := top + Vector3(cos(a) * spread, r.randf_range(1.0, 3.5), sin(a) * spread)
		tube(st, top - Vector3(0, 1.5, 0), tip, rad * 0.35, 0.08, 5, bark)
		for j in 9:
			var cc := tip + Vector3(r.randf_range(-2.4, 2.4), r.randf_range(-0.8, 1.2), r.randf_range(-2.4, 2.4))
			card(st, cc, Vector3(r.randf_range(-0.4, 0.4), 1.0, r.randf_range(-0.4, 0.4)), r.randf_range(2.2, 3.4), r.randf() * PI)
		if r.randf() < 0.6 and not sand:
			var hang := tip + Vector3(0, -r.randf_range(6.0, hgt * 0.6), 0)
			tube(st, tip, hang, 0.045, 0.03, 4, Color(0.05, 0.08, 0.03, 1))
	for j in 8:
		card(st, top + Vector3(r.randf_range(-1.5, 1.5), r.randf_range(0.5, 2.5), r.randf_range(-1.5, 1.5)), Vector3(r.randf_range(-0.3, 0.3), 1.0, r.randf_range(-0.3, 0.3)), r.randf_range(2.4, 3.4), r.randf() * PI)
	return st.commit()


static func palm_mesh(variant: int) -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = 1650 + variant
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hgt := r.randf_range(7.0, 11.0)
	var bend := Vector3(r.randf_range(-1.5, 1.5), 0, r.randf_range(-1.5, 1.5))
	var prev := Vector3(0, -0.3, 0)
	for i in 6:
		var t := float(i + 1) / 6.0
		var p := Vector3(0, hgt * t, 0) + bend * t * t
		tube(st, prev, p, 0.2, 0.17, 7, Color(0.05, 0.04, 0.03, 1))
		prev = p
	for k in 11:
		var a := TAU * k / 11.0 + r.randf() * 0.3
		var d := Vector3(cos(a), r.randf_range(-0.2, 0.5), sin(a))
		card(st, prev, d, r.randf_range(3.0, 4.2), a + PI * 0.5)
	return st.commit()


static func fern_mesh(variant: int) -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = 1670 + variant
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 7 if variant == 0 else 5
	for k in n:
		var a := TAU * k / n + r.randf() * 0.4
		var d := Vector3(cos(a), r.randf_range(0.5, 1.1), sin(a))
		card(st, Vector3(0, -0.05, 0), d, r.randf_range(0.9, 1.6) * (1.0 if variant == 0 else 1.5), a + PI * 0.5)
	return st.commit()


## A glacier spire: a leaning, faceted prism of ice, base at y = 0.
static func spire_mesh(sd: int) -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = sd
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 6
	var rb := r.randf_range(2.0, 3.6)
	var hgt := r.randf_range(10.0, 22.0)
	var tip := Vector3(r.randf_range(-1.5, 1.5), hgt, r.randf_range(-1.5, 1.5))
	var ring: Array = []
	var mid: Array = []
	for i in sides:
		var a := TAU * i / sides + r.randf_range(-0.2, 0.2)
		var rr := rb * r.randf_range(0.75, 1.15)
		ring.append(Vector3(cos(a) * rr, -2.0, sin(a) * rr))
		mid.append(Vector3(cos(a) * rr * 0.55, hgt * r.randf_range(0.45, 0.65), sin(a) * rr * 0.55) + tip * 0.4)
	for i in sides:
		var j := (i + 1) % sides
		for tri in [[ring[i], mid[j], ring[j]], [ring[i], mid[i], mid[j]], [mid[i], tip, mid[j]]]:
			var nrm: Vector3 = (tri[1] - tri[0]).cross(tri[2] - tri[0]).normalized()
			for v in [tri[0], tri[2], tri[1]]:
				st.set_normal(-nrm)
				st.add_vertex(v)
	st.generate_normals()
	return st.commit()


static func multimesh(mesh: Mesh, xfs: Array, mat: Material, shadows: bool, vis: float) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if vis > 0.0:
		mmi.visibility_range_end = vis
		mmi.visibility_range_end_margin = 8.0
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	return mmi


static func dot_mesh(size: float) -> QuadMesh:
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	return q
