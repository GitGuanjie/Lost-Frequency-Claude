extends RefCounted
## Level 17 engineering flats (lower deck) and passage fittings (upper deck).
## The page lists engineering stations among the compartments; boilers, pumps and
## a turbo-generator flat are our period-appropriate reading (ADAPTATION).

const Rooms := preload("res://levels/L017/L017_rooms.gd")
const LOW := -3.2


## A horizontal cylinder along local u (world z) or x, with an optional box collider.
static func hcyl(sb, c: Vector3, r: float, length: float, along_u: bool, mat: String, collide := true) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = length
	cm.radial_segments = 18
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = MatLib.get_mat(mat)
	sb.node.add_child(mi)
	mi.position = c
	if along_u:
		mi.rotation.x = PI * 0.5
	else:
		mi.rotation.z = PI * 0.5
	if collide:
		sb.k.box(c, Vector3(r * 2.0, r * 2.0, length) if along_u else Vector3(length, r * 2.0, r * 2.0), mat, 0, true)


static func valve(sb, p: Vector3, nrm: Vector3, r := 0.2) -> void:
	var g := Node3D.new()
	sb.node.add_child(g)
	g.position = p
	g.basis = Basis.looking_at(-nrm, Vector3.UP)
	Rooms.disc(g, r, 0.03, "l17_pipe_red")
	var hub := Rooms.disc(g, r * 0.3, 0.08, "l17_steel")
	hub.position.z = -0.02
	for a in 3:
		var sp := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(r * 2.0, 0.025, 0.025)
		sp.mesh = bm
		sp.rotation.z = a * PI / 3.0
		sp.material_override = MatLib.get_mat("l17_pipe_red")
		g.add_child(sp)


static func gauge(sb, p: Vector3, nrm: Vector3, r := 0.11) -> void:
	var g := Node3D.new()
	sb.node.add_child(g)
	g.position = p
	g.basis = Basis.looking_at(-nrm, Vector3.UP)
	Rooms.disc(g, r, 0.05, "l17_brass")
	var f := Rooms.disc(g, r * 0.86, 0.06, "l17_white")
	f.position.z = 0.004
	var nd := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.008, r * 0.7, 0.004)
	nd.mesh = bm
	nd.material_override = MatLib.get_mat("l17_black")
	nd.position = Vector3(0, r * 0.2, 0.04)
	nd.rotation.z = sb.rng.randf_range(-2.0, 2.0)
	g.add_child(nd)


static func vpipe(sb, x: float, u: float, r: float, mat: String, y0 := LOW, y1 := -0.3) -> void:
	sb.k.cylinder(sb.P(x, (y0 + y1) * 0.5, u), r, y1 - y0, mat, 10, false)
	for y in [y0 + 0.4, y1 - 0.4]:
		sb.k.cylinder(sb.P(x, y, u), r + 0.03, 0.05, mat, 10, false)


# ------------------------------------------------------------------ lower deck

static func engineering(sb) -> void:
	var kinds := ["boiler", "pump", "generator", "boiler"]
	var kind: String = kinds[sb.rng.randi() % 4]
	if sb.n == 8 or sb.n >= 200:
		kind = "pump"
	var L := LOW
	for s in [-1.0, 1.0]:
		var face := Vector3(-s, 0, 0)
		match kind:
			"boiler":
				var bx: float = s * 7.4
				sb.k.box(sb.P(bx, L + 1.05, 5.0), Vector3(3.6, 2.1, 6.0), "l17_hullside", GeoKit.ALL, true)
				sb.k.box(sb.P(s * 5.62, L + 1.05, 5.0), Vector3(0.06, 2.1, 6.0), "l17_rail", GeoKit.ALL, false)
				for i in 3:
					sb.k.box(sb.P(s * 5.6, L + 0.95, 3.0 + i * 2.0), Vector3(0.06, 0.9, 1.1), "l17_boiler", GeoKit.ALL, false)
				for i in 4:
					vpipe(sb, s * 5.45, 2.0 + i * 2.0, 0.07, "l17_lagging" if i % 2 == 0 else "l17_steel", L + 2.1, -0.3)
				sb.rail(Vector3(s * 4.2, 0, 2.2), Vector3(s * 4.2, 0, 7.8), L)
				hcyl(sb, sb.P(bx, L + 2.45, 5.0), 0.36, 6.4, true, "l17_lagging", false)
				sb.k.box(sb.P(s * 8.6, L + 2.6, 2.4), Vector3(1.2, 0.8, 1.0), "l17_boiler", GeoKit.ALL, false)
				for i in 3:
					var u := 3.0 + i * 2.0
					var g := Node3D.new()
					sb.node.add_child(g)
					g.position = sb.P(s * 5.58, L + 0.95, u)
					g.basis = Basis.looking_at(-face, Vector3.UP)
					Rooms.disc(g, 0.3, 0.06, "l17_steel")
					var eye := Rooms.disc(g, 0.08, 0.08, "l17_dial")
					eye.position.z = 0.02
					gauge(sb, sb.P(s * 5.58, L + 1.75, u), face)
					valve(sb, sb.P(s * 5.55, L + 0.45, u + 0.55), face, 0.13)
				sb.k.box(sb.P(s * 5.6, L + 1.5, 7.9), Vector3(0.05, 0.8, 0.06), "l17_dial_green", GeoKit.ALL, false)
				sb.k.box(sb.P(s * 4.9, L + 0.03, 5.0), Vector3(1.3, 0.06, 6.0), "l17_tread", GeoKit.ALL, false)
				Rooms.label(sb, "No. %d BOILER" % (2 if s > 0 else 1), sb.P(s * 5.58, L + 1.95, 5.0), face, 0.004, Color(0.6, 0.58, 0.5), 48)
			"pump":
				for i in 3:
					var pu := 2.4 + i * 3.2
					var px: float = s * 6.8
					sb.k.box(sb.P(px, L + 0.15, pu), Vector3(1.8, 0.3, 1.3), "l17_steel", GeoKit.ALL, true)
					sb.k.cylinder(sb.P(px - s * 0.35, L + 0.85, pu), 0.34, 1.1, "l17_pipe_red" if i == 1 else "l17_door", 16, false)
					hcyl(sb, sb.P(px + s * 0.45, L + 0.62, pu), 0.3, 0.8, false, "l17_door", false)
					sb.k.cylinder(sb.P(px - s * 0.35, L + 1.95, pu), 0.1, 1.2, "l17_steel", 10, false)
					hcyl(sb, sb.P(px - s * 0.35, L + 2.5, pu), 0.1, 1.8, false, "l17_steel", false)
					valve(sb, sb.P(px - s * 0.75, L + 1.25, pu), face, 0.16)
					gauge(sb, sb.P(px - s * 0.72, L + 1.65, pu + 0.3), face, 0.08)
				sb.k.box(sb.P(s * 6.8, L + 1.0, 6.0), Vector3(1.8, 2.0, 9.0), "l17_rail", 0, true)
				hcyl(sb, sb.P(s * 8.6, L + 1.1, 6.0), 0.18, 10.4, true, "l17_lagging", false)
			"generator":
				var gx: float = s * 7.2
				sb.k.box(sb.P(gx, L + 0.25, 5.0), Vector3(2.6, 0.5, 7.0), "l17_steel", GeoKit.ALL, true)
				hcyl(sb, sb.P(gx, L + 1.35, 3.4), 0.85, 3.2, true, "l17_door", true)
				hcyl(sb, sb.P(gx, L + 1.25, 6.6), 0.75, 2.6, true, "l17_hullside", true)
				sb.k.box(sb.P(gx, L + 1.0, 5.0), Vector3(1.6, 1.0, 0.6), "l17_door", GeoKit.ALL, false)
				hcyl(sb, sb.P(gx, L + 2.35, 3.4), 0.2, 3.0, true, "l17_lagging", false)
				sb.k.box(sb.P(s * 10.65, L + 1.1, 9.4), Vector3(0.6, 2.2, 3.2), "l17_black", GeoKit.ALL, true)
				for d in 10:
					var dp: Vector3 = sb.P(s * 10.33, L + 1.0 + (d % 2) * 0.55, 8.1 + int(d / 2) * 0.62)
					gauge(sb, dp, face, 0.09)
				for d in 6:
					sb.k.box(sb.P(s * 10.34, L + 0.55, 8.2 + d * 0.48), Vector3(0.02, 0.05, 0.05), "l17_dial" if d % 3 else "l17_dial_green", GeoKit.ALL, false)
				Rooms.label(sb, "SHIP SERVICE GENERATOR", sb.P(s * 10.33, L + 2.0, 9.4), face, 0.0035, Color(0.6, 0.58, 0.5), 48)
		# pipes against the hull and bulkheads
		vpipe(sb, s * 10.6, 3.0, 0.1, "l17_lagging")
		vpipe(sb, s * 10.6, 9.0, 0.08, "l17_steel")
		vpipe(sb, s * 3.9, 0.55, 0.09, "l17_pipe_red" if s > 0 else "l17_steel")
		vpipe(sb, s * 3.9, 11.45, 0.12, "l17_lagging")
		if s > 0:
			Props.place(sb.lv, sb.node, "ph/modular_pipes", sb.P(s * 10.78, L, 6.0), -s * 90.0)
		else:
			for j in 3:
				vpipe(sb, s * 10.75, 5.0 + j * 0.45, 0.07 + j * 0.02, "l17_steel" if j != 1 else "l17_lagging")
	# overhead bundles across the flat
	Rooms.pipe_x(sb, -11.0, 11.0, -0.62, 3.3, 0.12, "l17_lagging")
	Rooms.pipe_x(sb, -11.0, 11.0, -0.55, 3.65, 0.07, "l17_pipe_red")
	Rooms.pipe_x(sb, -11.0, 11.0, -0.6, 8.8, 0.1, "l17_steel")
	# centre: an evaporator shell between the two ladders, walkable round both sides
	sb.k.cylinder(sb.P(0.0, L + 1.0, 6.0), 0.65, 2.0, "l17_door", 18, true)
	sb.k.cylinder(sb.P(0.0, L + 2.05, 6.0), 0.5, 0.12, "l17_steel", 18, false)
	sb.k.cylinder(sb.P(0.0, L + 2.55, 6.0), 0.1, 0.9, "l17_steel", 8, false)
	gauge(sb, sb.P(0.0, L + 1.5, 5.34), Vector3(0, 0, 1))
	valve(sb, sb.P(0.67, L + 0.9, 6.0), Vector3(1, 0, 0), 0.15)
	# gauge board on the aft bulkhead; tools and stores along the hull
	sb.k.box(sb.P(-6.5, L + 1.5, 0.24), Vector3(2.4, 1.1, 0.06), "l17_black", GeoKit.ALL, false)
	for g in 6:
		gauge(sb, sb.P(-7.4 + (g % 3) * 0.9, L + 1.25 + int(g / 3) * 0.5, 0.29), Vector3(0, 0, -1), 0.12)
	Props.place(sb.lv, sb.node, "ph/metal_tool_chest", sb.P(-10.4, L, 1.2), 90.0, 0.0, true)
	Props.place(sb.lv, sb.node, "ph/Barrel_01", sb.P(10.3, L, 0.9), 0.0, 0.0, true)
	Props.place(sb.lv, sb.node, "ph/barrel_03", sb.P(10.3, L, 1.6), 40.0)
	sb.k.box(sb.P(-6.5, L + 0.85, 11.35), Vector3(2.4, 0.06, 0.7), "l17_wood", GeoKit.ALL, false)
	sb.k.box(sb.P(-6.5, L + 0.42, 11.35), Vector3(2.4, 0.84, 0.7), "l17_steel", 0, true)
	for lx in [-7.6, -5.4]:
		sb.k.box(sb.P(lx, L + 0.42, 11.35), Vector3(0.06, 0.84, 0.6), "l17_steel", GeoKit.ALL, false)
	sb.k.box(sb.P(-7.2, L + 1.05, 11.4), Vector3(0.6, 0.35, 0.4), "l17_pipe_red", GeoKit.ALL, false)
	sb.k.box(sb.P(-5.8, L + 0.93, 11.3), Vector3(0.3, 0.12, 0.2), "l17_steel", GeoKit.ALL, false)
	if sb.rng.randf() < 0.5:
		Props.place(sb.lv, sb.node, "ph/hand_truck", sb.P(4.4, L, 11.2), 160.0)
	Rooms.clock(sb, sb.P(4.5, L + 2.2, 0.21), Vector3(0, 0, -1), "%d-ENG" % sb.n)
	Rooms.label(sb, "ENGINEERING  %d" % sb.n, sb.P(-3.2, L + 2.35, 0.21), Vector3(0, 0, -1), 0.005, Color(0.55, 0.52, 0.45), 48)


# ------------------------------------------------------------------ passages

static func passages(sb) -> void:
	for s in [-1.0, 1.0]:
		var face := Vector3(s, 0, 0)
		var wx: float = s * 9.26
		# stiffeners on the passage face of the longitudinal bulkhead
		var u := 0.6
		while u < 11.6:
			if u < 4.7 or u > 7.3:
				sb.k.box(sb.P(s * 9.28, 1.35, u), Vector3(0.06, 2.7, 0.09), sb.paint(), GeoKit.ALL, false)
			u += 1.2
		# a cable run down the bulkhead and a junction box
		sb.k.box(sb.P(s * 9.3, 1.9, 9.6), Vector3(0.05, 1.6, 0.18), "l17_steel", GeoKit.ALL, false)
		sb.k.box(sb.P(s * 9.42, 1.2, 9.6), Vector3(0.22, 0.45, 0.38), "l17_door", GeoKit.ALL, false)
		sb.k.box(sb.P(s * 9.54, 1.3, 9.6), Vector3(0.02, 0.08, 0.08), "l17_brass", GeoKit.ALL, false)
	# fire station on the starboard side passage, phone box to port
	vpipe(sb, 10.75, 3.6, 0.06, "l17_pipe_red", 0.0, 2.7)
	valve(sb, sb.P(10.62, 1.2, 3.6), Vector3(-1, 0, 0), 0.13)
	sb.k.box(sb.P(10.8, 1.5, 4.3), Vector3(0.3, 0.7, 0.7), "l17_pipe_red", GeoKit.ALL, false)
	sb.k.cylinder(sb.P(10.6, 1.5, 4.3), 0.06, 0.5, "l17_canvas", 8, false)
	Rooms.label(sb, "FIRE PLUG 2-%d-1" % (sb.n * 10 + 3), sb.P(10.95, 2.05, 3.9), Vector3(-1, 0, 0), 0.0032, Color(0.5, 0.06, 0.04), 48)
	sb.k.box(sb.P(-10.88, 1.45, 4.2), Vector3(0.22, 0.4, 0.3), "l17_black", GeoKit.ALL, false)
	Rooms.label(sb, "SOUND POWERED\nPHONE", sb.P(-10.76, 1.78, 4.2), Vector3(1, 0, 0), 0.0024, Color(0.6, 0.6, 0.55), 40)
	# athwartship passage: stiffeners on both joiner bulkheads
	for wu in [5.06, 6.94]:
		var x := -8.85
		while x < 9.0:
			var ax := absf(x)
			if absf(ax - 6.1) > 0.65 and ax > 1.45 and not (wu < 6.0 and x > -4.95 and x < -3.55):
				sb.k.box(sb.P(x, 1.35, wu), Vector3(0.09, 2.7, 0.05), sb.paint(), GeoKit.ALL, false)
			x += 0.9
		sb.k.box(sb.P(0.0, 0.08, wu), Vector3(18.3, 0.16, 0.02), "l17_steel", GeoKit.ALL, false)
	sb.k.cylinder(sb.P(2.2, 1.0, 6.82), 0.09, 0.55, "l17_pipe_red", 10, false)
	sb.k.box(sb.P(2.2, 1.32, 6.82), Vector3(0.05, 0.1, 0.05), "l17_black", GeoKit.ALL, false)
	# athwartship passage: ventilation trunk with grilles and stencils
	sb.k.box(sb.P(0.0, 2.48, 6.75), Vector3(18.3, 0.36, 0.42), "l17_door", GeoKit.ALL, false)
	for gx in [-7.5, -2.0, 2.5, 7.0]:
		sb.k.box(sb.P(gx, 2.29, 6.75), Vector3(0.5, 0.02, 0.32), "l17_black", GeoKit.ALL, false)
	Rooms.label(sb, "NO SMOKING", sb.P(4.6, 1.75, 5.06), Vector3(0, 0, -1), 0.0042, Color(0.45, 0.06, 0.04), 48)
	Rooms.label(sb, "FR %d" % (sb.n * 10 + 5), sb.P(-1.6, 2.15, 6.94), Vector3(0, 0, 1), 0.004, Color(0.12, 0.12, 0.11), 48)
	# litter and upkeep
	var litter: int = [0, 2, 6][sb.wear]
	for i in litter:
		var p: Vector3 = sb.P(sb.rng.randf_range(-8.8, 8.8), 0.003, sb.rng.randf_range(5.2, 6.8))
		sb.k.box_xf(Transform3D(Basis(Vector3.UP, sb.rng.randf() * TAU), p), Vector3(0.21, 0.003, 0.29), "l17_paper", GeoKit.ALL, false)
	if sb.wear == 2:
		Props.place(sb.lv, sb.node, "ph/trashbag", sb.P(-10.6, 0.0, 6.9), sb.rng.randf() * 360.0)
		for i in 3:
			var q: Vector3 = sb.P(sb.rng.randf_range(-8.5, 8.5), 0.002, sb.rng.randf_range(5.1, 6.9))
			sb.k.box_xf(Transform3D(Basis(Vector3.UP, sb.rng.randf() * TAU), q), Vector3(sb.rng.randf_range(0.6, 1.4), 0.003, sb.rng.randf_range(0.4, 0.9)), "l17_sludge", GeoKit.ALL, false)
