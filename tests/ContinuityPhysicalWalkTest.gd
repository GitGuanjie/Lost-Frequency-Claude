extends Node
## Native physical traversal test for the continuity lab.
##
## Run (autoloads required, so this is a SCENE, not a --script run):
##   godot --headless --path . --fixed-fps 60 res://tests/ContinuityPhysicalWalkTest.tscn
##
## The topology tests prove the PLAN is consistent. This test proves the
## GEOMETRY is consistent with the plan: a real CharacterBody3D is driven
## through the generated world with the physics engine, and it has to
## physically cross chunk seams, cross the atrium bridge of the shared macro
## hall, climb a staircase to the next storey, reach negative coordinates and
## come back home.
##
## A numerical check is not a substitute for this. If the declared portal and
## the built wall disagree, the walker cannot get through and the test fails.
##
## The lab has open stairwells: one shaft of every storey holds the ramp up
## and the other holds the well down. The walker therefore uses the two
## lanes that are solid across a whole chunk (z = 2.2 m and z = 21.5 m) and
## only crosses a seam through a declared portal.

const SEED := 1337
const REPORT_PATH := "res://reports/qa/continuity_physical_walk.json"
const C := 24.0
const LANE_SOUTH := 2.2
const LANE_NORTH := 21.5

var lab: Node3D
var world: ChunkWorld3D
var player: Player
var findings: Array = []
var failures := 0
var _detour_sign := 1.0
var _detour_frames := 0
var _detour_offset := 0.0
var _last_progress := Vector3.ZERO
var _stuck_frames := 0
var _hop_cooldown := 0
var _deadline_ms := 0
var _route_trace: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")


## Watchdog: a GDScript error inside the test aborts the coroutine and would
## leave the SceneTree running forever. The runner also enforces a timeout,
## but failing fast with a report is far more useful.
func _process(_delta: float) -> void:
	if _deadline_ms > 0 and Time.get_ticks_msec() > _deadline_ms:
		_deadline_ms = 0
		push_error("PHYSICAL WALK: wall clock timeout")
		_report()
		get_tree().quit(2)


func _check(ok: bool, label: String, detail: Dictionary = {}) -> void:
	var entry := {"check": label, "pass": ok}
	if not detail.is_empty():
		entry["detail"] = detail
	findings.append(entry)
	if not ok:
		failures += 1
		push_error("PHYSICAL WALK FAIL: " + label + " " + JSON.stringify(detail))


func _run() -> void:
	_deadline_ms = Time.get_ticks_msec() + 15 * 60 * 1000
	_build_environment()
	# The lab scene is used as a library of geometry, not as a running game:
	# its own _ready would capture the mouse and load a saved seed.
	lab = load("res://labs/Level0ContinuityLab.tscn").instantiate()
	if lab == null or not ("world" in lab):
		_check(false, "continuity lab scene loads", {"scene": "res://labs/Level0ContinuityLab.tscn"})
		_report()
		return
	world = ChunkWorld3D.new()
	world.name = "QAWorld"
	world.seed_value = SEED
	world.world_id = "QA_PHYSICAL_WALK"
	world.disk_persistence_enabled = false
	world.radius_xz = 2
	world.radius_y = 1
	world.unload_xz = 3
	world.unload_y = 2
	world.builds_per_frame = 6
	lab.world = world
	world.builder = lab._build_chunk
	add_child(world)
	world.attach_save_scope()

	player = Player.new()
	player.name = "Walker"
	add_child(player)
	player.apply_rules({"gravity": 9.8, "flashlight": "allowed", "view_distance": 180.0})
	player.position = Vector3(11.0, 0.2, 11.0)
	player.qa_active = true
	player.qa_sprint = true
	world.target = player
	await _settle(30)

	var spawn := player.global_position
	_check(player.is_on_floor(), "walker spawns on solid ground", {"pos": str(spawn)})
	_check(world.key_at(spawn) == Vector3i(0, 0, 0), "walker spawns in chunk 0:0:0",
		{"chunk": str(world.key_at(spawn))})

	# --- 1. Cross the east seam of the spawn chunk. ------------------------
	# The east portal of chunk 0 is declared by the shared-face contract; the
	# walker has to find that hole in the wall with real collision.
	var east_offset := ContinuityTopology.face_offset(SEED, Vector3i(0, 0, 0), "east")
	var east_route := [
		Vector3(11.0, 0.0, LANE_SOUTH),
		Vector3(23.0, 0.0, LANE_SOUTH),
		Vector3(23.0, 0.0, east_offset),
		Vector3(26.0, 0.0, east_offset),
	]
	var r1 := await _walk_route(east_route, 3000)
	_check(r1["reached"], "walker reaches the declared east portal of chunk 0",
		{"offset": east_offset, "distance": r1["distance"], "pos": str(player.global_position)})
	_check(world.key_at(player.global_position).x >= 1,
		"walker physically crossed a chunk seam eastward",
		{"chunk": str(world.key_at(player.global_position)), "pos": str(player.global_position)})

	# --- 2. Come back home. ------------------------------------------------
	var r2 := await _walk_route([
		Vector3(23.0, 0.0, east_offset),
		Vector3(23.0, 0.0, LANE_SOUTH),
		Vector3(11.0, 0.0, LANE_SOUTH),
		Vector3(11.0, 0.0, 11.0),
	], 3600)
	_check(r2["reached"], "walker returns to the spawn point through the same portal",
		{"distance": r2["distance"], "pos": str(player.global_position)})

	# --- 3. Reach negative coordinates. ------------------------------------
	var west_offset := ContinuityTopology.face_offset(SEED, Vector3i(0, 0, 0), "west")
	var r3 := await _walk_route([
		Vector3(11.0, 0.0, LANE_SOUTH),
		Vector3(1.0, 0.0, LANE_SOUTH),
		Vector3(1.0, 0.0, west_offset),
		Vector3(-2.5, 0.0, west_offset),
	], 4200)
	_check(r3["reached"], "walker reaches negative chunk coordinates",
		{"offset": west_offset, "distance": r3["distance"], "pos": str(player.global_position)})
	_check(world.key_at(player.global_position).x <= -1,
		"walker is in a chunk with negative coordinates",
		{"chunk": str(world.key_at(player.global_position))})

	# --- 4. Return from the negative side. ----------------------------------
	var r4 := await _walk_route([
		Vector3(1.0, 0.0, west_offset),
		Vector3(1.0, 0.0, LANE_SOUTH),
		Vector3(11.0, 0.0, LANE_SOUTH),
		Vector3(11.0, 0.0, 11.0),
	], 4800)
	_check(r4["reached"], "walker returns from negative coordinates",
		{"distance": r4["distance"], "pos": str(player.global_position)})

	# --- 5. Climb the staircase to the next storey. ------------------------
	# The outgoing ramp of storey 0 starts at x 7.5 and climbs north.
	var r5 := await _walk_route([
		Vector3(7.5, 0.0, 3.0),
		Vector3(7.5, 0.0, 21.5),
	], 4800)
	_check(r5["reached"], "walker climbs the staircase to the next storey",
		{"distance": r5["distance"], "pos": str(player.global_position)})
	_check(world.key_at(player.global_position).y == 1 and player.global_position.y > 4.0,
		"walker is one storey higher after the climb",
		{"chunk": str(world.key_at(player.global_position)), "y": player.global_position.y})

	# --- 6. Cross the atrium bridge of the shared macro hall. --------------
	# The bridge spans the x seam of the 2x2 macro hall at local z 20..23.
	# The walker is placed on the solid floor beside the bridge: the bridge
	# crossing itself must then be completed with real physics.
	player.global_position = Vector3(24.0 + 18.2, 0.2, 24.0 + 21.5)
	player.velocity = Vector3.ZERO
	await _settle(12)
	var r6 := await _walk_route([
		Vector3(24.0 + 19.0, 0.0, 24.0 + 21.5),
		Vector3(24.0 + 27.0, 0.0, 24.0 + 21.5),
	], 2400)
	_check(r6["reached"], "walker physically crosses the atrium bridge",
		{"distance": r6["distance"], "pos": str(player.global_position)})
	_check(world.key_at(player.global_position).x == 2,
		"walker is on the far side of the macro hall",
		{"chunk": str(world.key_at(player.global_position))})
	_check(absf(player.global_position.y) < 1.0,
		"walker did not fall into the atrium void",
		{"y": player.global_position.y})

	# --- 7. A rebuilt chunk is identical to the one it replaces. ----------
	var probe_key := Vector3i(0, 0, 0)
	var before := world.meta_of(probe_key).duplicate(true)
	world._unload(probe_key)
	world._build(probe_key)
	var after := world.meta_of(probe_key)
	_check(before == after, "an unloaded and rebuilt chunk is byte-identical in structure",
		{"before": str(before), "after": str(after)})

	_report()


# ------------------------------------------------------------------ walker

## Walk a list of world waypoints in order.
func _walk_route(waypoints: Array, budget: int) -> Dictionary:
	var best := 999999.0
	var index := 0
	_stuck_frames = 0
	_detour_frames = 0
	_detour_offset = 0.0
	_last_progress = player.global_position
	_route_trace = []
	for frame in budget:
		if frame % 60 == 0:
			_route_trace.append([frame, player.global_position.x, player.global_position.y,
				player.global_position.z])
		while index < waypoints.size():
			var wp: Vector3 = waypoints[index]
			var flat := Vector3(wp.x - player.global_position.x, 0.0,
				wp.z - player.global_position.z)
			if flat.length() < 1.2:
				index += 1
				continue
			break
		if index >= waypoints.size():
			player.qa_input = Vector2.ZERO
			return {"reached": true, "distance": 0.0, "frames": frame}
		var goal: Vector3 = waypoints[index]
		var pos := player.global_position
		var flat := Vector3(goal.x - pos.x, 0.0, goal.z - pos.z)
		var distance := flat.length()
		best = minf(best, distance)
		if not player.is_on_floor():
			# Falling into an open stairwell is legitimate physics. Let gravity
			# do its work and pick the route up again afterwards.
			player.qa_input = Vector2.ZERO
			await get_tree().physics_frame
			continue
		var desired := flat.normalized()
		# The player controller already slides along walls in move_and_slide(),
		# so the walker simply pushes towards the goal and lets the physics
		# find the doorway. A detour offset is only added when the body has
		# been stuck for a while, and its sign alternates so the walker tries
		# both ways along the wall.
		if _detour_frames > 0:
			_detour_frames -= 1
		player.rotation.y = atan2(-desired.x, -desired.z) + _detour_offset
		player.qa_input = Vector2(0.0, 1.0)
		await get_tree().physics_frame
		# Hop assist: the goal is higher than the walker, and the way up is the
		# staircase ramp, which a walking body cannot mount without a step.
		if goal.y > player.global_position.y + 0.6 and player.is_on_floor():
			_hop_cooldown -= 1
			if _hop_cooldown <= 0:
				_hop_cooldown = 26
				player.velocity.y = 3.8
		if player.global_position.distance_to(_last_progress) > 1.6:
			_last_progress = player.global_position
			_stuck_frames = 0
		else:
			_stuck_frames += 1
			if _stuck_frames > 45:
				_stuck_frames = 0
				_detour_sign = -_detour_sign
				_detour_offset = _detour_sign * deg_to_rad(100.0)
				_detour_frames = 90
	return {"reached": false, "distance": best, "frames": budget}


## Choose a walkable heading close to the desired one. A slope is always
## followed directly: the staircase ramp is a slope, and a flat probe would
## wrongly report it as a wall.
func _choose_direction(desired: Vector3) -> Vector3:
	if player.is_on_floor() and player.get_floor_normal().y < 0.985:
		return desired
	for angle in [0.0, 0.35, -0.35, 0.7, -0.7, 1.05, -1.05, 1.4, -1.4, 1.75, -1.75, 2.2, -2.2, 3.14159]:
		var candidate := desired.rotated(Vector3.UP, angle).normalized()
		if _probe(candidate):
			return candidate
	return Vector3.ZERO


func _probe(direction: Vector3) -> bool:
	var motion := direction * 0.55
	var xf := player.global_transform
	if not player.test_move(xf, motion):
		return true
	# Allow a small step up, the same way the player controller does.
	xf.origin += Vector3.UP * player.step_height
	return not player.test_move(xf, motion)

# ------------------------------------------------------------------ helpers

func _settle(frames: int) -> void:
	for i in frames:
		await get_tree().physics_frame


func _build_environment() -> void:
	var env_node := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.08, 0.085, 0.09)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.93, 0.85, 0.69)
	e.ambient_light_energy = 0.4
	env_node.environment = e
	add_child(env_node)


func _report() -> void:
	var dir := ProjectSettings.globalize_path("res://reports/qa")
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(dir + "/continuity_physical_walk.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({
			"engine": Engine.get_version_info(),
			"seed": SEED,
			"status": "PASS" if failures == 0 else "FAIL",
			"checks": findings.size(),
			"failures": failures,
			"native": true,
			"findings": findings,
		}, "  ") + "\n")
		f.close()
	print("PHYSICAL_WALK %d checks, %d failures" % [findings.size(), failures])
	get_tree().quit(0 if failures == 0 else 1)
