extends LevelBase
## Level 737 "Dune Eternal" (Backrooms Wikidot rev 21, accessed 2026-11-04;
## "Level 737 - "Dune Eternal"" by exotichive, CC BY-SA 3.0).
## Dossier: docs/canon/levels/L737.md. Content note: the page warns of violence,
## torture, death and existential crisis; Entity 737/1 is a decapitated immortal.
## Here it is a still, chained, headless silhouette in darkness, nothing graphic.
## The page itself says public data on this level was fabricated; notes say so.
##
## PLAN (v2.0 rebuild: read -> design)
## - SOURCE: an endless desert of fine gold dust at up to 737 C under a yellow
##   dwarf fixed at the zenith (golden light, no day cycle); heat-resistant gear
##   (UltraSuits) required -> a gold-dust heightfield (L737_terrain.gd) under a
##   straight-down sun in a golden haze; the dust burns, the blocks do not.
## - SOURCE: ruined blocks of stone, marble, pyrite and gold, unaffected by the
##   heat, used as stepping points -> scattered blocks and ruins (L737_land.gd);
##   standing on anything but dust lets you cool.
## - SOURCE: Frontrooms landmarks in the dunes: Eiffel Tower (gleaming), Statue of
##   Liberty (tarnished, half buried), Elizabeth Tower (clock frozen at 07:37),
##   Sphinx of gold dust, Pyramids of Giza, Golden Gate over nothingness,
##   Versailles fragments, the tip of the Burj Khalifa -> set pieces in the haze.
## - SOURCE: the ruins of New Ephyra (Site 737-1; ADAPTATION: brought to the foot of
##   the pyramid instead of ~6 km out) and the Great Pyramid of Ilios (Site 737-2):
##   Egyptian-Greek, watchtowers for corners, upper halls up to 60 m high and 10 m
##   wide (here 48 m), ~7,373 named tombs (a sampled gallery), the floorless core
##   chamber with one platform, walls of reliefs of a blindfolded figure, the
##   tombstone of "King ... of Ephyra" with withered flowers, Entity 737/1 hanging
##   beyond its end (L737_pyramid.gd). Heights: desert 0, hall 0..48, stair down to
##   the tombs and platform at -8, the abyss below (kill).
## - SOURCE: SCARF-λ in the lower pyramid; Sector C "Spine" holds the primary
##   facility entrance; the Provisional Database 737-λ was dissolved; Fireteam
##   "Midas" apprehends intruders and extracts them to Level 169; an emergency
##   phone number is linked to Midas devices.
## - Exits: surrender to the Midas post -> Level 169 (first: the walker's target);
##   the emergency phone (EXT#5, Midas response); the Spine's extraction bay ->
##   Levels 46, 739, 998 (ADAPTATION: the page lists them without a method).
## - Signature mechanic (stateful): heat. Exposure climbs while you stand on the
##   dust and falls on stone or inside the pyramid (a refuge); past a threshold it
##   burns. A spare UltraSuit at the dissolved outpost cuts the rate to a trickle.
## - ABSENT: wildlife, water, sand creatures, a day/night cycle, gold as loot,
##   X-Seed 4000 (documentation halted), the Level 50 passage as a short door.

const Ter := preload("res://levels/L737/L737_terrain.gd")
const Pyr := preload("res://levels/L737/L737_pyramid.gd")
const Land := preload("res://levels/L737/L737_land.gd")

var ter
var P
var S
var props: Node3D
var dust_body: StaticBody3D
var heat := 0.0
var suit := false
var on_dust := false
var inside := false
var _probe_t := 0.0
var _hurt_t := 0.0
var _said := {}
var _dialled := false
var _zone := ""
var _wind: AudioStreamPlayer


func build() -> void:
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 2000.0
	rules["kill_y"] = -45.0
	rules["reverb_room"] = 0.15
	rules["reverb_wet"] = 0.05
	outdoor_env(Color(0.78, 0.52, 0.16), Color(1.0, 0.82, 0.48), Color(0.7, 0.5, 0.2), Vector2(89.0, 0.0), Color(1.0, 0.86, 0.55), 1.7, Color(0.95, 0.74, 0.40), 0.0013)
	environment.ambient_light_energy = 0.55
	environment.tonemap_exposure = 0.8
	environment.fog_sky_affect = 0.5
	environment.fog_aerial_perspective = 0.4
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.1
	environment.adjustment_contrast = 1.06
	environment.glow_enabled = true
	environment.glow_intensity = 0.45
	environment.glow_hdr_threshold = 1.0
	sun.directional_shadow_max_distance = 160.0
	Pyr.materials()
	_materials()
	props = Node3D.new()
	props.name = "Dressing"
	add_child(props)
	ter = Ter.new()
	var geo := Node3D.new()
	geo.name = "Desert"
	add_child(geo)
	ter.build_meshes(geo, ter.make_material())
	dust_body = ter.build_collision(geo)
	P = Pyr.new(self, props)
	P.build()
	S = Land.new(self, props, ter)
	S.build()
	_lights()
	_sounds()
	_exits()
	_interactions()
	_notes()
	add_arrival("start", Vector3(0, 0.15, 27.0), 0.0)
	add_landmark("End of the endless passage (from Level 50)", Vector3(0, 0, 32))
	add_landmark("Fireteam Midas post", Land.MIDAS)
	add_landmark("Provisional Database 737-λ (dissolved)", Land.PDB)
	add_landmark("Ruins of New Ephyra (Site 737-1)", Vector3(0, 0, -5))
	add_landmark("Great Pyramid of Ilios (Site 737-2)", Pyr.C)
	add_landmark("Core chamber: platform, tombstone, Entity 737/1", P.tombstone)
	add_landmark("SCARF-λ Sector C Spine (extraction bay)", Vector3(35, 0, -56))
	add_landmark("Elizabeth Tower, 07:37", S.bigben)
	add_shot("dune_vista", Vector3(1.5, 1.7, 25.5), Vector3(0.0, 22.0, -100.0), {"flashlight": false})
	add_shot("big_ben", Vector3(-30.0, 2.2, 22.0), S.bigben + Vector3(0, 60.0, 0), {"flashlight": false})
	add_shot("great_hall", Vector3(1.5, 1.7, -50.0), Vector3(-0.5, 14.0, -90.0), {"flashlight": false})
	add_shot("core_chamber", Vector3(-0.3, GY_EYE, -125.2), P.tombstone + Vector3(0.6, 1.6, 0), {"flashlight": false, "prepare": _prep_deep})
	add_shot("ruins", Vector3(20.0, 2.0, 18.0), Vector3(-10.0, 3.0, -20.0), {"flashlight": false})
	add_shot("spine", Vector3(35.6, 1.7, -42.5), Vector3(35.0, 1.2, -63.0), {"flashlight": false})

const GY_EYE := -8.0 + 1.7


func _materials() -> void:
	MatLib.define("l737_verdigris", {"albedo_a": Color(0.36, 0.55, 0.45), "albedo_b": Color(0.62, 0.55, 0.3), "noise_scale": 1.6,
		"noise_mix": 0.7, "metallic_value": 0.5, "roughness_a": 0.45, "roughness_b": 0.7, "bump_strength": 0.8}, "metal")
	MatLib.define("l737_glass", {"albedo_a": Color(0.55, 0.5, 0.38), "albedo_b": Color(0.45, 0.42, 0.32), "pattern": 1,
		"pattern_scale": Vector2(1.5, 3.0), "grout_width": 0.02, "grout_color": Color(0.3, 0.28, 0.22), "metallic_value": 0.9,
		"roughness_a": 0.12, "roughness_b": 0.2}, "metal")
	MatLib.define("l737_dust_solid", {"albedo_a": Color(0.86, 0.62, 0.22), "albedo_b": Color(0.7, 0.48, 0.14), "pattern": 13,
		"noise_scale": 0.8, "metallic_value": 0.5, "roughness_a": 0.45, "roughness_b": 0.6, "bump_strength": 1.0})
	MatLib.define("l737_bridge", {"albedo_a": Color(0.62, 0.22, 0.08), "albedo_b": Color(0.75, 0.55, 0.2), "noise_scale": 2.5,
		"noise_mix": 0.6, "metallic_value": 0.7, "roughness_a": 0.4, "roughness_b": 0.7}, "metal")


func _lights() -> void:
	lights.setup(12, 1)
	lights.max_distance = 40.0
	for l in P.lamps:
		lights.add_anchor(l["pos"], l["col"], 1.5 * float(l["e"]), 12.0, 0.0, "pyr")


func _sounds() -> void:
	_wind = sound.bed("wind", {"seconds": 7.0}, -18.0)
	sound.bed("room_tone", {"cutoff": 180.0, "rumble": 0.4, "seconds": 6.0}, -30.0)
	sound.oneshot("wind", {"seconds": 3.0}, 18.0, 40.0, 30.0, "[a hot gust; the gold dust hisses across the stones]", -16.0)
	sound.emitter("transformer", Vector3(0, -8.0, -150.0), {"base": 55.0, "seconds": 4.0}, -14.0, 30.0)
	sound.emitter("pad", Vector3(0, -6.0, -140.0), {"root": 55.0, "chord": [0, 7, 12], "bright": 0.1, "seconds": 10.0}, -14.0, 34.0)
	sound.emitter("room_tone", Vector3(0, 10.0, -70.0), {"cutoff": 120.0, "rumble": 0.6, "seconds": 6.0}, -16.0, 40.0)
	sound.emitter("static", S.midas_top + Vector3(2.2, 0.5, -2.2), {"seconds": 2.0}, -20.0, 10.0)
	sound.emitter("fluorescent_hum", Vector3(35, 3.0, -50), {"base": 100.0, "seconds": 3.0}, -22.0, 12.0)


func _exits() -> void:
	# 1 (walker target): give yourself up to the Midas sentinels -> Level 169
	add_exit("L737>L169#2", "walk_in", S.midas_top + Vector3(0, 1.0, 0), Vector3(5.0, 2.0, 5.0))
	# 2: the emergency phone, linked to every Midas device (destination set on dialling)
	var tp := add_exit("L737>EXT#5", "condition", S.phone, Vector3(3.0, 2.4, 3.0))
	if tp:
		tp.condition = func() -> bool: return _dialled
	# 3: the Spine's extraction bay (Levels 46, 739, 998)
	for d in P.bay_doors:
		add_exit(d["edge"], "interact", d["pos"], Vector3(1.8, 2.2, 1.4), "Board the extraction: " + str(d["label"]))


func _interactions() -> void:
	add_interactable(S.suit_crate, Vector3(1.0, 0.4, 0.7), "Open the Repository crate", _take_suit)
	add_interactable(S.phone, Vector3(0.4, 0.3, 0.4), "Dial the emergency number", _dial)
	add_interactable(P.tombstone + Vector3(0, 2.0, 0.5), Vector3(2.6, 3.0, 0.4), "Read the tombstone", _tombstone)
	add_interactable(Vector3(0, -7.0, -150.6), Vector3(9.0, 2.0, 0.6), "Look past the end of the platform", _look_entity)


func _notes() -> void:
	add_note("l737_tablet", "Wax tablet (Lost Legion script, partly translated)",
		"A decree of exile, as far as it can be read: those who betrayed their own kin are cast out, stripped of name and hearth, to follow the endless passage to where \"the dunes glisten like stolen coin and the sun weighs heavier than judgment.\"\n\n(paraphrase of Object 51/1 as quoted on the Level 737 page, Backrooms Wiki, CC BY-SA 3.0)",
		Vector3(-27.0, ter.h(-26.0, -6.0) - 0.6 + 1.13, -5.5))
	add_note("l737_pdb", "Repository notice (sun-bleached)",
		"Provisional Database 737-λ is dissolved; its primary objectives are concluded. All research and surveillance now runs from SCARF-λ, built into the lower pyramid.\n\nField note scrawled underneath: the gold is fool's gold. Outside this level it is worthless. Do not fill your pockets.",
		S.phone + Vector3(0.6, -0.04, 0.2))
	add_note("l737_classification", "Classification procedure (laminated)",
		"Public documentation of this level is fabricated: environment data, survival difficulty, entrances and exits. Real entrances and exits are hidden behind substituted level skips and an emergency phone number. Intruders are located and apprehended by Fireteam \"Midas\", or left to the environment, and extracted to Level 169.",
		S.midas_top + Vector3(-2.4, 0.32, 2.0))
	add_note("l737_scarf", "SCARF-λ sector board",
		"SECTOR A - THRONE: EDEN, EVE III, holding chamber. Access only on the word of the Master Administrator or the CEO of Backrooms Robotics.\nSECTOR B - PANOPTICON: observation decks, signal relay.\nSECTOR C - SPINE: power, air, quarters, stores, primary facility entrance.\n\nEXTRACTION: Level 46, Level 169, Level 739, Level 998.",
		Vector3(37.15, 1.4, -50.0), Vector3(0.2, 0.6, 0.8), false)
	var ek := kit("Extras")
	ek.box(Vector3(37.27, 1.4, -50.0), Vector3(0.04, 0.8, 1.0), "l737_screen", GeoKit.ALL, false)
	ek.commit()


# ---------------------------------------------------------------- interactions

func _take_suit() -> void:
	if suit:
		Overlay.subtitle("[the crate is empty]", 1.5)
		return
	suit = true
	heat = maxf(0.0, heat - 0.3)
	Overlay.toast("UltraSuit on: sealed, filtered, cooled. The dust can still burn you, slowly.", 3.5)


func _dial() -> void:
	var e := TransitionService.get_edge("L737>EXT#5")
	if not e.is_empty():
		e["to"] = "L169"
	_dialled = true
	Overlay.subtitle("[the line clicks once. A voice: \"Midas. Stay where you are.\"]", 3.0)


func _tombstone() -> void:
	Overlay.show_note("The tombstone",
		"A massive weathered stone, stacked about with withered flowers no botanist could name. The inscription reads HERE LIES KING, then a name the sand has worn away, then OF EPHYRA.\n\nThe page records it in full: \"Here lies King Sisyphus of Ephyra\".")


func _look_entity() -> void:
	Overlay.subtitle("[beyond the end, at the far edge of the dark, something vast hangs in chains and cables. It has no head. It does not move]", 4.0)


# ---------------------------------------------------------------- per frame

func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var pp := player.global_position
	_probe_t -= delta
	if _probe_t <= 0.0:
		_probe_t = 0.15
		var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(pp + Vector3.UP * 0.4, pp + Vector3.DOWN * 0.6, 1))
		on_dust = not hit.is_empty() and hit.get("collider") == dust_body
		inside = false
		for a in P.interior_aabbs:
			if (a as AABB).has_point(pp + Vector3.UP * 0.5):
				inside = true
	var rate := (1.0 / 40.0) * (0.12 if suit else 1.0) if on_dust else 0.0
	var cool := 0.0 if on_dust else (0.06 if inside else 0.02)
	heat = clampf(heat + rate * delta - cool * delta, 0.0, 1.0)
	Overlay.set_screen_effect("red_tint", heat * 0.45)
	Overlay.set_screen_effect("vignette", 0.25 + heat * 0.35)
	if heat > 0.65:
		_hurt_t -= delta
		if _hurt_t <= 0.0:
			_hurt_t = 1.0
			player.hurt(4.0 * (heat - 0.5) * 2.0, "burns from the gold dust")
	if on_dust and heat > 0.3 and not _said.has("burn"):
		_said["burn"] = true
		Overlay.subtitle("[the dust is burning through your soles. Get onto the stones]", 3.0)
	var zone := "out"
	if inside:
		zone = "deep" if pp.y < -2.0 else "in"
	if zone != _zone:
		_zone = zone
		if zone == "out":
			environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
			environment.ambient_light_energy = 0.55
			environment.fog_density = 0.0013
			environment.fog_light_color = Color(0.95, 0.74, 0.40)
			environment.fog_sky_affect = 0.5
			environment.fog_aerial_perspective = 0.4
			sun.visible = true
		else:
			environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			environment.ambient_light_color = Color(0.5, 0.36, 0.2) if zone == "in" else Color(0.18, 0.2, 0.3)
			environment.ambient_light_energy = 0.18 if zone == "in" else 0.05
			environment.fog_density = 0.006 if zone == "in" else 0.02
			environment.fog_light_color = Color(0.5, 0.36, 0.2) if zone == "in" else Color(0.02, 0.025, 0.04)
			environment.fog_sky_affect = 0.0
			environment.fog_aerial_perspective = 0.0
			sun.visible = zone == "in"
			if zone == "deep" and not _said.has("deep"):
				_said["deep"] = true
				Overlay.subtitle("[cool air, rising from somewhere far below. A low machine hum]", 3.0)
	_wind.volume_db = lerpf(_wind.volume_db, -40.0 if inside else -18.0, delta)


func _prep_deep() -> void:
	_zone = ""
	_probe_t = 0.0
	await get_tree().physics_frame
	await get_tree().process_frame


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "stepping stones and ruins built", "ok": S.stones.size() >= 40, "detail": S.stones.size()})
	out.append({"what": "named tombs, tombstone and extraction bay built", "ok": P.names.size() >= 20 and P.bay_doors.size() == 3 and is_instance_valid(P.entity), "detail": [P.names.size(), P.bay_doors.size()]})
	out.append({"what": "the dust collision body exists", "ok": is_instance_valid(dust_body) and dust_body.get_child_count() > 0, "detail": dust_body.get_child_count() if is_instance_valid(dust_body) else -1})
	return out
