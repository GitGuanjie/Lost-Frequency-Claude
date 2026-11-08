extends RefCounted
## Level 11.3 figures: the faceless Servant silhouette (also used, pale and
## warmly lit, for the hallucinated "human") and the Ambassador cube.


static func humanoid(level: Node3D, mat: Material) -> Node3D:
	var n := Node3D.new()
	var parts := [[CapsuleMesh.new(), Vector3(0, 0.98, 0), Vector3(0.24, 1.5, 0)], [SphereMesh.new(), Vector3(0, 1.86, 0.02), Vector3(0.13, 0.27, 0)],
		[CapsuleMesh.new(), Vector3(-0.33, 1.08, 0), Vector3(0.06, 0.95, 0)], [CapsuleMesh.new(), Vector3(0.33, 1.08, 0), Vector3(0.06, 0.95, 0)]]
	for pp in parts:
		var mi := MeshInstance3D.new()
		var m: PrimitiveMesh = pp[0]
		var dims: Vector3 = pp[2]
		if m is CapsuleMesh:
			(m as CapsuleMesh).radius = dims.x
			(m as CapsuleMesh).height = dims.y
		else:
			(m as SphereMesh).radius = dims.x
			(m as SphereMesh).height = dims.y
		mi.mesh = m
		mi.material_override = mat
		mi.position = pp[1]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(mi)
	level.add_child(n)
	return n



static func cube() -> Node3D:
	var n := Node3D.new()
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.1, 1.1, 1.1)
	mi.mesh = bm
	mi.material_override = MatLib.standard(Color(0.02, 0.018, 0.02), 0.2, 0.8)
	n.add_child(mi)
	var em := MatLib.get_mat("l113_win_red")
	for ax in 3:
		for sa in [-1.0, 1.0]:
			for sb in [-1.0, 1.0]:
				var e := MeshInstance3D.new()
				var eb := BoxMesh.new()
				var sz := Vector3(0.05, 0.05, 0.05)
				sz[ax] = 1.14
				eb.size = sz
				e.mesh = eb
				e.material_override = em
				var p := Vector3(sa * 0.55, sb * 0.55, 0)
				if ax == 0:
					p = Vector3(0, sa * 0.55, sb * 0.55)
				elif ax == 1:
					p = Vector3(sa * 0.55, 0, sb * 0.55)
				e.position = p
				n.add_child(e)
	return n


## The icy drizzle (thin vertical streaks that follow the player).
static func rain() -> CPUParticles3D:
	var rain := CPUParticles3D.new()
	rain.name = "Drizzle"
	rain.amount = 1000
	rain.lifetime = 1.2
	rain.preprocess = 1.2
	rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	rain.emission_box_extents = Vector3(16, 0.5, 16)
	rain.direction = Vector3(0.08, -1, 0.04)
	rain.spread = 3.0
	rain.gravity = Vector3(0, -9.0, 0)
	rain.initial_velocity_min = 11.0
	rain.initial_velocity_max = 15.0
	rain.local_coords = false
	var qm := QuadMesh.new()
	qm.size = Vector2(0.006, 0.34)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.7, 0.45, 0.42, 0.16)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	qm.material = m
	rain.mesh = qm
	return rain
