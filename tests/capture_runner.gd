extends Node
## Rendered evidence capture (needs a display: real GPU, or Xvfb + Mesa lavapipe):
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver vulkan \
##       res://tests/CaptureRunner.tscn -- --qa --levels=L000 [--w=640] [--frames=40]
## For each level: loads it in QA mode, poses the camera at the level's curated
## shots, waits for streaming/lights, saves JPEGs to res://reports/screenshots/
## and a render-timing sample to res://reports/qa/capture_results.json.
## Every image is a real engine frame; labels record engine/renderer/seed.

var args := {}
var out_rows: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1]
	DisplayServer.window_set_size(Vector2i(int(args.get("rw", "1280")), int(args.get("rh", "720"))))
	call_deferred("_run")


func _run() -> void:
	await get_tree().process_frame
	var ids: Array = str(args.get("levels", ",".join(LevelRegistry.spawnable_ids()))).split(",")
	for sid in ids:
		await _capture_level(sid)
	var info := {"engine": Engine.get_version_info()["string"], "driver": RenderingServer.get_current_rendering_driver_name(),
		"adapter": RenderingServer.get_video_adapter_name(), "vendor": RenderingServer.get_video_adapter_vendor(),
		"note": "Software rasteriser timings (llvmpipe/lavapipe) are NOT representative of GPU performance.",
		"captured": Time.get_datetime_string_from_system(true), "levels": out_rows}
	var gp := ProjectSettings.globalize_path(args.get("out", "res://reports/qa/capture_results.json"))
	DirAccess.make_dir_recursive_absolute(gp.get_base_dir())
	var f := FileAccess.open(gp, FileAccess.WRITE)
	f.store_string(JSON.stringify(info, "  "))
	f.close()
	print("CAPTURE DONE ", out_rows.size())
	get_tree().quit(0)


func _capture_level(sid: String) -> void:
	SessionState.set_mode(SessionState.Mode.QA)
	SessionState.qa_seed_override = int(args.get("seed", "1001"))
	TransitionService.pending_arrival = "start"
	TransitionService.qa_intercept = true
	var packed := load(LevelRegistry.scene_path(sid)) as PackedScene
	if packed == null:
		out_rows.append({"stable_id": sid, "error": "no scene"})
		return
	var lvl := packed.instantiate() as LevelBase
	get_tree().root.add_child(lvl)
	get_tree().current_scene = lvl
	var t0 := Time.get_ticks_msec()
	while not lvl.built and Time.get_ticks_msec() - t0 < 30000:
		await get_tree().process_frame
	Overlay.set_capture_mode(true)
	var shots: Array = lvl.qa_capture_plan()
	var files: Array = []
	var w := int(args.get("w", "640"))
	var frames := int(args.get("frames", "40"))
	for shot in shots:
		if shot.has("prepare") and (shot["prepare"] as Callable).is_valid():
			await (shot["prepare"] as Callable).call()
		lvl.player.frozen = true
		lvl.player.global_position = (shot["pos"] as Vector3) - Vector3.UP * Player.EYE_STAND
		var cam := lvl.player.camera
		var look: Vector3 = shot["target"]
		lvl.player.look_at_from_position(lvl.player.global_position, Vector3(look.x, lvl.player.global_position.y, look.z), Vector3.UP)
		lvl.player.rotation = Vector3(0, lvl.player.rotation.y, 0)
		var flat := Vector2(look.x - (shot["pos"] as Vector3).x, look.z - (shot["pos"] as Vector3).z).length()
		lvl.player.head.rotation.x = atan2(look.y - (shot["pos"] as Vector3).y, maxf(flat, 0.01))
		if shot.has("flashlight"):
			lvl.player.flashlight.visible = shot["flashlight"]
		Telemetry.start()
		for i in frames:
			await get_tree().process_frame
		var perf := Telemetry.stop()
		var img := get_viewport().get_texture().get_image()
		var h := int(round(float(w) * img.get_height() / img.get_width()))
		img.resize(w, h, Image.INTERPOLATE_LANCZOS)
		var rel := "res://reports/screenshots/%s_%s.jpg" % [sid, shot["name"]]
		var gp := ProjectSettings.globalize_path(rel)
		DirAccess.make_dir_recursive_absolute(gp.get_base_dir())
		img.save_jpg(gp, float(args.get("q", "0.72")))
		files.append({"file": rel, "shot": shot["name"], "pos": shot["pos"], "frame_ms_mean": perf.get("mean_ms", 0.0)})
		print("captured ", rel, " ", perf.get("mean_ms", 0.0), " ms")
	out_rows.append({"stable_id": sid, "seed": lvl.level_seed, "shots": files})
	lvl.queue_free()
	get_tree().current_scene = null
	await get_tree().process_frame
	await get_tree().process_frame
