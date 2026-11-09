extends RefCounted
## Level 94 land and the "crafted" look. The town sits on a level plateau
## (radius ~TOWN_R) round the origin; beyond it the grass hills roll on without
## end (streamed collision, a coarse far ring under the haze).
## Every surface uses one clay shader: flat toy colours, thumb-pressed relief,
## and a texture that "boils" a few times a second like hand-animated
## plasticine (page: "a grainy effect, as if this place was crafted";
## "stop-motion type feel").

const TOWN_R := 92.0
const NEAR := 520.0
const STEP := 6.5
const TILE := 130.0
const FAR := 2600.0
const FAR_STEP := 40.0

var n_a := FastNoiseLite.new()
var n_b := FastNoiseLite.new()


func _init() -> void:
	n_a.seed = 9401
	n_a.frequency = 0.0065
	n_a.fractal_octaves = 3
	n_b.seed = 9402
	n_b.frequency = 0.02


func hills(x: float, z: float) -> float:
	return 6.0 + 11.0 * n_a.get_noise_2d(x, z) + 2.0 * n_b.get_noise_2d(x, z)


## 0 inside the town plateau, 1 out in the hills.
func hill_w(x: float, z: float) -> float:
	return smoothstep(TOWN_R, TOWN_R + 70.0, Vector2(x, z).length())


func h(x: float, z: float) -> float:
	var w := hill_w(x, z)
	if w <= 0.0:
		return 0.0
	return maxf(hills(x, z), 0.0) * w


func normal_at(x: float, z: float, e: float = 1.0) -> Vector3:
	return Vector3(h(x - e, z) - h(x + e, z), 2.0 * e, h(x, z - e) - h(x, z + e)).normalized()


const CLAY := """
shader_type spatial;
render_mode diffuse_burley;
uniform vec3 col_a : source_color = vec3(0.8, 0.7, 0.55);
uniform vec3 col_b : source_color = vec3(0.7, 0.6, 0.45);
uniform float thumb = 1.0;       // depth of the pressed marks
uniform float scale = 1.0;
uniform float pattern = 0.0;     // 0 none, 1 boards, 2 bricks, 3 cobbles, 4 shingles, 5 grass
uniform float stepped_fps = 6.0;
varying vec3 wp;
varying vec3 wn;
float hsh(vec2 p) { vec3 q = fract(vec3(p.xyx) * 0.1031); q += dot(q, q.yzx + 33.33); return fract((q.x + q.y) * q.z); }
float vn(vec2 p) { vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hsh(i), hsh(i + vec2(1.0, 0.0)), f.x), mix(hsh(i + vec2(0.0, 1.0)), hsh(i + vec2(1.0, 1.0)), f.x), f.y); }
vec2 tri_uv(vec3 p, vec3 n) {
	vec3 a = abs(n);
	if (a.y > a.x && a.y > a.z) return p.xz;
	if (a.x > a.z) return p.zy;
	return p.xy;
}
void vertex() { wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz); }
void fragment() {
	vec2 uv = tri_uv(wp, wn) * scale;
	// the boil: the hand-made texture re-settles a few times a second
	float fr = floor(TIME * stepped_fps);
	vec2 j = vec2(hsh(vec2(fr, 1.3)), hsh(vec2(fr, 7.1))) * 0.35;
	float big = vn(uv * 0.7 + 11.0);
	float pr = vn(uv * 6.0 + j * 6.0);
	float fine = vn(uv * 22.0 + j * 13.0);
	vec3 c = mix(col_a, col_b, smoothstep(0.3, 0.75, big));
	float line = 0.0;
	if (pattern > 0.5 && pattern < 1.5) { line = smoothstep(0.04, 0.0, abs(fract(uv.y * 3.2) - 0.5) - 0.44); }
	if (pattern > 1.5 && pattern < 2.5) {
		vec2 b = uv * vec2(3.0, 6.0); b.x += step(1.0, mod(b.y, 2.0)) * 0.5;
		vec2 f = abs(fract(b) - 0.5); line = smoothstep(0.43, 0.48, max(f.x * 0.9, f.y));
	}
	if (pattern > 2.5 && pattern < 3.5) {
		vec2 b = uv * 1.6; b.x += step(1.0, mod(floor(b.y), 2.0)) * 0.5;
		vec2 f = abs(fract(b) - 0.5); line = smoothstep(0.36, 0.47, max(f.x, f.y));
		c *= 0.85 + 0.3 * hsh(floor(b));
	}
	if (pattern > 3.5 && pattern < 4.5) {
		vec2 b = uv * vec2(3.0, 4.0); b.x += step(1.0, mod(floor(b.y), 2.0)) * 0.5;
		line = smoothstep(0.3, 0.5, fract(b.y)) * 0.5 + smoothstep(0.45, 0.5, abs(fract(b.x) - 0.5)) * 0.5;
	}
	if (pattern > 4.5) {
		float tufts = vn(uv * 3.0 + j * 2.0);
		c = mix(c, c * vec3(1.15, 1.2, 0.9), smoothstep(0.55, 0.8, tufts));
		c *= 0.85 + 0.3 * vn(uv * 0.15);
	}
	c *= 1.0 - line * 0.35;
	c *= 0.9 + 0.12 * pr + 0.06 * fine;
	ALBEDO = c;
	ROUGHNESS = 0.78 - 0.12 * pr;
	SPECULAR = 0.35;
	// thumb-pressed relief, re-pressed every frame of the boil
	vec2 e = vec2(0.04, 0.0);
	float h0 = vn(uv * 6.0 + j * 6.0) + 0.4 * fine;
	float hx = vn((uv + e.xy) * 6.0 + j * 6.0) + 0.4 * vn((uv + e.xy) * 22.0 + j * 13.0);
	float hy = vn((uv + e.yx) * 6.0 + j * 6.0) + 0.4 * vn((uv + e.yx) * 22.0 + j * 13.0);
	NORMAL_MAP = normalize(vec3((h0 - hx) * thumb * 3.0, (h0 - hy) * thumb * 3.0, 1.0)) * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = 1.0;
}
"""

static var _clay_shader: Shader


## Register a clay colour under a GeoKit material name.
static func clay(name: String, a: Color, b: Color, pattern := 0, scale := 1.0, thumb := 1.0) -> ShaderMaterial:
	if _clay_shader == null:
		_clay_shader = Shader.new()
		_clay_shader.code = CLAY
	var m := ShaderMaterial.new()
	m.shader = _clay_shader
	m.set_shader_parameter("col_a", a)
	m.set_shader_parameter("col_b", b)
	m.set_shader_parameter("pattern", float(pattern))
	m.set_shader_parameter("scale", scale)
	m.set_shader_parameter("thumb", thumb)
	MatLib.register(name, m)
	return m


func build_meshes(parent: Node3D, mat: Material) -> void:
	var n := int(NEAR * 2.0 / TILE)
	for tz in n:
		for tx in n:
			var mn := Vector2(-NEAR + tx * TILE, -NEAR + tz * TILE)
			var mi := MeshInstance3D.new()
			mi.name = "Land_%d_%d" % [tx, tz]
			mi.mesh = _grid(mn, mn + Vector2(TILE, TILE), STEP, Rect2())
			mi.material_override = mat
			parent.add_child(mi)
	var hole := Rect2(Vector2(-NEAR, -NEAR), Vector2(NEAR * 2.0, NEAR * 2.0))
	var mf := MeshInstance3D.new()
	mf.name = "FarHills"
	mf.mesh = _grid(Vector2(-FAR, -FAR), Vector2(FAR, FAR), FAR_STEP, hole)
	mf.material_override = mat
	mf.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mf)


func _grid(mn: Vector2, mx: Vector2, step: float, hole: Rect2) -> ArrayMesh:
	var nx := int(round((mx.x - mn.x) / step)) + 1
	var nz := int(round((mx.y - mn.y) / step)) + 1
	var hs := PackedFloat32Array()
	hs.resize(nx * nz)
	for iz in nz:
		for ix in nx:
			var x := mn.x + ix * step
			var z := mn.y + iz * step
			var y := h(x, z) - 0.04
			if hole.size.x > 0.0 and hole.grow(step).has_point(Vector2(x, z)):
				y -= 1.5
			hs[iz * nx + ix] = y
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
			st.add_vertex(Vector3(mn.x + ix * step, hs[idx], mn.y + iz * step))
	for iz in nz - 1:
		for ix in nx - 1:
			if hole.size.x > 0.0 and hole.has_point(Vector2(mn.x + (ix + 0.5) * step, mn.y + (iz + 0.5) * step)):
				continue
			var a := iz * nx + ix
			st.add_index(a)
			st.add_index(a + 1)
			st.add_index(a + nx)
			st.add_index(a + 1)
			st.add_index(a + nx + 1)
			st.add_index(a + nx)
	return st.commit()


func collision_tile(node: Node3D, ox: float, oz: float, size: int) -> void:
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
	cs.set_meta("surface", "grass")
	body.add_child(cs)
