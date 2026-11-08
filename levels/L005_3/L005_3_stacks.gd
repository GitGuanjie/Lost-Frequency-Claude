extends RefCounted
## Level 5.3 stacks: one 24 m chunk of the library, all seven floors. A 4 m
## corridor band runs along the chunk's west and south edges (so corridors
## form an endless grid); the 20 m block between them is either a block of
## bookcases (walls of shelves facing the corridors, ranges inside, sometimes
## a dead-end corridor with a small wooden door) or the void, an open shaft
## through every floor fenced with iron bars and climbed by wooden stairs.
## Hotel language (Level 5): walnut, gilt, red-and-gold carpet, checkered
## marble; page: marble walls with granite, tuff pillars, iron bars, paintings
## above the shelves, "Promethei Bibliotheca" at the top of some walls.

const CS := 24.0
const COR := 4.0
const FH := 5.0
const SLAB := 0.35
const NF := 7
const ENTRY_F := 4
const SHELF_H := 3.4
const CEIL := FH - SLAB

static func floor_y(f: int) -> float:
	return float(f - ENTRY_F) * FH


static func floor_of(y: float) -> int:
	return clampi(int(floor((y + 1.2) / FH)) + ENTRY_F, 1, NF)


# ------------------------------------------------------------ materials

static func materials() -> void:
	var gold := Color(0.56, 0.4, 0.17)
	MatLib.define("l53_marble", {"albedo_a": Color(0.86, 0.84, 0.8), "albedo_b": Color(0.76, 0.74, 0.7), "pattern": 9, "pattern_scale": Vector2(0.7, 0.7),
		"pattern_color": Color(0.06, 0.055, 0.05), "pattern_strength": 0.55, "grout_color": Color(0.4, 0.38, 0.35), "grout_width": 0.004,
		"roughness_a": 0.08, "roughness_b": 0.2, "noise_scale": 2.4, "tile_variation": 0.03, "bump_strength": 0.25, "stain_amount": 0.2, "stain_color": Color(0.55, 0.5, 0.42)})
	MatLib.define("l53_marble_wall", {"albedo_a": Color(0.84, 0.82, 0.78), "albedo_b": Color(0.74, 0.72, 0.68), "noise_scale": 3.2, "roughness_a": 0.12,
		"roughness_b": 0.25, "stain_amount": 0.35, "stain_color": Color(0.5, 0.48, 0.45), "stain_scale": 1.4}, "plaster")
	MatLib.define("l53_granite", {"albedo_a": Color(0.16, 0.15, 0.15), "albedo_b": Color(0.09, 0.09, 0.09), "pattern": 15, "pattern_color": Color(0.45, 0.42, 0.4),
		"pattern_strength": 0.5, "pattern_scale": Vector2(0.05, 0.05), "roughness_a": 0.2, "roughness_b": 0.35, "noise_scale": 3.0}, "plaster")
	MatLib.define("l53_walnut_end", {"albedo_a": Color(0.16, 0.08, 0.04), "albedo_b": Color(0.12, 0.06, 0.03), "noise_scale": 3.0, "roughness_a": 0.3, "roughness_b": 0.45, "bump_strength": 0.4}, "plaster")
	MatLib.define("l53_tuff", {"albedo_a": Color(0.34, 0.31, 0.24), "albedo_b": Color(0.25, 0.23, 0.17), "pattern": 15, "pattern_color": Color(0.25, 0.21, 0.15),
		"pattern_strength": 0.45, "pattern_scale": Vector2(0.08, 0.08), "roughness_a": 0.9, "roughness_b": 1.0, "bump_strength": 1.6, "noise_scale": 1.2,
		"stain_amount": 0.3, "stain_color": Color(0.32, 0.27, 0.18)}, "rock")
	MatLib.define("l53_walnut", {"albedo_a": Color(0.2, 0.1, 0.05), "albedo_b": Color(0.15, 0.075, 0.038), "pattern": 3, "pattern_scale": Vector2(1.6, 0.13),
		"grout_color": Color(0.06, 0.03, 0.015), "grout_width": 0.003, "roughness_a": 0.22, "roughness_b": 0.38, "bump_strength": 0.5})
	MatLib.define("l53_parquet", {"albedo_a": Color(0.36, 0.2, 0.09), "albedo_b": Color(0.3, 0.16, 0.07), "pattern": 9, "pattern_scale": Vector2(0.6, 0.6),
		"pattern_color": Color(0.18, 0.09, 0.04), "pattern_strength": 0.42, "grout_color": Color(0.1, 0.05, 0.025), "grout_width": 0.004,
		"roughness_a": 0.25, "roughness_b": 0.4, "stain_amount": 0.25, "stain_color": Color(0.42, 0.36, 0.28)})
	MatLib.define("l53_carpet", {"albedo_a": Color(0.36, 0.045, 0.04), "albedo_b": Color(0.28, 0.03, 0.028), "pattern": 6, "pattern_scale": Vector2(0.62, 0.62),
		"pattern_color": Color(0.6, 0.42, 0.15), "pattern_strength": 0.5, "noise_scale": 0.5, "bump_strength": 0.6, "stain_amount": 0.3, "stain_color": Color(0.4, 0.33, 0.24)})
	MatLib.define("l53_ceiling", {"albedo_a": Color(0.16, 0.085, 0.045), "albedo_b": Color(0.12, 0.065, 0.035), "pattern": 1, "pattern_scale": Vector2(1.2, 1.2),
		"grout_color": Color(0.42, 0.3, 0.12), "grout_width": 0.03, "roughness_a": 0.4, "roughness_b": 0.6, "tile_variation": 0.04})
	MatLib.define("l53_gold", {"albedo_a": Color(0.7, 0.52, 0.22), "albedo_b": Color(0.56, 0.4, 0.16), "metallic_value": 0.85, "roughness_a": 0.3, "roughness_b": 0.5, "noise_scale": 3.0})
	MatLib.define("l53_iron", {"albedo_a": Color(0.12, 0.11, 0.1), "albedo_b": Color(0.2, 0.12, 0.07), "metallic_value": 0.7, "roughness_a": 0.45, "roughness_b": 0.75,
		"noise_scale": 3.0, "stain_amount": 0.4, "stain_color": Color(0.3, 0.15, 0.07)}, "metal")
	MatLib.define("l53_door_old", {"albedo_a": Color(0.2, 0.12, 0.07), "albedo_b": Color(0.15, 0.09, 0.05), "pattern": 3, "uv_rotate": 1.5708, "pattern_scale": Vector2(2.4, 0.16),
		"grout_color": Color(0.06, 0.035, 0.02), "grout_width": 0.004, "roughness_a": 0.6, "roughness_b": 0.8, "stain_amount": 0.45, "stain_color": Color(0.1, 0.07, 0.05)})
	MatLib.define("l53_wallpaper_old", {"albedo_a": Color(0.3, 0.06, 0.045), "albedo_b": Color(0.22, 0.045, 0.035), "pattern": 10, "pattern_scale": Vector2(0.21, 0.29),
		"pattern_color": gold * 0.8, "pattern_strength": 0.35, "peel_amount": 0.55, "peel_color": Color(0.42, 0.36, 0.26), "stain_amount": 0.5, "stain_color": Color(0.2, 0.12, 0.06)})
	MatLib.define("l53_shade", {"albedo_a": Color(0.08, 0.3, 0.12), "albedo_b": Color(0.06, 0.26, 0.1), "emission_color": Color(0.5, 0.9, 0.5), "emission_energy": 0.5, "roughness_a": 0.2}, "plaster")
	MatLib.define("l53_flame", {"albedo_a": Color(1.0, 0.86, 0.6), "albedo_b": Color(1.0, 0.8, 0.5), "emission_color": Color(1.0, 0.66, 0.32), "emission_energy": 6.0}, "plaster")
	MatLib.define("l53_candle", {"albedo_a": Color(0.92, 0.88, 0.78), "albedo_b": Color(0.88, 0.84, 0.72), "emission_color": Color(1.0, 0.8, 0.6), "emission_energy": 0.15}, "plaster")
	MatLib.define("l53_paper", {"albedo_a": Color(0.8, 0.76, 0.66), "albedo_b": Color(0.7, 0.66, 0.56), "noise_scale": 6.0, "roughness_a": 0.9}, "plaster")
	_shader("l53_books", BOOKS)
	_shader("l53_painting", PAINTING)
	_shader("l53_bars", BARS)
	_shader("l53_dust", DUST)


static func _shader(n: String, code: String) -> void:
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	MatLib.register(n, m)


## Book spines on a shelf face. UV is metre-space (x along the shelf, y = -height).
const BOOKS := """
shader_type spatial;
render_mode diffuse_burley;
uniform float pitch = 0.37;
varying vec3 wp;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
vec3 pal(float h) {
	if (h < 0.16) return vec3(0.17, 0.028, 0.022);
	if (h < 0.28) return vec3(0.028, 0.07, 0.035);
	if (h < 0.38) return vec3(0.025, 0.035, 0.09);
	if (h < 0.52) return vec3(0.13, 0.065, 0.028);
	if (h < 0.6) return vec3(0.32, 0.22, 0.11);
	if (h < 0.68) return vec3(0.02, 0.018, 0.016);
	if (h < 0.78) return vec3(0.2, 0.035, 0.06);
	if (h < 0.86) return vec3(0.28, 0.16, 0.045);
	if (h < 0.94) return vec3(0.1, 0.12, 0.14);
	return vec3(0.42, 0.36, 0.25);
}
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float y = -UV.y + 40.0;
	float row = floor(y / pitch);
	float fy = fract(y / pitch) * pitch;
	float bw = 0.034 + 0.018 * hsh(vec2(row, 3.1));
	float xs = UV.x + row * 0.371;
	float cell = floor(xs / bw);
	float fx = fract(xs / bw);
	float h1 = hsh(vec2(cell, row));
	float h2 = hsh(vec2(cell + 7.1, row * 1.3));
	float bh = pitch * (0.6 + 0.3 * h2) - 0.03;
	float board = 1.0 - step(0.03, fy);
	float gap = step(h1, 0.05);
	float book = (1.0 - board) * (1.0 - gap) * step(fy - 0.03, bh);
	vec3 col = pal(hsh(vec2(cell * 1.7, row + 9.0)));
	col *= 0.75 + 0.5 * hsh(vec2(cell, row + 2.0));
	// gilt bands and a title patch on some spines
	float rel = (fy - 0.03) / bh;
	float gilt = step(0.55, h2) * (step(abs(rel - 0.85), 0.025) + step(abs(rel - 0.15), 0.02));
	float label = step(0.75, h1) * step(abs(rel - 0.6), 0.09) * step(abs(fx - 0.5), 0.3);
	col = mix(col, vec3(0.62, 0.46, 0.18), clamp(gilt, 0.0, 1.0));
	col = mix(col, col * 1.6 + vec3(0.03), label * 0.5);
	// dust greys the tops of the books and the shelf lip
	float dust = smoothstep(bh - 0.05, bh, fy - 0.03) * 0.4 + board * 0.25;
	col = mix(col, vec3(0.32, 0.29, 0.25), dust);
	vec3 shelf_back = vec3(0.012, 0.007, 0.004);
	vec3 board_c = vec3(0.16, 0.08, 0.04);
	vec3 c = mix(shelf_back, col, book);
	c = mix(c, board_c, board);
	float edge = smoothstep(0.0, 0.18, fx) * smoothstep(1.0, 0.82, fx);
	c *= mix(1.0, 0.55 + 0.45 * edge, book);
	ALBEDO = c;
	ROUGHNESS = mix(0.9, 0.55 - 0.3 * gilt, book);
	METALLIC = gilt * book * 0.7;
	NORMAL_MAP = mix(vec3(0.5, 0.5, 1.0), vec3(0.5 + (fx - 0.5) * 0.9 * book, 0.5, 1.0), book);
}
"""

## Renaissance-style oil painting on a canvas quad (local UV 0..1, UV2.x seed).
const PAINTING := """
shader_type spatial;
render_mode diffuse_burley;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
float fbm(vec2 p) { float s = 0.0; float a = 0.5; for (int i = 0; i < 4; i++) { s += a * vn(p); p *= 2.1; a *= 0.5; } return s; }
void fragment() {
	vec2 uv = UV;
	float sd = UV2.x * 17.0;
	float y = 1.0 - uv.y;
	// sky: ultramarine to a warm horizon, painterly clouds
	float hor = 0.42 + 0.12 * hsh(vec2(sd, 1.0)) + 0.06 * sin(uv.x * 5.0 + sd);
	vec3 sky = mix(vec3(0.5, 0.36, 0.18), vec3(0.06, 0.12, 0.26), smoothstep(hor, 1.0, y));
	sky = mix(sky, vec3(0.62, 0.52, 0.36), smoothstep(0.55, 0.8, fbm(uv * vec2(4.0, 6.0) + sd)) * 0.6 * step(hor, y));
	// dark ground and architecture
	vec3 ground = mix(vec3(0.05, 0.035, 0.02), vec3(0.12, 0.08, 0.04), fbm(uv * 3.0 + sd));
	float land = step(y, hor - 0.05 * fbm(uv * vec2(6.0, 2.0) + sd));
	vec3 c = mix(sky, ground, land);
	float col_x = fract(uv.x * 2.0 + hsh(vec2(sd, 4.0)));
	c = mix(c, vec3(0.32, 0.27, 0.2), step(0.9, col_x) * step(y, 0.85) * step(0.25, y) * step(0.5, hsh(vec2(sd, 5.0))));
	// figures: draped bodies in crimson, blue, ochre, with pale faces
	for (int i = 0; i < 5; i++) {
		float fi = float(i);
		vec2 c0 = vec2(0.14 + 0.18 * fi + 0.06 * (hsh(vec2(sd, fi)) - 0.5), 0.12 + 0.18 * hsh(vec2(fi, sd)));
		float hgt = 0.34 + 0.2 * hsh(vec2(fi + 3.0, sd));
		vec2 d = (vec2(uv.x, y) - c0) / vec2(0.06, hgt);
		float body = step(length(vec2(d.x * (1.0 + d.y * 0.4), d.y - 0.5) * vec2(1.0, 1.9)), 1.0) * step(0.0, d.y);
		float face = step(length((vec2(uv.x, y) - (c0 + vec2(0.0, hgt * 1.02))) / vec2(0.026, 0.035)), 1.0);
		float hc = hsh(vec2(fi * 2.0, sd + 1.0));
		vec3 drape = hc < 0.35 ? vec3(0.32, 0.03, 0.025) : (hc < 0.6 ? vec3(0.04, 0.07, 0.22) : (hc < 0.8 ? vec3(0.42, 0.28, 0.07) : vec3(0.3, 0.3, 0.26)));
		drape *= 0.7 + 0.5 * fbm(uv * 30.0 + fi);
		c = mix(c, drape, body * step(0.25, hsh(vec2(fi, sd * 3.0))));
		c = mix(c, vec3(0.62, 0.42, 0.3), face * step(0.25, hsh(vec2(fi, sd * 3.0))));
	}
	// aged varnish, darkened edges, craquelure
	c = mix(c, c * vec3(1.0, 0.85, 0.55), 0.55);
	float vig = smoothstep(0.0, 0.25, uv.x) * smoothstep(1.0, 0.75, uv.x) * smoothstep(0.0, 0.25, uv.y) * smoothstep(1.0, 0.75, uv.y);
	c *= 0.45 + 0.55 * vig;
	vec2 g = uv * vec2(60.0, 40.0);
	float cr = smoothstep(0.03, 0.0, abs(fract(g.x + vn(g * 0.3) * 1.5) - 0.5) - 0.47) + smoothstep(0.03, 0.0, abs(fract(g.y + vn(g * 0.3 + 4.0) * 1.5) - 0.5) - 0.47);
	c *= 1.0 - 0.25 * clamp(cr, 0.0, 1.0);
	ALBEDO = c;
	ROUGHNESS = 0.35;
	SPECULAR = 0.4;
}
"""

## Wrought iron bars (alpha scissor), UV metre-space, both faces drawn.
const BARS := """
shader_type spatial;
render_mode diffuse_burley, cull_disabled;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
void fragment() {
	float u = fract(UV.x / 0.14);
	float bar = step(abs(u - 0.5), 0.12);
	float y = -UV.y;
	float rail = step(abs(fract(y / 1.1 + 0.5) - 0.5), 0.02);
	if (bar + rail < 0.5) { discard; }
	vec3 c = mix(vec3(0.05, 0.045, 0.04), vec3(0.17, 0.08, 0.04), hsh(floor(UV * vec2(7.0, 3.0))));
	ALBEDO = c;
	METALLIC = 0.6;
	ROUGHNESS = 0.6;
	NORMAL_MAP = vec3(0.5 + (u - 0.5) * 2.0 * bar, 0.5, 1.0);
}
"""

## Floating dust, lit only where light falls (additive motes).
const DUST := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
void fragment() {
	vec2 g = UV * vec2(18.0, 30.0) + vec2(0.0, TIME * 0.05);
	vec2 c = floor(g);
	vec2 f = fract(g) - 0.5 - (vec2(hsh(c), hsh(c + 3.0)) - 0.5) * 0.6;
	float m = step(hsh(c + 9.0), 0.08) * smoothstep(0.08, 0.0, length(f));
	float fade = smoothstep(0.0, 0.3, UV.y) * smoothstep(1.0, 0.7, UV.y) * smoothstep(0.0, 0.2, UV.x) * smoothstep(1.0, 0.8, UV.x);
	ALBEDO = vec3(1.0, 0.85, 0.6) * m * fade * 0.6;
}
"""


# ------------------------------------------------------------ chunk content

## Kinds: "void" (open shaft) or "stacks". A few chunks are fixed.
static func kind_of(cx: int, cz: int, sd: int) -> String:
	if cx == 0 and cz == -1:
		return "void"
	if (cx == 0 and cz == 0) or (cx == -1 and cz == 0) or (cx == 0 and cz == 1):
		return "stacks"
	return "void" if absf(fmod(float(hash([cx, cz, sd, 53])) / 9973.0, 1.0)) < 0.2 else "stacks"


## Dead-end corridor in this chunk's block on this floor (page: "a chance").
static func dead_end(cx: int, cz: int, f: int, sd: int, forced: Vector2i) -> bool:
	if cx == 0 and cz == 0:
		return false
	if Vector2i(cx, cz) == forced and f == ENTRY_F:
		return true
	return absf(fmod(float(hash([cx, cz, f, sd, 99])) / 7919.0, 1.0)) < 0.1


static func rnd(cx: int, cz: int, f: int, sd: int, salt: int) -> float:
	return absf(fmod(float(hash([cx, cz, f, sd, salt])) / 6007.0, 1.0))
