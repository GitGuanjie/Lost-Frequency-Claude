class_name Props
extends RefCounted
## Simple model placement for level authors.
##   Props.place(level, parent, "ph/metal_office_desk", pos, yaw_deg, height, collide)
##   Props.place(level, parent, "kenney/furniture-kit/desk", pos, yaw_deg)
## ids:
##   "ph/<id>"             -> res://assets/external/models/<id>.glb (Poly Haven, CC0)
##   "kenney/<pack>/<name>" -> res://assets/packs/<pack>/<name>.glb (Kenney, CC0)
## height <= 0 keeps the authored real-world scale (Poly Haven models are metric).
## collide adds ONE box collider from the measured bounds (never per-triangle).
## Placement is deterministic; bounds are measured once per model and cached.

## Models whose authored scale is wrong get a default height (m) when height <= 0.
const DEFAULT_HEIGHT := {"ph/steel_frame_shelves_01": 2.1}

static var _scenes: Dictionary = {}
static var _bounds: Dictionary = {}
static var placed_count := 0
static var missing: Dictionary = {}

static func path_for(id: String) -> String:
	if id.begins_with("ph/"):
		var n := id.substr(3)
		return "res://assets/external/models/%s.glb" % n
	if id.begins_with("kenney/"):
		return "res://assets/packs/%s.glb" % id.substr(7)
	return id

static func exists(id: String) -> bool:
	return ResourceLoader.exists(path_for(id))

static func _scene(id: String) -> PackedScene:
	if _scenes.has(id):
		return _scenes[id]
	var p := path_for(id)
	var ps: PackedScene = null
	if ResourceLoader.exists(p):
		ps = load(p) as PackedScene
	if ps == null and not missing.has(id):
		missing[id] = true
		push_warning("Props: missing model " + p)
	_scenes[id] = ps
	return ps

## Local-space AABB of a model (union of all MeshInstance3D bounds).
static func bounds(id: String) -> AABB:
	if _bounds.has(id):
		return _bounds[id]
	var ps := _scene(id)
	var box := AABB()
	if ps:
		var inst := ps.instantiate() as Node3D
		box = _measure(inst, Transform3D.IDENTITY)
		inst.free()
	_bounds[id] = box
	return box

static func _measure(n: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	var t := xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		out = t * (n as MeshInstance3D).mesh.get_aabb()
		first = false
	for c in n.get_children():
		var b := _measure(c, t)
		if b.size == Vector3.ZERO:
			continue
		out = b if first else out.merge(b)
		first = false
	return out

## Place a model with its base on pos.y, centred on pos.xz.
static func place(level: Node3D, parent: Node3D, id: String, pos: Vector3, yaw_deg: float = 0.0,
		height: float = 0.0, collide: bool = false, shadows: bool = true) -> Node3D:
	var ps := _scene(id)
	if ps == null:
		return null
	var model := ps.instantiate() as Node3D
	if model == null:
		return null
	var b := bounds(id)
	var s := 1.0
	if height <= 0.0:
		height = float(DEFAULT_HEIGHT.get(id, 0.0))
	if height > 0.0 and b.size.y > 0.01:
		s = height / b.size.y
	var holder := Node3D.new()
	holder.name = "GLB_" + id.get_file()
	holder.position = pos
	holder.rotation.y = deg_to_rad(yaw_deg)
	(parent if parent else level).add_child(holder)
	model.scale = Vector3.ONE * s
	model.position = Vector3(-(b.position.x + b.size.x * 0.5) * s, -b.position.y * s, -(b.position.z + b.size.z * 0.5) * s)
	holder.add_child(model)
	if not shadows:
		_no_shadows(model)
	if collide and b.size != Vector3.ZERO:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = b.size * s
		cs.shape = shape
		cs.position = Vector3(0, b.size.y * s * 0.5, 0)
		body.add_child(cs)
		holder.add_child(body)
	placed_count += 1
	return holder

static func _no_shadows(n: Node) -> void:
	if n is GeometryInstance3D:
		(n as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children():
		_no_shadows(c)

## Scatter helper: place `count` copies of ids along a deterministic RNG.
static func scatter(level: Node3D, parent: Node3D, ids: Array, rng: RandomNumberGenerator, count: int,
		min_corner: Vector3, max_corner: Vector3, height: float = 0.0, collide: bool = false) -> int:
	var n := 0
	for i in count:
		var id: String = ids[rng.randi() % ids.size()]
		var p := Vector3(rng.randf_range(min_corner.x, max_corner.x), min_corner.y, rng.randf_range(min_corner.z, max_corner.z))
		if place(level, parent, id, p, rng.randf_range(0.0, 360.0), height, collide) != null:
			n += 1
	return n
