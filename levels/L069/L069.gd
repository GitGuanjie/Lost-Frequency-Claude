extends LevelBase
## Level 69 — "The Road Trip of Affliction" (Backrooms Wikidot rev 46, accessed
## 2026-11-04; cite: Kaixo, CC BY-SA 3.0). Dossier: docs/canon/levels/L069.md.
## Content note: the page describes people being speared or carried off by
## entities, death by crashing and starvation. Nothing graphic is shown.
##
## PLAN (v2.0 rebuild)
## SOURCE: a deserted, infinite highway between tall, weathered concrete walls,
## in thick fog and pitch darkness; the only light is the light you produce. You
## wake in a car placed at random on the highway. The car is the only safe place
## (fog and entities avoid cars); a hidden compartment at its bottom centre holds
## the Fragment Of Destivinatia, which repels fog and entities, and removing it
## turns that off. No fuel; collisions are rare but a crash most likely kills.
## Do not park too long (Smilers, Wretches). Leave the car and the Beings From
## Above descend silently from the dark and carry you up. The Whispers: shared
## intrusive thoughts (REPORTED). Exits: an out-of-place tunnel perpendicular to
## the highway, one lane, ~17 hours of driving while the fog thins and the roof
## lights come on, then the car dies and you walk out (Level 11); no-clipping the
## car through the right spot in a side wall (Level 22, car parked, dead).
## Space: the highway streams in 40 m chunks along z (finite streaming window;
## the walls close both sides, black fog closes the ends). The tunnel is a real
## side branch: a lane, a raised walkway (+0.6 m) and, at the end, a stair to a
## landing (+1.26 m) and the way out. No other vehicles, signs or buildings.
## Signature mechanic (stateful): the car. Drive it (W/S, A/D, Space brakes,
## E gets out), crash at speed and die; out of the car an exposure clock runs and
## the legs come down (slower if you stay near the car); pull the Fragment and
## the clear air around the car collapses. The tunnel's 17 hours are compressed
## to TUNNEL_SECONDS of driving (a seamless treadmill in the uniform tunnel).
## QA fixture (QA mode only): start beside the dead car at the tunnel's end, so
## the walker bot walks the sourced last stretch out to Level 11.

const Road := preload("res://levels/L069/L069_road.gd")
const Car := preload("res://levels/L069/L069_car.gd")
const TUNNEL_SECONDS := 150.0
const CAPTURE := 14.0
const LANES := [-6.3, -2.15, 2.15, 6.3]
const PAINTS := [Color(0.3, 0.09, 0.08), Color(0.16, 0.2, 0.26), Color(0.42, 0.42, 0.4), Color(0.2, 0.22, 0.17), Color(0.5, 0.44, 0.32)]
const WHISPERS := ["no one is coming to look for you", "you passed the way out hours ago", "pull over. rest your eyes",
	"the car will not keep you safe forever", "you are going to run out of food first", "they already forgot your name"]
const QA_XE := -230.0

var road
var world: ChunkWorld
var car: CharacterBody3D
var parts: Dictionary = {}
var qa_fixture := false
var tz := -900.0
var dir_sign := -1.0
var spots: Array = []
var in_car := false
var speed := 0.0
var steer := 0.0
var look_yaw := 0.0
var look_pitch := 0.0
var engine_dead := false
var dying := 0.0
var crank_t := 0.0
var on_fire := false
var fragment_in := true
var fragment_seen := false
var exposure := 0.0
var beings_frozen := false
var captured := false
var legs: Array = []
var legs_said := false
var legs_anchor := Vector3.INF     # captures only: ring the legs round this point
var progress := 0.0
var hour_said := 0
var end_built := false
var x_end := QA_XE
var press_t := 0.0
var parked_t := 0.0
var parked_stage := 0
var whisper_t := 95.0
var crashed := false
var _lamp_ids: Array = []
var _lamp_phase: Array = []
var _engine: AudioStreamPlayer
var _rumble: AudioStreamPlayer
var _tunnel_hum: AudioStreamPlayer
var _smiler: Node3D
var _smiler_t := 0.0
var _fire_fx: Node3D
var _hint_said := {}


func build() -> void:
	qa_fixture = SessionState.is_qa()
	rules["view_distance"] = 160.0
	rules["flashlight"] = "allowed"
	rules["reverb_room"] = 0.4
	rules["reverb_wet"] = 0.14
	rules["kill_y"] = -60.0
	indoor_env(Color(0.03, 0.03, 0.035), 0.06, Color(0.0, 0.0, 0.0), 0.012)
	environment.background_color = Color(0, 0, 0)
	environment.volumetric_fog_enabled = true
	environment.volumetric_fog_density = 0.035
	environment.volumetric_fog_albedo = Color(0.6, 0.61, 0.63)
	environment.volumetric_fog_length = 56.0
	environment.volumetric_fog_ambient_inject = 0.0
	environment.volumetric_fog_detail_spread = 1.6
	environment.tonemap_exposure = 1.15
	environment.glow_intensity = 0.5
	environment.glow_hdr_threshold = 0.9
	environment.ssao_enabled = false
	# the seed places the car, the tunnel ahead of it and the soft spots in the walls
	dir_sign = -1.0 if rng.randf() < 0.5 else 1.0
	var lane: float = LANES[rng.randi_range(0, 3)]
	var yaw := (0.0 if dir_sign < 0.0 else 180.0) + rng.randf_range(-14.0, 14.0)
	tz = dir_sign * (760.0 + float(rng.randi_range(0, 8)) * 45.0)
	for kk in range(1, 7):
		for sg in [-1.0, 1.0]:
			var z: float = sg * (260.0 + float(kk - 1) * 520.0) + rng.randf_range(-60.0, 60.0)
			var side := -1.0 if rng.randf() < 0.5 else 1.0
			if absf(z - tz) > 90.0:
				spots.append({"z": z, "side": side})
	Road.materials()
	road = Road.new(self, level_seed, tz, spots)
	lights.setup(10, 0)
	lights.max_distance = 60.0
	var tk := kit("Tunnel")
	road.tunnel(tk)
	tk.commit()
	for p in road.lamp_positions():
		_lamp_ids.append(lights.add_anchor(p, Color(1.0, 0.85, 0.62), 0.0, 9.0))
		_lamp_phase.append(rng.randf())
	world = ChunkWorld.new()
	world.name = "Highway"
	world.chunk_size = Road.CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = road.build_chunk
	add_child(world)
	_make_car(PAINTS[rng.randi_range(0, PAINTS.size() - 1)], rng.randf() < 0.3)
	var start_pos: Vector3
	var start_yaw: float
	if qa_fixture:
		_fixture_tunnel_end()
		start_pos = Vector3(QA_XE + 13.0, 0.02, tz - 0.9)
		start_yaw = 90.0
	else:
		car.global_position = Vector3(lane, 0.0, 0.0)
		car.rotation.y = deg_to_rad(yaw)
		start_pos = car.to_global(Car.SEAT_EXIT_L) + Vector3(0, 0.02, 0)
		start_yaw = yaw
	for tag in ["start", "from_L003", "from_L008", "from_L022"]:
		add_arrival(tag, start_pos, start_yaw)
	world.build_around(start_pos, 2)
	_sounds()
	add_landmark("Your car", car.global_position)
	add_landmark("Perpendicular tunnel (to Level 11)", Vector3(-12.0, 0.0, tz))
	add_shot("highway_headlights", Vector3(7.4, 1.6, 40.0), Vector3(5.6, 1.1, 24.0), {"prepare": _prep_highway, "flashlight": true})
	add_shot("tunnel_portal", Vector3(3.2, 1.6, tz + 14.5 * -dir_sign), Vector3(-11.0, 1.8, tz), {"prepare": _prep_portal, "flashlight": true})
	add_shot("beings_from_above", Vector3(3.3, 1.5, 34.5), Vector3(2.15, 3.8, 18.0), {"prepare": _prep_beings, "flashlight": false})
	add_shot("tunnel_walkout", Vector3(QA_XE + 7.0, 0.6 + 1.62, tz + 2.3), Vector3(QA_XE - 25.0, 1.6, tz - 0.2), {"prepare": _prep_tunnel, "flashlight": false})


func _make_car(paint: Color, left_dead: bool) -> void:
	car = CharacterBody3D.new()
	car.name = "Car"
	car.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	car.collision_layer = 1
	car.collision_mask = 1
	car.safe_margin = 0.02
	add_child(car)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(1.84, 1.08, 4.52)
	cs.shape = bs
	cs.position = Vector3(0, 0.9, 0)
	car.add_child(cs)
	parts = Car.build(car, paint, left_dead)
	make_interactable(Vector3(-0.95, 1.0, 0.15), Vector3(0.4, 1.0, 1.3), "Get in the car", _enter_car, car)
	make_interactable(Vector3(0.95, 1.0, 0.15), Vector3(0.4, 1.0, 1.3), "Get in the car", _enter_car, car)
	make_interactable(Vector3(0, 0.22, 0.15), Vector3(2.3, 0.3, 1.4), "Search under the car", _search_under, car)


## QA only: the seventeen hours are already behind you; the car has died.
func _fixture_tunnel_end() -> void:
	progress = 1.0
	engine_dead = true
	car.global_position = Vector3(QA_XE + 22.0, 0.0, tz - 0.9)
	car.rotation.y = deg_to_rad(90.0)
	_build_end(QA_XE)


func _build_end(xe: float) -> void:
	if end_built:
		return
	end_built = true
	x_end = xe
	var node := Node3D.new()
	node.name = "TunnelEnd"
	add_child(node)
	make_exit("L069>L011#1", "walk_in", Vector3(xe - 25.3, 1.26 + 1.2, tz), Vector3(1.0, 2.4, 2.2), "", node)
	road.end_piece(node, xe)


# ------------------------------------------------------------------ the car

func _enter_car() -> void:
	if in_car or player == null or captured:
		return
	if on_fire:
		Overlay.subtitle("[the car is burning. You cannot get back in]", 3.0)
		return
	in_car = true
	player.frozen = true
	look_yaw = 0.0
	look_pitch = 0.0
	_seat_player()
	if fragment_in:
		Overlay.subtitle("[you pull the door shut. The fog draws back from the glass]", 3.5)
	else:
		Overlay.subtitle("[you pull the door shut, but the fog stays pressed against the glass]", 3.5)


func _exit_car() -> void:
	if not in_car:
		return
	if absf(speed) > 1.5:
		Overlay.subtitle("[not while the car is moving]", 2.0)
		return
	var spot := car.to_global(Car.SEAT_EXIT_L)
	if not _clear_at(spot):
		spot = car.to_global(Car.SEAT_EXIT_R)
	in_car = false
	speed = 0.0
	player.global_position = spot + Vector3(0, 0.05, 0)
	player.rotation = Vector3(0, car.rotation.y + look_yaw, 0)
	player.frozen = false
	if not _hint_said.has("out"):
		_hint_said["out"] = true
		Overlay.subtitle("[you step out onto the asphalt. The dark overhead is very quiet]", 4.0)


func _clear_at(p: Vector3) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = Player.RADIUS
	cap.height = Player.HEIGHT_STAND
	q.shape = cap
	q.transform = Transform3D(Basis(), p + Vector3.UP * (Player.HEIGHT_STAND * 0.5 + 0.05))
	q.collision_mask = 1
	return get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()


func _seat_player() -> void:
	player.global_position = car.to_global(Car.EYE) - Vector3.UP * Player.EYE_STAND
	player.rotation = Vector3(0, car.rotation.y + look_yaw, 0)
	player.look_pitch = look_pitch
	player.head.rotation.x = look_pitch


func _search_under() -> void:
	if in_car:
		return
	if not fragment_seen:
		fragment_seen = true
		Overlay.show_note("Under the car",
			"Lying on the asphalt you find a well hidden compartment at the bottom centre of the car. In its slot sits a thick, triangular thing like a shard of glass. A tiny label is inscribed on the slot.\n\nPeople call it the Fragment Of Destivinatia (Object 69). While it is in its slot, the car keeps the fog and the things in it away. Take it out and that stops.")
		return
	_toggle_fragment()


func _toggle_fragment() -> void:
	fragment_in = not fragment_in
	(parts["bubble"] as FogVolume).visible = fragment_in
	(parts["fragment"] as Node3D).get_node("Shard").visible = fragment_in
	if fragment_in:
		Overlay.subtitle("[the shard clicks back into its slot; the fog slides away from the car]", 3.5)
	else:
		Overlay.subtitle("[you lift the shard out. At once the fog rolls in against the car]", 3.5)


func _unhandled_input(event: InputEvent) -> void:
	if not in_car or player == null or Overlay.is_menu_open():
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens: float = Settings.get_value("mouse_sensitivity")
		var inv := -1.0 if Settings.get_value("invert_y") else 1.0
		look_yaw = clampf(look_yaw - event.relative.x * sens, -2.2, 2.2)
		look_pitch = clampf(look_pitch - event.relative.y * sens * inv, deg_to_rad(-60), deg_to_rad(50))
	elif event.is_action_pressed("interact"):
		if look_pitch > 0.42 and absf(look_yaw) < 0.7:
			_read_visor()
		else:
			_exit_car()
	elif event.is_action_pressed("flashlight"):
		player.toggle_flashlight()


func _read_visor() -> void:
	Overlay.show_note("A card tucked into the sun visor",
		"DO NOT GET OUT OF THE CAR. It is the only safe place here: the fog and the things in it keep away from cars. If you have to get out, stay right beside it.\n\nIt needs no fuel. Keep your eyes on the walls: the way out is a tunnel at a right angle to the road. Expect to drive through it for about seventeen hours.\n\nDrive fast and you might crash; crashing here usually kills. Park too long and something may find you.\n\n(paraphrase of the Level 69 page)")


func _physics_process(delta: float) -> void:
	if not built or player == null:
		return
	if in_car:
		var thr := Input.get_axis("move_back", "move_forward")
		var st := Input.get_axis("move_right", "move_left")
		_drive(delta, thr, st, Input.is_action_pressed("jump"))
		_seat_player()
		_noclip_press(delta, thr)
	_treadmill()


## One step of the car: bicycle steering, no fuel, walls stop or kill.
func _drive(delta: float, thr: float, st_in: float, brake: bool) -> void:
	if engine_dead or dying > 0.0 or on_fire:
		if engine_dead and absf(thr) > 0.1 and not on_fire:
			crank_t += delta
			if crank_t > 7.0:
				_catch_fire()
		thr = 0.0 if engine_dead else minf(thr, 0.0)
	var max_st := lerpf(0.55, 0.1, clampf(absf(speed) / 32.0, 0.0, 1.0))
	steer = move_toward(steer, st_in * max_st, delta * 1.6)
	var acc := 0.0
	if thr > 0.0:
		acc = (5.5 if speed >= -0.2 else 10.0) * thr
	elif thr < 0.0:
		acc = (10.0 if speed > 0.2 else 3.5) * thr
	speed += acc * delta
	if brake:
		speed = move_toward(speed, 0.0, 14.0 * delta)
	if absf(thr) < 0.05:
		speed = move_toward(speed, 0.0, 0.6 * delta)
	if dying > 0.0:
		dying -= delta
		speed = move_toward(speed, 0.0, 4.0 * delta)
		if dying <= 0.0:
			engine_dead = true
			Overlay.subtitle("[the engine shudders and dies. It will not turn over again]", 4.0)
	speed -= speed * 0.05 * delta
	speed = clampf(speed, -6.0, 33.0)
	car.rotation.y += speed / 2.7 * tan(steer) * delta
	var fwd := -car.global_transform.basis.z
	var pre := fwd * speed
	car.velocity = pre
	car.move_and_slide()
	var impact := 0.0
	for i in car.get_slide_collision_count():
		var n := car.get_slide_collision(i).get_normal()
		if absf(n.y) < 0.6:
			impact = maxf(impact, -pre.dot(n))
	if impact > 0.0:
		_impact(impact)
	speed = car.velocity.dot(fwd) if impact > 0.0 else speed
	car.global_position.y = 0.0
	if end_built and car.global_position.x < x_end + 6.0 and absf(car.global_position.z - tz) < 4.0:
		speed = minf(speed, 0.0)
	for w in parts.get("wheels", []):
		(w as Node3D).rotate_object_local(Vector3.RIGHT, -speed * delta / 0.33)
	(parts["steer"] as Node3D).rotation.y = steer * 1.6


func _impact(v: float) -> void:
	if crashed:
		return
	if v > 13.0:
		crashed = true
		sound.play_at("distant_boom", {}, car.global_position, 0.0, "[metal and concrete, all at once]")
		Overlay.glitch(1.0)
		in_car = false
		player.frozen = false
		player.hurt(1000.0, "crashed into the highway wall")
	elif v > 2.5:
		sound.play_at("knock", {"hits": 1}, car.global_position, -4.0, "[the car slams into the wall]")
		speed *= 0.35
	else:
		if not _hint_said.has("scrape"):
			_hint_said["scrape"] = true
			sound.play_at("scratch", {"seconds": 1.0}, car.global_position, -10.0, "[the side of the car scrapes along the concrete]")


func _catch_fire() -> void:
	if on_fire:
		return
	on_fire = true
	Overlay.subtitle("[smoke pours from under the hood, then flame. Get out]", 4.0)
	_fire_fx = Node3D.new()
	_fire_fx.position = Vector3(0, 0.95, -1.6)
	car.add_child(_fire_fx)
	for i in 2:
		var p := CPUParticles3D.new()
		p.amount = 40 if i == 0 else 24
		p.lifetime = 1.2 if i == 0 else 3.0
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = Vector3(0.6, 0.05, 0.5)
		p.direction = Vector3.UP
		p.spread = 15.0
		p.gravity = Vector3(0, 1.5 if i == 0 else 0.8, 0)
		p.initial_velocity_min = 0.6
		p.initial_velocity_max = 1.6
		p.scale_amount_min = 0.3
		p.scale_amount_max = 0.7 if i == 0 else 1.6
		var q := QuadMesh.new()
		q.size = Vector2(0.5, 0.5)
		var m := StandardMaterial3D.new()
		m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if i == 0 else BaseMaterial3D.SHADING_MODE_PER_PIXEL
		m.albedo_color = Color(1.0, 0.5, 0.12, 0.8) if i == 0 else Color(0.12, 0.12, 0.12, 0.5)
		q.material = m
		p.mesh = q
		_fire_fx.add_child(p)
	var fl := OmniLight3D.new()
	fl.light_color = Color(1.0, 0.5, 0.15)
	fl.light_energy = 3.0
	fl.omni_range = 8.0
	_fire_fx.add_child(fl)
	sound.emitter("crackle", car.global_position + Vector3(0, 1, 0), {}, -6.0, 18.0)
	if in_car:
		player.hurt(20.0, "the car caught fire")
		speed = 0.0
		_exit_car()


## The no-clip to Level 22: the car must lean into the right panel of the wall.
func _noclip_press(delta: float, thr: float) -> void:
	var near := false
	for sp in spots:
		var s: float = sp["side"]
		if absf(car.global_position.z - float(sp["z"])) < 2.6 and car.global_position.x * s > Road.WALL_X - 1.9 and thr > 0.3 and absf(speed) < 1.5:
			near = true
	if near:
		press_t += delta
		if press_t > 0.8 and not _hint_said.has("give"):
			_hint_said["give"] = true
			Overlay.subtitle("[the concrete gives, very slightly, under the bumper]", 3.0)
			Overlay.glitch(0.35)
	else:
		press_t = maxf(0.0, press_t - delta * 2.0)


func _noclip_ready(z: float, side: float) -> bool:
	return in_car and press_t > 2.6 and absf(car.global_position.z - z) < 3.0 and car.global_position.x * side > Road.WALL_X - 2.0


## The tunnel is uniform: while the seventeen hours run, the drive loops.
func _treadmill() -> void:
	if not in_car or progress >= 1.0:
		return
	var p := car.global_position
	if p.x < -200.0 and absf(p.z - tz) < 4.0 and speed > 0.0:
		car.global_position.x += 160.0
		_seat_player()


# ------------------------------------------------------------- per frame

func level_process(delta: float) -> void:
	if player == null:
		return
	var pp := player.global_position
	var in_tunnel := pp.x < -10.3 and absf(pp.z - tz) < 4.0
	world.target = car if in_car else player
	_tunnel(delta, in_tunnel)
	_beings(delta, in_tunnel)
	_parked(delta, in_tunnel)
	_whispers(delta, in_tunnel)
	_audio(in_tunnel)


func _tunnel(delta: float, in_tunnel: bool) -> void:
	if in_tunnel and in_car and not engine_dead and dying <= 0.0 and speed > 3.0 and progress < 1.0:
		progress = minf(1.0, progress + delta / TUNNEL_SECONDS)
		var h := int(progress * 17.0)
		if h > hour_said and h % 2 == 0:
			hour_said = h
			Overlay.subtitle("[hour %d in the tunnel. %s]" % [h, "The fog is thinner" if h < 12 else "Most of the roof lights are on"], 3.0)
		if progress >= 1.0:
			dying = 4.0
			Overlay.subtitle("[seventeen hours. The engine begins to cough]", 3.5)
			_build_end(floorf((car.global_position.x - 95.0) / 10.0) * 10.0)
	for i in _lamp_ids.size():
		var ph: float = _lamp_phase[i]
		lights.anchors[_lamp_ids[i]]["energy"] = 2.4 * smoothstep(0.1 + ph * 0.6, 0.18 + ph * 0.6, progress)
	(MatLib.get_mat("l69_lamp") as StandardMaterial3D).emission_energy_multiplier = 3.5 * progress
	var fog := lerpf(0.035, 0.003, progress) if in_tunnel else 0.035
	environment.volumetric_fog_density = fog
	environment.fog_density = lerpf(0.012, 0.002, progress) if in_tunnel else 0.012


## The Beings From Above: an exposure clock while you are outside the car (or
## the Fragment is out). Near the car it runs slowly. In the tunnel, never.
func _beings(delta: float, in_tunnel: bool) -> void:
	if captured:
		return
	if not beings_frozen:
		var exposed := (not in_car or not fragment_in) and not in_tunnel and not (qa_fixture and not beings_frozen)
		if exposed:
			var near := player.global_position.distance_to(car.global_position) < 4.0 and fragment_in
			var rate := 0.35 if near else 1.0
			if not fragment_in:
				rate *= 1.6
			exposure += rate * delta
		else:
			exposure = maxf(0.0, exposure - 2.0 * delta)
	var e := exposure / CAPTURE
	if e > 0.06 and legs.is_empty():
		_make_legs()
	for i in legs.size():
		var leg: Node3D = legs[i]
		leg.visible = e > 0.06
		if not leg.visible:
			continue
		var a := TAU * float(i) / legs.size() + (0.0 if beings_frozen else sin(Time.get_ticks_msec() * 0.0003 + i) * 0.2)
		var r := lerpf(9.0, 1.3, smoothstep(0.1, 1.0, e)) + float(i % 3) * 0.7
		var tip_y := lerpf(24.0, 0.25, smoothstep(0.06, 0.95, e)) + float(i % 2) * 1.5 * (1.0 - e)
		var c := player.global_position if legs_anchor == Vector3.INF else legs_anchor
		leg.global_position = Vector3(c.x + cos(a) * r, tip_y, c.z + sin(a) * r)
		leg.rotation = Vector3(0.0, -a, 0.0)
	if e > 0.25 and not legs_said:
		legs_said = true
		Overlay.subtitle("[long, jointed legs are lowering out of the dark above. They make no sound]", 4.5)
	if e < 0.05:
		legs_said = false
	if e >= 1.0 and not captured:
		captured = true
		Overlay.glitch(1.0)
		player.hurt(1000.0, "taken up into the dark by the Beings From Above")


func _make_legs() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.14, 0.13, 0.12)
	m.roughness = 0.1
	m.metallic = 0.55
	for i in 7:
		var leg := Node3D.new()
		leg.name = "BeingLeg%d" % i
		add_child(leg)
		# lower segment from the tip to the knee, upper segment up into the dark
		var lo := MeshInstance3D.new()
		var cl := CylinderMesh.new()
		cl.top_radius = 0.13
		cl.bottom_radius = 0.01
		cl.height = 3.2
		cl.radial_segments = 6
		lo.mesh = cl
		lo.material_override = m
		lo.position = Vector3(0.0, 1.5, 0.45)
		lo.rotation.x = 0.29
		leg.add_child(lo)
		var hi := MeshInstance3D.new()
		var ch := CylinderMesh.new()
		ch.top_radius = 0.24
		ch.bottom_radius = 0.14
		ch.height = 40.0
		ch.radial_segments = 6
		hi.mesh = ch
		hi.material_override = m
		hi.position = Vector3(0.0, 3.0 + 20.0 * cos(0.35), 0.9 + 20.0 * sin(0.35))
		hi.rotation.x = 0.35
		leg.add_child(hi)
		var knee := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.2
		sm.height = 0.4
		sm.radial_segments = 8
		sm.rings = 4
		knee.mesh = sm
		knee.material_override = m
		knee.position = Vector3(0.0, 3.0, 0.9)
		leg.add_child(knee)
		legs.append(leg)


## Do not park for too long: something in the fog notices.
func _parked(delta: float, in_tunnel: bool) -> void:
	if qa_fixture:
		return
	if in_car and absf(speed) < 0.3 and not in_tunnel:
		parked_t += delta
	elif absf(speed) > 5.0 or in_tunnel:
		parked_t = 0.0
		parked_stage = 0
	if parked_stage == 0 and parked_t > 150.0:
		parked_stage = 1
		_show_smiler()
	elif parked_stage == 1 and parked_t > 240.0:
		parked_stage = 2
		sound.play_at("scratch", {"seconds": 2.0}, car.global_position + car.global_transform.basis.x * 1.2, -4.0, "[something drags its nails slowly along the side of the car]")
	elif parked_stage == 2 and parked_t > 320.0:
		parked_stage = 3
		sound.play_at("knock", {"hits": 3}, car.global_position + car.global_transform.basis.x * 1.0 + Vector3.UP, 0.0, "[a fist strikes the window, three times. Drive]")
		Overlay.glitch(0.5)
	if _smiler and _smiler.visible:
		_smiler_t -= delta
		if _smiler_t <= 0.0:
			_smiler.visible = false


func _show_smiler() -> void:
	if _smiler == null:
		_smiler = Node3D.new()
		_smiler.name = "SmilerGlimpse"
		add_child(_smiler)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(0.92, 0.92, 0.88)
		for x in [-0.22, 0.22]:
			var eye := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.05
			sm.height = 0.1
			eye.mesh = sm
			eye.material_override = m
			eye.position = Vector3(x, 0.3, 0)
			_smiler.add_child(eye)
		for i in 13:
			var a := lerpf(-1.1, 1.1, float(i) / 12.0)
			var tooth := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.05, 0.07, 0.02)
			tooth.mesh = bm
			tooth.material_override = m
			tooth.position = Vector3(sin(a) * 0.38, -cos(a) * 0.16, 0)
			_smiler.add_child(tooth)
	var fwd := -car.global_transform.basis.z
	_smiler.global_position = car.global_position + fwd * 26.0 + Vector3(car.global_transform.basis.x.x * 3.0, 1.6, 0)
	_smiler.look_at(car.global_position + Vector3.UP * 1.6, Vector3.UP)
	_smiler.rotate_object_local(Vector3.UP, PI)
	_smiler.visible = true
	_smiler_t = 3.0
	Overlay.subtitle("[a wide white grin hangs in the fog beyond the headlights, then is gone]", 4.0)


## The Whispers (REPORTED): the same thought arrives in every head at once.
func _whispers(delta: float, in_tunnel: bool) -> void:
	if qa_fixture or in_tunnel:
		return
	whisper_t -= delta
	if whisper_t <= 0.0:
		whisper_t = rng.randf_range(70.0, 150.0)
		var line: String = WHISPERS[rng.randi_range(0, WHISPERS.size() - 1)]
		sound.play_at("whisper", {"seconds": 2.4}, player.global_position + Vector3(0, 1.6, 0), -12.0, "")
		Overlay.subtitle("[a thought that is not yours: \"%s\"]" % line, 4.5)


func _sounds() -> void:
	sound.bed("wind", {"seconds": 10.0}, -34.0)
	sound.bed("room_tone", {"cutoff": 140.0, "rumble": 0.6}, -38.0)
	_engine = sound.bed("transformer", {"base": 38.0, "seconds": 4.0}, -80.0)
	_rumble = sound.bed("room_tone", {"cutoff": 600.0, "rumble": 1.0, "seconds": 5.0}, -80.0)
	_tunnel_hum = sound.bed("fluorescent_hum", {"base": 60.0}, -80.0)


func _audio(in_tunnel: bool) -> void:
	var running := in_car and not engine_dead and not on_fire
	_engine.volume_db = lerpf(_engine.volume_db, -22.0 if running else -80.0, 0.08)
	_engine.pitch_scale = 0.7 + absf(speed) / 28.0
	_rumble.volume_db = lerpf(_rumble.volume_db, (-40.0 + absf(speed) * 0.7) if in_car else -80.0, 0.08)
	_tunnel_hum.volume_db = lerpf(_tunnel_hum.volume_db, (-40.0 + 14.0 * progress) if in_tunnel else -80.0, 0.05)


func on_player_ready() -> void:
	if qa_fixture:
		return
	_enter_car()
	Overlay.toast("You wake behind the wheel. W/S drive, A/D steer, Space brakes, E gets out. Look up at the visor and press E to read it.", 8.0)
	Overlay.toast("Content note: this page describes people being carried off by entities and dying in crashes. Nothing graphic is shown.", 7.0)


# ------------------------------------------------------------- captures

func _prep_highway() -> void:
	in_car = false
	beings_frozen = true
	exposure = 0.0
	car.global_position = Vector3(2.15, 0.0, 30.0)
	car.rotation.y = 0.0
	world.build_around(Vector3(0, 0, 30.0), 2)
	await get_tree().process_frame


func _prep_portal() -> void:
	in_car = false
	beings_frozen = true
	exposure = 0.0
	car.global_position = Vector3(-2.0, 0.0, tz + 9.0 * -dir_sign)
	car.rotation.y = deg_to_rad(90.0 + 25.0 * dir_sign)
	world.build_around(Vector3(0, 0, tz), 2)
	await get_tree().process_frame


func _prep_beings() -> void:
	in_car = false
	beings_frozen = true
	car.global_position = Vector3(2.15, 0.0, 30.0)
	car.rotation.y = 0.0
	world.build_around(Vector3(0, 0, 26.0), 2)
	exposure = CAPTURE * 0.72
	# the legs come down in the headlight beams, a few metres ahead of the car
	legs_anchor = Vector3(2.15, 0.0, 19.0)
	await get_tree().process_frame


func _prep_tunnel() -> void:
	legs_anchor = Vector3.INF
	exposure = 0.0
	in_car = false
	beings_frozen = true
	exposure = 0.0
	car.global_position = Vector3(QA_XE + 22.0, 0.0, tz - 0.9)
	car.rotation.y = deg_to_rad(90.0)
	await get_tree().process_frame


# ------------------------------------------------------------------ QA

func _ray(a: Vector3, b: Vector3) -> Dictionary:
	return get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(a, b, 1))


func qa_self_test() -> Array:
	await get_tree().physics_frame
	var out: Array = []
	var lane := _ray(Vector3(-120.0, 2.0, tz - 1.0), Vector3(-120.0, -2.0, tz - 1.0))
	out.append({"what": "tunnel lane collides", "ok": not lane.is_empty() and absf(lane["position"].y) < 0.05, "detail": lane.get("position")})
	var walk := _ray(Vector3(-120.0, 2.0, tz + 2.3), Vector3(-120.0, -2.0, tz + 2.3))
	out.append({"what": "tunnel walkway at +0.6 m", "ok": not walk.is_empty() and absf(walk["position"].y - 0.6) < 0.05, "detail": walk.get("position")})
	var land := _ray(Vector3(QA_XE - 12.0, 3.0, tz), Vector3(QA_XE - 12.0, -2.0, tz))
	out.append({"what": "tunnel end landing at +1.26 m", "ok": not land.is_empty() and absf(land["position"].y - 1.26) < 0.05, "detail": land.get("position")})
	var stair := _ray(Vector3(QA_XE - 1.0, 3.0, tz - 1.0), Vector3(QA_XE - 1.0, -2.0, tz - 1.0))
	out.append({"what": "end stair ramp collision", "ok": not stair.is_empty() and stair["position"].y > 0.3 and stair["position"].y < 1.1, "detail": stair.get("position")})
	# the car drives: throttle moves it forward, the dead engine does not
	var p0 := car.global_position
	var was_dead := engine_dead
	engine_dead = false
	speed = 0.0
	for i in 40:
		_drive(1.0 / 60.0, 1.0, 0.0, false)
		await get_tree().physics_frame
	var moved := car.global_position.distance_to(p0)
	out.append({"what": "car accelerates under throttle (no fuel needed)", "ok": moved > 0.5 and speed > 2.0, "detail": [moved, speed]})
	car.global_position = p0
	speed = 0.0
	engine_dead = was_dead
	var p1 := car.global_position
	for i in 20:
		_drive(1.0 / 60.0, 1.0, 0.0, false)
	out.append({"what": "dead engine does not move the car", "ok": car.global_position.distance_to(p1) < 0.05})
	crank_t = 0.0
	# fragment toggles the clear air around the car
	_toggle_fragment()
	var off := not (parts["bubble"] as FogVolume).visible
	_toggle_fragment()
	out.append({"what": "fragment removal collapses the fog bubble", "ok": off and (parts["bubble"] as FogVolume).visible})
	# the beings: exposure accumulates outside the car and ends in capture
	beings_frozen = true
	exposure = CAPTURE * 0.5
	_beings(0.0, false)
	out.append({"what": "legs descend when exposed", "ok": legs.size() == 7 and (legs[0] as Node3D).visible and (legs[0] as Node3D).global_position.y < 20.0})
	exposure = 0.0
	_beings(0.0, false)
	beings_frozen = false
	out.append({"what": "noclip spots seeded away from the tunnel", "ok": spots.size() >= 8 and spots.all(func(s): return absf(float(s["z"]) - tz) > 90.0), "detail": spots.size()})
	out.append({"what": "noclip needs the car pressed to the wall", "ok": not _noclip_ready(float(spots[0]["z"]), float(spots[0]["side"]))})
	return out
