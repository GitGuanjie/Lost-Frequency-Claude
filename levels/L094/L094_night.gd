extends RefCounted
## Level 94 cycle, music and the night.
## Day: the siren poles play happy cartoon music now and then; the town is
## safe and empty. Night: the music stops completely; the Animations come out
## and hunt anything they spot that is not animated; Death Rats, drawn in the
## same stepped stop-motion style, scurry along the walls. Houses hide you.
## Everything that moves here moves on "twos": poses change a few times a
## second, never smoothly (page: stop-motion feel).

const DAY_S := 360.0
const NIGHT_S := 180.0
const FPS := 8.0

var lv
var clock := 30.0
var night := 0.0
var is_night := false
var music: AudioStream
var players: Array = []
var music_t := 8.0
var music_on := false
var music_left := 0.0
var anims: Array = []        # {node, home, pos, yaw, state, t}
var rats: Array = []
var anim_mesh: ArrayMesh
var rat_mesh: ArrayMesh
var ink: StandardMaterial3D
var eye: StandardMaterial3D
var _step_t := 0.0
var spotted := 0.0
var said := {}
var frozen := false


func _init(level) -> void:
	lv = level
	ink = StandardMaterial3D.new()
	ink.albedo_color = Color(0.015, 0.012, 0.012)
	ink.roughness = 0.6
	eye = StandardMaterial3D.new()
	eye.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	eye.albedo_color = Color(0.95, 0.93, 0.85)
	anim_mesh = _figure()
	rat_mesh = _rat()


# ---------------------------------------------------------------- shapes

func _box(st: SurfaceTool, c: Vector3, s: Vector3, rot := 0.0) -> void:
	var b := Basis(Vector3(0, 0, 1), rot)
	var h := s * 0.5
	var faces := [[Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)], [Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, -1)],
		[Vector3(0, 1, 0), Vector3(0, 0, 1), Vector3(1, 0, 0)], [Vector3(0, -1, 0), Vector3(0, 0, -1), Vector3(1, 0, 0)],
		[Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)], [Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, 1, 0)]]
	for f in faces:
		var n: Vector3 = f[0]
		var u: Vector3 = f[1]
		var v: Vector3 = f[2]
		var cc := c + b * (n * h)
		var uu := b * (u * h)
		var vv := b * (v * h)
		var q := [cc - uu - vv, cc + uu - vv, cc + uu + vv, cc - uu + vv]
		for idx in [0, 2, 1, 0, 3, 2]:
			st.set_normal(b * n)
			st.add_vertex(q[idx])


## A rubber-hose cartoon figure (~1.8 m): pie-cut head with ears, a bean body,
## noodle limbs, big gloved hands. Ink black; the eyes are separate nodes.
func _figure() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_box(st, Vector3(0, 1.0, 0), Vector3(0.5, 0.55, 0.3))
	_box(st, Vector3(0, 1.45, 0), Vector3(0.46, 0.42, 0.36))
	for s in [-1.0, 1.0]:
		_box(st, Vector3(s * 0.2, 1.75, 0), Vector3(0.22, 0.22, 0.06))
		_box(st, Vector3(s * 0.12, 0.42, 0), Vector3(0.08, 0.84, 0.08), s * 0.08)
		_box(st, Vector3(s * 0.14, 0.04, 0.08), Vector3(0.18, 0.08, 0.3))
		_box(st, Vector3(s * 0.36, 0.95, 0), Vector3(0.07, 0.6, 0.07), s * 0.5)
		_box(st, Vector3(s * 0.5, 0.68, 0), Vector3(0.16, 0.16, 0.12))
	return st.commit()


func _rat() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_box(st, Vector3(0, 0.07, 0), Vector3(0.1, 0.09, 0.22))
	_box(st, Vector3(0, 0.08, 0.13), Vector3(0.07, 0.06, 0.08))
	_box(st, Vector3(0, 0.05, -0.2), Vector3(0.015, 0.015, 0.22))
	return st.commit()


# ---------------------------------------------------------------- music

## A jaunty cartoon two-step: xylophone tune over an oom-pah bass.
func build_music() -> void:
	var rate := 16000
	var bpm := 132.0
	var beat := 60.0 / bpm
	var tune := [0, 4, 7, 12, 11, 7, 9, -99, 7, 4, 5, 7, 4, 0, 2, -99, 0, 4, 7, 12, 14, 12, 9, 7, 5, 9, 7, 4, 2, 4, 0, -99]
	var bass := [0, 7, 5, 7, 0, 7, 5, 7]
	var steps := tune.size() * 2
	var n := int(steps * beat * 0.5 * rate)
	var buf := PackedFloat32Array()
	buf.resize(n)
	var root := 523.25
	for k in tune.size() * 2:
		var m: int = tune[k % tune.size()]
		if m == -99:
			continue
		var f := root * pow(2.0, float(m) / 12.0)
		var s0 := int(k * beat * 0.5 * rate)
		for i in range(s0, mini(n, s0 + int(0.35 * rate))):
			var t := float(i - s0) / rate
			buf[i] += (sin(TAU * f * t) + 0.35 * sin(TAU * f * 4.0 * t) * exp(-t * 30.0)) * exp(-t * 9.0) * 0.32
	for b in int(steps / 2):
		var m2: int = bass[b % bass.size()]
		var f2 := 130.81 * pow(2.0, float(m2) / 12.0) * (0.5 if b % 2 == 0 else 1.0)
		var s1 := int(b * beat * rate)
		for i in range(s1, mini(n, s1 + int(0.22 * rate))):
			var t := float(i - s1) / rate
			var sq := 1.0 if fmod(f2 * t, 1.0) < 0.5 else -1.0
			buf[i] += sq * exp(-t * 14.0) * 0.12
		if b % 2 == 1:
			var s2 := s1
			for i in range(s2, mini(n, s2 + int(0.05 * rate))):
				buf[i] += (randf() * 2.0 - 1.0) * exp(-float(i - s2) / rate * 80.0) * 0.08
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		data.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_end = n
	music = w


func add_speaker(pos: Vector3) -> void:
	var pl := AudioStreamPlayer3D.new()
	pl.stream = music
	pl.bus = "Ambience"
	pl.unit_size = 18.0
	pl.max_distance = 220.0
	pl.volume_db = -4.0
	pl.position = pos
	lv.add_child(pl)
	players.append(pl)


# ---------------------------------------------------------------- figures

func spawn(parent: Node3D, homes: Array) -> void:
	for h in homes:
		var n := Node3D.new()
		n.name = "Animation"
		var body := MeshInstance3D.new()
		body.mesh = anim_mesh
		body.material_override = ink
		n.add_child(body)
		for s in [-1.0, 1.0]:
			var e := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.075
			sm.height = 0.2
			sm.radial_segments = 8
			sm.rings = 4
			e.mesh = sm
			e.material_override = eye
			e.position = Vector3(s * 0.09, 1.5, 0.18)
			n.add_child(e)
			var gl := MeshInstance3D.new()
			var gm := SphereMesh.new()
			gm.radius = 0.11
			gm.height = 0.2
			gm.radial_segments = 8
			gm.rings = 4
			gl.mesh = gm
			gl.material_override = eye
			gl.position = Vector3(s * 0.5, 0.68, 0.0)
			n.add_child(gl)
		var face := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3(0.34, 0.2, 0.04)
		face.mesh = fm
		face.material_override = eye
		face.position = Vector3(0, 1.36, 0.17)
		n.add_child(face)
		n.position = h
		n.visible = false
		parent.add_child(n)
		anims.append({"node": n, "home": h, "pos": h, "yaw": 0.0, "state": "idle", "t": 0.0})
	for i in 10:
		var rn := MeshInstance3D.new()
		rn.mesh = rat_mesh
		rn.material_override = ink
		rn.visible = false
		parent.add_child(rn)
		rats.append({"node": rn, "pos": Vector3.ZERO, "dir": Vector3.FORWARD, "t": 0.0})


func tick(delta: float, pp: Vector3, indoors: bool) -> void:
	var qa := SessionState.is_qa()
	if not qa and not frozen:
		clock = fmod(clock + delta, DAY_S + NIGHT_S)
	var target := 0.0
	if clock > DAY_S:
		target = smoothstep(DAY_S, DAY_S + 25.0, clock) * (1.0 - smoothstep(DAY_S + NIGHT_S - 25.0, DAY_S + NIGHT_S, clock))
	night = target
	var was := is_night
	is_night = night > 0.5
	if is_night != was:
		_turn(is_night)
	_music(delta, qa)
	_step_t += delta
	if _step_t >= 1.0 / FPS:
		var dt := _step_t
		_step_t = 0.0
		_figures(dt, pp, indoors, qa)


func _turn(to_night: bool) -> void:
	if to_night:
		for pl in players:
			(pl as AudioStreamPlayer3D).stop()
		music_on = false
		for a in anims:
			a["node"].visible = true
			a["pos"] = a["home"]
			a["state"] = "patrol"
		for rt in rats:
			rt["node"].visible = true
			var h: Vector3 = lv.town.houses[lv.rng.randi() % lv.town.houses.size()]["front"]
			rt["pos"] = h + Vector3(lv.rng.randf_range(-3, 3), 0.17, lv.rng.randf_range(-3, 3))
		if not SessionState.is_qa():
			Overlay.subtitle("[the music stops. All of it, all at once.]", 4.0)
	else:
		for a in anims:
			a["node"].visible = false
		for rt in rats:
			rt["node"].visible = false
		spotted = 0.0
		if not SessionState.is_qa():
			Overlay.subtitle("[daylight comes back on like a lamp being switched on]", 4.0)


func _music(delta: float, qa: bool) -> void:
	if is_night:
		return
	if music_on:
		music_left -= delta
		if music_left <= 0.0:
			music_on = false
			for pl in players:
				(pl as AudioStreamPlayer3D).stop()
			music_t = lv.rng.randf_range(45.0, 90.0)
		return
	music_t -= delta
	if music_t <= 0.0:
		music_on = true
		music_left = lv.rng.randf_range(25.0, 40.0)
		for pl in players:
			(pl as AudioStreamPlayer3D).play()
		if not qa and not said.has("music"):
			said["music"] = true
			Overlay.subtitle("[the siren poles crackle and break into a happy cartoon tune]", 4.0)


func _figures(dt: float, pp: Vector3, indoors: bool, qa: bool) -> void:
	if not is_night:
		return
	var seen := false
	for a in anims:
		var n: Node3D = a["node"]
		var pos: Vector3 = a["pos"]
		var to := Vector3(pp.x - pos.x, 0, pp.z - pos.z)
		var dist := to.length()
		var fwd := Vector3(sin(a["yaw"]), 0, cos(a["yaw"]))
		var can_see: bool = not indoors and dist < 24.0 and (dist < 6.0 or fwd.dot(to / maxf(dist, 0.01)) > 0.3)
		if can_see:
			a["state"] = "chase"
			seen = true
		elif a["state"] == "chase" and (indoors or dist > 34.0):
			a["state"] = "patrol"
		var goal: Vector3
		var speed := 1.4
		if a["state"] == "chase":
			goal = pp
			speed = 4.6
		else:
			a["t"] -= dt
			if a["t"] <= 0.0:
				a["t"] = lv.rng.randf_range(3.0, 7.0)
				a["goal"] = (a["home"] as Vector3) + Vector3(lv.rng.randf_range(-12, 12), 0, lv.rng.randf_range(-12, 12))
			goal = a.get("goal", a["home"])
		var g := Vector3(goal.x - pos.x, 0, goal.z - pos.z)
		if g.length() > 0.3:
			a["yaw"] = atan2(g.x, g.z)
			pos += g.normalized() * minf(speed * dt, g.length())
		pos.y = lv.land.h(pos.x, pos.z) + 0.02
		a["pos"] = pos
		# pose on twos: a bob and a lean that jump between drawings
		n.position = pos + Vector3(0, 0.06 * float(int(lv.clock_frames()) % 2), 0)
		n.rotation = Vector3(0, a["yaw"], 0.08 * (1.0 if int(lv.clock_frames()) % 2 == 0 else -1.0))
		if a["state"] == "chase" and dist < 1.3 and not qa:
			lv.player.hurt(1000.0, "Level 94: an Animation caught you at night")
	if seen:
		spotted += dt
		if not said.has("spotted") and not qa:
			said["spotted"] = true
			Overlay.subtitle("[one of the Animations has seen you. Get indoors.]", 4.0)
	for rt in rats:
		var rp: Vector3 = rt["pos"]
		rt["t"] -= dt
		if rt["t"] <= 0.0:
			rt["t"] = lv.rng.randf_range(0.5, 2.0)
			var a2: float = lv.rng.randf() * TAU
			rt["dir"] = Vector3(cos(a2), 0, sin(a2))
		rp += (rt["dir"] as Vector3) * 1.6 * dt
		rt["pos"] = rp
		var rn: Node3D = rt["node"]
		rn.position = rp
		rn.rotation.y = atan2(rt["dir"].x, rt["dir"].z)
