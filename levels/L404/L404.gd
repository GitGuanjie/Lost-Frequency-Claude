extends LevelBase
## Level 404 — "my dearly fragmented" (Backrooms Wikidot rev 79, accessed
## 2026-11-04; by etoisle, CC BY-SA 3.0). Dossier: docs/canon/levels/L404.md.
##
## The page is second-person prose with almost no geography, so this level is
## a stateful psychological space rather than a map. SOURCE images used:
## the 404th circle of heaven; planes that intersect, bisect and bend like a
## failing hard drive; a consciousness that may develop, to be cut out with
## the sharpest piece of the sky; broken but home; unable to think straight or
## in circles; the ground flickers; the 3D mesh glitches while memories cloud
## the mind and still the hands; a lovely day, a walk, no one else around; sweet
## air, a surface waiting for holes; a remembered girl who laughed in
## hexadecimal and led you to the skybox, then was forgotten; an empty
## paradise; "come home"; bases = your memories, your own mind; entrance by
## catatonia; no stated exit. NO ENTITY PER SOURCE.
## ADAPTATION (see level.json notes): the circle/platter layout, the bent ramp
## and upper ring, the walk to a broken corner of a literal skybox, the three
## memory panels, the awareness/stillness system, every line of narration.

const Shaders := preload("res://levels/L404/L404_shaders.gd")
const World := preload("res://levels/L404/L404_world.gd")
const Mind := preload("res://levels/L404/L404_mind.gd")

const HOME := Vector3(0.0, 0.05, -3.2)
const HOME_R := 7.5
const CATCH_Y := -21.0
const CRACK := Vector3(0.0, 2.0, 63.3)

const ARRIVE := ["oh. you're back.", "have you forgotten already? this is the 404th circle.", "it's a lovely day. walk with me?"]
const ARRIVE_FORGOT := ["welcome home.", "you've always been alone here. isn't it lovely?"]
const HOME_LINES := ["you like it here. everything says so.", "nothing is missing. well. almost nothing.",
	"it's all a little broken. it's still home.", "stay. there's no hurry. there's no anything."]
const STILL_LINES := ["your hands are so still.", "let it cloud over. memories are heavy things.",
	"you could stay like this. you could be happy."]
const AWAY_LINES := ["where are you going, dear?", "nobody out there. nobody anywhere. how wonderful.",
	"you're writing this down, aren't you? who for?", "who is saying this? you are. aren't you?"]
const AWARE_LINES := ["you're starting to think. we can fix that.",
	"if a thought gets in, cut it out. the sky has sharp edges.", "you can feel it. the shape of someone missing."]
const FRAG_TEXT := [
	"you were small. you found a heaven of your own, made of code, and there was a girl in it, written so carefully you thought gods had carved her.",
	"she took your hand. you walked a long, straight way together, and you never asked where to.",
	"she laughed in hexadecimal. 68 61 68 61. she led you right up to the skybox, and then"]

var world: World
var mind: Mind
var mats := {}
var rt := RandomNumberGenerator.new()
var qa_fixture := false
var aware := 0.0                 # the consciousness you are developing (0..1)
var calm := 0.0                  # how perfect paradise has become (stillness)
var still_t := 0.0
var hands := 1.0                 # memories still the hands: movement scale
var straight_t := 0.0
var turn_acc := 0.0
var turn_win := 0.0
var read := [false, false, false]
var blank := [false, false, false]
var has_shard := false
var cuts := 0
var folds := 0
var falls := 0
var circles := 0
var drops: Array = []            # [{tile, t}]
var _falling := false
var _fall_haze := 0.0
var _intro := 0.0
var _clock := 0.0
var _yaw_prev := 0.0
var _drop_t := 5.0
var _whisper_t := 25.0
var _hdd_t := 5.0
var _hdd_said := false
var _laugh_said := false
var _line_t := 30.0
var _straight_said := -99.0
var _pool_i := {}
var _home_cp := false
var _lock: Dictionary = {}
var _base := [3.1, 5.3]
var _cut_it: Interactable
var _shard_it: Interactable
var _frag_its: Array = []
var _pad: AudioStreamPlayer
var _tone: AudioStreamPlayer
var _laugh: AudioStreamPlayer3D


func build() -> void:
	qa_fixture = SessionState.is_qa()
	rt.seed = hash([level_seed, "mind"])
	rules["view_distance"] = 300.0
	rules["reverb_room"] = 0.85
	rules["reverb_wet"] = 0.24
	indoor_env(Color(0.74, 0.7, 0.96), 0.42, Color(0.98, 0.8, 0.88), 0.004)
	environment.background_color = Color(0.1, 0.02, 0.14)
	environment.tonemap_exposure = 0.92
	environment.glow_intensity = 0.42
	environment.glow_bloom = 0.04
	environment.glow_hdr_threshold = 1.15
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.08
	environment.adjustment_contrast = 1.08
	var sun := DirectionalLight3D.new()
	sun.name = "SquareSun"
	add_child(sun)
	sun.look_at_from_position(Vector3(64, 46, -10), Vector3.ZERO, Vector3.UP)
	sun.light_color = Color(1.0, 0.93, 0.87)
	sun.light_energy = 1.05
	sun.shadow_enabled = true
	sun.shadow_blur = 1.6
	sun.directional_shadow_max_distance = 90.0
	lights.setup(0, 0)
	_materials()
	world = World.new(self, rng, mats)
	world.build_all()
	for i in 3:
		var fn: Node3D = world.frag_nodes[i]
		var idx := i
		_frag_its.append(add_interactable(fn.global_position, Vector3(1.7, 1.5, 1.7), "Remember", func(_p): _remember(idx)))
	_shard_it = add_interactable(world.sharp.position, Vector3(0.8, 1.4, 0.8), "Take the sharpest piece of the sky", func(_p): _take_shard())
	_cut_it = add_interactable(Vector3(0, -50, 0), Vector3(0.45, 0.45, 0.45), "", func(_p): _cut())
	_cut_it.collision_layer = 0
	var crack := Area3D.new()
	crack.name = "BrokenCorner"
	crack.collision_layer = 0
	crack.collision_mask = 2
	crack.position = CRACK
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(4.6, 4.0, 1.5)
	cs.shape = bs
	crack.add_child(cs)
	add_child(crack)
	crack.body_entered.connect(func(b):
		if b is Player:
			_come_home("leave"))
	add_arrival("start", HOME, 180.0)
	mind = Mind.new()
	mind.name = "Mind"
	add_child(mind)
	mind.setup(hash([level_seed, "voice"]))
	_pad = sound.bed("pad", {"root": 196.0, "chord": [0, 4, 7, 11, 16], "bright": 0.2, "seconds": 12.0}, -30.0)
	_tone = sound.bed("room_tone", {"cutoff": 240.0}, -36.0)
	_laugh = sound.emitter("chiptune", Vector3(5.0, 6.0, 62.5), {"bpm": 210.0, "scale": [0, 4, 7, 12, 16], "root": 880.0}, -30.0, 20.0)
	add_landmark("Home (the centre of the circle)", Vector3.ZERO)
	add_landmark("The broken corner of the sky", CRACK)
	add_shot("circle", Vector3(1.1, 1.9, -6.2), Vector3(-0.5, 2.6, 30.0),
		{"prepare": func(): await _pose(0.05, 0.12, "it's a lovely day. walk with me?", Vector2(0.07, 0.24))})
	add_shot("skybox", Vector3(0.2, 1.7, 49.0), Vector3(-1.2, 4.4, 64.0),
		{"prepare": func(): await _pose(0.62, 0.0, "where are you going, dear?", Vector2(0.07, 0.62))})


func _shader_mat(code: String, params: Dictionary = {}) -> ShaderMaterial:
	var sh := Shader.new()
	sh.code = code
	var m := ShaderMaterial.new()
	m.shader = sh
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m


func _materials() -> void:
	var none := PackedFloat32Array([-9, -9, -9, -9, -9, -9, -9, -9])
	mats["disc"] = _shader_mat(Shaders.DISC, {"drop_ids": none})
	mats["disc_deep"] = _shader_mat(Shaders.DISC, {"drop_ids": none, "dim": 0.5})
	mats["plane"] = _shader_mat(Shaders.PLANE)
	mats["plane_b"] = _shader_mat(Shaders.PLANE, {"tint": Color(0.97, 0.86, 0.92), "line_col": Color(0.95, 0.5, 0.78)})
	mats["sky"] = _shader_mat(Shaders.SKY, {"crack_pos": Vector3(0.0, 3.0, World.SK), "crack_r": 6.5})
	mats["shard"] = _shader_mat(Shaders.SKY, {"shard_mode": 1.0})
	mats["shard_sharp"] = _shader_mat(Shaders.SKY, {"shard_mode": 1.0, "glint": 0.55})
	for i in 3:
		mats["frag%d" % i] = _shader_mat(Shaders.FRAG, {"seedv": 1.7 + i * 2.3, "kind": float(i)})
	for k in mats:
		MatLib.register("l404_" + k, mats[k])


# ------------------------------------------------------------- mechanics

## Remembering her is how the consciousness grows.
func _remember(i: int) -> void:
	if blank[i]:
		mind.say("it's empty. it was always empty.", 4.0)
		return
	mind.memory(FRAG_TEXT[i])
	if read[i]:
		return
	read[i] = true
	aware = minf(1.0, aware + 0.22)
	sound.play_at("whisper", {"seconds": 2.0}, (world.frag_nodes[i] as Node3D).global_position, -14.0, "[a whisper, close, about her]")
	if read.all(func(x): return x):
		mind.say("you remember her now. that's the trouble with remembering.", 6.0, 13.0)


func _take_shard() -> void:
	if has_shard:
		return
	has_shard = true
	world.sharp.visible = false
	_shard_it.prompt = ""
	sound.play_at("ui", {"kind": "click"}, world.sharp.position, -10.0, "[a thin, glassy note]")
	mind.say("the sharpest piece. careful. it's for later.", 5.0)
	_save_flag("shard", true)


## SOURCE: should a consciousness develop, cut it out with the sharpest piece
## of the sky. It works. What it costs: every memory you had read of her.
func _cut() -> void:
	if not has_shard or player == null:
		return
	cuts += 1
	aware = 0.0
	calm = maxf(calm, 0.45)
	mind.flash = 1.0
	mind.release_memory()
	Overlay.glitch(0.5)
	sound.play_at("crackle", {"seconds": 0.5}, player.global_position + Vector3.UP, -8.0, "[something gives, like glass]")
	var lost := false
	for i in 3:
		if read[i] and not blank[i]:
			blank[i] = true
			lost = true
	if lost:
		_forget_all()
		mind.say("there.", 3.0, 0.8)
		mind.say("quieter now. isn't that better?", 4.5)
		mind.say("who were you just thinking about?", 4.5, 9.0)
		mind.say("never mind. it's a lovely day.", 5.0, 6.0)
		_save_flag("forgot", true)
	else:
		mind.say("there. nothing left to think about.", 4.5, 0.8)


## "and then you forgot her forever": the panels go blank, her words go.
func _forget_all() -> void:
	for i in 3:
		if read[i] or blank[i]:
			blank[i] = true
			(mats["frag%d" % i] as ShaderMaterial).set_shader_parameter("blank", 1.0)
	for w in world.words:
		if not w["keep"]:
			(w["label"] as Label3D).text = ""


## Every way of leaving brings you home. ADAPTATION of "why would you ever
## want to leave paradise?" (the page states no exit).
func _come_home(why: String) -> void:
	if player == null:
		return
	folds += 1
	player.global_position = HOME
	player.rotation.y = PI
	player.velocity = Vector3.ZERO
	player.gravity = rules["gravity"]
	_falling = false
	_fall_haze = 0.0
	mind.flash = maxf(mind.flash, 0.85)
	Overlay.glitch(0.7)
	if why == "leave":
		aware = minf(1.0, aware + 0.25)
		mind.say("leave? from paradise? don't be silly.", 4.5, 0.5)
	else:
		falls += 1
		mind.say("come home.", 3.5, 0.6)


func _circle() -> void:
	circles += 1
	turn_acc = 0.0
	turn_win = 0.0
	Overlay.glitch(0.45)
	if player and not qa_fixture:
		var fwd := -player.global_basis.z * Vector3(1, 0, 1)
		var from := player.global_position + Vector3.UP
		var q := PhysicsRayQueryParameters3D.create(from, from + fwd.normalized() * 1.7, 1)
		if get_world_3d().direct_space_state.intersect_ray(q).is_empty():
			player.global_position += fwd.normalized() * 1.2
	mind.say("not in circles either.", 3.5)


func _drop_tile(t: Dictionary, secs: float) -> void:
	(t["shape"] as CollisionShape3D).disabled = true
	drops.append({"tile": t, "t": secs})
	_push_drops()
	if rt.randf() < 0.35:
		sound.play_at("ui", {"kind": "close"}, t["pos"], -18.0)


func _push_drops() -> void:
	var arr := PackedFloat32Array([-9, -9, -9, -9, -9, -9, -9, -9])
	for i in mini(8, drops.size()):
		arr[i] = float(drops[i]["tile"]["id"])
	(mats["disc"] as ShaderMaterial).set_shader_parameter("drop_ids", arr)


## "the ground flickers beneath your feet": while you are aware, tiles near
## you are briefly simply not there. Very aware, out past home, the tile under
## you may go too; the fall is through sweet air and ends at home.
func _drop_tick(delta: float, p: Vector3) -> void:
	var changed := false
	for d in drops.duplicate():
		d["t"] -= delta
		if d["t"] <= 0.0:
			(d["tile"]["shape"] as CollisionShape3D).disabled = false
			drops.erase(d)
			changed = true
	if changed:
		_push_drops()
	if aware < 0.35 or drops.size() >= 8:
		return
	_drop_t -= delta
	if _drop_t > 0.0:
		return
	_drop_t = lerpf(6.0, 1.4, aware) * rt.randf_range(0.6, 1.3)
	var near_min := 0.0 if aware > 0.82 else 2.2
	var cands: Array = []
	for t in world.tiles:
		if (t["y"] as float) > 1.0 or (t["r"] as float) < 9.0:
			continue
		var d := Vector2(p.x - t["pos"].x, p.z - t["pos"].z).length()
		var min_d := maxf(near_min, 2.2) if t.has("path") else near_min
		if d >= min_d and d < 9.0 and not drops.any(func(x): return x["tile"]["id"] == t["id"]):
			cands.append(t)
	if not cands.is_empty():
		_drop_tile(cands[rt.randi() % cands.size()], rt.randf_range(1.8, 3.4))


func _say_pool(key: String, pool: Array) -> void:
	var i: int = _pool_i.get(key, rt.randi() % pool.size())
	mind.say(pool[i % pool.size()], 5.0)
	_pool_i[key] = i + 1


func _save_flag(key: String, value: Variant) -> void:
	if SessionState.is_story():
		SaveService.set_flag(stable_id, key, value)


# --------------------------------------------------------------- runtime

func on_player_ready() -> void:
	_base = [player.walk_speed, player.sprint_speed]
	_yaw_prev = player.rotation.y
	if SessionState.is_story():
		has_shard = bool(SaveService.flag(stable_id, "shard", false))
		if has_shard:
			world.sharp.visible = false
			_shard_it.prompt = ""
		if SaveService.flag(stable_id, "forgot", false):
			blank = [true, true, true]
			_forget_all()
	if qa_fixture:
		return
	# SOURCE entrance: you arrive by entering catatonia — the view starts milky,
	# the hands still, and the voice is already talking.
	_intro = 1.0
	hands = 0.15
	var lines: Array = ARRIVE_FORGOT if blank[0] else ARRIVE
	for i in lines.size():
		mind.say(lines[i], 4.5, 1.5 if i == 0 else 1.2)


func level_process(delta: float) -> void:
	if player == null:
		return
	_clock += delta
	for s in world.air_shards:
		var n: Node3D = s["node"]
		n.rotation += (s["spin"] as Vector3) * delta
		n.position.y = (s["base"] as Vector3).y + sin(_clock * 0.3 + float(s["bob"])) * 0.45
	if not _lock.is_empty():
		aware = _lock["aware"]
		calm = _lock["calm"]
		_apply(delta)
		return
	var p := player.global_position
	var hv := Vector2(player.velocity.x, player.velocity.z).length()
	var moving := hv > 0.25
	var r := Vector2(p.x, p.z).length()
	var on_walk := p.z > World.PATH_Z0 - 1.0 and absf(p.x) < 5.5 and p.y > -1.5
	var at_home := r < HOME_R and absf(p.y) < 1.0
	# stillness: memories cloud the mind and still the hands
	if moving:
		still_t = 0.0
		hands = minf(1.0, hands + delta * 0.2)
	else:
		still_t += delta
		if still_t > 10.0:
			hands = maxf(0.3, hands - delta * 0.02)
	var calm_goal := clampf((still_t - 5.0) / 45.0, 0.0, 1.0) * (1.0 - aware * 0.6)
	calm = move_toward(calm, calm_goal, delta * (0.06 if calm_goal > calm else 0.5))
	_intro = maxf(0.0, _intro - delta / 7.0)
	if _intro > 0.0:
		hands = minf(hands, 1.0 - _intro * 0.85)
	player.walk_speed = _base[0] * hands
	player.sprint_speed = _base[1] * hands
	# unable to think straight, unable to think in circles
	var dy := wrapf(player.rotation.y - _yaw_prev, -PI, PI)
	_yaw_prev = player.rotation.y
	if moving:
		straight_t = straight_t + delta if absf(dy) < delta * 0.3 else maxf(0.0, straight_t - delta * 3.0)
		turn_acc += dy
		turn_win += delta
		if turn_win > 14.0:
			turn_acc = 0.0
			turn_win = 0.0
		if absf(turn_acc) > TAU * 0.95:
			_circle()
	else:
		straight_t = 0.0
	if straight_t > 3.5 and not Settings.get_value("reduce_motion") and not qa_fixture:
		player.rotate_y(sin(_clock * 0.8) * delta * 0.055 * (0.4 + aware))
		_yaw_prev = player.rotation.y
	if straight_t > 6.0 and _clock - _straight_said > 45.0:
		_straight_said = _clock
		mind.say("don't think in straight lines here.", 4.0)
	# the consciousness: grows with distance, the walk, straight lines and
	# remembering; home and stillness dissolve it
	var g := 0.0
	if r > 9.0:
		g += 0.004 * clampf((r - 9.0) / 17.0, 0.0, 1.2)
	if on_walk:
		g += 0.010 + 0.012 * clampf((p.z - World.PATH_Z0) / 35.0, 0.0, 1.0)
	if straight_t > 4.0:
		g += 0.004
	if at_home:
		g -= 0.006 if moving else 0.018
	if still_t > 8.0:
		g -= 0.01
	aware = clampf(aware + g * delta, 0.0, 1.0)
	if at_home and calm > 0.8 and not _home_cp:
		_home_cp = true
		checkpoint("home")
	# sweet air: falling is slow and ends at home
	if p.y < -1.5 and not _falling:
		_falling = true
		player.gravity = 2.6
		mind.say("the air is sweet down here. breathe it in.", 3.5)
	if _falling:
		_fall_haze = minf(1.0, _fall_haze + delta * 0.3)
	if p.y < CATCH_Y:
		_come_home("fall")
	_drop_tick(delta, p)
	for i in 3:
		if (world.frag_nodes[i] as Node3D).global_position.distance_to(p) > 6.0 and i == _nearest_frag(p):
			mind.release_memory()
	_cut_place(p)
	_narrate(delta, p, at_home, moving, on_walk)
	_apply(delta)


func _nearest_frag(p: Vector3) -> int:
	var best := 0
	for i in 3:
		if (world.frag_nodes[i] as Node3D).global_position.distance_to(p) < (world.frag_nodes[best] as Node3D).global_position.distance_to(p):
			best = i
	return best


## With the shard in hand and a thought taking shape, the cut is always one
## motion away: a prompt held just in front of the eyes.
func _cut_place(p: Vector3) -> void:
	var near_frag := (world.frag_nodes[_nearest_frag(p)] as Node3D).global_position.distance_to(p) < 3.5
	var ok := has_shard and aware > 0.2 and not near_frag
	_cut_it.collision_layer = 4 if ok else 0
	_cut_it.prompt = "Cut it out with the sharpest piece of the sky" if ok else ""
	if ok:
		var cam := player.camera
		_cut_it.global_position = cam.global_position - cam.global_basis.z * 0.7


func _narrate(delta: float, p: Vector3, at_home: bool, moving: bool, on_walk: bool) -> void:
	_line_t -= delta
	if _line_t <= 0.0 and not mind.busy():
		_line_t = rt.randf_range(22.0, 38.0)
		if aware > 0.6:
			_say_pool("aware", AWARE_LINES)
		elif aware > 0.25 and moving:
			_say_pool("away", AWAY_LINES)
		elif at_home and still_t > 25.0:
			_say_pool("still", STILL_LINES)
		elif at_home or calm > 0.3:
			_say_pool("home", HOME_LINES)
	_whisper_t -= delta * (0.3 + aware * 2.0)
	if _whisper_t <= 0.0:
		_whisper_t = rt.randf_range(30.0, 55.0)
		var cam := player.camera.global_position
		sound.play_at("whisper", {"seconds": 2.6}, cam + Vector3(rt.randf_range(-6, 6), 1.0, rt.randf_range(-6, 6)),
			-20.0 + aware * 6.0, "[hushed whispers, about her]")
	_hdd_t -= delta * (0.5 + aware * 1.5)
	if _hdd_t <= 0.0:
		_hdd_t = rt.randf_range(3.0, 9.0)
		var cap := "" if _hdd_said else "[somewhere in the sky, a hard drive ticks and seeks]"
		_hdd_said = true
		sound.play_at("crackle", {"seconds": 0.12}, p + Vector3(rt.randf_range(-20, 20), rt.randf_range(8, 25), rt.randf_range(-20, 20)), -24.0 + aware * 8.0, cap)
	if not _laugh_said and on_walk and p.z > 50.0:
		_laugh_said = true
		Overlay.subtitle("[near the broken sky: a small laugh, made of bytes]", 4.0)


func _apply(delta: float) -> void:
	var err := aware * (1.0 - calm * 0.7)
	for k in ["disc", "plane", "plane_b", "sky", "shard", "shard_sharp", "frag0", "frag1", "frag2"]:
		(mats[k] as ShaderMaterial).set_shader_parameter("err", err)
	for k in ["disc", "sky"]:
		(mats[k] as ShaderMaterial).set_shader_parameter("calm", calm)
	environment.adjustment_saturation = 1.08
	environment.adjustment_contrast = 1.08 + calm * 0.22 - err * 0.3
	environment.fog_density = 0.004 + calm * 0.003 + _fall_haze * 0.03
	mind.glitch = clampf((aware - 0.2) / 0.8, 0.0, 1.0) * 0.85
	mind.haze = clampf(calm * 0.55 + _fall_haze * 0.7 + _intro, 0.0, 1.0)
	if _pad:
		_pad.volume_db = lerpf(_pad.volume_db, lerpf(-30.0, -16.0, calm) - aware * 6.0, clampf(delta * 2.0, 0.0, 1.0))
		_tone.volume_db = lerpf(-36.0, -28.0, aware)
		_laugh.volume_db = -30.0 if not blank[2] else -80.0


# --------------------------------------------------------------- QA

func _pose(a: float, c: float, line: String, at: Vector2) -> void:
	_lock = {"aware": a, "calm": c}
	mind.frozen_style = true
	mind.clear_lines()
	if line != "":
		mind.pose_line(line, at)
	await get_tree().process_frame


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	var movers := find_children("*", "CharacterBody3D", true, false).filter(func(n): return n != player)
	out.append({"what": "no entity: nothing but the wanderer moves here", "ok": movers.is_empty(), "detail": movers.size()})
	out.append({"what": "no exit is built (the page states none)", "ok": exits.is_empty() and manifest.get("exits", []).is_empty()})
	var a0 := aware
	_remember(0)
	out.append({"what": "remembering her grows the consciousness", "ok": aware > a0 + 0.1, "detail": [a0, aware]})
	_cut()
	out.append({"what": "the cut needs the sharpest piece of the sky", "ok": aware > 0.1 and cuts == 0})
	_take_shard()
	_cut()
	out.append({"what": "the shard cuts it out, and she is forgotten", "ok": aware == 0.0 and blank[0] and cuts == 1, "detail": [aware, blank]})
	player.global_position = Vector3(0, CATCH_Y - 1.0, 40.0)
	level_process(0.016)
	out.append({"what": "falling through the holes ends at home", "ok": player.global_position.distance_to(HOME) < 0.5 and falls == 1})
	_come_home("leave")
	out.append({"what": "the broken corner of the sky does not let you leave", "ok": player.global_position.distance_to(HOME) < 0.5 and aware > 0.2})
	var t: Dictionary = world.tiles.filter(func(x): return (x["r"] as float) >= 9.0 and (x["y"] as float) < 1.0)[0]
	_drop_tile(t, 0.5)
	var dropped := (t["shape"] as CollisionShape3D).disabled
	_drop_tick(0.6, Vector3(0, 0, -200))
	out.append({"what": "the ground flickers: a missing tile is really missing, then returns", "ok": dropped and not (t["shape"] as CollisionShape3D).disabled})
	player.velocity = Vector3.ZERO
	still_t = 30.0
	hands = 1.0
	for i in 60:
		level_process(0.5)
	out.append({"what": "stillness clouds the mind and stills the hands", "ok": hands < 0.6 and calm > 0.2, "detail": [hands, calm]})
	out.append({"what": "the circle frays: holes in the outer rings, home intact", "ok": _holes_ok()})
	aware = 0.0
	calm = 0.0
	hands = 1.0
	player.walk_speed = _base[0]
	player.sprint_speed = _base[1]
	return out


func _holes_ok() -> bool:
	var inner := 0
	var outer := 0
	for t in world.tiles:
		if t.has("path") or (t["y"] as float) > 1.0:
			continue
		if (t["r"] as float) < 8.0:
			inner += 1
		elif (t["r"] as float) > 20.0:
			outer += 1
	var full_outer := 0
	for ring in range(10, 13):
		full_outer += world._sector_count(ring)
	return inner == 6 + world._sector_count(1) + world._sector_count(2) + world._sector_count(3) and outer < full_outer
