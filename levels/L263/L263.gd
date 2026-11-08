extends LevelBase
## Level 263 — "Pretty Pink" (Backrooms Wikidot rev 17, accessed 2026-11-04;
## cite: PixelPurple, CC BY-SA 3.0). Dossier: docs/canon/levels/L263.md.
## Content note (page): loneliness; a past visitor who walked until they
## collapsed. Nothing of them is shown but a backpack and a laptop.
##
## PLAN (v2.0 rebuild)
## SOURCE (Revision 4 is the article): a seemingly endless, repetitive hallway
## with large segmented windows on both sides; walls and carpet vibrant pink,
## the carpet slightly darker; the windows are solid surfaces of constantly
## changing static; a pitch-black ceiling ~17 m up; the level is a
## consciousness, Pink, who speaks through any device that can display text
## (she changed the text on Blair's camera screen, then used a laptop's
## text-to-speech); friendly, eager, sad when visitors leave; aware of
## everything inside, sees out only through the exit; a long-ago visitor with a
## laptop and a backpack walked for days and collapsed, and she used their
## laptop to post GPD drafts as "pretty_pink"; "maybe more than a hallway would
## be nice"; infinity hurts to think about; quiet, soft static, no buzzing, no
## monsters; entrances are static doors; exit: "simply turning around", always
## straight back to where you came from.
## ADAPTATION: corridor 9 m wide in 6 m bays, windows 3.6 x 7.8 m in 2 x 4
## panes; the camcorder's REC line is the "camera screen" Pink writes on; the
## visitor's laptop lies ~90 m in; the static door you came through always
## stays a short walk behind you (it is moved only while you face away), so
## turning around is always the way out (edge L263>EXT#1, to @origin). The
## hallway streams along -Z: a finite window, never a claim of infinity.
## No second walkable height: the page describes one flat corridor.
## Helper: L263_hall.gd (geometry, static shader, door, laptop).

const HALL := preload("res://levels/L263/L263_hall.gd")
const DOOR_Z := 4.0
const LAPTOP := Vector3(-2.4, 0.0, -92.0)

var hall
var world: ChunkWorld
var door: Node3D
var door_z := DOOR_Z
var exit_t: ExitTrigger
var screen: Label3D
var static_mat: ShaderMaterial
var door_mat: ShaderMaterial
var clock := 0.0
var queue: Array = []          # [text, seconds] lines Pink writes on your camera
var rec_msg := ""
var rec_t := 0.0
var talk := 0                  # laptop conversation step
var mood := 0.0                # -1 sad .. 1 happy
var mood_target := 0.0
var said := {}
var furthest := 0.0
var bed_static: AudioStreamPlayer
var talk_it: Interactable
var follow := true

const TALK := [
	["Say hello to the laptop", "hello! you found it! i'm so happy you're here. it's been so long since anyone came."],
	["Ask how she can see you", "i'm not sure. it's more like i'm aware of everything in here, the way you picture something in your head."],
	["Ask whose laptop this is", "someone walked in a long time ago. they walked for a very long time. they never noticed me. they collapsed after a few days. then i used their laptop."],
	["Ask why the place looks like this", "i think i just identified with it as time passed. it's... me. because i liked it."],
	["Ask if the hallway ends", "infinity is hard to comprehend. it could be. thinking about it too much hurts my head. whatever my head is."],
	["Ask what she would change", "maybe more than a hallway would be nice."],
	["Tell her you can't stay", "oh. that's okay. the way out is right behind you. it always is. i won't keep you. ...please visit again?"],
]


func build() -> void:
	hall = HALL.new(self)
	rules["view_distance"] = 260.0
	rules["reverb_room"] = 0.85
	rules["reverb_wet"] = 0.22
	rules["flashlight"] = "allowed"
	indoor_env(Color(1.0, 0.62, 0.78), 0.42, Color(0.6, 0.26, 0.4), 0.02)
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.6, 0.26, 0.4)
	environment.fog_sky_affect = 1.0
	environment.fog_light_energy = 1.0
	environment.tonemap_exposure = 1.0
	environment.glow_intensity = 0.5
	environment.glow_bloom = 0.08
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.08
	HALL.define_materials()
	static_mat = MatLib.get_mat("l263_static")
	door_mat = MatLib.get_mat("l263_door")
	lights.setup(14, 0)
	world = ChunkWorld.new()
	world.name = "Hallway"
	world.chunk_size = HALL.CHUNK
	world.radius = 6
	world.unload_radius = 7
	world.builder = _chunk
	world.chunk_unloaded.connect(func(k): lights.remove_group("c%d_%d" % [k.x, k.y]))
	add_child(world)
	world.build_around(Vector3(0, 0, 0), 6)
	door = hall.door_assembly(self)
	door.position.z = DOOR_Z
	exit_t = add_exit("L263>EXT#1", "walk_in", Vector3(0, 1.5, DOOR_Z + 0.9), Vector3(2.3, 3.0, 1.0), "")
	screen = hall.visitor_things(self, LAPTOP)
	talk_it = add_interactable(LAPTOP + Vector3(0.1, 0.35, 0.0), Vector3(1.2, 0.8, 1.2), TALK[0][0], _talk)
	add_interactable(LAPTOP + Vector3(-0.7, 0.3, 0.1), Vector3(0.8, 0.6, 0.9), "Open the laptop's drafts folder", _drafts)
	add_arrival("start", Vector3(0, 0.05, 0.0), 0.0)
	add_landmark("Static door (always behind you)", Vector3(0, 0, DOOR_Z))
	add_landmark("The visitor's backpack and laptop", LAPTOP)
	_sounds()
	add_shot("pink_hall", Vector3(0.6, 1.62, -1.0), Vector3(0.0, 3.2, -80.0), {"flashlight": false})
	add_shot("static_windows", Vector3(1.4, 1.62, -36.5), Vector3(4.6, 4.4, -46.0), {"flashlight": false})
	add_shot("visitor_laptop", LAPTOP + Vector3(0.55, 0.8, 1.05), LAPTOP + Vector3(-0.05, 0.12, -0.2), {"flashlight": false, "prepare": _prep_laptop})
	add_shot("turn_around", Vector3(-1.2, 1.62, -62.0), Vector3(0.0, 2.4, -42.0), {"flashlight": false, "prepare": _prep_turn})


func _chunk(cx: int, cz: int, _v: int, node: Node3D) -> Dictionary:
	if cx != 0:
		return {}
	var k := GeoKit.new(node, "Bay")
	var anchors: Array = hall.chunk(k, node, cz)
	k.commit()
	for a in anchors:
		lights.add_anchor(a, Color(0.95, 0.86, 0.92), 1.15, 10.0, 0.08, "c%d_%d" % [cx, cz])
	return {"z": cz}


func _sounds() -> void:
	bed_static = sound.bed("static", {"seconds": 4.0}, -34.0)
	sound.bed("room_tone", {"seconds": 6.0, "cutoff": 180.0, "rumble": 0.1}, -40.0)


# ---------------------------------------------------------------- Pink

func _say(key: String, text: String, secs: float = 4.5) -> void:
	if said.has(key):
		return
	said[key] = true
	queue.append([text, secs])


func _rec_write(delta: float) -> void:
	if rec_t > 0.0:
		rec_t -= delta
		if rec_t <= 0.0:
			rec_msg = ""
	if rec_msg == "" and not queue.is_empty():
		var q: Array = queue.pop_front()
		rec_msg = q[0]
		rec_t = q[1]
		Overlay.glitch(0.12)
		if Overlay.rec_label == null or Overlay.rec_label.text == "":
			Overlay.subtitle("[on your camera's screen: %s]" % rec_msg, rec_t)
	# the camcorder's own REC line is a device that displays text
	if rec_msg != "" and Overlay.rec_label != null and Overlay.rec_label.text != "":
		Overlay.rec_label.text = "●  " + rec_msg


func _talk() -> void:
	if talk >= TALK.size():
		_tts("please visit!")
		return
	_tts(TALK[talk][1])
	talk += 1
	mood_target = 1.0 if talk < TALK.size() else 0.4
	if talk == TALK.size():
		SaveService.record_discovery(stable_id, "l263:talked", "Talked with Pink through the visitor's laptop.", "SOURCE")
	talk_it.prompt = TALK[talk][0] if talk < TALK.size() else "Say goodbye"


func _tts(text: String) -> void:
	screen.text = HALL.screen_text(text)
	Overlay.subtitle("[the laptop, text-to-speech] \"%s\"" % text, 6.0)
	sound.play_at("ui", {}, LAPTOP + Vector3(0, 0.3, 0), -14.0)


func _drafts() -> void:
	Overlay.show_note("Drafts - account: pretty_pink", "draft 1 - level \"pretty pink.\"\nnothing here but the pretty pink and the soft static. it's quiet. no buzzing, no monsters. just you and me. please trust me. walk into the walls of static. it's easy, i promise.\n\n[reply from GPD staff: page removed - please follow the standard format.]\n\ndraft 2 - i'm pink. my windows lead to soft static. there's no one here but me. please visit. you could walk out any time. i can't keep you here. please just come back.\n\n[reply from GPD staff: second warning.]\n\ndraft 3 - PLEASE PLEASE PLEASE PLEASE PLEASE\n\n[a later email, from the account to Blair:] i just want someone to visit.\n\n(The laptop's owner is never named. Pink only remembers a backpack.)")
	mood_target = maxf(mood_target, 0.6)


# ---------------------------------------------------------------- process

func on_player_ready() -> void:
	screen.text = "hello?"


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	clock += delta
	var p := player.global_position
	furthest = minf(furthest, p.z)
	# Pink notices you
	if clock > 4.0:
		_say("hello", "hello?", 3.5)
	if clock > 8.0:
		_say("there", "is someone there?", 3.5)
	if clock > 13.0:
		_say("me", "it's me! pink! sorry, i didn't mean to startle you.", 5.0)
	if clock > 20.0:
		_say("hear", "i can hear you, you know. and i'm writing on your camera. is that okay?", 5.5)
	if clock > 28.0:
		_say("laptop", "there's a laptop further down the hall. it can talk out loud.", 5.5)
	if p.distance_to(LAPTOP) < 7.0:
		_say("near", "that's it! that's the one.", 3.5)
	if furthest < -260.0:
		_say("far", "you don't have to keep walking. i don't think it ends. the last one didn't stop.", 6.0)
	if furthest < -600.0:
		_say("far2", "please turn around. the way out is right behind you.", 5.0)
	# leaving: walking back towards the door after meeting her
	var dd := door_z - p.z
	if talk > 0 and dd < 14.0:
		_say("leave", "you're leaving?", 3.5)
		mood_target = -1.0
	if talk > 0 and dd < 7.0:
		_say("leave2", "please come back.", 4.0)
	_rec_write(delta)
	_follow_door(p)
	# her mood colours the static
	mood = move_toward(mood, mood_target, delta * 0.35)
	static_mat.set_shader_parameter("pinkness", clampf(0.15 + mood * 0.45, 0.0, 0.7))
	static_mat.set_shader_parameter("energy", 1.25 + mood * 0.25)
	door_mat.set_shader_parameter("pinkness", clampf(0.55 + mood * 0.35, 0.1, 1.0))
	if bed_static:
		bed_static.volume_db = lerpf(bed_static.volume_db, -34.0 - mood * 4.0, delta)


## The exit is "simply turning around": the static door you came in by is
## carried along behind you, but only while you are facing away from it.
func _follow_door(p: Vector3) -> void:
	if not follow or p.z > door_z - 34.0:
		return
	var fwd := -player.global_transform.basis.z
	var to_door := Vector3(0, 0, door_z - p.z).normalized()
	if fwd.dot(to_door) > -0.25:
		return
	_move_door(p.z + 20.0)


func _move_door(z: float) -> void:
	door_z = z
	door.position.z = door_z
	exit_t.global_position = Vector3(0, 1.5, door_z + 0.9)


func _prep_turn() -> void:
	follow = false
	_move_door(-42.0)
	world.build_around(Vector3(0, 0, -62.0), 6)
	await get_tree().process_frame


func _prep_laptop() -> void:
	follow = false
	screen.text = HALL.screen_text("hello! you found it! i'm so happy you're here.")
	world.build_around(LAPTOP, 2)
	await get_tree().process_frame


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "one exit: the static door behind you", "ok": exits.size() == 1})
	out.append({"what": "door is behind the arrival (facing into the hall)", "ok": door_z > (arrivals["start"] as Transform3D).origin.z})
	out.append({"what": "no creature nodes (Pink is the level itself)", "ok": find_children("*", "CharacterBody3D", true, false).size() == 1})
	out.append({"what": "laptop conversation scripted", "ok": TALK.size() >= 6 and talk == 0})
	out.append({"what": "curated stills", "ok": qa_shots.size() >= 4})
	return out
