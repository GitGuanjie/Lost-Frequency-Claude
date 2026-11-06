extends LevelBase
## Level 289 — "Overflow" (Backrooms Wikidot rev 22, accessed 2026-11-04;
## cite: Stretchsterz, CC BY-SA 3.0). Dossier: docs/canon/levels/L289.md.
## The page is a purged M.E.G. entry whose only content is Event Log 1237
## (offset 1). Everything below maps to that log or is labelled ADAPTATION in
## level.json:
##   flooded basement, waist-high murky foul water (one explorer guessed Almond
##   Water; we never say it is), scaffolding everywhere, badly built, dark   SOURCE
##   a base radio voice heard in the water                                  SOURCE
##   an undocumented entity appears out of nowhere up ahead, crosses the dark
##   at incredible speed and stops dead (no momentum) in front of its target;
##   the target hears screaming that burns, nobody else hears anything, then
##   is carried backwards at the same speed "as if time had rewound" and is
##   found on Level 287 (edge L289>L287#2, ONE-WAY)                         SOURCE
##   the team's temporary hideout (checkpoint)                              SOURCE
##   the only exit leads to Level 14444444-<corrupted> which leads back to
##   Level 289 (edge L289>EXT#1, loops here)                                SOURCE
## World: ChunkWorld streams 16 m basement chunks (finite streaming window).

const Kit := preload("res://levels/L289/L289_kit.gd")
const Geo := preload("res://levels/L289/L289_geo.gd")
const Fx := preload("res://levels/L289/L289_fx.gd")
const CS := Kit.CS
const SURF := Kit.SURF
const START := Vector3(6.0, 0.05, 12.0)
const RADIO := Vector3(4.6, 0.08, 9.6)
const HIDEOUT := Rect2(9.2, 1.2, 5.6, 3.8)
const SIGHT_S := 2.6
const RUSH_S := 0.22
const SCREAM_S := 3.4
const REWIND_SPEED := 24.0

var geo: Geo
var world: ChunkWorld
var qa_fixture := false
var stair_key := Vector2i(1, 0)
var stair_door := Vector3.ZERO
var stair_arrival := Vector3.ZERO
var loops := 0
var level_t := 0.0
var enc_state := "dormant"      # dormant, sighted, rush, scream, rewind, relocate, gone
var enc_t := 0.0
var enc_radius := 65.0
var enc_from := Vector3.ZERO
var enc_to := Vector3.ZERO
var enc_node: MeshInstance3D
var enc_mat: ShaderMaterial
var trail := PackedVector3Array()
var relocated := false
var rewind_from := Vector3.ZERO
var _enc_check := 0.0
var _rw_i := 0
var _red := 0.0
var _pitch0 := 0.0
var _scream: AudioStreamPlayer
var _whoosh: AudioStreamPlayer
var _wade: AudioStreamPlayer
var _beds: Array = []
var _bed_db: Array = []
var _wade_said := false
var _hideout_done := false
var _radio_t := 6.0
var _radio_voice: AudioStreamPlayer3D
var _radio_lines: Array = []
var _radio_line_t := 0.0
var _arrive_fx := 0.0
var _relocate_exit: ExitTrigger


func build() -> void:
	qa_fixture = SessionState.is_qa()
	var has_light := not SessionState.is_story() or SaveService.item_count("flashlight") > 0
	rules["flashlight"] = "allowed" if has_light else "none"
	rules["view_distance"] = 90.0
	rules["reverb_room"] = 0.74
	rules["reverb_wet"] = 0.3
	loops = int(SaveService.flag(stable_id, "loops", 0))
	indoor_env(Color(0.42, 0.47, 0.45), 0.07, Color(0.05, 0.055, 0.038), 0.05)
	environment.tonemap_exposure = 1.2
	environment.glow_intensity = 0.5
	environment.glow_bloom = 0.08
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.82
	environment.adjustment_contrast = 1.08
	Kit.materials()
	geo = Geo.new(self)
	lights.setup(10, 1)
	lights.max_distance = 34.0
	if not qa_fixture:
		var ring: Array = []
		for z in range(-3, 4):
			for x in range(-3, 4):
				if maxi(absi(x), absi(z)) == 3:
					ring.append(Vector2i(x, z))
		stair_key = ring[absi(hash([level_seed, "stair"])) % ring.size()]
	enc_radius = 58.0 + float(absi(hash([level_seed, "enc"])) % 22)
	var so := Vector3(stair_key.x * CS, 0, stair_key.y * CS)
	stair_door = so + Vector3(10.6, Kit.STAIR_Y, 3.15)
	stair_arrival = so + Vector3(10.6, Kit.STAIR_Y + 0.05, 4.7)
	world = ChunkWorld.new()
	world.name = "Chunks"
	world.chunk_size = CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _chunk
	add_child(world)
	world.chunk_unloaded.connect(func(k): lights.remove_group("%d,%d" % [k.x, k.y]))
	add_arrival("start", START, -50.0)
	add_arrival("from_L019", Vector3(4.0, 0.05, 14.45), 0.0)
	add_arrival("from_L013", Vector3(0.95, 0.05, 4.0), -90.0)
	add_arrival("from_L289", stair_arrival, 180.0)
	var spawn := START
	var cp: Dictionary = TransitionService.pending_restore
	if cp.get("level", "") == stable_id and cp.get("pos") is Array and (cp["pos"] as Array).size() == 3:
		spawn = Vector3(cp["pos"][0], cp["pos"][1], cp["pos"][2])
	elif arrivals.has(TransitionService.pending_arrival):
		spawn = (arrivals[TransitionService.pending_arrival] as Transform3D).origin
	world.build_around(START if qa_fixture else spawn, 2)
	_props_authored()
	_audio()
	enc_mat = Fx.entity_material()
	enc_node = MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.9, 2.1)
	enc_node.mesh = qm
	enc_node.material_override = enc_mat
	enc_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	enc_node.visible = false
	add_child(enc_node)
	add_landmark("Arrival water (start)", START)
	add_landmark("Abandoned hideout deck", Vector3(12.0, Kit.DECK, 3.1))
	add_landmark("Radio in the water", RADIO)
	add_landmark("Stair core, corrupted-number door", stair_door)
	add_shot("basement", Vector3(2.4, 1.62, 9.6), Vector3(14.0, 1.0, 3.6), {"flashlight": false})
	add_shot("stair", stair_door + Vector3(-0.3, -1.62, 11.6), stair_door + Vector3(0.0, 2.2, 0.2), {"flashlight": false})


func kind_of(k: Vector2i) -> String:
	if k == Vector2i.ZERO:
		return "start"
	if k == stair_key:
		return "stair"
	var h := absi(hash([level_seed, k.x, k.y, "kind"])) % 100
	if h < 13:
		return "well"
	if h < 27:
		return "sump"
	if h < 36:
		return "collapse"
	return "bay"


func _chunk(cx: int, cz: int, _v: int, n: Node3D) -> Dictionary:
	return geo.chunk(cx, cz, n)


# ------------------------------------------------------- authored bits

func _props_authored() -> void:
	var k := kit("Authored")
	# the base radio, lying on the floor under the murky water
	k.box(RADIO + Vector3(0, 0.04, 0), Vector3(0.09, 0.08, 0.26), "l289_cable", GeoKit.ALL, false)
	Kit.tube(k, RADIO + Vector3(0.03, 0.08, 0.1), RADIO + Vector3(0.03, 0.08, 0.32), 0.006, "l289_cable")
	k.commit()
	add_interactable(RADIO + Vector3(0, 0.5, 0), Vector3(1.1, 1.0, 1.1), "Feel for the radio in the water", _on_radio)
	sound.emitter("static", RADIO + Vector3(0, 0.3, 0), {"seconds": 3.0}, -24.0, 9.0)
	_radio_voice = AudioStreamPlayer3D.new()
	_radio_voice.bus = "SFX"
	_radio_voice.max_distance = 14.0
	_radio_voice.volume_db = -10.0
	_radio_voice.position = RADIO + Vector3(0, 0.3, 0)
	_radio_voice.stream = Fx.radio_voice(2.6, 12370)
	add_child(_radio_voice)
	add_note("l289_terminal", "M.E.G. terminal: Entry Level 289", _terminal_text(),
		Vector3(13.85, Kit.DECK + 0.62, 1.75), Vector3(0.6, 0.4, 0.5), false)


## The purged entry, as the hideout laptop shows it. Each pass through the
## loop recovers one more backup file, as the page's two offsets do.
func _terminal_text() -> String:
	var t := "CAUTION: this entry has been purged.\nSearching for offline backups... 7 backup files found.\n"
	if loops == 0:
		t += "File data corrupted/lost (-2-3-4-5-6-7-). FILE 1 retrieved.\n\n"
		t += "[Event Log 1237, in summary] A regiment recorded arriving in a flooded basement: waist-deep, foul water (one of them guessed Almond Water) and scaffolding everywhere, badly put up. Further in, something they could not make out came at their lead faster than anyone could follow and stopped dead in front of him. The man who stepped in its way said it was screaming at him and that it burned. Nobody else heard a thing. Then he went backwards, away from the team, as fast as it had come, like time running back for him alone. Base later reported him found on Level 287, sitting with his back to a wall, humming.\n\n> OPEN FILE 2 > £÷¥π÷ππ¥π-£÷ ÷¢|}≠{=/~"
	else:
		t += "Entry errors repaired. FILE 1 retrieved. FILE 2 retrieved. (-3-4-5-6-7- lost)\n\n"
		t += "[End of log, in summary] The team made a temporary hideout and hid in it until backup came, and were then escorted through the level with no further sign of the thing. Extensive exploration found a single exit. It leads to Level 14444444-£÷¥π÷ππ^÷¢|}≠{=/~, and that leads back here. At the time of writing they had been stuck for a week.\n\nAccesses of this entry from this terminal: %d" % (loops + 1)
	return t


func _audio() -> void:
	_beds.append(sound.bed("room_tone", {"cutoff": 170.0, "rumble": 0.5}, -21.0))
	_beds.append(sound.bed("water_bed", {"bright": 0.12}, -23.0))
	for b in _beds:
		_bed_db.append((b as AudioStreamPlayer).volume_db)
	_wade = AudioStreamPlayer.new()
	_wade.stream = AudioSynth.get_stream("water_bed", {"bright": 0.75})
	_wade.bus = "SFX"
	_wade.volume_db = -60.0
	_wade.autoplay = true
	add_child(_wade)
	sound.oneshot("drip", {"freq": 900.0}, 4.0, 11.0, 9.0, "[water drips from the slab]", -15.0)
	sound.oneshot("creak", {"freq": 70.0}, 25.0, 60.0, 10.0, "[the scaffolding creaks]", -16.0)
	sound.oneshot("pipe_clank", {"f": 310.0}, 45.0, 110.0, 14.0, "[a loose clamp knocks against a tube]", -19.0)
	_scream = AudioStreamPlayer.new()
	_scream.bus = "SFX"
	_scream.volume_db = -2.0
	add_child(_scream)
	_whoosh = AudioStreamPlayer.new()
	_whoosh.bus = "SFX"
	_whoosh.volume_db = -4.0
	add_child(_whoosh)


func on_player_ready() -> void:
	world.target = player
	if qa_fixture:
		return
	var arr: String = spawn_report.get("used_arrival", "start")
	match arr:
		"start", "from_L013":
			sound.play_at("splash", {}, player.global_position + Vector3.UP * 0.6, -3.0, "[you go face first into the water]")
			_arrive_fx = 0.7
			Overlay.set_underwater(true, get_tree().get_nodes_in_group("water")[0])
		"from_L019":
			sound.play_at("splash", {}, player.global_position + Vector3.UP * 0.6, -8.0, "[you step down into waist-deep water]")
		"from_L289":
			Overlay.subtitle("[the same stairwell, the same water below. Someone has chalked another mark.]", 4.5)


func on_loop_exit(_edge: String) -> void:
	loops += 1
	SaveService.set_flag(stable_id, "loops", loops)


# ----------------------------------------------------------- per frame

func level_process(delta: float) -> void:
	level_t += delta
	if _arrive_fx > 0.0:
		_arrive_fx -= delta
		if _arrive_fx <= 0.0 and not player.head_under:
			Overlay.set_underwater(false)
	_wading(delta)
	_record_trail()
	_encounter(delta)
	_hideout()
	_radio(delta)


func _in_water(p: Vector3) -> bool:
	for w in get_tree().get_nodes_in_group("water"):
		if (w as WaterVolume).contains(p):
			return true
	return false


## Waist-deep water drags at the legs; scaffold boards are dry and quick.
func _wading(delta: float) -> void:
	if player.frozen:
		return
	var wet := _in_water(player.global_position + Vector3.UP * 0.3)
	player.walk_speed = move_toward(player.walk_speed, 1.9 if wet else 3.1, delta * 5.0)
	player.sprint_speed = move_toward(player.sprint_speed, 2.7 if wet else 5.1, delta * 5.0)
	var spd := Vector2(player.velocity.x, player.velocity.z).length()
	var want := (-15.0 + minf(spd, 2.5) * 2.4) if wet and spd > 0.3 else -60.0
	_wade.volume_db = lerpf(_wade.volume_db, want, clampf(delta * 4.0, 0.0, 1.0))
	if wet and spd > 0.6 and not _wade_said:
		_wade_said = true
		Overlay.subtitle("[waist-deep water. It stinks: sour, and faintly nutty]", 4.0)


func _record_trail() -> void:
	if enc_state in ["rewind", "relocate"] or player.frozen:
		return
	var p := player.global_position
	if trail.is_empty() or trail[trail.size() - 1].distance_to(p) > 0.25:
		trail.append(p)
		if trail.size() > 700:
			trail = trail.slice(trail.size() - 600)


func _hideout() -> void:
	if _hideout_done:
		return
	var p := player.global_position
	if p.y > 1.0 and HIDEOUT.has_point(Vector2(p.x, p.z)):
		_hideout_done = true
		checkpoint("hideout")
		Overlay.subtitle("[a dry deck under a tarp. Someone hid here, and packed up]", 4.0)


func _radio(delta: float) -> void:
	_radio_t -= delta
	if _radio_t <= 0.0:
		_radio_t = randf_range(22.0, 40.0)
		if player.global_position.distance_to(RADIO) < 12.0 and enc_state == "dormant":
			_radio_voice.play()
			Overlay.subtitle("[a radio somewhere under the water: a base operator, asking if anyone is still there]", 3.5)
	if not _radio_lines.is_empty():
		_radio_line_t -= delta
		if _radio_line_t <= 0.0:
			_radio_line_t = 3.6
			_radio_voice.play()
			Overlay.subtitle(_radio_lines.pop_front(), 3.4)


func _on_radio(_p: Player) -> void:
	_radio_lines = [
		"[radio, waterlogged: '...sending a backup team to your position. Over.']",
		"[radio: '...you have it marked on the app? ...Copy.']",
		"[radio: '...they found him on 287. Back to the wall. Humming to himself. Over.']",
		"[the radio hisses, then only static]"]
	_radio_line_t = 0.0


# ------------------------------------------------------------ the entity

func _encounter(delta: float) -> void:
	match enc_state:
		"dormant":
			if qa_fixture:
				return
			_enc_check -= delta
			if _enc_check > 0.0:
				return
			_enc_check = 0.5
			var fp := player.global_position
			if level_t < 70.0 or Vector2(fp.x - START.x, fp.z - START.z).length() < enc_radius:
				return
			if fp.y > 0.5 or player.swimming or fp.distance_to(stair_door) < 22.0:
				return
			var p := _sight_point()
			if p.x != INF:
				begin_encounter(p)
		"sighted":
			enc_t += delta
			enc_mat.set_shader_parameter("alpha", minf(0.55, enc_t * 0.4))
			if enc_t >= SIGHT_S:
				enc_state = "rush"
				enc_t = 0.0
				enc_from = enc_node.global_position
				Overlay.subtitle("[it is suddenly right in front of you]", 2.0)
		"rush":
			enc_t += delta
			var fwd := _flat_fwd()
			enc_to = player.global_position + fwd * 1.15 + Vector3.UP * 1.05
			var u := clampf(enc_t / RUSH_S, 0.0, 1.0)
			enc_node.global_position = enc_from.lerp(enc_to, u)
			enc_node.scale = Vector3(1.0 + 5.0 * sin(PI * u), 1.0, 1.0)
			enc_mat.set_shader_parameter("smear", sin(PI * u))
			enc_mat.set_shader_parameter("alpha", 0.75)
			if u >= 1.0:
				# stops dead: no momentum carried, nothing splashes
				enc_node.global_position = enc_to
				enc_node.scale = Vector3.ONE
				enc_mat.set_shader_parameter("smear", 0.0)
				enc_mat.set_shader_parameter("alpha", 0.85)
				enc_state = "scream"
				enc_t = 0.0
				player.frozen = true
				player.velocity = Vector3.ZERO
				_pitch0 = player.look_pitch
				_scream.play()
				Overlay.subtitle("[SCREAMING, right inside your ears, and it BURNS. The water around you is silent.]", SCREAM_S)
		"scream":
			enc_t += delta
			var u := clampf(enc_t / SCREAM_S, 0.0, 1.0)
			_red = minf(0.6, enc_t * 0.5)
			Overlay.set_screen_effect("red_tint", _red)
			Overlay.set_screen_effect("vignette", 0.25 + 0.5 * u)
			var amp := 0.012 + 0.03 * u
			player.camera.rotation = Vector3(randf_range(-amp, amp), randf_range(-amp, amp), randf_range(-amp, amp) * 1.5)
			player.look_pitch = lerpf(_pitch0, deg_to_rad(-28.0), u * u)
			player.head.rotation.x = player.look_pitch
			if enc_t >= SCREAM_S:
				enc_state = "rewind"
				enc_t = 0.0
				enc_node.visible = false
				rewind_from = player.global_position
				_rw_i = trail.size() - 1
				_whoosh.stream = Fx.rewind(1.8)
				_whoosh.play()
				Overlay.subtitle("[you are pulled backwards, fast: every step you took, unwinding]", 2.5)
		"rewind":
			enc_t += delta
			Overlay.glitch(0.9)
			Overlay.set_screen_effect("desaturate", minf(0.8, enc_t))
			var budget := REWIND_SPEED * delta
			var p := player.global_position
			while budget > 0.0 and _rw_i >= 0:
				var tgt: Vector3 = trail[_rw_i]
				var d := p.distance_to(tgt)
				if d <= budget:
					p = tgt
					budget -= d
					_rw_i -= 1
				else:
					p = p.move_toward(tgt, budget)
					budget = 0.0
			player.global_position = p
			if _rw_i < 0 or enc_t >= 1.8:
				_relocate()
		"relocate":
			enc_t += delta
			if enc_t > 0.3 and is_instance_valid(_relocate_exit) and not relocated:
				_relocate_exit.fire()
			if enc_t >= 1.4:
				enc_state = "gone"
				enc_t = 0.0
				player.frozen = false
				player.camera.rotation = Vector3.ZERO
				if is_instance_valid(_relocate_exit):
					_relocate_exit.enabled = false
				Overlay.subtitle("[it is gone. No sign of it anywhere.]", 3.0)
		"gone":
			if _red > 0.0:
				_red = maxf(0.0, _red - delta * 0.3)
				Overlay.set_screen_effect("red_tint", _red)
				Overlay.set_screen_effect("desaturate", _red)
				Overlay.set_screen_effect("vignette", 0.25 + _red * 0.6)
			for i in _beds.size():
				(_beds[i] as AudioStreamPlayer).volume_db = move_toward((_beds[i] as AudioStreamPlayer).volume_db, _bed_db[i], delta * 4.0)


func _flat_fwd() -> Vector3:
	var f := -player.global_transform.basis.z
	f.y = 0.0
	return f.normalized()


## A floor point in open water straight ahead, in clear line of sight.
func _sight_point() -> Vector3:
	var eye := player.camera.global_position
	var fwd := _flat_fwd()
	var space := get_world_3d().direct_space_state
	for d: float in [22.0, 18.0, 14.0, 10.0]:
		var tgt: Vector3 = eye + fwd * d
		if not space.intersect_ray(PhysicsRayQueryParameters3D.create(eye, tgt, 1)).is_empty():
			continue
		var h := space.intersect_ray(PhysicsRayQueryParameters3D.create(tgt, tgt + Vector3.DOWN * 4.0, 1))
		if h.is_empty() or absf(h["position"].y) > 0.1:
			continue
		return h["position"]
	return Vector3(INF, INF, INF)


## Out of nowhere: a shape standing in the water up ahead.
func begin_encounter(floor_point: Vector3) -> void:
	enc_state = "sighted"
	enc_t = 0.0
	enc_node.global_position = floor_point + Vector3.UP * 1.05
	enc_node.scale = Vector3.ONE
	enc_mat.set_shader_parameter("alpha", 0.0)
	enc_mat.set_shader_parameter("smear", 0.0)
	enc_node.visible = true
	if _scream.stream == null:
		_scream.stream = Fx.scream(SCREAM_S)
	for b in _beds:
		var tw := create_tween()
		tw.tween_property(b, "volume_db", -40.0, 1.5)
	Overlay.subtitle("[something is standing in the water up ahead]", 2.4)


## End of the rush backwards: the sourced relocation edge fires from here.
func _relocate() -> void:
	enc_state = "relocate"
	enc_t = 0.0
	_relocate_exit = add_exit("L289>L287#2", "condition", player.global_position + Vector3.UP * 0.9, Vector3(2.4, 2.4, 2.4))
	if _relocate_exit:
		_relocate_exit.condition = func(): return enc_state == "relocate"
		_relocate_exit.fired.connect(func(_e): relocated = true)


# ------------------------------------------------------------------- QA

func qa_capture_plan() -> Array:
	var plan: Array = qa_shots.duplicate()
	if "--l289debug" in OS.get_cmdline_user_args():
		for kd in ["well", "collapse", "sump"]:
			for z in range(-2, 3):
				for x in range(-2, 3):
					if kind_of(Vector2i(x, z)) == kd and not plan.any(func(q): return q["name"] == kd):
						var o := Vector3(x * CS, 0, z * CS)
						if kd == "well":
							plan.append({"name": kd, "pos": o + Vector3(5.6, 4.45 + 1.62, 11.0), "target": o + Vector3(10.0, 0.5, 4.0)})
							plan.append({"name": kd + "_low", "pos": o + Vector3(8.0, 1.62, 15.0), "target": o + Vector3(8.0, 4.0, 6.0)})
						elif kd == "collapse":
							var cc: Vector3 = world.meta_of(Vector2i(x, z)).get("collapse_c", o)
							plan.append({"name": kd, "pos": cc + Vector3(6.0, 1.62, 6.0), "target": cc + Vector3(0, 1.4, 0), "flashlight": true})
						else:
							plan.append({"name": kd, "pos": o + Vector3(0.5, 1.62, 0.5), "target": o + Vector3(8.0, 0.8, 8.0)})
	for s in plan:
		var p: Vector3 = s["pos"]
		s["prepare"] = func(): world.build_around(p, 2)
	return plan


func qa_self_test() -> Array:
	var out: Array = []
	var w_ok := false
	for w in get_tree().get_nodes_in_group("water"):
		if absf((w as WaterVolume).surface_y - SURF) < 0.01:
			w_ok = true
	out.append({"what": "waist-deep water volumes (surface 0.86 m over the basement floor)", "ok": w_ok})
	var ex_ok := false
	for t in exits:
		if is_instance_valid(t) and t.edge_id == "L289>EXT#1":
			ex_ok = stair_arrival.distance_to(t.global_position) < 3.5
	var man_ok := false
	for x in manifest.get("exits", []):
		if x.get("id", "") == "L289>EXT#1":
			man_ok = x.get("to", "") == "L289" and x.get("arrival", "") == "from_L289"
	out.append({"what": "corrupted-number exit loops back to Level 289 at the same door", "ok": ex_ok and man_ok, "detail": [ex_ok, man_ok]})
	# wade: walk north from the arrival for two seconds (also lays a trail)
	player.global_position = START
	player.rotation = Vector3.ZERO
	trail.clear()
	player.qa_active = true
	player.qa_input = Vector2(0, 1)
	for i in 120:
		await get_tree().physics_frame
	player.qa_input = Vector2.ZERO
	player.qa_active = false
	out.append({"what": "waist-deep water slows walking", "ok": player.walk_speed < 2.2, "detail": player.walk_speed})
	out.append({"what": "trail recorded while wading", "ok": trail.size() >= 6, "detail": trail.size()})
	TransitionService.qa_log.clear()
	var ahead := player.global_position + _flat_fwd() * 10.0
	var sp := _sight_point()
	begin_encounter(sp if sp.x != INF else Vector3(ahead.x, 0.0, ahead.z))
	var seen_stop := false
	var t := 0
	while enc_state != "gone" and t < 1200:
		await get_tree().process_frame
		t += 1
		if enc_state == "scream" and not seen_stop:
			seen_stop = enc_node.global_position.distance_to(player.global_position + Vector3.UP * 1.05) < 1.6
	var logged := false
	for e in TransitionService.qa_log:
		if e.get("id", "") == "L289>L287#2":
			logged = true
	out.append({"what": "entity rushes and stops dead in front of the wanderer", "ok": seen_stop})
	out.append({"what": "rewind carries the wanderer back along their own path", "ok": rewind_from.distance_to(player.global_position) > 1.5,
		"detail": rewind_from.distance_to(player.global_position)})
	out.append({"what": "relocation fires sourced edge L289>L287#2", "ok": logged and relocated, "detail": TransitionService.qa_log.size()})
	out.append({"what": "wanderer released, entity gone afterwards", "ok": not player.frozen and enc_state == "gone" and not enc_node.visible})
	Overlay.reset_screen_effects()
	return out
