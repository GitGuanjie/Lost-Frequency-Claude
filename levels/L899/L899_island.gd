extends RefCounted
## Level 899 island: one height function shared by the render mesh, the
## HeightMapShape3D collision, the underside, the grass and the fence. The shape
## is authored (fixed); the seed moves only dressing. North is -Z.
##   meadow ~4 m, lake hollow (west), hall terrace 8.5 m behind a retaining wall
##   (north), lookout hill ~13 m (north-west), mushroom slope (east), the rock
##   outcrop with the way back (south).

const H0 := 4.0
const LAKE := Vector2(-22.0, 10.0)
const LAKE_R := Vector2(21.0, 13.0)
const WATER_Y := 3.35
const TERRACE := Rect2(6.0, -46.0, 32.0, 28.0)   # x 6..38, z -46..-18
const TERRACE_Y := 8.5
const LOOKOUT := Vector2(-50.0, -30.0)
const OUTCROP := Vector3(6.0, H0, 62.0)
const FENCE_D := 0.9
const PATHS := [
	[Vector2(6, 50), Vector2(10, 30), Vector2(18, 8), Vector2(22, -8)],
	[Vector2(10, 30), Vector2(-4, 22), Vector2(-14, -4), Vector2(-30, -16), Vector2(-46, -26)],
	[Vector2(18, 8), Vector2(36, 6), Vector2(52, 4)],
	[Vector2(-4, 22), Vector2(-24, 30), Vector2(-42, 22)],
	[Vector2(22, -46), Vector2(30, -52)],
]

var n_hill := FastNoiseLite.new()
var n_edge := FastNoiseLite.new()
var n_fine := FastNoiseLite.new()


func _init() -> void:
	n_hill.seed = 899
	n_hill.frequency = 0.018
	n_hill.fractal_octaves = 3
	n_edge.seed = 8991
	n_edge.frequency = 0.9
	n_fine.seed = 8992
	n_fine.frequency = 0.12


## Island radius at an angle (x stretched).
func radius_at(ang: float) -> float:
	return 76.0 + 9.0 * n_edge.get_noise_1d(ang * 2.0) + 5.0 * n_edge.get_noise_1d(ang * 7.0 + 40.0)


func d_of(x: float, z: float) -> float:
	var ax := x / 1.22
	return Vector2(ax, z).length() / radius_at(atan2(z, ax))


func path_w(x: float, z: float) -> float:
	var p := Vector2(x, z)
	var best := 99.0
	for pl in PATHS:
		for i in pl.size() - 1:
			var a: Vector2 = pl[i]
			var b: Vector2 = pl[i + 1]
			var t := clampf((p - a).dot(b - a) / (b - a).length_squared(), 0.0, 1.0)
			best = minf(best, p.distance_to(a + (b - a) * t))
	return 1.0 - smoothstep(0.9, 1.9, best)


func terrace_d(x: float, z: float) -> float:
	var dx := maxf(maxf(TERRACE.position.x - x, x - TERRACE.end.x), 0.0)
	var dz := maxf(TERRACE.position.y - z, 0.0)
	return Vector2(dx, dz).length()


func h(x: float, z: float) -> float:
	var y := H0 + 1.4 * n_hill.get_noise_2d(x, z) + 0.25 * n_fine.get_noise_2d(x, z)
	# a gentle rise to the east where the mushroom beds are
	y += 1.6 * smoothstep(30.0, 70.0, x) * (1.0 - smoothstep(20.0, 40.0, absf(z)))
	# lookout hill
	var lk := Vector2(x, z).distance_to(LOOKOUT)
	y += 9.0 * exp(-lk * lk / (2.0 * 17.0 * 17.0))
	# terrace: flat at TERRACE_Y; south face drops behind the retaining wall (z = -18)
	var inside_x := x >= TERRACE.position.x and x <= TERRACE.end.x
	if z <= TERRACE.end.y:
		var td := terrace_d(x, z)
		var w := 1.0 - smoothstep(0.0, 22.0, td)
		y = lerpf(y, TERRACE_Y, w)
	elif inside_x or (x > TERRACE.position.x - 22.0 and x < TERRACE.end.x + 22.0):
		var sx := 1.0 - smoothstep(0.0, 22.0, maxf(maxf(TERRACE.position.x - x, x - TERRACE.end.x), 0.0))
		var drop := 1.0 - smoothstep(TERRACE.end.y, TERRACE.end.y + 1.1, z)
		y = lerpf(y, TERRACE_Y, sx * drop)
	# lake hollow
	var q := Vector2((x - LAKE.x) / LAKE_R.x, (z - LAKE.y) / LAKE_R.y)
	var l2 := q.length_squared()
	if l2 < 1.6:
		var bowl := 1.0 - smoothstep(0.0, 1.25, l2)
		y = lerpf(y, H0 - 0.2, smoothstep(1.6, 1.0, l2))
		y -= 2.6 * bowl
	# flat pad for the outcrop
	var od := Vector2(x - OUTCROP.x, z - OUTCROP.z).length()
	y = lerpf(y, H0, 1.0 - smoothstep(10.0, 20.0, od))
	# path beds sink a little
	y -= 0.08 * path_w(x, z)
	# rounded lip at the rim, then away into the void
	var d := d_of(x, z)
	if d > 0.86:
		var e := smoothstep(0.86, 1.06, d)
		y -= e * e * 9.0
	if d > 1.06:
		y = -40.0
	return y


func normal_at(x: float, z: float, e := 1.0) -> Vector3:
	return Vector3(h(x - e, z) - h(x + e, z), 2.0 * e, h(x, z - e) - h(x, z + e)).normalized()


# ------------------------------------------------------------------ meshes

static func shader_code() -> String:
	return """
shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D grass_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 grass_tint = vec3(0.55, 0.8, 0.5);
varying vec3 wpos;
varying vec3 wnrm;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec2 uv = wpos.xz / 2.5;
	float macro = texture(grass_alb, wpos.xz / 61.0).g;
	vec3 g = texture(grass_alb, uv).rgb * grass_tint * (0.75 + 0.5 * macro);
	vec3 d = texture(dirt_alb, wpos.xz / 2.0).rgb * vec3(0.8, 0.72, 0.62);
	vec3 bw = pow(abs(wnrm), vec3(4.0));
	bw /= (bw.x + bw.y + bw.z);
	vec3 r = (texture(rock_alb, wpos.zy / 9.0).rgb * bw.x + texture(rock_alb, wpos.xz / 9.0).rgb * bw.y + texture(rock_alb, wpos.xy / 9.0).rgb * bw.z) * vec3(0.55, 0.53, 0.56);
	float rock = clamp(COLOR.r, 0.0, 1.0);
	float path = clamp(COLOR.g, 0.0, 1.0);
	vec3 alb = mix(mix(g, d, path), r, rock);
	ALBEDO = alb;
	ROUGHNESS = mix(0.95, 0.85, rock);
	NORMAL_MAP = mix(texture(grass_nrm, uv).rgb, vec3(0.5, 0.5, 1.0), rock);
	NORMAL_MAP_DEPTH = 0.7;
}
"""


func make_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = shader_code()
	var m := ShaderMaterial.new()
	m.shader = sh
	var tex := {"grass_alb": "res://assets/external/sparse_grass/sparse_grass_diff_1k.jpg", "grass_nrm": "res://assets/external/sparse_grass/sparse_grass_nor_gl_1k.jpg",
		"dirt_alb": "res://assets/external/dirt_floor/dirt_floor_diff_1k.jpg", "rock_alb": "res://assets/external/aerial_rocks_02/aerial_rocks_02_diff_1k.jpg"}
	for k in tex.keys():
		if ResourceLoader.exists(tex[k]):
			m.set_shader_parameter(k, load(tex[k]))
	return m


## Top surface: 1.5 m grid over the island's bounding box; cells wholly in the
## void are skipped. Vertex colour R = rock weight, G = path weight.
func build_top(parent: Node3D, mat: Material) -> void:
	var step := 1.5
	var mn := Vector2(-104.0, -92.0)
	var nx := int(208.0 / step) + 1
	var nz := int(184.0 / step) + 1
	var hs := PackedFloat32Array()
	hs.resize(nx * nz)
	for iz in nz:
		for ix in nx:
			hs[iz * nx + ix] = h(mn.x + ix * step, mn.y + iz * step)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
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
			var rock := maxf(smoothstep(0.8, 0.55, nrm.y), smoothstep(0.93, 1.03, d_of(x, z)))
			st.set_normal(nrm)
			st.set_color(Color(rock, path_w(x, z) * (1.0 - rock), 0))
			st.add_vertex(Vector3(x, y, z))
	for iz in nz - 1:
		for ix in nx - 1:
			var a := iz * nx + ix
			if hs[a] < -39.0 and hs[a + 1] < -39.0 and hs[a + nx] < -39.0 and hs[a + nx + 1] < -39.0:
				continue
			if hs[a] < -39.0 or hs[a + 1] < -39.0 or hs[a + nx] < -39.0 or hs[a + nx + 1] < -39.0:
				continue
			st.add_index(a)
			st.add_index(a + 1)
			st.add_index(a + nx)
			st.add_index(a + 1)
			st.add_index(a + nx + 1)
			st.add_index(a + nx)
	var mi := MeshInstance3D.new()
	mi.name = "IslandTop"
	mi.mesh = st.commit()
	mi.material_override = mat
	parent.add_child(mi)


## The rock that hangs under the island into the void.
func build_underside(parent: Node3D, mat: Material) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segs := 96
	var rings := 12
	for j in rings + 1:
		var t := float(j) / rings
		for i in segs + 1:
			var ang := TAU * float(i % segs) / segs
			var r0 := radius_at(atan2(sin(ang), cos(ang)))
			var shrink := pow(1.0 - t, 1.25) * (1.0 + 0.12 * n_edge.get_noise_2d(i * 0.7, j * 2.1) * minf(1.0, t * 4.0))
			var rr := r0 * 1.055 * maxf(shrink, 0.0)
			var y := -5.0 - 95.0 * pow(t, 0.85) + 4.0 * n_edge.get_noise_2d(i * 1.3 + 50.0, j * 1.7)
			if j == 0:
				y = h(cos(ang) * r0 * 1.055 * 1.22, sin(ang) * r0 * 1.055) - 0.5
			var p := Vector3(cos(ang) * rr * 1.22, y, sin(ang) * rr)
			st.set_color(Color(1, 0, 0))
			st.set_normal(Vector3(cos(ang), 0.3 - t, sin(ang)).normalized())
			st.add_vertex(p)
	for j in rings:
		for i in segs:
			var a := j * (segs + 1) + i
			var b := a + segs + 1
			st.add_index(a)
			st.add_index(b)
			st.add_index(a + 1)
			st.add_index(a + 1)
			st.add_index(b)
			st.add_index(b + 1)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "IslandUnderside"
	mi.mesh = st.commit()
	mi.material_override = mat
	parent.add_child(mi)


## HeightMapShape3D tiles (1 m) over the island.
func build_collision(parent: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "IslandGround"
	parent.add_child(body)
	var t := 52
	for tz in 4:
		for tx in 5:
			var ox := -104.0 + tx * t
			var oz := -92.0 + tz * t
			var md := PackedFloat32Array()
			md.resize((t + 1) * (t + 1))
			var hi := -INF
			for j in t + 1:
				for i in t + 1:
					var y := h(ox + i, oz + j)
					md[j * (t + 1) + i] = y
					hi = maxf(hi, y)
			if hi < -30.0:
				continue
			var sh := HeightMapShape3D.new()
			sh.map_width = t + 1
			sh.map_depth = t + 1
			sh.map_data = md
			var cs := CollisionShape3D.new()
			cs.shape = sh
			cs.position = Vector3(ox + t * 0.5, 0.0, oz + t * 0.5)
			cs.set_meta("surface", "grass")
			body.add_child(cs)


## Grass tufts as one instanced mesh of crossed blades, swaying.
func build_grass(parent: Node3D, rng: RandomNumberGenerator, count: int) -> void:
	var brng := RandomNumberGenerator.new()
	brng.seed = 8990
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 9:
		var a := brng.randf() * TAU
		var off := Vector3(brng.randf_range(-0.09, 0.09), 0, brng.randf_range(-0.09, 0.09))
		var side := Vector3(cos(a), 0, sin(a)) * brng.randf_range(0.012, 0.022)
		var hgt := brng.randf_range(0.16, 0.36)
		var lean := Vector3(brng.randf_range(-0.08, 0.08), 0, brng.randf_range(-0.08, 0.08))
		var tip := off + lean + Vector3(0, hgt, 0)
		var shade := brng.randf()
		for v in [[off - side, 0.0], [off + side, 0.0], [tip, 1.0]]:
			st.set_color(Color(v[1], shade, 0))
			st.set_normal(Vector3.UP)
			st.add_vertex(v[0])
	var blade := st.commit()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = blade
	var pts: Array = []
	var tries := 0
	while pts.size() < count and tries < count * 4:
		tries += 1
		var x := rng.randf_range(-95.0, 95.0)
		var z := rng.randf_range(-80.0, 80.0)
		if d_of(x, z) > FENCE_D - 0.01 or path_w(x, z) > 0.2:
			continue
		var y := h(x, z)
		if y < WATER_Y + 0.15 or (z < TERRACE.end.y + 0.5 and terrace_d(x, z) < 0.5 and x > TERRACE.position.x and x < TERRACE.end.x):
			continue
		if Vector2(x - OUTCROP.x, z - OUTCROP.z).length() < 9.0:
			continue
		pts.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * rng.randf_range(0.8, 1.6)), Vector3(x, y - 0.02, z)))
	mm.instance_count = pts.size()
	for i in pts.size():
		mm.set_instance_transform(i, pts[i])
	var mi := MultiMeshInstance3D.new()
	mi.name = "Grass"
	mi.multimesh = mm
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode cull_disabled, diffuse_burley;
void vertex() {
	vec3 w = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	VERTEX.x += COLOR.r * 0.08 * sin(TIME * 1.3 + w.x * 0.3 + w.z * 0.2);
	VERTEX.z += COLOR.r * 0.05 * cos(TIME * 1.1 + w.z * 0.25);
}
void fragment() {
	vec3 tipc = mix(vec3(0.16, 0.3, 0.1), vec3(0.3, 0.36, 0.14), COLOR.g);
	ALBEDO = mix(vec3(0.03, 0.07, 0.025), tipc, COLOR.r);
	ROUGHNESS = 0.9;
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visibility_range_end = 70.0
	parent.add_child(mi)


## Points on the fence ring, every ~2.4 m.
func fence_points() -> Array:
	var out: Array = []
	var n := 220
	for i in n:
		var ang := TAU * float(i) / n
		var r := radius_at(atan2(sin(ang), cos(ang))) * FENCE_D
		var x := cos(ang) * r * 1.22
		var z := sin(ang) * r
		out.append(Vector3(x, h(x, z), z))
	return out
