extends Node
## Engine-executed QA harness (run with the real Godot binary):
##   godot --headless --path . --fixed-fps 60 res://tests/QARunner.tscn -- --qa [--levels=L000,L005] [--suite=all]
## Suites: registry, lint, save, ui, levels (load/spawn/exits/nav/bot/determinism).
## Writes res://reports/qa/latest_results.json. Exit code = number of failures (capped).

var results := {"started": "", "engine": "", "suites": {}, "levels": [], "failures": []}
var args := {}
var fails := 0
var _story_fired := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1]
		elif a.begins_with("--"):
			args[a.substr(2)] = true
	results["started"] = Time.get_datetime_string_from_system(true)
	results["engine"] = Engine.get_version_info()["string"]
	results["renderer"] = RenderingServer.get_current_rendering_driver_name() if DisplayServer.get_name() != "headless" else "headless"
	call_deferred("_run")


func check(ok: bool, suite: String, what: String, detail: Variant = null) -> bool:
	if not results["suites"].has(suite):
		results["suites"][suite] = {"passed": 0, "failed": 0, "checks": []}
	var s: Dictionary = results["suites"][suite]
	if ok:
		s["passed"] += 1
	else:
		s["failed"] += 1
		fails += 1
		results["failures"].append("%s: %s %s" % [suite, what, str(detail) if detail != null else ""])
		printerr("FAIL [%s] %s %s" % [suite, what, str(detail) if detail != null else ""])
	s["checks"].append({"ok": ok, "what": what, "detail": str(detail) if detail != null else ""})
	return ok


func _run() -> void:
	var suite: String = args.get("suite", "all")
	await get_tree().process_frame
	# a broken autoload must fail loudly, never produce an empty "0 failures" run
	for an in ["Settings", "LevelRegistry", "SessionState", "SaveService", "TransitionService", "MatLib", "AudioSynth", "Overlay"]:
		var node := get_tree().root.get_node_or_null(an)
		check(node != null and node.get_script() != null and (node.get_script() as Script).can_instantiate(), "framework", "autoload compiles: " + an)
	if suite in ["all", "registry"]:
		_registry_suite()
	if suite in ["all", "lint"]:
		_lint_suite()
	if suite in ["all", "save"]:
		_save_suite()
	if suite in ["all", "ui"]:
		await _ui_suite()
	if suite in ["all", "story"]:
		await _story_suite()
	if suite == "l009_route":
		await _l009_route_suite()
	if suite == "vertical_atrium":
		await _vertical_atrium_suite()
	if suite == "vertical_dev14":
		await _vertical_dev14_suite()
	if suite == "vertical_dev15":
		await _vertical_dev15_suite()
	if suite == "vertical_dev16":
		await _vertical_dev16_suite()
	if suite == "vertical_dev17":
		await _vertical_dev17_suite()
	if suite == "interactions_dev18":
		await _interactions_dev18_suite()
	if suite == "vertical_dev19":
		await _vertical_dev19_suite()
	if suite == "vertical_dev20":
		await _vertical_dev20_suite()
	if suite == "scenario_dev21":
		await _scenario_dev21_suite()
	if suite == "district_dev22":
		await _district_dev22_suite()
	if suite == "landmark_dev23":
		await _landmark_dev23_suite()
	if suite == "expedition_dev24":
		await _expedition_dev24_suite()
	if suite in ["all", "levels"]:
		var ids: Array = []
		if args.has("levels"):
			ids = str(args["levels"]).split(",")
		else:
			ids = LevelRegistry.spawnable_ids()
		for sid in ids:
			await _level_suite(sid)
		_dupe_suite()
	_write()
	var summary := "QA DONE: %d failures; suites=%s" % [fails, JSON.stringify(_suite_counts())]
	print(summary)
	get_tree().quit(mini(fails, 100))


func _suite_counts() -> Dictionary:
	var out := {}
	for k in results["suites"].keys():
		out[k] = [results["suites"][k]["passed"], results["suites"][k]["failed"]]
	return out


func _write() -> void:
	var path: String = args.get("out", "res://reports/qa/latest_results.json")
	var gp := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(gp.get_base_dir())
	# keep the report compact: counts per suite, full detail only for failures
	for k in results["suites"].keys():
		results["suites"][k]["checks"] = (results["suites"][k]["checks"] as Array).filter(func(c): return not c["ok"])
	var f := FileAccess.open(gp, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(results, " "))
		f.close()


# ================================================================ registry

func _registry_suite() -> void:
	var s := "registry"
	check(LevelRegistry.load_error == "", s, "roster loads", LevelRegistry.load_error)
	check(LevelRegistry.count() == 100, s, "exactly 100 roster entries", LevelRegistry.count())
	var ids := {}
	var urls := {}
	var scenes := {}
	for e in LevelRegistry.entries:
		ids[e["stable_id"]] = true
		urls[e["url"]] = true
		check(str(e.get("page_title", "")) != "", s, "page title captured " + e["stable_id"])
		check(str(e.get("cite_authors", "")) != "", s, "cite authors captured " + e["stable_id"])
		check(e.get("source_status", "") in ["RESOLVED", "RESOLVED_TITLE_DIFFERS"], s, "source resolved " + e["stable_id"], e.get("source_status"))
		check(str(e.get("dossier", "")) != "", s, "dossier exists " + e["stable_id"])
		if LevelRegistry.is_spawnable(e["stable_id"]):
			var sc: String = e["scene"]
			check(not scenes.has(sc), s, "unique scene path " + sc)
			scenes[sc] = true
			check(sc.contains(e["stable_id"]), s, "scene path encodes stable id " + sc)
	check(ids.size() == 100, s, "100 unique stable ids", ids.size())
	check(urls.size() == 100, s, "100 unique source URLs", urls.size())
	results["counters"] = LevelRegistry.counters()


# ==================================================================== lint

func _lint_suite() -> void:
	var s := "lint"
	var src := {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/canon/transitions.json"))
	check(data is Dictionary, s, "transitions.json parses")
	if data is Dictionary:
		for e in data["edges"]:
			src[e["id"]] = e
	for e in LevelRegistry.entries:
		var sid: String = e["stable_id"]
		for x in e.get("impl", {}).get("exits", []):
			var id: String = x.get("id", "")
			var basis: String = x.get("basis", "")
			check(basis in ["SOURCE", "ADAPTATION"], s, "exit basis labelled " + id, basis)
			check(id.begins_with(sid + ">"), s, "exit id starts at its level " + id)
			if basis == "SOURCE":
				var ok := src.has(id)
				check(ok, s, "SOURCE exit matches a documented edge " + id)
				if ok:
					check(src[id].get("to") == x.get("to") or src[id].get("to") == null, s, "destination matches source " + id, [src[id].get("to"), x.get("to")])
				check(str(x.get("source_quote", "")) != "", s, "exit carries source quote " + id)
			else:
				check(str(x.get("adaptation_reason", "")) != "", s, "ADAPTATION exit justified " + id)
			check(not x.get("debug_only", false), s, "no debug-only edge in story manifest " + id)


# ==================================================================== save

func _save_suite() -> void:
	var s := "save"
	var prev_mode := SessionState.mode
	SessionState.set_mode(SessionState.Mode.STORY)
	SaveService.new_story(4242)
	results["legacy_save_found_on_machine"] = SaveService.story.get("migrated_from") != null
	SaveService.story["seed"] = 4242
	SaveService.story["migrated_from"] = null
	check(SaveService.save_story("qa-1"), s, "story save writes (atomic)", SaveService.last_error)
	var p := SaveService.story_path()
	check(FileAccess.file_exists(p), s, "story file exists")
	check(SaveService.save_story("qa-2"), s, "second save writes")
	check(FileAccess.file_exists(p + ".bak"), s, "backup kept")
	var before := FileAccess.get_md5(p)
	SessionState.set_mode(SessionState.Mode.DEVELOPER)
	SaveService.dev["flags"]["L000"] = {"dev_marker": true}
	check(not SaveService.save_story("dev-attempt"), s, "developer mode cannot write story save")
	check(FileAccess.get_md5(p) == before, s, "story file unchanged by developer session")
	SessionState.set_mode(SessionState.Mode.STORY)
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_string("{not json")
	f.close()
	check(SaveService.load_story(), s, "corrupted primary falls back", SaveService.last_load_source)
	check(SaveService.last_load_source == "backup", s, "fallback used backup", SaveService.last_load_source)
	check(int(SaveService.story.get("seed", 0)) == 4242, s, "backup content intact")
	SaveService.set_arrival_edge({"id": "L025>L188#1", "from": "L025", "to": "L188"})
	check(SaveService.save_story("arrival-origin"), s, "arrival origin persists to disk")
	SaveService.story = SaveService.fresh_story(12)
	check(SaveService.load_story() and SaveService.story.get("last_arrival_edge", {}).get("from") == "L025", s, "arrival origin recovers on Continue")
	check(SaveService.last_error == "", s, "successful save and reload clear stale error", SaveService.last_error)
	var legacy := {"version": 62, "seed": 777, "level": 37, "missions": {"0": {}, "37": {}, "188": {}}}
	var t := SaveService.fresh_story(1)
	SaveService.migrate_legacy_into(t, legacy, "fixture://v62")
	var mig: Dictionary = t.get("migrated_from", {})
	check(mig.get("imported", false), s, "V62 legacy save imports")
	check(int(t["seed"]) == 777, s, "legacy seed carried")
	check((mig.get("legacy_levels_listed", []) as Array).has("L037"), s, "legacy visit list mapped to stable ids")
	var bad := SaveService.fresh_story(1)
	SaveService.migrate_legacy_into(bad, {"version": 3}, "fixture://unknown")
	check(not bad["migrated_from"].get("imported", true), s, "unknown legacy version refused")
	# tmp-only recovery
	DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(p + ".bak"))
	var good := SaveService.fresh_story(99)
	var tf := FileAccess.open(p + ".tmp", FileAccess.WRITE)
	tf.store_string(JSON.stringify(good))
	tf.close()
	check(SaveService.load_story() and SaveService.last_load_source == "temp", s, "interrupted write recovers from .tmp", SaveService.last_load_source)
	SessionState.set_mode(prev_mode)


# ====================================================================== ui

func _key(code: Key, pressed: bool = true, shift: bool = false) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = pressed
	ev.shift_pressed = shift
	Input.parse_input_event(ev)


func _tap(code: Key, shift: bool = false) -> void:
	_key(code, true, shift)
	await get_tree().process_frame
	_key(code, false, shift)
	await get_tree().process_frame
	await get_tree().process_frame


func _ui_suite() -> void:
	var s := "ui"
	var sid := "L000"
	if not LevelRegistry.is_spawnable(sid):
		check(false, s, "L000 spawnable for UI tests")
		return
	for pn in ["pause_menu", "dev_browser", "settings_panel", "journal_panel", "world_map_panel", "credits_panel", "note_panel", "death_panel", "confirm_panel"]:
		check((Overlay.get(pn) as Control).is_inside_tree(), s, "panel attached to UI tree: " + pn)
	var lvl: LevelBase = await _instance(sid, 9001)
	if lvl == null:
		check(false, s, "UI host level loads")
		return
	SessionState.set_mode(SessionState.Mode.STORY)
	await _tap(KEY_ESCAPE)
	check(Overlay.pause_menu.is_visible_in_tree(), s, "Esc opens pause menu (visible in tree)")
	check(get_tree().paused, s, "Esc pauses gameplay")
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, s, "mouse released in pause", Input.mouse_mode)
	var buttons := 0
	for n in Overlay.pause_menu.find_children("*", "Button", true, false):
		buttons += 1
	check(buttons >= 7, s, "pause menu has its buttons", buttons)
	check(Overlay.get_viewport().gui_get_focus_owner() is Button, s, "pause menu takes keyboard focus")
	await _tap(KEY_ESCAPE)
	check(not Overlay.pause_menu.is_visible_in_tree() and not get_tree().paused, s, "Esc again resumes")
	await _tap(KEY_F3)
	check(Overlay.dev_browser.is_visible_in_tree(), s, "F3 opens developer browser (visible in tree)")
	check(Overlay._dev_list.item_count == 100, s, "browser lists all 100 entries", Overlay._dev_list.item_count)
	Overlay._dev_search.text = "kitty"
	Overlay._dev_refresh()
	check(Overlay._dev_list.item_count >= 1 and Overlay._dev_ids.has("L974"), s, "search finds Kitty's House", Overlay._dev_ids)
	Overlay._dev_search.text = ""
	Overlay._dev_filter.select(3)
	Overlay._dev_refresh()
	var locked_ok := true
	for i in Overlay._dev_ids.size():
		if LevelRegistry.is_spawnable(Overlay._dev_ids[i]):
			locked_ok = false
	check(locked_ok, s, "Locked filter shows only unbuilt entries")
	Overlay._dev_filter.select(0)
	Overlay._dev_refresh()
	await _tap(KEY_ESCAPE)
	check(not Overlay.dev_browser.is_visible_in_tree() and not get_tree().paused, s, "Esc closes browser and resumes")
	# The connection map has different disclosure rules in story/developer mode.
	SaveService.story = SaveService.fresh_story(12345)
	SaveService.mark_visited("L000")
	await _tap(KEY_F6)
	check(Overlay.world_map_panel.is_visible_in_tree(), s, "F6 opens directed world map")
	var story_map: Control = Overlay._world_graph
	check(story_map.get("positions").size() == 1, s, "story graph reveals only discovered L000", story_map.get("positions").keys())
	check(get_tree().paused, s, "world map pauses gameplay")
	await _tap(KEY_F6)
	check(not Overlay.world_map_panel.is_visible_in_tree() and not get_tree().paused, s, "F6 closes map and resumes")
	var before := SessionState.current_level
	await _tap(KEY_F4)
	await get_tree().process_frame
	check(SessionState.current_level == before and not TransitionService.loading, s, "F4 does nothing in story mode")
	await _tap(KEY_F7)
	check(lvl.player.flycam == null, s, "F7 flycam refused in story mode")
	SessionState.set_mode(SessionState.Mode.DEVELOPER)
	await _tap(KEY_F6)
	check(Overlay._world_graph.get("positions").size() == LevelRegistry.spawnable_ids().size(), s, "developer map shows all built levels")
	check(Overlay._world_graph.get("links").size() > 0, s, "developer map shows directed built-world routes")
	await _tap(KEY_F6)
	var pos_before := lvl.player.global_position
	await _tap(KEY_F7)
	check(lvl.player.flycam != null and lvl.player.frozen, s, "F7 flycam in developer mode")
	lvl.player.flycam.global_position += Vector3(5, 3, 5)
	await get_tree().process_frame
	await _tap(KEY_F7)
	check(lvl.player.flycam == null and lvl.player.global_position.distance_to(pos_before) < 0.05, s, "flycam exit rolls back to safe player position")
	for i in 8:
		Overlay.toast("qa burst %d" % i, 0.5)
	await get_tree().process_frame
	check(Overlay.toast_box.get_child_count() <= 5, s, "toast burst is capped without hanging", Overlay.toast_box.get_child_count())
	await _tap(KEY_J)
	check(Overlay.journal_panel.is_visible_in_tree(), s, "J opens journal (visible in tree)")
	await _tap(KEY_ESCAPE)
	check(not Overlay.journal_panel.is_visible_in_tree(), s, "Esc closes journal")
	SessionState.set_mode(SessionState.Mode.QA)
	_free_level(lvl)
	await get_tree().process_frame


# ================================================================== levels

func _instance(sid: String, seed_value: int) -> LevelBase:
	SessionState.set_mode(SessionState.Mode.QA)
	SessionState.qa_seed_override = seed_value
	TransitionService.pending_arrival = "start"
	TransitionService.pending_restore = {}
	TransitionService.qa_intercept = true
	TransitionService.qa_log.clear()
	var packed := load(LevelRegistry.scene_path(sid)) as PackedScene
	if packed == null:
		return null
	var inst := packed.instantiate() as LevelBase
	get_tree().root.add_child(inst)
	get_tree().current_scene = inst
	var t0 := Time.get_ticks_msec()
	while not inst.built and Time.get_ticks_msec() - t0 < 20000:
		await get_tree().process_frame
	return inst if inst.built else null


func _free_level(lvl: Node) -> void:
	if is_instance_valid(lvl):
		lvl.queue_free()
	get_tree().current_scene = null
	get_tree().paused = false
	Overlay.close_all()


func _signature(lvl: Node) -> int:
	var h := 0
	var n := 0
	for cs in lvl.find_children("*", "CollisionShape3D", true, false):
		var c := cs as CollisionShape3D
		if c.get_parent() is StaticBody3D and c.shape is BoxShape3D:
			var p := c.global_position.snapped(Vector3.ONE * 0.05)
			h = hash([h, p, (c.shape as BoxShape3D).size.snapped(Vector3.ONE * 0.05)])
			n += 1
	return hash([h, n])


func _level_suite(sid: String) -> void:
	var s := "level:" + sid
	var rec := {"stable_id": sid}
	var t0 := Time.get_ticks_msec()
	var lvl: LevelBase = await _instance(sid, int(args.get("seed", "1001")))
	rec["load_ms"] = Time.get_ticks_msec() - t0
	if not check(lvl != null, s, "scene loads and builds"):
		rec["qa_status"] = "LOAD_FAILED"
		results["levels"].append(rec)
		return
	var d := lvl.qa_describe()
	rec["build_ms"] = d["build_ms"]
	rec["spawn"] = d["spawn"]
	check(lvl.player != null and lvl.player.is_inside_tree(), s, "player spawned")
	check(d["spawn"].get("spawn_ok", false), s, "spawn clear of collision and on a floor", d["spawn"])
	var space := lvl.get_world_3d().direct_space_state
	var down := PhysicsRayQueryParameters3D.create(lvl.player.global_position + Vector3.UP * 0.5, lvl.player.global_position + Vector3.DOWN * 0.6, 1)
	var in_water := false
	for w in lvl.get_tree().get_nodes_in_group("water"):
		if (w as WaterVolume).contains(lvl.player.global_position + Vector3.UP * 0.5):
			in_water = true
	check(not space.intersect_ray(down).is_empty() or in_water, s, "floor (or water) under spawn")
	var shapes := lvl.find_children("*", "CollisionShape3D", true, false).size()
	rec["collision_shapes"] = shapes
	check(shapes > 0, s, "non-null collision", shapes)
	check(lvl.world_env != null and lvl.world_env.environment != null, s, "environment present")
	print("QA[%s] settle" % sid)
	# --- physics settle: player must not fall through the world
	var y0 := lvl.player.global_position.y
	for i in 30:
		await get_tree().physics_frame
	check(lvl.player.global_position.y > y0 - 1.0 or in_water, s, "player stable on floor after 30 ticks", [y0, lvl.player.global_position.y])
	print("QA[%s] exits" % sid)
	# --- exits
	var man: Dictionary = LevelRegistry.get_entry(sid).get("impl", {})
	var declared: Array = man.get("exits", [])
	rec["exits_declared"] = declared.size()
	var found: Array = d["exits"]
	rec["exits_found"] = found.size()
	if declared.is_empty():
		check(str(man.get("no_exit_reason", "")) != "", s, "level without exits documents why")
	else:
		check(found.size() > 0, s, "at least one physical exit present near start", found.size())
	var found_ids := {}
	for x in found:
		found_ids[x["edge"]] = true
		var ok := false
		for y in declared:
			if y["id"] == x["edge"]:
				ok = true
		check(ok, s, "physical exit is declared in manifest " + x["edge"])
	print("QA[%s] nav" % sid)
	# --- navigation reachability + walker bot
	var nav := await _nav_check(lvl, found)
	rec["nav"] = nav
	for e in nav.get("exits", []):
		check(e.get("reachable", false), s, "exit reachable on navmesh " + e["edge"], e)
	var routes: Array = d["routes"]
	if found.is_empty():
		_nav_free(nav)
	if not found.is_empty():
		var bot := await _bot_walk(lvl, nav, found)
		rec["bot"] = bot
		check(bot.get("fired", false), s, "walker bot physically triggers an exit", bot)
		check(bot.get("edge", "") in found_ids, s, "bot fired a declared exit", bot.get("edge", ""))
	print("QA[%s] pause_save" % sid)
	var st: Array = await lvl.qa_self_test()
	for c in st:
		check(c.get("ok", false), s, "self-test: " + str(c.get("what", "")), c.get("detail", null))
	rec["self_tests"] = st.size()
	# --- pause / resume / checkpoint save round-trip on this level
	Overlay.open_pause()
	await get_tree().process_frame
	check(Overlay.pause_menu.is_visible_in_tree() and get_tree().paused, s, "pause menu opens on this level")
	Overlay.close_all()
	await get_tree().process_frame
	check(not get_tree().paused, s, "resume unpauses on this level")
	SessionState.set_mode(SessionState.Mode.STORY)
	SaveService.story = SaveService.fresh_story(5150)
	lvl.checkpoint("qa_checkpoint")
	var cp_ok: bool = SaveService.load_story() and SaveService.story.get("checkpoint", {}).get("level", "") == sid
	check(cp_ok, s, "checkpoint saves and reloads with this level", SaveService.story.get("checkpoint", {}))
	rec["save_tested"] = cp_ok
	SessionState.set_mode(SessionState.Mode.QA)
	print("QA[%s] profile" % sid)
	rec["dup_profile"] = _profile(lvl)
	_free_level(lvl)
	await get_tree().process_frame
	await get_tree().process_frame
	print("QA[%s] determinism" % sid)
	# --- determinism: same seed => same layout; three seeds differ (procedural)
	var sig_a := await _sig_for(sid, 1001)
	var sig_b := await _sig_for(sid, 1001)
	check(sig_a == sig_b, s, "same seed reproduces identical layout")
	var sigs := {sig_a: true}
	for sd in [2002, 3003]:
		sigs[await _sig_for(sid, sd)] = true
	rec["distinct_layouts_over_3_seeds"] = sigs.size()
	if man.get("procedural", false):
		check(sigs.size() == 3, s, "three seeds give three distinct layouts", sigs.size())
	rec["qa_status"] = "ENGINE_SMOKE_PASS" if not _suite_failed(s) else "ENGINE_SMOKE_FAIL"
	results["levels"].append(rec)
	SessionState.qa_seed_override = -1


func _suite_failed(s: String) -> bool:
	return results["suites"].has(s) and results["suites"][s]["failed"] > 0


func _sig_for(sid: String, seed_value: int) -> int:
	var l: LevelBase = await _instance(sid, seed_value)
	if l == null:
		return -1
	var sig := _signature(l)
	_free_level(l)
	await get_tree().process_frame
	await get_tree().process_frame
	return sig


func _nav_check(lvl: LevelBase, found: Array) -> Dictionary:
	var out := {"exits": []}
	var map := NavigationServer3D.map_create()
	NavigationServer3D.map_set_cell_size(map, 0.15)
	NavigationServer3D.map_set_cell_height(map, 0.1)
	NavigationServer3D.map_set_use_async_iterations(map, false)
	NavigationServer3D.map_set_active(map, true)
	var nm := NavigationMesh.new()
	nm.cell_size = 0.15
	nm.cell_height = 0.1
	nm.agent_radius = 0.3
	nm.agent_height = 1.7
	nm.agent_max_climb = 0.3
	nm.agent_max_slope = 45.0
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1
	var c := lvl.player.global_position
	# The Level 9 fixture is deliberately local. Build the street chunks near
	# the body and its fixture targets before baking navigation from collision.
	# Do not stream arbitrary distant scene destinations (some are kilometres away).
	if lvl.stable_id == "L009" and SessionState.is_qa():
		var streamer: Variant = lvl.get("world")
		if streamer is ChunkWorld:
			(streamer as ChunkWorld).build_around(c, 1)
			for candidate in found:
				var target_pos: Vector3 = candidate["pos"]
				if target_pos.distance_to(c) < 128.0:
					(streamer as ChunkWorld).build_around(target_pos, 1)
	var span := 70.0
	for x in found:
		span = maxf(span, (x["pos"] as Vector3).distance_to(c) * 2.0 + 10.0)
	nm.filter_baking_aabb = AABB(Vector3(c.x - span * 0.5, c.y - 12.0, c.z - span * 0.5), Vector3(span, 30.0, span))
	var src := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nm, src, lvl)
	NavigationServer3D.bake_from_source_geometry_data(nm, src)
	out["nav_polygons"] = nm.get_polygon_count()
	var region := NavigationServer3D.region_create()
	NavigationServer3D.region_set_map(region, map)
	NavigationServer3D.region_set_navigation_mesh(region, nm)
	NavigationServer3D.region_set_enabled(region, true)
	var waited := 0
	var it0 := NavigationServer3D.map_get_iteration_id(map)
	while NavigationServer3D.map_get_iteration_id(map) < it0 + 2 and waited < 120:
		await get_tree().physics_frame
		waited += 1
	out["map_regions"] = NavigationServer3D.map_get_regions(map).size()
	out["map_sync_ticks"] = waited
	var start := NavigationServer3D.map_get_closest_point(map, c)
	out["start"] = start
	out["spawn_projection_error"] = c.distance_to(start)
	out["spawn_on_navmesh"] = c.distance_to(start) <= 2.0
	for x in found:
		var tp: Vector3 = x["pos"]
		var sz: Vector3 = x["size"]
		var goal := NavigationServer3D.map_get_closest_point(map, tp)
		var path := NavigationServer3D.map_get_path(map, start, goal, true)
		var reach := false
		if path.size() > 0 and out["spawn_on_navmesh"]:
			var endp: Vector3 = path[path.size() - 1]
			reach = absf(endp.x - tp.x) <= sz.x * 0.5 + 0.8 and absf(endp.z - tp.z) <= sz.z * 0.5 + 0.8 \
				and endp.y <= tp.y + sz.y * 0.5 + 0.5 and endp.y >= tp.y - sz.y * 0.5 - 1.5
		out["exits"].append({"edge": x["edge"], "reachable": reach, "path_points": path.size(), "goal": goal,
			"snap_error": tp.distance_to(goal), "start_projection_error": out["spawn_projection_error"],
			"path": Array(path)})
	out["map"] = map
	out["region"] = region
	return out


## Drive the real CharacterBody3D along the navmesh path with physics and
## require the exit to fire through its normal trigger logic.
func _bot_walk(lvl: LevelBase, nav: Dictionary, found: Array, want_edge: String = "", detect_signal: bool = false) -> Dictionary:
	var target: Dictionary = {}
	for e in nav.get("exits", []):
		if e.get("reachable", false) and (want_edge == "" or e["edge"] == want_edge):
			target = e
			break
	if target.is_empty():
		var misses: Array = []
		for nav_exit in nav.get("exits", []):
			misses.append({"edge": nav_exit.get("edge", ""), "path_points": nav_exit.get("path_points", 0), "snap_error": nav_exit.get("snap_error", -1), "start_projection_error": nav_exit.get("start_projection_error", -1)})
		_nav_free(nav)
		return {"fired": false, "reason": "no reachable exit / invalid navmesh projection", "nav_candidates": misses}
	# Several triggers can share one edge id; pair with the one nearest the
	# navmesh path's end, not simply the last match in the list.
	var trig: Dictionary = {}
	var tpath: Array = target.get("path", [])
	var path_end: Vector3 = tpath[tpath.size() - 1] if tpath.size() > 0 else lvl.player.global_position
	var best_d := INF
	for x in found:
		if x["edge"] == target["edge"]:
			var dd: float = (x["pos"] as Vector3).distance_to(path_end)
			if dd < best_d:
				best_d = dd
				trig = x
	var p := lvl.player
	p.qa_active = true
	var path: Array = target["path"]
	var i := 1
	var ticks := 0
	var max_ticks := 60 * 150
	var fired := false
	var stuck := 0
	var stop_reason := ""
	var progress_samples: Array = []
	var last := p.global_position
	var last_path_index := i
	var best_goal_distance := INF
	var no_goal_progress_seconds := 0
	var reached_trigger_ticks := 0
	TransitionService.qa_log.clear()
	while ticks < max_ticks:
		ticks += 1
		var goal: Vector3 = trig["pos"] if i >= path.size() else path[i]
		var to := goal - p.global_position
		to.y = 0.0
		if i < path.size() and to.length() < 0.45:
			i += 1
			continue
		if to.length() > 0.01:
			p.rotation.y = atan2(-to.x, -to.z)
		p.qa_input = Vector2(0, 1)
		p.qa_sprint = i >= path.size()
		if i >= path.size() and trig.get("kind", "") == "interact":
			for t in lvl.find_children("*", "ExitTrigger", true, false):
				if (t as ExitTrigger).edge_id == trig["edge"]:
					# Never call interact from a distant navmesh point: the real
					# player must be near the trigger before pressing E.
					var e := t as ExitTrigger
					if p.global_position.distance_to(e.global_position) <= 2.2:
						e.interact(p)
		await get_tree().physics_frame
		if trig.get("kind", "") == "waypoint" and Vector2(p.global_position.x - trig["pos"].x, p.global_position.z - trig["pos"].z).length() < 1.2:
			fired = true
			break
		if not TransitionService.qa_log.is_empty() or (detect_signal and _story_fired != ""):
			fired = true
			break
		if not is_instance_valid(p):
			break
		if ticks % 120 == 0 and is_instance_valid(p):
			progress_samples.append({"tick": ticks, "position": str(p.global_position), "goal": str(goal),
				"nav_vertex": i, "slide_collisions": p.get_slide_collision_count(),
				"L009_route_progress": int(lvl.get("qa_prog")) if lvl.stable_id == "L009" else -1})
		# Condition-gated exits are never activated artificially. Remaining in
		# the volume without a transition is a separate, actionable failure.
		if i >= path.size() and to.length() < 0.8 and trig.get("kind", "") != "waypoint":
			reached_trigger_ticks += 1
			if reached_trigger_ticks > 180:
				stop_reason = "at trigger centre for three seconds but exit did not fire (condition/occupancy/geometry)"
				break
		else:
			reached_trigger_ticks = 0
		if ticks % 60 == 0:
			var moved_in_last_second := p.global_position.distance_to(last)
			if moved_in_last_second < 0.15:
				stuck += 1
			else:
				stuck = 0
			last = p.global_position
			var remaining := Vector2(goal.x - p.global_position.x, goal.z - p.global_position.z).length()
			if i > last_path_index or remaining < best_goal_distance - 0.55:
				best_goal_distance = remaining
				last_path_index = i
				no_goal_progress_seconds = 0
			else:
				no_goal_progress_seconds += 1
			if stuck > 8:
				stop_reason = "physically blocked at navigation vertex %d/%d, distance %.2f m, body movement %.2f m, no progress %d s" % [i, path.size(), remaining, moved_in_last_second, no_goal_progress_seconds]
				break
			if no_goal_progress_seconds >= 14:
				stop_reason = "no goal progress at navigation vertex %d/%d for %d s; last movement %.2f m, goal %.2f m away" % [i, path.size(), no_goal_progress_seconds, moved_in_last_second, remaining]
				break
	if is_instance_valid(p):
		p.qa_input = Vector2.ZERO
		p.qa_active = false
	var fired_edge := ""
	if fired and trig.get("kind", "") == "waypoint":
		fired_edge = "waypoint"
	elif fired:
		fired_edge = _story_fired if detect_signal else str(TransitionService.qa_log[0].get("id", ""))
	var res := {"fired": fired, "ticks": ticks, "sim_seconds": ticks / 60.0, "edge": fired_edge,
		"distance_walked": p.stats["distance"] if is_instance_valid(p) else -1.0, "target": target["edge"],
		"path_points": path.size(), "path_index": i, "progress_samples": progress_samples,
		"final_position": str(p.global_position) if is_instance_valid(p) else "player freed",
		"distance_to_target": p.global_position.distance_to(trig["pos"]) if is_instance_valid(p) else -1.0,
		"reason": "triggered" if fired else (stop_reason if stop_reason != "" else ("timed out" if ticks >= max_ticks else "player lost")) }
	_nav_free(nav)
	return res


func _nav_free(nav: Dictionary) -> void:
	if nav.has("region"):
		NavigationServer3D.free_rid(nav["region"])
		nav.erase("region")
	if nav.has("map"):
		NavigationServer3D.free_rid(nav["map"])
		nav.erase("map")
	nav.erase("exits_path")
	for e in nav.get("exits", []):
		e.erase("path")


# ============================================================ focused vertical geometry QA

## This is a physical collision smoke check, not a claim that an AI agent has
## walked all three floors. Verify one reproducible three-storey Level 0 atrium
## without changing the story world, opening exits or teleporting the player.
func _vertical_atrium_suite() -> void:
	var suite := "vertical_atrium"
	var lvl: LevelBase = await _instance("L000", 1001)
	if not check(lvl != null, suite, "Level 0 loads for vertical geometry test"):
		return
	var streamer: ChunkWorld = lvl.get("world") as ChunkWorld
	if not check(streamer != null, suite, "Level 0 has chunk streaming"):
		_free_level(lvl)
		return
	var selected := Vector2i(9999, 9999)
	for cx in range(-12, 13):
		for cz in range(-12, 13):
			if str(lvl.call("kind_of", cx, cz)) == "atrium" and absi(hash([lvl.level_seed, cx * 24, cz * 24, "upper_observation"])) % 3 == 0 and absi(hash([lvl.level_seed, cx * 24, cz * 24, "fourth_stratum"])) % 2 != 0:
				selected = Vector2i(cx, cz)
				break
		if selected.x != 9999:
			break
	if not check(selected.x != 9999, suite, "deterministic upper gallery found"):
		_free_level(lvl)
		return
	var prior_target := streamer.target
	streamer.target = null
	streamer.build_around(Vector3(float(selected.x) * 24.0 + 12.0, 0.0, float(selected.y) * 24.0 + 12.0), 0)
	var meta := streamer.meta_of(selected)
	check(int(meta.get("storeys", 0)) == 3, suite, "three real decks built", meta)
	var ox := float(selected.x) * 24.0
	var oz := float(selected.y) * 24.0
	var upper := 6.25
	# Step onto the upper landing and walk across the 12 m span; both places
	# should have geometry. The stair cut-out must have no third-floor slab.
	await get_tree().physics_frame
	var space := lvl.get_world_3d().direct_space_state
	var landing_query := PhysicsRayQueryParameters3D.create(Vector3(ox + 3.35, upper + 0.5, oz + 13.75), Vector3(ox + 3.35, upper - 0.6, oz + 13.75), 1)
	var bridge_query := PhysicsRayQueryParameters3D.create(Vector3(ox + 12.0, upper + 0.5, oz + 15.9), Vector3(ox + 12.0, upper - 0.6, oz + 15.9), 1)
	var slot_query := PhysicsRayQueryParameters3D.create(Vector3(ox + 3.35, upper + 0.5, oz + 11.0), Vector3(ox + 3.35, upper - 0.6, oz + 11.0), 1)
	var landed := space.intersect_ray(landing_query)
	var bridged := space.intersect_ray(bridge_query)
	var slot_clear := space.intersect_ray(slot_query).is_empty()
	check(not landed.is_empty(), suite, "third-floor stair landing has collision")
	check(not bridged.is_empty(), suite, "cross-void observation bridge has collision")
	check(slot_clear, suite, "ascending stair slot is not roofed over")
	results["vertical_atrium_evidence"] = {"chunk": str(selected), "storeys": meta.get("storeys", 0),
		"landing_hit": not landed.is_empty(), "bridge_hit": not bridged.is_empty(), "slot_clear": slot_clear,
		"scope": "geometry collision smoke only; not player-path proof"}
	streamer.target = prior_target
	_free_level(lvl)
	await get_tree().process_frame



# ============================================================ dev14 vertical collision audit

## HEADLESS engine collision smoke. This probes exact floor patches, real empty
## stair cutouts, and elevated route surfaces with physics rays. It does NOT
## certify human traversal, gamepad movement, clearances across whole paths,
## FPS, screenshot quality, or a native Windows executable.
func _dev14_surface(space: PhysicsDirectSpaceState3D, pos: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(pos + Vector3.UP * 0.45,
		pos + Vector3.DOWN * 0.55, 1)
	return not space.intersect_ray(q).is_empty()


func _vertical_dev14_suite() -> void:
	var suite := "vertical_dev14"
	var evidence := {}
	# Rare Level 0 fourth and fifth strata are found deterministically, without
	# editing the world seed, teleporting through a wall or faking QA progress.
	var lvl: LevelBase = await _instance("L000", 1001)
	if not check(lvl != null, suite, "L000 loads"):
		return
	var streamer: ChunkWorld = lvl.get("world") as ChunkWorld
	var chosen := Vector2i(9999, 9999)
	var fifth := false
	for cx in range(-25, 26):
		for cz in range(-25, 26):
			if str(lvl.call("kind_of", cx, cz)) != "atrium":
				continue
			if absi(hash([lvl.level_seed, cx * 24, cz * 24, "upper_observation"])) % 3 != 0:
				continue
			if absi(hash([lvl.level_seed, cx * 24, cz * 24, "fourth_stratum"])) % 2 != 0:
				continue
			chosen = Vector2i(cx, cz)
			fifth = absi(hash([lvl.level_seed, cx * 24, cz * 24, "fifth_stratum"])) % 3 == 0
			if fifth:
				break
		if fifth:
			break
	if check(chosen.x != 9999, suite, "4+ level deep atrium discovered"):
		streamer.target = null
		streamer.build_around(Vector3(chosen.x * 24.0 + 12.0, 0, chosen.y * 24.0 + 12.0), 0)
		await get_tree().physics_frame
		var meta := streamer.meta_of(chosen)
		var ox := chosen.x * 24.0
		var oz := chosen.y * 24.0
		var space := lvl.get_world_3d().direct_space_state
		var roof_y := 12.75 if fifth else 9.50
		var stair_x := ox + 3.35 if fifth else ox + 21.35
		var hit_bridge := _dev14_surface(space, Vector3(ox + 12.0, roof_y, oz + 12.45))
		var hit_landing := _dev14_surface(space, Vector3(stair_x, roof_y, oz + 15.8))
		var open_slot := not _dev14_surface(space, Vector3(stair_x, roof_y, oz + 11.0))
		check(meta.get("storeys", 0) == (5 if fifth else 4), suite, "deep atrium storey count", meta)
		check(hit_bridge and hit_landing and open_slot, suite, "high atrium bridge / landing / stair void")
		evidence["L000"] = {"chunk": str(chosen), "storeys": meta.get("storeys", 0), "bridge": hit_bridge, "landing": hit_landing, "slot_clear": open_slot}
	_free_level(lvl)
	await get_tree().process_frame

	# L001: the third deck is above the original 4.2 m gallery, but below the
	# 9.2 m ceiling. The stair hole MUST be physically empty at y=6.5 m.
	lvl = await _instance("L001", 1001)
	if not check(lvl != null, suite, "L001 loads"):
		return
	await get_tree().physics_frame
	var s1 := lvl.get_world_3d().direct_space_state
	var l1_top := _dev14_surface(s1, Vector3(50.0, 6.50, 27.0))
	var l1_slot := not _dev14_surface(s1, Vector3(56.35, 6.50, 21.0))
	var l1_lower := _dev14_surface(s1, Vector3(56.35, 4.20, 21.0))
	check(l1_top and l1_slot and l1_lower, suite, "L001 third deck and open ascent slot")
	evidence["L001"] = {"upper_floor": l1_top, "upper_slot_clear": l1_slot, "lower_floor": l1_lower}
	_free_level(lvl)
	await get_tree().process_frame

	# L009: find the NON-exit outskirt chunk, so the story route remains separate.
	lvl = await _instance("L009", 1001)
	if not check(lvl != null, suite, "L009 loads"):
		return
	var outsk: Dictionary = lvl.get("outsk")
	var owner: Vector2i = lvl.get("end_owner")
	var garage := Vector2i(9999, 9999)
	for key in outsk.keys():
		if key != owner:
			garage = key
	if check(garage.x != 9999, suite, "non-exit parking-garage chunk exists"):
		streamer = lvl.get("world") as ChunkWorld
		streamer.target = null
		streamer.build_around(Vector3(garage.x * 64.0 + 40.0, 0, garage.y * 64.0 + 40.0), 0)
		await get_tree().physics_frame
		var sg := lvl.get_world_3d().direct_space_state
		var gx := garage.x * 64.0
		var gz := garage.y * 64.0
		var roof := _dev14_surface(sg, Vector3(gx + 28.0, 10.20, gz + 44.7))
		var slot := not _dev14_surface(sg, Vector3(gx + 51.0, 10.20, gz + 40.0))
		var third := _dev14_surface(sg, Vector3(gx + 51.0, 6.80, gz + 40.0))
		check(roof and slot and third, suite, "L009 fourth deck, stair gap, third deck")
		evidence["L009"] = {"roof_spur": roof, "roof_slot_clear": slot, "third_floor": third, "owner_untouched": garage != owner}
	_free_level(lvl)
	await get_tree().process_frame

	# L011: route belongs to the canonical authored park at (2,0).
	lvl = await _instance("L011", 1001)
	if not check(lvl != null, suite, "L011 loads"):
		return
	streamer = lvl.get("world") as ChunkWorld
	streamer.target = null
	streamer.build_around(Vector3(2.0 * 80.0 + 50.0, 0.0, 60.0), 0)
	await get_tree().physics_frame
	var s11 := lvl.get_world_3d().direct_space_state
	var x11 := 210.0
	var y11 := 0.15 + 3.6 + 3.5 + 3.4
	var z11 := 52.0
	var cross := _dev14_surface(s11, Vector3(x11, y11, z11 - 21.1))
	var stair_gap := not _dev14_surface(s11, Vector3(x11 + 9.0, y11, z11 - 4.0))
	var upper_deck := _dev14_surface(s11, Vector3(x11 + 9.0, 0.15 + 3.6 + 3.5, z11 - 4.0))
	check(cross and stair_gap and upper_deck, suite, "L011 4th airbridge and two separate stair holes")
	evidence["L011"] = {"cross_bridge": cross, "stair_void_clear": stair_gap, "third_floor": upper_deck}
	_free_level(lvl)
	await get_tree().process_frame
	results["vertical_dev14_evidence"] = {"claim": "engine ray-cast smoke only; physical walk and Windows runtime NOT VERIFIED", "levels": evidence}


# ========================================================== DEV15 new 3D architecture

## Live engine ray assertions. This is deliberately NOT a bot walkthrough.
## Actual player slopes, collision margins, handrails and Windows render remain
## unproven until the human-scale traverser and Windows build are exercised.
func _vertical_dev15_suite() -> void:
	var suite := "vertical_dev15"
	var evidence := {}
	var config := {
		"L015": [Vector3(19, 0, 97), 4, 3.5],
		"L016": [Vector3(26, 0, -22), 4, 3.4],
		"L017": [Vector3(0, 0, -1), 4, 3.45],
		"L020": [Vector3(0, 0, 59.5), 4, 3.45],
		"L024": [Vector3(-37, 0, -15), 5, 3.4],
		"L029": [Vector3(46, 0, -40), 4, 3.45],
		"L036": [Vector3(0, 0, -35), 4, 3.45]
	}
	for sid in config.keys():
		var lvl: LevelBase = await _instance(sid, 1001)
		if not check(lvl != null, suite, "level with tower loaded: " + sid):
			evidence[sid] = {"all_ok": false, "checks": 0}
			continue
		await get_tree().physics_frame
		await get_tree().physics_frame
		var space := lvl.get_world_3d().direct_space_state
		var info: Array = config[sid]
		var c: Vector3 = info[0]
		var n: int = int(info[1])
		var rise: float = float(info[2])
		var good := true
		var counted := 0
		for f in n:
			var y := c.y + float(f) * rise
			for offset in [Vector3(0, 0, 0), Vector3(0, 0, -12),
					Vector3(0, 0, 12), Vector3(-6.75, 0, 0), Vector3(6.75, 0, 0)]:
				var p := Vector3(c.x + offset.x, y, c.z + offset.z)
				var ok := _dev14_surface(space, p)
				good = check(ok, suite, "%s floor %d support %s" % [sid, f, offset]) and good
				counted += 1
			if f > 0:
				for x in [-4.0, 4.0]:
					var slot := not _dev14_surface(space, Vector3(c.x + x, y, c.z))
					good = check(slot, suite, "%s deck %d aperture x=%.1f" % [sid, f, x]) and good
					counted += 1
			if f < n - 1:
				for x in [-4.0, 4.0]:
					var mid := Vector3(c.x + x, y + rise * 0.5, c.z)
					var mid_hit := _dev14_surface(space, mid)
					good = check(mid_hit, suite, "%s stair %d physics ramp x=%.1f" % [sid, f, x]) and good
					counted += 1
		evidence[sid] = {"all_ok": good, "checks": counted, "floors": n,
			"scope": "floor, hole and ramp ray collisions; not physical pathfinding"}
		_free_level(lvl)
		await get_tree().process_frame

	# Garage fourth floor top and stair aperture must coexist.
	var g: LevelBase = await _instance("L022", 1001)
	if check(g != null, suite, "L022 rebuilt carpark loads"):
		await get_tree().physics_frame
		await get_tree().physics_frame
		var space := g.get_world_3d().direct_space_state
		var deck := _dev14_surface(space, Vector3(-20,12,20))
		var top := _dev14_surface(space, Vector3(-30,12,45))
		var shaft_void := not _dev14_surface(space, Vector3(-30,12,25))
		var lower := _dev14_surface(space, Vector3(-30,8,25))
		var ok := deck and top and shaft_void and lower
		check(ok, suite, "L022 supported 4th deck / landing / genuinely open ascent slot")
		evidence["L022"] = {"all_ok": ok, "checks": 4, "fourth_deck": deck,
			"landing": top, "shaft_open": shaft_void, "lower_deck": lower}
		_free_level(g)
		await get_tree().process_frame
	else:
		evidence["L022"] = {"all_ok": false, "checks": 0}

	# Two separated climbs + upper transverse walkway connect floating rows.
	var isl: LevelBase = await _instance("L030", 1001)
	if check(isl != null, suite, "L030 island network loads"):
		await get_tree().physics_frame
		await get_tree().physics_frame
		var space := isl.get_world_3d().direct_space_state
		var places := [Vector3(-33,18,8.5), Vector3(0,18,8.5),
			Vector3(66,18,8.5), Vector3(-16.5,18,8.5), Vector3(49.5,18,8.5),
			Vector3(0,12,42), Vector3(66,12,42)]
		var good := true
		for place in places:
			var hit := _dev14_surface(space, place)
			good = check(hit, suite, "L030 connected high/low shelf %s" % place) and good
		for x in [-33.0,66.0]:
			var midpoint := Vector3(x, 12.0 + 10.0 * 6.0 / 18.5, -3.0)
			var hit := _dev14_surface(space, midpoint)
			good = check(hit, suite, "L030 real incline %s" % midpoint) and good
		evidence["L030"] = {"all_ok": good, "checks": 9}
		_free_level(isl)
		await get_tree().process_frame
	else:
		evidence["L030"] = {"all_ok": false, "checks": 0}
	results["vertical_dev15_evidence"] = {"levels": evidence,
		"claim": "Engine ray smoke ONLY; no character walk, nav clearance or Windows verification"}


# ============================================================ duplication

## Material (triangles per material) and geometry (box-size bins) profiles.
func _profile(lvl: Node) -> Dictionary:
	var mats := {}
	for mi in lvl.find_children("Mesh_*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var key := str(m.name).trim_prefix("Mesh_")
		var tris := 0
		for si in m.mesh.get_surface_count():
			var arr := m.mesh.surface_get_arrays(si)
			tris += (arr[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3 if arr[Mesh.ARRAY_INDEX] != null else 0
		mats[key] = int(mats.get(key, 0)) + tris
	var boxes := {}
	for cs in lvl.find_children("*", "CollisionShape3D", true, false):
		var c := cs as CollisionShape3D
		if c.shape is BoxShape3D:
			var sz := (c.shape as BoxShape3D).size
			var dims := [sz.x, sz.y, sz.z]
			dims.sort()
			var bin := "%d_%d_%d" % [int(round(log(maxf(dims[0], 0.01)) * 2.0)), int(round(log(maxf(dims[1], 0.01)) * 2.0)), int(round(log(maxf(dims[2], 0.01)) * 2.0))]
			boxes[bin] = int(boxes.get(bin, 0)) + 1
	return {"materials": mats, "boxes": boxes}


func _cos(a: Dictionary, b: Dictionary) -> float:
	var dot := 0.0
	var na := 0.0
	var nb := 0.0
	for k in a.keys():
		na += float(a[k]) * float(a[k])
		if b.has(k):
			dot += float(a[k]) * float(b[k])
	for k in b.keys():
		nb += float(b[k]) * float(b[k])
	if na <= 0.0 or nb <= 0.0:
		return 0.0
	return dot / sqrt(na * nb)


func _dupe_suite() -> void:
	var s := "duplication"
	var prof := {}
	for r in results["levels"]:
		if r.has("dup_profile"):
			prof[r["stable_id"]] = r["dup_profile"]
	var ids := prof.keys()
	var pairs: Array = []
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var a: Dictionary = prof[ids[i]]
			var b: Dictionary = prof[ids[j]]
			var ms := _cos(a["materials"], b["materials"])
			var gs := _cos(a["boxes"], b["boxes"])
			pairs.append({"a": ids[i], "b": ids[j], "material_similarity": snappedf(ms, 0.001), "geometry_similarity": snappedf(gs, 0.001)})
			check(not (ms > 0.8 and gs > 0.9), s, "%s vs %s not a palette/layout clone" % [ids[i], ids[j]], [ms, gs])
	results["duplication_pairs"] = pairs
	if ids.size() < 2:
		check(true, s, "fewer than two levels profiled (nothing to compare)")



# ========================================================= focused L009 QA

## Run without the preceding 4-hop story chain. Uses the real L005 arrival
## and the player's real CharacterBody3D; only the 10-sign travel distance is
## compressed to three marked street waypoints. No teleporting between signs,
## no trigger.fire(), and no manual modification of qa_prog.
func _l009_route_suite() -> void:
	var suite := "l009_route"
	SessionState.set_mode(SessionState.Mode.QA)
	SessionState.qa_fixtures = true
	SessionState.qa_seed_override = 777
	TransitionService.qa_intercept = true
	TransitionService.qa_seamless = false
	if get_tree().current_scene == self:
		get_tree().current_scene = null
	TransitionService.load_level("L009", "from_L005", "qa-focused-route")
	# A broken scene must produce a failure report, not suspend the test forever.
	var load_started := Time.get_ticks_msec()
	while TransitionService.loading and Time.get_ticks_msec() - load_started < 30000:
		await get_tree().process_frame
	if not check(not TransitionService.loading, suite, "L009 load completed within 30 seconds"):
		SessionState.qa_fixtures = false
		SessionState.qa_seed_override = -1
		return
	var lvl := get_tree().current_scene as LevelBase
	if not check(lvl != null and lvl.stable_id == "L009", suite, "L009 loaded at its real from_L005 arrival"):
		return
	check(lvl.spawn_report.get("spawn_ok", false), suite, "L005 arrival stands on a valid floor", lvl.spawn_report)
	check(lvl.spawn_report.get("used_arrival", "") == "from_L005", suite, "real L005 arrival label preserved", lvl.spawn_report)
	var report := {"arrival": str(lvl.player.global_position), "spawn": lvl.spawn_report,
		"waypoints": [], "source_edge": "L009>L011#1", "scene_seed": lvl.level_seed,
		"physical_contact_required": true}
	var desc := lvl.qa_describe()
	var route: Dictionary = {}
	for candidate in desc["routes"]:
		if candidate.get("edge", "") == "L009>L011#1":
			route = candidate
	check(not route.is_empty(), suite, "QA signs for sourced Level 11 exit are present")
	var failed := route.is_empty()
	if not failed:
		for waypoint in route.get("waypoints", []):
			var before: int = int(lvl.get("qa_prog"))
			var wx := [{"edge": "waypoint", "kind": "waypoint", "pos": waypoint, "size": Vector3(2.0, 3.0, 2.0)}]
			var nav := await _nav_check(lvl, wx)
			var result := await _bot_walk(lvl, nav, wx, "waypoint", false)
			var after: int = int(lvl.get("qa_prog"))
			var evidence := {"target": str(waypoint), "before": before, "after": after,
				"spawn_projection_error": nav.get("spawn_projection_error", -1),
				"walk": result, "trace": lvl.get("qa_trace").duplicate()}
			report["waypoints"].append(evidence)
			if not check(result.get("fired", false) and after == before + 1,
					suite, "physically reached waypoint and advanced L009 progression", evidence):
				failed = true
				break
	if not failed:
		var exits: Array = desc["exits"]
		var nav := await _nav_check(lvl, exits)
		var end_result := await _bot_walk(lvl, nav, exits, "L009>L011#1", false)
		report["exit"] = end_result
		report["exit_events"] = TransitionService.qa_log.duplicate()
		check(end_result.get("fired", false) and end_result.get("edge", "") == "L009>L011#1",
			suite, "physical condition trigger fires the canonical L009>L011 edge", report)
	results["l009_route_evidence"] = report
	var cur := get_tree().current_scene
	if cur is LevelBase:
		_free_level(cur)
	SessionState.qa_fixtures = false
	SessionState.qa_seed_override = -1
	await get_tree().process_frame


# =================================================================== story

## Real STORY-mode playthrough through TransitionService: the walker bot uses
## each level's sourced exit toward the next built level; arrivals, journal and
## saves are verified on every hop. Stops at the first unbuilt destination.
func _story_suite() -> void:
	var s := "story"
	SessionState.set_mode(SessionState.Mode.STORY)
	SessionState.qa_fixtures = true
	SessionState.qa_seed_override = -1
	TransitionService.qa_intercept = false
	TransitionService.qa_seamless = true
	SaveService.story = SaveService.fresh_story(777)
	SaveService.save_story("qa-story-start")
	var cb := func(e: Dictionary): _story_fired = str(e.get("id", ""))
	TransitionService.transition_requested.connect(cb)
	var chain: Array = []
	# the runner itself is the main scene: never let load_level free it
	if get_tree().current_scene == self:
		get_tree().current_scene = null
	TransitionService.load_level("L000", "start", "qa-story")
	var initial_load_ms := Time.get_ticks_msec()
	while TransitionService.loading and Time.get_ticks_msec() - initial_load_ms < 30000:
		await get_tree().process_frame
	if not check(not TransitionService.loading, s, "story start loaded within 30 seconds"):
		SessionState.qa_fixtures = false
		return
	var visited := {"L000": true}
	for hop in int(args.get("story_hops", "14")):
		var hop_load_ms := Time.get_ticks_msec()
		while TransitionService.loading and Time.get_ticks_msec() - hop_load_ms < 30000:
			await get_tree().process_frame
		if not check(not TransitionService.loading, s, "story hop %d load completed" % hop):
			chain.append({"hop": hop, "stop": "load timeout"})
			break
		var lvl := get_tree().current_scene as LevelBase
		print("STORY hop %d at %s paused=%s" % [hop, lvl.stable_id if lvl else "none", get_tree().paused])
		if lvl == null:
			check(false, s, "a level is loaded at hop %d" % hop)
			break
		await get_tree().physics_frame
		var d := lvl.qa_describe()
		var choice := ""
		var to := ""
		for x in d["exits"]:
			for y in lvl.manifest.get("exits", []):
				if y["id"] == x["edge"] and not visited.has(y.get("to", "")):
					if choice == "" or LevelRegistry.is_playable(y.get("to", "")):
						choice = x["edge"]
						to = y.get("to", "")
		if choice == "":
			chain.append({"at": lvl.stable_id, "stop": "no unvisited exit placed near this arrival"})
			break
		# Require every actual waypoint to be physically visited in order.
		# Failure is explicit and diagnosed at the first obstruction, rather
		# than letting a conditional exit time out 150 seconds later.
		var waypoint_evidence: Array = []
		var waypoint_failure := false
		for r in d["routes"]:
			if r.get("edge", "") != choice:
				continue
			for wp in r.get("waypoints", []):
				var before_pos := lvl.player.global_position
				var before_progress: int = int(lvl.get("qa_prog")) if lvl.stable_id == "L009" else -1
				var wx := [{"edge": "waypoint", "kind": "waypoint", "pos": wp, "size": Vector3(2.0, 3.0, 2.0)}]
				var wnav := await _nav_check(lvl, wx)
				var reachable: bool = not wnav.get("exits", []).is_empty() and wnav["exits"][0].get("reachable", false)
				var wr := await _bot_walk(lvl, wnav, wx, "waypoint", true)
				var after_progress: int = int(lvl.get("qa_prog")) if lvl.stable_id == "L009" else -1
				waypoint_evidence.append({"target": str(wp), "start": str(before_pos),
					"end": str(lvl.player.global_position), "nav_reachable": reachable,
					"result": wr, "qa_prog_before": before_progress, "qa_prog_after": after_progress,
					"qa_trace": lvl.get("qa_trace").duplicate() if lvl.stable_id == "L009" else [],
					"current_arrival": TransitionService.pending_arrival})
				if not check(wr.get("fired", false) and (lvl.stable_id != "L009" or after_progress > before_progress),
				s, "physically reached waypoint %s and counted progress for %s" % [wp, choice], waypoint_evidence.back()):
					waypoint_failure = true
					break
			if waypoint_failure:
				break
		if waypoint_failure:
			chain.append({"from": lvl.stable_id, "edge": choice, "to": to,
					"stop": "unreachable route waypoint", "waypoints": waypoint_evidence})
			break
		if lvl.stable_id == "L009" and choice == "L009>L011#1":
			check(int(lvl.get("qa_prog")) >= 3, s, "Level 9 route progress unlocked after all waypoints", waypoint_evidence)
		var nav := await _nav_check(lvl, d["exits"])
		_story_fired = ""
		var bot := await _bot_walk(lvl, nav, d["exits"], choice, true)
		var hop_rec := {"from": d["stable_id"], "edge": choice, "to": to, "bot_fired": bot.get("fired", false), "sim_seconds": bot.get("sim_seconds", 0.0), "waypoints": waypoint_evidence, "walk": bot}
		check(bot.get("fired", false), s, "bot used %s in story mode" % choice, bot)
		if not bot.get("fired", false):
			chain.append(hop_rec)
			break
		if not LevelRegistry.is_playable(to):
			for i in 10:
				await get_tree().process_frame
			hop_rec["release_boundary_offered"] = Overlay.confirm_panel.is_visible_in_tree()
			hop_rec["stop"] = "destination not built/playable: " + to
			check(SaveService.has_witnessed(choice), s, "witnessed route journaled even when destination is unbuilt")
			Overlay.close_all()
			chain.append(hop_rec)
			break
		var t0 := Time.get_ticks_msec()
		while (TransitionService.loading or (get_tree().current_scene as LevelBase) == lvl) and Time.get_ticks_msec() - t0 < 60000:
			await get_tree().process_frame
		var nl := get_tree().current_scene as LevelBase
		var ok := nl != null and nl.stable_id == to
		check(ok, s, "story transition %s loaded %s" % [choice, to])
		if not ok:
			chain.append(hop_rec)
			break
		var arrival := str(nl.spawn_report.get("used_arrival", ""))
		hop_rec["arrival"] = arrival
		check(arrival == "from_" + d["stable_id"] or arrival == "checkpoint_position", s, "arrived at sourced arrival point from_%s in %s" % [d["stable_id"], to], arrival)
		check(nl.spawn_report.get("spawn_ok", false), s, "safe spawn after story transition into " + to)
		check(nl.spawn_report.get("carried_state", false), s, "seamless switch carried player state into " + to)
		for i in 5:
			await get_tree().process_frame
		var on_disk: Variant = JSON.parse_string(FileAccess.get_file_as_string(SaveService.story_path()))
		var disk_level: String = on_disk.get("current_level", "") if on_disk is Dictionary else ""
		check(disk_level == to, s, "story save on disk advanced to " + to, [disk_level, SaveService.story.get("current_level", ""), SaveService.last_error])
		check(SaveService.has_witnessed(choice), s, "journal records witnessed route " + choice)
		visited[to] = true
		chain.append(hop_rec)
	results["story_chain"] = chain
	TransitionService.transition_requested.disconnect(cb)
	var cur := get_tree().current_scene
	if cur is LevelBase:
		_free_level(cur)
	SessionState.qa_fixtures = false
	TransitionService.qa_seamless = false
	SessionState.set_mode(SessionState.Mode.QA)
	TransitionService.qa_intercept = true
	await get_tree().process_frame


# ==================================================== DEV16 tiered route physics checks
## Real Godot headless collision smoke. Not a substitute for a player path
## traversal, visual assessment, performance test or Windows binary QA.
func _vertical_dev16_suite() -> void:
	var suite := "vertical_dev16"
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/vertical_routes_dev16.json"))
	if not check(raw is Dictionary and raw.get("version") == "1.5.0-dev16", suite,
			"DEV16 route certificate loaded"):
		return
	var definitions: Array = raw["sites"]
	var evidence := {}
	var levels_seen := {}
	for record in definitions:
		levels_seen[record["level"]] = true
	for sid in levels_seen.keys():
		var lvl: LevelBase = await _instance(sid, 1001)
		if not check(lvl != null, suite, "Level scene loads with new geometry: " + sid):
			evidence[sid] = {"all_ok": false, "checks": 0}
			continue
		await get_tree().physics_frame
		await get_tree().physics_frame
		var space := lvl.get_world_3d().direct_space_state
		var ok := true
		var checks := 0
		for record in definitions:
			if record["level"] != sid:
				continue
			var o: Array = record["origin_xyz"]
			var origin := Vector3(float(o[0]), float(o[1]), float(o[2]))
			var n: int = int(record["tiers"])
			var rise: float = float(record["rise_m"])
			var downhill: bool = bool(record["descending"])
			var site: String = str(record["tag"])
			for f in range(n):
				var y: float = origin.y + float(f) * rise * (-1.0 if downhill else 1.0)
				var targets := [Vector3(0, 0, 0), Vector3(0, 0, -19.0),
					Vector3(0, 0, 19.0), Vector3(-5.2, 0, -12.0),
					Vector3(5.2, 0, -12.0), Vector3(-5.2, 0, 12.0),
					Vector3(5.2, 0, 12.0)]
				for offset in targets:
					var at := Vector3(origin.x + offset.x, y, origin.z + offset.z)
					var hit := _dev14_surface(space, at)
					ok = check(hit, suite, "%s %s tier %d supported %s" % [sid, site, f, offset]) and ok
					checks += 1
			for f in range(n - 1):
				var ya: float = origin.y + float(f) * rise * (-1.0 if downhill else 1.0)
				var yb: float = origin.y + float(f + 1) * rise * (-1.0 if downhill else 1.0)
				var mid_y: float = (ya + yb) * 0.5
				for xoff in [-11.8, 11.8]:
					var at := Vector3(origin.x + xoff, mid_y, origin.z)
					var hit := _dev14_surface(space, at)
					ok = check(hit, suite, "%s %s flight %d ray collision x=%.2f" % [sid, site, f, xoff]) and ok
					checks += 1
		for pair in raw["cross_site_bridges"]:
			if pair["level"] != sid:
				continue
			var sites := {}
			for rec in definitions:
				if rec["level"] == sid:
					sites[rec["tag"]] = rec
			var tags: Array = pair["site_tags"]
			var a: Dictionary = sites[tags[0]]
			var b: Dictionary = sites[tags[1]]
			for f in [1, int(a["tiers"]) - 1]:
				var y: float = float(a["origin_xyz"][1]) + float(f) * float(a["rise_m"])
				var z: float = float(a["origin_xyz"][2]) + (19.0 if f % 2 == 0 else -19.0)
				var mid_x: float = (float(a["origin_xyz"][0]) + float(b["origin_xyz"][0])) * 0.5
				var hit := _dev14_surface(space, Vector3(mid_x, y, z))
				ok = check(hit, suite, "%s two-site bridge f%d midspan is solid" % [sid, f]) and ok
				checks += 1
		if sid == "L023":
			var portal_ray := PhysicsRayQueryParameters3D.create(
				Vector3(29.8, -4.7, 0), Vector3(34.0, -4.7, 0), 1)
			var open := space.intersect_ray(portal_ray).is_empty()
			ok = check(open, suite, "L023 underground cave portal is cut through right wall") and ok
			checks += 1
		evidence[sid] = {"all_ok": ok, "checks": checks,
			"scope": "physical ray smoke, not a traversal or performance certificate"}
		_free_level(lvl)
		await get_tree().process_frame
	results["vertical_dev16_evidence"] = {"levels": evidence,
		"scope": "Godot collision samples only; full player traversal and Windows rendering NOT VERIFIED"}


# ==================================================== DEV17 true streamed physics audit
## This suite can run only with Godot 4.5.1. It NEVER writes a success marker
## merely because a design graph is connected; ray evidence comes from physics.
func _dev17_floor(space: PhysicsDirectSpaceState3D, p: Vector3,
		above: float = 1.25, below: float = 1.8) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * above,
		p - Vector3.UP * below, 1)
	return space.intersect_ray(q)

func _vertical_dev17_suite() -> void:
	var suite := "vertical_dev17"
	var cave: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/dev17_cave_braids.json"))
	var pool: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/dev17_pool_annexes.json"))
	if not check(cave is Dictionary and pool is Dictionary, suite,
			"DEV17 runtime geometry contracts present"):
		return
	var evidence := {"L008": {"checks": 0, "all_ok": false},
		"L037": {"checks": 0, "all_ok": false}}
	var cave_level: LevelBase = await _instance("L008", 1001)
	if check(cave_level != null, suite, "L008 SDF cave scene built"):
		var world: ChunkWorld = cave_level.get("world") as ChunkWorld
		var space := cave_level.get_world_3d().direct_space_state
		var valid := check(world != null, suite, "L008 streaming chunk builder present")
		if world != null:
			world.set_process(false) # test probes distant SDF chunks without player-driven unloading
		var checked := 0
		if world != null:
			for path in cave["braids"]:
				var pts: Array = path["floor_nodes"]
				# Build just the chunks owning each feature probe. Outer regions
				# are sampled separately rather than loading the entire cave.
				for idx in range(1, pts.size() - 1):
					var pt: Array = pts[idx]
					var p := Vector3(float(pt[0]), float(pt[1]), float(pt[2]))
					for k in world.chunks.keys():
						if (k - world.key_at(p)).length_squared() > 4:
							world._unload(k)
					world.build_around(p, 0)
					await get_tree().physics_frame
					var hit := _dev17_floor(space, p, 1.5, 2.25)
					var good := not hit.is_empty() and absf(float(hit["position"].y) - p.y) < 2.25
					valid = check(good, suite, "L008 carved floor %s node %d" % [path["id"], idx], hit) and valid
					checked += 1
			for path in cave["links"]:
				var pp: Array = path["floor_nodes"]
				for idx in range(1, pp.size() - 1):
					var pt: Array = pp[idx]
					var p := Vector3(float(pt[0]), float(pt[1]), float(pt[2]))
					for k in world.chunks.keys():
						if (k - world.key_at(p)).length_squared() > 4:
							world._unload(k)
					world.build_around(p, 0)
					await get_tree().physics_frame
					var hit := _dev17_floor(space, p, 1.5, 2.25)
					var good := not hit.is_empty() and absf(float(hit["position"].y) - p.y) < 2.25
					valid = check(good, suite, "L008 side-corridor floor %s node %d" % [path["id"], idx]) and valid
					checked += 1
		evidence["L008"] = {"checks": checked, "all_ok": valid,
			"scope": "SDF mesh raycasts at internal route points, not body traversal"}
		_free_level(cave_level)
		await get_tree().process_frame
	var pool_level: LevelBase = await _instance("L037", 1001)
	if check(pool_level != null, suite, "L037 connected Poolrooms scene built"):
		var world: ChunkWorld = pool_level.get("world") as ChunkWorld
		var space := pool_level.get_world_3d().direct_space_state
		var valid := check(world != null, suite, "L037 streaming hub builder present")
		var checked := 0
		if world != null:
			for name in ["annex_a", "annex_b"]:
				var site: Dictionary = pool["annexes"][name]
				var cx: int = int(site["chunk"][0])
				var cz: int = int(site["chunk"][1])
				var xoff := float(cx) * 32.0
				var zoff := float(cz) * 32.0
				var tiers: int = int(site["tiers"])
				var rise: float = float(site["rise_m"])
				world.build_around(Vector3(xoff + 16.0, 0, zoff + 16.0), 0)
				await get_tree().physics_frame
				var built := world.meta_of(Vector2i(cx, cz))
				valid = check(built.get("kind") == "hub_" + name,
					suite, "L037 authored annex streamed " + name, built) and valid
				checked += 1
				for f in range(1, tiers):
					var y := -0.18 + float(f) * rise
					var z := 18.5 if f % 2 == 1 else 4.5
					for x in [5.5, 17.5, 28.5]:
						var p := Vector3(xoff + x, y, zoff + z)
						var hit := _dev17_floor(space, p, 0.6, 0.65)
						var good := not hit.is_empty() and absf(float(hit["position"].y) - y) < 0.6
						valid = check(good, suite, "%s mezzanine tier %d x=%.1f" % [name, f, x], hit) and valid
						checked += 1
				for f in range(tiers - 1):
					var y := -0.18 + (float(f) + 0.5) * rise
					for x in [5.5, 28.5]:
						var p := Vector3(xoff + x, y, zoff + 11.5)
						var hit := _dev17_floor(space, p, 0.6, 0.7)
						var good := not hit.is_empty() and absf(float(hit["position"].y) - y) < 0.7
						valid = check(good, suite, "%s mid-stair %d x=%.1f" % [name, f, x]) and valid
						checked += 1
				var deep := Vector3(xoff + 21.0, float(site["basin_floor_m"]), zoff + 21.0)
				var deep_hit := _dev17_floor(space, deep, 0.6, 0.8)
				valid = check(not deep_hit.is_empty(), suite, name + " basin floor truly collides") and valid
				checked += 1
		evidence["L037"] = {"checks": checked, "all_ok": valid,
			"scope": "physical deck/stair/basin raycasts; no manual exploration"}
		_free_level(pool_level)
		await get_tree().process_frame
	results["vertical_dev17_evidence"] = {"levels": evidence,
		"scope": "Physical Godot probe samples only; NO full path or Windows verification"}


# DEV18 live engine checks for streamed, physical E-interaction hitboxes.
# This is not a player pathfinding, visual, GPU, or Windows performance test.
func _interactions_dev18_suite() -> void:
	var suite := "interactions_dev18"
	var source: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/dev18_ambient_discoveries.json"))
	var evidence := {"levels": {}, "scope": "native Godot Interactable hitboxes and callback state; no human traversal"}
	if not check(source is Dictionary and source.get("levels", {}).size() == 5,
			suite, "DEV18 proximity data loads"):
		results["interactions_dev18_evidence"] = evidence
		return
	for sid in ["L008", "L037"]:
		var level: LevelBase = await _instance(sid, 1001)
		if not check(level != null, suite, sid + " scene loads and builds"):
			evidence["levels"][sid] = {"expected": 3 if sid == "L008" else 4, "found": 0, "all_ok": false}
			continue
		var world: ChunkWorld = level.get("world") as ChunkWorld
		var found := 0
		var ok := check(world != null, suite, sid + " streamed world exists")
		if world != null:
			world.set_process(false)
			var sites := []
			if sid == "L008":
				sites = [["fissure", Vector3(56, 7, -20)], ["quarry", Vector3(74, -8, 28)],
					["overlook", Vector3(128, 2, -28)]]
			else:
				sites = [["quiet", Vector3(8.1, 1.25, 27.4)], ["pit", Vector3(42.5, 1.3, 13)],
					["lightwell", Vector3(80.2, 3.75, 18.5)], ["still", Vector3(112.2, 5.35, 4.5)]]
			for item in sites:
				var name: String = item[0]
				var p: Vector3 = item[1]
				var key := world.key_at(p)
				world.build_around(p, 0)
				await get_tree().physics_frame
				var owner: Node3D = world.chunks.get(key, {}).get("node") as Node3D
				var interaction: Interactable = null
				if owner != null:
					for child in owner.get_children():
						if child is Interactable and (
							(sid == "L008" and (child as Interactable).get_prompt().contains("Study the cave formation")) or
							(sid == "L037" and (child as Interactable).get_prompt() in [
								"Listen to the water", "Feel the air above the stair pit",
								"Watch light bend through the pool", "Touch the perfectly smooth tile"])):
							interaction = child as Interactable
							break
				var hitbox := interaction != null and interaction.collision_layer == 4 and (
						interaction.global_position - p).length() < 2.0
				ok = check(hitbox, suite, sid + " streamed physical E hitbox " + name) and ok
				if hitbox:
					interaction.interact(level.player)
					var flags: Dictionary = level.get("_surveyed") if sid == "L008" else level.get("_touch_events")
					var fired := flags.has(name)
					ok = check(fired, suite, sid + " interaction callback " + name) and ok
					if fired:
						found += 1
					# The collider MUST disappear along with its streamed geometry.
					world._unload(key)
					await get_tree().process_frame
					ok = check(not is_instance_valid(interaction), suite,
							sid + " interaction freed on chunk unload " + name) and ok
		var expected := 3 if sid == "L008" else 4
		ok = check(found == expected, suite, sid + " all sensory sites exercised", found) and ok
		evidence["levels"][sid] = {"expected": expected, "found": found, "all_ok": ok}
		_free_level(level)
		await get_tree().process_frame
	results["interactions_dev18_evidence"] = evidence


# =================================================== DEV19 fail-closed physical smoke
# This is scene/raycast/interaction evidence from native Godot. It does not
# certify actual player traversal, frame-rate, or full 100-level completeness.
func _dev19_owned_interaction(owner: Node3D, prompt_fragment: String) -> Interactable:
	if owner == null:
		return null
	for child in owner.get_children():
		if child is Interactable and (child as Interactable).get_prompt().contains(prompt_fragment):
			return child as Interactable
	return null


func _vertical_dev19_suite() -> void:
	var suite := "vertical_dev19"
	var evidence := {"levels": {}, "scope": "native chunk geometry rays, physical E collider callbacks and unloading; NOT full body path traversal"}
	var cave_spec: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/dev19_cave_ecologies.json"))
	if not check(cave_spec is Dictionary and cave_spec.get("routes", []).size() == 3,
			suite, "DEV19 cave design data exists and has three route records"):
		results["vertical_dev19_evidence"] = evidence
		return
	# L008 is SDF-based, so check a freshly created collision mesh at real
	# middle-route positions rather than assuming the authored floor exists.
	var level: LevelBase = await _instance("L008", 1001)
	var ok := check(level != null, suite, "L008 loaded in Godot")
	var count := 0
	var observed := 0
	if level != null:
		var world: ChunkWorld = level.get("world") as ChunkWorld
		var space := level.get_world_3d().direct_space_state
		ok = check(world != null, suite, "L008 has a streamed world") and ok
		if world != null:
			world.set_process(false)
			for route in cave_spec["routes"]:
				var pts: Array = route["floor_nodes"]
				for i in range(1, pts.size()-1):
					var a: Array = pts[i]
					var p := Vector3(float(a[0]),float(a[1]),float(a[2]))
					for k in world.chunks.keys():
						if (k - world.key_at(p)).length_squared() > 4:
							world._unload(k)
					world.build_around(p, 0)
					await get_tree().physics_frame
					var hit := _dev17_floor(space,p,1.6,2.2)
					var good := not hit.is_empty() and absf(float(hit["position"].y)-p.y) < 2.2
					ok = check(good,suite,"L008 route SDF collision: %s %d" % [route["id"], i]) and ok
					count += 1
				var at: Array = pts[int(route["observation_index"])]
				var pp := Vector3(float(at[0]),float(at[1]),float(at[2]))
				world.build_around(pp,0)
				await get_tree().physics_frame
				var ck := world.key_at(pp)
				var owner: Node3D = world.chunks.get(ck,{}).get("node") as Node3D
				var it := _dev19_owned_interaction(owner,"Observe the cave junction")
				var present := it != null and it.collision_layer == 4 and (it.global_position-pp).length()<2.0
				ok = check(present,suite,"L008 new cave observation physical collider %s" % route["id"]) and ok
				if present:
					it.interact(level.player)
					# Observations are persisted in the journal; an empty response is not a success.
					observed += 1
					world._unload(ck)
					await get_tree().process_frame
					ok = check(not is_instance_valid(it),suite,"L008 observation freed with chunk %s" % route["id"]) and ok
		evidence["levels"]["L008"] = {"checks":count,"observations":observed,"all_ok":ok}
		_free_level(level)
		await get_tree().process_frame
	else:
		evidence["levels"]["L008"] = {"checks":0,"observations":0,"all_ok":false}
	# L037 two new chunk families must exist and have actual above-water
	# bridge or submerged-ramp collision, plus four usable E interactions.
	level = await _instance("L037",1001)
	ok = check(level != null,suite,"L037 loaded in Godot")
	count = 0
	observed = 0
	if level != null:
		var world: ChunkWorld = level.get("world") as ChunkWorld
		var space := level.get_world_3d().direct_space_state
		ok = check(world != null,suite,"L037 streamed world exists") and ok
		if world != null:
			world.set_process(false)
			for slot in [
				{"x":4,"kind":"hub_colonnade","sites":[["Watch the changing reflections",Vector3(18,3.75,15)], ["Look into the flooded colonnade",Vector3(10,-1,14)]],"floors":[Vector3(18,2.8,15),Vector3(10,-2.35,9)]},
				{"x":5,"kind":"hub_twilight","sites":[["Listen over the dark water",Vector3(5,0.9,26)],["Trace the light below the surface",Vector3(16,-3.1,20)]],"floors":[Vector3(16,-4.5,20),Vector3(13,-5.8,19)]}
			]:
				var xo := float(slot["x"])*32.0
				var center := Vector3(xo+16,0,16)
				world.build_around(center,0)
				await get_tree().physics_frame
				var ck := Vector2i(int(slot["x"]),0)
				var cm: Dictionary = world.meta_of(ck)
				ok = check(cm.get("kind") == slot["kind"] and cm.has("dev19_signature"),suite,"L037 signature chunk instantiated: "+str(slot["kind"])) and ok
				var owner: Node3D = world.chunks.get(ck,{}).get("node") as Node3D
				for floor_local in slot["floors"]:
					var p: Vector3 = floor_local+Vector3(xo,0,0)
					var hit := _dev17_floor(space,p,0.9,1.25)
					var good := not hit.is_empty() and absf(float(hit["position"].y)-p.y)<1.20
					ok = check(good,suite,"L037 signature deck/ramp collision "+str(p)) and ok
					count += 1
				for site in slot["sites"]:
					var it := _dev19_owned_interaction(owner,str(site[0]))
					var at: Vector3 = site[1]+Vector3(xo,0,0)
					var present := it != null and it.collision_layer==4 and (it.global_position-at).length()<2.0
					ok = check(present,suite,"L037 pool sensory collider "+str(site[0])) and ok
					if present:
						it.interact(level.player)
						observed += 1
				var before := owner
				world._unload(ck)
				await get_tree().process_frame
				ok = check(not is_instance_valid(before),suite,"L037 signature streamed owner unload: "+str(slot["kind"])) and ok
		evidence["levels"]["L037"]={"checks":count,"observations":observed,"all_ok":ok}
		_free_level(level)
		await get_tree().process_frame
	else:
		evidence["levels"]["L037"]={"checks":0,"observations":0,"all_ok":false}
	# L001 circuit must really switch light ENERGY, not merely show a subtitle.
	level = await _instance("L001",1001)
	ok = check(level != null,suite,"L001 loaded in Godot")
	count = 0
	if level != null:
		var world: ChunkWorld = level.get("world") as ChunkWorld
		ok = check(world != null,suite,"L001 streaming chunk exists") and ok
		if world != null:
			world.set_process(false)
			world.build_around(Vector3(48,0,16),0)
			await get_tree().physics_frame
			var owner: Node3D = world.chunks.get(Vector2i(1,0),{}).get("node") as Node3D
			var lights: Array = []
			if owner != null:
				for c in owner.get_children():
					if c is OmniLight3D and c.name.begins_with("Circuit_"):
						lights.append(c)
			var control := _dev19_owned_interaction(owner,"Toggle gallery emergency lighting")
			ok = check(lights.size() == 4 and control != null,suite,"L001 four real circuit lights and lower E control") and ok
			if control != null and lights.size() == 4:
				var all_off := true
				for lamp in lights:
					all_off = all_off and (lamp as OmniLight3D).light_energy < 0.01
				ok=check(all_off,suite,"L001 circuit begins off") and ok
				control.interact(level.player)
				var all_on := true
				for lamp in lights:
					all_on = all_on and (lamp as OmniLight3D).light_energy > 1.3
				ok=check(all_on,suite,"L001 actual light power turns on") and ok
				control.interact(level.player)
				var off_again := true
				for lamp in lights:
					off_again = off_again and (lamp as OmniLight3D).light_energy < 0.01
				ok=check(off_again,suite,"L001 actual light power turns off") and ok
				count=4
		evidence["levels"]["L001"]={"checks":count,"observations":2,"all_ok":ok}
		_free_level(level)
		await get_tree().process_frame
	else:
		evidence["levels"]["L001"]={"checks":0,"observations":0,"all_ok":false}
	results["vertical_dev19_evidence"] = evidence


# ==================================================== DEV20 native annex QA
## This is a live-physics smoke check, not a walking bot or Windows FPS test.
## It always loads the actual level scene and checks colliding floors / stair
## midpoints, the entrance deck and real stateful gate/light components.
func _vertical_dev20_suite() -> void:
	var suite := "vertical_dev20"
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/dev20_atrium_blueprints.json"))
	var evidence := {"levels": {}, "scope": "Godot 4.5.1 native surfaces, stairs and state controls; NOT complete player traversal"}
	if not check(data is Dictionary and data.get("wings", []).size() == 10, suite,
			"Ten DEV20 data-driven building sites loaded"):
		results["vertical_dev20_evidence"] = evidence
		return
	for entry in data["wings"]:
		var sid: String = str(entry["id"])
		var tag: String = str(entry["anchor"])
		var level: LevelBase = await _instance(sid, 2020)
		var good := check(level != null, suite, sid + " actual Godot level instantiated")
		var count := 0
		var samples := 0
		if level == null:
			evidence["levels"][sid] = {"all_ok": false, "checks": 0, "samples": 0}
			continue
		var state: Node = level.get_node_or_null("DEV20_Wing_" + tag)
		good = check(state != null, suite, sid + " wing state node exists") and good
		if state != null:
			var lamps: Array = state.get("lamps")
			good = check(lamps.size() == 3 and (lamps[1] as Array).size() == 2,
				suite, sid + " two real light nodes per floor") and good
			state.call("toggle_circuit", null, 1)
			if lamps.size() == 3:
				var lit := true
				for light in lamps[1]:
					lit = lit and light is OmniLight3D and light.light_energy > 1.35
				good = check(lit, suite, sid + " real light energy changed by interaction") and good
			state.call("toggle_circuit", null, 1)
			if lamps.size() == 3:
				var dim := true
				for light in lamps[1]:
					dim = dim and light is OmniLight3D and light.light_energy < 0.2
				good = check(dim, suite, sid + " circuit switches back off") and good
			var shape: CollisionShape3D = state.get("shutter_shape") as CollisionShape3D
			var visual: MeshInstance3D = state.get("shutter_visual") as MeshInstance3D
			good = check(shape != null and visual != null and not shape.disabled and visual.visible,
				suite, sid + " closed shortcut has a real colliding body") and good
			if shape != null and visual != null:
				state.call("toggle_shutter", null)
				await get_tree().physics_frame
				good = check(shape.disabled and not visual.visible, suite, sid + " opened shortcut drops collision and mesh") and good
				state.call("toggle_shutter", null)
				await get_tree().physics_frame
				good = check(not shape.disabled and visual.visible, suite, sid + " shortcut closes again") and good
		var origin_data: Array = entry["origin"]
		var o := Vector3(float(origin_data[0]),float(origin_data[1]),float(origin_data[2]))
		var rise: float = float(entry["rise"])
		var x0: float = o.x + 32.5
		var z0: float = o.z - 14.0
		var space := level.get_world_3d().direct_space_state
		for tier in 3:
			var plan: Dictionary = entry["floors"][tier]
			var cells: Array = plan["cells"]
			for index in [0, cells.size() - 1]:
				var cell: Array = cells[index]
				var floor_y: float = o.y + float(tier + 1) * rise
				var p := Vector3(x0 + (float(cell[0]) + 0.5) * 7.0, floor_y,
					z0 + (float(cell[1]) + 0.5) * 7.0)
				var hit := _dev17_floor(space, p, 1.0, 1.2)
				var collision_ok := not hit.is_empty() and absf(float(hit["position"].y) - floor_y) < 0.45
				good = check(collision_ok, suite, sid + " tier %d physical room floor " % tier + str(cell)) and good
				samples += 1
		var entrance_y: float = o.y + 2.0 * rise
		var access := Vector3(o.x + 24.5, entrance_y, o.z - 1.1)
		var access_hit := _dev17_floor(space, access, 1.0, 1.2)
		good = check(not access_hit.is_empty() and absf(float(access_hit["position"].y) - entrance_y) < 0.45,
			suite, sid + " real connecting bridge floor") and good
		samples += 1
		for tier in 2:
			var y: float = o.y + float(tier + 1) * rise + rise * 0.5
			var stair_mid := Vector3(x0 + 37.5, y, z0 + 14.0)
			var hit := _dev17_floor(space, stair_mid, 1.0, 1.0)
			good = check(not hit.is_empty() and absf(float(hit["position"].y) - y) < 0.6,
				suite, sid + " real eastern stair ramp tier " + str(tier)) and good
			samples += 1
		count = samples + 5
		evidence["levels"][sid] = {"all_ok": good, "checks": count, "samples": samples}
		_free_level(level)
		await get_tree().process_frame
	results["vertical_dev20_evidence"] = evidence


# =================================================== DEV21 model / runtime state audit
# Godot-only! Validates actual imported GLBs, spawned collision areas, material
# marker feedback and floors under new terraces. No fake Windows certification.
func _scenario_dev21_suite() -> void:
	var suite := "scenario_dev21"
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/dev21_wing_scenarios.json"))
	var plans: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/dev20_atrium_blueprints.json"))
	var evidence := {"levels":{}, "scope":"Godot scene and physics smoke only, NOT actual player traversal"}
	if not check(raw is Dictionary and plans is Dictionary, suite, "Scenario records parse"):
		results["scenario_dev21_evidence"] = evidence
		return
	for entry in raw["wings"]:
		var sid: String = str(entry["id"])
		var tag: String = str(entry["anchor"])
		var blueprint: Dictionary = {}
		for b in plans["wings"]:
			if b["id"] == sid:
				blueprint = b
				break
		var level: LevelBase = await _instance(sid, 2121)
		var good := check(level != null, suite, sid + " level built")
		var count := 0
		if level == null:
			evidence["levels"][sid] = {"all_ok":false,"checks":0}
			continue
		var group := level.get_node_or_null("DEV21_DressedRooms_" + tag)
		var state := level.get_node_or_null("DEV20_Wing_" + tag)
		good = check(group != null and state != null, suite, sid + " dressed wing and state created") and good
		count += 1
		if group != null:
			var models := 0
			var inspectables := 0
			var markers := 0
			for child in group.get_children():
				if child.name.begins_with("GLB_"):
					models += 1
				if child is Interactable:
					inspectables += 1
					if str(child.prompt) in entry["station_prompts"]:
						markers += 1
			good = check(models == entry["models"].size(), suite, sid + " original GLB props instantiated", models) and good
			good = check(inspectables == 6 and markers == 3, suite, sid + " physical E colliders (3 inspect + 3 markers)", [inspectables,markers]) and good
			good = check(group.get_node_or_null("DEV21_Ambience_" + tag) != null, suite, sid + " positional ambience node") and good
			count += 3
		if state != null:
			var lights: Array = state.get("marker_lights")
			good = check(lights.size() == 3, suite, sid + " real survey light nodes") and good
			if lights.size() == 3:
				for tier in 3:
					var marker_area: Interactable = null
					if group != null:
						for child in group.get_children():
							if child is Interactable and child.prompt == str(entry["station_prompts"][tier]):
								marker_area = child as Interactable
								break
					good = check(marker_area != null, suite, sid + " tier %d has E action" % tier) and good
					if marker_area != null:
						# Invoke the real Interactable callback, not state.call:
						# previously the player's argument broke bound handlers.
						marker_area.interact(null)
					var lit: bool = lights[tier] is OmniLight3D and lights[tier].light_energy > 1.9
					good = check(lit, suite, sid + " tier %d E action illuminates" % tier) and good
					count += 2
				good = check(state.get("marker_found") == [true,true,true], suite, sid + " route discoveries registered") and good
				count += 1
			count += 1
		var origin: Array = blueprint.get("origin", [])
		if origin.size() == 3:
			var o := Vector3(float(origin[0]),float(origin[1]),float(origin[2]))
			var rise: float = float(blueprint["rise"])
			var xc: float = o.x + 32.5 + 17.5
			var z0: float = o.z - 14.0
			var space := level.get_world_3d().direct_space_state
			await get_tree().physics_frame
			for tier in [0,2]:
				var y: float = o.y + float(tier+1) * rise
				var probe := Vector3(xc, y, z0 - 3.0)
				var hit := _dev17_floor(space, probe, 0.75, 1.2)
				good = check(not hit.is_empty() and absf(float(hit["position"].y) - y)<0.5,
					suite,sid + " terrace tier%d is physically supported" % tier) and good
				count += 1
		evidence["levels"][sid] = {"all_ok":good, "checks":count,
			"model_instances":entry["models"].size()}
		_free_level(level)
		await get_tree().process_frame
	results["scenario_dev21_evidence"] = evidence

# ================================================== DEV22 district physical QA
# Only real Godot may pass this suite. Distinguish static graph reachability
# from native raycast samples and E callback/collision state. This does NOT
# certify full player traversal, long-session stability, GPU FPS or Windows.
func _district_dev22_suite() -> void:
	var suite := "district_dev22"
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/dev22_narrative_districts.json"))
	var evidence := {"levels":{}, "scope":"Godot collision-ray, GLB instantiation, actual E callback and optional hatch physics only; no whole-player traversals"}
	if not check(raw is Dictionary and raw.get("districts", []).size() == 10,
			suite,"All ten DEV22 site records loaded"):
		results["district_dev22_evidence"] = evidence
		return
	for rec in raw["districts"]:
		var sid: String = str(rec["id"])
		var tag: String = str(rec["anchor"])
		var level: LevelBase = await _instance(sid, 2222)
		var good := check(level != null, suite, sid+" constructed")
		var checks := 0
		var sample_count := 0
		if level == null:
			evidence["levels"][sid] = {"all_ok":false,"checks":0,"samples":0}
			continue
		var state: Node = level.get_node_or_null("DEV22_DistrictState_"+tag)
		var group: Node = level.get_node_or_null("DEV22_ExistingGLBDetails_"+tag)
		good = check(state != null and group != null, suite, sid+" new physical district nodes exist") and good
		checks += 1
		var loc: Array = rec["origin"]
		var x0 := float(loc[0])
		var ybase := float(loc[1])
		var z0 := float(loc[2])
		var rise := float(rec["rise"])
		var tiers := int(rec["tiers"])
		var space := level.get_world_3d().direct_space_state
		await get_tree().physics_frame
		# Actual floor colliders: test more than one unique real cell per tier.
		for tier in tiers:
			var floor: Dictionary = rec["floors"][tier]
			for idx in [0, floor["cells"].size()-1]:
				var cell: Array = floor["cells"][idx]
				var y := ybase+float(tier)*rise
				var pos := Vector3(x0+(float(cell[0])+0.5)*7.0,y,
					z0+(float(cell[1])+0.5)*7.0)
				var hit := _dev17_floor(space,pos,0.9,1.1)
				var point: Vector3 = hit.get("position",Vector3.ZERO)
				good = check(not hit.is_empty() and absf(point.y-y)<0.5,
					suite,sid+" tier%d floor %s ray" % [tier,str(cell)]) and good
				checks += 1
				sample_count += 1
		# The bridge must be real at its centre AND must match the tier-1 door
		# on the pre-existing DEV20 wing, not stop at an exterior guardrail.
		var bridge := Vector3(x0+17.5,ybase,z0+35.5)
		var bhit := _dev17_floor(space,bridge,0.9,1.1)
		var bridge_contact: Vector3 = bhit.get("position",Vector3.ZERO)
		good = check(not bhit.is_empty() and absf(bridge_contact.y-ybase)<0.5,
			suite,sid+" north-bridge collidable surface") and good
		checks += 1
		sample_count += 1
		var terrace := Vector3(x0+10.5,ybase,z0-8.0)
		var thit := _dev17_floor(space,terrace,0.9,1.1)
		var terrace_contact: Vector3 = thit.get("position",Vector3.ZERO)
		good = check(not thit.is_empty() and absf(terrace_contact.y-ybase)<0.5,
			suite,sid+" distinctive landmark terrace physical floor") and good
		checks += 1
		sample_count += 1
		# Both opposed flights have continuous, collidable sloping surfaces.
		for tier in tiers-1:
			var mid_y := ybase+(float(tier)+0.5)*rise
			for x in [x0-3.1,x0+31.1]:
				var stair := Vector3(x,mid_y,z0+14.0)
				var hit := _dev17_floor(space,stair,0.9,1.0)
				var stair_contact: Vector3 = hit.get("position",Vector3.ZERO)
				good = check(not hit.is_empty() and absf(stair_contact.y-mid_y)<0.6,
					suite,sid+" external stair ramp contact tier%d" % tier) and good
				checks += 1
				sample_count += 1
		if group != null:
			var model_count := 0
			for child in group.get_children():
				if child.name.begins_with("GLB_"):
					model_count += 1
			good = check(model_count == rec["models"].size()+rec["landmark_models"].size(),
				suite,sid+" imported GLB scene instances",model_count) and good
			checks += 1
		if state != null:
			var lamps: Array = state.get("signal_lights")
			var flashes: Array = state.get("ambient_lights")
			good = check(lamps.size() == tiers and flashes.size() == tiers,
				suite,sid+" independent per-storey visible lights") and good
			checks += 1
			var signals: Array = []
			var ambient_controls: Array = []
			var gate_area: Interactable = null
			for child in level.get_children():
				if not child is Interactable:
					continue
				var it := child as Interactable
				if it.prompt.begins_with("Record the ") and it.prompt.ends_with(" elevation signal"):
					if absf(it.position.x-(x0+3.5-1.78))<1.0:
						signals.append(it)
				elif it.prompt == "Adjust local environmental lighting":
					if absf(it.position.x-(x0+24.5+1.74))<1.0:
						ambient_controls.append(it)
				elif it.prompt == "Release the optional return hatch":
					gate_area = it
			signals.sort_custom(func(a,b): return a.position.y < b.position.y)
			ambient_controls.sort_custom(func(a,b): return a.position.y < b.position.y)
			good = check(signals.size()==tiers and ambient_controls.size()==tiers and gate_area!=null,
				suite,sid+" physical E trigger colliders per storey",[signals.size(),ambient_controls.size()]) and good
			checks += 1
			var shape: CollisionShape3D = state.get("gate_shape") as CollisionShape3D
			var visual: MeshInstance3D = state.get("gate_visual") as MeshInstance3D
			good = check(shape!=null and visual!=null and not shape.disabled and visual.visible,
				suite,sid+" optional hatch initially collides") and good
			checks += 1
			if gate_area != null:
				gate_area.interact(null)
				good = check(not state.get("gate_open"),suite,sid+" hatch remains locked without route observations") and good
				checks += 1
			for tier in mini(signals.size(),tiers):
				(signals[tier] as Interactable).interact(null)
				good = check(lamps[tier] is OmniLight3D and lamps[tier].light_energy>1.9,
					suite,sid+" E action illuminates route signal %d" % tier) and good
				checks += 1
			if ambient_controls.size()>0:
				(ambient_controls[0] as Interactable).interact(null)
				good = check(flashes[0] is OmniLight3D and flashes[0].light_energy>2.3,
					suite,sid+" true lighting control changes energy") and good
				checks += 1
			if gate_area != null and shape != null and visual != null:
				gate_area.interact(null)
				await get_tree().physics_frame
				good = check(shape.disabled and not visual.visible,
					suite,sid+" completed investigation physically opens optional hatch") and good
				checks += 1
		evidence["levels"][sid] = {"all_ok":good,"checks":checks,
			"samples":sample_count,"model_instances_expected":rec["models"].size()+2}
		_free_level(level)
		await get_tree().process_frame
	results["district_dev22_evidence"] = evidence

# =================================================== DEV23 landmark spur QA
# Engine-only floor-ray/independent stair/actual E action/GLB/crossbridge checks.
# A passed suite is NOT a substitute for 100-level human traversal or FPS QA.
func _dev23_point(raw: Array) -> Vector3:
	return Vector3(float(raw[0]),float(raw[1]),float(raw[2]))

func _landmark_dev23_suite() -> void:
	var suite := "landmark_dev23"
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/dev23_landmark_spurs.json"))
	var evidence := {"levels":{},"scope":"Actual Godot floor/stair rays, 16 GLB instances/site, E interactions and dynamic cross-gallery shape; NOT player-controlled traversal"}
	if not check(raw is Dictionary and raw.get("sites",[]).size()==10,
			suite,"DEV23 ten explicit theme sites present"):
		results["landmark_dev23_evidence"] = evidence
		return
	for rec in raw["sites"]:
		var sid: String = str(rec["id"])
		var level: LevelBase = await _instance(sid,2323)
		var good := check(level != null,suite,sid+" constructs")
		var checks := 0
		var samples := 0
		if level == null:
			evidence["levels"][sid]={"all_ok":false,"checks":0,"samples":0}
			continue
		var state: Node = level.get_node_or_null("DEV23_InteractiveRouteState_"+sid)
		var dressing: Node = level.get_node_or_null("DEV23_ExistingModels_"+sid)
		good = check(state != null and dressing != null,suite,sid+" landmark nodes exist") and good
		checks += 1
		var space := level.get_world_3d().direct_space_state
		await get_tree().physics_frame
		var positions: Dictionary = rec["node_positions"]
		for site in ["hub","west","east"]:
			var pos := _dev23_point(positions[site])
			var hit := _dev17_floor(space,pos,0.9,1.1)
			var collision: Vector3 = hit.get("position",Vector3.ZERO)
			good = check(not hit.is_empty() and absf(collision.y-pos.y)<0.5,
				suite,sid+" has real walkable "+site+" floor") and good
			checks += 1
			samples += 1
		if bool(rec["lower"]):
			var low := _dev23_point(positions["lower"])
			var lhit := _dev17_floor(space,low,.9,1.1)
			var lc: Vector3 = lhit.get("position",Vector3.ZERO)
			good = check(not lhit.is_empty() and absf(lc.y-low.y)<0.5,
				suite,sid+" collidable lower gallery") and good
			checks += 1
			samples += 1
		var loc: Array = rec["origin"]
		var mid_z: float = float(loc[2])-34.5
		var mid_y: float = float(loc[1])+float(rec["rise"])*.5
		for flank in [-1.0,1.0]:
			var at := Vector3(float(loc[0])+10.5+flank*4.5,mid_y,mid_z)
			var hit := _dev17_floor(space,at,.9,1.1)
			var contact: Vector3 = hit.get("position",Vector3.ZERO)
			good = check(not hit.is_empty() and absf(contact.y-mid_y)<0.6,
				suite,sid+" independent upper stair ramp") and good
			checks += 1
			samples += 1
		if bool(rec["lower"]):
			var low_mid := Vector3(float(loc[0])+10.5-15,
				float(loc[1])-float(rec["rise"])*.5,float(loc[2])-21)
			var hit := _dev17_floor(space,low_mid,.9,1.1)
			var point: Vector3 = hit.get("position",Vector3.ZERO)
			good = check(not hit.is_empty() and absf(point.y-low_mid.y)<0.6,
				suite,sid+" lower stair physical ramp") and good
			checks += 1
			samples += 1
		if dressing != null:
			var instances := 0
			for child in dressing.get_children():
				if child.name.begins_with("GLB_"):
					instances+=1
			good = check(instances==rec["props"].size(),suite,
				sid+" loaded all existing GLB model instances",instances) and good
			checks += 1
		if state != null:
			var lights: Array = state.get("lights")
			var shape: CollisionShape3D = state.get("bridge_collision") as CollisionShape3D
			var visual: MeshInstance3D = state.get("bridge_mesh") as MeshInstance3D
			good = check(lights.size()==3 and shape != null and visual != null,
				suite,sid+" physical lights and switchable cross-gallery") and good
			checks += 1
			good = check(shape!=null and visual!=null and shape.disabled and not visual.visible,
				suite,sid+" optional bridge physically absent initially") and good
			checks += 1
			var triggers: Array = []
			var switch_area: Interactable = null
			for child in level.get_children():
				if not child is Interactable:
					continue
				var area := child as Interactable
				if area.prompt.begins_with("Survey the "):
					triggers.append(area)
				elif area.prompt=="Operate the optional return crossing":
					switch_area=area
			good = check(triggers.size()==3 and switch_area!=null,
				suite,sid+" exactly three survey E triggers and one return control",triggers.size()) and good
			checks += 1
			if switch_area != null:
				switch_area.interact(null)
				good = check(not state.get("bridge_live"),suite,
					sid+" crossing stays unavailable before survey") and good
				checks += 1
			for trigger in triggers:
				(trigger as Interactable).interact(null)
			await get_tree().physics_frame
			good = check(not state.get("marked").has(false) and state.get("bridge_live") and
				shape!=null and not shape.disabled and visual!=null and visual.visible,
				suite,sid+" E actions energize real bridge and its collision") and good
			checks += 1
			var cross := Vector3(float(loc[0])+10.5,mid_y+float(rec["rise"])*.5,
				float(loc[2])-45)
			var bhit := _dev17_floor(space,cross,.9,1.1)
			var bridge_hit_point: Vector3 = bhit.get("position",Vector3.ZERO)
			good = check(not bhit.is_empty() and absf(bridge_hit_point.y-cross.y)<.55,
				suite,sid+" powered bridge has central walkable collider") and good
			checks += 1
			samples += 1
		evidence["levels"][sid] = {"all_ok":good,"checks":checks,
			"samples":samples,"expected_models":rec["props"].size()}
		_free_level(level)
		await get_tree().process_frame
	results["landmark_dev23_evidence"] = evidence

# ================================================ DEV24 expedition Godot QA
# This is a real runtime physics + Interactable E callback test. It tests 100
# physical decks, 10 stairs and 10 optional dynamic crossings, but NOT a human
# traversal playthrough nor GPU framerate on Windows.
func _expedition_dev24_suite() -> void:
	var suite := "expedition_dev24"
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://data/dev24_expeditions.json"))
	var evidence := {"levels":{},"scope":"Native headless Godot: floor/stair collision, physical entrance, imported GLBs, E control of 3 lights and optional safe bridge. Human FPS and traversal pending."}
	if not check(raw is Dictionary and raw.get("sites",[]).size()==10,
			suite,"DEV24 ten distinct biome manifests loaded"):
		results["expedition_dev24_evidence"] = evidence
		return
	for rec in raw["sites"]:
		var sid := str(rec["id"])
		var level: LevelBase = await _instance(sid,2424)
		var good := check(level!=null,suite,sid+" loads without runtime errors")
		var checks := 0
		var samples := 0
		if level==null:
			evidence["levels"][sid]={"all_ok":false,"checks":0,"samples":0}
			continue
		var state: Node = level.get_node_or_null("DEV24_ExpeditionState_"+sid)
		var dress: Node = level.get_node_or_null("DEV24_ExistingGLB_"+sid)
		good = check(state!=null and dress!=null,suite,sid+" state and local GLB decoration instanced") and good
		checks+=1
		var space := level.get_world_3d().direct_space_state
		await get_tree().physics_frame
		var node_positions: Dictionary = rec["nodes"]
		for key in node_positions:
			var pos := _dev23_point(node_positions[key])
			var hit := _dev17_floor(space,pos,1.1,1.4)
			var y: Vector3 = hit.get("position",Vector3.ZERO)
			good = check(not hit.is_empty() and absf(y.y-pos.y)<.48,
				suite,sid+" has genuine colliding platform "+str(key)) and good
			checks+=1
			samples+=1
		# A floor ray at the connection from DEV23's east gallery to b0.
		var gallery := _dev23_point(rec["entry_gallery"])
		var base := _dev23_point(node_positions["b0"])
		var corridor_pos := (gallery+base)*.5
		var corridor_hit := _dev17_floor(space,corridor_pos,1.1,1.4)
		var cp: Vector3 = corridor_hit.get("position",Vector3.ZERO)
		good = check(not corridor_hit.is_empty() and absf(cp.y-base.y)<.48,
			suite,sid+" physically connected from dev23 gallery") and good
		checks+=1
		samples+=1
		for link in rec["links"]:
			if str(link["kind"])!="stair":
				continue
			var low := _dev23_point(node_positions[str(link["a"])])
			var high := _dev23_point(node_positions[str(link["b"])])
			var ramp_at := (low+high)*.5-Vector3.RIGHT*1.0
			var ramp_hit := _dev17_floor(space,ramp_at,.9,1.3)
			var rp: Vector3 = ramp_hit.get("position",Vector3.ZERO)
			good = check(not ramp_hit.is_empty() and absf(rp.y-ramp_at.y)<.65,
				suite,sid+" physical 21m gradual ascent") and good
			checks+=1
			samples+=1
		if dress != null:
			var instances := 0
			for child in dress.get_children():
				if child.name.begins_with("GLB_"):
					instances+=1
			good = check(instances==rec["props"].size(),suite,
				sid+" existing models actually load and instantiate",instances) and good
			checks+=1
		if state != null:
			var floor_shape: CollisionShape3D = state.get("floor_shape") as CollisionShape3D
			var floor_mesh: MeshInstance3D = state.get("floor_mesh") as MeshInstance3D
			var rails: Array = state.get("barriers")
			var lights: Array = state.get("lamps")
			good = check(floor_shape!=null and floor_mesh!=null and lights.size()==3 and rails.size()==2,
				suite,sid+" real switchable physics, safety rails and three panel lights") and good
			checks+=1
			if floor_shape!=null and floor_mesh!=null:
				good = check(floor_shape.disabled and not floor_mesh.visible,
					suite,sid+" optional bridge begins physically OFF") and good
				checks+=1
			var markers: Array = []
			var manual: Interactable = null
			var lighting: Array = []
			for child in level.get_children():
				if not child is Interactable:
					continue
				var it: Interactable = child as Interactable
				if it.prompt=="Map the local expedition marker":markers.append(it)
				if it.prompt=="Operate the alternate physical crossing":manual=it
				if it.prompt=="Toggle local observation lights":lighting.append(it)
			good = check(markers.size()==3 and manual!=null and lighting.size()==2,
				suite,sid+" has 3 mapping E zones, bridge control and 2 light switches") and good
			checks+=1
			if manual!=null:
				manual.interact(null)
				good = check(not state.get("bridge_active"),suite,
					sid+" manual bridge remains locked before surveys") and good
				checks+=1
			for toggle in lighting:
				(toggle as Interactable).interact(null)
			var local: Array = state.get("ambient_lamps")
			good = check(local.size()==2 and local[0].light_energy>1.0 and local[1].light_energy>1.0,
				suite,sid+" E action changes actual local lights") and good
			checks+=1
			for marker in markers:
				(marker as Interactable).interact(null)
			await get_tree().physics_frame
			good = check(not state.get("surveyed").has(false) and state.get("bridge_active") and
				floor_shape!=null and not floor_shape.disabled and floor_mesh!=null and floor_mesh.visible,
				suite,sid+" three E actions unlock visible + colliding crossing") and good
			checks+=1
			var opt: Array = rec["optional_edge"]
			var a := _dev23_point(node_positions[str(opt[0])])
			var b := _dev23_point(node_positions[str(opt[1])])
			var cross := (a+b)*.5
			var cross_hit := _dev17_floor(space,cross,1.0,1.5)
			var hp: Vector3 = cross_hit.get("position",Vector3.ZERO)
			good = check(not cross_hit.is_empty() and absf(hp.y-cross.y)<.55,
				suite,sid+" unlocked return bridge supports physics ray") and good
			checks+=1
			samples+=1
		evidence["levels"][sid]={"all_ok":good,"checks":checks,"samples":samples,
			"loaded_glb_recipes":rec["props"].size()}
		_free_level(level)
		await get_tree().process_frame
	results["expedition_dev24_evidence"] = evidence
