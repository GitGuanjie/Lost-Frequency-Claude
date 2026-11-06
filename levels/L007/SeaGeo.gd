extends RefCounted
## Level 7 geometry helpers (meshes only; rules live in L007.gd): the seamount
## heightfield, displaced rock blobs, a surface-nets SDF mesher (cave outcrop),
## bone props, the furnished entrance room and the sideways-sea material.
## Ocean frame: water surface at y = SEA (lifted 300 m because the shared
## player controller kills anything below y = -400), ceiling underside SEA+4.5.
## Depth zone constants Z_* are relative to the surface.

const SEA := 300.0
const AX := 14.0                 # seamount axis: almost directly below the doorway
const AZ := 22.0
const SUMMIT := SEA - 165.0
const FLOOR := SEA - 640.0            # carpeted abyss floor
const R := 330.0
const RIDGE_TH := 0.0            # one ridge runs east, down to the cave outcrop
const ROOM := Vector3(0.0, SEA + 60.0, 0.0)        # walkable entrance room (own frame)
const DOOR := Vector3(0.0, SEA + 4.5, 0.0)         # hatch in the ocean ceiling
const RING := Vector3(-150.0, SEA - 150.0, 6.0)   # Level 9 platform: ~150 m west, ~150 m down
const FORT := Vector3(185.0, SEA, -235.0)    # Fort Surrender island
const Z_DAY := -180.0
const Z_TWI := -320.0
const Z_MID := -500.0
const CS := 150.0

var hn := FastNoiseLite.new()    # fixed seed: the seamount is an authored anchor
var bn := FastNoiseLite.new()


func _init() -> void:
	hn.seed = 7007
	hn.frequency = 0.012
	hn.fractal_octaves = 4
	bn.seed = 77
	bn.frequency = 1.0
	bn.fractal_octaves = 3


class Acc:
	var v := PackedVector3Array()
	var n := PackedVector3Array()
	var i := PackedInt32Array()


# ------------------------------------------------------------- seamount

static func _lobe(th: float, c: float, w: float) -> float:
	var d := wrapf(th - c, -PI, PI) / w
	return exp(-d * d)


func mount_y(x: float, z: float) -> float:
	var dx := x - AX
	var dz := z - AZ
	var r := sqrt(dx * dx + dz * dz)
	var t := clampf((sqrt(r * r + 900.0) - 30.0) / R, 0.0, 1.0)
	if t >= 1.0:
		return FLOOR
	var th := atan2(dz, dx)
	var bell := sin(PI * t)
	var y := SUMMIT - (SUMMIT - FLOOR) * (1.0 - pow(1.0 - t, 2.2))
	y += 34.0 * _lobe(th, RIDGE_TH, 0.15) * bell
	y += 20.0 * (_lobe(th, 2.1, 0.22) + _lobe(th, 3.6, 0.2) + _lobe(th, 4.9, 0.25)) * bell
	y += hn.get_noise_2d(x, z) * 12.0 * minf(1.0, t * 4.0) * (1.0 - t * t)
	return maxf(y, FLOOR)


func mount_n(x: float, z: float) -> Vector3:
	var e := 1.5
	return Vector3(mount_y(x - e, z) - mount_y(x + e, z), 2.0 * e, mount_y(x, z - e) - mount_y(x, z + e)).normalized()


## Depth on the east ridge where the mountain surface reaches y.
func ridge_r_at(y: float) -> float:
	var lo := 0.0
	var hi := 360.0
	for it in 40:
		var m := (lo + hi) * 0.5
		if mount_y(AX + m, AZ) > y:
			lo = m
		else:
			hi = m
	return (lo + hi) * 0.5


func seamount(nr: int = 64, ns: int = 160, r_out: float = 420.0) -> Acc:
	var a := Acc.new()
	a.v.append(Vector3(AX, mount_y(AX, AZ), AZ))
	a.n.append(Vector3.UP)
	for ri in nr + 1:
		var r := 2.0 + (r_out - 2.0) * pow(float(ri) / nr, 1.3)
		for j in ns:
			var th := TAU * j / ns
			var x := AX + cos(th) * r
			var z := AZ + sin(th) * r
			a.v.append(Vector3(x, mount_y(x, z), z))
			a.n.append(mount_n(x, z))
	for j in ns:
		_tri(a, 0, 1 + j, 1 + (j + 1) % ns, Vector3.UP)
	for ri in nr:
		for j in ns:
			var p := 1 + ri * ns
			var q := 1 + (ri + 1) * ns
			quad(a, p + j, p + (j + 1) % ns, q + (j + 1) % ns, q + j, Vector3.UP)
	return a


# ------------------------------------------------------------ primitives

## Front faces in Godot are clockwise seen from the front: (b-a)x(c-a)·n < 0.
static func _tri(a: Acc, i0: int, i1: int, i2: int, n: Vector3) -> void:
	if (a.v[i1] - a.v[i0]).cross(a.v[i2] - a.v[i0]).dot(n) > 0.0:
		a.i.append_array([i0, i2, i1])
	else:
		a.i.append_array([i0, i1, i2])


static func quad(a: Acc, i0: int, i1: int, i2: int, i3: int, n: Vector3) -> void:
	if (a.v[i1] - a.v[i0]).cross(a.v[i2] - a.v[i0]).dot(n) > 0.0:
		a.i.append_array([i0, i2, i1, i0, i3, i2])
	else:
		a.i.append_array([i0, i1, i2, i0, i2, i3])


static func smooth_normals(a: Acc, from_v: int, from_i: int) -> void:
	var acc := PackedVector3Array()
	acc.resize(a.v.size() - from_v)
	for k in range(from_i, a.i.size(), 3):
		var i0 := a.i[k]
		var i1 := a.i[k + 1]
		var i2 := a.i[k + 2]
		var fn := -(a.v[i1] - a.v[i0]).cross(a.v[i2] - a.v[i0])
		acc[i0 - from_v] += fn
		acc[i1 - from_v] += fn
		acc[i2 - from_v] += fn
	for k in acc.size():
		var nn := acc[k].normalized()
		if a.n.size() > from_v + k:
			a.n[from_v + k] = nn
		else:
			a.n.append(nn)


## Displaced lat-long rock blob (islands, tar piles, boulders).
func blob(a: Acc, c: Vector3, radii: Vector3, rough: float, freq: float, off: float, rings: int = 14, segs: int = 22, flat_y: float = -1e9) -> void:
	var b0 := a.v.size()
	var i0 := a.i.size()
	var pts := [Vector3.UP]
	for ri in range(1, rings):
		var ph := PI * ri / rings
		for j in segs:
			var th := TAU * j / segs
			pts.append(Vector3(sin(ph) * cos(th), cos(ph), sin(ph) * sin(th)))
	pts.append(Vector3.DOWN)
	for d in pts:
		var k := 1.0 + rough * bn.get_noise_3d(d.x * freq + off, d.y * freq * 1.3, d.z * freq - off)
		var p: Vector3 = c + d * radii * k
		p.y = maxf(p.y, flat_y)
		a.v.append(p)
	var last := b0 + pts.size() - 1
	for j in segs:
		var j1 := (j + 1) % segs
		_tri(a, b0, b0 + 1 + j, b0 + 1 + j1, Vector3.UP)
		var lr := b0 + 1 + (rings - 2) * segs
		_tri(a, last, lr + j1, lr + j, Vector3.DOWN)
	for ri in rings - 2:
		for j in segs:
			var j1 := (j + 1) % segs
			var p0 := b0 + 1 + ri * segs
			var p1 := p0 + segs
			var out: Vector3 = (a.v[p0 + j] - c).normalized()
			quad(a, p0 + j, p0 + j1, p1 + j1, p1 + j, out)
	smooth_normals(a, b0, i0)


func blob_pole_y(c: Vector3, ry: float, rough: float, freq: float, off: float) -> float:
	return c.y + ry * (1.0 + rough * bn.get_noise_3d(off, freq * 1.3, -off))


static func commit(parent: Node3D, a: Acc, mat: String, collide: bool, surface: String = "concrete", shadows: bool = false) -> MeshInstance3D:
	if a.i.is_empty():
		return null
	var uv := PackedVector2Array()
	uv.resize(a.v.size())
	for k in a.v.size():
		uv[k] = Vector2(a.v[k].x, a.v[k].z) * 0.25
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = a.v
	arr[Mesh.ARRAY_NORMAL] = a.n
	arr[Mesh.ARRAY_TEX_UV] = uv
	arr[Mesh.ARRAY_INDEX] = a.i
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	mi.material_override = MatLib.get_mat(mat)
	if not shadows:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
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


# ------------------------------------------------- SDF grid (surface nets)

## Density grid: > 0 solid rock, < 0 water/air. Naive surface nets mesher.
class Grid:
	var o := Vector3.ZERO
	var h := 1.0
	var nx := 0
	var ny := 0
	var nz := 0
	var d := PackedFloat32Array()
	var nz_n := PackedFloat32Array()

	func _init(origin: Vector3, cell: float, size: Vector3, fill: float, noise: FastNoiseLite) -> void:
		o = origin
		h = cell
		nx = int(ceil(size.x / h)) + 1
		ny = int(ceil(size.y / h)) + 1
		nz = int(ceil(size.z / h)) + 1
		d.resize(nx * ny * nz)
		d.fill(fill)
		nz_n.resize(nx * ny * nz)
		var k := 0
		for z in nz:
			for y in ny:
				for x in nx:
					nz_n[k] = noise.get_noise_3d(o.x + x * h, o.y + y * h, o.z + z * h)
					k += 1

	func _range(lo: float, hi: float, base: float, n: int) -> Vector2i:
		return Vector2i(clampi(int(floor((lo - base) / h)), 0, n - 1), clampi(int(ceil((hi - base) / h)), 0, n - 1))

	## Add a noisy solid ellipsoid.
	func solid_ellipsoid(c: Vector3, rad: Vector3, amp: float) -> void:
		var m := rad + Vector3.ONE * (amp + h)
		var rx := _range(c.x - m.x, c.x + m.x, o.x, nx)
		var ry := _range(c.y - m.y, c.y + m.y, o.y, ny)
		var rz := _range(c.z - m.z, c.z + m.z, o.z, nz)
		var rmin := minf(rad.x, minf(rad.y, rad.z))
		for z in range(rz.x, rz.y + 1):
			for y in range(ry.x, ry.y + 1):
				for x in range(rx.x, rx.y + 1):
					var p := Vector3(o.x + x * h, o.y + y * h, o.z + z * h)
					var k := x + nx * (y + ny * z)
					var s := (((p - c) / rad).length() - 1.0) * rmin + nz_n[k] * amp
					d[k] = maxf(d[k], -s)

	## Carve a noisy tapered capsule a->b (radii ra->rb).
	func air_capsule(a: Vector3, b: Vector3, ra: float, rb: float, amp: float) -> void:
		var m := maxf(ra, rb) + amp + h
		var rx := _range(minf(a.x, b.x) - m, maxf(a.x, b.x) + m, o.x, nx)
		var ry := _range(minf(a.y, b.y) - m, maxf(a.y, b.y) + m, o.y, ny)
		var rz := _range(minf(a.z, b.z) - m, maxf(a.z, b.z) + m, o.z, nz)
		var ab := b - a
		var l2 := maxf(ab.length_squared(), 0.0001)
		for z in range(rz.x, rz.y + 1):
			for y in range(ry.x, ry.y + 1):
				for x in range(rx.x, rx.y + 1):
					var p := Vector3(o.x + x * h, o.y + y * h, o.z + z * h)
					var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
					var k := x + nx * (y + ny * z)
					var s := p.distance_to(a + ab * t) - lerpf(ra, rb, t) + nz_n[k] * amp
					d[k] = minf(d[k], s)

	func mesh(acc: Acc) -> void:
		var vid := PackedInt32Array()
		vid.resize(nx * ny * nz)
		vid.fill(-1)
		var sx := 1
		var sy := nx
		var sz := nx * ny
		var corner := [0, sx, sy, sx + sy, sz, sx + sz, sy + sz, sx + sy + sz]
		var cpos := [Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(1, 1, 0), Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(0, 1, 1), Vector3(1, 1, 1)]
		var edges := [0, 1, 2, 3, 4, 5, 6, 7, 0, 2, 1, 3, 4, 6, 5, 7, 0, 4, 1, 5, 2, 6, 3, 7]
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
					vid[base] = acc.v.size()
					acc.v.append(o + (Vector3(x, y, z) + sum / cnt) * h)
					acc.n.append(-g.normalized())
		# quads across every sign-changing grid edge
		for z in range(1, nz - 1):
			for y in range(1, ny - 1):
				for x in range(1, nx - 1):
					var p := x + sy * y + sz * z
					var d0 := d[p]
					for ax in 3:
						var st: int = [sx, sy, sz][ax]
						var d1 := d[p + st]
						if (d0 > 0.0) == (d1 > 0.0):
							continue
						var u: int = [sy, sx, sx][ax]
						var w: int = [sz, sz, sy][ax]
						var q0 := vid[p - u - w]
						var q1 := vid[p - w]
						var q2 := vid[p]
						var q3 := vid[p - u]
						if q0 < 0 or q1 < 0 or q2 < 0 or q3 < 0:
							continue
						var nrm := Vector3.ZERO
						nrm[ax] = 1.0 if d0 > 0.0 else -1.0
						Acc_quad(acc, q0, q1, q2, q3, nrm)

	static func Acc_quad(a: Acc, i0: int, i1: int, i2: int, i3: int, n: Vector3) -> void:
		if (a.v[i1] - a.v[i0]).cross(a.v[i2] - a.v[i0]).dot(n) > 0.0:
			a.i.append_array([i0, i2, i1, i0, i3, i2])
		else:
			a.i.append_array([i0, i1, i2, i0, i2, i3])


# ------------------------------------------------------------------ bones

## Humanoid skeleton lying in local +Z (head) with large toothed jaws and
## flipper feet (as the page describes). erosion = fraction of bones missing.
static func humanoid(k: GeoKit, xf: Transform3D, rng: RandomNumberGenerator, mat: String, s: float, erosion: float) -> void:
	var bones: Array = []
	for i in 10:
		bones.append([Vector3(0, 0.05, 0.08 + i * 0.065), Vector3(0.05, 0.05, 0.045), Vector3.ZERO])
	for i in 6:
		var z := 0.3 + i * 0.07
		for sd in [-1.0, 1.0]:
			bones.append([Vector3(sd * 0.09, 0.07, z), Vector3(0.13, 0.022, 0.022), Vector3(0, 0, sd * 0.55)])
			bones.append([Vector3(sd * 0.16, 0.16, z), Vector3(0.022, 0.13, 0.022), Vector3(0, 0, sd * 0.2)])
	bones.append([Vector3(0, 0.05, 0.0), Vector3(0.3, 0.07, 0.13), Vector3.ZERO])
	bones.append([Vector3(0, 0.11, 0.86), Vector3(0.21, 0.19, 0.24), Vector3.ZERO])
	bones.append([Vector3(0, 0.03, 1.0), Vector3(0.17, 0.045, 0.38), Vector3(-0.12, 0, 0)])
	for t in 9:
		var tz := 0.88 + t * 0.033
		for sd in [-1.0, 1.0]:
			bones.append([Vector3(sd * 0.07, 0.08, tz), Vector3(0.012, 0.075, 0.012), Vector3(0.2, 0, 0)])
	for sd in [-1.0, 1.0]:
		var aa := rng.randf_range(-0.6, 0.9)
		bones.append([Vector3(sd * 0.3, 0.06, 0.62), Vector3(0.04, 0.04, 0.3), Vector3(0, sd * aa, 0)])
		bones.append([Vector3(sd * (0.42 + aa * 0.1), 0.05, 0.4), Vector3(0.035, 0.035, 0.28), Vector3(0, sd * (aa + 0.4), 0)])
		bones.append([Vector3(sd * 0.11, 0.05, -0.24), Vector3(0.045, 0.045, 0.44), Vector3(0, sd * 0.1, 0)])
		bones.append([Vector3(sd * 0.14, 0.05, -0.66), Vector3(0.038, 0.038, 0.4), Vector3(0, sd * 0.05, 0)])
		for f in 5:
			bones.append([Vector3(sd * 0.15 + (f - 2) * 0.04, 0.03, -1.02), Vector3(0.016, 0.014, 0.4), Vector3(0, (f - 2) * 0.14, 0)])
		bones.append([Vector3(sd * 0.15, 0.025, -1.0), Vector3(0.2, 0.01, 0.3), Vector3.ZERO])
	for b in bones:
		if rng.randf() < erosion:
			continue
		var bx := Transform3D(Basis.from_euler(b[2]), b[0] * s)
		k.box_xf(xf * bx, b[1] * s, mat, GeoKit.ALL, false)


## Skeleton of a large unearthly fish: curved spine, long ribs (some missing:
## bite marks), heavy skull, tail fan. Length in metres.
static func fish(k: GeoKit, xf: Transform3D, rng: RandomNumberGenerator, mat: String, length: float) -> void:
	var n := 16
	var sw := rng.randf_range(0.05, 0.15)
	for i in n:
		var t := float(i) / (n - 1)
		var z := (t - 0.5) * length
		var x := sin(t * PI * 1.5) * sw * length
		var vs := length * 0.03
		k.box_xf(xf * Transform3D(Basis(), Vector3(x, length * 0.05, z)), Vector3(vs, vs, length * 0.055), mat, GeoKit.ALL, false)
		if i > 2 and i < n - 4 and rng.randf() > 0.25:
			var rl := length * 0.22 * sin(t * PI)
			for sd in [-1.0, 1.0]:
				if rng.randf() < 0.15:
					continue
				var rb := Basis.from_euler(Vector3(0.0, 0.0, sd * 0.9))
				k.box_xf(xf * Transform3D(rb, Vector3(x + sd * rl * 0.4, length * 0.05 + rl * 0.25, z)), Vector3(length * 0.01, rl, length * 0.012), mat, GeoKit.ALL, false)
	var hs := length * 0.14
	k.box_xf(xf * Transform3D(Basis(), Vector3(0, length * 0.06, length * 0.55)), Vector3(hs, hs * 0.8, hs * 1.4), mat, GeoKit.ALL, false)
	k.box_xf(xf * Transform3D(Basis.from_euler(Vector3(-0.3, 0, 0)), Vector3(0, length * 0.02, length * 0.62)), Vector3(hs * 0.8, hs * 0.18, hs * 1.6), mat, GeoKit.ALL, false)
	for f in 6:
		var a := (f - 2.5) * 0.28
		k.box_xf(xf * Transform3D(Basis.from_euler(Vector3(a, 0, 0)), Vector3(0, length * 0.05, -length * 0.58)), Vector3(length * 0.008, length * 0.008, length * 0.16), mat, GeoKit.ALL, false)


## "Incomprehensible": a vast tangle of spines branching at wrong angles,
## ribs in every direction, several skulls.
static func tangle(k: GeoKit, origin: Vector3, rng: RandomNumberGenerator, mat: String, size: float) -> void:
	var stack: Array = [[origin, Vector3(rng.randf_range(-1, 1), rng.randf_range(0.1, 0.6), rng.randf_range(-1, 1)).normalized(), 26, size * 0.05]]
	var guard := 0
	while not stack.is_empty() and guard < 9:
		guard += 1
		var br: Array = stack.pop_back()
		var p: Vector3 = br[0]
		var dir: Vector3 = br[1]
		var vs: float = br[3]
		for i in int(br[2]):
			dir = (dir + Vector3(rng.randf_range(-0.35, 0.35), rng.randf_range(-0.25, 0.25), rng.randf_range(-0.35, 0.35))).normalized()
			var step := vs * 1.6
			var bas := Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT)
			k.box_xf(Transform3D(bas, p + dir * step * 0.5), Vector3(vs, vs, step * 0.85), mat, GeoKit.ALL, false)
			if rng.randf() < 0.7:
				var rdir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
				var rl := rng.randf_range(4.0, 10.0) * vs
				var rb := Basis.looking_at(rdir, Vector3.UP if absf(rdir.y) < 0.95 else Vector3.RIGHT)
				k.box_xf(Transform3D(rb, p + rdir * rl * 0.5), Vector3(vs * 0.3, vs * 0.3, rl), mat, GeoKit.ALL, false)
			if rng.randf() < 0.07 and stack.size() < 4:
				stack.append([p, (dir + Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.5, 0.8), rng.randf_range(-1, 1))).normalized(), 10 + rng.randi() % 10, vs * 0.8])
			if rng.randf() < 0.06:
				k.box_xf(Transform3D(bas, p), Vector3(vs * 5, vs * 4, vs * 7), mat, GeoKit.ALL, false)
				for t in 6:
					k.box_xf(Transform3D(bas, p + bas.z * (vs * (t - 2.5))), Vector3(vs * 0.3, vs * 3.0, vs * 0.3), mat, GeoKit.ALL, false)
			p += dir * step


# ---------------------------------------------------------- entrance room

## The furnished entrance room in its own frame (door wall at z = 0, room
## toward +z, floor y = 0). Built twice: walkable (collide) and as the sideways
## copy seen through the ceiling hatch from the ocean (visual only).
static func room(k: GeoKit, xf: Transform3D, collide: bool, rng: RandomNumberGenerator) -> void:
	var B := func(c: Vector3, s: Vector3, m: String, rot: Vector3 = Vector3.ZERO, surf: String = ""):
		k.box_xf(xf * Transform3D(Basis.from_euler(rot), c), s, m, GeoKit.ALL, collide, surf)
	B.call(Vector3(0, -0.15, 3.2), Vector3(5.8, 0.3, 7.0), "l7_carpet", Vector3.ZERO, "water")
	B.call(Vector3(0, 2.75, 3.2), Vector3(5.8, 0.3, 7.0), "l7_room_ceiling")
	B.call(Vector3(-2.75, 1.3, 3.2), Vector3(0.3, 2.9, 7.0), "l7_wall")
	B.call(Vector3(2.75, 1.3, 3.2), Vector3(0.3, 2.9, 7.0), "l7_wall")
	# door wall (z = 0) with the doorway to the ocean
	B.call(Vector3(-1.525, 1.3, -0.15), Vector3(2.15, 2.9, 0.3), "l7_wall")
	B.call(Vector3(1.525, 1.3, -0.15), Vector3(2.15, 2.9, 0.3), "l7_wall")
	B.call(Vector3(0, 2.375, -0.15), Vector3(0.9, 0.65, 0.3), "l7_wall")
	# back wall (z = 6.4) open to the staircase from Level 6
	B.call(Vector3(-1.7, 1.3, 6.55), Vector3(1.9, 2.9, 0.3), "l7_wall")
	B.call(Vector3(1.7, 1.3, 6.55), Vector3(1.9, 2.9, 0.3), "l7_wall")
	B.call(Vector3(0, 2.5, 6.55), Vector3(1.5, 0.4, 0.3), "l7_wall")
	# baseboards and door casing
	for bb in [[Vector3(-2.58, 0.06, 3.2), Vector3(0.04, 0.12, 6.4)], [Vector3(2.58, 0.06, 3.2), Vector3(0.04, 0.12, 6.4)],
			[Vector3(-1.5, 0.06, 0.02), Vector3(2.1, 0.12, 0.04)], [Vector3(1.5, 0.06, 0.02), Vector3(2.1, 0.12, 0.04)]]:
		k.box_xf(xf * Transform3D(Basis(), bb[0]), bb[1], "l7_wood", GeoKit.ALL, false)
	for cx in [-0.51, 0.51]:
		k.box_xf(xf * Transform3D(Basis(), Vector3(cx, 1.04, 0.03)), Vector3(0.1, 2.1, 0.06), "l7_wood", GeoKit.ALL, false)
	k.box_xf(xf * Transform3D(Basis(), Vector3(0, 2.1, 0.03)), Vector3(1.12, 0.1, 0.06), "l7_wood", GeoKit.ALL, false)
	# the door leaf stands open into the room, hinged on the right jamb
	B.call(Vector3(0.47, 1.02, 0.47), Vector3(0.04, 2.02, 0.88), "l7_wood", Vector3(0, 0.08, 0))
	# bookcase against the left wall, books of unknown origin
	var bx := -2.42
	for sv in [[Vector3(bx, 1.0, 1.55), Vector3(0.34, 2.0, 0.04)], [Vector3(bx, 1.0, 3.05), Vector3(0.34, 2.0, 0.04)],
			[Vector3(bx - 0.16, 1.0, 2.3), Vector3(0.02, 2.0, 1.5)], [Vector3(bx, 1.99, 2.3), Vector3(0.34, 0.04, 1.54)]]:
		B.call(sv[0], sv[1], "l7_wood")
	var books := ["l7_book_a", "l7_book_b", "l7_book_c", "l7_book_d"]
	for sh in 5:
		var y := 0.06 + sh * 0.39
		k.box_xf(xf * Transform3D(Basis(), Vector3(bx, y, 2.3)), Vector3(0.32, 0.03, 1.46), "l7_wood", GeoKit.ALL, false)
		var z := 1.6
		while z < 2.98:
			var w := rng.randf_range(0.025, 0.06)
			var hh := rng.randf_range(0.2, 0.31)
			var lean := 0.0 if rng.randf() > 0.12 else rng.randf_range(-0.35, 0.35)
			k.box_xf(xf * Transform3D(Basis.from_euler(Vector3(lean, 0, 0)), Vector3(bx + 0.02, y + 0.015 + hh * 0.5, z + w * 0.5)), Vector3(0.24, hh, w), books[rng.randi() % 4], GeoKit.ALL, false)
			z += w + (0.004 if rng.randf() > 0.08 else 0.12)
	# small coffee table
	B.call(Vector3(0.6, 0.43, 3.1), Vector3(1.0, 0.05, 0.56), "l7_wood")
	for lg in [Vector3(0.15, 0.2, 2.88), Vector3(1.05, 0.2, 2.88), Vector3(0.15, 0.2, 3.32), Vector3(1.05, 0.2, 3.32)]:
		k.box_xf(xf * Transform3D(Basis(), lg), Vector3(0.05, 0.41, 0.05), "l7_wood", GeoKit.ALL, false)
	# a single armchair facing the doorway
	var cxf := xf * Transform3D(Basis.from_euler(Vector3(0, 0.35, 0)), Vector3(1.55, 0, 4.3))
	k.box_xf(cxf * Transform3D(Basis(), Vector3(0, 0.27, 0.02)), Vector3(0.84, 0.3, 0.8), "l7_fabric", GeoKit.ALL, collide)
	k.box_xf(cxf * Transform3D(Basis(), Vector3(0, 0.47, -0.02)), Vector3(0.62, 0.12, 0.66), "l7_fabric", GeoKit.ALL, false)
	k.box_xf(cxf * Transform3D(Basis.from_euler(Vector3(-0.16, 0, 0)), Vector3(0, 0.78, 0.36)), Vector3(0.84, 0.66, 0.18), "l7_fabric", GeoKit.ALL, collide)
	k.box_xf(cxf * Transform3D(Basis.from_euler(Vector3(-0.16, 0, 0)), Vector3(0, 1.1, 0.42)), Vector3(0.74, 0.1, 0.14), "l7_fabric", GeoKit.ALL, false)
	for sd in [-1.0, 1.0]:
		k.box_xf(cxf * Transform3D(Basis(), Vector3(sd * 0.36, 0.56, 0.02)), Vector3(0.14, 0.28, 0.8), "l7_fabric", GeoKit.ALL, collide)
		k.box_xf(cxf * Transform3D(Basis(), Vector3(sd * 0.36, 0.71, 0.0)), Vector3(0.16, 0.05, 0.84), "l7_fabric", GeoKit.ALL, false)
		for lz in [-0.33, 0.37]:
			k.box_xf(cxf * Transform3D(Basis(), Vector3(sd * 0.36, 0.06, lz)), Vector3(0.06, 0.12, 0.06), "l7_wood", GeoKit.ALL, false)
	# fluorescent ceiling lamp
	k.box_xf(xf * Transform3D(Basis(), Vector3(0, 2.565, 3.2)), Vector3(0.3, 0.07, 1.3), "l7_metal", GeoKit.ALL, false)
	var pc: Vector3 = xf * Vector3(0, 2.525, 3.2)
	k.quad(pc, xf.basis * Vector3.DOWN, xf.basis * Vector3(0.11, 0, 0), xf.basis * Vector3(0, 0, 0.6), "l7_panel", Vector2(1.0, 0.0), true)
	# staircase up toward Level 6, lost in darkness above
	var s0 := xf * Transform3D(Basis(), Vector3(0, 0, 6.45))
	for i in 18:
		var top := 0.19 * (i + 1)
		k.box_xf(s0 * Transform3D(Basis(), Vector3(0, top * 0.5, 0.27 * (i + 0.5))), Vector3(1.3, top, 0.27), "l7_concrete6", GeoKit.ALL, false)
	if collide:
		var a: Vector3 = xf * Vector3(0, 0.02, 6.45)
		var b: Vector3 = xf * Vector3(0, 0.19 * 18, 6.45 + 0.27 * 18)
		var zz := (b - a).normalized()
		var xx := Vector3.UP.cross(zz).normalized()
		k.add_box_shape(Transform3D(Basis(xx, zz.cross(xx), zz), (a + b) * 0.5 - zz.cross(xx) * 0.05), Vector3(1.3, 0.1, (b - a).length()), "concrete")
	for sx in [-0.8, 0.8]:
		B.call(Vector3(sx, 3.0, 9.0), Vector3(0.3, 6.6, 5.4), "l7_concrete6")
	B.call(Vector3(0, 6.45, 9.0), Vector3(1.9, 0.3, 5.4), "l7_concrete6")
	B.call(Vector3(0, 4.0, 11.55), Vector3(1.9, 8.0, 0.3), "l7_dark")


const NOISE_FN := """
float h2(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(i), h2(i + vec2(1, 0)), f.x), mix(h2(i + vec2(0, 1)), h2(i + vec2(1, 1)), f.x), f.y); }
float swell(vec2 p, float t) {
	return sin(dot(p, vec2(0.11, 0.05)) + t * 0.55) * 0.5 + sin(dot(p, vec2(-0.07, 0.13)) + t * 0.42) * 0.35
		+ sin(dot(p, vec2(0.23, -0.17)) + t * 0.9) * 0.15 + (vn(p * 0.35 + t * 0.1) - 0.5) * 0.6;
}
float ripple(vec2 p, float t) { return vn(p * 1.7 + vec2(t * 0.5, t * 0.3)) + 0.5 * vn(p * 4.1 - vec2(t * 0.7, -t * 0.4)); }
"""


## Ocean surface (both sides). Opaque so fog, lights and SSR apply: swell and
## ripples, a fake reflection of the grey ceiling haze at grazing angles, and
## seen from below a brighter rippled sheet that darkens outside Snell's window.
static func ocean_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;
uniform vec3 deep : source_color = vec3(0.03, 0.05, 0.062);
uniform vec3 haze : source_color = vec3(0.3, 0.34, 0.37);
uniform vec3 below : source_color = vec3(0.3, 0.44, 0.48);
uniform float amp = 0.24;
varying vec3 wp;
""" + NOISE_FN + """
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	VERTEX.y += swell(wp.xz, TIME) * amp;
}
void fragment() {
	float t = TIME;
	float e = 0.2;
	float h0 = swell(wp.xz, t);
	float r0 = ripple(wp.xz, t);
	vec3 n = normalize(vec3((h0 - swell(wp.xz + vec2(e, 0.0), t)) / e * amp * 1.6 + (r0 - ripple(wp.xz + vec2(0.05, 0.0), t)) * 1.2,
		1.0, (h0 - swell(wp.xz + vec2(0.0, e), t)) / e * amp * 1.6 + (r0 - ripple(wp.xz + vec2(0.0, 0.05), t)) * 1.2));
	vec3 vnrm = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	vec3 V = normalize(-VERTEX);
	if (FRONT_FACING) {
		NORMAL = vnrm;
		float f = 0.03 + 0.97 * pow(1.0 - clamp(dot(V, vnrm), 0.0, 1.0), 5.0);
		ALBEDO = deep;
		ROUGHNESS = 0.06;
		SPECULAR = 0.55;
		EMISSION = haze * f * 0.85 + deep * 0.15;
	} else {
		NORMAL = -vnrm;
		float w = smoothstep(0.35, 0.8, dot(V, -vnrm));
		ALBEDO = below * 0.2;
		ROUGHNESS = 0.3;
		EMISSION = below * (0.08 + 0.55 * w) * (0.75 + 0.5 * r0);
	}
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


## Sideways sea: the ocean surface seen face-on through the doorway (the room
## is built sideways into the ocean ceiling): dark swell, the warm pool the
## hatch lamp throws on the water, ripples. Shader source kept in-script.
static func sideways_sea_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;
uniform vec3 deep : source_color = vec3(0.03, 0.05, 0.062);
uniform vec3 warm : source_color = vec3(0.9, 0.78, 0.55);
uniform vec3 haze : source_color = vec3(0.3, 0.34, 0.37);
varying vec3 lp;
""" + NOISE_FN + """
void vertex() { lp = VERTEX; }
void fragment() {
	float t = TIME;
	vec2 p = vec2(lp.y, lp.x) * 1.0;
	float h0 = swell(p, t);
	float r0 = ripple(p, t);
	float hx = swell(p + vec2(0.2, 0.0), t) + ripple(p + vec2(0.05, 0.0), t) * 0.3;
	float hy = swell(p + vec2(0.0, 0.2), t) + ripple(p + vec2(0.0, 0.05), t) * 0.3;
	NORMAL_MAP = normalize(vec3((h0 + r0 * 0.3 - hy) * 2.5, (h0 + r0 * 0.3 - hx) * 2.5, 1.0)) * 0.5 + 0.5;
	float d = length(lp.xy);
	float pool = exp(-d * d / 6.0);
	ALBEDO = deep;
	ROUGHNESS = 0.04;
	SPECULAR = 0.7;
	float sp = vn(p * 3.2 + vec2(t * 0.9, -t * 0.6)) * vn(p * 4.7 - vec2(t * 0.5, t * 0.8));
	float glint = smoothstep(0.5, 0.75, sp);
	float sw = h0 * 0.5 + 0.5;
	EMISSION = warm * pool * (0.04 + 0.5 * glint) + haze * (0.09 + 0.12 * sw + 0.3 * glint);
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


## Faint additive light shaft from the hatch down to the water (vertex-colour
## gradient, no texture).
static func shaft_mesh(top_hx: float, top_hz: float, bot_hx: float, bot_hz: float, top_y: float, bot_y: float, col: Color) -> MeshInstance3D:
	var v := PackedVector3Array()
	var c := PackedColorArray()
	var tc := [Vector3(-top_hx, top_y, -top_hz), Vector3(top_hx, top_y, -top_hz), Vector3(top_hx, top_y, top_hz), Vector3(-top_hx, top_y, top_hz)]
	var bc := [Vector3(-bot_hx, bot_y, -bot_hz), Vector3(bot_hx, bot_y, -bot_hz), Vector3(bot_hx, bot_y, bot_hz), Vector3(-bot_hx, bot_y, bot_hz)]
	var k := Color(0, 0, 0, 0)
	for i in 4:
		var j := (i + 1) % 4
		v.append_array(PackedVector3Array([tc[i], tc[j], bc[j], tc[i], bc[j], bc[i]]))
		c.append_array(PackedColorArray([col, col, k, col, k, k]))
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_COLOR] = c
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.vertex_color_use_as_albedo = true
	m.disable_fog = true
	m.albedo_color = Color(1, 1, 1, 1)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Flooded carpet: dark pile under a thin sheet of water (opaque and glossy so
## screen-space reflections of the room show in it).
static func flooded_carpet_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;
uniform vec3 c1 : source_color = vec3(0.25, 0.21, 0.16);
uniform vec3 c2 : source_color = vec3(0.13, 0.11, 0.085);
varying vec3 wp;
""" + NOISE_FN + """
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = wp.xz + vec2(wp.y * 0.7, 0.0);
	float pile = vn(p * 160.0) * 0.6 + vn(p * 47.0) * 0.4;
	float blot = smoothstep(0.25, 0.8, vn(p * 0.9) * 0.6 + vn(p * 2.3) * 0.4);
	ALBEDO = mix(c1, c2, blot) * (0.75 + 0.4 * pile);
	float t = TIME;
	float r0 = ripple(p * 2.0, t * 0.6);
	float rx = ripple(p * 2.0 + vec2(0.04, 0.0), t * 0.6);
	float rz = ripple(p * 2.0 + vec2(0.0, 0.04), t * 0.6);
	NORMAL_MAP = normalize(vec3((r0 - rx) * 0.9, (r0 - rz) * 0.9, 1.0)) * 0.5 + 0.5;
	ROUGHNESS = 0.035;
	SPECULAR = 0.55;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	return m
