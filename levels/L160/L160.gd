extends LevelBase
## Level 160 "The City Of Promised Memories" (Backrooms Wikidot rev 70, accessed 2026-11-04;
## author account deleted, CC BY-SA 3.0). Dossier: docs/canon/levels/L160.md.
## CONTENT NOTE: the page mentions suicide. Nothing of it is depicted or quoted here.
##
## PLAN (read -> design):
## - The page is a second-person monologue: a voice lures "●●■°▪︎" with memories and a pact.
##   No layout is given, so the route is ADAPTATION built only from the page's own images
##   (text + credited image titles): a grey straw field in fog ("monotone and grey"), the
##   swing on a playground mound ("swinging on it, gazing at the open sky"; Emma humming),
##   an infinite stretch of azure under a burning orange sky (wade it or cross the raised
##   boardwalk), a short street of shut cottages named by the voice as "the city of promised
##   memories", and her house with striped awnings: the soup on the table, her bed upstairs,
##   the children's room, and a back door onto "one more place you need to go through".
## - Stateful mechanic: the voice. Each memory you approach or listen to raises the pull: the
##   grey world warms into colour and the piano swells. At the back door the voice offers the
##   pact; accepting opens the door into darkness (the exit, destination unknown); walking
##   away is refusal ("You know where to find me."), and the colour drains back to grey.
## - No people appear: Emma, the friends and the mother are only the voice's claims.
## - Verticality: playground mound, a 1 m boardwalk over the shallows, a two-storey house.

const World := preload("res://levels/L160/L160_world.gd")
const House := preload("res://levels/L160/L160_house.gd")
const NAME := "●●■°▪︎"
const CENTRE := Vector3(25.0, 0.0, -15.0)
const GREY := {"top": Color(0.30, 0.31, 0.33), "hor": Color(0.50, 0.50, 0.51), "fog": Color(0.42, 0.42, 0.43), "sun": Color(0.8, 0.8, 0.8), "e": 0.35}
const OPEN := {"top": Color(0.20, 0.40, 0.70), "hor": Color(0.64, 0.70, 0.76), "fog": Color(0.58, 0.62, 0.66), "sun": Color(1.0, 0.93, 0.8), "e": 0.95}
const ORANGE := {"top": Color(0.55, 0.18, 0.06), "hor": Color(1.0, 0.50, 0.16), "fog": Color(0.80, 0.44, 0.20), "sun": Color(1.0, 0.55, 0.22), "e": 1.2}
const DUSK := {"top": Color(0.16, 0.16, 0.24), "hor": Color(0.50, 0.40, 0.38), "fog": Color(0.34, 0.32, 0.34), "sun": Color(0.9, 0.6, 0.45), "e": 0.25}

var W
var Hs
var pull := 0.0
var accepted := false
var offered := false
var refused_said := false
var qa_fixture := false
var zones: Array = []          # [{pos, r, line, heard}]
var _t := 0.0
var _swing_phase := 0.0
var _music: AudioStreamPlayer
var _pad: AudioStreamPlayer
var _hum: AudioStreamPlayer3D
var _door_open := 0.0
var _limit_fade := 0.0
var _snap := true
var _colour := 0.0


func build() -> void:
	qa_fixture = SessionState.is_qa()
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 220.0
	rules["reverb_room"] = 0.3
	rules["reverb_wet"] = 0.1
	outdoor_env(GREY["top"], GREY["hor"], Color(0.25, 0.25, 0.25), Vector2(22, 215), GREY["sun"], GREY["e"], GREY["fog"], 0.03)
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.2
	environment.tonemap_exposure = 1.05
	environment.ambient_light_energy = 0.55
	World.materials()
	House.materials()
	var r := RandomNumberGenerator.new()
	r.seed = 160160
	var k := kit("MemoryRoute")
	W = World.new(self, k)
	W.field(r)
	W.playground()
	W.shallows()
	var lamp_spots: Array = W.street(r)
	k.commit()
	var hk := kit("HerHouse")
	Hs = House.new(self, hk)
	Hs.build()
	hk.commit()
	_dress(r, lamp_spots)
	_lights(lamp_spots)
	_sound()
	_voice()
	# the exit: the darkness past the back door (destination never named by the page)
	var ex := add_exit("L160>EXT#1", "walk_in", Vector3(50.0, House.F0 + 1.1, 19.5), Vector3(2.2, 2.2, 1.8), "")
	if ex:
		ex.condition = func() -> bool: return accepted
		ex.fired.connect(func(_e: String) -> void: Overlay.subtitle("[the dark closes behind you. The page never says what waits inside.]", 4.0))
	add_interactable(Vector3(50.0, House.F0 + 1.1, House.Z1 - 0.12), Vector3(1.1, 2.0, 0.3), "Answer the voice at the back door", _offer)
	if qa_fixture:
		_accept_now(true)
	add_arrival("start", Vector3(0.0, 0.02, 3.0), 0.0)
	add_landmark("The swing on the mound", World.PLAY)
	add_landmark("The azure under the orange sky", Vector3(37, 1, -46))
	add_landmark("Her house with the striped awnings", Vector3(50, 0, 7))
	_shots()


func _p(id: String, pos: Vector3, yaw: float = 0.0, h: float = 0.0, collide: bool = false) -> Node3D:
	return Props.place(self, _root(), id, pos, yaw, h, collide)


var _props: Node3D
func _root() -> Node3D:
	if _props == null:
		_props = Node3D.new()
		_props.name = "Dressing"
		add_child(_props)
	return _props


func _dress(r: RandomNumberGenerator, lamp_spots: Array) -> void:
	# field: dense dry grass (one MultiMesh), rocks, fallen trunks
	_grass(r)
	for i in 7:
		_p("ph/boulder_01", Vector3(r.randf_range(-26, 18), -0.15, r.randf_range(-34, 8)) + Vector3(5.0 if i % 2 == 0 else -5.0, 0, 0), r.randf_range(0, 360), r.randf_range(0.6, 1.3), true)
	for i in 5:
		_p("ph/dead_tree_trunk", Vector3(r.randf_range(-20, 16), 0, r.randf_range(-32, 4)) + Vector3(4.0, 0, 0), r.randf_range(0, 360))
	for i in 14:
		_p("ph/rock_07", Vector3(r.randf_range(-6, 6), 0, r.randf_range(-34, 2)), r.randf_range(0, 360))
	# playground
	_p("ph/wooden_picnic_table", Vector3(5.2, World.PLAY.y, -41.5), 75.0, 0.0, true)
	# the boardwalk
	_p("ph/lifebuoy", Vector3(31.0, World.DECK_Y + 0.55, -44.82), 0.0)
	_p("ph/lifebuoy", Vector3(43.0, World.DECK_Y + 0.55, -44.82), 0.0)
	# the street
	for l in lamp_spots:
		_p("ph/street_lamp_01", l[0], l[1], 0.0, true)
	_p("ph/fire_hydrant", Vector3(46.0, 0.15, -12.0), 90.0)
	_p("ph/water_manhole_cover", Vector3(50.0, 0.015, -9.0), 0.0)
	_p("ph/utility_box_01", Vector3(54.4, 0.15, -18.0), -90.0, 0.0, true)
	_p("ph/street_lamp_02", Vector3(47.6, 0.3, 6.1), 0.0)
	# her house: dining room with the soup, kitchen, sitting room
	var f0 := House.F0
	var f1 := House.F1
	_p("ph/dining_table", Vector3(46.9, f0, 10.0), 90.0, 0.0, true)
	for i in 6:
		var side := -1.0 if i < 3 else 1.0
		_p("ph/dining_chair_02", Vector3(46.9 + side * 0.98, f0, 9.3 + float(i % 3) * 0.7), 90.0 if side < 0.0 else -90.0)
	_p("ph/lantern_chandelier_01", Vector3(46.9, f0 + 2.05, 10.0), 0.0)
	_p("ph/vintage_grandfather_clock_01", Vector3(45.35, f0, 8.0), 90.0, 0.0, true)
	_p("kenney/furniture-kit/kitchenstove", Vector3(45.45, f0, 14.6), 90.0, 0.92, true)
	_p("kenney/furniture-kit/kitchensink", Vector3(45.45, f0, 15.5), 90.0, 0.92, true)
	_p("kenney/furniture-kit/kitchencabinetdrawer", Vector3(45.45, f0, 16.4), 90.0, 0.92, true)
	_p("kenney/furniture-kit/kitchenfridgelarge", Vector3(45.5, f0, 13.6), 90.0, 1.9, true)
	_p("ph/Sofa_01", Vector3(54.4, f0, 10.5), -90.0, 0.0, true)
	_p("ph/ArmChair_01", Vector3(52.2, f0, 8.0), 150.0, 0.0, true)
	_p("ph/coffee_table_round_01", Vector3(53.1, f0, 10.6), 0.0, 0.0, true)
	_p("ph/wooden_bookshelf_worn", Vector3(53.1, f0, 16.6), 180.0, 0.0, true)
	_p("ph/Television_01", Vector3(52.0, f0, 12.6), 120.0)
	_p("ph/ornate_mirror_01", Vector3(48.9, f0 + 1.3, 8.4), 90.0)
	_p("kenney/furniture-kit/coatrackstanding", Vector3(49.3, f0, 7.6), 0.0, 1.75)
	_p("kenney/furniture-kit/rugrectangle", Vector3(49.6, f0 + 0.005, 11.0), 90.0)
	_p("ph/wall_clock", Vector3(48.95, f0 + 1.9, 12.5), 90.0)
	# upstairs: her bed, the children's room
	_p("kenney/furniture-kit/beddouble", Vector3(46.2, f1, 11.0), 90.0, 0.72, true)
	_p("ph/ClassicNightstand_01", Vector3(45.35, f1, 9.6), 90.0)
	_p("ph/ClassicNightstand_01", Vector3(45.35, f1, 12.4), 90.0)
	_p("ph/drawer_cabinet", Vector3(47.0, f1, 16.6), 180.0, 1.3, true)
	_p("ph/ornate_mirror_01", Vector3(48.65, f1 + 1.2, 10.0), -90.0)
	for z in [9.0, 13.0]:
		_p("kenney/furniture-kit/bedsingle", Vector3(54.3, f1, z), -90.0, 0.62, true)
	_p("ph/SchoolDesk_01", Vector3(52.0, f1, 7.5), 180.0, 0.0, true)
	_p("ph/SchoolChair_01", Vector3(52.0, f1, 8.2), 0.0)
	_p("ph/rubber_duck_toy", Vector3(53.0, f1, 11.0), 40.0)
	_p("ph/plastic_crate_01", Vector3(52.0, f1, 16.5), 10.0)
	# blanket turned back on her bed
	var bk := kit("Linen")
	bk.box(Vector3(46.35, f1 + 0.74, 11.5), Vector3(1.6, 0.06, 1.2), "l160_blanket", GeoKit.ALL, false)
	bk.box(Vector3(45.5, f1 + 0.78, 11.0), Vector3(0.35, 0.1, 1.3), "l160_cloth", GeoKit.ALL, false)
	bk.commit()


## The straw field: ~1400 dry grass clumps from the Poly Haven grass mesh in one MultiMesh.
func _grass(r: RandomNumberGenerator) -> void:
	var ps := load("res://assets/external/models/grass_medium_01.glb") as PackedScene
	if ps == null:
		return
	var inst := ps.instantiate()
	var found := inst.find_children("*", "MeshInstance3D", true, false)
	if found.is_empty():
		inst.free()
		return
	var src := found[0] as MeshInstance3D
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = src.mesh
	var xs: Array = []
	var guard := 0
	while xs.size() < 1400 and guard < 6000:
		guard += 1
		var p := Vector3(r.randf_range(-40, 34), 0, r.randf_range(-62, 14))
		if absf(p.x) < 1.4 and p.z > -38.0:
			continue
		if p.x > 20.0 and p.z < -26.0:
			continue
		if absf(p.x) < 9.2 and p.z < -37.6 and p.z > -55.4:
			p.y = World.PLAY.y
			if Vector2(p.x, p.z + 47.0).length() < 3.4 or (absf(p.x) < 1.6 and p.z > -46.0) or (p.x > 0.0 and absf(p.z + 46.0) < 1.6):
				continue
		elif absf(p.z + 46.0) < 1.4 and p.x > 9.0:
			continue
		var b := Basis(Vector3.UP, r.randf_range(0, TAU)).scaled(Vector3(r.randf_range(0.25, 0.45), r.randf_range(1.6, 2.8), r.randf_range(1.2, 2.0)))
		xs.append(Transform3D(b, p))
	mm.instance_count = xs.size()
	for i in xs.size():
		mm.set_instance_transform(i, xs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "StrawGrass"
	mmi.multimesh = mm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if src.get_surface_override_material_count() > 0 and src.get_surface_override_material(0):
		mmi.material_override = src.get_surface_override_material(0)
	add_child(mmi)
	inst.free()


func _lights(lamp_spots: Array) -> void:
	lights.setup(8, 1)
	lights.max_distance = 45.0
	for l in lamp_spots:
		lights.add_anchor((l[0] as Vector3) + Vector3(0, 3.6, 0), Color(1.0, 0.76, 0.46), 1.6, 10.0, 0.0, "street")
	for l in Hs.lamps:
		lights.add_anchor((l[0] as Vector3), Color(1.0, 0.8, 0.56), float(l[1]), float(l[2]), 0.0, "house")
	lights.add_anchor(Vector3(47.6, 1.9, 6.0), Color(1.0, 0.78, 0.5), 1.0, 6.0, 0.0, "porch")


func _sound() -> void:
	sound.bed("wind", {"seconds": 8.0}, -30.0)
	_pad = sound.bed("pad", {"root": 110.0, "chord": [0, 3, 7, 10], "bright": 0.06, "seconds": 12.0}, -34.0, "Music")
	_music = sound.bed("music_box", {"notes": [9, 7, 4, 2, 4, -1, 0, 2, 4, 7, 4, 2, 0, -3, -1, 0], "root": 220.0}, -40.0, "Music")
	_hum = sound.emitter("music_box", World.PLAY + Vector3(0, 1.2, -1), {"notes": [0, 4, 7, 4, 2, 5, 9, 5], "root": 392.0}, -26.0, 11.0)
	sound.emitter("water_bed", Vector3(37, 0.2, -50), {"bright": 500.0, "seconds": 6.0}, -18.0, 26.0)
	sound.emitter("room_tone", Vector3(50, 1.5, 12), {"cutoff": 300.0, "seconds": 5.0}, -22.0, 9.0)


func _voice() -> void:
	var lines := [
		[Vector3(0, 0, 0), 5.0, "Don't you remember? How could you forget?"],
		[Vector3(0, 0, -20), 7.0, "It's all so different from now, where everything is monotone and grey."],
		[World.PLAY, 7.0, "You would spend hours swinging on it, gazing at the open sky."],
		[Vector3(37, 1, -48), 7.0, "You stood hopelessly in an infinite stretch of azure under the burning orange sky."],
		[Vector3(50, 0, -23), 6.0, "The city of promised memories."],
		[Vector3(50, 0.3, 5.0), 3.5, "She took you to her house, she shared her food with you, gave you new clothes, a shelter"],
		[Vector3(46.9, 0.3, 10.0), 3.0, "She has just finished preparing your favourite soup, laid out on the table and ready for you to eat"],
		[Vector3(46.6, 3.3, 11.0), 3.2, "Your poor mother, who has spent hours upon hours crying in bed"],
		[Vector3(53.2, 3.3, 11.0), 3.2, "Your friends? They're also here, all of them are waiting to see you again!"],
		[Vector3(50, 0.3, 16.0), 2.2, "There's just one more place you need to go through. I will be waiting for you inside."]]
	for l in lines:
		zones.append({"pos": l[0], "r": l[1], "line": l[2], "heard": false})
	var listen := [
		[World.PLAY + Vector3(0, 1.0, -1.0), "Sit by the swing and listen", "She is here, and she is waiting for you, humming to herself those lovesick tunes you would chant for her."],
		[Vector3(37, 2.0, -48.5), "Look out over the azure", "It wasn't your fault! It wasn't your fault! It wasn't your FAULT!"],
		[Vector3(50, 1.5, -22), "Look down the street", "You've finally arrived. It wasn't that hard, see?"],
		[Vector3(46.9, 1.2, 10.0), "Look at the soup", "...and you dismiss her just like that, only because you can?"],
		[Vector3(46.4, 4.2, 11.0), "Look at the turned-back blanket", "She is waiting for you there as well."]]
	for l in listen:
		add_interactable(l[0], Vector3(1.6, 1.6, 1.6), l[1], _listen.bind(l[2]))
	add_note("letter", "AN ENVELOPE ON THE PATH",
		"Addressed in a careful hand to " + NAME + ". Inside, one line: everyone you lost is waiting, and the way home is straight ahead. It is not signed.",
		Vector3(0.6, 0.06, -1.5))
	add_note("porch", "A NOTE PINNED BY HER DOOR",
		"Dinner is ready. Your clothes are washed and folded upstairs. Come in, " + NAME + ". Hurry, your friends are waiting.",
		Vector3(48.6, 1.3, 6.85), Vector3(0.3, 0.3, 0.1), false)


func _say(line: String) -> void:
	Overlay.subtitle("THE VOICE: \"%s\"" % line, 5.0)


func _listen(_p: Player, line: String) -> void:
	_say(line)
	pull = minf(1.0, pull + 0.12)


func _offer(_p: Player) -> void:
	if accepted:
		_say("I will be waiting for you inside.")
		return
	offered = true
	_say("All you have to do is accept my pact, and I will grant you everything that you have hitherto lost to fate.")
	Overlay.confirm("Accept the voice's pact?\n(The page never says what accepting means. Walking away is also an answer.)", func() -> void: _accept_now(false))


func _accept_now(silent: bool) -> void:
	accepted = true
	pull = 1.0
	if Hs.door_kit and Hs.door_kit.body:
		Hs.door_kit.body.collision_layer = 0
		Hs.door_kit.body.collision_mask = 0
		for c in Hs.door_kit.body.get_children():
			(c as CollisionShape3D).disabled = true
	if silent:
		_door_open = 1.0
		Hs.door_pivot.rotation.y = deg_to_rad(100.0)
	else:
		_say("I am so proud of you, my little paragon.")


func _shots() -> void:
	add_shot("field", Vector3(0.6, 1.65, 2.0), Vector3(-1.0, 1.8, -30.0), {"prepare": _prep})
	add_shot("swing", Vector3(4.2, 2.2, -40.5), Vector3(0.0, 1.5, -47.5), {"prepare": _prep})
	add_shot("azure", Vector3(36.0, 2.65, -48.5), Vector3(44.0, 0.6, -64.0), {"prepare": _prep})
	add_shot("street", Vector3(49.0, 1.7, -24.0), Vector3(50.0, 2.6, 8.0), {"prepare": _prep})
	add_shot("dining", Vector3(48.3, 1.75, 7.6), Vector3(46.4, 0.9, 11.6), {"prepare": _prep})
	add_shot("backdoor", Vector3(49.4, 1.95, 12.0), Vector3(49.9, 1.2, 18.5), {"prepare": _prep})
	add_shot("upstairs", Vector3(48.3, 4.9, 16.4), Vector3(45.9, 3.7, 10.8), {"prepare": _prep})
	add_shot("porch", Vector3(52.5, 1.6, 0.5), Vector3(50.0, 2.6, 7.0), {"prepare": _prep})


func _prep() -> void:
	_snap = true
	await get_tree().process_frame


func on_player_ready() -> void:
	_relocate_overlay()
	if not qa_fixture:
		Overlay.toast("Content note: this level's source page mentions suicide. It is not depicted.", 7.0)


## The shared DEV26 annex drops three cues at fixed points; move them onto this route.
func _relocate_overlay() -> void:
	var annex := get_node_or_null("DEV26_CuratedAtmospheres") as Node3D
	if annex == null:
		return
	var src := [Vector3(-4.8, 0, -42), Vector3(4.8, 0, 0), Vector3(-4.8, 0, 42)]
	var dst := [World.PLAY + Vector3(2.9, 0, -0.2), Vector3(23.2, 0.0, -36.0), Vector3(47.9, 0.3, 6.6)]
	for c in annex.get_children():
		if not (c is Node3D) or str(c.name).begins_with("DEV26_Proximity"):
			continue
		var n := c as Node3D
		var gp := n.global_position
		var best := 0
		for i in 3:
			if Vector2(gp.x - src[i].x, gp.z - src[i].z).length() < Vector2(gp.x - src[best].x, gp.z - src[best].z).length():
				best = i
		n.global_position = gp - src[best] + dst[best]
		if n.get_node_or_null("Visual") != null:
			n.scale = Vector3.ONE * 0.6


# ------------------------------------------------------------------ mechanics

func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	_t += delta
	var p := player.global_position
	for z in zones:
		if not z["heard"] and Vector2(p.x - z["pos"].x, p.z - z["pos"].z).length() < float(z["r"]) and absf(p.y - float(z["pos"].y)) < 2.2:
			z["heard"] = true
			pull = minf(1.0, pull + 0.08)
			if not qa_fixture:
				_say(z["line"])
	# refusal: walking away from the offer
	if offered and not accepted and not refused_said and (p.z < House.Z0 - 1.0):
		refused_said = true
		pull = 0.0
		_say("You know where to find me.")
	_swing(delta)
	_sky(delta, p)
	_soft_limit(delta, p)
	if accepted and _door_open < 1.0:
		_door_open = minf(1.0, _door_open + delta * 0.6)
		Hs.door_pivot.rotation.y = deg_to_rad(100.0 * ease(_door_open, -2.0))


func _swing(delta: float) -> void:
	_swing_phase += delta * 1.55
	var amp := 0.32 + pull * 0.1
	if W.swing_pivots.size() > 0:
		(W.swing_pivots[0] as Node3D).rotation.x = sin(_swing_phase) * amp
		(W.swing_pivots[1] as Node3D).rotation.x = sin(_swing_phase * 0.37 + 1.0) * 0.03
	var prev := sin(_swing_phase - delta * 1.55)
	var now := sin(_swing_phase)
	if signf(prev) != signf(now) and player.global_position.distance_to(World.PLAY) < 22.0:
		sound.play_at("creak", {"freq": 170.0}, World.PLAY + Vector3(-0.8, 2.6, -1.0), -15.0, "[a swing chain creaks]")


func _zone_weight(p: Vector3, mn: Vector2, mx: Vector2, fall: float) -> float:
	var dx := maxf(maxf(mn.x - p.x, 0.0), p.x - mx.x)
	var dz := maxf(maxf(mn.y - p.z, 0.0), p.z - mx.y)
	return 1.0 - clampf(Vector2(dx, dz).length() / fall, 0.0, 1.0)


func _sky(delta: float, p: Vector3) -> void:
	var wp := 1.0 - clampf((Vector2(p.x, p.z + 46.0).length() - 7.0) / 14.0, 0.0, 1.0)
	var wa := _zone_weight(p, Vector2(22, -66), Vector2(56, -32), 10.0)
	var wc := _zone_weight(p, Vector2(40, -26), Vector2(60, 22), 9.0)
	var target := {}
	for key in ["top", "hor", "fog", "sun"]:
		var c: Color = GREY[key]
		c = c.lerp(OPEN[key], wp * (0.35 + pull * 0.65))
		c = c.lerp(ORANGE[key], wa)
		c = c.lerp(DUSK[key], wc)
		target[key] = c
	var e: float = lerpf(lerpf(lerpf(GREY["e"], OPEN["e"], wp * (0.35 + pull * 0.65)), ORANGE["e"], wa), DUSK["e"], wc)
	var col := clampf(0.15 + pull * 0.35 + maxf(wp, wa) * 0.55 + wc * 0.2, 0.0, 1.1)
	var a := 1.0 if _snap else clampf(delta * 0.8, 0.0, 1.0)
	_snap = false
	var sky := environment.sky.sky_material as ProceduralSkyMaterial
	sky.sky_top_color = sky.sky_top_color.lerp(target["top"], a)
	sky.sky_horizon_color = sky.sky_horizon_color.lerp(target["hor"], a)
	sky.ground_horizon_color = sky.sky_horizon_color
	environment.fog_light_color = environment.fog_light_color.lerp(target["fog"], a)
	sun.light_color = sun.light_color.lerp(target["sun"], a)
	sun.light_energy = lerpf(sun.light_energy, e, a)
	_colour = lerpf(_colour, col, a)
	environment.adjustment_saturation = _colour
	_music.volume_db = lerpf(-40.0, -20.0, pull)
	_pad.volume_db = lerpf(-34.0, -24.0, maxf(wa, pull * 0.5))


## The grey folds back on itself: far from the route the fog thickens, your legs slow,
## and past ~105 m the memory returns you to the path (diegetic soft limit).
func _soft_limit(delta: float, p: Vector3) -> void:
	var d := Vector2(p.x - CENTRE.x, p.z - CENTRE.z).length()
	var f := clampf((d - 82.0) / 22.0, 0.0, 1.0)
	environment.fog_density = 0.03 + f * 0.09
	player.walk_speed = float(rules["walk_speed"]) * (1.0 - f * 0.6)
	player.sprint_speed = float(rules["sprint_speed"]) * (1.0 - f * 0.6)
	if f >= 1.0 and _limit_fade <= 0.0:
		_limit_fade = 0.01
		Overlay.subtitle("[the grey folds back on itself]", 3.0)
	if _limit_fade > 0.0:
		_limit_fade += delta
		Overlay.set_screen_effect("blackout", clampf(_limit_fade * 1.2, 0.0, 1.0) if _limit_fade < 1.0 else clampf(2.0 - _limit_fade, 0.0, 1.0))
		if _limit_fade >= 1.0 and _limit_fade - delta < 1.0:
			player.global_position = Vector3(0.0, 0.05, -6.0)
			player.velocity = Vector3.ZERO
		if _limit_fade > 2.0:
			_limit_fade = 0.0
			Overlay.set_screen_effect("blackout", 0.0)


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out := []
	out.append({"what": "one exit, destination left unnamed by the source", "ok": exits.size() == 1})
	out.append({"what": "voice zones cover the whole route", "ok": zones.size() >= 9})
	out.append({"what": "QA fixture: pact accepted, back door collision off", "ok": accepted and Hs.door_kit.body.collision_layer == 0})
	var s0: float = environment.adjustment_saturation
	pull = 1.0
	_snap = true
	_sky(0.016, Vector3(37, 1, -48))
	out.append({"what": "memories warm the grey world", "ok": environment.adjustment_saturation > s0 + 0.3, "detail": [s0, environment.adjustment_saturation]})
	out.append({"what": "swing set animated", "ok": W.swing_pivots.size() == 2})
	return out
