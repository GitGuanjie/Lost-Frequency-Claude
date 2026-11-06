extends RefCounted
## Level 10 structures (SOURCE: "small wooden sheds and outbuildings, as well as
## larger barns and stables ... largely empty ... wood and nails"). Built in a
## local frame: x across [0, w] with the door side at x = 0 facing the track,
## z along [0, d], y up from the floor. Barns carry a hay loft on stairs
## (ADAPTATION: ordinary barn anatomy; the page gives no interior plan).

var k: GeoKit
var xf: Transform3D
var r: RandomNumberGenerator


func _init(kit: GeoKit, frame: Transform3D, rand: RandomNumberGenerator) -> void:
	k = kit
	xf = frame
	r = rand


func P(x: float, y: float, z: float) -> Vector3:
	return xf * Vector3(x, y, z)


func bx(a: Vector3, b: Vector3, mat: String, col: bool = true) -> void:
	var mn := a.min(b)
	var mx := a.max(b)
	k.box_xf(Transform3D(xf.basis, xf * ((mn + mx) * 0.5)), mx - mn, mat, GeoKit.ALL, col)


func wall(a: Vector3, b: Vector3, h: float, mat: String, ops: Array = [], th: float = 0.16) -> void:
	k.wall(xf * a, xf * b, h, th, mat, ops)


## Two-sided flat polygon (gables, side infills).
func poly(pts: Array, mat: String) -> void:
	var wp: Array = []
	for q in pts:
		wp.append(xf * (q as Vector3))
	var n: Vector3 = ((wp[1] as Vector3) - wp[0]).cross((wp[2] as Vector3) - wp[0]).normalized()
	for side in 2:
		var s := k._s(mat)
		var base: int = s["v"].size()
		var nn := n if side == 0 else -n
		var tu := Vector3(-nn.z, 0.0, nn.x).normalized()
		for q in wp:
			var p: Vector3 = q
			s["v"].append(p + nn * 0.01)
			s["n"].append(nn)
			s["uv"].append(Vector2(p.dot(tu), -p.y))
			s["uv2"].append(Vector2.ZERO)
		for t in range(1, wp.size() - 1):
			if side == 0:
				s["i"].append_array([base, base + t + 1, base + t])
			else:
				s["i"].append_array([base, base + t, base + t + 1])


## Pitched roof plane as a thin rotated box from eave (x0, y0) to ridge (x1, y1).
func roof_plane(x0: float, y0: float, x1: float, y1: float, z0: float, z1: float, mat: String, col: bool = true, lift: float = 0.06) -> void:
	var dx := x1 - x0
	var dy := y1 - y0
	var ang := atan2(dy, dx)
	var bas := xf.basis * Basis(Vector3(0, 0, 1), ang)
	var c := xf * Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5 + lift, (z0 + z1) * 0.5)
	k.box_xf(Transform3D(bas, c), Vector3(sqrt(dx * dx + dy * dy), 0.12, z1 - z0), mat, GeoKit.ALL, col)


func gable_roof(w: float, d: float, eave: float, ridge: float, mat: String, wallm: String) -> void:
	roof_plane(-0.5, eave - 0.3, w * 0.5, ridge, -0.45, d + 0.45, mat)
	roof_plane(w + 0.5, eave - 0.3, w * 0.5, ridge, -0.45, d + 0.45, mat)
	roof_plane(0.0, eave - 0.05, w * 0.5, ridge - 0.05, 0.0, d, "l10_rafter_wood", false, -0.1)
	roof_plane(w, eave - 0.05, w * 0.5, ridge - 0.05, 0.0, d, "l10_rafter_wood", false, -0.1)
	for z in [0.0, d]:
		poly([Vector3(0, eave, z), Vector3(w * 0.5, ridge, z), Vector3(w, eave, z)], wallm)


## Darker inner lining: the scene's sky ambient is not occluded by the walls, so
## interiors read dim through their surfaces. ops per side [x=0, x=w, z=0, z=d]
## ("at" measured from 0.1 m along the wall); null = no lining on that side.
func lining(w: float, d: float, h: float, ops: Array, gable: float = 0.0) -> void:
	var sides := [[Vector3(0.1, 0, 0.1), Vector3(0.1, 0, d - 0.1)], [Vector3(w - 0.1, 0, 0.1), Vector3(w - 0.1, 0, d - 0.1)],
		[Vector3(0.1, 0, 0.1), Vector3(w - 0.1, 0, 0.1)], [Vector3(0.1, 0, d - 0.1), Vector3(w - 0.1, 0, d - 0.1)]]
	for i in 4:
		if ops[i] != null:
			wall(sides[i][0], sides[i][1], h, "l10_board_in", ops[i], 0.02)
	if gable > h:
		for z in [0.12, d - 0.12]:
			poly([Vector3(0.1, h, z), Vector3(w * 0.5, gable - 0.1, z), Vector3(w - 0.1, h, z)], "l10_board_in")


func plank_stack(c: Vector3, ln: float, layers: int, yaw: bool) -> void:
	var s := Vector3(ln, 0.045, 0.85) if yaw else Vector3(0.85, 0.045, ln)
	var hx := 0.03 if yaw else 0.42
	var hz := 0.42 if yaw else 0.03
	for l in layers:
		var y := c.y + l * 0.1
		bx(Vector3(c.x - s.x * 0.5, y + 0.055, c.z - s.z * 0.5), Vector3(c.x + s.x * 0.5, y + 0.1, c.z + s.z * 0.5), "l10_plank_wood", false)
		for t in [-0.4, 0.0, 0.4]:
			var o := Vector3(c.x + t * ln, y, c.z) if yaw else Vector3(c.x, y, c.z + t * ln)
			bx(o + Vector3(-hx, 0, -hz), o + Vector3(hx, 0.055, hz), "l10_beam_wood", false)
	k.add_box_shape(Transform3D(xf.basis, xf * (c + Vector3(0, layers * 0.05, 0))), Vector3(s.x, layers * 0.1, s.z), "wood")


func nails(c: Vector3) -> void:
	bx(c + Vector3(-0.22, 0, -0.16), c + Vector3(0.22, 0.26, 0.16), "l10_beam_wood")
	bx(c + Vector3(-0.19, 0.26, -0.13), c + Vector3(0.19, 0.3, 0.13), "l10_nails_metal", false)


## Returns {"inside": AABB (world), "door": world point outside the main door}.
func build(kind: String, red: bool) -> Dictionary:
	match kind:
		"barn":
			return barn(red)
		"stable":
			return stable()
		"shed":
			return shed()
	return cart()


func barn(red: bool) -> Dictionary:
	var w := 12.0
	var d := 26.0
	var eave := 5.2
	var ridge := 9.2
	var bm := "l10_board_red" if red else "l10_board"
	bx(Vector3(0, -0.8, 0), Vector3(w, 0, d), "l10_floor_dirt")
	var door := [{"at": d * 0.5, "w": 4.6, "h": 4.4}]
	for x in [0.0, w]:
		wall(Vector3(x, -0.6, 0), Vector3(x, -0.6, d), 1.3, "l10_stone", [{"at": d * 0.5, "w": 4.6, "h": 5.0}], 0.5)
		wall(Vector3(x, 0.7, 0), Vector3(x, 0.7, d), eave - 0.7, bm, [{"at": d * 0.5, "w": 4.6, "h": 3.7}])
	wall(Vector3(0, -0.6, 0), Vector3(w, -0.6, 0), 1.3, "l10_stone", [{"at": 3.0, "w": 1.1, "h": 3.0}], 0.5)
	wall(Vector3(0, 0.7, 0), Vector3(w, 0.7, 0), eave - 0.7, bm, [{"at": 3.0, "w": 1.1, "h": 1.5}])
	wall(Vector3(0, -0.6, d), Vector3(w, -0.6, d), 1.3, "l10_stone", [], 0.5)
	wall(Vector3(0, 0.7, d), Vector3(w, 0.7, d), eave - 0.7, bm)
	gable_roof(w, d, eave, ridge, "l10_tin", bm)
	var dop := [{"at": d * 0.5 - 0.1, "w": 4.6, "h": 4.4}]
	lining(w, d, eave, [dop, dop, [{"at": 2.9, "w": 1.1, "h": 2.2}], []], ridge)
	# loft door (closed, dark) high in the back gable
	bx(Vector3(w * 0.5 - 0.9, 5.6, d - 0.05), Vector3(w * 0.5 + 0.9, 7.2, d + 0.12), "l10_beam_wood", false)
	# timber frame: posts and tie beams at the bay lines
	for z in [4.3, 8.7, 17.3, 21.7]:
		for x in [0.25, w - 0.25]:
			bx(Vector3(x - 0.13, 0, z - 0.13), Vector3(x + 0.13, eave, z + 0.13), "l10_beam_wood")
		bx(Vector3(0.1, eave - 0.32, z - 0.12), Vector3(w - 0.1, eave - 0.06, z + 0.12), "l10_beam_wood", false)
		bx(Vector3(w * 0.5 - 0.1, eave - 0.06, z - 0.1), Vector3(w * 0.5 + 0.1, ridge - 0.25, z + 0.1), "l10_beam_wood", false)
	# hay loft over the back bay, reached by stairs along the far wall
	var ly := 3.3
	bx(Vector3(0.18, ly - 0.16, d - 8.0), Vector3(w - 0.18, ly, d - 0.18), "l10_loft_wood")
	for x in [2.5, 6.0, 9.5]:
		bx(Vector3(x - 0.12, ly - 0.42, d - 8.0), Vector3(x + 0.12, ly - 0.16, d - 0.2), "l10_beam_wood", false)
	for x in [0.5, 4.0, 7.6]:
		bx(Vector3(x - 0.06, ly, d - 8.06), Vector3(x + 0.06, ly + 1.0, d - 7.94), "l10_beam_wood", false)
	bx(Vector3(0.2, ly + 0.92, d - 8.07), Vector3(w - 1.7, ly + 1.02, d - 7.93), "l10_beam_wood")
	k.stairs(P(w - 0.85, 0.0, d - 8.0 - 15 * 0.27), xf.basis * Vector3(0, 0, 1), 0.9, ly, 15, "l10_loft_wood", 0.27, false)
	for sx in [w - 1.33, w - 0.37]:
		var sa := P(sx, 0.0, d - 8.0 - 15 * 0.27 - 0.1)
		var sb := P(sx, ly + 0.08, d - 8.0)
		var dz := sb - sa
		var bas := Basis(xf.basis.x, dz.normalized().cross(xf.basis.x).normalized() * -1.0, dz.normalized())
		k.box_xf(Transform3D(bas, (sa + sb) * 0.5), Vector3(0.06, 0.26, dz.length()), "l10_beam_wood", GeoKit.ALL, false)
	bx(Vector3(w - 1.4, 0, d - 8.0 - 0.15), Vector3(w - 1.3, ly, d - 8.0), "l10_beam_wood", false)
	# what the page says these hold: wood and nails
	plank_stack(Vector3(1.4, 0, 3.0), 3.6, 6, false)
	plank_stack(Vector3(2.5, 0, 22.0), 4.2, 9, false)
	plank_stack(Vector3(6.0, ly, d - 3.0), 3.2, 4, true)
	for p in [Vector3(10.6, 0, 3.4), Vector3(10.9, 0, 4.2), Vector3(10.2, 0, 21.0), Vector3(3.2, ly, d - 1.0)]:
		nails(p)
	for i in 5:
		var z := 8.0 + i * 0.45
		bx(Vector3(w - 0.55, 0, z), Vector3(w - 0.5, 3.4, z + 0.2), "l10_plank_wood", false)
	return {"inside": _aabb(Vector3(0.3, 0, 0.3), Vector3(w - 0.3, eave, d - 0.3)), "door": P(-2.5, 0, d * 0.5),
		"loft": P(w * 0.5, ly, d - 4.0), "size": Vector2(w, d), "eave": eave}


func stable() -> Dictionary:
	var w := 8.0
	var d := 21.0
	var eave := 3.0
	bx(Vector3(0, -0.8, 0), Vector3(w, 0, d), "l10_floor_dirt")
	var ops: Array = []
	for z in [2.4, 6.9, 11.4, 15.9]:
		ops.append({"at": z, "w": 1.3, "h": 2.6})
	wall(Vector3(0, -0.4, 0), Vector3(0, -0.4, d), eave + 0.4, "l10_board", ops)
	wall(Vector3(w, -0.4, 0), Vector3(w, -0.4, d), eave + 0.4, "l10_board", [{"at": 9.0, "w": 1.0, "h": 0.6, "sill": 1.7}])
	wall(Vector3(0, -0.4, 0), Vector3(w, -0.4, 0), eave + 0.4, "l10_board", [{"at": 6.6, "w": 1.8, "h": 3.0}])
	wall(Vector3(0, -0.4, d), Vector3(w, -0.4, d), eave + 0.4, "l10_board")
	gable_roof(w, d, eave, 5.0, "l10_tin", "l10_board")
	var sop: Array = []
	for z in [2.3, 6.8, 11.3, 15.8]:
		sop.append({"at": z, "w": 1.3, "h": 2.2})
	lining(w, d, eave, [sop, [{"at": 8.9, "w": 1.0, "h": 0.6, "sill": 1.3}], [{"at": 6.5, "w": 1.8, "h": 2.6}], []], 5.0)
	for z in [4.6, 9.1, 13.6, 18.1]:
		bx(Vector3(0.1, 0, z - 0.05), Vector3(5.0, 1.45, z + 0.05), "l10_loft_wood")
		bx(Vector3(4.95, 0, z - 0.08), Vector3(5.11, 2.3, z + 0.08), "l10_beam_wood")
	for z in [2.4, 6.9, 11.4, 15.9]:
		bx(Vector3(0.1, 0.9, z - 0.7), Vector3(0.5, 1.05, z + 0.7), "l10_beam_wood", false)
	plank_stack(Vector3(6.6, 0, 16.0), 3.0, 5, false)
	nails(Vector3(7.3, 0, 3.0))
	return {"inside": _aabb(Vector3(0.2, 0, 0.2), Vector3(w - 0.2, eave, d - 0.2)), "door": P(-2.0, 0, 2.4), "size": Vector2(w, d), "eave": eave}


func shed() -> Dictionary:
	var w := 4.0
	var d := 5.0
	bx(Vector3(0, -0.8, 0), Vector3(w, 0.02, d), "l10_loft_wood")
	wall(Vector3(0, -0.3, 0), Vector3(0, -0.3, d), 3.2, "l10_board", [{"at": 2.5, "w": 1.0, "h": 2.35}])
	wall(Vector3(w, -0.3, 0), Vector3(w, -0.3, d), 2.6, "l10_board")
	for z in [0.0, d]:
		wall(Vector3(0, -0.3, z), Vector3(w, -0.3, z), 2.6, "l10_board")
		poly([Vector3(0, 2.3, z), Vector3(0, 2.9, z), Vector3(w, 2.3, z)], "l10_board")
	roof_plane(w + 0.4, 2.22, -0.4, 2.98, -0.35, d + 0.35, "l10_tin")
	lining(w, d, 2.3, [[{"at": 2.4, "w": 1.0, "h": 2.05}], [], [], []])
	bx(Vector3(w - 0.55, 1.1, 0.3), Vector3(w - 0.1, 1.14, d - 0.3), "l10_loft_wood", false)
	nails(Vector3(w - 0.33, 1.14, 1.2))
	nails(Vector3(w - 0.33, 1.14, 3.6))
	plank_stack(Vector3(2.0, 0.02, 4.0), 2.4, 3, true)
	return {"inside": _aabb(Vector3(0.1, 0, 0.1), Vector3(w - 0.1, 2.3, d - 0.1)), "door": P(-1.5, 0, 2.5), "size": Vector2(w, d), "eave": 2.6}


func cart() -> Dictionary:
	var w := 7.0
	var d := 11.0
	bx(Vector3(0, -0.8, 0), Vector3(w, 0, d), "l10_floor_dirt")
	wall(Vector3(w, -0.4, 0), Vector3(w, -0.4, d), 3.2, "l10_board")
	for z in [0.0, d]:
		wall(Vector3(0.3, -0.4, z), Vector3(w, -0.4, z), 3.2, "l10_board")
		poly([Vector3(0.3, 2.8, z), Vector3(0.3, 3.6, z), Vector3(w, 2.8, z)], "l10_board")
	for z in [0.15, 3.67, 7.33, d - 0.15]:
		bx(Vector3(0.1, 0, z - 0.14), Vector3(0.38, 3.6, z + 0.14), "l10_beam_wood")
	bx(Vector3(0.08, 3.3, -0.1), Vector3(0.4, 3.6, d + 0.1), "l10_beam_wood", false)
	roof_plane(-0.5, 3.66, w + 0.4, 2.78, -0.4, d + 0.4, "l10_tin")
	lining(w, d, 2.8, [null, [], [], []])
	plank_stack(Vector3(4.6, 0, 3.0), 3.4, 8, false)
	plank_stack(Vector3(4.6, 0, 8.0), 3.4, 5, false)
	nails(Vector3(6.3, 0, 5.6))
	return {"inside": _aabb(Vector3(0.1, 0, 0.1), Vector3(w - 0.1, 2.8, d - 0.1)), "door": P(-2.0, 0, d * 0.5), "size": Vector2(w, d), "eave": 2.8}


func _aabb(a: Vector3, b: Vector3) -> AABB:
	var p := P(a.x, a.y, a.z)
	var q := P(b.x, b.y, b.z)
	return AABB(p.min(q), (q - p).abs())


## Cheap far-LOD silhouette (no collision).
func far(kind: String, red: bool) -> void:
	var dm: Vector2 = {"barn": Vector2(12, 26), "stable": Vector2(8, 21), "shed": Vector2(4, 5), "cart": Vector2(7, 11)}[kind]
	var eave: float = {"barn": 5.2, "stable": 3.0, "shed": 2.6, "cart": 3.0}[kind]
	var ridge: float = {"barn": 9.2, "stable": 5.0, "shed": 2.9, "cart": 3.4}[kind]
	var bm := "l10_board_red" if red else "l10_board"
	bx(Vector3(0, -0.6, 0), Vector3(dm.x, eave, dm.y), bm, false)
	roof_plane(-0.4, eave - 0.2, dm.x * 0.5, ridge, -0.3, dm.y + 0.3, "l10_tin", false)
	roof_plane(dm.x + 0.4, eave - 0.2, dm.x * 0.5, ridge, -0.3, dm.y + 0.3, "l10_tin", false)
	for z in [0.0, dm.y]:
		poly([Vector3(0, eave, z), Vector3(dm.x * 0.5, ridge, z), Vector3(dm.x, eave, z)], bm)
