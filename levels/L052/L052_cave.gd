extends RefCounted
## Level 52 cave geometry. The signed-distance field and surface-nets mesher are
## adapted from levels/L008/CaveGeo.gd (density > 0 rock, < 0 air, one global
## lattice of spacing H, seamless per-chunk meshing). Added here: an analytic
## SDF query with ray marching (to find real wall and ceiling points for cave
## paintings and stalactites), a lofted crawl tube with exact clearance (the
## shallow entrance passage) and the seeded, endless main gallery ("its length
## is unknown").

const H := 1.0
const CS := 24.0
const N := 24
const CLAMP := 1.2

class Acc:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var i := PackedInt32Array()


static func aabb_of(f: Dictionary) -> AABB:
	var m: float = f.get("amp", 0.0) + H * 2.0
	if str(f["t"]) == "tube":
		var sq: float = maxf(1.0, f.get("sq", 1.0))
		var r: float = maxf(f["ra"], f["rb"]) * sq + m * sq
		var a: Vector3 = f["a"]
		var b: Vector3 = f["b"]
		return AABB(a.min(b) - Vector3.ONE * r, (a - b).abs() + Vector3.ONE * r * 2.0)
	var r0: Vector3 = f["r"]
	var rr: Vector3 = r0 + Vector3.ONE * m * maxf(r0.x, maxf(r0.y, r0.z)) / minf(r0.x, minf(r0.y, r0.z))
	return AABB(f["c"] - rr, rr * 2.0)


static func sdf(fs: Array, p: Vector3, noise: FastNoiseLite) -> float:
	var nv := noise.get_noise_3d(p.x, p.y, p.z)
	var d := 50.0
	for f in fs:
		if (f["bb"] as AABB).grow(0.5).has_point(p):
			d = minf(d, Field.feat_sdf(f, p, nv))
	return d


static func grad(fs: Array, p: Vector3, noise: FastNoiseLite) -> Vector3:
	var e := 0.2
	return Vector3(sdf(fs, p + Vector3(e, 0, 0), noise) - sdf(fs, p - Vector3(e, 0, 0), noise),
		sdf(fs, p + Vector3(0, e, 0), noise) - sdf(fs, p - Vector3(0, e, 0), noise),
		sdf(fs, p + Vector3(0, 0, e), noise) - sdf(fs, p - Vector3(0, 0, e), noise)).normalized()


## March from an air point along dir; returns {p, n} of the first rock hit or {}.
static func march(fs: Array, from: Vector3, dir: Vector3, max_d: float, noise: FastNoiseLite) -> Dictionary:
	if sdf(fs, from, noise) > -0.1:
		return {}
	var t := 0.0
	var prev := 0.0
	while t < max_d:
		t += 0.3
		var d := sdf(fs, from + dir * t, noise)
		if d > 0.0:
			var lo := prev
			var hi := t
			for k in 6:
				var mid := (lo + hi) * 0.5
				if sdf(fs, from + dir * mid, noise) > 0.0:
					hi = mid
				else:
					lo = mid
			var hp := from + dir * hi
			return {"p": hp, "n": -grad(fs, hp, noise)}
		prev = t
	return {}


## One chunk column of the lattice. Same scheme as L008: one extra layer on the
## low sides, quads only for edges the chunk owns, so seams are watertight.
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

	## Signed distance of one feature at p (nv = noise value at p).
	static func feat_sdf(f: Dictionary, p: Vector3, nv: float) -> float:
		var amp: float = f.get("amp", 0.0)
		if str(f["t"]) == "tube":
			var a: Vector3 = f["a"]
			var ab: Vector3 = (f["b"] as Vector3) - a
			var tt := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
			var q := p - (a + ab * tt)
			q.y /= float(f.get("sq", 1.0))
			var s := q.length() - lerpf(f["ra"], f["rb"], tt) + nv * amp
			if f.has("fa"):
				s = maxf(s, lerpf(f["fa"], f["fb"], tt) + nv * float(f.get("fn", 0.0)) - p.y)
			return s
		var c: Vector3 = f["c"]
		var r: Vector3 = f["r"]
		var s2 := (((p - c) / r).length() - 1.0) * minf(r.x, minf(r.y, r.z)) + nv * amp
		if f.has("f"):
			s2 = maxf(s2, float(f["f"]) + nv * float(f.get("fn", 0.0)) - p.y)
		return s2

	func _rng(lo: float, hi: float, g0: int, n: int) -> Vector2i:
		return Vector2i(clampi(int(floor(lo / H)) - g0, 0, n - 1), clampi(int(ceil(hi / H)) - g0, 0, n - 1))

	func carve(f: Dictionary) -> void:
		var bb: AABB = f["bb"]
		var rx := _rng(bb.position.x, bb.end.x, gx0, nx)
		var ry := _rng(bb.position.y, bb.end.y, gy0, ny)
		var rz := _rng(bb.position.z, bb.end.z, gz0, nz)
		for z in range(rz.x, rz.y + 1):
			for y in range(ry.x, ry.y + 1):
				for x in range(rx.x, rx.y + 1):
					var k := x + nx * (y + ny * z)
					var p := Vector3((gx0 + x) * H, (gy0 + y) * H, (gz0 + z) * H)
					d[k] = minf(d[k], feat_sdf(f, p, nn[k]))

	func clamp_all() -> void:
		for k in d.size():
			d[k] = clampf(d[k], -CLAMP, CLAMP)

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


## A lofted crawl tube with a flat floor. path: floor points; prof(t) -> Vector2(half width,
## crest height) along the normalised length t. Faces point inward.
static func loft(a: Acc, fl: Acc, path: Array, prof: Callable, noise: FastNoiseLite, ring_step: float = 0.35) -> void:
	var pts: Array = []
	for i in path.size() - 1:
		var p0: Vector3 = path[i]
		var p1: Vector3 = path[i + 1]
		var n := maxi(1, ceili(p0.distance_to(p1) / ring_step))
		for s in n:
			pts.append(p0.lerp(p1, float(s) / n))
	pts.append(path[path.size() - 1])
	var total := 0.0
	var acc_len: Array = [0.0]
	for i in range(1, pts.size()):
		total += (pts[i] as Vector3).distance_to(pts[i - 1])
		acc_len.append(total)
	var K := 16
	var b0 := a.v.size()
	var f0 := fl.v.size()
	for j in pts.size():
		var c: Vector3 = pts[j]
		var tg: Vector3 = ((pts[mini(j + 1, pts.size() - 1)] as Vector3) - (pts[maxi(j - 1, 0)] as Vector3))
		tg.y = 0.0
		tg = tg.normalized()
		var side := tg.cross(Vector3.UP).normalized()
		var pr: Vector2 = prof.call(float(acc_len[j]) / total)
		for k in K:
			var th := TAU * float(k) / K
			var sx := cos(th)
			var sy := sin(th)
			var x := pr.x * sx
			var y := 0.0
			var nrm := Vector3.UP
			if sy > 0.0:
				var w := 1.0 + noise.get_noise_3d(c.x * 2.1, float(k) * 0.9, c.z * 2.1) * 0.16
				x *= w
				y = pr.y * sy * w
				nrm = -(side * (sx / pr.x) + Vector3.UP * (sy / pr.y)).normalized()
			else:
				y = noise.get_noise_2d(c.x * 3.0 + x, c.z * 3.0) * 0.03
			a.v.append(c + side * x + Vector3.UP * y)
			a.n.append(nrm)
			fl.v.append(c + side * x + Vector3.UP * y)
			fl.n.append(nrm)
	for j in pts.size() - 1:
		var axis: Vector3 = pts[j]
		for k in K:
			var k1 := (k + 1) % K
			var i0 := b0 + j * K + k
			var i1 := b0 + j * K + k1
			var i2 := b0 + (j + 1) * K + k1
			var i3 := b0 + (j + 1) * K + k
			var inward: Vector3 = axis + Vector3.UP * 0.5 - a.v[i0]
			var lo := sin(TAU * float(k) / K) <= 0.001 and sin(TAU * float(k1) / K) <= 0.001
			var dst: Acc = fl if lo else a
			var off := (f0 - b0) if lo else 0
			if (a.v[i1] - a.v[i0]).cross(a.v[i2] - a.v[i0]).dot(inward) > 0.0:
				dst.i.append_array([i0 + off, i2 + off, i1 + off, i0 + off, i3 + off, i2 + off])
			else:
				dst.i.append_array([i0 + off, i1 + off, i2 + off, i0 + off, i2 + off, i3 + off])


## Stalactite: a jagged, slightly bent cone hanging from base b along dir.
static func spike(a: Acc, b: Vector3, dir: Vector3, length: float, radius: float, rng: RandomNumberGenerator) -> void:
	var segs := 6
	var rings := 4
	var bas := Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT)
	var bend := Vector3(rng.randf_range(-0.12, 0.12), rng.randf_range(-0.12, 0.12), 0.0)
	var b0 := a.v.size()
	for r in rings:
		var t := float(r) / rings
		var c := b + bas * (Vector3(0, 0, -length * t) + bend * length * t * t)
		var rad := radius * pow(1.0 - t, 1.3) * rng.randf_range(0.85, 1.15)
		for j in segs:
			var ang := TAU * j / segs + t * 0.6
			a.v.append(c + bas * Vector3(cos(ang) * rad, sin(ang) * rad, 0.0))
			a.n.append((bas * Vector3(cos(ang), sin(ang), 0.2)).normalized())
	a.v.append(b + bas * (Vector3(0, 0, -length) + bend * length))
	a.n.append(dir)
	for r in rings - 1:
		for j in segs:
			var j1 := (j + 1) % segs
			var i0 := b0 + r * segs + j
			var i1 := b0 + r * segs + j1
			var i2 := b0 + (r + 1) * segs + j1
			var i3 := b0 + (r + 1) * segs + j
			var out: Vector3 = a.n[i0]
			if (a.v[i1] - a.v[i0]).cross(a.v[i2] - a.v[i0]).dot(out) > 0.0:
				a.i.append_array([i0, i2, i1, i0, i3, i2])
			else:
				a.i.append_array([i0, i1, i2, i0, i2, i3])
	var lt := b0 + (rings - 1) * segs
	var ti := a.v.size() - 1
	for j in segs:
		var i0 := lt + j
		var i1 := lt + (j + 1) % segs
		if (a.v[i1] - a.v[i0]).cross(a.v[ti] - a.v[i0]).dot(a.n[i0]) > 0.0:
			a.i.append_array([i0, ti, i1])
		else:
			a.i.append_array([i0, i1, ti])
