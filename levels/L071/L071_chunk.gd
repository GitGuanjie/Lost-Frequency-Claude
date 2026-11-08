extends RefCounted
## Level 71 streamed basement chunk (24 m = 4 x 4 structural bays of 6 m).
## The page gives no description beyond "an infinite basement", so every chunk is
## built only from the fabric a basement is made of: a dusty slab, a low ceiling on
## beams, concrete columns, block partitions with doorways, ducts, pipes, cable trays,
## floor drains, a few caged bulbs (most dead), a sunken bay or a raised plinth, and
## drifts of dust and sand. Some bays "failed to load" (Error 0071): their ceiling
## tiles are missing and the void shows through.

const CS := 24.0
const BAY := 6.0
const H := 2.7                      # floor to ceiling slab soffit
const SHAFT := Rect2(0.7, 1.4, 2.0, 7.2)   # stairwell footprint (x, z, w, d) in chunk (0,0)


static func _in_shaft(cx: int, cz: int, x0: float, z0: float, x1: float, z1: float) -> bool:
	if cx != 0 or cz != 0:
		return false
	var r := Rect2(Vector2(minf(x0, x1), minf(z0, z1)), Vector2(absf(x1 - x0), absf(z1 - z0))).grow(0.4)
	return r.intersects(SHAFT)


static func build(L, cx: int, cz: int, version: int, node: Node3D) -> Dictionary:
	var r := RandomNumberGenerator.new()
	r.seed = hash([L.level_seed, "l71", cx, cz, version])
	var ox := cx * CS
	var oz := cz * CS
	var k := GeoKit.new(node, "Basement")
	var group := "c%d_%d_%d" % [cx, cz, version]
	var meta := {"bulbs": 0, "void_bays": 0, "sunken": 0, "notes": 0}
	var sunken := Vector2i(-1, -1)
	var plinth := Vector2i(-1, -1)
	if r.randf() < 0.45:
		sunken = Vector2i(r.randi_range(1, 2), r.randi_range(1, 2))
	elif r.randf() < 0.5:
		plinth = Vector2i(r.randi_range(0, 3), r.randi_range(0, 3))
	if cx == 0 and cz == 0:
		sunken = Vector2i(2, 1)
		plinth = Vector2i(3, 3)
	# ---- floor and ceiling, bay by bay
	for j in 4:
		for i in 4:
			var x0 := ox + i * BAY
			var z0 := oz + j * BAY
			var bay := Vector2i(i, j)
			if bay == sunken:
				_sunken_bay(L, k, node, r, x0, z0)
				meta["sunken"] = 1
			else:
				k.box_mm(Vector3(x0, -0.3, z0), Vector3(x0 + BAY, 0.0, z0 + BAY), "l71_floor")
			if bay == plinth:
				k.box_mm(Vector3(x0 + 1.2, 0.0, z0 + 1.6), Vector3(x0 + 4.8, 0.42, z0 + 4.4), "l71_concrete", GeoKit.ALL, true, "concrete")
				k.stairs(Vector3(x0 + 3.0, 0.0, z0 + 1.0), Vector3(0, 0, 1), 1.2, 0.42, 2, "l71_concrete", 0.3)
				k.stairs(Vector3(x0 + 3.0, 0.0, z0 + 5.0), Vector3(0, 0, -1), 1.2, 0.42, 2, "l71_concrete", 0.3)
				for b in 4:
					k.box(Vector3(x0 + 2.2 + (b % 2) * 1.6, 0.47, z0 + 2.4 + (b / 2) * 1.2), Vector3(0.05, 0.1, 0.05), "l71_pipe", GeoKit.ALL, false)
			var void_bay: bool = r.randf() < 0.1 and not (cx == 0 and cz == 0)
			if void_bay:
				meta["void_bays"] += 1
				# a ragged hole: only the outer strip of the ceiling remains
				k.box_mm(Vector3(x0, H, z0), Vector3(x0 + BAY, H + 0.25, z0 + 0.9), "l71_ceiling", GeoKit.ALL, false)
				k.box_mm(Vector3(x0, H, z0 + BAY - 1.3), Vector3(x0 + BAY, H + 0.25, z0 + BAY), "l71_ceiling", GeoKit.ALL, false)
			elif cx == 0 and cz == 0 and i == 0 and j <= 1:
				# round the stairwell
				k.box_mm(Vector3(x0, H, z0), Vector3(SHAFT.position.x, H + 0.25, z0 + BAY), "l71_ceiling", GeoKit.ALL, false)
				k.box_mm(Vector3(SHAFT.end.x, H, z0), Vector3(x0 + BAY, H + 0.25, z0 + BAY), "l71_ceiling", GeoKit.ALL, false)
				if j == 0:
					k.box_mm(Vector3(SHAFT.position.x, H, z0), Vector3(SHAFT.end.x, H + 0.25, SHAFT.position.y), "l71_ceiling", GeoKit.ALL, false)
				else:
					k.box_mm(Vector3(SHAFT.position.x, H, SHAFT.end.y), Vector3(SHAFT.end.x, H + 0.25, z0 + BAY), "l71_ceiling", GeoKit.ALL, false)
			else:
				k.box_mm(Vector3(x0, H, z0), Vector3(x0 + BAY, H + 0.25, z0 + BAY), "l71_ceiling", GeoKit.ALL, false)
			# dust and sand drifts
			for d in r.randi_range(0, 3):
				_drift(L, node, Vector3(x0 + (r.randf_range(0.3, 0.9) if r.randf() < 0.5 else r.randf_range(5.1, 5.7)), 0.0 if bay != sunken else -0.9, z0 + r.randf_range(0.5, 5.5)), r)
	# ---- beams (along x on every bay line) and columns
	for j in 4:
		var z := oz + j * BAY
		if not _in_shaft(cx, cz, 0.0, z - oz - 0.2, CS, z - oz + 0.2):
			k.box_mm(Vector3(ox, H - 0.42, z - 0.18), Vector3(ox + CS, H, z + 0.18), "l71_concrete", GeoKit.ALL, false)
		else:
			k.box_mm(Vector3(ox + SHAFT.end.x + 0.4, H - 0.42, z - 0.18), Vector3(ox + CS, H, z + 0.18), "l71_concrete", GeoKit.ALL, false)
	for j in 4:
		for i in 4:
			var cpos := Vector3(ox + i * BAY, 0, oz + j * BAY)
			if r.randf() < 0.12 and not (i == 0 and j == 0):
				continue
			k.box(cpos + Vector3(0, H * 0.5, 0), Vector3(0.46, H, 0.46), "l71_concrete")
			if r.randf() < 0.18:
				var side: Vector3 = [Vector3(0.24, 0, 0), Vector3(-0.24, 0, 0), Vector3(0, 0, 0.24), Vector3(0, 0, -0.24)][r.randi() % 4]
				Props.place(L, node, ["ph/power_box_01", "ph/utility_box_01", "ph/fire_alarm"][r.randi() % 3], cpos + side * 1.35 + Vector3(0, 1.1 if r.randf() < 0.6 else 0.0, 0), rad_to_deg(atan2(side.x, side.z)))
	# ---- block partitions along bay lines, mostly with a doorway
	for j in 4:
		for i in 4:
			for axis in 2:
				if r.randf() > 0.2:
					continue
				var a := Vector3(ox + i * BAY, 0, oz + j * BAY)
				var b := a + (Vector3(BAY, 0, 0) if axis == 0 else Vector3(0, 0, BAY))
				if _in_shaft(cx, cz, a.x - ox, a.z - oz, b.x - ox, b.z - oz):
					continue
				if cx == 0 and cz == 0 and (Vector2i(i, j) == sunken or Vector2i(i, j) == plinth or (i <= 1 and j <= 1)):
					continue
				var ops: Array = []
				if r.randf() < 0.75:
					ops.append({"at": r.randf_range(1.4, BAY - 1.4), "w": 1.0, "h": 2.1, "sill": 0.0})
				k.wall(a, b, H - 0.42, 0.2, "l71_block", ops)
	# ---- services: ducts on hangers, a pipe run, cable trays
	var dz := oz + BAY * r.randi_range(1, 3) + 2.0
	if r.randf() < 0.7 and not _in_shaft(cx, cz, 0, dz - oz - 0.5, CS, dz - oz + 0.5):
		k.box_mm(Vector3(ox, H - 1.0, dz - 0.45), Vector3(ox + CS, H - 0.55, dz + 0.45), "l71_duct", GeoKit.ALL, false)
		for s in 4:
			k.box(Vector3(ox + 3.0 + s * BAY, H - 0.28, dz), Vector3(0.05, 0.55, 1.0), "metal", GeoKit.ALL, false)
	var px := ox + BAY * r.randi_range(0, 3) + 1.2
	if not _in_shaft(cx, cz, px - ox - 0.6, 0, px - ox + 0.6, CS):
		for t in 3:
			_pipe(node, Vector3(px + t * 0.2, H - 0.62 - t * 0.12, oz), Vector3(px + t * 0.2, H - 0.62 - t * 0.12, oz + CS), 0.05 + 0.025 * t)
		for s in 4:
			k.box(Vector3(px + 0.2, H - 0.3, oz + 3.0 + s * BAY), Vector3(0.7, 0.04, 0.05), "metal", GeoKit.ALL, false)
	# ---- bulbs: caged, most dead
	for j in 4:
		for i in 4:
			if r.randf() > 0.32:
				continue
			var bp := Vector3(ox + i * BAY + 3.0, H - 0.05, oz + j * BAY + 3.0)
			# a bare cord and a wire-caged bulb holder (built, not modelled: hundreds of these)
			k.box(bp - Vector3(0, 0.25, 0), Vector3(0.012, 0.5, 0.012), "l71_pipe", GeoKit.ALL, false)
			k.box(bp - Vector3(0, 0.52, 0), Vector3(0.07, 0.06, 0.07), "l71_pipe", GeoKit.ALL, false)
			for c in 4:
				var a := TAU * c / 4.0 + 0.4
				k.box(bp - Vector3(-cos(a) * 0.07, 0.62, -sin(a) * 0.07), Vector3(0.012, 0.16, 0.012), "metal", GeoKit.ALL, false)
			var lit: bool = r.randf() < 0.3 or (cx == 0 and cz == 0 and i == 0 and j == 0)
			if lit:
				meta["bulbs"] += 1
				var bulb := MeshInstance3D.new()
				var sm := SphereMesh.new()
				sm.radius = 0.06
				sm.height = 0.12
				bulb.mesh = sm
				bulb.material_override = MatLib.get_mat("l71_bulb")
				bulb.position = bp - Vector3(0, 0.55, 0)
				node.add_child(bulb)
				L.lights.add_anchor(bp - Vector3(0, 0.7, 0), Color(1.0, 0.78, 0.5), r.randf_range(0.7, 1.2), 7.5, r.randf_range(0.05, 0.4), group)
	# ---- floor drains and a scrap of paper now and then
	if r.randf() < 0.5:
		var dp := Vector3(ox + r.randi_range(0, 3) * BAY + 3.0, 0.0, oz + r.randi_range(0, 3) * BAY + 1.5)
		if not _in_shaft(cx, cz, dp.x - ox - 0.5, dp.z - oz - 0.5, dp.x - ox + 0.5, dp.z - oz + 0.5):
			Props.place(L, node, "ph/water_manhole_cover", dp - Vector3(0, 0.05, 0), 0.0, 0.05)
	if r.randf() < 0.22 and not (cx == 0 and cz == 0):
		meta["notes"] = 1
		L.scrap(node, Vector3(ox + r.randi_range(0, 3) * BAY + r.randf_range(1.0, 2.0), 0.02, oz + r.randi_range(0, 3) * BAY + r.randf_range(3.5, 4.5)), r.randi())
	k.commit()
	meta["group"] = group
	return meta


static func _sunken_bay(_L, k: GeoKit, _node: Node3D, _r: RandomNumberGenerator, x0: float, z0: float) -> void:
	var d := 0.9
	k.box_mm(Vector3(x0, -d - 0.3, z0), Vector3(x0 + BAY, -d, z0 + BAY), "l71_floor")
	# retaining kerbs on three sides, stairs down on the fourth
	k.box_mm(Vector3(x0, -d, z0 - 0.0), Vector3(x0 + BAY, 0.0, z0 + 0.25), "l71_concrete")
	k.box_mm(Vector3(x0, -d, z0 + BAY - 0.25), Vector3(x0 + BAY, 0.0, z0 + BAY), "l71_concrete")
	k.box_mm(Vector3(x0 + BAY - 0.25, -d, z0 + 0.25), Vector3(x0 + BAY, 0.0, z0 + BAY - 0.25), "l71_concrete")
	k.box_mm(Vector3(x0, -d, z0 + 0.25), Vector3(x0 + 0.25, 0.0, z0 + 1.6), "l71_concrete")
	k.box_mm(Vector3(x0, -d, z0 + 4.4), Vector3(x0 + 0.25, 0.0, z0 + BAY - 0.25), "l71_concrete")
	# five risers of 0.18 m down from the west edge
	k.stairs(Vector3(x0 + 0.25 + 0.3 * 5, -d, z0 + 3.0), Vector3(-1, 0, 0), 2.8, d, 5, "l71_concrete", 0.3)
	# a pipe rail round the drop
	for e in [[Vector3(x0 + 0.3, 0.0, z0 + 0.15), Vector3(x0 + BAY - 0.15, 0.0, z0 + 0.15)], [Vector3(x0 + 0.3, 0.0, z0 + BAY - 0.15), Vector3(x0 + BAY - 0.15, 0.0, z0 + BAY - 0.15)]]:
		var a: Vector3 = e[0]
		var b: Vector3 = e[1]
		k.box_mm(Vector3(a.x, 0.98, a.z - 0.025), Vector3(b.x, 1.03, b.z + 0.025), "l71_pipe", GeoKit.ALL, false)
		for s in 4:
			var p := a.lerp(b, s / 3.0)
			k.box(p + Vector3(0, 0.5, 0), Vector3(0.05, 1.0, 0.05), "l71_pipe", GeoKit.ALL, false)
	k.box_mm(Vector3(x0 + BAY - 0.15 - 0.025, 0.98, z0 + 0.15), Vector3(x0 + BAY - 0.15 + 0.025, 1.03, z0 + BAY - 0.15), "l71_pipe", GeoKit.ALL, false)


static func _pipe(node: Node3D, a: Vector3, b: Vector3, rad: float) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = rad
	cm.bottom_radius = rad
	cm.height = a.distance_to(b)
	cm.radial_segments = 8
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = MatLib.get_mat("l71_pipe")
	node.add_child(mi)
	mi.position = (a + b) * 0.5
	mi.basis = Basis(Vector3.RIGHT, PI * 0.5) if absf(b.z - a.z) > absf(b.x - a.x) else Basis(Vector3.BACK, PI * 0.5)


static func _drift(L, node: Node3D, p: Vector3, r: RandomNumberGenerator) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 12
	sm.rings = 6
	mi.mesh = sm
	mi.material_override = MatLib.get_mat("l71_sand")
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = p
	mi.scale = Vector3(r.randf_range(0.3, 0.6), r.randf_range(0.12, 0.26), r.randf_range(0.25, 0.5))
	mi.position.y -= mi.scale.y * 0.35
	mi.rotation.y = r.randf() * TAU
	node.add_child(mi)
