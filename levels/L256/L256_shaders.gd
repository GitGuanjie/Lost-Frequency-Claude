extends RefCounted
## Level 256 shader sources (all procedural; no textures). Kept apart from the
## level script so each file stays inside the per-file size budget.
##
## SCREEN — every terminal display. One shader, one material per screen, so a
##          screen can change program on its own (SOURCE: "they turn on on
##          their own now"). Programs follow the page's list of recorded
##          programs: 1 faint static (the most common), 2 a distorted
##          recording of the viewer (inverted / infrared / coloured outlines),
##          3 a low-definition early 3D demonstration (wireframe solid, copper
##          bars, a checker floor: the demoscene look), 4 a simple, banal game
##          with no ending, 5 a blank black screen (its loud tone is audio).
##          0 is a screen that is off; 9 is a back-lit marquee whose "game
##          franchise" logo is an invented pixel glyph (no real brand shown).
## NEON   — the neon blue strips and fixtures; one uniform dims them all as
##          the place gets darker.
## WINDOW — big dark windows onto a featureless exterior: black glass with a
##          faint neon reflection that the dark swallows as you stare.

const SCREEN := """
shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled, fog_disabled;
uniform int program = 1;
uniform float seedv = 0.0;
uniform float power = 1.0;
uniform float boot = 1.0;
uniform float jump_t = -10.0;
uniform float now = 0.0;
uniform float dread = 0.0;
uniform float scare = 0.0;
uniform float bright = 1.0;
uniform vec2 res = vec2(160.0, 112.0);
uniform vec3 brand = vec3(0.9, 0.2, 0.3);
uniform sampler2D feed : source_color, filter_linear;

float h21(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }

float seg(vec2 p, vec2 a, vec2 b) { vec2 pa = p - a; vec2 ba = b - a; float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0); return length(pa - ba * h); }

vec3 rot(vec3 v, float a, float b) {
	float ca = cos(a); float sa = sin(a); float cb = cos(b); float sb = sin(b);
	v = vec3(ca * v.x + sa * v.z, v.y, -sa * v.x + ca * v.z);
	return vec3(v.x, cb * v.y - sb * v.z, sb * v.y + cb * v.z);
}

vec2 proj(vec3 v) { return v.xy / (v.z + 3.2) * 1.6; }

vec3 static_prog(vec2 uv, float t) {
	vec2 px = floor(uv * res);
	float n = h21(px + vec2(floor(t * 24.0) * 17.0, seedv * 31.0));
	float roll = smoothstep(0.0, 0.08, abs(fract(uv.y * 0.7 - t * 0.21) - 0.5));
	return vec3(0.12 + n * 0.32) * mix(1.25, 1.0, roll);
}

vec3 feed_prog(vec2 uv, float t) {
	float mode = mod(floor(t / 5.0 + seedv * 3.0), 3.0);
	vec2 u = uv;
	float tear = h21(vec2(floor(uv.y * 48.0), floor(t * 9.0)));
	u.x += (tear - 0.5) * 0.015 * (1.0 + dread * 4.0) * step(0.86 - dread * 0.2, tear);
	vec2 q = vec2(u.x, 1.0 - u.y);
	vec3 c = texture(feed, q).rgb;
	float l = dot(c, vec3(0.3, 0.55, 0.15));
	vec3 o;
	if (mode < 0.5) {
		o = vec3(1.0) - c * 1.4;
	} else if (mode < 1.5) {
		float k = clamp(l * 3.2, 0.0, 1.0);
		o = mix(mix(vec3(0.05, 0.0, 0.3), vec3(0.9, 0.1, 0.2), smoothstep(0.0, 0.5, k)), vec3(1.0, 0.95, 0.4), smoothstep(0.5, 1.0, k));
	} else {
		vec2 e = vec2(1.0 / 192.0, 1.0 / 144.0);
		float lx = dot(texture(feed, q + vec2(e.x, 0.0)).rgb - texture(feed, q - vec2(e.x, 0.0)).rgb, vec3(0.33));
		float ly = dot(texture(feed, q + vec2(0.0, e.y)).rgb - texture(feed, q - vec2(0.0, e.y)).rgb, vec3(0.33));
		float ed = clamp(length(vec2(lx, ly)) * 9.0, 0.0, 1.0);
		o = mix(vec3(0.0), vec3(0.2, 1.0, 0.85) * (0.6 + 0.4 * sin(uv.y * 40.0 + t * 3.0)), ed) + vec3(0.9, 0.2, 0.8) * ed * step(0.5, fract(uv.x * 3.0 + t));
	}
	return o;
}

vec3 demo_prog(vec2 uv, float t) {
	vec2 p = (floor(uv * res) + 0.5) / res;
	vec2 c = (p - 0.5) * vec2(res.x / res.y, 1.0);
	vec3 col = vec3(0.0);
	float st = h21(floor(p * res * 0.5) + floor(vec2(t * 3.0, 0.0)));
	col += vec3(step(0.985, st)) * 0.6;
	for (int k = 0; k < 5; k++) {
		float cy = 0.5 + 0.36 * sin(t * 1.3 + float(k) * 0.55);
		float d = abs(p.y - cy);
		vec3 bc = 0.5 + 0.5 * cos(6.2831 * (vec3(0.0, 0.33, 0.67) + float(k) * 0.18));
		col = max(col, bc * smoothstep(0.045, 0.0, d) * 0.85);
	}
	if (p.y < 0.3) {
		float z = 0.3 / max(0.3 - p.y, 0.01);
		vec2 g = vec2(c.x * z, z + t * 1.5);
		float ch = mod(floor(g.x) + floor(g.y), 2.0);
		col = mix(vec3(0.05, 0.02, 0.2), vec3(0.2, 0.45, 1.0), ch) * clamp(0.3 - p.y, 0.0, 0.3) * 3.0;
	}
	vec3 v[8];
	for (int i = 0; i < 8; i++) {
		vec3 q = vec3(float(i & 1) * 2.0 - 1.0, float((i >> 1) & 1) * 2.0 - 1.0, float((i >> 2) & 1) * 2.0 - 1.0);
		v[i] = rot(q * 0.62, t * 0.7 + seedv, t * 0.45);
	}
	float dm = 9.0;
	for (int i = 0; i < 8; i++) {
		for (int b = 0; b < 3; b++) {
			int j = i ^ (1 << b);
			if (j > i) { dm = min(dm, seg(c, proj(v[i]), proj(v[j]))); }
		}
	}
	col = mix(col, vec3(0.75, 0.95, 1.0), smoothstep(0.012, 0.0, dm));
	return col;
}

vec3 game_prog(vec2 uv, float t) {
	vec2 p = (floor(uv * vec2(96.0, 64.0)) + 0.5) / vec2(96.0, 64.0);
	vec3 col = mix(vec3(0.35, 0.55, 1.0), vec3(0.6, 0.85, 1.0), p.y);
	float hill = 0.3 + 0.05 * sin(p.x * 9.0 + floor(t * 2.0) * 0.4);
	if (p.y < hill) col = vec3(0.2, 0.62, 0.2);
	if (p.y < 0.25) col = mix(vec3(0.55, 0.32, 0.12), vec3(0.45, 0.25, 0.1), step(0.5, fract(p.x * 12.0 + t * 1.6)));
	float dt = now - jump_t;
	float jy = (dt > 0.0 && dt < 0.7) ? dt * (0.7 - dt) * 1.6 : 0.0;
	vec2 hero = vec2(0.22, 0.25 + jy + 0.06);
	if (abs(p.x - hero.x) < 0.035 && abs(p.y - hero.y) < 0.06) col = vec3(0.95, 0.15, 0.1);
	if (abs(p.x - hero.x - 0.01) < 0.012 && abs(p.y - hero.y - 0.025) < 0.012) col = vec3(1.0, 0.85, 0.6);
	float ox = fract(-t * 0.27 + seedv);
	if (abs(p.x - ox) < 0.03 && p.y > 0.25 && p.y < 0.33) col = vec3(0.1, 0.4, 0.1);
	float sc = mod(floor(t * 4.0), 100000.0);
	if (p.y > 0.88 && p.x > 0.6 && p.x < 0.95) {
		float dg = floor((p.x - 0.6) / 0.07);
		float dv = mod(floor(sc / pow(10.0, 4.0 - dg)), 10.0);
		vec2 cc = fract(vec2((p.x - 0.6) / 0.07, (p.y - 0.88) / 0.09));
		if (h21(vec2(dv, floor(cc.x * 3.0) + floor(cc.y * 4.0) * 3.0)) > 0.45 && cc.x < 0.75) col = vec3(1.0);
	}
	return col;
}

vec3 marquee(vec2 uv, float t) {
	vec3 bg = mix(brand * 0.25, brand, smoothstep(0.0, 1.0, uv.y));
	bg = mix(bg, vec3(0.02), smoothstep(0.42, 0.5, abs(uv.y - 0.5)));
	vec2 g = vec2(uv.x * 30.0, uv.y * 7.0);
	vec2 cell = floor(g);
	float letter = floor(cell.x / 6.0);
	vec2 lc = vec2(mod(cell.x, 6.0), cell.y - 1.0);
	float on = (lc.x < 5.0 && lc.y >= 0.0 && lc.y < 5.0 && letter >= 0.0 && letter < 5.0) ? step(0.42, h21(vec2(lc.x + letter * 7.0 + seedv * 13.0, lc.y))) : 0.0;
	vec3 col = mix(bg, vec3(1.0, 0.97, 0.85), on);
	return col * (0.85 + 0.15 * sin(uv.x * 3.0 + t * 0.2));
}

void fragment() {
	vec2 uv = UV;
	float t = TIME + seedv * 11.0;
	vec3 col = vec3(0.0);
	if (program == 9) {
		col = marquee(uv, t) * bright;
		ALBEDO = col;
	} else {
		if (program == 1) col = static_prog(uv, t);
		else if (program == 2) col = feed_prog(uv, t);
		else if (program == 3) col = demo_prog(uv, t);
		else if (program == 4) col = game_prog(uv, t);
		else col = vec3(0.0);
		if (scare > 0.0) col = mix(col, vec3(1.0) - feed_prog(uv, t * 7.0).bgr, scare);
		float scan = 0.82 + 0.18 * sin(uv.y * res.y * 3.14159);
		vec2 v = uv - 0.5;
		float vig = 1.0 - dot(v, v) * 1.3;
		float bline = smoothstep(0.0, 0.02, boot * 0.5 - abs(uv.y - 0.5)) * smoothstep(0.0, 0.02, boot * 0.6 + 0.02 - abs(uv.x - 0.5));
		col *= scan * vig * bline * power;
		vec3 glass = vec3(0.012, 0.014, 0.022) + vec3(0.03, 0.05, 0.09) * smoothstep(0.7, 0.0, abs(uv.x + uv.y - 0.9)) * 0.6;
		ALBEDO = glass + col * 1.35 * bright;
	}
}
"""

const NEON := """
shader_type spatial;
render_mode unshaded, cull_back, shadows_disabled;
uniform vec3 color : source_color = vec3(0.2, 0.5, 1.0);
uniform float energy = 4.0;
uniform float dim = 1.0;
void fragment() {
	ALBEDO = color * energy * dim;
}
"""

const WINDOW := """
shader_type spatial;
render_mode cull_back, specular_schlick_ggx;
uniform float heavy = 0.0;
uniform float dark = 0.0;
uniform vec3 neon : source_color = vec3(0.12, 0.32, 1.0);
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
float band(float y, float c, float w) { return exp(-pow((y - c) / w, 2.0)); }
void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0);
	float along = wp.x + wp.z;
	// ghosts of the room's own neon in the black glass: the skirting, the
	// gallery lip, the ceiling lines, the kiosks' glow (fake reflections)
	float r = band(wp.y, 0.3, 0.05) * 0.9 + band(wp.y, 4.15, 0.04) * 0.7 + band(wp.y, 8.2, 0.06) * 0.6;
	r += band(wp.y, 1.7, 0.35) * 0.18 * smoothstep(0.6, 1.0, sin(along * 0.37 + 1.3));
	r *= 0.55 + 0.45 * sin(along * 0.11);
	if (wp.x > 1.8 && wp.x < 8.9 && wp.y > 2.0) {
		float cell = floor((wp.x - 1.725) / 0.55);
		float tube = smoothstep(0.05, 0.0, abs(fract((wp.x - 1.725) / 0.55) - 0.5) * 0.55);
		r += tube * step(2.4 + 3.2 * fract(sin(cell * 12.9898) * 43758.5453), wp.y) * 0.45;
	}
	float k = (1.0 - heavy * 0.9) * (1.0 - dark * 0.55);
	ALBEDO = vec3(0.0);
	ROUGHNESS = 0.03;
	SPECULAR = 0.85 * k;
	EMISSION = neon * (0.01 + fres * 0.12 + r * (0.35 + fres * 0.6)) * k;
}
"""
