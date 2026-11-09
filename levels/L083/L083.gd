extends LevelBase
## Level 83 "The Sunken Submarine" (Backrooms Wikidot rev 47, accessed 2026-11-04; Kitty Rika,
## CC BY-SA 3.0). Dossier: docs/canon/levels/L083.md.
##
## PLAN (read -> design):
## - SOURCE: the USS Ace of Spades (SSN 744), a nuclear submarine identical to a Los Angeles-class
##   boat except for windows on both sides, lying in a rocky underwater valley ~600 m down; the
##   interior is intact, controls are dead, lights and kitchen appliances work, the reactor runs.
##   -> an authored pressure hull (ADAPTATION: compressed to 84 m): forward compartment on three
##   decks joined by four ship's ladders (lower: auxiliary machinery and torpedo room; middle:
##   berthing, crew's mess, galley; upper: control room, radio, CO stateroom, sonar), the
##   shielded tunnel over the reactor, and a two-level engine room under the bare hull crown.
## - SOURCE: arrival is always in the berth or the canteen; the berth holds empty mattresses
##   free to use; the canteen holds only a leather couch, a few small metal tables, some chairs.
## - SOURCE: refrigerators with bottled water and food that restock -> stateful fridges.
## - SOURCE: windows on both sides show Pacific salmon, ragfish, Atka mackerel, rock formations
##   and flashes of movement in poor visibility -> shader-fogged rocks, fish, particles.
## - SOURCE: Kira's crumpled pirate drawings and post-it operating notes on appliances and
##   controls; her undamaged note on the OUTSIDE of the hull (readable through the glass).
## - SOURCE signature: the Great Observer (passive, herbivore) makes currents that creak and rock
##   the boat, rubs and drums on the hull, and presses its 20-inch eye to the windows
##   -> a timed cycle: groaning and rocking (crouch to hold on), rhythmic tapping, the eye at the
##   window nearest you, then it darts away. Never harmful.
## - SOURCE exit: undo the escape hatch at the top of the vessel and swim out -> escape trunk on
##   the upper deck, interact under the hatch (L083>L007#1). Crew signs point to it (they "will
##   show you the exit").
## - SOURCE entity: the Crew (20-100 friendly residents). ADAPTATION: shown by their traces
##   (made-up racks, notice board, trade table, signs), not as figures. No crew leader or rank.
## - ABSENT: drivable controls, hostile anything, an explorable seabed.

const Hull := preload("res://levels/L083/L083_hull.gd")
const Rooms := preload("res://levels/L083/L083_rooms.gd")
const Sea := preload("res://levels/L083/L083_sea.gd")

var H
var RM
var SEA
var reactor_light_pos := Vector3.ZERO
var hatch: ExitTrigger
var _band := -99
var _said := {}
var obs_phase := 0            # 0 idle, 1 currents, 2 tapping, 3 eye, 4 dart
var obs_t := 0.0
var obs_events := 0
var eye_window: Dictionary = {}
var eye_seen := false
var _roll := 0.0
var _arm_k := -1.0
var start_room := ""


func build() -> void:
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 160.0
	rules["kill_y"] = -40.0
	rules["reverb_room"] = 0.4
	rules["reverb_wet"] = 0.22
	indoor_env(Color(0.62, 0.66, 0.7), 0.1, Color(0.02, 0.025, 0.03), 0.01)
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.0, 0.004, 0.008)
	environment.glow_enabled = true
	environment.glow_intensity = 0.5
	environment.glow_bloom = 0.05
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.15
	Hull.materials()
	Rooms.materials()
	var k := kit("SubStructure")
	var d := kit("SubDressing")
	H = Hull.new(self, k, d)
	H.build()
	RM = Rooms.new(H, self, rng)
	RM.build()
	RM.finalize()
	k.commit()
	d.commit()
	SEA = Sea.new(self, rng)
	SEA.build()
	lights.setup(10, 1)
	lights.max_distance = 22.0
	_feed(1)
	var rl := OmniLight3D.new()
	rl.name = "ReactorGlow"
	rl.light_color = Color(1.0, 0.6, 0.25)
	rl.light_energy = 1.6
	rl.omni_range = 6.0
	rl.position = reactor_light_pos
	add_child(rl)
	_interactions()
	_sounds()
	# arrivals: always in the berth or the canteen (per seed)
	var berth := Vector3(-2.8, Hull.Y1 + 0.05, 9.0)
	var mess := Vector3(0.6, Hull.Y1 + 0.05, 22.6)
	start_room = "berth" if (level_seed % 2) == 0 else "canteen"
	if start_room == "berth":
		add_arrival("start", berth, 180.0)
	else:
		add_arrival("start", mess, 120.0)
	add_arrival("from_L007", Vector3(-2.8, Hull.Y1 + 0.05, 13.2), 180.0)
	hatch = add_exit("L083>L007#1", "interact", Vector3(0, 8.7, 1.9), Vector3(1.5, 2.4, 1.5),
		"Undo the escape hatch and swim out into the ocean")
	if hatch:
		hatch.fired.connect(func(_e: String) -> void: Overlay.glitch(0.8))
	add_landmark("Berthing", Vector3(-2.8, Hull.Y1, 11.0))
	add_landmark("Crew's mess (canteen)", Vector3(0, Hull.Y1, 25.0))
	add_landmark("Galley refrigerators", Vector3(-2.6, Hull.Y1, 39.0))
	add_landmark("Control room", Vector3(0, Hull.Y2, 23.0))
	add_landmark("Escape trunk", Vector3(0, Hull.TRUNK_FLOOR, 1.9))
	add_landmark("Reactor tunnel", Vector3(0, Hull.Y1, -7.0))
	add_landmark("Engine room", Vector3(0, Hull.Y0, -30.0))
	add_landmark("Torpedo room", Vector3(0, Hull.Y0, 25.0))
	obs_t = rng.randf_range(35.0, 70.0)
	_shots()


# --------------------------------------------------------------- light pool per deck

func _band_of(p: Vector3) -> int:
	if p.z < Hull.RX + 0.5:
		return 10     # engine room: lower flats and catwalks are one open space
	if p.y < 2.5:
		return 0
	if p.y < 5.2:
		return 1
	return 2


func _feed(b: int) -> void:
	if b == _band:
		return
	_band = b
	lights.clear_anchors()
	for lp in H.lamps:
		var lb: int = lp[4]
		var lpos: Vector3 = lp[0]
		var ok := false
		if b == 10:
			ok = lpos.z < Hull.RX + 1.0 or (lb == 1 and lpos.z < 0.5)
		elif b == 2:
			ok = (lb == 2 or lb == 3) and lpos.z > -0.5
		else:
			ok = lb == b and lpos.z > Hull.RX + 0.5
		if ok:
			lights.add_anchor(lpos, lp[1], lp[2], lp[3], 0.02 if lb != 3 else 0.0)


# --------------------------------------------------------------- interactions

func _interactions() -> void:
	for n in RM.notes:
		add_note(n[0], n[1], n[2], n[3], Vector3(0.5, 0.5, 0.5), false)
	for i in RM.fridges.size():
		var f: Dictionary = RM.fridges[i]
		add_interactable(f["pos"], Vector3(0.9, 1.6, 0.4), "Take bottled water and a sandwich", func(_p: Player) -> void: take_from_fridge(i))
	add_interactable(RM.helm_pos + Vector3(0, 1.0, 0.6), Vector3(2.4, 1.0, 0.8), "Try the helm",
		func(_p: Player) -> void: Overlay.subtitle("[the yoke moves; nothing answers. The controls are dead - only the lights, the galley and the reactor still work]", 4.5))
	add_interactable(RM.scope_pos + Vector3(0, 1.45, 0.25), Vector3(0.6, 0.5, 0.6), "Look through the periscope",
		func(_p: Player) -> void: _periscope())


func take_from_fridge(i: int) -> void:
	var f: Dictionary = RM.fridges[i]
	if not f["full"]:
		Overlay.subtitle("[the shelves are bare. They never stay that way for long]", 3.0)
		return
	f["full"] = false
	f["t"] = rng.randf_range(40.0, 75.0)
	f["taken"] = int(f["taken"]) + 1
	var root: Node3D = f["root"]
	if is_instance_valid(root):
		root.visible = false
	if player and is_instance_valid(player):
		player.heal(15.0)
	sound.play_at("ui", {"kind": "click"}, f["pos"], -10.0, "[cold bottled water, a sandwich, some fruit - the shelf is empty now]")


func _restock(delta: float) -> void:
	for f in RM.fridges:
		if f["full"]:
			continue
		f["t"] = float(f["t"]) - delta
		if float(f["t"]) <= 0.0:
			restock(f)


func restock(f: Dictionary) -> void:
	f["full"] = true
	var root: Node3D = f["root"]
	if is_instance_valid(root):
		root.visible = true
	if player and is_instance_valid(player) and player.global_position.distance_to(f["pos"]) < 8.0 and not SessionState.is_qa():
		Overlay.subtitle("[the refrigerator hums. It is full again; you never saw it happen]", 3.5)


func _periscope() -> void:
	Overlay.glitch(0.25)
	Overlay.subtitle("[black water. A paler smear of rock. Something moves past the glass, quick and huge, and is gone]", 5.0)


# --------------------------------------------------------------- the Great Observer

func _observer(delta: float) -> void:
	obs_t -= delta
	match obs_phase:
		0:
			if obs_t <= 0.0:
				start_observer()
		1:
			_roll = sin(Time.get_ticks_msec() * 0.0021) * 0.045 * clampf(obs_t / 2.0, 0.0, 1.0)
			if player and is_instance_valid(player) and not player.crouching and player.is_on_floor():
				player.velocity += Vector3(sin(Time.get_ticks_msec() * 0.0017), 0, 0) * delta * 2.2
			if obs_t <= 0.0:
				_roll = 0.0
				obs_phase = 2
				obs_t = 5.0
				var p := _ppos()
				sound.play_at("knock", {"hits": 4}, p + Vector3(4.4 if p.x > 0 else -4.4, 1.0, 1.5), -4.0, "[something taps the hull, slow and rhythmic, like a drum]")
		2:
			if obs_t <= 0.0:
				obs_phase = 3
				obs_t = 7.0
				eye_window = _nearest_window()
				_arm_k = 0.0
				SEA.show_eye(eye_window)
		3:
			if _arm_k >= 0.0:
				_arm_k += delta * 0.6
				SEA.sweep_arm(eye_window, _arm_k)
				if _arm_k > 1.0:
					_arm_k = -1.0
			if not eye_seen and _looking_at((eye_window["pos"] as Vector3)):
				eye_seen = true
				if not SessionState.is_qa():
					Overlay.subtitle("[an eye, as long as your forearm, pressed to the glass. It is watching. Stay calm. It simply observes]", 5.0)
			if obs_t <= 0.0:
				obs_phase = 4
				obs_t = 0.5
				sound.play_at("splash", {}, eye_window["pos"], -12.0, "[a surge of water past the window]")
		4:
			SEA.eye_dart(delta, eye_window["n"])
			if obs_t <= 0.0:
				SEA.hide_eye()
				obs_phase = 0
				eye_seen = false
				obs_t = rng.randf_range(70.0, 140.0)
	if player and is_instance_valid(player):
		player.head.rotation.z = lerpf(player.head.rotation.z, _roll, 0.1)


func start_observer() -> void:
	obs_events += 1
	obs_phase = 1
	obs_t = 6.0
	var p := _ppos()
	sound.play_at("creak", {"freq": 48.0}, p + Vector3(0, 2.0, 3.0), -2.0, "[the hull groans; the whole boat rocks as something huge swims past. Crouch and hold on]")
	Overlay.glitch(0.15)


func _ppos() -> Vector3:
	if player and is_instance_valid(player):
		return player.global_position
	return Vector3(0, Hull.Y1, 25.0)


func _nearest_window() -> Dictionary:
	var p := _ppos()
	var best: Dictionary = H.windows[0]
	var bd := INF
	for w in H.windows:
		var dd := p.distance_to(w["inner"])
		if dd < bd:
			bd = dd
			best = w
	return best


func _looking_at(target: Vector3) -> bool:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return false
	var to := (target - cam.global_position)
	return to.length() < 9.0 and (-cam.global_transform.basis.z).dot(to.normalized()) > 0.85


# --------------------------------------------------------------- sound, frame

func _sounds() -> void:
	sound.bed("room_tone", {"cutoff": 170.0, "rumble": 0.3, "seconds": 6.0}, -22.0)
	sound.bed("water_bed", {"bright": 0.04, "seconds": 8.0}, -36.0)
	sound.emitter("transformer", Vector3(0, 2.0, -7.0), {"base": 58.0, "seconds": 4.0}, -16.0, 12.0)
	sound.emitter("transformer", Vector3(0, 1.5, -30.0), {"base": 44.0, "seconds": 4.0}, -20.0, 18.0)
	sound.emitter("room_tone", Vector3(0, 2.0, -34.0), {"cutoff": 320.0, "rumble": 0.6, "seconds": 5.0}, -18.0, 16.0)
	sound.emitter("fluorescent_hum", Vector3(-2.6, Hull.Y1 + 1.0, 39.2), {"base": 100.0, "seconds": 3.0}, -26.0, 6.0)
	sound.emitter("fluorescent_hum", Vector3(0, Hull.Y2 + 1.8, 23.0), {"base": 120.0, "seconds": 3.0}, -32.0, 8.0)
	sound.oneshot("creak", {"freq": 70.0}, 22.0, 50.0, 10.0, "[the hull creaks under six hundred metres of water]", -20.0)
	sound.oneshot("drip", {"freq": 900.0}, 9.0, 20.0, 6.0, "", -26.0)
	sound.oneshot("pipe_clank", {"f": 160.0}, 25.0, 60.0, 10.0, "[a pipe ticks as it cools]", -24.0)


func on_player_ready() -> void:
	if SessionState.is_qa():
		return
	if TransitionService.pending_arrival == "from_L007":
		Overlay.subtitle("[you wake in a narrow rack. Steel, fluorescent light, the hum of a reactor somewhere aft]", 5.0)
	else:
		Overlay.subtitle("[a submarine. Warm air, humming lights - and black water behind the windows]", 4.0)


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_feed(_band_of(player.global_position))
	_restock(delta)
	if not SessionState.is_qa():
		_observer(delta)
	var p := player.global_position
	if not _said.has("trunk") and p.y > Hull.TRUNK_FLOOR - 0.2 and not SessionState.is_qa():
		_said["trunk"] = true
		Overlay.subtitle("[the hatch is right above you. Beyond it, six hundred metres of cold black water]", 4.0)


# --------------------------------------------------------------- QA

func _shots() -> void:
	add_shot("canteen", Vector3(2.6, Hull.Y1 + 1.62, 19.7), Vector3(-3.0, Hull.Y1 + 0.9, 27.0), {"flashlight": false})
	add_shot("berth", Vector3(-2.75, Hull.Y1 + 1.62, 7.7), Vector3(-2.9, Hull.Y1 + 1.0, 17.6), {"flashlight": false})
	add_shot("control_room", Vector3(1.6, Hull.Y2 + 1.62, 14.3), Vector3(-1.2, Hull.Y2 + 0.95, 30.0), {"flashlight": false})
	add_shot("engine_room", Vector3(-3.3, Hull.Y1 + 1.62, -19.4), Vector3(1.0, 1.2, -38.0), {"flashlight": false})
	add_shot("observer_eye", Vector3(3.15, Hull.Y1 + 1.42, 21.45), Vector3(4.9, Hull.Y1 + 1.4, 21.6), {"flashlight": false, "prepare": _prep_eye})
	add_shot("torpedo_room", Vector3(0.4, 1.62, 11.0), Vector3(-0.3, 0.9, 39.0), {"flashlight": false})
	add_shot("galley", Vector3(-1.2, Hull.Y1 + 1.62, 31.6), Vector3(-2.6, Hull.Y1 + 1.0, 39.5), {"flashlight": false})


func _prep_eye() -> void:
	for w in H.windows:
		if absf((w["pos"] as Vector3).z - 21.6) < 0.1 and (w["n"] as Vector3).x > 0.0 and w["deck"] == 1:
			eye_window = w
	SEA.show_eye(eye_window)
	for i in 3:
		await get_tree().process_frame


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	var space := get_world_3d().direct_space_state
	var decks := 0
	for y in [Hull.Y0, Hull.Y1, Hull.Y2]:
		var q := PhysicsRayQueryParameters3D.create(Vector3(0.0, y + 1.0, 25.0), Vector3(0.0, y - 0.5, 25.0), 1)
		var hit := space.intersect_ray(q)
		if not hit.is_empty() and absf((hit["position"] as Vector3).y - y) < 0.1:
			decks += 1
	out.append({"what": "three walkable decks in the forward compartment", "ok": decks == 3, "detail": decks})
	var port := 0
	var stbd := 0
	for w in H.windows:
		if (w["n"] as Vector3).x < 0.0:
			port += 1
		else:
			stbd += 1
	out.append({"what": "windows on both sides of the vessel", "ok": port >= 4 and stbd >= 4, "detail": [port, stbd]})
	out.append({"what": "escape hatch at the top of the vessel", "ok": hatch != null and hatch.global_position.y > Hull.R + Hull.HC - 0.5})
	out.append({"what": "arrival is in the berth or the canteen", "ok": start_room in ["berth", "canteen"] and arrivals.has("from_L007")})
	take_from_fridge(0)
	var f: Dictionary = RM.fridges[0]
	var emptied: bool = not f["full"] and not (f["root"] as Node3D).visible
	restock(f)
	out.append({"what": "a refrigerator empties when used and restocks", "ok": emptied and f["full"] and (f["root"] as Node3D).visible})
	eye_window = _nearest_window()
	start_observer()
	var ph := obs_phase
	obs_phase = 2
	obs_t = 0.0
	_observer(0.016)
	var eye_ok: bool = obs_phase == 3 and SEA.eye.visible and (SEA.eye.global_position as Vector3).distance_to(eye_window["pos"]) < 0.5
	SEA.hide_eye()
	obs_phase = 0
	_roll = 0.0
	if player and is_instance_valid(player):
		player.head.rotation.z = 0.0
	out.append({"what": "the Great Observer cycle rocks the boat and presses its eye to a window", "ok": ph == 1 and eye_ok})
	return out
