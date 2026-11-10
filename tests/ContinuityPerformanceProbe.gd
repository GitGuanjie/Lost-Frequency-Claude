extends Node
## Measured performance of the continuity laboratory.
##
## Run (autoloads required, so this is a SCENE):
##   godot --headless --path . --fixed-fps 60 res://tests/ContinuityPerformanceProbe.tscn
##
## The numbers this produces are CPU numbers from a HEADLESS run: there is no
## renderer, so GPU frame time is not measured here and is not claimed. What
## is measured is the cost of planning and building chunks, which is the part
## the procedural world owns.
##
## The probe walks the player along the SAME route the physical walk test
## proves is walkable - through the declared east portal, back through the
## west portal into negative coordinates, and home again - so the streamer
## really has to build and unload chunks while the measurement runs.
##
## The probe CHECKS that the route was walked and that chunks were streamed.
## A performance number measured over a route the player never moved along is
## a number about nothing: an earlier version of this probe reported a clean
## 19.7 ms median while the player had never left the spawn chunk and not a
## single chunk had been built.
##
## Cold start and steady state are reported SEPARATELY. The first frames
## build the initial chunk window and pay for every mesh and every collision
## shape at once; that cost is real and it is reported, but it is not the
## frame cost of exploring, and mixing the two hides both.

const REPORT_PATH := "res://reports/qa/continuity_performance.json"
const SEED := 1337
const WARMUP_FRAMES := 120
const LANE_SOUTH := 2.2
const LANE_NORTH := 21.5
## The player has to travel at least this far for the route to count.
const MIN_TRAVEL_M := 40.0

var lab: Node3D
var world: ChunkWorld3D
var player: Player
var samples: Array = []
var physics_samples: Array = []
var wall_samples: Array = []
var cold_samples: Array = []
var cold_physics_samples: Array = []
var cold_wall_samples: Array = []
var peak_chunks := 0
var peak_tris := 0
var peak_colliders := 0
var built := 0
var unloaded := 0
var built_at_start := 0
var unloaded_at_start := 0
var travel := 0.0
var failures := 0
var legs: Array = []
var _deadline_ms := 0
var _last_pos := Vector3.ZERO
var _last_usec := 0
var _t_start_usec := 0
var _t_end_usec := 0
var _stuck_frames := 0
var _detour_sign := 1.0
var _detour_frames := 0
var _detour_offset := 0.0
var _last_progress := Vector3.ZERO
var _hop_cooldown := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")


func _process(_delta: float) -> void:
	if _deadline_ms > 0 and Time.get_ticks_msec() > _deadline_ms:
		_deadline_ms = 0
		push_error("PERFORMANCE: wall clock timeout")
		_report()
		get_tree().quit(2)


func _run() -> void:
	_deadline_ms = Time.get_ticks_msec() + 20 * 60 * 1000
	lab = load("res://labs/Level0ContinuityLab.tscn").instantiate()
	if lab == null:
		push_error("PERFORMANCE: the laboratory scene does not load")
		get_tree().quit(1)
		return
	get_tree().root.add_child(lab)
	await _settle(60)
	world = lab.get("world") as ChunkWorld3D
	player = lab.get("player") as Player
	if world == null or player == null:
		push_error("PERFORMANCE: the laboratory did not produce a world and a player")
		get_tree().quit(1)
		return
	player.qa_active = true
	player.qa_sprint = true
	_last_pos = player.global_position

	# Warm the cache so the steady-state measurement covers streaming and not
	# the first frame's mesh and collision setup. The cold frames are kept
	# and reported separately.
	_last_usec = Time.get_ticks_usec()
	_t_start_usec = _last_usec
	for frame in WARMUP_FRAMES:
		await get_tree().physics_frame
		cold_samples.append(float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0)
		cold_physics_samples.append(float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0)
		cold_wall_samples.append(_wall_ms())
	built_at_start = int(world.stream_stats.get("built", 0))
	unloaded_at_start = int(world.stream_stats.get("unloaded", 0))

	# The same route the physical walk test proves is walkable: through the
	# declared east portal, back along the lane, out through the declared
	# west portal into negative coordinates, and home.
	var east_offset := ContinuityTopology.face_offset(SEED, Vector3i(0, 0, 0), "east")
	var west_offset := ContinuityTopology.face_offset(SEED, Vector3i(0, 0, 0), "west")
	legs = [
		{"name": "east seam", "budget": 2400, "waypoints": [
			Vector3(11.0, 0.0, LANE_SOUTH),
			Vector3(23.0, 0.0, LANE_SOUTH),
			Vector3(23.0, 0.0, east_offset),
			Vector3(26.0, 0.0, east_offset),
		]},
		{"name": "back to the lane", "budget": 1800, "waypoints": [
			Vector3(23.0, 0.0, east_offset),
			Vector3(23.0, 0.0, LANE_SOUTH),
			Vector3(11.0, 0.0, LANE_SOUTH),
		]},
		{"name": "west seam", "budget": 3000, "waypoints": [
			Vector3(11.0, 0.0, LANE_SOUTH),
			Vector3(1.0, 0.0, LANE_SOUTH),
			Vector3(1.0, 0.0, west_offset),
			Vector3(-2.5, 0.0, west_offset),
		]},
		{"name": "home", "budget": 2400, "waypoints": [
			Vector3(1.0, 0.0, west_offset),
			Vector3(1.0, 0.0, LANE_SOUTH),
			Vector3(11.0, 0.0, LANE_SOUTH),
			Vector3(11.0, 0.0, 11.0),
		]},
	]

	for leg in legs:
		var result := await _walk_route(leg["waypoints"], int(leg["budget"]))
		leg["reached"] = bool(result["reached"])
		leg["frames"] = int(result["frames"])
		leg["closest_m"] = float(result["distance"])
		_fail(bool(result["reached"]),
			"the probe walked the leg '%s'" % str(leg["name"]),
			{"closest_m": float(result["distance"]), "frames": int(result["frames"])})
		var chunk := world.key_at(player.global_position)
		leg["end_chunk"] = str(chunk)

	# The measurement is only meaningful if the player really moved and the
	# streamer really streamed.
	_t_end_usec = Time.get_ticks_usec()
	_fail(travel >= MIN_TRAVEL_M, "the player travelled the measured route",
		{"travel_m": travel, "min_m": MIN_TRAVEL_M})
	_fail(built > built_at_start,
		"the streamer built chunks while the player was walking",
		{"built_before": built_at_start, "built_after": built})
	_fail(unloaded > unloaded_at_start,
		"the streamer unloaded chunks while the player was walking",
		{"unloaded_before": unloaded_at_start, "unloaded_after": unloaded})
	_fail(peak_tris > 0 and peak_colliders > 0,
		"the streamed world has real geometry and real collision",
		{"triangles": peak_tris, "colliders": peak_colliders})

	# The instrument has to be able to disagree with the engine, and it has
	# to be validated against something. The wall clock is validated against
	# the total elapsed time of the measured section: if the per-sample
	# numbers did not add up to the time that actually passed, they would be
	# a number about nothing.
	var wall_sum := 0.0
	for v in wall_samples:
		wall_sum += float(v)
	var wall_total := float(_t_end_usec - _t_start_usec) / 1000.0
	_fail(wall_total > 0.0 and absf(wall_sum - wall_total) / wall_total < 0.25,
		"the wall-clock samples add up to the elapsed time of the measured section",
		{"sample_sum_ms": wall_sum, "elapsed_ms": wall_total,
		 "ratio": wall_sum / maxf(wall_total, 0.001)})
	# The engine's own TIME_PROCESS monitor is measured against the wall
	# clock, so that the report can state WHY the wall clock is the number
	# that is believed, instead of asserting it.
	var eng := _stats(samples)
	var eng_spread := 0.0
	if float(eng["median_ms"]) > 0.0:
		eng_spread = (float(eng["max_ms"]) - float(eng["min_ms"])) / float(eng["median_ms"])
	var wall_stats := _stats(wall_samples)
	var wall_spread := 0.0
	if float(wall_stats["median_ms"]) > 0.0:
		wall_spread = (float(wall_stats["max_ms"]) - float(wall_stats["min_ms"])) / float(wall_stats["median_ms"])
	_fail(wall_spread > eng_spread,
		"the wall clock resolves the frame cost better than the engine monitor",
		{"engine_relative_spread": eng_spread, "wall_relative_spread": wall_spread})

	_report()
	# Release the laboratory before quitting, so the run does not leave
	# leaked instances behind for the next measurement.
	if lab != null and is_instance_valid(lab):
		lab.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	get_tree().quit(0 if failures == 0 else 1)


# ------------------------------------------------------------------ walker
#
# The walking logic is the one the physical walk test uses: push towards the
# goal, let move_and_slide() find the doorway, add a detour when the body has
# been stuck for a while, hop when the goal is a step up, and let gravity do
# its work when the body falls into an open stairwell.

func _walk_route(waypoints: Array, budget: int) -> Dictionary:
	var best := 999999.0
	var index := 0
	_stuck_frames = 0
	_detour_frames = 0
	_detour_offset = 0.0
	_last_progress = player.global_position
	for frame in budget:
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
			player.qa_input = Vector2.ZERO
			await get_tree().physics_frame
			continue
		var desired := flat.normalized()
		if _detour_frames > 0:
			_detour_frames -= 1
		player.rotation.y = atan2(-desired.x, -desired.z) + _detour_offset
		player.qa_input = Vector2(0.0, 1.0)
		await get_tree().physics_frame
		if goal.y > player.global_position.y + 0.6 and player.is_on_floor():
			_hop_cooldown -= 1
			if _hop_cooldown <= 0:
				_hop_cooldown = 26
				player.velocity.y = 3.8
		_sample()
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


## Take one measurement sample and update the streaming totals.
func _sample() -> void:
	var here := player.global_position
	travel += here.distance_to(_last_pos)
	_last_pos = here
	samples.append(float(Performance.get_monitor(Performance.TIME_PROCESS)) * 1000.0)
	physics_samples.append(float(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)) * 1000.0)
	wall_samples.append(_wall_ms())
	var stats := world.stream_stats
	peak_chunks = maxi(peak_chunks, int(stats.get("peak_chunks", 0)))
	built = int(stats.get("built", 0))
	unloaded = int(stats.get("unloaded", 0))
	var geom: Vector2i = _geometry_totals()
	peak_tris = maxi(peak_tris, geom.x)
	peak_colliders = maxi(peak_colliders, geom.y)


## Wall-clock milliseconds since the previous sample.
##
## This is an INDEPENDENT instrument: the engine's own TIME_PROCESS monitor
## was measured to report a near-constant value under `--fixed-fps`, which
## cannot tell a cheap frame from an expensive one. The wall clock can.
func _wall_ms() -> float:
	var now := Time.get_ticks_usec()
	var delta := float(now - _last_usec) / 1000.0
	_last_usec = now
	return delta


func _fail(ok: bool, label: String, detail: Dictionary = {}) -> void:
	if ok:
		return
	failures += 1
	push_error("PERFORMANCE FAIL: " + label + " " + JSON.stringify(detail))


func _geometry_totals() -> Vector2i:
	var tris := 0
	var cols := 0
	for entry in world.chunks.values():
		var meta: Dictionary = entry.get("meta", {})
		tris += int(meta.get("triangles", 0))
		cols += int(meta.get("colliders", 0))
	return Vector2i(tris, cols)


func _settle(frames: int) -> void:
	for i in frames:
		await get_tree().physics_frame


func _stats(values: Array) -> Dictionary:
	if values.is_empty():
		return {"median_ms": 0.0, "p95_ms": 0.0, "p99_ms": 0.0, "max_ms": 0.0,
			"min_ms": 0.0, "samples": 0}
	var v := values.duplicate()
	v.sort()
	var n := v.size()
	return {
		"median_ms": _at(v, 0.50),
		"p95_ms": _at(v, 0.95),
		"p99_ms": _at(v, 0.99),
		"max_ms": float(v[n - 1]),
		"min_ms": float(v[0]),
		"samples": n,
	}


func _at(sorted_values: Array, q: float) -> float:
	var n := sorted_values.size()
	var i := int(floor(q * float(n - 1)))
	return float(sorted_values[clampi(i, 0, n - 1)])


func _report() -> void:
	var dir := ProjectSettings.globalize_path("res://reports/qa")
	DirAccess.make_dir_recursive_absolute(dir)
	var payload := {
		"engine": Engine.get_version_info(),
		"seed": SEED,
		"headless": true,
		"gpu_frame_time": "UNVERIFIED: headless run has no renderer",
		"note": "CPU numbers from a headless run. The 60 fps frame budget is 16.667 ms.",
		"engine_monitors": ("UNRELIABLE under --fixed-fps: Performance.TIME_PROCESS and "
			+ "Performance.TIME_PHYSICS_PROCESS report the simulation step budget, not the "
			+ "CPU cost. The wall clock is the number that is believed, and it is "
			+ "cross-checked against the elapsed time of the measured section."),
		"process_ms_steady_state": _stats(samples),
		"physics_ms_steady_state": _stats(physics_samples),
		"wall_ms_steady_state": _stats(wall_samples),
		"process_ms_cold_start": _stats(cold_samples),
		"physics_ms_cold_start": _stats(cold_physics_samples),
		"wall_ms_cold_start": _stats(cold_wall_samples),
		"route": {
			"travelled_m": travel,
			"warmup_frames": WARMUP_FRAMES,
			"measured_frames": samples.size(),
			"elapsed_ms": float(_t_end_usec - _t_start_usec) / 1000.0,
			"legs": legs,
		},
		"streaming": {
			"chunks_built_total": built,
			"chunks_built_during_measurement": built - built_at_start,
			"chunks_unloaded_total": unloaded,
			"chunks_unloaded_during_measurement": unloaded - unloaded_at_start,
			"peak_chunks": peak_chunks,
			"peak_triangles": peak_tris,
			"peak_colliders": peak_colliders,
		},
		"memory_static_mb": float(Performance.get_monitor(Performance.MEMORY_STATIC)) / 1048576.0,
		"failures": failures,
	}
	var f := FileAccess.open(dir + "/continuity_performance.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(payload, "  "))
		f.close()
	var p: Dictionary = payload["process_ms_steady_state"]
	var c: Dictionary = payload["process_ms_cold_start"]
	var w: Dictionary = payload["wall_ms_steady_state"]
	var wc: Dictionary = payload["wall_ms_cold_start"]
	print("PERFORMANCE wall steady median=%.3fms p95=%.3fms p99=%.3fms max=%.3fms | wall cold median=%.3fms max=%.3fms | engine-process steady median=%.3fms max=%.3fms | engine cold median=%.3fms max=%.3fms"
		% [w["median_ms"], w["p95_ms"], w["p99_ms"], w["max_ms"],
			wc["median_ms"], wc["max_ms"],
			p["median_ms"], p["max_ms"], c["median_ms"], c["max_ms"]])
	print("PERFORMANCE streaming built=%d(+%d) unloaded=%d(+%d) peak_chunks=%d peak_tris=%d peak_colliders=%d travel=%.1fm failures=%d"
		% [built, built - built_at_start, unloaded, unloaded - unloaded_at_start,
			peak_chunks, peak_tris, peak_colliders, travel, failures])
