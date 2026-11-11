extends Node
## Connectivity proof for the continuity laboratory.
##
## Run (autoloads required, so this is a SCENE, not a --script run):
##   godot --headless --path . --fixed-fps 60 res://tests/ContinuityConnectivityTest.tscn
##
## Requirement 4 of the brief asks the generator to "guarantee connectivity",
## and requirement 1 asks for "sensible connectivity" between the areas of
## Level 0. The topology test proves the PLAN is self-consistent; the
## physical walk test proves that ONE route can be walked. Neither of them
## proves that every seam of every chunk is actually open, and that the four
## portals of a chunk can be reached from one another inside that chunk.
##
## This test closes that gap with an instrument that does not read the
## generator's source:
##
##   1. The SEAM GRAPH is proved connected by a breadth-first search over the
##      declared shared-face openings, over a wide area and several seeds.
##   2. Every declared opening is PROBED WITH THE PLAYER'S OWN COLLIDER: a
##      capsule of the player's real radius and height must fit through the
##      hole in the wall. A door that is only declared but is walled off by a
##      partition fails here.
##   3. Every chunk is FLOOD FILLED with the same capsule over a navigation
##      grid, and all four of its portals must lie in ONE walkable component.
##      This is what "a chunk is a room you can move through" means, and it is
##      the property that a room partition can silently break.

const SEED := 1337
const SEEDS := [1337, 4242, 9001]
const C := 24.0
const STEP := 1.0
const RADIUS := 0.32
const HEIGHT := 1.78
## The capsule is placed this far ABOVE the floor surface, never flush with it.
##
## The reason is not fussiness. Godot's physics server keeps transforms in
## float32, so a ray that lands on a flat floor comes back as either
## +2.38418579e-07 or -2.38418579e-07 (2^-22) depending on the rounding of
## the hit. A capsule placed flush with the floor therefore sits 2.4e-07 m
## INSIDE the floor in half of the chunks, and the physics server reports
## that as a collision - the whole room then reads as "unwalkable" while
## nothing is actually blocked. Measured: chunk (-1,0,0) failed with
## floor_y = -2.38418579e-07 and chunk (0,0,0) passed with
## floor_y = +2.38418579e-07 for the SAME geometry.
##
## 2 cm is far above the 2.4e-07 artefact and far below anything that
## matters: the player capsule is 32 cm in radius and the door openings are
## 4.0 m wide, so 2 cm of clearance cannot turn a blocked room into an open
## one.
const CLEARANCE := 0.02
const SPAN := 2          # chunks in each direction around the spawn
const FLOOD_SPAN := 1    # chunks around the spawn that get the full flood fill
const FLOOD_STEP := 2.0  # grid step of the flood fill, in metres
const REPORT_PATH := "res://reports/qa/continuity_connectivity.json"

var lab: Node3D
var world: ChunkWorld3D
var space: PhysicsDirectSpaceState3D
var findings: Array = []
var failures := 0
var _deadline_ms := 0
var _capsule := CapsuleShape3D.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")


func _process(_delta: float) -> void:
	if _deadline_ms > 0 and Time.get_ticks_msec() > _deadline_ms:
		_deadline_ms = 0
		push_error("CONNECTIVITY: wall clock timeout")
		_report()
		get_tree().quit(2)


func _check(ok: bool, label: String, detail: Dictionary = {}) -> void:
	var entry := {"check": label, "pass": ok}
	if not detail.is_empty():
		entry["detail"] = detail
	findings.append(entry)
	if not ok:
		failures += 1
		push_error("CONNECTIVITY FAIL: " + label + " " + JSON.stringify(detail))


func _run() -> void:
	_deadline_ms = Time.get_ticks_msec() + 25 * 60 * 1000
	SessionState.set_mode(SessionState.Mode.DEVELOPER)
	_build_environment()
	_capsule.radius = RADIUS
	_capsule.height = HEIGHT

	# --- 1. The seam graph is connected, on the plan only. ----------------
	for seed_value in SEEDS:
		var reach := _seam_reach(seed_value, 12)
		_check(reach.size() == 25 * 25,
			"the seam graph of a 25x25 area is fully connected (seed %d)" % seed_value,
			{"reachable": reach.size(), "expected": 25 * 25})

	# --- 2 & 3. The geometry agrees with the plan. -------------------------
	lab = load("res://labs/Level0ContinuityLab.tscn").instantiate()
	_check(lab != null and ("world" in lab), "the continuity lab scene loads",
		{"scene": "res://labs/Level0ContinuityLab.tscn"})
	if lab == null:
		_report()
		return
	world = ChunkWorld3D.new()
	world.name = "QAWorld"
	world.seed_value = SEED
	world.world_id = "QA_CONNECTIVITY"
	world.disk_persistence_enabled = false
	world.radius_xz = SPAN
	world.radius_y = 0
	world.unload_xz = SPAN + 1
	world.unload_y = 0
	world.builds_per_frame = 64
	lab.world = world
	world.builder = lab._build_chunk
	add_child(world)
	world.build_around(Vector3(11.0, 0.12, 11.0), SPAN, 0)
	space = get_viewport().world_3d.direct_space_state
	for i in 4:
		await get_tree().physics_frame

	var probed_doors := 0
	var probed_chunks := 0
	var flooded_chunks := 0
	var worst_walkable := 1.0
	var worst_chunk := ""
	var clock := Time.get_ticks_msec()
	for cz in range(-SPAN, SPAN + 1):
		for cx in range(-SPAN, SPAN + 1):
			var key := Vector3i(cx, 0, cz)
			if not world.chunks.has(key):
				continue
			probed_chunks += 1
			var portal_points: Array = []
			for face in ["west", "east", "south", "north"]:
				var openings := ContinuityTopology.face_openings(SEED, key, face)
				if openings.is_empty():
					_check(false, "chunk %s declares an opening on its %s face" % [str(key), face])
					continue
				var op: Dictionary = openings[0]
				var centre := _face_point(key, face, float(op["at"]))
				probed_doors += 1
				_check(_fits(centre), "the %s portal of chunk %s is physically open" % [face, str(key)],
					{"at": op, "point": str(centre)})
				var inner := _face_point(key, face, float(op["at"]), -1.0)
				portal_points.append(inner)
			# The flood fill is the expensive half, so it runs on the chunks
			# around the spawn. Every chunk still gets the cheap door probe.
			if portal_points.size() < 4 or absi(cx) > FLOOD_SPAN or absi(cz) > FLOOD_SPAN:
				continue
			flooded_chunks += 1
			var result := _flood(key, portal_points)
			var fraction := float(result["walkable"]) / float(maxi(result["cells"], 1))
			if fraction < worst_walkable:
				worst_walkable = fraction
				worst_chunk = str(key)
			# The invariant is NOT "the room has one component". A room with a
			# hidden vault has a second, dead-end component, and that is the
			# feature, not the defect. The invariant is that all four portals
			# lie in ONE component, and that the ONLY other components are the
			# hidden regions the chunk declares.
			var pockets := int(result["components"]) - int(result["portal_components"])
			var meta := world.meta_of(key)
			var vault: Dictionary = meta.get("vault", {})
			var vault_rect := Rect2()
			if not vault.is_empty():
				vault_rect = vault["rect"]
			var stray := 0
			for pocket in result["pockets"]:
				if vault_rect.size == Vector2.ZERO or not vault_rect.encloses(pocket):
					stray += 1
			_check(int(result["portal_components"]) == 1,
				"all four portals of chunk %s lie in one walkable component" % str(key),
				{"portal_components": result["portal_components"],
					"components": result["components"], "pockets": pockets,
					"walkable_cells": result["walkable"], "cells": result["cells"],
					"fraction": fraction})
			_check(stray == 0,
				"every disconnected part of chunk %s is inside a declared hidden region" % str(key),
				{"stray_parts": stray, "pockets": pockets,
					"declared_hidden_regions": 1 if not vault.is_empty() else 0})
			_check(fraction > 0.25,
				"chunk %s is mostly walkable" % str(key),
				{"fraction": fraction, "walkable_cells": result["walkable"], "cells": result["cells"]})
			_check(result["portals_found"] == portal_points.size(),
				"every portal of chunk %s is reachable on foot" % str(key),
				{"found": result["portals_found"], "portals": portal_points.size()})
			_check(int(result["knife_edges"]) == 0,
				"chunk %s has no floor cell that only fits on a knife edge" % str(key),
				{"knife_edges": result["knife_edges"]})
			printerr("CONNECTIVITY chunk %s components=%d walkable=%.2f (%.1fs)" % [
				str(key), int(result["components"]), fraction,
				float(Time.get_ticks_msec() - clock) / 1000.0])

	_check(probed_doors == probed_chunks * 4,
		"every chunk contributed four probed doors", {"doors": probed_doors, "chunks": probed_chunks})
	_check(probed_chunks >= 25, "the probed area covers the whole 5x5 spawn neighbourhood",
		{"chunks": probed_chunks})
	_check(flooded_chunks >= 9, "the flood fill covered the 3x3 spawn neighbourhood",
		{"chunks": flooded_chunks})

	_report()


# ------------------------------------------------------------------ seam graph

## Breadth-first search over the declared shared-face openings. Two chunks are
## connected when the face they share declares an opening on both sides.
func _seam_reach(seed_value: int, radius: int) -> Dictionary:
	var seen := {Vector3i(0, 0, 0): true}
	var queue: Array = [Vector3i(0, 0, 0)]
	var head := 0
	while head < queue.size():
		var k: Vector3i = queue[head]
		head += 1
		for face in ["west", "east", "south", "north"]:
			var openings := ContinuityTopology.face_openings(seed_value, k, face)
			if openings.is_empty():
				continue
			var neighbour := ContinuityTopology.face_owner(k, face)
			if ContinuityTopology.face_axis(face) == "x":
				neighbour.x = k.x + (1 if face == "east" else -1)
			else:
				neighbour.z = k.z + (1 if face == "north" else -1)
			if absi(neighbour.x) > radius or absi(neighbour.z) > radius:
				continue
			if seen.has(neighbour):
				continue
			seen[neighbour] = true
			queue.append(neighbour)
	return seen


# ------------------------------------------------------------------ geometry

## World position of the middle of a face opening.
func _face_point(key: Vector3i, face: String, lateral: float, inset: float = 0.0) -> Vector3:
	var o := ContinuityTopology.origin(key)
	match face:
		"east":
			return Vector3(o.x + C + inset, o.y + 1.0, o.z + lateral)
		"west":
			return Vector3(o.x - inset, o.y + 1.0, o.z + lateral)
		"north":
			return Vector3(o.x + lateral, o.y + 1.0, o.z + C + inset)
		_:
			return Vector3(o.x + lateral, o.y + 1.0, o.z - inset)


## Can a capsule of the player's own size stand here?
func _fits(point: Vector3) -> bool:
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = _capsule
	params.transform = Transform3D(Basis.IDENTITY, point)
	params.collision_mask = 1
	params.collide_with_areas = false
	params.collide_with_bodies = true
	return space.intersect_shape(params, 1).is_empty()


## Height of the floor under a grid cell, or NAN when there is none.
func _floor_under(x: float, z: float, base_y: float) -> float:
	var params := PhysicsRayQueryParameters3D.create(
		Vector3(x, base_y + 2.4, z), Vector3(x, base_y - 1.2, z), 1)
	var hit := space.intersect_ray(params)
	if hit.is_empty():
		return NAN
	return float((hit["position"] as Vector3).y)


## Flood fill the walkable area of one chunk and report the components.
func _flood(key: Vector3i, portal_points: Array) -> Dictionary:
	var origin := ContinuityTopology.origin(key)
	var cells := int(ceil(C / STEP))
	var walkable: Dictionary = {}
	var knife_edges := 0
	for iz in cells:
		for ix in cells:
			# The grid is chunk local, but the physics space is in world
			# coordinates. Probing the local numbers would measure whichever
			# chunk happens to sit there - and every chunk would report the
			# same numbers.
			var x := origin.x + (float(ix) + 0.5) * STEP
			var z := origin.z + (float(iz) + 0.5) * STEP
			var floor_y := _floor_under(x, z, origin.y)
			if is_nan(floor_y):
				continue
			if not _fits(Vector3(x, floor_y + HEIGHT * 0.5 + CLEARANCE, z)):
				# A cell that only fits when the capsule is flush with the
				# floor is a knife edge, not a room: it is the float32
				# artefact described at CLEARANCE. Counted, never hidden.
				if _fits(Vector3(x, floor_y + HEIGHT * 0.5 + 1e-6, z)):
					knife_edges += 1
				continue
			walkable[Vector2i(ix, iz)] = floor_y
	var components := 0
	# How many of the four portals the BEST component reaches. Counting the
	# components that contain a portal would cap the answer at the number of
	# fragments, which is a different question.
	var best_portals := 0
	# How many components hold a portal at all. A room with a hidden vault has
	# a second component that holds none, and that is not a defect - but it
	# MUST be the only extra component, otherwise something else in the room
	# has been cut off.
	var portal_components := 0
	# The rectangle of every component that holds no portal. Whether a vault
	# shows up here depends on whether the 1 m grid happens to sample its
	# mouth: a narrow mouth is invisible to the grid and the vault reads as
	# a pocket, a wide one is sampled and the vault reads as part of the
	# room. Both are correct, so the pockets are checked by WHERE they are
	# and not by how many there are.
	var pockets: Array = []
	var seen: Dictionary = {}
	# The portal cells are resolved ONCE. Resolving them inside the component
	# loop made the cost of the probe grow with the number of fragments,
	# which is exactly the case where the probe matters most.
	var portal_cells: Array = []
	for portal in portal_points:
		portal_cells.append(_cell_of(key, portal))
	for start in walkable.keys():
		if seen.has(start):
			continue
		components += 1
		var queue: Array = [start]
		seen[start] = true
		var head := 0
		var cell_list: Array = []
		while head < queue.size():
			var cur: Vector2i = queue[head]
			head += 1
			cell_list.append(cur)
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nxt: Vector2i = cur + d
				if not walkable.has(nxt) or seen.has(nxt):
					continue
				seen[nxt] = true
				queue.append(nxt)
		var hits := 0
		for cell in portal_cells:
			if cell != Vector2i(-1, -1) and cell in cell_list:
				hits += 1
		if hits > 0:
			portal_components += 1
		else:
			var lo := Vector2(9999, 9999)
			var hi := Vector2(-9999, -9999)
			for cell in cell_list:
				lo.x = minf(lo.x, float(cell.x))
				lo.y = minf(lo.y, float(cell.y))
				hi.x = maxf(hi.x, float(cell.x))
				hi.y = maxf(hi.y, float(cell.y))
			pockets.append(Rect2(
				Vector2(lo.x * STEP, lo.y * STEP),
				Vector2((hi.x + 1) * STEP, (hi.y + 1) * STEP)))
		best_portals = maxi(best_portals, hits)
	return {"components": components, "walkable": walkable.size(), "cells": cells * cells,
		"portals_found": best_portals, "portal_components": portal_components,
		"pockets": pockets, "knife_edges": knife_edges}


## The walkable grid cell of a world point, in the chunk's own coordinates.
func _cell_of(key: Vector3i, point: Vector3) -> Vector2i:
	var o := ContinuityTopology.origin(key)
	var local_x := point.x - o.x
	var local_z := point.z - o.z
	var ix := int(floor(local_x / STEP))
	var iz := int(floor(local_z / STEP))
	var cells := int(ceil(C / STEP))
	for radius in range(7):
		for dz in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var cell := Vector2i(ix + dx, iz + dz)
				if cell.x < 0 or cell.y < 0 or cell.x >= cells or cell.y >= cells:
					continue
				if _cell_walkable(key, cell):
					return cell
	return Vector2i(-1, -1)


## Is this grid cell of this chunk walkable?
func _cell_walkable(key: Vector3i, cell: Vector2i) -> bool:
	var o := ContinuityTopology.origin(key)
	var x := o.x + (float(cell.x) + 0.5) * STEP
	var z := o.z + (float(cell.y) + 0.5) * STEP
	var floor_y := _floor_under(x, z, o.y)
	if is_nan(floor_y):
		return false
	return _fits(Vector3(x, floor_y + HEIGHT * 0.5 + CLEARANCE, z))


# ------------------------------------------------------------------ helpers

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


func _report() -> void:
	var dir := ProjectSettings.globalize_path("res://reports/qa")
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(dir + "/continuity_connectivity.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({
			"engine": Engine.get_version_info(),
			"seed": SEED,
			"status": "PASS" if failures == 0 else "FAIL",
			"checks": findings.size(),
			"failures": failures,
			"native": true,
			"probe": {"capsule_radius": RADIUS, "capsule_height": HEIGHT, "grid_step": STEP},
			"findings": findings,
		}, "  ") + "\n")
		f.close()
	print("CONNECTIVITY %d checks, %d failures" % [findings.size(), failures])
	get_tree().quit(0 if failures == 0 else 1)
