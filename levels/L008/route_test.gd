extends SceneTree
## Level 8 route verification with the real Player controller (developer mode:
## real exits, no QA fixture; transitions intercepted).
##   godot --headless --path . --fixed-fps 60 -s res://levels/L008/route_test.gd -- --qa
## 1) from_L007 arrival surfaces from the flooded tunnel; 2) walk the whole
## 9th Road incl. the 12 m ladder shaft -> L008>L009#1; 3) tar pool ->
## L008>L041#3; 4) cracked floor -> L008>L069#8. Writes
## res://reports/qa/levels/L008_routes.json; exit code = failures.

var res := {"routes": [], "failures": 0}
var lvl: Node
var p: CharacterBody3D
var ts: Node


func _initialize() -> void:
	_run.call_deferred()


func _check(name: String, ok: bool, detail: Dictionary) -> void:
	detail["route"] = name
	detail["ok"] = ok
	res["routes"].append(detail)
	if not ok:
		res["failures"] += 1
	print(("PASS " if ok else "FAIL ") + name + " " + JSON.stringify(detail))


func _load(arrival: String = "start") -> void:
	if lvl:
		lvl.queue_free()
		await process_frame
	root.get_node("Overlay").close_all()
	paused = false
	root.get_node("SessionState").set_mode(1)
	ts = root.get_node("TransitionService")
	ts.qa_intercept = true
	ts.pending_arrival = arrival
	ts.qa_log.clear()
	lvl = (load("res://levels/L008/L008.tscn") as PackedScene).instantiate()
	root.add_child(lvl)
	current_scene = lvl
	while not lvl.built:
		await process_frame
	p = lvl.player
	p.qa_active = true
	lvl.dip_t = 9999.0


func _fired(edge: String) -> bool:
	for e in ts.qa_log:
		if e.get("id", "") == edge:
			return true
	return false


func _run() -> void:
	await process_frame
	var Lay = load("res://levels/L008/CaveBuild.gd")
	# 1: arriving from Level 7 underwater, buoyancy brings you up into the pool
	await _load("from_L007")
	var y0: float = p.global_position.y
	var under0: bool = p.head_under
	var t := 0
	while t < 60 * 20 and p.head_under or t < 30:
		t += 1
		await physics_frame
	_check("from_L007_surfaces", under0 and not p.head_under and p.global_position.y > y0, {"start_y": y0, "end_y": p.global_position.y, "sim_seconds": t / 60.0, "arrival": lvl.spawn_report.get("used_arrival", "")})
	# 2: the whole road, walked
	await _load()
	var pts: Array = []
	for n in Lay.ROAD:
		pts.append((n[0] as Vector3) + Vector3(0, 0.1, 0))
	var si: int = 7
	pts[si] = Lay.SHAFT + Vector3(0.6, 0.1, 0)
	pts[si + 1] = Lay.SHAFT + Vector3(4.0, 12.1, 0)
	t = 0
	var i := 0
	var dist := 0.0
	var last: Vector3 = p.global_position
	var stuck := 0
	var climbed := false
	while t < 60 * 400 and not _fired("L008>L009#1") and not p.dead:
		t += 1
		var goal: Vector3 = pts[mini(i, pts.size() - 1)]
		var d := goal - p.global_position
		if Vector2(d.x, d.z).length() < 1.2 and absf(d.y) < 2.5 and i < pts.size() - 1:
			i += 1
			continue
		if not p.on_ladder:
			p.rotation.y = atan2(-d.x, -d.z)
		else:
			climbed = true
		p.qa_input = Vector2(0, 1)
		await physics_frame
		if t % 60 == 0:
			dist += p.global_position.distance_to(last)
			if p.global_position.distance_to(last) < 0.1:
				stuck += 1
			last = p.global_position
	p.qa_input = Vector2.ZERO
	_check("road_to_L009", _fired("L008>L009#1"), {"sim_seconds": snappedf(t / 60.0, 0.1), "waypoints": i, "of": pts.size(), "climbed_shaft_ladder": climbed,
		"distance_m": snappedf(dist, 0.1), "stuck_seconds": stuck, "pos": str(p.global_position.snapped(Vector3.ONE * 0.1)), "dead": p.dead})
	# 3: the tar pool's hands
	await _load()
	lvl.world.build_around(Lay.TAR, 1)
	await physics_frame
	await physics_frame
	p.global_position = Lay.TAR + Vector3(2.5, 0.1, 2.5)
	t = 0
	while t < 60 * 15 and not _fired("L008>L041#3"):
		t += 1
		var d2: Vector3 = Lay.TAR - p.global_position
		p.rotation.y = atan2(-d2.x, -d2.z)
		p.qa_input = Vector2(0, 1)
		await physics_frame
	_check("tar_pool_L041", _fired("L008>L041#3"), {"sim_seconds": t / 60.0, "grab_s": snappedf(lvl.tar_grab, 0.1)})
	# 4: the cracked floor gives way
	await _load()
	lvl.world.build_around(Lay.PIT, 1)
	await physics_frame
	await physics_frame
	p.global_position = Lay.PIT + Vector3(0.3, 0.1, 0.3)
	for w in 30:
		await physics_frame
	var stood: bool = p.is_on_floor() and p.global_position.y > Lay.PIT.y - 0.3
	p.qa_input = Vector2.ZERO
	t = 0
	while t < 60 * 15 and not _fired("L008>L069#8"):
		t += 1
		await physics_frame
	_check("cracked_floor_L069", stood and _fired("L008>L069#8"), {"stood_on_slab_first": stood, "sim_seconds": t / 60.0, "y": snappedf(p.global_position.y, 0.1)})
	var f := FileAccess.open(ProjectSettings.globalize_path("res://reports/qa/levels/L008_routes.json"), FileAccess.WRITE)
	if f:
		res["engine"] = Engine.get_version_info()["string"]
		res["note"] = "Developer mode (real exits, no QA fixture), transitions intercepted, fixed 60 Hz physics, real Player controller; flood dip held dry for the road walk."
		f.store_string(JSON.stringify(res, "  "))
		f.close()
	print("ROUTES DONE: %d failures" % res["failures"])
	quit(res["failures"])
