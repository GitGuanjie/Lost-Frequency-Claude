class_name WorldCoordinator
extends Node
## Persistent coordinator for a transfer between two places that are not
## physically adjacent.
##
## The coordinator OWNS the wanderer. A transfer therefore does not destroy
## and re-create the player: the same `Player` node, with the same body state,
## the same light and the same inventory, is moved into the destination place.
## That is what makes a non-Euclidean fold read as one continuous session
## rather than as a level load.
##
## Three connection kinds are distinguished and are never conflated:
##
##   PHYSICAL     the two places are adjacent in space and the player simply
##                walks across. The coordinator does nothing at all.
##   NOCLIP       a non-Euclidean fold. The player is moved to a place that is
##                not adjacent, without a loading screen and without losing
##                state.
##   CANON_STORY  a documented story route. The edge, its trigger and its
##                arrival come from the canon manifests and are never invented
##                here.
##
## The destination is always a REAL level scene, loaded through the level
## registry. There is no proxy level and no stand-in: an adaptation edge names
## the canon edge it realises, and the canon edge remains the authority for the
## trigger and the arrival.
##
## Autoloads are resolved at RUNTIME, never as compile-time identifiers: a
## headless `--script` run has no autoloads, and a hard reference made the
## world classes unloadable there.

const KIND_PHYSICAL := "PHYSICAL"
const KIND_NOCLIP := "NOCLIP"
const KIND_CANON_STORY := "CANON_STORY"

const LAB_EDGE_FILE := "res://data/lab/transitions.json"

signal transfer_started(edge: Dictionary, kind: String)
signal transfer_completed(edge: Dictionary, kind: String)
signal transfer_failed(edge: Dictionary, reason: String)

## The persistent wanderer. Set by adopt().
var player: Player = null
## The carried body state of the wanderer across a transfer.
var session: Dictionary = {}
## True while a transfer is running.
var busy := false
## The edge and kind of the last completed transfer.
var last_edge: Dictionary = {}
var last_kind := ""
## How many transfers have completed. A leak of the player would show up here.
var transfer_count := 0
## The place the player was in before the last transfer.
var last_source := ""
## Destination scenes that were loaded ahead of time, keyed by scene path.
var _prefetched: Dictionary = {}


# -------------------------------------------------------------- autoloads

static func _autoload(name: String) -> Object:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		var tree := loop as SceneTree
		if tree.root != null:
			return tree.root.get_node_or_null(NodePath(name))
	return null


func _registry() -> Object:
	return _autoload("LevelRegistry")


func _transitions() -> Object:
	return _autoload("TransitionService")


# -------------------------------------------------------------- singleton

## The coordinator lives under the scene-tree root, so it survives a scene
## change. There is exactly one per session.
static func ensure(tree: SceneTree) -> WorldCoordinator:
	if tree == null:
		return null
	for child in tree.root.get_children():
		if child is WorldCoordinator:
			return child
	var c := WorldCoordinator.new()
	c.name = "WorldCoordinator"
	c.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(c)
	return c


# ------------------------------------------------------------------ player

## Take ownership of a player node. The player is not moved here; it is moved
## at the moment of a transfer.
func adopt(p: Player) -> void:
	player = p
	capture_session()


## Snapshot the body state that must survive a fold.
func capture_session() -> Dictionary:
	session = {}
	if player == null or not is_instance_valid(player):
		return session
	session["flashlight"] = player.flashlight != null and player.flashlight.visible
	session["crouching"] = player.crouching
	session["pitch"] = player.look_pitch
	session["local_velocity"] = player.global_transform.basis.inverse() * player.velocity
	session["position"] = player.global_position
	return session


## Put the carried body state back on the player, subject to the destination's
## own rules: a destination that forbids a light keeps it dark.
func restore_session(p: Player, carried: Dictionary) -> void:
	if p == null or not is_instance_valid(p):
		return
	if p.flashlight != null:
		var allowed: bool = p.flashlight_policy in ["allowed", "weak"]
		p.flashlight.visible = allowed and bool(carried.get("flashlight", false))
	p.crouching = bool(carried.get("crouching", false))
	p.look_pitch = float(carried.get("pitch", 0.0))
	if p.head != null:
		p.head.rotation.x = p.look_pitch
	var lv: Vector3 = carried.get("local_velocity", Vector3.ZERO)
	p.velocity = p.global_transform.basis * Vector3(lv.x, 0.0, lv.z) * 0.6


# ------------------------------------------------------------------- edges

## Resolve an edge id to its definition.
##
## 1. A story edge declared by a level manifest (the canon route).
## 2. A laboratory adaptation edge, which names the canon edge it realises.
##    The canon edge must exist; the adaptation may not override its trigger
##    or its arrival.
func resolve_edge(edge_id: String) -> Dictionary:
	var ts := _transitions()
	if ts != null and ts.has_method("get_edge"):
		var e: Dictionary = ts.call("get_edge", edge_id)
		if not e.is_empty():
			return e
	if not FileAccess.file_exists(LAB_EDGE_FILE):
		return {}
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(LAB_EDGE_FILE))
	if not (raw is Dictionary):
		return {}
	for x in raw.get("edges", []):
		if not (x is Dictionary):
			continue
		if str((x as Dictionary).get("id", "")) != edge_id:
			continue
		var d: Dictionary = (x as Dictionary).duplicate(true)
		d["from"] = str(d.get("from", "LAB"))
		var canon_id := str(d.get("canon_edge", ""))
		if canon_id != "":
			var canon := resolve_edge(canon_id)
			if canon.is_empty():
				push_error("WorldCoordinator: laboratory edge %s names canon edge %s, which does not exist"
					% [edge_id, canon_id])
				return {}
			d["canon_edge"] = canon_id
			d["canon_trigger"] = str(canon.get("trigger", ""))
			d["canon_basis"] = str(canon.get("basis", ""))
			d["canon_source_quote"] = str(canon.get("source_quote", ""))
			# The arrival is taken from the canon edge unless the laboratory
			# declares one that the destination also declares.
			if str(d.get("arrival", "")) == "":
				d["arrival"] = str(canon.get("arrival", ""))
		return d
	return {}


## The connection kind of an edge. An explicit kind always wins; otherwise it
## is derived from the trigger and never from the destination's name.
static func kind_for(edge: Dictionary) -> String:
	if edge.has("canon_edge"):
		return KIND_NOCLIP
	match str(edge.get("trigger", "")):
		"noclip":
			return KIND_NOCLIP
		"walk_in", "dwell", "fall", "interact":
			return KIND_CANON_STORY
	return KIND_CANON_STORY


## Refuse a kind that the edge does not support. This is what stops a
## non-Euclidean fold from being smuggled in as a physical walk, and what
## stops an adaptation edge from being passed off as a canon story route.
static func validate_kind(edge: Dictionary, kind: String) -> String:
	var trigger := str(edge.get("trigger", edge.get("canon_trigger", "")))
	match kind:
		KIND_NOCLIP:
			if trigger != "noclip":
				return "edge %s is not a noclip edge (trigger=%s)" % [str(edge.get("id", "")), trigger]
			if not edge.has("canon_edge") and str(edge.get("basis", "")) == "":
				return "edge %s has no source basis" % str(edge.get("id", ""))
		KIND_CANON_STORY:
			if edge.has("canon_edge"):
				return "edge %s is a laboratory adaptation, not a canon story edge" % str(edge.get("id", ""))
		KIND_PHYSICAL:
			return "a physical connection needs no transfer: walk across"
	return ""


# --------------------------------------------------------------- transfer

## Perform a transfer. Returns true when the player ended up in the
## destination. This is a coroutine: the caller awaits it.
func transfer(edge_id: String, kind: String = "") -> bool:
	if busy:
		push_warning("WorldCoordinator: a transfer is already running")
		return false
	busy = true
	var edge := resolve_edge(edge_id)
	if edge.is_empty():
		busy = false
		_fail({}, "unknown edge " + edge_id)
		return false
	var resolved_kind := kind if kind != "" else kind_for(edge)
	var problem := validate_kind(edge, resolved_kind)
	if problem != "":
		busy = false
		_fail(edge, problem)
		return false
	last_edge = edge
	last_kind = resolved_kind
	transfer_started.emit(edge, resolved_kind)
	var ok := await _run_transfer(edge, resolved_kind)
	busy = false
	return ok


func _run_transfer(edge: Dictionary, kind: String) -> bool:
	var registry := _registry()
	if registry == null:
		_fail(edge, "LevelRegistry autoload is not available")
		return false
	var to := str(edge.get("to", ""))
	if to == "":
		_fail(edge, "edge declares no destination")
		return false
	if not registry.call("has_level", to):
		_fail(edge, "unknown destination level " + to)
		return false
	var scene_path: String = str(registry.call("scene_path", to))
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		_fail(edge, "destination scene is missing: " + to)
		return false
	# The destination must actually declare the arrival, otherwise the player
	# would be dropped at a place that does not exist in it.
	var arrival := str(edge.get("arrival", ""))
	if arrival == "":
		arrival = "from_" + str(edge.get("from", ""))
	var impl: Dictionary = registry.call("get_entry", to).get("impl", {})
	if not (impl.get("arrivals", []) as Array).has(arrival):
		_fail(edge, "destination %s does not declare the arrival %s" % [to, arrival])
		return false

	var carried := capture_session()
	if player != null and is_instance_valid(player):
		player.velocity = Vector3.ZERO
		player.set_physics_process(false)

	# The place being left is the node that OWNS the wanderer: it owns the
	# geometry, the collision bodies and the streaming of that place.
	#
	# It is deliberately NOT taken from `get_tree().current_scene` alone. A
	# place can be a child of the tree root that is not the current scene
	# (the laboratory under test, a streamed overlay in the game). Releasing
	# the WRONG node is not a cosmetic bug: the old place stays alive, the
	# new one is created beside it, two streamed worlds share one physics
	# space, and the Jolt job system then reports "exceeded the maximum
	# number of jobs" and waits for jobs that are never released - the fold
	# never completes and the process hangs.
	var source := _source_place()
	if source != null and (source == self or source == get_tree().root):
		_fail(edge, "the place being left could not be identified")
		_unfreeze()
		return false

	# Detach the persistent wanderer from the place it is leaving. The place
	# is freed below, and the wanderer has to outlive it.
	if player != null and is_instance_valid(player) and player.get_parent() != get_tree().root:
		player.reparent(get_tree().root, true)

	# Free the source BEFORE the destination is created, and wait until the
	# physics world has really released its bodies. Two streamed worlds alive
	# at the same time exhaust the physics job system.
	var bodies_total := _count_bodies()
	var bodies_in_source := _count_bodies_under(source)
	if source != null and is_instance_valid(source):
		source.queue_free()
	await get_tree().process_frame
	var released := 0
	var target_bodies := maxi(0, bodies_total - bodies_in_source)
	while _count_bodies() > target_bodies and released < 240:
		released += 1
		await get_tree().physics_frame

	# The destination spawns its own player at the declared arrival and
	# validates that the spawn is on solid ground. That validated transform is
	# what the persistent player is then placed at.
	var ts := _transitions()
	if ts != null and ts.has_method("pending_arrival"):
		ts.set("pending_arrival", arrival)
	var packed := await _load_packed(scene_path)
	if packed == null:
		_fail(edge, "could not load " + scene_path)
		_unfreeze()
		return false
	var inst := packed.instantiate()
	if inst == null:
		_fail(edge, "could not instantiate " + scene_path)
		_unfreeze()
		return false
	get_tree().root.add_child(inst)

	var deadline := Time.get_ticks_msec() + 60000
	while is_instance_valid(inst) and not bool(inst.get("built")):
		if Time.get_ticks_msec() > deadline:
			_fail(edge, "destination %s did not finish building" % to)
			_unfreeze()
			return false
		await get_tree().process_frame
	if not is_instance_valid(inst) or not bool(inst.get("built")):
		_fail(edge, "destination %s was not built" % to)
		_unfreeze()
		return false

	var dest_player := inst.get("player") as Player
	var arrival_xf := Transform3D()
	if dest_player != null and is_instance_valid(dest_player):
		arrival_xf = dest_player.global_transform
		dest_player.queue_free()

	last_source = str(edge.get("from", ""))
	if player != null and is_instance_valid(player):
		# reparent() detaches the player from the place it is leaving and
		# attaches it to the place it is entering, in one operation, without
		# the "parent is busy adding or removing children" hazard.
		player.reparent(inst, true)
		player.global_transform = arrival_xf
		var rules: Variant = inst.get("rules")
		if rules is Dictionary:
			player.apply_rules(rules)
		restore_session(player, carried)
		# The destination's streamed world must follow the persistent player,
		# not the player it spawned itself.
		#
		# The scan uses `is` rather than `find_children("*", "ChunkWorld")`:
		# the type filter of find_children matches NATIVE class names, so a
		# script class name is not a reliable filter, and the two streaming
		# worlds in this project (ChunkWorld and ChunkWorld3D) do not share
		# a base class at all.
		for c in _descendants(inst):
			if c is ChunkWorld:
				(c as ChunkWorld).target = player
			elif c is ChunkWorld3D:
				(c as ChunkWorld3D).target = player
		inst.set("player", player)
		player.set_physics_process(true)

	get_tree().current_scene = inst
	var state := _autoload("SessionState")
	if state != null:
		state.set("current_level", to)
		state.set("in_gameplay", true)

	transfer_count += 1
	transfer_completed.emit(edge, kind)
	return true


func _unfreeze() -> void:
	if player != null and is_instance_valid(player):
		player.set_physics_process(true)


## How many collision objects are alive in the tree. The physics job system
## has a fixed number of slots, and two streamed worlds alive at the same
## time can exceed it.
func _count_bodies() -> int:
	return get_tree().root.find_children("*", "CollisionObject3D", true, false).size()


## How many collision objects belong to one place.
func _count_bodies_under(node: Node) -> int:
	if node == null or not is_instance_valid(node):
		return 0
	return node.find_children("*", "CollisionObject3D", true, false).size()


## Every descendant of a node, in no particular order.
static func _descendants(node: Node) -> Array:
	var out: Array = []
	if node == null:
		return out
	var stack: Array = node.get_children()
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		out.append(n)
		stack.append_array(n.get_children())
	return out


## Whether `candidate` is `node` or one of its ancestors.
static func _is_ancestor_of(candidate: Node, node: Node) -> bool:
	var n: Node = node
	while n != null:
		if n == candidate:
			return true
		n = n.get_parent()
	return false


## The place the wanderer is leaving.
##
## The current scene is the usual answer, and it is preferred whenever it
## really is the place the wanderer stands in - that keeps this coordinator
## consistent with TransitionService.load_level in the game.
##
## It is not always the right answer though: a place can be a child of the
## tree root that is not the current scene (the laboratory under test, a
## streamed overlay in the game). The rule that always holds is ownership:
## the place is the top-level ancestor of the wanderer, because that node
## owns the geometry, the collision bodies and the streaming of that place.
func _source_place() -> Node:
	var root := get_tree().root
	var current := get_tree().current_scene
	if player != null and is_instance_valid(player):
		if current != null and is_instance_valid(current) and _is_ancestor_of(current, player):
			return current
		var n: Node = player.get_parent()
		while n != null and n != root:
			var parent := n.get_parent()
			if parent == null or parent == root:
				return n
			n = parent
	return current


## Load the destination scene.
##
## The scene is loaded AHEAD of the fold and kept warm, so the fold itself is a
## cache hit and costs nothing. The load is synchronous on purpose:
##
##   * On Godot 4.5.1 in headless mode a COLD threaded load of a level scene
##     never completes: `load_threaded_get_status()` stays at
##     THREAD_LOAD_IN_PROGRESS indefinitely and the scene only resolves at
##     shutdown, with a parse error on the scene's script line. This was
##     measured, not assumed - see reports/infinite_world/BASELINE.md.
##   * A warm cache returns instantly from either path.
##
## The prefetch therefore happens while the player is still walking towards
## the portal, which is where the one-off cost belongs.
func _load_packed(path: String) -> PackedScene:
	# A scene that was prefetched is already loaded and warm: take it from the
	# cache instead of asking the resource loader for it a second time.
	var cached := prefetched_scene(path)
	if cached != null:
		_prefetched.erase(path)
		return cached
	var packed := ResourceLoader.load(path) as PackedScene
	if packed == null:
		push_error("WorldCoordinator: could not load " + path)
	return packed


## Load a destination scene now and keep it warm for a later fold.
## Returns true when the scene is cached and ready.
func prefetch_scene(scene_path: String) -> bool:
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		return false
	if _prefetched.has(scene_path):
		return true
	var packed := ResourceLoader.load(scene_path) as PackedScene
	if packed == null:
		return false
	_prefetched[scene_path] = packed
	return true


## The cached scene for a path, if it was prefetched.
func prefetched_scene(scene_path: String) -> PackedScene:
	return _prefetched.get(scene_path, null)


func _fail(edge: Dictionary, reason: String) -> void:
	push_error("WorldCoordinator: transfer failed: " + reason)
	transfer_failed.emit(edge, reason)
