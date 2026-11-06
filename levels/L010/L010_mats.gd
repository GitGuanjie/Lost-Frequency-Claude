extends RefCounted
## Level 10 materials. Structure surfaces are MatLib presets; terrain, crop
## canopy, crop stalks, hedges/tree crowns, dirt-track ribbons, soil worms and
## the leaden overcast sky are small level-local shaders compiled from code (no
## textures). Crop colour, rows and the travelling wind gusts are computed in
## world space so near stalks, the canopy and the far LOD ring agree.

const COMMON := """
uniform float gust = 0.0;
uniform vec2 wdir = vec2(0.8, 0.6);
uniform float wet = 0.0;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
vec3 lin(vec3 c) { return pow(max(c, vec3(0.0)), vec3(2.2)); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
float wave(vec2 w) { float ph = dot(w, wdir) * 0.16 - TIME * 1.7 + vn(w * 0.018) * 6.0;
	return smoothstep(0.15, 1.0, 0.5 + 0.5 * sin(ph)) * (0.18 + gust); }
vec3 grass_col(vec2 w) { float a = vn(w * 0.07); float b = vn(w * 0.9); float c = vn(w * 6.0);
	vec3 g = mix(vec3(0.15, 0.2, 0.08), vec3(0.27, 0.3, 0.13), a);
	g = mix(g, vec3(0.36, 0.33, 0.2), smoothstep(0.5, 0.9, b) * 0.65);
	float d = vn(w * 23.0) * 0.6 + vn(w * 57.0) * 0.4;
	return g * (0.72 + 0.3 * c) * (0.75 + 0.45 * d); }
vec3 crop_col(float kind, vec2 w, float aa) {
	vec3 base = kind < 0.25 ? vec3(0.62, 0.48, 0.25) : (kind < 0.75 ? vec3(0.62, 0.57, 0.36) : vec3(0.78, 0.66, 0.06));
	float ears = mix(0.5, vn(w * 24.0) * 0.65 + vn(w * 61.0) * 0.35, aa); float clump = vn(w * 3.5); float patch = vn(w * 0.1);
	vec3 c = base * (0.78 + 0.34 * patch) * (0.5 + 0.8 * ears) * (0.85 + 0.28 * clump);
	if (kind > 0.75) { c = mix(vec3(0.24, 0.32, 0.10), c, smoothstep(0.25, 0.55, ears * 0.7 + clump * 0.5)); }
	float wv = wave(w); return mix(c, c * 1.3 + vec3(0.03, 0.025, 0.01), wv * 0.7); }
"""

const TERRAIN := """
shader_type spatial;
render_mode diffuse_burley;
%s
uniform float water_y = -2.6;
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec3 c = grass_col(wp.xz);
	float n = vn(wp.xz * 0.3);
	float shore = 1.0 - smoothstep(water_y + 0.2, water_y + 1.6 + n * 1.2, wp.y);
	vec3 mud = mix(vec3(0.14, 0.12, 0.08), vec3(0.25, 0.21, 0.15), vn(wp.xz * 2.0)) * (0.8 + 0.3 * vn(wp.xz * 13.0));
	c = mix(c, mud, shore * smoothstep(0.35, 0.75, vn(wp.xz * 0.35) * 0.7 + vn(wp.xz * 1.7) * 0.3 + shore * 0.45));
	vec3 soil = mix(vec3(0.17, 0.13, 0.09), vec3(0.27, 0.21, 0.14), vn(wp.xz * 3.0)) * (0.8 + 0.35 * vn(wp.xz * 11.0));
	c = mix(c, soil, COLOR.r);
	float aa = clamp(1.4 - length(fwidth(wp.xz)) * 20.0, 0.0, 1.0);
	c = mix(c, crop_col(COLOR.b, wp.xz, aa), COLOR.g);
	float under = 1.0 - smoothstep(water_y - 0.8, water_y - 0.05, wp.y);
	c = mix(c, vec3(0.13, 0.13, 0.09), under * 0.75);
	ALBEDO = lin(c * (1.0 - wet * 0.22));
	ROUGHNESS = mix(0.96, 0.55, max(shore * 0.5, wet * 0.35));
}
"""

const CANOPY := """
shader_type spatial;
render_mode diffuse_burley, cull_disabled;
%s
varying vec3 wp;
varying vec3 wn;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; wn = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz; }
void fragment() {
	float aa = clamp(1.4 - length(fwidth(wp.xz)) * 20.0, 0.0, 1.0);
	vec3 c = crop_col(COLOR.b, wp.xz, aa);
	if (abs(wn.y) < 0.5) {
		float e = abs(wn.x) > 0.5 ? wp.z : wp.x;
		float ym = UV.y;
		float chh = UV.x;
		float lay = COLOR.g * 2.0;
		float s = e * 34.0 + lay * 0.37;
		float f = fract(s);
		float r1 = hsh(vec2(floor(s), lay * 7.0 + 1.0));
		float ht = chh + 0.02 + r1 * 0.26;
		float fw = fwidth(s);
		if (ym > ht) { discard; }
		float ear = smoothstep(ht - 0.13, ht - 0.1, ym);
		float wid = mix(0.13, 0.33, ear) + fw * 0.5;
		if (lay < 1.5 && abs(f - 0.5) > wid && fw < 0.6) { discard; }
		vec3 stem = mix(vec3(0.07, 0.06, 0.035), c * 0.75, smoothstep(-0.05, chh, ym));
		c = mix(stem, c * (0.8 + 0.4 * r1), ear);
		if (lay > 1.5) { c *= mix(0.4, 1.0, smoothstep(chh - 0.35, chh, ym)); }
	} else {
		float rows = COLOR.r > 0.5 ? wp.x : wp.z;
		float tram = smoothstep(0.35, 0.0, abs(mod(rows, 20.0) - 10.0) - 0.9);
		c *= 1.0 - tram * 0.3;
	}
	ALBEDO = lin(c * (1.0 - wet * 0.15));
	ROUGHNESS = 0.9;
	BACKLIGHT = ALBEDO * 0.25;
}
"""

const STALK := """
shader_type spatial;
render_mode diffuse_burley, cull_disabled;
%s
varying float vh;
void vertex() {
	vec3 o = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float b = VERTEX.y * VERTEX.y;
	float wv = wave(o.xz);
	vec3 off = vec3(wdir.x, 0.0, wdir.y) * b * (0.05 + 0.32 * wv) + vec3(sin(TIME * 5.3 + o.x * 3.1), 0.0, cos(TIME * 4.7 + o.z * 2.7)) * b * 0.012;
	off.y = -b * 0.12 * wv;
	VERTEX += (transpose(mat3(MODEL_MATRIX)) * off) / dot(MODEL_MATRIX[0].xyz, MODEL_MATRIX[0].xyz);
	vh = VERTEX.y;
	NORMAL = normalize(mix(NORMAL, vec3(0.0, 1.0, 0.0), 0.6));
}
void fragment() {
	vec3 c = COLOR.rgb * mix(mix(0.4, 1.0, smoothstep(0.05, 0.75, vh)), 1.0, 1.0 - COLOR.a);
	ALBEDO = lin(c * (1.0 - wet * 0.15));
	ROUGHNESS = 0.85;
	BACKLIGHT = ALBEDO * 0.35;
}
"""

const FOLIAGE := """
shader_type spatial;
render_mode diffuse_burley;
%s
uniform vec3 col_a : source_color = vec3(0.10, 0.16, 0.06);
uniform vec3 col_b : source_color = vec3(0.20, 0.26, 0.10);
uniform float sway = 0.0;
varying vec3 wp;
varying vec3 wn;
void vertex() {
	vec3 o = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 off = vec3(wdir.x, 0.0, wdir.y) * sway * (0.3 + 1.2 * wave(o.xz)) * (0.6 + 0.4 * sin(TIME * 1.3 + o.x));
	VERTEX += (transpose(mat3(MODEL_MATRIX)) * off) / dot(MODEL_MATRIX[0].xyz, MODEL_MATRIX[0].xyz);
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	float l = (vn(wp.xz * 6.0) + vn(wp.xy * 6.0 + 3.1) + vn(wp.zy * 6.0 + 7.7)) * 0.333;
	l = l * 0.6 + 0.4 * (vn(wp.xz * 17.0) + vn(wp.xy * 17.0) + vn(wp.zy * 17.0)) * 0.333;
	float big = (vn(wp.xz * 0.7) + vn(wp.xy * 0.7) + vn(wp.zy * 0.7)) * 0.333;
	vec3 c = mix(col_a, col_b, smoothstep(0.3, 0.7, big)) * (0.25 + 1.15 * smoothstep(0.2, 0.8, l));
	c *= mix(0.55, 1.05, clamp(wn.y * 0.5 + 0.5, 0.0, 1.0));
	ALBEDO = c * 0.8;
	ROUGHNESS = 0.95;
	BACKLIGHT = c * 0.25;
}
"""

const TRACK := """
shader_type spatial;
render_mode diffuse_burley;
%s
varying vec3 wp;
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += 0.02 + length(wp - CAMERA_POSITION_WORLD) * 0.0012;
}
void fragment() {
	float x = abs(UV.x);
	vec3 g = grass_col(wp.xz);
	vec3 dirt = mix(vec3(0.31, 0.25, 0.18), vec3(0.40, 0.33, 0.24), vn(wp.xz * 1.3)) * (0.82 + 0.32 * vn(wp.xz * 9.0));
	float rut = 1.0 - smoothstep(0.16, 0.3, abs(x - 0.82 + (vn(vec2(UV.y * 0.3, UV.x)) - 0.5) * 0.1));
	float mid = 1.0 - smoothstep(0.2, 0.42, x + (vn(wp.xz * 2.0) - 0.5) * 0.3);
	float edge = smoothstep(1.25, 2.05, x + (vn(wp.xz * 1.5) - 0.5) * 0.6);
	vec3 c = mix(dirt, dirt * 0.66, rut);
	c = mix(c, g, max(mid * 0.85, edge));
	float pud = rut * smoothstep(0.6, 0.72, vn(vec2(UV.y * 0.22, x * 0.5))) * (0.35 + wet * 0.65);
	ALBEDO = lin(mix(c, c * 0.45, pud));
	ROUGHNESS = mix(0.95, 0.12, pud);
	METALLIC = pud * 0.1;
}
"""

const WORM := """
shader_type spatial;
render_mode diffuse_burley;
void vertex() {
	float t = TIME * 6.0 + float(INSTANCE_ID) * 1.7;
	VERTEX.x += sin(VERTEX.z * 20.0 + t) * 0.035;
	VERTEX.y += cos(VERTEX.z * 15.0 + t * 1.3) * 0.012;
}
void fragment() {
	ALBEDO = pow(vec3(0.5, 0.31, 0.29) * (0.8 + 0.25 * sin(UV.y * 90.0)), vec3(2.2));
	ROUGHNESS = 0.22;
	SPECULAR = 0.7;
}
"""

const SKY := """
shader_type sky;
uniform vec3 top : source_color = vec3(0.42, 0.44, 0.47);
uniform vec3 hor : source_color = vec3(0.64, 0.65, 0.66);
uniform float dark = 0.0;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
vec3 lin(vec3 c) { return pow(max(c, vec3(0.0)), vec3(2.2)); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
float fbm(vec2 p) { float s = 0.0; float a = 0.5; for (int i = 0; i < 5; i++) { s += a * vn(p); p = p * 2.07 + vec2(1.7, 9.2); a *= 0.5; } return s; }
void sky() {
	vec3 d = EYEDIR;
	float y = max(d.y, 0.0);
	vec2 uv = d.xz / (d.y + 0.12);
	float c = fbm(uv * 0.9 + vec2(3.1, 7.7));
	float c2 = fbm(uv * 2.6 + vec2(c * 2.0, 1.3));
	vec3 col = mix(hor, top, smoothstep(0.0, 0.6, y));
	col *= 0.66 + 0.42 * c + 0.16 * c2 - 0.12 * smoothstep(0.55, 0.8, c);
	col = mix(hor, col, smoothstep(0.0, 0.2, y));
	COLOR = col * (1.0 - dark * 0.18);
}
"""

static var shaded: Array = []


static func _sh(code: String) -> Shader:
	var s := Shader.new()
	s.code = code % COMMON if code.contains("%s") else code
	return s


static func _reg(name: String, code: String, params: Dictionary = {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _sh(code)
	for k in params:
		var v: Variant = params[k]
		m.set_shader_parameter(k, Vector3(v.r, v.g, v.b) if v is Color else v)
	MatLib.register(name, m)
	if code.contains("%s"):
		shaded.append(m)
	return m


static func define_all(water_y: float) -> void:
	shaded.clear()
	_reg("l10_terrain", TERRAIN, {"water_y": water_y})
	_reg("l10_canopy", CANOPY)
	_reg("l10_stalk", STALK)
	_reg("l10_hedge", FOLIAGE, {"col_a": Color(0.1, 0.15, 0.06), "col_b": Color(0.2, 0.25, 0.1)})
	_reg("l10_crown", FOLIAGE, {"col_a": Color(0.09, 0.13, 0.06), "col_b": Color(0.19, 0.23, 0.11), "sway": 0.06})
	_reg("l10_track", TRACK)
	_reg("l10_worm", WORM)
	MatLib.define("l10_board", {"albedo_a": Color(0.35, 0.3, 0.25), "albedo_b": Color(0.27, 0.23, 0.19), "pattern_scale": Vector2(3.4, 0.23),
		"uv_rotate": PI * 0.5, "grout_width": 0.012, "grout_color": Color(0.06, 0.05, 0.04), "stain_amount": 0.35, "stain_color": Color(0.2, 0.22, 0.17), "roughness_a": 0.9, "roughness_b": 1.0}, "wood_floor")
	MatLib.define("l10_board_red", {"albedo_a": Color(0.4, 0.16, 0.11), "albedo_b": Color(0.31, 0.13, 0.1), "pattern_scale": Vector2(3.4, 0.23),
		"uv_rotate": PI * 0.5, "grout_width": 0.012, "grout_color": Color(0.07, 0.04, 0.03), "stain_amount": 0.4, "stain_color": Color(0.3, 0.25, 0.2), "roughness_a": 0.9, "roughness_b": 1.0}, "wood_floor")
	MatLib.define("l10_board_in", {"albedo_a": Color(0.16, 0.13, 0.1), "albedo_b": Color(0.12, 0.1, 0.08), "pattern_scale": Vector2(3.4, 0.23),
		"uv_rotate": PI * 0.5, "grout_width": 0.02, "grout_color": Color(0.02, 0.02, 0.015), "stain_amount": 0.3, "stain_color": Color(0.08, 0.08, 0.06), "roughness_a": 0.9, "roughness_b": 1.0}, "wood_floor")
	MatLib.define("l10_tin", {"albedo_a": Color(0.38, 0.38, 0.37), "albedo_b": Color(0.33, 0.27, 0.22), "pattern": 2, "pattern_scale": Vector2(0.075, 0.075),
		"pattern_color": Color(0.22, 0.22, 0.22), "pattern_strength": 0.35, "noise_scale": 0.6, "stain_amount": 0.45, "stain_color": Color(0.36, 0.2, 0.1), "metallic_value": 0.12, "roughness_a": 0.75, "roughness_b": 0.95}, "metal")
	MatLib.define("l10_rafter_wood", {"albedo_a": Color(0.1, 0.075, 0.055), "albedo_b": Color(0.075, 0.055, 0.04), "pattern_scale": Vector2(3.0, 0.2), "grout_color": Color(0.03, 0.02, 0.02)}, "wood_floor")
	MatLib.define("l10_stone", {"albedo_a": Color(0.24, 0.23, 0.21), "albedo_b": Color(0.18, 0.17, 0.16), "pattern_scale": Vector2(0.55, 0.28), "grout_color": Color(0.3, 0.29, 0.26), "grout_width": 0.02}, "brick")
	MatLib.define("l10_floor_dirt", {"albedo_a": Color(0.13, 0.11, 0.085), "albedo_b": Color(0.1, 0.085, 0.065), "noise_scale": 1.6, "stain_amount": 0.4, "stain_color": Color(0.3, 0.26, 0.18)}, "dirt")
	MatLib.define("l10_loft_wood", {"albedo_a": Color(0.15, 0.115, 0.085), "albedo_b": Color(0.12, 0.09, 0.065), "pattern_scale": Vector2(2.4, 0.2)}, "wood_floor")
	MatLib.define("l10_beam_wood", {"albedo_a": Color(0.14, 0.105, 0.075), "albedo_b": Color(0.11, 0.08, 0.06), "pattern": 0, "noise_scale": 4.0}, "wood_floor")
	MatLib.define("l10_plank_wood", {"albedo_a": Color(0.46, 0.36, 0.24), "albedo_b": Color(0.4, 0.31, 0.2), "pattern_scale": Vector2(2.0, 0.15)}, "wood_floor")
	MatLib.define("l10_step_wood", {"albedo_a": Color(0.66, 0.55, 0.4), "albedo_b": Color(0.6, 0.49, 0.35), "pattern_scale": Vector2(1.0, 0.16), "stain_amount": 0.0}, "wood_floor")
	MatLib.define("l10_nails_metal", {"albedo_a": Color(0.32, 0.32, 0.33), "albedo_b": Color(0.24, 0.23, 0.22), "noise_scale": 40.0, "bump_strength": 2.0}, "metal")
	MatLib.define("l10_soil_dirt", {"albedo_a": Color(0.15, 0.11, 0.08), "albedo_b": Color(0.11, 0.08, 0.06), "noise_scale": 2.5, "wetness": 0.4}, "dirt")
	MatLib.define("l10_stake_wood", {"albedo_a": Color(0.55, 0.45, 0.3), "albedo_b": Color(0.5, 0.4, 0.27), "pattern": 0}, "wood_floor")
	MatLib.register("l10_tape", MatLib.standard(Color(0.85, 0.35, 0.08), 0.6))
	MatLib.register("l10_pot", MatLib.standard(Color(0.04, 0.035, 0.03), 0.7, 0.4))
	MatLib.register("l10_cloth", MatLib.standard(Color(0.4, 0.38, 0.3), 0.95))
	MatLib.register("l10_bark", MatLib.standard(Color(0.2, 0.17, 0.13), 0.95))
	MatLib.define("l10_asphalt", {"wetness": 0.1, "albedo_a": Color(0.2, 0.2, 0.2), "albedo_b": Color(0.15, 0.15, 0.15)}, "asphalt")
	MatLib.register("l10_city", MatLib.standard(Color(0.42, 0.44, 0.47), 1.0))


static func sky_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _sh(SKY)
	return m


static func set_weather(g: float, wd: Vector2, w: float) -> void:
	for m in shaded:
		(m as ShaderMaterial).set_shader_parameter("gust", g)
		(m as ShaderMaterial).set_shader_parameter("wdir", wd)
		(m as ShaderMaterial).set_shader_parameter("wet", w)
