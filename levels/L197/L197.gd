extends LevelBase
## Level 197 "Crystal Caverns" (Backrooms Wikidot rev 100, accessed 2026-11-04;
## NavyEOD_24, CC BY-SA 3.0). Dossier: docs/canon/levels/L197.md.
##
## PLAN (read -> design):
## - SOURCE: an expansive crystal cave in four known zones. -> One continuous authored
##   cave (SDF meshed in 24 m blocks, method from L052/L008) folded into a U: Zone 1
##   turquoise east, Zone 2 amethyst south, Zone 3 ruby west; Zone 4 (unconfirmed) is
##   only the anonymous note found at Outpost "Good Feels".
## - SOURCE Zone 1: 15 ft wide, 17 ft high smooth cylindrical tunnels of unbreakable
##   diabase; round, smoothed stalagmites; slow drips; lit by crystal bunches on ceiling
##   and floor; turquoise calms; M.E.G. Outpost "Good Feels" near the entrance (gas masks
##   for Zone 2); the Entranced (~125 passive wanderers); the hard-to-find Meditation Cove
##   (30 ft radius, a ~30 ft crystal pouring distilled water like a fountain); a rumoured
##   unlit path. -> arrival hall with the outpost, the lit path, a loop through the cove,
##   rows of identical bedrolls for the Entranced, an unlit path that just goes on.
## - SOURCE Zone 2: haphazard 7 x 5 ft passage of brittle diabase, dim fading amethysts,
##   diseases (gas mask helps), pitch-black grooves (Deathmoth swarms), open areas, a
##   breach ~10 ft down to a graphite layer (rope; entities cannot climb ropes).
##   SIGNATURE (stateful): entering Zone 2 grows an amethyst wall over the way back; going
##   back in time is safe; walking on, rock shatters behind you and the way back becomes an
##   amethyst tunnel that tightens to a dead end full of disease.
## - SOURCE Zone 3: 10 x 10 ft bores bathed in red, unbearably hot, searing rubies, inclines
##   up to 83 degrees, enraged roaming entities (turquoise dazes them, then detonates), the
##   Crimson Fortress (obsidian bridges, a platform on nothing, a cold crystal hall with
##   stairs, rooms and ruby chests) and an unlit tunnel with a fluorescent buzz that sends
##   you to Level 0 (exit L197>L000#5, the walker-bot target).
## - Entities: only as sound and subtitles (never bodies, never combat).

const C := preload("res://levels/L197/L197_cave.gd")
const Plan := preload("res://levels/L197/L197_plan.gd")
const Dress := preload("res://levels/L197/L197_dress.gd")
const Fort := preload("res://levels/L197/L197_fortress.gd")
const Mech := preload("res://levels/L197/L197_mech.gd")

var plan
var noise := FastNoiseLite.new()
var drng := RandomNumberGenerator.new()
var accs: Dictionary = {}
var hot_spots: Array = []
var cave_root: Node3D
var dress_root: Node3D
var stal_body: StaticBody3D
var zone_meshes := {}
var chest_at := Vector3.ZERO
var fortress_hall := AABB()
var room_doors: Array = []
var drips := 0
var mech


func build() -> void:
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 420.0
	rules["reverb_room"] = 0.85
	rules["reverb_wet"] = 0.32
	rules["kill_y"] = -45.0
	indoor_env(Color(0.35, 0.62, 0.62), 0.12, Color(0.02, 0.07, 0.08), 0.012)
	environment.tonemap_exposure = 1.5
	environment.glow_enabled = true
	environment.glow_intensity = 0.5
	environment.glow_bloom = 0.08
	environment.glow_hdr_threshold = 0.85
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.06
	environment.adjustment_saturation = 1.05
	_materials()
	noise.seed = 197
	noise.frequency = 0.13
	noise.fractal_octaves = 3
	drng.seed = 19700
	plan = Plan.new()
	lights.setup(14, 1)
	cave_root = Node3D.new()
	cave_root.name = "Cave"
	add_child(cave_root)
	dress_root = Node3D.new()
	dress_root.name = "Dress"
	add_child(dress_root)
	stal_body = StaticBody3D.new()
	stal_body.name = "Stalagmites"
	dress_root.add_child(stal_body)
	_blocks()
	_dress()
	Dress.outpost(self, dress_root)
	Dress.cove(self, dress_root)
	Dress.entranced_camp(self, dress_root)
	Fort.build(self, dress_root)
	_commit_accs()
	mech = Mech.new(self)
	mech.build()
	add_arrival("start", Plan.ARRIVAL, 45.0)
	add_arrival("from_L197", Plan.ARRIVAL, 45.0)
	add_exit("L197>L000#5", "walk_in", Plan.EXIT_L000 + Vector3(0, 1.2, 0), Vector3(2.8, 2.6, 2.6), "Follow the fluorescent buzz down the unlit tunnel")
	add_landmark("M.E.G. Outpost \"Good Feels\"", Plan.OUTPOST)
	add_landmark("Meditation Cove", Plan.COVE)
	add_landmark("Zone 2 threshold (amethyst wall)", Plan.THRESH)
	add_landmark("Breach to the graphite layer", Plan.BREACH)
	add_landmark("Zone 3 junction and chimney", Plan.R1)
	add_landmark("The Crimson Fortress", Fort.centre())
	add_landmark("Unlit tunnel with a fluorescent buzz", Plan.FLUO_END)
	var pc: Vector3 = Fort.centre()
	add_shot("outpost_hall", Vector3(6.6, 1.6, 3.4), Vector3(-2.0, 1.2, -3.0), {"flashlight": false})
	add_shot("meditation_cove", Plan.COVE + Vector3(-6.5, 1.7, -5.2), Plan.COVE + Vector3(0, 4.2, 0), {"flashlight": false})
	add_shot("amethyst_passage", Vector3(71.2, 0.5, -21.0), Vector3(72.0, -0.1, -28.0), {"flashlight": true})
	add_shot("ruby_bore", Vector3(40.0, -0.3, -43.0), Vector3(28.0, 0.2, -47.2), {"flashlight": false})
	add_shot("crimson_fortress", Vector3(Plan.MOUTH.x - 0.6, Plan.MOUTH.y + 1.7, -75.6), pc + Vector3(0, 10.0, 0), {"flashlight": false})
	add_shot("lit_path", Vector3(20.0, 1.6, -2.6), Vector3(36.0, 1.6, 0.6), {"flashlight": false})


func _photo(name: String, tex: String, tint: Color, scale: float, nrm: float, rough: float = 1.0, metal: float = 0.0) -> void:
	var m := ORMMaterial3D.new()
	var base := "res://assets/external/%s/%s_%s_1k.jpg"
	m.albedo_texture = load(base % [tex, tex, "diff"])
	m.normal_enabled = true
	m.normal_texture = load(base % [tex, tex, "nor_gl"])
	m.orm_texture = load(base % [tex, tex, "arm"])
	m.albedo_color = tint
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(scale, scale, scale)
	m.uv1_triplanar_sharpness = 5.0
	m.normal_scale = nrm
	m.roughness = rough
	m.metallic = metal
	MatLib.register(name, m)


func _crystal(name: String, alb: Color, em: Color, energy: float) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = alb
	m.roughness = 0.12
	m.metallic = 0.15
	m.metallic_specular = 0.9
	m.emission_enabled = true
	m.emission = em
	m.emission_energy_multiplier = energy
	m.rim_enabled = true
	m.rim = 0.4
	MatLib.register(name, m)


func _materials() -> void:
	_photo("l197_z1_rock", "aerial_rocks_02", Color(0.36, 0.44, 0.47), 0.22, 0.45, 0.62)
	_photo("l197_z1_floor", "aerial_rocks_02", Color(0.3, 0.36, 0.38), 0.3, 0.5, 0.7)
	_photo("l197_z2_rock", "aerial_rocks_02", Color(0.44, 0.38, 0.47), 0.42, 1.7)
	_photo("l197_z2_floor", "dirt_floor", Color(0.38, 0.33, 0.38), 0.4, 1.3)
	_photo("l197_z3_rock", "aerial_rocks_02", Color(0.55, 0.34, 0.29), 0.36, 1.4)
	_photo("l197_z3_floor", "aerial_rocks_02", Color(0.42, 0.27, 0.23), 0.4, 1.2)
	_photo("l197_z4_rock", "aerial_rocks_02", Color(0.2, 0.2, 0.21), 0.4, 1.5, 0.45, 0.55)
	_photo("l197_fort_rock", "aerial_rocks_02", Color(0.22, 0.08, 0.07), 0.06, 1.0)
	_crystal("l197_turq", Color(0.3, 0.85, 0.8), Color(0.1, 0.8, 0.72), 0.3)
	_crystal("l197_ame", Color(0.5, 0.26, 0.72), Color(0.55, 0.2, 0.95), 0.7)
	_crystal("l197_ruby", Color(0.7, 0.08, 0.07), Color(1.0, 0.1, 0.07), 0.45)
	_crystal("l197_ruby_solid", Color(0.5, 0.03, 0.04), Color(0.8, 0.06, 0.05), 0.6)
	var flow := StandardMaterial3D.new()
	flow.albedo_color = Color(0.3, 0.4, 0.42)
	flow.roughness = 0.28
	flow.metallic_specular = 0.7
	MatLib.register("l197_flow", flow)
	var obs := StandardMaterial3D.new()
	obs.albedo_color = Color(0.06, 0.05, 0.065)
	obs.roughness = 0.07
	obs.metallic = 0.3
	obs.metallic_specular = 1.0
	MatLib.register("l197_obsidian", obs)
	MatLib.define("l197_fort_wall", {"albedo_a": Color(0.32, 0.03, 0.04), "albedo_b": Color(0.2, 0.02, 0.03), "pattern": 11,
		"pattern_color": Color(0.55, 0.06, 0.06), "pattern_strength": 0.5, "roughness_a": 0.15, "roughness_b": 0.35,
		"emission_color": Color(0.5, 0.03, 0.02), "emission_energy": 0.25, "noise_scale": 0.6}, "rock")
	MatLib.define("l197_wood", {"albedo_a": Color(0.36, 0.26, 0.16), "albedo_b": Color(0.3, 0.2, 0.12)}, "wood_floor")
	MatLib.register("l197_board", MatLib.standard(Color(0.16, 0.24, 0.2), 0.8))
	MatLib.register("l197_bedroll", MatLib.standard(Color(0.22, 0.25, 0.2), 0.95))
	MatLib.register("l197_blanket", MatLib.standard(Color(0.35, 0.3, 0.24), 0.95))
	MatLib.register("l197_distilled", MatLib.water({"shallow_color": Color(0.32, 0.78, 0.8), "deep_color": Color(0.05, 0.35, 0.42), "clarity": 0.9, "wave_height": 0.01}))


# ------------------------------------------------------------------ cave blocks

const ZONE_MATS := {1: ["l197_z1_rock", "l197_z1_floor"], 2: ["l197_z2_rock", "l197_z2_floor"],
	3: ["l197_z3_rock", "l197_z3_floor"], 4: ["l197_z4_rock", "l197_z4_rock"]}


func _blocks() -> void:
	var bb: AABB = plan.bounds()
	var zf := func(p: Vector3) -> int: return Plan.zone_of(p)
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
				var zone := int(key) / 2
				if zone == 0:
					continue
				var fl := int(key) % 2 == 1
				var mat: String = ZONE_MATS[zone][1 if fl else 0]
				C.commit(node, buckets[key], mat, true, "concrete")
				zone_meshes[zone] = int(zone_meshes.get(zone, 0)) + 1


# ------------------------------------------------------------------ dressing

func acc(name: String) -> C.Acc:
	if not accs.has(name):
		accs[name] = C.Acc.new()
	return accs[name]


func fs_near(p: Vector3) -> Array:
	return plan.features_for(AABB(p - Vector3(16, 16, 16), Vector3(32, 32, 32)))


func crystal_light(p: Vector3, zone: int, opt: Dictionary) -> void:
	var col: Color = Dress.COL[zone]
	lights.add_anchor(p, col, float(opt.get("light", 1.0)), float(opt.get("lrange", 8.0)), float(opt.get("flicker", 0.0)), "z%d" % zone)


func stalagmite(g: Vector3, h: float, r: float) -> void:
	C.lathe(acc("l197_flow"), g - Vector3(0, 0.05, 0), h, r)
	if h > 0.55:
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = r * 0.8
		sh.height = h
		cs.shape = sh
		cs.position = g + Vector3(0, h * 0.5, 0)
		stal_body.add_child(cs)


func drip_at(tip: Vector3, _floor_p: Vector3) -> void:
	if drips >= 7:
		return
	drips += 1
	sound.emitter("drip", tip, {"freq": [900.0, 1080.0, 1240.0][drips % 3]}, -16.0, 12.0)


func label(text: String, p: Vector3, n: Vector3, px: float, col: Color, size: int = 64) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = px
	l.modulate = col
	l.outline_size = 0
	l.shaded = true
	l.double_sided = false
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(l)
	l.global_position = p
	l.basis = Basis.looking_at(-n, Vector3.UP)
	return l


func _dress() -> void:
	var z1 := {"step": 2.6, "ceil_p": 0.75, "wall_n": 2, "size": Vector2(0.45, 1.5), "count": Vector2i(4, 9),
		"light_every": 6.0, "light": 2.2, "lrange": 11.0, "stal": 0.45, "stalactite": 0.5, "lat": 1.6}
	Dress.dress_path(self, plan.lit_path, 1, z1)
	var z1c := z1.duplicate()
	z1c["ceil_p"] = 0.4
	z1c["light_every"] = 11.0
	z1c["wall_n"] = 1
	Dress.dress_path(self, plan.cove_path, 1, z1c)
	# the unlit path: smoothed stone only, no crystals
	Dress.dress_path(self, plan.unlit_path, 1, {"step": 3.0, "ceil_p": 0.0, "wall_n": 0, "stal": 0.6, "stalactite": 0.6})
	Dress.dress_room(self, Plan.HALL_A, 1, 26, Vector2(0.5, 1.4), 4, {"light": 2.0, "lrange": 11.0, "clear": 6.0})
	Dress.dress_room(self, Plan.J1, 1, 10, Vector2(0.5, 1.3), 1, {"light": 1.1, "lrange": 9.0})
	# Zone 2: single small amethysts, dim and fading
	var z2 := {"step": 2.0, "ceil_p": 0.35, "wall_n": 3, "size": Vector2(0.16, 0.38), "count": Vector2i(1, 4),
		"light_every": 6.5, "light": 0.9, "lrange": 6.0, "flicker": 0.6, "min_ceiling": 1.9, "wall_scale": 1.0, "lat": 0.4}
	Dress.dress_path(self, plan.z2_path, 2, z2)
	Dress.dress_room(self, Plan.O1, 2, 12, Vector2(0.15, 0.32), 1, {"light": 0.6, "lrange": 6.0, "flicker": 0.5})
	Dress.dress_room(self, Plan.O2, 2, 12, Vector2(0.15, 0.32), 1, {"light": 0.6, "lrange": 6.0, "flicker": 0.5})
	# graphite: crystals are rare
	Dress.dress_path(self, plan.graphite_path, 4, {"step": 6.0, "ceil_p": 0.0, "wall_n": 1, "size": Vector2(0.12, 0.22), "count": Vector2i(1, 2)})
	# Zone 3: rubies everywhere
	var z3 := {"step": 2.0, "ceil_p": 0.6, "wall_n": 3, "size": Vector2(0.35, 1.1), "count": Vector2i(3, 8),
		"light_every": 6.0, "light": 1.0, "lrange": 8.0, "min_ceiling": 2.6, "wall_scale": 0.65, "lat": 0.8, "flicker": 0.05}
	Dress.dress_path(self, plan.z3_path, 3, z3)
	Dress.dress_path(self, plan.upper_path.slice(0, plan.upper_path.size() - 1), 3, z3)
	Dress.dress_path(self, plan.fluo_path.slice(0, 2), 3, z3)
	Dress.dress_room(self, Plan.R1, 3, 14, Vector2(0.4, 1.2), 2, {"light": 1.5, "lrange": 9.0})


func _commit_accs() -> void:
	for name in accs.keys():
		var mi := C.commit(dress_root, accs[name], name, false, "concrete", name != "l197_turq")
		if mi:
			mi.name = "Acc_" + name


# ------------------------------------------------------------------ runtime

func on_player_ready() -> void:
	mech.on_ready()


func level_process(delta: float) -> void:
	mech.process(delta)


func qa_self_test() -> Array:
	await get_tree().process_frame
	return await mech.self_test()


## Route checkpoints for navigation debugging (floor points along the walked route).
func qa_debug_points() -> Array:
	var out: Array = []
	for pl in [plan.lit_path, plan.z2_path, plan.z3_path, plan.fluo_path]:
		for p in pl:
			out.append(p + Vector3(0, 0.1, 0))
	return out
