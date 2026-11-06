extends RefCounted
## Level 404 shader sources (all procedural; no textures). Kept apart from the
## level script so each file stays inside the per-file size budget.
##
## SKY    — the skybox as an object: a pastel "lovely day" painted on the inside
##          of a cube, pixel clouds that do not line up across the seams, a flat
##          square sun, sky tiles that go missing (magenta/black checker) as the
##          wanderer becomes aware, and the broken corner she led you to.
##          shard_mode = 1 turns it into a mirror of that sky for the pieces of
##          sky lying around ("the sharpest piece of the sky", SOURCE).
## DISC   — the 404th circle: pearl tracks like a platter, tiles that flicker
##          ("the ground flickers beneath your feet", SOURCE) and, on demand,
##          tiles that are simply not there (drop_ids).
## PLANE  — intersecting planes with a 3D-editor grid whose vertices stutter
##          ("as the 3d mesh glitches", SOURCE).
## FRAG   — memory fragments: datamoshed pastel images (ADAPTATION; the page is
##          illustrated with three credited glitch-art images we do not ship).
## MIND   — screen layer: macroblock datamosh, chroma split, milky haze when
##          memories cloud the mind, and the white of a cut.

const SKY := """
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled, shadows_disabled;
uniform float err = 0.0;
uniform float calm = 0.0;
uniform float half_size = 64.0;
uniform vec3 crack_pos = vec3(0.0, 3.0, 64.0);
uniform float crack_r = 6.5;
uniform float shard_mode = 0.0;
uniform float glint = 0.0;
varying vec3 wp;

float hash(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }
float vnoise(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y); }
float fbm(vec2 p) { float v = 0.0; float a = 0.5; for (int i = 0; i < 4; i++) { v += a * vnoise(p); p *= 2.03; a *= 0.5; } return v; }

vec3 sky_at(vec3 p) {
	vec3 d = normalize(p);
	float e = d.y;
	vec3 zen = vec3(0.22, 0.34, 0.80);
	vec3 blu = vec3(0.46, 0.64, 0.96);
	vec3 hor = vec3(0.98, 0.76, 0.74);
	vec3 low = vec3(0.80, 0.50, 0.72);
	vec3 deep = vec3(0.20, 0.10, 0.32);
	vec3 c = mix(hor, blu, smoothstep(0.0, 0.32, e));
	c = mix(c, zen, smoothstep(0.32, 0.95, e));
	c = mix(c, low, smoothstep(0.0, -0.12, e));
	c = mix(c, deep, smoothstep(-0.12, -0.75, e));
	vec3 a = abs(p);
	vec2 fuv; float face;
	if (a.x >= a.y && a.x >= a.z) { fuv = p.zy; face = sign(p.x); }
	else if (a.z >= a.y) { fuv = p.xy; face = 3.0 + sign(p.z); }
	else { fuv = p.xz; face = 6.0 + sign(p.y); }
	// clouds in big pixels; each face is offset so they never meet at a seam
	vec2 px = floor((fuv + vec2(face * 17.3, face * 5.1)) / 1.7);
	float cl = fbm(px * 0.085 + vec2(TIME * 0.006, face));
	float band = smoothstep(0.04, 0.22, e) * smoothstep(0.85, 0.30, e);
	float cm = smoothstep(0.54, 0.68, cl) * band;
	c = mix(c, mix(vec3(1.0, 0.80, 0.86), vec3(1.0, 0.97, 0.98), smoothstep(0.55, 0.72, cl)), cm * 0.9);
	// a flat square sun on the +x face
	vec2 sq = abs(p.zy - vec2(-10.0, 46.0));
	float onx = step(0.5, face) * step(face, 1.5);
	float sun = onx * step(max(sq.x, sq.y), 4.5);
	c = mix(c, vec3(1.6, 1.45, 1.2), sun);
	c += vec3(1.0, 0.9, 0.7) * 0.25 * onx * smoothstep(14.0, 4.5, max(sq.x, sq.y));
	// seams where the faces meet
	float nx = step(half_size - 0.5, a.x); float ny = step(half_size - 0.5, a.y); float nz = step(half_size - 0.5, a.z);
	float seam = step(1.5, nx + ny + nz) * step(0.5, shard_mode * -1.0 + 1.0);
	c = mix(c, vec3(1.3, 1.25, 1.35), seam * 0.8);
	// missing sky tiles while the wanderer is aware
	vec2 big = floor(fuv / 3.2);
	float dcr = distance(p, crack_pos);
	float miss = step(hash(big + vec2(face * 3.7, face)), err * err * 0.012 + err * 0.1 * smoothstep(26.0, 9.0, dcr));
	vec2 ck = floor(fuv / 0.8);
	vec3 checker = mod(ck.x + ck.y, 2.0) < 1.0 ? vec3(0.95, 0.0, 0.8) : vec3(0.03, 0.0, 0.05);
	vec2 vg = abs(fract(fuv / 2.0) - 0.5);
	vec3 voidc = vec3(0.05, 0.015, 0.10) + vec3(0.25, 0.1, 0.45) * smoothstep(0.47, 0.5, max(vg.x, vg.y));
	voidc = mix(voidc, checker, step(0.9, hash(floor(fuv / 1.6) + vec2(3.0, 1.0))));
	// the broken corner of the sky
	float dc = distance(p, crack_pos);
	float jag = (fbm(fuv * 0.55) - 0.5) * 6.0 + (hash(floor(fuv * 1.4)) - 0.5) * 1.6;
	float inside = step(dc + jag, crack_r) * (1.0 - shard_mode);
	c = mix(c, voidc, inside);
	c = mix(c, checker, miss * (1.0 - shard_mode) * (1.0 - inside));
	float rim = smoothstep(1.4, 0.0, abs(dc + jag - crack_r)) * (1.0 - shard_mode);
	c += vec3(1.0, 0.85, 1.0) * rim * 0.9;
	return c * (0.84 + calm * 0.08);
}

void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }

void fragment() {
	vec3 col;
	if (shard_mode > 0.5) {
		vec3 wn = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
		vec3 wv = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
		vec3 r = reflect(-wv, wn);
		vec3 m = abs(r);
		vec3 p = r * half_size / max(max(m.x, m.y), max(m.z, 0.001));
		col = sky_at(p);
		float fr = pow(1.0 - abs(dot(wn, wv)), 3.0);
		col = mix(col, vec3(1.4, 1.3, 1.45), fr * 0.7);
		col += vec3(1.2, 1.0, 1.3) * glint * (0.5 + 0.5 * sin(TIME * 4.0));
	} else {
		col = sky_at(wp);
	}
	ALBEDO = col;
}
"""

const DISC := """
shader_type spatial;
render_mode cull_disabled;
uniform float err = 0.0;
uniform float calm = 0.0;
uniform float dim = 1.0;
uniform float drop_ids[8];
varying vec3 wp;
varying vec3 wn;
varying flat float tid;

float h1(float n) { return fract(sin(n * 127.1 + 0.37) * 43758.5453); }

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
	tid = UV2.x;
}

void fragment() {
	for (int i = 0; i < 8; i++) { if (abs(drop_ids[i] - tid) < 0.5) { discard; } }
	float r = length(wp.xz);
	float ang = atan(wp.z, wp.x);
	float tr = fract(r * 2.5);
	float groove = smoothstep(0.0, 0.08, tr) * smoothstep(1.0, 0.92, tr);
	vec3 pearl = 0.5 + 0.5 * cos(6.2831 * (vec3(0.0, 0.33, 0.67) + r * 0.03 + ang * 0.159));
	vec3 base = mix(vec3(0.76, 0.74, 0.84), pearl, 0.26);
	base *= mix(0.62, 1.0, groove);
	float side = 1.0 - smoothstep(0.4, 0.8, abs(wn.y));
	base = mix(base, vec3(0.62, 0.55, 0.78), side);
	float t = floor(TIME * (5.0 + err * 16.0));
	float fl = h1(tid * 1.37 + t);
	float ev = step(fl, 0.010 + err * 0.11) * (1.0 - calm);
	base = mix(base, vec3(0.70, 0.86, 1.0), ev * 0.65);
	if (ev > 0.5 && h1(tid + t * 3.1) < 0.25 + err) {
		vec2 g = floor(FRAGCOORD.xy / 3.0);
		if (mod(g.x + g.y, 2.0) < 1.0) { discard; }
	}
	ALBEDO = base * dim;
	ROUGHNESS = 0.42;
	METALLIC = 0.08;
	SPECULAR = 0.4;
	EMISSION = base * (0.02 + 0.06 * calm) * dim + vec3(0.4, 0.6, 1.0) * ev * 0.35;
}
"""

const PLANE := """
shader_type spatial;
render_mode cull_disabled;
uniform float err = 0.0;
uniform vec3 tint : source_color = vec3(0.60, 0.62, 0.92);
uniform vec3 line_col : source_color = vec3(0.86, 0.9, 1.0);
varying vec3 wp;
varying vec3 wn;

float h(float n) { return fract(sin(n * 91.3 + 0.17) * 43758.5453); }

void vertex() {
	float id = UV2.x;
	float t = floor(TIME * 11.0);
	float burst = step(0.988 - err * 0.07, h(id * 3.1 + t));
	VERTEX += (vec3(h(t + id), h(t * 1.3 + id), h(t * 1.7 + id)) - 0.5) * burst * (0.25 + err * 1.1);
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}

void fragment() {
	vec3 n = abs(normalize(wn));
	vec2 uv = n.y > 0.6 ? wp.xz : (n.x > n.z ? wp.zy : wp.xy);
	vec2 g = abs(fract(uv) - 0.5);
	float line = smoothstep(0.465, 0.495, max(g.x, g.y));
	vec2 g4 = abs(fract(uv / 4.0) - 0.5);
	float line4 = smoothstep(0.482, 0.497, max(g4.x, g4.y));
	float grad = clamp(wp.y / 14.0, -0.3, 1.0);
	vec3 c = mix(tint, vec3(1.0, 0.88, 0.92), grad * 0.35);
	c = mix(c, line_col, line * 0.4 + line4 * 0.7);
	ALBEDO = c;
	ROUGHNESS = 0.5;
	EMISSION = line_col * (line4 * 0.6 + line * 0.12);
}
"""

const FRAG := """
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
uniform float seedv = 0.0;
uniform float kind = 0.0;
uniform float blank = 0.0;
uniform float err = 0.0;

float h12(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }

void fragment() {
	vec2 uv = UV;
	float t = floor(TIME * (1.5 + err * 9.0));
	float rows = h12(vec2(floor(uv.y * 36.0), seedv + t));
	uv.x += step(0.82, rows) * (rows - 0.82) * 1.6;
	vec3 c = 0.5 + 0.5 * cos(6.2831 * (vec3(0.0, 0.12, 0.24) + uv.y * 0.55 + seedv * 0.31 + uv.x * 0.18));
	c = mix(c, vec3(1.0, 0.75, 0.9), 0.12);
	float shape = 0.0;
	if (kind < 0.5) {            // a monument against a pale sky
		float w = 0.08 + (1.0 - uv.y) * 0.12;
		shape = step(abs(uv.x - 0.5 - (1.0 - uv.y) * 0.08), w) * step(0.22, uv.y);
		shape = max(shape, step(abs(uv.x - 0.5), 0.3) * step(0.86, uv.y));
	} else if (kind < 1.5) {     // an apparition: a smeared, ghosted band
		float g = 0.0;
		for (int i = 0; i < 5; i++) { g += step(abs(uv.x - 0.42 - float(i) * 0.035), 0.05) * step(0.3, uv.y) * 0.22; }
		shape = g;
	} else {                     // deeper: frames inside frames
		vec2 q = abs(uv - 0.5);
		float m = max(q.x * 1.2, q.y);
		shape = step(0.5, fract(m * 9.0 - TIME * 0.15)) * 0.6;
	}
	c = mix(c, vec3(0.22, 0.12, 0.30), shape * 0.75);
	vec2 mb = floor(uv * vec2(22.0, 14.0));
	float m = h12(mb + seedv + floor(t * 0.5));
	c = mix(c, c.brg, step(0.88 - err * 0.2, m));
	c = floor(c * 6.0) / 6.0;
	float fr = step(min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y)), 0.015);
	vec3 bl = vec3(0.70, 0.70, 0.74) + (h12(floor(UV * vec2(90.0, 60.0)) + vec2(TIME * 13.0, 0.0)) - 0.5) * 0.12;
	c = mix(c, bl, blank);
	c = mix(c, vec3(1.25, 1.2, 1.3), fr);
	ALBEDO = c * 1.1;
}
"""

const MIND := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float glitch = 0.0;
uniform float haze = 0.0;
uniform float flash = 0.0;
uniform float seed = 0.0;

float h12(vec2 p) { vec3 p3 = fract(vec3(p.xyx) * 0.1031); p3 += dot(p3, p3.yzx + 33.33); return fract((p3.x + p3.y) * p3.z); }

void fragment() {
	vec2 uv = SCREEN_UV;
	float t = floor(TIME * 8.0) + seed;
	vec2 blk = floor(uv * vec2(40.0, 22.5));
	float burst = step(h12(vec2(t, 7.0)), 0.18 + glitch * 0.45);
	float on = step(1.0 - glitch * (0.015 + 0.07 * burst), h12(blk * 0.37 + t));
	vec2 big = floor(uv * vec2(3.0, 14.0));
	float rb = h12(big + t * 0.71);
	float smear = step(1.0 - glitch * 0.16 * burst, rb);
	vec2 off = (vec2(h12(blk + t * 1.3), h12(blk + t * 2.1)) - 0.5) * 0.07 * on + vec2((rb - 0.5) * 0.14, 0.0) * smear;
	vec2 q = uv + off;
	q = on > 0.5 ? (floor(q * vec2(160.0, 90.0)) + 0.5) / vec2(160.0, 90.0) : q;
	float ca = glitch * 0.005 + on * 0.008;
	float lod = haze * 2.2;
	vec3 c = vec3(textureLod(screen_tex, q + vec2(ca, 0.0), lod).r, textureLod(screen_tex, q, lod).g,
		textureLod(screen_tex, q - vec2(ca, 0.0), lod).b);
	c = mix(c, floor(c * 5.0) / 5.0 + vec3(0.07, 0.0, 0.09), on * 0.7 + smear * 0.25);
	float vig = smoothstep(0.2, 0.9, length((uv - 0.5) * vec2(1.6, 1.0)));
	c = mix(c, vec3(1.0, 0.93, 0.96), clamp(haze * (0.28 + vig * 0.9), 0.0, 0.95));
	c = mix(c, vec3(1.0, 0.99, 1.0), flash);
	COLOR = vec4(c, 1.0);
}
"""
