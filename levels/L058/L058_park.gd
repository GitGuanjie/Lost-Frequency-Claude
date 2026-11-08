extends RefCounted
## Level 58 main Waterpark: the hall, two dry pools (blue tile rims, beige
## concrete, dry red leaves), the slide tower on white-chipped rusting beams
## with faded slides and the black one, the blue plastic landscape with
## uniquely painted trees and Tegan Trees, the spectator area behind filthy
## cracked glass, and the high windows onto a bright white void.

const HX := 30.0
const HZ := 22.0
const HH := 14.0
const LP := Rect2(-20.0, -2.0, 22.0, 14.0)    # leisure pool (x, z, w, d)
const SP := Rect2(8.0, 2.0, 10.0, 10.0)       # splash pool
const LD := 0.5
const SD := 0.45
const P1 := 4.2
const P2 := 8.0

var lvl
var r := RandomNumberGenerator.new()
var slides: Array = []        # {pts, color}
var black_mouth := Vector3.ZERO
var black_dir := Vector3.ZERO
var windows: Array = []       # centre points of the high windows (inside face)
var tegan: Array = []         # tree tops with fruit
var tree_parts: Array = []


func _init(level) -> void:
	lvl = level
	r.seed = 58058


static func materials() -> void:
	MatLib.define("l58_deck", {"albedo_a": Color(0.62, 0.6, 0.55), "albedo_b": Color(0.55, 0.53, 0.48), "noise_scale": 0.3,
		"roughness_a": 0.6, "stain_amount": 0.45, "stain_color": Color(0.35, 0.32, 0.26), "stain_scale": 0.2}, "concrete")
	MatLib.define("l58_pool", {"albedo_a": Color(0.72, 0.64, 0.5), "albedo_b": Color(0.62, 0.55, 0.42), "stain_amount": 0.6,
		"stain_color": Color(0.3, 0.27, 0.2), "grime_height": 0.3, "grime_color": Color(0.25, 0.22, 0.16), "floor_y": -0.5}, "concrete")
	MatLib.define("l58_bluetile", {"albedo_a": Color(0.1, 0.32, 0.62), "albedo_b": Color(0.12, 0.36, 0.66), "pattern": 1,
		"pattern_scale": Vector2(0.15, 0.15), "grout_width": 0.008, "grout_color": Color(0.6, 0.62, 0.6), "roughness_a": 0.25,
		"stain_amount": 0.3, "stain_color": Color(0.2, 0.22, 0.2)}, "pool_tile")
	MatLib.define("l58_coping", {"albedo_a": Color(0.82, 0.8, 0.74), "albedo_b": Color(0.76, 0.74, 0.68)}, "trim_white")
	MatLib.define("l58_wall", {"albedo_a": Color(0.74, 0.74, 0.7), "albedo_b": Color(0.68, 0.68, 0.64), "stain_amount": 0.4,
		"stain_color": Color(0.5, 0.46, 0.38), "grime_height": 1.5, "grime_color": Color(0.45, 0.42, 0.36)}, "plaster")
	MatLib.define("l58_dado", {"albedo_a": Color(0.55, 0.72, 0.78), "albedo_b": Color(0.5, 0.68, 0.74), "pattern": 1,
		"pattern_scale": Vector2(0.3, 0.3), "grout_width": 0.012, "grout_color": Color(0.7, 0.72, 0.7), "roughness_a": 0.3,
		"stain_amount": 0.4, "stain_color": Color(0.35, 0.35, 0.3)}, "pool_tile")
	MatLib.define("l58_beam", {"albedo_a": Color(0.86, 0.85, 0.82), "albedo_b": Color(0.8, 0.79, 0.76), "peel_amount": 0.55,
		"peel_color": Color(0.42, 0.2, 0.09), "stain_amount": 0.5, "stain_color": Color(0.5, 0.28, 0.12), "noise_scale": 2.5}, "plaster")
	MatLib.define("l58_grate", {"albedo_a": Color(0.5, 0.5, 0.5), "albedo_b": Color(0.42, 0.4, 0.38), "pattern": 1,
		"pattern_scale": Vector2(0.12, 0.12), "grout_width": 0.02, "grout_color": Color(0.2, 0.18, 0.16), "metallic_value": 0.6,
		"stain_amount": 0.5, "stain_color": Color(0.45, 0.22, 0.1)}, "metal")
	MatLib.define("l58_bluegrass", {"albedo_a": Color(0.12, 0.3, 0.72), "albedo_b": Color(0.16, 0.38, 0.8), "pattern": 12,
		"pattern_color": Color(0.1, 0.24, 0.6), "pattern_strength": 0.5, "roughness_a": 0.35, "roughness_b": 0.5, "noise_scale": 0.6}, "grass")
	MatLib.define("l58_bluesheet", {"albedo_a": Color(0.14, 0.34, 0.74), "albedo_b": Color(0.15, 0.36, 0.76), "roughness_a": 0.3,
		"stain_amount": 0.35, "stain_color": Color(0.1, 0.2, 0.4)}, "plaster")
	MatLib.define("l58_roof", {"albedo_a": Color(0.42, 0.42, 0.42), "albedo_b": Color(0.36, 0.36, 0.36), "metallic_value": 0.4}, "metal")
	MatLib.define("l58_leaf", {"albedo_a": Color(0.45, 0.12, 0.05), "albedo_b": Color(0.6, 0.2, 0.06), "noise_scale": 8.0}, "plaster")
	var trunks := [[2, Color(0.24, 0.14, 0.08), Color(0.16, 0.09, 0.05)], [5, Color(0.3, 0.18, 0.1), Color(0.18, 0.1, 0.06)],
		[8, Color(0.2, 0.12, 0.07), Color(0.32, 0.2, 0.1)], [9, Color(0.27, 0.15, 0.08), Color(0.14, 0.08, 0.04)], [10, Color(0.22, 0.13, 0.08), Color(0.35, 0.22, 0.12)]]
	for i in trunks.size():
		var t: Array = trunks[i]
		MatLib.define("l58_trunk%d" % i, {"albedo_a": t[1], "albedo_b": t[1], "pattern": t[0], "pattern_scale": Vector2(0.18, 0.18),
			"pattern_color": t[2], "pattern_strength": 0.8, "roughness_a": 0.4}, "plaster")
	MatLib.register("l58_void", MatLib.panel(Color(1.0, 1.0, 0.98), 3.2))
	MatLib.register("l58_leaves", MatLib.standard(Color(0.12, 0.33, 0.85), 0.35, 0.0, Color(0.05, 0.12, 0.35), 0.15))
	MatLib.register("l58_fruit", MatLib.standard(Color(0.38, 0.1, 0.48), 0.2))
	MatLib.register("l58_fruit_pink", MatLib.standard(Color(0.9, 0.42, 0.6), 0.25))
	var g := StandardMaterial3D.new()
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.albedo_color = Color(0.62, 0.64, 0.56, 0.38)
	g.roughness = 0.45
	MatLib.register("l58_dirtyglass", g)
	for e in [["l58_slide_yel", Color(0.86, 0.78, 0.48)], ["l58_slide_blu", Color(0.5, 0.66, 0.78)], ["l58_slide_red", Color(0.82, 0.5, 0.44)], ["l58_slide_blk", Color(0.03, 0.03, 0.035)]]:
		var m := StandardMaterial3D.new()
		m.albedo_color = e[1]
		m.roughness = 0.55 if e[0] != "l58_slide_blk" else 0.25
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		MatLib.register(e[0], m)


# ------------------------------------------------------------------ hall

func hall(k: GeoKit, lit: GeoKit) -> void:
	# deck around the pools
	k.slab(-HX, -HZ, HX, LP.position.y, 0.0, 0.5, "l58_deck")
	k.slab(-HX, LP.end.y, HX, HZ, 0.0, 0.5, "l58_deck")
	k.slab(-HX, LP.position.y, LP.position.x, LP.end.y, 0.0, 0.5, "l58_deck")
	k.slab(LP.end.x, LP.position.y, HX, SP.position.y, 0.0, 0.5, "l58_deck")
	k.slab(LP.end.x, SP.position.y, SP.position.x, LP.end.y, 0.0, 0.5, "l58_deck")
	k.slab(SP.end.x, SP.position.y, HX, LP.end.y, 0.0, 0.5, "l58_deck")
	_pool(k, LP, LD)
	_pool(k, SP, SD)
	k.stairs(Vector3(-18.5, -LD, LP.end.y - 1.05), Vector3(0, 0, 1), 2.4, LD, 3, "l58_coping", 0.35)
	k.stairs(Vector3(9.6, -SD, SP.end.y - 1.05), Vector3(0, 0, 1), 2.0, SD, 3, "l58_coping", 0.35)
	# walls: tiled dado, plain above, high windows on the north and west walls
	var wops: Array = []
	for i in 6:
		wops.append({"at": 5.0 + i * 10.0, "w": 4.2, "h": 4.0, "sill": 7.0})
	k.wall(Vector3(-HX, 0, -HZ - 0.2), Vector3(HX, 0, -HZ - 0.2), HH, 0.4, "l58_wall", wops)
	for i in 6:
		var c := Vector3(-HX + 5.0 + i * 10.0, 9.0, -HZ - 0.2)
		windows.append(c + Vector3(0, 0, 0.3))
		lit.box(c + Vector3(0, 0, -1.4), Vector3(5.0, 5.0, 0.1), "l58_void", GeoKit.ALL, false)
		k.box(c + Vector3(0, -2.05, 0.35), Vector3(4.4, 0.12, 0.35), "l58_coping", GeoKit.ALL, false)
	var wops2: Array = []
	for i in 4:
		wops2.append({"at": 6.0 + i * 10.5, "w": 4.0, "h": 4.0, "sill": 7.0})
	k.wall(Vector3(-HX - 0.2, 0, -HZ), Vector3(-HX - 0.2, 0, HZ), HH, 0.4, "l58_wall", wops2)
	for i in 4:
		var c := Vector3(-HX - 0.2, 9.0, -HZ + 6.0 + i * 10.5)
		windows.append(c + Vector3(0.3, 0, 0))
		lit.box(c + Vector3(-1.4, 0, 0), Vector3(0.1, 5.0, 5.0), "l58_void", GeoKit.ALL, false)
	k.wall(Vector3(-HX, 0, HZ + 0.2), Vector3(HX, 0, HZ + 0.2), HH, 0.4, "l58_wall")
	k.wall(Vector3(HX + 0.2, 0, -HZ), Vector3(HX + 0.2, 0, HZ), HH, 0.4, "l58_wall", [{"at": HZ, "w": 1.8, "h": 2.4}])
	for seg in [[Vector3(-HX, 0, -HZ + 0.02), Vector3(HX, 0, -HZ + 0.02)], [Vector3(-HX, 0, HZ - 0.02), Vector3(HX, 0, HZ - 0.02)], [Vector3(-HX + 0.02, 0, -HZ), Vector3(-HX + 0.02, 0, HZ)]]:
		k.wall(seg[0], seg[1], 1.4, 0.04, "l58_dado", [], GeoKit.ALL)
	k.wall(Vector3(HX - 0.02, 0, -HZ), Vector3(HX - 0.02, 0, HZ), 1.4, 0.04, "l58_dado", [{"at": HZ, "w": 1.8, "h": 2.4}])
	# roof and steel trusses
	k.slab(-HX - 0.4, -HZ - 0.4, HX + 0.4, HZ + 0.4, HH + 0.4, 0.4, "l58_roof")
	var x := -HX + 5.0
	while x < HX:
		k.box(Vector3(x, HH - 0.5, 0), Vector3(0.3, 1.0, HZ * 2.0), "l58_roof", GeoKit.ALL, false)
		k.box(Vector3(x, HH - 1.2, 0), Vector3(0.12, 0.12, HZ * 2.0), "l58_roof", GeoKit.ALL, false)
		x += 7.5
	# the doorway to the Corridors: a heavy metal door left ajar
	k.box(Vector3(HX - 0.5, 1.2, 0.97), Vector3(1.0, 2.35, 0.08), "l58_roof")


func _pool(k: GeoKit, rc: Rect2, d: float) -> void:
	k.slab(rc.position.x, rc.position.y, rc.end.x, rc.end.y, -d, 0.4, "l58_pool")
	var w := 0.25
	var sides := [[Vector3(rc.position.x, 0, rc.position.y + w * 0.5), Vector3(rc.end.x, 0, rc.position.y + w * 0.5)],
		[Vector3(rc.position.x, 0, rc.end.y - w * 0.5), Vector3(rc.end.x, 0, rc.end.y - w * 0.5)],
		[Vector3(rc.position.x + w * 0.5, 0, rc.position.y), Vector3(rc.position.x + w * 0.5, 0, rc.end.y)],
		[Vector3(rc.end.x - w * 0.5, 0, rc.position.y), Vector3(rc.end.x - w * 0.5, 0, rc.end.y)]]
	for s in sides:
		var a: Vector3 = s[0]
		var b: Vector3 = s[1]
		k.wall(a - Vector3(0, d, 0), b - Vector3(0, d, 0), d - 0.2, w, "l58_pool")
		k.wall(a - Vector3(0, 0.2, 0), b - Vector3(0, 0.2, 0), 0.2, w, "l58_bluetile")
	# coping strip around the rim
	k.box_mm(Vector3(rc.position.x - 0.35, 0.0, rc.position.y - 0.35), Vector3(rc.end.x + 0.35, 0.03, rc.position.y), "l58_coping", GeoKit.PY | GeoKit.SIDES, false)
	k.box_mm(Vector3(rc.position.x - 0.35, 0.0, rc.end.y), Vector3(rc.end.x + 0.35, 0.03, rc.end.y + 0.35), "l58_coping", GeoKit.PY | GeoKit.SIDES, false)
	k.box_mm(Vector3(rc.position.x - 0.35, 0.0, rc.position.y), Vector3(rc.position.x, 0.03, rc.end.y), "l58_coping", GeoKit.PY | GeoKit.SIDES, false)
	k.box_mm(Vector3(rc.end.x, 0.0, rc.position.y), Vector3(rc.end.x + 0.35, 0.03, rc.end.y), "l58_coping", GeoKit.PY | GeoKit.SIDES, false)


## Dry red leaves drifted in the pools (no exterior, origin unknown).
func leaves(k: GeoKit) -> void:
	for rc in [[LP, LD], [SP, SD]]:
		var rect: Rect2 = rc[0]
		var y: float = -float(rc[1]) + 0.012
		for i in (160 if rect == LP else 70):
			var p := Vector3(r.randf_range(rect.position.x + 0.4, rect.end.x - 0.4), y, r.randf_range(rect.position.y + 0.4, rect.end.y - 0.4))
			if r.randf() < 0.5:
				p.x = lerpf(p.x, rect.position.x + 0.5 if r.randf() < 0.5 else rect.end.x - 0.5, 0.7)
			k.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * TAU), p), Vector3(r.randf_range(0.08, 0.16), 0.006, r.randf_range(0.05, 0.1)), "l58_leaf", GeoKit.PY, false)


# --------------------------------------------------------- slide tower

func tower(k: GeoKit) -> void:
	k.slab(4.0, -19.0, 16.0, -9.0, P1, 0.25, "l58_grate")
	k.slab(10.8, -19.0, 16.0, -9.0, P2, 0.25, "l58_grate")
	k.stairs(Vector3(5.0, 0.0, -3.24), Vector3(0, 0, -1), 1.6, P1, 24, "l58_grate", 0.24)
	k.stairs(Vector3(5.5, P1, -11.5), Vector3(1, 0, 0), 1.4, P2 - P1, 22, "l58_grate", 0.24)
	for p in [Vector3(4.0, 0, -19.0), Vector3(4.0, 0, -9.0), Vector3(10.8, 0, -19.0), Vector3(10.8, 0, -9.0), Vector3(16.0, 0, -19.0), Vector3(16.0, 0, -9.0)]:
		var top := P2 if p.x > 10.0 else P1
		k.cylinder(p + Vector3(0, top * 0.5, 0), 0.2, top, "l58_beam", 10)
	for z in [-19.0, -9.0]:
		k.box_xf(Transform3D(Basis(Vector3.FORWARD, atan2(P1, 6.8)), Vector3(7.4, P1 * 0.5, z)), Vector3(0.1, 8.0, 0.1), "l58_beam", GeoKit.ALL, false)
		k.box_xf(Transform3D(Basis(Vector3.FORWARD, -atan2(P2 - P1, 5.2)), Vector3(13.4, (P1 + P2) * 0.5, z)), Vector3(0.1, 6.4, 0.1), "l58_beam", GeoKit.ALL, false)
	# railings (gaps at stairs and slide starts)
	_rail(k, Vector3(4.0, P1, -19.0), Vector3(4.0, P1, -9.0), [-14.0])
	_rail(k, Vector3(4.0, P1, -19.0), Vector3(10.8, P1, -19.0), [])
	_rail(k, Vector3(5.9, P1, -9.0), Vector3(10.8, P1, -9.0), [])
	_rail(k, Vector3(10.8, P2, -19.0), Vector3(16.0, P2, -19.0), [12.5])
	_rail(k, Vector3(16.0, P2, -19.0), Vector3(16.0, P2, -9.0), [-12.0])
	_rail(k, Vector3(10.8, P2, -9.0), Vector3(16.0, P2, -9.0), [14.0])
	_rail(k, Vector3(10.8, P2, -19.0), Vector3(10.8, P2, -9.0), [-11.5])
	_rail(k, Vector3(10.8, P1, -9.0), Vector3(16.0, P1, -9.0), [])
	_rail(k, Vector3(16.0, P1, -19.0), Vector3(16.0, P1, -9.0), [])
	# slides: faded yellow, faded blue, faded red, and the black one
	_slide(k, [Vector3(3.6, P1 + 0.6, -14.0), Vector3(-4.0, P1, -15.0), Vector3(-6.0, 2.0, -2.0), Vector3(-3.0, -LD + 0.55, 4.0)], "l58_slide_yel")
	_slide(k, [Vector3(12.5, P2 + 0.6, -19.4), Vector3(4.0, P2, -26.0), Vector3(-22.0, 6.0, -10.0), Vector3(-14.0, -LD + 0.55, 6.0)], "l58_slide_blu")
	_slide(k, [Vector3(16.4, P2 + 0.6, -12.0), Vector3(24.0, P2 - 1.0, -10.0), Vector3(24.0, 2.0, 4.0), Vector3(16.0, -SD + 0.55, 7.0)], "l58_slide_red")
	var bpts := [Vector3(14.0, P2 + 0.6, -8.6), Vector3(14.0, 6.0, -2.0), Vector3(9.0, 3.0, 1.0), Vector3(11.0, -SD + 0.55, 5.8)]
	_slide(k, bpts, "l58_slide_blk")
	black_mouth = bpts[3]
	var tan: Vector3 = (bpts[3] - bpts[2])
	tan.y = 0.0
	black_dir = tan.normalized()
	# the last metre of the black tube is solid: you push into it to no-clip
	k.box(black_mouth - black_dir * 0.9 + Vector3(0, 0.0, 0), Vector3(1.0, 1.1, 1.0), "l58_pool", 0)


func _rail(k: GeoKit, a: Vector3, b: Vector3, gaps: Array) -> void:
	var d := b - a
	var n := int(d.length() / 1.2)
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		var skip := false
		for g in gaps:
			if absf((p.x if absf(d.x) > absf(d.z) else p.z) - float(g)) < 1.1:
				skip = true
		if not skip:
			k.box(p + Vector3(0, 0.55, 0), Vector3(0.05, 1.1, 0.05), "l58_beam", GeoKit.ALL, false)
	var segs: Array = [[0.0, 1.0]]
	for g in gaps:
		var t := ((float(g) - (a.x if absf(d.x) > absf(d.z) else a.z)) / (d.x if absf(d.x) > absf(d.z) else d.z))
		segs = [[0.0, t - 1.1 / d.length()], [t + 1.1 / d.length(), 1.0]]
	for sg in segs:
		var p0 := a.lerp(b, float(sg[0]))
		var p1 := a.lerp(b, float(sg[1]))
		var c := (p0 + p1) * 0.5 + Vector3(0, 1.1, 0)
		var sz := Vector3(maxf(absf(p1.x - p0.x), 0.06), 0.06, maxf(absf(p1.z - p0.z), 0.06))
		k.box(c, sz, "l58_beam", GeoKit.ALL, false)
		k.box(c - Vector3(0, 0.55, 0), Vector3(sz.x, 1.1, sz.z), "l58_beam", 0)


func _bez(p: Array, t: float) -> Vector3:
	var u := 1.0 - t
	return p[0] * u * u * u + p[1] * 3.0 * u * u * t + p[2] * 3.0 * u * t * t + p[3] * t * t * t


func _slide(k: GeoKit, ctrl: Array, mat: String) -> void:
	var n := 22
	var prev: Vector3 = ctrl[0]
	var m := MatLib.get_mat(mat)
	for i in range(1, n + 1):
		var p := _bez(ctrl, float(i) / n)
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.55
		cm.bottom_radius = 0.55
		cm.height = prev.distance_to(p) + 0.05
		cm.radial_segments = 14
		cm.rings = 1
		cm.cap_top = false
		cm.cap_bottom = false
		mi.mesh = cm
		mi.material_override = m
		lvl.add_child(mi)
		var mid := (prev + p) * 0.5
		var dir := (p - prev).normalized()
		var side := dir.cross(Vector3.UP)
		if side.length() < 0.01:
			side = Vector3.RIGHT
		mi.global_transform = Transform3D(Basis(side.normalized(), dir, side.normalized().cross(dir)), mid)
		if i % 4 == 2 and p.y > 1.0:
			var floor_y := -LD if LP.has_point(Vector2(p.x, p.z)) else (-SD if SP.has_point(Vector2(p.x, p.z)) else 0.0)
			k.cylinder(Vector3(p.x, (p.y - 0.5 + floor_y) * 0.5, p.z), 0.09, p.y - 0.5 - floor_y, "l58_beam", 8, false)
		prev = p
	slides.append({"pts": ctrl, "mat": mat})


# ------------------------------------------------------- the landscape

func landscape(k: GeoKit) -> void:
	for m in [Rect2(-28.5, -20.5, 7.0, 15.0), Rect2(-12.0, -20.5, 12.0, 12.5), Rect2(19.5, -20.5, 9.0, 16.0), Rect2(20.0, 13.5, 8.5, 7.0), Rect2(-17.0, 14.5, 10.0, 6.5)]:
		_mound(k, m)
	# spectator area: blue plastic sheet, picnic benches, filthy cracked glass
	k.box_mm(Vector3(-29.8, 0.0, 14.0), Vector3(-21.0, 0.04, 21.8), "l58_bluesheet", GeoKit.PY | GeoKit.SIDES)
	for seg in [[Vector3(-29.8, 0, 13.6), Vector3(-20.6, 0, 13.6), []], [Vector3(-20.6, 0, 13.6), Vector3(-20.6, 0, 21.8), [{"at": 6.6, "w": 1.8, "h": 2.4}]]]:
		k.wall(seg[0], seg[1], 2.4, 0.06, "l58_dirtyglass", seg[2])
		var a: Vector3 = seg[0]
		var b: Vector3 = seg[1]
		var n := int(a.distance_to(b) / 2.3)
		for i in n + 1:
			k.box(a.lerp(b, float(i) / n) + Vector3(0, 1.2, 0), Vector3(0.08, 2.4, 0.08), "l58_roof", GeoKit.ALL, false)
		k.box((a + b) * 0.5 + Vector3(0, 2.42, 0), Vector3(maxf(absf(b.x - a.x), 0.08), 0.06, maxf(absf(b.z - a.z), 0.08)), "l58_roof", GeoKit.ALL, false)
	# crack lines on the glass
	for i in 14:
		var p := Vector3(r.randf_range(-29.0, -21.5), r.randf_range(0.4, 2.1), 13.56)
		k.box_xf(Transform3D(Basis(Vector3.BACK, r.randf() * PI), p), Vector3(r.randf_range(0.2, 0.7), 0.012, 0.012), "l58_coping", GeoKit.ALL, false)


func _mound(k: GeoKit, rc: Rect2) -> void:
	var layers := r.randi_range(2, 4)
	var inset := 0.0
	for l in layers:
		var y := 0.22 * (l + 1)
		k.box_mm(Vector3(rc.position.x + inset, 0.0, rc.position.y + inset), Vector3(rc.end.x - inset, y, rc.end.y - inset), "l58_bluegrass", GeoKit.PY | GeoKit.SIDES)
		inset += r.randf_range(0.6, 1.2)
		if rc.size.x - inset * 2.0 < 2.0 or rc.size.y - inset * 2.0 < 2.0:
			break
	var top := Vector3(rc.position.x + rc.size.x * 0.5, 0.22 * layers, rc.position.y + rc.size.y * 0.5)
	var nt := 1 + int(rc.get_area() / 45.0)
	for i in nt:
		var p := Vector3(r.randf_range(rc.position.x + 1.2, rc.end.x - 1.2), 0.0, r.randf_range(rc.position.y + 1.2, rc.end.y - 1.2))
		var hy := 0.22
		var ii := 0.0
		for l in layers:
			if p.x > rc.position.x + ii and p.x < rc.end.x - ii and p.z > rc.position.y + ii and p.z < rc.end.y - ii:
				hy = 0.22 * (l + 1)
			ii += 0.9
		_tree(k, Vector3(p.x, hy, p.z), r.randf() < 0.45)
	tree_parts.append(top)


func _tree(k: GeoKit, base: Vector3, is_tegan: bool) -> void:
	var h := r.randf_range(2.6, 4.6)
	var rad := r.randf_range(0.14, 0.26)
	k.cylinder(base + Vector3(0, h * 0.5, 0), rad, h, "l58_trunk%d" % (r.randi() % 5), 10)
	var crown := base + Vector3(0, h, 0)
	for i in r.randi_range(3, 5):
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radial_segments = 12
		sm.rings = 7
		var s := r.randf_range(0.9, 1.6)
		sm.radius = s
		sm.height = s * 1.6
		mi.mesh = sm
		mi.material_override = MatLib.get_mat("l58_leaves")
		mi.position = crown + Vector3(r.randf_range(-0.9, 0.9), r.randf_range(-0.3, 0.6), r.randf_range(-0.9, 0.9))
		lvl.add_child(mi)
	if is_tegan:
		tegan.append(crown)
		for i in 9:
			var f := MeshInstance3D.new()
			var fm := SphereMesh.new()
			fm.radius = 0.075
			fm.height = 0.13
			fm.radial_segments = 8
			fm.rings = 4
			f.mesh = fm
			f.material_override = MatLib.get_mat("l58_fruit" if i % 3 != 0 else "l58_fruit_pink")
			var a := r.randf() * TAU
			f.position = crown + Vector3(cos(a) * r.randf_range(0.9, 1.5), r.randf_range(-1.0, -0.5), sin(a) * r.randf_range(0.9, 1.5))
			lvl.add_child(f)
