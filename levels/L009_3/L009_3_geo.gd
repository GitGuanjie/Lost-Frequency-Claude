extends RefCounted
## Level 9.3 chunk geometry: terrain (mesh + heightmap collision), the highway
## ribbon, the mossy brick-and-cobble wall under its steel net, the wheat maze
## (stalk-card skirts + one box collider per block), motionless trees and bushes.

const W := preload("res://levels/L009_3/L009_3_world.gd")
const CS := W.CS

var w
static var _crown: ArrayMesh
static var _trunk: CylinderMesh
static var _bush: ArrayMesh
static var _tuft: ArrayMesh


class MB:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var uv := PackedVector2Array()
	var col := PackedColorArray()
	var i := PackedInt32Array()

	func vert(p: Vector3, nn: Vector3, t: Vector2 = Vector2.ZERO, c: Color = Color.WHITE) -> int:
		v.append(p)
		n.append(nn)
		uv.append(t)
		col.append(c)
		return v.size() - 1

	## quad a,b,c,d counter-clockwise when seen from the side the normal points to
	func quad(a: int, b: int, c: int, d: int) -> void:
		i.append_array([a, c, b, a, d, c])

	func inst(parent: Node3D, mat: String, shadow: bool = true) -> MeshInstance3D:
		if i.is_empty():
			return null
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = v
		arr[Mesh.ARRAY_NORMAL] = n
		arr[Mesh.ARRAY_TEX_UV] = uv
		arr[Mesh.ARRAY_COLOR] = col
		arr[Mesh.ARRAY_INDEX] = i
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		var mi := MeshInstance3D.new()
		mi.mesh = am
		mi.material_override = MatLib.get_mat(mat)
		if not shadow:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		return mi


func _init(world) -> void:
	w = world
	if _crown == null:
		_crown = _blob(3, 11)
		_bush = _blob(2, 23)
		_trunk = CylinderMesh.new()
		_trunk.top_radius = 0.18
		_trunk.bottom_radius = 0.32
		_trunk.height = 1.0
		_trunk.radial_segments = 7
		_trunk.rings = 1
		var mb := MB.new()
		for q in 3:
			var a := TAU * q / 3.0
			var d := Vector3(cos(a), 0, sin(a)) * 0.4
			var i0 := mb.vert(-d, Vector3.UP, Vector2(0, 0))
			mb.vert(d, Vector3.UP, Vector2(1, 0))
			mb.vert(d + Vector3(0, 0.5, 0), Vector3.UP, Vector2(1, 1))
			mb.vert(-d + Vector3(0, 0.5, 0), Vector3.UP, Vector2(0, 1))
			mb.i.append_array([i0, i0 + 1, i0 + 2, i0, i0 + 2, i0 + 3])
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = mb.v
		arr[Mesh.ARRAY_NORMAL] = mb.n
		arr[Mesh.ARRAY_TEX_UV] = mb.uv
		arr[Mesh.ARRAY_INDEX] = mb.i
		_tuft = ArrayMesh.new()
		_tuft.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)


static func _blob(sub: int, sd: int) -> ArrayMesh:
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 6 + sub * 3
	sm.rings = 3 + sub * 2
	var arr := sm.get_mesh_arrays()
	var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var nz := FastNoiseLite.new()
	nz.seed = sd
	nz.frequency = 1.3
	for k in vs.size():
		var p := vs[k]
		vs[k] = p * (1.0 + nz.get_noise_3dv(p * 1.7) * 0.35)
	arr[Mesh.ARRAY_VERTEX] = vs
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return am


func build(cx: int, cz: int, node: Node3D, r: RandomNumberGenerator) -> Dictionary:
	var ox := cx * CS
	var oz := cz * CS
	_terrain(ox, oz, node)
	var meta := {"road": false, "wheat": 0, "trees": 0}
	_road(ox, oz, node, meta)
	_wheat(cx, cz, ox, oz, node, meta)
	_trees(ox, oz, node, r, meta)
	return meta


func _terrain(ox: float, oz: float, node: Node3D) -> void:
	var mb := MB.new()
	var n := 25
	for gz in n:
		for gx in n:
			var x := ox + gx * 2.0
			var z := oz + gz * 2.0
			var nrm := Vector3(W.h_at(x - 1.0, z) - W.h_at(x + 1.0, z), 2.0, W.h_at(x, z - 1.0) - W.h_at(x, z + 1.0)).normalized()
			mb.vert(Vector3(x, W.h_at(x, z), z), nrm)
	for r in n - 1:
		for c in n - 1:
			var a := r * n + c
			mb.i.append_array([a, a + 1, a + n, a + 1, a + n + 1, a + n])
	var mi := mb.inst(node, "l93_grass")
	mi.name = "Ground"
	var m := 49
	var md := PackedFloat32Array()
	md.resize(m * m)
	for sz in m:
		for sx in m:
			md[sz * m + sx] = W.h_at(ox + sx, oz + sz)
	var sh := HeightMapShape3D.new()
	sh.map_width = m
	sh.map_depth = m
	sh.map_data = md
	var body := StaticBody3D.new()
	body.name = "GroundBody"
	var cs := CollisionShape3D.new()
	cs.shape = sh
	cs.position = Vector3(ox + 24.0, 0.0, oz + 24.0)
	cs.set_meta("surface", "grass")
	body.add_child(cs)
	node.add_child(body)


func _road(ox: float, oz: float, node: Node3D, meta: Dictionary) -> void:
	# the one highway crosses each period once along z; find its copy in this chunk
	var pz := floorf(oz / W.P) * W.P
	var px := floorf(ox / W.P) * W.P
	var mb := MB.new()
	var lines := MB.new()
	var k := GeoKit.new(node, "Wall")
	var net := MB.new()
	var got := false
	for off in [px - W.P, px, px + W.P]:
		var steps := 24
		for s in steps:
			var z0 := oz + s * 2.0
			var z1 := z0 + 2.0
			var u0: float = off + W.road_u(W.wrapf_p(z0))
			var u1: float = off + W.road_u(W.wrapf_p(z1))
			if u0 < ox - 12.0 or u0 > ox + CS + 12.0:
				continue
			got = true
			var y0 := W.road_h(W.wrapf_p(z0)) + 0.04
			var y1 := W.road_h(W.wrapf_p(z1)) + 0.04
			var a := mb.vert(Vector3(u0 - W.ROAD_HW, y0, z0), Vector3.UP)
			mb.vert(Vector3(u0 + W.ROAD_HW, y0, z0), Vector3.UP)
			mb.vert(Vector3(u1 + W.ROAD_HW, y1, z1), Vector3.UP)
			mb.vert(Vector3(u1 - W.ROAD_HW, y1, z1), Vector3.UP)
			mb.i.append_array([a, a + 1, a + 2, a, a + 2, a + 3])
			# worn centre dashes and edge lines
			if int(floor(z0 / 2.0)) % 4 < 2:
				var b := lines.vert(Vector3(u0 - 0.07, y0 + 0.01, z0), Vector3.UP)
				lines.vert(Vector3(u0 + 0.07, y0 + 0.01, z0), Vector3.UP)
				lines.vert(Vector3(u1 + 0.07, y1 + 0.01, z1), Vector3.UP)
				lines.vert(Vector3(u1 - 0.07, y1 + 0.01, z1), Vector3.UP)
				lines.i.append_array([b, b + 1, b + 2, b, b + 2, b + 3])
			# the brick-and-cobble wall on the west side, covered in a steel net
			var wx0 := u0 - W.ROAD_HW - 1.6
			var wx1 := u1 - W.ROAD_HW - 1.6
			var g0 := W.h_at(wx0, z0)
			var hgt := 1.55 + 0.12 * sin(z0 * 0.37)
			var c := Vector3((wx0 + wx1) * 0.5, g0 + hgt * 0.5 - 0.3, z0 + 1.0)
			var dir := Vector3(wx1 - wx0, 0, 2.0)
			var bas := Basis(Vector3.UP.cross(dir.normalized()).normalized(), Vector3.UP, dir.normalized())
			k.box_xf(Transform3D(bas, c), Vector3(0.62, hgt + 0.6, dir.length() + 0.02), "l93_wall" if s % 5 != 2 else "l93_cobble")
			# a capping course, some stones missing
			if s % 7 != 3:
				k.box_xf(Transform3D(bas, c + Vector3(0, hgt * 0.5 + 0.36, 0)), Vector3(0.72, 0.12, dir.length() + 0.02), "l93_cobble", GeoKit.ALL, false)
			var top := g0 + hgt + 0.15
			var nx := 0.33
			var g1 := W.h_at(wx1, z1)
			var q := net.vert(Vector3(wx0 + nx, g0 - 0.25, z0), Vector3.RIGHT, Vector2(z0, g0 - 0.25))
			net.vert(Vector3(wx1 + nx, g1 - 0.25, z1), Vector3.RIGHT, Vector2(z1, g1 - 0.25))
			net.vert(Vector3(wx1 + nx, top, z1), Vector3.RIGHT, Vector2(z1, top))
			net.vert(Vector3(wx0 + nx, top, z0), Vector3.RIGHT, Vector2(z0, top))
			net.i.append_array([q, q + 1, q + 2, q, q + 2, q + 3])
	if got:
		meta["road"] = true
		mb.inst(node, "l93_asphalt", false)
		lines.inst(node, "l93_line", false)
		net.inst(node, "l93_net", false)
	k.commit()


func _wheat(cx: int, cz: int, ox: float, oz: float, node: Node3D, meta: Dictionary) -> void:
	var mb := MB.new()
	var body := StaticBody3D.new()
	body.name = "Wheat"
	node.add_child(body)
	var c0 := int(ox / W.CELL)
	var r0 := int(oz / W.CELL)
	var per := int(CS / W.CELL)
	for j in per:
		for i in per:
			var gx := c0 + i
			var gz := r0 + j
			if not W.is_wheat(gx, gz):
				continue
			for b in w.wheat_blocks(gx, gz):
				var lo: Vector3 = b[0]
				var hi: Vector3 = b[1]
				_block(mb, lo, hi)
				var cs := CollisionShape3D.new()
				var sh := BoxShape3D.new()
				sh.size = hi - lo - Vector3(0.3, 0, 0.3)
				cs.shape = sh
				cs.position = (lo + hi) * 0.5
				cs.set_meta("surface", "grass")
				body.add_child(cs)
				meta["wheat"] += 1
	mb.inst(node, "l93_wheat")


func _block(mb: MB, lo: Vector3, hi: Vector3) -> void:
	var top := hi.y
	var a := mb.vert(Vector3(lo.x + 0.3, top - 0.12, lo.z + 0.3), Vector3.UP, Vector2(0, top))
	mb.vert(Vector3(hi.x - 0.3, top - 0.12, lo.z + 0.3), Vector3.UP, Vector2(0, top))
	mb.vert(Vector3(hi.x - 0.3, top - 0.12, hi.z - 0.3), Vector3.UP, Vector2(0, top))
	mb.vert(Vector3(lo.x + 0.3, top - 0.12, hi.z - 0.3), Vector3.UP, Vector2(0, top))
	mb.i.append_array([a, a + 2, a + 1, a, a + 3, a + 2])
	var sides := [[Vector3(lo.x, 0, lo.z), Vector3(hi.x, 0, lo.z), Vector3(0, 0, -1)],
		[Vector3(hi.x, 0, lo.z), Vector3(hi.x, 0, hi.z), Vector3(1, 0, 0)],
		[Vector3(hi.x, 0, hi.z), Vector3(lo.x, 0, hi.z), Vector3(0, 0, 1)],
		[Vector3(lo.x, 0, hi.z), Vector3(lo.x, 0, lo.z), Vector3(-1, 0, 0)]]
	for s in sides:
		var nn: Vector3 = s[2]
		for lay in 3:
			var ins: Vector3 = nn * -float([0.0, 0.3, 0.65][lay])
			var p0: Vector3 = s[0] + ins
			var p1: Vector3 = s[1] + ins
			var lc := Color(lay * 0.5, 0, 0)
			var b := mb.vert(Vector3(p0.x, lo.y, p0.z), nn, Vector2(0, top + 0.3), lc)
			mb.vert(Vector3(p1.x, lo.y, p1.z), nn, Vector2(0, top + 0.3), lc)
			mb.vert(Vector3(p1.x, top + 0.3, p1.z), nn, Vector2(0, top + 0.3), lc)
			mb.vert(Vector3(p0.x, top + 0.3, p0.z), nn, Vector2(0, top + 0.3), lc)
			mb.i.append_array([b, b + 2, b + 1, b, b + 3, b + 2])


func _mm(node: Node3D, mesh: Mesh, mat: String, xfs: Array, shadow: bool = true) -> void:
	if xfs.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for k in xfs.size():
		mm.set_instance_transform(k, xfs[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = MatLib.get_mat(mat)
	if not shadow:
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.add_child(mmi)


## Motionless trees: dense in the forest band, scattered clumps and hedgerows elsewhere,
## and a few colossal ones behind the hilltop houses.
func _trees(ox: float, oz: float, node: Node3D, r: RandomNumberGenerator, meta: Dictionary) -> void:
	var trunks: Array = []
	var crowns: Array = []
	var crowns_d: Array = []
	var bushes: Array = []
	var body := StaticBody3D.new()
	body.name = "Trunks"
	node.add_child(body)
	var add_tree := func(x: float, z: float, s: float) -> void:
		var g := W.h_at(x, z)
		var th := 5.0 * s
		trunks.append(Transform3D(Basis().scaled(Vector3(s, th, s)), Vector3(x, g + th * 0.5 - 0.2, z)))
		for c in 6:
			var cs := s * r.randf_range(1.4, 2.4) * (1.2 if c == 0 else 1.0)
			var off := Vector3(r.randf_range(-1.8, 1.8) * s, th + r.randf_range(-1.0, 3.0) * s, r.randf_range(-1.8, 1.8) * s) * (0.3 if c == 0 else 1.0)
			var xf := Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(cs, cs * 0.8, cs)), Vector3(x, g, z) + off)
			if c % 2 == 1:
				crowns_d.append(xf)
			else:
				crowns.append(xf)
		var col := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.3 * s
		cyl.height = th
		col.shape = cyl
		col.position = Vector3(x, g + th * 0.5, z)
		body.add_child(col)
	for i in 70:
		var x := ox + r.randf() * CS
		var z := oz + r.randf() * CS
		var u := W.wrapf_p(x)
		var v := W.wrapf_p(z)
		var fw := W.forest_w(u)
		if absf(W.dwrap(u, W.road_u(v))) < W.ROAD_HW + 4.0:
			continue
		var cxi := int(floor(x / W.CELL))
		var czi := int(floor(z / W.CELL))
		if W.is_wheat(cxi, czi):
			continue
		var near_hill := false
		for hl in W.HILLS:
			if Vector2(W.dwrap(u, hl[0]), W.dwrap(v, hl[1])).length() < 14.0:
				near_hill = true
		if near_hill:
			continue
		if fw > 0.5 and i < 46:
			add_tree.call(x, z, r.randf_range(1.0, 1.7))
		elif fw <= 0.5 and i % 9 == 0:
			add_tree.call(x, z, r.randf_range(0.8, 1.3))
		elif fw <= 0.5 and i % 3 == 0:
			var bs := r.randf_range(0.6, 1.3)
			bushes.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(bs * 1.3, bs, bs * 1.2)), Vector3(x, W.h_at(x, z) + bs * 0.4, z)))
	# colossal trees behind each house (seen from the bathroom casement)
	for hi in W.HILLS.size():
		var hx: Transform3D = W.house_xf(hi)
		hx.origin += Vector3(floor(ox / W.P) * W.P, 0, floor(oz / W.P) * W.P)
		for k in 3:
			var tp: Vector3 = hx * Vector3(-5.0 + k * 6.5, 0, 17.0 + (k % 2) * 4.0)
			if tp.x >= ox and tp.x < ox + CS and tp.z >= oz and tp.z < oz + CS:
				add_tree.call(tp.x, tp.z, 2.4 + k * 0.3)
	var tufts: Array = []
	for i in 900:
		var x := ox + r.randf() * CS
		var z := oz + r.randf() * CS
		if W.is_wheat(int(floor(x / W.CELL)), int(floor(z / W.CELL))) or absf(W.dwrap(W.wrapf_p(x), W.road_u(W.wrapf_p(z)))) < W.ROAD_HW + 0.3:
			continue
		var ts := r.randf_range(0.6, 1.2)
		tufts.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(ts, ts * r.randf_range(0.8, 1.5), ts)), Vector3(x, W.h_at(x, z) - 0.03, z)))
	_mm(node, _tuft, "l93_tuft", tufts, false)
	_mm(node, _trunk, "l93_bark", trunks)
	_mm(node, _crown, "l93_leaf", crowns)
	_mm(node, _crown, "l93_leaf_dark", crowns_d)
	_mm(node, _bush, "l93_bush", bushes)
	meta["trees"] = trunks.size()
