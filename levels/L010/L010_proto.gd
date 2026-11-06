extends RefCounted
## Level 10 mesh builder and prototype meshes instanced by L010_geo.gd: crop
## stalk clumps (wheat with upright ears, barley with nodding awned heads,
## canola with yellow flower heads), grass tufts, lumpy crown blobs, a tapered
## trunk and a soil worm. Vertex colours carry the crop colour.

class MB:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var c := PackedColorArray()
	var uv := PackedVector2Array()
	var i := PackedInt32Array()

	func vert(p: Vector3, nn: Vector3, col: Color = Color.WHITE, t: Vector2 = Vector2.ZERO) -> int:
		v.append(p)
		n.append(nn)
		c.append(col)
		uv.append(t)
		return v.size() - 1

	## Two triangles a-b-c-d whose front side looks along `face`.
	func quad(a: int, b: int, cc: int, d: int, face: Vector3) -> void:
		if (v[b] - v[a]).cross(v[cc] - v[a]).dot(face) > 0.0:
			i.append_array([a, cc, b, a, d, cc])
		else:
			i.append_array([a, b, cc, a, cc, d])

	func tri(a: int, b: int, cc: int, face: Vector3) -> void:
		if (v[b] - v[a]).cross(v[cc] - v[a]).dot(face) > 0.0:
			i.append_array([a, cc, b])
		else:
			i.append_array([a, b, cc])

	func mesh() -> ArrayMesh:
		if i.is_empty():
			return null
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = v
		arr[Mesh.ARRAY_NORMAL] = n
		arr[Mesh.ARRAY_COLOR] = c
		arr[Mesh.ARRAY_TEX_UV] = uv
		arr[Mesh.ARRAY_INDEX] = i
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		return am

	func inst(parent: Node3D, mat: String, shadow: bool = true) -> MeshInstance3D:
		var m := mesh()
		if m == null:
			return null
		var mi := MeshInstance3D.new()
		mi.mesh = m
		mi.material_override = MatLib.get_mat(mat)
		if not shadow:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		return mi


static func blade(mb: MB, a: Vector3, b: Vector3, hw: float, side: Vector3, col: Color, tip: float = 0.5) -> void:
	var nrm := side.cross(b - a).normalized()
	var i0 := mb.vert(a - side * hw, nrm, col * 0.8, Vector2(0, 0))
	mb.vert(a + side * hw, nrm, col * 0.8, Vector2(1, 0))
	mb.vert(b + side * hw * tip, nrm, col, Vector2(1, 1))
	mb.vert(b - side * hw * tip, nrm, col, Vector2(0, 1))
	mb.quad(i0, i0 + 1, i0 + 2, i0 + 3, nrm)


static func clump(kind: int) -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = 900 + kind
	var mb := MB.new()
	var n := 8 if kind < 3 else (5 if kind == 3 else 12)
	for s in n:
		if kind == 4:
			var ta := r.randf() * TAU
			var tb := Vector3(cos(ta), 0, sin(ta)) * r.randf_range(0.0, 0.08)
			var tl := Vector3(cos(ta), 0, sin(ta)) * r.randf_range(0.05, 0.16)
			var tc := Color(0.3, 0.36, 0.15).lerp(Color(0.48, 0.46, 0.26), r.randf() * r.randf())
			tc.a = 0.25
			blade(mb, tb, tb + tl + Vector3(0, r.randf_range(0.12, 0.3), 0), 0.01, Vector3(-tl.z, 0, tl.x).normalized(), tc, 0.15)
			continue
		var a := r.randf() * TAU
		var rad := sqrt(r.randf()) * 0.24
		var base := Vector3(cos(a) * rad, 0, sin(a) * rad)
		var h := r.randf_range(0.8, 1.0) if kind == 1 else (r.randf_range(0.68, 0.84) if kind == 2 else r.randf_range(1.0, 1.3))
		var lean := Vector3(r.randf_range(-0.08, 0.08), 0, r.randf_range(-0.08, 0.08))
		var top := base + lean + Vector3(0, h, 0)
		var yaw := r.randf() * PI
		var side := Vector3(cos(yaw), 0, sin(yaw))
		var side2 := Vector3(-side.z, 0, side.x)
		var v := r.randf_range(0.85, 1.12)
		match kind:
			1:
				blade(mb, base, top, 0.008, side, Color(0.56, 0.47, 0.28) * v)
				var e := top + (top - base).normalized() * 0.1
				blade(mb, top, e, 0.018, side, Color(0.8, 0.63, 0.34) * v, 0.6)
				blade(mb, top, e, 0.018, side2, Color(0.74, 0.58, 0.31) * v, 0.6)
				blade(mb, base + Vector3(0, 0.25, 0), base + Vector3(0, 0.45, 0) + side2 * 0.18, 0.012, side, Color(0.6, 0.52, 0.32) * v)
			2:
				blade(mb, base, top, 0.008, side, Color(0.6, 0.56, 0.36) * v)
				var nod := (Vector3(lean.x, 0, lean.z).normalized() * 0.75 + Vector3(0, -0.55, 0)).normalized()
				var e := top + nod * 0.075
				blade(mb, top, e, 0.016, side, Color(0.74, 0.68, 0.45) * v, 0.7)
				blade(mb, e, e + nod * 0.11 + Vector3(0, -0.02, 0), 0.03, side2, Color(0.84, 0.8, 0.6) * v, 1.4)
			3:
				blade(mb, base, top, 0.01, side, Color(0.3, 0.38, 0.14) * v)
				blade(mb, base + Vector3(0, 0.3, 0), base + Vector3(0, 0.55, 0) + side2 * 0.25, 0.05, side, Color(0.24, 0.34, 0.11) * v)
				for f in 7:
					var c := top + Vector3(r.randf_range(-0.08, 0.08), r.randf_range(-0.14, 0.03), r.randf_range(-0.08, 0.08))
					var u := Vector3(r.randf_range(0.03, 0.045), 0, 0)
					var q := Vector3(0, 0.012, r.randf_range(0.03, 0.045))
					var i0 := mb.vert(c - u - q, Vector3.UP, Color(0.95, 0.78, 0.07) * v)
					mb.vert(c + u - q, Vector3.UP, Color(0.95, 0.8, 0.08) * v)
					mb.vert(c + u + q, Vector3.UP, Color(0.98, 0.84, 0.1) * v)
					mb.vert(c - u + q, Vector3.UP, Color(0.9, 0.74, 0.06) * v)
					mb.quad(i0, i0 + 1, i0 + 2, i0 + 3, Vector3.UP)
	return mb.mesh()


static func blob(sub: int, sd: int) -> ArrayMesh:
	var t := (1.0 + sqrt(5.0)) * 0.5
	var vs: Array = [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0), Vector3(0, -1, t), Vector3(0, 1, t),
		Vector3(0, -1, -t), Vector3(0, 1, -t), Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	var fs: Array = [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]]
	for i in vs.size():
		vs[i] = (vs[i] as Vector3).normalized()
	for s in sub:
		var cache := {}
		var nf: Array = []
		for f in fs:
			var m: Array = []
			for e in 3:
				var a: int = f[e]
				var b: int = f[(e + 1) % 3]
				var key := Vector2i(mini(a, b), maxi(a, b))
				if not cache.has(key):
					vs.append(((vs[a] as Vector3) + vs[b]).normalized())
					cache[key] = vs.size() - 1
				m.append(cache[key])
			nf.append_array([[f[0], m[0], m[2]], [f[1], m[1], m[0]], [f[2], m[2], m[1]], [m[0], m[1], m[2]]])
		fs = nf
	var r := RandomNumberGenerator.new()
	r.seed = sd
	var mb := MB.new()
	for v in vs:
		var p: Vector3 = v * r.randf_range(0.8, 1.12)
		if p.y < 0.0:
			p.y *= 0.7
		mb.vert(p, (v as Vector3), Color.WHITE)
	for f in fs:
		var c: Vector3 = (vs[f[0]] + vs[f[1]] + vs[f[2]])
		mb.tri(f[0], f[1], f[2], c)
	return mb.mesh()


static func trunk() -> ArrayMesh:
	var mb := MB.new()
	for k in 6:
		var a0 := TAU * k / 6.0
		var a1 := TAU * (k + 1) / 6.0
		var p0 := Vector3(cos(a0), 0, sin(a0))
		var p1 := Vector3(cos(a1), 0, sin(a1))
		var i0 := mb.vert(p0, p0)
		mb.vert(p1, p1)
		mb.vert(p1 * 0.55 + Vector3.UP, p1)
		mb.vert(p0 * 0.55 + Vector3.UP, p0)
		mb.quad(i0, i0 + 1, i0 + 2, i0 + 3, p0 + p1)
	return mb.mesh()


static func worm() -> ArrayMesh:
	var mb := MB.new()
	var segs := 7
	for s in segs + 1:
		var z := -0.12 + 0.24 * s / segs
		var rad := 0.011 * (1.0 - absf(z) / 0.16)
		for q in 4:
			var a := TAU * q / 4.0
			var nn := Vector3(cos(a), sin(a), 0)
			mb.vert(Vector3(0, 0.012, z) + nn * rad, nn, Color.WHITE, Vector2(q / 4.0, z))
	for s in segs:
		for q in 4:
			var a := s * 4 + q
			var b := s * 4 + (q + 1) % 4
			mb.quad(a, b, b + 4, a + 4, mb.n[a] + mb.n[b])
	return mb.mesh()
