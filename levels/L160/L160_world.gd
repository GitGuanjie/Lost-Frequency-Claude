extends RefCounted
## Level 160 outdoor memory route: grey straw field -> the swing on its mound ->
## the azure shallows under the orange sky (with a raised boardwalk) -> the short
## street of shut cottages ("the city of promised memories") -> her house.
## Every image comes from the page text or its credited image titles (Straw Fogs,
## Grey Dreams, swings Empty, Orange Sky, Fittie, House With Striped Awnings).

const PLAY := Vector3(0.0, 0.5, -46.0)
const AZURE_MIN := Vector2(22.0, -66.0)
const AZURE_MAX := Vector2(56.0, -28.0)
const DECK_Y := 1.0
const STREET_X := 50.0
const STREET_Z0 := -26.0
const STREET_Z1 := 6.0

var L: Node3D
var k: GeoKit
var swing_pivots: Array = []


func _init(level: Node3D, kit: GeoKit) -> void:
	L = level
	k = kit


static func materials() -> void:
	MatLib.define("l160_grass", {"albedo_a": Color(0.25, 0.23, 0.17), "albedo_b": Color(0.19, 0.18, 0.13),
		"pattern": 12, "pattern_scale": Vector2(0.6, 0.6), "pattern_color": Color(0.36, 0.32, 0.22), "pattern_strength": 0.6,
		"noise_scale": 0.15, "stain_amount": 0.45, "stain_color": Color(0.14, 0.14, 0.12), "stain_scale": 0.08, "bump_strength": 0.8}, "grass")
	MatLib.define("l160_dirt", {"albedo_a": Color(0.36, 0.33, 0.29), "albedo_b": Color(0.30, 0.28, 0.25), "noise_scale": 0.6}, "dirt")
	MatLib.define("l160_sand", {"albedo_a": Color(0.66, 0.60, 0.48), "albedo_b": Color(0.58, 0.52, 0.41), "pattern": 13,
		"pattern_scale": Vector2(0.5, 0.5), "pattern_strength": 0.2, "wetness": 0.6}, "sand")
	MatLib.define("l160_azure", {"albedo_a": Color(0.03, 0.30, 0.72), "albedo_b": Color(0.02, 0.24, 0.62), "noise_scale": 0.05,
		"roughness_a": 0.22, "roughness_b": 0.32, "bump_strength": 0.15, "emission_color": Color(0.0, 0.10, 0.28), "emission_energy": 0.35})
	MatLib.define("l160_wood", {"albedo_a": Color(0.42, 0.36, 0.29), "albedo_b": Color(0.34, 0.29, 0.23), "pattern": 3,
		"pattern_scale": Vector2(0.14, 2.0), "stain_amount": 0.3, "stain_color": Color(0.25, 0.25, 0.24)}, "wood_floor")
	MatLib.define("l160_frame", {"albedo_a": Color(0.42, 0.18, 0.14), "albedo_b": Color(0.36, 0.15, 0.12),
		"metallic_value": 0.4, "roughness_a": 0.55, "roughness_b": 0.7, "stain_amount": 0.4, "stain_color": Color(0.30, 0.20, 0.14)}, "metal")
	MatLib.define("l160_chain", {"albedo_a": Color(0.5, 0.5, 0.5), "albedo_b": Color(0.42, 0.42, 0.42), "metallic_value": 0.8, "roughness_a": 0.4}, "metal")
	MatLib.register("l160_rubber", MatLib.standard(Color(0.08, 0.08, 0.09), 0.8))
	MatLib.define("l160_hay", {"albedo_a": Color(0.60, 0.53, 0.36), "albedo_b": Color(0.50, 0.44, 0.29), "pattern": 2,
		"pattern_scale": Vector2(0.05, 1.0), "pattern_strength": 0.3, "bump_strength": 0.8})
	MatLib.define("l160_cobble", {"albedo_a": Color(0.40, 0.40, 0.41), "albedo_b": Color(0.33, 0.33, 0.34), "pattern": 14,
		"pattern_scale": Vector2(0.22, 0.14), "grout_color": Color(0.22, 0.22, 0.22), "grout_width": 0.05, "wetness": 0.35}, "concrete")
	MatLib.define("l160_pavement", {"albedo_a": Color(0.52, 0.52, 0.51), "albedo_b": Color(0.46, 0.46, 0.45), "pattern": 1,
		"pattern_scale": Vector2(0.9, 0.9), "grout_color": Color(0.34, 0.34, 0.34)}, "concrete")
	var pastel := [Color(0.72, 0.62, 0.58), Color(0.62, 0.68, 0.70), Color(0.74, 0.70, 0.56), Color(0.64, 0.68, 0.58)]
	for i in pastel.size():
		MatLib.define("l160_cottage_%d" % i, {"albedo_a": pastel[i], "albedo_b": pastel[i].darkened(0.08), "stain_amount": 0.35,
			"stain_color": pastel[i].darkened(0.3), "grime_height": 0.6, "grime_color": Color(0.3, 0.3, 0.28)}, "plaster")
	MatLib.define("l160_roof", {"albedo_a": Color(0.22, 0.22, 0.24), "albedo_b": Color(0.17, 0.17, 0.19), "pattern": 14,
		"pattern_scale": Vector2(0.3, 0.2), "grout_color": Color(0.1, 0.1, 0.1)}, "concrete")
	MatLib.register("l160_dark_glass", MatLib.standard(Color(0.06, 0.07, 0.08), 0.1, 0.4))
	MatLib.define("l160_door", {"albedo_a": Color(0.30, 0.24, 0.20), "albedo_b": Color(0.26, 0.20, 0.17)}, "wood_floor")


## Ground, path, straw bales, posts and wires: the grey present.
func field(r: RandomNumberGenerator) -> void:
	k.box(Vector3(30, -0.25, -20), Vector3(420, 0.5, 420), "l160_grass", GeoKit.PY | GeoKit.SIDES, true)
	# worn path north to the swing, then east to the shallows
	k.box(Vector3(0, 0.006, -16), Vector3(1.8, 0.012, 36), "l160_dirt", GeoKit.PY, false)
	k.box(Vector3(17.5, 0.006, -46), Vector3(9, 0.012, 1.8), "l160_dirt", GeoKit.PY, false)
	# wooden utility poles and their sagging wires along the path
	var prev := Vector3.ZERO
	for i in 6:
		var p := Vector3(-3.2, 0, 6.0 - float(i) * 13.0)
		k.cylinder(p + Vector3(0, 3.6, 0), 0.13, 7.2, "l160_wood", 8, true)
		k.box(p + Vector3(0, 6.6, 0), Vector3(1.6, 0.12, 0.12), "l160_wood", GeoKit.ALL, false)
		if i > 0:
			for side in [-0.7, 0.7]:
				_wire(prev + Vector3(side, 6.6, 0), p + Vector3(side, 6.6, 0))
		prev = p
	# round straw bales standing in the fog
	for i in 9:
		var a := r.randf_range(0, TAU)
		var d := r.randf_range(9.0, 28.0)
		var c := Vector3(cos(a) * d, 0, -14 + sin(a) * d * 0.8)
		if absf(c.x) < 3.5:
			c.x += 6.0 * signf(c.x + 0.01)
		k.cylinder(c + Vector3(0, 0.6, 0), 0.75, 1.2, "l160_hay", 14, true)


func _wire(a: Vector3, b: Vector3) -> void:
	var n := 6
	for j in n:
		var t0 := float(j) / n
		var t1 := float(j + 1) / n
		var p0 := a.lerp(b, t0) - Vector3(0, sin(t0 * PI) * 0.7, 0)
		var p1 := a.lerp(b, t1) - Vector3(0, sin(t1 * PI) * 0.7, 0)
		var d := p1 - p0
		var bas := Basis.looking_at(d.normalized(), Vector3.UP) if absf(d.normalized().y) < 0.99 else Basis()
		k.box_xf(Transform3D(bas, (p0 + p1) * 0.5), Vector3(0.015, 0.015, d.length()), "l160_chain", GeoKit.ALL, false)


## The mound with the swing set "you used to share" (and a picnic table).
func playground() -> void:
	var y := PLAY.y
	k.slab(-9, -55, 9, -38, y, 0.6, "l160_grass")
	for e in [[Vector3(0, y * 0.5 - 0.05, -37.95), Vector3(18.2, y + 0.1, 0.12)], [Vector3(0, y * 0.5 - 0.05, -55.05), Vector3(18.2, y + 0.1, 0.12)],
			[Vector3(-9.05, y * 0.5 - 0.05, -46.5), Vector3(0.12, y + 0.1, 17.2)], [Vector3(9.05, y * 0.5 - 0.05, -46.5), Vector3(0.12, y + 0.1, 17.2)]]:
		k.box(e[0], e[1], "l160_wood", GeoKit.ALL, false)
	k.ramp(Vector3(0, 0, -33.6), Vector3(0, y, -38.0), 2.6, 0.3, "l160_dirt")
	k.ramp(Vector3(13.4, 0, -46), Vector3(9.0, y, -46), 2.6, 0.3, "l160_dirt")
	# sand under the swings
	k.box(Vector3(0, y + 0.006, -47), Vector3(5.6, 0.012, 3.6), "l160_sand", GeoKit.PY, false)
	# A-frames and top bar
	var top := y + 2.45
	for sx in [-2.0, 2.0]:
		for sz in [-1.0, 1.0]:
			var foot := Vector3(sx, y, -47 + sz * 0.95)
			var head := Vector3(sx, top, -47)
			var d := head - foot
			var bas := Basis.looking_at(d.normalized(), Vector3.RIGHT)
			k.box_xf(Transform3D(bas, (foot + head) * 0.5), Vector3(0.07, 0.07, d.length()), "l160_frame", GeoKit.ALL, false)
	k.box(Vector3(0, top, -47), Vector3(4.2, 0.09, 0.09), "l160_frame", GeoKit.ALL, false)
	k.add_box_shape(Transform3D(Basis(), Vector3(-2.0, y + 1.2, -47)), Vector3(0.2, 2.4, 1.9), "metal")
	k.add_box_shape(Transform3D(Basis(), Vector3(2.0, y + 1.2, -47)), Vector3(0.2, 2.4, 1.9), "metal")
	for sx in [-0.8, 0.8]:
		var pivot := Node3D.new()
		pivot.name = "Swing"
		pivot.position = Vector3(sx, top - 0.05, -47)
		L.add_child(pivot)
		var sk := GeoKit.new(pivot, "SwingSeat")
		var len := top - 0.05 - (y + 0.48)
		for cx in [-0.21, 0.21]:
			sk.box(Vector3(cx, -len * 0.5, 0), Vector3(0.012, len, 0.012), "l160_chain", GeoKit.ALL, false)
		sk.box(Vector3(0, -len, 0), Vector3(0.48, 0.03, 0.17), "l160_rubber", GeoKit.ALL, false)
		sk.commit()
		swing_pivots.append(pivot)


## The infinite stretch of azure under the burning orange sky; a raised boardwalk crosses it.
func shallows() -> void:
	var cx := (AZURE_MIN.x + AZURE_MAX.x) * 0.5
	var cz := (AZURE_MIN.y + AZURE_MAX.y) * 0.5
	var sx := AZURE_MAX.x - AZURE_MIN.x
	var sz := AZURE_MAX.y - AZURE_MIN.y
	# wet sand floor (footsteps splash), then the azure sheet reaching past the fog
	k.box(Vector3(cx, 0.005, cz), Vector3(sx, 0.01, sz), "l160_sand", GeoKit.PY, false)
	k.add_box_shape(Transform3D(Basis(), Vector3(cx, -0.04, cz)), Vector3(sx, 0.1, sz), "water")
	k.box(Vector3(cx + 40, 0.004, cz - 60), Vector3(sx + 120, 0.008, sz + 100), "l160_sand", GeoKit.PY, false)
	k.box(Vector3(cx + 40, 0.16, cz - 60), Vector3(sx + 140, 0.02, sz + 110), "l160_azure", GeoKit.PY, false)
	# boardwalk at +1.0 m from x=24 to x=50 along z=-46, with a viewing platform
	var z := -46.0
	k.stairs(Vector3(20.6, 0, z), Vector3(1, 0, 0), 2.2, DECK_Y, 5, "l160_wood")
	k.box(Vector3(37.0, DECK_Y - 0.06, z), Vector3(30.0, 0.12, 2.4), "l160_wood")
	k.box(Vector3(37.0, DECK_Y - 0.06, z - 2.9), Vector3(5.0, 0.12, 3.4), "l160_wood")
	k.stairs(Vector3(53.4, 0, z), Vector3(-1, 0, 0), 2.2, DECK_Y, 5, "l160_wood")
	for x in range(25, 50, 3):
		for side in [-1.15, 1.15]:
			k.box(Vector3(x, DECK_Y * 0.5 - 0.1, z + side), Vector3(0.16, DECK_Y + 0.2, 0.16), "l160_wood", GeoKit.ALL, false)
			k.box(Vector3(x, DECK_Y + 0.5, z + side), Vector3(0.08, 1.0, 0.08), "l160_wood", GeoKit.ALL, false)
	k.box(Vector3(37.0, DECK_Y + 1.0, z + 1.2), Vector3(30.0, 0.07, 0.07), "l160_wood")
	k.box(Vector3(28.25, DECK_Y + 1.0, z - 1.2), Vector3(12.5, 0.07, 0.07), "l160_wood")
	k.box(Vector3(45.75, DECK_Y + 1.0, z - 1.2), Vector3(12.5, 0.07, 0.07), "l160_wood")
	k.box(Vector3(37.0, DECK_Y + 1.0, z - 4.55), Vector3(5.0, 0.07, 0.07), "l160_wood")
	for sxp in [34.55, 39.45]:
		k.box(Vector3(sxp, DECK_Y + 1.0, z - 2.95), Vector3(0.07, 0.07, 3.3), "l160_wood")


## A short street of shut cottages: the "city" the voice names. No one is home.
func street(r: RandomNumberGenerator) -> Array:
	var lamps: Array = []
	var x := STREET_X
	var len := STREET_Z1 - STREET_Z0
	var cz := (STREET_Z0 + STREET_Z1) * 0.5
	k.box(Vector3(x, 0.01, cz), Vector3(6.0, 0.02, len), "l160_cobble", GeoKit.PY, false)
	for side in [-1.0, 1.0]:
		k.box(Vector3(x + side * 4.5, 0.075, cz), Vector3(3.0, 0.15, len), "l160_pavement", GeoKit.ALL, true)
	var i := 0
	for side in [-1.0, 1.0]:
		var z := STREET_Z0 + 1.0
		while z < STREET_Z1 - 5.0:
			var w := r.randf_range(5.2, 6.6)
			_cottage(Vector3(x + side * 9.6, 0, z + w * 0.5), w, side, i % 4, r)
			z += w + 0.4
			i += 1
	for j in 4:
		var lz := STREET_Z0 + 3.0 + float(j) * 8.5
		var lx := x + (3.3 if j % 2 == 0 else -3.3)
		lamps.append([Vector3(lx, 0.15, lz), 90.0 if j % 2 == 0 else -90.0])
	return lamps


func _cottage(c: Vector3, w: float, side: float, tint: int, r: RandomNumberGenerator) -> void:
	var d := 6.0
	var h := r.randf_range(3.0, 3.6)
	var mat := "l160_cottage_%d" % tint
	var front := c.x - side * d * 0.5
	k.box(Vector3(c.x, h * 0.5, c.z), Vector3(d, h, w), mat)
	# pitched roof: two slabs along z
	var pitch := deg_to_rad(34.0)
	var run := d * 0.5 + 0.35
	var slope := run / cos(pitch)
	for s in [-1.0, 1.0]:
		var bas := Basis(Vector3(0, 0, 1), s * -pitch)
		var ctr := Vector3(c.x + s * run * 0.5, h + tan(pitch) * run * 0.5 - 0.05, c.z)
		k.box_xf(Transform3D(bas, ctr), Vector3(slope, 0.12, w + 0.5), "l160_roof", GeoKit.ALL, false)
	# gable ends
	for gz in [c.z - w * 0.5 - 0.01, c.z + w * 0.5 + 0.01]:
		var steps := 6
		for sidx in steps:
			var yy := h + (float(sidx) + 0.5) * (tan(pitch) * d * 0.5) / steps
			var ww := d * (1.0 - (float(sidx) + 0.5) / steps)
			k.box(Vector3(c.x, yy, gz), Vector3(ww, tan(pitch) * d * 0.5 / steps, 0.04), mat, GeoKit.ALL, false)
	if r.randf() < 0.6:
		k.box(Vector3(c.x + side * 0.8, h + 1.6, c.z + w * 0.25), Vector3(0.6, 1.4, 0.6), "l160_roof", GeoKit.ALL, false)
	# door with a step, and two dark windows with sills: shut, curtained
	var fx := front - side * 0.02
	k.box(Vector3(fx, 1.05, c.z - w * 0.18), Vector3(0.06, 2.1, 0.95), "l160_door", GeoKit.ALL, false)
	k.box(Vector3(front - side * 0.35, 0.08, c.z - w * 0.18), Vector3(0.7, 0.16, 1.3), "l160_pavement", GeoKit.ALL, true)
	for wz in [c.z + w * 0.22]:
		k.box(Vector3(fx, 1.55, wz), Vector3(0.05, 1.1, 1.1), "l160_dark_glass", GeoKit.ALL, false)
		k.box(Vector3(fx - side * 0.04, 0.97, wz), Vector3(0.12, 0.06, 1.25), "l160_pavement", GeoKit.ALL, false)
		k.box(Vector3(fx - side * 0.01, 1.55, wz), Vector3(0.04, 1.1, 0.06), "l160_door", GeoKit.ALL, false)
		k.box(Vector3(fx - side * 0.01, 1.55, wz), Vector3(0.04, 0.06, 1.1), "l160_door", GeoKit.ALL, false)
