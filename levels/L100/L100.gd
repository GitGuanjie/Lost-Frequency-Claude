extends LevelBase
## Level 100 — "Brief Peace" (Backrooms Wikidot rev 20, accessed 2026-11-04;
## cite: Greggita Mahayfaio, CC BY-SA 3.0). Dossier: docs/canon/levels/L100.md.
## Every level fact is TESTIMONY from Holly Clove's interview and flashbacks.
##
## DESIGN (read -> plan):
## - "a thin, straight stretch of sand in an infinite, nearly static ocean"
##   (fact 2): a 34 m wide strip along z, streamed in 64 m lengths by a
##   ChunkWorld (finite window; the page's infinity is never simulated). Its
##   cross-section is a soft pale crest (two walkable heights: crest and the
##   wet shelf), dry slope, darker wet band, a wading shelf you can see through
##   the turquoise water, then a sheer submerged flank into deep sea.
## - Tide never moves, wind stagnant, no clouds, clear unrelenting sun, basic
##   blue gradient (facts 4-6): fixed procedural sky, high sun, no weather.
## - "The water only played close to the trail": the sea shader laps and foams
##   only along the shore and fades to glass beyond ~30 m (fact 7).
## - Graves (facts 3, 9, 10): your own shallow grave under a headstone where
##   you wake; hours along the strip (compressed to ~175 m) three new stones
##   with 2018 dates, epitaphs and small accessories such as photographs.
## - Signature mechanic (facts 13-15, exit): swimming away from the strip the
##   static water gives no pushback; fatigue grows, the swim slows, you sink.
##   A tall black being (REPORTED, single witness) takes you: you wake beside
##   it at a fresh grave it is etching; it nods, never speaks, and carries you
##   to "this office world" (Level 4). One way. Drowning anywhere ends the same.
## - ABSENT per dossier: islands, bases, items to collect, weather, day/night,
##   hostile entities. Nothing else is placed on the sand.

const Set := preload("res://levels/L100/L100_set.gd")
const CS := 64.0
const CREST := Set.CREST
const TRIO_Z := 175.0
const FATIGUE := 70.0

var world: ChunkWorld
var sea: WaterVolume
var surf: MeshInstance3D
var qa_fixture := false
var _read := {}
var _graves := {}
var _fatigue := 0.0
var _sinking := false
var _under_t := 0.0
var _phase := ""
var _cut_t := 0.0
var _being_done := false
var _stage: Node3D
var _being: Node3D
var _side := 1.0
var _lap: AudioStreamPlayer
var _msgs := {}


func build() -> void:
	qa_fixture = SessionState.is_qa()
	rules["view_distance"] = 1400.0
	rules["oxygen_seconds"] = 30.0
	rules["reverb_room"] = 0.1
	rules["reverb_wet"] = 0.02
	rules["flashlight"] = "none"
	outdoor_env(Color(0.12, 0.40, 0.82), Color(0.68, 0.85, 0.95), Color(0.05, 0.30, 0.45), Vector2(64, 30),
		Color(1.0, 0.95, 0.86), 1.1, Color(0.70, 0.85, 0.94), 0.0048)
	environment.fog_sky_affect = 0.25
	environment.tonemap_exposure = 0.8
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.08
	environment.ambient_light_energy = 0.45
	sun.directional_shadow_max_distance = 90.0
	Set.materials()
	lights.setup(2, 0)
	sea = WaterVolume.new()
	sea.name = "Ocean"
	add_child(sea)
	sea.setup(Vector3(-6000, -80, -6000), Vector3(6000, 0, 6000), "l100_sea", false)
	sea.tint = Color(0.06, 0.5, 0.55)
	sea.fog_color = Color(0.05, 0.38, 0.45)
	surf = MeshInstance3D.new()
	surf.name = "SeaSurface"
	var pm := PlaneMesh.new()
	pm.size = Vector2(2400, 2400)
	pm.subdivide_width = 24
	pm.subdivide_depth = 24
	surf.mesh = pm
	surf.material_override = MatLib.get_mat("l100_sea")
	surf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(surf)
	world = ChunkWorld.new()
	world.name = "Strip"
	world.chunk_size = CS
	world.radius = 4
	world.unload_radius = 5
	world.builder = _build_chunk
	add_child(world)
	world.build_around(Vector3(0, 0, 0), 4)
	add_arrival("start", Vector3(0.9, CREST + 0.05, 2.2), 180.0)
	add_arrival("from_L048", Vector3(1.6, CREST + 0.05, -30.0), 180.0)
	if qa_fixture:
		# QA FIXTURE ONLY: the real exit needs exhaustion in deep water and the
		# being's scene; the walker bot fires the same edge at the waterline.
		add_exit("L100>L004#1", "walk_in", Vector3(8.6, 0.8, 22.0), Vector3(2.6, 2.4, 2.6), "")
		qa_routes.append({"edge": "L100>L004#1", "target": Vector3(8.6, 0.2, 22.0), "note": "QA fixture at the waterline; story exit = swim out until exhausted, the being carries you"})
	_lap = sound.bed("water_bed", {"bright": 1100.0, "seconds": 6.0}, -18.0)
	sound.bed("wind", {"seconds": 10.0}, -44.0)
	add_landmark("Your own grave (arrival)", Vector3(-1.9, CREST, 0.0))
	add_landmark("Three new headstones", Vector3(-1.6, CREST, TRIO_Z))
	add_landmark("Glass-still water beyond the trail", Vector3(60, 0, 40))
	add_shot("strip", Vector3(1.4, CREST + 1.62, 6.0), Vector3(2.5, 0.6, 90.0), {"prepare": _prep.bind(Vector3(0, 0, 40))})
	add_shot("first_grave", Vector3(3.4, CREST - 0.05 + 1.62, 2.9), Vector3(-1.9, 0.75, -0.2), {"prepare": _prep.bind(Vector3.ZERO)})
	add_shot("three_graves", Vector3(4.2, CREST - 0.2 + 1.55, TRIO_Z + 1.2), Vector3(-1.6, 0.95, TRIO_Z), {"prepare": _prep.bind(Vector3(0, 0, TRIO_Z))})
	add_shot("glass_sea", Vector3(70.0, 1.15, 30.0), Vector3(0.0, 0.6, 60.0), {"prepare": _prep.bind(Vector3(0, 0, 40))})
	add_shot("the_being", Vector3(6.5, 0.45 + 1.1, 62.2), Vector3(3.3, 1.45, 60.2), {"prepare": _prep_being})


func _build_chunk(cx: int, cz: int, _v: int, node: Node3D) -> Dictionary:
	if cx != 0:
		return {"kind": "sea"}
	var z0 := cz * CS
	var k := GeoKit.new(node, "Sand")
	Set.strip(k, z0, z0 + CS)
	var meta := {"kind": "strip"}
	# Deterministic, purely visual sand relief: low drifts, never an obstacle.
	var r := RandomNumberGenerator.new()
	r.seed = hash(["l100-drifts", cz])
	for i in 7:
		var x := r.randf_range(-5.5, 5.5)
		var z := z0 + r.randf_range(2.0, CS - 2.0)
		var y := CREST if absf(x) < 3.0 else CREST - 0.15 * (absf(x) - 3.0)
		Set.mound(node, Vector3(x, y - 0.06, z), r.randf_range(-0.3, 0.3), r.randf_range(2.0, 5.0), "l100_sand")
	if cz == 0:
		_own_grave(k, node)
		meta["grave"] = "own"
	if z0 <= TRIO_Z and TRIO_Z < z0 + CS:
		_trio(k, node)
		meta["grave"] = "trio"
	k.commit()
	return meta


func _own_grave(k: GeoKit, node: Node3D) -> void:
	var face := Vector3(1, 0, 0)
	Set.headstone(k, node, Vector3(-1.9, CREST, 0.0), face, 0.66, 1.05, 4)
	# the shallow pit you clawed out of, and the sand thrown around it
	k.box_mm(Vector3(-1.75, CREST - 0.02, -0.55), Vector3(0.25, CREST + 0.012, 0.55), "l100_sand_dug", GeoKit.PY | GeoKit.SIDES, false)
	for m in [[Vector3(-0.6, CREST - 0.02, 0.85), 0.4, 0.8], [Vector3(0.55, CREST - 0.02, -0.35), 1.2, 0.7], [Vector3(-1.0, CREST - 0.02, -0.85), -0.2, 0.6]]:
		Set.mound(node, m[0], m[1], m[2], "l100_sand_dug")
	add_note("l100_own", "Your headstone",
		"New stone, sharply cut. The name on it is yours, and the date beneath it is in 2018.\n\nThe pit in front of it is barely three inches deep. Sand is still in your throat.",
		Vector3(-1.75, CREST + 0.8, 0.0), Vector3(0.6, 1.2, 1.0), false)


func _trio(k: GeoKit, node: Node3D) -> void:
	var face := Vector3(1, 0, 0)
	var stones := [
		["arwell", TRIO_Z - 2.5, "JOSEPH ARWELL\n01/11/74 - 25/06/18",
			"Joseph Arwell, 01/11/74 - 25/06/18.\n\nThe epitaph calls him a loyal protector of the M.E.G.'s most dangerous core base, who gave his life so others could prosper; the last of the Arwell family, \"which has lived in the blue for 102 years\".\n\nPhotographs are tucked against the stone: him with an older man who looks like him, with friends in empty back lots, a birthday in what looks like the inside of an electrical plant. You put them back exactly as you found them."],
		["cantor", TRIO_Z, "REBECCA CANTOR\n24/09/82 - 24/06/18",
			"Rebecca Cantor, 24/09/82 - 24/06/18.\n\n\"A hiker and explorer at heart.\" The stone says she never got to live the thrill of the worlds she fell into, and that her husband Johannes and her hiking group remember her on the fells every year.\n\nA photograph leans at its foot. The sand in front is a long low bump."],
		["feher", TRIO_Z + 2.5, "VERONIKA FEHER\n15/03/01 - 24/06/18",
			"Veronika Feher, 15/03/01 - 24/06/18.\n\n\"A young woman loved by many, even if not by those supposed to care for her.\"\n\nThe rest of the inscription is about her choice, and about the people who failed her."],
	]
	for i in stones.size():
		var s: Array = stones[i]
		var base := Vector3(-1.6, CREST, float(s[1]))
		Set.headstone(k, node, base, face, 0.62, 1.0, 5)
		Set.label(node, base + Vector3(0, 0.82, 0), face, str(s[2]), 22)
		Set.mound(node, Vector3(-0.3, CREST - 0.04, float(s[1])), PI * 0.5, 1.9, "l100_sand")
		var n := 3 if i == 0 else 1
		for j in n:
			Set.photo(k, base + Vector3(0.22, 0.04, -0.2 + j * 0.2), face, 0.35 + 0.1 * j, j % 2 == 1)
		var gid := str(s[0])
		var it := add_note("l100_" + gid, "Headstone", str(s[3]), base + Vector3(0.5, 0.75, 0), Vector3(0.9, 1.4, 1.0), false)
		it.used.connect(func(_by): _graves[gid] = true)
	add_interactable(Vector3(-1.3, CREST + 0.3, TRIO_Z - 2.5), Vector3(0.7, 0.5, 0.9), "Look at the photographs", func(_p):
		_read["photos"] = true
		Overlay.subtitle("[a life, shallowly buried. You put the photographs back exactly as you found them.]", 5.0))


func _prep(around: Vector3) -> void:
	world.build_around(around, 2)
	surf.position = Vector3(snappedf(around.x, 16.0), 0.0, snappedf(around.z, 16.0))
	await get_tree().process_frame


func _prep_being() -> void:
	world.build_around(Vector3(0, 0, 60), 2)
	if _stage == null:
		_build_stage(Vector3(0, 0, 60.0), 1.0)
	_being.rotation.y = atan2(1.0, 0.6)
	await get_tree().process_frame


# ------------------------------------------------------------ the being's scene

func _sand_y(ax: float) -> float:
	if ax <= 3.0:
		return CREST
	if ax <= 7.0:
		return CREST - 0.15 * (ax - 3.0)
	return 0.3 - 0.44 * (ax - 7.0) / 2.6


## A fresh grave on the strip at z, on the `side` facing the sea: the open
## pit, a shrouded body to the being's right, an unfinished stone, the being.
func _build_stage(at: Vector3, side: float) -> void:
	_side = side
	_stage = Node3D.new()
	_stage.name = "WorkingSite"
	add_child(_stage)
	var k := GeoKit.new(_stage, "Site")
	var face := Vector3(side, 0, 0)
	var stone := Vector3(2.0 * side, CREST, at.z)
	Set.headstone(k, _stage, stone, face, 0.62, 1.0, 2)
	var pit_x := 3.4 * side
	k.box_mm(Vector3(pit_x - 0.6, _sand_y(3.4) - 0.02, at.z - 0.55), Vector3(pit_x + 0.6, _sand_y(3.4) + 0.012, at.z + 0.55), "l100_sand_dug", GeoKit.PY | GeoKit.SIDES, false)
	Set.mound(_stage, Vector3(3.4 * side, _sand_y(3.4) - 0.05, at.z - 1.25), PI * 0.5, 1.6, "l100_sand_dug")
	# the shrouded body lies on the being's right
	var body := Vector3(3.5 * side, _sand_y(3.5) + 0.12, at.z + 1.2)
	var wrap := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.24
	cap.height = 1.7
	wrap.mesh = cap
	wrap.material_override = MatLib.get_mat("l100_shroud")
	wrap.transform = Transform3D(Basis(Vector3(0, 0, 1), PI * 0.5).scaled(Vector3(0.62, 1.0, 1.0)), body + Vector3(0, -0.04, 0))
	_stage.add_child(wrap)
	k.commit()
	_being = Set.being()
	_being.position = Vector3(4.6 * side, _sand_y(4.6), at.z)
	_being.rotation.y = atan2(-side, 0.0)
	(_being.get_node("Upper") as Node3D).rotation.x = -0.45
	_stage.add_child(_being)


func _begin_rescue() -> void:
	_phase = "taken"
	_cut_t = 0.0
	Overlay.subtitle("[a long, slender darkness glides over the surface. Two tendrils of ink reach for you.]", 4.5)


func _cutscene(delta: float) -> void:
	_cut_t += delta
	if _phase == "taken":
		Overlay.set_screen_effect("blackout", clampf(_cut_t / 2.5, 0.0, 1.0))
		if _cut_t >= 2.8:
			var p := player.global_position
			var side := 1.0 if p.x >= 0.0 else -1.0
			var z := snappedf(p.z, 1.0)
			world.build_around(Vector3(0, 0, z), 2)
			_build_stage(Vector3(0, 0, z), side)
			player.frozen = true
			player.velocity = Vector3.ZERO
			player.global_position = Vector3(6.6 * side, _sand_y(6.6) + 0.05, z + 1.4)
			player.rotation.y = atan2(side, 0.4)
			player.look_pitch = deg_to_rad(-6.0)
			player.head.rotation.x = player.look_pitch
			player.oxygen = player.oxygen_seconds
			var t := make_exit("L100>L004#1", "condition", _being.global_position + Vector3(1.0 * side, 1.0, 0.7), Vector3(6.0, 4.0, 6.0), "", self)
			if t:
				t.condition = func() -> bool: return _being_done
			_phase = "wake"
			_cut_t = 0.0
		return
	if _phase == "wake":
		Overlay.set_screen_effect("blackout", 1.0 - clampf((_cut_t - 0.5) / 3.0, 0.0, 1.0))
		var up := _being.get_node("Upper") as Node3D
		if _cut_t > 1.0:
			_say("wake", "[yellow first. Sand. Then, close enough to touch, something tall and black, kneeling at an open grave, etching the stone]", 6.0)
		if _cut_t > 5.0:
			_being.rotation.y = lerp_angle(_being.rotation.y, atan2(player.global_position.x - _being.global_position.x, player.global_position.z - _being.global_position.z), delta * 1.5)
			up.rotation.x = lerpf(up.rotation.x, -0.05, delta * 1.5)
		if _cut_t > 8.0 and _cut_t < 9.2:
			up.rotation.x = -0.05 - 0.3 * sin((_cut_t - 8.0) / 1.2 * PI)
			_say("nod", "[it does not speak. It gives one slow nod.]", 4.0)
		if _cut_t > 10.0:
			for a in [up.get_node("Arm-1"), up.get_node("Arm1")]:
				(a as Node3D).rotation.x = lerpf((a as Node3D).rotation.x, -1.2, delta * 1.2)
			_say("arms", "[its tendrils come up and wait at your sides. You cannot go back. It knows.]", 5.0)
		if _cut_t > 13.0:
			Overlay.set_screen_effect("blackout", clampf((_cut_t - 13.0) / 1.5, 0.0, 1.0))
		if _cut_t > 14.8 and not _being_done:
			_being_done = true
			SaveService.record_discovery(stable_id, "carried", "The tall black being carried you away from the strip.", "TESTIMONY")


# ----------------------------------------------------------------- runtime

func on_player_ready() -> void:
	world.target = player
	if SessionState.is_story() and not SaveService.flag(stable_id, "arrived", false):
		SaveService.set_flag(stable_id, "arrived", true)
		Overlay.subtitle("[sand in your mouth, in your lungs. Something stone behind your head.]", 5.0)


func _say(key: String, text: String, secs: float = 4.0) -> void:
	if _msgs.has(key):
		return
	_msgs[key] = true
	Overlay.subtitle(text, secs)


func _exit_tree() -> void:
	Overlay.set_screen_effect("blackout", 0.0)


func level_process(delta: float) -> void:
	if player == null:
		return
	var p := player.global_position
	surf.position = Vector3(snappedf(p.x, 16.0), 0.0, snappedf(p.z, 16.0))
	_lap.volume_db = lerpf(_lap.volume_db, -15.0 - 1.1 * clampf(absf(absf(p.x) - Set.SHORE_X), 0.0, 40.0), clampf(delta * 2.0, 0.0, 1.0))
	if _phase != "":
		_cutscene(delta)
		return
	var far := absf(p.x) > Set.SHELF_X
	if player.swimming and far:
		_fatigue += delta * (1.0 + absf(p.x) / 120.0)
	elif not player.swimming:
		_fatigue = maxf(0.0, _fatigue - delta * 0.6)
	var f := clampf(_fatigue / FATIGUE, 0.0, 1.0)
	if player.swimming:
		player.swim_speed = 2.4 * (1.0 - 0.8 * f)
		if far:
			player.stamina = player.stamina_max * (1.0 - f)
	if far and player.swimming:
		_say("still", "[beyond the little waves the water is as still as glass, and it gives no pushback]", 4.5)
	if f > 0.35:
		_say("burn", "[your arms burn. Every look back costs strength.]", 4.0)
	if f > 0.7:
		_say("needle", "[the sand behind you is a thin needle of yellow]", 4.0)
	if f >= 1.0 and not _sinking:
		_sinking = true
		Overlay.subtitle("[your limbs stop answering. Salt in your mouth.]", 4.0)
	if _sinking and player.swimming:
		player.global_position.y -= delta * 0.55
	if player.head_under:
		_under_t += delta
	else:
		_under_t = 0.0
	if (_sinking and _under_t > 3.5) or (player.head_under and player.oxygen < 6.0):
		_begin_rescue()
	if _graves.size() >= 3 and not _msgs.has("graves"):
		_say("graves", "[someone forgotten in a fight, someone never found, someone like you. You look at the water.]", 5.5)


func qa_self_test() -> Array:
	await get_tree().process_frame
	var trio := world.chunks.has(Vector2i(0, int(floor(TRIO_Z / CS))))
	var fixture_ok: bool = exits.size() == 1 and exits[0].edge_id == "L100>L004#1"
	var being_absent := _being == null and _phase == ""
	# Stage the rescue scene off to the side and check its gated story exit.
	_build_stage(Vector3(0, 0, -200.0), -1.0)
	var t := make_exit("L100>L004#1", "condition", _being.global_position + Vector3(0, 1, 0), Vector3(6, 4, 6), "", _stage)
	var gated := t != null
	if t:
		t.condition = func() -> bool: return _being_done
		gated = not t.condition.call()
	var tall: float = (_being.get_node("Upper/Head") as Node3D).global_position.y - _being.global_position.y
	_stage.queue_free()
	_stage = null
	_being = null
	exits = exits.filter(func(x): return is_instance_valid(x) and x != t)
	return [
		{"what": "rescue stage builds; its story exit waits for the being's scene", "ok": gated, "detail": tall},
		{"what": "the being is about ten feet tall (2.7-3.4 m)", "ok": tall > 2.4 and tall < 3.4, "detail": tall},
		{"what": "one sourced exit edge (QA fixture of L100>L004#1)", "ok": fixture_ok},
		{"what": "swimmable ocean defined around the strip", "ok": sea != null and sea.contains(Vector3(40, -2, 10))},
		{"what": "strip streamed with own grave and the three headstones in range", "ok": str(world.meta_of(Vector2i(0, 0)).get("grave", "")) == "own" and trio},
		{"what": "being absent until the rescue", "ok": being_absent},
		{"what": "fatigue starts at zero", "ok": _fatigue == 0.0},
	]
