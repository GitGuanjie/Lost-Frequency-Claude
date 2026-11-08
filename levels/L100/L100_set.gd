extends RefCounted
## Level 100 set pieces (static helpers): the sand strip cross-section, the
## headstones, grave mounds and their accessories, the sea surface shader and
## the tall black being. L100.gd owns placement and state.

const CREST := 0.9
const SHORE_X := 8.8          # where the wet ramp meets the sea surface (y = 0)
const SHELF_X := 16.0         # end of the wading shelf; beyond it the strip drops away
const FLOOR := -24.0


static func materials() -> void:
	MatLib.define("l100_sand", {"albedo_a": Color(0.84, 0.76, 0.60), "albedo_b": Color(0.76, 0.67, 0.51),
		"pattern": 13, "pattern_color": Color(0.64, 0.56, 0.42), "pattern_strength": 0.7,
		"noise_scale": 0.5, "roughness_a": 0.94, "roughness_b": 1.0, "bump_strength": 1.2}, "sand")
	MatLib.define("l100_sand_wet", {"albedo_a": Color(0.70, 0.62, 0.48), "albedo_b": Color(0.62, 0.55, 0.42),
		"pattern": 13, "pattern_color": Color(0.56, 0.49, 0.37), "pattern_strength": 0.35, "wetness": 0.75,
		"noise_scale": 0.4, "roughness_a": 0.35, "roughness_b": 0.55, "bump_strength": 0.4}, "sand")
	MatLib.define("l100_sand_sea", {"albedo_a": Color(0.86, 0.80, 0.66), "albedo_b": Color(0.78, 0.71, 0.56),
		"pattern": 13, "pattern_color": Color(0.72, 0.65, 0.50), "pattern_strength": 0.5,
		"noise_scale": 0.3, "roughness_a": 0.7, "roughness_b": 0.9, "caustics": 0.8, "water_y": 0.0}, "sand")
	MatLib.define("l100_sand_dug", {"albedo_a": Color(0.62, 0.54, 0.40), "albedo_b": Color(0.52, 0.45, 0.33),
		"noise_scale": 2.5, "roughness_a": 0.95, "roughness_b": 1.0, "bump_strength": 1.6}, "sand")
	MatLib.define("l100_stone", {"albedo_a": Color(0.66, 0.66, 0.64), "albedo_b": Color(0.58, 0.58, 0.57),
		"pattern": 0, "noise_scale": 3.5, "roughness_a": 0.55, "roughness_b": 0.75, "bump_strength": 0.5,
		"stain_amount": 0.0, "wetness": 0.0}, "rock")
	MatLib.register("l100_engrave", MatLib.standard(Color(0.22, 0.22, 0.22), 0.9))
	MatLib.register("l100_frame", MatLib.standard(Color(0.24, 0.15, 0.09), 0.6))
	MatLib.register("l100_photo", MatLib.standard(Color(0.62, 0.55, 0.45), 0.4))
	MatLib.register("l100_photo_b", MatLib.standard(Color(0.38, 0.42, 0.40), 0.4))
	MatLib.define("l100_shroud", {"albedo_a": Color(0.58, 0.55, 0.49), "albedo_b": Color(0.50, 0.47, 0.42),
		"noise_scale": 4.0, "roughness_a": 0.95, "roughness_b": 1.0, "bump_strength": 0.8}, "plaster")
	var ink := StandardMaterial3D.new()
	ink.albedo_color = Color(0.008, 0.008, 0.01)
	ink.roughness = 0.32
	ink.metallic_specular = 0.35
	MatLib.register("l100_ink", ink)
	MatLib.register("l100_sea", sea_material())


## One 64 m length of the strip (chunk), centred on x = 0, running along z.
static func strip(k: GeoKit, z0: float, z1: float) -> void:
	var zc := (z0 + z1) * 0.5
	var w := z1 - z0
	k.box_mm(Vector3(-3.0, CREST - 3.0, z0), Vector3(3.0, CREST, z1), "l100_sand", GeoKit.PY)
	for s in [-1.0, 1.0]:
		k.ramp(Vector3(3.0 * s, CREST, zc), Vector3(7.0 * s, 0.30, zc), w, 0.6, "l100_sand")
		k.ramp(Vector3(7.0 * s, 0.30, zc), Vector3(9.6 * s, -0.14, zc), w, 0.6, "l100_sand_wet")
		k.ramp(Vector3(9.6 * s, -0.14, zc), Vector3(SHELF_X * s, -1.75, zc), w, 0.6, "l100_sand_sea")
		# the strip's submerged flank drops straight to the sea floor
		var a := Vector3(minf(SHELF_X * s, (SHELF_X + 1.2) * s), FLOOR, z0)
		var b := Vector3(maxf(SHELF_X * s, (SHELF_X + 1.2) * s), -1.75, z1)
		k.box_mm(a, b, "l100_sand_sea", GeoKit.SIDES | GeoKit.PY)
	k.box_mm(Vector3(-SHELF_X, FLOOR, z0), Vector3(SHELF_X, -1.9, z1), "l100_sand_sea", GeoKit.NY, false)


## A headstone with a rounded top. `face` is the unit direction its epitaph faces.
static func headstone(k: GeoKit, parent: Node3D, base: Vector3, face: Vector3, w: float, h: float, lines: int) -> void:
	var yaw := atan2(face.x, face.z)
	var b := Basis(Vector3.UP, yaw)
	var t := 0.16
	k.box_xf(Transform3D(b, base + Vector3(0, (h - w * 0.5) * 0.5 - 0.15, 0)), Vector3(w, h - w * 0.5 + 0.3, t), "l100_stone")
	var top := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = w * 0.5
	cm.bottom_radius = w * 0.5
	cm.height = t
	cm.radial_segments = 20
	top.mesh = cm
	top.material_override = MatLib.get_mat("l100_stone")
	top.transform = Transform3D(b * Basis(Vector3.RIGHT, PI * 0.5), base + Vector3(0, h - w * 0.5, 0))
	parent.add_child(top)
	# a low plinth half-buried in the sand
	k.box_xf(Transform3D(b, base + Vector3(0, 0.02, 0)), Vector3(w + 0.16, 0.12, t + 0.14), "l100_stone", GeoKit.ALL, false)
	# engraved line work (unreadable from afar; read it up close)
	for i in lines:
		var lw := w * (0.62 if i == 0 else 0.48 - 0.06 * (i % 3))
		var y := h - w * 0.5 - 0.06 - i * 0.075 - (0.05 if i > 1 else 0.0)
		k.box_xf(Transform3D(b, base + Vector3(0, y, 0) + face * (t * 0.5 + 0.002)), Vector3(lw, 0.022 if i == 0 else 0.014, 0.004), "l100_engrave", GeoKit.ALL, false)


static func label(parent: Node3D, at: Vector3, face: Vector3, text: String, size: int) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.0011
	l.modulate = Color(0.16, 0.16, 0.16)
	l.outline_size = 0
	l.double_sided = false
	l.shaded = true
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = at + face * 0.083
	l.rotation.y = atan2(face.x, face.z)
	parent.add_child(l)


## Long low mound of sand in front of a stone.
static func mound(parent: Node3D, at: Vector3, yaw: float, length: float, mat: String) -> void:
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 20
	sm.rings = 10
	m.mesh = sm
	m.material_override = MatLib.get_mat(mat)
	m.transform = Transform3D(Basis(Vector3.UP, yaw) * Basis.from_scale(Vector3(0.8 if mat == "l100_sand" else 0.55, 0.3, length)), at)
	parent.add_child(m)


## A small framed photograph leaning against a stone (accessories, fact 10).
static func photo(k: GeoKit, at: Vector3, face: Vector3, lean: float, alt: bool) -> void:
	var b := Basis(Vector3.UP, atan2(face.x, face.z)) * Basis(Vector3.RIGHT, -lean)
	k.box_xf(Transform3D(b, at + Vector3(0, 0.09, 0)), Vector3(0.13, 0.18, 0.014), "l100_frame", GeoKit.ALL, false)
	k.box_xf(Transform3D(b, at + Vector3(0, 0.09, 0) + b * Vector3(0, 0, 0.008)), Vector3(0.1, 0.14, 0.002), "l100_photo_b" if alt else "l100_photo", GeoKit.ALL, false)


## The tall black being (single-witness testimony): ~3 m, a dress-like form on
## a chess-piece base, tendril arms reaching to the knees, a featureless head.
static func being() -> Node3D:
	var root := Node3D.new()
	root.name = "TallBlackBeing"
	var ink: Material = MatLib.get_mat("l100_ink")
	# chess-piece foot, collar, dress-like lower body: [top r, bottom r, height, y]
	var parts := [[0.46, 0.66, 0.30, 0.15], [0.50, 0.50, 0.08, 0.36], [0.21, 0.47, 1.35, 1.08]]
	for p in parts:
		var mi := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = p[0]
		mesh.bottom_radius = p[1]
		mesh.height = p[2]
		mi.mesh = mesh
		mi.material_override = ink
		mi.position = Vector3(0, p[3], 0)
		root.add_child(mi)
	var upper := Node3D.new()
	upper.name = "Upper"
	upper.position = Vector3(0, 1.72, 0)
	root.add_child(upper)
	var torso := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.29
	tm.bottom_radius = 0.2
	tm.height = 0.85
	torso.mesh = tm
	torso.material_override = ink
	torso.position = Vector3(0, 0.42, 0)
	upper.add_child(torso)
	var head := MeshInstance3D.new()
	head.name = "Head"
	var hm := SphereMesh.new()
	hm.radius = 0.21
	hm.height = 0.52
	head.mesh = hm
	head.material_override = ink
	head.position = Vector3(0, 1.12, 0)
	upper.add_child(head)
	for s in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.name = "Arm%d" % int(s)
		arm.position = Vector3(0.27 * s, 0.74, 0)
		arm.rotation.z = 0.12 * s
		upper.add_child(arm)
		var at := Vector3.ZERO
		for i in 7:
			var seg := MeshInstance3D.new()
			var cap := CapsuleMesh.new()
			cap.radius = 0.075 - 0.008 * i
			cap.height = 0.36
			seg.mesh = cap
			seg.material_override = ink
			var dir := Vector3(0.12 * s * sin(i * 0.9), -1.0, 0.18 * sin(i * 0.6 + 0.5)).normalized()
			seg.position = at + dir * 0.13
			seg.basis = Basis.looking_at(dir, Vector3.FORWARD) * Basis(Vector3.RIGHT, PI * 0.5)
			arm.add_child(seg)
			at += dir * 0.26
	return root


static func sea_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;
uniform vec3 shallow : source_color = vec3(0.36, 0.88, 0.80);
uniform vec3 mid : source_color = vec3(0.04, 0.58, 0.66);
uniform vec3 deep : source_color = vec3(0.02, 0.24, 0.42);
uniform float shore = 8.8;
varying vec3 wp;
float h2(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h2(i), h2(i + vec2(1, 0)), f.x), mix(h2(i + vec2(0, 1)), h2(i + vec2(1, 1)), f.x), f.y); }
float hgt(vec2 p, float t, float near) {
	float ripple = vn(p * 0.9 + vec2(t * 0.35, t * 0.12)) + 0.5 * vn(p * 2.1 - vec2(t * 0.5, -t * 0.2));
	float swash = sin(abs(p.x) * 1.6 - t * 1.4 + vn(p * 0.2) * 3.0);
	float glass = vn(p * 0.05 + t * 0.004);
	return (ripple * 0.5 + swash * 0.6) * near + glass * 0.08;
}
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float ax = abs(wp.x);
	float near = 1.0 - smoothstep(shore + 2.0, shore + 22.0, ax);
	float t = TIME;
	float e = 0.06;
	float h0 = hgt(wp.xz, t, near);
	float hx = hgt(wp.xz + vec2(e, 0.0), t, near);
	float hz = hgt(wp.xz + vec2(0.0, e), t, near);
	vec3 n = normalize(vec3((h0 - hx) * 0.55, 1.0, (h0 - hz) * 0.55));
	NORMAL = normalize((VIEW_MATRIX * vec4(FRONT_FACING ? n : -n, 0.0)).xyz);
	float lap = shore + 0.55 + 0.45 * sin(t * 0.8 + wp.z * 0.03 + vn(wp.zz * 0.07) * 2.0);
	float edge = 1.0 - smoothstep(0.0, 0.5, abs(ax - lap));
	float trail = (1.0 - smoothstep(lap, lap + 1.4, ax)) * step(shore, ax);
	float foam = clamp(edge * (0.55 + 0.45 * vn(wp.xz * 3.0 + t)) + trail * 0.35 * vn(wp.xz * 5.0 - t * 0.3), 0.0, 1.0);
	float sh = smoothstep(shore + 1.0, 17.5, ax);
	float dp = smoothstep(17.5, 80.0, ax);
	vec3 col = mix(mix(shallow, mid, sh), deep, dp);
	float fres = pow(1.0 - clamp(dot(normalize(-VERTEX), NORMAL), 0.0, 1.0), 4.0);
	ALBEDO = mix(col, vec3(0.97, 0.98, 0.97), foam * 0.85);
	ROUGHNESS = 0.02 + foam * 0.7;
	SPECULAR = 0.6;
	ALPHA = clamp(mix(0.38, 0.96, sh) + fres * 0.4 + foam * 0.5 + dp, 0.0, 1.0);
	if (!FRONT_FACING) { ALBEDO = mid * 0.6; ALPHA = 0.85; }
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	return m
