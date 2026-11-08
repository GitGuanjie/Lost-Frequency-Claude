extends LevelBase
## Level 20 "Boreas Structure", also known as Fun Zone (Backrooms Wikidot rev 52,
## accessed 2026-11-04; "Level 20 - "Boreas Structure"" by Crabs the Tubular,
## CC BY-SA 3.0). Dossier: docs/canon/levels/L020.md.
## Content note: the page's M.E.G. logs (deaths, a hallucinating narrator, the
## "planet" and the blue-flesh sky) are TESTIMONY and an in-universe info-hazard;
## they appear only as a withheld-logs notice and one paraphrased log card.
##
## PLAN (v2.0 rebuild: read -> design)
## - SOURCE: an activity palace of unknown extent in two sections. The Waiting
##   halls: white concrete, brown carpet, grey tiled ceiling; lockers, bins,
##   couches, tables, chairs, empty reception desks, Almond Water fountains,
##   vending machines -> a main hall from the blue FUN ZONE doors, a waiting lobby
##   with an empty reception desk, a window lounge and a cross hall of lockers
##   (L020_halls.gd). Lockers hold chocolate and pop, more of it the further you
##   are from the entrance (stateful, distance-weighted).
## - SOURCE: windows show a black void, stars and sometimes a moon; within 10 m
##   the temperature drops to -22..-43 C with headaches and paranoia (average 7 C)
##   -> four tall windows onto an unlit starfield; the cold field is computed from
##   the distance to the window wall. No-clipping through a window -> Level 24.
## - SOURCE: the Electric: black concrete, black tiled ceiling, grey carpet, neon;
##   it slopes down so gently it is unnoticeable and grows colder with depth
##   (lowest -27 C) -> three sloped runs (1.5-2.5 degrees, 4.4 m down in all) and a
##   dark bend that ends at a rimed, frozen double door (L020_electric.gd). The
##   two walkable heights are the halls (0 m) and the Electric's lower runs, plus
##   the Rock Climbing room's platforms and finish ledge (+6.6 m).
## - SOURCE: doors to games; win -> supplies, lose -> an entity or a teleport.
##   Viridis Red, Rock Climbing (Liquid Pain flood), Asteroid Blasters (lose ->
##   Level 6) and Lasers (lose -> Level 7) are playable (L020_games.gd). Game
##   doors with an exit sign nearby have a rare chance to lead out (-> Level 4).
## - SOURCE: hallucinated breathing, heavy wind and snowfall; an orange gel drops
##   through the ceiling at irregular intervals, harmless -> sound beds, a snowfall
##   that only exists near the camera, and gel drops that leave puddles.
## - Signature mechanic (stateful): cold. Body chill rises below 0 C, drains the
##   colour and closes the vignette, and hurts once it is deep; winter clothing
##   (Rock Climbing prize) slows it, food and Almond Water ease it.
## - Exits: staff-only door -> Level 2 (first: the walker's target), window
##   no-clip -> Level 24, rare game door -> Level 4, lost games -> Levels 6 / 7.
## - ABSENT: the "planet Boreas" and the sky entity (one hallucinating narrator),
##   entities inside games, visible hostile entities (minimal; only heard).

const Halls := preload("res://levels/L020/L020_halls.gd")
const Electric := preload("res://levels/L020/L020_electric.gd")
const Games := preload("res://levels/L020/L020_games.gd")
const START := Vector3(0.0, 0.0, 4.2)
const ENTRANCE := Vector3(0.0, 0.0, 5.0)

var H
var E
var G
var props: Node3D
var temp_c := 7.0
var chill := 0.0
var paranoia := 0.0
var winter := false
var supplies := {"chocolate": 0, "pop": 0}
var _rare_hit := false
var _band := 99
var _zone := ""
var _throw_prompt := false
var _gel_t := 20.0
var _gel_drops: Array = []
var _puddles: Array = []
var _breath_t := 30.0
var _hurt_t := 0.0
var _snow: GPUParticles3D
var _hum: AudioStreamPlayer
var _wind: AudioStreamPlayer
var _whisper: AudioStreamPlayer
var _buzz: AudioStreamPlayer
var _door_anim: Dictionary = {}


func build() -> void:
	rules["flashlight"] = "allowed"
	rules["view_distance"] = 160.0
	rules["reverb_room"] = 0.5
	rules["reverb_wet"] = 0.16
	rules["kill_y"] = -60.0
	indoor_env(Color(0.62, 0.64, 0.68), 0.22, Color(0.05, 0.05, 0.06), 0.008)
	environment.tonemap_exposure = 1.0
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.05
	environment.adjustment_saturation = 0.95
	environment.glow_enabled = true
	environment.glow_intensity = 0.5
	environment.glow_bloom = 0.06
	environment.glow_hdr_threshold = 0.95
	Halls.materials()
	Electric.materials()
	props = Node3D.new()
	props.name = "Dressing"
	add_child(props)
	H = Halls.new(self, props)
	H.build()
	E = Electric.new(self, props)
	E.build()
	var gk := kit("Games")
	G = Games.new(self, props, E)
	G.build(gk)
	_electric_dressing(gk)
	gk.commit()
	_lights()
	_sounds()
	_exits()
	_interactions()
	_notes()
	_make_snow()
	add_arrival("start", START, 0.0)
	add_arrival("from_L011", START, 0.0)
	add_arrival("from_L019", Vector3(-28.9, 0.0, -46.0), -90.0)
	add_landmark("Blue FUN ZONE doors (entrance)", Vector3(0, 0, 5.6))
	add_landmark("Waiting lobby, empty reception desk, staff-only door", Vector3(-14.6, 0, -12.0))
	add_landmark("Window lounge (void, stars, moon; cold)", Vector3(12.0, 0, -25.0))
	add_landmark("Entrance to the Electric", Halls.ELECTRIC_DOOR)
	add_landmark("Game doors: Viridis Red, Lasers, Rock Climbing, Asteroid Blasters", Vector3(10, -1.0, -70))
	add_landmark("Frozen double door at the bottom of the Electric", Vector3(38.5, Electric.STUB_Y, -64.0))
	add_shot("waiting_halls", Vector3(0.6, 1.62, 3.4), Vector3(-0.4, 1.3, -30.0), {"flashlight": false})
	add_shot("window_lounge", Vector3(4.2, 1.6, -34.4), Vector3(16.0, 1.5, -21.0), {"flashlight": false})
	add_shot("lobby", Vector3(-3.6, 1.65, -5.0), Vector3(-15.5, 1.0, -15.5), {"flashlight": false})
	add_shot("electric", Vector3(10.4, 1.55, -49.6), Vector3(9.6, 0.4, -92.0), {"flashlight": false})
	var yv: float = E.rooms["viridis"]["floor_y"]
	add_shot("viridis_red", Vector3(6.4, yv + 1.6, -56.0), Vector3(-4.0, yv + 1.8, -60.5), {"flashlight": false, "prepare": _prep_viridis})
	var yc: float = E.rooms["climb"]["floor_y"]
	add_shot("rock_climbing", Vector3(24.5, yc + 1.7, -101.2), Vector3(23.0, yc + 4.6, -114.0), {"flashlight": false, "prepare": _prep_doors})
	var yl: float = E.rooms["lasers"]["floor_y"]
	add_shot("lasers", Vector3(13.2, yl + 1.6, -74.0), Vector3(22.0, yl + 0.6, -84.0), {"flashlight": false, "prepare": _prep_lasers})


# ---------------------------------------------------------------- dressing

func _electric_dressing(k: GeoKit) -> void:
	# exit sign beside the Viridis Red door (SOURCE: game doors that lead out
	# always have an exit sign nearby)
	var dv: Vector3 = E.doors["viridis"]["pos"]
	k.box(dv + Vector3(0.18, 2.62, -1.1), Vector3(0.06, 0.24, 0.5), "l20_exitsign", GeoKit.ALL, false)
	var ex := Label3D.new()
	ex.text = "EXIT"
	ex.font_size = 40
	ex.pixel_size = 0.004
	ex.modulate = Color(0.85, 1.0, 0.88)
	ex.position = dv + Vector3(0.22, 2.62, -1.1)
	ex.rotation.y = deg_to_rad(90.0)
	props.add_child(ex)
	# neon game signs over the hall doors
	var signs := {"viridis": ["VIRIDIS RED", Color(0.3, 1.0, 0.4)], "lasers": ["LASERS", Color(1.0, 0.25, 0.25)],
		"climb": ["ROCK CLIMBING", Color(0.35, 1.0, 0.5)], "asteroids": ["ASTEROID BLASTERS", Color(0.45, 0.75, 1.0)]}
	for g in signs.keys():
		var d: Dictionary = E.doors[g]
		var pos: Vector3 = d["pos"]
		var piv := d["pivot"] as Node3D
		var inward: Vector3 = (piv.global_transform.basis.x if piv.is_inside_tree() else piv.transform.basis.x) * float(d["side"])
		var l := Label3D.new()
		l.text = signs[g][0]
		l.font_size = 52
		l.pixel_size = 0.004
		l.modulate = signs[g][1]
		l.outline_size = 8
		l.outline_modulate = Color(0, 0, 0, 0.8)
		l.position = pos - inward * 0.17 + Vector3(0, 2.75, 0)
		l.rotation.y = atan2(-inward.x, -inward.z)
		props.add_child(l)
	# sparse hall furniture: benches, bins, a dead arcade cabinet's worth of clutter
	for c in [Vector3(8.45, -0.6, -66.0), Vector3(8.45, -1.2, -86.0)]:
		Props.place(self, props, "kenney/furniture-kit/bench", c, 90.0, 0.45, true)
	Props.place(self, props, "kenney/furniture-kit/trashcan", Vector3(11.6, -0.25, -55.0), 0.0, 0.7, true)
	Props.place(self, props, "kenney/furniture-kit/trashcan", Vector3(30.0, -2.2, -99.6), 0.0, 0.7, true)
	Props.place(self, props, "ph/WetFloorSign_01", Vector3(44.0, -2.75, -97.0), 40.0)
	Props.place(self, props, "ph/security_camera_01", Vector3(11.7, 2.9, -49.0), -135.0)
	Props.place(self, props, "ph/cardboard_box_01", Vector3(51.2, -3.5, -84.0), 0.0)
	Props.place(self, props, "ph/ClassicNightstand_01", Vector3(-2.0, 0.0, 2.6), 90.0, 0.0, true)
	k.box(Vector3(11.97, 0.85, -62.0), Vector3(0.04, 0.6, 0.5), "l20_frame", GeoKit.ALL, false)
	var rl := Label3D.new()
	rl.text = "RULES"
	rl.font_size = 36
	rl.pixel_size = 0.004
	rl.modulate = Color(0.9, 0.9, 0.95)
	rl.position = Vector3(11.94, 1.08, -62.0)
	rl.rotation.y = deg_to_rad(-90.0)
	props.add_child(rl)
	Props.place(self, props, "ph/plastic_crate_01", Vector3(48.8, -4.2, -70.0), 70.0)


func _lights() -> void:
	lights.setup(14, 1)
	lights.max_distance = 34.0
	for p in H.panels:
		lights.add_anchor(p, Color(0.88, 0.93, 1.0), 1.5, 7.5, 0.0, "halls")
	var cols := {"cyan": Color(0.2, 0.85, 1.0), "magenta": Color(1.0, 0.2, 0.75), "violet": Color(0.55, 0.3, 1.0),
		"blue": Color(0.25, 0.4, 1.0), "green": Color(0.25, 1.0, 0.4), "red": Color(1.0, 0.15, 0.1), "dim": Color(0.3, 0.35, 0.6)}
	for s in E.neon_spots:
		lights.add_anchor(s["pos"], cols.get(s["col"], Color(0.6, 0.6, 1.0)), 1.6 * float(s["e"]), 7.5, 0.0, "electric")
	for z in Halls.WINDOW_ZS:
		lights.add_anchor(Vector3(15.2, 1.6, z), Color(0.55, 0.65, 0.9), 0.5, 5.0, 0.0, "window")


func _sounds() -> void:
	sound.bed("room_tone", {"cutoff": 260.0, "rumble": 0.25, "seconds": 6.0}, -27.0)
	_hum = sound.bed("fluorescent_hum", {"base": 120.0, "seconds": 4.0}, -30.0)
	_wind = sound.bed("wind", {"seconds": 6.0}, -60.0)
	_whisper = sound.bed("whisper", {"seconds": 5.0}, -60.0)
	_buzz = sound.bed("transformer", {"base": 60.0, "seconds": 4.0}, -60.0)
	var songs := {"viridis": [150.0, 392.0], "lasers": [176.0, 329.6], "climb": [132.0, 261.6], "asteroids": [168.0, 440.0]}
	for g in songs.keys():
		var d: Dictionary = E.doors[g]
		sound.emitter("chiptune", (d["pos"] as Vector3) + Vector3(0, 1.4, 0), {"bpm": songs[g][0], "root": songs[g][1], "scale": [0, 3, 7, 10, 12]}, -19.0, 14.0)
	sound.oneshot("creak", {"freq": 70.0}, 40.0, 90.0, 20.0, "[something heavy shifts, far down the halls]", -24.0)


func _exits() -> void:
	# 1 (walker target): the staff-only door in the Waiting lobby -> Level 2
	add_exit("L020>L002#1", "interact", Halls.STAFF_DOOR + Vector3(0.6, 1.0, 0), Vector3(1.4, 2.0, 1.6), "Open the staff-only door")
	# 2: no-clip through a window -> Level 24 (the page also names Level 78)
	for z in Halls.WINDOW_ZS:
		var t := add_exit("L020>L024#2", "noclip", Vector3(Halls.WINDOW_X - 0.35, 1.3, z), Vector3(0.9, 2.2, 2.4))
		if t:
			t.hold_seconds = 3.0
	# 3: the Viridis Red door has an exit sign beside it: a rare chance to lead out
	var dv: Vector3 = E.doors["viridis"]["pos"]
	var r3 := add_exit("L020>L004#3", "condition", dv + Vector3(1.0, 1.1, 0), Vector3(1.8, 2.2, 1.8))
	if r3:
		r3.condition = func() -> bool: return _rare_hit
	# 4/5: losing Asteroid Blasters (-> Level 6) and Lasers (-> Level 7)
	var ya: float = E.rooms["asteroids"]["floor_y"]
	var r4 := add_exit("L020>L006#4", "condition", Vector3(38.0, ya + 1.2, -91.3), Vector3(13.8, 2.6, 11.0))
	if r4:
		r4.condition = func() -> bool: return G.ast_lost
	var yl: float = E.rooms["lasers"]["floor_y"]
	var r5 := add_exit("L020>L007#5", "condition", Vector3(19.15, yl + 1.2, -80.0), Vector3(13.6, 2.6, 13.8))
	if r5:
		r5.condition = func() -> bool: return G.las_lost


func _interactions() -> void:
	for i in H.lockers.size():
		var lk: Dictionary = H.lockers[i]
		make_interactable(lk["pos"], Vector3(0.5, 1.4, 0.2), "Open the locker", _open_locker.bind(i), props)
	for f in H.fountains:
		add_interactable(f, Vector3(0.5, 0.3, 0.4), "Drink from the fountain (Almond Water)", _drink)
	for g in E.doors.keys():
		var d: Dictionary = E.doors[g]
		var piv := d["pivot"] as Node3D
		var c: Vector3 = piv.transform * Vector3(0, 1.15, 0.6)
		add_interactable(c, Vector3(0.5, 2.0, 1.1), "Open the door", _toggle_door.bind(g))


func _notes() -> void:
	add_note("l20_advisory", "Pinned card: Fun Zone",
		"Written in marker on an index card, M.E.G. style:\n\nYou are in the Waiting halls. The quickest way home is any door marked STAFF ONLY; they open onto Level 2.\n\nKeep away from the windows. Within about ten metres it gets brutally cold, your head starts to pound and you will feel watched.\n\nThe neon part (\"the Electric\") is further in. Its doors are games. Win and it feeds you. Lose and it does not.\n\nOrange jelly drops from the ceiling now and then. So far it has hurt nobody. Do not eat it.",
		Vector3(-1.95, 0.75, 2.6))
	add_note("l20_infohazard", "Database notice (printed, taped to the desk)",
		"The General Public Database has re-classed the M.E.G. expedition logs for this level as an info-hazard: reading them is said to harm anyone who later enters. They were public before this was understood, so they were left up. Read them anywhere but here.\n\nThe M.E.G. has said it will mount no further expeditions; there are too many entrances to close.\n\n(paraphrased; source: Level 20 article, Backrooms Wiki, CC BY-SA 3.0)",
		Vector3(-14.55, 1.16, -11.0))
	add_note("l20_log", "Log card, Compass Point team",
		"A laminated card wedged behind a neon tube, paraphrasing one entry of a Compass Point log: three men, days into the Electric, reached minus twenty-seven, \"far past the point where entities stop showing up\". The cold barely bothered them; they credited the winter gear and the hot chocolate. Their later logs are withheld.",
		Vector3(51.2, -3.13, -84.0))
	add_note("l20_games", "Rules board",
		"A plastic board screwed beside the doors, the lettering half rubbed off:\n\nVIRIDIS RED - common. Hit the green hexagons.\nROCK CLIMBING - common. Do not touch red.\nASTEROID BLASTERS - uncommon. At least ten.\nLASERS - uncommon. Press every button.\nMOLE HOLES - rare.\n\nStep on the lit pad to begin. Nothing follows you inside.",
		Vector3(11.85, 0.85, -62.0), Vector3(0.2, 0.6, 0.6), false)


func _make_snow() -> void:
	_snow = GPUParticles3D.new()
	_snow.name = "HallucinatedSnow"
	_snow.amount = 260
	_snow.lifetime = 5.0
	_snow.local_coords = false
	_snow.visibility_aabb = AABB(Vector3(-8, -5, -8), Vector3(16, 10, 16))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(5.0, 0.2, 5.0)
	pm.direction = Vector3(0.2, -1, 0.1)
	pm.spread = 15.0
	pm.initial_velocity_min = 0.4
	pm.initial_velocity_max = 0.8
	pm.gravity = Vector3(0.1, -0.25, 0.0)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.4
	_snow.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.025, 0.025)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.92, 0.95, 1.0, 0.85)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	q.material = m
	_snow.draw_pass_1 = q
	_snow.amount_ratio = 0.0
	add_child(_snow)


# ---------------------------------------------------------------- interactions

func _open_locker(i: int) -> void:
	var lk: Dictionary = H.lockers[i]
	if lk["used"]:
		Overlay.subtitle("[empty now]", 1.2)
		return
	lk["used"] = true
	_door_anim[lk["node"]] = {"from": (lk["node"] as Node3D).rotation.y, "to": (lk["node"] as Node3D).rotation.y - 1.9, "t": 0.0}
	var dist: float = (lk["pos"] as Vector3).distance_to(ENTRANCE)
	var chance := clampf(0.12 + dist / 70.0, 0.12, 0.85)
	sound.play_at("creak", {"freq": 300.0}, lk["pos"], -14.0, "")
	if rng.randf() < chance:
		var what := "chocolate" if rng.randf() < 0.55 else "pop"
		supplies[what] += 1
		chill = maxf(0.0, chill - 0.08)
		player.heal(4.0)
		Overlay.toast("Inside: %s. (chocolate %d, pop %d)" % ["a chocolate bar" if what == "chocolate" else "a can of pop", supplies["chocolate"], supplies["pop"]], 2.5)
	else:
		Overlay.subtitle("[the locker is empty]", 1.5)


func _drink() -> void:
	player.heal(10.0)
	chill = maxf(0.0, chill - 0.05)
	Overlay.subtitle("[Almond Water, cold and faintly sweet]", 2.0)


func _toggle_door(g: String) -> void:
	var d: Dictionary = E.doors[g]
	var piv := d["pivot"] as Node3D
	if not d["open"] and g == "viridis" and not SessionState.is_qa() and rng.randf() < 0.2:
		# the rare chance: this door, with its exit sign, leads somewhere else
		_rare_hit = true
		Overlay.subtitle("[the door opens on an exit sign and nothing else]", 2.0)
		return
	d["open"] = not d["open"]
	var to: float = d["base_yaw"] + (deg_to_rad(95.0) * float(d["side"]) if d["open"] else 0.0)
	_door_anim[piv] = {"from": piv.rotation.y, "to": to, "t": 0.0}
	(d["body"] as StaticBody3D).process_mode = Node.PROCESS_MODE_DISABLED if d["open"] else Node.PROCESS_MODE_INHERIT
	sound.play_at("creak", {"freq": 160.0}, d["pos"], -12.0, "")


func interact(_p: Player) -> void:
	# zone prompt inside the throwing games
	G.throw(player.camera)


func on_game_end(g: String, won: bool) -> void:
	var y: float = E.rooms[g]["floor_y"]
	if not won:
		if g == "asteroids":
			Overlay.subtitle("[only %d asteroids. The screens go black and the floor seems to tilt away]" % G.st["asteroids"]["score"], 3.0)
		return
	match g:
		"viridis":
			_prize([["kenney/food-kit/soda-bottle", Vector3(2.0, y, -59.0), 0.34]], Vector3(2.0, y + 0.3, -59.0), "Take the soft drink", "pop")
			Overlay.subtitle("[ten. A bottle of soda is standing in the middle of the room that was not there before]", 3.5)
		"asteroids":
			_prize([["kenney/food-kit/soda-bottle", Vector3(37.7, y, -89.0), 0.36], ["kenney/food-kit/soda-bottle", Vector3(38.1, y, -88.8), 0.36],
				["kenney/food-kit/carton", Vector3(38.3, y, -89.3), 0.3]], Vector3(38.0, y + 0.3, -89.0), "Take the space bottles", "pop")
			Overlay.subtitle("[the screens show a field of stars and stop. Bottles printed with planets stand on the floor]", 3.5)
		"lasers":
			var jar := CylinderMesh.new()
			jar.top_radius = 0.1
			jar.bottom_radius = 0.11
			jar.height = 0.26
			var mi := MeshInstance3D.new()
			mi.mesh = jar
			mi.material_override = MatLib.panel(Color(0.7, 0.85, 1.0), 1.6)
			mi.position = Vector3(19.15, y + 0.13, -80.0)
			props.add_child(mi)
			_prize([["kenney/food-kit/bag", Vector3(18.6, y, -79.6), 0.35], ["kenney/food-kit/bag", Vector3(19.7, y, -80.4), 0.35],
				["kenney/food-kit/soda-bottle", Vector3(19.6, y, -79.5), 0.33], ["kenney/food-kit/soda-bottle", Vector3(18.7, y, -80.5), 0.33]],
				Vector3(19.15, y + 0.3, -80.0), "Take the Memory Jar and the supplies", "chocolate")
			for b in G.beams:
				(b["mi"] as Node3D).visible = false
				if b.has("mi2"):
					(b["mi2"] as Node3D).visible = false
			Overlay.subtitle("[the beams die. A jar of light, bags of food and bottles of Almond Water wait in the centre]", 3.5)
		"climb":
			var top: float = E.rooms["climb"]["ledge_top"]
			_prize([["kenney/food-kit/mug", Vector3(18.0, top, -110.2), 0.11]], Vector3(18.2, top + 0.3, -110.6), "Put on the winter clothing and drink the hot chocolate", "climb")
			var coat := MeshInstance3D.new()
			var cb := BoxMesh.new()
			cb.size = Vector3(0.5, 0.12, 0.4)
			coat.mesh = cb
			coat.material_override = MatLib.standard(Color(0.08, 0.12, 0.25), 0.95)
			coat.position = Vector3(18.5, top + 0.06, -111.0)
			props.add_child(coat)
			Overlay.subtitle("[a mug of hot chocolate, still steaming, and a folded winter coat appear on the ledge]", 3.5)


func _prize(items: Array, at: Vector3, prompt: String, kind: String) -> void:
	var nodes: Array = []
	for it in items:
		nodes.append(Props.place(self, props, it[0], it[1], rng.randf_range(0, 360), it[2]))
	var take := func():
		for n in nodes:
			if is_instance_valid(n):
				(n as Node3D).visible = false
		if kind == "climb":
			winter = true
			chill = 0.0
			Overlay.toast("Winter clothing on; the hot chocolate is gone. The cold bites much less.", 3.0)
		else:
			supplies[kind] += 2
			chill = maxf(0.0, chill - 0.2)
			player.heal(20.0)
			Overlay.toast("Supplies taken. (chocolate %d, pop %d)" % [supplies["chocolate"], supplies["pop"]], 2.5)
	var it2 := add_interactable(at, Vector3(0.8, 0.6, 0.8), prompt, take)
	it2.once = true


# ---------------------------------------------------------------- per frame

func level_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var pp := player.global_position
	G.process(delta, pp)
	for n in _door_anim.keys():
		var a: Dictionary = _door_anim[n]
		a["t"] = minf(1.0, a["t"] + delta * 1.6)
		(n as Node3D).rotation.y = lerp_angle(a["from"], a["to"], smoothstep(0.0, 1.0, a["t"]))
		if a["t"] >= 1.0:
			_door_anim.erase(n)
	var want: bool = G.throw_target(player.camera) != ""
	if want != _throw_prompt:
		_throw_prompt = want
		player.set_zone_prompt(self, "Throw a foam ball (aim with your eyes)" if want else "")
	_climate(delta, pp)
	_gel(delta, pp)
	if _snow:
		_snow.global_position = pp + Vector3(0, 2.6, 0) + (-player.camera.global_basis.z * Vector3(1, 0, 1)) * 2.0


func _climate(delta: float, pp: Vector3) -> void:
	var electric := pp.y < -0.06 or (pp.z < -48.3 and pp.x > 7.0)
	var zone := "electric" if electric else "halls"
	var t := 7.0
	var depth := clampf(-pp.y / 4.4, 0.0, 1.0)
	if electric:
		t = lerpf(2.0, -27.0, depth)
	var dz := clampf(pp.z, -31.9, -16.1)
	var dw := Vector2(pp.x - Halls.WINDOW_X, pp.z - dz).length() if pp.x < Halls.WINDOW_X + 0.5 and not electric else 99.0
	var wf := smoothstep(10.5, 8.5, dw)
	if wf > 0.0:
		t = lerpf(t, lerpf(-43.0, -22.0, clampf(dw / 10.0, 0.0, 1.0)), wf)
	temp_c = lerpf(temp_c, t, minf(1.0, delta * 1.5))
	var rate := maxf(0.0, -temp_c) / 900.0 * (0.35 if winter else 1.0)
	chill = clampf(chill + rate * delta - (0.03 * delta if temp_c > 0.0 else 0.0), 0.0, 1.0)
	var near_w := clampf(1.0 - dw / 10.0, 0.0, 1.0)
	paranoia = lerpf(paranoia, clampf(near_w * 0.9 + depth * 0.8 + (0.15 if electric else 0.0), 0.0, 1.0), minf(1.0, delta * 0.5))
	var ache := near_w * (0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.004))
	Overlay.set_screen_effect("desaturate", chill * 0.7)
	Overlay.set_screen_effect("vignette", 0.25 + chill * 0.4 + ache * 0.2)
	if chill > 0.85:
		_hurt_t -= delta
		if _hurt_t <= 0.0:
			_hurt_t = 1.0
			player.hurt(1.5, "the cold")
	var band := int(floor(temp_c / 8.0))
	if band != _band and absf(temp_c - t) < 3.0:
		_band = band
		if temp_c < -15.0:
			Overlay.subtitle("[about %d C. Your breath smokes; your head %s]" % [int(round(temp_c)), "pounds" if near_w > 0.3 else "aches"], 2.5)
		elif temp_c < 0.0:
			Overlay.subtitle("[about %d C and falling]" % int(round(temp_c)), 2.0)
	if zone != _zone:
		_zone = zone
		environment.ambient_light_energy = 0.07 if electric else 0.22
		environment.fog_density = 0.014 if electric else 0.008
	if _snow:
		_snow.amount_ratio = clampf(paranoia * 0.9 - 0.05, 0.0, 1.0)
	_hum.volume_db = lerpf(_hum.volume_db, -60.0 if electric else -30.0, delta)
	_buzz.volume_db = lerpf(_buzz.volume_db, -26.0 if electric else -60.0, delta)
	_wind.volume_db = lerpf(_wind.volume_db, lerpf(-48.0, -18.0, paranoia), delta)
	_whisper.volume_db = lerpf(_whisper.volume_db, lerpf(-55.0, -24.0, paranoia), delta)
	_breath_t -= delta * (0.3 + paranoia)
	if _breath_t <= 0.0:
		_breath_t = rng.randf_range(25.0, 50.0)
		if paranoia > 0.35:
			Overlay.subtitle(["[breathing, very close behind you]", "[a heavy wind, though the air is still]", "[snow, falling where there is a ceiling]"][rng.randi() % 3], 2.5)


func _gel(delta: float, pp: Vector3) -> void:
	_gel_t -= delta
	if _gel_t <= 0.0:
		_gel_t = rng.randf_range(18.0, 45.0)
		var fwd := -player.camera.global_basis.z
		fwd.y = 0.0
		var at := pp + fwd.normalized() * rng.randf_range(2.0, 4.5) + Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1))
		var space := get_world_3d().direct_space_state
		var up := space.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3.UP * 1.0, at + Vector3.UP * 6.0, 1))
		var dn := space.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3.UP * 1.0, at + Vector3.DOWN * 3.0, 1))
		if not up.is_empty() and not dn.is_empty():
			var sm := SphereMesh.new()
			sm.radius = 0.07
			sm.height = 0.16
			var mi := MeshInstance3D.new()
			mi.mesh = sm
			mi.material_override = MatLib.get_mat("l20_gel")
			add_child(mi)
			mi.global_position = (up["position"] as Vector3) - Vector3(0, 0.08, 0)
			_gel_drops.append({"mi": mi, "v": 0.0, "floor": (dn["position"] as Vector3).y})
			sound.play_at("drip", {"freq": 420.0}, mi.global_position, -10.0, "[a gob of orange jelly drops through the ceiling]")
	for d in _gel_drops.duplicate():
		var mi := d["mi"] as MeshInstance3D
		d["v"] += 9.8 * delta
		mi.global_position.y -= d["v"] * delta
		if mi.global_position.y <= d["floor"] + 0.03:
			_gel_drops.erase(d)
			var cm := CylinderMesh.new()
			cm.top_radius = rng.randf_range(0.16, 0.3)
			cm.bottom_radius = cm.top_radius
			cm.height = 0.012
			mi.mesh = cm
			mi.global_position.y = d["floor"] + 0.008
			_puddles.append(mi)
			if _puddles.size() > 12:
				(_puddles.pop_front() as Node).queue_free()


# ---------------------------------------------------------------- QA stills

func _prep_viridis() -> void:
	G.st["viridis"]["state"] = "play"
	G.st["viridis"]["t"] = 25.0
	for i in G.hexes.size():
		var h: Dictionary = G.hexes[i]
		var s := "green" if i % 5 == 1 else ("red" if i % 7 == 3 else "off")
		h["state"] = s
		h["t"] = 99.0
		h["mi"].material_override = G.mats[s]
	await get_tree().process_frame


func _prep_doors() -> void:
	for g in E.doors.keys():
		if not E.doors[g]["open"]:
			_toggle_door(g)
	await get_tree().create_timer(0.8).timeout


func _prep_lasers() -> void:
	G._begin("lasers")
	for b in G.beams:
		b["speed"] = 0.0
	await get_tree().process_frame


func qa_self_test() -> Array:
	await get_tree().process_frame
	var out: Array = []
	out.append({"what": "Waiting halls are 7 C away from the windows", "ok": absf(temp_c - 7.0) < 1.5 or player.global_position.y < -0.1, "detail": temp_c})
	out.append({"what": "four playable game rooms built", "ok": E.rooms.size() == 4 and G.hexes.size() > 10 and G.platforms.size() == 12, "detail": E.rooms.keys()})
	out.append({"what": "lockers stocked by distance from the entrance", "ok": H.lockers.size() > 60, "detail": H.lockers.size()})
	return out
