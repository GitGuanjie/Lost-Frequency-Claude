extends RefCounted
## Level 197 dressing: mineral crystals found on the real cave surfaces (by
## marching the same SDF the mesh uses), Zone 1's round smoothed stalagmites,
## M.E.G. Outpost "Good Feels", the Meditation Cove fountain and the camp of
## the Entranced. All crystal geometry goes into one accumulator per mineral.

const C := preload("res://levels/L197/L197_cave.gd")
const Plan := preload("res://levels/L197/L197_plan.gd")

const FALL_SHADER := """
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, shadows_disabled;
uniform vec3 tint : source_color = vec3(0.7, 0.95, 0.95);
uniform float speed = 1.0;
float h1(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n2(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h1(i), h1(i + vec2(1, 0)), f.x), mix(h1(i + vec2(0, 1)), h1(i + vec2(1, 1)), f.x), f.y);
}
void fragment() {
	float t = TIME * speed;
	float s = n2(vec2(UV.x * 9.0, UV.y * 4.0 - t * 4.0)) * 0.6 + n2(vec2(UV.x * 31.0, UV.y * 12.0 - t * 7.0)) * 0.4;
	float edge = smoothstep(0.0, 0.25, UV.x) * smoothstep(1.0, 0.75, UV.x);
	ALBEDO = tint * (0.7 + 0.4 * s);
	ROUGHNESS = 0.05;
	SPECULAR = 0.8;
	EMISSION = tint * 0.35;
	ALPHA = clamp((0.3 + 0.7 * s) * edge, 0.0, 1.0) * 0.8;
}
"""

const COL := {1: Color(0.3, 0.9, 0.82), 2: Color(0.62, 0.3, 0.95), 3: Color(1.0, 0.3, 0.18), 4: Color(0.55, 0.6, 0.7)}
const MAT := {1: "l197_turq", 2: "l197_ame", 3: "l197_ruby", 4: "l197_turq"}


## Crystals along a floor polyline. opt: step, ceil_p, wall_n, size (Vector2), count (Vector2i),
## light_every (m, 0 = none), light (energy), lrange, stal (stalagmite chance), lat (lateral jitter)
static func dress_path(L, pts: Array, zone: int, opt: Dictionary) -> void:
	var r: RandomNumberGenerator = L.drng
	var step: float = opt.get("step", 3.0)
	var acc: C.Acc = L.acc(MAT[zone])
	var since_light := 0.0
	var light_every: float = opt.get("light_every", 0.0)
	var sz: Vector2 = opt.get("size", Vector2(0.4, 1.0))
	var cnt: Vector2i = opt.get("count", Vector2i(3, 7))
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var seg := a.distance_to(b)
		var dir := (b - a).normalized()
		var side := Vector3(-dir.z, 0, dir.x).normalized()
		var n := maxi(1, int(seg / step))
		for s in n:
			var p := a.lerp(b, (float(s) + r.randf_range(0.1, 0.9)) / n)
			var fs: Array = L.fs_near(p)
			var air := p + Vector3(0, 1.4, 0)
			if C.sdf(fs, air, L.noise) > -0.3:
				continue
			since_light += seg / n
			var lit_here := false
			# ceiling bunch
			if r.randf() < float(opt.get("ceil_p", 0.5)):
				var from := air + side * r.randf_range(-1.0, 1.0) * float(opt.get("lat", 1.0))
				var up := C.march(fs, from, Vector3.UP, 14.0, L.noise)
				if not up.is_empty() and (up["p"] as Vector3).y - p.y > float(opt.get("min_ceiling", 3.2)):
					var big := r.randf_range(sz.x, sz.y)
					big = minf(big, (up["p"] as Vector3).y - p.y - 2.3)
					if big > 0.1:
						C.cluster(acc, up["p"] - (up["n"] as Vector3) * 0.05, up["n"], big, r.randi_range(cnt.x, cnt.y), r)
						if light_every > 0.0 and since_light >= light_every:
							since_light = 0.0
							lit_here = true
							L.crystal_light((up["p"] as Vector3) + (up["n"] as Vector3) * 0.6, zone, opt)
			# wall bunches
			for k in int(opt.get("wall_n", 2)):
				var sgn := 1.0 if r.randf() < 0.5 else -1.0
				var d := (side * sgn + Vector3(0, r.randf_range(-0.35, 0.7), 0) + dir * r.randf_range(-0.4, 0.4)).normalized()
				var hit := C.march(fs, air, d, 9.0, L.noise)
				if hit.is_empty() or absf((hit["n"] as Vector3).y) > 0.75:
					continue
				var hp: Vector3 = hit["p"]
				var wsz := r.randf_range(sz.x, sz.y) * float(opt.get("wall_scale", 0.8))
				C.cluster(acc, hp - (hit["n"] as Vector3) * 0.05, (hit["n"] as Vector3 + Vector3(0, 0.25, 0)).normalized(), wsz, r.randi_range(cnt.x, cnt.y), r)
				L.hot_spots.append([hp, zone])
				if light_every > 0.0 and not lit_here and since_light >= light_every:
					since_light = 0.0
					lit_here = true
					L.crystal_light(hp + (hit["n"] as Vector3) * 0.7, zone, opt)
			# floor-edge stalagmites (Zone 1) or crystal bunches
			if r.randf() < float(opt.get("stal", 0.0)):
				var hit2 := C.march(fs, air, (side * (1.0 if r.randf() < 0.5 else -1.0) + Vector3(0, -0.2, 0)).normalized(), 9.0, L.noise)
				if not hit2.is_empty():
					var back := (hit2["p"] as Vector3) + (hit2["n"] as Vector3) * r.randf_range(0.35, 0.7)
					var dn := C.march(fs, back + Vector3(0, 0.5, 0), Vector3.DOWN, 4.0, L.noise)
					if not dn.is_empty():
						var g: Vector3 = dn["p"]
						if absf(g.y - p.y) < 0.8:
							L.stalagmite(g, r.randf_range(0.28, 1.2), r.randf_range(0.16, 0.32))
			if zone == 1 and r.randf() < float(opt.get("stalactite", 0.0)):
				var up2 := C.march(fs, air + side * r.randf_range(-1.2, 1.2), Vector3.UP, 12.0, L.noise)
				if not up2.is_empty() and (up2["p"] as Vector3).y - p.y > 3.6:
					var len := r.randf_range(0.3, minf(1.3, (up2["p"] as Vector3).y - p.y - 2.4))
					C.lathe(L.acc("l197_flow"), (up2["p"] as Vector3) + Vector3(0, 0.1, 0), len, r.randf_range(0.1, 0.22), -1.0)
					if r.randf() < 0.18:
						L.drip_at(up2["p"] + Vector3(0, -len, 0), p)


## A few bunches round a room (walls and ceiling), marched from its centre.
static func dress_room(L, centre: Vector3, zone: int, count: int, sz: Vector2, lights: int, opt: Dictionary = {}) -> void:
	var r: RandomNumberGenerator = L.drng
	var fs: Array = L.fs_near(centre)
	var acc: C.Acc = L.acc(MAT[zone])
	var lit := 0
	for i in count:
		var ang := r.randf() * TAU
		var d := Vector3(cos(ang), r.randf_range(float(opt.get("ymin", -0.15)), float(opt.get("ymax", 0.9))), sin(ang)).normalized()
		var from := centre + Vector3(0, float(opt.get("eye", 1.5)), 0)
		var hit := C.march(fs, from, d, 22.0, L.noise)
		if hit.is_empty():
			continue
		var hp: Vector3 = hit["p"]
		var hn: Vector3 = hit["n"]
		if hn.y > 0.7 and Vector2(hp.x - centre.x, hp.z - centre.z).length() < float(opt.get("clear", 3.0)):
			continue
		C.cluster(acc, hp - hn * 0.06, hn, r.randf_range(sz.x, sz.y), r.randi_range(4, 9), r)
		L.hot_spots.append([hp, zone])
		if lit < lights:
			lit += 1
			L.crystal_light(hp + hn * 0.8, zone, opt)


# ------------------------------------------------------------------ outpost

static func outpost(L, root: Node3D) -> void:
	var o: Vector3 = Plan.OUTPOST
	var P := func(id: String, p: Vector3, yaw: float, h: float = 0.0, col: bool = false) -> Node3D:
		return Props.place(L, root, id, o + p, yaw, h, col)
	P.call("ph/metal_office_desk", Vector3(0.0, 0, -0.6), 0.0, 0.0, true)
	P.call("ph/vintage_radio_transceiver", Vector3(-0.55, 0.79, -0.75), 10.0)
	P.call("ph/clipboard", Vector3(0.2, 0.79, -0.45), -12.0)
	P.call("ph/binder_notebook", Vector3(0.55, 0.79, -0.7), 30.0)
	P.call("ph/vintage_flashlight", Vector3(0.75, 0.79, -0.35), 70.0)
	P.call("ph/plastic_monobloc_chair_01", Vector3(-0.2, 0, 0.25), 170.0)
	P.call("ph/plastic_monobloc_chair_01", Vector3(1.5, 0, 0.4), 210.0)
	# crates of excavated turquoise, packed for Level 11, The Hub and Level 901
	P.call("ph/old_military_crate", Vector3(3.2, 0, -0.9), 90.0, 0.0, true)
	P.call("ph/old_military_crate", Vector3(3.2, 0.3, -0.9), 84.0)
	P.call("ph/wooden_crate_01", Vector3(3.1, 0.6, -0.8), 95.0)
	P.call("ph/plastic_crate_01", Vector3(2.2, 0, 0.3), 20.0)
	P.call("ph/plastic_crate_01", Vector3(2.55, 0, 0.55), -15.0)
	P.call("ph/hand_truck", Vector3(4.4, 0, 0.5), -60.0)
	# the gas-mask crate by the way to Zone 2
	P.call("ph/old_military_crate", Vector3(4.9, 0, 1.9), 30.0, 0.0, true)
	# power and light
	P.call("ph/portable_generator", Vector3(-2.6, 0, -1.2), 20.0, 0.0, true)
	P.call("ph/propane_tank", Vector3(-3.3, 0, -1.5), 0.0)
	P.call("ph/modular_electric_cables", Vector3(-1.6, 0.02, -0.4), 90.0)
	P.call("ph/power_box_01", Vector3(-1.4, 0, -1.6), 0.0)
	P.call("ph/street_lamp_02", Vector3(-2.2, 0, 0.8), 140.0, 2.1)
	P.call("ph/street_lamp_02", Vector3(4.2, 0, -1.6), 230.0, 2.1)
	P.call("ph/korean_fire_extinguisher_01", Vector3(-0.9, 0, -1.6), 0.0)
	P.call("ph/medical_box", Vector3(-1.0, 0.79, -0.7), -20.0)
	# two cots for the night shift
	P.call("ph/old_bed_frame", Vector3(-4.3, 0, 0.9), 90.0, 0.0, true)
	P.call("ph/old_bed_frame", Vector3(-4.3, 0, 3.0), 92.0)
	P.call("ph/Barrel_01", Vector3(5.4, 0, -0.4), 0.0, 0.0, true)
	P.call("ph/plastic_bottle_gallon", Vector3(5.1, 0, 0.25), 30.0)
	P.call("ph/plastic_bottle_gallon", Vector3(5.35, 0, 0.35), -40.0)
	# a painted board on two posts
	var k: GeoKit = L.kit("OutpostSign")
	var sp := o + Vector3(1.0, 0, -2.0)
	k.box(sp + Vector3(-1.1, 1.0, 0), Vector3(0.08, 2.0, 0.08), "l197_wood")
	k.box(sp + Vector3(1.1, 1.0, 0), Vector3(0.08, 2.0, 0.08), "l197_wood")
	k.box(sp + Vector3(0, 1.75, 0.03), Vector3(2.4, 0.55, 0.04), "l197_board", GeoKit.ALL, false)
	k.commit()
	L.label("M.E.G. OUTPOST \"GOOD FEELS\"\nLEVEL 197 - ZONE 1", sp + Vector3(0, 1.75, 0.06), Vector3(0, 0, 1), 0.0042, Color(0.95, 0.93, 0.85), 64)
	L.lights.add_anchor(o + Vector3(-2.2, 2.0, 0.8), Color(1.0, 0.82, 0.6), 1.4, 7.0, 0.05, "outpost")
	L.lights.add_anchor(o + Vector3(4.2, 2.0, -1.6), Color(1.0, 0.82, 0.6), 1.2, 7.0, 0.0, "outpost")


# ------------------------------------------------------------------ cove

static func cove(L, root: Node3D) -> void:
	var c: Vector3 = Plan.COVE
	var r: RandomNumberGenerator = L.drng
	var acc: C.Acc = L.acc("l197_turq")
	# the central formation: a ~9 m crystal with others growing out of it
	C.prism(acc, c + Vector3(0, -0.3, 0), Vector3(0.02, 1, 0.03), 9.2, 1.25, 0.2, 0.2)
	for i in 14:
		var ang := TAU * i / 14.0 + r.randf_range(-0.2, 0.2)
		var y := r.randf_range(0.2, 5.5)
		var out := Vector3(cos(ang), r.randf_range(0.25, 1.1), sin(ang)).normalized()
		C.prism(acc, c + Vector3(cos(ang) * 0.9, y, sin(ang) * 0.9), out, r.randf_range(1.2, 3.6) * (1.2 - y / 9.0), r.randf_range(0.18, 0.42), r.randf() * TAU)
	for i in 18:
		var ang := r.randf() * TAU
		var d := r.randf_range(1.3, 2.4)
		C.cluster(acc, c + Vector3(cos(ang) * d, -0.05, sin(ang) * d), Vector3(cos(ang) * 0.5, 1, sin(ang) * 0.5), r.randf_range(0.5, 1.4), r.randi_range(3, 6), r)
	# basin round its foot: a low smoothed rim and still distilled water
	var k: GeoKit = L.kit("CoveBasin")
	var rim := 3.3
	for i in 28:
		var a0 := TAU * i / 28.0
		var a1 := TAU * (i + 1) / 28.0
		var p0 := c + Vector3(cos(a0) * rim, 0, sin(a0) * rim)
		var p1 := c + Vector3(cos(a1) * rim, 0, sin(a1) * rim)
		var mid := (p0 + p1) * 0.5
		k.box_xf(Transform3D(Basis(Vector3.UP, -((a0 + a1) * 0.5) + PI * 0.5), mid + Vector3(0, 0.22, 0)), Vector3(p0.distance_to(p1) + 0.06, 0.62, 0.55), "l197_flow", GeoKit.ALL, true, "concrete")
	k.commit()
	var disc := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = rim - 0.1
	cm.bottom_radius = rim - 0.1
	cm.height = 0.02
	cm.radial_segments = 40
	disc.mesh = cm
	disc.material_override = MatLib.get_mat("l197_distilled")
	disc.position = c + Vector3(0, 0.38, 0)
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(disc)
	# streams arcing from high on the formation into the basin
	var fall := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = FALL_SHADER
	fall.shader = sh
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 7:
		var ang := TAU * i / 7.0 + 0.3
		var top := c + Vector3(cos(ang) * 0.75, r.randf_range(5.6, 7.8), sin(ang) * 0.75)
		var out := Vector3(cos(ang), 0, sin(ang))
		var reach := r.randf_range(1.7, 2.7)
		var w := r.randf_range(0.07, 0.14)
		var tside := Vector3(-out.z, 0, out.x) * w
		var segs := 14
		for s in segs:
			var t0 := float(s) / segs
			var t1 := float(s + 1) / segs
			var q0 := top + out * reach * t0 + Vector3(0, (0.38 - (top.y - c.y)) * t0 * t0 + 0.25 * t0 * (1.0 - t0), 0)
			var q1 := top + out * reach * t1 + Vector3(0, (0.38 - (top.y - c.y)) * t1 * t1 + 0.25 * t1 * (1.0 - t1), 0)
			for tri in [[q0 - tside, 0.0, t0], [q0 + tside, 1.0, t0], [q1 + tside, 1.0, t1], [q0 - tside, 0.0, t0], [q1 + tside, 1.0, t1], [q1 - tside, 0.0, t1]]:
				st.set_uv(Vector2(tri[1], tri[2] * 4.0))
				st.set_normal(out)
				st.add_vertex(tri[0])
	var falls := MeshInstance3D.new()
	falls.mesh = st.commit()
	falls.material_override = fall
	falls.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(falls)
	# a geode: the cove's own walls are crowded with turquoise
	dress_room(L, c, 1, 70, Vector2(0.5, 1.6), 0, {"clear": 4.2, "ymin": -0.25, "ymax": 1.0, "eye": 2.5})
	L.lights.add_anchor(c + Vector3(0, 4.5, 0), Color(0.3, 0.95, 0.9), 3.2, 16.0, 0.0, "cove")
	for i in 4:
		var ang := TAU * i / 4.0 + 0.6
		L.lights.add_anchor(c + Vector3(cos(ang) * 6.5, 2.2, sin(ang) * 6.5), Color(0.2, 0.85, 0.8), 1.3, 9.0, 0.0, "cove")


## The Entranced: around 125 wanderers who will not leave Zone 1. Their bedrolls lie in
## identical rows in the loop tunnel west of the cove, all turned the same way.
static func entranced_camp(L, root: Node3D) -> Vector3:
	var base := Vector3(19.0, -1.2, 26.4)
	var fwd := (Plan.COVE - base)
	fwd.y = 0
	fwd = fwd.normalized()
	var side := Vector3(-fwd.z, 0, fwd.x)
	var k: GeoKit = L.kit("Entranced")
	var yaw := atan2(fwd.x, fwd.z)
	for row in 3:
		for col in 4:
			var p := base - fwd * (row * 2.4) + side * ((col - 1.5) * 1.05)
			var fs: Array = L.fs_near(p)
			var dn := C.march(fs, p + Vector3(0, 1.2, 0), Vector3.DOWN, 3.0, L.noise)
			if dn.is_empty():
				continue
			var g: Vector3 = dn["p"]
			k.box_xf(Transform3D(Basis(Vector3.UP, yaw), g + Vector3(0, 0.05, 0)), Vector3(0.75, 0.1, 1.95), "l197_bedroll", GeoKit.ALL, false)
			k.box_xf(Transform3D(Basis(Vector3.UP, yaw), g + Vector3(0, 0.12, 0) + fwd * 0.75), Vector3(0.55, 0.12, 0.3), "l197_blanket", GeoKit.ALL, false)
			if (row + col) % 3 == 0:
				Props.place(L, root, "ph/plastic_bottle_gallon", g - fwd * 1.15 + side * 0.25, rad_to_deg(yaw))
	k.commit()
	Props.place(L, root, "ph/vintage_suitcase", base - fwd * 6.2 + side * 2.4, rad_to_deg(yaw) + 90.0)
	return base
