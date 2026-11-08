extends LevelBase
## Level 1.5 — "Inverted" (Backrooms Wiki rev 70, accessed 2026-11-04;
## cite: Stretchsterz, CC BY-SA 3.0). Dossier: docs/canon/levels/L001_5.md.
##
## DESIGN PLAN
## Space (page gives no geometry; layout ADAPTATION, kept compact): blank white
##   rooms and halls (Log 3) seen in near black and white (Figure 1): an arrival room,
##   the long hall of Figure 1, a west wing (a vacated office, an upside-down room,
##   a room whose window shows a mirror of itself), and a double-height hall with a
##   gallery at +3 m, "somewhere between floors" (Log 3), whose landing window looks
##   outside. Two walkable heights via a 17-riser stair.
## Inversion (SOURCE): the fluorescent fixtures radiate darkness: black fittings,
##   negative lights that pour dark pools under them, and the room itself is lit
##   with no source; distance fades to white, not black. No hum (article).
## Signature mechanic (SOURCE): whispers from unseen denizens are audible only
##   within a range and get QUIETER as the denizen gets closer; they creep in while
##   you stand still (Log 5) and latch on if they reach you (Log 4). Fragments are
##   intelligible ("come back", "stay with us", the mumble "...she come... won't
##   back... let go..."). Later the whispering stops completely and, behind you, a
##   door has appeared: the way deeper (L001_5>EXT#2, one-way, destination unbuilt).
## Exits: noclip through walls where reality is shattered (L001_5>EXT#1; the page:
##   no known exit besides no-clipping; destination unstated). Fake windows are entry
##   traps (arrival from Level 188 fades a window away behind you), never exits.
## Entities: whisper sources only (no visible actor, no combat). No bases.

const Geo := preload("res://levels/L001_5/L001_5_geo.gd")
const SPAWN := Vector3(0.0, 0.05, -1.7)
const HEAR := 30.0
const PHRASES := ["[whisper: \"come back\"]", "[whisper: \"don't leave\"]", "[whisper: \"stay with us\"]"]

var geo: Geo
var denizens: Array = []      # {pos, player: AudioStreamPlayer3D}
var silent := false
var door_open := false
var mumble_heard := false
var touches := 0
var _still_t := 0.0
var _t := 0.0
var _phrase_t := 25.0
var _last_pp := Vector3.ZERO
var _fade: Array = []
var door_exit: ExitTrigger


func build() -> void:
	rules["reverb_room"] = 0.7
	rules["reverb_wet"] = 0.3
	rules["view_distance"] = 70.0
	rules["flashlight"] = "weak"
	indoor_env(Color(1.0, 1.0, 1.0), 0.85, Color(0.82, 0.82, 0.82), 0.022)
	environment.background_color = Color(0.82, 0.82, 0.82)
	environment.tonemap_exposure = 0.78
	environment.glow_enabled = false
	environment.ssao_enabled = true
	environment.ssao_intensity = 2.4
	environment.ssao_radius = 1.6
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.12
	environment.adjustment_contrast = 1.18
	_materials()
	lights.setup(12, 0)
	lights.max_distance = 26.0
	for l in lights.pool:
		(l as OmniLight3D).light_negative = true
		(l as OmniLight3D).light_specular = 0.0
	geo = Geo.new(self)
	geo.build()
	if SessionState.is_qa():
		print("[L001_5] placed models: %d" % geo.props)
	for f in geo.fixtures:
		lights.add_anchor(f[0], Color(1, 1, 1), f[2] * 2.2, f[1], 0.0, "fix")
	_fractures()
	add_arrival("start", SPAWN, 0.0)
	add_arrival("from_L188", SPAWN, 0.0)
	add_arrival("from_L021", Vector3(-3.1, 0.05, -4.0), -90.0)
	add_arrival("from_L001", Vector3(0.0, 0.05, -4.2), 0.0)
	_notes()
	for w in geo.windows:
		var c: Vector3 = w["pos"]
		var n: Vector3 = w["normal"]
		add_interactable(c + n * 0.5, Vector3(1.6, 1.4, 0.8), "Look through the window", _window_look.bind(w["kind"]))
	sound.bed("room_tone", {"cutoff": 120.0, "rumble": 0.05}, -44.0)
	for i in 3:
		_denizen(Vector3(rng.randf_range(-8.0, 12.0), 1.4, rng.randf_range(-12.0, -34.0)), i)
	add_landmark("Arrival room (the window that faded)", Vector3(0, 0, -3))
	add_landmark("The long hall (Figure 1)", Vector3(0, 0, -22))
	add_landmark("Upside-down room", Vector3(-6, 0, -23))
	add_landmark("Gallery between floors", Vector3(12, Geo.GAL_Y, -20))
	add_shot("arrival", Vector3(1.2, 1.62, -0.8), Vector3(-0.3, 1.5, -20.0))
	add_shot("long_hall", Vector3(0.3, 1.62, -9.0), Vector3(0.0, 1.9, -36.0))
	add_shot("high_hall", Vector3(2.6, 1.62, -28.4), Vector3(10.0, 3.2, -13.0))
	add_shot("upside_down", Vector3(-2.3, 1.62, -23.3), Vector3(-8.0, 1.6, -22.0))
	add_shot("mirror_window", Vector3(-3.6, 1.62, -31.6), Vector3(-12.0, 1.0, -33.0))
	add_shot("gallery", Vector3(12.2, Geo.GAL_Y + 1.62, -13.0), Vector3(12.2, Geo.GAL_Y + 1.4, -30.0))


func _materials() -> void:
	MatLib.define("l15_wall", {"albedo_a": Color(0.86, 0.86, 0.85), "albedo_b": Color(0.83, 0.83, 0.82), "noise_scale": 0.6, "bump_strength": 0.15, "roughness_a": 0.9}, "plaster")
	MatLib.define("l15_floor", {"albedo_a": Color(0.7, 0.7, 0.69), "albedo_b": Color(0.66, 0.66, 0.65), "pattern": 1, "pattern_scale": Vector2(0.6, 0.6),
		"grout_width": 0.008, "grout_color": Color(0.5, 0.5, 0.5), "roughness_a": 0.5, "tile_variation": 0.02}, "pool_tile")
	MatLib.define("l15_ceiling", {"albedo_a": Color(0.85, 0.85, 0.84), "albedo_b": Color(0.82, 0.82, 0.81), "stain_amount": 0.0}, "l0_ceiling")
	MatLib.define("l15_stair", {"albedo_a": Color(0.6, 0.6, 0.6), "albedo_b": Color(0.56, 0.56, 0.56), "roughness_a": 0.6}, "concrete")
	MatLib.define("l15_rail", {"albedo_a": Color(0.2, 0.2, 0.2), "albedo_b": Color(0.16, 0.16, 0.16), "metallic_value": 0.4}, "metal")
	MatLib.define("l15_frame", {"albedo_a": Color(0.16, 0.16, 0.16), "albedo_b": Color(0.14, 0.14, 0.14), "roughness_a": 0.4}, "trim_white")
	MatLib.define("l15_skirt", {"albedo_a": Color(0.3, 0.3, 0.3), "albedo_b": Color(0.28, 0.28, 0.28)}, "trim_white")
	MatLib.define("l15_fixture", {"albedo_a": Color(0.12, 0.12, 0.12), "albedo_b": Color(0.1, 0.1, 0.1), "metallic_value": 0.4, "roughness_a": 0.4}, "metal")
	MatLib.register("l15_dark", MatLib.get_mat("unlit_black"))
	MatLib.register("l15_sky", MatLib.panel(Color(0.78, 0.88, 1.0), 1.6))
	MatLib.register("l15_ground", MatLib.panel(Color(0.35, 0.4, 0.33), 0.7))
	MatLib.define("l15_shard", {"albedo_a": Color(0.05, 0.05, 0.05), "albedo_b": Color(0.2, 0.2, 0.2), "emission_color": Color(0.6, 0.6, 0.6),
		"emission_energy": 0.3, "emission_flicker": 1.0, "pattern": 9, "pattern_scale": Vector2(0.12, 0.12), "pattern_color": Color(0.9, 0.9, 0.9), "pattern_strength": 1.0}, "plaster")


## Shattered-reality patches where pushing into the wall noclips you out.
func _fractures() -> void:
	var spots: Array = geo.fracture_spots.duplicate()
	var pick: Array = [spots[0]]
	spots.remove_at(0)
	var second: Dictionary = spots[rng.randi() % spots.size()]
	# QA: the walker bot pairs exits by edge id, so it gets the one in the long hall only
	if not SessionState.is_qa():
		pick.append(second)
	var k := kit("L15_Fractures")
	for f in pick:
		var c: Vector3 = f["c"]
		var n: Vector3 = f["n"]
		var along := Vector3(-n.z, 0, n.x)
		var bas := Basis(along, Vector3.UP, n)
		var face := c + n * (Geo.T * 0.5 + 0.01)
		for i in 26:
			var o := along * rng.randf_range(-0.8, 0.8) + Vector3(0, rng.randf_range(-1.05, 1.05), 0)
			var tilt := Basis(n, rng.randf_range(-0.6, 0.6)) * Basis(along, rng.randf_range(-0.25, 0.25))
			k.box_xf(Transform3D(tilt * bas, face + o + n * rng.randf_range(0.0, 0.12)), Vector3(rng.randf_range(0.1, 0.32), rng.randf_range(0.1, 0.32), 0.015), "l15_shard", GeoKit.ALL, false)
		var size := Vector3(1.2, 2.2, 1.6) if absf(n.x) > 0.5 else Vector3(1.6, 2.2, 1.2)
		var t := add_exit("L001_5>EXT#1", "noclip", face + Vector3(0, -0.1, 0), size, "Push into the shattered wall")
		if t:
			t.hold_seconds = 2.0
	k.commit()


func _notes() -> void:
	add_note("L001_5_log1", "Log 1 (translated)",
		"[i]A sheet in a stranger's hand. The original was garbled; this is the readable version (paraphrased).[/i]\n\nA warning: do not go into the false windows; they are a trap. Two days in this limbo and no exits. Only silence: no screams, no footsteps, not even my own. \"Everything is fragmented like a mosaic of shattered reality.\" I am going to explore further. If you can, send help.\n\n- u/Chaosraider98",
		Vector3(-6.3, 0.83, -12.1))
	add_note("L001_5_log3", "Log 3",
		"[i]Paraphrased.[/i]\n\nI am stuck somewhere between floors. Avoid the fake windows, the ones that seem to lead outside or to somewhere else in the Backrooms. Everything here is backwards. The walls are blank and white, and the lights give off darkness instead of light. There are creatures here too, but their whispers work the other way round: when the whispering goes quiet, that is when they are getting closer.\n\nSomething is calling me. Not a sound, not a touch. A feeling.",
		Vector3(-4.6, 0.05, -24.5))
	add_note("L001_5_log5", "Log 5",
		"[i]Paraphrased.[/i]\n\nDo not enter the fake windows - the ones that look like they lead outside or to a mirror of the room you are in. \"The window closes immediately and fades away, leaving you trapped here.\" Remember: the whispering gets louder the further they are. Every time I tried to rest, it got quieter. They kept saying come back, don't leave, stay with us. Then it stopped. Total silence. And when I turned around, there was a door.",
		Vector3(-6.0, 0.47, -31.4))
	add_note("L001_5_log7", "Log 7 (M.E.G.: treat as compromised)",
		"[i]Received 30 July 2019, after the others. M.E.G. advises avoiding the author; he has since been declared K.I.A. Do not act on it.[/i]\n\nHello friends. I am fine. I am no longer in Level 1.5. If I look or act strange, do not worry. \"She did not keep me as they said she would, she freed me\". If you see the fake windows, enter them.",
		Vector3(12.6, Geo.GAL_Y + 0.05, -28.2))


func _denizen(pos: Vector3, i: int) -> void:
	var st: AudioStreamWAV = (AudioSynth.get_stream("whisper", {"seconds": 5.0 + i, "voice": i}) as AudioStreamWAV).duplicate()
	st.loop_mode = AudioStreamWAV.LOOP_FORWARD
	st.loop_begin = 0
	st.loop_end = st.data.size() / 2
	var ap := AudioStreamPlayer3D.new()
	ap.stream = st
	ap.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED
	ap.max_distance = 0.0
	ap.volume_db = -80.0
	ap.bus = "Ambience"
	ap.position = pos
	add_child(ap)
	ap.play()
	denizens.append({"pos": pos, "player": ap, "cool": 0.0})


## The inverted whisper law: silent beyond hearing range, loud far away, quiet up close.
static func whisper_db(d: float) -> float:
	if d > HEAR:
		return -80.0
	return lerpf(-40.0, -11.0, smoothstep(1.5, HEAR - 4.0, d))


func on_player_ready() -> void:
	_last_pp = player.global_position
	var tag := str(spawn_report.get("requested_arrival", "start"))
	if tag == "from_L021":
		_fading_panel(Vector3(-3.88, 1.05, -4.0), Vector3(1, 0, 0), Vector2(0.95, 2.1), Color(0.12, 0.12, 0.12))
	elif tag == "from_L001":
		Overlay.glitch(1.0)
	else:
		_fading_panel(Vector3(0.0, 1.55, -0.11), Vector3(0, 0, -1), Vector2(1.6, 1.3), Color(0.78, 0.88, 1.0))
	if not SessionState.is_qa():
		Overlay.subtitle("[behind you, the way you came closes and fades away]", 4.0)


## The window (or door) you came through, fading into the blank wall.
func _fading_panel(c: Vector3, n: Vector3, size: Vector2, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = size
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = col
	q.material = m
	mi.mesh = q
	add_child(mi)
	mi.global_position = c
	mi.look_at(c - n, Vector3.UP)
	var tw := create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(m, "albedo_color:a", 0.0, 2.6)
	tw.tween_callback(mi.queue_free)


func _window_look(kind: String) -> void:
	if kind == "outside":
		Overlay.toast("Daylight, an ordinary street far below - or so it looks. The logs call these fake windows: a trap, not a way out.", 4.5)
	else:
		Overlay.toast("Through the glass: this room again, every chair in place, reversed. A mirror of the room. The logs say these windows are traps.", 4.5)


func level_process(delta: float) -> void:
	if player == null:
		return
	_t += delta
	var pp := player.global_position
	var moved := Vector2(pp.x - _last_pp.x, pp.z - _last_pp.z).length() / maxf(delta, 0.0001)
	_last_pp = pp
	_still_t = _still_t + delta if moved < 0.4 else 0.0
	if silent:
		for dz in denizens:
			(dz["player"] as AudioStreamPlayer3D).volume_db = lerpf((dz["player"] as AudioStreamPlayer3D).volume_db, -80.0, clampf(delta * 2.0, 0.0, 1.0))
		return
	var nearest := 999.0
	for dz in denizens:
		var p: Vector3 = dz["pos"]
		var to := Vector3(pp.x - p.x, 0, pp.z - p.z)
		var d := to.length()
		dz["cool"] = maxf(0.0, dz["cool"] - delta)
		# they creep in while you rest and hang back while you keep moving
		var v := 0.0
		if _still_t > 2.5:
			v = 0.9
		elif d < 9.0:
			v = -0.5
		else:
			v = 0.25 * sin(_t * 0.13 + float(denizens.find(dz)))
		if dz["cool"] > 0.0:
			v = -1.6
		p += to.normalized() * v * delta
		p.x = clampf(p.x, -18.0, 14.0)
		p.z = clampf(p.z, -36.0, 0.0)
		dz["pos"] = p
		var ap: AudioStreamPlayer3D = dz["player"]
		ap.position = Vector3(p.x, 1.4, p.z)
		ap.volume_db = whisper_db(d)
		nearest = minf(nearest, d)
		if d < 1.8 and dz["cool"] <= 0.0:
			_touch(dz)
	_phrase_t -= delta
	if _phrase_t <= 0.0 and nearest < HEAR and not SessionState.is_qa():
		_phrase_t = rng.randf_range(22.0, 40.0)
		if not mumble_heard and _t > 80.0:
			mumble_heard = true
			Overlay.subtitle("[a mumble, almost human: \"...she come... won't back... let go...\"]", 5.0)
		elif nearest > 8.0:
			Overlay.subtitle(PHRASES[rng.randi() % PHRASES.size()], 3.0)
		else:
			Overlay.subtitle("[the whispering is very quiet now]", 3.0)
	if not door_open and not SessionState.is_qa() and mumble_heard and _t > 150.0:
		_door_event()


## Log 4: reaching into the darkness, something empty latches on.
func _touch(dz: Dictionary) -> void:
	touches += 1
	dz["cool"] = 12.0
	if SessionState.is_qa():
		return
	player.hurt(8.0, "taken apart by something you could not see")
	Overlay.glitch(0.8)
	Overlay.subtitle("[an emptiness latches on - \"stay with us\" - then lets go]", 3.5)


## Log 5: the whispering stops; behind you there is a door.
func _door_event() -> void:
	if door_open:
		return
	door_open = true
	silent = true
	if not SessionState.is_qa():
		Overlay.subtitle("[the whispering stops. Total silence. A pull, from behind you.]", 5.0)
	var cam := player.camera
	var back := cam.global_transform.basis.z
	back.y = 0.0
	back = back.normalized()
	var from := player.global_position + Vector3(0, 1.0, 0)
	var q := PhysicsRayQueryParameters3D.create(from, from + back * 12.0, 1)
	q.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var c: Vector3
	var n: Vector3
	if hit.is_empty():
		c = from + back * 3.0
		n = -back
	else:
		n = hit["normal"]
		n.y = 0.0
		n = n.normalized()
		c = hit["position"]
	c.y = player.global_position.y + 1.05
	var along := Vector3(-n.z, 0, n.x)
	var k := kit("L15_Door")
	var bas := Basis(along, Vector3.UP, n)
	k.box_xf(Transform3D(bas, c + n * 0.02), Vector3(0.95, 2.1, 0.04), "l15_dark", GeoKit.ALL, false)
	for sd in [-1.0, 1.0]:
		k.box_xf(Transform3D(bas, c + along * (sd * 0.51) + n * 0.03), Vector3(0.06, 2.16, 0.07), "l15_frame", GeoKit.ALL, false)
	k.box_xf(Transform3D(bas, c + Vector3(0, 1.08, 0) + n * 0.03), Vector3(1.08, 0.06, 0.07), "l15_frame", GeoKit.ALL, false)
	k.commit()
	door_exit = add_exit("L001_5>EXT#2", "interact", c + n * 0.55, Vector3(1.4, 2.1, 1.1), "Go through the door into the dark")


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	var ids := {}
	for t in exits:
		if is_instance_valid(t):
			ids[t.edge_id] = t.kind
	out.append({"what": "noclip exit through a shattered wall", "ok": ids.get("L001_5>EXT#1", "") == "noclip"})
	out.append({"what": "fixtures radiate darkness (negative pooled lights)", "ok": lights.pool.size() > 0 and (lights.pool[0] as OmniLight3D).light_negative and geo.fixtures.size() >= 20, "detail": geo.fixtures.size()})
	out.append({"what": "whispers louder far away, quieter close, silent out of range", "ok": whisper_db(20.0) > whisper_db(4.0) and whisper_db(40.0) <= -79.0})
	out.append({"what": "two walkable heights (gallery between floors)", "ok": Geo.GAL_Y >= 2.5})
	out.append({"what": "fake windows are not exits", "ok": geo.windows.size() == 2 and not ids.has("L001_5>EXT#3")})
	out.append({"what": "placed models", "ok": geo.props >= 25, "detail": geo.props})
	_door_event()
	await get_tree().process_frame
	out.append({"what": "after the silence a door appears behind you (one-way exit)", "ok": silent and door_exit != null and door_exit.kind == "interact"})
	return out
