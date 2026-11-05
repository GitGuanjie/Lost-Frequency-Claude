extends RefCounted
## Level 25 props, called statically from L025.gd (`lvl` is the running level):
## upright 1980s cabinets (dead, wrecked, working), the coin machines, boxes,
## loose quarters, cold boilers, nailed shelves, pipes, missing ceiling tiles,
## faulty outlets and the level's procedural materials.

const TITLES := ["CHROME COMET", "ASTRO WARDEN", "VOLT RUNNER", "NEBULA KNIGHT", "GRID GOBLIN",
	"LASER LOTUS", "CRYSTAL DIVER", "ORBIT OGRE", "HYPER QUASAR", "TURBO TORTOISE"]
const TUNES := [{"bpm": 132.0, "scale": [0, 3, 5, 7, 10, 12], "root": 220.0},
	{"bpm": 150.0, "scale": [0, 2, 4, 7, 9, 12], "root": 262.0},
	{"bpm": 116.0, "scale": [0, 3, 7, 10, 12, 15], "root": 196.0}]
const TINTS := [Color(0.3, 0.95, 1.0), Color(1.0, 0.45, 0.9), Color(0.5, 1.0, 0.35), Color(1.0, 0.72, 0.3)]
## Marks left on the built-route machines (page: hints about the other side, or a level number).
const HINT := {"L025>L000#1": ["0", "YELLOW ROOMS. WET CARPET."], "L025>L005#2": ["5", "OLD HOTEL. JAZZ PLAYING"],
	"L025>L009#3": ["9", "NIGHT SUBURBS. AVOID STREETS"], "L025>L011#5": ["11", "EMPTY CITY. LIGHTS WORK"],
	"L025>L019#6": ["19", "ATTIC. DON'T FOLLOW THE GLOW"], "L025>L037#9": ["37", "WARM WATER, WHITE TILE"],
	"L025>L188#17": ["188", "DO NOT ENTER. WINDOWS"]}
## Attract-mode CRT: scrolling stars, an invader formation, a ship; credit dims, launch flashes.
const CRT := """shader_type spatial;
render_mode unshaded, cull_back;
uniform vec3 tint : source_color = vec3(0.3, 0.95, 1.0);
uniform float seed = 0.0;
uniform float mode = 0.0;
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233)) + seed * 7.13) * 43758.5453); }
void fragment() {
	vec2 uv = UV;
	vec2 c = uv - 0.5;
	float t = TIME + seed * 10.0;
	float star = step(0.986, h(floor(vec2(uv.x * 46.0, uv.y * 34.0 - t * 4.0))));
	vec2 q = vec2(uv.x * 9.0 + sin(t * 0.9) * 1.2, uv.y * 12.0);
	vec2 qi = floor(q);
	vec2 p = floor(fract(q) * vec2(7.0, 6.0));
	p.x = abs(p.x - 3.0);
	float row = step(1.0, qi.y) * step(qi.y, 4.0) * step(0.5, fract(qi.x * 0.5 + 0.25));
	float spr = row * step(0.42, h(p + vec2(0.0, qi.y * 5.0))) * step(p.x, 2.5) * step(0.5, p.y) * step(p.y, 4.5);
	float ship = step(abs(uv.x - 0.5 - sin(t * 1.3) * 0.3), 0.035) * step(abs(uv.y - 0.86), 0.025);
	vec3 col = tint * (star * 1.3 + spr * 1.1) + vec3(1.0, 0.95, 0.6) * ship * 1.4;
	col = col * (1.0 - 0.7 * step(0.5, mode) * step(mode, 1.5)) + tint * 0.05;
	col = mix(col, vec3(1.6), clamp(mode - 1.0, 0.0, 1.0) * (0.6 + 0.4 * sin(t * 40.0)));
	col *= (0.72 + 0.28 * sin(uv.y * 420.0)) * (1.0 - dot(c, c) * 1.8);
	ALBEDO = col;
}
"""
## Faded 1980s arcade carpet (ours: the page only says the floors are dusty).
const CARPET := """shader_type spatial;
render_mode diffuse_burley;
uniform vec3 base : source_color = vec3(0.05, 0.04, 0.075);
uniform vec3 dust : source_color = vec3(0.3, 0.28, 0.27);
varying vec3 wp;
float h(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1, 0)), f.x), mix(h(i + vec2(0, 1)), h(i + vec2(1, 1)), f.x), f.y); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 u = wp.xz * 2.9;
	vec2 ci = floor(u);
	float r = h(ci);
	vec2 q = fract(u) - 0.5 - (vec2(h(ci + 3.1), h(ci + 7.7)) - 0.5) * 0.35;
	float d = length(q);
	float s = 0.0;
	if (r < 0.28) s = smoothstep(0.03, 0.0, abs(d - 0.15));
	else if (r < 0.5) s = smoothstep(0.035, 0.0, min(abs(q.x), abs(q.y))) * step(d, 0.19);
	else if (r < 0.74) s = smoothstep(0.03, 0.0, abs(q.y - 0.07 * sin(q.x * 30.0))) * step(abs(q.x), 0.22);
	vec3 col = r < 0.28 ? vec3(0.5, 0.12, 0.4) : (r < 0.5 ? vec3(0.1, 0.38, 0.48) : vec3(0.52, 0.42, 0.12));
	vec3 a = mix(base, col, s * 0.5) * (0.82 + 0.36 * n2(wp.xz * 170.0));
	float dn = n2(wp.xz * 0.6) * 0.6 + n2(wp.xz * 2.9) * 0.4;
	ALBEDO = mix(a, dust, smoothstep(0.38, 0.9, dn) * 0.5);
	ROUGHNESS = 1.0;
}
"""


static func _var(n: String, base: Dictionary, over: Dictionary) -> void:
	var d := base.duplicate()
	d.merge(over, true)
	MatLib.define(n, d)


static func materials() -> void:
	var dust := Color(0.34, 0.31, 0.29)
	var wall := {"albedo_a": Color(0.3, 0.06, 0.075), "albedo_b": Color(0.23, 0.042, 0.056), "noise_scale": 0.5,
		"stain_amount": 0.5, "stain_color": Color(0.17, 0.08, 0.07), "stain_scale": 0.28, "grime_height": 1.1,
		"grime_color": Color(0.12, 0.06, 0.05),
		"roughness_a": 0.88, "roughness_b": 0.97, "bump_strength": 0.4}
	MatLib.define("l25_wall", wall)
	_var("l25_wall_b", wall, {"albedo_a": Color(0.1, 0.19, 0.2), "albedo_b": Color(0.08, 0.15, 0.16)})
	_var("l25_wall_c", wall, {"albedo_a": Color(0.38, 0.28, 0.1), "albedo_b": Color(0.31, 0.23, 0.08)})
	_var("l25_wall_d", wall, {"albedo_a": Color(0.19, 0.035, 0.05), "albedo_b": Color(0.14, 0.025, 0.04)})
	MatLib.define("l25_back", {"albedo_a": Color(0.27, 0.29, 0.25), "albedo_b": Color(0.22, 0.24, 0.2), "pattern": 4,
		"pattern_scale": Vector2(0.4, 0.2), "grout_width": 0.008, "grout_color": Color(0.17, 0.18, 0.15), "stain_amount": 0.6,
		"stain_color": Color(0.16, 0.14, 0.1), "grime_height": 0.9, "grime_color": Color(0.1, 0.09, 0.07), "roughness_a": 0.9, "roughness_b": 1.0})
	var sh2 := Shader.new()
	sh2.code = CARPET
	var cm := ShaderMaterial.new()
	cm.shader = sh2
	MatLib.register("l25_carpet", cm)
	MatLib.define("l25_concrete", {"albedo_a": Color(0.33, 0.32, 0.3), "albedo_b": Color(0.27, 0.26, 0.24), "stain_amount": 0.55,
		"stain_color": Color(0.2, 0.18, 0.15), "noise_scale": 1.2, "bump_strength": 0.7, "roughness_a": 0.9, "roughness_b": 1.0})
	MatLib.define("l25_ceiling", {"albedo_a": Color(0.44, 0.42, 0.38), "albedo_b": Color(0.37, 0.35, 0.31), "pattern": 7,
		"pattern_scale": Vector2(0.61, 0.61), "grout_width": 0.012, "grout_color": Color(0.24, 0.22, 0.19), "stain_amount": 0.62,
		"stain_color": Color(0.3, 0.23, 0.13), "roughness_a": 0.92, "roughness_b": 1.0, "noise_scale": 0.6, "tile_variation": 0.07})
	var art := [[Color(0.75, 0.2, 0.15), 8], [Color(0.2, 0.55, 0.75), 2], [Color(0.85, 0.65, 0.15), 10]]
	for i in 3:
		MatLib.define("l25_art%d" % i, {"albedo_a": Color(0.07, 0.06, 0.08), "albedo_b": Color(0.05, 0.05, 0.06), "pattern": art[i][1],
			"pattern_scale": Vector2(0.18, 0.14), "pattern_color": art[i][0], "pattern_strength": 0.8, "stain_amount": 0.5,
			"stain_color": dust, "roughness_a": 0.55, "noise_scale": 2.0})
	MatLib.define("l25_plenum", {"albedo_a": Color(0.05, 0.045, 0.04), "albedo_b": Color(0.03, 0.028, 0.025), "roughness_a": 1.0, "roughness_b": 1.0})
	MatLib.define("l25_pipe", {"albedo_a": Color(0.3, 0.22, 0.17), "albedo_b": Color(0.22, 0.16, 0.12), "metallic_value": 0.5,
		"roughness_a": 0.6, "roughness_b": 0.9, "stain_amount": 0.4, "stain_color": Color(0.35, 0.18, 0.08)})
	var paints := [[Color(0.06, 0.06, 0.07), Color(0.05, 0.05, 0.055)], [Color(0.42, 0.08, 0.06), Color(0.34, 0.06, 0.05)],
		[Color(0.09, 0.14, 0.34), Color(0.07, 0.1, 0.27)], [Color(0.46, 0.35, 0.09), Color(0.38, 0.28, 0.07)], [Color(0.34, 0.21, 0.12), Color(0.28, 0.17, 0.1)]]
	for i in 5:
		var d := {"albedo_a": paints[i][0], "albedo_b": paints[i][1], "stain_amount": 0.45, "stain_color": dust,
			"roughness_a": 0.5, "roughness_b": 0.8, "noise_scale": 2.2, "bump_strength": 0.3}
		if i == 0:
			d.merge({"pattern": 2, "pattern_scale": Vector2(0.33, 1.0), "pattern_color": Color(0.55, 0.12, 0.1), "pattern_strength": 0.55}, true)
		if i == 4:
			d.merge({"pattern": 3, "pattern_scale": Vector2(1.0, 0.18), "grout_width": 0.002, "grout_color": Color(0.18, 0.11, 0.06)}, true)
		MatLib.define("l25_cab%d" % i, d)
	MatLib.define("l25_burnt", {"albedo_a": Color(0.05, 0.045, 0.04), "albedo_b": Color(0.02, 0.02, 0.02), "stain_amount": 0.6,
		"stain_color": Color(0.16, 0.1, 0.06), "noise_scale": 3.0, "roughness_a": 1.0, "roughness_b": 1.0, "bump_strength": 1.5})
	MatLib.define("l25_scorch", {"albedo_a": Color(0.03, 0.025, 0.02), "albedo_b": Color(0.07, 0.05, 0.04), "noise_scale": 2.0, "roughness_a": 1.0})
	MatLib.define("l25_bezel", {"albedo_a": Color(0.035, 0.035, 0.04), "albedo_b": Color(0.03, 0.03, 0.035), "roughness_a": 0.45,
		"roughness_b": 0.6, "stain_amount": 0.3, "stain_color": dust})
	MatLib.define("l25_glass", {"albedo_a": Color(0.015, 0.02, 0.022), "albedo_b": Color(0.01, 0.012, 0.015), "roughness_a": 0.06,
		"roughness_b": 0.12, "stain_amount": 0.25, "stain_color": Color(0.2, 0.2, 0.2)})
	MatLib.define("l25_glass_broken", {"albedo_a": Color(0.02, 0.02, 0.025), "albedo_b": Color(0.02, 0.02, 0.025), "pattern": 15,
		"pattern_color": Color(0.45, 0.48, 0.5), "pattern_strength": 0.6, "roughness_a": 0.2, "roughness_b": 0.5})
	MatLib.define("l25_metal", {"albedo_a": Color(0.5, 0.5, 0.52), "albedo_b": Color(0.38, 0.38, 0.4), "metallic_value": 0.8,
		"roughness_a": 0.35, "roughness_b": 0.6, "noise_scale": 2.0, "stain_amount": 0.35, "stain_color": Color(0.3, 0.2, 0.12)})
	MatLib.define("l25_wood", {"albedo_a": Color(0.36, 0.25, 0.15), "albedo_b": Color(0.3, 0.2, 0.12), "pattern": 3,
		"pattern_scale": Vector2(1.2, 0.2), "stain_amount": 0.7, "stain_color": dust, "roughness_a": 0.8})
	MatLib.define("l25_card", {"albedo_a": Color(0.5, 0.38, 0.24), "albedo_b": Color(0.44, 0.33, 0.2), "stain_amount": 0.45,
		"stain_color": Color(0.33, 0.27, 0.2), "roughness_a": 1.0, "roughness_b": 1.0})
	MatLib.define("l25_boiler", {"albedo_a": Color(0.22, 0.2, 0.18), "albedo_b": Color(0.17, 0.15, 0.13), "metallic_value": 0.6,
		"roughness_a": 0.55, "roughness_b": 0.85, "stain_amount": 0.55, "stain_color": Color(0.36, 0.2, 0.1), "noise_scale": 1.8, "bump_strength": 0.8})
	MatLib.define("l25_door", {"albedo_a": Color(0.33, 0.38, 0.33), "albedo_b": Color(0.28, 0.33, 0.29), "stain_amount": 0.4,
		"stain_color": Color(0.25, 0.22, 0.18), "grime_height": 0.4, "roughness_a": 0.6})
	MatLib.define("l25_tape", {"albedo_a": Color(0.82, 0.75, 0.56), "albedo_b": Color(0.78, 0.71, 0.52), "roughness_a": 0.8})
	MatLib.define("l25_paper", {"albedo_a": Color(0.86, 0.84, 0.78), "albedo_b": Color(0.8, 0.78, 0.7), "roughness_a": 0.9})
	MatLib.define("l25_puddle", {"albedo_a": Color(0.07, 0.06, 0.07), "albedo_b": Color(0.05, 0.045, 0.055), "roughness_a": 0.06,
		"roughness_b": 0.18, "metallic_value": 0.2})
	MatLib.define("l25_coin", {"albedo_a": Color(0.75, 0.75, 0.72), "albedo_b": Color(0.7, 0.7, 0.66), "metallic_value": 0.9,
		"roughness_a": 0.25, "emission_color": Color(0.7, 0.7, 0.62), "emission_energy": 0.6})
	MatLib.define("l25_outlet", {"albedo_a": Color(0.7, 0.66, 0.58), "albedo_b": Color(0.62, 0.58, 0.5), "roughness_a": 0.5})
	MatLib.define("l25_marq_dead", {"albedo_a": Color(0.2, 0.17, 0.15), "albedo_b": Color(0.16, 0.13, 0.12), "roughness_a": 0.35,
		"stain_amount": 0.5, "stain_color": dust})
	MatLib.register("l25_panel_troffer", MatLib.panel(Color(1.0, 0.88, 0.7), 1.7))
	MatLib.register("l25_panel_bulb", MatLib.panel(Color(1.0, 0.78, 0.5), 3.0))
	MatLib.register("l25_panel_coin", MatLib.panel(Color(1.0, 0.16, 0.1), 2.4))
	MatLib.register("l25_panel_marq0", MatLib.panel(Color(1.0, 0.8, 0.5), 1.25))
	MatLib.register("l25_panel_marq1", MatLib.panel(Color(1.0, 0.45, 0.8), 1.25))
	MatLib.register("l25_panel_marq2", MatLib.panel(Color(0.5, 0.88, 1.0), 1.25))
	var sh := Shader.new()
	sh.code = CRT
	var crt := ShaderMaterial.new()
	crt.shader = sh
	MatLib.register("l25_crt", crt)


# ------------------------------------------------------------- cabinets

static func bx(k: GeoKit, xf: Transform3D, c: Vector3, s: Vector3, mat: String, tilt := 0.0) -> void:
	k.box_xf(xf * Transform3D(Basis(Vector3.RIGHT, tilt), c), s, mat, GeoKit.ALL, false)


## Upright cabinet in a local frame (front +Z, origin on the floor).
## wreck: lit | dead | smash | burnt | bullets | gutted
static func cab(k: GeoKit, xf: Transform3D, paint: int, wreck: String, r: RandomNumberGenerator) -> void:
	var m := "l25_burnt" if wreck == "burnt" else "l25_cab%d" % paint
	var B := xf.basis
	bx(k, xf, Vector3(0, 0.93, -0.13), Vector3(0.66, 1.86, 0.54), m)
	bx(k, xf, Vector3(0, 0.43, 0.27), Vector3(0.64, 0.86, 0.26), m)
	bx(k, xf, Vector3(0, 0.55, 0.405), Vector3(0.26, 0.3, 0.012), "l25_metal")
	if wreck != "burnt":
		for sd in [-1.0, 1.0]:
			k.quad(xf * Vector3(sd * 0.332, 0.98, -0.13), B.x * sd, B.z * 0.24, B.y * 0.6, "l25_art%d" % (paint % 3))
	if wreck != "gutted":
		bx(k, xf, Vector3(0, 0.93, 0.37), Vector3(0.62, 0.06, 0.3), "l25_bezel", 0.25)
		bx(k, xf, Vector3(-0.13, 1.0, 0.43), Vector3(0.025, 0.11, 0.025), "l25_metal")
		bx(k, xf, Vector3(-0.13, 1.06, 0.43), Vector3(0.05, 0.05, 0.05), "l25_cab1")
		bx(k, xf, Vector3(0.1, 0.975, 0.42), Vector3(0.045, 0.03, 0.045), "l25_cab3")
		bx(k, xf, Vector3(0.19, 0.97, 0.405), Vector3(0.045, 0.03, 0.045), "l25_cab1")
	bx(k, xf, Vector3(0, 1.3, 0.145), Vector3(0.62, 0.62, 0.02), "l25_bezel", -0.17)
	if wreck != "gutted" or r.randf() < 0.5:
		bx(k, xf, Vector3(0, 1.76, 0.24), Vector3(0.66, 0.24, 0.24), "l25_bezel")
		if wreck == "lit":
			k.quad(xf * Vector3(0, 1.76, 0.362), B.z, B.x * 0.31, B.y * 0.1, "l25_panel_marq%d" % (paint % 3), Vector2.ZERO, true)
		else:
			k.quad(xf * Vector3(0, 1.76, 0.362), B.z, B.x * 0.31, B.y * 0.1, "l25_marq_dead")
	if wreck == "lit":
		for s in [-0.05, 0.05]:
			k.quad(xf * Vector3(s, 0.63, 0.413), B.z, B.x * 0.014, B.y * 0.024, "l25_panel_coin", Vector2.ZERO, true)
	else:
		var sb := B * Basis(Vector3.RIGHT, -0.17)
		k.quad(xf * Vector3(0, 1.3, 0.157), sb.z, sb.x * 0.23, sb.y * 0.18, "l25_glass_broken" if wreck == "smash" else "l25_glass")
	k.quad(xf * Vector3(0, 0.49, 0.413), B.z, B.x * 0.05, B.y * 0.012, "l25_plenum")   # the second, larger slot
	if wreck == "bullets":
		for i in 5 + r.randi() % 4:
			var sd := 1.0 if r.randf() < 0.5 else -1.0
			k.quad(xf * Vector3(sd * 0.332, r.randf_range(0.5, 1.6), r.randf_range(-0.35, 0.3)), B.x * sd, B.z * 0.011, B.y * 0.011, "l25_plenum")
	k.add_box_shape(xf * Transform3D(Basis(), Vector3(0, 0.93, 0)), Vector3(0.66, 1.86, 0.8), "wood")


## A dead cabinet, sometimes pulled out and twisted, or (topple) knocked over.
static func dead(k: GeoKit, p: Vector3, yaw: float, r: RandomNumberGenerator, ransack: float, topple: bool) -> void:
	var b := Basis(Vector3.UP, yaw)
	var o := p
	var x := r.randf()
	if topple and x < ransack * 0.4:
		b = b * Basis(Vector3.RIGHT, -PI * 0.5)
		o += Vector3.UP * 0.4
	elif topple and x < ransack * 0.7:
		b = b * Basis(Vector3.FORWARD, PI * 0.5)
		o += Vector3.UP * 0.33
	elif x < ransack:
		b = Basis(Vector3.UP, yaw + r.randf_range(-0.5, 0.5))
		o += b.z * r.randf_range(0.0, 0.35)
	var w := r.randf()
	var wreck := "dead" if w < 0.3 else ("smash" if w < 0.55 else ("burnt" if w < 0.66 else ("bullets" if w < 0.78 else "gutted")))
	cab(k, Transform3D(b, o), r.randi() % 5, wreck, r)


static func examine(lvl, pos: Vector3, kind: String) -> void:
	var t: String = {"smash": "The screen was bashed in with something heavy. Glass grit crunches underfoot.",
		"bullets": "A ragged line of bullet holes through the side panel. Someone wanted this machine dead.",
		"burnt": "Scorched black, the paint blistered. These were set alight on purpose."}[kind]
	lvl.add_interactable(pos, Vector3(0.9, 1.2, 0.9), "Examine the cabinet", func(_p): Overlay.toast(t, 3.5))


## A working, tethered machine: lit marquee, CRT attract mode, coin lights,
## number marks, chiptune, the exit trigger and the coin interaction.
static func working(lvl, k: GeoKit, node: Node3D, p: Vector3, fwd: Vector3, e: String, g: String) -> void:
	var yaw := atan2(fwd.x, fwd.z)
	var xf := Transform3D(Basis(Vector3.UP, yaw), p)
	var n := absi(hash(e))
	var r := RandomNumberGenerator.new()
	r.seed = n
	cab(k, xf, n % 5, "lit", r)
	var tint: Color = Color(0.8, 0.86, 1.0) if e.ends_with("#17") else TINTS[n % 4]
	var sx := xf * Transform3D(Basis(Vector3.RIGHT, -0.17), Vector3(0, 1.3, 0.158))
	var scr := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.46, 0.36)
	scr.mesh = qm
	var mat := (MatLib.get_mat("l25_crt") as ShaderMaterial).duplicate() as ShaderMaterial
	mat.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
	mat.set_shader_parameter("seed", float(n % 97) * 0.37)
	scr.material_override = mat
	scr.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	scr.transform = sx
	node.add_child(scr)
	var txt := label(node, sx * Transform3D(Basis(), Vector3(0, -0.1, 0.004)), "INSERT COIN", 34, 0.0011, tint, true)
	label(node, xf * Transform3D(Basis(), Vector3(0, 1.76, 0.366)), TITLES[n % TITLES.size()], 40, 0.0012, Color(0.12, 0.03, 0.05), true)
	var lv: String = HINT[e][0] if HINT.has(e) else e.get_slice(">", 1).get_slice("#", 0).trim_prefix("L").lstrip("0")
	marks(k, node, xf, lv, HINT[e][1] if HINT.has(e) else "")
	var sl := SpotLight3D.new()
	sl.light_color = tint
	sl.light_energy = 2.4
	sl.spot_range = 6.5
	sl.spot_angle = 64.0
	sl.spot_attenuation = 1.1
	sl.transform = Transform3D(Basis.looking_at(fwd * 2.0 + Vector3.DOWN * 1.1, Vector3.UP), p + Vector3.UP * 1.35 + fwd * 0.3)
	node.add_child(sl)
	emit(node, "chiptune", p + Vector3.UP * 1.2, TUNES[n % 3], -17.0, 16.0)
	var t: ExitTrigger = lvl.make_exit(e, "interact", p + fwd * 0.95 + Vector3.UP * 1.0, Vector3(1.2, 2.0, 1.2), "", node)
	if t:
		t.condition = Callable(lvl, "machine_ready").bind(e)
	var it := Interactable.new()
	node.add_child(it)
	it.setup(p + Vector3.UP * 0.95, Vector3(0.74, 1.9, 0.86), "", Callable(lvl, "use_machine").bind(e))
	it.rotation.y = yaw
	lvl.cabs[e] = {"st": "idle", "t": 0.0, "it": it, "trig": t, "mat": mat, "txt": txt, "pos": p}
	lvl.refresh(lvl.cabs[e])


## Masking-tape note on the kick panel and a sprayed level number on both sides.
static func marks(k: GeoKit, node: Node3D, xf: Transform3D, lv: String, desc: String) -> void:
	var B := xf.basis
	k.quad(xf * Vector3(0, 0.79, 0.405), B.z, B.x * 0.22, B.y * 0.06, "l25_tape")
	label(node, xf * Transform3D(Basis(), Vector3(0, 0.79, 0.409)), "LVL " + lv + ("\n" + desc if desc != "" else ""), 22, 0.00095, Color(0.05, 0.05, 0.08), false)
	for s in [-1.0, 1.0]:
		label(node, xf * Transform3D(Basis(Vector3.UP, s * PI * 0.5), Vector3(s * 0.336, 1.22, -0.12)), lv, 130, 0.0024, Color(0.92, 0.92, 0.86), false)


## Ransack litter: prize tickets, paper, glass grit.
static func litter(k: GeoKit, R: Rect2, r: RandomNumberGenerator, n: int) -> void:
	for i in n:
		var c := Vector3(r.randf_range(R.position.x + 0.5, R.end.x - 0.5), 0.005, r.randf_range(R.position.y + 0.5, R.end.y - 0.5))
		var a := r.randf() * TAU
		var s := r.randf_range(0.04, 0.14)
		var u := Vector3(cos(a), 0, sin(a))
		k.quad(c, Vector3.UP, u * s, Vector3(-u.z, 0, u.x) * s * r.randf_range(0.4, 1.3), ["l25_paper", "l25_tape", "l25_glass_broken"][r.randi() % 3])


static func label(node: Node3D, xf: Transform3D, text: String, size: int, px: float, col: Color, glow: bool) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = px
	l.modulate = col
	l.outline_size = 0
	l.shaded = not glow
	l.double_sided = false
	l.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	l.transform = xf
	node.add_child(l)
	return l


static func emit(node: Node3D, recipe: String, p: Vector3, params: Dictionary, db: float, dist: float) -> AudioStreamPlayer3D:
	var a := AudioStreamPlayer3D.new()
	a.stream = AudioSynth.get_stream(recipe, params)
	a.volume_db = db
	a.max_distance = dist
	a.unit_size = 3.0
	a.bus = "Ambience"
	a.position = p
	a.autoplay = true
	node.add_child(a)
	return a


static func jingle(lvl, p: Vector3) -> void:
	var a := AudioStreamPlayer3D.new()
	a.stream = AudioSynth.get_stream("music_box", {"notes": [0, 4, 7, 12, 16, 19, 24, 28], "root": 523.25})
	a.bus = "SFX"
	a.volume_db = -6.0
	lvl.add_child(a)
	a.global_position = p
	a.play()
	lvl.get_tree().create_timer(2.4).timeout.connect(a.queue_free)


# ---------------------------------------------------------- supplies

## Cardboard box; content > 0 quarters, 0 empty, -1 junk. Searched boxes stay searched.
static func box(lvl, k: GeoKit, node: Node3D, p: Vector3, id: String, content: int, yaw := 0.0) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw), p + Vector3.UP * 0.21)
	k.box_xf(xf, Vector3(0.55, 0.42, 0.45), "l25_card", GeoKit.ALL, true)
	if SaveService.flag(lvl.stable_id, id, false):
		return
	k.box_xf(xf.translated(Vector3.UP * 0.215), Vector3(0.56, 0.01, 0.1), "l25_tape", GeoKit.PY, false)
	var it := Interactable.new()
	node.add_child(it)
	it.setup(p + Vector3.UP * 0.3, Vector3(0.64, 0.5, 0.54), "Search the box", func(_p):
		SaveService.set_flag(lvl.stable_id, id, true)
		if content > 0:
			SaveService.add_item("quarter", content)
			Overlay.toast("Under old prize tickets: %s. (Quarters: %d)" % ["a quarter" if content == 1 else "%d quarters" % content, SaveService.item_count("quarter")], 3.0)
		elif content < 0:
			Overlay.toast("Prize tickets, a cracked joystick, a coil of wire. Nothing useful.", 2.5)
		else:
			Overlay.toast("Empty apart from dust.", 2.0))
	it.once = true


static func quarter(lvl, node: Node3D, p: Vector3, id: String) -> void:
	if SaveService.flag(lvl.stable_id, id, false):
		return
	var it := Interactable.new()
	node.add_child(it)
	it.setup(p + Vector3.UP * 0.05, Vector3(0.32, 0.1, 0.32), "Pick up a quarter", Callable())
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.016
	cm.bottom_radius = 0.016
	cm.height = 0.004
	cm.radial_segments = 12
	m.mesh = cm
	m.material_override = MatLib.get_mat("l25_coin")
	m.position = Vector3(0, -0.047, 0)
	it.add_child(m)
	it.action = func(_p):
		SaveService.set_flag(lvl.stable_id, id, true)
		SaveService.add_item("quarter", 1)
		Overlay.toast("A tarnished quarter. (Quarters: %d)" % SaveService.item_count("quarter"), 2.5)
		it.queue_free()
	it.once = true


## Old, long-unfired boiler; its firebox holds supplies (page: Almond Water, snacks).
static func boiler(lvl, k: GeoKit, node: Node3D, p: Vector3, f: Vector3, id: String, item: String) -> void:
	k.box(p + Vector3.UP * 0.08, Vector3(1.7, 0.16, 1.7), "l25_concrete")
	k.cylinder(p + Vector3.UP * 1.16, 0.75, 2.0, "l25_boiler", 16)
	k.cylinder(p + Vector3(0, 2.19, 0), 0.6, 0.06, "l25_boiler", 16, false)
	k.cylinder(p + Vector3(-f.x * 0.3, 2.6, -f.z * 0.3), 0.1, 0.9, "l25_pipe", 8, false)
	var hp := p + f * 0.76 + Vector3.UP * 0.75
	k.box(hp, Vector3(0.06, 0.34, 0.42) if absf(f.x) > 0.5 else Vector3(0.42, 0.34, 0.06), "l25_metal", GeoKit.ALL, false)
	if SaveService.flag(lvl.stable_id, id, false):
		return
	var it := Interactable.new()
	node.add_child(it)
	it.setup(hp + f * 0.08, Vector3(0.5, 0.5, 0.5), "Open the boiler hatch", func(_p):
		SaveService.set_flag(lvl.stable_id, id, true)
		if item != "":
			SaveService.add_item(item, 1)
		Overlay.toast("The iron is freezing; this boiler hasn't been fired in years. " + str({"almond_water": "Inside the firebox: a bottle of Almond Water.",
			"snacks": "Inside the firebox: a few packets of snacks."}.get(item, "Inside: cold ash, nothing else.")), 3.5))
	it.once = true


# ------------------------------------------------------------ fittings

static func shelf(k: GeoKit, a: Vector3, b: Vector3, nrm: Vector3, r: RandomNumberGenerator) -> void:
	var d := (b - a).normalized()
	var bas := Basis(d, Vector3.UP, d.cross(Vector3.UP))
	var len := a.distance_to(b)
	k.box_xf(Transform3D(bas, (a + b) * 0.5 + nrm * 0.13), Vector3(len, 0.035, 0.24), "l25_wood", GeoKit.ALL, false)
	var t := 0.6
	while t < len - 0.3:
		var c := a + d * t + nrm * 0.13
		k.box(c + Vector3.DOWN * 0.08, Vector3(0.04 + absf(nrm.x) * 0.16, 0.13, 0.04 + absf(nrm.z) * 0.16), "l25_metal", GeoKit.ALL, false)
		if r.randf() < 0.35:
			var s := Vector3(r.randf_range(0.18, 0.4), r.randf_range(0.12, 0.3), 0.18)
			k.box_xf(Transform3D(bas, c + Vector3.UP * (0.0175 + s.y * 0.5)), s, "l25_card", GeoKit.ALL, false)
		t += r.randf_range(0.9, 1.6)


static func stack(k: GeoKit, p: Vector3, r: RandomNumberGenerator) -> void:
	var y := 0.0
	for i in 1 + r.randi() % 3:
		var s := Vector3(r.randf_range(0.45, 0.7), r.randf_range(0.3, 0.5), r.randf_range(0.4, 0.6))
		k.box_xf(Transform3D(Basis(Vector3.UP, r.randf_range(-0.2, 0.2)), p + Vector3(r.randf_range(-0.05, 0.05), y + s.y * 0.5, 0)), s, "l25_card", GeoKit.ALL, i == 0)
		y += s.y


## Wall outlet; a faulty one carries a scorch mark and a spark light.
static func outlet(lvl, k: GeoKit, p: Vector3, nrm: Vector3, spark: bool) -> void:
	var a := nrm.abs()
	k.box(p, Vector3(0.09, 0.13, 0.09) * (Vector3.ONE - a) + a * 0.016, "l25_outlet", GeoKit.ALL, false)
	if not spark:
		return
	k.quad(p + nrm * 0.004 + Vector3.UP * 0.2, nrm, nrm.cross(Vector3.UP) * 0.08, Vector3.UP * 0.16, "l25_scorch")
	var l := OmniLight3D.new()
	l.light_color = Color(0.75, 0.85, 1.0)
	l.omni_range = 3.5
	l.light_energy = 0.0
	l.position = p + nrm * 0.25
	lvl.add_child(l)
	lvl.sparks.append({"p": p, "t": randf_range(2.0, 6.0), "l": l})


static func pipe(k: GeoKit, a: Vector3, b: Vector3, rad: float, mat: String) -> void:
	var ax := (b - a).normalized()
	var u := ax.cross(Vector3.UP if absf(ax.y) < 0.9 else Vector3.RIGHT).normalized()
	var v := ax.cross(u)
	var half := (b - a) * 0.5
	for i in 8:
		var an := TAU * (i + 0.5) / 8.0
		var nn := u * cos(an) + v * sin(an)
		k.quad((a + b) * 0.5 + nn * rad * 0.924, nn, half, nn.cross(ax) * rad * 0.383, mat)


## A missing polystyrene tile: dark plenum box with pipes above, puddle below.
static func hole(k: GeoKit, c: Vector3, sx: float, sz: float) -> void:
	k.quad(c + Vector3.UP * 0.75, Vector3.DOWN, Vector3(sx * 0.5, 0, 0), Vector3(0, 0, sz * 0.5), "l25_plenum")
	for s in [-1.0, 1.0]:
		k.quad(c + Vector3(s * sx * 0.5, 0.375, 0), Vector3(-s, 0, 0), Vector3(0, 0, sz * 0.5), Vector3(0, 0.375, 0), "l25_plenum")
		k.quad(c + Vector3(0, 0.375, s * sz * 0.5), Vector3(0, 0, -s), Vector3(sx * 0.5, 0, 0), Vector3(0, 0.375, 0), "l25_plenum")
	pipe(k, c + Vector3(-sx * 0.7, 0.5, 0.3), c + Vector3(sx * 0.7, 0.5, 0.3), 0.07, "l25_pipe")
	pipe(k, c + Vector3(0.4, 0.62, -sz * 0.7), c + Vector3(0.4, 0.62, sz * 0.7), 0.045, "l25_pipe")
	patch(k, Vector3(c.x + 0.2, 0.0, c.z - 0.1), 0.95, "l25_puddle")


## Irregular flat patch on the floor (puddle, scorch).
static func patch(k: GeoKit, c: Vector3, rad: float, mat: String) -> void:
	var pts := []
	for i in 12:
		var a := TAU * i / 12.0
		pts.append(c + Vector3(cos(a), 0, sin(a)) * rad * (0.62 + 0.38 * absf(sin(a * 2.3 + c.x * 1.7))) + Vector3.UP * 0.006)
	for i in 12:
		k._tri_fan(c + Vector3.UP * 0.006, pts[i], pts[(i + 1) % 12], Vector3.UP, mat)


static func dust_motes() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(7.0, 2.2, 7.0)
	pm.gravity = Vector3(0, -0.004, 0)
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.initial_velocity_min = 0.0
	pm.initial_velocity_max = 0.04
	p.process_material = pm
	var qm := QuadMesh.new()
	qm.size = Vector2(0.01, 0.01)
	var m := StandardMaterial3D.new()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.92, 0.86, 0.8, 0.55)
	qm.material = m
	p.draw_pass_1 = qm
	p.amount = 180
	p.lifetime = 10.0
	p.preprocess = 10.0
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-10, -4, -10), Vector3(20, 8, 20))
	return p


## Two-sided wall from a to b (thickness 0.3, extended 0.15 at both ends) with
## paint mp on the +normal side (normal = dir x up) and mn on the other.
static func wall2(k: GeoKit, a: Vector3, b: Vector3, h: float, mp: String, mn: String, ops: Array) -> void:
	var d := (b - a).normalized()
	var nz := d.cross(Vector3.UP)
	var o2 := []
	for o in ops:
		var od: Dictionary = o
		var c := od.duplicate()
		c["at"] = float(od["at"]) + 0.15
		o2.append(c)
	a -= d * 0.15
	b += d * 0.15
	if mp == mn:
		k.wall(a, b, h, 0.3, mp, o2, GeoKit.SIDES)
	else:
		k.wall(a + nz * 0.075, b + nz * 0.075, h, 0.15, mp, o2, GeoKit.SIDES)
		k.wall(a - nz * 0.075, b - nz * 0.075, h, 0.15, mn, o2, GeoKit.SIDES)
