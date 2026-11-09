extends LevelBase
## Level 16 — "Altered Topography" (Backrooms Wikidot rev 48, accessed
## 2026-11-04; cite: DrBobtail, CC BY-SA 3.0). Dossier: docs/canon/levels/L016.md.
##
## PLAN (v2.0 rebuild)
## SOURCE: the page is a terminal recovering two backup files. File 1: a heavy
## rainforest with persistent fog, gravity greatly reduced for foreign objects
## and entities only (not native organisms), no day-night cycle (always
## dawn), a constant 21 C. File 2 (current state): arctic, ice with a luminous,
## highly reflective surface, a ~13 h day-night cycle, 10-6 C, large groups of
## Light Guides. The terrain alters itself at unknown intervals and its
## properties change with each shift; during a shift glaciers jut up, rivers
## gush out of boulders, the land freezes, small orbs surround you as a
## warning, and you can be encased in the changing terrain (frostbite,
## scrapes, or worse). No long-term bases. Exit to Level 46: rainforest -
## climb a tree covered in sand; arctic - stand on a sheet of ice covered in
## sand; the location changes with each alteration, the destination does not.
## Testimony: "Walked into a rainforest, walked out of a tundra."
## ADAPTATION: one valley (~260 m across, ridges all round, fog) holds both
## states; the shift sweeps out as a front from a seeded point (trees sink,
## glaciers rise, ice spreads; the reverse when it thaws); intervals are
## seeded at 4-7 minutes with a 25 s orb warning; the arctic day is compressed
## to 13 minutes; the starting state is seeded; Light Guides are shown only as
## groups of small drifting lights (the snapshot names them, nothing more);
## the expedition's dropped clipboard carries the two recovered files.
## Mechanic (stateful): terrain state + alteration timer + warning orbs +
## encasement + low gravity for you in the forest + an exit that moves with
## every alteration. Verticality: valley floor, a mesa with a walkable spur,
## river channel, glaciers, and long low-gravity jumps.

const LAND := preload("res://levels/L016/L016_land.gd")
const WORLD := preload("res://levels/L016/L016_world.gd")
const F := preload("res://levels/L016/L016_flora.gd")
const SHIFT := preload("res://levels/L016/L016_shift.gd")

var land
var wld
var shift
var terrain_mat: ShaderMaterial
var sky_mat: ShaderMaterial
var start := Vector3.ZERO


func build() -> void:
	rules["view_distance"] = 600.0
	rules["reverb_room"] = 0.1
	rules["reverb_wet"] = 0.05
	rules["flashlight"] = "allowed"
	rules["kill_y"] = -40.0
	land = LAND.new()
	wld = WORLD.new(self, land)
	outdoor_env(Color(0.3, 0.35, 0.5), Color(0.9, 0.6, 0.4), Color(0.1, 0.08, 0.06), Vector2(7.0, 120.0), Color(1.0, 0.7, 0.45), 1.0, Color(0.4, 0.34, 0.3), 0.02)
	sky_mat = LAND.shader_mat(LAND.SKY)
	environment.sky.sky_material = sky_mat
	environment.ambient_light_sky_contribution = 0.75
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.05
	environment.tonemap_exposure = 1.0
	sun.shadow_blur = 2.0
	sun.directional_shadow_max_distance = 90.0
	MatLib.define("l16_rock", {}, "rock")
	MatLib.register("l16_ice", wld.ice_mat)
	MatLib.define("l16_sand", {"albedo_a": Color(0.62, 0.52, 0.36), "albedo_b": Color(0.52, 0.43, 0.29), "pattern": 13, "noise_scale": 0.8}, "sand")
	var geo := Node3D.new()
	geo.name = "Terrain"
	add_child(geo)
	terrain_mat = land.terrain_material()
	land.build_mesh(geo, terrain_mat)
	land.collision(geo)
	start = Vector3(0, land.h(0, 0) + 0.05, 0)
	wld.plan_spots(rng)
	var clear: Array = [Vector3.ZERO]
	clear.append_array(wld.spots)
	var k := kit("Valley")
	var props := Node3D.new()
	props.name = "Dressing"
	add_child(props)
	wld.build_river(props, k, rng)
	wld.make_jets(props)
	wld.build_forest(props, rng, clear + [Vector3(land.MESA.x, 0, land.MESA.y)])
	wld.build_spires(props, rng, clear + [Vector3(land.MESA.x, 0, land.MESA.y)])
	_camp(k, props)
	k.commit()
	shift = SHIFT.new(self)
	add_child(shift)
	var face := Vector3(land.MESA.x, 0, land.MESA.y) - start
	add_arrival("start", start, rad_to_deg(atan2(-face.x, -face.z)) + 25.0)
	_sounds()
	add_landmark("The mesa and its spur", Vector3(land.MESA.x, 7.5, land.MESA.y))
	add_landmark("The river", Vector3(0, -1, land.river_z(0)))
	add_landmark("Dropped clipboard (the two recovered files)", Vector3(2.5, 0, 2.0))
	_shots()


func on_player_ready() -> void:
	shift.on_ready()
	checkpoint("start")


# ---------------------------------------------------------------- the clipboard

func _camp(_k: GeoKit, props: Node3D) -> void:
	var lp := Vector3(2.6, 0, 2.2)
	lp.y = land.h(lp.x, lp.z)
	Props.place(self, props, "ph/dead_tree_trunk", lp, 35.0, 0.0, false)
	var top := lp + Vector3(0, 0.28, 0)
	Props.place(self, props, "ph/clipboard", top + Vector3(-0.3, 0, 0.2), 60.0)
	Props.place(self, props, "ph/vintage_flashlight", top + Vector3(0.4, 0, -0.2), 140.0)
	Props.place(self, props, "ph/medical_box", Vector3(lp.x + 0.9, land.h(lp.x + 0.9, lp.z + 0.9), lp.z + 0.9), 20.0)
	add_note("l16_file1", "Printout: backup file 1 (date of edit 06/10)", "LEVEL 16 - recovered entry.\n\nA heavy rainforest, much like the ones outside the Backrooms, under persistent fog.\n\nGravity is greatly reduced - but only for things that came from somewhere else. Native organisms are not affected. You are affected.\n\nNo day and night: it stays at dawn. A steady 21 C, even in deep shade.\n\nA base would be possible in theory; the low gravity might do harm over time.\n\nExit: find a tree covered in sand and climb it. It goes to Level 46.", top + Vector3(-0.3, 0.05, 0.2), Vector3(0.4, 0.15, 0.4), false)
	add_note("l16_file2", "Printout: backup file 2 (date of edit 09/12)", "LEVEL 16 - recovered entry, marked CURRENT STATE.\n\nThe terrain changes itself at unknown intervals, and everything about it changes with it.\n\nNow: arctic. The ice has a luminous surface and reflects strongly. Day and night take about 13 hours. Between 10 C and 6 C.\n\nLight Guides in large numbers - odd, since they are rare and never seen in groups.\n\nNo long-term base can last here.\n\nExit: the location moves with every change, the destination does not. Find a sheet of ice covered in sand and stand on it. Level 46.\n\nNOTICE: once the level changes, old entries are archived. Do not rely on them to survive.", top + Vector3(-0.1, 0.05, 0.45), Vector3(0.4, 0.15, 0.4), false)
	add_note("l16_scrawl", "Pencil on the back of the printout", "Don't stay when it shifts. Glaciers came straight up out of the ground. Water burst out of the boulders. Everything froze and the air went cold. Little lights came and circled us first, like a warning.\n\nIf you're not careful the ground closes round you. I got out with frostbite and scrapes. Not everyone did.\n\nOur Level Key was wrong. We'd been here before and never knew - it just looked like a different place.\n\nWalked into a rainforest, walked out of a tundra.", top + Vector3(0.1, 0.05, 0.0), Vector3(0.4, 0.15, 0.4), false)


# ---------------------------------------------------------------- sound

func _sounds() -> void:
	shift.beds["forest"] = sound.bed("crickets", {}, -26.0)
	shift.beds["wind"] = sound.bed("wind", {"seconds": 10.0}, -30.0)
	shift.beds["rumble"] = sound.bed("room_tone", {"cutoff": 80.0, "rumble": 1.0}, -80.0)
	shift.beds["gush"] = sound.bed("water_bed", {"seconds": 6.0, "bright": 900.0}, -80.0)
	for x in [-60.0, -10.0, 40.0, 90.0]:
		sound.emitter("water_bed", Vector3(x, -0.6, land.river_z(x)), {"seconds": 7.0, "bright": 500.0}, -12.0, 30.0)
	sound.oneshot("drip", {"freq": 900.0}, 3.0, 8.0, 8.0, "[water drips from the leaves]", -16.0)


# ---------------------------------------------------------------- process

func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	shift.step(delta)
	# the valley sides become too steep and loose to climb
	var p := player.global_position
	var r := Vector2(p.x, p.z).length()
	if r > 132.0:
		var back := -Vector3(p.x, 0, p.z).normalized()
		player.velocity += back * minf((r - 132.0) * 2.0, 8.0) * delta * 10.0
		shift.say("steep", "[the slope here is too steep and loose to climb]", 3.0)


# ---------------------------------------------------------------- QA

func _shots() -> void:
	var m := Vector3(land.MESA.x, 0, land.MESA.y)
	var s0: Vector3 = wld.spots[0]
	add_shot("rainforest_dawn", start + Vector3(-1.5, 1.65, 3.0), m + Vector3(0, 6.0, 0), {"flashlight": false, "prepare": _prep.bind(0.0, 0.0)})
	add_shot("sand_tree", s0 + (start - s0).normalized() * 7.0 + Vector3(1.5, 1.7, 0), s0 + Vector3(0, 5.0, 0), {"flashlight": false, "prepare": _prep.bind(0.0, 0.0)})
	add_shot("arctic_glaciers", m + Vector3(-4.0, 9.4, 6.0), Vector3(-30, 2.0, 40.0), {"flashlight": false, "prepare": _prep.bind(1.0, 0.3)})
	add_shot("alteration_front", m + Vector3(-3.0, 9.4, 7.0), Vector3(-40, 0.0, 30.0), {"flashlight": false, "prepare": _prep.bind(0.5, 0.0)})
	add_shot("light_guides_night", start + Vector3(4.0, 1.7, -6.0), Vector3(-22.0, land.h(-22.0, 16.0) + 3.0, 16.0), {"flashlight": false, "prepare": _prep.bind(1.0, 0.75)})


func _prep(state: float, day: float) -> void:
	shift.stage(state, day)
	await get_tree().process_frame


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	var st0: int = shift.state
	out.append({"what": "low gravity applies to you only in the rainforest", "ok": (player.gravity < 5.0) == (st0 == 0), "detail": [st0, player.gravity]})
	out.append({"what": "one exit, on a sand-covered tree or ice sheet near the arrival", "ok": exits.size() == 1 and shift.exit_obj != null and is_instance_valid(shift.exit_obj)})
	var p0: Vector3 = shift.exit_pos
	var trees_before: bool = wld.cells[0]["node"].visible if wld.cells.size() > 0 else true
	await shift.qa_run_alteration()
	out.append({"what": "an alteration flips the terrain state", "ok": shift.state != st0, "detail": shift.state})
	out.append({"what": "the exit moves with the alteration (same destination)", "ok": shift.exit_pos.distance_to(p0) > 10.0 and exits.size() == 1 and exits[0].edge_id == "L016>L046#1", "detail": [p0, shift.exit_pos]})
	out.append({"what": "gravity follows the state", "ok": (player.gravity < 5.0) == (shift.state == 0)})
	var glacier_up := false
	for s in wld.spires:
		if (s["node"] as Node3D).position.y > (s["pos"] as Vector3).y - 1.0:
			glacier_up = true
	out.append({"what": "glaciers stand only in the arctic state; the forest only in the rainforest", "ok": glacier_up == (shift.state == 1) and (wld.cells[0]["node"].visible != trees_before or wld.cells.size() == 0)})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
