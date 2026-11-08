extends RefCounted
## Level 6.1 mall shell: a 1980s food-court atrium with the sourced "circular
## dip in the middle, with benches all around", four spacious halls with glass
## skylights that show only darkness, storefront facades for the snack bars and
## restaurants (open, counter kiosks, closed shutters), pillars, plants, benches.
## North = -Z. Atrium x,z in [-16,16], 7.5 m high; halls 8 m wide, 5 m high:
##   N: z -16..-64 (M.E.G. Level 6 outpost at the end)
##   S: z 16..56 (perimeter sliding glass doors at the end)
##   E: x 16..56 (a room choked with piled vending machines at the end)
##   W: x -16..-56 (a shuttered mall entrance; the bent wall)

const A := 16.0
const AH := 7.5
const HH := 5.0
const HW := 4.0
const T := 0.3
const PIT_R := [6.5, 7.2, 7.9]
const PIT_Y := [-0.9, -0.6, -0.3]
const HALLS := {
	"N": {"a": Vector3(0, 0, -16), "d": Vector3(0, 0, -1), "len": 48.0},
	"S": {"a": Vector3(0, 0, 16), "d": Vector3(0, 0, 1), "len": 40.0},
	"E": {"a": Vector3(16, 0, 0), "d": Vector3(1, 0, 0), "len": 40.0},
	"W": {"a": Vector3(-16, 0, 0), "d": Vector3(-1, 0, 0), "len": 40.0},
}

var L: LevelBase
var props: Node3D
var k: GeoKit
var K   # furniture kit
var slots: Array = []        # [{hall, side, i, type, name, xf (shop frame), center}]
var skylights: Array = []    # light anchor points (the paradoxical daylight)
var vents: Array = []        # [{pos, normal}]
var bent_wall := Vector3.ZERO
var speakers: Array = []


func _init(level: LevelBase, props_root: Node3D, kit: GeoKit, furniture) -> void:
	L = level
	props = props_root
	k = kit
	K = furniture


static func materials() -> void:
	MatLib.define("l61_terrazzo", {"albedo_a": Color(0.64, 0.60, 0.55), "albedo_b": Color(0.57, 0.53, 0.48), "pattern": 15,
		"pattern_scale": Vector2(0.5, 0.5), "pattern_color": Color(0.42, 0.36, 0.40), "pattern_strength": 0.45, "noise_scale": 0.8,
		"roughness_a": 0.18, "roughness_b": 0.3, "bump_strength": 0.15, "stain_amount": 0.1})
	MatLib.define("l61_tile", {"albedo_a": Color(0.80, 0.76, 0.66), "albedo_b": Color(0.62, 0.42, 0.30), "pattern": 9,
		"pattern_scale": Vector2(1.2, 1.2), "grout_width": 0.01, "grout_color": Color(0.45, 0.42, 0.38), "roughness_a": 0.2,
		"roughness_b": 0.35, "tile_variation": 0.04})
	MatLib.define("l61_wall", {"albedo_a": Color(0.78, 0.71, 0.60), "albedo_b": Color(0.74, 0.67, 0.56), "noise_scale": 1.0,
		"grime_height": 0.3, "grime_color": Color(0.6, 0.55, 0.47), "roughness_a": 0.8, "roughness_b": 0.9}, "plaster")
	MatLib.define("l61_trim", {"albedo_a": Color(0.55, 0.20, 0.32), "albedo_b": Color(0.50, 0.18, 0.30), "roughness_a": 0.4,
		"roughness_b": 0.5, "noise_scale": 0.6})
	MatLib.define("l61_trim_teal", {"albedo_a": Color(0.10, 0.45, 0.48), "albedo_b": Color(0.09, 0.40, 0.43), "roughness_a": 0.4,
		"roughness_b": 0.5, "noise_scale": 0.6})
	MatLib.define("l61_ceiling", {"albedo_a": Color(0.88, 0.86, 0.80), "albedo_b": Color(0.83, 0.81, 0.75), "pattern": 7,
		"pattern_scale": Vector2(0.61, 0.61), "grout_width": 0.012, "grout_color": Color(0.7, 0.68, 0.62), "roughness_a": 0.9,
		"roughness_b": 1.0, "noise_scale": 0.7})
	MatLib.define("l61_navy", {"albedo_a": Color(0.05, 0.09, 0.26), "albedo_b": Color(0.04, 0.08, 0.23), "roughness_a": 0.35,
		"roughness_b": 0.45, "noise_scale": 2.0})
	MatLib.define("l61_chrome", {"albedo_a": Color(0.75, 0.76, 0.78), "albedo_b": Color(0.68, 0.69, 0.71), "metallic_value": 0.9,
		"roughness_a": 0.18, "roughness_b": 0.3}, "metal")
	MatLib.define("l61_wood", {"albedo_a": Color(0.50, 0.32, 0.18), "albedo_b": Color(0.43, 0.27, 0.15), "pattern": 3,
		"pattern_scale": Vector2(1.6, 0.12), "grout_width": 0.003, "grout_color": Color(0.2, 0.12, 0.06), "roughness_a": 0.4,
		"roughness_b": 0.6}, "wood_floor")
	MatLib.define("l61_pillar", {"albedo_a": Color(0.92, 0.90, 0.86), "albedo_b": Color(0.88, 0.86, 0.82), "roughness_a": 0.3,
		"roughness_b": 0.4, "noise_scale": 0.5})
	MatLib.define("l61_terra_dark", {"albedo_a": Color(0.42, 0.22, 0.14), "albedo_b": Color(0.36, 0.19, 0.12), "roughness_a": 0.7,
		"roughness_b": 0.85, "noise_scale": 1.5})
	MatLib.define("l61_shutter", {"albedo_a": Color(0.62, 0.63, 0.64), "albedo_b": Color(0.55, 0.56, 0.57), "pattern": 2,
		"pattern_scale": Vector2(1.0, 0.09), "pattern_color": Color(0.38, 0.39, 0.40), "pattern_strength": 0.6, "metallic_value": 0.6,
		"roughness_a": 0.4, "roughness_b": 0.55, "stain_amount": 0.15, "stain_color": Color(0.4, 0.3, 0.2)}, "metal")
	MatLib.define("l61_black", {"albedo_a": Color(0.03, 0.03, 0.035), "albedo_b": Color(0.02, 0.02, 0.025), "roughness_a": 0.4,
		"roughness_b": 0.5})
	MatLib.define("l61_snack", {"albedo_a": Color(0.85, 0.55, 0.1), "albedo_b": Color(0.2, 0.55, 0.75), "noise_scale": 9.0,
		"noise_mix": 1.0, "roughness_a": 0.4, "roughness_b": 0.5})
	for v in [["l61_vend_red", Color(0.6, 0.06, 0.05)], ["l61_vend_blue", Color(0.06, 0.16, 0.5)], ["l61_vend_white", Color(0.85, 0.85, 0.82)],
			["l61_vend_green", Color(0.08, 0.35, 0.15)]]:
		MatLib.define(v[0], {"albedo_a": v[1], "albedo_b": v[1] * 0.88, "roughness_a": 0.3, "roughness_b": 0.45, "metallic_value": 0.2})
	for b in [["l61_bottle_a", Color(0.9, 0.85, 0.7)], ["l61_bottle_b", Color(0.75, 0.6, 0.4)], ["l61_bottle_c", Color(0.6, 0.8, 0.95)]]:
		MatLib.register(b[0], MatLib.panel(b[1], 0.6))
	MatLib.register("l61_vend_glow", MatLib.panel(Color(1.0, 0.95, 0.85), 1.3))
	MatLib.register("l61_fridge_glow", MatLib.panel(Color(0.85, 0.95, 1.0), 0.8))
	MatLib.register("l61_window_glow", MatLib.panel(Color(1.0, 0.86, 0.66), 2.2))
	MatLib.register("l61_daylight", MatLib.panel(Color(1.0, 0.9, 0.75), 4.0))
	var sk := StandardMaterial3D.new()
	sk.albedo_color = Color(0.0, 0.0, 0.0)
	sk.roughness = 0.05
	sk.metallic = 0.3
	sk.metallic_specular = 0.9
	MatLib.register("l61_skyglass", sk)
	var g := StandardMaterial3D.new()
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.albedo_color = Color(0.85, 0.9, 0.9, 0.12)
	g.roughness = 0.03
	g.metallic_specular = 0.6
	MatLib.register("l61_glass", g)
	var signs := {"pink": Color(1.0, 0.3, 0.6), "teal": Color(0.2, 0.9, 0.85), "amber": Color(1.0, 0.7, 0.25), "red": Color(1.0, 0.2, 0.15),
		"white": Color(1.0, 0.97, 0.9), "green": Color(0.35, 1.0, 0.45), "blue": Color(0.35, 0.55, 1.0)}
	for s in signs.keys():
		MatLib.register("l61_sign_" + s, MatLib.panel(signs[s], 1.8))


func build(slot_table: Dictionary) -> void:
	_atrium()
	for h in HALLS.keys():
		_hall(h, slot_table)
	_hall_ends()


# ------------------------------------------------------------------ atrium

func _atrium() -> void:
	# floor with the circular dip: one lathe mesh + trimesh collision
	var mesh := _pit_mesh()
	for ri in 3:
		var r: float = PIT_R[ri]
		var y0: float = PIT_Y[ri]
		var y1: float = PIT_Y[ri + 1] if ri < 2 else 0.0
		for i in 48:
			var a := TAU * (i + 0.5) / 48.0
			var bas := Basis(Vector3.UP, -a)
			k.box_xf(Transform3D(bas, Vector3(cos(a) * (r - 0.02), (y0 + y1) * 0.5, sin(a) * (r - 0.02))), Vector3(0.05, y1 - y0 - 0.01, TAU * r / 48.0 * 1.02), "l61_trim_teal", GeoKit.ALL, false)
	var mi := MeshInstance3D.new()
	mi.name = "AtriumFloor"
	mi.mesh = mesh
	mi.material_override = MatLib.get_mat("l61_terrazzo")
	props.add_child(mi)
	var body := StaticBody3D.new()
	body.name = "AtriumFloorBody"
	var cs := CollisionShape3D.new()
	cs.shape = mesh.create_trimesh_shape()
	cs.set_meta("surface", "tile")
	body.add_child(cs)
	props.add_child(body)
	k.box_mm(Vector3(-A, -1.4, -A), Vector3(A, -0.9, A), "l61_black", GeoKit.NY, false)
	# walls with the hall mouths (8 m wide, 5 m high) and orange-white clerestory windows
	for side in [[Vector3(-A, 0, -A), Vector3(A, 0, -A)], [Vector3(A, 0, -A), Vector3(A, 0, A)],
			[Vector3(A, 0, A), Vector3(-A, 0, A)], [Vector3(-A, 0, A), Vector3(-A, 0, -A)]]:
		var a: Vector3 = side[0]
		var b: Vector3 = side[1]
		k.wall(a, b, 5.2, T, "l61_wall", [{"at": A, "w": 8.0, "h": 5.0}])
		k.wall(a + Vector3(0, 5.2, 0), b + Vector3(0, 5.2, 0), AH - 5.2, T, "l61_wall",
			[{"at": 5.0, "w": 5.0, "h": 1.4, "sill": 0.35}, {"at": A * 2.0 - 5.0, "w": 5.0, "h": 1.4, "sill": 0.35}])
		var dir := (b - a).normalized()
		var n := Vector3.UP.cross(dir).normalized()  # points out of the atrium
		for at in [5.0, A * 2.0 - 5.0]:
			var c: Vector3 = a + dir * at + Vector3(0, 6.25, 0) + n * 0.1
			k.quad(c, -n, dir * 2.5, Vector3(0, 0.7, 0), "l61_window_glow")
		# a plum trim band at 5.2 m
		k.box(a.lerp(b, 0.5) + Vector3(0, 5.2, 0) - n * 0.16, Vector3(absf(dir.x) * 32.0 + 0.04, 0.18, absf(dir.z) * 32.0 + 0.04), "l61_trim", GeoKit.ALL, false)
	# ceiling with a 14 m square skylight: black glass, beams, nothing above
	var c0 := 7.0
	k.box_mm(Vector3(-A, AH, -A), Vector3(A, AH + 0.3, -c0), "l61_ceiling", GeoKit.NY | GeoKit.PY, true)
	k.box_mm(Vector3(-A, AH, c0), Vector3(A, AH + 0.3, A), "l61_ceiling", GeoKit.NY | GeoKit.PY, true)
	k.box_mm(Vector3(-A, AH, -c0), Vector3(-c0, AH + 0.3, c0), "l61_ceiling", GeoKit.NY | GeoKit.PY, true)
	k.box_mm(Vector3(c0, AH, -c0), Vector3(A, AH + 0.3, c0), "l61_ceiling", GeoKit.NY | GeoKit.PY, true)
	k.box_mm(Vector3(-c0, AH + 1.4, -c0), Vector3(c0, AH + 1.5, c0), "l61_skyglass", GeoKit.NY, false)
	for i in 8:
		var v := -c0 + i * 2.0
		k.box(Vector3(v, AH + 0.7, 0), Vector3(0.12, 1.4, c0 * 2.0), "l61_chrome", GeoKit.ALL, false)
		k.box(Vector3(0, AH + 0.7, v), Vector3(c0 * 2.0, 1.4, 0.12), "l61_chrome", GeoKit.ALL, false)
	for s in [Vector3(-c0, 0, 0), Vector3(c0, 0, 0)]:
		k.box(s + Vector3(0, AH + 0.75, 0), Vector3(0.3, 1.5, c0 * 2.0), "l61_ceiling", GeoKit.ALL, false)
	for s in [Vector3(0, 0, -c0), Vector3(0, 0, c0)]:
		k.box(s + Vector3(0, AH + 0.75, 0), Vector3(c0 * 2.0, 1.5, 0.3), "l61_ceiling", GeoKit.ALL, false)
	for x in [-4.0, 0.0, 4.0]:
		for z in [-4.0, 0.0, 4.0]:
			skylights.append(Vector3(x, AH - 0.3, z))
	# pillars, benches all around the dip, plants
	for c in [Vector3(-11.5, 0, -11.5), Vector3(11.5, 0, -11.5), Vector3(-11.5, 0, 11.5), Vector3(11.5, 0, 11.5)]:
		K.pillar(c, AH)
	for i in 12:
		var a2 := TAU * (i + 0.5) / 12.0
		K.bench(Vector3(cos(a2), 0, sin(a2)) * 8.75, -rad_to_deg(a2) + 90.0, 2.4)
	for c in [Vector3(-14.6, 0, -6.2), Vector3(14.6, 0, 6.2), Vector3(-6.2, 0, 14.6), Vector3(6.2, 0, -14.6)]:
		K.planter(c)
	# navy tables in the dip and around it
	for i in 6:
		var a3 := TAU * i / 6.0 + 0.3
		K.table_set(Vector3(cos(a3) * 3.8, -0.9, sin(a3) * 3.8), rad_to_deg(a3) * 0.5)
	K.table_set(Vector3(0, -0.9, 0), 15.0)
	for c in [Vector3(-12.5, 0, -2.6), Vector3(-12.5, 0, 3.0), Vector3(12.5, 0, -3.0), Vector3(12.5, 0, 2.6), Vector3(-3.0, 0, -12.6),
			Vector3(2.8, 0, -12.6), Vector3(-2.8, 0, 12.6), Vector3(3.0, 0, 12.6), Vector3(-13.2, 0, 13.0), Vector3(13.2, 0, -13.2)]:
		K.table_set(c, L.rng.randf_range(0.0, 40.0))
	for c in [Vector3(-14.3, 5.0, -14.3), Vector3(14.3, 5.0, 14.3)]:
		speakers.append(c)
		K.p("kenney/furniture-kit/speakersmall", c, 45.0, 0.5)


## Lathe: terrazzo floor out to the atrium walls, three steps down into the dip.
func _pit_mesh(risers_only := false) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 64
	var ring := func(r0: float, r1: float, y: float) -> void:
		for i in n:
			var a0 := TAU * i / n
			var a1 := TAU * (i + 1) / n
			var p00 := Vector3(cos(a0) * r0, y, sin(a0) * r0)
			var p01 := Vector3(cos(a1) * r0, y, sin(a1) * r0)
			var p10 := Vector3(cos(a0) * r1, y, sin(a0) * r1)
			var p11 := Vector3(cos(a1) * r1, y, sin(a1) * r1)
			for v in [p00, p10, p11, p00, p11, p01]:
				st.set_normal(Vector3.UP)
				st.set_uv(Vector2(v.x, v.z) * 0.5)
				st.add_vertex(v)
	var riser := func(r: float, y0: float, y1: float) -> void:
		for i in n:
			var a0 := TAU * i / n
			var a1 := TAU * (i + 1) / n
			var d0 := Vector3(cos(a0), 0, sin(a0))
			var d1 := Vector3(cos(a1), 0, sin(a1))
			var q := [d0 * r + Vector3(0, y0, 0), d1 * r + Vector3(0, y0, 0), d1 * r + Vector3(0, y1, 0), d0 * r + Vector3(0, y1, 0)]
			for j in ([0, 2, 1, 0, 3, 2, 0, 1, 2, 0, 2, 3] if risers_only else [0, 2, 1, 0, 3, 2]):
				st.set_normal(-(d0 + d1).normalized())
				st.set_uv(Vector2((TAU * (i + (1 if j in [1, 2] else 0)) / n) * r, (q[j] as Vector3).y) * 0.5)
				st.add_vertex(q[j])
	# pit floor disc and the two intermediate steps; risers drawn as a teal band
	riser.call(PIT_R[0], PIT_Y[0], PIT_Y[1])
	riser.call(PIT_R[1], PIT_Y[1], PIT_Y[2])
	riser.call(PIT_R[2], PIT_Y[2], 0.0)
	if risers_only:
		return st.commit()
	ring.call(0.0, PIT_R[0], PIT_Y[0])
	ring.call(PIT_R[0], PIT_R[1], PIT_Y[1])
	ring.call(PIT_R[1], PIT_R[2], PIT_Y[2])
	# outer floor: from the circle to the square boundary along each ray
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var c0 := Vector3(cos(a0), 0, sin(a0))
		var c1 := Vector3(cos(a1), 0, sin(a1))
		var s0 := c0 * (A / maxf(absf(c0.x), absf(c0.z)))
		var s1 := c1 * (A / maxf(absf(c1.x), absf(c1.z)))
		var verts := [c0 * PIT_R[2], s1, c1 * PIT_R[2], c0 * PIT_R[2], s0, s1]
		# a square corner falls between the two rays: add it
		for v in verts:
			st.set_normal(Vector3.UP)
			st.set_uv(Vector2(v.x, v.z) * 0.5)
			st.add_vertex(v)
		var corner_ang := fposmod(a0, PI * 0.5)
		if corner_ang < PI * 0.25 and fposmod(a1, PI * 0.5) > PI * 0.25:
			var cc := Vector3(signf(cos(a0 + PI * 0.25 - corner_ang)), 0, signf(sin(a0 + PI * 0.25 - corner_ang))) * A
			for v in [s0, cc, s1]:
				st.set_normal(Vector3.UP)
				st.set_uv(Vector2(v.x, v.z) * 0.5)
				st.add_vertex(v)
	st.index()
	st.generate_tangents()
	return st.commit()


# ------------------------------------------------------------------ halls

func _hall(h: String, slot_table: Dictionary) -> void:
	var cfg: Dictionary = HALLS[h]
	var a0: Vector3 = cfg["a"]
	var d: Vector3 = cfg["d"]
	var len: float = cfg["len"]
	var side_v := Vector3.UP.cross(d).normalized()
	var e := a0 + d * len
	var mm := func(p: Vector3, q: Vector3, y0: float, y1: float) -> Array:
		return [Vector3(minf(p.x, q.x), y0, minf(p.z, q.z)), Vector3(maxf(p.x, q.x), y1, maxf(p.z, q.z))]
	var f: Array = mm.call(a0 - side_v * (HW + 0.3), e + side_v * (HW + 0.3), -0.3, 0.0)
	k.box_mm(f[0], f[1], "l61_terrazzo")
	# ceiling at 5 m with a 3 m skylight strip of black glass down the middle
	for s in [-1.0, 1.0]:
		var c: Array = mm.call(a0 + side_v * 1.5 * s, e + side_v * (HW + 0.3) * s, HH, HH + 0.3)
		k.box_mm(c[0], c[1], "l61_ceiling", GeoKit.NY | GeoKit.PY, true)
		var w: Array = mm.call(a0 + side_v * 1.5 * s, e + side_v * 1.7 * s, HH, HH + 1.2)
		k.box_mm(w[0], w[1], "l61_ceiling", GeoKit.ALL, false)
	var g: Array = mm.call(a0 - side_v * 1.6, e + side_v * 1.6, HH + 1.15, HH + 1.25)
	k.box_mm(g[0], g[1], "l61_skyglass", GeoKit.NY, false)
	for i in int(len / 4.0):
		var bc := a0 + d * (2.0 + i * 4.0) + Vector3(0, HH + 0.9, 0)
		var bs := (side_v * 3.2).abs() + (d * 0.12).abs()
		k.box(bc, Vector3(bs.x, 0.1, bs.z), "l61_chrome", GeoKit.ALL, false)
		if i % 2 == 0:
			skylights.append(a0 + d * (2.0 + i * 4.0) + Vector3(0, HH - 0.4, 0))
	# storefront slots on both sides
	for side in [1, -1]:
		var n: Vector3 = side_v * side
		for i in int(len / 8.0):
			var key := "%s%s%d" % [h, "L" if side == 1 else "R", i]
			var info: Dictionary = slot_table.get(key, {"type": "wall", "name": ""})
			var c := a0 + d * (4.0 + 8.0 * i) + n * HW
			_facade(h, side, i, c, d, n, info)
	# pillars and benches down the middle line, planters
	for i in int(len / 16.0):
		var pc := a0 + d * (12.0 + 16.0 * i)
		K.bench(pc + side_v * 1.8, yaw_x(d), 2.2)
		K.bench(pc - side_v * 1.8, yaw_x(d), 2.2)
		K.planter(pc, true)


func _facade(h: String, side: int, i: int, c: Vector3, d: Vector3, n: Vector3, info: Dictionary) -> void:
	var a := c - d * 4.0
	var b := c + d * 4.0
	var t: String = info["type"]
	var ops: Array = []
	if t in ["open", "closed", "office"]:
		ops = [{"at": 4.0, "w": 3.8, "h": 2.9}]
	elif t == "kiosk":
		ops = [{"at": 4.0, "w": 5.2, "h": 2.6}]
	k.wall(a, b, HH, T, "l61_wall", ops)
	var X := Vector3.UP.cross(n).normalized()
	var xf := Transform3D(Basis(X, Vector3.UP, n), c)
	var slot := {"hall": h, "side": side, "i": i, "type": t, "name": info.get("name", ""), "xf": xf, "center": c,
		"front": c - n * 1.2, "kind": info.get("kind", ""), "col": info.get("col", "white")}
	slots.append(slot)
	# skirting and a plum trim band
	k.box(c - n * 0.17 + Vector3(0, 0.06, 0), (d * 8.0).abs() + (n * 0.04).abs() + Vector3(0, 0.12, 0), "l61_trim", GeoKit.ALL, false)
	if t in ["open", "closed", "kiosk", "office"]:
		# a sign band over the opening
		var sc := c - n * 0.25 + Vector3(0, 3.45, 0)
		var w := 5.6 if t == "kiosk" else 4.4
		k.box(sc, (d * w).abs() + (n * 0.16).abs() + Vector3(0, 0.75, 0), "l61_black", GeoKit.ALL, false)
		var nm: String = info.get("name", "")
		var col: String = info.get("col", "white")
		if nm != "":
			K.label(nm, sc - n * 0.09, rad_to_deg(atan2(-n.x, -n.z)), 92, _sign_col(col), 10)
		else:
			k.box(sc - n * 0.085, (d * (w - 0.4)).abs() + Vector3(0, 0.5, 0) + (n * 0.01).abs(), "l61_sign_" + col, GeoKit.ALL, false)
	elif t == "wall":
		var wk: String = info.get("kind", "")
		if wk == "vending":
			K.vending_machine(c - n * 0.55 - d * 1.2, rad_to_deg(atan2(-n.x, -n.z)), ["l61_vend_red", "l61_vend_blue", "l61_vend_white"][i % 3])
			K.vending_machine(c - n * 0.55, rad_to_deg(atan2(-n.x, -n.z)), ["l61_vend_blue", "l61_vend_green", "l61_vend_red"][i % 3])
			K.vending_machine(c - n * 0.55 + d * 1.2, rad_to_deg(atan2(-n.x, -n.z)), "l61_vend_white")
		elif wk == "vent":
			_vent(c - n * 0.16 + d * 2.0, n)
			K.bench(c - n * 0.6 - d * 1.5, yaw_x(d), 2.4)
		elif wk == "bent":
			_bent(c, d, n)
		else:
			K.bench(c - n * 0.6, yaw_x(d), 2.4)
			K.planter(c - n * 0.8 + d * 2.6, false)


## Yaw (degrees) that turns local +X onto the horizontal direction v.
static func yaw_x(v: Vector3) -> float:
	return rad_to_deg(atan2(-v.z, v.x))


func _sign_col(col: String) -> Color:
	var m := {"pink": Color(1.0, 0.45, 0.7), "teal": Color(0.35, 1.0, 0.95), "amber": Color(1.0, 0.8, 0.35), "red": Color(1.0, 0.35, 0.3),
		"white": Color(1.0, 0.98, 0.92), "green": Color(0.5, 1.0, 0.55), "blue": Color(0.5, 0.7, 1.0)}
	return m.get(col, Color(1, 1, 1))


## A floor-level vent opening (SOURCE: any vent opening sucks you into Level 3).
func _vent(c: Vector3, n: Vector3) -> void:
	var X := Vector3.UP.cross(n).normalized()
	var xf := Transform3D(Basis(X, Vector3.UP, n), c)
	k.box_xf(xf * Transform3D(Basis(), Vector3(0, 0.35, 0.05)), Vector3(0.9, 0.55, 0.1), "l61_black", GeoKit.ALL, false)
	for j in 5:
		k.box_xf(xf * Transform3D(Basis(), Vector3(0, 0.14 + j * 0.105, -0.02)), Vector3(0.9, 0.025, 0.03), "l61_chrome", GeoKit.ALL, false)
	k.box_xf(xf * Transform3D(Basis(), Vector3(0, 0.35, -0.02)), Vector3(1.0, 0.65, 0.02), "l61_chrome", GeoKit.ALL, false)
	vents.append({"pos": c + Vector3(0, 0.4, 0) - n * 0.5, "normal": n})


## SOURCE: "a wall that is unnaturally bent". A section of the hall wall bulges
## and twists out of true; hairline cracks glow faintly blue.
func _bent(c: Vector3, d: Vector3, n: Vector3) -> void:
	for j in 9:
		var t := (j - 4) / 4.0
		var bulge := (1.0 - t * t) * 0.55
		var twist := sin(t * 2.4) * 0.25
		var pc := c + d * (t * 1.6) - n * (0.15 + bulge) + Vector3(0, 1.6, 0)
		var bas := Basis(Vector3.UP, atan2(d.x, d.z) + twist) * Basis(Vector3.RIGHT, t * 0.15)
		k.box_xf(Transform3D(bas, pc), Vector3(0.12, 3.2, 0.45), "l61_wall", GeoKit.ALL, true)
	for j in 6:
		var cc := c + d * L.rng.randf_range(-1.2, 1.2) - n * 0.62 + Vector3(0, L.rng.randf_range(0.6, 2.8), 0)
		k.box_xf(Transform3D(Basis(Vector3.UP, atan2(-d.z, d.x)) * Basis(Vector3.BACK, L.rng.randf_range(-1.0, 1.0)), cc), Vector3(0.6, 0.02, 0.02), "l61_sign_blue", GeoKit.ALL, false)
	bent_wall = c - n * 0.9 + Vector3(0, 1.2, 0)


func _hall_ends() -> void:
	# N: the end wall with the rusty steel door (outpost built by the shops helper)
	k.wall(Vector3(-HW - 0.15, 0, -64), Vector3(HW + 0.15, 0, -64), HH, T, "l61_wall", [{"at": HW + 0.15, "w": 1.3, "h": 2.3}])
	# E: open into the vending-machine-choked room (shops helper); W: a shuttered mall entrance
	k.wall(Vector3(56, 0, -HW - 0.15), Vector3(56, 0, HW + 0.15), HH, T, "l61_wall", [{"at": HW + 0.15, "w": 5.0, "h": 3.2}])
	k.wall(Vector3(-56, 0, -HW - 0.15), Vector3(-56, 0, HW + 0.15), HH, T, "l61_wall", [{"at": HW + 0.15, "w": 7.0, "h": 3.4}])
	for j in 3:
		k.box(Vector3(-55.95, 1.7, -2.3 + j * 2.3), Vector3(0.08, 3.4, 2.3), "l61_shutter", GeoKit.ALL, true)
	k.box(Vector3(-55.8, 3.95, 0), Vector3(0.16, 0.8, 7.4), "l61_black", GeoKit.ALL, false)
	k.box(Vector3(-55.71, 3.95, 0), Vector3(0.01, 0.5, 6.8), "l61_sign_white", GeoKit.ALL, false)
	# S: the perimeter: a glass front with sliding doors and orange-white daylight beyond
	k.wall(Vector3(-HW - 0.15, 0, 56), Vector3(HW + 0.15, 0, 56), HH, T, "l61_wall", [{"at": HW + 0.15, "w": 7.4, "h": 3.6}])
	k.box(Vector3(0, 3.65, 56), Vector3(7.4, 0.1, 0.3), "l61_chrome", GeoKit.ALL, false)
	for x in [-3.2, 3.2]:
		k.box(Vector3(x, 1.8, 56), Vector3(1.0, 3.6, 0.06), "l61_glass", GeoKit.ALL, true)
		k.box(Vector3(x + signf(x) * 0.5, 1.8, 56), Vector3(0.08, 3.6, 0.12), "l61_chrome", GeoKit.ALL, false)
	k.box_mm(Vector3(-6, -0.3, 55.8), Vector3(6, 0.0, 62), "l61_terrazzo")
	k.box_mm(Vector3(-6, 0, 61.6), Vector3(6, 6, 62.0), "l61_daylight", GeoKit.NZ, false)
	k.box_mm(Vector3(-6.3, 0, 56.2), Vector3(-6.0, 6, 62.0), "l61_daylight", GeoKit.PX, false)
	k.box_mm(Vector3(6.0, 0, 56.2), Vector3(6.3, 6, 62.0), "l61_daylight", GeoKit.NX, false)
	k.box_mm(Vector3(-6.3, 5.0, 56.2), Vector3(6.3, 5.3, 62.0), "l61_daylight", GeoKit.NY, false)
	K.label("EXIT", Vector3(0, 4.1, 55.8), 180.0, 70, Color(0.4, 1.0, 0.5), 6)
