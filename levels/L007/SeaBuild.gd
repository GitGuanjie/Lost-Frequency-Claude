extends RefCounted
## Level 7 world building (authored set pieces and streamed chunks), split out
## of L007.gd to keep the level script inside its size budget. Rules and
## runtime behaviour stay in L007.gd; meshes come from SeaGeo.gd.

const Geo := preload("res://levels/L007/SeaGeo.gd")


static func materials() -> void:
	MatLib.register("l7_carpet", Geo.flooded_carpet_material())
	MatLib.define("l7_wall", {"albedo_a": Color(0.56, 0.58, 0.51), "albedo_b": Color(0.47, 0.5, 0.43), "stain_amount": 0.75, "stain_color": Color(0.4, 0.37, 0.27),
		"stain_scale": 0.6, "grime_height": 0.7, "floor_y": Geo.ROOM.y, "grime_color": Color(0.22, 0.22, 0.17), "noise_scale": 1.1, "bump_strength": 0.6,
		"roughness_a": 0.85, "peel_amount": 0.1, "peel_color": Color(0.42, 0.39, 0.32)}, "plaster")
	MatLib.define("l7_room_ceiling", {"stain_amount": 0.55, "stain_color": Color(0.6, 0.53, 0.38)}, "plaster")
	MatLib.define("l7_wood", {"albedo_a": Color(0.27, 0.17, 0.1), "albedo_b": Color(0.21, 0.13, 0.08), "pattern_scale": Vector2(0.9, 0.16), "wetness": 0.3}, "wood_floor")
	MatLib.define("l7_fabric", {"albedo_a": Color(0.4, 0.34, 0.2), "albedo_b": Color(0.32, 0.27, 0.15), "noise_scale": 5.0, "bump_strength": 0.25, "stain_amount": 0.45,
		"stain_color": Color(0.22, 0.19, 0.12), "roughness_a": 0.95, "roughness_b": 1.0}, "plaster")
	var bc := [Color(0.28, 0.1, 0.08), Color(0.1, 0.13, 0.2), Color(0.36, 0.3, 0.17), Color(0.13, 0.2, 0.14)]
	for i in 4:
		MatLib.define("l7_book_" + "abcd"[i], {"albedo_a": bc[i], "albedo_b": bc[i] * 0.8, "stain_amount": 0.3, "noise_scale": 3.0, "roughness_a": 0.8}, "plaster")
	MatLib.define("l7_metal", {"albedo_a": Color(0.7, 0.7, 0.68), "albedo_b": Color(0.6, 0.6, 0.58), "metallic_value": 0.3}, "metal")
	MatLib.register("l7_panel", MatLib.panel(Color(1.0, 0.95, 0.84), 2.8))
	MatLib.define("l7_concrete6", {"albedo_a": Color(0.2, 0.2, 0.2), "albedo_b": Color(0.16, 0.16, 0.16), "roughness_a": 0.5, "bump_strength": 0.2}, "concrete")
	MatLib.define("l7_dark", {"albedo_a": Color(0.02, 0.02, 0.02), "albedo_b": Color(0.0, 0.0, 0.0)}, "void_black")
	MatLib.define("l7_ceiling", {"albedo_a": Color(0.44, 0.45, 0.44), "albedo_b": Color(0.33, 0.34, 0.33), "noise_scale": 0.05, "stain_amount": 0.75,
		"stain_color": Color(0.22, 0.24, 0.23), "stain_scale": 0.035, "wetness": 0.55, "bump_strength": 0.5}, "concrete")
	MatLib.register("l7_sea", Geo.ocean_material())
	MatLib.register("l7_puddle", MatLib.water({"shallow_color": Color(0.85, 0.85, 0.8), "deep_color": Color(0.3, 0.3, 0.26), "absorption": 3.0,
		"clarity": 0.92, "wave_height": 0.001, "wave_scale": 2.0, "foam_amount": 0.0, "normal_strength": 0.08, "roughness_value": 0.03}))
	MatLib.register("l7_sidesea", Geo.sideways_sea_material())
	MatLib.define("l7_rock", {"albedo_a": Color(0.34, 0.35, 0.33), "albedo_b": Color(0.2, 0.21, 0.2), "pattern_color": Color(0.42, 0.42, 0.39),
		"noise_scale": 0.12, "bump_strength": 2.6, "wetness": 0.0, "stain_amount": 0.4, "stain_color": Color(0.08, 0.1, 0.1)}, "rock")
	MatLib.define("l7_isle", {"albedo_a": Color(0.2, 0.18, 0.2), "albedo_b": Color(0.13, 0.12, 0.14), "pattern_color": Color(0.34, 0.3, 0.27),
		"pattern_strength": 0.7, "noise_scale": 0.35, "wetness": 0.6}, "rock")
	MatLib.define("l7_stone", {"albedo_a": Color(0.42, 0.42, 0.4), "albedo_b": Color(0.34, 0.34, 0.32), "pattern": 4, "pattern_scale": Vector2(1.7, 0.85),
		"grout_width": 0.03, "grout_color": Color(0.2, 0.21, 0.2), "stain_amount": 0.5, "stain_color": Color(0.16, 0.2, 0.19)}, "concrete")
	MatLib.define("l7_pipe", {"albedo_a": Color(0.3, 0.16, 0.09), "albedo_b": Color(0.18, 0.1, 0.06)}, "rust")
	MatLib.define("l7_door", {"albedo_a": Color(0.24, 0.17, 0.1), "albedo_b": Color(0.18, 0.12, 0.07), "pattern_scale": Vector2(1.7, 0.18), "wetness": 0.7}, "wood_floor")
	MatLib.define("l7_bone", {"albedo_a": Color(0.86, 0.82, 0.72), "albedo_b": Color(0.74, 0.7, 0.6), "stain_amount": 0.35, "stain_color": Color(0.4, 0.38, 0.3),
		"noise_scale": 4.0, "roughness_a": 0.75, "bump_strength": 0.8}, "plaster")
	MatLib.define("l7_abyss_carpet", {"albedo_a": Color(0.13, 0.12, 0.11), "albedo_b": Color(0.08, 0.075, 0.07), "wetness": 1.0}, "l0_carpet")
	MatLib.define("l7_tar", {"albedo_a": Color(0.07, 0.05, 0.035), "albedo_b": Color(0.03, 0.022, 0.016), "roughness_a": 0.08, "roughness_b": 0.25,
		"bump_strength": 1.2, "noise_scale": 0.3}, "concrete")
	MatLib.define("l7_rope", {"albedo_a": Color(0.6, 0.52, 0.36), "albedo_b": Color(0.5, 0.42, 0.28), "noise_scale": 6.0}, "plaster")


static func bubbles(at: Vector3) -> CPUParticles3D:
	var b := CPUParticles3D.new()
	b.position = at
	b.amount = 90
	b.lifetime = 9.0
	b.preprocess = 9.0
	b.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	b.emission_sphere_radius = 0.6
	b.direction = Vector3.UP
	b.spread = 6.0
	b.gravity = Vector3(0, 0.35, 0)
	b.initial_velocity_min = 0.6
	b.initial_velocity_max = 1.3
	b.scale_amount_min = 0.5
	b.scale_amount_max = 1.6
	var sp := SphereMesh.new()
	sp.radius = 0.05
	sp.height = 0.1
	sp.radial_segments = 6
	sp.rings = 3
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.8, 0.86, 0.88)
	m.roughness = 0.1
	m.metallic_specular = 0.9
	sp.material = m
	b.mesh = sp
	return b


static func seamount(lv, geo: Geo, sd: int) -> void:
	var node := Node3D.new()
	node.name = "Seamount"
	lv.add_child(node)
	Geo.commit(node, geo.seamount(), "l7_rock", true)
	# cave outcrop on the east ridge, toward the bottom of the Midnight Zone
	var rm := geo.ridge_r_at(Geo.SEA - 470.0)
	var e := Vector3(Geo.AX + rm, Geo.SEA - 470.0, Geo.AZ)
	var gn := FastNoiseLite.new()
	gn.seed = 708
	gn.frequency = 0.09
	var g := Geo.Grid.new(e + Vector3(-14, -16, -42), 1.25, Vector3(46, 44, 70), -10.0, gn)
	g.solid_ellipsoid(e + Vector3(9, 3, -9), Vector3(15, 15, 27), 2.4)
	g.solid_ellipsoid(e + Vector3(2, -6, -6), Vector3(12, 12, 20), 2.0)
	var t0 := e + Vector3(27, 2.5, 0)
	var t1 := e + Vector3(11, 1.5, 0)
	var t2 := e + Vector3(9, 0.5, -16)
	var t3 := e + Vector3(10, 0.0, -31)
	g.air_capsule(t0, t1, 5.0, 3.6, 1.0)
	g.air_capsule(t1, t2, 3.6, 3.3, 1.0)
	g.air_capsule(t2, t3, 3.3, 1.2, 0.8)
	var a := Geo.Acc.new()
	g.mesh(a)
	Geo.commit(node, a, "l7_rock", true)
	lv.mouth = e + Vector3(22, 2.5, 0)
	var inner := e + Vector3(9.5, 0.6, -20)
	# the cave draws water in: two current volumes ahead of the open sea in tree order
	for cv in [[Vector3(t1.x - 2, e.y - 6, e.z - 6), Vector3(t0.x + 8, e.y + 10, e.z + 6), Vector3(-0.9, 0, 0)],
			[Vector3(t2.x - 6, e.y - 6, t3.z - 2), Vector3(t2.x + 6, e.y + 10, t1.z + 2), Vector3(0, 0, -0.8)]]:
		var w := WaterVolume.new()
		lv.add_child(w)
		lv.move_child(w, 0)
		w.setup(cv[0], cv[1], "l7_sea", false)
		w.current = cv[2]
		w.tint = Color(0.02, 0.04, 0.05)
	lv.sound.emitter("water_bed", lv.mouth, {"bright": 260.0}, -2.0, 70.0)
	lv.sound.emitter("wind", inner, {"seconds": 6.0}, -6.0, 40.0)
	lv.set_meta("cave_inner", inner)
	# scatter by zone: bones, rusted scrap, fibre scraps, skeletons
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = hash([sd, "scatter"])
	var kbs: Array = []
	for sct in 8:
		kbs.append(GeoKit.new(node, "Bones%d" % sct))
	var kr := GeoKit.new(node, "Scrap")
	for i in 260:
		var th := rng2.randf() * TAU
		var kb: GeoKit = kbs[int(th / TAU * 8.0) % 8]
		var r := rng2.randf_range(40.0, 345.0)
		var x := Geo.AX + cos(th) * r
		var z := Geo.AZ + sin(th) * r
		var y := geo.mount_y(x, z)
		if y > Geo.SEA + Geo.Z_DAY:
			continue
		var up := geo.mount_n(x, z)
		var bas := Basis(up.cross(Vector3.FORWARD).normalized(), up, Vector3.ZERO)
		bas.z = bas.x.cross(up).normalized()
		bas = bas.rotated(up, rng2.randf() * TAU)
		var xf := Transform3D(bas, Vector3(x, y + 0.05, z))
		var roll := rng2.randf()
		if y > Geo.SEA + Geo.Z_TWI:
			if roll < 0.35:
				Geo.humanoid(kb, xf, rng2, "l7_bone", rng2.randf_range(1.0, 1.25), 0.3)
			elif roll < 0.5:
				Geo.fish(kb, xf, rng2, "l7_bone", rng2.randf_range(3.0, 7.0))
			elif roll < 0.8:
				kr.box_xf(xf * Transform3D(Basis(), Vector3(0, 0.05, 0)), Vector3(rng2.randf_range(0.6, 2.5), 0.06, rng2.randf_range(0.4, 1.6)), "l7_pipe", GeoKit.ALL, false)
			else:
				kb.box_xf(xf, Vector3(0.05, 0.05, rng2.randf_range(0.3, 0.6)), "l7_bone", GeoKit.ALL, false)
		elif y > Geo.SEA + Geo.Z_MID:
			if roll < 0.6:
				Geo.humanoid(kb, xf, rng2, "l7_bone", rng2.randf_range(1.0, 1.3), 0.15)
			elif roll < 0.7:
				Geo.fish(kb, xf, rng2, "l7_bone", rng2.randf_range(6.0, 12.0))
			elif roll < 0.85:
				kr.box_xf(xf, Vector3(rng2.randf_range(0.4, 1.4), 0.03, rng2.randf_range(0.3, 1.0)), "l7_abyss_carpet", GeoKit.ALL, false)
			elif roll < 0.88:
				Geo.tangle(kb, xf.origin, rng2, "l7_bone", rng2.randf_range(30.0, 45.0))
		else:
			Geo.humanoid(kb, xf, rng2, "l7_bone", rng2.randf_range(1.0, 1.3), 0.55)
	for kb in kbs:
		kb.commit()
	kr.commit()
	# authored Abyss piece at the seamount's east foot: a tar-and-rock mountain,
	# eroded skeletons on the carpeted floor, a steady bubbling from below
	var ap := Vector3(Geo.AX + 400.0, Geo.FLOOR, Geo.AZ + 30.0)
	var at := Geo.Acc.new()
	geo.blob(at, ap, Vector3(26, 44, 22), 0.38, 1.7, 11.0, 14, 22, Geo.FLOOR - 0.5)
	geo.blob(at, ap + Vector3(-30, 0, -26), Vector3(16, 22, 15), 0.4, 2.1, 23.0, 10, 16, Geo.FLOOR - 0.5)
	Geo.commit(node, at, "l7_tar", true)
	var ar := Geo.Acc.new()
	geo.blob(ar, ap + Vector3(18, 0, 30), Vector3(14, 26, 12), 0.45, 2.4, 31.0, 10, 16, Geo.FLOOR - 0.5)
	Geo.commit(node, ar, "l7_rock", true)
	var ka := GeoKit.new(node, "AbyssSkeletons")
	for i in 22:
		var bp := ap + Vector3(rng2.randf_range(-60, -24), 0.03, rng2.randf_range(-40, 40))
		Geo.humanoid(ka, Transform3D(Basis(Vector3.UP, rng2.randf() * TAU), bp), rng2, "l7_bone", rng2.randf_range(1.0, 1.3), 0.5)
	ka.commit()
	lv.sound.emitter("water_bed", ap + Vector3(-28, 3, 0), {"bright": 200.0}, 0.0, 90.0)
	for bv in [ap + Vector3(-44, 0, -8), ap + Vector3(-38, 0, 14), ap + Vector3(-52, 0, -26)]:
		node.add_child(bubbles(bv))
	lv.set_meta("abyss_piece", ap)


static func ring(lv, geo: Geo) -> void:
	var node := Node3D.new()
	node.name = "Ring"
	lv.add_child(node)
	var k := GeoKit.new(node, "RingStone")
	var gy := geo.mount_y(Geo.RING.x, Geo.RING.z)
	var top := Geo.RING.y
	k.cylinder(Vector3(Geo.RING.x, top - 0.8, Geo.RING.z), 6.5, 1.6, "l7_stone", 24)
	k.cylinder(Vector3(Geo.RING.x, (top - 1.6 + gy) * 0.5, Geo.RING.z), 2.4, top - 1.6 - gy, "l7_stone", 12)
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 909
	for i in 12:
		var a := TAU * i / 12.0
		var p := Vector3(Geo.RING.x + cos(a) * 17.0, 0, Geo.RING.z + sin(a) * 17.0)
		var g := geo.mount_y(p.x, p.z)
		if i % 3 == 1:
			var ptop := top + rng2.randf_range(6.0, 14.0)
			k.cylinder(Vector3(p.x, (ptop + g) * 0.5, p.z), 2.1, ptop - g, "l7_pipe", 14)
			k.cylinder(Vector3(p.x, ptop - 0.06, p.z), 1.85, 0.1, "l7_dark", 14, false)
			for f in 4:
				k.cylinder(Vector3(p.x, ptop - 3.0 - f * 9.0, p.z), 2.45, 0.5, "l7_pipe", 14, false)
			var dir := Vector3(-cos(a), 0, -sin(a))
			lv.add_interactable(Vector3(p.x, top + 1.0, p.z) + dir * 2.0, Vector3(2.2, 2.4, 2.2), "Strike the rusted pipe (loud)", Callable(lv, "_strike_pipe").bind(Vector3(p.x, top + 1.0, p.z)))
		else:
			var ptop2 := top + rng2.randf_range(4.0, 16.0)
			k.cylinder(Vector3(p.x, (ptop2 + g) * 0.5, p.z), 1.6, ptop2 - g, "l7_stone", 12)
	# the wooden door set into the platform floor
	var kd := GeoKit.new(node, "Door")
	for i in 6:
		kd.box(Vector3(Geo.RING.x - 0.55 + i * 0.22, top + 0.03, Geo.RING.z), Vector3(0.2, 0.06, 1.7), "l7_door")
	for s in [-0.55, 0.55]:
		kd.box(Vector3(Geo.RING.x, top + 0.07, Geo.RING.z + s), Vector3(1.4, 0.03, 0.09), "l7_pipe", GeoKit.ALL, false)
	kd.cylinder(Vector3(Geo.RING.x + 0.4, top + 0.09, Geo.RING.z), 0.12, 0.03, "l7_pipe", 10, false)
	kd.commit()
	k.commit()
	# Tiny's home: a high quantity of skeletons and loose bone
	var kb := GeoKit.new(node, "RingBones")
	for i in 26:
		var a := rng2.randf() * TAU
		var r := rng2.randf_range(2.0, 6.0) if i < 9 else rng2.randf_range(7.0, 30.0)
		var x := Geo.RING.x + cos(a) * r
		var z := Geo.RING.z + sin(a) * r
		var y := top if r < 6.3 else geo.mount_y(x, z)
		var xf := Transform3D(Basis(Vector3.UP, rng2.randf() * TAU), Vector3(x, y + 0.02, z))
		if rng2.randf() < 0.6:
			Geo.humanoid(kb, xf, rng2, "l7_bone", rng2.randf_range(1.0, 1.2), 0.25)
		else:
			for j in 8:
				kb.box_xf(xf * Transform3D(Basis(Vector3.UP, rng2.randf() * TAU), Vector3(rng2.randf_range(-1, 1), 0.03, rng2.randf_range(-1, 1))), Vector3(0.05, 0.05, rng2.randf_range(0.2, 0.5)), "l7_bone", GeoKit.ALL, false)
	kb.commit()
	lv.sound.emitter("creak", Geo.RING + Vector3(0, -6, 0), {"freq": 48.0}, -60.0, 120.0)


static func fort(lv, geo: Geo) -> void:
	# Fort Surrender: closest recorded island; furniture shelter held with tar
	var node := Node3D.new()
	node.name = "FortSurrender"
	lv.add_child(node)
	var a := Geo.Acc.new()
	geo.blob(a, Geo.FORT + Vector3(0, -7.0, 0), Vector3(30, 9.5, 22), 0.25, 1.6, 3.0, 16, 26)
	Geo.commit(node, a, "l7_isle", true)
	var k := GeoKit.new(node, "Shelter")
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 2020
	var c := Vector3(Geo.FORT.x, geo.blob_pole_y(Geo.FORT + Vector3(0, -7.0, 0), 9.5, 0.25, 1.6, 3.0), Geo.FORT.z)
	for i in 9:
		var ang := TAU * i / 9.0
		var p := c + Vector3(cos(ang) * 2.0, 0.9, sin(ang) * 2.0)
		var lean := Basis(Vector3(-sin(ang), 0, cos(ang)), 0.32)
		k.box_xf(Transform3D(lean * Basis(Vector3.UP, ang + rng2.randf_range(-0.2, 0.2)), p), Vector3(rng2.randf_range(0.6, 1.1), rng2.randf_range(1.6, 2.2), 0.05), "l7_door")
		k.box_xf(Transform3D(lean, p + Vector3(0, rng2.randf_range(-0.4, 0.5), 0)), Vector3(0.35, 0.25, 0.3), "l7_tar", GeoKit.ALL, false)
	k.box(c + Vector3(1.5, 0.2, 1.2), Vector3(0.45, 0.45, 0.45), "l7_wood")
	k.box(c + Vector3(-1.0, 0.3, -2.8), Vector3(1.6, 0.06, 0.8), "l7_wood")
	k.commit()


static func h01(sd: int, a: int, b: int, salt: int) -> float:
	return float(absi(hash([sd, a, b, salt])) % 100003) / 100003.0


static func build_chunk(_lv, geo: Geo, sd: int, cx: int, cz: int, _version: int, node: Node3D) -> Dictionary:
	var k := GeoKit.new(node, "K")
	var ox := cx * Geo.CS
	var oz := cz * Geo.CS
	var o := Vector3(ox, 0, oz)
	var meta := {"kind": "sea"}
	var hc := Vector2i(floori(Geo.DOOR.x / Geo.CS), floori(Geo.DOOR.z / Geo.CS))
	if Vector2i(cx, cz) == hc:
		var hx0 := Geo.DOOR.x - 1.025
		var hx1 := Geo.DOOR.x + 1.025
		var hz0 := Geo.DOOR.z - 0.45
		var hz1 := Geo.DOOR.z + 0.45
		var c0 := Geo.SEA + 4.5
		var c1 := Geo.SEA + 4.8
		k.box_mm(Vector3(ox, c0, oz), Vector3(hx0, c1, oz + Geo.CS), "l7_ceiling")
		k.box_mm(Vector3(hx1, c0, oz), Vector3(ox + Geo.CS, c1, oz + Geo.CS), "l7_ceiling")
		k.box_mm(Vector3(hx0, c0, oz), Vector3(hx1, c1, hz0), "l7_ceiling")
		k.box_mm(Vector3(hx0, c0, hz1), Vector3(hx1, c1, oz + Geo.CS), "l7_ceiling")
		meta["kind"] = "hatch"
	else:
		k.box_mm(Vector3(ox, Geo.SEA + 4.5, oz), Vector3(ox + Geo.CS, Geo.SEA + 4.8, oz + Geo.CS), "l7_ceiling", GeoKit.NY)
	k.box_mm(Vector3(ox, Geo.FLOOR - 1.0, oz), Vector3(ox + Geo.CS, Geo.FLOOR, oz + Geo.CS), "l7_abyss_carpet", GeoKit.PY)
	var r := RandomNumberGenerator.new()
	r.seed = hash([sd, cx, cz])
	var d := maxi(absi(cx), absi(cz))
	if d >= 2 and h01(sd, cx, cz, 3) < 0.14 and o.distance_to(Geo.FORT) > 260.0:
		var a := Geo.Acc.new()
		var c := o + Vector3(r.randf_range(30, 120), Geo.SEA - 6.0, r.randf_range(30, 120))
		geo.blob(a, c, Vector3(r.randf_range(14, 34), r.randf_range(7.5, 9.0), r.randf_range(12, 30)), 0.3, 1.4, r.randf() * 50.0, 12, 20)
		Geo.commit(node, a, "l7_isle", true)
		meta["island"] = c
	# the abyss: mountainous piles of tar and rock, eroded skeletons, bubbling
	var piles := 1 + r.randi() % 2
	var kb := GeoKit.new(node, "AbyssBones")
	for i in piles:
		var pc := o + Vector3(r.randf_range(15, 135), Geo.FLOOR, r.randf_range(15, 135))
		if Vector2(pc.x - Geo.AX, pc.z - Geo.AZ).length() < 330.0:
			continue
		var hgt := r.randf_range(12.0, 45.0)
		var rad := r.randf_range(10.0, 26.0)
		var a := Geo.Acc.new()
		geo.blob(a, pc, Vector3(rad, hgt, rad * r.randf_range(0.7, 1.2)), 0.35, 1.8, r.randf() * 40.0, 10, 16, Geo.FLOOR - 0.5)
		Geo.commit(node, a, "l7_tar" if r.randf() < 0.55 else "l7_rock", false)
		k.add_box_shape(Transform3D(Basis(), pc + Vector3(0, hgt * 0.35, 0)), Vector3(rad * 1.2, hgt * 0.7, rad * 1.1), "concrete")
		var bub := AudioStreamPlayer3D.new()
		bub.stream = AudioSynth.get_stream("water_bed", {"bright": 220.0})
		bub.max_distance = 80.0
		bub.volume_db = -2.0
		bub.bus = "Ambience"
		bub.autoplay = true
		bub.position = pc + Vector3(rad, 2, 0)
		node.add_child(bub)
		for j in 2:
			var bx := pc + Vector3(r.randf_range(-rad * 1.6, rad * 1.6), 0.02, r.randf_range(-rad * 1.6, rad * 1.6))
			Geo.humanoid(kb, Transform3D(Basis(Vector3.UP, r.randf() * TAU), bx), r, "l7_bone", r.randf_range(1.0, 1.3), 0.6)
	kb.commit()
	k.commit()
	return meta
