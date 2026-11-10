class_name ChunkWorld3D
extends Node3D
## Streaming three-dimensional chunks, positive and negative coordinates.
## Builder contract: build_chunk(cx:int, cy:int, cz:int, version:int, node:Node3D)
## returns Dictionary. This class does NOT modify existing ChunkWorld clients.
## A chunk's geometry is regenerated on demand, not held globally.

signal chunk_built(key: Vector3i, meta: Dictionary)
signal chunk_unloaded(key: Vector3i)

var target: Node3D
var builder: Callable
var radius_xz := 1
var radius_y := 1
var unload_xz := 2
var unload_y := 2
var builds_per_frame := 2
## Time budget for chunk construction in one frame, in milliseconds. A fixed
## chunk count per frame stalls badly when one chunk happens to be expensive;
## a time budget keeps the frame time flat whatever the chunk contains.
var build_budget_ms := 6.0
var world_id := "continuity_lab"
var disk_persistence_enabled := false  # Lab-only opt-in, not used in QA or story
var disk_path := "user://continuity_lab/world.json"
var chunks: Dictionary = {} # Vector3i -> {node, meta}
var seed_value := 1337
var chunk_versions: Dictionary = {}  # stored as JSON string keys
var chunk_changes: Dictionary = {}  # stored as JSON string keys
var _store: Dictionary = {}
var _fallback_scope: Dictionary = {}
var _last_center := Vector3i(999999, 999999, 999999)
var _dirty := false
var _save_clock := 0.0
var _plan_cache: Dictionary = {}
## True while a chunk node is being attached to the tree. A parent that is
## adding a child may not remove another child at the same moment.
var _adding_child := false
const AUTOSAVE_SECONDS := 12.0
## Bumped whenever the generator changes the shape of a world. A save written
## by an older generator is migrated instead of being silently reinterpreted.
const GENERATOR_VERSION := 5
const SAVE_SCHEMA := 2
var stream_stats := {"built": 0, "unloaded": 0, "planned": 0, "peak_chunks": 0}


func _ready() -> void:
	attach_save_scope()
	if disk_persistence_enabled:
		_load_disk()


## The SaveService autoload is resolved at RUNTIME, never as a compile-time
## identifier. Headless `--script` runs (the native topology tests) have no
## autoloads at all, and a hard reference made this class unloadable there:
## the script failed to compile and the test tree then never reached quit().
static func _save_service() -> Object:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		var tree := loop as SceneTree
		if tree.root != null:
			return tree.root.get_node_or_null(^"SaveService")
	return null


## Active save scope: the story/dev dictionary from SaveService when the
## autoload exists, otherwise a private in-memory scope for standalone use.
func _scope() -> Dictionary:
	var service := _save_service()
	if service != null and service.has_method("scope"):
		var scope: Variant = service.call("scope")
		if scope is Dictionary:
			return scope
	return _fallback_scope


## Persist in the *current* scoped SaveService dictionary. Developer / QA
## state never touches story saves, exactly like the base project's dev mode.
func attach_save_scope() -> void:
	var scope := _scope()
	if not scope.has("chunk_worlds"):
		scope["chunk_worlds"] = {}
	var worlds: Dictionary = scope["chunk_worlds"]
	if not worlds.has(world_id):
		worlds[world_id] = {"seed": seed_value, "versions": {}, "changes": {}}
	_store = worlds[world_id]
	seed_value = int(_store.get("seed", seed_value))
	if not _store.has("versions"):
		_store["versions"] = {}
	if not _store.has("changes"):
		_store["changes"] = {}
	chunk_versions = _store["versions"]
	chunk_changes = _store["changes"]


## Pure structural plan for a chunk, cached. The plan is a pure function of
## the seed and the coordinates, so it can be computed off the critical path
## and reused for every rebuild of the same chunk.
func plan_for(k: Vector3i) -> Dictionary:
	var key := ContinuityTopology.encode(k)
	if _plan_cache.has(key):
		return _plan_cache[key]
	var plan := RegionalPlan.chunk_plan(seed_value, k)
	_plan_cache[key] = plan
	stream_stats["planned"] = int(stream_stats["planned"]) + 1
	return plan


func key_at(p: Vector3) -> Vector3i:
	return ContinuityTopology.key_for(p)


func meta_of(k: Vector3i) -> Dictionary:
	return chunks.get(k, {}).get("meta", {})


func version_of(k: Vector3i) -> int:
	return int(chunk_versions.get(ContinuityTopology.encode(k), 0))


func change_of(k: Vector3i, name: String, fallback: Variant = null) -> Variant:
	return chunk_changes.get(ContinuityTopology.encode(k), {}).get(name, fallback)


func set_change(k: Vector3i, name: String, value: Variant) -> void:
	var sk := ContinuityTopology.encode(k)
	if not chunk_changes.has(sk):
		chunk_changes[sk] = {}
	if chunk_changes[sk].get(name) == value:
		return
	chunk_changes[sk][name] = value
	_dirty = true
	# Periodic dirty writes avoid serializing the full world on every visited
	# chunk; the menu, seed switch and window-close paths flush immediately.


## Redraw a mutated chunk without changing its layout generation version.
func refresh_chunk(k: Vector3i) -> void:
	if chunks.has(k):
		_unload(k)
		_build(k)


func bump_version(k: Vector3i) -> void:
	var sk := ContinuityTopology.encode(k)
	chunk_versions[sk] = version_of(k) + 1
	_dirty = true
	if disk_persistence_enabled:
		save_to_disk()
	refresh_chunk(k)


func build_around(p: Vector3, horiz: int = -1, vertical: int = -1) -> void:
	var center := key_at(p)
	var hx := radius_xz if horiz < 0 else horiz
	var hy := radius_y if vertical < 0 else vertical
	var wanted := _desired(center, hx, hy)
	for k in wanted:
		if not chunks.has(k):
			_build(k)


## Chunks are wanted nearest first, and the chunks the player is heading
## towards are wanted sooner than the ones behind. Nothing here changes the
## content of a chunk, only the order in which it appears.
func _desired(center: Vector3i, hx: int, hy: int) -> Array:
	var result: Array = []
	for dy in range(-hy, hy + 1):
		for dz in range(-hx, hx + 1):
			for dx in range(-hx, hx + 1):
				var key := center + Vector3i(dx, dy, dz)
				if ContinuityTopology.between_floors(key):
					result.append(key)
	var forward := Vector3.ZERO
	if target != null and is_instance_valid(target):
		for body in target.get_children():
			if body is CharacterBody3D:
				var v: Vector3 = (body as CharacterBody3D).velocity
				v.y = 0.0
				if v.length() > 0.4:
					forward = v.normalized()
				break
	result.sort_custom(func(a, b):
		var pa: Vector3i = a - center
		var pb: Vector3i = b - center
		var da := pa.x * pa.x + pa.z * pa.z + 2 * pa.y * pa.y
		var db := pb.x * pb.x + pb.z * pb.z + 2 * pb.y * pb.y
		if forward != Vector3.ZERO:
			var ba := Vector3(float(pa.x), 0.0, float(pa.z)).normalized()
			var bb := Vector3(float(pb.x), 0.0, float(pb.z)).normalized()
			da -= ba.dot(forward) * 6.0
			db -= bb.dot(forward) * 6.0
		return da < db)
	return result


func _build(k: Vector3i) -> void:
	if chunks.has(k) or builder.is_null() or not ContinuityTopology.between_floors(k):
		return
	var n := Node3D.new()
	n.name = "World_%d_%d_%d" % [k.x, k.y, k.z]
	_adding_child = true
	add_child(n)
	_adding_child = false
	var meta: Dictionary = builder.call(k.x, k.y, k.z, version_of(k), n)
	chunks[k] = {"node": n, "meta": meta}
	# The counter has to be advanced HERE. It was declared in `stream_stats`
	# but never incremented, so every measurement that read it reported zero
	# builds while the streamer was in fact building chunks. A counter that
	# is always zero is indistinguishable from a broken instrument.
	stream_stats["built"] = int(stream_stats["built"]) + 1
	chunk_built.emit(k, meta)


func _unload(k: Vector3i) -> void:
	if not chunks.has(k):
		return
	var n: Node3D = chunks[k]["node"]
	chunks.erase(k)
	stream_stats["unloaded"] = int(stream_stats["unloaded"]) + 1
	chunk_unloaded.emit(k)
	if not is_instance_valid(n):
		return
	# The chunk is detached from the live world at once: it is hidden and its
	# collision is switched off before the free queue removes it at the end
	# of the frame. A parent that is busy adding or removing another child may
	# not remove one right now, which is why the tree bookkeeping is left to
	# queue_free instead of an explicit remove_child.
	n.visible = false
	for node in n.find_children("*", "CollisionObject3D", true, false):
		var body := node as CollisionObject3D
		body.collision_layer = 0
		body.collision_mask = 0
	n.queue_free()


func _process(delta: float) -> void:
	if disk_persistence_enabled and _dirty:
		_save_clock += delta
		if _save_clock >= AUTOSAVE_SECONDS:
			save_to_disk()
	if target == null or not is_instance_valid(target) or builder.is_null():
		return
	var center := key_at(target.global_position)
	var missing := _desired(center, radius_xz, radius_y)
	# Time budgeted construction: the chunk that would blow the budget is
	# simply built on the next frame. The order of `missing` already puts the
	# most relevant chunk first, so a chunk the player walked away from is
	# cancelled before it is ever created.
	var started := Time.get_ticks_usec()
	var built := 0
	for k in missing:
		if chunks.has(k):
			continue
		if built >= builds_per_frame:
			break
		if built > 0 and float(Time.get_ticks_usec() - started) / 1000.0 > build_budget_ms:
			break
		_build(k)
		built += 1
	for k in chunks.keys():
		var dx: int = absi(k.x - center.x)
		var dz: int = absi(k.z - center.z)
		var dy: int = absi(k.y - center.y)
		if dx > unload_xz or dz > unload_xz or dy > unload_y:
			_unload(k)
	stream_stats["peak_chunks"] = maxi(int(stream_stats["peak_chunks"]), chunks.size())
	_last_center = center


## The separate developer-lab save is persistent across process restarts. Do
## not rewrite the canonical story checkpoint or the game's world seed.
##
## The save records the generator version that wrote it. When the generator
## changed shape, the world seed is kept (the same seed must still describe
## the same place) but the per-chunk layout versions are reset, because a
## version counter only means something inside the generator that wrote it.
func _load_disk() -> void:
	var candidate: Variant = null
	for name in [disk_path, disk_path + ".bak"]:
		if not FileAccess.file_exists(name):
			continue
		var content := FileAccess.get_file_as_string(name)
		var decoded: Variant = JSON.parse_string(content)
		if decoded is Dictionary and decoded.get("world_id", "") == world_id \
				and decoded.get("versions") is Dictionary and decoded.get("changes") is Dictionary:
			candidate = decoded
			break
	if candidate == null:
		return
	var stored_seed := int(candidate.get("seed", seed_value))
	var stored_generator := int(candidate.get("generator_version", 0))
	if stored_seed != seed_value:
		# A different world in the same file: never mix two seeds.
		_plan_cache.clear()
	seed_value = stored_seed
	chunk_versions.clear()
	chunk_changes.clear()
	for key in candidate["versions"].keys():
		chunk_versions[key] = int(candidate["versions"][key])
	for key in candidate["changes"].keys():
		if candidate["changes"][key] is Dictionary:
			chunk_changes[key] = candidate["changes"][key]
	if stored_generator != GENERATOR_VERSION:
		chunk_versions.clear()
		_store["migrated_from_generator"] = stored_generator
		_store["migrated_to_generator"] = GENERATOR_VERSION
	_plan_cache.clear()
	_store["seed"] = seed_value
	_dirty = false


func save_to_disk() -> bool:
	if not disk_persistence_enabled:
		return false
	var abs_path := ProjectSettings.globalize_path(disk_path)
	var err := DirAccess.make_dir_recursive_absolute(abs_path.get_base_dir())
	if err != OK:
		push_warning("Continuity lab: cannot create save directory")
		return false
	var payload := JSON.stringify({"schema": SAVE_SCHEMA, "world_id": world_id,
		"seed": seed_value, "generator_version": GENERATOR_VERSION,
		"versions": chunk_versions, "changes": chunk_changes})
	var temp := disk_path + ".tmp"
	var f := FileAccess.open(temp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(payload)
	f.flush()
	f.close()
	var check: Variant = JSON.parse_string(FileAccess.get_file_as_string(temp))
	if not (check is Dictionary) or check.get("world_id", "") != world_id:
		return false
	if FileAccess.file_exists(disk_path):
		if FileAccess.file_exists(disk_path + ".bak"):
			DirAccess.remove_absolute(abs_path + ".bak")
		if DirAccess.rename_absolute(abs_path, abs_path + ".bak") != OK:
			return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), abs_path) != OK:
		# Backup remains loadable if rename failed.
		return false
	_dirty = false
	_save_clock = 0.0
	return true


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if disk_persistence_enabled and _dirty:
			save_to_disk()
