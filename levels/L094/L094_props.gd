extends RefCounted
## Level 94 objects built from the same clay: 1930s cars and Almond Milk vans,
## siren poles, the hills' water tower (Almond Water), the "wall with furniture
## next to it" fragments, and the floating castle on its Transparent Mountain.

var lv
var wheel_mesh: CylinderMesh
var lamp_mesh: SphereMesh
var horn_mesh: CylinderMesh
var bottle_mesh: CylinderMesh
var r := RandomNumberGenerator.new()
const BODY := ["l94_car_black", "l94_car_maroon", "l94_car_green", "l94_car_cream", "l94_car_blue"]


func _init(level) -> void:
	lv = level
	r.seed = 94050
	wheel_mesh = CylinderMesh.new()
	wheel_mesh.top_radius = 0.38
	wheel_mesh.bottom_radius = 0.38
	wheel_mesh.height = 0.2
	wheel_mesh.radial_segments = 14
	lamp_mesh = SphereMesh.new()
	lamp_mesh.radius = 0.13
	lamp_mesh.height = 0.26
	lamp_mesh.radial_segments = 10
	lamp_mesh.rings = 5
	horn_mesh = CylinderMesh.new()
	horn_mesh.top_radius = 0.36
	horn_mesh.bottom_radius = 0.07
	horn_mesh.height = 0.85
	horn_mesh.radial_segments = 12
	horn_mesh.cap_top = false
	bottle_mesh = CylinderMesh.new()
	bottle_mesh.top_radius = 0.035
	bottle_mesh.bottom_radius = 0.045
	bottle_mesh.height = 0.26
	bottle_mesh.radial_segments = 6


static func materials(clay: Callable) -> void:
	clay.call("l94_car_black", Color(0.06, 0.06, 0.07), Color(0.04, 0.04, 0.05), 0, 1.0, 0.5)
	clay.call("l94_car_maroon", Color(0.38, 0.06, 0.07), Color(0.32, 0.05, 0.06), 0, 1.0, 0.5)
	clay.call("l94_car_green", Color(0.08, 0.25, 0.14), Color(0.06, 0.2, 0.11), 0, 1.0, 0.5)
	clay.call("l94_car_cream", Color(0.8, 0.72, 0.55), Color(0.74, 0.66, 0.5), 0, 1.0, 0.5)
	clay.call("l94_car_blue", Color(0.14, 0.2, 0.42), Color(0.11, 0.16, 0.36), 0, 1.0, 0.5)
	clay.call("l94_chrome_metal", Color(0.75, 0.75, 0.72), Color(0.65, 0.65, 0.62), 0, 2.0, 0.3)
	clay.call("l94_tyre_rubber", Color(0.03, 0.03, 0.03), Color(0.05, 0.05, 0.05), 0, 2.0, 0.6)
	clay.call("l94_van_cream", Color(0.86, 0.82, 0.7), Color(0.8, 0.76, 0.64), 0, 1.0, 0.6)
	clay.call("l94_van_red", Color(0.6, 0.1, 0.1), Color(0.52, 0.08, 0.08), 0, 1.0, 0.6)
	clay.call("l94_milk_white", Color(0.92, 0.9, 0.84), Color(0.88, 0.86, 0.8), 0, 3.0, 0.2)
	clay.call("l94_tower_wood", Color(0.42, 0.3, 0.2), Color(0.35, 0.24, 0.16), 1, 0.8)
	clay.call("l94_tank_metal", Color(0.55, 0.6, 0.62), Color(0.48, 0.52, 0.55), 1, 0.5, 0.6)
	clay.call("l94_castle_pink", Color(0.85, 0.6, 0.65), Color(0.78, 0.54, 0.6), 2, 0.4)
	clay.call("l94_castle_blue", Color(0.25, 0.35, 0.75), Color(0.2, 0.3, 0.68), 4, 0.5)
	clay.call("l94_castle_gold", Color(0.9, 0.7, 0.2), Color(0.82, 0.6, 0.15), 0, 1.0)


func _mi(parent: Node3D, mesh: Mesh, mat: String, xf: Transform3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = MatLib.get_mat(mat)
	mi.transform = xf
	mi.visibility_range_end = 140.0
	parent.add_child(mi)
	return mi


## A 1930s car: tall upright cab, long bonnet, sweeping fenders, running boards
## and spoked wheels. Local +Z forward; `o` on the ground.
func car(k: GeoKit, parent: Node3D, o: Vector3, yaw: float, body: String = "") -> void:
	if body == "":
		body = BODY[r.randi() % BODY.size()]
	var bas := Basis(Vector3.UP, yaw)
	var L := func(v: Vector3) -> Vector3: return o + bas * v
	var B := func(c: Vector3, s: Vector3, m: String, rx := 0.0) -> void:
		k.box_xf(Transform3D(bas * Basis(Vector3(1, 0, 0), rx), L.call(c)), s, m, GeoKit.ALL, false)
	B.call(Vector3(0, 0.5, 0), Vector3(1.5, 0.22, 3.9), "l94_car_black")
	for s in [-1.0, 1.0]:
		B.call(Vector3(s * 0.88, 0.42, -0.1), Vector3(0.28, 0.05, 1.6), "l94_car_black")
		B.call(Vector3(s * 0.78, 0.72, 1.25), Vector3(0.36, 0.3, 1.2), body, 0.35)
		B.call(Vector3(s * 0.78, 0.72, -1.45), Vector3(0.36, 0.3, 1.0), body, -0.4)
	B.call(Vector3(0, 0.98, 1.15), Vector3(1.0, 0.56, 1.5), body)
	B.call(Vector3(0, 0.98, 1.93), Vector3(0.8, 0.72, 0.08), "l94_chrome_metal")
	B.call(Vector3(0, 0.95, -0.35), Vector3(1.55, 0.6, 1.9), body)
	B.call(Vector3(0, 1.48, -0.35), Vector3(1.42, 0.42, 1.75), "l94_glass")
	for zz in [0.55, -0.35, -1.25]:
		for s in [-1.0, 1.0]:
			B.call(Vector3(s * 0.73, 1.48, zz), Vector3(0.08, 0.44, 0.08), body)
	B.call(Vector3(0, 1.74, -0.35), Vector3(1.58, 0.12, 1.95), body)
	B.call(Vector3(0, 0.95, -1.62), Vector3(1.3, 0.7, 0.7), body)
	B.call(Vector3(0, 0.62, 2.05), Vector3(1.7, 0.08, 0.1), "l94_chrome_metal")
	for s in [-1.0, 1.0]:
		_mi(parent, lamp_mesh, "l94_chrome_metal", Transform3D(bas, L.call(Vector3(s * 0.62, 1.1, 1.85))))
		for zz in [1.25, -1.45]:
			_mi(parent, wheel_mesh, "l94_tyre_rubber", Transform3D(bas * Basis(Vector3(0, 0, 1), PI * 0.5), L.call(Vector3(s * 0.74, 0.38, zz))))
			_mi(parent, lamp_mesh, "l94_chrome_metal", Transform3D(bas * Basis().scaled(Vector3(1.0, 0.4, 1.0)) * Basis(Vector3(0, 0, 1), PI * 0.5), L.call(Vector3(s * 0.86, 0.38, zz))))
	_collider(parent, o + Vector3(0, 0.9, 0), bas, Vector3(1.8, 1.8, 4.1))


## An Almond Milk van: car-style cab, a tall box body, crates of bottles.
func van(k: GeoKit, parent: Node3D, o: Vector3, yaw: float) -> void:
	var bas := Basis(Vector3.UP, yaw)
	var L := func(v: Vector3) -> Vector3: return o + bas * v
	var B := func(c: Vector3, s: Vector3, m: String, rx := 0.0) -> void:
		k.box_xf(Transform3D(bas * Basis(Vector3(1, 0, 0), rx), L.call(c)), s, m, GeoKit.ALL, false)
	B.call(Vector3(0, 0.5, 0), Vector3(1.6, 0.22, 4.6), "l94_car_black")
	B.call(Vector3(0, 0.98, 1.65), Vector3(1.0, 0.56, 1.2), "l94_van_red")
	B.call(Vector3(0, 0.98, 2.27), Vector3(0.8, 0.72, 0.08), "l94_chrome_metal")
	B.call(Vector3(0, 1.1, 0.6), Vector3(1.7, 0.9, 1.0), "l94_van_red")
	B.call(Vector3(0, 1.75, 0.6), Vector3(1.6, 0.4, 0.95), "l94_glass")
	B.call(Vector3(0, 1.62, -1.0), Vector3(1.9, 2.15, 2.6), "l94_van_cream")
	B.call(Vector3(0, 2.72, -0.6), Vector3(1.95, 0.12, 3.4), "l94_van_red")
	B.call(Vector3(0, 1.2, -1.0), Vector3(1.94, 0.25, 2.62), "l94_van_red")
	for s in [-1.0, 1.0]:
		B.call(Vector3(s * 0.8, 0.72, 1.6), Vector3(0.36, 0.3, 1.1), "l94_van_red", 0.35)
		_mi(parent, lamp_mesh, "l94_chrome_metal", Transform3D(bas, L.call(Vector3(s * 0.62, 1.1, 2.2))))
		for zz in [1.6, -1.6]:
			_mi(parent, wheel_mesh, "l94_tyre_rubber", Transform3D(bas * Basis(Vector3(0, 0, 1), PI * 0.5), L.call(Vector3(s * 0.8, 0.38, zz))))
		var lb := Label3D.new()
		lb.text = "ALMOND MILK\nfresh daily"
		lb.font_size = 56
		lb.pixel_size = 0.006
		lb.modulate = Color(0.55, 0.08, 0.08)
		lb.outline_size = 0
		lb.shaded = true
		lb.double_sided = false
		lb.position = L.call(Vector3(s * 0.96, 1.85, -1.0))
		lb.rotation.y = yaw + s * PI * 0.5
		lb.visibility_range_end = 60.0
		parent.add_child(lb)
	# rear doors open on crates of bottles
	for s in [-1.0, 1.0]:
		k.box_xf(Transform3D(bas * Basis(Vector3.UP, s * 1.4), L.call(Vector3(s * 1.25, 1.62, -2.65))), Vector3(0.95, 2.0, 0.05), "l94_van_cream", GeoKit.ALL, false)
	for i in 4:
		var cpos := Vector3(-0.45 + (i % 2) * 0.9, 0.62 + int(i / 2) * 0.38, -2.0)
		B.call(cpos + Vector3(0, 0.12, 0), Vector3(0.8, 0.28, 0.5), "l94_tower_wood")
		for b in 6:
			_mi(parent, bottle_mesh, "l94_milk_white", Transform3D(bas, L.call(cpos + Vector3(-0.3 + (b % 3) * 0.3, 0.38, -0.1 + int(b / 3) * 0.2))))
	_collider(parent, o + Vector3(0, 1.4, 0) + bas * Vector3(0, 0, -0.2), bas, Vector3(2.0, 2.8, 4.6))


func _collider(parent: Node3D, c: Vector3, bas: Basis, s: Vector3) -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = s
	cs.shape = bs
	cs.transform = Transform3D(bas, c)
	cs.set_meta("surface", "metal")
	body.add_child(cs)
	parent.add_child(body)


## A siren pole: a tall mast with a cluster of horn speakers.
func siren_pole(k: GeoKit, parent: Node3D, o: Vector3) -> Vector3:
	k.cylinder(o + Vector3(0, 3.6, 0), 0.13, 7.2, "l94_metal_pole", 10)
	k.cylinder(o + Vector3(0, 0.25, 0), 0.32, 0.5, "l94_kerb_concrete", 10)
	k.box(o + Vector3(0, 7.25, 0), Vector3(0.5, 0.4, 0.5), "l94_metal_pole", GeoKit.ALL, false)
	for i in 4:
		var a := TAU * i / 4.0 + PI * 0.25
		var d := Vector3(cos(a), 0, sin(a))
		var xf := Transform3D(Basis(Vector3.UP, -a) * Basis(Vector3(0, 0, 1), -PI * 0.5 + 0.2), o + Vector3(0, 7.0, 0) + d * 0.55)
		_mi(parent, horn_mesh, "l94_chrome_metal", xf).visibility_range_end = 220.0
	return o + Vector3(0, 7.0, 0)


## The Almond Water tower out in the hills: four legs, a ladder to a catwalk
## round the tank (a second walkable height).
func water_tower(k: GeoKit, parent: Node3D, o: Vector3) -> Dictionary:
	var top := 9.5
	for dx in [-2.2, 2.2]:
		for dz in [-2.2, 2.2]:
			k.box(o + Vector3(dx, top * 0.5 - 0.5, dz), Vector3(0.35, top + 1.0, 0.35), "l94_tower_wood")
	for y in [3.0, 6.5]:
		for s in [-1.0, 1.0]:
			k.box(o + Vector3(0, y, s * 2.2), Vector3(4.6, 0.2, 0.2), "l94_tower_wood", GeoKit.ALL, false)
			k.box(o + Vector3(s * 2.2, y, 0), Vector3(0.2, 0.2, 4.6), "l94_tower_wood", GeoKit.ALL, false)
	k.box_mm(o + Vector3(-3.6, top - 0.2, -3.6), o + Vector3(3.6, top, 3.6), "l94_tower_wood")
	for s in [-1.0, 1.0]:
		k.box(o + Vector3(s * 3.55, top + 0.55, 0), Vector3(0.08, 1.0, 7.2), "l94_tower_wood", GeoKit.ALL, true)
		k.box(o + Vector3(0, top + 0.55, s * 3.55), Vector3(7.2, 1.0, 0.08), "l94_tower_wood", GeoKit.ALL, true)
	k.cylinder(o + Vector3(0, top + 2.4, 0), 2.8, 4.4, "l94_tank_metal", 20)
	for i in 6:
		var t := float(i) / 6.0
		k.cylinder(o + Vector3(0, top + 4.6 + t * 1.5, 0), 3.0 * (1.0 - t) + 0.1, 1.5 / 6.0 + 0.02, "l94_roof_red", 16, false)
	# the ladder: rungs on the south side, climbable volume
	var lx := o + Vector3(0, 0, 3.75)
	for s in [-1.0, 1.0]:
		k.box(lx + Vector3(s * 0.25, top * 0.5, 0), Vector3(0.06, top + 0.9, 0.06), "l94_metal_pole", GeoKit.ALL, false)
	for i in int(top / 0.3):
		k.box(lx + Vector3(0, 0.3 + i * 0.3, 0), Vector3(0.5, 0.04, 0.04), "l94_metal_pole", GeoKit.ALL, false)
	var lad := LadderVolume.new()
	lad.name = "TowerLadder"
	parent.add_child(lad)
	lad.setup(lx + Vector3(-0.45, 0.0, -0.1), lx + Vector3(0.45, top + 1.2, 0.6))
	var lb := Label3D.new()
	lb.text = "ALMOND WATER"
	lb.font_size = 96
	lb.pixel_size = 0.012
	lb.modulate = Color(0.5, 0.12, 0.1)
	lb.shaded = true
	lb.position = o + Vector3(0, top + 2.6, 2.82)
	parent.add_child(lb)
	return {"deck": o + Vector3(0, top, 0), "ladder": lx}


## A room fragment in the open hills: just one papered wall with a window and
## a set of furniture standing in front of it.
func fragment(k: GeoKit, parent: Node3D, o: Vector3, yaw: float, rr: RandomNumberGenerator) -> void:
	var bas := Basis(Vector3.UP, yaw)
	var L := func(v: Vector3) -> Vector3: return o + bas * v
	var wl: String = ["l94_wallpaper", "l94_mint_plaster", "l94_salmon_plaster", "l94_sky_plaster"][rr.randi() % 4]
	k.wall(L.call(Vector3(-2.6, -0.3, 0)), L.call(Vector3(2.6, -0.3, 0)), 3.0, 0.18, wl, [{"at": 3.6, "w": 0.9, "h": 1.1, "sill": 1.2}])
	k.box_xf(Transform3D(bas, L.call(Vector3(0, 0.02, 1.4))), Vector3(5.2, 0.05, 2.8), "l94_wood_floor", GeoKit.ALL, false)
	k.box_xf(Transform3D(bas, L.call(Vector3(-0.8, 2.7, 0))), Vector3(5.6, 0.1, 0.3), "l94_trim_white", GeoKit.ALL, false)
	var yd := rad_to_deg(yaw)
	var sets := [["ph/Sofa_01", Vector3(0, 0.05, 0.6), 0.0], ["ph/ArmChair_01", Vector3(-1.8, 0.05, 1.0), 30.0], ["ph/coffee_table_round_01", Vector3(0, 0.05, 1.7), 0.0],
		["ph/vintage_grandfather_clock_01", Vector3(2.2, 0.05, 0.4), 0.0], ["ph/wooden_bookshelf_worn", Vector3(1.6, 0.05, 0.45), 0.0], ["ph/GreenChair_01", Vector3(1.0, 0.05, 1.6), -40.0],
		["ph/Television_01", Vector3(-1.4, 0.05, 0.5), 10.0], ["ph/old_bed_frame", Vector3(0.6, 0.05, 1.2), 90.0], ["ph/dining_table", Vector3(0, 0.05, 1.4), 0.0]]
	for i in rr.randi_range(2, 4):
		var e: Array = sets[rr.randi() % sets.size()]
		Props.place(lv, parent, e[0], L.call(e[1] + Vector3(rr.randf_range(-0.3, 0.3), 0, 0)), yd + float(e[2]), 0.0 if e[0] != "ph/coffee_table_round_01" else 0.45)
	Props.place(lv, parent, "kenney/furniture-kit/rugrectangle", L.call(Vector3(0, 0.06, 1.3)), yd, 0.02)
	Props.place(lv, parent, "ph/wall_clock", L.call(Vector3(-0.8, 2.1, 0.12)), yd)


## The floating castle on its "Transparent Mountain": an upturned peak of
## clear crystal hanging in the sky, a toy castle of towers on its flat top.
func castle(parent: Node3D, c: Vector3) -> void:
	var root := Node3D.new()
	root.name = "FloatingCastle"
	root.position = c
	root.scale = Vector3.ONE * 1.4
	parent.add_child(root)
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_back, depth_draw_never, specular_schlick_ggx;
uniform float lum = 1.0;
void fragment() {
	float f = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	ALBEDO = mix(vec3(0.62, 0.8, 0.9), vec3(0.9, 0.97, 1.0), f) * lum;
	ALPHA = 0.16 + 0.55 * f;
	ROUGHNESS = 0.05;
	METALLIC = 0.0;
	SPECULAR = 0.9;
	EMISSION = vec3(0.25, 0.32, 0.36) * f * lum;
}
"""
	var glass := ShaderMaterial.new()
	glass.shader = sh
	var mt := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 70.0
	cm.bottom_radius = 3.0
	cm.height = 120.0
	cm.radial_segments = 9
	cm.rings = 3
	mt.mesh = cm
	mt.material_override = glass
	mt.position = Vector3(0, -60.0, 0)
	mt.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mt)
	var add := func(mesh: Mesh, mat: String, pos: Vector3) -> void:
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = MatLib.get_mat(mat)
		mi.position = pos
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
	var wall := BoxMesh.new()
	wall.size = Vector3(60.0, 14.0, 4.0)
	for i in 4:
		var mi := MeshInstance3D.new()
		mi.mesh = wall
		mi.material_override = MatLib.get_mat("l94_castle_pink")
		mi.position = Vector3(0, 7.0, 0) + Vector3(cos(TAU * i / 4.0), 0, sin(TAU * i / 4.0)) * 28.0
		mi.rotation.y = TAU * i / 4.0 + PI * 0.5
		root.add_child(mi)
	var specs := [[Vector2(-28, -28), 7.0, 30.0], [Vector2(28, -28), 7.0, 30.0], [Vector2(-28, 28), 7.0, 30.0], [Vector2(28, 28), 7.0, 30.0],
		[Vector2(0, 0), 12.0, 46.0], [Vector2(-10, 12), 6.0, 36.0], [Vector2(13, -9), 5.0, 40.0]]
	for s in specs:
		var tw := CylinderMesh.new()
		tw.top_radius = s[1]
		tw.bottom_radius = s[1]
		tw.height = s[2]
		tw.radial_segments = 14
		add.call(tw, "l94_castle_pink", Vector3(s[0].x, s[2] * 0.5, s[0].y))
		var rf := CylinderMesh.new()
		rf.top_radius = 0.0
		rf.bottom_radius = s[1] * 1.25
		rf.height = s[1] * 2.4
		rf.radial_segments = 14
		add.call(rf, "l94_castle_blue", Vector3(s[0].x, s[2] + s[1] * 1.2, s[0].y))
		var fl := BoxMesh.new()
		fl.size = Vector3(0.6, 6.0, 0.6)
		add.call(fl, "l94_castle_gold", Vector3(s[0].x, s[2] + s[1] * 2.4 + 3.0, s[0].y))
	var gate := BoxMesh.new()
	gate.size = Vector3(12.0, 18.0, 6.0)
	add.call(gate, "l94_castle_gold", Vector3(0, 9.0, 29.0))
