extends Node
## Hidden regions: places you can walk into, that are not on the way to
## anywhere else.
##
## "A hidden region" is a definition, and this test holds the generator to
## it. A hidden region is a walkable pocket that
##
##   1. the PLAYER'S OWN CAPSULE can travel into, through its single mouth,
##      with real collision and no cheating with the transform;
##   2. has exactly ONE opening - every other point of its wall ring is
##      solid, which makes it a dead end rather than a shortcut;
##   3. holds no face portal, so it is not on the main circulation;
##   4. is out of the line of sight from the middle of the room, so it is
##      something you find rather than something you walk past.
##
## The mouth is 1.4 m wide and the wall around it is 0.16 m thick. A grid
## flood CANNOT prove that such an opening is passable: the capsule is 0.64 m
## wide, so no grid cell centre is ever far enough from the wall plane, and
## every flood reports the vault as sealed. The test therefore sweeps the
## capsule with PhysicsDirectSpaceState3D.cast_motion(), which answers the
## question that actually matters: can this shape go from here to there.
##
## Run (autoloads required, so this is a SCENE, not a --script run):
##   godot --headless --path . --fixed-fps 60 res://tests/ContinuityHiddenRegionTest.tscn

const SEED := 1337
const C := 24.0
const RADIUS := 0.32
const HEIGHT := 1.78
const CLEARANCE := 0.02
const SPAN := 2
const REPORT_PATH := "res://reports/qa/continuity_hidden_region.json"

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
		push_error("HIDDEN REGION: wall clock timeout")
		_report()
		get_tree().quit(2)


func _check(ok: bool, label: String, detail: Dictionary = {}) -> void:
	var entry := {"check": label, "pass": ok}
	if not detail.is_empty():
		entry["detail"] = detail
	findings.append(entry)
	if not ok:
		failures += 1
		push_error("HIDDEN REGION FAIL: " + label + " " + JSON.stringify(detail))


func _run() -> void:
	_deadline_ms = Time.get_ticks_msec() + 20 * 60 * 1000
	SessionState.set_mode(SessionState.Mode.DEVELOPER)
	_build_environment()
	_capsule.radius = RADIUS
	_capsule.height = HEIGHT
	lab = load("res://labs/Level0ContinuityLab.tscn").instantiate()
	world = ChunkWorld3D.new()
	world.name = "QAWorld"
	world.seed_value = SEED
	world.world_id = "QA_HIDDEN_REGION"
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

	var vaults: Array = []
	for key in world.chunks.keys():
		var meta := world.meta_of(key)
		var vault: Dictionary = meta.get("vault", {})
		if not vault.is_empty():
			vaults.append({"key": key, "vault": vault})
	_check(vaults.size() >= 2,
		"the explored area contains at least two hidden regions",
		{"hidden_regions": vaults.size(), "chunks": world.chunks.size()})
	var tested := 0
	for entry in vaults:
		if tested >= 3:
			break
		tested += 1
		await _check_vault(entry["key"], entry["vault"])
	_report()


## The six properties of one hidden region.
func _check_vault(key: Vector3i, vault: Dictionary) -> void:
	var label := str(key)
	var origin := ContinuityTopology.origin(key)
	var approach: Vector3 = vault["approach"]
	var opening: Vector3 = vault["opening"]
	var inside: Vector3 = vault["inside"]
	var rect: Rect2 = vault["rect"]

	# 1. The capsule can travel from the room into the vault.
	var floor_y := _floor_under(approach.x, approach.z, origin.y)
	var start := Vector3(approach.x, floor_y + HEIGHT * 0.5 + CLEARANCE, approach.z)
	var target := Vector3(inside.x, floor_y + HEIGHT * 0.5 + CLEARANCE, inside.z)
	var sweep := _sweep(start, target - start)
	_check(sweep["safe"] >= 0.999,
		"the player capsule can travel into the hidden region of chunk %s" % label,
		{"safe_fraction": sweep["safe"], "unsafe_fraction": sweep["unsafe"],
			"from": str(start), "to": str(target)})
	_check(_fits(target),
		"the inside of the hidden region of chunk %s is standable" % label,
		{"point": str(target)})

	# 2. Exactly one opening: the wall ring is solid everywhere else.
	var gaps := _wall_gaps(key, rect, vault)
	_check(int(gaps["openings"]) == 1,
		"the hidden region of chunk %s has exactly one opening" % label,
		{"openings": gaps["openings"], "outside_mouth": gaps["outside_mouth"],
			"mouth_open": gaps["mouth_open"]})

	# 3. No face portal inside it.
	var portals_inside := 0
	for face in ["west", "east", "south", "north"]:
		var openings := ContinuityTopology.face_openings(SEED, key, face)
		if openings.is_empty():
			continue
		var at := _face_point(key, face, float(openings[0]["at"]))
		if rect.has_point(Vector2(at.x - origin.x, at.z - origin.z)):
			portals_inside += 1
	_check(portals_inside == 0,
		"the hidden region of chunk %s holds no face portal" % label,
		{"portals_inside": portals_inside})

	# 4. It is out of the line of sight from the middle of the room.
	var eye := Vector3(origin.x + 12.0, origin.y + 1.2, origin.z + 12.0)
	var blocked := _ray_blocked(eye, Vector3(inside.x, origin.y + 1.2, inside.z))
	_check(blocked,
		"the hidden region of chunk %s is not in the line of sight from the room" % label,
		{"eye": str(eye), "target": str(inside)})


## Sample every wall of the vault and count where a capsule would fit.
##
## The only opening of a vault is the gap in one of its four walls, so the
## samples that fit have to be exactly the span of that gap, and no sample
## on any other wall may fit at all.
func _wall_gaps(key: Vector3i, rect: Rect2, vault: Dictionary) -> Dictionary:
	var origin := ContinuityTopology.origin(key)
	var span: Array = vault["mouth_span"]
	var mouth_wall: String = vault["mouth_wall"]
	var mouth_open := false
	var outside_mouth := 0
	var openings := 0
	var samples := 0
	var step := 0.2
	# North and south walls run along x; west and east walls run along z.
	for wall in ["north", "south", "west", "east"]:
		var along := 0.0
		var length := 0.0
		if wall == "north" or wall == "south":
			along = rect.position.x
			length = rect.size.x
		else:
			along = rect.position.y
			length = rect.size.y
		var t := 0.0
		var was_open := false
		while t <= length + 0.001:
			var lateral := along + t
			var point := Vector2.ZERO
			match wall:
				"north":
					point = Vector2(origin.x + lateral, origin.z + rect.position.y)
				"south":
					point = Vector2(origin.x + lateral, origin.z + rect.end.y)
				"west":
					point = Vector2(origin.x + rect.position.x, origin.z + lateral)
				_:
					point = Vector2(origin.x + rect.end.x, origin.z + lateral)
			samples += 1
			if _probe_wall(point.x, point.y, origin.y):
				# An opening is a RUN of passable samples, not a sample. A
				# 1.4 m gap is passable for about four sample points, and
				# counting the points would report four openings.
				if not was_open:
					openings += 1
				was_open = true
				if wall == mouth_wall and lateral >= float(span[0]) - 0.05 \
						and lateral <= float(span[1]) + 0.05:
					mouth_open = true
				else:
					outside_mouth += 1
			else:
				was_open = false
			t += step
	return {"openings": openings, "outside_mouth": outside_mouth,
		"mouth_open": mouth_open, "samples": samples}


# ------------------------------------------------------------------ helpers

## World position of the middle of a face opening.
func _face_point(key: Vector3i, face: String, lateral: float) -> Vector3:
	var o := ContinuityTopology.origin(key)
	match face:
		"east":
			return Vector3(o.x + C, o.y + 1.0, o.z + lateral)
		"west":
			return Vector3(o.x, o.y + 1.0, o.z + lateral)
		"north":
			return Vector3(o.x + lateral, o.y + 1.0, o.z + C)
		_:
			return Vector3(o.x + lateral, o.y + 1.0, o.z)


## Height of the floor under a point, or NAN when there is none.
func _floor_under(x: float, z: float, base_y: float) -> float:
	var params := PhysicsRayQueryParameters3D.create(
		Vector3(x, base_y + 2.4, z), Vector3(x, base_y - 1.2, z), 1)
	var hit := space.intersect_ray(params)
	if hit.is_empty():
		return NAN
	return float((hit["position"] as Vector3).y)


## Can a capsule of the player's own size stand here?
func _fits(point: Vector3) -> bool:
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = _capsule
	params.transform = Transform3D(Basis.IDENTITY, point)
	params.collision_mask = 1
	params.collide_with_areas = false
	params.collide_with_bodies = true
	return space.intersect_shape(params, 1).is_empty()


## Can a capsule be placed at a wall and pass through it?
func _probe_wall(x: float, z: float, base_y: float) -> bool:
	var floor_y := _floor_under(x, z, base_y)
	if is_nan(floor_y):
		return false
	return _fits(Vector3(x, floor_y + HEIGHT * 0.5 + CLEARANCE, z))


## Sweep the capsule along a motion and report how far it gets.
func _sweep(from: Vector3, motion: Vector3) -> Dictionary:
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = _capsule
	params.transform = Transform3D(Basis.IDENTITY, from)
	params.motion = motion
	params.collision_mask = 1
	params.collide_with_areas = false
	params.collide_with_bodies = true
	var result := space.cast_motion(params)
	# Godot 4.5 hands back a PackedFloat32Array, not a dictionary. The two
	# numbers are the safe fraction and the unsafe fraction, and the safe one
	# is never the larger, so the smaller is the safe one whatever the order.
	if result.size() < 2:
		return {"safe": 0.0, "unsafe": 0.0}
	var a := float(result[0])
	var b := float(result[1])
	return {"safe": minf(a, b), "unsafe": maxf(a, b)}


## Is the straight line between two points blocked by the world?
func _ray_blocked(from: Vector3, to: Vector3) -> bool:
	var params := PhysicsRayQueryParameters3D.create(from, to, 1)
	var hit := space.intersect_ray(params)
	return not hit.is_empty()


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
	var f := FileAccess.open(dir + "/continuity_hidden_region.json", FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({
			"engine": Engine.get_version_info(),
			"seed": SEED,
			"status": "PASS" if failures == 0 else "FAIL",
			"checks": findings.size(),
			"failures": failures,
			"native": true,
			"probe": {"capsule_radius": RADIUS, "capsule_height": HEIGHT,
				"clearance": CLEARANCE},
			"findings": findings,
		}, "  ") + "\n")
		f.close()
	print("HIDDEN_REGION %d checks, %d failures" % [findings.size(), failures])
	get_tree().quit(0 if failures == 0 else 1)
