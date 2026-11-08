extends RefCounted
## Level 10.1 land model: one height function shared by the render mesh, the
## streamed HeightMapShape3D collision tiles and all prop placement. The lake
## is centred on the origin; the dirt track arrives from +Z (south), so the
## gate, the dump point and the start all sit near the +Z axis.
##   d = distance outside the shoreline (negative = under the liquid)
## Bands: liquid (d < 0), stained mud (0-3 m), grass bank rising to the rim
## (3 m - bank width), rim plateau with the barbed-wire fence (FENCE_D), a
## grass verge, then Level 10 wheat (CROP_D) and the zone edge (EXIT_D).

const RS0 := 172.0          # mean shoreline radius (m)
const FENCE_D := 86.0       # fence line, metres outside the shoreline
const CROP_D := 116.0       # Level 10 wheat starts here
const EXIT_D := 146.0       # walking this far out leaves the sub-section
const CANOPY := 1.0         # wheat canopy height above the soil
const NEAR := 372.0         # half size of the fine render mesh
const STEP := 3.0           # render mesh spacing
const FAR := 2200.0
const FAR_STEP := 48.0
const LUT := 1024

var n_shore := FastNoiseLite.new()
var n_bank := FastNoiseLite.new()
var n_fine := FastNoiseLite.new()
var lut_r := PackedFloat32Array()     # shoreline radius by bearing
var lut_rim := PackedFloat32Array()   # rim height by bearing
var lut_bw := PackedFloat32Array()    # bank width by bearing
var shore_s := 0.0                    # shoreline z on the track axis
var dump := Vector3.ZERO              # dump apron centre at the waterline


func _init() -> void:
	n_shore.seed = 1001
	n_shore.frequency = 0.9
	n_shore.fractal_octaves = 3
	n_bank.seed = 1002
	n_bank.frequency = 0.011
	n_bank.fractal_octaves = 3
	n_fine.seed = 1003
	n_fine.frequency = 0.06
	lut_r.resize(LUT + 1)
	lut_rim.resize(LUT + 1)
	lut_bw.resize(LUT + 1)
	for i in LUT + 1:
		var a := TAU * float(i) / float(LUT)
		var cx := cos(a)
		var sz := sin(a)
		lut_r[i] = RS0 + 26.0 * n_shore.get_noise_2d(cx * 1.4, sz * 1.4) + 6.0 * n_shore.get_noise_2d(cx * 5.0 + 9.0, sz * 5.0)
		lut_rim[i] = 11.5 + 3.5 * n_shore.get_noise_2d(cx * 2.2 + 30.0, sz * 2.2)
		lut_bw[i] = FENCE_D - 9.0 + 7.0 * n_shore.get_noise_2d(cx * 1.8 - 40.0, sz * 1.8)
	shore_s = shore_r(PI * 0.5)
	dump = Vector3(0.0, 0.32, shore_s + 4.0)


func _lut(t: PackedFloat32Array, a: float) -> float:
	var u := fposmod(a, TAU) / TAU * LUT
	var i := int(u)
	return lerpf(t[i], t[mini(i + 1, LUT)], u - i)


func shore_r(a: float) -> float:
	return _lut(lut_r, a)


func dist(x: float, z: float) -> float:
	return sqrt(x * x + z * z) - shore_r(atan2(z, x))


## Centre line of the track (it only exists on the +Z side).
func track_x(z: float) -> float:
	return 3.2 * sin(z * 0.017) * smoothstep(shore_s + FENCE_D + 8.0, shore_s + FENCE_D + 50.0, z)


func track_w(x: float, z: float) -> float:
	if z < shore_s - 4.0:
		return 0.0
	var off := absf(x - track_x(z))
	return 1.0 - smoothstep(2.4, 5.5, off)


func apron_w(x: float, z: float) -> float:
	var dd := Vector2(x - dump.x, z - dump.z).length()
	return 1.0 - smoothstep(9.0, 17.0, dd)


## Natural ground (no track): lake bed, mud, bank, rim plateau.
func ground(x: float, z: float) -> float:
	var a := atan2(z, x)
	var r := sqrt(x * x + z * z)
	var d := r - _lut(lut_r, a)
	if d <= 0.0:
		return -minf(-d * 0.16, 9.0) - 0.06
	var rim := _lut(lut_rim, a)
	var bw := _lut(lut_bw, a)
	# a dish: flat mud apron, a long slope that steepens towards a rounded crest
	var t := clampf((d - 2.5) / (bw - 2.5), 0.0, 1.0)
	var prof := t * t * (1.6 - 0.6 * t)
	prof = minf(prof, 1.0) if t < 1.0 else 1.0
	var y := 0.18 * smoothstep(0.0, 2.5, d) + rim * prof
	y += n_bank.get_noise_2d(x, z) * (0.6 + 1.2 * smoothstep(bw, bw + 90.0, d)) * smoothstep(4.0, 16.0, d)
	return y


func h(x: float, z: float) -> float:
	var y := ground(x, z)
	var tw := track_w(x, z)
	if tw > 0.0:
		var d := dist(x, z)
		var ty: float
		var top := FENCE_D + 10.0
		if d < top:
			# the track is cut into the bank as one ramp down to the dump point
			var rim_top := ground(track_x(shore_s + top), shore_s + top) - 0.1
			ty = lerpf(0.3, rim_top, clampf(d / top, 0.0, 1.0))
		else:
			ty = ground(track_x(z), z) - 0.1
		if d > -0.5:
			y = lerpf(y, ty, tw)
	var aw := apron_w(x, z)
	if aw > 0.0 and dist(x, z) > -0.4:
		y = lerpf(y, 0.32 + 0.05 * n_fine.get_noise_2d(x, z), aw)
	return y


## 0..1 crop cover (Level 10 wheat beyond the verge, never on the track).
func crop_w(x: float, z: float) -> float:
	var d := dist(x, z)
	var c := smoothstep(CROP_D - 1.0, CROP_D + 2.0, d + 3.0 * n_fine.get_noise_2d(x * 0.3, z * 0.3))
	c *= 1.0 - smoothstep(0.0, 0.6, track_w(x, z))
	# headland strips between plots (Level 10: plots divided by tree lines)
	var hx := absf(fposmod(x + 61.0, 230.0) - 115.0)
	var hz := absf(fposmod(z + 17.0, 260.0) - 130.0)
	if (hx > 111.0 or hz > 126.0) and d > CROP_D + 20.0:
		c = 0.0
	return c


func normal_at(x: float, z: float, e: float = 1.0) -> Vector3:
	return Vector3(h(x - e, z) - h(x + e, z), 2.0 * e, h(x, z - e) - h(x, z + e)).normalized()


# ------------------------------------------------------------ render mesh

static func terrain_shader() -> String:
	return """
shader_type spatial;
render_mode diffuse_burley;
uniform sampler2D grass_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D grass_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float gust = 0.2;
varying vec3 wp;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 uv = wp.xz / 2.6;
	float macro = vn(wp.xz * 0.025) * 0.6 + vn(wp.xz * 0.11) * 0.4;
	// Level 10 grass: muted green with straw patches; the photo texture adds detail
	float a = vn(wp.xz * 0.07); float b = vn(wp.xz * 0.9);
	vec3 g = mix(vec3(0.15, 0.2, 0.08), vec3(0.27, 0.3, 0.13), a);
	g = mix(g, vec3(0.36, 0.33, 0.2), smoothstep(0.5, 0.9, b) * 0.55);
	vec3 tex = texture(grass_alb, uv).rgb;
	g *= (0.62 + 0.75 * dot(tex, vec3(0.33))) * (0.8 + 0.3 * macro);
	vec3 dirt = texture(dirt_alb, wp.xz / 3.1).rgb * vec3(0.95, 0.86, 0.74);
	// two wheel ruts with a grass strip between them (COLOR.a = offset from the centre line)
	float off = abs((COLOR.a - 0.5) * 12.0);
	float strip = 1.0 - smoothstep(0.25, 0.55, off);
	float rut = smoothstep(0.55, 0.75, off) * (1.0 - smoothstep(1.1, 1.35, off));
	float tw = COLOR.g * (1.0 - strip * 0.75 * step(0.5, COLOR.g));
	vec3 dg = mix(dirt, vec3(dot(dirt, vec3(0.33))), 0.45) * vec3(0.62, 0.57, 0.5);
	vec3 c = mix(g, dg * (1.0 - rut * 0.3), tw);
	// stained mud at the waterline: darkened, rust-red where the liquid has soaked in
	float stain = COLOR.r * COLOR.r;
	vec3 mud = dirt * vec3(0.3, 0.24, 0.2);
	mud = mix(mud, vec3(0.085, 0.018, 0.016), stain * 0.9);
	c = mix(c, mud, COLOR.r);
	// Level 10 wheat canopy (golden ears, travelling gusts)
	float ears = vn(wp.xz * 21.0) * 0.6 + vn(wp.xz * 55.0) * 0.4;
	float clump = vn(wp.xz * 3.2);
	vec3 wheat = vec3(0.6, 0.47, 0.25) * (0.78 + 0.34 * vn(wp.xz * 0.09)) * (0.55 + 0.75 * ears) * (0.85 + 0.25 * clump);
	float wave = smoothstep(0.2, 1.0, 0.5 + 0.5 * sin(dot(wp.xz, vec2(0.8, 0.6)) * 0.15 - TIME * 1.6 + vn(wp.xz * 0.02) * 6.0)) * (0.2 + gust);
	wheat = mix(wheat, wheat * 1.25 + vec3(0.03, 0.02, 0.0), wave * 0.6);
	c = mix(c, wheat, COLOR.b);
	ALBEDO = c;
	ROUGHNESS = mix(0.94, 0.5, stain * (1.0 - COLOR.b));
	NORMAL_MAP = mix(texture(grass_nrm, uv).rgb, vec3(0.5, 0.5, 1.0), max(COLOR.b, COLOR.g * 0.6));
	NORMAL_MAP_DEPTH = 0.7;
}
"""


func make_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = terrain_shader()
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


## Fine basin mesh plus a coarse far ring of Level 10 plain. The visible
## height adds the wheat canopy on cropped ground (collision stays on soil).
func build_meshes(parent: Node3D, mat: Material) -> void:
	var near := _grid(Vector2(-NEAR, -NEAR), Vector2(NEAR, NEAR), STEP, Rect2())
	var mi := MeshInstance3D.new()
	mi.name = "Basin"
	mi.mesh = near
	mi.material_override = mat
	parent.add_child(mi)
	var hole := Rect2(Vector2(-NEAR + FAR_STEP, -NEAR + FAR_STEP), Vector2(NEAR * 2.0 - FAR_STEP * 2.0, NEAR * 2.0 - FAR_STEP * 2.0))
	var far := _grid(Vector2(-FAR, -FAR), Vector2(FAR, FAR), FAR_STEP, hole)
	var mf := MeshInstance3D.new()
	mf.name = "Level10Plain"
	mf.mesh = far
	mf.material_override = mat
	mf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mf)


func _grid(mn: Vector2, mx: Vector2, step: float, hole: Rect2) -> ArrayMesh:
	var nx := int(round((mx.x - mn.x) / step)) + 1
	var nz := int(round((mx.y - mn.y) / step)) + 1
	var hs := PackedFloat32Array()
	hs.resize(nx * nz)
	var cols := PackedColorArray()
	cols.resize(nx * nz)
	var deep := PackedByteArray()
	deep.resize(nx * nz)
	for iz in nz:
		for ix in nx:
			var x := mn.x + ix * step
			var z := mn.y + iz * step
			var y := h(x, z)
			var d := dist(x, z)
			var cw := crop_w(x, z) if d > CROP_D - 8.0 else 0.0
			var tw := maxf(track_w(x, z), apron_w(x, z) * float(d > -0.4))
			var mud := 1.0 - smoothstep(0.4, 3.2, d)
			var idx := iz * nx + ix
			if hole.size.x > 0.0 and hole.grow(step).has_point(Vector2(x, z)):
				y -= 0.8
			hs[idx] = y + cw * CANOPY
			var off := clampf((x - track_x(z)) / 12.0 + 0.5, 0.0, 1.0) if z > shore_s + 2.0 else 0.0
			cols[idx] = Color(mud, tw, cw, off)
			deep[idx] = 1 if y < -2.0 else 0
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
			var a := iz * nx + ix
			if deep[a] == 1 and deep[a + 1] == 1 and deep[a + nx] == 1 and deep[a + nx + 1] == 1:
				continue
			if hole.size.x > 0.0 and hole.has_point(Vector2(mn.x + (ix + 0.5) * step, mn.y + (iz + 0.5) * step)):
				continue
			st.add_index(a)
			st.add_index(a + 1)
			st.add_index(a + nx)
			st.add_index(a + 1)
			st.add_index(a + nx + 1)
			st.add_index(a + nx)
	return st.commit()


## One 64 m HeightMapShape3D tile (1 m samples) for a streamed chunk.
func collision_tile(node: Node3D, ox: float, oz: float, size: int) -> void:
	var md := PackedFloat32Array()
	md.resize((size + 1) * (size + 1))
	var lo := INF
	for j in size + 1:
		for i in size + 1:
			var y := h(ox + i, oz + j)
			md[j * (size + 1) + i] = y
			lo = minf(lo, y)
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
	cs.set_meta("surface", "grass")
	body.add_child(cs)
