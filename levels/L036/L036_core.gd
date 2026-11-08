extends RefCounted
## Level 36 authored centre: Lost and Found, BTA booth 0, the food-court mezzanine
## over the defunct security checks, the concourse with its one-way travelator,
## the carpeted duty-free hall, the Meeting Place and Concourse M, which connects
## to itself.

const S := preload("res://levels/L036/L036_strip.gd")
const CON_Z0 := -44.0
const CON_Z1 := -112.0
const CON_H := 5.5
const MEZZ_Y := 5.0
const TRAV := Rect2(-1.3, -100.0, 2.6, 50.0)
const LOOP_Z := -95.0
const LOOP_X0 := 6.0
const LOOP_X1 := 82.0
const LOOP_SEAM := 46.0
const LOOP_PERIOD := 30.0
const LAF := Rect2(-15.0, 7.0, 14.0, 9.0)
const MEET := Vector3(13.0, 0.0, -78.0)

var lvl
var k: GeoKit
var d: GeoKit
var laf_label: Label3D
var shelves_spot := Vector3(-8.0, 0.0, 14.6)


func _init(level, structure: GeoKit, detail: GeoKit) -> void:
	lvl = level
	k = structure
	d = detail


static func materials() -> void:
	var m := func(n: String, base: String, a: Color, b: Color, x: Dictionary) -> void:
		x["albedo_a"] = a
		x["albedo_b"] = b
		MatLib.define(n, x, base)
	m.call("l36_floor", "concrete", Color(0.62, 0.62, 0.6), Color(0.56, 0.56, 0.55), {"pattern": 15, "pattern_color": Color(0.4, 0.4, 0.4), "pattern_strength": 0.35,
		"roughness_a": 0.2, "roughness_b": 0.32, "noise_scale": 0.6, "bump_strength": 0.15, "stain_amount": 0.1})
	m.call("l36_floor_hall", "pool_tile", Color(0.7, 0.7, 0.68), Color(0.66, 0.66, 0.64), {"pattern_scale": Vector2(1.2, 1.2), "grout_width": 0.004,
		"grout_color": Color(0.5, 0.5, 0.48), "roughness_a": 0.16, "roughness_b": 0.26})
	m.call("l36_carpet", "l0_carpet", Color(0.18, 0.22, 0.32), Color(0.14, 0.17, 0.26), {"pattern": 6, "pattern_strength": 0.4, "pattern_color": Color(0.3, 0.28, 0.2),
		"wetness": 0.0, "stain_amount": 0.15, "roughness_a": 0.95})
	m.call("l36_carpet_shop", "l0_carpet", Color(0.3, 0.1, 0.11), Color(0.25, 0.08, 0.09), {"pattern": 6, "pattern_strength": 0.25, "pattern_color": Color(0.4, 0.3, 0.15),
		"wetness": 0.0, "stain_amount": 0.08})
	m.call("l36_wall", "plaster", Color(0.8, 0.8, 0.78), Color(0.74, 0.74, 0.72), {"pattern": 1, "pattern_scale": Vector2(1.5, 3.0), "grout_width": 0.006,
		"grout_color": Color(0.6, 0.6, 0.58), "roughness_a": 0.5})
	m.call("l36_wall_bag", "plaster", Color(0.6, 0.63, 0.66), Color(0.55, 0.58, 0.6), {"pattern": 1, "pattern_scale": Vector2(1.2, 1.2), "grout_width": 0.008,
		"grout_color": Color(0.4, 0.42, 0.44), "stain_amount": 0.2, "grime_height": 0.6, "grime_color": Color(0.35, 0.36, 0.37)})
	m.call("l36_ceiling", "plaster", Color(0.8, 0.8, 0.79), Color(0.77, 0.77, 0.76), {"pattern": 7, "pattern_scale": Vector2(1.2, 0.6), "grout_width": 0.01,
		"grout_color": Color(0.62, 0.62, 0.6), "stain_amount": 0.0, "bump_strength": 0.2})
	m.call("l36_column", "metal", Color(0.78, 0.79, 0.8), Color(0.72, 0.73, 0.75), {"metallic_value": 0.6, "roughness_a": 0.25, "stain_amount": 0.0})
	m.call("l36_steel", "metal", Color(0.66, 0.68, 0.7), Color(0.58, 0.6, 0.62), {"metallic_value": 0.85, "roughness_a": 0.25, "stain_amount": 0.0})
	m.call("l36_skirt", "metal", Color(0.22, 0.23, 0.25), Color(0.18, 0.19, 0.2), {"metallic_value": 0.6})
	m.call("l36_dark", "plaster", Color(0.07, 0.07, 0.08), Color(0.06, 0.06, 0.07), {"roughness_a": 0.4})
	m.call("l36_rubber", "plaster", Color(0.04, 0.04, 0.04), Color(0.05, 0.05, 0.05), {"roughness_a": 0.7})
	m.call("l36_counter", "plaster", Color(0.9, 0.9, 0.88), Color(0.86, 0.86, 0.84), {"roughness_a": 0.3})
	m.call("l36_counter_front", "plaster", Color(0.32, 0.4, 0.52), Color(0.28, 0.36, 0.48), {"pattern": 2, "pattern_scale": Vector2(0.6, 1.0), "pattern_strength": 0.15})
	m.call("l36_signboard", "plaster", Color(0.05, 0.07, 0.12), Color(0.05, 0.06, 0.1), {"roughness_a": 0.35})
	m.call("l36_shutter", "metal", Color(0.55, 0.57, 0.58), Color(0.5, 0.52, 0.53), {"pattern": 2, "pattern_scale": Vector2(1.0, 0.12), "pattern_strength": 0.4,
		"pattern_color": Color(0.38, 0.4, 0.41), "uv_rotate": 1.5708, "metallic_value": 0.1, "roughness_a": 0.6})
	m.call("l36_tape", "plaster", Color(0.1, 0.16, 0.42), Color(0.1, 0.15, 0.4), {"roughness_a": 0.4})
	m.call("l36_seat", "plaster", Color(0.16, 0.2, 0.28), Color(0.13, 0.17, 0.24), {"noise_scale": 3.0, "roughness_a": 0.8})
	m.call("l36_fabric", "plaster", Color(0.5, 0.36, 0.26), Color(0.42, 0.3, 0.22), {"noise_scale": 3.0, "bump_strength": 0.6})
	m.call("l36_shelf", "metal", Color(0.85, 0.85, 0.83), Color(0.8, 0.8, 0.78), {"metallic_value": 0.2, "roughness_a": 0.4})
	var g := StandardMaterial3D.new()
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.albedo_color = Color(0.82, 0.9, 0.92, 0.22)
	g.roughness = 0.03
	g.metallic_specular = 0.9
	MatLib.register("l36_glass", g)
	var v := StandardMaterial3D.new()
	v.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	v.albedo_color = Color(0.0, 0.0, 0.0)
	MatLib.register("l36_void", v)
	MatLib.register("l36_panel", MatLib.panel(Color(0.95, 0.97, 1.0), 2.6))
	MatLib.register("l36_frosted", MatLib.panel(Color(0.86, 0.9, 0.95), 1.15))
	MatLib.register("l36_panel_big", MatLib.panel(Color(0.96, 0.97, 1.0), 2.2))
	MatLib.register("l36_panel_flick", MatLib.panel(Color(0.95, 0.97, 1.0), 2.4, 1.0))
	MatLib.register("l36_screen", MatLib.panel(Color(0.09, 0.15, 0.34), 1.2))
	MatLib.register("l36_purple", MatLib.panel(Color(0.62, 0.22, 1.0), 2.6))
	MatLib.register("l36_exit", MatLib.panel(Color(0.2, 1.0, 0.4), 2.0))
	for c in [["l36_bag_a", Color(0.14, 0.16, 0.2)], ["l36_bag_b", Color(0.45, 0.08, 0.08)], ["l36_bag_c", Color(0.1, 0.25, 0.4)], ["l36_bag_d", Color(0.55, 0.45, 0.2)], ["l36_bag_e", Color(0.25, 0.3, 0.2)]]:
		MatLib.define(c[0], {"albedo_a": c[1], "albedo_b": (c[1] as Color).darkened(0.15), "roughness_a": 0.5, "pattern": 2, "pattern_scale": Vector2(0.3, 1.0), "pattern_strength": 0.15}, "plaster")


func label(node: Node3D, pos: Vector3, yaw: float, text: String, size := 64, col := Color(1.0, 0.84, 0.16)) -> Label3D:
	var lb := Label3D.new()
	lb.text = text
	lb.font_size = size
	lb.pixel_size = 0.0045
	lb.modulate = col
	lb.outline_size = 0
	lb.double_sided = false
	lb.position = pos
	lb.rotation.y = yaw
	node.add_child(lb)
	return lb


func board_sign(node: Node3D, pos: Vector3, yaw: float, text: String) -> void:
	var w := maxf(2.4, float(text.length()) * 0.24 + 0.6)
	d.box_xf(Transform3D(Basis(Vector3.UP, yaw), pos), Vector3(w, 0.7, 0.1), "l36_signboard", GeoKit.ALL, false)
	label(node, pos + Basis(Vector3.UP, yaw) * Vector3(0, 0, 0.06), yaw, text)
	label(node, pos + Basis(Vector3.UP, yaw) * Vector3(0, 0, -0.06), yaw + PI, text)


## A row of linked airport seats along local +x. Returns nothing; one collider.
func seats(o: Transform3D, n: int, collide := true) -> void:
	var w := 0.62
	var ln := float(n) * w
	d.box_xf(o * Transform3D(Basis(), Vector3(ln * 0.5, 0.36, 0)), Vector3(ln, 0.06, 0.12), "l36_steel", GeoKit.ALL, false)
	for i in n:
		var c := Vector3(w * (float(i) + 0.5), 0, 0)
		d.box_xf(o * Transform3D(Basis(), c + Vector3(0, 0.45, 0.02)), Vector3(w - 0.06, 0.08, 0.5), "l36_seat", GeoKit.ALL, false)
		d.box_xf(o * Transform3D(Basis(Vector3(1, 0, 0), -0.18), c + Vector3(0, 0.78, -0.24)), Vector3(w - 0.06, 0.62, 0.07), "l36_seat", GeoKit.ALL, false)
		if i % 3 == 0:
			d.box_xf(o * Transform3D(Basis(), c + Vector3(-w * 0.5, 0.62, 0.0)), Vector3(0.05, 0.05, 0.45), "l36_steel", GeoKit.ALL, false)
	for lx in [0.2, ln - 0.2]:
		d.box_xf(o * Transform3D(Basis(), Vector3(lx, 0.18, 0)), Vector3(0.06, 0.36, 0.45), "l36_steel", GeoKit.ALL, false)
	if collide:
		k.box_xf(o * Transform3D(Basis(), Vector3(ln * 0.5, 0.5, -0.02)), Vector3(ln, 1.0, 0.6), "l36_seat", 0, true)


func suitcase(pos: Vector3, yaw: float, r: RandomNumberGenerator, upright := true) -> void:
	var mats := ["l36_bag_a", "l36_bag_b", "l36_bag_c", "l36_bag_d", "l36_bag_e"]
	var s := Vector3(r.randf_range(0.38, 0.5), r.randf_range(0.55, 0.75), r.randf_range(0.22, 0.3))
	if not upright:
		s = Vector3(s.x, s.z, s.y)
	var b := Basis(Vector3.UP, yaw)
	d.box_xf(Transform3D(b, pos + Vector3(0, s.y * 0.5, 0)), s, mats[r.randi() % mats.size()], GeoKit.ALL, false)
	if upright:
		d.box_xf(Transform3D(b, pos + Vector3(0, s.y + 0.06, 0)), Vector3(0.16, 0.04, 0.03), "l36_dark", GeoKit.ALL, false)


# ------------------------------------------------------------------ centre

func lost_and_found(node: Node3D, r: RandomNumberGenerator) -> void:
	var a := LAF
	var x0 := a.position.x
	var x1 := a.end.x
	var z0 := a.position.y
	k.wall(Vector3(x0, 0, z0), Vector3(x1, 0, z0), 3.2, 0.25, "l36_wall", [{"at": 4.0, "w": 6.0, "h": 1.9, "sill": 0.9}, {"at": 11.0, "w": 1.6, "h": 2.3}])
	k.box(Vector3(x0 + 4.0, 1.85, z0), Vector3(6.0, 1.9, 0.06), "l36_glass")
	k.wall(Vector3(x0, 0, z0), Vector3(x0, 0, S.WALL_Z), 3.2, 0.25, "l36_wall")
	k.wall(Vector3(x1, 0, z0), Vector3(x1, 0, S.WALL_Z), 3.2, 0.25, "l36_wall")
	k.slab(x0, z0, x1, S.WALL_Z, 3.35, 0.15, "l36_ceiling")
	d.panel(Vector3(-8.0, 3.19, 11.5), 3.0, 0.6, "l36_panel", 3.0, 0.0)
	k.box_mm(Vector3(-13.5, 0, 9.4), Vector3(-6.0, 1.05, 10.2), "l36_counter_front")
	d.box_mm(Vector3(-13.6, 1.05, 9.35), Vector3(-5.9, 1.1, 10.3), "l36_counter")
	for zz in [15.4, 13.2]:
		for lv in [0.0, 0.8, 1.6]:
			d.box_mm(Vector3(-14.6, lv + 0.02, zz - 0.3), Vector3(-1.6, lv + 0.06, zz + 0.3), "l36_shelf", GeoKit.ALL, false)
			var x := -14.2
			while x < -2.0:
				if r.randf() < 0.7:
					suitcase(Vector3(x, lv + 0.06, zz), r.randf_range(-0.2, 0.2), r, r.randf() < 0.6)
				x += r.randf_range(0.5, 0.8)
		for xl in [-14.5, -8.0, -1.7]:
			d.box(Vector3(xl, 1.2, zz), Vector3(0.05, 2.4, 0.62), "l36_shelf", GeoKit.ALL, false)
	Props.place(lvl, node, "ph/vintage_suitcase", Vector3(-11.0, 1.1, 9.8), 10.0)
	board_sign(node, Vector3(-8.0, 3.7, z0 - 0.1), 0.0, "LOST AND FOUND")
	laf_label = label(node, Vector3(-9.8, 1.14, 9.9), 0.0, "REROUTED: 0", 28, Color(0.2, 0.2, 0.22))
	laf_label.rotation.x = -PI * 0.5


func bta_booth(node: Node3D) -> void:
	var c := Vector3(-9.0, 0, -15.5)
	k.box_mm(c + Vector3(-2.2, 0, -0.6), c + Vector3(2.2, 1.1, 0.6), "l36_counter_front")
	d.box_mm(c + Vector3(-2.3, 1.1, -0.65), c + Vector3(2.3, 1.15, 0.65), "l36_counter")
	d.box(c + Vector3(0, 0.55, 0.62), Vector3(4.2, 0.9, 0.02), "l36_purple", GeoKit.ALL, false)
	k.box(c + Vector3(2.9, 1.8, 0), Vector3(0.6, 3.6, 0.6), "l36_dark")
	d.box(c + Vector3(2.9, 2.6, 0.31), Vector3(0.5, 1.6, 0.02), "l36_purple", GeoKit.ALL, false)
	label(node, c + Vector3(2.9, 2.6, 0.33), 0.0, "B\nT\nA", 72, Color(1, 1, 1))
	d.box(c + Vector3(0, 2.6, -0.5), Vector3(4.4, 0.8, 0.08), "l36_purple", GeoKit.ALL, false)
	label(node, c + Vector3(0, 2.6, -0.45), 0.0, "BACKROOMS TRAVEL AGENCY  -  BOOTH 0", 40, Color(1, 1, 1))
	for i in 3:
		d.box(c + Vector3(-1.5 + float(i) * 0.4, 1.25, 0.2), Vector3(0.21, 0.18, 0.02), "paper", GeoKit.ALL, false)
	Props.place(lvl, node, "kenney/space-kit/desk-computerscreen", c + Vector3(0.6, 1.15, -0.2), 180.0, 0.55)
	Props.place(lvl, node, "kenney/furniture-kit/chairdesk", c + Vector3(0.4, 0, -1.2), 180.0, 1.0)


## Food-court mezzanine (+5 m) over the defunct security checks.
func mezzanine(node: Node3D, r: RandomNumberGenerator) -> void:
	k.slab(-16.0, -36.0, 16.0, S.BACK_Z + 0.2, MEZZ_Y, 0.3, "l36_floor_hall")
	d.box(Vector3(0, MEZZ_Y + 0.55, -36.05), Vector3(32.0, 1.1, 0.04), "l36_glass", GeoKit.ALL, false)
	k.box(Vector3(0, MEZZ_Y + 0.55, -36.05), Vector3(32.0, 1.1, 0.1), "l36_glass", 0, true)
	d.box(Vector3(0, MEZZ_Y + 1.12, -36.05), Vector3(32.0, 0.06, 0.1), "l36_steel", GeoKit.ALL, false)
	for xs in [-10.0, 10.0]:
		k.stairs(Vector3(xs, 0, -28.16), Vector3(0, 0, -1), 2.4, MEZZ_Y, 28, "l36_floor_hall", 0.28)
		for sx in [-1.25, 1.25]:
			d.box_xf(Transform3D(Basis(Vector3(1, 0, 0), atan2(MEZZ_Y, 7.84)), Vector3(xs + sx, MEZZ_Y * 0.5 + 0.95, -32.08)), Vector3(0.05, 0.05, 9.3), "l36_steel", GeoKit.ALL, false)
			d.box_xf(Transform3D(Basis(Vector3(1, 0, 0), atan2(MEZZ_Y, 7.84)), Vector3(xs + sx, MEZZ_Y * 0.5 + 0.45, -32.08)), Vector3(0.03, 0.95, 9.3), "l36_glass", GeoKit.ALL, false)
	for xc in [-7.0, 7.0]:
		k.cylinder(Vector3(xc, MEZZ_Y * 0.5, -36.4), 0.3, MEZZ_Y, "l36_column", 12)
	# kiosks along the back wall, shutters half down; tables and chairs
	for i in 5:
		var kx := -13.0 + float(i) * 6.5
		k.box_mm(Vector3(kx - 2.5, MEZZ_Y, -44.0), Vector3(kx + 2.5, MEZZ_Y + 3.4, -42.4), "l36_wall")
		d.box(Vector3(kx, MEZZ_Y + 1.6, -42.35), Vector3(4.6, 1.6 + float(i % 2) * 0.9, 0.06), "l36_shutter", GeoKit.ALL, false)
		d.box(Vector3(kx, MEZZ_Y + 3.0, -42.33), Vector3(4.6, 0.5, 0.06), ["l36_bag_b", "l36_bag_c", "l36_bag_d", "l36_bag_e", "l36_bag_b"][i], GeoKit.ALL, false)
		d.panel(Vector3(kx, MEZZ_Y + 3.39, -41.8), 3.0, 0.4, "l36_panel", float(i), 0.0)
	for i in 8:
		var tc := Vector3(-12.0 + float(i % 4) * 8.0, MEZZ_Y, -38.5 - float(i / 4) * 2.4)
		d.cylinder(tc + Vector3(0, 0.37, 0), 0.04, 0.74, "l36_steel", 6, false)
		d.cylinder(tc + Vector3(0, 0.75, 0), 0.45, 0.03, "l36_counter", 16, false)
		for a in 3:
			var ang := TAU * float(a) / 3.0 + r.randf()
			Props.place(lvl, node, "kenney/furniture-kit/chairmodernframecushion", tc + Vector3(cos(ang) * 0.75, 0, sin(ang) * 0.75), rad_to_deg(-ang) - 90.0, 0.9)
	board_sign(node, Vector3(0, MEZZ_Y + 2.6, -36.4), 0.0, "FOOD COURT")
	# defunct security: two walk-through frames and dead scanners, centre lane clear
	for sx in [-1.0, 1.0]:
		var fx: float = sx * 4.4
		for px in [-0.5, 0.5]:
			d.box(Vector3(fx + px, 1.1, -40.0), Vector3(0.12, 2.2, 0.5), "l36_counter", GeoKit.ALL, false)
		d.box(Vector3(fx, 2.25, -40.0), Vector3(1.2, 0.18, 0.55), "l36_counter", GeoKit.ALL, false)
		k.box(Vector3(fx + sx * 1.6, 0.5, -40.0), Vector3(0.8, 1.0, 3.6), "l36_skirt")
		d.box(Vector3(fx + sx * 1.6, 1.2, -40.0), Vector3(0.9, 0.6, 1.4), "l36_counter", GeoKit.ALL, false)
		for t in 4:
			d.box(Vector3(fx + sx * 1.6, 1.03, -41.2 + float(t) * 0.12), Vector3(0.55, 0.06, 0.4), "l36_dark", GeoKit.ALL, false)
	d.panel(Vector3(0, MEZZ_Y - 0.01, -40.0), 4.0, 1.0, "l36_panel", 5.0, 0.0)


# ------------------------------------------------------------------ concourse

func concourse(node: Node3D, r: RandomNumberGenerator) -> void:
	var z0 := CON_Z0
	var z1 := CON_Z1
	k.slab(-6.0, z0, 6.0, z1, 0.0, 0.5, "l36_floor_hall")
	k.slab(-6.0, z0, 6.0, z1, CON_H + 0.4, 0.4, "l36_ceiling")
	var at := func(z: float) -> float:
		return z0 - z
	k.wall(Vector3(-6, 0, z0), Vector3(-6, 0, z1), CON_H, 0.3, "l36_wall", [{"at": at.call(-68.0), "w": 14.0, "h": 4.2}])
	k.wall(Vector3(6, 0, z0), Vector3(6, 0, z1), CON_H, 0.3, "l36_wall", [{"at": at.call(-78.0), "w": 8.0, "h": 4.0}, {"at": at.call(LOOP_Z), "w": 6.0, "h": 4.2}])
	# the travelator (one-way, toward the gates)
	var t := TRAV
	k.box_mm(Vector3(t.position.x, 0, t.position.y), Vector3(t.end.x, 0.06, t.end.y), "l36_skirt")
	var mi := MeshInstance3D.new()
	var q := PlaneMesh.new()
	q.size = Vector2(t.size.y, t.size.x - 0.2)
	mi.mesh = q
	var bm: ShaderMaterial = lvl.strip.belt_on.duplicate()
	bm.set_shader_parameter("speed", 1.3)
	bm.set_shader_parameter("uscale", t.size.y)
	mi.material_override = bm
	mi.position = Vector3(0, 0.065, t.get_center().y)
	mi.rotation.y = PI * 0.5
	node.add_child(mi)
	for sx in [-1.0, 1.0]:
		var x: float = sx * (t.size.x * 0.5 + 0.12)
		k.box(Vector3(x, 0.5, t.get_center().y), Vector3(0.22, 1.0, t.size.y - 1.0), "l36_glass")
		d.box(Vector3(x, 1.02, t.get_center().y), Vector3(0.14, 0.06, t.size.y - 0.8), "l36_rubber", GeoKit.ALL, false)
		d.box(Vector3(x, 0.08, t.get_center().y), Vector3(0.26, 0.16, t.size.y - 1.0), "l36_steel", GeoKit.ALL, false)
	# seating against the walls, lights, signs that do not agree
	for z in [-50.0, -84.0, -102.0]:
		seats(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(-5.6, 0, z + 3.0)), 6)
	for z in [-50.0, -60.0, -102.0]:
		seats(Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(5.6, 0, z - 1.5 + 3.0 - 3.0)), 6)
	var z := z0 - 3.0
	var i := 0
	while z > z1 + 1.0:
		for sx in [-3.2, 3.2]:
			d.panel(Vector3(sx, CON_H - 0.01, z), 0.5, 4.0, "l36_panel_flick" if i == 5 and sx > 0 else "l36_panel", float(i * 3 + int(sx)), 1.0 if i == 5 and sx > 0 else 0.0)
		lvl.lights.add_anchor(Vector3(0, CON_H - 0.6, z), Color(0.95, 0.96, 1.0), 1.2, 10.0, 0.6 if i == 5 else 0.0)
		z -= 6.0
		i += 1
	var texts := ["GATES C30-C32  ^", "GATES C  v", "CONCOURSE M  >", "<  DUTY FREE", "EXIT  >", "BAGGAGE CLAIM  ^", "GATES A-Z  ^"]
	for j in 6:
		board_sign(node, Vector3(0, CON_H - 0.9, z0 - 8.0 - float(j) * 11.0), 0.0, texts[j % texts.size()])


## The carpeted duty-free hall (west of the concourse).
func duty_free(node: Node3D, r: RandomNumberGenerator) -> void:
	var x0 := -36.0
	var z0 := -54.0
	var z1 := -82.0
	k.slab(x0, z0, -6.0, z1, 0.0, 0.5, "l36_carpet_shop")
	k.slab(x0, z0, -6.0, z1, 6.4, 0.4, "l36_ceiling")
	k.wall(Vector3(x0, 0, z0), Vector3(-6, 0, z0), 6.0, 0.3, "l36_wall")
	k.wall(Vector3(x0, 0, z1), Vector3(-6, 0, z1), 6.0, 0.3, "l36_wall")
	k.wall(Vector3(x0, 0, z0), Vector3(x0, 0, z1), 6.0, 0.3, "l36_wall")
	k.box_mm(Vector3(-6.15, CON_H, z1), Vector3(-5.85, 6.0, z0), "l36_wall")
	# shop units along the walls: fronts, shelving, coloured fascias
	var fascia := ["l36_bag_b", "l36_bag_c", "l36_bag_d", "l36_bag_e", "l36_purple"]
	for i in 4:
		var sx := -33.0 + float(i) * 7.0
		d.box(Vector3(sx, 3.6, z0 - 0.2), Vector3(6.4, 0.6, 0.1), fascia[i % fascia.size()], GeoKit.ALL, false)
		for lv in [0.4, 1.1, 1.8]:
			d.box(Vector3(sx, lv, z0 - 0.45), Vector3(6.0, 0.04, 0.5), "l36_shelf", GeoKit.ALL, false)
			for j in 10:
				d.box(Vector3(sx - 2.7 + float(j) * 0.6, lv + 0.14, z0 - 0.45), Vector3(0.4, 0.24, 0.3), fascia[(i + j) % 4], GeoKit.ALL, false)
		k.box(Vector3(sx, 1.0, z0 - 0.45), Vector3(6.0, 2.0, 0.5), "l36_shelf", 0, true)
	for row in 3:
		for col in 3:
			var c := Vector3(-30.0 + float(col) * 8.0, 0, -62.0 - float(row) * 6.0)
			k.box(c + Vector3(0, 0.75, 0), Vector3(5.0, 1.5, 0.8), "l36_shelf")
			for lv in [0.5, 1.0, 1.5]:
				for j in 8:
					var item: String = ["kenney/food-kit/soda-bottle", "kenney/food-kit/carton", "kenney/food-kit/can-open", "kenney/food-kit/bag"][(row + col + j) % 4]
					if (row * 3 + col + j) % 3 == 0:
						Props.place(lvl, node, item, c + Vector3(-2.1 + float(j) * 0.6, lv, 0.45), 0.0, 0.2)
					else:
						d.box(c + Vector3(-2.1 + float(j) * 0.6, lv + 0.1, 0.42), Vector3(0.4, 0.2, 0.12), fascia[(row + j) % 4], GeoKit.ALL, false)
	# a clothes rail and a makeup counter
	for j in 12:
		d.box(Vector3(-32.0 + float(j) * 0.18, 1.0, -79.5), Vector3(0.06, 1.0, 0.5), fascia[j % 4], GeoKit.ALL, false)
	d.box(Vector3(-31.0, 1.55, -79.5), Vector3(2.4, 0.04, 0.04), "l36_steel", GeoKit.ALL, false)
	k.box(Vector3(-12.0, 0.5, -79.0), Vector3(4.0, 1.0, 1.0), "l36_counter")
	board_sign(node, Vector3(-8.0, 4.6, -68.0), PI * 0.5, "DUTY FREE")
	for p in [Vector3(-28, 6.39, -60), Vector3(-14, 6.39, -60), Vector3(-28, 6.39, -74), Vector3(-14, 6.39, -74)]:
		d.panel(p, 5.0, 1.0, "l36_panel", p.x, 0.0)
		lvl.lights.add_anchor(p + Vector3(0, -0.6, 0), Color(1.0, 0.95, 0.88), 1.4, 13.0)


## The Meeting Place: a sunken seating ring around a sign column.
func meeting_place(node: Node3D) -> void:
	var x0 := 6.0
	var x1 := 20.0
	var z0 := -72.0
	var z1 := -84.0
	var c := MEET
	k.slab(x0, z0, x1, c.z + 3.0, 0.0, 0.5, "l36_carpet")
	k.slab(x0, c.z - 3.0, x1, z1, 0.0, 0.5, "l36_carpet")
	k.slab(x0, c.z + 3.0, c.x - 3.0, c.z - 3.0, 0.0, 0.5, "l36_carpet")
	k.slab(c.x + 3.0, c.z + 3.0, x1, c.z - 3.0, 0.0, 0.5, "l36_carpet")
	k.slab(c.x - 3.0, c.z + 3.0, c.x + 3.0, c.z - 3.0, -0.54, 0.5, "l36_carpet")
	k.stairs(Vector3(c.x - 2.0, -0.54, c.z), Vector3(-1, 0, 0), 2.0, 0.54, 3, "l36_floor_hall", 0.33)
	k.slab(x0, z0, x1, z1, CON_H + 0.4, 0.4, "l36_ceiling")
	k.wall(Vector3(x0, 0, z0), Vector3(x1, 0, z0), CON_H, 0.3, "l36_wall")
	k.wall(Vector3(x0, 0, z1), Vector3(x1, 0, z1), CON_H, 0.3, "l36_wall")
	k.wall(Vector3(x1, 0, z0), Vector3(x1, 0, z1), CON_H, 0.3, "l36_wall")
	k.cylinder(c + Vector3(0, CON_H * 0.5 - 0.27, 0), 0.5, CON_H + 0.54, "l36_column", 16)
	d.box(c + Vector3(0, 2.6, 0), Vector3(1.4, 1.0, 1.4), "l36_signboard", GeoKit.ALL, false)
	for i in 4:
		var yaw := float(i) * PI * 0.5
		label(node, c + Basis(Vector3.UP, yaw) * Vector3(0, 2.6, 0.71), yaw, "MEETING\nPLACE", 48)
	for i in 6:
		var a := TAU * float(i) / 6.0 + 0.5
		var p := c + Vector3(cos(a) * 2.2, -0.54, sin(a) * 2.2)
		if cos(a) < -0.7:
			continue
		Props.place(lvl, node, "kenney/furniture-kit/loungesofa", p, rad_to_deg(-a) + 90.0 + 180.0, 0.82)
	for p in [Vector3(7.0, 0, -73.0), Vector3(19.0, 0, -83.0), Vector3(19.0, 0, -73.0)]:
		Props.place(lvl, node, "kenney/furniture-kit/pottedplant", p, 0.0, 1.3)
	d.panel(c + Vector3(0, CON_H - 0.01, 0), 2.0, 2.0, "l36_panel", 9.0, 0.0)
	lvl.lights.add_anchor(c + Vector3(0, CON_H - 0.8, 0), Color(1.0, 0.92, 0.8), 1.3, 10.0)


## Concourse M: a corridor that connects to itself (a seam returns you 30 m back).
func loop(node: Node3D) -> void:
	var zc := LOOP_Z
	var w := 6.0
	var h := 4.2
	k.slab(LOOP_X0, zc + w * 0.5, LOOP_X1, zc - w * 0.5, 0.0, 0.5, "l36_floor_hall")
	k.slab(LOOP_X0, zc + w * 0.5, LOOP_X1, zc - w * 0.5, h + 0.4, 0.4, "l36_ceiling")
	k.wall(Vector3(LOOP_X0, 0, zc + w * 0.5), Vector3(LOOP_X1, 0, zc + w * 0.5), h, 0.3, "l36_wall")
	k.wall(Vector3(LOOP_X0, 0, zc - w * 0.5), Vector3(LOOP_X1, 0, zc - w * 0.5), h, 0.3, "l36_wall")
	k.wall(Vector3(LOOP_X1, 0, zc + w * 0.5), Vector3(LOOP_X1, 0, zc - w * 0.5), h, 0.3, "l36_wall")
	k.box_mm(Vector3(5.85, CON_H - 1.3, zc - 3.0), Vector3(6.15, CON_H, zc + 3.0), "l36_wall")
	var x := 12.0
	while x < LOOP_X1 - 20.0:
		d.panel(Vector3(x, h - 0.01, zc), 0.5, 3.0, "l36_panel", x, 0.0)
		lvl.lights.add_anchor(Vector3(x, h - 0.6, zc), Color(0.95, 0.96, 1.0), 0.9, 8.0)
		x += 10.0
	for base in [0.0, LOOP_PERIOD]:
		seats(Transform3D(Basis(), Vector3(14.0 + base, 0, zc - 2.5)), 6)
		board_sign(node, Vector3(20.0 + base, h - 0.8, zc), PI * 0.5, "CONCOURSE M  >")
		board_sign(node, Vector3(26.0 + base, h - 0.8, zc), -PI * 0.5, "<  CONCOURSE M")
		d.box(Vector3(24.0 + base, 2.0, zc + 2.84), Vector3(3.0, 1.6, 0.04), "l36_screen", GeoKit.ALL, false)
