extends RefCounted
## Level 601 "The End": the fake realities. Two personalised sub-areas sit side
## by side in every period cell and bleed into each other and into the stacks:
## a family home at dusk (its floorboards and walls fray into the library) whose
## open back door gives onto a field under a painted evening sky, where the six
## Junkies keep their outpost beside a dead vending machine (the vending machine
## in a field comes from the page's "corrupted" image credit; ADAPTATION).
## Coordinates are chunk-local (u, v) in 0..24.

const L := preload("res://levels/L601/L601_lib.gd")
const CS := 24.0
const SKY_H := 14.0
const HOME := Rect2(6.0, 6.6, 13.0, 11.4)
const DOOR := Vector3(12.0, 0.0, 18.0)
const GATE := Vector3(15.3, 0.0, 21.0)
const CAMP := Vector3(7.0, 0.0, 15.5)
const VEND := Vector3(13.0, 0.0, 9.0)

const SKY_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled, fog_disabled;
uniform vec3 horizon : source_color = vec3(1.0, 0.70, 0.46);
uniform vec3 high : source_color = vec3(0.30, 0.42, 0.70);
uniform vec3 band : source_color = vec3(0.98, 0.50, 0.34);
varying vec3 wp;
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec3 d = normalize(wp - CAMERA_POSITION_WORLD);
	float e = clamp(d.y, -0.2, 1.0);
	vec3 c = mix(band, horizon, smoothstep(-0.02, 0.14, e));
	c = mix(c, high, smoothstep(0.14, 0.8, e));
	float ang = atan(d.x, d.z);
	float hill = 0.012 + 0.012 * sin(ang * 5.0 + 1.0) + 0.006 * sin(ang * 13.0 + 2.0) + 0.003 * sin(ang * 41.0);
	vec3 land = mix(vec3(0.12, 0.11, 0.07), vec3(0.22, 0.20, 0.12), smoothstep(-0.2, 0.0, e));
	c = mix(c, land, 1.0 - smoothstep(hill - 0.002, hill + 0.002, e));
	vec2 sp = d.xz / max(d.y, 0.06) * 3.0;
	float s = sin(sp.x * 0.9 + sp.y * 0.3) * sin(sp.y * 0.55 - sp.x * 0.2 + 1.3);
	c = mix(c, vec3(1.0, 0.84, 0.76), smoothstep(0.55, 0.95, s) * smoothstep(0.06, 0.35, e) * 0.3);
	ALBEDO = c;
}
"""

var lib: L
var lvl: Node3D


func _init(library: L) -> void:
	lib = library
	lvl = library.lvl


static func materials() -> void:
	MatLib.define("l601_home_wood", {"pattern_scale": Vector2(1.4, 0.14), "albedo_a": Color(0.50, 0.33, 0.19),
		"albedo_b": Color(0.42, 0.27, 0.15), "roughness_a": 0.4, "roughness_b": 0.6}, "wood_floor")
	MatLib.define("l601_home_wall", {"albedo_a": Color(0.80, 0.70, 0.56), "albedo_b": Color(0.74, 0.64, 0.50),
		"pattern": 10, "pattern_scale": Vector2(0.26, 0.34), "pattern_color": Color(0.70, 0.58, 0.44),
		"pattern_strength": 0.45, "grime_height": 0.18, "grime_color": Color(0.5, 0.42, 0.32), "noise_scale": 0.8})
	MatLib.define("l601_home_siding", {"albedo_a": Color(0.62, 0.66, 0.66), "albedo_b": Color(0.56, 0.60, 0.60),
		"pattern": 2, "pattern_scale": Vector2(0.18, 1.0), "pattern_color": Color(0.42, 0.46, 0.46),
		"pattern_strength": 0.5, "uv_rotate": 1.5708})
	MatLib.define("l601_home_ceiling", {"albedo_a": Color(0.86, 0.80, 0.70), "albedo_b": Color(0.82, 0.76, 0.66)}, "plaster")
	MatLib.define("l601_rug", {"albedo_a": Color(0.42, 0.16, 0.12), "albedo_b": Color(0.34, 0.12, 0.10),
		"pattern": 6, "pattern_scale": Vector2(0.4, 0.4), "pattern_color": Color(0.70, 0.55, 0.30), "pattern_strength": 0.5})
	MatLib.define("l601_sofa", {"albedo_a": Color(0.36, 0.40, 0.30), "albedo_b": Color(0.30, 0.34, 0.25), "pattern": 6, "noise_scale": 1.2})
	MatLib.define("l601_dark_wood", {"albedo_a": Color(0.26, 0.16, 0.10), "albedo_b": Color(0.20, 0.12, 0.08),
		"pattern": 3, "pattern_scale": Vector2(1.2, 0.2), "grout_width": 0.001, "roughness_a": 0.35, "roughness_b": 0.55})
	MatLib.define("l601_counter", {"albedo_a": Color(0.82, 0.80, 0.74), "albedo_b": Color(0.76, 0.74, 0.68), "pattern": 15,
		"pattern_strength": 0.2, "roughness_a": 0.3, "roughness_b": 0.45})
	MatLib.define("l601_tv_dead", {"albedo_a": Color(0.02, 0.02, 0.025), "albedo_b": Color(0.03, 0.03, 0.035),
		"roughness_a": 0.08, "roughness_b": 0.12, "bump_strength": 0.0})
	MatLib.define("l601_photo", {"albedo_a": Color(0.55, 0.47, 0.38), "albedo_b": Color(0.35, 0.30, 0.28), "noise_scale": 9.0,
		"bump_strength": 0.0, "roughness_a": 0.2, "roughness_b": 0.3})
	MatLib.define("l601_grass", {"albedo_a": Color(0.36, 0.40, 0.16), "albedo_b": Color(0.28, 0.32, 0.12),
		"pattern_color": Color(0.52, 0.50, 0.22)}, "grass")
	MatLib.define("l601_vend_body", {"albedo_a": Color(0.62, 0.12, 0.10), "albedo_b": Color(0.52, 0.10, 0.08),
		"metallic_value": 0.3, "roughness_a": 0.35, "roughness_b": 0.55, "stain_amount": 0.3, "stain_color": Color(0.3, 0.18, 0.1)})
	MatLib.define("l601_vend_glass", {"albedo_a": Color(0.06, 0.07, 0.08), "albedo_b": Color(0.04, 0.05, 0.06),
		"pattern": 5, "pattern_scale": Vector2(0.11, 0.24), "pattern_color": Color(0.35, 0.30, 0.22), "pattern_strength": 0.8,
		"roughness_a": 0.05, "roughness_b": 0.1})
	MatLib.define("l601_fence_wood", {"albedo_a": Color(0.42, 0.36, 0.28), "albedo_b": Color(0.34, 0.29, 0.22),
		"pattern": 3, "pattern_scale": Vector2(2.0, 0.12)})
	for i in 3:
		var cl: Color = [Color(0.16, 0.17, 0.2), Color(0.28, 0.22, 0.17), Color(0.2, 0.26, 0.22)][i]
		MatLib.define("l601_cloth_" + str(i), {"albedo_a": cl, "albedo_b": cl * 0.8, "pattern": 6, "noise_scale": 2.0})
	MatLib.define("l601_skin", {"albedo_a": Color(0.62, 0.46, 0.38), "albedo_b": Color(0.55, 0.40, 0.33), "bump_strength": 0.1})
	var dusk := MatLib.panel(Color(1.0, 0.62, 0.34), 2.2)
	dusk.set_shader_parameter("ribs", 0.0)
	MatLib.register("l601_dusk_panel", dusk)
	var ember := MatLib.panel(Color(1.0, 0.36, 0.1), 1.1)
	ember.set_shader_parameter("ribs", 0.0)
	MatLib.register("l601_ember_panel", ember)
	var sh := Shader.new()
	sh.code = SKY_SHADER
	var sm := ShaderMaterial.new()
	sm.shader = sh
	MatLib.register("l601_sky_panel", sm)


func _sky_face(k: GeoKit, c: Vector3, nrm: Vector3, hu: Vector3, hv: Vector3) -> void:
	k.quad(c, nrm, hu, hv, "l601_sky_panel", Vector2.ZERO, true)


# ------------------------------------------------------------------- home

func home(o: Vector3, lx: int, lz: int, group: String, n: Node3D) -> Dictionary:
	var k := GeoKit.new(n, "Home")
	var hs := [lib.seed_value, lx, lz, "home"]
	lib._floor(k, o, Rect2())
	lib.ceiling(k, o, 0.0, 0.0, 19.0, CS)
	lib.columns(k, o, true)
	# the stacks this pocket is cut from
	for r in [[2.0, 1.6, 10.4, true], [2.0, 13.6, 22.4, true], [4.2, 1.6, 10.4, true], [4.2, 13.6, 18.6, true],
			[2.0, 11.0, 22.4, false], [4.2, 11.0, 17.6, false], [21.4, 1.6, 10.4, true], [21.4, 13.6, 18.6, true],
			[9.0, 1.6, 8.6, true]]:
		lib.local_run(k, o, r[3], r[0], r[1], r[2], hs + [r[0], r[1]])
	for p in [[6.0, 3.1, 6.0, 1.0], [16.0, 3.1, 5.0, 1.0], [3.1, 16.0, 1.0, 6.0], [8.0, 19.8, 6.0, 1.0]]:
		k.panel(o + Vector3(p[0], L.CEIL - 0.01, p[1]), p[2], p[3], "l601_skylight_panel")
		lib.light(o + Vector3(p[0], L.CEIL - 0.4, p[1]), Color(0.9, 0.94, 1.0), 1.0, 8.0, group)
	# floorboards over the carpet, frayed where the house stops being a house
	k.box_mm(o + Vector3(6.0, 0.0, 6.6), o + Vector3(19.0, 0.02, 18.0), "l601_home_wood", GeoKit.PY, false)
	var v := 7.0
	while v < 18.0:
		var ln := 0.15 + 1.9 * L.h01(hs + ["w", v])
		k.box_mm(o + Vector3(6.0 - ln, 0.0, v), o + Vector3(6.0, 0.02, v + 0.42), "l601_home_wood", GeoKit.PY | GeoKit.SIDES, false)
		v += 0.42
	var u := 6.0
	while u < 19.0:
		var w := 0.7 + 0.9 * L.h01(hs + ["n", u])
		var ln2 := 0.1 + 1.3 * L.h01(hs + ["m", u])
		k.box_mm(o + Vector3(u, 0.0, 6.6 - ln2), o + Vector3(minf(u + w, 19.0), 0.02, 6.6), "l601_home_wood", GeoKit.PY | GeoKit.SIDES, false)
		u += w
	_home_walls(k, o)
	# ceiling at 2.7 m, torn open toward the stacks
	for r in [[9.8, 6.6, 19.0, 18.0], [6.0, 11.2, 9.8, 18.0], [8.0, 8.4, 9.8, 11.2], [7.0, 9.6, 8.0, 11.2]]:
		k.box_mm(o + Vector3(r[0], 2.7, r[1]), o + Vector3(r[2], 2.82, r[3]), "l601_home_ceiling", GeoKit.NY | GeoKit.SIDES, false)
	_home_furniture(k, o)
	# the back garden that becomes the field
	k.box_mm(o + Vector3(19.0, 0.0, 0.0), o + Vector3(CS, 0.015, CS), "l601_grass", GeoKit.PY, false)
	k.box_mm(o + Vector3(19.0, 0.0, 10.6), o + Vector3(21.6, 0.04, 13.4), "concrete", GeoKit.PY | GeoKit.SIDES, false)
	_sky_face(k, o + Vector3(21.5, SKY_H, 12), Vector3.DOWN, Vector3(2.5, 0, 0), Vector3(0, 0, 12))
	_sky_face(k, o + Vector3(21.5, SKY_H * 0.5, 0.3), Vector3.BACK, Vector3(2.5, 0, 0), Vector3(0, SKY_H * 0.5, 0))
	_sky_face(k, o + Vector3(21.5, SKY_H * 0.5, CS - 0.3), Vector3.FORWARD, Vector3(2.5, 0, 0), Vector3(0, SKY_H * 0.5, 0))
	_sky_face(k, o + Vector3(19.0, (SKY_H + L.CEIL + 0.2) * 0.5, 12), Vector3.RIGHT, Vector3(0, 0, 12), Vector3(0, (SKY_H - L.CEIL - 0.2) * 0.5, 0))
	k.commit()
	var warm := Color(1.0, 0.66, 0.42)
	for p in [Vector3(9.0, 1.8, 17.2), Vector3(16.0, 1.8, 17.2), Vector3(18.2, 1.9, 12.0)]:
		lib.light(o + p, warm, 1.3, 7.0, group)
	lib.light(o + Vector3(12.5, 2.2, 12.0), Color(1.0, 0.75, 0.55), 0.6, 8.0, group)
	var door_t: ExitTrigger = lvl.make_exit("L601>EXT#1", "interact", o + DOOR + Vector3(0, 1.05, -0.55), Vector3(1.4, 2.1, 1.0), "Open the front door", n)
	if door_t:
		door_t.condition = func() -> bool: return lvl.try_door("home")
	var crick: AudioStreamPlayer3D = lvl.sound.emitter("crickets", o + DOOR + Vector3(0, 1.4, 0.2), {}, -21.0, 9.0)
	crick.reparent(n)
	return {"kind": "home", "layout": ["home"], "free": [], "door": o + DOOR}


func _home_walls(k: GeoKit, o: Vector3) -> void:
	var walls := [
		[Vector3(6, 0, 18), Vector3(19, 0, 18), [{"at": 6.0, "w": 1.0, "h": 2.1}, {"at": 3.0, "w": 1.4, "h": 1.2, "sill": 0.9}, {"at": 10.0, "w": 1.4, "h": 1.2, "sill": 0.9}], true],
		[Vector3(19, 0, 6.6), Vector3(19, 0, 18), [{"at": 5.4, "w": 2.4, "h": 2.2}, {"at": 1.9, "w": 1.2, "h": 1.1, "sill": 0.95}], false],
		[Vector3(9.8, 0, 6.6), Vector3(19, 0, 6.6), [{"at": 5.7, "w": 1.4, "h": 1.0, "sill": 1.05}], false],
		[Vector3(6, 0, 13), Vector3(6, 0, 18), [], true],
	]
	for wl in walls:
		var inside_pz: bool = not wl[3]
		var inner := (GeoKit.PZ if inside_pz else GeoKit.NZ) | GeoKit.PX | GeoKit.NX | GeoKit.PY
		k.wall(o + wl[0], o + wl[1], 2.7, 0.15, "l601_home_wall", wl[2], inner)
		k.wall(o + wl[0], o + wl[1], 2.7, 0.15, "l601_home_siding", wl[2], GeoKit.NZ if inside_pz else GeoKit.PZ)
	# torn fragments: the wall gives out as it nears the stacks
	for f in [[8.0, 8.6, 2.0], [8.6, 9.2, 1.3], [9.2, 9.8, 0.6]]:
		k.box_mm(o + Vector3(f[0], 0, 6.525), o + Vector3(f[1], f[2], 6.675), "l601_home_wall")
	for f in [[12.4, 13.0, 2.1], [11.8, 12.4, 1.4], [11.2, 11.8, 0.7]]:
		k.box_mm(o + Vector3(5.925, 0, f[0]), o + Vector3(6.075, f[2], f[1]), "l601_home_wall")
	# front door (closed), windows full of a dusk that is never reached
	k.box(o + DOOR + Vector3(0, 1.04, 0), Vector3(0.94, 2.08, 0.05), "l601_dark_wood")
	k.quad(o + DOOR + Vector3(0, 1.62, -0.03), Vector3.FORWARD, Vector3(0.16, 0, 0), Vector3(0, 0.24, 0), "l601_dusk_panel", Vector2.ZERO, true)
	k.box(o + DOOR + Vector3(0.36, 1.0, -0.06), Vector3(0.04, 0.04, 0.08), "l601_steel", GeoKit.ALL, false)
	for wu in [9.0, 16.0]:
		for nz in [Vector3.FORWARD, Vector3.BACK]:
			k.quad(o + Vector3(wu, 1.5, 18.0) + nz * 0.01, nz, Vector3(0.7, 0, 0), Vector3(0, 0.6, 0), "l601_dusk_panel", Vector2.ZERO, true)
		k.box(o + Vector3(wu, 1.5, 18.0), Vector3(0.04, 1.2, 0.06), "l601_dark_wood", GeoKit.ALL, false)
	k.box(o + Vector3(19.0, 1.5, 8.5), Vector3(0.02, 1.1, 1.2), "glass")
	k.box(o + Vector3(15.5, 1.55, 6.6), Vector3(1.4, 1.0, 0.02), "glass")
	k.box(o + Vector3(18.9, 1.1, 10.3), Vector3(0.05, 2.2, 1.3), "glass")


func _fb(k: GeoKit, o: Vector3, c: Vector3, s: Vector3, m: String, col := false) -> void:
	k.box(o + c, s, m, GeoKit.ALL, col)


func _home_furniture(k: GeoKit, o: Vector3) -> void:
	_fb(k, o, Vector3(9.5, 0.025, 13.4), Vector3(3.2, 0.01, 2.4), "l601_rug")
	_fb(k, o, Vector3(9.5, 0.25, 10.65), Vector3(1.8, 0.5, 0.45), "l601_dark_wood", true)
	_fb(k, o, Vector3(9.5, 0.84, 10.62), Vector3(1.1, 0.66, 0.06), "l601_tv_dead")
	_fb(k, o, Vector3(9.5, 0.4, 13.4), Vector3(1.1, 0.04, 0.6), "l601_dark_wood")
	for sx in [-0.5, 0.5]:
		_fb(k, o, Vector3(9.5 + sx, 0.2, 13.4), Vector3(0.05, 0.38, 0.5), "l601_dark_wood")
	k.add_box_shape(Transform3D(Basis(), o + Vector3(9.5, 0.21, 13.4)), Vector3(1.1, 0.42, 0.6), "wood")
	_fb(k, o, Vector3(9.5, 0.22, 15.65), Vector3(2.2, 0.44, 0.9), "l601_sofa", true)
	_fb(k, o, Vector3(9.5, 0.7, 16.0), Vector3(2.2, 0.55, 0.22), "l601_sofa")
	for sx in [-1.0, 1.0]:
		_fb(k, o, Vector3(9.5 + sx, 0.32, 15.65), Vector3(0.2, 0.64, 0.9), "l601_sofa")
	_fb(k, o, Vector3(7.05, 0.22, 13.4), Vector3(0.8, 0.44, 0.8), "l601_sofa", true)
	_fb(k, o, Vector3(6.72, 0.7, 13.4), Vector3(0.18, 0.55, 0.8), "l601_sofa")
	_fb(k, o, Vector3(11.1, 0.75, 16.3), Vector3(0.03, 1.5, 0.03), "l601_plinth")
	_fb(k, o, Vector3(11.1, 1.55, 16.3), Vector3(0.36, 0.26, 0.36), "l601_home_ceiling")
	_fb(k, o, Vector3(14.5, 0.75, 14.0), Vector3(1.8, 0.04, 0.9), "l601_dark_wood")
	k.add_box_shape(Transform3D(Basis(), o + Vector3(14.5, 0.38, 14.0)), Vector3(1.8, 0.76, 0.9), "wood")
	for c in [Vector3(13.9, 0, 13.3), Vector3(15.1, 0, 13.3), Vector3(13.9, 0, 14.7), Vector3(15.1, 0, 14.7)]:
		var sd := -1.0 if c.z < 14.0 else 1.0
		_fb(k, o, c + Vector3(0, 0.45, 0), Vector3(0.42, 0.04, 0.42), "l601_dark_wood")
		_fb(k, o, c + Vector3(0, 0.7, sd * 0.2), Vector3(0.42, 0.5, 0.03), "l601_dark_wood")
	_fb(k, o, Vector3(15.25, 0.45, 7.05), Vector3(5.5, 0.9, 0.6), "l601_home_siding", true)
	_fb(k, o, Vector3(15.25, 0.92, 7.07), Vector3(5.6, 0.04, 0.64), "l601_counter")
	_fb(k, o, Vector3(18.45, 0.9, 7.1), Vector3(0.7, 1.8, 0.65), "trim_white", true)
	for wu in [13.2, 17.3]:
		_fb(k, o, Vector3(wu, 1.85, 6.86), Vector3(1.4, 0.7, 0.35), "l601_home_siding")
	for ph in [[13.6, 1.6, 17.9, 0.32, 0.42], [14.3, 1.7, 17.9, 0.26, 0.34], [6.1, 1.6, 15.5, 0.3, 0.4]]:
		var sz := Vector3(ph[3], ph[4], 0.02) if ph[2] > 17.0 else Vector3(0.02, ph[4], ph[3])
		_fb(k, o, Vector3(ph[0], ph[1], ph[2]), sz, "l601_photo")
	_fb(k, o, Vector3(13.1, 0.9, 17.55), Vector3(0.04, 1.8, 0.04), "l601_dark_wood")
	_fb(k, o, Vector3(13.1, 1.55, 17.5), Vector3(0.3, 0.6, 0.12), "l601_cloth_1")


# ------------------------------------------------------------------ field

func field(o: Vector3, lx: int, lz: int, group: String, n: Node3D) -> Dictionary:
	var k := GeoKit.new(n, "Field")
	var hs := [lib.seed_value, lx, lz, "field"]
	k.slab(o.x, o.z, o.x + CS, o.z + CS, 0.0, 0.2, "l601_grass", GeoKit.PY)
	_sky_face(k, o + Vector3(12, SKY_H, 12), Vector3.DOWN, Vector3(12, 0, 0), Vector3(0, 0, 12))
	# a painted horizon on every side but the house: its border, and walking
	# through it is the breach that puts the library back (no collision)
	var hy := SKY_H * 0.5
	_sky_face(k, o + Vector3(11.85, hy, 0.3), Vector3.BACK, Vector3(11.85, 0, 0), Vector3(0, hy, 0))
	_sky_face(k, o + Vector3(11.85, hy, CS - 0.3), Vector3.FORWARD, Vector3(11.85, 0, 0), Vector3(0, hy, 0))
	_sky_face(k, o + Vector3(CS - 0.3, hy, 12), Vector3.LEFT, Vector3(0, 0, 11.7), Vector3(0, hy, 0))
	# a dead vending machine standing in the grass
	var vb := Basis(Vector3.UP, 0.22)
	k.box_xf(Transform3D(vb, o + VEND + Vector3(0, 0.93, 0)), Vector3(0.8, 1.86, 0.95), "l601_vend_body")
	k.box_xf(Transform3D(vb, o + VEND + vb * Vector3(-0.405, 1.05, 0.08)), Vector3(0.02, 1.25, 0.66), "l601_vend_glass", GeoKit.ALL, false)
	k.box_xf(Transform3D(vb, o + VEND + vb * Vector3(-0.41, 0.2, 0.0)), Vector3(0.02, 0.18, 0.6), "l601_monitor", GeoKit.ALL, false)
	# the Junkies' outpost: a cold fire ring, six bedrolls, six people
	for i in 9:
		var a := TAU * i / 9.0
		k.box(o + CAMP + Vector3(cos(a) * 0.55, 0.08, sin(a) * 0.55), Vector3(0.2, 0.16, 0.18), "rock", GeoKit.ALL, false)
	k.quad(o + CAMP + Vector3(0, 0.03, 0), Vector3.UP, Vector3(0.38, 0, 0), Vector3(0, 0, 0.38), "l601_ember_panel", Vector2.ZERO, true)
	var people: Array = []
	for i in 6:
		var a := TAU * (i + 0.3) / 6.0 + 0.2 * L.h01(hs + [i])
		var dir := Vector3(cos(a), 0, sin(a))
		var bed := Basis(Vector3.UP, atan2(dir.x, dir.z))
		k.box_xf(Transform3D(bed, o + CAMP + dir * 2.3 + Vector3(0, 0.06, 0)), Vector3(0.7, 0.12, 1.9), "l601_cloth_" + str(i % 3), GeoKit.ALL, false)
		var pp := o + CAMP + dir * 1.45
		_person(k, pp, -dir, i)
		people.append(pp)
		k.cylinder(o + CAMP + dir.rotated(Vector3.UP, 0.4) * 1.1 + Vector3(0, 0.12, 0), 0.035, 0.24, "glass", 8, false)
	k.box(o + CAMP + Vector3(2.6, 0.7, -1.9), Vector3(0.06, 1.4, 0.06), "l601_fence_wood", GeoKit.ALL, false)
	k.box(o + CAMP + Vector3(2.6, 1.25, -1.88), Vector3(0.95, 0.5, 0.03), "l601_fence_wood", GeoKit.ALL, false)
	var sign := Label3D.new()
	sign.text = "TRADE\nMEMORY JUICE ONLY"
	sign.font_size = 40
	sign.pixel_size = 0.0035
	sign.modulate = Color(0.12, 0.1, 0.08)
	sign.outline_size = 0
	sign.shaded = true
	sign.position = o + CAMP + Vector3(2.6, 1.25, -1.86)
	n.add_child(sign)
	# a fence with a gate at the far end of the field
	var fz := GATE.z
	var x := 2.0
	while x < 22.0:
		if x < 14.0 or x > 16.6:
			k.box(o + Vector3(x, 0.6, fz), Vector3(0.12, 1.2, 0.12), "l601_fence_wood")
		x += 2.5
	for seg in [[2.0, 14.0], [16.6, 22.0]]:
		for y in [0.55, 1.0]:
			k.box(o + Vector3((seg[0] + seg[1]) * 0.5, y, fz), Vector3(seg[1] - seg[0], 0.1, 0.05), "l601_fence_wood", GeoKit.ALL, false)
		k.add_box_shape(Transform3D(Basis(), o + Vector3((seg[0] + seg[1]) * 0.5, 0.6, fz)), Vector3(seg[1] - seg[0], 1.2, 0.1), "wood")
	for gx in [14.0, 16.6]:
		k.box(o + Vector3(gx, 0.7, fz), Vector3(0.14, 1.4, 0.14), "l601_fence_wood")
	for y in [0.3, 0.65, 1.0]:
		k.box(o + Vector3(15.3, y, fz), Vector3(2.46, 0.1, 0.05), "l601_fence_wood")
	k.box_xf(Transform3D(Basis(Vector3.BACK, 0.42), o + Vector3(15.3, 0.65, fz)), Vector3(2.5, 0.08, 0.05), "l601_fence_wood", GeoKit.ALL, false)
	k.commit()
	lib.light(o + Vector3(20.0, 10.0, 3.0), Color(1.0, 0.76, 0.5), 3.2, 34.0, group)
	lib.light(o + Vector3(5.0, 6.0, 19.0), Color(1.0, 0.8, 0.62), 1.1, 18.0, group)
	lib.light(o + CAMP + Vector3(0, 0.6, 0), Color(1.0, 0.5, 0.22), 1.4, 7.0, group, 0.3)
	var gate_t: ExitTrigger = lvl.make_exit("L601>EXT#1", "interact", o + GATE + Vector3(0, 0.8, -0.6), Vector3(2.4, 1.6, 1.0), "Open the gate", n)
	if gate_t:
		gate_t.condition = func() -> bool: return lvl.try_door("gate")
	for i in people.size():
		var it: Interactable = lvl.add_interactable(people[i] + Vector3(0, 0.6, 0), Vector3(0.6, 1.2, 0.6), "Speak to them", lvl.on_junkie)
		it.reparent(n)
	var note: Interactable = lvl.add_note("l601_bntg", "Tag tied to the gate", lvl.bntg_text(), o + GATE + Vector3(0.9, 1.05, -0.08), Vector3(0.3, 0.3, 0.1), false)
	note.reparent(n)
	var crack: AudioStreamPlayer3D = lvl.sound.emitter("crackle", o + CAMP + Vector3(0, 0.3, 0), {}, -20.0, 10.0)
	crack.reparent(n)
	var wind: AudioStreamPlayer3D = lvl.sound.emitter("wind", o + Vector3(12, 4, 12), {}, -24.0, 22.0)
	wind.reparent(n)
	return {"kind": "field", "layout": ["field"], "free": [], "people": people, "gate": o + GATE}


## A seated, slumped figure facing `face` (the fire). Humans are perceivable
## inside the fake realities (SOURCE); they do not move.
func _person(k: GeoKit, p: Vector3, face: Vector3, i: int) -> void:
	var yaw := atan2(face.x, face.z)
	var b := Basis(Vector3.UP, yaw)
	var cloth := "l601_cloth_" + str(i % 3)
	var lean := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, 0.38 + 0.1 * (i % 2))
	for s in [-0.1, 0.1]:
		k.box_xf(Transform3D(b, p + b * Vector3(s, 0.1, 0.25)), Vector3(0.14, 0.14, 0.5), cloth, GeoKit.ALL, false)
	k.box_xf(Transform3D(lean, p + b * Vector3(0, 0.0, -0.08) + lean * Vector3(0, 0.42, 0)), Vector3(0.38, 0.56, 0.22), cloth, GeoKit.ALL, false)
	var head_b := Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, 0.6)
	k.box_xf(Transform3D(head_b, p + b * Vector3(0, 0, -0.08) + lean * Vector3(0, 0.8, 0.06)), Vector3(0.17, 0.22, 0.2), "l601_skin", GeoKit.ALL, false)
	for s in [-0.22, 0.22]:
		k.box_xf(Transform3D(lean, p + b * Vector3(s, 0, -0.04) + lean * Vector3(0, 0.45, 0.12)), Vector3(0.09, 0.42, 0.1), cloth, GeoKit.ALL, false)
	k.add_box_shape(Transform3D(b, p + Vector3(0, 0.45, 0)), Vector3(0.5, 0.9, 0.7), "plush")
