extends LevelBase
## Level 0.3 — "The Icy Rooms" (Backrooms Wiki rev 32, accessed 2026-11-04;
## cite: CursedSliver, CC BY-SA 3.0). Dossier: docs/canon/levels/L000_3.md.
##
## DESIGN PLAN
## Space: a sub-section of Level 0 that is "nearly identical to Level 0" but iced
##   everywhere and bitterly cold. Seeded 24 m chunks of Level 0 floor plan (3 m
##   grid, rooms, hallways, doorways, drop ceiling, fluorescent panels) stream
##   around the player; the playable world is a finite streaming window.
##   Original frozen state (page, remodel summary 1): frost-laced carpet coarse as
##   gravel, bare walls with scraps of pale frozen wallpaper (some peel off and
##   drift down), frostbitten wall stains, and gigantic ice cubes in rooms that
##   barely contain them (0.75 m margins). Near the camp the crew's remodel shows:
##   new wool carpet and new wallpaper, both failing again, blowtorched cube
##   remains and refrozen meltwater sheets.
## Anchors: the abandoned Task Force 104-CX camp (chunk 0,0: desk, laptop email
##   thread, clipboard assignment, binder of progress reports, generator and tripod
##   work lights, carpet/wallpaper stock, the crate with two blowtorches that no
##   longer light) and the duct hall (chunk -1,0): a two-storey Level 0 hall with a
##   gallery reached by a stair, the centuries-old rusty ducts crossing the void,
##   one cube crammed into the gallery's end room, the crew's last note.
## Second heights: the duct hall gallery (+3.24 m) and sunken rooms (three risers
##   down) whose floor is a sheet of ice.
## Signature mechanic (SOURCE): vents pump frosty mist (particles, hiss, the air
##   thickens and greys as you near one). You can wedge a board over a wall vent;
##   it holds for a while, then the mist forces it off (page: "We tried to block it
##   off, but it didn't work too well"). The old ducts "clip around": sections jolt
##   out of line and snap back with a clank. Frozen wallpaper scraps let go.
## Exits: none (page states none). Entities: none; the missing task forces are
##   implied only by the empty camp. No cold-damage mechanic (page: only "so damn
##   cold"). Light: cold fluorescent panels, the crew's warm work lights.

const Geo := preload("res://levels/L000_3/L000_3_geo.gd")
const Dress := preload("res://levels/L000_3/L000_3_dress.gd")
const SPAWN := Vector3(12.0, 0.05, 16.4)
const FOG_BASE := 0.010

var geo
var dress
var world: ChunkWorld
var vents: Array = []        # {pos, n, ps, board, blocked, t, snd, wall}
var ducts: Array = []        # {node, base}
var scraps: Array = []       # MeshInstance3D
var metas: Dictionary = {}   # chunk -> meta
var notes_staged := 0
var _duct_t := 6.0
var _scrap_t := 20.0
var _mist := 0.0
var _clip_live: Dictionary = {}
var _cold_told := false


func build() -> void:
	rules["reverb_room"] = 0.34
	rules["reverb_wet"] = 0.12
	rules["view_distance"] = 90.0
	rules["kill_y"] = -30.0
	indoor_env(Color(0.8, 0.86, 0.95), 0.09, Color(0.11, 0.13, 0.16), FOG_BASE)
	environment.background_color = Color(0.03, 0.035, 0.045)
	environment.tonemap_exposure = 0.88
	environment.glow_intensity = 0.22
	environment.glow_hdr_threshold = 1.0
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.82
	environment.adjustment_contrast = 1.07
	_materials()
	lights.setup(14, 1)
	lights.max_distance = 26.0
	geo = Geo.new(self)
	dress = Dress.new(self)
	world = ChunkWorld.new()
	world.name = "Chunks"
	world.chunk_size = Geo.CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _build_chunk
	add_child(world)
	world.chunk_unloaded.connect(_on_unload)
	add_arrival("start", SPAWN, 0.0)
	world.build_around(SPAWN, 2)
	_documents()
	add_landmark("Task Force 104-CX camp", Vector3(12, 0, 12))
	add_landmark("Duct hall (gallery)", Vector3(-12, Geo.UP, 2))
	sound.bed("room_tone", {"cutoff": 210.0, "rumble": 0.3}, -24.0)
	sound.bed("fluorescent_hum", {"base": 60.0, "rasp": 0.18}, -31.0)
	sound.bed("wind", {}, -38.0)
	sound.emitter("transformer", dress.gen_pos + Vector3(0, 0.4, 0), {"base": 48.0}, -17.0, 9.0)
	sound.oneshot("creak", {"freq": 52.0}, 26.0, 70.0, 10.0, "[ice creaks somewhere inside the walls]", -14.0)
	_shots()


func _materials() -> void:
	var m := func(n: String, base: String, x: Dictionary) -> void:
		MatLib.define(n, x, base)
	var frost := Color(0.84, 0.88, 0.92)
	m.call("l03_wall_frozen", "l0_wallpaper", {"albedo_a": Color(0.66, 0.63, 0.5), "albedo_b": Color(0.6, 0.58, 0.47),
		"pattern_color": Color(0.56, 0.53, 0.42), "pattern_strength": 0.4, "peel_amount": 0.42, "peel_color": Color(0.5, 0.53, 0.55),
		"stain_amount": 0.4, "stain_color": Color(0.36, 0.39, 0.44), "stain_scale": 0.9, "grime_height": 0.5, "grime_color": frost,
		"roughness_a": 0.5, "roughness_b": 0.8, "bump_strength": 0.9, "noise_scale": 1.4})
	m.call("l03_wall_new", "l0_wallpaper", {"albedo_a": Color(0.74, 0.7, 0.55), "albedo_b": Color(0.68, 0.64, 0.5), "pattern": 10,
		"pattern_scale": Vector2(0.25, 0.32), "pattern_color": Color(0.64, 0.6, 0.46), "pattern_strength": 0.45,
		"peel_amount": 0.22, "peel_color": Color(0.52, 0.55, 0.57), "stain_amount": 0.2, "stain_color": Color(0.6, 0.62, 0.64),
		"grime_height": 0.4, "grime_color": frost, "roughness_a": 0.6})
	m.call("l03_carpet_frost", "l0_carpet", {"albedo_a": Color(0.42, 0.38, 0.28), "albedo_b": Color(0.34, 0.31, 0.23), "wetness": 0.35,
		"stain_amount": 0.42, "stain_color": Color(0.7, 0.74, 0.78), "stain_scale": 0.9, "roughness_a": 0.6, "roughness_b": 0.95,
		"noise_scale": 2.6, "bump_strength": 1.8})
	m.call("l03_carpet_wool", "l0_carpet", {"albedo_a": Color(0.5, 0.45, 0.36), "albedo_b": Color(0.44, 0.4, 0.32), "wetness": 0.1,
		"stain_amount": 0.3, "stain_color": frost, "stain_scale": 0.6, "noise_scale": 0.6, "bump_strength": 0.5})
	m.call("l03_carpet_wool_new", "l0_carpet", {"albedo_a": Color(0.44, 0.38, 0.3), "albedo_b": Color(0.4, 0.34, 0.27), "wetness": 0.0,
		"stain_amount": 0.15, "stain_color": frost, "noise_scale": 0.5, "bump_strength": 0.4})
	m.call("l03_ceiling", "l0_ceiling", {"albedo_a": Color(0.78, 0.8, 0.79), "albedo_b": Color(0.72, 0.74, 0.73), "stain_amount": 0.4,
		"stain_color": Color(0.9, 0.92, 0.95), "grout_color": Color(0.62, 0.64, 0.64)})
	m.call("l03_plenum", "concrete_dark", {"albedo_a": Color(0.18, 0.18, 0.19), "albedo_b": Color(0.12, 0.12, 0.13), "stain_amount": 0.4, "stain_color": Color(0.5, 0.52, 0.55)})
	m.call("l03_rust", "rust", {"albedo_a": Color(0.4, 0.3, 0.24), "albedo_b": Color(0.3, 0.2, 0.14), "metallic_value": 0.6,
		"roughness_a": 0.55, "stain_amount": 0.35, "stain_color": frost, "stain_scale": 0.8})
	m.call("l03_rust_dark", "rust", {"albedo_a": Color(0.3, 0.17, 0.1), "albedo_b": Color(0.2, 0.12, 0.08), "stain_amount": 0.25, "stain_color": frost})
	m.call("l03_grille", "metal", {"albedo_a": Color(0.55, 0.56, 0.57), "albedo_b": Color(0.45, 0.46, 0.47), "pattern": 1,
		"pattern_scale": Vector2(0.04, 0.04), "grout_width": 0.3, "grout_color": Color(0.04, 0.04, 0.05), "stain_amount": 0.5, "stain_color": frost})
	m.call("l03_frame", "metal", {"albedo_a": Color(0.8, 0.8, 0.79), "albedo_b": Color(0.74, 0.74, 0.73), "metallic_value": 0.2})
	m.call("l03_metal", "metal", {})
	m.call("l03_snow", "plaster", {"albedo_a": Color(0.88, 0.91, 0.95), "albedo_b": Color(0.8, 0.85, 0.9), "noise_scale": 3.0, "bump_strength": 1.2, "roughness_a": 0.6})
	m.call("l03_icesheet", "pool_tile", {"albedo_a": Color(0.42, 0.52, 0.6), "albedo_b": Color(0.36, 0.46, 0.55), "pattern": 0,
		"roughness_a": 0.04, "roughness_b": 0.15, "noise_scale": 0.7, "bump_strength": 0.3, "stain_amount": 0.3, "stain_color": Color(0.85, 0.9, 0.95)})
	m.call("l03_scrap", "l0_wallpaper", {"albedo_a": Color(0.78, 0.75, 0.6), "albedo_b": Color(0.72, 0.69, 0.55), "pattern_strength": 0.3,
		"stain_amount": 0.4, "stain_color": frost, "grime_height": 0.0})
	m.call("l03_roll_wool", "l0_carpet", {"albedo_a": Color(0.68, 0.64, 0.56), "albedo_b": Color(0.62, 0.58, 0.5), "wetness": 0.0, "stain_amount": 0.2, "stain_color": frost})
	m.call("l03_roll_paper", "l0_wallpaper", {"albedo_a": Color(0.78, 0.74, 0.58), "pattern": 10, "pattern_scale": Vector2(0.1, 0.1), "grime_height": 0.0})
	m.call("l03_cardboard", "plaster", {"albedo_a": Color(0.55, 0.42, 0.27), "albedo_b": Color(0.48, 0.36, 0.22), "noise_scale": 4.0, "stain_amount": 0.3, "stain_color": frost})
	m.call("l03_bucket", "plaster", {"albedo_a": Color(0.86, 0.86, 0.84), "albedo_b": Color(0.8, 0.8, 0.78), "roughness_a": 0.35})
	m.call("l03_paste", "plaster", {"albedo_a": Color(0.82, 0.86, 0.9), "albedo_b": Color(0.76, 0.8, 0.86), "roughness_a": 0.1})
	m.call("l03_torch", "metal", {"albedo_a": Color(0.62, 0.1, 0.08), "albedo_b": Color(0.5, 0.08, 0.06), "metallic_value": 0.5, "stain_amount": 0.3, "stain_color": frost})
	m.call("l03_brass", "metal", {"albedo_a": Color(0.7, 0.58, 0.3), "albedo_b": Color(0.6, 0.48, 0.24), "metallic_value": 0.9, "roughness_a": 0.3})
	m.call("l03_cable", "plaster", {"albedo_a": Color(0.06, 0.06, 0.06), "albedo_b": Color(0.05, 0.05, 0.05)})
	m.call("l03_dropcloth", "plaster", {"albedo_a": Color(0.42, 0.41, 0.38), "albedo_b": Color(0.36, 0.35, 0.33), "noise_scale": 2.0, "stain_amount": 0.45, "stain_color": Color(0.62, 0.66, 0.7)})
	m.call("l03_board", "wood_floor", {"albedo_a": Color(0.62, 0.48, 0.3), "albedo_b": Color(0.5, 0.37, 0.22), "pattern": 0, "noise_scale": 7.0})
	var ice := StandardMaterial3D.new()
	ice.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ice.albedo_color = Color(0.78, 0.9, 0.98, 0.8)
	ice.albedo_texture = _noise_tex(false)
	ice.normal_enabled = true
	ice.normal_texture = _noise_tex(true)
	ice.normal_scale = 0.6
	ice.uv1_triplanar = true
	ice.uv1_scale = Vector3(0.45, 0.45, 0.45)
	ice.roughness = 0.12
	ice.metallic_specular = 0.9
	ice.rim_enabled = true
	ice.rim = 0.5
	ice.rim_tint = 0.5
	ice.emission_enabled = true
	ice.emission = Color(0.2, 0.32, 0.42)
	ice.emission_energy_multiplier = 0.3
	MatLib.register("l03_ice", ice)
	var crack := StandardMaterial3D.new()
	crack.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	crack.albedo_color = Color(0.92, 0.96, 1.0, 0.2)
	crack.cull_mode = BaseMaterial3D.CULL_DISABLED
	crack.roughness = 0.3
	MatLib.register("l03_ice_crack", crack)
	MatLib.register("l03_panel", MatLib.panel(Color(0.9, 0.95, 1.0), 2.2))
	MatLib.register("l03_panel_dim", MatLib.panel(Color(0.78, 0.86, 0.92), 0.9))
	MatLib.register("l03_panel_dead", MatLib.panel(Color(0.16, 0.17, 0.18), 0.0, 0.0, 100.0))


## Cellular noise for ice: frozen-in fracture lines and frost (generated, no files).
func _noise_tex(normal: bool) -> NoiseTexture2D:
	var fn := FastNoiseLite.new()
	fn.noise_type = FastNoiseLite.TYPE_CELLULAR
	fn.frequency = 0.035
	fn.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_SUB
	fn.fractal_type = FastNoiseLite.FRACTAL_FBM
	fn.fractal_octaves = 3
	var t := NoiseTexture2D.new()
	t.width = 256
	t.height = 256
	t.seamless = true
	t.noise = fn
	if normal:
		t.as_normal_map = true
		t.bump_strength = 6.0
	else:
		var g := Gradient.new()
		g.set_color(0, Color(0.62, 0.78, 0.9))
		g.set_color(1, Color(0.97, 0.99, 1.0))
		t.color_ramp = g
	return t


# ------------------------------------------------------------------ chunks

func _build_chunk(cx: int, cz: int, _v: int, node: Node3D) -> Dictionary:
	var meta: Dictionary = geo.build_chunk(cx, cz, node)
	var grp := "%d,%d" % [cx, cz]
	var r := RandomNumberGenerator.new()
	r.seed = hash([level_seed, cx, cz, "dress"])
	dress.doors = meta["doors"]
	if cx == 0 and cz == 0:
		dress.camp(node, grp)
	elif meta["hall"]:
		dress.hall(node, cx * Geo.CS, cz * Geo.CS, grp)
	else:
		dress.traces(node, meta["rooms"], r, grp)
	for v in meta["vents"]:
		_vent(node, v)
	for d in meta["ducts"]:
		ducts.append({"node": d, "base": (d as Node3D).position})
	for s in meta["scraps"]:
		scraps.append(s)
	metas[Vector2i(cx, cz)] = meta
	return meta


func _on_unload(k: Vector2i) -> void:
	lights.remove_group("%d,%d" % [k.x, k.y])
	metas.erase(k)
	vents = vents.filter(func(v): return is_instance_valid(v["ps"]))
	ducts = ducts.filter(func(d): return is_instance_valid(d["node"]))
	scraps = scraps.filter(func(s): return is_instance_valid(s))


## A vent that pumps frosty mist: sinking particle plume, hiss, and (for wall
## vents) a board you can wedge over it until the mist pushes it off.
func _vent(node: Node3D, v: Dictionary) -> void:
	var pos: Vector3 = v["pos"]
	var n: Vector3 = v["n"]
	var wall: bool = absf(n.y) < 0.5
	var ps := CPUParticles3D.new()
	ps.amount = 26 if wall else 30
	ps.lifetime = 9.0 if wall else 11.0
	ps.preprocess = 9.0
	ps.direction = n
	ps.spread = 22.0
	ps.initial_velocity_min = 0.25
	ps.initial_velocity_max = 0.5
	ps.gravity = Vector3(0, -0.045 if wall else -0.03, 0)
	ps.damping_min = 0.04
	ps.damping_max = 0.1
	ps.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ps.emission_box_extents = Vector3(0.22, 0.08, 0.22)
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.35))
	curve.add_point(Vector2(1, 1.0))
	ps.scale_amount_curve = curve
	ps.scale_amount_min = 0.9
	ps.scale_amount_max = 1.8
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0.0))
	grad.set_color(1, Color(1, 1, 1, 0.0))
	grad.add_point(0.15, Color(1, 1, 1, 1.0))
	grad.add_point(0.7, Color(1, 1, 1, 0.7))
	ps.color_ramp = grad
	var q := QuadMesh.new()
	q.size = Vector2(1.1, 1.1)
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(0.86, 0.92, 0.98, 0.07)
	var soft := GradientTexture2D.new()
	soft.fill = GradientTexture2D.FILL_RADIAL
	soft.fill_from = Vector2(0.5, 0.5)
	soft.fill_to = Vector2(1.0, 0.5)
	var sg := Gradient.new()
	sg.set_color(0, Color(1, 1, 1, 1))
	sg.set_color(1, Color(1, 1, 1, 0))
	soft.gradient = sg
	mat.albedo_texture = soft
	q.material = mat
	ps.mesh = q
	ps.position = pos + n * 0.12
	ps.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(ps)
	ps.emitting = true
	var snd := sound.emitter("wind", pos, {}, -17.0, 9.0)
	snd.reparent(node)
	var rec := {"pos": pos, "n": n, "rect": v.get("rect", Rect2()), "ps": ps, "board": null, "blocked": false, "t": 0.0, "snd": snd, "wall": wall}
	vents.append(rec)
	if wall:
		make_interactable(pos + n * 0.25, Vector3(0.9, 0.7, 0.9), "Wedge a board over the vent", _block.bind(rec), node)


func _block(rec: Dictionary) -> void:
	if rec["blocked"]:
		Overlay.toast("The board is holding. For now. Frost is already creeping round its edges.", 3.0)
		return
	rec["blocked"] = true
	rec["t"] = rng.randf_range(16.0, 32.0)
	(rec["ps"] as CPUParticles3D).emitting = false
	var b: MeshInstance3D = rec["board"]
	if b == null or not is_instance_valid(b):
		b = MeshInstance3D.new()
		var bm := BoxMesh.new()
		var n: Vector3 = rec["n"]
		bm.size = Vector3(0.8, 0.45, 0.025) if absf(n.z) > 0.5 else Vector3(0.025, 0.45, 0.8)
		b.mesh = bm
		b.material_override = MatLib.get_mat("l03_board")
		(rec["ps"] as Node3D).get_parent().add_child(b)
		rec["board"] = b
	b.position = rec["pos"] + (rec["n"] as Vector3) * 0.03
	b.rotation = Vector3.ZERO
	(rec["snd"] as AudioStreamPlayer3D).volume_db = -32.0
	sound.play_at("knock", {"hits": 2}, rec["pos"], -8.0)
	if not SessionState.is_qa():
		Overlay.toast("You wedge a loose board over the grille. The hiss drops to a mutter.", 3.0)


func _unblock(rec: Dictionary, instant: bool = false) -> void:
	rec["blocked"] = false
	(rec["ps"] as CPUParticles3D).emitting = true
	(rec["snd"] as AudioStreamPlayer3D).volume_db = -17.0
	var b: MeshInstance3D = rec["board"]
	if b and is_instance_valid(b):
		var floor_p: Vector3 = Vector3(rec["pos"].x, 0.03, rec["pos"].z) + (rec["n"] as Vector3) * 0.5
		if instant:
			b.position = floor_p
			b.rotation = Vector3(PI * 0.5, rng.randf() * 0.6, 0)
		else:
			var tw := create_tween()
			tw.tween_property(b, "position", floor_p, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.parallel().tween_property(b, "rotation", Vector3(PI * 0.5, rng.randf() * 0.6, 0), 0.6)
			tw.tween_callback(func(): sound.play_at("knock", {"hits": 1}, floor_p, -6.0))
	if not instant and not SessionState.is_qa() and player and player.global_position.distance_to(rec["pos"]) < 16.0:
		Overlay.subtitle("[the board over the vent bangs loose; frosty mist pours out again]", 3.5)


# ------------------------------------------------------------------ documents

func _documents() -> void:
	var d: Vector3 = dress.desk
	var a := add_note("L000_3_assignment", "Clipboard: remodelling assignment",
		"[i]A typed assignment sheet, paraphrased.[/i]\n\nTarget: Level 0.3, Sector A891-01. Objective: defrosting and a Class-B remodel. Task Force 104-CX: Planes, Chris, Havec, Evie. Start 09-02-2019, due 12-31-2019. Extra equipment: two blowtorches.\n\nMajor Took's covering note reminds the crew of 'that catastrophe' when Level 0 was remodelled and expects clean, pristine, comfortably warm rooms this time. They are to work with what they were given.",
		d + Vector3(0.05, 0.81, 0.15))
	var b := add_note("L000_3_reports", "Binder: progress reports",
		"[i]Three upbeat progress summaries in the binder, paraphrased. Lines have been struck through.[/i]\n\n1. The frost-crusted carpet, coarse as gravel, is gone. The bare walls with their scraps of frozen wallpaper are covered. The blowtorches took care of the giant ice cubes. Havec is pumping out the gas.\n\n2. Softer wool carpet is down, the walls are polished, new wallpaper is up. The blowtorch can't be used any more. The air vents keep pumping out frosty mist that ruins [s]everything[/s] some things. We tried to block it off; it didn't work well.\n\n3. Just polishing the centuries-old air ducts. They clip around a lot and are unstable. [s]The carpets are barely holding on.[/s] Awesome! [s]The wallpaper is peeling off agai[/s] Fabulous!",
		d + Vector3(-0.85, 0.81, -0.2))
	var c := add_note("L000_3_emails", "Laptop: email thread",
		"[i]The laptop is still on. Its battery icon is red. The thread, paraphrased:[/i]\n\n10-29-2019, Planes: there is a lot more ice than we thought; can we have backup? Took sends Task Force 105-CX.\n11-30-2019, Planes: it has been a month; more workers please. Took suspects slacking but agrees to send another task force. Planes insists they are only working on the vents and the mist.\n12-29-2019, Took: due in two days. Planes: almost done, can we have another task force? Took sends 108-CX.\n\n01-01-2020, Major Took: I have arrived at the remodelled location.\n\"Where are you?\"\nHe asks what happened to Task Force 105-CX, 107-CX and 108-CX.\n\n[i]There is no reply.[/i]",
		d + Vector3(-0.45, 0.83, 0.05), Vector3(0.5, 0.25, 0.4), false)
	var hall_note := Vector3(-24.0 + 14.5, Geo.UP + 0.02, 2.0)
	var e := add_note("L000_3_final", "Dropped sheet: final description",
		"[i]A sheet torn from the binder, face down on the gallery carpet. The handwriting slides. Paraphrased.[/i]\n\nI think we have successfully renovated Level 0.3. We replaced the carpets. We replaced the wallpapers. I guess we improved the lightings. And the vents, I mean, we also got rid of the giant ice cubes, maybe, and I guess we [s]the rooms[/s] are done f\n\n[i]The line ends there.[/i]",
		hall_note)
	notes_staged = 4
	for it in [a, b, c, e]:
		(it as Interactable).used.connect(func(_p): _cold_line())
	for t in dress.torches:
		add_interactable(t, Vector3(0.9, 0.5, 0.7), "Try one of the blowtorches", _torch)


func _torch() -> void:
	sound.play_at("crackle", {}, dress.torches[0], -12.0)
	Overlay.toast("The igniter clicks. Nothing. You try the second one: the valve is frozen solid. The crew could not use these any more either.", 4.0)


func _cold_line() -> void:
	if not _cold_told and not SessionState.is_qa():
		_cold_told = true
		Overlay.subtitle("[the cold gets into your fingers as you read]", 3.0)


# ------------------------------------------------------------------ per frame

func on_player_ready() -> void:
	world.target = player
	if not SessionState.is_qa():
		Overlay.subtitle("[It is bitterly cold. Frost crunches under every step.]", 4.0)


func level_process(delta: float) -> void:
	if player == null:
		return
	var pp := player.global_position
	# vents: blocks give way; mist thickens the air near an open vent
	var near := 0.0
	for v in vents:
		if not is_instance_valid(v["ps"]):
			continue
		if v["blocked"]:
			v["t"] -= delta
			if v["t"] <= 0.0:
				_unblock(v)
			continue
		var vp: Vector3 = v["pos"]
		var d := Vector2(vp.x - pp.x, vp.z - pp.z).length()
		near = maxf(near, clampf(1.0 - (d - 1.0) / 7.0, 0.0, 1.0) * (1.0 if v["wall"] else 0.7))
	_mist = lerpf(_mist, near, clampf(delta * 0.7, 0.0, 1.0))
	environment.fog_density = FOG_BASE + _mist * 0.022
	environment.fog_light_color = Color(0.11, 0.13, 0.16).lerp(Color(0.3, 0.34, 0.38), _mist)
	if not SessionState.is_qa():
		Overlay.set_screen_effect("desaturate", _mist * 0.3)
	# ducts clip around
	_duct_t -= delta
	if _duct_t <= 0.0:
		_duct_t = rng.randf_range(5.0, 13.0)
		_clip_near(pp)
	# frozen wallpaper scraps let go
	_scrap_t -= delta
	if _scrap_t <= 0.0:
		_scrap_t = rng.randf_range(18.0, 45.0)
		_drop_scrap(pp)


func _clip_near(pp: Vector3, force: bool = false) -> Node3D:
	var cand: Array = []
	for d in ducts:
		if is_instance_valid(d["node"]) and not _clip_live.has(d["node"]) and ((d["node"] as Node3D).global_position.distance_to(pp) < 20.0 or force):
			cand.append(d)
	if cand.is_empty():
		return null
	var d: Dictionary = cand[rng.randi() % cand.size()]
	var nd: Node3D = d["node"]
	var base: Vector3 = d["base"]
	var off := Vector3(rng.randf_range(-0.45, 0.45), rng.randf_range(-0.22, 0.12), rng.randf_range(-0.45, 0.45))
	nd.position = base + off
	_clip_live[nd] = true
	sound.play_at("pipe_clank", {"f": rng.randf_range(90.0, 160.0)}, nd.global_position, -7.0,
		"" if SessionState.is_qa() else "[an old duct clanks and jolts out of line]")
	var hold := rng.randf_range(0.25, 1.1)
	get_tree().create_timer(hold).timeout.connect(_clip_back.bind(nd, base, off))
	return nd


func _clip_back(nd: Node3D, base: Vector3, off: Vector3) -> void:
	if is_instance_valid(nd):
		nd.position = base - off * 0.3
	get_tree().create_timer(0.12).timeout.connect(_clip_home.bind(nd, base))


func _clip_home(nd: Node3D, base: Vector3) -> void:
	if is_instance_valid(nd):
		nd.position = base
	_clip_live.erase(nd)


func _drop_scrap(pp: Vector3) -> void:
	for s in scraps:
		if not is_instance_valid(s):
			continue
		var mi := s as MeshInstance3D
		var d := mi.global_position.distance_to(pp)
		if d < 3.0 or d > 11.0:
			continue
		scraps.erase(s)
		var to := mi.global_position + mi.global_transform.basis.z * 0.5
		to.y = 0.015
		var tw := create_tween()
		tw.tween_property(mi, "global_position", to, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(mi, "rotation", Vector3(-PI * 0.5, mi.rotation.y + rng.randf_range(-1.0, 1.0), 0), 2.2)
		if not SessionState.is_qa():
			Overlay.subtitle("[a scrap of frozen wallpaper tears loose and drifts down]", 3.0)
		return


# ------------------------------------------------------------------ QA

func _shots() -> void:
	add_shot("camp", Vector3(15.2, 1.62, 17.2), Vector3(10.0, 0.9, 9.0))
	add_shot("camp_work", Vector3(8.5, 1.62, 16.2), Vector3(16.5, 0.8, 9.5))
	add_shot("duct_hall", Vector3(-4.8, Geo.UP + 1.62, 12.5), Vector3(-16.5, 0.2, 10.5))
	add_shot("duct_hall_floor", Vector3(-11.0, 1.62, 17.0), Vector3(-12.5, 5.0, 6.0))


func _find_room(kind: String) -> Dictionary:
	for rr in range(1, 4):
		for dz in range(-rr, rr + 1):
			for dx in range(-rr, rr + 1):
				if maxi(absi(dx), absi(dz)) != rr:
					continue
				var k := Vector2i(dx, dz)
				if not metas.has(k):
					world.build_around(Vector3((dx + 0.5) * Geo.CS, 0, (dz + 0.5) * Geo.CS), 0)
				var m: Dictionary = metas.get(k, {})
				for rm in m.get("rooms", []):
					if rm["kind"] == kind:
						return {"chunk": k, "rect": rm["rect"], "meta": m}
	return {}


func qa_capture_plan() -> Array:
	var plan: Array = qa_shots.duplicate()
	var ice := _find_room("ice")
	if not ice.is_empty():
		var wr: Rect2 = ice["rect"]
		var o := Vector3(wr.position.x + 0.38, 1.5, wr.end.y - 0.38)
		plan.append({"name": "ice_cube_room", "pos": o, "target": Vector3(wr.position.x + 0.6, 1.25, wr.position.y + 0.2),
			"prepare": func(): world.build_around(o, 1)})
		for dp in ice["meta"]["doors"]:
			var dv: Vector3 = dp
			if not wr.grow(0.2).has_point(Vector2(dv.x, dv.z)) or wr.grow(-0.2).has_point(Vector2(dv.x, dv.z)):
				continue
			var out := Vector3(dv.x - wr.get_center().x, 0, dv.z - wr.get_center().y)
			out = Vector3(signf(out.x), 0, 0) if absf(dv.x - wr.position.x) < 0.3 or absf(dv.x - wr.end.x) < 0.3 else Vector3(0, 0, signf(out.z))
			var o2 := dv + out * 2.2 + Vector3(0, 1.62, 0)
			plan.append({"name": "ice_cube_doorway", "pos": o2, "target": Vector3(wr.get_center().x, 1.0, wr.get_center().y),
				"prepare": func(): world.build_around(o2, 1)})
			break
	var pit := _find_room("pit")
	if not pit.is_empty():
		var pr: Rect2 = pit["rect"]
		var o3 := Vector3(pr.position.x + 0.6, 1.62, pr.position.y + 0.6)
		plan.append({"name": "sunken_room", "pos": o3, "target": Vector3(pr.end.x - 1.5, -0.4, pr.end.y - 1.5),
			"prepare": func(): world.build_around(o3, 1)})
	var duct := _find_room("duct")
	if not duct.is_empty():
		var dr: Rect2 = duct["rect"]
		var o4 := Vector3(dr.position.x + 0.7, 1.62, dr.position.y + 0.7)
		plan.append({"name": "duct_room", "pos": o4, "target": Vector3(dr.end.x - 1.0, 2.6, dr.end.y - 1.0),
			"prepare": func(): world.build_around(o4, 1)})
	for v in vents:
		if v["wall"] and is_instance_valid(v["ps"]):
			var vp: Vector3 = v["pos"]
			var o5 := vp + (v["n"] as Vector3) * 3.4
			var vr: Rect2 = v.get("rect", Rect2(o5.x - 1, o5.z - 1, 2, 2))
			vr = vr.grow(-0.45)
			o5 = Vector3(clampf(o5.x, vr.position.x, vr.end.x), 1.62, clampf(o5.z, vr.position.y, vr.end.y))
			plan.append({"name": "vent_mist", "pos": o5, "target": vp + Vector3(0, -0.9, 0),
				"prepare": func(): world.build_around(o5, 1)})
			break
	return plan


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "no exits (page states none)", "ok": exits.is_empty()})
	out.append({"what": "four recovered documents staged", "ok": notes_staged == 4})
	out.append({"what": "camp dressed with placed models", "ok": dress.props >= 40, "detail": dress.props})
	var cubes := 0
	for k in metas.keys():
		cubes += (metas[k]["ice"] as Array).size()
	out.append({"what": "giant ice cubes in the streamed rooms", "ok": cubes >= 3, "detail": cubes})
	# second walkable height: the duct hall gallery
	var space := get_world_3d().direct_space_state
	var g: Vector3 = metas.get(Geo.HALL, {}).get("gallery", Vector3(-7.5, Geo.UP, 3.0))
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(g + Vector3(0, 1.5, 0), g + Vector3(0, -1.0, 0), 1))
	out.append({"what": "duct hall gallery is a walkable second storey", "ok": not hit.is_empty() and absf(hit["position"].y - Geo.UP) < 0.1, "detail": hit.get("position", null)})
	# vents: block, then the mist forces the board off
	var wv: Dictionary = {}
	for v in vents:
		if v["wall"] and is_instance_valid(v["ps"]):
			wv = v
			break
	out.append({"what": "a wall vent pumps mist", "ok": not wv.is_empty() and (wv["ps"] as CPUParticles3D).emitting})
	if not wv.is_empty():
		_block(wv)
		var held: bool = wv["blocked"] and not (wv["ps"] as CPUParticles3D).emitting
		wv["t"] = 0.01
		for i in 3:
			await get_tree().process_frame
		out.append({"what": "a board stops the mist, then the mist forces it off", "ok": held and not wv["blocked"] and (wv["ps"] as CPUParticles3D).emitting})
	var nd := _clip_near(player.global_position, true)
	var moved := nd != null and nd.position.distance_to(_base_of(nd)) > 0.01
	out.append({"what": "an old duct section clips out of line", "ok": moved})
	await get_tree().create_timer(1.6).timeout
	out.append({"what": "and snaps back", "ok": nd != null and is_instance_valid(nd) and nd.position.distance_to(_base_of(nd)) < 0.01})
	return out


func _base_of(nd: Node3D) -> Vector3:
	for d in ducts:
		if d["node"] == nd:
			return d["base"]
	return Vector3.INF
