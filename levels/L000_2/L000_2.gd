extends LevelBase
## Level 0.2 — "Remodeled Mess" (Backrooms Wiki rev 41, accessed 2026-11-04;
## cite: RowanLater, CC BY-SA 3.0). Dossier: docs/canon/levels/L000_2.md.
##
## DESIGN PLAN
## Space: one storey of a remodelled Level 0 office suite on a 3 m grid (27 x 36 m):
##   reception (arrival, the door you came in by) -> a straight hall -> lobby with the
##   older door back to Level 0. Off the hall: open-plan office, bathroom with stalls,
##   the crew's storage room, conference room, file room, break room, a sunken lounge
##   (three risers down: second walkable height), the foreman's site office with the
##   clipboard, a small office and a utility room. Dry red carpet, repainted white
##   walls, drop ceiling with troffers, outlets everywhere, Wi-Fi routers (SOURCE).
## Hidden structure (SOURCE "an unfinished house"): every wall sheet is a skin over
##   bare studs, the ceiling hangs under open floor joists and the carpet deck sits on
##   a crawlspace slab, so a collapse reveals real framing instead of a void.
## Signature mechanic (SOURCE): once you are inside (walked in, or touched something)
##   the level falls apart in a chain reaction that starts at the entrance and sweeps
##   toward the door back to Level 0, where it stops. Ceiling panels swing down or
##   drop, wall sheets topple onto the carpet, floor cells sag into the crawlspace.
##   Debris hurts if it lands on you; the dust that follows is dangerous to breathe
##   (fog + slow health loss). Re-entry rebuilds the pristine state (scene reload).
## Exit: the old door in the lobby's north wall (L000_2>L000#1, interact).
## Documents: the clipboard in the foreman's office holds Documents 1-3, paraphrased.
## Entities: none (page names none). No crew NPCs, no Level 1 exit.
## ADAPTATION: floor plan, room list beyond the bathroom, front speed (0.85 m/s),
##   damage numbers, the sag shape (two hinged half-panels) and the entry door that
##   stays shut are ours; the page gives no map or numbers.

const Geo := preload("res://levels/L000_2/L000_2_geo.gd")
const Dress := preload("res://levels/L000_2/L000_2_dress.gd")
const SPAWN := Vector3(0.0, 0.05, -1.1)
const FRONT_SPEED := 0.85
const FOG_BASE := 0.004

var geo
var dress
var armed := false
var stopped := false
var front_t := 0.0
var collapsed := 0
var notes_staged := 0
var hum: AudioStreamPlayer
var _order: Array = []
var _cough := 0.0
var _led_t := 0.0
var _dust_now := 0.0


func build() -> void:
	rules["reverb_room"] = 0.3
	rules["reverb_wet"] = 0.14
	rules["view_distance"] = 80.0
	rules["kill_y"] = -30.0
	indoor_env(Color(0.95, 0.93, 0.9), 0.15, Color(0.46, 0.43, 0.39), FOG_BASE)
	environment.background_color = Color(0.02, 0.018, 0.015)
	environment.tonemap_exposure = 0.95
	environment.glow_intensity = 0.25
	environment.glow_hdr_threshold = 1.0
	environment.adjustment_enabled = true
	environment.adjustment_saturation = 1.04
	environment.adjustment_contrast = 1.05
	_materials()
	lights.setup(14, 1)
	lights.max_distance = 24.0
	geo = Geo.new(self)
	geo.plan()
	geo.build()
	_doors()
	dress = Dress.new(self, geo)
	dress.dress()
	_light_cells()
	_schedule()
	if SessionState.is_qa():
		print("[L000_2] placed models: %d" % dress.props)
	add_arrival("start", SPAWN, 0.0)
	add_arrival("from_L000", SPAWN, 0.0)
	var ex := add_exit("L000_2>L000#1", "interact", Vector3(0.0, 1.05, -35.55), Vector3(1.4, 2.1, 1.0), "Open the old door back to Level 0")
	ex.fired.connect(func(_e): checkpoint("lobby_door"))
	add_interactable(Vector3(0.0, 1.05, -0.35), Vector3(1.3, 2.1, 0.6), "Try the door you came in by", _entry_door)
	_documents()
	add_landmark("Reception and the door you came in by", Vector3(0, 0, -2))
	add_landmark("Sunken lounge", Vector3(7.5, -0.54, -19.5))
	add_landmark("Foreman's site office (clipboard)", Vector3(4.5, 0, -27))
	add_landmark("Lobby: the old door back to Level 0", Vector3(0, 0, -34))
	hum = sound.bed("fluorescent_hum", {"base": 60.0, "rasp": 0.12}, -31.0)
	sound.bed("room_tone", {"cutoff": 320.0, "rumble": 0.2}, -30.0)
	sound.emitter("fluorescent_hum", Vector3(0, 1.2, -36.8), {"base": 60.0, "rasp": 0.45}, -14.0, 10.0)
	_shots()


func _materials() -> void:
	var m := func(n: String, base: String, x: Dictionary) -> void:
		MatLib.define(n, x, base)
	m.call("l02_carpet", "l0_carpet", {"albedo_a": Color(0.36, 0.045, 0.04), "albedo_b": Color(0.29, 0.03, 0.03), "wetness": 0.0,
		"stain_amount": 0.0, "roughness_a": 0.96, "roughness_b": 1.0, "bump_strength": 0.7, "noise_scale": 0.7})
	m.call("l02_carpet_pit", "l0_carpet", {"albedo_a": Color(0.33, 0.04, 0.035), "albedo_b": Color(0.27, 0.03, 0.03), "wetness": 0.0, "stain_amount": 0.0})
	m.call("l02_wall", "plaster", {"albedo_a": Color(0.78, 0.77, 0.74), "albedo_b": Color(0.75, 0.74, 0.71), "noise_scale": 0.7, "bump_strength": 0.2, "roughness_a": 0.82})
	m.call("l02_trim", "trim_white", {"albedo_a": Color(0.86, 0.86, 0.84), "albedo_b": Color(0.83, 0.83, 0.81)})
	m.call("l02_ceiling", "l0_ceiling", {"albedo_a": Color(0.8, 0.8, 0.78), "albedo_b": Color(0.77, 0.77, 0.75), "stain_amount": 0.04,
		"grout_color": Color(0.7, 0.7, 0.68), "pattern_scale": Vector2(0.6, 0.6)})
	m.call("l02_tileback", "plaster", {"albedo_a": Color(0.55, 0.52, 0.47), "albedo_b": Color(0.47, 0.44, 0.39), "noise_scale": 6.0, "bump_strength": 1.4})
	m.call("l02_art_a", "plaster", {"albedo_a": Color(0.25, 0.38, 0.45), "albedo_b": Color(0.62, 0.58, 0.48), "noise_scale": 2.2, "bump_strength": 0.1, "roughness_a": 0.4})
	m.call("l02_art_b", "plaster", {"albedo_a": Color(0.55, 0.42, 0.3), "albedo_b": Color(0.3, 0.4, 0.3), "noise_scale": 1.6, "bump_strength": 0.1, "roughness_a": 0.4})
	m.call("l02_art_frame", "metal", {"albedo_a": Color(0.12, 0.12, 0.12), "albedo_b": Color(0.1, 0.1, 0.1), "metallic_value": 0.4, "roughness_a": 0.4})
	m.call("l02_cardboard", "plaster", {"albedo_a": Color(0.55, 0.42, 0.27), "albedo_b": Color(0.48, 0.36, 0.22), "noise_scale": 4.0, "bump_strength": 0.3})
	m.call("l02_tape", "plaster", {"albedo_a": Color(0.7, 0.6, 0.42), "albedo_b": Color(0.66, 0.56, 0.4), "roughness_a": 0.3})
	m.call("l02_frame", "metal", {"albedo_a": Color(0.82, 0.82, 0.8), "albedo_b": Color(0.78, 0.78, 0.76), "metallic_value": 0.2, "roughness_a": 0.4})
	m.call("l02_grille", "metal", {"albedo_a": Color(0.6, 0.6, 0.6), "albedo_b": Color(0.5, 0.5, 0.5), "pattern": 1, "pattern_scale": Vector2(0.03, 0.03),
		"grout_width": 0.25, "grout_color": Color(0.1, 0.1, 0.1), "metallic_value": 0.3})
	m.call("l02_stud", "wood_floor", {"albedo_a": Color(0.7, 0.56, 0.38), "albedo_b": Color(0.6, 0.47, 0.31), "pattern": 0, "noise_scale": 3.5, "roughness_a": 0.9})
	m.call("l02_joist_rim", "wood_floor", {"albedo_a": Color(0.55, 0.42, 0.27), "albedo_b": Color(0.45, 0.33, 0.2), "pattern": 0, "noise_scale": 3.0})
	m.call("l02_ply", "wood_floor", {"albedo_a": Color(0.62, 0.48, 0.3), "albedo_b": Color(0.5, 0.37, 0.22), "pattern": 0, "noise_scale": 7.0})
	m.call("l02_osb", "wood_floor", {"albedo_a": Color(0.6, 0.47, 0.29), "albedo_b": Color(0.44, 0.32, 0.19), "pattern": 0, "noise_scale": 11.0, "bump_strength": 1.2})
	m.call("l02_insul", "plaster", {"albedo_a": Color(0.86, 0.56, 0.55), "albedo_b": Color(0.74, 0.44, 0.44), "noise_scale": 5.0, "bump_strength": 2.0, "roughness_a": 1.0})
	m.call("l02_slab", "concrete", {"albedo_a": Color(0.42, 0.41, 0.39), "albedo_b": Color(0.34, 0.33, 0.31)})
	m.call("l02_dirt", "dirt", {"albedo_a": Color(0.5, 0.48, 0.44), "albedo_b": Color(0.4, 0.38, 0.35)})
	m.call("l02_btile_floor", "pool_tile", {"albedo_a": Color(0.82, 0.83, 0.82), "albedo_b": Color(0.78, 0.79, 0.78), "pattern_scale": Vector2(0.3, 0.3), "grout_color": Color(0.55, 0.56, 0.55), "roughness_a": 0.3})
	m.call("l02_btile_wall", "pool_tile", {"albedo_a": Color(0.84, 0.86, 0.86), "albedo_b": Color(0.8, 0.82, 0.82), "pattern_scale": Vector2(0.15, 0.15)})
	m.call("l02_door", "trim_white", {"albedo_a": Color(0.82, 0.81, 0.78), "albedo_b": Color(0.79, 0.78, 0.75)})
	m.call("l02_door_old", "wood_floor", {"albedo_a": Color(0.56, 0.47, 0.3), "albedo_b": Color(0.47, 0.39, 0.24), "pattern": 0, "stain_amount": 0.6,
		"stain_color": Color(0.36, 0.3, 0.18), "grime_height": 0.6, "grime_color": Color(0.3, 0.25, 0.15)})
	m.call("l02_brass", "metal", {"albedo_a": Color(0.7, 0.58, 0.3), "albedo_b": Color(0.6, 0.48, 0.24), "metallic_value": 0.9, "roughness_a": 0.3})
	m.call("l02_metal", "metal", {"albedo_a": Color(0.62, 0.62, 0.6), "albedo_b": Color(0.54, 0.54, 0.52), "metallic_value": 0.5})
	m.call("l02_fabric", "plaster", {"albedo_a": Color(0.32, 0.35, 0.4), "albedo_b": Color(0.28, 0.31, 0.36), "noise_scale": 6.0, "bump_strength": 1.0, "roughness_a": 1.0})
	m.call("l02_laminate", "wood_floor", {"albedo_a": Color(0.6, 0.47, 0.33), "albedo_b": Color(0.52, 0.4, 0.28), "pattern_scale": Vector2(2.0, 0.3)})
	m.call("l02_counter_top", "plaster", {"albedo_a": Color(0.86, 0.84, 0.8), "albedo_b": Color(0.8, 0.79, 0.75), "roughness_a": 0.35})
	m.call("l02_cabinet", "plaster", {"albedo_a": Color(0.82, 0.81, 0.78), "albedo_b": Color(0.78, 0.77, 0.74), "roughness_a": 0.5,
		"pattern": 1, "pattern_scale": Vector2(0.6, 0.88), "grout_width": 0.006, "grout_color": Color(0.5, 0.5, 0.48)})
	m.call("l02_stall", "metal", {"albedo_a": Color(0.72, 0.7, 0.62), "albedo_b": Color(0.68, 0.66, 0.58), "metallic_value": 0.2, "roughness_a": 0.5})
	m.call("l02_paint_can", "metal", {"albedo_a": Color(0.85, 0.85, 0.83), "albedo_b": Color(0.75, 0.75, 0.73), "metallic_value": 0.4, "stain_amount": 0.3, "stain_color": Color(0.9, 0.9, 0.9)})
	m.call("l02_dropcloth", "plaster", {"albedo_a": Color(0.7, 0.68, 0.62), "albedo_b": Color(0.62, 0.6, 0.55), "noise_scale": 2.0, "stain_amount": 0.6, "stain_color": Color(0.88, 0.88, 0.86)})
	m.call("l02_board", "plaster", {"albedo_a": Color(0.92, 0.92, 0.92), "albedo_b": Color(0.9, 0.9, 0.9), "roughness_a": 0.15})
	m.call("l02_cork", "plaster", {"albedo_a": Color(0.55, 0.38, 0.22), "albedo_b": Color(0.45, 0.3, 0.17), "noise_scale": 9.0, "bump_strength": 1.0})
	m.call("l02_blueprint", "plaster", {"albedo_a": Color(0.12, 0.25, 0.55), "albedo_b": Color(0.16, 0.3, 0.6), "pattern": 1, "pattern_scale": Vector2(0.05, 0.05),
		"grout_width": 0.05, "grout_color": Color(0.7, 0.75, 0.9)})
	m.call("l02_rug", "l0_carpet", {"albedo_a": Color(0.5, 0.45, 0.38), "albedo_b": Color(0.42, 0.37, 0.3), "wetness": 0.0, "stain_amount": 0.0})
	m.call("l02_mat", "l0_carpet", {"albedo_a": Color(0.12, 0.12, 0.12), "albedo_b": Color(0.09, 0.09, 0.09), "wetness": 0.0})
	m.call("l02_duct", "metal", {"albedo_a": Color(0.66, 0.67, 0.68), "albedo_b": Color(0.55, 0.56, 0.57), "metallic_value": 0.7, "roughness_a": 0.4})
	m.call("l02_cable", "plaster", {"albedo_a": Color(0.1, 0.1, 0.1), "albedo_b": Color(0.08, 0.08, 0.08)})
	m.call("l02_router", "plaster", {"albedo_a": Color(0.12, 0.12, 0.13), "albedo_b": Color(0.1, 0.1, 0.11), "roughness_a": 0.4})
	m.call("l02_heater", "metal", {"albedo_a": Color(0.82, 0.82, 0.8), "albedo_b": Color(0.76, 0.76, 0.74), "metallic_value": 0.3})
	m.call("l02_mopsink", "pool_tile", {"albedo_a": Color(0.7, 0.7, 0.68), "albedo_b": Color(0.6, 0.6, 0.58)})
	MatLib.register("l02_trof", MatLib.panel(Color(0.96, 0.97, 1.0), 2.3))
	MatLib.register("l02_trof_dead", MatLib.panel(Color(0.12, 0.12, 0.12), 0.0, 0.0, 100.0))
	MatLib.register("l02_trof_flick", MatLib.panel(Color(0.96, 0.97, 1.0), 2.0, 1.0))
	MatLib.register("l02_l0glow", MatLib.panel(Color(1.0, 0.86, 0.45), 2.2))
	MatLib.register("l02_led", MatLib.panel(Color(0.3, 1.0, 0.45), 3.0))


## The entry door (shut behind you) and the older door back to Level 0.
func _doors() -> void:
	var k := kit("L02_Doors")
	for d in [[Geo.ENTRY_DOOR, "l02_door", 1.0], [Geo.EXIT_DOOR, "l02_door_old", -1.0]]:
		var c: Vector3 = d[0]
		var face: float = d[2]
		k.box(c + Vector3(0, Geo.DOOR_H * 0.5, 0), Vector3(Geo.DOOR_W, Geo.DOOR_H, 0.05), d[1])
		k.box(c + Vector3(0.36, 1.0, -0.05 * face), Vector3(0.05, 0.05, 0.07), "l02_brass", GeoKit.ALL, false)
		for sx in [-1.0, 1.0]:
			k.box(c + Vector3(sx * (Geo.DOOR_W * 0.5 + 0.035), Geo.DOOR_H * 0.5, 0), Vector3(0.07, Geo.DOOR_H, Geo.T + 0.04), "l02_trim", GeoKit.ALL, false)
		k.box(c + Vector3(0, Geo.DOOR_H + 0.035, 0), Vector3(Geo.DOOR_W + 0.14, 0.07, Geo.T + 0.04), "l02_trim", GeoKit.ALL, false)
	# Level 0's light and hum leak under the old door
	k.quad(Geo.EXIT_DOOR + Vector3(0, 0.004, 0.32), Vector3.UP, Vector3(0.48, 0, 0), Vector3(0, 0, 0.3), "l02_l0glow")
	k.box(Geo.EXIT_DOOR + Vector3(0, 0.012, 0.03), Vector3(Geo.DOOR_W, 0.02, 0.02), "l02_l0glow", GeoKit.ALL, false)
	k.commit()
	lights.add_anchor(Geo.EXIT_DOOR + Vector3(0, 0.25, 0.6), Color(1.0, 0.84, 0.45), 0.7, 2.6, 0.0, "door")


func _light_cells() -> void:
	for key in geo.cells.keys():
		var rec: Dictionary = geo.cells[key]
		if rec["lit"]:
			lights.add_anchor(rec["c"] + Vector3(0, Geo.H - 0.15, 0), Color(1.0, 0.96, 0.9), 1.15, 5.4, 0.0, "c%d_%d" % [key.x, key.y])
		if rec["work"]:
			Props.place(self, null, "ph/caged_hanging_light", rec["c"] + Vector3(0.4, 2.86, 0.3), rng.randf() * 180.0, 0.4)


## Collapse order: the front leaves the entrance and reaches the lobby door last.
func _schedule() -> void:
	for key in geo.cells.keys():
		var rec: Dictionary = geo.cells[key]
		rec["t"] = (-rec["c"].z - 1.5) / FRONT_SPEED + rng.randf_range(0.0, 2.2)
		rec["falls"] = rng.randf() < (0.85 if rec["room"] == "C" else 0.72)
		rec["warned"] = false
		var door_cell: bool = key.y == Geo.NJ - 1 and absi(key.x - 4) <= 1
		if not door_cell:
			_order.append(rec)
	_order.sort_custom(func(a, b): return a["t"] < b["t"])


func _documents() -> void:
	var c: Vector2 = geo.room_rect("E3").get_center()
	var base := Vector3(c.x - 0.15, 0.83, c.y - 0.35)
	var docs := [
		["L000_2_doc1", "Clipboard: Document 1",
			"[i]A printed company sheet clipped on top.[/i]\n\nBACKROOMS REMODELLING COMPANY\n\n\"True order comes through furniture.\"\n\nNothing else is printed on it."],
		["L000_2_doc2", "Clipboard: Document 2 (job order)",
			"[i]A typed job order (paraphrased).[/i]\n\nTarget: Level 0. Sector: A880-1. Objective: a Class-A remodelling job. Task force sent: 102-CX. Supervisor: Major Took.\n\nIn the job notes the supervisor tells the four-person crew this may be their only chance to keep their jobs: every job they lead ends badly, his superiors have noticed, and their 'leader' Cap'n will be punished for any more mistakes. \"Do good this time.\""],
		["L000_2_doc3", "Clipboard: Document 3 (torn)",
			"[i]A cheerful handwritten letter to Major Took (paraphrased).[/i]\n\nOne of the crew writes instead of working to say everything is fine over here, apart from a few things. They are working extra hard, apologise for all the exclamation marks, ask how home base is, and beg him to ask the higher-ups for a few more chances: most of the malfunctions were not their fault. Then it stops mid-word, \"I should probab\", and the rest of the page has been ripped off."],
	]
	for i in docs.size():
		var it := add_note(docs[i][0], docs[i][1], docs[i][2], base + Vector3(0.02 * i, 0.004 * i, 0.0))
		it.used.connect(func(_p): _arm("touched"))
		notes_staged += 1


func _shots() -> void:
	add_shot("reception", Vector3(3.6, 1.62, -0.7), Vector3(-1.5, 1.1, -7.0))
	add_shot("hall", Vector3(0.6, 1.62, -6.3), Vector3(-0.2, 1.3, -30.0))
	add_shot("office", Vector3(-2.3, 1.62, -6.8), Vector3(-10.0, 0.9, -15.0))
	add_shot("lounge", Vector3(2.1, 1.62, -15.6), Vector3(8.5, -0.2, -20.5))
	add_shot("break_room", Vector3(2.2, 1.62, -6.7), Vector3(10.5, 0.9, -12.5))
	add_shot("collapse_hall", Vector3(0.7, 1.62, -7.0), Vector3(-0.2, 1.5, -26.0), {"prepare": func(): _collapse_all(true)})
	add_shot("collapse_office", Vector3(-2.3, 1.62, -6.8), Vector3(-9.0, 1.6, -14.0))
	add_shot("old_door", Vector3(1.4, 1.62, -30.8), Vector3(0.0, 1.0, -36.0))


# ------------------------------------------------------------------ mechanic

func _entry_door() -> void:
	_arm("touched")
	Overlay.toast("The new door you came in by has settled into its frame and will not move. The page says a door leads back to Level 0; it will have to be another one.", 5.0)


func _arm(_why: String) -> void:
	if armed or SessionState.is_qa():
		return
	armed = true
	front_t = 0.0
	Overlay.subtitle("[a long crack runs through the fresh plaster behind you]", 4.0)
	sound.play_at("creak", {"freq": 70.0}, SPAWN + Vector3(0, 2.4, 0.6), -2.0)


func level_process(delta: float) -> void:
	if player == null:
		return
	var pp := player.global_position
	if not armed and not SessionState.is_qa() and Vector2(pp.x - SPAWN.x, pp.z - SPAWN.z).length() > 4.0:
		_arm("entered")
	if armed and not stopped:
		front_t += delta
		while not _order.is_empty() and (_order[0] as Dictionary)["t"] <= front_t:
			_collapse(_order.pop_front(), false)
		for rec in _order:
			if rec["t"] - front_t > 1.4:
				break
			if not rec["warned"]:
				rec["warned"] = true
				if (rec["c"] as Vector3).distance_to(pp) < 14.0 and rng.randf() < 0.5:
					sound.play_at("creak", {"freq": rng.randf_range(55.0, 110.0)}, rec["c"] + Vector3(0, 2.5, 0), -6.0)
		if _order.is_empty():
			_stop()
	_dust(delta, pp)
	_led_t += delta


func _stop() -> void:
	stopped = true
	if not SessionState.is_qa():
		Overlay.subtitle("[the noise stops at the old door. Dust settles.]", 4.5)


## One cell of the chain reaction. instant=true sets the end state with no
## animation, sound or damage (QA self-test and rendered stills).
func _collapse(rec: Dictionary, instant: bool) -> void:
	if rec["state"] != 0:
		return
	rec["state"] = 1
	collapsed += 1
	rec["dust"] = 1.0 if not instant else 0.0
	var key: Vector2i = rec["key"]
	var pv: Node3D = rec["ceil"]
	if rec["falls"] and pv:
		lights.remove_group("c%d_%d" % [key.x, key.y])
		if rec["trof"]:
			(rec["trof"] as MeshInstance3D).material_override = MatLib.get_mat("l02_trof_dead")
		var floor_y: float = geo.floor_y_at(rec["c"])
		var drop := Geo.H - floor_y - 0.06
		var axis := Vector3.ZERO
		var target := 0.0
		match rec["hinge"]:
			"west":
				axis = Vector3(0, 0, 1)
				target = -asin(clampf(drop / Geo.C, 0.0, 1.0))
			"east":
				axis = Vector3(0, 0, 1)
				target = asin(clampf(drop / Geo.C, 0.0, 1.0))
			"north":
				axis = Vector3(1, 0, 0)
				target = asin(clampf(drop / Geo.C, 0.0, 1.0))
		if axis == Vector3.ZERO:
			# four sections come down one after another and land askew
			var lag := 0.0
			for sp in rec["subs"]:
				var sv: Node3D = sp
				var rx := rng.randf_range(-0.38, 0.38)
				var rz := rng.randf_range(-0.38, 0.38)
				var ty: float = geo.floor_y_at(sv.position) + 0.03 + 0.75 * maxf(absf(sin(rx)), absf(sin(rz)))
				if instant:
					sv.position.y = ty
					sv.rotation = Vector3(rx, rng.randf_range(-0.4, 0.4), rz)
				else:
					var tw := create_tween()
					tw.tween_interval(lag)
					tw.tween_property(sv, "position:y", ty, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
					tw.parallel().tween_property(sv, "rotation", Vector3(rx, rng.randf_range(-0.4, 0.4), rz), 0.7)
					if lag == 0.0:
						tw.tween_callback(_impact.bind(rec))
				lag += rng.randf_range(0.1, 0.5)
		elif instant:
			pv.basis = Basis(axis, target)
		else:
			var tw := create_tween()
			tw.tween_method(func(v: float): pv.basis = Basis(axis, v), 0.0, target, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.tween_callback(_impact.bind(rec))
		if rec["work"]:
			lights.add_anchor(rec["c"] + Vector3(0.4, 2.55, 0.3), Color(1.0, 0.78, 0.5), 1.1, 6.0, 0.0, "w%d_%d" % [key.x, key.y])
	elif rec["trof"]:
		(rec["trof"] as MeshInstance3D).material_override = MatLib.get_mat("l02_trof_flick")
		for a in lights.anchors:
			if a.get("group", "") == "c%d_%d" % [key.x, key.y]:
				a["flicker"] = 0.7
	var delay := 0.25
	for w in rec["walls"]:
		var wp: Node3D = w["pivot"]
		var ang: float = w["sign"] * deg_to_rad(86.0)
		var wax: Vector3 = w["axis"]
		if instant:
			wp.basis = Basis(wax, ang)
		else:
			var tw := create_tween()
			tw.tween_interval(delay)
			tw.tween_method(func(v: float): wp.basis = Basis(wax, v), 0.0, ang, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.tween_callback(func(): sound.play_at("knock", {"hits": 1}, wp.global_position + Vector3(0, 0.3, 0), -4.0))
			delay += rng.randf_range(0.2, 0.7)
	for h in rec["deck"]:
		var hp: Node3D = h["pivot"]
		var hax: Vector3 = h["axis"]
		var ang2: float = h["sign"] * asin(0.55 / (Geo.C * 0.5))
		if instant:
			hp.basis = Basis(hax, ang2)
		else:
			var tw := create_tween()
			tw.tween_interval(delay)
			tw.tween_method(func(v: float): hp.basis = Basis(hax, v), 0.0, ang2, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	if not instant:
		var pct := float(collapsed) / maxf(1.0, float(geo.cells.size()))
		if hum:
			hum.volume_db = lerpf(-31.0, -60.0, pct)


func _impact(rec: Dictionary) -> void:
	var c: Vector3 = rec["c"]
	sound.play_at("distant_boom", {}, c + Vector3(0, 1.0, 0), -6.0)
	_puff(c + Vector3(0, 0.6, 0))
	if player and not player.dead:
		var r := Geo.cell_rect(rec["key"].x, rec["key"].y)
		var pp := player.global_position
		if r.grow(-0.2).has_point(Vector2(pp.x, pp.z)):
			player.hurt(22.0, "crushed by a falling ceiling")
			Overlay.subtitle("[ceiling panels come down on you]", 2.5)
			Overlay.glitch(0.4)


func _puff(pos: Vector3) -> void:
	var ps := CPUParticles3D.new()
	ps.one_shot = true
	ps.amount = 26
	ps.lifetime = 4.5
	ps.explosiveness = 0.85
	ps.direction = Vector3.UP
	ps.spread = 85.0
	ps.initial_velocity_min = 0.4
	ps.initial_velocity_max = 1.6
	ps.gravity = Vector3(0, -0.06, 0)
	ps.damping_min = 0.6
	ps.damping_max = 1.2
	ps.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	ps.emission_box_extents = Vector3(1.3, 0.4, 1.3)
	ps.scale_amount_min = 0.8
	ps.scale_amount_max = 2.2
	var q := QuadMesh.new()
	q.size = Vector2(0.9, 0.9)
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.albedo_color = Color(0.72, 0.7, 0.66, 0.16)
	q.material = mat
	ps.mesh = q
	ps.position = pos
	add_child(ps)
	ps.emitting = true
	get_tree().create_timer(5.0).timeout.connect(ps.queue_free)


## Plaster dust after each fall: local fog that thickens and slowly hurts.
func _dust(delta: float, pp: Vector3) -> void:
	var near := 0.0
	for key in geo.cells.keys():
		var rec: Dictionary = geo.cells[key]
		if rec["dust"] <= 0.0:
			continue
		rec["dust"] = maxf(0.0, rec["dust"] - delta / 45.0)
		var d := Vector2(rec["c"].x - pp.x, rec["c"].z - pp.z).length()
		near = maxf(near, rec["dust"] * clampf(1.0 - (d - 2.0) / 8.0, 0.0, 1.0))
	_dust_now = lerpf(_dust_now, near, clampf(delta * 0.8, 0.0, 1.0))
	environment.fog_density = FOG_BASE + _dust_now * 0.07
	if _dust_now > 0.5 and not player.dead:
		player.hurt(delta * 1.4 * _dust_now, "choked on plaster dust")
		_cough -= delta
		if _cough <= 0.0:
			_cough = 7.0
			Overlay.subtitle("[you cough; the plaster dust is thick]", 2.5)


func _collapse_all(instant: bool) -> void:
	for rec in _order.duplicate():
		_collapse(rec, instant)
	_order.clear()
	stopped = true
	_dust_now = 0.45
	environment.fog_density = FOG_BASE + 0.012
	environment.fog_light_color = Color(0.5, 0.47, 0.42)


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "one sourced exit: the door back to Level 0", "ok": exits.size() == 1})
	out.append({"what": "three recovered documents on the clipboard", "ok": notes_staged == 3})
	out.append({"what": "suite dressed with placed models", "ok": dress.props >= 60, "detail": dress.props})
	out.append({"what": "pristine on entry (nothing collapsed yet)", "ok": collapsed == 0 and not stopped, "detail": collapsed})
	var cells: int = geo.cells.size()
	_collapse_all(true)
	await get_tree().process_frame
	var door_intact := true
	for key in geo.cells.keys():
		if key.y == Geo.NJ - 1 and absi(key.x - 4) <= 1 and geo.cells[key]["state"] != 0:
			door_intact = false
	out.append({"what": "chain reaction collapses the suite", "ok": collapsed >= int(cells * 0.8), "detail": [collapsed, cells]})
	out.append({"what": "collapse stops at the door back to Level 0", "ok": door_intact and stopped})
	var sag := 0
	for k in geo.dip_cells:
		for h in geo.cells[k]["deck"]:
			if absf((h["pivot"] as Node3D).rotation.length()) > 0.2:
				sag += 1
	out.append({"what": "floor sags into the crawlspace of the unfinished house", "ok": sag >= 2, "detail": sag})
	out.append({"what": "dust raises the fog", "ok": environment.fog_density > FOG_BASE})
	return out
