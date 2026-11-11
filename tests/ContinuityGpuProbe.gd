extends Node
## The level of detail and the occlusion culling, measured on a real GPU.
##
## The numbers here are the renderer's numbers, so this test has to run
## WINDOWED. The headless display server has no renderer at all: a headless
## run of this file would report zero draw calls and a perfect frame time,
## which is exactly the kind of green that means nothing. It is therefore
## NOT part of the headless gate - it is a separate command with its own
## report.
##
## Run:
##   godot --path . --rendering-driver d3d12 res://tests/ContinuityGpuProbe.tscn -- --probe
##
## The three configurations are measured in an INTERLEAVED order, several
## rounds each. A laptop GPU that is shared with the desktop drifts, and a
## number measured now and a number measured two minutes later are not the
## same measurement. Interleaving turns that drift into a common factor
## that hits every configuration equally, so the comparison survives it.

const SEED := 1337
const ROUNDS := 3
const WARMUP := 20
const FRAMES := 60
const REPORT_PATH := "res://reports/qa/continuity_gpu_probe.json"

var lab: Node3D
var world: ChunkWorld3D
var camera: Camera3D
var findings: Array = []
var failures := 0
var _deadline_ms := 0
var _samples: Dictionary = {}
var _details: Dictionary = {}
var _occluder_count := 0


## The level of detail has to work in both directions.
##
## The camera walks away from the chunk it started on. The chunk it left
## behind is still resident - the streamer unloads further away than that -
## so it has to have given its detail back. A level of detail that only ever
## adds detail saves nothing in a world that is explored.
func _check_detail_lifecycle() -> void:
	var home := Vector3i(0, 0, 0)
	world.lod_enabled = true
	world.lod_near_chunks = 1
	world.lod_far_chunks = 2
	for k in world.chunks.keys().duplicate():
		world._unload(k)
	camera.position = Vector3(11.0, 1.7, 11.0)
	world.build_around(camera.global_position, world.radius_xz, world.radius_y)
	await _settle_stream()
	var before := int(world.chunks.get(home, {}).get("detail", -1))
	# Three chunks away: far enough for the detail to go, close enough for
	# the chunk to still be resident.
	camera.position = Vector3(11.0 + 3.0 * 24.0, 1.7, 11.0)
	await _settle_stream()
	var still_there := world.chunks.has(home)
	var after := int(world.chunks.get(home, {}).get("detail", -1))
	_check(before == 0,
		"the chunk the camera started on was built with full detail",
		{"detail": before})
	_check(not still_there or after > before,
		"the chunk the camera left behind gave its detail back",
		{"still_resident": still_there, "detail_before": before, "detail_after": after})
	# Put the camera back where the measurement expects it.
	camera.position = Vector3(11.0, 1.7, 11.0)
	camera.look_at(Vector3(41.0, 1.7, 11.0))
	await _settle_stream()


## Wait until the streamer has stopped changing the resident set.
func _settle_stream() -> void:
	var last := -1
	var stable := 0
	while stable < 8:
		await get_tree().process_frame
		var n := world.chunks.size()
		if n == last and n > 0:
			stable += 1
		else:
			stable = 0
		last = n


## How many chunks were built at each level of detail. This is the proof
## that the level of detail actually changed the world and was not a
## setting that no chunk ever reached.
func _detail_histogram() -> Dictionary:
	var histogram := {}
	for k in world.chunks.keys():
		var level := int(world.chunks[k].get("detail", 0))
		histogram[level] = int(histogram.get(level, 0)) + 1
	return histogram


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")


func _process(_delta: float) -> void:
	if _deadline_ms > 0 and Time.get_ticks_msec() > _deadline_ms:
		_deadline_ms = 0
		push_error("GPU PROBE: wall clock timeout")
		_report()
		get_tree().quit(2)


func _check(ok: bool, label: String, detail: Dictionary = {}) -> void:
	var entry := {"check": label, "pass": ok}
	if not detail.is_empty():
		entry["detail"] = detail
	findings.append(entry)
	if not ok:
		failures += 1
		push_error("GPU PROBE FAIL: " + label + " " + JSON.stringify(detail))


func _run() -> void:
	_deadline_ms = Time.get_ticks_msec() + 20 * 60 * 1000
	if DisplayServer.get_name() == "headless":
		# Loudly, on purpose. A headless run of this file would measure
		# nothing at all and would still look like a pass.
		push_error("GPU PROBE: the headless display server has no renderer. "
			+ "Run this windowed: godot --path . res://tests/ContinuityGpuProbe.tscn -- --probe")
		get_tree().quit(2)
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_build_environment()
	lab = load("res://labs/Level0ContinuityLab.tscn").instantiate()
	world = ChunkWorld3D.new()
	world.name = "QAWorld"
	world.seed_value = SEED
	world.world_id = "QA_GPU_PROBE"
	world.disk_persistence_enabled = false
	world.radius_xz = 2
	world.radius_y = 1
	world.unload_xz = 3
	world.unload_y = 2
	world.builds_per_frame = 16
	lab.world = world
	world.builder = lab._build_chunk
	add_child(world)

	camera = Camera3D.new()
	camera.name = "ProbeCamera"
	add_child(camera)
	camera.position = Vector3(11.0, 1.7, 11.0)
	camera.look_at(Vector3(41.0, 1.7, 11.0))
	camera.current = true
	world.target = camera

	var modes := ["baseline", "lod_geometry", "lod", "lod_occlusion"]
	for round_index in range(ROUNDS):
		for mode in modes:
			await _configure(mode)
			var sample := await _measure()
			if not _samples.has(mode):
				_samples[mode] = []
			_samples[mode].append(sample)
			_details[mode] = _detail_histogram()
			printerr("GPU PROBE round " + str(round_index) + " " + mode + " "
				+ "draws=" + str(int(sample["draw_calls"]))
				+ " objects=" + str(int(sample["objects"]))
				+ " tris=" + str(int(sample["primitives"]))
				+ " frame_ms=" + ("%.2f" % float(sample["frame_ms"]))
				+ " details=" + str(_details[mode]))

	var summary := {}
	for mode in modes:
		var list: Array = _samples.get(mode, [])
		if list.is_empty():
			continue
		summary[mode] = {
			"draw_calls": _median(_column(list, "draw_calls")),
			"objects": _median(_column(list, "objects")),
			"primitives": _median(_column(list, "primitives")),
			"frame_ms": _median(_column(list, "frame_ms")),
			"rounds": list.size(),
		}
	var base: Dictionary = summary.get("baseline", {})
	var geom: Dictionary = summary.get("lod_geometry", {})
	var lod: Dictionary = summary.get("lod", {})
	var occ: Dictionary = summary.get("lod_occlusion", {})

	# The instrument has to prove that it is measuring what it claims to
	# measure. Occlusion culling is a project setting in Godot 4.5, and when
	# it is off the "lod_occlusion" configuration is byte for byte the same
	# world as "lod" - the comparison would then be a comparison of a world
	# with itself, and it would look like a result.
	var culling_on := bool(ProjectSettings.get_setting(
		"rendering/occlusion_culling/use_occlusion_culling", false))
	_check(culling_on,
		"the renderer has occlusion culling switched on",
		{"setting": "rendering/occlusion_culling/use_occlusion_culling",
			"value": culling_on})
	var occluders := _count_occluders()
	_occluder_count = occluders
	_check(occluders > 0,
		"the world really contains occluder instances",
		{"occluder_instances": occluders})
	# The level of detail has to have changed SOMETHING. A setting that no
	# chunk ever reaches produces a comparison of a world with itself.
	var base_details: Dictionary = _details.get("baseline", {})
	var lod_details: Dictionary = _details.get("lod", {})
	var reduced := 0
	for level in lod_details.keys():
		if int(level) > 0:
			reduced += int(lod_details[level])
	_check(reduced > 0,
		"the level of detail really lowered the detail of some chunks",
		{"baseline": base_details, "lod": lod_details})
	# And it has to work in BOTH directions. A level of detail that only ever
	# adds detail saves nothing in a world that is explored, because the
	# chunks the wanderer has visited are exactly the ones that are kept.
	await _check_detail_lifecycle()

	if not base.is_empty():
		_check(int(base["draw_calls"]) > 0,
			"the renderer really drew the world",
			{"draw_calls": base["draw_calls"], "objects": base["objects"]})
		_check(int(geom.get("primitives", 0)) < int(base["primitives"]),
			"the geometric level of detail alone draws fewer primitives",
			{"baseline": base["primitives"], "lod_geometry": geom.get("primitives", 0)})
		_check(int(lod.get("draw_calls", 0)) < int(base["draw_calls"]),
			"the level of detail and the visibility range reduce the draw calls",
			{"baseline": base["draw_calls"], "lod": lod.get("draw_calls", 0)})
		_check(int(occ.get("primitives", 0)) <= int(lod.get("primitives", 1)),
			"the occlusion culling does not draw more than the level of detail alone",
			{"lod": lod.get("primitives", 0), "lod_occlusion": occ.get("primitives", 0)})
	_report(summary)


## Rebuild the world in one of the three configurations and wait until the
## streamer has finished.
func _configure(mode: String) -> void:
	for k in world.chunks.keys().duplicate():
		world._unload(k)
	world.lod_enabled = mode != "baseline"
	# The level of detail only bites when the far chunks really are far.
	# With lod_far_chunks equal to the streaming radius no chunk ever leaves
	# the decorative tail, and the measurement compares a world with itself.
	world.lod_near_chunks = 1
	world.lod_far_chunks = 1
	# The visibility range has to be inside the size of the loaded world, or
	# it can never cull anything: two chunks of 24 m reach 48 m.
	#
	# "lod_geometry" is the configuration that separates the two mechanisms:
	# the level of detail rebuilds the far chunks with less geometry, but
	# everything is still DRAWN, so the difference between "baseline" and
	# "lod_geometry" is the geometric level of detail alone.
	world.visibility_range = 0.0
	if mode == "lod" or mode == "lod_occlusion":
		world.visibility_range = 40.0
	lab.occluders_enabled = mode == "lod_occlusion"
	world.build_around(camera.global_position, world.radius_xz, world.radius_y)
	var last := -1
	var stable := 0
	while stable < 6:
		await get_tree().process_frame
		var n := world.chunks.size()
		if n == last and n > 0:
			stable += 1
		else:
			stable = 0
		last = n
	world.apply_visibility_range()
	for i in WARMUP:
		await get_tree().process_frame


## Measure a run of frames: what the renderer drew, and how long the frame
## took. The frame time is measured between two rendered frames, not between
## two process ticks, so it includes the GPU work.
func _measure() -> Dictionary:
	var draws: Array = []
	var objects: Array = []
	var primitives: Array = []
	var frame_ms: Array = []
	for i in range(FRAMES):
		var t0 := Time.get_ticks_usec()
		await RenderingServer.frame_post_draw
		var t1 := Time.get_ticks_usec()
		draws.append(float(Performance.get_monitor(
			Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		objects.append(float(Performance.get_monitor(
			Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)))
		primitives.append(float(Performance.get_monitor(
			Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
		frame_ms.append(float(t1 - t0) / 1000.0)
	return {"draw_calls": _median(draws), "objects": _median(objects),
		"primitives": _median(primitives), "frame_ms": _median(frame_ms)}


## How many occluder instances the built world actually holds. An occluder
## that was never instantiated is an occluder that never culls anything.
func _count_occluders() -> int:
	var count := 0
	for k in world.chunks.keys():
		var node: Node3D = world.chunks[k].get("node")
		if node == null:
			continue
		count += node.find_children("*", "OccluderInstance3D", true, false).size()
	return count


func _column(list: Array, key: String) -> Array:
	var out: Array = []
	for item in list:
		out.append(float(item[key]))
	return out


func _median(values: Array) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	var mid := sorted.size() / 2
	if sorted.size() % 2 == 1:
		return float(sorted[mid])
	return (float(sorted[mid - 1]) + float(sorted[mid])) * 0.5


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


func _report(summary: Dictionary = {}) -> void:
	var dir := ProjectSettings.globalize_path("res://reports/qa")
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(dir + "/continuity_gpu_probe.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({
			"engine": Engine.get_version_info(),
			"renderer": RenderingServer.get_video_adapter_name(),
			"api": RenderingServer.get_video_adapter_api_version(),
			"seed": SEED,
			"status": "PASS" if failures == 0 else "FAIL",
			"checks": findings.size(),
			"failures": failures,
			"native": true,
			"windowed": true,
			"rounds": ROUNDS,
			"frames_per_sample": FRAMES,
			"occlusion_culling_enabled": bool(ProjectSettings.get_setting(
				"rendering/occlusion_culling/use_occlusion_culling", false)),
			"occluder_instances": _occluder_count,
			"detail_histogram": _details,
			"summary": summary,
			"samples": _samples,
			"findings": findings,
		}, "  ") + "\n")
		f.close()
	print("GPU_PROBE %d checks, %d failures" % [findings.size(), failures])
	get_tree().quit(0 if failures == 0 else 1)
