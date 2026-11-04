extends Node
## Procedural audio created in-project (no third-party samples). Every stream is
## synthesised at runtime into an AudioStreamWAV and cached by recipe key.
## Recipes are deliberately level-specific: a Level 0 ballast buzz is not the
## Level 37 water bed, and both differ from the Level 3 transformer drone.

const RATE := 22050
var _cache: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func get_stream(recipe: String, params: Dictionary = {}) -> AudioStreamWAV:
	var key := recipe + JSON.stringify(params)
	if _cache.has(key):
		return _cache[key]
	var s: AudioStreamWAV
	_rng.seed = hash(key)
	match recipe:
		"fluorescent_hum": s = _fluorescent(params)
		"room_tone": s = _room_tone(params)
		"water_bed": s = _water_bed(params)
		"drip": s = _drip(params)
		"footstep": s = _footstep(params)
		"wind": s = _wind(params)
		"crickets": s = _crickets(params)
		"transformer": s = _transformer(params)
		"crackle": s = _crackle(params)
		"pipe_clank": s = _clank(params)
		"rain": s = _rain(params)
		"thunder": s = _thunder(params)
		"pad": s = _pad(params)
		"chiptune": s = _chiptune(params)
		"static": s = _static(params)
		"creak": s = _creak(params)
		"ui": s = _ui(params)
		"splash": s = _splash(params)
		"knock": s = _knock(params)
		"music_box": s = _music_box(params)
		"heartbeat": s = _heartbeat(params)
		"distant_boom": s = _thunder({"seconds": 3.0, "low": 0.6})
		"whisper": s = _whisper(params)
		"scratch": s = _scratch(params)
		_:
			push_warning("AudioSynth: unknown recipe " + recipe)
			s = _room_tone({})
	_cache[key] = s
	return s


# ---------------------------------------------------------------- utilities

func _to_stream(buf: PackedFloat32Array, loop: bool, xfade: int = 0) -> AudioStreamWAV:
	var n := buf.size()
	if loop and xfade > 0 and n > xfade * 2:
		# crossfade the tail into the head so the loop point is seamless
		for i in xfade:
			var t := float(i) / float(xfade)
			buf[i] = buf[i] * t + buf[n - xfade + i] * (1.0 - t)
		buf.resize(n - xfade)
		n = buf.size()
	var peak := 0.0001
	for v in buf:
		peak = maxf(peak, absf(v))
	var gain := minf(0.9 / peak, 4.0)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(clampf(buf[i] * gain, -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = bytes
	if loop:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = n
	return s


func _white() -> float:
	return _rng.randf() * 2.0 - 1.0


## brown noise integrator state
var _brown := 0.0
func _brown_noise() -> float:
	_brown = clampf(_brown + _white() * 0.04, -1.0, 1.0) * 0.998
	return _brown


func _lp(prev: float, x: float, a: float) -> float:
	return prev + a * (x - prev)


func _alpha(cut_hz: float) -> float:
	var rc := 1.0 / (TAU * cut_hz)
	var dt := 1.0 / RATE
	return dt / (rc + dt)


# ----------------------------------------------------------------- recipes

## Magnetic-ballast fluorescent buzz: 120 Hz family + rasp, gentle flutter.
func _fluorescent(p: Dictionary) -> AudioStreamWAV:
	var secs: float = p.get("seconds", 2.0)
	var base: float = p.get("base", 60.0)
	var rasp: float = p.get("rasp", 0.35)
	var n := int(secs * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var hp := 0.0
	var lpv := 0.0
	var a := _alpha(3200.0)
	for i in n:
		var t := float(i) / RATE
		var v := 0.55 * sin(TAU * base * 2.0 * t) + 0.25 * sin(TAU * base * 4.0 * t + 0.4) \
			+ 0.12 * sin(TAU * base * 6.0 * t + 1.1) + 0.06 * sin(TAU * base * 1.0 * t)
		var mod := 0.5 + 0.5 * sin(TAU * base * 2.0 * t)
		var nz := _white()
		lpv = _lp(lpv, nz, a)
		hp = nz - lpv
		v += rasp * hp * pow(mod, 6.0)
		v *= 0.92 + 0.08 * sin(TAU * 0.5 * t)
		buf[i] = v
	return _to_stream(buf, true)


## Air handling / room tone: brown + pink-ish noise, low-passed.
func _room_tone(p: Dictionary) -> AudioStreamWAV:
	var secs: float = p.get("seconds", 4.0)
	var cut: float = p.get("cutoff", 380.0)
	var rumble: float = p.get("rumble", 0.0)
	var n := int(secs * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n + 4096)
	var l1 := 0.0
	var l2 := 0.0
	var a := _alpha(cut)
	for i in buf.size():
		var t := float(i) / RATE
		l1 = _lp(l1, _white(), a)
		l2 = _lp(l2, l1, a)
		var v := l2 * 3.0 + _brown_noise() * 0.35
		if rumble > 0.0:
			v += rumble * sin(TAU * 31.0 * t) * (0.6 + 0.4 * sin(TAU * 0.13 * t))
		buf[i] = v
	return _to_stream(buf, true, 4096)


## Lapping water: slow swells of filtered noise with small glassy plips.
func _water_bed(p: Dictionary) -> AudioStreamWAV:
	var secs: float = p.get("seconds", 6.0)
	var bright: float = p.get("bright", 900.0)
	var n := int(secs * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n + 6000)
	var l1 := 0.0
	var l2 := 0.0
	var a := _alpha(bright)
	var plip_t := -1.0
	var plip_f := 900.0
	for i in buf.size():
		var t := float(i) / RATE
		l1 = _lp(l1, _white(), a)
		l2 = _lp(l2, l1, a * 0.5)
		var swell := 0.45 + 0.35 * sin(TAU * 0.21 * t) + 0.2 * sin(TAU * 0.47 * t + 1.3)
		var v := (l1 - l2) * 4.0 * swell + l2 * 1.5
		if _rng.randf() < 0.00012:
			plip_t = t
			plip_f = _rng.randf_range(700.0, 1500.0)
		if plip_t >= 0.0:
			var dt := t - plip_t
			if dt < 0.12:
				v += 0.35 * sin(TAU * plip_f * (1.0 + dt * 3.0) * dt) * exp(-dt * 40.0)
		buf[i] = v
	return _to_stream(buf, true, 6000)


func _drip(p: Dictionary) -> AudioStreamWAV:
	var n := int(0.5 * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var f0: float = p.get("freq", 1100.0)
	for i in n:
		var t := float(i) / RATE
		var f := f0 * (1.0 - 0.45 * minf(t * 12.0, 1.0))
		buf[i] = sin(TAU * f * t) * exp(-t * 18.0) + 0.05 * _white() * exp(-t * 60.0)
	return _to_stream(buf, false)


## Footsteps per surface family. 'variant' gives non-identical repeats.
func _footstep(p: Dictionary) -> AudioStreamWAV:
	var surf: String = p.get("surface", "carpet")
	var variant: int = p.get("variant", 0)
	_rng.seed = hash(surf) + variant * 7919
	var dur := 0.28
	var n := int(dur * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var cut := 600.0
	var decay := 30.0
	var ring := 0.0
	var ring_f := 0.0
	var sweep := 0.0
	match surf:
		"carpet": cut = 380.0; decay = 34.0
		"concrete": cut = 2200.0; decay = 45.0; ring = 0.08; ring_f = 180.0
		"tile": cut = 4200.0; decay = 55.0; ring = 0.25; ring_f = 2400.0
		"metal": cut = 3000.0; decay = 22.0; ring = 0.45; ring_f = 520.0
		"wood": cut = 1400.0; decay = 30.0; ring = 0.3; ring_f = 210.0
		"water": cut = 2600.0; decay = 9.0; sweep = 1.0
		"grass": cut = 3200.0; decay = 20.0
		"dirt": cut = 1500.0; decay = 26.0
		"snow": cut = 2600.0; decay = 14.0
		"sand": cut = 2200.0; decay = 16.0
		"plush": cut = 260.0; decay = 40.0
	cut *= _rng.randf_range(0.85, 1.15)
	var a := _alpha(cut)
	var l := 0.0
	for i in n:
		var t := float(i) / RATE
		l = _lp(l, _white(), a)
		var env := exp(-t * decay) * minf(t * 400.0, 1.0)
		var v := l * env * 2.5
		if surf in ["grass", "dirt", "snow", "sand"]:
			v *= 0.6 + 0.8 * _rng.randf()  # granular crunch
		if ring > 0.0:
			v += ring * sin(TAU * ring_f * t) * exp(-t * decay * 0.8)
		if sweep > 0.0:
			v += 0.4 * sin(TAU * (300.0 + 900.0 * t) * t) * exp(-t * 12.0) * _rng.randf_range(0.6, 1.0)
		buf[i] = v
	return _to_stream(buf, false)


func _wind(p: Dictionary) -> AudioStreamWAV:
	var secs: float = p.get("seconds", 8.0)
	var n := int(secs * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n + 8000)
	var l1 := 0.0
	var l2 := 0.0
	for i in buf.size():
		var t := float(i) / RATE
		var gust := 0.5 + 0.3 * sin(TAU * 0.09 * t) + 0.2 * sin(TAU * 0.23 * t + 2.0)
		var cut := 300.0 + 700.0 * gust
		l1 = _lp(l1, _white(), _alpha(cut))
		l2 = _lp(l2, l1, _alpha(cut * 0.5))
		buf[i] = (l1 - l2) * 3.0 * gust + l2 * 0.6
	return _to_stream(buf, true, 8000)


func _crickets(p: Dictionary) -> AudioStreamWAV:
	var secs: float = p.get("seconds", 6.0)
	var n := int(secs * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var voices := []
	for k in 5:
		voices.append({"f": _rng.randf_range(3800.0, 5200.0), "rate": _rng.randf_range(1.2, 2.6),
			"ph": _rng.randf() * 10.0, "amp": _rng.randf_range(0.15, 0.4)})
	var bed := 0.0
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for vc in voices:
			var cyc := fmod(t * vc["rate"] + vc["ph"], 1.0)
			if cyc < 0.25:
				var pulse := 0.5 + 0.5 * sin(TAU * 32.0 * t)
				v += vc["amp"] * sin(TAU * vc["f"] * t) * pulse * sin(PI * cyc / 0.25)
		bed = _lp(bed, _white(), 0.02)
		buf[i] = v + bed * 0.4
	return _to_stream(buf, true)


## Electrical substation drone (Level 3 family): 50/60 Hz + strong 2nd/3rd.
func _transformer(p: Dictionary) -> AudioStreamWAV:
	var base: float = p.get("base", 60.0)
	var n := int(2.0 * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for i in n:
		var t := float(i) / RATE
		var v := 0.7 * sin(TAU * base * 2.0 * t) + 0.45 * sin(TAU * base * 3.0 * t) \
			+ 0.3 * sin(TAU * base * 4.0 * t) + 0.15 * sin(TAU * base * 6.0 * t)
		v = tanh(v * 1.6)
		buf[i] = v * (0.85 + 0.15 * sin(TAU * 0.25 * t))
	return _to_stream(buf, true)


func _crackle(p: Dictionary) -> AudioStreamWAV:
	var n := int(p.get("seconds", 1.2) * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var energy := 0.0
	for i in n:
		if _rng.randf() < 0.004:
			energy = _rng.randf_range(0.5, 1.0)
		energy *= 0.993
		buf[i] = _white() * energy * (1.0 if _rng.randf() < 0.3 else 0.2)
	return _to_stream(buf, false)


func _clank(p: Dictionary) -> AudioStreamWAV:
	var n := int(1.6 * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var fs := [p.get("f", 310.0), p.get("f", 310.0) * 2.76, p.get("f", 310.0) * 5.4]
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for k in fs.size():
			v += sin(TAU * fs[k] * t) * exp(-t * (3.0 + k * 3.0)) / (k + 1.0)
		v += _white() * exp(-t * 80.0) * 0.6
		buf[i] = v
	return _to_stream(buf, false)


func _rain(p: Dictionary) -> AudioStreamWAV:
	var n := int(p.get("seconds", 5.0) * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n + 4000)
	var l := 0.0
	for i in buf.size():
		l = _lp(l, _white(), 0.35)
		var drop := 0.0
		if _rng.randf() < 0.01:
			drop = _rng.randf_range(0.3, 1.0)
		buf[i] = l * 0.8 + drop * _white()
	return _to_stream(buf, true, 4000)


func _thunder(p: Dictionary) -> AudioStreamWAV:
	var secs: float = p.get("seconds", 5.0)
	var low: float = p.get("low", 1.0)
	var n := int(secs * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var l1 := 0.0
	var l2 := 0.0
	for i in n:
		var t := float(i) / RATE
		l1 = _lp(l1, _white(), _alpha(140.0 * low + 40.0))
		l2 = _lp(l2, l1, _alpha(90.0))
		var env := minf(t * 3.0, 1.0) * exp(-t * 0.9) * (0.7 + 0.3 * sin(TAU * 1.7 * t))
		buf[i] = (l1 * 2.0 + l2 * 4.0) * env
	return _to_stream(buf, false)


## Soft detuned pad: chord as semitone offsets from root (Hz).
func _pad(p: Dictionary) -> AudioStreamWAV:
	var root: float = p.get("root", 110.0)
	var chord: Array = p.get("chord", [0, 7, 12, 16])
	var secs: float = p.get("seconds", 8.0)
	var bright: float = p.get("bright", 0.3)
	var n := int(secs * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var freqs := []
	for c in chord:
		var f := root * pow(2.0, float(c) / 12.0)
		freqs.append(f)
		freqs.append(f * 1.004)
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for f in freqs:
			var ph: float = TAU * f * t
			v += sin(ph) + bright * 0.3 * sin(2.0 * ph)
		buf[i] = v * (0.75 + 0.25 * sin(TAU * t / secs))
	return _to_stream(buf, true, 2000)


## Square/triangle tracker loop for Level 256 "Demoscene" and synth levels.
func _chiptune(p: Dictionary) -> AudioStreamWAV:
	var bpm: float = p.get("bpm", 132.0)
	var scale: Array = p.get("scale", [0, 3, 5, 7, 10, 12, 15])
	var root: float = p.get("root", 220.0)
	var bars := 4
	var step := 60.0 / bpm / 4.0
	var steps := bars * 16
	var n := int(steps * step * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var melody := []
	for k in steps:
		melody.append(scale[_rng.randi() % scale.size()] if _rng.randf() < 0.7 else -99)
	var bass := [0, 0, 7, 5]
	for i in n:
		var t := float(i) / RATE
		var si := int(t / step) % steps
		var lt := fmod(t, step)
		var v := 0.0
		var m: int = melody[si]
		if m != -99:
			var f := root * pow(2.0, float(m) / 12.0)
			v += (1.0 if fmod(t * f, 1.0) < 0.25 else -1.0) * 0.25 * exp(-lt * 6.0)
		var bar := int(si / 16) % 4
		var bf := root * 0.25 * pow(2.0, float(bass[bar]) / 12.0)
		var tri := 4.0 * absf(fmod(t * bf, 1.0) - 0.5) - 1.0
		v += tri * 0.35
		if si % 4 == 0 and lt < 0.05:
			v += _white() * 0.3 * (1.0 - lt / 0.05)
		buf[i] = v
	return _to_stream(buf, true)


func _static(p: Dictionary) -> AudioStreamWAV:
	var n := int(p.get("seconds", 3.0) * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n + 2000)
	var l := 0.0
	for i in buf.size():
		var t := float(i) / RATE
		l = _lp(l, _white(), 0.5)
		buf[i] = l * (0.6 + 0.4 * sin(TAU * 0.7 * t)) + 0.1 * sin(TAU * 1000.0 * t) * (1.0 if fmod(t, 1.3) < 0.05 else 0.0)
	return _to_stream(buf, true, 2000)


func _creak(p: Dictionary) -> AudioStreamWAV:
	var n := int(1.4 * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var f0: float = p.get("freq", 140.0)
	for i in n:
		var t := float(i) / RATE
		var f := f0 * (1.0 + 0.25 * sin(TAU * 0.8 * t))
		var saw := fmod(t * f, 1.0) * 2.0 - 1.0
		var grit := 1.0 if _rng.randf() < 0.6 else 0.3
		buf[i] = saw * grit * sin(PI * t / 1.4) * 0.6
	return _to_stream(buf, false)


func _ui(p: Dictionary) -> AudioStreamWAV:
	var kind: String = p.get("kind", "click")
	var n := int(0.12 * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var f := 880.0 if kind == "click" else (660.0 if kind == "hover" else 520.0)
	for i in n:
		var t := float(i) / RATE
		buf[i] = sin(TAU * f * t) * exp(-t * 45.0) * 0.5
	return _to_stream(buf, false)


func _splash(_p: Dictionary) -> AudioStreamWAV:
	var n := int(0.9 * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var l := 0.0
	for i in n:
		var t := float(i) / RATE
		l = _lp(l, _white(), 0.3)
		buf[i] = l * exp(-t * 5.0) * 2.0 + 0.3 * sin(TAU * (400.0 + 600.0 * t) * t) * exp(-t * 9.0)
	return _to_stream(buf, false)


func _knock(p: Dictionary) -> AudioStreamWAV:
	var n := int(1.2 * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var hits: int = p.get("hits", 3)
	for h in hits:
		var start := int(h * 0.28 * RATE)
		for i in range(start, mini(n, start + int(0.2 * RATE))):
			var t := float(i - start) / RATE
			buf[i] += (0.8 * sin(TAU * 140.0 * t) + 0.4 * _white()) * exp(-t * 30.0)
	return _to_stream(buf, false)


func _music_box(p: Dictionary) -> AudioStreamWAV:
	var notes: Array = p.get("notes", [0, 4, 7, 12, 7, 4, 2, 5, 9, 14, 9, 5])
	var root: float = p.get("root", 523.25)
	var step := 0.42
	var n := int(notes.size() * step * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for k in notes.size():
		var f := root * pow(2.0, float(notes[k]) / 12.0)
		var start := int(k * step * RATE)
		for i in range(start, mini(n, start + int(1.2 * RATE))):
			var t := float(i - start) / RATE
			buf[i] += (sin(TAU * f * t) + 0.3 * sin(TAU * f * 3.01 * t)) * exp(-t * 4.0)
	return _to_stream(buf, true)


func _heartbeat(_p: Dictionary) -> AudioStreamWAV:
	var n := int(1.0 * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	for beat in [0.0, 0.28]:
		var start := int(beat * RATE)
		for i in range(start, mini(n, start + int(0.18 * RATE))):
			var t := float(i - start) / RATE
			buf[i] += sin(TAU * 52.0 * t) * exp(-t * 22.0)
	return _to_stream(buf, true)


## Breathy, syllabic noise — indistinct whispering (no words are synthesised).
func _whisper(p: Dictionary) -> AudioStreamWAV:
	var secs: float = p.get("seconds", 2.4)
	var n := int(secs * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var l1 := 0.0
	var l2 := 0.0
	var syl := _rng.randf_range(3.5, 5.5)
	for i in n:
		var t := float(i) / RATE
		var nz := _white()
		l1 = _lp(l1, nz, _alpha(3200.0))
		l2 = _lp(l2, l1, _alpha(900.0))
		var band := l1 - l2
		var env := pow(maxf(0.0, sin(PI * fmod(t * syl, 1.0))), 2.0) * sin(PI * t / secs)
		var formant := 0.6 + 0.4 * sin(TAU * (1.3 + 0.7 * sin(t * 2.1)) * t)
		buf[i] = band * env * formant * 2.0
	return _to_stream(buf, false)


## Fingernail scratching behind a wall: bursts of gritty high noise.
func _scratch(p: Dictionary) -> AudioStreamWAV:
	var secs: float = p.get("seconds", 1.8)
	var n := int(secs * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var l := 0.0
	var strokes := 4 + _rng.randi() % 4
	for s in strokes:
		var st := int(_rng.randf_range(0.0, secs - 0.3) * RATE)
		var ln := int(_rng.randf_range(0.12, 0.3) * RATE)
		for i in range(st, mini(n, st + ln)):
			var t := float(i - st) / ln
			l = _lp(l, _white(), 0.6)
			var grit := 1.0 if _rng.randf() < 0.35 else 0.15
			buf[i] += (_white() - l) * grit * sin(PI * t) * 0.8
	return _to_stream(buf, false)
