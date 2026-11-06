extends LevelBase
## Level 601 - "The End" (Backrooms Wikidot rev 119, accessed 2026-11-04; cite:
## 1000dumplings, original author skivy123, CC BY-SA 3.0). Dossier:
## docs/canon/levels/L601.md. The page is marked as being rewritten; only what it
## documents is built, and its closing first-person monologue is TESTIMONY.
##   a 'trap Level' that creates the illusion of escaping                   SOURCE
##   a seemingly endless modern library; main area in the centre with metal
##   letters spelling 'the end is near'                                     SOURCE
##   near-complete silence; the centre's computer terminals buzz loudly;
##   staying in the centre is recommended against isolation                 SOURCE
##   walking one way loops; turning around then meets a wall               SOURCE
##   frequent random noclipping that never exits the level                 SOURCE
##   wanderers cannot perceive other wanderers (no one is shown)           SOURCE
##   fake realities: personalised familiar sub-areas close together that
##   blend; breaching a border returns everything to normal; humans there
##   are perceivable (the six Junkies; Memory Juice only)                   SOURCE
##   all electricity fails except the terminals (flashlight dies at once)  SOURCE
##   terminals advised against: Partygoers frequent them; reports of people
##   taken (presence only: no Partygoer is spawned or shown)               SOURCE
##   exits sometimes inside fake realities, never consistent (L601>EXT#1)  SOURCE
## World: ChunkWorld streams 24 m chunks whose content repeats every 6 chunks
## (a 144 m period cell). The playable world is a finite streaming window.

const Lib := preload("res://levels/L601/L601_lib.gd")
const Fake := preload("res://levels/L601/L601_fake.gd")
const CS := 24.0
const N := 6
const PERIOD := 144.0
const OFF := 48.0
const START := Vector3(5.0, 0.05, 20.8)
const CENTRE := Vector2(12.0, 12.0)
const HOME_R := Rect2(30.0, 30.6, 13.0, 11.4)
const FIELD_R := Rect2(43.0, 24.0, 29.0, 24.0)

var lib: Lib
var fake: Fake
var world: ChunkWorld
var qa_fixture := false
var ev := RandomNumberGenerator.new()
var period := Vector2i.ZERO
var start_period := Vector2i.ZERO
var loops := 0
var seam_pending: Array = [{}, {}]
var seam_walls: Array = []
var seam_set: Array = [false, false]
var iso := 0.0
var noclip_t := 90.0
var noclips := 0
var attention := 0
var door_tries := 0
var breach_hold := false
var was_in_pocket := false
var w_home := 0.0
var w_field := 0.0
var smiles: Array = []
var buzzers: Array = []
var _bed: AudioStreamPlayer
var _heart: AudioStreamPlayer
var _said := {}
var _fl_t := 0.0


func build() -> void:
	qa_fixture = SessionState.is_qa()
	ev.seed = hash([level_seed, "events"])
	rules["flashlight"] = "fails"
	rules["view_distance"] = 90.0
	rules["reverb_room"] = 0.3
	rules["reverb_wet"] = 0.08
	indoor_env(Color(0.66, 0.70, 0.75), 0.2, Color(0.44, 0.46, 0.49), 0.016)
	environment.tonemap_exposure = 0.92
	environment.glow_intensity = 0.38
	environment.glow_bloom = 0.06
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.9
	environment.adjustment_contrast = 1.04
	Lib.materials()
	Fake.materials()
	lib = Lib.new(self, level_seed)
	fake = Fake.new(lib)
	lights.setup(14, 1)
	lights.max_distance = 32.0
	world = ChunkWorld.new()
	world.name = "Chunks"
	world.chunk_size = CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _chunk
	add_child(world)
	world.chunk_unloaded.connect(func(k): lights.remove_group("%d,%d" % [k.x, k.y]))
	add_arrival("start", START, -39.0)
	add_arrival("from_L085", Vector3(-18.0, 0.05, 12.0), -90.0)
	var spawn := START
	var cp: Dictionary = TransitionService.pending_restore
	if cp.get("level", "") == stable_id and cp.get("pos") is Array and (cp["pos"] as Array).size() == 3:
		spawn = Vector3(cp["pos"][0], cp["pos"][1], cp["pos"][2])
	elif arrivals.has(TransitionService.pending_arrival):
		spawn = (arrivals[TransitionService.pending_arrival] as Transform3D).origin
	world.build_around(START if qa_fixture else spawn, 2)
	period = period_of(spawn)
	start_period = period
	for i in 2:
		seam_walls.append(_make_seam_wall(i))
	_audio()
	add_landmark("Main area: 'the end is near' and the terminals", Vector3(12, 0, 12))
	add_landmark("Door you came in by (neon sign, dead)", Vector3(5.0, 0, 22.4))
	add_landmark("Fake reality: the home (front door)", Vector3(36.0, 0, 42.0))
	add_landmark("Fake reality: the field (Junkies, gate)", Vector3(63.3, 0, 45.0))
	add_shot("centre", Vector3(13.5, 1.62, 20.6), Vector3(12.3, 4.6, 2.0), {"flashlight": false})
	add_shot("home", Vector3(27.0, 1.62, 33.6), Vector3(38.0, 1.0, 39.0), {"flashlight": false})


static func loc(c: int) -> int:
	return posmod(c + 2, N) - 2


static func period_of(p: Vector3) -> Vector2i:
	return Vector2i(floori((p.x + OFF) / PERIOD), floori((p.z + OFF) / PERIOD))


static func local_of(p: Vector3) -> Vector2:
	return Vector2(fposmod(p.x + OFF, PERIOD) - OFF, fposmod(p.z + OFF, PERIOD) - OFF)


func _chunk(cx: int, cz: int, _v: int, n: Node3D) -> Dictionary:
	var lx := loc(cx)
	var lz := loc(cz)
	var o := Vector3(cx * CS, 0, cz * CS)
	var group := "%d,%d" % [cx, cz]
	var meta: Dictionary
	if lx == 0 and lz == 0:
		meta = lib.centre(o, group, n)
		_wire_centre(o, n, meta)
	elif lx == 1 and lz == 1:
		meta = fake.home(o, lx, lz, group, n)
	elif lx == 2 and lz == 1:
		meta = fake.field(o, lx, lz, group, n)
	else:
		meta = lib.stacks(o, lx, lz, group, n)
	meta["local"] = Vector2i(lx, lz)
	return meta


func _wire_centre(o: Vector3, n: Node3D, meta: Dictionary) -> void:
	for t in meta.get("terminals", []):
		var it := add_interactable(t["pos"], Vector3(0.7, 0.5, 0.35), "Use the terminal", _on_terminal)
		it.reparent(n)
		var s: Label3D = t["smile"]
		s.visible = attention > 0
		smiles.append(s)
	var notes := [add_note("l601_survey", "Notes left on a reading table", survey_text(), o + Vector3(3.5, 0.79, 10.4)),
		add_note("l601_tape", "Note taped to the terminal desk", tape_text(), o + Vector3(9.75, 0.79, 11.3))]
	for nt in notes:
		(nt as Node).reparent(n)
	var door := add_interactable(o + Vector3(5.0, 1.05, 22.15), Vector3(1.0, 2.1, 0.3), "Try the door you came in by", _on_entry_door)
	door.reparent(n)
	var neon := Label3D.new()
	neon.text = "EXIT"
	neon.font_size = 48
	neon.pixel_size = 0.0045
	neon.modulate = Color(0.32, 0.08, 0.07)
	neon.shaded = true
	neon.outline_size = 0
	neon.position = o + Vector3(5.0, 2.46, 22.16)
	neon.rotation.y = PI
	n.add_child(neon)
	for e in [["transformer", {"base": 118.0}, -5.0], ["fluorescent_hum", {"base": 60.0, "rasp": 0.6}, -9.0]]:
		var b := sound.emitter(e[0], o + Vector3(13.0, 1.0, 12.0), e[1], e[2], 20.0)
		b.reparent(n)
		b.set_meta("db", e[2])
		buzzers.append(b)


func _make_seam_wall(axis: int) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.name = "SeamWall%d" % axis
	var size := Vector3(0.3, 3.2, 110.0) if axis == 0 else Vector3(110.0, 3.2, 0.3)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	cs.set_meta("surface", "concrete")
	cs.disabled = true
	sb.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = MatLib.get_mat("l601_wall")
	sb.add_child(mi)
	sb.visible = false
	sb.position = Vector3(0, -50, 0)
	add_child(sb)
	return sb


func _audio() -> void:
	_bed = sound.bed("room_tone", {"cutoff": 90.0, "rumble": 0.1}, -34.0)
	_heart = sound.bed("heartbeat", {}, -80.0, "SFX")
	sound.oneshot("creak", {"freq": 0.6}, 45.0, 110.0, 14.0, "[somewhere in the stacks, a shelf settles]", -26.0)


func on_player_ready() -> void:
	if qa_fixture:
		return
	var tag := str(spawn_report.get("used_arrival", "start"))
	if tag == "from_L085":
		Overlay.glitch(0.8)
		Overlay.subtitle("[you fall through the floor of one library and land between the shelves of another]", 4.5)
	elif tag == "start":
		Overlay.subtitle("[the door shuts behind you. A library: bright, quiet, ordinary. It feels like you got out.]", 5.0)
	checkpoint("arrival")


# ------------------------------------------------------------- per frame

func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var p := player.global_position
	_flashlight(delta)
	_seams(p)
	var lp := local_of(p)
	var in_pocket := HOME_R.has_point(lp) or FIELD_R.has_point(lp)
	_blend(lp, in_pocket)
	var dc := lp.distance_to(CENTRE)
	_isolation(dc, in_pocket, delta)
	_noclip_tick(dc, in_pocket, delta)
	_apply_env(clampf(delta * 1.8, 0.0, 1.0))
	if dc < 9.0 and period != start_period and not _said.has("loop"):
		_said["loop"] = true
		Overlay.subtitle("[the letters again: the end is near. You walked one way the whole time, and you are back.]", 5.0)
	if dc < 9.0 and not _said.has("centre"):
		_said["centre"] = true
		Overlay.subtitle("[near-total silence. Only the computer terminals buzz, loudly.]", 4.0)
	if HOME_R.grow(-1.0).has_point(lp) and not _said.has("home"):
		_said["home"] = true
		Overlay.subtitle("[floorboards under the carpet. A living room you almost know, the windows full of evening.]", 5.0)
	if FIELD_R.grow(-3.0).has_point(lp) and lp.x > 49.0 and not _said.has("field"):
		_said["field"] = true
		Overlay.subtitle("[grass, an evening sky, a dead vending machine. Six people sit around a cold fire.]", 5.0)


func _flashlight(delta: float) -> void:
	_fl_t -= delta
	if player.flashlight.visible:
		player.flashlight.visible = false
		if _fl_t <= 0.0:
			_fl_t = 4.0
			Overlay.subtitle("[click. Nothing. Nothing electric works here.]", 2.5)


## Loop seams: every 144 m the plan repeats. Once you have walked through a
## seam, turning back meets a wall that was not there.
func _seams(p: Vector3) -> void:
	var cur := period_of(p)
	for a in 2:
		var c: int = cur.x if a == 0 else cur.y
		var was: int = period.x if a == 0 else period.y
		if c != was:
			var seam := float(maxi(c, was)) * PERIOD - OFF
			seam_pending[a] = {"at": seam, "dir": signi(c - was)}
			loops += 1
			if a == 0:
				period.x = c
			else:
				period.y = c
		var pend: Dictionary = seam_pending[a]
		if pend.is_empty():
			continue
		var pa: float = p.x if a == 0 else p.z
		var past: float = (pa - float(pend["at"])) * float(pend["dir"])
		if past < -0.5:
			seam_pending[a] = {}
			continue
		if past > 2.2 and not _seam_in_view(a, float(pend["at"])):
			_place_wall(a, float(pend["at"]), p)
			seam_pending[a] = {}
			if not _said.has("wall"):
				_said["wall"] = true
				Overlay.subtitle("[you have been walking in a straight line for a long time. The shelves look familiar.]", 4.5)
	for a in 2:
		if seam_set[a]:
			var w: StaticBody3D = seam_walls[a]
			var along: float = p.z if a == 0 else p.x
			var cur_c: float = w.position.z if a == 0 else w.position.x
			if absf(along - cur_c) > 16.0:
				if a == 0:
					w.position.z = along
				else:
					w.position.x = along


func _seam_in_view(a: int, at: float) -> bool:
	var cam := player.camera
	var fwd := -cam.global_transform.basis.z
	var p := player.global_position
	var to := Vector3(at - p.x, 0, 0) if a == 0 else Vector3(0, 0, at - p.z)
	return fwd.normalized().dot(to.normalized()) > 0.3


func _place_wall(a: int, at: float, p: Vector3) -> void:
	var w: StaticBody3D = seam_walls[a]
	w.position = Vector3(at, 1.6, p.z) if a == 0 else Vector3(p.x, 1.6, at)
	w.visible = true
	(w.get_child(0) as CollisionShape3D).disabled = false
	seam_set[a] = true


func _blend(lp: Vector2, in_pocket: bool) -> void:
	if was_in_pocket and not in_pocket:
		breach_hold = true
		_breach_fx("[you step past the edge of it, and everything is normal again: carpet, shelves, silence.]")
	was_in_pocket = in_pocket
	var dh := _rect_dist(HOME_R, lp)
	var df := _rect_dist(FIELD_R, lp)
	if breach_hold:
		if minf(dh, df) > 3.5 or in_pocket:
			breach_hold = false
		else:
			w_home = 0.0
			w_field = 0.0
			return
	w_home = 1.0 - smoothstep(0.0, 6.0, dh)
	w_field = (1.0 - smoothstep(0.0, 6.0, df)) * smoothstep(41.0, 47.0, lp.x)


static func _rect_dist(r: Rect2, p: Vector2) -> float:
	var dx := maxf(maxf(r.position.x - p.x, 0.0), p.x - r.end.x)
	var dz := maxf(maxf(r.position.y - p.y, 0.0), p.y - r.end.y)
	return Vector2(dx, dz).length()


func _isolation(dc: float, in_pocket: bool, delta: float) -> void:
	if dc < 14.0:
		iso = maxf(0.0, iso - 0.08 * delta)
	elif in_pocket:
		iso = maxf(0.0, iso - 0.02 * delta)
	else:
		iso = minf(1.0, iso + (0.003 + 0.00022 * (dc - 14.0)) * delta)
	if iso > 0.35 and not _said.has("iso1"):
		_said["iso1"] = true
		Overlay.subtitle("[the silence presses in. You cannot hear anyone else, anywhere. You cannot see anyone either.]", 5.0)
	if iso > 0.75 and not _said.has("iso2"):
		_said["iso2"] = true
		Overlay.subtitle("[you have seen no one since you arrived. You begin to doubt there is anyone to see.]", 5.0)
	_heart.volume_db = lerpf(-80.0, -16.0, smoothstep(0.45, 1.0, iso))
	_bed.volume_db = lerpf(-34.0, -46.0, iso)


func _noclip_tick(dc: float, in_pocket: bool, delta: float) -> void:
	if qa_fixture or player.frozen or dc < 13.0 or in_pocket:
		return
	noclip_t -= delta * (1.0 + 1.6 * iso)
	if noclip_t <= 0.0:
		noclip_t = ev.randf_range(55.0, 140.0)
		do_noclip("[the floor gives like a missed step... and you are standing between shelves again. Still the library. Still The End.]")


## Random no-clip: you fall through, and land somewhere else in the library.
func do_noclip(caption: String) -> bool:
	var c := world.key_at(player.global_position)
	var cand: Array = []
	for dz in range(-2, 3):
		for dx in range(-2, 3):
			if maxi(absi(dx), absi(dz)) < 1:
				continue
			var k := c + Vector2i(dx, dz)
			var meta := world.meta_of(k)
			if meta.get("kind", "") in ["stacks", "pit", "tables"]:
				for f in meta.get("free", []):
					cand.append(world.chunk_origin(k) + Vector3(f.x, 0.05, f.y))
	if cand.is_empty():
		return false
	var t: Vector3 = cand[ev.randi() % cand.size()]
	world.build_around(t, 1)
	Overlay.glitch(1.0)
	player.global_position = t
	player.velocity = Vector3.ZERO
	noclips += 1
	Overlay.subtitle(caption, 4.5)
	return true


func _breach_fx(caption: String) -> void:
	Overlay.glitch(0.55)
	Overlay.subtitle(caption, 4.0)
	_apply_env(1.0)


func _apply_env(k: float) -> void:
	var amb := Color(0.66, 0.70, 0.75).lerp(Color(1.0, 0.72, 0.52), w_home).lerp(Color(1.0, 0.78, 0.55), w_field)
	var ae := lerpf(lerpf(0.2, 0.18, w_home), 0.3, w_field) * (1.0 - 0.3 * iso)
	var fc := Color(0.44, 0.46, 0.49).lerp(Color(0.26, 0.18, 0.12), w_home).lerp(Color(0.78, 0.56, 0.38), w_field)
	var fd := lerpf(lerpf(0.016, 0.012, w_home), 0.016, w_field) + 0.03 * iso
	var sat := lerpf(lerpf(0.9, 1.05, w_home), 1.1, w_field) * (1.0 - 0.55 * iso)
	environment.ambient_light_color = environment.ambient_light_color.lerp(amb, k)
	environment.ambient_light_energy = lerpf(environment.ambient_light_energy, ae, k)
	environment.fog_light_color = environment.fog_light_color.lerp(fc, k)
	environment.fog_density = lerpf(environment.fog_density, fd, k)
	environment.adjustment_saturation = lerpf(environment.adjustment_saturation, sat, k)
	Overlay.set_screen_effect("vignette", 0.25 + 0.35 * iso)


# ------------------------------------------------------------- interaction

func _on_terminal(_p: Player) -> void:
	attention += 1
	for s in smiles:
		if is_instance_valid(s):
			(s as Label3D).visible = true
	for b in buzzers:
		if is_instance_valid(b):
			(b as AudioStreamPlayer3D).volume_db = float(b.get_meta("db")) + 4.0 * attention
	if attention == 1:
		Overlay.show_note("Terminal", "The screen wakes and finds a network at once, any network: it seems to reach every Wi-Fi source there is, here where nothing else electric works.\n\nOne unread message, no sender:\n\n=)\n\nEvery screen in the room now shows the same two characters.")
	elif attention == 2:
		Overlay.show_note("Terminal", "Another message, no sender. It reads like the end of the page about this place: someone in the first person who claims to send the messages and to rewrite the records, and who says there are only three outcomes: leave, die, or go along with them.\n\n[TESTIMONY: unattributed and unreliable. Nothing it claims is verified.]\n\nThe buzzing is louder. The room feels attended, though you see no one.")
		Overlay.subtitle("[the terminals' buzz climbs. You are told not to use these.]", 4.0)
	else:
		_taken()


func _taken() -> void:
	player.frozen = true
	Overlay.subtitle("[the screens all smile at once. Something is in the room with you.]", 3.0)
	await Overlay.fade_to(1.0, 1.6)
	attention = 0
	player.frozen = false
	player.hurt(1000.0, "Taken at the terminals. Wanderers chased into The End have been reported taken by Partygoers here.")
	Overlay.fade_to(0.0, 0.6)


func _on_entry_door(_p: Player) -> void:
	Overlay.subtitle("[it will not open. From this side it is only a door, and the neon sign above it is dead.]", 4.0)


func on_junkie(_p: Player) -> void:
	if SaveService.item_count("memory_juice") > 0:
		Overlay.subtitle("[their eyes find your Memory Juice. Nobody says what they would give for it.]", 4.5)
	else:
		Overlay.subtitle("[they do not look up. One murmurs that they are home now, and that they trade for Memory Juice, nothing else.]", 5.0)


## A fake reality's way out. Sometimes it is a real exit (L601>EXT#1); far more
## often you breach the border and the library is simply back. Never consistent.
func try_door(which: String) -> bool:
	if qa_fixture:
		return true
	door_tries += 1
	var chance := 0.28 if which == "home" else 0.14
	if ev.randf() < chance:
		Overlay.subtitle("[it opens onto somewhere else. Somewhere safer, maybe.]", 3.5)
		return true
	call_deferred("_door_breach", which)
	return false


func _door_breach(which: String) -> void:
	breach_hold = true
	var cap := "[you open the front door - and you are standing in the stacks. The house is gone behind the shelves. Everything is normal again.]" \
		if which == "home" else "[you push the gate - and there is carpet under your feet, and shelves, and silence. Everything is normal again.]"
	if not do_noclip(cap):
		_breach_fx(cap)
	was_in_pocket = false
	w_home = 0.0
	w_field = 0.0
	_apply_env(1.0)


# ------------------------------------------------------------- text

func survey_text() -> String:
	return "Handwritten, several people, mostly crossed out and rewritten.\n\n" + \
		"- It looks like you got out. You didn't. This is a trap that only looks like the way home.\n" + \
		"- The library goes on and on. Stay here in the middle, under the letters. Out there the quiet gets to you.\n" + \
		"- If you walk one way long enough you come back round to the middle. Don't turn back after that. There's a wall.\n" + \
		"- You'll drop through the floor now and then. You land in the library again. It never lets you out.\n" + \
		"- Two of us stood a metre apart and couldn't see each other.\n" + \
		"- Nothing that runs on power works. Except the computers.\n" + \
		"- There are rooms out there that look like home. Your home. When you walk out of one, it's gone. Sometimes, they say, one of them has a real door. Not twice in a row.\n" + \
		"- There are exits. Nobody has managed to write down where."


func tape_text() -> String:
	return "DON'T USE THESE.\n\nThey work, they'll connect to anything, and that's the problem. Partygoers come round here, and whatever they keep calling their host. At least three people were chased in here and taken. Leave the screens alone."


func bntg_text() -> String:
	return "B.N.T.G. outreach tag, weatherproofed.\n\nReturned again for the six at the camp. Same as last time: they will not come. They say they are home. They are only open to trade if you carry Memory Juice, and they drink what they get so that home feels real. Rescue not achieved. Will try again."


# ------------------------------------------------------------------- QA

func snap_env_to(pos: Vector3) -> void:
	var lp := local_of(pos)
	breach_hold = false
	was_in_pocket = HOME_R.has_point(lp) or FIELD_R.has_point(lp)
	_blend(lp, was_in_pocket)
	iso = 0.0
	_apply_env(1.0)


func qa_capture_plan() -> Array:
	var plan: Array = qa_shots.duplicate()
	if "--l601all" in OS.get_cmdline_user_args():
		plan.append({"name": "field", "pos": Vector3(46.5, 1.62, 33.0), "target": Vector3(56.0, 1.0, 40.0)})
		plan.append({"name": "dbg2", "pos": Vector3(12.0, 1.62, 9.0), "target": Vector3(12.0, 2.2, 0.0)})
		plan.append({"name": "home_in", "pos": Vector3(33.0, 1.62, 31.4), "target": Vector3(40.5, 1.0, 41.5)})
		plan.append({"name": "edge", "pos": Vector3(79.0, 1.62, 36.0), "target": Vector3(66.0, 1.8, 36.0)})
		plan.append({"name": "stacks", "pos": Vector3(-12.0, 1.62, 6.0), "target": Vector3(-1.0, 1.4, 6.5)})
		plan.append({"name": "gallery", "pos": Vector3(20.5, GAL_EYE, 20.0), "target": Vector3(8.0, 4.0, 4.0)})
		plan.append({"name": "pit", "pos": _pit_shot(), "target": _pit_shot() + Vector3(4.5, -1.2, 4.5)})
	for s in plan:
		var p: Vector3 = s["pos"]
		s["prepare"] = func():
			world.build_around(p, 2)
			snap_env_to(p - Vector3.UP * 1.6)
	return plan


const GAL_EYE := 5.22


func _pit_shot() -> Vector3:
	for z in range(-2, 3):
		for x in range(-2, 3):
			if lib.stacks_desc(loc(x), loc(z))["kind"] == "pit" and not (loc(x) in [0, 1, 2] and loc(z) in [0, 1]):
				return Vector3(x * CS + 13.0, 1.62, z * CS + 13.0)
	return Vector3(-36, 1.62, -36)


func qa_self_test() -> Array:
	var out: Array = []
	var p0 := START
	# electricity fails: the flashlight dies the moment it is switched on
	player.flashlight_policy = "fails"
	player.toggle_flashlight()
	await get_tree().process_frame
	await get_tree().process_frame
	out.append({"what": "flashlight dies at once (all electricity fails)", "ok": not player.flashlight.visible})
	# the loop: the plan repeats every 6 chunks, so the main area recurs
	var same := lib.stacks_desc(3, 2) == lib.stacks_desc(loc(3 + N), loc(2 - N))
	var m0: Dictionary = world.meta_of(Vector2i(0, 0))
	out.append({"what": "plan repeats every 144 m (loop)", "ok": same and loc(6) == 0 and loc(-6) == 0 and m0.get("kind", "") == "centre"})
	out.append({"what": "main area carries 'the end is near' and eight terminals",
		"ok": m0.get("letters", []).size() > 0 and (m0["letters"][0] as Label3D).text == "the end is near" and m0.get("terminals", []).size() == 8})
	# walking one way through a seam, then turning around, meets a wall
	var seam_x := PERIOD - OFF
	player.global_position = Vector3(seam_x - 3.0, 0.05, 9.7)
	world.build_around(player.global_position, 1)
	period = period_of(player.global_position)
	player.rotation.y = -PI * 0.5
	await get_tree().physics_frame
	player.global_position = Vector3(seam_x + 3.0, 0.05, 9.7)
	world.build_around(player.global_position, 1)
	_seams(player.global_position)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var q := PhysicsRayQueryParameters3D.create(Vector3(seam_x + 1.0, 1.2, 9.7), Vector3(seam_x - 1.0, 1.2, 9.7), 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var wall_ok: bool = seam_set[0] and not hit.is_empty() and absf(float(hit["position"].x) - (seam_x + 0.15)) < 0.3
	out.append({"what": "after a loop seam, turning back meets a wall", "ok": wall_ok, "detail": hit.get("position", null)})
	out.append({"what": "loop counted", "ok": loops >= 1, "detail": loops})
	# random no-clip relocates inside the level and never exits
	TransitionService.qa_log.clear()
	player.global_position = Vector3(-36.0 + 12.0, 0.05, 6.0)
	world.build_around(player.global_position, 2)
	var before := player.global_position
	var moved := do_noclip("[qa]")
	for i in 3:
		await get_tree().physics_frame
	var dn := PhysicsRayQueryParameters3D.create(player.global_position + Vector3.UP, player.global_position + Vector3.DOWN, 1)
	out.append({"what": "random no-clip lands elsewhere in The End, on a floor, no exit", "ok": moved and before.distance_to(player.global_position) > 4.0 \
		and not get_world_3d().direct_space_state.intersect_ray(dn).is_empty() and TransitionService.qa_log.is_empty()})
	# fake realities blend and a breached border snaps back to normal
	snap_env_to(Vector3(36.0, 0.0, 36.0))
	var warm_ok := w_home > 0.95 and environment.ambient_light_color.b < 0.7
	snap_env_to(Vector3(60.0, 0.0, 36.0))
	var field_ok := w_field > 0.95
	_blend(local_of(Vector3(60.0, 0.0, 50.5)), false)
	out.append({"what": "fake realities blend in (home warm, field)", "ok": warm_ok and field_ok})
	out.append({"what": "breaching a fake reality's border returns to normal", "ok": breach_hold and w_field == 0.0 and w_home == 0.0})
	var cm: Dictionary = world.meta_of(Vector2i(2, 1))
	out.append({"what": "six Junkies perceivable in the field (humans, static)", "ok": cm.get("people", []).size() == 6})
	# the door is inconsistent outside the QA fixture; failure breaches into the stacks
	qa_fixture = false
	ev.seed = 7
	var res: Array = []
	for i in 12:
		player.global_position = Vector3(36.0, 0.05, 41.0)
		res.append(try_door("home"))
		await get_tree().process_frame
	qa_fixture = true
	out.append({"what": "fake-reality door is not consistent (some tries exit, most breach)", "ok": res.has(true) and res.has(false), "detail": res})
	# terminals: usable, discouraged, escalating
	_on_terminal(player)
	Overlay.close_all()
	var vis := 0
	for s in smiles:
		if is_instance_valid(s) and (s as Label3D).visible:
			vis += 1
	_on_terminal(player)
	Overlay.close_all()
	out.append({"what": "terminal use escalates (screens smile, buzz rises)", "ok": attention == 2 and vis >= 8})
	attention = 0
	# isolation grows far from the centre and decays in it
	iso = 0.0
	_isolation(60.0, false, 10.0)
	var far := iso
	_isolation(3.0, false, 10.0)
	out.append({"what": "isolation rises away from the centre, eases near it", "ok": far > 0.05 and iso < far, "detail": [far, iso]})
	iso = 0.0
	for a in 2:
		(seam_walls[a] as StaticBody3D).visible = false
		((seam_walls[a] as StaticBody3D).get_child(0) as CollisionShape3D).disabled = true
		seam_set[a] = false
	player.global_position = p0
	period = period_of(p0)
	snap_env_to(p0)
	Overlay.reset_screen_effects()
	return out
