extends LevelBase
## Level 71 "Void Basement" (Backrooms Wikidot rev 42, accessed 2026-11-04; Stretchsterz,
## CC BY-SA 3.0). Dossier: docs/canon/levels/L071.md. Page flagged outdated; its entry
## data "fails to load" by design (Error 0071) and its Exit section is a fading monologue.
##
## PLAN (read -> design):
## - SOURCE: "It appears to be an infinite basement." Nothing else is described. -> a
##   streamed basement (ChunkWorld, 24 m chunks of 6 m bays, seeded) built only from what a
##   basement is: a dusty slab, a 2.7 m ceiling on beams, concrete columns, block partitions
##   with doorways, ducts, pipe runs, cable trays, drains, caged bulbs (most dead), sunken
##   bays and bare machine plinths (two walkable heights besides the stair). No items, no
##   furniture, no set pieces: the dossier lists those as ABSENT.
## - SOURCE: "Finding a basement in Level 4 will lead you to Level 71. This entrance is
##   closed soon after." -> arrival at the foot of a concrete stair down from a Level 4 door;
##   once you walk away, the door slams and the doorway is a blank wall (stateful, one way).
## - SOURCE (diegetic): "There was an error while loading Entry data. Error 0071." -> an
##   M.E.G. printout at the stair foot whose Description/Group reload buttons fail; some bays
##   "failed to load" and show the void where their ceiling should be.
## - TESTIMONY (Exit section): dark, cold, dust and sand, body parts fading, "who am I",
##   layers of reality folding "like folding of laundry", "Fade into the Sh4de", the file
##   corrupts. -> SIGNATURE: a fade meter that only rises (faster in the dark). Colour drains,
##   the torch fails, subtitles slip into leetspeak, unseen parts of the basement fold into new
##   layouts behind you, and at the end the file corrupts. No exit is built (none is stated).
## - Entity policy: NO ENTITY PER SOURCE ("Who are you?" stays an unanswered line).

const Chunk := preload("res://levels/L071/L071_chunk.gd")

const STAIR_FOOT := Vector3(1.7, 0.0, 1.2)
const DOOR_Z := 8.6
const LANDING_Y := 2.88
const ERR := Vector3(0.245, 1.35, 0.0)          # printout on the column by the stair foot

var world: ChunkWorld
var qa := false
var fade := 0.0
var door_closed := false
var t_inside := 0.0
var door_node: Node3D
var wall_node: Node3D
var _groups := {}
var _said := {}
var _whisper_t := 25.0
var _corrupted := false
var _reloads := 0
var notes_found := 0

const LINES := [
	[0.06, "[It's so dark... Cold...]"],
	[0.14, "[Where am I?]"],
	[0.24, "[I can't feel my... My arms...]"],
	[0.34, "[I can still walk... But...]"],
	[0.44, "[Who... Who are you? Who am I?]"],
	[0.55, "[I am now fading into the past.]"],
	[0.66, "[Layers of reality start to collapse onto me. Like folding of laundry...]"],
	[0.76, "[The dust... Sand... I am one...]"],
	[0.86, "[Fade into the Sh4de]"],
	[0.94, "[I'm Fading... im fading... h3lp!]"],
]


func build() -> void:
	qa = SessionState.is_qa()
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 70.0
	rules["reverb_room"] = 0.62
	rules["reverb_wet"] = 0.28
	rules["walk_speed"] = 2.9
	indoor_env(Color(0.5, 0.52, 0.56), 0.05, Color(0.004, 0.0045, 0.005), 0.06)
	environment.tonemap_exposure = 1.7
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 0.85
	environment.adjustment_contrast = 1.08
	_materials()
	lights.setup(8, 0)
	world = ChunkWorld.new()
	world.name = "Basement"
	world.chunk_size = Chunk.CS
	world.radius = 2
	world.unload_radius = 3
	world.builder = _build_chunk
	world.can_shift = func(k: Vector2i, _m: Dictionary) -> bool: return k != Vector2i(0, 0) and fade > 0.5
	world.shift_after = 6.0
	world.chunk_unloaded.connect(_on_unloaded)
	add_child(world)
	world.build_around(STAIR_FOOT, 2)
	_stairwell()
	_sounds()
	add_arrival("start", STAIR_FOOT + Vector3(0, 0.02, -0.4), 0.0)
	add_arrival("from_L004", STAIR_FOOT + Vector3(0, 0.02, -0.4), 0.0)
	add_landmark("Stair down from Level 4 (closes)", STAIR_FOOT)
	add_landmark("Error 0071 printout", ERR)
	add_shot("stair_foot", Vector3(3.6, 1.6, -3.4), Vector3(1.7, 2.3, 6.0), {"flashlight": false})
	add_shot("basement", Vector3(2.2, 1.6, 0.0), Vector3(14.0, 1.0, -16.0), {"flashlight": true})
	add_shot("sunken_bay", Vector3(10.5, 1.65, 4.0), Vector3(15.0, -0.6, 9.0), {"flashlight": true})
	add_shot("dark_bays", Vector3(-1.5, 1.5, -3.0), Vector3(-12.0, 1.0, -18.0), {"flashlight": true})


func _photo(name: String, tex: String, tint: Color, scale: float, nrm: float = 1.0) -> void:
	var m := ORMMaterial3D.new()
	var base := "res://assets/external/%s/%s_%s_1k.jpg"
	m.albedo_texture = load(base % [tex, tex, "diff"])
	m.normal_enabled = true
	m.normal_texture = load(base % [tex, tex, "nor_gl"])
	m.orm_texture = load(base % [tex, tex, "arm"])
	m.albedo_color = tint
	m.uv1_triplanar = true
	m.uv1_scale = Vector3(scale, scale, scale)
	m.normal_scale = nrm
	MatLib.register(name, m)


func _materials() -> void:
	_photo("l71_floor", "dirty_concrete", Color(0.62, 0.6, 0.56), 0.3, 1.2)
	_photo("l71_concrete", "concrete", Color(0.66, 0.66, 0.65), 0.32)
	_photo("l71_ceiling", "concrete", Color(0.5, 0.5, 0.5), 0.28)
	MatLib.define("l71_block", {"albedo_a": Color(0.52, 0.52, 0.5), "albedo_b": Color(0.46, 0.46, 0.44), "pattern": 4,
		"pattern_scale": Vector2(0.4, 0.2), "grout_width": 0.008, "grout_color": Color(0.36, 0.36, 0.34),
		"stain_amount": 0.35, "stain_color": Color(0.33, 0.31, 0.27), "grime_height": 0.5, "grime_color": Color(0.3, 0.28, 0.24)}, "concrete")
	MatLib.define("l71_pipe", {"albedo_a": Color(0.32, 0.3, 0.27), "albedo_b": Color(0.24, 0.22, 0.2), "stain_amount": 0.4,
		"stain_color": Color(0.36, 0.22, 0.12)}, "metal")
	MatLib.define("l71_duct", {"albedo_a": Color(0.5, 0.52, 0.53), "albedo_b": Color(0.42, 0.44, 0.45), "pattern": 2,
		"pattern_scale": Vector2(1.2, 1.0), "pattern_strength": 0.2}, "metal")
	MatLib.define("l71_sand", {"albedo_a": Color(0.2, 0.19, 0.17), "albedo_b": Color(0.15, 0.14, 0.13), "noise_scale": 3.0, "roughness_a": 1.0}, "sand")
	MatLib.register("l71_bulb", MatLib.standard(Color(1, 0.9, 0.7), 0.4, 0.0, Color(1.0, 0.8, 0.5), 5.0))
	MatLib.register("l71_door", MatLib.standard(Color(0.42, 0.4, 0.35), 0.6, 0.2))
	MatLib.register("l71_l4light", MatLib.panel(Color(0.95, 0.95, 0.85), 2.2))


func _build_chunk(cx: int, cz: int, version: int, node: Node3D) -> Dictionary:
	var meta: Dictionary = Chunk.build(self, cx, cz, version, node)
	_groups[Vector2i(cx, cz)] = meta.get("group", "")
	return meta


func _on_unloaded(k: Vector2i) -> void:
	if _groups.has(k):
		lights.remove_group(_groups[k])
		_groups.erase(k)


## A scrap of paper in the dust with a few lines of the monologue (TESTIMONY).
func scrap(node: Node3D, p: Vector3, which: int) -> void:
	var frag := [
		"Hello?\nIt's so dark...\nCold...\nWhere am I?",
		"I can't feel my...\nMy arms...\nThe side of my body...\nI can still walk...",
		"Who...\nWho are you?\nWho am I?",
		"I am now fading into the past.\nI am forever missing in the shade.",
		"Layers of reality starts to collapse onto me.\nLike folding of laundry...",
		"The dust... Sand...\nI am one...",
	]
	var txt: String = frag[absi(which) % frag.size()]
	var it := make_interactable(p + Vector3(0, 0.05, 0), Vector3(0.5, 0.2, 0.5), "Read", func(_pl = null) -> void:
		notes_found += 1
		Overlay.subtitle("[a scrap of paper, written in pencil, words pressed hard:]", 2.5)
		Overlay.toast(_corrupt(txt + "\n\n(Level 71, Exit section: unreliable narration)"), 7.0), node)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.18, 0.003, 0.24)
	mi.mesh = bm
	mi.material_override = MatLib.get_mat("paper")
	mi.position = p + Vector3(0, 0.003, 0)
	mi.rotation.y = float(which % 628) * 0.01
	node.add_child(mi)
	it.name = "Scrap"


# ------------------------------------------------------------------ the stair from Level 4

func _stairwell() -> void:
	var k := kit("Stairwell")
	var x0: float = Chunk.SHAFT.position.x
	var x1: float = Chunk.SHAFT.end.x
	var z0: float = Chunk.SHAFT.position.y
	var top := 5.4
	# side walls of the shaft, from the floor up through the ceiling
	k.box_mm(Vector3(x0 - 0.2, 0.0, z0 + 0.4), Vector3(x0, top, DOOR_Z + 0.2), "l71_block")
	k.box_mm(Vector3(x1, 0.0, z0 + 0.4), Vector3(x1 + 0.2, top, DOOR_Z + 0.2), "l71_block")
	k.box_mm(Vector3(x0 - 0.2, top, z0), Vector3(x1 + 0.2, top + 0.2, DOOR_Z + 0.2), "l71_ceiling")
	# 16 risers of 0.18 m rising north from the foot to the landing
	var steps := 16
	var run := 0.28
	var s0 := z0 + 0.6
	k.stairs(Vector3((x0 + x1) * 0.5, 0.0, s0), Vector3(0, 0, 1), x1 - x0, LANDING_Y, steps, "l71_concrete", run)
	k.box_mm(Vector3(x0, 0.0, s0 + run * steps), Vector3(x1, LANDING_Y, DOOR_Z), "l71_concrete")
	# end wall above the landing door
	k.box_mm(Vector3(x0 - 0.2, LANDING_Y + 2.15, DOOR_Z), Vector3(x1 + 0.2, top, DOOR_Z + 0.2), "l71_block")
	k.box_mm(Vector3(x0 - 0.2, LANDING_Y, DOOR_Z), Vector3(x0 + 0.45, LANDING_Y + 2.15, DOOR_Z + 0.2), "l71_block")
	k.box_mm(Vector3(x1 - 0.45, LANDING_Y, DOOR_Z), Vector3(x1 + 0.2, LANDING_Y + 2.15, DOOR_Z + 0.2), "l71_block")
	# a handrail
	k.box_mm(Vector3(x1 - 0.08, 0.95, s0), Vector3(x1 - 0.04, 1.0, s0 + run * steps), "l71_pipe", GeoKit.ALL, false)
	k.commit()
	# the Level 4 door: open, office light spilling down the stairs
	door_node = Node3D.new()
	door_node.name = "Level4Door"
	add_child(door_node)
	var dk := GeoKit.new(door_node, "Door")
	dk.box_mm(Vector3(x0 + 0.45, LANDING_Y, DOOR_Z + 0.25), Vector3(x1 - 0.45, LANDING_Y + 2.15, DOOR_Z + 0.3), "l71_l4light", GeoKit.ALL, true)
	dk.box_xf(Transform3D(Basis(Vector3.UP, deg_to_rad(-70.0)), Vector3(x0 + 0.5 + 0.42, LANDING_Y + 1.06, DOOR_Z - 0.4)), Vector3(0.88, 2.1, 0.05), "l71_door", GeoKit.ALL, false)
	dk.commit()
	lights.add_anchor(Vector3((x0 + x1) * 0.5, LANDING_Y + 1.6, DOOR_Z - 0.6), Color(0.92, 0.95, 1.0), 1.4, 7.0, 0.08, "level4")
	wall_node = Node3D.new()
	wall_node.name = "ClosedDoorway"
	wall_node.visible = false
	add_child(wall_node)
	add_note("l71_error", "M.E.G. - Bettering Humanity (printout taped to the column)",
		"LEVEL 71\nLevel 71 is the 72nd level of the Backrooms. It appears to be an infinite basement.\n\nThere was an error while loading Entry data. Error 0071.\nPlease interact with the Description and Group categories to reload the data.\n\nSurvival class: {$one} / {$two} / {$three}",
		ERR, Vector3(0.15, 0.4, 0.3), false)
	var sheet := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.004, 0.29, 0.21)
	sheet.mesh = bm
	sheet.material_override = MatLib.get_mat("paper")
	add_child(sheet)
	sheet.position = ERR
	for cat in ["Description", "Group"]:
		add_interactable(ERR + Vector3(0.12, -0.32, 0.12 if cat == "Group" else -0.12), Vector3(0.2, 0.2, 0.2), "Reload " + cat, func(_p = null) -> void:
			_reloads += 1
			Overlay.toast("Reloading %s...\nThere was an error while loading Entry data. Error 0071." % cat, 4.0))


func _close_door() -> void:
	if door_closed:
		return
	door_closed = true
	if is_instance_valid(door_node):
		door_node.queue_free()
	lights.remove_group("level4")
	var x0: float = Chunk.SHAFT.position.x
	var x1: float = Chunk.SHAFT.end.x
	var wk := GeoKit.new(wall_node, "Blank")
	wk.box_mm(Vector3(x0 + 0.45, LANDING_Y, DOOR_Z), Vector3(x1 - 0.45, LANDING_Y + 2.15, DOOR_Z + 0.2), "l71_block")
	wk.commit()
	wall_node.visible = true
	if not qa:
		sound.play_at("knock", {"hits": 1}, Vector3((x0 + x1) * 0.5, LANDING_Y + 1.0, DOOR_Z), 4.0, "[up the stairs, the door slams. The light is gone.]")
		add_interactable(Vector3((x0 + x1) * 0.5, LANDING_Y + 1.0, DOOR_Z - 0.4), Vector3(1.2, 2.0, 0.6), "Feel for the door", func(_p = null) -> void:
			Overlay.subtitle(_corrupt("[cold block wall, the mortar old and dusty. There was never a door here.]"), 4.0))


func _sounds() -> void:
	sound.bed("room_tone", {"cutoff": 90.0, "rumble": 0.4, "seconds": 7.0}, -24.0)
	sound.bed("wind", {}, -38.0)
	sound.oneshot("pipe_clank", {"f": 140.0}, 22.0, 55.0, 30.0, "[somewhere in the dark, a pipe knocks once]", -20.0)
	sound.oneshot("crackle", {}, 18.0, 40.0, 8.0, "[sand trickles from a crack in the ceiling]", -26.0)


# ------------------------------------------------------------------ runtime

func on_player_ready() -> void:
	world.target = player
	if not qa:
		Overlay.subtitle("[the bottom of the stairs. Concrete, dust, a cold you can feel in your teeth.]", 5.0)
	checkpoint("stair_foot")


## Subtitles and notes slip into leetspeak as the fade grows.
func _corrupt(s: String) -> String:
	if fade < 0.35:
		return s
	var r := RandomNumberGenerator.new()
	r.seed = hash([s, int(fade * 10.0)])
	var out := ""
	var map := {"e": "3", "o": "0", "a": "4", "i": "1", "s": "5", "t": "7"}
	for ch in s:
		var lc := ch.to_lower()
		if map.has(lc) and r.randf() < (fade - 0.3) * 0.9:
			out += map[lc]
		elif ch != "\n" and ch != " " and r.randf() < (fade - 0.6) * 0.25:
			out += ""
		else:
			out += ch
	return out


func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var p := player.global_position
	t_inside += delta
	if not door_closed and (p.distance_to(STAIR_FOOT) > 9.0 or t_inside > 40.0):
		_close_door()
	if qa or _corrupted:
		return
	# the fade only rises; darkness speeds it
	var lit := player.flashlight.visible
	var near_bulb := false
	for l in lights.pool:
		if (l as OmniLight3D).visible and (l as OmniLight3D).global_position.distance_to(p) < 5.0:
			near_bulb = true
	fade = minf(1.0, fade + delta / 900.0 * (1.0 if (lit or near_bulb) else 1.8))
	environment.adjustment_saturation = lerpf(0.85, 0.05, fade)
	environment.fog_density = lerpf(0.06, 0.12, fade)
	environment.ambient_light_energy = lerpf(0.05, 0.008, fade)
	Overlay.set_screen_effect("desaturate", fade * 0.8)
	Overlay.set_screen_effect("vignette", 0.3 + fade * 0.5)
	Overlay.set_screen_effect("glitch", maxf(0.0, fade - 0.6) * 0.5)
	world.shift_enabled = fade > 0.5
	if lit and fade > 0.4:
		player.flashlight.light_energy = 2.2 * (1.0 - fade * 0.6) * (0.75 + 0.25 * absf(sin(Time.get_ticks_msec() * 0.013 * (1.0 + fade))))
	for l in LINES:
		if fade >= float(l[0]) and not _said.has(l[0]):
			_said[l[0]] = true
			sound.play_at("whisper", {}, p + Vector3(0, 1.6, 0) - player.global_transform.basis.z * -1.5, -6.0)
			Overlay.subtitle(_corrupt(l[1]), 5.0)
	_whisper_t -= delta
	if _whisper_t <= 0.0:
		_whisper_t = randf_range(35.0, 70.0) * (1.0 - fade * 0.6)
		var bk := -player.global_transform.basis.z
		sound.play_at("scratch", {}, p - bk * 6.0 + Vector3(0, 1.0, 0), -14.0, _corrupt("[behind you, something like cloth folding]") if fade > 0.6 else "")
	if fade >= 1.0:
		_corrupted = true
		Overlay.toast("File reached maximum text space of 500 MB. File reloading... File corrupted and no longer exists.", 6.0)
		player.hurt(1000.0, "faded into the Sh4de of Gr4y (Level 71)")


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out := []
	out.append({"what": "no exit is built (none stated); reason in level.json", "ok": exits.is_empty()})
	out.append({"what": "the basement streams in chunks around the stair", "ok": world.chunks.size() >= 20, "detail": world.chunks.size()})
	var was := door_closed
	_close_door()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var x := (Chunk.SHAFT.position.x + Chunk.SHAFT.end.x) * 0.5
	var q := PhysicsRayQueryParameters3D.create(Vector3(x, LANDING_Y + 1.0, DOOR_Z - 1.0), Vector3(x, LANDING_Y + 1.0, DOOR_Z + 1.5), 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	out.append({"what": "the Level 4 entrance closes behind you (blank wall)", "ok": door_closed and not hit.is_empty(), "detail": was})
	var f0 := fade
	fade = 0.8
	var c := _corrupt("there was an error while loading entry data")
	out.append({"what": "text corrupts into leetspeak as the fade grows", "ok": c != "there was an error while loading entry data", "detail": c})
	fade = f0
	if not is_instance_valid(world):
		return out
	var before := world.versions.duplicate()
	var k := Vector2i(2, 2)
	world.rebuild(k, true)
	out.append({"what": "unseen basement can fold into a new layout (peripheral shift)", "ok": int(world.versions.get(k, 0)) > int(before.get(k, 0))})
	return out
