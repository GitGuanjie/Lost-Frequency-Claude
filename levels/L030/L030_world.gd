extends RefCounted
## Level 30 geometry: the flat grass island of the bright false form (thin
## grass over stone, a rock underside tapering into open sky), the lower rock
## shelf with what is left of the outpost, the distant islands and clouds of
## the daytime skybox, the dark form's bridges that clip into one another,
## and the Memory Lurker figure.

const SHELF_Y := -4.0

var lvl
var r := RandomNumberGenerator.new()
var rows: Array = []          # [z0, x0, x1]
var rn := 0.0                 # island radius due north (-z)
var ramp_x := 16.0
var ramp_top := Vector3.ZERO
var shelf_c := Vector3.ZERO
var blue_end := Vector3.ZERO
var flat_at := Vector3.ZERO


func _init(level) -> void:
	lvl = level
	r.seed = 30030


static func rad(a: float) -> float:
	return 108.0 + 16.0 * sin(3.0 * a + 1.0) + 9.0 * sin(5.0 * a + 2.3) + 5.0 * sin(9.0 * a + 0.4)


static func inside(x: float, z: float, inset: float = 0.0) -> bool:
	return Vector2(x, z).length() < rad(atan2(z, x)) - inset


static func materials() -> void:
	MatLib.define("l30_grass", {"albedo_a": Color(0.15, 0.3, 0.08), "albedo_b": Color(0.32, 0.46, 0.14), "pattern": 12,
		"pattern_color": Color(0.2, 0.36, 0.12), "pattern_strength": 0.45, "noise_scale": 0.05, "roughness_a": 0.85}, "grass")
	MatLib.define("l30_soil", {"albedo_a": Color(0.3, 0.22, 0.15), "albedo_b": Color(0.24, 0.17, 0.11), "noise_scale": 1.2}, "dirt")
	MatLib.define("l30_rock", {"albedo_a": Color(0.55, 0.44, 0.32), "albedo_b": Color(0.42, 0.33, 0.24), "pattern": 11,
		"pattern_color": Color(0.26, 0.25, 0.24), "pattern_strength": 0.35, "noise_scale": 0.12, "bump_strength": 0.8}, "rock")
	MatLib.define("l30_rock_dark", {"albedo_a": Color(0.3, 0.29, 0.29), "albedo_b": Color(0.22, 0.21, 0.21), "pattern": 11,
		"pattern_color": Color(0.17, 0.16, 0.16), "pattern_strength": 0.35, "noise_scale": 0.1}, "rock")
	MatLib.define("l30_far", {"albedo_a": Color(0.42, 0.6, 0.3), "albedo_b": Color(0.36, 0.55, 0.26), "noise_scale": 0.02}, "grass")
	MatLib.define("l30_far_rock", {"albedo_a": Color(0.5, 0.53, 0.58), "albedo_b": Color(0.44, 0.47, 0.52), "noise_scale": 0.02}, "rock")
	MatLib.define("l30_canvas", {"albedo_a": Color(0.42, 0.4, 0.3), "albedo_b": Color(0.36, 0.34, 0.26), "stain_amount": 0.5,
		"stain_color": Color(0.2, 0.18, 0.12)}, "plaster")
	MatLib.define("l30_pole", {"albedo_a": Color(0.35, 0.36, 0.36), "albedo_b": Color(0.28, 0.28, 0.29), "metallic_value": 0.6}, "metal")
	MatLib.define("l30_bridge", {"albedo_a": Color(0.36, 0.38, 0.43), "albedo_b": Color(0.33, 0.35, 0.4), "noise_scale": 0.01,
		"roughness_a": 0.18, "roughness_b": 0.25, "bump_strength": 0.0, "pattern": 1, "pattern_scale": Vector2(3.0, 3.0),
		"grout_width": 0.03, "grout_color": Color(0.1, 0.11, 0.12), "emission_color": Color(0.3, 0.36, 0.55), "emission_energy": 0.22}, "concrete")
	MatLib.register("l30_rail", MatLib.panel(Color(0.55, 0.65, 0.9), 2.0))
	MatLib.register("l30_blue", MatLib.panel(Color(0.2, 0.5, 1.0), 3.5))
	MatLib.register("l30_sky_flat", MatLib.panel(Color(0.45, 0.68, 0.95), 1.4))
	MatLib.register("l30_grass_flat", MatLib.panel(Color(0.3, 0.6, 0.22), 1.2))
	MatLib.register("l30_cloud", MatLib.standard(Color(0.97, 0.98, 1.0), 1.0, 0.0, Color(0.85, 0.88, 0.95), 0.55))


# --------------------------------------------------------------- the island

const SEG := 120

## A floating island built as one mesh: a flat grass top (fan), a soil rim and
## a rock underside tapering in noisy rings. rfn(angle) -> radius.
## Collision: thin boxes per 1 m row for the top, plus an inset rock body.
func islet(parent: Node3D, col: GeoKit, c: Vector3, rfn: Callable, rings: Array, seed_v: int) -> void:
	var nz := FastNoiseLite.new()
	nz.seed = seed_v
	nz.frequency = 0.9
	var sts := {}
	for mn in ["l30_grass", "l30_soil", "l30_rock", "l30_rock_dark"]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		sts[mn] = st
	var prev: Array = []
	for ri in rings.size():
		var ring: Array = []
		var dy: float = rings[ri][0]
		var f: float = rings[ri][1]
		for i in SEG:
			var a := TAU * i / SEG
			var rr: float = float(rfn.call(a)) * (1.0 - f)
			if ri > 1:
				rr += nz.get_noise_2d(cos(a) * 3.0, sin(a) * 3.0 + ri * 1.7) * (2.0 + f * 14.0)
			ring.append(c + Vector3(cos(a) * maxf(rr, 0.5), dy, sin(a) * maxf(rr, 0.5)))
		if ri == 0:
			for i in SEG:
				_tri(sts["l30_grass"], c, ring[i], ring[(i + 1) % SEG], Vector3.UP, true)
		else:
			var mn := "l30_soil" if ri == 1 else ("l30_rock" if dy > -16.0 else "l30_rock_dark")
			for i in SEG:
				var j := (i + 1) % SEG
				var out := Vector3(cos(TAU * (i + 0.5) / SEG), 0.0, sin(TAU * (i + 0.5) / SEG))
				_tri(sts[mn], prev[i], prev[j], ring[i], out, false)
				_tri(sts[mn], prev[j], ring[j], ring[i], out, false)
		prev = ring
	var tip := c + Vector3(0, float(rings[rings.size() - 1][0]) - 6.0, 0)
	for i in SEG:
		_tri(sts["l30_rock_dark"], prev[i], prev[(i + 1) % SEG], tip, Vector3.DOWN, false)
	for mn in sts.keys():
		var mi := MeshInstance3D.new()
		mi.mesh = (sts[mn] as SurfaceTool).commit()
		mi.material_override = MatLib.get_mat(mn)
		parent.add_child(mi)
	# collision rows
	var z := c.z - 180.0
	while z < c.z + 180.0:
		var x0 := 1.0e9
		var x1 := -1.0e9
		var x := c.x - 180.0
		while x <= c.x + 180.0:
			var d := Vector2(x - c.x, z + 0.5 - c.z)
			if d.length() < float(rfn.call(atan2(d.y, d.x))) - 0.35:
				x0 = minf(x0, x)
				x1 = maxf(x1, x)
			x += 0.5
		if x1 > x0:
			col.box_mm(Vector3(x0, c.y - 0.5, z), Vector3(x1 + 0.5, c.y, z + 1.0), "l30_grass", 0)
			if x1 - x0 > 3.0:
				col.box_mm(Vector3(x0 + 1.0, c.y - 6.0, z), Vector3(x1 - 0.5, c.y - 0.5, z + 1.0), "l30_rock", 0)
			if c.y > -1.0:
				rows.append([z, x0, x1 + 0.5])
		z += 1.0


func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, want: Vector3, top: bool) -> void:
	var n := (b - a).cross(c - a)
	if n.dot(want) > 0.0:
		var t := b
		b = c
		c = t
		n = -n
	var nn := -n.normalized()
	for v in [a, b, c]:
		st.set_normal(nn)
		var vv: Vector3 = v
		st.set_uv(Vector2(vv.x, vv.z) if top else Vector2(vv.x + vv.z, -vv.y))
		st.add_vertex(vv)


func island(parent: Node3D, col: GeoKit) -> void:
	rn = rad(-PI * 0.5)
	islet(parent, col, Vector3.ZERO, rad, [[0.0, 0.0], [-1.3, 0.004], [-6.0, 0.02], [-14.0, 0.09], [-26.0, 0.22], [-40.0, 0.4], [-56.0, 0.6], [-70.0, 0.8]], 30)


static func shelf_rad(a: float) -> float:
	return 14.0 + 2.5 * sin(3.0 * a + 0.7) + 1.5 * sin(7.0 * a)


## The lower shelf below the north rim, the rock causeway down to it and the
## remains of the destroyed outpost.
func shelf(parent: Node3D, col: GeoKit, k: GeoKit) -> void:
	var zr := 0.0
	for row in rows:
		if ramp_x >= float(row[1]) and ramp_x <= float(row[2]):
			zr = float(row[0])
			break
	ramp_top = Vector3(ramp_x, 0.0, zr + 0.6)
	var bot := Vector3(ramp_x, SHELF_Y, zr - 11.0)
	k.ramp(ramp_top, bot, 3.0, 1.0, "l30_rock")
	var sc := Vector3(ramp_x - 7.0, SHELF_Y, zr - 13.5)
	islet(parent, col, sc, shelf_rad, [[0.0, 0.0], [-1.0, 0.01], [-5.0, 0.08], [-11.0, 0.3], [-18.0, 0.6]], 31)
	shelf_c = sc + Vector3(-1.0, 0.0, -1.0)
	for i in 7:
		var t := float(i) / 6.0
		var p := ramp_top.lerp(bot, t)
		for s in [-1.0, 1.0]:
			k.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * PI), p + Vector3(s * 1.7, 0.2, 0)), Vector3(r.randf_range(0.6, 1.1), 0.6, r.randf_range(0.6, 1.2)), "l30_rock", GeoKit.ALL, false)
	# the outpost: a collapsed tent frame, a torn canvas, a fallen mast
	var c := shelf_c
	for pp in [[Vector3(-3, 0, -2), 0.2], [Vector3(3, 0, -2), -0.4], [Vector3(-3, 0, 2.5), 0.9], [Vector3(3, 0, 2.5), 0.0]]:
		var tilt: float = pp[1]
		k.box_xf(Transform3D(Basis(Vector3.FORWARD, tilt), c + pp[0] + Vector3(0, 1.1, 0)), Vector3(0.07, 2.2, 0.07), "l30_pole", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.RIGHT, 0.5) * Basis(Vector3.FORWARD, 0.15), c + Vector3(0.5, 0.9, 0.3)), Vector3(6.2, 0.03, 4.0), "l30_canvas", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.UP, 0.4) * Basis(Vector3.FORWARD, 1.47), c + Vector3(-6.0, 0.15, 3.0)), Vector3(0.12, 6.0, 0.12), "l30_pole", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.UP, -0.3), c + Vector3(5.5, 0.02, -3.0)), Vector3(3.0, 0.03, 2.0), "l30_canvas", GeoKit.ALL, false)


# ------------------------------------------------------------ the skybox

func far_islands(k: GeoKit) -> void:
	for i in 12:
		var ang := TAU * i / 12.0 + r.randf_range(-0.2, 0.2)
		var d := r.randf_range(450.0, 700.0) if i % 3 == 0 else r.randf_range(800.0, 2200.0)
		var c := Vector3(cos(ang) * d, r.randf_range(-260.0, 160.0), sin(ang) * d)
		var rr := r.randf_range(60.0, 180.0)
		k.cylinder(c + Vector3(0, -1.0, 0), rr, 2.0, "l30_far", 24, false)
		var h := 0.0
		var rad2 := rr
		while rad2 > rr * 0.15:
			var seg := rr * 0.22
			k.cylinder(c + Vector3(0, -2.0 - h - seg * 0.5, 0), rad2, seg, "l30_far_rock", 18, false)
			h += seg
			rad2 *= 0.72


func clouds(parent: Node3D) -> void:
	var m := MatLib.get_mat("l30_cloud")
	for i in 26:
		var ang := r.randf() * TAU
		var d := r.randf_range(380.0, 1900.0)
		var c := Vector3(cos(ang) * d, r.randf_range(-320.0, 260.0), sin(ang) * d)
		var cl := Node3D.new()
		cl.position = c
		parent.add_child(cl)
		for j in r.randi_range(4, 7):
			var mi := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radial_segments = 14
			sm.rings = 8
			mi.mesh = sm
			var s := r.randf_range(26.0, 60.0)
			mi.scale = Vector3(s * r.randf_range(1.2, 2.0), s * 0.55, s)
			mi.position = Vector3(r.randf_range(-60, 60), r.randf_range(-8, 12), r.randf_range(-40, 40))
			mi.material_override = m
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			cl.add_child(mi)


# ------------------------------------------------------ the dark false form

## Bridges that clip through each other, radiating from the rim into the dark.
## Built under `parent`, which the level parks far away outside the trance.
func bridges(k: GeoKit) -> void:
	var defs := [[-0.3, 140.0, 0.0, "blue"], [0.35, 70.0, 6.0, "void"], [-0.9, 95.0, -5.0, "void"], [0.9, 80.0, 3.0, "flat"],
		[-1.4, 60.0, 9.0, "void"], [1.5, 110.0, -8.0, "void"], [2.3, 75.0, 4.0, "void"], [-2.4, 90.0, -2.0, "void"], [3.0, 65.0, 7.0, "void"]]
	for dd in defs:
		var a: float = float(dd[0]) - PI * 0.5
		var length: float = dd[1]
		var rise: float = dd[2]
		var dir := Vector3(cos(a), 0.0, sin(a))
		var p0 := dir * (rad(a) - 6.0)
		var p1 := p0 + dir * length + Vector3(0, rise, 0)
		k.ramp(p0 + Vector3(0, 0.02, 0), p1, 3.2, 0.5, "l30_bridge")
		var side := dir.cross(Vector3.UP).normalized()
		for s in [-1.0, 1.0]:
			var q0: Vector3 = p0 + side * (1.55 * s) + Vector3(0, 1.0, 0)
			var q1: Vector3 = p1 + side * (1.55 * s) + Vector3(0, 1.0, 0)
			var mid := (q0 + q1) * 0.5
			var xf := Transform3D(Basis.looking_at((q1 - q0).normalized(), Vector3.UP), mid)
			k.box_xf(xf, Vector3(0.06, 0.06, q0.distance_to(q1)), "l30_rail", GeoKit.ALL, false)
			var n := int(length / 6.0)
			for i in n + 1:
				var t := float(i) / float(n)
				k.box(q0.lerp(q1, t) - Vector3(0, 0.5, 0), Vector3(0.08, 1.0, 0.08), "l30_bridge", GeoKit.ALL, false)
		if dd[3] == "blue":
			blue_end = p1
		elif dd[3] == "flat":
			flat_at = p1 - dir * 3.0
	# crossing spans that pierce the others at odd heights
	for i in 6:
		var a := r.randf_range(-PI, PI)
		var c := Vector3(cos(a), 0, sin(a)) * r.randf_range(115.0, 170.0) + Vector3(0, r.randf_range(-3.0, 9.0), 0)
		var dir := Vector3(cos(a + PI * 0.5 + r.randf_range(-0.6, 0.6)), r.randf_range(-0.12, 0.12), 0.0)
		dir.z = sin(a + PI * 0.5)
		dir = dir.normalized()
		k.ramp(c - dir * 60.0, c + dir * 60.0, 3.0, 0.5, "l30_bridge")


## The painted backdrop at the end of one bridge: the bright island, flat.
func backdrop(k: GeoKit) -> void:
	var dir := (flat_at * Vector3(1, 0, 1)).normalized()
	var face := Basis.looking_at(-dir, Vector3.UP)
	var c := flat_at + dir * 2.5 + Vector3(0, 4.0, 0)
	k.box_xf(Transform3D(face, c + Vector3(0, 1.5, 0)), Vector3(14.0, 5.0, 0.05), "l30_sky_flat", GeoKit.ALL, false)
	k.box_xf(Transform3D(face, c - Vector3(0, 2.0, 0)), Vector3(14.0, 2.0, 0.06), "l30_grass_flat", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		k.box_xf(Transform3D(face, c + face.x * (7.1 * s) - Vector3(0, 0.5, 0)), Vector3(0.2, 8.0, 0.2), "l30_pole", GeoKit.ALL, false)


static func lurker(mat: Material) -> Node3D:
	var n := Node3D.new()
	var body := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.16
	cm.height = 0.62
	body.mesh = cm
	body.material_override = mat
	body.rotation.x = PI * 0.5
	n.add_child(body)
	var fin := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.2
	cone.height = 0.28
	fin.mesh = cone
	fin.material_override = mat
	fin.rotation.x = -PI * 0.5
	fin.position = Vector3(0, 0, -0.42)
	n.add_child(fin)
	for i in 8:
		var a := TAU * i / 8.0
		var t := MeshInstance3D.new()
		var tm := CapsuleMesh.new()
		tm.radius = 0.025
		tm.height = 0.55 + 0.1 * (i % 3)
		t.mesh = tm
		t.material_override = mat
		t.rotation.x = PI * 0.5 + 0.15
		t.position = Vector3(cos(a) * 0.09, sin(a) * 0.09, 0.5)
		t.name = "T%d" % i
		n.add_child(t)
	return n
