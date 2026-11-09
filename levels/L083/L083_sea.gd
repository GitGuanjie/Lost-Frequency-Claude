extends RefCounted
## Level 83: what the windows show. 600 m down in a rocky valley: black water, rock formations
## faintly lit by the boat's own windows, drifting particles, Pacific fish (salmon, ragfish,
## Atka mackerel) and, now and then, the Great Observer's eye at the glass. Nothing here is
## walkable: the page says the outside is unexplored.

const WATER := Color(0.004, 0.018, 0.03)

const OUT_SHADER := """
shader_type spatial;
render_mode unshaded, fog_disabled, cull_back;
uniform vec3 base : source_color = vec3(0.16, 0.15, 0.13);
uniform vec3 water : source_color = vec3(0.004, 0.018, 0.03);
uniform float disp = 0.0;
uniform float fog_k = 0.075;
varying vec3 wpos;
varying vec3 wnrm;
float h3(vec3 p) { return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453); }
float n3(vec3 p) {
	vec3 i = floor(p); vec3 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1,0,0)), f.x), mix(h3(i + vec3(0,1,0)), h3(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(h3(i + vec3(0,0,1)), h3(i + vec3(1,0,1)), f.x), mix(h3(i + vec3(0,1,1)), h3(i + vec3(1,1,1)), f.x), f.y), f.z);
}
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float n = n3(w * 0.35) * 0.65 + n3(w * 1.1) * 0.25 + n3(w * 3.0) * 0.1;
	VERTEX += NORMAL * (n - 0.5) * disp;
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	float n = n3(wpos * 2.3);
	vec3 col = base * (0.6 + 0.6 * n);
	// the only light down here spills from the boat's windows (hull axis x = 0, y ~ 3.4)
	vec3 to_hull = vec3(0.0, 3.4, clamp(wpos.z, -40.0, 40.0)) - wpos;
	float dh = length(to_hull);
	float facing = clamp(dot(wnrm, normalize(to_hull)) * 0.6 + 0.4, 0.0, 1.0);
	float lit = exp(-max(dh - 5.0, 0.0) * 0.16) * facing * 1.4 + 0.05 * clamp(wnrm.y, 0.0, 1.0);
	col *= lit;
	float dist = length(VERTEX);
	ALBEDO = mix(col, water, 1.0 - exp(-dist * fog_k));
}
"""

const BACK_SHADER := """
shader_type spatial;
render_mode unshaded, fog_disabled, cull_front, depth_draw_never;
uniform vec3 deep : source_color = vec3(0.0, 0.004, 0.008);
uniform vec3 high : source_color = vec3(0.01, 0.045, 0.06);
varying vec3 dir;
void vertex() { dir = normalize(VERTEX); }
void fragment() {
	float t = clamp(dir.y * 0.8 + 0.35, 0.0, 1.0);
	ALBEDO = mix(deep, high, t * t);
}
"""

const FISH_SHADER := """
shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled;
uniform vec3 water : source_color = vec3(0.004, 0.018, 0.03);
varying vec3 tint;
varying float band;
void vertex() {
	vec4 c = INSTANCE_CUSTOM;            // r phase, g speed, b radius, a species
	float a = TIME * c.g + c.r * 6.2831;
	float wag = sin(TIME * 7.0 + c.r * 40.0) * 0.18 * smoothstep(0.0, -0.3, VERTEX.z);
	vec3 v = VERTEX + vec3(wag, 0.0, 0.0);
	float yaw = -a;
	float sd = sign(c.g);
	vec3 r = vec3(v.x * cos(yaw) + v.z * sin(yaw) * sd, v.y, -v.x * sin(yaw) * sd + v.z * cos(yaw));
	vec3 off = vec3(cos(a) * c.b, sin(a * 0.7 + c.r * 3.0) * 0.5, sin(a) * c.b);
	VERTEX = r + off;
	band = VERTEX.z;
	tint = c.a < 0.33 ? vec3(0.55, 0.5, 0.48) : (c.a < 0.66 ? vec3(0.32, 0.24, 0.18) : vec3(0.5, 0.44, 0.22));
}
void fragment() {
	vec3 w = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float dh = length(vec2(w.x, w.y - 3.4));
	float lit = exp(-max(dh - 5.0, 0.0) * 0.18) * 1.5 + 0.03;
	vec3 col = tint * lit * (0.8 + 0.2 * sin(band * 40.0));
	ALBEDO = mix(col, water, 1.0 - exp(-length(VERTEX) * 0.09));
}
"""

const SNOW_SHADER := """
shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, blend_add, depth_draw_never;
void vertex() {
	vec4 c = INSTANCE_CUSTOM;
	vec3 o = MODEL_MATRIX[3].xyz;
	o.y = mod(o.y - TIME * (0.05 + c.g * 0.08) + 40.0, 14.0) - 3.0;
	o.x += sin(TIME * 0.2 + c.r * 9.0) * 0.4;
	vec3 cam_r = INV_VIEW_MATRIX[0].xyz;
	vec3 cam_u = INV_VIEW_MATRIX[1].xyz;
	vec3 wv = o + (cam_r * VERTEX.x + cam_u * VERTEX.y);
	POSITION = PROJECTION_MATRIX * VIEW_MATRIX * vec4(wv, 1.0);
}
void fragment() {
	float d = length(UV - vec2(0.5));
	ALBEDO = vec3(0.35, 0.4, 0.38) * smoothstep(0.5, 0.1, d) * 0.5;
}
"""

const EYE_SHADER := """
shader_type spatial;
render_mode cull_back;
uniform float open = 1.0;
varying vec3 lp;
void vertex() { lp = VERTEX; }
void fragment() {
	// local +x faces the glass. Sclera, a wide golden iris and a huge black pupil.
	vec2 q = lp.yz / vec2(0.8, 1.0);
	float r = length(q);
	vec3 sclera = vec3(0.62, 0.58, 0.46) - 0.1 * vec3(sin(q.x * 30.0) * sin(q.y * 25.0));
	vec3 iris = mix(vec3(0.42, 0.28, 0.06), vec3(0.2, 0.12, 0.03), smoothstep(0.35, 0.75, r)) * (0.85 + 0.15 * sin(atan(q.y, q.x) * 40.0));
	vec3 col = mix(iris, sclera, smoothstep(0.72, 0.8, r));
	col = mix(vec3(0.0), col, smoothstep(0.34, 0.4, r));
	float lid = step(abs(q.x), open * 0.95);
	ALBEDO = mix(vec3(0.16, 0.05, 0.05), col, lid);
	ROUGHNESS = 0.08;
	SPECULAR = 0.9;
	EMISSION = ALBEDO * 0.55;
}
"""

var L: LevelBase
var rng: RandomNumberGenerator
var root: Node3D
var eye: Node3D
var body: MeshInstance3D
var tentacle: MeshInstance3D
var out_mat: ShaderMaterial
var floor_mat: ShaderMaterial


func _init(level: LevelBase, r: RandomNumberGenerator) -> void:
	L = level
	rng = r
	root = Node3D.new()
	root.name = "Outside"
	L.add_child(root)


func _mat(code: String) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


func build() -> void:
	# black water all round
	var back := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 140.0
	sm.height = 280.0
	back.mesh = sm
	back.material_override = _mat(BACK_SHADER)
	back.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	back.position = Vector3(0, 0, -2)
	root.add_child(back)
	out_mat = _mat(OUT_SHADER)
	out_mat.set_shader_parameter("disp", 2.2)
	out_mat.set_shader_parameter("water", Vector3(WATER.r, WATER.g, WATER.b))
	floor_mat = _mat(OUT_SHADER)
	floor_mat.set_shader_parameter("disp", 0.35)
	floor_mat.set_shader_parameter("base", Vector3(0.13, 0.12, 0.1))
	# the valley floor the boat rests on (y -1.5) and its silt
	var pm := PlaneMesh.new()
	pm.size = Vector2(220, 220)
	pm.subdivide_width = 60
	pm.subdivide_depth = 60
	var fl := MeshInstance3D.new()
	fl.mesh = pm
	fl.material_override = floor_mat
	fl.position = Vector3(0, -1.55, -2)
	fl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(fl)
	# rock formations: the valley walls on both beams, plus boulders near the hull
	for side: float in [-1.0, 1.0]:
		var z := -70.0
		while z < 70.0:
			var r := rng.randf_range(7.0, 13.0)
			_rock(Vector3(side * rng.randf_range(16.0, 24.0), rng.randf_range(-2.0, 6.0), z), Vector3(r, r * rng.randf_range(1.2, 2.2), r * 1.1))
			if rng.randf() < 0.6:
				var r2 := rng.randf_range(5.0, 9.0)
				_rock(Vector3(side * rng.randf_range(26.0, 34.0), rng.randf_range(10.0, 22.0), z + rng.randf_range(-6.0, 6.0)), Vector3(r2, r2 * 1.6, r2))
			z += rng.randf_range(9.0, 15.0)
		for i in 7:
			var r3 := rng.randf_range(0.8, 2.4)
			_rock(Vector3(side * rng.randf_range(6.5, 12.0), -1.4 + r3 * 0.3, rng.randf_range(-40.0, 40.0)), Vector3(r3 * 1.3, r3 * 0.8, r3))
	_fish()
	_snow()
	_observer()


func _rock(c: Vector3, s: Vector3) -> void:
	var m := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 20
	sm.rings = 12
	m.mesh = sm
	m.material_override = out_mat
	m.scale = s
	m.rotation = Vector3(rng.randf_range(-0.3, 0.3), rng.randf() * TAU, rng.randf_range(-0.2, 0.2))
	m.position = c
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(m)


func _fish_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var L0 := 0.32
	var nose := Vector3(0, 0, L0)
	var tailj := Vector3(0, 0, -L0 * 0.9)
	var ring := [Vector3(0.0, 0.08, 0.05), Vector3(0.045, 0.0, 0.05), Vector3(0.0, -0.07, 0.05), Vector3(-0.045, 0.0, 0.05)]
	for i in 4:
		var a: Vector3 = ring[i]
		var b: Vector3 = ring[(i + 1) % 4]
		st.add_vertex(nose)
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(tailj)
		st.add_vertex(b)
		st.add_vertex(a)
	st.add_vertex(tailj)
	st.add_vertex(tailj + Vector3(0, 0.1, -0.14))
	st.add_vertex(tailj + Vector3(0, -0.1, -0.14))
	return st.commit()


## Pacific salmon, ragfish and Atka mackerel circling in the light from the windows.
func _fish() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = _fish_mesh()
	var n := 70
	mm.instance_count = n
	for i in n:
		var side := -1.0 if i % 2 == 0 else 1.0
		var species := float(i % 3) / 3.0 + 0.1
		var size := [1.1, 1.5, 0.8][i % 3] as float
		var c := Vector3(side * rng.randf_range(8.0, 15.0), rng.randf_range(0.0, 7.0), rng.randf_range(-36.0, 36.0))
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * size), c))
		var spd := rng.randf_range(0.08, 0.2) * (1.0 if rng.randf() < 0.5 else -1.0)
		mm.set_instance_custom_data(i, Color(rng.randf(), spd, rng.randf_range(2.0, 5.0), species))
	var mi := MultiMeshInstance3D.new()
	mi.name = "PacificFish"
	mi.multimesh = mm
	mi.material_override = _mat(FISH_SHADER)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 16.0
	root.add_child(mi)


func _snow() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	var qm := QuadMesh.new()
	qm.size = Vector2(0.05, 0.05)
	mm.mesh = qm
	mm.instance_count = 500
	for i in 500:
		var side := -1.0 if i % 2 == 0 else 1.0
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(side * rng.randf_range(5.0, 11.0), rng.randf_range(-3.0, 11.0), rng.randf_range(-44.0, 42.0))))
		mm.set_instance_custom_data(i, Color(rng.randf(), rng.randf(), 0, 0))
	var mi := MultiMeshInstance3D.new()
	mi.name = "MarineSnow"
	mi.multimesh = mm
	mi.material_override = _mat(SNOW_SHADER)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 20.0
	root.add_child(mi)


## The Great Observer: its 20-inch eye, the skin around it, and one serrated arm.
func _observer() -> void:
	eye = Node3D.new()
	eye.name = "GreatObserverEye"
	eye.visible = false
	root.add_child(eye)
	var em := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 32
	sm.rings = 16
	em.mesh = sm
	em.scale = Vector3(0.14, 0.21, 0.25)
	em.material_override = _mat(EYE_SHADER)
	eye.add_child(em)
	body = MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 1.0
	bm.height = 2.0
	body.mesh = bm
	body.scale = Vector3(0.9, 1.3, 2.2)
	body.position = Vector3(0.82, 0, 0)
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.2, 0.05, 0.05)
	skin.roughness = 0.25
	skin.emission_enabled = true
	skin.emission = Color(0.05, 0.01, 0.01)
	body.material_override = skin
	eye.add_child(body)
	tentacle = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.05
	cm.bottom_radius = 0.45
	cm.height = 9.0
	tentacle.mesh = cm
	tentacle.material_override = skin
	tentacle.visible = false
	root.add_child(tentacle)


## Press the eye against a window (n = outward normal of the glass).
func show_eye(w: Dictionary) -> void:
	var p: Vector3 = w["pos"]
	var n: Vector3 = w["n"]
	eye.global_position = p + n * 0.12
	eye.rotation = Vector3(0, 0.0 if n.x > 0.0 else PI, 0)
	eye.visible = true


func hide_eye() -> void:
	eye.visible = false


func eye_dart(t: float, n: Vector3) -> void:
	eye.global_position += n * t * 30.0 + Vector3(0, t * 6.0, 0)


func sweep_arm(w: Dictionary, k: float) -> void:
	var p: Vector3 = w["pos"]
	var n: Vector3 = w["n"]
	tentacle.visible = k > 0.0 and k < 1.0
	tentacle.global_position = p + n * 1.2 + Vector3(0, 0, lerpf(-6.0, 6.0, k))
	tentacle.rotation = Vector3(PI * 0.5, 0, 0.3)
