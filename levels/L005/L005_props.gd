extends RefCounted
## Level 5 props: 1920s furniture, candle-holder sconces, paintings, placards,
## door leaves and lift gates. Furniture is merged into the caller's GeoKit (one
## draw per material per chunk); moving parts are baked once into shared meshes.
## Local frames: x along the wall, y up, z away from the wall (into the space).

const DoorScript := preload("res://levels/L005/L005_door.gd")

var L: Node3D
var _meshes := {}


func _init(level: Node3D) -> void:
	L = level


static func frame(p: Vector3, n: Vector3) -> Basis:
	return Basis(Vector3.UP.cross(n).normalized(), Vector3.UP, n.normalized())


static func put(k: GeoKit, b: Basis, p: Vector3, c: Vector3, s: Vector3, mat: String, collide := false, faces := GeoKit.ALL) -> void:
	k.box_xf(Transform3D(b, p + b * c), s, mat, faces, collide)


## Polygonal tube between two points (pipes, rails, horns). Merged into the kit.
static func tube(k: GeoKit, a: Vector3, b: Vector3, r: float, mat: String, sides := 8, collide := false) -> void:
	var ax := b - a
	var length := ax.length()
	if length < 0.001:
		return
	var w := ax / length
	var u := w.cross(Vector3.UP if absf(w.y) < 0.9 else Vector3.RIGHT).normalized()
	var v := w.cross(u).normalized()
	var mid := (a + b) * 0.5
	var chord := 2.0 * r * sin(PI / sides)
	for i in sides:
		var ang := TAU * (i + 0.5) / sides
		var nrm := u * cos(ang) + v * sin(ang)
		var tang := u * -sin(ang) + v * cos(ang)
		k.quad(mid + nrm * r * cos(PI / sides), nrm, tang * chord * 0.5, w * length * 0.5, mat)
	if collide:
		var bas := Basis(u, v, w)
		k.add_box_shape(Transform3D(bas, mid), Vector3(r * 2.0, r * 2.0, length), GeoKit.surface_for(mat))


static func label(parent: Node3D, text: String, p: Vector3, n: Vector3, px: float, col: Color, vis := 11.0) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = 64
	l.pixel_size = px
	l.modulate = col
	l.outline_size = 0
	l.shaded = true
	l.double_sided = false
	l.basis = frame(p, n)
	l.position = p + n * 0.008
	l.visibility_range_end = vis
	parent.add_child(l)
	return l


# ------------------------------------------------------------- furniture

func sofa(k: GeoKit, p: Vector3, n: Vector3) -> void:
	var b := frame(p, n)
	put(k, b, p, Vector3(0, 0.27, 0.43), Vector3(1.9, 0.34, 0.78), "l5_velvet")
	put(k, b, p, Vector3(0, 0.71, 0.13), Vector3(1.9, 0.56, 0.2), "l5_velvet")
	for sx in [-1.0, 1.0]:
		put(k, b, p, Vector3(sx * 0.86, 0.56, 0.45), Vector3(0.18, 0.26, 0.76), "l5_velvet")
		put(k, b, p, Vector3(sx * 0.44, 0.48, 0.5), Vector3(0.82, 0.1, 0.6), "l5_velvet_dark")
		for sz in [0.12, 0.76]:
			put(k, b, p, Vector3(sx * 0.86, 0.05, sz), Vector3(0.07, 0.1, 0.07), "l5_wood")
	put(k, b, p, Vector3(0, 0.45, 0.43), Vector3(1.9, 0.9, 0.8), "l5_velvet", true, 0)


func bookshelf(k: GeoKit, p: Vector3, n: Vector3, r: RandomNumberGenerator) -> void:
	var b := frame(p, n)
	put(k, b, p, Vector3(0, 1.05, 0.02), Vector3(1.04, 2.1, 0.03), "l5_wood")
	for sx in [-1.0, 1.0]:
		put(k, b, p, Vector3(sx * 0.5, 1.05, 0.19), Vector3(0.04, 2.1, 0.36), "l5_wood")
	put(k, b, p, Vector3(0, 2.12, 0.2), Vector3(1.1, 0.05, 0.4), "l5_wood")
	for s in 5:
		var y := 0.08 + s * 0.42
		put(k, b, p, Vector3(0, y, 0.19), Vector3(0.96, 0.03, 0.34), "l5_wood")
		var x := -0.46
		while x < 0.4:
			var w := r.randf_range(0.12, 0.3)
			w = minf(w, 0.46 - x)
			var h := r.randf_range(0.22, 0.33)
			put(k, b, p, Vector3(x + w * 0.5, y + 0.015 + h * 0.5, 0.17), Vector3(w - 0.006, h, 0.24), "l5_books" if r.randf() < 0.6 else "l5_books_b")
			x += w + (0.04 if r.randf() < 0.15 else 0.0)
	put(k, b, p, Vector3(0, 1.05, 0.19), Vector3(1.04, 2.1, 0.38), "l5_wood", true, 0)


func cabinet(k: GeoKit, p: Vector3, n: Vector3, gramophone: bool) -> void:
	var b := frame(p, n)
	put(k, b, p, Vector3(0, 0.5, 0.23), Vector3(1.2, 0.84, 0.44), "l5_wood")
	put(k, b, p, Vector3(0, 0.94, 0.24), Vector3(1.28, 0.04, 0.48), "l5_wood")
	for sx in [-1.0, 1.0]:
		put(k, b, p, Vector3(sx * 0.29, 0.5, 0.455), Vector3(0.52, 0.7, 0.012), "l5_door_inset")
		put(k, b, p, Vector3(sx * 0.07, 0.55, 0.47), Vector3(0.03, 0.08, 0.02), "l5_trim_gold")
		put(k, b, p, Vector3(sx * 0.55, 0.04, 0.23), Vector3(0.06, 0.08, 0.4), "l5_wood")
	put(k, b, p, Vector3(0, 0.48, 0.24), Vector3(1.28, 0.96, 0.48), "l5_wood", true, 0)
	if gramophone:
		put(k, b, p, Vector3(0.15, 1.03, 0.24), Vector3(0.36, 0.14, 0.34), "l5_wood")
		k.cylinder(p + b * Vector3(0.15, 1.105, 0.24), 0.15, 0.012, "l5_record", 16, false)
		var base := p + b * Vector3(-0.0, 1.1, 0.12)
		var tip := p + b * Vector3(-0.22, 1.62, 0.3)
		var steps := 6
		for s in steps:
			var t0 := float(s) / steps
			var t1 := float(s + 1) / steps
			tube(k, base.lerp(tip, t0), base.lerp(tip, t1), 0.025 + 0.2 * t1 * t1, "l5_trim_gold", 10)


func painting(k: GeoKit, p: Vector3, n: Vector3, w: float, h: float, cy: float) -> void:
	var b := frame(p, n)
	put(k, b, p, Vector3(0, cy, 0.025), Vector3(w, h, 0.05), "l5_trim_gold")
	put(k, b, p, Vector3(0, cy, 0.052), Vector3(w - 0.14, h - 0.14, 0.01), "l5_painting")


func console(k: GeoKit, p: Vector3, n: Vector3) -> void:
	var b := frame(p, n)
	put(k, b, p, Vector3(0, 0.8, 0.2), Vector3(1.1, 0.04, 0.4), "l5_wood")
	put(k, b, p, Vector3(0, 0.72, 0.2), Vector3(1.02, 0.12, 0.34), "l5_wood")
	for sx in [-1.0, 1.0]:
		for sz in [0.06, 0.34]:
			put(k, b, p, Vector3(sx * 0.5, 0.36, sz), Vector3(0.04, 0.72, 0.04), "l5_wood")
	put(k, b, p, Vector3(0, 0.4, 0.2), Vector3(1.1, 0.8, 0.4), "l5_wood", true, 0)


func speaker(k: GeoKit, p: Vector3, n: Vector3) -> Vector3:
	var b := frame(p, n)
	put(k, b, p, Vector3(0, 2.72, 0.11), Vector3(0.42, 0.34, 0.22), "l5_wood")
	put(k, b, p, Vector3(0, 2.72, 0.222), Vector3(0.34, 0.26, 0.006), "l5_grille")
	return p + b * Vector3(0, 2.72, 0.3)


## Antique candle holder; some are electric lamps. Returns the light position.
func sconce(k: GeoKit, p: Vector3, n: Vector3, dead: bool, y := 1.88) -> Vector3:
	var b := frame(p, n)
	put(k, b, p, Vector3(0, y, 0.012), Vector3(0.11, 0.26, 0.024), "l5_trim_gold")
	put(k, b, p, Vector3(0, y - 0.06, 0.09), Vector3(0.035, 0.035, 0.16), "l5_trim_gold")
	put(k, b, p, Vector3(0, y - 0.06, 0.16), Vector3(0.34, 0.03, 0.03), "l5_trim_gold")
	for sx in [-1.0, 1.0]:
		put(k, b, p, Vector3(sx * 0.16, y - 0.03, 0.16), Vector3(0.06, 0.03, 0.06), "l5_trim_gold")
		put(k, b, p, Vector3(sx * 0.16, y + 0.05, 0.16), Vector3(0.026, 0.13, 0.026), "l5_candle")
		put(k, b, p, Vector3(sx * 0.16, y + 0.135, 0.16), Vector3(0.032, 0.05, 0.032), "l5_flame_dead" if dead else "l5_flame")
	return p + b * Vector3(0, y + 0.08, 0.3)


func bed(k: GeoKit, b: Basis, p: Vector3) -> void:
	# p = foot of the far wall, b: x lateral, z = back toward the door
	put(k, b, p, Vector3(0, 0.22, 1.05), Vector3(1.5, 0.3, 2.0), "l5_wood")
	put(k, b, p, Vector3(0, 0.46, 1.05), Vector3(1.42, 0.2, 1.92), "l5_linen")
	put(k, b, p, Vector3(0, 0.58, 1.3), Vector3(1.46, 0.06, 1.4), "l5_velvet_dark")
	for sx in [-0.36, 0.36]:
		put(k, b, p, Vector3(sx, 0.62, 0.3), Vector3(0.6, 0.12, 0.34), "l5_linen")
	put(k, b, p, Vector3(0, 0.62, 0.04), Vector3(1.6, 1.24, 0.07), "l5_wood")
	put(k, b, p, Vector3(0, 0.36, 2.06), Vector3(1.6, 0.72, 0.06), "l5_wood")
	put(k, b, p, Vector3(0, 0.4, 1.05), Vector3(1.6, 0.8, 2.1), "l5_wood", true, 0)


func room_set(k: GeoKit, b: Basis, p: Vector3, depth: float) -> Vector3:
	# far wall at p (on the room's centre line), b.z pointing back toward the door
	bed(k, b, p + b * Vector3(-0.2, 0, 0))
	put(k, b, p, Vector3(1.05, 0.3, 0.3), Vector3(0.42, 0.6, 0.4), "l5_wood", true)
	k.cylinder(p + b * Vector3(1.05, 0.68, 0.3), 0.05, 0.16, "l5_trim_gold", 8, false)
	k.cylinder(p + b * Vector3(1.05, 0.86, 0.3), 0.15, 0.2, "l5_shade", 10, false)
	put(k, b, p, Vector3(-1.18, 1.0, depth - 3.3), Vector3(0.6, 2.0, 1.1), "l5_wood", true)
	put(k, b, p, Vector3(-0.88, 1.0, depth - 3.3), Vector3(0.012, 1.8, 0.02), "l5_door_inset")
	put(k, b, p, Vector3(0.95, 0.3, depth - 1.9), Vector3(0.75, 0.6, 0.75), "l5_velvet", true)
	put(k, b, p, Vector3(0.95, 0.75, depth - 1.62), Vector3(0.75, 0.6, 0.18), "l5_velvet")
	put(k, b, p, Vector3(0, 0.006, 2.8), Vector3(1.9, 0.012, 2.4), "l5_rug")
	return p + b * Vector3(1.05, 0.95, 0.3)


# --------------------------------------------------------------- baked parts

func bake(k: GeoKit) -> ArrayMesh:
	var am := ArrayMesh.new()
	for mat in k._surf.keys():
		var s: Dictionary = k._surf[mat]
		if (s["v"] as PackedVector3Array).is_empty():
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = s["v"]
		arrays[Mesh.ARRAY_NORMAL] = s["n"]
		arrays[Mesh.ARRAY_TEX_UV] = s["uv"]
		arrays[Mesh.ARRAY_TEX_UV2] = s["uv2"]
		arrays[Mesh.ARRAY_INDEX] = s["i"]
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		am.surface_set_material(am.get_surface_count() - 1, MatLib.get_mat(mat))
	k._surf.clear()
	k.root.queue_free()
	return am


## Door leaf in local space: hinge at the origin, leaf along +x (1.0 m).
func door_mesh(style: String) -> ArrayMesh:
	if _meshes.has(style):
		return _meshes[style]
	var k := GeoKit.new(L, "_bake")
	var wood: String = {"std": "l5_door", "white": "l5_door_white", "dark": "l5_door_dark", "plain": "l5_door_plain"}[style]
	var inset: String = {"std": "l5_door_inset", "white": "l5_trim_gold", "dark": "l5_door_dark", "plain": "l5_door_plain"}[style]
	var brass := "l5_trim_gold" if style != "dark" else "l5_brass_dull"
	k.box(Vector3(0.5, 1.125, 0), Vector3(0.99, 2.25, 0.045), wood, GeoKit.ALL, false)
	for side in [-1.0, 1.0]:
		for pnl in [[0.27, 0.6, 0.3, 0.86], [0.73, 0.6, 0.3, 0.86], [0.27, 1.64, 0.3, 0.92], [0.73, 1.64, 0.3, 0.92]]:
			if style == "white":
				for e in [[0, -1], [0, 1], [-1, 0], [1, 0]]:
					var sz := Vector3(pnl[2] if e[0] == 0 else 0.016, pnl[3] if e[1] == 0 else 0.016, 0.006)
					k.box(Vector3(pnl[0] + e[0] * pnl[2] * 0.5, pnl[1] + e[1] * pnl[3] * 0.5, side * 0.025), sz, inset, GeoKit.ALL, false)
			else:
				k.box(Vector3(pnl[0], pnl[1], side * 0.025), Vector3(pnl[2], pnl[3], 0.008), inset, GeoKit.ALL, false)
		k.box(Vector3(0.89, 1.0, side * 0.026), Vector3(0.055, 0.2, 0.006), brass, GeoKit.ALL, false)
		k.box(Vector3(0.89, 1.0, side * 0.052), Vector3(0.05, 0.05, 0.045), brass, GeoKit.ALL, false)
	var m := bake(k)
	_meshes[style] = m
	return m


## Folding copper lattice gate, 1.6 m wide (scaled on x to fold).
func gate_mesh() -> ArrayMesh:
	if _meshes.has("gate"):
		return _meshes["gate"]
	var k := GeoKit.new(L, "_bake")
	var w := 1.6
	var bars := 14
	for i in bars + 1:
		k.box(Vector3(w * i / bars, 1.15, 0), Vector3(0.018, 2.3, 0.018), "l5_copper", GeoKit.ALL, false)
	for y in [0.06, 1.15, 2.24]:
		k.box(Vector3(w * 0.5, y, 0), Vector3(w, 0.03, 0.024), "l5_copper", GeoKit.ALL, false)
	for i in bars:
		var cx := w * (i + 0.5) / bars
		for sgn in [-1.0, 1.0]:
			for yy in [0.6, 1.7]:
				var bas := Basis(Vector3.BACK, sgn * 1.2)
				k.box_xf(Transform3D(bas, Vector3(cx, yy, 0.01)), Vector3(0.012, 0.95, 0.012), "l5_copper", GeoKit.ALL, false)
	var m := bake(k)
	_meshes["gate"] = m
	return m


## A real hinged hotel door. hinge on the wall's centre line, t along the wall
## toward the latch, room_dir pointing into the room it opens into.
func make_door(parent: Node3D, hinge: Vector3, t: Vector3, room_dir: Vector3, style: String) -> StaticBody3D:
	var d: StaticBody3D = DoorScript.new()
	d.collision_layer = 1 | 4
	d.collision_mask = 0
	var z := t.cross(Vector3.UP)
	d.base_basis = Basis(t, Vector3.UP, z)
	d.swing = 1.0 if room_dir.dot(z) < 0.0 else -1.0
	d.transform = Transform3D(d.base_basis, hinge)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(1.0, 2.25, 0.05)
	cs.shape = sh
	cs.position = Vector3(0.5, 1.125, 0)
	cs.set_meta("surface", "wood")
	d.add_child(cs)
	var mi := MeshInstance3D.new()
	mi.mesh = door_mesh(style)
	mi.visibility_range_end = 60.0
	d.add_child(mi)
	d.level = L
	parent.add_child(d)
	return d
