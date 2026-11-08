extends RefCounted
## Level 31 shell: the rink hall (oval maple floor, rail and gates, rough black
## carpet concourse, neon ceiling, star fixture, raised DJ booth), the blue-walled
## skate rental, the food court, the TV corridor and the stepped Cinema.
## The arcade and its back room live in L031_arcade.gd. Coordinates: x east,
## -z north, y up; floor of the hall at y = 0.

const T := 0.3
const H_HALL := 7.0
const RINK_A := 8.0        # half-length of the oval's straight
const RINK_R := 9.0        # radius of the oval's round ends
const GAME_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
uniform vec3 c1 : source_color = vec3(0.1, 0.2, 0.9);
uniform vec3 c2 : source_color = vec3(1.0, 0.8, 0.1);
uniform vec3 c3 : source_color = vec3(0.9, 0.2, 0.5);
uniform float seed = 0.0;
uniform float energy = 1.4;
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233)) + seed * 7.13) * 43758.5453); }
void fragment() {
	vec2 g = floor(UV * vec2(28.0, 22.0));
	float t = floor(TIME * 3.0 + seed * 11.0);
	vec3 col = mix(c1 * 0.08, c1 * 0.32, UV.y);
	float alien = step(0.86, h(vec2(g.x, floor((g.y + t * 0.25) / 2.0)))) * step(g.y, 13.0);
	col = mix(col, c2, alien);
	float px = floor(fract(TIME * 0.11 + seed) * 26.0) + 1.0;
	col = mix(col, c3, step(abs(g.x - px), 0.6) * step(19.0, g.y) * step(g.y, 20.5));
	col = mix(col, vec3(1.0), step(0.985, h(g + t)) * 0.6);
	float scan = 0.82 + 0.18 * sin(UV.y * 260.0);
	ALBEDO = col * scan * energy;
}
"""
const MOVIE_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;
uniform float seed = 0.0;
uniform float energy = 1.2;
void fragment() {
	vec2 uv = UV;
	float t = TIME * 0.05 + seed;
	vec3 sky = mix(vec3(0.95, 0.62, 0.38), vec3(0.22, 0.32, 0.62), smoothstep(0.1, 0.9, 1.0 - uv.y + 0.15 * sin(t)));
	float hill = 0.32 + 0.06 * sin(uv.x * 7.0 + t * 3.0) + 0.04 * sin(uv.x * 17.0 - t * 5.0);
	vec3 col = mix(sky, vec3(0.16, 0.24, 0.14), step(1.0 - uv.y, hill));
	vec2 d = vec2(fract(t * 0.9) * 1.4 - 0.2, 0.62 + 0.04 * sin(t * 9.0));
	float dog = 1.0 - smoothstep(0.04, 0.05, length((uv - d) * vec2(1.0, 1.6)));
	col = mix(col, vec3(0.55, 0.36, 0.18), dog);
	float halo = 1.0 - smoothstep(0.0, 0.22, length(uv - vec2(0.5 + 0.2 * sin(t * 2.0), 0.25)));
	col += vec3(1.0, 0.95, 0.7) * halo * 0.35;
	float flick = 0.93 + 0.07 * fract(sin(floor(TIME * 18.0)) * 4375.0);
	ALBEDO = col * flick * energy;
}
"""

var L: LevelBase
var props: Node3D
var star: Node3D
var hall_kit: GeoKit


func _init(level: LevelBase, props_root: Node3D) -> void:
	L = level
	props = props_root


static func materials() -> void:
	MatLib.define("l31_rinkwood", {"albedo_a": Color(0.72, 0.50, 0.28), "albedo_b": Color(0.62, 0.41, 0.22), "pattern": 3,
		"pattern_scale": Vector2(2.4, 0.07), "grout_width": 0.003, "grout_color": Color(0.30, 0.18, 0.09), "tile_variation": 0.08,
		"roughness_a": 0.16, "roughness_b": 0.34, "noise_scale": 2.0, "stain_amount": 0.18, "stain_color": Color(0.45, 0.29, 0.14),
		"bump_strength": 0.25}, "wood_floor")
	MatLib.define("l31_carpet", {"albedo_a": Color(0.035, 0.035, 0.045), "albedo_b": Color(0.02, 0.02, 0.03), "pattern": 6,
		"pattern_scale": Vector2(0.55, 0.55), "pattern_color": Color(0.30, 0.10, 0.45), "pattern_strength": 0.35, "noise_scale": 6.0,
		"roughness_a": 1.0, "roughness_b": 1.0, "bump_strength": 1.1, "stain_amount": 0.15, "stain_color": Color(0.06, 0.05, 0.05)})
	MatLib.define("l31_arcade_carpet", {"albedo_a": Color(0.03, 0.03, 0.08), "albedo_b": Color(0.02, 0.02, 0.05), "pattern": 6,
		"pattern_scale": Vector2(0.4, 0.4), "pattern_color": Color(0.05, 0.55, 0.65), "pattern_strength": 0.55, "noise_scale": 6.0,
		"roughness_a": 1.0, "roughness_b": 1.0, "bump_strength": 1.0})
	MatLib.define("l31_wall", {"albedo_a": Color(0.10, 0.08, 0.20), "albedo_b": Color(0.08, 0.06, 0.16), "pattern": 14,
		"pattern_scale": Vector2(0.4, 0.2), "grout_width": 0.008, "grout_color": Color(0.06, 0.05, 0.12), "roughness_a": 0.8,
		"roughness_b": 0.9, "grime_height": 0.4, "grime_color": Color(0.05, 0.04, 0.08), "bump_strength": 0.4}, "plaster")
	MatLib.define("l31_wall_carpet", {"albedo_a": Color(0.05, 0.04, 0.09), "albedo_b": Color(0.04, 0.03, 0.07), "pattern": 6,
		"pattern_scale": Vector2(0.5, 0.5), "pattern_color": Color(0.5, 0.15, 0.4), "pattern_strength": 0.3, "bump_strength": 0.8})
	MatLib.define("l31_mural", {"albedo_a": Color(0.85, 0.15, 0.55), "albedo_b": Color(0.85, 0.15, 0.55), "pattern": 2,
		"pattern_scale": Vector2(1.0, 0.2), "pattern_color": Color(0.1, 0.65, 0.8), "pattern_strength": 1.0,
		"emission_color": Color(0.5, 0.1, 0.4), "emission_energy": 0.25, "roughness_a": 0.5, "roughness_b": 0.6})
	MatLib.define("l31_ceiling", {"albedo_a": Color(0.03, 0.03, 0.04), "albedo_b": Color(0.02, 0.02, 0.03), "noise_scale": 2.0,
		"roughness_a": 0.95, "roughness_b": 1.0}, "concrete")
	MatLib.define("l31_rail", {"albedo_a": Color(0.78, 0.74, 0.66), "albedo_b": Color(0.70, 0.66, 0.58), "pattern": 3,
		"pattern_scale": Vector2(1.6, 0.16), "grout_width": 0.004, "grout_color": Color(0.4, 0.36, 0.3), "stain_amount": 0.25,
		"stain_color": Color(0.45, 0.4, 0.32), "roughness_a": 0.45, "roughness_b": 0.6, "grime_height": 0.18,
		"grime_color": Color(0.3, 0.26, 0.2)}, "wood_floor")
	MatLib.define("l31_darkwood", {"albedo_a": Color(0.24, 0.13, 0.07), "albedo_b": Color(0.19, 0.10, 0.05), "roughness_a": 0.3,
		"roughness_b": 0.45}, "wood_floor")
	MatLib.define("l31_paint", {"albedo_a": Color(0.06, 0.06, 0.08), "albedo_b": Color(0.05, 0.05, 0.06), "roughness_a": 0.55,
		"roughness_b": 0.7, "noise_scale": 3.0}, "plaster")
	MatLib.define("l31_blue", {"albedo_a": Color(0.10, 0.26, 0.62), "albedo_b": Color(0.08, 0.22, 0.54), "stain_amount": 0.2,
		"stain_color": Color(0.07, 0.15, 0.34), "grime_height": 0.3, "grime_color": Color(0.05, 0.12, 0.3)}, "plaster")
	MatLib.define("l31_tile", {"albedo_a": Color(0.82, 0.78, 0.68), "albedo_b": Color(0.78, 0.74, 0.64), "pattern": 9,
		"pattern_scale": Vector2(0.3, 0.3), "pattern_color": Color(0.55, 0.12, 0.08), "pattern_strength": 0.85,
		"roughness_a": 0.3, "roughness_b": 0.45, "stain_amount": 0.25, "stain_color": Color(0.5, 0.42, 0.3)})
	MatLib.define("l31_fc_wall", {"albedo_a": Color(0.86, 0.80, 0.66), "albedo_b": Color(0.80, 0.74, 0.60), "pattern": 1,
		"pattern_scale": Vector2(0.15, 0.15), "grout_width": 0.006, "grout_color": Color(0.7, 0.66, 0.56), "roughness_a": 0.3,
		"roughness_b": 0.4, "grime_height": 0.25, "grime_color": Color(0.55, 0.48, 0.36)}, "plaster")
	MatLib.define("l31_red", {"albedo_a": Color(0.62, 0.07, 0.05), "albedo_b": Color(0.55, 0.05, 0.04), "roughness_a": 0.35,
		"roughness_b": 0.45}, "plaster")
	MatLib.define("l31_orange", {"albedo_a": Color(0.92, 0.38, 0.06), "albedo_b": Color(0.85, 0.33, 0.05), "roughness_a": 0.35,
		"roughness_b": 0.5, "metallic_value": 0.3}, "metal")
	MatLib.define("l31_green", {"albedo_a": Color(0.12, 0.48, 0.20), "albedo_b": Color(0.10, 0.42, 0.17), "roughness_a": 0.35,
		"roughness_b": 0.5, "metallic_value": 0.3}, "metal")
	MatLib.define("l31_steel", {"albedo_a": Color(0.60, 0.61, 0.63), "albedo_b": Color(0.50, 0.51, 0.53), "roughness_a": 0.3,
		"roughness_b": 0.45}, "metal")
	MatLib.define("l31_locker", {"albedo_a": Color(0.16, 0.30, 0.56), "albedo_b": Color(0.14, 0.27, 0.50), "pattern": 2,
		"pattern_scale": Vector2(0.45, 1.0), "pattern_color": Color(0.05, 0.08, 0.15), "pattern_strength": 0.7,
		"metallic_value": 0.5, "roughness_a": 0.4, "roughness_b": 0.55}, "metal")
	MatLib.define("l31_cloth", {"albedo_a": Color(0.46, 0.43, 0.38), "albedo_b": Color(0.38, 0.35, 0.31), "noise_scale": 4.0,
		"stain_amount": 0.35, "stain_color": Color(0.3, 0.28, 0.24), "roughness_a": 1.0, "roughness_b": 1.0, "bump_strength": 1.4})
	MatLib.define("l31_white_door", {"albedo_a": Color(0.86, 0.86, 0.84), "albedo_b": Color(0.82, 0.82, 0.80), "roughness_a": 0.4,
		"roughness_b": 0.5, "stain_amount": 0.15}, "trim_white")
	MatLib.define("l31_door_wood", {"albedo_a": Color(0.42, 0.27, 0.15), "albedo_b": Color(0.36, 0.23, 0.12), "pattern": 3,
		"pattern_scale": Vector2(0.18, 2.0), "grout_width": 0.003}, "wood_floor")
	MatLib.define("l31_black", {"albedo_a": Color(0.03, 0.03, 0.03), "albedo_b": Color(0.02, 0.02, 0.02), "roughness_a": 0.35,
		"roughness_b": 0.5}, "plaster")
	MatLib.define("l31_woodgrain", {"albedo_a": Color(0.38, 0.22, 0.10), "albedo_b": Color(0.30, 0.17, 0.08), "pattern": 3,
		"pattern_scale": Vector2(0.12, 1.5), "grout_width": 0.001}, "wood_floor")
	MatLib.define("l31_boot", {"albedo_a": Color(0.88, 0.86, 0.80), "albedo_b": Color(0.80, 0.78, 0.72), "roughness_a": 0.6,
		"roughness_b": 0.7, "stain_amount": 0.4, "stain_color": Color(0.5, 0.45, 0.4)})
	MatLib.register("l31_glass", MatLib.get_mat("glass"))
	var neon := {"pink": Color(1.0, 0.18, 0.62), "cyan": Color(0.15, 0.85, 1.0), "violet": Color(0.55, 0.25, 1.0),
		"yellow": Color(1.0, 0.82, 0.2), "green": Color(0.25, 1.0, 0.45), "warm": Color(1.0, 0.86, 0.6),
		"white": Color(0.92, 0.95, 1.0), "red": Color(1.0, 0.12, 0.1), "blue": Color(0.2, 0.35, 1.0)}
	for key in neon.keys():
		MatLib.register("l31_neon_" + key, MatLib.panel(neon[key], 2.6))
	MatLib.register("l31_fluor", MatLib.panel(Color(0.95, 0.96, 0.9), 1.6))
	MatLib.register("l31_star", MatLib.panel(Color(1.0, 0.9, 0.62), 3.4))
	var gs := Shader.new()
	gs.code = GAME_SHADER
	var pal := [[Color(0.1, 0.2, 0.9), Color(1, 0.85, 0.1), Color(1, 0.2, 0.5)], [Color(0.9, 0.1, 0.3), Color(0.2, 1, 0.5), Color(1, 1, 0.3)],
		[Color(0.1, 0.7, 0.4), Color(1, 0.3, 0.9), Color(0.2, 0.8, 1)], [Color(0.8, 0.4, 0.05), Color(0.3, 0.6, 1), Color(1, 1, 1)],
		[Color(0.4, 0.1, 0.8), Color(0.2, 1, 0.9), Color(1, 0.5, 0.1)], [Color(0.05, 0.05, 0.4), Color(1, 1, 1), Color(0.3, 1, 0.3)]]
	for i in pal.size():
		var m := ShaderMaterial.new()
		m.shader = gs
		m.set_shader_parameter("c1", pal[i][0])
		m.set_shader_parameter("c2", pal[i][1])
		m.set_shader_parameter("c3", pal[i][2])
		m.set_shader_parameter("seed", float(i) * 1.37)
		MatLib.register("l31_game%d" % i, m)
	var ms := Shader.new()
	ms.code = MOVIE_SHADER
	for i in 2:
		var mm := ShaderMaterial.new()
		mm.shader = ms
		mm.set_shader_parameter("seed", float(i) * 3.1)
		mm.set_shader_parameter("energy", 1.25 if i == 0 else 0.9)
		MatLib.register("l31_movie%d" % i, mm)


func p(id: String, pos: Vector3, yaw: float = 0.0, h: float = 0.0, collide: bool = false) -> Node3D:
	return Props.place(L, props, id, pos, yaw, h, collide)


## Recolour a placed model (Kenney/Poly Haven) with one material.
static func tint(n: Node, mat: Material) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).material_override = mat
	for c in n.get_children():
		tint(c, mat)


static func label(parent: Node3D, text: String, pos: Vector3, yaw: float, size: int, col: Color, outline := 0) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.004
	l.modulate = col
	l.outline_size = outline
	l.outline_modulate = Color(col.r * 0.4, col.g * 0.4, col.b * 0.4, 0.8)
	l.position = pos
	l.rotation.y = deg_to_rad(yaw)
	l.double_sided = false
	parent.add_child(l)
	return l


func neon_line(k: GeoKit, a: Vector3, b: Vector3, mat: String, thick := 0.06) -> void:
	var d := b - a
	var len := d.length()
	if len < 0.01:
		return
	var z := d / len
	var x := Vector3.UP.cross(z)
	if x.length() < 0.1:
		x = Vector3.RIGHT
	x = x.normalized()
	var y := z.cross(x).normalized()
	k.box_xf(Transform3D(Basis(x, y, z), (a + b) * 0.5), Vector3(thick, thick, len), mat, GeoKit.ALL, false)


## Oval point at parameter t in [0,1) for a lane of half-width r around the rink.
static func oval_point(t: float, r: float) -> Vector3:
	var straight := RINK_A * 2.0
	var arc := PI * r
	var per := straight * 2.0 + arc * 2.0
	var s := fposmod(t, 1.0) * per
	if s < straight:
		return Vector3(-RINK_A + s, 0, r)
	s -= straight
	if s < arc:
		var a := PI * 0.5 - s / r
		return Vector3(RINK_A + cos(a) * r, 0, sin(a) * r)
	s -= arc
	if s < straight:
		return Vector3(RINK_A - s, 0, -r)
	s -= straight
	var b := -PI * 0.5 - s / r
	return Vector3(-RINK_A + cos(b) * r, 0, sin(b) * r)


# ------------------------------------------------------------------ hall

func hall() -> void:
	var k := L.kit("RinkHall")
	hall_kit = k
	k.slab(-28, -16, 28, 16, 0.0, 0.4, "l31_carpet")
	k.slab(-28.15, -16.15, 28.15, 16.15, H_HALL + 0.3, 0.3, "l31_ceiling")
	# walls: carpeted dado to 1.2 m, painted block above, a neon-stripe mural band
	k.wall(Vector3(-28, 0, -16), Vector3(-28, 0, 16), H_HALL, T, "l31_wall")
	k.wall(Vector3(-28, 0, 16), Vector3(28, 0, 16), H_HALL, T, "l31_wall")
	k.wall(Vector3(28, 0, -16), Vector3(28, 0, 16), H_HALL, T, "l31_wall", [{"at": 16.0, "w": 6.0, "h": 3.2}])
	k.wall(Vector3(-28, 0, -16), Vector3(28, 0, -16), H_HALL, T, "l31_wall",
		[{"at": 4.0, "w": 4.0, "h": 2.8}, {"at": 23.0, "w": 5.0, "h": 2.8}, {"at": 42.0, "w": 8.0, "h": 3.0}])
	var dado := [[Vector3(-27.84, 0.6, 0), Vector3(0.02, 1.2, 31.4)], [Vector3(0, 0.6, 15.84), Vector3(55.4, 1.2, 0.02)]]
	for d in dado:
		k.box(d[0], d[1], "l31_wall_carpet", GeoKit.ALL, false)
	for seg in [[-27.7, -26.0], [-22.0, -7.5], [-2.5, 10.0], [18.0, 27.7]]:
		k.box(Vector3((seg[0] + seg[1]) * 0.5, 0.6, -15.84), Vector3(seg[1] - seg[0], 1.2, 0.02), "l31_wall_carpet", GeoKit.ALL, false)
	for seg in [[-15.8, -3.0], [3.0, 15.8]]:
		k.box(Vector3(27.84, 0.6, (seg[0] + seg[1]) * 0.5), Vector3(0.02, 1.2, seg[1] - seg[0]), "l31_wall_carpet", GeoKit.ALL, false)
	k.box(Vector3(-27.83, 4.0, 0), Vector3(0.03, 0.5, 31.4), "l31_mural", GeoKit.ALL, false)
	k.box(Vector3(0, 4.0, 15.83), Vector3(55.4, 0.5, 0.03), "l31_mural", GeoKit.ALL, false)
	k.box(Vector3(0, 4.0, -15.83), Vector3(55.4, 0.5, 0.03), "l31_mural", GeoKit.ALL, false)
	k.box(Vector3(27.83, 4.0, 0), Vector3(0.03, 0.5, 31.4), "l31_mural", GeoKit.ALL, false)
	# the wooden door you came through (closed behind you, music on its other side)
	k.box(Vector3(-27.81, 1.06, 2.0), Vector3(0.06, 2.12, 1.0), "l31_door_wood", GeoKit.ALL, false)
	for dz in [-0.56, 0.56]:
		k.box(Vector3(-27.8, 1.1, 2.0 + dz), Vector3(0.08, 2.2, 0.1), "l31_darkwood", GeoKit.ALL, false)
	k.box(Vector3(-27.8, 2.22, 2.0), Vector3(0.08, 0.1, 1.22), "l31_darkwood", GeoKit.ALL, false)
	k.box(Vector3(-27.74, 1.0, 1.65), Vector3(0.06, 0.06, 0.14), "l31_steel", GeoKit.ALL, false)
	_rink(k)
	_ceiling(k)
	_dj_booth(k)
	_concourse(k)
	k.commit()
	star = _star()


func _rink(k: GeoKit) -> void:
	var y := 0.03
	# maple floor: a visual oval and its own wooden collision (footsteps read "wood")
	k.quad(Vector3(0, y, 0), Vector3.UP, Vector3(RINK_A, 0, 0), Vector3(0, 0, RINK_R), "l31_rinkwood")
	var n := 20
	for side in [-1.0, 1.0]:
		var c := Vector3(side * RINK_A, y, 0)
		for i in n:
			var a0 := -PI * 0.5 + PI * float(i) / n
			var a1 := -PI * 0.5 + PI * float(i + 1) / n
			var p0 := c + Vector3(side * cos(a0) * RINK_R, 0, sin(a0) * RINK_R)
			var p1 := c + Vector3(side * cos(a1) * RINK_R, 0, sin(a1) * RINK_R)
			k._tri_fan(c, p0, p1, Vector3.UP, "l31_rinkwood")
	k.add_box_shape(Transform3D(Basis(), Vector3(0, y - 0.05, 0)), Vector3(RINK_A * 2.0, 0.1, RINK_R * 2.0), "wood")
	for side in [-1.0, 1.0]:
		for i in 6:
			var x0 := RINK_R * float(i) / 6.0
			var x1 := RINK_R * float(i + 1) / 6.0
			var hz := sqrt(maxf(RINK_R * RINK_R - x1 * x1, 0.0)) if i < 5 else sqrt(maxf(RINK_R * RINK_R - x0 * x0, 0.0)) * 0.6
			k.add_box_shape(Transform3D(Basis(), Vector3(side * (RINK_A + (x0 + x1) * 0.5), y - 0.05, 0)), Vector3(x1 - x0, 0.1, hz * 2.0), "wood")
	# centre circle and lane line painted on the maple
	for i in 32:
		var a := TAU * float(i) / 32.0
		var b := TAU * float(i + 1) / 32.0
		k.box_xf(Transform3D(Basis(Vector3.UP, -(a + b) * 0.5), Vector3(cos((a + b) * 0.5) * 3.0, y + 0.002, sin((a + b) * 0.5) * 3.0)),
			Vector3(0.06, 0.004, 3.0 * (b - a) + 0.02), "l31_red", GeoKit.PY, false)
	# the rail: a short wooden wall around the oval, gates with flaps onto the carpet
	var rr := RINK_R + 0.06
	var gates_n := [-5.0, 5.0]
	var gates_s := [-6.0]
	var ops_n := []
	for g in gates_n:
		ops_n.append({"at": g + RINK_A, "w": 1.4, "h": 2.0})
	var ops_s := []
	for g in gates_s:
		ops_s.append({"at": g + RINK_A, "w": 1.4, "h": 2.0})
	k.wall(Vector3(-RINK_A, 0, -rr), Vector3(RINK_A, 0, -rr), 1.0, 0.1, "l31_rail", ops_n)
	k.wall(Vector3(-RINK_A, 0, rr), Vector3(RINK_A, 0, rr), 1.0, 0.1, "l31_rail", ops_s)
	for side in [-1.0, 1.0]:
		var c := Vector3(side * RINK_A, 0, 0)
		for i in 16:
			var a0 := -PI * 0.5 + PI * float(i) / 16.0
			var a1 := -PI * 0.5 + PI * float(i + 1) / 16.0
			var p0 := c + Vector3(side * cos(a0) * rr, 0, sin(a0) * rr)
			var p1 := c + Vector3(side * cos(a1) * rr, 0, sin(a1) * rr)
			k.wall(p0, p1, 1.0, 0.1, "l31_rail")
			k.wall(p0 + Vector3(0, 1.0, 0), p1 + Vector3(0, 1.0, 0), 0.05, 0.18, "l31_darkwood", [], GeoKit.ALL)
	for z in [-rr, rr]:
		var gl: Array = gates_n if z < 0.0 else gates_s
		var xs := [-RINK_A]
		for g in gl:
			xs.append(float(g) - 0.7)
			xs.append(float(g) + 0.7)
		xs.append(RINK_A)
		for j in range(0, xs.size(), 2):
			k.box(Vector3((xs[j] + xs[j + 1]) * 0.5, 1.025, z), Vector3(xs[j + 1] - xs[j], 0.05, 0.18), "l31_darkwood", GeoKit.ALL, false)
		# gate flaps: two short wooden leaves swung outward onto the carpet
		var out := -1.0 if z < 0.0 else 1.0
		for g in gl:
			for s in [-1.0, 1.0]:
				k.box(Vector3(float(g) + s * 0.66, 0.5, z + out * 0.36), Vector3(0.04, 0.72, 0.64), "l31_rail", GeoKit.ALL, false)
	# rubber kick-strip at the rail foot
	for z in [-rr + 0.08, rr - 0.08]:
		k.box(Vector3(0, 0.08, z), Vector3(RINK_A * 2.0, 0.16, 0.04), "l31_black", GeoKit.ALL, false)


func _ceiling(k: GeoKit) -> void:
	# colourful tubes in concentric ovals and chevrons over the concourse
	var cols := ["pink", "cyan", "violet", "yellow"]
	var rings := [[7.6, 6.3], [4.6, 6.45]]
	for ri in rings.size():
		var r: float = rings[ri][0]
		var y: float = rings[ri][1]
		var segs := 28
		for i in segs:
			if i % 7 == 6:
				continue
			var a := oval_point(float(i) / segs, r) + Vector3(0, y, 0)
			var b := oval_point(float(i + 0.8) / segs, r) + Vector3(0, y, 0)
			neon_line(k, a, b, "l31_neon_" + cols[(i / 2 + ri) % cols.size()])
	for zs in [-1.0, 1.0]:
		for i in 9:
			var x := -24.0 + float(i) * 6.0
			var a := Vector3(x, 6.2, zs * 12.4)
			var b := Vector3(x + 3.0, 6.2, zs * 14.2)
			var c := Vector3(x + 6.0, 6.2, zs * 12.4)
			neon_line(k, a, b, "l31_neon_" + cols[(i + 1) % 4])
			neon_line(k, b, c, "l31_neon_" + cols[(i + 2) % 4])
	# hanging cables for the rings
	for i in 8:
		var q := oval_point(float(i) / 8.0, 7.6)
		k.box(Vector3(q.x, 6.68, q.z), Vector3(0.015, 0.75, 0.015), "l31_black", GeoKit.ALL, false)
	# roof trusses spanning the hall (black steel, read against the neon)
	for x in [-21.0, -10.5, 0.0, 10.5, 21.0]:
		k.box(Vector3(x, 6.85, 0), Vector3(0.25, 0.35, 32.0), "l31_steel", GeoKit.ALL, false)
		k.box(Vector3(x, 6.45, 0), Vector3(0.12, 0.08, 32.0), "l31_steel", GeoKit.ALL, false)
		for i in 16:
			var z := -15.0 + i * 2.0
			neon_line(k, Vector3(x, 6.47, z), Vector3(x, 6.83, z + 1.0), "l31_steel", 0.05)
			neon_line(k, Vector3(x, 6.83, z + 1.0), Vector3(x, 6.47, z + 2.0), "l31_steel", 0.05)
	# speaker clusters hung over the rink ends
	for x in [-14.0, 14.0]:
		k.box(Vector3(x, 5.6, 0), Vector3(0.7, 1.0, 0.7), "l31_black", GeoKit.ALL, false)
		k.box(Vector3(x, 6.6, 0), Vector3(0.02, 1.0, 0.02), "l31_black", GeoKit.ALL, false)


## The star-shaped light fixture at the centre; it turns slowly (adaptation).
func _star() -> Node3D:
	var n := Node3D.new()
	n.name = "StarFixture"
	n.position = Vector3(0, 5.7, 0)
	L.add_child(n)
	var k := GeoKit.new(n, "Star")
	var pts := []
	for i in 10:
		var a := -PI * 0.5 + TAU * float(i) / 10.0
		var r := 2.7 if i % 2 == 0 else 1.1
		pts.append(Vector3(cos(a) * r, 0, sin(a) * r))
	for i in 10:
		neon_line(k, pts[i], pts[(i + 1) % 10], "l31_star", 0.12)
		neon_line(k, pts[i] + Vector3(0, 0.14, 0), pts[(i + 1) % 10] + Vector3(0, 0.14, 0), "l31_steel", 0.05)
	for i in range(0, 10, 2):
		neon_line(k, Vector3.ZERO, pts[i] * 0.85, "l31_neon_white", 0.04)
	k.cylinder(Vector3(0, 0.0, 0), 0.5, 0.18, "l31_steel", 16, false)
	k.cylinder(Vector3(0, -0.1, 0), 0.38, 0.04, "l31_star", 16, false)
	k.box(Vector3(0, 0.75, 0), Vector3(0.03, 1.4, 0.03), "l31_black", GeoKit.ALL, false)
	k.commit()
	return n


func _dj_booth(k: GeoKit) -> void:
	# SOURCE: the DJ station at the south side of the rink. Raised booth (+1.08 m).
	var top := 1.08
	k.box_mm(Vector3(-4, 0, 11.6), Vector3(6.4, top, 15.85), "l31_paint")
	k.box(Vector3(1.2, 0.5, 11.58), Vector3(10.4, 0.06, 0.04), "l31_neon_cyan", GeoKit.ALL, false)
	k.box(Vector3(1.2, 0.9, 11.58), Vector3(10.4, 0.04, 0.04), "l31_neon_pink", GeoKit.ALL, false)
	for x in [-4.0, 4.0]:
		k.box_mm(Vector3(x - 0.1, top, 11.6), Vector3(x + 0.1, 3.6, 15.85), "l31_paint")
	k.box_mm(Vector3(-4, top, 11.55), Vector3(4, top + 0.95, 11.7), "l31_paint")
	k.box_mm(Vector3(-4, top + 2.3, 11.55), Vector3(4, 3.6, 11.7), "l31_paint")
	k.box_mm(Vector3(-3.9, top + 0.95, 11.6), Vector3(3.9, top + 2.3, 11.64), "l31_glass", GeoKit.ALL, false)
	k.box_mm(Vector3(-4.2, 3.6, 11.4), Vector3(4.2, 3.85, 15.85), "l31_paint")
	# door from the landing in the booth's east side
	k.box_mm(Vector3(3.9, top, 11.6), Vector3(4.1, 3.6, 13.05), "l31_paint")
	k.box_mm(Vector3(3.9, top + 2.1, 13.05), Vector3(4.1, 3.6, 13.95), "l31_paint")
	k.box_mm(Vector3(3.9, top, 13.95), Vector3(4.1, 3.6, 15.85), "l31_paint")
	# railing of the landing and the stair from the concourse
	k.wall(Vector3(4.1, top, 11.62), Vector3(6.4, top, 11.62), 1.0, 0.06, "l31_steel")
	k.wall(Vector3(6.38, top, 11.62), Vector3(6.38, top, 13.5), 1.0, 0.06, "l31_steel")
	k.stairs(Vector3(8.08, 0, 14.2), Vector3(-1, 0, 0), 1.2, top, 6, "l31_paint", 0.28)
	k.box(Vector3(7.24, 0.95, 13.55), Vector3(1.7, 0.05, 0.05), "l31_steel", GeoKit.ALL, false)
	# desk, decks, mixer, record crates
	k.box_mm(Vector3(-3.0, top, 12.0), Vector3(3.0, top + 0.92, 12.7), "l31_black")
	k.box(Vector3(0, top + 0.93, 12.35), Vector3(6.0, 0.03, 0.72), "l31_steel", GeoKit.ALL, false)
	for x in [-1.6, 1.6]:
		k.cylinder(Vector3(x, top + 0.98, 12.35), 0.2, 0.04, "l31_black", 20, false)
	k.box(Vector3(0, top + 0.99, 12.35), Vector3(0.7, 0.08, 0.45), "l31_neon_green", GeoKit.ALL, false)
	for i in 6:
		k.box(Vector3(-0.25 + i * 0.1, top + 1.04, 12.3), Vector3(0.03, 0.02, 0.25), "l31_neon_red" if i % 3 == 0 else "l31_neon_yellow", GeoKit.ALL, false)
	k.box(Vector3(-2.4, top + 0.25, 14.9), Vector3(0.9, 0.5, 0.45), "l31_darkwood")
	label(L, "DJ", Vector3(0.0, 3.72, 11.38), 180.0, 120, Color(1.0, 0.3, 0.7), 8)
	for x in [-3.6, 3.6]:
		p("kenney/furniture-kit/speaker", Vector3(x, top, 12.0), 180.0, 1.5)
	p("ph/vintage_radio_transceiver", Vector3(2.4, top + 0.95, 12.4), 180.0)
	p("kenney/furniture-kit/computerscreen", Vector3(-2.4, top + 0.95, 12.45), 180.0, 0.4)
	p("ph/cardboard_box_01", Vector3(3.2, top, 15.3), 10.0)


func _concourse(k: GeoKit) -> void:
	# lockers along the south wall, benches for lacing skates, the Venosha's camp
	k.box_mm(Vector3(-26.5, 0, 15.3), Vector3(-9.0, 1.9, 15.85), "l31_locker")
	k.box(Vector3(-17.75, 1.95, 15.55), Vector3(17.5, 0.1, 0.6), "l31_paint")
	for i in 5:
		var x := -25.0 + i * 3.6
		k.box(Vector3(x, 0.42, 14.2), Vector3(2.4, 0.06, 0.4), "l31_darkwood")
		for dx in [-1.0, 1.0]:
			k.box(Vector3(x + dx, 0.2, 14.2), Vector3(0.06, 0.4, 0.34), "l31_steel", GeoKit.ALL, false)
	for i in 6:
		var z := -12.0 + i * 4.4
		if absf(z - 2.0) < 1.5:
			continue
		k.box(Vector3(-26.8, 0.42, z), Vector3(0.45, 0.06, 2.2), "l31_darkwood")
		k.box(Vector3(-27.4, 0.75, z), Vector3(0.1, 0.6, 2.2), "l31_darkwood", GeoKit.ALL, false)
	# rail-side benches on the north concourse
	for x in [-11.0, 10.0]:
		k.box(Vector3(x, 0.42, -11.4), Vector3(3.0, 0.06, 0.45), "l31_darkwood")
	for pos in [Vector3(-12.5, 0, -11.9), Vector3(11.5, 0, -11.9), Vector3(-20, 0, 14.6)]:
		p("kenney/furniture-kit/trashcan", pos, 0.0, 0.9, true)
	p("ph/WetFloorSign_01", Vector3(-5.0, 0.0, -10.0), 30.0)
	p("ph/korean_fire_extinguisher_01", Vector3(-27.75, 0.9, -6.0), 90.0)
	p("ph/fire_alarm", Vector3(-27.82, 1.5, -6.0), 90.0)
	p("ph/security_camera_01", Vector3(27.5, 5.2, 15.5), -135.0)
	p("ph/wall_clock", Vector3(0.0, 3.1, -15.82), 0.0)
	for c in [Vector3(-27.4, 4.8, -15.4), Vector3(27.4, 4.8, -15.4), Vector3(-27.4, 4.8, 15.4), Vector3(27.4, 4.8, 15.4)]:
		p("kenney/furniture-kit/speaker", c, 45.0 if c.x < 0 else -45.0, 1.1)
	# The Venosha's temporary camp (SOURCE: they have set up temporary camps)
	var camp := Vector3(-24.5, 0, -12.6)
	k.box(camp + Vector3(0, 0.05, 0), Vector3(0.8, 0.1, 2.0), "l31_cloth", GeoKit.ALL, false)
	k.box(camp + Vector3(1.1, 0.05, 0.3), Vector3(0.8, 0.1, 2.0), "l31_green", GeoKit.ALL, false)
	p("ph/old_military_crate", camp + Vector3(-1.4, 0, 1.6), 80.0, 0.0, true)
	p("ph/vintage_suitcase", camp + Vector3(2.3, 0, -1.4), 10.0)
	p("ph/plastic_bottle_gallon", camp + Vector3(-0.9, 0, -1.2), 0.0)
	p("ph/vintage_flashlight", camp + Vector3(0.3, 0.1, -0.8), 40.0)
	p("ph/propane_tank", camp + Vector3(-1.7, 0, -0.6), 0.0)
	p("kenney/food-kit/can-open", camp + Vector3(0.8, 0.0, 1.5), 0.0, 0.12)


# ------------------------------------------------------------ north rooms

func rental() -> void:
	# SOURCE: skate rental near the food court, an area with blue walls; a counter
	# with a US size chart; run by the Coach.
	var k := L.kit("SkateRental")
	k.slab(-12, -30, 2, -16, 0.0, 0.4, "l31_carpet")
	k.slab(-12.15, -30.15, 2.15, -16, 3.5, 0.3, "l31_paint")
	k.wall(Vector3(-12, 0, -30), Vector3(-12, 0, -16), 3.2, T, "l31_blue")
	k.wall(Vector3(-12, 0, -30), Vector3(2, 0, -30), 3.2, T, "l31_blue")
	k.wall(Vector3(2, 0, -30), Vector3(2, 0, -16), 3.6, T, "l31_blue", [{"at": 9.5, "w": 3.0, "h": 2.6}])
	for x in [-9.5, -5.0, -0.5]:
		k.panel(Vector3(x, 3.19, -22.0), 1.2, 0.6, "l31_fluor")
		k.panel(Vector3(x, 3.19, -26.5), 1.2, 0.6, "l31_fluor")
	# counter (customer side faces south) and a flap at its east end
	k.box_mm(Vector3(-11.0, 0, -24.4), Vector3(-1.2, 1.05, -23.7), "l31_blue")
	k.box_mm(Vector3(-11.1, 1.05, -24.5), Vector3(-1.1, 1.1, -23.6), "l31_darkwood")
	k.box(Vector3(-6.1, 0.5, -23.68), Vector3(9.8, 0.05, 0.02), "l31_neon_white", GeoKit.ALL, false)
	# cubby wall full of skates, sizes taped on
	k.box_mm(Vector3(-11.4, 0, -29.85), Vector3(-1.0, 2.6, -29.25), "l31_darkwood")
	for col in 12:
		for row in 4:
			var x := -11.0 + col * 0.84 + 0.42
			var y := 0.25 + row * 0.6
			k.box(Vector3(x, y + 0.26, -29.25), Vector3(0.8, 0.04, 0.02), "l31_rail", GeoKit.ALL, false)
			if (col * 7 + row * 3) % 9 == 0:
				continue
			for s in [-0.14, 0.14]:
				k.box(Vector3(x + s, y + 0.06, -29.4), Vector3(0.12, 0.22, 0.3), "l31_boot", GeoKit.ALL, false)
				k.box(Vector3(x + s, y - 0.08, -29.4), Vector3(0.1, 0.06, 0.26), "l31_neon_pink" if (col + row) % 3 == 0 else "l31_black", GeoKit.ALL, false)
	label(L, "SKATE RENTAL", Vector3(-6.0, 2.85, -29.2), 0.0, 90, Color(0.3, 0.7, 1.0), 6)
	label(L, "US SIZE CHART\nKIDS  10  11  12  13  1  2  3\nMEN   4  5  6  7  8  9  10  11  12  13\nWOMEN 5  6  7  8  9  10  11  12",
		Vector3(-11.83, 1.7, -21.0), 90.0, 28, Color(0.95, 0.95, 0.9))
	k.box(Vector3(-11.84, 1.7, -21.0), Vector3(0.02, 0.8, 2.2), "l31_black", GeoKit.ALL, false)
	# benches for lacing up
	for x in [-9.0, -4.5]:
		k.box(Vector3(x, 0.42, -18.0), Vector3(2.6, 0.06, 0.45), "l31_darkwood")
		for dx in [-1.1, 1.1]:
			k.box(Vector3(x + dx, 0.2, -18.0), Vector3(0.06, 0.4, 0.4), "l31_steel", GeoKit.ALL, false)
	k.commit()
	p("ph/CashRegister_01", Vector3(-2.2, 1.1, -24.05), 180.0)
	p("ph/clipboard", Vector3(-4.0, 1.1, -24.0), 170.0)
	p("ph/steel_frame_shelves_02", Vector3(-0.2, 0, -28.6), 0.0, 2.1, true)
	p("ph/cardboard_box_01", Vector3(-0.4, 0, -26.6), 25.0, 0.0, true)
	p("ph/cardboard_box_01", Vector3(-0.5, 0.34, -26.7), 60.0)
	p("ph/wall_clock", Vector3(1.82, 2.6, -25.0), -90.0)


func corridor_and_cinema() -> Array:
	# SOURCE: walking northward past TV screens leads to the small Cinema: a large
	# main television and three rows of continuous metal benches in a staircase.
	var k := L.kit("Cinema")
	k.slab(-26, -44, -22, -16, 0.0, 0.4, "l31_carpet")
	k.slab(-26.15, -44, -21.85, -16, 3.1, 0.3, "l31_paint")
	k.wall(Vector3(-26, 0, -44), Vector3(-26, 0, -16), 2.8, T, "l31_paint")
	k.wall(Vector3(-22, 0, -44), Vector3(-22, 0, -16), 2.8, T, "l31_paint")
	var tvs := []
	for i in 7:
		var z := -19.5 - i * 3.5
		for side in [-1.0, 1.0]:
			var x: float = -24.0 + side * 1.55
			var y := 1.75 + 0.25 * float((i + int(side)) % 2)
			k.box(Vector3(x + side * 0.05, y, z), Vector3(0.5, 0.48, 0.62), "l31_black")
			k.quad(Vector3(x - side * 0.205, y + 0.02, z), Vector3(-side, 0, 0), Vector3(0, 0, 0.24), Vector3(0, 0.18, 0), "l31_movie1", Vector2.ZERO, true)
			k.box(Vector3(x + side * 0.1, y - 0.3, z), Vector3(0.4, 0.04, 0.5), "l31_steel", GeoKit.ALL, false)
			tvs.append(Vector3(x - side * 0.3, y, z))
	# the cinema floor: front at -0.9, a middle tier at -0.45, the back at 0.0
	k.slab(-34, -60, -14, -44, -0.9, 0.3, "l31_carpet")
	k.box_mm(Vector3(-34, -0.9, -51.0), Vector3(-17, -0.45, -48.5), "l31_carpet")
	k.box_mm(Vector3(-34, -0.9, -48.5), Vector3(-14, 0.0, -44.0), "l31_carpet")
	k.box(Vector3(-25.5, -0.47, -51.02), Vector3(17, 0.04, 0.04), "l31_neon_violet", GeoKit.ALL, false)
	k.box(Vector3(-24.0, -0.02, -48.52), Vector3(20, 0.04, 0.04), "l31_neon_violet", GeoKit.ALL, false)
	k.stairs(Vector3(-16.0, -0.9, -53.0), Vector3(0, 0, 1), 2.0, 0.9, 6, "l31_carpet", 0.75)
	k.slab(-34.15, -60.15, -13.85, -44, 4.5, 0.3, "l31_paint")
	k.wall(Vector3(-34, -0.9, -44), Vector3(-14, -0.9, -44), 5.4, T, "l31_wall", [{"at": 10.0, "w": 4.0, "h": 2.8, "sill": 0.9}])
	k.wall(Vector3(-34, -0.9, -60), Vector3(-14, -0.9, -60), 5.4, T, "l31_paint")
	k.wall(Vector3(-34, -0.9, -60), Vector3(-34, -0.9, -44), 5.4, T, "l31_wall")
	k.wall(Vector3(-14, -0.9, -60), Vector3(-14, -0.9, -44), 5.4, T, "l31_wall")
	# the large main television
	k.box(Vector3(-24.0, 2.0, -59.75), Vector3(7.6, 4.3, 0.2), "l31_black")
	k.quad(Vector3(-24.0, 2.0, -59.63), Vector3(0, 0, 1), Vector3(3.6, 0, 0), Vector3(0, 2.02, 0), "l31_movie0", Vector2.ZERO, true)
	k.box(Vector3(-24.0, -0.4, -59.5), Vector3(5.0, 1.0, 0.5), "l31_black")
	# three continuous metal benches, all the same length
	var rows := [[-52.2, -0.9], [-49.8, -0.45], [-47.3, 0.0]]
	for r in rows:
		var z: float = r[0]
		var y: float = r[1]
		k.box(Vector3(-25.5, y + 0.44, z), Vector3(12.0, 0.05, 0.42), "l31_steel")
		k.box(Vector3(-25.5, y + 0.8, z + 0.24), Vector3(12.0, 0.45, 0.04), "l31_steel", GeoKit.ALL, false)
		for i in 7:
			k.box(Vector3(-31.3 + i * 1.95, y + 0.21, z), Vector3(0.05, 0.42, 0.36), "l31_steel", GeoKit.ALL, false)
	for z in [-57.0, -52.0, -47.0]:
		for x in [-33.83, -14.17]:
			k.box(Vector3(x, 2.2, z), Vector3(0.04, 0.3, 0.18), "l31_neon_warm", GeoKit.ALL, false)
	k.commit()
	return tvs


func food_court() -> Dictionary:
	# SOURCE: small food court: counter with pizza (cheese/pepperoni), wings, foot-long
	# hot dogs, a soda fountain with almond water; square tables and orange plastic
	# chairs; orange and green metal benches screwed in by the walls; a condiment stand
	# by the queue; trash cans by the exit under a taped sign; a door "Employees only!".
	var k := L.kit("FoodCourt")
	k.slab(2, -34, 28, -16, 0.0, 0.4, "l31_tile")
	k.slab(1.85, -34.15, 28.15, -16, 3.9, 0.3, "l31_paint")
	k.wall(Vector3(2, 0, -34), Vector3(28, 0, -34), 3.6, T, "l31_fc_wall")
	k.wall(Vector3(2, 0, -34), Vector3(2, 0, -30), 3.6, T, "l31_fc_wall")
	k.wall(Vector3(28, 0, -34), Vector3(28, 0, -16), 3.8, T, "l31_fc_wall", [{"at": 7.0, "w": 3.5, "h": 2.8}])
	k.box(Vector3(15, 1.15, -33.84), Vector3(25.6, 0.12, 0.02), "l31_red", GeoKit.ALL, false)
	for x in [6.0, 11.0, 16.0, 21.0, 25.0]:
		for z in [-19.5, -24.0]:
			k.panel(Vector3(x, 3.59, z), 1.2, 0.6, "l31_fluor")
	# counter and the kitchen line behind it
	k.box_mm(Vector3(5.0, 0, -29.4), Vector3(22.0, 1.05, -28.7), "l31_red")
	k.box_mm(Vector3(4.9, 1.05, -29.5), Vector3(22.1, 1.1, -28.6), "l31_steel")
	k.box_mm(Vector3(5.0, 0, -33.85), Vector3(22.0, 0.9, -33.1), "l31_steel")
	k.box_mm(Vector3(7.0, 0.9, -33.85), Vector3(9.4, 1.9, -33.0), "l31_steel")
	k.box(Vector3(8.2, 1.4, -32.98), Vector3(1.6, 0.35, 0.02), "l31_neon_warm", GeoKit.ALL, false)
	k.box_mm(Vector3(17.0, 0.9, -33.85), Vector3(19.2, 1.75, -33.2), "l31_black")
	for i in 6:
		k.box(Vector3(17.3 + i * 0.34, 1.35, -33.18), Vector3(0.18, 0.22, 0.02), ["l31_neon_red", "l31_neon_blue", "l31_neon_green"][i % 3], GeoKit.ALL, false)
	k.box_mm(Vector3(4.9, 2.3, -33.84), Vector3(22.1, 3.2, -33.7), "l31_black")
	label(L, "PIZZA  cheese / pepperoni        WINGS  mild · hot · fire        FOOT-LONG HOT DOGS        SODA · ALMOND WATER",
		Vector3(13.5, 2.75, -33.66), 0.0, 40, Color(1.0, 0.85, 0.45), 4)
	# queue stanchions and the condiment stand beside the queue
	for x in [10.0, 11.5, 13.0]:
		k.cylinder(Vector3(x, 0.45, -26.6), 0.03, 0.9, "l31_steel", 8, false)
	k.box(Vector3(11.5, 0.88, -26.6), Vector3(3.0, 0.04, 0.03), "l31_red", GeoKit.ALL, false)
	k.box(Vector3(14.6, 0.5, -26.4), Vector3(0.9, 1.0, 0.6), "l31_steel")
	# the Employees only! door in the north wall, east of the counter
	k.box(Vector3(25.5, 1.06, -33.82), Vector3(1.0, 2.12, 0.06), "l31_door_wood", GeoKit.ALL, false)
	for dx in [-0.56, 0.56]:
		k.box(Vector3(25.5 + dx, 1.1, -33.8), Vector3(0.1, 2.2, 0.08), "l31_steel", GeoKit.ALL, false)
	k.box(Vector3(25.85, 1.0, -33.76), Vector3(0.14, 0.06, 0.06), "l31_steel", GeoKit.ALL, false)
	label(L, "EMPLOYEES ONLY!", Vector3(25.5, 1.62, -33.77), 0.0, 34, Color(0.95, 0.1, 0.08))
	# trash cans by the exit (into the rink hall) and the taped sign over them
	k.box(Vector3(8.6, 1.55, -16.17), Vector3(1.4, 0.45, 0.01), "paper", GeoKit.ALL, false)
	label(L, "Please throw away trash\nand uneaten food here!", Vector3(8.6, 1.55, -16.19), 180.0, 22, Color(0.1, 0.1, 0.1))
	# metal park benches screwed in along the walls, orange and green
	var benches := [[Vector3(3.0, 0, -24.5), 90.0, "l31_orange"], [Vector3(3.0, 0, -27.6), 90.0, "l31_green"],
		[Vector3(27.0, 0, -20.0), -90.0, "l31_orange"], [Vector3(20.0, 0, -16.9), 180.0, "l31_green"], [Vector3(24.5, 0, -16.9), 180.0, "l31_orange"]]
	for b in benches:
		var c: Vector3 = b[0]
		var bas := Basis(Vector3.UP, deg_to_rad(float(b[1])))
		var xf := Transform3D(bas, c)
		k.box_xf(xf * Transform3D(Basis(), Vector3(0, 0.45, 0)), Vector3(2.4, 0.05, 0.5), b[2])
		k.box_xf(xf * Transform3D(Basis(), Vector3(0, 0.8, 0.24)), Vector3(2.4, 0.4, 0.04), b[2], GeoKit.ALL, false)
		for dx in [-1.0, 1.0]:
			k.box_xf(xf * Transform3D(Basis(), Vector3(dx, 0.22, 0)), Vector3(0.05, 0.44, 0.45), "l31_steel", GeoKit.ALL, false)
	# square tables in the middle
	var tables := []
	for i in 4:
		for j in 2:
			var c := Vector3(8.0 + i * 4.0, 0, -24.2 + j * 4.2)
			tables.append(c)
			k.box(c + Vector3(0, 0.74, 0), Vector3(1.0, 0.04, 1.0), "l31_fc_wall")
			k.cylinder(c + Vector3(0, 0.37, 0), 0.05, 0.72, "l31_steel", 8, false)
			k.box(c + Vector3(0, 0.37, 0), Vector3(0.12, 0.74, 0.12), "l31_steel", GeoKit.ALL, true)
	k.commit()
	var orange := MatLib.standard(Color(0.95, 0.42, 0.08), 0.45)
	var r := RandomNumberGenerator.new()
	r.seed = 3131
	for c in tables:
		for a in 4:
			if (int(c.x) + a) % 5 == 4:
				continue
			var dir := Vector3(sin(a * PI * 0.5), 0, cos(a * PI * 0.5))
			var ch := p("ph/plastic_monobloc_chair_01", c + dir * 0.78, rad_to_deg(atan2(dir.x, dir.z)) + r.randf_range(-12, 12))
			if ch:
				tint(ch, orange)
	p("ph/CashRegister_01", Vector3(19.5, 1.1, -29.05), 0.0)
	p("ph/CashRegister_01", Vector3(9.0, 1.1, -29.05), 0.0)
	p("kenney/food-kit/pizza", Vector3(12.0, 1.1, -29.0), 15.0, 0.03)
	p("kenney/food-kit/pizza-box", Vector3(13.4, 1.1, -29.1), -10.0, 0.08)
	p("kenney/food-kit/pizza-box", Vector3(13.4, 1.18, -29.1), 12.0, 0.08)
	for i in 4:
		p("kenney/food-kit/soda-bottle", Vector3(14.35 + i * 0.18, 1.0, -26.4), 0.0, 0.24)
	p("kenney/food-kit/cup", Vector3(15.6, 1.1, -29.0), 0.0, 0.16)
	p("kenney/food-kit/soda-can", Vector3(11.8, 0.76, -20.0), 0.0, 0.12)
	p("kenney/food-kit/plate", Vector3(15.8, 0.76, -24.3), 0.0, 0.02)
	for x in [7.6, 8.6, 9.6]:
		p("kenney/furniture-kit/trashcan", Vector3(x, 0, -16.7), 0.0, 0.95, true)
	p("kenney/furniture-kit/kitchenfridgelarge", Vector3(20.6, 0, -33.4), 0.0, 1.9, true)
	p("kenney/furniture-kit/kitchenmicrowave", Vector3(10.6, 0.9, -33.5), 0.0, 0.3)
	p("ph/WetFloorSign_01", Vector3(22.8, 0.0, -27.0), -20.0)
	return {"tables": tables}
