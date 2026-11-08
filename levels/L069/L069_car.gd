extends RefCounted
## Level 69 car: a plain four-door sedan of no recognisable make ("none of the
## cars ... are of any recognizable brand or model"), built in-project. Local
## frame: forward is -z, origin on the road under the car's centre.
## The hidden compartment at the bottom centre holds the Fragment Of
## Destivinatia (Object 69): while it sits in its slot the car repels fog and
## entities (a clear bubble of air around the car).

const EYE := Vector3(-0.4, 1.17, 0.2)          # driver's eye
const SEAT_EXIT_L := Vector3(-1.55, 0.0, 0.1)
const SEAT_EXIT_R := Vector3(1.55, 0.0, 0.1)

static func _mat(name: String, c: Color, rough: float, metal: float = 0.0, emit: Color = Color.BLACK, e: float = 0.0, alpha: float = 1.0) -> String:
	if MatLib.has_mat(name):
		return name
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.roughness = rough
	m.metallic = metal
	if e > 0.0:
		m.emission_enabled = true
		m.emission = emit
		m.emission_energy_multiplier = e
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.metallic_specular = 0.9
	MatLib.register(name, m)
	return name


## Builds the visual car under `car`. Returns handles the level animates.
static func build(car: Node3D, paint: Color, left_lamp_dead: bool) -> Dictionary:
	var body := _mat("l69_paint_%02x%02x%02x" % [int(paint.r * 255), int(paint.g * 255), int(paint.b * 255)], paint, 0.42, 0.35)
	var dark := _mat("l69_car_dark", Color(0.035, 0.035, 0.04), 0.7)
	var trim := _mat("l69_car_chrome", Color(0.6, 0.6, 0.62), 0.25, 0.9)
	var glass := _mat("l69_car_glass", Color(0.08, 0.1, 0.11), 0.05, 0.0, Color.BLACK, 0.0, 0.32)
	var cloth := _mat("l69_car_cloth", Color(0.13, 0.12, 0.11), 0.95)
	var dash := _mat("l69_car_dash", Color(0.08, 0.08, 0.08), 0.6)
	var gauge := _mat("l69_car_gauge", Color(0.2, 0.15, 0.05), 0.5, 0.0, Color(1.0, 0.55, 0.15), 0.6)
	var lamp := _mat("l69_car_lamp", Color(0.9, 0.9, 0.85), 0.2, 0.0, Color(1.0, 0.95, 0.85), 4.0)
	var lamp_off := _mat("l69_car_lamp_off", Color(0.5, 0.5, 0.48), 0.2)
	var tail := _mat("l69_car_tail", Color(0.4, 0.02, 0.02), 0.3, 0.0, Color(1.0, 0.05, 0.03), 2.0)
	var k := GeoKit.new(car, "CarBody")
	k.shadows = true
	# lower body: hood block, boot block, door panels, floor pan
	k.box_mm(Vector3(-0.91, 0.34, -2.25), Vector3(0.91, 0.9, -0.88), body, GeoKit.ALL, false)
	k.box_mm(Vector3(-0.91, 0.34, 1.18), Vector3(0.91, 0.95, 2.25), body, GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		k.box_mm(Vector3(minf(s * 0.83, s * 0.91), 0.34, -0.88), Vector3(maxf(s * 0.83, s * 0.91), 0.98, 1.18), body, GeoKit.ALL, false)
		k.box(Vector3(s * 0.915, 0.62, 0.15), Vector3(0.01, 0.6, 0.012), dark, GeoKit.ALL, false)
		k.box(Vector3(s * 0.915, 0.8, -0.3), Vector3(0.02, 0.03, 0.18), trim, GeoKit.ALL, false)
		k.box(Vector3(s * 0.915, 0.8, 0.62), Vector3(0.02, 0.03, 0.18), trim, GeoKit.ALL, false)
		k.box(Vector3(s * 0.78, 1.18, 0.25), Vector3(0.012, 0.4, 1.72), glass, GeoKit.SIDES, false)
		k.box(Vector3(s * 0.77, 1.18, 0.25), Vector3(0.07, 0.42, 0.08), body, GeoKit.ALL, false)    # B pillar
		k.box_xf(Transform3D(Basis(Vector3.RIGHT, -0.78), Vector3(s * 0.74, 1.19, -0.84)), Vector3(0.07, 0.05, 0.6), body, GeoKit.ALL, false)
		k.box_xf(Transform3D(Basis(Vector3.RIGHT, 0.86), Vector3(s * 0.74, 1.19, 1.32)), Vector3(0.09, 0.05, 0.6), body, GeoKit.ALL, false)
		k.box(Vector3(s * 0.96, 1.02, -0.72), Vector3(0.12, 0.08, 0.16), dark, GeoKit.ALL, false)    # mirror
	k.box_mm(Vector3(-0.83, 0.34, -0.88), Vector3(0.83, 0.42, 1.18), dark, GeoKit.PY, false)
	k.box(Vector3(0, 0.93, -1.56), Vector3(1.78, 0.06, 1.34), body, GeoKit.PY, false)
	k.box(Vector3(0, 0.97, 1.7), Vector3(1.78, 0.04, 1.0), body, GeoKit.PY, false)
	# cabin: roof, windscreen, rear window
	k.box(Vector3(0, 1.41, 0.25), Vector3(1.52, 0.05, 1.76), body)
	k.box_xf(Transform3D(Basis(Vector3.RIGHT, -0.78), Vector3(0, 1.19, -0.84)), Vector3(1.48, 0.012, 0.6), glass, GeoKit.PY | GeoKit.NY, false)
	k.box_xf(Transform3D(Basis(Vector3.RIGHT, 0.86), Vector3(0, 1.19, 1.32)), Vector3(1.48, 0.012, 0.6), glass, GeoKit.PY | GeoKit.NY, false)
	# bumpers, grille, lamps
	k.box(Vector3(0, 0.44, -2.29), Vector3(1.86, 0.22, 0.12), dark, GeoKit.ALL, false)
	k.box(Vector3(0, 0.44, 2.29), Vector3(1.86, 0.22, 0.12), dark, GeoKit.ALL, false)
	k.box(Vector3(0, 0.7, -2.26), Vector3(0.72, 0.18, 0.03), dark, GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		var dead: bool = s < 0.0 and left_lamp_dead
		k.box(Vector3(s * 0.62, 0.73, -2.26), Vector3(0.4, 0.15, 0.04), lamp_off if dead else lamp, GeoKit.ALL, false)
		k.box(Vector3(s * 0.66, 0.82, 2.26), Vector3(0.36, 0.13, 0.04), tail, GeoKit.ALL, false)
	k.box(Vector3(0, 0.62, 2.265), Vector3(0.5, 0.14, 0.02), dark, GeoKit.ALL, false)
	# interior: dash, gauges, seats, floor
	k.box(Vector3(0, 0.95, -0.72), Vector3(1.62, 0.22, 0.36), dash, GeoKit.ALL, false)
	k.box(Vector3(0.05, 1.0, -0.545), Vector3(0.22, 0.12, 0.02), dash, GeoKit.PZ, false)
	for x in [-0.4, 0.4]:
		k.box(Vector3(x, 0.56, 0.2), Vector3(0.52, 0.14, 0.52), cloth, GeoKit.ALL, false)
		k.box_xf(Transform3D(Basis(Vector3.RIGHT, -0.22), Vector3(x, 0.92, 0.5)), Vector3(0.5, 0.62, 0.12), cloth, GeoKit.ALL, false)
		k.box(Vector3(x, 1.28, 0.58), Vector3(0.26, 0.16, 0.1), cloth, GeoKit.ALL, false)
	k.box(Vector3(0, 0.56, 0.95), Vector3(1.5, 0.14, 0.5), cloth, GeoKit.ALL, false)
	k.box_xf(Transform3D(Basis(Vector3.RIGHT, -0.2), Vector3(0, 0.88, 1.16)), Vector3(1.5, 0.56, 0.12), cloth, GeoKit.ALL, false)
	k.commit()
	# steering wheel and wheels
	var wheel := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.16
	tm.outer_radius = 0.19
	tm.rings = 18
	tm.ring_segments = 6
	wheel.mesh = tm
	wheel.material_override = MatLib.get_mat(dark)
	wheel.position = Vector3(-0.4, 0.9, -0.36)
	wheel.rotation.x = deg_to_rad(60.0)
	car.add_child(wheel)
	for gx in [-0.5, -0.3]:
		var dial := MeshInstance3D.new()
		var dm := CylinderMesh.new()
		dm.top_radius = 0.055
		dm.bottom_radius = 0.055
		dm.height = 0.01
		dm.radial_segments = 16
		dial.mesh = dm
		dial.material_override = MatLib.get_mat(gauge)
		dial.position = Vector3(gx, 1.0, -0.54)
		dial.rotation.x = PI * 0.5
		car.add_child(dial)
		var needle := MeshInstance3D.new()
		var nm := BoxMesh.new()
		nm.size = Vector3(0.006, 0.045, 0.004)
		needle.mesh = nm
		needle.material_override = MatLib.get_mat(lamp)
		needle.position = Vector3(gx, 1.01, -0.532)
		needle.rotation.z = -0.7
		car.add_child(needle)
	var wheels: Array = []
	for p in [Vector3(-0.82, 0.33, -1.38), Vector3(0.82, 0.33, -1.38), Vector3(-0.82, 0.33, 1.42), Vector3(0.82, 0.33, 1.42)]:
		var w := Node3D.new()
		w.position = p
		car.add_child(w)
		var tyre := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.33
		cm.bottom_radius = 0.33
		cm.height = 0.23
		cm.radial_segments = 18
		tyre.mesh = cm
		tyre.material_override = MatLib.get_mat(dark)
		tyre.rotation.z = PI * 0.5
		w.add_child(tyre)
		var hub := MeshInstance3D.new()
		var hm := CylinderMesh.new()
		hm.top_radius = 0.19
		hm.bottom_radius = 0.19
		hm.height = 0.24
		hm.radial_segments = 10
		hub.mesh = hm
		hub.material_override = MatLib.get_mat(trim)
		hub.rotation.z = PI * 0.5
		w.add_child(hub)
		wheels.append(w)
	# headlights (the only light on the level besides your own)
	var beams: Array = []
	for s in [-1.0, 1.0]:
		if s < 0.0 and left_lamp_dead:
			continue
		var sl := SpotLight3D.new()
		sl.position = Vector3(s * 0.62, 0.74, -2.3)
		sl.rotation.x = deg_to_rad(-4.0)
		sl.spot_range = 55.0
		sl.spot_angle = 30.0
		sl.spot_attenuation = 0.9
		sl.light_energy = 12.0
		sl.light_color = Color(1.0, 0.94, 0.82)
		sl.light_volumetric_fog_energy = 1.4
		sl.shadow_enabled = false
		car.add_child(sl)
		beams.append(sl)
	var red := OmniLight3D.new()
	red.position = Vector3(0, 0.8, 2.5)
	red.light_color = Color(1.0, 0.08, 0.04)
	red.light_energy = 0.8
	red.omni_range = 4.0
	red.light_volumetric_fog_energy = 0.6
	car.add_child(red)
	var glow := OmniLight3D.new()
	glow.position = Vector3(-0.35, 1.05, -0.45)
	glow.light_color = Color(1.0, 0.6, 0.25)
	glow.light_energy = 0.05
	glow.omni_range = 0.8
	car.add_child(glow)
	# the hidden compartment and the Fragment
	var frag := _fragment()
	frag.position = Vector3(0, 0.3, 0.15)
	car.add_child(frag)
	var bubble := FogVolume.new()
	bubble.size = Vector3(11.0, 6.0, 14.0)
	bubble.shape = RenderingServer.FOG_VOLUME_SHAPE_ELLIPSOID
	var fm := FogMaterial.new()
	fm.density = -1.2
	bubble.material = fm
	bubble.position = Vector3(0, 1.5, -1.0)
	car.add_child(bubble)
	return {"beams": beams, "wheels": wheels, "fragment": frag, "bubble": bubble, "steer": wheel, "tail": red}


## Object 69: a thick triangular shard with glass-like properties in its slot.
static func _fragment() -> Node3D:
	var root := Node3D.new()
	root.name = "Fragment"
	var slot := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.36, 0.05, 0.36)
	slot.mesh = bm
	slot.material_override = MatLib.get_mat(_mat("l69_car_dark", Color(0.035, 0.035, 0.04), 0.7))
	slot.position = Vector3(0, 0.02, 0)
	root.add_child(slot)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r := 0.12
	var t := 0.035
	var pts: Array = []
	for i in 3:
		var a := TAU * float(i) / 3.0
		pts.append(Vector3(cos(a) * r, 0, sin(a) * r))
	for y in [-t, t]:
		for i in 3:
			st.set_normal(Vector3.UP * signf(y))
			st.add_vertex(pts[i if y > 0.0 else 2 - i] + Vector3(0, y, 0))
	for i in 3:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[(i + 1) % 3]
		var n := ((a + b) * 0.5).normalized()
		for v in [a + Vector3(0, -t, 0), b + Vector3(0, -t, 0), b + Vector3(0, t, 0), a + Vector3(0, -t, 0), b + Vector3(0, t, 0), a + Vector3(0, t, 0)]:
			st.set_normal(n)
			st.add_vertex(v)
	var shard := MeshInstance3D.new()
	shard.name = "Shard"
	shard.mesh = st.commit()
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.75, 0.88, 0.95, 0.55)
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.roughness = 0.02
	gm.metallic_specular = 1.0
	gm.cull_mode = BaseMaterial3D.CULL_DISABLED
	gm.emission_enabled = true
	gm.emission = Color(0.5, 0.8, 0.9)
	gm.emission_energy_multiplier = 0.25
	shard.material_override = gm
	shard.position = Vector3(0, -0.02, 0)
	root.add_child(shard)
	return root
