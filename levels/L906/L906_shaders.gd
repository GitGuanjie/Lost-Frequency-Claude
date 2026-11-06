extends RefCounted
## Level 906 shaders (code strings, no binary textures).
##  BOOKS    - leather and vellum spines on a global 0.375 m shelf lattice, with
##             gilt bands, paper labels, gaps and the dark carcass behind.
##  CEILING  - the impossibly high ceiling: leaded stained-glass roses alternating
##             with painted landscape cartouches inside gilt ribs (page: "ornamented
##             with stained glass and painted landscapes").
##  PAINTING - framed canvas: a landscape, or (mode 1) the portrait of Blanche
##             (page: pale, long blonde hair, light blue eyes, tea gown).
##  GLOW     - additive halo for the Light Guides and candle flames.

const BOOKS := """
shader_type spatial;
render_mode diffuse_burley;
uniform float pitch = 0.375;
uniform float seed = 0.0;
varying vec3 wp;
varying vec3 wn;
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
float h2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
vec3 leather(float k) {
	k = floor(k * 10.0);
	if (k < 1.0) return vec3(0.32, 0.05, 0.04);
	if (k < 2.0) return vec3(0.06, 0.09, 0.22);
	if (k < 3.0) return vec3(0.07, 0.17, 0.09);
	if (k < 4.0) return vec3(0.42, 0.25, 0.12);
	if (k < 5.0) return vec3(0.05, 0.04, 0.035);
	if (k < 6.0) return vec3(0.24, 0.13, 0.06);
	if (k < 7.0) return vec3(0.48, 0.35, 0.15);
	if (k < 8.0) return vec3(0.66, 0.58, 0.44);
	if (k < 9.0) return vec3(0.20, 0.06, 0.13);
	return vec3(0.30, 0.18, 0.09);
}
void fragment() {
	vec3 t = normalize(vec3(-wn.z, 0.0, wn.x));
	float u = dot(wp, t);
	float y = wp.y / pitch;
	float row = floor(y);
	float ly = fract(y);
	float su = u / 0.13 + h2(vec2(row, seed)) * 7.0;
	float slot = floor(su);
	float sf = fract(su);
	float n = 1.0 + floor(h2(vec2(slot, row + seed * 3.1)) * 3.0);
	float bi = floor(sf * n);
	float bf = fract(sf * n);
	vec2 id = vec2(slot * 3.0 + bi, row + 17.0 * floor(wn.x * 2.0 + wn.z * 5.0));
	float board = 0.08;
	float top = board + (0.5 + 0.44 * h2(id + 1.7)) * (0.94 - board);
	bool gap = h2(id + 4.2) < 0.05;
	vec3 col;
	float rough = 0.6;
	float metal = 0.0;
	if (ly < board) {
		col = vec3(0.15, 0.085, 0.045);
		rough = 0.45;
	} else if (gap || ly > top) {
		col = vec3(0.022, 0.015, 0.01) * (0.5 + 0.5 * ly);
		rough = 1.0;
	} else {
		col = leather(h2(id + 0.37)) * (0.75 + 0.45 * h2(id + 9.0));
		float by = (ly - board) / (top - board);
		col *= 0.6 + 0.4 * sin(3.14159 * bf);
		float band = step(abs(by - 0.1), 0.014) + step(abs(by - 0.9), 0.014) + step(abs(by - 0.83), 0.007);
		if (h2(id + 2.9) < 0.72 && band > 0.0) {
			col = vec3(0.66, 0.49, 0.2) * (0.7 + 0.3 * sin(3.14159 * bf));
			metal = 0.85;
			rough = 0.3;
		}
		if (h2(id + 6.1) < 0.3 && abs(by - 0.6) < 0.07 && abs(bf - 0.5) < 0.3) {
			col = vec3(0.6, 0.52, 0.36);
		}
		col *= mix(0.35, 1.0, smoothstep(0.0, 0.1, bf) * smoothstep(1.0, 0.9, bf));
		rough = max(rough, 0.5 + 0.35 * h2(id + 3.3)) * (metal > 0.0 ? 0.6 : 1.0);
	}
	col *= mix(0.4, 1.0, smoothstep(1.0, 0.78, ly));
	ALBEDO = col;
	ROUGHNESS = rough;
	METALLIC = metal;
}
"""

const CEILING := """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform float cell = 9.0;
uniform float glow = 1.0;
varying vec3 wp;
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
float h2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(i), h2(i + vec2(1, 0)), f.x), mix(h2(i + vec2(0, 1)), h2(i + vec2(1, 1)), f.x), f.y);
}
vec3 jewel(float k) {
	k = floor(k * 6.0);
	if (k < 1.0) return vec3(0.75, 0.08, 0.06);
	if (k < 2.0) return vec3(0.08, 0.16, 0.7);
	if (k < 3.0) return vec3(0.85, 0.62, 0.12);
	if (k < 4.0) return vec3(0.1, 0.5, 0.25);
	if (k < 5.0) return vec3(0.45, 0.12, 0.55);
	return vec3(0.25, 0.55, 0.8);
}
void fragment() {
	vec2 p = wp.xz / cell;
	vec2 c = floor(p);
	vec2 f = fract(p) - 0.5;
	float frame = max(abs(f.x), abs(f.y));
	vec3 col;
	if (frame > 0.45) {
		col = vec3(0.34, 0.25, 0.1) * (0.6 + 0.5 * vn(wp.xz * 2.0)) * (0.6 + 0.4 * smoothstep(0.5, 0.47, frame));
	} else if (mod(c.x + c.y, 2.0) < 0.5) {
		float r = length(f) * 2.2;
		float a = atan(f.y, f.x) / 6.28318 + 0.5;
		float ring = floor(r * 5.0);
		float pet = (ring < 1.0) ? 1.0 : 6.0 + ring * 4.0;
		float sa = fract(a * pet);
		float lead = max(smoothstep(0.92, 0.98, abs(sa - 0.5) * 2.0), smoothstep(0.86, 0.95, abs(fract(r * 5.0) - 0.5) * 2.0));
		vec3 g = jewel(h2(vec2(ring, floor(a * pet)) + c * 3.0)) * (0.7 + 0.5 * vn(f * 40.0));
		col = (r < 1.0) ? mix(g * 1.6 * glow, vec3(0.03, 0.025, 0.02), lead) : vec3(0.06, 0.05, 0.04) + 0.05 * vn(wp.xz * 4.0);
	} else {
		vec2 q = f / 0.42;
		float ov = length(q * vec2(1.0, 1.25));
		if (ov > 1.0) {
			col = mix(vec3(0.42, 0.31, 0.12), vec3(0.08, 0.06, 0.05), smoothstep(1.0, 1.06, ov));
		} else {
			float s = q.y * 0.5 + 0.5;
			col = mix(vec3(0.85, 0.72, 0.52), vec3(0.32, 0.46, 0.66), smoothstep(0.35, 1.0, s));
			col = mix(col, vec3(0.95, 0.9, 0.82), smoothstep(0.6, 0.8, vn(q * vec2(3.0, 7.0) + c)) * 0.6 * step(0.45, s));
			float m1 = 0.38 + 0.08 * sin(q.x * 4.0 + c.x * 2.0) + 0.04 * vn(q * 6.0 + c);
			if (s < m1) col = vec3(0.36, 0.42, 0.52);
			float m2 = 0.24 + 0.07 * sin(q.x * 2.3 + c.y) + 0.03 * sin(q.x * 9.0);
			if (s < m2) col = mix(vec3(0.2, 0.32, 0.12), vec3(0.32, 0.4, 0.16), vn(q * 9.0 + c));
			col *= 0.85;
		}
	}
	ALBEDO = col;
}
"""

const PAINTING := """
shader_type spatial;
uniform int mode = 0;
uniform float seed = 0.0;
float h2(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vn(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(i), h2(i + vec2(1, 0)), f.x), mix(h2(i + vec2(0, 1)), h2(i + vec2(1, 1)), f.x), f.y);
}
void fragment() {
	vec2 uv = vec2(UV.x, 1.0 - UV.y);
	vec3 col;
	float brush = vn(uv * vec2(60.0, 18.0) + seed) * 0.08;
	if (mode == 1) {
		col = mix(vec3(0.05, 0.1, 0.08), vec3(0.12, 0.18, 0.14), uv.y);
		vec2 hc = uv - vec2(0.5, 0.6);
		float hair = length(hc * vec2(1.7, 0.9));
		if (hair < 0.27 && uv.y > 0.25) col = vec3(0.86, 0.72, 0.42) * (0.85 + 0.3 * vn(uv * vec2(80.0, 6.0)));
		float gown = length((uv - vec2(0.5, 0.0)) * vec2(1.25, 1.5));
		if (gown < 0.42) col = vec3(0.68, 0.78, 0.9) * (0.8 + 0.2 * uv.y);
		vec2 fc = uv - vec2(0.5, 0.64);
		if (length(fc * vec2(1.0, 0.78)) < 0.115) {
			col = vec3(0.94, 0.86, 0.8);
			if (length(fc - vec2(-0.04, 0.02)) < 0.014 || length(fc - vec2(0.04, 0.02)) < 0.014) col = vec3(0.45, 0.68, 0.9);
			if (abs(fc.y + 0.055) < 0.006 && abs(fc.x) < 0.025) col = vec3(0.7, 0.38, 0.4);
		}
		if (uv.x > 0.7 && uv.x < 0.92 && uv.y > 0.05 && uv.y < 0.09) col = mix(col, vec3(0.12, 0.08, 0.05), step(0.5, vn(uv * vec2(120.0, 40.0))));
	} else {
		float s = uv.y;
		col = mix(vec3(0.86, 0.76, 0.56), vec3(0.36, 0.5, 0.68), smoothstep(0.4, 1.0, s));
		if (s < 0.5 + 0.06 * sin(uv.x * 7.0 + seed) + 0.05 * vn(uv * 9.0 + seed)) col = vec3(0.38, 0.45, 0.55);
		if (s < 0.34 + 0.08 * sin(uv.x * 3.0 + seed * 2.0)) col = mix(vec3(0.2, 0.3, 0.12), vec3(0.34, 0.38, 0.14), vn(uv * 20.0));
		if (s < 0.14) col = vec3(0.24, 0.2, 0.1);
	}
	ALBEDO = col * (0.92 + brush);
	ROUGHNESS = 0.75;
}
"""

const GLOW := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
uniform vec3 tint : source_color = vec3(1.0, 0.85, 0.6);
uniform float energy = 1.0;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	float d = length(UV - 0.5) * 2.0;
	float a = pow(max(0.0, 1.0 - d), 2.2);
	ALBEDO = tint * a * energy;
}
"""


static func mat(code: String, params: Dictionary = {}) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	for k in params.keys():
		m.set_shader_parameter(k, params[k])
	return m
