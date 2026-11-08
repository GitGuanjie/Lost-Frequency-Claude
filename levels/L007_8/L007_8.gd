extends LevelBase
## Level 7.8 "Impaled Ocean" (Backrooms Wikidot rev 39, accessed 2026-11-04; Light_Nate,
## CC BY-SA 3.0). Dossier: docs/canon/levels/L007_8.md. The Captain's Journal (1705) is
## in-universe TESTIMONY; the article voice wins where they differ.
##
## PLAN (read -> design):
## - SOURCE: an endless, nearly motionless saline sea under a bright sun that never moves,
##   broken by wooden houses on stilts of wood, metal and concrete; villages of about ten
##   structures joined by bridges; the seabed 20 m down (sand, rocks, metal, coral) ->
##   one authored stilt village (9 houses + a water-level landing), stilts running to the
##   seabed, rope-and-plank bridges, two-storey houses with outside stairs and balconies,
##   houses full of supplies; a 4.4 km sea window with streamed lone houses and drifting
##   boats toward a hazy horizon (ChunkWorld; finite streaming window).
## - SOURCE: houses on concrete columns are the best stocked and safest -> the central
##   house stands on concrete; bridges may break -> one seeded side bridge gives way under
##   you (stateful, remembered) and drops you in the sea; ladders lead back up.
## - SOURCE: Deep Eyes, subsided holes in the seabed, semi-dark, coral and fish, used for
##   fishing; Level 8 exits were found in them -> a 76 m Eye east of the village with coral
##   on its rim and fish schools; a dark opening in its wall at -48 m is the L008 exit
##   (created only once you dive into the Eye; ADAPTATION: depth and spot are ours).
## - SOURCE: houses with snow on the roof that never melts in the glaring sun hold an
##   entrance to Level 7.7 -> one house apart from the rest, roof under snow; its doorway
##   is the walk-in exit; the from_L007_7 arrival steps out of that door.
## - SOURCE: deserted drifting vessels; rifts and impossible ships in the distant waves
##   (RUMORED) -> a moored rowing boat; casting off is the rumoured voyage (EXT#3).
## - SOURCE: Seawalkers, 40-70 m four-legged crab-like giants with grey skin and white
##   empty eyes wearing stilt houses as shells, groups of 3+, only in water <= 20 m, not
##   aggressive -> three walk a slow circuit 330 m out and never enter the Eye; domestic
##   gulls circle the roofs; compasses spin (journal); a metal box plays music (journal).
## - ABSENT: hostile sea monsters, storms, waves, day/night, a route back to Level 7.

const V := preload("res://levels/L007_8/L007_8_village.gd")
const S := preload("res://levels/L007_8/L007_8_sea.gd")
const LANDING := Vector3(7.6, 0.5, -17.0)
const BOAT := Vector3(12.4, 0.0, -17.0)

var nz := FastNoiseLite.new()
var world: ChunkWorld
var sea: WaterVolume
var houses: Array = []
var bridges: Array = []          # [{a, b, weak, kit}]
var weak_idx := -1
var weak_t := 0.0
var bridge_broken := false
var walkers: Array = []
var gulls: Array = []
var schools: Array = []
var eye_exit_made := false
var compass_turns := 0
var music_plays := 0
var _clock := 0.0
var _said := {}
var _under := false


func build() -> void:
	nz.seed = level_seed
	nz.frequency = 0.08
	rules["view_distance"] = 1600.0
	rules["oxygen_seconds"] = 80.0
	rules["kill_y"] = -300.0
	rules["reverb_room"] = 0.1
	rules["reverb_wet"] = 0.03
	outdoor_env(Color(0.2, 0.4, 0.72), Color(0.68, 0.78, 0.86), Color(0.08, 0.18, 0.24), Vector2(58.0, 35.0),
		Color(1.0, 0.96, 0.9), 1.55, Color(0.68, 0.78, 0.86), 0.0016)
	environment.ambient_light_energy = 0.7
	environment.tonemap_exposure = 1.0
	environment.fog_sky_affect = 0.5
	environment.fog_aerial_perspective = 0.6
	sun.directional_shadow_max_distance = 90.0
	_materials()
	sea = WaterVolume.new()
	sea.name = "Sea"
	add_child(sea)
	sea.setup(Vector3(-S.WORLD_R, -200.0, -S.WORLD_R), Vector3(S.WORLD_R, 0.0, S.WORLD_R), "l78_sea", true)
	sea.fog_color = Color(0.06, 0.32, 0.36)
	sea.fog_density = 0.035
	sea.tint = Color(0.2, 0.55, 0.6)
	S.seabed(self, nz)
	_village()
	schools = S.eye_life(self, rng)
	_walkers()
	_gulls()
	world = ChunkWorld.new()
	world.name = "Horizon"
	world.chunk_size = 160.0
	world.radius = 3
	world.unload_radius = 4
	world.builder = func(cx: int, cz: int, _v: int, node: Node3D) -> Dictionary: return S.chunk(self, cx, cz, node, level_seed)
	add_child(world)
	world.build_around(Vector3.ZERO, 3)
	_sounds()
	add_arrival("start", Vector3(-5.3, 3.25, 1.8), 90.0)
	var snow: Dictionary = houses[8]
	add_arrival("from_L007_7", (snow["door_pos"] as Vector3) + Vector3(0.4, 0.05, 0.0), -90.0)
	var t := add_exit("L007_8>L007_7#2", "walk_in", (snow["inside"] as Vector3) + Vector3(0, 1.1, 0), Vector3(1.6, 2.2, 1.8),
		"Step into the house with the snow that never melts")
	if t:
		t.hold_seconds = 0.0
	add_exit("L007_8>EXT#3", "interact", LANDING + Vector3(2.0, 1.0, 0.0), Vector3(1.6, 2.0, 3.0),
		"Cast off in the drifting boat, toward the distant waves (rumoured rifts and impossible ships)")
	add_landmark("House on concrete columns", Vector3(0, 3.2, 0))
	add_landmark("Snow-roofed house", snow["c"])
	add_landmark("Deep Eye", S.EYE)
	add_landmark("Landing and boat", LANDING)
	add_shot("village_from_balcony", Vector3(8.6, 7.85, 11.6), Vector3(-22.0, 3.0, -12.0), {"flashlight": false})
	add_shot("snow_roof_house", Vector3(-19.0, 4.8, -9.5), Vector3(-31.0, 5.5, -15.0), {"flashlight": false})
	add_shot("seawalkers", Vector3(30.5, 4.55, 6.8), Vector3(240.0, 26.0, 230.0), {"flashlight": false, "prepare": _prep_walkers})
	add_shot("deep_eye_dive", S.EYE + Vector3(-26.0, -16.0, -12.0), S.EYE + Vector3(-36.0, -27.0, -14.0), {"flashlight": false})
	add_shot("house_interior", Vector3(-2.6, 4.85, 1.6), Vector3(3.5, 3.9, -2.8), {"flashlight": false})


func _materials() -> void:
	MatLib.register("l78_sea", MatLib.water({"shallow_color": Color(0.12, 0.52, 0.56), "deep_color": Color(0.02, 0.13, 0.22),
		"absorption": 0.035, "clarity": 0.93, "wave_height": 0.02, "wave_scale": 0.35, "wave_speed": 0.2, "foam_amount": 0.12}))
	var paint := {"blue": [Color(0.36, 0.52, 0.62), Color(0.30, 0.45, 0.55)], "red": [Color(0.55, 0.22, 0.18), Color(0.47, 0.18, 0.15)],
		"green": [Color(0.38, 0.52, 0.42), Color(0.31, 0.44, 0.35)], "white": [Color(0.82, 0.81, 0.76), Color(0.74, 0.73, 0.68)],
		"yellow": [Color(0.78, 0.66, 0.38), Color(0.70, 0.58, 0.32)]}
	for key in paint.keys():
		MatLib.define("l78_paint_" + key, {"albedo_a": paint[key][0], "albedo_b": paint[key][1], "pattern": 3,
			"pattern_scale": Vector2(3.2, 0.19), "grout_width": 0.012, "grout_color": Color(0.16, 0.14, 0.12), "pattern_strength": 0.3,
			"tile_variation": 0.05, "noise_scale": 1.3, "stain_amount": 0.35, "stain_color": Color(0.35, 0.33, 0.28), "peel_amount": 0.25,
			"peel_color": Color(0.36, 0.27, 0.19), "roughness_a": 0.8, "roughness_b": 0.95, "bump_strength": 0.8,
			"grime_height": 0.5, "grime_color": Color(0.25, 0.25, 0.22)}, "")
	MatLib.define("l78_wood_stilt", {"albedo_a": Color(0.28, 0.22, 0.16), "albedo_b": Color(0.20, 0.16, 0.12), "noise_scale": 2.0,
		"stain_amount": 0.4, "stain_color": Color(0.15, 0.17, 0.14), "wetness": 0.4, "roughness_a": 0.7, "roughness_b": 0.95, "bump_strength": 1.2}, "")
	MatLib.define("l78_wood_rail", {"albedo_a": Color(0.52, 0.48, 0.42), "albedo_b": Color(0.42, 0.38, 0.33), "noise_scale": 3.0,
		"stain_amount": 0.3, "roughness_a": 0.85, "roughness_b": 1.0, "bump_strength": 0.8}, "")
	MatLib.define("l78_rope", {"albedo_a": Color(0.62, 0.54, 0.40), "albedo_b": Color(0.52, 0.45, 0.33), "noise_scale": 8.0}, "")
	MatLib.define("l78_trim", {"albedo_a": Color(0.86, 0.85, 0.80), "albedo_b": Color(0.78, 0.77, 0.72), "stain_amount": 0.3,
		"stain_color": Color(0.6, 0.58, 0.5), "roughness_a": 0.6, "roughness_b": 0.8}, "")
	MatLib.define("l78_ceiling", {"albedo_a": Color(0.62, 0.55, 0.45), "albedo_b": Color(0.55, 0.48, 0.39), "pattern": 3,
		"pattern_scale": Vector2(2.4, 0.15), "grout_width": 0.01, "grout_color": Color(0.3, 0.25, 0.2)}, "")
	MatLib.define("l78_snow", {"albedo_a": Color(0.94, 0.95, 0.97), "albedo_b": Color(0.86, 0.88, 0.92), "noise_scale": 1.6,
		"roughness_a": 0.55, "roughness_b": 0.8, "bump_strength": 0.6}, "")
	MatLib.define("l78_roof_tar", {"albedo_a": Color(0.16, 0.16, 0.17), "albedo_b": Color(0.12, 0.12, 0.13), "pattern": 2,
		"pattern_scale": Vector2(0.9, 0.9), "pattern_color": Color(0.2, 0.2, 0.21), "pattern_strength": 0.4, "stain_amount": 0.4,
		"stain_color": Color(0.3, 0.3, 0.27), "roughness_a": 0.8, "roughness_b": 0.95}, "")
	MatLib.define("l78_boat_paint", {"albedo_a": Color(0.25, 0.47, 0.46), "albedo_b": Color(0.20, 0.38, 0.37), "pattern": 3,
		"pattern_scale": Vector2(2.0, 0.16), "grout_width": 0.01, "grout_color": Color(0.1, 0.1, 0.1), "peel_amount": 0.35,
		"peel_color": Color(0.4, 0.3, 0.2)}, "")
	MatLib.define("l78_coral_sand", {"albedo_a": Color(0.86, 0.80, 0.66), "albedo_b": Color(0.76, 0.70, 0.56), "pattern": 13, "noise_scale": 0.5}, "")
	MatLib.define("l78_eye_rock", {"albedo_a": Color(0.36, 0.38, 0.36), "albedo_b": Color(0.24, 0.27, 0.27), "pattern": 11,
		"pattern_strength": 0.4, "noise_scale": 0.15, "bump_strength": 2.0}, "")
	MatLib.define("l78_abyss_rock", {"albedo_a": Color(0.08, 0.1, 0.12), "albedo_b": Color(0.04, 0.05, 0.07), "pattern": 11, "noise_scale": 0.12}, "")
	var corals := {"pink": Color(0.72, 0.36, 0.42), "orange": Color(0.8, 0.45, 0.22), "purple": Color(0.42, 0.28, 0.52), "yellow": Color(0.74, 0.66, 0.34)}
	for key in corals.keys():
		var c: Color = corals[key]
		MatLib.define("l78_coral_" + key, {"albedo_a": c, "albedo_b": c.darkened(0.25), "noise_scale": 6.0, "bump_strength": 1.5, "roughness_a": 0.8}, "")
	for f in [["a", Color(0.95, 0.75, 0.15)], ["b", Color(0.2, 0.55, 0.95)], ["c", Color(0.95, 0.4, 0.25)]]:
		MatLib.define("l78_fish_" + str(f[0]), {"albedo_a": f[1], "albedo_b": (f[1] as Color).lightened(0.2), "emission_color": f[1], "emission_energy": 0.25}, "")
	MatLib.define("l78_nest", {"albedo_a": Color(0.42, 0.34, 0.24), "albedo_b": Color(0.30, 0.24, 0.17), "noise_scale": 12.0, "bump_strength": 2.0}, "dirt")


# --------------------------------------------------------------------- the village

func _village() -> void:
	var specs := [
		{"c": Vector3(0, 3.2, 0), "w": 9.0, "d": 7.0, "floors": 2, "stilt": "concrete", "paint": "l78_paint_white", "roof": "rust", "door": "s", "porch": 1.6},
		{"c": Vector3(15, 3.0, -6), "w": 6.0, "d": 5.0, "stilt": "wood", "paint": "l78_paint_blue", "roof": "l78_roof_tar", "door": "w", "porch": 1.2},
		{"c": Vector3(13, 3.4, 11), "w": 7.0, "d": 5.5, "floors": 2, "stilt": "metal", "paint": "l78_paint_red", "roof": "rust", "door": "w", "porch": 1.6},
		{"c": Vector3(-14, 2.8, 7), "w": 5.5, "d": 5.0, "stilt": "wood", "paint": "l78_paint_green", "roof": "l78_roof_tar", "door": "e", "porch": 1.2},
		{"c": Vector3(-15, 3.0, -8), "w": 6.0, "d": 6.0, "stilt": "wood", "paint": "l78_paint_yellow", "roof": "rust", "door": "e", "porch": 1.2},
		{"c": Vector3(2, 3.2, 19), "w": 6.0, "d": 5.0, "stilt": "metal", "paint": "l78_paint_blue", "roof": "rust", "door": "n", "porch": 1.2},
		{"c": Vector3(28, 2.9, 4), "w": 5.0, "d": 5.0, "stilt": "wood", "paint": "l78_paint_white", "roof": "l78_roof_tar", "door": "w", "porch": 1.2},
		{"c": Vector3(-3, 3.0, -17), "w": 6.0, "d": 5.0, "stilt": "wood", "paint": "l78_paint_red", "roof": "l78_roof_tar", "door": "n", "porch": 1.2},
		{"c": Vector3(-31, 3.1, -15), "w": 6.0, "d": 5.0, "stilt": "wood", "paint": "l78_paint_white", "roof": "l78_roof_tar", "door": "e", "porch": 1.4, "snow": true}]
	var links := [[0, 1], [0, 2], [0, 3], [3, 4], [4, 8], [0, 7], [2, 5], [1, 6], [2, 6], [0, 4], [0, 5]]
	var weak_choices := [7, 8]
	weak_idx = int(weak_choices[rng.randi() % weak_choices.size()])
	bridge_broken = SessionState.is_story() and bool(SaveService.flag(stable_id, "bridge_broken", false))
	var gaps: Array = []
	for i in specs.size():
		gaps.append([])
	for l in links:
		var a: Dictionary = specs[l[0]]
		var b: Dictionary = specs[l[1]]
		var pa := V.edge_toward(a, b["c"])
		var pb := V.edge_toward(b, a["c"])
		gaps[l[0]].append(pa)
		gaps[l[1]].append(pb)
		bridges.append({"a": pa, "b": pb, "weak": bridges.size() == weak_idx})
	gaps[7].append(Vector3(1.2, 3.0, -17.0))
	var k := kit("Village")
	var hr := RandomNumberGenerator.new()
	hr.seed = 78
	for i in specs.size():
		var h: Dictionary = specs[i]
		var info := V.house(k, h, hr, gaps[i])
		h.merge(info)
		houses.append(h)
	for i in bridges.size():
		var br: Dictionary = bridges[i]
		if br["weak"]:
			continue
		V.bridge(k, br["a"], br["b"], hr, false)
	# landing at the waterline, stair up to the red house, ladder from the sea
	k.slab(LANDING.x - 2.5, LANDING.z - 2.0, LANDING.x + 2.5, LANDING.z + 2.0, LANDING.y, 0.3, "wood_floor")
	for sx in [-2.2, 0.0, 2.2]:
		for sz in [-1.7, 1.7]:
			k.cylinder(Vector3(LANDING.x + sx, (LANDING.y - 0.3 + V.SEABED) * 0.5, LANDING.z + sz), 0.15, LANDING.y - 0.3 - V.SEABED, "l78_wood_stilt", 7)
	k.stairs(Vector3(5.12, LANDING.y, -17.0), Vector3(-1, 0, 0), 1.2, 3.0 - LANDING.y, 14, "wood_floor", 0.28, false)
	V.rails(k, Rect2(LANDING.x - 2.5, LANDING.z - 2.0, 5.0, 4.0), LANDING.y, [Vector3(5.1, 0, -17.0), LANDING + Vector3(2.5, 0, 0), LANDING + Vector3(0, 0, -2.0)])
	for i in 9:
		k.box(LANDING + Vector3(0, -2.4 + i * 0.36, -2.05), Vector3(0.7, 0.05, 0.06), "l78_wood_rail", GeoKit.ALL, false)
	for sx in [-0.36, 0.36]:
		k.box(LANDING + Vector3(sx, -1.0, -2.05), Vector3(0.06, 3.4, 0.06), "l78_wood_rail", GeoKit.ALL, false)
	V.boat(k, BOAT, 0.0, "l78_boat_paint")
	k.commit()
	var lad := LadderVolume.new()
	add_child(lad)
	lad.setup(LANDING + Vector3(-0.6, -3.0, -2.7), LANDING + Vector3(0.6, 1.4, -1.7))
	if not bridge_broken:
		_weak_bridge()
	_dress_houses()


func _weak_bridge() -> void:
	var br: Dictionary = bridges[weak_idx]
	var kb := kit("WeakBridge")
	var r := RandomNumberGenerator.new()
	r.seed = level_seed + 7
	V.bridge(kb, br["a"], br["b"], r, true)
	kb.commit()
	br["kit"] = kb.root


func _dress_houses() -> void:
	var d := Node3D.new()
	d.name = "Supplies"
	add_child(d)
	var ids := ["ph/barrel_03", "ph/Barrel_01", "ph/propane_tank", "ph/barrel_03", "ph/Shelf_01"]
	var big := ["ph/wooden_crate_01", "ph/dining_table", "ph/steel_frame_shelves_02", "ph/barrel_03"]
	for hi in [0, 1, 2, 3, 4, 5, 7]:
		var h: Dictionary = houses[hi]
		var c: Vector3 = h["c"]
		var w: float = h["w"]
		var dd: float = h["d"]
		var dn: Vector3 = h["dn"]
		var floors: int = h.get("floors", 1)
		for fl in floors:
			var y := c.y + fl * 2.8
			var n := rng.randi_range(6, 9) if hi == 0 else rng.randi_range(4, 6)
			for j in n:
				var side := j % 4
				var wn := [Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)][side] as Vector3
				if wn.dot(dn) > 0.5:
					wn = -dn
				var along := rng.randf_range(-0.38, 0.38)
				var depth := (dd if absf(wn.z) > 0.5 else w) * 0.5
				var span := (w if absf(wn.z) > 0.5 else dd)
				var id: String = (big + ids)[rng.randi() % (big.size() + ids.size())]
				var bb := Props.bounds(id)
				var inset := maxf(bb.size.x, bb.size.z) * 0.5 + 0.1
				var lim := maxf(0.0, span * 0.5 - inset)
				var p := Vector3(c.x, y, c.z) + wn * (depth - inset) + wn.cross(Vector3.UP) * clampf(along * span, -lim, lim)
				var held := Props.place(self, d, id, p, rad_to_deg(atan2(wn.x, wn.z)) + 180.0, 0.0, id in big)
				if held and id in ["ph/wooden_crate_01", "ph/dining_table", "ph/steel_frame_shelves_02"]:
					for bx in rng.randi_range(1, 3):
						Props.place(self, d, "kenney/furniture-kit/cardboardboxclosed", p + Vector3(rng.randf_range(-0.25, 0.25), 0.36 if id == "ph/wooden_crate_01" else (0.88 if id == "ph/dining_table" else 0.05), rng.randf_range(-0.15, 0.15)), rng.randf() * 360.0, rng.randf_range(0.25, 0.4))
			if hi in [0, 2]:
				Props.place(self, d, "ph/lantern_chandelier_01", Vector3(c.x, y + 1.72, c.z), 0.0)
		if hi in [0, 5, 7]:
			Props.place(self, d, "ph/lifebuoy", Vector3(c.x, c.y + 1.3, c.z) + dn * ((dd if absf(dn.z) > 0.5 else w) * 0.5 + 0.09) + dn.cross(Vector3.UP) * 1.1, rad_to_deg(atan2(dn.x, dn.z)))
		add_child(_room_light(Vector3(c.x, c.y + 2.2, c.z)))
	var h0c: Vector3 = houses[0]["c"]
	Props.place(self, d, "ph/dining_table", h0c + Vector3(1.0, 0, -0.6), 90.0, 0.0, true)
	Props.place(self, d, "ph/vintage_radio_transceiver", h0c + Vector3(1.0, 0.88, -0.9), 120.0)
	Props.place(self, d, "ph/dining_chair_02", h0c + Vector3(-0.2, 0, -0.6), 80.0)
	Props.place(self, d, "ph/dining_chair_02", h0c + Vector3(2.1, 0, -0.4), -100.0)
	# the concrete-column house is the best stocked: a wall of shelving and stacked crates
	for i in 4:
		var sp := h0c + Vector3(-3.6 + i * 0.62, 0, -3.1)
		Props.place(self, d, "ph/steel_frame_shelves_02", sp, 0.0, 0.0, i == 0)
		for lv in [0.08, 0.72, 1.38]:
			for bx in 2:
				Props.place(self, d, "kenney/furniture-kit/cardboardboxclosed", sp + Vector3(-0.14 + bx * 0.28, lv, 0.0), rng.randf_range(-15.0, 15.0), rng.randf_range(0.22, 0.3))
	for i in 3:
		Props.place(self, d, "ph/wooden_crate_01", h0c + Vector3(3.6, i * 0.35, 2.4), 90.0 + rng.randf_range(-8.0, 8.0), 0.0, i == 0)
	Props.place(self, d, "ph/barrel_03", h0c + Vector3(3.7, 0, 0.9), 0.0, 0.0, true)
	Props.place(self, d, "ph/Barrel_01", h0c + Vector3(3.6, 0, 0.1), 40.0, 0.0, true)
	# gull nests on the rails and roofs
	var kn := kit("Nests")
	for hi in [1, 3, 6, 5, 8]:
		var r: Rect2 = houses[hi]["rect"]
		var hc: Vector3 = houses[hi]["c"]
		kn.cylinder(Vector3(r.position.x + 0.35, hc.y + 1.12, r.position.y + 0.35), 0.28, 0.14, "l78_nest", 7, false)
	kn.commit()
	var h0: Vector3 = houses[0]["c"]
	add_note("l78_settler_notes", "Notes pinned inside the door", "Someone's notes for whoever comes next, in short:\n\n" +
		"- Search the houses on concrete columns first: most supplies, and they stay standing.\n- Bridges break and stilts snap. Test every plank.\n" +
		"- The walkers with houses on their backs only wade where it is shallow, twenty metres or less. They leave you alone, but they may want your house.\n" +
		"- East of here the seabed falls into one of the Deep Eyes. Fish there. People say ways down to Level 8 are in them.\n" +
		"- A house with snow on its roof that never melts has a way into Level 7.7.\n- The Grand Colony feeds anyone who works. I never found out which way it lies.",
		Vector3(h0.x - 3.2, h0.y + 1.2, h0.z + 2.6), Vector3(0.4, 0.5, 0.4))
	var h2: Vector3 = houses[2]["c"]
	Props.place(self, d, "ph/dining_table", Vector3(h2.x, h2.y + 2.8, h2.z), 0.0, 0.0, true)
	add_interactable(Vector3(h2.x, h2.y + 3.8, h2.z), Vector3(1.0, 0.6, 0.8), "Look at the brass compass on the table", func(_p = null): _compass())
	var h5: Vector3 = houses[5]["c"]
	Props.place(self, d, "ph/metal_tool_chest", Vector3(h5.x - 1.8, h5.y, h5.z - 1.6), 30.0)
	add_interactable(Vector3(h5.x - 1.8, h5.y + 0.6, h5.z - 1.6), Vector3(0.8, 0.8, 0.8), "Touch the odd metal box", func(_p = null): _music_box())
	add_interactable(Vector3(houses[1]["c"].x, houses[1]["c"].y + 0.8, houses[1]["c"].z), Vector3(3.0, 1.2, 2.5), "Search the house", func(_p = null):
		Overlay.toast("Shelves of tins, coils of rope, jugs of rain water, a net mended many times. The house is full, as if someone had just stocked it.", 5.0))


func _room_light(p: Vector3) -> OmniLight3D:
	var o := OmniLight3D.new()
	o.position = p
	o.light_color = Color(1.0, 0.93, 0.82)
	o.light_energy = 0.45
	o.omni_range = 5.5
	return o


# --------------------------------------------------------------------- life

func _walkers() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = level_seed + 31
	var phase := r.randf() * TAU
	for i in 3:
		var w: Dictionary = S.seawalker(self, r.randf_range(42.0, 66.0) if i > 0 else 64.0, r)
		w["lag"] = float(i) * 0.11
		w["side"] = float(i - 1) * 34.0
		w["phase0"] = phase
		walkers.append(w)
	_place_walkers(0.0)


func _walker_pos(t: float, w: Dictionary) -> Transform3D:
	var a := float(w["phase0"]) + t * 0.0042 - float(w["lag"])
	var rad := 330.0 + float(w["side"])
	var p := Vector3(cos(a) * rad, 0.0, sin(a) * rad)
	var fwd := Vector3(-sin(a), 0, cos(a))
	return Transform3D(Basis.looking_at(fwd, Vector3.UP, true), p)


func _place_walkers(t: float) -> void:
	for w in walkers:
		var xf := _walker_pos(t, w)
		var root: Node3D = w["root"]
		var hgt: float = w["height"]
		var gait := t * 0.55
		root.transform = xf
		root.position.y = sin(gait * 2.0) * hgt * 0.004
		for leg in w["legs"]:
			var swing := sin(gait + float(leg["phase"]) * TAU) * 0.22
			(leg["hip"] as Node3D).rotation.x = float(leg["fz"]) * 0.25 + swing
			(leg["knee"] as Node3D).rotation.x = maxf(0.0, -swing) * 0.6


func _gulls() -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.92, 0.92, 0.9)
	m.roughness = 0.9
	for i in 9:
		var g: Dictionary = S.gull(self, m)
		g["rad"] = rng.randf_range(8.0, 26.0)
		g["h"] = rng.randf_range(9.0, 17.0)
		g["spd"] = rng.randf_range(0.25, 0.45) * (1.0 if i % 3 else -1.0)
		g["a"] = rng.randf() * TAU
		g["c"] = (houses[rng.randi() % 6]["c"] as Vector3)
		gulls.append(g)


func _sounds() -> void:
	sound.bed("water_bed", {"seconds": 8.0, "bright": 650.0}, -25.0)
	sound.bed("wind", {"seconds": 10.0}, -31.0)
	sound.oneshot("creak", {"freq": 210.0}, 6.0, 15.0, 12.0, "[wooden stilts creak]", -12.0)
	sound.oneshot("splash", {}, 9.0, 22.0, 30.0, "[something splashes, far off]", -20.0)


# --------------------------------------------------------------------- mechanics

func level_process(delta: float) -> void:
	_clock += delta
	_place_walkers(_clock)
	for g in gulls:
		g["a"] = float(g["a"]) + float(g["spd"]) * delta
		var a: float = g["a"]
		var root: Node3D = g["root"]
		var c: Vector3 = g["c"]
		root.position = c + Vector3(cos(a) * float(g["rad"]), float(g["h"]) + sin(_clock * 0.7 + a) * 0.6, sin(a) * float(g["rad"]))
		root.rotation.y = -a + (0.0 if float(g["spd"]) > 0.0 else PI)
		for wg in g["wings"]:
			(wg["pivot"] as Node3D).rotation.z = float(wg["s"]) * sin(_clock * 7.0 + a * 3.0) * 0.55
	for s in schools:
		(s["node"] as Node3D).rotation.y += float(s["speed"]) * delta
	if player == null or not is_instance_valid(player):
		return
	world.target = player
	var p := player.global_position
	_underwater(p)
	_bridge_strain(delta, p)
	if not eye_exit_made and not SessionState.is_qa() and p.y < -22.0 and Vector2(p.x - S.EYE.x, p.z - S.EYE.z).length() < S.EYE_R:
		_make_eye_exit()
	var far := Vector2(p.x, p.z).length()
	sea.current = Vector3(-p.x, 0, -p.z).normalized() * 1.2 if far > 1500.0 else Vector3.ZERO
	if far > 1500.0:
		_say("far", "[however you swim, the still water carries you back toward the houses]", 5.0)
	if p.y > 2.0 and Vector2(p.x, p.z).distance_to(Vector2((walkers[0]["root"] as Node3D).position.x, (walkers[0]["root"] as Node3D).position.z)) < 420.0:
		_say("walkers", "[far off, houses walk on long grey legs: Seawalkers, wading where the sea is shallow]", 6.0)


func _underwater(p: Vector3) -> void:
	var cam := player.camera.global_position
	var under := cam.y < 0.0
	if under:
		var depth := -cam.y
		var dark := clampf((depth - 20.0) / 50.0, 0.0, 1.0)
		environment.fog_light_color = Color(0.04, 0.24, 0.32).lerp(Color(0.005, 0.02, 0.05), dark)
		environment.fog_density = lerpf(0.035, 0.08, dark)
		environment.fog_sky_affect = 1.0
		environment.ambient_light_energy = lerpf(0.55, 0.06, dark)
		sun.light_energy = lerpf(1.1, 0.0, dark)
	elif _under:
		environment.fog_light_color = Color(0.68, 0.78, 0.86)
		environment.fog_density = 0.0016
		environment.fog_sky_affect = 0.5
		environment.ambient_light_energy = 0.7
		sun.light_energy = 1.55
	_under = under


## Bridges may break (SOURCE). The seeded weak bridge creaks under you, then goes.
func _bridge_strain(delta: float, p: Vector3) -> void:
	if bridge_broken or weak_idx < 0 or SessionState.is_qa():
		return
	var br: Dictionary = bridges[weak_idx]
	var a: Vector3 = br["a"]
	var b: Vector3 = br["b"]
	var ab := Vector2(b.x - a.x, b.z - a.z)
	var t := clampf(Vector2(p.x - a.x, p.z - a.z).dot(ab) / ab.length_squared(), 0.0, 1.0)
	var on := Vector2(p.x, p.z).distance_to(Vector2(a.x, a.z) + ab * t) < 0.8 and t > 0.15 and t < 0.85 and absf(p.y - lerpf(a.y, b.y, t)) < 0.6
	if on:
		weak_t += delta
		if weak_t > 0.8:
			_say("creak", "[the planks groan and sag under you]", 2.0)
		if weak_t > 2.2:
			break_bridge()
	else:
		weak_t = maxf(0.0, weak_t - delta)


func break_bridge() -> void:
	bridge_broken = true
	var br: Dictionary = bridges[weak_idx]
	if br.has("kit") and is_instance_valid(br["kit"]):
		(br["kit"] as Node).queue_free()
	if SessionState.is_story():
		SaveService.set_flag(stable_id, "bridge_broken", true)
	if player:
		sound.play_at("creak", {"freq": 120.0}, player.global_position, 2.0, "[the bridge gives way]")
		sound.play_at("splash", {}, player.global_position + Vector3.DOWN * 3.0, 0.0, "")


func _make_eye_exit() -> void:
	eye_exit_made = true
	var a := deg_to_rad(205.0)
	var mouth := S.EYE + Vector3(cos(a) * (S.EYE_R - 2.5), -48.0, sin(a) * (S.EYE_R - 2.5))
	var k := kit("EyeOpening")
	k.box(mouth + Vector3(cos(a), 0, sin(a)) * 2.4, Vector3(5.0, 5.0, 5.0), "unlit_black", GeoKit.ALL, false)
	k.commit()
	make_exit("L007_8>L008#1", "walk_in", mouth, Vector3(5.0, 5.0, 5.0), "", self)
	_say("eye", "[the Eye's wall opens into a black hole here; the water pulls toward it]", 5.0)


func _compass() -> void:
	compass_turns += 1
	Overlay.toast("The needle will not settle. It swings round and round, as the old captain's journal says theirs did.", 4.5)


func _music_box() -> void:
	music_plays += 1
	sound.play_at("music_box", {"notes": 10, "root": 523.0}, player.global_position + Vector3(0, 1.4, 0), -4.0, "[a tinkling tune that seems to play only for you]")
	Overlay.toast("A box of some unknown metal, smooth as a pebble. Touch it in the right place and it plays music, close, as if inside your own ears.", 5.0)


func _say(key: String, text: String, secs: float) -> void:
	if _said.has(key) or SessionState.is_qa():
		return
	_said[key] = true
	Overlay.subtitle(text, secs)


func _prep_walkers() -> void:
	# put the herd where the camera looks, mid-stride
	for w in walkers:
		w["phase0"] = atan2(230.0, 240.0) - 0.05
	_clock = 9.0
	_place_walkers(_clock)
	await get_tree().process_frame


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "snow-roof door and the boat are the exits near start", "ok": exits.size() == 2})
	out.append({"what": "about ten structures (9 houses + landing)", "ok": houses.size() == 9})
	var space := get_world_3d().direct_space_state
	var bed := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-60, -1, 40), Vector3(-60, -40, 40), 1))
	out.append({"what": "seabed 20 m down", "ok": not bed.is_empty() and absf((bed["position"] as Vector3).y + 20.0) < 2.0, "detail": bed.get("position")})
	var eye := space.intersect_ray(PhysicsRayQueryParameters3D.create(S.EYE + Vector3(0, -1, 0), S.EYE + Vector3(0, -260, 0), 1))
	out.append({"what": "the Deep Eye drops far below the seabed", "ok": not eye.is_empty() and (eye["position"] as Vector3).y < -150.0})
	var bad: Array = []
	for i in bridges.size():
		var br: Dictionary = bridges[i]
		var m: Vector3 = ((br["a"] as Vector3) + (br["b"] as Vector3)) * 0.5
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(m + Vector3.UP * 1.0, m + Vector3.DOWN * 2.0, 1))
		if hit.is_empty() or absf((hit["position"] as Vector3).y - m.y) > 0.3:
			bad.append(i)
	out.append({"what": "every bridge carries you", "ok": bad.is_empty(), "detail": bad})
	var near := INF
	var shallow := true
	for k in 120:
		for w in walkers:
			var p := _walker_pos(float(k) * 30.0, w).origin
			near = minf(near, Vector2(p.x, p.z).length())
			if Vector2(p.x - S.EYE.x, p.z - S.EYE.z).length() < S.EYE_R + 30.0:
				shallow = false
	out.append({"what": "three Seawalkers keep to shallow water, away from the village and the Eye", "ok": walkers.size() >= 3 and shallow and near > 250.0, "detail": near})
	out.append({"what": "no Level 8 opening until you dive into the Eye", "ok": not eye_exit_made})
	_compass()
	out.append({"what": "compass spins (journal)", "ok": compass_turns == 1})
	var br: Dictionary = bridges[weak_idx]
	var wm: Vector3 = ((br["a"] as Vector3) + (br["b"] as Vector3)) * 0.5
	break_bridge()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var gone := space.intersect_ray(PhysicsRayQueryParameters3D.create(wm + Vector3.UP * 1.0, wm + Vector3.DOWN * 1.5, 1))
	out.append({"what": "the weak bridge gives way", "ok": bridge_broken and gone.is_empty(), "detail": gone.get("position")})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
