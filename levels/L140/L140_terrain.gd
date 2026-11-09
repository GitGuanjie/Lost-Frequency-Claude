extends RefCounted
## Level 140 terrain: a gently rolling field that "seems to stretch out to the
## horizon" (SOURCE, testimony). East is +X. The camp (the lobby cottage and
## its backyard) sits on a low rise at the origin; the first sunflower field
## lies east; the second field of weeds to its left (north); the wheat field
## that runs on "infinite" begins to the south.

const COTTAGE := Vector3(-8.0, 0.0, 0.0)
const SUN_FIELD := Rect2(18.0, -38.0, 96.0, 74.0)        # x, z, w, d
const WEED_FIELD := Rect2(20.0, -122.0, 86.0, 62.0)
const WHEAT_Z := 150.0
const WHEAT_NEAR := Rect2(-70.0, 150.0, 140.0, 70.0)
const BLUE_FLOWER := Vector3(-14.0, 0.0, 58.0)
const PATH_END := Vector3(4.0, 0.0, 152.0)
const HIVES := Vector3(10.0, 0.0, 30.0)
const WEIRD := Vector3(58.0, 0.0, -92.0)
const NEAR_MIN := Vector2(-280.0, -280.0)
const NEAR_MAX := Vector2(280.0, 300.0)
const NEAR_STEP := 2.0
const FAR_STEP := 40.0
const FAR_MIN := Vector2(-3600.0, -3600.0)
const FAR_MAX := Vector2(3600.0, 3600.0)

var n_roll := FastNoiseLite.new()
var n_det := FastNoiseLite.new()


func _init() -> void:
	n_roll.seed = 14001
	n_roll.fractal_octaves = 3
	n_roll.frequency = 0.006
	n_det.seed = 14002
	n_det.frequency = 0.05


func h(x: float, z: float) -> float:
	var y := 1.6 * n_roll.get_noise_2d(x, z) + 0.25 * n_det.get_noise_2d(x, z)
	# far away the land swells a little more, so the horizon is a soft line
	var r := Vector2(x, z).length()
	y += smoothstep(300.0, 1500.0, r) * 8.0 * n_roll.get_noise_2d(x * 0.4 + 900.0, z * 0.4)
	# the camp rise
	var dc := Vector2(x - COTTAGE.x, z - COTTAGE.z).length()
	y += 2.2 * (1.0 - smoothstep(10.0, 60.0, dc))
	# keep the cottage pad level
	y = lerpf(h_pad(), y, smoothstep(9.0, 16.0, dc))
	return y


func h_pad() -> float:
	return 2.2 + 1.6 * n_roll.get_noise_2d(COTTAGE.x, COTTAGE.z) + 0.25 * n_det.get_noise_2d(COTTAGE.x, COTTAGE.z)


func normal_at(x: float, z: float, e: float = 1.0) -> Vector3:
	return Vector3(h(x - e, z) - h(x + e, z), 2.0 * e, h(x, z - e) - h(x, z + e)).normalized()


## Distance to the camp paths (cottage -> hives -> field, cottage -> blue flower).
func path_d(x: float, z: float) -> float:
	var segs := [[Vector2(-2.0, 2.0), Vector2(HIVES.x - 3.0, HIVES.z - 4.0)], [Vector2(-2.0, 0.0), Vector2(SUN_FIELD.position.x - 2.0, 0.0)],
		[Vector2(-8.0, 8.0), Vector2(BLUE_FLOWER.x + 2.0, BLUE_FLOWER.z - 3.0)], [Vector2(-2.0, -2.0), Vector2(30.0, -56.0)]]
	var best := INF
	for s in segs:
		var a: Vector2 = s[0]
		var b: Vector2 = s[1]
		var p := Vector2(x, z)
		var t := clampf((p - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
		best = minf(best, p.distance_to(a + (b - a) * t))
	return best


## r: worn path, g: wheat gold, b: sunflower/weed soil, a: lush.
func weights(x: float, z: float) -> Color:
	var path := 1.0 - smoothstep(0.8, 1.8, path_d(x, z) + 0.6 * n_det.get_noise_2d(x * 2.0, z * 2.0))
	var wheat := smoothstep(WHEAT_Z - 6.0, WHEAT_Z + 6.0, z + 4.0 * n_det.get_noise_2d(x * 0.3, 0.0))
	var soil := 0.0
	if SUN_FIELD.grow(1.0).has_point(Vector2(x, z)) or WEED_FIELD.grow(1.0).has_point(Vector2(x, z)):
		soil = 0.7
	var lush := 0.5 + 0.5 * n_roll.get_noise_2d(x * 3.0, z * 3.0)
	return Color(path, wheat, soil, lush)


static func shader_code() -> String:
	return """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D grass_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 grass_tint = vec3(0.85, 1.35, 0.42);
uniform vec3 dry_tint = vec3(1.15, 1.25, 0.5);
uniform vec3 wheat_col = vec3(0.86, 0.66, 0.28);
uniform vec3 dirt_tint = vec3(0.9, 0.78, 0.6);
uniform float shell = 0.0;
varying vec3 wpos;
varying vec4 wts;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wts = COLOR;
}
void fragment() {
	float macro = texture(grass_alb, wpos.xz / 151.0).g * 0.6 + texture(dirt_alb, wpos.zx / 67.0).r * 0.4;
	vec3 g1 = texture(grass_alb, wpos.xz / 3.0).rgb;
	vec3 g2 = texture(grass_alb, wpos.xz / 11.0 + 0.3).rgb;
	vec3 gr = mix(g1, g2, 0.4) * mix(dry_tint, grass_tint, clamp(wts.a * 0.8 + macro * 0.4, 0.0, 1.0)) * (0.8 + 0.4 * macro);
	gr = mix(vec3(0.17, 0.3, 0.07) * (0.8 + 0.5 * macro), gr, 0.45);
	vec3 di = texture(dirt_alb, wpos.xz / 2.4).rgb * dirt_tint;
	vec3 wh = wheat_col * (0.8 + 0.4 * texture(dirt_alb, wpos.xz / vec2(0.7, 4.0)).r) * (0.9 + 0.2 * macro);
	vec3 alb = gr;
	alb = mix(alb, di * 0.8 + gr * 0.2, wts.b * 0.6);
	alb = mix(alb, wh, clamp(wts.g, 0.0, 1.0));
	alb = mix(alb, di, clamp(wts.r, 0.0, 1.0));
	if (shell > 0.5) {
		alb = wh * 1.05;
	}
	ALBEDO = alb;
	ROUGHNESS = 0.95;
	SPECULAR = 0.25;
}
"""


func make_material(shell: bool) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = shader_code()
	var m := ShaderMaterial.new()
	m.shader = sh
	for pair in [["grass_alb", "sparse_grass/sparse_grass_diff_1k.jpg"], ["dirt_alb", "dirt_floor/dirt_floor_diff_1k.jpg"]]:
		var p := "res://assets/external/" + str(pair[1])
		if ResourceLoader.exists(p):
			m.set_shader_parameter(pair[0], load(p))
	m.set_shader_parameter("shell", 1.0 if shell else 0.0)
	return m


func build_meshes(parent: Node3D, mat: Material, shell_mat: Material) -> void:
	var near := _grid(NEAR_MIN, NEAR_MAX, NEAR_STEP, Rect2(), 0.0, Rect2())
	var mi := MeshInstance3D.new()
	mi.name = "Field"
	mi.mesh = near
	mi.material_override = mat
	parent.add_child(mi)
	var hole := Rect2(NEAR_MIN + Vector2(FAR_STEP, FAR_STEP), NEAR_MAX - NEAR_MIN - Vector2(FAR_STEP, FAR_STEP) * 2.0)
	var far := _grid(FAR_MIN, FAR_MAX, FAR_STEP, hole, 0.0, Rect2())
	var mf := MeshInstance3D.new()
	mf.name = "FieldToTheHorizon"
	mf.mesh = far
	mf.material_override = mat
	mf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mf)
	# the wheat beyond the planted band: a waist-high golden surface to the horizon
	var near_rect := Rect2(-300.0, WHEAT_Z + 2.0, 600.0, 200.0)
	var shells := [_grid(near_rect.position, near_rect.end, 3.0, Rect2(), 1.0, WHEAT_NEAR.grow(-3.0)),
		_grid(Vector2(-3600.0, WHEAT_Z + 2.0), Vector2(3600.0, 3600.0), 40.0, near_rect.grow(-40.0), 1.0, Rect2())]
	for sm in shells:
		var ms := MeshInstance3D.new()
		ms.name = "WheatToTheHorizon"
		ms.mesh = sm
		ms.material_override = shell_mat
		ms.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(ms)


func _grid(mn: Vector2, mx: Vector2, step: float, hole: Rect2, lift: float, skip: Rect2) -> ArrayMesh:
	var nx := int(round((mx.x - mn.x) / step)) + 1
	var nz := int(round((mx.y - mn.y) / step)) + 1
	# coarse grids over the far wheat are capped so the vertex count stays sane
	if nx * nz > 140000:
		step = maxf(step, sqrt((mx.x - mn.x) * (mx.y - mn.y) / 120000.0))
		nx = int(round((mx.x - mn.x) / step)) + 1
		nz = int(round((mx.y - mn.y) / step)) + 1
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hs := PackedFloat32Array()
	hs.resize(nx * nz)
	for iz in nz:
		for ix in nx:
			var x := mn.x + ix * step
			var z := mn.y + iz * step
			var y := h(x, z) + lift * (0.95 + 0.15 * n_det.get_noise_2d(x * 0.5, z * 0.5))
			if hole.size.x > 0.0 and hole.grow(step).has_point(Vector2(x, z)):
				y -= 0.6
			hs[iz * nx + ix] = y
	for iz in nz:
		for ix in nx:
			var x := mn.x + ix * step
			var z := mn.y + iz * step
			var hl := hs[iz * nx + maxi(ix - 1, 0)]
			var hr := hs[iz * nx + mini(ix + 1, nx - 1)]
			var hu := hs[maxi(iz - 1, 0) * nx + ix]
			var hd := hs[mini(iz + 1, nz - 1) * nx + ix]
			st.set_normal(Vector3(hl - hr, 2.0 * step, hu - hd).normalized())
			st.set_color(weights(x, z))
			st.add_vertex(Vector3(x, hs[iz * nx + ix], z))
	for iz in nz - 1:
		for ix in nx - 1:
			var cx := mn.x + (ix + 0.5) * step
			var cz := mn.y + (iz + 0.5) * step
			if hole.size.x > 0.0 and hole.has_point(Vector2(cx, cz)):
				continue
			if skip.size.x > 0.0 and skip.has_point(Vector2(cx, cz)):
				continue
			var a := iz * nx + ix
			st.add_index(a)
			st.add_index(a + 1)
			st.add_index(a + nx)
			st.add_index(a + 1)
			st.add_index(a + nx + 1)
			st.add_index(a + nx)
	return st.commit()


func build_collision(parent: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "Ground"
	parent.add_child(body)
	var t := 64
	for tz in 9:
		for tx in 9:
			var ox := -288.0 + tx * t
			var oz := -288.0 + tz * t
			var md := PackedFloat32Array()
			md.resize((t + 1) * (t + 1))
			for j in t + 1:
				for i in t + 1:
					md[j * (t + 1) + i] = h(ox + i, oz + j)
			var sh := HeightMapShape3D.new()
			sh.map_width = t + 1
			sh.map_depth = t + 1
			sh.map_data = md
			var cs := CollisionShape3D.new()
			cs.shape = sh
			cs.position = Vector3(ox + t * 0.5, 0.0, oz + t * 0.5)
			cs.set_meta("surface", "grass")
			body.add_child(cs)
