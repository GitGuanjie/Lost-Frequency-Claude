extends RefCounted
## Level 77 land model. One height function feeds the render meshes, the
## streamed HeightMapShape3D collision tiles and every placement.
## The central hill country ("New Shenandoah") is centred on the origin; its
## border with the nightbound deciduous forest wanders around radius RB.
##   d = distance outside the border (negative = inside the hills)
## ADAPTATION (scale): the page's 25 km2 of hills become ~0.45 km2 here and
## forest depth is read at 1 game metre = 40 m (DEPTH_SCALE), so the page's
## "4 km" entrance ring sits 100 m into the trees and its "6 km" exit line 150 m.

const RB := 380.0
const DEPTH_SCALE := 40.0
const ARRIVE_D := 100.0      # 4 km into the forest
const EXIT_D := 150.0        # 6 km into the forest
const NEAR := 600.0          # half size of the fine render square
const STEP := 4.0
const TILE := 150.0
const FAR := 2600.0
const FAR_STEP := 40.0
const CANOPY := 17.0         # height of the far canopy shell above the floor
const LUT := 720

var n_big := FastNoiseLite.new()
var n_mid := FastNoiseLite.new()
var n_fine := FastNoiseLite.new()
var n_edge := FastNoiseLite.new()
var lut_b := PackedFloat32Array()


func _init() -> void:
	n_big.seed = 7701
	n_big.frequency = 0.0042
	n_big.fractal_octaves = 3
	n_big.fractal_gain = 0.45
	n_mid.seed = 7702
	n_mid.frequency = 0.011
	n_mid.fractal_octaves = 2
	n_fine.seed = 7703
	n_fine.frequency = 0.05
	n_edge.seed = 7704
	n_edge.frequency = 1.3
	n_edge.fractal_octaves = 3
	lut_b.resize(LUT + 1)
	for i in LUT + 1:
		var a := TAU * float(i) / LUT
		lut_b[i] = RB + 26.0 * n_edge.get_noise_2d(cos(a) * 1.5, sin(a) * 1.5)


func border_r(a: float) -> float:
	var u := fposmod(a, TAU) / TAU * LUT
	var i := int(u)
	return lerpf(lut_b[i], lut_b[mini(i + 1, LUT)], u - i)


## Signed distance outside the forest border (negative inside the hills).
func dist(x: float, z: float) -> float:
	return sqrt(x * x + z * z) - border_r(atan2(z, x))


## Forest depth in the page's kilometres.
func depth_km(x: float, z: float) -> float:
	return maxf(dist(x, z), 0.0) * DEPTH_SCALE / 1000.0


## Steep, undulating hills: valleys near 0-6 m, crests up to ~70 m.
func hills(x: float, z: float) -> float:
	var b := n_big.get_noise_2d(x, z)
	var m := n_mid.get_noise_2d(x, z)
	var y := 23.0 + 50.0 * b + 9.0 * m + 40.0 * maxf(b - 0.35, 0.0)
	# soft floor: valleys flatten out instead of going below ground
	y = 3.0 + log(1.0 + exp((y - 3.0) / 4.0)) * 4.0
	return y + 0.4 * n_fine.get_noise_2d(x, z)


## Gentle forest floor (root-heaved, litter-covered).
func forest(x: float, z: float) -> float:
	return 13.0 + 2.2 * n_mid.get_noise_2d(x * 0.7 + 300.0, z * 0.7) + 0.5 * n_fine.get_noise_2d(x, z)


func forest_w(x: float, z: float) -> float:
	return smoothstep(-6.0, 4.0, dist(x, z))


func h(x: float, z: float) -> float:
	var d := dist(x, z)
	if d > 12.0:
		return forest(x, z)
	if d < -80.0:
		return hills(x, z)
	return lerpf(hills(x, z), forest(x, z), smoothstep(-80.0, 12.0, d))


func normal_at(x: float, z: float, e: float = 1.0) -> Vector3:
	return Vector3(h(x - e, z) - h(x + e, z), 2.0 * e, h(x, z - e) - h(x, z + e)).normalized()


# ------------------------------------------------------------ render meshes

const SHADER := """
shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D grass_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float forest_k = 0.25;   // forest albedo factor (dark from the hills)
uniform float day_glow = 0.0;    // hills read as daylight when seen from the night
varying vec3 wp;
varying float up;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; up = NORMAL.y; }
void fragment() {
	vec2 uv = wp.xz / 2.2;
	vec3 tex = texture(grass_alb, uv).rgb;
	float a = vn(wp.xz * 0.045); float b = vn(wp.xz * 0.6);
	// zoysia: dense, even, saturated; bluegrass drifts and moss on the steep faces
	vec3 zoy = mix(vec3(0.07, 0.135, 0.035), vec3(0.1, 0.17, 0.045), a);
	vec3 blue = vec3(0.07, 0.14, 0.08);
	vec3 moss = vec3(0.1, 0.14, 0.03);
	vec3 g = mix(zoy, blue, smoothstep(0.62, 0.8, vn(wp.xz * 0.02 + 7.0)) * 0.7);
	g = mix(g, moss, smoothstep(0.82, 0.62, up) * 0.8);
	g *= 0.62 + 0.8 * dot(tex, vec3(0.33));
	g *= 0.82 + 0.3 * b;
	// mottling of the sward, wind-combed streaks and worn sheep trails
	float mot = vn(wp.xz * 0.11) * 0.6 + vn(wp.xz * 0.33) * 0.4;
	g *= 0.78 + 0.38 * mot;
	g = mix(g, g * vec3(1.15, 1.08, 0.8), smoothstep(0.55, 0.9, vn(vec2(wp.x * 0.05, wp.z * 0.5))) * 0.35);
	float tr = 1.0 - smoothstep(0.0, 0.012, abs(vn(wp.xz * 0.018 + 40.0) - 0.5));
	vec3 loam = texture(dirt_alb, wp.xz / 2.0).rgb * vec3(0.2, 0.17, 0.12);
	g = mix(g, loam, tr * 0.5 * smoothstep(0.6, 0.85, up));
	// leaf litter and loam under the trees
	vec3 dirt = texture(dirt_alb, wp.xz / 2.7).rgb;
	vec3 litter = mix(vec3(0.09, 0.055, 0.03), vec3(0.14, 0.09, 0.045), vn(wp.xz * 1.3)) * (0.6 + 0.6 * dot(dirt, vec3(0.33)));
	float f = COLOR.r;
	vec3 c = mix(g, litter, f);
	c *= mix(1.0, forest_k, f);
	// the far canopy shell (only on the impostor meshes)
	vec3 can = mix(vec3(0.03, 0.05, 0.02), vec3(0.055, 0.075, 0.03), vn(wp.xz * 0.15)) * forest_k;
	c = mix(c, can, COLOR.g);
	ALBEDO = c;
	ROUGHNESS = 0.95;
	NORMAL_MAP = mix(texture(grass_nrm, uv).rgb, vec3(0.5, 0.5, 1.0), max(COLOR.g, f * 0.5));
	NORMAL_MAP_DEPTH = 0.8;
	EMISSION = g * day_glow * (1.0 - f) * (1.0 - COLOR.g);
}
"""


func make_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	var g := "res://assets/external/sparse_grass/sparse_grass_%s_1k.jpg"
	var dt := "res://assets/external/dirt_floor/dirt_floor_%s_1k.jpg"
	if ResourceLoader.exists(g % "diff"):
		m.set_shader_parameter("grass_alb", load(g % "diff"))
		m.set_shader_parameter("grass_nrm", load(g % "nor_gl"))
	if ResourceLoader.exists(dt % "diff"):
		m.set_shader_parameter("dirt_alb", load(dt % "diff"))
	return m


## Fine tiled square (frustum-culled per tile), canopy impostor tiles over the
## forest inside it (shown only beyond the streamed trees), and a coarse far
## ring whose forest part is the canopy shell.
func build_meshes(parent: Node3D, mat: Material, tree_reach: float) -> void:
	var n := int(NEAR * 2.0 / TILE)
	for tz in n:
		for tx in n:
			var mn := Vector2(-NEAR + tx * TILE, -NEAR + tz * TILE)
			var mi := MeshInstance3D.new()
			mi.name = "Land_%d_%d" % [tx, tz]
			mi.mesh = _grid(mn, mn + Vector2(TILE, TILE), STEP, Rect2(), false)
			mi.material_override = mat
			parent.add_child(mi)
	# canopy impostor tiles: forest only, inside the fine square
	var ct := 50.0
	var m := int(NEAR * 2.0 / ct)
	for tz in m:
		for tx in m:
			var mn := Vector2(-NEAR + tx * ct, -NEAR + tz * ct)
			var c := mn + Vector2(ct * 0.5, ct * 0.5)
			if dist(c.x, c.y) < 40.0:
				continue
			var mi := MeshInstance3D.new()
			mi.name = "Canopy_%d_%d" % [tx, tz]
			mi.mesh = _grid(Vector2(-ct * 0.5, -ct * 0.5), Vector2(ct * 0.5, ct * 0.5), 6.25, Rect2(), true, c)
			mi.position = Vector3(c.x, 0.0, c.y)
			mi.material_override = mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.visibility_range_begin = tree_reach
			mi.visibility_range_begin_margin = 6.0
			mi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
			parent.add_child(mi)
	var hole := Rect2(Vector2(-NEAR, -NEAR), Vector2(NEAR * 2.0, NEAR * 2.0))
	var mf := MeshInstance3D.new()
	mf.name = "FarForest"
	mf.mesh = _grid(Vector2(-FAR, -FAR), Vector2(FAR, FAR), FAR_STEP, hole, true)
	mf.material_override = mat
	mf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mf)


func _canopy_h(x: float, z: float) -> float:
	return h(x, z) + CANOPY + 5.0 * n_mid.get_noise_2d(x * 3.0, z * 3.0) + 2.0 * n_fine.get_noise_2d(x * 2.0, z * 2.0)


## A grid mesh. `canopy` raises forest vertices into the canopy shell.
## `off` shifts sampling for locally positioned tiles.
func _grid(mn: Vector2, mx: Vector2, step: float, hole: Rect2, canopy: bool, off := Vector2.ZERO) -> ArrayMesh:
	var nx := int(round((mx.x - mn.x) / step)) + 1
	var nz := int(round((mx.y - mn.y) / step)) + 1
	var hs := PackedFloat32Array()
	hs.resize(nx * nz)
	var cols := PackedColorArray()
	cols.resize(nx * nz)
	for iz in nz:
		for ix in nx:
			var x := mn.x + ix * step + off.x
			var z := mn.y + iz * step + off.y
			var fw := forest_w(x, z)
			var y: float
			var cg := 0.0
			if canopy:
				var k := smoothstep(20.0, 45.0, dist(x, z))
				y = lerpf(h(x, z) - 2.0, _canopy_h(x, z), k)
				cg = k
			else:
				y = h(x, z)
			if hole.size.x > 0.0 and hole.grow(step).has_point(Vector2(x, z)):
				y -= 1.5
			hs[iz * nx + ix] = y
			cols[iz * nx + ix] = Color(fw, cg, 0.0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in nz:
		for ix in nx:
			var idx := iz * nx + ix
			var hl := hs[iz * nx + maxi(ix - 1, 0)]
			var hr := hs[iz * nx + mini(ix + 1, nx - 1)]
			var hu := hs[maxi(iz - 1, 0) * nx + ix]
			var hd := hs[mini(iz + 1, nz - 1) * nx + ix]
			st.set_normal(Vector3(hl - hr, 2.0 * step, hu - hd).normalized())
			st.set_color(cols[idx])
			st.add_vertex(Vector3(mn.x + ix * step, hs[idx], mn.y + iz * step))
	for iz in nz - 1:
		for ix in nx - 1:
			if hole.size.x > 0.0 and hole.has_point(Vector2(mn.x + (ix + 0.5) * step, mn.y + (iz + 0.5) * step)):
				continue
			if canopy and hole.size.x == 0.0:
				# impostor tiles: drop quads that would sit over the open hills
				var a0 := cols[iz * nx + ix].g + cols[iz * nx + ix + 1].g + cols[(iz + 1) * nx + ix].g
				if a0 <= 0.0:
					continue
			var a := iz * nx + ix
			st.add_index(a)
			st.add_index(a + 1)
			st.add_index(a + nx)
			st.add_index(a + 1)
			st.add_index(a + nx + 1)
			st.add_index(a + nx)
	return st.commit()


## One 1 m HeightMapShape3D collision tile for a streamed chunk.
func collision_tile(node: Node3D, ox: float, oz: float, size: int, surface: String) -> void:
	var md := PackedFloat32Array()
	md.resize((size + 1) * (size + 1))
	for j in size + 1:
		for i in size + 1:
			md[j * (size + 1) + i] = h(ox + i, oz + j)
	var body := StaticBody3D.new()
	body.name = "Ground"
	node.add_child(body)
	var sh := HeightMapShape3D.new()
	sh.map_width = size + 1
	sh.map_depth = size + 1
	sh.map_data = md
	var cs := CollisionShape3D.new()
	cs.shape = sh
	cs.position = Vector3(ox + size * 0.5, 0.0, oz + size * 0.5)
	cs.set_meta("surface", surface)
	body.add_child(cs)
