extends RefCounted
## Level 256 geometry: an abandoned technology demonstration and exhibition
## centre (SOURCE), entirely indoors, modern, neon blue, with big windows onto
## a featureless dark (SOURCE). The plan is ours (ADAPTATION; the page gives
## no map):
##  - the Atrium, 32 x 24 m and 9 m high, its whole north side one curtain
##    wall of black glass; exhibition islands of branded terminals, a screen
##    totem, suspended neon rings and a "light forest" of hanging tubes;
##  - the Gallery, a mezzanine at +4.5 m along the east side, reached by a
##    wide stair; you arrive up there, out of the east wall (from Level 4);
##  - the Corridor of locked doors to the south, clocks above the doors;
##  - the Viewer Room (west), where screens show you to yourself;
##  - the Theatre (west), a sunken auditorium (-1.8 m) facing a wall-sized
##    screen that runs an early 3D demo with a sine scroller.
## Every door is a leaf on a solid wall (SOURCE: locked; more wall behind).

const H := 9.0                   # atrium ceiling
const GAL_Y := 4.5               # gallery floor
const GAL_X := 10.5              # gallery inner edge
const GAL_Z1 := 2.6              # gallery south edge (stair top)
const COR_H := 3.0
const TH_Y := -1.8               # theatre front floor
const WIN_Z := -14.0

var L: Node3D
var rng: RandomNumberGenerator
var k: GeoKit                    # architecture (collision = layout signature)
var screen_shader: Shader
var kiosks: Array = []           # {pos, yaw, prog, wake, mat, marquee, node, it}
var doors: Array = []            # {id, pos, n, leaf, it, kicked, tries}
var clocks: Array = []           # {label, pos, base, shown, unseen}
var windows: Array = []          # {c, n, hu, hv}
var big_screens: Array = []      # {mat}
var scroller: Array = []         # Label3D slots
var theatre_screen := Vector3(-29.8, 2.3, 2.0)
var mono: SystemFont


func _init(level: Node3D, r: RandomNumberGenerator, shader: Shader) -> void:
	L = level
	rng = r
	screen_shader = shader
	k = GeoKit.new(level, "Architecture")
	mono = SystemFont.new()
	mono.font_names = PackedStringArray(["DejaVu Sans Mono", "Liberation Mono", "Courier New", "monospace"])


func build_all() -> void:
	_atrium()
	_gallery()
	_corridor()
	_viewer_room()
	_theatre()
	_fixtures()
	_terminals()
	_seam()
	k.commit()


## Level materials (all procedural). Returns the shader materials driven at runtime.
static func materials() -> Dictionary:
	var mats := {}
	MatLib.define("l256_floor", {"albedo_a": Color(0.12, 0.13, 0.155), "albedo_b": Color(0.09, 0.1, 0.12), "pattern": 1,
		"pattern_scale": Vector2(1.2, 1.2), "grout_width": 0.003, "grout_color": Color(0.1, 0.12, 0.18), "roughness_a": 0.08,
		"roughness_b": 0.2, "tile_variation": 0.02, "bump_strength": 0.1, "noise_scale": 0.4}, "pool_tile")
	MatLib.define("l256_floor_gal", {"albedo_a": Color(0.06, 0.065, 0.08), "albedo_b": Color(0.05, 0.055, 0.07), "pattern": 3,
		"pattern_scale": Vector2(2.4, 0.3), "grout_width": 0.002, "grout_color": Color(0.02, 0.02, 0.03), "roughness_a": 0.18, "roughness_b": 0.3}, "wood_floor")
	MatLib.define("l256_wall", {"albedo_a": Color(0.1, 0.105, 0.12), "albedo_b": Color(0.085, 0.09, 0.105), "pattern": 2,
		"pattern_scale": Vector2(1.2, 1.0), "pattern_color": Color(0.05, 0.05, 0.06), "pattern_strength": 0.5, "roughness_a": 0.45, "roughness_b": 0.6, "noise_scale": 0.6}, "plaster")
	MatLib.define("l256_wall_lt", {"albedo_a": Color(0.5, 0.52, 0.56), "albedo_b": Color(0.46, 0.48, 0.52), "pattern": 14,
		"pattern_scale": Vector2(2.4, 1.2), "grout_width": 0.004, "grout_color": Color(0.2, 0.21, 0.24), "roughness_a": 0.35, "roughness_b": 0.5}, "plaster")
	MatLib.define("l256_ceil", {"albedo_a": Color(0.02, 0.02, 0.025), "albedo_b": Color(0.015, 0.015, 0.02), "roughness_a": 0.95}, "concrete_dark")
	MatLib.define("l256_gloss", {"albedo_a": Color(0.015, 0.016, 0.02), "albedo_b": Color(0.012, 0.012, 0.016), "roughness_a": 0.06,
		"roughness_b": 0.12, "metallic_value": 0.2, "bump_strength": 0.0, "stain_amount": 0.0}, "metal")
	MatLib.define("l256_alu", {"albedo_a": Color(0.6, 0.62, 0.66), "albedo_b": Color(0.52, 0.54, 0.58), "roughness_a": 0.3, "stain_amount": 0.0}, "metal")
	MatLib.define("l256_door", {"albedo_a": Color(0.16, 0.18, 0.23), "albedo_b": Color(0.14, 0.16, 0.2), "roughness_a": 0.4, "metallic_value": 0.3, "stain_amount": 0.05}, "metal")
	MatLib.define("l256_stair", {"albedo_a": Color(0.08, 0.085, 0.1), "albedo_b": Color(0.06, 0.065, 0.08), "roughness_a": 0.2, "bump_strength": 0.1}, "concrete_dark")
	MatLib.define("l256_seat", {"albedo_a": Color(0.05, 0.07, 0.17), "albedo_b": Color(0.04, 0.05, 0.13), "pattern": 6, "wetness": 0.0, "stain_amount": 0.0}, "l0_carpet")
	MatLib.define("l256_seat_floor", {"albedo_a": Color(0.035, 0.04, 0.07), "albedo_b": Color(0.03, 0.03, 0.055), "pattern": 6, "wetness": 0.0, "stain_amount": 0.05}, "l0_carpet")
	MatLib.define("l256_l4_carpet", {"albedo_a": Color(0.33, 0.34, 0.37), "albedo_b": Color(0.27, 0.28, 0.31), "pattern": 6, "pattern_strength": 0.0,
		"wetness": 0.0, "noise_scale": 0.55, "stain_amount": 0.32, "stain_color": Color(0.24, 0.23, 0.21), "stain_scale": 0.22}, "l0_carpet")
	MatLib.define("l256_pack", {"albedo_a": Color(0.16, 0.2, 0.14), "albedo_b": Color(0.12, 0.15, 0.1), "pattern": 6, "wetness": 0.0}, "l0_carpet")
	var bottle := MatLib.standard(Color(0.6, 0.75, 0.85), 0.1)
	bottle.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bottle.albedo_color.a = 0.5
	MatLib.register("l256_bottle", bottle)
	var rail := MatLib.standard(Color(0.5, 0.65, 0.8), 0.05, 0.0)
	rail.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rail.albedo_color.a = 0.14
	MatLib.register("l256_rail_glass", rail)
	for n in [["l256_neon", Color(0.22, 0.5, 1.0), 4.5], ["l256_neon_soft", Color(0.35, 0.6, 1.0), 2.4]]:
		var m := ShaderMaterial.new()
		var s := Shader.new()
		s.code = preload("res://levels/L256/L256_shaders.gd").NEON
		m.shader = s
		m.set_shader_parameter("color", n[1])
		m.set_shader_parameter("energy", n[2])
		mats[n[0]] = m
		MatLib.register(n[0], m)
	var w := ShaderMaterial.new()
	var ws := Shader.new()
	ws.code = preload("res://levels/L256/L256_shaders.gd").WINDOW
	w.shader = ws
	mats["window"] = w
	MatLib.register("l256_window", w)
	return mats


## The loud distorted tone of the black screens (synthesised, 2.2 s).
static func make_tone() -> AudioStreamWAV:
	var rate := 22050
	var n := int(2.2 * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var f := 740.0 + 30.0 * sin(TAU * 7.0 * t)
		var v := (1.0 if fmod(t * f, 1.0) < 0.5 else -1.0) * 0.5 + (1.0 if fmod(t * f * 1.414, 1.0) < 0.3 else -1.0) * 0.4
		v += sin(TAU * 55.0 * t) * 0.5
		v = clampf(snappedf(v * 1.8, 0.25), -1.0, 1.0) * minf(1.0, t * 40.0) * minf(1.0, (2.2 - t) * 8.0)
		data.encode_s16(i * 2, int(v * 30000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.data = data
	return s


# ----------------------------------------------------------------- shells

func _atrium() -> void:
	k.slab(-16, -14, 16, 14.5, 0.0, 0.4, "l256_floor")
	k.slab(-16, -14, 16, 10, H + 0.3, 0.3, "l256_ceil")
	# north: one curtain wall of black glass (the gallery storey shares it)
	_curtain(Vector3(-16, 0, WIN_Z), Vector3(16, 0, WIN_Z), H, 2.0)
	# east wall (the seam you came through is up on the gallery)
	k.wall(Vector3(16.15, 0, -14), Vector3(16.15, 0, 10), H, 0.3, "l256_wall")
	k.wall(Vector3(16.15, 0, 10), Vector3(16.15, 0, 14.5), COR_H, 0.3, "l256_wall")
	# south wall to the corridor: three wide openings
	var ops := []
	for x in [-9.0, -1.0, 6.0]:
		ops.append({"at": x + 16.0, "w": 3.4, "h": 2.8})
	k.wall(Vector3(-16, 0, 10.15), Vector3(16, 0, 10.15), H, 0.3, "l256_wall_lt", ops)
	# west wall: to the Viewer Room and to the Theatre
	k.wall(Vector3(-16.15, 0, -14), Vector3(-16.15, 0, 10), H, 0.3, "l256_wall_lt",
		[{"at": 4.0, "w": 4.0, "h": 3.2}, {"at": 17.5, "w": 4.0, "h": 3.2}])
	# skirting neon along the long walls
	for z in [9.98]:
		k.box(Vector3(0, 0.03, z), Vector3(32, 0.05, 0.03), "l256_neon", ALL_F(), false)
	k.box(Vector3(-15.98, 0.03, -2), Vector3(0.03, 0.05, 24), "l256_neon", ALL_F(), false)
	# wall-washer coves: lines of neon along the top of the walls and over the openings
	k.box(Vector3(0, 3.4, 9.98), Vector3(32, 0.04, 0.04), "l256_neon", ALL_F(), false)
	k.box(Vector3(-15.98, 3.6, -2), Vector3(0.04, 0.04, 24), "l256_neon", ALL_F(), false)
	for z in [-14.0 + 0.3, 9.7]:
		k.box(Vector3(0, H - 0.25, z), Vector3(32, 0.04, 0.05), "l256_neon_soft", ALL_F(), false)
	k.box(Vector3(15.98, H - 0.25, -2), Vector3(0.04, 0.04, 24), "l256_neon_soft", ALL_F(), false)
	k.box(Vector3(-15.97, H - 0.25, -2), Vector3(0.04, 0.04, 24), "l256_neon_soft", ALL_F(), false)
	door(Vector3(15.99, 0, -8.0), Vector3(-1, 0, 0), "atrium_east")


func _curtain(a: Vector3, b: Vector3, h: float, bay: float) -> void:
	var d := (b - a)
	var length := d.length()
	var dir := d / length
	var n := Vector3(-dir.z, 0, dir.x)       # into the room (+z for the north wall)
	var bays := int(round(length / bay))
	k.box((a + b) * 0.5 + Vector3(0, 0.12, 0), Vector3(absf(d.x) + 0.3, 0.24, absf(d.z) + 0.3) + n.abs() * 0.1, "l256_alu")
	k.box((a + b) * 0.5 + Vector3(0, h - 0.12, 0), Vector3(absf(d.x) + 0.3, 0.24, absf(d.z) + 0.3) + n.abs() * 0.1, "l256_alu")
	for i in bays + 1:
		var p := a + dir * (length * i / bays)
		k.box(p + Vector3(0, h * 0.5, 0) + n * 0.05, Vector3(0.12, h, 0.12) + n.abs() * 0.18, "l256_alu", ALL_F(), false)
	for y in ([GAL_Y + 0.02, GAL_Y + 0.95] if h > 6.0 else [h * 0.62]):
		k.box((a + b) * 0.5 + Vector3(0, y, 0) + n * 0.03, Vector3(absf(d.x), 0.08, absf(d.z)) + n.abs() * 0.12, "l256_alu", ALL_F(), false)
	k.box((a + b) * 0.5 + Vector3(0, 0.26, 0) + n * 0.21, Vector3(absf(d.x), 0.03, absf(d.z)) + n.abs() * 0.03, "l256_neon", ALL_F(), false)
	# the glass itself: a solid pane (you cannot leave), black beyond
	var c := (a + b) * 0.5 + Vector3(0, h * 0.5, 0)
	k.box(c - n * 0.06, Vector3(absf(d.x), h - 0.48, absf(d.z)) + n.abs() * 0.04, "l256_window", PZ_or(n))
	windows.append({"c": c - n * 0.04, "n": n, "hu": dir * length * 0.5, "hv": Vector3(0, (h - 0.48) * 0.5, 0)})


func _gallery() -> void:
	k.slab(GAL_X, WIN_Z, 16, GAL_Z1, GAL_Y, 0.35, "l256_floor_gal")
	k.box(Vector3(GAL_X + 0.02, GAL_Y - 0.36, (WIN_Z + GAL_Z1) * 0.5), Vector3(0.05, 0.03, GAL_Z1 - WIN_Z), "l256_neon", ALL_F(), false)
	# glass balustrade with an aluminium rail and a neon lip
	_rail(Vector3(GAL_X + 0.05, GAL_Y, WIN_Z + 0.1), Vector3(GAL_X + 0.05, GAL_Y, GAL_Z1 - 0.05))
	_rail(Vector3(GAL_X, GAL_Y, GAL_Z1 - 0.05), Vector3(12.0, GAL_Y, GAL_Z1 - 0.05))
	_rail(Vector3(14.5, GAL_Y, GAL_Z1 - 0.05), Vector3(16.0, GAL_Y, GAL_Z1 - 0.05))
	# the stair down to the atrium floor (risers 0.18 m)
	k.stairs(Vector3(13.25, 0, 9.6), Vector3(0, 0, -1), 2.4, GAL_Y, 25, "l256_stair", 0.28)
	_rail(Vector3(12.0, 0.0, 9.6), Vector3(12.0, GAL_Y, GAL_Z1))
	# columns carrying the gallery
	for z in [-10.0, -4.0]:
		k.box(Vector3(GAL_X + 0.6, GAL_Y * 0.5, z), Vector3(0.45, GAL_Y, 0.45), "l256_gloss")
	door(Vector3(15.99, GAL_Y, -10.5), Vector3(-1, 0, 0), "gallery_east")


## Glass balustrade from a to b (floor points); a sloped one follows the stair.
func _rail(a: Vector3, b: Vector3) -> void:
	var d := b - a
	var z := d.normalized()
	var x := Vector3.UP.cross(z).normalized()
	var y := z.cross(x).normalized()
	var bas := Basis(x, y, z)
	var c := (a + b) * 0.5 + Vector3(0, 0.55, 0)
	k.box_xf(Transform3D(bas, c), Vector3(0.03, 1.0, d.length()), "l256_rail_glass", ALL_F(), true)
	k.box_xf(Transform3D(bas, c + y * 0.52), Vector3(0.07, 0.05, d.length()), "l256_alu", ALL_F(), false)
	k.box_xf(Transform3D(bas, c + y * 0.49), Vector3(0.02, 0.015, d.length()), "l256_neon", ALL_F(), false)


func _corridor() -> void:
	k.slab(-16, 10.3, 16, 14.5, COR_H + 0.3, 0.3, "l256_ceil")
	k.wall(Vector3(-16, 0, 14.65), Vector3(16, 0, 14.65), COR_H, 0.3, "l256_wall")
	k.wall(Vector3(-16.15, 0, 10), Vector3(-16.15, 0, 14.5), COR_H, 0.3, "l256_wall")
	k.box(Vector3(0, COR_H - 0.06, 12.4), Vector3(31.5, 0.04, 0.08), "l256_neon", ALL_F(), false)
	k.box(Vector3(0, 0.03, 14.48), Vector3(32, 0.05, 0.03), "l256_neon", ALL_F(), false)
	var i := 0
	for x in [-12.0, -6.0, 0.0, 6.0, 12.0]:
		door(Vector3(x, 0, 14.49), Vector3(0, 0, -1), "corridor_%d" % i)
		clock(Vector3(x, 2.62, 14.47), Basis(Vector3.UP, PI))
		i += 1
	door(Vector3(-15.99, 0, 12.25), Vector3(1, 0, 0), "corridor_west")
	door(Vector3(15.99, 0, 12.25), Vector3(-1, 0, 0), "corridor_east")
	clock(Vector3(-1.0, 4.2, 10.0 - 0.02), Basis(Vector3.UP, PI), 0.016)


func _viewer_room() -> void:
	k.slab(-28.3, -14, -16, -6, 0.0, 0.4, "l256_floor")
	k.slab(-28.3, -14, -16.3, -6, 4.3, 0.3, "l256_ceil")
	_curtain(Vector3(-28.3, 0, WIN_Z), Vector3(-16.3, 0, WIN_Z), 4.0, 2.0)
	k.wall(Vector3(-28.45, 0, -14), Vector3(-28.45, 0, -6), 4.0, 0.3, "l256_wall")
	k.wall(Vector3(-30.3, -2.2, -5.85), Vector3(-16.3, -2.2, -5.85), 9.0, 0.3, "l256_wall_lt")
	k.box(Vector3(-22.3, 3.96, -10), Vector3(11.5, 0.04, 0.06), "l256_neon", ALL_F(), false)
	door(Vector3(-28.29, 0, -10.0), Vector3(1, 0, 0), "viewer_west")
	clock(Vector3(-28.28, 2.9, -7.4), Basis(Vector3.UP, PI * 0.5))


func _theatre() -> void:
	k.slab(-19.0, -5.7, -16, 10, 0.0, 0.4, "l256_floor")
	k.slab(-30.3, -6, -16.3, 10, 6.8, 0.3, "l256_ceil")
	k.wall(Vector3(-30.15, -2.2, -6), Vector3(-30.15, -2.2, 10), 9.0, 0.3, "l256_wall")
	k.wall(Vector3(-30.3, -2.2, 10.15), Vector3(-16.3, -2.2, 10.15), 9.0, 0.3, "l256_wall")
	# raked seating: six tiers of 0.30 m, aisle half-steps (0.15 m) at both sides
	for t in range(1, 7):
		var x1 := -19.0 - (t - 1) * 1.1
		var x0 := x1 - 1.1
		var top := -0.3 * t
		k.box_mm(Vector3(x0, -2.2, -5.7), Vector3(x1, top, 9.85), "l256_seat_floor")
		for az in [[-5.7, -4.5], [8.65, 9.85]]:
			k.box_mm(Vector3(x1 - 0.55, top, az[0]), Vector3(x1, top + 0.15, az[1]), "l256_seat_floor")
			k.box(Vector3(x1 - 0.3, top + 0.152, (az[0] + az[1]) * 0.5), Vector3(0.03, 0.006, 1.1), "l256_neon", ALL_F(), false)
		if t < 6:
			_seat_row(Vector3(x0 + 0.55, top, 2.07), 12.6)
	k.box_mm(Vector3(-30, -2.2, -5.7), Vector3(-25.6, TH_Y, 9.85), "l256_seat_floor")
	# the wall-sized screen
	var sc := theatre_screen
	k.box(sc + Vector3(-0.08, 0, 0), Vector3(0.12, 6.6, 11.4), "l256_gloss", ALL_F(), false)
	var m := screen_mat(3, 7.0, Vector2(320, 180))
	big_screens.append({"mat": m})
	_screen_quad(sc + Vector3(0.0, 0, 0), Basis(Vector3.UP, PI * 0.5), Vector2(11.0, 6.2), m)
	clock(Vector3(-16.32, 3.6, 3.5 + 2.6), Basis(Vector3.UP, -PI * 0.5))
	# sine scroller slots in front of the screen (demoscene)
	for i in 34:
		var l := Label3D.new()
		l.font = mono
		l.font_size = 96
		l.pixel_size = 0.009
		l.modulate = Color(0.85, 0.95, 1.0)
		l.outline_size = 10
		l.outline_modulate = Color(0.1, 0.25, 0.9)
		l.shaded = false
		l.fixed_size = false
		l.rotation.y = PI * 0.5
		L.add_child(l)
		l.position = sc + Vector3(0.08, -1.9, 0)
		scroller.append(l)


func _seat_row(c: Vector3, length: float) -> void:
	k.box(c + Vector3(-0.1, 0.22, 0), Vector3(0.55, 0.44, length), "l256_seat")
	k.box(c + Vector3(0.22, 0.5, 0), Vector3(0.12, 0.62, length), "l256_seat", ALL_F(), false)
	var n := int(length / 0.56)
	for i in n + 1:
		var z := c.z - length * 0.5 + i * length / n
		k.box(Vector3(c.x + 0.05, c.y + 0.5, z), Vector3(0.52, 0.06, 0.05), "l256_gloss", ALL_F(), false)


# --------------------------------------------------------------- fixtures

func _fixtures() -> void:
	# the screen totem: four big screens round a column at the atrium's heart
	var tc := Vector3(-2.0, 0, -3.0)
	k.cylinder(tc + Vector3(0, 0.22, 0), 2.3, 0.44, "l256_gloss", 24)
	k.cylinder(tc + Vector3(0, 0.42, 0), 2.32, 0.03, "l256_neon", 24, false, false)
	k.box(tc + Vector3(0, 4.7, 0), Vector3(0.9, 8.6, 0.9), "l256_gloss")
	k.box(tc + Vector3(0, 3.6, 0), Vector3(2.9, 1.9, 2.9), "l256_gloss", ALL_F(), false)
	var progs := [3, 1, 3, 1]
	for i in 4:
		var yaw := i * PI * 0.5
		var b := Basis(Vector3.UP, yaw)
		var m := screen_mat(progs[i], 3.0 + i, Vector2(200, 128))
		m.set_shader_parameter("bright", 0.55 if progs[i] == 1 else 0.8)
		big_screens.append({"mat": m})
		_screen_quad(tc + Vector3(0, 3.6, 0) + b * Vector3(0, 0, 1.46), b, Vector2(2.7, 1.7), m)
	# suspended neon rings (static: nothing here moves but the screens)
	for r in [[3.6, 0.0, 0.0], [2.8, 0.5, 0.3], [2.0, -0.4, 0.9]]:
		var t := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = r[0] - 0.05
		tm.outer_radius = r[0]
		tm.rings = 48
		tm.ring_segments = 6
		t.mesh = tm
		t.material_override = MatLib.get_mat("l256_neon")
		t.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		L.add_child(t)
		t.position = tc + Vector3(0, 7.2, 0)
		t.rotation = Vector3(r[1], r[2], 0)
	# "light forest": hanging tubes of uneven length over the north-east floor
	for ix in 6:
		for iz in 4:
			var p := Vector3(2.0 + ix * 1.1 + (iz % 2) * 0.55, 0, -11.5 + iz * 1.2)
			var low := 2.4 + rng.randf() * 3.2
			k.box(Vector3(p.x, (H + low) * 0.5, p.z), Vector3(0.05, H - low, 0.05), "l256_neon_soft", ALL_F(), false)
	# exhibition islands: low plinths with neon edges
	for isl in [[Vector3(-9.5, 0, -8.0), Vector2(6.0, 3.2)], [Vector3(-9.0, 0, 5.0), Vector2(6.0, 3.2)], [Vector3(4.5, 0, 4.2), Vector2(5.0, 3.0)]]:
		var c: Vector3 = isl[0]
		var s: Vector2 = isl[1]
		k.box(c + Vector3(0, 0.06, 0), Vector3(s.x, 0.12, s.y), "l256_gloss")
		for e in [[Vector3(0, 0, s.y * 0.5), Vector3(s.x, 0, 0)], [Vector3(0, 0, -s.y * 0.5), Vector3(s.x, 0, 0)], [Vector3(s.x * 0.5, 0, 0), Vector3(0, 0, s.y)], [Vector3(-s.x * 0.5, 0, 0), Vector3(0, 0, s.y)]]:
			k.box(c + e[0] + Vector3(0, 0.1, 0), e[1] + Vector3(0.03, 0.03, 0.03), "l256_neon", ALL_F(), false)
	# benches facing the windows
	for x in [-12.0, -5.0, 6.0]:
		k.box(Vector3(x, 0.22, -11.0), Vector3(2.4, 0.44, 0.6), "l256_wall_lt")
	# linear ceiling fixtures
	for z in [-11.0, 5.5]:
		k.box(Vector3(-4.0, H - 0.8, z), Vector3(18.0, 0.05, 0.08), "l256_neon", ALL_F(), false)


# -------------------------------------------------------------- terminals

func _terminals() -> void:
	# [pos, yaw, program, wake]  program: 1 static, 2 viewer, 3 demo, 4 game, 5 black
	# wake 0 = on from the start; 0.34 / 0.67 = turns on by itself later
	var wild := [1, 1, 3, 5, 1]
	var defs := [
		[Vector3(-11.5, 0.12, -8.0), PI * 0.15, 1, 0.0], [Vector3(-9.5, 0.12, -8.3), 0.0, 3, 0.0], [Vector3(-7.5, 0.12, -8.0), -PI * 0.15, 1, 0.34],
		[Vector3(-11.0, 0.12, 5.2), PI * 0.85, 4, 0.0], [Vector3(-9.0, 0.12, 5.5), PI, 1, 0.0], [Vector3(-7.0, 0.12, 5.2), -PI * 0.85, 5, 0.0],
		[Vector3(3.0, 0.12, 4.4), PI, 1, 0.0], [Vector3(6.0, 0.12, 4.4), PI, wild[rng.randi() % wild.size()], 0.67],
		[Vector3(15.5, GAL_Y, -12.0), -PI * 0.5, 1, 0.34], [Vector3(15.5, GAL_Y, -7.0), -PI * 0.5, 5, 0.67],
		[Vector3(-26.5, 0, -12.5), PI * 0.25, 2, 0.0], [Vector3(-22.0, 0, -12.8), 0.0, 1, 0.0], [Vector3(-18.0, 0, -12.5), -PI * 0.25, 2, 0.67],
		[Vector3(13.8, 0, -13.0), PI * 0.1, 1, 0.67],
	]
	for d in defs:
		kiosk(d[0], d[1], d[2], d[3])


func kiosk(pos: Vector3, yaw: float, prog: int, wake: float) -> void:
	var b := Basis(Vector3.UP, yaw)
	k.box_xf(Transform3D(b, pos + b * Vector3(0, 0.55, 0)), Vector3(0.8, 1.1, 0.5), "l256_gloss")
	k.box_xf(Transform3D(b, pos + b * Vector3(0, 0.03, 0.26)), Vector3(0.8, 0.04, 0.03), "l256_neon", ALL_F(), false)
	k.box_xf(Transform3D(b, pos + b * Vector3(0, 1.25, -0.05)), Vector3(0.14, 0.4, 0.1), "l256_alu", ALL_F(), false)
	k.box_xf(Transform3D(b, pos + b * Vector3(0, 1.62, 0.0)), Vector3(0.88, 0.62, 0.1), "l256_gloss", ALL_F(), false)
	k.box_xf(Transform3D(b, pos + b * Vector3(0, 2.05, 0.0)), Vector3(0.88, 0.2, 0.12), "l256_gloss", ALL_F(), false)
	var m := screen_mat(prog if wake <= 0.0 else 0, rng.randf() * 50.0, Vector2(160, 112))
	_screen_quad(pos + b * Vector3(0, 1.62, 0.052), b, Vector2(0.78, 0.52), m)
	var mq := screen_mat(9, rng.randf() * 50.0, Vector2(64, 16))
	mq.set_shader_parameter("brand", Color.from_hsv(rng.randf(), 0.8, 0.95))
	_screen_quad(pos + b * Vector3(0, 2.05, 0.062), b, Vector2(0.84, 0.16), mq)
	kiosks.append({"pos": pos, "yaw": yaw, "prog": prog, "wake": wake, "mat": m, "marquee": mq,
		"on": wake <= 0.0, "face": pos + b * Vector3(0, 1.62, 0.06), "fwd": b * Vector3(0, 0, 1),
		"seen": false, "cool": 0.0, "near_t": 0.0, "unseen": 0.0})


func screen_mat(prog: int, seed_value: float, res: Vector2) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = screen_shader
	m.set_shader_parameter("program", prog)
	m.set_shader_parameter("seedv", seed_value)
	m.set_shader_parameter("res", res)
	return m


func _screen_quad(c: Vector3, b: Basis, size: Vector2, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	L.add_child(mi)
	mi.global_transform = Transform3D(b, c)
	return mi


## A locked door: frame and leaf on a solid wall. pos = floor point on the wall
## face, n = the side you stand on. The leaf is its own mesh so a kick can
## knock it down; behind it there is only more wall.
func door(pos: Vector3, n: Vector3, id: String, w := 1.0) -> void:
	var b := Basis(Vector3.UP.cross(n).normalized(), Vector3.UP, n)
	k.box_xf(Transform3D(b, pos + n * 0.03 + Vector3(0, 2.14, 0)), Vector3(w + 0.2, 0.1, 0.06), "l256_alu", ALL_F(), false)
	for s in [-1.0, 1.0]:
		k.box_xf(Transform3D(b, pos + n * 0.03 + b.x * (s * (w * 0.5 + 0.05)) + Vector3(0, 1.05, 0)), Vector3(0.1, 2.1, 0.06), "l256_alu", ALL_F(), false)
	var leaf := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(w - 0.02, 2.08, 0.045)
	leaf.mesh = bm
	leaf.material_override = MatLib.get_mat("l256_door")
	var handle := MeshInstance3D.new()
	var hm := BoxMesh.new()
	hm.size = Vector3(0.16, 0.03, 0.05)
	handle.mesh = hm
	handle.material_override = MatLib.get_mat("l256_alu")
	handle.position = Vector3(w * 0.36, 0.0, 0.04)
	leaf.add_child(handle)
	L.add_child(leaf)
	leaf.global_transform = Transform3D(b, pos + n * 0.026 + Vector3(0, 1.05, 0))
	doors.append({"id": id, "pos": pos, "n": n, "leaf": leaf, "b": b, "kicked": false, "tries": 0})


## A digital wall clock. Clocks here do not tick (SOURCE testimony).
func clock(pos: Vector3, b: Basis, px := 0.008) -> void:
	k.box_xf(Transform3D(b, pos - b.z * 0.03), Vector3(0.62 * px / 0.008, 0.24 * px / 0.008, 0.05), "l256_gloss", ALL_F(), false)
	var l := Label3D.new()
	l.font = mono
	l.font_size = 64
	l.pixel_size = px * 0.5
	l.modulate = Color(0.45, 0.75, 1.0)
	l.outline_size = 0
	l.shaded = false
	L.add_child(l)
	l.global_transform = Transform3D(b, pos)
	var base := "%02d:%02d" % [rng.randi() % 24, rng.randi() % 60]
	l.text = base
	clocks.append({"label": l, "pos": pos, "base": base, "unseen": 0.0})


## Where you came through from Level 4: a square of that level's grey office
## carpet carried along on the gallery floor, and your own pack beside it.
func _seam() -> void:
	k.box(Vector3(15.0, GAL_Y + 0.01, -2.4), Vector3(1.9, 0.02, 2.3), "l256_l4_carpet", ALL_F(), false)
	k.box(Vector3(15.65, GAL_Y + 0.22, -0.9), Vector3(0.38, 0.44, 0.26), "l256_pack", ALL_F(), false)
	for i in 3:
		k.cylinder(Vector3(15.2 + i * 0.12, GAL_Y + 0.12, -0.55), 0.04, 0.24, "l256_bottle", 8, false)
	k.box(Vector3(15.5, GAL_Y + 0.04, -0.4), Vector3(0.22, 0.08, 0.14), "l256_pack", ALL_F(), false)


static func ALL_F() -> int:
	return GeoKit.ALL


static func PZ_or(n: Vector3) -> int:
	if n.z > 0.5:
		return GeoKit.PZ
	if n.z < -0.5:
		return GeoKit.NZ
	return GeoKit.PX if n.x > 0.5 else GeoKit.NX
