extends LevelBase
## Level 10 — "Bumper Crop" (Backrooms Wikidot rev 45, accessed 2026-11-04; cite:
## scutoid studios & egglord, CC BY-SA 3.0). Dossier: docs/canon/levels/L010.md.
## SOURCE: endless wheat and barley plots divided by tree and shrub lines that
## never outgrow one another; a leaden overcast sky with brief light rain and
## fog and gusts of wind in the crops as the only change; water in every hollow
## below one elevation (clear, drinkable, earthy); less cultivated lake edges;
## empty sheds, outbuildings, barns and stables holding wood and nails; dirt
## tracks (two ruts, grass strip) that no vehicle ever uses and that lead to
## Level 11; canola among the wheat (Level 184); lakes to aquatic levels; a 1 m
## soil crust over a worm mass that surges if dug deeper. ADAPTATION notes are
## in level.json. Helpers: L010_world.gd (model), L010_geo.gd (meshing),
## L010_barn.gd (structures), L010_mats.gd (shaders).

const WM := preload("res://levels/L010/L010_world.gd")
const GEO := preload("res://levels/L010/L010_geo.gd")
const M := preload("res://levels/L010/L010_mats.gd")
const CS := 64.0
const NEED_M := 1100.0
const SKY_TOP := Color(0.25, 0.27, 0.3)
const SKY_HOR := Color(0.42, 0.44, 0.46)
const FOG := 0.0062

var wm
var geo
var world: ChunkWorld
var farw: ChunkWorld
var qa_fixture := false
var start := Vector3.ZERO
var water: WaterVolume
var tiles := {}
var tick := 0.0
var cp_cool := 0.0
var said := {}
# weather: gusts, rare fog / light-rain spells
var gust := 0.25
var gust_phase := 0
var gust_t := 9.0
var wdir := Vector2(0.8, 0.6)
var wet := 0.0
var spell := ""
var spell_amt := 0.0
var spell_t := 0.0
var next_spell := 260.0
var rain: GPUParticles3D
var wind_bed: AudioStreamPlayer
var rain_bed: AudioStreamPlayer
# the road to Level 11
var road_m := 0.0
var off_m := 0.0
var last_p := Vector3.ZERO
var road_dir := Vector3(0, 0, -1)
var road_done := false
var skyline: Node3D
# the survey pit and the worms
var pit_c := Vector3.ZERO
var pit_depth := 0.6
var pit_floor: MeshInstance3D
var worms: MultiMeshInstance3D
var worm_src: Array = []
var surge_t := 0.0
var slip_t := 0.0
# lakes
var dive_t := 0.0
var swim_exit: ExitTrigger


func build() -> void:
	qa_fixture = SessionState.is_qa()
	rules["view_distance"] = 900.0
	rules["reverb_room"] = 0.05
	rules["reverb_wet"] = 0.02
	wm = WM.new(level_seed, qa_fixture)
	M.define_all(WM.WATER_Y)
	MatLib.register("l10_lake", MatLib.water({"shallow_color": Color(0.42, 0.5, 0.45), "deep_color": Color(0.1, 0.16, 0.15), "absorption": 0.32,
		"clarity": 0.92, "wave_height": 0.02, "wave_scale": 0.5, "foam_amount": 0.05, "roughness_value": 0.06}))
	geo = GEO.new(wm)
	outdoor_env(SKY_TOP, SKY_HOR, SKY_HOR, Vector2(54.0, 35.0), Color(0.9, 0.91, 0.92), 1.45, SKY_HOR, FOG)
	var sm: ShaderMaterial = M.sky_material()
	sm.set_shader_parameter("top", Vector3(SKY_TOP.r, SKY_TOP.g, SKY_TOP.b))
	sm.set_shader_parameter("hor", Vector3(SKY_HOR.r, SKY_HOR.g, SKY_HOR.b))
	environment.sky.sky_material = sm
	environment.ambient_light_sky_contribution = 0.5
	environment.ambient_light_color = Color(0.42, 0.44, 0.46)
	environment.ambient_light_energy = 0.55
	environment.fog_sky_affect = 0.3
	environment.fog_aerial_perspective = 0.2
	environment.fog_height = WM.WATER_Y + 1.6
	environment.fog_height_density = 0.05
	environment.tonemap_exposure = 0.98
	environment.glow_intensity = 0.15
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.92
	environment.adjustment_contrast = 1.12
	sun.shadow_blur = 3.0
	sun.directional_shadow_max_distance = 90.0
	start = Vector3(WM.TOFF, wm.h_at(WM.TOFF, 34.0) + 0.05, 34.0)
	if qa_fixture:
		_qa_fixture()
	world = ChunkWorld.new()
	world.name = "Chunks"
	world.chunk_size = CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _near_chunk
	add_child(world)
	farw = ChunkWorld.new()
	farw.name = "FarRing"
	farw.chunk_size = CS
	farw.radius = 5
	farw.unload_radius = 6
	farw.builds_per_frame = 2
	farw.builder = func(cx, cz, _v, node): return geo.far(cx, cz, node)
	add_child(farw)
	world.chunk_built.connect(func(k, _m): _farvis(k))
	world.chunk_unloaded.connect(func(k): _farvis(k))
	farw.chunk_built.connect(func(k, _m): _farvis(k))
	world.build_around(start, 2)
	farw.build_around(start, 5)
	water = WaterVolume.new()
	water.name = "Lakes"
	add_child(water)
	water.setup(Vector3(-400, WM.WATER_Y - 30.0, -400), Vector3(400, WM.WATER_Y, 400), "l10_lake")
	water.fog_color = Color(0.32, 0.4, 0.37)
	water.fog_density = 0.045
	water.tint = Color(0.55, 0.66, 0.6)
	_water_follow(start)
	_home()
	_rain_fx()
	_sounds()
	_arrivals()
	last_p = start
	add_shot("fields", start + Vector3(0.6, 1.62, 2.0), start + Vector3(-14.0, -1.0, -80.0), {"flashlight": false})
	add_landmark("Spawn on the dirt track (home barn ahead, right)", start)


# --------------------------------------------------------------- chunks

func _near_chunk(cx: int, cz: int, _v: int, node: Node3D) -> Dictionary:
	var meta: Dictionary = geo.near(cx, cz, node)
	for rc: Rect2 in meta["canola"]:
		var c := rc.get_center()
		if c.distance_to(Vector2(start.x, start.z)) > 120.0:
			make_exit("L010>L184#2", "walk_in", Vector3(c.x, wm.h_at(c.x, c.y) + 1.2, c.y), Vector3(maxf(2.0, rc.size.x - 5.0), 3.0, maxf(2.0, rc.size.y - 5.0)), "", node)
	return meta


func _farvis(k: Vector2i) -> void:
	if farw and farw.chunks.has(k):
		var n: Node3D = farw.chunks[k]["node"]
		if is_instance_valid(n):
			n.visible = not world.chunks.has(k)


## Stream stalk tiles within ~46 m of the camera (budget = builds this call).
func _tiles_tick(budget: int) -> void:
	var cam := get_viewport().get_camera_3d()
	var p: Vector3 = cam.global_position if cam else (player.global_position if player else start)
	for key: Vector2i in world.chunks.keys():
		var meta: Dictionary = world.meta_of(key)
		var node: Node3D = world.chunks[key]["node"]
		for t in 16:
			var cx: float = float(meta["ox"]) + (t % 4) * 16.0 + 8.0
			var cz: float = float(meta["oz"]) + (t / 4) * 16.0 + 8.0
			var d := Vector2(cx - p.x, cz - p.z).length()
			var tk := Vector3i(key.x, key.y, t)
			var have: bool = tiles.has(tk) and is_instance_valid(tiles[tk])
			if d < 46.0 and not have and budget > 0:
				tiles[tk] = geo.tile(meta, t % 4, t / 4, node)
				budget -= 1
			elif d > 62.0 and have:
				(tiles[tk] as Node3D).queue_free()
				tiles.erase(tk)
	for tk in tiles.keys():
		if not is_instance_valid(tiles[tk]):
			tiles.erase(tk)


func _tiles_now() -> void:
	_tiles_tick(400)


func _water_follow(p: Vector3) -> void:
	var s := p.snapped(Vector3(32, 32, 32))
	water.aabb.position = Vector3(s.x - 400.0, WM.WATER_Y - 30.0, s.z - 400.0)
	water.surface_mesh.position = Vector3(s.x, WM.WATER_Y, s.z)


# ----------------------------------------------------------- anchors

## The barn beside the spawn track: a survey pit, the transit card, and the
## traces the page's narrator describes (testimony; nothing is mandatory).
func _home() -> void:
	var hp: Dictionary = wm.plot(WM.HOME.x, WM.HOME.y)
	var fr: Transform3D = hp["frame"]
	var pad: float = hp["pad"]
	var k := kit("Home")
	var P := func(x: float, y: float, z: float) -> Vector3: return fr * Vector3(x, y, z)
	var bx := func(a: Vector3, b: Vector3, mat: String, col: bool) -> void:
		k.box_xf(Transform3D(fr.basis, fr * ((a + b) * 0.5)), (b - a).abs(), mat, GeoKit.ALL, col)
	# new wooden doorstep at the main door, and a wheat stalk left on it
	bx.call(Vector3(-1.0, -0.2, 11.0), Vector3(-0.02, -0.02, 15.0), "l10_step_wood", true)
	bx.call(Vector3(-0.7, -0.02, 12.4), Vector3(-0.68, -0.008, 12.95), "l10_plank_wood", false)
	bx.call(Vector3(-0.71, -0.02, 12.95), Vector3(-0.67, 0.0, 13.06), "l10_step_wood", false)
	# a cold camp stove, a scorched pot and the floor burnt black around it; bedrolls
	bx.call(Vector3(8.6, 0.0, 19.0), Vector3(9.0, 0.25, 19.35), "l10_nails_metal", true)
	k.cylinder(P.call(8.8, 0.36, 19.17), 0.13, 0.22, "l10_pot", 10, false)
	bx.call(Vector3(7.9, 0.002, 18.4), Vector3(9.7, 0.008, 20.1), "l10_pot", false)
	for z in [21.0, 23.0]:
		bx.call(Vector3(6.4, 0.0, z), Vector3(8.3, 0.12, z + 0.75), "l10_cloth", false)
	bx.call(Vector3(9.4, 0.0, 22.4), Vector3(10.2, 0.08, 23.2), "l10_cloth", false)
	add_note("l10_meg", "M.E.G. transit card", "LEVEL 10. Transit only; no outpost here. Rest a short while in a barn, then move on. Dirt tracks run on toward Level 11 if you keep to them long enough. Lake water tested drinkable: clear, earthy. Do NOT dig past one metre. Grain harvest suspended pending a nutrition review. Canola among the wheat has been reported as a crossing.", P.call(2.5, 0.96, 21.4), Vector3(0.4, 0.06, 0.4))
	add_note("l10_scrap", "Notebook scrap", "Mum put in a new doorstep. I left a bit of wheat on it so I could watch it go off, like I used to at home with apple cores. It hasn't. A worm came up and tried it and went straight back down.", P.call(-0.5, 0.01, 13.6), Vector3(0.4, 0.06, 0.4))
	# M.E.G. survey pit (2 x 2 m, taped off) with the spade in the spoil heap
	pit_c = Vector3(wm.pit.x, pad, wm.pit.y)
	var hw := WM.CELL * 0.5
	for s in [[Vector3(-hw, 0, 0), Vector3(0.1, 1.7, 2.0 * hw)], [Vector3(hw, 0, 0), Vector3(0.1, 1.7, 2.0 * hw)], [Vector3(0, 0, -hw), Vector3(2.0 * hw, 1.7, 0.1)], [Vector3(0, 0, hw), Vector3(2.0 * hw, 1.7, 0.1)]]:
		k.box(pit_c + (s[0] as Vector3) * 1.05 + Vector3(0, -0.85, 0), s[1], "l10_soil_dirt", GeoKit.ALL, false)
	pit_floor = MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.0, 0.1, 2.0)
	pit_floor.mesh = bm
	pit_floor.material_override = MatLib.get_mat("l10_soil_dirt")
	add_child(pit_floor)
	for m in [[Vector3(0.0, 0.0, 2.3), Vector3(2.6, 0.55, 1.1), 0.1], [Vector3(-0.6, 0.0, 2.9), Vector3(1.6, 0.35, 1.2), -0.3], [Vector3(2.3, 0.0, 0.4), Vector3(1.0, 0.4, 1.8), 0.2]]:
		k.box_xf(Transform3D(Basis(Vector3.UP, m[2]), pit_c + (m[0] as Vector3) + Vector3(0, (m[1] as Vector3).y * 0.5 - 0.05, 0)), m[1], "l10_soil_dirt")
	k.box_xf(Transform3D(Basis(Vector3(1, 0, 0), 0.35), pit_c + Vector3(0.4, 0.95, 2.35)), Vector3(0.04, 1.1, 0.04), "l10_beam_wood", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3(1, 0, 0), 0.35), pit_c + Vector3(0.4, 0.33, 2.15)), Vector3(0.2, 0.28, 0.02), "l10_nails_metal", GeoKit.ALL, false)
	var cor := [Vector3(-1.4, 0, -1.4), Vector3(1.4, 0, -1.4), Vector3(1.4, 0, 1.4), Vector3(-1.4, 0, 1.4)]
	for i in 4:
		var a: Vector3 = pit_c + cor[i]
		var b: Vector3 = pit_c + cor[(i + 1) % 4]
		k.box(a + Vector3(0, 0.47, 0), Vector3(0.05, 0.95, 0.05), "l10_stake_wood", GeoKit.ALL, false)
		k.box((a + b) * 0.5 + Vector3(0, 0.86, 0), Vector3(absf(b.x - a.x) + 0.03, 0.04, absf(b.z - a.z) + 0.03), "l10_tape", GeoKit.ALL, false)
		k.add_box_shape(Transform3D(Basis(), (a + b) * 0.5 + Vector3(0, 0.5, 0)), Vector3(absf(b.x - a.x) + 0.1, 1.0, absf(b.z - a.z) + 0.1), "dirt")
	k.commit()
	add_interactable(pit_c + Vector3(0, 0.25, 0), Vector3(2.0, 0.5, 2.0), "Dig deeper with the survey spade", _dig)
	_pit_visual()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = geo.worm
	mm.instance_count = 380
	worms = MultiMeshInstance3D.new()
	worms.multimesh = mm
	worms.material_override = MatLib.get_mat("l10_worm")
	worms.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	worms.visible = false
	add_child(worms)
	var r := RandomNumberGenerator.new()
	r.seed = level_seed + 10
	for i in 380:
		var a := r.randf() * TAU
		var rad := r.randf_range(0.6, 4.4) if i >= 120 else 0.0
		worm_src.append([Vector3(r.randf_range(-0.9, 0.9), 0, r.randf_range(-0.9, 0.9)), Vector3(cos(a) * rad, 0, sin(a) * rad), r.randf() * TAU, r.randf_range(0.7, 1.6)])
	# a shore where the lake can be drunk from (march from the spawn toward the lake)
	var to := Vector3(WM.LAKE.x, 0, WM.LAKE.y) - start
	to.y = 0.0
	for i in 200:
		var q := start + to.normalized() * float(i)
		if wm.h_at(q.x, q.z) < WM.WATER_Y + 0.15:
			add_interactable(Vector3(q.x, WM.WATER_Y + 0.25, q.z), Vector3(2.0, 0.6, 2.0), "Cup your hands and drink", _drink)
			add_landmark("Lake shore (drinkable water)", q)
			break


func _pit_visual() -> void:
	pit_floor.position = pit_c + Vector3(0, -pit_depth - 0.05, 0)
	var r := RandomNumberGenerator.new()
	r.seed = level_seed + 11
	if worms == null:
		return
	worms.visible = pit_depth >= 1.0 or surge_t > 0.0
	for i in 380:
		var s: Array = worm_src[i]
		var o: Vector3 = s[0]
		var y := -pit_depth + 0.02
		if i >= 120 and surge_t <= 0.0:
			o = Vector3(0, -3.0, 0)
		worms.multimesh.set_instance_transform(i, Transform3D(Basis(Vector3.UP, s[2]).scaled(Vector3.ONE * float(s[3])), pit_c + o + Vector3(0, y, 0)))


func _dig(_p: Player) -> void:
	if surge_t > 0.0:
		Overlay.toast("The pit is boiling with worms.", 2.5)
		return
	pit_depth += 0.2
	sound.play_at("footstep", {"surface": "dirt", "variant": int(pit_depth * 10.0) % 3}, pit_c, -6.0, "[a spade bites into damp soil]")
	if pit_depth < 0.95:
		Overlay.toast("Cool, damp soil. The pit is about %.1f m deep." % pit_depth, 2.5)
	elif pit_depth < 1.15:
		Overlay.subtitle("[the spade breaks through into something soft that moves]", 3.5)
		Overlay.toast("One metre down the soil simply stops. Below: a dark, writhing mass of worms.", 4.0)
	else:
		_surge()
	_pit_visual()


func _surge() -> void:
	surge_t = 24.0
	slip_t = 0.0
	Overlay.subtitle("[the soil heaves: worms boil up out of the pit]", 4.0)
	sound.play_at("scratch", {"seconds": 3.0}, pit_c, 0.0, "[a wet, writhing rush]")


func _surge_tick(delta: float) -> void:
	if surge_t <= 0.0:
		return
	surge_t -= delta
	var age := 24.0 - surge_t
	var out := clampf(age / 3.0, 0.0, 1.0) * clampf(surge_t / 6.0, 0.0, 1.0)
	out = 1.0 - pow(1.0 - out, 2.0)
	for i in range(120, 380):
		var s: Array = worm_src[i]
		var tgt: Vector3 = s[1]
		var o: Vector3 = (s[0] as Vector3).lerp(tgt, out)
		var gy: float = wm.h_at(pit_c.x + o.x, pit_c.z + o.z) - pit_c.y if out > 0.05 else -pit_depth
		var wig := sin(age * 3.0 + i) * 0.05
		worms.multimesh.set_instance_transform(i, Transform3D(Basis(Vector3.UP, float(s[2]) + age * 0.6 + wig).scaled(Vector3.ONE * float(s[3])), pit_c + o + Vector3(0, gy + 0.01, 0)))
	var d := Vector2(player.global_position.x - pit_c.x, player.global_position.z - pit_c.z).length()
	if d < 4.6 * out + 0.8 and out > 0.2:
		slip_t -= delta
		if not qa_fixture:
			player.hurt(2.2 * delta, "Worms burrowed into the skin")
		if slip_t <= 0.0:
			slip_t = rng.randf_range(0.5, 1.1)
			player.velocity += Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized() * 2.8
			if not said.has("slip"):
				said["slip"] = true
				Overlay.toast("You slip in the writhing mass. Worms work at your sleeves and boots.", 4.0)
	if surge_t <= 0.0:
		surge_t = 0.0
		pit_depth = 0.85
		said.erase("slip")
		Overlay.subtitle("[the worms sink back; loose soil slumps into the pit]", 3.5)
		_pit_visual()


func _drink(_p: Player) -> void:
	player.heal(6.0)
	Overlay.toast("Cold and very clear, with an earthy aftertaste.", 3.0)


# -------------------------------------------------------------- road

func _road_step(p: Vector3) -> void:
	var mv := p - last_p
	mv.y = 0.0
	last_p = p
	var ln := mv.length()
	if ln > 25.0 or ln < 0.001:
		return
	var tn: Array = wm.track_near(p.x, p.z)
	if float(tn[0]) < WM.THW + 0.8 and not (player and player.swimming):
		road_m += ln
		off_m = maxf(0.0, off_m - ln)
		var ax := Vector3(0, 0, 1) if int(tn[1]) == 0 else Vector3(1, 0, 0)
		var dd := ax * signf(mv.dot(ax))
		if dd != Vector3.ZERO and absf(mv.normalized().dot(ax)) > 0.6:
			road_dir = dd
	else:
		off_m += ln
		if off_m > 45.0 and road_m > 0.0:
			if road_m > 200.0 and not road_done:
				Overlay.subtitle("[you have lost the track]", 3.0)
			road_m = 0.0
			said.erase("r1")
			said.erase("r2")
	if road_m > 300.0 and not said.has("r1"):
		said["r1"] = true
		Overlay.subtitle("[the ruts look fresh, as if something passed moments ago; nothing has]", 4.5)
	if road_m > 650.0 and not said.has("r2"):
		said["r2"] = true
		Overlay.subtitle("[far down the track, grey shapes stand above the trees]", 4.5)
	if road_m > 600.0 and not road_done:
		_skyline_at(p, NEED_M - road_m + 300.0)
	if road_m >= NEED_M and not road_done:
		_road_end(p)


func _track_point(p: Vector3, ahead: float) -> Vector3:
	var q := p + road_dir * ahead
	if road_dir.z != 0.0:
		q.x = wm.xline(wm.xi(p.x)) + WM.TOFF
	else:
		q.z = wm.zline(wm.zi(p.z)) + WM.TOFF
	q.y = wm.h_at(q.x, q.z)
	return q


func _skyline_at(p: Vector3, dist: float) -> void:
	if skyline == null:
		skyline = Node3D.new()
		skyline.name = "Skyline"
		add_child(skyline)
		var k := GeoKit.new(skyline, "Sky")
		k.shadows = false
		var r := RandomNumberGenerator.new()
		r.seed = level_seed + 12
		for i in 14:
			var hgt := r.randf_range(24.0, 75.0)
			var x := r.randf_range(-170.0, 170.0)
			k.box(Vector3(x, hgt * 0.5 - 6.0, r.randf_range(0.0, 90.0)), Vector3(r.randf_range(16.0, 36.0), hgt, r.randf_range(16.0, 30.0)), "l10_city", GeoKit.ALL, false)
		k.commit()
	var q := _track_point(p, dist)
	skyline.global_transform = Transform3D(Basis.looking_at(-road_dir, Vector3.UP), Vector3(q.x, wm.h_at(q.x, q.z), q.z))


## After a prolonged walk on the tracks the dirt meets a cracked asphalt back
## road (Level 11's page: "a back road that leads to Level 10").
func _road_end(p: Vector3) -> void:
	road_done = true
	var e := _track_point(p, 60.0)
	var k := kit("BackRoad")
	var side := Vector3(-road_dir.z, 0, road_dir.x)
	for i in 22:
		var c := e + road_dir * (i * 2.0 + 1.0)
		c.y = wm.h_at(c.x, c.z)
		var sz := Vector3(2.0, 0.3, 5.6) if road_dir.x != 0.0 else Vector3(5.6, 0.3, 2.0)
		k.box(c + Vector3(0, -0.12 + i * 0.002, 0), sz, "l10_asphalt")
		k.box(c + side * 3.0 + Vector3(0, -0.05, 0), Vector3(2.0, 0.3, 0.3) if road_dir.x != 0.0 else Vector3(0.3, 0.3, 2.0), "concrete", GeoKit.ALL, false)
	k.commit()
	var t := add_exit("L010>L011#1", "walk_in", e + road_dir * 3.0 + Vector3(0, 1.4, 0), Vector3(2.0, 3.0, 7.0) if road_dir.x != 0.0 else Vector3(7.0, 3.0, 2.0), "")
	if t:
		Overlay.subtitle("[ahead, the dirt track runs out onto cracked asphalt]", 4.5)


# ----------------------------------------------------------- runtime

func level_process(delta: float) -> void:
	if player == null:
		return
	_weather(delta)
	_tiles_tick(2)
	_surge_tick(delta)
	if rain:
		rain.global_position = player.global_position + Vector3(0, 9.0, 0)
	tick -= delta
	cp_cool = maxf(0.0, cp_cool - delta)
	if tick > 0.0:
		return
	tick = 0.2
	var p := player.global_position
	_water_follow(p)
	_road_step(p)
	var on_crop: int = wm.crop_at(p.x, p.z, p.y) if not player.swimming else 0
	player.walk_speed = 2.5 if on_crop > 0 else float(rules["walk_speed"])
	player.sprint_speed = 4.3 if on_crop > 0 else float(rules["sprint_speed"])
	if on_crop > 0 and not said.has("wade"):
		said["wade"] = true
		Overlay.subtitle("[dry stalks hiss against your legs]", 3.0)
	var inside := false
	for key in [world.key_at(p)]:
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				var meta: Dictionary = world.meta_of(key + Vector2i(dx, dz))
				for s in meta.get("structs", []):
					if (s["inside"] as AABB).grow(0.2).has_point(p + Vector3.UP * 0.5):
						inside = true
				for rc: Rect2 in meta.get("canola", []):
					var tag := "c%d_%d" % [int(rc.position.x), int(rc.position.y)]
					if rc.get_center().distance_to(Vector2(p.x, p.z)) < 70.0 and not said.has(tag):
						said[tag] = true
						Overlay.subtitle("[a sharp, sweet mustard smell drifts over the wheat]", 4.0)
	if inside and SessionState.is_story() and cp_cool <= 0.0:
		cp_cool = 90.0
		checkpoint("barn")
		Overlay.toast("Out of the wind for a while. (Checkpoint)", 3.0)
	_swim_tick(p)


func _swim_tick(p: Vector3) -> void:
	var deep: float = WM.WATER_Y - wm.h_at(p.x, p.z)
	if player.swimming and player.head_under and deep > 2.2:
		dive_t += 0.2
	else:
		dive_t = maxf(0.0, dive_t - 0.4)
	if dive_t > 0.6 and swim_exit == null:
		swim_exit = add_exit("L010>EXT#3", "condition", p, Vector3(4, 4, 4), "")
		if swim_exit:
			swim_exit.condition = func(): return dive_t >= 4.4
	if swim_exit:
		swim_exit.global_position = p
	if dive_t > 1.0 and not said.has("dive"):
		said["dive"] = true
		Overlay.subtitle("[the water is cold and strangely clear; streams of fine bubbles]", 3.5)
	if dive_t > 2.6 and not said.has("dive2"):
		said["dive2"] = true
		Overlay.subtitle("[below you the lake keeps going down]", 3.0)
	if dive_t <= 0.0:
		said.erase("dive")
		said.erase("dive2")


## Gusts in the crops; rare spells of fog or light rain (never night, never sun).
func _weather(delta: float) -> void:
	gust_t -= delta
	match gust_phase:
		0:
			gust = move_toward(gust, 0.0, delta * 0.05)
			if gust_t <= 0.0 and not qa_fixture:
				gust_phase = 1
				gust_t = 3.0
				wdir = wdir.rotated(rng.randf_range(-0.5, 0.5))
				if rng.randf() < 0.4:
					Overlay.subtitle("[a gust hisses through the wheat]", 2.5)
		1:
			gust = minf(1.0, gust + delta / 2.5)
			if gust_t <= 0.0:
				gust_phase = 2
				gust_t = rng.randf_range(3.0, 7.0)
		2:
			if gust_t <= 0.0:
				gust_phase = 3
		_:
			gust = maxf(0.0, gust - delta / 5.0)
			if gust <= 0.02:
				gust_phase = 0
				gust_t = rng.randf_range(14.0, 45.0)
	if not qa_fixture:
		next_spell -= delta
	if spell == "" and next_spell <= 0.0:
		spell = "fog" if rng.randf() < 0.5 else "rain"
		spell_t = rng.randf_range(60.0, 120.0)
		Overlay.subtitle("[fog settles over the fields]" if spell == "fog" else "[a light rain begins to patter on the crops]", 4.0)
	if spell != "" and not spell.begins_with("ending"):
		spell_t -= delta
		spell_amt = minf(1.0, spell_amt + delta / 20.0)
		if spell_t <= 0.0:
			spell = "ending_" + spell
	if spell.begins_with("ending"):
		spell_amt = maxf(0.0, spell_amt - delta / 25.0)
		if spell_amt <= 0.0:
			spell = ""
			next_spell = rng.randf_range(240.0, 480.0)
	var fogged := spell_amt if spell.ends_with("fog") else 0.0
	var rained := spell_amt if spell.ends_with("rain") else 0.0
	wet = clampf(wet + (delta / 30.0 if rained > 0.3 else -delta / 240.0), 0.0, 1.0)
	environment.fog_density = lerpf(FOG, 0.035, fogged) + rained * 0.004
	environment.fog_height_density = lerpf(0.05, 0.25, fogged)
	if rain:
		rain.emitting = rained > 0.15
		rain.amount_ratio = clampf(rained, 0.05, 1.0)
	rain_bed.volume_db = lerpf(-60.0, -16.0, rained)
	wind_bed.volume_db = lerpf(-28.0, -13.0, gust)
	M.set_weather(gust, wdir, wet)


func _rain_fx() -> void:
	rain = GPUParticles3D.new()
	rain.name = "Rain"
	rain.amount = 1600
	rain.lifetime = 1.3
	rain.emitting = false
	rain.visibility_aabb = AABB(Vector3(-20, -14, -20), Vector3(40, 18, 40))
	rain.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(16, 0.5, 16)
	pm.direction = Vector3(0.12, -1, 0.08)
	pm.spread = 3.0
	pm.initial_velocity_min = 8.5
	pm.initial_velocity_max = 10.0
	pm.gravity = Vector3(0, -4, 0)
	rain.process_material = pm
	var qm := QuadMesh.new()
	qm.size = Vector2(0.012, 0.42)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.78, 0.8, 0.82, 0.3)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	qm.material = mat
	rain.draw_pass_1 = qm
	add_child(rain)


func _sounds() -> void:
	wind_bed = sound.bed("wind", {"seconds": 9.0}, -28.0)
	rain_bed = sound.bed("rain", {}, -60.0)
	sound.bed("room_tone", {"cutoff": 120.0}, -36.0)
	sound.oneshot("creak", {"freq": 90.0}, 50.0, 120.0, 30.0, "[a loose barn door knocks in the wind, far off]", -24.0)


func _arrivals() -> void:
	add_arrival("start", start, 0.0)
	add_arrival("from_L009", Vector3(-1.4, wm.h_at(-1.4, 22.0) + 0.05, 22.0), 90.0)


func on_player_ready() -> void:
	world.target = player
	farw.target = player
	last_p = player.global_position
	_tiles_now()
	if SessionState.is_story() and SaveService.flag(stable_id, "arrived", false) == false:
		SaveService.set_flag(stable_id, "arrived", true)
		Overlay.subtitle("[wind moving through wheat] [the smell of damp soil]", 5.0)
	if TransitionService.pending_arrival == "from_L009":
		Overlay.subtitle("[the night is gone: grey daylight over a field]", 4.0)


# ------------------------------------------------------------------ QA

## QA mode only: a small canola patch 20 m from the spawn (the real patches are
## seeded hundreds of metres out) so the walker bot can fire L010>L184#2.
func _qa_fixture() -> void:
	var rc: Rect2 = wm.plot(0, 0)["canola"]
	var c := rc.get_center()
	var tgt := Vector3(c.x, wm.h_at(c.x, c.y), c.y)
	add_exit("L010>L184#2", "walk_in", tgt + Vector3(0, 1.2, 0), Vector3(5.0, 3.0, 4.0), "")
	qa_routes.append({"edge": "L010>L184#2", "target": tgt, "waypoints": [tgt], "note": "QA fixture: a canola patch planted 20 m from the spawn"})


func qa_self_test() -> Array:
	var out: Array = []
	await get_tree().process_frame
	_tiles_now()
	var inst := 0
	for tk in tiles:
		for mi in (tiles[tk] as Node3D).get_children():
			inst += (mi as MultiMeshInstance3D).multimesh.instance_count
	out.append({"what": "thousands of crop clumps stream around the spawn as MultiMesh tiles", "ok": inst > 3000, "detail": {"tiles": tiles.size(), "clumps": inst}})
	var hidden_ok := true
	for k in world.chunks.keys():
		if farw.chunks.has(k) and (farw.chunks[k]["node"] as Node3D).visible:
			hidden_ok = false
	out.append({"what": "far LOD ring surrounds the streamed window and hides under it", "ok": farw.chunks.size() >= 100 and hidden_ok, "detail": farw.chunks.size()})
	var lk := Vector3(WM.LAKE.x, WM.WATER_Y - 0.5, WM.LAKE.y)
	out.append({"what": "the authored lake hollow lies below the one water level and is swimmable", "ok": wm.h_at(lk.x, lk.z) < WM.WATER_Y - 1.0 and water.contains(lk), "detail": wm.h_at(lk.x, lk.z)})
	out.append({"what": "spawn stands on a dirt track above the water", "ok": float(wm.track_near(start.x, start.z)[0]) < 0.5 and start.y > WM.WATER_Y + 0.5, "detail": start})
	var d0 := pit_depth
	for i in 4:
		_dig(player)
	out.append({"what": "digging past one metre makes the worms surge", "ok": surge_t > 0.0 and worms.visible, "detail": [d0, surge_t]})
	surge_t = 0.0
	pit_depth = 0.6
	_pit_visual()
	var p0 := Vector3(WM.TOFF, 0, 30.0)
	last_p = p0
	for i in 125:
		_road_step(p0 + Vector3(0, 0, -10.0 * (i + 1)))
	var found := false
	for t in exits:
		if is_instance_valid(t) and t.edge_id == "L010>L011#1":
			found = true
	out.append({"what": "about 1.1 km along a dirt track the back road to Level 11 appears", "ok": road_done and found and skyline != null, "detail": road_m})
	print("L010 self-test ", out)
	return out


func qa_capture_plan() -> Array:
	var plan: Array = qa_shots.duplicate()
	var hp: Dictionary = wm.plot(WM.HOME.x, WM.HOME.y)
	var fr: Transform3D = hp["frame"]
	plan.append({"name": "barn", "pos": fr * Vector3(2.2, 1.62, 13.0), "target": fr * Vector3(8.0, 2.6, 22.5), "flashlight": false, "prepare": _tiles_now})
	return plan
