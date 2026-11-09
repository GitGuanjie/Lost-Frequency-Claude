extends RefCounted
## Level 29 terrain: one height function shared by the render meshes, the
## HeightMapShape3D collision tiles and all placement. East is +X, the open
## sea (the "outer areas") is south (+Z), the mountain-protected inner basin
## (the "inner circle") is north (-Z). The macro shape is authored; level_seed
## only moves dressing.
##
##   sea y 0 | cliff coast z~100 | cove + dockyard x~0, z 60-118 | gully road
##   up to the outer-circle plateau (y~14) | south mountain arm with a pass |
##   inner basin (y~20) with Hyperia, farms, an Almond Water river and lake,
##   ringed by high mountains | flank ranges east and west.

const SEA_Y := 0.0
const BASIN := Vector2(0.0, -250.0)     # basin centre (x, z)
const BASIN_R := Vector2(190.0, 130.0)  # ellipse radii
const PLATEAU_Y := 14.0
const BASIN_Y := 20.0
const LAKE := Vector2(78.0, -262.0)
const LAKE_R := 30.0
const RIVER_X := 74.0
const RIVER_Z0 := -372.0                 # waterfall foot
const WATER_Y := 18.7                    # river + lake level (Almond Water)
const NEAR_MIN := Vector2(-250.0, -430.0)
const NEAR_MAX := Vector2(250.0, 170.0)
const NEAR_STEP := 2.0
const FAR_STEP := 32.0
const FAR_MIN := Vector2(-1700.0, -1900.0)
const FAR_MAX := Vector2(1700.0, 1400.0)

## Farm fields in the inner circle: [centre x, centre z, half x, half z, crop]
const FIELDS := [
	[-70.0, -205.0, 26.0, 18.0, 0], [-122.0, -212.0, 20.0, 24.0, 1], [-78.0, -255.0, 30.0, 16.0, 2],
	[-128.0, -268.0, 18.0, 22.0, 0], [-60.0, -300.0, 26.0, 18.0, 1], [-112.0, -318.0, 22.0, 14.0, 2],
	[30.0, -318.0, 22.0, 16.0, 0], [128.0, -214.0, 22.0, 18.0, 1], [140.0, -300.0, 18.0, 24.0, 2],
]
const TOWN := Vector3(0.0, 20.0, -205.0)   # Hyperia plaza centre

var n_coast := FastNoiseLite.new()
var n_hill := FastNoiseLite.new()
var n_ridge := FastNoiseLite.new()
var n_det := FastNoiseLite.new()


func _init() -> void:
	n_coast.seed = 2901
	n_coast.frequency = 0.01
	n_hill.seed = 2902
	n_hill.fractal_octaves = 3
	n_hill.frequency = 0.012
	n_ridge.seed = 2903
	n_ridge.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n_ridge.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	n_ridge.fractal_octaves = 4
	n_ridge.frequency = 0.0045
	n_det.seed = 2904
	n_det.fractal_octaves = 3
	n_det.frequency = 0.05


func coast_z(x: float) -> float:
	return 100.0 + 9.0 * n_coast.get_noise_1d(x) + 4.0 * n_coast.get_noise_1d(x * 5.0 + 90.0)


func road_x(z: float) -> float:
	# the main road: dock gully -> plateau -> pass -> Hyperia
	return 5.0 * sin(z * 0.021) * smoothstep(40.0, -20.0, z) * smoothstep(-200.0, -150.0, z)


## Distance (m, approx.) outside the basin ellipse; < 0 inside.
func basin_d(x: float, z: float) -> float:
	var e := Vector2((x - BASIN.x) / BASIN_R.x, (z - BASIN.y) / BASIN_R.y).length()
	return (e - 1.0) * BASIN_R.y


## Mountain height added on top of the lowland (>= 0).
func mountain(x: float, z: float) -> float:
	var d := basin_d(x, z)
	var south := smoothstep(-215.0, -140.0, z)
	var ridge := 0.5 + 0.5 * n_ridge.get_noise_2d(x, z)
	var spur := 0.5 + 0.5 * n_ridge.get_noise_2d(x * 3.3 + 700.0, z * 3.3)
	var m := 0.0
	if d > -6.0:
		var dd := maxf(d, 0.0)
		var north := 150.0 * (1.0 - exp(-dd / 55.0)) + 0.25 * dd + ridge * 170.0 * smoothstep(6.0, 140.0, dd) + spur * 40.0 * smoothstep(2.0, 30.0, dd)
		var arm := (46.0 + ridge * 34.0 + spur * 16.0) * sin(PI * clampf(dd / 86.0, 0.0, 1.0)) * smoothstep(0.0, 14.0, dd)
		m = lerpf(north, arm, south)
		m += pow(clampf((d + 6.0) / 6.0, 0.0, 1.0), 2.0) * 1.5 * (1.0 - south)
	# flank ranges east and west of the outer circle and running into the sea
	var fx := absf(x) - (205.0 + 14.0 * n_coast.get_noise_1d(z + 400.0))
	if fx > -4.0:
		var fd := maxf(fx, 0.0)
		var flank := 120.0 * (1.0 - exp(-fd / 45.0)) + ridge * 130.0 * smoothstep(4.0, 120.0, fd) + spur * 30.0 * smoothstep(2.0, 24.0, fd)
		m = maxf(m, flank)
	# the pass through the south arm (road), widening into the basin
	var pz := smoothstep(-150.0, -40.0, z) * smoothstep(-20.0, -60.0, z)
	if pz > 0.0:
		var px := absf(x - road_x(z))
		var cap := maxf(0.0, px - 14.0) * 1.15 + maxf(0.0, px - 30.0) * 0.6
		m = lerpf(m, minf(m, cap), pz)
	return m


func lowland(x: float, z: float) -> float:
	var y := lerpf(PLATEAU_Y, BASIN_Y, smoothstep(-70.0, -150.0, z))
	var hill := n_hill.get_noise_2d(x, z)
	y += hill * lerpf(2.6, 0.9, smoothstep(-70.0, -150.0, z))
	# keep the town plaza and the road nearly level
	var rd := absf(x - road_x(z))
	y = lerpf(y, lerpf(PLATEAU_Y, BASIN_Y, smoothstep(-70.0, -150.0, z)) + hill * 0.6, 1.0 - smoothstep(4.0, 14.0, rd))
	var td := Vector2(x - TOWN.x, z - TOWN.z).length()
	y = lerpf(TOWN.y, y, smoothstep(34.0, 64.0, td))
	return y


func cove_floor(z: float) -> float:
	if z < 58.0:
		return lerpf(PLATEAU_Y, 1.45, smoothstep(-14.0, 58.0, z))
	return 1.45 - (z - 58.0) * 0.12 - maxf(0.0, z - 76.0) * 0.12


func cove_half(z: float) -> float:
	return lerpf(10.0, 44.0, smoothstep(-12.0, 62.0, z)) + maxf(0.0, z - 62.0) * 0.6


func h(x: float, z: float) -> float:
	var y := lowland(x, z) + mountain(x, z)
	# rough cliffs down to the sea
	var cz := coast_z(x)
	if z > cz - 2.0:
		var t := z - cz
		var sea_floor := -7.0 - 0.06 * maxf(t, 0.0) - 2.0 * n_det.get_noise_2d(x, z)
		var ledge := 1.5 * n_det.get_noise_2d(x * 0.7, z * 2.0)
		y = lerpf(y + ledge * smoothstep(-2.0, 2.0, t), sea_floor, smoothstep(-1.0, 9.0, t))
	# the cove: the gully road falls from the plateau to the dockyard beach
	if z > -30.0:
		var half := cove_half(z)
		var w := maxf(0.0, absf(x - road_x(z)) - half)
		var cap := cove_floor(z) + w * 2.6 + w * w * 0.02 + 1.2 * n_det.get_noise_2d(x * 1.5, z * 1.5) * smoothstep(0.0, 3.0, w)
		if y > cap:
			y = cap
	# Almond Water: the river from the north waterfall and the lake it feeds
	var rv := absf(x - (RIVER_X + 6.0 * sin(z * 0.03))) - 4.0
	if z > RIVER_Z0 - 8.0 and z < LAKE.y and rv < 6.0:
		var bed := WATER_Y - 1.8 + maxf(0.0, rv) * 0.5
		bed = lerpf(y, bed, smoothstep(RIVER_Z0 - 8.0, RIVER_Z0 + 4.0, z))
		y = minf(y, bed)
	var ld := Vector2(x - LAKE.x, z - LAKE.y).length() - LAKE_R
	if ld < 12.0:
		y = minf(y, WATER_Y - 2.4 + maxf(0.0, ld) * 0.4 + maxf(0.0, ld + 8.0) * 0.08)
	return y


func normal_at(x: float, z: float, e: float = 1.0) -> Vector3:
	return Vector3(h(x - e, z) - h(x + e, z), 2.0 * e, h(x, z - e) - h(x, z + e)).normalized()


func in_field(x: float, z: float, margin: float = 0.0) -> int:
	for i in FIELDS.size():
		var f: Array = FIELDS[i]
		if absf(x - f[0]) < f[2] + margin and absf(z - f[1]) < f[3] + margin:
			return i
	return -1


## Vertex colour weights: r rock, g sand, b dirt (roads and fields), a metal.
func weights(x: float, z: float, y: float, nrm: Vector3) -> Color:
	var steep := smoothstep(0.84, 0.6, nrm.y)
	var high := smoothstep(30.0, 70.0, y - lowland(x, z) * 0.0) * smoothstep(0.95, 0.8, nrm.y)
	var r := clampf(maxf(steep, high * 0.8), 0.0, 1.0)
	var sand := 0.0
	if z > 38.0 and y < 4.5:
		sand = smoothstep(4.5, 2.6, y)
	if y < 0.4:
		sand = 1.0
	var dirt := 0.0
	var rd := absf(x - road_x(z))
	if z < 64.0 and z > -190.0:
		dirt = 1.0 - smoothstep(2.4, 3.6, rd)
	var td := Vector2(x - TOWN.x, z - TOWN.z).length()
	dirt = maxf(dirt, 1.0 - smoothstep(18.0, 30.0, td + 9.0 * n_det.get_noise_2d(x * 0.5, z * 0.5)))
	if in_field(x, z, 1.0) >= 0:
		dirt = maxf(dirt, 0.85)
	dirt *= 1.0 - r
	# rock-and-metal: rusted metal seams in the coastal cliffs and high rock
	var metal := 0.0
	if r > 0.3:
		metal = smoothstep(0.35, 0.75, n_det.get_noise_2d(x * 0.18, y * 0.9 + z * 0.1) * 0.5 + 0.5) * r
		metal *= 0.45 + 0.55 * smoothstep(60.0, 100.0, z)
	return Color(r, sand * (1.0 - r), dirt, metal)


# ------------------------------------------------------------------ meshes

static func shader_code() -> String:
	return """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform sampler2D grass_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D sand_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D metal_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 grass_tint = vec3(1.45, 1.65, 0.9);
uniform vec3 sand_tint = vec3(0.95, 0.86, 0.80);
uniform vec3 rock_tint = vec3(0.66, 0.60, 0.62);
uniform vec3 dirt_tint = vec3(0.64, 0.63, 0.6);
varying vec3 wpos;
varying vec3 wnrm;
varying vec4 wts;
vec3 tri(sampler2D t, vec3 p, vec3 bw) {
	return texture(t, p.zy).rgb * bw.x + texture(t, p.xz).rgb * bw.y + texture(t, p.xy).rgb * bw.z;
}
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	wts = COLOR;
}
void fragment() {
	float macro = texture(grass_alb, wpos.xz / 173.0).g * 0.6 + texture(sand_alb, wpos.zx / 61.0).r * 0.4;
	vec3 gr = texture(grass_alb, wpos.xz / 3.2).rgb * grass_tint * (0.75 + 0.5 * macro);
	vec3 gr2 = texture(grass_alb, wpos.xz / 11.0 + 0.3).rgb * grass_tint;
	gr = mix(gr, gr2, 0.35);
	vec3 sa = texture(sand_alb, wpos.xz / 3.0).rgb * sand_tint;
	vec3 di = texture(dirt_alb, wpos.xz / 2.6).rgb * dirt_tint * (0.85 + 0.3 * macro);
	vec3 bw = pow(abs(wnrm), vec3(4.0));
	bw /= (bw.x + bw.y + bw.z);
	vec3 ra = tri(rock_alb, wpos / 10.0, bw) * 0.55 + tri(rock_alb, wpos / 41.0 + vec3(0.37), bw) * 0.45;
	ra *= rock_tint * (0.8 + 0.4 * macro);
	vec3 me = tri(metal_alb, wpos / 6.0, bw) * vec3(0.95, 0.72, 0.62);
	float r = clamp(wts.r, 0.0, 1.0);
	float s = clamp(wts.g, 0.0, 1.0);
	float d = clamp(wts.b, 0.0, 1.0);
	float m = clamp(wts.a, 0.0, 1.0);
	vec3 alb = gr;
	alb = mix(alb, di, smoothstep(0.2, 0.8, d + (macro - 0.5) * 0.4));
	alb = mix(alb, sa, s);
	alb = mix(alb, ra, r);
	alb = mix(alb, me, m);
	float wet = smoothstep(0.5, -0.1, wpos.y) * s;
	alb *= mix(1.0, 0.62, wet);
	alb *= mix(1.0, 0.3, smoothstep(-0.3, -3.0, wpos.y));
	ALBEDO = alb;
	ROUGHNESS = mix(mix(0.93, 0.8, r), 0.45, m) - wet * 0.4;
	METALLIC = m * 0.45;
	SPECULAR = 0.35 + wet * 0.2;
}
"""


func make_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = shader_code()
	var m := ShaderMaterial.new()
	m.shader = sh
	var sets := {"grass_alb": "sparse_grass", "sand_alb": "coast_sand_01", "rock_alb": "aerial_rocks_02",
		"dirt_alb": "dirt_floor", "metal_alb": "rusty_metal"}
	for k in sets.keys():
		var p := "res://assets/external/%s/%s_diff_1k.jpg" % [sets[k], sets[k]]
		if ResourceLoader.exists(p):
			m.set_shader_parameter(k, load(p))
	return m


func build_meshes(parent: Node3D, mat: Material) -> int:
	var near := _grid_mesh(NEAR_MIN, NEAR_MAX, NEAR_STEP, Rect2())
	var mi := MeshInstance3D.new()
	mi.name = "IslandTerrain"
	mi.mesh = near
	mi.material_override = mat
	parent.add_child(mi)
	var hole := Rect2(NEAR_MIN + Vector2(FAR_STEP, FAR_STEP), NEAR_MAX - NEAR_MIN - Vector2(FAR_STEP, FAR_STEP) * 2.0)
	var far := _grid_mesh(FAR_MIN, FAR_MAX, FAR_STEP, hole)
	var mf := MeshInstance3D.new()
	mf.name = "MountainsAndCoast"
	mf.mesh = far
	mf.material_override = mat
	mf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mf)
	return near.get_faces().size() / 3 + far.get_faces().size() / 3


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
			var nrm := Vector3(hl - hr, 2.0 * step, hu - hd).normalized()
			st.set_normal(nrm)
			st.set_uv(Vector2(x, z))
			st.set_color(weights(x, z, y, nrm))
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


## 1 m HeightMapShape3D tiles over the reachable island; tiles wholly inside
## the high rock are skipped (the slopes around them are too steep to climb).
func build_collision(parent: Node3D) -> int:
	var body := StaticBody3D.new()
	body.name = "IslandGround"
	parent.add_child(body)
	var count := 0
	var t := 64
	var x0 := -240.0
	var z0 := -416.0
	for tz in 9:
		for tx in 8:
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
			if lo > 60.0:
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
			count += 1
	return count
