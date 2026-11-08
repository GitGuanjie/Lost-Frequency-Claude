extends LevelBase
## Level 998 - "A Path Across Hell, and Towards Any Beyond" (Backrooms Wikidot
## rev 179, accessed 2026-11-04; cite: Greggita Mahayfaio, CC BY-SA 3.0).
## Dossier: docs/canon/levels/L998.md.
## CONTENT NOTE: the page treats suicide as a central theme. Nothing here
## depicts a method; the end is an abstract fade inside the storm.
##
## PLAN (v2.0 rebuild)
## SOURCE: every entrance (a white metal double door like a lift's, in many
##   levels) leads to the same place: the base floor of a concrete office
##   stairwell. Eight flights up is a small, originally bare room where ~38
##   hand-painted pebbles lie in a clumsy pile, an empty doorway, and beyond it a
##   blank, flat plane of cloud: a solid wool-textured floor whose imprinted
##   clouds seem to move with your position and gaze. From outside the room is a
##   square rooftop elevator house with roof skirting and a triangular skylight.
##   Past ~30 km the clouds and sky grey, a cold light breeze starts (~11 C) and
##   figures (Smilers, Dullers, entity-17 infected, Woodlins) drift outward,
##   ignoring you unless you get too close. Past ~80 km a black haze floods
##   ground and sky, gales to 29 m/s and harsh rain; 15 km further the edge of a
##   neverending black storm where cameras break and become waterlogged within
##   minutes. Beyond that the level is an enigma; where its edges lead was never
##   known.
## SPACE: stairwell (8 x 1.6 m flights, landings, rails, bulkhead lamps, the
##   white double door behind the arrival) under the plane; the room and its
##   skylight above; one flat cloud plane 3 km across at y 12.8 with a storm wall
##   ring. ADAPTATION: distance is compressed, 1 m walked = 200 m of the level
##   (QA mode: 1 km) so the grey zone starts 150 m out, the black at 400 m and
##   the storm at 475 m; zone changes, wind, rain and sky follow that odometer.
## SIGNATURE MECHANIC (stateful): the outward walk. Zones change with distance
##   from the epicentre (white -> grey -> black -> storm); wind pushes and rain
##   lashes in the black; drifters walk outward and turn on you only if you
##   crowd them; in the storm your light fails and the camera fills with water
##   and goes dark; staying in it ends the walk with no destination (the
##   L998>EXT#1 edge, "never known"). Turning back is always possible.
## ABSENT: a destination, landmarks on the plane, hostile packs, gore.

const B := preload("res://levels/L998/L998_build.gd")
const EXIT_ID := "L998>EXT#1"
const GREY_KM := 30.0
const BLACK_KM := 80.0
const STORM_KM := 95.0
const START := Vector3(0.0, 0.05, -4.0)

var b
var m_to_km := 0.2
var km := 0.0
var zone := "stair"
var grey := 0.0
var black := 0.0
var storm := 0.0
var storm_t := 0.0
var ending_done := false
var told := {}
var figures: Array = []          # {node, ang, r, speed, legs, stop}
var pebble_count := 0
var rain_l: GPUParticles3D
var rain_h: GPUParticles3D
var wind_bed: AudioStreamPlayer
var gale_bed: AudioStreamPlayer
var rain_bed: AudioStreamPlayer
var tone_bed: AudioStreamPlayer
var thunder_t := 8.0
var gust := Vector3.ZERO
var gust_t := 0.0
var _flash_policy := "allowed"
var triggers: Array = []


func build() -> void:
	if SessionState.is_qa():
		m_to_km = 1.0
	rules["view_distance"] = 2400.0
	rules["reverb_room"] = 0.55
	rules["reverb_wet"] = 0.2
	rules["flashlight"] = "allowed"
	var kg := kit("Stairwell")
	var kl := kit("Lamps")
	kl.shadows = false
	b = B.new(self, kg, kl)
	b.materials(m_to_km, STORM_KM)
	_env()
	b.stairwell()
	b.room()
	var col := kit("Plane")
	var world := Node3D.new()
	world.name = "Plane"
	add_child(world)
	b.plane(world, col, 1500.0)
	b.storm_wall(world, STORM_KM / m_to_km)
	kg.commit()
	kl.commit()
	col.commit()
	var props := Node3D.new()
	props.name = "Props"
	add_child(props)
	pebble_count = b.pebbles(props).size()
	_dress(props)
	lights.setup(5, 1)
	for lp in b.lamps:
		lights.add_anchor(lp, Color(1.0, 0.93, 0.8), 1.3, 5.0)
	rain_l = b.rain(self, false)
	rain_h = b.rain(self, true)
	_figures()
	_sounds()
	for tag in ["start", "from_L001", "from_L002", "from_L011", "from_L737"]:
		add_arrival(tag, START, 180.0)
	_exits()
	add_interactable(b.pebble_spot + Vector3(0, 0.2, 0), Vector3(1.1, 0.5, 1.1), "Look at the painted stones", _stones)
	add_landmark("Base of the concrete stairwell (white double door)", START)
	add_landmark("The small room at the top (pebbles, skylight)", Vector3(2.5, B.TOP_Y, 0))
	add_landmark("Grey territory (~30 km, compressed)", Vector3(GREY_KM / m_to_km, B.TOP_Y, 0))
	add_landmark("Black haze (~80 km, compressed)", Vector3(BLACK_KM / m_to_km, B.TOP_Y, 0))
	add_landmark("Edge of the neverending storm (~95 km, compressed)", Vector3(STORM_KM / m_to_km, B.TOP_Y, 0))
	_shots()


func _env() -> void:
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = b.sky_mat
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.75, 0.8, 0.88)
	environment.ambient_light_energy = 0.8
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.78, 0.84, 0.92)
	environment.fog_density = 0.0015
	environment.fog_sky_affect = 0.25
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-52.0, -140.0, 0)
	sun.light_color = Color(1.0, 0.97, 0.9)
	sun.light_energy = 1.2
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	add_child(sun)


func _dress(props: Node3D) -> void:
	Props.place(self, props, "ph/korean_fire_extinguisher_01", Vector3(-1.4, 0.0, -2.9), 90.0, 0.0, true)
	Props.place(self, props, "ph/fire_alarm", Vector3(1.57, 1.4, -3.6), -90.0)
	Props.place(self, props, "ph/fire_alarm", Vector3(-1.57, 7.8, -2.4), 90.0)
	Props.place(self, props, "ph/utility_box_01", Vector3(1.32, 0.0, -4.3), -90.0, 0.0, true)


func _exits() -> void:
	var rc := (STORM_KM + 4.0) / m_to_km
	var depth := 8.0 / m_to_km
	var n := 12
	for i in n:
		var a := TAU * i / n
		var c := Vector3(cos(a) * rc, B.TOP_Y + 2.0, sin(a) * rc)
		var w := TAU * rc / n * 1.06
		var t := add_exit(EXIT_ID, "walk_in", c, Vector3(depth, 4.0, w), "")
		if t:
			t.rotation.y = -a
			t.condition = func() -> bool: return ending_done
			triggers.append(t)


func _figures() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.09, 0.09, 0.1)
	mat.roughness = 1.0
	var r := RandomNumberGenerator.new()
	r.seed = 99810
	var defs: Array = []
	for i in 6:
		defs.append([r.randf_range(-0.35, 0.35) if i < 3 else r.randf() * TAU, r.randf_range(33.0, 72.0), r.randf_range(1.6, 1.85)])
	for i in 8:
		defs.append([r.randf_range(-0.4, 0.4) if i < 4 else r.randf() * TAU, r.randf_range(82.0, 93.0), r.randf_range(1.5, 2.1)])
	for d in defs:
		var n: Node3D = B.figure(mat, d[2])
		add_child(n)
		var f := {"node": n, "ang": d[0], "r": float(d[1]) / m_to_km, "speed": r.randf_range(0.45, 0.7), "stop": 0.0, "ph": r.randf() * TAU}
		figures.append(f)
		_place_fig(f, 0.0)
	var sm: Node3D = B.smiler()
	add_child(sm)
	var f2 := {"node": sm, "ang": 0.12, "r": 89.0 / m_to_km, "speed": 0.35, "stop": 0.0, "ph": 0.0, "smiler": true}
	figures.append(f2)
	_place_fig(f2, 0.0)


func _place_fig(f: Dictionary, t: float) -> void:
	var n: Node3D = f["node"]
	var a: float = f["ang"]
	n.position = Vector3(cos(a) * float(f["r"]), B.TOP_Y, sin(a) * float(f["r"]))
	if not f.has("smiler"):
		n.rotation.y = -a - PI * 0.5 if f["stop"] <= 0.0 else n.rotation.y
		for c in n.get_children():
			if c.name.begins_with("Leg"):
				(c as Node3D).rotation.x = 0.35 * sin(t * 4.0 + float(f["ph"]) + (PI if c.name == "Leg1" else 0.0)) * (0.0 if f["stop"] > 0.0 else 1.0)


func _sounds() -> void:
	tone_bed = sound.bed("room_tone", {"cutoff": 260.0, "rumble": 0.2}, -30.0)
	wind_bed = sound.bed("wind", {"seconds": 9.0}, -60.0)
	gale_bed = sound.bed("wind", {"seconds": 6.0}, -80.0)
	rain_bed = sound.bed("rain", {"seconds": 5.0}, -80.0)
	for i in range(0, b.lamps.size(), 2):
		sound.emitter("fluorescent_hum", b.lamps[i], {}, -30.0, 5.0)


func _shots() -> void:
	add_shot("stair_base", Vector3(1.0, 1.55, -4.3), Vector3(-0.8, 3.4, 1.8), {"flashlight": false})
	add_shot("top_room", Vector3(2.2, B.TOP_Y + 1.45, 0.9), Vector3(3.8, B.TOP_Y + 0.35, -1.4), {"flashlight": false})
	add_shot("cloud_plane", Vector3(16.0, B.TOP_Y + 1.65, 9.0), Vector3(1.0, B.TOP_Y + 1.6, -1.0), {"flashlight": false})
	var gx := 48.0 / m_to_km
	add_shot("grey_drifters", Vector3(gx, B.TOP_Y + 1.65, 1.5), Vector3(gx + 40.0, B.TOP_Y + 1.0, -2.0), {"flashlight": false, "prepare": _prep_grey})
	var sx := 89.0 / m_to_km
	add_shot("black_storm", Vector3(sx, B.TOP_Y + 1.65, -2.0), Vector3(sx + 40.0, B.TOP_Y + 6.0, 4.0), {"flashlight": false})


func _prep_grey() -> void:
	# put one drifter a little ahead of the camera, walking away
	var f: Dictionary = figures[0]
	f["ang"] = 0.03
	f["r"] = 48.0 / m_to_km + 9.0
	_place_fig(f, 0.0)
	await get_tree().process_frame


# ---------------------------------------------------------------- runtime

func on_player_ready() -> void:
	_flash_policy = player.flashlight_policy
	if SessionState.is_qa():
		return
	if not SaveService.flag(stable_id, "content_note_seen", false):
		SaveService.set_flag(stable_id, "content_note_seen", true)
		Overlay.show_note("Content note: Level 998", "The source page for this level treats suicide as a central theme: people walk outward across it toward an unknown end, by their own choice. Nothing in this level depicts a method or harm; the walk ends in an abstract storm.\n\nYou can turn back at any time.\n\n(Level 998, Backrooms Wiki, Greggita Mahayfaio, CC BY-SA 3.0.)")
	Overlay.subtitle("[the white doors close behind you. A concrete stairwell goes up.]", 4.0)


func _stones() -> void:
	Overlay.subtitle("[%d small stones, hand-painted: a sun, a name, a heart, a date, a spiral. Someone counted those who came this way.]" % pebble_count, 6.0)
	SaveService.set_flag(stable_id, "saw_stones", true)


func _say(key: String, text: String, secs := 5.0) -> void:
	if told.has(key):
		return
	told[key] = true
	Overlay.subtitle(text, secs)


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var p := player.global_position
	var outside := p.y > B.TOP_Y - 0.4 and not (p.x > -B.SX - 0.3 and p.x < B.RX1 + 0.3 and absf(p.z) < B.SZ + 0.3)
	km = Vector2(p.x, p.z).length() * m_to_km if outside else 0.0
	var tg := smoothstep(GREY_KM - 3.0, GREY_KM + 4.0, km)
	var tb := smoothstep(BLACK_KM - 3.0, BLACK_KM + 5.0, km)
	var ts := smoothstep(STORM_KM - 1.0, STORM_KM + 2.0, km)
	var k := clampf(delta * 1.5, 0.0, 1.0)
	grey = lerpf(grey, tg, k)
	black = lerpf(black, tb, k)
	storm = lerpf(storm, ts, k)
	_apply_look(outside)
	_tick_figures(delta, p)
	if rain_l:
		rain_l.global_position = p + Vector3(0, 10.0, 0)
		rain_h.global_position = p + Vector3(0, 10.0, 0)
		rain_l.emitting = outside and black > 0.3 and storm < 0.3
		rain_h.emitting = outside and storm > 0.2
	# captions on the way out
	if outside and km > 0.6:
		_say("plane", "[a flat plain of cloud. It looks deep enough to fall into, but underfoot it is solid, and soft as wool.]")
	if km > GREY_KM:
		_say("grey", "[the clouds underfoot are greying, and the sky with them. A cold, light breeze; maybe eleven degrees.]")
	if km > BLACK_KM:
		_say("black", "[a black haze floods the clouds below and above. The wind is a gale now.]")
	if km > STORM_KM - 2.0:
		_say("edge", "[ahead, the edge of the storm: black cloud, thunder, almost no visibility]")
	# the storm: gear fails, the camera drowns, the walk ends
	if storm > 0.5 and outside:
		storm_t += delta
		player.flashlight_policy = "fails"
		if player.flashlight.visible and storm_t > 0.6:
			player.flashlight.visible = false
		var need := 1.6 if SessionState.is_qa() else 8.0
		Overlay.set_screen_effect("blackout", clampf(storm_t / need, 0.0, 1.0) * 0.95)
		if fmod(storm_t, 1.3) < delta:
			Overlay.glitch(0.4 + 0.4 * clampf(storm_t / need, 0.0, 1.0))
		_say("drown", "[rain hammers the lens. The picture blurs, fills with water, and starts to go dark.]", 5.0)
		if storm_t >= need and not ending_done:
			ending_done = true
			_say("end", "[nothing is visible any more. Nobody has ever said where this leads.]", 6.0)
	elif storm_t > 0.0:
		storm_t = maxf(0.0, storm_t - delta * 2.0)
		Overlay.set_screen_effect("blackout", clampf(storm_t / 8.0, 0.0, 1.0) * 0.95)
		if storm_t <= 0.0:
			player.flashlight_policy = _flash_policy
			ending_done = false
	if SessionState.is_qa():
		return
	# gales and harsh rain push you around in the black territory
	if outside and black > 0.2:
		gust_t -= delta
		if gust_t <= 0.0:
			gust_t = rng.randf_range(1.5, 4.0)
			var ga := rng.randf() * TAU
			gust = Vector3(cos(ga), 0, sin(ga)) * rng.randf_range(0.4, 1.6) * (black + storm)
		player.global_position += gust * delta
	thunder_t -= delta
	if outside and black > 0.5 and thunder_t <= 0.0:
		thunder_t = rng.randf_range(6.0, 16.0) * (1.2 - storm)
		sound.play_at("thunder", {"seconds": 4.0, "low": 1.0}, p + Vector3(rng.randf_range(-60, 60), 40, rng.randf_range(-60, 60)), -8.0, "[thunder]")


func _apply_look(outside: bool) -> void:
	var sm: ShaderMaterial = b.sky_mat
	sm.set_shader_parameter("grey", grey)
	sm.set_shader_parameter("black", black)
	sm.set_shader_parameter("storm", storm)
	(b.wall_mat as ShaderMaterial).set_shader_parameter("near", clampf((km - 60.0) / 30.0, 0.0, 1.0))
	var fog_white := Color(0.78, 0.84, 0.92)
	var fog_grey := Color(0.36, 0.37, 0.39)
	var fog_black := Color(0.018, 0.018, 0.022)
	environment.fog_light_color = fog_white.lerp(fog_grey, grey).lerp(fog_black, black)
	environment.fog_density = lerpf(lerpf(lerpf(0.0012, 0.004, grey), 0.012, black), 0.08, storm)
	environment.fog_sky_affect = lerpf(0.05, 0.6, maxf(grey, black))
	sun.light_energy = lerpf(lerpf(1.25, 0.45, grey), 0.03, black)
	if outside:
		environment.ambient_light_color = Color(0.75, 0.8, 0.88).lerp(Color(0.5, 0.5, 0.52), grey).lerp(Color(0.3, 0.3, 0.34), black)
		environment.ambient_light_energy = lerpf(lerpf(0.85, 0.55, grey), 0.25, black)
	else:
		environment.ambient_light_color = Color(0.55, 0.55, 0.52)
		environment.ambient_light_energy = 0.22
	if wind_bed:
		wind_bed.volume_db = lerpf(-60.0, -24.0, maxf(grey, 0.0)) if outside else -60.0
		gale_bed.volume_db = lerpf(-80.0, -10.0, black) if outside else -80.0
		rain_bed.volume_db = lerpf(-80.0, -8.0, maxf(black * 0.7, storm)) if outside else -80.0
		tone_bed.volume_db = -60.0 if outside else -30.0


func _tick_figures(delta: float, p: Vector3) -> void:
	var t := Time.get_ticks_msec() * 0.001
	for f in figures:
		var n: Node3D = f["node"]
		if not is_instance_valid(n):
			continue
		if f["stop"] > 0.0:
			f["stop"] -= delta
		else:
			f["r"] = float(f["r"]) + float(f["speed"]) * delta
		# past the storm edge the figure is gone into it
		n.visible = float(f["r"]) * m_to_km < STORM_KM + 1.0
		_place_fig(f, t)
		if f.has("smiler"):
			n.look_at(Vector3(p.x, n.global_position.y, p.z) + Vector3(0, 0.001, 0), Vector3.UP)
			n.rotate_y(PI)
			continue
		if SessionState.is_qa():
			continue
		var d := Vector2(n.position.x - p.x, n.position.z - p.z).length()
		if d < 2.4 and f["stop"] <= 0.0:
			f["stop"] = 3.5
			n.look_at(Vector3(p.x, n.position.y, p.z), Vector3.UP)
			n.rotate_y(PI)
			Overlay.subtitle("[it stops, and turns to face you. Better to give it room.]", 3.5)
			sound.play_at("knock", {"hits": 1}, n.position + Vector3(0, 1, 0), -10.0, "")
			var away := (p - n.position)
			away.y = 0.0
			player.velocity += away.normalized() * 4.0
		elif d < 14.0:
			_say("drifter", "[a figure walks past, outward, away from the stair. It does not seem to know you are here.]", 5.0)


# ---------------------------------------------------------------- QA

func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	var space := get_world_3d().direct_space_state
	out.append({"what": "one edge only (L998>EXT#1), a ring of 12 storm triggers", "ok": triggers.size() == 12 and exits.all(func(t): return not is_instance_valid(t) or t.edge_id == EXIT_ID)})
	var top := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(3.0, B.TOP_Y + 1.0, 0.0), Vector3(3.0, B.TOP_Y - 1.0, 0.0), 1))
	var base := space.intersect_ray(PhysicsRayQueryParameters3D.create(START + Vector3(0, 1.0, 0), START + Vector3(0, -1.0, 0), 1))
	out.append({"what": "stair base and top room are two walkable heights 12.8 m apart", "ok": not top.is_empty() and not base.is_empty() and absf(float(top["position"].y) - float(base["position"].y) - B.TOP_Y) < 0.1})
	var plane := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(60.0, B.TOP_Y + 1.0, 40.0), Vector3(60.0, B.TOP_Y - 1.0, 40.0), 1))
	out.append({"what": "flat walkable cloud plane outside", "ok": not plane.is_empty() and absf(float(plane["position"].y) - B.TOP_Y) < 0.05})
	out.append({"what": "about 38 painted pebbles in the room", "ok": pebble_count == 38})
	# back on the stair, the storm's hold lets go: the exit is gated again
	player.global_position = START
	player.velocity = Vector3.ZERO
	for i in 400:
		if storm_t <= 0.0:
			break
		await get_tree().process_frame
	out.append({"what": "storm exit is gated (only inside the storm)", "ok": not ending_done and storm_t <= 0.0})
	var f: Dictionary = figures[1]
	var r0 := float(f["r"])
	for i in 20:
		await get_tree().process_frame
	out.append({"what": "drifters walk outward from the epicentre", "ok": float(f["r"]) > r0, "detail": [r0, f["r"]]})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
