extends RefCounted
## Level 11 materials. Surface presets come from MatLib; three small level-local
## shaders are compiled from code (no files, no textures): a facade shader that
## draws window grids in metre UVs (lit, dark or black-mirror glass, averaged
## to a glow at distance), cycling traffic-signal lamps, and an arcade
## attract-mode screen. Used by levels/L011/L011.gd and L011_city.gd.

const FACADE := """
shader_type spatial;
render_mode blend_mix, cull_back, diffuse_burley, specular_schlick_ggx;
uniform vec3 wall_a : source_color = vec3(0.4);
uniform vec3 wall_b : source_color = vec3(0.35);
uniform vec2 cell = vec2(3.0, 3.6);
uniform vec2 win = vec2(0.6, 0.55);
uniform float lit = 0.35;
uniform vec3 lit_a : source_color = vec3(1.0, 0.8, 0.52);
uniform vec3 lit_b : source_color = vec3(0.72, 0.84, 1.0);
uniform float energy = 2.0;
uniform float mirror = 0.0;
uniform float min_y = 4.5;
uniform vec3 roof : source_color = vec3(0.1);
varying vec3 wp;
varying vec3 wn;
float h(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	if (abs(wn.y) > 0.5) {
		ALBEDO = roof;
		ROUGHNESS = 0.9;
	} else {
		vec2 g = vec2(UV.x / cell.x, -UV.y / cell.y);
		vec2 id = floor(g);
		vec2 f = fract(g);
		float above = step(min_y, wp.y);
		float m = step(abs(f.x - 0.5), win.x * 0.5) * step(abs(f.y - 0.45), win.y * 0.5) * above;
		float fw = max(fwidth(g.x), fwidth(g.y));
		float aa = clamp(1.6 - fw * 2.4, 0.0, 1.0);
		vec2 bid = floor(wp.xz / 37.0) * 13.7 + wn.xz * 5.3;
		float on = step(h(id * vec2(1.37, 2.11) + bid), lit) * (1.0 - mirror);
		float mm = mix(win.x * win.y * above, m, aa);
		vec3 wall = mix(wall_a, wall_b, h(floor(wp.xz * 0.21) + vec2(id.y * 0.0)));
		vec3 glass = mix(vec3(0.03, 0.035, 0.045), vec3(0.004, 0.005, 0.007), mirror);
		ALBEDO = mix(wall, glass, mm);
		ROUGHNESS = mix(0.85, mix(0.2, 0.04, mirror), mm);
		METALLIC = mix(0.0, mix(0.3, 0.9, mirror), mm);
		vec3 lc = mix(lit_a, lit_b, h(id * 3.3 + bid + 1.7)) * (0.5 + 0.5 * h(id * 7.1 + bid));
		EMISSION = lc * energy * mix(win.x * win.y * lit * (1.0 - mirror) * above * 0.6, m * on, aa);
	}
}
"""

const SIGNAL := """
shader_type spatial;
render_mode unshaded;
uniform vec3 col : source_color = vec3(1.0, 0.1, 0.1);
uniform float a = 0.0;
uniform float b = 0.5;
uniform float off = 0.0;
uniform float period = 26.0;
void fragment() {
	float t = fract(TIME / period + off);
	float on = step(a, t) * step(t, b);
	ALBEDO = col * mix(0.04, 3.2, on);
}
"""

const SCREEN := """
shader_type spatial;
render_mode unshaded;
uniform float seed = 0.0;
void fragment() {
	vec2 u = UV;
	float t = TIME * 0.7 + seed;
	float bands = step(0.5, fract(u.y * 6.0 + t * 0.6));
	vec3 c = 0.5 + 0.5 * cos(6.2831 * (vec3(0.0, 0.33, 0.67) + u.x * 0.6 + t * 0.15));
	float blink = step(0.35, fract(t * 0.9));
	ALBEDO = c * mix(0.6, 1.6, bands) * (0.7 + 0.5 * blink);
}
"""

const BLINK := """
shader_type spatial;
render_mode unshaded;
uniform vec3 col : source_color = vec3(1.0, 0.05, 0.03);
void fragment() {
	ALBEDO = col * mix(0.05, 4.0, step(0.55, fract(TIME * 0.5 + UV2.x)));
}
"""


static func _sh(code: String) -> Shader:
	var s := Shader.new()
	s.code = code
	return s


static func define_all() -> void:
	var fac := _sh(FACADE)
	# name: wall_a, wall_b, cell, win, lit, mirror, min_y
	var facs := {
		"l11_fac_office": [Color(0.23, 0.27, 0.31), Color(0.2, 0.23, 0.27), Vector2(1.6, 3.8), Vector2(0.86, 0.74), 0.4, 0.0],
		"l11_fac_stone": [Color(0.52, 0.47, 0.4), Color(0.47, 0.43, 0.37), Vector2(3.2, 3.6), Vector2(0.45, 0.52), 0.34, 0.0],
		"l11_fac_brick": [Color(0.36, 0.2, 0.15), Color(0.31, 0.17, 0.13), Vector2(3.0, 3.3), Vector2(0.42, 0.55), 0.38, 0.0],
		"l11_fac_concrete": [Color(0.42, 0.42, 0.4), Color(0.37, 0.37, 0.36), Vector2(3.4, 3.4), Vector2(0.55, 0.5), 0.3, 0.0],
		"l11_fac_apts": [Color(0.55, 0.5, 0.42), Color(0.5, 0.45, 0.38), Vector2(3.6, 3.0), Vector2(0.36, 0.5), 0.42, 0.0],
		"l11_fac_house": [Color(0.6, 0.57, 0.5), Color(0.55, 0.52, 0.46), Vector2(3.4, 2.9), Vector2(0.32, 0.45), 0.5, 0.0],
		"l11_fac_mirror": [Color(0.09, 0.09, 0.1), Color(0.07, 0.07, 0.08), Vector2(1.8, 3.6), Vector2(0.88, 0.8), 0.0, 1.0],
	}
	for n in facs.keys():
		var p: Array = facs[n]
		var m := ShaderMaterial.new()
		m.shader = fac
		m.set_shader_parameter("wall_a", p[0])
		m.set_shader_parameter("wall_b", p[1])
		m.set_shader_parameter("cell", p[2])
		m.set_shader_parameter("win", p[3])
		m.set_shader_parameter("lit", p[4])
		m.set_shader_parameter("mirror", p[5])
		m.set_shader_parameter("min_y", 0.9 if n == "l11_fac_mirror" else (2.0 if n == "l11_fac_house" else 4.6))
		m.set_shader_parameter("roof", Color(0.07, 0.07, 0.075))
		MatLib.register(n, m)
	var sig := _sh(SIGNAL)
	# NS: green [0,.44] amber [.44,.5] red [.5,1]; EW is half a cycle later
	for d in ["ns", "ew"]:
		for c in [["r", Color(1.0, 0.08, 0.05), 0.5, 1.0], ["a", Color(1.0, 0.55, 0.05), 0.44, 0.5], ["g", Color(0.1, 1.0, 0.45), 0.0, 0.44]]:
			var m := ShaderMaterial.new()
			m.shader = sig
			m.set_shader_parameter("col", c[1])
			m.set_shader_parameter("a", c[2])
			m.set_shader_parameter("b", c[3])
			m.set_shader_parameter("off", 0.0 if d == "ns" else 0.5)
			MatLib.register("l11_sig_%s_%s" % [d, c[0]], m)
	var scr := ShaderMaterial.new()
	scr.shader = _sh(SCREEN)
	MatLib.register("l11_screen_game", scr)
	var bl := ShaderMaterial.new()
	bl.shader = _sh(BLINK)
	MatLib.register("l11_blink", bl)
	MatLib.define("l11_asphalt", {"albedo_a": Color(0.1, 0.1, 0.105), "albedo_b": Color(0.075, 0.075, 0.08), "wetness": 0.35, "pattern_strength": 0.25}, "asphalt")
	MatLib.define("l11_sidewalk", {"pattern": 1, "pattern_scale": Vector2(1.5, 1.5), "grout_width": 0.01, "grout_color": Color(0.2, 0.2, 0.19), "albedo_a": Color(0.42, 0.41, 0.39), "albedo_b": Color(0.37, 0.36, 0.34), "tile_variation": 0.05, "stain_amount": 0.25}, "concrete")
	MatLib.define("l11_plaza", {"pattern": 14, "pattern_scale": Vector2(1.2, 0.6), "grout_width": 0.012, "grout_color": Color(0.22, 0.21, 0.2), "albedo_a": Color(0.5, 0.47, 0.43), "albedo_b": Color(0.44, 0.42, 0.38)}, "concrete")
	MatLib.define("l11_curb", {"albedo_a": Color(0.5, 0.5, 0.48), "albedo_b": Color(0.45, 0.45, 0.43)}, "concrete")
	MatLib.define("l11_paint_white", {"albedo_a": Color(0.75, 0.75, 0.72), "albedo_b": Color(0.68, 0.68, 0.65), "roughness_a": 0.6}, "trim_white")
	MatLib.define("l11_paint_yellow", {"albedo_a": Color(0.75, 0.58, 0.12), "albedo_b": Color(0.7, 0.52, 0.1), "roughness_a": 0.6}, "trim_white")
	MatLib.define("l11_spray", {"albedo_a": Color(0.95, 0.35, 0.05), "albedo_b": Color(0.9, 0.3, 0.04), "emission_color": Color(0.9, 0.3, 0.05), "emission_energy": 0.25}, "trim_white")
	MatLib.define("l11_spray_red", {"albedo_a": Color(0.75, 0.05, 0.05), "albedo_b": Color(0.7, 0.04, 0.04), "emission_color": Color(0.8, 0.05, 0.05), "emission_energy": 0.2}, "trim_white")
	MatLib.define("l11_canal_wall", {"albedo_a": Color(0.3, 0.3, 0.28), "albedo_b": Color(0.24, 0.24, 0.23), "wetness": 0.5, "stain_amount": 0.5, "stain_color": Color(0.16, 0.18, 0.14), "grime_height": 1.2}, "concrete")
	MatLib.register("l11_water", MatLib.water({"shallow_color": Color(0.05, 0.09, 0.1), "deep_color": Color(0.01, 0.02, 0.025), "absorption": 1.6, "clarity": 0.3, "wave_height": 0.02, "wave_scale": 0.35, "foam_amount": 0.0, "roughness_value": 0.03}))
	MatLib.define("l11_rail_metal", {"albedo_a": Color(0.14, 0.15, 0.16), "albedo_b": Color(0.11, 0.12, 0.13), "metallic_value": 0.7, "roughness_a": 0.4}, "metal")
	MatLib.define("l11_steel", {"albedo_a": Color(0.62, 0.63, 0.65), "albedo_b": Color(0.56, 0.57, 0.59), "metallic_value": 0.9, "roughness_a": 0.22, "roughness_b": 0.3, "pattern": 2, "pattern_scale": Vector2(0.02, 1.0), "pattern_color": Color(0.5, 0.5, 0.52), "pattern_strength": 0.3}, "metal")
	MatLib.define("l11_grass", {"albedo_a": Color(0.12, 0.2, 0.08), "albedo_b": Color(0.09, 0.15, 0.06)}, "grass")
	MatLib.define("l11_bark", {"albedo_a": Color(0.2, 0.15, 0.11), "albedo_b": Color(0.15, 0.11, 0.08)}, "dirt")
	MatLib.define("l11_leaves", {"albedo_a": Color(0.1, 0.2, 0.08), "albedo_b": Color(0.06, 0.13, 0.05), "noise_scale": 3.0, "bump_strength": 2.2}, "grass")
	MatLib.define("l11_roofdeck", {"albedo_a": Color(0.16, 0.16, 0.17), "albedo_b": Color(0.12, 0.12, 0.13)}, "concrete_dark")
	MatLib.define("l11_terrazzo", {"pattern": 15, "albedo_a": Color(0.62, 0.6, 0.56), "albedo_b": Color(0.58, 0.56, 0.52), "pattern_color": Color(0.35, 0.34, 0.32), "pattern_strength": 0.6, "roughness_a": 0.25, "roughness_b": 0.35}, "concrete")
	MatLib.define("l11_tile", {"pattern": 1, "pattern_scale": Vector2(0.6, 0.6), "grout_width": 0.008, "grout_color": Color(0.5, 0.5, 0.48), "albedo_a": Color(0.74, 0.74, 0.7), "albedo_b": Color(0.7, 0.7, 0.67), "roughness_a": 0.3}, "concrete")
	MatLib.define("l11_carpet", {"albedo_a": Color(0.25, 0.27, 0.3), "albedo_b": Color(0.22, 0.24, 0.27), "wetness": 0.0, "stain_amount": 0.05}, "l0_carpet")
	MatLib.define("l11_shop_wall", {"albedo_a": Color(0.82, 0.8, 0.74), "albedo_b": Color(0.78, 0.76, 0.7), "emission_color": Color(1.0, 0.93, 0.8), "emission_energy": 0.32}, "plaster")
	MatLib.define("l11_shop_ceiling", {"albedo_a": Color(0.85, 0.85, 0.82), "albedo_b": Color(0.8, 0.8, 0.78), "emission_color": Color(1.0, 0.95, 0.85), "emission_energy": 0.22, "pattern": 7, "pattern_scale": Vector2(0.6, 0.6), "grout_width": 0.01, "grout_color": Color(0.6, 0.6, 0.58)}, "plaster")
	MatLib.register("l11_panel", MatLib.panel(Color(0.95, 0.97, 1.0), 2.6))
	MatLib.register("l11_lamp", MatLib.panel(Color(1.0, 0.82, 0.55), 3.4))
	MatLib.register("l11_lamp_led", MatLib.panel(Color(0.85, 0.92, 1.0), 3.2))
	MatLib.register("l11_neon_pink", MatLib.panel(Color(1.0, 0.25, 0.75), 3.4))
	MatLib.register("l11_neon_cyan", MatLib.panel(Color(0.2, 0.9, 1.0), 3.0))
	MatLib.register("l11_button", MatLib.panel(Color(1.0, 0.85, 0.4), 2.2))
	MatLib.register("l11_candle", MatLib.panel(Color(1.0, 0.6, 0.25), 2.6, 0.6))
	MatLib.define("l11_shelf", {"albedo_a": Color(0.7, 0.7, 0.68), "albedo_b": Color(0.65, 0.65, 0.63), "metallic_value": 0.3}, "metal")
	MatLib.define("l11_goods", {"pattern": 2, "pattern_scale": Vector2(0.11, 1.0), "pattern_color": Color(0.75, 0.2, 0.15), "pattern_strength": 0.8, "albedo_a": Color(0.25, 0.4, 0.6), "albedo_b": Color(0.7, 0.6, 0.2), "noise_scale": 6.0}, "plaster")
	MatLib.define("l11_wood", {"albedo_a": Color(0.4, 0.27, 0.16), "albedo_b": Color(0.34, 0.22, 0.13)}, "wood_floor")
	MatLib.define("l11_fabric", {"albedo_a": Color(0.25, 0.3, 0.42), "albedo_b": Color(0.2, 0.25, 0.36), "noise_scale": 4.0}, "plaster")
	MatLib.define("l11_dark", {"albedo_a": Color(0.05, 0.05, 0.055), "albedo_b": Color(0.04, 0.04, 0.045), "roughness_a": 0.5}, "concrete_dark")
	MatLib.define("l11_cabinet_red", {"albedo_a": Color(0.45, 0.06, 0.08), "albedo_b": Color(0.4, 0.05, 0.07), "roughness_a": 0.4}, "trim_white")
	MatLib.define("l11_cabinet_blue", {"albedo_a": Color(0.08, 0.12, 0.4), "albedo_b": Color(0.07, 0.1, 0.35), "roughness_a": 0.4}, "trim_white")
	MatLib.define("l11_poster", {"albedo_a": Color(0.24, 0.27, 0.16), "albedo_b": Color(0.22, 0.25, 0.15), "pattern": 2, "pattern_scale": Vector2(0.4, 1.0), "pattern_color": Color(0.5, 0.08, 0.06), "pattern_strength": 0.5}, "plaster")
	MatLib.define("l11_barrier", {"pattern": 2, "uv_rotate": 0.785, "pattern_scale": Vector2(0.3, 1.0), "albedo_a": Color(0.85, 0.85, 0.82), "albedo_b": Color(0.8, 0.8, 0.78), "pattern_color": Color(0.75, 0.08, 0.05), "pattern_strength": 1.0}, "trim_white")
	MatLib.define("l11_cone", {"albedo_a": Color(0.95, 0.35, 0.05), "albedo_b": Color(0.9, 0.3, 0.04), "emission_color": Color(0.9, 0.3, 0.05), "emission_energy": 0.15}, "trim_white")
	MatLib.define("l11_flower", {"albedo_a": Color(0.85, 0.85, 0.8), "albedo_b": Color(0.8, 0.2, 0.25), "noise_scale": 9.0, "noise_mix": 0.6}, "plaster")
	MatLib.define("l11_paper", {"albedo_a": Color(0.86, 0.84, 0.78), "albedo_b": Color(0.82, 0.8, 0.74)}, "plaster")
	MatLib.define("l11_crate", {"albedo_a": Color(0.5, 0.4, 0.26), "albedo_b": Color(0.44, 0.35, 0.22), "uv_rotate": 1.5708, "pattern_scale": Vector2(1.0, 0.15)}, "wood_floor")
	var ads := [[Color(0.9, 0.2, 0.1), Color(1.0, 0.85, 0.2), 2], [Color(0.1, 0.4, 0.9), Color(0.95, 0.95, 0.9), 9], [Color(0.1, 0.65, 0.35), Color(0.95, 0.9, 0.3), 5],
		[Color(0.55, 0.1, 0.6), Color(0.2, 0.8, 0.9), 10], [Color(0.95, 0.6, 0.1), Color(0.15, 0.15, 0.2), 2], [Color(0.85, 0.85, 0.82), Color(0.8, 0.1, 0.15), 9]]
	for i in ads.size():
		var a: Array = ads[i]
		MatLib.define("l11_ad_%d" % i, {"albedo_a": a[0], "albedo_b": a[0], "pattern": a[2], "pattern_scale": Vector2(0.9, 0.9), "pattern_color": a[1], "pattern_strength": 0.7,
			"emission_color": (a[0] as Color).lerp(a[1], 0.3), "emission_energy": 1.1, "noise_scale": 0.3}, "plaster")
	MatLib.define("l11_ad_faded", {"albedo_a": Color(0.42, 0.4, 0.36), "albedo_b": Color(0.3, 0.28, 0.25), "noise_scale": 2.0, "peel_amount": 0.7, "peel_color": Color(0.2, 0.19, 0.17), "stain_amount": 0.6}, "plaster")
