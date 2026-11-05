extends RefCounted
## Level 6 touch memory. Nothing in Level 6 is lit and nothing emits light: the
## world material is unshaded black. Navigation is "by feeling one's way", so the
## only image is a fading imprint of surfaces the wanderer has touched (hands out
## at arm's length, feet on the floor). ADAPTATION: a tactile memory map rendered
## in-shader (no light is cast, no light source works).

const TN := 48
const SHADER := """
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_opaque;
uniform vec4 touch_pos[48];
uniform vec4 touch_col[48];
uniform float radius = 0.62;
uniform float gain = 0.5;
uniform vec3 surface_tint : source_color = vec3(1.0);
varying vec3 wp;
varying vec3 wn;
float h3(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.11, 0.17, 0.13));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}
float vn(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h3(i), h3(i + vec3(1, 0, 0)), f.x), mix(h3(i + vec3(0, 1, 0)), h3(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(h3(i + vec3(0, 0, 1)), h3(i + vec3(1, 0, 1)), f.x), mix(h3(i + vec3(0, 1, 1)), h3(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	float acc = 0.0;
	vec3 col = vec3(0.0);
	float r2 = radius * radius;
	for (int i = 0; i < 48; i++) {
		vec4 t = touch_pos[i];
		if (t.w > 0.004) {
			vec3 d = wp - t.xyz;
			float k = t.w * exp(-dot(d, d) / r2);
			acc += k;
			col += k * touch_col[i].rgb;
		}
	}
	vec3 c = vec3(0.0);
	if (acc > 0.003) {
		col /= acc;
		acc = min(acc, 1.0);
		vec2 uv = abs(wn.y) > 0.5 ? wp.xz : vec2(dot(wp.xz, vec2(-wn.z, wn.x)), wp.y);
		float seam = max(smoothstep(0.03, 0.0, abs(fract(uv.x / 1.2) - 0.5) - 0.468), smoothstep(0.03, 0.0, abs(fract(uv.y / 0.6) - 0.5) - 0.47));
		float tie = smoothstep(0.045, 0.02, length(fract(uv / 0.6 + 0.5) - 0.5));
		float grain = vn(wp * 7.0) * 0.55 + vn(wp * 23.0) * 0.3 + vn(wp * 61.0) * 0.15;
		float rim = smoothstep(0.0, 0.5, acc);
		c = col * surface_tint * gain * rim * (0.5 + 0.5 * grain) * (1.0 - 0.5 * seam) * (1.0 - 0.55 * tie);
	}
	ALBEDO = c;
}
"""

var mats: Array = []
var pos := PackedVector4Array()
var col := PackedVector4Array()
var birth := PackedFloat32Array()
var base := PackedFloat32Array()
var idx := 0
var fade := 8.0


func _init() -> void:
	pos.resize(TN)
	col.resize(TN)
	birth.resize(TN)
	base.resize(TN)
	for i in TN:
		birth[i] = -1000.0


func make_material(mat_name: String, tint: Color, gain := 0.5) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("surface_tint", Vector3(tint.r, tint.g, tint.b))
	m.set_shader_parameter("gain", gain)
	MatLib.register(mat_name, m)
	mats.append(m)
	return m


## Record a touch (deduplicated against fresh touches nearby).
func add(p: Vector3, c: Color, strength: float, now: float) -> void:
	for i in TN:
		if now - birth[i] < 0.9 and Vector3(pos[i].x, pos[i].y, pos[i].z).distance_squared_to(p) < 0.1:
			birth[i] = now
			base[i] = maxf(base[i], strength)
			return
	pos[idx] = Vector4(p.x, p.y, p.z, 0.0)
	col[idx] = Vector4(c.r, c.g, c.b, 1.0)
	birth[idx] = now
	base[idx] = strength
	idx = (idx + 1) % TN


func clear() -> void:
	for i in TN:
		birth[i] = -1000.0


func upload(now: float) -> void:
	for i in TN:
		var age := now - birth[i]
		var w := 0.0
		if age < fade * 3.0:
			w = base[i] * exp(-age / fade) * minf(1.0, age * 8.0 + 0.3)
		pos[i] = Vector4(pos[i].x, pos[i].y, pos[i].z, w)
	for m in mats:
		m.set_shader_parameter("touch_pos", pos)
		m.set_shader_parameter("touch_col", col)
