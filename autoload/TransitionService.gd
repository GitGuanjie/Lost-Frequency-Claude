extends Node
## Rule-checked travel between levels. Story travel only follows exits that a
## level manifest declares and that cite a source (or are labelled ADAPTATION).
## Developer jumps are a separate channel that never writes the story save.

signal level_loaded(sid: String)
signal transition_requested(edge: Dictionary)   # also emitted in QA intercept mode
signal load_failed(sid: String, reason: String)

const MAIN_MENU := "res://ui/MainMenu.tscn"

var loading := false
var pending_arrival := "start"
var pending_restore: Dictionary = {}   # checkpoint pos/yaw restore for Continue
var arrived_via: Dictionary = {}       # edge used to enter the current level
var qa_intercept := false
var qa_log: Array = []
var _edge_cache: Dictionary = {}       # edge id -> edge dict (from manifests)
var qa_seamless := false               # QA story suite exercises the seamless path
var carry: Dictionary = {}             # player state carried across a seamless switch
var _prefetched: Dictionary = {}       # scene path -> true (threaded load requested)


## Start loading a destination scene in the background (called near exits).
func prefetch(sid: String) -> void:
	var path := LevelRegistry.scene_path(sid)
	if path == "" or _prefetched.has(path) or not ResourceLoader.exists(path):
		return
	if ResourceLoader.load_threaded_request(path, "PackedScene", true) == OK:
		_prefetched[path] = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


# ------------------------------------------------------------------ edges

func exits_of(sid: String) -> Array:
	var e := LevelRegistry.get_entry(sid)
	if e.is_empty():
		return []
	var out: Array = []
	for x in e.get("impl", {}).get("exits", []):
		var d: Dictionary = (x as Dictionary).duplicate()
		d["from"] = sid
		out.append(d)
	return out


func get_edge(edge_id: String) -> Dictionary:
	if _edge_cache.has(edge_id):
		return _edge_cache[edge_id]
	var parts := edge_id.split(">")
	if parts.size() < 2:
		return {}
	for x in exits_of(parts[0]):
		if x.get("id", "") == edge_id:
			_edge_cache[edge_id] = x
			return x
	return {}


## Called by ExitTrigger nodes when their (sourced) condition is met.
func request_exit(edge_id: String) -> void:
	var edge := get_edge(edge_id)
	if edge.is_empty():
		push_error("Unknown exit edge: " + edge_id)
		Overlay.toast("Route error: unknown exit " + edge_id, 4.0)
		return
	if qa_intercept:
		qa_log.append(edge)
		transition_requested.emit(edge)
		return
	if loading:
		return
	if edge.get("debug_only", false) and not SessionState.is_developer():
		return
	if SessionState.is_story() and edge.get("from", "") != SessionState.current_level:
		push_warning("Exit %s does not belong to current level" % edge_id)
		return
	var to: String = edge.get("to", "")
	if to == "@origin":
		# canon "return the way you came" (e.g. Level 188's entry window)
		to = str(arrived_via.get("from", previous_level()))
		edge = edge.duplicate()
		edge["to"] = to
	transition_requested.emit(edge)
	var allowed := LevelRegistry.is_playable(to) if SessionState.is_story() else LevelRegistry.is_spawnable(to)
	SaveService.record_edge(edge)
	if not allowed:
		var nm := LevelRegistry.display_name(to) if LevelRegistry.has_level(to) else str(edge.get("to_label", to))
		SaveService.save_story("route-witnessed")
		var back := previous_level()
		if back != "" and LevelRegistry.is_spawnable(back) and back != SessionState.current_level:
			Overlay.confirm("This documented route leads to %s, which is not built in this release (IN DEVELOPMENT). The route is now in your journal.\n\nRELEASE BOUNDARY (not canon): return to %s to continue your expedition?" % [nm, LevelRegistry.display_name(back)],
				func(): load_level(back, "from_" + SessionState.current_level, "release-boundary"))
		else:
			Overlay.toast("This documented route leads to %s — not built in this release (IN DEVELOPMENT)." % nm, 6.0)
		return
	arrived_via = edge
	load_level(to, edge.get("arrival", "from_" + str(edge.get("from", ""))), "exit:" + edge_id)


## The level visited before the current one (journal order), "" if none.
func previous_level() -> String:
	var lv: Array = SaveService.scope()["journal"]["levels_visited"]
	var edges: Array = SaveService.scope()["journal"]["edges"]
	for i in range(edges.size() - 1, -1, -1):
		var e: Dictionary = edges[i]
		if e.get("to", "") == SessionState.current_level and e.get("from", "") != SessionState.current_level:
			return e.get("from", "")
	for i in range(lv.size() - 1, -1, -1):
		if lv[i] != SessionState.current_level:
			return lv[i]
	return ""


# --------------------------------------------------------------- top level

func new_expedition() -> void:
	SessionState.set_mode(SessionState.Mode.STORY)
	SaveService.new_story()
	SaveService.save_story("new")
	arrived_via = {}
	load_level("L000", "start", "new")


func continue_expedition() -> void:
	SessionState.set_mode(SessionState.Mode.STORY)
	SaveService.load_story()
	var cp: Dictionary = SaveService.story.get("checkpoint", {})
	var sid: String = cp.get("level", "L000")
	if not LevelRegistry.is_playable(sid):
		sid = "L000"
		cp = {}
	pending_restore = cp
	load_level(sid, cp.get("arrival", "start"), "continue")


func dev_jump(sid: String, arrival := "start") -> void:
	if not LevelRegistry.is_spawnable(sid):
		Overlay.toast("%s is LOCKED / IN DEVELOPMENT — no scene to spawn." % LevelRegistry.display_name(sid), 4.0)
		return
	if SessionState.is_story() and SessionState.in_gameplay:
		SaveService.save_story("before-developer-mode")
	SessionState.set_mode(SessionState.Mode.DEVELOPER)
	arrived_via = {}
	load_level(sid, arrival, "developer")


func reload_checkpoint() -> void:
	var s := SaveService.scope()
	var cp: Dictionary = s.get("checkpoint", {})
	var sid: String = cp.get("level", SessionState.current_level)
	if sid == "" or not LevelRegistry.is_spawnable(sid):
		sid = SessionState.current_level
	pending_restore = cp if cp.get("level", "") == sid else {}
	load_level(sid, cp.get("arrival", "start"), "restart")


func goto_main_menu() -> void:
	if SessionState.is_story() and SessionState.in_gameplay:
		SaveService.save_story("to-menu")
	get_tree().paused = false
	SessionState.in_gameplay = false
	SessionState.current_level = ""
	SessionState.set_mode(SessionState.Mode.STORY)
	Overlay.close_all()
	get_tree().change_scene_to_file(MAIN_MENU)


# ----------------------------------------------------------------- loading

func load_level(sid: String, arrival: String, reason: String) -> void:
	if loading:
		return
	var path := LevelRegistry.scene_path(sid)
	if path == "" or not ResourceLoader.exists(path):
		load_failed.emit(sid, "scene missing")
		Overlay.toast("Cannot load %s: scene missing." % sid, 5.0)
		return
	loading = true
	pending_arrival = arrival
	get_tree().paused = false
	Overlay.close_all()
	var seamless: bool = Settings.get_value("seamless") and reason.begins_with("exit:") and (not SessionState.qa_run or qa_seamless)
	if seamless:
		# keep the old level alive while the new one loads in the background
		if not _prefetched.has(path):
			ResourceLoader.load_threaded_request(path, "PackedScene", true)
			_prefetched[path] = true
		Overlay.glitch(0.6)
		while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			Overlay.glitch(0.6)
			await get_tree().process_frame
		_capture_carry()
		Overlay.glitch(1.0)
		await get_tree().process_frame
	else:
		carry = {}
		Overlay.show_loading(LevelRegistry.display_name(sid), reason)
		await Overlay.fade_to(1.0, 0.35)
	SessionState.in_gameplay = false
	# drop the old level first so both worlds never coexist in memory
	var old := get_tree().current_scene
	if old:
		old.queue_free()
	await get_tree().process_frame
	if not _prefetched.has(path):
		var err := ResourceLoader.load_threaded_request(path, "PackedScene", true)
		if err != OK:
			_fail(sid, "load request failed: " + error_string(err))
			return
	_prefetched.erase(path)
	var progress := []
	while true:
		var st := ResourceLoader.load_threaded_get_status(path, progress)
		if st == ResourceLoader.THREAD_LOAD_LOADED:
			break
		if st == ResourceLoader.THREAD_LOAD_FAILED or st == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			_fail(sid, "resource load failed")
			return
		Overlay.set_loading_progress(float(progress[0]) if progress.size() > 0 else 0.0)
		await get_tree().process_frame
	var packed := ResourceLoader.load_threaded_get(path) as PackedScene
	if packed == null:
		_fail(sid, "not a PackedScene")
		return
	SessionState.current_level = sid
	var inst := packed.instantiate()
	get_tree().root.add_child(inst)
	get_tree().current_scene = inst
	# LevelBase emits level_loaded after build + player placement
	await level_loaded
	SaveService.mark_visited(sid)
	if reason != "continue" and reason != "restart":
		# an arrival is a checkpoint: Continue must resume in the level you reached
		SaveService.set_checkpoint(sid, arrival, null)
	if SessionState.is_story():
		SaveService.save_story("arrive:" + sid)
	Overlay.hide_loading()
	if seamless:
		Overlay.glitch(0.8)
		carry = {}
	else:
		await Overlay.fade_to(0.0, 0.6)
	loading = false


func _capture_carry() -> void:
	carry = {}
	var ps := get_tree().get_nodes_in_group("player")
	if ps.is_empty():
		return
	var p := ps[0] as Player
	var local_v := p.global_transform.basis.inverse() * p.velocity
	carry = {"pitch": p.look_pitch, "local_velocity": local_v, "flashlight": p.flashlight.visible, "crouch": p.crouching}


func _fail(sid: String, reason: String) -> void:
	push_error("Level load failed %s: %s" % [sid, reason])
	load_failed.emit(sid, reason)
	loading = false
	Overlay.hide_loading()
	Overlay.fade_to(0.0, 0.2)
	Overlay.toast("Loading %s failed (%s). Returned to the menu." % [sid, reason], 6.0)
	get_tree().change_scene_to_file(MAIN_MENU)


## LevelBase calls this once its world is built and the player placed.
func notify_level_ready(sid: String) -> void:
	pending_restore = {}
	level_loaded.emit(sid)
