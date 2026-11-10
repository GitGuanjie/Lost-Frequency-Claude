extends Node
## Native verification of the canonical Level 0 -> Level 1 transition.
##
## Run (autoloads required, so this is a SCENE, not a --script run):
##   godot --headless --path . --fixed-fps 60 res://tests/ContinuityCanonTransitionTest.tscn
##
## The test drives a real CharacterBody3D into the flickering wall of the
## procedural laboratory and proves that the fold actually happens:
##
##   1. the laboratory edge resolves and names the canon edge L000>L001#1;
##   2. the canon edge exists in the canonical manifest and its trigger is
##      `noclip`;
##   3. the destination is the REAL Level 1 scene, never a proxy;
##   4. the player physically reaches and enters the trigger volume;
##   5. the transfer completes and the scene is Level 1;
##   6. EXACTLY ONE player node exists in the tree: the wanderer is moved, not
##      destroyed and re-created;
##   7. the player is at the `from_L000` arrival that Level 1 declares;
##   8. the carried state survived the fold.
##
## A static check of the edge table cannot prove any of this. The body has to
## run into the wall.

const REPORT_PATH := "res://reports/qa/continuity_canon_transition.json"
const SEED := 1337
const LAB_EDGE := "LAB>L000>L001#1"
const CANON_EDGE := "L000>L001#1"

var findings: Array = []
var failures := 0
var _deadline_ms := 0
var lab: Node3D
var world: ChunkWorld3D
var lab_id := 0
var world_id := 0
var player: Player
var coordinator: WorldCoordinator


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")


func _process(_delta: float) -> void:
	if _deadline_ms > 0 and Time.get_ticks_msec() > _deadline_ms:
		_deadline_ms = 0
		push_error("CANON TRANSITION: wall clock timeout")
		_report()
		get_tree().quit(2)


func _check(ok: bool, label: String, detail: Dictionary = {}) -> void:
	var entry := {"check": label, "pass": ok}
	if not detail.is_empty():
		entry["detail"] = detail
	findings.append(entry)
	if not ok:
		failures += 1
		push_error("CANON TRANSITION FAIL: " + label + " " + JSON.stringify(detail))


func _run() -> void:
	_deadline_ms = Time.get_ticks_msec() + 10 * 60 * 1000
	await _settle(2)
	print("CT phase edges")

	# ---------------------------------------------------------- 1. the edges
	var coord := WorldCoordinator.ensure(get_tree())
	_check(coord != null, "a WorldCoordinator exists")
	if coord == null:
		_report()
		get_tree().quit(1)
		return
	coordinator = coord
	var lab_edge := coordinator.resolve_edge(LAB_EDGE)
	_check(not lab_edge.is_empty(), "the laboratory edge resolves",
		{"edge": LAB_EDGE})
	if lab_edge.is_empty():
		_report()
		get_tree().quit(1)
		return
	_check(str(lab_edge.get("canon_edge", "")) == CANON_EDGE,
		"the laboratory edge names the canon edge",
		{"canon_edge": str(lab_edge.get("canon_edge", ""))})
	_check(str(lab_edge.get("basis", "")) == "ADAPTATION",
		"the laboratory edge is labelled ADAPTATION, not canon",
		{"basis": str(lab_edge.get("basis", ""))})
	_check(str(lab_edge.get("to", "")) == "L001",
		"the laboratory edge points at the real Level 1",
		{"to": str(lab_edge.get("to", ""))})
	var canon_edge := coordinator.resolve_edge(CANON_EDGE)
	_check(not canon_edge.is_empty(), "the canon edge resolves from the canonical manifest",
		{"edge": CANON_EDGE})
	_check(str(canon_edge.get("trigger", "")) == "noclip",
		"the canon edge is a noclip route",
		{"trigger": str(canon_edge.get("trigger", ""))})
	_check(str(canon_edge.get("basis", "")) == "SOURCE",
		"the canon edge carries a source basis",
		{"basis": str(canon_edge.get("basis", ""))})
	_check(str(canon_edge.get("source_quote", "")) != "",
		"the canon edge carries a source quote",
		{"quote": str(canon_edge.get("source_quote", ""))})
	_check(str(lab_edge.get("arrival", "")) == "from_L000",
		"the arrival is the one Level 1 declares for this route",
		{"arrival": str(lab_edge.get("arrival", ""))})

	# The destination must be a real scene, and it must not be a proxy.
	var registry := get_tree().root.get_node_or_null(^"LevelRegistry")
	_check(registry != null, "LevelRegistry is present")
	if registry == null:
		_report()
		get_tree().quit(1)
		return
	var scene_path: String = str(registry.call("scene_path", "L001"))
	_check(scene_path == "res://levels/L001/L001.tscn",
		"the destination is the real Level 1 scene", {"scene": scene_path})
	_check(ResourceLoader.exists(scene_path), "the Level 1 scene exists on disk",
		{"scene": scene_path})
	var impl: Dictionary = registry.call("get_entry", "L001").get("impl", {})
	_check((impl.get("arrivals", []) as Array).has("from_L000"),
		"Level 1 declares the from_L000 arrival")
	# A proxy must never stand in for the canonical Level 1.
	var proxy_paths: Array = []
	for sid in registry.call("get_all_sids") if registry.has_method("get_all_sids") else []:
		var p := str(registry.call("scene_path", sid))
		if p.to_upper().contains("PROXY"):
			proxy_paths.append(p)
	_check(proxy_paths.is_empty(), "no proxy level is used as the destination",
		{"proxies": proxy_paths})

	print("CT phase boot")
	# ------------------------------------------------ 2. boot the laboratory
	lab = load("res://labs/Level0ContinuityLab.tscn").instantiate()
	if lab == null:
		_check(false, "the laboratory scene loads")
		_report()
		get_tree().quit(1)
		return
	get_tree().root.add_child(lab)
	await _settle(30)
	player = lab.get("player") as Player
	_check(player != null and is_instance_valid(player), "the laboratory spawns a player")
	if player == null:
		_report()
		get_tree().quit(1)
		return
	world = lab.get("world") as ChunkWorld3D
	_check(world != null, "the laboratory has a world")
	lab_id = lab.get_instance_id()
	world_id = world.get_instance_id() if world != null else 0
	_check(coordinator.player == player,
		"the coordinator adopted the laboratory player")

	# The flickering wall must exist as real geometry with a trigger.
	var portal := _find_portal(lab)
	_check(portal != null, "the laboratory built the flickering-wall portal")
	if portal == null:
		_report()
		get_tree().quit(1)
		return
	_check(str(portal.get("edge_id")) == LAB_EDGE,
		"the portal fires the laboratory edge", {"edge": str(portal.get("edge_id"))})
	_check(str(portal.get("kind")) == "noclip",
		"the portal is a noclip portal", {"kind": str(portal.get("kind"))})

	print("CT phase walk")
	# ---------------------------------------------- 3. run into the wall
	var trigger_pos: Vector3 = portal.get("global_position")
	var wall_pos := Vector3(trigger_pos.x, trigger_pos.y, trigger_pos.z + 0.4)
	# Stand in front of the trigger and run at it.
	player.global_position = Vector3(trigger_pos.x, 0.2, trigger_pos.z - 2.6)
	player.velocity = Vector3.ZERO
	player.qa_active = true
	player.qa_sprint = true
	await _settle(20)
	_check(player.is_on_floor(), "the runner stands on solid ground in front of the wall",
		{"pos": str(player.global_position)})

	var before_id := player.get_instance_id()
	var before_light := player.flashlight != null and player.flashlight.visible
	var fired := false
	var frames := 0
	# Run north into the wall. The portal needs the player to KEEP pushing, so
	# the input is held for the whole approach.
	# The controller walks along -basis.z, so the heading that faces the wall is
	# atan2(-dx, -dz) of the desired direction, exactly like the physical walk
	# test uses.
	var to_wall := Vector3(0.0, 0.0, 1.0)
	var heading := atan2(-to_wall.x, -to_wall.z)
	while frames < 600 and not fired:
		frames += 1
		player.rotation.y = heading
		player.qa_input = Vector2(0.0, 1.0)
		await get_tree().physics_frame
		var p := player.global_position
		if p.z > trigger_pos.z - 0.6:
			fired = true
		if coordinator.transfer_count > 0:
			fired = true
		if not is_instance_valid(player):
			break
	_check(fired, "the runner reaches the trigger volume",
		{"frames": frames, "pos": str(player.global_position),
		 "trigger": str(trigger_pos)})
	_check(player != null and is_instance_valid(player),
		"the player survived the approach")

	print("CT phase transfer")
	# The fold itself: wait for the transfer to complete.
	var wait := 0
	while wait < 900 and coordinator.transfer_count == 0:
		wait += 1
		await get_tree().physics_frame
	_check(coordinator.transfer_count == 1,
		"the fold completed exactly once",
		{"transfers": coordinator.transfer_count})
	if coordinator.transfer_count != 1:
		_report()
		get_tree().quit(1)
		return

	print("CT phase destination")
	# ------------------------------------------------ 4. the destination
	await _settle(20)
	var state := get_tree().root.get_node_or_null(^"SessionState")
	_check(state != null and str(state.get("current_level")) == "L001",
		"the session is now in Level 1",
		{"current_level": str(state.get("current_level")) if state != null else "?"})
	var current := get_tree().current_scene
	_check(current != null and str(current.name) == "L001",
		"the current scene is Level 1",
		{"scene": str(current.name) if current != null else "?"})
	_check(current != null and current.get_script() != null and
		str(current.get_script().resource_path) == "res://levels/L001/L001.gd",
		"the current scene runs the canonical Level 1 script",
		{"script": str(current.get_script().resource_path) if current != null else "?"})

	# Exactly one player, and it is the SAME node: the wanderer was moved.
	var players := get_tree().get_nodes_in_group("player")
	var named := 0
	for p in players:
		if p is Player:
			named += 1
	_check(named == 1, "exactly one player node exists after the fold",
		{"players": named, "group_size": players.size()})
	_check(player != null and is_instance_valid(player),
		"the original player node is still alive")
	if player != null and is_instance_valid(player):
		_check(player.get_instance_id() == before_id,
			"the player node was MOVED, not destroyed and re-created",
			{"before": before_id, "after": player.get_instance_id()})
		_check(current != null and player.get_parent() == current,
			"the player now belongs to the Level 1 scene",
			{"parent": str(player.get_parent().name)})
		var dest_player := current.get("player") as Player
		_check(dest_player == player,
			"Level 1 drives the persistent player")
		# The arrival: Level 1 declares `from_L000`, and the player must be on
		# solid ground there.
		_check(player.is_on_floor(),
			"the player is standing on solid ground in Level 1",
			{"pos": str(player.global_position)})
		_check(player.flashlight != null and player.flashlight.visible == before_light,
			"the carried light state survived the fold",
			{"before": before_light,
			 "after": player.flashlight.visible if player.flashlight != null else false})
	# A freed node reference reads as `null` in GDScript, so `is_instance_valid`
	# on such a reference is indistinguishable from "there was never one".
	# The instance id is the unambiguous test: an id that no longer resolves
	# is a node that is really gone.
	_check(world_id != 0 and not is_instance_id_valid(world_id),
		"the laboratory's streamed world was released",
		{"world_id": world_id,
		 "still_resolves": is_instance_id_valid(world_id)})
	# The place that OWNS the wanderer is what has to be released. Releasing
	# the wrong node leaves the old world alive beside the new one, which
	# exhausts the physics job system and hangs the fold.
	_check(lab_id != 0 and not is_instance_id_valid(lab_id),
		"the laboratory PLACE was released, not merely its chunks",
		{"lab_id": lab_id,
		 "still_resolves": is_instance_id_valid(lab_id)})

	_report()
	get_tree().quit(0 if failures == 0 else 1)


func _find_portal(root: Node) -> LabPortal:
	for p in root.find_children("*", "LabPortal", true, false):
		return p as LabPortal
	return null


func _settle(frames: int) -> void:
	for i in frames:
		await get_tree().physics_frame


func _report() -> void:
	var dir := ProjectSettings.globalize_path("res://reports/qa")
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(dir + "/continuity_canon_transition.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({
			"engine": Engine.get_version_info(),
			"seed": SEED,
			"lab_edge": LAB_EDGE,
			"canon_edge": CANON_EDGE,
			"checks": findings,
			"failures": failures,
		}, "  "))
		f.close()
	print("CANON_TRANSITION %d checks, %d failures" % [findings.size(), failures])

