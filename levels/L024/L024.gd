extends LevelBase
## Level 24 "The Moon" (Backrooms Wikidot rev 33, accessed 2026-11-04; DrAkimoto,
## CC BY-SA 3.0). Dossier: docs/canon/levels/L024.md.
##
## PLAN (read -> design):
## - SOURCE: a 1:1 plastic scale model of the solar system; only the Moon is accessible;
##   its top ~30 m is lead-based light grey paint over HDPE-polystyrene; standard gravity.
##   -> a painted grey lunar plain with craters (terrain heightfield, 1.6 x 0.5 km walkable,
##   far surface to the horizon); pits cut through the paint show the plastic beneath.
##   Normal gravity. Black sky; the Sun and a planet as model bodies; the "Victorian
##   study" round the model is never shown, only a faint warmth at the horizon.
## - SOURCE: B.N.T.G. PlasticWorks, a new automated mine about 1 km from Bluehole: mining
##   columns, three crews living on site, ~300 t a day, recruiting; the only way out is
##   to follow the road to its main gate, where miners show you out. -> three benched
##   mining columns under gantry cranes (ramps down 8 m), a processing shed with
##   conveyors, pallets of plastic and a control mezzanine, a fenced crew compound with
##   lit prefab quarters and the main gate (L024>EXT#1, walk_in), floodlight masts and
##   orange marker poles along the road.
## - SOURCE/TESTIMONY: the Bluehole ("Bluehell") 1.3 km down the road: shaft through the
##   paint into plastic dyed blue by paint thinner, the caustic pool, the main gantry
##   whose pulley failed, Hot-Shovels (propane, up to 530 C), the reports (paraphrased).
## - SOURCE entities: Moon Mites (giant, harmless, avoid people, 6-8 mating pairs,
##   shallow burrows of 25-50 cream eggs, commonest after dust storms) and Beauford (an
##   incomprehensibly large humanoid, only seen far off; its approach brings one of the
##   two weathers; vocalisations heard and felt). Never chased, never fought.
## - Stateful signature: the weather cycle. Calm -> Beauford approaches (PlasticWorks
##   alarms, a vast silhouette at the horizon, the light dims, low vocalisations shake
##   the ground) -> either the lemon-smelling toxic mist (hurts while you stand in the
##   open; shelter under a roof) or the sandstorm of skin, plastic, hair and fibres
##   (visibility drops; oversized flakes) -> clear; after a storm a new mite group
##   appears nearby and keeps its distance.
## - ADAPTATION: site layouts, distances (1.3 km), the shed, compound and road markers,
##   the timing of the cycle; the exit destination is not stated (EXT).

const T := preload("res://levels/L024/L024_terrain.gd")
const W := preload("res://levels/L024/L024_works.gd")
const BHS := preload("res://levels/L024/L024_bluehole.gd")
const Life := preload("res://levels/L024/L024_life.gd")
const SKY := """
shader_type sky;
uniform vec3 warm : source_color = vec3(0.05, 0.032, 0.018);
uniform vec3 planet_dir = vec3(-0.45, 0.32, -0.83);
uniform float dim = 1.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
void sky() {
	vec3 d = EYEDIR;
	float e = max(d.y, 0.0);
	vec3 col = warm * exp(-e * 7.0) * (0.6 + 0.4 * hash(floor(d.xz * 3.0)) * 0.0);
	if (d.y < 0.0) { col = warm * 0.4; }
	vec3 sd = normalize(LIGHT0_DIRECTION);
	float s = dot(d, sd);
	col += vec3(1.0, 0.95, 0.85) * (smoothstep(0.9993, 0.9996, s) * 14.0 + pow(max(s, 0.0), 300.0) * 0.6) * dim;
	vec3 pd = normalize(planet_dir);
	float pdot = dot(d, pd);
	float disc = smoothstep(0.99955, 0.9997, pdot);
	vec3 lit = vec3(0.25, 0.42, 0.75) * (0.4 + 0.6 * clamp(dot(normalize(d - pd * pdot + sd * 0.01), sd) * 0.5 + 0.5, 0.0, 1.0));
	col = mix(col, lit, disc);
	COLOR = col;
}
"""

var ter
var works
var bh
var life
var sky_mat: ShaderMaterial
var state := "calm"
var state_t := 0.0
var weather := ""
var beau_k := 0.0
var shelter_t := 0.0
var said := {}
var cycles := 0
var sun_e0 := 1.6
var _sirens: Array = []
var _boom_t := 0.0
var _hurt_t := 0.0
var _shake := 0.0
var gate_miners: Array = []
var START := Vector3(232.0, 0.0, 1.5)


func build() -> void:
	rules["gravity"] = 9.8
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 9000.0
	rules["kill_y"] = -60.0
	rules["reverb_room"] = 0.1
	rules["reverb_wet"] = 0.04
	outdoor_env(Color(0, 0, 0), Color(0.03, 0.02, 0.01), Color(0.02, 0.02, 0.02), Vector2(14.0, 115.0), Color(1.0, 0.97, 0.92), sun_e0, Color(0.03, 0.025, 0.02), 0.00012)
	var sh := Shader.new()
	sh.code = SKY
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = sh
	environment.sky.sky_material = sky_mat
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.58, 0.65)
	environment.ambient_light_energy = 0.32
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.fog_sky_affect = 0.0
	environment.tonemap_exposure = 1.0
	environment.glow_intensity = 0.5
	sun.directional_shadow_max_distance = 160.0
	sun.shadow_blur = 0.4
	W.materials()
	Life.materials()
	ter = T.new()
	var ground := Node3D.new()
	ground.name = "Moon"
	add_child(ground)
	ter.build_meshes(ground, ter.make_material())
	ter.build_collision(ground)
	works = W.new(self, ter, rng)
	works.build_all()
	bh = BHS.new(self, ter, rng, works.props)
	bh.build_all()
	bh.k.commit()
	lights.setup(10, 0)
	lights.max_distance = 70.0
	for lp in works.light_pts:
		lights.add_anchor(lp[0], lp[1], lp[2], lp[3])
	lights.add_anchor(bh.spots["light"], Color(1.0, 0.9, 0.75), 1.6, 14.0, 0.15)
	life = Life.new(self, ter)
	life.make_beauford()
	life.make_weather()
	life.group(Vector3(110.0, 0, 72.0), 7)
	life.burrow(Vector3(104.0, 0, 64.0), 38)
	life.burrow(Vector3(-430.0, 0, 70.0), 27)
	life.group(Vector3(-440.0, 0, 80.0), 6)
	_miners()
	_start_y()
	for spec in [["start", START, -90.0], ["from_L001", Vector3(214.0, 0, 24.0), -110.0], ["from_L020", Vector3(206.0, 0, -22.0), -70.0], ["from_L025", Vector3(244.0, 0, -28.0), -60.0]]:
		var p: Vector3 = spec[1]
		p.y = ter.h(p.x, p.z) + 0.05
		add_arrival(spec[0], p, spec[2])
	var gx: Vector3 = works.spots["gate"]
	var ex := add_exit("L024>EXT#1", "walk_in", gx + Vector3(1.0, 1.5, 0), Vector3(4.0, 3.0, 9.0), "")
	if ex:
		ex.fired.connect(func(_e: String) -> void:
			Overlay.subtitle("[the miners at the gate wave you through: \"Way out's this way.\"]", 3.5))
	add_note("l24_plasticworks", "PlasticWorks notice (gatehouse)",
		"B.N.T.G. PlasticWorks: built with safety and efficiency first. Automated columns, air-quality control, three crews on three-day shifts, nearly 300 tonnes a day. New recruits wanted. Lost? Follow the road to the main gate; the miners will see you out.",
		gx + Vector3(-5.6, 1.2, -9.5), Vector3(1.0, 1.4, 1.0))
	add_note("l24_weather", "Field card: weather on the Moon",
		"Two kinds, both tied to Beauford coming near: a brief toxic mist that smells of lemon (nausea, weakness; get under cover) and a dry storm of skin, plastic, lead, hair and fibre, in flakes far too big. Mites follow the storms. They are harmless.",
		Vector3(318.0, ter.h(318.0, 2.2) + 1.0, 2.2), Vector3(0.6, 1.0, 1.0))
	add_interactable(Vector3(104.0, ter.h(104.0, 64.0) + 0.4, 64.0), Vector3(3.0, 0.8, 3.0), "Look at the eggs",
		func() -> void: Overlay.subtitle("[a shallow scrape full of cream-coloured eggs, each bigger than a fist. Mite eggs. Staff have eaten them in lean times]", 4.5))
	_sounds()
	add_landmark("PlasticWorks main gate", gx)
	add_landmark("Mining column 1", works.spots["column1"])
	add_landmark("Processing shed", works.spots["shed"])
	add_landmark("The Bluehole", bh.spots["pool"])
	add_landmark("Mite burrow", Vector3(104.0, 0, 64.0))
	state_t = rng.randf_range(140.0, 220.0)
	_shots()


func _start_y() -> void:
	START.y = ter.h(START.x, START.z) + 0.05


func _miners() -> void:
	for p in works.spots["gate_miners"]:
		var q: Vector3 = p
		gate_miners.append(life.miner(q, -90.0))
	for i in 3:
		var c: Vector3 = works.spots["column%d" % (i + 1)]
		life.miner(c + Vector3(-3.0, 0, 3.0), 40.0 + i * 70.0)
		life.miner(c + Vector3(2.0, 0, -2.5), 200.0 + i * 30.0)
	var sh: Vector3 = works.spots["shed"]
	life.miner(sh + Vector3(-6.0, 0, 2.0), 90.0)
	life.miner(works.spots["mezzanine"], 180.0, false)


func _sounds() -> void:
	sound.bed("wind", {"seconds": 9.0}, -34.0)
	sound.bed("room_tone", {"cutoff": 90.0, "rumble": 0.4, "seconds": 8.0}, -32.0)
	sound.emitter("transformer", works.spots["shed"] + Vector3(0, 2, 0), {"base": 55.0, "seconds": 4.0}, -14.0, 70.0)
	sound.emitter("pipe_clank", works.spots["shed"] + Vector3(10, 1, 0), {"f": 220.0}, -22.0, 40.0)
	for i in 3:
		sound.emitter("fluorescent_hum", works.spots["column%d" % (i + 1)] + Vector3(0, 9, 0), {"base": 90.0, "seconds": 2.5}, -24.0, 30.0)
	sound.emitter("creak", bh.spots["pool"] + Vector3(0, 12, 0), {"freq": 70.0}, -18.0, 50.0)
	for p in [works.spots["gate"] + Vector3(-2, 5, 0), works.spots["shed"] + Vector3(0, 12, -20)]:
		var s := sound.emitter("pad", p, {"root": 520.0, "chord": [0, 3], "bright": 0.9, "seconds": 3.0}, -80.0, 600.0)
		_sirens.append(s)


func on_player_ready() -> void:
	if not SessionState.is_qa():
		Overlay.subtitle("[grey ground under a black sky, hard light, and your own weight exactly as usual. Floodlights and gantries ahead, along a road]", 5.0)


# --------------------------------------------------------------- weather cycle

func set_state(s: String) -> void:
	state = s
	match s:
		"approach":
			state_t = 38.0
			beauford_show(true)
			if not SessionState.is_qa():
				Overlay.subtitle("[sirens at PlasticWorks: Beauford is near. Something vast rises past the horizon]", 5.0)
		"weather":
			state_t = rng.randf_range(45.0, 70.0)
			weather = "mist" if rng.randf() < 0.5 else "storm"
			if not SessionState.is_qa():
				Overlay.subtitle("[a fine mist drifts down. It smells sharply of lemon. Get under cover]" if weather == "mist" else
					"[a dry storm sweeps in: flakes of skin and plastic, hair, fibres, some as big as your hand]", 5.0)
		"clear":
			state_t = 20.0
			if weather == "storm":
				var pp := player.global_position if player else START
				var a := rng.randf() * TAU
				life.group(pp + Vector3(cos(a) * 45.0, 0, sin(a) * 45.0), rng.randi_range(6, 8))
				if not SessionState.is_qa():
					Overlay.subtitle("[the storm passes. Out on the grey, pale shapes the size of dogs: mites, already moving away from you]", 5.0)
		"calm":
			state_t = rng.randf_range(160.0, 260.0)
			weather = ""
			cycles += 1


func beauford_show(on: bool) -> void:
	if is_instance_valid(life.beauford):
		life.beauford.visible = on


func _weather(delta: float) -> void:
	state_t -= delta
	var pp := player.global_position
	match state:
		"calm":
			beau_k = move_toward(beau_k, 0.0, delta * 0.05)
			if state_t <= 0.0:
				set_state("approach")
		"approach":
			beau_k = move_toward(beau_k, 1.0, delta / 30.0)
			_boom_t -= delta
			if _boom_t <= 0.0:
				_boom_t = rng.randf_range(6.0, 11.0)
				sound.play_at("distant_boom", {}, pp + Vector3(30, 10, -40), 4.0, "" if said.has("voice") else "[a sound too low to hear properly; you feel it in your chest]")
				said["voice"] = true
				_shake = 1.2
			if state_t <= 0.0:
				set_state("weather")
		"weather":
			beau_k = move_toward(beau_k, 0.7, delta * 0.05)
			if weather == "mist":
				_hurt_t -= delta
				if _hurt_t <= 0.0:
					_hurt_t = 1.0
					if not _sheltered(pp) and not SessionState.is_qa():
						player.hurt(1.5, "toxic lemon mist")
			if state_t <= 0.0:
				set_state("clear")
		"clear":
			beau_k = move_toward(beau_k, 0.0, delta * 0.08)
			if state_t <= 0.0:
				beauford_show(false)
				set_state("calm")
	var wk := 1.0 if state == "weather" else 0.0
	var wf := clampf(1.0 - state_t / 6.0, 0.0, 1.0) if state == "clear" else 1.0
	wk *= wf
	life.mist.emitting = state == "weather" and weather == "mist"
	life.storm.emitting = state == "weather" and weather == "storm"
	life.fibres.emitting = life.storm.emitting
	life.follow(pp)
	var fogc := Color(0.03, 0.025, 0.02)
	var dens := 0.00012
	if state == "weather":
		if weather == "mist":
			fogc = Color(0.32, 0.33, 0.2)
			dens = 0.022
		else:
			fogc = Color(0.3, 0.26, 0.2)
			dens = 0.05
	environment.fog_light_color = environment.fog_light_color.lerp(fogc, minf(1.0, delta * 0.5))
	environment.fog_density = lerpf(environment.fog_density, dens, minf(1.0, delta * 0.5))
	sun.light_energy = sun_e0 * lerpf(1.0, 0.45, beau_k)
	sky_mat.set_shader_parameter("dim", lerpf(1.0, 0.5, beau_k))
	if life.beauford.visible:
		life.place_beauford(beau_k, pp)
	var siren_on := state == "approach" or (state == "weather" and state_t > 30.0)
	for s in _sirens:
		if is_instance_valid(s):
			(s as AudioStreamPlayer3D).volume_db = move_toward((s as AudioStreamPlayer3D).volume_db, -6.0 if siren_on else -80.0, delta * 30.0)
			(s as AudioStreamPlayer3D).pitch_scale = 1.0 + 0.25 * sin(Time.get_ticks_msec() * 0.0025)


## Under a roof or girder: something solid within 20 m straight up.
func _sheltered(pp: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(pp + Vector3(0, 1.8, 0), pp + Vector3(0, 22.0, 0), 1)
	return not get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func level_process(delta: float) -> void:
	if player == null:
		return
	if not SessionState.is_qa() or state != "calm":
		_weather(delta)
	life.update_mites(delta, player.global_position)
	if _shake > 0.0 and is_instance_valid(player.camera):
		_shake = maxf(0.0, _shake - delta)
		player.camera.h_offset = randf_range(-0.03, 0.03) * _shake
		player.camera.v_offset = randf_range(-0.03, 0.03) * _shake
	elif is_instance_valid(player.camera):
		player.camera.h_offset = 0.0
		player.camera.v_offset = 0.0
	var pp := player.global_position
	if not said.has("gate") and pp.distance_to(works.spots["gate"]) < 22.0 and not SessionState.is_qa():
		said["gate"] = true
		Overlay.subtitle("[a miner in a respirator lifts a hand: \"You lost? Way out's through the gate. Come on.\"]", 4.0)
	for m in gate_miners:
		if is_instance_valid(m) and pp.distance_to(m.position) < 25.0:
			var to: Vector3 = pp - m.position
			m.rotation.y = lerp_angle(m.rotation.y, atan2(to.x, to.z), minf(1.0, delta * 2.0))
	if not said.has("bluehole") and pp.distance_to(bh.spots["pool"]) < 40.0 and not SessionState.is_qa():
		said["bluehole"] = true
		Overlay.subtitle("[the Bluehole. The plastic down the shaft walls is stained blue, and the pool at the bottom stinks of thinner]", 5.0)
	var pool: Vector3 = bh.spots["pool"]
	if pp.y < T.POOL_Y + 0.2 and Vector2(pp.x - pool.x, pp.z - pool.z).length() < 9.5 and not SessionState.is_qa():
		_hurt_t -= delta
		if _hurt_t <= 0.0:
			_hurt_t = 0.5
			player.hurt(6.0, "a caustic pool of lead paint and paint thinner")


# --------------------------------------------------------------- QA

func _shots() -> void:
	var gx: Vector3 = works.spots["gate"]
	add_shot("road_to_plasticworks", START + Vector3(-6.0, 1.75, 1.5), gx + Vector3(20.0, 3.0, -12.0), {"flashlight": false})
	var c1: Vector3 = works.spots["column1"]
	add_shot("mining_column", c1 + Vector3(-13.0, 11.5, 14.0), c1 + Vector3(2.0, 0.5, -2.0), {"flashlight": false})
	var pool: Vector3 = bh.spots["pool"]
	add_shot("bluehole", pool + Vector3(-24.0, 12.4, -10.0), pool + Vector3(2.0, 2.0, 1.0), {"flashlight": false})
	add_shot("beauford_and_the_storm", START + Vector3(0.0, 1.75, 0.0), START + Vector3(500.0, 260.0, -760.0), {"flashlight": false, "prepare": _prep_storm})
	var sh: Vector3 = works.spots["shed"]
	add_shot("processing_shed", sh + Vector3(-18.0, 2.0, -12.0), sh + Vector3(12.0, 2.5, 8.0), {"flashlight": false, "prepare": _prep_calm})
	add_shot("mites", Vector3(92.0, ter.h(92.0, 52.0) + 1.7, 52.0), Vector3(110.0, ter.h(110.0, 72.0) + 0.3, 72.0), {"flashlight": false, "prepare": _prep_calm})


func _prep_storm() -> void:
	beau_k = 0.75
	beauford_show(true)
	state = "weather"
	weather = "storm"
	state_t = 50.0
	life.place_beauford(beau_k, START)
	for i in 4:
		await get_tree().process_frame


func _prep_calm() -> void:
	state = "calm"
	state_t = 999.0
	beau_k = 0.0
	beauford_show(false)
	environment.fog_density = 0.00012
	environment.fog_light_color = Color(0.03, 0.025, 0.02)
	life.storm.emitting = false
	life.fibres.emitting = false
	for i in 2:
		await get_tree().process_frame


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "standard gravity (page: not low gravity)", "ok": is_equal_approx(float(rules["gravity"]), 9.8)})
	out.append({"what": "PlasticWorks main gate exit present", "ok": exits.size() == 1, "detail": exits.size()})
	out.append({"what": "mite groups exist and keep their distance", "ok": life.mites.size() >= 12, "detail": life.mites.size()})
	var g0: Vector3 = works.spots["column1"]
	out.append({"what": "mining column is cut 8 m below the paint", "ok": ter.h(g0.x, g0.z) < -7.0, "detail": ter.h(g0.x, g0.z)})
	out.append({"what": "Bluehole shaft holds the caustic pool", "ok": get_node_or_null("CausticPool") is WaterVolume})
	var s0 := state
	set_state("approach")
	var a_ok: bool = state == "approach" and life.beauford.visible
	set_state("weather")
	var w_ok := weather in ["mist", "storm"]
	var n0: int = life.mites.size()
	weather = "storm"
	set_state("clear")
	var m_ok: bool = life.mites.size() > n0
	beauford_show(false)
	set_state("calm")
	state = s0
	out.append({"what": "Beauford's approach brings a weather", "ok": a_ok and w_ok})
	out.append({"what": "a storm leaves a new mite group behind", "ok": m_ok, "detail": life.mites.size()})
	return out
