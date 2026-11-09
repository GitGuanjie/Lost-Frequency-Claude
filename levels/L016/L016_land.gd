extends RefCounted
## Level 16 land: one valley shared by both terrain states. A rolling floor
## crossed by a river, a rock mesa with a spur you can walk up, and ridges
## that climb steeply all round (the edge is terrain and fog, never a wall).
## The render mesh, the collision heightmap and prop placement share h().
## The terrain shader blends rainforest floor -> luminous ice by a front that
## sweeps out from `front_origin` (uniform `front`, `dir`: 1 freezing, 0 thaw).

const HALF := 180.0
const STEP := 2.0
const N := 181
const FLOOR_R := 104.0
const MESA := Vector2(34.0, -22.0)

var hs := PackedFloat32Array()
var n_a := FastNoiseLite.new()
var n_b := FastNoiseLite.new()


func _init() -> void:
	n_a.seed = 1601
	n_a.frequency = 0.018
	n_a.fractal_octaves = 4
	n_b.seed = 1602
	n_b.frequency = 0.09
	_bake()


func river_z(x: float) -> float:
	return 30.0 + 18.0 * sin(x * 0.021 + 0.6) + 6.0 * sin(x * 0.057)


func river_d(x: float, z: float) -> float:
	return absf(z - river_z(x))


func _raw(x: float, z: float) -> float:
	var r := sqrt(x * x + z * z)
	var a := atan2(z, x)
	var y := 1.6 * n_a.get_noise_2d(x, z) + 0.35 * n_b.get_noise_2d(x, z)
	var ridge := smoothstep(FLOOR_R - 6.0, FLOOR_R + 62.0, r)
	y += ridge * ridge * (44.0 + 14.0 * n_a.get_noise_2d(cos(a) * 60.0, sin(a) * 60.0)) + ridge * 6.0 * n_b.get_noise_2d(x * 0.4, z * 0.4)
	# the mesa: a flat-topped rock with one spur running down towards the start
	var md := Vector2(x, z).distance_to(MESA)
	var top := 7.5 + 0.4 * n_b.get_noise_2d(x * 2.0, z * 2.0)
	var mesa := top * (1.0 - smoothstep(10.0, 14.5, md))
	var to_start := (Vector2.ZERO - MESA).normalized()
	var rel := Vector2(x, z) - MESA
	var along := rel.dot(to_start)
	var side := absf(rel.dot(Vector2(-to_start.y, to_start.x)))
	if along > 8.0 and along < 30.0 and side < 4.0:
		var spur := top * (1.0 - (along - 8.0) / 22.0) * (1.0 - smoothstep(2.6, 4.0, side))
		mesa = maxf(mesa, spur)
	y = maxf(y, y * 0.3 + mesa)
	# the river channel
	var rd := river_d(x, z)
	y -= 1.5 * (1.0 - smoothstep(2.8, 6.5, rd)) * (1.0 - ridge)
	return y


func _bake() -> void:
	hs.resize(N * N)
	for iz in N:
		for ix in N:
			hs[iz * N + ix] = _raw(-HALF + ix * STEP, -HALF + iz * STEP)


func h(x: float, z: float) -> float:
	var fx := clampf((x + HALF) / STEP, 0.0, N - 1.001)
	var fz := clampf((z + HALF) / STEP, 0.0, N - 1.001)
	var ix := int(fx)
	var iz := int(fz)
	var tx := fx - ix
	var tz := fz - iz
	return lerpf(lerpf(hs[iz * N + ix], hs[iz * N + ix + 1], tx), lerpf(hs[(iz + 1) * N + ix], hs[(iz + 1) * N + ix + 1], tx), tz)


func slope(x: float, z: float) -> float:
	var e := 1.5
	return Vector2(h(x + e, z) - h(x - e, z), h(x, z + e) - h(x, z - e)).length() / (2.0 * e)


func water_y() -> float:
	return -0.95


# ------------------------------------------------------------ meshes

func build_mesh(parent: Node3D, mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in N:
		for ix in N:
			var x := -HALF + ix * STEP
			var z := -HALF + iz * STEP
			var l := hs[iz * N + maxi(ix - 1, 0)]
			var r := hs[iz * N + mini(ix + 1, N - 1)]
			var u := hs[maxi(iz - 1, 0) * N + ix]
			var d := hs[mini(iz + 1, N - 1) * N + ix]
			var nrm := Vector3(l - r, 2.0 * STEP, u - d).normalized()
			var wet := 1.0 - smoothstep(2.0, 7.0, river_d(x, z))
			st.set_normal(nrm)
			st.set_color(Color(1.0 - nrm.y, wet, 0, 0))
			st.add_vertex(Vector3(x, hs[iz * N + ix], z))
	for iz in N - 1:
		for ix in N - 1:
			var a := iz * N + ix
			st.add_index(a)
			st.add_index(a + 1)
			st.add_index(a + N)
			st.add_index(a + 1)
			st.add_index(a + N + 1)
			st.add_index(a + N)
	var mi := MeshInstance3D.new()
	mi.name = "Valley"
	mi.mesh = st.commit()
	mi.material_override = mat
	parent.add_child(mi)
	# far ridges so the horizon is always land
	var fs := SurfaceTool.new()
	fs.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 96
	var radii := [HALF - 4.0, HALF + 40.0, HALF + 120.0, HALF + 260.0, HALF + 520.0]
	for j in segs + 1:
		var a := TAU * j / segs
		for i in radii.size():
			var rr: float = radii[i]
			var y := 52.0 + 20.0 * n_a.get_noise_2d(cos(a) * 80.0, sin(a) * 80.0) + float(i) * 6.0
			if i == 0:
				y = h(cos(a) * rr, sin(a) * rr)
			fs.set_normal(Vector3(-cos(a), 1.6, -sin(a)).normalized())
			fs.set_color(Color(0.6, 0, 0, 0))
			fs.add_vertex(Vector3(cos(a) * rr, y, sin(a) * rr))
	var nr := radii.size()
	for j in segs:
		for i in nr - 1:
			var a0 := j * nr + i
			var b0 := (j + 1) * nr + i
			fs.add_index(a0)
			fs.add_index(a0 + 1)
			fs.add_index(b0)
			fs.add_index(a0 + 1)
			fs.add_index(b0 + 1)
			fs.add_index(b0)
	var mf := MeshInstance3D.new()
	mf.name = "FarRidges"
	mf.mesh = fs.commit()
	mf.material_override = mat
	mf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mf)


func collision(parent: Node3D) -> void:
	var size := 300
	var md := PackedFloat32Array()
	md.resize((size + 1) * (size + 1))
	for j in size + 1:
		for i in size + 1:
			md[j * (size + 1) + i] = h(-150.0 + i, -150.0 + j)
	var body := StaticBody3D.new()
	body.name = "Ground"
	parent.add_child(body)
	var sh := HeightMapShape3D.new()
	sh.map_width = size + 1
	sh.map_depth = size + 1
	sh.map_data = md
	var cs := CollisionShape3D.new()
	cs.shape = sh
	cs.position = Vector3(0, 0, 0)
	cs.set_meta("surface", "dirt")
	body.add_child(cs)


# ------------------------------------------------------------ shaders

const TERRAIN := """
shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D soil_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 front_origin = vec3(0.0);
uniform float front = -1000.0;
uniform float dir = 1.0;
uniform float glow = 0.35;
varying vec3 wp;
varying vec3 wn;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz); }
void fragment() {
	float macro = vn(wp.xz * 0.04) * 0.6 + vn(wp.xz * 0.2) * 0.4;
	float steep = clamp(COLOR.r * 2.4, 0.0, 1.0);
	// rainforest floor: dark soil, leaf litter, moss
	vec3 soil = texture(soil_alb, wp.xz / 2.6).rgb * vec3(0.55, 0.45, 0.34);
	vec3 moss = texture(grass_alb, wp.xz / 2.2).rgb * vec3(0.55, 0.85, 0.4);
	float litter = vn(wp.xz * 1.7) * 0.5 + vn(wp.xz * 5.0) * 0.5;
	vec3 forest = mix(soil, moss, smoothstep(0.35, 0.75, macro) * 0.8);
	forest = mix(forest, vec3(0.2, 0.11, 0.05) * (0.6 + 0.6 * litter), smoothstep(0.55, 0.85, litter) * 0.45);
	vec3 rock = texture(rock_alb, wp.xz / 4.0 + wp.y * 0.1).rgb * 0.8;
	forest = mix(forest, rock, smoothstep(0.35, 0.7, steep));
	forest = mix(forest, soil * 0.55, COLOR.g * 0.7);
	// arctic: snow with luminous, highly reflective ice where it is flat and low
	float sparkle = step(0.992, hsh(floor(wp.xz * 40.0) + floor(TIME * 2.0)));
	vec3 snow = vec3(0.78, 0.84, 0.9) * (0.88 + 0.12 * macro);
	float icef = clamp(smoothstep(0.45, 0.8, vn(wp.xz * 0.05 + 3.0)) + COLOR.g, 0.0, 1.0);
	vec3 ice = vec3(0.45, 0.66, 0.82);
	vec3 arctic = mix(snow, ice, icef * 0.75);
	arctic = mix(arctic, rock * vec3(0.8, 0.85, 0.95), smoothstep(0.55, 0.9, steep) * 0.7);
	// where the change has reached
	float d = length(wp.xz - front_origin.xz) + vn(wp.xz * 0.08) * 22.0;
	float t = smoothstep(front - 18.0, front, d);
	float s = dir > 0.5 ? 1.0 - t : t;
	float edge = (1.0 - abs(t * 2.0 - 1.0)) * step(-999.0, front);
	vec3 c = mix(forest, arctic, s);
	ALBEDO = c;
	ROUGHNESS = mix(0.95, mix(0.5, 0.06, icef), s);
	SPECULAR = mix(0.25, 0.8, s);
	EMISSION = (arctic * glow * (0.35 + 0.65 * icef) + vec3(0.6, 0.85, 1.0) * sparkle * 1.5) * s + vec3(0.4, 0.7, 1.0) * edge * 0.6;
}
"""

const SKY := """
shader_type sky;
uniform vec3 top_a : source_color = vec3(0.32, 0.38, 0.52);
uniform vec3 hor_a : source_color = vec3(0.95, 0.62, 0.42);
uniform vec3 top_b : source_color = vec3(0.24, 0.42, 0.7);
uniform vec3 hor_b : source_color = vec3(0.8, 0.88, 0.95);
uniform float state = 0.0;
uniform float night = 0.0;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
void sky() {
	vec3 d = EYEDIR;
	float y = max(d.y, 0.0);
	vec3 top = mix(top_a, top_b, state);
	vec3 hor = mix(hor_a, hor_b, state);
	vec3 c = mix(hor, top, smoothstep(0.0, 0.5, y));
	// the low dawn sun glow (state A) / the moving sun (state B)
	float sun = pow(max(dot(d, LIGHT0_DIRECTION), 0.0), 220.0) * 6.0 + pow(max(dot(d, LIGHT0_DIRECTION), 0.0), 6.0) * 0.35;
	c += LIGHT0_COLOR * sun * (1.0 - night);
	vec2 uv = d.xz / (d.y + 0.15);
	float cl = vn(uv * 1.3 + TIME * 0.003) * 0.6 + vn(uv * 3.0) * 0.4;
	c = mix(c, c * 1.15 + vec3(0.05), smoothstep(0.55, 0.85, cl) * 0.5 * y);
	vec3 nightc = vec3(0.01, 0.015, 0.035) + vec3(0.02, 0.04, 0.06) * (1.0 - y);
	float stars = step(0.997, hsh(floor(d.xz / (d.y + 0.4) * 300.0))) * y;
	c = mix(c, nightc + stars, night);
	if (d.y < 0.0) { c = hor * (1.0 - night * 0.9); }
	COLOR = c;
}
"""


static func shader_mat(code: String) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


func terrain_material() -> ShaderMaterial:
	var m := shader_mat(TERRAIN)
	for pair in [["soil_alb", "res://assets/external/dirt_floor/dirt_floor_diff_1k.jpg"], ["grass_alb", "res://assets/external/sparse_grass/sparse_grass_diff_1k.jpg"],
			["rock_alb", "res://assets/external/aerial_rocks_02/aerial_rocks_02_diff_1k.jpg"]]:
		if ResourceLoader.exists(pair[1]):
			m.set_shader_parameter(pair[0], load(pair[1]))
	return m
