extends RefCounted
## Level 994 terrain: one height function shared by the render meshes, the
## HeightMapShape3D collision tiles and the prop placement. The macro shape
## (bay, mountains, gorge, north sand cliff) is fixed; level_seed only moves
## dressing. East is +X (the sea), north is -Z.

const SEA_X := 40.0          # shoreline at mean sea level (y = 0)
const BEACH_SLOPE := 0.026   # 2.6 % rise towards the mountains
const GATE := Vector3(-143.0, 7.6, 0.0)
const GORGE_FLOOR := 7.6
const NEAR_MIN := Vector2(-176.0, -372.0)
const NEAR_MAX := Vector2(140.0, 372.0)
const NEAR_STEP := 2.0
const FAR_STEP := 24.0
const FAR_MIN := Vector2(-1400.0, -1600.0)
const FAR_MAX := Vector2(900.0, 1600.0)

var n_foot := FastNoiseLite.new()
var n_ridge := FastNoiseLite.new()
var n_sand := FastNoiseLite.new()
var n_shore := FastNoiseLite.new()


func _init() -> void:
	n_foot.seed = 994
	n_foot.frequency = 0.006
	n_ridge.seed = 9941
	n_ridge.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n_ridge.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	n_ridge.fractal_octaves = 4
	n_ridge.frequency = 0.004
	n_sand.seed = 9942
	n_sand.fractal_octaves = 3
	n_sand.frequency = 0.03
	n_shore.seed = 9943
	n_shore.frequency = 0.012


## Mountain "inside" distance (> 0 = inside the rock mass, metres).
func mountain_d(x: float, z: float) -> float:
	var foot := -114.0 + 12.0 * n_foot.get_noise_1d(z) + 7.0 * n_foot.get_noise_1d(z * 4.3 + 300.0) + 0.00004 * z * z
	var d_w := foot - x
	# north and south arms close the bay and run out into the sea as headlands
	var coast := 300.0 + 22.0 * n_foot.get_noise_1d(x + 777.0) + maxf(0.0, x - SEA_X) * 0.55
	var d_ns := absf(z) - coast
	return maxf(d_w, d_ns)


func sand_cliff_w(x: float, z: float) -> float:
	# The north end is a cliff of nothing but sand (audio log, TESTIMONY).
	if z > -250.0:
		return 0.0
	return smoothstep(-250.0, -275.0, z) * (1.0 - smoothstep(10.0, 60.0, x))


func h(x: float, z: float) -> float:
	var sx := SEA_X + 7.0 * n_shore.get_noise_1d(z)
	var base: float
	if x < sx:
		base = (sx - x) * BEACH_SLOPE
	else:
		base = -16.0 * (1.0 - exp(-(x - sx) / 55.0))
	# soft dunes and ripples on the upper beach, fading into the wet band
	var dune := n_sand.get_noise_2d(x, z) * 0.55 * smoothstep(sx - 10.0, sx - 70.0, x)
	base += dune
	# north sand cliff: a 13 m sand step before the rock begins
	var sc := sand_cliff_w(x, z)
	if sc > 0.0:
		var step := smoothstep(-282.0, -296.0, z) * 13.0
		base += step * sc
	var m := mountain_d(x, z)
	if m > -9.0:
		# talus apron (walkable), then the rock face and ridged peaks behind it
		var fade := 1.0 - smoothstep(SEA_X + 120.0, SEA_X + 620.0, x)
		var mm := maxf(m, 0.0)
		var apron := pow(minf(m + 9.0, 9.0), 2.0) * 0.028
		var ridge := 0.5 + 0.5 * n_ridge.get_noise_2d(x, z)
		var spur := 0.5 + 0.5 * n_ridge.get_noise_2d(x * 3.7 + 900.0, z * 3.7)
		var rise := 120.0 * (1.0 - exp(-mm / 60.0)) + 0.22 * mm + ridge * 190.0 * smoothstep(4.0, 140.0, mm) + spur * 55.0 * smoothstep(2.0, 40.0, mm)
		rise += 6.0 * n_sand.get_noise_2d(x * 3.1, z * 3.1) * smoothstep(0.0, 6.0, mm)
		rise = (rise + apron) * maxf(fade, 0.04)
		if sc > 0.0:
			rise *= smoothstep(-300.0, -330.0, z) * 0.9 + 0.1
		base += rise
	# the gorge in the west mountain that holds the iron gate: a V-shaped pass
	# whose floor climbs to the gate ledge; the back wall closes it at x = -147
	if x > -270.0 and x < -88.0 and absf(z) < 150.0:
		var floor_y := lerpf(3.9, GORGE_FLOOR, smoothstep(-108.0, -136.0, x))
		var half := lerpf(4.0, 13.0, smoothstep(-128.0, -98.0, x))
		var wall := maxf(0.0, absf(z) - half)
		var cap := floor_y + wall * 1.25 + wall * wall * 0.012 + maxf(0.0, -147.0 - x) * 2.8
		cap += 2.5 * n_sand.get_noise_2d(x * 2.0, z * 2.0) * smoothstep(0.0, 4.0, wall)
		if base > cap:
			base = cap
	return base


func normal_at(x: float, z: float, e: float = 1.0) -> Vector3:
	return Vector3(h(x - e, z) - h(x + e, z), 2.0 * e, h(x, z - e) - h(x, z + e)).normalized()


## 0 = sand, 1 = rock. Steep mountain faces are rock; the north cliff stays sand.
func rock_w(x: float, z: float, nrm: Vector3) -> float:
	var steep := smoothstep(0.86, 0.6, nrm.y)
	var inside := smoothstep(-1.0, 3.0, mountain_d(x, z))
	var r := maxf(steep, inside)
	r *= 1.0 - sand_cliff_w(x, z) * smoothstep(-300.0, -284.0, z)
	return clampf(r, 0.0, 1.0)


# ------------------------------------------------------------------ meshes

static func shader_code() -> String:
	return """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D sand_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 sand_tint = vec3(0.92, 0.9, 0.86);
uniform vec3 rock_tint = vec3(0.62, 0.62, 0.63);
uniform float sand_rep = 3.0;
uniform float rock_rep = 11.0;
uniform float water_y = 0.0;
uniform float wet_top = 0.6;
varying vec3 wpos;
varying vec3 wnrm;
vec3 tri(vec3 p, vec3 bw) {
	return texture(rock_alb, p.zy).rgb * bw.x + texture(rock_alb, p.xz).rgb * bw.y + texture(rock_alb, p.xy).rgb * bw.z;
}
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec2 uvs = wpos.xz / sand_rep;
	float macro = texture(sand_alb, wpos.xz / 131.0).r * 0.6 + texture(sand_alb, wpos.zx / 47.0).g * 0.4;
	vec3 sa = texture(sand_alb, uvs).rgb * sand_tint * (0.82 + 0.36 * macro);
	vec3 bw = pow(abs(wnrm), vec3(4.0));
	bw /= (bw.x + bw.y + bw.z);
	vec3 ra = tri(wpos / rock_rep, bw) * 0.55 + tri(wpos / (rock_rep * 4.7) + vec3(0.37), bw) * 0.45;
	ra = mix(ra, vec3(dot(ra, vec3(0.33))), 0.35);
	ra *= rock_tint * (0.8 + 0.4 * macro);
	float r = clamp(COLOR.r, 0.0, 1.0);
	float wet = smoothstep(wet_top, wet_top - 0.9, wpos.y) * (1.0 - r);
	float sheen = smoothstep(water_y + 0.35, water_y + 0.02, wpos.y) * (1.0 - r);
	vec3 alb = mix(sa, ra, r);
	alb *= mix(1.0, 0.58, wet);
	ALBEDO = alb;
	ROUGHNESS = mix(mix(0.94, 0.82, r), 0.22, max(wet * 0.6, sheen));
	SPECULAR = 0.4 + sheen * 0.3;
	NORMAL_MAP = mix(texture(sand_nrm, uvs).rgb, vec3(0.5, 0.5, 1.0), clamp(r + sheen * 0.7, 0.0, 1.0));
	NORMAL_MAP_DEPTH = 0.8;
}
"""


func make_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = shader_code()
	var m := ShaderMaterial.new()
	m.shader = sh
	var sa := "res://assets/external/coast_sand_01/coast_sand_01_%s_1k.jpg"
	var ra := "res://assets/external/aerial_rocks_02/aerial_rocks_02_%s_1k.jpg"
	if ResourceLoader.exists(sa % "diff"):
		m.set_shader_parameter("sand_alb", load(sa % "diff"))
		m.set_shader_parameter("sand_nrm", load(sa % "nor_gl"))
	if ResourceLoader.exists(ra % "diff"):
		m.set_shader_parameter("rock_alb", load(ra % "diff"))
	return m


## Fine near mesh (the bay) as one surface; far ring at coarse spacing.
func build_meshes(parent: Node3D, mat: Material) -> Dictionary:
	var stats := {"tris": 0}
	var near := _grid_mesh(NEAR_MIN, NEAR_MAX, NEAR_STEP, Rect2())
	var mi := MeshInstance3D.new()
	mi.name = "BayTerrain"
	mi.mesh = near
	mi.material_override = mat
	parent.add_child(mi)
	var far := _grid_mesh(FAR_MIN, FAR_MAX, FAR_STEP, Rect2(NEAR_MIN + Vector2(FAR_STEP, FAR_STEP), NEAR_MAX - NEAR_MIN - Vector2(FAR_STEP, FAR_STEP) * 2.0))
	var mf := MeshInstance3D.new()
	mf.name = "MountainRing"
	mf.mesh = far
	mf.material_override = mat
	mf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mf)
	return stats


func _grid_mesh(mn: Vector2, mx: Vector2, step: float, hole: Rect2) -> ArrayMesh:
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
			var y := h(x, z)
			# the far ring sinks a little under the near mesh where they overlap
			if hole.size.x > 0.0 and hole.grow(step).has_point(Vector2(x, z)):
				y -= 0.6
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
			var nrm := Vector3(hl - hr, 2.0 * step, hu - hd).normalized()
			st.set_normal(nrm)
			st.set_uv(Vector2(x, z))
			st.set_color(Color(rock_w(x, z, nrm), 0, 0))
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
	st.generate_tangents()
	return st.commit()


## 1 m HeightMapShape3D tiles over the reachable bay. Tiles that sit wholly
## inside the mountains are skipped; the steep faces around them are walls.
func build_collision(parent: Node3D) -> int:
	var body := StaticBody3D.new()
	body.name = "BayGround"
	parent.add_child(body)
	var count := 0
	var t := 64
	var x0 := -168.0
	var z0 := -340.0
	for tz in 11:
		for tx in 5:
			var ox := x0 + tx * t
			var oz := z0 + tz * t
			var md := PackedFloat32Array()
			md.resize((t + 1) * (t + 1))
			var lo := INF
			for j in t + 1:
				for i in t + 1:
					var y := h(ox + i, oz + j)
					md[j * (t + 1) + i] = y
					lo = minf(lo, y)
			if lo > 40.0:
				continue
			var sh := HeightMapShape3D.new()
			sh.map_width = t + 1
			sh.map_depth = t + 1
			sh.map_data = md
			var cs := CollisionShape3D.new()
			cs.shape = sh
			cs.position = Vector3(ox + t * 0.5, 0.0, oz + t * 0.5)
			cs.set_meta("surface", "sand")
			body.add_child(cs)
			count += 1
	return count
