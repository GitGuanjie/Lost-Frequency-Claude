extends RefCounted
## Level 41 dressing: the page's list of submerged constructs (telegraph poles,
## small power pylons, tiled bungalow roofs, flat brick townhouse roofs, metal
## rods), the remains of the failed groups, dead bushes and animal bones on
## the islands, fires on the tar, and the Collagen Leviathan skeleton meshes.

const B := preload("res://levels/L041/L041_build.gd")
const LAND := preload("res://levels/L041/L041_land.gd")

var lvl
var land
var fires: Array = []        # {pos: Vector3, r: float}
var avoid: Array = []        # Vector3 points (xz) to keep clear (routes, landmarks)
var flame_mat: ShaderMaterial
var smoke_mat: ShaderMaterial


func _init(level, land_model) -> void:
	lvl = level
	land = land_model
	flame_mat = LAND.shader_mat(LAND.FLAME)
	smoke_mat = LAND.shader_mat(LAND.SMOKE)


func _clear(p: Vector3, r: float) -> bool:
	for a in avoid:
		if Vector2(p.x - a.x, p.z - a.z).length() < r:
			return false
	return true


## Seeded spot on open tar (not on an island, clear of routes), inside reach.
func tar_spot(rng: RandomNumberGenerator, clear: float, rmin := 20.0, rmax := 190.0) -> Vector3:
	for i in 60:
		var a := rng.randf_range(0, TAU)
		var r := rng.randf_range(rmin, rmax)
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		if land.h(p.x, p.z) < -0.6 and _clear(p, clear) and land.h(p.x + 4, p.z) < -0.3 and land.h(p.x - 4, p.z) < -0.3 and land.h(p.x, p.z + 4) < -0.3 and land.h(p.x, p.z - 4) < -0.3:
			return p
	return Vector3(rng.randf_range(-150, 150), 0, rng.randf_range(-150, -100))


# ------------------------------------------------------------ submerged things

func telegraph_line(k: GeoKit, start: Vector3, dir: float, n: int, rng: RandomNumberGenerator) -> void:
	var d := Vector3(cos(dir), 0, sin(dir))
	var side := Vector3(-d.z, 0, d.x)
	var tops: Array = []
	for i in n:
		var base := start + d * (i * 22.0) + side * rng.randf_range(-1.5, 1.5)
		var lean := Vector3(rng.randf_range(-0.25, 0.25), 0, rng.randf_range(-0.25, 0.25))
		var vis := rng.randf_range(2.5, 6.5)
		var top := base + Vector3.UP * vis + lean * vis
		B.beam(k, base + Vector3.DOWN * 3.0 - lean * 3.0, top, 0.26, 0.26, "l41_pole")
		var arm_c := top - Vector3.UP * 0.45
		var arm_r := side.rotated(Vector3.UP, rng.randf_range(-0.2, 0.2))
		B.beam(k, arm_c - arm_r * 1.0, arm_c + arm_r * 1.0, 0.12, 0.12, "l41_pole")
		for s in [-0.8, -0.3, 0.3, 0.8]:
			k.cylinder(arm_c + arm_r * s + Vector3.UP * 0.12, 0.05, 0.16, "l41_white", 5, false)
		tops.append(arm_c + Vector3.UP * 0.2)
	# sagging wires between the poles, a few already cut down (copper taken)
	for i in n - 1:
		if rng.randf() < 0.35:
			continue
		for s in [-0.8, 0.8]:
			var a: Vector3 = tops[i] + side * s
			var b: Vector3 = tops[i + 1] + side * s
			var prev := a
			for j in range(1, 7):
				var t := j / 6.0
				var p := a.lerp(b, t) + Vector3.DOWN * (sin(PI * t) * 1.6)
				B.beam(k, prev, p, 0.025, 0.025, "l41_wire")
				prev = p


func pylon(k: GeoKit, c: Vector3, yaw: float, tilt: float) -> void:
	var b := Basis(Vector3.UP, yaw) * Basis(Vector3(1, 0, 0), tilt)
	var o := c + Vector3.DOWN * 3.0
	var h := 11.0
	var corners := [Vector3(-1.4, 0, -1.4), Vector3(1.4, 0, -1.4), Vector3(1.4, 0, 1.4), Vector3(-1.4, 0, 1.4)]
	var levels := [0.0, 2.8, 5.4, 7.8, 9.8, h]
	var widths := [1.0, 0.82, 0.64, 0.48, 0.36, 0.22]
	for li in levels.size() - 1:
		for ci in 4:
			var p0: Vector3 = o + b * (corners[ci] * widths[li] + Vector3.UP * levels[li])
			var p1: Vector3 = o + b * (corners[ci] * widths[li + 1] + Vector3.UP * levels[li + 1])
			B.beam(k, p0, p1, 0.1, 0.1, "l41_steel")
			var q0: Vector3 = o + b * (corners[(ci + 1) % 4] * widths[li + 1] + Vector3.UP * levels[li + 1])
			B.beam(k, p0, q0, 0.05, 0.05, "l41_steel")
			B.beam(k, p1, q0, 0.06, 0.06, "l41_steel")
	# cross arms with hanging insulators
	for ah in [7.8, 9.8]:
		var ac: Vector3 = o + b * Vector3(0, ah, 0)
		B.beam(k, ac - b.x * 2.6, ac + b.x * 2.6, 0.12, 0.14, "l41_steel")
		for s in [-2.3, 2.3]:
			B.beam(k, ac + b.x * s, ac + b.x * s + Vector3.DOWN * 0.7, 0.08, 0.08, "l41_white")


func bungalow_roof(k: GeoKit, c: Vector3, yaw: float, ridge: float, tiled: bool) -> void:
	var b := Basis(Vector3.UP, yaw)
	var ln := 9.0
	var half := 4.2
	var pitch := atan2(2.6, half)
	var mat := "l41_roof_tile" if tiled else "l41_slate"
	for s in [-1.0, 1.0]:
		var rb := b * Basis(Vector3(0, 0, 1), -s * pitch)
		var slope_len := sqrt(half * half + 2.6 * 2.6)
		var mid := c + b * Vector3(s * half * 0.5, ridge - 1.3, 0)
		k.box_xf(Transform3D(rb, mid), Vector3(slope_len + 0.3, 0.16, ln), mat, GeoKit.ALL, true)
	# ridge tiles, a chimney stack and a gable end
	k.box_xf(Transform3D(b, c + Vector3.UP * (ridge + 0.04)), Vector3(0.32, 0.18, ln + 0.2), mat, GeoKit.ALL, false)
	k.box_xf(Transform3D(b, c + b * Vector3(1.6, ridge - 0.2, 2.2)), Vector3(0.7, 2.4, 0.7), "l41_brick", GeoKit.ALL, true)
	k.box_xf(Transform3D(b, c + b * Vector3(1.6, ridge + 1.05, 2.2)), Vector3(0.8, 0.12, 0.8), "l41_concrete", GeoKit.ALL, false)
	for e in [-1.0, 1.0]:
		k.box_xf(Transform3D(b, c + b * Vector3(0, ridge - 1.6, e * ln * 0.5)), Vector3(half * 1.6, 2.8, 0.2), "l41_white", GeoKit.ALL, false)


func townhouse_roof(k: GeoKit, c: Vector3, yaw: float, rng: RandomNumberGenerator) -> void:
	var b := Basis(Vector3.UP, yaw)
	var sx := rng.randf_range(7.0, 10.0)
	var sz := rng.randf_range(10.0, 14.0)
	var top := rng.randf_range(0.35, 0.9)
	# parapet walls just clear of the tar; the roof inside is drowned
	for e in [[Vector3(0, 0, sz * 0.5), Vector3(sx, 0, 0.3)], [Vector3(0, 0, -sz * 0.5), Vector3(sx, 0, 0.3)],
			[Vector3(sx * 0.5, 0, 0), Vector3(0.3, 0, sz)], [Vector3(-sx * 0.5, 0, 0), Vector3(0.3, 0, sz)]]:
		var sz3: Vector3 = e[1]
		sz3.y = top + 1.4
		k.box_xf(Transform3D(b, c + b * e[0] + Vector3.UP * (top - sz3.y * 0.5)), sz3, "l41_brick", GeoKit.ALL, true)
		var cap: Vector3 = e[1] + Vector3(0.12, 0.08, 0.12)
		k.box_xf(Transform3D(b, c + b * e[0] + Vector3.UP * (top + 0.04)), cap, "l41_concrete", GeoKit.ALL, false)
	# chimney stack with pots, and a bent aerial
	var cs := c + b * Vector3(sx * 0.3, 0, -sz * 0.3)
	k.box_xf(Transform3D(b, cs + Vector3.UP * (top + 0.7)), Vector3(1.4, 2.4, 0.6), "l41_brick", GeoKit.ALL, true)
	for i in 3:
		k.cylinder(cs + b * Vector3(-0.45 + i * 0.45, 0, 0) + Vector3.UP * (top + 2.1), 0.13, 0.4, "l41_roof_tile", 8, false)
	var ap := c + b * Vector3(-sx * 0.25, top, sz * 0.2)
	B.beam(k, ap, ap + Vector3(0.4, 2.6, 0.2), 0.05, 0.05, "l41_steel")
	B.beam(k, ap + Vector3(0.35, 2.2, 0.17) - b.x * 0.8, ap + Vector3(0.35, 2.2, 0.17) + b.x * 0.8, 0.03, 0.03, "l41_steel")


func rods(k: GeoKit, c: Vector3, rng: RandomNumberGenerator) -> void:
	for i in rng.randi_range(5, 9):
		var p := c + Vector3(rng.randf_range(-2.5, 2.5), -1.0, rng.randf_range(-2.5, 2.5))
		var d := Vector3(rng.randf_range(-0.5, 0.5), 1.0, rng.randf_range(-0.5, 0.5)).normalized()
		B.beam(k, p, p + d * rng.randf_range(1.6, 4.5), 0.05, 0.05, "l41_steel")


# ------------------------------------------------------------ islands

## Dead, dried bush: a fan of grey twigs (MultiMesh-able mesh).
static func bush_mesh(sd: int) -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = sd
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in r.randi_range(7, 12):
		var a := r.randf() * TAU
		var p0 := Vector3(r.randf_range(-0.08, 0.08), 0, r.randf_range(-0.08, 0.08))
		var p1 := p0 + Vector3(cos(a) * r.randf_range(0.15, 0.4), r.randf_range(0.3, 0.6), sin(a) * r.randf_range(0.15, 0.4))
		_twig(st, p0, p1, 0.025)
		for j in 2:
			var a2 := a + r.randf_range(-0.9, 0.9)
			var p2 := p1 + Vector3(cos(a2) * r.randf_range(0.1, 0.3), r.randf_range(0.1, 0.35), sin(a2) * r.randf_range(0.1, 0.3))
			_twig(st, p1, p2, 0.012)
	st.generate_normals()
	return st.commit()


static func _twig(st: SurfaceTool, a: Vector3, b: Vector3, rad: float) -> void:
	var ax := (b - a).normalized()
	var u := ax.cross(Vector3.RIGHT if absf(ax.x) < 0.9 else Vector3.FORWARD).normalized()
	var w := ax.cross(u)
	for s in 4:
		var a0 := TAU * s / 4.0
		var a1 := TAU * (s + 1) / 4.0
		var d0 := u * cos(a0) + w * sin(a0)
		var d1 := u * cos(a1) + w * sin(a1)
		var q := [a + d0 * rad, a + d1 * rad, b + d1 * rad * 0.4, b + d0 * rad * 0.4]
		for i in [0, 2, 1, 0, 3, 2]:
			st.add_vertex(q[i])


## A small animal skeleton lying in the sand (ribs, spine, skull).
static func bones_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_twig(st, Vector3(0, 0.05, -0.5), Vector3(0, 0.05, 0.4), 0.025)
	for i in 6:
		var z := -0.3 + i * 0.09
		for s in [-1.0, 1.0]:
			_twig(st, Vector3(0, 0.07, z), Vector3(s * 0.14, 0.04, z + 0.04), 0.012)
			_twig(st, Vector3(s * 0.14, 0.04, z + 0.04), Vector3(s * 0.16, -0.02, z + 0.08), 0.01)
	_twig(st, Vector3(0, 0.06, -0.62), Vector3(0, 0.07, -0.42), 0.06)
	_twig(st, Vector3(0.12, 0.03, 0.35), Vector3(0.3, 0.02, 0.62), 0.02)
	st.generate_normals()
	return st.commit()


func scatter_islands(parent: Node3D, rng: RandomNumberGenerator) -> void:
	var bushes: Array = []
	var bones: Array = []
	for isl in land.islands:
		var c: Vector2 = isl["c"]
		var n := int(float(isl["rx"]) * float(isl["rz"]) * 0.09) + 1
		for i in n:
			var p := Vector3(c.x + rng.randf_range(-isl["rx"], isl["rx"]) * 0.75, 0, c.y + rng.randf_range(-isl["rz"], isl["rz"]) * 0.75)
			p.y = land.h(p.x, p.z)
			if p.y < 0.12 or not _clear(p, 2.2):
				continue
			var s := rng.randf_range(0.7, 1.6)
			var xf := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s * rng.randf_range(0.8, 1.3), s)), p - Vector3.UP * 0.05)
			if rng.randf() < 0.82:
				bushes.append(xf)
			else:
				bones.append(xf)
	var bone_mat: Material = MatLib.get_mat("l41_bone")
	var twig_mat := MatLib.define("l41_twig", {"albedo_a": Color(0.26, 0.24, 0.21), "albedo_b": Color(0.16, 0.15, 0.13), "noise_scale": 8.0, "roughness_a": 0.95}, "plaster")
	parent.add_child(_mm(bush_mesh(41), bushes, twig_mat, true))
	parent.add_child(_mm(bones_mesh(), bones, bone_mat, false))


static func _mm(mesh: Mesh, xfs: Array, mat: Material, shadows: bool) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mmi


func _p(parent: Node3D, id: String, x: float, z: float, yaw := 0.0, h := 0.0, collide := false, dy := -0.05) -> Node3D:
	return Props.place(lvl, parent, id, Vector3(x, land.h(x, z) + dy, z), yaw, h, collide)


## The remains of one of the failed groups on the landing island: a fallen
## lean-to, empty water jugs, drums, a radio, a half-built plank bridge that
## ends in the tar, and a drum of copper wire stripped from the poles.
func group_remains(k: GeoKit, parent: Node3D, c: Vector3) -> Dictionary:
	var gy: float = land.h(c.x, c.z)
	# lean-to: two posts, a ridge pole and a sagging tarp on the sand
	var a := c + Vector3(-1.6, 0, -0.8)
	var b := c + Vector3(1.6, 0, -1.4)
	for p in [a, b]:
		B.beam(k, Vector3(p.x, land.h(p.x, p.z) - 0.2, p.z), Vector3(p.x, land.h(p.x, p.z) + 1.1, p.z) + Vector3(0.1, 0, 0.05), 0.09, 0.09, "l41_beam")
	B.beam(k, Vector3(a.x, gy + 1.05, a.z), Vector3(b.x, gy + 1.05, b.z), 0.07, 0.07, "l41_beam")
	var mid := (a + b) * 0.5
	var bas := B.seg_basis(a, b)
	var tb := bas.rotated(bas.z.normalized(), -atan2(1.05, 1.3))
	k.box_xf(Transform3D(tb, Vector3(mid.x, gy + 0.5, mid.z) + bas.x * 0.62), Vector3(1.6, 0.03, 2.6), "l41_canvas", GeoKit.ALL, false)
	_p(parent, "ph/Barrel_01", c.x + 2.4, c.z + 0.6, 30.0, 0.0, true)
	_p(parent, "ph/barrel_03", c.x + 3.1, c.z - 0.3, 75.0, 0.0, true)
	var tipped := _p(parent, "ph/barrel_03", c.x + 2.2, c.z + 2.0, 0.0, 0.0, false, 0.25)
	if tipped:
		tipped.rotation = Vector3(0.0, 0.6, PI * 0.5)
	for i in 4:
		_p(parent, "ph/plastic_bottle_gallon", c.x - 0.6 + i * 0.32, c.z + 1.1 + (i % 2) * 0.2, i * 40.0)
	_p(parent, "ph/vintage_radio_transceiver", c.x - 0.4, c.z - 0.3, 160.0)
	_p(parent, "ph/wooden_crate_01", c.x - 2.6, c.z + 0.8, 20.0, 0.0, true)
	_p(parent, "ph/old_military_crate", c.x - 2.2, c.z + 2.2, -35.0, 0.0, true)
	_p(parent, "ph/metal_tool_chest", c.x + 0.9, c.z + 1.6, 200.0)
	_p(parent, "ph/old_tyre", c.x + 4.0, c.z + 2.5, 10.0)
	_p(parent, "ph/propane_tank", c.x + 1.4, c.z - 0.2, 0.0)
	# copper drum: a cable reel wound with stripped wire
	var rc := Vector3(c.x - 3.6, 0, c.z - 1.4)
	rc.y = land.h(rc.x, rc.z) + 0.36
	for yy in [-0.33, 0.33]:
		k.cylinder(rc + Vector3.UP * yy, 0.58, 0.06, "l41_beam", 14, true)
	k.cylinder(rc, 0.42, 0.62, "l41_wire", 14, false, false)
	return {"board": c + Vector3(-0.4, 0, -0.3), "reel": rc}


## A bridge the group began towards an outlying island: planks on drums,
## ending where the tar took it.
func group_bridge(k: GeoKit, from: Vector3, dir: Vector3) -> void:
	dir = dir.normalized()
	var side := Vector3(-dir.z, 0, dir.x)
	for i in 9:
		var p := from + dir * (i * 1.1)
		var gy: float = land.h(p.x, p.z)
		var y := maxf(gy, 0.0) + 0.35 - maxf(0.0, i - 5.0) * 0.18
		k.box_xf(Transform3D(B.seg_basis(p - dir, p + dir).rotated(dir, (i % 3 - 1) * 0.06), Vector3(p.x, y, p.z)), Vector3(1.1, 0.06, 1.15), "l41_plank" if i < 6 else "l41_char", GeoKit.ALL, i < 4, "wood")
		if i % 2 == 0:
			for s in [-0.5, 0.5]:
				var q: Vector3 = p + side * s
				k.cylinder(Vector3(q.x, y - 0.4, q.z), 0.22, 0.75, "l41_steel", 8, false)


# ------------------------------------------------------------ fire and smoke

func fire(parent: Node3D, p: Vector3, size: float, rng: RandomNumberGenerator, smoke := true) -> void:
	fires.append({"pos": p, "r": size})
	var q := QuadMesh.new()
	q.size = Vector2(1, 1)
	q.center_offset = Vector3(0, 0.5, 0)
	for i in int(3 + size * 2.0):
		var mi := MeshInstance3D.new()
		mi.mesh = q
		var m := flame_mat.duplicate() as ShaderMaterial
		m.set_shader_parameter("seed", rng.randf() * 10.0)
		m.set_shader_parameter("energy", rng.randf_range(2.2, 3.6))
		mi.material_override = m
		var hgt := rng.randf_range(0.8, 1.9) * size
		mi.scale = Vector3(hgt * rng.randf_range(0.5, 0.8), hgt, 1.0)
		var a := rng.randf() * TAU
		var rr := rng.randf() * size * 0.7
		mi.position = p + Vector3(cos(a) * rr, -0.05, sin(a) * rr)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.visibility_range_end = 260.0
		parent.add_child(mi)
	if smoke:
		for i in 2:
			var sm := MeshInstance3D.new()
			sm.mesh = q
			var m2 := smoke_mat.duplicate() as ShaderMaterial
			m2.set_shader_parameter("seed", rng.randf() * 10.0)
			sm.material_override = m2
			var sh := rng.randf_range(7.0, 13.0) * clampf(size, 0.6, 1.6)
			sm.scale = Vector3(sh * 0.5, sh, 1.0)
			sm.position = p + Vector3(rng.randf_range(-0.6, 0.6), 0.6, rng.randf_range(-0.6, 0.6))
			sm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			sm.visibility_range_end = 260.0
			parent.add_child(sm)


# ------------------------------------------------------------ the leviathan

static func _ellipsoid(st: SurfaceTool, c: Vector3, r: Vector3, rings: int, segs: int) -> void:
	for i in rings:
		var t0 := PI * i / rings
		var t1 := PI * (i + 1) / rings
		for j in segs:
			var p0 := TAU * j / segs
			var p1 := TAU * (j + 1) / segs
			var dirs := [Vector3(sin(t0) * cos(p0), cos(t0), sin(t0) * sin(p0)), Vector3(sin(t1) * cos(p0), cos(t1), sin(t1) * sin(p0)),
				Vector3(sin(t1) * cos(p1), cos(t1), sin(t1) * sin(p1)), Vector3(sin(t0) * cos(p1), cos(t0), sin(t0) * sin(p1))]
			for kk in [0, 2, 1, 0, 3, 2]:
				st.add_vertex(c + dirs[kk] * r)


## One vertebra with a dorsal spine and a pair of ribs; local +Z = forward.
static func vertebra_mesh(ribs: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_ellipsoid(st, Vector3.ZERO, Vector3(0.16, 0.15, 0.19), 4, 7)
	_twig(st, Vector3(0, 0.1, 0), Vector3(0, 0.42, -0.12), 0.05)
	for s in [-1.0, 1.0]:
		_twig(st, Vector3(s * 0.1, 0, 0), Vector3(s * 0.3, 0.05, -0.04), 0.035)
		if ribs:
			_twig(st, Vector3(s * 0.12, -0.02, 0), Vector3(s * 0.42, -0.3, -0.08), 0.03)
			_twig(st, Vector3(s * 0.42, -0.3, -0.08), Vector3(s * 0.26, -0.68, -0.16), 0.025)
	st.generate_normals()
	return st.commit()


## The long, eel-and-salmon-like skull with an open lower jaw and teeth.
static func skull_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_ellipsoid(st, Vector3(0, 0.05, 0.3), Vector3(0.36, 0.3, 0.62), 6, 9)
	_ellipsoid(st, Vector3(0, 0.0, 0.95), Vector3(0.2, 0.16, 0.5), 5, 8)
	for s in [-1.0, 1.0]:
		_ellipsoid(st, Vector3(s * 0.2, 0.2, 0.55), Vector3(0.09, 0.09, 0.09), 3, 6)    # orbits (dark by shadow)
		_twig(st, Vector3(s * 0.22, -0.15, 0.0), Vector3(s * 0.12, -0.42, 1.2), 0.06)   # lower jaw rami
		for t in 7:
			var z := 0.45 + t * 0.12
			_twig(st, Vector3(s * (0.17 - t * 0.012), -0.08, z), Vector3(s * (0.15 - t * 0.012), -0.28, z + 0.03), 0.025)
			_twig(st, Vector3(s * (0.15 - t * 0.012), -0.33 - t * 0.012, z), Vector3(s * (0.13 - t * 0.012), -0.16, z + 0.02), 0.02)
	_twig(st, Vector3(0, 0.3, -0.2), Vector3(0, 0.45, -0.45), 0.08)
	st.generate_normals()
	return st.commit()
