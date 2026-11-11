class_name ContinuityPathFinder
extends RefCounted
## Plans a route that the player's own body can walk.
##
## The world is not a corridor system. A chunk holds a stair well that eats
## the middle of it, some rooms are divided by partition walls whose only
## door opens onto that well, and the bay columns of a megastructure stand
## 0.8 m from the centre of a face opening - which is 0.02 m too close for
## a body of the player's width. A hand written route therefore has to know
## the room type of every chunk, and it breaks the first time the seed
## changes.
##
## This planner asks the geometry instead:
##
##   1. It lays a world aligned grid of points the player's capsule fits in.
##   2. It searches that grid for the shortest route.
##   3. It removes the corners of the route with a physics sweep, so the
##      body only ever has to walk along a line it can actually walk.
##
## The clearance under the capsule is 2 cm. Godot's physics server keeps
## transforms in float32, so a capsule placed flush with the floor lands
## 2.4e-07 m inside it in half of the chunks and reads as a collision.

const RADIUS := 0.32
const HEIGHT := 1.78
const CLEARANCE := 0.02
const STEP := 0.75

var _space: PhysicsDirectSpaceState3D
var _capsule := CapsuleShape3D.new()


func _init(space: PhysicsDirectSpaceState3D) -> void:
	_space = space
	_capsule.radius = RADIUS
	_capsule.height = HEIGHT


## Plan a route between two world points.
##
## area is the rectangle, in world x and z, that the route may use. The
## result is a list of world points; an empty list means that there is no
## route that the player's own body could take.
func plan(from: Vector3, to: Vector3, area: Rect2) -> Array:
	var grid := _grid(area)
	if grid.is_empty():
		return []
	var start := _nearest(grid, from)
	var goal := _nearest(grid, to)
	if start.x < 0 or goal.x < 0:
		return []
	var cells := _bfs(grid, start, goal)
	if cells.is_empty():
		return []
	var points: Array = []
	for cell in cells:
		points.append(_point(cell, grid[cell]))
	return _simplify(points)


## The walkable grid of an area: a cell is walkable when the player's own
## capsule fits above the floor that is actually there.
func _grid(area: Rect2) -> Dictionary:
	var grid := {}
	var i0 := int(floor(area.position.x / STEP))
	var i1 := int(ceil((area.position.x + area.size.x) / STEP))
	var j0 := int(floor(area.position.y / STEP))
	var j1 := int(ceil((area.position.y + area.size.y) / STEP))
	for j in range(j0, j1):
		for i in range(i0, i1):
			var x := (float(i) + 0.5) * STEP
			var z := (float(j) + 0.5) * STEP
			var fy := _floor_under(x, z)
			if is_nan(fy):
				continue
			if not _fits(Vector3(x, fy + HEIGHT * 0.5 + CLEARANCE, z)):
				continue
			grid[Vector2i(i, j)] = fy
	return grid


func _point(cell: Vector2i, floor_y: float) -> Vector3:
	return Vector3((float(cell.x) + 0.5) * STEP, floor_y + 1.0,
		(float(cell.y) + 0.5) * STEP)


## The walkable cell closest to a world point.
func _nearest(grid: Dictionary, point: Vector3) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_distance := 1e9
	for cell in grid.keys():
		var p := _point(cell, grid[cell])
		var d := Vector2(p.x - point.x, p.z - point.z).length()
		if d < best_distance:
			best_distance = d
			best = cell
	return best


func _bfs(grid: Dictionary, start: Vector2i, goal: Vector2i) -> Array:
	var came := {start: start}
	var queue: Array = [start]
	var head := 0
	while head < queue.size():
		var cur: Vector2i = queue[head]
		head += 1
		if cur == goal:
			break
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nxt: Vector2i = cur + d
			if not grid.has(nxt) or came.has(nxt):
				continue
			came[nxt] = cur
			queue.append(nxt)
	if not came.has(goal):
		return []
	var path: Array = []
	var cur := goal
	while cur != start:
		path.push_front(cur)
		cur = came[cur]
	path.push_front(start)
	return path


## Remove the corners of a grid path, keeping only the points that the body
## really has to stop at. A point is kept when the straight line from the
## last kept point to it is NOT clear - the body cannot take that line.
func _simplify(points: Array) -> Array:
	if points.size() < 3:
		return points
	var kept: Array = [points[0]]
	var anchor := 0
	while anchor < points.size() - 1:
		var best := anchor + 1
		var j := points.size() - 1
		while j > anchor + 1:
			if _clear(points[anchor], points[j]):
				best = j
				break
			j -= 1
		kept.append(points[best])
		anchor = best
	return kept


## Can the player's capsule travel straight from one point to another?
func _clear(from: Vector3, to: Vector3) -> bool:
	var fy := _floor_under(from.x, from.z)
	if is_nan(fy):
		return false
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = _capsule
	params.transform = Transform3D(Basis.IDENTITY,
		Vector3(from.x, fy + HEIGHT * 0.5 + CLEARANCE, from.z))
	params.motion = to - from
	params.collision_mask = 1
	params.collide_with_areas = false
	params.collide_with_bodies = true
	var result := _space.cast_motion(params)
	if result.size() < 2:
		return false
	# Godot 4.5 returns a PackedFloat32Array here, not the dictionary that
	# older documentation shows. The two numbers are the safe fraction and
	# the unsafe fraction, and the safe one is never the larger of the two,
	# so the smaller is the safe one whatever the order is.
	return minf(float(result[0]), float(result[1])) >= 0.999


func _floor_under(x: float, z: float) -> float:
	var params := PhysicsRayQueryParameters3D.create(
		Vector3(x, 2.6, z), Vector3(x, -1.4, z), 1)
	var hit := _space.intersect_ray(params)
	if hit.is_empty():
		return NAN
	return float((hit["position"] as Vector3).y)


func _fits(point: Vector3) -> bool:
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = _capsule
	params.transform = Transform3D(Basis.IDENTITY, point)
	params.collision_mask = 1
	params.collide_with_areas = false
	params.collide_with_bodies = true
	return _space.intersect_shape(params, 1).is_empty()
