extends RefCounted
## Level 16 world content for both states and the morph between them:
## vegetation cells (sink into the ground / rise again as the front passes),
## glacier spires (jut up / sink), the river (water / ice), boulders that
## gush water while the land changes, the exit objects, the warning orbs and
## the Light Guides (arctic state only).

const F := preload("res://levels/L016/L016_flora.gd")
const CELL := 40.0

var lvl
var land
var cells: Array = []        # {node, body, center: Vector3, state_a: bool}
var spires: Array = []       # {node, pos, r, up: bool}
var boulders: Array = []     # Vector3
var jets: Array = []         # MeshInstance3D
var guides: Node3D
var orbs: Node3D
var water: MeshInstance3D
var ice_river: Node3D
var leaf_mat: ShaderMaterial
var ice_mat: ShaderMaterial
var dot_mat: ShaderMaterial
var jet_water: Material
var spots: Array = []        # exit spots (Vector3), seeded


func _init(level, land_model) -> void:
	lvl = level
	land = land_model
	leaf_mat = F.shader_mat(F.LEAF)
	ice_mat = F.shader_mat(F.ICE)
	dot_mat = F.shader_mat(F.GLOWDOT)


func ok_ground(x: float, z: float, clear: Array, r: float) -> bool:
	if Vector2(x, z).length() > 128.0:
		return false
	if land.river_d(x, z) < 6.0 or land.slope(x, z) > 0.55:
		return false
	for c in clear:
		if Vector2(x - c.x, z - c.z).length() < r:
			return false
	return true


## Exit spots: the first near the arrival, the rest anywhere in the valley.
func plan_spots(rng: RandomNumberGenerator) -> void:
	spots.clear()
	var tries := 0
	while spots.size() < 1 and tries < 200:
		tries += 1
		var a := rng.randf_range(0, TAU)
		var r := rng.randf_range(30.0, 40.0)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if ok_ground(p.x, p.z, [Vector3(land.MESA.x, 0, land.MESA.y)], 18.0) and land.h(p.x, p.z) < 3.0 and _straight(p):
			spots.append(Vector3(p.x, land.h(p.x, p.z), p.z))
	if spots.is_empty():
		spots.append(Vector3(-32.0, land.h(-32.0, -6.0), -6.0))
	while spots.size() < 6 and tries < 800:
		tries += 1
		var p := Vector3(rng.randf_range(-115, 115), 0, rng.randf_range(-115, 115))
		if ok_ground(p.x, p.z, spots + [Vector3(land.MESA.x, 0, land.MESA.y)], 30.0):
			spots.append(Vector3(p.x, land.h(p.x, p.z), p.z))


## The route from the arrival to a spot stays on dry, walkable ground.
func _straight(p: Vector3) -> bool:
	for i in 20:
		var q := Vector3.ZERO.lerp(p, i / 20.0)
		if land.river_d(q.x, q.z) < 7.0 or land.slope(q.x, q.z) > 0.45:
			return false
	return true


# ------------------------------------------------------------ rainforest

func build_forest(parent: Node3D, rng: RandomNumberGenerator, clear: Array) -> void:
	var meshes := [F.tree_mesh(0), F.tree_mesh(1), F.tree_mesh(2), F.tree_mesh(3), F.palm_mesh(0), F.palm_mesh(1), F.fern_mesh(0), F.fern_mesh(1)]
	var n := int(ceil(260.0 / CELL))
	for cz in n:
		for cx in n:
			var ox := -130.0 + cx * CELL
			var oz := -130.0 + cz * CELL
			var center := Vector3(ox + CELL * 0.5, 0, oz + CELL * 0.5)
			if Vector2(center.x, center.z).length() > 150.0:
				continue
			var node := Node3D.new()
			node.name = "Forest_%d_%d" % [cx, cz]
			parent.add_child(node)
			var body := StaticBody3D.new()
			body.name = "Trunks"
			node.add_child(body)
			var xfs: Array = [[], [], [], [], [], [], [], []]
			for i in 34:
				var x := ox + rng.randf_range(0, CELL)
				var z := oz + rng.randf_range(0, CELL)
				var kind := rng.randi_range(0, 9)
				var big := kind <= 3
				if not ok_ground(x, z, clear, 9.0 if big else 4.0):
					continue
				if Vector2(x - land.MESA.x, z - land.MESA.y).length() < 13.0 and big:
					continue
				var y: float = land.h(x, z)
				var mi := 0
				if kind <= 1:
					mi = kind
				elif kind <= 3:
					mi = kind
				elif kind <= 5:
					mi = 4 + (kind - 4)
				else:
					mi = 6 + (kind % 2)
				var s := rng.randf_range(0.85, 1.2)
				xfs[mi].append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * s), Vector3(x, y, z)))
				if big:
					var cs := CollisionShape3D.new()
					var cy := CylinderShape3D.new()
					cy.radius = (0.75 if mi < 2 else 0.42) * s
					cy.height = 8.0
					cs.shape = cy
					cs.position = Vector3(x, y + 4.0, z)
					cs.set_meta("surface", "wood")
					body.add_child(cs)
			# extra understory: ferns along the cell
			for i in 46:
				var x := ox + rng.randf_range(0, CELL)
				var z := oz + rng.randf_range(0, CELL)
				if land.river_d(x, z) < 3.5 or land.slope(x, z) > 0.8 or Vector2(x, z).length() > 132.0 or Vector2(x, z).length() < 3.0:
					continue
				var s2 := rng.randf_range(0.7, 1.4)
				xfs[6 + (i % 2)].append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * s2), Vector3(x, land.h(x, z), z)))
			for mi in 8:
				if xfs[mi].is_empty():
					continue
				var mm := F.multimesh(meshes[mi], xfs[mi], leaf_mat, mi < 6, 200.0 if mi < 4 else (120.0 if mi < 6 else 70.0))
				node.add_child(mm)
			cells.append({"node": node, "body": body, "center": center})


# ------------------------------------------------------------ arctic

func build_spires(parent: Node3D, rng: RandomNumberGenerator, clear: Array) -> void:
	var tries := 0
	while spires.size() < 26 and tries < 600:
		tries += 1
		var p := Vector3(rng.randf_range(-120, 120), 0, rng.randf_range(-120, 120))
		if not ok_ground(p.x, p.z, clear, 14.0):
			continue
		var far := true
		for s in spires:
			if (s["pos"] as Vector3).distance_to(p) < 12.0:
				far = false
		if not far:
			continue
		p.y = land.h(p.x, p.z)
		var node := Node3D.new()
		node.name = "Glacier"
		parent.add_child(node)
		var mi := MeshInstance3D.new()
		mi.mesh = F.spire_mesh(rng.randi())
		mi.material_override = ice_mat
		node.add_child(mi)
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = Vector3(3.2, 10.0, 3.2)
		cs.shape = bx
		cs.position = Vector3(0, 5.0, 0)
		cs.set_meta("surface", "snow")
		body.add_child(cs)
		node.add_child(body)
		node.position = p
		node.rotation.y = rng.randf() * TAU
		spires.append({"node": node, "pos": p, "r": 3.2, "up": true})
	# Light Guides: groups of small lights (the page names them only)
	guides = Node3D.new()
	guides.name = "LightGuides"
	parent.add_child(guides)
	var q := F.dot_mesh(0.35)
	for g in 5:
		var a := rng.randf_range(0, TAU)
		var r := rng.randf_range(35.0, 95.0)
		var c := Vector3(cos(a) * r, 0, sin(a) * r)
		c.y = land.h(c.x, c.z) + rng.randf_range(2.0, 4.5)
		for i in 14:
			var mi := MeshInstance3D.new()
			mi.mesh = q
			var m := dot_mat.duplicate() as ShaderMaterial
			m.set_shader_parameter("col", Vector3(0.85, 0.95, 1.0))
			m.set_shader_parameter("energy", rng.randf_range(1.5, 3.0))
			mi.material_override = m
			mi.position = c + Vector3(rng.randf_range(-4, 4), rng.randf_range(-1.2, 1.5), rng.randf_range(-4, 4))
			mi.set_meta("base", mi.position)
			mi.set_meta("ph", rng.randf() * TAU)
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			guides.add_child(mi)
	orbs = Node3D.new()
	orbs.name = "WarningOrbs"
	parent.add_child(orbs)
	for i in 14:
		var mi := MeshInstance3D.new()
		mi.mesh = F.dot_mesh(0.22)
		var m := dot_mat.duplicate() as ShaderMaterial
		m.set_shader_parameter("col", Vector3(0.75, 0.9, 1.0))
		m.set_shader_parameter("energy", 3.5)
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		orbs.add_child(mi)
	orbs.visible = false


# ------------------------------------------------------------ river and boulders

func build_river(parent: Node3D, k: GeoKit, rng: RandomNumberGenerator) -> void:
	MatLib.register("l16_river", MatLib.water({"shallow_color": Color(0.16, 0.22, 0.17), "deep_color": Color(0.05, 0.08, 0.06),
		"absorption": 1.6, "clarity": 0.3, "wave_height": 0.02, "wave_scale": 0.6, "wave_speed": 0.5, "foam_amount": 0.2}))
	jet_water = MatLib.get_mat("l16_river")
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var wy: float = land.water_y()
	var x := -150.0
	while x < 150.0:
		var z0: float = land.river_z(x)
		var z1: float = land.river_z(x + 4.0)
		var w := 6.5
		for v in [Vector3(x, wy, z0 - w), Vector3(x + 4.0, wy, z1 - w), Vector3(x + 4.0, wy, z1 + w), Vector3(x, wy, z0 - w), Vector3(x + 4.0, wy, z1 + w), Vector3(x, wy, z0 + w)]:
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(v.x, v.z) * 0.2)
			st.add_vertex(v)
		x += 4.0
	water = MeshInstance3D.new()
	water.name = "River"
	water.mesh = st.commit()
	water.material_override = jet_water
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(water)
	# ice over the river (arctic) with collision, built as its own node
	ice_river = Node3D.new()
	ice_river.name = "FrozenRiver"
	parent.add_child(ice_river)
	var imi := MeshInstance3D.new()
	imi.mesh = water.mesh
	imi.material_override = ice_mat
	imi.position.y = 0.05
	ice_river.add_child(imi)
	var ib := StaticBody3D.new()
	ice_river.add_child(ib)
	x = -140.0
	while x < 140.0:
		var zc: float = land.river_z(x + 5.0)
		var cs := CollisionShape3D.new()
		var bx := BoxShape3D.new()
		bx.size = Vector3(10.4, 0.3, 12.0)
		cs.shape = bx
		cs.position = Vector3(x + 5.0, wy - 0.1, zc)
		cs.rotation.y = -atan2(land.river_z(x + 10.0) - land.river_z(x), 10.0)
		cs.set_meta("surface", "snow")
		ib.add_child(cs)
		x += 10.0
	# boulders on the banks; a few will gush water while the land changes
	for i in 22:
		var bx2 := rng.randf_range(-120, 120)
		var side := -1.0 if rng.randf() < 0.5 else 1.0
		var bz: float = land.river_z(bx2) + side * rng.randf_range(7.0, 14.0)
		if Vector2(bx2, bz).length() > 125.0 or Vector2(bx2, bz).length() < 12.0:
			continue
		var s := rng.randf_range(1.2, 3.2)
		var by: float = land.h(bx2, bz)
		Props.place(lvl, parent, "ph/boulder_01", Vector3(bx2, by - s * 0.3, bz), rng.randf_range(0, 360), s, false)
		k.box(Vector3(bx2, by + s * 0.25, bz), Vector3(s * 1.1, s * 0.7, s * 1.1), "l16_rock", 0, true, "stone")
		if boulders.size() < 6:
			boulders.append(Vector3(bx2, by + s * 0.55, bz))


## Water bursting out of the boulders towards the river.
func make_jets(parent: Node3D) -> void:
	for b in boulders:
		var mi := MeshInstance3D.new()
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var to := Vector3(b.x, land.water_y(), land.river_z(b.x))
		var seg := 10
		var prev_l := Vector3.ZERO
		var prev_r := Vector3.ZERO
		for i in seg + 1:
			var t := float(i) / seg
			var p: Vector3 = b.lerp(to, t) + Vector3.UP * sin(t * PI) * 1.2
			var side := Vector3(1, 0, 0) * (0.35 + t * 0.8)
			if i > 0:
				for v in [prev_l, p + side, prev_r, prev_r, p + side, p - side]:
					st.set_normal(Vector3.UP)
					st.set_uv(Vector2(v.x, v.z))
					st.add_vertex(v)
			prev_l = p + side
			prev_r = p - side
		mi.mesh = st.commit()
		mi.material_override = jet_water
		mi.visible = false
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		jets.append(mi)


# ------------------------------------------------------------ apply a state

## s: 0 rainforest .. 1 arctic at a world point (by the sweeping front).
func set_cell_state(c: Dictionary, arctic: float) -> void:
	var n: Node3D = c["node"]
	var b: StaticBody3D = c["body"]
	if not is_instance_valid(n):
		return
	n.position.y = -34.0 * smoothstep(0.0, 1.0, arctic)
	n.visible = arctic < 0.99
	b.process_mode = Node.PROCESS_MODE_DISABLED if arctic > 0.5 else Node.PROCESS_MODE_INHERIT
	for cs in b.get_children():
		(cs as CollisionShape3D).disabled = arctic > 0.5


func set_spire_state(s: Dictionary, arctic: float) -> void:
	var n: Node3D = s["node"]
	if not is_instance_valid(n):
		return
	var p: Vector3 = s["pos"]
	n.position = p + Vector3.DOWN * 24.0 * (1.0 - smoothstep(0.0, 1.0, arctic))
	n.visible = arctic > 0.01
	for c in n.get_children():
		if c is StaticBody3D:
			for cs in c.get_children():
				(cs as CollisionShape3D).disabled = arctic < 0.5
