extends LevelBase
## Level 13 — "The Boiling Frogs" (Backrooms Wikidot rev 28, accessed 2026-11-04;
## cite: "Level 13 - "The Boiling Frogs"" by Greggita Mahayfaio, CC BY-SA 3.0).
## Dossier: docs/canon/levels/L013.md. Systems map to SOURCE FACT rows or to
## ADAPTATION notes in level.json.
##
## Layout: a seeded, streamed 20th-century apartment complex (L013_block.gd):
## dim plaster halls on laminate or linoleum, near-identical flats, plentiful
## stair cores with lifts beside them. Two storeys are walkable at a time; the
## stair shafts show the building above and below, and climbing past them moves
## you two floors (the numbers on the landings count 1..290, block re-floored).
## Stateful systems:
##  - Lethargy and attachment: time spent in a flat, resting, eating and
##    watching TV makes you slow and heavy; the flat you rest in becomes yours
##    and walking away from it drags. Moving through the halls clears it.
##  - Restocking: every empty flat's fridge holds basic food and microwavable
##    meals and is refilled after you leave and come back.
##  - Lifts: call buttons work inconsistently; a car that does come jumps an
##    unpredictable number of floors.
##  - Exits: plain doors that look a little different (L0/114/327/395/410), red
##    doors (275), a door numbered 235, deeper-yellow walls (289, many are duds),
##    generated chessboards (157), bottom-floor stairs down (70/208), and the
##    rare stair that keeps climbing (280).
## Entities: none (page: Non-Entity Hazards). Residents exist only behind shut
## doors: TV murmur, light under the door, a doormat, no answer to knocks.

const P := preload("res://levels/L013/L013_parts.gd")
const Block := preload("res://levels/L013/L013_block.gd")
const Interior := preload("res://levels/L013/L013_interior.gd")
const START := Vector3(3.0, 0.02, 1.0)
const FH := P.FH

var parts: RefCounted
var block: RefCounted
var interior: RefCounted
var world: ChunkWorld
var qa_fixture := false
var floor_base := 1
var start_base := 1
var lethargy := 0.0
var attachment := 0.0
var claimed := ""
var endless_count := 0
var _meta: Dictionary = {}        # chunk key -> meta
var _apt_now := ""
var _taken: Dictionary = {}       # apt id -> time the fridge was emptied
var _tv_on: Dictionary = {}       # apt id -> Node3D (screen + sound)
var meals := 0
var _riding := false
var _lift_presses := 0
var _rides := 0
var _clock := 0.0
var _tv_cd := 0.0
var _knock_t := 0.0
var _lamps: Dictionary = {}       # group -> [[pos, color, energy, range, flicker, storey, shaft]]
var _lamp_storey := 0
var _said: Dictionary = {}
var _endless_key := Vector2i(9999, 9999)
var anchor_apt: Dictionary = {}


func build() -> void:
	qa_fixture = SessionState.is_qa()
	start_base = 2 * (absi(hash([level_seed, "floor"])) % 120) + 21
	floor_base = start_base
	var cp: Dictionary = TransitionService.pending_restore
	if cp.get("level", "") == stable_id:
		floor_base = int(SaveService.flag(stable_id, "floor_base", start_base))
	rules["walk_speed"] = 3.0
	rules["sprint_speed"] = 5.0
	rules["reverb_room"] = 0.3
	rules["reverb_wet"] = 0.11
	rules["view_distance"] = 70.0
	indoor_env(Color(0.92, 0.84, 0.72), 0.075, Color(0.03, 0.026, 0.022), 0.042)
	environment.tonemap_exposure = 1.05
	environment.glow_intensity = 0.3
	environment.glow_hdr_threshold = 1.0
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.86
	environment.adjustment_contrast = 1.05
	P.define_materials()
	lights.setup(16, 1)
	lights.max_distance = 22.0
	parts = P.new(self)
	interior = Interior.new(self)
	block = Block.new(self, parts)
	world = ChunkWorld.new()
	world.name = "Chunks"
	world.chunk_size = Block.CS
	world.radius = 2
	world.unload_radius = 3
	world.builds_per_frame = 1
	world.builder = _build_chunk
	add_child(world)
	world.chunk_unloaded.connect(_on_unload)
	add_arrival("start", START, -90.0)
	world.build_around(START, 0)     # the authored anchor first (its exits come first)
	world.build_around(START, 2)
	_audio()
	add_shot("corridor", Vector3(2.6, 1.6, 1.45), Vector3(30.0, 1.15, 0.55))
	add_landmark("Start: the long north hall, floor %d" % start_base, START)


func _audio() -> void:
	sound.bed("room_tone", {"cutoff": 150.0, "rumble": 0.3}, -21.0)
	sound.bed("fluorescent_hum", {"base": 60.0, "rasp": 0.05}, -34.0)
	sound.oneshot("knock", {"hits": 1}, 25.0, 70.0, 16.0, "[a door shuts somewhere down the hall]", -20.0)
	sound.oneshot("creak", {"freq": 52.0}, 60.0, 150.0, 12.0, "[the building groans under its own weight]", -21.0)
	sound.oneshot("pipe_clank", {"f": 95.0}, 45.0, 120.0, 10.0, "[water knocks in the pipes]", -24.0)
	sound.oneshot("footstep", {"surface": "wood", "variant": 2}, 40.0, 110.0, 8.0, "[footsteps on the floor above]", -19.0)
	sound.oneshot("whisper", {"seconds": 2.4}, 35.0, 90.0, 9.0, "[a television murmurs through a wall]", -26.0)


# ------------------------------------------------------------------ chunks

func _build_chunk(cx: int, cz: int, _version: int, node: Node3D) -> Dictionary:
	var _t0 := Time.get_ticks_usec()
	var meta: Dictionary = block.build_chunk(cx, cz, node)
	if OS.has_environment("L13PROF"):
		print("L13PROF ", cx, ",", cz, " ", (Time.get_ticks_usec() - _t0) / 1000.0, " ms core=", meta["core"]["core"], " apts=", meta["apts"].size(), " shapes=", node.find_children("*", "CollisionShape3D", true, false).size())
	_meta[Vector2i(cx, cz)] = meta
	if meta.get("endless", false):
		var sr: Rect2 = meta["shaft"]
		var t: ExitTrigger = make_exit("L013>L280#13", "condition", Vector3(sr.get_center().x, 1.5, sr.get_center().y), Vector3(3.0, 18.0, 5.2), "", node)
		if t:
			var key := Vector2i(cx, cz)
			t.condition = func() -> bool: return _endless_key == key and endless_count >= 4
	return meta


func _on_unload(k: Vector2i) -> void:
	var g := "%d,%d" % [k.x, k.y]
	lights.remove_group(g)
	_lamps.erase(g)
	_meta.erase(k)


## Light fixtures are fed to the LightPool per storey: pool lights cast no
## shadows, so fixtures on the other storey would shine through the slab.
## Stair-shaft landings within one storey of the player stay on.
func lamp(pos: Vector3, color: Color, energy: float, rng: float, flicker: float, group: String, storey: int, shaft := false) -> void:
	if not _lamps.has(group):
		_lamps[group] = []
	_lamps[group].append([pos, color, energy, rng, flicker, storey, shaft])
	if _feeds(storey, shaft):
		lights.add_anchor(pos, color, energy, rng, flicker, group)


func _feeds(storey: int, shaft: bool) -> bool:
	return storey == _lamp_storey or (shaft and absi(storey - _lamp_storey) <= 1)


func _relight() -> void:
	lights.clear_anchors()
	for g in _lamps:
		for l in _lamps[g]:
			if _feeds(l[5], l[6]):
				lights.add_anchor(l[0], l[1], l[2], l[3], l[4], g)


## An empty flat: exits and notes now; fridge / TV / bed prompts are created
## when the player first walks in (keeps the loaded collider count down).
func add_apt_items(node: Node3D, id: String, info: Dictionary) -> void:
	info["node"] = node
	if info.has("chess"):
		var t: ExitTrigger = make_exit("L013>L157#8", "interact", info["chess"], Vector3(1.7, 1.6, 1.7), "Touch the chessboard", node)
		if t:
			t.hold_seconds = 0.0
	if info.get("anchor", false):
		anchor_apt = info
		_note(node, "l13_meg_interview", "M.E.G. interview, floor 277 (transcript excerpt)",
			"21/04/20. A resident agreed to talk to a small M.E.G. team. His home: two small rooms, no windows, basic meals and old television. He was hostile from the start, complained about neighbours knocking about sugar and noise, and said the man next door simply stopped knocking about a year ago. Asked whether he would move to Level 11, he refused, called the room the best decision he ever made, and ended the interview by throwing a glass at the door.\n\n[Testimony: one resident's account, not survey fact.]",
			info["note"])


func _item(node: Node3D, c: Vector3, size: Vector3, prompt: String, cb: Callable) -> Interactable:
	var it := Interactable.new()
	node.add_child(it)
	it.setup(c, size, prompt, cb)
	return it


func _note(node: Node3D, id: String, title: String, text: String, c: Vector3) -> void:
	var it := Interactable.new()
	node.add_child(it)
	it.setup(c + Vector3.UP * 0.03, Vector3(0.4, 0.06, 0.3), "Read")
	it.as_note(id, title, text)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.21, 0.003, 0.29)
	mi.mesh = bm
	mi.material_override = MatLib.get_mat("paper")
	mi.position = Vector3(0, -0.028, 0)
	mi.rotation.y = 0.3
	it.add_child(mi)


func lobby_note(node: Node3D, c: Vector3, n: Vector3) -> void:
	var it := Interactable.new()
	node.add_child(it)
	it.setup(c, Vector3(0.5, 0.5, 0.12), "Read")
	it.as_note("l13_free_home", "Flyer pinned in the lift lobby: B.N.T.G. Free Home Project",
		"FREE HOME PROJECT - FLOOR 283. Basic housing and food, no rent, since July 2019. Ask about room rotation, and about discounts on food from other B.N.T.G. locations. Found work elsewhere in the network? Exit and reintegration help for everyone (paid back through B.N.T.G. loans, with interest).\n\nSomeone has written underneath in pencil: nobody rotates.",
		)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.21, 0.29, 0.003)
	mi.mesh = bm
	mi.material_override = MatLib.get_mat("paper")
	it.add_child(mi)
	mi.global_transform = Transform3D(Basis(Vector3.UP.cross(n).normalized(), Vector3.UP, n), c - n * 0.03)


## Inhabited door: the knock prompt is created when the player comes close.
func add_knock(node: Node3D, c: Vector3, tv: bool, meta: Dictionary) -> void:
	meta["knocks"].append({"pos": c, "tv": tv, "node": node})
	if tv:
		var p := AudioStreamPlayer3D.new()
		p.stream = AudioSynth.get_stream("whisper", {"seconds": 2.4})
		p.volume_db = -27.0
		p.max_distance = 7.0
		p.unit_size = 2.0
		p.bus = "Ambience"
		p.position = c
		p.autoplay = true
		node.add_child(p)


func add_lift(node: Node3D, c: Vector3, key: Vector2i, s: int) -> Interactable:
	return _item(node, c, Vector3(0.3, 0.4, 0.3), "Press the lift call button", func(_p): lift_call(key, s))


# ------------------------------------------------------------- interactions

func knock(c: Vector3, tv: bool) -> void:
	sound.play_at("knock", {"hits": 3}, c, -8.0)
	var lines := ["[no answer]", "[someone shuffles to the door, then away again]", "[a television is turned up]", "[a chain rattles; the door stays shut]"]
	var i := absi(hash([c.snapped(Vector3.ONE * 0.1), int(_clock / 20.0)])) % lines.size()
	if tv and i == 0:
		i = 2
	Overlay.subtitle(lines[i], 3.0)


func fridge(id: String) -> void:
	if _taken.has(id):
		Overlay.toast("Empty apart from the light and a smell of cold plastic. It will be full again.", 3.5)
		return
	_taken[id] = _clock
	meals += 1
	if player:
		player.heal(20.0)
	_add_lethargy(0.06)
	sound.play_at("ui", {"kind": "confirm"}, player.global_position if player else Vector3.ZERO, -16.0, "[the microwave pings]")
	Overlay.toast("Milk, bread, eggs, margarine and a stack of microwavable meals. Three minutes in the microwave; it tastes of almost nothing, and it is enough.", 4.5)


func television(id: String, node: Node3D, info: Dictionary) -> void:
	if _tv_on.has(id) and is_instance_valid(_tv_on[id]):
		(_tv_on[id] as Node).queue_free()
		_tv_on.erase(id)
		Overlay.subtitle("[the picture shrinks to a dot]", 1.5)
		return
	var holder := Node3D.new()
	node.add_child(holder)
	var mi := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.5, 0.38)
	mi.mesh = qm
	mi.material_override = MatLib.get_mat("l13_tv_on")
	var n: Vector3 = info["tv_n"]
	holder.add_child(mi)
	mi.global_transform = Transform3D(Basis(Vector3.UP.cross(n).normalized(), Vector3.UP, n), info["tv"] + n * 0.004)
	var lt := OmniLight3D.new()
	lt.light_color = Color(0.6, 0.72, 0.95)
	lt.light_energy = 0.5
	lt.omni_range = 3.0
	holder.add_child(lt)
	lt.global_position = info["tv"] + n * 0.6
	var au := AudioStreamPlayer3D.new()
	au.stream = AudioSynth.get_stream("whisper", {"seconds": 2.4})
	au.volume_db = -14.0
	au.max_distance = 9.0
	au.autoplay = true
	holder.add_child(au)
	au.global_position = info["tv"]
	_tv_on[id] = holder
	var shows := ["a black-and-white sitcom", "an old quiz show", "a cowboy serial", "a variety hour", "a cooking programme"]
	var r := absi(hash([id, _clock]))
	var a := 1 + r % 12
	var b := 1 + (r / 13) % 12
	if b == a + 1:
		b = (a + 6) % 12 + 1
	Overlay.subtitle("[%s: episode %d, then, without a break, episode %d]" % [shows[r % shows.size()], a, b], 4.0)
	_add_lethargy(0.05)


func rest(id: String) -> void:
	if _riding:
		return
	_riding = true
	await Overlay.fade_to(1.0, 0.8)
	if player:
		player.heal(15.0)
	_add_lethargy(0.15)
	if claimed == "" or claimed == id:
		claimed = id
		attachment = minf(1.0, attachment + 0.2)
	if SessionState.is_story():
		SaveService.set_flag(stable_id, "floor_base", floor_base)
		checkpoint("rest")
	await get_tree().create_timer(0.8).timeout
	await Overlay.fade_to(0.0, 1.0)
	Overlay.subtitle("[you could stay. It would be easy to stay]" if lethargy > 0.5 else "[the mattress is thin; you sleep anyway]", 3.0)
	_riding = false


func _add_lethargy(v: float) -> void:
	lethargy = clampf(lethargy + v, 0.0, 1.0)


# ------------------------------------------------------------------ lifts

func lift_outcome(key: Vector2i, s: int, n: int) -> String:
	var roll := float(absi(hash([level_seed, key, floor_base, s, n])) % 1000) / 1000.0
	if roll < 0.38:
		return "dead"
	if roll < 0.58:
		return "pass"
	return "ride"


func lift_call(key: Vector2i, s: int) -> void:
	if _riding:
		return
	_lift_presses += 1
	match lift_outcome(key, s, _lift_presses):
		"dead":
			Overlay.toast("The button lights. Nothing comes. After a while the light goes out again.", 3.5)
		"pass":
			Overlay.subtitle("[behind the doors a car hums past this floor without stopping]", 3.0)
		_:
			await ride(key, s)


func ride(key: Vector2i, s: int) -> void:
	_riding = true
	Overlay.subtitle("[the doors grind open on a car that smells of old carpet]", 2.0)
	await Overlay.fade_to(1.0, 0.7)
	var h := absi(hash([level_seed, key, floor_base, _rides]))
	_rides += 1
	var jump := (3 + h % 58) * (1 if (h / 59) % 2 == 0 else -1)
	var target := clampi(floor_base + s + jump, 1, 290)
	floor_base = target if target % 2 == 1 else target - 1
	var ns := target - floor_base
	var zc: float = block.core_plan(key.x, key.y)["zc"]
	var pos: Vector3 = block.local_to_world(key, 5.5, ns * FH + 0.03, zc - 0.85)
	var out: Vector3 = block.local_to_world(key, 5.5, 0.0, zc) - block.local_to_world(key, 5.5, 0.0, zc - 1.0)
	for k in world.chunks.keys():
		world._unload(k)
	world.build_around(pos, 1)
	player.global_position = pos
	player.velocity = Vector3.ZERO
	player.rotation.y = atan2(-out.x, -out.z)
	sound.play_at("transformer", {"base": 50.0}, pos, -14.0)
	Overlay.subtitle("[the indicator skips numbers and stops at %d]" % target, 3.0)
	if SessionState.is_story():
		SaveService.set_flag(stable_id, "floor_base", floor_base)
	await get_tree().create_timer(0.7).timeout
	await Overlay.fade_to(0.0, 0.8)
	_riding = false


## Move the walkable pair of storeys by two floors (stairs past the edge).
func refloor(new_base: int, dy: float) -> void:
	floor_base = new_base
	player.global_position.y += dy
	var pk := world.key_at(player.global_position)
	for k in world.chunks.keys():
		if k != pk:
			world._unload(k)
	world.rebuild(pk, false)
	if SessionState.is_story():
		SaveService.set_flag(stable_id, "floor_base", floor_base)


# ----------------------------------------------------------------- runtime

func on_player_ready() -> void:
	world.target = player
	if SessionState.is_story():
		SaveService.set_flag(stable_id, "floor_base", floor_base)
		checkpoint(str(spawn_report.get("used_arrival", "start")))
		if not SaveService.flag(stable_id, "arrived", false):
			SaveService.set_flag(stable_id, "arrived", true)
			Overlay.subtitle("[a long beige hall of identical doors] [somewhere, a television]", 5.0)
	if qa_fixture:
		qa_routes.append({"edge": "L013>L000#1", "target": Vector3(13.6, 0.0, 2.6), "note": "start hall, past the yellow wall and the lift lobby, to the plain door with no number"})


func level_process(delta: float) -> void:
	if player == null or player.camera == null or _riding:
		return
	_clock += delta
	var st := int(floor((player.global_position.y + 0.8) / FH))
	if st != _lamp_storey:
		_lamp_storey = st
		_relight()
	_tick_wrap()
	_tick_rooms(delta)
	_tick_duds(delta)
	_knock_t -= delta
	if _knock_t <= 0.0:
		_knock_t = 0.3
		for m in _near_meta():
			for kn in m.get("knocks", []):
				if not kn.has("made") and (kn["pos"] as Vector3).distance_to(player.global_position) < 4.0 and is_instance_valid(kn["node"]):
					kn["made"] = true
					var c: Vector3 = kn["pos"]
					var tv: bool = kn["tv"]
					_item(kn["node"], c, Vector3(0.9, 1.6, 0.25), "Knock", func(_p): knock(c, tv))
	_tv_cd -= delta
	if _tv_cd <= 0.0:
		for m in _near_meta():
			for c in m.get("tvdoors", []):
				if (c as Vector3).distance_to(player.global_position) < 3.0:
					_tv_cd = 40.0
					Overlay.subtitle("[a television murmurs behind the door: an old programme, mid-episode]", 3.0)


func _near_meta() -> Array:
	var pk := world.key_at(player.global_position)
	var out: Array = []
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var m: Variant = _meta.get(pk + Vector2i(dx, dz))
			if m is Dictionary:
				out.append(m)
	return out


## Climbing past the walkable storeys moves you two floors (seamless: the shaft
## is identical one floor up and one floor down).
func _tick_wrap() -> void:
	var p := player.global_position
	var key := world.key_at(p)
	var m: Dictionary = _meta.get(key, {})
	if not m.has("shaft") or not (m["shaft"] as Rect2).grow(0.1).has_point(Vector2(p.x, p.z)):
		if _endless_key != Vector2i(9999, 9999):
			_endless_key = Vector2i(9999, 9999)
			endless_count = 0
		return
	if p.y > FH * 1.5 + 0.3:
		if m.get("endless", false):
			if _endless_key != key:
				_endless_key = key
				endless_count = 0
			endless_count += 1
			player.global_position.y -= 2.0 * FH
			if endless_count == 2:
				Overlay.subtitle("[the numbers on the landings have stopped changing]", 3.0)
		elif floor_base < 289:
			refloor(floor_base + 2, -2.0 * FH)
	elif p.y < -FH * 0.5 - 0.3 and floor_base > 1:
		endless_count = 0
		refloor(floor_base - 2, 2.0 * FH)


## Lethargy, attachment and restocking.
func _tick_rooms(delta: float) -> void:
	var p := player.global_position
	var here := ""
	for m in _near_meta():
		for a in m.get("apts", []):
			var r: Rect2 = a["rect"]
			if r.has_point(Vector2(p.x, p.z)) and absf(p.y - float(a["y"])) < 1.4:
				here = a["id"]
				_make_items(a)
	if here != _apt_now:
		switch_apt(here)
	var moving := Vector2(player.velocity.x, player.velocity.z).length() > 0.6
	if here != "":
		lethargy += delta * (0.011 if here == claimed else 0.005)
		if here == claimed:
			attachment = minf(1.0, attachment + delta * 0.008)
	else:
		lethargy -= delta * (0.012 if moving else 0.002)
		attachment = maxf(0.0, attachment - delta * 0.0025)
	lethargy = clampf(lethargy, 0.0, 1.0)
	var drag := 0.0
	if claimed != "" and here != claimed and attachment > 0.25:
		drag = 0.35 * attachment
	var f := clampf(1.0 - 0.42 * lethargy - drag, 0.35, 1.0)
	player.walk_speed = float(rules["walk_speed"]) * f
	player.sprint_speed = float(rules["sprint_speed"]) * f if lethargy < 0.65 else player.walk_speed
	Overlay.set_screen_effect("desaturate", 0.55 * lethargy)
	Overlay.set_screen_effect("vignette", 0.25 + 0.35 * maxf(lethargy, attachment * 0.6))
	if lethargy > 0.35 and not _said.has("leth1"):
		_said["leth1"] = true
		Overlay.subtitle("[your limbs feel heavy; there is no hurry, is there?]", 3.5)
	if drag > 0.15 and not _said.has("drag"):
		_said["drag"] = true
		Overlay.subtitle("[your feet keep turning back toward your room]", 3.5)


func _make_items(info: Dictionary) -> void:
	var node: Node3D = info.get("node")
	if info.has("items") or node == null or not is_instance_valid(node):
		return
	info["items"] = true
	var id: String = info["id"]
	_item(node, info["fridge"], Vector3(0.8, 1.6, 0.6), "Open the fridge", func(_p): fridge(id))
	_item(node, info["tv"], Vector3(0.75, 0.6, 0.5), "Turn the television on or off", func(_p): television(id, node, info))
	_item(node, info["bed"], Vector3(1.0, 0.4, 1.6), "Lie down for a while", func(_p): rest(id))


## Entering a flat: its fridge is restocked if you emptied it a while ago.
func switch_apt(here: String) -> void:
	if here != "" and _taken.has(here) and _clock - float(_taken[here]) > 12.0:
		_taken.erase(here)
		Overlay.subtitle("[the fridge hums; it has been restocked]", 2.5)
	_apt_now = here


## Deeper-yellow walls that are not a way through: repeated failure.
func _tick_duds(delta: float) -> void:
	for m in _near_meta():
		for d in m.get("duds", []):
			var c: Vector3 = d["pos"]
			if c.distance_to(player.global_position + Vector3.UP) > 1.6:
				continue
			if player.pushing_into(c, Vector3(2.0, 2.0, 2.0)):
				d["hold"] = float(d["hold"]) + delta
				player.noclip_progress(float(d["hold"]) / 2.6)
				if float(d["hold"]) >= 1.7:
					d["hold"] = 0.0
					d["fails"] = int(d["fails"]) + 1
					player.noclip_progress(0.0)
					if int(d["fails"]) >= 3:
						Overlay.toast("Three tries and the paint is still only paint. This is probably not one of the walls that leads anywhere.", 4.5)
					else:
						Overlay.toast("For a moment the yellow gives. Then it is a wall again.", 3.0)
			else:
				d["hold"] = maxf(0.0, float(d["hold"]) - delta * 2.0)


# ---------------------------------------------------------------------- QA

func qa_capture_plan() -> Array:
	var plan: Array = qa_shots.duplicate()
	if not anchor_apt.is_empty():
		plan.append({"name": "apartment", "pos": anchor_apt["eye"], "target": anchor_apt["look"]})
	var zc: float = block.core_plan(0, 0)["zc"]
	if OS.has_environment("L13_EXTRA_SHOTS"):
		plan.append({"name": "stairwell", "pos": block.local_to_world(Vector2i.ZERO, 5.5, 3.0 + 1.62, zc + 1.2), "target": block.local_to_world(Vector2i.ZERO, 5.5, -6.0, zc + 3.4)})
	return plan


func qa_self_test() -> Array:
	var out: Array = []
	var space := get_world_3d().direct_space_state
	var h1 := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(6.0, 5.5, 1.0), Vector3(6.0, -2.0, 1.0), 1))
	var h0 := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(6.0, 2.5, 1.0), Vector3(6.0, -2.0, 1.0), 1))
	out.append({"what": "two walkable storeys in the anchor hall (y 3 and y 0)", "ok": not h1.is_empty() and not h0.is_empty()
		and absf(float(h1["position"].y) - 3.0) < 0.05 and absf(float(h0["position"].y)) < 0.05, "detail": [h1.get("position"), h0.get("position")]})
	# streamed plan carries every sourced exit kind somewhere (QA mode hides them near start)
	var keep := qa_fixture
	qa_fixture = false
	var seen := {}
	for cz in range(-12, 13):
		for cx in range(-12, 13):
			var cp: Dictionary = block.core_plan(cx, cz)
			if cp["core"]:
				seen["core"] = int(seen.get("core", 0)) + 1
			if cp["endless"]:
				seen["endless"] = true
			var sp: Dictionary = block._specials(cx, cz, 0, {"anchor": false})
			for kk in sp:
				seen[str(kk) + ("_real" if kk == "yellow" and sp[kk] else "")] = true
	qa_fixture = keep
	var kinds_ok: bool = seen.has("bland") and seen.has("red") and seen.has("d235") and seen.has("yellow_real") and seen.has("yellow") and seen.has("chess") and seen.has("endless")
	out.append({"what": "streamed plan generates bland, red, 235, yellow (real + dud), chess and endless-stair exits", "ok": kinds_ok, "detail": seen})
	out.append({"what": "stair cores are plentiful (> 40% of chunks)", "ok": int(seen.get("core", 0)) > 250, "detail": seen.get("core", 0)})
	# fridge restock
	var before := meals
	fridge("qa:apt")
	fridge("qa:apt")
	var once := meals == before + 1
	switch_apt("qa:elsewhere")
	switch_apt("qa:apt")
	var early := _taken.has("qa:apt")
	_taken["qa:apt"] = _clock - 30.0
	switch_apt("qa:elsewhere")
	switch_apt("qa:apt")
	out.append({"what": "fridge gives one meal, then restocks after you leave and come back", "ok": once and early and not _taken.has("qa:apt"), "detail": [before, meals]})
	switch_apt("")
	# walking into an empty flat sets up its fridge / TV / bed and starts the lethargy
	lethargy = 0.0
	var ap: Dictionary = anchor_apt
	var ae: Vector3 = ap["eye"]
	player.global_position = Vector3(ae.x, float(ap["y"]) + 0.05, ae.z)
	player.velocity = Vector3.ZERO
	for i in 90:
		await get_tree().physics_frame
	out.append({"what": "entering an empty flat creates its fridge/TV/bed prompts; time inside raises lethargy", "ok": ap.has("items") and lethargy > 0.0 and _apt_now == ap["id"], "detail": [lethargy, _apt_now]})
	player.global_position = START
	for i in 3:
		await get_tree().physics_frame
	# lethargy slows you down; rest claims the room
	lethargy = 0.0
	await rest("qa:apt")
	_add_lethargy(0.5)
	for i in 3:
		await get_tree().process_frame
	out.append({"what": "rest + lethargy make the room yours and slow you down", "ok": claimed == "qa:apt" and player.walk_speed < 3.0 * 0.85, "detail": [lethargy, player.walk_speed, claimed]})
	lethargy = 0.0
	attachment = 0.0
	claimed = ""
	# lift: inconsistent outcomes, and a ride moves you floors
	var outs := {}
	for n in 40:
		outs[lift_outcome(Vector2i(0, 0), 0, n)] = true
	var fb0 := floor_base
	await ride(Vector2i(0, 0), 0)
	var lp: Vector3 = block.local_to_world(Vector2i.ZERO, 5.5, player.global_position.y, 11.0 - 0.85)
	var moved := floor_base != fb0 and player.global_position.distance_to(lp) < 0.6
	out.append({"what": "lift call buttons are inconsistent (dead / pass / ride) and a ride jumps floors", "ok": outs.size() == 3 and moved, "detail": [outs.keys(), fb0, floor_base]})
	# stairs: climbing past storey 1 re-floors seamlessly; going down undoes it
	refloor(start_base, 0.0)
	await get_tree().process_frame
	var zc: float = block.core_plan(0, 0)["zc"]
	player.velocity = Vector3.ZERO
	player.global_position = block.local_to_world(Vector2i.ZERO, 6.38, 5.35, zc + 2.5)
	for i in 4:
		await get_tree().physics_frame
	var up_ok := floor_base == start_base + 2 and player.global_position.y < 0.0
	player.global_position = block.local_to_world(Vector2i.ZERO, 4.62, -2.5, zc + 2.0)
	for i in 4:
		await get_tree().physics_frame
	var down_ok := floor_base == start_base and player.global_position.y > 3.0
	out.append({"what": "stair wrap: up past storey 1 = +2 floors, down past storey 0 = -2 floors", "ok": up_ok and down_ok, "detail": [up_ok, down_ok, floor_base]})
	# bottom floor: the stairs down lead out (Level 70 / 208)
	refloor(1, 0.0)
	var down_exit := false
	for e in exits:
		if is_instance_valid(e) and (e.edge_id == "L013>L070#6" or e.edge_id == "L013>L208#7"):
			down_exit = true
	out.append({"what": "on the bottom floor the stair core's flight down is an exit (L70/L208)", "ok": down_exit})
	refloor(start_base, 0.0)
	for i in 30:
		await get_tree().process_frame
	player.global_position = START
	player.velocity = Vector3.ZERO
	for i in 3:
		await get_tree().physics_frame
	var duds := 0
	for m in _near_meta():
		duds += (m.get("duds", []) as Array).size()
	out.append({"what": "anchor rebuilt on return; a dud deeper-yellow wall sits near start", "ok": duds >= 1 and not anchor_apt.is_empty(), "detail": duds})
	lethargy = 0.0
	return out
