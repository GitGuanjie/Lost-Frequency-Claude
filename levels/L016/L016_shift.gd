extends Node
## Level 16 terrain-state machine. steady -> warning (orbs circle you, the
## ground rumbles) -> altering (a front sweeps across the valley: trees sink,
## glaciers rise, water bursts from boulders, the ground freezes; or the
## reverse) -> steady in the other state, with the exit moved to a new spot.
## The environment, gravity (low for you in the forest) and sound follow the
## front as it passes you. Arctic state: a compressed 13-minute day.

const F := preload("res://levels/L016/L016_flora.gd")
const ALTER_T := 16.0
const WARN_T := 25.0
const DAY_T := 780.0
const G_FOREST := 3.4

var lvl
var land
var wld
var state := 0
var phase := "steady"
var t_next := 300.0
var t_phase := 0.0
var day_t := 0.3
var blend := 0.0
var front := -1000.0
var origin := Vector3.ZERO
var to_state := 1
var spot_i := 0
var exit_obj: Node3D
var exit_trig: ExitTrigger
var exit_pos := Vector3.ZERO
var beds := {}
var said := {}
var frozen := false
var _creak_t := 12.0
var _t := 0.0
var _spire_up: Array = []


func _init(level) -> void:
	lvl = level
	land = level.land
	wld = level.wld
	name = "Alteration"


func _ready() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = lvl.level_seed + 16
	state = 0 if r.randf() < 0.5 else 1
	t_next = r.randf_range(240.0, 420.0)
	day_t = r.randf_range(0.12, 0.38)
	for s in wld.spires:
		_spire_up.append(state == 1)
	_apply_instant(state)
	_place_exit()


func on_ready() -> void:
	_gravity()
	if state == 0:
		say("arrive", "[dawn light through fog and leaves. Your body feels strangely light]", 5.0)
	else:
		say("arrive", "[cold, bright air. The ice gives off a faint light of its own]", 5.0)


func say(key: String, text: String, secs: float) -> void:
	if said.has(key):
		return
	said[key] = true
	Overlay.subtitle(text, secs)


# ---------------------------------------------------------------- states

func _apply_instant(s: int) -> void:
	state = s
	front = -1000.0
	blend = float(s)
	for c in wld.cells:
		wld.set_cell_state(c, float(s))
	for i in wld.spires.size():
		wld.set_spire_state(wld.spires[i], float(s))
		_spire_up[i] = s == 1
	for j in wld.jets:
		j.visible = s == 1
		j.material_override = wld.ice_mat if s == 1 else wld.jet_water
	_terrain_uniforms()
	_env()


func _terrain_uniforms() -> void:
	var m: ShaderMaterial = lvl.terrain_mat
	m.set_shader_parameter("front", front)
	m.set_shader_parameter("front_origin", origin)
	m.set_shader_parameter("dir", 1.0 if (phase == "altering" and to_state == 1) or (phase != "altering" and state == 0) else 0.0)


## Fraction of the change that has passed a point (0 before the front, 1 after).
func _passed(p: Vector3) -> float:
	if phase != "altering" and not frozen:
		return 1.0
	var d := Vector2(p.x - origin.x, p.z - origin.z).length()
	return 1.0 - smoothstep(front - 25.0, front, d)


func _arctic_at(p: Vector3) -> float:
	if phase != "altering" and not frozen:
		return float(state)
	var ps := _passed(p)
	return ps if to_state == 1 else 1.0 - ps


func _env() -> void:
	var b := blend
	var el := 50.0 * sin(day_t * TAU)
	var night := clampf(-el / 15.0, 0.0, 1.0) * b
	var sun_el := lerpf(7.0, maxf(el, 4.0), b)
	lvl.sun.rotation_degrees = Vector3(-sun_el, lerpf(120.0, 200.0 - day_t * 180.0, b), 0)
	lvl.sun.light_color = Color(1.0, 0.8, 0.6).lerp(Color(0.95, 0.97, 1.0), b)
	lvl.sun.light_energy = lerpf(0.85, 1.05 * (1.0 - night), b)
	var env: Environment = lvl.environment
	var fog_a := Color(0.3, 0.31, 0.27)
	var fog_b := Color(0.6, 0.68, 0.76).lerp(Color(0.02, 0.03, 0.05), night / maxf(b, 0.001))
	env.fog_light_color = fog_a.lerp(fog_b, b)
	env.fog_density = lerpf(0.024, 0.007, b)
	env.tonemap_exposure = lerpf(1.0, 0.78, b * (1.0 - night))
	env.ambient_light_energy = lerpf(0.65, lerpf(0.85, 0.3, night / maxf(b, 0.001)), b)
	env.ambient_light_color = Color(0.32, 0.42, 0.3).lerp(Color(0.6, 0.68, 0.8), b)
	env.ambient_light_sky_contribution = lerpf(0.35, 0.75, b)
	env.adjustment_contrast = lerpf(1.04, 1.12, b)
	var sm: ShaderMaterial = lvl.sky_mat
	sm.set_shader_parameter("state", b)
	sm.set_shader_parameter("night", night)
	var glow := 0.1 + 0.6 * night
	lvl.terrain_mat.set_shader_parameter("glow", glow)
	wld.ice_mat.set_shader_parameter("glow", 0.12 + 0.7 * night)
	wld.guides.visible = b > 0.5
	wld.water.visible = b < 0.5
	wld.ice_river.visible = b >= 0.5
	for c in wld.ice_river.get_children():
		if c is StaticBody3D:
			for cs in c.get_children():
				(cs as CollisionShape3D).disabled = b < 0.5


func _gravity() -> void:
	var pl: Player = lvl.player
	if pl == null or not is_instance_valid(pl):
		return
	pl.gravity = G_FOREST if blend < 0.5 else 9.8


# ---------------------------------------------------------------- the exit

func _place_exit() -> void:
	if is_instance_valid(exit_trig):
		lvl.exits.erase(exit_trig)
	if is_instance_valid(exit_obj):
		exit_obj.queue_free()
	exit_obj = Node3D.new()
	exit_obj.name = "ExitObject"
	lvl.add_child(exit_obj)
	var p: Vector3 = wld.spots[spot_i % wld.spots.size()]
	exit_pos = p
	if state == 0:
		var mi := MeshInstance3D.new()
		mi.mesh = F.tree_mesh(1, true)
		var m := wld.leaf_mat.duplicate() as ShaderMaterial
		m.set_shader_parameter("sand", 1.0)
		mi.material_override = m
		mi.position = p
		exit_obj.add_child(mi)
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var cy := CylinderShape3D.new()
		cy.radius = 0.75
		cy.height = 8.0
		cs.shape = cy
		cs.position = p + Vector3(0, 4.0, 0)
		body.add_child(cs)
		exit_obj.add_child(body)
		# sand drifted round the roots
		var k := GeoKit.new(exit_obj, "Sand")
		k.cylinder(p + Vector3(0, 0.04, 0), 2.4, 0.12, "l16_sand", 14, false)
		k.commit()
		exit_trig = lvl.make_exit("L016>L046#1", "interact", p + Vector3(0, 1.1, 0), Vector3(3.6, 2.4, 3.6), "Climb the sand-covered tree", exit_obj)
	else:
		var k2 := GeoKit.new(exit_obj, "IceSheet")
		k2.box(p + Vector3(0, 0.08, 0), Vector3(5.0, 0.24, 3.6), "l16_ice", GeoKit.SIDES | GeoKit.NY, true, "snow")
		k2.box(p + Vector3(0, 0.205, 0), Vector3(4.9, 0.01, 3.5), "l16_sand", GeoKit.PY, false)
		k2.commit()
		exit_trig = lvl.make_exit("L016>L046#1", "dwell", p + Vector3(0, 1.1, 0), Vector3(4.6, 2.0, 3.2), "", exit_obj)
		if exit_trig:
			exit_trig.hold_seconds = 2.5


# ---------------------------------------------------------------- per frame

func step(delta: float) -> void:
	_t += delta
	var pl: Player = lvl.player
	if pl == null or not is_instance_valid(pl):
		return
	if blend > 0.5 and not frozen:
		day_t = fposmod(day_t + delta / DAY_T, 1.0)
	_guides(delta)
	if frozen:
		return
	match phase:
		"steady":
			t_next -= delta
			if t_next <= 0.0 and not SessionState.is_qa():
				_begin_warning()
		"warning":
			t_phase += delta
			_orbs(pl.global_position, t_phase / WARN_T)
			if t_phase >= WARN_T:
				_begin_alter(pl.global_position)
		"altering":
			_alter_step(delta)
	_audio(delta)
	if Engine.get_process_frames() % 15 == 0:
		_env()


func _begin_warning() -> void:
	phase = "warning"
	t_phase = 0.0
	wld.orbs.visible = true
	Overlay.subtitle("[small lights gather out of nowhere and start to circle you]", 5.0)


func _begin_alter(p: Vector3) -> void:
	phase = "altering"
	t_phase = 0.0
	to_state = 1 - state
	var a := randf_range(0, TAU)
	origin = Vector3(p.x + cos(a) * 70.0, 0, p.z + sin(a) * 70.0)
	front = 0.0
	for j in wld.jets:
		j.visible = true
		j.material_override = wld.jet_water
	Overlay.subtitle("[the ground lurches. Somewhere water bursts out of rock]" if to_state == 1 else "[the ice cracks open everywhere at once]", 5.0)


func _alter_step(delta: float) -> void:
	t_phase += delta
	front = t_phase / ALTER_T * 320.0
	_terrain_uniforms()
	var pl: Player = lvl.player
	for c in wld.cells:
		wld.set_cell_state(c, _arctic_at(c["center"]))
	for i in wld.spires.size():
		var s: Dictionary = wld.spires[i]
		var a := _arctic_at(s["pos"])
		wld.set_spire_state(s, a)
		var up := a > 0.5
		if up and not _spire_up[i] and is_instance_valid(pl):
			_encase_check(pl, s)
		_spire_up[i] = up
	var b_old := blend
	blend = _arctic_at(pl.global_position) if is_instance_valid(pl) else blend
	if (b_old < 0.5) != (blend < 0.5):
		_gravity()
		Overlay.subtitle("[the air turns bitterly cold around you]" if blend >= 0.5 else "[warm, wet air - and you feel light on your feet again]", 4.0)
	_orbs(pl.global_position if is_instance_valid(pl) else Vector3.ZERO, 1.0 - t_phase / ALTER_T)
	if t_phase >= ALTER_T:
		phase = "steady"
		state = to_state
		front = -1000.0
		blend = float(state)
		wld.orbs.visible = false
		for j in wld.jets:
			j.visible = state == 1
			j.material_override = wld.ice_mat if state == 1 else wld.jet_water
		_terrain_uniforms()
		_env()
		_gravity()
		spot_i += 1
		_place_exit()
		t_next = randf_range(240.0, 420.0)
		said.erase("shifted")
		say("shifted", "[it is over. Nothing here looks like the place you were standing in a minute ago]", 5.0)


## A glacier coming up under you: frostbite and scrapes at the edge, worse inside.
func _encase_check(pl: Player, s: Dictionary) -> void:
	var p: Vector3 = s["pos"]
	var d := Vector2(pl.global_position.x - p.x, pl.global_position.z - p.z).length()
	var r: float = s["r"]
	if d > r + 1.2:
		return
	var out := Vector3(pl.global_position.x - p.x, 0, pl.global_position.z - p.z)
	if out.length() < 0.1:
		out = Vector3(1, 0, 0)
	pl.global_position += out.normalized() * (r + 2.0 - d) + Vector3.UP * 0.3
	Overlay.glitch(0.5)
	if SessionState.is_qa():
		return
	if d < r * 0.5:
		Overlay.subtitle("[the ice closes round you before you can move]", 4.0)
		pl.hurt(1000.0, "Level 16: encased in the changing terrain")
	else:
		Overlay.subtitle("[ice rips up beside you - you tear free with frostbitten hands and scraped skin]", 5.0)
		pl.hurt(30.0, "Level 16: caught at the edge of a rising glacier")


func _orbs(p: Vector3, k: float) -> void:
	var i := 0
	for o in wld.orbs.get_children():
		var a := _t * (0.8 + 0.1 * i) + TAU * i / 14.0
		var r := lerpf(9.0, 2.6, clampf(k, 0.0, 1.0)) + 0.6 * sin(_t + i)
		(o as Node3D).position = p + Vector3(cos(a) * r, 1.2 + 0.8 * sin(_t * 1.3 + i * 0.7), sin(a) * r)
		i += 1


func _guides(_delta: float) -> void:
	if not wld.guides.visible:
		return
	for g in wld.guides.get_children():
		var base: Vector3 = g.get_meta("base")
		var ph: float = g.get_meta("ph")
		g.position = base + Vector3(sin(_t * 0.3 + ph) * 0.8, sin(_t * 0.7 + ph * 2.0) * 0.4, cos(_t * 0.25 + ph) * 0.8)


func _audio(delta: float) -> void:
	var k := minf(delta * 1.2, 1.0)
	_vol("forest", lerpf(-26.0, -80.0, blend), k)
	_vol("wind", lerpf(-30.0, -17.0, blend), k)
	_vol("rumble", -12.0 if phase != "steady" else -80.0, k)
	_vol("gush", -10.0 if phase == "altering" else -80.0, k)
	_creak_t -= delta
	if _creak_t <= 0.0:
		_creak_t = randf_range(10.0, 22.0)
		if blend > 0.5:
			lvl.sound.play_at("creak", {"freq": 70.0}, lvl.player.global_position + Vector3(randf_range(-20, 20), 0, randf_range(-20, 20)), -10.0, "[the ice groans]")


func _vol(key: String, db: float, k: float) -> void:
	var pl: AudioStreamPlayer = beds.get(key)
	if is_instance_valid(pl):
		pl.volume_db = lerpf(pl.volume_db, db, k)


# ---------------------------------------------------------------- stills / QA

## Freeze a look for a still: s = 0, 1, or 0.5 (mid-alteration, half frozen).
func stage(s: float, day: float) -> void:
	frozen = false
	phase = "steady"
	day_t = day if day > 0.0 else day_t
	if s < 0.25 or s > 0.75:
		_apply_instant(int(round(s)))
		if exit_obj and (state == 0) != (exit_obj.get_node_or_null("IceSheet") == null):
			_place_exit()
	else:
		state = 0
		phase = "altering"
		to_state = 1
		origin = Vector3(-140.0, 0, 70.0)
		front = Vector2(origin.x - land.MESA.x, origin.z - land.MESA.y).length() - 14.0
		frozen = true
		for c in wld.cells:
			wld.set_cell_state(c, _arctic_at(c["center"]))
		for i in wld.spires.size():
			wld.set_spire_state(wld.spires[i], _arctic_at(wld.spires[i]["pos"]))
		_terrain_uniforms()
		blend = 0.0
		wld.orbs.visible = true
		_orbs(Vector3(land.MESA.x - 3.0, 8.0, land.MESA.y + 7.0), 0.6)
		for j in wld.jets:
			j.visible = true
	_env()
	if frozen:
		wld.guides.visible = false


## Run a whole alteration in fast steps (QA only).
func qa_run_alteration() -> void:
	_begin_alter(lvl.player.global_position)
	var n := 0
	while phase == "altering" and n < 200:
		_alter_step(ALTER_T / 40.0)
		n += 1
	await lvl.get_tree().process_frame
