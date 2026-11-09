extends RefCounted
## Level 17 authored sector anchors, from the page's observation table (sector
## numbers are ordered by distance from the entrance closet): 1 sludge writing,
## 8 depth-charge blast, 12 the uniformed man, 33 naval charts, 47 whispering
## closet, 67 etched mathematics, 104 infirmary (door stuck ajar), 156 Project
## RAINBOW title page, 165 skinless man at the barracks, 185 the bridge, 200-206
## the cold sectors, 217 the active machine and the fused crew.

const Rooms := preload("res://levels/L017/L017_rooms.gd")
const MATH := ["dψ/dt = -iHψ", "Σ 1/n² = π²/6", "∮ E·dl = -dΦ/dt", "x = 0.0217 t³ - 4.06", "∇×B = μ₀J", "e^{iπ} + 1 = 0",
	"217 / 42 = 5.1666…", "f(t) ≠ f(t)", "Δt₁ ≠ Δt₂ ≠ Δt₃", "1943 - 1982 = ?", "∂²u/∂x² = (1/c²) ∂²u/∂t²", "lim t→∞ (t) = 9:00",
	"a² + b² = c² + 1", "n = n + 1", "ζ(s) = Σ n⁻ˢ", "∫ dt / dt = 0", "R = 216 + 1", "sin θ / cos θ = θ", "v = λf  λ = ?", "11 × 19 = 217"]


static func plan(sb) -> void:
	match sb.n:
		8:
			sb.plan["AP"] = "wreck"
			sb.holes_up.append([-8.4, -4.4, 1.3, 4.3])
		33:
			sb.plan["FS"] = "chartroom"
		47:
			sb.plan["FP"] = "storage"
		104:
			sb.plan["AS"] = "infirmary"
		156:
			sb.plan["FP"] = "schematics"
		165:
			sb.plan["AP"] = "barracks_blocked"
		185:
			sb.plan["FP"] = "bridge"
		217:
			sb.plan["FP"] = "machine"
			sb.plan["FS"] = "machine"


static func dress(sb) -> void:
	match sb.n:
		1:
			_sludge(sb)
			_closet(sb)
		8:
			_blast(sb)
		12:
			sb.meta["figures"].append({"kind": "sailor", "pos": sb.P(-7.6, 0.0, 6.0), "yaw": -90.0, "watch": true, "home": sb.P(-7.6, 0.0, 6.0)})
		33:
			_charts(sb)
		47:
			_whisper_closet(sb)
		67:
			_mathematics(sb)
		104:
			_infirmary(sb)
		156:
			_rainbow(sb)
		165:
			sb.meta["figures"].append({"kind": "skinless", "pos": sb.P(-6.1, 0.0, Rooms.PA + 0.45), "yaw": 180.0, "watch": true, "block": true})
			sb.k.box(sb.P(-6.1, 1.0, Rooms.PA + 0.3), Vector3(0.9, 2.0, 0.5), "l17_rail", 0, true)
		185:
			_bridge(sb)
		217:
			_machine(sb)
	if sb.n >= 200 and sb.n <= 206:
		_cold(sb)


# ------------------------------------------------------------------ figures

static func mannequin(kind: String) -> Node3D:
	var n := Node3D.new()
	var body_mat := {"sailor": "l17_navy", "dungarees": "l17_dungaree", "skinless": "l17_skinless"}.get(kind, "l17_sheet") as String
	var head_mat := "l17_skinless" if kind == "skinless" else "l17_skin"
	if kind == "remains":
		var lump := _cap(n, 0.24, 1.75, "l17_sheet")
		lump.rotation.z = PI * 0.5
		lump.position = Vector3(0, 0.16, 0)
		lump.scale = Vector3(1.0, 1.0, 0.75)
		var feet := _cap(n, 0.12, 0.4, "l17_sheet")
		feet.position = Vector3(0.95, 0.16, 0.12)
		feet.rotation.z = PI * 0.5
		return n
	var legs := _cap(n, 0.16, 0.95, "l17_navy" if kind != "skinless" else "l17_skinless")
	legs.position = Vector3(0, 0.48, 0)
	legs.scale = Vector3(1.15, 1.0, 0.8)
	var torso := _cap(n, 0.21, 0.78, body_mat)
	torso.position = Vector3(0, 1.22, 0)
	torso.scale = Vector3(1.05, 1.0, 0.7)
	for s in [-1.0, 1.0]:
		var arm := _cap(n, 0.06, 0.72, body_mat)
		arm.position = Vector3(s * 0.27, 1.17, 0.0)
		arm.rotation.z = s * 0.06
	var head := _cap(n, 0.11, 0.27, head_mat)
	head.position = Vector3(0, 1.7, 0)
	head.name = "Head"
	if kind == "sailor":
		var cap := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.13
		cm.bottom_radius = 0.11
		cm.height = 0.07
		cap.mesh = cm
		cap.material_override = MatLib.get_mat("l17_white")
		cap.position = Vector3(0, 1.83, 0)
		n.add_child(cap)
		var collar := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.36, 0.2, 0.02)
		collar.mesh = bm
		collar.material_override = MatLib.get_mat("l17_navy")
		collar.position = Vector3(0, 1.48, 0.14)
		n.add_child(collar)
	return n


static func _cap(parent: Node3D, r: float, h: float, mat: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = r
	cm.height = h
	cm.radial_segments = 12
	cm.rings = 4
	mi.mesh = cm
	mi.material_override = MatLib.get_mat(mat)
	parent.add_child(mi)
	return mi


# ------------------------------------------------------------------ anchors

static func _sludge(sb) -> void:
	# next to the first bulkhead door, on the port passage wall, in coagulated oil
	var p: Vector3 = sb.P(-9.14, 1.45, 10.9)
	sb.k.box(p + Vector3(0.012, -0.05, 0), Vector3(0.01, 0.9, 1.5), "l17_sludge", GeoKit.ALL, false)
	for i in 5:
		sb.k.box(p + Vector3(0.016, -0.55 - i * 0.07, -0.6 + i * 0.27), Vector3(0.01, 0.35 + i * 0.05, 0.035), "l17_sludge", GeoKit.ALL, false)
	var l := Rooms.label(sb, "We co me  to th\nEl  ri ge", p + Vector3(0.01, 0.05, 0), Vector3(1, 0, 0), 0.0065, Color(0.05, 0.035, 0.02), 64)
	l.line_spacing = -6.0
	Rooms.note(sb, "l17_sludge", "Writing beside the first bulkhead door",
		"Smeared beside the door in something thick and dark, like oil left to clot: \"We co me to th El ri ge\". Five of the letters can no longer be read.",
		p + Vector3(-0.4, -0.4, 0), Vector3(0.7, 1.4, 1.6))


static func _closet(sb) -> void:
	# the entrance closet set into sector 1's aft bulkhead, port passage
	var x := -10.1
	for s in [-1.0, 1.0]:
		sb.bmm(x + s * 0.36, 0.0, -1.25, x + s * 0.46, 2.0, -0.2, "l17_locker")
	sb.bmm(x - 0.46, 0.0, -1.35, x + 0.46, 2.0, -1.25, "l17_locker")
	sb.bmm(x - 0.46, 1.9, -1.35, x + 0.46, 2.05, -0.2, "l17_locker")
	sb.bmm(x - 0.36, 0.0, -1.25, x + 0.36, 0.02, -0.2, "l17_steel", GeoKit.PY)
	for y in [0.5, 1.1]:
		sb.bmm(x - 0.36, y, -1.2, x + 0.36, y + 0.03, -0.95, "l17_steel", GeoKit.ALL, false)
	sb.bmm(x - 0.1, 1.13, -1.2, x + 0.25, 1.4, -0.9, "l17_paper", GeoKit.ALL, false)
	sb.bmm(x - 0.3, 0.53, -1.15, x - 0.05, 0.85, -0.95, "l17_steel", GeoKit.ALL, false)
	# the door leaf stands open against the bulkhead
	sb.k.box(sb.P(x + 0.72, 0.97, 0.26), Vector3(0.7, 1.9, 0.04), "l17_locker", GeoKit.ALL, false)
	sb.k.box(sb.P(x + 0.95, 1.0, 0.3), Vector3(0.1, 0.04, 0.04), "l17_brass", GeoKit.ALL, false)
	Rooms.label(sb, "STORES", sb.P(x, 2.06, 0.22), Vector3(0, 0, -1), 0.003, Color(0.1, 0.1, 0.1), 48)


static func _blast(sb) -> void:
	# a small explosion tore up the port compartment and the deck under it
	var L: float = Rooms.LOW
	for i in 9:
		var p: Vector3 = sb.P(sb.rng.randf_range(-8.6, -4.0), L + 0.1, sb.rng.randf_range(1.2, 4.6))
		var xf: Transform3D = Transform3D(Basis.from_euler(Vector3(sb.rng.randf_range(-0.9, 0.9), sb.rng.randf() * TAU, sb.rng.randf_range(-0.9, 0.9))), p)
		sb.k.box_xf(xf, Vector3(sb.rng.randf_range(0.6, 1.6), 0.03, sb.rng.randf_range(0.4, 1.1)), "l17_scorch", GeoKit.ALL, false)
	sb.k.box(sb.P(-6.4, L + 0.35, 2.8), Vector3(2.4, 0.7, 2.0), "l17_scorch", GeoKit.ALL, true)
	# curled plates at the hole's edge, scorch across the walls and the overhead
	for i in 7:
		var u := 1.4 + i * 0.45
		var xf: Transform3D = Transform3D(Basis.from_euler(Vector3(sb.rng.randf_range(-0.5, 0.5), 0, sb.rng.randf_range(0.4, 1.1))), sb.P(-4.3 - sb.rng.randf() * 0.2, -0.15, u))
		sb.k.box_xf(xf, Vector3(0.7, 0.025, 0.4), "l17_scorch", GeoKit.ALL, false)
	sb.bmm(-9.15, 0.0, 0.25, -9.13, 2.6, 4.9, "l17_scorch", GeoKit.ALL, false)
	sb.bmm(-8.9, 2.68, 0.4, -3.2, 2.69, 4.8, "l17_scorch", GeoKit.NY, false)
	sb.bmm(-3.05, 0.0, 0.3, -3.04, 2.6, 4.8, "l17_scorch", GeoKit.ALL, false)
	for i in 24:
		var fp: Vector3 = sb.P(sb.rng.randf_range(-9.0, -3.3), 0.03, sb.rng.randf_range(4.6, 6.8))
		sb.k.box_xf(Transform3D(Basis.from_euler(Vector3(sb.rng.randf(), sb.rng.randf() * TAU, sb.rng.randf())), fp), Vector3(0.12, 0.05, 0.2) * sb.rng.randf_range(0.5, 1.5), "l17_scorch", GeoKit.ALL, false)
	sb.meta["lights_low"].append([sb.P(-6.4, -1.2, 2.8), Color(1.0, 0.55, 0.3), 0.6, 5.0, 0.25])
	Rooms.note(sb, "l17_blast", "Sector 8: blast damage",
		"Plating curled outward, scorch to the overhead, the deck torn through to the engine flat below. The fragments match Mk. 6 depth-charge casings, per the survey.",
		sb.P(-5.0, 1.0, 5.4), Vector3(1.4, 2.0, 0.6))


static func _charts(sb) -> void:
	var r: Array = Rooms.ROOMS["FS"]
	var cx := (float(r[0]) + float(r[1])) * 0.5
	sb.k.box(sb.P(cx, 0.9, 9.6), Vector3(2.6, 0.05, 1.4), "l17_wood", GeoKit.ALL, false)
	sb.k.box(sb.P(cx, 0.45, 9.6), Vector3(2.5, 0.9, 1.3), "l17_steel", 0, true)
	for i in 3:
		var xf: Transform3D = Transform3D(Basis(Vector3.UP, sb.rng.randf_range(-0.2, 0.2)), sb.P(cx - 0.8 + i * 0.8, 0.93 + i * 0.003, 9.6))
		sb.k.box_xf(xf, Vector3(0.9, 0.003, 0.65), "l17_chart", GeoKit.ALL, false)
	var titles := ["WESTERN NORTH ATLANTIC", "DELAWARE RIVER\nPHILADELPHIA TO THE SEA", "EAST COAST OF THE UNITED STATES"]
	for i in 3:
		var p: Vector3 = sb.P(r[0] + 0.9 + i * 2.0, 1.6, 11.74)
		sb.k.box(p, Vector3(1.4, 1.0, 0.01), "l17_chart", GeoKit.ALL, false)
		Rooms.label(sb, titles[i], p + Vector3(0, 0.38, 0.0), Vector3(0, 0, 1), 0.0022, Color(0.1, 0.12, 0.2), 48)
	Rooms.label(sb, "HARBOR REGISTRY - NEW YORK\nHARBOR REGISTRY - PHILADELPHIA", sb.P(cx, 0.94, 9.2), Vector3(0, 1, 0), 0.0016, Color(0.1, 0.1, 0.15), 48)
	Rooms.note(sb, "l17_charts", "Sector 33: naval charts",
		"Charts of the western Atlantic, the Delaware River and the US east coast, pencilled with courses. Harbor registries for New York and Philadelphia are clipped to them.",
		sb.P(cx, 1.0, 9.6), Vector3(2.6, 0.6, 1.6))


static func _whisper_closet(sb) -> void:
	var p: Vector3 = sb.P(3.9, 1.0, Rooms.PF - 0.3)
	sb.k.box(p, Vector3(1.0, 2.0, 0.5), "l17_locker", GeoKit.ALL, true)
	sb.k.box(p + Vector3(0, 0.0, 0.255), Vector3(0.02, 1.9, 0.01), "l17_steel", GeoKit.ALL, false)
	Rooms.label(sb, "STORES  2-%d-0-A" % (sb.n * 10 + 1), p + Vector3(0, 1.08, 0.25), Vector3(0, 0, 1), 0.0026, Color(0.1, 0.1, 0.1), 48)
	sb.meta["fx"].append({"kind": "whisper_closet", "pos": p + Vector3(0, 0, 0.6)})


static func _mathematics(sb) -> void:
	var col := Color(0.16, 0.16, 0.14)
	var spots: Array = []
	for u in [0.8, 2.0, 3.2, 4.4, 7.6, 8.8, 10.0, 11.2]:
		for y in [0.7, 1.3, 1.9]:
			spots.append([sb.P(-9.26, y, u), Vector3(-1, 0, 0)])
			spots.append([sb.P(9.26, y, u), Vector3(1, 0, 0)])
			spots.append([sb.P(-10.94, y, u), Vector3(1, 0, 0)])
			spots.append([sb.P(10.94, y, u), Vector3(-1, 0, 0)])
	for x in [-8.0, -5.0, -2.0, 1.5, 4.5, 7.5]:
		for y in [0.8, 1.5, 2.2]:
			spots.append([sb.P(x, y, Rooms.PA + 0.06), Vector3(0, 0, -1)])
			spots.append([sb.P(x, y, Rooms.PF - 0.06), Vector3(0, 0, 1)])
	for x in [-10.5, -9.6, 9.6, 10.5]:
		for y in [0.6, 1.2, 1.8, 2.4]:
			spots.append([sb.P(x, y, 0.21), Vector3(0, 0, -1)])
	for s in spots:
		var t: String = MATH[sb.rng.randi() % MATH.size()]
		if sb.rng.randf() < 0.5:
			t += "\n" + MATH[sb.rng.randi() % MATH.size()]
		var l: Label3D = Rooms.label(sb, t, s[0] + Vector3(sb.rng.randf_range(-0.15, 0.15), 0, 0), s[1], 0.0026, col, 40)
		l.rotate_object_local(Vector3(0, 0, 1), sb.rng.randf_range(-0.08, 0.08))
	Rooms.note(sb, "l17_math", "Sector 67: etched mathematics",
		"Every bulkhead here is scratched with equations, over almost every bare surface. Most of it means nothing; some lines repeat 217 and 42, and one insists the time is always the same.",
		sb.P(-4.25, 1.2, Rooms.PA + 0.4), Vector3(1.2, 1.2, 0.6))


static func _infirmary(sb) -> void:
	var r: Array = Rooms.ROOMS["AS"]
	# the door is stuck ajar: the leaf hangs open a hand's width, jammed from inside
	var hinge: Vector3 = sb.P(6.1 + 0.41, 0.98, Rooms.PA)
	var xf := Transform3D(Basis(Vector3.UP, deg_to_rad(-25.0)), hinge + Vector3(-0.36, 0, 0.17))
	sb.k.box_xf(xf, Vector3(0.8, 1.94, 0.05), "l17_door", GeoKit.ALL, true)
	sb.k.box(sb.P(6.1, 1.0, Rooms.PA - 0.25), Vector3(0.82, 2.0, 0.3), "l17_door", 0, true)
	# inside: bunks and the floor covered in sheeted shapes, more than anyone could count
	for i in 4:
		Rooms.rack(sb, r[0] + 0.8 + i * 1.5, 1.0, false, 2)
	for i in 22:
		var lump := mannequin("remains")
		sb.node.add_child(lump)
		var tier := i % 3
		lump.position = sb.P(r[0] + 0.8 + (i % 4) * 1.5 + sb.rng.randf_range(-0.1, 0.1), [0.42, 1.06, 0.0][tier], 1.0 + (0.0 if tier < 2 else sb.rng.randf_range(1.0, 3.6)))
		lump.rotation.y = PI * 0.5 + (0.0 if tier < 2 else sb.rng.randf_range(-0.8, 0.8))
	sb.meta["lights_up"].append([sb.P(6.1, 2.2, 2.5), Color(0.75, 0.82, 0.9), 0.35, 4.0, 0.15])
	Rooms.bulb(sb, sb.P(6.1, 2.7, 2.5), false)
	Rooms.note(sb, "l17_infirmary", "Sector 104: the infirmary",
		"The door will open no wider than a hand: something heavy is piled against it. Through the gap, sheeted shapes fill the bunks and the deck. Adult men, the survey says; it does not give a number.",
		sb.P(6.1, 1.2, Rooms.PA + 0.5), Vector3(1.2, 2.0, 0.6))


static func _rainbow(sb) -> void:
	var r: Array = Rooms.ROOMS["FP"]
	var cx := (float(r[0]) + float(r[1])) * 0.5
	sb.k.box(sb.P(cx, 0.85, 9.0), Vector3(2.0, 0.05, 1.2), "l17_wood", GeoKit.ALL, false)
	sb.k.box(sb.P(cx, 0.42, 9.0), Vector3(1.9, 0.84, 1.1), "l17_steel", 0, true)
	for i in 4:
		var xf: Transform3D = Transform3D(Basis(Vector3.UP, sb.rng.randf_range(-0.3, 0.3)), sb.P(cx - 0.6 + i * 0.4, 0.876 + i * 0.002, 9.0 + sb.rng.randf_range(-0.2, 0.2)))
		sb.k.box_xf(xf, Vector3(0.6, 0.002, 0.45), "l17_blueprint", GeoKit.ALL, false)
	sb.k.box(sb.P(cx + 0.55, 0.882, 8.8), Vector3(0.3, 0.002, 0.42), "l17_paper", GeoKit.ALL, false)
	Rooms.label(sb, "CONFIDENTIAL\n\nPROJECT\nRAINBOW", sb.P(cx + 0.55, 0.885, 8.8), Vector3(0, 1, 0), 0.0012, Color(0.25, 0.04, 0.03), 48)
	Rooms.note(sb, "l17_rainbow", "Sector 156: the title page",
		"The schematics found in every sector have a cover sheet here. It is stamped CONFIDENTIAL and titled \"Project RAINBOW\". Nothing on it says what the machine is for.",
		sb.P(cx, 1.0, 9.0), Vector3(2.0, 0.6, 1.4))


static func _bridge(sb) -> void:
	# the door marked BRIDGE stays shut; behind it, infants (survey count 216)
	var p: Vector3 = sb.P(-6.1, 1.0, Rooms.PF - 0.3)
	sb.meta["fx"].append({"kind": "bridge", "pos": p})
	Rooms.note(sb, "l17_bridge", "Sector 185: the bridge",
		"Behind the door marked BRIDGE: crying, from far too many small voices, and a smell that comes through the seams. The survey counted 216 living infants in there. You do not open it.",
		p, Vector3(1.2, 2.0, 0.6))


static func _cold(sb) -> void:
	for i in 10:
		var p: Vector3 = sb.P(sb.rng.randf_range(-10.8, 10.8), 0.005, sb.rng.randf_range(0.4, 11.6))
		var xf: Transform3D = Transform3D(Basis(Vector3.UP, sb.rng.randf() * TAU), p)
		sb.k.box_xf(xf, Vector3(sb.rng.randf_range(0.6, 2.4), 0.004, sb.rng.randf_range(0.5, 1.6)), "l17_frost", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		sb.bmm(s * 10.94, 0.0, 0.3, s * 10.92, 2.6, 11.7, "l17_frost", GeoKit.ALL, false)
	var tp: Vector3 = sb.P(-1.6, 1.5, Rooms.PA + 0.06)
	sb.k.box(tp, Vector3(0.12, 0.4, 0.03), "l17_white", GeoKit.ALL, false)
	sb.k.box(tp + Vector3(0, -0.05, -0.02), Vector3(0.015, 0.28, 0.01), "l17_pipe_red", GeoKit.ALL, false)
	sb.meta["fx"].append({"kind": "thermometer", "pos": tp + Vector3(0, 0, -0.3)})


static func _machine(sb) -> void:
	# The fore compartments are one machine space. The machine stands against the
	# end bulkhead: racks of vacuum tubes round a blue-lit core.
	var L := 11.75
	sb.k.box(sb.P(0, 1.2, L - 0.45), Vector3(7.0, 2.4, 0.9), "l17_black", GeoKit.ALL, true)
	for i in 6:
		sb.k.box(sb.P(0, 0.35 + i * 0.36, L - 0.92), Vector3(6.8, 0.03, 0.12), "l17_steel", GeoKit.ALL, false)
	for x in [-3.5, -1.2, 1.2, 3.5]:
		sb.k.box(sb.P(x, 1.2, L - 0.92), Vector3(0.08, 2.4, 0.14), "l17_steel", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		sb.k.box(sb.P(s * 6.3, 1.0, L - 0.6), Vector3(2.6, 2.0, 1.2), "l17_black", GeoKit.ALL, true)
		for d in 6:
			sb.k.box(sb.P(s * 6.3 - 0.9 + d * 0.36, 1.5, L - 1.21), Vector3(0.18, 0.18, 0.02), "l17_blue_dim", GeoKit.ALL, false)
	sb.k.cylinder(sb.P(0, 1.25, 9.4), 0.55, 2.5, "l17_blue", 20, true)
	sb.k.cylinder(sb.P(0, 0.08, 9.4), 0.8, 0.16, "l17_steel", 20, false)
	sb.k.cylinder(sb.P(0, 2.6, 9.4), 0.8, 0.16, "l17_steel", 20, false)
	for a in 8:
		var ang := TAU * a / 8.0
		sb.k.box(sb.P(cos(ang) * 0.72, 1.3, 9.4 + sin(ang) * 0.72), Vector3(0.04, 2.5, 0.04), "l17_brass", GeoKit.ALL, false)
	for i in 10:
		var u: float = 9.0 + sb.rng.randf_range(-1.5, 2.0)
		sb.k.box(sb.P(sb.rng.randf_range(-5.0, 5.0), 0.04, u), Vector3(sb.rng.randf_range(1.0, 3.0), 0.05, 0.05), "l17_black", GeoKit.ALL, false)
	sb.meta["fx"].append({"kind": "machine", "pos": sb.P(0, 1.4, 9.4), "tubes": [sb.P(-3.4, 0.37, L - 0.95), sb.P(3.4, 2.19, L - 0.95)]})
	sb.meta["lights_up"].append([sb.P(0, 2.3, 8.0), Color(0.35, 0.55, 1.0), 1.4, 9.0, 0.3])
	sb.meta["lights_up"].append([sb.P(0, 2.2, 5.6), Color(0.35, 0.55, 1.0), 0.8, 7.0, 0.2])
	Rooms.note(sb, "l17_machine", "Sector 217: the machine",
		"The machine from the schematics, built and running: thousands of tubes, a blue light, a high thin tone and a knocking from inside. The only active one ever found.",
		sb.P(0, 1.0, 7.6), Vector3(3.0, 2.0, 0.8))
	sb.meta["fx"].append({"kind": "fused", "count": 216})
