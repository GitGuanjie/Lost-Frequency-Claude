extends LevelBase
## Level 108 - "Fertile Grounds" (Backrooms Wikidot rev 39, accessed 2026-11-04;
## cite: DrAkimoto, CC BY-SA 3.0). Dossier: docs/canon/levels/L108.md.
## CONTENT WARNING (page): mutation, predation, implied cult ritual. Kept to
## captions, screen effects and the child's diary (testimony).
##
## PLAN (v2.0 rebuild)
## SOURCE: a verdant primeval forest (the Craterwood) whose trees grow larger
## toward the central crater; flooded areas around fissures (~300 m deep)
## radiating from it, the water unsafe; a mutagenic mist released from the
## crater in step with a slow rise and fall of the floor, rolling across the
## level and gathering in the Hauntwood; effects immediate and irreversible;
## 12 h of light and 18 h of dark; the Hauntwood Expanse beyond: grey, dormant
## hardwoods in spatial superposition that "choose" a position only when
## observed, low entity encounters; keep a straight heading and you leave the
## zone; F.O.R.E.S.T. protocols (filters, sealed supplies, awareness, evade
## flooded areas and Anthosia, skin cover, shelter at New Hereth); teal trail
## guides lead to New Hereth, purple ones mark the known exits; New Hereth is
## ~2 km from the eastern Hauntwood border, partly underground with filtered
## air, B.N.T.G. + U.E.C. + I.M.B.H., 35-40 people, built by Zenith Corp over
## Old Hereth, whose only near-intact building is the Church of Rosmerta
## (records, the child's diary); Dendroids (ambush as dead trees, fear fire),
## Anthosia (bright flowers, toxic pollen), Grimshells (flooded areas, nesting
## pairs), the Black Goat (reported; stalks, wants to be followed).
## ADAPTATION: scale 1 m = 12 m between New Hereth and the Hauntwood (~170 m);
## one fissure ~110 m west; the day is compressed to 2 min light / 3 min dark;
## mist pulses every few minutes; a respirator from New Hereth's rack cuts
## exposure to a tenth; the purple guides end at one marked gap between
## fallen boles (destination not stated); the Hauntwood straight-heading exit
## appears once you have kept one course ~70 m inside it; Dendroid, Grimshell
## and the Goat are scripted presences only (no combat); the Boneyard, the
## Neon Grove, Cass and the crater itself are not built.
## Mechanic: mist exposure meter with irreversible stages, plus Hauntwood
## chunks that re-seed whenever unobserved (ChunkWorld peripheral shift).
## Verticality: the sunken court and underground halls (-4.2 m), the church
## gallery (+2.9 m) and tower, the watch platform (+4.6 m), the fissure.
## Helpers: L108_land.gd, L108_flora.gd, L108_hereth.gd, L108_life.gd.

const LAND := preload("res://levels/L108/L108_land.gd")
const FLORA := preload("res://levels/L108/L108_flora.gd")
const HERETH := preload("res://levels/L108/L108_hereth.gd")
const LIFE := preload("res://levels/L108/L108_life.gd")
const CS := 48.0
const TREE_REACH := 150.0
const DAY_S := 120.0
const NIGHT_S := 180.0

var land
var flora
var her
var life
var world: ChunkWorld
var sky_mat: ProceduralSkyMaterial
var water: WaterVolume
var start := Vector3.ZERO
var exit_c := Vector3.ZERO
var exit_dir := Vector3.ZERO
var clock := 20.0
var night := 0.0
var freeze_clock := false


func build() -> void:
	land = LAND.new()
	flora = FLORA.new()
	life = LIFE.new(self)
	HERETH.materials()
	rules["view_distance"] = 1800.0
	rules["flashlight"] = "allowed"
	rules["kill_y"] = -40.0
	rules["reverb_room"] = 0.2
	rules["reverb_wet"] = 0.08
	outdoor_env(Color(0.36, 0.46, 0.42), Color(0.56, 0.62, 0.52), Color(0.1, 0.12, 0.08), Vector2(58.0, -40.0),
		Color(1.0, 0.94, 0.78), 1.05, Color(0.3, 0.36, 0.27), 0.009)
	sky_mat = environment.sky.sky_material as ProceduralSkyMaterial
	environment.ambient_light_sky_contribution = 0.8
	environment.ambient_light_energy = 0.55
	environment.fog_sky_affect = 0.5
	environment.fog_aerial_perspective = 0.3
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.05
	environment.adjustment_contrast = 1.05
	sun.shadow_blur = 1.6
	sun.directional_shadow_max_distance = 70.0
	lights.setup(8, 0)
	var geo := Node3D.new()
	geo.name = "Terrain"
	add_child(geo)
	land.build_meshes(geo, land.make_material())
	MatLib.register("l108_flood", MatLib.water({"shallow_color": Color(0.08, 0.1, 0.05), "deep_color": Color(0.02, 0.03, 0.015),
		"absorption": 2.6, "clarity": 0.08, "wave_height": 0.01, "wave_scale": 0.2, "foam_amount": 0.0, "dark_surface": 0.85}))
	water = WaterVolume.new()
	water.name = "FloodedFissure"
	add_child(water)
	water.setup(Vector3(LAND.FX - 48.0, -62.0, -LAND.NEAR), Vector3(LAND.FX + 48.0, LAND.WATER_Y, LAND.NEAR), "l108_flood", true)
	water.fog_color = Color(0.03, 0.05, 0.02)
	water.fog_density = 0.6
	water.tint = Color(0.15, 0.22, 0.08)
	var props := Node3D.new()
	props.name = "Dressing"
	add_child(props)
	var k := kit("Hereth")
	her = HERETH.new(self, land, k, props)
	her.church()
	her.ruins()
	her.compound()
	start = Vector3(-38.0, 0.0, 40.0)
	start.y = land.h(start.x, start.z) + 0.05
	exit_c = Vector3(-50.0, 0.0, -50.0)
	exit_c.y = land.h(exit_c.x, exit_c.z)
	exit_dir = Vector3(-0.6, 0, -0.8).normalized()
	var cd: Vector3 = her.spots["church_door"]
	var go: Vector3 = her.spots["gate_out"]
	her.trail([start + Vector3(2.5, 0, -1.0), Vector3(-20, 0, 32), Vector3(-2, 0, 24), Vector3(14, 0, 14), go], "l108_teal", 9.0)
	her.trail([cd + Vector3(-1.5, 0, -3.0), Vector3(-30, 0, -14), Vector3(-42, 0, -38), exit_c - exit_dir * 4.0], "l108_purple", 9.0)
	her.exit_gate(exit_c, exit_dir)
	k.commit()
	for ls in her.lamp_spots:
		lights.add_anchor(ls[0], ls[1], ls[2], ls[3], 0.0, ls[4])
	var ex := add_exit("L108>EXT#2", "walk_in", exit_c + exit_dir * 1.5 + Vector3(0, 1.2, 0), Vector3(3.0, 2.4, 2.0), "")
	ex.rotation.y = atan2(exit_dir.x, exit_dir.z)
	world = ChunkWorld.new()
	world.name = "Chunks"
	world.chunk_size = CS
	world.radius = 3
	world.unload_radius = 4
	world.builder = _chunk
	world.can_shift = func(_k: Vector2i, meta: Dictionary) -> bool: return bool(meta.get("hw", false))
	world.shift_enabled = true
	world.shift_after = 6.0
	add_child(world)
	world.build_around(start, 3)
	life.setup(props)
	_notes()
	life.sounds()
	add_arrival("start", start, rad_to_deg(atan2(-(4.0 - start.x), -(0.0 - start.z))))
	var fa := Vector3(14.0, 0, 58.0)
	fa.y = land.h(fa.x, fa.z) + 0.05
	add_arrival("from_L025", fa, rad_to_deg(atan2(-(4.0 - fa.x), -(0.0 - fa.z))))
	add_landmark("Church of Rosmerta (Old Hereth)", Vector3(0, her.fy, 0))
	add_landmark("New Hereth sunken court", her.spots["court"])
	add_landmark("Purple-marked known exit", exit_c)
	add_landmark("Flooded fissure", Vector3(LAND.FX, 0, 0))
	add_landmark("Hauntwood border", Vector3(LAND.HB, 0, 0))
	_shots()


# ---------------------------------------------------------------- streaming

func _chunk(cx: int, cz: int, v: int, node: Node3D) -> Dictionary:
	var ox := cx * CS
	var oz := cz * CS
	var cc := Vector3(ox + CS * 0.5, 0, oz + CS * 0.5)
	cc.y = land.h(cc.x, cc.z)
	land.collision_tile(node, ox, oz, int(CS))
	var hw: bool = land.haunt_d(cc.x, cc.z) > 8.0
	var r := RandomNumberGenerator.new()
	r.seed = hash([cx, cz, v if hw else 0, level_seed, 108])
	var body := StaticBody3D.new()
	body.name = "Boles"
	node.add_child(body)
	var greens := {}
	var deads := {}
	var ferns: Array = []
	var step := 5.0 if hw else 8.0
	var n := int(CS / step)
	for j in n:
		for i in n:
			var x := ox + (i + r.randf_range(0.1, 0.9)) * step
			var z := oz + (j + r.randf_range(0.1, 0.9)) * step
			if _clear(x, z):
				continue
			var y: float = land.h(x, z)
			var dead_here: bool = land.haunt_d(x, z) > r.randf_range(-12.0, 12.0)
			if dead_here:
				if r.randf() > 0.72:
					continue
				var kk := r.randi() % 3
				var s := r.randf_range(0.85, 1.25)
				if not deads.has(kk):
					deads[kk] = []
				deads[kk].append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(s, s, s)), Vector3(x, y - 0.2, z)))
				_bole(body, Vector3(x, y, z), (0.38 + kk * 0.06) * s)
			else:
				if r.randf() > 0.7:
					continue
				var kk := r.randi() % 4
				var grow := 1.0 + clampf((-x - 40.0) / 150.0, 0.0, 2.6)
				var s := r.randf_range(0.8, 1.15) * grow
				if not greens.has(kk):
					greens[kk] = []
				greens[kk].append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(s, s, s)), Vector3(x, y - 0.3, z)))
				_bole(body, Vector3(x, y, z), (0.75 + kk * 0.12) * s)
			# undergrowth round the boles (the Craterwood only)
			if not dead_here and land.fissure_off(x, z) > LAND.FLOOD_W:
				for f in r.randi_range(1, 4):
					var fp := Vector3(x + r.randf_range(-3.5, 3.5), 0, z + r.randf_range(-3.5, 3.5))
					if _clear(fp.x, fp.z):
						continue
					fp.y = land.h(fp.x, fp.z)
					var fs := r.randf_range(0.8, 1.6)
					ferns.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(fs, fs, fs)), fp))
	for kk in greens.keys():
		var pair: Array = flora.green[kk]
		flora.mm(node, pair[0], flora.bark_mat, greens[kk], cc, TREE_REACH, true)
		flora.mm(node, pair[1], flora.crown_mat, greens[kk], cc, TREE_REACH, true)
	for kk in deads.keys():
		flora.mm(node, flora.dead[kk][0], flora.dead_mat, deads[kk], cc, TREE_REACH, true)
	flora.mm(node, flora.fern, flora.fern_mat, ferns, cc, 60.0)
	# Anthosia patches in the open Craterwood
	if not hw and r.randf() < 0.35:
		var ap := Vector3(ox + r.randf_range(6, CS - 6), 0, oz + r.randf_range(6, CS - 6))
		if not _clear(ap.x, ap.z) and land.fissure_off(ap.x, ap.z) > LAND.FLOOD_W + 4.0:
			life.anthosia(node, ap, r, false)
	# fallen boles
	for f in r.randi_range(0, 2):
		var lp := Vector3(ox + r.randf_range(4, CS - 4), 0, oz + r.randf_range(4, CS - 4))
		if _clear(lp.x, lp.z):
			continue
		lp.y = land.h(lp.x, lp.z) + 0.15
		Props.place(self, node, "ph/dead_tree_trunk", lp, r.randf_range(0, 360), r.randf_range(0.5, 0.9), false, false)
	return {"hw": hw}


func _bole(body: StaticBody3D, p: Vector3, rad: float) -> void:
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = rad * 1.2
	cyl.height = 6.0
	cs.shape = cyl
	cs.position = p + Vector3(0, 2.6, 0)
	cs.set_meta("surface", "wood")
	body.add_child(cs)


## Ground kept free of trees: the village clearing, the compound, trails,
## the exit gate, the arrivals.
func _clear(x: float, z: float) -> bool:
	if Vector2(x - 2.0, z).length() < 44.0:
		return true
	if x > 14.0 and x < 98.0 and z > -24.0 and z < 30.0:
		return true
	var q := Vector2(x, z)
	if q.distance_to(Vector2(exit_c.x, exit_c.z)) < 7.0 or q.distance_to(Vector2(start.x, start.z)) < 6.0 or q.distance_to(Vector2(14, 58)) < 5.0:
		return true
	if land.fissure_off(x, z) < LAND.FLOOD_W - 4.0 or q.distance_to(Vector2(land.fx(-20.0) + 17.0, -20.0)) < 6.0:
		return true
	return _seg(q, Vector2(start.x, start.z), Vector2(-2, 24)) < 3.0 or _seg(q, Vector2(-14, -2), Vector2(exit_c.x, exit_c.z)) < 3.0


func _seg(q: Vector2, a: Vector2, b: Vector2) -> float:
	var t := clampf((q - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
	return q.distance_to(a.lerp(b, t))


# ---------------------------------------------------------------- notes

func _notes() -> void:
	add_note("l108_forest", "F.O.R.E.S.T. (card nailed to a teal guide post)",
		"F - Filters first. Wear a respirator. The mist changes you, and it does not change back.\nO - Only trust sealed supplies. Eat and drink nothing from the level.\nR - Remain aware. Follow trail guides and marked paths.\nE - Evade hazards: flooded ground, Anthosia patches, the Hauntwoods.\nS - Skin coverage. Cover everything you can.\nT - Take shelter. Teal guides lead to New Hereth.",
		start + Vector3(2.5, 1.25, -1.0), Vector3(0.35, 0.4, 0.35), false)
	add_note("l108_diary", "A child's diary (Old Hereth, c. 1906; I.M.B.H. transcription)",
		"TESTIMONY. Paraphrased; spelling kept where quoted.\n\nPapa brought home 'the goat' from the woods. The church sang to Rosmerta; the song made the child's tummy hurt and the church 'smelled like old pennies'.\n\nPapa said God was coming and was like all the Momas. The child's mother was 'taken by the smiling monsters' before they came here.\n\nDreams: a fire in the woods, the goat dancing, everyone changed. A trip to a farm with many sheep; a bag traded for a barrel that smelled like the church. The goat, in a dream, gave God's real name and led the child to big stones in a clearing.\n\nThe last entry: \"Last night I saw God and she was very pretty.\"",
		her.spots["diary"], Vector3(0.45, 0.2, 0.35))
	add_note("l108_records", "Parish register, restored (Church of Rosmerta)",
		"Hereth, late 1800s: thirty-eight people, four dogs, twelve chickens, six cats. Wheat and barley; herbs and food foraged from the forest. The whole village kept the Way of the All-Mother, worshipping Rosmerta, a fertility goddess.\n\nThe registers describe an ordinary forest: no Anthosia, no mist, none of the things out there now.\n\nThe last entries coincide with a large ceremony. After 1906 there is nothing.",
		her.spots["records"], Vector3(0.5, 0.6, 0.4), false)
	add_note("l108_lab", "Whiteboard - B.N.T.G. Medicinal Research Group",
		"Lead: Dr. Melissa Sims (pharmaceutical botany). 8 researchers; admin 2; maintenance 4.\n\nThis week: Anthosia pollen extracts (SEALED HOOD ONLY). Fungal isolates from the north transect. Bark samples - NOT from anything that moved.\n\nReminder: filters are changed at the rack by the door, every excursion, no exceptions.",
		her.spots["lab"], Vector3(0.5, 0.2, 0.35))
	add_note("l108_watch", "Duty roster - U.E.C. Homeland Defense Force, Training Squad Agoge",
		"Sixteen on strength; new recruits rotate in every three months. Watch platform and gate cameras manned at all times. Every research excursion gets an escort.\n\nStanding orders: torches for Dendroids - they will not follow through fire. Nobody wades. Nobody follows the goat.",
		her.spots["watch"], Vector3(0.5, 0.2, 0.35))
	add_note("l108_k3", "I.M.B.H. Outpost K3 - field memo",
		"Twelve staff; most often away on other levels with pre-industrial settlements.\n\nOld Hereth's records point to an ancient, pre-Lost ritual site somewhere on this level. Not found.\n\nSightings to log: Iron Fist (possible outpost?), Amor Incrementum seen entering and leaving. Do not approach either.\n\nZenith Corp built this place in 1987 over Hereth's ruins; the B.N.T.G. took it, and the Level Key, in 2022.",
		her.spots["archive"], Vector3(0.45, 0.2, 0.35))
	add_note("l108_mist", "Posted at the blast door",
		"MIST WARNING\nThe crater breathes out in time with the ground. When the floor lifts, the mist follows within the minute and rolls east, and it pools in the Hauntwood.\n\nThe contagion rewrites the body. Effects are immediate and permanent. Filters on. Doors shut.",
		her.spots["court"] + Vector3(5.6, 1.5, 0.8), Vector3(0.4, 0.5, 0.2), false)
	add_note("l108_gate", "Tag tied to the purple-marked post",
		"KNOWN EXIT - mapped by the B.N.T.G.\nWalk between the posts and keep going. Where it lets out is not written here.",
		exit_c + Vector3(-exit_dir.z, 0, exit_dir.x) * 1.6 + Vector3(0, 1.4, 0), Vector3(0.3, 0.4, 0.3), false)
	add_interactable(her.spots["rack"], Vector3(1.8, 0.8, 0.5), "Take a respirator and a fresh filter", life.take_mask)


# ---------------------------------------------------------------- process

func on_player_ready() -> void:
	world.target = player


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	if not freeze_clock and not SessionState.is_qa():
		clock = fmod(clock + delta, DAY_S + NIGHT_S)
	var want := 0.0
	if clock > DAY_S:
		want = smoothstep(DAY_S, DAY_S + 20.0, clock) * (1.0 - smoothstep(DAY_S + NIGHT_S - 20.0, DAY_S + NIGHT_S, clock))
	night = want
	life.tick(delta, player.global_position)


func apply_sky(mist: float, haunt: float) -> void:
	var n := night
	sun.light_energy = lerpf(1.05, 0.04, n) * (1.0 - 0.35 * mist)
	sun.shadow_enabled = n < 0.7
	sky_mat.sky_top_color = Color(0.36, 0.46, 0.42).lerp(Color(0.01, 0.012, 0.015), n)
	sky_mat.sky_horizon_color = Color(0.56, 0.62, 0.52).lerp(Color(0.015, 0.018, 0.02), n)
	sky_mat.ground_horizon_color = sky_mat.sky_horizon_color
	environment.ambient_light_energy = lerpf(0.55, 0.12, n)
	var fog_day := Color(0.3, 0.36, 0.27).lerp(Color(0.34, 0.36, 0.3), haunt)
	var fog_c := fog_day.lerp(Color(0.012, 0.014, 0.012), n).lerp(Color(0.32, 0.38, 0.24) * (1.0 - 0.85 * n), mist * 0.7)
	environment.fog_light_color = fog_c
	environment.fog_density = 0.009 + 0.012 * haunt + 0.028 * mist


# ---------------------------------------------------------------- QA

func _shots() -> void:
	var cd: Vector3 = her.spots["church_door"]
	var a := Vector3(-21.0, 0.0, 17.0)
	a.y = land.h(a.x, a.z) + 1.62
	add_shot("old_hereth_church", a, Vector3(-3.0, her.fy + 4.5, -1.0), {"flashlight": false, "prepare": _prep_goat.bind(a)})
	var fy: float = her.fy
	add_shot("church_of_rosmerta_nave", Vector3(-8.2, fy + 1.62, -2.2), Vector3(7.0, fy + 1.9, 0.6), {"flashlight": false, "prepare": _prep.bind(cd)})
	var gpos := Vector3(LAND.PIT.position.x - 9.0, 0.0, LAND.PIT.position.y + 10.0)
	gpos.y = land.h(gpos.x, gpos.z) + 2.6
	add_shot("new_hereth_sunken_court", gpos, Vector3(LAND.PIT.end.x, LAND.PIT_FLOOR + 1.6, LAND.PIT.position.y + 11.0), {"flashlight": false, "prepare": _prep.bind(gpos)})
	var fz := -20.0
	var fp := Vector3(land.fx(fz) + 17.0, 0, fz)
	fp.y = maxf(land.h(fp.x, fp.z), LAND.WATER_Y) + 2.4
	add_shot("flooded_fissure", fp, Vector3(land.fx(fz - 35.0), -1.5, fz - 35.0), {"flashlight": false, "prepare": _prep.bind(fp)})
	var hp := Vector3(LAND.HB - 10.0, 0, 30.0)
	hp.y = land.h(hp.x, hp.z) + 1.7
	add_shot("hauntwood_edge", hp, hp + Vector3(30.0, 1.0, 4.0), {"flashlight": false, "prepare": _prep.bind(hp)})


func _prep(p: Vector3) -> void:
	freeze_clock = true
	night = 0.0
	life.freeze_for_shot()
	world.build_around(p, 2)
	await get_tree().process_frame


func _prep_goat(p: Vector3) -> void:
	await _prep(p)
	var gp := Vector3(-30.0, 0, -6.0)
	gp.y = land.h(gp.x, gp.z)
	life.show_goat_at(gp, p)


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "purple-guided known exit present (walk-in)", "ok": exits.size() >= 1 and (exits[0] as ExitTrigger).edge_id == "L108>EXT#2"})
	out.append({"what": "start is in the Craterwood, not the Hauntwood", "ok": land.haunt_d(start.x, start.z) < -100.0})
	out.append({"what": "New Hereth court is below ground (partly underground)", "ok": LAND.PIT_FLOOR < land.h(30.0, 30.0) - 3.0})
	out.append({"what": "fissure is flooded (water volume over the margin)", "ok": water.contains(Vector3(land.fx(0.0) + 8.0, -0.6, 0.0))})
	out.append({"what": "church gallery is a second height", "ok": float((her.spots["gallery"] as Vector3).y) > her.fy + 2.5})
	out.append({"what": "mist exposure starts at zero", "ok": life.exposure == 0.0})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
