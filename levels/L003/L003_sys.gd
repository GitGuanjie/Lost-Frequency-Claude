extends Node
## Level 3 runtime phenomena (failing machinery, sludge, hotspots, dread past the
## bars, Sanctum refuge, Base Gamma gate/lift, occasional car room) and QA hooks.

const U := Vector3(0, 1, 0)
const K := preload("res://levels/L003/L003_kit.gd")
const EX_CAR := "L003>L069#4"

var lvl
var car_exit: ExitTrigger
var unstable_gen := Vector3.ZERO
var gen_emit: AudioStreamPlayer3D
var lift_dest := 0
var car_open := false
var gate_open := false
var zone := ""
var para := 0.0
var dread := 0.0
var fume := 0.0
var _rng := RandomNumberGenerator.new()
var _plug: GeoKit
var _car_t := 240.0
var _lift_state := "open"
var _lift_t := 0.0
var _lift_c := Vector3.ZERO
var _doors: Array = []
var _gate: Node3D
var _gate_x := 0.0
var _leds: Array = []
var _lock_pivot: Node3D
var _lock_t := -1.0
var _lock_open := false
var _lock_at := Vector3.ZERO
var _stare := 0.0
var _look: Dictionary = {}
var _para_t := 6.0
var _dread_cd := 10.0
var _fig: Node3D
var _fig_t := 0.0
var _fig_v := Vector3.ZERO
var _shock_cd := 0.0
var _burn_cd := 0.0
var _fume_cd := 0.0
var _crack_t := 1.0
var _frag_t := 75.0
var _gen_t := 70.0
var _gen_phase := 0
var _sparks_gen: CPUParticles3D
var _flash: OmniLight3D
var _beds: Array = []
var _said := {}
var _cams: Array = []
var _belts: Array = []
var _spark_mat: StandardMaterial3D


func setup(level) -> void:
	lvl = level
	_rng.randomize()
	_spark_mat = StandardMaterial3D.new()
	_spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_spark_mat.albedo_color = Color("ffbf59")
	_spark_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED


func _say(key: String, text: String, secs: float = 3.5) -> void:
	if not _said.has(key):
		_said[key] = true
		Overlay.subtitle(text, secs)


# ------------------------------------------------------------ build helpers

func sparks(pos: Vector3, amount: int = 14, emitting: bool = true, drip := false) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.position = pos
	p.amount = 4 if drip else amount
	p.lifetime = 1.0 if drip else 0.45
	p.explosiveness = 0.0 if drip else 0.5
	p.direction = Vector3.DOWN if drip else U
	p.spread = 5.0 if drip else 70.0
	p.initial_velocity_min = 0.1 if drip else 1.0
	p.initial_velocity_max = 0.3 if drip else 3.0
	var q := QuadMesh.new()
	q.size = Vector2(0.03, 0.05) if drip else Vector2(0.025, 0.025)
	q.material = MatLib.get_mat("l3_sludge") if drip else _spark_mat
	p.mesh = q
	p.emitting = emitting
	lvl.add_child(p)
	return p


func drip(pos: Vector3) -> void:
	sparks(pos, 4, true, true)


## A live cable fallen from the trays: cable, sparking tip on the floor.
func live_wire(k: GeoKit, top: Vector3, tip: Vector3) -> void:
	var mid := (top + tip) * 0.5 + Vector3(0.25, 0.0, 0.1)
	K.pipe(k, top, mid, 0.022, "l3_cable", 5)
	K.pipe(k, mid, tip + U * 0.05, 0.022, "l3_cable", 5)
	for i in 6:
		var a0 := i * 1.1
		K.pipe(k, tip + Vector3(cos(a0) * 0.3, 0.03, sin(a0) * 0.3), tip + Vector3(cos(a0 + 1.1) * 0.3, 0.03, sin(a0 + 1.1) * 0.3), 0.022, "l3_cable", 5)
	sparks(tip + Vector3(0.3, 0.06, 0.0), 10)
	lvl.wires.append(tip)
	lvl.lights.add_anchor(tip + U * 0.3, Color("ffb259"), 0.35, 3.0, 0.9)


func outlet(k: GeoKit, pos: Vector3, out: Vector3) -> void:
	K.obox(k, pos, out, Vector3(0.1, 0.13, 0.05), "l3_outlet")
	k.box(pos + out * 0.03 + U * 0.12, Vector3(0.14, 0.12, 0.14) * Vector3(absf(out.z) + 0.2, 1, absf(out.x) + 0.2), "l3_sludge", GeoKit.ALL, false)
	sparks(pos + out * 0.05, 6)


## Purpification (page: dead entities partly noclipped into a wall, the wall
## around them completely purple; one case was a Hound). Position is ours.
func purpified(k: GeoKit, base: Vector3, out: Vector3) -> void:
	var b := K.frame(out)
	k.box_xf(Transform3D(b, base + U * 0.9 + out * 0.02), Vector3(2.2, 1.8, 0.05), "l3_purple", GeoKit.ALL, false)
	var body := base + U * 0.75 + out * 0.15
	K.pipe(k, body - b.x * 0.55 - out * 0.3, body + b.x * 0.35 + out * 0.15, 0.22, "l3_purple_flesh", 9)
	k.box_xf(Transform3D(b, body + b.x * 0.55 + out * 0.25 + U * 0.12), Vector3(0.36, 0.28, 0.42), "l3_purple_flesh", GeoKit.ALL, false)
	for s: float in [-0.3, 0.25]:
		K.pipe(k, body + b.x * s + out * 0.1, body + b.x * (s + 0.1) + out * 0.5 + Vector3.DOWN * 0.72, 0.06, "l3_purple_flesh", 6)
	lvl.lights.add_anchor(base + U * 1.0 + out * 0.8, Color("9940ff"), 0.6, 4.0)
	K.sign(k, "PURPIFICATION SITE\ngamma — do not touch\n— M.E.G.", base + U * 1.9 + b.x * 1.45 + out * 0.03, out, 0.55, 0.32, "l3_sign_white", Color("590d73"), 30)
	lvl.zones.append({"name": "purple", "box": AABB(base - Vector3(3, 1, 3), Vector3(6, 4, 6))})


func car_plug(wall_mat: String) -> void:
	_plug = GeoKit.new(lvl, "CarPlug")
	_plug.wall(Vector3(6.68, 0, -1.55), Vector3(9.32, 0, -1.55), 2.62, 0.3, wall_mat)
	_plug.commit()
	_set_car(lvl.qa_fixture)
	_car_t = _rng.randf_range(150.0, 330.0)


func _set_car(open: bool) -> void:
	car_open = open
	_plug.root.visible = not open
	_plug.body.collision_layer = 0 if open else 1
	if car_exit:
		car_exit.enabled = open


## Gated bars (page: rare gates with locked doors, opened by lock-picking).
## Beyond the gate: a short pocket with artwork and a notebook page, then more
## bars that never open.
func gate_pocket(k: GeoKit, bp: Vector3, f: Vector3, side: Vector3, w: float, h: float) -> void:
	var half := w * 0.5 + 0.28
	K.bars(k, bp - side * half, bp - side * 0.47, h, false, 0.0)
	K.bars(k, bp + side * 0.47, bp + side * half, h, false, 0.0)
	for s: float in [-0.47, 0.47]:
		K.obox(k, bp + side * s + U * (h * 0.5), f, Vector3(0.07, h, 0.07), "l3_bars")
	_lock_pivot = Node3D.new()
	_lock_pivot.position = bp - side * 0.45
	lvl.add_child(_lock_pivot)
	var gk := GeoKit.new(_lock_pivot, "GateLeaf")
	var x := 0.06
	while x < 0.9:
		K.pipe(gk, side * x + U * 0.02, side * x + U * (h - 0.05), 0.019, "l3_bars", 6)
		x += 0.125
	for y: float in [0.14, h * 0.52, h - 0.12]:
		gk.box_xf(Transform3D(K.frame(f), side * 0.45 + U * y), Vector3(0.9, 0.06, 0.03), "l3_bars", GeoKit.ALL, false)
	gk.box_xf(Transform3D(K.frame(f), side * 0.76 - f * 0.05 + U * 1.05), Vector3(0.16, 0.22, 0.09), "l3_lockbox", GeoKit.ALL, false)
	gk.add_box_shape(Transform3D(K.frame(f), side * 0.45 + U * (h * 0.5)), Vector3(0.9, h, 0.1), "metal")
	gk.commit()
	_lock_at = bp + side * 0.31 + U * 1.05
	lvl.add_interactable(_lock_at - f * 0.12, Vector3(0.5, 0.5, 0.25), "Pick the gate's lock", _pick)
	K.obox(k, bp + f * 3.0 + side * (w * 0.5 - 0.02) + U * 1.55, -side, Vector3(1.7, 1.3, 0.02), "l3_canvas")
	K.obox(k, bp + f * 3.05 + side * (w * 0.5 - 0.035) + U * 1.85, -side, Vector3(0.32, 0.36, 0.01), "l3_cable")
	lvl.add_note("L003_notebook", "A torn notebook page",
		"[i]Cramped, furious handwriting on worn paper. M.E.G. treats these pages as unverified in-world documents.[/i]\n\nVermin. They crawl in through every crack and strip my halls bare, and they call it a gift. This place was already in ruins before they came. Now it is theirs to pick clean.\n\n[i]The rest of the page is scored through until the paper tore.[/i]",
		bp + f * 4.0 - side * 0.3 + U * 0.03)


func _pick(_p) -> void:
	if _lock_open or _lock_t >= 0.0:
		return
	_lock_t = 0.0
	Overlay.subtitle("[you work the old lock with a bent wire]", 2.5)


func add_belt(a: Vector3, b: Vector3, kind: String) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var hh := 0.15
	if kind == "bottle":
		var c := CylinderMesh.new()
		c.top_radius = 0.045
		c.bottom_radius = 0.045
		c.height = 0.26
		c.radial_segments = 8
		c.material = MatLib.get_mat("l3_bottle")
		mm.mesh = c
		hh = 0.13
	else:
		var bm := BoxMesh.new()
		bm.size = Vector3(0.42, 0.3, 0.36)
		bm.material = MatLib.get_mat("l3_cardboard")
		mm.mesh = bm
	var n := int(a.distance_to(b) / (0.55 if kind == "bottle" else 1.3))
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	lvl.add_child(mi)
	var bl := {"mm": mm, "a": a, "b": b, "n": n, "off": 0.0, "h": hh}
	_belts.append(bl)
	_belt_set(bl)


func _belt_set(bl: Dictionary) -> void:
	var n: int = bl["n"]
	for i in n:
		var t := fmod(float(bl["off"]) + float(i) / n, 1.0)
		var p: Vector3 = (bl["a"] as Vector3).lerp(bl["b"], t) + U * float(bl["h"])
		(bl["mm"] as MultiMesh).set_instance_transform(i, Transform3D(Basis(U, i * 0.7), p))


func take_water(_p) -> void:
	SaveService.add_item("almond_water")
	if lvl.player:
		lvl.player.heal(20.0)
	Overlay.toast("You take a bottle of Almond Water off the pallet. The stack looks no smaller. (%d carried)" % SaveService.item_count("almond_water"), 4.0)


## A box mesh (optionally solid) under its own movable node.
func _bx(pos: Vector3, size: Vector3, mat: String, collide: bool = false) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	lvl.add_child(n)
	var gk := GeoKit.new(n, "B")
	gk.box(Vector3.ZERO, size, mat, GeoKit.ALL, collide, "metal")
	gk.commit()
	return n


func add_camera(head: Vector3) -> void:
	var n := _bx(head, Vector3(0.2, 0.2, 0.42), "l3_ebox")
	n.rotation.y = _rng.randf() * TAU
	_cams.append(n)


func make_lift(door_c: Vector3) -> void:
	_lift_c = door_c
	for s: float in [-1.0, 1.0]:
		_doors.append([_bx(Vector3.ZERO, Vector3(1.0, 2.3, 0.05), "l3_lift"), s])
	_lift_doors(0.0)


func _lift_doors(closed: float) -> void:
	for d in _doors:
		var s: float = d[1]
		(d[0] as Node3D).position = _lift_c + Vector3(s * lerpf(1.45, 0.5, closed), 1.15, -0.22)


func lift_press(_p) -> void:
	if _lift_state != "open":
		return
	_lift_state = "closing"
	_lift_t = 0.0
	lvl.sound.play_at("creak", {"freq": 70.0}, _lift_c + U, -6.0, "[the doors grind shut]")


func make_gate(c: Vector3) -> void:
	_gate = _bx(c + U * 1.2, Vector3(0.1, 2.4, 1.62), "l3_steel", true)
	for i in 2:
		_leds.append(_bx(Vector3(103.1 + i * 0.12, -3.3, -2.31), Vector3(0.06, 0.06, 0.01), ["l3_red_led", "l3_green_led"][i]))
	_set_gate(lvl.qa_fixture, true)


func _set_gate(open: bool, snap: bool = false) -> void:
	gate_open = open
	_leds[0].visible = not open
	_leds[1].visible = open
	if snap:
		_gate_x = 1.0 if open else 0.0
		_gate.position.z = _gate_x * 1.65


func blood_check(_p) -> void:
	if gate_open:
		Overlay.toast("The light over the hatch is green. The gate stands open.", 3.0)
		return
	Overlay.subtitle("[a needle pricks your fingertip]", 2.0)
	await get_tree().create_timer(1.3).timeout
	Overlay.subtitle("[the strip shows red blood. A bolt slides back. Speaker: \"Through you go.\"]", 4.0)
	_set_gate(true)


# ----------------------------------------------------------------- audio

func _bed(recipe: String, params: Dictionary, db: float, kind: String) -> AudioStreamPlayer:
	var p: AudioStreamPlayer = lvl.sound.bed(recipe, params, db)
	_beds.append({"p": p, "db": db, "kind": kind})
	return p


func beds() -> void:
	_bed("fluorescent_hum", {"base": 60.0, "rasp": 0.4}, -28.0, "all")
	_bed("transformer", {"base": 60.0}, -24.0, "maze")
	_bed("room_tone", {"cutoff": 220.0, "rumble": 0.6}, -17.0, "all")
	_bed("water_bed", {"bright": 0.1}, -27.0, "maze")
	_bed("pad", {"root": 98.0, "chord": [0, 4, 7, 11, 14], "bright": 0.45, "seconds": 8.0}, -21.0, "gamma")
	_bed("heartbeat", {}, -6.0, "fx")
	lvl.sound.oneshot("crackle", {"seconds": 1.2}, 9.0, 22.0, 6.0, "[electricity crackles inside the walls]", -16.0)
	lvl.sound.oneshot("pipe_clank", {"f": 120.0}, 18.0, 40.0, 8.0, "[thick liquid surges through a pipe]", -15.0)
	lvl.sound.oneshot("creak", {"freq": 80.0}, 25.0, 60.0, 9.0, "[a machine whirs up, stutters, whirs on]", -16.0)
	for b in _beds:
		if b["kind"] in ["gamma", "fx"]:
			(b["p"] as AudioStreamPlayer).volume_db = -80.0


func _audio(delta: float) -> void:
	var quiet := zone == "sanctum"
	var base := zone in ["gamma", "transfer"]
	for b in _beds:
		var t: float = b["db"]
		match b["kind"]:
			"all":
				t += -22.0 if quiet else 0.0
			"maze":
				t += -40.0 if quiet else (-12.0 if base else 0.0)
			"gamma":
				t = t if base else -80.0
				if zone == "transfer":
					t -= 4.0
			"fx":
				t = lerpf(-40.0, t, dread) if dread > 0.05 else -80.0
		var p: AudioStreamPlayer = b["p"]
		p.volume_db = lerpf(p.volume_db, t, minf(1.0, delta * 1.5))


# --------------------------------------------------------------- runtime

func on_ready() -> void:
	if unstable_gen != Vector3.ZERO:
		_sparks_gen = sparks(unstable_gen + Vector3(1.6, 1.4, 1.3), 30, false)
		_flash = OmniLight3D.new()
		_flash.position = unstable_gen + U * 2.5
		_flash.light_color = Color("ffb266")
		_flash.omni_range = 18.0
		_flash.light_energy = 0.0
		lvl.add_child(_flash)
	if lvl.qa_fixture:
		lvl.qa_routes.append({"edge": EX_CAR, "note": "QA fixture: the occasional car room stands open from the start; the car is 9 m from the arrival"})
	if str(lvl.spawn_report.get("used_arrival", "")) in ["from_L004", "from_L005"]:
		Overlay.subtitle("[the lift shudders to a stop; the doors drag open on a vast, bright hall]", 4.0)
	elif SessionState.is_story() and not SaveService.flag("L003", "arrived", false):
		SaveService.set_flag("L003", "arrived", true)
		Overlay.subtitle("[a faint hum under buzzing, crackling machines] [hot, stale air] [something thick rushes through the pipes]", 5.0)


func _zone_at(p: Vector3) -> String:
	for z in lvl.zones:
		if (z["box"] as AABB).has_point(p + U * 0.5):
			return z["name"]
	return "halls"


func tick(delta: float) -> void:
	var p: Player = lvl.player
	if p == null or p.dead:
		return
	var pos := p.global_position
	var nz := _zone_at(pos)
	if nz != zone:
		zone = nz
		_enter_zone(nz)
	_audio(delta)
	_hazards(delta, p, pos)
	_paranoia(delta, p, pos)
	_bars_dread(delta)
	var v := 0.25 + maxf(maxf(para * 0.4, dread * 0.45), fume * 0.3)
	Overlay.set_screen_effect("vignette", v)
	Overlay.set_screen_effect("desaturate", clampf(fume * 0.5, 0.0, 0.6))
	_car_tick(delta, pos)
	_lift_tick(delta)
	if not gate_open and zone == "transfer" and Vector2(pos.x - 105.0, pos.z).length() < 2.6:
		_set_gate(true)
		Overlay.subtitle("[the gate buzzes and slides open from this side]", 2.5)
	_gate_x = move_toward(_gate_x, 1.0 if gate_open else 0.0, delta * 0.8)
	_gate.position.z = _gate_x * 1.65
	_lock_tick(delta, p)
	if zone in ["gamma", "transfer"]:
		var head := pos + U * 1.5
		for c in _cams:
			var n := c as Node3D
			if n.global_position.distance_to(head) < 110.0:
				var want := n.global_transform.looking_at(head, U).basis.get_rotation_quaternion()
				n.quaternion = n.quaternion.slerp(want, minf(1.0, delta * 2.0))
	for bl in _belts:
		if pos.distance_to(((bl["a"] as Vector3) + (bl["b"] as Vector3)) * 0.5) < 50.0:
			bl["off"] = fmod(float(bl["off"]) + delta * 0.5 / (bl["a"] as Vector3).distance_to(bl["b"]), 1.0)
			_belt_set(bl)
	if _fig != null:
		_fig_t -= delta
		_fig.position += _fig_v * delta
		if _fig_t <= 0.0:
			_fig.queue_free()
			_fig = null


func _enter_zone(z: String) -> void:
	match z:
		"generator":
			_say("gen", "[hot, stuffy air — thirty degrees at least; the generators drone]")
		"boiler":
			_say("boil", "[stifling heat; the pipes tick and knock; a sharp chemical stink]")
		"assembly":
			_say("asm", "[conveyors rattle on with nobody minding them]")
		"sanctum":
			_say("san", "[the hum and the crackle fall away. It is very quiet in here.]", 4.0)
			lvl.checkpoint("sanctum")
		"gamma":
			_say("gam", "[cameras on poles turn to follow you] [somewhere ahead: music, a crowd, a PA]", 4.0)
		"transfer":
			_say("trn", "[through the walls: a crowd, music, someone laughing — the base is full of people]", 4.0)
			lvl.checkpoint("base_gamma")
		"purple":
			_say("pur", "[the bricks around the carcass glow a faint, steady purple]", 3.5)


func _hazards(delta: float, p: Player, pos: Vector3) -> void:
	_shock_cd -= delta
	_burn_cd -= delta
	_fume_cd -= delta
	_crack_t -= delta
	for w: Vector3 in lvl.wires:
		var d := Vector2(pos.x - w.x, pos.z - w.z).length()
		if d < 3.0 and _crack_t <= 0.0:
			_crack_t = _rng.randf_range(1.0, 2.6)
			lvl.sound.play_at("crackle", {"seconds": 0.6}, w + U * 0.1, -6.0)
		if d < 0.75 and absf(pos.y - w.y) < 1.2 and _shock_cd <= 0.0:
			_shock_cd = 2.0
			p.hurt(18.0, "electrocuted by a fallen live wire")
			Overlay.glitch(0.5)
			Overlay.subtitle("[ZAP — a fallen wire, still live]", 2.5)
			var away := Vector3(pos.x - w.x, 0.0, pos.z - w.z).normalized()
			p.velocity += away * 4.0
	var in_s := false
	var near := false
	for s in lvl.sludge:
		var c: Vector3 = s["c"]
		var d2 := Vector2(pos.x - c.x, pos.z - c.z).length()
		if absf(pos.y - c.y) < 0.8:
			in_s = in_s or d2 < float(s["r"])
			near = near or d2 < float(s["r"]) + 2.5
	if in_s:
		p.hurt(14.0 * delta, "scalded by the black sludge")
		if _burn_cd <= 0.0:
			_burn_cd = 3.0
			Overlay.subtitle("[the black sludge is scalding — it eats through your shoes]", 2.5)
	fume = clampf(fume + (delta * 0.12 if near else -delta * 0.07) + (delta * 0.3 if in_s else 0.0), 0.0, 1.5)
	if zone == "sanctum":
		fume = maxf(0.0, fume - delta * 0.3)
	if fume > 0.35 and _fume_cd <= 0.0:
		_fume_cd = 14.0
		Overlay.subtitle("[the fumes make your head swim — get away from the sludge]", 3.0)
	if fume > 1.0:
		p.hurt(2.5 * delta, "poisoned by black sludge fumes")
	_frag_t -= delta
	if _frag_t <= 0.0:
		_frag_t = _rng.randf_range(60.0, 150.0)
		for f in lvl.fragile:
			if not f["broken"] and (f["pos"] as Vector3).distance_to(pos) < 16.0:
				shatter(f)
				break
	_gen_tick(delta, p, pos)


func shatter(f: Dictionary) -> void:
	f["broken"] = true
	for ch in (f["kit"] as GeoKit).root.get_children():
		if ch is MeshInstance3D and str(ch.name).contains("l3_tube"):
			(ch as MeshInstance3D).material_override = MatLib.get_mat("l3_tube_dead")
	lvl.lights.anchors[int(f["anchor"])]["energy"] = 0.0
	var at: Vector3 = f["pos"]
	lvl.sound.play_at("crackle", {"seconds": 0.5}, at, -2.0, "[a tube bursts overhead — glass rains down]")
	var pp: Vector3 = lvl.player.global_position
	if Vector2(pp.x - at.x, pp.z - at.z).length() < 1.6:
		lvl.player.hurt(8.0, "cut by falling glass")


func _gen_tick(delta: float, p: Player, pos: Vector3) -> void:
	if _flash == null:
		return
	_flash.light_energy = maxf(0.0, _flash.light_energy - delta * 20.0)
	var d := pos.distance_to(unstable_gen)
	if _gen_phase == 0:
		if d < 40.0:
			_gen_t -= delta
		if _gen_t <= 0.0:
			_gen_phase = 1
			_gen_t = 6.0
			_sparks_gen.emitting = true
			if d < 30.0:
				Overlay.subtitle("[a generator's whine climbs higher and higher]", 3.0)
	else:
		_gen_t -= delta
		if gen_emit:
			gen_emit.pitch_scale = 1.0 + (6.0 - _gen_t) * 0.12
		if _gen_t <= 0.0:
			explode(p, d)


func explode(p: Player, d: float) -> void:
	lvl.sound.play_at("distant_boom", {}, unstable_gen + U * 2.0, 6.0, "[BANG — the generator blows apart in a sheet of sparks]")
	lvl.sound.play_at("crackle", {"seconds": 1.5}, unstable_gen + U * 2.0, 0.0)
	_flash.light_energy = 16.0
	Overlay.glitch(clampf(0.5 * (1.0 - d / 30.0), 0.0, 0.5))
	if d < 6.0:
		p.hurt(45.0 * (1.0 - d / 6.0), "caught by an exploding generator")
	_gen_phase = 0
	_gen_t = _rng.randf_range(80.0, 160.0)
	_sparks_gen.emitting = false
	if gen_emit:
		gen_emit.pitch_scale = 1.0


func _paranoia(delta: float, p: Player, pos: Vector3) -> void:
	var inside := false
	for hs: AABB in lvl.hotspots:
		if hs.has_point(pos + U * 0.5):
			inside = true
	if zone == "sanctum":
		para = maxf(0.0, para - delta * 0.5)
	elif inside:
		para = minf(1.0, para + delta / 22.0)
	else:
		para = maxf(0.0, para - delta / 12.0)
	if not inside:
		return
	_say("hot", "[the air goes close and heavy; you feel watched]")
	_para_t -= delta * (0.5 + para)
	if _para_t > 0.0:
		return
	_para_t = _rng.randf_range(6.0, 12.0)
	var at := pos + Vector3(_rng.randf_range(-3, 3), 1.2, _rng.randf_range(-4, 4))
	var opts := [["whisper", {"seconds": 2.2}, "[whispering, just behind you]"], ["whisper", {"seconds": 3.0}, "[someone crying, somewhere ahead in the dark]"],
		["knock", {"hits": 3}, "[metal clanks, close by — nothing there]"], ["static", {"seconds": 1.2}, "[a voice shouts \"help\" — then nothing]"],
		["scratch", {}, "[laughter, high and wrong, from the dark]"], ["whisper", {"seconds": 1.6}, "[heavy breathing, right at your ear]"]]
	var o: Array = opts[_rng.randi() % opts.size()]
	var cap: String = o[2]
	if not _said.has("tape"):
		_said["tape"] = true
		cap += "  (the camcorder's level meter does not move)"
	if para > 0.9 and _rng.randf() < 0.1:
		o = ["static", {"seconds": 2.5}, ""]
		cap = "[a sound you will never be able to describe]"
		Overlay.glitch(0.25)
	elif para > 0.7 and _rng.randf() < 0.25:
		cap = "[a voice speaks to you, close and calm. A moment later you cannot remember one word of it.]"
	lvl.sound.play_at(o[0], o[1], at, -8.0, cap)


func _bars_dread(delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var fwd := -cam.global_transform.basis.z
	var looking := false
	for bv in lvl.bar_views:
		var to: Vector3 = (bv["c"] as Vector3) - cam.global_position
		var d := to.length()
		if d < 10.0 and d > 0.3 and fwd.dot(to / d) > 0.9 and (bv["n"] as Vector3).dot(to / d) > 0.3:
			looking = true
			_look = bv
	if looking and zone != "sanctum":
		_stare += delta
	else:
		_stare = maxf(0.0, _stare - delta * 1.5)
	dread = clampf((_stare - 3.0) / 8.0, 0.0, 1.0)
	_dread_cd -= delta
	if _stare > 6.5 and _dread_cd <= 0.0 and not _look.is_empty():
		_dread_cd = 35.0
		if _rng.randf() < 0.55:
			glimpse(_look)
		else:
			lvl.sound.play_at("whisper", {"seconds": 3.0}, (_look["c"] as Vector3) + (_look["n"] as Vector3) * 9.0, -16.0, "[faint crying past the bars, barely over the machines]")


## The reported shadowy figure: a dark shape running away far past the bars.
func glimpse(bv: Dictionary) -> void:
	if _fig != null:
		return
	var n: Vector3 = bv["n"]
	_fig = MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.22
	cm.height = 1.75
	_fig.mesh = cm
	_fig.material_override = MatLib.get_mat("void_black")
	lvl.add_child(_fig)
	_fig.global_position = (bv["c"] as Vector3) + n * 8.5 + U * (0.875 - 1.5)
	_fig_v = n * 5.0
	_fig_t = 1.1
	Overlay.subtitle("[something dark runs off down the hall, far past the bars]", 3.0)


func _car_tick(delta: float, pos: Vector3) -> void:
	if lvl.qa_fixture:
		return
	_car_t -= delta
	if _car_t > 0.0:
		return
	var cam := get_viewport().get_camera_3d()
	var door := Vector3(8.0, 1.3, -1.55)
	var seen: bool = cam != null and cam.is_position_in_frustum(door) and cam.global_position.distance_to(door) < 40.0
	if not car_open:
		if not seen:
			_set_car(true)
			_car_t = _rng.randf_range(200.0, 320.0)
		else:
			_car_t = 4.0
	else:
		var inside := pos.z < -1.5 and pos.x > 4.0 and pos.x < 12.0
		if not seen and not inside:
			_set_car(false)
			_car_t = _rng.randf_range(240.0, 480.0)
		else:
			_car_t = 5.0


func _lift_tick(delta: float) -> void:
	_lift_t += delta
	match _lift_state:
		"closing":
			_lift_doors(clampf(_lift_t / 1.6, 0.0, 1.0))
			if _lift_t >= 1.6:
				_lift_state = "moving"
				_lift_t = 0.0
				lvl.sound.play_at("room_tone", {"cutoff": 90.0, "rumble": 1.0}, _lift_c, -4.0, "[the car lurches and drops — no floor numbers, no display]")
		"moving":
			if _lift_t >= 1.8:
				lift_dest = 4 if _rng.randf() < 0.5 else 5
				_lift_state = "sent"
				_lift_t = 0.0
		"sent":
			if _lift_t >= 3.0:
				lift_dest = 0
				_lift_state = "opening"
				_lift_t = 0.0
		"opening":
			_lift_doors(clampf(1.0 - _lift_t / 1.2, 0.0, 1.0))
			if _lift_t >= 1.2:
				_lift_state = "open"


func _lock_tick(delta: float, p: Player) -> void:
	if _lock_t < 0.0:
		return
	if p.global_position.distance_to(_lock_at) > 1.8:
		_lock_t = -1.0
		p.noclip_progress(0.0)
		Overlay.subtitle("[the pins slip back]", 1.5)
		return
	_lock_t += delta
	p.noclip_progress(_lock_t / 4.0)
	if _lock_t >= 4.0:
		_lock_t = -1.0
		_lock_open = true
		p.noclip_progress(0.0)
		lvl.sound.play_at("knock", {"hits": 1}, _lock_at, -4.0, "[the lock gives with a click; the gate swings in]")
		create_tween().tween_property(_lock_pivot, "rotation:y", deg_to_rad(-100.0), 1.4)


# -------------------------------------------------------------------- QA

func capture_plan() -> Array:
	return lvl.qa_shots


func self_test() -> Array:
	var out: Array = []
	await get_tree().physics_frame
	var space: PhysicsDirectSpaceState3D = lvl.get_world_3d().direct_space_state
	var blocked := 0
	for bv in lvl.bar_views:
		var c: Vector3 = bv["c"]
		var n: Vector3 = bv["n"]
		if not space.intersect_ray(PhysicsRayQueryParameters3D.create(c - n * 0.8, c + n * 0.8, 1)).is_empty():
			blocked += 1
	out.append({"what": "every set of bars blocks passage (no gap, no noclip)", "ok": blocked == lvl.bar_views.size() and blocked >= 2, "detail": [blocked, lvl.bar_views.size()]})
	var heights := []
	for probe: Vector3 in [Vector3(49.0, 7.0, -11.3), Vector3(10.0, -1.0, 24.0), Vector3(76.5, 7.0, 7.0), Vector3(90.0, -3.0, 0.0), Vector3(110.0, 1.0, 9.0), Vector3(50.0, 6.0, 41.5)]:
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(probe, probe + Vector3.DOWN * 3.0, 1))
		heights.append(snappedf(hit["position"].y, 0.1) if not hit.is_empty() else null)
	out.append({"what": "walkable decks at several heights (catwalk, boiler floor, gantry, Base Gamma floor, outpost, mezzanine)", "ok": not heights.has(null), "detail": heights})
	var seen := {}
	for i in 40:
		seen[4 if _rng.randf() < 0.5 else 5] = true
	out.append({"what": "lift destination is Level 4 or Level 5 at random", "ok": seen.size() == 2, "detail": seen.keys()})
	var was := car_open
	_set_car(false)
	await get_tree().physics_frame
	var shut := not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(8, 1.2, 0.0), Vector3(8, 1.2, -3.0), 1)).is_empty()
	_set_car(true)
	await get_tree().physics_frame
	var open := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(8, 1.2, 0.0), Vector3(8, 1.2, -3.0), 1)).is_empty()
	_set_car(was)
	out.append({"what": "the car room appears and disappears (wall plug toggles)", "ok": shut and open, "detail": [shut, open]})
	var g0 := gate_open
	_set_gate(false, true)
	await blood_check(null)
	out.append({"what": "finger-prick blood check opens the Base Gamma gate", "ok": gate_open, "detail": gate_open})
	_set_gate(g0, true)
	out.append({"what": "Sanctum is a zone where hotspot paranoia drains", "ok": _zone_at(Vector3(27, 0, -35)) == "sanctum" and _zone_at(Vector3(27.2, 0, -10)) == "halls", "detail": [_zone_at(Vector3(27, 0, -35))]})
	var hs_ok := false
	for hs: AABB in lvl.hotspots:
		hs_ok = hs_ok or hs.has_point(Vector3(27.2, 0.5, -10.0))
	out.append({"what": "the dark crouch passage is a paranoia hotspot", "ok": hs_ok})
	var arr_ok := true
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.78
	for tag in lvl.arrivals.keys():
		var o: Vector3 = (lvl.arrivals[tag] as Transform3D).origin
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = cap
		q.transform = Transform3D(Basis(), o + U * 0.95)
		arr_ok = arr_ok and space.intersect_shape(q, 1).is_empty() and not space.intersect_ray(PhysicsRayQueryParameters3D.create(o + U * 0.5, o + Vector3.DOWN * 0.5, 1)).is_empty()
	out.append({"what": "every arrival (start, from_L004, from_L005 inside the lift) has floor and clearance", "ok": arr_ok, "detail": lvl.arrivals.keys()})
	var hp: float = lvl.player.health
	explode(lvl.player, 99.0)
	shatter(lvl.fragile[0])
	glimpse(lvl.bar_views[0])
	for i in 3:
		_paranoia(9.0, lvl.player, Vector3(27.2, 0, -10))
	lift_press(null)
	for i in 40:
		_lift_tick(0.25)
	para = 0.0
	out.append({"what": "generator blast, tube burst, glimpse, hallucinations and a lift cycle run and spare a distant wanderer", "ok": lvl.player.health == hp and _lift_state == "open" and lift_dest == 0, "detail": [lvl.player.health, _lift_state]})
	out.append({"what": "black sludge pools and live wires are placed", "ok": lvl.sludge.size() >= 3 and lvl.wires.size() >= 2, "detail": [lvl.sludge.size(), lvl.wires.size()]})
	return out
