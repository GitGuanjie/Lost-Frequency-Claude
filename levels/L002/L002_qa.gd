extends RefCounted
## Level 2 QA hooks: curated capture stills and engine self-tests for the
## sourced mechanics (lattice connectivity, decks, 45-degree turns, series
## circuits, void room round trip).

const G := preload("res://levels/L002/L002_geo.gd")
const DY := 4.2



static func _find_half(lvl, modes: Array, need_doors: bool = false) -> Array:
	for rr in range(0, 4):
		for dz in range(-rr, rr + 1):
			for dx in range(-rr, rr + 1):
				if maxi(absi(dx), absi(dz)) != rr or (dx == 0 and dz == 0):
					continue
				for d: int in [0, 2, 4, 6]:
					var h: Dictionary = lvl.half_info(dx, dz, d)
					if h["mode"] in modes and lvl.node_kind(dx, dz) == "small":
						return [Vector2i(dx, dz), d, h]
	return []


static func capture_plan(lvl) -> Array:
	var plan: Array = lvl.qa_shots.duplicate()
	var g := Vector3(50, 0, 10)
	plan.append({"name": "gallery_floor", "pos": g + Vector3(-5.6, 1.62, -1.6), "target": g + Vector3(4.0, 3.6, 3.4)})
	plan.append({"name": "catwalk", "pos": g + Vector3(0.0, DY + 1.62, -5.0), "target": g + Vector3(4.5, 0.8, 4.5)})
	for spec in [["stacked", ["stack"]], ["stair", ["stair"]], ["corridor", ["lo"]]]:
		var f := _find_half(lvl, spec[1])
		if f.is_empty():
			continue
		var key: Vector2i = f[0]
		var d: int = f[1]
		var C := Vector3(key.x * 20.0 + 10.0, 0, key.y * 20.0 + 10.0)
		var a: float = lvl.apothem(key.x, key.y)
		var dv := G.dvec(d)
		var pos := C + dv * (a - 1.6) + Vector3.UP * 1.62
		var tgt := C + dv * 16.0 + Vector3.UP * (1.5 if spec[0] != "stair" else DY + 1.2)
		plan.append({"name": spec[0], "pos": pos, "target": tgt, "prepare": func(): lvl.world.build_around(C, 1)})
	return plan


static func self_test(lvl, sys) -> Array:
	var out: Array = []
	await lvl.get_tree().process_frame
	# lower deck: the service lattice is connected around the arrival
	var seen := {Vector2i(0, 0): true}
	var q: Array = [Vector2i(0, 0)]
	while not q.is_empty():
		var n: Vector2i = q.pop_front()
		for d in 8:
			var h: Dictionary = lvl.half_info(n.x, n.y, d)
			if h["mode"] in ["lo", "stack", "stair"] or (h["mode"] == "up" and int(h["stair"]) != 0):
				var dv := G.dvec(d)
				var m := n + Vector2i(roundi(dv.x), roundi(dv.z))
				if absi(m.x) <= 4 and absi(m.y) <= 4 and not seen.has(m):
					seen[m] = true
					q.append(m)
	out.append({"what": "every junction in a 9x9 window is reachable on foot from the arrival", "ok": seen.size() == 81, "detail": seen.size()})
	var stairs := 0
	var stacks := 0
	var galleries := 0
	var turns_ok := true
	for key in lvl.world.chunks.keys():
		if lvl.node_kind(key.x, key.y) == "gallery":
			galleries += 1
		for d in 8:
			var h: Dictionary = lvl.half_info(key.x, key.y, d)
			if h["mode"] == "stair":
				stairs += 1
			if h["mode"] == "stack":
				stacks += 1
			var ang := rad_to_deg(atan2(G.dvec(d).z, G.dvec(d).x))
			if absf(fmod(absf(ang) + 0.001, 45.0)) > 0.01:
				turns_ok = false
	out.append({"what": "two walkable decks: stairs, stacked corridors and a gallery stream in", "ok": stairs > 0 and stacks > 0 and galleries > 0, "detail": [stairs, stacks, galleries]})
	out.append({"what": "corridors leave junctions only at multiples of 45 degrees", "ok": turns_ok})
	# series circuit: one break darkens the whole block
	var counts := {}
	for a in lvl.lights.anchors:
		if a.has("cid"):
			counts[a["cid"]] = int(counts.get(a["cid"], 0)) + 1
	var best := ""
	for c in counts.keys():
		if best == "" or counts[c] > counts[best]:
			best = c
	var dead: int = sys.trip(best, false)
	var lit_left := 0
	for a in lvl.lights.anchors:
		if a.get("cid", "") == best and float(a["energy"]) > 0.0:
			lit_left += 1
	out.append({"what": "breaking one light kills its whole series circuit", "ok": best != "" and lit_left == 0 and dead > 0, "detail": [best, counts.get(best, 0), dead]})
	out.append({"what": "a circuit spans a 3x3..6x6-ish block of fixtures", "ok": int(counts.get(best, 0)) >= 6 and int(counts.get(best, 0)) <= 48, "detail": counts.get(best, 0)})
	# void room round trip
	var p: Player = lvl.player
	var back := p.global_position
	sys.enter_void(back + Vector3(0, 0, 0.5), Vector3(0, 0, -1))
	await lvl.get_tree().physics_frame
	var deep: bool = p.global_position.y < -100.0 and lvl.environment.ambient_light_energy == 0.0
	sys.leave_void()
	await lvl.get_tree().physics_frame
	out.append({"what": "void room is lightless and the doorway leads back", "ok": deep and p.global_position.y > -1.0, "detail": p.global_position})
	return out
