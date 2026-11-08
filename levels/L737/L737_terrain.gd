extends RefCounted
## Level 737 terrain: an endless desert of fine gold dust (Object 737/1). One
## height function drives the render meshes, the HeightMapShape3D collision and
## prop placement. North = -Z. The Great Pyramid of Ilios sits at (0, 0, -100);
## its footprint is cut deep (-70) so the interior floors and the bottomless
## core chamber are built from geometry. A ring of sheer dune walls (~300 m out)
## closes the walkable area; the visual terrain runs on to the horizon in haze,
## and the canyon the Golden Gate Bridge hangs over is cut in the far west.

const PYR := Vector3(0, 0, -100)
const PYR_CUT := 62.0
const NEAR := 336.0
const NEAR_STEP := 2.5
const FAR := 1800.0
const FAR_STEP := 40.0
const RING_C := Vector3(0, 0, -50)
const RING_R := 300.0

var n_dune := FastNoiseLite.new()
var n_ripple := FastNoiseLite.new()
var n_big := FastNoiseLite.new()


func _init() -> void:
	n_dune.seed = 737
	n_dune.frequency = 0.007
	n_dune.fractal_octaves = 3
	n_ripple.seed = 7371
	n_ripple.frequency = 0.045
	n_big.seed = 7372
	n_big.frequency = 0.0016


func in_pyramid(x: float, z: float) -> bool:
	return absf(x - PYR.x) < PYR_CUT and absf(z - PYR.z) < PYR_CUT


func h(x: float, z: float) -> float:
	if in_pyramid(x, z):
		return -70.0
	var d := 2.4 * n_dune.get_noise_2d(x, z) + 6.0 * n_big.get_noise_2d(x, z) + 0.35 * n_ripple.get_noise_2d(x * 1.6, z)
	# the city of New Ephyra and the plaza before the pyramid sit on old paving
	var flat := 1.0 - smoothstep(0.0, 26.0, maxf(maxf(absf(x) - 72.0, z - 46.0), maxf(-36.0 - z, 0.0)))
	var pl := 1.0 - smoothstep(0.0, 22.0, maxf(absf(x - PYR.x) - 64.0, absf(z - PYR.z) - 64.0))
	flat = maxf(flat, pl)
	d = lerpf(d, 0.15 * n_ripple.get_noise_2d(x, z) - 0.05, flat)
	# sheer dune walls close the walkable desert
	var r := Vector2(x - RING_C.x, z - RING_C.z).length() + 14.0 * n_dune.get_noise_2d(z * 0.7, x * 0.7)
	if r > RING_R:
		d += minf((r - RING_R) * 1.7, 70.0) + 10.0 * n_big.get_noise_2d(x * 3.0, z * 3.0) * smoothstep(RING_R, RING_R + 60.0, r)
	# the canyon of nothingness under the Golden Gate (far west, out of reach)
	if x < -380.0 and x > -520.0:
		var cw := 1.0 - smoothstep(30.0, 70.0, absf(x + 450.0))
		d = lerpf(d, -400.0, cw)
	return d


static func shader_code() -> String:
	return """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
uniform vec3 gold_a : source_color = vec3(0.86, 0.62, 0.20);
uniform vec3 gold_b : source_color = vec3(0.62, 0.40, 0.10);
varying vec3 wpos;
float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float vnoise(vec2 p) {
	vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), f.x), mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), f.x), f.y);
}
void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = wpos.xz;
	float rip = sin(p.x * 1.9 + vnoise(p * 0.15) * 6.0 + p.y * 0.4);
	float m = vnoise(p * 0.035) * 0.6 + vnoise(p * 0.21) * 0.3 + vnoise(p * 1.7) * 0.1;
	vec3 alb = mix(gold_b, gold_a, clamp(m + rip * 0.08, 0.0, 1.0));
	ALBEDO = alb;
	METALLIC = 0.55;
	ROUGHNESS = 0.42 - 0.1 * rip;
	float g = hash(floor(p * 9.0) + floor(TIME * 3.0) * 0.0);
	float glint = step(0.996, g) * pow(max(0.0, dot(normalize(-VIEW), vec3(0.0, 1.0, 0.0)) * 0.5 + 0.5), 2.0);
	EMISSION = vec3(1.0, 0.8, 0.4) * glint * 1.5 + alb * 0.12;
	NORMAL_MAP = normalize(vec3(0.5 + 0.18 * cos(p.x * 1.9 + p.y * 0.4), 0.5, 1.0));
	NORMAL_MAP_DEPTH = 0.6;
}
"""


func make_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = shader_code()
	var m := ShaderMaterial.new()
	m.shader = sh
	return m


func build_meshes(parent: Node3D, mat: Material) -> void:
	var near := _grid(Vector2(-NEAR, -NEAR) + Vector2(RING_C.x, RING_C.z), Vector2(NEAR, NEAR) + Vector2(RING_C.x, RING_C.z), NEAR_STEP, Rect2())
	var mi := MeshInstance3D.new()
	mi.name = "GoldDust"
	mi.mesh = near
	mi.material_override = mat
	parent.add_child(mi)
	var hole := Rect2(Vector2(-NEAR + FAR_STEP, -NEAR + FAR_STEP) + Vector2(RING_C.x, RING_C.z), Vector2(NEAR * 2.0 - FAR_STEP * 2.0, NEAR * 2.0 - FAR_STEP * 2.0))
	var far := _grid(Vector2(-FAR, -FAR), Vector2(FAR, FAR), FAR_STEP, hole)
	var mf := MeshInstance3D.new()
	mf.name = "GoldDustFar"
	mf.mesh = far
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
			var y := h(x, z)
			if hole.size.x > 0.0 and hole.grow(step).has_point(Vector2(x, z)):
				y -= 1.0
			hs[iz * nx + ix] = y
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for iz in nz:
		for ix in nx:
			var y := hs[iz * nx + ix]
			var hl := hs[iz * nx + maxi(ix - 1, 0)]
			var hr := hs[iz * nx + mini(ix + 1, nx - 1)]
			var hu := hs[maxi(iz - 1, 0) * nx + ix]
			var hd := hs[mini(iz + 1, nz - 1) * nx + ix]
			st.set_normal(Vector3(hl - hr, 2.0 * step, hu - hd).normalized())
			st.set_uv(Vector2(mn.x + ix * step, mn.y + iz * step))
			st.add_vertex(Vector3(mn.x + ix * step, y, mn.y + iz * step))
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


## 2 m HeightMapShape3D tiles over the walkable desert (named "Dust": standing
## on it burns; everything else is stone, marble or metal and does not).
func build_collision(parent: Node3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Dust"
	parent.add_child(body)
	var cells := 64
	var sp := 2.0
	var span := cells * sp
	var x0 := RING_C.x - NEAR
	var z0 := RING_C.z - NEAR
	var n := int(ceil(NEAR * 2.0 / span))
	for tz in n:
		for tx in n:
			var ox := x0 + tx * span
			var oz := z0 + tz * span
			var md := PackedFloat32Array()
			md.resize((cells + 1) * (cells + 1))
			for j in cells + 1:
				for i in cells + 1:
					md[j * (cells + 1) + i] = h(ox + i * sp, oz + j * sp)
			var shape := HeightMapShape3D.new()
			shape.map_width = cells + 1
			shape.map_depth = cells + 1
			shape.map_data = md
			var cs := CollisionShape3D.new()
			cs.shape = shape
			cs.scale = Vector3(sp, 1.0, sp)
			cs.position = Vector3(ox + span * 0.5, 0.0, oz + span * 0.5)
			cs.set_meta("surface", "sand")
			body.add_child(cs)
	return body
