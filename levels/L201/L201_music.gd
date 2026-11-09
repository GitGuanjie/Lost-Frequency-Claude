extends RefCounted
## Level 201: the "background music". Original synthesized lounge loop: slow electric-piano
## seventh chords, a soft bass, brushed hats and vinyl crackle, pitched down as if slowed and
## remixed. The key, tempo and progression change with the seed: different for every wanderer.

const RATE := 11025

const PROGRESSIONS := [
	[[0, 4, 7, 11], [9, 12, 16, 19], [2, 5, 9, 12], [7, 11, 14, 17]],
	[[2, 5, 9, 12], [7, 11, 14, 17], [0, 4, 7, 11], [0, 4, 7, 14]],
	[[5, 9, 12, 16], [4, 7, 11, 14], [2, 5, 9, 12], [0, 4, 7, 14]],
	[[0, 3, 7, 10], [5, 8, 12, 15], [10, 14, 17, 21], [3, 7, 10, 14]],
]


static func make(seed_v: int) -> AudioStreamWAV:
	var r := RandomNumberGenerator.new()
	r.seed = seed_v * 7919 + 201
	var prog: Array = PROGRESSIONS[r.randi() % PROGRESSIONS.size()]
	var root := r.randf_range(110.0, 147.0)
	var bpm := r.randf_range(62.0, 74.0)
	var beat := 60.0 / bpm
	var bar := beat * 4.0
	var n := int(bar * 4.0 * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for b in 4:
		var chord: Array = prog[b]
		var t0 := b * bar
		for i in chord.size():
			var f := root * pow(2.0, float(chord[i]) / 12.0)
			_note(buf, t0 + i * 0.035, bar * 0.98, f, 0.16)
			if r.randf() < 0.5:
				_note(buf, t0 + beat * 2.5 + i * 0.03, beat * 1.4, f, 0.08)
		var bf := root * 0.5 * pow(2.0, float(chord[0]) / 12.0)
		_bass(buf, t0, beat * 1.8, bf)
		_bass(buf, t0 + beat * 2.0, beat * 1.6, bf * 1.4983)
		for q in 4:
			if q % 2 == 1:
				_hat(buf, t0 + q * beat, r)
	var crackle := 0.0
	for i in n:
		if r.randf() < 0.0012:
			crackle = r.randf_range(0.05, 0.15)
		buf[i] += crackle * r.randf_range(-1.0, 1.0)
		crackle *= 0.7
	var peak := 0.001
	for i in n:
		peak = maxf(peak, absf(buf[i]))
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var v := int(clampf(buf[i] / peak * 0.7, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = n
	return s


## Electric piano: sine plus a decaying bell partial, gentle tremolo.
static func _note(buf: PackedFloat32Array, t0: float, dur: float, f: float, amp: float) -> void:
	var a := int(t0 * RATE)
	var e := mini(buf.size(), a + int((dur + 0.6) * RATE))
	for i in range(a, e):
		var t := float(i - a) / RATE
		var env := minf(t / 0.012, 1.0) * (0.35 * exp(-t * 2.2) + 0.65 * exp(-t * 0.55)) * (1.0 if t < dur else exp(-(t - dur) * 8.0))
		var ph := TAU * f * t
		var v := sin(ph) + 0.3 * sin(2.0 * ph) * exp(-t * 3.0) + 0.12 * sin(7.0 * ph) * exp(-t * 9.0)
		buf[i] += v * env * amp * (0.9 + 0.1 * sin(TAU * 4.5 * t))


static func _bass(buf: PackedFloat32Array, t0: float, dur: float, f: float) -> void:
	var a := int(t0 * RATE)
	var e := mini(buf.size(), a + int(dur * RATE))
	for i in range(a, e):
		var t := float(i - a) / RATE
		var env := minf(t / 0.02, 1.0) * exp(-t * 1.6)
		buf[i] += (sin(TAU * f * t) + 0.2 * sin(TAU * f * 2.0 * t)) * env * 0.32


static func _hat(buf: PackedFloat32Array, t0: float, r: RandomNumberGenerator) -> void:
	var a := int(t0 * RATE)
	var e := mini(buf.size(), a + int(0.12 * RATE))
	var lp := 0.0
	for i in range(a, e):
		var t := float(i - a) / RATE
		var w := r.randf_range(-1.0, 1.0)
		lp = lp * 0.4 + w * 0.6
		buf[i] += (w - lp) * exp(-t * 40.0) * 0.06
