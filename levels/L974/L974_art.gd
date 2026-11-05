extends RefCounted
## Level 974 procedural artwork (no image files).
## WINDOW: the windows "simply reveal artwork depicting what one would typically
##   see outdoors, except with a notably coquette theming" (SOURCE) — a painted
##   pastel landscape: pink sky, soft clouds, mint hills, blossom trees, a white
##   picket fence, hearts in the sky, brush strokes and canvas weave.
## POSTER: generic cute posters (ADAPTATION: no trademarked mascots — the page
##   names Sanrio/San-X, which we never reproduce) — a smiling bear, cloud or
##   star on a pastel field with dots, stripes or checks, varied per seed.

const COMMON := """
float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash12(i), hash12(i + vec2(1, 0)), f.x), mix(hash12(i + vec2(0, 1)), hash12(i + vec2(1, 1)), f.x), f.y);
}
float fbm(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		s += a * vnoise(p);
		p = p * 2.03 + vec2(17.1, 3.7);
		a *= 0.5;
	}
	return s;
}
float dot2(vec2 v) { return dot(v, v); }
float heart(vec2 p) {
	p.x = abs(p.x);
	if (p.y + p.x > 1.0) {
		return sqrt(dot2(p - vec2(0.25, 0.75))) - 0.35355;
	}
	return sqrt(min(dot2(p - vec2(0.0, 1.0)), dot2(p - 0.5 * max(p.x + p.y, 0.0)))) * sign(p.x - p.y);
}
float disk(vec2 p, vec2 c, vec2 r) {
	return smoothstep(1.0, 0.92, length((p - c) / r));
}
"""

const WINDOW_T := """
shader_type spatial;
render_mode unshaded, cull_back;
uniform float seed = 0.0;
uniform float glow = 1.0;
uniform float torn = 0.0;
%s
void fragment() {
	vec2 uv = UV;
	float t = 1.0 - uv.y;
	vec2 q = vec2(uv.x, t);
	vec3 col = mix(vec3(1.0, 0.93, 0.89), vec3(0.98, 0.70, 0.81), smoothstep(0.32, 1.0, t));
	float cl = fbm(vec2(uv.x * 3.2 + seed * 5.0, t * 6.5));
	col = mix(col, vec3(1.0, 0.97, 0.98), smoothstep(0.55, 0.70, cl) * smoothstep(0.42, 0.78, t) * 0.9);
	col = mix(col, vec3(1.0, 0.95, 0.84), disk(q * vec2(1.0, 1.25), vec2(0.72 + 0.12 * sin(seed * 3.1), 0.98), vec2(0.08)));
	float h1 = 0.37 + 0.06 * sin(uv.x * 5.0 + seed * 3.0) + 0.025 * sin(uv.x * 13.0 + seed);
	float h2 = 0.25 + 0.05 * sin(uv.x * 7.0 + 1.3 + seed);
	col = mix(col, vec3(0.80, 0.93, 0.82), smoothstep(h1 + 0.004, h1 - 0.004, t));
	col = mix(col, vec3(0.64, 0.86, 0.70), smoothstep(h2 + 0.004, h2 - 0.004, t));
	for (int i = 0; i < 4; i++) {
		float fx = fract(seed * 0.37 + float(i) * 0.271);
		vec2 tc = vec2(0.08 + fx * 0.84, h1 + 0.02);
		float trunk = step(abs(uv.x - tc.x), 0.007) * step(t, tc.y + 0.05) * step(h1 - 0.03, t);
		col = mix(col, vec3(0.55, 0.38, 0.42), trunk);
		col = mix(col, vec3(1.0, 0.70, 0.82) * (0.88 + 0.16 * fbm(uv * 38.0 + float(i))), disk(q * vec2(1.0, 1.2), (tc + vec2(0.0, 0.08)) * vec2(1.0, 1.2), vec2(0.075)));
	}
	float fx = fract(uv.x * 22.0);
	float post = step(fx, 0.42) * step(0.07, t) * step(t, 0.20 - abs(fx - 0.21) * 0.25);
	float rail = (step(abs(t - 0.12), 0.007) + step(abs(t - 0.165), 0.007)) * step(0.07, t);
	col = mix(col, vec3(1.0, 0.985, 0.975), clamp(post + rail, 0.0, 1.0));
	for (int i = 0; i < 6; i++) {
		vec2 hc = vec2(0.06 + fract(seed * 0.71 + float(i) * 0.193) * 0.88, 0.52 + fract(float(i) * 0.37 + seed * 0.13) * 0.42);
		float hd = heart((q - hc) * 30.0 + vec2(0.0, 0.5));
		col = mix(col, vec3(0.96, 0.50, 0.66), smoothstep(0.06, -0.06, hd) * 0.92);
	}
	col *= 0.94 + 0.07 * fbm(uv * vec2(70.0, 16.0));
	col *= 0.975 + 0.025 * sin(uv.x * 900.0) * sin(uv.y * 640.0);
	if (torn > 0.0) {
		float rip = smoothstep(0.45, 0.5, fbm(uv * 4.0 + 7.0));
		col = mix(col, vec3(0.16, 0.10, 0.12), rip * torn);
	}
	ALBEDO = col * glow;
}
"""

const POSTER_T := """
shader_type spatial;
render_mode cull_back, diffuse_burley;
uniform float seed = 0.0;
uniform vec3 bg : source_color = vec3(0.75, 0.88, 1.0);
uniform vec3 fg : source_color = vec3(1.0, 0.8, 0.9);
%s
void fragment() {
	vec2 uv = UV;
	vec2 q = vec2(uv.x, 1.0 - uv.y);
	vec3 col = bg;
	float kind = floor(fract(seed * 0.618) * 3.0);
	float pat = floor(fract(seed * 0.377) * 3.0);
	if (pat < 1.0) {
		col = mix(col, fg, step(0.82, 1.0 - length(fract(q * 9.0) - 0.5) * 2.2) * 0.6);
	} else if (pat < 2.0) {
		col = mix(col, fg, step(0.5, fract((q.x + q.y) * 7.0)) * 0.35);
	} else {
		col = mix(col, fg, step(0.5, fract(floor(q.x * 8.0) * 0.5 + floor(q.y * 10.0) * 0.5)) * 0.35);
	}
	vec2 c = vec2(0.5, 0.52);
	vec3 face = vec3(1.0, 0.97, 0.93);
	float m = 0.0;
	if (kind < 1.0) {
		face = vec3(0.86, 0.68, 0.52);
		m = max(disk(q, c, vec2(0.28, 0.22)), max(disk(q, c + vec2(-0.21, 0.19), vec2(0.08, 0.065)), disk(q, c + vec2(0.21, 0.19), vec2(0.08, 0.065))));
	} else if (kind < 2.0) {
		m = max(disk(q, c, vec2(0.30, 0.17)), max(disk(q, c + vec2(-0.14, 0.09), vec2(0.15, 0.12)), disk(q, c + vec2(0.12, 0.12), vec2(0.17, 0.14))));
	} else {
		face = vec3(1.0, 0.90, 0.55);
		vec2 p = (q - c) * vec2(1.0, 1.0);
		float a = atan(p.y, p.x);
		float r = 0.17 + 0.09 * cos(a * 5.0 + 1.5708);
		m = smoothstep(r + 0.01, r - 0.01, length(p));
	}
	col = mix(col, face, m);
	float eyes = max(disk(q, c + vec2(-0.075, 0.015), vec2(0.022, 0.03)), disk(q, c + vec2(0.075, 0.015), vec2(0.022, 0.03)));
	col = mix(col, vec3(0.12, 0.08, 0.1), eyes * m);
	float blush = max(disk(q, c + vec2(-0.13, -0.04), vec2(0.04, 0.022)), disk(q, c + vec2(0.13, -0.04), vec2(0.04, 0.022)));
	col = mix(col, vec3(1.0, 0.6, 0.7), blush * m * 0.8);
	float mouth = smoothstep(0.012, 0.0, abs(length(q - (c + vec2(0.0, -0.01))) - 0.035)) * step(q.y, c.y - 0.01);
	col = mix(col, vec3(0.3, 0.12, 0.16), mouth * m);
	float edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
	col = mix(vec3(1.0), col, smoothstep(0.02, 0.03, edge));
	ALBEDO = col * (0.96 + 0.04 * vnoise(uv * 300.0));
	ROUGHNESS = 0.55;
}
"""


static func window_mat(seed_value: float) -> ShaderMaterial:
	return _mat(WINDOW_T % COMMON, {"seed": seed_value, "glow": 1.05})


static func poster_mat(seed_value: float, bg: Color, fg: Color) -> ShaderMaterial:
	return _mat(POSTER_T % COMMON, {"seed": seed_value, "bg": Vector3(bg.r, bg.g, bg.b), "fg": Vector3(fg.r, fg.g, fg.b)})


static var _shaders: Dictionary = {}


static func _mat(code: String, params: Dictionary) -> ShaderMaterial:
	if not _shaders.has(code):
		var sh := Shader.new()
		sh.code = code
		_shaders[code] = sh
	var m := ShaderMaterial.new()
	m.shader = _shaders[code]
	for k in params.keys():
		m.set_shader_parameter(k, params[k])
	return m
