extends LevelBase
## Level 23 - "The Petrified Garden" (Backrooms Wikidot rev 88, accessed
## 2026-11-04; cite: Kitty Rika and Beep Bot, CC BY-SA 3.0).
## Dossier: docs/canon/levels/L023.md.
## Content note: screams loud enough to burst eardrums (the buried sentries).
##
## PLAN (v2.0 rebuild)
## SOURCE: a planetoid-sized superorganism of intertwined trees; travel is
##   through air pockets and winding tunnels inside it. The surface is an
##   extremely dense forest of varied species that lets little light through;
##   a star above the canopy never moves, there is no day or night. Glow rooms
##   are large caverns where trees grow in and sprout leaves, lit by the
##   Gardener's Sorries (glowworm-like, many colours, whispering "sorry..."),
##   with glowing fungi and bushes, damp cool air. Deep in them stand mossy
##   ruins like Frontrooms landmarks with their shapes swapped (a spherical
##   Great Pyramid with a Latin plaque, a square Colosseum, a triangular
##   Parthenon, a pyramidal Lighthouse) holding poor pottery, damaged paintings,
##   cloth and hasty Latin writing. Saying "it's only a matter of time" wakes the
##   buried sentries in the wood, who scream. The hollow core: a spherical
##   ceiling held up by the Green Giants, trees growing down into it, and at the
##   centre the Heart of Water; entering it no-clips you at random to the ocean
##   of Level 7 or 121, or an exhibit in Level 43. M.E.G. Base Seedling (friendly,
##   ~30 members, cleared of hostiles and sentries) guards the only consistent
##   exit: the hollow tree at its centre, a two-way gate to Level 135.
## SPACE (ADAPTATION, compressed planetoid): signed-distance caves carved in
##   the wood. Base Seedling's glow room at y 0 (spawn); a winding tunnel up to
##   the ruin grove (y +3); a long rising tunnel that opens as a root trench onto
##   the surface clearing (y +12, open to the canopy); a descending tunnel into
##   the hollow core (y -10) with the Giants around the Heart's basin.
## SIGNATURE MECHANICS (stateful): the Heart rolls a random no-clip destination
##   each time you wade in (Level 7 / 121 common, 43 rare); the spoken phrase
##   wakes the sentries (scream, ear damage, muffled hearing, counted); the
##   Sorries' light and whispers follow you through every glow room.
## ABSENT: combat, day/night, buildings later than 1000 A.D., chopping Giants.

const C := preload("res://levels/L023/L023_cave.gd")
const P := preload("res://levels/L023/L023_plan.gd")
const Flora := preload("res://levels/L023/L023_flora.gd")
const Places := preload("res://levels/L023/L023_places.gd")
const Dress := preload("res://levels/L023/L023_dress.gd")
const GATE := "L023>L135#4"
const HEART := {"L007": "L023>L007#1", "L121": "L023>L121#2", "L043": "L023>L043#3"}
const ZONE_MATS := {1: ["l23_wood", "l23_rootmat"], 2: ["l23_wood_core", "l23_moss_core"], 3: ["l23_soil", "l23_litter"], 4: ["l23_wood", "l23_rootmat_g"]}

var plan
var noise := FastNoiseLite.new()
var flora
var places
var dress
var cave_root: Node3D
var heart_pick := "L007"
var in_heart := false
var zone := 1
var screams := 0
var deaf_t := 0.0
var deaf_fx: AudioEffectLowPassFilter
var gate: ExitTrigger
var heart_exits: Array = []


func build() -> void:
	rules["view_distance"] = 260.0
	rules["reverb_room"] = 0.75
	rules["reverb_wet"] = 0.3
	rules["flashlight"] = "allowed"
	rules["kill_y"] = -80.0
	noise.seed = 2323
	noise.frequency = 0.08
	Dress.materials()
	Places.materials()
	_env()
	plan = P.new()
	flora = Flora.new()
	cave_root = Node3D.new()
	cave_root.name = "Caves"
	add_child(cave_root)
	_blocks()
	var k := kit("Places")
	var props := Node3D.new()
	props.name = "Props"
	add_child(props)
	places = Places.new(self, k, props)
	places.hollow_tree(ceiling_at(Places.TREE + Vector3(0, 1, 0)))
	places.seedling()
	places.ruins()
	var giants: Array = places.giants(flora)
	k.commit()
	lights.setup(10, 0)
	dress = Dress.new(self, flora, plan, noise)
	dress.glow_room(P.ROOM_A, P.ROOM_A_R, 23101, places.footprints, 1.0)
	dress.glow_room(P.ROOM_B, P.ROOM_B_R, 23102, places.footprints, 1.2)
	dress.core(giants, places.footprints)
	dress.surface(places.footprints)
	dress.tunnels()
	for lp in places.lamps:
		lights.add_anchor(lp, Color(1.0, 0.72, 0.4), 1.6, 7.0, 0.04)
	_heart()
	_exits()
	var hs := Places.TREE + Vector3(0.4, 0.05, Places.TREE_R + 1.6)
	add_arrival("start", hs, 180.0)
	add_arrival("from_L135", hs, 180.0)
	add_arrival("from_L012", Vector3(-18.0, 0.05, -12.0), 120.0)
	add_arrival("from_L022", P.ROOM_B + Vector3(-12.0, 0.05, 10.0), 160.0)
	_notes()
	_sounds()
	add_landmark("M.E.G. Base Seedling and its hollow tree (to Level 135)", Places.TREE)
	add_landmark("Ruin grove: the Great Sphere", Places.SPHERE)
	add_landmark("Surface clearing under the canopy", P.SURF)
	add_landmark("Hollow core: the Heart of Water", P.CORE)
	_shots()


func _env() -> void:
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = Dress.sky_material()
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.4, 0.5, 0.65)
	environment.ambient_light_energy = 0.4
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.015, 0.03, 0.035)
	environment.fog_density = 0.02
	environment.fog_sky_affect = 0.0
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.15
	environment.glow_enabled = true
	environment.glow_intensity = 0.7
	environment.glow_bloom = 0.12
	environment.glow_hdr_threshold = 0.9


# ------------------------------------------------------------ caves

func _blocks() -> void:
	var bb: AABB = plan.bounds()
	var zf := func(p: Vector3) -> int: return P.zone_of(p)
	for bz in range(floori(bb.position.z / C.CS), floori(bb.end.z / C.CS) + 1):
		for bx in range(floori(bb.position.x / C.CS), floori(bb.end.x / C.CS) + 1):
			var ox := bx * C.CS
			var oz := bz * C.CS
			var region := AABB(Vector3(ox - C.H, -100.0, oz - C.H), Vector3(C.CS + C.H * 2.0, 200.0, C.CS + C.H * 2.0))
			var fs: Array = plan.features_for(region)
			if fs.is_empty():
				continue
			var ylo := 1e9
			var yhi := -1e9
			for f in fs:
				ylo = minf(ylo, (f["bb"] as AABB).position.y)
				yhi = maxf(yhi, (f["bb"] as AABB).end.y)
			var gy0 := floori(ylo / C.H) - 1
			var gy1 := ceili(yhi / C.H) + 1
			var field := C.Field.new(Vector3i(bx * C.N - 1, gy0, bz * C.N - 1), Vector3i(C.N + 2, gy1 - gy0 + 1, C.N + 2), noise)
			for f in fs:
				field.carve(f)
			field.clamp_all()
			var buckets := {}
			field.mesh(buckets, zf)
			var node := Node3D.new()
			node.name = "Block_%d_%d" % [bx, bz]
			cave_root.add_child(node)
			for key in buckets.keys():
				var z := int(key) / 2
				if z == 0:
					continue
				var fl := int(key) % 2 == 1
				C.commit(node, buckets[key], ZONE_MATS[z][1 if fl else 0], true, "dirt" if fl else "wood")


## Height of the cave ceiling (or open sky: +40) above an air point.
func ceiling_at(p: Vector3) -> float:
	var h: Dictionary = C.march(plan.features_for(AABB(p - Vector3(2, 2, 2), Vector3(4, 60, 4))), p, Vector3.UP, 50.0, noise)
	return float(h["p"].y) if not h.is_empty() else p.y + 40.0


# ------------------------------------------------------------ Heart and exits

func _heart() -> void:
	MatLib.register("l23_heart", MatLib.water({"shallow_color": Color(0.2, 0.6, 0.55), "deep_color": Color(0.02, 0.12, 0.16),
		"absorption": 0.6, "clarity": 0.8, "wave_height": 0.03, "wave_scale": 0.4, "foam_amount": 0.05}))
	var c := P.CORE
	var w := WaterVolume.new()
	w.name = "HeartOfWater"
	add_child(w)
	w.setup(Vector3(c.x - P.HEART_R, -13.5, c.z - P.HEART_R), Vector3(c.x + P.HEART_R, P.WATER_Y, c.z + P.HEART_R), "l23_heart")
	w.fog_color = Color(0.03, 0.18, 0.18)
	w.tint = Color(0.15, 0.5, 0.45)
	lights.add_anchor(c + Vector3(0, 3.0, 0), Color(0.35, 0.9, 0.8), 4.0, 26.0)
	for i in 4:
		var a := TAU * i / 4.0
		lights.add_anchor(c + Vector3(cos(a) * 9.0, 0.2, sin(a) * 9.0), Color(0.3, 0.85, 0.75), 2.2, 12.0)
	_roll()


func _roll() -> void:
	var x := rng.randf()
	heart_pick = "L007" if x < 0.45 else ("L121" if x < 0.9 else "L043")


func _exits() -> void:
	gate = add_exit(GATE, "interact", Places.TREE + Vector3(0, 1.1, 0), Vector3(2.6, 2.2, 2.6), "Step into the hollow tree (to Level 135)")
	var c := P.CORE + Vector3(7.8, -0.8, 0.0)
	for to in ["L007", "L121", "L043"]:
		var t := add_exit(HEART[to], "walk_in", c, Vector3(5.0, 2.0, 5.0), "")
		if t:
			var dest: String = to
			t.condition = func() -> bool: return heart_pick == dest
			heart_exits.append(t)


# ------------------------------------------------------------ notes, sentries

func _notes() -> void:
	add_note("l23_seedling", "M.E.G. Base Seedling: notice board", "BASE SEEDLING. Exploration, anthropology and research. About thirty members and five rescued volunteer wanderers live here. Friendly; open to trade. Water is steady, food is not.\n\nThis glow room has been cleared of hostile entities and of buried sentries. Outside it, they are still in the wood.\n\nDO NOT say the words \"it's only a matter of time\" anywhere on this Level. The walls will scream. Ears have burst.\n\nThe hollow tree in the middle of camp is the only consistent way out: it leads to Level 135, and back.\n\nDo not tamper with the Green Giants in the core. Do not wade into the water at the core unless you want to be dropped into the middle of an ocean, or somewhere stranger.", Places.TREE + Vector3(5.5, 1.3, 2.53), Vector3(0.6, 0.5, 0.2), false)
	add_note("l23_plaque", "Plaque at the Great Sphere (rough translation from Latin)", "We dedicate this Great Sphere of Giza to the Great Gardener, hoping to be forgiven the great wrong we did.\n\nOur purple eyes have already turned green. Forgotten and overgrown, we have begun to return to the earth. Our only hope is that, left alone and petrified, we will not disappear: the architects of a failed project.\n\n(Paraphrased from the M.E.G. translation of the plaque.)", Places.SPHERE + Vector3(2.6, 0.95, 5.2), Vector3(1.1, 0.5, 0.3), false)
	add_note("l23_scrawl", "Scratched into the Colosseum's stone", "Faded words in Latin, cut quickly and unevenly into the stone. Most of the letters have worn away; what is left was written in a hurry.\n\n(The ruins hold pottery, damaged paintings and cloth, every piece worse made than its Frontrooms twin. Nothing here resembles anything built after 1000 A.D.)", Places.COLOSSEUM + Vector3(-7.6, 1.5, 0.0), Vector3(0.3, 0.6, 1.2), false)
	for p in [Places.SPHERE + Vector3(-9.0, 1.5, 6.0), plan.paths["surface"][3] + Vector3(0, 1.2, 0)]:
		add_interactable(p, Vector3(2.0, 2.0, 2.0), "Say it aloud: \"it's only a matter of time\"", _say_phrase.bind(p))


func _say_phrase(at: Vector3) -> void:
	if Vector2(at.x - Places.TREE.x, at.z - Places.TREE.z).length() < 26.0:
		Overlay.subtitle("[nothing answers. Base Seedling was cleared of sentries.]", 3.0)
		return
	screams += 1
	SaveService.set_flag(stable_id, "sentry_screams", screams)
	Overlay.subtitle("[the wood around you SCREAMS: rusty chainsaws cutting through bark, from every wall at once]", 5.0)
	Overlay.glitch(1.0)
	for i in 4:
		var a := TAU * i / 4.0
		sound.play_at("static", {"seconds": 2.6}, at + Vector3(cos(a) * 6.0, 1.5, sin(a) * 6.0), 4.0, "")
		sound.play_at("scratch", {"seconds": 2.0}, at + Vector3(cos(a) * 5.0, 2.0, sin(a) * 5.0), 2.0, "")
	if player and is_instance_valid(player) and not SessionState.is_qa():
		player.hurt(12.0 + 6.0 * mini(screams, 4), "eardrums burst by the buried sentries")
	deaf_t = 18.0
	if deaf_fx == null:
		deaf_fx = AudioEffectLowPassFilter.new()
		deaf_fx.cutoff_hz = 400.0
		AudioServer.add_bus_effect(AudioServer.get_bus_index("Master"), deaf_fx)


# ------------------------------------------------------------ sound, shots

func _sounds() -> void:
	sound.bed("room_tone", {"cutoff": 180.0, "rumble": 0.25}, -28.0)
	for p in dress.sorry_spots:
		sound.emitter("whisper", p, {"seconds": 3.0}, -20.0, 16.0)
	sound.oneshot("whisper", {"seconds": 2.4}, 14.0, 30.0, 10.0, "[soft voices overhead: sorry... sorry...]", -18.0)
	sound.oneshot("creak", {"freq": 70.0}, 25.0, 60.0, 25.0, "[the wood groans somewhere inside the walls]", -20.0)
	sound.oneshot("drip", {"freq": 700.0}, 3.0, 9.0, 8.0, "", -24.0)
	sound.emitter("water_bed", P.CORE + Vector3(0, -10.5, 0), {"bright": 600.0}, -10.0, 40.0)
	sound.emitter("wind", P.SURF + Vector3(0, 3.0, 0), {"seconds": 8.0}, -18.0, 45.0)
	sound.emitter("crackle", Places.TREE + Vector3(9.0, 1.0, 9.0), {}, -26.0, 10.0)


func _shots() -> void:
	var t := Places.TREE
	add_shot("seedling_camp", t + Vector3(12.0, 1.7, 15.0), t + Vector3(-1.0, 3.2, 0.0), {"flashlight": false})
	add_shot("ruin_grove", Places.SPHERE + Vector3(14.0, 2.4, 13.0), Places.SPHERE + Vector3(0.0, 3.5, 0.0), {"flashlight": false})
	add_shot("heart_core", P.CORE + Vector3(24.0, 3.0, 9.0), P.CORE + Vector3(0.0, 1.0, 0.0), {"flashlight": false})
	add_shot("surface_canopy", P.SURF + Vector3(-19.5, 1.7, 2.0), P.SURF + Vector3(2.0, 7.0, -4.0), {"flashlight": false})


# ------------------------------------------------------------ runtime

func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var p := player.global_position
	var z := P.zone_of(p)
	if z == 0:
		z = 3
	if z != zone:
		zone = z
		_mood()
	var wet := p.y < P.WATER_Y + 0.3 and Vector2(p.x - P.CORE.x, p.z - P.CORE.z).length() < P.HEART_R
	if in_heart and not wet:
		_roll()
	in_heart = wet
	if deaf_t > 0.0:
		deaf_t -= delta
		if deaf_t <= 0.0 and deaf_fx:
			var bus := AudioServer.get_bus_index("Master")
			for i in AudioServer.get_bus_effect_count(bus):
				if AudioServer.get_bus_effect(bus, i) == deaf_fx:
					AudioServer.remove_bus_effect(bus, i)
					break
			deaf_fx = null


func _mood() -> void:
	match zone:
		3:
			environment.ambient_light_color = Color(0.5, 0.58, 0.36)
			environment.ambient_light_energy = 0.75
			environment.fog_light_color = Color(0.02, 0.035, 0.02)
			environment.fog_density = 0.03
		2:
			environment.ambient_light_color = Color(0.35, 0.6, 0.6)
			environment.ambient_light_energy = 0.45
			environment.fog_light_color = Color(0.02, 0.05, 0.05)
			environment.fog_density = 0.014
		_:
			environment.ambient_light_color = Color(0.4, 0.5, 0.65)
			environment.ambient_light_energy = 0.4
			environment.fog_light_color = Color(0.015, 0.03, 0.035)
			environment.fog_density = 0.02


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	var space := get_world_3d().direct_space_state
	out.append({"what": "gate to Level 135 first, three Heart of Water triggers", "ok": is_instance_valid(gate) and exits[0] == gate and heart_exits.size() == 3})
	var hits := {}
	for nm in ["seedling", "grove", "surface", "core"]:
		var q: Vector3 = {"seedling": Places.TREE + Vector3(6, 0, 6), "grove": P.ROOM_B + Vector3(0, 0, 12), "surface": P.SURF + Vector3(-8, 0, 0), "core": P.CORE + Vector3(-22, 0, 0)}[nm]
		var h := space.intersect_ray(PhysicsRayQueryParameters3D.create(q + Vector3(0, 2.0, 0), q + Vector3(0, -3.0, 0), 1))
		hits[nm] = float(h["position"].y) if not h.is_empty() else -999.0
	out.append({"what": "four walkable heights: core -10, base 0, grove +3, surface +12", "ok": absf(hits["seedling"]) < 0.8 and absf(hits["grove"] - 3.0) < 0.8 and absf(hits["surface"] - 12.0) < 0.8 and absf(hits["core"] + 10.0) < 0.8, "detail": hits})
	var picks := {}
	for i in 60:
		_roll()
		picks[heart_pick] = true
	out.append({"what": "the Heart rolls among Level 7, 121 and 43", "ok": picks.size() == 3, "detail": picks.keys()})
	var only := 0
	for t in heart_exits:
		if (t as ExitTrigger).condition.call():
			only += 1
	out.append({"what": "exactly one Heart destination is armed at a time", "ok": only == 1})
	out.append({"what": "Sorries light the glow rooms", "ok": dress.sorry_spots.size() >= 8 and dress.specks > 1000, "detail": [dress.sorry_spots.size(), dress.specks]})
	out.append({"what": "dense surface forest planted", "ok": dress.surface_trees > 150, "detail": dress.surface_trees})
	_say_phrase(Places.SPHERE + Vector3(-9.0, 1.5, 6.0))
	out.append({"what": "the phrase wakes the sentries (counted, hearing muffled)", "ok": screams == 1 and deaf_t > 0.0})
	_say_phrase(Places.TREE + Vector3(3, 1, 3))
	out.append({"what": "Base Seedling is free of sentries", "ok": screams == 1})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
