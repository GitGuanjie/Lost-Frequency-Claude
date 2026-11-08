extends Node
## Level 1 runtime systems, owned by L001.gd. Source: "Level 1 - Habitable Zone"
## (Backrooms Wiki rev 83, CC BY-SA 3.0), dossier docs/canon/levels/L001.md.
##  Flickering - random total blackouts of every light; green EXIT lights stay on
##  Smilers    - "attracted by light (and noise once having spotted their prey)"
##  Crates     - appear behind your back / after Flickering, vanish unobserved
##  Halls      - non-Euclidean: no landmark in view -> disorientation -> fold
##  Corridors  - Euclidean, entities rarely wander there, rooms are restful

const Kit := preload("res://levels/L001/L001_kit.gd")
const HH := 4.6
const LOOT := [["almond_water", 22, "a sealed bottle of Almond Water. It tastes sweet and nutty", 30.0],
	["canned_food", 16, "sealed cans of food", 18.0], ["bandages", 9, "bandages and a bottle of antiseptic", 12.0],
	["yarn", 12, "balls of yarn", 0.0], ["clothes", 9, "a warm sweatshirt and clean socks", 0.0],
	["", 12, "nothing but packing straw and loose planks", 0.0], ["notepad", 5, "a notepad and a pen", 0.0],
	["", 6, "glass shards; one slices your finger", -12.0], ["", 4, "leaking chemical bottles; the fumes sting", -8.0],
	["", 3, "a cube of solid nitrogen that burns with cold", -6.0], ["", 2, "explosives. You lower the lid very gently", 0.0]]
const PAINT_AT := Vector3(20.3, 0.1, 41.55)

var L                                   # the Level 1 scene (L001.gd)
var rt := RandomNumberGenerator.new()   # runtime randomness only, never layout
var zone := "hall"
var meta: Dictionary = {}
var fl := "calm"                        # calm | stutter | dark | return
var fl_t := 9999.0
var lit := 1.0
var _st_t := 0.0
var _cue_t := 5.0
var _amb_t := 8.0
var hunt := 0.0
var smiler: Node3D
var _interest := 0.0
var _smiler_occluded := 0.0
var dis := 0.0
var _fold_cd := 40.0
var _fold_fx := 0.0
var _lock_t := 0.0
var locked := false
var base_fov := 75.0
var crates: Dictionary = {}
var cstate: Dictionary = {}
var _appear_t := 90.0
var _spawn_n := 0
var _crate_t := 0.0
var painting: Node3D
var _paint_unseen := 0.0
var _rest_t := 0.0
var _rest_cd := 0.0
var _beds: Dictionary = {}


func setup(level) -> void:
	L = level
	rt.randomize()
	if not L.qa_fixture:
		fl_t = rt.randf_range(70.0, 150.0)
	for b in [["hall", "room_tone", {"cutoff": 170.0, "rumble": 0.25}], ["hum", "fluorescent_hum", {"base": 50.0, "rasp": 0.12}],
			["corr", "room_tone", {"cutoff": 520.0, "seconds": 3.0}], ["util", "transformer", {"base": 50.0}], ["heart", "heartbeat", {}]]:
		_beds[b[0]] = L.sound.bed(b[1], b[2], -70.0, "SFX" if b[0] == "heart" else "Ambience")


static func in_block(m: Dictionary, p: Vector3) -> bool:
	for b in m.get("blocks", []):
		if (b as Rect2).has_point(Vector2(p.x, p.z)):
			return true
	return false


func step(delta: float) -> void:
	var p: Player = L.player
	meta = L.world.meta_of(L.world.key_at(p.global_position))
	var z := "corridor" if in_block(meta, p.global_position) else "hall"
	if z != zone:
		zone = z
		Settings.set_reverb(0.85 if z == "hall" else 0.3, 0.28 if z == "hall" else 0.09)
	_flicker(delta, p)
	_hunt(delta, p)
	_disorient(delta, p)
	_crate_step()
	if not L.qa_fixture and fl == "calm":
		_appear_t -= delta
		if _appear_t <= 0.0:
			_appear_t = rt.randf_range(70.0, 160.0)
			crate_behind()
	_rest(delta, p)
	_audio(delta, p)


# -------------------------------------------------------------- Flickering

func set_lit(v: float) -> void:
	lit = v
	(MatLib.get_mat("l1_panel") as ShaderMaterial).set_shader_parameter("energy", 2.4 * v)
	(MatLib.get_mat("l1_panel_warm") as ShaderMaterial).set_shader_parameter("energy", 2.3 * v)
	(MatLib.get_mat("l1_bulb") as ShaderMaterial).set_shader_parameter("emission_energy", 5.0 * v)
	L.lights.visible = v > 0.5


func _flicker(delta: float, p: Player) -> void:
	fl_t -= delta
	_st_t -= delta
	match fl:
		"calm":
			if fl_t <= 0.0:
				fl = "stutter"
				fl_t = rt.randf_range(1.3, 2.6)
				Overlay.subtitle("[the fluorescent lights stutter]", 2.0)
		"stutter", "return":
			if _st_t <= 0.0:
				_st_t = rt.randf_range(0.05, 0.16)
				set_lit(1.0 if rt.randf() < (0.35 if fl == "stutter" else 0.65) else 0.1)
			if fl_t <= 0.0 and fl == "stutter":
				fl = "dark"
				fl_t = rt.randf_range(18.0, 50.0)
				set_lit(0.0)
				Overlay.subtitle("[every light goes out; the hum dies with them]", 3.0)
			elif fl_t <= 0.0:
				fl = "calm"
				fl_t = rt.randf_range(110.0, 260.0)
				set_lit(1.0)
				Overlay.subtitle("[the lights buzz back on]", 2.5)
				if not L.qa_fixture:   # crates appear "after a Flickering event"
					for i in 1 + rt.randi() % 2:
						crate_behind()
		"dark":
			if fl_t <= 0.0:
				fl = "return"
				fl_t = 0.9
	var env: Environment = L.environment
	var a := clampf(delta * 6.0, 0.0, 1.0)
	env.ambient_light_energy = lerpf(env.ambient_light_energy, (0.07 if zone == "hall" else 0.035) * lit + 0.003, a)
	env.fog_light_energy = lerpf(env.fog_light_energy, lit + 0.02, a)
	env.background_color = L.fog_color * env.fog_light_energy
	if fl != "dark":
		return
	_cue_t -= delta
	if _cue_t > 0.0:
		return
	_cue_t = rt.randf_range(4.0, 9.0)
	var ang := rt.randf() * TAU
	var at := p.global_position + Vector3(cos(ang), 0.0, sin(ang)) * rt.randf_range(7.0, 16.0)
	if zone == "hall":   # sound-only presences of the listed entities
		match rt.randi() % 3:
			0: L.sound.play_at("footstep", {"surface": "concrete", "variant": rt.randi() % 4}, at, -2.0, "[bare skin slapping on concrete, somewhere close]")
			1: L.sound.play_at("scratch", {}, at + Vector3.UP, -6.0, "[claws scraping in the dark]")
			2: L.sound.play_at("knock", {"hits": 2}, at + Vector3.UP * 3.5, -8.0, "[something bumps through a vent above]")
	elif rt.randf() < 0.15:
		L.sound.play_at("scratch", {}, at + Vector3.UP, -18.0, "[a faint scratching, far off]")


# ----------------------------------------------------------------- Smilers

func _hunt(delta: float, p: Player) -> void:
	var exposed := fl == "dark" and zone == "hall" and not p.dead and p.global_position.y < 2.0
	var light_on := p.flashlight.visible
	var loud := Vector2(p.velocity.x, p.velocity.z).length() > 4.2
	if exposed:
		if light_on:
			hunt += delta * 0.45
		elif loud and smiler:
			hunt += delta * 0.2
		else:
			hunt = maxf(0.0, hunt - delta * 0.12)
		if hunt >= 1.0 and smiler == null:
			_spawn_smiler(p)
	else:
		hunt = maxf(0.0, hunt - delta * 0.6)
	var threat := 0.0
	if smiler:
		var cam := p.camera.global_position
		var to := cam - smiler.global_position
		# Unlike the old direct-position chase, the presence cannot pass through
		# warehouse walls, crate stacks or a closed corridor door.
		var space: PhysicsDirectSpaceState3D = L.get_world_3d().direct_space_state
		var ray := PhysicsRayQueryParameters3D.create(smiler.global_position, cam, 1)
		ray.exclude = [p.get_rid()]
		var clear: bool = space.intersect_ray(ray).is_empty()
		threat = clampf(1.0 - to.length() / 16.0, 0.2, 1.0) if clear else 0.0
		if not exposed:
			_drop_smiler(0.0)
		elif light_on or loud:
			if clear:
				_smiler_occluded = 0.0
				_interest = 5.0
				var stp := to.normalized() * delta * (1.7 if light_on else 1.2)
				smiler.global_position += Vector3(stp.x, 0.0, stp.z)
			else:
				_smiler_occluded += delta
				if _smiler_occluded > 5.0:
					_drop_smiler(0.35)
		else:
			_interest -= delta   # switching off the light can break its fixation
			if _interest <= 0.0:
				_drop_smiler(0.3)
		if smiler:
			smiler.look_at(cam, Vector3.UP, true)
			if clear and to.length() < 1.5:
				p.hurt(1000.0, "A Smiler followed your light in the dark")
	var hb: AudioStreamPlayer = _beds["heart"]
	hb.volume_db = lerpf(hb.volume_db, -70.0 + 62.0 * threat, clampf(delta * 3.0, 0.0, 1.0))


func _drop_smiler(h: float) -> void:
	smiler.queue_free()
	smiler = null
	_smiler_occluded = 0.0
	hunt = h


func _spawn_smiler(p: Player) -> void:
	var cam := p.camera
	var f := -cam.global_transform.basis.z
	f.y = 0.0
	f = f.normalized().rotated(Vector3.UP, rt.randf_range(-0.25, 0.25))
	var d := 14.0
	var space: PhysicsDirectSpaceState3D = L.get_world_3d().direct_space_state
	var found := false
	# Try several directions. Never instantiate the face inside nearby walls.
	for offset in [0.0, -0.65, 0.65, -1.2, 1.2]:
		var direction := f.rotated(Vector3.UP, offset)
		var spawn_ray := PhysicsRayQueryParameters3D.create(cam.global_position, cam.global_position + direction * d, 1)
		spawn_ray.exclude = [p.get_rid()]
		var hit: Dictionary = space.intersect_ray(spawn_ray)
		var dist := d if hit.is_empty() else cam.global_position.distance_to(hit["position"]) - 1.2
		if dist >= 9.0:
			f = direction
			d = dist
			found = true
			break
	if not found:
		hunt = 0.5
		return
	smiler = Node3D.new()
	smiler.name = "Smiler"
	L.add_child(smiler)
	var k := GeoKit.new(smiler, "Face")
	k.shadows = false
	for s in [-1.0, 1.0]:
		k.quad(Vector3(s * 0.15, 0.1, 0), Vector3.BACK, Vector3(0.075, 0, 0), Vector3(0, 0.028, 0), "l1_smile")
	for i in 11:
		var t := -1.0 + 2.0 * i / 10.0
		k.quad(Vector3(t * 0.27, -0.1 - 0.09 * (1.0 - t * t), 0), Vector3.BACK, Vector3(0.026, 0, 0), Vector3(0, 0.02 + 0.016 * (1.0 - absf(t)), 0), "l1_smile")
	k.commit()
	var gl := OmniLight3D.new()
	gl.light_color = Color(1.0, 0.98, 0.9)
	gl.light_energy = 0.5
	gl.omni_range = 2.5
	smiler.add_child(gl)
	smiler.global_position = Vector3(cam.global_position.x, 1.6, cam.global_position.z) + f * d
	_interest = 5.0


# ------------------------------------------------- non-Euclidean halls (fold)

func _disorient(delta: float, p: Player) -> void:
	_lock_t -= delta
	if _lock_t <= 0.0:
		_lock_t = 0.25
		locked = _landmark_locked(p)
	if zone != "hall":
		dis = maxf(0.0, dis - delta * 0.3)
	elif locked:
		dis = maxf(0.0, dis - delta * 0.12)
	elif Vector2(p.velocity.x, p.velocity.z).length() > 0.6:
		dis = minf(1.1, dis + delta / 45.0)
	else:
		dis = maxf(0.0, dis - delta * 0.03)
	_fold_cd -= delta
	if dis >= 1.0 and _fold_cd <= 0.0 and zone == "hall" and fl == "calm" and not L.qa_fixture:
		_fold(p)
	_fold_fx = maxf(0.0, _fold_fx - delta * 2.5)
	var w := maxf(0.0, dis - 0.3) / 0.7
	p.camera.fov = base_fov + w * 8.0 * (0.55 + 0.45 * sin(Time.get_ticks_msec() * 0.0009))
	Overlay.set_screen_effect("desaturate", clampf(w * 0.3 + _fold_fx * 0.6, 0.0, 0.9))
	Overlay.set_screen_effect("blackout", _fold_fx * 0.85)


## A landmark held near the centre of view, in line of sight ("Walk towards it
## carefully, never looking away from it").
func _landmark_locked(p: Player) -> bool:
	var o := p.camera.global_position
	var fwd := -p.camera.global_transform.basis.z
	var space: PhysicsDirectSpaceState3D = L.get_world_3d().direct_space_state
	var cands: Array = []
	var kc: Vector2i = L.world.key_at(o)
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			cands.append_array(L.world.meta_of(kc + Vector2i(dx, dz)).get("lm", []))
	for c in crates.values():
		cands.append(c["pos"])
	for q in cands:
		var v: Vector3 = q - o
		var d := v.length()
		if d < 3.0 or d > 50.0 or fwd.dot(v / d) < 0.97:
			continue
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(o, q, 1))
		if hit.is_empty() or o.distance_to(hit["position"]) > d - 1.2:
			return true
	return false


## "Walking for a few dozens of seconds, yet finding yourself where you thought the
## horizon was" / "only to realize you barely moved": shift by whole 8 m bays so the
## pillar lattice lines up while the crates, walls and lights do not.
func _fold(p: Player) -> void:
	var f := -p.global_transform.basis.z
	var ax := Vector3(signf(f.x), 0, 0) if absf(f.x) > absf(f.z) else Vector3(0, 0, signf(f.z))
	var opts := [-16.0, 24.0, -24.0, 16.0, 32.0, -8.0]
	if rt.randf() < 0.5:
		opts.reverse()
	var space: PhysicsDirectSpaceState3D = L.get_world_3d().direct_space_state
	for dd in opts:
		var tp: Vector3 = p.global_position + ax * float(dd)
		var km: Dictionary = L.world.meta_of(L.world.key_at(tp))
		if km.is_empty() or km.get("authored", false) or in_block(km, tp):
			continue
		var q := PhysicsShapeQueryParameters3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = Player.RADIUS + 0.1
		cap.height = Player.HEIGHT_STAND
		q.shape = cap
		q.transform = Transform3D(Basis(), tp + Vector3.UP * (Player.HEIGHT_STAND * 0.5 + 0.05))
		q.collision_mask = 1
		if not space.intersect_shape(q, 1).is_empty():
			continue
		if space.intersect_ray(PhysicsRayQueryParameters3D.create(tp + Vector3.UP, tp + Vector3.DOWN, 1)).is_empty():
			continue
		p.global_position = tp
		_fold_fx = 1.0
		dis = 0.35
		_fold_cd = 45.0
		L.sound.play_at("distant_boom", {}, tp + Vector3.UP * 4.0, -8.0, "[a long groan runs through the pipes]")
		return


# ------------------------------------------------------------------ crates

func make_crate(parent: Node3D, id: String, pos: Vector3, yaw: float, size: Vector3, keep: bool = false) -> void:
	var st: String = cstate.get(id, "")
	if st == "gone":
		return
	var root := Node3D.new()
	root.name = "Crate_" + id
	parent.add_child(root)
	var k := GeoKit.new(root, "G")
	var c := pos + Vector3.UP * size.y * 0.5
	Kit.crate(k, c, size, yaw, st == "open")
	k.commit()
	if st != "open":
		var it := Interactable.new()
		root.add_child(it)
		it.setup(c, size + Vector3(0.08, 0.08, 0.08), "Pry open the crate", open_crate.bind(id))
		it.rotation.y = yaw
	crates[id] = {"root": root, "pos": c, "unseen": 0.0, "keep": keep and st != "open", "size": size, "yaw": yaw}
	root.tree_exiting.connect(_forget.bind(id, root))


func _forget(id: String, root: Node3D) -> void:
	if crates.has(id) and crates[id]["root"] == root:
		crates.erase(id)


func open_crate(p: Player, id: String) -> void:
	if cstate.get(id, "") != "" or not crates.has(id):
		return
	cstate[id] = "open"
	var rec: Dictionary = crates[id]
	var size: Vector3 = rec["size"]
	var c: Vector3 = rec["pos"]
	var parent: Node = (rec["root"] as Node3D).get_parent()
	(rec["root"] as Node3D).queue_free()
	crates.erase(id)
	make_crate(parent, id, c - Vector3.UP * size.y * 0.5, rec["yaw"], size)
	L.sound.play_at("creak", {"freq": 220.0}, c, -6.0, "[nails shriek as the lid comes off]")
	var cr := RandomNumberGenerator.new()
	cr.seed = hash([L.level_seed, id, "loot"])
	if id == "start":
		SaveService.set_flag("L001", "start_crate_open", true)
	# "Headlights or flashlight, to use in the corridors (but ... not ... in the halls!)"
	if (id == "start" or cr.randf() < 0.04) and SaveService.item_count("flashlight") == 0:
		SaveService.add_item("flashlight")
		p.flashlight_policy = "allowed"
		Overlay.toast("Inside: a working flashlight. Collectors' advice: use lights in the corridors, never in the halls. [%s] toggles it." % Settings.binding_text("flashlight"), 6.0)
		return
	var tot := 0
	for e in LOOT:
		tot += int(e[1])
	var pick := cr.randi() % tot
	for e in LOOT:
		pick -= int(e[1])
		if pick < 0:
			if str(e[0]) != "":
				SaveService.add_item(str(e[0]))
			var hp: float = e[3]
			if hp > 0.0:
				p.heal(hp)
			elif hp < 0.0:
				p.hurt(-hp, "Crate hazard")
			Overlay.toast("Inside the crate: %s." % e[2], 4.5)
			return


func _crate_step() -> void:
	_crate_t -= get_process_delta_time()
	if _crate_t > 0.0:
		return
	_crate_t = 0.5
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	for id in crates.keys():
		var c: Dictionary = crates[id]
		var q: Vector3 = c["pos"]
		if c["keep"] or cam.is_position_in_frustum(q) or q.distance_to(cam.global_position) < 9.0:
			c["unseen"] = 0.0
			continue
		c["unseen"] += 0.5
		if c["unseen"] > 35.0:
			c["unseen"] = 15.0
			if rt.randf() < 0.5:   # "crates can disappear once not looked at"
				cstate[id] = "gone"
				(c["root"] as Node3D).queue_free()
	if is_instance_valid(painting):
		var seen := cam.is_position_in_frustum(PAINT_AT) and cam.global_position.distance_to(PAINT_AT) < 30.0
		_paint_unseen = 0.0 if seen else _paint_unseen + 0.5
		if _paint_unseen > 14.0:   # paintings "have a tendency to disappear when not looked at"
			cstate["painting"] = "gone"
			painting.queue_free()


## "Usually appearing behind your back, or after a Flickering event".
func crate_behind() -> void:
	var p: Player = L.player
	if p == null or zone != "hall":
		return
	var f := -p.global_transform.basis.z
	f.y = 0.0
	f = f.normalized()
	var space: PhysicsDirectSpaceState3D = L.get_world_3d().direct_space_state
	for attempt in 8:
		var q := p.global_position - f * rt.randf_range(4.5, 8.0) + f.cross(Vector3.UP) * rt.randf_range(-2.5, 2.5)
		var key: Vector2i = L.world.key_at(q)
		if not L.world.chunks.has(key) or in_block(L.world.meta_of(key), q):
			continue
		var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(q + Vector3.UP, q + Vector3.DOWN * 0.6, 1))
		if hit.is_empty() or absf(float(hit["position"].y)) > 0.05:
			continue
		var sq := PhysicsShapeQueryParameters3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(1.1, 0.8, 1.1)
		sq.shape = bs
		sq.transform = Transform3D(Basis(), q + Vector3.UP * 0.5)
		sq.collision_mask = 1
		if not space.intersect_shape(sq, 1).is_empty():
			continue
		_spawn_n += 1
		make_crate(L.world.chunks[key]["node"], "s%d" % _spawn_n, Vector3(q.x, 0.0, q.z), rt.randf() * TAU, Vector3(0.8, 0.62, 0.66))
		return


func floor_painting(node: Node3D, p: Vector3) -> void:
	if cstate.get("painting", "") == "gone":
		return
	painting = Node3D.new()
	node.add_child(painting)
	var k := GeoKit.new(painting, "Painting")
	k.box(p + Vector3.UP * 0.02, Vector3(0.9, 0.04, 0.7), "l1_frame", GeoKit.ALL, false)
	k.box(p + Vector3.UP * 0.041, Vector3(0.78, 0.005, 0.58), "l1_canvas_b", GeoKit.PY, false)
	k.commit()


# ------------------------------------------------------------- rest, sound

func _rest(delta: float, p: Player) -> void:
	_rest_cd = maxf(0.0, _rest_cd - delta)
	var in_room := false
	for rc in meta.get("rooms", []):
		if (rc as Rect2).has_point(Vector2(p.global_position.x, p.global_position.z)):
			in_room = true
	if in_room and p.velocity.length() < 0.25 and not p.dead:
		_rest_t += delta
		if _rest_t > 5.0 and _rest_cd <= 0.0:
			_rest_cd = 90.0
			L.checkpoint("corridor_room")
			Overlay.toast("You rest in the corridors. Nothing here shifts; the walls stay where they are. (Checkpoint)", 4.0)
	else:
		_rest_t = 0.0


func _audio(delta: float, p: Player) -> void:
	var hall := zone == "hall"
	var on := lit > 0.5
	var u: float = meta.get("util", 0.0)
	var a := clampf(delta * 2.5, 0.0, 1.0)
	var want := {"hall": (-17.0 if hall else -32.0) if on else -75.0, "hum": (-29.0 if hall else -42.0) if on else -80.0,
		"corr": -60.0 if hall else (-22.0 if on else -34.0), "util": lerpf(-70.0, -15.0, u) if on else -75.0}
	for key in want.keys():
		var b: AudioStreamPlayer = _beds[key]
		b.volume_db = lerpf(b.volume_db, want[key], a)
	if fl != "calm" or not hall:
		return
	_amb_t -= delta
	if _amb_t > 0.0:
		return
	_amb_t = rt.randf_range(8.0, 20.0)
	var pos := p.global_position
	var leak := Vector3.INF
	for l in meta.get("leaks", []):
		if pos.distance_to(l) < 14.0:
			leak = l
	var roll := rt.randf()
	if leak != Vector3.INF and roll < 0.4:
		L.sound.play_at("drip", {"freq": rt.randf_range(900.0, 1300.0)}, leak + Vector3.UP * 0.2, -10.0, "[water dripping from a pipe]")
	elif roll < 0.75 or u > 0.3:
		L.sound.play_at("pipe_clank", {"f": rt.randf_range(140.0, 320.0)}, pos + Vector3(rt.randf_range(-15, 15), HH - 0.8, rt.randf_range(-15, 15)), -8.0 + u * 6.0, "[a pipe clangs overhead]")
	else:
		L.sound.play_at("distant_boom", {}, pos + Vector3(rt.randf_range(-30, 30), HH, rt.randf_range(-30, 30)), -14.0, "[a low rumble rolls through the pipes]")
