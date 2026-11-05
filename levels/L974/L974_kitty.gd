extends Node3D
## Kitty — Level 974's only entity (SOURCE): a 3.2 m humanoid with unnaturally
## long, lanky limbs that lack hands or feet, matt-black skin like mosou black
## fabric, no facial features; she moves smoothly and swiftly, often appearing
## close by, and stalks wanderers without ever showing hostility. If aggression
## is shown or the house is damaged she stops stalking (SOURCE).
## ADAPTATION: she stoops under the 2.6 m ceiling (legs 1.56 + torso 0.95 +
## neck 0.25 + head 0.45 = 3.21 m when upright) and travels a waypoint graph of
## doorways and rooms; she never blocks you: crowd her and she drifts away.

enum State { HOME, STALK, WITHDRAWN, GIFTED }

signal appeared_close

var state := State.STALK
var player: Player
var nodes: Array = []          # Vector3 waypoints (house coordinates)
var adj: Array = []            # adjacency lists
var home := Vector3.ZERO
var home_face := Vector3.ZERO  # direction to face while at home
var frozen := false            # QA fixture / capture posing
var seen := false
var moving := false
var _cur := 0
var _path: Array = []
var _think := 4.0
var _surprise_t := 50.0
var _sneaking := false
var _was_seen := false
var _rng := RandomNumberGenerator.new()
var _spine: Node3D
var _neck: Node3D
var _head: Node3D
var _t := 0.0


func setup(p_seed: int) -> void:
	_rng.seed = p_seed
	var black := StandardMaterial3D.new()
	black.albedo_color = Color(0.006, 0.006, 0.008)
	black.roughness = 1.0
	black.metallic_specular = 0.0
	for sx in [-1.0, 1.0]:
		var leg := _limb(1.56, 0.075, 0.012, black)
		leg.position = Vector3(0.11 * sx, 0.78, 0.0)
		leg.rotation.z = 0.03 * sx
		add_child(leg)
	var hips := Node3D.new()
	hips.position = Vector3(0, 1.55, 0)
	add_child(hips)
	var pelvis := _blob(Vector3(0.17, 0.12, 0.11), black)
	hips.add_child(pelvis)
	_spine = Node3D.new()
	_spine.rotation.x = -0.9
	hips.add_child(_spine)
	var torso := _limb(0.95, 0.15, 0.09, black)
	torso.position = Vector3(0, 0.475, 0)
	torso.scale = Vector3(1.0, 1.0, 0.65)
	_spine.add_child(torso)
	var shoulders := Node3D.new()
	shoulders.position = Vector3(0, 0.95, 0)
	_spine.add_child(shoulders)
	_neck = Node3D.new()
	_neck.rotation.x = -0.75
	shoulders.add_child(_neck)
	var neck := _limb(0.25, 0.035, 0.04, black)
	neck.position = Vector3(0, 0.125, 0)
	_neck.add_child(neck)
	_head = Node3D.new()
	_head.position = Vector3(0, 0.25, 0)
	_head.rotation.x = 1.1
	_neck.add_child(_head)
	var head := _blob(Vector3(0.14, 0.225, 0.15), black)
	head.position = Vector3(0, 0.2, 0)
	_head.add_child(head)
	for sx in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(0.2 * sx, -0.02, 0)
		pivot.rotation = Vector3(0.92, 0, 0.05 * sx)
		shoulders.add_child(pivot)
		var arm := _limb(1.75, 0.04, 0.02, black)
		arm.position = Vector3(0, -0.875, 0)
		pivot.add_child(arm)


func _limb(length: float, r_top: float, r_bottom: float, mat: Material) -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.height = length
	m.top_radius = r_top
	m.bottom_radius = r_bottom
	m.radial_segments = 10
	m.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = mat
	return mi


func _blob(radii: Vector3, mat: Material) -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = 1.0
	m.height = 2.0
	m.radial_segments = 16
	m.rings = 8
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.scale = radii
	mi.material_override = mat
	return mi


func place_at(pos: Vector3, face: Vector3) -> void:
	global_position = pos
	_cur = _nearest(pos)
	_path.clear()
	if face.length() > 0.01:
		rotation.y = atan2(-face.x, -face.z)


func chest() -> Vector3:
	return global_position + Vector3(0, 1.7, 0)


func _nearest(p: Vector3) -> int:
	var best := 0
	var bd := INF
	for i in nodes.size():
		var d: float = (nodes[i] as Vector3).distance_squared_to(p)
		if d < bd:
			bd = d
			best = i
	return best


func _bfs(a: int, b: int) -> Array:
	var prev := {a: -1}
	var q := [a]
	while not q.is_empty():
		var n: int = q.pop_front()
		if n == b:
			break
		for m in adj[n]:
			if not prev.has(m):
				prev[m] = n
				q.append(m)
	if not prev.has(b):
		return []
	var out: Array = []
	var c := b
	while c != a:
		out.push_front(c)
		c = prev[c]
	return out


func _visible_to(cam: Camera3D) -> bool:
	if cam == null or not cam.is_position_in_frustum(chest()):
		return false
	var q := PhysicsRayQueryParameters3D.create(cam.global_position, chest(), 1)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _process(delta: float) -> void:
	_t += delta
	if _spine:
		_spine.rotation.x = -0.9 + sin(_t * 0.9) * 0.025
	if player == null or frozen:
		return
	seen = _visible_to(get_viewport().get_camera_3d())
	var pp := player.global_position
	var to_p := Vector3(pp.x - global_position.x, 0, pp.z - global_position.z)
	match state:
		State.STALK:
			_stalk(delta, pp, to_p)
		State.HOME, State.WITHDRAWN:
			if global_position.distance_to(home) > 0.15:
				if _path.is_empty():
					_path = _bfs(_cur, _nearest(home))
					_path.append(-1)
				_follow(delta, 1.6)
			else:
				moving = false
				_face(home_face, delta)
		State.GIFTED:
			moving = false
	if seen and not _was_seen and _sneaking and to_p.length() < 2.8:
		_sneaking = false
		appeared_close.emit()
	_was_seen = seen


func _stalk(delta: float, pp: Vector3, to_p: Vector3) -> void:
	_think -= delta
	_surprise_t -= delta
	var fwd := -player.global_transform.basis.z
	fwd.y = 0.0
	# personal space: never block the wanderer; drift away when crowded
	if to_p.length() < 1.1 and player.velocity.length() > 0.5 and player.velocity.normalized().dot(-to_p.normalized()) > 0.4:
		var away := -1
		var far := 0.0
		for m in adj[_cur]:
			var d := (nodes[m] as Vector3).distance_to(pp)
			if d > far:
				far = d
				away = m
		if away >= 0:
			_path = [away]
			_think = 4.0
	if _path.is_empty() and _think <= 0.0:
		_think = _rng.randf_range(6.0, 13.0)
		var want_close := _surprise_t <= 0.0 and not seen
		var best := -1
		var bs := -INF
		for i in nodes.size():
			var off: Vector3 = (nodes[i] as Vector3) - pp
			off.y = 0.0
			var d := off.length()
			var lo := 1.6 if want_close else 2.4
			var hi := 2.6 if want_close else 5.8
			if d < lo or d > hi:
				continue
			var s := -fwd.dot(off.normalized()) + _rng.randf() * 0.5
			if s > bs:
				bs = s
				best = i
		if best >= 0 and best != _cur:
			_path = _bfs(_cur, best)
			if want_close:
				_surprise_t = _rng.randf_range(40.0, 80.0)
				_sneaking = true
	if not _path.is_empty():
		# smooth and swift: faster while nobody is looking
		_follow(delta, 1.5 if seen else 3.6)
	else:
		moving = false
		_face(to_p, delta)


func _follow(delta: float, speed: float) -> void:
	var n: int = _path[0]
	var goal: Vector3 = home if n < 0 else nodes[n]
	var d := goal - global_position
	if d.length() < 0.05:
		if n >= 0:
			_cur = n
		_path.pop_front()
		return
	moving = true
	var step := minf(d.length(), speed * delta)
	global_position += d.normalized() * step
	_face(Vector3(d.x, 0, d.z), delta * 1.6)


func _face(dir: Vector3, delta: float) -> void:
	if dir.length() < 0.01:
		return
	var want := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, want, clampf(delta * 3.0, 0.0, 1.0))


## Called by the level when aggression is shown or the house is damaged.
func withdraw() -> void:
	state = State.WITHDRAWN
	_path.clear()
	_sneaking = false
