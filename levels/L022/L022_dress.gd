extends RefCounted
## Level 22 dressing kit: collapse rubble, rebar and girder poles, rusted 1950s car
## husks, shopping trolleys, tents (some still occupied), shacks of wood or mined
## concrete, sleeping bags, dead and dying ceiling lights. Geometry goes into the
## level's GeoKits (one mesh per material); props come from Props.place().

const S := preload("res://levels/L022/L022_struct.gd")

var L
var k: GeoKit          # collidable structure-scale pieces
var v: GeoKit          # visual-only pieces
var r := RandomNumberGenerator.new()
var tent_st := {}


func _init(level, kit_c: GeoKit, kit_v: GeoKit) -> void:
	L = level
	k = kit_c
	v = kit_v
	r.seed = 2222


func _xf(p: Vector3, yaw: float, pitch: float = 0.0, roll: float = 0.0) -> Transform3D:
	return Transform3D(Basis.from_euler(Vector3(pitch, yaw, roll)), p)


## A heap of broken slab: chunks in a mound, rebar poking out; optional single collider.
func rubble(base: Vector3, size: Vector3, collide: bool, n: int = -1) -> void:
	if n < 0:
		n = clampi(int(size.x * size.z * 1.2), 6, 40)
	for i in n:
		var u := r.randf_range(-0.5, 0.5)
		var w := r.randf_range(-0.5, 0.5)
		var hgt := size.y * (1.0 - (u * u + w * w) * 3.2)
		if hgt <= 0.05:
			hgt = 0.1
		var p := base + Vector3(u * size.x, r.randf_range(0.0, hgt) * 0.8, w * size.z)
		var cs := Vector3(r.randf_range(0.25, 1.1), r.randf_range(0.12, 0.35), r.randf_range(0.25, 0.9)) * (1.0 + hgt * 0.15)
		v.box_xf(_xf(p, r.randf() * TAU, r.randf_range(-0.6, 0.6), r.randf_range(-0.6, 0.6)), cs, "l22_rubble" if r.randf() < 0.7 else "l22_deck", GeoKit.ALL, false)
		if r.randf() < 0.25:
			rebar(p + Vector3(0, cs.y * 0.5, 0), Vector3(r.randf_range(-1, 1), r.randf_range(0.2, 1.0), r.randf_range(-1, 1)).normalized(), r.randf_range(0.5, 1.4))
	if collide:
		k.box(base + Vector3(0, size.y * 0.45, 0), Vector3(size.x * 0.8, size.y * 0.9, size.z * 0.8), "l22_rubble", 0, true, "concrete")


func rebar(p: Vector3, dir: Vector3, length: float) -> void:
	var z := dir.normalized()
	var x := Vector3.UP.cross(z)
	if x.length() < 0.1:
		x = Vector3.RIGHT
	x = x.normalized()
	v.box_xf(Transform3D(Basis(x, z.cross(x), z), p + z * length * 0.5), Vector3(0.025, 0.025, length), "l22_rust", GeoKit.ALL, false)


## An I-section girder pole from a to b (lying, leaning or wedged).
func girder(a: Vector3, b: Vector3, collide: bool = false) -> void:
	var z := (b - a).normalized()
	var x := Vector3.UP.cross(z)
	if x.length() < 0.1:
		x = Vector3.RIGHT
	x = x.normalized()
	var y := z.cross(x)
	var c := (a + b) * 0.5
	var l := a.distance_to(b)
	var bas := Basis(x, y, z)
	k.box_xf(Transform3D(bas, c), Vector3(0.03, 0.3, l), "l22_rust", GeoKit.ALL, collide)
	v.box_xf(Transform3D(bas, c + y * 0.15), Vector3(0.18, 0.025, l), "l22_rust", GeoKit.ALL, false)
	v.box_xf(Transform3D(bas, c - y * 0.15), Vector3(0.18, 0.025, l), "l22_rust", GeoKit.ALL, false)


## A torn-up 1950s sedan husk. state: 0 husk, 1 roofless, 2 crushed, 3 tidy (the L069 car).
func car(p: Vector3, yaw: float, state: int) -> Dictionary:
	var bas := Basis(Vector3.UP, yaw)
	var fw := bas * Vector3(0, 0, 1)
	var sd := bas * Vector3(1, 0, 0)
	var mat := "l22_carrust" if state != 3 else "l22_carpaint"
	var lift := 0.12 if state != 3 else 0.32
	var body_h := 0.62
	var c := p + Vector3(0, lift + body_h * 0.5, 0)
	k.box_xf(Transform3D(bas, c), Vector3(1.86, body_h, 5.1), mat, GeoKit.ALL, true, "metal")
	# rounded nose and tail, fenders
	v.box_xf(Transform3D(bas.rotated(sd, 0.18), c + fw * 2.45 + Vector3(0, 0.12, 0)), Vector3(1.8, 0.4, 0.6), mat, GeoKit.ALL, false)
	v.box_xf(Transform3D(bas.rotated(sd, -0.12), c - fw * 2.5 + Vector3(0, 0.1, 0)), Vector3(1.78, 0.45, 0.5), mat, GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		for e in [-1.0, 1.0]:
			if state != 3:
				v.box_xf(Transform3D(bas, c + sd * s * 0.86 + fw * e * 1.55 - Vector3(0, 0.2, 0)), Vector3(0.25, 0.42, 0.85), "l22_dark", GeoKit.ALL, false)
			else:
				var wp: Vector3 = p + sd * s * 0.78 + fw * e * 1.55 + Vector3(0, 0.33, 0)
				v.box_xf(Transform3D(bas, wp), Vector3(0.22, 0.62, 0.62), "l22_tyre", GeoKit.ALL, false)
	var cab_h := 0.6 if state != 2 else 0.22
	var top := c.y + body_h * 0.5
	if state != 1:
		v.box_xf(Transform3D(bas, Vector3(c.x, top + cab_h, c.z) - fw * 0.25), Vector3(1.55, 0.07, 2.2), mat, GeoKit.ALL, false)
		for s in [-1.0, 1.0]:
			for e in [-1.0, 1.0]:
				v.box_xf(Transform3D(bas, Vector3(c.x, top + cab_h * 0.5, c.z) + sd * s * 0.72 + fw * (e * 1.0 - 0.25)), Vector3(0.07, cab_h, 0.08), mat, GeoKit.ALL, false)
		if state == 3:
			for s in [-1.0, 1.0]:
				v.box_xf(Transform3D(bas, Vector3(c.x, top + cab_h * 0.5, c.z) + sd * s * 0.74 - fw * 0.25), Vector3(0.02, cab_h * 0.9, 2.0), "l22_glass", GeoKit.ALL, false)
	else:
		# the roof lies torn off beside it
		v.box_xf(_xf(p + sd * 1.9 + Vector3(0, 0.08, 0), yaw + 0.4, 0.05, 0.12), Vector3(1.5, 0.06, 2.1), mat, GeoKit.ALL, false)
	v.box_xf(Transform3D(bas, Vector3(c.x, top + 0.02, c.z) - fw * 0.25), Vector3(1.6, 0.04, 2.3), "l22_dark", GeoKit.ALL, false)
	if state != 3 and r.randf() < 0.6:
		Props.place(L, L.props_root, "ph/old_tyre", p + sd * (1.6 if r.randf() < 0.5 else -1.6) + fw * r.randf_range(-1.5, 1.5), r.randf() * 360.0)
	return {"pos": p, "yaw": yaw, "size": Vector3(1.9, 1.4, 5.2)}


## A shopping trolley, upright or on its side.
func trolley(p: Vector3, yaw: float, tipped: bool) -> void:
	var b := Basis(Vector3.UP, yaw)
	if tipped:
		b = b * Basis(Vector3(0, 0, 1), PI * 0.5)
		p += Vector3(0, 0.3, 0)
	var o := Vector3(0, 0.0 if tipped else 0.0, 0)
	var edges := [
		[Vector3(-0.27, 0.95, -0.45), Vector3(0.54, 0.02, 0.02)], [Vector3(-0.27, 0.95, 0.45), Vector3(0.54, 0.02, 0.02)],
		[Vector3(-0.22, 0.45, -0.4), Vector3(0.44, 0.02, 0.02)], [Vector3(-0.22, 0.45, 0.4), Vector3(0.44, 0.02, 0.02)],
		[Vector3(-0.27, 0.95, -0.45), Vector3(0.02, 0.02, 0.9)], [Vector3(0.27, 0.95, -0.45), Vector3(0.02, 0.02, 0.9)],
		[Vector3(-0.22, 0.45, -0.4), Vector3(0.02, 0.02, 0.8)], [Vector3(0.22, 0.45, -0.4), Vector3(0.02, 0.02, 0.8)],
	]
	for e in edges:
		var a: Vector3 = e[0]
		var s: Vector3 = e[1]
		v.box_xf(Transform3D(b, p + b * (a + s * 0.5 - Vector3(s.x * 0.0, 0, 0)) + o), s.max(Vector3(0.02, 0.02, 0.02)), "l22_chrome", GeoKit.ALL, false)
	for x in [-0.25, 0.25]:
		for z in [-0.43, 0.43]:
			v.box_xf(Transform3D(b, p + b * Vector3(x * 0.9, 0.7, z * 0.95)), Vector3(0.02, 0.5, 0.02), "l22_chrome", GeoKit.ALL, false)
			v.box_xf(Transform3D(b, p + b * Vector3(x * 0.85, 0.06, z * 0.9)), Vector3(0.03, 0.1, 0.1), "l22_dark", GeoKit.ALL, false)
	v.box_xf(Transform3D(b, p + b * Vector3(0, 1.02, 0.52)), Vector3(0.56, 0.035, 0.035), "l22_red", GeoKit.ALL, false)
	for x in [-0.15, -0.05, 0.05, 0.15]:
		v.box_xf(Transform3D(b, p + b * Vector3(x, 0.7, 0.0)), Vector3(0.01, 0.5, 0.85), "l22_chrome", GeoKit.ALL, false)


## An A-frame canvas tent; returns its centre. occupied tents hold a still sleeping bag.
func tent(p: Vector3, yaw: float, col: Color, occupied: bool, collapsed: bool) -> Vector3:
	var st: SurfaceTool = tent_st.get(col)
	if st == null:
		st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		tent_st[col] = st
	var b := Basis(Vector3.UP, yaw)
	var hw := 0.85
	var hl := 1.15
	var h := 1.15 if not collapsed else 0.45
	var ridge_skew := Vector3(0.25, 0, 0) if collapsed else Vector3.ZERO
	var A := p + b * Vector3(-hw, 0.02, -hl)
	var B := p + b * Vector3(hw, 0.02, -hl)
	var C := p + b * Vector3(hw, 0.02, hl)
	var D := p + b * Vector3(-hw, 0.02, hl)
	var R0 := p + b * (Vector3(0, h, -hl) + ridge_skew)
	var R1 := p + b * (Vector3(0, h, hl) + ridge_skew)
	for t in [[A, R0, R1], [A, R1, D], [B, C, R1], [B, R1, R0], [A, B, R0]]:
		var n := ((t[1] as Vector3) - (t[0] as Vector3)).cross((t[2] as Vector3) - (t[0] as Vector3)).normalized()
		for q in t:
			st.set_normal(n)
			st.set_uv(Vector2((q as Vector3).x + (q as Vector3).z, (q as Vector3).y))
			st.add_vertex(q)
	# the front: two flaps, half open on a dark inside
	for t in [[D, R1, D.lerp(C, 0.3)], [C, C.lerp(D, 0.3), R1]]:
		var n2 := ((t[1] as Vector3) - (t[0] as Vector3)).cross((t[2] as Vector3) - (t[0] as Vector3)).normalized()
		for q in t:
			st.set_normal(n2)
			st.set_uv(Vector2((q as Vector3).x, (q as Vector3).y))
			st.add_vertex(q)
	v.box_xf(Transform3D(b, p + Vector3(0, 0.01, 0)), Vector3(hw * 2.0, 0.02, hl * 2.0), "l22_dark", GeoKit.ALL, false)
	if occupied:
		var bag := MeshInstance3D.new()
		var cap := CapsuleMesh.new()
		cap.radius = 0.28
		cap.height = 1.85
		cap.radial_segments = 10
		cap.rings = 3
		bag.mesh = cap
		bag.material_override = MatLib.get_mat("l22_bag")
		L.props_root.add_child(bag)
		bag.global_transform = Transform3D(b * Basis(Vector3(1, 0, 0), PI * 0.5), p + Vector3(0, 0.2, 0))
		bag.scale = Vector3(1, 1, 0.55)
	return p


func commit_tents() -> void:
	for col in tent_st.keys():
		var mi := MeshInstance3D.new()
		mi.mesh = (tent_st[col] as SurfaceTool).commit()
		var m := MatLib.standard(col, 0.95)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = m
		L.props_root.add_child(mi)


func sleeping_bag(p: Vector3, yaw: float, mat: String = "l22_bag") -> void:
	var bag := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.3
	cap.height = 1.9
	cap.radial_segments = 10
	cap.rings = 3
	bag.mesh = cap
	bag.material_override = MatLib.get_mat(mat)
	L.props_root.add_child(bag)
	bag.global_transform = Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3(1, 0, 0), PI * 0.5), p + Vector3(0, 0.14, 0))
	bag.scale = Vector3(1, 1, 0.42)


## A shack: wood planks or mined concrete chunks, a rusty sheet roof under the beams.
func shack(p: Vector3, yaw: float, concrete: bool, w: float = 3.0, d: float = 2.4) -> void:
	var b := Basis(Vector3.UP, yaw)
	var h := 2.0
	var mat := "l22_minedblock" if concrete else "l22_plank"
	var walls := [[Vector3(0, 0, -d * 0.5), Vector3(w, h, 0.12)], [Vector3(-w * 0.5, 0, 0), Vector3(0.12, h, d)], [Vector3(w * 0.5, 0, 0), Vector3(0.12, h, d)]]
	for wl in walls:
		var o: Vector3 = wl[0]
		var s: Vector3 = wl[1]
		k.box_xf(Transform3D(b, p + b * (o + Vector3(0, s.y * 0.5, 0))), s, mat, GeoKit.ALL, true, "wood" if not concrete else "concrete")
	# front wall with a doorway
	var fw := (w - 0.8) * 0.5
	for sgn in [-1.0, 1.0]:
		k.box_xf(Transform3D(b, p + b * Vector3(sgn * (0.4 + fw * 0.5), h * 0.5, d * 0.5)), Vector3(fw, h, 0.12), mat, GeoKit.ALL, true, "wood" if not concrete else "concrete")
	v.box_xf(Transform3D(b * Basis(Vector3(1, 0, 0), 0.08), p + b * Vector3(0, h + 0.06, 0)), Vector3(w + 0.4, 0.03, d + 0.5), "l22_sheet", GeoKit.ALL, false)
	v.box_xf(Transform3D(b, p + Vector3(0, 0.01, 0)), Vector3(w - 0.2, 0.02, d - 0.2), "l22_rug", GeoKit.ALL, false)


## A ceiling light under the slab at deck y: dead, flickering or (rarely) burning.
func fixture(p: Vector3, state: int) -> void:
	var y := p.y
	v.box(Vector3(p.x, y - 0.06, p.z), Vector3(1.25, 0.1, 0.22), "l22_alu", GeoKit.ALL, false)
	v.box(Vector3(p.x, y - 0.12, p.z), Vector3(1.15, 0.03, 0.14), "l22_tube_on" if state > 0 else "l22_tube_off", GeoKit.ALL, false)
	if state > 0:
		L.lights.add_anchor(Vector3(p.x, y - 0.5, p.z), Color(1.0, 0.72, 0.42) if state == 2 else Color(0.85, 0.92, 1.0), 1.5 if state == 2 else 1.1, 9.0, 0.05 if state == 2 else 0.55, "fix")
