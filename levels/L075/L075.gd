extends LevelBase
## Level 75 — Liminality / The Sandrooms.
## Canon: docs/canon/levels/L075.md (Br Miller, CC BY-SA 3.0).
## A source-constrained 6x5 room-and-corridor maze. Floors stay covered in
## inert sand, footprints do not disappear, all conventional lights are dead.
## No entities, consumables, settlements, electrical power or damage mechanics.
## This scene is an IN_DEVELOPMENT candidate until the Godot QA suite passes.

const NX := 6
const NZ := 5
const SPAN := 10.0
const HEIGHT := 4.3
const START_CELL := Vector2i(0, 2)
const EXIT_CELL := Vector2i(5, 2)
const PRINT_LIMIT := 512

var carved := {}
var exit_trigger: ExitTrigger
var prints: MultiMeshInstance3D
var foot_count := 0
var last_step := Vector3(1.0e6, 0, 0)
var is_fixture := false


func build() -> void:
	is_fixture = SessionState.is_qa()
	rules["flashlight"] = "none"
	rules["reverb_room"] = 0.62
	rules["reverb_wet"] = 0.02
	rules["view_distance"] = 150.0
	indoor_env(Color(0.94, 0.87, 0.71), 0.46, Color(0.76, 0.75, 0.64), 0.0015)
	environment.tonemap_exposure = 1.02
	environment.glow_intensity = 0.15
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.88
	_materials()
	lights.setup(12, 1)
	lights.max_distance = 26.0
	_plan()
	_construct()
	_make_footprints()
	add_arrival("start", _cell_center(START_CELL) + Vector3(0, 0.05, 0), -90.0)
	add_arrival("from_L008", _cell_center(START_CELL) + Vector3(0, 0.05, 0), -90.0)
	# The article says an exit restores an originally intended level; there is
	# no specified destination, so this is an honest release boundary (EXT).
	var out := _cell_center(EXIT_CELL) + Vector3(SPAN * 0.5 - 0.8, 1.2, 0)
	exit_trigger = add_exit("L075>EXT#1", "interact", out, Vector3(1.8, 2.4, 1.0), "Open the sand-free doorway")
	sound.bed("rain", {"seconds": 5.0}, -26.0)
	sound.bed("room_tone", {"cutoff": 160.0, "seconds": 4.0}, -42.0)
	add_shot("sand_corridor", _cell_center(START_CELL) + Vector3(-3, 1.62, 0), _cell_center(Vector2i(2, 2)) + Vector3(0, 1.35, 0))
	add_shot("clean_exit", _cell_center(EXIT_CELL) + Vector3(-2.4, 1.62, -2.1), _cell_center(EXIT_CELL) + Vector3(4.4, 1.3, 0))
	add_landmark("Arrival in the Sandrooms", _cell_center(START_CELL))
	add_landmark("Sand-free exit chamber", _cell_center(EXIT_CELL))


func _materials() -> void:
	MatLib.define("l75_sand", {"albedo_a": Color(0.70, 0.58, 0.35), "albedo_b": Color(0.78, 0.67, 0.45), "noise_scale": 4.0, "roughness_a": 1.0, "bump_strength": 1.5}, "sand")
	MatLib.define("l75_blue", {"albedo_a": Color(0.27, 0.44, 0.53), "albedo_b": Color(0.36, 0.55, 0.62), "peel_amount": 0.48, "stain_amount": 0.62, "roughness_a": 0.94}, "plaster")
	MatLib.define("l75_cream", {"albedo_a": Color(0.68, 0.63, 0.49), "albedo_b": Color(0.80, 0.75, 0.62), "peel_amount": 0.42, "stain_amount": 0.54, "roughness_a": 0.9}, "plaster")
	MatLib.define("l75_red", {"albedo_a": Color(0.52, 0.23, 0.20), "albedo_b": Color(0.59, 0.28, 0.23), "peel_amount": 0.62, "stain_amount": 0.7}, "plaster")
	MatLib.define("l75_steel", {"albedo_a": Color(0.34, 0.35, 0.35), "albedo_b": Color(0.27, 0.27, 0.27), "metallic_value": 0.65, "stain_amount": 0.68}, "metal")
	MatLib.define("l75_voidstone", {"albedo_a": Color(0.1, 0.10, 0.12), "albedo_b": Color(0.065, 0.066, 0.08), "roughness_a": 1.0}, "concrete_dark")
	MatLib.define("l75_clean_floor", {"albedo_a": Color(0.55, 0.55, 0.54), "albedo_b": Color(0.48, 0.49, 0.48)}, "concrete")
	MatLib.register("l75_sun", MatLib.panel(Color(1.0, 0.88, 0.67), 1.7))
	MatLib.define("l75_toy", {"albedo_a": Color(0.48, 0.43, 0.30), "albedo_b": Color(0.42, 0.39, 0.27), "roughness_a": 0.75}, "plaster")


func _cell_center(c: Vector2i) -> Vector3:
	return Vector3((float(c.x) + 0.5) * SPAN, 0, (float(c.y) + 0.5) * SPAN)


func _edge_key(a: Vector2i, b: Vector2i) -> String:
	var x := a if a.x < b.x or (a.x == b.x and a.y < b.y) else b
	var y := b if x == a else a
	return "%d,%d:%d,%d" % [x.x, x.y, y.x, y.y]


func _connected(a: Vector2i, b: Vector2i) -> bool:
	return carved.has(_edge_key(a, b))


func _plan() -> void:
	# Seeded depth-first spanning tree: every chamber connects to START,
	# independent of random loops. No forced teleportation through walls.
	var start := START_CELL
	var seen := {start: true}
	var stack: Array = [start]
	while not stack.is_empty():
		var a: Vector2i = stack.back()
		var choices: Array = []
		for delta in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var b: Vector2i = a + delta
			if b.x >= 0 and b.x < NX and b.y >= 0 and b.y < NZ and not seen.has(b):
				choices.append(b)
		if choices.is_empty():
			stack.pop_back()
			continue
		var next: Vector2i = choices[rng.randi_range(0, choices.size() - 1)]
		seen[next] = true
		carved[_edge_key(a, next)] = true
		stack.append(next)
	for z in NZ:
		for x in NX:
			var a := Vector2i(x, z)
			for d in [Vector2i(1, 0), Vector2i(0, 1)]:
				var b: Vector2i = a + d
				if b.x < NX and b.y < NZ and not _connected(a, b) and rng.randf() < 0.13:
					carved[_edge_key(a, b)] = true


func _construct() -> void:
	var k := kit("LiminalityArchitecture")
	for z in NZ:
		for x in NX:
			var c := Vector2i(x, z)
			var x0 := float(x) * SPAN
			var z0 := float(z) * SPAN
			var is_exit := c == EXIT_CELL
			k.slab(x0, z0, x0 + SPAN, z0 + SPAN, 0.0, 0.35, "l75_clean_floor" if is_exit else "l75_sand", GeoKit.ALL)
			# The voidstone roof is solid and never breaks.
			k.box(Vector3(x0 + SPAN * 0.5, HEIGHT + 0.35, z0 + SPAN * 0.5), Vector3(SPAN, 0.70, SPAN), "l75_voidstone")
			var palette := "l75_red" if rng.randf() < 0.06 else ("l75_blue" if rng.randf() < 0.48 else "l75_cream")
			if x == 0:
				_wall_x(k, x0, z0, false, palette)
			if z == 0:
				_wall_z(k, x0, z0, false, palette)
			_wall_x(k, x0 + SPAN, z0, _connected(c, c + Vector2i(1, 0)) or is_exit, palette)
			_wall_z(k, x0, z0 + SPAN, _connected(c, c + Vector2i(0, 1)), palette)
			# No working ceiling fixtures. Non-electrical illumination appears
			# from arbitrary bright patches in walls and the voidstone.
			if rng.randf() < 0.62:
				var glow := Vector3(x0 + rng.randf_range(1.5, 8.5), HEIGHT - 0.12, z0 + rng.randf_range(1.5, 8.5))
				k.box(glow, Vector3(rng.randf_range(0.8, 2.4), 0.03, 0.24), "l75_sun", GeoKit.NY, false)
				lights.add_anchor(glow - Vector3.UP * 0.6, Color(1.0, 0.89, 0.68), 0.8, 8.0, 0.85, "l75")
			if not is_exit and rng.randf() < 0.32:
				_toy(k, _cell_center(c) + Vector3(rng.randf_range(-2.7, 2.7), 0, rng.randf_range(-2.7, 2.7)))
			if not is_exit and rng.randf() < 0.46:
				_old_tracks(k, _cell_center(c), rng.randi_range(2, 5))
	# The only exit is the door in the room without sand, not a random wall.
	var p := _cell_center(EXIT_CELL)
	k.box(Vector3(p.x + SPAN * 0.5 - 0.25, 1.25, p.z), Vector3(0.12, 2.5, 2.4), "l75_steel", GeoKit.PX | GeoKit.NX, false)
	k.commit()


func _wall_x(k: GeoKit, x: float, z0: float, opening: bool, mat: String) -> void:
	if opening:
		k.box_mm(Vector3(x-0.14, 0, z0), Vector3(x+0.14, HEIGHT, z0+3.8), mat)
		k.box_mm(Vector3(x-0.14, 0, z0+6.2), Vector3(x+0.14, HEIGHT, z0+SPAN), mat)
		k.box_mm(Vector3(x-0.14, 2.65, z0+3.8), Vector3(x+0.14, HEIGHT, z0+6.2), mat)
	else:
		k.box_mm(Vector3(x-0.14, 0, z0), Vector3(x+0.14, HEIGHT, z0+SPAN), mat)


func _wall_z(k: GeoKit, x0: float, z: float, opening: bool, mat: String) -> void:
	if opening:
		k.box_mm(Vector3(x0, 0, z-0.14), Vector3(x0+3.8, HEIGHT, z+0.14), mat)
		k.box_mm(Vector3(x0+6.2, 0, z-0.14), Vector3(x0+SPAN, HEIGHT, z+0.14), mat)
		k.box_mm(Vector3(x0+3.8, 2.65, z-0.14), Vector3(x0+6.2, HEIGHT, z+0.14), mat)
	else:
		k.box_mm(Vector3(x0, 0, z-0.14), Vector3(x0+SPAN, HEIGHT, z+0.14), mat)


func _toy(k: GeoKit, p: Vector3) -> void:
	# An inert toy half-buried in sand; nothing is collectible here.
	if rng.randf() < 0.5:
		k.box(p + Vector3.UP * 0.06, Vector3(0.42, 0.12, 0.30), "l75_toy", GeoKit.ALL, false)
		for dz in [-0.12, 0.12]:
			k.box(p + Vector3(0, 0.05, dz), Vector3(0.29, 0.12, 0.08), "l75_steel", GeoKit.ALL, false)
	else:
		k.box(p + Vector3.UP * 0.06, Vector3(0.38, 0.14, 0.38), "l75_toy", GeoKit.ALL, false)
		k.box(p + Vector3.UP * 0.16, Vector3(0.05, 0.18, 0.28), "l75_steel", GeoKit.ALL, false)


func _old_tracks(k: GeoKit, p: Vector3, n: int) -> void:
	for i in n:
		var q := p + Vector3(float(i) * 0.35 - 1.1, 0.007, sin(float(i) * 0.6) * 0.16)
		k.box(q, Vector3(0.15, 0.006, 0.28), "l75_clean_floor", GeoKit.PY, false)


func _make_footprints() -> void:
	prints = MultiMeshInstance3D.new()
	prints.name = "PersistentFootprints"
	var surface := PlaneMesh.new()
	surface.size = Vector2(0.17, 0.31)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.30, 0.24, 0.16, 0.72)
	m.roughness = 1.0
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	surface.material = m
	var mult := MultiMesh.new()
	mult.transform_format = MultiMesh.TRANSFORM_3D
	mult.mesh = surface
	mult.instance_count = PRINT_LIMIT
	mult.visible_instance_count = 0
	prints.multimesh = mult
	prints.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(prints)


func on_player_ready() -> void:
	last_step = player.global_position
	if not SessionState.is_qa():
		Overlay.subtitle("[rain without rain] [dry sand settles under your shoes]", 5.0)


func level_process(_delta: float) -> void:
	if player == null or prints == null:
		return
	var p := player.global_position
	if Vector2(p.x - last_step.x, p.z - last_step.z).length() < 0.77:
		return
	last_step = p
	# Static impressions remain until the level is unloaded; unlike physics
	# props they do not consume collision shapes or draw calls per footprint.
	var c := Vector2i(floori(p.x / SPAN), floori(p.z / SPAN))
	if c.x < 0 or c.x >= NX or c.y < 0 or c.y >= NZ or c == EXIT_CELL:
		return
	var m := prints.multimesh
	var index := foot_count % PRINT_LIMIT
	var sideways := player.global_transform.basis.x * (0.10 if foot_count % 2 == 0 else -0.10)
	var xf := Transform3D(Basis(Vector3.UP, player.rotation.y), Vector3(p.x + sideways.x, 0.016, p.z + sideways.z))
	m.set_instance_transform(index, xf)
	foot_count += 1
	m.visible_instance_count = mini(PRINT_LIMIT, foot_count)


func qa_self_test() -> Array:
	return [
		{"ok": carved.size() >= NX * NZ - 1, "what": "spanning maze has enough connections"},
		{"ok": exit_trigger != null, "what": "single, sourced exit created"},
		{"ok": prints != null, "what": "persistent footprint mesh created"},
		{"ok": arrivals.has("from_L008"), "what": "source L008 arrival provided"},
	]
