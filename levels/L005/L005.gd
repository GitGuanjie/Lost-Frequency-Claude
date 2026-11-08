extends LevelBase
const ModelDress := preload("res://core/world/ModelDress.gd")
## Level 5 — "Terror Hotel" (Backrooms Wikidot rev 184, accessed 2026-11-04; cite:
## "Level 5 - "Terror Hotel"" by Stretchsterz, CC BY-SA 3.0). Dossier:
## docs/canon/levels/L005.md. Every system maps to a SOURCE FACT row or an
## ADAPTATION note in level.json.
##
## Layout: authored anchors (lift lobby, The Beverly Room in its Main Hall ring,
## service stair, The Boiler Room) + streamed Main Hall chunks (L005_hotel.gd).
## Stateful systems: lifts (1-12 relocate on the same floor, 13+ death or
## disappearance, re-board to Level 3 only for those who came that way); doors
## (locked / unlock over time / swing on their own); heat by Boiler Room depth;
## self-cleaning (tracked soot fades in minutes); turntable jazz that switches at
## random; lights flickering in unison conjure a wooden door (Level 427);
## the Mahjong game that cannot be finished.

const Props := preload("res://levels/L005/L005_props.gd")
const Hotel := preload("res://levels/L005/L005_hotel.gd")
const Core := preload("res://levels/L005/L005_core.gd")
const Boiler := preload("res://levels/L005/L005_boiler.gd")
const Bank := preload("res://levels/L005/L005_audio.gd")
const Mats := preload("res://levels/L005/L005_mats.gd")
const TABLE := Vector3(16.0, 0.0, 12.8)

static var _bank: RefCounted = null

var props: RefCounted
var hotel: RefCounted
var core: RefCounted
var boiler: RefCounted
var world: ChunkWorld
var qa_fixture := false
var chandelier: OmniLight3D
var chandelier_fill: OmniLight3D
var doors: Array = []
var cars: Dictionary = {}
var _panel_cars: Dictionary = {}
var ride: Dictionary = {}
var t_level := 0.0
var zone := "hotel"
var heat := 0.0
var _arrived_lift := false
var _motor: AudioStreamPlayer
var _machinery: AudioStreamPlayer
var _heart: AudioStreamPlayer
var _music_2d: AudioStreamPlayer
var _speakers: Array = []
var _chatter: Array = []
var _buzz: Array = []
var _heard := {}
var _track := -1
var _track_t := 4.0
var _pool_t := 0.0
var _door_t := 0.0
var _unison_t := 0.0
var _unison_on := 0.0
var _tap_t := 0.0
var _moth_t := 20.0
var _heat_msg := 0
var _haze: ShaderMaterial
var _haze_rect: ColorRect
var _soot := 0.0
var _last_print := Vector3.ZERO
var _prints: Array = []
var _print_mat: StandardMaterial3D
var _print_side := 1.0
var _mj := 0
var _shove := Vector3.ZERO
var _shove_t := 0.0
var _zone_rev := ""
var _service_clues: Array = []
var _service_complete := false


func build() -> void:
	qa_fixture = SessionState.is_qa()
	var has_light := SessionState.is_developer() or SaveService.item_count("flashlight") > 0
	rules["flashlight"] = "allowed" if has_light else "none"
	rules["reverb_room"] = 0.36
	rules["reverb_wet"] = 0.12
	rules["view_distance"] = 140.0
	indoor_env(Color(0.58, 0.46, 0.38), 0.17, Color(0.07, 0.045, 0.03), 0.02)
	environment.tonemap_exposure = 1.0
	environment.glow_intensity = 0.55
	environment.glow_bloom = 0.05
	environment.glow_hdr_threshold = 0.95
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.06
	environment.adjustment_contrast = 1.07
	Mats.define_all()
	lights.setup(16, 1)
	lights.max_distance = 30.0
	props = Props.new(self)
	hotel = Hotel.new(self, props)
	core = Core.new(self, props, hotel)
	boiler = Boiler.new(self, props, hotel)
	boiler.build(self)
	_unison_t = rng.randf_range(240.0, 420.0)
	_tap_t = rng.randf_range(150.0, 320.0)
	world = ChunkWorld.new()
	world.name = "Chunks"
	world.chunk_size = Hotel.CS
	world.radius = 1
	world.unload_radius = 2
	world.builder = _build_chunk
	add_child(world)
	world.chunk_unloaded.connect(_on_unload)
	world.build_around(Vector3(-3.2, 0, 1.8), 1)
	add_arrival("start", Vector3(-3.2, 0.05, 1.8), 180.0)
	add_arrival("from_L019", Vector3(-5.5, 0.05, 4.8), -90.0)
	add_arrival("from_L025", Vector3(-3.2, 0.05, 30.2), 0.0)
	add_arrival("from_L006", Vector3(16.0, -7.3, 88.2), 0.0)
	add_arrival("from_L003", Vector3(-8.3, 0.05, 8.0), -90.0)
	# Added with Level 4 (edge L004>L005#1, "an old-fashioned stairway in Level 4"):
	# the wanderer comes down a stairway and lands on the service stair's top landing,
	# facing the door into the hotel. Nothing else in Level 5 changes.
	add_arrival("from_L004", Vector3(22.0, 0.05, 26.8), 0.0)
	_audio()
	_print_mat = StandardMaterial3D.new()
	_print_mat.albedo_color = Color(0.05, 0.04, 0.035, 0.8)
	_print_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_print_mat.roughness = 1.0
	var layer := CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	_haze_rect = ColorRect.new()
	_haze_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_haze_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = "shader_type canvas_item;\nuniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;\nuniform float amount = 0.0;\nvoid fragment() {\n\tvec2 uv = SCREEN_UV;\n\tvec2 off = vec2(sin(uv.y * 38.0 + TIME * 2.7) + 0.5 * sin(uv.y * 71.0 - TIME * 4.1), cos(uv.x * 29.0 + TIME * 2.1)) * 0.0024 * amount;\n\tvec3 c = texture(screen_tex, uv + off).rgb;\n\tc = mix(c, c * vec3(1.14, 0.93, 0.76) + vec3(0.035, 0.012, 0.0), amount * 0.6);\n\tCOLOR = vec4(c, 1.0);\n}\n"
	_haze = ShaderMaterial.new()
	_haze.shader = sh
	_haze_rect.material = _haze
	_haze_rect.visible = false
	layer.add_child(_haze_rect)
	add_landmark("Lift lobby (floor 1)", Vector3(-3.2, 0, 16.0))
	add_landmark("The Beverly Room", TABLE)
	add_landmark("Boiler Room - Housekeeping post", Vector3(5.0, -5.0, 17.4))
	add_landmark("The way down to Level 6", Vector3(16.0, -10.0, 98.7))
	add_shot("service_records", Vector3(18.9, 1.7, 15.4), Vector3(17.9, 1.3, 13.4))


	ModelDress.decorate(self, "L005")
	_install_housekeeping_records()

## OPTIONAL ADAPTATION: the hotel cannot be solved with a three-key puzzle.
## These records are collectibles with localized sound and persistent journal
## flags; they never override the source-defined doors, lift or Boiler Room exits.
func _install_housekeeping_records() -> void:
	var clues := [
		{"key": "lobby", "p": Vector3(-3.2, 1.25, 2.6), "title": "Hotel guest register", "line": "The arrival column has no dates, only floor numbers that repeat."},
		{"key": "ballroom", "p": Vector3(17.9, 1.3, 13.4), "title": "Beverly Room service slip", "line": "A dining order was collected before it was placed."},
		{"key": "boiler", "p": Vector3(5.0, -4.2, 17.4), "title": "Boiler maintenance log", "line": "The temperature rises when no fuel has been added."}
	]
	var k := kit("HousekeepingRecords")
	for item in clues:
		var pt: Vector3 = item["p"]
		var key: String = item["key"]
		_service_clues.append(key)
		k.box(pt, Vector3(0.46, 0.04, 0.32), "l5_walnut", GeoKit.ALL, false)
		add_interactable(pt + Vector3(0, 0.18, 0), Vector3(0.85, 0.85, 0.85), "Inspect a housekeeping record", func(_p): _read_housekeeping(key, str(item["title"]), str(item["line"])))
	k.commit()
	add_landmark("Guest register", Vector3(-3.2, 0.0, 2.6))
	add_landmark("Housekeeping service slip", Vector3(17.9, 0.0, 13.4))
	add_landmark("Maintenance record in the boiler", Vector3(5.0, -5.0, 17.4))
	_service_complete = _housekeeping_count() == 3


func _housekeeping_count() -> int:
	var n := 0
	for key in _service_clues:
		if SaveService.flag(stable_id, "service_" + key, false):
			n += 1
	return n


func _read_housekeeping(key: String, title: String, line: String) -> void:
	SaveService.set_flag(stable_id, "service_" + key, true)
	Overlay.toast("%s: %s (%d/3)" % [title, line, _housekeeping_count()], 5.0)
	if _housekeeping_count() == 3 and not _service_complete:
		_service_complete = true
		Overlay.subtitle("[the records have different handwriting, but the same signature]", 5.0)
		SaveService.set_flag(stable_id, "service_all_read", true)


func _audio() -> void:
	if _bank == null:
		_bank = Bank.new()
		_bank.start()
	sound.bed("room_tone", {"cutoff": 220.0}, -30.0)
	sound.oneshot("whisper", {}, 170.0, 400.0, 2.4, "[an incoherent whisper, right behind you]", -17.0)
	_music_2d = AudioStreamPlayer.new()
	_music_2d.bus = "Ambience"
	_music_2d.volume_db = -80.0
	add_child(_music_2d)
	for i in 2:
		_speakers.append(_p3d(-12.0, 16.0))
		_chatter.append(_p3d(-11.0, 10.0))
		var b := _p3d(-21.0, 6.0)
		b.stream = AudioSynth.get_stream("fluorescent_hum", {"base": 60.0, "rasp": 0.5})
		_buzz.append(b)
	_motor = AudioStreamPlayer.new()
	_motor.stream = AudioSynth.get_stream("transformer", {"base": 30.0})
	_motor.bus = "SFX"
	_motor.volume_db = -60.0
	add_child(_motor)
	_machinery = sound.bed("room_tone", {"cutoff": 150.0, "rumble": 0.9}, -80.0)
	_heart = sound.bed("heartbeat", {}, -80.0, "SFX")


func _p3d(db: float, dist: float) -> AudioStreamPlayer3D:
	var p := AudioStreamPlayer3D.new()
	p.volume_db = db
	p.max_distance = dist
	p.unit_size = 2.5
	p.bus = "Ambience"
	add_child(p)
	return p


# ------------------------------------------------------------- chunks

func _build_chunk(cx: int, cz: int, _version: int, node: Node3D) -> Dictionary:
	var meta: Dictionary = hotel.build_chunk(cx, cz, node)
	var key := Vector2i(cx, cz)
	cars[key] = meta["cars"]
	for c in meta["cars"]:
		_panel_cars[(c["panel"] as Node).get_instance_id()] = c
		c["lamp_ref"] = lights.anchors[c["lamp"]]
	if meta["kind"] == "lobby" and not meta["cars"].is_empty():
		var c0: Dictionary = meta["cars"][0]
		var t := make_exit("L005>L003#1", "interact", c0["origin"] + Vector3.UP * 1.1, Vector3(2.6, 2.2, 2.6),
			"Get back on the elevator: ride it back down to Level 3" if _arrived_by_lift() else "", node)
		if t:
			t.condition = _arrived_by_lift
	return meta


func _arrived_by_lift() -> bool:
	return spawn_report.get("used_arrival", "") == "from_L003" or str(TransitionService.arrived_via.get("from", "")) == "L003"


func _on_unload(k: Vector2i) -> void:
	lights.remove_group("%d,%d" % [k.x, k.y])
	for c in cars.get(k, []):
		_panel_cars.erase((c["panel"] as Node).get_instance_id())
	cars.erase(k)


func register_door(d: Node) -> void:
	doors.append(d)


# --------------------------------------------------------------- doors

func door_prompt(d: Node) -> String:
	var what: String = "the door" if d.beverly else "Room %s" % d.number
	if d.state in ["locked", "unlocks"]:
		return "Try %s" % what
	return ("Close %s" if d.open_amount > 0.5 else "Open %s") % what


func door_use(d: Node, _p: Node) -> void:
	if d.state in ["locked", "unlocks"]:
		sound.play_at("knock", {"hits": 2}, d.global_position + Vector3.UP * 1.0, -16.0, "[the handle rattles: locked]")
		return
	d.swing_to(0.0 if d.open_amount > 0.5 else 1.0)
	sound.play_at("creak", {"freq": 120.0}, d.global_position + Vector3.UP * 1.2, -18.0)


func _doors_tick() -> void:
	doors = doors.filter(func(d): return is_instance_valid(d))
	var pp := player.global_position
	for d in doors:
		var dist: float = d.global_position.distance_to(pp)
		if d.state == "unlocks" and t_level >= d.unlock_at:
			d.state = "unlocked"
			if dist < 12.0:
				sound.play_at("knock", {"hits": 1}, d.global_position + Vector3.UP, -24.0, "[a lock clicks open somewhere nearby]")
		elif d.state == "random" and dist < 22.0 and dist > 2.0 and t_level >= d.next_event:
			d.next_event = t_level + rng.randf_range(25.0, 75.0)
			var opening: bool = d.open_amount < 0.5
			d.swing_to(1.0 if opening else 0.0)
			sound.play_at("creak", {"freq": 95.0}, d.global_position + Vector3.UP * 1.2, -12.0,
				"[a door creaks open on its own]" if opening else "[a door swings shut down the hall]")


# ------------------------------------------------------------------ lifts

func _floor_at(car: Dictionary, hit: Vector3) -> int:
	var o: Vector3 = car["origin"]
	var col := int(floor((hit.x - (o.x + 0.88 - 0.21)) / 0.03))
	var row := int(floor((hit.y - (1.35 - 0.42)) / 0.03))
	if col < 0 or col > 13 or row < 0 or row > 27:
		return -1
	var f := row * 14 + col + 1
	return f if f <= 382 else -1


func _in_car(car: Dictionary, p: Vector3) -> bool:
	var o: Vector3 = car["origin"]
	return absf(p.x - o.x) < 1.45 and absf(p.z - o.z) < 1.45 and absf(p.y - o.y) < 1.0


func _panel_aim() -> void:
	var ray: RayCast3D = player.ray
	if not ray.is_colliding() or ray.get_collider() == null:
		return
	var car: Dictionary = _panel_cars.get(ray.get_collider().get_instance_id(), {})
	if car.is_empty():
		return
	var f := _floor_at(car, ray.get_collision_point())
	(car["panel"] as Interactable).prompt = ("Press floor %d" % f) if f > 0 else "Floors 1 to 382"
	if ride.is_empty():
		(car["readout"] as Label3D).text = str(f) if f > 0 else ""


func panel_press(_p: Node, car: Dictionary) -> void:
	if not ride.is_empty() or TransitionService.loading:
		return
	var f := _floor_at(car, player.ray.get_collision_point()) if player.ray.is_colliding() else -1
	if f < 1:
		Overlay.subtitle("[you need to press one of the buttons]", 2.0)
		return
	if not _in_car(car, player.global_position):
		Overlay.toast("Step inside the car first.", 2.5)
		return
	ride = {"car": car, "floor": f, "t": 0.0, "stage": 0}
	(car["readout"] as Label3D).text = str(f)
	_car_door(car, false)
	sound.play_at("creak", {"freq": 70.0}, car["origin"] + Vector3.UP * 1.4, -9.0, "[the doors close]")
	_motor.pitch_scale = 1.0
	_motor.play()


func _car_door(car: Dictionary, open: bool, instant := false) -> void:
	if not is_instance_valid(car["door"]):
		return
	car["open"] = open
	(car["blocker"] as StaticBody3D).collision_layer = 0 if open else 1
	var tw: Tween = null if instant else create_tween().set_parallel(true)
	var leaves: Array = car["leaves"]
	if car["style"] == "antique":
		var sc := Vector3(0.12 if open else 1.0, 1, 1)
		if instant:
			leaves[0].scale = sc
		else:
			tw.tween_property(leaves[0], "scale", sc, 0.9)
	else:
		for s in 2:
			var z: float = (-0.42 if s == 0 else 2.02) if open else (0.4 if s == 0 else 1.2)
			if instant:
				leaves[s].position.z = z
			else:
				tw.tween_property(leaves[s], "position:z", z, 0.9)


func _ride_tick(delta: float) -> void:
	var car: Dictionary = ride["car"]
	ride["t"] += delta
	var t: float = ride["t"]
	var f: int = ride["floor"]
	_motor.volume_db = lerpf(_motor.volume_db, -13.0, clampf(delta * 2.0, 0.0, 1.0))
	if f <= 12:
		if ride["stage"] == 0 and t > 1.2:
			ride["stage"] = 1
			Overlay.subtitle("[the car hums and sways, but you never feel it climb]", 3.0)
		elif ride["stage"] == 1 and t > 4.3:
			ride["stage"] = 2
			_relocate(car, f)
		elif ride["stage"] == 2 and t > 5.0:
			ride["stage"] = 3
			_car_door(ride["car"], true)
			sound.play_at("music_box", {"notes": [12, -99, -99, -99], "root": 880.0}, player.global_position + Vector3.UP, -14.0, "[ding] Floor %d. The same floor, somewhere else in the hotel." % f)
		elif ride["stage"] == 3 and t > 6.2:
			_motor.stop()
			ride = {}
		return
	_motor.pitch_scale = 1.0 + t * 0.14
	var lamp: Dictionary = car.get("lamp_ref", {})
	if not lamp.is_empty():
		lamp["energy"] = 0.8 if rng.randf() < 0.55 else 0.05
	if ride["stage"] == 0 and t > 1.2:
		ride["stage"] = 1
		Overlay.subtitle("[the car begins to rise]", 2.5)
	if t > 3.6:
		Overlay.set_screen_effect("blackout", clampf((t - 3.6) / 1.5, 0.0, 1.0))
	if ride["stage"] == 1 and t > 5.4:
		ride["stage"] = 2
		_motor.stop()
		var dies := absi(hash([level_seed, f])) % 2 == 0
		player.hurt(1000.0, ("The car climbed past floor 12 (button %d). Riding to 13 or higher ends in death." % f) if dies
			else ("You rode to floor %d and were never seen again. It is unknown what is above floor 12." % f))


func _relocate(car: Dictionary, f: int) -> void:
	var dest: Vector2i = hotel.lift_keys[f - 1]
	if dest == car["key"]:
		dest = hotel.lift_keys[f % 12]
	world.build_around(Vector3(dest.x * Hotel.CS + 16.0, 0, dest.y * Hotel.CS + 16.0), 1)
	var dcar := {}
	for c in cars.get(dest, []):
		if c["idx"] == car["idx"]:
			dcar = c
	if dcar.is_empty():
		ride["car"] = car
		return
	_car_door(dcar, false, true)
	var off: Vector3 = player.global_position - (car["origin"] as Vector3)
	player.global_position = (dcar["origin"] as Vector3) + off
	_car_door(car, true, true)
	(dcar["indicator"] as Label3D).text = str(f)
	(dcar["readout"] as Label3D).text = str(f)
	ride["car"] = dcar


# ------------------------------------------------------------ interactions

func mahjong_attempt(p: Node) -> void:
	_mj += 1
	var away: Vector3 = p.global_position - TABLE
	away.y = 0.0
	_shove = away.normalized() * (3.2 + minf(_mj, 5) * 0.6)
	_shove_t = 0.7
	Overlay.subtitle(["[an overwhelming urge to step away from the table]", "[your hands will not reach the tiles]", "[you would rather be anywhere but here]"][_mj % 3], 3.0)
	if _mj == 1:
		Overlay.toast("Whoever sat here never finished. You cannot either: something in you refuses.", 4.5)


func rest_in_room(_p: Node) -> void:
	checkpoint("living_quarters")
	Overlay.toast("The furnished quarters are clean, quiet and lived-in. You rest a while. (Checkpoint)", 4.0)


func maintenance_lift(_p: Node) -> void:
	Overlay.toast("Housekeeping has chained the gate. Maintenance elevators are present, but using them is not advised.", 4.5)


# ----------------------------------------------------------------- runtime

func on_player_ready() -> void:
	world.target = player
	_arrived_lift = _arrived_by_lift()
	if SessionState.is_story():
		checkpoint(str(spawn_report.get("used_arrival", "start")))
		if not SaveService.flag(stable_id, "arrived", false):
			SaveService.set_flag(stable_id, "arrived", true)
			Overlay.subtitle("[quiet jazz from a turntable somewhere down the hall] [polished wood and brass]", 5.0)
	if qa_fixture:
		qa_routes.append({"edge": "L005>L006#3", "target": Vector3(16.0, -9.0, 98.7), "note": "lobby -> Beverly Room -> service stair -> Boiler Room -> deep passage"})


func level_process(delta: float) -> void:
	if player == null:
		return
	t_level += delta
	var p := player.global_position
	var was := zone
	zone = "boiler" if (p.y < -1.0 and p.x > 2.0 and p.x < 36.0 and p.z > 3.0 and p.z < 101.0) else "hotel"
	heat = Boiler.heat_at(p)
	_env(delta, p)
	if zone != was or _zone_rev == "":
		_zone_rev = zone
		Settings.set_reverb(0.72 if zone == "boiler" else 0.36, 0.2 if zone == "boiler" else 0.12)
	_heat_effects(delta)
	_panel_aim()
	if not ride.is_empty():
		_ride_tick(delta)
	_door_t -= delta
	if _door_t <= 0.0:
		_door_t = 0.5
		_doors_tick()
	_pool_t -= delta
	if _pool_t <= 0.0:
		_pool_t = 0.5
		_pools(p)
	_music(delta)
	_sporadic(delta, p)
	_unison(delta, p)
	_footprints(delta, p)
	_ambient_events(delta, p)
	if _shove_t > 0.0:
		_shove_t -= delta
		player.move_and_collide(_shove * delta)
	elif zone == "hotel" and Vector2(p.x - TABLE.x, p.z - TABLE.z).length() < 0.95 and p.y < 1.0:
		var a := Vector3(p.x - TABLE.x, 0, p.z - TABLE.z).normalized()
		player.move_and_collide(a * 1.6 * delta)


func _env(delta: float, p: Vector3) -> void:
	var k := clampf(delta * 1.5, 0.0, 1.0)
	var boil := zone == "boiler"
	var fog_c := Color(0.07, 0.045, 0.03)
	var dens := 0.02
	var amb := 0.17
	if boil:
		fog_c = Color(0.13, 0.095, 0.07).lerp(Color(0.24, 0.1, 0.045), heat)
		dens = 0.022 + heat * 0.03
		amb = 0.18
	environment.fog_light_color = environment.fog_light_color.lerp(fog_c, k)
	environment.fog_density = lerpf(environment.fog_density, dens, k)
	environment.ambient_light_energy = lerpf(environment.ambient_light_energy, amb, k)
	var hotel_on := p.y > -1.6
	var boil_on := p.y < 0.6
	if lights.is_processing() != hotel_on:
		lights.set_process(hotel_on)
		for l in lights.pool:
			l.visible = false
	if boiler.lights.is_processing() != boil_on:
		boiler.lights.set_process(boil_on)
		for l in boiler.lights.pool:
			l.visible = false
	if is_instance_valid(chandelier):
		chandelier.visible = hotel_on and p.y > -0.8
		chandelier_fill.visible = chandelier.visible
	_music_2d.volume_db = lerpf(_music_2d.volume_db, -31.0 if (not boil and _track >= 0) else -80.0, k)
	_machinery.volume_db = lerpf(_machinery.volume_db, -11.0 if boil else -80.0, k)


func _heat_effects(delta: float) -> void:
	var vis := smoothstep(0.42, 1.0, heat)
	_haze_rect.visible = vis > 0.01
	_haze.set_shader_parameter("amount", vis)
	player.sprint_speed = lerpf(5.3, 3.3, smoothstep(0.62, 0.9, heat))
	_heart.volume_db = lerpf(-80.0, -9.0, smoothstep(0.7, 1.0, heat))
	if heat > 0.86 and not player.frozen and not player.dead:
		player.hurt((heat - 0.86) * 34.0 * delta, "Overcome by the extreme heat deep in the Boiler Room")
	elif heat < 0.5 and not player.dead:
		player.heal(2.5 * delta)
	var lvl := 0
	if heat >= 0.88:
		lvl = 2
	elif heat >= 0.68:
		lvl = 1
	if lvl > _heat_msg:
		Overlay.subtitle(["", "[the air is scalding; sweat stings your eyes]", "[the heat is unbearable: every breath burns]"][lvl], 3.5)
	_heat_msg = lvl if lvl > _heat_msg or heat < 0.5 else _heat_msg


func _pools(p: Vector3) -> void:
	var spk: Array = []
	var cht: Array = []
	var bz: Array = []
	for key in world.chunks.keys():
		var m: Dictionary = world.chunks[key]["meta"]
		spk.append_array(m.get("speakers", []))
		cht.append_array(m.get("chatter", []))
		bz.append_array(m.get("buzz", []))
	_assign(_speakers, spk, p, 30.0, null)
	_assign(_chatter, cht, p, 14.0, _bank.chatter if (_bank and _bank.is_ready()) else null)
	_assign(_buzz, bz, p, 9.0, null)
	if zone == "hotel":
		for c in cht:
			var key := str(Vector3i(c))
			if c.distance_to(p) < 6.0 and not _heard.has(key):
				_heard[key] = true
				Overlay.subtitle("[party chatter on the other side of the wall]", 3.0)
		for b in bz:
			var key := "b" + str(Vector3i(b))
			if b.distance_to(p) < 3.5 and not _heard.has(key):
				_heard[key] = true
				Overlay.subtitle("[an electric candle buzzes, like the lights of Level 0]", 3.0)


func _assign(players: Array, anchors: Array, p: Vector3, maxd: float, stream: AudioStream) -> void:
	anchors.sort_custom(func(a, b): return a.distance_squared_to(p) < b.distance_squared_to(p))
	for i in players.size():
		var pl: AudioStreamPlayer3D = players[i]
		if stream != null and pl.stream != stream:
			pl.stream = stream
		if i < anchors.size() and anchors[i].distance_to(p) < maxd and pl.stream != null and zone == "hotel":
			pl.global_position = anchors[i]
			if not pl.playing:
				pl.play()
		elif pl.playing:
			pl.stop()


func _music(delta: float) -> void:
	if _bank == null or not _bank.is_ready():
		return
	_track_t -= delta
	if _track_t > 0.0:
		return
	_track_t = rng.randf_range(70.0, 150.0)
	var first := _track < 0
	var pick := rng.randi() % 3
	if not first and rng.randf() < 0.22:
		pick = 3
	elif pick == _track:
		pick = (pick + 1) % 3
	_track = pick
	var st: AudioStream = _bank.tracks[pick] if pick < 3 else AudioSynth.get_stream("chiptune", {"bpm": 150.0, "root": 262.0})
	if pick == 3:
		_track_t = rng.randf_range(25.0, 45.0)
	for pl in [_music_2d] + _speakers:
		pl.stream = st
		if pl == _music_2d or pl.playing:
			pl.play()
	if not first and zone == "hotel":
		Overlay.subtitle("[the speakers switch to something that does not belong here]" if pick == 3 else "[the record changes abruptly]", 3.0)


func _sporadic(delta: float, p: Vector3) -> void:
	for s in boiler.sporadic:
		s["t"] -= delta
		if s["t"] > 0.0:
			continue
		s["t"] = rng.randf_range(s["min"], s["max"])
		var d: float = (s["pos"] as Vector3).distance_to(p)
		if d < s["dist"]:
			sound.play_at(s["recipe"], s["params"], s["pos"], s["vol"], s["caption"] if d < s["dist"] * 0.6 else "")


## "If flickering lights occur in unison, then a wooden door will appear."
func _unison(delta: float, p: Vector3) -> void:
	if zone != "hotel" or not ride.is_empty():
		return
	_unison_t -= delta
	if _unison_on <= 0.0 and _unison_t <= 0.0:
		_unison_on = 3.6
		Overlay.subtitle("[every light in the hall flickers at once]", 3.0)
	if _unison_on <= 0.0:
		return
	_unison_on -= delta
	var on := fmod(t_level * 7.3, 1.0) < 0.5 and fmod(t_level * 2.9, 1.0) > 0.2
	_light_mult(1.0 if (on or _unison_on <= 0.0) else 0.05)
	if _unison_on <= 0.0:
		_unison_t = rng.randf_range(300.0, 600.0)
		_spawn_427(p)


func _light_mult(m: float) -> void:
	for a in lights.anchors:
		if not a.has("base"):
			a["base"] = a["energy"]
		a["energy"] = a["base"] * m
	(MatLib.get_mat("l5_flame") as ShaderMaterial).set_shader_parameter("emission_energy", 7.0 * m)
	(MatLib.get_mat("l5_crystal") as ShaderMaterial).set_shader_parameter("emission_energy", 4.5 * m)
	if is_instance_valid(chandelier):
		chandelier.light_energy = 3.0 * m


func _spawn_427(p: Vector3) -> void:
	var best := {}
	var bd := 1e9
	var bkey := Vector2i.ZERO
	for key in world.chunks.keys():
		for b in world.chunks[key]["meta"].get("blank", []):
			var d: float = (b["p"] as Vector3).distance_to(p)
			if d > 2.5 and d < 14.0 and d < bd:
				bd = d
				best = b
				bkey = key
	if best.is_empty():
		return
	var node: Node3D = world.chunks[bkey]["node"]
	var c: Vector3 = best["p"]
	var t: Vector3 = best["t"]
	var n: Vector3 = best["n"]
	var mi := MeshInstance3D.new()
	mi.mesh = props.door_mesh("plain")
	mi.transform = Transform3D(Basis(t, Vector3.UP, t.cross(Vector3.UP)), c - t * 0.5 + n * 0.03)
	node.add_child(mi)
	var k := GeoKit.new(node, "Door427")
	hotel._casing(k, c - t * 1.6 + n * 0.0, t, n, "l5_wood", 0.0)
	k.commit()
	(best as Dictionary)["p"] = Vector3(1e6, 0, 1e6)
	var sz := Vector3(1.2, 2.2, 1.4) if absf(t.x) > 0.5 else Vector3(1.4, 2.2, 1.2)
	make_exit("L005>L427#7", "interact", c + n * 0.7 + Vector3.UP * 1.1, sz, "Open the wooden door", node)
	Overlay.subtitle("[a plain wooden door stands where there was only wallpaper]", 4.0)


## The level cleans itself: soot tracked up from the Boiler Room fades in minutes.
func _footprints(delta: float, p: Vector3) -> void:
	if zone == "boiler" and player.is_on_floor():
		_soot = 1.0
	elif _soot > 0.0 and player.is_on_floor() and p.y > -0.2 and Vector2(p.x - _last_print.x, p.z - _last_print.z).length() > 0.7:
		var dir := Vector3(p.x - _last_print.x, 0, p.z - _last_print.z).normalized()
		_last_print = p
		_print_side = -_print_side
		var mi := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.11, 0.27)
		mi.mesh = qm
		mi.material_override = _print_mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
		var side := dir.cross(Vector3.UP) * 0.11 * _print_side
		mi.position = p + side + Vector3.UP * 0.012
		mi.rotation = Vector3(-PI * 0.5, atan2(-dir.x, -dir.z), 0)
		mi.transparency = 1.0 - _soot
		_prints.append({"node": mi, "age": 0.0, "life": rng.randf_range(110.0, 200.0), "a0": 1.0 - _soot})
		_soot -= 0.07
	if _prints.is_empty():
		return
	var keep: Array = []
	for pr in _prints:
		pr["age"] += delta
		var life: float = pr["life"]
		var n: MeshInstance3D = pr["node"]
		if pr["age"] > life or not is_instance_valid(n):
			if is_instance_valid(n):
				n.queue_free()
			continue
		n.transparency = maxf(pr["a0"], smoothstep(life * 0.55, life, pr["age"]))
		keep.append(pr)
	_prints = keep


func _ambient_events(delta: float, p: Vector3) -> void:
	if zone != "hotel":
		return
	_tap_t -= delta
	if _tap_t <= 0.0:
		_tap_t = rng.randf_range(200.0, 460.0)
		sound.play_at("knock", {"hits": 1}, player.global_position + Vector3.UP * 1.4, -24.0, "[something taps your shoulder: no one is there]")
		player.head.rotation.z = 0.0
	_moth_t -= delta
	if _moth_t > 0.0:
		return
	_moth_t = 4.0
	var key := world.key_at(p)
	var m: Dictionary = world.meta_of(key)
	for dr in m.get("dark_rooms", []):
		var pos: Vector3 = dr["pos"]
		if pos.distance_to(p) < 9.0:
			_moth_t = rng.randf_range(70.0, 140.0)
			_moths(pos, dr["n"])
			return


## Deathmoths "fly out of dark rooms, swarming the halls" (ambient swarm only).
func _moths(pos: Vector3, n: Vector3) -> void:
	var cp := CPUParticles3D.new()
	cp.one_shot = true
	cp.amount = 70
	cp.lifetime = 4.5
	cp.explosiveness = 0.55
	cp.direction = n + Vector3.UP * 0.2
	cp.spread = 50.0
	cp.gravity = Vector3(0, 0.15, 0)
	cp.initial_velocity_min = 1.5
	cp.initial_velocity_max = 4.0
	cp.angular_velocity_min = -360.0
	cp.angular_velocity_max = 360.0
	cp.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	cp.emission_box_extents = Vector3(0.4, 0.8, 0.4)
	var qm := QuadMesh.new()
	qm.size = Vector2(0.09, 0.06)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.32, 0.27, 0.2)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	qm.material = mat
	cp.mesh = qm
	cp.position = pos
	add_child(cp)
	cp.emitting = true
	get_tree().create_timer(6.0).timeout.connect(cp.queue_free)
	sound.play_at("crackle", {"seconds": 2.6}, pos, -10.0, "[a rush of wings: moths pour out of a dark room]")


# ----------------------------------------------------------------- QA

func qa_self_test() -> Array:
	var result: Array = []
	# DEV13: the lower inspection deck and both aligned B1 entry catwalks
	# must have real StaticBody colliders, not only graph declarations.
	var physics := get_world_3d().direct_space_state
	var lower := physics.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(-10.1, -6.1, 24.5), Vector3(-10.1, -9.1, 24.5), 1))
	var entry_a := physics.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(-1.5, -3.4, 15.0), Vector3(-1.5, -6.3, 15.0), 1))
	var entry_b := physics.intersect_ray(PhysicsRayQueryParameters3D.create(
		Vector3(0.0, -3.4, 19.5), Vector3(0.0, -6.3, 19.5), 1))
	result.append({"what": "DEV13 B1 inspection annex lower deck collision at -8.1m",
		"ok": not lower.is_empty() and absf(float(lower.get("position", Vector3.ZERO).y) + 8.1) < 0.2,
		"detail": lower.get("position", Vector3.ZERO)})
	result.append({"what": "DEV13 both B1 annex entry catwalks have walkable collisions",
		"ok": not entry_a.is_empty() and not entry_b.is_empty()
			and absf(float(entry_a.get("position", Vector3.ZERO).y) + 5.0) < 0.2
			and absf(float(entry_b.get("position", Vector3.ZERO).y) + 5.0) < 0.2,
		"detail": [entry_a.get("position", Vector3.ZERO), entry_b.get("position", Vector3.ZERO)]})
	result.append({"what": "three distinct housekeeping records", "ok": _service_clues == ["lobby", "ballroom", "boiler"]})
	for key in _service_clues:
		_read_housekeeping(key, "QA", "Optional evidence")
	result.append({"what": "service evidence persists without altering exits", "ok": _housekeeping_count() == 3 and bool(SaveService.flag(stable_id, "service_all_read", false))})
	return result


func qa_capture_plan() -> Array:
	var plan: Array = []
	plan.append({"name": "hall", "pos": Vector3(-2.6, 1.62, 0.7), "target": Vector3(-4.9, 1.45, 22.0)})
	plan.append({"name": "beverly", "pos": Vector3(8.2, 1.65, 19.6), "target": Vector3(16.6, 4.0, 11.0)})
	plan.append({"name": "ballroom_wide", "pos": Vector3(4.6, 1.75, 21.2), "target": Vector3(17.5, 3.4, 9.0)})
	plan.append({"name": "ring", "pos": Vector3(1.6, 1.62, 26.5), "target": Vector3(1.6, 1.5, 4.0)})
	plan.append({"name": "boiler", "pos": Vector3(6.0, -3.3, 21.5), "target": Vector3(19.0, -3.8, 9.5)})
	plan.append({"name": "dev13_b1_annex", "pos": Vector3(-10.0, -6.1, 24.5), "target": Vector3(-1.1, -4.2, 19.5)})
	plan.append({"name": "furnace", "pos": Vector3(20.0, -4.4, 62.6), "target": Vector3(15.0, -5.2, 75.0)})
	plan.append({"name": "deep", "pos": Vector3(16.0, -4.7, 77.0), "target": Vector3(16.0, -7.6, 92.0)})
	var cs := _corridor_shot()
	if not cs.is_empty():
		plan.append(cs)
	var c0: Dictionary = cars.get(Vector2i(-1, 0), [{}])[0]
	if not c0.is_empty():
		var o: Vector3 = c0["origin"]
		plan.append({"name": "lift", "pos": o + Vector3(-0.9, 1.62, 0.9), "target": o + Vector3(0.88, 1.4, -1.49)})
	return plan


func _corridor_shot() -> Dictionary:
	for key in [Vector2i(-2, -1), Vector2i(1, -1), Vector2i(-2, 1), Vector2i(1, 1), Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, -1)]:
		if not hotel.kind_of(key.x, key.y) in ["hall", "walnut"]:
			continue
		var cells: PackedInt32Array = hotel.layout(key.x, key.y)["cells"]
		for j in Hotel.N:
			var run := 0
			for i in Hotel.N:
				run = run + 1 if cells[j * Hotel.N + i] == Hotel.COR else 0
				if run >= 5:
					var o := Vector3(key.x * Hotel.CS, 0, key.y * Hotel.CS)
					var a := o + Vector3((i - run + 1) * Hotel.G + 0.5, 1.62, j * Hotel.G + 1.6)
					var b := o + Vector3((i + 1) * Hotel.G, 1.5, j * Hotel.G + 1.6)
					return {"name": "corridor", "pos": a, "target": b, "prepare": func(): world.build_around(a, 1)}
	return {}
