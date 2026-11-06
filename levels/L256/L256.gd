extends LevelBase
## Level 256 — "Demoscene" (Backrooms Wikidot rev 46, accessed 2026-11-04; by
## etoisle, CC BY-SA 3.0). Dossier: docs/canon/levels/L256.md.
##
## SOURCE: the 257th Level, an abandoned technological demonstration and
## exhibition center; entirely indoors; windows onto a featureless dark;
## modern interiors, neon blue lighting, artistic fixtures; all doors locked
## (a kicked door shows more wall); terminals branded with game franchises
## that show something else: faint static (most common), a distorted
## recording of the viewer, early 3D demos, banal games with no ending, loud
## distorted tones on a black screen; nobody here; entered by clipping through
## Level 4; no exit found. Draft-3 testimony: the terminals turn on by
## themselves, nothing moves but the screens, the air does not move, clocks
## do not tick and change time when unwatched (all 00:00, then normal), the
## dark outside is heavy, "its not the sky", and the upload fails because
## user isle4 does not exist. NO ENTITY PER SOURCE.
## ADAPTATION (level.json notes): the plan, the drafting terminal, the dread
## system that writes the three drafts, the theatre's sine scroller.

const Shaders := preload("res://levels/L256/L256_shaders.gd")
const World := preload("res://levels/L256/L256_world.gd")
const Draft := preload("res://levels/L256/L256_draft.gd")

const ARRIVE := Vector3(15.0, 4.5, -2.4)
const PACK := Vector3(15.5, 4.5, -0.8)
const VIEWER_LAYER := 1 << 19
const STAGE := [0.0, 0.34, 0.67]
const KEY_OF := {1: "static", 2: "viewer", 3: "demo", 4: "game", 5: "tone"}
const SCROLL := ["   *** GREETINGS TO EVERYONE WHO CAN SEE THIS ***   NO ONE ELSE HERE   ***   KEEP LOOKING   ***",
	"   *** IS ANYONE WATCHING THIS ***   ARE THESE EVEN UPLOADING   ***   THERE HAS TO BE SOMETHING   ***",
	"   *** PLEASE IF YOU CAN SEE THIS SEND ME A MESSAGE   DO SOMETHING ***   ITS TOO DARK   ***",
	"   *** USER ISLE4 DOES NOT EXIST ***   USER ISLE4 DOES NOT EXIST ***   "]

var world: World
var draft: Draft
var mats := {}
var rt := RandomNumberGenerator.new()
var qa_fixture := false
var dread := 0.0
var stage := 1
var gone := false
var heavy := 0.0
var gaze_t := 0.0
var still_t := 0.0
var plays := 0
var scare_at := 5
var scares := 0
var tones := 0
var logged := {}
var feed_vp: SubViewport
var feed_cam: Camera3D
var viewer_body: Node3D
var _clock := 0.0
var _tick := 0.0
var _scroll := 0.0
var _zero_t := -1.0
var _jump_seen := false
var _jump_t := -99.0
var _sky_said := false
var _lock := false
var _anchor_base: Array = []
var _kiosk_anchor := {}
var _pressure: AudioStreamPlayer
var _chip_said := false
var _tone_stream: AudioStreamWAV
var _kill_t := -1.0


func build() -> void:
	qa_fixture = SessionState.is_qa()
	rt.seed = hash([level_seed, "screens"])
	rules["view_distance"] = 120.0
	rules["reverb_room"] = 0.7
	rules["reverb_wet"] = 0.2
	rules["flashlight"] = "allowed"
	indoor_env(Color(0.14, 0.2, 0.42), 0.26, Color(0.015, 0.025, 0.07), 0.012)
	environment.background_color = Color(0, 0, 0)
	environment.tonemap_exposure = 1.0
	environment.glow_enabled = true
	environment.glow_intensity = 0.75
	environment.glow_bloom = 0.08
	environment.glow_hdr_threshold = 0.9
	environment.ssr_enabled = Settings.quality() >= 2
	environment.ssr_max_steps = 48
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.08
	environment.adjustment_saturation = 1.05
	mats = World.materials()
	var sh := Shader.new()
	sh.code = Shaders.SCREEN
	world = World.new(self, rng, sh)
	world.build_all()
	_lights()
	_feed()
	for d in world.doors:
		var door: Dictionary = d
		door["it"] = add_interactable(door["pos"] + door["n"] * 0.4 + Vector3(0, 1.1, 0), Vector3(1.1, 2.0, 0.6), "Try the door", func(_p): _door(door))
	for kd in world.kiosks:
		var kk: Dictionary = kd
		kk["it"] = add_interactable(kk["face"] + kk["fwd"] * 0.35, Vector3(0.9, 0.7, 0.5), "Look at the screen", func(_p): _watch(kk))
		if kk["prog"] == 4:
			kk["it"].prompt = "Play"
		(kk["mat"] as ShaderMaterial).set_shader_parameter("feed", feed_vp.get_texture())
	add_interactable(PACK + Vector3(0, 0.3, 0), Vector3(0.9, 0.6, 0.9), "Read the M.E.G. terminal", func(_p): _read_terminal())
	add_arrival("start", ARRIVE, 90.0)
	add_arrival("from_L004", ARRIVE, 90.0)
	draft = Draft.new()
	draft.name = "MEGTerminal"
	add_child(draft)
	draft.setup(hash([level_seed, "isle4"]))
	_pressure = sound.bed("room_tone", {"cutoff": 55.0, "rumble": 1.2, "seconds": 6.0}, -80.0)
	sound.emitter("chiptune", world.theatre_screen + Vector3(5.0, -1.0, 0), {"bpm": 140.0, "scale": [0, 3, 5, 7, 10, 12, 15], "root": 220.0}, -13.0, 24.0)
	_tone_stream = World.make_tone()
	for kd in world.kiosks:
		if kd["on"]:
			_hum(kd)
	add_landmark("Gallery (where you came through)", ARRIVE)
	add_landmark("Screen totem", Vector3(-2, 0, -3))
	add_landmark("Theatre screen", world.theatre_screen)
	add_landmark("Viewer room", Vector3(-22, 0, -10))
	add_shot("gallery", Vector3(14.6, GAL_EYE(), -1.6), Vector3(-5.0, 1.8, -10.5),
		{"prepare": func(): await _pose(0.2, ["A:Level n is the (n+1)'nd Level of the Backrooms. It [fill this in later]",
			"N:was in level 4 and i clipped through. so that's a way in. no one else here."])})
	add_shot("theatre", Vector3(-18.4, 1.55, 8.4), Vector3(-29.0, 1.4, 0.6),
		{"prepare": func(): await _pose(0.8, ["A:Level 256: an abandoned technological exhibition center.",
			"N:they turn on on their own now. i can't see anything moving.", "N:nothing moves here but the screens", "N:its too dark"])})


static func GAL_EYE() -> float:
	return World.GAL_Y + 1.6


func _lights() -> void:
	lights.setup(14, 1)
	var blue := Color(0.25, 0.45, 1.0)
	for x in [-12.0, -4.0, 4.0, 12.0]:
		for z in [-9.0, 0.0, 7.0]:
			lights.add_anchor(Vector3(x, 6.8, z), blue, 2.6, 13.0)
	for i in 4:
		lights.add_anchor(Vector3(-2, 3.6, -3) + Basis(Vector3.UP, i * PI * 0.5) * Vector3(0, 0, 2.6), Color(0.6, 0.7, 1.0), 1.6, 7.0)
	lights.add_anchor(Vector3(5.0, 3.5, -9.7), Color(0.4, 0.62, 1.0), 1.2, 8.0)
	lights.add_anchor(world.theatre_screen + Vector3(3.5, -0.5, 0), Color(0.5, 0.6, 1.0), 1.8, 13.0)
	lights.add_anchor(world.theatre_screen + Vector3(4.5, -2.5, -3.0), Color(0.55, 0.6, 1.0), 1.4, 9.0)
	lights.add_anchor(world.theatre_screen + Vector3(4.5, -2.5, 6.0), Color(0.75, 0.5, 1.0), 1.2, 9.0)
	lights.add_anchor(Vector3(-21.0, 1.0, 6.0), blue, 0.8, 7.0)
	lights.add_anchor(Vector3(-22.0, 3.2, -10.0), blue, 0.9, 8.0)
	lights.add_anchor(Vector3(13.0, 7.2, -6.0), blue, 1.0, 8.0)
	for x in [-11.0, -2.0, 7.0]:
		lights.add_anchor(Vector3(x, 2.6, 12.3), blue, 0.8, 6.5)
	for a in lights.anchors:
		_anchor_base.append(a["energy"])
	for kd in world.kiosks:
		var idx := lights.add_anchor(kd["face"] + kd["fwd"] * 0.6, Color(0.55, 0.65, 0.95), 0.9 if kd["on"] else 0.0, 4.5)
		_kiosk_anchor[kd["face"]] = idx
		_anchor_base.append(0.9)


## The recording of the viewer: a small camera that looks back at you from
## whichever recording terminal is nearest; it sees a figure where you stand.
func _feed() -> void:
	feed_vp = SubViewport.new()
	feed_vp.size = Vector2i(192, 144)
	feed_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(feed_vp)
	feed_cam = Camera3D.new()
	feed_cam.fov = 62.0
	feed_cam.far = 60.0
	feed_vp.add_child(feed_cam)
	viewer_body = Node3D.new()
	viewer_body.name = "ViewerOnScreen"
	add_child(viewer_body)
	var dark := MatLib.standard(Color(0.08, 0.08, 0.1), 0.7)
	for part in [[CapsuleMesh.new(), Vector3(0, 0.82, 0)], [SphereMesh.new(), Vector3(0, 1.62, 0)]]:
		var mi := MeshInstance3D.new()
		mi.mesh = part[0]
		if part[0] is CapsuleMesh:
			(mi.mesh as CapsuleMesh).radius = 0.24
			(mi.mesh as CapsuleMesh).height = 1.5
		else:
			(mi.mesh as SphereMesh).radius = 0.13
			(mi.mesh as SphereMesh).height = 0.26
		mi.material_override = dark
		mi.layers = VIEWER_LAYER
		mi.position = part[1]
		viewer_body.add_child(mi)


func _hum(kd: Dictionary) -> void:
	if kd["prog"] == 1 or kd["prog"] == 3:
		kd["hum"] = sound.emitter("static", kd["face"], {"seconds": 3.0}, -32.0, 5.0)


# ------------------------------------------------------------- the drafts

func _w(line: String, delay := 0.0) -> void:
	draft.write(line.substr(2), {"A": "article", "N": "note", "T": "term"}.get(line[0], "note"), delay)


## Write what a discovery means into the current draft, once per draft.
func _log(key: String) -> void:
	var tag := "%s%d" % [key, stage]
	if logged.has(tag) or gone:
		return
	logged[tag] = true
	for line in Draft.TEXT[key][stage - 1]:
		_w(line)


func _bump(amount: float) -> void:
	if not gone:
		dread = clampf(dread + amount, 0.0, 1.0)


func _stage_tick() -> void:
	var want := 1 + int(dread >= STAGE[1]) + int(dread >= STAGE[2])
	while stage < want:
		for line in Draft.EXITS[stage - 1]:
			_w(line)
		_w("T:uploading draft %d ... sent. no reply." % stage)
		stage += 1
		draft.new_draft(stage, "")
		for line in Draft.HEADERS[stage - 1]:
			_w(line)
		_save("stage", stage)
	if stage == 3 and dread >= 0.999 and not gone:
		_upload_fails()


## SOURCE (the page's last lines): the upload is aborted, retried, and the
## author's account does not exist. Nothing else changes: there is no way out.
func _upload_fails() -> void:
	_log("sorry")
	for line in Draft.EXITS[2]:
		_w(line)
	_w("T:Upload aborted due to unexpected error. Try again? [Y/N]", 1.0)
	_w("T:>Y", 1.5)
	_w("T:ERROR: Authentication failed. User isle4 does not exist.", 1.5)
	gone = true
	_save("gone", true)
	_kill_t = 9.0
	for kd in world.kiosks:
		_set_prog(kd, 1)


func _read_terminal() -> void:
	var t := "4 documents matching the ID of isle4.\n\n"
	t += "\n".join(draft.lines)
	Overlay.show_note("M.E.G. Mobile Terminal AE4", t)


# -------------------------------------------------------------- terminals

func _set_prog(kd: Dictionary, prog: int) -> void:
	var m: ShaderMaterial = kd["mat"]
	var was_on: bool = kd["on"]
	kd["prog"] = prog
	kd["on"] = true
	m.set_shader_parameter("program", prog)
	if not was_on:
		kd["boot"] = 0.0
		lights.anchors[_kiosk_anchor[kd["face"]]]["energy"] = 0.9
		_hum(kd)
		sound.play_at("ui", {"kind": "click"}, kd["face"], -10.0, "[somewhere, a terminal switches itself on]")
	if kd.has("it"):
		(kd["it"] as Interactable).prompt = "Play" if prog == 4 else "Look at the screen"


func _watch(kd: Dictionary) -> void:
	if not kd["on"]:
		Overlay.subtitle("[the screen is dark. your own shape in the glass]", 3.0)
		return
	var prog: int = kd["prog"]
	if prog == 4:
		_play(kd)
		return
	var cap := {1: "[faint static]", 2: "[the screen shows someone standing where you stand]", 3: "[a crude 3D shape turns over and over]", 5: "[a blank black screen]"}
	Overlay.subtitle(cap.get(prog, ""), 3.0)
	if prog == 5:
		_tone(kd)
	_seen(kd)


func _seen(kd: Dictionary) -> void:
	if not kd["seen"]:
		kd["seen"] = true
		_bump(0.03)
	_log(KEY_OF[kd["prog"]])


## A banal game with no ending; one of them is waiting to scare you (SOURCE
## testimony: "that scared the shit out of me"). ADAPTATION: what it does.
func _play(kd: Dictionary) -> void:
	plays += 1
	_jump_t = _clock
	(kd["mat"] as ShaderMaterial).set_shader_parameter("jump_t", _clock)
	sound.play_at("ui", {"kind": "hover"}, kd["face"], -12.0)
	_seen(kd)
	if plays >= scare_at:
		plays = 0
		scare_at = 6 + rt.randi() % 5
		scares += 1
		kd["scare"] = 1.0
		_tone(kd, true)
		_bump(0.08)
		_log("scare")


func _tone(kd: Dictionary, force := false) -> void:
	if kd["cool"] > 0.0 and not force:
		return
	kd["cool"] = 25.0
	tones += 1
	var p := AudioStreamPlayer3D.new()
	p.stream = _tone_stream
	p.bus = "SFX"
	p.volume_db = 2.0
	p.max_distance = 40.0
	add_child(p)
	p.global_position = kd["face"]
	p.play()
	p.finished.connect(p.queue_free)
	Overlay.subtitle("[an extremely loud, distorted electronic tone]", 2.4)
	Overlay.glitch(0.35)
	_bump(0.05)
	_log("tone")


# ------------------------------------------------------------------ doors

## SOURCE: all doors are locked; kicked down, there is just more wall behind.
func _door(d: Dictionary) -> void:
	if d["kicked"]:
		return
	d["tries"] += 1
	if d["tries"] == 1:
		sound.play_at("knock", {"hits": 2}, d["pos"] + Vector3(0, 1, 0), -8.0, "[the handle won't move. locked]")
		(d["it"] as Interactable).prompt = "Kick the door"
		_log("door")
		return
	_kick(d, false)


func _kick(d: Dictionary, quiet: bool) -> void:
	d["kicked"] = true
	(d["it"] as Interactable).prompt = ""
	(d["it"] as Interactable).collision_layer = 0
	var leaf: MeshInstance3D = d["leaf"]
	var b: Basis = d["b"]
	var pivot: Vector3 = d["pos"] + d["n"] * 0.026 + Vector3(0, 0.025, 0)
	var axis: Vector3 = b.x
	if quiet:
		leaf.global_transform = Transform3D(b.rotated(axis, PI * 0.5), pivot + Basis(axis, PI * 0.5) * Vector3(0, 1.04, 0))
		return
	var tw := create_tween()
	tw.tween_method(func(a: float):
		leaf.global_transform = Transform3D(b.rotated(axis, a), pivot + Basis(axis, a) * Vector3(0, 1.04, 0)), 0.0, PI * 0.5, 0.45).set_ease(Tween.EASE_IN)
	sound.play_at("knock", {"hits": 1}, d["pos"] + Vector3(0, 0.5, 0), 0.0, "[the door slams flat. behind it: wall]")
	_bump(0.04)
	_log("kick")
	_save("kicked_" + d["id"], true)


# ---------------------------------------------------------------- runtime

func on_player_ready() -> void:
	player.camera.cull_mask &= ~VIEWER_LAYER
	if SessionState.is_story():
		stage = int(SaveService.flag(stable_id, "stage", 1))
		dread = STAGE[stage - 1]
		gone = bool(SaveService.flag(stable_id, "gone", false))
		for d in world.doors:
			if SaveService.flag(stable_id, "kicked_" + d["id"], false):
				_kick(d, true)
	draft.new_draft(stage, "")
	if gone:
		dread = 1.0
		_w("T:ERROR: Authentication failed. User isle4 does not exist.")
		draft.kill()
		for kd in world.kiosks:
			_set_prog(kd, 1)
		return
	for line in Draft.HEADERS[stage - 1]:
		_w(line, 1.5)
	if qa_fixture:
		return
	# SOURCE entrance: you clipped through Level 4 and came out of this wall.
	Overlay.glitch(0.9)
	_log("arrive")


func level_process(delta: float) -> void:
	if player == null:
		return
	_clock += delta
	if _kill_t > 0.0:
		_kill_t -= delta
		if _kill_t <= 0.0:
			draft.kill()
	var cam := player.camera
	var p := player.global_position
	viewer_body.global_position = p
	viewer_body.rotation.y = player.rotation.y
	_scroller(delta)
	for kd in world.kiosks:
		var m: ShaderMaterial = kd["mat"]
		m.set_shader_parameter("now", _clock)
		if kd.has("boot"):
			kd["boot"] = minf(1.0, kd["boot"] + delta * 1.5)
			m.set_shader_parameter("boot", kd["boot"])
		if kd.get("scare", 0.0) > 0.0:
			kd["scare"] = maxf(0.0, kd["scare"] - delta * 0.6)
			m.set_shader_parameter("scare", kd["scare"])
		kd["cool"] = maxf(0.0, kd["cool"] - delta)
	if _lock:
		_aim_feed(cam.global_position)
		_apply(delta)
		return
	var moving := Vector2(player.velocity.x, player.velocity.z).length() > 0.2
	still_t = 0.0 if moving else still_t + delta
	# the dark outside: staring into it is heavy
	var gazing := _gazing(cam)
	gaze_t = gaze_t + delta if gazing else maxf(0.0, gaze_t - delta * 2.0)
	heavy = move_toward(heavy, clampf(gaze_t / 6.0, 0.0, 1.0) * (0.5 + dread * 0.5), delta * 0.5)
	if gazing:
		_bump(0.02 * delta)
		if gaze_t > 1.5:
			_log("windows")
		if stage == 3 and gaze_t > 8.0:
			_log("stare")
		if gone and gaze_t > 4.0 and not _sky_said:
			_sky_said = true
			draft.dead = false
			draft.write("its not the sky", "note")
			_kill_t = 6.0
	# time alone wears on the volunteer; stillness in the end most of all
	_bump(delta / 420.0)
	if stage == 3 and still_t > 3.0:
		_bump(delta * 0.003)
	if stage == 3 and still_t > 14.0:
		_log("still")
	if p.distance_to(PACK) < 2.5 and still_t > 2.0:
		dread = maxf(STAGE[stage - 1], dread - delta * 0.01)
		if stage == 3 and not logged.has("safe3"):
			_log("safe")
			checkpoint("safe_place")
	if _clock > 14.0:
		_log("dark")
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.15
		_terminals_tick(cam, p, 0.15)
		_clocks_tick(cam, 0.15)
		_stage_tick()
	if not _chip_said and p.distance_to(world.theatre_screen) < 16.0:
		_chip_said = true
		Overlay.subtitle("[tinny chiptune music from the big screen]", 3.0)
	_apply(delta)


func _gazing(cam: Camera3D) -> bool:
	var o := cam.global_position
	var f := -cam.global_basis.z
	for w in world.windows:
		var n: Vector3 = w["n"]
		var dn := f.dot(n)
		if dn > -0.55:
			continue
		var t: float = (w["c"] - o).dot(n) / dn
		if t <= 0.0 or t > 11.0:
			continue
		var hit: Vector3 = o + f * t - w["c"]
		var hu: Vector3 = w["hu"]
		var hv: Vector3 = w["hv"]
		if absf(hit.dot(hu.normalized())) < hu.length() and absf(hit.dot(hv.normalized())) < hv.length():
			return true
	return false


func _terminals_tick(cam: Camera3D, p: Vector3, dt: float) -> void:
	var o := cam.global_position
	var f := -cam.global_basis.z
	for kd in world.kiosks:
		if not kd["on"] and dread >= kd["wake"] and kd["wake"] > 0.0:
			_set_prog(kd, kd["prog"])
			if stage == 3:
				_log("wake")
		if not kd["on"]:
			continue
		var to: Vector3 = kd["face"] - o
		var dist := to.length()
		var facing: bool = f.dot(to / maxf(dist, 0.01)) > 0.85 and (kd["fwd"] as Vector3).dot(-to) > 0.2
		if dist < 3.0 and facing:
			kd["near_t"] += dt
			if kd["near_t"] > 1.2:
				if kd["prog"] == 5:
					_tone(kd)
				_seen(kd)
		else:
			kd["near_t"] = 0.0
		# Draft 3: screens change on their own while nobody is looking
		if stage == 3 and not gone and kd["prog"] != 4:
			var seen := cam.is_position_in_frustum(kd["face"]) and dist < 25.0
			kd["unseen"] = 0.0 if seen else kd["unseen"] + dt
			if kd["unseen"] > 9.0:
				kd["unseen"] = 0.0
				_set_prog(kd, [1, 1, 1, 2, 3, 5][rt.randi() % 6])
	_aim_feed(o)


## Aim the recording at the viewer from the nearest lit recording terminal.
func _aim_feed(o: Vector3) -> void:
	var feed_k: Dictionary = {}
	var best := 14.0
	for kd in world.kiosks:
		if kd["on"] and kd["prog"] == 2 and (kd["face"] as Vector3).distance_to(o) < best:
			best = (kd["face"] as Vector3).distance_to(o)
			feed_k = kd
	if feed_k.is_empty():
		feed_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	feed_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var eye: Vector3 = feed_k["face"] + Vector3(0, 0.4, 0) + feed_k["fwd"] * 0.1
	if eye.distance_to(o) > 0.3:
		feed_cam.look_at_from_position(eye, o - Vector3(0, 0.4, 0), Vector3.UP)


## SOURCE testimony: the clocks don't tick; looked away from, they show another
## time; once they all read 00:00, then went back to normal.
func _clocks_tick(cam: Camera3D, dt: float) -> void:
	var space := get_world_3d().direct_space_state
	var any_seen := false
	for c in world.clocks:
		var pos: Vector3 = c["pos"]
		var o := cam.global_position
		var seen := cam.is_position_in_frustum(pos) and o.distance_to(pos) < 22.0
		if seen:
			var q := PhysicsRayQueryParameters3D.create(o, pos + (o - pos).normalized() * 0.2, 1)
			q.exclude = [player.get_rid()]
			seen = space.intersect_ray(q).is_empty()
		var l: Label3D = c["label"]
		if seen:
			any_seen = true
			if o.distance_to(pos) < 10.0:
				_log("clocks")
			if c.get("moved", false):
				c["moved"] = false
				_log("clock_jump")
				_jump_seen = true
			c["unseen"] = 0.0
		else:
			c["unseen"] += dt
			if stage == 3 and _zero_t < 0.0 and c["unseen"] > 2.5 and l.text != "00:00":
				l.text = "%02d:%02d" % [rt.randi() % 24, rt.randi() % 60]
				c["moved"] = true
				c["unseen"] = 0.0
	if stage == 3 and _jump_seen and _zero_t < 0.0 and any_seen and rt.randf() < 0.02:
		_zero_t = 6.0
		for c in world.clocks:
			(c["label"] as Label3D).text = "00:00"
		_log("zero")
	if _zero_t > 0.0:
		_zero_t -= dt
		if _zero_t <= 0.0:
			_zero_t = 0.0
			for c in world.clocks:
				(c["label"] as Label3D).text = c["base"]


## The theatre's demo: a classic sine scroller over the big screen.
func _scroller(delta: float) -> void:
	_scroll += delta * 1.6
	var text: String = SCROLL[3] if gone else SCROLL[stage - 1]
	var cw := 0.36
	var first := int(_scroll / cw)
	var frac := fmod(_scroll, cw)
	var sc := world.theatre_screen
	for i in world.scroller.size():
		var l: Label3D = world.scroller[i]
		var z := sc.z + 5.4 - (i * cw - frac)
		l.position = Vector3(sc.x + 0.06, sc.y - 1.5 + sin(_clock * 2.3 + z * 0.55) * 0.42, z)
		l.text = text[(first + i) % text.length()]
		l.visible = absf(z - sc.z) < 5.3


func _apply(_delta: float) -> void:
	var dim := 1.0 - dread * 0.5
	(mats["l256_neon"] as ShaderMaterial).set_shader_parameter("dim", dim)
	(mats["l256_neon_soft"] as ShaderMaterial).set_shader_parameter("dim", dim * (1.0 - heavy * 0.3))
	var w: ShaderMaterial = mats["window"]
	w.set_shader_parameter("heavy", heavy)
	w.set_shader_parameter("dark", dread)
	for i in _anchor_base.size():
		if i < lights.anchors.size() and lights.anchors[i]["energy"] > 0.0:
			lights.anchors[i]["energy"] = _anchor_base[i] * lerpf(1.0, 0.45, dread)
	environment.ambient_light_energy = lerpf(0.34, 0.12, dread)
	environment.tonemap_exposure = lerpf(1.0, 0.78, dread) * (1.0 - heavy * 0.25)
	Overlay.set_screen_effect("vignette", 0.25 + dread * 0.2 + heavy * 0.55)
	Overlay.set_screen_effect("desaturate", heavy * 0.35)
	if _pressure:
		_pressure.volume_db = lerpf(-60.0, -12.0, heavy) if heavy > 0.02 else -80.0
	draft.corrupt = clampf((dread - 0.6) / 0.4, 0.0, 1.0)
	for kd in world.kiosks:
		(kd["mat"] as ShaderMaterial).set_shader_parameter("dread", dread)


func _save(key: String, value: Variant) -> void:
	if SessionState.is_story():
		SaveService.set_flag(stable_id, key, value)


# --------------------------------------------------------------------- QA

func _pose(d: float, shown: Array) -> void:
	_lock = true
	dread = d
	stage = 1 + int(d >= STAGE[1]) + int(d >= STAGE[2])
	for kd in world.kiosks:
		if kd["wake"] <= d and not kd["on"]:
			_set_prog(kd, kd["prog"])
		kd["boot"] = 1.0
	heavy = 0.0
	_apply(0.0)
	draft.pose(stage, shown)
	await get_tree().process_frame


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	var movers := find_children("*", "CharacterBody3D", true, false).filter(func(n): return n != player)
	var rigid := find_children("*", "RigidBody3D", true, false)
	out.append({"what": "no entity: nothing moves here but the screens", "ok": movers.is_empty() and rigid.is_empty(), "detail": [movers.size(), rigid.size()]})
	out.append({"what": "no exit is built (none found per source)", "ok": exits.is_empty() and manifest.get("exits", []).is_empty()})
	var progs := {}
	for kd in world.kiosks:
		progs[kd["prog"]] = int(progs.get(kd["prog"], 0)) + 1
	var stat_most := true
	for kp in progs:
		if kp != 1 and progs[kp] >= progs.get(1, 0):
			stat_most = false
	out.append({"what": "all five sourced programs exist; static is the most common", "ok": progs.has(1) and progs.has(2) and progs.has(3) and progs.has(4) and progs.has(5) and stat_most, "detail": progs})
	var space := get_world_3d().direct_space_state
	var hits := 0
	for w in world.windows:
		var from: Vector3 = w["c"] - w["n"] * 0.3
		var q := PhysicsRayQueryParameters3D.create(from, from - w["n"] * 300.0, 0xFFFFFFFF)
		hits += int(not space.intersect_ray(q).is_empty())
	out.append({"what": "beyond the windows there is nothing at all (featureless dark)", "ok": hits == 0 and world.windows.size() >= 2})
	var d: Dictionary = world.doors[0]
	_door(d)
	var locked: bool = not d["kicked"]
	_door(d)
	await get_tree().create_timer(0.6).timeout
	var at: Vector3 = d["pos"] + d["n"] * 0.6 + Vector3(0, 1.2, 0)
	var qd := PhysicsRayQueryParameters3D.create(at, at - d["n"] * 1.5, 1)
	qd.exclude = [player.get_rid()]
	var wall := space.intersect_ray(qd)
	out.append({"what": "a door is locked; kicked down there is only more wall", "ok": locked and d["kicked"] and not wall.is_empty() and absf(((wall["position"] as Vector3) - d["pos"]).dot(d["n"])) < 0.1})
	var floors := []
	for pt in [Vector3(14.0, 6.0, -6.0), Vector3(0.0, 2.0, 0.0), Vector3(-27.5, 1.0, 2.0)]:
		var r := space.intersect_ray(PhysicsRayQueryParameters3D.create(pt, pt + Vector3.DOWN * 5.0, 1))
		floors.append(snappedf((r.get("position", Vector3(0, -99, 0)) as Vector3).y, 0.05))
	out.append({"what": "three walkable heights: gallery, atrium, sunken theatre", "ok": floors == [4.5, 0.0, -1.8], "detail": floors})
	var on0 := world.kiosks.filter(func(x): return x["on"]).size()
	var g: Dictionary = world.kiosks.filter(func(x): return x["prog"] == 4)[0]
	for i in scare_at:
		_play(g)
	out.append({"what": "the endless game scares you (loud tone, viewer flash)", "ok": scares == 1 and g["scare"] > 0.5 and tones >= 1})
	var b: Dictionary = world.kiosks.filter(func(x): return x["prog"] == 5)[0]
	var t0 := tones
	player.global_position = b["face"] + b["fwd"] * 1.6 - Vector3(0, Player.EYE_STAND - 0.1, 0)
	player.look_at(Vector3(b["face"].x, player.global_position.y, b["face"].z), Vector3.UP)
	player.rotation.x = 0.0
	player.head.rotation.x = -0.3
	b["cool"] = 0.0
	for i in 12:
		_terminals_tick(player.camera, player.global_position, 0.15)
	out.append({"what": "a black screen blasts its tone when you face it", "ok": tones > t0, "detail": [t0, tones]})
	var s0 := stage
	dread = 0.3
	_bump(0.1)
	_stage_tick()
	_terminals_tick(player.camera, player.global_position, 0.15)
	var mid := stage
	dread = 0.7
	_stage_tick()
	_terminals_tick(player.camera, player.global_position, 0.15)
	var on3 := world.kiosks.filter(func(x): return x["on"]).size()
	out.append({"what": "dread writes the drafts (1 -> 2 -> 3) and screens turn on by themselves", "ok": s0 == 1 and mid == 2 and stage == 3 and on3 == world.kiosks.size() and on3 > on0, "detail": [s0, mid, stage, on0, on3]})
	var c: Dictionary = world.clocks[0]
	var before: String = (c["label"] as Label3D).text
	player.global_position = Vector3(0, 0.05, 0)
	player.look_at(Vector3(0, 0.05, -10), Vector3.UP)
	for i in 30:
		_clocks_tick(player.camera, 0.15)
	out.append({"what": "an unwatched clock is on a different time", "ok": (c["label"] as Label3D).text != before, "detail": [before, (c["label"] as Label3D).text]})
	dread = 1.0
	_stage_tick()
	out.append({"what": "the last upload fails: user isle4 does not exist", "ok": gone and draft.lines.has("ERROR: Authentication failed. User isle4 does not exist.")})
	out.append({"what": "the volunteer's figure is only on the recordings", "ok": player.camera.cull_mask & VIEWER_LAYER == 0})
	return out
