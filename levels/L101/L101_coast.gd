extends RefCounted
## Level 101 coastal suburb: one street along X with houses both sides, the
## home lot at x = 0, dunes and a beach behind the south-side gardens and the
## sea beyond. Streamed along X in 48 m chunks (two 24 m lots per side).
## South (+Z) is the sea. Street z -14..-6, home front at z = 0.

const CHUNK := 48.0
const LOT := 24.0
const ST0 := -14.0
const ST1 := -6.0
const DUNE0 := 15.0
const BEACH0 := 44.0
const SHORE := 88.0
const ZMIN := -64.0
const ZMAX := 232.0
const SIDINGS := [Color(0.93, 0.92, 0.88), Color(0.74, 0.82, 0.86), Color(0.8, 0.84, 0.74), Color(0.92, 0.86, 0.72),
	Color(0.86, 0.78, 0.72), Color(0.66, 0.7, 0.74)]

var lvl
var n_dune := FastNoiseLite.new()
var n_shore := FastNoiseLite.new()
var tuft: ArrayMesh
var crown: ArrayMesh
var gable_st: Dictionary = {}


func _init(level) -> void:
	lvl = level
	n_dune.seed = 1011
	n_dune.frequency = 0.03
	n_dune.fractal_octaves = 3
	n_shore.seed = 1012
	n_shore.frequency = 0.008
	tuft = _tuft()
	crown = _blob()


# ---------------------------------------------------------------- land

func shore_z(x: float) -> float:
	return SHORE + 5.0 * n_shore.get_noise_1d(x)


## Path through the dune behind the home: the dune is cut down to a saddle.
func path_w(x: float, z: float) -> float:
	if z < DUNE0 - 2.0 or z > BEACH0 + 6.0:
		return 0.0
	return 1.0 - smoothstep(1.4, 5.0, absf(x - 0.6))


func h(x: float, z: float) -> float:
	if z < DUNE0:
		return 0.0
	var sz := shore_z(x)
	var y: float
	if z < BEACH0:
		var t := (z - DUNE0) / (BEACH0 - DUNE0)
		var crest := 3.4 + 1.8 * n_dune.get_noise_2d(x * 0.6, 3.0)
		y = crest * sin(PI * minf(t * 1.15, 1.0)) * smoothstep(0.0, 0.25, t)
		y = maxf(y, lerpf(0.0, 1.9, smoothstep(0.55, 1.0, t)))
		y += 0.7 * n_dune.get_noise_2d(x * 1.7, z * 1.7) * sin(PI * t)
		var pw := path_w(x, z)
		if pw > 0.0:
			y = lerpf(y, lerpf(0.05, 1.9, smoothstep(0.1, 0.95, t)) + 0.35 * sin(PI * t), pw)
	elif z < sz:
		y = lerpf(1.9, 0.0, (z - BEACH0) / (sz - BEACH0))
		y += 0.12 * n_dune.get_noise_2d(x * 2.0, z * 2.0) * (1.0 - smoothstep(sz - 12.0, sz, z))
	else:
		y = -1.6 * (1.0 - exp(-(z - sz) / 14.0)) - 0.03 * (z - sz)
		y = maxf(y, -7.5)
	return y


# ---------------------------------------------------------------- materials

static func photo(name: String, asset: String, tint: Color, repeat_m: float, rough: float = -1.0) -> Material:
	var base := "res://assets/external/%s/%s_%%s_1k.jpg" % [asset, asset]
	if not ResourceLoader.exists(base % "diff"):
		return MatLib.define(name, {"albedo_a": tint, "albedo_b": tint.darkened(0.08)}, "plaster")
	var m := ORMMaterial3D.new()
	m.albedo_texture = load(base % "diff")
	m.albedo_color = tint
	if ResourceLoader.exists(base % "nor_gl"):
		m.normal_enabled = true
		m.normal_texture = load(base % "nor_gl")
	if ResourceLoader.exists(base % "arm"):
		m.orm_texture = load(base % "arm")
	if rough >= 0.0:
		m.orm_texture = null
		m.roughness = rough
	m.uv1_scale = Vector3(1.0 / repeat_m, 1.0 / repeat_m, 1.0)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return MatLib.register(name, m)


static func define_materials() -> void:
	for i in SIDINGS.size():
		photo("l101_sid%d" % i, "painted_plaster_wall", SIDINGS[i], 2.2)
	photo("l101_asphalt", "asphalt_02", Color(0.78, 0.78, 0.8), 4.0)
	photo("l101_walk", "concrete", Color(0.92, 0.91, 0.88), 2.5)
	photo("l101_brick", "brick_4", Color(0.85, 0.8, 0.78), 2.0)
	photo("l101_wood", "old_wood_floor", Color(1.0, 0.95, 0.88), 2.2)
	photo("l101_deck", "old_wood_floor", Color(0.72, 0.66, 0.58), 1.8)
	photo("l101_paint", "painted_plaster_wall", Color(1.0, 0.97, 0.9), 2.5)
	photo("l101_paint2", "painted_plaster_wall", Color(0.96, 0.9, 0.82), 2.5)
	MatLib.define("l101_roof0", {"albedo_a": Color(0.25, 0.25, 0.27), "albedo_b": Color(0.2, 0.2, 0.22), "pattern": 14,
		"pattern_scale": Vector2(0.34, 0.2), "grout_width": 0.012, "grout_color": Color(0.1, 0.1, 0.11), "roughness_a": 0.85,
		"roughness_b": 0.95, "noise_scale": 2.5, "bump_strength": 0.8}, "concrete")
	MatLib.define("l101_roof1", {"albedo_a": Color(0.36, 0.22, 0.18), "albedo_b": Color(0.3, 0.18, 0.15), "pattern": 14,
		"pattern_scale": Vector2(0.34, 0.2), "grout_width": 0.012, "grout_color": Color(0.14, 0.09, 0.08), "roughness_a": 0.85,
		"roughness_b": 0.95, "noise_scale": 2.5, "bump_strength": 0.8}, "concrete")
	MatLib.define("l101_roof2", {"albedo_a": Color(0.3, 0.33, 0.36), "albedo_b": Color(0.25, 0.28, 0.3), "pattern": 14,
		"pattern_scale": Vector2(0.34, 0.2), "grout_width": 0.012, "grout_color": Color(0.12, 0.13, 0.14), "roughness_a": 0.85,
		"roughness_b": 0.95, "noise_scale": 2.5, "bump_strength": 0.8}, "concrete")
	MatLib.define("l101_trim", {"albedo_a": Color(0.95, 0.95, 0.93), "albedo_b": Color(0.92, 0.92, 0.9), "roughness_a": 0.5,
		"roughness_b": 0.6, "noise_scale": 0.6}, "trim_white")
	MatLib.define("l101_door", {"albedo_a": Color(0.3, 0.36, 0.42), "albedo_b": Color(0.27, 0.33, 0.39), "roughness_a": 0.5,
		"roughness_b": 0.6}, "trim_white")
	MatLib.define("l101_tile", {"albedo_a": Color(0.86, 0.87, 0.86), "albedo_b": Color(0.8, 0.81, 0.8)}, "pool_tile")
	MatLib.define("l101_hedge", {"albedo_a": Color(0.13, 0.2, 0.08), "albedo_b": Color(0.09, 0.15, 0.06), "noise_scale": 5.0,
		"bump_strength": 2.0, "roughness_a": 0.95, "roughness_b": 1.0}, "grass")
	MatLib.define("l101_pole", {"albedo_a": Color(0.3, 0.24, 0.18), "albedo_b": Color(0.24, 0.19, 0.14), "pattern": 2,
		"pattern_scale": Vector2(0.05, 1.0), "roughness_a": 0.9, "roughness_b": 1.0, "noise_scale": 3.0}, "wood_floor")
	MatLib.define("l101_wire", {"albedo_a": Color(0.06, 0.06, 0.06), "albedo_b": Color(0.05, 0.05, 0.05)}, "concrete_dark")
	for i in 3:
		var pm := StandardMaterial3D.new()
		pm.albedo_color = [Color(0.45, 0.58, 0.66), Color(0.7, 0.62, 0.45), Color(0.5, 0.6, 0.42)][i]
		pm.roughness = 0.3
		MatLib.register("l101_pic%d" % i, pm)
	var dr := StandardMaterial3D.new()
	dr.albedo_color = Color(0.62, 0.66, 0.7)
	dr.roughness = 0.95
	MatLib.register("l101_drape", dr)
	var wk := StandardMaterial3D.new()
	wk.albedo_color = Color(0.22, 0.2, 0.1)
	wk.roughness = 0.6
	MatLib.register("l101_wrack", wk)
	MatLib.define("l101_stripe", {"albedo_a": Color(0.9, 0.88, 0.8), "albedo_b": Color(0.85, 0.83, 0.75)}, "trim_white")
	var g := StandardMaterial3D.new()
	g.albedo_color = Color(0.1, 0.12, 0.14)
	g.metallic = 0.6
	g.roughness = 0.08
	MatLib.register("l101_winglass", g)
	var cl := StandardMaterial3D.new()
	cl.albedo_color = Color(0.85, 0.82, 0.74)
	cl.roughness = 0.9
	MatLib.register("l101_curtain", cl)
	var gl := StandardMaterial3D.new()
	gl.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gl.albedo_color = Color(0.75, 0.85, 0.9, 0.12)
	gl.roughness = 0.04
	gl.metallic_specular = 0.9
	MatLib.register("l101_clear", gl)
	MatLib.register("l101_sea", MatLib.water({"shallow_color": Color(0.36, 0.5, 0.5), "deep_color": Color(0.08, 0.2, 0.26),
		"absorption": 0.25, "clarity": 0.75, "wave_height": 0.16, "wave_scale": 0.12, "wave_speed": 0.55,
		"normal_strength": 0.5, "foam_amount": 0.75, "foam_width": 0.6, "roughness_value": 0.05}))
	var sh := Shader.new()
	sh.code = TERRAIN
	var tm := ShaderMaterial.new()
	tm.shader = sh
	var sa := "res://assets/external/coast_sand_01/coast_sand_01_%s_1k.jpg"
	var ga := "res://assets/external/sparse_grass/sparse_grass_%s_1k.jpg"
	if ResourceLoader.exists(sa % "diff"):
		tm.set_shader_parameter("sand_alb", load(sa % "diff"))
		tm.set_shader_parameter("sand_nrm", load(sa % "nor_gl"))
	if ResourceLoader.exists(ga % "diff"):
		tm.set_shader_parameter("grass_alb", load(ga % "diff"))
	MatLib.register("l101_ground", tm)
	var vs := Shader.new()
	vs.code = VEG
	var vm := ShaderMaterial.new()
	vm.shader = vs
	MatLib.register("l101_veg", vm)
	var cs := Shader.new()
	cs.code = CROWN
	var cm := ShaderMaterial.new()
	cm.shader = cs
	MatLib.register("l101_crown", cm)


const TERRAIN := """
shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D sand_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float water_y = 0.0;
varying vec3 wp;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 uv = wp.xz / 3.0;
	float macro = vn(wp.xz * 0.04) * 0.6 + vn(wp.xz * 0.17) * 0.4;
	vec3 sand = texture(sand_alb, uv).rgb * vec3(0.98, 0.94, 0.86) * (0.85 + 0.25 * macro);
	float a = vn(wp.xz * 0.08);
	vec3 g = mix(vec3(0.2, 0.28, 0.1), vec3(0.3, 0.36, 0.15), a);
	g *= 0.6 + 0.8 * dot(texture(grass_alb, wp.xz / 2.5).rgb, vec3(0.33));
	vec3 dune = mix(sand, mix(sand, g * 1.1, 0.55), smoothstep(0.45, 0.7, vn(wp.xz * 0.35)));
	vec3 c = mix(sand, dune, COLOR.g);
	c = mix(c, g, COLOR.r);
	float wet = (1.0 - smoothstep(water_y + 0.05, water_y + 0.7, wp.y)) * (1.0 - COLOR.r);
	c *= mix(1.0, 0.62, wet);
	ALBEDO = c;
	ROUGHNESS = mix(0.95, 0.3, wet);
	NORMAL_MAP = mix(texture(sand_nrm, uv).rgb, vec3(0.5, 0.5, 1.0), COLOR.r);
	NORMAL_MAP_DEPTH = 0.8;
}
"""

const VEG := """
shader_type spatial;
render_mode diffuse_burley, cull_disabled;
uniform float gust = 0.5;
varying float hgt;
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	hgt = VERTEX.y;
	float ph = dot(w.xz, vec2(0.6, 0.8)) * 0.2 - TIME * 2.4;
	float sway = (0.5 + 0.5 * sin(ph)) * (0.25 + gust) + 0.08 * sin(TIME * 4.1 + w.x * 1.7);
	VERTEX.xz += vec2(-0.6, -0.8) * sway * VERTEX.y * VERTEX.y * 0.35;
}
void fragment() {
	ALBEDO = COLOR.rgb * (0.6 + 0.4 * clamp(hgt * 1.5, 0.0, 1.0));
	ROUGHNESS = 0.9;
	BACKLIGHT = COLOR.rgb * 0.4;
}
"""

const CROWN := """
shader_type spatial;
render_mode diffuse_burley;
float hsh(vec3 p) { p = fract(p * 0.3183 + 0.1); p *= 17.0; return fract(p.x * p.y * p.z * (p.x + p.y + p.z)); }
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float n = hsh(floor(wp * 2.6));
	ALBEDO = mix(vec3(0.08, 0.13, 0.05), vec3(0.2, 0.27, 0.1), n) * (0.75 + 0.35 * COLOR.r);
	ROUGHNESS = 0.95;
}
"""


# ---------------------------------------------------------------- one chunk

## Builds street, sidewalks, houses (not the home lot), yards, the dune and
## beach terrain, dune grass and beach litter for x in [ox, ox + 48).
## Returns {"lamps": [Node3D], ...}.
func chunk(node: Node3D, cx: int, seed_v: int) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	var ox := cx * CHUNK
	var k := GeoKit.new(node, "Street")
	gable_st = {}
	# street, curbs, sidewalks, lawn strips
	k.box_mm(Vector3(ox, -0.2, ST0), Vector3(ox + CHUNK, 0.02, ST1), "l101_asphalt")
	for i in 4:
		var x := ox + 6.0 + 12.0 * i
		k.box(Vector3(x, 0.025, (ST0 + ST1) * 0.5), Vector3(3.0, 0.01, 0.14), "l101_stripe", GeoKit.PY, false)
	for side in [[ST0 - 2.2, ST0], [ST1, ST1 + 2.2]]:
		k.box_mm(Vector3(ox, -0.2, side[0]), Vector3(ox + CHUNK, 0.15, side[1]), "l101_walk")
	k.box_mm(Vector3(ox, -0.3, ZMIN), Vector3(ox + CHUNK, 0.0, ST0 - 2.2), "l101_ground", GeoKit.PY)
	k.box_mm(Vector3(ox, -0.3, ST1 + 2.2), Vector3(ox + CHUNK, 0.0, DUNE0 - 3.0), "l101_ground", GeoKit.PY)
	var lamps: Array = []
	for i in 2:
		var lx := ox + 10.0 + LOT * i
		var lp := Props.place(lvl, node, "ph/street_lamp_01", Vector3(lx, 0.15, ST1 + 1.6), 180.0, 0.0, true)
		if lp:
			lamps.append(lp)
		var px := ox + 4.0 + LOT * i
		# a timber utility pole with a crossarm, wires running on to the next one
		k.cylinder(Vector3(px, 4.5, ST0 - 1.2), 0.14, 9.0, "l101_pole", 8, true)
		k.box(Vector3(px, 8.4, ST0 - 1.2), Vector3(0.12, 0.12, 1.8), "l101_pole", GeoKit.ALL, false)
		for wz in [-0.75, 0.0, 0.75]:
			k.box(Vector3(px + LOT * 0.5, 8.5, ST0 - 1.2 + wz), Vector3(LOT, 0.02, 0.02), "l101_wire", GeoKit.ALL, false)
	if r.randf() < 0.5:
		Props.place(lvl, node, "ph/fire_hydrant", Vector3(ox + r.randf_range(4.0, 44.0), 0.15, ST1 + 0.6), r.randf_range(0, 360), 0.0, true)
	# north side: two houses facing the street, closed off behind by a tall fence
	for i in 2:
		var hx := ox + 12.0 + LOT * i
		_house(k, node, r, hx, ST0 - 7.0, 1.0)
		k.box(Vector3(hx + LOT * 0.5 - 0.05, 0.6, -32.0), Vector3(0.06, 1.2, 22.0), "l101_deck", GeoKit.ALL, true)
	k.box(Vector3(ox + CHUNK * 0.5, 1.0, -44.0), Vector3(CHUNK, 2.0, 0.12), "l101_deck")
	k.box(Vector3(ox + CHUNK * 0.5, 2.6, -47.0), Vector3(CHUNK, 5.2, 2.6), "l101_hedge")
	# south side: houses with gardens running down to the dune (home lot excluded)
	for i in 2:
		var hx := ox + LOT * i
		if absf(hx) < 1.0:
			continue
		_house(k, node, r, hx, 0.0, -1.0)
		_garden(k, node, r, hx)
	# far rooftops of the next street inland (no collision)
	for i in 4:
		var fx := ox + 6.0 + 12.0 * i + r.randf_range(-2.0, 2.0)
		var fh := r.randf_range(5.0, 7.5)
		k.box(Vector3(fx, fh * 0.5, -60.0 + r.randf_range(-3.0, 3.0)), Vector3(r.randf_range(8.0, 10.0), fh, 9.0), "l101_sid%d" % r.randi_range(0, 5), GeoKit.ALL, false)
	k.commit()
	_commit_gables(node)
	_terrain(node, ox)
	_dune_life(node, ox, r)
	return {"lamps": lamps}


## A closed neighbour's house. dir = -1: facade at zf faces the street (-Z),
## body runs south; dir = +1: facade at zf faces the street (+Z), body north.
func _house(k: GeoKit, node: Node3D, r: RandomNumberGenerator, cx: float, zf: float, dir: float) -> void:
	var w := r.randf_range(9.0, 11.5)
	var d := r.randf_range(8.5, 10.0)
	var two := r.randf() < 0.6
	var hh := 5.9 if two else 3.1
	var f0 := 0.45
	var mat := "l101_sid%d" % r.randi_range(0, 5)
	var zb := zf - dir * d          # back wall
	var z0 := minf(zf, zb)
	var z1 := maxf(zf, zb)
	k.box_mm(Vector3(cx - w * 0.5 - 0.06, 0.0, z0 - 0.06), Vector3(cx + w * 0.5 + 0.06, f0, z1 + 0.06), "l101_brick")
	k.box_mm(Vector3(cx - w * 0.5, f0, z0), Vector3(cx + w * 0.5, f0 + hh, z1), mat)
	# windows on the facade and the sides
	var storeys := 2 if two else 1
	for s in storeys:
		var wy := f0 + 1.0 + s * 2.8
		for j in 3:
			var wx := cx - w * 0.5 + w * (j + 0.5) / 3.0
			if s == 0 and j == 1:
				continue
			_window(k, Vector3(wx, wy + 0.7, zf + dir * 0.04), dir, 1.15, 1.4)
		for sx in [-1.0, 1.0]:
			_window_x(k, Vector3(cx + sx * (w * 0.5 + 0.04), wy + 0.7, (z0 + z1) * 0.5), sx, 1.0, 1.3)
	# front door, frame, porch slab and steps
	var dz := zf + dir * 0.05
	k.box(Vector3(cx, f0 + 1.05, dz), Vector3(1.0, 2.1, 0.06), "l101_door", GeoKit.ALL, false)
	k.box(Vector3(cx, f0 + 2.18, dz + dir * 0.02), Vector3(1.3, 0.12, 0.08), "l101_trim", GeoKit.ALL, false)
	k.box_mm(Vector3(cx - 1.6, 0.0, minf(zf, zf + dir * 1.8)), Vector3(cx + 1.6, f0, maxf(zf, zf + dir * 1.8)), "l101_walk")
	k.box_mm(Vector3(cx - 1.0, 0.0, minf(zf + dir * 1.8, zf + dir * 2.3)), Vector3(cx + 1.0, f0 * 0.5, maxf(zf + dir * 1.8, zf + dir * 2.3)), "l101_walk")
	# path to the sidewalk
	var sw := ST1 + 2.2 if dir < 0.0 else ST0 - 2.2
	k.box_mm(Vector3(cx - 0.6, 0.0, minf(zf + dir * 2.3, sw)), Vector3(cx + 0.6, 0.06, maxf(zf + dir * 2.3, sw)), "l101_walk", GeoKit.PY, false)
	_roof(k, cx, (z0 + z1) * 0.5, w, d, f0 + hh, "l101_roof%d" % r.randi_range(0, 2), mat)
	if r.randf() < 0.5:
		k.box(Vector3(cx + w * 0.3, f0 + hh + 2.4, (z0 + z1) * 0.5 + 1.2), Vector3(0.7, 2.6, 0.7), "l101_brick", GeoKit.ALL, false)
	# a covered car on the drive, bins, a mailbox
	var side := 1.0 if r.randf() < 0.5 else -1.0
	var drive_x := cx + side * (w * 0.5 + 1.9)
	k.box_mm(Vector3(drive_x - 1.5, 0.0, minf(zf, sw)), Vector3(drive_x + 1.5, 0.05, maxf(zf, sw)), "l101_walk", GeoKit.PY, false)
	if r.randf() < 0.55:
		Props.place(lvl, node, "ph/covered_car", Vector3(drive_x, 0.05, zf + dir * 3.6), 0.0, 0.0, true)
	Props.place(lvl, node, "kenney/furniture-kit/trashcan", Vector3(drive_x + side * 1.1, 0.05, sw - dir * 0.8), r.randf_range(0, 40), 0.95, true)
	k.box(Vector3(cx - side * 2.2, 0.55, sw - dir * 0.4), Vector3(0.08, 1.1, 0.08), "l101_trim")
	k.box(Vector3(cx - side * 2.2, 1.18, sw - dir * 0.4), Vector3(0.22, 0.2, 0.42), "l101_door", GeoKit.ALL, false)


func _window(k: GeoKit, c: Vector3, dir: float, w: float, hh: float) -> void:
	k.box(c, Vector3(w, hh, 0.04), "l101_winglass", GeoKit.ALL, false)
	k.box(c + Vector3(0, 0, dir * 0.01), Vector3(w * 0.42, hh * 0.92, 0.03), "l101_curtain", GeoKit.ALL, false)
	k.box(c + Vector3(0, 0, dir * 0.03), Vector3(0.05, hh, 0.04), "l101_trim", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		k.box(c + Vector3(s * w * 0.5, 0, dir * 0.03), Vector3(0.09, hh + 0.12, 0.06), "l101_trim", GeoKit.ALL, false)
		k.box(c + Vector3(0, s * hh * 0.5, dir * 0.03), Vector3(w + 0.12, 0.09, 0.06), "l101_trim", GeoKit.ALL, false)
	k.box(c + Vector3(0, -hh * 0.5 - 0.06, dir * 0.08), Vector3(w + 0.3, 0.06, 0.16), "l101_trim", GeoKit.ALL, false)


func _window_x(k: GeoKit, c: Vector3, sx: float, w: float, hh: float) -> void:
	k.box(c, Vector3(0.04, hh, w), "l101_winglass", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		k.box(c + Vector3(sx * 0.03, 0, s * w * 0.5), Vector3(0.06, hh + 0.12, 0.09), "l101_trim", GeoKit.ALL, false)
		k.box(c + Vector3(sx * 0.03, s * hh * 0.5, 0), Vector3(0.06, 0.09, w + 0.12), "l101_trim", GeoKit.ALL, false)


## Gable roof running along X; the gable triangles go into a per-material mesh.
func _roof(k: GeoKit, cx: float, zm: float, w: float, d: float, eave: float, roof_mat: String, wall_mat: String) -> void:
	var pitch := deg_to_rad(32.0)
	var rise := d * 0.5 * tan(pitch)
	var over := 0.45
	var half := d * 0.5 + over
	var slope_len := half / cos(pitch)
	for s in [-1.0, 1.0]:
		var b := Basis(Vector3.RIGHT, s * pitch)
		var mid := Vector3(cx, eave + rise - (half * tan(pitch)) * 0.5 + 0.08 + 0.45, zm + s * half * 0.5)
		k.box_xf(Transform3D(b, mid), Vector3(w + over * 2.0, 0.16, slope_len), roof_mat, GeoKit.ALL, false)
	if not gable_st.has(wall_mat):
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		gable_st[wall_mat] = st
	var stt: SurfaceTool = gable_st[wall_mat]
	for sx in [-1.0, 1.0]:
		var x: float = cx + sx * w * 0.5
		var n := Vector3(sx, 0, 0)
		var a := Vector3(x, eave, zm - d * 0.5)
		var b2 := Vector3(x, eave, zm + d * 0.5)
		var c := Vector3(x, eave + rise + 0.45, zm)
		for v in ([a, c, b2] if sx > 0.0 else [a, b2, c]):
			stt.set_normal(n)
			stt.set_uv(Vector2(v.z, v.y) / 2.2)
			stt.add_vertex(v)


func _commit_gables(node: Node3D) -> void:
	for m in gable_st.keys():
		var mi := MeshInstance3D.new()
		mi.mesh = (gable_st[m] as SurfaceTool).commit()
		mi.material_override = MatLib.get_mat(m)
		node.add_child(mi)
	gable_st = {}


## Back garden: lawn, a low fence along the dune with a gap, a tree or two.
func _garden(k: GeoKit, node: Node3D, r: RandomNumberGenerator, cx: float) -> void:
	k.box(Vector3(cx + LOT * 0.5 - 0.05, 0.55, 8.5), Vector3(0.06, 1.1, 13.0), "l101_deck", GeoKit.ALL, true)
	for s in [-1.0, 1.0]:
		k.box(Vector3(cx + s * 7.0, 0.5, DUNE0 - 0.6), Vector3(10.0, 1.0, 0.08), "l101_deck")
	if r.randf() < 0.7:
		var tx := cx + r.randf_range(-8.0, 8.0)
		_tree(node, Vector3(tx, 0.0, r.randf_range(10.5, 13.0)), r)


func _tree(node: Node3D, p: Vector3, r: RandomNumberGenerator) -> void:
	var k := GeoKit.new(node, "Tree")
	k.cylinder(p + Vector3(0, 1.6, 0), 0.16, 3.2, "l101_deck", 7, true)
	k.commit()
	for i in 4:
		var mi := MeshInstance3D.new()
		mi.mesh = crown
		mi.material_override = MatLib.get_mat("l101_crown")
		var s := r.randf_range(1.2, 1.9)
		mi.scale = Vector3(s, s * 0.85, s)
		mi.position = p + Vector3(r.randf_range(-1.0, 1.0), 3.6 + r.randf_range(0.0, 1.2), r.randf_range(-1.0, 1.0))
		node.add_child(mi)


# ---------------------------------------------------------------- terrain

func _terrain(node: Node3D, ox: float) -> void:
	var z0 := DUNE0 - 3.0
	var nx := int(CHUNK / 2.0) + 1
	var nz := int((ZMAX - z0) / 2.0) + 1
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hs := PackedFloat32Array()
	hs.resize(nx * nz)
	for j in nz:
		for i in nx:
			hs[j * nx + i] = h(ox + i * 2.0, z0 + j * 2.0)
	for j in nz:
		for i in nx:
			var x := ox + i * 2.0
			var z := z0 + j * 2.0
			var hl := hs[j * nx + maxi(i - 1, 0)]
			var hr := hs[j * nx + mini(i + 1, nx - 1)]
			var hu := hs[maxi(j - 1, 0) * nx + i]
			var hd := hs[mini(j + 1, nz - 1) * nx + i]
			st.set_normal(Vector3(hl - hr, 4.0, hu - hd).normalized())
			var lawn := 1.0 - smoothstep(DUNE0 - 1.0, DUNE0 + 1.5, z)
			var dune := smoothstep(DUNE0, DUNE0 + 4.0, z) * (1.0 - smoothstep(BEACH0 - 3.0, BEACH0 + 3.0, z)) * (1.0 - path_w(x, z))
			st.set_color(Color(lawn, dune, 0, 1))
			st.add_vertex(Vector3(x, hs[j * nx + i], z))
	for j in nz - 1:
		for i in nx - 1:
			var a := j * nx + i
			st.add_index(a)
			st.add_index(a + 1)
			st.add_index(a + nx)
			st.add_index(a + 1)
			st.add_index(a + nx + 1)
			st.add_index(a + nx)
	var mi := MeshInstance3D.new()
	mi.name = "Coast"
	mi.mesh = st.commit()
	mi.material_override = MatLib.get_mat("l101_ground")
	node.add_child(mi)
	# 1 m collision over the garden edge, dune and beach
	var w := int(CHUNK) + 1
	var d := int(ZMAX - z0) + 1
	var md := PackedFloat32Array()
	md.resize(w * d)
	for j in d:
		for i in w:
			md[j * w + i] = h(ox + i, z0 + j)
	var body := StaticBody3D.new()
	body.name = "Ground"
	node.add_child(body)
	var sh := HeightMapShape3D.new()
	sh.map_width = w
	sh.map_depth = d
	sh.map_data = md
	var cs := CollisionShape3D.new()
	cs.shape = sh
	cs.position = Vector3(ox + (w - 1) * 0.5, 0.0, z0 + (d - 1) * 0.5)
	cs.set_meta("surface", "sand")
	body.add_child(cs)
	# flat garden/street level collision north of the dune
	var gb := StaticBody3D.new()
	node.add_child(gb)
	var bs := BoxShape3D.new()
	bs.size = Vector3(CHUNK, 0.4, DUNE0 - 2.0 - ZMIN)
	var bc := CollisionShape3D.new()
	bc.shape = bs
	bc.position = Vector3(ox + CHUNK * 0.5, -0.2, (ZMIN + DUNE0 - 2.0) * 0.5)
	bc.set_meta("surface", "grass")
	gb.add_child(bc)


## Marram grass on the dune, lawn tufts in the gardens, driftwood and
## wrack on the beach.
func _dune_life(node: Node3D, ox: float, r: RandomNumberGenerator) -> void:
	var buf := PackedFloat32Array()
	for i in 2600:
		var x := ox + r.randf() * CHUNK
		var z := r.randf_range(DUNE0 - 1.0, BEACH0 + 4.0)
		if path_w(x, z) > 0.2:
			continue
		if n_dune.get_noise_2d(x * 2.0, z * 2.0) < -0.15:
			continue
		var s := r.randf_range(0.7, 1.4)
		var yaw := r.randf() * TAU
		buf.append_array([cos(yaw) * s, 0, sin(yaw) * s, x, 0, s, 0, h(x, z) - 0.03, -sin(yaw) * s, 0, cos(yaw) * s, z])
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = tuft
	mm.instance_count = buf.size() / 12
	mm.buffer = buf
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = MatLib.get_mat("l101_veg")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = 110.0
	node.add_child(mi)
	var wr := PackedFloat32Array()
	for i in 220:
		var x := ox + r.randf() * CHUNK
		var z := shore_z(x) - 4.5 - 2.5 * n_shore.get_noise_1d(x * 6.0) + r.randf_range(-0.8, 0.8)
		var s := r.randf_range(0.08, 0.22)
		var yaw := r.randf() * TAU
		wr.append_array([cos(yaw) * s * 1.8, 0, sin(yaw) * s * 1.8, x, 0, s * 0.18, 0, h(x, z) - 0.01, -sin(yaw) * s, 0, cos(yaw) * s, z])
	var wm := MultiMesh.new()
	wm.transform_format = MultiMesh.TRANSFORM_3D
	wm.mesh = crown
	wm.instance_count = wr.size() / 12
	wm.buffer = wr
	var wi := MultiMeshInstance3D.new()
	wi.multimesh = wm
	wi.material_override = MatLib.get_mat("l101_wrack")
	wi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	wi.visibility_range_end = 90.0
	node.add_child(wi)
	for i in 4:
		var x := ox + r.randf_range(2.0, CHUNK - 2.0)
		var z := shore_z(x) - r.randf_range(6.0, 22.0)
		var dw := Props.place(lvl, node, "ph/dead_tree_trunk", Vector3(x, h(x, z) - 0.06, z), r.randf_range(0, 360), 0.0, false)
		if dw:
			dw.scale *= r.randf_range(0.6, 1.2)


# ---------------------------------------------------------------- meshes

func _tuft() -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = 1015
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for s in 26:
		var a := r.randf() * TAU
		var base := Vector3(cos(a), 0, sin(a)) * sqrt(r.randf()) * 0.2
		var top := base + Vector3(cos(a), 0, sin(a)) * r.randf_range(0.15, 0.4) + Vector3(0, r.randf_range(0.5, 1.0), 0)
		var side := Vector3(cos(a + 1.57), 0, sin(a + 1.57))
		var col := Color(0.36, 0.4, 0.2).lerp(Color(0.62, 0.58, 0.38), r.randf()) * r.randf_range(0.85, 1.1)
		var nrm := side.cross(top - base).normalized()
		for v in [[base - side * 0.016, 0.8], [base + side * 0.016, 0.8], [top, 1.0]]:
			st.set_normal(nrm)
			st.set_color(col * float(v[1]))
			st.add_vertex(v[0])
	return st.commit()


func _blob() -> ArrayMesh:
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 12
	sm.rings = 7
	var arr := sm.get_mesh_arrays()
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nz := FastNoiseLite.new()
	nz.seed = 1016
	nz.frequency = 1.4
	var cols := PackedColorArray()
	cols.resize(vs.size())
	for i in vs.size():
		var p := vs[i]
		vs[i] = p * (0.85 + 0.3 * nz.get_noise_3dv(p))
		cols[i] = Color(clampf(0.5 + p.y * 0.5, 0.0, 1.0), 0, 0)
	arr[Mesh.ARRAY_VERTEX] = vs
	arr[Mesh.ARRAY_COLOR] = cols
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return am
