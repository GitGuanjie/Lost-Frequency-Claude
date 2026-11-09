extends RefCounted
## Level 20 Waiting halls (SOURCE: white concrete, brown carpet, grey tiled
## ceiling; lockers, trash cans, couches, tables, chairs, empty reception desks,
## water fountains pouring Almond Water, vending machines; windows onto a black
## void with stars and an occasional moon). Floor y = 0, ceiling 3.0 m.
## Plan (metres, north = -Z):
##   W1 main hall   x -2.5..2.5,  z 6..-48 (blue FUN ZONE doors at the south end)
##   Lobby (west)   x -18..-2.5,  z -4..-20 (reception desk, waiting rows, staff door)
##   Gallery (east) x 2.5..16,    z -14..-36 (tall windows in the east wall, x = 16)
##   W2 cross hall  x -30..14,    z -44..-48 (lockers; the Electric opens north at x = 10)

const H := 3.0
const T := 0.3
const WINDOW_ZS := [-17.4, -21.8, -26.2, -30.6]
const WINDOW_X := 16.0
const STAFF_DOOR := Vector3(-18.0, 0.0, -16.0)
const BROKEN_DOOR := Vector3(-30.0, 0.0, -46.0)
const ELECTRIC_DOOR := Vector3(10.0, 0.0, -48.0)

var L: LevelBase
var props: Node3D
var k: GeoKit
var lockers: Array = []      # [{pos, yaw, node(door pivot), used}]
var fountains: Array = []    # [Vector3]
var vending: Array = []      # [Vector3]
var panels: Array = []       # light anchor positions


func _init(level: LevelBase, props_root: Node3D) -> void:
	L = level
	props = props_root


func p(id: String, pos: Vector3, yaw: float = 0.0, h: float = 0.0, collide: bool = false) -> Node3D:
	return Props.place(L, props, id, pos, yaw, h, collide)


static func materials() -> void:
	MatLib.define("l20_wall", {"albedo_a": Color(0.84, 0.84, 0.82), "albedo_b": Color(0.77, 0.77, 0.75), "noise_scale": 1.3,
		"stain_amount": 0.12, "stain_color": Color(0.62, 0.6, 0.56), "grime_height": 0.22, "grime_color": Color(0.55, 0.52, 0.48),
		"roughness_a": 0.85, "roughness_b": 0.95, "bump_strength": 0.45}, "concrete")
	MatLib.define("l20_carpet", {"albedo_a": Color(0.25, 0.15, 0.08), "albedo_b": Color(0.20, 0.12, 0.06), "pattern": 6,
		"pattern_scale": Vector2(0.5, 0.5), "pattern_color": Color(0.32, 0.2, 0.11), "pattern_strength": 0.3, "noise_scale": 0.7,
		"stain_amount": 0.25, "stain_color": Color(0.16, 0.09, 0.05), "roughness_a": 0.98, "roughness_b": 1.0, "bump_strength": 0.6})
	MatLib.define("l20_ceiling", {"albedo_a": Color(0.46, 0.47, 0.48), "albedo_b": Color(0.41, 0.42, 0.43), "pattern": 7,
		"pattern_scale": Vector2(0.61, 0.61), "grout_width": 0.012, "grout_color": Color(0.30, 0.31, 0.32), "stain_amount": 0.15,
		"stain_color": Color(0.36, 0.33, 0.28), "roughness_a": 0.9, "roughness_b": 1.0, "noise_scale": 0.7, "tile_variation": 0.04})
	MatLib.define("l20_trim", {"albedo_a": Color(0.30, 0.30, 0.31), "albedo_b": Color(0.26, 0.26, 0.27), "roughness_a": 0.5,
		"roughness_b": 0.7, "noise_scale": 0.5})
	MatLib.define("l20_locker", {"albedo_a": Color(0.36, 0.45, 0.55), "albedo_b": Color(0.32, 0.40, 0.50), "pattern": 2,
		"pattern_scale": Vector2(0.05, 1.0), "pattern_color": Color(0.22, 0.28, 0.34), "pattern_strength": 0.2, "metallic_value": 0.5,
		"roughness_a": 0.45, "roughness_b": 0.6, "stain_amount": 0.15, "stain_color": Color(0.3, 0.25, 0.2), "noise_scale": 2.0}, "metal")
	MatLib.define("l20_steel", {"albedo_a": Color(0.70, 0.71, 0.72), "albedo_b": Color(0.62, 0.63, 0.65), "metallic_value": 0.85,
		"roughness_a": 0.25, "roughness_b": 0.4}, "metal")
	MatLib.define("l20_bluedoor", {"albedo_a": Color(0.07, 0.24, 0.62), "albedo_b": Color(0.06, 0.20, 0.55), "roughness_a": 0.4,
		"roughness_b": 0.55, "noise_scale": 1.0, "stain_amount": 0.1})
	MatLib.define("l20_door", {"albedo_a": Color(0.56, 0.57, 0.58), "albedo_b": Color(0.50, 0.51, 0.52), "roughness_a": 0.5,
		"roughness_b": 0.6, "metallic_value": 0.3})
	MatLib.define("l20_desk", {"albedo_a": Color(0.42, 0.30, 0.20), "albedo_b": Color(0.36, 0.25, 0.16), "pattern": 3,
		"pattern_scale": Vector2(1.4, 0.18), "grout_width": 0.002, "roughness_a": 0.45, "roughness_b": 0.6}, "wood_floor")
	MatLib.define("l20_vend_red", {"albedo_a": Color(0.55, 0.05, 0.05), "albedo_b": Color(0.48, 0.04, 0.04), "roughness_a": 0.35,
		"roughness_b": 0.5, "metallic_value": 0.2})
	MatLib.define("l20_vend_blue", {"albedo_a": Color(0.05, 0.12, 0.42), "albedo_b": Color(0.04, 0.1, 0.36), "roughness_a": 0.35,
		"roughness_b": 0.5, "metallic_value": 0.2})
	MatLib.define("l20_black", {"albedo_a": Color(0.03, 0.03, 0.035), "albedo_b": Color(0.02, 0.02, 0.025), "roughness_a": 0.4,
		"roughness_b": 0.6})
	MatLib.define("l20_snack", {"albedo_a": Color(0.8, 0.55, 0.1), "albedo_b": Color(0.2, 0.5, 0.75), "noise_scale": 9.0,
		"noise_mix": 1.0, "roughness_a": 0.4, "roughness_b": 0.5})
	MatLib.define("l20_frame", {"albedo_a": Color(0.18, 0.18, 0.19), "albedo_b": Color(0.15, 0.15, 0.16), "metallic_value": 0.6,
		"roughness_a": 0.35, "roughness_b": 0.5})
	MatLib.define("l20_gel", {"albedo_a": Color(0.95, 0.38, 0.02), "albedo_b": Color(0.85, 0.30, 0.01), "roughness_a": 0.08,
		"roughness_b": 0.15, "emission_color": Color(0.5, 0.12, 0.0), "emission_energy": 0.25, "noise_scale": 3.0})
	MatLib.register("l20_panel", MatLib.panel(Color(0.92, 0.96, 1.0), 2.6))
	MatLib.register("l20_panel_dead", MatLib.panel(Color(0.5, 0.52, 0.55), 0.05))
	MatLib.register("l20_vend_glow", MatLib.panel(Color(0.95, 0.92, 0.85), 1.4))
	MatLib.register("l20_exitsign", MatLib.panel(Color(0.2, 1.0, 0.35), 2.2))
	MatLib.register("l20_almond", MatLib.panel(Color(0.95, 0.88, 0.7), 0.5))
	var g := StandardMaterial3D.new()
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.albedo_color = Color(0.8, 0.85, 0.9, 0.04)
	g.roughness = 0.02
	g.metallic_specular = 0.25
	MatLib.register("l20_glass", g)
	var sh := Shader.new()
	sh.code = VOID_SHADER
	var vm := ShaderMaterial.new()
	vm.shader = sh
	MatLib.register("l20_void", vm)


const VOID_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled, shadows_disabled;
uniform vec3 moon_dir = vec3(0.86, 0.26, -0.44);
float h3(vec3 p) { p = fract(p * 0.3183099 + 0.1); p *= 17.0; return fract(p.x * p.y * p.z * (p.x + p.y + p.z)); }
float layer(vec3 d, float sc, float th, float sz) {
	vec3 q = d * sc;
	vec3 c = floor(q);
	vec3 f = fract(q) - 0.5;
	float r = h3(c);
	if (r < th) return 0.0;
	vec3 o = vec3(h3(c + 3.1), h3(c + 7.7), h3(c + 1.3)) - 0.5;
	return smoothstep(sz, 0.0, length(f - o * 0.6)) * (0.5 + 0.5 * h3(c + 9.0));
}
void fragment() {
	vec3 d = normalize((INV_VIEW_MATRIX * vec4(VERTEX, 0.0)).xyz);
	float s = layer(d, 60.0, 0.9, 0.26) * 1.6 + layer(d, 140.0, 0.88, 0.3) * 0.9 + layer(d, 28.0, 0.975, 0.16) * 3.0;
	float neb = 0.012 * smoothstep(0.4, 1.0, sin(d.x * 3.0 + d.y * 5.0) * sin(d.z * 4.0 - d.y * 2.0));
	vec3 col = vec3(s) * vec3(0.85, 0.9, 1.0) + vec3(neb * 0.6, neb * 0.7, neb);
	vec3 md = normalize(moon_dir);
	float m = dot(d, md);
	if (m > 0.9986) {
		vec3 lit = normalize(md + vec3(-0.6, 0.5, -0.2));
		vec3 n = normalize(d - md * 0.9986);
		col = vec3(0.78, 0.78, 0.74) * (0.25 + 0.75 * smoothstep(-0.2, 0.6, dot(n, lit)));
	} else {
		col += vec3(0.5, 0.55, 0.6) * smoothstep(0.996, 0.9986, m) * 0.08;
	}
	ALBEDO = col;
}
"""


func build() -> void:
	k = L.kit("WaitingHalls")
	# floors (one slab per room, slightly overlapping) and ceilings
	k.slab(-2.5, 6.2, 2.5, -48.3, 0.0, 0.3, "l20_carpet")
	k.slab(-18.2, -3.8, -2.5, -20.2, 0.0, 0.3, "l20_carpet")
	k.slab(2.5, -13.8, 16.2, -36.2, 0.0, 0.3, "l20_carpet")
	k.slab(-30.2, -43.8, 14.2, -48.3, 0.0, 0.3, "l20_carpet")
	for r in [[-2.6, 6.2, 2.6, -48.2], [-18.2, -3.8, -2.4, -20.2], [2.4, -13.8, 16.2, -36.2], [-30.2, -43.8, 14.2, -48.2]]:
		k.box_mm(Vector3(r[0], H, r[3]), Vector3(r[2], H + 0.25, r[1]), "l20_ceiling", GeoKit.NY | GeoKit.PY, false)
	_walls()
	_ceiling_panels()
	_windows()
	_lobby()
	_gallery()
	_halls_dressing()
	k.commit()


func _walls() -> void:
	# W1 west wall (lobby openings), east wall (gallery openings), south end
	k.wall(Vector3(-2.5, 0, 6), Vector3(-2.5, 0, -44), H, T, "l20_wall", [{"at": 13.0, "w": 3.2, "h": 2.5}, {"at": 21.0, "w": 3.2, "h": 2.5}])
	k.wall(Vector3(2.5, 0, 6), Vector3(2.5, 0, -44), H, T, "l20_wall", [{"at": 25.0, "w": 3.0, "h": 2.5}, {"at": 35.0, "w": 3.0, "h": 2.5}])
	k.wall(Vector3(-2.65, 0, 6), Vector3(2.65, 0, 6), H, T, "l20_wall", [{"at": 2.65, "w": 1.9, "h": 2.3}])
	# lobby
	k.wall(Vector3(-18, 0, -4), Vector3(-2.5, 0, -4), H, T, "l20_wall")
	k.wall(Vector3(-18, 0, -20), Vector3(-2.5, 0, -20), H, T, "l20_wall")
	k.wall(Vector3(-18, 0, -3.85), Vector3(-18, 0, -20.15), H, T, "l20_wall", [{"at": 12.15, "w": 1.1, "h": 2.15}])
	# gallery: the east wall is built by _windows()
	k.wall(Vector3(2.5, 0, -14), Vector3(16, 0, -14), H, T, "l20_wall")
	k.wall(Vector3(2.5, 0, -36), Vector3(16, 0, -36), H, T, "l20_wall")
	# W2 cross hall: south wall (W1 joins at x -2.5..2.5), north wall (Electric door at x = 10)
	k.wall(Vector3(-30, 0, -44), Vector3(-2.5, 0, -44), H, T, "l20_wall")
	k.wall(Vector3(2.5, 0, -44), Vector3(14, 0, -44), H, T, "l20_wall")
	k.wall(Vector3(-30.15, 0, -48), Vector3(14.15, 0, -48), H, T, "l20_wall", [{"at": 40.15, "w": 2.6, "h": 2.6}])
	k.wall(Vector3(14, 0, -43.85), Vector3(14, 0, -48.15), H, T, "l20_wall")
	k.wall(Vector3(-30, 0, -43.85), Vector3(-30, 0, -48.15), H, T, "l20_wall", [{"at": 2.15, "w": 1.1, "h": 2.15}])
	# skirting along the main walls
	for seg in [[Vector3(-2.33, 0.06, -19), 50.0, true], [Vector3(2.33, 0.06, -19), 50.0, true]]:
		k.box(seg[0], Vector3(0.04, 0.12, seg[1]), "l20_trim", GeoKit.ALL, false)
	# the blue FUN ZONE double door you came in by (closed, south end)
	k.box(Vector3(-0.46, 1.12, 6.0), Vector3(0.88, 2.24, 0.08), "l20_bluedoor", GeoKit.ALL, true)
	k.box(Vector3(0.46, 1.12, 6.0), Vector3(0.88, 2.24, 0.08), "l20_bluedoor", GeoKit.ALL, true)
	k.box(Vector3(0, 2.33, 5.95), Vector3(2.0, 0.12, 0.2), "l20_trim", GeoKit.ALL, false)
	for x in [-0.12, 0.12]:
		k.box(Vector3(x, 1.05, 5.93), Vector3(0.04, 0.3, 0.05), "l20_steel", GeoKit.ALL, false)
	_label("FUN ZONE", Vector3(0, 1.75, 5.94), 180.0, 120, Color(0.95, 0.97, 1.0))
	# staff-only door (Level 2) in the lobby's west wall, the broken door at the W2 west end
	k.box(STAFF_DOOR + Vector3(0.0, 1.07, 0), Vector3(0.06, 2.14, 1.06), "l20_door", GeoKit.ALL, true)
	k.box(STAFF_DOOR + Vector3(0.06, 1.0, 0.38), Vector3(0.05, 0.05, 0.16), "l20_steel", GeoKit.ALL, false)
	_label("STAFF ONLY", STAFF_DOOR + Vector3(0.05, 1.6, 0), 90.0, 44, Color(0.15, 0.15, 0.17))
	k.box_xf(Transform3D(Basis(Vector3.UP, 0.55), BROKEN_DOOR + Vector3(0.45, 1.05, 0.35)), Vector3(0.05, 2.1, 1.0), "l20_door", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.FORWARD, 0.1), BROKEN_DOOR + Vector3(0.1, 2.2, 0)), Vector3(0.2, 0.08, 1.1), "l20_trim", GeoKit.ALL, false)
	k.box(BROKEN_DOOR + Vector3(-0.5, 1.07, 0), Vector3(0.6, 2.14, 1.2), "unlit_black", GeoKit.PX, false)


func _ceiling_panels() -> void:
	var spots: Array = []
	for z in range(4, -46, -5):
		spots.append(Vector3(0, H - 0.01, z))
	for x in [-14.0, -9.0, -5.0]:
		for z in [-8.0, -16.0]:
			spots.append(Vector3(x, H - 0.01, z))
	for x in [6.0, 11.0]:
		for z in [-18.0, -25.0, -32.0]:
			spots.append(Vector3(x, H - 0.01, z))
	for x in range(-26, 14, 6):
		spots.append(Vector3(x, H - 0.01, -46))
	var i := 0
	for s in spots:
		i += 1
		var dead: bool = (i % 9) == 4
		k.box(s + Vector3(0, 0.02, 0), Vector3(0.66, 0.04, 1.26), "l20_trim", GeoKit.NY, false)
		k.panel(s, 0.6, 1.2, "l20_panel_dead" if dead else "l20_panel", float(i), 0.0)
		if not dead:
			panels.append(s + Vector3(0, -0.25, 0))


func _windows() -> void:
	# East wall of the gallery: four tall windows. Beyond: the black void with stars.
	var ops: Array = []
	for z in WINDOW_ZS:
		ops.append({"at": -14.0 - z + 0.0, "w": 2.6, "h": 2.25, "sill": 0.35})
	k.wall(Vector3(WINDOW_X, 0, -14), Vector3(WINDOW_X, 0, -36), H, T, "l20_wall", ops)
	for z in WINDOW_ZS:
		k.box(Vector3(WINDOW_X, 1.475, z), Vector3(0.04, 2.25, 2.6), "l20_glass", GeoKit.ALL, true)
		k.box(Vector3(WINDOW_X - 0.18, 0.37, z), Vector3(0.12, 0.05, 2.7), "l20_frame", GeoKit.ALL, false)
		k.box(Vector3(WINDOW_X, 2.6, z), Vector3(0.34, 0.06, 2.7), "l20_frame", GeoKit.ALL, false)
		k.box(Vector3(WINDOW_X, 1.475, z), Vector3(0.34, 2.25, 0.06), "l20_frame", GeoKit.ALL, false)
		for s in [-1.0, 1.0]:
			k.box(Vector3(WINDOW_X, 1.475, z + s * 1.3), Vector3(0.34, 2.25, 0.05), "l20_frame", GeoKit.ALL, false)
	# the void: a large unlit shell outside the east wall
	k.box_mm(Vector3(16.25, -40, -70), Vector3(90, 40, 20), "l20_void", GeoKit.ALL, false)


func _lobby() -> void:
	# empty reception desk facing the waiting rows, staff door behind it
	var d := Vector3(-14.6, 0, -12.0)
	k.box(d + Vector3(0, 0.55, 0), Vector3(0.7, 1.1, 3.4), "l20_desk", GeoKit.ALL, true)
	k.box(d + Vector3(0.05, 1.12, 0), Vector3(0.85, 0.05, 3.6), "l20_trim", GeoKit.ALL, false)
	k.box(d + Vector3(-0.9, 0.38, 1.4), Vector3(0.6, 0.76, 0.8), "l20_desk", GeoKit.ALL, true)
	p("ph/classic_laptop", d + Vector3(-0.1, 1.145, -0.8), 90.0)
	p("ph/clipboard", d + Vector3(0.1, 1.145, 0.6), 80.0)
	p("ph/office_notepads", d + Vector3(-1.05, 0.76, 1.4), 0.0, 0.0)
	p("ph/SchoolChair_01", d + Vector3(-1.1, 0, -0.6), -90.0)
	p("ph/wall_clock", Vector3(-17.82, 2.3, -9.0), 90.0)
	# waiting rows facing the desk
	for row in 3:
		for j in 6:
			var c := Vector3(-11.0 + row * 2.0, 0, -7.0 - j * 0.75 - (1.2 if j > 2 else 0.0))
			p("ph/SchoolChair_01" if (row + j) % 5 != 3 else "ph/GreenChair_01", c, -90.0 + (j % 3) * 4.0 - 4.0, 0.0, false)
	p("ph/Sofa_01", Vector3(-6.0, 0, -19.4), 0.0, 0.0, true)
	p("ph/Sofa_01", Vector3(-9.5, 0, -19.4), 0.0, 0.0, true)
	p("ph/coffee_table_round_01", Vector3(-7.7, 0, -17.8), 0.0, 0.0, true)
	p("ph/binder_notebook", Vector3(-7.6, 0.49, -17.7), 30.0)
	p("ph/ArmChair_01", Vector3(-4.0, 0, -18.6), 30.0, 0.0, true)
	p("ph/Television_01", Vector3(-3.2, 1.6, -4.5), 200.0)
	k.box(Vector3(-3.2, 1.58, -4.3), Vector3(0.7, 0.04, 0.5), "l20_frame", GeoKit.ALL, false)
	p("kenney/furniture-kit/trashcan", Vector3(-17.4, 0, -19.2), 0.0, 0.7, true)
	p("kenney/furniture-kit/trashcan", Vector3(-3.2, 0, -12.0), 0.0, 0.7, true)
	p("ph/fire_alarm", Vector3(-17.84, 1.4, -18.2), 90.0)
	p("ph/security_camera_01", Vector3(-17.6, 2.7, -4.4), 135.0)
	locker_row(Vector3(-17.7, 0, -5.0), 90.0, 3, Vector3(0, 0, -0.5))


func _gallery() -> void:
	# a viewing lounge facing the windows: couches and low tables, cold even to look at
	for z in [-19.6, -28.4]:
		p("ph/Sofa_01", Vector3(11.0, 0, z), -90.0, 0.0, true)
		p("ph/coffee_table_round_01", Vector3(12.8, 0, z), 0.0, 0.0, true)
	p("ph/ArmChair_01", Vector3(10.4, 0, -24.0), -70.0, 0.0, true)
	p("ph/ArmChair_01", Vector3(10.4, 0, -33.6), -110.0, 0.0, true)
	p("kenney/furniture-kit/trashcan", Vector3(3.0, 0, -35.4), 0.0, 0.7, true)
	p("ph/plastic_monobloc_chair_01", Vector3(14.6, 0, -35.0), 200.0)
	p("ph/WetFloorSign_01", Vector3(8.6, 0, -22.4), 25.0)
	for z in [-18.6, -24.0, -29.6]:
		p("ph/Sofa_01", Vector3(7.0, 0, z), -90.0, 0.0, true)
	p("ph/coffee_table_round_01", Vector3(8.7, 0, -21.4), 0.0, 0.0, true)
	p("ph/GreenChair_01", Vector3(8.4, 0, -33.0), -60.0)
	p("ph/SchoolChair_01", Vector3(13.4, 0, -15.4), 160.0)
	p("ph/binder_notebook", Vector3(12.8, 0.49, -28.3), 70.0)
	p("ph/ceiling_fan", Vector3(9.0, 2.48, -25.0), 0.0)
	locker_row(Vector3(4.6, 0, -14.4), 0.0, 10, Vector3(0.5, 0, 0))
	locker_row(Vector3(4.6, 0, -35.6), 180.0, 6, Vector3(0.5, 0, 0))
	fountain(Vector3(2.85, 0, -16.5), 90.0)
	vending_machine(Vector3(3.3, 0, -24.8), 90.0, "l20_vend_blue")


func _halls_dressing() -> void:
	# W1: vending machines, fountains, benches, bins along the walls
	vending_machine(Vector3(1.85, 0, -3.0), -90.0, "l20_vend_red")
	vending_machine(Vector3(1.85, 0, -4.05), -90.0, "l20_vend_blue")
	fountain(Vector3(-2.15, 0, -1.5), 90.0)
	fountain(Vector3(-2.15, 0, -38.0), 90.0)
	p("kenney/furniture-kit/benchcushion", Vector3(-1.95, 0, -27.0), 90.0, 0.5, true)
	p("kenney/furniture-kit/trashcan", Vector3(2.1, 0, 3.2), 0.0, 0.7, true)
	p("kenney/furniture-kit/trashcan", Vector3(-2.1, 0, -31.5), 0.0, 0.7, true)
	p("ph/Sofa_01", Vector3(-2.0, 0, -34.5), 90.0, 0.0, true)
	p("ph/ArmChair_01", Vector3(1.95, 0, 1.2), -95.0, 0.0, true)
	p("ph/ArmChair_01", Vector3(1.95, 0, -0.2), -80.0, 0.0, true)
	p("ph/SchoolChair_01", Vector3(-1.9, 0, -3.4), 80.0)
	p("ph/plastic_monobloc_chair_01", Vector3(-1.8, 0, -4.4), 110.0)
	p("ph/Sofa_01", Vector3(2.0, 0, -33.8), -90.0, 0.0, true)
	p("ph/SchoolDesk_01", Vector3(-1.95, 0, -24.0), 90.0, 0.0, true)
	p("ph/SchoolChair_01", Vector3(-1.2, 0, -24.1), -100.0)
	p("ph/plastic_monobloc_chair_01", Vector3(1.9, 0, -8.2), -120.0)
	p("ph/plastic_monobloc_chair_01", Vector3(1.85, 0, -9.0), -70.0)
	p("kenney/furniture-kit/trashcan", Vector3(2.1, 0, -22.0), 0.0, 0.7, true)
	p("ph/GreenChair_01", Vector3(-1.9, 0, -11.2), 95.0)
	p("ph/fire_alarm", Vector3(2.33, 1.4, 4.0), -90.0)
	p("ph/korean_fire_extinguisher_01", Vector3(2.2, 0, -10.0), -90.0)
	p("ph/wall_clock", Vector3(-2.33, 2.4, -24.0), 90.0)
	locker_row(Vector3(-2.2, 0, -18.2), 90.0, 6, Vector3(0, 0, -0.5))
	locker_row(Vector3(2.2, 0, -12.0), -90.0, 8, Vector3(0, 0, -0.5))
	locker_row(Vector3(-2.2, 0, -40.5), 90.0, 6, Vector3(0, 0, -0.5))
	locker_row(Vector3(2.2, 0, -37.8), -90.0, 8, Vector3(0, 0, -0.5))
	# W2 cross hall: long locker banks (deeper from the entrance = better stocked)
	locker_row(Vector3(-28.0, 0, -44.3), 180.0, 18, Vector3(0.5, 0, 0))
	locker_row(Vector3(-29.0, 0, -47.7), 0.0, 10, Vector3(0.5, 0, 0))
	locker_row(Vector3(3.6, 0, -44.3), 180.0, 10, Vector3(0.5, 0, 0))
	vending_machine(Vector3(-16.0, 0, -47.4), 0.0, "l20_vend_red")
	vending_machine(Vector3(-15.0, 0, -47.4), 0.0, "l20_vend_red")
	fountain(Vector3(-12.6, 0, -47.75), 0.0)
	p("ph/Sofa_01", Vector3(-8.8, 0, -47.3), 0.0, 0.0, true)
	p("kenney/furniture-kit/trashcan", Vector3(-6.6, 0, -47.5), 0.0, 0.7, true)
	p("ph/SchoolDesk_01", Vector3(6.5, 0, -47.2), 0.0, 0.0, true)
	# a second empty reception desk in the cross hall
	k.box(Vector3(-21.0, 0.55, -46.9), Vector3(3.0, 1.1, 0.7), "l20_desk", GeoKit.ALL, true)
	k.box(Vector3(-21.0, 1.12, -46.85), Vector3(3.2, 0.05, 0.85), "l20_trim", GeoKit.ALL, false)
	p("ph/SchoolChair_01", Vector3(-21.4, 0, -47.6), 0.0)
	p("ph/wall_clock", Vector3(-21.0, 2.3, -47.83), 0.0)
	p("ph/Sofa_01", Vector3(-4.5, 0, -44.6), 180.0, 0.0, true)
	p("ph/ArmChair_01", Vector3(1.0, 0, -47.2), 10.0, 0.0, true)
	p("ph/SchoolChair_01", Vector3(6.5, 0, -46.4), 180.0)
	p("ph/WetFloorSign_01", Vector3(-20.0, 0, -45.8), 70.0)
	p("ph/security_camera_01", Vector3(13.6, 2.7, -44.4), -135.0)
	fountain(Vector3(13.65, 0, -46.0), -90.0)


func locker_row(start: Vector3, yaw: float, count: int, step: Vector3) -> void:
	var bas := Basis(Vector3.UP, deg_to_rad(yaw))
	for i in count:
		var c := start + step * i
		var xf := Transform3D(bas, c)
		k.box_xf(xf * Transform3D(Basis(), Vector3(0, 0.95, 0.0)), Vector3(0.48, 1.9, 0.45), "l20_locker", GeoKit.ALL, true)
		k.box_xf(xf * Transform3D(Basis(), Vector3(0, 0.05, -0.02)), Vector3(0.5, 0.1, 0.42), "l20_black", GeoKit.ALL, false)
		# hinged door (its own node so it can swing open)
		var pivot := Node3D.new()
		pivot.transform = xf * Transform3D(Basis(), Vector3(-0.22, 0, 0.235))
		props.add_child(pivot)
		var door := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.44, 1.72, 0.02)
		door.mesh = bm
		door.position = Vector3(0.22, 1.0, 0)
		door.material_override = MatLib.get_mat("l20_locker")
		pivot.add_child(door)
		var vent := MeshInstance3D.new()
		var vm := BoxMesh.new()
		vm.size = Vector3(0.28, 0.18, 0.012)
		vent.mesh = vm
		vent.position = Vector3(0.22, 1.6, 0.012)
		vent.material_override = MatLib.get_mat("l20_black")
		pivot.add_child(vent)
		lockers.append({"pos": xf * Vector3(0, 1.1, 0.33), "yaw": yaw, "node": pivot, "used": false})


func vending_machine(c: Vector3, yaw: float, body: String) -> void:
	var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), c)
	k.box_xf(xf * Transform3D(Basis(), Vector3(0, 0.95, 0)), Vector3(0.95, 1.9, 0.8), body, GeoKit.ALL, true)
	k.box_xf(xf * Transform3D(Basis(), Vector3(-0.1, 1.15, 0.402)), Vector3(0.62, 1.3, 0.01), "l20_vend_glow", GeoKit.ALL, false)
	for r in 5:
		k.box_xf(xf * Transform3D(Basis(), Vector3(-0.1, 0.62 + r * 0.25, 0.38)), Vector3(0.58, 0.1, 0.04), "l20_snack", GeoKit.ALL, false)
	k.box_xf(xf * Transform3D(Basis(), Vector3(0.33, 1.2, 0.405)), Vector3(0.18, 0.5, 0.01), "l20_black", GeoKit.ALL, false)
	k.box_xf(xf * Transform3D(Basis(), Vector3(-0.1, 0.28, 0.405)), Vector3(0.6, 0.2, 0.01), "l20_black", GeoKit.ALL, false)
	vending.append(xf * Vector3(0, 1.2, 0.8))


func fountain(c: Vector3, yaw: float) -> void:
	var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), c)
	k.box_xf(xf * Transform3D(Basis(), Vector3(0, 0.82, 0.05)), Vector3(0.5, 0.16, 0.42), "l20_steel", GeoKit.ALL, true)
	k.box_xf(xf * Transform3D(Basis(), Vector3(0, 0.45, -0.08)), Vector3(0.22, 0.6, 0.16), "l20_steel", GeoKit.ALL, false)
	k.box_xf(xf * Transform3D(Basis(), Vector3(0, 0.905, 0.07)), Vector3(0.36, 0.01, 0.26), "l20_almond", GeoKit.ALL, false)
	k.box_xf(xf * Transform3D(Basis(), Vector3(0.12, 0.95, 0.1)), Vector3(0.03, 0.08, 0.03), "l20_steel", GeoKit.ALL, false)
	fountains.append(xf * Vector3(0, 1.0, 0.3))


func _label(text: String, pos: Vector3, yaw: float, size: int, col: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.004
	l.modulate = col
	l.position = pos
	l.rotation.y = deg_to_rad(yaw)
	l.double_sided = false
	props.add_child(l)
	return l
