extends RefCounted
## Level 24 built sites. B.N.T.G. PlasticWorks (the new automated mine: three
## benched mining columns under gantries, a processing shed with a control
## mezzanine, a fenced crew compound with the main gate, floodlights) and the
## marker poles along the road. The Bluehole ruin is in L024_bluehole.gd.

const T := preload("res://levels/L024/L024_terrain.gd")

var lv
var ter
var k: GeoKit
var rng: RandomNumberGenerator
var props: Node3D
var spots := {}
var light_pts: Array = []


func _init(level, terrain, r: RandomNumberGenerator) -> void:
	lv = level
	ter = terrain
	rng = r
	k = level.kit("PlasticWorks")
	props = Node3D.new()
	props.name = "WorksProps"
	level.add_child(props)


static func materials() -> void:
	MatLib.define("l24_steel", {"albedo_a": Color(0.3, 0.31, 0.32), "albedo_b": Color(0.22, 0.23, 0.24), "metallic_value": 0.5, "roughness_a": 0.45, "stain_amount": 0.2}, "")
	MatLib.define("l24_yellow", {"albedo_a": Color(0.62, 0.42, 0.04), "albedo_b": Color(0.55, 0.36, 0.03), "metallic_value": 0.3, "roughness_a": 0.5, "stain_amount": 0.25, "stain_color": Color(0.3, 0.25, 0.2)}, "")
	MatLib.define("l24_panel", {"albedo_a": Color(0.55, 0.56, 0.56), "albedo_b": Color(0.48, 0.49, 0.5), "pattern": 2, "pattern_scale": Vector2(0.3, 3.0), "pattern_strength": 0.2, "metallic_value": 0.35, "roughness_a": 0.4}, "")
	MatLib.define("l24_blue_panel", {"albedo_a": Color(0.08, 0.17, 0.36), "albedo_b": Color(0.06, 0.13, 0.3), "pattern": 2, "pattern_scale": Vector2(0.3, 3.0), "pattern_strength": 0.2, "metallic_value": 0.3, "roughness_a": 0.45}, "")
	MatLib.define("l24_concrete", {"albedo_a": Color(0.45, 0.44, 0.42), "albedo_b": Color(0.38, 0.37, 0.35), "noise_scale": 2.0, "stain_amount": 0.2}, "")
	MatLib.define("l24_mesh", {"albedo_a": Color(0.36, 0.37, 0.38), "albedo_b": Color(0.3, 0.31, 0.32), "pattern": 9, "pattern_scale": Vector2(0.06, 0.06), "pattern_color": Color(0.12, 0.12, 0.12), "pattern_strength": 0.7, "metallic_value": 0.5}, "")
	MatLib.define("l24_plastic", {"albedo_a": Color(0.72, 0.69, 0.64), "albedo_b": Color(0.66, 0.63, 0.58), "roughness_a": 0.3, "roughness_b": 0.45, "noise_scale": 3.0}, "")
	MatLib.define("l24_plastic_blue", {"albedo_a": Color(0.14, 0.32, 0.6), "albedo_b": Color(0.1, 0.25, 0.5), "roughness_a": 0.3, "noise_scale": 3.0}, "")
	MatLib.define("l24_rubber", {"albedo_a": Color(0.04, 0.04, 0.04), "albedo_b": Color(0.06, 0.06, 0.06), "roughness_a": 0.9}, "")
	MatLib.define("l24_window", {"albedo_a": Color(0.5, 0.42, 0.25), "albedo_b": Color(0.5, 0.42, 0.25), "emission_color": Color(1.0, 0.8, 0.5), "emission_energy": 1.2}, "")
	MatLib.define("l24_orange", {"albedo_a": Color(0.75, 0.22, 0.03), "albedo_b": Color(0.68, 0.18, 0.02), "roughness_a": 0.6}, "")
	MatLib.define("l24_wood", {"albedo_a": Color(0.32, 0.22, 0.12), "albedo_b": Color(0.26, 0.17, 0.09), "pattern": 3, "pattern_scale": Vector2(0.15, 1.2)}, "")
	MatLib.define("l24_rust", {"albedo_a": Color(0.3, 0.14, 0.06), "albedo_b": Color(0.2, 0.09, 0.04), "metallic_value": 0.3, "roughness_a": 0.8, "noise_scale": 4.0}, "")
	MatLib.define("l24_window_dead", {"albedo_a": Color(0.03, 0.035, 0.04), "albedo_b": Color(0.05, 0.05, 0.06), "roughness_a": 0.1, "metallic_value": 0.4}, "")
	MatLib.register("l24_lamp", MatLib.panel(Color(1.0, 0.92, 0.78), 5.0))
	MatLib.register("l24_reflector", MatLib.panel(Color(1.0, 0.45, 0.1), 2.0))
	MatLib.register("l24_beacon", MatLib.panel(Color(1.0, 0.25, 0.05), 3.0, 0.6))


func g(x: float, z: float) -> float:
	return ter.h(x, z)


func build_all() -> void:
	compound()
	shed()
	for i in T.COLUMNS.size():
		column(i)
	markers()
	k.commit()


func label(text: String, p: Vector3, yaw: float, px: float, col: Color, size := 64) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = px
	l.modulate = col
	l.shaded = true
	l.position = p
	l.rotation.y = yaw
	l.visibility_range_end = 160.0
	lv.add_child(l)
	return l


func mast(p: Vector3, hgt: float, face_yaw: float) -> void:
	k.box(p + Vector3(0, hgt * 0.5, 0), Vector3(0.25, hgt, 0.25), "l24_steel")
	var head := p + Vector3(0, hgt, 0)
	var dir := Vector3(sin(face_yaw), 0, cos(face_yaw))
	for s in [-0.6, 0.6]:
		var side: Vector3 = dir.cross(Vector3.UP) * s
		k.box(head + side + dir * 0.3, Vector3(0.7, 0.45, 0.7), "l24_steel", GeoKit.ALL, false)
		k.box(head + side + dir * 0.66 - Vector3(0, 0.05, 0), Vector3(0.55, 0.3, 0.05) if absf(dir.z) > 0.5 else Vector3(0.05, 0.3, 0.55), "l24_lamp", GeoKit.ALL, false)
	light_pts.append([head + dir * 1.2 - Vector3(0, 0.8, 0), Color(1.0, 0.92, 0.8), 3.0, 28.0])


# ------------------------------------------------------------------ crew compound and main gate

func compound() -> void:
	var x0 := 300.0
	var x1 := 392.0
	var z0 := -42.0
	var z1 := 42.0
	var gap := 5.5
	var sides := [[Vector3(x0, 0, z0), Vector3(x1, 0, z0)], [Vector3(x1, 0, z0), Vector3(x1, 0, z1)], [Vector3(x1, 0, z1), Vector3(x0, 0, z1)],
		[Vector3(x0, 0, z1), Vector3(x0, 0, gap)], [Vector3(x0, 0, -gap), Vector3(x0, 0, z0)]]
	for sd in sides:
		var a: Vector3 = sd[0]
		var b: Vector3 = sd[1]
		var len := a.distance_to(b)
		var n := int(len / 3.0)
		for i in n + 1:
			var p := a.lerp(b, float(i) / n)
			p.y = g(p.x, p.z)
			k.box(p + Vector3(0, 1.4, 0), Vector3(0.1, 2.8, 0.1), "l24_steel", GeoKit.ALL, false)
		var mid := (a + b) * 0.5
		mid.y = g(mid.x, mid.z)
		var along_x := absf(b.x - a.x) > 1.0
		var sz := Vector3(len, 2.5, 0.03) if along_x else Vector3(0.03, 2.5, len)
		k.box(mid + Vector3(0, 1.35, 0), sz, "l24_mesh", GeoKit.ALL, false)
		k.box(mid + Vector3(0, 2.75, 0), Vector3(len, 0.06, 0.06) if along_x else Vector3(0.06, 0.06, len), "l24_steel", GeoKit.ALL, false)
		k.box(mid + Vector3(0, 1.5, 0), Vector3(len, 3.0, 0.3) if along_x else Vector3(0.3, 3.0, len), "l24_steel", 0, true)
	# main gate: concrete pillars, sliding leaf pulled open, raised boom, gatehouse
	var gy := g(x0, 0.0)
	for s in [-1.0, 1.0]:
		k.box(Vector3(x0, gy + 2.0, s * (gap + 0.4)), Vector3(0.9, 4.0, 0.9), "l24_concrete")
	k.box(Vector3(x0, gy + 4.6, 0), Vector3(1.0, 1.2, 2.0 * gap + 1.8), "l24_blue_panel")
	label("B.N.T.G. PLASTICWORKS", Vector3(x0 - 0.52, gy + 4.75, 0), -PI * 0.5, 0.011, Color(0.9, 0.9, 0.86), 64)
	label("MAIN GATE", Vector3(x0 - 0.52, gy + 4.25, 0), -PI * 0.5, 0.007, Color(0.95, 0.75, 0.2), 64)
	for i in 6:
		k.box(Vector3(x0 + 0.5, gy + 0.2 + i * 0.45, gap + 4.2), Vector3(0.06, 0.06, 7.6), "l24_yellow", GeoKit.ALL, false)
	for zz in [gap + 0.6, gap + 8.0]:
		k.box(Vector3(x0 + 0.5, gy + 1.25, zz), Vector3(0.1, 2.5, 0.1), "l24_yellow", GeoKit.ALL, false)
	k.box(Vector3(x0 - 1.0, gy + 0.6, -gap - 1.4), Vector3(0.4, 1.2, 0.4), "l24_yellow")
	var boom := Transform3D(Basis(Vector3(1, 0, 0), -1.3), Vector3(x0 - 1.0, gy + 1.2 + 2.0, -gap - 1.4 + 0.5))
	k.box_xf(boom, Vector3(0.12, 0.12, 4.4), "l24_orange", GeoKit.ALL, false)
	_hut(Vector3(x0 - 4.5, gy, -gap - 4.5), 3.2, 3.0, 0.0)
	label("NOW RECRUITING\nmining crews - ask your supervisor\nfor a transfer application", Vector3(x0 - 4.5 + 1.62, gy + 1.7, -gap - 4.5), PI * 0.5, 0.0035, Color(0.1, 0.12, 0.2), 48)
	k.box(Vector3(x0 - 4.5 + 1.61, gy + 1.65, -gap - 4.5), Vector3(0.02, 0.9, 1.6), "l24_plastic", GeoKit.ALL, false)
	mast(Vector3(x0 - 3.0, gy, gap + 3.0), 9.0, -PI * 0.5)
	mast(Vector3(x0 - 3.0, gy, -gap - 8.0), 9.0, -PI * 0.5)
	for s in [-1.0, 1.0]:
		k.box(Vector3(x0 - 0.1, gy + 4.0, s * (gap + 0.4)), Vector3(0.25, 0.25, 0.25), "l24_beacon", GeoKit.ALL, false)
	spots["gate"] = Vector3(x0 + 2.0, gy, 0.0)
	spots["gate_miners"] = [Vector3(x0 - 1.4, gy, 3.9), Vector3(x0 + 3.0, gy, -3.6)]
	# crew quarters: prefab modules with lit windows, air units, a dish, tanks
	var mods := [Vector3(322, 0, -24), Vector3(322, 0, 24), Vector3(352, 0, -24), Vector3(352, 0, 24), Vector3(372, 0, 0)]
	for i in mods.size():
		var m: Vector3 = mods[i]
		m.y = g(m.x, m.z)
		var yaw := 0.0 if i < 4 else PI * 0.5
		_module(m, yaw)
	Props.place(lv, props, "kenney/space-kit/satellitedish-large", Vector3(380, g(380, -30), -30), 200.0, 4.0, true)
	for t in [Vector3(384, 0, 30), Vector3(380, 0, 34)]:
		k.cylinder(Vector3(t.x, g(t.x, t.z) + 2.5, t.z), 1.6, 5.0, "l24_panel", 18, true)
	label("DAYS WITHOUT INCIDENT", Vector3(318.0, gy + 2.7, -2.0), -PI * 0.5, 0.005, Color(0.9, 0.85, 0.75), 48)
	label("217", Vector3(318.0, gy + 2.1, -2.0), -PI * 0.5, 0.016, Color(0.2, 0.75, 0.3), 64)
	k.box(Vector3(318.08, gy + 2.3, -2.0), Vector3(0.1, 1.6, 2.6), "l24_blue_panel")
	k.box(Vector3(318.08, gy + 0.75, -2.0), Vector3(0.12, 1.5, 0.12), "l24_steel", GeoKit.ALL, false)
	light_pts.append([Vector3(330, gy + 3.5, 0), Color(1.0, 0.85, 0.65), 1.4, 16.0])


func _hut(p: Vector3, w: float, d: float, yaw: float) -> void:
	var bas := Basis(Vector3.UP, yaw)
	k.box_xf(Transform3D(bas, p + Vector3(0, 1.3, 0)), Vector3(w, 2.6, d), "l24_panel")
	k.box_xf(Transform3D(bas, p + Vector3(0, 2.68, 0)), Vector3(w + 0.3, 0.16, d + 0.3), "l24_steel", GeoKit.ALL, false)
	for s in [-1.0, 1.0]:
		k.box_xf(Transform3D(bas, p + bas * Vector3(s * (w * 0.5 + 0.01), 1.6, 0)), Vector3(0.02, 0.8, 1.6), "l24_window", GeoKit.ALL, false)


func _module(p: Vector3, yaw: float) -> void:
	var bas := Basis(Vector3.UP, yaw)
	var w := 13.0
	var d := 4.2
	k.box_xf(Transform3D(bas, p + Vector3(0, 0.25, 0)), Vector3(w + 0.4, 0.5, d + 0.4), "l24_concrete")
	k.box_xf(Transform3D(bas, p + Vector3(0, 0.5 + 1.45, 0)), Vector3(w, 2.9, d), "l24_panel")
	k.box_xf(Transform3D(bas, p + Vector3(0, 3.5, 0)), Vector3(w + 0.2, 0.2, d + 0.2), "l24_blue_panel", GeoKit.ALL, false)
	for i in 5:
		var off := -w * 0.5 + 1.5 + i * 2.5
		for s in [-1.0, 1.0]:
			if i == 2 and s > 0:
				k.box_xf(Transform3D(bas, p + bas * Vector3(off, 1.55, s * (d * 0.5 + 0.02))), Vector3(1.0, 2.1, 0.04), "l24_steel", GeoKit.ALL, false)
				continue
			k.box_xf(Transform3D(bas, p + bas * Vector3(off, 2.0, s * (d * 0.5 + 0.02))), Vector3(1.2, 0.8, 0.03), "l24_window", GeoKit.ALL, false)
	Props.place(lv, props, "ph/exterior_aircon_unit", p + bas * Vector3(w * 0.5 + 0.3, 0.5, 0), rad_to_deg(yaw) + 90.0, 0.0, true)


# ------------------------------------------------------------------ processing shed

func shed() -> void:
	var x0 := 196.0
	var x1 := 246.0
	var z0 := 40.0
	var z1 := 78.0
	var hh := 12.0
	var fy := g((x0 + x1) * 0.5, (z0 + z1) * 0.5)
	k.box_mm(Vector3(x0, fy - 1.0, z0), Vector3(x1, fy + 0.15, z1), "l24_concrete", GeoKit.PY | GeoKit.SIDES)
	fy += 0.15
	var wall := func(a: Vector3, b: Vector3, ops: Array) -> void: k.wall(a, b, hh, 0.3, "l24_panel", ops)
	wall.call(Vector3(x0, fy, z0), Vector3(x1, fy, z0), [{"at": 25.0, "w": 12.0, "h": 8.0}, {"at": 8.0, "w": 1.0, "h": 2.1}])
	wall.call(Vector3(x1, fy, z0), Vector3(x1, fy, z1), [])
	wall.call(Vector3(x1, fy, z1), Vector3(x0, fy, z1), [])
	wall.call(Vector3(x0, fy, z1), Vector3(x0, fy, z0), [{"at": 19.0, "w": 6.0, "h": 5.0}])
	k.box_mm(Vector3(x0 - 0.3, fy + hh, z0 - 0.3), Vector3(x1 + 0.3, fy + hh + 0.4, z1 + 0.3), "l24_blue_panel")
	for i in 6:
		var x := x0 + 4.0 + i * 8.4
		k.box(Vector3(x, fy + hh - 0.5, (z0 + z1) * 0.5), Vector3(0.4, 0.8, z1 - z0), "l24_steel", GeoKit.ALL, false)
		k.panel(Vector3(x, fy + hh - 0.92, (z0 + z1) * 0.5), 0.5, 20.0, "l24_lamp")
		light_pts.append([Vector3(x, fy + hh - 2.0, (z0 + z1) * 0.5), Color(0.95, 0.95, 1.0), 2.2, 22.0])
	label("B.N.T.G. PLASTICWORKS - PROCESSING", Vector3((x0 + x1) * 0.5, fy + 9.6, z0 - 0.17), PI, 0.02, Color(0.92, 0.92, 0.9), 64)
	# conveyor lines carrying cut blocks to the press machines
	for line in 2:
		var lz := 52.0 + line * 12.0
		for x in range(int(x0) + 4, int(x1) - 10, 3):
			k.box(Vector3(x + 1.5, fy + 0.45, lz), Vector3(3.0, 0.9, 0.12), "l24_steel", GeoKit.ALL, false)
		k.box(Vector3((x0 + x1) * 0.5 - 3.0, fy + 0.95, lz), Vector3(x1 - x0 - 14.0, 0.12, 1.4), "l24_rubber", GeoKit.ALL, false)
		k.box(Vector3((x0 + x1) * 0.5 - 3.0, fy + 0.5, lz), Vector3(x1 - x0 - 14.0, 1.0, 1.6), "l24_steel", 0, true)
		for b in 9:
			k.box(Vector3(x0 + 6.0 + b * 3.6 + rng.randf_range(-0.4, 0.4), fy + 1.3, lz), Vector3(1.0, 0.6, 0.7), "l24_plastic")
		Props.place(lv, props, "kenney/space-kit/machine-generatorlarge", Vector3(x1 - 6.0, fy, lz), 90.0, 3.0, true)
		Props.place(lv, props, "kenney/space-kit/machine-barrellarge", Vector3(x0 + 2.8, fy, lz + 3.0), 0.0, 2.6, true)
	# pallets of finished plastic
	for i in 8:
		var px := x0 + 4.0 + (i % 4) * 4.0
		var pz := z1 - 4.0 - int(i / 4) * 3.5
		k.box(Vector3(px, fy + 0.08, pz), Vector3(2.2, 0.16, 1.6), "l24_wood", GeoKit.ALL, false)
		for s in rng.randi_range(2, 5):
			k.box(Vector3(px + rng.randf_range(-0.2, 0.2), fy + 0.46 + s * 0.6, pz), Vector3(1.9, 0.58, 1.4), "l24_plastic" if (i + s) % 5 else "l24_plastic_blue")
	# control mezzanine along the back wall, reached by a steel stair
	var my := fy + 4.5
	k.box_mm(Vector3(x0 + 20.0, my - 0.25, z1 - 6.0), Vector3(x1 - 0.3, my, z1 - 0.3), "l24_mesh")
	for x in [x0 + 20.3, x0 + 32.0, x1 - 0.8]:
		k.box(Vector3(x, (fy + my) * 0.5, z1 - 6.0), Vector3(0.3, my - fy, 0.3), "l24_steel")
	for x in range(int(x0) + 21, int(x1), 2):
		k.box(Vector3(x, my + 0.55, z1 - 6.0), Vector3(0.05, 1.1, 0.05), "l24_yellow", GeoKit.ALL, false)
	k.box(Vector3((x0 + 20.0 + x1) * 0.5, my + 1.05, z1 - 6.0), Vector3(x1 - x0 - 20.0, 0.06, 0.06), "l24_yellow", GeoKit.ALL, false)
	k.box(Vector3((x0 + 20.0 + x1) * 0.5, my + 0.55, z1 - 6.0), Vector3(x1 - x0 - 20.0, 1.1, 0.08), "l24_yellow", 0, true)
	var steps := 25
	k.stairs(Vector3(x0 + 13.0, fy, z1 - 3.0), Vector3(1, 0, 0), 1.4, my - fy, steps, "l24_mesh", 0.28)
	for i in 3:
		Props.place(lv, props, "kenney/space-kit/desk-computerscreen", Vector3(x1 - 6.0 - i * 5.0, my, z1 - 1.0), 180.0, 1.2, true)
	light_pts.append([Vector3(x1 - 10.0, my + 2.5, z1 - 3.0), Color(0.85, 0.9, 1.0), 1.0, 9.0])
	spots["shed"] = Vector3((x0 + x1) * 0.5, fy, (z0 + z1) * 0.5)
	spots["mezzanine"] = Vector3(x1 - 8.0, my, z1 - 3.0)
	mast(Vector3(x0 + 25.0, fy, z0 - 6.0), 10.0, PI)


# ------------------------------------------------------------------ mining columns

func column(i: int) -> void:
	var c: Vector2 = T.COLUMNS[i]
	var hf := T.COL_HALF
	var top := 0.0
	# gantry crane: four legs, two girders, a trolley and a hoisted block
	var legs := [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
	for l in legs:
		var p := Vector3(c.x + l.x * (hf + 1.6), 0, c.y + l.y * (hf + 1.6))
		p.y = g(p.x, p.z)
		k.box(p + Vector3(0, 5.5, 0), Vector3(0.6, 11.0, 0.6), "l24_yellow")
	for s in [-1.0, 1.0]:
		k.box(Vector3(c.x, top + 11.2, c.y + s * (hf + 1.6)), Vector3(2.0 * hf + 4.0, 0.9, 0.7), "l24_yellow", GeoKit.ALL, false)
	var tz := c.y + rng.randf_range(-3.0, 3.0)
	k.box(Vector3(c.x, top + 11.0, tz), Vector3(2.0, 0.9, 2.0 * hf + 4.0), "l24_yellow", GeoKit.ALL, false)
	k.box(Vector3(c.x + 1.0, top + 10.3, tz), Vector3(1.6, 0.8, 1.6), "l24_steel", GeoKit.ALL, false)
	var hang := rng.randf_range(3.0, 7.0)
	k.box(Vector3(c.x + 1.0, top + 10.3 - hang * 0.5, tz), Vector3(0.05, hang, 0.05), "l24_rubber", GeoKit.ALL, false)
	k.box(Vector3(c.x + 1.0, top + 9.7 - hang, tz), Vector3(1.6, 1.0, 1.2), "l24_plastic", GeoKit.ALL, false)
	# safety rail round the rim, open where the ramp cut leaves
	var ry := 0.0
	for side in 4:
		for j in 9:
			var t := -hf - 0.6 + j * (2.0 * hf + 1.2) / 8.0
			var p2 := Vector2(t, -hf - 0.6) if side == 0 else (Vector2(t, hf + 0.6) if side == 1 else (Vector2(-hf - 0.6, t) if side == 2 else Vector2(hf + 0.6, t)))
			if side == 2 and t < -hf + 4.6:
				continue
			if side == 0 and t < -hf + 1.0:
				continue
			var q := Vector3(c.x + p2.x, 0, c.y + p2.y)
			q.y = g(q.x, q.z)
			ry = q.y
			k.box(q + Vector3(0, 0.55, 0), Vector3(0.08, 1.1, 0.08), "l24_yellow", GeoKit.ALL, false)
	for side in 4:
		var a := Vector2(-hf - 0.6, -hf - 0.6)
		var b := Vector2(hf + 0.6, -hf - 0.6)
		match side:
			1:
				a = Vector2(-hf - 0.6, hf + 0.6)
				b = Vector2(hf + 0.6, hf + 0.6)
			2:
				a = Vector2(-hf - 0.6, -hf + 4.6)
				b = Vector2(-hf - 0.6, hf + 0.6)
			3:
				a = Vector2(hf + 0.6, -hf - 0.6)
				b = Vector2(hf + 0.6, hf + 0.6)
		if side == 0:
			a = Vector2(-hf + 1.0, -hf - 0.6)
		var mid := Vector3(c.x + (a.x + b.x) * 0.5, ry, c.y + (a.y + b.y) * 0.5)
		var sz := Vector3(absf(b.x - a.x) + 0.08, 0.06, 0.06) if side < 2 else Vector3(0.06, 0.06, absf(b.y - a.y) + 0.08)
		k.box(mid + Vector3(0, 1.08, 0), sz, "l24_yellow", GeoKit.ALL, false)
		k.box(mid + Vector3(0, 0.6, 0), sz, "l24_yellow", GeoKit.ALL, false)
		k.box(mid + Vector3(0, 0.55, 0), Vector3(sz.x, 1.1, sz.z if side >= 2 else 0.1) if side < 2 else Vector3(0.1, 1.1, sz.z), "l24_yellow", 0, true)
	# on the column floor: cut blocks, a cutting rig, a miner's hot-shovel rack
	var fy := T.COL_FLOOR
	for b in 7:
		k.box(Vector3(c.x + rng.randf_range(-5.0, 5.0), fy + 0.3, c.y + rng.randf_range(-3.0, 6.0)), Vector3(1.0, 0.6, 0.7), "l24_plastic")
	Props.place(lv, props, "kenney/space-kit/machine-wirelesscable", Vector3(c.x + 4.0, fy, c.y + 4.5), 30.0, 2.2, true)
	for s in 3:
		_hot_shovel(Vector3(c.x - 6.5, fy, c.y + 5.0 + s * 0.6), 80.0)
	label("MINING COLUMN %d" % (i + 1), Vector3(c.x - hf - 1.2, 1.6, c.y - hf - 2.2), -PI * 0.5, 0.008, Color(0.1, 0.1, 0.1), 64)
	k.box(Vector3(c.x - hf - 1.25, 1.6, c.y - hf - 2.2), Vector3(0.06, 0.8, 3.6), "l24_yellow", GeoKit.ALL, false)
	k.box(Vector3(c.x - hf - 1.25, 0.6, c.y - hf - 2.2), Vector3(0.1, 1.2, 0.1), "l24_steel", GeoKit.ALL, false)
	mast(Vector3(c.x + hf + 3.5, 0, c.y + hf + 3.5), 10.0, -PI * 0.75)
	light_pts.append([Vector3(c.x, fy + 4.0, c.y), Color(1.0, 0.95, 0.85), 1.6, 14.0])
	spots["column%d" % (i + 1)] = Vector3(c.x, fy, c.y)


func _hot_shovel(p: Vector3, yaw_deg: float) -> void:
	var bas := Basis(Vector3.UP, deg_to_rad(yaw_deg)) * Basis(Vector3(1, 0, 0), 0.25)
	k.box_xf(Transform3D(bas, p + Vector3(0, 0.75, 0)), Vector3(0.05, 1.4, 0.05), "l24_steel", GeoKit.ALL, false)
	k.box_xf(Transform3D(bas, p + Vector3(0, 0.12, 0)), Vector3(0.28, 0.32, 0.03), "l24_orange", GeoKit.ALL, false)
	Props.place(lv, props, "ph/propane_tank", p + Vector3(0.3, 0, 0), yaw_deg, 0.45)


func markers() -> void:
	for e in ter.road_points(22.0):
		var p2: Vector2 = e[0]
		var dir: Vector2 = e[1]
		if p2.x > 280.0 or p2.x < -985.0:
			continue
		var side := Vector2(-dir.y, dir.x) * 4.6
		for s in [-1.0, 1.0]:
			var q: Vector2 = p2 + side * s
			var y := g(q.x, q.y)
			k.box(Vector3(q.x, y + 0.7, q.y), Vector3(0.1, 1.4, 0.1), "l24_orange", GeoKit.ALL, false)
			k.box(Vector3(q.x, y + 1.25, q.y), Vector3(0.12, 0.12, 0.12), "l24_reflector", GeoKit.ALL, false)
