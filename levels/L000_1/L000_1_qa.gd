extends RefCounted
## Level 0.1 QA hooks: curated stills and engine self-tests for the sourced
## mechanics (decks and stairs, the cavity, the stacked Level 0 view, sliding
## doors, the lift, lethal climate, hallucinations, automatons, isolation).

const D := preload("res://levels/L000_1/L000_1_dims.gd")


static func capture_plan(lvl) -> Array:
	var plan: Array = lvl.qa_shots.duplicate()
	if OS.get_cmdline_user_args().has("--extra=2"):
		return [{"name": "dbg_back", "pos": Vector3(0, -150, 500), "target": Vector3(0, 0, 0)},
			{"name": "dbg_side", "pos": Vector3(60, 5, 40), "target": Vector3(0, 5, 0)}]
	if OS.get_cmdline_user_args().has("--extra=1"):
		var th: Vector3 = D.TH
		plan.append({"name": "x_atrium", "pos": Vector3(-4.5, 1.62, -6.5), "target": Vector3(2.0, 12.0, 6.0)})
		plan.append({"name": "x_deck3", "pos": Vector3(-24.0, D.deck_y(3) + 1.62, -6.0), "target": Vector3(4.0, D.deck_y(3) - 3.0, 9.0)})
		plan.append({"name": "x_bridge", "pos": th + Vector3(0.4, D.L0Y + 1.62, -24.0), "target": th + Vector3(0.0, 1.5, -6.0)})
		plan.append({"name": "x_concourse", "pos": th + Vector3(-1.0, 1.62, -4.0), "target": th + Vector3(0.0, 1.2, 10.0)})
		plan.append({"name": "x_gantry_up", "pos": Vector3(19.0, D.deck_y(2) + 1.62, D.edge(2) + 6.0), "target": Vector3(-40.0, 60.0, 60.0)})
		plan.append({"name": "x_gantry_out", "pos": Vector3(21.0, D.deck_y(2) + 1.62, D.edge(2) + 7.0), "target": Vector3(30.0, -120.0, 900.0)})
		var e2 := D.edge(2)
		plan.append({"name": "x_vac_a", "pos": Vector3(21.0, 10.62, e2 + 4.5), "target": Vector3(-60.0, 0.0, 40.0)})
		plan.append({"name": "x_vac_b", "pos": Vector3(21.0, 10.62, e2 + 6.0), "target": Vector3(-20.0, -30.0, 60.0)})
		plan.append({"name": "x_vac_c", "pos": Vector3(0.0, D.deck_y(3) + 1.62, -2.6), "target": Vector3(0.0, -20.0, 200.0)})
		plan.append({"name": "x_vac_d", "pos": Vector3(-27.0, D.deck_y(1) + 1.62, 2.6), "target": Vector3(40.0, -10.0, 60.0)})
		plan.append({"name": "x_h1", "pos": Vector3(21.5, 10.62, e2 + 6.9), "target": Vector3(-40.0, -20.0, 10.0)})
		plan.append({"name": "x_h2", "pos": Vector3(21.5, 10.62, e2 + 6.9), "target": Vector3(-60.0, 5.0, 60.0)})
		plan.append({"name": "x_h3", "pos": Vector3(19.0, 10.62, e2 + 6.9), "target": Vector3(60.0, -30.0, 40.0)})
		plan.append({"name": "x_thr_a", "pos": th + Vector3(6.5, 1.62, -5.6), "target": th + Vector3(-4.0, -6.0, -45.0)})
		plan.append({"name": "x_thr_b", "pos": th + Vector3(-1.0, 1.0, -7.4), "target": th + Vector3(0.0, 0.6, -60.0)})
		plan.append({"name": "x_thr_c", "pos": th + Vector3(0.8, 1.08, -40.0), "target": th + Vector3(-1.4, 6.0, -60.0)})
		plan.append({"name": "x_window_up", "pos": th + Vector3(7.5, 1.62, -5.6), "target": th + Vector3(4.0, 40.0, -60.0)})
		plan.append({"name": "x_window_down", "pos": th + Vector3(-7.5, 1.62, -5.6), "target": th + Vector3(-2.0, -40.0, -60.0)})
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--only="):
				var keep: Array = a.substr(7).split(",")
				plan = plan.filter(func(sh): return keep.has(sh["name"]))
		for m in []:
			if m.has("aabb") and m["state"] in ["cold", "hot", "normal"]:
				var b: AABB = m["aabb"]
				var c := b.get_center()
				plan.append({"name": "x_mod_%s_%s" % [m["type"], m["state"]], "pos": Vector3(c.x - 1.5, b.position.y + 1.82, D.ZW + 0.8), "target": Vector3(c.x + 1.0, b.position.y + 0.9, D.ZB)})
	return plan


static func _ray_y(lvl, x: float, y0: float, z: float) -> float:
	var hit: Dictionary = lvl.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x, y0, z), Vector3(x, y0 - 6.0, z), 1))
	return float(hit["position"].y) if not hit.is_empty() else -9999.0


static func _put(lvl, p: Vector3, yaw: float = 0.0) -> void:
	lvl.player.global_position = p
	lvl.player.velocity = Vector3.ZERO
	lvl.player.rotation.y = yaw
	await lvl.get_tree().physics_frame
	await lvl.get_tree().physics_frame


static func _wait(lvl, frames: int) -> void:
	for i in frames:
		await lvl.get_tree().physics_frame


static func self_test(lvl) -> Array:
	var out: Array = []
	var sys = lvl.sys
	var g = lvl.gallery
	await lvl.get_tree().process_frame
	# --- structure: four walkable decks, three flights joining them
	var ys: Array = []
	var ok := true
	for k in D.DECKS:
		var y := _ray_y(lvl, -20.0, D.deck_y(k) + 2.0, -4.0)
		ys.append(y)
		ok = ok and absf(y - D.deck_y(k)) < 0.05
	out.append({"what": "Inner Gallery has four walkable decks (y 0 / 4.5 / 9 / 13.5)", "ok": ok, "detail": ys})
	ok = true
	var mids: Array = []
	for f in D.DECKS - 1:
		var y := _ray_y(lvl, g.stair_x(f), D.deck_y(f) + 4.0, (D.ST_LO + D.ST_HI) * 0.5)
		mids.append(y)
		ok = ok and y > D.deck_y(f) + 1.6 and y < D.deck_y(f) + 2.9
	out.append({"what": "stair flights climb between every pair of decks", "ok": ok, "detail": mids})
	var gy := _ray_y(lvl, 20.0, D.deck_y(2) + 2.0, D.edge(2) + 6.0)
	out.append({"what": "the gantry stands out over the cavity, past the glass line", "ok": absf(gy - D.deck_y(2)) < 0.05, "detail": gy})
	# --- scale: the cavity sphere, the facade, the stacked Level 0 floors
	var cav: Node = lvl.find_child("Cavity", true, false)
	out.append({"what": "cavity sphere (r %.0f m) and near facade (%d segments)" % [D.R, lvl.facade_segments], "ok": cav != null and lvl.facade_segments > 800})
	var dz := D.z_edge(0.0, D.deck_y(3)) - D.z_edge(0.0, 0.0)
	out.append({"what": "decks step out over the cavity like a sphere's upper half", "ok": dz > 5.0 and dz < 8.0, "detail": dz})
	out.append({"what": "Level 0 seen from the hull: identical floors stacked vertically", "ok": lvl.stack_floors >= 100, "detail": lvl.stack_floors})
	# --- sliding doors
	var auto_d: Dictionary = {}
	var jam: Dictionary = {}
	for d in sys.doors:
		if d["mode"] == "auto" and auto_d.is_empty() and (d["cw"] as Vector3).y < 100.0:
			auto_d = d
		if d["mode"] == "jammed" and jam.is_empty():
			jam = d
	if not auto_d.is_empty():
		await _put(lvl, (auto_d["cw"] as Vector3) + Vector3(0, 0.05, 1.5))
		await _wait(lvl, 50)
		var o1: float = auto_d["open"]
		await _put(lvl, (auto_d["cw"] as Vector3) + Vector3(0, 0.05, 6.0))
		await _wait(lvl, 60)
		out.append({"what": "an automatic sliding door opens on approach and closes behind", "ok": o1 > 0.9 and float(auto_d["open"]) < 0.1, "detail": [o1, auto_d["open"]]})
	if not jam.is_empty():
		await _put(lvl, (jam["cw"] as Vector3) + Vector3(0, 0.05, 1.2))
		await _wait(lvl, 40)
		out.append({"what": "a jammed door stays shut", "ok": float(jam["open"]) == 0.0})
	# --- the radial lift, both ways
	var c0: Node3D = sys.cars[0]["node"]
	var c1: Node3D = sys.cars[1]["node"]
	await _put(lvl, c0.global_transform * Vector3(0, 0.05, -1.3), PI)
	await _wait(lvl, 30)
	sys.ride_from(0)
	var n := 0
	while sys.lift["state"] != "idle" and n < 900:
		await lvl.get_tree().physics_frame
		n += 1
	var in1: bool = sys.in_car(1, lvl.player.global_position)
	out.append({"what": "the radial lift carries you from the Outer Ring to the Inner Gallery", "ok": in1 and sys.zone == "gallery", "detail": [n, lvl.player.global_position]})
	await _wait(lvl, 2)
	var live: Array = []
	for t in lvl.exits:
		if is_instance_valid(t) and not t.is_queued_for_deletion():
			live.append(t.edge_id)
	out.append({"what": "exit triggers stream with the slice: gallery has its flickering wall, not the hull's walk-back", "ok": live == ["L000_1>L001#2"], "detail": live})
	sys.ride_from(1)
	n = 0
	while sys.lift["state"] != "idle" and n < 900:
		await lvl.get_tree().physics_frame
		n += 1
	out.append({"what": "and back out to the hull", "ok": sys.in_car(0, lvl.player.global_position) and sys.zone == "hull", "detail": n})
	# --- climate: a frozen or overheated wing is lethal; leaving lets you recover
	for kind in ["cold", "hot"]:
		var box := AABB()
		for c in sys.climates:
			if c["state"] == kind:
				box = c["box"]
				break
		if box.size == Vector3.ZERO:
			out.append({"what": "a %s wing exists" % kind, "ok": false})
			continue
		lvl.player.health = 100.0
		sys.exposure = 0.0
		await _put(lvl, Vector3(box.get_center().x, box.position.y + 0.25, D.ZW - 1.2))
		var t := 0
		while lvl.player.health > 92.0 and t < 1500:
			await lvl.get_tree().physics_frame
			t += 1
		var peak: float = sys.exposure
		var hurt: bool = lvl.player.health < 100.0
		await _put(lvl, Vector3(-20.0, D.deck_y(int(round(box.position.y / D.DY))) + 0.05, -4.0))
		await _wait(lvl, 180)
		out.append({"what": "%s wing: exposure builds and hurts, then fades outside" % kind, "ok": hurt and peak > 0.5 and sys.exposure < peak - 0.3 and not lvl.player.dead,
			"detail": [t / 60.0, peak, sys.exposure, lvl.player.health]})
		lvl.player.health = 100.0
	sys.exposure = 0.0
	# --- hallucinations: heard and seen, but nothing is spawned
	var bodies_before: int = lvl.find_children("*", "CharacterBody3D", true, false).size()
	var h0: int = sys.halluc_count
	for kind in 4:
		sys.hallucinate(kind)
		await _wait(lvl, 20)
	out.append({"what": "hallucinations fire (footsteps, phantom door, Level 0 bleed, voice) without spawning anyone",
		"ok": sys.halluc_count == h0 + 4 and lvl.find_children("*", "CharacterBody3D", true, false).size() == bodies_before and bodies_before == 1})
	# --- automatons: the cleaner roams and stops for you
	var cl: Dictionary = sys.cleaners[0]
	var r: Node3D = cl["root"]
	await _put(lvl, Vector3(20.0, 0.05, -4.0))
	var p0 := r.position
	await _wait(lvl, 150)
	var moved := r.position.distance_to(p0)
	await _put(lvl, r.position + Vector3(0.0, 0.05, 1.1) if r.position.z < -5.0 else r.position + Vector3(0.0, 0.05, -1.1))
	await _wait(lvl, 10)
	var p1 := r.position
	await _wait(lvl, 90)
	out.append({"what": "the heptapedal cleaning automaton roams, and pauses beside you", "ok": moved > 0.5 and r.position.distance_to(p1) < 0.05 and cl["paused"], "detail": [moved, r.position.distance_to(p1)]})
	out.append({"what": "no entities: nothing in the level hunts or follows", "ok": lvl.get_tree().get_nodes_in_group("entity").is_empty()})
	lvl.player.health = 100.0
	Overlay.reset_screen_effects()
	await _put(lvl, lvl.arrivals["start"].origin, PI)
	return out
