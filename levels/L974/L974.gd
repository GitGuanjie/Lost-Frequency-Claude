extends LevelBase
## Level 974 — "Kitty's House" (Backrooms Wikidot rev 15, accessed 2026-11-04;
## cite: AndromedeadReal, CC BY-SA 3.0). Dossier: docs/canon/levels/L974.md.
##
## A compact, finite, pink home (~970 sq ft) with no door to the outdoors and
## windows that are coquette artwork. Developer-accessible only (the page's
## entrance is a slight chance when no-clipping with a 'cute' item; no story
## route reaches it). Systems, each mapped to the page:
##   Kitty           stalks smoothly and swiftly, never hostile; withdraws for good
##                   after aggression or house damage (food and sanity go too)
##   Gift exit       hand Kitty a cute item obtained BEFORE the visit -> you fall
##                   asleep and wake in an unnamed safe level (unbuilt route)
##   Sleep exit      DreamSleep loads ~1 min, then sleeping in the BED -> 974.1;
##                   sleeping anywhere else leads nowhere
##   Pink walls      calming at first, then anxiety and sanity loss over time
##   Food            fridge/pantry restock themselves; long stays turn it to sugar;
##                   childhood-meal smells (rarely a real meal on the table)
##   Memories        childhood memories surface fuzzy while inside
## The keepsake: arriving here requires carrying a 'cute' item (Entrances), so
## the wanderer always holds the one that brought them — that is the gift.

const House := preload("res://levels/L974/L974_house.gd")
const KittyScript := preload("res://levels/L974/L974_kitty.gd")
const PcScript := preload("res://levels/L974/L974_pc.gd")
const WARM := Color(1.0, 0.87, 0.78)
const WAYPOINTS := [
	Vector3(2.1, 0.18, 1.6), Vector3(3.5, 0.18, 2.3), Vector3(3.5, 0, 3.6), Vector3(1.2, 0, 3.6), Vector3(5.15, 0, 3.6),
	Vector3(5.15, 0, 2.1), Vector3(6.9, 0, 3.6), Vector3(6.9, 0, 2.4), Vector3(8.0, 0, 1.6), Vector3(7.9, 0, 3.6),
	Vector3(7.9, 0, 5.5), Vector3(10.0, 0, 6.2), Vector3(10.95, 0, 3.6), Vector3(10.95, 0, 2.2), Vector3(4.0, -0.36, 5.1),
	Vector3(2.4, -0.36, 6.3), Vector3(4.4, -0.36, 5.2)]
const EDGES := [[0, 1], [1, 2], [2, 3], [2, 4], [2, 14], [4, 5], [4, 6], [6, 7], [7, 8], [6, 9], [9, 10], [10, 11],
	[9, 12], [12, 13], [14, 15], [15, 16], [16, 10], [14, 16]]

var kitty
var pc
var qa_fixture := false
var keepsake := true
var gifted := false
var sanity := 100.0
var exposure := 0.0
var withdrawn := false
var house_damaged := false
var food := {"fridge": 3, "pantry": 3}
var _restock := {"fridge": 0.0, "pantry": 0.0}
var _real_meal := false
var _meal_it: Interactable
var _meal_mesh: Node3D
var _music: AudioStreamPlayer
var _rustle: AudioStreamPlayer3D
var _smell_t := 0.0
var _memory_t := 70.0
var _anx_msg := false
var _calm_msg := false
var _window_tries := {}
var _sleep_fx := 0.0


func build() -> void:
	qa_fixture = SessionState.is_qa()
	rules["flashlight"] = "allowed"
	rules["reverb_room"] = 0.18
	rules["reverb_wet"] = 0.06
	rules["view_distance"] = 60.0
	indoor_env(Color(1.0, 0.86, 0.9), 0.24, Color(0.95, 0.8, 0.85), 0.0)
	environment.tonemap_exposure = 1.0
	environment.glow_enabled = true
	environment.glow_intensity = 0.3
	environment.glow_hdr_threshold = 1.1
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.06
	House.materials(level_seed)
	lights.setup(10, 1)
	lights.max_distance = 20.0
	var k := kit("House")
	House.shell(k)
	var wins: Array = House.windows(k)
	House.bedroom(k)
	House.master(k)
	House.baths(k)
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "tailored"])
	House.kitchen(k, r)
	House.switches(k)
	House.frames(k, r)
	_lamps(k)
	k.commit()
	_plushies(r)
	# Kitty first: her gift trigger is the QA walker's target
	kitty = KittyScript.new()
	kitty.name = "Kitty"
	add_child(kitty)
	kitty.setup(hash([level_seed, "kitty"]))
	kitty.nodes = WAYPOINTS.duplicate()
	for i in WAYPOINTS.size():
		kitty.adj.append([])
	for e in EDGES:
		kitty.adj[e[0]].append(e[1])
		kitty.adj[e[1]].append(e[0])
	kitty.home = Vector3(2.1, 0.18, 1.35)
	kitty.home_face = Vector3(0, 0, 1)
	kitty.place_at(kitty.home if qa_fixture else Vector3(10.95, 0, 3.6), Vector3(0, 0, 1) if qa_fixture else Vector3(-1, 0, 0))
	kitty.state = KittyScript.State.HOME if qa_fixture else KittyScript.State.STALK
	kitty.frozen = qa_fixture
	kitty.appeared_close.connect(_on_kitty_close)
	var gift := make_exit("L974>EXT#2", "interact", Vector3(0, 1.2, 0), Vector3(2.8, 2.4, 2.8), "", kitty)
	if gift:
		gift.condition = _gift_ok
		gift.fired.connect(func(_e: String) -> void: _on_gift())
	var kit_it := Interactable.new()
	kit_it.name = "KittyHitbox"
	kitty.add_child(kit_it)
	kit_it.setup(Vector3(0, 1.25, -0.15), Vector3(0.8, 2.4, 0.8), "Give Kitty your keepsake", func(p: Player) -> void:
		if gift:
			gift.interact(p))
	kitty.set_meta("hitbox", kit_it)
	_rustle = AudioStreamPlayer3D.new()
	_rustle.stream = AudioSynth.get_stream("room_tone", {"cutoff": 1700.0, "seconds": 2.0})
	_rustle.volume_db = -60.0
	_rustle.max_distance = 9.0
	_rustle.bus = "SFX"
	_rustle.autoplay = true
	_rustle.position = Vector3(0, 1.4, 0)
	kitty.add_child(_rustle)
	# computer and bed (DreamSleep -> 974.1)
	pc = PcScript.new()
	pc.name = "Computer"
	add_child(pc)
	pc.build(Vector3(6.66, 0.955, 1.02), Vector3(1, 0, 0), self)
	pc.dreams_ready.connect(func() -> void: Overlay.subtitle("[the monitor chimes softly: your dreams are ready]", 4.0))
	var bed := make_exit("L974>L974_1#1", "interact", Vector3(9.5, 0.6, 1.34), Vector3(1.4, 1.2, 2.2), "", self)
	if bed:
		bed.condition = func() -> bool: return pc.ready_flag
		bed.fired.connect(func(_e: String) -> void: _fall_asleep("[you sleep in the bed, and the dream takes you]"))
		add_interactable(Vector3(9.5, 0.62, 1.34), Vector3(0.95, 0.3, 1.85), "Lie down on the bed", func(p: Player) -> void:
			if pc.ready_flag:
				bed.interact(p)
			else:
				_doze("You lie down. The sheets smell faintly familiar and you grow drowsy, but no dream comes."))
	add_interactable(Vector3(2.1, 0.45, 0.55), Vector3(0.9, 0.4, 0.9), "Curl up in the cat bed", func(_p: Player) -> void:
		_doze("You curl up in the cat bed and doze. Sleeping anywhere but the bed leads nowhere."))
	# food, meal, taps, windows
	add_interactable(Vector3(11.2, 0.9, 5.37), Vector3(0.1, 1.6, 0.7), "Open the fridge", _take_food.bind("fridge"))
	add_interactable(Vector3(11.37, 1.0, 6.25), Vector3(0.1, 1.9, 0.75), "Open the pantry", _take_food.bind("pantry"))
	_real_meal = r.randf() < 0.12
	if _real_meal:
		_place_meal()
	for tap in [Vector3(9.9, 1.0, 4.58), Vector3(5.9, 0.95, 1.55), Vector3(11.7, 0.95, 1.9)]:
		add_interactable(tap, Vector3(0.3, 0.2, 0.3), "Run the tap", func(_p: Player) -> void:
			sound.play_at("splash", {}, tap, -12.0, "[water runs from the tap, clear and warm]"))
	for i in wins.size():
		var wd: Array = wins[i]
		var n: Vector3 = wd[1]
		add_interactable(wd[0] + n * 0.05, Vector3(0.3 + absf(n.z) * float(wd[2]), float(wd[3]), 0.3 + absf(n.x) * float(wd[2])), "Try to open the window", _window.bind(i))
	# sound: "A foggy lullaby" (the page's own audio), soft pad, room tone, fridge hum
	_music = sound.bed("music_box", {"notes": [0, 4, 7, 12, 11, 7, 4, 2, 0, 4, 9, 7, 5, 4, 2, -1], "root": 392.0}, -17.0, "Music")
	sound.bed("pad", {"root": 196.0, "chord": [0, 4, 7, 11], "bright": 0.08, "seconds": 10.0}, -24.0, "Music")
	sound.bed("room_tone", {"cutoff": 300.0}, -33.0)
	sound.emitter("fluorescent_hum", Vector3(11.6, 1.2, 5.4), {"base": 50.0, "rasp": 0.05}, -30.0, 5.0)
	add_arrival("start", Vector3(2.6, -0.34, 6.7), 0.0)
	add_shot("bedroom", Vector3(6.45, 1.62, 2.6), Vector3(9.7, 1.05, 0.9), {"prepare": _pose.bind(Vector3(8.55, 0, 0.95), "dream")})
	add_shot("house", Vector3(0.7, -0.36 + 1.62, 7.5), Vector3(6.5, 0.9, 4.6), {"prepare": _pose.bind(Vector3(4.15, -0.36, 5.75), "")})
	add_landmark("Living room (sunken)", Vector3(2.6, -0.36, 6.3))
	add_landmark("Kitty's cat bed", Vector3(2.1, 0.18, 0.55))


func _lamps(k: GeoKit) -> void:
	for l in [[Vector3(2.6, 2.6, 6.1), 1.5], [Vector3(10.0, 2.6, 6.2), 1.4], [Vector3(8.0, 2.6, 1.5), 1.3],
			[Vector3(2.1, 2.6, 1.5), 0.8], [Vector3(5.2, 2.6, 1.5), 0.9], [Vector3(11.0, 2.6, 1.5), 0.9],
			[Vector3(2.0, 2.6, 3.6), 0.7], [Vector3(9.2, 2.6, 3.6), 0.7]]:
		var p: Vector3 = l[0]
		k.cylinder(p - Vector3(0, 0.05, 0), 0.2, 0.08, "l974_lamp_panel", 16, false)
		lights.add_anchor(p - Vector3(0, 0.35, 0), WARM, float(l[1]) * 0.8, 6.0)
	k.cylinder(Vector3(6.6, 2.3, 6.82), 0.008, 0.62, "l974_dark", 6, false)
	k.cylinder(Vector3(6.6, 1.93, 6.82), 0.17, 0.14, "l974_lamp_panel", 16, false)
	lights.add_anchor(Vector3(6.6, 1.7, 6.82), WARM, 1.1, 4.5)
	# soft daylight-coloured glow from each painted window
	for w in [Vector3(8.0, 1.5, 0.6), Vector3(2.3, 1.1, 7.4), Vector3(9.1, 1.5, 7.4), Vector3(0.6, 1.7, 1.5), Vector3(0.6, 1.1, 6.1)]:
		lights.add_anchor(w, Color(1.0, 0.82, 0.88), 0.55, 4.0)


func _plushies(r: RandomNumberGenerator) -> void:
	var cols := [Color(1.0, 0.78, 0.86), Color(0.98, 0.95, 0.9), Color(0.8, 0.88, 1.0), Color(0.95, 0.85, 1.0), Color(1.0, 0.9, 0.72)]
	var spots := [[Vector3(9.3, 0.58, 0.55), 0.3], [Vector3(9.6, 0.58, 0.6), -0.4], [Vector3(9.75, 0.58, 1.3), 1.4],
		[Vector3(7.9, 0.86, 2.75), 3.0], [Vector3(8.5, 0.86, 2.72), 2.8], [Vector3(6.32, 1.39, 0.5), 1.6],
		[Vector3(6.32, 1.39, 1.45), 1.4], [Vector3(6.5, 0.0, 2.6), 2.2], [Vector3(9.4, 0.58, 2.05), 0.0]]
	for i in spots.size():
		House.plush(self, spots[i][0], spots[i][1], cols[r.randi() % cols.size()], r.randf() < 0.45, 1.0 if i != 7 else 1.6)


# ------------------------------------------------------------- interactions

func _gift_ok() -> bool:
	return keepsake and not gifted and player != null and player.global_position.distance_to(kitty.global_position) < 2.4


func _on_gift() -> void:
	gifted = true
	keepsake = false
	kitty.state = KittyScript.State.GIFTED
	_fall_asleep("[you hand Kitty your keepsake ... and immediately fall asleep]")


func _fall_asleep(caption: String) -> void:
	Overlay.subtitle(caption, 4.0)
	_sleep_fx = 1.0
	await get_tree().create_timer(3.2).timeout
	if is_inside_tree() and not TransitionService.loading:
		_sleep_fx = 0.0   # route unbuilt in this release: wake back up here


func _doze(text: String) -> void:
	Overlay.toast(text, 4.0)
	_sleep_fx = 0.6
	await get_tree().create_timer(2.0).timeout
	if is_inside_tree():
		_sleep_fx = 0.0


func _take_food(p: Player, where: String) -> void:
	if withdrawn:
		Overlay.toast("Empty. Every shelf is bare.", 3.0)
		return
	if int(food[where]) <= 0:
		Overlay.toast("Nothing left for now.", 2.5)
		return
	food[where] = int(food[where]) - 1
	_restock[where] = 75.0
	var sugary := exposure > 600.0
	var names := ["Greasy Marshmallows", "a cold glass of milk", "a slice of birthday cake"] if where == "fridge" else ["Greasy Marshmallows", "a box of animal crackers", "a cup of fruit gummies"]
	var item: String = names[int(food[where]) % names.size()]
	p.heal(8.0 if sugary else 20.0)
	Overlay.toast("You eat %s.%s" % [item, " It tastes of almost nothing but sugar now." if sugary else " It is fresh and safe."], 3.5)


func _place_meal() -> void:
	var mk := kit("Meal")
	mk.cylinder(Vector3(6.4, 0.785, 6.75), 0.16, 0.02, "l974_porcelain", 18, false)
	mk.cylinder(Vector3(6.4, 0.81, 6.75), 0.1, 0.04, "l974_pinkwood", 12, false)
	mk.commit()
	_meal_mesh = mk.root
	_meal_it = add_interactable(Vector3(6.4, 0.85, 6.75), Vector3(0.4, 0.2, 0.4), "Eat the meal from your childhood", func(p: Player) -> void:
		p.heal(35.0)
		sanity = minf(100.0, sanity + 15.0)
		Overlay.toast("It is exactly how it used to taste.", 3.5)
		_meal_mesh.visible = false
		_meal_it.queue_free())


func _window(_p: Player, i: int) -> void:
	var tries: int = _window_tries.get(i, 0)
	_window_tries[i] = tries + 1
	if tries == 0:
		Overlay.toast("It does not open. Behind the glass is only a painting of outside. There is no door out, either.", 4.0)
	elif tries == 1:
		Overlay.toast("Trying again would mean breaking it. (Interact once more to smash the glass.)", 3.5)
	elif not house_damaged:
		house_damaged = true
		sound.play_at("crackle", {}, player.global_position + Vector3(0, 1.4, 0), -6.0, "[glass cracks]")
		_offend("You have damaged the house.")


func _offend(why: String) -> void:
	if withdrawn:
		return
	withdrawn = true
	kitty.withdraw()
	sanity = maxf(0.0, sanity - 40.0)
	food = {"fridge": 0, "pantry": 0}
	Overlay.toast(why + " Kitty no longer follows you. The kitchen is empty.", 5.0)
	Overlay.subtitle("[something in the house goes quiet and cold]", 4.0)


func _on_kitty_close() -> void:
	_rustle.volume_db = -14.0
	Overlay.subtitle("[a soft rustle of fabric — Kitty is standing right beside you]", 3.5)


# ----------------------------------------------------------------- runtime

func on_player_ready() -> void:
	Overlay.subtitle("[a foggy lullaby] [the smell of something sweet]", 5.0)
	Overlay.toast("You are still holding the little plush charm that was in your pocket when you no-clipped. Something cute brought you here.", 6.0)
	kitty.player = player
	if qa_fixture:
		qa_routes.append({"edge": "L974>EXT#2", "target": kitty.global_position,
			"note": "QA fixture: Kitty waits by her cat bed instead of stalking"})


func _exit_tree() -> void:
	for k in ["vignette"]:
		Overlay.set_screen_effect(k, 0.25)
	Overlay.set_screen_effect("desaturate", 0.0)
	Overlay.set_screen_effect("blackout", 0.0)


func level_process(delta: float) -> void:
	if player == null:
		return
	exposure += delta
	var p := player.global_position
	# Baker Miller pink: calming at first, then anxiety and sanity loss
	if exposure > 240.0:
		sanity = maxf(0.0, sanity - delta * 0.12)
		if not _anx_msg:
			_anx_msg = true
			Overlay.subtitle("[the pink walls feel closer than they did]", 4.0)
	elif exposure > 15.0 and not _calm_msg:
		_calm_msg = true
		Overlay.subtitle("[the soft pink is oddly soothing]", 3.5)
	var anx := 1.0 - sanity / 100.0
	var calm := 1.0 - clampf(exposure / 240.0, 0.0, 1.0)
	Overlay.set_screen_effect("vignette", 0.25 - 0.1 * calm + 0.45 * anx)
	Overlay.set_screen_effect("desaturate", 0.4 * anx)
	_music.pitch_scale = 1.0 + sin(exposure * 0.7) * 0.035 * anx
	Overlay.set_screen_effect("blackout", lerpf(0.0, 0.92, _sleep_fx) if _sleep_fx > 0.0 else 0.0)
	# food replaces itself (unless the house was damaged)
	for w in _restock.keys():
		if _restock[w] > 0.0:
			_restock[w] -= delta
			if _restock[w] <= 0.0 and not withdrawn:
				food[w] = mini(3, int(food[w]) + 1)
	# childhood-meal smell near the kitchen (mostly an olfactory hallucination)
	_smell_t -= delta
	if p.x > 7.0 and p.z > 4.2 and _smell_t <= 0.0:
		_smell_t = 120.0
		Overlay.subtitle("[the smell of a meal from your childhood]", 4.0)
	_memory_t -= delta
	if _memory_t <= 0.0:
		_memory_t = randf_range(80.0, 140.0)
		Overlay.subtitle("[a childhood memory surfaces — fuzzy, hard to hold]", 4.0)
	# aggression: shoving into Kitty at a sprint
	var kd := Vector2(p.x - kitty.global_position.x, p.z - kitty.global_position.z).length()
	if not withdrawn and not gifted and kd < 0.75 and Vector2(player.velocity.x, player.velocity.z).length() > 4.2:
		_offend("You shoved Kitty.")
	var hb: Interactable = kitty.get_meta("hitbox")
	hb.prompt = "Give Kitty your keepsake (the plush charm you carried here)" if keepsake and not gifted else ""
	_rustle.volume_db = lerpf(_rustle.volume_db, -24.0 if kitty.moving else -60.0, clampf(delta * 3.0, 0.0, 1.0))


## Level self-tests (QA): the rules the page states, checked on the live level.
func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "gift refused while Kitty is out of reach", "ok": player.global_position.distance_to(kitty.global_position) < 2.4 or not _gift_ok()})
	out.append({"what": "bed does not lead to 974.1 before DreamSleep is ready", "ok": not pc.ready_flag})
	out.append({"what": "no exterior door: every exit is the gift or the bed", "ok": exits.size() == 2})
	out.append({"what": "Kitty has no hostile state", "ok": not ("ATTACK" in KittyScript.State.keys())})
	return out


func _pose(pos: Vector3, pc_state: String) -> void:
	kitty.frozen = true
	var cam := Vector3(6.45, 1.6, 2.6) if pc_state != "" else Vector3(0.7, 1.3, 7.5)
	kitty.place_at(pos, cam - pos)
	if pc_state == "dream":
		pc.ready_flag = true
		pc.state = "dream"
		pc._render()
	await get_tree().process_frame
