extends LevelBase
## Level 9.3 "The Overcast Manifold" (Backrooms Wikidot rev 36, accessed 2026-11-04;
## ForestIsWatching, CC BY-SA 3.0). Dossier: docs/canon/levels/L009_3.md.
##
## PLAN (read -> design):
## - SOURCE: a subsector of Level 9: titanic grassy fields and lonely roads ringed by
##   forested hills, static, overcast, foggy, humid; weak light from the clouds; trees that
##   never move; no inhabitants, no hazards but the place itself. -> streamed 48 m chunks of
##   heightmap terrain under a leaden sky and dense pale fog (L009's suburb, gone outskirts).
## - SOURCE: wheat grown metres high forming an endless labyrinth that diverges toward the
##   buildings. -> a seeded torus maze of 2.6-3.5 m wheat walls (8 m cells, 2.7 m corridors)
##   that opens onto meadows below each hill.
## - SOURCE: one single highway that warps under the fog; tar that tires you; a brittle
##   moss-covered brick and cobble wall under a steel net on one side; roads with no cars but
##   an echo of engines. -> one sinuous highway per period with the netted wall on its west;
##   walking on the tar slows you; the engine swells but never arrives, and calms faster
##   when you crouch hidden in the wheat, bushes or forest ("a blanket to hide under").
## - SOURCE: houses on hilltops: tiny, putrescent, wooden, drenched, filled with utensils,
##   furnishings and beams; a hallway ending in a bathroom with a commode under a casement
##   onto colossal motionless trees; a back door with a frozen knob but weak. -> one house per
##   hill (3 per period) with a plank loft (second walkable height), and the back door as the
##   level's only edge: forcing it puts you "once again within grassy fields" (L009_3>EXT#1,
##   routed to this level's meadow arrival).
## - SOURCE: Möbius terrain, forests that lead back to the fields, an outside visible only as
##   a fuzzy image in the sky. -> the world is periodic (384 m): walk straight through the
##   forest and you come out in the same fields; a faint upside-down landscape in the sky.
## - SOURCE: nothing grows, fades or breaks down. -> no wind sway, no weather, no day cycle.

const W := preload("res://levels/L009_3/L009_3_world.gd")
const G := preload("res://levels/L009_3/L009_3_geo.gd")
const Hs := preload("res://levels/L009_3/L009_3_house.gd")
const CS := W.CS
const FOG := Color(0.66, 0.68, 0.68)

var wm
var geo
var world: ChunkWorld
var qa_fixture := false
var sky_img: MeshInstance3D
var start := Vector3.ZERO
var houses: Array = []            # [{xf (world), exit}]
var engine: AudioStreamPlayer
var rumble: AudioStreamPlayer
var eng_phase := 0                # 0 quiet, 1 swelling, 2 receding
var eng_t := 30.0
var eng_v := 0.0
var hidden := false
var on_tar := false
var tar_t := 0.0
var _period := Vector2i.ZERO
var _said: Dictionary = {}
var wheat_shot := {}


func build() -> void:
	qa_fixture = SessionState.is_qa()
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 260.0
	rules["reverb_room"] = 0.08
	rules["reverb_wet"] = 0.03
	rules["kill_y"] = -60.0
	W.materials()
	Hs.materials()
	wm = W.new(level_seed)
	geo = G.new(wm)
	outdoor_env(Color(0.5, 0.52, 0.54), FOG, Color(0.3, 0.31, 0.28), Vector2(62.0, 140.0), Color(0.86, 0.88, 0.9), 0.6, FOG, 0.017)
	environment.ambient_light_energy = 0.75
	environment.ambient_light_sky_contribution = 0.85
	environment.fog_sky_affect = 0.85
	environment.fog_aerial_perspective = 0.3
	environment.tonemap_exposure = 1.05
	environment.glow_intensity = 0.12
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.82
	environment.adjustment_contrast = 1.05
	sun.shadow_blur = 4.0
	sun.light_angular_distance = 8.0
	sun.directional_shadow_max_distance = 80.0
	var m0: Array = W.MEADOWS[0]
	start = Vector3(m0[0] - 4.0, 0, m0[1] + 4.0)
	start.y = W.h_at(start.x, start.z) + 0.05
	world = ChunkWorld.new()
	world.name = "Fields"
	world.chunk_size = CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _build_chunk
	add_child(world)
	world.build_around(start, 2)
	_arrivals()
	_sky_image()
	_sounds()
	_shots()
	add_landmark("Meadow below the first hill house", start)
	add_landmark("Hilltop house (back door)", W.house_xf(0).origin)
	add_landmark("The highway and its netted wall", Vector3(W.road_u(120.0), W.road_h(120.0), 120.0))


func _arrivals() -> void:
	var face := func(from: Vector3, to: Vector3) -> float:
		return rad_to_deg(atan2(-(to.x - from.x), -(to.z - from.z)))
	var h0: Vector3 = W.house_xf(0).origin
	add_arrival("start", start, face.call(start, h0))
	var f := Vector3(W.FOREST_E + 3.0, 0, 150.0)
	f.y = W.h_at(f.x, f.z) + 0.05
	add_arrival("from_L028", f, -90.0)
	var m1: Array = W.MEADOWS[1]
	var lp := Vector3(m1[0] - 3.0, 0, m1[1] - 3.0)
	lp.y = W.h_at(lp.x, lp.z) + 0.05
	add_arrival("from_L009_3", lp, face.call(lp, W.house_xf(1).origin))


# ------------------------------------------------------------------ chunks

func _build_chunk(cx: int, cz: int, version: int, node: Node3D) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, "chunk", cx, cz, version])
	var meta: Dictionary = geo.build(cx, cz, node, r)
	var ox := cx * CS
	var oz := cz * CS
	var off := Vector3(floor(ox / W.P) * W.P, 0, floor(oz / W.P) * W.P)
	for i in W.HILLS.size():
		var xf: Transform3D = W.house_xf(i)
		xf.origin += off
		var c := xf * Vector3(0, 0, 5.5)
		if c.x < ox or c.x >= ox + CS or c.z < oz or c.z >= oz + CS:
			continue
		var h = Hs.new(self, node, xf, hash([level_seed, "house", i]))
		var info: Dictionary = h.build()
		var ex := make_exit("L009_3>EXT#1", "interact", xf * (info["exit_local"] as Vector3), Vector3(1.4, 2.0, 1.4), "Force the weak back door (the knob is frozen)", node)
		if ex:
			ex.fired.connect(_door_forced)
		var tl: Vector3 = xf * (info["toilet"] as Vector3)
		make_interactable(tl + Vector3(0, 0.6, 0), Vector3(0.9, 1.2, 0.9), "Sit on the commode and turn round", func(_p: Player) -> void:
			Overlay.subtitle("[through the casement: trees, colossal, so close they could fall on you. Not one leaf moves.]", 5.0), node)
		make_interactable(xf * Vector3(-2.0, 1.6, 10.9), Vector3(0.6, 0.6, 0.4), "Try the doorknob", func(_p: Player) -> void:
			Overlay.subtitle("[the knob is frozen solid. The wood around the lock is soft and rotten, though.]", 4.0), node)
		make_interactable(xf * Vector3(1.3, 1.6, 3.2), Vector3(1.6, 0.8, 1.2), "Look at the table", func(_p: Player) -> void:
			Overlay.subtitle("[pots, a pan, a cutting board: all soaked, as if carried in after a storm. Nothing has rotted further.]", 4.5), node)
		var drip := sound.emitter("drip", xf * Vector3(0.5, 3.0, 2.0), {"freq": 900.0 + i * 140.0}, -12.0, 16.0)
		if drip:
			drip.reparent(node)
		houses.append({"xf": xf, "exit": ex})
		meta["house"] = i
	if meta.get("road", false):
		var v := W.wrapf_p(oz + CS * 0.5)
		var wp := Vector3(off.x + W.road_u(v) - W.ROAD_HW - 1.2, 0, oz + CS * 0.5)
		wp.y = W.h_at(wp.x, wp.z) + 1.0
		make_interactable(wp, Vector3(1.6, 2.0, 2.0), "Touch the wall", func(_p: Player) -> void:
			Overlay.subtitle("[cold, wet brick and cobble, furred with moss. It crumbles at a touch; only the steel net holds it together.]", 4.5), node)
	if cx == int(floor(start.x / CS)) and cz == int(floor(start.z / CS)):
		add_note("soaked_sheet", "A SOAKED SHEET IN THE GRASS",
			"Nothing here grows or rots. The fog turns every hill into the same hill. The road is one road, bending when you cannot see it; its tar wears you down. When you hear the engine, get down in the wheat. It never comes. It never stops coming.",
			start + Vector3(1.4, 0.05, -0.6))
	return meta


# ------------------------------------------------------------- atmosphere

func _sky_image() -> void:
	# The "outside" as a faint, fuzzy upside-down landscape high in the clouds.
	sky_img = MeshInstance3D.new()
	sky_img.name = "FuzzyOutside"
	var q := PlaneMesh.new()
	q.size = Vector2(1400, 1400)
	q.flip_faces = true
	sky_img.mesh = q
	sky_img.material_override = MatLib.get_mat("l93_skyimg")
	sky_img.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sky_img.position = start + Vector3(0, 210, 0)
	add_child(sky_img)


func _sounds() -> void:
	sound.bed("wind", {"seconds": 9.0}, -31.0)
	sound.bed("room_tone", {"cutoff": 320.0, "rumble": 0.05, "seconds": 6.0}, -36.0)
	engine = sound.bed("transformer", {"base": 36.0}, -80.0)
	rumble = sound.bed("room_tone", {"cutoff": 90.0, "rumble": 0.9, "seconds": 5.0}, -80.0)


func _shots() -> void:
	var v := 120.0
	var ru := W.road_u(v)
	var hp := Vector3(ru + 1.2, W.road_h(v) + 1.62, v)
	add_shot("highway", hp, Vector3(W.road_u(v + 40.0) - 1.0, W.road_h(v + 40.0) + 1.0, v + 40.0), {"prepare": _prep.bind(hp)})
	var h0: Transform3D = W.house_xf(0)
	var hc: Vector3 = h0 * Vector3(2.5, 0, -12.5)
	hc.y = W.h_at(hc.x, hc.z) + 1.7
	add_shot("house", hc, h0 * Vector3(0, 2.4, 4.0), {"prepare": _prep.bind(start)})
	add_shot("bathroom", h0 * Vector3(3.0, 2.2, 6.4), h0 * Vector3(3.0, 1.5, 11.0), {"prepare": _prep.bind(h0.origin)})
	# a long wheat corridor near the start meadow
	for cz in range(16, 26):
		for cx in range(10, 22):
			if wheat_shot.is_empty() and W.is_wheat(cx, cz) and W.is_wheat(cx, cz + 1) and W.is_wheat(cx, cz + 2) and wm.linked(cx, cz, 2) and wm.linked(cx, cz + 1, 2):
				var a := Vector3((cx + 0.5) * W.CELL, 0, (cz + 0.5) * W.CELL)
				a.y = W.h_at(a.x, a.z) + 1.62
				var b := Vector3(a.x, 0, a.z + 16.0)
				b.y = W.h_at(b.x, b.z) + 1.2
				wheat_shot = {"a": a, "b": b}
	if not wheat_shot.is_empty():
		add_shot("wheat", wheat_shot["a"], wheat_shot["b"], {"prepare": _prep.bind(wheat_shot["a"])})
	add_shot("loft", h0 * Vector3(-1.5, 4.6, 1.4), h0 * Vector3(1.5, 0.9, 5.2), {"prepare": _prep.bind(h0.origin)})
	var fp := Vector3(W.FOREST_E + 2.0, 0, 160.0)
	fp.y = W.h_at(fp.x, fp.z) + 1.62
	add_shot("forest", fp, Vector3(fp.x - 30.0, fp.y + 2.0, fp.z + 6.0), {"prepare": _prep.bind(fp)})


func _prep(at: Vector3) -> void:
	world.build_around(at, 1)
	await get_tree().process_frame


# ----------------------------------------------------------------- runtime

func on_player_ready() -> void:
	world.target = player
	_period = _period_of(player.global_position)
	if qa_fixture:
		return
	match spawn_report.get("used_arrival", "start"):
		"from_L009_3":
			Overlay.subtitle("[the door gave way ... and you are standing in grassy fields again, leading nowhere]", 5.0)
		"from_L028":
			Overlay.subtitle("[the trees thin out. Fields, a road, houses on the hills, and fog over everything.]", 5.0)
		_:
			Overlay.subtitle("[a darkened corner of the wheat swallowed you. Behind you there is only more wheat.]", 5.0)


func _period_of(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / W.P), floori(p.z / W.P))


func _door_forced(_e: String) -> void:
	sound.play_at("knock", {"hits": 3}, player.global_position + Vector3(0, 1, 0), -6.0, "[you shoulder the rotten door; it splinters outward]")


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var p := player.global_position
	sky_img.position = Vector3(p.x, p.y + 210.0, p.z)
	# Möbius terrain: crossing a period boundary means the same fields again
	var per := _period_of(p)
	if per != _period:
		_period = per
		if not qa_fixture and not _said.has("loop"):
			_said["loop"] = true
			Overlay.subtitle("[that hill. That house. You have seen exactly this before.]", 4.5)
	# the tar wears you down
	on_tar = wm.on_road(p.x, p.z)
	if not qa_fixture:
		player.walk_speed = 2.3 if on_tar else float(rules["walk_speed"])
		player.sprint_speed = 3.4 if on_tar else float(rules["sprint_speed"])
		if on_tar and player.velocity.length() > 0.5:
			player.stamina = maxf(0.0, player.stamina - delta * 0.6)
			tar_t += delta
			if tar_t > 20.0 and not _said.has("tar"):
				_said["tar"] = true
				Overlay.subtitle("[your legs are heavy. The tar pulls at every step, as if it wants you to sit down.]", 4.5)
	hidden = player.crouching and _covered(p)
	_engine(delta)


## Cover: inside the wheat maze, in the forest band, or among bushes/fog off the road.
func _covered(p: Vector3) -> bool:
	var cx := floori(p.x / W.CELL)
	var cz := floori(p.z / W.CELL)
	if W.is_wheat(cx, cz) or W.forest_w(W.wrapf_p(p.x)) > 0.4:
		return true
	return absf(W.dwrap(W.wrapf_p(p.x), W.road_u(W.wrapf_p(p.z)))) > 30.0


## The engine: it swells, approaching but never closer, and dies away again.
func _engine(delta: float) -> void:
	eng_t -= delta * (1.6 if on_tar else 1.0)
	match eng_phase:
		0:
			eng_v = move_toward(eng_v, 0.0, delta * 0.08)
			if eng_t <= 0.0:
				eng_phase = 1
				eng_t = rng.randf_range(22.0, 34.0)
				if not qa_fixture:
					Overlay.subtitle("[an engine, somewhere out in the fog, coming closer]", 4.0)
		1:
			eng_v = minf(0.82, eng_v + delta / 30.0)
			if hidden:
				eng_t -= delta * 2.0
			if eng_t <= 0.0:
				eng_phase = 2
				eng_t = 12.0
				if not qa_fixture:
					Overlay.subtitle("[the engine is no closer. It fades, without ever having arrived.]" if not hidden else "[you stay down. The engine drones on, then thins away.]", 4.0)
		2:
			eng_v = maxf(0.0, eng_v - delta / 10.0)
			if eng_v <= 0.0:
				eng_phase = 0
				eng_t = rng.randf_range(35.0, 80.0)
	engine.volume_db = -80.0 if eng_v < 0.02 else lerpf(-42.0, -17.0, eng_v)
	engine.pitch_scale = 0.85 + eng_v * 0.25
	rumble.volume_db = -80.0 if eng_v < 0.02 else lerpf(-40.0, -19.0, eng_v)
	if not qa_fixture:
		Overlay.set_screen_effect("vignette", 0.15 + eng_v * 0.3)


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out := []
	out.append({"what": "a hilltop house with the weak back door is streamed near the start", "ok": not houses.is_empty() and exits.size() >= 1})
	var a := W.h_at(37.5, 91.0)
	var b := W.h_at(37.5 + W.P, 91.0 - W.P)
	out.append({"what": "terrain is periodic (forest leads back to the same fields)", "ok": absf(a - b) < 0.001, "detail": [a, b]})
	var mx := -INF
	var ph := eng_phase
	eng_phase = 1
	eng_t = 1000.0
	for i in 2400:
		_engine(0.05)
		mx = maxf(mx, engine.volume_db)
	out.append({"what": "the engine swells but never passes its far-off ceiling", "ok": mx <= -16.9 and mx > -30.0, "detail": mx})
	eng_phase = ph
	eng_v = 0.0
	var ru := W.road_u(50.0)
	out.append({"what": "the highway is detected as tar", "ok": wm.on_road(ru, 50.0) and not wm.on_road(ru + 20.0, 50.0)})
	var cells := 0
	for cz in 12:
		for cx in 12:
			if W.is_wheat(cx + 12, cz + 12):
				cells += 1
	out.append({"what": "the wheat labyrinth occupies the fields", "ok": cells > 20, "detail": cells})
	return out
