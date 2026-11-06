extends RefCounted
## Level 14 procedural art: shaders and meshes, no binary assets.
## Trees whose limbs reach up toward the sky, crimson grass wet with dew,
## a starlit sky with a moon, waterfalls and mist, the guests' bones and the
## small silhouettes that stand in rows on the falls meadow.

const SKY := "shader_type sky;
uniform vec3 zenith : source_color = vec3(0.006, 0.008, 0.03);
uniform vec3 horizon : source_color = vec3(0.05, 0.03, 0.065);
uniform float star_gain = 1.0;
uniform float band_gain = 1.0;
float h1(vec3 p) { p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419)); p *= 17.0; return fract(p.x * p.y * p.z * (p.x + p.y + p.z)); }
float vn(vec3 x) { vec3 i = floor(x); vec3 f = fract(x); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h1(i), h1(i + vec3(1,0,0)), f.x), mix(h1(i + vec3(0,1,0)), h1(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(h1(i + vec3(0,0,1)), h1(i + vec3(1,0,1)), f.x), mix(h1(i + vec3(0,1,1)), h1(i + vec3(1,1,1)), f.x), f.y), f.z); }
float stars(vec3 d, float sc, float th, float sz) {
	vec3 p = d * sc; vec3 c = floor(p); vec3 f = fract(p); float h = h1(c);
	if (h < th) return 0.0;
	vec3 o = vec3(h1(c + 3.1), h1(c + 7.7), h1(c + 1.9)) * 0.6 + 0.2;
	float tw = 0.7 + 0.3 * sin(TIME * (1.5 + h * 5.0) + h * 40.0);
	return smoothstep(sz, 0.0, length(f - o)) * (0.35 + 0.65 * (h - th) / (1.0 - th)) * tw;
}
void sky() {
	vec3 d = EYEDIR;
	float el = d.y;
	vec3 col = mix(horizon, zenith, smoothstep(-0.02, 0.5, el));
	if (!AT_CUBEMAP_PASS && el > -0.04) {
		float fade = smoothstep(-0.01, 0.16, el);
		vec3 bn = normalize(vec3(0.62, 0.42, -0.66));
		float b = dot(d, bn);
		float cl = vn(d * 7.0) * 0.6 + vn(d * 17.0) * 0.4;
		float band = exp(-b * b / 0.026) * (0.25 + 1.1 * cl * cl);
		col += vec3(0.07, 0.055, 0.11) * band * fade * band_gain;
		float s = stars(d, 95.0, 0.978, 0.24) * 2.6 + stars(d, 190.0, 0.962, 0.2) * 1.2 + stars(d, 330.0, 0.93, 0.17) * 0.6;
		s *= 1.0 + band * 1.6;
		vec3 sc = mix(vec3(0.75, 0.82, 1.0), vec3(1.0, 0.86, 0.78), h1(floor(d * 95.0)));
		col += sc * s * fade * star_gain;
	}
	float md = distance(d, LIGHT0_DIRECTION);
	float disc = smoothstep(0.034, 0.031, md);
	float maria = vn(d * 120.0) * 0.6 + vn(d * 300.0) * 0.4;
	col = mix(col, vec3(1.0, 0.98, 0.9) * (2.4 - 0.9 * maria), disc);
	col += vec3(0.45, 0.5, 0.65) * exp(-md * 18.0) * 0.35 + vec3(0.18, 0.16, 0.26) * exp(-md * 4.0) * 0.18;
	COLOR = col;
}"

const GROUND := "shader_type spatial;
render_mode diffuse_burley, specular_disabled;
uniform float lure = 0.0;
uniform vec3 moon_dir = vec3(-0.27, 0.44, -0.86);
uniform float truth = 0.0;
varying vec3 wp;
varying vec3 wn;
float h1(vec3 p) { p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419)); p *= 17.0; return fract(p.x * p.y * p.z * (p.x + p.y + p.z)); }
float vn(vec3 x) { vec3 i = floor(x); vec3 f = fract(x); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h1(i), h1(i + vec3(1,0,0)), f.x), mix(h1(i + vec3(0,1,0)), h1(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(h1(i + vec3(0,0,1)), h1(i + vec3(1,0,1)), f.x), mix(h1(i + vec3(0,1,1)), h1(i + vec3(1,1,1)), f.x), f.y), f.z); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; wn = NORMAL; }
void fragment() {
	float n1 = vn(wp * 0.33); float n2 = vn(wp * 1.9); float n3 = vn(wp * 0.07);
	vec3 crim = mix(vec3(0.12, 0.006, 0.014), vec3(0.30, 0.016, 0.03), n1 * 0.7 + n2 * 0.3);
	crim = mix(crim, vec3(0.62, 0.02, 0.09), lure * 0.55);
	crim = mix(crim, vec3(0.17, 0.08, 0.06), truth * 0.7);
	vec3 soil = mix(vec3(0.05, 0.02, 0.02), vec3(0.09, 0.04, 0.035), n2);
	float strata = 0.55 + 0.45 * sin(wp.y * 3.1 + n1 * 4.0 + vn(wp * vec3(0.4, 0.05, 0.4)) * 6.0);
	vec3 rock = mix(vec3(0.025, 0.023, 0.027), vec3(0.068, 0.062, 0.066), n1 * 0.5 + strata * 0.5) * (0.7 + 0.3 * n2);
	rock *= 1.0 - 0.45 * smoothstep(0.55, 0.8, vn(wp * vec3(1.2, 0.12, 1.2)));
	float slope = 1.0 - wn.y;
	float rockw = smoothstep(0.2, 0.34, slope + (n2 - 0.5) * 0.12);
	float soilw = smoothstep(0.7, 0.85, n3 + n2 * 0.2) * (1.0 - rockw) * 0.5;
	vec3 col = mix(mix(crim, soil, soilw), rock, rockw);
	float wet = smoothstep(-0.1, -0.6, wp.y) * (1.0 - rockw);
	ALBEDO = col * (1.0 - wet * 0.45);
	ROUGHNESS = 1.0;
	// dew: tiny facets that catch the moon
	vec3 c = floor(wp * 28.0);
	float hh = h1(c);
	float on = step(0.975 - 0.02 * lure, hh) * (1.0 - rockw) * smoothstep(0.5, 0.2, length(fract(wp * 28.0) - 0.5));
	vec3 gn = normalize(wn + (vec3(h1(c + 1.7), h1(c + 4.1), h1(c + 9.3)) - 0.5) * 1.3);
	vec3 v = normalize(CAMERA_POSITION_WORLD - wp);
	float g = pow(clamp(dot(reflect(-moon_dir, gn), v), 0.0, 1.0), 40.0);
	float sheen = pow(clamp(dot(reflect(-moon_dir, wn), v), 0.0, 1.0), 6.0) * wet;
	EMISSION = vec3(0.85, 0.9, 1.0) * (on * g * (2.5 + 3.0 * lure) + sheen * 0.15);
}
void light() {
	DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR / PI;
}"

const GRASS := "shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;
uniform vec3 moon_dir = vec3(-0.27, 0.44, -0.86);
uniform float lure = 0.0;
uniform float truth = 0.0;
uniform float sway = 0.12;
varying float tip;
varying vec3 ipos;
void vertex() {
	tip = clamp(VERTEX.y / 0.6, 0.0, 1.0);
	ipos = MODEL_MATRIX[3].xyz;
	float d = distance(ipos, INV_VIEW_MATRIX[3].xyz);
	float shrink = 1.0 - smoothstep(26.0, 36.0, d);
	VERTEX.y *= shrink;
	VERTEX.xz *= mix(1.0, 0.4, 1.0 - shrink);
	float t = TIME * (0.9 + lure * 0.6);
	float ph = ipos.x * 0.37 + ipos.z * 0.23;
	vec3 w = vec3(sin(t + ph) + 0.4 * sin(t * 2.3 + ph * 1.7), 0.0, cos(t * 0.8 + ph * 1.3)) * (sway + lure * 0.12);
	VERTEX += (inverse(mat3(MODEL_MATRIX)) * w) * tip * tip;
}
void fragment() {
	float iv = fract(sin(dot(ipos.xz, vec2(12.9898, 78.233))) * 43758.5453);
	vec3 base = mix(vec3(0.07, 0.002, 0.008), vec3(0.42, 0.012, 0.03) * (0.6 + 0.6 * iv), tip);
	base = mix(base, vec3(0.55, 0.006, 0.05) * mix(0.5, 1.0, tip), lure * 0.5);
	base = mix(base, vec3(0.16, 0.08, 0.05) * mix(0.6, 1.0, tip), truth * 0.7);
	ALBEDO = base;
	ROUGHNESS = 0.8;
	SPECULAR = 0.0;
	if (!FRONT_FACING) { NORMAL = -NORMAL; }
}
void light() {
	float nl = dot(NORMAL, LIGHT);
	// diffuse, plus red light passing through blades lit from behind
	DIFFUSE_LIGHT += (clamp(nl, 0.0, 1.0) + clamp(-nl, 0.0, 1.0) * 0.45 * tip) * ATTENUATION * LIGHT_COLOR / PI;
}"

const TREE := "shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_disabled;
uniform float lure = 0.0;
uniform float truth = 0.0;
varying float leaf;
float h1(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float vn(vec2 x) { vec2 i = floor(x); vec2 f = fract(x); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h1(i), h1(i + vec2(1, 0)), f.x), mix(h1(i + vec2(0, 1)), h1(i + vec2(1, 1)), f.x), f.y); }
void vertex() {
	leaf = 1.0 - COLOR.a;
	vec3 ip = MODEL_MATRIX[3].xyz;
	float hy = VERTEX.y / 13.0;
	float t = TIME * 0.5 + ip.x * 0.11 + ip.z * 0.07;
	vec3 w = vec3(sin(t), 0.0, cos(t * 0.8)) * 0.18 * hy * hy;
	// the longer you stay, the more the limbs strain upward and toward the Clearing
	w.y += COLOR.g * lure * 1.6;
	vec2 to_c = -ip.xz / max(length(ip.xz), 1.0);
	w.xz += to_c * hy * hy * lure * 1.4;
	VERTEX += inverse(mat3(MODEL_MATRIX)) * w;
}
void fragment() {
	vec3 bark = vec3(0.032, 0.027, 0.027) * (0.6 + 0.7 * vn(UV * vec2(5.0, 9.0)));
	vec3 lf = mix(vec3(0.02, 0.032, 0.036), vec3(0.06, 0.07, 0.07), vn(UV * 6.0));
	lf = mix(lf, vec3(0.07, 0.015, 0.03), lure * 0.4);
	ALBEDO = mix(bark, lf, leaf);
	ROUGHNESS = mix(0.95, 0.7, leaf);
	SPECULAR = 0.15;
	if (leaf > 0.5) {
		vec2 q = UV * 2.0 - 1.0;
		float a = atan(q.y, q.x);
		float r = length(q) * (0.85 + 0.15 * sin(a * 5.0 + UV.y * 2.0));
		float m = vn(UV * 5.0) * 0.55 + vn(UV * 13.0 + 3.1) * 0.45;
		ALPHA = (1.0 - smoothstep(0.55, 1.0, r)) * smoothstep(0.32, 0.5, m) * 1.6;
		ALPHA_SCISSOR_THRESHOLD = 0.5;
		BACKLIGHT = vec3(0.04, 0.05, 0.06);
	}
	if (!FRONT_FACING) { NORMAL = -NORMAL; }
}"

const FIGURE := "shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled;
uniform float presence = 1.0;
uniform vec3 fogc : source_color = vec3(0.05, 0.03, 0.065);
uniform float near_fade = 13.0;
varying float dist;
void vertex() { dist = distance((MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz, INV_VIEW_MATRIX[3].xyz); }
void fragment() {
	float a = presence * smoothstep(near_fade, near_fade + 9.0, dist);
	float th = fract(dot(FRAGCOORD.xy, vec2(0.0671, 0.00584)) * 52.9829);
	if (a < th) discard;
	float rim = pow(1.0 - clamp(abs(dot(NORMAL, VIEW)), 0.0, 1.0), 4.5);
	ALBEDO = mix(vec3(0.004, 0.003, 0.008), fogc, smoothstep(30.0, 140.0, dist) * 0.55) + vec3(0.45, 0.5, 0.75) * rim * 0.55;
}"

const ROCK := "shader_type spatial;
render_mode diffuse_burley, specular_disabled;
uniform float truth = 0.0;
varying vec3 wp;
varying vec3 wn;
float h1(vec3 p) { p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419)); p *= 17.0; return fract(p.x * p.y * p.z * (p.x + p.y + p.z)); }
float vn(vec3 x) { vec3 i = floor(x); vec3 f = fract(x); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h1(i), h1(i + vec3(1,0,0)), f.x), mix(h1(i + vec3(0,1,0)), h1(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(h1(i + vec3(0,0,1)), h1(i + vec3(1,0,1)), f.x), mix(h1(i + vec3(0,1,1)), h1(i + vec3(1,1,1)), f.x), f.y), f.z); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz); }
void fragment() {
	float n1 = vn(wp * 0.8); float n2 = vn(wp * 3.7);
	float strata = 0.55 + 0.45 * sin(wp.y * 3.1 + n1 * 4.0);
	vec3 rock = mix(vec3(0.03, 0.028, 0.031), vec3(0.08, 0.074, 0.075), n1 * 0.5 + strata * 0.5) * (0.7 + 0.3 * n2);
	float moss = smoothstep(0.55, 0.85, wn.y + (n2 - 0.5) * 0.3);
	ALBEDO = mix(rock, mix(vec3(0.2, 0.01, 0.025), vec3(0.15, 0.08, 0.05), truth), moss);
	ROUGHNESS = mix(0.7, 0.95, n2);
	SPECULAR = 0.15;
}"

const FALLS := "shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
uniform float gain = 1.0;
float h1(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
float vn(vec2 x) { vec2 i = floor(x); vec2 f = fract(x); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h1(i), h1(i + vec2(1, 0)), f.x), mix(h1(i + vec2(0, 1)), h1(i + vec2(1, 1)), f.x), f.y); }
void fragment() {
	float y = UV.y;
	float s1 = vn(vec2(UV.x * 14.0, y * 2.2 - TIME * 2.6));
	float s2 = vn(vec2(UV.x * 31.0 + 7.0, y * 5.0 - TIME * 4.1));
	float streak = s1 * 0.6 + s2 * 0.4;
	float edge = smoothstep(0.0, 0.18, UV.x) * smoothstep(1.0, 0.82, UV.x);
	float a = clamp(streak * 1.5 - 0.25, 0.0, 1.0) * edge;
	a = mix(a, 1.0, smoothstep(0.82, 1.0, y) * edge * 0.6);
	ALBEDO = mix(vec3(0.42, 0.5, 0.62), vec3(0.9, 0.94, 1.0), streak) * gain;
	ALPHA = a * 0.88;
}"

const MIST := "shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
uniform float gain = 0.16;
void fragment() {
	vec2 q = UV * 2.0 - 1.0;
	float a = (1.0 - smoothstep(0.1, 1.0, length(q))) * (0.75 + 0.25 * sin(TIME * 0.7 + UV.x * 3.0));
	ALBEDO = vec3(0.62, 0.68, 0.82);
	ALPHA = a * a * gain;
}"


static func shader_mat(code: String) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


# ------------------------------------------------------------ mesh helpers

## Tapered tube between a and b with vertex colour (bark: a = 1).
static func tube(st: SurfaceTool, a: Vector3, b: Vector3, ra: float, rb: float, sides: int, col_a: Color, col_b: Color) -> void:
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
		var c := [col_a, col_a, col_b, col_b]
		var uv := [Vector2(float(s) / sides, 0), Vector2(float(s + 1) / sides, 0), Vector2(float(s + 1) / sides, ln), Vector2(float(s) / sides, ln)]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_color(c[k])
			st.set_uv(uv[k])
			st.set_normal(n[k])
			st.add_vertex(p[k])


static func ellipsoid(st: SurfaceTool, c: Vector3, r: Vector3, rings: int, segs: int, col: Color, b := Basis()) -> void:
	for i in rings:
		var t0 := PI * i / rings
		var t1 := PI * (i + 1) / rings
		for j in segs:
			var p0 := TAU * j / segs
			var p1 := TAU * (j + 1) / segs
			var dirs := [Vector3(sin(t0) * cos(p0), cos(t0), sin(t0) * sin(p0)), Vector3(sin(t1) * cos(p0), cos(t1), sin(t1) * sin(p0)),
				Vector3(sin(t1) * cos(p1), cos(t1), sin(t1) * sin(p1)), Vector3(sin(t0) * cos(p1), cos(t0), sin(t0) * sin(p1))]
			for k in [0, 2, 1, 0, 3, 2]:
				var dd: Vector3 = dirs[k]
				st.set_color(col)
				st.set_uv(Vector2(float(j) / segs, float(i) / rings))
				st.set_normal((b * (dd / r)).normalized())
				st.add_vertex(c + b * (dd * r))


## Leaf card (two crossed quads) centred at c; COLOR.a = 0 marks foliage.
static func leaf_card(st: SurfaceTool, c: Vector3, size: float, yaw: float, tipw: float) -> void:
	for k in 2:
		var a := yaw + k * PI * 0.5
		var u := Vector3(cos(a), 0.0, sin(a)) * size
		var v := Vector3(0.0, size, 0.0)
		var n := Vector3(-sin(a), 0.25, cos(a)).normalized()
		var col := Color(0, tipw, 0, 0)
		var p := [c - u - v, c + u - v, c + u + v, c - u + v]
		var uv := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		for i in [0, 1, 2, 0, 2, 3]:
			st.set_color(col)
			st.set_uv(uv[i])
			st.set_normal(n)
			st.add_vertex(p[i])


## A tall tree whose limbs climb steeply toward the sky, like raised arms,
## with sparse dark foliage only near the tips. variant 0..2.
static func tree_mesh(variant: int) -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = 1400 + variant * 17
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hgt: float = [12.0, 14.5, 10.5][variant]
	var bark := Color(1, 0, 0, 1)
	var lean := Vector3(r.randf_range(-0.3, 0.3), 0, r.randf_range(-0.3, 0.3))
	var fork := Vector3(0, hgt * r.randf_range(0.42, 0.55), 0) + lean * 0.5
	tube(st, Vector3(0, -0.6, 0), fork, 0.38, 0.24, 7, bark, bark)
	for k in 4:
		var a := TAU * k / 4.0 + r.randf() * 0.6
		tube(st, Vector3(0, 0.8, 0), Vector3(cos(a) * 1.0, -0.25, sin(a) * 1.0), 0.2, 0.05, 4, bark, bark)
	# a few low, short limbs on the trunk
	for k in 2 + variant:
		var a := r.randf() * TAU
		var b0 := Vector3(0, hgt * r.randf_range(0.2, 0.4), 0) + lean * 0.3
		var tp := b0 + Vector3(cos(a) * 1.0, r.randf_range(1.6, 2.6), sin(a) * 1.0)
		tube(st, b0, tp, 0.07, 0.015, 4, bark, Color(1, 0.8, 0, 1))
		leaf_card(st, tp + Vector3(0, 0.1, 0), r.randf_range(0.35, 0.55), r.randf() * PI, 0.8)
	# main limbs: steep, slightly bowed, splaying into upward fingers
	var arms := 4 + variant
	for k in arms:
		var a := TAU * k / arms + r.randf_range(-0.35, 0.35)
		var spread := r.randf_range(0.9, 2.2)
		var rise := hgt - fork.y + r.randf_range(-1.5, 1.5)
		var elbow := fork + Vector3(cos(a) * spread * 0.7, rise * 0.45, sin(a) * spread * 0.7)
		var tip := fork + Vector3(cos(a) * spread, rise, sin(a) * spread)
		tube(st, fork, elbow, 0.17, 0.11, 6, bark, Color(1, 0.35, 0, 1))
		tube(st, elbow, tip, 0.11, 0.02, 5, Color(1, 0.35, 0, 1), Color(1, 1, 0, 1))
		for t in 3:
			var ta := a + r.randf_range(-1.2, 1.2)
			var base := elbow.lerp(tip, r.randf_range(0.35, 0.85))
			var tw := base + Vector3(cos(ta) * r.randf_range(0.4, 0.9), r.randf_range(1.0, 2.0), sin(ta) * r.randf_range(0.4, 0.9))
			tube(st, base, tw, 0.04, 0.006, 3, Color(1, 0.7, 0, 1), Color(1, 1, 0, 1))
			leaf_card(st, tw + Vector3(0, -0.1, 0), r.randf_range(0.35, 0.6), r.randf() * PI, 1.0)
		leaf_card(st, tip, r.randf_range(0.45, 0.7), r.randf() * PI, 1.0)
	return st.commit()


## One crimson tuft: blades bent outward, two segments each.
static func tuft_mesh() -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = 1414
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for b in 8:
		var a := r.randf() * TAU
		var dir := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-dir.z, 0, dir.x)
		var root := dir * r.randf_range(0.0, 0.14)
		var hgt := r.randf_range(0.32, 0.62)
		var bend := r.randf_range(0.08, 0.26)
		var w := r.randf_range(0.022, 0.034)
		var p0 := root - side * w
		var p1 := root + side * w
		var m0 := root + dir * bend * 0.35 + Vector3(0, hgt * 0.55, 0) - side * w * 0.7
		var m1 := root + dir * bend * 0.35 + Vector3(0, hgt * 0.55, 0) + side * w * 0.7
		var t := root + dir * bend + Vector3(0, hgt, 0)
		var fn := side.cross(t - root).normalized()
		for pt in [p0, p1, m1, p0, m1, m0, m0, m1, t]:
			st.set_normal((fn + Vector3.UP * 0.6).normalized())
			st.add_vertex(pt)
	return st.commit()


## A guest lying on its back in the soil (bones only), length along +Z.
static func bones_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c := Color(1, 1, 1, 1)
	ellipsoid(st, Vector3(0, 0.08, -0.82), Vector3(0.085, 0.09, 0.11), 6, 8, c)       # skull
	ellipsoid(st, Vector3(0, 0.04, -0.72), Vector3(0.05, 0.03, 0.05), 3, 6, c)        # jaw
	tube(st, Vector3(0, 0.05, -0.66), Vector3(0, 0.05, 0.05), 0.022, 0.022, 4, c, c)  # spine
	for i in 6:
		var z := -0.55 + i * 0.07
		var rr := 0.13 - absf(i - 2.0) * 0.012
		for s in [-1.0, 1.0]:
			var p0 := Vector3(0, 0.07, z)
			var p1 := Vector3(s * rr, 0.06, z + 0.03)
			var p2 := Vector3(s * rr * 1.05, -0.02, z + 0.07)
			tube(st, p0, p1, 0.011, 0.011, 3, c, c)
			tube(st, p1, p2, 0.011, 0.009, 3, c, c)
	ellipsoid(st, Vector3(0, 0.04, 0.1), Vector3(0.15, 0.05, 0.08), 4, 8, c)          # pelvis
	for s in [-1.0, 1.0]:
		tube(st, Vector3(s * 0.17, 0.05, -0.6), Vector3(s * 0.22, 0.03, -0.32), 0.02, 0.016, 4, c, c)   # humerus
		tube(st, Vector3(s * 0.22, 0.03, -0.32), Vector3(s * 0.16, 0.04, -0.06), 0.015, 0.012, 4, c, c) # forearm
		tube(st, Vector3(s * 0.09, 0.04, 0.15), Vector3(s * 0.11, 0.03, 0.58), 0.026, 0.02, 5, c, c)   # femur
		tube(st, Vector3(s * 0.11, 0.03, 0.6), Vector3(s * 0.12, 0.02, 1.0), 0.019, 0.015, 4, c, c)    # shin
		ellipsoid(st, Vector3(s * 0.12, 0.03, 0.59), Vector3(0.03, 0.025, 0.03), 3, 5, c)
		tube(st, Vector3(s * 0.15, 0.06, -0.62), Vector3(s * 0.02, 0.07, -0.64), 0.012, 0.01, 3, c, c)  # clavicle
	st.generate_normals()
	return st.commit()


## A small standing figure, head tipped back toward the moon (~1.2 m).
static func child_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var c := Color(0, 0, 0, 1)
	for s in [-1.0, 1.0]:
		tube(st, Vector3(s * 0.07, 0.0, 0), Vector3(s * 0.065, 0.55, 0), 0.05, 0.06, 5, c, c)
		tube(st, Vector3(s * 0.17, 0.95, 0), Vector3(s * 0.2, 0.55, 0.02), 0.04, 0.032, 5, c, c)
	tube(st, Vector3(0, 0.5, 0), Vector3(0, 0.98, 0), 0.15, 0.13, 7, c, c)
	tube(st, Vector3(0, 0.96, 0), Vector3(0, 1.04, 0.02), 0.05, 0.045, 5, c, c)
	ellipsoid(st, Vector3(0, 1.12, 0.05), Vector3(0.1, 0.12, 0.11), 6, 8, c, Basis(Vector3.RIGHT, -0.6))
	return st.commit()


## Waterfall ribbon: a parabolic arc from the lip to the pool, width w.
static func falls_mesh(lip: Vector3, land_y: float, speed: float, w: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var t_end := sqrt(2.0 * (lip.y - land_y) / 9.8)
	var seg := 16
	var pts: Array = []
	for i in seg + 1:
		var t := t_end * i / seg
		pts.append(lip + Vector3(0, -4.9 * t * t, speed * t))
	for i in seg:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var wa := w * (1.0 + 0.5 * float(i) / seg)
		var wb := w * (1.0 + 0.5 * float(i + 1) / seg)
		var q := [a - Vector3(wa * 0.5, 0, 0), a + Vector3(wa * 0.5, 0, 0), b + Vector3(wb * 0.5, 0, 0), b - Vector3(wb * 0.5, 0, 0)]
		var uv := [Vector2(0, float(i) / seg), Vector2(1, float(i) / seg), Vector2(1, float(i + 1) / seg), Vector2(0, float(i + 1) / seg)]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_uv(uv[k])
			st.set_normal(Vector3(0, 0.2, 1).normalized())
			st.add_vertex(q[k])
	return st.commit()


## A weathered boulder: a noise-displaced ellipsoid.
static func rock_mesh(sd: int) -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = sd
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 7
	var segs := 10
	var ph := [r.randf() * TAU, r.randf() * TAU, r.randf() * TAU]
	var pts := {}
	for i in rings + 1:
		for j in segs + 1:
			var t := PI * i / rings
			var p := TAU * j / segs
			var d := Vector3(sin(t) * cos(p), cos(t), sin(t) * sin(p))
			var k := 1.0 + 0.16 * sin(d.x * 3.1 + ph[0]) * sin(d.z * 2.7 + ph[1]) + 0.1 * sin(d.y * 5.0 + ph[2])
			k *= 1.0 - 0.35 * maxf(0.0, -d.y)
			pts[Vector2i(i, j % segs)] = d * k
	for i in rings:
		for j in segs:
			var q := [pts[Vector2i(i, j)], pts[Vector2i(i + 1, j)], pts[Vector2i(i + 1, (j + 1) % segs)], pts[Vector2i(i, (j + 1) % segs)]]
			for idx in [0, 2, 1, 0, 3, 2]:
				st.add_vertex(q[idx])
	st.generate_normals()
	return st.commit()


static func multimesh(mesh: Mesh, xfs: Array, mat: Material, shadows: bool) -> MultiMeshInstance3D:
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
	return mmi
