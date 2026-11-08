extends RefCounted
## Level 899 presences, all non-hostile: Karl the caretaker (a human-shaped,
## gargoyle-like figure with folded wings, per the diary), residents who have
## stayed (aged; sitting, lying in the grass under the aurora) and staff as the
## brochure describes them (extra arms and eyes). Built from primitives.


static func materials() -> void:
	MatLib.define("l899_karl", {"albedo_a": Color(0.2, 0.2, 0.21), "albedo_b": Color(0.14, 0.14, 0.15), "noise_scale": 3.0, "bump_strength": 1.2, "roughness_a": 0.8}, "")
	MatLib.define("l899_wing", {"albedo_a": Color(0.11, 0.1, 0.11), "albedo_b": Color(0.08, 0.07, 0.08), "pattern": 2, "pattern_scale": Vector2(0.15, 0.15), "pattern_strength": 0.3}, "")
	MatLib.define("l899_skin", {"albedo_a": Color(0.52, 0.4, 0.33), "albedo_b": Color(0.45, 0.34, 0.28)}, "")
	MatLib.define("l899_skin_old", {"albedo_a": Color(0.5, 0.42, 0.38), "albedo_b": Color(0.44, 0.37, 0.33), "noise_scale": 6.0}, "")
	MatLib.define("l899_hair_grey", {"albedo_a": Color(0.55, 0.55, 0.53), "albedo_b": Color(0.45, 0.45, 0.44)}, "")
	MatLib.define("l899_staff", {"albedo_a": Color(0.36, 0.33, 0.27), "albedo_b": Color(0.3, 0.27, 0.22)}, "")
	MatLib.define("l899_apron", {"albedo_a": Color(0.55, 0.53, 0.48), "albedo_b": Color(0.5, 0.48, 0.43)}, "")
	MatLib.define("l899_staff_skin", {"albedo_a": Color(0.3, 0.33, 0.36), "albedo_b": Color(0.25, 0.28, 0.31)}, "")
	MatLib.define("l899_eye", {"albedo_a": Color(0.9, 0.85, 0.5), "albedo_b": Color(0.9, 0.85, 0.5), "emission_color": Color(0.9, 0.8, 0.4), "emission_energy": 0.6}, "")
	var cloth := [Color(0.25, 0.18, 0.14), Color(0.16, 0.2, 0.26), Color(0.32, 0.3, 0.22), Color(0.22, 0.12, 0.14), Color(0.18, 0.24, 0.18)]
	for i in cloth.size():
		MatLib.define("l899_cloth%d" % i, {"albedo_a": cloth[i], "albedo_b": cloth[i] * 0.85, "noise_scale": 4.0}, "")


static func _cap(parent: Node3D, r: float, h: float, mat: String, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = r
	cm.height = maxf(h, r * 2.0)
	cm.radial_segments = 12
	cm.rings = 4
	mi.mesh = cm
	mi.material_override = MatLib.get_mat(mat)
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi


static func _sph(parent: Node3D, r: float, mat: String, pos: Vector3, sc := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	sm.radial_segments = 12
	sm.rings = 6
	mi.mesh = sm
	mi.material_override = MatLib.get_mat(mat)
	mi.position = pos
	mi.scale = sc
	parent.add_child(mi)
	return mi


## pose: "stand", "sit" (on a 0.45 m seat), "lie" (on the back, face up).
static func person(kind: String, pose: String, cloth: int) -> Node3D:
	var root := Node3D.new()
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var cm := "l899_cloth%d" % cloth
	var skin := "l899_skin_old" if kind == "resident" else ("l899_karl" if kind == "karl" else ("l899_staff_skin" if kind == "staff" else "l899_skin"))
	var tall := 1.0
	if kind == "staff":
		tall = 1.12
		cm = "l899_staff"
	elif kind == "karl":
		cm = "l899_karl"
	var hip := 0.95 * tall
	# legs
	for s in [-1.0, 1.0]:
		if pose == "sit":
			_cap(body, 0.075, 0.5, cm, Vector3(s * 0.11, 0.48, 0.22), Vector3(PI * 0.5, 0, 0))
			_cap(body, 0.065, 0.5, cm, Vector3(s * 0.11, 0.24, 0.45))
		else:
			_cap(body, 0.08, 0.92 * tall, cm, Vector3(s * 0.11, hip * 0.5, 0))
	var ty := (0.48 if pose == "sit" else hip) + 0.33 * tall
	var torso := _cap(body, 0.19, 0.72 * tall, cm, Vector3(0, ty, 0))
	torso.scale = Vector3(1.05, 1.0, 0.72)
	if kind == "resident":
		torso.rotation.x = 0.18
	if kind == "staff":
		_cap(body, 0.17, 0.6, "l899_apron", Vector3(0, ty - 0.15, 0.08)).scale = Vector3(1.0, 1.0, 0.4)
	var arms := 4 if kind == "staff" else 2
	for a in arms:
		var s := -1.0 if a % 2 == 0 else 1.0
		var low := a >= 2
		var arm := _cap(body, 0.055, 0.62 * tall, skin if kind == "karl" else cm, Vector3(s * (0.26 if not low else 0.23), ty - (0.02 if not low else 0.2), 0.05 if not low else 0.12), Vector3(-0.5 if low else -0.15, 0, s * (0.12 if not low else 0.3)))
		if pose == "lie":
			arm.rotation.z = s * 0.5
	var hy := ty + 0.5 * tall
	var head := _sph(body, 0.12, skin, Vector3(0, hy, 0.02), Vector3(0.9, 1.1, 0.95))
	head.name = "Head"
	if kind == "resident":
		_sph(body, 0.125, "l899_hair_grey", Vector3(0, hy + 0.04, -0.02), Vector3(0.95, 0.8, 0.95))
	elif kind == "staff":
		for e in 4:
			_sph(body, 0.017, "l899_eye", Vector3(-0.07 + e * 0.047, hy + 0.04 + (0.03 if e in [0, 3] else 0.0), 0.12))
		_sph(body, 0.11, "l899_apron", Vector3(0, hy + 0.08, -0.01), Vector3(1.0, 0.6, 1.0))
	elif kind == "karl":
		# small horns, a heavy brow and folded wings behind the shoulders
		for s in [-1.0, 1.0]:
			_cap(body, 0.025, 0.12, "l899_karl", Vector3(s * 0.07, hy + 0.13, -0.02), Vector3(-0.4, 0, -s * 0.4))
			var wing := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.05, 1.25, 0.55)
			wing.mesh = bm
			wing.material_override = MatLib.get_mat("l899_wing")
			wing.position = Vector3(s * 0.2, ty + 0.18, -0.24)
			wing.rotation = Vector3(0.12, s * 0.35, s * 0.1)
			body.add_child(wing)
			var tip := _cap(body, 0.03, 0.5, "l899_wing", Vector3(s * 0.26, ty + 0.85, -0.3), Vector3(0.3, 0, -s * 0.3))
			tip.name = "WingTip"
		_sph(body, 0.11, "l899_karl", Vector3(0, hy + 0.055, 0.035), Vector3(1.0, 0.45, 0.9))
	if pose == "lie":
		body.rotation.x = -PI * 0.5
		body.position = Vector3(0, 0.12, hip * 0.9)
	return root
