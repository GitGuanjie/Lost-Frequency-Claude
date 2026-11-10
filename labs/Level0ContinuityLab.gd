extends Node3D
## Non-canon continuity laboratory, v4. One SceneTree / physics space with
## deterministic XYZ chunks, coherent macro-regions, four-way passable seams,
## per-chunk room motifs and persistently discoverable artifacts.
## No changes to the 100 canonical level definitions or their story transitions.

const C := 24.0
const DY := 4.5
const H := 4.25
const DEFAULT_SEED := 1337
const SEED_FILE := "user://continuity_lab/selected_seed.txt"
const SEED_INDEX := "user://continuity_lab/seed_index.json"

## Native QA override. When qa_seed is positive the lab boots with that seed
## and, when qa_persistence is false, with disk persistence disabled. The
## physical traversal test uses this to start from a known world and to never
## touch a player's saved lab state.
static var qa_seed := 0
static var qa_persistence := true

var world: ChunkWorld3D
var player: Player
var _hud: Label
var _map: Label
var _map_shown := false
var _near_key := Vector3i(999999, 999999, 999999)
var _current_district := "L000"
var _hud_clock := 0.0
var _capture_shot_path := ""
var _capture_shot_countdown := 0
## Where the canonical flickering wall is, once the spawn chunk is built.
var _canon_portal_pos := Vector3.ZERO
## True once the destination scene has been loaded ahead of the fold.
var _canon_prefetched := false


func _ready() -> void:
	SessionState.set_mode(SessionState.Mode.DEVELOPER)
	SessionState.current_level = "L000"
	SessionState.in_gameplay = true
	_build_environment()
	var initial_seed := _read_seed()
	if qa_seed > 0:
		initial_seed = qa_seed
	_register_seed(initial_seed)
	world = ChunkWorld3D.new()
	world.name = "Continuous3DWorld"
	world.seed_value = initial_seed
	world.world_id = "L000_CONTINUITY_PROTOTYPE" if initial_seed == DEFAULT_SEED else "L000_CONTINUITY_%d" % initial_seed
	world.disk_persistence_enabled = qa_persistence
	world.disk_path = "user://continuity_lab/world.json" if initial_seed == DEFAULT_SEED else "user://continuity_lab/world_%d.json" % initial_seed
	world.radius_xz = 1
	world.radius_y = 1
	world.unload_xz = 2
	world.unload_y = 2
	world.builds_per_frame = 2
	world.builder = _build_chunk
	add_child(world)
	# Populate the local floor before spawning the player; remaining storeys
	# stream in during the first frames, avoiding a 27-chunk start-up stall.
	world.build_around(Vector3(11, 0.12, 11), 1, 0)
	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.position = Vector3(11.0, 0.14, 11.0)
	player.apply_rules({"gravity": 9.8, "flashlight": "allowed", "view_distance": 180.0})
	player.flashlight.visible = true
	player.died.connect(_on_dead)
	world.target = player
	# The laboratory hands the wanderer to the persistent coordinator, which
	# keeps this exact player alive across a non-Euclidean fold.
	var coordinator := WorldCoordinator.ensure(get_tree())
	if coordinator != null:
		coordinator.adopt(player)
	_make_hud()
	SessionState.capture_mouse()
	Overlay.toast("INFINITE BACKROOMS v5: 16x16 districts, 8x8 superdistricts, region-owned megastructures. F8 map, F9 mark, F4 reshape, F5/F6 seeds, F10 menu", 8.0)
	Overlay.toast("A flickering wall in the spawn hall throws you through to Level 1 (canon route, ADAPTATION entry). Sprint into it and keep pushing.", 9.0)
	# Announce the scene on stdout. A headless or exported run that reaches
	# this line proves the lab scene was really instantiated, which a silent
	# process cannot show.
	print("[ContinuityLab] ready seed=%d world_id=%s" % [initial_seed, world.world_id])
	_maybe_capture_shot()


## QA entry point: `--shot <file.png>` writes a viewport capture of the
## generated world and quits. It gives the release build a verifiable image
## without a human at the keyboard.
func _maybe_capture_shot() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		var arg := str(args[i])
		if arg.begins_with("--shot="):
			_capture_shot_path = arg.substr(7).strip_edges()
		elif arg == "--shot" and i + 1 < args.size():
			_capture_shot_path = str(args[i + 1]).strip_edges()
		else:
			continue
		if _capture_shot_path == "":
			_capture_shot_path = "user://infinite_backrooms_shot.png"
		_capture_shot_countdown = 90
		return


func _capture_shot() -> void:
	if _capture_shot_countdown <= 0:
		return
	_capture_shot_countdown -= 1
	if _capture_shot_countdown > 0:
		return
	if DisplayServer.get_name() == "headless":
		# RenderingServer.frame_post_draw never fires under the dummy
		# renderer, so the await below would hang forever and the run would
		# look like a silent success. Fail loudly instead.
		print("SHOT failed: the headless display server cannot render a frame")
		get_tree().quit(2)
		return
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var target := _capture_shot_path
	if target.begins_with("user://"):
		target = ProjectSettings.globalize_path(target)
	DirAccess.make_dir_recursive_absolute(target.get_base_dir())
	var err := image.save_png(target)
	print("SHOT %s err=%d size=%dx%d" % [target, err, image.get_width(), image.get_height()])
	get_tree().quit(0 if err == OK else 1)


func _read_seed() -> int:
	if FileAccess.file_exists(SEED_FILE):
		var raw := FileAccess.get_file_as_string(SEED_FILE).strip_edges()
		if raw.is_valid_int() and int(raw) > 0:
			return int(raw)
	return DEFAULT_SEED


func _write_seed(seed_value: int) -> bool:
	var directory := ProjectSettings.globalize_path("user://continuity_lab")
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		return false
	var f := FileAccess.open(SEED_FILE, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(str(seed_value))
	f.close()
	return true


## The index lets the player revisit old generated worlds. Each seed has a
## separate chunk-state JSON file; changing worlds never deletes its history.
func _known_seeds() -> Array:
	if not FileAccess.file_exists(SEED_INDEX):
		return [DEFAULT_SEED]
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SEED_INDEX))
	if not (parsed is Dictionary) or not (parsed.get("seeds") is Array):
		return [DEFAULT_SEED]
	var clean := []
	for item in parsed["seeds"]:
		if int(item) > 0 and not clean.has(int(item)):
			clean.append(int(item))
	if not clean.has(DEFAULT_SEED):
		clean.push_front(DEFAULT_SEED)
	return clean


func _register_seed(value: int) -> void:
	var seeds := _known_seeds()
	if seeds.has(value) and FileAccess.file_exists(SEED_INDEX):
		return
	if not seeds.has(value):
		seeds.append(value)
	var directory := ProjectSettings.globalize_path("user://continuity_lab")
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		return
	var f := FileAccess.open(SEED_INDEX, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"schema": 1, "seeds": seeds}))
		f.close()


func _switch_seed(value: int) -> void:
	if value == world.seed_value or not _write_seed(value):
		return
	world.save_to_disk()
	SessionState.release_mouse()
	get_tree().call_deferred("change_scene_to_file", "res://labs/Level0ContinuityLab.tscn")


func _cycle_seed() -> void:
	var seeds := _known_seeds()
	if seeds.size() <= 1:
		Overlay.toast("Only one world saved. F6 creates another seed.", 2.5)
		return
	var index := seeds.find(world.seed_value)
	var next_seed: int = seeds[posmod(index + 1, seeds.size())]
	Overlay.toast("Opening saved seed %d" % next_seed, 2.0)
	_switch_seed(next_seed)


func _build_environment() -> void:
	var root_env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.08, 0.085, 0.09)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.93, 0.85, 0.69)
	e.ambient_light_energy = 0.36
	e.fog_enabled = true
	e.fog_light_color = Color(0.50, 0.45, 0.33)
	e.fog_density = 0.016
	root_env.environment = e
	add_child(root_env)


func _make_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)
	_hud = Label.new()
	_hud.position = Vector2(18, 18)
	_hud.add_theme_color_override("font_color", Color(0.96, 0.91, 0.72))
	_hud.add_theme_font_size_override("font_size", 15)
	canvas.add_child(_hud)
	_map = Label.new()
	_map.position = Vector2(18, 96)
	_map.add_theme_color_override("font_color", Color(0.85, 0.98, 0.88))
	_map.add_theme_font_size_override("font_size", 16)
	_map.visible = _map_shown
	canvas.add_child(_map)


## Explicit shared border contract. Paired faces use identical portals.
## Core-to-core walls admit a broad hall opening and a separate atrium well.
## Border ownership is deterministic and does not depend on chunk load order.
func _boundary(kit: GeoKit, key: Vector3i, o: Vector3, face: String, mat: String) -> void:
	var openings := ContinuityTopology.face_openings(world.seed_value, key, face)
	var a := Vector3.ZERO
	var b := Vector3.ZERO
	match face:
		"east":
			a = Vector3(o.x + C, o.y, o.z)
			b = Vector3(o.x + C, o.y, o.z + C)
		"west":
			a = Vector3(o.x, o.y, o.z)
			b = Vector3(o.x, o.y, o.z + C)
		"north":
			a = Vector3(o.x, o.y, o.z + C)
			b = Vector3(o.x + C, o.y, o.z + C)
		"south":
			a = Vector3(o.x, o.y, o.z)
			b = Vector3(o.x + C, o.y, o.z)
	kit.wall(a, b, H, 0.18, mat, openings)


func _build_chunk(cx: int, cy: int, cz: int, version: int, node: Node3D) -> Dictionary:
	var key := Vector3i(cx, cy, cz)
	var o := ContinuityTopology.origin(key)
	# The regional plan owns the architecture. A 24 m chunk never chooses its
	# own style in isolation: the 16x16 district, the 8x8 superdistrict and
	# the megastructure inside it decide together what this space is.
	var plan := world.plan_for(key)
	var zone: String = plan["zone_id"]
	var family: String = plan["family"]
	var materials := RegionalPlan.family_materials(family)
	var warehouse := family == RegionalPlan.FAMILY_WAREHOUSE
	var theme: String = plan["theme"]
	# The room MOTIF is the one reshufflable element (F4). The regional
	# structure above it never moves.
	var room := ContinuityTopology.room_type(world.seed_value, key, version)
	var role: String = plan["role"]
	var wall: String = materials["wall"]
	var ground: String = materials["floor"]
	var roof: String = materials["ceiling"]
	var kit := GeoKit.new(node, "RoomGeometry")
	var y := o.y
	var incoming := ContinuityTopology.incoming_shaft(cy)
	var outgoing := ContinuityTopology.outgoing_shaft(cy)
	var hole := ContinuityTopology.continuity_hole(world.seed_value, key)
	var bridge := ContinuityTopology.continuity_bridge(world.seed_value, key)
	if cy > ContinuityTopology.MIN_FLOOR:
		if hole.size != Vector2.ZERO:
			_floor_with_slot_and_atrium(kit, o, y, incoming, ground, hole, bridge)
			_atrium_safety_rails(kit, o, y, hole, bridge)
		else:
			_floor_with_slot(kit, o, y, incoming, ground)
	else:
		kit.slab(o.x, o.z, o.x + C, o.z + C, y, 0.25, ground)
	if cy < ContinuityTopology.MAX_FLOOR:
		# The ramp is built on the SAME rectangle as the floor opening it
		# passes through, so the hole is always completely filled.
		var ramp_slot := ContinuityTopology.stair_slot(outgoing)
		var sx := o.x + ramp_slot.position.x + ramp_slot.size.x * 0.5
		kit.stairs(Vector3(sx, y, o.z + ramp_slot.position.y), Vector3(0, 0, 1),
			ramp_slot.size.x, DY, ContinuityTopology.STAIR_STEPS,
			"metal" if warehouse else "wood_floor", ContinuityTopology.STAIR_RUN, false)
	else:
		kit.slab(o.x, o.z, o.x + C, o.z + C, y + DY, 0.22, roof)
	for face in ["west", "east", "south", "north"]:
		_boundary(kit, key, o, face, wall)
	if not ContinuityTopology.is_macro_core(key) and not ContinuityTopology.is_super_spine(key):
		_add_room_partitions(kit, o, room, wall)
	# Decorative geometry never blocks the main cross-shaped circulation,
	# either stair shaft, or any of the four seeded edge portals.
	if role == "core":
		_add_superstructure(kit, o, key, warehouse, version)
	elif role == "hub" or role == "spine":
		_add_super_spine_architecture(kit, o, key, warehouse, version)
	elif role == "structure":
		_add_megastructure(kit, node, o, key, plan, version)
	else:
		_add_architecture(kit, o, key, room, theme, warehouse, version)
	_add_lighting(kit, node, o, key, room, theme, warehouse)
	# The documented Level 0 -> Level 1 route lives in the spawn chunk, so it
	# is always reachable from the start and its position never moves.
	if key == Vector3i(0, 0, 0):
		_add_canon_portal(kit, node, o, y)
	if ContinuityTopology.is_power_anchor(world.seed_value, key):
		_add_power_relay(kit, node, key, o)
	if ContinuityTopology.is_super_terminal(key):
		_add_super_terminal(kit, node, key, o)
	if bool(world.change_of(key, "marked", false)):
		kit.box(Vector3(o.x + 10.8, y + 0.14, o.z + 20.9),
			Vector3(0.9, 0.28, 0.9), "metal", GeoKit.ALL, false)
	if ContinuityTopology.has_landmark(world.seed_value, key):
		_add_discovery(kit, node, key, o, y)
	kit.commit()
	return {"district": zone, "macro": theme, "room": room,
		"superstructure": ContinuityTopology.macro_structure(world.seed_value, key),
		"superdistrict": ContinuityTopology.super_type(world.seed_value, key),
		"hub": ContinuityTopology.is_superhub(key),
		"spine": ContinuityTopology.is_super_spine(key),
		"atrium": hole.size != Vector2.ZERO, "floor": cy,
		"role": role, "structure": plan["structure_id"],
		"structure_kind": plan["structure_kind"],
		"district_style": plan["district"]["style"],
		"version": version, "boxes": kit.stats["boxes"],
		"triangles": kit.stats["tris"], "colliders": kit.stats["shapes"]}


## A carved floor around two non-overlapping openings: the standard incoming
## staircase and the central atrium well. Splitting on ALL rectangle boundaries
## is slower than one slab but only runs in 4 core chunks per 4x4 macro-region.
## The bridge is an actual floor strip, not decorative geometry.
func _floor_with_slot_and_atrium(kit: GeoKit, o: Vector3, y: float, shaft: int,
		mat: String, hole: Rect2, bridge: Rect2) -> void:
	# Same rectangle as _floor_with_slot: the hole is the ramp's footprint.
	var slot := ContinuityTopology.stair_slot(shaft)
	var a := slot.position.x
	var b := slot.end.x
	var xs: Array = [0.0, a, b, hole.position.x,
		hole.end.x, C]
	var zs: Array = [0.0, slot.position.y, slot.end.y, hole.position.y,
		hole.end.y, bridge.position.y, bridge.end.y, C]
	xs.sort()
	zs.sort()
	for xi in range(xs.size() - 1):
		for zi in range(zs.size() - 1):
			var x0: float = xs[xi]
			var x1: float = xs[xi + 1]
			var z0: float = zs[zi]
			var z1: float = zs[zi + 1]
			if x1 - x0 < 0.02 or z1 - z0 < 0.02:
				continue
			var mid := Vector2((x0 + x1) * 0.5, (z0 + z1) * 0.5)
			if slot.has_point(mid):
				continue
			if hole.has_point(mid) and not bridge.has_point(mid):
				continue
			kit.slab(o.x + x0, o.z + z0, o.x + x1, o.z + z1, y, 0.22, mat)
	# Same incoming-stair protection as the ordinary floors.
	for lateral in [a - 0.12, b + 0.12]:
		kit.box(Vector3(o.x + lateral, y + 0.55, o.z + (slot.position.y + slot.end.y) * 0.5),
			Vector3(0.15, 1.10, slot.size.y), "metal")
	kit.box(Vector3(o.x + (a + b) * 0.5, y + 0.55, o.z + slot.position.y - 0.12),
		Vector3(b - a, 1.10, 0.15), "metal")


## Solid perimeter rails except at the two east-west bridge entrances.
## The bridge carries two side rails, with open ends on both x sides.
func _atrium_safety_rails(kit: GeoKit, o: Vector3, y: float,
		hole: Rect2, bridge: Rect2) -> void:
	var x_edge := hole.position.x if hole.position.x > 0.1 else hole.end.x
	var z_edge := hole.position.y if hole.position.y > 0.1 else hole.end.y
	for section in [Vector2(hole.position.y, bridge.position.y),
			Vector2(bridge.end.y, hole.end.y)]:
		var length: float = section.y - section.x
		if length > 0.15:
			kit.box(Vector3(o.x + x_edge, y + 0.62,
				o.z + (section.x + section.y) * 0.5),
				Vector3(0.16, 1.24, length), "metal")
	kit.box(Vector3(o.x + (hole.position.x + hole.end.x) * 0.5,
		y + 0.62, o.z + z_edge), Vector3(hole.size.x, 1.24, 0.16), "metal")
	for z in [bridge.position.y, bridge.end.y]:
		kit.box(Vector3(o.x + (bridge.position.x + bridge.end.x) * 0.5,
			y + 0.62, o.z + z), Vector3(bridge.size.x, 1.24, 0.12), "metal")


## Contiguous 2x2 chunk architecture: the hall walls contain wide openings,
## the 10x10 central well spans four chunks and four storeys, and the strip
## bridges physically connect each east-west pair. This is not four unrelated
## room motifs; all coordinates and silhouettes are set by the macro plan.
func _add_superstructure(kit: GeoKit, o: Vector3, key: Vector3i,
		warehouse: bool, version: int) -> void:
	var style := ContinuityTopology.macro_structure(world.seed_value, key)
	var material := "metal" if warehouse else "l0_wallpaper_pale"
	var beam := "concrete" if warehouse else "wood_floor"
	# Refit overhead decor when F4 is pressed; region/voids/bridges/doors stay fixed.
	var fitout := ContinuityTopology.stable_roll(world.seed_value,
		["atrium-fitout", key.x, key.y, key.z, version], 3)
	var west := posmod(key.x, 4) == 1
	var south := posmod(key.z, 4) == 1
	var edge_x := 3.0 if west else 21.0
	var edge_z := 3.0 if south else 21.0
	# Monumental perimeter supports, away from doorway corridor and stair wells.
	kit.cylinder(Vector3(o.x + edge_x, o.y + H * 0.5, o.z + edge_z),
		0.9, H, material, 12)
	# Suspended cornices and ribs; all above the playable clear height.
	for zz in [2.0, 22.0]:
		kit.box(Vector3(o.x + 12.0, o.y + H - 0.25, o.z + zz),
			Vector3(22.0, 0.42, 0.75), beam, GeoKit.ALL, false)
	for xx in [2.0, 22.0]:
		kit.box(Vector3(o.x + xx, o.y + H - 0.28, o.z + 12.0),
			Vector3(0.75, 0.45, 21.0), beam, GeoKit.ALL, false)
	# The void side has strongly repeated vertical visual motifs.
	var hole := ContinuityTopology.atrium_hole(world.seed_value, key)
	if hole.size != Vector2.ZERO:
		var hx := hole.position.x + 2.5
		var hz := hole.position.y + 2.5
		for offset in [-1.6, 1.6]:
			kit.box(Vector3(o.x + hx + offset, o.y + H * 0.5,
				o.z + hz), Vector3(0.16, H, 0.16),
				"metal", GeoKit.ALL, false)
	if style == "hanging_archive":
		for xx in [3.0, 21.0]:
			kit.box(Vector3(o.x + xx, o.y + H - 1.1, o.z + 12.0),
				Vector3(1.8, 1.9, 7.0), "wood_floor", GeoKit.ALL, false)
	elif style == "industrial_concourse" or style == "riser_court":
		for zz in [4.0, 20.0]:
			kit.box(Vector3(o.x + 12.0, o.y + H - 0.9, o.z + zz),
				Vector3(16.0, 0.28, 1.1), "metal", GeoKit.ALL, false)
	elif style == "grand_atrium":
		# Framing bands make the ceiling appear much larger from ground level.
		for xx in [4.0, 20.0]:
			kit.box(Vector3(o.x + xx, o.y + H - 0.7, o.z + 12.0),
				Vector3(0.28, 0.35, 16.0), material, GeoKit.ALL, false)
	# Versioned non-colliding superstructure details (safe to reshuffle).
	if fitout == 0:
		for xx in [6.0, 12.0, 18.0]:
			kit.box(Vector3(o.x + xx, o.y + H - 0.14, o.z + 12.0),
				Vector3(0.28, 0.25, 16.0), "panel", GeoKit.ALL, false)
	elif fitout == 1:
		for zz in [5.5, 12.0, 18.5]:
			kit.box(Vector3(o.x + 12.0, o.y + H - 0.15, o.z + zz),
				Vector3(16.0, 0.28, 0.28), "metal", GeoKit.ALL, false)
	else:
		for xx in [5.0, 19.0]:
			for zz in [5.0, 19.0]:
				kit.box(Vector3(o.x + xx, o.y + H - 0.18, o.z + zz),
					Vector3(2.0, 0.30, 2.0), "panel", GeoKit.ALL, false)


## A visible 192m-scale plan across 8x8 chunks: two uninterrupted boulevards
## lead into a 2x2 atrium hub. The same vocabulary repeats across storeys.
## All decorative ribs sit above headroom; the 4m side portals and both
## stair shafts retain a clear walking route into the superdistrict network.
func _add_super_spine_architecture(kit: GeoKit, o: Vector3, key: Vector3i,
		warehouse: bool, version: int) -> void:
	var stype := ContinuityTopology.super_type(world.seed_value, key)
	var material := "metal" if warehouse or stype in ["vertical_foundry", "deserted_transit_hub"] else "l0_wallpaper_pale"
	var trim := "panel" if stype in ["hanging_city", "great_archive"] else "concrete"
	var y := o.y
	var x_lane := posmod(key.x, 8) in [3, 4]
	var z_lane := posmod(key.z, 8) in [3, 4]
	var fitout := ContinuityTopology.stable_roll(world.seed_value,
		["super-fitout", key.x, key.y, key.z, version], 3)
	# Corridor-scale rhythm: paired pilasters on the outer margins.
	for offset in [2.0, 22.0]:
		if x_lane:
			kit.cylinder(Vector3(o.x + offset, y + H * 0.5, o.z + 3.0),
				0.36, H, material, 8)
		if z_lane:
			kit.cylinder(Vector3(o.x + 3.0, y + H * 0.5, o.z + offset),
				0.36, H, material, 8)
	# Beams are overhead and collision-free; their phase changes on F4.
	for n in range(3):
		var t := 4.0 + 7.0 * float(n)
		if x_lane:
			kit.box(Vector3(o.x + 12.0, y + H - 0.18, o.z + t),
				Vector3(18.0, 0.33, 0.34 + float(fitout) * 0.13),
				trim, GeoKit.ALL, false)
		if z_lane:
			kit.box(Vector3(o.x + t, y + H - 0.18, o.z + 12.0),
				Vector3(0.34 + float(fitout) * 0.13, 0.33, 18.0),
				trim, GeoKit.ALL, false)
	# Repeatable silhouettes in all 5 storeys; no global mesh is needed.
	# Each 8x8 intersection reads as a recognizable architectural landmark.
	if ContinuityTopology.is_superhub(key):
		var colx := 3.2 if posmod(key.x, 8) == 3 else 20.8
		var colz := 3.2 if posmod(key.z, 8) == 3 else 20.8
		kit.cylinder(Vector3(o.x + colx, y + H * 0.5, o.z + colz),
			0.85, H, material, 12)
		for xx in [5.5, 18.5]:
			kit.box(Vector3(o.x + xx, y + H - 0.40, o.z + 12.0),
				Vector3(0.30, 0.36, 17.0), trim, GeoKit.ALL, false)

	# Six distinct architectural silhouettes, all overhead or confined to
	# side alcoves. Unlike the V3 random fitout, the broad geometry is fixed
	# for a given 8x8 district so exploration reads as a coherent place.
	match stype:
		"threshold_nexus":
			for side in [2.3, 21.7]:
				kit.box(Vector3(o.x + side, y + H - 0.85, o.z + 12.0),
					Vector3(0.9, 1.1, 13.0), "wood_floor", GeoKit.ALL, false)
		"vertical_foundry":
			for offset in [3.4, 20.6]:
				kit.box(Vector3(o.x + offset, y + H - 0.65, o.z + 12.0),
					Vector3(0.9, 0.9, 18.0), "metal", GeoKit.ALL, false)
				kit.box(Vector3(o.x + 12.0, y + H - 0.55, o.z + offset),
					Vector3(17.0, 0.8, 0.9), "metal", GeoKit.ALL, false)
		"deserted_transit_hub":
			for marker in [6.0, 18.0]:
				kit.box(Vector3(o.x + 12.0, y + H - 0.7, o.z + marker),
					Vector3(7.0, 0.8, 0.35), "panel", GeoKit.ALL, false)
		"hanging_city":
			for x_pos in [3.0, 21.0]:
				for z_pos in [7.0, 17.0]:
					kit.box(Vector3(o.x + x_pos, y + H - 0.9, o.z + z_pos),
						Vector3(2.6, 1.4, 2.3), "concrete", GeoKit.ALL, false)
		"great_archive":
			for x_pos in [3.0, 21.0]:
				kit.box(Vector3(o.x + x_pos, y + H - 1.15, o.z + 12.0),
					Vector3(1.3, 1.8, 16.0), "wood_floor", GeoKit.ALL, false)
		"service_cathedral":
			for z_pos in [5.0, 12.0, 19.0]:
				kit.box(Vector3(o.x + 12.0, y + H - 0.55, o.z + z_pos),
					Vector3(20.0, 0.65, 0.9), "l0_wallpaper_pale", GeoKit.ALL, false)
		"silent_cistern":
			for x_pos in [4.0, 20.0]:
				for z_pos in [4.0, 20.0]:
					kit.box(Vector3(o.x + x_pos, y + H - 0.5, o.z + z_pos),
						Vector3(2.5, 0.6, 2.5), "concrete_dark", GeoKit.ALL, false)


## Region-wide architecture for one megastructure.
##
## Every chunk of a structure repeats the SAME world-aligned bay grid, so the
## colonnade, the wall rhythm and the floor inlays line up across chunk seams
## and the whole structure reads as one building instead of a row of decorated
## boxes. The four anchor bays sit outside the stair slots, the atrium wells
## and the four seeded edge portals, so every guaranteed route is untouched.
func _add_megastructure(kit: GeoKit, node: Node3D, o: Vector3, key: Vector3i,
		plan: Dictionary, version: int) -> void:
	var kind: String = plan["structure_kind"]
	var family: String = plan["family"]
	var accent := RegionalPlan.structure_accent(kind, family)
	var axis: String = plan["structure_axis"]
	var anchors := [Vector2(4.0, 3.7), Vector2(20.0, 3.7),
		Vector2(4.0, 20.3), Vector2(20.0, 20.3)]
	var is_anchor_chunk: bool = key == Vector3i(plan["structure_anchor"])
	var fitout := ContinuityTopology.stable_roll(world.seed_value,
		["structure-fitout", key.x, key.y, key.z, version], 3)
	var y := o.y
	# 1. The structural bay. World-aligned, so the rhythm is continuous.
	for n in anchors.size():
		var a: Vector2 = anchors[n]
		var base := Vector3(o.x + a.x, y, o.z + a.y)
		if is_anchor_chunk and n == 0:
			_add_structure_beacon(kit, node, base, accent)
			continue
		match kind:
			RegionalPlan.KIND_MACHINE_HALL:
				if n == 0 or n == 3:
					kit.cylinder(base + Vector3.UP * (H * 0.5), 1.25, H, accent, 10)
				else:
					kit.cylinder(base + Vector3.UP * (H * 0.5), 0.45, H, accent, 8)
			RegionalPlan.KIND_SHAFT_STACK:
				kit.cylinder(base + Vector3.UP * (H * 0.5), 0.34, H, accent, 8)
				kit.box(base + Vector3.UP * (H - 0.32), Vector3(0.9, 0.62, 0.9),
					"metal", GeoKit.ALL, false)
			RegionalPlan.KIND_ARCHIVE_BLOCK:
				kit.box(base + Vector3.UP * 1.05, Vector3(2.0, 2.1, 0.75), accent)
				for shelf in range(1, 4):
					kit.box(base + Vector3.UP * (0.28 + 0.52 * shelf) + Vector3(0, 0, 0.42),
						Vector3(1.8, 0.08, 0.16), "metal", GeoKit.ALL, false)
			_:
				kit.cylinder(base + Vector3.UP * (H * 0.5), 0.50, H, accent, 10)
	# 2. Wall pilasters: a continuous vertical rhythm along the whole structure.
	for a in anchors:
		kit.box(Vector3(o.x + a.x, y + H * 0.5, o.z + 0.18),
			Vector3(0.9, H, 0.36), accent, GeoKit.ALL, false)
		kit.box(Vector3(o.x + a.x, y + H * 0.5, o.z + C - 0.18),
			Vector3(0.9, H, 0.36), accent, GeoKit.ALL, false)
		kit.box(Vector3(o.x + 0.18, y + H * 0.5, o.z + a.y),
			Vector3(0.36, H, 0.9), accent, GeoKit.ALL, false)
		kit.box(Vector3(o.x + C - 0.18, y + H * 0.5, o.z + a.y),
			Vector3(0.36, H, 0.9), accent, GeoKit.ALL, false)
	# 3. Overhead structure, aligned with the long axis of the megastructure.
	if axis == "x":
		kit.box(Vector3(o.x + C * 0.5, y + H - 0.26, o.z + 12.0),
			Vector3(C, 0.46, 0.85), accent, GeoKit.ALL, false)
		for a in anchors:
			kit.box(Vector3(o.x + a.x, y + H - 0.30, o.z + 12.0),
				Vector3(0.55, 0.52, 23.0), accent, GeoKit.ALL, false)
	else:
		kit.box(Vector3(o.x + 12.0, y + H - 0.26, o.z + C * 0.5),
			Vector3(0.85, 0.46, C), accent, GeoKit.ALL, false)
		for a in anchors:
			kit.box(Vector3(o.x + 12.0, y + H - 0.30, o.z + a.y),
				Vector3(23.0, 0.52, 0.55), accent, GeoKit.ALL, false)
	# 4. Floor inlays: two continuous bands that cross every chunk seam. They
	# are 12 mm proud of the floor, carry no collision and never block a door.
	for band in [2.0, C - 2.0]:
		kit.box(Vector3(o.x + C * 0.5, y + 0.007, o.z + band),
			Vector3(C, 0.012, 1.0), accent, GeoKit.ALL, false)
	# 5. Kind-specific fittings, all above head clearance or out of the way.
	match kind:
		RegionalPlan.KIND_ARCADE:
			for a in anchors:
				kit.box(Vector3(o.x + a.x, y + H - 0.62, o.z + a.y),
					Vector3(1.5, 0.5, 1.5), accent, GeoKit.ALL, false)
		RegionalPlan.KIND_MACHINE_HALL:
			for n in 2:
				kit.box(Vector3(o.x + 8.0 + 8.0 * float(n), y + H - 0.55, o.z + 12.0),
					Vector3(0.7, 0.9, 20.0), "metal", GeoKit.ALL, false)
		RegionalPlan.KIND_SHAFT_STACK:
			for a in anchors:
				kit.box(Vector3(o.x + a.x, y + H - 0.95, o.z + a.y),
					Vector3(1.6, 1.1, 1.6), "metal", GeoKit.ALL, false)
		RegionalPlan.KIND_ARCHIVE_BLOCK:
			for n in 3:
				kit.box(Vector3(o.x + 6.0 + 6.0 * float(n), y + H - 0.55, o.z + 12.0),
					Vector3(0.45, 0.35, 18.0), accent, GeoKit.ALL, false)
	if fitout == 0:
		for a in anchors:
			kit.box(Vector3(o.x + a.x, y + H - 0.16, o.z + a.y),
				Vector3(1.2, 0.24, 1.2), "panel", GeoKit.ALL, false)
	elif fitout == 1:
		for n in 4:
			kit.box(Vector3(o.x + 3.0 + 6.0 * float(n), y + H - 0.14, o.z + 12.0),
				Vector3(0.3, 0.22, 20.0), "metal", GeoKit.ALL, false)


## The one landmark of a megastructure: a fluted pylon with a beacon. It sits
## in the corner bay, clear of every portal, stair slot and atrium well.
func _add_structure_beacon(kit: GeoKit, node: Node3D, base: Vector3,
		accent: String) -> void:
	kit.cylinder(base + Vector3.UP * (H * 0.5), 0.62, H, accent, 12)
	kit.cylinder(base + Vector3.UP * (H - 0.30), 0.92, 0.40, "metal", 12, false)
	kit.panel(base + Vector3.UP * (H - 0.12), 1.4, 1.4, "panel")
	var light := OmniLight3D.new()
	light.position = base + Vector3.UP * (H - 0.45)
	light.light_color = Color(1.0, 0.88, 0.62)
	light.light_energy = 1.6
	light.omni_range = 16.0
	light.shadow_enabled = false
	node.add_child(light)



func _add_super_terminal(kit: GeoKit, node: Node3D, key: Vector3i,
		o: Vector3) -> void:
	var enabled := bool(world.change_of(key, "network_online", false))
	var center := Vector3(o.x + 12.0, o.y + 0.68, o.z + 3.4)
	kit.box(center, Vector3(1.2, 1.24, 0.72),
		"panel" if enabled else "metal", GeoKit.ALL, false)
	kit.box(center + Vector3(0, 0.45, -0.38), Vector3(0.84, 0.26, 0.08),
		"panel", GeoKit.ALL, false)
	var it := Interactable.new()
	node.add_child(it)
	it.setup(center, Vector3(1.6, 1.4, 1.1),
		"Power down superdistrict" if enabled else "Activate superdistrict survey",
		func() -> void: _toggle_super_network(key))


func _toggle_super_network(anchor: Vector3i) -> void:
	var active := bool(world.change_of(anchor, "network_online", false))
	world.set_change(anchor, "network_online", not active)
	var target_super := ContinuityTopology.super_key(anchor)
	for key in world.chunks.keys():
		if ContinuityTopology.super_key(key) == target_super and \
				ContinuityTopology.is_super_spine(key):
			world.call_deferred("refresh_chunk", key)
	var subtype := ContinuityTopology.super_type(world.seed_value, anchor)
	Overlay.show_note("SURVEY ARRAY — " + subtype.replace("_", " ").to_upper(),
		"Non-canon continuity experiment. 8x8 chunks (192m square), five storeys. " +
		"The transit spine and suspended bridges are continuous. Survey lighting: %s. " %
		("OFF" if active else "ON") +
		"This state and explored landmarks are saved separately for each world seed.")


func _add_power_relay(kit: GeoKit, node: Node3D, key: Vector3i,
		o: Vector3) -> void:
	# A non-blocking interactable beside the hall, outside either stair slot.
	var active := bool(world.change_of(key, "relay_active", false))
	var center := Vector3(o.x + 12.0, o.y + 0.72, o.z + 4.1)
	kit.box(center, Vector3(0.75, 1.30, 0.50),
		"panel" if active else "metal", GeoKit.ALL, false)
	var interact := Interactable.new()
	node.add_child(interact)
	interact.setup(center, Vector3(1.2, 1.5, 0.9),
		"Disable macro relay" if active else "Restore macro relay",
		func() -> void: _toggle_relay(key))


func _toggle_relay(anchor: Vector3i) -> void:
	var old := bool(world.change_of(anchor, "relay_active", false))
	world.set_change(anchor, "relay_active", not old)
	for k in world.chunks.keys():
		if ContinuityTopology.macro_key(k) == ContinuityTopology.macro_key(anchor) and \
				ContinuityTopology.is_macro_core(k):
			world.call_deferred("refresh_chunk", k)
	Overlay.toast("Atrium relay %s — lights updated in the loaded galleries." %
		("OFF" if old else "ON"), 3.0)


## Optional walkable side galleries. Every partition leaves a >=4.4 m
## central doorway, so a west/south/east/north boundary opening always has
## a route into the central circulation. Architectural rooms remain fully
## inside their chunk: walls never depend on neighbouring generation order.
## The documented Level 0 -> Level 1 route, reachable from the laboratory.
##
## The canonical Level 0 exit is a flickering wall: "find a flickering wall to
## throw yourself through". This builds one in the spawn chunk, against the
## north boundary, clear of every declared portal, stair slot, atrium well and
## structural pilaster. The placement is deterministic and does not depend on
## the seed, so the route is always in the same place.
##
## The WALL is an ADAPTATION entry point into the laboratory. The ROUTE it
## opens is the canon route, and it leads to the REAL Level 1 scene through
## the persistent WorldCoordinator. There is no proxy level here.
func _add_canon_portal(kit: GeoKit, node: Node3D, o: Vector3, y: float) -> void:
	# The same material the canonical Level 0 uses, so the wall reads exactly
	# like the one the source page describes.
	MatLib.define("l0_wall_flicker",
		{"emission_color": Color(1.0, 0.93, 0.62), "emission_energy": 0.55,
			"emission_flicker": 1.0}, "l0_wallpaper")
	var x0 := o.x + 20.9
	var x1 := o.x + 23.6
	var z := o.z + 23.78
	kit.wall(Vector3(x0, y, z), Vector3(x1, y, z), H, 0.16, "l0_wall_flicker", [], GeoKit.ALL)
	# A buzzing light in front of it: the wall is lit, and it crackles.
	var light := OmniLight3D.new()
	light.position = Vector3((x0 + x1) * 0.5, y + 2.3, z - 0.9)
	light.light_color = Color(1.0, 0.95, 0.75)
	light.light_energy = 1.7
	light.omni_range = 9.0
	light.shadow_enabled = false
	node.add_child(light)
	var hum := AudioStreamPlayer3D.new()
	hum.stream = AudioSynth.get_stream("static", {"seconds": 2.0})
	hum.unit_size = 6.0
	hum.max_db = -16.0
	hum.position = Vector3((x0 + x1) * 0.5, y + 1.2, z - 0.9)
	hum.autoplay = true
	node.add_child(hum)
	# The trigger volume sits in front of the wall, on the side the player
	# approaches from. Its centre is NORTH of the player's body centre, so the
	# "pushing into it" test points the right way when the player runs at it.
	var portal := LabPortal.new()
	portal.name = "LabPortal_L000_L001"
	node.add_child(portal)
	portal.setup_portal("LAB>L000>L001#1",
		Vector3((x0 + x1) * 0.5, y + 1.1, z - 0.28),
		Vector3(2.9, 2.3, 1.6),
		"Throw yourself through the flickering wall (sprint into it)")
	_canon_portal_pos = portal.global_position


func _add_room_partitions(kit: GeoKit, o: Vector3, room: String, wall_mat: String) -> void:
	if room in ["entry_hall", "crossroads", "column_gallery"]:
		return
	var door := [{"at": 11.0, "w": 4.4, "h": 3.1}]
	if room in ["archive", "reading_room", "shrine", "observation"]:
		kit.wall(Vector3(o.x + 1.0, o.y, o.z + 3.4),
			Vector3(o.x + 23.0, o.y, o.z + 3.4), H, 0.15, wall_mat, door)
		kit.wall(Vector3(o.x + 1.0, o.y, o.z + 20.6),
			Vector3(o.x + 23.0, o.y, o.z + 20.6), H, 0.15, wall_mat, door)
	if room in ["storage", "machinery", "observation", "shrine"]:
		kit.wall(Vector3(o.x + 3.4, o.y, o.z + 1.0),
			Vector3(o.x + 3.4, o.y, o.z + 23.0), H, 0.15, wall_mat, door)
		kit.wall(Vector3(o.x + 20.6, o.y, o.z + 1.0),
			Vector3(o.x + 20.6, o.y, o.z + 23.0), H, 0.15, wall_mat, door)


func _floor_with_slot(kit: GeoKit, o: Vector3, y: float, shaft: int, mat: String) -> void:
	# The hole in the floor IS the footprint of the ramp that fills it. The two
	# are one rectangle, so there is no uncovered strip and no unguarded drop.
	var slot := ContinuityTopology.stair_slot(shaft)
	var a := slot.position.x
	var b := slot.end.x
	var z0 := slot.position.y
	var z1 := slot.end.y
	kit.slab(o.x, o.z, o.x + a, o.z + C, y, 0.22, mat)
	kit.slab(o.x + b, o.z, o.x + C, o.z + C, y, 0.22, mat)
	kit.slab(o.x + a, o.z, o.x + b, o.z + z0, y, 0.22, mat)
	kit.slab(o.x + a, o.z + z1, o.x + b, o.z + C, y, 0.22, mat)
	# Guard the drop around the stairwell; leave z1 open for the upward ramp
	# to arrive on this floor. Every rail sits over existing slab, not the void.
	var railing := "metal"
	for lateral in [a - 0.12, b + 0.12]:
		kit.box(Vector3(o.x + lateral, y + 0.55, o.z + (z0 + z1) * 0.5),
			Vector3(0.15, 1.10, z1 - z0), railing)
	kit.box(Vector3(o.x + (a + b) * 0.5, y + 0.55, o.z + z0 - 0.12),
		Vector3(b - a, 1.10, 0.15), railing)


func _add_architecture(kit: GeoKit, o: Vector3, key: Vector3i, room: String,
		theme: String, warehouse: bool, version: int) -> void:
	var y := o.y
	var column_mat := "metal" if warehouse else "l0_wallpaper_pale"
	var prop_mat := "metal" if warehouse else "wood_floor"
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([world.seed_value, key.x, key.y, key.z, version, "props-v2"])
	# Four architectural anchor points are outside the circulation and shafts.
	# They provide repeatable local scale; each motif dresses them differently.
	var anchors := [Vector2(4.0, 3.7), Vector2(20.0, 3.7),
		Vector2(4.0, 20.3), Vector2(20.0, 20.3)]
	for n in anchors.size():
		var a: Vector2 = anchors[n]
		var x := o.x + a.x
		var z := o.z + a.y
		if room in ["column_gallery", "entry_hall", "shrine", "observation"]:
			kit.cylinder(Vector3(x, y + H * 0.5, z), 0.46, H, column_mat, 10)
			kit.box(Vector3(x, y + H - 0.23, z), Vector3(1.35, 0.38, 1.35), prop_mat, GeoKit.ALL, false)
		elif room in ["archive", "reading_room"]:
			kit.box(Vector3(x, y + 1.1, z), Vector3(2.0, 2.2, 0.63), prop_mat)
			for shelf in range(1, 4):
				kit.box(Vector3(x, y + 0.30 + 0.50 * shelf, z + 0.35),
					Vector3(1.8, 0.08, 0.16), "metal", GeoKit.ALL, false)
		elif room in ["storage", "crossroads"]:
			var box_height := rng.randf_range(0.6, 1.55)
			kit.box(Vector3(x, y + box_height * 0.5, z),
				Vector3(1.1, box_height, 1.1), prop_mat)
		elif room == "machinery":
			kit.box(Vector3(x, y + 1.1, z), Vector3(1.45, 2.2, 0.78), "metal")
			kit.box(Vector3(x, y + 1.75, z + 0.43),
				Vector3(0.82, 0.24, 0.1), "panel", GeoKit.ALL, false)
		else:
			kit.cylinder(Vector3(x, y + 0.7, z), 0.50, 1.4, column_mat, 8)
	# Suspended beams, ceiling lights, and ribs introduce scale while remaining
	# above head clearance; they are purely visual and no-collision.
	for i in 3:
		var zline := o.z + 4.5 + 7.5 * float(i)
		kit.box(Vector3(o.x + C * 0.5, y + H - 0.13, zline),
			Vector3(C - 2.0, 0.23, 0.30), column_mat, GeoKit.ALL, false)
	# Visual macro-landmark: enormous colonnade/rail crown in one out of four
	# geographic quadrants, without removing any walkable floor or stairs.
	if room == "entry_hall" or room == "column_gallery":
		for xpos in [3.5, 20.5]:
			kit.box(Vector3(o.x + xpos, y + H - 0.42, o.z + 12.0),
				Vector3(0.55, 0.65, 14.0), column_mat, GeoKit.ALL, false)
	if room == "observation":
		for xpos in [7.0, 17.0]:
			kit.box(Vector3(o.x + xpos, y + 0.08, o.z + 3.3),
				Vector3(2.3, 0.16, 1.2), "wood_floor", GeoKit.ALL, false)
	if room == "shrine":
		kit.box(Vector3(o.x + 12.0, y + H - 0.5, o.z + 12.0),
			Vector3(3.2, 0.34, 3.2), "metal", GeoKit.ALL, false)
	if warehouse:
		for xpos in [3.1, 20.9]:
			kit.box(Vector3(o.x + xpos, y + H - 0.40, o.z + 12.0),
				Vector3(0.32, 0.32, 16.0), "metal", GeoKit.ALL, false)
	# Coherent 4x4 chunk neighbourhood treatments. All of these are
	# non-colliding and overhead so they cannot alter topology or stair access.
	match theme:
		"vaulted_offices", "structural_gallery":
			for zpos in [5.0, 12.0, 19.0]:
				kit.box(Vector3(o.x + 12.0, y + H - 0.45, o.z + zpos),
					Vector3(18.0, 0.63, 0.60), column_mat, GeoKit.ALL, false)
		"abandoned_archive":
			for zpos in [3.3, 20.7]:
				for xpos in [7.0, 17.0]:
					kit.box(Vector3(o.x + xpos, y + H - 0.50, o.z + zpos),
						Vector3(4.0, 0.45, 0.45), "wood_floor", GeoKit.ALL, false)
		"service_annex", "pipeworks", "maintenance":
			for xpos in [3.0, 21.0]:
				kit.box(Vector3(o.x + xpos, y + H - 0.55, o.z + 12.0),
					Vector3(0.38, 0.38, 18.0), "metal", GeoKit.ALL, false)
		"concrete_warehouse", "loading_bay":
			for xpos in [5.0, 19.0]:
				kit.box(Vector3(o.x + xpos, y + H - 0.5, o.z + 12.0),
					Vector3(0.65, 0.8, 18.0), "concrete", GeoKit.ALL, false)
		"silent_quarters":
			for zpos in [3.0, 21.0]:
				kit.box(Vector3(o.x + 12.0, y + H - 0.22, o.z + zpos),
					Vector3(18.0, 0.30, 1.0), "l0_ceiling", GeoKit.ALL, false)
		_:
			pass
	# Primary shared traversal contracts are NEVER generated from room RNG
	# or mutable version counters.


func _add_lighting(kit: GeoKit, node: Node3D, o: Vector3, key: Vector3i,
		room: String, theme: String, warehouse: bool) -> void:
	var cold := warehouse or room == "machinery"
	var macro_anchor := ContinuityTopology.macro_anchor(key)
	var relay_on := bool(world.change_of(macro_anchor, "relay_active", false))
	var survey_anchor := ContinuityTopology.super_anchor(key)
	var survey_on := bool(world.change_of(survey_anchor, "network_online", false))
	for i in 2:
		var x := o.x + 7.0 + 10.0 * float(i)
		var z := o.z + 12.0
		kit.panel(Vector3(x, o.y + H - 0.08, z), 2.0, 0.55, "panel")
		var light := OmniLight3D.new()
		light.position = Vector3(x, o.y + H - 0.50, z)
		light.light_color = Color(0.70, 0.86, 1.0) if cold else Color(1.0, 0.92, 0.69)
		if ContinuityTopology.is_macro_core(key):
			light.light_energy = 1.35 if relay_on else 0.38
		elif ContinuityTopology.is_super_spine(key):
			light.light_energy = 1.45 if survey_on else 0.52
		else:
			light.light_energy = 0.55 if theme == "silent_quarters" else 0.9
		light.omni_range = 12.0
		light.shadow_enabled = false
		node.add_child(light)
	if ContinuityTopology.has_landmark(world.seed_value, key):
		kit.panel(Vector3(o.x + 12.0, o.y + H - 0.09, o.z + 18.0), 1.2, 1.2, "panel")


func _add_discovery(kit: GeoKit, node: Node3D, key: Vector3i,
		o: Vector3, y: float) -> void:
	if bool(world.change_of(key, "discovered", false)):
		return
	var loc := Vector3(o.x + 12.0, y + 0.56, o.z + 18.0)
	# No solid prop in the guaranteed circulation. The interaction layer has
	# a raycast hitbox but blocks neither walking nor stair access.
	kit.box(Vector3(loc.x, y + 0.24, loc.z),
		Vector3(0.8, 0.48, 0.8), "metal", GeoKit.ALL, false)
	kit.box(Vector3(loc.x, y + 0.50, loc.z),
		Vector3(0.45, 0.04, 0.34), "wood_floor", GeoKit.ALL, false)
	var item := Interactable.new()
	node.add_child(item)
	item.setup(loc, Vector3(0.85, 1.1, 0.85),
		"Recover: " + ContinuityTopology.discovery_label(world.seed_value, key),
		func() -> void: _collect_discovery(key))


func _collect_discovery(key: Vector3i) -> void:
	if bool(world.change_of(key, "discovered", false)):
		return
	world.set_change(key, "discovered", true)
	world.call_deferred("refresh_chunk", key)
	var artifact := ContinuityTopology.discovery_label(world.seed_value, key)
	Overlay.show_note(artifact,
		"WORLD LAB — NON-CANON. Recovered in chunk %s, floor %d. " % [
		ContinuityTopology.encode(key), key.y] +
		"The architecture changes with the seed. This discovery persists after restart.")


func _process(delta: float) -> void:
	if _capture_shot_countdown > 0:
		_capture_shot()
	if player == null:
		return
	# Load the destination of the canonical route while the player is still
	# walking towards it, so the fold itself is a cache hit and costs nothing.
	if not _canon_prefetched and _canon_portal_pos != Vector3.ZERO:
		if player.global_position.distance_to(_canon_portal_pos) < 16.0:
			_canon_prefetched = true
			var coordinator := WorldCoordinator.ensure(get_tree())
			if coordinator != null:
				coordinator.prefetch_scene("res://levels/L001/L001.tscn")
	var key := world.key_at(player.global_position)
	if key != _near_key:
		_near_key = key
		_current_district = ContinuityTopology.zone_id(world.seed_value, key)
		if not bool(world.change_of(key, "visited", false)):
			world.set_change(key, "visited", true)
		_update_map()
	_hud_clock += delta
	if _hud_clock > 0.18:
		_hud_clock = 0.0
		var room := ContinuityTopology.room_type(world.seed_value, key, world.version_of(key))
		var region := ContinuityTopology.macro_theme(world.seed_value, key)
		var structure := ContinuityTopology.macro_structure(world.seed_value, key)
		var supertype := ContinuityTopology.super_type(world.seed_value, key)
		var plan := RegionalPlan.chunk_plan(world.seed_value, key)
		var address := WorldAddress.from_position(world.world_id, _current_district,
			player.global_position)
		var geom := _loaded_geometry_totals()
		_hud.text = "CONTINUITY LAB v5 | %s · %s / %s\n8x8 REGION %s | 4x4 %s | Chunk %s | seed %d\nROLE %s | STRUCTURE %s %s | ADDRESS %s\nLoaded %d / visited %d | triangles %d / colliders %d\nF2 locate next hub | F8 map | F9 mark | F4 reshape | F5/F6 seeds | F10 menu" % [
			_current_district, region, room, supertype, structure,
			ContinuityTopology.encode(key), world.seed_value,
			plan["role"], plan["structure_id"], plan["structure_kind"],
			address.encode(),
			world.chunks.size(), _explored_count(), geom.x, geom.y]


func _loaded_geometry_totals() -> Vector2i:
	var tris := 0
	var colliders := 0
	for entry in world.chunks.values():
		var metadata: Dictionary = entry.get("meta", {})
		tris += int(metadata.get("triangles", 0))
		colliders += int(metadata.get("colliders", 0))
	return Vector2i(tris, colliders)


func _explored_count() -> int:
	var count := 0
	for v in world.chunk_changes.values():
		if v is Dictionary and bool(v.get("visited", false)):
			count += 1
	return count


func _update_map() -> void:
	if _map == null:
		return
	var lines := ["EXPLORED  H hub / = spine / B megastructure / A atrium / * clue / M marker"]
	for dz in range(-4, 5):
		var line := ""
		for dx in range(-4, 5):
			var k := _near_key + Vector3i(dx, 0, dz)
			var symbol := "·"
			if bool(world.change_of(k, "visited", false)):
				if ContinuityTopology.is_superhub(k):
					symbol = "H"
				elif ContinuityTopology.has_atrium(world.seed_value, k):
					symbol = "A"
				elif ContinuityTopology.is_super_spine(k):
					symbol = "="
				elif not RegionalPlan.structure_of(world.seed_value, k).is_empty():
					symbol = "B"
				else:
					symbol = "*" if ContinuityTopology.has_landmark(world.seed_value, k) else "+"
			if bool(world.change_of(k, "marked", false)):
				symbol = "M"
			if k == _near_key:
				symbol = "@"
			line += symbol + " "
		lines.append(line)
	lines.append("Floor %d / %d .. %d" % [
		_near_key.y, ContinuityTopology.MIN_FLOOR, ContinuityTopology.MAX_FLOOR])
	_map.text = "\n".join(lines)


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_F2:
			_locate_unexplored_hub()
		KEY_F10:
			_return_menu.call_deferred()
		KEY_F8:
			_map_shown = not _map_shown
			_map.visible = _map_shown
			_update_map()
		KEY_F9:
			var old := bool(world.change_of(_near_key, "marked", false))
			world.set_change(_near_key, "marked", not old)
			world.call_deferred("refresh_chunk", _near_key)
			Overlay.toast("Persistent chunk marker: %s" % ("OFF" if old else "ON"), 2.5)
		KEY_F4:
			world.call_deferred("bump_version", _near_key)
			Overlay.toast("The room has shifted. Fixed passage topology is unchanged.", 2.8)
		KEY_F5:
			_cycle_seed()
		KEY_F6:
			_new_world()


## A local, deterministic navigation aid, never a teleport or a spoiler for
## the canon story. Finds the nearest superdistrict anchor not visited yet.
func _locate_unexplored_hub() -> void:
	var p := world.key_at(player.global_position)
	var s := ContinuityTopology.super_key(p)
	var best := Vector3i.ZERO
	var best_score := 99999999
	var found := false
	for sz in range(s.z - 3, s.z + 4):
		for sx in range(s.x - 3, s.x + 4):
			var candidate := ContinuityTopology.super_anchor(Vector3i(sx * 8, 0, sz * 8))
			if bool(world.change_of(candidate, "visited", false)):
				continue
			var ddx := candidate.x - p.x
			var ddz := candidate.z - p.z
			var score := ddx * ddx + ddz * ddz
			if score < best_score:
				best = candidate
				best_score = score
				found = true
	if not found:
		Overlay.toast("All survey hubs within three superdistricts have been visited.", 3.0)
		return
	var direction := Vector2(float(best.x - p.x), float(best.z - p.z))
	var bearing := "east" if absf(direction.x) >= absf(direction.y) and direction.x >= 0 else \
		("west" if absf(direction.x) >= absf(direction.y) else \
		("north" if direction.y >= 0 else "south"))
	Overlay.show_note("SURVEY SIGNAL — " + bearing.to_upper(),
		"Unvisited central transit hub near chunk %s, about %d metres away horizontally. " % [
		ContinuityTopology.encode(best), int(sqrt(float(best_score)) * C)] +
		"It belongs to a 192m-wide 8x8 area. Find the main corridor and follow it; " +
		"no teleport is performed. This is an experimental navigation aid.")


func _new_world() -> void:
	# Never overwrite another world's data: every seed has its own save file.
	var next_seed := absi(hash([Time.get_ticks_usec(), randi()])) % 2000000000 + 1
	if next_seed == world.seed_value:
		next_seed += 1
	_register_seed(next_seed)
	Overlay.toast("Creating lab seed %d; older seeds remain selectable by F5" % next_seed, 3.0)
	_switch_seed(next_seed)


func _on_dead(_cause: String) -> void:
	player.dead = false
	player.health = 100.0
	player.global_position = Vector3(11.0, 0.14, 11.0)
	player.velocity = Vector3.ZERO


func _return_menu() -> void:
	world.save_to_disk()
	SessionState.in_gameplay = false
	SessionState.release_mouse()
	get_tree().change_scene_to_file("res://ui/MainMenu.tscn")
