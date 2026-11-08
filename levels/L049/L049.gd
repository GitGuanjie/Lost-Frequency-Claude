extends LevelBase
## Level 49 — "The Unfilled River of Phlegethon" (Backrooms Wikidot rev 55,
## accessed 2026-11-04; cite: exotichive, CC BY-SA 3.0). Dossier:
## docs/canon/levels/L049.md. Content note (page): war violence.
##
## PLAN (v2.0 rebuild)
## SOURCE: an endless WWI-style battlefield of which only the abandoned trench
## system is accessible: complex but Euclidean, random twists and turns; walls
## of decaying planks, corroded iron sheets and worn sandbags, rusted barbed
## wire; widths from narrow paths to gun emplacements, artillery stations
## (mortars of non-human make) and damp bunkers, some collapsed; thick damp
## soil; eerie silence broken by distant gunfire; leaving the trench means a
## precise shot to the head; shells at random, rare bombers (L.E.A.D.S.);
## day and night twice as long, less gunfire at night; sudden thick fog; rare
## storms flooding to the waist, lightning (struck -> Level 3) and a flooded
## tunnel (-> Level 7); Almond Water, cans, medical kits, uniforms, empty
## rifles, notes; the M.E.G. "Gutter Bunkers", three connected bunkers whose
## specific rusted doors lead to Levels 14, 65 and 50; Entity 49/1, the
## Trenchcleaner (10 ft, eight-barrel chaingun, blue lights, head beam).
## ADAPTATION: a streamed grid of 32 m chunks, each a 16 x 16 grid of 2 m
## cells carved into zig-zag trenches between the crossing points of its open
## edges (row 0 is a continuous fire trench, every third column a
## communication trench); features per chunk (covered emplacement with a high
## fire-step, artillery pit, dugout bunker, collapsed dugout). Chunk (0,0) is
## the Gutter Bunkers (three dugouts joined by a tunnel, a drainage culvert).
## The parapet rule: eyes above ground level for 0.7 s = a sniper's shot (a
## crack past your ear first). Day/night cycle 80 min; fog, storm and flood,
## lightning and the flooded culvert are timed events; shells and a rare
## bomber pass. The Trenchcleaner is a scripted presence that stalks, sweeps
## and withdraws, firing only on a clear line of sight to a moving, upright or
## lit wanderer. No combat for the player. Killing a wanderer (-> Level 666)
## is not implementable: no other wanderers exist here.
## Verticality: trench floor, fire-steps, dugouts 2.8 m below the trenches.
## Helpers: L049_trench.gd (grammar), L049_under.gd (structures),
## L049_dress.gd (supplies, documents), L049_cleaner.gd (Entity 49/1).

const TR := preload("res://levels/L049/L049_trench.gd")
const UN := preload("res://levels/L049/L049_under.gd")
const DR := preload("res://levels/L049/L049_dress.gd")
const CL := preload("res://levels/L049/L049_cleaner.gd")
const DAY := 4800.0

var T
var dress
var world: ChunkWorld
var open_cells: Dictionary = {}       # world cell -> floor position
var chunk_cells: Dictionary = {}      # chunk key -> [world cells]
var gutter_nodes := {}
var tod := 0.12
var weather := "clear"
var weather_t := 600.0
var storm_t := 0.0
var flood: WaterVolume
var flood_y := TR.FLOOR - 0.3
var flood_exit: ExitTrigger
var grate: Array = []                 # [CollisionShape3D, MeshInstance3D]
var shell_t := 70.0
var gun_t := 8.0
var bomber_t := 900.0
var bomber := -1.0
var strike_t := -1.0
var strike_at := Vector3.ZERO
var flash_t := 9.0
var exposed := 0.0
var cracked := false
var cleaner: Node3D
var cleaner_t := 300.0
var beds := {}
var said := {}
var qa := false


func build() -> void:
	qa = SessionState.is_qa()
	T = TR.new(level_seed)
	dress = DR.new(self)
	rules["view_distance"] = 140.0
	rules["kill_y"] = -60.0
	rules["reverb_room"] = 0.2
	rules["reverb_wet"] = 0.08
	rules["flashlight"] = "allowed"
	outdoor_env(Color(0.42, 0.45, 0.47), Color(0.64, 0.63, 0.58), Color(0.2, 0.18, 0.15), Vector2(34.0, 140.0), Color(0.95, 0.9, 0.82), 0.7, Color(0.5, 0.5, 0.47), 0.014)
	environment.ambient_light_sky_contribution = 0.6
	environment.ambient_light_energy = 0.5
	environment.fog_sky_affect = 0.5
	environment.ssao_enabled = true
	sun.directional_shadow_max_distance = 60.0
	_materials()
	lights.setup(8, 0)
	_far_planes()
	world = ChunkWorld.new()
	world.name = "Trenches"
	world.chunk_size = TR.CHUNK
	world.radius = 1
	world.unload_radius = 2
	world.builder = _chunk
	world.chunk_unloaded.connect(_on_unload)
	add_child(world)
	var start := Vector3(11.0, TR.FLOOR + 0.08, 17.0)
	world.build_around(start, 1)
	add_arrival("start", start, -90.0)
	add_arrival("from_L011", start, -90.0)
	add_arrival("from_L048", Vector3(3.0, TR.FLOOR + 0.08, 17.0), -90.0)
	add_landmark("Gutter Bunkers (M.E.G.)", Vector3(15.0, TR.UFLOOR, 10.0))
	add_landmark("Fire trench", Vector3(16.0, TR.FLOOR, 17.0))
	_sounds()
	_shots()
	_apply_time(0.0)


# ---------------------------------------------------------------- materials

func _photo(name: String, asset: String, tint: Color, repeat_m: float, rough: float = -1.0) -> void:
	var base := "res://assets/external/%s/%s_%%s_1k.jpg" % [asset, asset]
	if not ResourceLoader.exists(base % "diff"):
		MatLib.define(name, {"albedo_a": tint * 0.4, "albedo_b": tint * 0.35}, "dirt")
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
	_photo("l49_mud_floor", "dirt_floor", Color(0.42, 0.34, 0.28), 2.2, 0.35)
	_photo("l49_mud_wall", "dirt_floor", Color(0.46, 0.39, 0.33), 2.6)
	_photo("l49_ground", "dirt_floor", Color(0.27, 0.24, 0.21), 3.2)
	var grime := {"grime_height": 0.7, "floor_y": TR.FLOOR, "grime_color": Color(0.035, 0.026, 0.018), "stain_amount": 0.55,
		"stain_color": Color(0.045, 0.035, 0.025), "stain_scale": 0.8}
	var plank := {"albedo_a": Color(0.085, 0.07, 0.056), "albedo_b": Color(0.058, 0.048, 0.04), "pattern": 2,
		"pattern_scale": Vector2(1.0, 0.035), "pattern_color": Color(0.045, 0.036, 0.03), "pattern_strength": 0.35,
		"noise_scale": 3.0, "roughness_a": 0.9, "roughness_b": 1.0, "bump_strength": 0.8}
	plank.merge(grime)
	MatLib.define("l49_plank", plank, "plaster")
	var wet := plank.duplicate()
	wet["albedo_a"] = Color(0.06, 0.05, 0.04)
	wet["albedo_b"] = Color(0.042, 0.036, 0.03)
	wet["grime_height"] = 0.0
	MatLib.define("l49_plank_wet", wet, "plaster")
	var iron := {"albedo_a": Color(0.1, 0.055, 0.032), "albedo_b": Color(0.065, 0.038, 0.024), "pattern": 2,
		"pattern_scale": Vector2(1.0, 0.075), "pattern_color": Color(0.035, 0.022, 0.014), "pattern_strength": 0.6,
		"metallic_value": 0.45, "roughness_a": 0.6, "roughness_b": 0.95, "noise_scale": 2.6, "bump_strength": 1.4}
	iron.merge(grime)
	MatLib.define("l49_iron", iron, "plaster")
	_photo("l49_board", "old_wood_floor", Color(0.56, 0.5, 0.42), 1.0)
	_photo("l49_board_dark", "old_wood_floor", Color(0.32, 0.28, 0.24), 1.2)
	_photo("l49_post", "old_wood_floor", Color(0.4, 0.34, 0.28), 0.9)
	_photo("l49_door_rust", "rusty_metal", Color(0.62, 0.5, 0.42), 1.2)
	_photo("l49_brick", "brick_4", Color(0.5, 0.42, 0.38), 1.6)
	var bag := {"albedo_a": Color(0.085, 0.072, 0.05), "albedo_b": Color(0.06, 0.052, 0.036), "noise_scale": 6.0,
		"bump_strength": 1.4, "roughness_a": 0.95, "roughness_b": 1.0}
	bag.merge(grime)
	MatLib.define("l49_bag", bag, "concrete")
	MatLib.register("l49_crater", MatLib.standard(Color(0.07, 0.058, 0.045), 0.95))
	MatLib.register("l49_puddle", MatLib.standard(Color(0.05, 0.045, 0.035), 0.08, 0.1))
	MatLib.register("l49_stain", MatLib.standard(Color(0.1, 0.05, 0.035), 0.9))
	MatLib.register("l49_rust", MatLib.standard(Color(0.32, 0.17, 0.09), 0.85, 0.4))
	MatLib.register("l49_steel", MatLib.standard(Color(0.16, 0.16, 0.17), 0.45, 0.8))
	MatLib.register("l49_uniform", MatLib.standard(Color(0.24, 0.24, 0.15), 0.95))
	MatLib.register("l49_rifle_wood", MatLib.standard(Color(0.3, 0.19, 0.11), 0.7))
	MatLib.register("l49_alien", MatLib.standard(Color(0.13, 0.15, 0.11), 0.3, 0.9))
	MatLib.register("l49_alien_dark", MatLib.standard(Color(0.06, 0.07, 0.06), 0.4, 0.8))
	MatLib.register("l49_alien_glass", MatLib.standard(Color(0.06, 0.12, 0.09), 0.1, 0.2, Color(0.2, 0.7, 0.45), 0.25))
	MatLib.register("l49_tc_armor", MatLib.standard(Color(0.15, 0.16, 0.17), 0.5, 0.75))
	MatLib.register("l49_tc_dark", MatLib.standard(Color(0.06, 0.06, 0.07), 0.6, 0.6))
	MatLib.register("l49_tc_blue", MatLib.standard(Color(0.1, 0.3, 0.9), 0.3, 0.0, Color(0.25, 0.55, 1.0), 4.0))
	MatLib.register("l49_flood", MatLib.water({"shallow_color": Color(0.24, 0.2, 0.14), "deep_color": Color(0.1, 0.08, 0.05),
		"absorption": 2.5, "clarity": 0.15, "wave_height": 0.02, "wave_scale": 2.0, "foam_amount": 0.1}))


## Mud planes beyond the streamed window (seen only down a long trench).
func _far_planes() -> void:
	for y in [TR.FLOOR - 0.06, -0.04]:
		var mi := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(1200.0, 1200.0)
		mi.mesh = pm
		mi.material_override = MatLib.get_mat("l49_mud_floor" if y < -1.0 else "l49_ground")
		mi.position = Vector3(0, y, 0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.name = "FarMud"
		add_child(mi)


# ---------------------------------------------------------------- streaming

func _chunk(cx: int, cz: int, _v: int, node: Node3D) -> Dictionary:
	node.position = Vector3(cx * TR.CHUNK, 0.0, cz * TR.CHUNK)
	var origin := node.position
	var key := Vector2i(cx, cz)
	var group := "c%d_%d" % [cx, cz]
	var lay: Dictionary = T.layout(cx, cz)
	var r := RandomNumberGenerator.new()
	r.seed = T.h([cx, cz, "geo"])
	var k := GeoKit.new(node, "Trench")
	var info: Dictionary = T.build(k, lay, r)
	var bunks: Array = UN.bunkers(k, lay, r)
	var feature: String = lay["feature"]
	var gutter := cx == 0 and cz == 0
	if feature == "emplacement":
		var em: Dictionary = UN.emplacement(k, lay, r)
		if not em.is_empty():
			dress.note(node, em["warn"] - (em["dv"] as Vector3) * 0.3 + Vector3(0, -0.9, 0), 4)
	elif feature == "artillery":
		UN.artillery(k, lay, r)
		Props.place(self, node, "ph/old_military_crate", TR.cpos(lay["node"], TR.FLOOR) + Vector3(-2.2, 0, 1.6), 90.0, 0.0, true)
	var docs := 0
	for b in bunks:
		if b.get("collapsed", false):
			make_interactable(b["entrance"] + Vector3(0, 1.0, 0), Vector3(1.6, 2.0, 1.2), "Look at the dugout entrance", func():
				Overlay.subtitle("[the dugout has caved in: timbers snapped, the stair full of wet earth. Whatever was down there stays there.]", 5.0), node)
			continue
		var lp: Vector3 = dress.bunker_room(k, node, b, r)
		lights.add_anchor(origin + lp, Color(1.0, 0.72, 0.4), 1.5, 5.0, 0.12, group)
		if not gutter and docs < 1:
			dress.note(node, (b["corner_b"] as Vector3) + Vector3(0.1, 0.79, 0.2), T.h([cx, cz, "doc"]) % 5)
			docs += 1
	if gutter:
		_gutter(k, node, bunks, lay)
	dress.supplies(k, node, info, r, 4 + r.randi() % 5)
	dress.no_mans_land(k, node, lay, r)
	k.commit()
	if gutter:
		_grate(node, lay)
	var mine: Array = []
	for c in info["floor_cells"]:
		var wc := Vector2i(cx * TR.NC, cz * TR.NC) + (c as Vector2i)
		open_cells[wc] = origin + TR.cpos(c, TR.FLOOR)
		mine.append(wc)
	chunk_cells[key] = mine
	return {"feature": feature, "cells": mine.size(), "bunkers": bunks.size()}


func _on_unload(k: Vector2i) -> void:
	lights.remove_group("c%d_%d" % [k.x, k.y])
	for wc in chunk_cells.get(k, []):
		open_cells.erase(wc)
	chunk_cells.erase(k)
	if k == Vector2i.ZERO:
		grate.clear()
		flood_exit = null


## The Gutter Bunkers: a rusted door at the back of each, only one of them
## "specific"; a second, jammed door in each side wall; the outpost's papers.
func _gutter(k: GeoKit, node: Node3D, bunks: Array, lay: Dictionary) -> void:
	var ids := ["L049>L014#1", "L049>L065#2", "L049>L050#3"]
	var labels := ["Level 14", "Level 65", "Level 50"]
	for i in mini(3, bunks.size()):
		var b: Dictionary = bunks[i]
		var d: Vector2i = b["d"]
		var n := Vector3(d.x, 0, d.y)
		var back: Vector3 = b["back"]
		DR.iron_door(k, back, n)
		var ex := make_exit(ids[i], "interact", back - n * 0.55 + Vector3(0, 1.1, 0), Vector3(1.6, 2.2, 1.1), "Force the rusted door open", node)
		if ex:
			ex.fired.connect(func(_id): Overlay.glitch(0.5))
		var lat: Vector2i = b["lat"]
		var lv := Vector3(lat.x, 0, lat.y)
		var side: Vector3 = b["side"]
		if i != 1:
			DR.iron_door(k, side, lv)
			make_interactable(side - lv * 0.5 + Vector3(0, 1.1, 0), Vector3(1.0, 2.0, 1.0), "Try the rusted door", func():
				Overlay.subtitle("[rusted solid. It doesn't move at all - not one of the right doors.]", 4.0), node)
		Props.place(self, node, "kenney/graveyard-kit/lantern-glass", back - n * 0.3 + Vector3(0.0, 2.05, 0.0) + lv * 0.75, 0.0, 0.3)
		gutter_nodes[labels[i]] = back
	dress.gutter_extras(k, node, bunks)
	var cu: Dictionary = UN.culvert(k, lay)
	if not cu.is_empty():
		gutter_nodes["culvert"] = cu["mouth"]
		gutter_nodes["culvert_inner"] = cu["inner"]
	# M.E.G. stencil board at the fire trench
	dress.note(node, TR.cpos(Vector2i(6, 8), TR.FLOOR + 0.08) + Vector3(0, 0, -0.6), 3)


func _grate(node: Node3D, _lay: Dictionary) -> void:
	if not gutter_nodes.has("culvert"):
		return
	var m: Vector3 = gutter_nodes["culvert"]
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(1.6, 1.25, 0.2)
	cs.shape = bs
	body.position = m + Vector3(0, 0.62, 0)
	body.add_child(cs)
	node.add_child(body)
	var gk := GeoKit.new(node, "Grate")
	for i in 7:
		gk.box(m + Vector3(-0.66 + i * 0.22, 0.62, 0), Vector3(0.04, 1.2, 0.04), "l49_rust", GeoKit.ALL, false)
	for y: float in [0.2, 1.0]:
		gk.box(m + Vector3(0, y, 0), Vector3(1.5, 0.05, 0.05), "l49_rust", GeoKit.ALL, false)
	gk.commit()
	grate = [cs, gk.root]
	make_interactable(m + Vector3(0, 0.7, -0.5), Vector3(1.6, 1.4, 0.8), "Look into the drain", func():
		if weather == "storm" and flood_y > TR.FLOOR + 0.8:
			Overlay.subtitle("[the flood has torn the grate away. The drain is a black, water-filled tunnel, pulling south.]", 5.0)
		else:
			Overlay.subtitle("[a brick drain under the parapet, grated shut, silted to the bars. Water must go somewhere when it rains.]", 5.0), node)


# ---------------------------------------------------------------- simple pickups

func _almond() -> void:
	Overlay.subtitle("[half a bottle of Almond Water, gritty with soil. You drink it anyway.]", 4.0)
	if player:
		player.heal(15.0)
		player.stamina = player.stamina_max


func _can() -> void:
	Overlay.subtitle("[a dented can of rations, still sealed. It tastes of tin and salt.]", 4.0)
	if player:
		player.stamina = player.stamina_max


func _medkit() -> void:
	Overlay.subtitle("[a used field kit - most of it gone, but there are still bandages.]", 4.0)
	if player:
		player.heal(35.0)


# ---------------------------------------------------------------- time and weather

func _apply_time(_delta: float) -> void:
	# 0.0-0.5 day, 0.5-1.0 night; the sun is low and the light grey all day
	var day := clampf(sin(tod * TAU) * 1.6 + 0.35, 0.0, 1.0)
	var storm := 1.0 if weather == "storm" else 0.0
	sun.light_energy = lerpf(0.06, 0.7, day) * (1.0 - storm * 0.6)
	sun.light_color = Color(0.95, 0.9, 0.82).lerp(Color(0.5, 0.6, 0.85), 1.0 - day)
	sun.rotation_degrees = Vector3(-lerpf(18.0, 40.0, day), 140.0 + tod * 120.0, 0.0)
	environment.ambient_light_energy = lerpf(0.1, 0.5, day) * (1.0 - storm * 0.4)
	var sky := environment.sky.sky_material as ProceduralSkyMaterial
	var top := Color(0.42, 0.45, 0.47).lerp(Color(0.03, 0.04, 0.07), 1.0 - day).lerp(Color(0.2, 0.21, 0.22), storm * day)
	var hor := Color(0.64, 0.63, 0.58).lerp(Color(0.06, 0.07, 0.09), 1.0 - day).lerp(Color(0.32, 0.32, 0.31), storm * day)
	sky.sky_top_color = top
	sky.sky_horizon_color = hor
	sky.ground_horizon_color = hor
	environment.fog_light_color = hor.lerp(Color(0.36, 0.35, 0.32), 0.5 * day)


func _weather(delta: float, p: Vector3) -> void:
	tod = fposmod(tod + delta / DAY, 1.0)
	_apply_time(delta)
	weather_t -= delta
	var target_fog := 0.014
	match weather:
		"clear":
			if weather_t <= 0.0:
				if randf() < 0.68:
					weather = "fog"
					weather_t = randf_range(240.0, 480.0)
					Overlay.subtitle("[a thick fog rolls in out of nowhere. Sound goes dull. It's hard to keep your thoughts together.]", 6.0)
				else:
					weather = "storm"
					storm_t = 0.0
					weather_t = 300.0
					Overlay.subtitle("[the sky goes black and the rain comes down all at once]", 5.0)
		"fog":
			target_fog = 0.1
			if weather_t <= 0.0:
				weather = "clear"
				weather_t = randf_range(480.0, 840.0)
		"storm":
			target_fog = 0.035
			storm_t += delta
			_storm(delta, p)
			if weather_t <= 0.0:
				weather = "clear"
				weather_t = randf_range(600.0, 900.0)
				Overlay.subtitle("[the rain stops. The water drains away and leaves the mud deeper than before.]", 5.0)
	environment.fog_density = lerpf(environment.fog_density, target_fog, minf(delta * 0.4, 1.0))
	Overlay.set_screen_effect("vignette", 0.25 + (0.2 if weather == "fog" else 0.0))
	var vol_k := minf(delta * 0.8, 1.0)
	_vol("rain", -16.0 if weather == "storm" else -80.0, vol_k)
	_vol("wind", -26.0 if weather == "storm" else (-40.0 if weather == "fog" else -32.0), vol_k)


## Waist-deep flood rising and falling over the storm; lightning; the drain.
func _storm(delta: float, p: Vector3) -> void:
	var lvl_t := TR.FLOOR - 0.3
	if storm_t < 90.0:
		lvl_t = lerpf(TR.FLOOR - 0.3, TR.FLOOR + 1.05, storm_t / 90.0)
	elif storm_t < 200.0:
		lvl_t = TR.FLOOR + 1.05
	else:
		lvl_t = lerpf(TR.FLOOR + 1.05, TR.FLOOR - 0.3, clampf((storm_t - 200.0) / 90.0, 0.0, 1.0))
	flood_y = lvl_t
	if flood == null:
		flood = WaterVolume.new()
		flood.name = "Flood"
		add_child(flood)
		flood.setup(Vector3(p.x - 300.0, TR.UFLOOR - 1.0, p.z - 300.0), Vector3(p.x + 300.0, flood_y, p.z + 300.0), "l49_flood", true)
		flood.fog_color = Color(0.12, 0.09, 0.05)
		flood.tint = Color(0.35, 0.28, 0.18)
	flood.aabb = AABB(Vector3(p.x - 300.0, TR.UFLOOR - 1.0, p.z - 300.0), Vector3(600.0, flood_y - TR.UFLOOR + 1.0, 600.0))
	flood.surface_y = flood_y
	if flood.surface_mesh:
		flood.surface_mesh.position = Vector3(p.x, flood_y, p.z)
	if storm_t > 70.0 and storm_t < 80.0:
		_say("flood", "[the water in the trench is up to your waist. Down in the dugouts it would be over your head.]", 5.0)
	# the drain opens into a water-filled tunnel at the height of the flood
	var open := flood_y > TR.FLOOR + 0.8
	if grate.size() == 2 and is_instance_valid(grate[0]):
		(grate[0] as CollisionShape3D).disabled = open
		(grate[1] as Node3D).visible = not open
		if open and flood_exit == null and gutter_nodes.has("culvert_inner"):
			var chunk0: Node = world.chunks.get(Vector2i.ZERO, {}).get("node")
			if chunk0:
				flood_exit = make_exit("L049>L007#5", "walk_in", (gutter_nodes["culvert_inner"] as Vector3) + Vector3(0, 0.6, 0), Vector3(1.6, 1.2, 1.6), "", chunk0)
		elif not open and flood_exit != null:
			if is_instance_valid(flood_exit):
				flood_exit.queue_free()
			flood_exit = null
	if storm_t > 290.0 and flood:
		flood.queue_free()
		flood = null
	# lightning
	flash_t -= delta
	if flash_t <= 0.0:
		flash_t = randf_range(5.0, 14.0)
		Overlay.glitch(0.05)
		var tw := create_tween()
		tw.tween_property(environment, "ambient_light_energy", 3.0, 0.05)
		tw.tween_property(environment, "ambient_light_energy", 0.3, 0.3)
		var dist := randf_range(200.0, 900.0)
		get_tree().create_timer(dist / 343.0).timeout.connect(func(): sound.play_at("thunder", {"seconds": 4.0}, p + Vector3(randf_range(-40, 40), 30, randf_range(-40, 40)), -6.0))
		if strike_t < 0.0 and p.y > TR.UCEIL and randf() < 0.12:
			strike_t = 2.2
			strike_at = p
			Overlay.subtitle("[the hair on your arms stands up. The air smells of metal.]", 2.5)
			sound.play_at("crackle", {"seconds": 2.0}, p + Vector3(0, 2, 0), -4.0)
	if strike_t >= 0.0:
		strike_t -= delta
		if strike_t < 0.0:
			if p.y > TR.UCEIL and p.distance_to(strike_at) < 3.0:
				Overlay.glitch(1.0)
				sound.play_at("thunder", {"seconds": 4.0}, p, 6.0)
				TransitionService.request_exit("L049>L003#4")
			else:
				sound.play_at("thunder", {"seconds": 4.0}, strike_at, 4.0, "[lightning strikes the trench just where you were standing]")


## Shells at random, gunfire by day, now and then a bomber (L.E.A.D.S.).
func _war(delta: float, p: Vector3) -> void:
	var night := tod > 0.5
	gun_t -= delta
	if gun_t <= 0.0:
		gun_t = randf_range(4.0, 12.0) * (3.0 if night else 1.0)
		var far := p + Vector3(randf_range(-1, 1), 0.3, randf_range(-1, 1)).normalized() * 25.0 + Vector3(0, 8, 0)
		sound.play_at("knock", {"hits": randi_range(2, 7)}, far, -20.0, "" if said.has("gunfire") else "[distant gunfire, somewhere beyond no man's land]")
		said["gunfire"] = true
	shell_t -= delta
	if shell_t <= 0.0:
		shell_t = randf_range(45.0, 130.0) * (1.6 if night else 1.0)
		var close := randf() < 0.1
		var d := randf_range(9.0, 16.0) if close else randf_range(25.0, 70.0)
		var a := randf() * TAU
		var at := p + Vector3(cos(a) * d, 2.4, sin(a) * d)
		sound.play_at("distant_boom", {}, at, 4.0 if close else -6.0, "[a shell lands close - earth rains down into the trench]" if close else "[a shell lands somewhere in the trenches]")
		if close:
			Overlay.glitch(0.4)
			if p.y > TR.UCEIL and not player.crouching:
				player.hurt(12.0, "shellfire")
	bomber_t -= delta
	if bomber_t <= 0.0 and bomber < 0.0:
		bomber = 0.0
		bomber_t = randf_range(1100.0, 1700.0)
		_transient("transformer", {"base": 38.0}, p + Vector3(20, 40, 0), -6.0, 20.0)
		Overlay.subtitle("[engines overhead - a bomber. L.E.A.D.S.: Locate shelter, Enter it, Avoid the open, Duck, Shield your head.]", 7.0)
	if bomber >= 0.0:
		bomber += delta
		if int(bomber) in [12, 14, 15, 17] and int(bomber - delta) != int(bomber):
			var at2 := p + Vector3(randf_range(-30, 30), 2.0, randf_range(-30, 30))
			sound.play_at("distant_boom", {}, at2, 6.0)
			Overlay.glitch(0.3)
		if bomber > 18.0:
			bomber = -1.0
			if p.y > TR.UCEIL and not player.crouching:
				player.hurt(30.0, "bombing")
				Overlay.subtitle("[the blast throws you against the revetment. You should have been down, in cover.]", 5.0)
			else:
				Overlay.subtitle("[the bombs walk past. Dirt sifts down from the timbers.]", 4.0)


## The parapet rule: eyes above ground level for long are shot.
func _parapet(delta: float, p: Vector3) -> void:
	var eye := p.y + (1.0 if player.crouching else 1.62)
	if eye > 0.12:
		exposed += delta
		if exposed > 0.25 and not cracked:
			cracked = true
			sound.play_at("knock", {"hits": 1}, p + Vector3(0.6, 1.6, 0), 4.0, "[a round cracks past your ear. Get down!]")
		if exposed > 0.7 and not player.dead:
			player.hurt(500.0, "shot from beyond no man's land")
	else:
		exposed = 0.0
		cracked = false


func _cleaner(delta: float, p: Vector3) -> void:
	if cleaner != null and is_instance_valid(cleaner):
		return
	cleaner_t -= delta
	if cleaner_t > 0.0:
		return
	cleaner_t = randf_range(360.0, 720.0)
	if p.y < TR.UCEIL:
		return
	# breadth-first over the loaded trench cells from the player
	var start := Vector2i(floori(p.x / TR.CELL), floori(p.z / TR.CELL))
	if not open_cells.has(start):
		return
	var parent := {start: start}
	var dist := {start: 0}
	var q: Array = [start]
	var cand: Array = []
	while not q.is_empty():
		var c: Vector2i = q.pop_front()
		if dist[c] >= 14 and dist[c] <= 24:
			cand.append(c)
		if dist[c] > 24:
			continue
		for dv: Vector2i in TR.DIRS:
			var n: Vector2i = c + dv
			if open_cells.has(n) and not dist.has(n):
				dist[n] = dist[c] + 1
				parent[n] = c
				q.append(n)
	if cand.is_empty():
		return
	var c0: Vector2i = cand[randi() % cand.size()]
	var route: Array = []
	var c1 := c0
	while c1 != start and route.size() < 40:
		route.append(open_cells[c1])
		c1 = parent[c1]
	cleaner = CL.new()
	cleaner.name = "Trenchcleaner"
	add_child(cleaner)
	cleaner.setup(self, route)
	Overlay.subtitle("[somewhere along the trench, a low mechanical whine, and heavy steps that don't sound like boots]", 5.0)


# ---------------------------------------------------------------- sound

func _sounds() -> void:
	beds["wind"] = sound.bed("wind", {"seconds": 9.0}, -32.0)
	beds["rain"] = sound.bed("rain", {"seconds": 6.0}, -80.0)
	beds["room"] = sound.bed("room_tone", {"seconds": 6.0, "cutoff": 180.0, "rumble": 0.3}, -48.0)
	sound.oneshot("drip", {"freq": 900.0}, 6.0, 16.0, 5.0, "", -30.0)
	sound.oneshot("creak", {"freq": 70.0}, 25.0, 60.0, 10.0, "[timber shoring groans under the weight of earth]", -28.0)


func _transient(recipe: String, params: Dictionary, pos: Vector3, db: float, secs: float) -> void:
	var pl := AudioStreamPlayer3D.new()
	pl.stream = AudioSynth.get_stream(recipe, params)
	pl.volume_db = db
	pl.max_distance = 200.0
	pl.bus = "SFX"
	add_child(pl)
	pl.global_position = pos
	pl.play()
	var tw := create_tween()
	tw.tween_interval(secs * 0.6)
	tw.tween_property(pl, "volume_db", -60.0, secs * 0.4)
	tw.tween_callback(pl.queue_free)


func _vol(key: String, db: float, k: float) -> void:
	var pl: AudioStreamPlayer = beds.get(key)
	if pl:
		pl.volume_db = lerpf(pl.volume_db, db, k)


func _say(key: String, text: String, secs: float = 4.5) -> void:
	if said.has(key) or qa:
		return
	said[key] = true
	Overlay.subtitle(text, secs)


# ---------------------------------------------------------------- process

func on_player_ready() -> void:
	world.target = player
	_say("arrive", "[mud to the ankles, the smell of wet earth and something rotten under it. Silence - then, far off, gunfire. Keep your head below the sandbags.]", 7.0)


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var p := player.global_position
	if qa:
		return
	_parapet(delta, p)
	_weather(delta, p)
	_war(delta, p)
	_cleaner(delta, p)
	_vol("room", -34.0 if p.y < TR.UCEIL else -48.0, minf(delta, 1.0))


# ---------------------------------------------------------------- QA

func _shots() -> void:
	var F := TR.FLOOR
	add_shot("fire_trench", Vector3(14.2, F + 1.6, 17.0), Vector3(24.0, F + 1.0, 15.0), {"flashlight": false})
	add_shot("gutter_bunker", Vector3(15.0, TR.UFLOOR + 1.55, 11.6), Vector3(15.0, TR.UFLOOR + 1.0, 8.0), {"flashlight": false})
	add_shot("trench_network", Vector3(18.0, 5.5, 30.0), Vector3(34.0, -2.0, 50.0), {"flashlight": false, "prepare": _prep_far})
	# find an artillery pit or emplacement near the outpost for the fourth still
	for ring in [[1, 0], [-1, 0], [0, 1], [0, -1], [1, 1], [-1, 1], [1, -1], [-1, -1], [2, 0], [-2, 0], [0, 2], [2, 1], [-2, 1], [1, 2]]:
		var lay: Dictionary = T.layout(ring[0], ring[1])
		if lay["feature"] in ["artillery", "emplacement"]:
			var c := Vector3(ring[0] * TR.CHUNK, 0, ring[1] * TR.CHUNK) + TR.cpos(lay["node"], F)
			add_shot(lay["feature"], c + Vector3(-3.4, 1.6, -3.0), c + Vector3(1.0, 0.6, 1.0), {"flashlight": false, "prepare": func():
				world.build_around(c, 1)
				await get_tree().process_frame})
			break


func _prep_far() -> void:
	world.build_around(Vector3(34.0, 0, 50.0), 1)
	await get_tree().process_frame


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	var ids := {}
	for e in exits:
		if is_instance_valid(e):
			ids[(e as ExitTrigger).edge_id] = true
	out.append({"what": "three Gutter Bunker doors (Levels 14, 65, 50)", "ok": ids.has("L049>L014#1") and ids.has("L049>L065#2") and ids.has("L049>L050#3"), "detail": ids.keys()})
	var space := get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(11.0, -1.0, 17.0), Vector3(11.0, -4.0, 17.0), 1))
	out.append({"what": "trench floor (duckboards) under the start", "ok": not hit.is_empty() and absf(float(hit["position"].y) - TR.FLOOR) < 0.15, "detail": hit.get("position", null)})
	var hit2 := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(15.0, -3.0, 9.0), Vector3(15.0, -7.0, 9.0), 1))
	out.append({"what": "bunker room floor 2.8 m below the trench", "ok": not hit2.is_empty() and absf(float(hit2["position"].y) - TR.UFLOOR) < 0.1, "detail": hit2.get("position", null)})
	var hit3 := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(15.0, -1.0, 14.0), Vector3(15.0, -6.0, 14.0), 1))
	out.append({"what": "dugout stair ramp halfway down", "ok": not hit3.is_empty() and absf(float(hit3["position"].y) - (TR.FLOOR + TR.UFLOOR) * 0.5) < 0.4, "detail": hit3.get("position", null)})
	var hit4 := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(11.0, 3.0, 20.6), Vector3(11.0, -1.0, 20.6), 1))
	out.append({"what": "earth at ground level beside the trench (parapet)", "ok": not hit4.is_empty() and absf(float(hit4["position"].y)) < 0.1, "detail": hit4.get("position", null)})
	out.append({"what": "streamed trench window loaded", "ok": world.chunks.size() >= 9 and open_cells.size() > 60, "detail": open_cells.size()})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
