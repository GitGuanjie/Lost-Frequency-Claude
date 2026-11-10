class_name ChunkWorld
extends Node3D
## Deterministic streamed chunks for canonically vast levels. A level supplies
## `builder(cx, cz, version, node) -> Dictionary` and optionally
## `can_shift(key, meta) -> bool`. The playable world is a finite streaming
## window with stable coordinates; canonical infinity is never simulated.
## Peripheral-shift support: a chunk unobserved for `shift_after` seconds (not
## in the camera frustum, not containing the player) may be rebuilt with a new
## version, so the layout changes only when nobody is looking.

signal chunk_built(key: Vector2i, meta: Dictionary)
signal chunk_shifted(key: Vector2i, version: int)
signal chunk_unloaded(key: Vector2i)

var chunk_size := 24.0
var radius := 2
var unload_radius := 3
var builder: Callable
var can_shift: Callable
var shift_enabled := false
var shift_after := 9.0
var builds_per_frame := 1
var target: Node3D
var chunks: Dictionary = {}      # Vector2i -> {node, version, unseen, meta}
var versions: Dictionary = {}    # Vector2i -> int, survives unload
var shift_count := 0
var _queue: Array = []
var persistence_key := ""  # opt-in, preserves existing levels by default
var _persistent_state: Dictionary = {}


func _ready() -> void:
	if persistence_key != "":
		var scope := SaveService.scope()
		if not scope.has("chunk_worlds"):
			scope["chunk_worlds"] = {}
		var all_worlds: Dictionary = scope["chunk_worlds"]
		if not all_worlds.has(persistence_key):
			all_worlds[persistence_key] = {"versions": {}, "changes": {}}
		_persistent_state = all_worlds[persistence_key]
		if not _persistent_state.has("versions"):
			_persistent_state["versions"] = {}
		if not _persistent_state.has("changes"):
			_persistent_state["changes"] = {}
		for id in _persistent_state["versions"].keys():
			var parts: PackedStringArray = str(id).split(":")
			if parts.size() != 2:
				continue
			versions[Vector2i(int(parts[0]), int(parts[1]))] = int(_persistent_state["versions"][id])


func change_of(k: Vector2i, name: String, fallback: Variant = null) -> Variant:
	if persistence_key == "":
		return fallback
	return _persistent_state.get("changes", {}).get("%d:%d" % [k.x, k.y], {}).get(name, fallback)


func set_change(k: Vector2i, name: String, value: Variant) -> void:
	if persistence_key == "":
		return
	var id := "%d:%d" % [k.x, k.y]
	var changes: Dictionary = _persistent_state["changes"]
	if not changes.has(id):
		changes[id] = {}
	changes[id][name] = value



func key_at(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / chunk_size), floori(p.z / chunk_size))


func chunk_origin(k: Vector2i) -> Vector3:
	return Vector3(k.x * chunk_size, 0, k.y * chunk_size)


func meta_of(k: Vector2i) -> Dictionary:
	return chunks.get(k, {}).get("meta", {})


## Build everything within radius immediately (spawn, QA, captures).
func build_around(p: Vector3, r: int = -1) -> void:
	if r < 0:
		r = radius
	var c := key_at(p)
	for dz in range(-r, r + 1):
		for dx in range(-r, r + 1):
			var k := c + Vector2i(dx, dz)
			if not chunks.has(k):
				_build(k)


func _build(k: Vector2i) -> void:
	var v: int = versions.get(k, 0)
	var n := Node3D.new()
	n.name = "C_%d_%d_v%d" % [k.x, k.y, v]
	add_child(n)
	var meta: Dictionary = builder.call(k.x, k.y, v, n)
	chunks[k] = {"node": n, "version": v, "unseen": 0.0, "meta": meta}
	chunk_built.emit(k, meta)


func _unload(k: Vector2i) -> void:
	var c: Dictionary = chunks.get(k, {})
	if c.has("node") and is_instance_valid(c["node"]):
		c["node"].queue_free()
	chunks.erase(k)
	chunk_unloaded.emit(k)


func rebuild(k: Vector2i, bump_version: bool) -> void:
	if bump_version:
		versions[k] = int(versions.get(k, 0)) + 1
		if persistence_key != "":
			_persistent_state["versions"]["%d:%d" % [k.x, k.y]] = versions[k]
	_unload(k)
	_build(k)


func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target) or builder.is_null():
		return
	var pc := key_at(target.global_position)
	# queue missing chunks nearest-first
	_queue.clear()
	for dz in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			var k := pc + Vector2i(dx, dz)
			if not chunks.has(k):
				_queue.append(k)
	_queue.sort_custom(func(a, b): return (a - pc).length_squared() < (b - pc).length_squared())
	for i in mini(builds_per_frame, _queue.size()):
		_build(_queue[i])
	for k in chunks.keys():
		var d: Vector2i = k - pc
		if absi(d.x) > unload_radius or absi(d.y) > unload_radius:
			_unload(k)
	if shift_enabled:
		_peripheral_shift(delta, pc)


func _peripheral_shift(delta: float, pc: Vector2i) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var planes := cam.get_frustum()
	var tp := target.global_position
	for k in chunks.keys():
		var c: Dictionary = chunks[k]
		var o := chunk_origin(k)
		var aabb := AABB(o + Vector3(-1, -2, -1), Vector3(chunk_size + 2, 8, chunk_size + 2))
		var contains_player := aabb.grow(1.5).has_point(Vector3(tp.x, o.y + 1.0, tp.z))
		if contains_player or k == pc or _aabb_in_frustum(aabb, planes):
			c["unseen"] = 0.0
			continue
		c["unseen"] += delta
		if c["unseen"] >= shift_after:
			c["unseen"] = 0.0
			if can_shift.is_valid() and not can_shift.call(k, c["meta"]):
				continue
			rebuild(k, true)
			shift_count += 1
			chunk_shifted.emit(k, versions[k])
			return  # at most one shift per frame


static func _aabb_in_frustum(aabb: AABB, planes: Array) -> bool:
	for pl in planes:
		var plane: Plane = pl
		var all_out := true
		for i in 8:
			if not plane.is_point_over(aabb.get_endpoint(i)):
				all_out = false
				break
		if all_out:
			return false
	return true
