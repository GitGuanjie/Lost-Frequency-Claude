extends Node
## Long distance exploration, under load.
##
## "Stress-test long-distance exploration" is a requirement of the brief, and
## it has two halves that fail in different ways:
##
##   1. The PHYSICAL half: a body that walks a long way must actually get
##      there, through real doorways, and the world must still be coherent
##      when it arrives.
##   2. The STREAMING half: a world that is explored for a long distance
##      must not grow without bound. Chunks must come and go, the build
##      budget must hold, and the state of a chunk must survive being
##      unloaded and loaded again.
##
## The test measures both, and it measures the build cost of a chunk
## directly rather than trusting the counters the streamer maintains.
##
## Run (autoloads required, so this is a SCENE, not a --script run):
##   godot --headless --path . --fixed-fps 60 res://tests/ContinuityStressTest.tscn

const SEED := 1337
const C := 24.0
const LANE_Z := 2.2
const WALK_CHUNKS := 6      # chunks to walk physically
const SWEEP_CHUNKS := 40    # chunks to travel through
const REPORT_PATH := "res://reports/qa/continuity_stress.json"
## Loaded by path: a class_name only reaches a script that an editor import
## has registered, and a headless gate run must not depend on that.
const PathFinder := preload("res://tests/ContinuityPathFinder.gd")
const Walker := preload("res://tests/ContinuityWalker.gd")

var lab: Node3D
var world: ChunkWorld3D
var player: Player
var findings: Array = []
var failures := 0
var _deadline_ms := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")


func _process(_delta: float) -> void:
	if _deadline_ms > 0 and Time.get_ticks_msec() > _deadline_ms:
		_deadline_ms = 0
		push_error("STRESS: wall clock timeout")
		_report()
		get_tree().quit(2)


func _check(ok: bool, label: String, detail: Dictionary = {}) -> void:
	var entry := {"check": label, "pass": ok}
	if not detail.is_empty():
		entry["detail"] = detail
	findings.append(entry)
	if not ok:
		failures += 1
		push_error("STRESS FAIL: " + label + " " + JSON.stringify(detail))


func _run() -> void:
	_deadline_ms = Time.get_ticks_msec() + 25 * 60 * 1000
	_build_environment()
	lab = load("res://labs/Level0ContinuityLab.tscn").instantiate()
	if lab == null or not ("world" in lab):
		_check(false, "continuity lab scene loads",
			{"scene": "res://labs/Level0ContinuityLab.tscn"})
		_report()
		return
	world = ChunkWorld3D.new()
	world.name = "QAWorld"
	world.seed_value = SEED
	world.world_id = "QA_STRESS"
	world.disk_persistence_enabled = false
	world.radius_xz = 2
	world.radius_y = 1
	world.unload_xz = 3
	world.unload_y = 2
	world.builds_per_frame = 8
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
	await _settle(40)

	# --- 1. The cost of building one chunk, measured directly. -------------
	var build_times: Array = []
	for i in range(12):
		var key := Vector3i(20 + i, 0, 20 + i)
		if world.chunks.has(key):
			continue
		var started := Time.get_ticks_usec()
		world._build(key)
		build_times.append((Time.get_ticks_usec() - started) / 1000.0)
	build_times.sort()
	var median_build := 0.0
	if build_times.size() > 0:
		median_build = float(build_times[build_times.size() / 2])
	_check(build_times.size() >= 8,
		"twelve fresh chunks were built for the cost measurement",
		{"built": build_times.size()})
	_check(median_build < 60.0,
		"the median chunk build stays inside the frame budget",
		{"median_ms": median_build, "worst_ms": build_times[-1] if build_times.size() > 0 else 0.0,
			"all_ms": build_times})

	# --- 2. The physical half: walk a long way. ---------------------------
	#
	# The route of the next leg is planned WHILE the walker walks the one
	# before it. The chunks six rooms east are not built yet when the walk
	# starts - the streamer builds them as the walker approaches - so a
	# route planned for them in advance would be a route through nothing.
	var spawn := player.global_position
	var space := get_viewport().world_3d.direct_space_state
	var finder = PathFinder.new(space)
	var walker = Walker.new()
	walker.setup(player, [])
	var failed_legs: Array = []
	var next_leg := 0
	var reached := false
	var crossed := 0
	var last_key := world.key_at(spawn)
	for frame in 120000:
		if walker.index >= walker.waypoints.size():
			if next_leg >= WALK_CHUNKS:
				reached = true
				break
			var key := Vector3i(next_leg, 0, 0)
			var openings := ContinuityTopology.face_openings(SEED, key, "east")
			if openings.is_empty():
				next_leg += 1
				continue
			var lateral := float(openings[0]["at"])
			var goal := Vector3(C * float(next_leg + 1) + 2.0, 0.0, lateral)
			var area := _area_of(player.global_position, goal)
			var path = finder.plan(player.global_position, goal, area)
			if path.is_empty():
				failed_legs.append(next_leg)
			else:
				for p in path:
					walker.waypoints.append(p)
			next_leg += 1
			continue
		await walker.step(get_tree())
		var here := world.key_at(player.global_position)
		if here.x != last_key.x:
			crossed += 1
		last_key = here
	var walked := player.global_position
	_check(reached,
		"the walker completed the long walk",
		{"waypoints": walker.waypoints.size(), "reached": walker.index,
			"pos": str(walked), "recoveries": walker.recoveries,
			"forced": walker.forced, "stuck": walker.stuck_report()})
	_check(failed_legs.is_empty(),
		"a route was planned for every leg of the long walk",
		{"failed_legs": failed_legs})
	_check(walker.waypoints.size() >= 8,
		"the long walk is a route with real waypoints in it",
		{"waypoints": walker.waypoints.size(), "chunks": WALK_CHUNKS})
	_check(crossed >= WALK_CHUNKS - 1,
		"the walker crossed every chunk seam of the long walk",
		{"crossed": crossed, "chunks": WALK_CHUNKS})
	_check(walked.distance_to(spawn) > 100.0,
		"the walker travelled more than 100 m",
		{"distance": Vector2(walked.x - spawn.x, walked.z - spawn.z).length()})

	# --- 3. The streaming half: travel far, and keep the world bounded. ---
	# The state of the chunk the walker starts in must survive the trip.
	var home_key := world.key_at(spawn)
	world.set_change(home_key, "stress_marker", 1)
	var resident_peak := world.chunks.size()
	var built_before := int(world.stream_stats["built"])
	var unloaded_before := int(world.stream_stats["unloaded"])
	var missing := 0
	var steps := SWEEP_CHUNKS
	for step in range(1, steps + 1):
		var target := Vector3(spawn.x + C * float(step), 0.0, spawn.z)
		player.global_position = target
		player.velocity = Vector3.ZERO
		var key := world.key_at(target)
		var waited := 0
		while not world.chunks.has(key) and waited < 900:
			await get_tree().physics_frame
			waited += 1
		if not world.chunks.has(key):
			missing += 1
			continue
		# Put the body back on the floor of the chunk it just reached.
		player.global_position = Vector3(target.x, 0.2, target.z)
		player.velocity = Vector3.ZERO
		await _settle(2)
		resident_peak = maxi(resident_peak, world.chunks.size())
	_check(missing == 0,
		"every chunk of the long sweep was built before it was entered",
		{"missing": missing, "steps": steps})
	var built_after := int(world.stream_stats["built"])
	var unloaded_after := int(world.stream_stats["unloaded"])
	_check(built_after - built_before > 20,
		"the sweep really streamed new chunks in",
		{"built": built_after - built_before, "unloaded": unloaded_after - unloaded_before})
	_check(unloaded_after - unloaded_before > 0,
		"the sweep really streamed chunks back out",
		{"built": built_after - built_before, "unloaded": unloaded_after - unloaded_before})
	_check(resident_peak <= 260,
		"the resident chunk count stays bounded during the sweep",
		{"peak_resident": resident_peak, "final_resident": world.chunks.size(),
			"radius_xz": world.radius_xz, "unload_xz": world.unload_xz})

	# --- 4. The state survived the trip. ----------------------------------
	player.global_position = spawn
	player.velocity = Vector3.ZERO
	var waited_back := 0
	while not world.chunks.has(home_key) and waited_back < 900:
		await get_tree().physics_frame
		waited_back += 1
	_check(int(world.change_of(home_key, "stress_marker", 0)) == 1,
		"a change made before the sweep is still there after it",
		{"chunk": str(home_key), "marker": world.change_of(home_key, "stress_marker", 0)})
	_report()


## The rectangle a leg of the long walk is allowed to use. It is generous
## on purpose: the route between two openings of the same row of chunks has
## to reach the door of a partition wall, and that door is not on the
## straight line between them.
func _area_of(from: Vector3, to: Vector3) -> Rect2:
	var pad := 9.0
	var lo := Vector2(minf(from.x, to.x), minf(from.z, to.z)) - Vector2(pad, pad)
	var hi := Vector2(maxf(from.x, to.x), maxf(from.z, to.z)) + Vector2(pad, pad)
	return Rect2(lo, hi - lo)


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
	var f := FileAccess.open(dir + "/continuity_stress.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({
			"engine": Engine.get_version_info(),
			"seed": SEED,
			"status": "PASS" if failures == 0 else "FAIL",
			"checks": findings.size(),
			"failures": failures,
			"native": true,
			"walk_chunks": WALK_CHUNKS,
			"sweep_chunks": SWEEP_CHUNKS,
			"findings": findings,
		}, "  ") + "\n")
		f.close()
	print("STRESS %d checks, %d failures" % [findings.size(), failures])
	get_tree().quit(0 if failures == 0 else 1)
