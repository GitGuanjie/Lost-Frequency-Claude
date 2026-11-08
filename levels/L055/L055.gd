extends LevelBase
## Level 55 — "Pit Stop" (Backrooms Wikidot rev 12, accessed 2026-11-04;
## cite: bird_stalwart055, CC BY-SA 3.0). Dossier: docs/canon/levels/L055.md.
##
## PLAN (v2.0 rebuild)
## SOURCE: an infinite set of segmented rooms like an abandoned rustic
## restaurant, joined by halls and corridors; each room usually has an
## ordering counter, a kitchen and rows of seating, bathrooms are rare; cracked
## brick, flaking wallpaper, creaking floorboards, thick dust; everyone arrives
## in the Safe Room (the only entry); beyond it the "outskirts" look much the
## same; Frontrooms food and plain water, no Almond Water; always eerily quiet
## (no hum, no machinery, no life); humid and cool; long stays bring auditory
## and sensory hallucinations; unobserved outskirts rooms move and reconnect
## (no new rooms appear); sunlight from an unperceivable source at various
## angles in every room, which makes exhausted wanderers drowsy; M.E.G. leaves
## phones and pamphlets; no conventional exit: after a random time the level
## no-clips you back to where you came from, and you know your time is short.
## ADAPTATION: a streamed grid of 24 m chunks, one 18 m room each with four
## doorways and short corridors (door offsets alternate so no sightline runs
## through three rooms); rooms are drawn from a finite seeded set of 32
## designs (diner, tavern with a raised dais, cafe, dining room) and a chunk
## nobody can see is rebuilt as another of them (ChunkWorld peripheral shift);
## the Safe Room is chunk (0,0), authored, never shifts. Sunbeams are spot
## lights with dusty shafts that begin in mid-air. Stay timer compressed to
## 20-45 minutes; resting in a sunbeam passes 6-12 minutes; when it runs out
## the light grows harsh and the level returns you (to: @origin).
## Verticality: raised dais rooms (three steps up). Entities: none.
## Helpers: L055_room.gd (shell, corridors, kitchen), L055_dress.gd (seating,
## light, sunbeams, props), L055_safe.gd (the Safe Room).

const R := preload("res://levels/L055/L055_room.gd")
const D := preload("res://levels/L055/L055_dress.gd")
const S := preload("res://levels/L055/L055_safe.gd")

var dress
var safe
var world: ChunkWorld
var beams: Dictionary = {}          # chunk key -> [world points]
var stay_left := 1800.0
var clock := 0.0
var rests := 0
var harsh := -1.0
var ejected := false
var beam_t := 0.0
var halluc_t := 300.0
var visited: Dictionary = {}
var said := {}
var qa_exit: ExitTrigger
var shifted := 0
var base_exposure := 1.0


func build() -> void:
	dress = D.new(self)
	safe = S.new(self)
	rules["view_distance"] = 90.0
	rules["reverb_room"] = 0.55
	rules["reverb_wet"] = 0.16
	rules["flashlight"] = "allowed"
	indoor_env(Color(0.6, 0.46, 0.32), 0.95, Color(0.3, 0.22, 0.14), 0.02)
	environment.background_color = Color(0.03, 0.022, 0.015)
	environment.tonemap_exposure = 1.1
	environment.glow_enabled = true
	environment.glow_intensity = 0.55
	environment.glow_bloom = 0.08
	environment.ssao_enabled = true
	_materials()
	lights.setup(10, 0)
	world = ChunkWorld.new()
	world.name = "Outskirts"
	world.chunk_size = R.CHUNK
	world.radius = 1
	world.unload_radius = 2
	world.builder = _chunk
	world.shift_enabled = not SessionState.is_qa()
	world.shift_after = 25.0
	world.can_shift = func(k: Vector2i, _m: Dictionary) -> bool: return k != Vector2i.ZERO
	world.chunk_unloaded.connect(_on_unload)
	world.chunk_shifted.connect(_on_shift)
	add_child(world)
	var start := Vector3(6.6, 0.05, 15.6)
	world.build_around(start, 1)
	add_arrival("start", start, -90.0)
	add_arrival("from_L011", start, -90.0)
	if SessionState.is_qa():
		# QA fixture only: the timed return as a reachable volume in the Safe Room
		qa_exit = add_exit("L055>EXT#1", "condition", Vector3(12.6, 1.2, 15.6), Vector3(2.4, 2.4, 2.4), "")
		if qa_exit:
			qa_exit.condition = func() -> bool: return stay_left <= 0.0
		stay_left = 0.0
	else:
		stay_left = rng.randf_range(1200.0, 2700.0)
	add_landmark("The Safe Room", Vector3(12, 0, 12))
	add_landmark("Outskirts (east)", Vector3(36, 0, 12))
	_sounds()
	_shots()


# ---------------------------------------------------------------- materials

func _photo(name: String, asset: String, tint: Color, repeat_m: float, rough: float = -1.0) -> void:
	var base := "res://assets/external/%s/%s_%%s_1k.jpg" % [asset, asset]
	if not ResourceLoader.exists(base % "diff"):
		MatLib.define(name, {"albedo_a": tint, "albedo_b": tint.darkened(0.1)}, "wood_floor")
		return
	var m := ORMMaterial3D.new()
	m.albedo_texture = load(base % "diff")
	m.albedo_color = tint
	if ResourceLoader.exists(base % "nor_gl"):
		m.normal_enabled = true
		m.normal_texture = load(base % "nor_gl")
	if ResourceLoader.exists(base % "arm"):
		m.orm_texture = load(base % "arm")
	if rough >= 0.0:
		m.orm_texture = null
		m.roughness = rough
	m.uv1_scale = Vector3(1.0 / repeat_m, 1.0 / repeat_m, 1.0)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	MatLib.register(name, m)


func _materials() -> void:
	# dusty floorboards: pale, matte
	MatLib.define("l55_floor", {"albedo_a": Color(0.3, 0.25, 0.2), "albedo_b": Color(0.24, 0.19, 0.15), "pattern": 3,
		"pattern_scale": Vector2(1.6, 0.17), "grout_width": 0.005, "grout_color": Color(0.14, 0.1, 0.07), "stain_amount": 0.65,
		"stain_color": Color(0.46, 0.43, 0.38), "stain_scale": 0.45, "roughness_a": 0.8, "roughness_b": 0.95, "tile_variation": 0.12,
		"noise_scale": 1.6, "bump_strength": 0.5}, "wood_floor")
	_photo("l55_brick", "brick_4", Color(0.82, 0.68, 0.6), 1.8)
	_photo("l55_beam", "old_wood_floor", Color(0.55, 0.42, 0.32), 1.2)
	_photo("l55_ceiling", "old_wood_floor", Color(0.62, 0.52, 0.42), 1.6, 0.9)
	_photo("l55_table", "old_wood_floor", Color(0.8, 0.62, 0.46), 1.0)
	_photo("l55_chair", "old_wood_floor", Color(0.6, 0.45, 0.33), 0.8)
	_photo("l55_counter", "old_wood_floor", Color(0.7, 0.52, 0.38), 1.2)
	_photo("l55_panel", "old_wood_floor", Color(0.66, 0.5, 0.38), 1.0)
	var papers := [[Color(0.5, 0.42, 0.26), Color(0.38, 0.3, 0.18)], [Color(0.42, 0.22, 0.17), Color(0.3, 0.15, 0.12)],
		[Color(0.33, 0.38, 0.3), Color(0.24, 0.3, 0.22)], [Color(0.52, 0.47, 0.38), Color(0.4, 0.34, 0.26)]]
	for i in papers.size():
		MatLib.define("l55_paper%d" % i, {"albedo_a": papers[i][0], "albedo_b": papers[i][0].darkened(0.08), "pattern": 10,
			"pattern_scale": Vector2(0.32, 0.42), "pattern_color": papers[i][1], "pattern_strength": 0.55, "stain_amount": 0.45,
			"stain_color": Color(0.3, 0.24, 0.15), "grime_height": 0.6, "grime_color": Color(0.25, 0.2, 0.13),
			"peel_amount": 0.32, "peel_color": Color(0.5, 0.42, 0.34), "roughness_a": 0.9, "roughness_b": 1.0, "noise_scale": 1.0}, "plaster")
	MatLib.define("l55_paper_hall", {"albedo_a": Color(0.46, 0.4, 0.3), "albedo_b": Color(0.4, 0.34, 0.25), "pattern": 2,
		"pattern_scale": Vector2(0.12, 1.0), "pattern_color": Color(0.36, 0.3, 0.2), "pattern_strength": 0.4, "stain_amount": 0.5,
		"peel_amount": 0.4, "peel_color": Color(0.52, 0.44, 0.36), "grime_height": 0.5}, "plaster")
	MatLib.define("l55_tile_floor", {"albedo_a": Color(0.82, 0.82, 0.8), "albedo_b": Color(0.76, 0.76, 0.74), "pattern": 9,
		"pattern_scale": Vector2(0.3, 0.3), "pattern_color": Color(0.2, 0.2, 0.2), "pattern_strength": 0.15, "stain_amount": 0.35,
		"stain_color": Color(0.5, 0.45, 0.36), "roughness_a": 0.4, "roughness_b": 0.6}, "pool_tile")
	MatLib.define("l55_tile_wall", {"albedo_a": Color(0.86, 0.87, 0.85), "albedo_b": Color(0.82, 0.83, 0.81), "pattern": 1,
		"pattern_scale": Vector2(0.15, 0.15), "grout_width": 0.006, "grout_color": Color(0.6, 0.6, 0.56), "stain_amount": 0.3,
		"stain_color": Color(0.55, 0.5, 0.4)}, "pool_tile")
	var pics := [Color(0.32, 0.36, 0.3), Color(0.5, 0.4, 0.28), Color(0.28, 0.3, 0.38), Color(0.45, 0.32, 0.3)]
	for i in pics.size():
		MatLib.define("l55_pic%d" % i, {"albedo_a": pics[i], "albedo_b": pics[i].lightened(0.25), "noise_scale": 3.5, "noise_mix": 0.8,
			"stain_amount": 0.4, "stain_color": Color(0.5, 0.42, 0.28), "roughness_a": 0.6, "roughness_b": 0.8}, "plaster")
	MatLib.register("l55_steel", MatLib.standard(Color(0.62, 0.63, 0.64), 0.35, 0.85))
	MatLib.register("l55_board", MatLib.standard(Color(0.08, 0.1, 0.09), 0.9))
	MatLib.register("l55_cloth", MatLib.standard(Color(0.78, 0.74, 0.66), 0.95))
	MatLib.register("l55_booth", MatLib.standard(Color(0.38, 0.12, 0.09), 0.7))
	MatLib.register("l55_blanket", MatLib.standard(Color(0.3, 0.33, 0.26), 0.95))
	MatLib.register("l55_phone", MatLib.standard(Color(0.06, 0.06, 0.07), 0.4))
	D.shaft_material()


# ---------------------------------------------------------------- streaming

func design_for(cx: int, cz: int, v: int) -> Dictionary:
	if cx == 0 and cz == 0:
		return S.DESIGN
	return D.design(posmod(hash([cx, cz, v, level_seed]), D.ROOMS), level_seed)


func _chunk(cx: int, cz: int, v: int, node: Node3D) -> Dictionary:
	node.position = Vector3(cx * R.CHUNK, 0.0, cz * R.CHUNK)
	var d := design_for(cx, cz, v)
	var r := RandomNumberGenerator.new()
	r.seed = hash([d["seed"], cx == 0 and cz == 0])
	var key := Vector2i(cx, cz)
	var group := "c%d_%d" % [cx, cz]
	var origin := node.position
	var k := GeoKit.new(node, "Room")
	R.shell(k, cx, cz, d)
	for s in 4:
		R.corridor(k, cx, cz, s, d)
	var ka := R.kitchen(k, cx, cz, d)
	var rr := {}
	if d["bath"]:
		rr = R.restroom(k, cx, cz, d)
	var dz: Dictionary = dress.dais(k, cx, cz, d)
	var tops: Array
	if cx == 0 and cz == 0:
		tops = safe.furnish(k, node)
	else:
		tops = dress.seating(k, node, cx, cz, d, r, dz)
	k.commit()
	dress.kitchen_props(node, d, ka, r)
	_menu(node, d, ka)
	if not rr.is_empty():
		var ks: int = d["kside"]
		var yaw := rad_to_deg(atan2(-(R.N[ks] as Vector3).x, -(R.N[ks] as Vector3).z))
		Props.place(self, node, "kenney/furniture-kit/toilet", rr["toilet"], yaw, Props.bounds("kenney/furniture-kit/toilet").size.y * D.KS, true)
		Props.place(self, node, "kenney/furniture-kit/bathroomsink", rr["sink"], yaw + 90.0, Props.bounds("kenney/furniture-kit/bathroomsink").size.y * D.KS, true)
	for l in dress.lamps(node, tops, d, r, origin):
		lights.add_anchor(l[0], l[1], l[2], l[3], l[4], group)
	lights.add_anchor(origin + (ka["lamp"] as Vector3), Color(1.0, 0.86, 0.7), 0.5, 5.0, 0.35, group)
	lights.add_anchor(origin + R.C + Vector3(0, 3.5, 0), Color(1.0, 0.8, 0.6), 1.0, 14.0, 0.0, group)
	if not (cx == 0 and cz == 0):
		dress.table_dressing(node, tops, r)
	var wk := GeoKit.new(node, "WallDressing")
	dress.wall_dressing(wk, node, cx, cz, d, r)
	wk.commit()
	# sunbeams: onto a table or a patch of floor, from nowhere
	var pts: Array = []
	var hits: Array = []
	if cx == 0 and cz == 0:
		hits = safe.beam_targets()
	else:
		for i in int(d["beams"]):
			if not tops.is_empty() and r.randf() < 0.7:
				hits.append((tops[r.randi() % tops.size()] as Vector3) - Vector3(0, 0.02, 0))
			else:
				hits.append(Vector3(R.C.x + r.randf_range(-5.0, 5.0), 0.0, R.C.z + r.randf_range(-5.0, 5.0)))
	for i in hits.size():
		var hp: Vector3 = dress.beam(node, hits[i], r, cx == 0 and cz == 0 and i == 0)
		var wp := origin + Vector3(hp.x, 0.0, hp.z)
		pts.append(wp)
		lights.add_anchor(origin + hp + Vector3(0, 0.35, 0), Color(1.0, 0.8, 0.58), 0.5, 4.0, 0.0, group)
		make_interactable(Vector3(hp.x, 0.7, hp.z), Vector3(1.8, 1.4, 1.8), "Sit a while in the sunlight", _rest, node)
	beams[key] = pts
	make_interactable((ka["fridge"] as Vector3) + Vector3(0, 1.0, 0), Vector3(1.2, 2.0, 1.2), "Look for something to eat", _eat, node)
	make_interactable((ka["sink"] as Vector3) + Vector3(0, 1.0, 0), Vector3(1.0, 1.4, 1.0), "Drink from the tap", _drink, node)
	return {"design": d["id"], "arch": d["arch"], "beams": pts.size()}


func _menu(node: Node3D, d: Dictionary, ka: Dictionary) -> void:
	var ks: int = d["kside"]
	var n: Vector3 = -(R.N[ks] as Vector3)
	var lb := Label3D.new()
	lb.text = ["TODAY\nsoup of the day\nmeat loaf & mash\nburger & fries\napple pie\ncoffee . tea . water",
		"MENU\nbreakfast all day\npancakes\nclub sandwich\nchicken pot pie\nlemonade . water",
		"SPECIALS\ngoulash & bread\nfish & chips\nroast dinner\ncheesecake\ncoffee . water"][int(d["id"]) % 3]
	lb.font_size = 28
	lb.pixel_size = 0.0042
	lb.modulate = Color(0.86, 0.84, 0.76, 0.9)
	lb.position = (ka["menu"] as Vector3) + n * 0.035
	lb.rotation.y = atan2(n.x, n.z)
	lb.shaded = true
	node.add_child(lb)


func _on_unload(k: Vector2i) -> void:
	lights.remove_group("c%d_%d" % [k.x, k.y])
	beams.erase(k)


func _on_shift(k: Vector2i, _v: int) -> void:
	shifted += 1
	if visited.has(k):
		_say("shift", "[the room through that doorway is not the one you walked through before. Nothing new - just rooms you've seen, in different places.]", 6.0)


# ---------------------------------------------------------------- mechanics

func _rest() -> void:
	if harsh >= 0.0:
		return
	rests += 1
	var lines := ["[the light is warm on your face. You close your eyes for a moment. When you open them the beam has moved.]",
		"[you drift. An afternoon glow through a classroom window; a bell; then nothing.]",
		"[you dream of a cafe in the rain, a mug going cold, someone across the table who wants you to be happy.]",
		"[you sleep, and wake, and the light is exactly where it was. You feel rested, and a little less like yourself.]"]
	var skip := rng.randf_range(360.0, 720.0)
	if not SessionState.is_qa():
		stay_left = maxf(stay_left - skip, 30.0)
	if player:
		player.stamina = player.stamina_max
	var tw := create_tween()
	tw.tween_method(func(v: float): Overlay.set_screen_effect("blackout", v), 0.0, 1.0, 1.6)
	tw.tween_interval(1.6)
	tw.tween_callback(func(): Overlay.subtitle(lines[(rests - 1) % lines.size()], 7.0))
	tw.tween_method(func(v: float): Overlay.set_screen_effect("blackout", v), 1.0, 0.0, 2.2)
	SaveService.record_discovery(stable_id, "l55:rest", "Rested in the sunlight of Level 55.", "SOURCE")


func _eat() -> void:
	Overlay.subtitle(["[sandwiches wrapped in wax paper, a pie, cold roast chicken. Ordinary food from home - nothing from the Backrooms.]",
		"[a tray of soup and bread, still good somehow. No one made it.]", "[fruit, cheese, a carton of milk. No almond water anywhere.]"][randi() % 3], 6.0)
	if player:
		player.stamina = player.stamina_max
	SaveService.record_discovery(stable_id, "l55:food", "Found ordinary Frontrooms food in Level 55.", "SOURCE")


func _drink() -> void:
	Overlay.subtitle("[plain, cold tap water. Not almond water - just water.]", 4.5)


func _beam_near(p: Vector3) -> bool:
	for k in beams:
		for b in beams[k]:
			if Vector2(p.x - (b as Vector3).x, p.z - (b as Vector3).z).length() < 1.3:
				return true
	return false


func _mechanics(delta: float, p: Vector3) -> void:
	clock += delta
	var key := world.key_at(p)
	visited[key] = true
	# sunlight makes the tired drowsy
	if _beam_near(p):
		beam_t += delta * (2.0 if player.stamina < player.stamina_max * 0.5 else 1.0)
		Overlay.set_screen_effect("vignette", 0.25 + minf(beam_t / 20.0, 0.35))
		if beam_t > 8.0:
			_say("drowsy", "[standing in the light, you feel how tired you are. You could sit down. Just for a while.]", 6.0)
	elif beam_t > 0.0:
		beam_t = maxf(beam_t - delta * 3.0, 0.0)
		Overlay.set_screen_effect("vignette", 0.25 + minf(beam_t / 20.0, 0.35))
	if SessionState.is_qa():
		return
	stay_left -= delta
	# hallucinations after a while
	if clock > 420.0:
		halluc_t -= delta
		if halluc_t <= 0.0:
			halluc_t = randf_range(110.0, 240.0)
			var f := p + Vector3(randf_range(-6, 6), 1.4, randf_range(-6, 6))
			match randi() % 3:
				0: _transient("whisper", {}, f, -22.0, 4.0, "[someone murmurs in the next room. No one is there.]")
				1: _transient("pad", {"root": 220.0, "chord": [0, 4, 7, 12], "bright": 0.3, "seconds": 7.0}, f + Vector3(0, 2, 0), -24.0, 8.0, "[very faintly, something like a choir, ringing in your ears]")
				_: _transient("rain", {"seconds": 6.0}, f, -26.0, 9.0, "[rain tapping on glass - there is no glass here]")
	if stay_left < 150.0:
		_say("soon", "[you know, the way you know you're about to wake, that your time here is nearly up]", 6.0)
	if stay_left <= 0.0 and harsh < 0.0:
		harsh = 0.0
		Overlay.subtitle("[the light grows harsher, whiter. The room seems to come apart around you.]", 8.0)
	if harsh >= 0.0 and not ejected:
		harsh += delta
		environment.tonemap_exposure = base_exposure + harsh * 0.25
		environment.glow_intensity = 0.55 + harsh * 0.1
		if harsh > 9.0:
			ejected = true
			Overlay.glitch(1.0)
			TransitionService.request_exit("L055>EXT#1")


# ---------------------------------------------------------------- sound

func _sounds() -> void:
	# silence is the identity: a faint room tone, no hum, no machinery
	sound.bed("room_tone", {"seconds": 7.0, "cutoff": 160.0, "rumble": 0.05}, -46.0)
	sound.oneshot("creak", {"freq": 92.0}, 14.0, 34.0, 7.0, "[a floorboard creaks under its own weight]", -26.0)
	sound.oneshot("creak", {"freq": 140.0}, 30.0, 70.0, 12.0, "[old timber settling somewhere in another room]", -30.0)


## A sound that plays for `secs` and fades (looping recipes included).
func _transient(recipe: String, params: Dictionary, pos: Vector3, db: float, secs: float, caption: String) -> void:
	var p := AudioStreamPlayer3D.new()
	p.stream = AudioSynth.get_stream(recipe, params)
	p.volume_db = db
	p.bus = "SFX"
	p.max_distance = 30.0
	add_child(p)
	p.global_position = pos
	p.play()
	var tw := create_tween()
	tw.tween_interval(secs * 0.7)
	tw.tween_property(p, "volume_db", -60.0, secs * 0.3)
	tw.tween_callback(p.queue_free)
	Overlay.subtitle(caption, 4.0)


func _say(key: String, text: String, secs: float = 4.5) -> void:
	if said.has(key) or SessionState.is_qa():
		return
	said[key] = true
	Overlay.subtitle(text, secs)


# ---------------------------------------------------------------- process

func on_player_ready() -> void:
	world.target = player
	base_exposure = environment.tonemap_exposure
	_say("arrive", "[everything goes quiet. Cold brick under your hands, dust, the smell of an old restaurant - and light, from nowhere, across a table. You know, somehow, that you can't stay.]", 8.0)


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_mechanics(delta, player.global_position)


# ---------------------------------------------------------------- QA

func _shots() -> void:
	add_shot("safe_room", Vector3(5.4, 1.62, 18.6), Vector3(14.0, 1.0, 11.0), {"flashlight": false})
	add_shot("sunlit_table", Vector3(14.6, 1.5, 17.2), Vector3(10.6, 0.7, 12.4), {"flashlight": false})
	add_shot("outskirts_room", Vector3(28.4, 1.62, 15.8), Vector3(40.0, 1.2, 10.0), {"flashlight": false, "prepare": _prep_east})
	add_shot("corridor_doorway", Vector3(16.5, 1.62, 15.5), Vector3(30.0, 1.4, 15.5), {"flashlight": false})


func _prep_east() -> void:
	world.build_around(Vector3(36, 0, 12), 1)
	await get_tree().process_frame


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "Safe Room is chunk (0,0) and never shifts", "ok": world.chunks.has(Vector2i.ZERO) and not world.can_shift.call(Vector2i.ZERO, {})})
	out.append({"what": "nine rooms streamed round the Safe Room", "ok": world.chunks.size() >= 9, "detail": world.chunks.size()})
	var n := 0
	for k in beams:
		n += (beams[k] as Array).size()
	out.append({"what": "every streamed room has sunlight", "ok": n >= world.chunks.size(), "detail": n})
	var designs := {}
	for k in world.chunks:
		designs[world.meta_of(k).get("design", -1)] = true
	out.append({"what": "rooms come from the finite design set", "ok": designs.size() >= 3, "detail": designs.size()})
	out.append({"what": "QA fixture for the timed return", "ok": qa_exit != null and exits.size() == 1})
	var space := get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(36.0, 2.0, 12.0), Vector3(36.0, -1.0, 12.0), 1))
	out.append({"what": "outskirts floor present east of the Safe Room", "ok": not hit.is_empty(), "detail": hit.get("position", null)})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
