extends RefCounted
## Level 24: the ruined B.N.T.G. Bluehole ("Bluehell"), about a kilometre down the
## road from PlasticWorks. A shaft cut through the paint into plastic dyed blue by
## paint thinner, a caustic pool of paint and thinner at the bottom, the main gantry
## whose pulley failed, Paint Busters' gear, Hot-Shovels, abandoned huts and the
## reports, paraphrased. The dead are not shown.

const T := preload("res://levels/L024/L024_terrain.gd")

var lv
var ter
var k: GeoKit
var rng: RandomNumberGenerator
var props: Node3D
var spots := {}


func _init(level, terrain, r: RandomNumberGenerator, prop_root: Node3D) -> void:
	lv = level
	ter = terrain
	rng = r
	k = level.kit("Bluehole")
	props = prop_root


func g(x: float, z: float) -> float:
	return ter.h(x, z)


func build_all() -> void:
	var c := Vector3(T.BH.x, 0.0, T.BH.y)
	MatLib.register("l24_caustic", MatLib.water({"shallow_color": Color(0.32, 0.36, 0.3), "deep_color": Color(0.12, 0.16, 0.2), "absorption": 0.3,
		"clarity": 0.15, "wave_height": 0.01, "wave_scale": 0.4, "wave_speed": 0.15, "foam_amount": 0.25, "roughness_value": 0.05}))
	var pool := WaterVolume.new()
	pool.name = "CausticPool"
	lv.add_child(pool)
	pool.setup(Vector3(c.x - 9.0, T.BH_FLOOR - 1.0, c.z - 9.0), Vector3(c.x + 9.0, T.POOL_Y, c.z + 9.0), "l24_caustic", true)
	pool.fog_color = Color(0.2, 0.22, 0.18)
	pool.fog_density = 0.9
	pool.tint = Color(0.4, 0.45, 0.35)
	spots["pool"] = Vector3(c.x, T.POOL_Y, c.z)
	# the main gantry over the shaft: two A-frames on the rims, a top girder and the failed pulley
	for s in [-1.0, 1.0]:
		var base := Vector3(c.x, 0, c.z + s * (T.BH_R + 3.5))
		base.y = g(base.x, base.z)
		for lx in [-3.0, 3.0]:
			var foot := base + Vector3(lx, 0, 0)
			var top := Vector3(c.x, base.y + 13.0, base.z)
			var mid := (foot + top) * 0.5
			var d := top - foot
			var bas := Basis(Vector3(0, 0, 1).cross(d.normalized()).normalized(), d.normalized(), Vector3(0, 0, 1)).orthonormalized()
			k.box_xf(Transform3D(bas, mid), Vector3(0.45, d.length(), 0.45), "l24_steel")
	k.box(Vector3(c.x, g(c.x, c.z + T.BH_R + 3.5) + 13.2, c.z), Vector3(0.7, 0.8, 2.0 * T.BH_R + 8.0), "l24_steel", GeoKit.ALL, false)
	var wheel := Node3D.new()
	lv.add_child(wheel)
	wheel.position = Vector3(c.x + 0.6, 12.2, c.z + 2.0)
	wheel.rotation = Vector3(0.0, PI * 0.5, 0.5)
	var wm := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.75
	tm.outer_radius = 0.95
	wm.mesh = tm
	wm.rotation.x = PI * 0.5
	wm.material_override = MatLib.get_mat("l24_rust")
	wheel.add_child(wm)
	k.box(Vector3(c.x + 0.9, (12.0 + T.POOL_Y) * 0.5 + 0.5, c.z + 2.6), Vector3(0.04, 12.0 - T.POOL_Y - 1.0, 0.04), "l24_rubber", GeoKit.ALL, false)
	Props.place(lv, props, "ph/barrel_03", Vector3(c.x + 1.2, T.POOL_Y - 0.5, c.z + 3.0), 40.0)
	label("BLUEHOLE - B.N.T.G. MOON-MINE\nCLOSED", Vector3(c.x - T.BH_R - 7.0, g(c.x - T.BH_R - 7.0, c.z + 5.0) + 2.0, c.z + 5.0), -PI * 0.5, 0.008, Color(0.85, 0.85, 0.8))
	k.box(Vector3(c.x - T.BH_R - 6.95, g(c.x - T.BH_R - 7.0, c.z + 5.0) + 2.0, c.z + 5.0), Vector3(0.06, 1.2, 3.8), "l24_blue_panel", GeoKit.ALL, false)
	k.box(Vector3(c.x - T.BH_R - 6.95, g(c.x - T.BH_R - 7.0, c.z + 5.0) + 0.7, c.z + 5.0), Vector3(0.12, 1.4, 0.12), "l24_steel", GeoKit.ALL, false)
	label("\"It may be blue, but we promise it's hell.\"\n- Mining Crew 1", Vector3(c.x - T.BH_R - 7.0, g(c.x - T.BH_R - 7.0, c.z - 6.0) + 1.6, c.z - 6.0), -PI * 0.5, 0.0045, Color(0.12, 0.25, 0.6))
	k.box(Vector3(c.x - T.BH_R - 6.95, g(c.x - T.BH_R - 7.0, c.z - 6.0) + 1.6, c.z - 6.0), Vector3(0.05, 0.8, 3.2), "l24_plastic", GeoKit.ALL, false)
	k.box(Vector3(c.x - T.BH_R - 6.95, g(c.x - T.BH_R - 7.0, c.z - 6.0) + 0.6, c.z - 6.0), Vector3(0.12, 1.2, 0.12), "l24_steel", GeoKit.ALL, false)
	# loading area: two huts, one crushed; gear left where it fell
	var hut := Vector3(c.x - 26.0, 0, c.z - 14.0)
	hut.y = g(hut.x, hut.z)
	k.box(hut + Vector3(0, 1.3, 0), Vector3(8.0, 2.6, 4.0), "l24_panel")
	k.box(hut + Vector3(0, 2.7, 0), Vector3(8.4, 0.16, 4.4), "l24_steel", GeoKit.ALL, false)
	for i in 3:
		k.box(hut + Vector3(-2.5 + i * 2.5, 1.6, 2.02), Vector3(1.1, 0.7, 0.03), "l24_window_dead", GeoKit.ALL, false)
	var hut2 := Vector3(c.x - 24.0, 0, c.z + 16.0)
	hut2.y = g(hut2.x, hut2.z)
	k.box_xf(Transform3D(Basis(Vector3(0, 0, 1), 0.22) * Basis(Vector3.UP, 0.3), hut2 + Vector3(0, 0.9, 0)), Vector3(7.0, 1.8, 4.0), "l24_panel")
	k.box_xf(Transform3D(Basis(Vector3(1, 0, 0), 0.35), hut2 + Vector3(0.5, 1.6, 1.0)), Vector3(7.4, 0.14, 3.0), "l24_steel")
	for i in 5:
		_shovel(Vector3(c.x - 18.0 + rng.randf_range(-3.0, 3.0), 0, c.z - 6.0 + i * 1.7), rng.randf() * 360.0)
	for i in 4:
		var p := Vector3(c.x - 20.0 + rng.randf_range(-6.0, 6.0), 0, c.z + rng.randf_range(-12.0, 12.0))
		p.y = g(p.x, p.z)
		Props.place(lv, props, ["ph/Barrel_01", "ph/old_military_crate", "ph/portable_generator", "ph/propane_tank"][i], p, rng.randf() * 360.0, 0.0, i < 3)
	# chipped plastic and blue-dyed blocks heaped by the ramp
	for i in 26:
		var q := Vector3(c.x - T.BH_R - 4.0 + rng.randf_range(-8.0, 3.0), 0, c.z + rng.randf_range(-7.0, 7.0))
		q.y = g(q.x, q.z)
		var xf := Transform3D(Basis.from_euler(Vector3(rng.randf_range(-0.4, 0.4), rng.randf() * TAU, rng.randf_range(-0.4, 0.4))), q + Vector3(0, 0.1, 0))
		var big := i % 4 == 0
		k.box_xf(xf, Vector3(0.9, 0.5, 0.6) if big else Vector3(0.18, 0.08, 0.14) * rng.randf_range(0.6, 2.0), "l24_plastic_blue" if rng.randf() < 0.6 else "l24_plastic", GeoKit.ALL, big)
	# a light rig that still has power in its battery
	var lr := Vector3(c.x - 12.0, 0, c.z + 9.0)
	lr.y = g(lr.x, lr.z)
	k.box(lr + Vector3(0, 2.0, 0), Vector3(0.15, 4.0, 0.15), "l24_steel", GeoKit.ALL, false)
	k.box(lr + Vector3(0.3, 4.0, -0.3), Vector3(0.5, 0.4, 0.5), "l24_lamp", GeoKit.ALL, false)
	spots["light"] = lr + Vector3(1.0, 3.6, -1.0)
	spots["rim"] = Vector3(c.x - T.BH_R - 3.0, 0.0, c.z)
	spots["hut"] = hut
	lv.add_note("l24_paintbusters", "Paint Busters report (pinned in the hut)",
		"Foreman's complaint: jackhammering the paint put four men in the infirmary; respirators clog faster than they can be swapped; twelve metres down and a third of the crew is out. Requests paint thinner. (B.N.T.G. report, paraphrased; testimony)",
		hut + Vector3(0, 1.0, 2.4), Vector3(1.2, 1.4, 0.8))
	lv.add_note("l24_disaster", "Bluehole disaster overview (on the gantry)",
		"23 June: a Hot-Shovel opened a hidden pocket of paint thinner. The blast, then the propane tank, then boiling fumes down the column: all 24 of Mining Crew 1 died. The foreman lived long enough to tell it. (B.N.T.G. record, paraphrased)",
		Vector3(c.x - 3.0, g(c.x - 3.0, c.z - T.BH_R - 3.5) + 1.2, c.z - T.BH_R - 3.5), Vector3(1.4, 1.6, 1.0))


func label(text: String, p: Vector3, yaw: float, px: float, col: Color) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = 64
	l.pixel_size = px
	l.modulate = col
	l.shaded = true
	l.position = p
	l.rotation.y = yaw
	l.visibility_range_end = 120.0
	lv.add_child(l)


func _shovel(p: Vector3, yaw: float) -> void:
	p.y = g(p.x, p.z)
	var bas := Basis(Vector3.UP, deg_to_rad(yaw)) * Basis(Vector3(0, 0, 1), PI * 0.5 - 0.06)
	k.box_xf(Transform3D(bas, p + Vector3(0, 0.06, 0)), Vector3(0.05, 1.5, 0.05), "l24_steel", GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), p + Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3(0.8, 0.03, 0)), Vector3(0.32, 0.03, 0.28), "l24_rust", GeoKit.ALL, false)
	Props.place(lv, props, "ph/propane_tank", p + Basis(Vector3.UP, deg_to_rad(yaw)) * Vector3(-0.4, 0, 0.25), yaw, 0.4)
