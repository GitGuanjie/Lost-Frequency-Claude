extends RefCounted
## Drives a real body along a route of waypoints.
##
## The body is a real CharacterBody3D with real collision. The walker does
## not cheat: it never teleports, it never ignores a wall, and it never
## pretends that a route it could not walk was walked.
##
## Three failures it has to survive, and each one has a lesson in it:
##
##   1. PUSHING STRAIGHT INTO A WALL. A body that pushes into a wall stops
##      dead. A body that pushes at a slight angle slides along it. So the
##      walker PROBES the directions around the desired one and picks the
##      first one the player's own capsule can actually move in.
##   2. WANDERING INTO A DEAD END. The world has rooms with exactly one
##      opening. A body that drifts into one and keeps pushing towards a
##      waypoint on the far side of the wall is stuck for good. So when the
##      body stops making progress the walker BACKTRACKS along the route it
##      already walked, and comes at the obstacle from a different angle.
##   3. A ROUTE THAT WAS PLANNED FOR A DIFFERENT PLACE. The world streams,
##      so the route in front of the body can stop being walkable. The
##      walker reports that it had to recover instead of hiding it.
##
## The walker is shared by the tests on purpose. A first version of it lived
## in two files at once, and a bug in it had to be fixed in two places; the
## bug was that the detour offset was never cleared, so a body that had
## detoured once walked 100 degrees off its route for the rest of the walk.

const REACH := 0.4            # how close counts as "waypoint reached"
const NEAR := 1.6             # how close counts as "next to the waypoint"
const NEAR_FRAMES := 300      # frames next to a waypoint before forcing it
const STUCK_FRAMES := 40      # frames without progress before a recovery
const RECOVER_FRAMES := 240   # how long a recovery may last
const PROBE_STEP := 0.55      # how far ahead a probe looks
const TRACE_POINTS := 48      # recent positions kept for the failure report

var player: Player
var waypoints: Array = []
var index := 0
var reached := false
var recoveries := 0
var forced := 0               # waypoints the body gave up on
var trace: Array = []         # recent positions, so a failure says where
var _stuck := 0
var _near := 0
var _best := INF          # the closest the body has been to its target
var _recover := 0
var _started := false
var _last_target := Vector3.ZERO
var _recover_from := 0


func setup(body: Player, points: Array) -> void:
	player = body
	waypoints = points


## Walk the waypoints. Returns when the list is done or the budget is out.
func walk(tree: SceneTree, budget: int) -> void:
	_start()
	while index < waypoints.size() and budget > 0:
		budget -= 1
		await step(tree)
	reached = index >= waypoints.size()


## Advance the body by ONE frame. A test that has to plan the next leg of a
## route while the body walks the leg before it drives the walker this way.
func step(tree: SceneTree) -> void:
	if not _started:
		_start()
	if index >= waypoints.size():
		return
	var recovering := _recover > 0
	var target: Vector3 = _target()
	var flat := Vector3(target.x - player.global_position.x, 0.0,
		target.z - player.global_position.z)
	var distance := flat.length()
	if distance < REACH:
		if recovering:
			# The body is back on the route it walked before. It now starts
			# the remaining route again from there.
			_recover = 0
			index = maxi(0, index - 1)
		else:
			index += 1
		_near = 0
		_best = INF
		return
	if distance < NEAR:
		_near += 1
		if _near > NEAR_FRAMES:
			# The body cannot get closer to this waypoint at all. Waiting for
			# ever would hide the fact, so the waypoint is given up on and the
			# count is reported.
			_near = 0
			forced += 1
			index += 1
			_best = INF
			return
	else:
		_near = 0
	# Is the body getting closer to its target? THAT is progress. Measuring
	# progress as "distance from some earlier position" is wrong: a body
	# that walks a metre towards its target, turns a corner and walks a
	# metre back has covered two metres and arrived where it started, and an
	# instrument that only watches the net displacement calls that a body
	# that is stuck. The long walk of the stress test failed exactly that
	# way: the walker was moving at three metres per second towards the
	# waypoint and was dragged back to the corner every forty frames.
	if distance < _best - 0.02:
		_best = distance
		_stuck = 0
	else:
		_stuck += 1
		if _stuck >= STUCK_FRAMES:
			_stuck = 0
			_begin_recovery()
	if not player.is_on_floor():
		# Falling into an open stairwell is legitimate physics. Let gravity
		# do its work and pick the route up again afterwards.
		player.qa_input = Vector2.ZERO
		await tree.physics_frame
		return
	var desired := flat.normalized()
	var heading := _steer(desired, recovering)
	if heading == Vector3.ZERO:
		# Nothing free that still makes progress towards the target. Better
		# to stand still and let the recovery backtrack than to walk into a
		# side room that has no other exit.
		player.qa_input = Vector2.ZERO
		_last_target = target
		await tree.physics_frame
		_record()
		return
	player.rotation.y = atan2(-heading.x, -heading.z)
	player.qa_input = Vector2(0.0, 1.0)
	_last_target = target
	await tree.physics_frame
	_record()


func _start() -> void:
	_started = true
	_best = INF


## Where the body is heading right now.
func _target() -> Vector3:
	if _recover > 0:
		# Backtrack: the last waypoint the body really reached is known
		# ground, because the body walked it.
		return waypoints[_recover_from]
	return waypoints[index]


## The body stopped making progress. Backtrack along the route and come at
## the obstacle again from a different angle.
func _begin_recovery() -> void:
	recoveries += 1
	_recover = RECOVER_FRAMES
	_recover_from = maxi(0, index - 1)
	_best = INF


## Choose a heading close to the desired one that the body can actually
## move in. A slope is always followed directly: a staircase is a slope, and
## a flat probe would report it as a wall.
##
## The probe uses the PLAYER'S OWN capsule at the PLAYER'S OWN transform, so
## it cannot disagree with the body it is about to move.
func _steer(desired: Vector3, wide: bool) -> Vector3:
	var angles := [0.0, 0.25, -0.25, 0.5, -0.5, 0.85, -0.85, 1.2, -1.2, 1.6, -1.6]
	if wide:
		# A recovery may have to turn the body right around.
		angles = [0.0, 0.3, -0.3, 0.7, -0.7, 1.1, -1.1, 1.57, -1.57,
			2.1, -2.1, 2.6, -2.6, PI]
	# The best free heading: the one that still makes progress towards the
	# target. A free heading that turns AWAY from the target is a door into a
	# side room, and a side room with one opening is where a walker dies.
	var best_free := Vector3.ZERO
	var best_progress := -2.0
	# The least blocked heading, used only when nothing at all is free.
	var best_blocked := desired
	var best_free_fraction := -1.0
	for angle in angles:
		var candidate := desired.rotated(Vector3.UP, angle).normalized()
		var score := _free_fraction(candidate)
		if score < 0.999:
			if score > best_free_fraction:
				best_free_fraction = score
				best_blocked = candidate
			continue
		var progress := candidate.dot(desired)
		if not wide and progress <= 0.0:
			continue
		if progress > best_progress:
			best_progress = progress
			best_free = candidate
	if best_progress > -2.0:
		return best_free
	if best_free_fraction < 0.0:
		return Vector3.ZERO
	return best_blocked


## How far the body can travel in this direction before it hits something.
## 1.0 means "all the way".
func _free_fraction(direction: Vector3) -> float:
	var motion := direction * PROBE_STEP
	var score := _sweep(motion)
	if score >= 0.999:
		return score
	# Allow a small step up, the same way the player controller does.
	if player.shape == null:
		return score
	var lifted := player.shape.global_transform
	lifted.origin += Vector3.UP * player.step_height
	return maxf(score, _sweep_from(lifted, motion))


## The sweep of the body's own shape from where it stands.
func _sweep(motion: Vector3) -> float:
	if player.shape == null:
		return 1.0
	return _sweep_from(player.shape.global_transform, motion)


## Sweep the body's own collision shape from a given transform.
func _sweep_from(xf: Transform3D, motion: Vector3) -> float:
	var shape := player.shape
	if shape == null:
		return 1.0
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = shape.shape
	params.transform = xf
	params.motion = motion
	params.collision_mask = 1
	params.collide_with_areas = false
	params.collide_with_bodies = true
	var space := player.get_world_3d().direct_space_state
	var result := space.cast_motion(params)
	if result.size() < 2:
		return 1.0
	# Godot 4.5 returns a PackedFloat32Array here, not the dictionary that
	# older documentation shows. The two numbers are the safe fraction and
	# the unsafe fraction, and the safe one is never the larger of the two,
	# so the smaller is the safe one whatever the order is.
	return minf(float(result[0]), float(result[1]))


func _record() -> void:
	trace.append(player.global_position)
	while trace.size() > TRACE_POINTS:
		trace.pop_front()


## A short description of where the body stopped, for the report.
func stuck_report() -> Dictionary:
	return {
		"waypoint_index": index,
		"target": str(_last_target),
		"position": str(player.global_position),
		"recoveries": recoveries,
		"forced": forced,
		"trace_head": str(trace[0]) if trace.size() > 0 else "",
		"trace_tail": str(trace[-1]) if trace.size() > 0 else "",
	}
