extends RefCounted
## Level 201: shared looks. Static Ghosts, Binary Fish, neon tubes and rings, the floating
## geometric shapes, lit skyscraper facades, the Trench's early-Internet windows, palms, rain.

const GHOST := """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, shadows_disabled;
uniform float seed = 0.0;
float h2(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233)) + seed) * 43758.5453); }
void fragment() {
	vec2 cell = floor(vec2(SCREEN_UV.x * 220.0, SCREEN_UV.y * 160.0) + floor(TIME * 24.0) * 7.0);
	float n = h2(cell);
	float scan = 0.6 + 0.4 * sin(SCREEN_UV.y * 500.0 + TIME * 20.0);
	float edge = pow(1.0 - abs(dot(NORMAL, VIEW)), 1.5);
	ALBEDO = vec3(0.75, 0.8, 0.95) * (0.15 + 0.6 * n * scan) * (0.4 + edge);
}
"""

const FISH := """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never, shadows_disabled;
void vertex() {
	vec4 c = INSTANCE_CUSTOM;
	float a = TIME * c.g + c.r * 6.2831;
	vec3 off = vec3(cos(a) * c.b, sin(a * 1.7 + c.r * 9.0) * 0.4, sin(a) * c.b);
	vec3 tang = normalize(vec3(-sin(a), 0.0, cos(a)) * sign(c.g));
	vec3 side = vec3(0.0, 1.0, 0.0);
	vec3 wv = MODEL_MATRIX[3].xyz + off + tang * VERTEX.x + side * VERTEX.y;
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(wv, 1.0);
}
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float body = step(p.x * p.x / 0.55 + p.y * p.y / 0.18, 1.0) * step(p.x, 0.75);
	float tail = step(0.6, p.x) * step(abs(p.y), (p.x - 0.55) * 0.9);
	float m = max(body, tail);
	vec2 g = vec2(floor(UV.x * 9.0), floor(UV.y * 4.0));
	float bit = fract(sin(dot(g, vec2(17.1, 93.7)) + floor(TIME * 3.0)) * 431.7);
	vec2 f = fract(vec2(UV.x * 9.0, UV.y * 4.0));
	float glyph = bit > 0.5 ? step(abs(f.x - 0.5), 0.12) : (step(abs(length((f - 0.5) * vec2(1.6, 1.0)) - 0.3), 0.09));
	if (m < 0.5) { discard; }
	ALBEDO = mix(vec3(0.35, 0.36, 0.4), vec3(0.85, 0.95, 0.9), glyph);
}
"""

const SHAPE := """
shader_type spatial;
render_mode diffuse_burley;
uniform vec3 a : source_color = vec3(1.0, 0.4, 0.75);
uniform vec3 b : source_color = vec3(0.2, 0.9, 1.0);
varying vec3 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	float t = clamp(lp.y * 0.5 + 0.5, 0.0, 1.0);
	vec3 c = mix(a, b, t);
	vec3 g = abs(fract(lp * 3.0) - 0.5);
	float line = smoothstep(0.46, 0.5, max(max(g.x, g.y), g.z));
	ALBEDO = c * 0.55;
	EMISSION = c * 0.35 + vec3(1.0) * line * 0.6;
	METALLIC = 0.6;
	ROUGHNESS = 0.2;
}
"""

const FACADE := """
shader_type spatial;
render_mode diffuse_burley;
uniform vec3 wall : source_color = vec3(0.07, 0.05, 0.12);
uniform vec3 lit_a : source_color = vec3(0.55, 0.3, 1.0);
uniform vec3 lit_b : source_color = vec3(0.2, 0.85, 1.0);
uniform float seed = 0.0;
varying vec3 wp;
varying vec3 wn;
float h2(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233)) + seed) * 43758.5453); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz); }
void fragment() {
	vec2 uv = abs(wn.x) > 0.5 ? wp.zy : wp.xy;
	vec2 cell = floor(uv / vec2(2.2, 3.4));
	vec2 f = fract(uv / vec2(2.2, 3.4));
	float win = step(0.18, f.x) * step(f.x, 0.82) * step(0.25, f.y) * step(f.y, 0.8) * step(0.5, 1.0 - abs(wn.y));
	float on = step(0.55, h2(cell));
	vec3 lit = mix(lit_a, lit_b, h2(cell + 3.1)) * (0.5 + 0.5 * h2(cell + 7.7));
	ALBEDO = mix(wall, vec3(0.05, 0.04, 0.1), win);
	EMISSION = lit * win * on * 1.6;
	ROUGHNESS = mix(0.8, 0.15, win);
}
"""

const RAIN := """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never, shadows_disabled;
uniform float amount = 0.0;
void vertex() {
	vec3 cam = INV_VIEW_MATRIX[3].xyz;
	vec3 p = MODEL_MATRIX[3].xyz;
	p.y -= TIME * 11.0;
	p = mod(p - cam + vec3(15.0, 12.0, 15.0), vec3(30.0, 24.0, 30.0)) - vec3(15.0, 12.0, 15.0) + cam;
	vec3 r = normalize(vec3(INV_VIEW_MATRIX[0].x, 0.0, INV_VIEW_MATRIX[0].z));
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(p + r * VERTEX.x + vec3(0.0, 1.0, 0.0) * VERTEX.y, 1.0);
}
void fragment() {
	ALBEDO = vec3(0.7, 0.6, 0.95);
	ALPHA = amount * 0.35;
}
"""


static func mat(code: String) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


static func materials() -> void:
	MatLib.define("l201_marble", {"albedo_a": Color(0.36, 0.2, 0.5), "albedo_b": Color(0.46, 0.3, 0.6), "noise_scale": 0.6,
		"roughness_a": 0.15, "roughness_b": 0.3, "stain_amount": 0.35, "stain_color": Color(0.62, 0.48, 0.75), "stain_scale": 1.6,
		"bump_strength": 0.15}, "")
	MatLib.define("l201_marble_tile", {"albedo_a": Color(0.42, 0.28, 0.55), "albedo_b": Color(0.3, 0.18, 0.42), "pattern": 9,
		"pattern_scale": Vector2(1.0, 1.0), "roughness_a": 0.12, "roughness_b": 0.2, "grout_width": 0.01}, "")
	MatLib.define("l201_asphalt", {"albedo_a": Color(0.06, 0.05, 0.08), "albedo_b": Color(0.08, 0.07, 0.1), "noise_scale": 2.0,
		"roughness_a": 0.35, "roughness_b": 0.6, "wetness": 0.6}, "")
	MatLib.define("l201_curb", {"albedo_a": Color(0.2, 0.18, 0.24), "albedo_b": Color(0.16, 0.14, 0.2), "pattern": 1,
		"pattern_scale": Vector2(1.0, 1.0), "roughness_a": 0.5}, "")
	MatLib.define("l201_canvas", {"albedo_a": Color(0.42, 0.4, 0.3), "albedo_b": Color(0.36, 0.34, 0.25), "roughness_a": 0.95}, "")
	MatLib.define("l201_metal", {"albedo_a": Color(0.3, 0.3, 0.34), "albedo_b": Color(0.24, 0.24, 0.28), "metallic_value": 0.6, "roughness_a": 0.35}, "")
	MatLib.define("l201_cabinet", {"albedo_a": Color(0.06, 0.04, 0.1), "albedo_b": Color(0.1, 0.06, 0.16), "roughness_a": 0.4}, "")
	MatLib.define("l201_trunk", {"albedo_a": Color(0.42, 0.3, 0.26), "albedo_b": Color(0.3, 0.2, 0.2), "pattern": 2,
		"pattern_scale": Vector2(1.0, 5.0), "pattern_color": Color(0.22, 0.14, 0.16), "pattern_strength": 0.5}, "")
	MatLib.register("l201_pink", MatLib.panel(Color(1.0, 0.25, 0.65), 2.6))
	MatLib.register("l201_cyan", MatLib.panel(Color(0.2, 0.95, 1.0), 2.4))
	MatLib.register("l201_yellow", MatLib.panel(Color(1.0, 0.85, 0.3), 2.2))
	MatLib.register("l201_red", MatLib.panel(Color(1.0, 0.08, 0.1), 3.0))
	MatLib.register("l201_green", MatLib.panel(Color(0.2, 1.0, 0.35), 2.6))
	MatLib.register("l201_screen", MatLib.panel(Color(0.5, 0.3, 0.9), 1.4, 0.15))
	MatLib.register("l201_crt", MatLib.panel(Color(0.3, 0.9, 0.55), 1.0, 0.05))
	MatLib.register("l201_frond", MatLib.standard(Color(0.18, 0.42, 0.34), 0.6, 0.0, Color(0.1, 0.3, 0.3), 0.25))
	var g := StandardMaterial3D.new()
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.albedo_color = Color(0.5, 0.6, 0.9, 0.2)
	g.roughness = 0.05
	g.metallic_specular = 0.9
	MatLib.register("l201_glass", g)


## A Static Ghost: a person-shaped hiss of static. pose: "stand", "lie", "wave".
static func ghost(parent: Node3D, pos: Vector3, yaw: float, pose: String, seed_v: float) -> Node3D:
	var n := Node3D.new()
	n.name = "StaticGhost"
	parent.add_child(n)
	n.position = pos
	n.rotation.y = yaw
	var m := mat(GHOST)
	m.set_shader_parameter("seed", seed_v)
	var parts := [[Vector3(0, 0.95, 0), Vector3(0.36, 0.95, 0.24), "cap"], [Vector3(0, 1.68, 0), Vector3(0.22, 0.26, 0.22), "sph"],
		[Vector3(0.28, 1.05, 0), Vector3(0.1, 0.66, 0.1), "cap"], [Vector3(-0.28, 1.05, 0), Vector3(0.1, 0.66, 0.1), "cap"]]
	for p in parts:
		var mi := MeshInstance3D.new()
		var mesh: PrimitiveMesh
		if p[2] == "cap":
			var cm := CapsuleMesh.new()
			cm.radius = 0.5
			cm.height = 2.0
			cm.radial_segments = 10
			cm.rings = 4
			mesh = cm
		else:
			var sm := SphereMesh.new()
			sm.radius = 0.5
			sm.height = 1.0
			sm.radial_segments = 10
			sm.rings = 6
			mesh = sm
		mi.mesh = mesh
		mi.scale = p[1] as Vector3 * (Vector3(1, 0.5, 1) if p[2] == "cap" else Vector3.ONE * 2.0)
		mi.position = p[0]
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		n.add_child(mi)
	if pose == "lie":
		n.rotation.x = -PI * 0.5
		n.position.y += 0.22
	elif pose == "wave":
		var arm: MeshInstance3D = n.get_child(2)
		arm.rotation.z = 2.4
		arm.position = Vector3(0.45, 1.75, 0)
	return n


static func neon_ring(parent: Node3D, c: Vector3, r: float, mat_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = r - 0.06
	tm.outer_radius = r + 0.06
	tm.rings = 32
	tm.ring_segments = 6
	mi.mesh = tm
	mi.material_override = MatLib.get_mat(mat_name)
	mi.position = c
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## A neon sign: glowing tube text plus a dark backing box.
static func neon_text(parent: Node3D, text: String, pos: Vector3, normal: Vector3, size: float, col: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = 96
	l.pixel_size = size / 96.0
	l.modulate = col * 2.2
	l.outline_size = 18
	l.outline_modulate = Color(col.r, col.g, col.b, 0.35)
	l.shaded = false
	l.double_sided = false
	parent.add_child(l)
	l.position = pos + normal * 0.03
	l.look_at(l.global_position - normal, Vector3.UP)
	return l


## A simple palm (unit-free): ringed trunk and drooping box-fronds, height h.
static func palm(k: GeoKit, base: Vector3, h: float, lean: Vector3, fronds: int = 9) -> void:
	var segs := 6
	var prev := base
	for i in segs:
		var t := float(i + 1) / segs
		var p := base + Vector3(0, h * t, 0) + lean * (t * t * h * 0.12)
		var mid := (prev + p) * 0.5
		var dir := (p - prev).normalized()
		var bx := dir.cross(Vector3(0, 0, 1)).normalized()
		var r := lerpf(0.2, 0.13, t) * h / 9.0
		k.box_xf(Transform3D(Basis(bx, dir, bx.cross(dir)), mid), Vector3(r * 2.0, prev.distance_to(p) * 1.02, r * 2.0), "l201_trunk", GeoKit.ALL, false)
		prev = p
	for f in fronds:
		var yaw := TAU * f / fronds + 0.3 * sin(f * 1.7)
		var dir := Vector3(cos(yaw), 0, sin(yaw))
		var c0 := prev
		for sgm in 4:
			var t := float(sgm + 1) / 4.0
			var c1 := prev + dir * (h * 0.32 * t) + Vector3(0, h * 0.32 * (0.35 * t - 0.75 * t * t), 0)
			var dd := (c1 - c0).normalized()
			var side := dd.cross(Vector3.UP).normalized()
			var w := h * 0.075 * sin(PI * minf(t * 1.15, 1.0)) + 0.08
			k.box_xf(Transform3D(Basis(side, side.cross(dd) * -1.0, dd).orthonormalized(), (c0 + c1) * 0.5), Vector3(w * 2.0, 0.03, c0.distance_to(c1) * 1.05), "l201_frond", GeoKit.ALL, false)
			c0 = c1


static func rain_node() -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var qm := QuadMesh.new()
	qm.size = Vector2(0.015, 0.6)
	mm.mesh = qm
	mm.instance_count = 1200
	var r := RandomNumberGenerator.new()
	r.seed = 201
	for i in 1200:
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(r.randf() * 30.0, r.randf() * 24.0, r.randf() * 30.0)))
	var mi := MultiMeshInstance3D.new()
	mi.name = "CityRain"
	mi.multimesh = mm
	mi.material_override = mat(RAIN)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 16384.0
	mi.visible = false
	return mi


## A school of Binary Fish circling a point.
static func fish_school(parent: Node3D, c: Vector3, n: int, r: RandomNumberGenerator) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	var qm := QuadMesh.new()
	qm.size = Vector2(0.22, 0.1)
	mm.mesh = qm
	mm.instance_count = n
	var dirn := 1.0 if r.randf() < 0.5 else -1.0
	for i in n:
		mm.set_instance_transform(i, Transform3D(Basis(), c + Vector3(r.randf_range(-0.6, 0.6), r.randf_range(-0.5, 0.5), r.randf_range(-0.6, 0.6))))
		mm.set_instance_custom_data(i, Color(r.randf() * 0.15, dirn * r.randf_range(0.35, 0.5), r.randf_range(2.2, 3.4), 0))
	var mi := MultiMeshInstance3D.new()
	mi.name = "BinaryFish"
	mi.multimesh = mm
	mi.material_override = mat(FISH)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 8.0
	parent.add_child(mi)
	return mi
