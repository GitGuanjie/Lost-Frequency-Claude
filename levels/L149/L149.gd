extends LevelBase
## Level 149 "The Coconut Isles" (Backrooms Wikidot rev 32, accessed 2026-11-04; Ferraru,
## CC BY-SA 3.0). Dossier: docs/canon/levels/L149.md.
##
## PLAN (read -> design):
## - SOURCE: an expansive evening sky filled with floating sand isles with coconut palms; no
##   day-night cycle, the Sun fixed; gravity ~15 % of Earth's; strong winds below keep the isles
##   from falling into the abyss; isles of sand, dirt and rock, 5 m to 6 km, drifting slowly;
##   100-200 palms in the middle of almost every isle, as tall as about half the isle's width;
##   bigger isles toward the centre carry grass, bushes, rarely flowers; crickets; rain and
##   moderate winds are common.
##   -> the largest isle (ADAPTATION: 144 x 124 m) under a custom evening sky shader with a sun
##   fixed low in the west, a cloud sea far below; seven walkable satellite isles in an eastward
##   chain and seven more around it, all drifting (AnimatableBody3D), jumpable in 0.15 g
##   (gravity 1.47 m/s2, jump 3.3 m/s); ~50 distant isles to the horizon; palms (MultiMesh,
##   two LODs) clustered in each isle's middle; rain showers come and go.
## - SOURCE: the Lost Suns' only settlement on the largest isle: Iroquois-style longhouses,
##   tree houses, coconut-tree huts and one public house; palm-bark bows, palm spears, shared
##   ripe coconuts; neutral; drawings of Coconut Snares since the 15th century.
##   -> three bark longhouses (barrel roofs, two-tier sleeping platforms, hearths under smoke
##   holes), two tree houses on 6 m decks with stairs, six huts, the public house with the
##   drawing board, the hunters' rack and the coconut heap; fires burn. ADAPTATION: the 40-100
##   residents are not modelled (no figure models); their lit fires, mats and stores show them.
## - SOURCE: the Barrier ~200 km out: stronger gravity, no isles beyond, loud noises, intense
##   anxiety; going too deep has an extremely small chance of no-clipping to Level 37 or 140.
##   -> east of x 250 gravity climbs to 5 m/s2, the sky flickers violet, booms and a heartbeat
##   rise, the vignette tightens; the outermost isle's east rim is a rock lip; pushing into the
##   Barrier there rolls a 1-in-150 chance per attempt (L149>L037#1 / L149>L140#2).
## - Entity: Coconut Snares exist only on the far isles' palms; never shown (page gives no
##   behaviour); the rustling crowns and the drawings stand for them.
## - ABSENT: night, other entities, vehicles, bridges between isles, an easy exit.

const Isle := preload("res://levels/L149/L149_isle.gd")
const Village := preload("res://levels/L149/L149_village.gd")
const G_LOW := 1.47
const G_BARRIER := 5.0
const BARRIER_X := 250.0
const BARRIER_P := 1.0 / 150.0
const SUN_DIR := Vector3(-0.99, 0.14, 0.0)

var IS: Isle
var V: Village
var main: Dictionary
var outer: Dictionary
var walkable: Array = []
var decor_count := 0
var palm_total := 0
var sky_mat: ShaderMaterial
var rain_mi: MultiMeshInstance3D
var rain_k := 0.0
var rain_on := false
var rain_t := 0.0
var _rain_bed: AudioStreamPlayer
var _rumble: AudioStreamPlayer
var _heart: AudioStreamPlayer
var _wind: AudioStreamPlayer
var drift_t := 0.0
var barrier_k := 0.0
var _attempt_t := 0.0
var _barrier_dest := ""
var _push_said := 0.0
var _said := {}
var exit37: ExitTrigger
var exit140: ExitTrigger


func build() -> void:
	rules["gravity"] = G_LOW
	rules["jump_velocity"] = 3.3
	rules["view_distance"] = 2600.0
	rules["kill_y"] = -400.0
	rules["reverb_room"] = 0.05
	rules["reverb_wet"] = 0.02
	outdoor_env(Color(0.14, 0.13, 0.32), Color(0.98, 0.56, 0.36), Color(0.06, 0.04, 0.1), Vector2(8.0, -90.0),
		Color(1.0, 0.66, 0.42), 1.25, Color(0.62, 0.44, 0.44), 0.0011)
	IS = Isle.new(self)
	sky_mat = IS.sky_material()
	sky_mat.set_shader_parameter("sun_dir", SUN_DIR)
	environment.sky.sky_material = sky_mat
	environment.ambient_light_energy = 0.75
	environment.fog_sky_affect = 0.0
	environment.fog_aerial_perspective = 0.45
	environment.fog_height = -25.0
	environment.fog_height_density = 0.012
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.05
	environment.glow_enabled = true
	environment.glow_intensity = 0.4
	sun.directional_shadow_max_distance = 140.0
	Isle.materials()
	Village.materials()
	IS.make_palm_meshes()
	_main_isle()
	_satellites()
	_far_isles()
	lights.setup(8, 0)
	lights.max_distance = 45.0
	for f in V.fires:
		lights.add_anchor(f, Color(1.0, 0.55, 0.22), 1.1, 7.0, 0.25)
	rain_mi = IS.rain_node()
	add_child(rain_mi)
	rain_t = rng.randf_range(90.0, 180.0)
	_barrier()
	_interactions()
	_sounds()
	var ax := -72.0 * Isle.edge_r(main, PI) * 0.8
	var arr := Vector3(ax, IS.h_local(main, ax, 0.0) + 0.1, 0.0)
	add_arrival("from_L046", arr, -90.0)
	if SessionState.is_qa():
		# QA fixture: the bot starts on the outermost isle of the Barrier and walks to its rim.
		var o: Vector3 = outer["c"]
		add_arrival("start", o + Vector3(-5.0, IS.h_local(outer, -5.0, 0.0) + 0.1, 0.0), -90.0)
		qa_routes.append({"edge": "L149>L037#1", "target": o + Vector3(float(outer["rim"]), 0, 0), "note": "QA fixture: start on the outermost Barrier isle; the roll is forced to succeed"})
	else:
		add_arrival("start", arr, -90.0)
	add_landmark("Lost Suns village", Vector3(0, 3, 0))
	add_landmark("Public house", Vector3(34, 2, 14))
	add_landmark("Eastward chain of isles", Vector3(138, 0, -10))
	add_landmark("The Barrier", outer["c"])
	_shots()


# --------------------------------------------------------------- isles

func _main_isle() -> void:
	main = {"c": Vector3.ZERO, "rx": 72.0, "rz": 62.0, "seed": 1.3, "dome": 3.2, "depth": 80.0, "rings": 26, "segs": 64, "grass": 0.8}
	var flats: Array = []
	for s in Village.site_plan():
		var x: float = s[1]
		var z: float = s[2]
		var r := 4.0
		match s[0]:
			"longhouse":
				r = float(s[3]) * 0.62
			"public":
				r = 11.0
			"treehouse":
				r = 6.0
			"fire":
				r = 3.5
		flats.append(Vector4(x, z, IS.h_local(main, x, z), r))
	main["flats"] = flats
	IS.build(main, self)
	V = Village.new(self, IS, main, rng)
	V.build()
	var avoid: Array = V.avoid.duplicate()
	for s in Village.site_plan():
		avoid.append(Vector3(s[1], s[2], 14.0 if s[0] == "longhouse" else (10.0 if s[0] == "public" else 5.0)))
	palm_total += IS.palms(main, 150, 13.0, 24.0, 0.34, rng, avoid)
	palm_total += IS.palms(main, 45, 8.0, 15.0, 0.88, rng, avoid)
	_bushes(main, 220, 0.85, avoid)
	walkable.append(main)


func _satellites() -> void:
	# eastward chain to the Barrier [x, y, z, rx, rz]; the last two are inside the Barrier
	var chain := [[98.0, 2.0, 8.0, 18.0, 15.0], [138.0, -2.5, -9.0, 14.0, 12.0], [172.0, 1.0, 5.0, 12.0, 11.0],
		[203.0, 3.5, -5.0, 11.0, 9.5], [232.0, 0.5, 6.0, 10.0, 9.0], [262.0, -1.5, -3.0, 12.0, 10.0], [295.0, 0.0, 2.0, 13.0, 11.0],
		[40.0, 6.0, -98.0, 16.0, 14.0], [-28.0, -4.0, -102.0, 13.0, 11.0], [-98.0, 3.0, -42.0, 15.0, 13.0], [-110.0, -2.0, 42.0, 12.0, 12.0],
		[30.0, 3.0, 100.0, 14.0, 12.0], [-50.0, 8.0, 94.0, 10.0, 9.0], [92.0, 9.0, 72.0, 8.0, 7.0]]
	for i in chain.size():
		var c: Array = chain[i]
		var sp := {"c": Vector3(c[0], c[1], c[2]), "rx": c[3], "rz": c[4], "seed": 2.0 + i * 1.37, "dome": 0.6 + float(c[3]) * 0.06,
			"depth": float(c[3]) * 1.6, "rings": 10, "segs": 30, "grass": 0.55 if float(c[3]) > 12.0 else 0.0, "moving": true}
		sp["home"] = sp["c"]
		sp["amp"] = Vector3(rng.randf_range(1.5, 3.5), rng.randf_range(0.3, 0.8), rng.randf_range(1.5, 3.5)) * (0.4 if i >= 5 and i <= 6 else 1.0)
		sp["period"] = rng.randf_range(160.0, 320.0)
		sp["phase"] = rng.randf() * TAU
		IS.build(sp, self)
		palm_total += IS.palms(sp, int(clampf(float(c[3]) * 2.2, 12.0, 40.0)), float(c[3]) * 0.75, float(c[3]) * 1.05, 0.45, rng)
		if float(c[3]) > 12.0:
			_bushes(sp, int(float(c[3]) * 2.0), 0.6, [])
		walkable.append(sp)
	outer = walkable[7]


func _far_isles() -> void:
	var n := 0
	while n < 52:
		var a := rng.randf() * TAU
		var dist := rng.randf_range(340.0, 1500.0)
		var p := Vector3(cos(a) * dist, rng.randf_range(-170.0, 150.0), sin(a) * dist * 0.8)
		if p.x > 230.0:
			continue
		var r := clampf(lerpf(150.0, 25.0, (dist - 340.0) / 1160.0) * rng.randf_range(0.4, 1.1), 12.0, 160.0)
		var sp := {"c": p, "rx": r, "rz": r * rng.randf_range(0.7, 1.0), "seed": 9.0 + n * 0.77, "dome": r * 0.05, "depth": r * 0.8,
			"rings": 5, "segs": 18, "grass": 0.6, "decor": true}
		IS.build(sp, self)
		IS.palms(sp, int(clampf(r * 0.4, 10.0, 30.0)), r * 0.35, r * 0.5, 0.4, rng, [], true)
		n += 1
	decor_count = n


func _bushes(sp: Dictionary, count: int, spread: float, avoid: Array) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = IS.shrub_mesh
	var xs: Array = []
	var cols: Array = []
	for i in count * 2:
		if xs.size() >= count:
			break
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf()) * spread
		var lx := cos(a) * r * float(sp["rx"])
		var lz := sin(a) * r * float(sp["rz"])
		var bad := false
		for v: Vector3 in avoid:
			if Vector2(lx - v.x, lz - v.y).length() < v.z:
				bad = true
		if bad:
			continue
		var s := rng.randf_range(0.9, 2.2)
		xs.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.7, 1.1), s)), IS.ground(sp, lx, lz) - Vector3(0, 0.05, 0)))
		if rng.randf() < 0.07:
			cols.append(IS.ground(sp, lx, lz) + Vector3(rng.randf_range(-0.4, 0.4), 0.45 * s, rng.randf_range(-0.4, 0.4)))
	mm.instance_count = xs.size()
	for i in xs.size():
		mm.set_instance_transform(i, xs[i])
	var mi := MultiMeshInstance3D.new()
	mi.name = "Bushes"
	mi.multimesh = mm
	mi.visibility_range_end = 160.0
	(sp["body"] as Node3D).add_child(mi)
	if cols.is_empty():
		return
	# rare tropical flowers among the larger isles' bushes
	var fm := MultiMesh.new()
	fm.transform_format = MultiMesh.TRANSFORM_3D
	var sm := SphereMesh.new()
	sm.radius = 0.09
	sm.height = 0.14
	sm.radial_segments = 6
	sm.rings = 3
	fm.mesh = sm
	fm.instance_count = cols.size() * 3
	for i in cols.size():
		for q in 3:
			fm.set_instance_transform(i * 3 + q, Transform3D(Basis(), (cols[i] as Vector3) + Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(-0.1, 0.1), rng.randf_range(-0.2, 0.2))))
	var fmi := MultiMeshInstance3D.new()
	fmi.name = "Flowers"
	fmi.multimesh = fm
	fmi.material_override = MatLib.standard(Color(0.85, 0.12, 0.25), 0.6)
	fmi.visibility_range_end = 60.0
	(sp["body"] as Node3D).add_child(fmi)


func _drift(delta: float) -> void:
	drift_t += delta
	for sp in walkable:
		if not sp.get("moving", false):
			continue
		var body: Node3D = sp.get("body")
		if not is_instance_valid(body):
			continue
		var ph: float = float(sp["phase"]) + drift_t * TAU / float(sp["period"])
		var amp: Vector3 = sp["amp"]
		body.position = (sp["home"] as Vector3) + Vector3(sin(ph) * amp.x, sin(ph * 2.0) * amp.y, cos(ph * 0.7) * amp.z)


# --------------------------------------------------------------- the Barrier

func _barrier() -> void:
	var body: Node3D = outer["body"]
	var rim: float = float(outer["rx"]) * Isle.edge_r(outer, 0.0) * 0.96
	outer["rim"] = rim
	# a lip of rock on the east rim: the end of the level
	for i in 7:
		var z := -6.0 + i * 2.0
		var lx := rim + 0.3
		var y := IS.h_local(outer, lx - 0.8, z) - 0.3
		var rk := Props.place(self, body, "kenney/nature-kit/rock-tallc" if i % 2 == 0 else "kenney/nature-kit/rock-talld", Vector3(lx, y, z), rng.randf() * 360.0, rng.randf_range(1.2, 1.8))
		_restyle(rk, MatLib.get_mat("l149_root"))
	var lip := StaticBody3D.new()
	body.add_child(lip)
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = Vector3(1.2, 2.5, 14.0)
	cs.shape = bx
	cs.position = Vector3(rim + 0.5, IS.h_local(outer, rim - 1.0, 0.0) + 1.0, 0.0)
	lip.add_child(cs)
	var tp := Vector3(rim + 0.4, IS.h_local(outer, rim - 1.0, 0.0) + 1.2, 0.0)
	exit37 = make_exit("L149>L037#1", "noclip", tp, Vector3(3.6, 3.0, 8.0), "Push on, deeper into the Barrier", body)
	exit140 = make_exit("L149>L140#2", "noclip", tp, Vector3(3.6, 3.0, 8.0), "", body)
	if exit37:
		exit37.condition = func() -> bool: return _barrier_cond("L037")
		exit37.fired.connect(func(_e: String) -> void: Overlay.glitch(1.0))
	if exit140:
		exit140.condition = func() -> bool: return _barrier_cond("L140")
		exit140.fired.connect(func(_e: String) -> void: Overlay.glitch(1.0))
	# the unstable edge itself: a faint shimmering curtain beyond the last isle
	var cur := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(900.0, 700.0)
	pm.orientation = PlaneMesh.FACE_X
	cur.mesh = pm
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, shadows_disabled, fog_disabled;
uniform float strength = 0.12;
void fragment() {
	float t = TIME;
	float lines = smoothstep(0.92, 1.0, sin(UV.y * 900.0 + sin(UV.x * 40.0 + t * 2.0) * 6.0 + t * 30.0));
	float bands = 0.5 + 0.5 * sin(UV.x * 18.0 + t * 0.7) * sin(UV.y * 7.0 - t * 0.4);
	float edge = smoothstep(0.0, 0.3, UV.y) * smoothstep(1.0, 0.6, UV.y);
	ALBEDO = vec3(0.45, 0.3, 0.75) * (lines * 0.6 + bands * 0.15) * strength * edge;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	cur.material_override = m
	cur.position = Vector3((outer["c"] as Vector3).x + rim + 14.0, 0.0, 0.0)
	cur.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(cur)


func _restyle(n: Node, m: Material) -> void:
	if n == null:
		return
	if n is MeshInstance3D:
		(n as MeshInstance3D).material_override = m
	for c in n.get_children():
		_restyle(c, m)


func _barrier_cond(dest: String) -> bool:
	if SessionState.is_qa():
		return dest == "L037"
	if _attempt_t <= 0.0:
		_attempt_t = 6.0
		_barrier_dest = ""
		if rng.randf() < BARRIER_P:
			_barrier_dest = "L037" if rng.randf() < 0.5 else "L140"
	return _barrier_dest == dest


func _barrier_update(delta: float, p: Vector3) -> void:
	_attempt_t = maxf(0.0, _attempt_t - delta)
	barrier_k = smoothstep(BARRIER_X, (outer["c"] as Vector3).x + 8.0, p.x)
	player.gravity = lerpf(G_LOW, G_BARRIER, pow(barrier_k, 1.4))
	sky_mat.set_shader_parameter("unrest", barrier_k)
	if not SessionState.is_qa():
		Overlay.set_screen_effect("vignette", 0.25 + 0.5 * barrier_k)
	if _rumble:
		_rumble.volume_db = lerpf(-60.0, -10.0, barrier_k)
	if _heart:
		_heart.volume_db = lerpf(-60.0, -12.0, smoothstep(0.4, 1.0, barrier_k))
	if barrier_k > 0.2 and not _said.has("barrier") and not SessionState.is_qa():
		_said["barrier"] = true
		Overlay.subtitle("[you feel heavy. Something huge booms out past the last isles, and dread climbs your throat]", 5.0)
	if barrier_k > 0.3 and rng.randf() < delta * 0.12 * barrier_k:
		sound.play_at("distant_boom", {}, p + Vector3(60.0, rng.randf_range(-30.0, 30.0), rng.randf_range(-40.0, 40.0)), -2.0, "[a deep boom from the Barrier]")
	_push_said = maxf(0.0, _push_said - delta)
	if exit37 and is_instance_valid(exit37) and player.pushing_into(exit37.global_position, exit37.size) and barrier_k > 0.8 \
			and _barrier_dest == "" and _push_said <= 0.0 and not SessionState.is_qa() and player.global_position.distance_to(exit37.global_position) < 4.0:
		_push_said = 6.0
		Overlay.glitch(0.25)
		Overlay.subtitle("[the air thickens into a wall and shoves you back. Nothing gives - this time]", 3.5)


# --------------------------------------------------------------- rain, interactions, sound

func _rain(delta: float) -> void:
	rain_t -= delta
	if rain_t <= 0.0:
		rain_on = not rain_on
		rain_t = rng.randf_range(60.0, 110.0) if rain_on else rng.randf_range(150.0, 300.0)
		if rain_on and not SessionState.is_qa():
			Overlay.subtitle("[warm rain sweeps in across the isles]", 3.0)
	set_rain(move_toward(rain_k, 1.0 if rain_on else 0.0, delta / 12.0))


func set_rain(v: float) -> void:
	rain_k = v
	rain_mi.visible = v > 0.01
	(rain_mi.material_override as ShaderMaterial).set_shader_parameter("amount", v)
	sky_mat.set_shader_parameter("rain", v)
	sun.light_energy = lerpf(1.25, 0.45, v)
	environment.fog_density = lerpf(0.0011, 0.004, v)
	if _rain_bed:
		_rain_bed.volume_db = lerpf(-60.0, -16.0, v)


func _interactions() -> void:
	for n in V.notes:
		add_note(n[0], n[1], n[2], n[3], Vector3(0.8, 0.8, 0.8), false)
	for cp in V.coconut_piles:
		add_interactable(cp + Vector3(0, 0.35, 0), Vector3(1.6, 0.8, 1.6), "Take a ripe coconut (they are shared here)",
			func(pl: Player) -> void:
				if is_instance_valid(pl):
					pl.heal(10.0)
				Overlay.subtitle("[you crack a ripe coconut on a stone. Sweet water, white meat]", 3.0))


func _sounds() -> void:
	_wind = sound.bed("wind", {"seconds": 9.0}, -22.0)
	sound.emitter("crickets", Vector3(0, 4, 0), {"seconds": 7.0}, -18.0, 90.0)
	for f in V.fires:
		sound.emitter("crackle", f, {"seconds": 4.0}, -16.0, 10.0)
	_rain_bed = sound.bed("rain", {"seconds": 5.0}, -60.0)
	_rumble = sound.bed("room_tone", {"cutoff": 70.0, "rumble": 1.0, "seconds": 6.0}, -60.0)
	_heart = sound.bed("heartbeat", {}, -60.0)
	sound.oneshot("creak", {"freq": 140.0}, 25.0, 60.0, 20.0, "[palm trunks creak in the wind]", -24.0)


func on_player_ready() -> void:
	if SessionState.is_qa():
		return
	if TransitionService.pending_arrival == "from_L046":
		Overlay.subtitle("[the ground gets lighter with every step - then there is sand, palms and an evening sky full of floating isles]", 5.0)
	else:
		Overlay.subtitle("[evening, and it stays evening. Isles float in every direction, palms crowded in their middles]", 5.0)


func level_process(delta: float) -> void:
	if not SessionState.is_qa():
		_drift(delta)
		_rain(delta)
	if player == null or not is_instance_valid(player):
		return
	var p := player.global_position
	_barrier_update(delta, p)
	if p.y < -30.0 and not _said.has("fall"):
		_said["fall"] = true
		if not SessionState.is_qa():
			Overlay.subtitle("[you are falling. The wind roars up out of the abyss]", 4.0)
	elif p.y > -5.0:
		_said.erase("fall")
	if p.y < -120.0 and not player.dead:
		player.hurt(1000.0, "lost to the abyss beneath the isles")


# --------------------------------------------------------------- QA

func _shots() -> void:
	var th: Vector3 = V.treehouse_tops[0]
	add_shot("village_from_treehouse", th + Vector3(0, 1.62, 0), Vector3(-36.0, 3.0, -8.0), {"flashlight": false})
	add_shot("isle_chain", Vector3(64.0, IS.h_local(main, 64.0, 2.0) + 1.7, 2.0), Vector3(200.0, 6.0, -2.0), {"flashlight": false})
	add_shot("longhouse", Vector3(-36.0, IS.h_local(main, -36.0, -8.0) + 1.62, -17.5), Vector3(-36.0, IS.h_local(main, -36.0, -8.0) + 1.3, 4.0), {"flashlight": false})
	var o: Vector3 = outer["c"]
	add_shot("barrier_rim", o + Vector3(-9.0, 2.6, -4.0), o + Vector3(80.0, 6.0, 8.0), {"flashlight": false})
	add_shot("main_isle_from_north", Vector3(40.0, 9.0 + 1.62, -88.0), Vector3(0.0, -6.0, 0.0), {"flashlight": false})
	add_shot("grove", Vector3(-14.0, IS.h_local(main, -14.0, 12.0) + 1.62, 12.0), Vector3(10.0, 9.0, -6.0), {"flashlight": false})


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "gravity is about 15 % of Earth's away from the Barrier", "ok": absf(G_LOW - 9.8 * 0.15) < 0.05 and rules["gravity"] == G_LOW})
	out.append({"what": "fifteen walkable isles and dozens of distant ones", "ok": walkable.size() == 15 and decor_count >= 40, "detail": [walkable.size(), decor_count]})
	out.append({"what": "hundreds of palms clustered on the isles", "ok": palm_total >= 400, "detail": palm_total})
	out.append({"what": "settlement: three longhouses, two tree houses, a public house", "ok": V.longhouse_in.size() == 3 and V.treehouse_tops.size() == 2 and V.coconut_piles.size() >= 1})
	var sp: Dictionary = walkable[2]
	var before: Vector3 = (sp["body"] as Node3D).position
	var keep := drift_t
	_drift(40.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var moved: float = (sp["body"] as Node3D).position.distance_to(before)
	drift_t = keep
	(sp["body"] as Node3D).position = before
	await get_tree().physics_frame
	await get_tree().physics_frame
	out.append({"what": "isles drift slowly (never fixed)", "ok": moved > 0.2 and (sp["body"] as Node3D).position.distance_to(before) < 0.05, "detail": moved})
	set_rain(1.0)
	var raining: bool = rain_mi.visible and sun.light_energy < 0.6
	set_rain(0.0)
	out.append({"what": "rain showers darken the sky and fall around you", "ok": raining and not rain_mi.visible})
	var g_far := 0.0
	if player and is_instance_valid(player):
		_barrier_update(0.0, Vector3((outer["c"] as Vector3).x + 6.0, 0, 0))
		g_far = player.gravity
		_barrier_update(0.0, Vector3(0, 0, 0))
	out.append({"what": "gravity grows stronger at the Barrier", "ok": g_far > 4.0, "detail": g_far})
	return out
