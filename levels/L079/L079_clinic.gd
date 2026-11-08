extends "res://levels/L079/L079_rooms.gd"
## Level 79 clinic, continued: rooms 2-7 dressing, the corridor, the clocks and the machine.


func _init(level: LevelBase, arch: GeoKit, dress: GeoKit) -> void:
	super(level, arch, dress)


## Room 2 (left): equipment storage. Six named machines and four unknown, newer ones.
func storage() -> void:
	# steel shelving with boxed supplies along the west wall
	for i in 4:
		var z := -3.3 - i * 0.62
		_p("ph/steel_frame_shelves_02", Vector3(-6.72, 0, z), 90.0, 2.1, i == 0)
	var r := RandomNumberGenerator.new()
	r.seed = 7902
	for i in 4:
		for lvl in [0.42, 1.02, 1.6]:
			if r.randf() < 0.75:
				_p("ph/medical_box" if r.randf() < 0.5 else "ph/cardboard_box_01", Vector3(-6.72, lvl, -3.3 - i * 0.62 + r.randf_range(-0.08, 0.08)), 90.0 + r.randf_range(-20, 20), 0.0)
	# cardiopulmonary monitor: a CRT on a cart
	var t1 := cart(Vector3(-4.2, 0, -3.1), 0.0)
	_p("ph/Television_01", t1, 180.0)
	# ECG machine
	var t2 := cart(Vector3(-3.1, 0, -3.1), 0.0, 0.6, 0.45)
	_p("ph/vintage_radio_transceiver", t2, 180.0)
	d.box(t2 + Vector3(0.0, -0.4, 0.0), Vector3(0.5, 0.25, 0.35), "l79_cart", GeoKit.ALL, false)
	# kidney dialysis machine: tall cabinet, pump drum, tubing
	d.box(Vector3(-2.2, 0.72, -3.0), Vector3(0.55, 1.44, 0.5), "l79_enamel", GeoKit.ALL, true)
	d.box(Vector3(-2.2, 1.0, -2.74), Vector3(0.26, 0.26, 0.03), "l79_chrome", GeoKit.ALL, false)
	d.box(Vector3(-2.2, 1.3, -2.745), Vector3(0.36, 0.14, 0.01), "l79_rubber", GeoKit.ALL, false)
	for i in 3:
		d.cylinder(Vector3(-2.38 + i * 0.18, 1.62, -3.0), 0.012, 0.36, "l79_rubber", 6, false)
	# mechanical ventilator: bellows column on a stand
	var t3 := cart(Vector3(-2.6, 0, -9.0), 180.0, 0.6, 0.5, 0.7)
	d.box(t3 + Vector3(0, 0.22, 0), Vector3(0.5, 0.44, 0.4), "l79_cart", GeoKit.ALL, false)
	d.cylinder(t3 + Vector3(0.12, 0.66, 0), 0.11, 0.42, "l79_frost", 12, false)
	# sonograph: console with a small screen and probe arm
	var t4 := cart(Vector3(-3.6, 0, -9.0), 180.0, 0.7, 0.55, 0.78)
	_p("kenney/furniture-kit/televisionvintage", t4, 0.0, 0.32)
	d.box(t4 + Vector3(0.28, 0.25, 0.1), Vector3(0.04, 0.5, 0.04), "l79_chrome", GeoKit.ALL, false)
	# fixed-angle centrifuge on a bench
	d.box(Vector3(-4.9, 0.45, -9.15), Vector3(1.2, 0.9, 0.55), "l79_wood", GeoKit.ALL, true)
	d.cylinder(Vector3(-5.0, 1.04, -9.15), 0.22, 0.28, "l79_enamel", 16, false)
	d.cylinder(Vector3(-5.0, 1.19, -9.15), 0.2, 0.03, "l79_chrome", 16, false)
	# the four machines of unknown purpose, newer than anything else here
	_p("kenney/space-kit/machine-generatorlarge", Vector3(-6.2, 0, -8.3), 90.0, 1.25, true)
	_p("kenney/space-kit/machine-wirelesscable", Vector3(-6.3, 0, -6.9), 90.0, 1.35, true)
	_p("kenney/space-kit/machine-barrellarge", Vector3(-5.0, 0, -7.6), 30.0, 0.95)
	_p("kenney/space-kit/machine-generator", Vector3(-5.3, 0, -6.3), -60.0, 0.75)
	_p("ph/hand_truck", Vector3(-2.2, 0, -8.6), 200.0)
	_p("ph/clipboard", Vector3(-4.95, 0.9, -9.05), 15.0)


## Room 3 (right): examination room. Wall machine on the right as you enter; locked
## medicine cabinet on the left.
func exam() -> void:
	# examination couch
	d.box(Vector3(4.4, 0.42, -11.5), Vector3(0.7, 0.84, 1.85), "l79_enamel", GeoKit.ALL, true)
	d.box(Vector3(4.4, 0.89, -11.5), Vector3(0.72, 0.1, 1.9), "l79_rubber", GeoKit.ALL, false)
	d.box_xf(Transform3D(Basis(Vector3(1, 0, 0), deg_to_rad(28.0)), Vector3(4.4, 1.1, -10.75)), Vector3(0.72, 0.1, 0.62), "l79_rubber", GeoKit.ALL, false)
	_p("kenney/furniture-kit/stoolbar", Vector3(3.3, 0, -12.2), 30.0, 0.55)
	# the wall-embedded machine of unknown function (south wall = right side on entering)
	d.box_mm(Vector3(2.9, 0.0, -7.58), Vector3(5.7, 2.6, -7.48), "l79_machine_b", GeoKit.ALL, false)
	d.box_mm(Vector3(3.1, 0.12, -7.95), Vector3(5.5, 0.95, -7.56), "l79_machine", GeoKit.ALL, true)
	d.box_mm(Vector3(3.1, 1.1, -7.75), Vector3(5.5, 2.45, -7.56), "l79_machine", GeoKit.ALL, false)
	for i in 6:
		d.box(Vector3(3.35 + i * 0.4, 1.85, -7.74), Vector3(0.22, 0.12, 0.02), "l79_lightbox" if i == 2 else "l79_frame", GeoKit.ALL, false)
	# corrugated hoses, IV lines and wires spilling from the lower compartment
	var r := RandomNumberGenerator.new()
	r.seed = 7903
	for i in 5:
		var x := 3.3 + i * 0.5
		for s in 6:
			d.box(Vector3(x + s * 0.03, 0.08, -8.0 - s * 0.16), Vector3(0.09, 0.09, 0.12), "l79_rubber", GeoKit.ALL, false)
	for i in 4:
		var x2 := 3.4 + i * 0.6
		d.box(Vector3(x2, 1.6, -7.98), Vector3(0.008, 1.2, 0.008), "l79_frost", GeoKit.ALL, false)
	_p("ph/modular_electric_cables", Vector3(4.3, 2.48, -7.62), 0.0, 0.5)
	_p("ph/modular_industrial_pipes_01", Vector3(5.85, 0, -7.7), 0.0, 2.6)
	# locked medicine cabinet, glass front (north wall = left side)
	d.box_mm(Vector3(3.4, 0.9, -15.12), Vector3(4.7, 2.2, -14.72), "l79_enamel", GeoKit.ALL, true)
	d.box_mm(Vector3(3.45, 0.95, -14.73), Vector3(4.65, 2.15, -14.71), "glass", GeoKit.ALL, false)
	for sh in [1.25, 1.62, 1.98]:
		d.box(Vector3(4.05, sh - 0.12, -14.95), Vector3(1.2, 0.02, 0.32), "l79_chrome", GeoKit.ALL, false)
		for j in 8:
			var col: String = ["l79_lightbox", "l79_red_ball", "l79_enamel", "l79_frost"][int(r.randi() % 4)]
			d.cylinder(Vector3(3.55 + j * 0.14, sh - 0.04, -14.95 + r.randf_range(-0.05, 0.05)), 0.03, 0.14 + r.randf() * 0.06, col, 8, false)
	d.box(Vector3(4.66, 1.5, -14.7), Vector3(0.05, 0.12, 0.04), "l79_chrome", GeoKit.ALL, false)
	# sink and wall cabinets on the far wall
	_p("kenney/furniture-kit/bathroomsinksquare", Vector3(6.75, 0, -13.6), -90.0, 0.95)
	_p("kenney/furniture-kit/bathroommirror", Vector3(6.97, 1.2, -13.6), -90.0, 0.6)
	_p("kenney/furniture-kit/kitchencabinetupper", Vector3(6.8, 1.5, -10.4), -90.0, 0.7)
	_p("ph/medical_box", Vector3(6.6, 0.0, -9.0), 30.0)
	# a folding screen
	for i in 3:
		var p := Vector3(2.4 + i * 0.5, 0.9, -9.4 - (i % 2) * 0.12)
		d.box(p, Vector3(0.5, 1.6, 0.03), "l79_mattress", GeoKit.ALL, false)


## Room 4 (left): radiology. A mid-century X-ray unit and, on the rear wall, the
## negatoscope with a single film.
func xray() -> void:
	# patient table
	d.box(Vector3(-4.2, 0.4, -13.2), Vector3(0.9, 0.8, 0.5), "l79_frame", GeoKit.ALL, true)
	d.box(Vector3(-4.2, 0.84, -13.2), Vector3(2.1, 0.08, 0.75), "l79_enamel", GeoKit.ALL, false)
	# tube stand on floor rails: twin column, carriage, cross-arm, tube head and collimator
	for sx in [-0.1, 0.1]:
		d.box(Vector3(-4.2 + sx, 1.4, -14.4), Vector3(0.07, 2.8, 0.12), "l79_chrome", GeoKit.ALL, false)
	d.box(Vector3(-4.2, 1.4, -14.4), Vector3(0.28, 2.8, 0.04), "l79_enamel", GeoKit.ALL, true)
	for sx in [-1.2, 1.2]:
		d.box(Vector3(-4.2 + sx * 0.0, 0.03, -14.4), Vector3(2.6, 0.06, 0.1), "l79_chrome", GeoKit.ALL, false)
	d.box(Vector3(-4.2, 2.05, -14.25), Vector3(0.36, 0.34, 0.22), "l79_enamel", GeoKit.ALL, false)
	d.box(Vector3(-4.2, 2.05, -13.75), Vector3(0.1, 0.1, 0.9), "l79_chrome", GeoKit.ALL, false)
	hcyl(Vector3(-4.2, 1.92, -13.25), 0.13, 0.62, Vector3(1, 0, 0), "l79_enamel")
	for sx in [-1.0, 1.0]:
		hcyl(Vector3(-4.2 + sx * 0.33, 1.92, -13.25), 0.15, 0.06, Vector3(1, 0, 0), "l79_frame")
	d.box(Vector3(-4.2, 1.68, -13.25), Vector3(0.22, 0.2, 0.22), "l79_frame", GeoKit.ALL, false)
	d.box(Vector3(-4.2, 1.56, -13.25), Vector3(0.16, 0.05, 0.16), "l79_lightbox", GeoKit.ALL, false)
	for i in 3:
		d.box(Vector3(-4.32 + i * 0.12, 2.24, -14.25), Vector3(0.012, 0.012, 0.6), "l79_rubber", GeoKit.ALL, false)
	# bucky tray under the table top
	d.box(Vector3(-4.2, 0.74, -13.2), Vector3(0.5, 0.08, 0.6), "l79_chrome", GeoKit.ALL, false)
	# control desk and lead apron
	d.box(Vector3(-2.3, 0.55, -10.2), Vector3(0.9, 1.1, 0.55), "l79_cart", GeoKit.ALL, true)
	for i in 4:
		d.cylinder(Vector3(-2.55 + i * 0.16, 1.12, -10.2), 0.035, 0.03, "l79_frame", 10, false)
	d.box(Vector3(-2.3, 1.45, -10.42), Vector3(0.7, 0.55, 0.06), "l79_frame", GeoKit.ALL, false)
	d.box(Vector3(-6.95, 1.3, -10.6), Vector3(0.06, 1.0, 0.55), "l79_rubber", GeoKit.ALL, false)
	d.box(Vector3(-6.97, 1.85, -10.6), Vector3(0.04, 0.06, 0.3), "l79_chrome", GeoKit.ALL, false)
	# the negatoscope: a lit box on the rear wall with one film clipped on
	d.box(Vector3(-6.96, 1.55, -13.2), Vector3(0.12, 0.8, 1.6), "l79_enamel", GeoKit.ALL, false)
	d.box(Vector3(-6.895, 1.57, -13.2), Vector3(0.01, 0.62, 1.44), "l79_lightbox", GeoKit.ALL, false)
	d.box(Vector3(-6.885, 1.57, -13.55), Vector3(0.01, 0.5, 0.4), "l79_board", GeoKit.ALL, false)
	# the radiograph: pale bone shapes of a small, badly deformed forearm and hand
	var bones := [[-13.55, 1.42, 0.03, 0.32, 8.0], [-13.5, 1.44, 0.025, 0.3, -6.0], [-13.6, 1.66, 0.06, 0.08, 20.0],
		[-13.66, 1.73, 0.015, 0.1, 35.0], [-13.58, 1.76, 0.015, 0.09, 5.0], [-13.5, 1.72, 0.015, 0.07, -40.0]]
	for b in bones:
		d.box_xf(Transform3D(Basis(Vector3(1, 0, 0), deg_to_rad(float(b[4]))), Vector3(-6.879, float(b[1]), float(b[0]))),
			Vector3(0.004, float(b[3]), float(b[2])), "l79_enamel", GeoKit.ALL, false)
	_p("ph/clipboard", Vector3(-2.35, 1.1, -10.1), 80.0)
	_p("ph/SchoolChair_01", Vector3(-2.6, 0, -11.0), 200.0)


## Room 5 (right): living quarters. Six twin mattresses on wire frames, two dressers.
func quarters() -> void:
	var beds := [[5.95, -16.1, 90.0], [5.95, -18.1, 90.0], [5.95, -20.6, 90.0], [5.95, -22.6, 90.0], [2.35, -22.9, 0.0], [3.6, -22.9, 0.0]]
	var r := RandomNumberGenerator.new()
	r.seed = 7905
	for b in beds:
		var p := Vector3(float(b[0]), 0, float(b[1]))
		var yaw: float = float(b[2])
		_p("ph/old_bed_frame", p, yaw, 0.0, true)
		var bas := Basis(Vector3.UP, deg_to_rad(yaw + r.randf_range(-3, 3)))
		d.box_xf(Transform3D(bas, p + Vector3.UP * 0.5), Vector3(0.84, 0.13, 1.88), "l79_mattress", GeoKit.ALL, false)
	# two dressers against the entrance-side wall
	_p("ph/drawer_cabinet", Vector3(3.0, 0, -15.56), 180.0, 1.15, true)
	_p("ph/drawer_cabinet", Vector3(4.45, 0, -15.56), 180.0, 1.15, true)
	# three black crayons and the blank sheets on top
	for i in 3:
		d.box_xf(Transform3D(Basis(Vector3.UP, 0.4 + i * 0.5), Vector3(2.85 + i * 0.07, 1.16, -15.5)), Vector3(0.09, 0.009, 0.009), "l79_rubber", GeoKit.ALL, false)
	for i in 4:
		d.box_xf(Transform3D(Basis(Vector3.UP, r.randf_range(-0.3, 0.3)), Vector3(4.45, 1.155 + i * 0.002, -15.5)), Vector3(0.21, 0.001, 0.28), "paper", GeoKit.ALL, false)
	# the red rubber handball, by the wall
	var ball := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.035
	sm.height = 0.07
	ball.mesh = sm
	ball.material_override = MatLib.get_mat("l79_red_ball")
	ball.position = Vector3(5.2, 0.035, -19.3)
	props.add_child(ball)
	_radiator(Vector3(1.75, 0, -22.6), Vector3(0, 0, 1))


## Room 6 (left): operating theatre, sunk four steps below a viewing landing. Empty;
## a slurry of fluids with screws and metal shavings has built up on the floor.
func theatre() -> void:
	var y := THEATRE_Y
	k.stairs(Vector3(-4.1, y, -20.4), Vector3(1, 0, 0), 1.6, -y, 4, "l79_floor_tile", 0.3)
	# landing rail, open at the stair
	for seg in [[-16.9, -19.6], [-21.2, -23.9]]:
		var z0: float = float(seg[0])
		var z1: float = float(seg[1])
		k.box(Vector3(-2.92, 0.98, (z0 + z1) * 0.5), Vector3(0.05, 0.05, absf(z1 - z0)), "l79_chrome", GeoKit.ALL, false)
		k.box(Vector3(-2.92, 0.5, (z0 + z1) * 0.5), Vector3(0.03, 1.0, absf(z1 - z0)), "glass", GeoKit.ALL, true)
		for i in int(absf(z1 - z0) / 0.9) + 1:
			k.box(Vector3(-2.92, 0.5, z0 - i * 0.9), Vector3(0.04, 1.0, 0.04), "l79_chrome", GeoKit.ALL, false)
	# operating table and the lamp above it
	var c := Vector3(-5.3, y, -20.4)
	d.box(c + Vector3(0, 0.45, 0), Vector3(0.35, 0.9, 0.35), "l79_chrome", GeoKit.ALL, true)
	d.box(c + Vector3(0, 0.06, 0), Vector3(0.7, 0.12, 0.9), "l79_chrome", GeoKit.ALL, false)
	d.box(c + Vector3(0, 0.95, 0), Vector3(0.6, 0.1, 1.95), "l79_rubber", GeoKit.ALL, false)
	d.cylinder(c + Vector3(0, H - y - 0.4, 0), 0.03, 0.8, "l79_chrome", 6, false)
	d.cylinder(c + Vector3(0, H - y - 0.9, 0), 0.42, 0.22, "l79_enamel", 18, false)
	d.panel(c + Vector3(0, H - y - 1.015, 0), 0.5, 0.5, "l79_panel_on")
	# instrument trolley, empty
	var tt := cart(c + Vector3(0.3, 0, 1.75), 20.0, 0.6, 0.4, 0.85)
	d.box(tt + Vector3(0, 0.01, 0), Vector3(0.5, 0.015, 0.32), "l79_chrome", GeoKit.ALL, false)
	# the slurry: one wide pool around the table and runnels toward the drain
	d.box(c + Vector3(-0.1, 0.006, 0.1), Vector3(2.6, 0.012, 3.4), "l79_slurry", GeoKit.ALL, false)
	d.box(c + Vector3(0.6, 0.008, -1.6), Vector3(1.0, 0.012, 1.0), "l79_slurry", GeoKit.ALL, false)
	d.box(c + Vector3(-1.0, 0.008, 1.9), Vector3(0.9, 0.012, 1.1), "l79_slurry", GeoKit.ALL, false)
	d.cylinder(c + Vector3(0.9, 0.004, -0.6), 0.12, 0.008, "l79_frame", 12, false)
	var r := RandomNumberGenerator.new()
	r.seed = 7906
	for i in 26:
		var o := Vector3(r.randf_range(-1.2, 1.2), 0.016, r.randf_range(-1.6, 1.6))
		d.box_xf(Transform3D(Basis(Vector3.UP, r.randf() * TAU), c + o), Vector3(0.03 + r.randf() * 0.03, 0.008, 0.008), "l79_chrome", GeoKit.ALL, false)
	_p("ph/korean_fire_extinguisher_01", Vector3(-1.8, 0, -17.3), 0.0)


func corridor_dressing() -> void:
	# bench by the entrance, with the log sheet
	d.box(Vector3(-1.15, 0.42, -2.0), Vector3(0.4, 0.05, 1.4), "l79_wood", GeoKit.ALL, true)
	for z in [-1.4, -2.6]:
		d.box(Vector3(-1.15, 0.2, z), Vector3(0.36, 0.4, 0.05), "l79_frame", GeoKit.ALL, false)
	_p("ph/clipboard", Vector3(-1.1, 0.445, -2.0), 85.0)
	# bumper rail on both corridor walls (skipping doorways)
	var ops := {1.0: [[0.0, 3.1], [4.3, 10.7], [11.9, 19.0], [20.2, 24.0]], -1.0: [[0.2, 5.1], [6.9, 12.6], [13.8, 19.5], [21.3, 24.0]]}
	for sx in ops.keys():
		for seg in ops[sx]:
			var z0 := -float(seg[0])
			var z1 := -float(seg[1])
			d.box(Vector3(float(sx) * (CW - 0.03), 0.92, (z0 + z1) * 0.5), Vector3(0.06, 0.14, absf(z1 - z0)), "l79_wood", GeoKit.ALL, false)
	# a gurney left against the wall, a wheel missing
	var g := Vector3(-0.95, 0, -16.5)
	d.box(g + Vector3(0, 0.78, 0), Vector3(0.6, 0.08, 1.9), "l79_rubber", GeoKit.ALL, true)
	d.box(g + Vector3(0, 0.7, 0), Vector3(0.62, 0.06, 1.95), "l79_chrome", GeoKit.ALL, false)
	for sz in [-0.85, 0.85]:
		d.box(g + Vector3(0, 0.36, sz), Vector3(0.5, 0.04, 0.04), "l79_chrome", GeoKit.ALL, false)
		for sx2 in [-0.27, 0.27]:
			d.box(g + Vector3(sx2, 0.36, sz), Vector3(0.03, 0.7, 0.03), "l79_chrome", GeoKit.ALL, false)
	d.box(g + Vector3(0.0, 0.83, 0.65), Vector3(0.5, 0.06, 0.4), "l79_mattress", GeoKit.ALL, false)
	# pipes under the ceiling, a fire extinguisher, an alarm, radiators
	d.box(Vector3(0.95, H - 0.18, -12.0), Vector3(0.11, 0.11, 24.0), "l79_pipe", GeoKit.ALL, false)
	d.box(Vector3(0.7, H - 0.12, -12.0), Vector3(0.06, 0.06, 24.0), "l79_pipe", GeoKit.ALL, false)
	for z in [-2.0, -12.0, -22.0]:
		d.box(Vector3(0.95, H - 0.06, z), Vector3(0.04, 0.12, 0.04), "l79_frame", GeoKit.ALL, false)
	_p("ph/korean_fire_extinguisher_01", Vector3(1.2, 0.0, -14.4), -90.0)
	_p("ph/fire_alarm", Vector3(1.39, 1.45, -14.4), -90.0)
	_radiator(Vector3(-1.32, 0, -10.8), Vector3(0, 0, 1))
	_radiator(Vector3(1.32, 0, -6.4), Vector3(0, 0, 1))
	_p("ph/WetFloorSign_01", Vector3(0.6, 0, -22.4), 30.0)
	_p("kenney/furniture-kit/trashcan", Vector3(-1.15, 0, -4.2), 0.0, 0.5)


## The corridor clock (it jumps when the machine knocks).
func corridor_clock(p: Vector3) -> Dictionary:
	return _clock(p, Vector3(-1, 0, 0), 0.17, 0.4, 2.1)


## A wall clock facing n: bezel, lit face, ticks and two hands on pivots.
func _clock(c: Vector3, n: Vector3, r: float, hour_angle: float, min_angle: float) -> Dictionary:
	var root := Node3D.new()
	root.basis = Basis.looking_at(-n, Vector3.UP)
	root.position = c
	props.add_child(root)
	var bez := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r + 0.03
	cm.bottom_radius = r + 0.03
	cm.height = 0.06
	cm.radial_segments = 20
	bez.mesh = cm
	bez.rotation.x = PI * 0.5
	bez.material_override = MatLib.get_mat("l79_frame")
	root.add_child(bez)
	var face := MeshInstance3D.new()
	var fm := CylinderMesh.new()
	fm.top_radius = r
	fm.bottom_radius = r
	fm.height = 0.01
	fm.radial_segments = 20
	face.mesh = fm
	face.rotation.x = PI * 0.5
	face.position.z = 0.031
	face.material_override = MatLib.get_mat("l79_clockface")
	root.add_child(face)
	for i in 12:
		var t := MeshInstance3D.new()
		var tb := BoxMesh.new()
		tb.size = Vector3(0.012, r * (0.2 if i % 3 == 0 else 0.11), 0.004)
		t.mesh = tb
		var a := TAU * i / 12.0
		t.position = Vector3(sin(a), cos(a), 0) * r * 0.84 + Vector3(0, 0, 0.038)
		t.rotation.z = -a
		t.material_override = MatLib.get_mat("l79_rubber")
		root.add_child(t)
	var out := {}
	for hand in [["hour", 0.55, 0.022, hour_angle], ["min", 0.82, 0.014, min_angle]]:
		var piv := Node3D.new()
		piv.position = Vector3(0, 0, 0.042 if hand[0] == "hour" else 0.046)
		piv.rotation.z = -float(hand[3])
		root.add_child(piv)
		var m := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(float(hand[2]), r * float(hand[1]), 0.004)
		m.mesh = bm
		m.position = Vector3(0, r * float(hand[1]) * 0.45, 0)
		m.material_override = MatLib.get_mat("l79_rubber")
		piv.add_child(m)
		out[hand[0]] = piv
	return out


## Room 7 (centre): the machine. Undetermined composition; sixteen clocks, each showing a
## different time; a slow leak from its left side. Returns the clocks.
func machine(base: Vector3) -> Array:
	var fz := base.z + 0.9
	k.box(base + Vector3(0, 1.75, 0), Vector3(5.0, 3.5, 1.8), "l79_machine", GeoKit.ALL, true)
	k.box(base + Vector3(0, 3.95, -0.3), Vector3(3.8, 0.9, 1.2), "l79_machine_b", GeoKit.ALL, false)
	for sx in [-1.0, 1.0]:
		k.box(base + Vector3(sx * 2.85, 1.2, -0.2), Vector3(0.7, 2.4, 1.3), "l79_machine_b", GeoKit.ALL, true)
		k.box(base + Vector3(sx * 2.85, 1.2, 0.46), Vector3(0.5, 2.0, 0.02), "l79_frame", GeoKit.ALL, false)
	# pipes into the ceiling and walls
	for i in 5:
		var x := -1.6 + i * 0.8
		d.cylinder(base + Vector3(x, 4.65, -0.3 + (i % 2) * 0.3), 0.09 + (i % 3) * 0.03, 0.6, "l79_pipe", 10, false)
	d.cylinder(Vector3(-4.6, 2.7, base.z - 0.4), 0.12, 1.6, "l79_pipe", 10, false)
	d.box(Vector3(-4.6, 3.45, base.z - 0.4), Vector3(0.24, 0.1, 1.4), "l79_pipe", GeoKit.ALL, false)
	# cables across the floor from both sides
	var r := RandomNumberGenerator.new()
	r.seed = 7907
	for i in 8:
		var sx2 := -1.0 if i % 2 == 0 else 1.0
		var x0 := sx2 * (2.5 + r.randf() * 0.3)
		var z0 := base.z + r.randf_range(-0.5, 1.6)
		d.box_xf(Transform3D(Basis(Vector3.UP, r.randf_range(-0.6, 0.6)), Vector3(x0 + sx2 * 1.1, base.y + 0.025, z0)),
			Vector3(2.2, 0.05, 0.05), "l79_rubber", GeoKit.ALL, false)
	# the face: rivets and vents around a 4 x 4 grid of clocks
	for row in 2:
		for i in 11:
			d.box(Vector3(base.x - 2.25 + i * 0.45, base.y + 0.15 + row * 3.2, fz + 0.01), Vector3(0.05, 0.05, 0.02), "l79_chrome", GeoKit.ALL, false)
	d.box(Vector3(base.x, base.y + 1.8, fz + 0.005), Vector3(3.9, 3.2, 0.02), "l79_board", GeoKit.ALL, false)
	var clocks: Array = []
	var used := {}
	for row in 4:
		for col in 4:
			var cp := Vector3(base.x - 1.38 + col * 0.92, base.y + 0.55 + row * 0.82, fz + 0.03)
			var hh := 0
			var mm := 0
			while true:
				hh = r.randi() % 12
				mm = r.randi() % 60
				if not used.has(hh * 60 + mm):
					used[hh * 60 + mm] = true
					break
			var hour_a := TAU * (hh + mm / 60.0) / 12.0
			var min_a := TAU * mm / 60.0
			var c := _clock(cp, Vector3(0, 0, 1), 0.3, hour_a, min_a)
			var rate := TAU / 3600.0 * r.randf_range(0.4, 3.0) * (-1.0 if r.randf() < 0.3 else 1.0)
			c["rate"] = rate
			clocks.append(c)
	# a manifold across the top, conduit columns, louvres and a hatch: it is built, not grown
	hcyl(base + Vector3(0, 2.75, 0.75), 0.16, 5.4, Vector3(1, 0, 0), "l79_pipe")
	for sx in [-1.0, 1.0]:
		hcyl(base + Vector3(sx * 2.15, 1.3, 1.02), 0.11, 2.6, Vector3(0, 1, 0), "l79_pipe")
		hcyl(base + Vector3(sx * 2.15, 2.75, 1.02), 0.14, 0.18, Vector3(0, 1, 0), "l79_frame")
		for j in 9:
			d.box(base + Vector3(sx * 2.85, 0.5 + j * 0.16, 0.48), Vector3(0.44, 0.03, 0.05), "l79_frame", GeoKit.ALL, false)
		hcyl(Vector3(sx * 4.2, base.y + 3.0, base.z), 0.1, 2.6, Vector3(1, 0, 0), "l79_pipe")
	d.box(base + Vector3(0, 0.12, 0.92), Vector3(3.9, 0.2, 0.05), "l79_frame", GeoKit.ALL, false)
	d.box(base + Vector3(0, 3.32, 0.92), Vector3(3.9, 0.2, 0.05), "l79_frame", GeoKit.ALL, false)
	for i in 6:
		d.box(Vector3(-1.5 + i * 0.6, 3.85, base.z + 0.2), Vector3(0.02, 0.7, 0.02), "l79_rubber", GeoKit.ALL, false)
	# the leak runs down the left side to the floor
	d.box(Vector3(base.x - 2.52, base.y + 1.1, fz - 0.4), Vector3(0.02, 1.8, 0.16), "l79_slurry", GeoKit.ALL, false)
	return clocks


func leak_patch(p: Vector3) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.6
	cm.bottom_radius = 0.6
	cm.height = 0.012
	cm.radial_segments = 20
	m.mesh = cm
	m.position = p
	m.material_override = MatLib.get_mat("l79_slurry")
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	props.add_child(m)
	return m
