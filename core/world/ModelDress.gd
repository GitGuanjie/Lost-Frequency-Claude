extends RefCounted
## Curated low-poly decoration layer for CC0 Kenney GLB packs.
## The original GeoKit architecture remains authoritative for walkability,
## exits, navigation and existing collision. GLB props are decorative by
## default, and only explicitly authorised off-route props gain collision.
## Chunked levels call decorate_chunk() from their chunk builder, so instances
## are freed when their owner chunk is unloaded.

const CATALOG := "res://assets/packs/catalog.json"
const RECIPES := "res://data/model_dressings.json"
static var _catalog: Dictionary = {}
static var _recipes: Dictionary = {}
static var _scenes: Dictionary = {}
static var _placements_by_chunk: Dictionary = {}
static var _static_placements: Dictionary = {}
static var missing_paths: Dictionary = {}

static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("ModelDress: missing " + path)
		return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary:
		return data
	return {}

static func _data_ready() -> void:
	if _catalog.is_empty():
		_catalog = _read_json(CATALOG).get("models", {})
	if _recipes.is_empty():
		_recipes = _read_json(RECIPES).get("levels", {})
		# An indexed recipe avoids scanning all 466 placements for EVERY streamed
		# chunk and keeps each model's owner tied to its chunk's lifecycle.
		for level_id in _recipes:
			var static_batch: Array = []
			var chunk_batches: Dictionary = {}
			for item in _recipes[level_id]:
				if not (item is Dictionary):
					continue
				if str(item.get("scope", "static")) == "chunk":
					var ck := "%d,%d" % [int(item.get("cx", 0)), int(item.get("cz", 0))]
					if not chunk_batches.has(ck):
						chunk_batches[ck] = []
					chunk_batches[ck].append(item)
				else:
					static_batch.append(item)
			_static_placements[level_id] = static_batch
			_placements_by_chunk[level_id] = chunk_batches

static func decorate(level: Node3D, level_id: String) -> int:
	return _apply(level, level, level_id, "static", 0, 0)

static func decorate_chunk(level: Node3D, owner: Node3D, level_id: String, cx: int, cz: int) -> int:
	return _apply(level, owner, level_id, "chunk", cx, cz)

static func _apply(level: Node3D, owner: Node3D, level_id: String, scope: String, cx: int, cz: int) -> int:
	_data_ready()
	var batch: Array = []
	if scope == "chunk":
		batch = _placements_by_chunk.get(level_id, {}).get("%d,%d" % [cx, cz], [])
	else:
		batch = _static_placements.get(level_id, [])
	var count := 0
	for item in batch:
		if _place(level, owner, item):
			count += 1
	return count

static func _place(level: Node3D, owner: Node3D, item: Dictionary) -> bool:
	# The asset gallery calls _place() directly; initialise the index here too.
	_data_ready()
	var path := "res://assets/packs/%s/%s.glb" % [str(item.get("pack", "")), str(item.get("model", ""))]
	if not _catalog.has(path.trim_prefix("res://")):
		push_warning("ModelDress: unindexed asset " + path)
		return false
	if not ResourceLoader.exists(path):
		if not missing_paths.has(path):
			missing_paths[path] = true
			push_warning("ModelDress: import missing " + path)
		return false
	var scene: PackedScene = _scenes.get(path, null)
	if scene == null:
		scene = load(path) as PackedScene
		if scene == null:
			return false
		_scenes[path] = scene
	var model: Node3D = scene.instantiate() as Node3D
	if model == null:
		return false
	var d: Dictionary = _catalog[path.trim_prefix("res://")]
	var lower: Array = d["min"]
	var upper: Array = d["max"]
	var span: Array = d["size"]
	var h: float = float(item.get("height", 1.0))
	# Bounds measured from the actual GLB scene graph (including node transforms),
	# not guessed from filenames. Prevent near-flat props from huge upscaling.
	var factor: float = minf(8.0, h / maxf(0.18, float(span[1])))
	var anchor := Node3D.new()
	anchor.name = "GLB_%s" % str(item["model"])
	var xyz: Array = item.get("pos", [0.0, 0.0, 0.0])
	anchor.position = Vector3(float(xyz[0]), float(xyz[1]), float(xyz[2]))
	anchor.rotation.y = deg_to_rad(float(item.get("yaw", 0.0)))
	# readable unique names: duplicates become GLB_<model>2, GLB_<model>3 ... (keeps the GLB_ prefix)
	owner.add_child(anchor, true)
	model.name = "Visual"
	anchor.add_child(model)
	model.scale = Vector3.ONE * factor
	model.position = Vector3(-(float(lower[0]) + float(upper[0])) * 0.5, -float(lower[1]), -(float(lower[2]) + float(upper[2])) * 0.5) * factor
	# Optional explicit simple collision only for off-route objects. No trimesh
	# generated collisions and no physics shapes for plates, books or small props.
	if bool(item.get("solid", false)):
		var body := StaticBody3D.new()
		body.name = "OffRouteCollision"
		body.collision_layer = 1
		var box := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(float(span[0]), float(span[1]), float(span[2])) * factor
		box.shape = shape
		box.position.y = float(span[1]) * factor * 0.5
		body.add_child(box)
		anchor.add_child(body)
	var description: String = str(item.get("inspect", ""))
	if description != "" and level is LevelBase:
		var prompt: String = str(item.get("prompt", "Inspect an abandoned object"))
		var p: Vector3 = anchor.position + Vector3(0.0, minf(h * 0.65, 1.15), 0.0)
		var trigger := (level as LevelBase).add_interactable(p, Vector3(1.6, 1.6, 1.6), prompt, func(_p): Overlay.subtitle(description, 3.5))
		# A streamed decoration must own its interaction area as well as its mesh.
		if owner != level and trigger != null:
			trigger.reparent(owner)
	return true
