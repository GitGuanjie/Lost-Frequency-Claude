extends RefCounted
## Level 899 structures: the rock outcrop with the way back, the terrace and its
## dining hall (chefs, mushroom dishes), the cottages of the residents (one is the
## guest cottage), the spring and its lake, the mushroom beds, the lookout and the
## rail round the island's rim. No electric light anywhere (brochure).

const I := preload("res://levels/L899/L899_island.gd")

var lv
var isl
var k: GeoKit
var rng: RandomNumberGenerator
var props: Node3D
var spots := {}


func _init(level, island, r: RandomNumberGenerator) -> void:
	lv = level
	isl = island
	rng = r
	k = level.kit("Structures")
	props = Node3D.new()
	props.name = "Props"
	level.add_child(props)


static func materials() -> void:
	MatLib.define("l899_stone", {"albedo_a": Color(0.36, 0.34, 0.31), "albedo_b": Color(0.27, 0.26, 0.24), "pattern": 4,
		"pattern_scale": Vector2(0.7, 0.35), "grout_width": 0.03, "grout_color": Color(0.18, 0.17, 0.16), "tile_variation": 0.12, "bump_strength": 1.2, "stain_amount": 0.3, "stain_color": Color(0.2, 0.25, 0.15)}, "")
	MatLib.define("l899_plaster", {"albedo_a": Color(0.42, 0.4, 0.36), "albedo_b": Color(0.36, 0.34, 0.3), "noise_scale": 1.5, "stain_amount": 0.25, "stain_color": Color(0.35, 0.33, 0.25), "grime_height": 0.5, "grime_color": Color(0.3, 0.28, 0.2)}, "")
	MatLib.define("l899_timber", {"albedo_a": Color(0.16, 0.1, 0.06), "albedo_b": Color(0.12, 0.075, 0.045), "pattern": 3, "pattern_scale": Vector2(0.2, 2.0), "roughness_a": 0.8}, "")
	MatLib.define("l899_plank", {"albedo_a": Color(0.3, 0.2, 0.12), "albedo_b": Color(0.24, 0.16, 0.1), "pattern": 3, "pattern_scale": Vector2(0.18, 2.4), "roughness_a": 0.7}, "")
	MatLib.define("l899_roof", {"albedo_a": Color(0.13, 0.12, 0.13), "albedo_b": Color(0.1, 0.09, 0.1), "pattern": 14, "pattern_scale": Vector2(0.35, 0.25), "grout_width": 0.03, "grout_color": Color(0.04, 0.04, 0.05), "tile_variation": 0.15, "bump_strength": 1.0}, "")
	MatLib.define("l899_flag", {"albedo_a": Color(0.26, 0.25, 0.23), "albedo_b": Color(0.2, 0.19, 0.18), "pattern": 15, "pattern_scale": Vector2(0.6, 0.6), "grout_width": 0.02, "grout_color": Color(0.2, 0.19, 0.18)}, "")
	MatLib.define("l899_soil", {"albedo_a": Color(0.07, 0.05, 0.035), "albedo_b": Color(0.05, 0.035, 0.025), "noise_scale": 6.0, "roughness_a": 1.0}, "")
	MatLib.define("l899_window", {"albedo_a": Color(0.02, 0.025, 0.04), "albedo_b": Color(0.03, 0.04, 0.06), "roughness_a": 0.08, "roughness_b": 0.15, "metallic_value": 0.4}, "")
	MatLib.define("l899_rockmass", {"albedo_a": Color(0.2, 0.19, 0.2), "albedo_b": Color(0.13, 0.12, 0.13), "pattern": 11, "pattern_scale": Vector2(1.4, 0.6), "pattern_strength": 0.4, "noise_scale": 0.8, "bump_strength": 1.6, "stain_amount": 0.35, "stain_color": Color(0.12, 0.16, 0.1)}, "")
	MatLib.define("l899_cloth", {"albedo_a": Color(0.36, 0.33, 0.28), "albedo_b": Color(0.3, 0.28, 0.24), "pattern": 2, "pattern_scale": Vector2(0.25, 0.25), "pattern_color": Color(0.35, 0.2, 0.18), "pattern_strength": 0.25}, "")
	MatLib.define("l899_iron", {"albedo_a": Color(0.04, 0.04, 0.04), "albedo_b": Color(0.06, 0.05, 0.05), "metallic_value": 0.5, "roughness_a": 0.6}, "")
	MatLib.register("l899_fire", MatLib.panel(Color(1.0, 0.45, 0.12), 2.6, 0.35))
	MatLib.register("l899_stream", MatLib.water({"shallow_color": Color(0.35, 0.55, 0.6), "deep_color": Color(0.1, 0.25, 0.3), "wave_height": 0.02, "wave_scale": 0.6, "wave_speed": 2.0, "foam_amount": 0.6}))
	MatLib.register("l899_lake", MatLib.water({"shallow_color": Color(0.16, 0.3, 0.34), "deep_color": Color(0.03, 0.07, 0.1), "absorption": 0.06, "clarity": 0.7, "wave_height": 0.03, "wave_scale": 0.3, "wave_speed": 0.3, "foam_amount": 0.1, "roughness_value": 0.04}))


func y(x: float, z: float) -> float:
	return isl.h(x, z)


func build_all() -> void:
	outcrop()
	terrace()
	hall()
	cottages()
	spring()
	beds()
	lookout()
	fence()
	k.commit()


# ------------------------------------------------------------------ the way back

func outcrop() -> void:
	var o: Vector3 = I.OUTCROP
	var fy := I.H0
	# the passage: stone-lined, 3 m wide, running 15 m south into the rock
	k.box_mm(Vector3(o.x - 1.7, fy - 0.4, 54.0), Vector3(o.x + 1.7, fy + 0.05, 71.0), "l899_flag", GeoKit.PY | GeoKit.SIDES)
	for s in [-1.0, 1.0]:
		k.box_mm(Vector3(o.x + s * 1.5 - 0.3, fy, 55.0), Vector3(o.x + s * 1.5 + 0.3, fy + 3.2, 71.0), "l899_stone")
	k.box_mm(Vector3(o.x - 1.8, fy + 3.1, 55.0), Vector3(o.x + 1.8, fy + 3.6, 71.0), "l899_stone")
	k.box_mm(Vector3(o.x - 1.8, fy, 70.6), Vector3(o.x + 1.8, fy + 3.6, 71.2), "unlit_black")
	for zz in [57.0, 61.0, 65.0]:
		k.box(Vector3(o.x, fy + 3.0, zz), Vector3(3.0, 0.22, 0.3), "l899_timber", GeoKit.ALL, false)
		for s in [-1.0, 1.0]:
			k.box(Vector3(o.x + s * 1.15, fy + 1.5, zz), Vector3(0.22, 3.0, 0.3), "l899_timber", GeoKit.ALL, false)
	# portal: dressed stone jambs and lintel with a carved name board
	for s in [-1.0, 1.0]:
		k.box(Vector3(o.x + s * 1.95, fy + 1.8, 55.2), Vector3(0.7, 3.6, 0.9), "l899_stone")
	k.box(Vector3(o.x, fy + 3.85, 55.2), Vector3(4.6, 0.7, 0.95), "l899_stone")
	k.box(Vector3(o.x, fy + 4.55, 55.05), Vector3(2.6, 0.5, 0.08), "l899_timber", GeoKit.ALL, false)
	var lb := Label3D.new()
	lb.text = "YONDER'S END"
	lb.font_size = 64
	lb.pixel_size = 0.0055
	lb.modulate = Color(0.75, 0.68, 0.5)
	lb.shaded = true
	lb.position = Vector3(o.x, fy + 4.55, 55.0)
	lb.rotation.y = PI
	lv.add_child(lb)
	# the rock mass round it
	var blocks := [[Vector3(o.x - 6.0, fy + 3.0, 63.0), Vector3(7.0, 7.0, 17.0), 0.06], [Vector3(o.x + 6.1, fy + 3.4, 63.5), Vector3(7.0, 8.0, 17.0), -0.05],
		[Vector3(o.x, fy + 6.6, 63.5), Vector3(7.0, 4.2, 17.0), 0.03], [Vector3(o.x - 1.0, fy + 8.6, 66.0), Vector3(9.0, 3.0, 10.0), 0.18],
		[Vector3(o.x + 0.5, fy + 2.5, 73.5), Vector3(14.0, 6.0, 4.0), 0.0]]
	for b in blocks:
		var xf := Transform3D(Basis(Vector3.UP, float(b[2])) * Basis(Vector3(1, 0, 0), float(b[2]) * 0.6), b[0])
		k.box_xf(xf, b[1], "l899_rockmass")
	for b in [[-4.6, 53.6, 2.2], [7.4, 54.2, 2.6], [-9.8, 57.5, 3.0], [10.6, 57.0, 3.4], [-11.5, 63.0, 2.8], [12.5, 64.0, 3.2], [3.8, 74.5, 2.5]]:
		var bp := Vector3(o.x + float(b[0]), 0, float(b[1]))
		Props.place(lv, props, "ph/boulder_01", Vector3(bp.x, y(bp.x, bp.z) - 0.4, bp.z), rng.randf() * 360.0, float(b[2]), true)
	spots["tunnel_end"] = Vector3(o.x, fy + 1.4, 67.0)
	spots["mouth"] = Vector3(o.x, fy, 54.0)


# ------------------------------------------------------------------ terrace and hall

func terrace() -> void:
	var tr: Rect2 = I.TERRACE
	var ty := I.TERRACE_Y
	var wz := tr.end.y
	# retaining wall with a stair gap at x 21..23.2
	for seg in [[tr.position.x, 20.8], [23.4, tr.end.x]]:
		var cx := (float(seg[0]) + float(seg[1])) * 0.5
		var w := float(seg[1]) - float(seg[0])
		k.box(Vector3(cx, ty - 2.6, wz + 0.45), Vector3(w, 6.0, 1.3), "l899_stone")
		k.box(Vector3(cx, ty + 0.5, wz + 0.45), Vector3(w + 0.1, 0.25, 1.45), "l899_flag")
	# stair up the wall
	var rise := 0.0
	var z0 := wz + 7.0
	for it in 3:
		rise = ty - y(22.1, z0)
		var steps := int(ceil(rise / 0.18))
		z0 = wz + 0.1 + steps * 0.3
	var steps2 := int(ceil(rise / 0.18))
	var base := Vector3(22.1, y(22.1, z0) - 0.02, z0)
	k.stairs(base, Vector3(0, 0, -1), 2.4, ty - base.y, steps2, "l899_flag", 0.3)
	for s in [-1.0, 1.0]:
		var a := Vector3(22.1 + s * 1.35, 0, z0)
		k.box_mm(Vector3(a.x - 0.15, base.y - 0.5, wz), Vector3(a.x + 0.15, ty + 0.6, z0), "l899_stone")
	spots["stair_foot"] = base


func hall() -> void:
	var ty := I.TERRACE_Y
	var x0 := 16.5
	var x1 := 27.5
	var z0 := -43.0
	var z1 := -23.0
	var fy := ty + 0.12
	k.box_mm(Vector3(x0, ty - 0.6, z0), Vector3(x1, fy, z1), "l899_flag", GeoKit.PY | GeoKit.SIDES)
	# posts, plates, rafters and a pitched shingle roof
	var z := z0 + 0.3
	while z <= z1:
		for x in [x0 + 0.3, x1 - 0.3]:
			k.box(Vector3(x, fy + 1.6, z), Vector3(0.3, 3.2, 0.3), "l899_timber")
		k.box(Vector3((x0 + x1) * 0.5, fy + 3.35, z), Vector3(x1 - x0, 0.25, 0.22), "l899_timber", GeoKit.ALL, false)
		z += 4.0
	for x in [x0 + 0.3, x1 - 0.3]:
		k.box(Vector3(x, fy + 3.25, (z0 + z1) * 0.5), Vector3(0.3, 0.3, z1 - z0), "l899_timber", GeoKit.ALL, false)
	var half := (x1 - x0) * 0.5 + 0.8
	var pitch := 0.55
	for s in [-1.0, 1.0]:
		var c := Vector3((x0 + x1) * 0.5 + s * half * 0.5 * cos(pitch), fy + 3.45 + half * 0.5 * sin(pitch), (z0 + z1) * 0.5)
		var xf := Transform3D(Basis(Vector3(0, 0, 1), -s * pitch), c)
		k.box_xf(xf, Vector3(half, 0.18, z1 - z0 + 1.2), "l899_roof", GeoKit.ALL, false)
	k.box(Vector3((x0 + x1) * 0.5, fy + 3.45 + half * sin(pitch), (z0 + z1) * 0.5), Vector3(0.3, 0.3, z1 - z0 + 1.2), "l899_timber", GeoKit.ALL, false)
	# kitchen at the north end: a stone range with a live fire, chimney, work tables
	var kz := z0 + 1.2
	k.box(Vector3(22.0, fy + 0.5, kz), Vector3(4.0, 1.0, 1.4), "l899_stone")
	k.box(Vector3(22.0, fy + 1.02, kz), Vector3(4.1, 0.06, 1.5), "l899_iron", GeoKit.ALL, false)
	k.box(Vector3(22.0, fy + 0.45, kz + 0.71), Vector3(1.2, 0.5, 0.02), "l899_fire", GeoKit.ALL, false)
	k.box(Vector3(22.0, fy + 4.0, kz - 0.2), Vector3(1.4, 6.0, 1.0), "l899_stone")
	for i in 3:
		Props.place(lv, props, ["kenney/food-kit/pot-stew", "kenney/food-kit/pan-stew", "kenney/food-kit/pot"][i], Vector3(20.8 + i * 1.2, fy + 1.05, kz), rng.randf() * 360.0, 0.3)
	for s in [-1.0, 1.0]:
		var tx: float = 22.0 + s * 3.6
		k.box(Vector3(tx, fy + 0.85, kz + 2.2), Vector3(1.0, 0.08, 2.6), "l899_plank", GeoKit.ALL, false)
		k.box(Vector3(tx, fy + 0.42, kz + 2.2), Vector3(0.9, 0.84, 2.4), "l899_timber", 0, true)
		Props.place(lv, props, "kenney/food-kit/cutting-board", Vector3(tx, fy + 0.9, kz + 1.6), 0.0, 0.04)
		Props.place(lv, props, "ph/wooden_crate_01", Vector3(tx + s * 0.9, fy, kz + 3.6), 90.0, 0.0, true)
		for b in 3:
			Props.place(lv, props, "kenney/food-kit/bowl", Vector3(tx, fy + 0.9, kz + 2.3 + b * 0.35), rng.randf() * 360.0, 0.1)
	Props.place(lv, props, "ph/Barrel_01", Vector3(x0 + 0.9, fy, kz + 0.4), 0.0, 0.0, true)
	spots["fire"] = Vector3(22.0, fy + 0.6, kz + 1.0)
	spots["chef"] = Vector3(22.0, fy, kz + 1.6)
	# two long tables with benches and bowls of the day's mushrooms
	for s in [-1.0, 1.0]:
		var tx2: float = 22.0 + s * 2.3
		var tz := (z0 + z1) * 0.5 + 2.5
		k.box(Vector3(tx2, fy + 0.76, tz), Vector3(1.0, 0.07, 11.0), "l899_plank", GeoKit.ALL, false)
		k.box(Vector3(tx2, fy + 0.79, tz), Vector3(1.04, 0.01, 11.0), "l899_cloth", GeoKit.ALL, false)
		k.box(Vector3(tx2, fy + 0.38, tz), Vector3(1.0, 0.76, 11.0), "l899_timber", 0, true)
		for e in [-5.0, 5.0]:
			k.box(Vector3(tx2, fy + 0.37, tz + e), Vector3(0.9, 0.74, 0.12), "l899_timber", GeoKit.ALL, false)
		for b in [-0.75, 0.75]:
			k.box(Vector3(tx2 + b, fy + 0.43, tz), Vector3(0.32, 0.06, 10.6), "l899_plank", GeoKit.ALL, false)
			k.box(Vector3(tx2 + b, fy + 0.2, tz), Vector3(0.08, 0.4, 10.0), "l899_timber", GeoKit.ALL, false)
		for i in 7:
			var pz := tz - 4.5 + i * 1.5
			Props.place(lv, props, "kenney/food-kit/bowl" if i % 2 == 0 else "kenney/food-kit/plate-deep", Vector3(tx2 + rng.randf_range(-0.25, 0.25), fy + 0.8, pz), rng.randf() * 360.0, 0.09 if i % 2 == 0 else 0.05)
			if i % 3 == 0:
				Props.place(lv, props, "kenney/food-kit/mug", Vector3(tx2 + 0.3, fy + 0.8, pz + 0.4), rng.randf() * 360.0, 0.1)
	spots["table_a"] = Vector3(22.0 - 2.3 - 0.75, fy + 0.45, -30.5)
	spots["table_b"] = Vector3(22.0 + 2.3 + 0.75, fy + 0.45, -27.0)
	spots["hall"] = Vector3(22.0, fy, -30.0)
	lv.add_note("l899_terms", "The faculty's terms (pinned to a post)",
		"Guests are welcome for a few days. Anything longer counts as a lifetime reservation: you stay forever, you give up your youth, and you never need to worry about anything again. Nothing is hidden. Everyone here chose to be here.",
		Vector3(x1 - 0.15, fy + 1.5, -25.0), Vector3(0.4, 0.8, 0.8), false)
	var paper := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.01, 0.4, 0.3)
	paper.mesh = bm
	paper.material_override = MatLib.get_mat("paper")
	paper.position = Vector3(x1 - 0.13, fy + 1.5, -25.0)
	lv.add_child(paper)


# ------------------------------------------------------------------ cottages

func cottage(c: Vector2, yaw: float, guest := false) -> void:
	var gy := y(c.x, c.y)
	for dx in [-2.6, 2.6]:
		for dz in [-2.1, 2.1]:
			var p := Vector2(c.x, c.y) + Vector2(dx, dz).rotated(-yaw)
			gy = maxf(gy, y(p.x, p.y))
	gy += 0.15
	var bas := Basis(Vector3.UP, yaw)
	var o := Vector3(c.x, gy, c.y)
	var L := func(v: Vector3) -> Vector3: return o + bas * v
	var w := 5.2
	var d := 4.2
	k.box_xf(Transform3D(bas, o + Vector3(0, -0.8, 0)), Vector3(w + 0.4, 1.8, d + 0.4), "l899_stone")
	var hh := 2.5
	var walls := [[Vector3(-w * 0.5, 0, d * 0.5), Vector3(w * 0.5, 0, d * 0.5), [{"at": 1.4, "w": 0.95, "h": 2.0}, {"at": 3.9, "w": 0.9, "h": 0.9, "sill": 0.95}]],
		[Vector3(w * 0.5, 0, d * 0.5), Vector3(w * 0.5, 0, -d * 0.5), [{"at": 2.1, "w": 0.9, "h": 0.9, "sill": 0.95}]],
		[Vector3(w * 0.5, 0, -d * 0.5), Vector3(-w * 0.5, 0, -d * 0.5), [{"at": 2.6, "w": 0.9, "h": 0.9, "sill": 0.95}]],
		[Vector3(-w * 0.5, 0, -d * 0.5), Vector3(-w * 0.5, 0, d * 0.5), []]]
	for wl in walls:
		k.wall(L.call(wl[0]), L.call(wl[1]), hh, 0.3, "l899_plaster", wl[2])
	# window glass and frames
	for wp in [[Vector3(-w * 0.5 + 3.9, 1.4, d * 0.5), 0.0], [Vector3(w * 0.5, 1.4, d * 0.5 - 2.1), PI * 0.5], [Vector3(w * 0.5 - 2.6, 1.4, -d * 0.5), 0.0]]:
		k.box_xf(Transform3D(bas * Basis(Vector3.UP, wp[1]), L.call(wp[0])), Vector3(0.9, 0.9, 0.05), "l899_window", GeoKit.ALL, false)
		k.box_xf(Transform3D(bas * Basis(Vector3.UP, wp[1]), L.call(wp[0])), Vector3(0.06, 0.9, 0.08), "l899_timber", GeoKit.ALL, false)
	# door leaf: open for the guest cottage, shut for the others
	if guest:
		k.box_xf(Transform3D(bas * Basis(Vector3.UP, -1.3), L.call(Vector3(-w * 0.5 + 0.92, 1.0, d * 0.5 + 0.45))), Vector3(0.9, 2.0, 0.06), "l899_plank", GeoKit.ALL, false)
	else:
		k.box_xf(Transform3D(bas, L.call(Vector3(-w * 0.5 + 1.4, 1.0, d * 0.5))), Vector3(0.95, 2.0, 0.08), "l899_plank")
	# roof
	var pitch := 0.62
	var half := d * 0.5 + 0.5
	for s in [-1.0, 1.0]:
		var rc := Vector3(0, hh + half * 0.5 * sin(pitch) + 0.05, s * half * 0.5 * cos(pitch))
		k.box_xf(Transform3D(bas * Basis(Vector3(1, 0, 0), s * pitch), L.call(rc)), Vector3(w + 0.8, 0.16, half + 0.05), "l899_roof", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		for r in 5:
			var t := float(r) / 5.0
			k.box_xf(Transform3D(bas, L.call(Vector3(s * w * 0.5, hh + 0.12 + t * half * sin(pitch) * 0.95, 0))), Vector3(0.3, 0.26, (1.0 - t) * d), "l899_plaster", GeoKit.ALL, false)
	k.box_xf(Transform3D(bas, L.call(Vector3(w * 0.5 - 1.0, hh + 1.6, -0.8))), Vector3(0.6, 1.6, 0.6), "l899_stone", GeoKit.ALL, false)
	k.box_xf(Transform3D(bas, L.call(Vector3(0, -0.02, 0))), Vector3(w - 0.3, 0.04, d - 0.3), "l899_plank", GeoKit.PY)
	# a bench by the door
	k.box_xf(Transform3D(bas, L.call(Vector3(w * 0.5 - 1.6, 0.42, d * 0.5 + 0.55))), Vector3(1.4, 0.07, 0.4), "l899_plank", GeoKit.ALL, false)
	k.box_xf(Transform3D(bas, L.call(Vector3(w * 0.5 - 1.6, 0.2, d * 0.5 + 0.55))), Vector3(1.3, 0.4, 0.3), "l899_timber", 0, true)
	Props.place(lv, props, "ph/barrel_03", L.call(Vector3(w * 0.5 + 0.55, 0.0, d * 0.5 - 0.5)), rng.randf() * 360.0, 0.0, true)
	if rng.randf() < 0.6:
		Props.place(lv, props, "ph/wooden_crate_01", L.call(Vector3(-w * 0.5 - 0.6, 0.0, -0.8)), rad_to_deg(yaw) + 90.0, 0.0, true)
	if rng.randf() < 0.4:
		Props.place(lv, props, "ph/wooden_ladder", L.call(Vector3(w * 0.5 + 0.3, 0.0, -1.2)), rad_to_deg(yaw) - 90.0)
	if guest:
		var inside := func(v: Vector3) -> Vector3: return L.call(v)
		Props.place(lv, props, "ph/old_bed_frame", inside.call(Vector3(1.4, 0, -0.9)), rad_to_deg(yaw) + 90.0, 0.0, true)
		k.box_xf(Transform3D(bas, inside.call(Vector3(1.4, 0.5, -0.9))), Vector3(1.9, 0.14, 0.85), "l899_cloth", GeoKit.ALL, false)
		Props.place(lv, props, "ph/ClassicNightstand_01", inside.call(Vector3(2.2, 0, 0.6)), rad_to_deg(yaw) - 90.0)
		Props.place(lv, props, "ph/ArmChair_01", inside.call(Vector3(-1.6, 0, -1.2)), rad_to_deg(yaw) + 30.0)
		Props.place(lv, props, "ph/vintage_suitcase", inside.call(Vector3(-0.5, 0, -1.7)), rad_to_deg(yaw))
		Props.place(lv, props, "ph/wall_clock", inside.call(Vector3(0.0, 1.9, -d * 0.5 + 0.18)), rad_to_deg(yaw))
		Props.place(lv, props, "kenney/furniture-kit/rugrectangle", inside.call(Vector3(-0.3, 0.01, 0.2)), rad_to_deg(yaw), 0.02)
		spots["bed"] = inside.call(Vector3(1.4, 0.6, -0.9))
		spots["guest_door"] = inside.call(Vector3(-w * 0.5 + 1.4, 0.0, d * 0.5 + 1.6))
		spots["guest_in"] = inside.call(Vector3(-0.6, 0.0, 0.4))
		spots["guest_yaw"] = yaw


func cottages() -> void:
	var list := [[Vector2(-6, 34), 0.3, true], [Vector2(-34, 34), -0.2, false], [Vector2(-50, 2), 1.4, false], [Vector2(-36, -14), 0.9, false],
		[Vector2(-10, -14), 0.1, false], [Vector2(40, 30), -0.6, false], [Vector2(-22, -36), 0.4, false], [Vector2(48, -30), -1.1, false]]
	for c in list:
		cottage(c[0], c[1], c[2])


# ------------------------------------------------------------------ water

func spring() -> void:
	var lk: Vector2 = I.LAKE
	var r: Vector2 = I.LAKE_R
	var wv := WaterVolume.new()
	wv.name = "Lake"
	lv.add_child(wv)
	wv.setup(Vector3(lk.x - r.x * 0.86, 0.0, lk.y - r.y * 0.86), Vector3(lk.x + r.x * 0.86, I.WATER_Y, lk.y + r.y * 0.86), "l899_lake", true)
	wv.fog_color = Color(0.03, 0.07, 0.09)
	wv.fog_density = 0.25
	wv.tint = Color(0.2, 0.4, 0.45)
	# the spring: rocks at the west end, water running down into the lake
	var sp := Vector3(lk.x - r.x - 2.0, 0.0, lk.y)
	sp.y = y(sp.x, sp.z)
	for i in 6:
		var a := TAU * i / 6.0
		var p := sp + Vector3(cos(a) * 2.6, 0, sin(a) * 2.4)
		Props.place(lv, props, "ph/boulder_01", Vector3(p.x, y(p.x, p.z) - 0.3, p.z), rng.randf() * 360.0, rng.randf_range(1.2, 2.4), true)
	Props.place(lv, props, "ph/boulder_01", sp + Vector3(-1.5, -0.3, 0), 30.0, 3.0, true)
	var top := sp + Vector3(0.2, 2.2, 0)
	var bot := Vector3(lk.x - r.x * 0.8, I.WATER_Y + 0.02, lk.y)
	var d := bot - top
	var c := (top + bot) * 0.5
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.9, d.length(), 0.05)
	mi.mesh = bm
	mi.material_override = MatLib.get_mat("l899_stream")
	mi.transform = Transform3D(Basis.looking_at(d.normalized(), Vector3.UP) * Basis(Vector3(1, 0, 0), PI * 0.5), c)
	mi.scale = Vector3(1, 1, 1)
	lv.add_child(mi)
	# a short plank jetty out over the lake, and tables on the shore
	var jx := lk.x + 4.0
	var jz := lk.y - r.y * 0.98
	var jy := I.WATER_Y + 0.35
	k.box_mm(Vector3(jx - 0.9, jy - 0.12, jz - 0.5), Vector3(jx + 0.9, jy, jz + 7.0), "l899_plank")
	for pz in [0.5, 3.0, 5.5]:
		for sx in [-0.8, 0.8]:
			k.box(Vector3(jx + sx, jy - 1.4, jz + pz), Vector3(0.18, 2.8, 0.18), "l899_timber", GeoKit.ALL, false)
	for t in [[Vector3(lk.x + 15.0, 0, lk.y - 9.0), 20.0], [Vector3(lk.x - 8.0, 0, lk.y + 17.0), -35.0], [Vector3(10.0, 0, -12.0), 80.0]]:
		var tp: Vector3 = t[0]
		tp.y = y(tp.x, tp.z)
		Props.place(lv, props, "ph/wooden_picnic_table", tp, float(t[1]), 0.0, true)
	spots["spring"] = sp + Vector3(0, 1.0, 0)
	spots["lake"] = Vector3(lk.x, I.WATER_Y, lk.y)


# ------------------------------------------------------------------ mushrooms

func beds() -> void:
	var stems: Array = []
	var caps: Array = []
	for row in 6:
		var bx := 44.0 + row * 4.0
		for seg in 2:
			var z0 := -12.0 + seg * 15.0
			var z1 := z0 + 12.0
			var gy := (y(bx, z0) + y(bx, z1) + y(bx, (z0 + z1) * 0.5)) / 3.0
			k.box_mm(Vector3(bx - 0.7, gy - 0.8, z0), Vector3(bx + 0.7, gy + 0.3, z1), "l899_plank")
			k.box_mm(Vector3(bx - 0.6, gy + 0.3, z0 + 0.1), Vector3(bx + 0.6, gy + 0.33, z1 - 0.1), "l899_soil", GeoKit.PY, false)
			for m in 40:
				var p := Vector3(bx + rng.randf_range(-0.5, 0.5), gy + 0.33, rng.randf_range(z0 + 0.3, z1 - 0.3))
				var sz := rng.randf_range(1.0, 2.6)
				stems.append(Transform3D(Basis().scaled(Vector3(sz, sz, sz)), p + Vector3(0, 0.06 * sz, 0)))
				caps.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(sz, sz * rng.randf_range(0.5, 0.9), sz)), p + Vector3(0, 0.11 * sz, 0)))
	# inoculated log stacks with clusters on them
	for i in 4:
		var c := Vector3(40.0 + i * 7.0, 0, 21.0 + (i % 2) * 2.0)
		c.y = y(c.x, c.z)
		for l in 4:
			var yaw := 0.0 if l % 2 == 0 else 90.0
			Props.place(lv, props, "ph/dead_tree_trunk", c + Vector3(0, l * 0.27, 0), yaw + rng.randf_range(-6, 6))
			for m in 5:
				var along := Vector3(rng.randf_range(-1.3, 1.3), 0, 0).rotated(Vector3.UP, deg_to_rad(yaw))
				var p2 := c + along + Vector3(0, l * 0.27 + 0.26, 0)
				var s2 := rng.randf_range(0.5, 1.0)
				stems.append(Transform3D(Basis().scaled(Vector3(s2, s2, s2)), p2 + Vector3(0, 0.05 * s2, 0)))
				caps.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s2, s2 * 0.6, s2)), p2 + Vector3(0, 0.1 * s2, 0)))
	_mm(stems, _stem_mesh(), Color(0.72, 0.68, 0.6))
	_mm(caps, _cap_mesh(), Color(0.45, 0.32, 0.2), true)
	for c in [Vector3(42.5, 0, -14.5), Vector3(43.0, 0, 1.6), Vector3(66.0, 0, -14.0)]:
		var cp: Vector3 = c
		cp.y = y(cp.x, cp.z)
		Props.place(lv, props, "ph/wooden_crate_01", cp, rng.randf() * 40.0, 0.0, true)
		Props.place(lv, props, "ph/wooden_crate_01", cp + Vector3(0, 0.35, 0), rng.randf() * 40.0)
		Props.place(lv, props, "ph/Barrel_01", cp + Vector3(1.0, 0, 0.6), 0.0, 0.0, true)
	spots["beds"] = Vector3(54.0, y(54.0, 0.0), 0.0)


func _stem_mesh() -> Mesh:
	var cm := CylinderMesh.new()
	cm.top_radius = 0.018
	cm.bottom_radius = 0.026
	cm.height = 0.12
	cm.radial_segments = 6
	cm.rings = 1
	return cm


func _cap_mesh() -> Mesh:
	var sm := SphereMesh.new()
	sm.radius = 0.065
	sm.height = 0.065
	sm.is_hemisphere = true
	sm.radial_segments = 10
	sm.rings = 3
	return sm


func _mm(xfs: Array, mesh: Mesh, col: Color, vary := false) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	var tones := [Color(0.5, 0.36, 0.22), Color(0.7, 0.62, 0.48), Color(0.36, 0.24, 0.15), Color(0.62, 0.5, 0.34), Color(0.78, 0.74, 0.64)]
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
		mm.set_instance_color(i, tones[rng.randi() % tones.size()] if vary else col)
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.7
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = 60.0
	lv.add_child(mi)


# ------------------------------------------------------------------ lookout and rail

func lookout() -> void:
	var lk: Vector2 = I.LOOKOUT
	var p := Vector3(lk.x - 4.0, 0, lk.y - 4.0)
	p.y = y(p.x, p.z)
	var bas := Basis(Vector3.UP, deg_to_rad(45.0))
	k.box_xf(Transform3D(bas, p + Vector3(0, 0.44, 0)), Vector3(2.2, 0.08, 0.5), "l899_plank", GeoKit.ALL, false)
	k.box_xf(Transform3D(bas, p + Vector3(0, 0.2, 0)), Vector3(2.0, 0.42, 0.4), "l899_timber", 0, true)
	k.box_xf(Transform3D(bas, p + bas * Vector3(0, 0.75, 0.24)), Vector3(2.2, 0.5, 0.06), "l899_plank", GeoKit.ALL, false)
	spots["bench"] = p
	spots["lookout"] = Vector3(lk.x, y(lk.x, lk.y), lk.y)


func fence() -> void:
	var pts: Array = isl.fence_points()
	var o: Vector3 = I.OUTCROP
	for i in pts.size():
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % pts.size()]
		if Vector2(a.x - o.x, a.z - o.z).length() < 12.5 or Vector2(b.x - o.x, b.z - o.z).length() < 12.5:
			continue
		k.box(a + Vector3(0, 0.55, 0), Vector3(0.14, 1.3, 0.14), "l899_timber", GeoKit.ALL, false)
		var mid := (a + b) * 0.5
		var dd := b - a
		var flat := Vector3(dd.x, 0, dd.z)
		var yaw := atan2(flat.x, flat.z)
		var tilt := atan2(dd.y, flat.length())
		var bas := Basis(Vector3.UP, yaw) * Basis(Vector3(1, 0, 0), -tilt)
		for ry in [0.55, 1.05]:
			k.box_xf(Transform3D(bas, mid + Vector3(0, ry, 0)), Vector3(0.07, 0.1, dd.length() + 0.1), "l899_timber", GeoKit.ALL, false)
		k.box_xf(Transform3D(Basis(Vector3.UP, yaw), mid + Vector3(0, 1.2, 0)), Vector3(0.2, 2.6, flat.length() + 0.2), "l899_timber", 0, true)
