extends RefCounted
## Level 24 living things and weather: Moon Mites (giant, harmless, they keep away
## from people; groups of 6-8 pairs; shallow burrows of cream eggs), Beauford (an
## incomprehensibly large humanoid only ever seen far off, whose approach brings the
## weather), the two weathers as particles, and the PlasticWorks miners.

var lv
var ter
var mites: Array = []          # {node, home, legs, phase, goal}
var beauford: Node3D
var mist: GPUParticles3D
var storm: GPUParticles3D
var fibres: GPUParticles3D
var _rng := RandomNumberGenerator.new()


func _init(level, terrain) -> void:
	lv = level
	ter = terrain
	_rng.seed = 2477


static func materials() -> void:
	MatLib.define("l24_mite", {"albedo_a": Color(0.62, 0.55, 0.42), "albedo_b": Color(0.5, 0.43, 0.32), "pattern": 2, "pattern_scale": Vector2(0.08, 0.08), "pattern_strength": 0.25, "roughness_a": 0.35, "roughness_b": 0.5}, "")
	MatLib.define("l24_mite_leg", {"albedo_a": Color(0.45, 0.38, 0.28), "albedo_b": Color(0.4, 0.33, 0.24), "roughness_a": 0.5}, "")
	MatLib.define("l24_egg", {"albedo_a": Color(0.82, 0.78, 0.66), "albedo_b": Color(0.76, 0.72, 0.6), "roughness_a": 0.25}, "")
	MatLib.define("l24_hivis", {"albedo_a": Color(0.85, 0.36, 0.04), "albedo_b": Color(0.75, 0.3, 0.03), "roughness_a": 0.7, "stain_amount": 0.3, "stain_color": Color(0.3, 0.3, 0.3)}, "")
	MatLib.define("l24_skin", {"albedo_a": Color(0.5, 0.38, 0.3), "albedo_b": Color(0.44, 0.33, 0.26)}, "")
	MatLib.define("l24_helmet", {"albedo_a": Color(0.85, 0.85, 0.82), "albedo_b": Color(0.8, 0.8, 0.77), "roughness_a": 0.3}, "")


func _mesh(parent: Node3D, m: Mesh, mat: String, pos: Vector3, rot := Vector3.ZERO, sc := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = MatLib.get_mat(mat)
	mi.position = pos
	mi.rotation = rot
	mi.scale = sc
	parent.add_child(mi)
	return mi


func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 14
	s.rings = 8
	return s


func _capsule(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.radial_segments = 8
	c.rings = 2
	return c


# ------------------------------------------------------------------ mites

func mite(pos: Vector3) -> Dictionary:
	var n := Node3D.new()
	lv.add_child(n)
	n.position = pos
	var body := Node3D.new()
	n.add_child(body)
	var sc := _rng.randf_range(0.8, 1.25)
	body.scale = Vector3.ONE * sc
	_mesh(body, _sphere(0.5), "l24_mite", Vector3(0, 0.42, 0), Vector3.ZERO, Vector3(0.95, 0.62, 1.35))
	_mesh(body, _sphere(0.16), "l24_mite_leg", Vector3(0, 0.36, -0.68), Vector3.ZERO, Vector3(1.0, 0.7, 1.2))
	for i in 3:
		_mesh(body, _capsule(0.012, 0.5), "l24_mite_leg", Vector3(-0.15 + i * 0.15, 0.55, 0.45), Vector3(-0.9, 0, 0))
	var legs: Array = []
	for s in [-1.0, 1.0]:
		for j in 4:
			var pv := Node3D.new()
			pv.position = Vector3(s * 0.35, 0.35, -0.45 + j * 0.28)
			body.add_child(pv)
			var leg := _mesh(pv, _capsule(0.035, 0.75), "l24_mite_leg", Vector3(s * 0.3, -0.08, 0), Vector3(0, 0, s * 1.15))
			leg.name = "Leg"
			legs.append(pv)
	return {"node": n, "home": pos, "legs": legs, "phase": _rng.randf() * TAU, "goal": pos, "speed": 0.0}


func group(center: Vector3, pairs: int) -> void:
	for i in pairs * 2:
		var a := _rng.randf() * TAU
		var r := _rng.randf_range(1.5, 7.0)
		var p := center + Vector3(cos(a) * r, 0, sin(a) * r)
		p.y = ter.h(p.x, p.z)
		var m := mite(p)
		(m["node"] as Node3D).rotation.y = _rng.randf() * TAU
		mites.append(m)


func burrow(center: Vector3, count: int) -> void:
	var c := center
	c.y = ter.h(c.x, c.z)
	var pit := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.6
	cm.bottom_radius = 1.2
	cm.height = 0.08
	pit.mesh = cm
	pit.material_override = MatLib.get_mat("l24_rubber")
	pit.position = c + Vector3(0, 0.02, 0)
	lv.add_child(pit)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _sphere(0.11)
	mm.instance_count = count
	for i in count:
		var a := _rng.randf() * TAU
		var r := sqrt(_rng.randf()) * 1.1
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(1.0, 0.8, 1.25)), c + Vector3(cos(a) * r, 0.1 + (i % 3) * 0.06, sin(a) * r)))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = MatLib.get_mat("l24_egg")
	lv.add_child(mi)


func update_mites(delta: float, pp: Vector3) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	for m in mites:
		var n: Node3D = m["node"]
		if not is_instance_valid(n):
			continue
		var pos := n.position
		var d := Vector2(pos.x - pp.x, pos.z - pp.z).length()
		if d > 220.0:
			continue
		var goal: Vector3 = m["goal"]
		var speed := 0.6
		if d < 24.0:
			var away := Vector3(pos.x - pp.x, 0, pos.z - pp.z).normalized()
			goal = pos + away * 10.0
			speed = 4.2
		elif pos.distance_to(goal) < 0.8:
			var home: Vector3 = m["home"]
			goal = home + Vector3(_rng.randf_range(-9.0, 9.0), 0, _rng.randf_range(-9.0, 9.0))
		m["goal"] = goal
		m["speed"] = move_toward(m["speed"], speed, delta * 4.0)
		var dir := Vector3(goal.x - pos.x, 0, goal.z - pos.z)
		if dir.length() > 0.05:
			var want := atan2(-dir.x, -dir.z)
			n.rotation.y = lerp_angle(n.rotation.y, want, minf(1.0, delta * 5.0))
			pos += dir.normalized() * float(m["speed"]) * delta
		pos.y = ter.h(pos.x, pos.z)
		n.position = pos
		var k := float(m["speed"]) * 6.0 + 1.0
		var ph: float = m["phase"]
		var legs: Array = m["legs"]
		for i in legs.size():
			(legs[i] as Node3D).rotation.y = sin(t * k + ph + i * 1.7) * 0.35 * minf(1.0, float(m["speed"]))


# ------------------------------------------------------------------ Beauford

func make_beauford() -> void:
	beauford = Node3D.new()
	beauford.name = "Beauford"
	lv.add_child(beauford)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.004, 0.003, 0.003)
	m.disable_fog = true
	var parts := [[Vector3(0, 0.62, 0), 0.16, 0.5, Vector3(1.0, 1.0, 0.6)], [Vector3(0, 0.98, 0), 0.08, 0.16, Vector3(0.85, 1.0, 0.85)],
		[Vector3(-0.08, 0.25, 0), 0.06, 0.5, Vector3.ONE], [Vector3(0.08, 0.25, 0), 0.06, 0.5, Vector3.ONE],
		[Vector3(-0.21, 0.6, 0), 0.04, 0.48, Vector3.ONE], [Vector3(0.21, 0.6, 0), 0.04, 0.48, Vector3.ONE]]
	for p in parts:
		var mi := MeshInstance3D.new()
		var c := CapsuleMesh.new()
		c.radius = p[1]
		c.height = maxf(p[2], p[1] * 2.0)
		mi.mesh = c
		mi.material_override = m
		mi.position = p[0]
		mi.scale = p[3]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.extra_cull_margin = 16384.0
		beauford.add_child(mi)
	beauford.visible = false


## k: 0 = far beyond the horizon, 1 = as close as it comes.
func place_beauford(k: float, around: Vector3) -> void:
	var dir := Vector3(0.55, 0, -0.83).normalized()
	var dist := lerpf(7600.0, 4300.0, k)
	var size := lerpf(2400.0, 3600.0, k)
	beauford.position = Vector3(around.x, 0, around.z) + dir * dist - Vector3(0, size * lerpf(0.55, 0.2, k), 0)
	beauford.scale = Vector3.ONE * size
	beauford.rotation.y = atan2(dir.x, dir.z)
	beauford.rotation.z = sin(Time.get_ticks_msec() * 0.0002) * 0.03


# ------------------------------------------------------------------ weather

func make_weather() -> void:
	mist = _particles(1600, 1.6, Vector3(18, 6, 18), Vector3(0, -1, 0), 7.0, 9.0, Vector2(0.015, 0.4), Color(0.85, 0.85, 0.55, 0.35), true)
	storm = _particles(1400, 3.0, Vector3(30, 7, 30), Vector3(1, 0.05, 0.2), 10.0, 18.0, Vector2(0.35, 0.28), Color(0.55, 0.47, 0.38, 0.6), false)
	fibres = _particles(300, 3.0, Vector3(30, 7, 30), Vector3(1, 0.1, 0.25), 9.0, 15.0, Vector2(1.6, 0.03), Color(0.25, 0.2, 0.15, 0.9), false)


func _particles(amount: int, life: float, box: Vector3, dir: Vector3, v0: float, v1: float, quad: Vector2, col: Color, streak: bool) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	p.emitting = false
	p.local_coords = false
	p.visibility_aabb = AABB(Vector3(-60, -20, -60), Vector3(120, 40, 120))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = box
	pm.direction = dir
	pm.spread = 12.0
	pm.initial_velocity_min = v0
	pm.initial_velocity_max = v1
	pm.gravity = Vector3(0, -2.0, 0) if streak else Vector3(0, -0.3, 0)
	pm.scale_min = 0.4
	pm.scale_max = 1.6
	pm.angular_velocity_min = -90.0 if not streak else 0.0
	pm.angular_velocity_max = 90.0 if not streak else 0.0
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = quad
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if streak else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = col
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y if streak else BaseMaterial3D.BILLBOARD_PARTICLES
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	q.material = m
	p.draw_pass_1 = q
	lv.add_child(p)
	return p


func follow(pp: Vector3) -> void:
	for p in [mist, storm, fibres]:
		if is_instance_valid(p):
			p.global_position = pp + Vector3(0, 3.0, 0) - (Vector3(14, 0, 3) if p != mist else Vector3.ZERO)


# ------------------------------------------------------------------ miners

func miner(pos: Vector3, yaw_deg: float, collide := true) -> Node3D:
	var n := Node3D.new()
	lv.add_child(n)
	n.position = pos
	n.rotation_degrees.y = yaw_deg
	for s in [-1.0, 1.0]:
		_mesh(n, _capsule(0.085, 0.9), "l24_hivis", Vector3(s * 0.11, 0.46, 0))
		_mesh(n, _capsule(0.06, 0.66), "l24_hivis", Vector3(s * 0.27, 1.2, 0.02), Vector3(0, 0, s * 0.1))
	_mesh(n, _capsule(0.2, 0.75), "l24_hivis", Vector3(0, 1.25, 0), Vector3.ZERO, Vector3(1.05, 1.0, 0.72))
	_mesh(n, _sphere(0.115), "l24_skin", Vector3(0, 1.72, 0), Vector3.ZERO, Vector3(0.9, 1.1, 0.95))
	var hat := SphereMesh.new()
	hat.radius = 0.15
	hat.height = 0.15
	hat.is_hemisphere = true
	_mesh(n, hat, "l24_helmet", Vector3(0, 1.79, 0))
	var resp := BoxMesh.new()
	resp.size = Vector3(0.14, 0.1, 0.08)
	_mesh(n, resp, "l24_rubber", Vector3(0, 1.66, -0.11))
	for s in [-1.0, 1.0]:
		var band := BoxMesh.new()
		band.size = Vector3(0.42, 0.04, 0.3)
		_mesh(n, band, "l24_reflector", Vector3(0, 1.0 + s * 0.25, 0))
	if collide:
		var b := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(0.5, 1.8, 0.4)
		cs.shape = sh
		cs.position.y = 0.9
		b.add_child(cs)
		n.add_child(b)
	return n
