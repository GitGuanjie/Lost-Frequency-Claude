extends RefCounted
## Level 6.1 furniture and people kit: navy cafeteria tables and chairs, free
## vending machines, fridges and shelves, benches, planters, Faceling staff and
## M.E.G. guards. Cheap procedural geometry for the many repeated pieces; Poly
## Haven / Kenney models for accents.

var L: LevelBase
var props: Node3D
var k: GeoKit
var vending: Array = []      # [{pos, yaw, stock, shop}]


func _init(level: LevelBase, props_root: Node3D, kit: GeoKit) -> void:
	L = level
	props = props_root
	k = kit


func p(id: String, pos: Vector3, yaw: float = 0.0, h: float = 0.0, collide: bool = false) -> Node3D:
	return Props.place(L, props, id, pos, yaw, h, collide)


func bx(xf: Transform3D, c: Vector3, size: Vector3, mat: String, collide := false) -> void:
	k.box_xf(xf * Transform3D(Basis(), c), size, mat, GeoKit.ALL, collide)


## Moulded navy cafeteria chair (1980s food-court style).
func chair(c: Vector3, yaw: float) -> void:
	var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), c)
	bx(xf, Vector3(0, 0.45, 0), Vector3(0.42, 0.04, 0.42), "l61_navy")
	bx(xf, Vector3(0, 0.68, -0.2), Vector3(0.42, 0.36, 0.035), "l61_navy")
	for sx in [-0.18, 0.18]:
		for sz in [-0.18, 0.18]:
			bx(xf, Vector3(sx, 0.22, sz), Vector3(0.025, 0.44, 0.025), "l61_chrome")


## Round navy table on a pedestal with four chairs.
func table_set(c: Vector3, yaw: float, chairs := 4, square := false) -> void:
	if square:
		k.box(c + Vector3(0, 0.73, 0), Vector3(0.9, 0.04, 0.9), "l61_navy", GeoKit.ALL, true)
	else:
		k.cylinder(c + Vector3(0, 0.73, 0), 0.5, 0.04, "l61_navy", 16, true)
	k.cylinder(c + Vector3(0, 0.36, 0), 0.05, 0.72, "l61_chrome", 8, false)
	k.cylinder(c + Vector3(0, 0.015, 0), 0.26, 0.03, "l61_chrome", 12, false)
	for i in chairs:
		var ad := yaw + 360.0 / chairs * i
		var a := deg_to_rad(ad)
		chair(c + Vector3(sin(a), 0, cos(a)) * 0.78, ad + 180.0)


func bench(c: Vector3, yaw: float, length := 2.0) -> void:
	var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), c)
	bx(xf, Vector3(0, 0.44, 0), Vector3(length, 0.06, 0.45), "l61_wood", true)
	for sx in [-length * 0.4, length * 0.4]:
		bx(xf, Vector3(sx, 0.21, 0), Vector3(0.08, 0.42, 0.4), "l61_chrome")


func planter(c: Vector3, big := true) -> void:
	k.cylinder(c + Vector3(0, 0.3, 0), 0.5 if big else 0.32, 0.6, "l61_terra_dark", 14, true)
	k.cylinder(c + Vector3(0, 0.6, 0), 0.45 if big else 0.28, 0.02, "dirt", 12, false)
	p("kenney/furniture-kit/pottedplant", c + Vector3(0, 0.2, 0), L.rng.randf_range(0, 360), 1.9 if big else 1.2)


func pillar(c: Vector3, h: float) -> void:
	k.cylinder(c + Vector3(0, h * 0.5, 0), 0.45, h, "l61_pillar", 16, true)
	k.cylinder(c + Vector3(0, 0.08, 0), 0.52, 0.16, "l61_chrome", 16, false)
	k.cylinder(c + Vector3(0, h - 0.15, 0), 0.55, 0.3, "l61_trim", 16, false)


## Free vending machine (no payment slot works; any button gives something).
func vending_machine(c: Vector3, yaw: float, body: String, shop := "", collide := true) -> void:
	var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), c)
	bx(xf, Vector3(0, 0.95, 0), Vector3(0.95, 1.9, 0.8), body, collide)
	bx(xf, Vector3(-0.1, 1.15, 0.402), Vector3(0.62, 1.3, 0.01), "l61_vend_glow")
	for r in 5:
		bx(xf, Vector3(-0.1, 0.62 + r * 0.25, 0.38), Vector3(0.58, 0.1, 0.04), "l61_snack")
	bx(xf, Vector3(0.33, 1.2, 0.405), Vector3(0.18, 0.5, 0.01), "l61_black")
	bx(xf, Vector3(-0.1, 0.28, 0.405), Vector3(0.6, 0.2, 0.01), "l61_black")
	vending.append({"pos": xf * Vector3(0, 1.2, 0.75), "yaw": yaw, "stock": 3 + L.rng.randi() % 4, "shop": shop})


## Glass-door drinks fridge (Almond Water, Cashew Water, distilled water).
func fridge(c: Vector3, yaw: float) -> void:
	var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), c)
	bx(xf, Vector3(0, 1.0, 0), Vector3(0.8, 2.0, 0.7), "l61_chrome", true)
	bx(xf, Vector3(0, 1.05, 0.352), Vector3(0.7, 1.7, 0.01), "l61_fridge_glow")
	for r in 4:
		for j in 5:
			var col: String = ["l61_bottle_a", "l61_bottle_b", "l61_bottle_c"][(r + j) % 3]
			bx(xf, Vector3(-0.26 + j * 0.13, 0.42 + r * 0.42, 0.25), Vector3(0.07, 0.24, 0.07), col)


## Featureless person: a Faceling with "The 11 Effect" (staff apron), or a
## human (M.E.G. guard, Track Mapper, Snackrooms Staff).
func figure(pos: Vector3, yaw: float, kind: String) -> Node3D:
	var root := Node3D.new()
	root.name = "Figure_" + kind
	root.position = pos
	root.rotation.y = deg_to_rad(yaw)
	props.add_child(root)
	var cols := {"cook": [Color(0.15, 0.15, 0.18), Color(0.92, 0.92, 0.9)], "server": [Color(0.1, 0.1, 0.12), Color(0.75, 0.1, 0.1)],
		"cleaner": [Color(0.2, 0.25, 0.4), Color(0.3, 0.45, 0.7)], "guard": [Color(0.08, 0.09, 0.08), Color(0.12, 0.14, 0.12)],
		"mapper": [Color(0.2, 0.18, 0.15), Color(0.62, 0.5, 0.3)], "staff": [Color(0.1, 0.12, 0.2), Color(0.95, 0.75, 0.2)]}
	var c: Array = cols.get(kind, cols["staff"])
	var pants := MatLib.standard(c[0], 0.85)
	var shirt := MatLib.standard(c[1], 0.8)
	for x in [-0.11, 0.11]:
		_part(root, "capsule", Vector3(x, 0.46, 0), Vector3(0.15, 0.92, 0.15), pants)
	_part(root, "capsule", Vector3(0, 1.23, 0), Vector3(0.44, 0.74, 0.27), shirt)
	for s in [-1.0, 1.0]:
		var arm := _part(root, "capsule", Vector3(s * 0.28, 1.12, -0.04 if kind == "guard" else 0.0), Vector3(0.1, 0.68, 0.1), shirt)
		arm.rotation.z = s * 0.1
		if kind == "guard":
			arm.rotation.x = -0.5
	var face := Color(0.82, 0.73, 0.65)
	_part(root, "sphere", Vector3(0, 1.73, 0), Vector3(0.22, 0.27, 0.23), MatLib.standard(face, 0.55))
	if kind in ["cook", "server", "cleaner"]:
		# Facelings: smooth faces, staff aprons and caps
		_part(root, "box", Vector3(0, 1.05, -0.14), Vector3(0.36, 0.55, 0.02), MatLib.standard(Color(0.95, 0.95, 0.92), 0.8))
		if kind == "cook":
			_part(root, "cyl", Vector3(0, 1.93, 0), Vector3(0.12, 0.16, 0.12), MatLib.standard(Color(0.98, 0.98, 0.98), 0.8))
	else:
		# humans: hair, and for guards a helmet, vest and M.E.G. armband
		_part(root, "sphere", Vector3(0, 1.81, 0.02), Vector3(0.24, 0.15, 0.25), MatLib.standard(Color(0.18, 0.12, 0.08), 0.9))
		_part(root, "sphere", Vector3(0, 1.66, -0.11), Vector3(0.12, 0.1, 0.04), MatLib.standard(face * 0.92, 0.6))
		if kind == "guard":
			_part(root, "sphere", Vector3(0, 1.84, 0), Vector3(0.27, 0.17, 0.28), MatLib.standard(Color(0.1, 0.12, 0.1), 0.6))
			_part(root, "box", Vector3(0, 1.25, 0), Vector3(0.48, 0.5, 0.32), MatLib.standard(Color(0.06, 0.07, 0.06), 0.7))
			_part(root, "box", Vector3(0.29, 1.35, 0), Vector3(0.11, 0.08, 0.11), MatLib.standard(Color(0.9, 0.75, 0.1), 0.6))
			_part(root, "box", Vector3(0.05, 1.12, -0.32), Vector3(0.06, 0.08, 0.7), MatLib.standard(Color(0.05, 0.05, 0.05), 0.4, 0.6))
	return root


func _part(root: Node3D, t: String, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	if t == "capsule":
		var cm := CapsuleMesh.new()
		cm.radius = size.x * 0.5
		cm.height = size.y
		cm.radial_segments = 10
		cm.rings = 4
		mi.mesh = cm
	elif t == "sphere":
		var sm := SphereMesh.new()
		sm.radius = 0.5
		sm.height = 1.0
		sm.radial_segments = 14
		sm.rings = 7
		mi.mesh = sm
		mi.scale = size
	elif t == "cyl":
		var cy := CylinderMesh.new()
		cy.top_radius = size.x
		cy.bottom_radius = size.x
		cy.height = size.y
		mi.mesh = cy
	else:
		var b := BoxMesh.new()
		b.size = size
		mi.mesh = b
	mi.material_override = mat
	mi.position = pos
	root.add_child(mi)
	return mi


func label(text: String, pos: Vector3, yaw: float, size: int, col: Color, outline := 0) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.004
	l.modulate = col
	l.outline_size = outline
	l.outline_modulate = Color(col.r * 0.25, col.g * 0.25, col.b * 0.25, 0.9)
	l.position = pos
	l.rotation.y = deg_to_rad(yaw)
	l.double_sided = false
	props.add_child(l)
	return l
