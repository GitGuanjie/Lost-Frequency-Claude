extends RefCounted
## Level 289 sound and screen-space look, synthesised in code (no binary
## assets): the scream only the targeted wanderer hears, the base radio's
## garbled voice under the water, the backward rush, and the entity's look
## (a dark refracting smear: the log says its appearance could not be made
## out because of its speed and the dark).

const RATE := 22050


static func _wav(buf: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(buf.size() * 2)
	for i in buf.size():
		data.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	return s


## Two detuned sawtooth voices through three formant band-passes (open "aa"),
## pitch climbing, clipped hard, with a thin ringing tone riding on top.
static func scream(sec: float = 3.4) -> AudioStreamWAV:
	var n := int(sec * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 289
	var p1 := 0.0
	var p2 := 0.0
	var l1 := 0.0
	var b1 := 0.0
	var l2 := 0.0
	var b2 := 0.0
	var l3 := 0.0
	var b3 := 0.0
	var jit := 0.0
	for i in n:
		var t := float(i) / RATE
		var env := minf(1.0, t / 0.05) * minf(1.0, (sec - t) / 0.3) * (0.82 + 0.18 * sin(TAU * 6.5 * t))
		jit = lerpf(jit, rng.randf_range(-1.0, 1.0), 0.002)
		var f0 := 430.0 + 210.0 * (t / sec) + 28.0 * sin(TAU * 5.1 * t) + 60.0 * jit
		p1 = fmod(p1 + f0 / RATE, 1.0)
		p2 = fmod(p2 + f0 * 1.061 / RATE, 1.0)
		var src := (p1 * 2.0 - 1.0) + 0.75 * (p2 * 2.0 - 1.0) + 0.5 * rng.randf_range(-1.0, 1.0)
		var w := 1.0 + 0.07 * sin(TAU * 0.8 * t)
		var f1 := 2.0 * sin(PI * 850.0 * w / RATE)
		var f2 := 2.0 * sin(PI * 1300.0 * w / RATE)
		var f3 := 2.0 * sin(PI * 2900.0 / RATE)
		l1 += f1 * b1
		b1 += f1 * (src - l1 - 0.22 * b1)
		l2 += f2 * b2
		b2 += f2 * (src - l2 - 0.2 * b2)
		l3 += f3 * b3
		b3 += f3 * (src - l3 - 0.25 * b3)
		var v := (b1 + 0.8 * b2 + 0.45 * b3) * 0.55
		buf[i] = (tanh(v * 2.2) * 0.78 + 0.06 * sin(TAU * 7300.0 * t)) * env
	return _wav(buf)


## Base-radio voice heard through water: buzz + breath through moving
## formants, chopped into syllables, band-limited and clipped like a handset.
static func radio_voice(sec: float, seed_value: int) -> AudioStreamWAV:
	var n := int(sec * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var ph := 0.0
	var l1 := 0.0
	var b1 := 0.0
	var l2 := 0.0
	var b2 := 0.0
	var hp := 0.0
	var syl_t := 0.0
	var syl_len := 0.2
	var fa := 600.0
	var fb := 1400.0
	var gap := false
	for i in n:
		var t := float(i) / RATE
		syl_t += 1.0 / RATE
		if syl_t >= syl_len:
			syl_t = 0.0
			gap = rng.randf() < 0.22
			syl_len = rng.randf_range(0.09, 0.26) if not gap else rng.randf_range(0.06, 0.3)
			fa = rng.randf_range(350.0, 850.0)
			fb = rng.randf_range(1000.0, 2300.0)
		var env := 0.0 if gap else sin(PI * syl_t / syl_len)
		var f0 := 118.0 + 22.0 * sin(TAU * 0.6 * t) + 15.0 * env
		ph = fmod(ph + f0 / RATE, 1.0)
		var src := (ph * 2.0 - 1.0) * 0.8 + rng.randf_range(-0.3, 0.3)
		var g1 := 2.0 * sin(PI * fa / RATE)
		var g2 := 2.0 * sin(PI * fb / RATE)
		l1 += g1 * b1
		b1 += g1 * (src - l1 - 0.3 * b1)
		l2 += g2 * b2
		b2 += g2 * (src - l2 - 0.3 * b2)
		var v := (b1 + 0.7 * b2) * env * 0.9
		hp = lerpf(hp, v, 0.08)
		v = tanh((v - hp) * 3.0) * 0.5 + rng.randf_range(-0.08, 0.08)
		buf[i] = v * minf(1.0, (sec - t) / 0.1)
	return _wav(buf)


## The backward rush: noise swept downward with a swelling, then cut, envelope.
static func rewind(sec: float = 1.8) -> AudioStreamWAV:
	var n := int(sec * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1237
	var l := 0.0
	var b := 0.0
	for i in n:
		var t := float(i) / RATE
		var u := t / sec
		var f := 2.0 * sin(PI * lerpf(3600.0, 180.0, u * u) / RATE)
		l += f * b
		b += f * (rng.randf_range(-1.0, 1.0) - l - 0.35 * b)
		buf[i] = tanh(b * 1.6) * pow(u, 1.5) * minf(1.0, (1.0 - u) / 0.03) * 0.9
	return _wav(buf)


static func entity_material() -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform float alpha = 0.0;
uniform float smear = 0.0;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
		vec4(0.0, 1.0, 0.0, 0.0), vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
}
void fragment() {
	float x = (UV.x - 0.5) * 2.0;
	float y = 1.0 - UV.y;
	float t = TIME;
	float wob = sin(y * 23.0 + t * 31.0) * 0.07 + sin(y * 7.0 - t * 13.0) * 0.1 + sin(t * 57.0 + y * 3.0) * 0.03;
	float width = mix(0.62, 0.32, smoothstep(0.5, 0.95, y));
	float body = 1.0 - smoothstep(width * 0.45, width, abs(x + wob));
	body *= smoothstep(0.0, 0.18, y) * (1.0 - smoothstep(0.82, 1.0, y));
	vec2 off = vec2(wob * 0.05 + sin(t * 40.0 + y * 50.0) * 0.006 * (1.0 + smear * 5.0), 0.0) * body;
	vec3 bg = textureLod(screen_tex, SCREEN_UV + off, 1.0 + smear * 3.0).rgb;
	ALBEDO = bg * (1.0 - 0.9 * body);
	ALPHA = clamp(body * alpha, 0.0, 1.0);
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	return m
