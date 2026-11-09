extends RefCounted
## Level 108 states and presences:
## - mutagenic mist: the floor lifts (a groan from the west), the mist follows
##   and rolls through, then thins; in the Hauntwood it never fully clears;
## - exposure meter with three irreversible stages (a respirator from New
##   Hereth's rack cuts the dose to a tenth); Anthosia pollen counts too;
## - the Hauntwood heading rule: keep one course ~70 m and you walk out;
## - scripted presences: a Dendroid lying as a dead tree, a Grimshell pair in
##   the flooded margin, the Black Goat at the edge of sight. No combat.

const LAND := preload("res://levels/L108/L108_land.gd")
const PULSE := 200.0
const STAGES := [18.0, 45.0, 90.0]

var lv
var exposure := 0.0
var stage := 0
var has_mask := false
var mist := 0.0
var pulse_t := 70.0
var phase := 0            # 0 calm, 1 groan, 2 rising, 3 thinning
var phase_t := 0.0
var patches: Array = []   # [pos, radius]
var said := {}
var beds := {}
var goat: MeshInstance3D
var goat_t := 25.0
var goat_on := false
var dendroid: Node3D
var dendroid_moved := false
var shells: Array = []
var shell_threat := 0.0
var course := Vector3.ZERO
var straight := 0.0
var off_course := 0.0
var last_p := Vector3.ZERO
var hw_exit: ExitTrigger
var frozen := false


func _init(level) -> void:
	lv = level


func setup(props: Node3D) -> void:
	var land = lv.land
	var r := RandomNumberGenerator.new()
	r.seed = 108040
	anthosia(props, Vector3(-30.0, 0, 18.0), r, true)
	anthosia(props, Vector3(24.0, 0, -36.0), r, true)
	# a "dead tree" on the purple path's flank (a Dendroid, older ones lie still)
	var dp := Vector3(-36.0, 0, -24.0)
	dp.y = land.h(dp.x, dp.z) + 0.2
	dendroid = Props.place(lv, props, "ph/dead_tree_trunk", dp, 35.0, 1.0, true)
	for k in 5:
		var mi := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.02
		cm.bottom_radius = 0.07
		cm.height = r.randf_range(1.2, 2.2)
		cm.radial_segments = 5
		mi.mesh = cm
		mi.material_override = lv.flora.dead_mat
		mi.position = Vector3(r.randf_range(-1.6, 1.6), 0.3, r.randf_range(-0.2, 0.2))
		mi.rotation = Vector3(r.randf_range(-1.2, 1.2), 0, r.randf_range(0.8, 1.4) * (1.0 if k % 2 == 0 else -1.0))
		if dendroid:
			dendroid.add_child(mi)
	# a Grimshell pair half-submerged in the flooded margin
	for zz in [-70.0, -64.0]:
		var sp := Vector3(land.fx(zz) + 7.0 + (zz + 67.0) * 0.4, LAND.WATER_Y - 0.25, zz)
		var sh := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 1.0
		sm.height = 2.0
		sm.radial_segments = 12
		sm.rings = 6
		sh.mesh = sm
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.05, 0.045, 0.035)
		m.roughness = 0.35
		sh.material_override = m
		sh.position = sp
		sh.scale = Vector3(1.3, 0.45, 1.0)
		props.add_child(sh)
		for s in [-1.0, 1.0]:
			var claw := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.25, 0.3, 0.9)
			claw.mesh = bm
			claw.material_override = m
			claw.position = Vector3(s * 0.8, -0.2, 1.1)
			claw.rotation.y = s * 0.4
			sh.add_child(claw)
		shells.append(sh)
	goat = MeshInstance3D.new()
	goat.mesh = lv.flora.goat
	goat.material_override = lv.flora.goat_mat
	goat.visible = false
	props.add_child(goat)


## A patch of Anthosia (one colour per patch) with a haze of pollen.
func anthosia(parent: Node3D, c: Vector3, r: RandomNumberGenerator, authored: bool) -> void:
	var land = lv.land
	var col: int = r.randi() % lv.flora.flowers.size()
	var xfs: Array = []
	var rad := r.randf_range(3.0, 5.5)
	for i in r.randi_range(14, 26):
		var a := r.randf() * TAU
		var d := sqrt(r.randf()) * rad
		var p := Vector3(c.x + cos(a) * d, 0, c.z + sin(a) * d)
		p.y = land.h(p.x, p.z)
		var s := r.randf_range(0.7, 1.3)
		xfs.append(Transform3D(Basis(Vector3.UP, r.randf() * TAU).scaled(Vector3(s, s, s)), p))
	var org := Vector3(c.x, land.h(c.x, c.z), c.z)
	lv.flora.mm(parent, lv.flora.flowers[col], lv.flora.flower_mat, xfs, org, 90.0)
	var pp := CPUParticles3D.new()
	pp.amount = 40
	pp.lifetime = 6.0
	pp.preprocess = 6.0
	pp.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	pp.emission_box_extents = Vector3(rad, 0.6, rad)
	pp.direction = Vector3(0, 1, 0)
	pp.spread = 60.0
	pp.initial_velocity_min = 0.05
	pp.initial_velocity_max = 0.2
	pp.gravity = Vector3(0, 0.02, 0)
	var qm := QuadMesh.new()
	qm.size = Vector2(0.05, 0.05)
	var pm := StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var fc: Color = [Color(1.0, 0.6, 0.8), Color(1.0, 0.9, 0.4), Color(0.85, 0.6, 1.0), Color(1.0, 0.7, 0.45)][col]
	pm.albedo_color = Color(fc.r, fc.g, fc.b, 0.55)
	qm.material = pm
	pp.mesh = qm
	pp.position = org + Vector3(0, 0.9, 0)
	pp.visibility_range_end = 45.0
	parent.add_child(pp)
	patches.append([org, rad, parent])


func take_mask() -> void:
	if has_mask:
		Overlay.subtitle("[the respirator is on. The filter hisses with every breath.]", 2.5)
		return
	has_mask = true
	Overlay.subtitle("[a respirator and a sealed filter from the rack. Breathing is harder; the air tastes of rubber]", 4.5)
	SaveService.record_discovery(lv.stable_id, "l108:respirator", "Took a respirator from New Hereth's filter rack.", "SOURCE")


func sounds() -> void:
	var s = lv.sound
	beds["forest"] = s.bed("wind", {"seconds": 9.0}, -32.0)
	beds["insects"] = s.bed("crickets", {"seconds": 6.0}, -34.0)
	beds["rumble"] = s.bed("room_tone", {"seconds": 6.0, "cutoff": 90.0, "rumble": 0.8}, -70.0)
	beds["haunt"] = s.bed("whisper", {"seconds": 8.0}, -70.0)
	s.emitter("transformer", lv.her.spots["hall_in"] + Vector3(0, 2.0, 0), {"base": 60.0}, -14.0, 22.0)
	s.emitter("water_bed", Vector3(LAND.FX + 6.0, 0.0, -20.0), {"seconds": 8.0, "bright": 400.0}, -16.0, 40.0)


func freeze_for_shot() -> void:
	frozen = true
	mist = 0.0
	phase = 0
	lv.apply_sky(0.0, 0.0)


func _say(key: String, text: String, secs := 4.0) -> void:
	if said.has(key) or SessionState.is_qa():
		return
	said[key] = true
	Overlay.subtitle(text, secs)


func tick(delta: float, pp: Vector3) -> void:
	var land = lv.land
	var qa := SessionState.is_qa()
	var hd: float = land.haunt_d(pp.x, pp.z)
	var haunt := smoothstep(-10.0, 25.0, hd)
	if not qa and not frozen:
		_pulse(delta)
	var m := maxf(mist, haunt * 0.55)
	lv.apply_sky(m, haunt)
	_exposure(delta, pp, m, qa)
	_hauntwood(delta, pp, hd)
	if not qa:
		_presences(delta, pp)
	_vol("rumble", -70.0 if phase == 0 else (-16.0 if phase == 1 else -30.0), minf(delta * 1.5, 1.0))
	_vol("haunt", lerpf(-70.0, -26.0, haunt), minf(delta, 1.0))
	_vol("insects", lerpf(-34.0, -60.0, haunt), minf(delta, 1.0))


func _pulse(delta: float) -> void:
	phase_t += delta
	match phase:
		0:
			pulse_t -= delta
			if pulse_t <= 0.0:
				phase = 1
				phase_t = 0.0
				lv.sound.play_at("distant_boom", {}, lv.player.global_position + Vector3(-60, 0, 0), -6.0, "[a deep groan from the west; the ground lifts under you, a hair]")
		1:
			if phase_t > 14.0:
				phase = 2
				phase_t = 0.0
				_say("mist" + str(pulse_t), "[mist rolls in through the trees from the crater side]", 4.0)
		2:
			mist = minf(1.0, mist + delta / 18.0)
			if phase_t > 60.0:
				phase = 3
				phase_t = 0.0
		3:
			mist = maxf(0.0, mist - delta / 30.0)
			if mist <= 0.0:
				phase = 0
				pulse_t = PULSE + lv.rng.randf_range(-40.0, 40.0)


func _exposure(delta: float, pp: Vector3, m: float, qa: bool) -> void:
	var dose := 0.0
	if m > 0.2:
		dose += m
	for pa in patches:
		if is_instance_valid(pa[2]) and Vector2(pp.x - pa[0].x, pp.z - pa[0].z).length() < float(pa[1]) + 0.5:
			dose += 1.2
			_say("pollen", "[a sweet, heavy pollen hangs over the flowers. It coats your throat.]", 4.0)
	if has_mask:
		dose *= 0.1
	if qa:
		return
	exposure += dose * delta
	if stage < 3 and exposure >= STAGES[stage]:
		stage += 1
		match stage:
			1:
				Overlay.subtitle("[your skin crawls and your mouth tastes of copper. It does not go away.]", 5.0)
			2:
				Overlay.subtitle("[the colours are wrong now, and they stay wrong]", 5.0)
			3:
				Overlay.subtitle("[something in you has changed for good. The mist did it in a breath.]", 5.0)
		SaveService.record_discovery(lv.stable_id, "l108:mutation%d" % stage, "Mutagenic mist exposure, stage %d (irreversible)." % stage, "SOURCE")
	# irreversible: effects only ever grow
	Overlay.set_screen_effect("red_tint", 0.04 * float(stage >= 1) + 0.04 * float(stage >= 3))
	Overlay.set_screen_effect("desaturate", 0.25 * float(stage >= 2))
	Overlay.set_screen_effect("vignette", 0.25 + 0.15 * m + 0.1 * float(stage >= 3))


## Keep one course in the Hauntwood for ~70 m and the zone lets you out.
func _hauntwood(delta: float, pp: Vector3, hd: float) -> void:
	var step := Vector3(pp.x - last_p.x, 0, pp.z - last_p.z)
	last_p = pp
	if hd < 4.0:
		straight = 0.0
		course = Vector3.ZERO
		if hw_exit and is_instance_valid(hw_exit):
			hw_exit.queue_free()
			hw_exit = null
		return
	_say("hw", "[grey trees, all of them dormant. When you look back, they are not where they were.]", 4.5)
	var sl := step.length()
	if sl < 0.005 or sl > 3.0:
		return
	var d := step / sl
	if course == Vector3.ZERO:
		course = d
	if d.dot(course) > cos(deg_to_rad(35.0)):
		straight += sl
		course = course.lerp(d, 0.02).normalized()
		off_course = 0.0
	else:
		off_course += delta
		if off_course > 1.2:
			straight = 0.0
			course = d
			off_course = 0.0
	if straight > 70.0 and hw_exit == null and course.x > -0.3:
		var c := pp + course * 4.0 + Vector3(0, 1.2, 0)
		hw_exit = lv.make_exit("L108>EXT#1", "walk_in", c, Vector3(6.0, 3.0, 2.0), "", lv)
		if hw_exit:
			hw_exit.rotation.y = atan2(course.x, course.z)
		_say("hw_out", "[the grey trees thin ahead, all at once]", 3.0)
	elif straight > 70.0 and course.x <= -0.3:
		_say("hw_back", "[the trees turn green again: the Craterwood]", 3.0)


func _presences(delta: float, pp: Vector3) -> void:
	# Dendroid: lies still until you are close, then shifts its limbs
	if dendroid and is_instance_valid(dendroid) and not dendroid_moved and dendroid.global_position.distance_to(pp) < 7.0:
		dendroid_moved = true
		dendroid.rotation.y += 0.25
		dendroid.position.y += 0.08
		lv.sound.play_at("creak", {"freq": 90.0}, dendroid.global_position, -4.0, "[the dead tree drags itself an inch closer]")
		_say("dendroid", "[it was not a dead tree. Its limbs drag on the moss. They hate fire, the guards say.]", 5.0)
	# Grimshells: territorial pair in the shallows
	var in_water: bool = lv.water.contains(pp + Vector3(0, 0.3, 0))
	var near := false
	for s in shells:
		if (s as Node3D).global_position.distance_to(pp) < 16.0:
			near = true
	if in_water and near:
		shell_threat += delta
		_say("grim", "[the dark shell in the shallows lifts. Another answers it. You are in their nest.]", 4.5)
		if shell_threat > 9.0:
			shell_threat = 0.0
			lv.player.hurt(1000.0, "Level 108: a Grimshell pair defending its nest")
	else:
		shell_threat = maxf(0.0, shell_threat - delta)
	if in_water:
		_say("water", "[the water is warm and alive with things. Do not drink it.]", 3.5)
	# the Black Goat at the edge of sight, west of you, wanting to be followed
	goat_t -= delta
	if not goat_on and goat_t <= 0.0 and pp.x < 60.0:
		goat_t = lv.rng.randf_range(80.0, 160.0)
		var a: float = lv.rng.randf_range(-0.6, 0.6) + PI
		var gp := pp + Vector3(cos(a), 0, sin(a)) * 38.0
		gp.y = lv.land.h(gp.x, gp.z)
		goat.global_position = gp
		goat.rotation.y = atan2(pp.x - gp.x, pp.z - gp.z)
		goat.visible = true
		goat_on = true
		_say("goat", "[a black goat between the trees, watching you. It turns, and waits, as if you should follow.]", 5.0)
	if goat_on:
		var to: Vector3 = goat.global_position - pp
		if to.length() < 22.0:
			goat.rotation.y = atan2(-1.0, 0.0)
			goat.global_position += Vector3(-1.0, 0, 0) * delta * 2.2
			goat.global_position.y = lv.land.h(goat.global_position.x, goat.global_position.z)
		if to.length() < 14.0 or to.length() > 70.0:
			goat.visible = false
			goat_on = false


func show_goat_at(p: Vector3, face: Vector3) -> void:
	goat.global_position = p
	goat.rotation.y = atan2(face.x - p.x, face.z - p.z)
	goat.visible = true


func _vol(key: String, db: float, k: float) -> void:
	var pl: AudioStreamPlayer = beds.get(key)
	if pl:
		pl.volume_db = lerpf(pl.volume_db, db, k)
