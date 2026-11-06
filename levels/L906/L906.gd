extends LevelBase
## Level 906 — "The Cygnus Archive" (Backrooms Wikidot rev 135, accessed
## 2026-11-04; cite: "Level 906 - "The Cygnus Archive"" by SnomWriting, from the
## Backrooms Wiki, CC BY-SA 3.0). Dossier: docs/canon/levels/L906.md.
##
## A massive, seemingly endless library ruled by its host, Blanche. You arrive in
## her office at the centre (page: the entry point for all visitors); four halls
## of shelving run out from the crossing without end (streamed segments around
## the player; the playable world is a finite streaming window). Systems:
##  - etiquette: polite guests get tea, a room, and a door to a safe level of their
##    choosing; rude ones are warned, called out, lectured; hostile ones are held
##    by telekinesis and then sent back where they came from (L906_hosts.gd);
##  - the ceiling recedes as you climb; signed books spawn in and clip out; Light
##    Guides flicker and vanish; recording equipment fails (L906_life.gd);
##  - floating bookcases reached by wooden ladders, a gallery level, a marble
##    stair, guest rooms on the gallery (L906_arm.gd, L906_core.gd, L906_rooms.gd).
## No hazards. "Witnessing the Beyond" exists only as a rumour on a guest's note.

const K := preload("res://levels/L906/L906_kit.gd")
const Arm := preload("res://levels/L906/L906_arm.gd")
const Core := preload("res://levels/L906/L906_core.gd")
const Rooms := preload("res://levels/L906/L906_rooms.gd")
const Hosts := preload("res://levels/L906/L906_hosts.gd")
const Life := preload("res://levels/L906/L906_life.gd")
const START := Vector3(2.9, 0.05, 6.7)
const START_YAW := 48.0
const STREAM_R := 98.0

var arm: RefCounted
var core: RefCounted
var rooms: RefCounted
var hosts: RefCounted
var life: RefCounted
var segs: Dictionary = {}       # Vector2i(arm, index) -> meta
var exit_leave: ExitTrigger
var exit_expel: ExitTrigger
var qa_fixture := false
var _stream_t := 0.0


func build() -> void:
	qa_fixture = SessionState.is_qa()
	rules["flashlight"] = "allowed"
	rules["reverb_room"] = 0.82
	rules["reverb_wet"] = 0.26
	rules["view_distance"] = 400.0
	indoor_env(Color(1.0, 0.8, 0.6), 0.2, Color(0.075, 0.05, 0.03), 0.0)
	environment.background_color = Color(0.06, 0.04, 0.024)
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_DEPTH
	environment.fog_light_color = Color(0.06, 0.04, 0.024)
	environment.fog_depth_begin = 20.0
	environment.fog_depth_end = 100.0
	environment.fog_depth_curve = 1.4
	environment.fog_density = 1.0
	environment.fog_sky_affect = 1.0
	environment.tonemap_exposure = 1.08
	environment.glow_intensity = 0.55
	environment.glow_bloom = 0.08
	environment.glow_hdr_threshold = 0.95
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.06
	environment.adjustment_contrast = 1.05
	K.materials()
	lights.setup(14, 1)
	lights.max_distance = 44.0
	core = Core.new(self)
	core.build()
	rooms = Rooms.new(self)
	rooms.build_office()
	rooms.build_tea_room()
	rooms.build_guest_room("plain")
	hosts = Hosts.new(self)
	hosts.setup()
	life = Life.new(self)
	life.setup()
	life.add_spots("core", core.spots + [Vector3(1.0, 0.8, 8.5), Vector3(-1.2, 0.01, 6.6), Vector3(5.6, 0.01, -1.0),
		Vector3(-7.5, 0.01, 3.0), Vector3(14.8, 0.78, 16.0), Vector3(-0.8, 0.01, 11.0)])
	arm = Arm.new(self)
	_stream(START, true)
	# the leave door (opened only when Blanche guides you) and the expulsion
	exit_leave = make_exit("L906>EXT#1", "walk_in", Vector3(0, 1.0, -2.2), Vector3(1.5, 2.0, 1.4), "", core.door_node)
	exit_leave.enabled = false
	exit_expel = add_exit("L906>EXT#2", "condition", Vector3(0, 20.0, 0), Vector3(900, 240, 900))
	exit_expel.condition = func(): return hosts.expelled and hosts.held <= 0.0
	add_arrival("start", START, START_YAW)
	if qa_fixture:
		# QA FIXTURE: the guest has already asked politely; the door is open onto the
		# first safe built level, so the walker bot can leave through it.
		var safe: Array = hosts.safe_levels()
		if not safe.is_empty():
			hosts.guide(safe[0])
			hosts.place("office")
	_audio()
	add_shot("office", Vector3(2.6, 1.62, 6.6), Vector3(-1.6, 1.25, 3.6))
	add_shot("long_room", Vector3(4.2, 6.1, -18.3), Vector3(-1.0, 3.2, -62.0))
	add_landmark("Blanche's office (entry point)", START)
	add_landmark("Tea Room", Rooms.TEA)
	add_landmark("Guide door", core.door_node.global_position)


func _audio() -> void:
	sound.bed("room_tone", {"cutoff": 120.0, "rumble": 0.15}, -26.0)
	sound.bed("pad", {"root": 82.4, "chord": [0, 7, 12], "bright": 0.05, "seconds": 10.0}, -40.0)
	sound.emitter("crackle", Vector3(0, 12.0, 1.5), {}, -30.0, 22.0)
	sound.oneshot("creak", {"freq": 95.0}, 18.0, 46.0, 14.0, "[a ladder creaks somewhere in the stacks]", -24.0)
	sound.oneshot("whisper", {"seconds": 0.7}, 12.0, 30.0, 10.0, "[a page turns, though nobody is near]", -26.0)
	sound.oneshot("knock", {"hits": 1}, 50.0, 120.0, 20.0, "[a heavy book closes, far off]", -24.0)


# ----------------------------------------------------------- streaming halls

func _stream(p: Vector3, all_now: bool) -> void:
	var built := 0
	var want := {}
	for a in 4:
		var bas := Arm.arm_basis(a)
		var u := p.dot(bas.z)
		var v := p.dot(bas.x)
		if absf(v) >= STREAM_R:
			continue
		var reach := sqrt(STREAM_R * STREAM_R - v * v)
		var i0 := maxi(0, int(floor((u - reach - Arm.START) / Arm.SEG)))
		var i1 := int(floor((u + reach - Arm.START) / Arm.SEG))
		for i in range(i0, i1 + 1):
			want[Vector2i(a, i)] = true
	for key in want.keys():
		if segs.has(key):
			continue
		if not all_now and built >= 1:
			continue
		var node := Node3D.new()
		node.name = "Hall_%d_%d" % [key.x, key.y]
		add_child(node)
		var meta: Dictionary = arm.build(key.x, key.y, node)
		meta["node"] = node
		segs[key] = meta
		life.add_spots(meta["group"], meta["spots"])
		built += 1
	for key in segs.keys():
		if want.has(key):
			continue
		var c := Arm.seg_center(key.x, key.y)
		if Vector2(c.x - p.x, c.z - p.z).length() < STREAM_R + 24.0:
			continue
		var m: Dictionary = segs[key]
		lights.remove_group(m["group"])
		life.drop_spots(m["group"])
		(m["node"] as Node).queue_free()
		segs.erase(key)


# ------------------------------------------------------------------ runtime

func on_player_ready() -> void:
	if SessionState.is_story():
		checkpoint(str(spawn_report.get("used_arrival", "start")))
	if qa_fixture:
		qa_routes.append({"edge": "L906>EXT#1", "target": core.door_node.global_position, "note": "office -> crossing -> the open guide door in the NW corner"})
		return
	Overlay.subtitle("[your fingertip is still on the ink of a signature] [old paper, candle smoke, perfect quiet]", 5.0)
	await get_tree().create_timer(2.2).timeout
	if is_instance_valid(self) and not hosts.greeted:
		Overlay.subtitle("Blanche: \"Oh! A guest. It is a pleasure to meet you.\"", 4.5)
	if Settings.get_value("camcorder"):
		Overlay.toast("Your recorder's screen fills with noise, then shows only an error. Nothing records in here.", 5.0)


func level_process(delta: float) -> void:
	if player == null:
		return
	_stream_t -= delta
	if _stream_t <= 0.0:
		_stream_t = 0.25
		_stream(player.global_position, false)
	hosts.process(delta)
	life.process(delta)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("screenshot") and SessionState.in_gameplay and not SessionState.is_qa():
		get_viewport().set_input_as_handled()
		life.block_screenshot()


func _exit_tree() -> void:
	if hosts:
		hosts.free_ui()
	Overlay.set_screen_effect("desaturate", 0.0)
	Overlay.set_screen_effect("vignette", 0.25)


# ---------------------------------------------------------------------- QA

func qa_capture_plan() -> Array:
	var plan: Array = qa_shots.duplicate()
	# the long-room still looks down the north hall towards a floating bookcase
	var tops: Array = []
	for key in segs:
		var m: Dictionary = segs[key]
		if m.has("float") and key.x == 0 and (m["float"]["top"] as Vector3).z < -30.0:
			tops.append(m["float"]["top"])
	tops.sort_custom(func(p, q): return p.z > q.z)
	if not tops.is_empty():
		var top: Vector3 = tops[0]
		for s in plan:
			if s["name"] == "long_room":
				s["pos"] = Vector3(top.x - 1.6, 1.62, top.z + 14.0)
				s["target"] = Vector3(top.x - 0.2, top.y - 0.4, top.z - 5.0)
		if OS.get_environment("L906_ALL_SHOTS") != "":
			plan.append({"name": "x_float", "pos": Vector3(top.x + 5.2, 1.3, top.z + 3.5), "target": top + Vector3(0, -3.2, 0)})
	if OS.get_environment("L906_ALL_SHOTS") == "":
		return plan
	plan.append({"name": "x_ceiling", "pos": Vector3(-2.0, 1.62, -24.0), "target": Vector3(1.0, 30.0, -50.0)})
	plan.append({"name": "x_tea", "pos": Vector3(12.6, 1.62, 13.2), "target": Vector3(17.0, 1.0, 17.5)})
	plan.append({"name": "x_crossing", "pos": Vector3(-9.0, 1.62, 9.0), "target": Vector3(0.0, 3.0, -8.0)})
	plan.append({"name": "x_room", "pos": Vector3(14.6, 6.12, 14.5), "target": Vector3(18.0, 5.0, 17.5)})
	plan.append({"name": "x_door", "pos": Vector3(-5.0, 1.62, -5.0), "target": Vector3(-12.4, 1.3, -12.4)})
	return plan


func _ray_y(x: float, z: float, from_y: float) -> float:
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, from_y, z), Vector3(x, from_y - 12.0, z), 1))
	return float((hit["position"] as Vector3).y) if not hit.is_empty() else -999.0


func _qa_walk(from: Vector3, dir: Vector3, secs: float) -> float:
	player.global_position = from
	player.velocity = Vector3.ZERO
	player.rotation.y = atan2(-dir.x, -dir.z)
	player.qa_active = true
	player.qa_input = Vector2(0, 1)
	for i in int(secs * 60.0):
		await get_tree().physics_frame
	player.qa_input = Vector2.ZERO
	player.qa_active = false
	return player.global_position.y


func qa_self_test() -> Array:
	var out: Array = []
	var pp := player.global_position
	# two walkable heights in a hall, plus the floating bookcase decks
	var gy := _ray_y(9.6, -26.0 - 2.0, 7.0)
	out.append({"what": "north hall: gallery deck at 4.5 m over the floor", "ok": absf(gy - K.GAL) < 0.05 and absf(_ray_y(0.0, -30.0, 1.5)) < 0.05, "detail": gy})
	var floats := 0
	var ladders := 0
	for key in segs:
		var m: Dictionary = segs[key]
		if m.has("float"):
			var top: Vector3 = m["float"]["top"]
			if absf(_ray_y(top.x, top.z, top.y + 1.0) - top.y) < 0.06 and top.y > 4.5:
				floats += 1
	for l in get_tree().get_nodes_in_group("ladder"):
		ladders += 1
	out.append({"what": "floating bookcases with walkable tops, reached by ladders", "ok": floats >= 2 and ladders >= floats, "detail": [floats, ladders]})
	# climb a floating bookcase's ladder, and the marble stair to the gallery
	var climb := {}
	for key in segs:
		var m: Dictionary = segs[key]
		if m.has("float"):
			climb = m["float"]
			break
	if not climb.is_empty():
		var top: Vector3 = climb["top"]
		var face: Vector3 = climb["face"]
		var y_end := await _qa_walk(climb["foot"], face, 7.0)
		out.append({"what": "a wooden ladder climbs onto a floating bookcase", "ok": absf(y_end - top.y) < 0.3, "detail": [y_end, top.y]})
	var y_st := await _qa_walk(Vector3(0.0, 0.05, -1.8), Vector3(0, 0, -1), 6.0)
	out.append({"what": "the marble stair reaches the north gallery", "ok": absf(y_st - K.GAL) < 0.2 and player.global_position.z < -11.0, "detail": [y_st, player.global_position.z]})
	player.global_position = pp
	# receding ceiling
	var d0: float = life.ceiling_target(1.62) - 1.62
	var d1: float = life.ceiling_target(8.4) - 8.4
	out.append({"what": "ceiling recedes as you climb (gap grows with height)", "ok": d1 > d0 + 10.0 and d0 > 40.0, "detail": [d0, d1]})
	# safe destinations and the polite exit (QA fixture already guided)
	var safe: Array = hosts.safe_levels()
	var unsafe_ok := not safe.has("L008") and not safe.has("L188") and not safe.has("L906")
	out.append({"what": "Blanche offers only built, safe levels", "ok": not safe.is_empty() and unsafe_ok, "detail": safe})
	out.append({"what": "asked politely: guide door open, leave edge routed to the chosen level", "ok": exit_leave.enabled and absf(core.door_pivot.rotation.y) > 1.0 and str(TransitionService.get_edge("L906>EXT#1").get("to", "")) == hosts.guide_to, "detail": hosts.guide_to})
	# etiquette ladder: warn, call out, lecture, apology; hold; expulsion
	hosts.impolite_act("qa")
	hosts.impolite_act("qa")
	hosts.impolite_act("qa")
	var ladder_ok: bool = hosts.lectured and hosts.hostile == 0 and not hosts.expelled and hosts.events.has("lecture")
	hosts.apologise()
	out.append({"what": "rudeness: warned, called out, lectured; an apology clears it", "ok": ladder_ok and hosts.impolite == 0, "detail": hosts.events})
	hosts.hostile_act("qa")
	var held_ok: bool = player.frozen and hosts.held > 0.0 and not hosts.expelled
	for i in 420:
		await get_tree().process_frame
		if hosts.held <= 0.0:
			break
	out.append({"what": "hostility: immobilised by telekinesis, then released", "ok": held_ok and not player.frozen, "detail": hosts.held})
	TransitionService.qa_log.clear()
	hosts.hostile_act("qa again")
	var fired := ""
	for i in 300:
		await get_tree().physics_frame
		if not TransitionService.qa_log.is_empty():
			fired = str(TransitionService.qa_log[0].get("id", "")) + ">" + str(TransitionService.qa_log[0].get("to", ""))
			break
	out.append({"what": "continued hostility: teleported out (EXT#2) to a safe level", "ok": fired.begins_with("L906>EXT#2>") and safe.has(fired.get_slice(">", 2)), "detail": fired})
	hosts.expelled = false
	hosts.hostile = 0
	player.frozen = false
	player.global_position = pp
	# books spawn in and clip out, all signed
	var before: int = life.spawned
	var a: Dictionary = life.spawn_item(pp + Vector3(1.0, 0.0, 0.0))
	var b: Dictionary = life.spawn_item(pp + Vector3(-1.0, 0.0, 0.0))
	var signed: bool = not a.is_empty() and a["signed"] and str(a["text"]).contains("Blanche") and not b.is_empty()
	life.clip_item(a)
	out.append({"what": "loose books spawn in and clip out, each signed by Blanche", "ok": life.spawned == before + 2 and life.clipped >= 1 and signed, "detail": [life.spawned, life.clipped]})
	# tea, the guest room that reshapes, Light Guides, recorder
	hosts.go_tea()
	var tea_ok: bool = hosts.in_tea and player.frozen and hosts.blanche.global_position.distance_to(Rooms.TEA) < 1.5
	hosts.end_tea()
	out.append({"what": "tea with Blanche in the Tea Room, then you stand up rested", "ok": tea_ok and not player.frozen and hosts.tea_count == 1, "detail": hosts.tea_count})
	hosts.ask_room()
	var s1: String = rooms.room_style
	hosts.read_count = 4
	life.reshape_room(true)
	out.append({"what": "the guest room reshapes to suit the guest", "ok": s1 == "tea" and rooms.room_style == "study", "detail": [s1, rooms.room_style]})
	out.append({"what": "Light Guides drift through the level", "ok": life.guides.size() == 4, "detail": life.guides.size()})
	out.append({"what": "recording equipment shows an error instead of a timecode", "ok": life.recorder_text().contains("REC ERR") or life.recorder_text().contains("CANNOT RECORD")})
	player.global_position = pp
	return out
