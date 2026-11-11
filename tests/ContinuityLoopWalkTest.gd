extends Node
## A loop is a route that comes back to where it started.
##
## A world can fail to have loops in three different ways, so this test proves
## all three separately:
##
##   1. PLAN. The seam graph must contain a cycle: more edges than a tree
##      needs. This is pure topology and reads no geometry.
##   2. GEOMETRY. The circuit that the megastructure publishes in its chunk
##      meta must be ONE closed ring, and the floor that was actually built
##      must contain that ring. The check is done against the built mesh
##      vertices, not against a second copy of the generator's formula.
##   3. PHYSICS. A real CharacterBody3D must walk the four-chunk ring
##      through real doorways and come back to its starting point.
##
## Run (autoloads required, so this is a SCENE, not a --script run):
##   godot --headless --path . --fixed-fps 60 res://tests/ContinuityLoopWalkTest.tscn

const SEED := 1337
const C := 24.0
const LANE_Z := 2.2     # local z of the lane that runs east-west
const REPORT_PATH := "res://reports/qa/continuity_loop_walk.json"
## The planner is loaded by path, not by its class name: a class_name only
## reaches a script that has been registered by an editor import, and a
## headless gate run must not depend on that.
const PathFinder := preload("res://tests/ContinuityPathFinder.gd")
const Walker := preload("res://tests/ContinuityWalker.gd")

var lab: Node3D
var world: ChunkWorld3D
var player: Player
var findings: Array = []
var failures := 0
var _deadline_ms := 0
var _trace: Array = []


func _trace_tail(count: int) -> Array:
	if _trace.size() <= count:
		return _trace
	return _trace.slice(_trace.size() - count)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_run")


func _process(_delta: float) -> void:
	if _deadline_ms > 0 and Time.get_ticks_msec() > _deadline_ms:
		_deadline_ms = 0
		push_error("LOOP WALK: wall clock timeout")
		_report()
		get_tree().quit(2)


func _check(ok: bool, label: String, detail: Dictionary = {}) -> void:
	var entry := {"check": label, "pass": ok}
	if not detail.is_empty():
		entry["detail"] = detail
	findings.append(entry)
	if not ok:
		failures += 1
		push_error("LOOP WALK FAIL: " + label + " " + JSON.stringify(detail))


func _run() -> void:
	_deadline_ms = Time.get_ticks_msec() + 20 * 60 * 1000
	_build_environment()
	lab = load("res://labs/Level0ContinuityLab.tscn").instantiate()
	if lab == null or not ("world" in lab):
		_check(false, "continuity lab scene loads",
			{"scene": "res://labs/Level0ContinuityLab.tscn"})
		_report()
		return
	world = ChunkWorld3D.new()
	world.name = "QAWorld"
	world.seed_value = SEED
	world.world_id = "QA_LOOP_WALK"
	world.disk_persistence_enabled = false
	world.radius_xz = 2
	world.radius_y = 1
	world.unload_xz = 3
	world.unload_y = 2
	world.builds_per_frame = 16
	lab.world = world
	world.builder = lab._build_chunk
	add_child(world)
	world.attach_save_scope()

	# --- 1. The plan has a cycle. ------------------------------------------
	var graph := _seam_graph(4)
	_check(graph["edges"] > graph["nodes"] - 1,
		"the seam graph of a 9x9 area contains a cycle",
		{"nodes": graph["nodes"], "edges": graph["edges"],
			"excess_edges": graph["edges"] - (graph["nodes"] - 1)})
	_check(_ring_corners().size() == 4, "the ring has four distinct corners",
		{"corners": str(_ring_corners())})

	# --- 2. The circuit is one closed ring, and it is really built. ------
	#
	# The ring belongs to a megastructure that is much larger than the area
	# around the spawn, so the chunks that carry it are built on purpose.
	# Otherwise the ring would arrive at the edge of the loaded area with a
	# dangling end, and "is it closed?" could not be answered at all.
	var perimeter := _structure_perimeter(SEED, Vector3i(0, 0, 0))
	_check(perimeter.size() >= 8,
		"the megastructure around the spawn has a perimeter of chunks",
		{"perimeter_chunks": perimeter.size()})
	for pk in perimeter:
		if not world.chunks.has(pk):
			world._build(pk)
	var segments: Array = []
	for pk in perimeter:
		for seg in world.meta_of(pk).get("circuit", []):
			segments.append(seg)
	_check(segments.size() >= 8,
		"the megastructure publishes the pieces of its circuit ring",
		{"segments": segments.size(), "perimeter_chunks": perimeter.size()})
	var ring := _ring_shape(segments)
	_check(ring["closed"], "the circuit segments form one closed ring",
		{"segments": segments.size(), "open_ends": ring["open_ends"],
			"length": ring["length"]})
	_check(ring["length"] > 100.0,
		"the circuit ring is longer than 100 m",
		{"length": ring["length"]})
	var built := _probe_ring_in_meshes(segments, perimeter)
	_check(built["missing"] == 0,
		"the circuit ring is present in the floor that was built",
		{"segments": segments.size(), "missing": built["missing"],
			"vertices_per_segment": built["counts"]})
	# The perimeter chunks are far outside the streaming radius; they were
	# built for the measurement only and are released again.
	for pk in perimeter:
		if world.chunks.has(pk):
			world._unload(pk)

	# --- 3. The physics: walk the ring and come home. ---------------------
	player = Player.new()
	player.name = "Walker"
	add_child(player)
	player.apply_rules({"gravity": 9.8, "flashlight": "allowed", "view_distance": 180.0})
	player.position = Vector3(11.0, 0.2, 11.0)
	player.qa_active = true
	player.qa_sprint = true
	world.target = player
	await _settle(30)

	# The route is planned on the grid the player's own capsule defines, so
	# the walker is asked to do what the geometry allows rather than what a
	# hand written list of coordinates hoped for.
	var space := get_viewport().world_3d.direct_space_state
	var finder = PathFinder.new(space)
	var east := _lateral(Vector3i(0, 0, 0), "east")
	var north := _lateral(Vector3i(1, 0, 0), "north")
	var west := _lateral(Vector3i(1, 0, 1), "west")
	var south := _lateral(Vector3i(0, 0, 1), "south")
	var spawn_point := Vector3(11.0, 0.2, 11.0)
	var legs := [
		{"name": "east", "from": spawn_point, "to": Vector3(C + 2.0, 0.0, east)},
		{"name": "north", "from": Vector3(C + 2.0, 0.0, east),
			"to": Vector3(C + north, 0.0, C + 2.0)},
		{"name": "west", "from": Vector3(C + north, 0.0, C + 2.0),
			"to": Vector3(C - 2.0, 0.0, C + west)},
		{"name": "south", "from": Vector3(C - 2.0, 0.0, C + west),
			"to": Vector3(south, 0.0, C - 2.0)},
		{"name": "home", "from": Vector3(south, 0.0, C - 2.0), "to": spawn_point},
	]
	var waypoints: Array = []
	for leg in legs:
		var area := _area_of(leg["from"], leg["to"])
		var path := finder.plan(leg["from"], leg["to"], area)
		_check(not path.is_empty(),
			"a route the player's own body can walk was planned for the %s leg" % leg["name"],
			{"from": str(leg["from"]), "to": str(leg["to"]), "points": path.size()})
		for p in path:
			waypoints.append(p)
	_check(waypoints.size() >= 8,
		"the ring is a route with real waypoints in it",
		{"waypoints": waypoints.size()})

	var spawn := player.global_position
	var visited := {}
	var start_key := world.key_at(spawn)
	visited[start_key] = true
	var walker = Walker.new()
	walker.setup(player, waypoints)
	var reached := false
	for frame in 60000:
		if walker.index >= walker.waypoints.size():
			reached = true
			break
		await walker.step(get_tree())
		var here := world.key_at(player.global_position)
		if not visited.has(here):
			visited[here] = true
		if frame % 30 == 0:
			_trace.append([frame, player.global_position.x, player.global_position.y,
				player.global_position.z, walker.index])
	var home := player.global_position
	var home_key := world.key_at(home)
	_check(reached,
		"the walker completed every waypoint of the ring",
		{"waypoints": waypoints.size(), "reached": walker.index,
			"pos": str(home), "chunk": str(home_key),
			"recoveries": walker.recoveries, "forced": walker.forced,
			"trace": _trace_tail(40)})
	_check(visited.size() >= 4,
		"the walker visited at least four chunks on the ring",
		{"visited": str(visited.keys())})
	_check(home_key == start_key,
		"the walker came back to the chunk it started in",
		{"start": str(start_key), "end": str(home_key)})
	_check(Vector2(home.x - spawn.x, home.z - spawn.z).length() < 6.0,
		"the walker came back to within six metres of its starting point",
		{"spawn": str(spawn), "home": str(home),
			"distance": Vector2(home.x - spawn.x, home.z - spawn.z).length()})
	_report()


## The rectangle a leg of the ring is allowed to use.
##
## The padding is generous on purpose. A route through a divided room has to
## reach the door of a partition wall, and that door can be a long way from
## the straight line between the two ends of the leg: the door of the x=20.6
## partition of chunk (0,0,1) is at local z 9.8..14.2, while the leg ends
## at local z 4.5 and local z -2. A tight box around the two ends of the
## leg does not contain the way through.
func _area_of(from: Vector3, to: Vector3) -> Rect2:
	var pad := 9.0
	var lo := Vector2(minf(from.x, to.x), minf(from.z, to.z)) - Vector2(pad, pad)
	var hi := Vector2(maxf(from.x, to.x), maxf(from.z, to.z)) + Vector2(pad, pad)
	return Rect2(lo, hi - lo)


# ------------------------------------------------------------------ the plan

## The shared-face graph of a square area, counted in nodes and edges.
## More edges than a tree needs means there is a cycle in the graph.
func _seam_graph(radius: int) -> Dictionary:
	var nodes := 0
	var edges := 0
	for cz in range(-radius, radius + 1):
		for cx in range(-radius, radius + 1):
			var k := Vector3i(cx, 0, cz)
			nodes += 1
			for face in ["east", "north"]:
				if ContinuityTopology.face_openings(SEED, k, face).is_empty():
					continue
				var owner_key := ContinuityTopology.face_owner(k, face)
				if owner_key == k:
					edges += 1
	return {"nodes": nodes, "edges": edges}


func _ring_corners() -> Array:
	return [Vector3i(0, 0, 0), Vector3i(1, 0, 0), Vector3i(1, 0, 1), Vector3i(0, 0, 1)]


## The chunks on the perimeter of the megastructure that owns a chunk. The
## circuit ring is drawn in exactly these chunks, so they are the chunks that
## have to exist for the ring to be complete.
func _structure_perimeter(seed_value: int, key: Vector3i) -> Array:
	var structure := RegionalPlan.structure_of(seed_value, key)
	if structure.is_empty():
		return []
	var footprint: Rect2i = structure.get("footprint", Rect2i())
	var anchor: Vector3i = structure.get("anchor", Vector3i.ZERO)
	var keys: Array = []
	for i in range(footprint.size.x):
		keys.append(Vector3i(anchor.x + i, key.y, anchor.z))
		keys.append(Vector3i(anchor.x + i, key.y, anchor.z + footprint.size.y - 1))
	for j in range(footprint.size.y):
		keys.append(Vector3i(anchor.x, key.y, anchor.z + j))
		keys.append(Vector3i(anchor.x + footprint.size.x - 1, key.y, anchor.z + j))
	# The corner chunks come out of this list twice. Counting their segments
	# twice inflates every corner endpoint, and a ring whose corners all have
	# four neighbours is not a ring.
	var unique: Array = []
	for k in keys:
		if not unique.has(k):
			unique.append(k)
	return unique


## The lateral offset of a face opening: a z coordinate for the east and west
## faces, an x coordinate for the north and south faces.
func _lateral(key: Vector3i, face: String) -> float:
	var openings := ContinuityTopology.face_openings(SEED, key, face)
	if openings.is_empty():
		return 11.0
	return float(openings[0]["at"])


## The waypoints of the four-chunk ring are not written down anywhere.
##
## They used to be, and they were wrong twice: the lanes and the openings do
## not line up, and the stair wells of a storey are open. Both mistakes are
## invisible on a plan and obvious to a body. The route is therefore planned
## on the grid that the player's own capsule defines.


# ------------------------------------------------------------- the geometry

## Do the published segments form one closed ring?
func _ring_shape(segments: Array) -> Dictionary:
	var ends := {}
	var length := 0.0
	for seg in segments:
		var a := Vector2(seg[0], seg[1])
		var b := Vector2(seg[2], seg[3])
		length += a.distance_to(b)
		for p in [a, b]:
			var key := "%.2f,%.2f,%.2f" % [p.x, p.y, float(seg[4])]
			ends[key] = int(ends.get(key, 0)) + 1
	var open_ends := 0
	for key in ends.keys():
		if int(ends[key]) != 2:
			open_ends += 1
	# One cycle means the segments can be walked as a closed chain: every
	# endpoint has exactly two neighbours.
	return {"closed": open_ends == 0 and segments.size() >= 8,
		"open_ends": open_ends, "length": length}


## Is the ring actually in the floor that was built?
##
## The inlay is 12 mm proud of the floor and carries no collision, so it is
## invisible to a physics probe. It IS in the merged mesh, and its vertices
## sit between 2 mm and 20 mm above the floor slab - a height band that the
## floor slab itself does not reach.
func _probe_ring_in_meshes(segments: Array, perimeter: Array) -> Dictionary:
	var missing := 0
	var counts: Array = []
	for seg in segments:
		var a := Vector2(seg[0], seg[1])
		var b := Vector2(seg[2], seg[3])
		var axis := (b - a).normalized()
		var length := a.distance_to(b)
		var found := 0
		for pk in perimeter:
			var record: Dictionary = world.chunks.get(pk, {})
			var node: Node3D = record.get("node")
			if node == null:
				continue
			var origin := ContinuityTopology.origin(pk)
			if a.x < origin.x - 0.5 or a.x > origin.x + C + 0.5:
				continue
			if a.y < origin.z - 0.5 or a.y > origin.z + C + 0.5:
				continue
			found += _band_vertices(node, a, axis, length)
		counts.append(found)
		if found < 8:
			missing += 1
	return {"missing": missing, "counts": counts}


func _band_vertices(node: Node3D, start: Vector2, axis: Vector2, length: float) -> int:
	var found := 0
	for mesh_node in _mesh_nodes(node):
		var mesh: Mesh = (mesh_node as MeshInstance3D).mesh
		if mesh == null or mesh.get_surface_count() == 0:
			continue
		var arrays := mesh.surface_get_arrays(0)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for v in verts:
			if v.y < 0.002 or v.y > 0.02:
				continue
			var delta := Vector2(v.x, v.z) - start
			var along := delta.dot(axis)
			if along < -0.3 or along > length + 0.3:
				continue
			var across := absf(delta.x * axis.y - delta.y * axis.x)
			if across > 0.65:
				continue
			found += 1
	return found


## GeoKit puts the merged meshes under a "RoomGeometry" node, so the meshes
## are not direct children of the chunk.
func _mesh_nodes(node: Node) -> Array:
	var out: Array = []
	for child in node.get_children():
		if child is MeshInstance3D:
			out.append(child)
		else:
			out.append_array(_mesh_nodes(child))
	return out


# ------------------------------------------------------------------ helpers

func _settle(frames: int) -> void:
	for i in frames:
		await get_tree().physics_frame


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
	var f := FileAccess.open(dir + "/continuity_loop_walk.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({
			"engine": Engine.get_version_info(),
			"seed": SEED,
			"status": "PASS" if failures == 0 else "FAIL",
			"checks": findings.size(),
			"failures": failures,
			"native": true,
			"findings": findings,
		}, "  ") + "\n")
		f.close()
	print("LOOP_WALK %d checks, %d failures" % [findings.size(), failures])
	get_tree().quit(0 if failures == 0 else 1)
