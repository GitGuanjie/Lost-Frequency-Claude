extends Node3D
## Entity 49/1 "Trenchcleaner" as a scripted presence (never a fight): a
## ~3 m (10 ft) bipedal war machine with an eight-barrel chaingun, blue
## lights and a head beam. It appears some way off in the trench network,
## stalks along the trenches toward you (its lights and beam show above the
## parapets), sweeps, then withdraws. If it has a clear line of sight while
## you move, run, or show a light in the open, it spins up and fires a burst.
## Staying low, still, dark and in cover is the page's own advice.

const TR := preload("res://levels/L049/L049_trench.gd")
const SPEED := 1.25

var lvl
var path: Array = []          # world positions (trench floor), toward the player
var idx := 0
var state := "stalk"          # stalk | linger | leave | gone
var linger_t := 0.0
var spin := -1.0
var cool := 0.0
var step_t := 0.0
var phase := 0.0
var legs: Array = []
var gun: Node3D
var head: Node3D
var beam: SpotLight3D
var flash: OmniLight3D
var hum: AudioStreamPlayer3D
var seen_said := false


func setup(level, route: Array) -> void:
	lvl = level
	path = route
	global_position = path[0]
	_model()
	hum = AudioStreamPlayer3D.new()
	hum.stream = AudioSynth.get_stream("transformer", {"base": 73.0})
	hum.volume_db = -8.0
	hum.max_distance = 60.0
	hum.bus = "Ambience"
	add_child(hum)
	hum.play()


func _model() -> void:
	var k := GeoKit.new(self, "Body")
	k.box(Vector3(0, 2.15, 0), Vector3(1.3, 0.9, 1.0), "l49_tc_armor", GeoKit.ALL, false)
	k.box(Vector3(0, 1.62, 0), Vector3(0.9, 0.3, 0.8), "l49_tc_dark", GeoKit.ALL, false)
	k.box(Vector3(0, 2.75, -0.05), Vector3(0.6, 0.38, 0.62), "l49_tc_armor", GeoKit.ALL, false)
	k.box(Vector3(0, 2.75, -0.37), Vector3(0.44, 0.08, 0.02), "l49_tc_blue", GeoKit.ALL, false)
	for s: float in [-1.0, 1.0]:
		k.box(Vector3(s * 0.66, 2.35, -0.51), Vector3(0.08, 0.3, 0.02), "l49_tc_blue", GeoKit.ALL, false)
		k.box(Vector3(s * 0.8, 2.3, 0), Vector3(0.3, 0.5, 0.6), "l49_tc_dark", GeoKit.ALL, false)
	k.commit()
	for s: float in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(s * 0.42, 1.55, 0)
		add_child(pivot)
		var lk := GeoKit.new(pivot, "Leg")
		lk.box(Vector3(0, -0.4, 0.12), Vector3(0.26, 0.85, 0.3), "l49_tc_armor", GeoKit.ALL, false)
		lk.box(Vector3(0, -1.0, -0.05), Vector3(0.2, 0.7, 0.22), "l49_tc_dark", GeoKit.ALL, false)
		lk.box(Vector3(0, -1.47, -0.12), Vector3(0.36, 0.14, 0.56), "l49_tc_armor", GeoKit.ALL, false)
		lk.commit()
		legs.append(pivot)
	gun = Node3D.new()
	gun.position = Vector3(0.95, 2.0, -0.2)
	add_child(gun)
	var gk := GeoKit.new(gun, "Gun")
	gk.box(Vector3(0, 0, 0.1), Vector3(0.36, 0.36, 0.5), "l49_tc_dark", GeoKit.ALL, false)
	for i in 8:
		var a := TAU * i / 8.0
		gk.box(Vector3(cos(a) * 0.11, sin(a) * 0.11, -0.55), Vector3(0.045, 0.045, 1.0), "l49_steel", GeoKit.ALL, false)
	gk.commit()
	head = Node3D.new()
	head.position = Vector3(0, 2.75, -0.38)
	add_child(head)
	beam = SpotLight3D.new()
	beam.light_color = Color(0.75, 0.85, 1.0)
	beam.light_energy = 9.0
	beam.spot_range = 34.0
	beam.spot_angle = 16.0
	beam.shadow_enabled = false
	beam.rotation.x = deg_to_rad(-14.0)
	head.add_child(beam)
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.3, 0.55, 1.0)
	glow.light_energy = 1.6
	glow.omni_range = 5.0
	glow.position = Vector3(0, 2.4, -0.7)
	add_child(glow)
	flash = OmniLight3D.new()
	flash.light_color = Color(1.0, 0.8, 0.45)
	flash.omni_range = 9.0
	flash.light_energy = 0.0
	flash.position = gun.position + Vector3(0, 0, -1.2)
	add_child(flash)


func _process(delta: float) -> void:
	if state == "gone" or lvl == null or lvl.player == null:
		return
	var pl: Player = lvl.player
	var moving := false
	match state:
		"stalk":
			moving = _advance(delta, 1)
			if not moving or (pl.global_position - global_position).length() < 13.0:
				state = "linger"
				linger_t = 9.0
		"linger":
			linger_t -= delta
			var to := pl.global_position - global_position
			to.y = 0.0
			if to.length() > 0.1:
				var want := atan2(-to.x, -to.z) + sin(Time.get_ticks_msec() * 0.0012) * 0.7
				rotation.y = lerp_angle(rotation.y, want, minf(delta * 1.2, 1.0))
			if linger_t <= 0.0:
				state = "leave"
		"leave":
			moving = _advance(delta, -1)
			if not moving:
				state = "gone"
				queue_free()
				return
	phase += delta * (5.0 if moving else 0.0)
	for i in legs.size():
		(legs[i] as Node3D).rotation.x = sin(phase + PI * i) * 0.35 * (1.0 if moving else 0.0)
	position.y = path[clampi(idx, 0, path.size() - 1)].y + absf(sin(phase)) * 0.06
	if moving:
		step_t -= delta
		if step_t <= 0.0:
			step_t = 0.63
			lvl.sound.play_at("pipe_clank", {"f": 58.0}, global_position, -6.0)
	_watch(delta, pl)


func _advance(delta: float, dirn: int) -> bool:
	var target := idx + dirn
	if target < 0 or target >= path.size():
		return false
	var goal: Vector3 = path[target]
	var to := goal - global_position
	to.y = 0.0
	if to.length() < 0.15:
		idx = target
		return true
	var step := minf(SPEED * delta, to.length())
	global_position += to.normalized() * step
	rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), minf(delta * 3.0, 1.0))
	return true


func _visible_to(pl: Player) -> bool:
	var eye := pl.global_position + Vector3(0, 1.0 if pl.crouching else 1.6, 0)
	var from := head.global_position
	var to := eye - from
	if to.length() > 28.0:
		return false
	var fwd := -global_transform.basis.z
	var flat := Vector3(to.x, 0, to.z).normalized()
	if fwd.dot(flat) < 0.35:
		return false
	var q := PhysicsRayQueryParameters3D.create(from, eye, 1)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()


func _watch(delta: float, pl: Player) -> void:
	cool = maxf(cool - delta, 0.0)
	flash.light_energy = lerpf(flash.light_energy, 0.0, minf(delta * 20.0, 1.0))
	if spin >= 0.0:
		spin += delta
		gun.rotation.z += delta * (6.0 + spin * 30.0)
		if spin > 0.9 and spin < 2.1:
			flash.light_energy = 6.0 if int(spin * 30.0) % 2 == 0 else 1.0
			if int(spin * 10.0) != int((spin - delta) * 10.0):
				lvl.sound.play_at("knock", {"hits": 3}, global_position + Vector3(0, 2, 0), 2.0)
				var hit := pl.global_position + Vector3(randf_range(-1.5, 1.5), randf_range(0.2, 2.2), randf_range(-1.5, 1.5))
				lvl.sound.play_at("crackle", {"seconds": 0.3}, hit, -6.0)
		if spin >= 2.1:
			spin = -1.0
			cool = 6.0
			if _visible_to(pl):
				pl.hurt(40.0, "Trenchcleaner chaingun")
				Overlay.glitch(0.7)
				Overlay.subtitle("[rounds tear through the sandbags around you. Get down. Get out of its sight.]", 4.0)
			else:
				Overlay.subtitle("[the burst chews the parapet where you were a moment ago]", 3.5)
		return
	if cool > 0.0:
		return
	var loud: bool = pl.velocity.length() > 3.6 or (pl.velocity.length() > 0.8 and not pl.crouching) or pl.flashlight.visible
	if loud and _visible_to(pl):
		spin = 0.0
		lvl.sound.play_at("pipe_clank", {"f": 880.0}, global_position + Vector3(0, 2, 0), -4.0)
		if not seen_said:
			seen_said = true
			Overlay.subtitle("[blue lights turn your way. A whine rises as eight barrels begin to spin.]", 4.0)
