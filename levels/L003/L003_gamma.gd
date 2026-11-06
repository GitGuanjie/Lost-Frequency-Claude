extends RefCounted
## Base Gamma: largest area, ceiling hundreds of feet up, sunlike lamps, cameras,
## blood check, a non-Entity-81 lift and the Level 11 door (page). ADAPTATION: a
## finite hazy hall; the fortress is massing; only the gatehouse is walkable.

const U := Vector3(0, 1, 0)
const K := preload("res://levels/L003/L003_kit.gd")


static func _rail_slope(k: GeoKit, a: Vector3, b: Vector3) -> void:
	K.pipe(k, a + U * 1.0, b + U * 1.0, 0.025, "l3_rail", 6)
	K.pipe(k, a + U * 0.5, b + U * 0.5, 0.02, "l3_rail", 6)
	var z := (b - a).normalized()
	var x := U.cross(z).normalized()
	var y := z.cross(x).normalized()
	k.add_box_shape(Transform3D(Basis(x, y, z), (a + b) * 0.5 + y * 0.55), Vector3(0.06, 1.1, (b - a).length()), "metal")


static func build(lvl, k: GeoKit, r: RandomNumberGenerator) -> void:
	var g: GeoKit = lvl.kit("Gamma")
	var gl: GeoKit = lvl.kit("GammaLights")
	gl.shadows = false
	# ------------------------------------------------------------ the hall
	g.slab(74.0, -260.0, 520.0, 260.0, -5.0, 0.5, "l3_bg_floor")
	g.slab(74.0, -260.0, 520.0, 260.0, 80.5, 0.5, "l3_ceiling")
	g.wall(Vector3(74.0, -5, -260), Vector3(74.0, -5, 260), 85.0, 0.6, "l3_bg_wall", [{"at": 256.0, "w": 2.4, "h": 3.0}, {"at": 266.0, "w": 2.2, "h": 2.4, "sill": 10.0}])
	g.wall(Vector3(520.0, -5, -260), Vector3(520.0, -5, 260), 85.0, 0.6, "l3_bg_wall")
	g.wall(Vector3(74.0, -5, -260), Vector3(520.0, -5, -260), 85.0, 0.6, "l3_bg_wall")
	g.wall(Vector3(74.0, -5, 260), Vector3(520.0, -5, 260), 85.0, 0.6, "l3_bg_wall")
	var z := -250.0
	while z < 250.0:
		if absf(z - 1.0) > 14.0:
			g.box_mm(Vector3(74.3, -5, z - 0.8), Vector3(75.6, 80, z + 0.8), "l3_bg_wall")
			K.pipe(g, Vector3(75.0, -5, z + 1.6), Vector3(75.0, 80, z + 1.6), 0.25, "l3_pipe_black", 8)
			K.pipe(g, Vector3(74.7, -5, z + 2.2), Vector3(74.7, 80, z + 2.2), 0.12, "l3_conduit", 6)
		z += 16.0
	for gx: float in [100.0, 150.0, 200.0, 260.0, 330.0]:
		g.box_mm(Vector3(gx - 1.0, 75.5, -260), Vector3(gx + 1.0, 80.0, 260), "l3_steel", GeoKit.ALL, false)
	for gz: float in [-120.0, -40.0, 40.0, 120.0]:
		g.box_mm(Vector3(74.0, 77.0, gz - 0.6), Vector3(520.0, 80.0, gz + 0.6), "l3_steel", GeoKit.ALL, false)
	# --------------------------------------- viewing gantry and long stair
	K.deck(g, 74.3, 3.0, 79.0, 11.4, 5.0)
	K.railing(g, Vector3(74.3, 5, 3.0), Vector3(79.0, 5, 3.0))
	K.railing(g, Vector3(79.0, 5, 3.0), Vector3(79.0, 5, 11.4))
	K.railing(g, Vector3(74.3, 5, 11.4), Vector3(76.65, 5, 11.4))
	K.railing(g, Vector3(78.35, 5, 11.4), Vector3(79.0, 5, 11.4))
	g.stairs(Vector3(77.5, -5, 26.5), Vector3(0, 0, -1), 1.6, 10.0, 56, "l3_grate", 0.27, false)
	_rail_slope(g, Vector3(76.68, -5, 26.5), Vector3(76.68, 5, 11.38))
	_rail_slope(g, Vector3(78.32, -5, 26.5), Vector3(78.32, 5, 11.38))
	for p: Vector3 in [Vector3(74.6, 0, 3.2), Vector3(78.8, 0, 3.2), Vector3(78.8, 0, 11.2), Vector3(74.6, 0, 11.2)]:
		g.box(Vector3(p.x, -0.03, p.z), Vector3(0.3, 9.94, 0.3), "l3_steel")
	for zz: float in [16.0, 21.0]:
		var top: float = -5.0 + 10.0 * (26.5 - zz) / 15.12 - 0.2
		for xx: float in [76.8, 78.2]:
			g.box(Vector3(xx, (-5.0 + top) * 0.5, zz), Vector3(0.18, top + 5.0, 0.18), "l3_steel")
	lvl.lamp(g, Vector3(76.5, 7.8, 7.0), Vector3(0, 0, 1), 0.0, "warm", 8.0)
	g.box_mm(Vector3(74.3, 7.6, 3.0), Vector3(79.0, 7.8, 11.4), "l3_steel", GeoKit.ALL, false)
	K.sign(g, "M.E.G.  —  BASE GAMMA\nall wanderers welcome\nsecurity check at the gate", Vector3(74.32, 8.1, 6.0), Vector3(1, 0, 0), 1.2, 0.5)
	# -------------------------------------------- perimeter (100 m radius)
	for i in 6:
		for s: float in [-1.0, 1.0]:
			var bx := 83.0 + i * 2.9
			g.box(Vector3(bx, -4.6, 3.6 * s), Vector3(2.6, 0.8, 0.55), "l3_ebox_grey")
	for p: Vector3 in [Vector3(86, -5, -9), Vector3(86, -5, 10), Vector3(95, -5, -15), Vector3(95, -5, 15), Vector3(81, -5, -24), Vector3(82, -5, 34)]:
		g.cylinder(p + U * 3.2, 0.09, 6.4, "l3_steel", 8)
		lvl.sys.add_camera(p + U * 6.2)
	for p: Vector3 in [Vector3(90, -5, -18), Vector3(90, -5, 18)]:
		g.cylinder(p + U * 4.5, 0.14, 9.0, "l3_steel", 8)
		g.box(p + Vector3(0.3, 9.1, 0), Vector3(0.6, 0.5, 1.2), "l3_fixture", GeoKit.ALL, false)
		gl.quad(p + Vector3(0.61, 9.1, 0), Vector3(1, 0, 0), Vector3(0, 0, 0.55), Vector3(0, 0.22, 0), "l3_sun")
		lvl.lights.add_anchor(p + Vector3(2.5, 7.5, 0), Color("ffebbf"), 2.2, 22.0)
	# --------------------------------------------- sun lamps on lattice masts
	for mz: float in [-26.0, 26.0, -80.0, 80.0]:
		var m := Vector3(106.0, -5, mz)
		for c: Vector3 in [Vector3(-0.8, 0, -0.8), Vector3(0.8, 0, -0.8), Vector3(0.8, 0, 0.8), Vector3(-0.8, 0, 0.8)]:
			K.pipe(g, m + c, m + c * 0.4 + U * 27.0, 0.11, "l3_steel", 6)
		var y := 2.0
		while y < 25.0:
			K.pipe(g, m + Vector3(-0.8 + y * 0.011, y, 0), m + Vector3(0.8 - y * 0.011, y + 3.0, 0), 0.04, "l3_steel", 4)
			y += 3.0
		g.box(m + Vector3(-0.6, 27.5, 0), Vector3(0.8, 3.4, 5.2), "l3_steel", GeoKit.ALL, false)
		for iy in 2:
			for iz in 3:
				gl.quad(m + Vector3(-1.02, 26.7 + iy * 1.6, -1.6 + iz * 1.6), Vector3(-1, 0, 0), Vector3(0, 0, 0.66), Vector3(0, 0.66, 0), "l3_sun")
	for mz: float in [-26.0, 26.0]:
		var sp := SpotLight3D.new()
		sp.position = Vector3(104.0, 26.0, mz)
		sp.light_color = Color("ffedcc")
		sp.light_energy = 4.5
		sp.spot_range = 90.0
		sp.spot_angle = 38.0
		sp.spot_attenuation = 0.6
		lvl.add_child(sp)
		sp.look_at(Vector3(92.0, -5.0, mz * 0.25))
	for p: Vector3 in [Vector3(102.0, 24.0, -80.0), Vector3(102.0, 24.0, 80.0), Vector3(126.0, 30.0, 0.0)]:
		var om := OmniLight3D.new()
		om.position = p
		om.light_color = Color("ffe6bd")
		om.light_energy = 3.0
		om.omni_range = 70.0
		om.omni_attenuation = 0.8
		lvl.add_child(om)
	for cx: float in [150.0, 210.0]:
		for cz: float in [-50.0, 0.0, 50.0]:
			gl.quad(Vector3(cx, 79.9, cz), Vector3.DOWN, Vector3(9, 0, 0), Vector3(0, 0, 9), "l3_sun_dim")
	_fortress(lvl, g, gl, r)
	_gatehouse(lvl, g, gl, r)
	g.commit()
	gl.commit()
	lvl.zones.append({"name": "gamma", "box": AABB(Vector3(74, -6, -260), Vector3(446, 90, 520))})


static func _windows(gl: GeoKit, r: RandomNumberGenerator, x: float, z0: float, z1: float, y: float, w: float, h: float, step: float, skip: Vector2, mats: Array) -> void:
	var zz := z0
	while zz + w <= z1:
		var c := zz + w * 0.5
		if c < skip.x or c > skip.y:
			var pick: float = r.randf()
			var mat: String = str(mats[mats.size() - 1][0])
			for m in mats:
				if pick < float(m[1]):
					mat = str(m[0])
					break
				pick -= float(m[1])
			gl.quad(Vector3(x, y + h * 0.5, c), Vector3(-1, 0, 0), Vector3(0, 0, w * 0.5), Vector3(0, h * 0.5, 0), mat, Vector2(r.randf() * 50.0, 0.0), true)
		zz += step


static func _fortress(lvl, g: GeoKit, gl: GeoKit, r: RandomNumberGenerator) -> void:
	# Public Sector: four mall floors
	g.box_mm(Vector3(118, -5, -95), Vector3(270, 17, 95), "l3_facade")
	var shop := [["l3_win_shop", 0.35], ["l3_win_warm", 0.3], ["l3_glass_dark", 0.35]]
	for f in 4:
		var y0 := -5.0 + f * 5.5
		g.box_mm(Vector3(117.4, y0 + 4.6, -95.5), Vector3(118.0, y0 + 5.5, 95.5), "l3_facade", GeoKit.ALL, false)
		var skip := Vector2(-14.0, 14.0) if f < 2 else Vector2(1000, 1000)
		_windows(gl, r, 117.38, -94.0, 94.0, y0 + 0.9, 5.6, 3.3, 6.4, skip, shop)
		for zz in range(-94, 95, 6):
			if f >= 2 or absi(zz) > 14:
				g.box_mm(Vector3(117.3, y0 + 0.7, zz - 0.2), Vector3(117.4, y0 + 4.4, zz + 0.2), "l3_steel", GeoKit.ALL, false)
		for zz in range(-90, 91, 13):
			if f >= 2 or absi(zz) > 15:
				g.box_mm(Vector3(116.7, y0, zz - 0.45), Vector3(118.0, y0 + 5.5, zz + 0.45), "l3_facade", GeoKit.ALL, false)
	# grand atrium entrance (closed) with the base's name above it
	g.box_mm(Vector3(112.0, 6.4, -54.0), Vector3(118.0, 7.0, -36.0), "l3_steel")
	gl.quad(Vector3(117.36, 0.6, -45.0), Vector3(-1, 0, 0), Vector3(0, 0, 7.5), Vector3(0, 5.6, 0), "l3_win_shop")
	for zz: float in [-52.5, -48.0, -42.0, -37.5]:
		g.box_mm(Vector3(117.0, -5, zz - 0.15), Vector3(117.36, 6.4, zz + 0.15), "l3_steel", GeoKit.ALL, false)
	g.box_mm(Vector3(116.5, 11.2, -60.0), Vector3(117.2, 16.4, -30.0), "l3_bars")
	K.label(g.root, "BASE  GAMMA", Vector3(116.48, 14.4, -45.0), Vector3(-1, 0, 0), 220, Color("fff2d1"), 0.026)
	K.label(g.root, "M.E.G.  ·  ALL WANDERERS WELCOME", Vector3(116.48, 12.0, -45.0), Vector3(-1, 0, 0), 72, Color("f2d999"), 0.026)
	# shop and service signs over the mall fronts
	for i in 26:
		var sz := r.randf_range(-92.0, 92.0)
		if absf(sz) < 16.0 or (sz > -62.0 and sz < -28.0):
			continue
		var fy := -5.0 + float(r.randi() % 3) * 5.5 + 4.05
		gl.quad(Vector3(117.28, fy, sz), Vector3(-1, 0, 0), Vector3(0, 0, r.randf_range(1.2, 2.6)), Vector3(0, 0.22, 0), ["l3_sign_red", "l3_sign_blue", "l3_sign_green", "l3_win_shop"][r.randi() % 4])
	# Residence Sector (hotel-style rooms) and Administration above
	g.box_mm(Vector3(132, 17, -82), Vector3(262, 33, 82), "l3_facade")
	g.box_mm(Vector3(117.6, 17, -95), Vector3(118.4, 18.1, 95), "l3_facade", GeoKit.ALL, false)
	var rooms := [["l3_win_warm", 0.45], ["l3_win_cool", 0.1], ["l3_glass_dark", 0.45]]
	for f in 4:
		_windows(gl, r, 131.98, -81.0, 81.0, 17.8 + f * 3.8, 1.4, 1.7, 3.2, Vector2(1000, 1000), rooms)
	g.box_mm(Vector3(150, 33, -45), Vector3(240, 47, 45), "l3_facade")
	for f in 3:
		_windows(gl, r, 149.98, -44.0, 44.0, 34.4 + f * 4.4, 5.0, 2.2, 5.6, Vector2(1000, 1000), [["l3_win_cool", 0.75], ["l3_glass_dark", 0.25]])
	for p: Vector3 in [Vector3(160, 47, -30), Vector3(175, 47, 20), Vector3(200, 47, -10), Vector3(225, 47, 30)]:
		K.pipe(g, p, p + U * 16.0, 0.25, "l3_steel", 6)
		gl.quad(p + Vector3(-0.3, 16.2, 0), Vector3(-1, 0, 0), Vector3(0, 0, 0.3), Vector3(0, 0.3, 0), "l3_red_led")
	g.cylinder(Vector3(190, 49.0, 0), 3.0, 0.4, "l3_steel", 16, false)


static func _gatehouse(lvl, g: GeoKit, gl: GeoKit, r: RandomNumberGenerator) -> void:
	var B := "l3_makeshift"
	# shell: makeshift brick walls, wood upper boarding, roof
	g.slab(100.0, -12.0, 118.0, 12.0, -4.97, 0.03, "l3_floor")
	g.slab(99.7, -12.3, 118.0, 12.3, 3.8, 0.3, "l3_ceiling")
	g.box_mm(Vector3(99.7, 3.8, -12.3), Vector3(118.0, 4.5, -12.0), "l3_facade")
	g.box_mm(Vector3(99.7, 3.8, 12.0), Vector3(118.0, 4.5, 12.3), "l3_facade")
	g.box_mm(Vector3(99.7, 3.8, -12.0), Vector3(100.0, 4.5, 12.0), "l3_facade")
	for p: Vector3 in [Vector3(104.0, 3.8, -7.0), Vector3(108.0, 3.8, -7.5), Vector3(112.5, 3.8, 6.0)]:
		g.box(p + Vector3(0, 0.6, 0), Vector3(2.2, 1.2, 1.6), "l3_ebox_grey", GeoKit.ALL, false)
		g.box(p + Vector3(0, 1.22, 0), Vector3(1.0, 0.04, 1.0), "l3_louvre", GeoKit.ALL, false)
	K.pipe(g, Vector3(115.0, 3.8, 9.0), Vector3(115.0, 12.0, 9.0), 0.08, "l3_steel", 6)
	gl.quad(Vector3(114.85, 12.1, 9.0), Vector3(-1, 0, 0), Vector3(0, 0, 0.12), Vector3(0, 0.12, 0), "l3_red_led")
	g.wall(Vector3(100.0, -5, -12.3), Vector3(100.0, -5, 12.3), 8.5, 0.3, B, [{"at": 12.3, "w": 2.2, "h": 2.4}])
	g.wall(Vector3(99.85, -5, -12.0), Vector3(118.0, -5, -12.0), 8.5, 0.3, B, [{"at": 10.15, "w": 2.0, "h": 2.3}])
	g.wall(Vector3(99.85, -5, 12.0), Vector3(118.0, -5, 12.0), 8.5, 0.3, B)
	g.box_mm(Vector3(99.75, 0.3, -12.3), Vector3(99.85, 3.5, 12.3), "l3_wood", GeoKit.ALL, false)
	K.label(g.root, "INTAKE  ·  TRANSFER", Vector3(99.74, -1.6, 0.0), Vector3(-1, 0, 0), 120, Color("1f1a14"), 0.008)
	g.box_mm(Vector3(98.8, -2.45, -1.8), Vector3(99.85, -2.3, 1.8), "l3_steel", GeoKit.ALL, false)
	gl.quad(Vector3(99.3, -2.47, 0.0), Vector3.DOWN, Vector3(0.4, 0, 0), Vector3(0, 0, 1.4), "l3_tube")
	lvl.lights.add_anchor(Vector3(99.0, -3.0, 0.0), Color("ffebc7"), 1.4, 8.0)
	# vestibule: metal detector arch, finger-prick hatch, sliding gate
	for s: float in [-2.5, 2.5]:
		g.wall(Vector3(100.0, -5, s), Vector3(105.0, -5, s), 8.5, 0.3, B)
	g.slab(100.15, -2.35, 105.0, 2.35, -2.0, 0.2, "l3_ceiling")
	g.wall(Vector3(105.0, -5, -12.0), Vector3(105.0, -5, 12.0), 8.5, 0.3, B, [{"at": 12.0, "w": 1.6, "h": 2.4}])
	for s: float in [-0.7, 0.7]:
		g.box(Vector3(102.4, -3.9, s), Vector3(0.3, 2.2, 0.16), "l3_ebox_grey")
	g.box(Vector3(102.4, -2.7, 0.0), Vector3(0.3, 0.2, 1.56), "l3_ebox_grey", GeoKit.ALL, false)
	g.box(Vector3(103.4, -3.6, -2.33), Vector3(0.5, 0.4, 0.04), "l3_steel", GeoKit.ALL, false)
	g.box(Vector3(103.4, -2.4, -2.34), Vector3(1.4, 0.7, 0.02), "l3_glass_dark", GeoKit.ALL, false)
	lvl.add_interactable(Vector3(103.4, -3.6, -2.2), Vector3(0.6, 0.5, 0.3), "Put your finger in the hatch", lvl.sys.blood_check)
	lvl.add_note("L003_intake", "M.E.G. intake notice",
		"[b]BASE GAMMA — WANDERER INTAKE[/b]\n\nEveryone is welcome here. Room, board and meals are free.\n\n1. Hold out a finger at the hatch. We check the colour of your blood.\n2. Walk through the arch. No weapons inside the base; anything you carry will be taken and logged.\n3. New arrivals are scanned for a biometric profile (retina, prints, face).\n\nThe door on the east wall goes straight back to our entry point on Level 11.\nThe service lift has been checked: it is not Entity 81. It goes to Level 4 or Level 5, and nobody can tell you which.",
		Vector3(101.6, -3.4, 2.33), Vector3(0.6, 0.6, 0.2), false)
	K.sign(g, "M.E.G. INTAKE\nread before you enter", Vector3(101.6, -3.4, 2.34), Vector3(0, 0, -1), 0.55, 0.42, "l3_sign_white", Color("141a4c"), 30)
	lvl.sys.make_gate(Vector3(105.0, -5.0, 0.0))
	# transfer hall: lift, the Level 11 door, the outpost mezzanine
	g.wall(Vector3(118.0, -5, -12.0), Vector3(118.0, -5, 12.0), 8.5, 0.3, B, [{"at": 7.0, "w": 1.4, "h": 2.3}])
	g.box(Vector3(117.92, -3.85, -5.0), Vector3(0.12, 2.3, 1.4), "l3_door")
	g.box(Vector3(117.8, -3.9, -4.5), Vector3(0.1, 0.06, 0.06), "l3_steel", GeoKit.ALL, false)
	K.sign(g, "L-11 TRANSFER\nBase Gamma entry point\nguarded — keep this door clear", Vector3(117.84, -1.9, -5.0), Vector3(-1, 0, 0), 1.2, 0.55, "l3_sign_yellow")
	lvl.add_exit("L003>L011#3", "interact", Vector3(117.3, -4.0, -5.0), Vector3(1.2, 2.0, 1.8), "Open the transfer door")
	for p: Vector3 in [Vector3(113.0, -5, -10.0), Vector3(115.4, -5, -10.2), Vector3(113.3, -5, -0.8), Vector3(114.2, -5, 1.4)]:
		g.box(p + Vector3(0, 0.07, 0), Vector3(1.2, 0.14, 1.0), "l3_crate")
		K.crate(g, p + Vector3(0, 0.14, 0), Vector3(1.0, 0.8 + r.randf() * 0.6, 0.9), r.randf_range(-0.1, 0.1), "l3_crate" if r.randf() < 0.6 else "l3_cardboard")
	# lift car (checked: not Entity 81)
	g.slab(108.4, -15.6, 111.6, -12.15, -4.97, 0.03, "l3_lift")
	g.slab(108.4, -15.6, 111.6, -12.15, -2.3, 0.2, "l3_lift")
	for x: float in [108.75, 111.25]:
		g.box_mm(Vector3(x - 0.15, -5, -15.6), Vector3(x + 0.15, -2.3, -12.15), "l3_lift")
	g.box_mm(Vector3(108.4, -5, -15.9), Vector3(111.6, -2.3, -15.6), "l3_lift")
	gl.quad(Vector3(110.0, -2.32, -13.9), Vector3.DOWN, Vector3(0.5, 0, 0), Vector3(0, 0, 0.9), "l3_tube")
	lvl.lights.add_anchor(Vector3(110.0, -2.8, -13.9), Color("f2f2e6"), 0.8, 4.0)
	g.box(Vector3(111.08, -3.8, -12.9), Vector3(0.04, 0.4, 0.22), "l3_ebox_grey", GeoKit.ALL, false)
	lvl.add_interactable(Vector3(110.95, -3.8, -12.9), Vector3(0.25, 0.5, 0.35), "Press the lift button", lvl.sys.lift_press)
	lvl.sys.make_lift(Vector3(110.0, -5.0, -12.1))
	var l4: ExitTrigger = lvl.add_exit("L003>L004#1", "condition", Vector3(110.0, -4.0, -13.8), Vector3(1.9, 2.0, 2.6), "")
	var l5: ExitTrigger = lvl.add_exit("L003>L005#2", "condition", Vector3(110.0, -4.0, -13.8), Vector3(1.9, 2.0, 2.6), "")
	l4.condition = func(): return lvl.sys.lift_dest == 4
	l5.condition = func(): return lvl.sys.lift_dest == 5
	K.sign(g, "SERVICE LIFT\nchecked: NOT Entity 81\nLevel 4 or Level 5 — at random", Vector3(112.2, -2.9, -11.84), Vector3(0, 0, 1), 1.05, 0.5, "l3_sign_white", Color("141a4c"), 32)
	# mezzanine with the security outpost (mirrored glass)
	g.slab(105.15, 4.2, 117.85, 11.85, -1.0, 0.3, "l3_grate")
	K.railing(g, Vector3(105.15, -1.0, 4.2), Vector3(116.0, -1.0, 4.2))
	g.stairs(Vector3(116.8, -5, -2.0), Vector3(0, 0, 1), 1.4, 4.0, 22, "l3_grate", 0.28, false)
	_rail_slope(g, Vector3(116.08, -5, -2.0), Vector3(116.08, -1.0, 4.16))
	for x: float in [108.0, 112.0]:
		g.box(Vector3(x, -3.0, 4.4), Vector3(0.25, 4.0, 0.25), "l3_steel")
	g.wall(Vector3(106.0, -1.0, 6.5), Vector3(115.0, -1.0, 6.5), 2.8, 0.2, "l3_wood", [{"at": 4.5, "w": 7.0, "h": 1.3, "sill": 1.0}])
	g.box(Vector3(110.5, 0.65, 6.5), Vector3(7.0, 1.3, 0.04), "l3_glass_dark", GeoKit.ALL, false)
	for x: float in [106.0, 115.0]:
		g.wall(Vector3(x, -1.0, 6.5), Vector3(x, -1.0, 11.85), 2.8, 0.2, "l3_wood")
	g.slab(106.0, 6.5, 115.0, 11.85, 2.0, 0.15, "l3_wood")
	for lp: Vector3 in [Vector3(108.5, 3.5, -6.0), Vector3(114.0, 3.5, -6.0), Vector3(108.5, 3.5, 1.0), Vector3(111.0, 3.5, 9.0)]:
		lvl.lamp(g, lp, Vector3(1, 0, 0), 1.0, "on", 9.0)
	lvl.zones.append({"name": "transfer", "box": AABB(Vector3(105, -6, -16), Vector3(13, 10, 28))})
