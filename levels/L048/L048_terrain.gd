extends RefCounted
## Level 48 terrain: one height function for meshes, collision and placement.
## East is +X along the beach; the lukewarm sea is south (+Z); the tropical
## forest begins 200 m north of the waterline (SOURCE) and runs north.
##   sea | waterline z~60 | beach to z~0 | dunes | promenade + hotels and
##   villas z -10..-150 | Veroka farm | forest edge z~-140 (200 m from the
##   water) | forest with a small lake, a farmhouse and a dirt trench north.
## The beach and sea continue in a coarse far mesh to the horizon haze; the far
## forest is a canopy band so the treeline never ends in a cut-off.

const WATERLINE := 60.0
const FOREST_Z := -140.0
const PROM_Y := 3.4
const LAKE := Vector2(118.0, -262.0)
const LAKE_R := 15.0
const LAKE_Y := 4.6
const LAKE_FLOOR := 0.6
const NEAR_MIN := Vector2(-280.0, -460.0)
const NEAR_MAX := Vector2(280.0, 170.0)
const NEAR_STEP := 2.0
const FAR_STEP := 32.0
const FAR_MIN := Vector2(-3200.0, -2600.0)
const FAR_MAX := Vector2(3200.0, 700.0)
const POOL := Rect2(-15.0, -26.0, 11.0, 9.0)   # hotel pool basin (x, z, w, d)
const PLANT_X := 250.0
const PLANT_Z := -440.0
## The dirt trench (SOURCE: followed long enough, it leads to Level 49).
const TRENCH := [Vector2(-40.0, -150.0), Vector2(-52.0, -200.0), Vector2(-74.0, -250.0), Vector2(-70.0, -300.0), Vector2(-92.0, -350.0), Vector2(-104.0, -410.0)]

var n_shore := FastNoiseLite.new()
var n_dune := FastNoiseLite.new()
var n_hill := FastNoiseLite.new()
var n_det := FastNoiseLite.new()


func _init() -> void:
	n_shore.seed = 4801
	n_shore.frequency = 0.008
	n_dune.seed = 4802
	n_dune.fractal_octaves = 3
	n_dune.frequency = 0.03
	n_hill.seed = 4803
	n_hill.fractal_octaves = 3
	n_hill.frequency = 0.01
	n_det.seed = 4804
	n_det.frequency = 0.06


func waterline(x: float) -> float:
	return WATERLINE + 5.0 * n_shore.get_noise_1d(x)


func trench_d(x: float, z: float) -> float:
	var best := INF
	for i in TRENCH.size() - 1:
		var a: Vector2 = TRENCH[i]
		var b: Vector2 = TRENCH[i + 1]
		var p := Vector2(x, z)
		var t := clampf((p - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
		best = minf(best, p.distance_to(a + (b - a) * t))
	return best


func h(x: float, z: float) -> float:
	var wl := waterline(x)
	var y: float
	if z > wl:
		y = -(z - wl) * 0.05 - maxf(0.0, z - wl - 60.0) * 0.05
		y = maxf(y, -14.0)
	elif z > 2.0:
		y = (wl - z) * 0.034
	else:
		# dunes behind the beach, then the level ground of the promenade strip
		var base := (wl - 2.0) * 0.034
		var dune := (0.9 + 0.8 * n_dune.get_noise_2d(x, z)) * sin(PI * clampf((2.0 - z) / 12.0, 0.0, 1.0)) * 1.4
		y = lerpf(base, PROM_Y, smoothstep(2.0, -6.0, z)) + dune * smoothstep(-14.0, -6.0, z)
		# inland the ground rises gently into forested hills
		y += smoothstep(-110.0, -260.0, z) * (3.0 + 4.0 * (0.5 + 0.5 * n_hill.get_noise_2d(x, z)))
		y += 0.35 * n_dune.get_noise_2d(x * 0.5, z * 0.5) * smoothstep(-20.0, -60.0, z)
	# the trench: a narrow dirt cut through the forest floor
	if z < -140.0 and z > -425.0:
		var td := trench_d(x, z)
		if td < 3.0:
			y -= 1.15 * (1.0 - smoothstep(1.1, 3.0, td))
	# the hotel pool basin
	if POOL.grow(0.6).has_point(Vector2(x, z)):
		y = PROM_Y - 1.9
	# the small lake (SOURCE: swim to its floor)
	var ld := Vector2(x - LAKE.x, z - LAKE.y).length()
	if ld < LAKE_R + 10.0:
		var bowl := lerpf(LAKE_FLOOR, LAKE_Y + 0.4, smoothstep(LAKE_R * 0.55, LAKE_R + 1.0, ld))
		var rim := lerpf(bowl, y, smoothstep(LAKE_R + 1.0, LAKE_R + 10.0, ld))
		y = minf(y, rim) if ld < LAKE_R + 1.0 else rim
	return y


func normal_at(x: float, z: float, e: float = 1.0) -> Vector3:
	return Vector3(h(x - e, z) - h(x + e, z), 2.0 * e, h(x, z - e) - h(x, z + e)).normalized()


func forest_w(x: float, z: float) -> float:
	return smoothstep(FOREST_Z + 12.0, FOREST_Z - 20.0, z)


## r: sand, g: forest floor, b: dirt (paths, trench, farm), a: wet.
func weights(x: float, z: float, y: float) -> Color:
	var sand := 1.0 - smoothstep(-8.0, -16.0, z)
	var forest := forest_w(x, z)
	var dirt := 0.0
	if z < -140.0 and z > -425.0:
		dirt = 1.0 - smoothstep(2.0, 4.0, trench_d(x, z))
	# Veroka farm plot and the path inland
	if x > 52.0 and x < 132.0 and z > -132.0 and z < -96.0:
		dirt = maxf(dirt, 0.8)
	if absf(x - 6.0 - 5.0 * sin(z * 0.04)) < 2.0 and z < -60.0 and z > -150.0:
		dirt = maxf(dirt, 0.9)
	var wet := smoothstep(0.6, 0.0, y) * sand
	return Color(sand, forest * (1.0 - sand), dirt, wet)


# ------------------------------------------------------------------ meshes

static func shader_code() -> String:
	return """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D grass_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 grass_tint = vec3(1.2, 1.35, 0.7);
uniform vec3 sand_tint = vec3(1.05, 0.92, 0.78);
uniform vec3 floor_tint = vec3(0.7, 0.75, 0.42);
uniform vec3 dirt_tint = vec3(0.75, 0.66, 0.55);
uniform float canopy = 0.0;
varying vec3 wpos;
varying vec4 wts;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wts = COLOR;
}
void fragment() {
	float macro = texture(grass_alb, wpos.xz / 167.0).g * 0.6 + texture(sand_alb, wpos.zx / 59.0).r * 0.4;
	vec2 uvs = wpos.xz / 3.0;
	vec3 sa = texture(sand_alb, uvs).rgb * sand_tint * (0.85 + 0.3 * macro);
	vec3 gr = mix(texture(grass_alb, wpos.xz / 3.2).rgb, texture(grass_alb, wpos.xz / 12.0 + 0.4).rgb, 0.4) * grass_tint * (0.75 + 0.5 * macro);
	vec3 fl = texture(dirt_alb, wpos.xz / 2.8).rgb * floor_tint;
	fl = mix(fl, gr * 0.6, 0.35 + 0.3 * macro);
	vec3 di = texture(dirt_alb, wpos.xz / 2.4).rgb * dirt_tint;
	float s = clamp(wts.r, 0.0, 1.0);
	float f = clamp(wts.g, 0.0, 1.0);
	float d = clamp(wts.b, 0.0, 1.0);
	vec3 alb = mix(gr, fl, f);
	alb = mix(alb, di, d);
	alb = mix(alb, sa, s);
	float wet = clamp(wts.a, 0.0, 1.0);
	alb *= mix(1.0, 0.6, wet);
	alb *= mix(1.0, 0.35, smoothstep(-0.3, -4.0, wpos.y));
	if (canopy > 0.5) {
		alb = mix(alb, vec3(0.035, 0.07, 0.03) * (0.7 + 0.6 * macro), f);
	}
	ALBEDO = alb;
	ROUGHNESS = mix(0.95, 0.35, wet);
	SPECULAR = 0.3 + wet * 0.3;
	NORMAL_MAP = mix(texture(sand_nrm, uvs).rgb, vec3(0.5, 0.5, 1.0), 1.0 - s * 0.8);
	NORMAL_MAP_DEPTH = 0.7;
}
"""


func make_material(canopy: bool = false) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = shader_code()
	var m := ShaderMaterial.new()
	m.shader = sh
	var sets := {"grass_alb": "sparse_grass/sparse_grass_diff_1k.jpg", "sand_alb": "coast_sand_01/coast_sand_01_diff_1k.jpg",
		"sand_nrm": "coast_sand_01/coast_sand_01_nor_gl_1k.jpg", "dirt_alb": "dirt_floor/dirt_floor_diff_1k.jpg"}
	for k in sets.keys():
		var p := "res://assets/external/" + str(sets[k])
		if ResourceLoader.exists(p):
			m.set_shader_parameter(k, load(p))
	m.set_shader_parameter("canopy", 1.0 if canopy else 0.0)
	return m


func build_meshes(parent: Node3D, mat: Material, far_mat: Material) -> void:
	var near := _grid_mesh(NEAR_MIN, NEAR_MAX, NEAR_STEP, Rect2(), false)
	var mi := MeshInstance3D.new()
	mi.name = "BeachTerrain"
	mi.mesh = near
	mi.material_override = mat
	parent.add_child(mi)
	var hole := Rect2(NEAR_MIN + Vector2(FAR_STEP, FAR_STEP), NEAR_MAX - NEAR_MIN - Vector2(FAR_STEP, FAR_STEP) * 2.0)
	var far := _grid_mesh(FAR_MIN, FAR_MAX, FAR_STEP, hole, true)
	var mf := MeshInstance3D.new()
	mf.name = "FarCoastAndCanopy"
	mf.mesh = far
	mf.material_override = far_mat
	mf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mf)


## In the far mesh, forested ground beyond the planted area is lifted into a
## lumpy canopy surface (dark green in the far material).
func far_h(x: float, z: float) -> float:
	var y := h(x, z)
	var f := forest_w(x, z)
	if f > 0.0 and (absf(x) > PLANT_X - 10.0 or z < PLANT_Z + 10.0):
		y += f * (15.0 + 5.0 * n_hill.get_noise_2d(x * 3.0, z * 3.0))
	return y


func _grid_mesh(mn: Vector2, mx: Vector2, step: float, hole: Rect2, far: bool) -> ArrayMesh:
	var nx := int(round((mx.x - mn.x) / step)) + 1
	var nz := int(round((mx.y - mn.y) / step)) + 1
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hs := PackedFloat32Array()
	hs.resize(nx * nz)
	for iz in nz:
		for ix in nx:
			var x := mn.x + ix * step
			var z := mn.y + iz * step
			var y := far_h(x, z) if far else h(x, z)
			if hole.size.x > 0.0 and hole.grow(step).has_point(Vector2(x, z)):
				y -= 0.8
			hs[iz * nx + ix] = y
	for iz in nz:
		for ix in nx:
			var x := mn.x + ix * step
			var z := mn.y + iz * step
			var y := hs[iz * nx + ix]
			var hl := hs[iz * nx + maxi(ix - 1, 0)]
			var hr := hs[iz * nx + mini(ix + 1, nx - 1)]
			var hu := hs[maxi(iz - 1, 0) * nx + ix]
			var hd := hs[mini(iz + 1, nz - 1) * nx + ix]
			st.set_normal(Vector3(hl - hr, 2.0 * step, hu - hd).normalized())
			st.set_color(weights(x, z, y))
			st.add_vertex(Vector3(x, y, z))
	for iz in nz - 1:
		for ix in nx - 1:
			if hole.size.x > 0.0:
				var cx := mn.x + (ix + 0.5) * step
				var cz := mn.y + (iz + 0.5) * step
				if hole.has_point(Vector2(cx, cz)):
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
	var x0 := -272.0
	var z0 := -456.0
	for tz in 10:
		for tx in 9:
			var ox := x0 + tx * t
			var oz := z0 + tz * t
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
			cs.set_meta("surface", "sand" if oz > -80.0 else "grass")
			body.add_child(cs)
