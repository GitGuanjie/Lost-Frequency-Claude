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
	for pn in ["pause_menu", "dev_browser", "settings_panel", "journal_panel", "credits_panel", "note_panel", "death_panel", "confirm_panel"]:
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
	var before := SessionState.current_level
	await _tap(KEY_F4)
	await get_tree().process_frame
	check(SessionState.current_level == before and not TransitionService.loading, s, "F4 does nothing in story mode")
	await _tap(KEY_F7)
	check(lvl.player.flycam == null, s, "F7 flycam refused in story mode")
	SessionState.set_mode(SessionState.Mode.DEVELOPER)
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
	for x in found:
		var tp: Vector3 = x["pos"]
		var sz: Vector3 = x["size"]
		var goal := NavigationServer3D.map_get_closest_point(map, tp)
		var path := NavigationServer3D.map_get_path(map, start, goal, true)
		var reach := false
		if path.size() > 0:
			var endp: Vector3 = path[path.size() - 1]
			reach = absf(endp.x - tp.x) <= sz.x * 0.5 + 0.8 and absf(endp.z - tp.z) <= sz.z * 0.5 + 0.8 \
				and endp.y <= tp.y + sz.y * 0.5 + 0.5 and endp.y >= tp.y - sz.y * 0.5 - 1.5
		out["exits"].append({"edge": x["edge"], "reachable": reach, "path_points": path.size(), "goal": goal,
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
		_nav_free(nav)
		return {"fired": false, "reason": "no reachable exit"}
	var trig: Dictionary = {}
	for x in found:
		if x["edge"] == target["edge"]:
			trig = x
	var p := lvl.player
	p.qa_active = true
	var path: Array = target["path"]
	var i := 1
	var ticks := 0
	var max_ticks := 60 * 150
	var fired := false
	var stuck := 0
	var last := p.global_position
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
					(t as ExitTrigger).interact(p)
		await get_tree().physics_frame
		if trig.get("kind", "") == "waypoint" and Vector2(p.global_position.x - trig["pos"].x, p.global_position.z - trig["pos"].z).length() < 1.2:
			fired = true
			break
		if not TransitionService.qa_log.is_empty() or (detect_signal and _story_fired != ""):
			fired = true
			break
		if not is_instance_valid(p):
			break
		if ticks % 60 == 0:
			if p.global_position.distance_to(last) < 0.15:
				stuck += 1
			last = p.global_position
			if stuck > 6 and i < path.size():
				i += 1
				stuck = 0
	if is_instance_valid(p):
		p.qa_input = Vector2.ZERO
		p.qa_active = false
	var fired_edge := ""
	if fired and trig.get("kind", "") == "waypoint":
		fired_edge = "waypoint"
	elif fired:
		fired_edge = _story_fired if detect_signal else str(TransitionService.qa_log[0].get("id", ""))
	var res := {"fired": fired, "ticks": ticks, "sim_seconds": ticks / 60.0, "edge": fired_edge,
		"distance_walked": p.stats["distance"] if is_instance_valid(p) else -1.0, "target": target["edge"]}
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
	await TransitionService.level_loaded
	var visited := {"L000": true}
	for hop in int(args.get("story_hops", "14")):
		while TransitionService.loading:
			await get_tree().process_frame
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
		# levels may declare sourced route waypoints (e.g. Level 9's arrow signs)
		for r in d["routes"]:
			if r.get("edge", "") == choice:
				for wp in r.get("waypoints", []):
					var wx := [{"edge": "waypoint", "kind": "waypoint", "pos": wp, "size": Vector3(2.0, 3.0, 2.0)}]
					var wnav := await _nav_check(lvl, wx)
					var wr := await _bot_walk(lvl, wnav, wx, "waypoint", true)
					print("STORY waypoint %s reached=%s sim=%.1f" % [wp, wr.get("fired", false), wr.get("sim_seconds", 0.0)])
		var nav := await _nav_check(lvl, d["exits"])
		_story_fired = ""
		var bot := await _bot_walk(lvl, nav, d["exits"], choice, true)
		var hop_rec := {"from": d["stable_id"], "edge": choice, "to": to, "bot_fired": bot.get("fired", false), "sim_seconds": bot.get("sim_seconds", 0.0)}
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
