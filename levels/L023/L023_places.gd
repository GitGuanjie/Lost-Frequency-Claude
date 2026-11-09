extends RefCounted
## Level 23 authored places: M.E.G. Base Seedling around its hollow tree (the
## two-way gateway to Level 135), the ancient ruins of the grove (a spherical
## Great Pyramid with its plaque, a square Colosseum, a triangular Parthenon, a
## pyramidal Lighthouse) and the Green Giants rising from the Heart of Water.

const P := preload("res://levels/L023/L023_plan.gd")

const TREE := Vector3(-4.0, 0.0, 2.0)          # Base Seedling's hollow tree
const TREE_R := 3.2
const SPHERE := Vector3(-6.0, 3.0, -86.0)
const COLOSSEUM := Vector3(24.0, 3.0, -80.0)
const PARTHENON := Vector3(12.0, 3.0, -96.0)
const LIGHTHOUSE := Vector3(-20.0, 3.0, -70.0)

var lvl
var k: GeoKit
var props: Node3D
var r := RandomNumberGenerator.new()
var lamps: Array = []
var footprints: Array = []     # [centre, radius] kept clear of growth


func _init(level, kit: GeoKit, prop_parent: Node3D) -> void:
	lvl = level
	k = kit
	props = prop_parent
	r.seed = 23230


static func materials() -> void:
	MatLib.define("l23_stone", {"albedo_a": Color(0.36, 0.33, 0.27), "albedo_b": Color(0.27, 0.25, 0.2), "noise_scale": 0.9,
		"stain_amount": 0.75, "stain_color": Color(0.07, 0.14, 0.05), "stain_scale": 0.45, "grime_height": 1.4,
		"grime_color": Color(0.05, 0.1, 0.04), "bump_strength": 1.6, "wetness": 0.3}, "concrete")
	MatLib.define("l23_block", {"albedo_a": Color(0.34, 0.31, 0.25), "albedo_b": Color(0.26, 0.24, 0.19), "pattern": 4,
		"pattern_scale": Vector2(0.9, 0.45), "grout_width": 0.03, "grout_color": Color(0.08, 0.1, 0.06), "stain_amount": 0.7,
		"stain_color": Color(0.06, 0.13, 0.05), "stain_scale": 0.5, "grime_height": 1.2, "grime_color": Color(0.05, 0.1, 0.04), "bump_strength": 1.4}, "brick")
	MatLib.define("l23_moss", {"albedo_a": Color(0.06, 0.13, 0.04), "albedo_b": Color(0.04, 0.09, 0.03), "noise_scale": 2.5,
		"roughness_a": 1.0, "bump_strength": 1.0}, "grass")
	MatLib.define("l23_canvas", {"albedo_a": Color(0.2, 0.22, 0.16), "albedo_b": Color(0.17, 0.19, 0.14), "noise_scale": 3.0,
		"stain_amount": 0.4, "stain_color": Color(0.12, 0.12, 0.09)}, "plaster")
	MatLib.define("l23_pole", {"albedo_a": Color(0.3, 0.3, 0.3), "albedo_b": Color(0.25, 0.25, 0.25), "metallic_value": 0.6}, "metal")
	MatLib.define("l23_plank", {"albedo_a": Color(0.26, 0.19, 0.12), "albedo_b": Color(0.21, 0.15, 0.1), "pattern": 3,
		"pattern_scale": Vector2(1.4, 0.2)}, "wood_floor")
	MatLib.register("l23_lamp", MatLib.panel(Color(1.0, 0.78, 0.45), 2.6))
	MatLib.define("l23_paint", {"albedo_a": Color(0.25, 0.18, 0.12), "albedo_b": Color(0.18, 0.14, 0.1), "noise_scale": 6.0,
		"stain_amount": 0.8, "stain_color": Color(0.32, 0.22, 0.1), "stain_scale": 3.0, "peel_amount": 0.5, "peel_color": Color(0.1, 0.09, 0.08)}, "plaster")


func prop(id: String, p: Vector3, yaw: float, collide := false, h := 0.0) -> Node3D:
	return Props.place(lvl, props, id, p, yaw, h, collide)


# ------------------------------------------------------------ Base Seedling

## The hollow tree: a ring of bark staves with a man-sized opening facing
## the camp; dark inside; rises into the cavern ceiling.
func hollow_tree(ceiling: float) -> void:
	var c := TREE
	var n := 22
	var h := ceiling - c.y + 2.0
	for i in n:
		var a := TAU * i / n
		if absf(wrapf(a - PI * 0.5, -PI, PI)) < 0.32:
			continue      # the opening faces +z (toward the camp)
		var p := c + Vector3(cos(a), 0, sin(a)) * TREE_R
		var w := TAU * TREE_R / n * 1.25
		k.box_xf(Transform3D(Basis(Vector3.UP, -a + PI * 0.5), p + Vector3(0, h * 0.5, 0)), Vector3(w, h, 0.9 + 0.3 * sin(i * 1.7)), "l23_bark")
	# lintel over the opening and root flares around the base
	k.box_xf(Transform3D(Basis(), c + Vector3(0, 2.6 + 1.2, TREE_R)), Vector3(2.0, 2.4, 0.9), "l23_bark", GeoKit.ALL, false)
	for i in 9:
		var a := TAU * i / 9 + 0.3
		if absf(wrapf(a - PI * 0.5, -PI, PI)) < 0.5:
			continue
		var d := Vector3(cos(a), 0, sin(a))
		k.box_xf(Transform3D(Basis.looking_at(-d, Vector3.UP) * Basis(Vector3.RIGHT, -0.5), c + d * (TREE_R + 0.9) + Vector3(0, 0.4, 0)), Vector3(0.8, 0.5, 2.6), "l23_bark", GeoKit.ALL, false)
	k.box(c + Vector3(0, 0.02, 0), Vector3(TREE_R * 1.6, 0.04, TREE_R * 1.6), "l23_moss", GeoKit.PY, false)
	footprints.append([c, TREE_R + 3.5])


## Shelters, supplies and lights of the M.E.G. base around the hollow tree.
func seedling() -> void:
	var tents := [[Vector3(8.0, 0, 7.0), 20.0], [Vector3(-14.0, 0, 9.0), -25.0], [Vector3(10.0, 0, -6.0), 75.0],
		[Vector3(-15.0, 0, -5.0), 100.0], [Vector3(1.0, 0, 13.5), 0.0]]
	for t in tents:
		_shelter(t[0], t[1])
		footprints.append([t[0], 4.0])
	# a work table with the radio, a water point, food crates
	var w := Vector3(3.0, 0, 7.5)
	prop("ph/metal_office_desk", w, 180.0, true)
	prop("ph/vintage_radio_transceiver", w + Vector3(-0.4, 0.79, 0), 160.0)
	prop("ph/clipboard", w + Vector3(0.5, 0.79, 0.1), 10.0)
	prop("ph/plastic_monobloc_chair_01", w + Vector3(0.2, 0, -0.9), 20.0)
	prop("ph/plastic_monobloc_chair_01", w + Vector3(-1.4, 0, -0.8), -30.0)
	for i in 4:
		prop("ph/Barrel_01", Vector3(-9.0 + i * 0.7, 0, 15.0 + (i % 2) * 0.6), i * 40.0, i == 0)
	for i in 5:
		prop("ph/plastic_bottle_gallon", Vector3(-7.6 + i * 0.28, 0, 14.4), i * 25.0)
	prop("ph/old_military_crate", Vector3(14.0, 0, 1.0), 80.0, true)
	prop("ph/old_military_crate", Vector3(14.1, 0.3, 1.1), 95.0)
	prop("ph/wooden_crate_01", Vector3(12.5, 0, 3.0), 10.0, true)
	prop("ph/cardboard_box_01", Vector3(13.0, 0, 4.0), 30.0)
	prop("ph/medical_box", Vector3(-12.6, 0.0, 6.5), 0.0)
	prop("ph/portable_generator", Vector3(-17.0, 0, 2.0), 60.0, true)
	prop("ph/vintage_suitcase", Vector3(7.0, 0, 9.4), 15.0)
	prop("ph/plastic_crate_01", Vector3(-1.5, 0, 9.0), 0.0)
	prop("ph/plastic_crate_01", Vector3(-1.5, 0.26, 9.0), 25.0)
	# lantern poles
	for lp in [Vector3(4.0, 0, 3.0), Vector3(-9.0, 0, 3.5), Vector3(6.0, 0, 11.5), Vector3(-6.5, 0, 11.0), Vector3(11.0, 0, -1.5)]:
		k.cylinder(lp + Vector3(0, 1.3, 0), 0.04, 2.6, "l23_pole", 6, false)
		k.box(lp + Vector3(0, 2.55, 0.18), Vector3(0.05, 0.05, 0.4), "l23_pole", GeoKit.ALL, false)
		prop("kenney/graveyard-kit/lantern-glass", lp + Vector3(0, 2.05, 0.36), 0.0, false, 0.38)
		lamps.append(lp + Vector3(0, 2.2, 0.36))
	# the notice board
	var nb := Vector3(1.5, 0, 4.5)
	k.box(nb + Vector3(0, 1.3, 0), Vector3(1.6, 1.0, 0.06), "l23_plank")
	for s in [-0.75, 0.75]:
		k.box(nb + Vector3(s, 0.9, 0.0), Vector3(0.08, 1.8, 0.08), "l23_plank", GeoKit.ALL, false)


func _shelter(c: Vector3, yaw: float) -> void:
	var b := Basis(Vector3.UP, deg_to_rad(yaw))
	var L := func(v: Vector3) -> Vector3: return c + b * v
	for sx in [-1.6, 1.6]:
		for sz in [-1.3, 1.3]:
			k.box_xf(Transform3D(b, L.call(Vector3(sx, 1.0, sz))), Vector3(0.06, 2.0, 0.06), "l23_pole", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, L.call(Vector3(0, 2.2, 0))), Vector3(0.06, 0.06, 2.8), "l23_pole", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		k.box_xf(Transform3D(b * Basis(Vector3.FORWARD, s * 0.55), L.call(Vector3(s * 0.88, 1.65, 0))), Vector3(2.0, 0.03, 3.0), "l23_canvas", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, L.call(Vector3(0, 1.0, -1.32))), Vector3(3.2, 2.0, 0.03), "l23_canvas", GeoKit.ALL, false)
	k.add_box_shape(Transform3D(b, L.call(Vector3(0, 1.0, 0))), Vector3(3.3, 2.0, 2.7), "plush")
	Props.place(lvl, props, "ph/old_bed_frame", L.call(Vector3(0.6, 0, -0.1)), yaw + 90.0)
	Props.place(lvl, props, "ph/plastic_crate_01", L.call(Vector3(-1.0, 0, 0.6)), yaw)


# ------------------------------------------------------------ the ruins

func ruins() -> void:
	_sphere()
	_colosseum()
	_parthenon()
	_lighthouse()
	# artifacts: worse-quality pottery, a damaged painting, cloth
	for p in [SPHERE + Vector3(5.5, 0, 4.0), SPHERE + Vector3(6.2, 0, 3.1), PARTHENON + Vector3(-1.0, 0.9, 0.5), COLOSSEUM + Vector3(-3.0, 0, 2.0), LIGHTHOUSE + Vector3(6.0, 0, 2.0)]:
		prop("kenney/mini-dungeon/pot", p, r.randf() * 360.0, false, r.randf_range(0.4, 0.75))
	k.box_xf(Transform3D(Basis(Vector3.UP, 0.4) * Basis(Vector3.RIGHT, -0.25), COLOSSEUM + Vector3(-4.6, 0.7, 4.0)), Vector3(1.2, 0.9, 0.04), "l23_paint", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.UP, 1.1), PARTHENON + Vector3(2.0, 0.92, -0.5)), Vector3(1.4, 0.02, 0.9), "l23_canvas", GeoKit.ALL, false)


func _sphere() -> void:
	# the "Great Sphere": a ball of courses of stone blocks, half sunk in moss
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var R := 5.5
	var rings := 18
	var segs := 36
	var ctr := SPHERE + Vector3(0, 4.0, 0)
	for i in rings:
		for j in segs:
			var q := []
			for dv in [[0, 0], [0, 1], [1, 1], [1, 0]]:
				var v := PI * float(i + dv[0]) / rings
				var u := TAU * float(j + dv[1]) / segs
				var n := Vector3(sin(v) * cos(u), cos(v), sin(v) * sin(u))
				q.append([ctr + n * R, n, Vector2(u * R, v * R)])
			for idx in [0, 1, 2, 0, 2, 3]:
				st.set_normal(q[idx][1])
				st.set_uv(q[idx][2])
				st.add_vertex(q[idx][0])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = MatLib.get_mat("l23_block")
	lvl.add_child(mi)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = 5.4
	cs.shape = sh
	cs.set_meta("surface", "concrete")
	sb.add_child(cs)
	sb.position = SPHERE + Vector3(0, 4.0, 0)
	lvl.add_child(sb)
	# a dark doorway and the plaque at the base
	k.box(SPHERE + Vector3(0.0, 1.2, 5.05), Vector3(1.4, 2.2, 0.6), "unlit_black", GeoKit.PZ, false)
	k.box(SPHERE + Vector3(2.6, 0.55, 5.1), Vector3(1.1, 0.7, 0.12), "l23_stone")
	k.box(SPHERE + Vector3(0, 0.15, 4.7), Vector3(4.0, 0.3, 1.6), "l23_moss", GeoKit.ALL, false)
	footprints.append([SPHERE, 7.5])


func _colosseum() -> void:
	var c := COLOSSEUM
	var h := 4.2
	var hs := 7.0
	var corners := [Vector3(-hs, 0, -hs), Vector3(hs, 0, -hs), Vector3(hs, 0, hs), Vector3(-hs, 0, hs)]
	for i in 4:
		var a: Vector3 = c + corners[i]
		var b: Vector3 = c + corners[(i + 1) % 4]
		var arches := []
		for j in 4:
			if i == 2 and j == 1:
				continue
			arches.append({"at": 1.75 + j * 3.5, "w": 2.0, "spring": 2.1})
		if i == 3:
			# a collapsed side: only the lower storey stands
			k.arch_wall(a, b, h * 0.55, 1.1, "l23_block", arches)
			for q in 5:
				k.box_xf(Transform3D(Basis(Vector3(r.randf(), r.randf(), r.randf()).normalized(), r.randf() * 2.0), a.lerp(b, r.randf()) + Vector3(r.randf_range(-2, 2), 0.4, r.randf_range(-2.5, 0)) ), Vector3(1.2, 0.8, 0.9), "l23_block", GeoKit.ALL, true)
		else:
			k.arch_wall(a, b, h, 1.1, "l23_block", arches)
			k.arch_wall(a + Vector3(0, h, 0), b + Vector3(0, h, 0), h * 0.7 if i != 1 else h * 0.35, 0.9, "l23_block", [{"at": 3.5, "w": 1.6, "spring": 1.3}, {"at": 10.5, "w": 1.6, "spring": 1.3}])
	k.box(c + Vector3(0, 0.03, 0), Vector3(hs * 1.6, 0.06, hs * 1.6), "l23_moss", GeoKit.PY, false)
	footprints.append([c, hs + 2.5])


func _parthenon() -> void:
	var c := PARTHENON
	var side := 12.0
	var tri: Array = []
	for i in 3:
		var a := TAU * i / 3.0 - PI * 0.5
		tri.append(Vector3(cos(a), 0, sin(a)) * side / sqrt(3.0))
	# three stepped triangular platforms (stylobate), each 0.3 m: a raised floor
	for s in 3:
		var sc := 1.0 + (2 - s) * 0.12
		_tri_slab(c, tri, sc, 0.3 * s, 0.3 * (s + 1))
	var top := c + Vector3(0, 0.9, 0)
	for i in 3:
		var a: Vector3 = tri[i]
		var b: Vector3 = tri[(i + 1) % 3]
		var n := 6
		for j in n:
			var p: Vector3 = top + a.lerp(b, float(j) / n) * 0.92
			var broken := (i == 1 and (j == 2 or j == 3)) or (i == 2 and j == 4)
			var hh := r.randf_range(1.2, 2.6) if broken else 5.6
			k.cylinder(p + Vector3(0, hh * 0.5, 0), 0.42, hh, "l23_stone", 12, true)
			if broken:
				k.box_xf(Transform3D(Basis(Vector3.FORWARD, PI * 0.5) * Basis(Vector3.UP, r.randf()), p + Vector3(r.randf_range(1.2, 2.0), -0.45, r.randf_range(-1, 1))), Vector3(0.8, 2.0, 0.8), "l23_stone", GeoKit.ALL, false)
		if i != 1:
			var pa: Vector3 = top + a * 0.92 + Vector3(0, 5.9, 0)
			var pb: Vector3 = top + b * 0.92 + Vector3(0, 5.9, 0)
			k.box_xf(Transform3D(Basis.looking_at((pb - pa).normalized(), Vector3.UP), (pa + pb) * 0.5), Vector3(1.0, 0.7, pa.distance_to(pb) + 0.8), "l23_block", GeoKit.ALL, false)
	footprints.append([c, 9.0])


func _tri_slab(c: Vector3, tri: Array, sc: float, y0: float, y1: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lo: Array = []
	var hi: Array = []
	for v in tri:
		lo.append(c + (v as Vector3) * sc + Vector3(0, y0, 0))
		hi.append(c + (v as Vector3) * sc + Vector3(0, y1, 0))
	var faces := [[hi[0], hi[2], hi[1]]]
	for i in 3:
		var j := (i + 1) % 3
		faces.append([lo[i], hi[i], hi[j]])
		faces.append([lo[i], hi[j], lo[j]])
	var pts := PackedVector3Array()
	for f in faces:
		for v in f:
			st.set_uv(Vector2((v as Vector3).x + (v as Vector3).z, (v as Vector3).y))
			st.add_vertex(v)
			pts.append(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = MatLib.get_mat("l23_block")
	lvl.add_child(mi)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := ConvexPolygonShape3D.new()
	var cp := PackedVector3Array()
	for v in lo:
		cp.append(v)
	for v in hi:
		cp.append(v)
	sh.points = cp
	cs.shape = sh
	cs.set_meta("surface", "concrete")
	sb.add_child(cs)
	lvl.add_child(sb)


func _lighthouse() -> void:
	var c := LIGHTHOUSE
	var y := 0.0
	var sizes := [11.0, 8.6, 6.4, 4.4, 2.6]
	for i in sizes.size():
		var s: float = sizes[i]
		var hh := 2.2 if i < 4 else 1.6
		k.box(c + Vector3(0, y + hh * 0.5, 0), Vector3(s, hh, s), "l23_block")
		y += hh
	# the lantern room on top: four posts and a cap
	for sx in [-0.9, 0.9]:
		for sz in [-0.9, 0.9]:
			k.box(c + Vector3(sx, y + 1.0, sz), Vector3(0.25, 2.0, 0.25), "l23_stone", GeoKit.ALL, false)
	k.box(c + Vector3(0, y + 2.15, 0), Vector3(2.4, 0.3, 2.4), "l23_stone", GeoKit.ALL, false)
	# a stair up the first tier (the only way onto the lower terrace)
	k.stairs(c + Vector3(0, 0, 5.5 + 2.6), Vector3(0, 0, -1), 1.6, 2.2, 12, "l23_block", 0.22, true)
	footprints.append([c, 8.5])


# ------------------------------------------------------------ the core

## The Green Giants: three vast trunks rising from around the Heart through
## the spherical ceiling, their roots tangled down into the water.
func giants(flora) -> Array:
	var out: Array = []
	var c := P.CORE
	for i in 3:
		var a := TAU * i / 3.0 + 0.4
		var d := P.HEART_R + 4.0
		var p := c + Vector3(cos(a) * d, -1.0, sin(a) * d)
		var rad := 4.0 + i * 1.3
		k.cylinder(p + Vector3(0, 40.0, 0), rad, 82.0, "l23_bark", 20, true)
		for j in 7:
			var ra := a + PI + r.randf_range(-1.2, 1.2)
			var dir := Vector3(cos(ra), 0, sin(ra))
			var root_len := r.randf_range(6.0, 11.0)
			var base := p + dir * rad * 0.8 + Vector3(0, r.randf_range(0.5, 2.5), 0)
			var tip := base + dir * root_len + Vector3(0, -2.5, 0)
			k.box_xf(Transform3D(Basis.looking_at((tip - base).normalized(), Vector3.UP), (base + tip) * 0.5), Vector3(r.randf_range(0.8, 1.5), r.randf_range(0.7, 1.3), root_len), "l23_bark", GeoKit.ALL, false)
		out.append([p, rad])
		footprints.append([p, rad + 2.0])
	return out
