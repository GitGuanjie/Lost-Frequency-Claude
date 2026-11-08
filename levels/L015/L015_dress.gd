extends RefCounted
## Level 15 dressing: the camp, consoles, machines (spinning flywheel, the rod
## press), the dead in lab coats with their makeshift weapons, dried blood, the
## piled Hound corpses, the storage shelves and the wrecked engine room.

const G := preload("res://levels/L015/L015_geo.gd")

var lvl
var k: GeoKit          # dressing geometry (no collision unless asked)
var fx: GeoKit
var props := 0
var corpses := 0
var hounds := 0
var rods: Array = []        # moving rods on the conveyor
var pile: Array = []        # rods in the bin (hidden until produced)
var wheel: Node3D


func _init(level, dress: GeoKit, faces: GeoKit) -> void:
	lvl = level
	k = dress
	fx = faces


static func materials() -> void:
	var m := func(n: String, base: String, x: Dictionary) -> void:
		MatLib.define(n, x, base)
	m.call("l15_coat", "plaster", {"albedo_a": Color(0.74, 0.73, 0.68), "albedo_b": Color(0.66, 0.64, 0.58), "noise_scale": 3.0,
		"stain_amount": 0.5, "stain_color": Color(0.4, 0.3, 0.2), "stain_scale": 2.0, "bump_strength": 0.5})
	m.call("l15_trousers", "plaster", {"albedo_a": Color(0.13, 0.14, 0.16), "albedo_b": Color(0.1, 0.11, 0.12), "noise_scale": 3.0})
	m.call("l15_skin", "plaster", {"albedo_a": Color(0.3, 0.21, 0.14), "albedo_b": Color(0.22, 0.15, 0.1), "noise_scale": 6.0, "bump_strength": 1.2})
	m.call("l15_hair", "plaster", {"albedo_a": Color(0.06, 0.05, 0.05), "albedo_b": Color(0.1, 0.08, 0.06)})
	m.call("l15_blood", "plaster", {"albedo_a": Color(0.14, 0.045, 0.03), "albedo_b": Color(0.2, 0.07, 0.04), "noise_scale": 5.0,
		"roughness_a": 0.7, "roughness_b": 0.9, "bump_strength": 0.3})
	m.call("l15_char", "concrete_dark", {"albedo_a": Color(0.05, 0.045, 0.04), "albedo_b": Color(0.09, 0.08, 0.07), "bump_strength": 1.6, "wetness": 0.0})
	m.call("l15_ash", "concrete", {"albedo_a": Color(0.42, 0.41, 0.39), "albedo_b": Color(0.33, 0.32, 0.3), "noise_scale": 4.0, "stain_amount": 0.0})
	m.call("l15_tape", "plaster", {"albedo_a": Color(0.5, 0.48, 0.42), "albedo_b": Color(0.44, 0.42, 0.37), "roughness_a": 0.6})
	m.call("l15_console", "metal", {"albedo_a": Color(0.78, 0.8, 0.82), "albedo_b": Color(0.72, 0.74, 0.76), "metallic_value": 0.3, "roughness_a": 0.35})
	m.call("l15_carton", "plaster", {"albedo_a": Color(0.55, 0.42, 0.27), "albedo_b": Color(0.48, 0.36, 0.22), "noise_scale": 4.0})
	m.call("l15_jug_cap", "plaster", {"albedo_a": Color(0.1, 0.3, 0.6), "albedo_b": Color(0.1, 0.28, 0.55)})
	m.call("l15_mattress", "plaster", {"albedo_a": Color(0.34, 0.4, 0.46), "albedo_b": Color(0.3, 0.35, 0.4), "noise_scale": 3.0, "bump_strength": 0.7})
	MatLib.register("l15_screen", MatLib.panel(Color(0.04, 0.16, 0.14), 1.0))
	MatLib.register("l15_screen_text", MatLib.panel(Color(0.35, 0.95, 0.7), 1.3, 0.0))
	var jug := StandardMaterial3D.new()
	jug.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	jug.albedo_color = Color(0.82, 0.9, 0.95, 0.55)
	jug.roughness = 0.25
	MatLib.register("l15_jug", jug)
	var rod := StandardMaterial3D.new()
	rod.albedo_color = Color(0.62, 0.64, 0.68)
	rod.metallic = 0.9
	rod.roughness = 0.3
	MatLib.register("l15_rod", rod)


func p(parent: Node3D, id: String, pos: Vector3, yaw := 0.0, h := 0.0, collide := false) -> Node3D:
	var n: Node3D = Props.place(lvl, parent, id, pos, yaw, h, collide)
	if n:
		props += 1
	return n


## Box in a local frame (o = origin transform), with local yaw/pitch/roll in degrees.
func bx(o: Transform3D, lp: Vector3, size: Vector3, mat: String, ypr := Vector3.ZERO) -> void:
	var b := Basis.from_euler(Vector3(deg_to_rad(ypr.y), deg_to_rad(ypr.x), deg_to_rad(ypr.z)))
	k.box_xf(o * Transform3D(b, lp), size, mat, GeoKit.ALL, false)


## Dried blood: overlapping flat irregular patches.
func blood(c: Vector3, r: float, rr: RandomNumberGenerator, trail := Vector3.ZERO) -> void:
	for i in 5:
		var off := Vector3(rr.randf_range(-r, r) * 0.6, 0, rr.randf_range(-r, r) * 0.6)
		var s := rr.randf_range(0.5, 1.0) * r
		k.box_xf(Transform3D(Basis(Vector3.UP, rr.randf() * PI), c + off + Vector3(0, 0.004 + 0.0007 * i, 0)),
			Vector3(s * rr.randf_range(0.8, 1.6), 0.004, s), "l15_blood", GeoKit.ALL, false)
	if trail != Vector3.ZERO:
		var d := trail - c
		k.box_xf(Transform3D(Basis.looking_at(Vector3(d.x, 0, d.z), Vector3.UP), (c + trail) * 0.5 + Vector3(0, 0.003, 0)),
			Vector3(0.22, 0.004, Vector2(d.x, d.z).length()), "l15_blood", GeoKit.ALL, false)


## A desiccated body in a lab coat, lying on its back (feet toward +z local).
## weapon: "" | "knife" | "spear".
func corpse(pos: Vector3, yaw: float, rr: RandomNumberGenerator, weapon := "", slump := false) -> void:
	corpses += 1
	var o := Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), pos)
	if slump:
		# sitting against a wall, head dropped forward, legs out along +z
		bx(o, Vector3(0, 0.45, -0.05), Vector3(0.42, 0.62, 0.24), "l15_coat", Vector3(0, -12, 0))
		bx(o, Vector3(0, 0.2, 0.15), Vector3(0.44, 0.2, 0.4), "l15_coat")
		for sx in [-0.11, 0.11]:
			bx(o, Vector3(sx, 0.08, 0.6), Vector3(0.14, 0.13, 0.75), "l15_trousers", Vector3(sx * 40.0, 0, 0))
			bx(o, Vector3(sx * 1.3, 0.07, 1.02), Vector3(0.11, 0.12, 0.26), "l15_hair")
			bx(o, Vector3(sx * 2.6, 0.32, 0.12), Vector3(0.1, 0.1, 0.5), "l15_coat", Vector3(sx * 60.0, 30, 0))
		bx(o, Vector3(0, 0.82, 0.06), Vector3(0.17, 0.2, 0.2), "l15_skin", Vector3(0, -35, 8))
		bx(o, Vector3(0, 0.9, 0.0), Vector3(0.18, 0.08, 0.2), "l15_hair", Vector3(0, -35, 8))
		blood(pos + o.basis * Vector3(0.1, 0, 0.3), 0.55, rr)
	else:
		bx(o, Vector3(0, 0.11, -0.35), Vector3(0.44, 0.2, 0.55), "l15_coat")
		bx(o, Vector3(0, 0.1, 0.05), Vector3(0.42, 0.18, 0.32), "l15_coat")
		bx(o, Vector3(0.04, 0.012, 0.15), Vector3(0.66, 0.02, 0.6), "l15_coat", Vector3(rr.randf_range(-8, 8), 0, 0))
		var spread := rr.randf_range(4.0, 14.0)
		for sx in [-0.11, 0.11]:
			bx(o, Vector3(sx, 0.08, 0.52), Vector3(0.15, 0.14, 0.8), "l15_trousers", Vector3(sx / 0.11 * spread, 0, 0))
			bx(o, Vector3(sx * 1.5, 0.08, 0.96), Vector3(0.11, 0.1, 0.27), "l15_hair", Vector3(sx / 0.11 * spread, 0, 0))
		bx(o, Vector3(-0.3, 0.07, -0.32), Vector3(0.11, 0.1, 0.56), "l15_coat", Vector3(-6, 0, 0))
		bx(o, Vector3(0.48, 0.07, -0.6), Vector3(0.11, 0.1, 0.56), "l15_coat", Vector3(rr.randf_range(50, 80), 0, 0))
		bx(o, Vector3(-0.31, 0.04, -0.02), Vector3(0.08, 0.04, 0.15), "l15_skin")
		bx(o, Vector3(0.72, 0.04, -0.78), Vector3(0.08, 0.04, 0.15), "l15_skin", Vector3(70, 0, 0))
		bx(o, Vector3(0, 0.1, -0.76), Vector3(0.17, 0.16, 0.22), "l15_skin", Vector3(rr.randf_range(-25, 25), 0, 0))
		bx(o, Vector3(0, 0.1, -0.84), Vector3(0.18, 0.17, 0.1), "l15_hair", Vector3(rr.randf_range(-25, 25), 0, 0))
		blood(pos + o.basis * Vector3(0.1, 0, -0.45), 0.7, rr, pos + o.basis * Vector3(rr.randf_range(-1.0, 1.0), 0, -2.2))
	match weapon:
		"knife":
			var kp := pos + o.basis * Vector3(0.95, 0.012, -0.55)
			var kb := Basis(Vector3.UP, rr.randf() * TAU)
			k.box_xf(Transform3D(kb, kp), Vector3(0.03, 0.006, 0.17), "l15_steel", GeoKit.ALL, false)
			k.box_xf(Transform3D(kb, kp + kb * Vector3(0, 0.006, 0.13)), Vector3(0.035, 0.025, 0.11), "l15_tape", GeoKit.ALL, false)
		"spear":
			var sp := pos + o.basis * Vector3(-0.7, 0.02, 0.1)
			var sb := Basis(Vector3.UP, deg_to_rad(yaw + rr.randf_range(-30.0, 30.0)))
			k.box_xf(Transform3D(sb, sp), Vector3(0.035, 0.035, 1.9), "l15_steel", GeoKit.ALL, false)
			k.box_xf(Transform3D(sb, sp + sb * Vector3(0, 0, -1.02)), Vector3(0.05, 0.008, 0.24), "l15_beam", GeoKit.ALL, false)
			k.box_xf(Transform3D(sb, sp + sb * Vector3(0, 0, -0.86)), Vector3(0.06, 0.05, 0.12), "l15_tape", GeoKit.ALL, false)


## A charred Hound corpse (pile element). o = full transform.
func hound(o: Transform3D, rr: RandomNumberGenerator) -> void:
	hounds += 1
	o = o.scaled_local(Vector3(1.6, 1.6, 1.6))
	bx(o, Vector3(0, 0, 0), Vector3(0.38, 0.3, 0.95), "l15_char")
	bx(o, Vector3(0, 0.02, -0.62), Vector3(0.24, 0.22, 0.3), "l15_char", Vector3(rr.randf_range(-30, 30), rr.randf_range(-20, 20), 0))
	for sx in [-0.17, 0.17]:
		bx(o, Vector3(sx, -0.12, -0.32), Vector3(0.09, 0.09, 0.62), "l15_char", Vector3(sx * 120.0, 40, 0))
		bx(o, Vector3(sx, -0.1, 0.42), Vector3(0.1, 0.1, 0.7), "l15_char", Vector3(sx * 90.0, -30, 0))
	bx(o, Vector3(0, 0.12, 0.1), Vector3(0.3, 0.06, 0.6), "l15_ash")


# ------------------------------------------------------------------ rooms

func control_room(node: Node3D, rr: RandomNumberGenerator) -> void:
	# two curved rows of consoles facing the radar wall, centre aisle left clear
	for row in [[-9.5, 3.0], [-14.5, 2.0]]:
		var z: float = row[0]
		for side in [-1.0, 1.0]:
			for i in int(row[1]):
				var x: float = side * (3.4 + float(i) * 2.2)
				if x > 8.0:
					continue
				var a := deg_to_rad(side * -6.0 * float(i))
				var o := Transform3D(Basis(Vector3.UP, a), Vector3(x, 0, z))
				bx(o, Vector3(0, 0.4, 0), Vector3(2.0, 0.8, 0.75), "l15_console")
				bx(o, Vector3(0, 0.9, -0.12), Vector3(2.0, 0.08, 0.7), "l15_console", Vector3(-22, 0, 0))
				bx(o, Vector3(0, 1.2, -0.42), Vector3(1.9, 0.62, 0.06), "l15_steel", Vector3(-8, 0, 0))
				var sc := o * Transform3D(Basis.from_euler(Vector3(deg_to_rad(-8), 0, 0)), Vector3(0, 1.2, -0.385))
				fx.quad(sc.origin, sc.basis.z, sc.basis.x * 0.85, sc.basis.y * 0.26, "l15_screen", Vector2.ZERO, true)
				for li in 3:
					fx.box_xf(sc * Transform3D(Basis(), Vector3(-0.5 + float(li) * 0.18, 0.12 - float(li) * 0.07, 0.006)), Vector3(0.5, 0.02, 0.002), "l15_screen_text", GeoKit.ALL, false)
				k.box_xf(o * Transform3D(Basis(), Vector3(0, 0.4, 0)), Vector3(2.0, 0.8, 0.75), "l15_console", 0, true)
				var ch := p(node, "kenney/space-kit/desk-chair", o * Vector3(rr.randf_range(-0.4, 0.4), 0, 0.85), rad_to_deg(a) + rr.randf_range(-40, 40), 1.0)
				if ch and rr.randf() < 0.25:
					ch.rotation.z = PI * 0.5
					ch.position.y += 0.25
	# equipment racks along the west wall, indicators blinking
	var z := -5.0
	while z > -20.0:
		k.box(Vector3(-13.3, 1.3, z), Vector3(0.8, 2.6, 1.1), "l15_steel", GeoKit.ALL, true)
		for j in 4:
			fx.box(Vector3(-12.89, 0.6 + float(j) * 0.5, z + rr.randf_range(-0.4, 0.4)), Vector3(0.02, 0.04, 0.06),
				["l15_green", "l15_amber", "l15_green", "l15_cyan"][rr.randi() % 4], GeoKit.ALL, false)
		z -= 1.25
	p(node, "ph/power_box_01", Vector3(-13.6, 1.3, -21.0), 90.0)
	p(node, "ph/modular_electric_cables", Vector3(-13.75, 3.2, -12.0), 90.0)
	p(node, "ph/security_camera_01", Vector3(13.6, 7.0, -1.0), -135.0)
	p(node, "ph/fire_alarm", Vector3(2.6, 1.5, -0.2), 180.0)
	p(node, "ph/korean_fire_extinguisher_01", Vector3(-2.8, 0.0, -0.45), 0.0)
	# Enric's camp on the operator gallery (+3.4 m)
	var g := 3.4
	k.box(Vector3(12.7, g + 0.12, -18.6), Vector3(1.0, 0.24, 2.1), "l15_mattress", GeoKit.ALL, false)
	p(node, "kenney/furniture-kit/pillowlong", Vector3(12.7, g + 0.26, -19.4), 0.0, 0.2)
	k.box(Vector3(12.6, g + 0.25, -18.3), Vector3(0.95, 0.06, 1.2), "l15_trousers", GeoKit.ALL, false)
	p(node, "ph/metal_office_desk", Vector3(12.9, g, -12.0), -90.0, 0.0, true)
	p(node, "ph/classic_laptop", Vector3(12.8, g + 0.79, -12.4), -90.0)
	p(node, "ph/vintage_radio_transceiver", Vector3(13.0, g + 0.79, -11.3), -90.0)
	p(node, "ph/office_notepads", Vector3(12.6, g + 0.79, -12.9), -80.0)
	p(node, "kenney/space-kit/desk-chair", Vector3(11.8, g, -12.1), 90.0, 1.0)
	p(node, "kenney/furniture-kit/lamproundfloor", Vector3(13.4, g, -14.2), 0.0, 1.5)
	for i in 2:
		p(node, "ph/plastic_bottle_gallon", Vector3(13.4, g, -15.0 - float(i) * 0.22), rr.randf() * 360.0)
	for i in 3:
		p(node, "kenney/furniture-kit/cardboardboxclosed", Vector3(13.3, g + float(i) * 0.5, -16.4), rr.randf_range(-10, 10), 0.5)
	for i in 5:
		p(node, "kenney/furniture-kit/books", Vector3(11.6 + rr.randf_range(-0.2, 0.2), g + float(i) * 0.12, -17.2), rr.randf() * 360.0, 0.12)
	p(node, "kenney/food-kit/mug", Vector3(12.3, g + 0.79, -11.5), 0.0, 0.11)
	p(node, "ph/old_military_crate", Vector3(10.3, g, -20.6), 0.0)
	# his map of the halls, pinned to the gallery wall
	k.box(Vector3(13.77, g + 1.6, -15.0), Vector3(0.02, 1.0, 1.4), "paper", GeoKit.ALL, false)
	for i in 6:
		k.box(Vector3(13.75, g + 1.25 + float(i) * 0.12, -15.0 + rr.randf_range(-0.4, 0.4)), Vector3(0.01, 0.02, rr.randf_range(0.3, 0.9)), "l15_trousers", GeoKit.ALL, false)


## Engine hall machines. Returns nothing; animated parts are kept on self.
func engine_hall(node: Node3D, rr: RandomNumberGenerator) -> void:
	var y := G.E1_Y
	# the machine of unmeasurable size: a drum through floor and ceiling
	var dc := Vector3(30.0, 0, -40.0)
	lvl.geo.k.cylinder(Vector3(dc.x, 1.7, dc.z), 6.0, 15.4, "l15_enamel", 32, true, false)
	lvl.geo.k.cylinder(Vector3(dc.x, y + 0.4, dc.z), 7.0, 0.8, "l15_steel", 32, true)
	for ry in [-4.5, -1.0, 3.0, 6.5]:
		k.cylinder(Vector3(dc.x, ry, dc.z), 6.25, 0.5, "l15_steel", 32, false)
	for i in 16:
		var a := TAU * float(i) / 16.0
		k.box_xf(Transform3D(Basis(Vector3.UP, -a), dc + Vector3(cos(a) * 6.05, 1.5, sin(a) * 6.05)), Vector3(0.3, 14.0, 0.45), "l15_beam", GeoKit.ALL, false)
	for i in 6:
		var a2 := TAU * float(i) / 6.0 + 0.3
		fx.box_xf(Transform3D(Basis(Vector3.UP, -a2), dc + Vector3(cos(a2) * 6.3, y + 1.4, sin(a2) * 6.3)), Vector3(0.05, 0.12, 0.6), "l15_cyan", GeoKit.ALL, false)
	# the flywheel, face-on to the glass, turning without a load
	wheel = Node3D.new()
	wheel.name = "Flywheel"
	wheel.position = Vector3(14.0, -1.6, -33.0)
	node.add_child(wheel)
	var spin := Node3D.new()
	spin.rotation.z = PI * 0.5
	wheel.add_child(spin)
	var wk := GeoKit.new(spin, "WheelKit")
	for i in 28:
		var a := TAU * float(i) / 28.0
		wk.box_xf(Transform3D(Basis(Vector3.UP, -a), Vector3(cos(a) * 3.8, 0, sin(a) * 3.8)), Vector3(0.5, 0.6, 0.9), "l15_steel", GeoKit.ALL, false)
	for i in 6:
		var a := TAU * float(i) / 6.0
		wk.box_xf(Transform3D(Basis(Vector3.UP, -a), Vector3(cos(a) * 1.9, 0, sin(a) * 1.9)), Vector3(3.4, 0.3, 0.3), "l15_beam", GeoKit.ALL, false)
	wk.cylinder(Vector3.ZERO, 0.7, 0.8, "l15_enamel", 16, false)
	fx.box(Vector3(14.0, -1.6, -33.0), Vector3(0.2, 0.2, 0.2), "l15_amber", GeoKit.ALL, false)
	wk.commit()
	for xs in [12.9, 15.1]:
		lvl.geo.k.box(Vector3(xs, -3.8, -33.0), Vector3(0.6, 4.4, 1.4), "l15_enamel")
	k.box(Vector3(14.0, -1.6, -33.0), Vector3(3.0, 0.4, 0.4), "l15_steel", GeoKit.ALL, false)
	for zz in [-28.6, -37.4]:
		lvl.geo.k.box(Vector3(14.0, y + 0.55, zz), Vector3(5.0, 0.08, 0.08), "l15_hazard", GeoKit.ALL, false)
		lvl.geo.k.box(Vector3(14.0, y + 0.55, zz), Vector3(5.0, 1.1, 0.1), "l15_glass")
	# the rod press: a housing, a hopper, a conveyor and a bin of finished rods
	var pc := Vector3(14.0, y, -52.0)
	lvl.geo.k.box(pc + Vector3(0, 1.6, 0), Vector3(3.2, 3.2, 3.0), "l15_enamel")
	k.box(pc + Vector3(0, 3.6, 0), Vector3(1.8, 0.8, 1.8), "l15_steel", GeoKit.ALL, false)
	k.box(pc + Vector3(1.62, 1.0, 0), Vector3(0.05, 0.5, 0.6), "l15_void", GeoKit.ALL, false)
	fx.box(pc + Vector3(1.63, 2.6, 0.9), Vector3(0.03, 0.12, 0.12), "l15_amber", GeoKit.ALL, false)
	fx.box(pc + Vector3(1.63, 2.6, 0.6), Vector3(0.03, 0.12, 0.12), "l15_green", GeoKit.ALL, false)
	lvl.geo.k.box(Vector3(21.0, y + 0.45, -52.0), Vector3(10.0, 0.9, 1.3), "l15_steel")
	k.box(Vector3(21.0, y + 0.92, -52.0), Vector3(10.0, 0.04, 1.2), "l15_grate", GeoKit.ALL, false)
	var bin := Vector3(27.6, y, -52.0)
	for s in [[Vector3(0, 0.5, 0.95), Vector3(2.2, 1.0, 0.1)], [Vector3(0, 0.5, -0.95), Vector3(2.2, 1.0, 0.1)],
			[Vector3(1.05, 0.5, 0), Vector3(0.1, 1.0, 2.0)], [Vector3(-1.05, 0.5, 0), Vector3(0.1, 1.0, 2.0)]]:
		lvl.geo.k.box(bin + s[0], s[1], "l15_steel")
	var cm := CylinderMesh.new()
	cm.top_radius = 0.045
	cm.bottom_radius = 0.045
	cm.height = 2.4
	cm.radial_segments = 8
	for i in 8:
		var mi := MeshInstance3D.new()
		mi.mesh = cm
		mi.material_override = MatLib.get_mat("l15_rod")
		mi.rotation.z = PI * 0.5
		mi.position = Vector3(16.6 + float(i) * 1.2, y + 0.99, -52.0 + rr.randf_range(-0.2, 0.2))
		node.add_child(mi)
		rods.append(mi)
	for i in 36:
		var mi := MeshInstance3D.new()
		var cm2 := cm
		mi.mesh = cm2
		mi.material_override = MatLib.get_mat("l15_rod")
		mi.rotation = Vector3(rr.randf_range(-0.08, 0.08), rr.randf_range(-0.2, 0.2), PI * 0.5)
		mi.scale = Vector3(1, 0.85, 1)
		mi.position = bin + Vector3(rr.randf_range(-0.05, 0.05), 0.1 + float(i / 9) * 0.09, -0.75 + float(i % 9) * 0.19)
		mi.visible = i < 14
		node.add_child(mi)
		pile.append(mi)
	# laptop-sized machines on a bench by the foot of the stair, all running
	k.box(Vector3(24.5, y + 0.85, -59.8), Vector3(3.2, 0.08, 1.0), "l15_console", GeoKit.ALL, false)
	for xb in [23.1, 25.9]:
		k.box(Vector3(xb, y + 0.42, -59.8), Vector3(0.08, 0.84, 0.9), "l15_steel", GeoKit.ALL, false)
	p(node, "kenney/space-kit/machine-generator", Vector3(23.6, y + 0.89, -59.8), 180.0, 0.3)
	p(node, "kenney/space-kit/machine-wireless", Vector3(24.6, y + 0.89, -59.7), 180.0, 0.32)
	p(node, "kenney/space-kit/machine-barrel", Vector3(25.6, y + 0.89, -59.8), 160.0, 0.34)
	# big machines along the east wall, pipes on the south wall
	p(node, "kenney/space-kit/machine-generatorlarge", Vector3(36.5, y, -55.5), -90.0, 3.4)
	p(node, "kenney/space-kit/machine-barrellarge", Vector3(36.0, y, -29.5), 0.0, 3.0)
	p(node, "kenney/space-kit/machine-wirelesscable", Vector3(22.0, y, -28.4), 180.0, 2.8)
	for xs in [8.0, 20.0, 33.0]:
		p(node, "ph/modular_pipes", Vector3(xs, y + 0.2, -26.45), 0.0, 3.6)
	p(node, "ph/modular_airduct_rectangular_01", Vector3(26.0, 7.6, -61.0), 0.0)
	p(node, "kenney/space-kit/satellitedish-large", Vector3(8.4, 0.35, -61.2), 160.0, 0.6)
	p(node, "kenney/space-kit/desk-computerscreen", Vector3(9.4, 0.0, -61.2), 180.0, 1.3)
	# medium machines under the glass, ducts and pipes overhead
	p(node, "kenney/space-kit/machine-generatorlarge", Vector3(8.0, y, -44.0), 90.0, 2.4)
	p(node, "kenney/space-kit/machine-barrellarge", Vector3(8.2, y, -48.6), 0.0, 2.2)
	p(node, "kenney/space-kit/structure-detailed", Vector3(19.0, y, -44.5), 0.0, 4.0)
	p(node, "kenney/space-kit/supports-high", Vector3(19.0, y + 4.0, -44.5), 0.0, 1.6)
	for xs in [7.0, 7.8, 38.6]:
		lvl.geo.k.box(Vector3(xs, 7.3, -44.0), Vector3(0.5, 0.5, 35.0), "l15_steel", GeoKit.ALL, false)
	for zs in [-27.0, -61.0]:
		k.box(Vector3(22.0, 7.9, zs), Vector3(35.0, 0.7, 0.7), "l15_enamel", GeoKit.ALL, false)
	for zz in [-30.0, -38.0, -46.0, -54.0]:
		k.box(Vector3(38.6, 0.6, zz), Vector3(0.5, 13.4, 0.5), "l15_steel", GeoKit.ALL, false)
		fx.box(Vector3(38.3, y + 2.2, zz + 1.0), Vector3(0.04, 0.1, 0.3), "l15_amber" if int(zz) % 16 == 6 else "l15_green", GeoKit.ALL, false)
	for i in 9:
		lvl.geo.lamp(Vector3(4.42 + float(i) * 4.0, y + 0.012, -26.25), Vector3.UP, 2.6, 0.22, "l15_lamp_ground")
		lvl.geo.lamp(Vector3(4.42 + float(i) * 4.0, y + 0.012, -61.75), Vector3.UP, 2.6, 0.22, "l15_lamp_ground")
	# hazard border around the drum
	for i in 24:
		var a3 := TAU * float(i) / 24.0
		k.box_xf(Transform3D(Basis(Vector3.UP, -a3), dc + Vector3(cos(a3) * 7.6, y + 0.01, sin(a3) * 7.6)), Vector3(0.25, 0.02, 2.05), "l15_hazard", GeoKit.ALL, false)


## Rods slide off the press and drop into the bin; returns rods produced this step.
func rods_step(delta: float) -> int:
	var made := 0
	for r in rods:
		var mi := r as MeshInstance3D
		mi.position.x += delta * 0.55
		if mi.position.x > 26.4:
			mi.position.x -= 9.6
			made += 1
	return made


func wreck_room(node: Node3D, rr: RandomNumberGenerator) -> void:
	for c in [Vector3(10.5, 0, -73.0), Vector3(17.5, 0, -77.5), Vector3(12.0, 0, -80.5)]:
		var o := Transform3D(Basis(Vector3.UP, rr.randf_range(-0.3, 0.3)), c)
		bx(o, Vector3(0, 0.6, 0), Vector3(3.0, 1.2, 2.4), "l15_enamel")
		bx(o, Vector3(-1.2, 1.6, 0), Vector3(0.6, 0.9, 2.4), "l15_enamel", Vector3(0, 0, 35))
		bx(o, Vector3(1.0, 1.5, -0.4), Vector3(0.5, 0.8, 1.4), "l15_steel", Vector3(30, 20, -40))
		bx(o, Vector3(0, 1.23, 0), Vector3(2.0, 0.03, 1.6), "l15_soot")
		for i in 4:
			var a := rr.randf() * TAU
			var d := rr.randf_range(2.0, 4.0)
			bx(o, Vector3(cos(a) * d, 0.04, sin(a) * d), Vector3(rr.randf_range(0.6, 1.4), 0.04, rr.randf_range(0.5, 1.1)), "l15_enamel", Vector3(rr.randf_range(0, 180), rr.randf_range(-8, 8), rr.randf_range(-8, 8)))
		k.box_xf(Transform3D(Basis(Vector3.UP, rr.randf()), c + Vector3(0, 0.006, 0)), Vector3(5.0, 0.008, 4.2), "l15_soot", GeoKit.ALL, false)
		for i in 10:
			if i < 2:
				p(node, "kenney/space-kit/barrel", c + Vector3(rr.randf_range(-3, 3), 0, rr.randf_range(-3, 3)), rr.randf() * 360.0, 0.25)
			else:
				bx(Transform3D(Basis(), c), Vector3(rr.randf_range(-3.5, 3.5), 0.05, rr.randf_range(-3.5, 3.5)), Vector3(0.18, 0.1, 0.14), "l15_steel", Vector3(rr.randf() * 180, 0, 0))
	# soot thrown up the walls
	k.box(Vector3(23.75, 2.5, -77.0), Vector3(0.02, 3.4, 4.0), "l15_soot", GeoKit.ALL, false)
	k.box(Vector3(14.0, 3.0, -83.75), Vector3(5.0, 3.2, 0.02), "l15_soot", GeoKit.ALL, false)
	var mg := p(node, "kenney/space-kit/machine-generatorlarge", Vector3(20.5, 0.4, -70.0), 30.0, 2.0)
	if mg:
		mg.rotation.z = 0.35
	p(node, "ph/modular_electric_cables", Vector3(23.75, 1.8, -71.0), -90.0)


func cremation_room(node: Node3D, rr: RandomNumberGenerator) -> void:
	var base := Vector3(15.5, 0, -110.0)
	k.box_xf(Transform3D(Basis(), base + Vector3(0, 0.02, 0)), Vector3(6.0, 0.04, 7.0), "l15_ash", GeoKit.ALL, false)
	for i in 16:
		var lay := 0 if i < 8 else (1 if i < 13 else 2)
		var pos := base + Vector3(rr.randf_range(-2.0, 2.0) * (1.0 - 0.3 * lay), 0.3 + 0.42 * float(lay), rr.randf_range(-2.4, 2.4) * (1.0 - 0.3 * lay))
		var b := Basis.from_euler(Vector3(rr.randf_range(-0.3, 0.3), rr.randf() * TAU, rr.randf_range(-0.5, 0.5)))
		hound(Transform3D(b, pos), rr)
	k.box(Vector3(21.75, 4.2, -110.0), Vector3(0.02, 1.4, 6.0), "l15_soot", GeoKit.ALL, false)
	p(node, "ph/hand_truck", Vector3(12.0, 0, -104.2), 200.0)
	p(node, "ph/metal_trash_can", Vector3(6.0, 0, -118.5), 0.0)
	for i in 3:
		p(node, "ph/barrel_03", Vector3(6.0 + float(i) * 0.7, 0, -101.0), rr.randf() * 360.0)


func lab(node: Node3D, rr: RandomNumberGenerator) -> void:
	for zc in [-30.5, -34.5]:
		lvl.geo.k.box(Vector3(-13.0, 0.45, zc), Vector3(5.0, 0.9, 1.3), "l15_console")
		k.box(Vector3(-13.0, 0.93, zc), Vector3(5.1, 0.06, 1.4), "l15_enamel", GeoKit.ALL, false)
		k.box(Vector3(-13.0, 1.6, zc), Vector3(4.6, 0.04, 0.4), "l15_steel", GeoKit.ALL, false)
		p(node, "ph/medical_box", Vector3(-14.5, 0.96, zc + 0.2), rr.randf_range(-20, 20))
		p(node, "ph/clipboard", Vector3(-12.1, 0.96, zc - 0.2), rr.randf() * 360.0)
		p(node, "kenney/space-kit/machine-wireless", Vector3(-11.0, 0.96, zc), 90.0, 0.45)
		p(node, "ph/stationery_supplies", Vector3(-15.2, 0.96, zc - 0.3), 30.0)
	lvl.geo.k.box(Vector3(-19.4, 0.45, -34.0), Vector3(1.1, 0.9, 14.0), "l15_console")
	k.box(Vector3(-19.4, 0.93, -34.0), Vector3(1.2, 0.06, 14.0), "l15_enamel", GeoKit.ALL, false)
	k.box(Vector3(-19.2, 1.9, -29.0), Vector3(1.4, 1.9, 2.2), "l15_enamel", GeoKit.ALL, false)
	k.box(Vector3(-18.48, 1.75, -29.0), Vector3(0.02, 1.0, 2.0), "l15_glass", GeoKit.ALL, false)
	p(node, "kenney/space-kit/desk-computerscreen", Vector3(-19.4, 0.96, -36.5), 90.0, 0.6)
	p(node, "ph/binder_notebook", Vector3(-19.3, 0.96, -38.0), 80.0)
	for i in 3:
		var st := p(node, "kenney/furniture-kit/stoolbar", Vector3(-11.0 - float(i) * 1.9, 0, -32.5 + rr.randf_range(-0.4, 0.4)), rr.randf() * 360.0, 0.75)
		if st and i == 1:
			st.rotation.x = PI * 0.5
			st.position.y = 0.2
	corpse(Vector3(-9.0, 0, -37.6), 70.0, rr, "knife")
	k.box(Vector3(-4.22, 1.1, -36.2), Vector3(0.02, 0.9, 0.5), "l15_blood", GeoKit.ALL, false)


func dorm(node: Node3D, rr: RandomNumberGenerator) -> void:
	for i in 5:
		var z := -48.0 - float(i) * 3.0
		p(node, "kenney/furniture-kit/bedbunk", Vector3(-18.6, 0, z), 90.0, 1.8, true)
		if i % 2 == 0:
			p(node, "kenney/furniture-kit/bedbunk", Vector3(-10.4, 0, z), -90.0, 1.8, true)
	for i in 6:
		k.box(Vector3(-16.0 + float(i) * 0.62, 0.95, -61.6), Vector3(0.58, 1.9, 0.5), "l15_door", GeoKit.ALL, true)
	p(node, "ph/vintage_suitcase", Vector3(-14.0, 0, -52.0), 30.0)
	corpse(Vector3(-13.5, 0, -57.0), -110.0, rr, "spear")


func kitchen(node: Node3D, rr: RandomNumberGenerator) -> void:
	var ids := ["kitchencabinet", "kitchenstove", "kitchencabinetdrawer", "kitchensink", "kitchencabinet", "kitchenstove", "kitchencabinetdrawer", "kitchencabinet"]
	for i in ids.size():
		p(node, "kenney/furniture-kit/" + ids[i], Vector3(-19.55, 0, -67.4 - float(i) * 0.9), 90.0, 0.92, true)
	p(node, "kenney/furniture-kit/kitchenfridgelarge", Vector3(-19.4, 0, -75.6), 90.0, 1.95, true)
	p(node, "kenney/furniture-kit/kitchenfridgelarge", Vector3(-19.4, 0, -76.8), 90.0, 1.95, true)
	# extraction hood and a shelf of pans over the stoves
	k.box(Vector3(-19.3, 2.5, -70.5), Vector3(1.4, 0.5, 6.0), "l15_enamel", GeoKit.ALL, false)
	k.box(Vector3(-19.55, 1.75, -73.9), Vector3(0.5, 0.04, 2.4), "l15_steel", GeoKit.ALL, false)
	for i in 4:
		p(node, "kenney/food-kit/" + ["pot", "pan-stew", "pot-stew", "pan"][i], Vector3(-19.5, 1.77, -73.0 - float(i) * 0.55), 90.0, 0.2)
	# a stainless prep island
	lvl.geo.k.box(Vector3(-15.0, 0.46, -72.0), Vector3(1.4, 0.92, 5.0), "l15_steel")
	k.box(Vector3(-15.0, 0.93, -72.0), Vector3(1.5, 0.04, 5.1), "l15_enamel", GeoKit.ALL, false)
	for id in ["cutting-board", "knife-block", "bowl", "plate-dinner", "glass"]:
		p(node, "kenney/food-kit/" + id, Vector3(-15.0 + rr.randf_range(-0.4, 0.4), 0.95, -72.0 + rr.randf_range(-2.2, 2.2)), rr.randf() * 360.0, 0.12)
	# canteen tables in two rows; the far ones knocked over in the fight
	for row in 2:
		for i in 3:
			var c := Vector3(-10.5 + float(row) * 3.6, 0, -68.5 - float(i) * 3.4)
			var over := row == 1 and i == 1
			var o := Transform3D(Basis(Vector3.UP, rr.randf_range(-0.05, 0.05) + (0.6 if over else 0.0)), c)
			if over:
				o = o * Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5), Vector3(0, 0.38, 0.0))
			bx(o, Vector3(0, 0.74, 0), Vector3(0.9, 0.04, 2.2), "l15_enamel")
			for lx in [-0.36, 0.36]:
				for lz in [-0.95, 0.95]:
					bx(o, Vector3(lx, 0.36, lz), Vector3(0.05, 0.72, 0.05), "l15_steel")
			if not over:
				for bxs in [-0.8, 0.8]:
					bx(o, Vector3(bxs, 0.44, 0), Vector3(0.3, 0.04, 2.0), "l15_enamel")
					bx(o, Vector3(bxs, 0.22, 0), Vector3(0.06, 0.44, 1.8), "l15_steel")
	for id in ["pot", "pan", "plate-broken", "frying-pan", "can-open", "plate-broken", "soda-can-crushed"]:
		p(node, "kenney/food-kit/" + id, Vector3(-11.0 + rr.randf_range(-3, 3), 0, -73.0 + rr.randf_range(-4, 4)), rr.randf() * 360.0, 0.12)
	corpse(Vector3(-7.4, 0, -76.6), 160.0, rr, "spear")
	corpse(Vector3(-15.0, 0, -78.6), 15.0, rr, "knife", true)


func storage(node: Node3D, rr: RandomNumberGenerator) -> void:
	for zr in [-108.0, -113.0, -118.0]:
		var x := -20.5
		while x < -8.0:
			p(node, "ph/steel_frame_shelves_01", Vector3(x, 0, zr), 0.0, 2.1, true)
			var kind := rr.randi() % 3
			for lv in [0.04, 2.15]:
				for j in 4:
					var c := Vector3(x - 0.39 + float(j) * 0.26, lv, zr + rr.randf_range(-0.06, 0.06))
					match kind:
						0:   # water jugs
							k.box(c + Vector3(0, 0.15, 0), Vector3(0.2, 0.3, 0.2), "l15_jug", GeoKit.ALL, false)
							k.box(c + Vector3(0, 0.33, 0), Vector3(0.06, 0.06, 0.06), "l15_jug_cap", GeoKit.ALL, false)
						1:   # food cartons
							k.box(c + Vector3(0, 0.14, 0), Vector3(0.24, 0.28, 0.36), "l15_carton", GeoKit.ALL, false)
						2:   # equipment cases
							if j % 2 == 0:
								k.box(c + Vector3(0.13, 0.11, 0), Vector3(0.48, 0.22, 0.34), "l15_steel", GeoKit.ALL, false)
			x += 2.3
	p(node, "kenney/space-kit/barrels", Vector3(-6.5, 0, -110.0), 90.0, 1.0)
	p(node, "kenney/space-kit/barrels-rail", Vector3(-6.5, 0, -115.0), 90.0, 1.0)
	for i in 3:
		p(node, "ph/old_military_crate", Vector3(-21.6, float(i) * 0.3, -101.5), 90.0)
	p(node, "ph/plastic_bottle_gallon", Vector3(-20.4, 0, -101.0), 40.0)
	p(node, "ph/metal_tool_chest", Vector3(-6.0, 0, -122.8), 180.0)
	p(node, "ph/portable_generator", Vector3(-8.0, 0, -122.8), 180.0)
	p(node, "ph/hand_truck", Vector3(-10.0, 0, -101.0), 40.0)
	corpse(Vector3(-15.0, 0, -121.5), 95.0, rr, "", true)


## Abandoned camps of the dead, bodies along the spine and the cross gallery.
func halls(node: Node3D, rr: RandomNumberGenerator) -> void:
	corpse(Vector3(-2.6, 0, -64.5), 15.0, rr, "spear")
	corpse(Vector3(2.7, 0, -95.0), -160.0, rr, "knife")
	corpse(Vector3(-31.0, 0, -88.0), 90.0, rr, "spear", true)
	var camp := Vector3(-44.0, 0, -91.5)
	k.box(camp + Vector3(0, 0.08, 0), Vector3(1.9, 0.16, 0.8), "l15_mattress", GeoKit.ALL, false)
	p(node, "ph/vintage_flashlight", camp + Vector3(1.3, 0, 0.4), 70.0)
	p(node, "ph/trashbag", camp + Vector3(-1.4, 0, 0.3), 20.0)
	p(node, "kenney/food-kit/can-open", camp + Vector3(0.9, 0, 0.8), 0.0, 0.12)
	p(node, "ph/hand_truck", Vector3(30.0, 0, -88.5), 120.0)
	# cable runs and fittings along the spine
	for z in [-30.0, -60.0, -90.0, -120.0]:
		k.box(Vector3(-3.72, 0.05, z - 15.0), Vector3(0.08, 0.08, 30.0), "l15_rubber", GeoKit.ALL, false)
	for z in [-34.0, -66.0, -106.0]:
		p(node, "ph/security_camera_01", Vector3(3.6, 5.4, z), -60.0)
	for z in [-36.0, -56.0, -101.0]:
		p(node, "ph/korean_fire_extinguisher_01", Vector3(-3.65, 0.0, z), 90.0)
	for z in [-46.0, -78.0, -118.0]:
		k.box(Vector3(3.78, 4.9, z), Vector3(0.05, 0.7, 1.4), "l15_grate", GeoKit.ALL, false)
		k.box(Vector3(-3.78, 4.9, z + 2.0), Vector3(0.05, 0.7, 1.4), "l15_grate", GeoKit.ALL, false)
