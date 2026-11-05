extends RefCounted
## Level 8 cave geometry (meshes only; rules live in L008.gd).
## Caves are signed-distance fields (density > 0 rock, < 0 air) sampled on one
## global lattice of spacing H, meshed per streamed chunk with naive surface
## nets. A chunk samples one extra lattice layer on its low sides and emits
## quads only for lattice edges whose base point it owns, so neighbouring
## chunks share every border vertex and the rock is seamless and watertight.
## Features: tubes (capsules, optional flat floor, vertical squash for
## phreatic "eye" sections or tall vadose canyons), rooms (ellipsoids with a
## flat floor), bowls (lake beds) and shafts.

const H := 1.25
const CLAMP := 1.2              # densities are clamped so border samples agree

class Acc:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var i := PackedInt32Array()


static func aabb_of(f: Dictionary) -> AABB:
	var m: float = f.get("amp", 0.0) + H * 2.0
	match str(f["t"]):
		"tube":
			var r: float = maxf(f["ra"], f["rb"]) * maxf(1.0, f.get("sq", 1.0)) + m * maxf(1.0, f.get("sq", 1.0))
			var a: Vector3 = f["a"]
			var b: Vector3 = f["b"]
			return AABB(a.min(b) - Vector3.ONE * r, (a - b).abs() + Vector3.ONE * r * 2.0)
		"room":
			var r0: Vector3 = f["r"]
			var rr: Vector3 = r0 + Vector3.ONE * m * maxf(r0.x, maxf(r0.y, r0.z)) / minf(r0.x, minf(r0.y, r0.z))
			return AABB(f["c"] - rr, rr * 2.0)
		_:
			var rb: Vector2 = f["r"]
			var c: Vector3 = f["c"]
			return AABB(Vector3(c.x - rb.x - m, c.y - f["depth"] - m, c.z - rb.y - m), Vector3(rb.x * 2.0 + m * 2.0, f["depth"] + m * 2.0 + 0.5, rb.y * 2.0 + m * 2.0))


## One chunk column: lattice indices [gx0, gx0+nx) x [gy0, gy0+ny) x [gz0, gz0+nz).
class Field:
	var gx0 := 0
	var gy0 := 0
	var gz0 := 0
	var nx := 0
	var ny := 0
	var nz := 0
	var d := PackedFloat32Array()
	var nn := PackedFloat32Array()

	func _init(g0: Vector3i, n: Vector3i, noise: FastNoiseLite) -> void:
		gx0 = g0.x
		gy0 = g0.y
		gz0 = g0.z
		nx = n.x
		ny = n.y
		nz = n.z
		d.resize(nx * ny * nz)
		d.fill(50.0)
		nn.resize(nx * ny * nz)
		var k := 0
		for z in nz:
			for y in ny:
				for x in nx:
					nn[k] = noise.get_noise_3d((gx0 + x) * H, (gy0 + y) * H, (gz0 + z) * H)
					k += 1

	func _rng(lo: float, hi: float, g0: int, n: int) -> Vector2i:
		return Vector2i(clampi(int(floor(lo / H)) - g0, 0, n - 1), clampi(int(ceil(hi / H)) - g0, 0, n - 1))

	func carve(f: Dictionary) -> void:
		var bb: AABB = f["bb"]
		var rx := _rng(bb.position.x, bb.end.x, gx0, nx)
		var ry := _rng(bb.position.y, bb.end.y, gy0, ny)
		var rz := _rng(bb.position.z, bb.end.z, gz0, nz)
		var t := str(f["t"])
		var amp: float = f.get("amp", 0.0)
		if t == "tube":
			var a: Vector3 = f["a"]
			var ab: Vector3 = (f["b"] as Vector3) - a
			var l2 := maxf(ab.length_squared(), 0.0001)
			var ra: float = f["ra"]
			var rb: float = f["rb"]
			var isq: float = 1.0 / float(f.get("sq", 1.0))
			var has_f: bool = f.has("fa")
			var fa: float = f.get("fa", 0.0)
			var fb: float = f.get("fb", 0.0)
			for z in range(rz.x, rz.y + 1):
				for y in range(ry.x, ry.y + 1):
					for x in range(rx.x, rx.y + 1):
						var p := Vector3((gx0 + x) * H, (gy0 + y) * H, (gz0 + z) * H)
						var k := x + nx * (y + ny * z)
						var tt := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
						var q := p - (a + ab * tt)
						q.y *= isq
						var s := q.length() - lerpf(ra, rb, tt) + nn[k] * amp
						if has_f:
							s = maxf(s, lerpf(fa, fb, tt) - p.y)
						d[k] = minf(d[k], s)
		elif t == "room":
			var c: Vector3 = f["c"]
			var r: Vector3 = f["r"]
			var rmin := minf(r.x, minf(r.y, r.z))
			var has_f: bool = f.has("f")
			var fl: float = f.get("f", 0.0)
			for z in range(rz.x, rz.y + 1):
				for y in range(ry.x, ry.y + 1):
					for x in range(rx.x, rx.y + 1):
						var p := Vector3((gx0 + x) * H, (gy0 + y) * H, (gz0 + z) * H)
						var k := x + nx * (y + ny * z)
						var s := (((p - c) / r).length() - 1.0) * rmin + nn[k] * amp
						if has_f:
							s = maxf(s, fl - p.y)
						d[k] = minf(d[k], s)
		else:
			var c: Vector3 = f["c"]
			var rb2: Vector2 = f["r"]
			var dep: float = f["depth"]
			for z in range(rz.x, rz.y + 1):
				for y in range(ry.x, ry.y + 1):
					for x in range(rx.x, rx.y + 1):
						var p := Vector3((gx0 + x) * H, (gy0 + y) * H, (gz0 + z) * H)
						var k := x + nx * (y + ny * z)
						var qx := (p.x - c.x) / rb2.x
						var qz := (p.z - c.z) / rb2.y
						var bed := c.y - dep * (1.0 - qx * qx - qz * qz) + nn[k] * amp
						d[k] = minf(d[k], maxf(bed - p.y, p.y - (c.y + 0.4)))

	func clamp_all() -> void:
		for k in d.size():
			d[k] = clampf(d[k], -CLAMP, CLAMP)

	## Surface nets. Emits quads for lattice edges whose base point (local
	## index) lies in [1, nx-1) x [1, ny-1) x [1, nz-1): the chunk's own points.
	func mesh(floor_acc: Acc, wall_acc: Acc) -> void:
		var sy := nx
		var sz := nx * ny
		var corner := PackedInt32Array([0, 1, sy, 1 + sy, sz, 1 + sz, sy + sz, 1 + sy + sz])
		var cpos := [Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(0, 1, 1), Vector3(1, 1, 1)]
		var edges := PackedInt32Array([0, 1, 2, 3, 4, 5, 6, 7, 0, 2, 1, 3, 4, 6, 5, 7, 0, 4, 1, 5, 2, 6, 3, 7])
		var vpos := PackedVector3Array()
		var vnrm := PackedVector3Array()
		var vid := PackedInt32Array()
		vid.resize(nx * ny * nz)
		vid.fill(-1)
		var cv := PackedFloat32Array()
		cv.resize(8)
		for z in nz - 1:
			for y in ny - 1:
				for x in nx - 1:
					var base := x + sy * y + sz * z
					var pos := 0
					for c in 8:
						var val := d[base + corner[c]]
						cv[c] = val
						if val > 0.0:
							pos += 1
					if pos == 0 or pos == 8:
						continue
					var sum := Vector3.ZERO
					var cnt := 0
					for e in range(0, 24, 2):
						var va := cv[edges[e]]
						var vb := cv[edges[e + 1]]
						if (va > 0.0) != (vb > 0.0):
							sum += (cpos[edges[e]] as Vector3).lerp(cpos[edges[e + 1]], va / (va - vb))
							cnt += 1
					var g := Vector3((cv[1] + cv[3] + cv[5] + cv[7]) - (cv[0] + cv[2] + cv[4] + cv[6]),
						(cv[2] + cv[3] + cv[6] + cv[7]) - (cv[0] + cv[1] + cv[4] + cv[5]),
						(cv[4] + cv[5] + cv[6] + cv[7]) - (cv[0] + cv[1] + cv[2] + cv[3]))
					vid[base] = vpos.size()
					vpos.append((Vector3(gx0 + x, gy0 + y, gz0 + z) + sum / cnt) * H)
					vnrm.append(-g.normalized())
		var steps := PackedInt32Array([1, sy, sz])
		var us := PackedInt32Array([sy, 1, 1])
		var ws := PackedInt32Array([sz, sz, sy])
		var fmap := {}
		var wmap := {}
		for z in range(1, nz - 1):
			for y in range(1, ny - 1):
				for x in range(1, nx - 1):
					var p := x + sy * y + sz * z
					var d0 := d[p]
					for ax in 3:
						var d1 := d[p + steps[ax]]
						if (d0 > 0.0) == (d1 > 0.0):
							continue
						var q := PackedInt32Array([vid[p - us[ax] - ws[ax]], vid[p - ws[ax]], vid[p], vid[p - us[ax]]])
						if q[0] < 0 or q[1] < 0 or q[2] < 0 or q[3] < 0:
							continue
						var nrm := Vector3.ZERO
						nrm[ax] = 1.0 if d0 > 0.0 else -1.0
						var fl: bool = (vnrm[q[0]] + vnrm[q[1]] + vnrm[q[2]] + vnrm[q[3]]).y > 2.4
						var acc: Acc = floor_acc if fl else wall_acc
						var mp: Dictionary = fmap if fl else wmap
						var li := PackedInt32Array()
						for qi in q:
							if not mp.has(qi):
								mp[qi] = acc.v.size()
								acc.v.append(vpos[qi])
								acc.n.append(vnrm[qi])
							li.append(mp[qi])
						if (acc.v[li[1]] - acc.v[li[0]]).cross(acc.v[li[2]] - acc.v[li[0]]).dot(nrm) > 0.0:
							acc.i.append_array([li[0], li[2], li[1], li[0], li[3], li[2]])
						else:
							acc.i.append_array([li[0], li[1], li[2], li[0], li[2], li[3]])


static func commit(parent: Node3D, a: Acc, mat: String, collide: bool, surface: String) -> MeshInstance3D:
	if a.i.is_empty():
		return null
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = a.v
	arr[Mesh.ARRAY_NORMAL] = a.n
	var uv := PackedVector2Array()
	uv.resize(a.v.size())
	for k in a.v.size():
		uv[k] = Vector2(a.v[k].x + a.v[k].y * 0.7, a.v[k].z)
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_INDEX] = a.i
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	mi.material_override = MatLib.get_mat(mat)
	parent.add_child(mi)
	if collide:
		var sb := StaticBody3D.new()
		parent.add_child(sb)
		var cs := CollisionShape3D.new()
		var sh := ConcavePolygonShape3D.new()
		sh.backface_collision = true
		var f := PackedVector3Array()
		f.resize(a.i.size())
		for k in a.i.size():
			f[k] = a.v[a.i[k]]
		sh.set_faces(f)
		cs.shape = sh
		cs.set_meta("surface", surface)
		sb.add_child(cs)
	return mi


## Stalagspike: a jagged cone from base point b along dir. Twisted, sometimes
## kinked (they "loop around, zigzag, or end in multiple sharp points").
static func spike(a: Acc, b: Vector3, dir: Vector3, length: float, radius: float, rng: RandomNumberGenerator) -> void:
	var segs := 6
	var rings := 4
	var bas := Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT)
	var bend := Vector3(rng.randf_range(-0.25, 0.25), rng.randf_range(-0.25, 0.25), 0.0)
	var b0 := a.v.size()
	var pts: Array = []
	for r in rings:
		var t := float(r) / rings
		var c := b + bas * (Vector3(0, 0, -length * t) + bend * length * t * t)
		var rad := radius * (1.0 - t) * rng.randf_range(0.85, 1.15)
		for j in segs:
			var ang := TAU * j / segs + t * 0.6
			pts.append(c + bas * Vector3(cos(ang) * rad, sin(ang) * rad, 0.0))
	var tip := b + bas * (Vector3(0, 0, -length) + bend * length)
	for q in pts:
		a.v.append(q)
		a.n.append(((q as Vector3) - b).normalized())
	a.v.append(tip)
	a.n.append(dir)
	for r in rings - 1:
		for j in segs:
			var j1 := (j + 1) % segs
			var i0 := b0 + r * segs + j
			var i1 := b0 + r * segs + j1
			var i2 := b0 + (r + 1) * segs + j1
			var i3 := b0 + (r + 1) * segs + j
			var out: Vector3 = (a.v[i0] - b).normalized()
			if (a.v[i1] - a.v[i0]).cross(a.v[i2] - a.v[i0]).dot(out) > 0.0:
				a.i.append_array([i0, i2, i1, i0, i3, i2])
			else:
				a.i.append_array([i0, i1, i2, i0, i2, i3])
	var lt := b0 + (rings - 1) * segs
	var ti := a.v.size() - 1
	for j in segs:
		var i0 := lt + j
		var i1 := lt + (j + 1) % segs
		if (a.v[i1] - a.v[i0]).cross(a.v[ti] - a.v[i0]).dot(a.v[i0] - b) > 0.0:
			a.i.append_array([i0, ti, i1])
		else:
			a.i.append_array([i0, i1, ti])


## A rock that looks carved into an arm and open hand (the page's "hands"
## stalagspikes: natural minerals in the shape of human hands).
static func stone_hand(k: GeoKit, base: Vector3, yaw: float, s: float, mat: String) -> void:
	var xf := Transform3D(Basis(Vector3.UP, yaw), base)
	k.box_xf(xf * Transform3D(Basis.from_euler(Vector3(0.08, 0, 0.05)), Vector3(0, 0.9 * s, 0)), Vector3(0.22, 1.8, 0.22) * s, mat)
	k.box_xf(xf * Transform3D(Basis(), Vector3(0, 1.95 * s, 0.03 * s)), Vector3(0.34, 0.36, 0.12) * s, mat, GeoKit.ALL, false)
	for f in 4:
		var fx := (-0.12 + f * 0.08) * s
		k.box_xf(xf * Transform3D(Basis.from_euler(Vector3(0, 0, (f - 1.5) * 0.12)), Vector3(fx, 2.32 * s, 0.03 * s)), Vector3(0.06, 0.42 - absf(f - 1.5) * 0.06, 0.06) * s, mat, GeoKit.ALL, false)
	k.box_xf(xf * Transform3D(Basis.from_euler(Vector3(0, 0, -0.9)), Vector3(0.24 * s, 1.95 * s, 0.03 * s)), Vector3(0.07, 0.28, 0.07) * s, mat, GeoKit.ALL, false)
