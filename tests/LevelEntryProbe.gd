extends Node
## DEV24 entry acceptance probe. One fresh Godot process per level.
## Exercises the exact TransitionService.dev_jump path used by F3,
## then verifies a built LevelBase, player, and a safe start spawn.
## This is a real native test, not a JSON/scene-exists shortcut.

const REPORT_DIR := "res://reports/qa/entry_audit/levels"
const MAX_WAIT_MS := 90000

var _sid := ""
var _signal_loaded := false
var _signal_error := ""
var _report: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run_probe")


func _on_loaded(sid: String) -> void:
	if sid == _sid:
		_signal_loaded = true


func _on_failed(sid: String, why: String) -> void:
	if sid == _sid:
		_signal_error = why


func _run_probe() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--level="):
			_sid = arg.trim_prefix("--level=")
	_report = {"level": _sid, "status": "FAIL", "engine_native": true,
		"test": "real F3 developer jump and safe spawn", "stage": "preflight",
		"reason": "", "build_ms": -1, "spawn_report": {}}
	if _sid == "" or not LevelRegistry.has_level(_sid):
		_finish("unknown level or --level missing")
		return
	_report["scene"] = LevelRegistry.scene_path(_sid)
	_report["manifest_status"] = str(LevelRegistry.get_entry(_sid).get("status", ""))
	if not LevelRegistry.is_spawnable(_sid):
		_finish("F3 refuses this level: scene not spawnable")
		return
	# The probe must survive TransitionService replacing the active scene.
	# Clear the scene pointer; this probe is a root child, not a level.
	get_tree().current_scene = null
	TransitionService.level_loaded.connect(_on_loaded)
	TransitionService.load_failed.connect(_on_failed)
	_report["stage"] = "developer_jump"
	TransitionService.dev_jump(_sid, "start")
	var deadline := Time.get_ticks_msec() + MAX_WAIT_MS
	while Time.get_ticks_msec() < deadline:
		if _signal_error != "":
			_finish("TransitionService.load_failed: " + _signal_error)
			return
		if _signal_loaded and not TransitionService.loading:
			break
		await get_tree().process_frame
	if not _signal_loaded or TransitionService.loading:
		_finish("load did not finish in 90 seconds")
		return
	_report["stage"] = "scene_and_player"
	var scene := get_tree().current_scene as LevelBase
	if scene == null:
		_finish("current scene is not a LevelBase")
		return
	if not scene.built or scene.stable_id != _sid:
		_finish("wrong or unbuilt scene: " + scene.stable_id)
		return
	if scene.get_script() == null or not (scene.get_script() as Script).can_instantiate():
		_finish("scene root script is not instantiable")
		return
	if not is_instance_valid(scene.player) or not scene.player.is_inside_tree():
		_finish("player missing")
		return
	_report["spawn_report"] = scene.spawn_report.duplicate(true)
	_report["build_ms"] = scene.build_ms
	if not scene.spawn_report.get("spawn_ok", false):
		_finish("player spawned without a safe floor or water location")
		return
	if scene.spawn_report.get("used_arrival", "") != "start":
		_finish("F3 start arrival silently fell back to a different arrival")
		return
	_report["stage"] = "physics_settle"
	var initial_y: float = scene.player.global_position.y
	for tick in 15:
		await get_tree().physics_frame
	if not is_instance_valid(scene.player):
		_finish("player vanished during physics")
		return
	var end_y: float = scene.player.global_position.y
	_report["spawn_y_before"] = initial_y
	_report["spawn_y_after"] = end_y
	if end_y < initial_y - 1.5:
		_finish("player fell more than 1.5 m immediately after entering")
		return
	_report["metrics"] = _metrics(scene)
	_report["stage"] = "complete"
	_report["status"] = "PASS"
	_report["reason"] = "loaded via real developer transition, safe player spawn, 15 physics ticks"
	_write_and_quit(0)


## Content metrics used to flag empty/placeholder levels (counts, not judgement).
func _metrics(scene: Node) -> Dictionary:
	var m := {"mesh_instances": 0, "multimesh_instances": 0, "triangles": 0, "lights": 0,
		"collision_shapes": 0, "exit_triggers": 0, "interactables": 0, "glb_models": 0,
		"materials": 0, "audio_players": 0}
	var mats := {}
	var aabb := AABB()
	var first := true
	var stack: Array[Node] = [scene]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			if mi.mesh == null:
				continue
			m["mesh_instances"] += 1
			for si in mi.mesh.get_surface_count():
				var mat: Material = mi.get_active_material(si)
				if mat:
					mats[mat.get_rid()] = true
				var arr := mi.mesh.surface_get_arrays(si) if mi.mesh is ArrayMesh else []
				if arr.size() > Mesh.ARRAY_INDEX and arr[Mesh.ARRAY_INDEX] != null:
					m["triangles"] += (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3
				elif arr.size() > Mesh.ARRAY_VERTEX and arr[Mesh.ARRAY_VERTEX] != null:
					m["triangles"] += (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() / 3
			var box := mi.global_transform * mi.get_aabb()
			if box.size.length() < 2000.0:
				aabb = box if first else aabb.merge(box)
				first = false
		elif n is MultiMeshInstance3D:
			var mm := n as MultiMeshInstance3D
			m["multimesh_instances"] += mm.multimesh.instance_count if mm.multimesh else 0
		elif n is Light3D:
			m["lights"] += 1
		elif n is CollisionShape3D:
			m["collision_shapes"] += 1
		elif n is AudioStreamPlayer3D or n is AudioStreamPlayer:
			m["audio_players"] += 1
		if n is ExitTrigger:
			m["exit_triggers"] += 1
		elif n is Interactable:
			m["interactables"] += 1
		if str(n.name).begins_with("GLB_"):
			m["glb_models"] += 1
	m["materials"] = mats.size()
	m["footprint_x"] = snappedf(aabb.size.x, 0.1)
	m["footprint_y"] = snappedf(aabb.size.y, 0.1)
	m["footprint_z"] = snappedf(aabb.size.z, 0.1)
	return m


func _finish(reason: String) -> void:
	_report["reason"] = reason
	_write_and_quit(1)


func _write_and_quit(code: int) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(REPORT_DIR))
	var destination := ProjectSettings.globalize_path(REPORT_DIR + "/" + (_sid if _sid != "" else "missing") + ".json")
	var f := FileAccess.open(destination, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(_report, "  ") + "\n")
		f.close()
	print("ENTRY_PROBE " + _sid + " " + str(_report["status"]) + " " + str(_report["reason"]))
	get_tree().quit(code)
