extends LevelBase
## Level 922 "I finally travelled to the 'True End', and all I got was this fucking
## staircase." (Backrooms Wikidot rev 26, accessed 2026-11-04; Sky3, CC BY-SA 3.0).
## Dossier: docs/canon/levels/L922.md. NARRATIVE_FORMAT page: three paragraphs, no
## entrances, exits, entities or items. The whole level is one stairwell.
##
## PLAN (read -> design):
## - SOURCE: "The Escherian Stairwell", an antique mass of brutalist architecture, a
##   spiral staircase that begins but never ends; it only goes up -> one round, board-
##   formed concrete shaft (11.2 m across, a confined area) with a helical stair of
##   24 steps per 4.2 m turn round an open 4 m well. It BEGINS: a black terrazzo floor
##   at the bottom, the first riser, a solid plinth under the first three quarters.
## - SOURCE: a blinding light encases the ceiling and the distance never closes ->
##   an unshaded white disc filling the shaft is kept 38 m above the player (the
##   dossier's parallax trick); fog thickens upward into white; one shadowed key
##   light falls through the well from it.
## - SOURCE: trekkers return to their original starting point -> seamless loop:
##   above turn 2 the player is shifted down exactly one turn (identical geometry)
##   while not looking down the well; after 3-5 turns climbed the shift instead
##   sets them on the first steps above the floor they started from.
## - SOURCE: black and white monotony -> scene saturation 0, white concrete, black
##   terrazzo, black stair nosings and a black steel rail.
## - SOURCE: silence so complete you hear your heartbeat and breath whistle -> no
##   room tone, no reverb tail; a heartbeat loop and a procedural breath loop whose
##   rate and level follow climbing exertion (the stateful mechanic), with captions.
## - SOURCE: nothing to fear, no danger, no reward, no significance -> no entities,
##   notes, items, exits or payoff. Two plain interactions only restate what you see.
## - ADAPTATION: dimensions, step count and the 3-5 turn loop length are ours.

const R_IN := 2.0          # well radius (inner face of the parapet band)
const R_OUT := 5.6         # shaft wall (inner face)
const PAR_T := 0.22        # parapet thickness (toward the well)
const STEPS := 24          # steps per turn
const RISE := 4.2          # rise per turn
const TURNS := 14          # built turns (58.8 m); the player is kept in turns 0..2
const H := RISE / STEPS    # 0.175 m riser
const D := TAU / STEPS     # 15 degrees per step
const PLINTH := 18         # steps of turn 0 that sit on a solid plinth
const LIGHT_GAP := 38.0
const WRAP_Y := 2.0 * RISE + 0.6

var loop_count := 0
var flights := 0.0         # turns climbed since the last return to the start
var loop_at := 4
var wraps := 0
var exertion := 0.0
var _last_y := 0.0
var _disc: MeshInstance3D
var _key: SpotLight3D
var _heart: AudioStreamPlayer
var _breath: AudioStreamPlayer
var _said_t := {}
var _clock := 0.0


func build() -> void:
	rules["view_distance"] = 120.0
	rules["reverb_room"] = 0.0
	rules["reverb_wet"] = 0.0
	rules["flashlight"] = "allowed"
	indoor_env(Color(0.85, 0.85, 0.85), 0.3, Color(0.96, 0.96, 0.96), 0.004)
	environment.background_color = Color(0.85, 0.85, 0.85)
	environment.fog_height_density = -0.045
	environment.fog_height = 6.0
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.0
	environment.adjustment_contrast = 1.12
	environment.tonemap_exposure = 0.9
	environment.glow_enabled = true
	environment.glow_intensity = 0.8
	environment.glow_bloom = 0.15
	environment.glow_hdr_threshold = 1.0
	loop_at = rng.randi_range(3, 5)
	_materials()
	_stairwell()
	_light()
	_sound()
	# The only canon place to stand: the floor where the stair begins.
	var a := deg_to_rad(318.0)
	var p := Vector3(cos(a) * 3.8, 0.05, sin(a) * 3.8)
	add_arrival("start", p, _yaw_along(a))
	add_landmark("The first step", Vector3(3.8, 0.0, 0.2))
	add_landmark("The well, and the light above it", Vector3(0, 0, 0))
	add_interactable(Vector3(cos(deg_to_rad(300.0)) * (R_IN + 0.3), 4.6, sin(deg_to_rad(300.0)) * (R_IN + 0.3)), Vector3(0.8, 1.2, 0.8),
		"Look up the well", func(_p = null): _look_up())
	add_interactable(Vector3(cos(deg_to_rad(250.0)) * 4.4, 3.95, sin(deg_to_rad(250.0)) * 4.4), Vector3(1.0, 1.2, 1.0),
		"Lean over the rail", func(_p = null): _lean_over())
	add_interactable(Vector3(cos(deg_to_rad(330.0)) * 4.9, 0.9, sin(deg_to_rad(330.0)) * 4.9), Vector3(0.6, 1.6, 1.6),
		"Touch the wall", func(_p = null): Overlay.toast("Cold, dry concrete. The marks of the boards it was cast against run on round the shaft, unbroken. There is no door in it.", 4.5))
	var s1 := deg_to_rad(320.0)
	add_shot("first_step", Vector3(cos(s1) * 4.1, 1.62, sin(s1) * 4.1), _helix(deg_to_rad(60.0), 3.6, 1.7), {"flashlight": false})
	add_shot("well_up", Vector3(0.35, 1.5, 0.2), Vector3(-0.2, 30.0, -0.6), {"flashlight": false})
	var s3 := deg_to_rad(200.0) + TAU * 2.0
	add_shot("rail_down", _helix(s3, 1.1, 1.75), Vector3(0.25, 0.0, 0.15), {"flashlight": false})
	var s4 := deg_to_rad(40.0) + TAU
	add_shot("climbing", _helix(s4, 4.3, 1.62), _helix(s4 + deg_to_rad(75.0), 3.4, 2.6), {"flashlight": false})


# ------------------------------------------------------------------ helpers

## Height of the pitch line through the tread nosings at helix angle a (radians).
func _nose_y(a: float) -> float:
	return (a / D + 1.0) * H


func _p(a: float, r: float, y: float) -> Vector3:
	return Vector3(cos(a) * r, y, sin(a) * r)


## Point on the walking line at helix angle a, radius r, plus a height offset.
func _helix(a: float, r: float, up: float) -> Vector3:
	return _p(a, r, (a / D + 0.5) * H + up)


func _yaw_along(a: float) -> float:
	var t := Vector3(-sin(a), 0.0, cos(a))
	return rad_to_deg(atan2(-t.x, -t.z))


## Planar polygon (convex, ordered) into a GeoKit surface with world-metre UVs.
func _poly(k: GeoKit, mat: String, pts: Array, n: Vector3) -> void:
	var s: Dictionary = k._s(mat)
	var base: int = s["v"].size()
	var tu: Vector3 = (pts[1] - pts[0]).normalized()
	var tv: Vector3 = n.cross(tu).normalized()
	for q in pts:
		s["v"].append(q)
		s["n"].append(n)
		s["uv"].append(k._uv_for(q, n, tu, tv))
		s["uv2"].append(Vector2.ZERO)
	var flip: bool = (pts[1] - pts[0]).cross(pts[2] - pts[0]).dot(n) > 0.0
	for i in range(1, pts.size() - 1):
		if flip:
			s["i"].append_array([base, base + i + 1, base + i])
		else:
			s["i"].append_array([base, base + i, base + i + 1])
	k.stats["tris"] += pts.size() - 2


func _quad_n(k: GeoKit, mat: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3, toward: Vector3) -> void:
	var n := (b - a).cross(d - a).normalized()
	if n.dot(toward) < 0.0:
		n = -n
	_poly(k, mat, [a, b, c, d], n)


func _materials() -> void:
	MatLib.define("l922_concrete_wall", {"albedo_a": Color(0.66, 0.66, 0.65), "albedo_b": Color(0.52, 0.52, 0.51),
		"pattern": 3, "pattern_scale": Vector2(2.4, 0.16), "grout_width": 0.006, "grout_color": Color(0.5, 0.5, 0.5),
		"pattern_strength": 0.45, "tile_variation": 0.02, "noise_scale": 1.4, "stain_amount": 0.5,
		"stain_color": Color(0.30, 0.30, 0.30), "stain_scale": 0.22, "grime_height": 0.6, "grime_color": Color(0.3, 0.3, 0.3), "roughness_a": 0.9, "roughness_b": 1.0,
		"bump_strength": 1.1}, "concrete")
	MatLib.define("l922_concrete_step", {"albedo_a": Color(0.80, 0.80, 0.79), "albedo_b": Color(0.70, 0.70, 0.69),
		"noise_scale": 2.2, "stain_amount": 0.3, "stain_color": Color(0.55, 0.55, 0.54), "roughness_a": 0.75,
		"roughness_b": 0.92, "bump_strength": 0.6}, "concrete")
	MatLib.define("l922_concrete_band", {"albedo_a": Color(0.88, 0.88, 0.87), "albedo_b": Color(0.80, 0.80, 0.79),
		"noise_scale": 1.0, "stain_amount": 0.25, "stain_color": Color(0.6, 0.6, 0.6), "roughness_a": 0.85,
		"roughness_b": 0.95, "bump_strength": 0.5}, "concrete")
	MatLib.define("l922_concrete_soffit", {"albedo_a": Color(0.50, 0.50, 0.49), "albedo_b": Color(0.41, 0.41, 0.40),
		"pattern": 3, "pattern_scale": Vector2(2.4, 0.16), "grout_width": 0.005, "grout_color": Color(0.33, 0.33, 0.33),
		"pattern_strength": 0.3, "noise_scale": 1.6, "stain_amount": 0.4, "stain_color": Color(0.3, 0.3, 0.3),
		"roughness_a": 0.92, "roughness_b": 1.0, "bump_strength": 1.0}, "concrete")
	MatLib.define("l922_terrazzo_black", {"albedo_a": Color(0.035, 0.035, 0.035), "albedo_b": Color(0.06, 0.06, 0.06),
		"pattern": 15, "pattern_color": Color(0.85, 0.85, 0.85), "pattern_strength": 0.55, "pattern_scale": Vector2(0.6, 0.6),
		"roughness_a": 0.45, "roughness_b": 0.6, "noise_scale": 1.0, "bump_strength": 0.15}, "")
	MatLib.define("l922_metal_black", {"albedo_a": Color(0.03, 0.03, 0.03), "albedo_b": Color(0.05, 0.05, 0.05),
		"metallic_value": 0.6, "roughness_a": 0.35, "roughness_b": 0.5, "noise_scale": 3.0, "bump_strength": 0.1}, "")
	MatLib.define("l922_tile_nosing", {"albedo_a": Color(0.04, 0.04, 0.04), "albedo_b": Color(0.07, 0.07, 0.07),
		"roughness_a": 0.4, "roughness_b": 0.6, "noise_scale": 2.0, "bump_strength": 0.2}, "")


# --------------------------------------------------------------- the stairwell

func _stairwell() -> void:
	var k := kit("EscherianStairwell")
	var walk := PackedVector3Array()       # smooth walking surface (one trimesh)
	var guard := PackedVector3Array()      # parapet face toward the stair
	var r_par := R_IN - PAR_T
	for s in TURNS * STEPS:
		var a0 := float(s) * D
		var a1 := a0 + D
		var y_top := float(s + 1) * H
		var y_bot := float(s) * H
		var plinth := s < PLINTH
		var soff0: float = 0.0 if plinth else _nose_y(a0) - H - 0.27
		var soff1: float = 0.0 if plinth else _nose_y(a1) - H - 0.27
		var mid := (a0 + a1) * 0.5
		var out_dir := Vector3(cos(mid), 0, sin(mid))
		# tread, with a black nosing strip at its front edge
		var ni := 0.06 / R_IN
		var no := 0.06 / R_OUT
		_poly(k, "l922_concrete_step", [_p(a0 + ni, R_IN, y_top), _p(a0 + no, R_OUT, y_top), _p(a1, R_OUT, y_top), _p(a1, R_IN, y_top)], Vector3.UP)
		_poly(k, "l922_tile_nosing", [_p(a0, R_IN, y_top + 0.002), _p(a0, R_OUT, y_top + 0.002), _p(a0 + no, R_OUT, y_top + 0.002), _p(a0 + ni, R_IN, y_top + 0.002)], Vector3.UP)
		# riser, facing down the stair
		var tback := Vector3(sin(a0), 0, -cos(a0))
		var ry0 := minf(y_bot, soff0) if s == 0 else y_bot
		_quad_n(k, "l922_concrete_step", _p(a0, R_IN, ry0), _p(a0, R_OUT, ry0), _p(a0, R_OUT, y_top), _p(a0, R_IN, y_top), tback)
		# helicoid soffit (the stair floats above the floor after the plinth)
		if not plinth:
			_quad_n(k, "l922_concrete_soffit", _p(a0, r_par, soff0), _p(a0, R_OUT, soff0), _p(a1, R_OUT, soff1), _p(a1, r_par, soff1), Vector3.DOWN)
		elif s == PLINTH - 1:
			# the plinth's end wall, facing the open landing under the stair's last quarter
			var sf := _nose_y(a1) - H - 0.27
			_quad_n(k, "l922_concrete_band", _p(a1, r_par, 0.0), _p(a1, R_OUT, 0.0), _p(a1, R_OUT, sf), _p(a1, r_par, sf), Vector3(-sin(a1), 0, cos(a1)))
		# parapet band at the well: smooth helix, 1.05 m above the nosing line
		var t0 := _nose_y(a0) + 1.05
		var t1 := _nose_y(a1) + 1.05
		_quad_n(k, "l922_concrete_band", _p(a0, r_par, soff0), _p(a1, r_par, soff1), _p(a1, r_par, t1), _p(a0, r_par, t0), -out_dir)
		_quad_n(k, "l922_concrete_band", _p(a0, R_IN, y_bot), _p(a1, R_IN, y_bot + H), _p(a1, R_IN, t1), _p(a0, R_IN, t0), out_dir)
		_quad_n(k, "l922_concrete_band", _p(a0, r_par, t0), _p(a1, r_par, t1), _p(a1, R_IN, t1), _p(a0, R_IN, t0), Vector3.UP)
		# black steel handrail on posts along the parapet top
		var ra := _p(a0, R_IN - PAR_T * 0.5, t0 + 0.06)
		var rb := _p(a1, R_IN - PAR_T * 0.5, t1 + 0.06)
		var z := (rb - ra).normalized()
		var x := Vector3.UP.cross(z).normalized()
		var bas := Basis(x, z.cross(x).normalized(), z)
		k.box_xf(Transform3D(bas, (ra + rb) * 0.5), Vector3(0.07, 0.05, (rb - ra).length() + 0.02), "l922_metal_black", GeoKit.ALL, false)
		if s % 2 == 0:
			k.box(ra + Vector3(0, -0.035, 0), Vector3(0.03, 0.06, 0.03), "l922_metal_black", GeoKit.ALL, false)
		# outer skirting where the stair meets the wall: a black line that rises with it
		var k0 := _nose_y(a0) + 0.18
		var k1 := _nose_y(a1) + 0.18
		_quad_n(k, "l922_tile_nosing", _p(a0, R_OUT - 0.01, k0 - 0.2), _p(a1, R_OUT - 0.01, k1 - 0.2), _p(a1, R_OUT - 0.01, k1), _p(a0, R_OUT - 0.01, k0), -out_dir)
		# collision: smooth helicoid through the tread midpoints, and the parapet
		var w0 := (a0 / D + 0.5) * H
		var w1 := (a1 / D + 0.5) * H
		var q := [_p(a0, R_IN, w0), _p(a0, R_OUT, w0), _p(a1, R_OUT, w1), _p(a1, R_IN, w1)]
		walk.append_array(PackedVector3Array([q[0], q[1], q[2], q[0], q[2], q[3]]))
		var g := [_p(a0, R_IN, y_bot - 0.2), _p(a1, R_IN, y_bot + H - 0.2), _p(a1, R_IN, t1), _p(a0, R_IN, t0)]
		guard.append_array(PackedVector3Array([g[0], g[1], g[2], g[0], g[2], g[3]]))
	# the shaft: one board-formed concrete drum, faceted every 7.5 degrees
	var wall := PackedVector3Array()
	var top := float(TURNS) * RISE + 1.0
	var facets := 48
	for i in facets:
		var a0 := TAU * float(i) / facets
		var a1 := TAU * float(i + 1) / facets
		var c := Vector3(cos((a0 + a1) * 0.5), 0, sin((a0 + a1) * 0.5))
		var w := [_p(a0, R_OUT, -0.5), _p(a1, R_OUT, -0.5), _p(a1, R_OUT, top), _p(a0, R_OUT, top)]
		_quad_n(k, "l922_concrete_wall", w[0], w[1], w[2], w[3], -c)
		wall.append_array(PackedVector3Array([w[0], w[1], w[2], w[0], w[2], w[3]]))
		# floor: black terrazzo, a white marble ring set round the foot of the well
		_poly(k, "l922_terrazzo_black", [Vector3(0, 0, 0), _p(a0, R_OUT, 0.0), _p(a1, R_OUT, 0.0)], Vector3.UP)
		_poly(k, "l922_concrete_band", [_p(a0, R_IN + 0.06, 0.004), _p(a0, R_IN + 0.24, 0.004), _p(a1, R_IN + 0.24, 0.004), _p(a1, R_IN + 0.06, 0.004)], Vector3.UP)
		# a plain recessed plinth course where the drum meets the floor
		_quad_n(k, "l922_tile_nosing", _p(a0, R_OUT - 0.012, 0.0), _p(a1, R_OUT - 0.012, 0.0), _p(a1, R_OUT - 0.012, 0.16), _p(a0, R_OUT - 0.012, 0.16), -c)
	k.box(Vector3(0, -0.3, 0), Vector3(R_OUT * 2.0 + 1.0, 0.6, R_OUT * 2.0 + 1.0), "l922_terrazzo_black", 0, true, "tile")
	_trimesh(k, walk, "concrete")
	_trimesh(k, guard, "concrete")
	_trimesh(k, wall, "concrete")
	k.commit()


func _trimesh(k: GeoKit, faces: PackedVector3Array, surface: String) -> void:
	var sh := ConcavePolygonShape3D.new()
	sh.set_faces(faces)
	sh.backface_collision = true
	var cs := CollisionShape3D.new()
	cs.shape = sh
	cs.set_meta("surface", surface)
	k.body.add_child(cs)
	k.stats["shapes"] += 1


# ------------------------------------------------------------------ the light

func _light() -> void:
	var dm := CylinderMesh.new()
	dm.top_radius = R_OUT + 0.4
	dm.bottom_radius = R_OUT + 0.4
	dm.height = 0.05
	dm.radial_segments = 48
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1, 1, 1)
	m.emission_enabled = true
	m.emission = Color(1, 1, 1)
	m.emission_energy_multiplier = 9.0
	m.disable_fog = true
	dm.material = m
	_disc = MeshInstance3D.new()
	_disc.name = "BlindingLight"
	_disc.mesh = dm
	_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_disc.position = Vector3(0, LIGHT_GAP, 0)
	add_child(_disc)
	# one shadowed key from the light down the well: the spiral throws rings of shadow
	_key = SpotLight3D.new()
	_key.name = "LightFromAbove"
	_key.rotation_degrees = Vector3(-90, 0, 0)
	_key.position = Vector3(0, 24.0, 0)
	_key.light_color = Color(1, 1, 1)
	_key.light_energy = 5.0
	_key.spot_range = 60.0
	_key.spot_angle = 11.0
	_key.spot_attenuation = 0.6
	_key.shadow_enabled = true
	add_child(_key)
	# soft bounce off the white concrete, carried up the axis of the well (periodic)
	lights.setup(6, 0)
	var n := int(float(TURNS) * RISE / 2.1)
	for i in n:
		lights.add_anchor(Vector3(0, 1.6 + float(i) * 2.1, 0), Color(1, 1, 1), 0.55, 6.5, 0.0, "bounce")


func _place_light() -> void:
	if player == null:
		return
	var y := player.global_position.y
	_disc.position.y = y + LIGHT_GAP
	_key.position.y = y + 24.0
	environment.fog_height = y + 9.0


# ------------------------------------------------------------------- sound

func _sound() -> void:
	# No room tone, no hum, no reverb: the page's silence. Only the body.
	_heart = sound.bed("heartbeat", {}, -60.0)
	_breath = AudioStreamPlayer.new()
	_breath.name = "Breath"
	_breath.stream = _breath_stream()
	_breath.volume_db = -60.0
	_breath.bus = "Ambience" if AudioServer.get_bus_index("Ambience") >= 0 else "Master"
	add_child(_breath)
	_breath.play()


## Procedural breath: band-limited noise with an inhale/exhale envelope and a faint
## whistle formant (in-project synthesis; no recorded audio).
func _breath_stream() -> AudioStreamWAV:
	var rate := 22050
	var secs := 3.6
	var n := int(secs * rate)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var r := RandomNumberGenerator.new()
	r.seed = 922
	var l1 := 0.0
	var l2 := 0.0
	var ph := 0.0
	for i in n:
		var t := float(i) / rate
		var nz := r.randf_range(-1.0, 1.0)
		l1 += (nz - l1) * 0.35
		l2 += (l1 - l2) * 0.08
		var band := l1 - l2
		var env := 0.0
		if t < 1.3:
			env = sin(PI * t / 1.3) * 0.7
		elif t > 1.5 and t < 3.3:
			env = sin(PI * (t - 1.5) / 1.8)
		ph += TAU * (1650.0 + 120.0 * sin(t * 3.0)) / rate
		buf[i] = band * env * 1.6 + sin(ph) * env * 0.04
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var peak := 0.0001
	for v in buf:
		peak = maxf(peak, absf(v))
	for i in n:
		bytes.encode_s16(i * 2, int(clampf(buf[i] / peak * 0.85, -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = rate
	s.data = bytes
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_end = n
	return s


# ------------------------------------------------------------------ mechanics

func on_player_ready() -> void:
	_last_y = player.global_position.y
	_place_light()


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_clock += delta
	var y := player.global_position.y
	var dy := y - _last_y
	_last_y = y
	if not player.frozen:
		# exertion: climbing raises it, standing still lets it settle (no harm, ever)
		var climb := maxf(dy, 0.0) / maxf(delta, 0.001)
		exertion = clampf(exertion + (climb * 0.11 - 0.05) * delta, 0.0, 1.0)
		if dy > 0.0:
			flights += dy / RISE
		if player.head.rotation.x > -0.45:
			if not _return_to_start() and y > WRAP_Y:
				_wrap_one()
	_place_light()
	_mix(delta)


## The Escherian loop. Geometry above turn 1 repeats exactly, so moving the player down
## by whole turns is invisible unless they look down the well; we only do it then.
func _wrap_one() -> void:
	player.global_position.y -= RISE
	_last_y = player.global_position.y
	wraps += 1


## After a few turns the climb ends where it began: just after a turn boundary the player
## is set on the same spot of turn 0, the first steps above the floor they started from.
func _return_to_start() -> bool:
	if flights < float(loop_at):
		return false
	var p := player.global_position
	var a := fposmod(atan2(p.z, p.x), TAU)
	if a < deg_to_rad(4.0) or a > deg_to_rad(40.0):
		return false
	var turns := int(floor((p.y - _nose_y(a) + 0.5) / RISE))
	if turns < 1:
		return false
	player.global_position.y = p.y - float(turns) * RISE
	_last_y = player.global_position.y
	loop_count += 1
	flights = 0.0
	loop_at = 3 + (loop_count % 3)
	if not SessionState.is_qa():
		_say("loop", "[the black floor again, just behind the first step]", 5.0, 9999.0)
	return true


func _mix(delta: float) -> void:
	var k := minf(delta * 1.5, 1.0)
	var e := exertion
	var quiet := 1.0 if _clock > 2.0 else 0.0
	if _heart:
		_heart.volume_db = lerpf(_heart.volume_db, lerpf(-30.0, -13.0, e) if quiet > 0.0 else -60.0, k)
		_heart.pitch_scale = lerpf(_heart.pitch_scale, 1.0 + e * 0.75, k)
	if _breath:
		_breath.volume_db = lerpf(_breath.volume_db, lerpf(-34.0, -14.0, e) if quiet > 0.0 else -60.0, k)
		_breath.pitch_scale = lerpf(_breath.pitch_scale, 1.0 + e * 0.6, k)
	if SessionState.is_qa() or _clock < 3.0:
		return
	_say("heart", "[your heartbeat]", 3.0, 70.0)
	if e > 0.35:
		_say("breath", "[your breath, whistling]", 3.0, 70.0)


func _say(key: String, text: String, secs: float, every: float) -> void:
	if _said_t.has(key) and _clock - float(_said_t[key]) < every:
		return
	_said_t[key] = _clock
	Overlay.subtitle(text, secs)


func _look_up() -> void:
	Overlay.show_note("The well", "The stair turns round the well, flight over flight, until the concrete bands thin into white.\n\nThe light up there fills the whole shaft. However far you have climbed, it is no nearer than it was from the floor.")


func _lean_over() -> void:
	var below := "the black floor, and the first step" if player.global_position.y < RISE * 2.2 else "flight under flight"
	Overlay.show_note("Over the rail", "Below: %s.\nAbove: more stair, then white.\n\nNothing moves. Nothing waits. You can hear your own heart." % below)


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "no fabricated destination (no exits)", "ok": exits.is_empty()})
	out.append({"what": "spawn on the floor at the foot of the stair", "ok": absf(player.global_position.y) < 0.4, "detail": player.global_position})
	# the loop: one-turn wrap keeps the climb going; the light keeps its distance
	var keep := player.global_position
	var a := deg_to_rad(120.0)
	player.head.rotation.x = 0.0
	flights = 0.0
	player.global_position = _p(a, 3.8, (a / D + 0.5) * H + RISE * 2.0 + 0.05)
	var y0 := player.global_position.y
	var wrapped := not _return_to_start()
	if wrapped:
		_wrap_one()
	_place_light()
	out.append({"what": "climbing past turn 2 wraps down exactly one turn", "ok": wrapped and absf((y0 - player.global_position.y) - RISE) < 0.001, "detail": [y0, player.global_position.y]})
	out.append({"what": "the light stays the same distance above", "ok": absf(_disc.position.y - player.global_position.y - LIGHT_GAP) < 0.01})
	flights = float(loop_at)
	var b := deg_to_rad(12.0)
	player.global_position = _p(b, 3.8, (b / D + 0.5) * H + RISE * 2.0 + 0.05)
	var returned := _return_to_start()
	out.append({"what": "after a few flights the loop returns you to the first steps", "ok": returned and player.global_position.y < 0.5 and loop_count == 1, "detail": player.global_position})
	player.global_position = keep
	_last_y = keep.y
	_place_light()
	# the climb is walkable all the way: a floor under every point of the walking line
	# for three turns and room for a standing body above it
	var space := get_world_3d().direct_space_state
	var bad: Array = []
	var cap := CapsuleShape3D.new()
	cap.radius = Player.RADIUS
	cap.height = Player.HEIGHT_STAND
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cap
	q.collision_mask = 1
	var ang := 0.05
	while ang < TAU * 3.0:
		for r in [2.7, 3.8, 4.9]:
			var top := _p(ang, r, (ang / D + 0.5) * H + 1.0)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(top, top + Vector3.DOWN * 2.0, 1))
			if hit.is_empty() or absf((hit["position"] as Vector3).y - (ang / D + 0.5) * H) > 0.12:
				bad.append(["floor", snappedf(ang, 0.01), r])
				continue
			q.transform = Transform3D(Basis(), (hit["position"] as Vector3) + Vector3.UP * (Player.HEIGHT_STAND * 0.5 + 0.05))
			if not space.intersect_shape(q, 1).is_empty():
				bad.append(["head", snappedf(ang, 0.01), r])
		ang += deg_to_rad(10.0)
	out.append({"what": "three turns of stair: continuous floor and standing headroom", "ok": bad.is_empty(), "detail": bad.slice(0, 6)})
	out.append({"what": "black and white (saturation 0)", "ok": environment.adjustment_enabled and environment.adjustment_saturation == 0.0})
	out.append({"what": "silence: no reverb tail", "ok": float(rules["reverb_wet"]) == 0.0})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
