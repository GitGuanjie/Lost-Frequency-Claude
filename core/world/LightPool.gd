class_name LightPool
extends Node3D
## Many authored light fixtures, few real lights: a fixed pool of OmniLight3D /
## SpotLight3D nodes is reassigned to the fixtures nearest the camera. Emissive
## panels carry the look at distance; real lights give local pools and shadows.

var anchors: Array = []      # {pos, color, energy, range, flicker, spot}
var pool: Array = []
var pool_size := 10
var shadow_count := 1
var refresh := 0.2
var _t := 0.0
var _assign: Array = []      # pool index -> anchor index
var _rng := RandomNumberGenerator.new()
var max_distance := 40.0
var attenuation := 1.4


func setup(size: int, shadows: int = 1) -> void:
	pool_size = size
	shadow_count = shadows
	for i in pool_size:
		var l := OmniLight3D.new()
		l.name = "Pool%02d" % i
		l.visible = false
		l.shadow_enabled = i < shadow_count
		l.omni_attenuation = attenuation
		l.light_specular = 0.35
		add_child(l)
		pool.append(l)
		_assign.append(-1)


func add_anchor(pos: Vector3, color: Color, energy: float, light_range: float, flicker: float = 0.0, group: String = "") -> int:
	anchors.append({"pos": pos, "color": color, "energy": energy, "range": light_range, "flicker": flicker, "group": group})
	return anchors.size() - 1


## Remove all anchors of a group (e.g. an unloaded chunk) and re-pool.
func remove_group(group: String) -> void:
	var keep: Array = []
	for a in anchors:
		if a.get("group", "") != group:
			keep.append(a)
	if keep.size() == anchors.size():
		return
	anchors = keep
	for i in pool.size():
		_assign[i] = -1
		pool[i].visible = false
	_t = 0.0


func clear_anchors() -> void:
	anchors.clear()
	for i in pool.size():
		_assign[i] = -1
		pool[i].visible = false


func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null or pool.is_empty():
		return
	_t -= delta
	if _t <= 0.0:
		_t = refresh
		_reassign(cam.global_position)
	var now := Time.get_ticks_msec() / 1000.0
	for i in pool.size():
		var ai: int = _assign[i]
		if ai < 0:
			continue
		var a: Dictionary = anchors[ai]
		var l: OmniLight3D = pool[i]
		var target: float = a["energy"]
		if a["flicker"] > 0.0:
			var n := sin(now * 31.0 + ai * 1.7) * sin(now * 7.3 + ai)
			if n > 1.0 - a["flicker"] * 0.6:
				target *= 0.15
		l.light_energy = lerpf(l.light_energy, target, minf(1.0, delta * 10.0))


func _reassign(cam_pos: Vector3) -> void:
	var best: Array = []
	var md2 := max_distance * max_distance
	for i in anchors.size():
		var d2: float = cam_pos.distance_squared_to(anchors[i]["pos"])
		if d2 < md2:
			best.append([d2, i])
	best.sort_custom(func(x, y): return x[0] < y[0])
	var wanted := {}
	for k in mini(pool.size(), best.size()):
		wanted[best[k][1]] = true
	# keep lights already on wanted anchors (no popping)
	var free_slots: Array = []
	for i in pool.size():
		var ai: int = _assign[i]
		if ai >= 0 and wanted.has(ai):
			wanted.erase(ai)
		else:
			free_slots.append(i)
	var remaining := wanted.keys()
	for i in free_slots:
		var l: OmniLight3D = pool[i]
		if remaining.is_empty():
			l.visible = false
			_assign[i] = -1
			continue
		var ai: int = remaining.pop_back()
		var a: Dictionary = anchors[ai]
		_assign[i] = ai
		l.global_position = a["pos"]
		l.light_color = a["color"]
		l.omni_range = a["range"]
		l.light_energy = 0.0
		l.visible = true
