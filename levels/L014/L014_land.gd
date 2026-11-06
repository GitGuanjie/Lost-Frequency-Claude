extends RefCounted
## Level 14 terrain: one deterministic height function h(x, z) shared by every
## streamed chunk, so seams always agree. ADAPTATION (the page gives no map):
##   - the Clearing anchor: a basin floor (r < 12 m) around the world origin,
##     whose slopes rise to a forested rim (~8 m) and blend into seeded hills;
##   - the Falls: a 10 m cliff on the basin's north side with two waterfalls
##     dropping into two pools, and a meadow on the cliff top;
##   - the Gully: an authored ravine leaving the basin to the west;
##   - seeded ravines further out (beyond ~100 m) so the wider forest has relief.
## Scatter (trees, grass, guests) is a pure function of (seed, chunk).

const CS := 32.0
const RES := 1.0
const N := 33                       # height samples per chunk side (1 m)
const POOL_Y := -0.3
const POOLS := [[Vector2(-3.0, -11.0), 5.2, 2.0], [Vector2(6.5, -12.2), 3.6, 1.4]]
const CLIFF_TOP := 8.5
const GULLY := [Vector2(-17.0, -1.0), Vector2(-36.0, 6.0), Vector2(-56.0, 21.0), Vector2(-80.0, 30.0), Vector2(-108.0, 52.0)]

var seed_i := 0
var off := Vector2.ZERO


func _init(level_seed: int) -> void:
	seed_i = absi(level_seed) & 0x7FFFFFFF
	off = Vector2(float(seed_i % 997) * 3.17, float((seed_i / 997) % 991) * 2.71)


# ------------------------------------------------------------------ noise

func _hh(ix: int, iz: int, s: int) -> float:
	var n := (ix * 374761393 + iz * 668265263 + (seed_i + s) * 1442695041) & 0xFFFFFFFF
	n = ((n ^ (n >> 13)) * 1274126177) & 0xFFFFFFFF
	n = n ^ (n >> 16)
	return float(n & 0xFFFFFF) / 16777215.0


func vn(x: float, z: float, s: int = 0) -> float:
	var ix := floori(x)
	var iz := floori(z)
	var fx := x - ix
	var fz := z - iz
	fx = fx * fx * (3.0 - 2.0 * fx)
	fz = fz * fz * (3.0 - 2.0 * fz)
	var a := _hh(ix, iz, s)
	var b := _hh(ix + 1, iz, s)
	var c := _hh(ix, iz + 1, s)
	var d := _hh(ix + 1, iz + 1, s)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fz)


func fbm(x: float, z: float, s: int) -> float:
	return vn(x, z, s) * 0.55 + vn(x * 2.03 + 5.2, z * 2.03 - 1.7, s + 1) * 0.3 + vn(x * 4.1 - 3.3, z * 4.1 + 8.1, s + 2) * 0.15


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / ab.length_squared(), 0.0, 1.0)
	return Vector2((p - (a + ab * t)).length(), t)


## Distance to the authored gully centreline and the arc length along it.
func gully(x: float, z: float) -> Vector2:
	var p := Vector2(x, z)
	var best := Vector2(1e9, 0.0)
	var acc := 0.0
	for i in GULLY.size() - 1:
		var a: Vector2 = GULLY[i]
		var b: Vector2 = GULLY[i + 1]
		var r := _seg_dist(p, a, b)
		if r.x < best.x:
			best = Vector2(r.x, acc + r.y * (b - a).length())
		acc += (b - a).length()
	return best


# ----------------------------------------------------------------- height

## Cliff weight (0..1) of the Falls band north of the basin.
func cliff_w(x: float, z: float) -> float:
	var d := Vector2(x, z).length()
	var jag := (vn(x * 0.35 + off.x, 3.7, 7) - 0.5) * 1.6
	return smoothstep(-13.8 + jag, -16.0 + jag, z) * (1.0 - smoothstep(19.0, 27.0, absf(x))) * (1.0 - smoothstep(38.0, 56.0, d))


func h(x: float, z: float) -> float:
	var d := Vector2(x, z).length()
	var px := x + off.x
	var pz := z + off.y
	var hills := (fbm(px * 0.011, pz * 0.011, 3) - 0.5) * 26.0
	var detail := (vn(px * 0.09, pz * 0.09, 9) - 0.5) * 1.4
	var outer := smoothstep(34.0, 82.0, d)
	# basin: flat floor, slopes up to the rim, then seeded hills
	var y := 8.0 * smoothstep(12.0, 36.0, d) + (hills + detail) * outer
	y += (vn(px * 0.25, pz * 0.25, 4) - 0.5) * lerpf(0.18, 0.5, smoothstep(10.0, 30.0, d))
	# the Falls cliff and its meadow
	var c := cliff_w(x, z)
	if c > 0.0:
		var tier := clampf(-17.0 - z, 0.0, 9.0) * 0.13     # the meadow rises gently behind the lip
		y = lerpf(y, CLIFF_TOP + tier + (vn(px * 0.2, pz * 0.2, 5) - 0.5) * 0.3, c)
	# plunge pools at the foot of the falls
	for pl in POOLS:
		var pd := Vector2(x, z).distance_to(pl[0])
		if pd < pl[1]:
			y -= float(pl[2]) * (1.0 - smoothstep(float(pl[1]) * 0.35, float(pl[1]), pd))
	# the Gully: depth ramps in from its head, steep walls, a 4 m floor
	var g := gully(x, z)
	if g.x < 9.0:
		var depth := 6.5 * smoothstep(0.0, 16.0, g.y)
		y -= depth * (1.0 - smoothstep(2.2, 6.8, g.x + (vn(px * 0.3, pz * 0.3, 6) - 0.5) * 0.8))
	# seeded ravines out in the wider forest
	if d > 95.0:
		var wx := px + (vn(px * 0.02, pz * 0.02 + 7.0, 11) - 0.5) * 40.0
		var wz := pz + (vn(px * 0.02 + 3.0, pz * 0.02, 12) - 0.5) * 40.0
		var rn := vn(wx * 0.009, wz * 0.009, 13)
		var rv := 1.0 - smoothstep(0.028, 0.07, absf(rn - 0.5))
		y -= 7.0 * rv * smoothstep(95.0, 130.0, d)
	return y


func normal_at(x: float, z: float) -> Vector3:
	return Vector3(h(x - 0.5, z) - h(x + 0.5, z), 1.0, h(x, z - 0.5) - h(x, z + 0.5)).normalized()


# ------------------------------------------------------------------ chunk

## Heights on a (N+2)^2 grid with a 1-sample border (for normals).
func chunk_heights(cx: int, cz: int) -> PackedFloat32Array:
	var ox := cx * CS
	var oz := cz * CS
	var out := PackedFloat32Array()
	out.resize((N + 2) * (N + 2))
	for j in N + 2:
		for i in N + 2:
			out[j * (N + 2) + i] = h(ox + (i - 1) * RES, oz + (j - 1) * RES)
	return out


static func hg(hs: PackedFloat32Array, i: int, j: int) -> float:
	return hs[(j + 1) * (N + 2) + (i + 1)]


## Bilinear height inside the chunk from the cached grid (local metres).
static func hl(hs: PackedFloat32Array, lx: float, lz: float) -> float:
	var i := clampi(floori(lx), 0, N - 2)
	var j := clampi(floori(lz), 0, N - 2)
	var fx := clampf(lx - i, 0.0, 1.0)
	var fz := clampf(lz - j, 0.0, 1.0)
	return lerpf(lerpf(hg(hs, i, j), hg(hs, i + 1, j), fx), lerpf(hg(hs, i, j + 1), hg(hs, i + 1, j + 1), fx), fz)


static func nl(hs: PackedFloat32Array, lx: float, lz: float) -> Vector3:
	return Vector3(hl(hs, lx - 0.5, lz) - hl(hs, lx + 0.5, lz), 1.0, hl(hs, lx, lz - 0.5) - hl(hs, lx, lz + 0.5)).normalized()


## Terrain mesh + HeightMapShape3D collision for one chunk.
func build_ground(node: Node3D, cx: int, cz: int, hs: PackedFloat32Array, mat: Material) -> void:
	var v := PackedVector3Array()
	var nrm := PackedVector3Array()
	var idx := PackedInt32Array()
	v.resize(N * N)
	nrm.resize(N * N)
	for j in N:
		for i in N:
			var k := j * N + i
			v[k] = Vector3(i * RES, hg(hs, i, j), j * RES)
			nrm[k] = Vector3(hg(hs, i - 1, j) - hg(hs, i + 1, j), 2.0 * RES, hg(hs, i, j - 1) - hg(hs, i, j + 1)).normalized()
	for j in N - 1:
		for i in N - 1:
			var a := j * N + i
			idx.append_array([a, a + 1, a + N, a + 1, a + N + 1, a + N])
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_NORMAL] = nrm
	arr[Mesh.ARRAY_INDEX] = idx
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.name = "Ground"
	mi.mesh = am
	mi.material_override = mat
	mi.position = Vector3(cx * CS, 0, cz * CS)
	node.add_child(mi)
	var sb := StaticBody3D.new()
	sb.name = "GroundBody"
	node.add_child(sb)
	var cs := CollisionShape3D.new()
	var hm := HeightMapShape3D.new()
	hm.map_width = N
	hm.map_depth = N
	var data := PackedFloat32Array()
	data.resize(N * N)
	for j in N:
		for i in N:
			data[j * N + i] = hg(hs, i, j)
	hm.map_data = data
	cs.shape = hm
	cs.position = Vector3(cx * CS + (N - 1) * RES * 0.5, 0, cz * CS + (N - 1) * RES * 0.5)
	cs.set_meta("surface", "grass")
	sb.add_child(cs)


# ---------------------------------------------------------------- scatter

func _rng(cx: int, cz: int, salt: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = hash([seed_i, cx, cz, salt])
	return r


## Tree density (0..1) at a world point: open basin floor and falls, sparse
## basin slopes (so the Clearing can be seen), dense forest beyond the rim.
func tree_density(x: float, z: float) -> float:
	var d := Vector2(x, z).length()
	if d < 15.0 or cliff_w(x, z) > 0.2:
		return 0.0
	for pl in POOLS:
		if Vector2(x, z).distance_to(pl[0]) < float(pl[1]) + 1.5:
			return 0.0
	var base := lerpf(0.10, 0.82, smoothstep(26.0, 44.0, d))
	if z < -13.0 and absf(x) < 34.0 and z > -60.0:
		base *= smoothstep(-48.0, -66.0, z) * 0.7   # keep the falls meadow open to the sky
	return base * (0.55 + 0.9 * vn((x + off.x) * 0.05, (z + off.y) * 0.05, 21))


## Trees as [local pos, yaw, scale, variant]; slope and keep-out filtered.
func trees(cx: int, cz: int, hs: PackedFloat32Array, keep_out: Array) -> Array:
	var r := _rng(cx, cz, 1)
	var out: Array = []
	var cell := 4.0
	for gj in int(CS / cell):
		for gi in int(CS / cell):
			var lx := (gi + r.randf_range(0.15, 0.85)) * cell
			var lz := (gj + r.randf_range(0.15, 0.85)) * cell
			var wx := cx * CS + lx
			var wz := cz * CS + lz
			var p := r.randf()
			var yaw := r.randf() * TAU
			var sc := r.randf_range(0.8, 1.3)
			var var_i := r.randi() % 3
			if p > tree_density(wx, wz):
				continue
			if nl(hs, lx, lz).y < 0.8:
				continue
			var ok := true
			for ko in keep_out:
				if Vector2(wx, wz).distance_to(ko[0]) < float(ko[1]):
					ok = false
					break
			if gully(wx, wz).x < 6.5:
				ok = false
			if ok:
				out.append([Vector3(lx, hl(hs, lx, lz), lz), yaw, sc, var_i])
	return out


## Grass tufts as Transform3D (local), skipping rock slopes and pool water.
func grass(cx: int, cz: int, hs: PackedFloat32Array, spacing: float, bare: Array = []) -> Array:
	var r := _rng(cx, cz, 2)
	var out: Array = []
	var n := int(CS / spacing)
	for gj in n:
		for gi in n:
			var lx := (gi + r.randf()) * spacing
			var lz := (gj + r.randf()) * spacing
			var yaw := r.randf() * TAU
			var sc := r.randf_range(0.7, 1.35)
			var y := hl(hs, lx, lz)
			if y < POOL_Y + 0.05:
				continue
			var skip := false
			for bp in bare:
				if Vector2(cx * CS + lx, cz * CS + lz).distance_to(bp) < 1.9:
					skip = true
					break
			if skip:
				continue
			var nn := nl(hs, lx, lz)
			if nn.y < 0.78:
				continue
			var b := Basis(Vector3.UP, yaw).scaled(Vector3(sc, sc * r.randf_range(0.8, 1.25), sc))
			out.append(Transform3D(b, Vector3(lx, y - 0.03, lz)))
	return out


## Guests lying in the soil: more of them nearer the Clearing.
func guests(cx: int, cz: int, hs: PackedFloat32Array) -> Array:
	var r := _rng(cx, cz, 3)
	var out: Array = []
	var cnt := r.randi_range(0, 3)
	for k in cnt:
		var lx := r.randf_range(1.0, CS - 1.0)
		var lz := r.randf_range(1.0, CS - 1.0)
		var wd := Vector2(cx * CS + lx, cz * CS + lz).length()
		var keep := r.randf() < (1.0 - smoothstep(20.0, 140.0, wd)) * 0.9 + 0.08
		var yaw := r.randf() * TAU
		if not keep or wd < 16.0 or nl(hs, lx, lz).y < 0.86 or hl(hs, lx, lz) < POOL_Y + 0.1:
			continue
		out.append(Transform3D(Basis(Vector3.UP, yaw), Vector3(lx, hl(hs, lx, lz) + 0.01, lz)))
	return out
