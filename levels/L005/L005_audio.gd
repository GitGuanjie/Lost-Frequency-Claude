extends RefCounted
## Level 5 sound system, synthesised in-project (no samples): quiet smooth jazz
## for the hall turntables/speakers and the muffled party behind the walls. Built
## once per run on a worker thread at 11.025 kHz, the band-limited, crackling
## range of a 1930s turntable speaker. Track choice/switching is the level's job.

const R := 11025
const Q := {"M7": [0, 4, 7, 11, 14], "m7": [0, 3, 7, 10, 14], "7": [0, 4, 7, 10, 13], "m9": [0, 3, 7, 10, 14], "m7b5": [0, 3, 6, 10, 13]}

var tracks: Array = []
var chatter: AudioStreamWAV = null
var done := false
var task := -1
var _s := 12345


func start() -> void:
	task = WorkerThreadPool.add_task(_build)


func is_ready() -> bool:
	if done and task >= 0:
		WorkerThreadPool.wait_for_task_completion(task)
		task = -1
	return done


func _build() -> void:
	var specs := [
		{"key": 174.61, "bpm": 84.0, "seed": 11, "prog": [[0, "M7"], [9, "m7"], [2, "m7"], [7, "7"], [4, "m7"], [9, "7"], [2, "m7"], [7, "7"]]},
		{"key": 146.83, "bpm": 96.0, "seed": 23, "prog": [[0, "m9"], [0, "m9"], [5, "m9"], [5, "m9"], [4, "m7b5"], [9, "7"], [0, "m9"], [9, "7"]]},
		{"key": 233.08, "bpm": 116.0, "seed": 37, "prog": [[0, "M7"], [9, "7"], [2, "m7"], [7, "7"], [4, "m7"], [9, "7"], [2, "m7"], [7, "7"]]},
	]
	var out := []
	for sp in specs:
		out.append(_jazz(sp))
	var ch := _chatter()
	tracks = out
	chatter = ch
	done = true


func _noise() -> float:
	_s = (_s * 1103515245 + 12345) & 0x7fffffff
	return float(_s) / 1073741823.5 - 1.0


static func _hz(base: float, semi: int, lo: float) -> float:
	var f := base * pow(2.0, semi / 12.0)
	while f < lo:
		f *= 2.0
	while f >= lo * 2.0:
		f *= 0.5
	return f


func _jazz(sp: Dictionary) -> AudioStreamWAV:
	var r := RandomNumberGenerator.new()
	r.seed = sp["seed"]
	_s = int(sp["seed"]) * 7919
	var beat := 60.0 / float(sp["bpm"])
	var prog: Array = sp["prog"]
	var bars := prog.size()
	var n := int(bars * 4 * beat * R)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var key: float = sp["key"]
	var sw := 0.64
	for bar in bars:
		var root: int = prog[bar][0]
		var iv: Array = Q[prog[bar][1]]
		var nxt: int = prog[(bar + 1) % bars][0]
		for b in 4:
			var t0 := (bar * 4 + b) * beat
			var semi := root
			if b == 1:
				semi = root + int(iv[1 + r.randi() % 2])
			elif b == 2:
				semi = root + (int(iv[2]) if r.randf() < 0.6 else int(iv[3]) - 12)
			elif b == 3:
				semi = nxt + (1 if r.randf() < 0.5 else -1)
			_pluck(buf, t0, _hz(key * 0.25, semi, 55.0), beat * 0.98, 0.5)
			_ride(buf, t0, 0.07 if b % 2 == 0 else 0.09)
			if b % 2 == 1:
				_ride(buf, t0 + beat * sw, 0.05)
				_brush(buf, t0, beat * 0.5, 0.05)
			if r.randf() < (0.32 if b == 0 else 0.5):
				var tc := t0 + (beat * sw if r.randf() < 0.55 else 0.0)
				for v in [1, 3, 4]:
					_rhodes(buf, tc, _hz(key, root + int(iv[v]), 233.0), beat * 1.4, 0.09)
	_melody(buf, sp, r, beat, sw)
	_gramophone(buf, 3100.0, 170.0, 0.0006)
	return _wav(buf)


func _pluck(buf: PackedFloat32Array, t0: float, f: float, dur: float, amp: float) -> void:
	var n := buf.size()
	var i0 := int(t0 * R)
	var w := TAU * f / R
	for i in int(dur * R):
		var t := float(i) / R
		var env := minf(t * 160.0, 1.0) * exp(-t * 3.0)
		var j := (i0 + i) % n
		buf[j] += amp * env * (sin(w * i) + 0.3 * sin(2.0 * w * i) * exp(-t * 7.0))


func _ride(buf: PackedFloat32Array, t0: float, amp: float) -> void:
	var n := buf.size()
	var i0 := int(t0 * R)
	var w1 := TAU * 2950.0 / R
	var w2 := TAU * 3710.0 / R
	var w3 := TAU * 4630.0 / R
	for i in int(0.42 * R):
		var t := float(i) / R
		var e := exp(-t * 8.5)
		buf[(i0 + i) % n] += amp * e * (0.45 * sin(w1 * i) + 0.35 * sin(w2 * i) + 0.25 * sin(w3 * i) + 0.5 * _noise())


func _brush(buf: PackedFloat32Array, t0: float, dur: float, amp: float) -> void:
	var n := buf.size()
	var i0 := int(t0 * R)
	var lp := 0.0
	var lp2 := 0.0
	for i in int(dur * R):
		var t := float(i) / R
		var e := minf(t / 0.05, 1.0) * exp(-t * 7.0)
		lp += 0.45 * (_noise() - lp)
		lp2 += 0.08 * (lp - lp2)
		buf[(i0 + i) % n] += amp * e * (lp - lp2) * 2.0


func _rhodes(buf: PackedFloat32Array, t0: float, f: float, dur: float, amp: float) -> void:
	var n := buf.size()
	var i0 := int(t0 * R)
	var w := TAU * f / R
	for i in int(dur * R):
		var t := float(i) / R
		var idx := 0.25 + 1.3 * exp(-t * 6.0)
		var e := minf(t * 300.0, 1.0) * exp(-t * 2.2)
		buf[(i0 + i) % n] += amp * e * sin(w * i + idx * sin(w * i))


func _vibe(buf: PackedFloat32Array, t0: float, f: float, dur: float, amp: float) -> void:
	var n := buf.size()
	var i0 := int(t0 * R)
	var w := TAU * f / R
	for i in int(dur * R):
		var t := float(i) / R
		var e := minf(t * 250.0, 1.0) * exp(-t * 2.0) * (0.78 + 0.22 * sin(TAU * 5.2 * t))
		buf[(i0 + i) % n] += amp * e * (sin(w * i) + 0.12 * sin(4.0 * w * i) * exp(-t * 9.0))


func _melody(buf: PackedFloat32Array, sp: Dictionary, r: RandomNumberGenerator, beat: float, sw: float) -> void:
	var prog: Array = sp["prog"]
	var key: float = sp["key"]
	var deg := 7
	for bar in prog.size():
		if bar % 2 == 1 and r.randf() < 0.55:
			continue
		var iv: Array = Q[prog[bar][1]]
		var root: int = prog[bar][0]
		var notes := 3 + r.randi() % 5
		var start := r.randi() % 3
		for q in notes:
			var slot := start + q
			if slot >= 8:
				break
			var b := slot / 2
			var t := (bar * 4 + b) * beat + (beat * sw if slot % 2 == 1 else 0.0)
			deg = clampi(deg + [-2, -1, 1, 2, 3, -3][r.randi() % 6], 0, 12)
			var semi := root + int(iv[deg % 5]) + 12 * (deg / 5)
			var hold := beat * (1.6 if q == notes - 1 else 0.7)
			_vibe(buf, t, _hz(key * 2.0, semi, 330.0), hold, 0.16)


## Turntable speaker: band-limit, soft saturation, surface crackle and hiss.
func _gramophone(buf: PackedFloat32Array, lp_hz: float, hp_hz: float, crackle: float) -> void:
	var a_lp := 1.0 - exp(-TAU * lp_hz / R)
	var a_hp := exp(-TAU * hp_hz / R)
	var hp := 0.0
	var prev := 0.0
	var l1 := 0.0
	var l2 := 0.0
	var peak := 0.0001
	for v in buf:
		peak = maxf(peak, absf(v))
	var g := 0.8 / peak
	for i in buf.size():
		var x := buf[i] * g
		hp = a_hp * (hp + x - prev)
		prev = x
		l1 += a_lp * (hp - l1)
		l2 += a_lp * (l1 - l2)
		var y := tanh(l2 * 1.3)
		if crackle > 0.0:
			var z := _noise()
			if absf(z) < crackle:
				y += z / crackle * 0.25
			y += _noise() * 0.006
		buf[i] = y


func _wav(buf: PackedFloat32Array) -> AudioStreamWAV:
	var peak := 0.0001
	for v in buf:
		peak = maxf(peak, absf(v))
	var g := 0.9 / peak
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in buf.size():
		bytes.encode_s16(i * 2, int(clampf(buf[i] * g, -1.0, 1.0) * 32767.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = R
	s.stereo = false
	s.data = bytes
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = buf.size()
	return s


## Muffled party beyond a wall: overlapping voices, laughter, glasses.
func _chatter() -> AudioStreamWAV:
	var secs := 7.0
	var n := int(secs * R)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var r := RandomNumberGenerator.new()
	r.seed = 99
	for v in 7:
		var f0 := r.randf_range(92.0, 235.0)
		var t := r.randf() * 0.6
		while t < secs:
			var syl := r.randf_range(0.08, 0.2)
			_syllable(buf, t, syl, f0 * r.randf_range(0.9, 1.12), r.randf_range(300.0, 780.0), r.randf_range(950.0, 2200.0), r.randf_range(0.1, 0.22))
			t += syl + (r.randf_range(0.02, 0.07) if r.randf() < 0.8 else r.randf_range(0.35, 1.0))
	for q in 3:
		var t := r.randf_range(0.3, secs - 1.2)
		var f0 := r.randf_range(230.0, 300.0)
		for h in 5:
			_syllable(buf, t + h * 0.17, 0.12, f0 * (1.0 - h * 0.03), 720.0, 1250.0, 0.28 - h * 0.03)
	_gramophone(buf, 760.0, 120.0, 0.0)
	for q in 5:
		var i0 := int(r.randf_range(0.0, secs - 0.5) * R)
		var w := TAU * r.randf_range(2600.0, 3400.0) / R
		for i in int(0.35 * R):
			var t := float(i) / R
			buf[(i0 + i) % n] += 0.05 * exp(-t * 14.0) * sin(w * i)
	return _wav(buf)


func _syllable(buf: PackedFloat32Array, t0: float, dur: float, f0: float, F1: float, F2: float, amp: float) -> void:
	var n := buf.size()
	var i0 := int(t0 * R)
	var ph := 0.0
	var f1 := 2.0 * sin(PI * F1 / R)
	var f2 := 2.0 * sin(PI * F2 / R)
	var lo1 := 0.0
	var bd1 := 0.0
	var lo2 := 0.0
	var bd2 := 0.0
	var m := int(dur * R)
	for i in m:
		ph = fmod(ph + f0 / R, 1.0)
		var x := (2.0 * ph - 1.0) + 0.25 * _noise()
		lo1 += f1 * bd1
		var hi1 := x - lo1 - 0.25 * bd1
		bd1 += f1 * hi1
		lo2 += f2 * bd2
		var hi2 := x - lo2 - 0.3 * bd2
		bd2 += f2 * hi2
		var e := pow(sin(PI * float(i) / m), 1.5)
		buf[(i0 + i) % n] += amp * e * (bd1 + 0.6 * bd2) * 0.35
