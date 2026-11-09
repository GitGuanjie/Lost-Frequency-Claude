extends LevelBase
## Level 201 "A E S T H E T I C" (Backrooms Wikidot rev 80, accessed 2026-11-04; mike14264,
## CC BY-SA 3.0). Dossier: docs/canon/levels/L201.md.
##
## PLAN (read -> design):
## - SOURCE: a giant desert of yellow and violet sand with the Web Sea at its warm (north) edge,
##   the Neon City at its cold (south) edge and barren, unclimbable mountains east and west; an
##   orange-pink sun six times our sun's size, fragmented in horizontal lines, stuck setting over
##   the sea; a white line grid across a sky going from bright orange to deep purple at the city.
##   -> one long north-south axis (ADAPTATION: ~600 m): sky shader with the sliced sun and grid,
##   a heightfield desert with mountain walls, the coast, the sea and the city.
## - SOURCE: the Cool Desert: half-buried Greco-Roman temples of smooth purple marble with
##   statues, busts and murals, floating neon rings round the columns, dial-up desktop terminals
##   sitting on courtyard floors; potted plants; palms only at the oases below sea level;
##   floating geometric shapes; M.E.G. Base Zeta abandoned near a temple with supplies.
## - SOURCE: Sunset Coast with palms and soft sand; Static Ghosts staring at the sun or lying on
##   the sand; the Web Sea: net-like vector lines, blue fading to purple, almost no waves, water
##   that cannot be swum but can be walked and breathed in; the Digital Trenches: dark, full of
##   early-Internet windows with hyperlinks; safe links 1, 3, 4, 5, 7, 25, 31, 87, broken links
##   0, 2, 6, 8, 17, 58 lead to the Null; Binary Fish schools.
##   -> walk down the beach under the surface (no swimming, no WaterVolume) to a trench (ADAPTATION:
##   11 m deep, not 500 m) with fourteen floating windows: eight safe exits, six to the Null.
## - SOURCE: Neon City: constant night, towers, hotels, malls with neon, marble tiles, glass roofs,
##   neon rings on columns, closed stores, open arcades on free play, a ball pit to avoid, vending
##   machines, TVs that can be no-clipped into; Light Traffic stopped only by red lights; random
##   rain; streets teeming with Static Ghosts.
## - SOURCE signature: the background music (lounge/elevator/smooth jazz, slowed and remixed,
##   different for every wanderer) and the Tune-Out: stop and listen and you calm, static covers
##   you, and you become a Static Ghost; an outside noise like an alarm clock prevents it.
##   -> synthesized lounge loop (seeded per wanderer), a Tune-Out meter that climbs while you
##   stand still, the alarm clock at Base Zeta that rings it back down.
## - ABSENT: Partygoers, swimming, working compasses, a moving sun, hostile Static Ghosts.

const Land := preload("res://levels/L201/L201_land.gd")
const FX := preload("res://levels/L201/L201_fx.gd")
const Desert := preload("res://levels/L201/L201_desert.gd")
const City := preload("res://levels/L201/L201_city.gd")
const Music := preload("res://levels/L201/L201_music.gd")

var land: Land
var land_mat: Material
var D: Desert
var C: City
var sea_mat: ShaderMaterial
var music: AudioStreamPlayer
var _surf: AudioStreamPlayer3D
var tune := 0.0
var _still := 0.0
var has_clock := false
var _clock_t := 0.0
var _under := false
var _city_exits := false
var _said := {}
var _fish_t := 0.0
var rain_mi: MultiMeshInstance3D
var rain_k := 0.0
var _rain_t := 90.0
var _rain_on := false
var _pit_t := 0.0
var _fog_air := Color(0.55, 0.3, 0.5)
var sun_rot := Vector3.ZERO


func build() -> void:
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 2600.0
	rules["kill_y"] = -60.0
	rules["reverb_room"] = 0.1
	rules["reverb_wet"] = 0.04
	outdoor_env(Color(0.3, 0.1, 0.4), Color(1.0, 0.45, 0.35), Color(0.1, 0.03, 0.14), Vector2(5.0, 180.0),
		Color(1.0, 0.55, 0.55), 1.1, _fog_air, 0.0012)
	land = Land.new()
	var sky := land.make_mat(Land.SKY)
	environment.sky.sky_material = sky
	environment.ambient_light_energy = 0.7
	environment.fog_sky_affect = 0.15
	environment.fog_aerial_perspective = 0.3
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.55
	environment.glow_bloom = 0.08
	sun.directional_shadow_max_distance = 120.0
	sun_rot = sun.rotation
	FX.materials()
	land.build_meshes(self)
	land_mat = (get_node("Sand") as MeshInstance3D).material_override
	land.build_collision(self)
	sea_mat = land.build_water(self)
	D = Desert.new(self, land, rng)
	D.build()
	C = City.new(self, rng)
	C.build()
	lights.setup(10, 0)
	lights.max_distance = 50.0
	for lp in D.lamp_pts + C.lamp_pts:
		lights.add_anchor(lp[0], lp[1], lp[2], lp[3], 0.0)
	rain_mi = FX.rain_node()
	add_child(rain_mi)
	_exits()
	_interactions()
	_sounds()
	var coast := Vector3(2.0, land.h(2.0, -74.0) + 0.1, -74.0)
	add_arrival("start", coast, 0.0)
	add_arrival("from_L001", coast + Vector3(-6.0, land.h(-4.0, -74.0) - coast.y + 0.1, 0.0), 0.0)
	add_arrival("from_L011", coast + Vector3(8.0, land.h(10.0, -74.0) - coast.y + 0.1, 0.0), 0.0)
	add_arrival("from_L025", Vector3(36.0, City.WALK + 0.1, 124.5), 180.0)
	add_landmark("Sunset Coast", Vector3(0, 0, -78))
	add_landmark("Digital Trench", Vector3(0, Land.TRENCH_FLOOR, -137))
	add_landmark("Purple marble temple", Land.TEMPLE)
	add_landmark("M.E.G. Base Zeta", D.clock_pos)
	add_landmark("Oasis", Land.OASIS)
	add_landmark("Neon City mall arcade", C.arcade_pos)
	_shots()


func _exits() -> void:
	# safe windows first (Level 1 leads: it is the walker bot's target), broken ones after
	var order: Array = D.windows.duplicate()
	order.sort_custom(func(a, b): return (0 if a["sid"] == "L001" else (1 if a["safe"] else 2)) < (0 if b["sid"] == "L001" else (1 if b["safe"] else 2)))
	for w in order:
		var p: Vector3 = w["pos"]
		var lvl_no := str(int((w["sid"] as String).substr(1)))
		var prompt := "Touch the hyperlink: Level %s" % lvl_no if w["safe"] else "Touch the hyperlink (Level %s)" % lvl_no
		var t := add_exit(w["edge"], "interact", p + Vector3(0, 1.5, 0), Vector3(2.8, 3.0, 2.2), prompt)
		if t:
			t.fired.connect(func(_e: String) -> void: Overlay.glitch(1.0))
			w["trigger"] = t


## The TVs and arcade cabinets are no-clip exits inside the city; they exist once you are there.
func _make_city_exits() -> void:
	_city_exits = true
	var tv := add_exit("L201>EXT#1", "noclip", C.tv_pos + Vector3(0, -0.2, -0.1), Vector3(9.0, 2.2, 1.6), "Push into a television showing another level")
	if tv:
		tv.fired.connect(func(_e: String) -> void: Overlay.glitch(1.0))
	var cab := add_exit("L201>L040#11", "noclip", C.cabinet_pos + Vector3(0, 0, 0.0), Vector3(1.2, 2.0, 1.2), "Push into the arcade cabinet")
	if cab:
		cab.condition = func() -> bool: return (int(Time.get_ticks_msec() / 4000) % 2) == 0
	var cab25 := add_exit("L201>L025#8", "noclip", C.cabinet_pos, Vector3(1.2, 2.0, 1.2), "")
	if cab25:
		cab25.condition = func() -> bool: return (int(Time.get_ticks_msec() / 4000) % 2) == 1


func _interactions() -> void:
	for n in D.notes:
		add_note(n[0], n[1], n[2], n[3], Vector3(0.8, 0.8, 0.8), false)
	add_interactable(D.terminal_pos, Vector3(0.8, 0.8, 0.8), "Use the terminal (dial-up)", func(_p: Player) -> void:
		sound.play_at("static", {"seconds": 2.0}, D.terminal_pos, -6.0, "[a long dial-up screech, then a page crawls onto the screen]")
		Overlay.show_note("Terminal - early Internet page", "THE WEB SEA: the windows in the Digital Trenches carry links to other levels. Confirmed safe: 1, 3, 4, 5, 7, 25, 31, 87. Broken - into the Null: 0, 2, 6, 8, 17, 58. (No mouse works with these machines.)"))
	add_interactable(D.clock_pos, Vector3(0.5, 0.5, 0.5), "Take the team's alarm clock", func(_p: Player) -> void: take_clock())
	add_interactable(C.cabinet_pos + Vector3(0, 0.4, -0.5), Vector3(0.9, 0.8, 0.5), "Play (free play)", func(_p: Player) -> void:
		sound.play_at("chiptune", {"bpm": 140.0, "root": 330.0}, C.cabinet_pos, -8.0, "[the cabinet plays a jingle: FREE PLAY - a token rattles into the tray]"))


func take_clock() -> void:
	if has_clock:
		return
	has_clock = true
	_clock_t = 40.0
	if D.clock_node and is_instance_valid(D.clock_node):
		D.clock_node.visible = false
	Overlay.subtitle("[you take the team's clock. Its alarm bell still works - noise to keep you here]", 4.0)


# --------------------------------------------------------------- the music and the Tune-Out

func _sounds() -> void:
	music = AudioStreamPlayer.new()
	music.name = "BackgroundMusic"
	music.stream = Music.make(level_seed)
	music.bus = "Music" if AudioServer.get_bus_index("Music") >= 0 else "Master"
	music.volume_db = -12.0
	music.autoplay = not SessionState.is_qa()
	add_child(music)
	_surf = sound.emitter("water_bed", Vector3(0, 0.5, -90.0), {"bright": 0.2, "seconds": 7.0}, -14.0, 50.0)
	sound.bed("wind", {"seconds": 9.0}, -32.0)
	sound.emitter("chiptune", C.arcade_pos + Vector3(0, 1.5, 0), {"bpm": 128.0, "root": 262.0}, -18.0, 16.0)
	sound.emitter("fluorescent_hum", Vector3(0, 6.0, 170.0), {"base": 90.0, "seconds": 3.0}, -26.0, 50.0)
	sound.emitter("whisper", Vector3(0, -8.0, -137.0), {"seconds": 3.0}, -28.0, 25.0)
	sound.oneshot("static", {"seconds": 1.5}, 25.0, 60.0, 14.0, "[a faint hiss of static drifts past]", -26.0)


func _tune_update(delta: float) -> void:
	var moving := player.velocity.length() > 0.4
	_still = 0.0 if moving else _still + delta
	if _still > 3.0:
		tune = minf(1.0, tune + delta / 50.0)
	else:
		tune = maxf(0.0, tune - delta / 8.0)
	if has_clock:
		_clock_t -= delta
		if _clock_t <= 0.0:
			_clock_t = 40.0
			sound.play_at("ui", {"kind": "click"}, player.global_position, 0.0, "[the alarm clock rattles - the music drops back into the background]")
			tune = 0.0
	if music:
		music.volume_db = lerpf(-12.0, -3.0, tune)
	Overlay.set_screen_effect("grain", 0.03 + tune * 0.45)
	Overlay.set_screen_effect("desaturate", tune * 0.7)
	if tune > 0.4 and not _said.has("tune"):
		_said["tune"] = true
		Overlay.subtitle("[the music is so familiar. So calm. Static prickles over your hands... move]", 5.0)
	elif tune < 0.1:
		_said.erase("tune")
	if tune >= 1.0 and not player.dead:
		player.hurt(1000.0, "you tuned out and became a Static Ghost")


# --------------------------------------------------------------- frame

func on_player_ready() -> void:
	if SessionState.is_qa():
		return
	Overlay.subtitle("[a huge sliced sun sinks over a still blue sea that never finishes setting. Music, from nowhere]", 5.0)


func level_process(delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for r in D.rings:
		var n: Node3D = r[0]
		n.position.y = float(r[1]) + sin(now * 0.8 + float(r[2])) * 0.25
		n.rotation.y = now * 0.4 + float(r[2])
		n.rotation.x = sin(now * 0.5 + float(r[2])) * 0.15
	for s in D.shapes:
		var n: Node3D = s[0]
		n.rotate(s[1], delta * float(s[2]))
		n.position.y = float(s[3]) + sin(now * 0.3 + float(s[2]) * 10.0) * 0.8
	for w in D.windows:
		var n: Node3D = w["node"]
		n.position.y = float(w["base_y"]) + sin(now * 0.7 + n.position.x) * 0.08
	sea_mat.set_shader_parameter("shift", 0.5 + 0.5 * sin(now * 0.05))
	C.update_traffic(delta)
	for g in C.ghosts:
		if is_instance_valid(g) and g.get_child_count() > 2:
			(g.get_child(2) as Node3D).rotation.x = sin(now * 3.0 + g.position.x) * 0.3 if (g.get_child(2) as Node3D).rotation.z > 2.0 else 0.0
	if player == null or not is_instance_valid(player):
		return
	var p := player.global_position
	var eye := p + Vector3(0, 1.6, 0)
	_water(eye)
	_city_mix(p)
	if not _city_exits and p.z > Land.CITY_Z:
		_make_city_exits()
	if SessionState.is_qa():
		return
	_tune_update(delta)
	_city_rain(delta, p)
	if C.traffic_hits(p) and not player.dead:
		player.hurt(1000.0, "run over by the Light Traffic")
	if C.ball_pit.has_point(Vector2(p.x, p.z)) and p.y < City.WALK + 1.2:
		_pit_t += delta
		if _pit_t > 0.6:
			_pit_t = 0.0
			player.velocity = Vector3(-4.0, 3.0, 0.0)
			Overlay.subtitle("[something under the balls moves against your leg. Get out. Avoid it at all costs]", 4.0)
	_fish(delta, p)


func _water(eye: Vector3) -> void:
	var od := Vector2(eye.x - Land.OASIS.x, eye.z - Land.OASIS.z).length()
	var under := (eye.y < -0.05 and eye.z < Land.SHORE_Z + 6.0) or (od < 14.0 and eye.y < -1.25)
	if under == _under:
		return
	_under = under
	if under:
		environment.fog_light_color = Color(0.06, 0.12, 0.42)
		environment.fog_density = 0.045
		environment.fog_sky_affect = 1.0
		Overlay.set_underwater(true)
		if not _said.has("water") and not SessionState.is_qa():
			_said["water"] = true
			Overlay.subtitle("[the water is barely there - wet, yet you breathe it. You cannot swim, so you walk]", 5.0)
	else:
		environment.fog_light_color = _fog_air
		environment.fog_density = 0.0012
		environment.fog_sky_affect = 0.15
		Overlay.set_underwater(false)


## The city is always night: the sunset light fades as you walk south into it.
func _city_mix(p: Vector3) -> void:
	if _under:
		return
	var k := smoothstep(Land.CITY_Z - 20.0, Land.CITY_Z + 15.0, p.z)
	sun.light_energy = lerpf(1.1, 0.12, k)
	environment.ambient_light_energy = lerpf(0.7, 0.25, k)
	environment.fog_light_color = _fog_air.lerp(Color(0.12, 0.05, 0.22), k)
	environment.fog_density = lerpf(0.0012, 0.004, k)


func _city_rain(delta: float, p: Vector3) -> void:
	_rain_t -= delta
	if _rain_t <= 0.0:
		_rain_on = not _rain_on
		_rain_t = rng.randf_range(60.0, 150.0) if _rain_on else rng.randf_range(120.0, 300.0)
	var want := 1.0 if (_rain_on and p.z > Land.CITY_Z) else 0.0
	rain_k = move_toward(rain_k, want, delta / 6.0)
	rain_mi.visible = rain_k > 0.01
	(rain_mi.material_override as ShaderMaterial).set_shader_parameter("amount", rain_k)
	if want > 0.5 and not _said.has("rain"):
		_said["rain"] = true
		Overlay.subtitle("[rain out of a clear night sky, warm, lit pink by the signs]", 3.5)


func _fish(delta: float, p: Vector3) -> void:
	if not _under:
		_fish_t = 0.0
		return
	var near := false
	for s in D.schools:
		if (s[1] as Vector3).distance_to(p + Vector3(0, 1.0, 0)) < 4.0:
			near = true
	_fish_t = _fish_t + delta if near else maxf(0.0, _fish_t - delta)
	if _fish_t > 7.0:
		_fish_t = 0.0
		player.hurt(8.0, "bitten by Binary Fish")
		Overlay.glitch(0.5)
		Overlay.subtitle("[Binary Fish nip at you; where they bite, your skin flickers into strings of digits]", 4.0)


# --------------------------------------------------------------- QA

func _shots() -> void:
	var cy := land.h(0.0, -66.0)
	add_shot("sunset_coast", Vector3(-6.0, cy + 1.62, -66.0), Vector3(4.0, 2.0, -300.0), {"flashlight": false})
	var t: Vector3 = Land.TEMPLE
	add_shot("temple", t + Vector3(-15.0, 3.0, -21.0), t + Vector3(0.0, 3.0, 0.0), {"flashlight": false})
	add_shot("digital_trench", Vector3(-4.0, Land.TRENCH_FLOOR + 2.0, -122.0), Vector3(2.0, Land.TRENCH_FLOOR + 1.6, -150.0), {"flashlight": false})
	add_shot("neon_city", Vector3(-2.0, City.WALK + 1.8, 108.0), Vector3(1.0, 14.0, 200.0), {"flashlight": false})
	add_shot("mall_arcade", Vector3(33.0, City.WALK + 2.2, 121.5), Vector3(40.0, City.WALK + 0.8, 140.0), {"flashlight": false})
	add_shot("oasis", Land.OASIS + Vector3(16.0, 5.0, -14.0), Land.OASIS + Vector3(0.0, 1.0, 0.0), {"flashlight": false})


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	var safe := 0
	var broken := 0
	for w in D.windows:
		if w["safe"]:
			safe += 1
		else:
			broken += 1
	out.append({"what": "Trench windows: eight safe links, six broken (to the Null)", "ok": safe == 8 and broken == 6, "detail": [safe, broken]})
	out.append({"what": "every window is a physical exit", "ok": exits.size() >= 14, "detail": exits.size()})
	out.append({"what": "no swimming: the sea is walkable, not a WaterVolume", "ok": get_tree().get_nodes_in_group("water").is_empty() and land.h(0.0, -137.0) < -7.0})
	var rot0 := sun.rotation
	level_process(0.5)
	out.append({"what": "the sun is stuck in place over the sea", "ok": sun.rotation.is_equal_approx(rot0) and sun_rot.is_equal_approx(rot0)})
	if player and is_instance_valid(player):
		tune = 0.0
		_still = 10.0
		var keep_v := player.velocity
		player.velocity = Vector3.ZERO
		_tune_update(10.0)
		var rose := tune > 0.1
		take_clock()
		_clock_t = 0.0
		_tune_update(0.1)
		out.append({"what": "the Tune-Out climbs while you stand and listen; the alarm clock resets it", "ok": rose and tune < 0.05})
		tune = 0.0
		has_clock = false
		player.velocity = keep_v
		Overlay.set_screen_effect("grain", 0.03)
		Overlay.set_screen_effect("desaturate", 0.0)
	C.signal_t = 10.5
	C.update_traffic(0.0)
	var avenue_red := C.green_group() == 0
	var s: Dictionary = C.streaks[16]
	var before: float = s["t"]
	for i in 30:
		C.update_traffic(0.1)
	out.append({"what": "Light Traffic is held by red lights (avenue red while the cross street runs)", "ok": avenue_red, "detail": [before, s["t"]]})
	var keep_under := _under
	_under = false
	_city_mix(Vector3(0, 0, 160))
	var night := sun.light_energy < 0.3
	_city_mix(Vector3(0, 0, -70))
	_under = keep_under
	out.append({"what": "the Neon City is always night", "ok": night})
	return out
