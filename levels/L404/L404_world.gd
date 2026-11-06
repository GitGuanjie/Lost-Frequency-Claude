extends RefCounted
## Level 404 geometry. Nothing here is a room: the page gives no map, so the
## space is assembled from the page's own images (ADAPTATION of SOURCE facts):
##  - the 404th circle: a pearl platter of ring tiles, whole at the centre
##    ("your home"), fraying into missing sectors towards its edge;
##  - planes that intersect, bisect and bend: a bent ramp-plane arcing up to a
##    broken upper ring, grid slabs crossing through the disc and each other;
##  - pieces of sky stuck in the ground and drifting in the air;
##  - the skybox itself, a cube you can see the seams of, and one straight
##    walk out to the corner of it that is broken ("guided you to the skybox");
##  - "deeper": a dim copy of the circle far below, seen through the holes.
## Collision is boxes (tiles, slabs) plus convex shapes for the big shards.

const SK := 64.0                 # skybox half-size
const RING_W := 2.0
const RINGS := 13                # ring 0 (centre) .. ring 12, outer radius 26
const ARC_A0 := 105.0            # upper ring span (degrees, atan2(z, x))
const ARC_A1 := 215.0
const ARC_R0 := 14.0
const ARC_R1 := 19.0
const ARC_Y := 6.0
const RAMP_A0 := 35.0
const RAMP_R0 := 8.0
const PATH_Z0 := 24.6
const LAND_Z0 := 57.0
const World_404_POS := Vector3(14.0, -33.4, -12.0)

var L: Node3D                    # the level (LevelBase)
var rng: RandomNumberGenerator
var col: GeoKit                  # collision-only kit (boxes are the QA layout signature)
var mats := {}
var _acc := {}
var tiles: Array = []            # [{id, pos, shape, ring}] droppable disc tiles
var next_id := 1
var air_shards: Array = []       # [{node, spin, bob, base}]
var words: Array = []            # [{label, text, keep}]
var sharp: Node3D                # the sharpest piece of the sky
var frag_nodes: Array = []       # memory panels (MeshInstance3D)
var ramp_pts: Array = []


func _init(level: Node3D, r: RandomNumberGenerator, materials: Dictionary) -> void:
	L = level
	rng = r
	mats = materials
	col = GeoKit.new(level, "Solid")


# ------------------------------------------------------------ mesh helpers

func _s(m: String) -> Dictionary:
	if not _acc.has(m):
		_acc[m] = {"v": PackedVector3Array(), "n": PackedVector3Array(), "uv": PackedVector2Array(),
			"uv2": PackedVector2Array(), "i": PackedInt32Array()}
	return _acc[m]


func quad4(m: String, p: Array, n: Vector3, uv2: Vector2) -> void:
	var s := _s(m)
	var b: int = s["v"].size()
	var luv := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
	for k in 4:
		s["v"].append(p[k])
		s["n"].append(n)
		s["uv"].append(luv[k])
		s["uv2"].append(uv2)
	if ((p[1] as Vector3) - p[0]).cross((p[2] as Vector3) - p[0]).dot(n) > 0.0:
		s["i"].append_array([b, b + 2, b + 1, b, b + 3, b + 2])
	else:
		s["i"].append_array([b, b + 1, b + 2, b, b + 2, b + 3])


func box_vis(m: String, xf: Transform3D, size: Vector3, uv2: Vector2) -> void:
	var h := size * 0.5
	var c := xf.origin
	var ax := xf.basis.x.normalized()
	var ay := xf.basis.y.normalized()
	var az := xf.basis.z.normalized()
	for f in [[ax, h.x, az * h.z, ay * h.y], [-ax, h.x, az * h.z, ay * h.y], [ay, h.y, ax * h.x, az * h.z],
			[-ay, h.y, ax * h.x, az * h.z], [az, h.z, ax * h.x, ay * h.y], [-az, h.z, ax * h.x, ay * h.y]]:
		var n: Vector3 = f[0]
		var fc: Vector3 = c + n * float(f[1])
		var u: Vector3 = f[2]
		var v: Vector3 = f[3]
		quad4(m, [fc - u - v, fc + u - v, fc + u + v, fc - u + v], n, uv2)


func solid_box(m: String, xf: Transform3D, size: Vector3, uv2: Vector2, surface := "tile") -> CollisionShape3D:
	box_vis(m, xf, size, uv2)
	return col.add_box_shape(xf, size, surface)


func commit(parent: Node3D, cast_shadow := true) -> void:
	for m in _acc.keys():
		var s: Dictionary = _acc[m]
		if s["v"].size() == 0:
			continue
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = s["v"]
		arr[Mesh.ARRAY_NORMAL] = s["n"]
		arr[Mesh.ARRAY_TEX_UV] = s["uv"]
		arr[Mesh.ARRAY_TEX_UV2] = s["uv2"]
		arr[Mesh.ARRAY_INDEX] = s["i"]
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		var mi := MeshInstance3D.new()
		mi.name = "Mesh_" + m
		mi.mesh = am
		mi.material_override = mats[m]
		if not cast_shadow or m == "sky":
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
	_acc.clear()


static func polar(r: float, a_deg: float, y: float) -> Vector3:
	var a := deg_to_rad(a_deg)
	return Vector3(cos(a) * r, y, sin(a) * r)


## One ring sector (an annular tile) with skirts; returns its collision shape.
func sector(m: String, r0: float, r1: float, a0: float, a1: float, y: float, thick: float, collide: bool) -> CollisionShape3D:
	var id := next_id
	next_id += 1
	var uv2 := Vector2(id, 0)
	var g := 0.025
	var ri := r0 + g if r0 > 0.0 else 0.0
	var ro := r1 - g
	var ga := rad_to_deg(g / maxf(r1, 0.5))
	var b0 := a0 + ga
	var b1 := a1 - ga
	var k := maxi(2, int(ceil(deg_to_rad(b1 - b0) * ro / 0.9)))
	var yb := y - thick
	for j in k:
		var c0 := lerpf(b0, b1, float(j) / k)
		var c1 := lerpf(b0, b1, float(j + 1) / k)
		quad4(m, [polar(ri, c0, y), polar(ro, c0, y), polar(ro, c1, y), polar(ri, c1, y)], Vector3.UP, uv2)
		var on := polar(1.0, (c0 + c1) * 0.5, 0.0)
		quad4(m, [polar(ro, c0, y), polar(ro, c1, y), polar(ro, c1, yb), polar(ro, c0, yb)], on, uv2)
		if ri > 0.0:
			quad4(m, [polar(ri, c0, y), polar(ri, c1, y), polar(ri, c1, yb), polar(ri, c0, yb)], -on, uv2)
	for e in [[b0, -1.0], [b1, 1.0]]:
		var tn := polar(1.0, e[0] + 90.0 * e[1], 0.0)
		quad4(m, [polar(ri, e[0], y), polar(ro, e[0], y), polar(ro, e[0], yb), polar(ri, e[0], yb)], tn, uv2)
	if not collide:
		return null
	var am := (a0 + a1) * 0.5
	var rad := polar(1.0, am, 0.0)
	var tan := Vector3(-rad.z, 0.0, rad.x)
	var bas := Basis(tan, Vector3.UP, tan.cross(Vector3.UP))
	var size := Vector3(r1 * deg_to_rad(a1 - a0) + 0.06, thick, (r1 - r0) + 0.08)
	var shape := col.add_box_shape(Transform3D(bas, polar((r0 + r1) * 0.5, am, y - thick * 0.5)), size, "tile")
	tiles.append({"id": id, "pos": polar((r0 + r1) * 0.5, am, y), "shape": shape, "y": y,
		"r": (r0 + r1) * 0.5})
	return shape


# ------------------------------------------------------------------ build

func build_all() -> void:
	_disc()
	_upper_arc()
	_bent_ramp()
	_planes()
	_walk()
	_skybox()
	var root := Node3D.new()
	root.name = "Paradise"
	L.add_child(root)
	commit(root)
	_deeper()
	_shards()
	_fragments()
	_words()


func _sector_count(ring: int) -> int:
	if ring == 0:
		return 6
	return maxi(8, int(round(TAU * (ring + 0.5) * RING_W / 2.6)))


func _disc() -> void:
	for ring in RINGS:
		var r0 := ring * RING_W
		var r1 := r0 + RING_W
		var n := _sector_count(ring)
		var off := rng.randf() * 360.0 / n
		for j in n:
			var a0 := off + 360.0 * j / n
			var a1 := off + 360.0 * (j + 1) / n
			var am := fposmod((a0 + a1) * 0.5, 360.0)
			var keep := true
			var p_hole := 0.0 if ring < 5 else 0.03 + (ring - 5) * 0.035
			if ring >= 11:
				p_hole += 0.12
			if absf(am - 90.0) < 11.0:
				p_hole = 0.0      # an unbroken way from home out to the walk
			if absf(fposmod(am - RAMP_A0 + 180.0, 360.0) - 180.0) < 16.0 and ring >= 3 and ring <= 5:
				p_hole = 0.0      # the foot of the bent plane
			if rng.randf() < p_hole:
				keep = false
			if keep:
				sector("disc", r0, r1, a0, a1, 0.0, 0.35, true)


func _upper_arc() -> void:
	var n := 16
	for j in n:
		var a0 := lerpf(ARC_A0, ARC_A1, float(j) / n)
		var a1 := lerpf(ARC_A0, ARC_A1, float(j + 1) / n)
		var t := (float(j) + 0.5) / n
		var y := ARC_Y + 0.55 * sin(t * PI)              # the ring is bent, gently
		if j == n - 1 and rng.randf() < 0.5:
			continue                                      # its far end is broken off
		var r0 := ARC_R0 + (0.6 if j % 5 == 3 else 0.0)  # bites out of the inner edge
		sector("disc", r0, ARC_R1, a0, a1, y, 0.45, true)


func _ramp_point(s: float) -> Vector3:
	var a := lerpf(RAMP_A0, ARC_A0 + 1.5, s)
	var r := lerpf(RAMP_R0, (ARC_R0 + ARC_R1) * 0.5, s)
	var y := lerpf(-0.02, ARC_Y + 0.05, s)
	return polar(r, a, y)


func _bent_ramp() -> void:
	var n := 12
	var id := float(next_id)
	next_id += 1
	for i in n:
		var a := _ramp_point(float(i) / n)
		var b := _ramp_point(float(i + 1) / n)
		ramp_pts.append(a)
		var z := (b - a).normalized()
		var x := Vector3.UP.cross(z).normalized()
		var roll := deg_to_rad(6.0 * sin(float(i) / n * TAU))
		x = x.rotated(z, roll)
		var y := z.cross(x).normalized()
		var thick := 0.35
		var seg := (b - a).length() + 0.5
		var c := (a + b) * 0.5 - y * (thick * 0.5)
		solid_box("plane", Transform3D(Basis(x, y, z), c), Vector3(3.2, thick, seg), Vector2(id + i * 0.01, 0), "tile")
	ramp_pts.append(_ramp_point(1.0))


## Grid slabs that intersect the disc, each other and the air.
func _planes() -> void:
	# authored: a pair crossing in an X behind-left of home, one walkable.
	var cx := polar(15.5, 300.0 + rng.randf_range(-8.0, 8.0), 0.0)
	_slab(cx + Vector3(0, 1.6, 0), 300.0 + 90.0, 24.0, 14.0, 22.0, 0.0)
	_slab(cx + Vector3(0, 3.0, 0), 300.0, 70.0, 16.0, 15.0, 8.0)
	# the plane that says you like it here
	_slab(polar(21.0, 255.0, 3.5), 345.0, 82.0, 15.0, 11.0, -4.0, "plane_b")
	var placed := 0
	var tries := 0
	var want := 4 + rng.randi() % 3
	while placed < want and tries < 60:
		tries += 1
		var a := rng.randf_range(-130.0, 5.0)
		var p := polar(rng.randf_range(10.0, 24.0), a, rng.randf_range(-2.0, 3.5))
		var yaw := a + rng.randf_range(-70.0, 70.0)
		var pitch := rng.randf_range(38.0, 86.0)
		var w := rng.randf_range(10.0, 22.0)
		var h := rng.randf_range(6.0, 14.0)
		var roll := rng.randf_range(-12.0, 12.0)
		if not _slab_clear(p, yaw, pitch, w, h, roll):
			continue
		_slab(p, yaw, pitch, w, h, roll, "plane" if placed % 2 == 0 else "plane_b")
		placed += 1


static func _slab_basis(yaw: float, pitch: float, roll: float) -> Basis:
	return Basis(Vector3.UP, deg_to_rad(-yaw)) * Basis(Vector3.RIGHT, deg_to_rad(pitch)) * Basis(Vector3.FORWARD, deg_to_rad(roll))


## Keep random slabs off home, the bent plane, the walk and the upper ring.
func _slab_clear(c: Vector3, yaw: float, pitch: float, w: float, h: float, roll: float) -> bool:
	var bas := _slab_basis(yaw, pitch, roll)
	for i in 7:
		for j in 5:
			var q := c + bas.x * (w * 0.5 * (i / 3.0 - 1.0)) + bas.z * (h * 0.5 * (j / 2.0 - 1.0))
			if q.y < -1.0 or q.y > 9.0:
				continue
			var r := Vector2(q.x, q.z).length()
			if r < 7.0 or (q.z > 18.0 and absf(q.x) < 4.0):
				return false
			for rp in ramp_pts:
				if Vector2(q.x - rp.x, q.z - rp.z).length() < 3.5:
					return false
			var ang := fposmod(rad_to_deg(atan2(q.z, q.x)), 360.0)
			if ang > ARC_A0 - 8.0 and ang < ARC_A1 + 8.0 and r > ARC_R0 - 2.0 and r < ARC_R1 + 2.0:
				return false
	return true


## A thin slab: yaw (deg) of its long axis, pitch (deg) from horizontal.
func _slab(c: Vector3, yaw: float, pitch: float, w: float, h: float, roll: float, m := "plane") -> void:
	var bas := _slab_basis(yaw, pitch, roll)
	var id := float(next_id)
	next_id += 1
	solid_box(m, Transform3D(bas, c), Vector3(w, 0.35, h), Vector2(id, 0), "tile")


## The walk: straight out from the circle's edge to the broken corner of the
## sky, slightly out of true tile by tile.
func _walk() -> void:
	var z := PATH_Z0
	var x := 0.0
	var i := 0
	while z < LAND_Z0:
		var step_len := 1.5
		x = clampf(x + rng.randf_range(-0.22, 0.22), -0.7, 0.7)
		var id := next_id
		next_id += 1
		var y := -0.01 * float(i % 2)
		var shape := solid_box("disc", Transform3D(Basis(Vector3.UP, deg_to_rad(rng.randf_range(-3.0, 3.0))),
			Vector3(x, y - 0.175, z + step_len * 0.5)), Vector3(1.9, 0.35, step_len - 0.06), Vector2(id, 0), "tile")
		tiles.append({"id": id, "pos": Vector3(x, 0.0, z + step_len * 0.5), "shape": shape, "y": 0.0, "r": 99.0, "path": true})
		z += step_len
		i += 1
	# the landing at the foot of the sky
	solid_box("disc", Transform3D(Basis(), Vector3(0, -0.2, (LAND_Z0 + SK) * 0.5)), Vector3(9.0, 0.4, SK - LAND_Z0 + 0.1), Vector2(next_id, 0), "tile")
	next_id += 1
	for k in 3:
		var bx := rng.randf_range(-5.5, 5.5)
		solid_box("disc", Transform3D(Basis(Vector3.UP, rng.randf() * 0.6), Vector3(bx, -0.25, LAND_Z0 - 0.6 - k * 0.4)),
			Vector3(1.6, 0.4, 1.2), Vector2(next_id, 0), "tile")
		next_id += 1


func _skybox() -> void:
	var s := SK
	for f in [[Vector3(s, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, s), Vector3(0, s, 0)],
			[Vector3(-s, 0, 0), Vector3(1, 0, 0), Vector3(0, 0, s), Vector3(0, s, 0)],
			[Vector3(0, 0, s), Vector3(0, 0, -1), Vector3(s, 0, 0), Vector3(0, s, 0)],
			[Vector3(0, 0, -s), Vector3(0, 0, 1), Vector3(s, 0, 0), Vector3(0, s, 0)],
			[Vector3(0, s, 0), Vector3(0, -1, 0), Vector3(s, 0, 0), Vector3(0, 0, s)],
			[Vector3(0, -s, 0), Vector3(0, 1, 0), Vector3(s, 0, 0), Vector3(0, 0, s)]]:
		var c: Vector3 = f[0]
		var u: Vector3 = f[2]
		var v: Vector3 = f[3]
		quad4("sky", [c - u - v, c + u - v, c + u + v, c - u + v], f[1], Vector2.ZERO)
		if absf(c.y) < 1.0:
			var size := Vector3(1.0, s * 2.0, s * 2.0 + 1.0) if absf(c.x) > 1.0 else Vector3(s * 2.0 + 1.0, s * 2.0, 1.0)
			col.add_box_shape(Transform3D(Basis(), c + c.normalized() * 0.5), size, "tile")


## "deeper": the circle again, far below, dim and out of reach.
func _deeper() -> void:
	for ring in range(1, 11):
		var n := maxi(6, _sector_count(ring) / 2)
		var off := rng.randf() * 360.0 / n
		for j in n:
			if rng.randf() < 0.18:
				continue
			sector("disc_deep", ring * RING_W * 1.3, (ring + 1) * RING_W * 1.3, off + 360.0 * j / n, off + 360.0 * (j + 1) / n, -34.0, 0.5, false)
	var root := Node3D.new()
	root.name = "Deeper"
	L.add_child(root)
	commit(root, false)


func _prism(size: Vector3, apex: float) -> PrismMesh:
	var pm := PrismMesh.new()
	pm.size = size
	pm.left_to_right = apex
	return pm


func _shards() -> void:
	var root := Node3D.new()
	root.name = "SkyShards"
	L.add_child(root)
	var body := StaticBody3D.new()
	body.name = "ShardCollision"
	root.add_child(body)
	# big pieces of sky stuck into the circle
	for i in 4:
		var a := rng.randf_range(-150.0, 5.0) if i < 3 else rng.randf_range(225.0, 240.0)
		var p := polar(rng.randf_range(11.0, 23.0), a, 0.0)
		var mi := MeshInstance3D.new()
		var sz := Vector3(rng.randf_range(2.5, 4.5), rng.randf_range(6.0, 11.0), 0.25)
		mi.mesh = _prism(sz, rng.randf_range(0.15, 0.85))
		mi.material_override = mats["shard"]
		mi.position = p + Vector3(0, sz.y * 0.5 - rng.randf_range(0.8, 2.0), 0)
		mi.rotation = Vector3(rng.randf_range(-0.35, 0.35), rng.randf() * TAU, rng.randf_range(-0.4, 0.4))
		root.add_child(mi)
		var cs := CollisionShape3D.new()
		cs.shape = mi.mesh.create_convex_shape()
		cs.transform = mi.transform
		body.add_child(cs)
	# pieces drifting in the air over the circle
	for i in 30:
		var mi := MeshInstance3D.new()
		var s := rng.randf_range(0.5, 2.6)
		mi.mesh = _prism(Vector3(s * 0.45, s, 0.06), rng.randf())
		mi.material_override = mats["shard"]
		var base := polar(rng.randf_range(6.0, 30.0), rng.randf() * 360.0, rng.randf_range(3.0, 16.0))
		if i % 3 == 0:     # some drift over the walk, falling slowly towards the break
			base = Vector3(rng.randf_range(-9.0, 9.0), rng.randf_range(3.5, 13.0), rng.randf_range(12.0, 58.0))
		mi.position = base
		mi.rotation = Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
		air_shards.append({"node": mi, "spin": Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(-0.3, 0.3), 0.0),
			"bob": rng.randf() * TAU, "base": base})
	# fallen pieces at the foot of the broken corner
	for i in 10:
		var mi := MeshInstance3D.new()
		var s := rng.randf_range(0.3, 1.1)
		mi.mesh = _prism(Vector3(s * 0.5, s, 0.05), rng.randf())
		mi.material_override = mats["shard"]
		mi.position = Vector3(rng.randf_range(-4.0, 4.0), 0.03, rng.randf_range(LAND_Z0 + 1.0, SK - 0.8))
		mi.rotation = Vector3(PI * 0.5 + rng.randf_range(-0.25, 0.25), rng.randf() * TAU, 0.0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
	# the sharpest one, leaning, catching light
	sharp = MeshInstance3D.new()
	(sharp as MeshInstance3D).mesh = _prism(Vector3(0.22, 1.25, 0.04), 0.12)
	(sharp as MeshInstance3D).material_override = mats["shard_sharp"]
	sharp.position = Vector3(1.6, 0.6, SK - 2.4)
	sharp.rotation = Vector3(0.12, 0.6, -0.32)
	root.add_child(sharp)


## Memory fragments: three datamoshed panels hung in the air.
func _fragments() -> void:
	var spots := [polar(16.8, 203.0, ARC_Y + 0.3 + 1.55), Vector3(1.9, 1.7, 44.0), Vector3(-3.4, 1.75, SK - 3.5)]
	var looks := [Vector3(0, ARC_Y + 1.6, 0), Vector3(-6.0, 1.6, 36.0), Vector3(2.0, 1.6, LAND_Z0)]
	for i in 3:
		var mi := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(2.3, 1.5)
		mi.mesh = qm
		mi.material_override = mats["frag%d" % i]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		L.add_child(mi)
		mi.look_at_from_position(spots[i], looks[i], Vector3.UP)
		mi.rotate_object_local(Vector3.UP, PI)
		frag_nodes.append(mi)


func _label(text: String, pos: Vector3, bas: Basis, px: float, color: Color, font: Font, keep: bool) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = font
	l.font_size = 160
	l.pixel_size = px
	l.modulate = color
	l.outline_size = 0
	l.double_sided = true
	l.shaded = false
	l.transform = Transform3D(bas, pos)
	L.add_child(l)
	words.append({"label": l, "text": text, "keep": keep, "color": color})
	return l


## The page's words, lying in the world: a few lower-case fragments written
## into the surfaces (paraphrase/short echoes only).
func _words() -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["DejaVu Serif", "Liberation Serif", "Times New Roman", "serif"])
	font.font_italic = true
	var flat_up := Basis(Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0))
	_label("home", Vector3(0, 0.03, 1.2), flat_up, 0.022, Color(0.55, 0.45, 0.85, 0.62), font, true)
	# written on the slab that leans over the back of the circle
	var wpos := polar(21.0, 255.0, 0.0)
	var face := (-wpos).normalized()
	var lb := Basis(face.cross(Vector3.UP).normalized() * -1.0, Vector3.UP, face)
	_label("you like it here", wpos + face * 0.45 + Vector3(0, 3.8, 0), lb, 0.0105, Color(0.48, 0.42, 0.9, 0.8), font, false)
	# along the walk, one word to a few tiles
	var wd := ["walk", "with", "me"]
	for i in 3:
		_label(wd[i], Vector3(0.0, 0.03, 30.0 + i * 7.5), flat_up, 0.0055, Color(0.5, 0.42, 0.8, 0.7), font, false)
	# her laugh, in bytes, on the sky beside the break
	var sky_b := Basis(Vector3(-1, 0, 0), Vector3.UP, Vector3(0, 0, -1))
	_label("68 61 68 61", Vector3(7.2, 7.5, SK - 0.4), sky_b, 0.018, Color(1.0, 0.55, 0.85, 0.9), font, false)
	# written across the top of the sky
	var down := Basis(Vector3(-1, 0, 0), Vector3(0, 0, -1), Vector3(0, -1, 0))
	_label("come home", Vector3(0, SK - 0.5, 8.0), down, 0.16, Color(1.0, 1.0, 1.0, 0.42), font, true)
	# far below, through the holes
	_label("404", World_404_POS, flat_up, 0.1, Color(0.85, 0.55, 0.95, 0.55), font, true)
