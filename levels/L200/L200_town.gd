extends RefCounted
## Level 200 "Home" — the town around the house. SOURCE: "the nicest little
## town", not too big, nothing that stands out; Joe Vee's breakfast place; the
## school with its dark, cold basement ("Below, below, below"); about 4,000
## residents ("Everyone's here"). The page's licence box credits a photo of a
## small-town Main Street, which sets the look: two-storey brick and clapboard
## fronts, utility poles, frame houses with porches.
## ADAPTATION: one block of Main Street (x -56..56): frame houses on the north
## side, storefronts, the diner and the school on the south side; a T-junction
## at each end where the townspeople stand shoulder to shoulder across the road
## (the street ends in people and fog, never in a world edge). Bare trees and an
## overcast "bleak blue sky" come from the page's remembered mornings.

const FX := preload("res://levels/L200/L200_fx.gd")
const NORTH_LOTS := [-48.0, -32.0, -16.0, 16.0, 32.0, 48.0]
const SW_N := 12.5     # north sidewalk 12.5..14.5
const ROAD0 := 14.5
const ROAD1 := 20.5
const SW_S := 22.5     # south sidewalk 20.5..22.5, building fronts at 22.5
const END_X := 52.5    # first row of the crowd
const PIT := [20.25, 26.25, 25.7, 28.0]
const DINER := [-12.0, -1.0]
const DINER_Y := 0.28


static func ground(k: GeoKit) -> void:
	k.slab(-220, -170, 220, SW_N, 0.0, 0.3, "l200_grass", GeoKit.PY)
	k.slab(-220, SW_N, 220, ROAD0, 0.1, 0.4, "l200_sidewalk", GeoKit.PY | GeoKit.SIDES)
	k.slab(-220, ROAD0, 220, ROAD1, 0.0, 0.3, "l200_asphalt", GeoKit.PY)
	k.slab(-220, ROAD1, 220, SW_S, 0.1, 0.4, "l200_sidewalk", GeoKit.PY | GeoKit.SIDES)
	for x in [-1.0, 1.0]:
		k.slab(x * 58.0, -170, x * 66.0, SW_N, 0.01, 0.3, "l200_asphalt", GeoKit.PY)
	# south side ground, leaving the school's basement areaway open
	k.slab(-220, SW_S, PIT[0] - 1.25, 200, 0.0, 0.3, "l200_concrete", GeoKit.PY)
	k.slab(45.0, SW_S, 220, 200, 0.0, 0.3, "l200_concrete", GeoKit.PY)
	k.slab(PIT[0] - 1.25, SW_S, 45.0, PIT[1], 0.0, 0.3, "l200_asphalt", GeoKit.PY)
	k.slab(PIT[0] - 1.25, PIT[1], PIT[0], PIT[3], 0.0, 0.3, "l200_asphalt", GeoKit.PY)
	k.slab(PIT[2], PIT[1], 45.0, PIT[3], 0.0, 0.3, "l200_asphalt", GeoKit.PY)
	k.slab(25.5, 26.7, PIT[2], 27.7, 0.0, 0.3, "l200_asphalt", GeoKit.PY)
	k.slab(PIT[0] - 1.25, PIT[3], 45.0, 200, 0.0, 0.3, "l200_concrete", GeoKit.PY)
	# road markings and curbs
	for x in range(-56, 57, 6):
		k.box(Vector3(x, 0.005, (ROAD0 + ROAD1) * 0.5), Vector3(3.0, 0.01, 0.12), "l200_trim", GeoKit.ALL, false)


## A closed frame house (not enterable). v picks colour and roof direction.
static func nhouse(k: GeoKit, cx: float, v: int) -> void:
	var w := 9.0 + float(v % 3) * 0.6
	var x0 := cx - w * 0.5
	var x1 := cx + w * 0.5
	var z0 := -4.0
	var z1 := 4.0
	var e := 6.0
	var mat := "l200_sid%d" % (v % 5)
	k.box_mm(Vector3(x0 - 0.02, -0.1, z0 - 0.02), Vector3(x1 + 0.02, 0.5, z1 + 0.02), "l200_concrete")
	k.box_mm(Vector3(x0, 0.5, z0), Vector3(x1, e, z1), mat)
	var ridge_x := v % 2 == 0
	var roof := "l200_roof" if v % 3 != 1 else "l200_roof_b"
	if ridge_x:
		for s in [-1.0, 1.0]:
			_plane(k, Vector3(cx, e - 0.2, s * (z1 + 0.45)), Vector3(cx, e + 2.4, 0), w + 0.7, roof)
			FX.tri(k, Vector3(x0 if s < 0 else x1, e, z0), Vector3(x0 if s < 0 else x1, e, z1), Vector3(x0 if s < 0 else x1, e + 2.35, 0), Vector3(s, 0, 0), mat)
	else:
		for s in [-1.0, 1.0]:
			_plane(k, Vector3(cx + s * (w * 0.5 + 0.45), e - 0.2, 0), Vector3(cx, e + 2.6, 0), 8.7, roof, true)
			FX.tri(k, Vector3(x0, e, s * z1), Vector3(x1, e, s * z1), Vector3(cx, e + 2.55, s * z1), Vector3(0, 0, s), mat)
	# windows (dark glass, casings) on the street face and the sides
	for fl in [1.4, 4.1]:
		for i in 3:
			var x := x0 + w * (0.2 + 0.3 * i)
			if fl < 2.0 and i == 1:
				continue
			_win(k, Vector3(x, fl, z1), Vector3(0, 0, 1), 1.0, 1.4)
		for s in [-1.0, 1.0]:
			_win(k, Vector3(x1 if s > 0 else x0, fl, 1.2), Vector3(s, 0, 0), 0.9, 1.3)
			_win(k, Vector3(x0 + w * (0.25 + 0.5 * (s * 0.5 + 0.5)), fl, z0), Vector3(0, 0, -1), 1.0, 1.3)
	# porch, door, steps
	k.box_mm(Vector3(cx - 1.8, 0, z1), Vector3(cx + 1.8, 0.54, z1 + 1.8), "l200_fence_wood")
	k.stairs(Vector3(cx, 0, z1 + 2.61), Vector3(0, 0, -1), 1.4, 0.54, 3, "l200_fence_wood", 0.27)
	k.box_mm(Vector3(cx - 0.5, 0.54, z1 - 0.02), Vector3(cx + 0.5, 2.64, z1 + 0.04), "l200_dark")
	k.box_xf(Transform3D(Basis(Vector3.RIGHT, 0.15), Vector3(cx, 2.95, z1 + 0.95)), Vector3(4.0, 0.1, 2.1), roof, GeoKit.ALL, false)
	for x in [cx - 1.7, cx + 1.7]:
		k.box(Vector3(x, 1.7, z1 + 1.72), Vector3(0.12, 2.3, 0.12), "l200_trim")
	k.box_mm(Vector3(cx - 0.6, -0.05, z1 + 2.61), Vector3(cx + 0.6, 0.03, SW_N), "l200_sidewalk", GeoKit.PY | GeoKit.SIDES)


static func _plane(k: GeoKit, lo: Vector3, hi: Vector3, width: float, mat: String, along_z := false) -> void:
	var d := hi - lo
	var z := d.normalized()
	var side := Vector3.BACK if along_z else Vector3.RIGHT
	var y := z.cross(side).normalized()
	if y.y < 0:
		y = -y
	var x := y.cross(z).normalized()
	k.box_xf(Transform3D(Basis(x, y, z), (lo + hi) * 0.5 + y * 0.06), Vector3(width, 0.12, d.length()), mat, GeoKit.ALL, false)


static func _win(k: GeoKit, c: Vector3, n: Vector3, w: float, h: float, lit := false) -> void:
	var a := Vector3(-n.z, 0, n.x).abs()
	var p := c + Vector3(0, h * 0.5, 0) + n * 0.01
	k.box(p, a * w + n.abs() * 0.02 + Vector3(0, h, 0), "l200_win_lit" if lit else "l200_glass", GeoKit.ALL, false)
	k.box(p + n * 0.02, a * 0.05 + n.abs() * 0.03 + Vector3(0, h, 0), "l200_trim", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		k.box(p + a * s * (w * 0.5 + 0.05), a * 0.1 + n.abs() * 0.08 + Vector3(0, h + 0.1, 0), "l200_trim", GeoKit.ALL, false)
		k.box(p + Vector3(0, s * (h * 0.5 + 0.05), 0) + n * 0.03, a * (w + 0.25) + n.abs() * 0.1 + Vector3(0, 0.08, 0), "l200_trim", GeoKit.ALL, false)


## Storefront: brick or clapboard two-storey block, shop window, upper windows.
static func store(k: GeoKit, x0: float, x1: float, v: int, lit_upper: int) -> void:
	var h := 7.2 + float(v % 3) * 0.7
	var mat: String = ["l200_brick", "l200_brick_b", "l200_sid2", "l200_brick", "l200_sid4"][v % 5]
	k.box_mm(Vector3(x0, 0, SW_S + 0.3), Vector3(x1, h, SW_S + 10.0), mat)
	var w := x1 - x0
	k.wall(Vector3(x0, 0, SW_S + 0.15), Vector3(x1, 0, SW_S + 0.15), h, 0.3, mat,
		[{"at": (w - 1.6) * 0.5, "w": w - 3.2, "h": 2.3, "sill": 0.55}, {"at": w - 1.1, "w": 1.0, "h": 2.3, "sill": 0.1}])
	k.box_mm(Vector3(x0 + 0.8, 0.55, SW_S + 0.28), Vector3(x1 - 2.4, 2.85, SW_S + 0.3), "l200_glass", GeoKit.ALL, false)
	k.box_mm(Vector3(x1 - 1.6, 0.1, SW_S + 0.26), Vector3(x1 - 0.6, 2.4, SW_S + 0.3), "l200_dark", GeoKit.ALL, false)
	var n := int(w / 2.6)
	for i in n:
		var x := x0 + w * (i + 0.5) / n
		_win(k, Vector3(x, 3.9, SW_S - 0.0), Vector3(0, 0, -1), 1.0, 1.6, i == lit_upper)
	k.box_mm(Vector3(x0, h, SW_S - 0.15), Vector3(x1, h + 0.35, SW_S + 0.3), "l200_trim", GeoKit.ALL, false)
	k.box_mm(Vector3(x0, 3.05, SW_S - 0.1), Vector3(x1, 3.4, SW_S + 0.05), "l200_trim", GeoKit.ALL, false)
	if v % 2 == 0:
		k.box_xf(Transform3D(Basis(Vector3.RIGHT, -0.35), Vector3((x0 + x1) * 0.5 - 0.8, 2.95, SW_S - 0.65)), Vector3(w - 2.6, 0.06, 1.4), "l200_awning", GeoKit.ALL, false)


static func storefronts(k: GeoKit) -> void:
	var cuts := [-58.0, -46.0, -36.0, -24.0, DINER[0]]
	for i in cuts.size() - 1:
		store(k, cuts[i], cuts[i + 1], i, (i * 2) % 3)
	store(k, DINER[1], 8.0, 5, 1)
	store(k, 8.0, 19.0, 6, -1)
	store(k, 45.0, 58.0, 7, 0)
	# the back of the block: taller rears and rooftops beyond the fronts
	var r := RandomNumberGenerator.new()
	r.seed = 2001
	var x := -64.0
	while x < 64.0:
		var bw := r.randf_range(8.0, 14.0)
		var bh := r.randf_range(8.5, 13.0)
		var z0 := r.randf_range(36.0, 44.0)
		k.box_mm(Vector3(x, 0, z0), Vector3(x + bw - 0.4, bh, z0 + 12.0), ["l200_brick_b", "l200_brick", "l200_concrete", "l200_sid1"][r.randi() % 4])
		for wx in range(1, int(bw / 2.6)):
			_win(k, Vector3(x + wx * 2.6, bh - 3.2, z0), Vector3(0, 0, -1), 1.0, 1.5, r.randf() < 0.12)
		x += bw
	# the T-junctions: a closing row of fronts across each end
	for s in [-1.0, 1.0]:
		k.box_mm(Vector3(66.0 if s > 0 else -76.0, 0, -80), Vector3(76.0 if s > 0 else -66.0, 9.0, 90), "l200_brick_b")
		for z in range(-10, 40, 4):
			_win(k, Vector3(s * 65.9, 4.0, float(z)), Vector3(-s, 0, 0), 1.0, 1.6)


## Joe Vee's breakfast place: enterable single-storey diner.
static func diner(k: GeoKit) -> void:
	var x0: float = DINER[0]
	var x1: float = DINER[1]
	var y := DINER_Y
	var zf := SW_S
	var zb := 31.8
	var wd := x1 - x0
	k.box_mm(Vector3(x0, 0, zf), Vector3(x1, y, zb), "l200_concrete")
	k.box_mm(Vector3(x0, y - 0.02, zf + 0.2), Vector3(x1, y, zb), "l200_diner_floor", GeoKit.PY)
	k.wall(Vector3(x0, y, zf + 0.1), Vector3(x1, y, zf + 0.1), 3.3, 0.2, "l200_trim",
		[{"at": 3.6, "w": 6.2, "h": 1.7, "sill": 0.8}, {"at": wd - 2.0, "w": 1.0, "h": 2.15, "sill": 0.0}, {"at": wd - 0.7, "w": 0.8, "h": 1.7, "sill": 0.8}])
	k.box_mm(Vector3(x0 + 0.5, y + 0.8, zf + 0.09), Vector3(x0 + 6.7, y + 2.5, zf + 0.11), "glass")
	k.box_mm(Vector3(x1 - 1.1, y + 0.8, zf + 0.09), Vector3(x1 - 0.3, y + 2.5, zf + 0.11), "glass")
	k.box_mm(Vector3(x0, y, zf + 0.2), Vector3(x0 + 0.2, y + 3.3, zb), "l200_diner_wall")
	k.box_mm(Vector3(x1 - 0.2, y, zf + 0.2), Vector3(x1, y + 3.3, zb), "l200_diner_wall")
	k.box_mm(Vector3(x0, y, zb - 0.2), Vector3(x1, y + 3.3, zb), "l200_diner_wall")
	k.box_mm(Vector3(x0 + 0.2, y, zf + 0.2), Vector3(x0 + 0.23, y + 1.0, zb - 0.2), "l200_wood_dark", GeoKit.ALL, false)
	k.box_mm(Vector3(x1 - 0.23, y, zf + 0.2), Vector3(x1 - 0.2, y + 1.0, zb - 0.2), "l200_wood_dark", GeoKit.ALL, false)
	k.box_mm(Vector3(x0, y + 3.2, zf), Vector3(x1, y + 3.3, zb), "l200_ceiling", GeoKit.NY)
	k.box_mm(Vector3(x0 - 0.1, y + 3.3, zf - 0.1), Vector3(x1 + 0.1, y + 3.6, zb), "l200_concrete", GeoKit.ALL, false)
	k.box_mm(Vector3(x0 + 1.0, y + 3.6, zf - 0.05), Vector3(x1 - 1.0, y + 4.6, zf + 0.1), "l200_awning", GeoKit.ALL, false)
	k.box_mm(Vector3(x0 + 1.15, y + 3.7, zf - 0.07), Vector3(x1 - 1.15, y + 4.5, zf - 0.05), "l200_trim", GeoKit.ALL, false)
	k.box_mm(Vector3(x0, 0, zf - 0.1), Vector3(x1, 0.8, zf), "l200_vinyl_red", GeoKit.ALL, false)
	# a single step up at the door
	k.box_mm(Vector3(x1 - 2.6, 0.0, zf - 0.32), Vector3(x1 - 1.4, 0.19, zf), "l200_concrete")
	# counter, stools, back bar, pass-through
	k.box_mm(Vector3(x0 + 1.4, y, 27.6), Vector3(x1 - 3.4, y + 1.0, 28.1), "l200_vinyl_red")
	k.box_mm(Vector3(x0 + 1.35, y + 1.0, 27.45), Vector3(x1 - 3.35, y + 1.05, 28.2), "l200_formica")
	for i in 8:
		var sx := x0 + 1.9 + i * 0.8
		k.cylinder(Vector3(sx, y + 0.35, 27.0), 0.04, 0.7, "l200_metal", 8)
		k.cylinder(Vector3(sx, y + 0.74, 27.0), 0.19, 0.08, "l200_vinyl_red", 14, false)
	k.box_mm(Vector3(x0 + 0.2, y, zb - 0.8), Vector3(x1 - 2.0, y + 0.95, zb - 0.2), "l200_trim")
	k.box_mm(Vector3(x0 + 0.2, y + 0.95, zb - 0.8), Vector3(x1 - 2.0, y + 1.0, zb - 0.2), "l200_formica")
	for yy in [1.6, 2.1]:
		k.box_mm(Vector3(x0 + 0.3, y + yy, zb - 0.45), Vector3(x0 + 4.2, y + yy + 0.03, zb - 0.2), "l200_trim", GeoKit.ALL, false)
	k.box_mm(Vector3(x0 + 5.0, y + 1.3, zb - 0.22), Vector3(x0 + 7.2, y + 2.2, zb - 0.19), "l200_dark", GeoKit.ALL, false)
	k.box_mm(Vector3(x0 + 0.6, y + 1.0, zb - 0.7), Vector3(x0 + 1.1, y + 1.45, zb - 0.3), "l200_metal", GeoKit.ALL, false)
	k.box_mm(Vector3(x0 + 0.25, y + 2.4, 24.5), Vector3(x0 + 0.27, y + 2.9, 27.0), "l200_dark", GeoKit.ALL, false)
	# booths along the front window
	for tx in [x0 + 1.3, x0 + 3.6, x0 + 5.9]:
		k.box_mm(Vector3(tx - 0.35, y + 0.72, zf + 0.35), Vector3(tx + 0.35, y + 0.76, zf + 1.6), "l200_formica")
		k.cylinder(Vector3(tx, y + 0.36, zf + 1.2), 0.05, 0.72, "l200_metal", 8, false)
		for s in [-1.0, 1.0]:
			var bx: float = tx + s * 0.75
			k.box_mm(Vector3(bx - 0.22, y, zf + 0.3), Vector3(bx + 0.22, y + 0.45, zf + 1.7), "l200_vinyl_red")
			k.box_mm(Vector3(bx + s * 0.12 - 0.1, y + 0.45, zf + 0.3), Vector3(bx + s * 0.12 + 0.1, y + 1.15, zf + 1.7), "l200_vinyl_red", GeoKit.ALL, false)
	for lx in [x0 + 2.5, x0 + 6.5, x1 - 2.2]:
		k.panel(Vector3(lx, y + 3.19, 26.0), 1.2, 0.3, "l200_tube")


## The school: brick front, schoolyard, and the basement areaway with its door.
static func school(k: GeoKit) -> void:
	var x0 := 20.0
	var x1 := 43.0
	var zf := 28.0
	k.box_mm(Vector3(x0, 0, zf + 0.3), Vector3(x1, 8.6, 42.0), "l200_brick")
	k.wall(Vector3(x0, 0, zf + 0.15), Vector3(x1, 0, zf + 0.15), 8.6, 0.3, "l200_brick", [{"at": 13.5, "w": 2.2, "h": 2.7, "sill": 0.0}])
	k.box_mm(Vector3(32.4, 0, zf + 0.25), Vector3(34.6, 2.7, zf + 0.3), "l200_wood_dark", GeoKit.ALL, false)
	k.box_mm(Vector3(32.1, 2.9, zf - 0.6), Vector3(34.9, 3.05, zf + 0.1), "l200_concrete", GeoKit.ALL, false)
	k.box_mm(Vector3(31.8, 3.4, zf - 0.04), Vector3(35.2, 4.2, zf), "l200_concrete", GeoKit.ALL, false)
	for row in [1.2, 4.6]:
		for i in 9:
			var x := x0 + 1.3 + i * 2.5
			if row < 2.0 and absf(x - 33.5) < 2.2:
				continue
			_win(k, Vector3(x, row, zf), Vector3(0, 0, -1), 1.5, 1.9, row > 2.0 and i == 6)
	k.box_mm(Vector3(x0 - 0.1, 8.6, zf - 0.15), Vector3(x1 + 0.1, 9.0, 42.0), "l200_concrete", GeoKit.ALL, false)
	k.box_mm(Vector3(x0, 3.4, zf - 0.08), Vector3(x1, 3.6, zf), "l200_concrete", GeoKit.ALL, false)
	k.cylinder(Vector3(38.0, 4.5, 24.0), 0.06, 9.0, "l200_metal", 8)
	# fences: chain link along the sidewalk with a gate gap; side closures
	_chain(k, Vector3(19.0, 0, 22.7), Vector3(23.5, 0, 22.7))
	_chain(k, Vector3(27.0, 0, 22.7), Vector3(45.0, 0, 22.7))
	_chain(k, Vector3(19.0, 0, 22.7), Vector3(19.0, 0, zf))
	_chain(k, Vector3(45.0, 0, 22.7), Vector3(45.0, 0, zf))
	k.box_mm(Vector3(19.0, 0, zf - 0.1), Vector3(20.0, 2.0, zf + 0.3), "l200_brick")
	k.box_mm(Vector3(43.0, 0, zf - 0.1), Vector3(45.0, 2.0, zf + 0.3), "l200_brick")
	# areaway: retaining walls (a 0.95 m parapet above the yard), stair, landing
	var p := PIT
	k.box_mm(Vector3(p[0], -2.4, p[1]), Vector3(p[2], 0.95, p[1] + 0.15), "l200_concrete")
	k.box_mm(Vector3(p[0], -2.4, p[1]), Vector3(p[0] + 0.15, 0.95, p[3]), "l200_concrete")
	k.box_mm(Vector3(p[2] - 0.15, -2.4, p[1]), Vector3(p[2], 0.95, 26.7), "l200_concrete")
	k.box_mm(Vector3(p[2] - 0.15, -2.4, 27.7), Vector3(p[2], 0.95, p[3]), "l200_concrete")
	k.box_mm(Vector3(p[0], -2.7, p[1]), Vector3(p[2], -2.4, p[3]), "l200_basement", GeoKit.PY)
	k.stairs(Vector3(22.0, -2.4, 27.2), Vector3(1, 0, 0), 1.0, 2.4, 13, "l200_concrete", 0.27)
	k.box_mm(Vector3(22.0, -2.4, 26.4), Vector3(25.55, -2.3, 26.7), "l200_concrete", GeoKit.ALL, false)
	k.box_mm(Vector3(p[2] - 0.2, 0.95, p[1]), Vector3(p[2], 1.0, p[3]), "l200_metal", GeoKit.ALL, false)
	k.box_mm(Vector3(20.6, -2.4, zf - 0.05), Vector3(21.8, -0.3, zf + 0.3), "l200_dark", GeoKit.ALL, false)


static func basement(k: GeoKit) -> void:
	var x0 := 19.4
	var x1 := 27.0
	var z0 := 28.0
	var z1 := 34.2
	var y := -2.4
	k.box_mm(Vector3(x0, y - 0.3, z0), Vector3(x1, y, z1), "l200_basement", GeoKit.PY)
	k.wall(Vector3(x0, y, z0 + 0.15), Vector3(x1, y, z0 + 0.15), 2.4, 0.3, "l200_basement", [{"at": 21.2 - x0, "w": 0.95, "h": 2.0, "sill": 0.0}])
	k.box_mm(Vector3(x0, y, z0), Vector3(x0 + 0.2, 0.0, z1), "l200_basement")
	k.box_mm(Vector3(x1 - 0.2, y, z0), Vector3(x1, 0.0, z1), "l200_basement")
	k.box_mm(Vector3(x0, y, z1 - 0.2), Vector3(x1, 0.0, z1), "l200_basement")
	k.box_mm(Vector3(x0, -0.32, z0), Vector3(x1, -0.3, z1), "l200_basement", GeoKit.NY, false)
	# boiler, pipes, stacked desks, shelving, a puddle
	k.cylinder(Vector3(25.6, y + 0.85, 32.8), 0.7, 1.7, "l200_pipe", 16)
	k.cylinder(Vector3(25.6, y + 1.95, 32.8), 0.12, 0.6, "l200_pipe", 8, false)
	for z in [29.0, 30.2]:
		k.box_mm(Vector3(x0 + 0.2, -0.56, z - 0.07), Vector3(x1 - 0.2, -0.44, z + 0.07), "l200_pipe", GeoKit.ALL, false)
	k.box_mm(Vector3(25.5, -0.56, 30.2), Vector3(25.7, y + 2.0, 30.4), "l200_pipe", GeoKit.ALL, false)
	for i in 3:
		var dz := 31.6 + i * 0.05
		k.box_mm(Vector3(20.0, y + i * 0.75, dz), Vector3(21.2, y + i * 0.75 + 0.7, dz + 0.6), "l200_wood_dark", GeoKit.ALL, i == 0)
	k.box_mm(Vector3(22.6, y, 33.6), Vector3(24.6, y + 1.9, 34.0), "l200_pipe")
	for yy in [0.5, 1.0, 1.5]:
		k.box_mm(Vector3(22.7, y + yy, 33.62), Vector3(24.5, y + yy + 0.25, 33.95), "l200_dark", GeoKit.ALL, false)
	k.box_mm(Vector3(19.62, y + 0.9, 29.2), Vector3(19.64, y + 2.0, 31.0), "l200_chalk", GeoKit.ALL, false)
	k.cylinder(Vector3(23.0, -0.45, 31.0), 0.004, 0.3, "l200_dark", 4, false)
	k.cylinder(Vector3(23.0, -0.62, 31.0), 0.035, 0.07, "l200_bulb", 8, false)


static func _chain(k: GeoKit, a: Vector3, b: Vector3) -> void:
	k.wall(a, b, 2.0, 0.03, "l200_chainlink")
	var d := b - a
	var n := maxi(1, int(d.length() / 3.0))
	for i in n + 1:
		k.cylinder(a + d * (float(i) / n) + Vector3(0, 1.0, 0), 0.035, 2.0, "l200_metal", 6, false)
	k.box(a.lerp(b, 0.5) + Vector3(0, 2.0, 0), Vector3(absf(d.x) + 0.05, 0.05, absf(d.z) + 0.05), "l200_metal", GeoKit.ALL, false)


static func fences(k: GeoKit) -> void:
	# side fences between lots, the long back fence, hedges closing the block
	for x in [-56.0, -40.0, -24.0, -8.0, 8.0, 24.0, 40.0, 56.0]:
		var zend := 2.5 if absf(x) < 50.0 else SW_N
		var mat := "l200_fence_wood" if absf(x) < 50.0 else "l200_hedge"
		k.box_mm(Vector3(x - 0.04, 0, -14.0), Vector3(x + 0.04, 1.9 if absf(x) < 50.0 else 2.4, zend), mat)
	k.box_mm(Vector3(-56.0, 0, -14.08), Vector3(56.0, 1.9, -14.0), "l200_fence_wood")
	for x in range(-56, 56, 2):
		k.box(Vector3(x + 1.0, 1.0, -13.97), Vector3(0.09, 1.95, 0.05), "l200_fence_wood", GeoKit.ALL, false)
	# Home's white picket fence along the sidewalk, gap at the walk
	for seg in [[-7.9, -0.9], [0.9, 7.9]]:
		var x0: float = seg[0]
		var x1: float = seg[1]
		k.box(Vector3((x0 + x1) * 0.5, 0.65, 12.2), Vector3(x1 - x0, 0.06, 0.04), "l200_trim")
		var n := int((x1 - x0) / 0.14)
		for j in n + 1:
			k.box(Vector3(x0 + (x1 - x0) * j / n, 0.42, 12.2), Vector3(0.07, 0.84, 0.025), "l200_trim", GeoKit.ALL, false)
	# far rear houses and rooftops (beyond the back fence, never reachable)
	for i in 8:
		var cx := -56.0 + i * 16.0
		k.box_mm(Vector3(cx - 4.5, 0, -30.0), Vector3(cx + 4.5, 5.6, -22.0), "l200_sid%d" % ((i + 2) % 5))
		k.box_mm(Vector3(cx + 3.0, 0, -52.0), Vector3(cx + 12.0, 7.5, -42.0), "l200_sid%d" % ((i + 4) % 5))
		_plane(k, Vector3(cx + 7.5, 7.3, -41.6), Vector3(cx + 7.5, 9.8, -47.0), 9.6, "l200_roof_b", false)
		_plane(k, Vector3(cx, 5.4, -21.6), Vector3(cx, 7.8, -26.0), 9.6, "l200_roof", false)
		_plane(k, Vector3(cx, 5.4, -30.4), Vector3(cx, 7.8, -26.0), 9.6, "l200_roof", false)
		_win(k, Vector3(cx - 2.0, 3.2, -22.0), Vector3(0, 0, 1), 1.0, 1.3, i == 3)
		_win(k, Vector3(cx + 2.0, 3.2, -22.0), Vector3(0, 0, 1), 1.0, 1.3)


static func tree(k: GeoKit, p: Vector3, sc: float, seed_v: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	k.cylinder(p + Vector3(0, 1.6 * sc, 0), 0.16 * sc, 3.2 * sc, "l200_wood_dark", 8)
	for i in 6:
		var a := TAU * i / 6.0 + r.randf() * 0.6
		var base := p + Vector3(0, (2.4 + r.randf() * 0.8) * sc, 0)
		var tip := base + Vector3(cos(a) * 1.8 * sc, (1.6 + r.randf()) * sc, sin(a) * 1.8 * sc)
		_stick(k, base, tip, 0.09 * sc, "l200_wood_dark")
		_stick(k, tip, tip + Vector3(cos(a + 0.6) * 0.9 * sc, 0.8 * sc, sin(a + 0.6) * 0.9 * sc), 0.045 * sc, "l200_wood_dark")


static func _stick(k: GeoKit, a: Vector3, b: Vector3, th: float, mat: String) -> void:
	var d := b - a
	var z := d.normalized()
	var x := Vector3.UP.cross(z)
	if x.length() < 0.01:
		x = Vector3.RIGHT
	x = x.normalized()
	var y := z.cross(x).normalized()
	k.box_xf(Transform3D(Basis(x, y, z), (a + b) * 0.5), Vector3(th, th, d.length()), mat, GeoKit.ALL, false)


static func street_props(k: GeoKit) -> void:
	for p in [[Vector3(5.6, 0, 9.6), 1.0], [Vector3(-11.5, 0, 9.0), 1.15], [Vector3(20.5, 0, 9.8), 0.9], [Vector3(-27.0, 0, 9.4), 1.1],
			[Vector3(36.5, 0, 10.0), 1.0], [Vector3(-43.0, 0, 9.0), 0.95], [Vector3(-3.5, 0, -9.5), 1.2], [Vector3(4.0, 0, -11.0), 0.9]]:
		tree(k, p[0], p[1], int(p[0].x * 13.0))
	var tops: Array = []
	for i in 6:
		var x := -50.0 + i * 20.0
		k.cylinder(Vector3(x, 4.5, 12.75), 0.14, 9.0, "l200_wood_dark", 8)
		k.box(Vector3(x, 8.4, 12.75), Vector3(0.12, 0.12, 1.8), "l200_wood_dark", GeoKit.ALL, false)
		tops.append(Vector3(x, 8.45, 12.75))
	for i in tops.size() - 1:
		for dz in [-0.8, 0.0, 0.8]:
			var a: Vector3 = tops[i] + Vector3(0, 0, dz)
			var b: Vector3 = tops[i + 1] + Vector3(0, 0, dz)
			_stick(k, a, a.lerp(b, 0.5) + Vector3(0, -0.5, 0), 0.02, "l200_dark")
			_stick(k, a.lerp(b, 0.5) + Vector3(0, -0.5, 0), b, 0.02, "l200_dark")
	k.box(Vector3(1.4, 0.55, 12.0), Vector3(0.08, 1.1, 0.08), "l200_wood_dark")
	k.box(Vector3(1.4, 1.15, 12.0), Vector3(0.22, 0.22, 0.46), "l200_dark", GeoKit.ALL, false)
	k.cylinder(Vector3(9.0, 0.4, 13.0), 0.12, 0.6, "l200_vinyl_red", 10)


## The townspeople closing both ends of the street (static, solid as a crowd).
static func crowd(k: GeoKit) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 200
	var coats := ["l200_coat0", "l200_coat1", "l200_coat2", "l200_coat3"]
	for s in [-1.0, 1.0]:
		for row in 3:
			var z := SW_N + 0.15 + row * 0.35
			while z < SW_S - 0.1:
				var p := Vector3(s * (END_X + row * 0.65 + r.randf() * 0.2), 0.0 if z > ROAD0 and z < ROAD1 else 0.1, z)
				FX.kfig(k, p, s * PI * 0.5 + r.randf_range(-0.15, 0.15), r.randf_range(1.55, 1.88), coats[r.randi() % 4], "l200_pants%d" % (r.randi() % 2), true)
				z += 0.7
